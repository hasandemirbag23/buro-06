# Karakter Tasarımı — Strateji

Ayrıntılar: `CHARACTER_DESIGN_MAIN.md` (5 ana karakter), `CHARACTER_DESIGN_SECONDARY.md` (diğerleri).

## İki kademe, iki üretim yolu

| Kademe | Karakterler | Üretim | Neden |
|---|---|---|---|
| Ana | Behzat, Hayalet, Akbaba, Savcı, Cevdet | **Tripo** tam gövde (v3.1, detaylı doku) + Tripo humanoid rig | Gövde, kıyafet ve kumaş kalitesi Quaternius ile elde edilemez |
| İkincil | Player, Ayşe, Tarık, Zafer, Mert, Haldun, Nevzat, İdris + eksik 4 şüpheli | **Prosedürel kafa** (`tools/headgen`, 0 kredi) + mevcut gövde + Godot kumaş malzemeleri | Kredi bütçesi 12 ayrı Tripo karakterini taşımaz; kafa sistemi yüz animasyonunu zaten destekliyor |

## Ana karakterlerde yüz sorunu ve test

Tripo yüzleri dokuya boyanmış gözlerle tek mesh gelir. Sonuç iki seçenekten biri olacak; Behzat testi karar verecek:

- **A — Tam Tripo:** Gövde + yüz Tripo. Çene/kaş/ağız deformasyonu `FACE_GLSL` ile Tripo kafasına uygulanır (göz ve ağız koordinatları elle ölçülüp `head.json` benzeri dosyaya yazılır). **Göz kırpma olmaz.** Yüz kalitesi Tripo'ya bağlı.
- **B — Melez:** Tripo gövde, boyundan yukarısı prosedürel kafa (`character_styler.apply` bugün de böyle çalışıyor). Kırpma ve tüm ifadeler çalışır; risk, gövde ile kafa arasında kalite/stil farkı.

Ölçüt: Normal oyun kamerasında (sorgu yakın çekimi `Cam_SuspectCloseUp`) Tripo yüzü prosedürel yüzden daha inandırıcıysa A; değilse B.

## Rig ve animasyon

Tripo humanoid rig (`rig_type=biped`) → GLB. Godot içe aktarmada `BoneMap` ile `SkeletonProfileHumanoid`'e (GeneralSkeleton) eşlenir — Quaternius modellerine bugün yapılanın aynısı (`assets/anim/bonemap_quaternius.tres`). Böylece mevcut animasyon kütüphanesi, `PoseOverlay` ve `CharacterRig.act()` değişmeden çalışır. Tripo'nun kendi animasyonları kullanılmayacak.

**Godot'un yapamadığı:** Tripo mesh'inin ağırlık boyamasını (skin weights) düzeltmek. Tripo rigi kötü çıkarsa çözüm yeniden rig istemektir (kredi), Godot'ta elle ağırlık boyanamaz.

## Ortak kurallar

- Gerçek oyuncu yüzü yok; karakter kimliği kişilikten ve kıyafetten gelir.
- Her ana karakterin siluet testi: siyah dolgu hâlinde bile ayırt edilebilmeli (Behzat kambur + deri ceket, Hayalet uzun-ince + kapüşon, Savcı blazer + dik duruş, Cevdet düz omuz + kısa saç, Akbaba tulum/yelek + kamera).
- A-poz, ayaklar yerde, kollar 45°; Tripo promptlarında açıkça istenir (rig için şart).
