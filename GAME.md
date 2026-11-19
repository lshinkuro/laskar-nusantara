# Laskar Nusantara — Dokumen Game

Roguelite arena shooter (co-op 1–4 pemain) bertema Nusantara. Prajurit dari 8 kerajaan bersatu
mengusir **Kekaisaran Besi**. Bertahan 20 wave, belanja di Pasar Rakyat di antara wave,
dan kalahkan **Gubernur Jenderal Besi** di wave 20.

- Mesin: Godot 4.7 (renderer Compatibility), resolusi dasar 640×360, gambar flat berdetail (SVG dari `tools/make_art.py`), font Nunito.
- Platform: Web (GitHub Pages), desktop, HP (kontrol sentuh).
- Main: https://lshinkuro.github.io/laskar-nusantara/

## Alur satu run

1. **Menu** — pilih baju kerajaan & nama, pilih **karakter** (kartu bergambar), pilih **tingkat kesulitan**.
2. **Wave** (20–60 detik) — gerak menghindar, senjata menembak otomatis, kumpulkan rempah,
   selamatkan warga. Boss muncul di pertengahan tiap wave.
3. **Pasar Rakyat** — belanja senjata/item dengan rempah, pilih *ilmu* untuk tiap level baru,
   gabung/lepas barang di Tas Pusaka, lalu **Siap Berperang**.
4. Ulangi sampai wave 20 (menang) atau semua pemain gugur (kalah). Layar akhir menampilkan rangkuman run.

## Durasi

Sama dengan Brotato: wave 1 = 20 detik, +5 detik tiap wave, maksimal 60 detik (wave 9–19).
Wave 20 selesai saat Gubernur Jenderal Besi tumbang. Satu run ±15–20 menit plus waktu belanja.

## Kontrol

| Aksi | Keyboard | HP |
|---|---|---|
| Gerak | WASD / panah | sentuh & geser |
| Menembak | otomatis | otomatis |
| Pekik Merdeka | Spasi | tombol *PEKIK MERDEKA!* |
| Jeda | Esc / P | tombol *Jeda* |
| Siap (di Pasar) | Enter | tombol *Siap Berperang* |

## Karakter (10)

Tiap karakter punya potret sendiri, senjata awal, kelebihan, dan kekurangan. Karakter terbuka
setelah pernah mencapai wave tertentu (progres disimpan di `user://settings.cfg`).

| Karakter | Senjata awal | Kelebihan | Kekurangan | Terbuka |
|---|---|---|---|---|
| Pendekar Silat | Keris | +50% damage jarak dekat | -30% damage jarak jauh | awal |
| Petani | Ketapel | +30% rempah | -20% damage | awal |
| Pemburu Dayak | Sumpit | +30% damage jarak jauh, +20% jangkauan | -20% damage jarak dekat, Armor -1 | wave 2 |
| Dukun | Mantra Api | Regen HP, +30% damage magis | Armor -3 | wave 4 |
| Pecalang Bali | Tombak | Armor +3, HP Maks +20% | -15% kecepatan | wave 6 |
| Pelaut Bugis | Panah | +20% kecepatan, +15% menghindar | HP Maks -20% | wave 8 |
| Saudagar Minang | Kujang | +50% rempah, Hoki +20 | -15% damage | wave 10 |
| Penari Jaipong | Cakra | +40% kecepatan serang | HP Maks -40% | wave 12 |
| Jawara Betawi | Golok | HP Maks +50%, +20% damage jarak dekat | -20% kecepatan serang | wave 14 |
| Senopati Majapahit | Meriam Lela | +1 peluru semua senjata, +20% damage | Armor -2, -10% kecepatan | wave 17 |

Nambah karakter: buat `data/characters/<nama>.tres` dan potretnya di `tools/make_art.py` (`KARAKTER`), lalu jalankan `python3 tools/make_art.py`.

## Tingkat kesulitan

Dipilih di menu (untuk co-op, yang berlaku pilihan host).

| Kesulitan | HP musuh | Damage musuh | Jumlah musuh | Bekal perang |
|---|---|---|---|---|
| Mudah | ×0.7 | ×0.7 | ×0.8 | – |
| Normal | ×1.0 | ×1.0 | ×1.0 | – |
| Sulit | ×1.6 | ×1.4 | ×1.3 | +15 rempah |
| Neraka | ×2.5 | ×2.0 | ×1.6 | +25 rempah |

*Bekal perang* diberikan di akhir wave 1–5 supaya bisa belanja cukup sebelum musuh membesar.

**Neraka terkunci** sampai kamu menang sekali di Sulit. Setiap kemenangan memberi karakter itu
*medali* (belah ketupat di kartu karakter) berwarna tingkat kesulitan tertinggi yang dimenangkan.

Selain itu musuh **tumbuh berlipat tiap wave**: HP ×1.08 dan damage ×1.04 per wave (di atas
kenaikan linear), karena item dan senjata pemain juga berlipat. Di wave 20, HP musuh ±4.7× dan
damage ±2.2× dibanding kurva lama, supaya build yang sudah kuat tetap ditantang.
Angkanya ada di `Net.DIFFICULTIES` (`scripts/net.gd`) dan `HP_GROWTH`/`DMG_GROWTH` (`scripts/wave_manager.gd`).

## Ekonomi & progres

- **Rempah** dari musuh = uang belanja sekaligus XP. Tampilannya acak: pala, cengkeh, lada, kayu manis,
  bunga lawang, atau kepeng (koin), melayang naik-turun. Harga di Pasar naik 12% tiap wave.
