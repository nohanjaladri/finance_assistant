import 'package:flutter/material.dart';
import '../../data/services/backend_ai_service.dart';

class AgentSimulatorView extends StatefulWidget {
  final String agentType;
  const AgentSimulatorView({super.key, required this.agentType});

  @override
  State<AgentSimulatorView> createState() => _AgentSimulatorViewState();
}

class _AgentSimulatorViewState extends State<AgentSimulatorView> {
  final BackendAiService _aiService = BackendAiService();
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;
  List<String> _simLogs = [];
  
  // Entry Agent Output Data
  Map<String, dynamic>? _entryExtracted;
  double _entryConf = 0.0;
  bool _entryAmb = false;
  String? _entryClarify;
  
  // Analyst Agent Output Data
  String _analystQuery = "";
  List<dynamic> _analystRows = [];
  
  // Budget Agent Output Data
  int _budgetLimit = 0;
  int _budgetSpent = 0;
  String _budgetStatus = "Unknown";
  List<dynamic> _budgetTips = [];

  // Search Agent Output Data
  List<dynamic> _searchResults = [];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _runSimulation() async {
    final text = _inputController.text.trim();
    if (text.isEmpty && widget.agentType != "Budget") return;

    setState(() {
      _isLoading = true;
      _simLogs = ["Menjalankan simulasi agen..."];
    });

    try {
      if (widget.agentType == "Entry") {
        final res = await _aiService.simulateEntryAgent(text);
        if (res != null) {
          setState(() {
            _entryExtracted = res['extracted_data'] as Map<String, dynamic>?;
            _entryConf = (res['confidence_score'] as num?)?.toDouble() ?? 0.0;
            _entryAmb = res['is_ambiguous'] as bool? ?? false;
            _entryClarify = res['clarification_question'] as String?;
            _simLogs = List<String>.from(res['logs'] ?? []);
          });
        }
      } else if (widget.agentType == "Analyst") {
        final res = await _aiService.simulateAnalystAgent(text, "default_user");
        if (res != null) {
          setState(() {
            _analystQuery = res['sql_query'] as String? ?? "";
            _analystRows = res['results'] as List<dynamic>? ?? [];
            _simLogs = List<String>.from(res['logs'] ?? []);
          });
        }
      } else if (widget.agentType == "Budget") {
        final res = await _aiService.simulateBudgetAgent("default_user");
        if (res != null) {
          setState(() {
            _budgetLimit = (res['limit'] as num?)?.toInt() ?? 0;
            _budgetSpent = (res['spent'] as num?)?.toInt() ?? 0;
            _budgetStatus = res['status'] as String? ?? "AMAN";
            _budgetTips = res['tips'] as List<dynamic>? ?? [];
            _simLogs = List<String>.from(res['logs'] ?? []);
          });
        }
      } else if (widget.agentType == "Search") {
        final res = await _aiService.simulateSearchAgent(text);
        if (res != null) {
          setState(() {
            _searchResults = res['results'] as List<dynamic>? ?? [];
            _simLogs = List<String>.from(res['logs'] ?? []);
          });
        }
      } else if (widget.agentType == "Orchestrator") {
        // Run full Orchestrator chat test
        final res = await _aiService.sendMessage(text, userId: "default_user");
        if (res != null) {
          setState(() {
            _simLogs = [
              "[Orchestrator] Menerima pesan: \"$text\"",
              ...res.logs,
              "[Orchestrator] Respon Akhir: \"${res.reply}\""
            ];
          });
        }
      }
    } catch (e) {
      setState(() {
        _simLogs.add("[Error Simulator] Gagal memanggil API: $e");
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    Widget leftContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAgentOverviewCard(),
        const SizedBox(height: 20),
        if (widget.agentType != "Budget") ...[
          const Text(
            "Masukkan Simulasi Perintah",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _getHintText(),
                    hintStyle: const TextStyle(color: Colors.white30),
                    fillColor: const Color(0xFF1E293B),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _isLoading ? null : _runSimulation,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
        ] else ...[
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _runSimulation,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text("Mulai Evaluasi Keuangan", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
        const SizedBox(height: 25),
        const Text(
          "Simulated Output Visual",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        _buildOutputVisualizer(),
      ],
    );

    Widget rightContent = Container(
      color: const Color(0xFF070B14),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🤖 Agent Execution Log",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
          const SizedBox(height: 5),
          const Text(
            "Runtutan alur pikir dan aksi yang dikerjakan oleh agen:",
            style: TextStyle(fontSize: 11, color: Colors.white54),
          ),
          const SizedBox(height: 15),
          _simLogs.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      "Belum ada logs. Mulai simulasi untuk melihat langkah agen.",
                      style: TextStyle(color: Colors.white30, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _simLogs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("• ", style: TextStyle(color: Colors.greenAccent, fontSize: 16)),
                          Expanded(
                            child: Text(
                              _simLogs[index],
                              style: const TextStyle(
                                color: Color(0xE6FFFFFF),
                                fontSize: 13,
                                fontFamily: "monospace",
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text("${widget.agentType} Simulator"),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: isMobile
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  leftContent,
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: rightContent,
                  ),
                ],
              ),
            )
          : Row(
              key: const ValueKey("simulators_row"),
              children: [
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: leftContent,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Container(
                    color: const Color(0xFF070B14),
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "🤖 Agent Execution Log",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Runtutan alur pikir dan aksi yang dikerjakan oleh agen:",
                          style: TextStyle(fontSize: 11, color: Colors.white54),
                        ),
                        const SizedBox(height: 15),
                        Expanded(
                          child: _simLogs.isEmpty
                              ? const Center(child: Text("Belum ada logs. Mulai simulasi untuk melihat langkah agen.", style: TextStyle(color: Colors.white30, fontSize: 13), textAlign: TextAlign.center))
                              : ListView.builder(
                                  itemCount: _simLogs.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("• ", style: TextStyle(color: Colors.greenAccent, fontSize: 16)),
                                          Expanded(
                                            child: Text(
                                              _simLogs[index],
                                              style: const TextStyle(
                                                color: Color(0xE6FFFFFF),
                                                fontSize: 13,
                                                fontFamily: "monospace",
                                              ),
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
                  ),
                ),
              ],
            ),
    );
  }

  String _getHintText() {
    switch (widget.agentType) {
      case "Entry":
        return "Contoh: Beli bakso 15000 dan teh 5000";
      case "Analyst":
        return "Contoh: Berapa total belanja boba saya?";
      case "Search":
        return "Contoh: Harga iPhone 15 Pro Max";
      default:
        return "Ketik perintah di sini...";
    }
  }

  Widget _buildAgentOverviewCard() {
    String overviewText = "";
    IconData icon = Icons.info;
    Color gradStart = Colors.blue;
    Color gradEnd = Colors.indigo;

    switch (widget.agentType) {
      case "Orchestrator":
        overviewText = "Agen pusat pengambil keputusan. Membaca input, mengklasifikasi intent, dan merencanakan koordinasi antar agen.";
        icon = Icons.psychology;
        gradStart = const Color(0xFF3B82F6);
        gradEnd = const Color(0xFF1E3A8A);
        break;
      case "Entry":
        overviewText = "Spesialis pengurai data belanja. Membaca kalimat kasual, merangkumnya menjadi entri database, dan menghitung confidence level.";
        icon = Icons.edit_note;
        gradStart = const Color(0xFF10B981);
        gradEnd = const Color(0xFF065F46);
        break;
      case "Analyst":
        overviewText = "Spesialis kueri database. Memilih tabel yang aman, menyusun perintah SELECT PostgreSQL, dan menyajikan baris data laporan.";
        icon = Icons.analytics;
        gradStart = const Color(0xFFF59E0B);
        gradEnd = const Color(0xFF92400E);
        break;
      case "Budget":
        overviewText = "Spesialis penilai anggaran. Membaca total belanja bulan ini di DB, mencocokkannya dengan target limit, dan memberi solusi finansial.";
        icon = Icons.savings;
        gradStart = const Color(0xFFEC4899);
        gradEnd = const Color(0xFF9D174D);
        break;
      case "Search":
        overviewText = "Spesialis riset online. Menjelajahi internet untuk mencari estimasi harga barang di pasar sebagai rujukan anggaran belanja.";
        icon = Icons.travel_explore;
        gradStart = const Color(0xFF8B5CF6);
        gradEnd = const Color(0xFF5B21B6);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [gradStart, gradEnd]),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, size: 45, color: Colors.white),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Overview: ${widget.agentType} Agent",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 5),
                Text(overviewText, style: const TextStyle(fontSize: 13, color: Color(0xCCFFFFFF), height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOutputVisualizer() {
    // 1. ORCHESTRATOR VISUALIZER
    if (widget.agentType == "Orchestrator") {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
        child: Column(
          children: [
            const Text("LangGraph Node Execution Flowchart", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFlowBox("User Input", Colors.grey[700]!),
                  const Icon(Icons.arrow_forward, color: Colors.white54),
                  _buildFlowBox("detect_intent\n(Orchestrator)", Colors.blueAccent),
                  const Icon(Icons.arrow_forward, color: Colors.white54),
                  _buildFlowBox("tool_executor\n(Spec. Agents)", Colors.purple),
                  const Icon(Icons.arrow_forward, color: Colors.white54),
                  _buildFlowBox("Database / User Response", Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text("Status: READY FOR QUERY SIMULATION", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    // 2. ENTRY AGENT VISUALIZER
    if (widget.agentType == "Entry") {
      if (_entryExtracted == null) {
        return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Belum ada data ekstraksi belanja. Kirim masukan di atas.", style: TextStyle(color: Colors.white30))));
      }

      final items = _entryExtracted!['items'] as List<dynamic>? ?? [];
      final category = _entryExtracted!['category'] ?? 'N/A';
      final pm = _entryExtracted!['payment_method'] ?? 'N/A';
      final type = _entryExtracted!['type'] ?? 'OUT';

      return Column(
        children: [
          Row(
            children: [
              // Gauge Confidence
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      const Text("Confidence Level", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 15),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: _entryConf,
                              strokeWidth: 8,
                              backgroundColor: Colors.white12,
                              color: _entryConf > 0.8 ? Colors.green : Colors.orange,
                            ),
                          ),
                          Text("${(_entryConf * 100).toInt()}%", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 15),
              // Meta badges
              Expanded(
                flex: 6,
                child: Container(
                  height: 125,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetaRow("Kategori:", category, Colors.blueAccent),
                      _buildMetaRow("Metode:", pm, Colors.orange),
                      _buildMetaRow("Tipe Transaksi:", type == "OUT" ? "Pengeluaran (OUT)" : "Pemasukan (IN)", type == "OUT" ? Colors.redAccent : Colors.greenAccent),
                    ],
                  ),
                ),
              )
            ],
          ),
          
          if (_entryAmb) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.15), border: Border.all(color: Colors.redAccent), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Memicu Pertanyaan Klarifikasi (Data Ambigu):", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 5),
                        Text(_entryClarify ?? "Meminta kejelasan harga.", style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 15),
          // Items Table
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Items Extracted Table", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                const Divider(color: Colors.white12, height: 20),
                if (items.isEmpty)
                  const Center(child: Text("Tidak ada detail item terekstrak.", style: TextStyle(color: Colors.white30, fontSize: 12)))
                else
                  ...items.map((it) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${it['note']} x${it['quantity']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          Text("Rp ${it['amount']}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      );
    }

    // 3. ANALYST AGENT VISUALIZER
    if (widget.agentType == "Analyst") {
      if (_analystQuery.isEmpty) {
        return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Belum ada query SQL yang diuji. Ketik kueri di atas.", style: TextStyle(color: Colors.white30))));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Query Code Block
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("PostgreSQL SELECT Query", style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: "monospace")),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16, color: Colors.white54),
                      onPressed: () {},
                    )
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  _analystQuery,
                  style: const TextStyle(color: Colors.white, fontFamily: "monospace", fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          // Results Table
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Query Results Table", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                const Divider(color: Colors.white12, height: 20),
                if (_analystRows.isEmpty)
                  const Center(child: Text("0 baris dikembalikan dari database.", style: TextStyle(color: Colors.white30, fontSize: 12)))
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: _analystRows[0]
                          .keys
                          .map<DataColumn>((k) => DataColumn(label: Text(k.toString(), style: const TextStyle(color: Colors.blueAccent))))
                          .toList(),
                      rows: _analystRows.map<DataRow>((row) {
                        return DataRow(
                          cells: row.values
                              .map<DataCell>((v) => DataCell(Text(v.toString(), style: const TextStyle(color: Colors.white))))
                              .toList(),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    // 4. BUDGET AGENT VISUALIZER
    if (widget.agentType == "Budget") {
      if (_budgetStatus == "Unknown") {
        return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Klik tombol di atas untuk menyinkronkan status anggaran.", style: TextStyle(color: Colors.white30))));
      }

      final isSafe = _budgetStatus.contains("AMAN");
      final usagePct = (_budgetSpent / _budgetLimit) * 100;

      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Limit Bulanan", style: TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 5),
                      Text("Rp $_budgetLimit", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Total Terpakai", style: TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 5),
                      Text("Rp $_budgetSpent", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isSafe ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
              border: Border.all(color: isSafe ? Colors.green : Colors.red),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("STATUS BUDGET: $_budgetStatus", style: TextStyle(fontWeight: FontWeight.bold, color: isSafe ? Colors.greenAccent : Colors.redAccent)),
                Text("${usagePct.toInt()}% Terpakai", style: TextStyle(color: isSafe ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Saran & Rekomendasi Finansial", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const Divider(color: Colors.white12, height: 20),
                if (_budgetTips.isEmpty)
                  const Text("Tidak ada saran khusus saat ini.", style: TextStyle(color: Colors.white54))
                else
                  ..._budgetTips.map((tip) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 16),
                          const SizedBox(width: 10),
                          Expanded(child: Text(tip.toString(), style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13, height: 1.4))),
                        ],
                      ),
                    );
                  })
              ],
            ),
          ),
        ],
      );
    }

    // 5. WEB SEARCH AGENT VISUALIZER
    if (widget.agentType == "Search") {
      if (_searchResults.isEmpty) {
        return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Belum ada data pencarian web. Cari barang/gadget di atas.", style: TextStyle(color: Colors.white30))));
      }

      return Column(
        children: _searchResults.map((res) {
          return Card(
            color: const Color(0xFF1E293B),
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          res['title'] ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                      ),
                      if (res['price'] != null && res['price'] != "N/A")
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                          child: Text(res['price'].toString(), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                        )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(res['snippet'] ?? 'No snippet available.', style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    return const SizedBox();
  }

  Widget _buildFlowBox(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12),
        ),
      ],
    );
  }
}
