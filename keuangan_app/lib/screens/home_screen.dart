import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../services/api_service.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';
import 'form_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();

  DateTime _selectedMonth = DateTime.now();
  List<Transaction> _transactions = [];
  double _income = 0;
  double _expense = 0;
  double _balance = 0;
  bool _loading = true;

  String get _monthParam => DateFormat('yyyy-MM').format(_selectedMonth);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        _api.getTransactions(month: _monthParam),
        _api.getSummary(month: _monthParam),
      ]);

      final summary = results[1] as Map<String, double>;
      setState(() {
        _transactions = results[0] as List<Transaction>;
        _income = summary['income'] ?? 0;
        _expense = summary['expense'] ?? 0;
        _balance = summary['balance'] ?? 0;
      });
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
      if (e.toString().contains('Sesi berakhir')) {
        await _goToLogin();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih bulan',
    );

    if (picked == null) return;

    setState(() => _selectedMonth = DateTime(picked.year, picked.month));
    await _loadData();
  }

  Future<void> _openForm(Transaction? transaction) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FormScreen(transaction: transaction),
      ),
    );

    if (changed == true) {
      await _loadData();
    }
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    try {
      await _api.deleteTransaction(transaction.id);
      await _loadData();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _logout() async {
    try {
      await _api.logout();
      await _goToLogin();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _goToLogin() async {
    await _api.clearToken();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
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
        title: const Text('Pencatat Keuangan'),
        actions: [
          IconButton(
            onPressed: _selectMonth,
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Pilih bulan',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(null),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
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
            SummaryCard(
              balance: _balance,
              income: _income,
              expense: _expense,
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: Text('Belum ada transaksi bulan ini.')),
              )
            else
              ..._transactions.map(
                (transaction) => TransactionTile(
                  transaction: transaction,
                  onEdit: () => _openForm(transaction),
                  onDelete: () => _deleteTransaction(transaction),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