- **Naik level**: HP Maks +1, lalu pilih 1 dari 4 *ilmu* (upgrade stat) per level di akhir wave.
- **Kritis**: tiap pukulan 8% (+ luck/4 %) jadi kritis, damage ×2, angka merah besar.
- **Aura**: kekuatan perlengkapan (jumlah level item + 2 × tier senjata di atas 1) ≥ 12 → aura emas,
  ≥ 24 → emas berkobar, ≥ 40 → aura biru berkilat. Teman co-op juga melihatnya.
- **Ketupat**: kadang jatuh dari musuh, +3 HP.
- **Semangat Rakyat**: selamatkan warga terkurung & kalahkan musuh untuk mengisi meter. Penuh →
  *Pekik Merdeka*: gelombang merah putih melukai & mendorong musuh, pulih 30% HP, kebal sebentar.

## Senjata (13) — maks 6 slot

| Senjata | Jenis | Damage | Efek |
|---|---|---|---|
| Keris | dekat | 12 | berdarah, menembus 2 |
| Tombak | dekat | 11 | dorong |
| Golok | dekat | 9 | tebasan 3 arah, dorong |
| Kujang | dekat | 9 | memantul |
| Bambu Runcing | dekat | 8 | berdarah, menembus |
| Meriam Lela | jauh | 22 | ledakan, menembus 3 |
| Panah | jauh | 9 | menembus 1 |
| Ketapel | jauh | 7 | lambat |
| Kunai | jauh | 6 | berdarah, menembus |
| Shuriken | jauh | 5 | memantul |
| Sumpit | jauh | 4 | racun |
| Cakra | magis | 6 | memantul, 3 sekaligus |
| Mantra Api | magis | 3 | terbakar |

Tier abu → biru → ungu → merah: tiap tier +1 peluru dan damage ×1.5. Dua senjata sama & setier
digabung di Tas Pusaka (kalau slot penuh, otomatis digabung).

## Item (31) — **tanpa batas jumlah**

Kelangkaan Biasa / Langka / Epik / Legendaris (peluang naik dengan wave & Hoki). Tas Pusaka
bisa menampung item sebanyak apa pun. Dua item sama & selevel bisa digabung: Lv2 = 2.5× efek,
Lv3 = 6× efek. Item yang dilepas dijual ±40%.

Item unik: **Meriam Jaga** (turret: tiap awal wave satu meriam per item dipasang di dekatmu dan
menembak sendiri dengan ledakan kecil), Wayang Kulit (sekutu menembak), Kalung Taring (pulih saat kena), Obor Bambu (membakar),
Gelang Akar Bahar (balas damage), Kentongan (gelombang dorong), Jimat Rajah (selamat dari maut
sekali tiap wave), Lumbung Padi (rempah memulihkan HP), Busur Arjuna (+1 peluru semua senjata).

## Sinergi

| Sinergi | Syarat | Bonus |
|---|---|---|
| Jurus Silat | 3 senjata jarak dekat | +20% damage dekat, Armor +2 |
| Barisan Pemanah | 3 senjata jarak jauh | +10% kecepatan serang, +15% jangkauan |
| Ilmu Kebatinan | 3 senjata magis | +25% damage magis, regen +2 |
| Kuliner Nusantara | 3 item kuliner | HP Maks +6, regen +2 |
| Busana Adat | 3 item busana | Armor +2, menghindar +8% |
| Pusaka Leluhur | 2 item pusaka | +10% damage, Hoki +15 |

## Musuh

| Musuh | Mulai wave | Ciri |
|---|---|---|
| Serdadu Besi | 1 | dasar |
| Anjing Pelacak | 3 | cepat, rapuh |
| Penembak | 5 | berhenti & membidik (garis merah) lalu menembak |
| Kavaleri Besi | 6 | menyeruduk |
| Serdadu Perisai | 7 | tebal, lambat |
| Pelempar Granat | 8 | granat area |
| Tukang Ranjau | 9 | memasang ranjau |
| Tabib Besi | 11 | menyembuhkan teman |
| Raksasa Baja | 13 | sangat tebal, pecah jadi 2 |

Tiap musuh biasa punya **gaya jalan acak**: lurus, zig-zag, mengapit dari samping, atau ragu-ragu
(sesekali menyimpang), dengan kecepatan ±15%, supaya gerombolan tidak bergerak monoton.

**Boss** (tiap wave, di pertengahan): Komandan Besi (terjang + cincin peluru), Laksamana Besi
(wave 9, 12, 17), Mandor Kejam (wave 10 & 15), Gubernur Jenderal Besi (wave 20, 2 fase).
Boss menjatuhkan **Peti Pusaka** berisi item/senjata acak yang condong langka.

## Medan

| Wave | Medan |
|---|---|
| 1–4 | Lembah Sungai |
| 5–8 | Hutan Kalimantan |
| 9–12 | Pelabuhan Sunda Kelapa (laut tak bisa diseberangi) |
| 13–16 | Desa & Candi |
| 17–20 | Benteng Besi |

## Co-op online

2–4 pemain lewat WebRTC (signaling MQTT publik). Host membuat room dengan kode 5 huruf, teman
bergabung lewat kode atau link. Host menjalankan wave, musuh, dan kesulitan; tiap pemain mengurus
prajurit, senjata, dan belanjanya sendiri. HP boss dan jumlah musuh naik 60% per pemain tambahan.

**Bantuan mengejar**: pemain yang levelnya tertinggal dari teman tertinggi mendapat +30% rempah/XP
per level tertinggal (maks 4 level = +120%), plus bonus (2 + wave) rempah per level tertinggal di
akhir wave. Yang mati di awal wave pun tetap kebagian bonus ini.
