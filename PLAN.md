# Laskar Nusantara — Rencana Game Web (Godot 4)

> Roguelite arena shooter ala Brotato, bertema Nusantara.
> Pemain jadi pejuang rakyat yang melawan **Kekaisaran Besi**, rezim fiksi yang menindas negeri.

**Target:** versi demo yang bisa dimainkan di itch.io dalam **12 minggu**
**Asumsi:** dikerjakan sendiri, paruh waktu (10–15 jam/minggu), aset 2D sederhana

| Ringkasan | Nilai |
|---|---|
| Waktu ke demo | 12 minggu (6 milestone) |
| Wave per run | 20 (boss di wave 20) |
| Isi demo | 5 karakter, 12 senjata, ~30 item, 1 map |
| Durasi satu run | ~25 menit |

---

## I. Konsep & Pilar

### Cerita singkat
Kekaisaran Besi menjajah Nusantara dan memeras rakyatnya. Para pejuang dari berbagai daerah bangkit dan bertahan dari gelombang pasukan rezim, sampai akhirnya menghadapi **Gubernur Jenderal Besi**.
- Rezimnya sengaja fiksi supaya ceritanya bebas dan aman dirilis publik.
- Cerita cukup disampaikan lewat teks pembuka, deskripsi karakter, dan dialog boss. Tidak perlu cutscene.

### Tiga pilar desain
1. **Cepat & kacau:** wave pendek, banyak musuh, senjata menembak otomatis.
2. **Build yang lucu:** kombinasi senjata dan item bisa bikin run yang absurd.
3. **Terasa Nusantara:** semua senjata, item, musuh, map, dan musik berakar dari budaya lokal.

### Alur satu run
`Pilih karakter → Pilih senjata awal → Wave (20–60 detik) → Level up → Toko → ulangi sampai wave 20`
- **Rempah** yang didrop musuh jadi uang di toko.
- Kalau mati, run langsung berakhir. Hasil run membuka karakter baru.

---

## II. Isi Versi Demo

### Karakter (5)
| Karakter | Kelebihan | Kekurangan |
|---|---|---|
| Pendekar Silat | +50% damage melee | −30% damage jarak jauh |
| Dukun | Regen HP, senjata magis lebih kuat | Armor −3 |
| Pelaut Bugis | +20% speed, +15% dodge | Max HP −20% |
| Petani | +30% rempah dari musuh | Damage −20% |
| Penari Jaipong | +40% kecepatan serangan | Max HP −40% |

### Senjata (12)
- **Melee:** keris, golok, tombak, bambu runcing, kujang
- **Jarak jauh:** sumpit, ketapel, panah, meriam lela
- **Magis/unik:** cakra (memantul), mantra api, gasing (berputar di sekitar pemain)
- Ada 4 tier: abu → biru → ungu → merah. Dua senjata yang sama bisa digabung jadi satu tier di atasnya.

### Item toko (~30)
Item mengubah stat, sebagian punya efek khusus. Contoh:
- Jamu: regen HP
- Rendang: max HP
- Batik: armor
- Kopi tubruk: speed
- Kemenyan: luck
- Wayang: summon sekutu
- Sambal: damage naik, HP turun

### Musuh & Boss
- **Biasa:** serdadu besi (mengejar), anjing pelacak (cepat), penembak (menembak dari jauh), tukang pasang ranjau
- **Elite (wave 10 & 15):** Mandor Kejam, yang memanggil serdadu dan menyerang area
- **Boss (wave 20):** Gubernur Jenderal Besi, dengan 2 fase serangan

### Map
- Demo: **Sawah**
- Sudah: Lembah Sungai, Hutan Kalimantan, Pelabuhan Sunda Kelapa, Desa & Candi, Benteng Besi

---

## III. Roadmap 12 Minggu

### M1 · Minggu 1–2: Prototipe inti
- [x] Gerakan pemain (CharacterBody2D)
- [x] 1 senjata yang menembak otomatis ke musuh terdekat
- [x] 1 jenis musuh yang mengejar pemain
- [x] Wave manager (timer + spawn)
- [x] HP, damage, game over
- **Selesai kalau:** wave 1–5 sudah seru dimainkan meski grafisnya masih kotak-kotak.

### M2 · Minggu 3–4: Ekonomi
- [x] Musuh mendrop rempah yang otomatis tertarik ke pemain
- [x] Sistem XP dan level up, dengan pilihan upgrade stat
- [x] Toko antar-wave: beli, reroll, kunci item
- [x] Inventori dengan maksimal 6 slot senjata

