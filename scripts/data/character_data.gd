class_name CharacterData
extends Resource
## Karakter (kelas) yang bisa dipilih. Nambah karakter cukup bikin .tres baru di data/characters/.

@export var title := ""
@export var pros := ""
@export var cons := ""
## Gambar di kartu pilih karakter (assets/sprites/karakter_*.png, dari tools/make_sprites.py).
@export var portrait: Texture2D
## Perubahan stat awal, kunci sesuai Player.BASE_STATS.
@export var stats := {}
@export var start_weapon: WeaponData
## Terbuka setelah pernah mencapai wave ini (0 = terbuka dari awal).
@export var unlock_wave := 0
## Urutan tampil di menu.
@export var order := 0
