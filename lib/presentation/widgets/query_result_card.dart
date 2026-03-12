/// query_result_card.dart
/// Widget untuk menampilkan hasil Text-to-SQL:
/// - Ringkasan teks dari AI
/// - Tombol "Lihat Detail"
/// - Modal detail berisi tabel + chart (dipilih AI)
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/database/database_helper.dart';

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
  final RawQueryResult result; // Data mentah dari SQLite
  final VizType vizType; // Hint visualisasi dari AI
  final String originalQuestion;

  const QueryResultCard({
    super.key,
    required this.aiSummary,
    required this.result,
    required this.vizType,
    required this.originalQuestion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge "Data dari Database"
          Row(
            children: [
              const Icon(Icons.analytics, size: 14, color: Colors.deepPurple),
              const SizedBox(width: 4),
              Text(
                'Analisis Data',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.deepPurple[300],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Ringkasan teks AI
          Text(
            aiSummary,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),

          // Tombol Lihat Detail (hanya jika ada data)
          if (result.isSuccess && !result.isEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showDetailModal(context),
                icon: const Icon(Icons.table_chart, size: 16),
                label: Text('Lihat Detail (${result.rowCount} baris)'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.deepPurple.withOpacity(0.4)),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDetailModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailModal(
        result: result,
        vizType: _resolveVizType(),
        title: originalQuestion,
      ),
    );
  }

  /// Tentukan tipe visualisasi final (resolve 'auto')
  VizType _resolveVizType() {
    if (vizType != VizType.auto) return vizType;

    // Auto-detect: jika ada kolom angka dan <= 8 baris → pie/bar
    // Jika banyak baris dengan kolom date → line
    final hasDateCol = result.columns.any(
      (c) =>
          c.toLowerCase().contains('date') ||
          c.toLowerCase().contains('tanggal'),
    );
    final numericCols = result.columns.where((c) {
      final sample = result.rows.first[c];
      return sample is int || sample is double;
    }).length;

    if (hasDateCol && result.rowCount > 3) return VizType.line;
    if (numericCols >= 1 && result.rowCount <= 8) return VizType.bar;
    return VizType.table;
  }
}

// ==========================================
// MODAL DETAIL
// ==========================================

class _DetailModal extends StatefulWidget {
  final RawQueryResult result;
  final VizType vizType;
  final String title;

  const _DetailModal({
    required this.result,
    required this.vizType,
    required this.title,
  });

  @override
  State<_DetailModal> createState() => _DetailModalState();
}

class _DetailModalState extends State<_DetailModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Tab: Chart + Tabel (jika vizType bukan table-only)
    _tabController = TabController(
      length: widget.vizType == VizType.table ? 1 : 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTableOnly = widget.vizType == VizType.table;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // TabBar
            if (!isTableOnly)
              TabBar(
                controller: _tabController,
                labelColor: Colors.deepPurple,
                tabs: [
                  Tab(icon: Icon(_getChartIcon()), text: _getChartLabel()),
                  const Tab(icon: Icon(Icons.table_rows), text: 'Tabel'),
                ],
              ),
            // TabBarView
            Expanded(
              child: isTableOnly
                  ? _buildTable(scrollController)
                  : TabBarView(
                      controller: _tabController,
                      children: [_buildChart(), _buildTable(scrollController)],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getChartIcon() {
    switch (widget.vizType) {
      case VizType.pie:
        return Icons.pie_chart;
      case VizType.line:
        return Icons.show_chart;
      default:
        return Icons.bar_chart;
    }
  }

  String _getChartLabel() {
    switch (widget.vizType) {
      case VizType.pie:
        return 'Pie Chart';
      case VizType.line:
        return 'Line Chart';
      default:
        return 'Bar Chart';
    }
  }

  // ==========================================
  // BUILDER: Tabel
  // ==========================================

  Widget _buildTable(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.deepPurple[50]),
          columns: widget.result.columns
              .map(
                (c) => DataColumn(
                  label: Text(
                    c,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )
              .toList(),
          rows: widget.result.rows
              .map(
                (row) => DataRow(
                  cells: widget.result.columns
                      .map((c) => DataCell(Text(row[c]?.toString() ?? '-')))
                      .toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  // ==========================================
  // BUILDER: Chart (Bar / Pie / Line)
  // ==========================================

  Widget _buildChart() {
    switch (widget.vizType) {
      case VizType.pie:
        return _buildPieChart();
      case VizType.line:
        return _buildLineChart();
      default:
        return _buildBarChart();
    }
  }

  /// Cari kolom label (string) dan kolom nilai (angka) otomatis
  _ChartData _extractChartData() {
    String labelCol = widget.result.columns.first;
    String valueCol = widget.result.columns.last;

    // Cari kolom pertama yang isinya angka sebagai value
    for (final col in widget.result.columns) {
      final sample = widget.result.rows.first[col];
      if (sample is int || sample is double) {
        valueCol = col;
        break;
      }
    }
    // Cari kolom string sebagai label
    for (final col in widget.result.columns) {
      final sample = widget.result.rows.first[col];
      if (sample is String) {
        labelCol = col;
        break;
      }
    }

    final labels = widget.result.rows
        .map((r) => r[labelCol]?.toString() ?? '')
        .toList();
    final values = widget.result.rows.map((r) {
      final v = r[valueCol];
      if (v is int) return v.toDouble();
      if (v is double) return v;
      return double.tryParse(v?.toString() ?? '0') ?? 0.0;
    }).toList();

    return _ChartData(labels: labels, values: values, valueLabel: valueCol);
  }

  Widget _buildBarChart() {
    final data = _extractChartData();
    const colors = [
      Colors.deepPurple,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.blue,
      Colors.green,
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: data.values.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value,
                  color: colors[e.key % colors.length],
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= data.labels.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data.labels[i].length > 8
                          ? '${data.labels[i].substring(0, 8)}...'
                          : data.labels[i],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 50),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final data = _extractChartData();
    const colors = [
      Colors.deepPurple,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.blue,
      Colors.green,
      Colors.red,
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: data.values.asMap().entries.map((e) {
                  return PieChartSectionData(
                    value: e.value,
                    color: colors[e.key % colors.length],
                    title: data.labels[e.key].length > 10
                        ? '${data.labels[e.key].substring(0, 10)}...'
                        : data.labels[e.key],
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    radius: 80,
                  );
                }).toList(),
                centerSpaceRadius: 40,
              ),
            ),
          ),
          // Legend
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: data.labels.asMap().entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[e.key % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(e.value, style: const TextStyle(fontSize: 11)),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    final data = _extractChartData();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: data.values
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              isCurved: true,
              color: Colors.deepPurple,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.deepPurple.withOpacity(0.1),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= data.labels.length) return const SizedBox();
                  return Text(
                    data.labels[i].length > 6
                        ? data.labels[i].substring(0, 6)
                        : data.labels[i],
                    style: const TextStyle(fontSize: 9),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 50),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// DATA CLASS UNTUK CHART
// ==========================================

class _ChartData {
  final List<String> labels;
  final List<double> values;
  final String valueLabel;
  _ChartData({
    required this.labels,
    required this.values,
    required this.valueLabel,
  });
}
