import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/category_stat.dart';

// Detail kategori berisi warna legenda, nominal, jumlah transaksi, dan persen.
class CategoryStatTile extends StatelessWidget {
  final CategoryStat stat;
  final Color color;

  const CategoryStatTile({
    super.key,
    required this.stat,
    required this.color,
  });

  String _currency(double value) {
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        stat.category,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${stat.count} transaksi'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _currency(stat.total),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text('${stat.percentage.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }
}
