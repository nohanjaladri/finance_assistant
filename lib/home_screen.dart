import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'logic/voice_service.dart';
import 'logic/finance_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Dio _dio = Dio();

  // Variabel untuk menampung transaksi yang butuh konfirmasi (Fitur Mendatang)
  Map<String, dynamic>? _pendingTransaction;

  bool isChatExpanded = false;
  bool _showScrollToBottom = false;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double currentScroll = _scrollController.position.pixels;
        if (maxScroll - currentScroll > 200) {
          if (!_showScrollToBottom) setState(() => _showScrollToBottom = true);
        } else {
          if (_showScrollToBottom) setState(() => _showScrollToBottom = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // ==========================================
  // PENEMPATAN FUNGSI API KEY
  // ==========================================
  String _getApiKey() {
    // Karena sudah di-load di Splash, ini pasti aman
    return dotenv.maybeGet('GROQ_API_KEY') ?? "";
  }

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
  // PENEMPATAN FUNGSI PROCESS MESSAGE
  // ==========================================
  Future<void> _processMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    final apiKey = _getApiKey();
    if (apiKey.isEmpty) {
      /* KODE KHUSUS ERROR */
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("API Key tidak ditemukan. Periksa file .env"),
        ),
      );
      return;
    }

    final finance = context.read<FinanceProvider>();
    final voice = context.read<VoiceService>();

    voice.stop();
    await finance.addMessage(userText, false);
    finance.setAiThinking(true);
    _scrollToBottom();

    try {
      final response = await _dio.post(
        "https://api.groq.com/openai/v1/chat/completions",
        options: Options(headers: {"Authorization": "Bearer $apiKey"}),
        data: {
          "model": "llama-3.1-8b-instant",
          "messages": [
            {
              "role": "system",
              "content": """Kamu adalah bot pencatat keuangan. 
    Tugasmu ADALAH mengeluarkan tag transaksi di AKHIR setiap jawaban jika ada data uang masuk/keluar.
    
    ATURAN FORMAT: [TX:jumlah:keterangan:TIPE:KATEGORI]
    - TIPE wajib 'IN' untuk uang masuk, 'OUT' untuk uang keluar.
    - JUMLAH tidak boleh pakai titik atau koma.
    
    CONTOH JAWABAN:
    'Oke, sudah dicatat ya! [TX:75000:Beli bakso:OUT:Food]' """,
            },
            ...finance.chatHistory.map(
              (m) => {
                "role": m['isAi'] == 1 ? "assistant" : "user",
                "content": m['text'],
              },
            ),
            {"role": "user", "content": userText},
          ],
        },
      );

      String aiRawRes = response.data['choices'][0]['message']['content'];

      final regExp = RegExp(
        r"\[TX\s*:\s*([\d\s\.,]+)\s*:\s*([^:]+)\s*:\s*(IN|OUT)\s*:\s*([^\]]+)\]",
        caseSensitive: false,
      );
      final matches = regExp.allMatches(aiRawRes);

      if (matches.isNotEmpty) {
        for (var match in matches) {
          String amountStr = match.group(1)!.replaceAll(RegExp(r'[^\d]'), '');
          int amount = int.tryParse(amountStr) ?? 0;
          String type = match.group(3)!.toUpperCase().trim();

          if (amount > 0) {
            await finance.addTransaction(
              amount,
              match.group(2)!.trim(),
              type,
              match.group(4)!.trim(),
            );
          }
        }
      }

      await finance.addMessage(aiRawRes, true);
      if (isChatExpanded) {
        voice.speak(aiRawRes);
      }
    } catch (e) {
      /* KODE KHUSUS ERROR */
      debugPrint("CATCH_ERROR: $e");
      await finance.addMessage(
        "Maaf, sepertinya ada masalah koneksi ke asisten AI.",
        true,
      );
    } finally {
      finance.setAiThinking(false);
      _scrollToBottom();
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

  // --- WIDGET DASHBOARD ---
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
    int saldo = finance.totalIn - finance.totalOut;
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
            "Rp $saldo",
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
        "Rp $amount",
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
        bool isIn = item['type'] == 'IN';
        return ListTile(
          leading: Icon(
            isIn ? Icons.add_circle : Icons.remove_circle,
            color: isIn ? Colors.teal : Colors.orange,
          ),
          title: Text(item['note'] ?? ""),
          trailing: Text(
            "Rp ${item['amount']}",
            style: TextStyle(
              color: isIn ? Colors.teal : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET CHAT PANEL ---
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
        title: const Text("Asisten AI"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() => isChatExpanded = false),
        ),
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
                bool isAi = m['isAi'] == 1;
                return Align(
                  alignment: isAi
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
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
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final voice = Provider.of<VoiceService>(context);
    return Container(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: "Ketik transaksi...",
                filled: true,
                fillColor: Colors.grey[100],
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
              child: Icon(
                _textController.text.isNotEmpty ? Icons.send : Icons.mic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
