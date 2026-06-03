# PRD: Pencatat Keuangan Pribadi
**Untuk AI Agent — Instruksi Pembangunan Aplikasi**

> Dokumen ini adalah spesifikasi teknis lengkap yang dapat langsung dieksekusi oleh AI Agent untuk membangun aplikasi Pencatat Keuangan Pribadi dari nol. Ikuti setiap bagian secara berurutan.

---

## Metadata Proyek

| Field | Value |
|---|---|
| Nama Aplikasi | Pencatat Keuangan Pribadi |
| Versi | 1.0.0 |
| Frontend | Flutter 3.x (Dart) |
| Backend | Laravel 11.x (PHP 8.2+) |
| Database | MySQL 8.x |
| Auth | Laravel Sanctum (Bearer Token) |
| State Management | setState (Flutter) |
| Target Platform | Android (API 23+) dan iOS 12+ |

---

## Daftar Isi

1. [Tujuan & Konteks](#1-tujuan--konteks)
2. [Struktur Direktori](#2-struktur-direktori)
3. [Setup & Konfigurasi](#3-setup--konfigurasi)
4. [Database & Migration](#4-database--migration)
5. [Backend Laravel — Model & Relasi](#5-backend-laravel--model--relasi)
6. [Backend Laravel — API Controllers](#6-backend-laravel--api-controllers)
7. [Backend Laravel — Routes](#7-backend-laravel--routes)
8. [Frontend Flutter — pubspec.yaml](#8-frontend-flutter--pubspecyaml)
9. [Frontend Flutter — Model](#9-frontend-flutter--model)
10. [Frontend Flutter — API Service](#10-frontend-flutter--api-service)
11. [Frontend Flutter — Screens](#11-frontend-flutter--screens)
12. [Frontend Flutter — Widgets](#12-frontend-flutter--widgets)
13. [Frontend Flutter — main.dart](#13-frontend-flutter--maindart)
14. [Spesifikasi API Lengkap](#14-spesifikasi-api-lengkap)
15. [Validasi & Error Handling](#15-validasi--error-handling)
16. [Aturan Bisnis](#16-aturan-bisnis)
17. [Kriteria Penerimaan](#17-kriteria-penerimaan)

---

## 1. Tujuan & Konteks

### Deskripsi Singkat
Aplikasi mobile untuk mencatat pemasukan dan pengeluaran pribadi. Pengguna dapat login, mencatat transaksi, memfilter per bulan, dan melihat ringkasan saldo bulanan. Data disimpan di server Laravel dan diakses melalui REST API.

### Fitur Utama (v1.0)
- Autentikasi (register, login, logout, persistent session)
- CRUD transaksi (tambah, lihat daftar, edit, hapus)
- Filter daftar dan ringkasan per bulan
- Kategorisasi transaksi (pemasukan & pengeluaran)
- Kartu ringkasan: saldo, total pemasukan, total pengeluaran

### Yang TIDAK dibangun di v1.0
- Grafik/chart visualisasi
- Notifikasi push
- Ekspor PDF/Excel
- Fitur offline-first
- Multi-akun

---

## 2. Struktur Direktori

AI Agent HARUS membuat file tepat pada path berikut:

### Laravel (Backend)
```
keuangan-backend/
├── app/
│   ├── Models/
│   │   ├── User.php                         # Edit: tambah relasi transactions()
│   │   └── Transaction.php                  # Buat baru
│   └── Http/
│       └── Controllers/
│           └── Api/
│               ├── AuthController.php        # Buat baru
│               └── TransactionController.php # Buat baru
├── database/
│   └── migrations/
│       └── xxxx_xx_xx_create_transactions_table.php  # Buat baru
├── routes/
│   └── api.php                              # Timpa isi default
└── .env                                     # Edit sesuai spesifikasi
```

### Flutter (Frontend)
```
keuangan_app/
├── lib/
│   ├── main.dart                            # Buat baru
│   ├── models/
│   │   └── transaction.dart                 # Buat baru
│   ├── services/
│   │   └── api_service.dart                 # Buat baru
│   ├── screens/
│   │   ├── login_screen.dart                # Buat baru
│   │   ├── home_screen.dart                 # Buat baru
│   │   └── form_screen.dart                 # Buat baru
│   └── widgets/
│       ├── summary_card.dart                # Buat baru
│       └── transaction_tile.dart            # Buat baru
├── pubspec.yaml                             # Edit: tambah dependencies
└── android/app/src/main/AndroidManifest.xml # Edit: tambah permission internet
```

---

## 3. Setup & Konfigurasi

### 3.1 Inisialisasi Laravel

Jalankan perintah berikut secara berurutan:

```bash
composer create-project laravel/laravel keuangan-backend
cd keuangan-backend
composer require laravel/sanctum
php artisan install:api
```

### 3.2 Konfigurasi `.env` Laravel

Ubah nilai berikut di file `.env`:

```env
APP_NAME=KeuanganAPI
APP_URL=http://localhost:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=keuangan_db
DB_USERNAME=root
DB_PASSWORD=

# Jika menggunakan SQLite untuk development:
# DB_CONNECTION=sqlite
# DB_DATABASE=/absolute/path/to/database.sqlite
```

### 3.3 Inisialisasi Flutter

```bash
flutter create keuangan_app
cd keuangan_app
```

### 3.4 Konfigurasi AndroidManifest.xml

File: `android/app/src/main/AndroidManifest.xml`

Tambahkan di dalam tag `<manifest>` (sebelum `<application>`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Tambahkan di dalam tag `<application>`:
```xml
android:usesCleartextTraffic="true"
```

> Atribut `usesCleartextTraffic="true"` diperlukan karena development menggunakan HTTP (bukan HTTPS). Hapus di production.

---

## 4. Database & Migration

### 4.1 Tabel `users` (sudah ada di Laravel default)

Pastikan kolom default tersedia: `id`, `name`, `email`, `password`, `email_verified_at`, `remember_token`, `created_at`, `updated_at`.

### 4.2 Tabel `transactions` — Buat Migration Baru

```bash
php artisan make:migration create_transactions_table
```

Isi migration:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->decimal('amount', 15, 2);
            $table->enum('type', ['income', 'expense']);
            $table->string('category');
            $table->date('date');
            $table->text('note')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
```

### 4.3 Jalankan Migration

```bash
php artisan migrate
```

### 4.4 Aturan Kolom Database

| Kolom | Tipe | Constraint | Keterangan |
|---|---|---|---|
| id | bigint unsigned | PK, auto increment | |
| user_id | bigint unsigned | FK → users.id, CASCADE DELETE | Pemilik transaksi |
| title | varchar(255) | NOT NULL | Keterangan transaksi |
| amount | decimal(15,2) | NOT NULL, > 0 | Nominal |
| type | enum | NOT NULL: 'income'\|'expense' | Jenis transaksi |
| category | varchar(100) | NOT NULL | Kategori |
| date | date | NOT NULL | Tanggal transaksi |
| note | text | NULLABLE | Catatan tambahan |
| created_at | timestamp | | |
| updated_at | timestamp | | |

---

## 5. Backend Laravel — Model & Relasi

### 5.1 `app/Models/Transaction.php` — Buat File Baru

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Transaction extends Model
{
    protected $fillable = [
        'user_id',
        'title',
        'amount',
        'type',
        'category',
        'date',
        'note',
    ];

    protected $casts = [
        'date'   => 'date',
        'amount' => 'decimal:2',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Scope: filter transaksi berdasarkan bulan.
     * Format parameter $month: 'yyyy-MM' (contoh: '2026-06')
     */
    public function scopeForMonth($query, string $month)
    {
        return $query
            ->whereYear('date', substr($month, 0, 4))
            ->whereMonth('date', substr($month, 5, 2));
    }
}
```

### 5.2 `app/Models/User.php` — Edit, Tambahkan Relasi

Tambahkan method berikut ke dalam class `User`:

```php
use Illuminate\Database\Eloquent\Relations\HasMany;

public function transactions(): HasMany
{
    return $this->hasMany(Transaction::class);
}
```

> Pastikan import `HasMany` ditambahkan di bagian `use` atas file.

---

## 6. Backend Laravel — API Controllers

### 6.1 `app/Http/Controllers/Api/AuthController.php`

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * POST /api/register
     * Body: { name, email, password, password_confirmation }
     * Response 201: { token, user: { id, name, email } }
     */
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = User::create([
            'name'     => $validated['name'],
            'email'    => $validated['email'],
            'password' => Hash::make($validated['password']),
        ]);

        $token = $user->createToken('flutter_app')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user'  => $user->only('id', 'name', 'email'),
        ], 201);
    }

    /**
     * POST /api/login
     * Body: { email, password }
     * Response 200: { token, user: { id, name, email } }
     * Error 422: jika email/password salah
     */
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Email atau password salah.'],
            ]);
        }

        // Hapus semua token lama, buat token baru
        $user->tokens()->delete();
        $token = $user->createToken('flutter_app')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user'  => $user->only('id', 'name', 'email'),
        ]);
    }

    /**
     * POST /api/logout  [Auth required]
     * Response 200: { message }
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logout berhasil']);
    }

    /**
     * GET /api/me  [Auth required]
     * Response 200: { data: { id, name, email, ... } }
     */
    public function me(Request $request): JsonResponse
    {
        return response()->json(['data' => $request->user()]);
    }
}
```

### 6.2 `app/Http/Controllers/Api/TransactionController.php`

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    /**
     * GET /api/transactions  [Auth required]
     * Query params: ?month=yyyy-MM (opsional)
     * Response 200: { data: Transaction[] }
     * Urutan: date DESC, id DESC
     */
    public function index(Request $request): JsonResponse
    {
        $query = $request->user()
            ->transactions()
            ->orderByDesc('date')
            ->orderByDesc('id');

        if ($request->filled('month')) {
            $query->forMonth($request->month);
        }

        return response()->json([
            'data' => $query->get(),
        ]);
    }

    /**
     * GET /api/transactions/summary  [Auth required]
     * Query params: ?month=yyyy-MM (opsional)
     * Response 200: { data: { income: float, expense: float, balance: float } }
     * PENTING: route ini harus didaftarkan SEBELUM apiResource agar tidak
     *          tertukar dengan GET /api/transactions/{transaction}
     */
    public function summary(Request $request): JsonResponse
    {
        $query = $request->user()->transactions();

        if ($request->filled('month')) {
            $query->forMonth($request->month);
        }

        $transactions = $query->get();
        $income  = $transactions->where('type', 'income')->sum('amount');
        $expense = $transactions->where('type', 'expense')->sum('amount');

        return response()->json([
            'data' => [
                'income'  => (float) $income,
                'expense' => (float) $expense,
                'balance' => (float) ($income - $expense),
            ],
        ]);
    }

    /**
     * POST /api/transactions  [Auth required]
     * Body: { title, amount, type, category, date, note? }
     * Response 201: { data: Transaction }
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title'    => 'required|string|max:255',
            'amount'   => 'required|numeric|min:0.01',
            'type'     => 'required|in:income,expense',
            'category' => 'required|string|max:100',
            'date'     => 'required|date',
            'note'     => 'nullable|string',
        ]);

        $transaction = $request->user()
            ->transactions()
            ->create($validated);

        return response()->json(['data' => $transaction], 201);
    }

    /**
     * PUT /api/transactions/{transaction}  [Auth required]
     * Body: { title, amount, type, category, date, note? }
     * Response 200: { data: Transaction }
     * Error 403: jika transaksi bukan milik user yang login
     */
    public function update(Request $request, Transaction $transaction): JsonResponse
    {
        if ($transaction->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $validated = $request->validate([
            'title'    => 'required|string|max:255',
            'amount'   => 'required|numeric|min:0.01',
            'type'     => 'required|in:income,expense',
            'category' => 'required|string|max:100',
            'date'     => 'required|date',
            'note'     => 'nullable|string',
        ]);

        $transaction->update($validated);

        return response()->json(['data' => $transaction->fresh()]);
    }

    /**
     * DELETE /api/transactions/{transaction}  [Auth required]
     * Response 200: { message }
     * Error 403: jika transaksi bukan milik user yang login
     */
    public function destroy(Request $request, Transaction $transaction): JsonResponse
    {
        if ($transaction->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $transaction->delete();

        return response()->json(['message' => 'Transaksi berhasil dihapus']);
    }
}
```

---

## 7. Backend Laravel — Routes

### `routes/api.php` — Timpa Seluruh Isi File

```php
<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\TransactionController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Public Routes — tidak butuh token
|--------------------------------------------------------------------------
*/
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login',    [AuthController::class, 'login']);

/*
|--------------------------------------------------------------------------
| Protected Routes — wajib menyertakan Bearer Token
|--------------------------------------------------------------------------
*/
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me',      [AuthController::class, 'me']);

    // PENTING: /summary harus SEBELUM apiResource
    // agar tidak dianggap sebagai {transaction} = "summary"
    Route::get('/transactions/summary', [TransactionController::class, 'summary']);
    Route::apiResource('transactions', TransactionController::class);
});
```

### Jalankan server

```bash
php artisan serve
# API tersedia di: http://localhost:8000/api
```

---

## 8. Frontend Flutter — pubspec.yaml

Tambahkan dependencies berikut ke `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  shared_preferences: ^2.2.2
  intl: ^0.19.0
```

Setelah edit, jalankan:

```bash
flutter pub get
```

---

## 9. Frontend Flutter — Model

### `lib/models/transaction.dart`

```dart
class Transaction {
  final int id;
  final String title;
  final double amount;
  final String type; // 'income' | 'expense'
  final String category;
  final String date; // format: 'yyyy-MM-dd'
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

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      title: json['title'],
      amount: double.parse(json['amount'].toString()),
      type: json['type'],
      category: json['category'],
      date: json['date'] is String
          ? json['date'].substring(0, 10)  // ambil 'yyyy-MM-dd' saja
          : json['date'].toString(),
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'amount': amount,
        'type': type,
        'category': category,
        'date': date,
        'note': note,
      };

  bool get isIncome => type == 'income';
}
```

---

## 10. Frontend Flutter — API Service

### `lib/services/api_service.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class ApiService {
  /// Base URL API Laravel.
  /// Android emulator  → 10.0.2.2
  /// iOS simulator     → 127.0.0.1
  /// Device fisik      → IP komputer (misal: 192.168.1.10)
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // ── Token helpers ──────────────────────────────────────────────────────

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── Auth ───────────────────────────────────────────────────────────────

  /// Login. Menyimpan token ke SharedPreferences.
  /// Throws Exception jika gagal.
  Future<void> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      await _saveToken(data['token']);
    } else {
      final errors = data['errors'] as Map<String, dynamic>?;
      final msg = errors?.values.first?.first ??
          data['message'] ??
          'Login gagal';
      throw Exception(msg);
    }
  }

  /// Logout. Menghapus token dari server dan SharedPreferences.
  Future<void> logout() async {
    final headers = await _headers();
    await http.post(Uri.parse('$baseUrl/logout'), headers: headers);
    await _removeToken();
  }

  // ── Transaksi ──────────────────────────────────────────────────────────

  /// Ambil daftar transaksi. [month] format 'yyyy-MM' (opsional).
  Future<List<Transaction>> getTransactions({String? month}) async {
    final uri = Uri.parse('$baseUrl/transactions').replace(
      queryParameters: month != null ? {'month': month} : null,
    );
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body)['data'];
      return data.map((e) => Transaction.fromJson(e)).toList();
    }
    throw Exception('Gagal memuat transaksi (${res.statusCode})');
  }

  /// Ambil ringkasan keuangan. [month] format 'yyyy-MM' (opsional).
  /// Returns: { 'income': double, 'expense': double, 'balance': double }
  Future<Map<String, dynamic>> getSummary({String? month}) async {
    final uri = Uri.parse('$baseUrl/transactions/summary').replace(
      queryParameters: month != null ? {'month': month} : null,
    );
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode == 200) return jsonDecode(res.body)['data'];
    throw Exception('Gagal memuat ringkasan (${res.statusCode})');
  }

  /// Tambah transaksi baru.
  Future<Transaction> createTransaction(Transaction t) async {
    final res = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: await _headers(),
      body: jsonEncode(t.toJson()),
    );
    if (res.statusCode == 201) {
      return Transaction.fromJson(jsonDecode(res.body)['data']);
    }
    throw Exception('Gagal menyimpan transaksi (${res.statusCode})');
  }

  /// Update transaksi berdasarkan [id].
  Future<Transaction> updateTransaction(int id, Transaction t) async {
    final res = await http.put(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: await _headers(),
      body: jsonEncode(t.toJson()),
    );
    if (res.statusCode == 200) {
      return Transaction.fromJson(jsonDecode(res.body)['data']);
    }
    throw Exception('Gagal memperbarui transaksi (${res.statusCode})');
  }

  /// Hapus transaksi berdasarkan [id].
  Future<void> deleteTransaction(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception('Gagal menghapus transaksi (${res.statusCode})');
    }
  }
}
```

---

## 11. Frontend Flutter — Screens

### 11.1 `lib/screens/login_screen.dart`

**Spesifikasi UI:**
- Ikon dompet di tengah atas
- Judul aplikasi
- Field email (TextInputType.emailAddress)
- Field password (obscureText: true)
- Tombol Masuk (FilledButton)
- Loading indicator saat request berjalan
- Pesan error merah di bawah field password jika login gagal

**Logika:**
- Panggil `ApiService().login(email, password)`
- Jika berhasil → `Navigator.pushReplacement` ke `HomeScreen`
- Jika gagal → tampilkan pesan error di bawah field password

```dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _api = ApiService();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _api.login(_emailCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  size: 64, color: Colors.indigo),
              const SizedBox(height: 12),
              const Text('Pencatat Keuangan',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 32),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Masuk'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### 11.2 `lib/screens/home_screen.dart`

