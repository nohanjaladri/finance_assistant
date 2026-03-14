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

  String buildSystemPrompt(String pendingContext) {
    final today = DateTime.now().toIso8601String().split('T').first;

    return """
Kamu adalah AI Validasi Keuangan Berjenjang (State Machine). HARI INI: $today

ATURAN MUTLAK (DILARANG MELANGGAR):
1. TRANSAKSI TERTUNDA: Jika user melengkapi DAFTAR TERTUNDA di bawah ini, panggil `update_pending_state`. JIKA SUDAH LENGKAP (missing fields kosong), DILARANG KERAS memanggil `record_transaction` lagi untuk barang yang sama!
2. OUT OF CONTEXT / GANTI TOPIK: Jika kamu bertanya harga barang A, tapi user malah membahas barang B yang baru, ABAIKAN pertanyaan lama. Langsung proses barang B tersebut ke `record_transaction` (jika lengkap) atau `create_pending_state` (jika kurang).
3. BATAL: Jika user bilang "batal" atau "nggak jadi" untuk barang tertunda, panggil `cancel_pending_state`.
4. AMBIGU: Jika ada banyak antrean tertunda, dan user cuma jawab "20000", kamu WAJIB panggil `ask_clarification` untuk bertanya itu buat yang mana.
5. DILARANG MENEBAK HARGA. DILARANG MERESPONS TEKS ANGKA TANPA TOOL.

$pendingContext
""";
  }

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
            "content": "$systemPrompt\nRangkum hasil query ini dengan ramah.",
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
}