### Tambahan (di luar rencana awal)
- [x] Co-op online 2–4 pemain dengan kode room / link undangan (WebRTC + signaling MQTT publik)
- [x] Prajurit 4 kerajaan (Majapahit, Sriwijaya, Mataram, Pajajaran) vs Serdadu Besi, sprite pixel art
- [x] UI bertema batik (font Pixelify Sans), kontrol sentuh
- [x] Ganti baju: 8 seragam kerajaan, tersinkron di co-op
- [x] Ketupat penambah HP yang dijatuhkan musuh
- [x] 3 medan berganti per wave: Lembah Sungai, Hutan Kalimantan, Desa & Candi (pohon/bangunan sebagai penghalang)

### M3 · Minggu 5–6: Sistem data (Resource)
- [x] `CharacterData`, `WeaponData`, `ItemData` sebagai file `.tres` (jenis musuh masih di `enemies.gd`)
- [ ] Nambah konten cukup bikin file baru, tanpa ngoding
- [x] 5 karakter, 13 senjata (+efek kena), 30 item (7 item unik, kelangkaan, 6 sinergi)
- [x] Pilih karakter di menu & lobby (5 karakter, terbuka sesuai wave tertinggi)

### M4 · Minggu 7–8: Musuh & Boss
- [x] 4 jenis musuh biasa (+ Serdadu Perisai)
- [x] Elite Mandor Kejam
- [x] Boss Gubernur Jenderal Besi (2 fase) + Komandan Besi sebagai boss di wave lain
- [ ] Tabel kurva kesulitan wave 1–20 (jumlah, jenis, dan HP musuh per wave)

### M5 · Minggu 9–10: Grafis, suara, "juice"
- [ ] Sprite final
- [x] Efek kena hit: flash, getar layar, angka damage, percikan, kilatan & jejak tembakan
- [x] Musik gamelan/kendang dan SFX (disintesis, `tools/make_sounds.py`)
- [x] Menu utama (latar senja bergerak), pause, settings volume musik & efek terpisah

### M6 · Minggu 11–12: Balancing & rilis
- [ ] Playtest dengan 5–10 teman: catat di wave berapa mereka mati dan build apa yang terlalu kuat
- [ ] Balancing
- [x] Simpan progres (karakter yang terbuka) di `user://`
- [ ] Export Web, lalu upload ke itch.io (+ GitHub Pages otomatis via Actions)

---

## IV. Teknis Godot untuk Web

### Struktur folder
```
res://
├── scenes/    # main, player, enemy, projectile, shop, ui
├── scripts/   # player, weapon, enemy, wave_manager, shop, game_state (autoload)
├── data/      # .tres: characters/, weapons/, items/, enemies/, waves/
└── assets/    # sprites/, audio/, fonts/
```

### Setting wajib
- Renderer: **Compatibility**, karena paling stabil di browser
- Export Web: **matikan Thread Support** supaya jalan di itch.io / GitHub Pages tanpa setting header tambahan
- Resolusi dasar **640×360**, stretch mode `canvas_items`, supaya pixel art tetap tajam

### Performa
- Batasi maksimal ~150–200 musuh di layar
- Pakai **object pooling** untuk peluru dan rempah, jangan terus-terusan `instantiate`/`queue_free`
- Cari musuh terdekat sekali per interval tembak, jangan tiap frame

---

## V. Risiko & Cara Menjaga Scope

| Risiko | Cara mengatasi |
|---|---|
| **Scope membengkak** (risiko utama) | Kunci isi demo di angka yang sudah ditentukan. Ide baru masuk ke `IDEAS.md`. |
| Aset grafis | Pakai placeholder sampai M5. Cari aset gratis (itch.io, Kenney) dan cek lisensinya. |
| Terlalu mirip Brotato | Jangan salin nama, aset, atau angka stat. Tambah mekanik khas sendiri. |

### Mekanik khas: Semangat Rakyat ✅
Meter yang terisi saat pemain menyelamatkan warga di map (dan sedikit dari tiap kill). Kalau penuh,
dipakai untuk serangan spesial **Pekik Merdeka**.

---

## Ide untuk nanti (setelah demo)
- Map tambahan: hutan Kalimantan, pelataran candi, pelabuhan
- Karakter tambahan
- Tingkat kesulitan (Danger level)
- Co-op lokal (co-op online sudah ada)
