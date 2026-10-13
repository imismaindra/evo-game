# Studi Kasus Evolusi Perangkat Lunak: Sistem Pathfinding & Arsitektur Status NPC 2D

Studi kasus teknis dan akademis yang mendemonstrasikan prinsip-prinsip **Evolusi Perangkat Lunak** (*Software Evolution*) pada prototipe game 2D menggunakan Godot Engine 4. Repositori ini mendokumentasikan transisi dari algoritma pergerakan linier monolitik yang memiliki kelemahan (*flaw*) pada **Versi 1.0** menuju arsitektur navigasi spasial berbasis graf poligon dan *Finite State Machine* (FSM) pada **Versi 2.0**.

---

## 1. Gambaran Umum

Evolusi perangkat lunak mempelajari siklus hidup refaktorisasi kode, peningkatan efisiensi algoritma, dan adaptasi struktural dalam merespons *technical debt* maupun kompleksitas kebutuhan sistem.

Pada simulasi interaktif dan video game, perilaku agen non-pemain (*Non-Player Character* / NPC) merupakan subsistem krusial. Proyek ini membandingkan dua iterasi evolusi:

* **Versi 1.0 (Baseline Prototype):** Model pengejaran garis lurus (*naive pursuit*) tanpa kesadaran spasial lingkungan, menyebabkan agen musuh tersangkut permanen saat berhadapan dengan rintangan bersekat/sudut siku (dinding huruf "L").
* **Versi 2.0 (Evolved Architecture):** Model perutean spasial modular menggunakan algoritma pencarian rute terpendek **A\*** di atas *Navigation Mesh* 2D (`NavigationRegion2D` / `NavigationAgent2D`), dikombinasikan dengan arsitektur **Finite State Machine (FSM)**.

---

## 2. Matriks Komparasi Evolusi: v1.0 vs v2.0

| Parameter / Dimensi | Versi 1.0 (Baseline) | Versi 2.0 (Evolusi) |
| :--- | :--- | :--- |
| **Algoritma Perutean** | Vektor Euclidean linier langsung | Algoritma pencarian A\* pada poligon konveks (*NavMesh*) |
| **Kesadaran Spasial** | Tidak ada ($O(1)$ kalkulasi vektor mentah) | Pemetaan topologi area melalui `NavigationRegion2D` |
| **Penanganan Rintangan** | Tersangkut permanen pada sudut rintangan ("L") | Menghitung *waypoint* dinamis memutari rintangan |
| **Arsitektur Kontrol AI** | Monolitik (*single procedural condition*) | Pola status terpisah (*State Pattern* / `match` & `enum`) |
| **Status Agen** | Implisit (hanya mengejar tanpa variasi) | Eksplisit (`CHASE` dan `SEARCH`) |
| **Maintainability Kode** | Rendah (*tightly coupled*, sulit diekspansi) | Tinggi (*loosely coupled*, mudah menambah status baru) |

---

## 3. Landasan Matematis & Algoritma

### Versi 1.0: Celah Logika Pengejaran Linier

Pada v1.0, vektor kecepatan $\vec{v}$ agen musuh dihitung murni dari selisih koordinat Euclidean posisi target dan posisi agen saat ini:

$$
\vec{d} = \vec{P}_{\text{target}} - \vec{P}_{\text{agent}}
$$

$$
\vec{v} = \frac{\vec{d}}{\Vert{}\vec{d}\Vert{}} \cdot s
$$

*(Di mana $s$ melambangkan kecepatan gerak konstan).* 

Ketika sebuah rintangan geometris $O$ memotong garis edar langsung antara $\vec{P}_{\text{agent}}$ dan $\vec{P}_{\text{target}}$, gaya normal tabrakan meniadakan komponen kecepatan maju sepanjang bidang kontak dinding, memicu kondisi macet permanen (*deadlock*: $\vec{v} \cdot \vec{n}_{\text{dinding}} \approx 0$).

### Versi 2.0: Optimasi Pathfinding A\* pada Navigation Mesh

Versi 2.0 mengatasi masalah oklusi rintangan dengan mencari urutan simpul simetris pada poligon navigasi 2D terdistribusi (*triangulated continuous mesh*) menggunakan evaluasi algoritma **A\***:

$$
f(n) = g(n) + h(n)
$$

* $g(n)$: Biaya riil akumulasi jarak tempuh dari simpul awal ke simpul $n$.
* $h(n)$: Biaya estimasi heuristik (jarak Euclidean) dari simpul $n$ menuju koordinat target.

