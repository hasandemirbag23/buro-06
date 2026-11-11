# BÜRO-06 — Proje Analizi

Tarih: 10 Kasım 2026 · Dal: `yuz-duzeltme-ve-animasyon` · Godot 4.7.2 (Forward+)

## 1. Genel yapı

| Katman | Dosyalar | Not |
|---|---|---|
| Akış | `scenes/main.gd` (974 satır) | Menü → büro → olay yeri → sorgu; tablet UI |
| Veri | `data/episode_0[1-5].json`, `cases.json` | Bölüm başına kadro, hotspot, delil, sorgu ağacı |
| Durum | `autoload/game_state.gd`, `scenario.gd`, `cinematic.gd`, `audio_hub.gd` | |
| Karakter | `scenes/character_rig.gd`, `character_styler.gd`, `face_rig.gd`, `pose_overlay.gd` | Quaternius gövde + prosedürel kafa + gölgelendirici yüz animasyonu |
| Mekân | `scenes/crime_office_3d.gd` (büro), `scenes/interrogation.gd` (sorgu), `scenes/crime_scene_3d.gd` + `scenes/sets/*_set.gd` (5 olay yeri) | Neredeyse tamamı kodla kurulan kutular + hazır kit parçaları |
| Kafa üretimi | `tools/headgen/headgen.py` | SDF → marching cubes; Python, Blender değil |

## 2. Görsel açıdan bugünkü durum

**Karakterler.** 12 karakter: Quaternius CC0 düşük poligon gövde + SDF kafa. Yüz hataları ve yüz animasyonu 9–10 Kasım'da düzeltildi (bkz. `docs/` dışı not: commit `2dc5493`, `8058972`). Kalan sorun: gövdeler düşük poligon ve düz renkli, kıyafetler Ankara polisi gibi değil; saçlar tek parça kabuk.

**Şehir.** Arka planlar Kenney *City Kit* (Amerikan banliyö evleri, gökdelenler, ABD trafik ışıkları) ile kurulmuş: `tower_set.gd:267-271`, `eczane_set.gd:95`, `menu_stage.gd:26-29`. **"Ankara'da değilim" hissinin ana kaynağı bu.** Kit, modülerlik açısından iyi ama mimari dil yanlış.

**İç mekânlar.** Büro Kenney *Furniture Kit* + kodla kutular; sorgu odası 42 prosedürel kutu + tek sandalye. Malzemeler büyük ölçüde düz renk. Poly Haven PBR dokuları (`assets/textures`, 9 set) yalnız `mesh_factory.gd:130` üzerinden birkaç yüzeyde kullanılıyor.

**Kullanılmayan varlıklar.** ~60 GLB hiçbir sahnede yüklenmiyor (City Kit'in yolları, işaretler, banliyö evleri; birkaç Quaternius gövdesi). Liste: `ASSET_INVENTORY.md`.

## 3. Korunacak sistemler (dokunulmayacak)

- `GameState` akışı, hotspot/delil/sorgu mantığı, tablet uygulamaları.
- Kamera geçişleri (`interrogation.gd · set_shot`, büro ve olay yeri kamera işaretleri).
- `CharacterRig` API'si: `setup/play/act/pose/look_at_target/set_expression/talk_for`. Yeni modeller bu arayüzün arkasına takılacak.
- Animasyon kütüphanesi `assets/anim/AnimationLibrary_Godot_Standard.gltf` + `GeneralSkeleton` humanoid profili.
- Testler: `tests/characters_test`, `episodes_test`, `scene_test`, `playthrough` — her entegrasyon adımından sonra koşulacak.

## 4. Kritik bulgular

1. **Tripo API bakiyesi 0.** `tripo doctor` ve `tripo balance` → `{"balance":0,"frozen":0}` (bölge ov). Planlanan 950 kredi bu hesapta görünmüyor. Tripo'da web stüdyo aboneliği kredileri ile API platformu kredileri **ayrı bakiyelerdir**; API'den yalnız platform bakiyesi harcanabilir. Test üretimi bu yüzden yapılamadı.
2. **Cevdet oyunda yok.** Beş bölümün kadrosunda, sorgu ağaçlarında ve diyaloglarda geçmiyor. Tasarlanabilir ama oyuna girmesi için senaryoya eklenmesi gerekir (anlatı işi, bu planın dışında).
3. **Dört şüphelinin kafası yok.** Rıza, Selim (bölüm 04), Yavuz, Adil (bölüm 05) `character_templates.json`'da tanımlı değil; varsayılan gövdeyle ve özel kafa olmadan çıkıyorlar.
4. **Tripo'nun yapabildikleri ile bu projenin ihtiyacı.** Tripo tek parça, dokulu mesh üretir; döşenebilir (tileable) bina cephesi modülü, kesintisiz yol/kaldırım parçası ya da birbirine kenetlenen mimari ızgara üretmekte zayıftır. Bu yüzden mimari Godot'ta modüler kurulacak, Tripo nesne ve kahraman varlıklar için kullanılacak (bkz. `ENVIRONMENT_DESIGN.md`).
5. **Tripo karakterlerinde yüz animasyonu sınırı.** Tripo yüzü dokuya boyanmış gözlerle tek mesh olarak verir; ayrı göz küresi ve göz kapağı yoktur. Bugünkü gölgelendirici yüz sistemi (`FACE_GLSL`) çene, kaş ve ağız deformasyonunu bir Tripo kafasına da uygulayabilir (anatomi koordinatları verilirse), **ama göz kırpma uygulanamaz.** Behzat testi bu ödünleşimi ölçmek için tasarlandı.

## 5. Performans

Ölçüm alınmadı (oyun pencereli koşturulup kare süresi kaydedilmedi). Bilinen yükler: kafa başına ~60k (deri) + ~40k (saç) üçgen; sahnede 3–6 karakter. Tripo modelleri için hedef bütçeler `GODOT_INTEGRATION.md`'de.

## 6. Ortam sorunları

- Repo iCloud ile eşitlenen `~/Desktop` altında; macOS dosyaları buluta taşıyınca git ve Godot zaman aşımına düşüyor. Kalıcı çözüm: repo'yu `~/projects` altına taşımak (kullanıcı şimdilik istemedi).
- `godot --headless --import` işini bitirip kapanmıyor; süreç elle sonlandırılmalı.
