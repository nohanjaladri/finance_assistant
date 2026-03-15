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
Kamu adalah AI Validasi Keuangan & Database Administrator (State Machine). HARI INI: $today

ATURAN MUTLAK:
1. PENDING: Selesaikan antrean di DAFTAR TERTUNDA menggunakan `update_pending_state`. Jangan panggil `record_transaction` untuk barang yang sama.
2. GANTI TOPIK: Jika user bahas barang baru saat ditanya barang lama, abaikan yang lama, fokus proses yang baru.
3. DILARANG MENEBAK HARGA.
4. QUERY DATABASE (SUPER ADMIN): Jika user bertanya analisis data (contoh: "Total beli makan bulan ini?", "Cari transaksi gojek"), JANGAN MENEBAK! Panggil tool `query_database` dan racik SQL-nya. Format kolom date adalah YYYY-MM-DDTHH:MM:SS. Gunakan fungsi LIKE atau strftime() milik SQLite.
5. EDIT DATA: Jika user minta mengubah transaksi lama, panggil `query_database` dulu untuk cari ID-nya, lalu panggil `update_transaction`.

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
            "content":
                "$systemPrompt\nRangkum hasil data database ini secara natural dan ramah layaknya asisten keuangan pintar. JANGAN TAMPILKAN FORMAT SQL ATAU ARRAY JSON MENTAH KEPADA USER!",
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
