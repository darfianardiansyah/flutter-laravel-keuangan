import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/category_stat.dart';
import '../services/api_service.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/category_stat_tile.dart';

// Layar statistik bulanan untuk melihat komposisi kategori transaksi.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _api = ApiService();

  DateTime _selectedMonth = DateTime.now();
  String _type = 'expense';
  List<CategoryStat> _incomeStats = [];
  List<CategoryStat> _expenseStats = [];
  bool _loading = true;

  static const _colors = [
    Color(0xFF3F51B5),
    Color(0xFF009688),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF607D8B),
    Color(0xFF8BC34A),
    Color(0xFF9C27B0),
    Color(0xFFFF5722),
  ];

  // Format query month yang dipakai endpoint statistik Laravel.
  String get _monthParam => DateFormat('yyyy-MM').format(_selectedMonth);

  // Data aktif mengikuti segmented control pemasukan/pengeluaran.
  List<CategoryStat> get _activeStats =>
      _type == 'income' ? _incomeStats : _expenseStats;

  String get _emptyMessage => _type == 'income'
      ? 'Belum ada data pemasukan bulan ini.'
      : 'Belum ada data pengeluaran bulan ini.';

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _loading = true);

    try {
      final result = await _api.getStatistics(month: _monthParam);
      setState(() {
        _incomeStats = result['income'] ?? [];
        _expenseStats = result['expense'] ?? [];
      });
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectMonth() async {
    // Date picker dipakai untuk memilih bulan statistik.
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih bulan statistik',
    );

    if (picked == null) return;

    setState(() => _selectedMonth = DateTime(picked.year, picked.month));
    await _loadStatistics();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy', 'id').format(_selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Bulanan'),
        actions: [
          IconButton(
            onPressed: _selectMonth,
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Pilih bulan',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    monthLabel,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _selectMonth,
                  icon: const Icon(Icons.tune),
                  label: const Text('Filter'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'income',
                  label: Text('Pemasukan'),
                  icon: Icon(Icons.arrow_downward, color: Colors.green),
                ),
                ButtonSegment(
                  value: 'expense',
                  label: Text('Pengeluaran'),
                  icon: Icon(Icons.arrow_upward, color: Colors.red),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (value) => setState(() {
                _type = value.first;
              }),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 72),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              CategoryPieChart(
                stats: _activeStats,
                colors: _colors,
                emptyMessage: _emptyMessage,
              ),
              const SizedBox(height: 12),
              Text(
                _type == 'income'
                    ? 'Detail Pemasukan'
                    : 'Detail Pengeluaran',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_activeStats.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(child: Text(_emptyMessage)),
                )
              else
                for (var i = 0; i < _activeStats.length; i++)
                  CategoryStatTile(
                    stat: _activeStats[i],
                    color: _colors[i % _colors.length],
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
