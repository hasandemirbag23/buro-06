# Tripo Kredi Takibi

## API harcaması (güncel: 11.11.2026)

**670 / 950** (bakiye 1000 → 330). Tek kaynak: `tools/tripo/ledger.csv` (her iş `tools/tripo/uret.sh` ile, sınırı betik uygular).

| Kalem | Kredi |
|---|---:|
| 4 ana karakter (Hayalet, Savcı, Akbaba, Cevdet) × 65 (görselden 3B 40 + rig 25) | 260 |
| 18 nesne (B1 B2 B3 B6 Q1 Q2 N1 N3 C1 M1 M2 M3 M4 S1 S3 S4 S5 S6) | 410 |
| **Toplam** | **670** |
| Kalan sınır (yedek ~80 ayrılırsa üretilebilir) | 280 (≈200) |

Öncelik 1–2 nesnelerin hepsi üretildi. Öncelik 3 (T1 T2 F1 F2 P1 E1 G1 ≈ 180) kalan sınıra sığar; henüz üretilmedi. S5/S6 dokusundaki logo/yazı yeniden üretim yerine 0 krediyle silindi (`PROP_SCALES.md`).


**Bütçe sınırı: 3000 stüdyo kredisi** (kullanıcı, 10.11.2026: "950 API içindi, 3000'e kadar geçebilirsin"). Stüdyo başlangıç bakiyesi 3645.

**Stüdyo hattı (ölçülen fiyatlar):** üretim 55 · Retopo (≤10 000 quad) 40 · Rig (insansı, Mixamo iskeleti) 20 · görsel üretimi 0 (ücretsiz kota, kuyruk yavaş) · her işlemde **3 ücretsiz yeniden deneme**.
Karakter = 55 + 40 + 20 = **115** · çevre nesnesi = 55 + 40 = **95**.

### Yeni dağılım (3000)
| Kategori | Kredi | İçerik |
|---|---:|---|
| Ana karakterler (5) | 575 + test 55 | 5 × 115 |
| İkincil karakterler | 0 | prosedürel kafa sistemi (gerekçe aşağıda, değişmedi) |
| Çevre + senaryo nesneleri | ~1 900 | ~20 varlık × 95 |
| Yedek | ~470 | başarısız/iyileştirme |
**API bakiyesi (10 Kasım 2026, `tripo balance`): 0 kredi.** → Üretim yapılamıyor. Bkz. Engeller.


## Stüdyo harcaması — ikincil karakterler (11.11.2026)

