import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/ai_agent_tools.dart';

class AiService {
  static const String _agentModel = "meta-llama/llama-4-scout-17b-16e-instruct";
  final Dio _dio;
  final String apiKey;

  AiService({required this.apiKey}) : _dio = Dio() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) {
          if (e.response != null) {
            debugPrint(
              "GROQ_ERROR_${e.response!.statusCode}: ${e.response!.data}",
            );
          }
          handler.next(e);
        },
      ),
    );
  }

  String buildSystemPrompt(String pendingContext) =>
      """
Kamu adalah AI finansial agent untuk aplikasi pencatat keuangan.
Bahasa: Indonesia. Nada: ramah, singkat, natural.

DATABASE:
  transactions: id, amount(rupiah), note, type(IN/OUT), category, date
  pending_requests: data transaksi belum lengkap

TOOLS TERSEDIA:
- record_transaction: jika ada NAMA item + NOMINAL jelas dari user
- save_pending: jika ada nama tapi TIDAK ada nominal, atau sebaliknya, atau ambigu
- query_database: pertanyaan data historis
- ask_clarification: benar-benar tidak bisa dipahami

ATURAN KERAS:
- amount HANYA dari input user — JANGAN mengarang
- Jika tidak ada nominal → save_pending, tanya nominal
- Jika tidak ada nama item → save_pending, tanya nama
- Kategorisasi otomatis dari konteks (ojek→Transport, makan→Food, dll)

$pendingContext
""";

  Future<Response> sendAgentMessage(List<Map<String, dynamic>> messages) async {
    return await _dio.post(
      "https://api.groq.com/openai/v1/chat/completions",
      options: Options(headers: {"Authorization": "Bearer $apiKey"}),
      data: {
        "model": _agentModel,
        "messages": messages,
        "tools": agentTools,
        "tool_choice": "auto",
        "max_tokens": 1024,
      },
    );
  }

  Future<String> summarizeQuery(
    String systemPrompt,
    String userText,
    Map<String, dynamic> agentMessage,
    String toolCallId,
    String resultContent,
  ) async {
    final r = await _dio.post(
      "https://api.groq.com/openai/v1/chat/completions",
      options: Options(headers: {"Authorization": "Bearer $apiKey"}),
      data: {
        "model": _agentModel,
        "messages": [
          {
            "role": "system",
            "content":
                "$systemPrompt\nRangkum hasil dalam 1-3 kalimat. Format: Rp 1.500.000.",
          },
          {"role": "user", "content": userText},
          {
            "role": "assistant",
            "content": agentMessage['content'] ?? "",
            "tool_calls": agentMessage['tool_calls'],
          },
          {
            "role": "tool",
            "tool_call_id": toolCallId,
            "content": resultContent,
          },
        ],
        "tools": agentTools,
        "max_tokens": 512,
      },
    );
    return r.data['choices'][0]['message']['content'] as String? ??
        resultContent;
  }

  Future<String> generateConfirmation(
    String systemPrompt,
    String userText,
    Map<String, dynamic> agentMessage,
    List<Map<String, dynamic>> toolResultMessages,
  ) async {
    final r = await _dio.post(
      "https://api.groq.com/openai/v1/chat/completions",
      options: Options(headers: {"Authorization": "Bearer $apiKey"}),
      data: {
        "model": _agentModel,
        "messages": [
          {
            "role": "system",
            "content":
                "$systemPrompt\nBuat respons konfirmasi singkat. Jika ada save_pending, langsung tanyakan yang kurang.",
          },
          {"role": "user", "content": userText},
          {
            "role": "assistant",
            "content": agentMessage['content'] ?? "",
            "tool_calls": agentMessage['tool_calls'],
          },
          ...toolResultMessages,
        ],
        "tools": agentTools,
        "tool_choice": "none",
        "max_tokens": 512,
      },
    );
    return r.data['choices'][0]['message']['content'] as String? ?? "Siap!";
  }

  Future<String> confirmDirectResolve(
    String systemPrompt,
    String nama,
    int resolvedAmount,
  ) async {
    final r = await _dio.post(
      "https://api.groq.com/openai/v1/chat/completions",
      options: Options(headers: {"Authorization": "Bearer $apiKey"}),
      data: {
        "model": _agentModel,
        "messages": [
          {
            "role": "system",
            "content": "$systemPrompt\nKonfirmasi pencatatan singkat.",
          },
          {"role": "user", "content": "Dicatat: $nama Rp $resolvedAmount"},
        ],
        "tools": agentTools,
        "tool_choice": "none",
        "max_tokens": 256,
      },
    );
    return r.data['choices'][0]['message']['content'] as String? ??
        "Dicatat! ✓";
  }
}
