# Labyrinth Escape: The Protocol (Evolusi Perangkat Lunak)

Studi kasus implementasi tugas mata kuliah **Evolusi Perangkat Lunak**. Proyek ini mendokumentasikan proses refaktorisasi sistem kendali karakter non-player (NPC musuh) pada game 2D dari logika linier (**v1.0**) ke sistem berbasis Navigation Mesh dan Finite State Machine (**v2.0**) menggunakan Godot Engine 4.

---

## 1. Konsep & Aturan Permainan

* **Entitas Pemain (Core-01):** Kotak biru yang digerakkan menggunakan tombol panah atau WASD.
* **Entitas Musuh (Hunter-X):** Kotak merah yang bertugas mengejar pemain secara otomatis.
* **Objektif Utama:** Pemain harus mengambil 5 fragmen kunci enkripsi (koin kuning) yang tersebar di peta, lalu masuk ke portal hijau untuk menyelesaikan permainan.
* **Kondisi Kalah:** Pemain bersentuhan fisik dengan karakter musuh.
* **Fokus Pengujian Spasial:** Dua koin diletakkan sengaja di dalam ceruk rintangan dinding siku "L" untuk menguji perilaku musuh saat garis pandang langsung terhalang rintangan statis.

---

## 2. Masalah pada Versi 1.0 (Baseline)

Pada rilis v1.0, musuh hanya menghitung selisih koordinat vektor langsung yang dinormalisasi terhadap posisi pemain:

$$\vec{d} = \frac{\vec{P}_{\text{pemain}} - \vec{P}_{\text{musuh}}}{\Vert{}\vec{P}_{\text{pemain}} - \vec{P}_{\text{musuh}}\Vert{}}$$

```gdscript
# scripts/enemy_v1.gd
extends CharacterBody2D

@export var player: Node2D
const SPEED: float = 130.0

func _physics_process(_delta: float) -> void:
	if player:
		var direction: Vector2 = (player.global_position - global_position).normalized()
		velocity = direction * SPEED
		move_and_slide()
```

### Dampak Masalah:
* Musuh tidak memiliki kesadaran spasial terhadap bentuk rintangan lingkungan.
* Saat pemain berada di balik dinding sudut siku "L", musuh tetap menekan lurus ke dinding. Akibatnya, agen mengalami *deadlock* (tersangkut permanen di tempat).

---

## 3. Solusi pada Versi 2.0 (Hasil Evolusi)

Sistem diperbaiki melalui dua aspek rekayasa perangkat lunak:

1. **Pemetaan Jalur (A\* Pathfinding):** Menggunakan node `NavigationRegion2D` untuk menghasilkan poligon area jalan kontinu (*NavMesh*) dan node `NavigationAgent2D` pada musuh untuk menghasilkan lintasan titik belok (*waypoints*).
2. **Arsitektur Kontrol (FSM):** Mengganti percabangan kondisional monolitik dengan Finite State Machine (`CHASE` dan `SEARCH`).

```gdscript
# scripts/enemy_v2.gd
extends CharacterBody2D

enum State { CHASE, SEARCH }

@export var player: Node2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

const SPEED: float = 130.0
var current_state: State = State.CHASE

func _physics_process(_delta: float) -> void:
	match current_state:
		State.CHASE:
			if player:
				nav_agent.target_position = player.global_position
				if not nav_agent.is_navigation_finished():
					var next_pos: Vector2 = nav_agent.get_next_path_position()
					velocity = (next_pos - global_position).normalized() * SPEED
					move_and_slide()
				else:
					current_state = State.SEARCH

		State.SEARCH:
			velocity = Vector2.ZERO
			if player and global_position.distance_to(player.global_position) > 40.0:
				current_state = State.CHASE
```

---

## 4. Tabel Matriks Komparasi

| Parameter | Versi 1.0 (Baseline) | Versi 2.0 (Hasil Evolusi) |
|---|---|---|
| **Metode Penentuan Jalur** | Vektor Linier Euclidean Langsung | Poligon NavMesh & Algoritma A* |
| **Respon Rintangan Siku "L"** | Tersangkut permanen (*deadlock*) | Menghitung rute memutar otomatis |
| **Pola Arsitektur Kode** | Kondisional tunggal prosedural | Finite State Machine (Modular) |
| **Tingkat Keterpeliharaan (*Maintainability*)** | Rendah (*spaghetti code*) | Tinggi (mudah diekspansi status baru) |

---

## 5. Struktur Berkas Repositori

```text
├── scenes/
│   ├── main.tscn       # Arena labirin, rintangan L, dan portal
│   ├── player.tscn     # Scene pemain (Core-01)
│   ├── enemy.tscn      # Scene musuh (Hunter-X)
│   ├── coin.tscn       # Item kunci enkripsi (Area2D)
│   └── portal.tscn     # Gerbang ekstraksi akhir (Area2D)
├── scripts/
│   ├── player.gd       # Kendali gerak & inventori kunci
│   ├── enemy.gd        # Skrip navigasi dan perilaku musuh
│   ├── coin.gd         # Deteksi interaksi pengambilan kunci
│   └── portal.gd       # Validasi syarat menang
├── project.godot       # Konfigurasi engine Godot 4
└── README.md
```

---

## 6. Panduan Menjalankan Proyek

### Prasyarat
* Godot Engine versi 4.x (Standard Edition).

### Langkah-langkah
1. Klon repositori ini:
   ```bash
   git clone https://github.com/imismaindra/evo-game.git
   cd evo-game
   ```
2. Buka Godot Engine 4, klik **Import**, lalu pilih berkas `project.godot`.
3. Tekan **F5** untuk menjalankan simulasi (`main.tscn`).

### Memeriksa Riwayat Versi di Git
* Meninjau kondisi awal v1.0:
  ```bash
  git checkout v1.0
  ```
* Kembali ke versi evolusi v2.0:
  ```bash
  git checkout main
  ```

---

## 7. Referensi Ilmiah

1. Hart, P. E., Nilsson, N. J., & Raphael, B. (1968). *A Formal Basis for the Heuristic Determination of Minimum Cost Paths.* IEEE Transactions on Systems Science and Cybernetics, 4(2), 100–107.
2. Kallmann, M., & Kapadia, M. (2016). *Navigation Meshes and Real-Time Dynamic Obstacle Avoidance for Virtual Populations.* Synthesis Lectures on Visual Computing, Springer.
3. Millington, I., & Funge, J. (2018). *Artificial Intelligence for Games* (3rd ed.). CRC Press.
4. Lehman, M. M. (1980). *Programs, Life Cycles, and Laws of Software Evolution.* Proceedings of the IEEE, 68(9), 1060–1076.
