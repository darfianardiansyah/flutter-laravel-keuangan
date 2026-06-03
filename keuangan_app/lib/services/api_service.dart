import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction.dart';

// Service pusat untuk semua komunikasi Flutter ke Laravel API.
class ApiService {
  // Base URL menyesuaikan target runtime:
  // Android emulator memakai 10.0.2.2, desktop/web memakai localhost.
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }

    return 'http://127.0.0.1:8000/api';
  }

  // Mengambil token Bearer yang tersimpan agar session tetap login.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Menyimpan token setelah login/register berhasil.
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Menghapus token lokal saat logout atau session expired.
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // Mendaftarkan user baru, lalu menyimpan token dari Laravel Sanctum.
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      }),
    );

    final body = _decode(response);
    if (response.statusCode != 201) {
      throw Exception(_errorMessage(body));
    }

    await _saveToken(body['token']);
  }

  // Login user dan menyimpan token untuk request protected berikutnya.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = _decode(response);
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(body));
    }

    await _saveToken(body['token']);
  }

  // Logout di server dan membersihkan token lokal.
  Future<void> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 401) {
      throw Exception(_errorMessage(_decode(response)));
    }

    await clearToken();
  }

  // Mengambil daftar transaksi, optional difilter dengan format bulan yyyy-MM.
  Future<List<Transaction>> getTransactions({String? month}) async {
    final uri = Uri.parse('$baseUrl/transactions').replace(
      queryParameters: month == null ? null : {'month': month},
    );
    final response = await http.get(uri, headers: await _authHeaders());
    final body = _decode(response);

    _throwIfFailed(response.statusCode, body);

    return (body['data'] as List)
        .map((item) => Transaction.fromJson(item))
        .toList();
  }

  // Mengambil ringkasan saldo, pemasukan, dan pengeluaran dari API.
  Future<Map<String, double>> getSummary({String? month}) async {
    final uri = Uri.parse('$baseUrl/transactions/summary').replace(
      queryParameters: month == null ? null : {'month': month},
    );
    final response = await http.get(uri, headers: await _authHeaders());
    final body = _decode(response);

    _throwIfFailed(response.statusCode, body);

    final data = body['data'];
    return {
      'income': double.parse(data['income'].toString()),
      'expense': double.parse(data['expense'].toString()),
      'balance': double.parse(data['balance'].toString()),
    };
  }

  // Membuat transaksi baru di server.
  Future<Transaction> createTransaction(Transaction transaction) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: await _authHeaders(),
      body: jsonEncode(transaction.toJson()),
    );
    final body = _decode(response);

    if (response.statusCode != 201) {
      throw Exception(_errorMessage(body));
    }

    return Transaction.fromJson(body['data']);
  }

  // Mengubah transaksi yang sudah ada berdasarkan id.
  Future<Transaction> updateTransaction(
    int id,
    Transaction transaction,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: await _authHeaders(),
      body: jsonEncode(transaction.toJson()),
    );
    final body = _decode(response);

    _throwIfFailed(response.statusCode, body);

    return Transaction.fromJson(body['data']);
  }

  // Menghapus transaksi berdasarkan id.
  Future<void> deleteTransaction(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: await _authHeaders(),
    );

    _throwIfFailed(response.statusCode, _decode(response));
  }

  // Header standar request JSON.
  Map<String, String> _headers() => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  // Header request untuk endpoint yang membutuhkan Bearer Token.
  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      ..._headers(),
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Decode body JSON; response kosong dikembalikan sebagai map kosong.
  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // Menyeragamkan error HTTP agar UI cukup menampilkan SnackBar.
  void _throwIfFailed(int statusCode, Map<String, dynamic> body) {
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }

    if (statusCode == 401) {
      throw Exception('Sesi berakhir. Silakan login kembali.');
    }

    if (statusCode == 500) {
      throw Exception('Terjadi kesalahan server.');
    }

    throw Exception(_errorMessage(body));
  }

  // Mengambil pesan validasi Laravel paling relevan untuk user.
  String _errorMessage(Map<String, dynamic> body) {
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) {
        return first.first.toString();
      }
    }

    return body['message']?.toString() ?? 'Terjadi kesalahan.';
  }
}
