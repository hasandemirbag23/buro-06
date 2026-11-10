# İkincil Karakterler — Ekonomik Tasarım

Yol: prosedürel kafa (`tools/headgen`, 0 kredi) + gövde + Godot kumaş malzemeleri (`character_styler.cloth_material`). Yüz animasyonu (kırpma, konuşma, ifade) bu yolda zaten çalışıyor.

Bilgiler senaryo verisinden (`episode_*.json`, `character_templates.json · _ref`) alındı; tahmin yok, belirsiz olanlar işaretli.

| Karakter | Bölüm / rol | Yaş (veri) | Ayırt edici görünüm | Kıyafet & palet | Yapılacak |
|---|---|---|---|---|---|
| Player — Komiser | oyuncu | 31 | geniş yuvarlak alt çene, açık bakış, kısa koyu kahve saç | koyu takım, siyah gömlek | kafa iyileştirildi (8058972); gövde/kontrol **değişmez** |
| Ayşe — Arşiv | büro | 58 | yuvarlak yüz, göz kenarı kırışıkları, gri topuz, gözlük | bej hırka, kahve etek | topuz küre yerine örgü kütle; kafa ok |
| Tarık Soylu | 01 inşaat patronu | 48 | geniş kısa kafa, dolgun yanak, çift çene, geriye taranmış saç, şakakta beyaz | lacivert takım, altın kravat, altın saat | kafa yenilendi; gövde: takım kumaşı |
| Zafer Yılmaz | 01 şantiye şefi | (veride yok) | kalın bıyık, kâse saç, sert kaşlar | sarı baret, reflektörlü yelek, haki iş pantolonu | baret ve yelek nesne olarak |
| Mert Aksoy | 02 asistan | (veride yok) | genç, ince yüz, tedirgin kaşlar | gri kazak, gömlek yakası, kot | kafa ok |
| Prof. Dr. Haldun Erk | 02 profesör | (veride yok) | ince yüz, gri keçi sakal, gözlük | tüvit ceket, kravat | sakal kontrolü |
| Nevzat Şahin | 03 muhasebeci | (veride yok) | seyrek saç, gözlük, yorgun | kahve takım, ince kravat | kafa ok |
| İdris | 03 pavyon sahibi | (veride yok) | kalın bıyık, ağır kaş, geriye jöleli saç | siyah gömlek açık yaka, altın zincir, altın saat | aksesuar ok |
| **Rıza Koç** | 04 kocası | — | **kafa yok** | gövde SITE_CHIEF | yeni şablon + `skin_*` yok → varsayılan heykel; şablonla ayrıştırılacak |
| **Selim Baran** | 04 ilaç deposu sahibi | — | **kafa yok** | CRIMINAL_BOSS | yeni şablon |
| **Yavuz Erten** | 05 polis | — | **kafa yok** | POLICE | yeni şablon |
| **Adil Korkmaz** | 05 kulüp sahibi | — | **kafa yok** | CRIMINAL_BOSS | yeni şablon |

## Eksik dört şüpheli için ilke

Varsayılan heykel fonksiyonu (`Head._sculpt` sonundaki genel yol) şablon parametreleriyle çalışıyor; yeni `skin_<id>` yazmadan, yalnız `character_templates.json`'a farklı parametreler girilerek dört ayrı yüz elde edilebilir. Yaş ve kişilik verisi senaryoda yok — sorgu repliklerinden çıkarılan izlenimle (Rıza: yorgun orta yaş; Selim: bakımlı tüccar; Yavuz: sert meslektaş; Adil: gösterişli gece kulübü sahibi) şablon yazılacak ve kullanıcıya sunulacak.

## Tripo kullanımı (ikincil)

Kafa üretimi yok. Yalnız ayırt edici **aksesuarlar** Tripo'dan gelebilir (baret, reflektörlü yelek, altın saat) — bunlar `SCENARIO_ASSETS.md` içinde senaryo nesnesi olarak sayıldı.
