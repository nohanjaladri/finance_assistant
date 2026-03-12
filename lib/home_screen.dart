/// home_screen.dart
/// Pending request baru: wajib(nama+nominal), opsional(qty+datetime), auto(AI)
/// Follow-up: setelah catat berhasil DAN ketika idle
/// Follow-up format: "Ada X data belum lengkap, mau dilengkapi?"

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'logic/voice_service.dart';
import 'logic/finance_provider.dart';
import 'logic/query_validator.dart';
import 'logic/database_helper.dart';
import 'logic/pending_request_helper.dart';
import 'logic/ai_agent_tools.dart';
import 'widgets/query_result_card.dart';
import 'widgets/pending_reminder_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Dio _dio = Dio();
  bool isChatExpanded = false;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DateTime? _lastPressedAt;

  static const String _agentModel = "meta-llama/llama-4-scout-17b-16e-instruct";

  // ==========================================
  // PARSING AMOUNT
  // ==========================================

  static const Map<String, int> _wordNumbers = {
    'nol': 0,
    'satu': 1,
    'dua': 2,
    'tiga': 3,
    'empat': 4,
    'lima': 5,
    'enam': 6,
    'tujuh': 7,
    'delapan': 8,
    'sembilan': 9,
    'sepuluh': 10,
    'sebelas': 11,
    'dua belas': 12,
    'tiga belas': 13,
    'empat belas': 14,
    'lima belas': 15,
    'enam belas': 16,
    'tujuh belas': 17,
    'delapan belas': 18,
    'sembilan belas': 19,
    'dua puluh': 20,
    'tiga puluh': 30,
    'empat puluh': 40,
    'lima puluh': 50,
    'enam puluh': 60,
    'tujuh puluh': 70,
    'delapan puluh': 80,
    'sembilan puluh': 90,
    'seratus': 100,
    'dua ratus': 200,
    'tiga ratus': 300,
    'empat ratus': 400,
    'lima ratus': 500,
    'enam ratus': 600,
    'tujuh ratus': 700,
    'delapan ratus': 800,
    'sembilan ratus': 900,
    'seribu': 1000,
    'sejuta': 1000000,
  };

  int? _wordToInt(String word) {
    word = word.trim();
    if (word.isEmpty) return null;
    if (_wordNumbers.containsKey(word)) return _wordNumbers[word];
    for (final tens in [20, 30, 40, 50, 60, 70, 80, 90]) {
      final tw = _wordNumbers.entries
          .firstWhere(
            (e) => e.value == tens,
            orElse: () => const MapEntry('', 0),
          )
          .key;
      if (tw.isEmpty) continue;
      if (word.startsWith(tw)) {
        final rest = word.substring(tw.length).trim();
        if (rest.isEmpty) return tens;
        final ones = _wordNumbers[rest];
        if (ones != null && ones < 10) return tens + ones;
      }
    }
    return int.tryParse(word);
  }

  int? _parseWordAmount(String text) {
    final lower = text.toLowerCase();
    final jutaReg = RegExp(
      r'(?:(\d+)|([a-z]+?(?:\s+[a-z]+?)*?))\s+juta(?:\s+(?:(\d+)|([a-z]+?(?:\s+[a-z]+?)*?))\s+ribu)?',
    );
    final jutaMatch = jutaReg.firstMatch(lower);
    if (jutaMatch != null) {
      int? jv =
          int.tryParse(jutaMatch.group(1) ?? '') ??
          _wordToInt(jutaMatch.group(2) ?? '');
      if (jv != null && jv > 0) {
        int total = jv * 1000000;
        final rs = (jutaMatch.group(3) ?? jutaMatch.group(4) ?? '').trim();
        if (rs.isNotEmpty) {
          int? rv = int.tryParse(rs) ?? _wordToInt(rs);
          if (rv != null) total += rv * 1000;
        }
        return total;
      }
    }
    final ratusRibuReg = RegExp(
      r'(?:(\d+)|([a-z]+(?:\s+[a-z]+)*))\s+ratus\s+ribu',
    );
    final rrm = ratusRibuReg.firstMatch(lower);
    if (rrm != null) {
      int? v =
          int.tryParse(rrm.group(1) ?? '') ?? _wordToInt(rrm.group(2) ?? '');
      if (v != null && v > 0) return v * 100000;
    }
    final ribuReg = RegExp(
      r'(?:(\d+(?:[.,]\d+)?)|([a-z]+(?:\s+[a-z]+)*))\s+ribu',
    );
    final rm = ribuReg.firstMatch(lower);
    if (rm != null) {
      final raw = rm.group(1);
      if (raw != null) {
        final v = double.tryParse(raw.replaceAll(',', '.'));
        if (v != null && v > 0) return (v * 1000).round();
      }
      int? v = _wordToInt(rm.group(2) ?? '');
      if (v != null && v > 0) return v * 1000;
    }
    final ratusReg = RegExp(r'(?:(\d+)|([a-z]+(?:\s+[a-z]+)*))\s+ratus');
    final ratm = ratusReg.firstMatch(lower);
    if (ratm != null) {
      int? v =
          int.tryParse(ratm.group(1) ?? '') ?? _wordToInt(ratm.group(2) ?? '');
      if (v != null && v > 0) return v * 100;
    }
    for (final e in _wordNumbers.entries) {
      if (lower.contains(e.key) && e.value > 0) return e.value;
    }
    return null;
  }

  String _cleanNumberString(String raw) {
    final dc = '.'.allMatches(raw).length;
    final cc = ','.allMatches(raw).length;
    if (dc == 0 && cc == 0) return raw;
    if (dc > 1) return raw.replaceAll('.', '');
    if (cc > 1) return raw.replaceAll(',', '');
    if (dc == 1 && cc == 0) {
      final parts = raw.split('.');
      if (parts.last.length == 3 && parts.first.length <= 3)
        return raw.replaceAll('.', '');
      return parts.first;
    }
    if (cc == 1 && dc == 0) {
      final parts = raw.split(',');
      if (parts.last.length == 3 && parts.first.length <= 3)
        return raw.replaceAll(',', '');
      return parts.first;
    }
    if (dc == 1 && cc == 1) {
      final di = raw.indexOf('.');
      final ci = raw.indexOf(',');
      if (di < ci) return raw.replaceAll('.', '').split(',').first;
      return raw.replaceAll(',', '').split('.').first;
    }
    return raw.replaceAll(RegExp(r'[.,]'), '');
  }

  int? _parseAmount(String text) {
    final lower = text.toLowerCase().trim();
    final jutaDigit = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(?:juta|jt\b)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (jutaDigit != null) {
      final v = double.tryParse(jutaDigit.group(1)!.replaceAll(',', '.'));
      if (v != null && v > 0) return (v * 1000000).round();
    }
    final ribuDigit = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(?:rb|ribu|k\b)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (ribuDigit != null) {
      final v = double.tryParse(ribuDigit.group(1)!.replaceAll(',', '.'));
      if (v != null && v > 0) return (v * 1000).round();
    }
    final rp = RegExp(
      r'rp\.?\s*([\d.,]+)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (rp != null) {
      final v = int.tryParse(_cleanNumberString(rp.group(1)!));
      if (v != null && v > 0) return v;
    }
    final num = RegExp(r'\b(\d[\d.,]*\d|\d+)\b').firstMatch(lower);
    if (num != null) {
      final v = int.tryParse(_cleanNumberString(num.group(1)!));
      if (v != null && v > 0) return v;
    }
    return _parseWordAmount(lower);
  }

  // ==========================================
  // CEK DIRECT REPLY
  // ==========================================

  bool _isDirectReplyOnly(String userText, PendingRequest activePending) {
    final lower = userText.toLowerCase().trim();
    String stripped = lower
        .replaceAll(
          RegExp(
            r'\d+(?:[.,]\d+)?\s*(?:juta|jt|ribu|rb|k\b)?'
            r'|\b(?:satu|dua|tiga|empat|lima|enam|tujuh|delapan|sembilan|sepuluh|sebelas'
            r'|dua\s+puluh|tiga\s+puluh|empat\s+puluh|lima\s+puluh|enam\s+puluh'
            r'|tujuh\s+puluh|delapan\s+puluh|sembilan\s+puluh'
            r'|seratus|dua\s+ratus|tiga\s+ratus|empat\s+ratus|lima\s+ratus'
            r'|enam\s+ratus|tujuh\s+ratus|delapan\s+ratus|sembilan\s+ratus'
            r'|seribu|sejuta)\s*(?:juta|ribu|ratus)?\b',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    if (stripped.isEmpty) return true;

    const confirmWords = {
      'ya',
      'iya',
      'yep',
      'ok',
      'oke',
      'yoi',
      'betul',
      'benar',
      'rupiah',
      'rp',
      'aja',
      'deh',
      'dong',
      'nih',
      'tuh',
    };
    final words = stripped
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.every((w) => confirmWords.contains(w))) return true;

    final pendingNama = (activePending.nama ?? '').toLowerCase();
    if (pendingNama.isNotEmpty && stripped.contains(pendingNama)) return true;

    return false;
  }

  // ==========================================
  // LIFECYCLE
  // ==========================================

  @override
  void initState() {
    super.initState();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceProvider>().addListener(_onFinanceChanged);
    });
  }

  void _onFinanceChanged() {
    final finance = context.read<FinanceProvider>();
    if (finance.pendingToFollowUp != null) {
      _injectFollowUpBubble(finance.pendingToFollowUp!);
      finance.consumeFollowUp();
    }
  }

  void _injectFollowUpBubble(PendingRequest pending) {
    if (!isChatExpanded) setState(() => isChatExpanded = true);
    final finance = context.read<FinanceProvider>();
    finance.setWaitingDirectReply(true);
    finance.addMessage(pending.aiQuestion, true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    context.read<FinanceProvider>().removeListener(_onFinanceChanged);
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  String _getApiKey() => dotenv.maybeGet('GROQ_API_KEY') ?? "";

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ==========================================
  // FOLLOW-UP PENDING: tanya ke user
  // "Ada X data belum lengkap, mau dilengkapi?"
  // ==========================================

  Future<void> _maybeShowFollowUp(FinanceProvider finance) async {
    final count = await PendingRequestHelper.instance.countPending();
    if (count == 0) return;

    final all = await finance.getAllPending();

    // Bangun ringkasan daftar pending
    final summaries = all
        .take(3)
        .map((p) => '• ${p.followUpSummary}')
        .join('\n');
    final more = all.length > 3 ? '\n...dan ${all.length - 3} lainnya' : '';

    final followUpMsg =
        'Ada $count data transaksi yang belum lengkap, mau dilengkapi sekarang?\n\n'
        '$summaries$more';

    // Tambah bubble AI dengan tombol Ya/Nanti
    finance.setPendingFollowUpQuestion(followUpMsg, all);
  }

  // ==========================================
  // BUILD CONTEXT UNTUK AI
  // ==========================================

  Future<String> _buildPendingContext(FinanceProvider finance) async {
    final all = await finance.getAllPending();
    if (all.isEmpty) return "";
    final oldest = all.first;
    final others = all.length - 1;
    return """
=== TRANSAKSI TERTUNDA ===
Prioritas: ${oldest.contextSummary}
${others > 0 ? '+ $others lainnya' : ''}
==========================
""";
  }

  String _buildSystemPrompt(String pendingContext) =>
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
${pendingContext.isNotEmpty ? 'INGAT: Ada transaksi tertunda, singgung di akhir.' : ''}
""";

  // ==========================================
  // ENTRY POINT: PROCESS MESSAGE
  // ==========================================

  Future<void> _processMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    final apiKey = _getApiKey();
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("API Key tidak ditemukan.")));
      return;
    }

    final finance = context.read<FinanceProvider>();
    final voice = context.read<VoiceService>();

    // Cek apakah ini jawaban follow-up Ya/Tidak
    if (finance.isWaitingFollowUpConfirm) {
      await _handleFollowUpConfirm(userText, finance, voice, apiKey);
      return;
    }

    final userAmount = _parseAmount(userText);
    final wasWaitingDirectReply = finance.isWaitingDirectReply;
    final activePendingSnapshot = finance.activeResolvingPending;

    voice.stop();
    finance.consumeDirectReply();
    await finance.addMessage(userText, false);
    finance.setAiThinking(true);
    _scrollToBottom();

    try {
      final pendingContext = await _buildPendingContext(finance);

      // SHORTCUT: DIRECT REPLY — angka langsung untuk pending aktif
      if (wasWaitingDirectReply &&
          userAmount != null &&
          activePendingSnapshot != null &&
          _isDirectReplyOnly(userText, activePendingSnapshot)) {
        debugPrint(
          "DIRECT_REPLY: ID=${activePendingSnapshot.id} amount=$userAmount",
        );
        await _executeResolvePending(
          userText: userText,
          apiKey: apiKey,
          finance: finance,
          voice: voice,
          resolvedAmount: userAmount,
          targetPending: activePendingSnapshot,
          pendingContext: pendingContext,
        );
        return;
      }

      // AI AGENT: Tool Calling
      final systemPrompt = _buildSystemPrompt(pendingContext);
      final messages = [
        {"role": "system", "content": systemPrompt},
        ...finance.chatHistory
            .where((m) => m['queryResult'] == null && m['isFollowUp'] != true)
            .takeLast(8)
            .map(
              (m) => {
                "role": m['isAi'] == 1 ? "assistant" : "user",
                "content": m['text'] as String? ?? "",
              },
            ),
        {"role": "user", "content": userText},
      ];

      final agentResponse = await _dio.post(
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

      final choice = agentResponse.data['choices'][0];
      final message = choice['message'];
      final toolCalls = message['tool_calls'] as List<dynamic>?;

      if (toolCalls != null && toolCalls.isNotEmpty) {
        await _executeToolCalls(
          toolCalls: toolCalls,
          agentMessage: message,
          userText: userText,
          apiKey: apiKey,
          finance: finance,
          voice: voice,
          pendingContext: pendingContext,
          userAmount: userAmount,
        );
      } else {
        final content = message['content'] as String? ?? "";
        await finance.addMessage(content, true);
        if (isChatExpanded) voice.speak(content);
        // Idle: tampilkan follow-up jika ada pending
        await _maybeShowFollowUp(finance);
      }
    } catch (e) {
      debugPrint("AGENT_ERROR: $e");
      await finance.addMessage("Maaf, ada gangguan koneksi.", true);
    } finally {
      finance.setAiThinking(false);
      _scrollToBottom();
    }
  }

  // ==========================================
  // HANDLE JAWABAN FOLLOW-UP (Ya / Tidak)
  // ==========================================

  Future<void> _handleFollowUpConfirm(
    String userText,
    FinanceProvider finance,
    VoiceService voice,
    String apiKey,
  ) async {
    final lower = userText.toLowerCase().trim();
    final isYes = RegExp(
      r'^(ya|iya|yep|ok|oke|yoi|mau|lanjut|boleh|silakan)',
    ).hasMatch(lower);

    finance.setWaitingFollowUpConfirm(false);
    await finance.addMessage(userText, false);

    if (isYes) {
      // Ambil pending tertua dan mulai lengkapi
      final oldest = await finance.getOldestPending();
      if (oldest != null) {
        finance.setActiveResolvingPending(oldest);
        finance.setWaitingDirectReply(true);

        // Tampilkan detail pending yang perlu dilengkapi
        final detail = _buildFollowUpDetail(oldest);
        await finance.addMessage(detail, true);
        if (isChatExpanded) voice.speak(oldest.aiQuestion);
      }
    } else {
      // Tidak mau → simpan, tanya lagi nanti
      await finance.addMessage('Oke, nanti saya ingatkan lagi ya! 😊', true);
    }

    _scrollToBottom();
  }

  /// Bangun pesan detail untuk pending yang mau dilengkapi
  String _buildFollowUpDetail(PendingRequest p) {
    final buf = StringBuffer();
    buf.writeln('Oke, lengkapi data ini:');
    buf.writeln('');
    buf.writeln('📋 *${p.nama ?? p.originalInput}*');
    if (p.nama != null) buf.writeln('   Nama: ${p.nama}');
    if (p.nominal != null)
      buf.writeln('   Harga: Rp ${_formatRupiah(p.nominal!)}');
    buf.writeln('   Jumlah: ${p.quantity}x');
    buf.writeln('   Waktu input: ${p.formattedInputDatetime}');
    buf.writeln('   Kurang: ${p.missingFieldsLabel}');
    buf.writeln('');
    buf.writeln(p.aiQuestion);
    return buf.toString();
  }

  // ==========================================
  // EKSEKUSI TOOL CALLS
  // ==========================================

  Future<void> _executeToolCalls({
    required List<dynamic> toolCalls,
    required Map<String, dynamic> agentMessage,
    required String userText,
    required String apiKey,
    required FinanceProvider finance,
    required VoiceService voice,
    required String pendingContext,
    required int? userAmount,
  }) async {
    final toolResults = <Map<String, dynamic>>[];
    bool anyRecordSuccess = false;

    for (final call in toolCalls) {
      final toolName = call['function']['name'] as String;
      final toolCallId = call['id'] as String;
      Map<String, dynamic> args = {};
      try {
        final raw = call['function']['arguments'];
        args =
            jsonDecode(raw is String ? raw : jsonEncode(raw))
                as Map<String, dynamic>;
      } catch (e) {
        debugPrint("TOOL_ARG_PARSE_ERROR: $e");
      }

      debugPrint("TOOL_CALL: $toolName | args=$args");
      String result = "";

      switch (toolName) {
        case "record_transaction":
          result = await _toolRecordTransaction(
            args: args,
            finance: finance,
            userAmount: userAmount,
          );
          if (result.startsWith('success')) anyRecordSuccess = true;
          break;
        case "save_pending":
          result = await _toolSavePending(
            args: args,
            finance: finance,
            userAmount: userAmount,
          );
          break;
        case "query_database":
          result = "query_pending";
          break;
        case "ask_clarification":
          result = "clarification_sent";
          break;
        default:
          result = "unknown_tool";
      }

      toolResults.add({
        "tool_call_id": toolCallId,
        "tool_name": toolName,
        "result": result,
        "args": args,
      });
    }

    // Handle query
    final queryTool = toolResults
        .where((r) => r['result'] == 'query_pending')
        .firstOrNull;
    if (queryTool != null) {
      await _executeQueryTool(
        args: queryTool['args'] as Map<String, dynamic>,
        toolCallId: queryTool['tool_call_id'] as String,
        agentMessage: agentMessage,
        userText: userText,
        apiKey: apiKey,
        finance: finance,
        voice: voice,
        pendingContext: pendingContext,
      );
      return;
    }

    // Handle clarification
    final clarifyTool = toolResults
        .where((r) => r['result'] == 'clarification_sent')
        .firstOrNull;
    if (clarifyTool != null) {
      final q =
          (clarifyTool['args'] as Map<String, dynamic>)['question']
              as String? ??
          "";
      await finance.addMessage(q, true);
      if (isChatExpanded) voice.speak(q);
      return;
    }

    // Generate konfirmasi
    await _generateAgentConfirmation(
      toolResults: toolResults,
      agentMessage: agentMessage,
      userText: userText,
      apiKey: apiKey,
      finance: finance,
      voice: voice,
      pendingContext: pendingContext,
    );

    // ✅ Setelah catat berhasil → tampilkan follow-up pending jika ada
    if (anyRecordSuccess) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _maybeShowFollowUp(finance);
    }
  }

  // ==========================================
  // TOOL: record_transaction
  // ==========================================

  Future<String> _toolRecordTransaction({
    required Map<String, dynamic> args,
    required FinanceProvider finance,
    required int? userAmount,
  }) async {
    final finalAmount = userAmount ?? 0;
    if (finalAmount <= 0) {
      debugPrint("RECORD_REJECTED: tidak ada nominal dari user");
      return "error: tidak ada nominal di input user";
    }
    final note = args['note'] as String? ?? "Transaksi";
    final type = (args['type'] as String? ?? 'OUT').toUpperCase();
    final category = args['category'] as String? ?? 'Other';

    await finance.addTransaction(finalAmount, note, type, category);
    if (finance.activeResolvingPending != null) {
      await finance.completePending(finance.activeResolvingPending!.id);
    }
    return "success: $note Rp $finalAmount $type $category";
  }

  // ==========================================
  // TOOL: save_pending — BARU dengan 4 field
  // ==========================================

  Future<String> _toolSavePending({
    required Map<String, dynamic> args,
    required FinanceProvider finance,
    required int? userAmount,
  }) async {
    final originalInput = args['original_input'] as String? ?? "";
    final partialNote = args['partial_note'] as String? ?? originalInput;
    final partialType = (args['partial_type'] as String? ?? 'OUT')
        .replaceAll('UNKNOWN', 'OUT')
        .toUpperCase();
    final partialCategory = args['partial_category'] as String? ?? 'Other';
    final question =
        args['question'] as String? ?? 'Bisa lengkapi informasinya?';
    final reason = args['reason'] as String? ?? 'Data tidak lengkap';

    // Tentukan nama dan nominal dari apa yang sudah diketahui
    // nama: ambil dari partial_note jika bukan placeholder
    final nama = (partialNote != originalInput && partialNote.isNotEmpty)
        ? partialNote
        : null;
    // nominal: dari userAmount jika ada (mungkin AI kirim save_pending padahal ada nominal)
    final nominal = userAmount;

    // Hitung missing fields
    final missing = <String>[];
    if (nama == null) missing.add('nama');
    if (nominal == null) missing.add('nominal');

    await finance.savePendingRequestNew(
      originalInput: originalInput,
      nama: nama,
      nominal: nominal,
      aiQuestion: question,
      reason: reason,
      category: partialCategory,
      type: partialType,
      missingFields: missing,
      partialData: {
        'note': partialNote,
        'type': partialType,
        'category': partialCategory,
      },
    );

    final oldest = await finance.getOldestPending();
    if (oldest != null) finance.setActiveResolvingPending(oldest);
    finance.setWaitingDirectReply(true);

    return "saved: $question";
  }

  // ==========================================
  // TOOL: query_database
  // ==========================================

  Future<void> _executeQueryTool({
    required Map<String, dynamic> args,
    required String toolCallId,
    required Map<String, dynamic> agentMessage,
    required String userText,
    required String apiKey,
    required FinanceProvider finance,
    required VoiceService voice,
    required String pendingContext,
  }) async {
    final sql = args['sql'] as String? ?? '';
    final vizType = args['viz_type'] as String? ?? 'auto';
    if (sql.isEmpty) {
      await finance.addMessage("Tidak bisa membuat query ini.", true);
      return;
    }

    final validation = QueryValidator.validate(sql);
    if (!validation.isValid) {
      await finance.addMessage(
        "Query tidak valid: ${validation.errorMessage}",
        true,
      );
      return;
    }

    final queryResult = await finance.executeQuery(validation.sanitizedQuery!);
    if (!queryResult.isSuccess) {
      await finance.addMessage("Gagal mengambil data.", true);
      return;
    }

    final resultContent = queryResult.isEffectivelyEmpty
        ? "Tidak ada data ditemukan"
        : "Ditemukan ${queryResult.rowCount} baris:\n${queryResult.rows.take(10).map((r) => r.toString()).join('\n')}";

    try {
      final r = await _dio.post(
        "https://api.groq.com/openai/v1/chat/completions",
        options: Options(headers: {"Authorization": "Bearer $apiKey"}),
        data: {
          "model": _agentModel,
          "messages": [
            {
              "role": "system",
              "content":
                  "${_buildSystemPrompt(pendingContext)}\nRangkum hasil dalam 1-3 kalimat. Format: Rp 1.500.000.",
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
      final aiSummary =
          r.data['choices'][0]['message']['content'] as String? ??
          resultContent;
      if (queryResult.isEffectivelyEmpty) {
        await finance.addMessage(aiSummary, true);
      } else {
        await finance.addQueryResultMessage(
          aiSummary: aiSummary,
          queryResult: queryResult,
          vizType: vizType,
          originalQuestion: userText,
        );
      }
      if (isChatExpanded)
        voice.speak(
          r.data['choices'][0]['message']['content'] as String? ?? "",
        );
    } catch (_) {
      await finance.addMessage(
        queryResult.isEffectivelyEmpty
            ? "Belum ada data."
            : "Ada ${queryResult.rowCount} data.",
        true,
      );
    }
  }

  // ==========================================
  // GENERATE KONFIRMASI
  // ==========================================

  Future<void> _generateAgentConfirmation({
    required List<Map<String, dynamic>> toolResults,
    required Map<String, dynamic> agentMessage,
    required String userText,
    required String apiKey,
    required FinanceProvider finance,
    required VoiceService voice,
    required String pendingContext,
  }) async {
    try {
      final newPendingCtx = await _buildPendingContext(finance);
      final toolResultMessages = toolResults
          .map(
            (r) => {
              "role": "tool",
              "tool_call_id": r['tool_call_id'],
              "content": r['result'] as String,
            },
          )
          .toList();

      final r = await _dio.post(
        "https://api.groq.com/openai/v1/chat/completions",
        options: Options(headers: {"Authorization": "Bearer $apiKey"}),
        data: {
          "model": _agentModel,
          "messages": [
            {
              "role": "system",
              "content":
                  "${_buildSystemPrompt(newPendingCtx)}\nBuat respons konfirmasi singkat. Jika ada save_pending, langsung tanyakan yang kurang.",
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
      final confirmation =
          r.data['choices'][0]['message']['content'] as String? ?? "Siap!";
      await finance.addMessage(confirmation, true);
      if (isChatExpanded) voice.speak(confirmation);
    } catch (e) {
      debugPrint("CONFIRM_ERROR: $e");
      final hasPending = toolResults.any(
        (r) => r['tool_name'] == 'save_pending',
      );
      if (hasPending) {
        final q =
            (toolResults.firstWhere(
                      (r) => r['tool_name'] == 'save_pending',
                    )['result']
                    as String)
                .replaceFirst("saved: ", "");
        await finance.addMessage(q, true);
      } else {
        await finance.addMessage("Dicatat! ✓", true);
      }
    }
  }

  // ==========================================
  // RESOLVE PENDING DIRECT
  // ==========================================

  Future<void> _executeResolvePending({
    required String userText,
    required String apiKey,
    required FinanceProvider finance,
    required VoiceService voice,
    required int resolvedAmount,
    required PendingRequest targetPending,
    required String pendingContext,
  }) async {
    final type = (targetPending.type == '?' || targetPending.type.isEmpty)
        ? 'OUT'
        : targetPending.type;
    final nama = targetPending.nama ?? targetPending.originalInput;

    await finance.addTransaction(
      resolvedAmount,
      nama,
      type,
      targetPending.category,
    );
    await finance.completePending(targetPending.id);

    final newCtx = await _buildPendingContext(finance);
    try {
      final r = await _dio.post(
        "https://api.groq.com/openai/v1/chat/completions",
        options: Options(headers: {"Authorization": "Bearer $apiKey"}),
        data: {
          "model": _agentModel,
          "messages": [
            {
              "role": "system",
              "content":
                  "${_buildSystemPrompt(newCtx)}\nKonfirmasi pencatatan singkat.",
            },
            {"role": "user", "content": "Dicatat: $nama Rp $resolvedAmount"},
          ],
          "tools": agentTools,
          "tool_choice": "none",
          "max_tokens": 256,
        },
      );
      final aiRes =
          r.data['choices'][0]['message']['content'] as String? ?? "Dicatat! ✓";
      if (newCtx.isNotEmpty) {
        final next = await finance.getOldestPending();
        if (next != null) {
          finance.setActiveResolvingPending(next);
          finance.setWaitingDirectReply(true);
        }
      }
      await finance.addMessage(aiRes, true);
      if (isChatExpanded) voice.speak(aiRes);
    } catch (_) {
      await finance.addMessage("Dicatat! ✓", true);
    }

    // Cek pending sisa → follow-up
    await Future.delayed(const Duration(milliseconds: 500));
    await _maybeShowFollowUp(finance);
  }

  // ==========================================
  // FORMAT RUPIAH
  // ==========================================

  String _formatRupiah(int amount) {
    final str = amount.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return amount < 0 ? '-${buf.toString()}' : buf.toString();
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (isChatExpanded) {
          context.read<VoiceService>().stop();
          setState(() => isChatExpanded = false);
          return;
        }
        final now = DateTime.now();
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tekan lagi untuk keluar')),
          );
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: Stack(
          children: [_buildDashboard(finance), _buildChatPanel(finance)],
        ),
      ),
    );
  }

  Widget _buildDashboard(FinanceProvider finance) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => finance.refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Dompetku",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => finance.clearAll(),
                    icon: const Icon(Icons.delete_sweep, color: Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildBalanceCard(finance),
              const SizedBox(height: 30),
              const Text(
                "Analisis Dana",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _buildChart(finance),
              const SizedBox(height: 20),
              const Text(
                "Histori Transaksi",
                style: TextStyle(color: Colors.grey),
              ),
              _buildHistoryList(finance),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(FinanceProvider finance) {
    final saldo = finance.totalIn - finance.totalOut;
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.indigo],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          const Text("Sisa Saldo", style: TextStyle(color: Colors.white70)),
          Text(
            "Rp ${_formatRupiah(saldo)}",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Divider(color: Colors.white24, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _sumCol("Masuk", finance.totalIn, Colors.greenAccent),
              _sumCol("Keluar", finance.totalOut, Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sumCol(String label, int amount, Color color) => Column(
    children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.white60)),
      Text(
        "Rp ${_formatRupiah(amount)}",
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
    ],
  );

  Widget _buildChart(FinanceProvider finance) {
    return SizedBox(
      height: 200,
      child: (finance.totalIn == 0 && finance.totalOut == 0)
          ? const Center(child: Text("Belum ada data"))
          : PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: finance.totalIn.toDouble(),
                    color: Colors.teal,
                    title: 'IN',
                  ),
                  PieChartSectionData(
                    value: finance.totalOut.toDouble(),
                    color: Colors.orange,
                    title: 'OUT',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHistoryList(FinanceProvider finance) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: finance.history.length,
      itemBuilder: (context, i) {
        final item = finance.history[i];
        final isIn = item['type'] == 'IN';
        return ListTile(
          leading: Icon(
            isIn ? Icons.add_circle : Icons.remove_circle,
            color: isIn ? Colors.teal : Colors.orange,
          ),
          title: Text(item['note'] ?? ""),
          subtitle: Text(
            item['category'] ?? "",
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          trailing: Text(
            "Rp ${_formatRupiah(item['amount'] as int)}",
            style: TextStyle(
              color: isIn ? Colors.teal : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatPanel(FinanceProvider finance) {
    return AnimatedAlign(
      duration: const Duration(milliseconds: 400),
      alignment: isChatExpanded ? Alignment.center : Alignment.bottomCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        margin: EdgeInsets.all(isChatExpanded ? 0 : 20),
        height: isChatExpanded ? MediaQuery.of(context).size.height : 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isChatExpanded ? 0 : 30),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: isChatExpanded ? _buildFullChat(finance) : _buildMiniChat(),
      ),
    );
  }

  Widget _buildMiniChat() => InkWell(
    onTap: () {
      setState(() => isChatExpanded = true);
      _scrollToBottom();
    },
    child: const Center(
      child: Text(
        "💬 Tanya AI Keuangan",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
      ),
    ),
  );

  Widget _buildFullChat(FinanceProvider finance) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Asisten AI", style: TextStyle(fontSize: 16)),
            if (finance.activeResolvingPending != null)
              Text(
                '📝 "${finance.activeResolvingPending!.nama ?? finance.activeResolvingPending!.originalInput}"',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.deepPurpleAccent,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() => isChatExpanded = false),
        ),
        actions: const [PendingBadge()],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(15),
              itemCount: finance.chatHistory.length,
              itemBuilder: (context, i) {
                final m = finance.chatHistory[i];
                final isAi = m['isAi'] == 1;

                // Query result bubble
                if (isAi && m.containsKey('queryResult')) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: QueryResultCard(
                      aiSummary: m['text'] ?? "",
                      result: m['queryResult'] as RawQueryResult,
                      vizType: vizTypeFromString(
                        m['vizType'] as String? ?? 'auto',
                      ),
                      originalQuestion: m['originalQuestion'] as String? ?? "",
                    ),
                  );
                }

                // Follow-up bubble dengan tombol Ya/Nanti
                if (isAi && m['isFollowUp'] == true) {
                  return _buildFollowUpBubble(m['text'] as String, finance);
                }

                return Align(
                  alignment: isAi
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isAi ? Colors.grey[100] : Colors.deepPurple,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      m['text'] ?? "",
                      style: TextStyle(
                        color: isAi ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (finance.isAiThinking)
            const LinearProgressIndicator(color: Colors.deepPurple),
          _buildInputArea(finance),
        ],
      ),
    );
  }

  /// Bubble follow-up dengan tombol Ya / Nanti
  Widget _buildFollowUpBubble(String message, FinanceProvider finance) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.deepPurple[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.deepPurple.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Text(message, style: const TextStyle(fontSize: 13)),
            ),
            const Divider(height: 1),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: finance.isWaitingFollowUpConfirm
                        ? () => _handleFollowUpConfirm(
                            "ya",
                            finance,
                            context.read<VoiceService>(),
                            _getApiKey(),
                          )
                        : null,
                    child: const Text(
                      "Ya, lengkapi",
                      style: TextStyle(color: Colors.deepPurple),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: TextButton(
                    onPressed: finance.isWaitingFollowUpConfirm
                        ? () => _handleFollowUpConfirm(
                            "tidak",
                            finance,
                            context.read<VoiceService>(),
                            _getApiKey(),
                          )
                        : null,
                    child: Text(
                      "Nanti saja",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(FinanceProvider finance) {
    final voice = Provider.of<VoiceService>(context);
    final isWaiting = finance.isWaitingDirectReply;

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 8, 15, 15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (finance.activeResolvingPending != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isWaiting
                    ? Colors.deepPurple[100]
                    : Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isWaiting
                      ? Colors.deepPurple.shade400
                      : Colors.deepPurple.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isWaiting ? Icons.reply : Icons.pending_actions,
                    size: 14,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      finance.activeResolvingPending!.aiQuestion,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.deepPurple,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      finance.setActiveResolvingPending(null);
                      finance.setWaitingDirectReply(false);
                    },
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: isWaiting
                        ? "Ketik jawaban langsung..."
                        : finance.activeResolvingPending != null
                        ? "Ketik jawaban..."
                        : "Ketik transaksi atau tanya data...",
                    filled: true,
                    fillColor: isWaiting
                        ? Colors.deepPurple[50]
                        : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (v) {
                    _processMessage(v);
                    _textController.clear();
                  },
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () {
                  if (_textController.text.isNotEmpty) {
                    _processMessage(_textController.text);
                    _textController.clear();
                  } else {
                    voice.startListening(
                      onResult: (t, f) {
                        _textController.text = t;
                        if (f) {
                          _processMessage(t);
                          _textController.clear();
                        }
                      },
                    );
                  }
                },
                icon: CircleAvatar(
                  backgroundColor: isWaiting ? Colors.deepPurple : null,
                  child: Icon(
                    _textController.text.isNotEmpty ? Icons.send : Icons.mic,
                    color: isWaiting ? Colors.white : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension IterableExtension<T> on Iterable<T> {
  Iterable<T> takeLast(int n) {
    final list = toList();
    return list.skip((list.length - n).clamp(0, list.length));
  }
}
