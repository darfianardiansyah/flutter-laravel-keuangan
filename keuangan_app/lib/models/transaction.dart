// Model data transaksi yang dipakai oleh UI dan API service.
class Transaction {
  final int id;
  final String title;
  final double amount;
  final String type;
  final String category;
  final String date;
  final String? note;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
  });

  // Mengubah response JSON Laravel menjadi object Transaction di Flutter.
  factory Transaction.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'].toString();

    return Transaction(
      id: json['id'] ?? 0,
      title: json['title'],
      amount: double.parse(json['amount'].toString()),
      type: json['type'],
      category: json['category'],
      date: rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate,
      note: json['note'],
    );
  }

  // Mengubah Transaction menjadi JSON untuk request create/update ke API.
  Map<String, dynamic> toJson() => {
        'title': title,
        'amount': amount,
        'type': type,
        'category': category,
        'date': date,
        'note': note,
      };

  // Membantu UI menentukan warna dan tanda nominal transaksi.
  bool get isIncome => type == 'income';
}
