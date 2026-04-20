import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/ai_agent_tools.dart';

class AiService {
  static const String _agentModel = "meta-llama/llama-4-scout-17b-16e-instruct";

  static const String _visionModel =
      "meta-llama/llama-4-scout-17b-16e-instruct";

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
6. STRUK BELANJA: Jika user memberikan daftar barang hasil ekstrak foto/gambar struk, panggil `record_receipt_items` untuk memproses seluruh barang sekaligus, jangan dipisah-pisah.

$pendingContext
""";
  }

  Future<String> analyzeReceiptImage(String base64Image) async {
    try {
      final r = await _dio.post(
        "https://api.groq.com/openai/v1/chat/completions",
        options: Options(headers: {"Authorization": "Bearer $apiKey"}),
        data: {
          "model": _visionModel, // Sekarang menggunakan Llama 4 Scout Vision
          "messages": [
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text":
                      "Ekstrak semua barang belanjaan dan harganya dari struk ini beserta nama toko/merchant-nya. Formatkan dengan jelas, misalnya:\nToko: Nama Toko\n1. Barang A - Rp 10.000\n2. Barang B - Rp 20.000\nTotal: Rp 30.000\nAbaikan teks yang tidak berhubungan dengan barang dan harga.",
                },
                {
                  "type": "image_url",
                  "image_url": {"url": "data:image/jpeg;base64,$base64Image"},
                },
              ],
            },
          ],
          "max_tokens": 1024,
          "temperature": 0.1,
        },
      );
      return r.data['choices'][0]['message']['content'] as String? ??
          "Gagal mengekstrak teks dari gambar struk.";
    } catch (e) {
      debugPrint("Vision Error: $e");
      return "Terjadi kesalahan saat memindai gambar struk.";
    }
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
