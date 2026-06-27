# Kaspersky Silent Uninstaller

Script PowerShell untuk uninstall **Kaspersky Endpoint Security (KES)** dan **Kaspersky Security Center Network Agent** secara silent, cocok untuk deployment via GPO di environment domain.

---

## Deskripsi

Script ini menjalankan 2 proses uninstall secara berurutan:

1. **Process 1** - Uninstall Kaspersky Endpoint Security menggunakan `msiexec.exe` dengan GUID yang diambil otomatis dari registry.
2. **Process 2** - Uninstall Kaspersky Security Center Network Agent menggunakan `cleaner.exe` yang disalin dari network share.

---

## Prasyarat

- Dijalankan dengan **hak akses Administrator** (atau via GPO dengan SYSTEM privilege)
- Network share `\\isi_server\isi_share\` harus dapat diakses dari endpoint target
- `cleaner.exe` (Kaspersky Network Agent Cleaner) sudah tersedia di network share
- KES harus memiliki password uninstall jika fitur Self-Defense diaktifkan

---

## Konfigurasi

Sebelum deploy, isi variabel berikut di bagian atas script:

```powershell
$klUsername = ""   # Username KES (isi jika diperlukan)
$klPassword = ""   # Password uninstall KES (isi jika Self-Defense aktif)

$cleanerSource = "\\isi_server\isi_share\cleaner.exe"   # Path cleaner.exe di network share
$cleanerLocal  = "C:\Windows\Temp\cleaner.exe"          # Path temporary di endpoint
```

> **Catatan:** Jika KES tidak menggunakan password protection, `$klUsername` dan `$klPassword` bisa dibiarkan kosong.

---

## Cara Penggunaan

### Manual (single endpoint)

```powershell
# Jalankan PowerShell sebagai Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force
.\uninstall-kaspersky.ps1
```

### Via GPO (mass deployment)

1. Simpan script ke network share yang dapat diakses semua endpoint.
2. Buat **Computer Configuration > Preferences > Windows Settings > Files** untuk mendistribusikan script jika perlu.
3. Buat GPO baru: **Computer Configuration > Windows Settings > Scripts > Startup**
4. Tambahkan script dengan parameter:
   ```
   PowerShell.exe -ExecutionPolicy Bypass -File "\\path\to\uninstall-kaspersky.ps1"
   ```

---

## Alur Eksekusi

```
START
  │
  ├─ [Process 1] Cari GUID KES di registry
  │      ├─ Ditemukan → jalankan msiexec /x {GUID} /qn
  │      └─ Tidak ditemukan → skip, lanjut ke Process 2
  │
  ├─ [Process 2] Salin cleaner.exe dari network share ke C:\Windows\Temp\
  │      ├─ Gagal salin → exit script
  │      ├─ Cari GUID Network Agent di registry
  │      │      ├─ Ditemukan → jalankan cleaner.exe /uc {GUID}
  │      │      └─ Tidak ditemukan → skip
  │      └─ Hapus cleaner.exe dari temp
  │
  END
```

---

## Output / Indikator

| Prefix | Warna | Arti |
|--------|-------|------|
| `[*]` | Cyan | Informasi / proses sedang berjalan |
| `[+]` | Green | Sukses |
| `[-]` | Red | Gagal / error |
| `[v]` | Yellow | Proses selesai (done) |

---

## Exit Code msiexec

| Exit Code | Keterangan |
|-----------|------------|
| `0` | Uninstall berhasil |
| `1603` | Fatal error (cek password atau hak akses) |
| `1605` | GUID tidak valid / produk tidak terdaftar |
| `1618` | Proses instalasi lain sedang berjalan |

---

## Catatan Tambahan

- Script mengambil GUID **secara otomatis** dari registry, tidak perlu hardcode.
- Jika ditemukan lebih dari satu entri registry, script menggunakan entri pertama.
- `cleaner.exe` dihapus otomatis dari folder temp setelah proses selesai.
- Script ini **tidak melakukan restart otomatis** — restart mungkin diperlukan agar uninstall sepenuhnya efektif.

---

## Struktur File

```
📁 network share (\\isi_server\isi_share\)
   └── cleaner.exe              # Kaspersky Network Agent Cleaner

📄 uninstall-kaspersky.ps1     # Script utama (file ini)
```

---

## Dibuat Oleh

Internal use — PT Digital Solusi Grup (DSG)  
Security Engineer Internship
