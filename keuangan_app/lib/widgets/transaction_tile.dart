import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';

// Baris transaksi yang mendukung tap untuk edit dan swipe untuk hapus.
class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  // Mapping kategori ke ikon agar daftar transaksi lebih mudah dipindai.
  static const _icons = <String, IconData>{
    'Makanan': Icons.restaurant,
    'Transportasi': Icons.directions_car,
    'Belanja': Icons.shopping_bag,
    'Tagihan': Icons.receipt_long,
    'Hiburan': Icons.movie,
    'Kesehatan': Icons.medical_services,
    'Gaji': Icons.work,
    'Bonus': Icons.star,
    'Investasi': Icons.trending_up,
    'Lainnya': Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    // Warna dan tanda nominal mengikuti tipe income/expense.
    final isIncome = transaction.isIncome;
    final currency = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final date = DateFormat('dd MMMM yyyy', 'id')
        .format(DateTime.parse(transaction.date));

    return Dismissible(
      // Swipe kiri menampilkan aksi hapus dengan konfirmasi dialog.
      key: Key('transaction-${transaction.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        // Konfirmasi mencegah transaksi terhapus tanpa sengaja.
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Hapus transaksi?'),
            content: Text('Hapus "${transaction.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Hapus',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: ListTile(
        // Icon kategori membantu membedakan transaksi tanpa membaca penuh.
        leading: CircleAvatar(
          backgroundColor:
              isIncome ? Colors.green.shade50 : Colors.red.shade50,
          child: Icon(
            _icons[transaction.category] ?? Icons.attach_money,
            color: isIncome ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          transaction.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${transaction.category} - $date',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncome ? '+' : '-'}${currency.format(transaction.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            if (transaction.note != null && transaction.note!.isNotEmpty)
              // Ikon catatan memberi sinyal ada detail tambahan.
              const Icon(Icons.note_outlined, size: 12, color: Colors.grey),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}
