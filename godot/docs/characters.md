# BÜRO: Dosya No 06 — Karakter Tasarım Sistemi

Konsept sayfası: `docs/concept/character_sheet.png` (ön / yan / arka / yüz yakın plan / 3 aksiyon).
Veri: `data/characters.json` · Rig: `scenes/character_rig.gd` · Poz katmanı: `scenes/pose_overlay.gd`.

## Ortak sanat yönü

- Stilize gerçekçi, düşük-orta poligon; keskin kıyafet siluetleri, sade yüz geometrisi, boyalı değil düz-renk PBR (albedo + roughness).
- Palet: antrasit `#14171D`, kan kırmızısı `#DC2626`, dosya sarısı `#F59E0B`, gece mavisi `#1a2744`, parşömen `#e7d7b1`.
- Hepsi **Godot SkeletonProfileHumanoid** iskeletinde (`GeneralSkeleton`), 1.80–1.88 m, Y-up, metre ölçeği, A/T-pose.
- Animasyonlar karakterden bağımsız tek kütüphanede (`assets/anim/AnimationLibrary_Godot_Standard.gltf`) → her karakterde yeniden kullanılır.
- Yüz: 52 ARKit blend shape (browDownLeft, browInnerUp, eyeSquint*, eyeWide*, jawOpen, mouthFrown*, mouthSmile*, mouthPress*, cheekPuff…) → `set_expression()` otomatik eşler; blend shape yoksa baş duruşuyla ima eder.

## Mevcut durum (CC0 geçici modeller)

| Karakter | Taban model (Quaternius CC0) | Tint / aksesuar | Aksiyonlar |
|---|---|---|---|
| Başkomiser Behzat | man_Casual2 | kahve deri-ceket tonu, kır saç, kirli sakal, kambur overlay, çay bardağı | Idle, Talking, Angry, DrinkingTea, Thinking |
| Akbaba (Olay Yeri) | woman_Worker | lacivert tulum, beyaz yelek, mavi eldiven, kamera | Idle, Photographing, Inspecting, WritingReport |
| Hayalet (İstihbarat) | man_Casual | haki kapüşon, koyu kot | Walking, Talking, LookingAround, Idle |
| Savcı Nilgün Erdem | woman_Suit | siyah takım, dik duruş overlay | Talking, ReviewingDocuments, Angry, Thinking |
| Tarık Soylu | man_Suit | lacivert takım, altın kravat/saat | Confident, Arrogant, Nervous, Sweat, Angry, Confession |

Klip eşlemesi: Idle→`Idle`, Talking→`Idle_Talking`, Walking→`Walk`, Inspecting/Photographing→`Crouch_Idle`, oturma→`Sitting_Idle/Sitting_Talking`, diz→`Fixing_Kneeling`, tek seferlik→`Interact`, `PickUp_Table`, `Hit_Chest`. Thinking / DrinkingTea / WritingReport / Arrogant / Nervous / Confession = klip + `PoseOverlay` kemik ofsetleri.

## Model gereksinimleri (üretim)

- Bağımsız GLB, tam vücut + yüz geometrisi, düzgün anatomi, tek `Skeleton3D`.
- Kemik adları Godot humanoid profiliyle eşleşmeli (Hips, Spine, Chest, UpperChest, Neck, Head, Left/RightShoulder, UpperArm, LowerArm, Hand, parmaklar, UpperLeg, LowerLeg, Foot, Toes). Mixamo/Rigify adları da olur; `BoneMap` ile retarget edilir.
- Bacaklar **Hips**'in çocuğu olmalı (Root'un değil).
- Baş meshinde 52 ARKit blend shape; gözler ayrı mesh, göz kapakları kemikli ya da blend shape.
- ≤ 25k üçgen, 2048 albedo + ORM, kıyafet/saç/deri ayrı materyal slotları (`Body`, `Head`, `Legs`, `Feet` mesh adları korunur; tint sistemi materyal adıyla çalışır).
- Animasyon gerekmez; kütüphane retarget edilir. Karaktere özel klipler (DrinkingTea, Photographing) istenirse aynı iskelette ek GLB.

## Model üretim promptları (Meshy / Tripo / Blender-MPFB / Character Creator)

Ortak son ek (her prompta ekle):
`stylized-realistic 3D game character, full body, T-pose, clean topology, PBR flat-color materials, 52 ARKit facial blend shapes, humanoid rig with Godot/Mixamo bone names, legs parented to hips, 1.85 m, Y-up, glTF binary export, neutral studio lighting, no background`

### 1 — Başkomiser Behzat
`Turkish homicide chief detective, 48 years old, tired and hard face, deep nasolabial folds, grey-flecked stubble beard, messy salt-and-pepper hair, heavy eyelids, dark charcoal shirt with rolled sleeves under a worn brown leather jacket, dark trousers, scuffed black shoes, slightly hunched posture, stressed expression without a cigarette, small tea glass in left hand` + ortak son ek.
Animasyonlar: Idle, Talking, Angry, DrinkingTea, Thinking.

### 2 — Akbaba, Olay Yeri Uzmanı
`female crime scene investigator, 37 years old, calm and focused face, very short dark hair, navy forensic coverall with white reflective vest, blue nitrile gloves, navy cap with "OLAY YERİ" text, DSLR camera on chest strap, evidence marker in hand, upright attentive stance` + ortak son ek.
Animasyonlar: Photographing, Inspecting, WritingReport, Idle.

### 3 — Hayalet, İstihbarat Ekip Üyesi
`male undercover intelligence officer, 34 years old, street-smart relaxed look, sharp observant eyes, short beard shadow, olive-khaki hoodie under a dark bomber jacket, dark denim, worn sneakers, hands in pockets, slight head turn as if scanning the street` + ortak son ek.
Animasyonlar: Walking, Talking, LookingAround, Idle.

### 4 — Savcı Nilgün Erdem
`female Turkish public prosecutor, 38 years old, formal serious controlled expression, dark hair in a low bun, minimal makeup, black tailored classic suit, white shirt, discreet watch, leather document folder under arm, perfectly straight posture` + ortak son ek.
Animasyonlar: Talking, ReviewingDocuments, Angry, Thinking.

### 5 — Tarık Soylu
`wealthy Turkish construction tycoon, 48 years old, groomed hair greying at the temples, tanned skin, expensive navy three-piece suit, gold tie and gold wristwatch, confident chin-up pose but tense eyes and tight jaw hinting hidden guilt, polished brown shoes` + ortak son ek.
Animasyonlar: Confident, Arrogant, Nervous, Sweat, Angry, Confession.

## Entegrasyon

1. GLB'yi `assets/characters/` içine koy, `.import` dosyasında `retarget/bone_map` = `assets/anim/bonemap_<rig>.tres`, `retarget_method = 1` (Overwrite Axis), `rename_bones = true`, `make_unique = true` (`GeneralSkeleton`).
2. `data/characters.json` → `model` yolunu değiştir; `tint` anahtarları `Parça/Materyal`.
3. Yüz blend shape adları ARKit ise `set_expression("angry")` otomatik çalışır.
