# Laskar Nusantara

Roguelite arena shooter co-op bertema Nusantara (Godot 4.7, renderer Compatibility).
Prajurit dari 8 kerajaan Nusantara bersatu melawan Kekaisaran Besi.
Rencana lengkap: [PLAN.md](PLAN.md).

**Main:** https://lshinkuro.github.io/laskar-nusantara/

## Cara main
- **Gerak:** WASD / panah, atau sentuh & geser layar (HP). Senjata menembak otomatis.
- **Karakter:** Pendekar Silat, Petani (terbuka dari awal), Dukun (capai wave 4), Pelaut Bugis (wave 8),
  Penari Jaipong (wave 12). Tiap karakter punya kelebihan, kekurangan, dan senjata awal sendiri;
  progres tersimpan di `user://`.
- **Ganti baju:** pilih seragam kerajaan (Majapahit, Sriwijaya, Mataram, Pajajaran, Samudra Pasai,
  Gowa, Kutai, Ternate) dengan tombol `<` `>` di menu/lobby.
- **Semangat Rakyat:** selamatkan warga yang terkurung (berdiri di dekat kurungan ±1,5 dtk; panah "!" di
  tepi layar menunjuk arahnya) dan kalahkan musuh untuk mengisi meter Semangat. Saat penuh, tekan **Spasi**
  atau tombol *PEKIK MERDEKA!*: gelombang merah putih melukai & mendorong semua musuh di sekitar,
  memulihkan 30% HP, dan kebal sebentar.
- **Rempah** dari musuh yang gugur = uang belanja di **Pasar Rakyat** antar-wave sekaligus XP.
- **Naik level:** HP Maks +1, lalu di akhir wave pilih 1 dari 4 *ilmu* (upgrade stat) per level.
- **Ketupat** kadang jatuh dari musuh: +3 HP (tidak diambil kalau HP masih penuh).
- **Medan berganti:** wave 1–6 Lembah Sungai (terasering & sungai), 7–13 Hutan Kalimantan, 14–20 Desa & Candi. Pohon, bangunan,
  dan batu menghalangi gerak dan peluru.
- **Suara:** musik gamelan & efek suara, volume musik dan efek diatur terpisah (menu *Pengaturan* / layar jeda).
- **Musuh:** Serdadu Besi, Anjing Pelacak (w3+), Penembak (w5+), Serdadu Perisai (w7+), Tukang Ranjau (w9+).
- **Boss tiap wave** (muncul di pertengahan): Komandan Besi (terjang + cincin peluru), Mandor Kejam
  (wave 10 & 15: panggil pasukan + hantaman area), Gubernur Jenderal Besi (wave 20, 2 fase; harus dikalahkan untuk menang).
- **13 senjata** (jarak dekat/jauh/magis), masing-masing dengan efek saat kena: terbakar (Mantra Api), racun (Sumpit),
  berdarah (Keris, Kunai, Bambu Runcing), lambat (Ketapel), dorong (Tombak, Golok), ledakan (Meriam Lela),
  memantul (Shuriken, Kujang, Cakra). Senjata jarak dekat memunculkan efek tebasan.
- **30 item** dengan kelangkaan Biasa/Langka/Epik/Legendaris (peluang naik dengan wave & Hoki), termasuk
  item unik: Wayang Kulit (sekutu menembak), Kalung Taring (pulih saat kena), Obor Bambu (membakar),
  Gelang Akar Bahar (balas damage), Kentongan (gelombang dorong), Jimat Rajah (selamat dari maut), Lumbung Padi.
- **Sinergi:** Jurus Silat / Barisan Pemanah / Ilmu Kebatinan (3 senjata sejenis), Kuliner Nusantara &
  Busana Adat (3 item berlabel), Pusaka Leluhur (2 item pusaka).
- **Rangkuman run:** kill, damage per senjata, pukulan terkuat, rempah, waktu, sinergi.
- **Senjata bertingkat:** beli senjata yang sama untuk menggabung (abu → biru → ungu → merah), tiap tier +1 peluru
  & damage x1.5. *Busur Arjuna* (item) dan *Hujan Panah* (ilmu) menambah peluru semua senjata.
- **Jeda:** tombol *Jeda*, Esc, atau P. Di co-op, jeda berlaku untuk semua pemain.
- **Co-op online (2–4 pemain):** "Buat Room Online" → bagikan kode 5 huruf atau tombol *Salin Link*.
  Teman memasukkan kode lalu "Gabung" (atau buka link-nya). Host menekan "Mulai Perang!".

## Cara kerja online
- Signaling (tukar SDP/ICE) lewat broker MQTT publik `broker.emqx.io`, sesudah itu data game
  langsung antar-browser via WebRTC. Tidak perlu server sendiri.
- Host = peer 1: menjalankan wave, musuh, dan rempah. Tiap pemain menggerakkan prajurit, senjata,
  dan tokonya sendiri.
- Tanpa TURN server, sebagian jaringan (NAT ketat / beberapa operator seluler) bisa gagal tersambung.

## Struktur
```
scenes/   menu, main (game), player, enemy, projectile, rempah
scripts/  net (autoload lobby+signaling), sfx (autoload suara), map + obstacle (medan), main, player, weapon, enemies, pickups,
          projectiles, wave_manager, shop, menu, touch_joystick
data/     characters/*.tres, items/*.tres, weapons/*.tres   (nambah konten = bikin file baru)
assets/   sprites/ (tools/make_sprites.py), audio/ (tools/make_sounds.py, sintesis gamelan),
          fonts/ (Pixelify Sans, OFL), ui/theme.tres
tests/    smoke_test (solo), level_test (XP, ilmu, ketupat, jeda), character_test (karakter & unlock), weapon_test (efek senjata), item_test (item unik & sinergi), semangat_test (warga & Pekik Merdeka), boss_test (boss, musuh baru, ranjau, gabung senjata), touch_test, net_test (co-op 2 proses lewat ENet)
```

## Tes
```sh
godot --headless --fixed-fps 60 -s res://tests/smoke_test.gd
godot --headless -s res://tests/level_test.gd
godot --headless -s res://tests/character_test.gd
godot --headless --fixed-fps 60 -s res://tests/weapon_test.gd
godot --headless --fixed-fps 60 -s res://tests/item_test.gd
godot --headless --fixed-fps 60 -s res://tests/semangat_test.gd
godot --headless --fixed-fps 60 -s res://tests/boss_test.gd
godot --headless -s res://tests/net_test.gd -- host &  godot --headless -s res://tests/net_test.gd -- client
```

## Rilis web
Setiap push ke `main` otomatis di-export ke Web dan di-deploy ke GitHub Pages
(`.github/workflows/deploy.yml`). Thread Support dimatikan, jadi tidak perlu header COOP/COEP.
