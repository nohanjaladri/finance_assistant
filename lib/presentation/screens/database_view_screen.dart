import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';

class DatabaseViewScreen extends StatefulWidget {
  const DatabaseViewScreen({super.key});

  @override
  State<DatabaseViewScreen> createState() => _DatabaseViewScreenState();
}

class _DatabaseViewScreenState extends State<DatabaseViewScreen> {
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final source = TransactionDataSource(finance.history);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          "Database Transaksi",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        iconTheme: const IconThemeData(color: Colors.deepPurple),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: PaginatedDataTable(
          header: const Text(
            "Seluruh Data Lokal",
            style: TextStyle(fontSize: 16),
          ),
          rowsPerPage: _rowsPerPage,
          availableRowsPerPage: const [10, 20, 50, 100],
          onRowsPerPageChanged: (value) {
            if (value != null) {
              setState(() {
                _rowsPerPage = value;
              });
            }
          },
          columnSpacing: 25,
          horizontalMargin: 20,
          showCheckboxColumn: false,
          columns: const [
            DataColumn(
              label: Text("ID", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text(
                "Waktu",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                "Keterangan",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                "Tipe",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                "Kategori",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                "Nominal",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          source: source,
        ),
      ),
    );
  }
}

class TransactionDataSource extends DataTableSource {
  final List<Map<String, dynamic>> _data;

  TransactionDataSource(this._data);

  String _formatRupiah(int amount) {
    final str = amount.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return amount < 0 ? '-Rp ${buf.toString()}' : 'Rp ${buf.toString()}';
  }

  String _formatDate(String isoString) {
    try {
      final d = DateTime.parse(isoString).toLocal();
      return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoString;
    }
  }

  @override
  DataRow? getRow(int index) {
    if (index >= _data.length) return null;
    final item = _data[index];
    final isIn = item['type'] == 'IN';

    return DataRow(
      cells: [
        DataCell(Text(item['id'].toString())),
        DataCell(Text(_formatDate(item['date'] ?? ''))),
        DataCell(Text(item['note'] ?? '')),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isIn
                  ? Colors.teal.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item['type'] ?? '',
              style: TextStyle(
                color: isIn ? Colors.teal : Colors.deepOrange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(Text(item['category'] ?? '')),
        DataCell(
          Text(
            _formatRupiah(item['amount'] as int),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _data.length;

  @override
  int get selectedRowCount => 0;
}
