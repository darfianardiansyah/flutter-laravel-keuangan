// Model statistik kategori untuk pie chart pemasukan dan pengeluaran.
class CategoryStat {
  final String category;
  final double total;
  final int count;
  final double percentage;

  CategoryStat({
    required this.category,
    required this.total,
    required this.count,
    required this.percentage,
  });

  // Mengubah item JSON statistik dari Laravel menjadi object Flutter.
  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      category: json['category'],
      total: double.parse(json['total'].toString()),
      count: int.parse(json['count'].toString()),
      percentage: double.parse(json['percentage'].toString()),
    );
  }
}
