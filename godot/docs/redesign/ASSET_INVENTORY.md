# Varlık Envanteri

## Mevcut 3B varlıklar (`godot/assets/`)

| Klasör | Adet | Kaynak / lisans | Kullanım | Karar |
|---|---:|---|---|---|
| `characters/` | 9 GLB | Quaternius CC0 | 4'ü kullanılıyor (gövde) | Tripo gövdeleri gelene kadar kalır |
| `heads/` | 12 × (skin, hair, json) | `tools/headgen` | tüm karakterler | İkincil karakterlerde kalır, iyileştirilir |
| `anim/` | 1 glTF + 2 bonemap | Universal Animation Library | tüm rigler | **Korunur** — Tripo rigleri buna retarget edilecek |
| `city/` | 45 GLB | Kenney City Kit CC0 | yollar, ağaç, tabela, şantiye | **Binalar değiştirildi** (11.11): `set_base.city()` Kenney bina çağrılarını Ankara apartmanına çevirir; lamba → S1, dumpster → S3. Ana menü silüeti de `set_base.apartment()` ile (Kenney binası kalmadı) |
| `furniture/` | 21 GLB | Kenney Furniture CC0 | büro + Cebeci dairesi | Kahraman masalar Tripo ile, arka plan kalır |
| `interior/` | 17 GLB | Quaternius CC0 | büro | Kısmen kalır |
| `props/` | 13 GLB | Quaternius / Kenney CC0 | olay yeri | Kısmen kalır |
| `vehicles/` | 9 GLB | Kenney Car Kit CC0 | olay yeri | **Polis aracı ve sedan görünümü Tripo S6/S5** (Kenney düğümü çarpışma için gizli kalır); SUV hotspot olduğu için kaldı |
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
| hayalet | characters | `5ae21818` | 65 | ok | büro, olay yerleri (tripo: true) |
| savci | characters | `ae3b7f0d` | 65 | ok | sorgu/büro (tripo: true) |
| akbaba | characters | `6deb0ba5` | 65 | ok | büro, olay yerleri (tripo: true) |
| cevdet | characters | `bca9ffaa` | 65 | ok | kullanılmıyor (senaryoda yok) |
| B1 | props | `7fad3128` | 30 | ok | büro masaları ×4 |
| B2 | props | `e376cfca` | 20 | ok | büro arşiv dolabı |
| B3 | props | `f39b560b` | 20 | ok | büro ×2 |
| B6 | props | `60364d05` | 20 | ok | büro, sorgu |
| Q1 | props | `5757e79d` | 20 | ok | sorgu masası |
| Q2 | props | `deec4b08` | 20 | ok | sorgu sandalyeleri ×2 |
| N1 | props | `8019984e` | 20 | ok | henüz yerleştirilmedi |
| N3 | props | `892407d8` | 20 | ok | henüz yerleştirilmedi |
| C1 | props | `85f784ed` | 20 | ok | kullanılmıyor (kalite düşük) |
| M1 | props | `b62b506b` | 20 | ok | apartman balkonları (MultiMesh) |
| M2 | props | `98bf59e1` | 20 | ok | apartman pencereleri (MultiMesh) |
| M3 | props | `bda773ee` | 30 | ok | apartman dükkânları (MultiMesh) |
| M4 | props | `8e963e88` | 20 | ok | apartman girişleri |
| S1 | props | `e9956785` | 20 | ok | tüm sokak lambaları |
| S3 | props | `4d8bcaf2` | 20 | ok | çöp konteynerleri |
| S4 | props | `773de129` | 30 | ok | henüz yerleştirilmedi |
| S5 | props | `6a93f170` | 30 | ok | park araçlar, set sedanları |
| S6 | props | `28feccb3` | 30 | ok | olay yeri ekip araçları, park |
| **Toplam** | | | **670** | | API sınırı 950 |

Behzat stüdyo hattıyla üretildi (stüdyo bütçesi, bkz. TRIPO_CREDIT_TRACKER). Ölçek ve yön: `PROP_SCALES.md`, kod: `scenes/props_lib.gd`.
