# Sahne Envanteri

| Sahne | Dosya | Kurulum | Kamera | Karakterler | Bugünkü görsel kaynak |
|---|---|---|---|---|---|
| Ana menü | `scenes/menu_stage.gd` (967) | prosedürel | sabit + yavaş kayma | — | Kenney City Kit gökdelen/bina (A/B/C/low) |
| Büro (Cinayet Büro, Vadi Kule) | `scenes/crime_office_3d.gd` (595) | 24 prosedürel kutu + 18 kit parçası | serbest/odak | Behzat, Hayalet, Ayşe, Savcı (NPC beyni) | Kenney Furniture + Interior kit |
| Olay yeri kabuğu | `scenes/crime_scene_3d.gd` (851) | 27 kutu + araçlar | hotspot kameraları | Akbaba, Behzat, Hayalet | Kenney araçlar (police, sedan, suv, truck) |
| — 01 Vadi Kule şantiyesi | `sets/tower_set.gd` (307) | **93 kutu** | | Zafer, Tarık | City Kit gökdelenler (arka plan) |
| — 02 Cebeci, Öveç Sokak dairesi | `sets/flat_set.gd` (137) | 31 kutu + 7 mobilya | | Mert, Haldun | Furniture Kit |
| — 03 Maltepe, Geceler Gazinosu | `sets/pavyon_set.gd` (121) | 28 kutu + sedan | | Nevzat, İdris | — |
| — 04 Bahçelievler 4. Cadde eczanesi | `sets/eczane_set.gd` (105) | 15 kutu | | Rıza, Selim | City Kit silüet |
| — 05 Ulus Zabıta Otoparkı | `sets/garaj_set.gd` (91) | 12 kutu | | Yavuz, Adil | — |
| Sorgu odası | `scenes/interrogation.gd` (587) | 42 kutu + 1 sandalye | 6 sabit çekim (`SHOT_NODES`) | şüpheli, Behzat, oyuncu | prosedürel |
| Tablet UI | `scenes/ui/tablet*` | 2B | — | — | — |

**Geçişler:** `main.gd · SCENES` = `office`, `site`, `interrogation` (+ menü). Olay yeri seti `Scenario.data["set"]` ile seçiliyor (`crime_scene_3d.gd:16-20, 552`). Bu yapı korunacak; yeni mekânlar aynı `set_base.gd` arayüzünü uygulayacak.

## Yeniden tasarım önceliği (oyuncunun gördüğü süreye göre)

1. **Büro** — her bölümün başı ve sonu; en çok görülen mekân.
2. **Sorgu odası** — her bölümün doruk noktası, yakın çekim karakter yüzleri.
3. **Olay yeri sokak dokusu** (5 set ortak): kaldırım, apartman cephesi, sokak lambası, araçlar.
4. Set özelinde kahraman varlıklar (şantiye iskelesi, eczane tezgâhı, pavyon sahnesi…).
5. Ana menü arka planı (Ankara silüeti).
