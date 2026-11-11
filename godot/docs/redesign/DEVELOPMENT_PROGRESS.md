# Gelişim Durumu

Son güncelleme: 11 Kasım 2026

| Aşama | Durum | Çıktı |
|---|---|---|
| 1 — Proje analizi | ✅ | `PROJECT_ANALYSIS.md`, `*_INVENTORY.md` |
| 2 — Sanat yönü | ✅ (referans fotoğraf seti kullanıcıyla netleşecek) | `ART_DIRECTION.md`, `ANKARA_WORLD_DESIGN.md` |
| 3 — Karakter tasarımları | ✅ belge | `CHARACTER_DESIGN*.md` |
| 4 — Çevre tasarımı | ✅ belge | `ENVIRONMENT_DESIGN.md`, `BUILDING_DESIGN.md`, `INTERIOR_DESIGN.md`, `STREET_AND_ROAD_DESIGN.md`, `MATERIAL_LIBRARY.md`, `SCENARIO_ASSETS.md` |
| 5 — Kredi planı | ✅ (gerçek v3.1 fiyatlarıyla) | `TRIPO_CREDIT_TRACKER.md` |
| 6 — Test üretimi | ⛔ **engelli: API bakiyesi 0** | hazır: `tools/tripo/test_uretim.sh` (kuru çalıştırma doğrulandı) |
| 7 — Kullanıcı onayı | ⏳ bekliyor | aşağıdaki kararlar |
| 8–10 | başlamadı | |

## Kullanıcıdan beklenen kararlar

1. **Kredi:** API bakiyesi 0. 950 kredi web stüdyodaysa API platformuna (developers.tripo3d.ai → Billing) aktarılması/yüklenmesi gerekiyor. Satın alma işlemini ben yapamam.
2. **Akbaba'nın cinsiyeti:** Oyunda kadın; tasarım promptu erkek diyor. Varsayılan: oyundaki gibi kadın.
3. **Cevdet:** Oyunda yok. Model üretilsin mi, yoksa kredi başka ana karaktere/çevreye mi aktarılsın? Üretilirse senaryoya eklenmesi ayrı iş.
4. **Bütçe sapması:** "Diğer karakterler" %5 → %0, çevreye aktarıldı (gerekçe kredi takibinde).
5. **Behzat testinden sonra:** A (tam Tripo, kırpmasız) mı B (Tripo gövde + prosedürel animasyonlu kafa) mı — test görselleriyle karar.

## Test sonrası yapılacaklar (onay geldiğinde, sırayla)

1. `tools/tripo/test_uretim.sh` (~75 kr) → Godot'a içe aktar → `bonemap_tripo.tres` → sorgu yakın çekimi render → A/B kararı.
2. Kredi takibine gerçek rig maliyeti yazılır, plan güncellenir.
3. Öncelik 1 ortak varlıklar (büro, sorgu, delil) → entegrasyon → testler.
4. Kalan ana karakterler.
5. Sokak modülleri + `set_base` apartman/sokak yardımcıları (0 kredi, şimdi de başlanabilir).
6. Bölüm kahraman varlıkları.

## Kredi gerektirmeyen, onay beklemeden yapılabilecek işler

- `set_base.gd`: modüler apartman, kaldırım/bordür, Türkçe tabela yardımcıları (Kenney City Kit'in yerine).
- `material_library.gd`: paylaşılan PBR malzemeler.
- Eksik dört şüpheli (Rıza, Selim, Yavuz, Adil) için kafa şablonları.

## DEVAM NOKTASI (11.11.2026)

**Proje yeri değişti:** `~/Projeler/Büro-06` (iCloud dışı). Masaüstündeki kopya disk dolu olduğu için iCloud'a boşaltılıyordu; GitHub'dan klonlandı, yerel commit'ler ve commit edilmemiş iş taşındı. Masaüstü kopyası artık kullanılmamalı.

**Bitti:**
- API 670/950: 4 karakter ve öncelik 1–2'nin 18 nesnesi. Ayrıntı: `TRIPO_CREDIT_TRACKER.md`, `ASSET_INVENTORY.md`.
- `scenes/props_lib.gd` ile ölçek ve yön tablosu (`PROP_SCALES.md`).
- Büro: B1 masalar, B2 dolap, B3 bilgisayar, B6 çay.
- Sorgu: Q1 masa, Q2 sandalyeler, B6 çay.
- Olay yerleri (`set_base.gd`):
  - Kenney binaları yerine Ankara apartmanları (A/B/C/D tipleri; kiremit çatı, kat bantları, M2 pencere, M1 balkon, M3 dükkân, M4 giriş MultiMesh ile).
  - S1 lambalar, S3 konteynerler, S5/S6 park araçları.
  - `crime_scene_3d._reskin` ile Kenney polis aracı ve sedanlar Tripo görünümünde; Kenney düğümü çarpışma ve ışık için gizli kalır.
- Oynanış, hotspot, kamera ve çarpışma kutuları değişmedi.
- Testler: `characters_test` TAMAM, `episodes_test` OK, `scene_test` OK.
- Render araçları: `tools/scene_shot.tscn -- <office|interrogation|episode_0N>`, `tools/prop_sheet.tscn`.

**Bilinen sorun:** Tripo API rig'li karakterlerde (Hayalet, Savcı, Akbaba) animasyon oynarken baş öne/yana eğik. T-pozunda dik; Behzat (Mixamo) düzgün. `bonemap_tripo.tres` ve retarget ayarları incelenmeli. `fix_silhouette` filtresine Neck/Head eklemek etki etmedi.

**Sıradaki işler:**
1. Tripo rig baş eğikliği.
2. N1/N3/S4 yerleştirme (delil torbası, telefon, durak).
3. Öncelik 3 nesneler (≈180 kr).
4. Kaldırım/asfalt PBR, Türkçe sokak tabelaları.
5. Eksik 4 şüpheli kafası.
