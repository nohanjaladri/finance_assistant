import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../core/utils/amount_parser.dart';
import '../../core/utils/query_validator.dart';
import '../../data/database/database_helper.dart';
import '../../data/database/pending_request_helper.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/voice_service.dart';
import '../providers/finance_provider.dart';
import '../widgets/query_result_card.dart';
import '../widgets/pending_reminder_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isChatExpanded = false;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceProvider>().addListener(_onFinanceChanged);
    });
  }

  // SNACKBAR ERROR HELPER
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onFinanceChanged() {
    final finance = context.read<FinanceProvider>();
    final pending = finance.pendingToFollowUp;

    if (pending != null) {
      finance.consumeFollowUp();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _injectFollowUpBubble(pending);
      });
    }
  }

  void _injectFollowUpBubble(PendingRequest pending) {
    if (!mounted) return;
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

  Future<String> _buildPendingContext(FinanceProvider finance) async {
    if (finance.activeResolvingPending == null) {
      return "";
    }

    final active = finance.activeResolvingPending!;
    final nama = active.nama ?? active.originalInput;
    final nominal = active.nominal != null
        ? "Rp ${active.nominal}"
        : "Belum ada";

    return "=== TRANSAKSI TERTUNDA (SEDANG DILENGKAPI) ===\nNama: $nama\nNominal: $nominal\nPertanyaan AI sebelumnya: ${active.aiQuestion}\n==========================\n";
  }

  Future<void> _processMessage(String userText) async {
    if (userText.trim().isEmpty) return;
    debugPrint("[HomeScreen] _processMessage: Memproses teks -> $userText");

    final apiKey = _getApiKey();
    if (apiKey.isEmpty) {
      _showErrorSnackBar("API Key Groq tidak ditemukan di file .env");
      return;
    }

    final finance = context.read<FinanceProvider>();
    final voice = context.read<VoiceService>();
    final aiService = AiService(apiKey: apiKey);

    final userAmountFallback = AmountParser.parseAmount(userText);
    final wasWaitingDirectReply = finance.isWaitingDirectReply;
    final activePendingSnapshot = finance.activeResolvingPending;

    voice.stop();

    bool isDirectlyResolving = false;
    if (wasWaitingDirectReply &&
        activePendingSnapshot != null &&
        _isDirectReplyOnly(userText, activePendingSnapshot)) {
      isDirectlyResolving = true;
    } else {
      finance.consumeDirectReply();
      finance.setActiveResolvingPending(null);
    }

    try {
      await finance.addMessage(userText, false);
    } catch (e) {
      _showErrorSnackBar("Gagal menyimpan pesan ke database.");
      return;
    }

    finance.setAiThinking(true);
    _scrollToBottom();

    try {
      final pendingContext = await _buildPendingContext(finance);

      if (isDirectlyResolving &&
          userAmountFallback != null &&
          activePendingSnapshot != null) {
        debugPrint("[HomeScreen] _processMessage: Mode Direct Resolve Aktif");
        await _executeResolvePending(
          userText: userText,
          aiService: aiService,
          finance: finance,
          voice: voice,
          resolvedAmount: userAmountFallback,
          targetPending: activePendingSnapshot,
          pendingContext: pendingContext,
        );
        return;
      }

      final systemPrompt = aiService.buildSystemPrompt(pendingContext);
      final messages = [
        {"role": "system", "content": systemPrompt},
        ...finance.chatHistory
            .where((m) => m['queryResult'] == null)
            .takeLast(8)
            .map(
              (m) => {
                "role": m['isAi'] == 1 ? "assistant" : "user",
                "content": m['text'] as String? ?? "",
              },
            ),
        {"role": "user", "content": userText},
      ];

      debugPrint(
        "[HomeScreen] _processMessage: Mengirim request ke API Groq...",
      );
      final agentResponse = await aiService.sendAgentMessage(messages);
      final choice = agentResponse.data['choices'][0];
      final message = choice['message'];
      final toolCalls = message['tool_calls'] as List<dynamic>?;

      if (toolCalls != null && toolCalls.isNotEmpty) {
        debugPrint(
          "[HomeScreen] _processMessage: Ditemukan ${toolCalls.length} panggilan tool.",
        );
        await _executeToolCalls(
          toolCalls: toolCalls,
          agentMessage: message,
          userText: userText,
          aiService: aiService,
          finance: finance,
          voice: voice,
          pendingContext: pendingContext,
        );
      } else {
        debugPrint("[HomeScreen] _processMessage: Respon berupa teks biasa.");
        final content = message['content'] as String? ?? "";
        await finance.addMessage(content, true);
        if (isChatExpanded) voice.speak(content);
      }
    } catch (e) {
      debugPrint("[HomeScreen] AGENT_ERROR: $e");
      _showErrorSnackBar("Maaf, ada gangguan koneksi ke AI.");
      await finance.addMessage(
        "Maaf, gagal memproses data karena gangguan koneksi.",
        true,
      );
    } finally {
      finance.setAiThinking(false);
      _scrollToBottom();
    }
  }

  Future<void> _executeToolCalls({
    required List<dynamic> toolCalls,
    required Map<String, dynamic> agentMessage,
    required String userText,
    required AiService aiService,
    required FinanceProvider finance,
    required VoiceService voice,
    required String pendingContext,
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
        debugPrint(
          "[HomeScreen] _executeToolCalls: Mengeksekusi $toolName dengan argumen $args",
        );
      } catch (e) {
        debugPrint("[HomeScreen] TOOL_ARG_PARSE_ERROR: $e");
        _showErrorSnackBar("Format argumen dari AI tidak valid.");
      }

      String result = "";
      if (toolName == "record_transaction") {
        int finalAmount = 0;
        if (args['amount'] != null) {
          // PENGAMAN (BACKUP PARSER): Membersihkan karakter non-angka (seperti Rp, titik, atau koma)
          String rawAmount = args['amount'].toString();
          String cleanedAmount = AmountParser.cleanNumberString(rawAmount);
          finalAmount = int.tryParse(cleanedAmount) ?? 0;
          debugPrint(
            "[HomeScreen] record_transaction: Ekstraksi angka (Raw: $rawAmount -> Cleaned: $cleanedAmount -> Final: $finalAmount)",
          );
        }

        if (finalAmount <= 0) {
          result = "error: amount tidak valid atau tidak disebutkan";
          debugPrint(
            "[HomeScreen] record_transaction: Gagal karena finalAmount <= 0",
          );
        } else {
          final note = args['note'] as String? ?? "Transaksi";
          final type = (args['type'] as String? ?? 'OUT').toUpperCase();
          final category = args['category'] as String? ?? 'Other';

          try {
            await finance.addTransaction(finalAmount, note, type, category);
            if (finance.activeResolvingPending != null)
              await finance.completePending(finance.activeResolvingPending!.id);
            result = "success: $note Rp $finalAmount $type $category";
            anyRecordSuccess = true;
          } catch (e) {
            result = "error_database: gagal menyimpan ke lokal";
            _showErrorSnackBar("Gagal menyimpan transaksi ke database.");
          }
        }
      } else if (toolName == "save_pending") {
        final originalInput = args['original_input'] as String? ?? "";
        final partialNote = args['partial_note'] as String? ?? originalInput;
        final partialType = (args['partial_type'] as String? ?? 'OUT')
            .replaceAll('UNKNOWN', 'OUT')
            .toUpperCase();
        final partialCategory = args['partial_category'] as String? ?? 'Other';
        final reason = args['reason'] as String? ?? 'Data tidak lengkap';

        int? aiAmount;
        if (args['amount'] != null) {
          String rawAmount = args['amount'].toString();
          String cleanedAmount = AmountParser.cleanNumberString(rawAmount);
          aiAmount = int.tryParse(cleanedAmount);
        }

        final nama = (partialNote != originalInput && partialNote.isNotEmpty)
            ? partialNote
            : null;
        final missing = <String>[];
        if (nama == null) missing.add('nama');
        if (aiAmount == null) missing.add('nominal');

        try {
          await finance.savePendingRequestNew(
            originalInput: originalInput,
            nama: nama,
            nominal: aiAmount,
            aiQuestion:
                "Informasi belum lengkap. Tolong sebutkan nama dan nominalnya.",
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
          result =
              "saved_silently: Data berhasil dimasukkan ke antrean pending.";
        } catch (e) {
          result = "error_database: gagal save pending";
          _showErrorSnackBar("Gagal menyimpan ke antrean pending.");
        }
      } else if (toolName == "update_transaction") {
        final id = int.tryParse(args['id'].toString()) ?? -1;

        int newAmount = 0;
        if (args['new_amount'] != null) {
          String rawAmount = args['new_amount'].toString();
          String cleanedAmount = AmountParser.cleanNumberString(rawAmount);
          newAmount = int.tryParse(cleanedAmount) ?? 0;
        }

        final newNote = args['new_note'] as String?;

        if (id != -1 && newAmount > 0) {
          try {
            await DatabaseHelper.instance.updateTransaction(
              id,
              newAmount,
              newNote,
            );
            await finance.refreshData();
            result =
                "success_update: Transaksi ID $id berhasil diperbarui menjadi Rp $newAmount.";
          } catch (e) {
            result = "error_database: Gagal memperbarui transaksi";
            _showErrorSnackBar("Gagal memperbarui transaksi di database.");
          }
        } else {
          result = "error: ID tidak ditemukan atau amount tidak valid.";
        }
      } else if (toolName == "query_database") {
        result = "query_pending";
      } else if (toolName == "ask_clarification") {
        result = "clarification_sent";
      }

      toolResults.add({
        "tool_call_id": toolCallId,
        "tool_name": toolName,
        "result": result,
        "args": args,
      });
    }

    final hasPending = toolResults.any((r) => r['tool_name'] == 'save_pending');
    if (hasPending) {
      final msg = anyRecordSuccess
          ? "Sebagian dicatat, sisanya masuk antrean pending ✓"
          : "Dicatat di antrean pending ✓";
      await finance.addMessage(msg, true);

      if (isChatExpanded)
        voice.speak(
          anyRecordSuccess ? "Masuk pending sebagian" : "Masuk pending",
        );
      return;
    }

    final queryTool = toolResults
        .where((r) => r['result'] == 'query_pending')
        .firstOrNull;
    if (queryTool != null) {
      final args = queryTool['args'] as Map<String, dynamic>;
      final sql = args['sql'] as String? ?? '';
      final vizType = args['viz_type'] as String? ?? 'auto';

      if (sql.isEmpty) {
        await finance.addMessage("Tidak bisa membuat query ini.", true);
        return;
      }

      final validation = QueryValidator.validate(sql);
      if (!validation.isValid) {
        _showErrorSnackBar(
          "Query diblokir: Sistem mendeteksi query yang berpotensi merusak data.",
        );
        await finance.addMessage(
          "Query tidak valid: ${validation.errorMessage}",
          true,
        );
        return;
      }

      try {
        final queryResult = await finance.executeQuery(
          validation.sanitizedQuery!,
        );
        if (!queryResult.isSuccess) {
          _showErrorSnackBar("Gagal mengeksekusi pencarian data di database.");
          await finance.addMessage("Gagal mengambil data.", true);
          return;
        }

        final resultContent = queryResult.isEffectivelyEmpty
            ? "Tidak ada data ditemukan"
            : "Ditemukan ${queryResult.rowCount} baris:\n${queryResult.rows.take(10).map((r) => r.toString()).join('\n')}";

        final sysPrompt = aiService.buildSystemPrompt(pendingContext);
        final aiSummary = await aiService.summarizeQuery(
          sysPrompt,
          userText,
          agentMessage,
          queryTool['tool_call_id'] as String,
          resultContent,
        );

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
        if (isChatExpanded) voice.speak(aiSummary);
      } catch (e) {
        debugPrint("[HomeScreen] _executeToolCalls: Error saat query -> $e");
        await finance.addMessage("Terjadi kesalahan saat mencari data.", true);
      }
      return;
    }

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

    try {
      final toolResultMessages = toolResults
          .map(
            (r) => {
              "role": "tool",
              "tool_call_id": r['tool_call_id'],
              "content": r['result'] as String,
            },
          )
          .toList();
      final sysPrompt = aiService.buildSystemPrompt(pendingContext);
      final confirmation = await aiService.generateConfirmation(
        sysPrompt,
        userText,
        agentMessage,
        toolResultMessages,
      );
      await finance.addMessage(confirmation, true);
      if (isChatExpanded) voice.speak(confirmation);
    } catch (e) {
      debugPrint(
        "[HomeScreen] _executeToolCalls: Konfirmasi AI gagal, mencetak konfirmasi lokal.",
      );
      await finance.addMessage("Proses Selesai! ✓", true);
    }
  }

  Future<void> _executeResolvePending({
    required String userText,
    required AiService aiService,
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

    try {
      await finance.addTransaction(
        resolvedAmount,
        nama,
        type,
        targetPending.category,
      );
      await finance.completePending(targetPending.id);

      final sysPrompt = aiService.buildSystemPrompt("");
      final aiRes = await aiService.confirmDirectResolve(
        sysPrompt,
        nama,
        resolvedAmount,
      );
      await finance.addMessage(aiRes, true);
      if (isChatExpanded) voice.speak(aiRes);
    } catch (e) {
      debugPrint("[HomeScreen] ERROR _executeResolvePending: $e");
      _showErrorSnackBar("Gagal memproses resolusi pending.");
      await finance.addMessage("Dicatat! ✓", true);
    }
  }

  String _formatRupiah(int amount) {
    final str = amount.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return amount < 0 ? '-${buf.toString()}' : buf.toString();
  }

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
        actions: const [PendingBadge()], // Memanggil Widget PendingReminderCard
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

                if (isAi && m.containsKey('queryResult')) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: QueryResultCard(
                      aiSummary: m['text'] ?? "",
                      result: m['queryResult'] as RawQueryResult,
                      vizType: m['vizType'],
                      originalQuestion: m['originalQuestion'] as String? ?? "",
                    ),
                  );
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