**Spesifikasi UI:**
- AppBar: judul "Keuangan Saya" + ikon logout kanan
- Di bawah AppBar: baris pilih bulan (teks bulan + tombol "Ganti Bulan")
- `SummaryCard` menampilkan saldo, pemasukan, pengeluaran
- `ListView` berisi `TransactionTile` untuk setiap transaksi
- Jika list kosong: teks "Belum ada transaksi bulan ini."
- `FloatingActionButton` (+) untuk tambah transaksi
- `RefreshIndicator` untuk pull-to-refresh

**Logika:**
- `initState` → panggil `_load()`
- `_load()`: `Future.wait([getTransactions(month), getSummary(month)])` → update state
- Ganti bulan → `showDatePicker` → update `_selectedMonth` → `_load()`
- Tap FAB → `Navigator.push` ke `FormScreen(transaction: null)` → jika kembali `true` → `_load()`
- Tap tile → `Navigator.push` ke `FormScreen(transaction: existing)` → jika kembali `true` → `_load()`
- Swipe hapus → `_api.deleteTransaction(id)` → `_load()`
- Logout → `_api.logout()` → `Navigator.pushReplacement` ke `LoginScreen`

```dart
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
  List<Transaction> _transactions = [];
  Map<String, dynamic> _summary = {};
  bool _loading = true;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getTransactions(month: _selectedMonth),
        _api.getSummary(month: _selectedMonth),
      ]);
      setState(() {
        _transactions = results[0] as List<Transaction>;
        _summary     = results[1] as Map<String, dynamic>;
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(Transaction t) async {
    try {
      await _api.deleteTransaction(t.id);
      _load();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg.replaceFirst('Exception: ', '')),
      backgroundColor: Colors.red,
    ));
  }

  Future<void> _openForm([Transaction? existing]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FormScreen(transaction: existing)),
    );
    if (saved == true) _load();
  }

  Future<void> _logout() async {
    await _api.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final income  = (_summary['income']  ?? 0).toDouble();
    final expense = (_summary['expense'] ?? 0).toDouble();
    final balance = income - expense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keuangan Saya'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_outlined,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(_selectedMonth,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                              const Spacer(),
                              TextButton(
                                child: const Text('Ganti Bulan'),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _selectedMonth =
                                          DateFormat('yyyy-MM').format(picked);
                                    });
                                    _load();
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SummaryCard(
                              balance: balance,
                              income: income,
                              expense: expense),
                        ],
                      ),
                    ),
                  ),
                  if (_transactions.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text('Belum ada transaksi bulan ini.',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => TransactionTile(
                          transaction: _transactions[i],
                          onEdit: () => _openForm(_transactions[i]),
                          onDelete: () => _delete(_transactions[i]),
                        ),
                        childCount: _transactions.length,
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

---

### 11.3 `lib/screens/form_screen.dart`

**Spesifikasi UI:**
- AppBar: "Tambah Transaksi" atau "Edit Transaksi" sesuai mode
- `SegmentedButton`: pilih jenis (Pemasukan / Pengeluaran)
- Field keterangan (wajib)
- Field nominal dengan prefix "Rp " (wajib, keyboard angka)
- Dropdown kategori (berubah sesuai jenis yang dipilih)
- `ListTile` tanggal + `showDatePicker`
- Field catatan (opsional, multiline)
- Tombol simpan

**Kategori:**
- Pemasukan: `['Gaji', 'Bonus', 'Investasi', 'Lainnya']`
- Pengeluaran: `['Makanan', 'Transportasi', 'Belanja', 'Tagihan', 'Hiburan', 'Kesehatan', 'Lainnya']`

**Logika:**
- Mode edit: jika `widget.transaction != null`, prefill semua field dari data yang ada
- Mode tambah: jika `widget.transaction == null`, semua field kosong, tanggal = hari ini
- Validasi: title dan amount tidak boleh kosong → tampilkan SnackBar
- Simpan: panggil `createTransaction` atau `updateTransaction` → `Navigator.pop(context, true)`

```dart
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
  final _titleCtrl  = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();
  final _api        = ApiService();

  String   _type     = 'expense';
  String   _category = 'Makanan';
  DateTime _date     = DateTime.now();
  bool     _loading  = false;

  static const _incomeCategories  = ['Gaji', 'Bonus', 'Investasi', 'Lainnya'];
  static const _expenseCategories = [
    'Makanan', 'Transportasi', 'Belanja',
    'Tagihan', 'Hiburan', 'Kesehatan', 'Lainnya'
  ];

  List<String> get _categories =>
      _type == 'income' ? _incomeCategories : _expenseCategories;

  bool get _isEdit => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final t = widget.transaction!;
      _titleCtrl.text  = t.title;
      _amountCtrl.text = t.amount.toStringAsFixed(0);
      _noteCtrl.text   = t.note ?? '';
      _type            = t.type;
      _category        = t.category;
      _date            = DateTime.parse(t.date);
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
    if (_titleCtrl.text.isEmpty || _amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keterangan dan nominal wajib diisi')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final t = Transaction(
        id:       widget.transaction?.id ?? 0,
        title:    _titleCtrl.text.trim(),
        amount:   double.parse(_amountCtrl.text.replaceAll(',', '')),
        type:     _type,
        category: _category,
        date:     DateFormat('yyyy-MM-dd').format(_date),
        note:     _noteCtrl.text.isNotEmpty ? _noteCtrl.text.trim() : null,
      );

      if (_isEdit) {
        await _api.updateTransaction(t.id, t);
      } else {
        await _api.createTransaction(t);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _loading = false);
    }
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
                ButtonSegment(value: 'income',  label: Text('Pemasukan'),
                    icon: Icon(Icons.arrow_downward, color: Colors.green)),
                ButtonSegment(value: 'expense', label: Text('Pengeluaran'),
                    icon: Icon(Icons.arrow_upward, color: Colors.red)),
              ],
              selected: {_type},
              onSelectionChanged: (val) => setState(() {
                _type     = val.first;
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
                labelText: 'Nominal (Rp)',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(DateFormat('dd MMMM yyyy', 'id').format(_date)),
              subtitle: const Text('Tanggal transaksi'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const Divider(),
            const SizedBox(height: 4),
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 12. Frontend Flutter — Widgets

### 12.1 `lib/widgets/summary_card.dart`

**Spesifikasi:** Container biru gradient, tampilkan saldo besar di atas, pemasukan dan pengeluaran berdampingan di bawah dengan ikon warna berbeda.

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;

  const SummaryCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
  });

  String _fmt(double v) =>
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0)
          .format(v);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Saldo Bulan Ini',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(_fmt(balance),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                    icon: Icons.arrow_downward_rounded,
                    iconColor: Colors.greenAccent,
                    label: 'Pemasukan',
                    value: _fmt(income)),
              ),
              Expanded(
                child: _SummaryItem(
                    icon: Icons.arrow_upward_rounded,
                    iconColor: Colors.redAccent,
                    label: 'Pengeluaran',
                    value: _fmt(expense)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 11)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
```

---

### 12.2 `lib/widgets/transaction_tile.dart`

**Spesifikasi:**
- Ikon kategori di `CircleAvatar` (hijau untuk pemasukan, merah untuk pengeluaran)
- Judul transaksi, subtitle: kategori + tanggal
- Nominal di kanan dengan warna +hijau / -merah
- Ikon catatan kecil jika ada note
- `Dismissible` dengan swipe kiri → kanan memunculkan background merah + ikon hapus
- Dialog konfirmasi sebelum hapus
- Tap item → `onEdit`

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

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

  static const _icons = <String, IconData>{
    'Makanan':      Icons.restaurant,
    'Transportasi': Icons.directions_car,
    'Belanja':      Icons.shopping_bag,
    'Tagihan':      Icons.receipt_long,
    'Hiburan':      Icons.movie,
    'Kesehatan':    Icons.medical_services,
    'Gaji':         Icons.work,
    'Bonus':        Icons.star,
    'Investasi':    Icons.trending_up,
    'Lainnya':      Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final fmt = NumberFormat.currency(
        locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Dismissible(
      key: Key('txn-${transaction.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Hapus transaksi?'),
            content: Text('Hapus "${transaction.title}"?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Hapus',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isIncome ? Colors.green.shade50 : Colors.red.shade50,
          child: Icon(
            _icons[transaction.category] ?? Icons.attach_money,
            color: isIncome ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(transaction.title,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${transaction.category} · ${transaction.date}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncome ? '+' : '-'}${fmt.format(transaction.amount)}',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isIncome ? Colors.green : Colors.red),
            ),
            if (transaction.note != null && transaction.note!.isNotEmpty)
              const Icon(Icons.note_outlined, size: 12, color: Colors.grey),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}
```

---

## 13. Frontend Flutter — main.dart

### `lib/main.dart`

**Logika splash:**
1. Inisialisasi `intl` locale Indonesia
2. Cek token di `SharedPreferences`
3. Ada token → `HomeScreen`, tidak ada → `LoginScreen`

```dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pencatat Keuangan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const _SplashDecider(),
    );
  }
}

class _SplashDecider extends StatefulWidget {
  const _SplashDecider();

  @override
  State<_SplashDecider> createState() => _SplashDeciderState();
}

class _SplashDeciderState extends State<_SplashDecider> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            token != null ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
```

---

## 14. Spesifikasi API Lengkap

### Base URL
```
http://10.0.2.2:8000/api           ← Android emulator
http://127.0.0.1:8000/api          ← iOS simulator
http://<IP_KOMPUTER>:8000/api      ← Device fisik
```

### Header Standar
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer {token}      ← untuk endpoint terproteksi
```

### Endpoint & Contoh Response

#### POST /api/login
Request:
```json
{ "email": "user@example.com", "password": "password123" }
```
Response 200:
```json
{
  "token": "1|abc123...",
  "user": { "id": 1, "name": "Budi", "email": "user@example.com" }
}
```
Response 422 (salah password):
```json
{
  "message": "The given data was invalid.",
  "errors": { "email": ["Email atau password salah."] }
}
```

#### GET /api/transactions?month=2026-06
Response 200:
```json
{
  "data": [
    {
      "id": 5,
      "user_id": 1,
      "title": "Makan siang",
      "amount": "25000.00",
      "type": "expense",
      "category": "Makanan",
      "date": "2026-06-03",
      "note": null,
      "created_at": "2026-06-03T10:00:00.000000Z",
      "updated_at": "2026-06-03T10:00:00.000000Z"
    }
  ]
}
```

#### GET /api/transactions/summary?month=2026-06
Response 200:
```json
{
  "data": {
    "income": 5000000.0,
    "expense": 1250000.0,
    "balance": 3750000.0
  }
}
```

#### POST /api/transactions
Request:
```json
{
  "title": "Makan siang",
  "amount": 25000,
  "type": "expense",
  "category": "Makanan",
  "date": "2026-06-03",
  "note": "Nasi padang"
}
```
Response 201:
```json
{ "data": { "id": 6, "title": "Makan siang", ... } }
```

#### PUT /api/transactions/6
Request: sama dengan POST
Response 200:
```json
{ "data": { "id": 6, "title": "Makan siang (updated)", ... } }
```

#### DELETE /api/transactions/6
Response 200:
```json
{ "message": "Transaksi berhasil dihapus" }
```

---

## 15. Validasi & Error Handling

### Laravel — Aturan Validasi

| Field | Aturan |
|---|---|
| name | required, string, max:255 |
| email | required, email, unique:users |
| password | required, string, min:8, confirmed |
| title | required, string, max:255 |
| amount | required, numeric, min:0.01 |
| type | required, in:income,expense |
| category | required, string, max:100 |
| date | required, date |
| note | nullable, string |

### Flutter — Pola Error Handling

```dart
// Setiap API call dibungkus try-catch
try {
  // panggil API
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(e.toString().replaceFirst('Exception: ', '')),
      backgroundColor: Colors.red,
    ),
  );
}
```

### HTTP Status Code yang Ditangani

| Status | Situasi | Tindakan Flutter |
|---|---|---|
| 200 | Sukses | Parse response, update state |
| 201 | Dibuat | Parse response, pop screen dengan `true` |
| 401 | Token tidak valid / expired | Redirect ke LoginScreen |
| 403 | Bukan milik user ini | Tampilkan SnackBar error |
| 422 | Validasi gagal | Tampilkan pesan error dari `errors` |
| 500 | Server error | Tampilkan SnackBar "Terjadi kesalahan server" |

---

## 16. Aturan Bisnis

1. **Isolasi data per user** — Setiap transaksi terikat ke `user_id`. User hanya bisa melihat, mengedit, dan menghapus transaksi miliknya sendiri.

2. **Validasi kepemilikan di server** — Controller mengecek `$transaction->user_id !== $request->user()->id` dan mengembalikan 403 jika tidak sesuai. Jangan hanya mengandalkan validasi di Flutter.

3. **Token satu aktif** — Saat login berhasil, semua token lama dihapus (`$user->tokens()->delete()`) sebelum token baru dibuat. Ini mencegah penumpukan token.

4. **Filter bulan opsional** — Jika parameter `?month` tidak disertakan, API mengembalikan SEMUA transaksi user (tanpa filter bulan). Flutter selalu mengirim `month` kecuali user belum memilih.

5. **Nominal selalu positif** — `amount` minimal 0.01. Jenis transaksi (income/expense) menentukan apakah ini pemasukan atau pengeluaran, bukan tanda negatif pada nominal.

6. **Kategori tidak disimpan sebagai enum** — Disimpan sebagai `varchar` agar mudah dikembangkan (tambah kategori baru tidak perlu migration).

7. **Format tanggal konsisten** — Selalu gunakan `yyyy-MM-dd` antara Flutter dan Laravel. Flutter mengambil 10 karakter pertama dari response date untuk mengabaikan timestamp.

---

## 17. Kriteria Penerimaan

AI Agent dinyatakan selesai jika seluruh poin berikut terpenuhi:

### Status Progres per 2026-06-03

Ringkasan tahapan yang sudah dilakukan:

- [x] Backend Laravel berhasil dibuat di `keuangan-backend/`.
- [x] Laravel Sanctum berhasil dipasang untuk autentikasi Bearer Token.
- [x] Model `Transaction`, relasi `User::transactions()`, migration transaksi, controller auth, controller transaksi, dan route API sudah dibuat.
- [x] Test backend sudah dibuat di `keuangan-backend/tests/Feature/FinanceApiTest.php`.
- [x] Test backend terakhir lulus: `7 passed (40 assertions)`.
- [x] Struktur Flutter berhasil dibuat di `keuangan_app/`.
- [x] File Flutter utama sudah dibuat: model, API service, login/register screen, home screen, form screen, summary card, dan transaction tile.
- [x] Flutter CLI tersedia: Flutter 3.44.1 stable.
- [x] `flutter pub get` berhasil dan `pubspec.lock` sudah dibuat.
- [x] `flutter analyze` lulus: `No issues found`.
- [x] Komentar `//` sudah ditambahkan pada kode Flutter untuk menjelaskan fungsi fitur dan method penting.
- [ ] `flutter run` belum berhasil karena belum ada device Android/iOS terhubung.
- [ ] Integrasi mobile ke Laravel belum diuji langsung karena belum ada device Android/iOS.

