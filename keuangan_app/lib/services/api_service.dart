import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

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

  Future<void> deleteTransaction(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: await _authHeaders(),
    );

    _throwIfFailed(response.statusCode, _decode(response));
  }

  Map<String, String> _headers() => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      ..._headers(),
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

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