Sistem *NavigationServer* kemudian melakukan teknik *string-pulling* (algoritma corong / *funnel algorithm*) di atas graf poligon sehingga menghasilkan daftar simpul belokan $\mathcal{W} = \{w_1, w_2, \dots, w_k\}$ yang memandu kemudi agen secara mulus tanpa menabrak dinding.

---

## 4. Evolusi Kode Sumber

### Skrip Versi 1.0 (`enemy_v1.gd`)

```gdscript
extends CharacterBody2D

# Kelemahan Struktural v1.0:
# 1. Tidak memiliki state machine (hanya loop if-else linier).
# 2. Tidak memiliki kesadaran terhadap geometri lingkungan (spatial awareness).

@export var player_node: Node2D
const SPEED = 130.0

func _physics_process(_delta):
	if player_node:
		var target_pos = player_node.global_position
		var direction = (target_pos - global_position).normalized()
		velocity = direction * SPEED
		move_and_slide()
```

### Skrip Versi 2.0 (`enemy_v2.gd`)

```gdscript
extends CharacterBody2D

# Peningkatan Evolusi v2.0:
# 1. State Machine modular via Enum dan Match pattern.
# 2. Sinkronisasi asinkronus dengan NavigationServer.
# 3. Penentuan titik belok (waypoint) dinamis menggunakan NavigationAgent2D.

enum State { CHASE, SEARCH }
var current_state = State.CHASE

@export var player_node: Node2D
const SPEED = 130.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

func _ready():
	# Menunggu frame fisika pertama selesai untuk sinkronisasi NavigationServer
	await get_tree().physics_frame

func _physics_process(_delta):
	if not player_node:
		return

	match current_state:
		State.CHASE:
			nav_agent.target_position = player_node.global_position
			
			if not nav_agent.is_target_reached():
				var next_path_pos = nav_agent.get_next_path_position()
				var direction = (next_path_pos - global_position).normalized()
				velocity = direction * SPEED
				move_and_slide()
			else:
				velocity = Vector2.ZERO
				current_state = State.SEARCH
				
		State.SEARCH:
			velocity = Vector2.ZERO
			if global_position.distance_to(player_node.global_position) > 40.0:
				current_state = State.CHASE
```

---

## 5. Struktur Direktori Proyek

```text
├── .gitignore
├── README.md
├── project.godot
├── scenes/
│   ├── Main.tscn           # Mengorkestrasi Player, Enemy, Dinding, & NavigationRegion2D
│   ├── Player.tscn         # Entitas karakter pemain (CharacterBody2D)
│   └── Enemy.tscn          # Entitas musuh cerdas dengan NavigationAgent2D
└── scripts/
    ├── player.gd           # Skrip kendali pergerakan karakter utama
    └── enemy.gd            # Skrip evolusi FSM dan navigasi waypoint musuh
```

---

## 6. Petunjuk Menjalankan Proyek

### Prasyarat

* [Godot Engine 4.x](https://godotengine.org/download) (Edisi Standar)
* Git

### Instalasi & Eksekusi

1. Kloning repositori ini:
   ```bash
   git clone https://github.com/<username-anda>/<nama-repo-anda>.git
   cd <nama-repo-anda>
   ```
2. Buka Godot Engine dan pilih tombol **Import**.
3. Arahkan ke file `project.godot` di dalam folder proyek.
4. Buka scene `Main.tscn`.
5. Tekan tombol **F5** untuk menjalankan simulasi.

### Kontrol Permainan

* **W, A, S, D** atau **Tombol Panah**: Menggerakkan entitas pemain (kotak biru).
* Arahkan pemain masuk ke balik cekungan dinding sudut "L" untuk mengamati agen musuh (kotak merah) menghitung rute memutar secara *real-time*.

---

## 7. Referensi Ilmiah

1. **Hart, P. E., Nilsson, N. J., & Raphael, B. (1968).** *A Formal Basis for the Heuristic Determination of Minimum Cost Paths.* IEEE Transactions on Systems Science and Cybernetics, 4(2), 100–107.
2. **Millington, I., & Funge, J. (2018).** *Artificial Intelligence for Games* (3rd ed.). CRC Press / Taylor & Francis Group. (Topik: *Pathfinding* dan *Finite State Machines*).
3. **Lehman, M. M. (1980).** *Programs, Life Cycles, and Laws of Software Evolution.* Proceedings of the IEEE, 68(9), 1060–1076.