# Prop Ölçekleri (Tripo API, 11.11.2026)

Tripo çıktısı en uzun kenarı **1,0 birim** olacak şekilde normalize edilir ve **orijinde ortalanır** (taban `y = min_y`, yani yarı yükseklik kadar aşağıda). Godot'ta tek tip ölçek `s` uygulanır, sonra model `-min_y × s` kadar yukarı kaldırılır ki zemine otursun. Değerler `scenes/props_lib.gd` içindeki tabloyla aynıdır. Kaynak ölçüm: GLB `POSITION` accessor min/max (normalize boyutlar aşağıda).

| # | Varlık | Normalize boyut (x · y · z) | Ölçek `s` | Gerçek boyut (m) | Ölçeği belirleyen | Not |
|---|---|---|---:|---|---|---|
| B1 | Ahşap ofis masası | 0,56 · 0,42 · 1,00 | 1,81 | 1,02 × 0,76 × 1,81 | yükseklik 0,76 | yön −90°: çekmeceler oturan tarafta (−Z); büroda 1,46 × 0,79 × 0,76 m'ye sığdırılır (eski masa izi) |
| B2 | Metal dosya dolabı | 0,69 · 1,00 · 0,58 | 1,32 | 0,91 × 1,32 × 0,77 | yükseklik 1,32 | yön −90° (çekmeceler +Z) |
| B3 | Bilgisayar seti | 1,00 · 0,75 · 0,70 | 0,75 | 0,75 × 0,56 × 0,52 | genişlik | masa üstüne |
| B6 | Çay seti | 0,48 · 0,87 · 1,00 | 0,35 | 0,17 × 0,30 × 0,35 | çaydanlık 0,30 | |
| C1 | Branda altında ceset | 0,61 · 1,00 · 0,74 | 1,80 | — | boy 1,80 | **kullanılmıyor**: buruşuk dik çarşaf çıktı, ceset okunmuyor |
| M1 | Balkon korkuluğu | 0,22 · 0,70 · 1,00 | 1,44 | 0,32 × 1,00 × 1,44 | yükseklik 1,00 | uzun kenar Z |
| M2 | Pencere + panjur | 0,31 · 1,00 · 0,90 | 1,60 | 0,50 × 1,60 × 1,44 | yükseklik 1,60 | cephe X'e bakar |
| M3 | Kepenkli dükkân | 0,54 · 0,96 · 1,00 | 3,60 | 1,93 × 3,44 × 3,60 | genişlik 3,60 | yön −90° (kepenk +Z) |
| M4 | Apartman girişi | 0,71 · 1,00 · 0,76 | 3,00 | 2,13 × 3,00 × 2,29 | yükseklik 3,00 | |
| N1 | Delil torbası | 0,21 · 0,97 · 1,00 | 0,30 | — | uzunluk 0,30 | dik çıktı: Z'de 90° yatır |
| N3 | Çatlak telefon | 0,53 · 0,08 · 1,00 | 0,16 | 0,08 × 0,013 × 0,16 | boy 0,16 | zaten yatık |
| Q1 | Sorgu masası | 1,00 · 0,62 · 0,53 | 1,20 | 1,20 × 0,74 × 0,64 | uzunluk 1,20 | |
| Q2 | Sorgu sandalyesi | 0,82 · 1,00 · 0,83 | 0,85 | 0,69 × 0,85 × 0,70 | yükseklik 0,85 | yön −45° (model çapraz çıktı) |
| S1 | Çift kollu lamba | 0,15 · 1,00 · 0,47 | 7,00 | 1,05 × 7,00 × 3,30 | yükseklik 7,0 | |
| S3 | Çöp konteyneri | 1,00 · 0,87 · 0,68 | 1,49 | 1,49 × 1,30 × 1,01 | yükseklik 1,30 | |
| S4 | Otobüs durağı | 0,44 · 0,65 · 1,00 | 4,00 | 1,77 × 2,58 × 4,00 | uzunluk 4,0 | |
| S5 | 90'lar sedan | 1,00 · 0,35 · 0,45 | 4,30 | 4,30 × 1,48 × 1,95 | uzunluk 4,3 | ızgara logosu dokudan silindi |
| S6 | Polis aracı | 1,00 · 0,38 · 0,46 | 4,60 | 4,60 × 1,75 × 2,11 | uzunluk 4,6 | "PALICE" yazısı ve amblemler dokudan silindi; "POLİS" Godot'ta `Label3D` |

## Doku temizliği (S5, S6)

Tripo metin/logo eklemeye meyilli. Logolar yeniden üretim (30 kr) yerine **0 kredi** ile silindi: GLB'deki gömülü doku çıkarıldı, Godot `Image` API'siyle "çevresi lacivertse (veya koyuysa) açık pikseli komşu ortalamasıyla doldur" kuralı birkaç tur uygulandı (düz kenarlar korunur, yalnız çevrili yazı/amblem erir), sonra doku GLB'ye geri gömüldü. Orijinal GLB'ler yedeklenmedi; yeniden üretim gerekirse görev kimlikleri `tools/tripo/ledger.csv`'de.

## Poligon

Toplam ~79 000 üçgen (18 varlık). En ağırları araçlar (~9 500) ve masa (6 500); bir sahnede ≤ 6 masa + 2 araç bütçe içinde.

## Yön doğrulama

`tools/prop_sheet.tscn` tüm nesneleri hedef boyutta dizer ve `/tmp/props_sheet.png` yazar: `godot --path . --resolution 1600x900 res://tools/prop_sheet.tscn`. Yön düzeltmeleri `scenes/props_lib.gd · SPEC` içinde; düzeltmeden sonra her modelin önü +Z'ye bakar.