Commit tahapan yang sudah dibuat:

- `5af98b7 chore(backend): siapkan project laravel`
- `6cbff33 feat(backend): tambah api transaksi dan autentikasi`
- `eb7d44c test(backend): tambah pengujian api keuangan`
- `8b57605 chore(frontend): siapkan struktur flutter`
- `8c0939f feat(frontend): tambah alur pencatat keuangan`
- `0788eea docs: tambah panduan menjalankan project`
- `448bbcd chore(frontend): kunci dependency flutter`
- `9001f11 refactor(frontend): jelaskan alur core flutter`
- `f07bfc9 refactor(frontend): jelaskan fitur auth dan dashboard`
- `f5dd920 refactor(frontend): jelaskan fitur transaksi`

Catatan blokir:

- `flutter run` belum bisa dilanjutkan karena tidak ada device Android/iOS yang tersedia.
- Device yang terdeteksi sebelumnya adalah Windows, Chrome, dan Edge, tetapi project belum dibuat untuk target desktop/web karena target PRD adalah Android dan iOS.
- Tahap berikutnya: hubungkan emulator/device Android atau simulator iOS, jalankan Laravel di `localhost:8000`, lalu jalankan `flutter run`.

### Backend Laravel
- [x] Migration `create_transactions_table` berhasil dijalankan tanpa error di test environment
- [x] `POST /api/register` membuat user baru dan mengembalikan token
- [x] `POST /api/login` mengembalikan token jika kredensial benar, 422 jika salah
- [x] `POST /api/logout` menghapus token aktif
- [x] `GET /api/transactions` mengembalikan hanya transaksi milik user yang login
- [x] `GET /api/transactions?month=yyyy-MM` memfilter transaksi berdasarkan bulan
- [x] `GET /api/transactions/summary` mengembalikan income, expense, balance yang akurat
- [x] `POST /api/transactions` membuat transaksi baru dengan validasi lengkap
- [x] `PUT /api/transactions/{id}` mengembalikan 403 jika bukan milik user
- [x] `DELETE /api/transactions/{id}` mengembalikan 403 jika bukan milik user
- [x] Semua endpoint terproteksi mengembalikan 401 tanpa token