Kullanıcı onayıyla stüdyo bütçesinden (bakiye 2940 → 2595, **345 kr**). Hat: `TRIPO_STUDIO_PIPELINE.md` §0–§5 (doğrudan T-pozu prompt'u, Nano Banana 2 ücretsiz, çok açılı 3B 55 + Retopo 40 + Mixamo rig 20).

| Karakter | Görev (rig) | Kredi | Sonuç |
|---|---|---:|---|
| tarik (Tarık Soylu) | 0b7d3b6d | 115 | kabul — lacivert takım, altın kravat ve saat, kırlaşmış şakak; 17 986 üçgen |
| player (Komiser) | 5e98f96a | 115 | kabul — füme takım, siyah gömlek; 17 842 üçgen |
| arsiv (Ayşe) | 4e631817 | 115 | kabul — topuz gri saç, gözlük, hırka, pileli etek; 19 747 üçgen |

Godot: Behzat'ın `.import` ayarları (bonemap_mixamo, fix_silhouette), `root_scale` = boy (1,78 / 1,80 / 1,62). Mixamo rig'li stüdyo çıktısı +Z'ye bakıyor, `face_z.py` gerekmez. `characters.json`'da eski değerler `legacy_model/legacy_tint/legacy_overlay`. Not: bu ortamda stüdyo "Dışa Aktar" dosyayı ~/Downloads'a indirmiyor; ajan GLB'yi sayfadan yakalayıp yerel geçici sunucuyla aldı.

## Gerçek fiyatlar (Tripo H3.1 / v3.1, resmi)

Kaynak: [developers.tripo3d.com/en/models/v3-1](https://developers.tripo3d.com/en/models/v3-1) + `tripo make --dry-run` tahmini.

| İş | Dokusuz | Standart doku | Detaylı doku | 8K doku |
|---|---:|---:|---:|---:|
| Metinden 3B | 10 | 20 | 30 | 40 |
| Görselden 3B | 20 | 30 | 40 | 50 |
| Çok görüşten 3B | 20 | 30 | 40 | 50 |

Ekler: detaylı geometri +20 · quad mesh +5 · smart low-poly +10 · parçalı üretim +20.
**Rig maliyeti resmi sayfada yok.** Plan değeri 25 kr **varsayımdır**; ilk rigden sonra `tripo usage` ile ölçülüp bu tablo düzeltilecek.

Karşılaştırma: CLI varsayılanı P2 modeli aynı iş için **110–120 kr** (dry-run). 950 krediyle P2'de ~8 model, v3.1'de ~35–45 model çıkar → **v3.1 seçildi.** P2'ye yalnız Behzat testi sonucu v3.1 yüzü yetersiz bulunursa, yedekten ve kullanıcı onayıyla geçilir.

## Plan

| Kategori | Hedef (prompt) | Plan | Kredi | Gerekçe |
|---|---:|---:|---:|---|
| Ankara, binalar, sokaklar, iç mekân, senaryo nesneleri | %55 · 523 | **%62** | **590** | 27 varlık; binalar Godot'ta modüler olduğu için Tripo nesnelere ayrıldı |
| Beş ana karakter | %30 · 285 | **%29** | **275** | 5 × (30 detaylı doku + 25 rig) |
| Diğer karakterler | %5 · 48 | **%0** | **0** | Prosedürel kafa sistemi 0 kredi ve yüz animasyonunu destekliyor; Tripo'da 48 kr ancak 1 karakter eder, tek bir Tripo karakteri ikincil kadro içinde stil uyumsuzluğu yaratırdı |
| Yedek / iyileştirme | %10 · 95 | **%9** | **85** | Behzat detaylı geometri tekrarı (50) + 1 başarısız üretim |
| **Toplam** | | | **950** | |

Sapma özeti: diğer karakterlerin %5'i çevreye aktarıldı; rig maliyeti varsayımdan yüksek çıkarsa fark yedekten karşılanır, yedek yetmezse öncelik 3 varlıklardan biri (P1 → F2) çıkarılır.

## Harcama kaydı

| # | Tarih | Varlık | Kategori | Ayar | Kredi | Sonuç | Tekrar? | Toplam | Kalan |
|---|---|---|---|---|---:|---|---|---:|---:|
| 1 | 10.11.2026 | Behzat (test 1) | Ana karakter | stüdyo, metinden 3B, H3.1, 4K PBR | 55 | **ret**: karikatür oranları (büyük kafa/el/burun), 1 919 149 yüz | evet — görselden 3B ile | 55 | 895 |

| 2 | 10.11.2026 | Behzat (test 2) | Ana karakter | stüdyo, metinden 3B, H3.1; prompt: "photorealistic 3D scan", oran ölçüsü (baş = boy/7,5), "stylized/game character" çıkarıldı · görev 928dfe8c | 55 | **kabul**: gerçekçi oran, deri ceket ve bıyık okunuyor; yüz hafif stilize | — | 110 | 2890 |
| 3 | 10.11.2026 | Behzat retopo | Ana karakter | Quad, 10 000 | 40 | 10 076 yüz, doku korundu | — | 150 | 2850 |
| 4 | 10.11.2026 | Behzat rig | Ana karakter | insansı, Mixamo | 20 | 65 kemik `mixamorig:*`; Godot'ta GeneralSkeleton'a eşlendi, animasyonlar çalışıyor | — | 170 | 2830 |

| 5 | 10.11.2026 | Hayalet/Savcı/Akbaba/Cevdet (ajan, metinden 3B) | Ana karakter | ajan durduruldu: kullanıcı referans sayfasından birebir üretimi istedi | 305 | yarım kaldı (son görev 41483f45, retopo 9796) | evet — referans görselden | 475 | 2525 |

**Yön değişti (10.11):** Ana karakterler artık kullanıcının verdiği tarzdaki **karakter referans sayfasından** (ön/yan/arka + yüz) görselden/çoklu görünümden 3B ile üretilecek. Stüdyo bakiyesi: 3170.

**Behzat entegre edildi:** `assets/generated/characters/behzat/behzat.glb` (18 947 üçgen, 4K PBR) · `data/characters.json` · hat: `TRIPO_STUDIO_PIPELINE.md`.

Not: ücretsiz görsel kuyruğu 15 dk ilerlemedi; görselden-3B yolu bu yüzden bırakıldı (0 kr harcandı).

**Test 1 dersi:** Metinden 3B, Tripo'nun "karakter" sınıflandırmasıyla stilize/karikatür oranlara kayıyor ("stylized" etiketi otomatik eklendi). Çözüm: önce ücretsiz görsel üretimiyle (Nano Banana 2, 100 ücretsiz hak) **fotogerçekçi referans**, sonra **görselden 3B** (55 kr). Dışa aktarmada poligon sınırı yok → üretimden sonra **Retopo** gerekiyor (maliyeti ölçülecek).

**Stüdyo fiyatları (gözlenen):** metinden/görselden 3B 55 kr · görsel üretimi 0 kr (ücretsiz kota) · Retopo, Rig: ölçülecek.

> **Kaynak değişti:** API bakiyesi 0 olduğu için üretim **tripo3d.ai web stüdyosundan** yapılıyor (stüdyo bakiyesi 3645). 950 sınırı stüdyo harcamasına uygulanıyor. Stüdyo fiyatı API'den farklı: metinden 3B = **55 kr** (API v3.1 tahmini 30 + rig). Plan buna göre güncellenecek.

## Engeller

1. **API bakiyesi 0.** 950 kredi web stüdyo aboneliğindeyse API'den kullanılamaz; platform bakiyesine yükleme gerekir. Kredi satın alma yetkim yok; kullanıcı onayı ve işlemi gerekir.
