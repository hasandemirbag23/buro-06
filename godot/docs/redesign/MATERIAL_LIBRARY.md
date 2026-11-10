# Malzeme Kütüphanesi

Hedef dosya: `godot/scenes/material_library.gd` (henüz yazılmadı) — her malzeme bir kez oluşturulup önbellekte paylaşılır (bugünkü `character_styler._cloth_cache` deseni). Dokular Poly Haven CC0 (lisans uygun); mevcut 9 set var, eksikler eklenecek.

| Malzeme | Doku kaynağı | Roughness | Normal | Not |
|---|---|---|---|---|
| Asfalt (aşınmış) | ✅ `asphalt_02` | 0,85 / ıslakta 0,25 | evet | ıslaklık maskesi (gölgelendirici) |
| Beton | ✅ `concrete_wall_006` | 0,9 | evet | |
| Beton zemin | ✅ `concrete_floor_worn_001` | 0,8 | evet | otopark, sorgu |
| Kaldırım taşı (kilitli parke) | ➕ Poly Haven `cobblestone_floor`/`paving` | 0,85 | evet | |
| Sıva (bej/somon) | ✅ `plastered_wall_02` + renk çarpanı | 0,92 | hafif | cephe varyasyonu tohumla |
| Eski boya duvar | ✅ `plastered_wall_02` + yağlı boya bandı | 0,6 alt / 0,85 üst | hafif | büro yarım boya |
| Tuğla | ➕ `red_brick` | 0,9 | evet | Ulus, bodrum |
| Ahşap masa | ✅ `wood_table_001` | 0,55 | evet | |
| Parke | ✅ `wood_floor_worn` | 0,6 | evet | Cebeci dairesi |
| Paslı metal | ✅ `rusty_metal_02` | 0,7 | evet | şantiye, korkuluk |
| Boyalı metal | düz renk + gürültü normal | 0,45 | prosedürel | dolap, sorgu masası |
| Cam | düz | 0,05, şeffaf | — | pencere, durak |
| Fayans / seramik | ➕ `tiles` | 0,3 | evet | mutfak, eczane |
| Mermer | ➕ `marble` | 0,2 | hafif | apartman girişi |
| Toprak/çamur | ✅ `brown_mud_leaves_01`, `mud_cracked_dry_03` | 0,95 | evet | şantiye |
| Deri | prosedürel (`character_styler.FABRICS.leather`) | 0,42 | gürültü | Behzat ceketi |
| Kumaş (yün, pamuk, kot, takım) | prosedürel (`FABRICS`) | 0,8–0,95 | gürültü | karakterler |
| Plastik | düz | 0,5 | — | konteyner, sandalye |

✅ = projede var · ➕ = eklenecek (Poly Haven CC0, indirme kullanıcı onayıyla).

Tripo varlıklarının kendi dokuları korunur; yalnız roughness/renk, sahne malzemeleriyle uyum için Godot'ta ayarlanır.
