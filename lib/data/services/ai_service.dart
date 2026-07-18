/// ai_service.dart (v2)
/// AI Service dengan 3-layer fallback:
/// Layer 1: Groq API (Llama 4 Scout) — Primary, cepat, gratis
/// Layer 2: Gemini API (gemini-2.0-flash) — Fallback jika Groq gagal
/// Layer 3: Rule-based Engine — Last resort, tidak butuh internet
library;

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/constants/ai_agent_tools.dart';
import '../../core/constants/app_config.dart';

enum AiProvider { groq, gemini, rulebased }

class AiResponse {
  final String? content;
  final List<dynamic>? toolCalls;
  final AiProvider usedProvider;
  final bool isError;
  final String? errorMessage;

  const AiResponse({
    this.content,
    this.toolCalls,
    required this.usedProvider,
    this.isError = false,
    this.errorMessage,
  });
}

class AiService {
  static const String _groqModel = "llama-3.3-70b-versatile";
  static const String _geminiModel = "gemini-2.0-flash";

  final String groqApiKey;
  final String? geminiApiKey;
  final Dio _dio;

  AiService({required this.groqApiKey, this.geminiApiKey}) : _dio = Dio() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) {
          debugPrint(
            "AI_HTTP_ERROR: ${e.response?.statusCode} ${e.response?.data}",
          );
          handler.next(e);
        },
      ),
    );
  }

  // ========================================================
  // SYSTEM PROMPT BUILDER
  // ========================================================

  String buildSystemPrompt({
    required String pendingContext,
    required Map<String, dynamic> financialSummary,
    required String recentTransactionsContext,
    String? currentRoomInfo,
  }) {
    final today = DateTime.now().toIso8601String().split('T').first;
    final now = DateTime.now();
    final summary = financialSummary;

    // Format ringkasan keuangan untuk konteks AI
    final summaryStr = summary.isEmpty
        ? "Data keuangan belum tersedia."
        : """
Ringkasan 30 hari terakhir:
- Total Pemasukan: Rp ${_fmt(summary['total_in'] ?? 0)}
- Total Pengeluaran: Rp ${_fmt(summary['total_out'] ?? 0)}
- Saldo Bersih: Rp ${_fmt(summary['saldo'] ?? 0)}
- Pengeluaran Tunai: Rp ${_fmt(summary['tunai_out'] ?? 0)}
- Pengeluaran Non Tunai: Rp ${_fmt(summary['non_tunai_out'] ?? 0)}
- Jumlah Transaksi: ${summary['transaction_count'] ?? 0} transaksi
""";

    return """
Kamu adalah "Dompetku AI" — asisten keuangan pribadi yang cerdas, ramah, dan dapat diandalkan.
HARI INI: $today | WAKTU: ${now.hour}:${now.minute.toString().padLeft(2, '0')}
NAMA SKEMA DATABASE AKTIF: ${AppConfig.schema}

═══════════════════════════════════
KONTEKS KEUANGAN USER (REAL-TIME):
═══════════════════════════════════
$summaryStr
${currentRoomInfo != null ? '\nMode Sharing Aktif: $currentRoomInfo' : ''}

═══════════════════════════════════
TRANSAKSI TERBARU YANG SUDAH TERCATAT:
═══════════════════════════════════
$recentTransactionsContext

═══════════════════════════════════
ATURAN KERJA (WAJIB DIIKUTI):
═══════════════════════════════════
1. PENDING RESOLUTION: Jika ada DAFTAR TERTUNDA, selesaikan dengan `update_pending_state`. JANGAN panggil `record_transaction` untuk item yang sama.
2. ANTI HALUSINASI HARGA: DILARANG KERAS menebak, mengasumsikan, atau menggunakan harga barang dari transaksi lama di riwayat/database untuk transaksi baru. Jika user tidak menyebutkan nominal/harga secara spesifik untuk barang tersebut pada pesan saat ini, kamu wajib membuat status tertunda menggunakan `create_pending_state`.
3. QUERY CERDAS: Jika user bertanya data (pengeluaran hari ini/minggu ini/bulan ini/dll), panggil `query_database` dengan SQL yang tepat. Kamu WAJIB menyertakan prefix skema aktif "${AppConfig.schema}" pada setiap nama tabel dalam query SQL. Contoh: SELECT SUM(amount) FROM ${AppConfig.schema}.transactions WHERE type='OUT';
   JANGAN menebak dari ringkasan di atas — ringkasan hanya untuk gambaran umum.
4. EDIT DATA: Jika user minta ubah transaksi lama → `query_database` dulu untuk cari ID → `update_transaction`.
5. PAYMENT METHOD OTOMATIS: Tentukan 'payment_method' based on kategori.
6. CHATBOT KEUANGAN: Jika user bertanya sesuatu bukan transaksi (tips menabung, istilah keuangan, dll), gunakan `general_response`.
7. BATAS TOPIK: JANGAN berikan saran investasi saham/crypto spesifik, prediksi harga, atau info berita real-time.
8. GANTI TOPIK: Jika user bahas barang baru saat ditanya barang lama, abaikan yang lama, proses yang baru.
9. PEMISAHAN MULTIPLE ITEMS: Jika user menyebutkan beberapa barang/item sekaligus dalam satu pesan (misalnya 'mie ayam dan es teh'), kamu WAJIB memisahkan mereka menjadi beberapa transaksi terpisah. Panggil tool `record_transaction` atau `create_pending_state` terpisah untuk masing-masing item. JANGAN menggabungkan mereka menjadi satu catatan tunggal seperti 'mie ayam dan es teh'.
10. PERTANYAAN SATU PER SATU: Jika ada lebih dari satu informasi yang kurang (misalnya beberapa item pending sekaligus), kamu hanya boleh mengajukan SATU pertanyaan untuk SATU item yang paling lama/prioritas terlebih dahulu pada respon asistenmu. Selesaikan satu item terlebih dahulu sebelum menanyakan item berikutnya.


═══════════════════════════════════
DAFTAR TRANSAKSI TERTUNDA:
═══════════════════════════════════
$pendingContext
""";
  }

  String _fmt(dynamic n) {
    if (n == null) return '0';
    final num = n is int ? n : int.tryParse(n.toString()) ?? 0;
    final str = num.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  // ========================================================
  // LAYER 1: GROQ API
  // ========================================================

  Future<AiResponse> _callGroq(List<Map<String, dynamic>> messages) async {
    final payload = {
      "model": _groqModel,
      "messages": messages,
      "tools": agentTools,
      "tool_choice": "auto",
      "max_tokens": 1024,
      "temperature": 0.1,
    };
    debugPrint("[GROQ REQUEST PAYLOAD]: ${jsonEncode(payload)}");
    try {
      final response = await _dio.post(
        "https://api.groq.com/openai/v1/chat/completions",
        options: Options(
          headers: {"Authorization": "Bearer $groqApiKey"},
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 15),
        ),
        data: payload,
      );

      debugPrint("[GROQ RESPONSE DATA]: ${jsonEncode(response.data)}");
      final choice = response.data['choices'][0];
      final message = choice['message'];
      return AiResponse(
        content: message['content'] as String?,
        toolCalls: message['tool_calls'] as List<dynamic>?,
        usedProvider: AiProvider.groq,
      );
    } on DioException catch (e) {
      debugPrint("[GROQ ERROR]: (${e.response?.statusCode}): ${e.message}");
      rethrow;
    }
  }

  // ========================================================
  // LAYER 2: GEMINI API
  // ========================================================

  Future<AiResponse> _callGemini(List<Map<String, dynamic>> messages) async {
    if (geminiApiKey == null || geminiApiKey!.isEmpty) {
      throw Exception("Gemini API key tidak tersedia");
    }

    try {
      // Konversi pesan ke format Gemini
      final geminiHistory = <Content>[];
      String systemInstruction = '';

      for (final msg in messages) {
        final role = msg['role'] as String;
        final content = msg['content'] as String? ?? '';

        if (role == 'system') {
          systemInstruction = content;
        } else if (role == 'user') {
          geminiHistory.add(Content.text(content));
        } else if (role == 'assistant' && content.isNotEmpty) {
          geminiHistory.add(Content('model', [TextPart(content)]));
        }
      }

      debugPrint(
        "[GEMINI REQUEST HISTORY]: ${geminiHistory.map((c) => c.toJson()).toList()}",
      );
      debugPrint("[GEMINI SYSTEM INSTRUCTION]: $systemInstruction");

      final model = GenerativeModel(
        model: _geminiModel,
        apiKey: geminiApiKey!,
        tools: _buildGeminiTools(),
        generationConfig: GenerationConfig(
          temperature: 0.1,
          maxOutputTokens: 1024,
        ),
        systemInstruction: systemInstruction.isNotEmpty
            ? Content.system(systemInstruction)
            : null,
      );

      final chat = model.startChat(
        history: geminiHistory.take(geminiHistory.length - 1).toList(),
      );

      final lastMsg = geminiHistory.isNotEmpty
          ? (geminiHistory.last.parts.first as TextPart).text
          : '';
      final response = await chat.sendMessage(Content.text(lastMsg));

      debugPrint(
        "[GEMINI RESPONSE DATA]: ${jsonEncode({
          'text': response.text,
          'candidates': response.candidates.map((c) => {
            'content': {
              'role': c.content.role,
              'parts': c.content.parts.map((p) {
                if (p is TextPart) {
                  return {'text': p.text};
                } else if (p is FunctionCall) {
                  return {
                    'functionCall': {'name': p.name, 'args': p.args},
                  };
                }
                return {'type': p.runtimeType.toString()};
              }).toList(),
            },
          }).toList(),
        })}",
      );

      // Parse Gemini response — extract tool calls if any
      List<dynamic>? toolCalls;
      String? textContent;

      for (final part in response.candidates.first.content.parts) {
        if (part is FunctionCall) {
          toolCalls ??= [];
          toolCalls.add({
            'id': 'gemini_${DateTime.now().millisecondsSinceEpoch}',
            'type': 'function',
            'function': {'name': part.name, 'arguments': jsonEncode(part.args)},
          });
        } else if (part is TextPart) {
          textContent = part.text;
        }
      }

      return AiResponse(
        content: textContent,
        toolCalls: toolCalls,
        usedProvider: AiProvider.gemini,
      );
    } catch (e) {
      debugPrint("[GEMINI ERROR]: $e");
      rethrow;
    }
  }

  List<Tool> _buildGeminiTools() {
    // Konversi agentTools ke format Gemini FunctionDeclaration
    return [
      Tool(
        functionDeclarations: agentTools.map((t) {
          final fn = t['function'] as Map<String, dynamic>;
          final params = fn['parameters'] as Map<String, dynamic>;
          return FunctionDeclaration(
            fn['name'] as String,
            fn['description'] as String,
            _convertSchema(params),
          );
        }).toList(),
      ),
    ];
  }

  Schema _convertSchema(Map<String, dynamic> params) {
    final props = params['properties'] as Map<String, dynamic>? ?? {};
    final required = (params['required'] as List?)?.cast<String>() ?? [];

    return Schema(
      SchemaType.object,
      properties: props.map((key, val) {
        final v = val as Map<String, dynamic>;
        final type = v['type'] as String? ?? 'string';
        SchemaType schemaType;
        switch (type) {
          case 'integer':
            schemaType = SchemaType.integer;
            break;
          case 'array':
            schemaType = SchemaType.array;
            break;
          case 'boolean':
            schemaType = SchemaType.boolean;
            break;
          default:
            schemaType = SchemaType.string;
        }
        return MapEntry(
          key,
          Schema(
            schemaType,
            description: v['description'] as String?,
            enumValues: (v['enum'] as List?)?.cast<String>(),
          ),
        );
      }),
      requiredProperties: required,
    );
  }

  // ========================================================
  // LAYER 3: RULE-BASED FALLBACK ENGINE
  // ========================================================

  AiResponse _ruleBasedFallback(String userText) {
    final lower = userText.toLowerCase();

    // Deteksi intent sederhana
    if (lower.contains('saldo') ||
        lower.contains('berapa uang') ||
        lower.contains('tabungan')) {
      return const AiResponse(
        content:
            "Maaf, saya sedang tidak bisa terhubung ke server AI. Anda bisa melihat saldo di dashboard utama atau coba lagi sebentar.",
        usedProvider: AiProvider.rulebased,
      );
    }

    if (lower.contains('terima kasih') || lower.contains('makasih')) {
      return const AiResponse(
        content: "Sama-sama! Ada yang bisa saya bantu lagi? 😊",
        usedProvider: AiProvider.rulebased,
      );
    }

    if (lower.contains('halo') ||
        lower.contains('hai') ||
        lower.contains('hello')) {
      return const AiResponse(
        content:
            "Halo! Saya Dompetku AI. Maaf, saya sedang dalam mode terbatas karena gangguan koneksi. Silakan coba lagi dalam beberapa saat. 🙏",
        usedProvider: AiProvider.rulebased,
      );
    }

    return const AiResponse(
      content:
          "Maaf, saya sedang mengalami gangguan koneksi ke server AI. Silakan coba lagi dalam beberapa saat. Data Anda aman dan tersimpan dengan baik. 🙏",
      usedProvider: AiProvider.rulebased,
    );
  }

  // ========================================================
  // MAIN: sendMessage dengan fallback chain
  // ========================================================

  Future<AiResponse> sendMessage(List<Map<String, dynamic>> messages) async {
    // Layer 1: Groq
    if (groqApiKey.isNotEmpty) {
      try {
        final result = await _callGroq(messages);
        debugPrint("✅ AI Provider: Groq");
        return result;
      } catch (e) {
        debugPrint("⚠️ Groq gagal, menggunakan rule-based...");
      }
    }

    // Layer 2: Rule-based (Gemini bypassed)
    final lastUserMsg =
        messages.lastWhere(
              (m) => m['role'] == 'user',
              orElse: () => <String, dynamic>{'content': ''},
            )['content']
            as String? ?? '';
    debugPrint("✅ AI Provider: Rule-based (last resort)");
    return _ruleBasedFallback(lastUserMsg);
  }

  // ========================================================
  // SUMMARIZE QUERY RESULT
  // ========================================================

  Future<String> summarizeQueryResult({
    required String systemPrompt,
    required String userText,
    required Map<String, dynamic> agentMessage,
    required String toolCallId,
    required String resultContent,
  }) async {
    final messages = [
      {
        "role": "system",
        "content":
            "$systemPrompt\nRangkum hasil data database ini secara natural dan ramah layaknya asisten keuangan pintar. JANGAN TAMPILKAN FORMAT SQL ATAU ARRAY JSON MENTAH! Gunakan format Rupiah yang tepat (Rp xxx.xxx).",
      },
      {"role": "user", "content": userText},
      {
        "role": "assistant",
        "content": agentMessage['content'] ?? "",
        "tool_calls": agentMessage['tool_calls'],
      },
      {"role": "tool", "tool_call_id": toolCallId, "content": resultContent},
    ];

    try {
      final response = await sendMessage(messages);
      return response.content ?? resultContent;
    } catch (e) {
      return resultContent;
    }
  }

  /// Deteksi apakah user input kemungkinan besar adalah transaksi
  static bool isLikelyTransaction(String text) {
    final lower = text.toLowerCase();
    final transactionKeywords = [
      'beli',
      'bayar',
      'jajan',
      'makan',
      'minum',
      'bensin',
      'transfer',
      'kirim',
      'terima',
      'dapat',
      'gaji',
      'topup',
      'top up',
      'isi',
      'beli',
      'belanja',
      'parkir',
      'ojek',
      'grab',
      'gojek',
    ];
    return transactionKeywords.any((kw) => lower.contains(kw));
  }
}
