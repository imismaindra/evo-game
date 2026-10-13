# PRODUCT REQUIREMENT DOCUMENT (PRD)
## Proyek: Labyrinth Escape - The Protocol (Evolusi Perangkat Lunak)

---

### 1. Informasi Dokumen
* **Nama Proyek:** Labyrinth Escape: The Protocol
* **Mata Kuliah:** Evolusi Perangkat Lunak
* **Fokus Studi Kasus:** Transisi Sistem Kendali Navigasi & Arsitektur NPC 2D (v1.0 ke v2.0)
* **Target Engine:** Godot Engine 4.x
* **Status Dokumen:** Approved / Baseline Release

---

### 2. Latar Belakang & Masalah
Dalam pengembangan game 2D top-down, agen musuh non-player (NPC) sering kali dimulai dengan logika penjelajahan langsung (vektor linier Euclidean). Pada rilis awal (**v1.0**), algoritma ini bekerja jika area terbuka tanpa halangan. Namun, begitu arena memiliki rintangan cekung atau sudut siku berbentuk "L", musuh mengalami *spatial blindness* (kebutaan spasial) dan menabrak dinding tanpa kemampuan berbelok, menyebabkan status macet permanen (*deadlock*).

Berdasarkan prinsip *Software Evolution* (Hukum Lehman mengenai *Continuing Change* dan *Increasing Complexity*), sistem harus direfaktorisasi secara arsitektural menjadi **v2.0** dengan mengintegrasikan representasi Navigation Mesh (NavMesh) poligon dan Finite State Machine (FSM).

---

### 3. Visi & Tujuan Produk
1. **Playable Baseline (v1.0):** Membangun game mini berbasis labirin yang utuh dan berfungsi penuh (dapat dimainkan, memiliki tujuan menang/kalah), tetapi mengandung cacat desain navigasi AI yang terbukti secara empiris.
2. **Empirical Flaw Demonstration:** Menempatkan objektif game di dalam ceruk rintangan dinding siku "L" untuk membuktikan kegagalan gerak musuh v1.0 saat gameplay berlangsung.
3. **Evolved System (v2.0):** Mengimplementasikan `NavigationAgent2D` (algoritma A*) dan pola arsitektur FSM (Status: `CHASE` & `SEARCH`) untuk menjamin musuh mampu bermanuver memutari sudut tanpa tersangkut.

---

### 4. Narasi Game (Thematic Narrative)
* **Latar:** Sektor memori rusak pada server legacy *A.E.G.I.S.*
* **Karakter Pemain (Core-01):** Paket data otonom berwarna biru neon.
* **Karakter Musuh (Hunter-X):** Subsistem antivirus berkode warna merah.
* **Objektif:** Core-01 harus mengumpulkan 5 fragmen kunci enkripsi digital (*Encryption Keys*) sebelum sistem melakukan format paksa, lalu menuju ke portal ekstraksi hijau.

---

### 5. Kebutuhan Fungsional (Functional Requirements)

#### 5.1 Karakter Pemain (Core-01)
* **FR-PL-01:** Pemain dapat bergerak ke 8 arah menggunakan tombol WASD atau tombol panah keyboard.
* **FR-PL-02:** Kecepatan konstan pemain diatur pada 200 px/detik.
* **FR-PL-03:** Pemain memiliki counter internal untuk menghitung jumlah kunci yang telah dikumpulkan (0 sampai 5).
* **FR-PL-04:** Jika pemain bersentuhan secara fisik dengan musuh, sesi permainan langsung berakhir dengan status kalah (*Game Over*).

#### 5.2 Karakter Musuh (Hunter-X)
* **FR-EN-01 (v1.0):** Bergerak mengejar pemain menggunakan vektor selisih koordinat Euclidean langsung: `(Player_Pos - Enemy_Pos).normalized() * SPEED` dengan kecepatan 130 px/detik.
* **FR-EN-02 (v2.0):** Terkoneksi dengan `NavigationAgent2D` dan memperbarui `target_position` ke posisi pemain.
* **FR-EN-03 (v2.0):** Mengambil posisi titik belok berikutnya (`get_next_path_position()`) untuk menghindari rintangan dinding.
* **FR-EN-04 (v2.0):** Menggunakan status Finite State Machine (`CHASE` dan `SEARCH`) agar logika transisi terisolasi dan tidak monolitik.

