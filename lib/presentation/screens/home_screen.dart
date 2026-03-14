import 'dart:async';
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
import '../widgets/receipt_card.dart';
import 'transaction_history_screen.dart';

class AnimatedThinkingBubble extends StatefulWidget {
  const AnimatedThinkingBubble({super.key});
  @override
  State<AnimatedThinkingBubble> createState() => _AnimatedThinkingBubbleState();
}

class _AnimatedThinkingBubbleState extends State<AnimatedThinkingBubble> {
  int _dotCount = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (mounted) setState(() => _dotCount = (_dotCount + 1) % 4);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String dots = List.filled(_dotCount, '.').join(' ');
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "Sedang berpikir $dots",
              style: const TextStyle(
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _injectFollowUpBubble(pending),
      );
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

  Future<String> _buildPendingContext(FinanceProvider finance) async {
    final pendings = await finance.getAllPending();
    if (pendings.isEmpty) return "";

    StringBuffer sb = StringBuffer();
    sb.writeln("=== DAFTAR TRANSAKSI TERTUNDA (PENDING) ===");
    for (var p in pendings) {
      final nama = p.nama ?? 'Belum ada';
      final nominal = p.nominal != null ? "Rp ${p.nominal}" : "Belum ada";
      sb.writeln(
        "[ID: ${p.id}] Barang: $nama | Harga: $nominal | Field Kurang: ${p.missingFields} | Pertanyaan Aktif: '${p.aiQuestion}'",
      );
    }
    sb.writeln("===========================================");
    return sb.toString();
  }

  Future<void> _processMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    final apiKey = _getApiKey();
    if (apiKey.isEmpty) {
      _showErrorSnackBar("API Key Groq tidak ditemukan di file .env");
      return;
    }

    final finance = context.read<FinanceProvider>();
    final voice = context.read<VoiceService>();
    final aiService = AiService(apiKey: apiKey);

    final userAmountFallback = AmountParser.parseAmount(userText);
    bool userHasDigits =
        RegExp(r'\d').hasMatch(userText) || userAmountFallback != null;

    voice.stop();
    finance.consumeDirectReply();

    try {
      await finance.addMessage(userText, false);
    } catch (e) {
      _showErrorSnackBar("Gagal menyimpan pesan.");
      return;
    }

    finance.setAiThinking(true);
    _scrollToBottom();

