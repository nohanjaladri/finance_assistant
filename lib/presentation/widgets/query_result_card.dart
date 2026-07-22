/// query_result_card.dart
/// Widget untuk menampilkan hasil Text-to-SQL:
/// - Ringkasan teks dari AI
/// - Tombol "Lihat Detail"
/// - Modal detail berisi tabel + chart (dipilih AI)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

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

          // Bubble 2: Tabel Data Modern & Profesional (Jika Ada Data)
          if (result.isSuccess && !result.isEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Modern Header Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    color: const Color(0xFFF8F9FE),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.storage_rounded, size: 14, color: Color(0xFF5E5CE6)),
                            const SizedBox(width: 6),
                            Text(
                              'Tabel Data (${result.rowCount} entri)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => _showDetailModal(context, result),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                Text(
                                  'Visualisasi',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF5E5CE6),
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF5E5CE6)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  // Horizontal scrollable clean data table
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                      dataRowMinHeight: 36,
                      dataRowMaxHeight: 44,
                      columnSpacing: 20,
                      horizontalMargin: 14,
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                      dataTextStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E293B),
                      ),
                      columns: result.columns.map((col) {
                        return DataColumn(
                          label: Text(
                            col.toUpperCase().replaceAll('_', ' '),
                          ),
                        );
                      }).toList(),
                      rows: result.rows.map((row) {
                        return DataRow(
                          cells: result.columns.map((col) {
                            final val = row[col];
                            String displayVal = val?.toString() ?? '-';
                            if (val is int && (col.toLowerCase().contains('amount') || col.toLowerCase().contains('total') || col.toLowerCase().contains('harga') || col.toLowerCase().contains('nominal'))) {
                              final str = val.abs().toString();
                              final buf = StringBuffer();
                              for (int i = 0; i < str.length; i++) {
                                if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
                                buf.write(str[i]);
                              }
                              displayVal = "Rp ${buf.toString()}";
                            }
                            return DataCell(
                              Text(
                                displayVal,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Bubble 3: Tombol Detail Query SQL
          if (effectiveSql != null && effectiveSql.isNotEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(top: 2),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showSqlQueryModal(context, effectiveSql),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF5E5CE6).withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                          )
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.code_rounded, size: 14, color: Color(0xFF5E5CE6)),
                          SizedBox(width: 6),
                          Text(
                            "Lihat Detail Query SQL",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5E5CE6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSqlQueryModal(BuildContext context, String sql) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.terminal_rounded, color: Color(0xFF5E5CE6), size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Detail Kueri SQL",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E1E2C),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF5E5CE6)),
                  tooltip: "Salin Query",
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: sql));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Query SQL berhasil disalin!"),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                sql,
                style: const TextStyle(
                  fontFamily: "monospace",
                  fontSize: 12,
                  color: Color(0xFF00FF66),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDetailModal(BuildContext context, RawQueryResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailModal(
        result: result,
        vizType: _resolveVizType(result),
        title: "Detail Analisis",
      ),
    );
  }

  /// Tentukan tipe visualisasi final (resolve 'auto')
  VizType _resolveVizType(RawQueryResult result) {
    if (vizType != VizType.auto) return vizType;

    // Auto-detect: jika ada kolom angka dan <= 8 baris → pie/bar
    // Jika banyak baris dengan kolom date → line
    final hasDateCol = result.columns.any(
      (c) =>
          c.toLowerCase().contains('date') ||
          c.toLowerCase().contains('tanggal'),
    );
    final numericCols = result.columns.where((c) {
      if (result.rows.isEmpty) return false;
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
