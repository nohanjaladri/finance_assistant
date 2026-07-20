/// home_screen.dart (v2)
/// Dashboard utama dengan tab Tunai / Non Tunai / Sharing (kondisional)
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../data/models/transaction_model.dart';
import '../../data/services/backend_ai_service.dart';
import '../../data/services/supabase_service.dart';
import '../../data/services/voice_service.dart';
import '../providers/finance_provider.dart';
import '../widgets/query_result_card.dart';
import '../widgets/receipt_card.dart';
import 'auth_screens.dart';
import 'settings_profile_screens.dart';
import 'transaction_history_screen.dart';
import 'transaction_detail_screen.dart';
import '../../core/utils/amount_parser.dart';

// ============================================================
// HOME SCREEN — TabController master
// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Tabs
  late TabController _tabController;
  int _prevTabCount = 2;

  // Chat
  bool _isChatExpanded = false;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _showScrollToBottom = false;
  DateTime? _lastBackPressed;
  String? _voicePreviewText;

  // Scaffold drawer key
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _chatScrollController.addListener(_onChatScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceProvider>().addListener(_onProviderChanged);
      _updateActiveChatType();
    });
  }

  void _onTabChanged() {
    _updateActiveChatType();
  }

  void _updateActiveChatType() {
    if (!mounted) return;
    final finance = context.read<FinanceProvider>();
    String type;
    if (_tabController.index == 0) {
      type = 'tunai';
    } else if (_tabController.index == 1) {
      type = 'non_tunai';
    } else {
      type = 'sharing';
    }
    finance.setActiveChatType(type);
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final finance = context.read<FinanceProvider>();
    final newCount = finance.isSharingConnected ? 3 : 2;
    if (newCount != _prevTabCount) {
      _prevTabCount = newCount;
      final currentIndex = _tabController.index;
      _tabController.removeListener(_onTabChanged);
      _tabController.dispose();
      _tabController = TabController(
        length: newCount,
        vsync: this,
        initialIndex: currentIndex.clamp(0, newCount - 1),
      );
      _tabController.addListener(_onTabChanged);
      _updateActiveChatType();
      setState(() {});
    }
  }

  void _onChatScroll() {
    if (_chatScrollController.hasClients) {
      final max = _chatScrollController.position.maxScrollExtent;
      final cur = _chatScrollController.offset;
      final show = (max - cur) > 150;
      if (_showScrollToBottom != show) {
        setState(() => _showScrollToBottom = show);
      }
    }
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuart,
        );
      }
    });
  }

  void _jumpChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.jumpTo(_chatScrollController.position.maxScrollExtent);
      }
    });
  }

  void _toggleChat(bool open) {
    setState(() => _isChatExpanded = open);
    if (open) _scrollChatToBottom();
  }

  @override
  void dispose() {
    context.read<FinanceProvider>().removeListener(_onProviderChanged);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _textController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================
  Future<void> _sendMessage({String? customText}) async {
    final text = (customText ?? _textController.text).trim();
    if (text.isEmpty) return;
    if (customText == null) {
      _textController.clear();
    }

    final finance = context.read<FinanceProvider>();
    final voice = context.read<VoiceService>();

    // Add user message to UI
    await finance.addMessage(text, false);
    finance.setAiThinking(true);
    _scrollChatToBottom();

    try {
      final response = await BackendAiService().sendMessage(
        text,
        userId: SupabaseService.instance.currentUserId,
      );
      if (response != null) {
        // Show AI reply
        await finance.addMessage(response.reply, true);
        if (_isChatExpanded) {
          voice.speak(response.reply);
        }

        // Refresh data from Supabase since the backend already inserted the transaction
        if (response.intent == 'ADD_EXPENSE' ||
            response.intent == 'ADD_INCOME') {
          await finance.refreshAll();
        }
      } else {
        await finance.addMessage("Maaf, gagal terhubung ke backend AI.", true);
      }
    } catch (e) {
      debugPrint("Error sending message to backend: $e");
      await finance.addMessage(
        "Terjadi kesalahan sistem saat menghubungi AI.",
        true,
      );
    } finally {
      finance.setAiThinking(false);
      _scrollChatToBottom();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final tabCount = finance.isSharingConnected ? 3 : 2;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isChatExpanded) {
          _toggleChat(false);
          return;
        }
        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Tekan lagi untuk keluar"),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(20),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF4F6FC),
        drawer: _buildDrawer(finance),
        body: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(finance, tabCount),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: finance.refreshAll,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _TunaiTab(finance: finance),
                        _NonTunaiTab(finance: finance),
                        if (tabCount == 3) _SharingTab(finance: finance),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // AI Chat panel overlay
            _buildChatPanel(finance),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR with tabs
  // ============================================================
  Widget _buildAppBar(FinanceProvider finance, int tabCount) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5E5CE6), Color(0xFF8C52FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const Expanded(
                    child: Text(
                      "Dompetku AI",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  // Sync indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (finance.syncStatus == SyncStatus.syncing)
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white,
                            ),
                          )
                        else
                          Icon(
                            finance.syncStatus == SyncStatus.error
                                ? Icons.cloud_off_rounded
                                : Icons.cloud_done_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        const SizedBox(width: 4),
                        Text(
                          finance.syncStatus == SyncStatus.syncing
                              ? "Sync..."
                              : finance.syncStatus == SyncStatus.error
                              ? "Offline"
                              : "Tersimpan",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Chat button
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isChatExpanded
                              ? Icons.chat_bubble_rounded
                              : Icons.chat_bubble_outline_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => _toggleChat(!_isChatExpanded),
                      ),
                      if (finance.pendingCount > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                finance.pendingCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Tab bar
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                const Tab(
                  icon: Icon(Icons.payments_rounded, size: 18),
                  text: "Tunai",
                  iconMargin: EdgeInsets.only(bottom: 2),
                ),
                const Tab(
                  icon: Icon(Icons.credit_card_rounded, size: 18),
                  text: "Non Tunai",
                  iconMargin: EdgeInsets.only(bottom: 2),
                ),
                if (tabCount == 3)
                  const Tab(
                    icon: Icon(Icons.group_rounded, size: 18),
                    text: "Sharing",
                    iconMargin: EdgeInsets.only(bottom: 2),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DRAWER (Hamburger Menu)
  // ============================================================
  Widget _buildDrawer(FinanceProvider finance) {
    final user = SupabaseService.instance.currentUser;
    final email = user?.email ?? "pengguna@email.com";

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5E5CE6), Color(0xFF8C52FF)],
              ),
            ),
            accountName: const Text(
              "Dompetku AI",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                email.isNotEmpty ? email[0].toUpperCase() : "D",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5E5CE6),
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text("Profil Saya"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_rounded),
            title: const Text("Riwayat Transaksi"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TransactionHistoryScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text("Pengaturan"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const Divider(height: 1),
          // SHARING — Di dalam Pengaturan (bisa juga taruh langsung di drawer)
          ListTile(
            leading: Icon(
              Icons.group_rounded,
              color: finance.isSharingConnected
                  ? const Color(0xFF009688)
                  : Colors.grey,
            ),
            title: const Text("Dompet Bersama"),
            subtitle: Text(
              finance.isSharingConnected
                  ? "Terhubung: ${finance.activeRoom?.name ?? 'Room'}"
                  : "Belum terhubung",
              style: TextStyle(
                fontSize: 12,
                color: finance.isSharingConnected
                    ? const Color(0xFF009688)
                    : Colors.grey,
              ),
            ),
            trailing: finance.isSharingConnected
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF009688),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "AKTIF",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const Spacer(),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              "Keluar",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () async {
              Navigator.pop(context);
              await SupabaseService.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ============================================================
  // AI CHAT PANEL (Overlay)
  // ============================================================
  Widget _buildChatPanel(FinanceProvider finance) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      bottom: 0,
      left: 0,
      right: 0,
      top: _isChatExpanded ? 0 : null,
      child: Container(
        height: _isChatExpanded ? null : 0,
        decoration: const BoxDecoration(
          color: Color(0xFFF4F6FC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x20000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: _isChatExpanded
            ? SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Chat handle bar
                    GestureDetector(
                      onTap: () => _toggleChat(false),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.chat_bubble_rounded,
                                  color: Color(0xFF5E5CE6),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  "Asisten AI",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E1E2C),
                                  ),
                                ),
                                if (finance.isAiThinking) ...[
                                  const SizedBox(width: 8),
                                  const _ThinkingDots(),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    // Messages
                    Expanded(
                      child: ListView.builder(
                        controller: _chatScrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: finance.chatHistory.length +
                            (_voicePreviewText != null ? 1 : 0) +
                            (finance.isAiThinking ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i < finance.chatHistory.length) {
                            return _buildMessageBubble(finance.chatHistory[i]);
                          }
                          final offsetIndex = i - finance.chatHistory.length;
                          if (_voicePreviewText != null && offsetIndex == 0) {
                            return _buildPreviewBubble(_voicePreviewText!);
                          }
                          return const _ThinkingBubble();
                        },
                      ),
                    ),
                    // Input area
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 12,
                        bottom: 12,
                      ),
                      child: Row(
                        children: [
                          // Voice button
                          _buildVoiceButton(),
                          const SizedBox(width: 8),
                          // Text input
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              onSubmitted: (_) => _sendMessage(),
                              textInputAction: TextInputAction.send,
                              decoration: InputDecoration(
                                hintText: "Ketik atau ucapkan transaksi...",
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF4F6FC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Send button
                          GestureDetector(
                            onTap: _sendMessage,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF5E5CE6),
                                    Color(0xFF8C52FF),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildVoiceButton() {
    final voice = context.watch<VoiceService>();
    return GestureDetector(
      onTap: () async {
        if (voice.isListening) {
          await voice.stopListening();
          setState(() {
            _voicePreviewText = null;
          });
        } else {
          await voice.startListening(
            onResult: (text, isFinal) {
              if (text.isNotEmpty) {
                setState(() {
                  _voicePreviewText = text;
                });
                _jumpChatToBottom();
              }
              if (isFinal) {
                setState(() {
                  _voicePreviewText = null;
                });
                _sendMessage(customText: text);
              }
            },
          );
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: voice.isListening ? Colors.red.shade100 : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          voice.isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
          color: voice.isListening ? Colors.red : Colors.grey.shade600,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildPreviewBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF5E5CE6).withOpacity(0.6),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic_none_rounded, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
               ),
             ),
           ],
         ),
       ),
     );
   }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isAi = msg['is_ai'] as bool? ?? (msg['isAi'] == 1);
    final text = msg['text'] as String? ?? '';
    final receiptData = msg['receipt_data'];
    final queryResult = msg['query_result'];
    final vizType = msg['viz_type'] as String? ?? 'auto';

    if (text == 'RECEIPT_DATA' && receiptData != null) {
      Map<String, dynamic> data = {};
      if (receiptData is String) {
        try {
          data = jsonDecode(receiptData);
        } catch (_) {}
      } else if (receiptData is Map) {
        data = Map<String, dynamic>.from(receiptData);
      }
      return ReceiptCard(receiptData: data);
    }

    if (queryResult != null) {
      return QueryResultCard(
        aiSummary: text,
        queryResult: queryResult is Map
            ? Map<String, dynamic>.from(queryResult)
            : {},
        vizType: vizTypeFromString(vizType),
      );
    }

    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isAi ? Colors.white : const Color(0xFF5E5CE6),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isAi
                ? const Radius.circular(4)
                : const Radius.circular(18),
            bottomRight: isAi
                ? const Radius.circular(18)
                : const Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isAi ? const Color(0xFF1E1E2C) : Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TUNAI TAB
// ============================================================
class _TunaiTab extends StatelessWidget {
  final FinanceProvider finance;
  const _TunaiTab({required this.finance});

  @override
  Widget build(BuildContext context) {
    return _TransactionTab(
      transactions: finance.tunaiTransactions,
      totalIn: finance.tunaiIn,
      totalOut: finance.tunaiOut,
      label: "Tunai",
      color: const Color(0xFF27AE60),
      emptyIcon: Icons.payments_outlined,
      emptyMsg:
          "Belum ada transaksi tunai.\nCoba ucapkan ke AI: \"beli makan 20rb\"",
    );
  }
}

// ============================================================
// NON TUNAI TAB
// ============================================================
class _NonTunaiTab extends StatelessWidget {
  final FinanceProvider finance;
  const _NonTunaiTab({required this.finance});

  @override
  Widget build(BuildContext context) {
    return _TransactionTab(
      transactions: finance.nonTunaiTransactions,
      totalIn: finance.nonTunaiIn,
      totalOut: finance.nonTunaiOut,
      label: "Non Tunai",
      color: const Color(0xFF2980B9),
      emptyIcon: Icons.credit_card_outlined,
      emptyMsg:
          "Belum ada transaksi non tunai.\nCoba: \"bayar listrik via gopay 150rb\"",
    );
  }
}

// ============================================================
// SHARING TAB
// ============================================================
class _SharingTab extends StatelessWidget {
  final FinanceProvider finance;
  const _SharingTab({required this.finance});

  @override
  Widget build(BuildContext context) {
    return _TransactionTab(
      transactions: finance.sharedTransactions,
      totalIn: finance.sharedTotalIn,
      totalOut: finance.sharedTotalOut,
      label: "Bersama",
      color: const Color(0xFF009688),
      emptyIcon: Icons.group_outlined,
      emptyMsg:
          "Belum ada transaksi bersama.\nAjak teman untuk mencatat bersama!",
    );
  }
}

// ============================================================
// GENERIC TRANSACTION TAB CONTENT
// ============================================================
class _TransactionTab extends StatefulWidget {
  final List<TransactionModel> transactions;
  final int totalIn;
  final int totalOut;
  final String label;
  final Color color;
  final IconData emptyIcon;
  final String emptyMsg;

  const _TransactionTab({
    required this.transactions,
    required this.totalIn,
    required this.totalOut,
    required this.label,
    required this.color,
    required this.emptyIcon,
    required this.emptyMsg,
  });

  @override
  State<_TransactionTab> createState() => _TransactionTabState();
}

class _TransactionTabState extends State<_TransactionTab> {
  bool _showChartAnim = false;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _showChartAnim = true);
    });
  }

  @override
  void didUpdateWidget(covariant _TransactionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactions.length != widget.transactions.length ||
        oldWidget.totalIn != widget.totalIn ||
        oldWidget.totalOut != widget.totalOut) {
      _refreshKey++;
      _showChartAnim = false;
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) setState(() => _showChartAnim = true);
      });
    }
  }

  String _formatRupiah(int amount) {
    final isNegative = amount < 0;
    final str = amount.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return "${isNegative ? '-' : ''}Rp ${buf.toString()}";
  }

  String _compactAmount(int amount) {
    if (amount >= 1000000) {
      return "Rp ${(amount / 1000000).toStringAsFixed(1)}jt";
    } else if (amount >= 1000) {
      return "Rp ${(amount ~/ 1000)}rb";
    }
    return "Rp $amount";
  }

  String _compactNumber(double value) {
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}jt";
    } else if (value >= 1000) {
      return "${(value ~/ 1000)}rb";
    }
    return value.toInt().toString();
  }

  List<dynamic> _buildGroupedList(List<TransactionModel> transactions) {
    List<dynamic> grouped = [];
    String currentGroup = "";
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var tx in transactions) {
      final txDate = tx.createdAt.toLocal();
      final justTx = DateTime(txDate.year, txDate.month, txDate.day);
      final diff = today.difference(justTx).inDays;

      String groupName = "";
      if (diff == 0) {
        groupName = "Hari Ini";
      } else if (diff == 1) {
        groupName = "Kemarin";
      } else if (diff > 1 && diff <= 7) {
        groupName = "Minggu Ini";
      } else if (diff > 7 && diff <= 14) {
        groupName = "Minggu Lalu";
      } else {
        final months = [
          'Januari',
          'Februari',
          'Maret',
          'April',
          'Mei',
          'Juni',
          'Juli',
          'Agustus',
          'September',
          'Oktober',
          'November',
          'Desember',
        ];
        groupName = "${months[txDate.month - 1]} ${txDate.year}";
      }

      if (groupName != currentGroup) {
        grouped.add(groupName);
        currentGroup = groupName;
      }
      grouped.add(tx);
    }
    return grouped;
  }

  Widget _buildHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      margin: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(0xFFA0A5BA),
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showActionModal(BuildContext context, TransactionModel item) {
    final finance = context.read<FinanceProvider>();
    final int id = item.id ?? -1;
    if (id == -1) return;
    final String currentNote = item.note;
    final int currentAmount = item.amount;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.only(
            bottom: 30,
            top: 12,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Opsi Transaksi",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1E2C),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5E5CE6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Color(0xFF5E5CE6),
                  ),
                ),
                title: const Text(
                  "Edit Transaksi",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditDialog(
                    context,
                    finance,
                    id,
                    currentNote,
                    currentAmount,
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF647C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: Color(0xFFFF647C),
                  ),
                ),
                title: const Text(
                  "Hapus Transaksi",
                  style: TextStyle(
                    color: Color(0xFFFF647C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirmation(context, finance, id, currentNote);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    FinanceProvider finance,
    int id,
    String note,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Hapus Transaksi?",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          "Apakah Anda yakin ingin menghapus '$note' secara permanen?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Batal",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF647C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () {
              finance.deleteTransactionManual(id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Transaksi dihapus"),
                  backgroundColor: Color(0xFFFF647C),
                ),
              );
            },
            child: const Text(
              "Hapus",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    FinanceProvider finance,
    int id,
    String oldNote,
    int oldAmount,
  ) {
    final noteCtrl = TextEditingController(text: oldNote);
    final amountCtrl = TextEditingController(text: oldAmount.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Edit Transaksi",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: "Nama Transaksi",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Nominal (Rp)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Batal",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E5CE6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () {
              final newNote = noteCtrl.text.trim();
              final newAmt =
                  int.tryParse(
                    AmountParser.cleanNumberString(amountCtrl.text),
                  ) ??
                  0;
              if (newNote.isNotEmpty && newAmt > 0) {
                finance.updateTransactionManual(id, newAmt, newNote);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Data diperbarui"),
                    backgroundColor: Color(0xFF00C48C),
                  ),
                );
              }
            },
            child: const Text(
              "Simpan",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (widget.transactions.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Text(
            "Belum ada data 7 hari terakhir",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final justToday = DateTime(now.year, now.month, now.day);

    List<double> inData = List.filled(7, 0.0);
    List<double> outData = List.filled(7, 0.0);
    List<String> xLabels = List.filled(7, '');

    final List<String> hariIndo = [
      'Sen',
      'Sel',
      'Rab',
      'Kam',
      'Jum',
      'Sab',
      'Min',
    ];

    for (int i = 0; i < 7; i++) {
      final targetDate = justToday.subtract(Duration(days: 6 - i));
      xLabels[i] = hariIndo[targetDate.weekday - 1];
    }

    double maxY = 0;

    for (var tx in widget.transactions) {
      final txDate = tx.createdAt;
      final justTx = DateTime(txDate.year, txDate.month, txDate.day);
      final diff = justToday.difference(justTx).inDays;

      if (diff >= 0 && diff <= 6) {
        final index = 6 - diff;
        final amt = tx.amount.toDouble();
        if (tx.type.value == 'OUT') {
          outData[index] += amt;
        } else {
          inData[index] += amt;
        }
      }
    }

    for (var val in inData) {
      if (val > maxY) maxY = val;
    }
    for (var val in outData) {
      if (val > maxY) maxY = val;
    }

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
      height: 220,
      padding: const EdgeInsets.only(top: 20, right: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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

  @override
  Widget build(BuildContext context) {
    final saldo = widget.totalIn - widget.totalOut;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Balance Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.color, widget.color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Saldo ${widget.label}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                key: ValueKey<int>(_refreshKey),
                tween: Tween<double>(begin: 0, end: saldo.toDouble()),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  final isMinus = saldo < 0;
                  return Text(
                    _formatRupiah(value.toInt()),
                    style: TextStyle(
                      color: isMinus ? const Color(0xFFFF8A8A) : Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_downward_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Masuk",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              TweenAnimationBuilder<double>(
                                key: ValueKey<int>(_refreshKey),
                                tween: Tween<double>(
                                  begin: 0,
                                  end: widget.totalIn.toDouble(),
                                ),
                                duration: const Duration(milliseconds: 1500),
                                curve: Curves.easeOutQuart,
                                builder: (context, value, child) {
                                  return Text(
                                    _compactAmount(value.toInt()),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Keluar",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              TweenAnimationBuilder<double>(
                                key: ValueKey<int>(_refreshKey),
                                tween: Tween<double>(
                                  begin: 0,
                                  end: widget.totalOut.toDouble(),
                                ),
                                duration: const Duration(milliseconds: 1500),
                                curve: Curves.easeOutQuart,
                                builder: (context, value, child) {
                                  return Text(
                                    _compactAmount(value.toInt()),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Chart Section
        Text(
          "Analisis 7 Hari Terakhir",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        _buildChart(),
        const SizedBox(height: 24),
        // Transaction list
        if (widget.transactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(widget.emptyIcon, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    widget.emptyMsg,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Transaksi Terakhir",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                "${widget.transactions.length} transaksi",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ..._buildGroupedList(widget.transactions.take(5).toList()).map((
            item,
          ) {
            if (item is String) {
              return _buildHeader(item);
            } else {
              final tx = item as TransactionModel;
              return _TransactionTile(
                tx: tx,
                accentColor: widget.color,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionDetailScreen(transaction: tx),
                    ),
                  );
                },
              );
            }
          }),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Lihat Riwayat Lainnya",
                  style: TextStyle(
                    color: widget.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: widget.color),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final Color accentColor;
  final VoidCallback? onTap;

  const _TransactionTile({
    required this.tx,
    required this.accentColor,
    this.onTap,
  });

  IconData _getCategoryIcon(String category, bool isIn) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'groceries':
        return Icons.shopping_basket_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'salary':
        return Icons.payments_rounded;
      case 'bills':
      case 'utilities':
        return Icons.receipt_long_rounded;
      case 'transfer_in':
      case 'transfer_out':
        return Icons.swap_horiz_rounded;
      case 'entertainment':
        return Icons.movie_filter_rounded;
      default:
        return isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    }
  }

  Color _getCategoryColor(String category, bool isIn) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFFF9F0A); // Apple Orange
      case 'groceries':
        return const Color(0xFF30D158); // Apple Green
      case 'transport':
        return const Color(0xFF5E5CE6); // Apple Indigo
      case 'shopping':
        return const Color(0xFFBF5AF2); // Apple Purple
      case 'salary':
        return const Color(0xFF34C759); // Apple Money Green
      case 'bills':
      case 'utilities':
        return const Color(0xFFFF453A); // Apple Red
      case 'transfer_in':
      case 'transfer_out':
        return const Color(0xFF64D2FF); // Apple Sky Blue
      case 'entertainment':
        return const Color(0xFFFF375F); // Apple Pink
      default:
        return isIn ? const Color(0xFF34C759) : const Color(0xFFFF453A);
    }
  }

  String _formatDate(DateTime dt) {
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
    return "${dt.day} ${months[dt.month - 1]} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final isIn = tx.type == TransactionType.income;
    final amt = tx.amount;
    final iconColor = _getCategoryColor(tx.category, isIn);
    final iconData = _getCategoryIcon(tx.category, isIn);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.note,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1E1E2C),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tx.category,
                            style: TextStyle(
                              fontSize: 10,
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(tx.createdAt.toLocal()),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Amount
              Text(
                "${isIn ? '+' : '-'} Rp ${_formatAmt(amt)}",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isIn ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ============================================================
// THINKING BUBBLE & DOTS
// ============================================================
class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF5E5CE6),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "AI sedang berpikir...",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots> {
  int _count = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (mounted) setState(() => _count = (_count + 1) % 4);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '.' * _count,
      style: const TextStyle(
        color: Color(0xFF5E5CE6),
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }
}

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

// (end of file)
