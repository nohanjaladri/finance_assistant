/// query_result_card.dart
/// Widget untuk menampilkan hasil Text-to-SQL:
/// - Ringkasan teks dari AI
/// - Tombol "Lihat Detail"
/// - Modal detail berisi tabel + chart (dipilih AI)
library;

import 'package:flutter/material.dart';
import '../screens/query_detail_screen.dart';

class RawQueryResult {
  final List<String> columns;
  final List<Map<String, dynamic>> rows;
  final String? error;

  RawQueryResult({
    required this.columns,
    required this.rows,
    required this.error,
  });

  bool get isSuccess => error == null;
  bool get isEmpty => rows.isEmpty;
  int get rowCount => rows.length;

  bool get isEffectivelyEmpty {
    if (rows.isEmpty) return true;
    for (final row in rows) {
      for (final val in row.values) {
        if (val != null && val != 0 && val != '0') return false;
      }
    }
    return true;
  }
}

// ==========================================
// ENUM TIPE VISUALISASI
// ==========================================

/// Tipe chart yang bisa dipilih AI
enum VizType { table, bar, pie, line, auto }

VizType vizTypeFromString(String s) {
  switch (s.toLowerCase()) {
    case 'bar':
      return VizType.bar;
    case 'pie':
      return VizType.pie;
    case 'line':
      return VizType.line;
    case 'table':
      return VizType.table;
    default:
      return VizType.auto;
  }
}

// ==========================================
// MAIN WIDGET: QueryResultCard
// ==========================================

class QueryResultCard extends StatelessWidget {
  final String aiSummary; // Jawaban teks ringkas dari AI
  final Map<String, dynamic> queryResult; // Structured query result map {'rows': ..., 'columns': ...}
  final VizType vizType; // Hint visualisasi dari AI
  final String? sqlQuery; // Query SQL opsional

  const QueryResultCard({
    super.key,
    required this.aiSummary,
    required this.queryResult,
    required this.vizType,
    this.sqlQuery,
  });

  RawQueryResult _toRawResult() {
    final rowsList = queryResult['rows'] as List<dynamic>? ?? [];
    final colsList = queryResult['columns'] as List<dynamic>? ?? [];
    final rows = rowsList.map((r) => Map<String, dynamic>.from(r as Map)).toList();
    final columns = colsList.map((c) => c.toString()).toList();
    return RawQueryResult(columns: columns, rows: rows, error: null);
  }

  @override
  Widget build(BuildContext context) {
    final result = _toRawResult();
    final effectiveSql = sqlQuery ?? queryResult['sql_query'] as String?;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.88,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bubble 1: Ringkasan teks AI
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5E5CE6).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.table_chart_rounded, size: 14, color: Color(0xFF5E5CE6)),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Hasil Analisis Data',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF5E5CE6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  aiSummary,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1E1E2C), height: 1.4),
                ),
              ],
            ),
          ),

          // Tombol Tunggal: "Lihat Detail" Premium Style
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showDetailModal(context, result, effectiveSql),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.analytics_rounded, size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        result.rowCount > 0 ? "Buka Detail Analisis (${result.rowCount} entri)" : "Buka Detail Analisis",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3730A3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF4F46E5)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailModal(BuildContext context, RawQueryResult result, String? sqlQuery) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QueryDetailScreen(
          aiSummary: aiSummary,
          columns: result.columns,
          rows: result.rows,
          sqlQuery: sqlQuery,
          vizType: vizType.name,
        ),
      ),
    );
  }
}