#### 5.3 Sistem Kunci Enkripsi (Collectibles)
* **FR-KC-01:** Sebanyak 5 koin diletakkan di dalam arena permainan.
* **FR-KC-02:** Minimal 2 koin diletakkan di dalam ceruk dinding berbentuk siku "L".
* **FR-KC-03:** Koin mendeteksi sentuhan pemain melalui `Area2D`, menambah nilai kunci pada pemain, memancarkan sinyal pembaruan HUD, dan menghapus dirinya sendiri (`queue_free()`).

#### 5.4 Portal Ekstraksi (Escape Portal)
* **FR-PO-01:** Berada di salah satu ujung arena level.
* **FR-PO-02:** Menolak interaksi kemenangan jika jumlah kunci pemain belum mencapai 5.
* **FR-PO-03:** Memancarkan sinyal kemenangan (*Victory*) jika pemain menyentuh portal saat seluruh 5 kunci telah terkumpul.

#### 5.5 Antarmuka & HUD
* **FR-UI-01:** Menampilkan label penghitung kunci secara real-time (`Keys: X / 5`).
* **FR-UI-02:** Menampilkan pesan akhir ketika menang atau kalah.
* **FR-UI-03:** Menyediakan tombol pintas `R` untuk memuat ulang (*restart*) sesi permainan.

---

### 6. Kebutuhan Non-Fungsional (Non-Functional Requirements)
* **NFR-01 (Performance):** Game harus berjalan stabil pada 60 FPS pada spesifikasi desktop standar tanpa latensi kalkulasi pathfinding.
* **NFR-02 (Maintainability):** Struktur kode skrip musuh pada v2.0 harus terpisah per-status (*State Pattern*) agar penambahan status baru (misal: `PATROL`, `FLEE`) tidak merusak logika yang sudah ada.
* **NFR-03 (Reproducibility):** Masalah kegagalan gerak v1.0 harus dapat diulang 100% konsisten ketika pemain berdiri di balik ceruk dinding siku "L".

---

### 7. Struktur Arsitektur & Hierarki Node (Godot 4)

```text
res://
├── scenes/
│   ├── main.tscn             (Node2D: Level Root)
│   │   ├── NavigationRegion2D (Khusus v2.0 - NavMesh Polygon)
│   │   ├── Walls             (StaticBody2D + CollisionShape2D)
│   │   ├── Player            (Instance: player.tscn)
│   │   ├── Enemy             (Instance: enemy.tscn)
│   │   ├── Coins             (Node2D penampung 5x coin.tscn)
│   │   ├── Portal            (Instance: portal.tscn)
│   │   └── HUD               (CanvasLayer: Skor & Status Teks)
│   ├── player.tscn           (CharacterBody2D + CollisionShape2D + ColorRect)
│   ├── enemy.tscn            (CharacterBody2D + CollisionShape2D + ColorRect + NavigationAgent2D [v2.0])
│   ├── coin.tscn             (Area2D + CollisionShape2D + ColorRect)
│   └── portal.tscn           (Area2D + CollisionShape2D + ColorRect)
└── scripts/
    ├── player.gd
    ├── enemy.gd
    ├── coin.gd
    ├── portal.gd
    └── hud.gd
```

---

### 8. Matriks Evaluasi Evolusi Sistem

| Komponen Pengujian | Versi 1.0 (Baseline) | Versi 2.0 (Hasil Evolusi) |
|---|---|---|
| **Metode Penentuan Arah** | Normalisasi Vektor Euclidean Langsung | Algoritma A* berbasis NavMesh Poligon |
| **Pola Perilaku Kode** | Monolitik percabangan `_physics_process` | Finite State Machine (`enum` & `match`) |
| **Respon Dinding Sudut L** | Terjebak permanen (*deadlock*) | Menghitung titik belok dan memutari sudut |
| **Tingkat Keberhasilan Skenario** | 0% (Musuh gagal mencapai target di balik siku) | 100% (Musuh berhasil menjangkau pemain di balik siku) |

---

### 9. Rencana Rilis & Version Control (Git)
* **Tag v1.0:** Rilis game utuh dengan 5 koin, portal, HUD, dan musuh berbasis vektor linier (memperlihatkan bug navigasi).
* **Branch v2.0:** Penambahan `NavigationRegion2D`, integrasi `NavigationAgent2D` pada musuh, dan refaktorisasi FSM.
* **Tag v2.0 / Merge to Main:** Rilis final hasil evolusi perangkat lunak yang telah tervalidasi.
