# Pencatat Keuangan Pribadi

Aplikasi pencatat pemasukan dan pengeluaran pribadi berbasis Laravel API dan Flutter mobile.

## Struktur Project

```text
keuangan-backend/  Laravel API dengan Sanctum
keuangan_app/      Flutter mobile app
ai-workspace/      PRD, guideline, dan dokumen kerja project
```

## Backend Laravel

Masuk ke folder backend:

```bash
cd keuangan-backend
composer install
cp .env.example .env
php artisan key:generate
```

Atur database di `.env`:

```env
APP_NAME=KeuanganAPI
APP_URL=http://localhost:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=keuangan_db
DB_USERNAME=root
DB_PASSWORD=
```

Jalankan migration dan server:

```bash
php artisan migrate
php artisan serve
```

API tersedia di:

```text
http://localhost:8000/api
```

Test backend:

```bash
php artisan test
```

## Frontend Flutter

Masuk ke folder Flutter:

```bash
cd keuangan_app
flutter pub get
flutter run
```

Base URL API berada di:

```text
lib/services/api_service.dart
```

Default untuk Android emulator:

```text
http://10.0.2.2:8000/api
```

Untuk device fisik, ganti dengan IP komputer yang menjalankan Laravel, misalnya:

```text
http://192.168.1.10:8000/api
```

## Fitur v1.0

- Register, login, logout, dan persistent session.
- CRUD transaksi pemasukan dan pengeluaran.
- Filter transaksi berdasarkan bulan.
- Ringkasan saldo, total pemasukan, dan total pengeluaran.
- Validasi server untuk kepemilikan data per user.
- Tampilan nominal Rupiah dan tanggal Indonesia.
