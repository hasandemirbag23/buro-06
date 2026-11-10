# Tripo Stüdyo → Godot Hattı (doğrulandı: Behzat, 10.11.2026)

Ajanlar için çalışma tarifi. API bakiyesi 0; üretim **studio.tripo3d.ai** web stüdyosundan, uygulama içi tarayıcıyla (hesap zaten girişli) yapılır. Bütçe: 3000 stüdyo kredisi, kayıt `TRIPO_CREDIT_TRACKER.md`.

## 1. Üretim (55 kr)
- `https://studio.tripo3d.ai/tr/workspace/generate` → sol kutuda kalem simgesi (metin modu) → `textarea`.
- Metni yazmak için `computer type` güvenilmez (gecikmeli çift yazım oldu). JS ile yaz:
  `Object.getOwnPropertyDescriptor(HTMLTextAreaElement.prototype,'value').set.call(t,v); t.dispatchEvent(new Event('input',{bubbles:true}))` → sayaç `N/1000` doğrula.
- "Oluştur 55" düğmesi. URL `/workspace/generate/<task_id>` olur. ~3 dk.
- **Prompt kuralı (karikatürü önler):** "Photorealistic 3D scan of a real …", oran ölçüsü ("head is 1/7.5 of body height, normal-sized hands, normal nose"), "Standing straight in A-pose, arms 30 degrees away from the body, feet together", sonda "Not a cartoon, not a caricature, not a toy figure, no exaggerated features." **"stylized", "game character" kelimelerini kullanma.**
- Kötü sonuçta önce **"Ücretsiz Yeniden Dene (×3)"** kullan (kredi harcamaz).

## 2. Retopo (40 kr) — yalnız karakter ve büyük nesneler
- `/workspace/retopology/<task_id>`; görüntüleyici boşsa sağdaki Varlıklar'dan modele tıkla, yüklenmesini bekle.
- Quad, Akıllı Ağ açık, Poligon 10000 (karakter) / 3000–6000 (nesne). "Retopoloji 40". ~1,5 dk. Sonuç: "Yüzeyler 10076".

## 3. Rig (20 kr) — yalnız karakter
- Soldaki **Rig** öğesine sayfa içinden tıkla (URL'ye gitme; retopo sürümü kaybolabilir). İnsansı + **Mixamo** ön ayarı → "Otomatik Rig 20". ~1 dk.

## 4. Dışa aktarma
- "Dışa Aktar" → Format **GLB** (varsayılan FBX!), doku 4k (karakter) / 2k (nesne), ad = id. Pencere düğmesine JS ile tıkla: `button.animate-button` metni "Dışa Aktar". Ekran görüntüsü bazen bayat kalır; durumu `document.body.innerText` ile doğrula. Tarayıcı boyutu değişince pencere sıfırlanır.
- Dosya `~/Downloads/<id>.glb` iner → `godot/assets/generated/characters/<id>/<id>.glb` (nesne: `.../props/<id>/`).

## 5. Godot (karakter)
1. Bir kez içe aktar: `godot --headless --path . --import` arka planda; `.godot/imported/<id>.glb-*.scn` oluşunca `pkill -x godot` (süreç kendiliğinden kapanmaz).
2. `<id>.glb.import` içinde: `nodes/root_scale` = karakter boyu (m) / model boyu (Tripo çıktısı 1,0 birim) → ör. 1.8; `_subresources` bloğu Behzat'takiyle aynı (`assets/generated/characters/behzat/behzat.glb.import` kopyala): yol anahtarı `"PATH:Node/node_0/RootNode/Armature/Skeleton3D"`, bone map `res://assets/anim/bonemap_mixamo.tres`, `fix_silhouette/enable: true` (yoksa kollar sırta döner). Yeniden içe aktar.
3. `data/characters.json` → `<id>`: `legacy_model` = eski model, `model` = yeni GLB, `"tripo": true`, `tint: {}`, eski `overlay` → `legacy_overlay`, `overlay: {}`.
4. Doğrulama: `godot --path . --resolution 1280x720 res://scenes/CharacterShowcase.tscn -- shots <id>` → `/tmp/showcase_<id>_front_sinema.png`; kollar önde, baş dik, ayaklar yerde olmalı. Sonra `tests/characters_test.tscn` (FAIL yok).

## 6. Kayıt
Her adımı `TRIPO_CREDIT_TRACKER.md` harcama tablosuna satır olarak ekle (task_id, kredi, sonuç). Kabul/ret gerekçesini yaz.

## Bilinen sınırlar
- Tripo yüzlerinde ayrı göz küresi yok → göz kırpma yok; prosedürel yüz animasyonu (`FaceRig`) Tripo karakterlerinde kapalı.
- Showcase'in "face" açısı prosedürel kafa yüksekliğine göre kadrajlıyor; Tripo karakterde kadraj kayık olur (oyunu etkilemez).
