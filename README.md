# Laskar Nusantara

Roguelite arena shooter co-op bertema Nusantara (Godot 4.7, renderer Compatibility).
Prajurit dari 8 kerajaan Nusantara bersatu melawan Kekaisaran Besi.
Rencana lengkap: [PLAN.md](PLAN.md).

**Main:** https://lshinkuro.github.io/laskar-nusantara/

## Cara main
- **Gerak:** WASD / panah, atau sentuh & geser layar (HP). Senjata menembak otomatis.
- **Ganti baju:** pilih seragam kerajaan (Majapahit, Sriwijaya, Mataram, Pajajaran, Samudra Pasai,
  Gowa, Kutai, Ternate) dengan tombol `<` `>` di menu/lobby.
- **Rempah** dari musuh yang gugur = uang belanja di **Pasar Rakyat** antar-wave sekaligus XP.
- **Naik level:** HP Maks +1, lalu di akhir wave pilih 1 dari 4 *ilmu* (upgrade stat) per level.
- **Ketupat** kadang jatuh dari musuh: +3 HP (tidak diambil kalau HP masih penuh).
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
scripts/  net (autoload lobby+signaling), main, player, weapon, enemies, pickups,
          projectiles, wave_manager, shop, menu, sawah, touch_joystick
data/     items/*.tres, weapons/*.tres   (nambah konten = bikin file baru)
assets/   sprites/ (dibuat oleh tools/make_sprites.py), fonts/ (Pixelify Sans, OFL), ui/theme.tres
tests/    smoke_test (solo), level_test (XP, ilmu, ketupat), touch_test, net_test (co-op 2 proses lewat ENet)
```

## Tes
```sh
godot --headless --fixed-fps 60 -s res://tests/smoke_test.gd
godot --headless -s res://tests/level_test.gd
godot --headless -s res://tests/net_test.gd -- host &  godot --headless -s res://tests/net_test.gd -- client
```

## Rilis web
Setiap push ke `main` otomatis di-export ke Web dan di-deploy ke GitHub Pages
(`.github/workflows/deploy.yml`). Thread Support dimatikan, jadi tidak perlu header COOP/COEP.
