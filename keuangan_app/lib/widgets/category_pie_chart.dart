import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/category_stat.dart';

// Pie chart untuk menampilkan komposisi kategori pemasukan/pengeluaran.
class CategoryPieChart extends StatelessWidget {
  final List<CategoryStat> stats;
  final List<Color> colors;
  final String emptyMessage;

  const CategoryPieChart({
    super.key,
    required this.stats,
    required this.colors,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(child: Text(emptyMessage)),
      );
    }

    return SizedBox(
      height: 240,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 48,
          sectionsSpace: 2,
          sections: [
            for (var i = 0; i < stats.length; i++)
              PieChartSectionData(
                value: stats[i].total,
                color: colors[i % colors.length],
                radius: 82,
                title: stats[i].percentage >= 7
                    ? '${stats[i].percentage.toStringAsFixed(1)}%'
                    : '',
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
