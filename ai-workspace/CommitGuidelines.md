# Git Commit Guidelines

Panduan ini digunakan untuk menjaga konsistensi commit di dalam project.

## Format Commit

Gunakan format berikut:

```text
<type>(optional-scope): <deskripsi singkat>
```

Contoh:

```text
feat: tambah fitur catat transaksi
fix: perbaiki validasi nominal
refactor(auth): rapikan proses login
style: rapikan tampilan dashboard
docs: tambah panduan instalasi
```

## Daftar Type

| Type     | Keterangan                       |
| -------- | -------------------------------- |
| feat     | Penambahan fitur baru            |
| fix      | Perbaikan bug                    |
| refactor | Perubahan kode tanpa ubah fungsi |
| style    | Perubahan tampilan atau format   |
| docs     | Perubahan dokumentasi            |
| perf     | Peningkatan performa             |
| test     | Penambahan atau perbaikan test   |
| chore    | Maintenance non-fungsional       |

## Rules Wajib

- Gunakan kalimat singkat dan jelas.
- Gunakan huruf kecil pada pesan commit.
- Gunakan bahasa yang konsisten, disarankan bahasa Indonesia.
- Jangan gunakan pesan yang terlalu umum seperti `update`, `fix bug`, atau `revisi`.
- Satu commit harus mewakili satu tujuan perubahan.
- Jangan gabungkan banyak perubahan yang tidak berhubungan dalam satu commit.
- Gunakan scope jika perubahan hanya menyentuh area tertentu.

## Commit Per Tahapan

Setiap tahapan pekerjaan harus ditutup dengan commit terpisah berdasarkan aturan di file ini.

File kerja AI agent boleh ikut commit jika berisi konteks yang berguna untuk project, seperti PRD, guideline, catatan keputusan teknis, rencana implementasi, atau dokumen handoff. Jangan commit file sementara yang hanya berisi log mentah, cache, prompt pribadi, secret, token, atau data sensitif.

Tahapan yang disarankan:

1. Analisis dan setup awal
   - Commit jika ada perubahan file konfigurasi, struktur folder, atau dokumentasi awal.
   - Contoh: `chore: siapkan struktur awal project`
   - Contoh untuk file kerja AI: `docs(ai): tambah prd pencatat keuangan`

2. Implementasi fitur
   - Commit setiap fitur utama selesai dan dapat diuji.
   - Contoh: `feat(transaksi): tambah form pemasukan`

3. Perbaikan bug
   - Commit setiap bug selesai diperbaiki.
   - Contoh: `fix(transaksi): validasi nominal kosong`

4. Refactor
   - Commit perubahan perapian kode yang tidak mengubah perilaku aplikasi.
   - Contoh: `refactor(repository): pisahkan query transaksi`

5. Tampilan
   - Commit perubahan UI atau styling secara terpisah dari logic.
   - Contoh: `style(dashboard): rapikan kartu ringkasan`

6. Testing
   - Commit penambahan atau perbaikan test setelah test relevan berjalan.
   - Contoh: `test(transaksi): tambah test simpan pemasukan`

7. Dokumentasi
   - Commit perubahan README, panduan instalasi, atau catatan teknis.
   - Contoh: `docs: tambah panduan menjalankan project`

## Alur Kerja Sebelum Commit

Sebelum membuat commit:

```text
git status
git diff
```

Pastikan hanya perubahan yang sesuai dengan tujuan commit yang masuk stage.

```text
git add <file-terkait>
git commit -m "type(scope): deskripsi singkat"
```

Jika ada beberapa tahapan yang selesai sekaligus, pisahkan commit berdasarkan tujuan perubahan.

Untuk file kerja AI agent, gunakan type `docs` jika isinya dokumentasi project atau `chore` jika isinya pengaturan proses kerja. Contoh:

```text
docs(ai): tambah panduan commit per tahapan
docs(ai): tambah prd pencatat keuangan
chore(ai): atur file kerja agent ikut commit
```

## Bekerja di Device Berbeda

Jika project dikerjakan dari device berbeda, pastikan perubahan dari device sebelumnya sudah di-commit dan di-push ke Git terlebih dahulu.

Sebelum pindah device:

```text
git status
git add <file-terkait>
git commit -m "type: deskripsi perubahan"
git push
```

Saat mulai kerja di device lain:

```text
git status
git pull origin nama-branch
```

Contoh jika menggunakan branch `main`:

```text
git pull origin main
```

Untuk project Laravel, setelah `pull` cek kebutuhan setup berikut jika ada perubahan dependency, database, atau file environment:

```text
composer install
npm install
php artisan migrate
```

Jika `.env` baru dibuat dan `APP_KEY` masih kosong:

```text
php artisan key:generate
```

Biasakan selalu menjalankan `git pull` sebelum mulai coding di device baru agar perubahan lokal tidak tertinggal dari remote.

## Tujuan

- Memudahkan tracking perubahan.
- Mempercepat debugging.
- Menjaga konsistensi tim.
- Mempermudah code review.
