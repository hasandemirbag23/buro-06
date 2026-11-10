# Varlık Envanteri

## Mevcut 3B varlıklar (`godot/assets/`)

| Klasör | Adet | Kaynak / lisans | Kullanım | Karar |
|---|---:|---|---|---|
| `characters/` | 9 GLB | Quaternius CC0 | 4'ü kullanılıyor (gövde) | Tripo gövdeleri gelene kadar kalır |
| `heads/` | 12 × (skin, hair, json) | `tools/headgen` | tüm karakterler | İkincil karakterlerde kalır, iyileştirilir |
| `anim/` | 1 glTF + 2 bonemap | Universal Animation Library | tüm rigler | **Korunur** — Tripo rigleri buna retarget edilecek |
| `city/` | 45 GLB | Kenney City Kit CC0 | 10'u arka plan silüeti | **Değiştirilecek** (Amerikan mimari) |
| `furniture/` | 21 GLB | Kenney Furniture CC0 | büro + Cebeci dairesi | Kahraman masalar Tripo ile, arka plan kalır |
| `interior/` | 17 GLB | Quaternius CC0 | büro | Kısmen kalır |
| `props/` | 13 GLB | Quaternius / Kenney CC0 | olay yeri | Kısmen kalır |
| `vehicles/` | 9 GLB | Kenney Car Kit CC0 | olay yeri | Polis aracı değiştirilecek |
| `textures/` | 9 PBR set (27 JPG) | Poly Haven CC0 | az | **Genişletilecek** (bkz. MATERIAL_LIBRARY) |
| `audio/` | 30+ OGG | Kenney / CC0 | — | dokunulmaz |

## Hiç yüklenmeyen GLB'ler (temizlik adayı)

City Kit: `building-d/e/f/g/h`, tüm `building-type-*` (banliyö), `building-skyscraper-b/c`, `low-detail-building-b/c/d`, tüm `road-*`, `traffic-light`, `sign-highway`, `road-sign-street`, `construction-*`, `dumpster`, `electricity-pole`, `light-square*`, `fence`, `planter`, `path-long`, `tree-*`, `detail-*`.
Diğer: `Trashcan`, `cp_TV_1`, `Radio`, `cp_Pipe_1`, `cp_AC`, `Torch`, `cp_Computer`, `Streetlight_Double`, `lampRoundTable`, `cardboardBoxOpen`, `bookcaseOpen`, `televisionVintage`, `deskCorner`, `wheel*`, `deliveryFlat`, `Trashcan_Small1`, `Drawer_2/4`, `Chair_1/2`, `Shelf_Large`, `Light_Ceiling3`, `Light_Desk`, `Stool`.

Silme işlemi yapılmadı; yeni varlıklar oturduktan sonra değerlendirilecek.

## Yeni üretilecek varlıkların listesi

Tam liste ve öncelik: `SCENARIO_ASSETS.md`. Kredi dağılımı: `TRIPO_CREDIT_TRACKER.md`.

Kayıt kuralı: Tripo çıktıları `godot/assets/generated/<kategori>/<ad>/` altına iner; her biri bu tabloya satır olarak eklenir (ad · kategori · task_id · kredi · durum · sahne).

| Ad | Kategori | task_id | Kredi | Durum | Sahne |
|---|---|---|---:|---|---|
| — | — | — | — | henüz üretim yok | — |
