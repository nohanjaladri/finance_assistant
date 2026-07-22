import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

class QueryDetailScreen extends StatefulWidget {
  final String aiSummary;
  final List<String> columns;
  final List<Map<String, dynamic>> rows;
  final String? sqlQuery;
  final String vizType;

  const QueryDetailScreen({
    super.key,
    required this.aiSummary,
    required this.columns,
    required this.rows,
    this.sqlQuery,
    this.vizType = 'auto',
  });

  @override
  State<QueryDetailScreen> createState() => _QueryDetailScreenState();
}

class _QueryDetailScreenState extends State<QueryDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _viewTabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategoryFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _viewTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _viewTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredRows {
    return widget.rows.where((row) {
      final matchesSearch = _searchQuery.isEmpty ||
          row.values.any((v) => v.toString().toLowerCase().contains(_searchQuery.toLowerCase()));

      final categoryVal = (row['kategori'] ?? row['category'] ?? '').toString();
      final matchesCategory = _selectedCategoryFilter == 'Semua' ||
          categoryVal.toLowerCase() == _selectedCategoryFilter.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  num _getRowAmount(Map<String, dynamic> row) {
    for (final key in ['total_harga', 'total_amount', 'total', 'amount']) {
      if (row.containsKey(key) && row[key] is num) {
        return row[key] as num;
      }
    }
    if (row.containsKey('harga_satuan') && row['harga_satuan'] is num) {
      final price = row['harga_satuan'] as num;
      final qty = (row['jumlah'] ?? row['quantity'] ?? 1);
      if (qty is num) {
        return price * qty;
      }
      return price;
    }
    for (final entry in row.entries) {
      final k = entry.key.toLowerCase();
      if (k.contains('total') || k.contains('amount') || k.contains('nominal') || k.contains('harga')) {
        if (entry.value is num) {
          return entry.value as num;
        }
      }
    }
    return 0;
  }

  // Calculate Metrics
  num _totalAmountOf(List<Map<String, dynamic>> targetRows) {
    num total = 0;
    for (final row in targetRows) {
      total += _getRowAmount(row);
    }
    return total;
  }

  num get _avgAmount {
    if (widget.rows.isEmpty) return 0;
    return _totalAmountOf(widget.rows) / widget.rows.length;
  }

  Map<String, dynamic>? get _highestItem {
    if (widget.rows.isEmpty) return null;
    Map<String, dynamic>? highest;
    num maxVal = -1;
    for (final row in widget.rows) {
      final amt = _getRowAmount(row);
      if (amt > maxVal) {
        maxVal = amt;
        highest = row;
      }
    }
    return highest;
  }

  Set<String> get _categories {
    final set = <String>{'Semua'};
    for (final row in widget.rows) {
      final cat = row['kategori'] ?? row['category'];
      if (cat != null && cat.toString().isNotEmpty) {
        set.add(cat.toString());
      }
    }
    return set;
  }

  String _formatRupiah(num val) {
    final intVal = val.toInt();
    final str = intVal.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return "Rp ${buf.toString()}";
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('makan') || cat.contains('food') || cat.contains('kuliner') || cat.contains('minum')) {
      return Icons.fastfood_rounded;
    }
    if (cat.contains('trans') || cat.contains('bensin') || cat.contains('ojek') || cat.contains('parkir')) {
      return Icons.directions_car_rounded;
    }
    if (cat.contains('belanja') || cat.contains('shop') || cat.contains('mall')) {
      return Icons.shopping_bag_rounded;
    }
    if (cat.contains('tagihan') || cat.contains('bill') || cat.contains('listrik') || cat.contains('pulsa')) {
      return Icons.receipt_long_rounded;
    }
    if (cat.contains('hiburan') || cat.contains('movie') || cat.contains('game')) {
      return Icons.sports_esports_rounded;
    }
    return Icons.payments_rounded;
  }

  Color _getCategoryColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('makan') || cat.contains('food') || cat.contains('kuliner')) {
      return const Color(0xFFFF6B6B);
    }
    if (cat.contains('trans') || cat.contains('bensin') || cat.contains('ojek')) {
      return const Color(0xFF4D96FF);
    }
    if (cat.contains('belanja') || cat.contains('shop')) {
      return const Color(0xFF6C5CE7);
    }
    if (cat.contains('tagihan') || cat.contains('bill')) {
      return const Color(0xFFFFB142);
    }
    if (cat.contains('hiburan') || cat.contains('movie')) {
      return const Color(0xFFFF5252);
    }
    return const Color(0xFF5E5CE6);
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filteredRows;
    final totalVal = _totalAmountOf(rows);
    final avgVal = _avgAmount;
    final highest = _highestItem;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rincian Detail Analisis',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Asisten Keuangan AI • Data Terverifikasi',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.sqlQuery != null && widget.sqlQuery!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showSqlSheet(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5E5CE6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF5E5CE6).withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.terminal_rounded, color: Color(0xFF5E5CE6), size: 15),
                        SizedBox(width: 4),
                        Text(
                          'SQL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5E5CE6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Executive Summary & Dynamic Stat Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium Gradient Hero Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF312E81)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.auto_awesome_rounded, color: Colors.amberAccent, size: 14),
                                  SizedBox(width: 5),
                                  Text(
                                    'Laporan Eksekutif AI',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${widget.rows.length} Item',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'Total Keseluruhan',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatRupiah(totalVal),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.format_quote_rounded, color: Colors.white54, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.aiSummary,
                                  style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Mini KPI Cards Row (Average & Highest Item)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.functions_rounded, size: 14, color: Color(0xFF6366F1)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Rata-Rata Item',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatRupiah(avgVal),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.north_east_rounded, size: 14, color: Color(0xFFEF4444)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Item Termahal',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                highest != null
                                    ? (highest['item'] ?? highest['note'] ?? '-').toString()
                                    : '-',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Search Bar & Filter Chips
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Cari transaksi / item...',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),

                  if (_categories.length > 2) ...[
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _categories.map((cat) {
                          final isSelected = _selectedCategoryFilter == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(cat),
                              selected: isSelected,
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : const Color(0xFF475569),
                              ),
                              selectedColor: const Color(0xFF4F46E5),
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                              ),
                              onSelected: (_) {
                                setState(() => _selectedCategoryFilter = cat);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Segmented Switcher TabBar
                  Container(
                    height: 44,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _viewTabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      labelColor: const Color(0xFF4F46E5),
                      unselectedLabelColor: const Color(0xFF64748B),
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      tabs: const [
                        Tab(text: 'Kartu Item'),
                        Tab(text: 'Tabel Data'),
                        Tab(text: 'Grafik Chart'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Main Content Tab Views
          SliverFillRemaining(
            hasScrollBody: true,
            child: TabBarView(
              controller: _viewTabController,
              children: [
                _buildCardListView(rows),
                _buildTableView(rows),
                _buildChartView(rows),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // BUILDER 1: Card List View
  Widget _buildCardListView(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        final title = (row['item'] ?? row['note'] ?? 'Item ${index + 1}').toString();
        final qty = row['jumlah'] ?? row['quantity'] ?? 1;
        final category = (row['kategori'] ?? row['category'] ?? 'Umum').toString();
        final date = (row['tanggal'] ?? row['created_at'] ?? '').toString();

        final amount = _getRowAmount(row);

        final catColor = _getCategoryColor(category);
        final catIcon = _getCategoryIcon(category);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(catIcon, color: catColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(fontSize: 10, color: catColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (qty > 1) ...[
                          const SizedBox(width: 6),
                          Text(
                            'x$qty',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                          ),
                        ],
                        if (date.isNotEmpty) ...[
                          const Spacer(),
                          Text(
                            date.split('T')[0],
                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatRupiah(amount),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
              ),
            ],
          ),
        );
      },
    );
  }

  // BUILDER 2: Data Table View with Total Row
  Widget _buildTableView(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      return _buildEmptyState();
    }
    final totalVal = _totalAmountOf(rows);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            dataRowMinHeight: 40,
            dataRowMaxHeight: 48,
            columnSpacing: 22,
            horizontalMargin: 16,
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF475569),
            ),
            dataTextStyle: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1E293B),
            ),
            columns: widget.columns.map((c) {
              return DataColumn(
                label: Text(
                  c.toUpperCase().replaceAll('_', ' '),
                ),
              );
            }).toList(),
            rows: [
              ...rows.asMap().entries.map((e) {
                final row = e.value;
                final isEven = e.key % 2 == 0;
                return DataRow(
                  color: WidgetStateProperty.all(isEven ? Colors.white : const Color(0xFFFAFAFE)),
                  cells: widget.columns.map((col) {
                    final val = row[col];
                    String displayVal = val?.toString() ?? '-';
                    if (val is num && (col.toLowerCase().contains('amount') || col.toLowerCase().contains('total') || col.toLowerCase().contains('harga') || col.toLowerCase().contains('nominal') || col.toLowerCase().contains('biaya') || col.toLowerCase().contains('price'))) {
                      displayVal = _formatRupiah(val);
                    }
                    return DataCell(
                      Text(
                        displayVal,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
                );
              }),
              // Total Footer Row
              DataRow(
                color: WidgetStateProperty.all(const Color(0xFFEEF2FF)),
                cells: widget.columns.map((col) {
                  final cLower = col.toLowerCase();
                  if (col == widget.columns.first) {
                    return const DataCell(
                      Text('TOTAL SUMMARY', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                    );
                  }
                  if (cLower.contains('amount') || cLower.contains('total') || cLower.contains('harga') || cLower.contains('nominal')) {
                    return DataCell(
                      Text(_formatRupiah(totalVal), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                    );
                  }
                  return const DataCell(Text('-'));
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // BUILDER 3: Chart View
  Widget _buildChartView(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      return _buildEmptyState();
    }

    final List<BarChartGroupData> groups = [];
    int index = 0;
    for (final row in rows.take(10)) {
      final amount = _getRowAmount(row);
      groups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: amount.toDouble(),
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
          ],
        ),
      );
      index++;
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Visualisasi Nominal Top Items',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8),
                ],
              ),
              child: BarChart(
                BarChartData(
                  barGroups: groups,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < rows.length) {
                            final name = (rows[idx]['item'] ?? rows[idx]['note'] ?? '${idx + 1}').toString();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                name.length > 6 ? '${name.substring(0, 6)}..' : name,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('Data tidak ditemukan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  void _showSqlSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Color(0xFF0B0E17),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.terminal_rounded, color: Color(0xFF00E5FF), size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Query SQL PostgreSQL (AI Generated)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF00E5FF)),
                  tooltip: "Salin Query",
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.sqlQuery ?? ''));
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF05070C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: SelectableText(
                widget.sqlQuery ?? '',
                style: const TextStyle(
                  fontFamily: "monospace",
                  fontSize: 12,
                  color: Color(0xFF00E5FF),
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
