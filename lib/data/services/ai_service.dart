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
            debugPrint("GROQ_ERROR_${e.response!.statusCode}: ${e.response!.data}");
          }
          handler.next(e);
        },
      ),
    );
  }

  String buildSystemPrompt(String pendingContext) {
    // Menyuntikkan tanggal hari ini agar query database akurat
    final today = DateTime.now().toIso8601String().split('T').first;
    
    return """
Kamu adalah mesin inti pencatat keuangan.
HARI INI TANGGAL: $today

ATURAN MUTLAK SISTEM (HARUS DIIKUTI 100%):
1. WAJIB GUNAKAN TOOL: Jika input user mengandung niat mencatat uang masuk (income) atau uang keluar (expense), KAMU WAJIB MEMANGGIL TOOL `record_transaction`. DILARANG KERAS hanya membalas dengan teks (seperti "Transaksi berhasil dicatat") tanpa mengeksekusi tool!
2. TRANSAKSI CAMPURAN: Jika dalam satu kalimat terdapat Pemasukan DAN Pengeluaran sekaligus, panggil tool `record_transaction` BERKALI-KALI untuk setiap item. Jangan pernah dirangkum jadi satu.
3. ANTI-HALUSINASI: amount HANYA dari input user. JANGAN MENEBAK HARGA. Jika tidak ada angka sama sekali, langsung panggil `save_pending`.
4. FORMAT ANGKA: Wajib angka bulat. Contoh: 15000 (bukan 15.000 atau Rp15rb).
5. QUERY DATABASE: Untuk mencari transaksi hari ini, gunakan WHERE date LIKE '$today%'.

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

  Future<String> summarizeQuery(String systemPrompt, String userText, Map<String, dynamic> agentMessage, String toolCallId, String resultContent) async {
    final r = await _dio.post(
      "https://api.groq.com/openai/v1/chat/completions",
      options: Options(headers: {"Authorization": "Bearer $apiKey"}),
      data: {
        "model": _agentModel,
        "messages": [
          {"role": "system", "content": "$systemPrompt\nRangkum hasil query ini dalam 1-3 kalimat. Format uang: Rp 1.500.000."},
          {"role": "user", "content": userText},
          {"role": "assistant", "content": agentMessage['content'] ?? "", "tool_calls": agentMessage['tool_calls']},
          {"role": "tool", "tool_call_id": toolCallId, "content": resultContent},
        ],
        "tools": agentTools,
        "max_tokens": 512,
      },
    );
    return r.data['choices'][0]['message']['content'] as String? ?? resultContent;
  }

  Future<String> generateConfirmation(String systemPrompt, String userText, Map<String, dynamic> agentMessage, List<Map<String, dynamic>> toolResultMessages) async {
    final r = await _dio.post(
      "https://api.groq.com/openai/v1/chat/completions",
      options: Options(headers: {"Authorization": "Bearer $apiKey"}),
      data: {
        "model": _agentModel,
        "messages": [
          {"role": "system", "content": "$systemPrompt\nBuat respons konfirmasi singkat HANYA berdasarkan eksekusi tool. JANGAN bertanya balik kepada user."},
          {"role": "user", "content": userText},
          {"role": "assistant", "content": agentMessage['content'] ?? "", "tool_calls": agentMessage['tool_calls']},
          ...toolResultMessages,
        ],
        "tools": agentTools,
        "tool_choice": "none",
        "max_tokens": 512,
      },
    );
    return r.data['choices'][0]['message']['content'] as String? ?? "Siap!";
  }

  Future<String> confirmDirectResolve(String systemPrompt, String nama, int resolvedAmount) async {
    final r = await _dio.post(
      "https://api.groq.com/openai/v1/chat/completions",
      options: Options(headers: {"Authorization": "Bearer $apiKey"}),
      data: {
        "model": _agentModel,
        "messages": [
          {"role": "system", "content": "$systemPrompt\nBerikan 1 kalimat konfirmasi pencatatan singkat."},
          {"role": "user", "content": "Dicatat: $nama Rp $resolvedAmount"},
        ],
        "tools": agentTools,
        "tool_choice": "none",
        "max_tokens": 256,
      },
    );
    return r.data['choices'][0]['message']['content'] as String? ?? "Dicatat! ✓";
  }
}