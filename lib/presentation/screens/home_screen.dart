/// home_screen.dart (v2)
/// Dashboard utama dengan tab Tunai / Non Tunai / Sharing (kondisional)
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/services/backend_ai_service.dart';
import '../../data/services/supabase_service.dart';
import '../../data/services/voice_service.dart';
import '../providers/finance_provider.dart';
import '../widgets/query_result_card.dart';
import '../widgets/receipt_card.dart';
import '../widgets/transaction_tab.dart';
import '../widgets/chat_widgets.dart';
import 'auth_screens.dart';
import 'settings_profile_screens.dart';
import 'transaction_history_screen.dart';
import 'agent_control_center_screen.dart';


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
    setState(() {});
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

  String _formatRupiah(int amount) {
    final str = amount.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return buf.toString();
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
    finance.addDebugLog("User input: \"$text\"");
    finance.setAiThinking(true);
    _scrollChatToBottom();

    try {
      finance.addDebugLog("Calling backend AI /chat service...");
      final response = await BackendAiService().sendMessage(
        text,
        userId: SupabaseService.instance.currentUserId,
      );

      if (response != null) {
        finance.addDebugLog("AI Intent detected: ${response.intent}");
        if (response.logs.isNotEmpty) {
          for (final log in response.logs) {
            finance.addDebugLog("[Step] $log");
          }
        }

        // Check if response used rule-based fallback
        final isFallback = response.logs.any((log) => log.contains('Fallback') || log.contains('rule-based'));
        if (isFallback && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("LLM Limit/Offline: Menggunakan Parsing Rule-Based Lokal"),
              backgroundColor: Colors.amber,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }

        if (response.intent == 'ADD_EXPENSE' || response.intent == 'ADD_INCOME') {
          final itemsList = (response.extractedData['items'] as List<dynamic>?) ??
              (response.extractedData['transactions'] as List<dynamic>?) ??
              [];
          
          final itemNamesList = itemsList.map((e) => (e['note'] ?? 'Item').toString()).toList();
          final itemNames = itemNamesList.join(', ');

          int totalAmount = 0;
          for (final it in itemsList) {
            final amt = (it['amount'] as int?) ?? 0;
            final qty = (it['quantity'] as int?) ?? (it['qty'] as int?) ?? 1;
            totalAmount += (amt * qty);
          }

          final hardcodedReply = "Transaksi untuk $itemNames berhasil dicatat dengan total Rp ${_formatRupiah(totalAmount)}.";

          // 1. Show main text reply
          await finance.addMessage(hardcodedReply, true, logs: response.logs);
          if (_isChatExpanded) {
            voice.speak(hardcodedReply);
          }

          // 2. Add receipt breakdown bubble
          final receiptMap = {
            'transactions': itemsList,
            'intent': response.intent,
            'total': totalAmount,
          };
          await finance.addMessage('RECEIPT_DATA', true, receiptData: receiptMap);

          await finance.refreshAll();
        } else {
          // General AI query or analysis response
          final qResult = response.queryResult ?? response.extractedData['query_result'];
          await finance.addMessage(response.reply, true, logs: response.logs, queryResult: qResult, vizType: response.vizType);
          if (_isChatExpanded && response.reply.isNotEmpty) {
            voice.speak(response.reply);
          }
        }
      } else {
        await finance.addMessage("Maaf, gagal terhubung ke backend AI.", true);
        finance.addDebugLog("Error: Backend returned null response");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal terhubung ke AI (Backend Response Null)."),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error sending message to backend: $e");
      finance.addDebugLog("Exception: $e");
      await finance.addMessage(
        "Terjadi kesalahan sistem saat menghubungi AI.",
        true,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error Sistem: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
                        TunaiTab(finance: finance),
                        NonTunaiTab(finance: finance),
                        if (tabCount == 3) SharingTab(finance: finance),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // AI Chat panel overlay
            _buildChatPanel(finance, tabCount),
          ],
        ),
        bottomNavigationBar: _isChatExpanded
            ? null
            : BottomAppBar(
                shape: const CircularNotchedRectangle(),
                notchMargin: 8,
                color: Colors.white,
                elevation: 10,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _buildBottomNavItems(finance, tabCount),
                ),
              ),
        floatingActionButton: _isChatExpanded
            ? null
            : FloatingActionButton(
                shape: const CircleBorder(),
                onPressed: () => _toggleChat(!_isChatExpanded),
                backgroundColor: const Color(0xFF5E5CE6),
                elevation: 4,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    if (finance.pendingCount > 0)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              finance.pendingCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
        floatingActionButtonLocation: _isChatExpanded ? null : FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  List<Widget> _buildBottomNavItems(FinanceProvider finance, int tabCount) {
    if (tabCount == 2) {
      return [
        _buildTabItem(0, Icons.payments_rounded, "Tunai"),
        const SizedBox(width: 48), // Space for FAB
        _buildTabItem(1, Icons.credit_card_rounded, "Non Tunai"),
      ];
    } else {
      return [
        _buildTabItem(0, Icons.payments_rounded, "Tunai"),
        _buildTabItem(1, Icons.credit_card_rounded, "Non Tunai"),
        const SizedBox(width: 48), // Space for FAB
        _buildTabItem(2, Icons.group_rounded, "Sharing"),
        _buildTabItem(-1, Icons.menu_open_rounded, "Menu", onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        }),
      ];
    }
  }

  Widget _buildTabItem(int index, IconData icon, String label, {VoidCallback? onPressed}) {
    final isSelected = index >= 0 && _tabController.index == index;
    final color = isSelected ? const Color(0xFF5E5CE6) : Colors.grey.shade400;

    return Expanded(
      child: InkWell(
        onTap: onPressed ?? () {
          if (index >= 0) {
            _tabController.animateTo(index);
            setState(() {});
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
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
          colors: [Color(0xFF108EE9), Color(0xFF1A9EF2)],
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
                  IconButton(
                    icon: const Icon(Icons.psychology_outlined, color: Colors.white),
                    tooltip: "Jarvis Panel",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AgentControlCenterScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
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
  Widget _buildChatPanel(FinanceProvider finance, int tabCount) {
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
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  const SizedBox(width: 32),
                                  Expanded(
                                    child: Row(
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
                                          const ThinkingDots(),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.developer_mode_rounded,
                                      color: Color(0xFF5E5CE6),
                                      size: 20,
                                    ),
                                    tooltip: "Dev Tools Console",
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _showDevToolsConsole(context, finance),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    // Context Switcher (Tunai / Non Tunai / Sharing)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                finance.setActiveChatType('tunai');
                                _tabController.animateTo(0);
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: finance.activeChatType == 'tunai' ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: finance.activeChatType == 'tunai' ? [
                                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                                  ] : null,
                                ),
                                child: Center(
                                  child: Text(
                                    "Tunai",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: finance.activeChatType == 'tunai' ? const Color(0xFF5E5CE6) : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                finance.setActiveChatType('non_tunai');
                                _tabController.animateTo(1);
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: finance.activeChatType == 'non_tunai' ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: finance.activeChatType == 'non_tunai' ? [
                                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                                  ] : null,
                                ),
                                child: Center(
                                  child: Text(
                                    "Non Tunai",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: finance.activeChatType == 'non_tunai' ? const Color(0xFF5E5CE6) : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (tabCount == 3)
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  finance.setActiveChatType('sharing');
                                  _tabController.animateTo(2);
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: finance.activeChatType == 'sharing' ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: finance.activeChatType == 'sharing' ? [
                                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                                    ] : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Bersama",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: finance.activeChatType == 'sharing' ? const Color(0xFF5E5CE6) : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
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
                          return const ThinkingBubble();
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

  void _showDevToolsConsole(BuildContext context, FinanceProvider finance) {
    final Set<String> allLogsSet = {};
    for (final log in finance.debugLogs) {
      allLogsSet.add(log);
    }
    for (final msg in finance.chatHistory) {
      final rawLogs = msg['logs'];
      if (rawLogs is List) {
        for (final l in rawLogs) {
          allLogsSet.add("[Step] ${l.toString()}");
        }
      }
    }
    final logsList = allLogsSet.toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = "";
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = logsList
                .where((l) => l.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();
            final fullTextLog = filtered.join("\n");

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFF181824),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle bar & Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white10)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.terminal_rounded, color: Color(0xFF00FF66), size: 22),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                "Dev Tools Console (Debug Log)",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 20),
                              tooltip: "Salin Semua Log",
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: fullTextLog));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text("Semua log debug berhasil disalin!"),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                              tooltip: "Hapus Log",
                              onPressed: () {
                                finance.clearDebugLogs();
                                setModalState(() {});
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Search bar
                        TextField(
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          onChanged: (val) {
                            setModalState(() => searchQuery = val);
                          },
                          decoration: InputDecoration(
                            hintText: "Cari log / query...",
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.08),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Log list view
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              "Belum ada log debug tercatat.",
                              style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final item = filtered[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: SelectableText(
                                        item,
                                        style: const TextStyle(
                                          color: Color(0xFF00FF66),
                                          fontSize: 11,
                                          fontFamily: "monospace",
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: item));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text("Log disalin!"),
                                            duration: const Duration(seconds: 1),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        );
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Icon(Icons.copy_rounded, color: Colors.white54, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