### Frontend Flutter
- [x] Aplikasi langsung ke HomeScreen jika token tersimpan, ke LoginScreen jika tidak (kode dibuat dan analyzer lulus)
- [x] Login berhasil menyimpan token dan berpindah ke HomeScreen (kode dibuat dan analyzer lulus)
- [x] Logout menghapus token dan kembali ke LoginScreen (kode dibuat dan analyzer lulus)
- [x] HomeScreen menampilkan SummaryCard dan daftar transaksi bulan berjalan (kode dibuat dan analyzer lulus)
- [x] Ganti bulan memperbarui daftar dan ringkasan (kode dibuat dan analyzer lulus)
- [x] Pull-to-refresh memuat ulang data (kode dibuat dan analyzer lulus)
- [x] FAB membuka FormScreen kosong (kode dibuat dan analyzer lulus)
- [x] Tap item transaksi membuka FormScreen dengan data prefill (kode dibuat dan analyzer lulus)
- [x] Swipe kiri → konfirmasi → hapus transaksi dari daftar (kode dibuat dan analyzer lulus)
- [x] Form menolak submit jika keterangan atau nominal kosong (kode dibuat dan analyzer lulus)
- [x] Semua error API ditampilkan sebagai SnackBar merah, bukan crash (kode dibuat dan analyzer lulus)

### Integrasi
- [ ] Flutter dapat berkomunikasi dengan Laravel yang berjalan di `localhost:8000` (belum diuji karena belum ada device Android/iOS)
- [ ] Data yang ditambah via Flutter langsung muncul setelah refresh (belum diuji karena belum ada device Android/iOS)
- [x] Nominal ditampilkan dalam format Rupiah (`Rp 25.000`) (kode dibuat dan analyzer lulus)
- [x] Tanggal ditampilkan dalam format yang terbaca (`03 Juni 2026`) (kode dibuat dan analyzer lulus)

---

*Setelah semua kriteria terpenuhi, aplikasi v1.0 siap digunakan dan siap dikembangkan ke fitur v1.1 (grafik & pencarian).*
