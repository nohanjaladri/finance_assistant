import 'package:flutter/material.dart';
import 'agent_simulators.dart';

class AgentControlCenterScreen extends StatelessWidget {
  const AgentControlCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark elegant Slate background
      appBar: AppBar(
        title: const Text(
          "Jarvis Control Center",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          key: const ValueKey("agent_control_body"),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Jarvis Multi-Agent Architecture",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Supervisor-Worker Pattern: Otak utama (Supervisor) mengorkestrasi tugas secara dinamis dan menugaskannya ke agen spesialis (Workers). Ketuk salah satu agen di bawah untuk menyimulasikan cara kerjanya secara mandiri.",
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xE6FFFFFF),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              const Text(
                "Jarvis Active Agents",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              
              // Agent list items
              _buildAgentCard(
                context,
                title: "🧠 Jarvis Orchestrator",
                description: "Supervisor pusat. Bertugas menganalisis input user dan merutekan tugas ke agen spesialis lainnya.",
                status: "ACTIVE",
                statusColor: Colors.greenAccent,
                icon: Icons.psychology,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AgentSimulatorView(agentType: "Orchestrator"),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildAgentCard(
                context,
                title: "✍️ Entry Transaction Agent",
                description: "Spesialis pencatatan. Mengekstrak item belanja, kategori, nominal harga, dan menghitung confidence score.",
                status: "ACTIVE",
                statusColor: Colors.greenAccent,
                icon: Icons.edit_note,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AgentSimulatorView(agentType: "Entry"),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildAgentCard(
                context,
                title: "📊 Database Analyst Agent",
                description: "Spesialis query & analisis database. Menerjemahkan bahasa alami ke kueri SQL SELECT PostgreSQL secara aman.",
                status: "ACTIVE",
                statusColor: Colors.greenAccent,
                icon: Icons.analytics,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AgentSimulatorView(agentType: "Analyst"),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildAgentCard(
                context,
                title: "💰 Planner & Budget Agent",
                description: "Spesialis perencanaan & anggaran. Mengevaluasi sisa limit budget bulanan dan memberi tips hemat.",
                status: "ACTIVE",
                statusColor: Colors.greenAccent,
                icon: Icons.savings,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AgentSimulatorView(agentType: "Budget"),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildAgentCard(
                context,
                title: "🌐 Web Search Agent",
                description: "Spesialis internet search. Menjelajahi informasi luar seperti harga barang terkini di marketplace.",
                status: "ACTIVE",
                statusColor: Colors.greenAccent,
                icon: Icons.travel_explore,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AgentSimulatorView(agentType: "Search"),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgentCard(
    BuildContext context, {
    required String title,
    required String description,
    required String status,
    required Color statusColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B), // Slate-800 card color
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF0F172A),
              child: Icon(icon, color: Colors.blueAccent),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Text(
                        "Buka Simulator",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 5),
                      Icon(Icons.arrow_forward_ios, size: 10, color: Colors.blueAccent),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