    try {
      final pendingContext = await _buildPendingContext(finance);
      final systemPrompt = aiService.buildSystemPrompt(pendingContext);

      final messages = [
        {"role": "system", "content": systemPrompt},
        ...finance.chatHistory
            .where((m) => m['queryResult'] == null && m['receiptData'] == null)
            .takeLast(8)
            .map(
              (m) => {
                "role": m['isAi'] == 1 ? "assistant" : "user",
                "content": m['text'] as String? ?? "",
              },
            ),
        {"role": "user", "content": userText},
      ];

      final agentResponse = await aiService.sendAgentMessage(messages);
      final choice = agentResponse.data['choices'][0];
      final message = choice['message'];
      final toolCalls = message['tool_calls'] as List<dynamic>?;

      if (toolCalls != null && toolCalls.isNotEmpty) {
        await _executeToolCalls(
          toolCalls: toolCalls,
          agentMessage: message,
          userText: userText,
          aiService: aiService,
          finance: finance,
          voice: voice,
          pendingContext: pendingContext,
          userHasDigits: userHasDigits,
        );
      } else {
        String content = message['content'] as String? ?? "";

        bool aiHasPrice = RegExp(
          r'(Rp\s*\.?\s*\d+|\d{3,})',
          caseSensitive: false,
        ).hasMatch(content);
        if (aiHasPrice && !userHasDigits) {
          String extractedNote = userText
              .replaceAll(
                RegExp(
                  r'\d+(?:[.,]\d+)?\s*(?:juta|jt|ribu|rb|k\b)?|rp\s*',
                  caseSensitive: false,
                ),
                '',
              )
              .trim();
          if (extractedNote.isEmpty) extractedNote = "Item tersebut";

          await finance.savePendingRequestNew(
            originalInput: userText,
            nama: extractedNote,
            nominal: null,
            aiQuestion: "Mohon lengkapi nominal/harga untuk '$extractedNote'.",
            reason: "Penghancur Halusinasi Teks AI",
            type: 'OUT',
            missingFields: ['amount'],
            partialData: {'note': extractedNote},
          );
          content = "Mohon lengkapi nominal/harga untuk '$extractedNote'.";
        }
        await finance.addMessage(content, true);
        if (isChatExpanded) voice.speak(content);
      }
    } catch (e) {
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
    required bool userHasDigits,
  }) async {
    final toolResults = <Map<String, dynamic>>[];
    List<Map<String, dynamic>> recordedTxs = [];
    bool intercepted = false;
    List<String> interactiveQuestions = [];

    Set<String> processedSignatures = {};

    for (final call in toolCalls) {
      String toolName = call['function']['name'] as String;
      final toolCallId = call['id'] as String;
      Map<String, dynamic> args = {};
      try {
        final raw = call['function']['arguments'];
        args =
            jsonDecode(raw is String ? raw : jsonEncode(raw))
                as Map<String, dynamic>;
      } catch (_) {}

      if (toolName == "record_transaction") {
        int checkAmount = 0;
        if (args['amount'] != null)
          checkAmount =
              int.tryParse(
                AmountParser.cleanNumberString(args['amount'].toString()),
              ) ??
              0;
        if (!userHasDigits && checkAmount > 0) {
          intercepted = true;
          toolName = "create_pending_state";
          args['partial_note'] = args['note'];
          args['missing_fields'] = ['amount'];
          args['amount'] = null;
          args['ai_generated_question'] =
              "Berapa nominal untuk ${args['note']}?";
        }
      }

      String result = "";

      if (toolName == "record_transaction") {
        int finalAmount = 0;
        if (args['amount'] != null)
          finalAmount =
              int.tryParse(
                AmountParser.cleanNumberString(args['amount'].toString()),
              ) ??
              0;
        final note = args['note'] as String? ?? "Transaksi";

        if (finalAmount > 0) {
          String sig = "${note.toLowerCase()}_$finalAmount";
          if (!processedSignatures.contains(sig)) {
            processedSignatures.add(sig);

            final type = (args['type'] as String? ?? 'OUT').toUpperCase();
            final category = args['category'] as String? ?? 'Other';

            try {
              await finance.addTransaction(finalAmount, note, type, category);
              result = "success";
              recordedTxs.add({
                'note': note,
                'amount': finalAmount,
                'type': type,
              });
            } catch (_) {}
          } else {
            result = "skipped_duplicate";
          }
        }
      } else if (toolName == "create_pending_state") {
        final partialNote = args['partial_note'] as String? ?? "";
        final aiQuestion =
            args['ai_generated_question'] as String? ?? "Mohon lengkapi data.";
        int? aiAmount;
        if (args['partial_amount'] != null)
          aiAmount = int.tryParse(
            AmountParser.cleanNumberString(args['partial_amount'].toString()),
          );

        final missing =
            (args['missing_fields'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[];

        try {
          await finance.savePendingRequestNew(
            originalInput: userText,
            nama: partialNote.isEmpty ? null : partialNote,
            nominal: aiAmount,
            aiQuestion: aiQuestion,
            reason: "Data belum lengkap",
            type: 'OUT',
            missingFields: missing,
            partialData: {'note': partialNote},
          );
          interactiveQuestions.add(aiQuestion);
          result = "pending_created";
        } catch (_) {}
      } else if (toolName == "update_pending_state") {
        int pId = int.tryParse(args['pending_id'].toString()) ?? -1;
        List<String> missing =
            (args['remaining_missing_fields'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[];
        String nextQuestion = args['next_ai_question'] as String? ?? "";

        int? updatedAmount;
        if (args['updated_amount'] != null)
          updatedAmount = int.tryParse(
            AmountParser.cleanNumberString(args['updated_amount'].toString()),
          );
        String updatedNote = args['updated_note'] as String? ?? "Transaksi";

        if (pId != -1) {
          if (missing.isEmpty && updatedAmount != null && updatedAmount > 0) {
            String sig = "${updatedNote.toLowerCase()}_$updatedAmount";

            try {
              if (!processedSignatures.contains(sig)) {
                processedSignatures.add(sig);
                await finance.addTransaction(
                  updatedAmount,
                  updatedNote,
                  "OUT",
                  "Other",
                );
                recordedTxs.add({
                  'note': updatedNote,
                  'amount': updatedAmount,
                  'type': "OUT",
                });
              }
              await finance.completePending(pId);
              result = "resolved";
            } catch (_) {}
          } else {
            try {
              await finance.updatePendingState(
                pId,
                updatedNote,
                updatedAmount,
                jsonEncode(missing),
                nextQuestion,
              );
              if (nextQuestion.isNotEmpty)
                interactiveQuestions.add(nextQuestion);
              result = "updated_still_pending";
            } catch (_) {}
          }
        }
      } else if (toolName == "cancel_pending_state") {
        int pId = int.tryParse(args['pending_id'].toString()) ?? -1;
        if (pId != -1) {
          await finance.cancelPending(pId);
          result = "cancelled";
        }
      } else if (toolName == "update_transaction") {
        final id = int.tryParse(args['id'].toString()) ?? -1;
        int newAmount =
            int.tryParse(
              AmountParser.cleanNumberString(args['new_amount'].toString()),
            ) ??
            0;
        final newNote = args['new_note'] as String?;
        if (id != -1 && newAmount > 0) {
          await DatabaseHelper.instance.updateTransaction(
            id,
            newAmount,
            newNote,
          );
          await finance.refreshData();
          result = "success";
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

    final queryTool = toolResults
        .where((r) => r['result'] == 'query_pending')
        .firstOrNull;
    if (queryTool != null) {
      final args = queryTool['args'] as Map<String, dynamic>;
      final sql = args['sql'] as String? ?? '';
      if (sql.isNotEmpty) {
        final validation = QueryValidator.validate(sql);
        if (validation.isValid) {
          final queryResult = await finance.executeQuery(
            validation.sanitizedQuery!,
          );
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

          final isSimpleAggregate =
              (queryResult.rows.length == 1 && queryResult.columns.length <= 2);
          if (queryResult.isEffectivelyEmpty || isSimpleAggregate) {
            await finance.addMessage(aiSummary, true);
          } else {
            VizType parsedVizType = VizType.auto;
            try {
              parsedVizType = VizType.values.firstWhere(
                (e) =>
                    e.toString().split('.').last ==
                    (args['viz_type']?.toString() ?? 'auto'),
                orElse: () => VizType.auto,
              );
            } catch (_) {}
            await finance.addQueryResultMessage(
              aiSummary: aiSummary,
              queryResult: queryResult,
              vizType: parsedVizType.toString().split('.').last,
              originalQuestion: userText,
            );
          }
          if (isChatExpanded) voice.speak(aiSummary);
        }
      }
      return;
    }

    final hasUpdate = toolResults.any(
      (r) => r['tool_name'] == 'update_transaction',
    );
    final hasCancel = toolResults.any(
      (r) => r['tool_name'] == 'cancel_pending_state',
    );

    if (hasUpdate) {
      await finance.addMessage("Data transaksi berhasil diperbarui! ✓", true);
      if (isChatExpanded) voice.speak("Data diperbarui");
    }

    if (hasCancel) {
      await finance.addMessage(
        "Transaksi yang tertunda telah dibatalkan. ✓",
        true,
      );
      if (isChatExpanded) voice.speak("Dibatalkan.");
    }

    if (recordedTxs.isNotEmpty) {
      await finance.addMessage("Transaksi Selesai & Dicatat ✓", true);
      String jsonStr = jsonEncode(recordedTxs);
      await finance.addMessage("RECEIPT_DATA", true, receiptData: jsonStr);
    }

    final clarifyTool = toolResults
        .where((r) => r['tool_name'] == 'ask_clarification')
        .firstOrNull;
    final remainingPendings = await finance.getAllPending();

    if (clarifyTool != null) {
      final q =
          clarifyTool['args']['question'] as String? ??
          "Bisa diperjelas lagi maksudnya?";
      await finance.addMessage(q, true);
      if (isChatExpanded) voice.speak(q);
    } else if (interactiveQuestions.isNotEmpty) {
      await finance.addMessage(interactiveQuestions.join("\n"), true);
      if (isChatExpanded && recordedTxs.isEmpty)
        voice.speak("Mohon lengkapi datanya.");
    } else if (intercepted) {
      await finance.addMessage("Berapa nominal/harganya?", true);
    } else if (remainingPendings.isNotEmpty) {
      String nextQ = remainingPendings.first.aiQuestion;
      await finance.addMessage("Masih ada yang tertunda:\n$nextQ", true);
      if (isChatExpanded) voice.speak("Masih ada transaksi tertunda.");
    } else if (recordedTxs.isNotEmpty) {
      if (isChatExpanded) voice.speak("Semua transaksi berhasil dicatat");
    } else if (!hasUpdate && !hasCancel) {
      await finance.addMessage("Proses Selesai! ✓", true);
    }
  }

  String _formatRupiah(int amount) {
    final str = amount.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  String _compactNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toInt().toString();
  }

  // --- HELPER IKON BARU (SINKRONISASI KE DASBOR) ---
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Groceries':
        return Icons.local_grocery_store;
      case 'Transport':
        return Icons.two_wheeler;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Health':
        return Icons.medical_services;
      case 'Entertainment':
        return Icons.sports_esports;
      case 'Bills':
        return Icons.receipt;
      case 'EWallet':
        return Icons.account_balance_wallet;
      case 'Education':
        return Icons.school;
      case 'Charity':
        return Icons.volunteer_activism;
      case 'Investment':
        return Icons.trending_up;
      case 'Salary':
        return Icons.payments;
      case 'Business':
        return Icons.store;
      case 'Transfer_In':
        return Icons.south_west;
      case 'Transfer_Out':
        return Icons.north_east;
      default:
        return Icons.category;
    }
  }

  String _formatDateForTile(String isoDate) {
    if (isoDate.isEmpty) return "Waktu tidak diketahui";
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Ags',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      final day = date.day.toString().padLeft(2, '0');
      final month = months[date.month - 1];
      final year = date.year;
      final hh = date.hour.toString().padLeft(2, '0');
      final mm = date.minute.toString().padLeft(2, '0');
      return "$day $month $year • $hh:$mm";
    } catch (_) {
      return isoDate;
    }
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
                "Analisis 7 Hari Terakhir",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              _buildChart(finance),

              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Histori Transaksi",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransactionHistoryScreen(),
                      ),
                    ),
                    child: const Text(
                      "Lihat Semua",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
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
    if (finance.history.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("Belum ada data untuk ditampilkan")),
      );
    }

    final now = DateTime.now();
    final justToday = DateTime(now.year, now.month, now.day);

    List<double> inData = List.filled(7, 0.0);
    List<double> outData = List.filled(7, 0.0);
    List<String> xLabels = List.filled(7, '');

    for (int i = 0; i < 7; i++) {
      final targetDate = justToday.subtract(Duration(days: 6 - i));
      xLabels[i] = "${targetDate.day}/${targetDate.month}";
    }

    double maxY = 0;

    for (var tx in finance.history) {
      final dateStr = tx['date'] as String?;
      if (dateStr == null) continue;
      final txDate = DateTime.tryParse(dateStr)?.toLocal();
      if (txDate == null) continue;

      final justTx = DateTime(txDate.year, txDate.month, txDate.day);
      final diff = justToday.difference(justTx).inDays;

      if (diff >= 0 && diff <= 6) {
        final index = 6 - diff;
        final amt = (tx['amount'] as int).toDouble();
        if (tx['type'] == 'OUT') {
          outData[index] += amt;
        } else {
          inData[index] += amt;
        }
      }
    }

    for (var val in inData) if (val > maxY) maxY = val;
    for (var val in outData) if (val > maxY) maxY = val;

    maxY = maxY > 0 ? maxY * 1.2 : 1000;

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < 7; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 4,
          barRods: [
            BarChartRodData(
              toY: inData[i],
              color: Colors.teal,
              width: 10,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: outData[i],
              color: Colors.orange,
              width: 10,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.only(right: 15, left: 0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < 7) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        xLabels[idx],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: maxY / 4 == 0 ? 1 : maxY / 4,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(
                    _compactNumber(value),
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4 == 0 ? 1 : maxY / 4,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          barGroups: barGroups,
        ),
      ),
    );
  }

  Widget _buildHistoryList(FinanceProvider finance) {
    final latestTransactions = finance.history.take(5).toList();

    if (latestTransactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: Center(
          child: Text("Belum ada data", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: latestTransactions.length,
      itemBuilder: (context, i) {
        final item = latestTransactions[i];
        final isIn = item['type'] == 'IN';
        final amountColor = isIn ? Colors.green : Colors.red;
        final amountPrefix = isIn ? "Rp" : "-Rp";
        final arrowIcon = isIn ? Icons.arrow_upward : Icons.arrow_downward;
        final note = item['note']?.toString() ?? 'Transaksi';
        final category = item['category']?.toString() ?? 'Other';
        final dateStr = item['date']?.toString() ?? '';
        final amount = item['amount'] as int? ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: Colors.black87,
                  size: 22,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateForTile(dateStr),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "$amountPrefix${_formatRupiah(amount)}",
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: amountColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(arrowIcon, color: amountColor, size: 12),
                  ),
                ],
              ),
            ],
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
    final int listCount =
        finance.chatHistory.length + (finance.isAiThinking ? 1 : 0);

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
              itemCount: listCount,
              itemBuilder: (context, i) {
                if (i == finance.chatHistory.length)
                  return const AnimatedThinkingBubble();

                final m = finance.chatHistory[i];
                final isAi = m['isAi'] == 1;

                if (isAi && m['receiptData'] != null) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: ReceiptCard(receiptJson: m['receiptData']),
                  );
                }

                if (isAi &&
                    m.containsKey('queryResult') &&
                    m['queryResult'] != null) {
                  VizType parsedVizType = VizType.auto;
                  try {
                    parsedVizType = VizType.values.firstWhere(
                      (e) =>
                          e.toString().split('.').last ==
                          (m['vizType']?.toString() ?? 'auto'),
                      orElse: () => VizType.auto,
                    );
                  } catch (_) {}
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: QueryResultCard(
                      aiSummary: m['text'] ?? "",
                      result: m['queryResult'] as RawQueryResult,
                      vizType: parsedVizType,
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
