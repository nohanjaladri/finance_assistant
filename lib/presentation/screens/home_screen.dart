import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'settings_profile_screens.dart';
import '../../core/utils/amount_parser.dart';
import '../../core/utils/query_validator.dart';
import '../../data/database/database_helper.dart';
import '../../data/database/pending_request_helper.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/voice_service.dart';
import '../../data/services/auth_service.dart';
import '../providers/finance_provider.dart';
import '../widgets/query_result_card.dart';
import '../widgets/pending_reminder_card.dart';
import '../widgets/receipt_card.dart';
import 'transaction_history_screen.dart';
import 'auth_screens.dart';

// ==========================================
// WIDGET SKELETON
// ==========================================
class Skeleton extends StatefulWidget {
  final double? width, height;
  final BorderRadius? borderRadius;
  const Skeleton({super.key, this.width, this.height, this.borderRadius});
  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// ==========================================
// WIDGET CLOUD SYNC
// ==========================================
class CloudSyncIndicator extends StatelessWidget {
  final SyncStatus status;
  const CloudSyncIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: _buildIndicator(),
    );
  }

  Widget _buildIndicator() {
    switch (status) {
      case SyncStatus.syncing:
        return Container(
          key: const ValueKey("syncing"),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Menyinkronkan",
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      case SyncStatus.offline:
        return Container(
          key: const ValueKey("offline"),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Colors.redAccent,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                "Offline",
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      case SyncStatus.synced:
      default:
        return Container(
          key: const ValueKey("synced"),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_done_rounded,
                color: Colors.green,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                "Tersimpan",
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
    }
  }
}

// ==========================================
// BUBBLE BERPIKIR AI
// ==========================================
class AnimatedThinkingBubble extends StatefulWidget {
  final Color primaryColor;
  const AnimatedThinkingBubble({super.key, required this.primaryColor});
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
        margin: const EdgeInsets.only(bottom: 12, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: widget.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Sedang berpikir $dots",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// HOME SCREEN
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isChatExpanded = false;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  DateTime? _lastPressedAt;

  bool _showChartAnim = false;
  bool _isLoading = false;
  int _refreshKey = 0;
  bool _showScrollToBottom = false;

  late FinanceProvider _financeProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _financeProvider = context.read<FinanceProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _financeProvider.addListener(_onFinanceChanged);
    });

    _scrollController.addListener(_scrollListener);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _showChartAnim = true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _financeProvider.refreshData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _financeProvider.removeListener(_onFinanceChanged);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      final show = (maxScroll - currentScroll) > 150;
      if (_showScrollToBottom != show) {
        setState(() => _showScrollToBottom = show);
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isLoading = true;
      _showChartAnim = false;
    });

    await context.read<FinanceProvider>().refreshData();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _refreshKey++;
      });
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) setState(() => _showChartAnim = true);
      });
    }
  }

  void _toggleChat(bool open) {
    setState(() => isChatExpanded = open);
    if (open) {
      _scrollToBottom();
    } else {
      _handleRefresh();
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
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
    if (!isChatExpanded) _toggleChat(true);
    final finance = context.read<FinanceProvider>();
    finance.setWaitingDirectReply(true);
    finance.addMessage(pending.aiQuestion, true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  String _getApiKey() => dotenv.maybeGet('GROQ_API_KEY') ?? "";

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuart,
        );
      }
    });
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image == null) return;

      if (!isChatExpanded) _toggleChat(true);

      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      final finance = context.read<FinanceProvider>();
      await finance.addMessage("Memindai dan membaca gambar struk...", false);
      finance.setAiThinking(true);
      _scrollToBottom();

      final apiKey = _getApiKey();
      final aiService = AiService(apiKey: apiKey);

      final extractedText = await aiService.analyzeReceiptImage(base64Image);

      finance.setAiThinking(false);

      if (extractedText.contains("Terjadi kesalahan") ||
          extractedText.contains("Gagal")) {
        await finance.addMessage(extractedText, true);
        return;
      }

      final userMessage =
          "Tolong catat struk belanja ini ke database:\n$extractedText";
      await _processMessage(userMessage, isInternalProcess: true);
    } catch (e) {
      _showErrorSnackBar("Gagal memproses gambar: $e");
      context.read<FinanceProvider>().setAiThinking(false);
    }
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
        "[ID: ${p.id}] Barang: $nama | Harga: $nominal | Pertanyaan Aktif: '${p.aiQuestion}'",
      );
    }
    sb.writeln("===========================================");
    return sb.toString();
  }

  Future<void> _processMessage(
    String userText, {
    bool isInternalProcess = false,
  }) async {
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

    if (!isInternalProcess) {
      try {
        await finance.addMessage(userText, false);
      } catch (e) {
        _showErrorSnackBar("Gagal menyimpan pesan.");
        return;
      }
    }

    finance.setAiThinking(true);
    _scrollToBottom();

    try {
      final pendingContext = await _buildPendingContext(finance);
      final systemPrompt = aiService.buildSystemPrompt(pendingContext);

      final messages = [
        {"role": "system", "content": systemPrompt},
        ...finance.chatHistory
            .where(
              (m) =>
                  m['queryResult'] == null &&
                  m['receiptData'] == null &&
                  (m['text']?.toString().trim().isNotEmpty ?? false),
            )
            .takeLast(8)
            .map(
              (m) => {
                "role": m['isAi'] == 1 ? "assistant" : "user",
                "content": m['text'] as String,
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
        await finance.addMessage(content, true);
        if (isChatExpanded) voice.speak(content);
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException && e.response != null) {
        try {
          errorMessage = jsonEncode(e.response?.data);
        } catch (_) {
          errorMessage = e.response?.data.toString() ?? errorMessage;
        }
      }
      await finance.addMessage(
        "Maaf, sepertinya saya tidak mengerti maksudnya.\n\n[INFO ERROR UNTUK DEV]\n$errorMessage",
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
    Set<String> processedSignatures = {};

    List<String> otherReplies = [];
    String? firstTxAiReply;

    bool hasUpdatePending = false;
    bool hasCancelPending = false;

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
            final categoryId =
                args['category_id'] as String? ?? 'cat_other_out';

            if (firstTxAiReply == null || firstTxAiReply.isEmpty) {
              firstTxAiReply = args['friendly_reply']?.toString().trim();
            }

            try {
              await finance.addTransaction(finalAmount, note, type, categoryId);
              result = "success";
              recordedTxs.add({
                'note': note,
                'amount': finalAmount,
                'type': type,
              });

              if (finance.activeResolvingPending != null) {
                await finance.completePending(
                  finance.activeResolvingPending!.id,
                );
                finance.setActiveResolvingPending(null);
                hasUpdatePending = true;
              } else {
                final allPendings = await finance.getAllPending();
                for (var p in allPendings) {
                  if (p.nama != null &&
                      (note.toLowerCase().contains(p.nama!.toLowerCase()) ||
                          p.nama!.toLowerCase().contains(note.toLowerCase()))) {
                    await finance.completePending(p.id);
                    hasUpdatePending = true;
                  }
                }
              }
            } catch (_) {}
          } else {
            result = "skipped_duplicate";
          }
        }
      } else if (toolName == "record_receipt_items") {
        final merchant = args['merchant_name'] as String? ?? "Toko";
        final items = args['items'] as List<dynamic>? ?? [];
        for (var item in items) {
          final name = item['name'] as String? ?? "Barang";
          int price = 0;
          if (item['price'] != null) {
            price =
                int.tryParse(
                  AmountParser.cleanNumberString(item['price'].toString()),
                ) ??
                0;
          }
          final cat = item['category_id'] as String? ?? "cat_other_out";

          if (price > 0) {
            String sig = "${name.toLowerCase()}_$price";
            if (!processedSignatures.contains(sig)) {
              processedSignatures.add(sig);
              try {
                await finance.addTransaction(
                  price,
                  "$merchant: $name",
                  "OUT",
                  cat,
                );
                recordedTxs.add({
                  'note': "$merchant: $name",
                  'amount': price,
                  'type': "OUT",
                });
              } catch (_) {}
            }
          }
        }
        result = "receipt_saved";
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
          otherReplies.add(aiQuestion);
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
                  "cat_other_out",
                );
                recordedTxs.add({
                  'note': updatedNote,
                  'amount': updatedAmount,
                  'type': "OUT",
                });
              }
              await finance.completePending(pId);
              finance.setActiveResolvingPending(null);
              hasUpdatePending = true;
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
              if (nextQuestion.isNotEmpty) otherReplies.add(nextQuestion);
              result = "updated_still_pending";
            } catch (_) {}
          }
        }
      } else if (toolName == "cancel_pending_state") {
        int pId = int.tryParse(args['pending_id'].toString()) ?? -1;
        if (pId != -1) {
          await finance.cancelPending(pId);
          finance.setActiveResolvingPending(null);
          hasCancelPending = true;
          result = "cancelled";
        }
      } else if (toolName == "query_database") {
        result = "query_pending";
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

    List<String> finalMessagesToUser = [];

    if (hasCancelPending) {
      finalMessagesToUser.add("Oke, transaksi yang tadi kita batalkan ya. 🗑️");
    }

    if (recordedTxs.isNotEmpty) {
      if (recordedTxs.length == 1) {
        String reply = firstTxAiReply ?? "";
        if (reply.isEmpty) {
          final fallbacks = [
            "Sip! Transaksi untuk ${recordedTxs.first['note']} sebesar Rp ${_formatRupiah(recordedTxs.first['amount'])} sudah aku catat rapi di buku ya! 📝✨",
            "Oke, ${recordedTxs.first['note']} (Rp ${_formatRupiah(recordedTxs.first['amount'])}) berhasil ditambahkan. 💸",
          ];
          reply = fallbacks[Random().nextInt(fallbacks.length)];
        }

        if (hasUpdatePending) {
          finalMessagesToUser.add("Sempurna! $reply");
        } else {
          finalMessagesToUser.add(reply);
        }
      } else {
        List<String> notes = recordedTxs
            .map((t) => t['note'].toString())
            .toList();
        int totalAmount = recordedTxs.fold(
          0,
          (sum, t) => sum + (t['amount'] as int),
        );

        String joinedNotes;
        if (notes.length == 2) {
          joinedNotes = "${notes[0]} dan ${notes[1]}";
        } else {
          joinedNotes =
              "${notes.sublist(0, notes.length - 1).join(', ')}, dan ${notes.last}";
        }

        finalMessagesToUser.add(
          "Sip! Transaksi untuk $joinedNotes dengan total Rp ${_formatRupiah(totalAmount)} sudah aku catat semuanya ya! 📝✨",
        );
      }

      String jsonStr = jsonEncode(recordedTxs);
      await finance.addMessage("RECEIPT_DATA", true, receiptData: jsonStr);
    }

    if (otherReplies.isNotEmpty) {
      finalMessagesToUser.addAll(otherReplies);
    }

    if (finalMessagesToUser.isNotEmpty) {
      final finalReply = finalMessagesToUser.join("\n\n");
      await finance.addMessage(finalReply, true);
      if (isChatExpanded) voice.speak(finalReply);
    }

    // ====== PENTING: REFRESH DATA DASHBOARD SETELAH AI SELESAI ======
    if (recordedTxs.isNotEmpty || hasCancelPending || hasUpdatePending) {
      await finance.refreshData();
      if (mounted) {
        setState(() {
          _refreshKey++;
          _showChartAnim = false;
        });
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            setState(() => _showChartAnim = true);
          }
        });
      }
    }
    // ==================================================================
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
      String str = (value / 1000000).toStringAsFixed(1);
      if (str.endsWith('.0')) str = str.substring(0, str.length - 2);
      return '$str jt';
    } else if (value >= 1000) {
      String str = (value / 1000).toStringAsFixed(0);
      return '$str rb';
    }
    return value.toInt().toString();
  }

  IconData _parseIconData(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'two_wheeler':
        return Icons.two_wheeler;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'payments':
        return Icons.payments;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'medical_services':
        return Icons.medical_services;
      case 'school':
        return Icons.school;
      case 'trending_up':
        return Icons.trending_up;
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

  Widget _buildWorkspaceToggle(FinanceProvider finance, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double switchWidth = constraints.maxWidth;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                left: finance.isSharedMode ? switchWidth / 2 : 0,
                child: Container(
                  width: (switchWidth / 2) - 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (finance.isSharedMode) finance.toggleWorkspace();
                      },
                      child: Container(
                        height: 40,
                        color: Colors.transparent,
                        child: Center(
                          child: Text(
                            "Pribadi",
                            style: TextStyle(
                              color: !finance.isSharedMode
                                  ? primaryColor
                                  : Colors.grey.shade400,
                              fontWeight: !finance.isSharedMode
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!finance.isSharedMode) finance.toggleWorkspace();
                      },
                      child: Container(
                        height: 40,
                        color: Colors.transparent,
                        child: Center(
                          child: Text(
                            "Bersama",
                            style: TextStyle(
                              color: finance.isSharedMode
                                  ? primaryColor
                                  : Colors.grey.shade400,
                              fontWeight: finance.isSharedMode
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final Color primaryColor = finance.isSharedMode
        ? const Color(0xFF009688)
        : const Color(0xFF5E5CE6);
    final List<Color> cardGradient = finance.isSharedMode
        ? [const Color(0xFF00B4DB), const Color(0xFF0083B0)]
        : [const Color(0xFF5E5CE6), const Color(0xFF8C52FF)];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (isChatExpanded) {
          context.read<VoiceService>().stop();
          _toggleChat(false);
          return;
        }
        final now = DateTime.now();
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Tekan lagi untuk keluar',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF4F6FC),
        drawer: _buildSideMenu(primaryColor, finance),
        body: Stack(
          children: [
            _buildDashboard(finance, primaryColor, cardGradient),
            _buildChatPanel(finance, primaryColor, cardGradient),
          ],
        ),
      ),
    );
  }

  Widget _buildSideMenu(Color primaryColor, FinanceProvider finance) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? "pengguna@email.com";

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: primaryColor),
            accountName: const Text(
              "Dompetku AI User",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                email[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profil Saya'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Pengaturan'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.group_add_outlined),
            title: const Text(
              'Dompet Bersama',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "ACTIVE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showSharedWalletBottomSheet(primaryColor, finance);
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Keluar (Logout)',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () async {
              Navigator.pop(context);
              await AuthService().signOut();
              if (mounted)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showSharedWalletBottomSheet(
    Color primaryColor,
    FinanceProvider finance,
  ) {
    final TextEditingController joinController = TextEditingController();
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Dompet Bersama",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1E2C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Bagikan kode ini ke pasangan/teman Anda agar mereka bisa mengakses data di Mode Bersama.",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 30),

                    const Text(
                      "Kode Ruangan Anda:",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1E2C),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            finance.myRoomCode,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy_rounded, color: primaryColor),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: finance.myRoomCode),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Kode berhasil disalin!"),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "ATAU",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 30),

                    if (finance.isJoiningOtherRoom) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 40,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Anda sedang berada di Ruangan Teman",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                Navigator.pop(sheetContext);
                                await finance.leaveSharedRoom();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Kembali ke ruangan sendiri.",
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                "Keluar & Kembali ke Ruang Sendiri",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Text(
                        "Gabung ke Ruangan Teman:",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E1E2C),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: joinController,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 5,
                        decoration: InputDecoration(
                          hintText: "Masukkan 5 Digit Kode",
                          counterText: "",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: isProcessing
                                  ? null
                                  : () async {
                                      if (joinController.text.length != 5)
                                        return;
                                      setSheetState(() => isProcessing = true);

                                      bool success = await finance
                                          .joinSharedRoom(joinController.text);

                                      setSheetState(() => isProcessing = false);
                                      if (success) {
                                        Navigator.pop(sheetContext);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Berhasil gabung ke ruang teman!",
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Kode tidak ditemukan!",
                                            ),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    },
                              child: isProcessing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Gabung",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDashboard(
    FinanceProvider finance,
    Color primaryColor,
    List<Color> cardGradient,
  ) {
    return SafeArea(
      child: RefreshIndicator(
        color: primaryColor,
        backgroundColor: Colors.white,
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.menu_rounded,
                          size: 30,
                          color: Color(0xFF1E1E2C),
                        ),
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Dompetku",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E1E2C),
                        ),
                      ),
                    ],
                  ),
                  CloudSyncIndicator(status: finance.syncStatus),
                ],
              ),
              const SizedBox(height: 20),

              _buildWorkspaceToggle(finance, primaryColor),

              _isLoading
                  ? const Skeleton(
                      height: 220,
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    )
                  : _buildBalanceCard(finance, cardGradient, primaryColor),
              const SizedBox(height: 36),
              const Text(
                "Analisis Minggu Ini",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF1E1E2C),
                ),
              ),
              const SizedBox(height: 24),

              _isLoading
                  ? const Skeleton(
                      height: 240,
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    )
                  : _buildChart(finance),

              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Histori Transaksi",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Color(0xFF1E1E2C),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransactionHistoryScreen(),
                      ),
                    ),
                    child: Text(
                      "Lihat Semua",
                      style: TextStyle(
                        fontSize: 14,
                        color: primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? Column(
                      children: [
                        const Skeleton(
                          height: 80,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        const SizedBox(height: 16),
                        const Skeleton(
                          height: 80,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ],
                    )
                  : _buildHistoryList(finance),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    FinanceProvider finance,
    List<Color> cardGradient,
    Color primaryColor,
  ) {
    final saldo = finance.totalIn - finance.totalOut;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Saldo",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (finance.isJoiningOtherRoom)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.link, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        "Terhubung",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          TweenAnimationBuilder<double>(
            key: ValueKey<int>(_refreshKey),
            tween: Tween<double>(begin: 0, end: saldo.toDouble()),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutQuart,
            builder: (context, value, child) {
              final isNegative = value < 0;
              final prefix = isNegative ? "-Rp " : "Rp ";
              final textColor = isNegative ? Colors.redAccent : Colors.white;

              return Text(
                "$prefix${_formatRupiah(value.toInt())}",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: -1,
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sumColAnim("Pemasukan", finance.totalIn, Colors.greenAccent),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.2),
              ),
              _sumColAnim("Pengeluaran", finance.totalOut, Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sumColAnim(String label, int amount, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white60,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 4),
      TweenAnimationBuilder<double>(
        key: ValueKey<int>(_refreshKey),
        tween: Tween<double>(begin: 0, end: amount.toDouble()),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart,
        builder: (context, value, child) {
          return Text(
            "Rp ${_formatRupiah(value.toInt())}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 15,
            ),
          );
        },
      ),
    ],
  );

  Widget _buildChart(FinanceProvider finance) {
    if (finance.history.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Text(
            "Belum ada data minggu ini",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final justMonday = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    List<double> inData = List.filled(7, 0.0);
    List<double> outData = List.filled(7, 0.0);

    final List<String> xLabels = [
      'Sen',
      'Sel',
      'Rab',
      'Kam',
      'Jum',
      'Sab',
      'Min',
    ];

    double maxY = 0;

    for (var tx in finance.history) {
      final dateStr = tx['date'] as String?;
      if (dateStr == null) continue;
      final txDate = DateTime.tryParse(dateStr)?.toLocal();
      if (txDate == null) continue;

      final justTx = DateTime(txDate.year, txDate.month, txDate.day);
      final diff = justTx.difference(justMonday).inDays;

      if (diff >= 0 && diff <= 6) {
        final amt = (tx['amount'] as int).toDouble();
        if (tx['type'] == 'OUT') {
          outData[diff] += amt;
        } else {
          inData[diff] += amt;
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
          barsSpace: 6,
          barRods: [
            BarChartRodData(
              toY: _showChartAnim ? inData[i] : 0,
              color: const Color(0xFF00C48C),
              width: 10,
              borderRadius: BorderRadius.circular(6),
            ),
            BarChartRodData(
              toY: _showChartAnim ? outData[i] : 0,
              color: const Color(0xFFFF647C),
              width: 10,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 240,
      padding: const EdgeInsets.only(top: 20, right: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => const Color(0xFF1E1E2C),
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final isIncome = rodIndex == 0;
                final color = isIncome
                    ? const Color(0xFF00C48C)
                    : const Color(0xFFFF647C);
                final prefix = isIncome ? "+" : "-";
                return BarTooltipItem(
                  '$prefix Rp ${_formatRupiah(rod.toY.toInt())}',
                  TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
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
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < 7) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        xLabels[idx],
                        style: const TextStyle(
                          color: Color(0xFFA0A5BA),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
                reservedSize: 56,
                interval: maxY / 4 == 0 ? 1 : maxY / 4,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(
                      _compactNumber(value),
                      style: const TextStyle(
                        color: Color(0xFFA0A5BA),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade100,
              strokeWidth: 1.5,
              dashArray: [5, 5],
            ),
          ),
          barGroups: barGroups,
        ),
        swapAnimationDuration: const Duration(milliseconds: 1000),
        swapAnimationCurve: Curves.easeOutQuart,
      ),
    );
  }

  Widget _buildHistoryList(FinanceProvider finance) {
    final latestTransactions = finance.history.take(5).toList();

    if (latestTransactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            "Belum ada data transaksi",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: latestTransactions.length,
        itemBuilder: (context, i) {
          final item = latestTransactions[i];
          final isIn = item['type'] == 'IN';
          final amountColor = isIn
              ? const Color(0xFF00C48C)
              : const Color(0xFFFF647C);
          final amountPrefix = isIn ? "Rp" : "-Rp";
          final arrowIcon = isIn ? Icons.arrow_upward : Icons.arrow_downward;

          final note = item['note']?.toString() ?? 'Transaksi';
          final dateStr = item['date']?.toString() ?? '';
          final amount = item['amount'] as int? ?? 0;

          final categoryName = item['category_name']?.toString() ?? 'Lainnya';
          final categoryIconStr =
              item['category_icon']?.toString() ?? 'receipt_long';
          final parsedIcon = _parseIconData(categoryIconStr);

          return Container(
            margin: EdgeInsets.only(
              bottom: i == latestTransactions.length - 1 ? 0 : 20,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  child: Icon(
                    parsedIcon,
                    color: const Color(0xFF1E1E2C),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1E1E2C),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$categoryName • ${_formatDateForTile(dateStr)}",
                        style: const TextStyle(
                          color: Color(0xFFA0A5BA),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
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
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: amountColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(arrowIcon, color: amountColor, size: 12),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatPanel(
    FinanceProvider finance,
    Color primaryColor,
    List<Color> cardGradient,
  ) {
    return AnimatedAlign(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: isChatExpanded ? Alignment.center : Alignment.bottomCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.all(isChatExpanded ? 0 : 24),
        height: isChatExpanded ? MediaQuery.of(context).size.height : 65,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isChatExpanded ? 0 : 40),
          boxShadow: isChatExpanded
              ? null
              : [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isChatExpanded
              ? _buildFullChat(finance, primaryColor, cardGradient)
              : _buildMiniChat(primaryColor),
        ),
      ),
    );
  }

  Widget _buildMiniChat(Color primaryColor) => InkWell(
    onTap: () => _toggleChat(true),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.auto_awesome, color: primaryColor, size: 20),
        const SizedBox(width: 10),
        Text(
          "Tanya Asisten Finansial",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: primaryColor,
            fontSize: 16,
          ),
        ),
      ],
    ),
  );

  Widget _buildFullChat(
    FinanceProvider finance,
    Color primaryColor,
    List<Color> cardGradient,
  ) {
    final int listCount =
        finance.chatHistory.length + (finance.isAiThinking ? 1 : 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: primaryColor, size: 18),
                const SizedBox(width: 8),
                const Text(
                  "Asisten Finansial",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1E2C),
                  ),
                ),
              ],
            ),
            if (finance.activeResolvingPending != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '📝 "${finance.activeResolvingPending!.nama ?? finance.activeResolvingPending!.originalInput}"',
                  style: TextStyle(
                    fontSize: 11,
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF1E1E2C),
            size: 30,
          ),
          onPressed: () => _toggleChat(false),
        ),
        actions: const [PendingBadge()],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  itemCount: listCount,
                  itemBuilder: (context, i) {
                    if (i == finance.chatHistory.length)
                      return AnimatedThinkingBubble(primaryColor: primaryColor);

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
                          originalQuestion:
                              m['originalQuestion'] as String? ?? "",
                        ),
                      );
                    }

                    return Align(
                      alignment: isAi
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          gradient: isAi
                              ? null
                              : LinearGradient(colors: cardGradient),
                          color: isAi ? Colors.white : null,
                          boxShadow: isAi
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomRight: Radius.circular(isAi ? 20 : 5),
                            bottomLeft: Radius.circular(isAi ? 5 : 20),
                          ),
                        ),
                        child: Text(
                          m['text'] ?? "",
                          style: TextStyle(
                            color: isAi
                                ? const Color(0xFF1E1E2C)
                                : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildInputArea(finance, primaryColor, cardGradient),
            ],
          ),
          Positioned(
            bottom: 110,
            right: 20,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showScrollToBottom ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !_showScrollToBottom,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  elevation: 4,
                  onPressed: _scrollToBottom,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: primaryColor,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(
    FinanceProvider finance,
    Color primaryColor,
    List<Color> cardGradient,
  ) {
    final voice = Provider.of<VoiceService>(context);
    final isWaiting = finance.isWaitingDirectReply;

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (finance.activeResolvingPending != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isWaiting ? primaryColor.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isWaiting ? primaryColor : Colors.grey.shade300,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    isWaiting ? Icons.reply : Icons.pending_actions,
                    size: 16,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      finance.activeResolvingPending!.aiQuestion,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E1E2C),
                        fontWeight: FontWeight.w600,
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
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                // --- PERBAIKAN UI: Tombol '+' untuk memunculkan Bottom Sheet Kamera & Galeri ---
                IconButton(
                  padding: const EdgeInsets.only(left: 8),
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: primaryColor.withOpacity(0.8),
                    size: 28,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (bottomSheetContext) => Container(
                        padding: const EdgeInsets.only(
                          top: 10,
                          bottom: 30,
                          left: 20,
                          right: 20,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  color: primaryColor,
                                ),
                              ),
                              title: const Text(
                                "Ambil dari Kamera",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              onTap: () {
                                Navigator.pop(bottomSheetContext);
                                _pickAndProcessImage(ImageSource.camera);
                              },
                            ),
                            const SizedBox(height: 8),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.photo_library_rounded,
                                  color: primaryColor,
                                ),
                              ),
                              title: const Text(
                                "Pilih dari Galeri",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              onTap: () {
                                Navigator.pop(bottomSheetContext);
                                _pickAndProcessImage(ImageSource.gallery);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E1E2C),
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 18,
                      ),
                      hintText: isWaiting
                          ? "Ketik jawaban..."
                          : finance.activeResolvingPending != null
                          ? "Ketik jawaban..."
                          : "Ketik transaksi...",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (text) {
                      setState(() {});
                    },
                    onSubmitted: (v) {
                      _processMessage(v);
                      _textController.clear();
                      setState(() {});
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: cardGradient),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        if (_textController.text.isNotEmpty) {
                          _processMessage(_textController.text);
                          _textController.clear();
                          setState(() {});
                        } else {
                          voice.startListening(
                            onResult: (t, f) {
                              _textController.text = t;
                              if (f) {
                                _processMessage(t);
                                _textController.clear();
                                setState(() {});
                              }
                            },
                          );
                        }
                      },
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                        child: Icon(
                          _textController.text.isNotEmpty
                              ? Icons.send_rounded
                              : Icons.mic_rounded,
                          key: ValueKey<bool>(_textController.text.isNotEmpty),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
