import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../services/api_service.dart';

class FormScreen extends StatefulWidget {
  final Transaction? transaction;

  const FormScreen({super.key, this.transaction});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _api = ApiService();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _type = 'expense';
  String _category = 'Makanan';
  DateTime _date = DateTime.now();
  bool _loading = false;

  bool get _isEdit => widget.transaction != null;

  List<String> get _categories => _type == 'income'
      ? ['Gaji', 'Bonus', 'Investasi', 'Lainnya']
      : [
          'Makanan',
          'Transportasi',
          'Belanja',
          'Tagihan',
          'Hiburan',
          'Kesehatan',
          'Lainnya',
        ];

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    if (transaction != null) {
      _titleCtrl.text = transaction.title;
      _amountCtrl.text = transaction.amount.toStringAsFixed(0);
      _noteCtrl.text = transaction.note ?? '';
      _type = transaction.type;
      _category = transaction.category;
      _date = DateTime.parse(transaction.date);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.replaceAll('.', ''));

    if (title.isEmpty) {
      _showError('Keterangan wajib diisi.');
      return;
    }

    if (amount == null || amount <= 0) {
      _showError('Nominal wajib diisi dan lebih dari 0.');
      return;
    }

    setState(() => _loading = true);

    try {
      final transaction = Transaction(
        id: widget.transaction?.id ?? 0,
        title: title,
        amount: amount,
        type: _type,
        category: _category,
        date: DateFormat('yyyy-MM-dd').format(_date),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );

      if (_isEdit) {
        await _api.updateTransaction(transaction.id, transaction);
      } else {
        await _api.createTransaction(transaction);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Transaksi' : 'Tambah Transaksi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                _category = _categories.first;
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Keterangan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _categories.contains(_category)
                  ? _category
                  : _categories.first,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(DateFormat('dd MMMM yyyy', 'id').format(_date)),
              subtitle: const Text('Tanggal transaksi'),
              onTap: _pickDate,
            ),
            const Divider(),
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan opsional',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loading ? null : _save,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isEdit ? 'Simpan Perubahan' : 'Tambah'),
            ),
          ],
        ),
      ),
    );
  }
}
