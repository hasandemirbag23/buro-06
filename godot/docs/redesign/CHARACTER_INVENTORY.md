# Karakter Envanteri

Kaynak: `data/episode_0[1-5].json`, `data/character_templates.json`, `data/characters.json`.
"Kafa" = `assets/heads/<id>_*` (SDF heykel). "Gövde" = Quaternius CC0 modeli.

## Ana ekip (her bölümde)

| id | Oyundaki adı | Rol | Görüldüğü yer | Kafa | Gövde | Plan kademesi |
|---|---|---|---|---|---|---|
| behzat | Başkomiser Behzat | Ekip amiri, sorguda yanında | büro, olay yeri, sorgu | var | man_Casual2 | **Ana** |
| hayalet | Hayalet | İstihbarat | büro, olay yeri | var | man_Casual | **Ana** |
| akbaba | Akbaba | Olay yeri inceleme, kamera | olay yeri (her bölüm açılış repliği) | var | woman_Worker | **Ana** |
| savci | Savcı Nilgün Erdem | Soruşturma savcısı | büro, telefon | var | woman_Suit | **Ana** |
| — | **Cevdet** | Kullanıcının istediği ana karakter | **oyunda yok** | yok | yok | **Ana (yeni)** |
| player | Komiser (oyuncu) | Oyuncu karakteri | her yer | var | man_Suit | İkincil, kontrol uyumu korunur |
| arsiv | Ayşe | Arşiv / e-sorgu | büro | var | woman_Formal | İkincil |

> **Akbaba notu:** Mevcut verilerde Akbaba **kadın** bir olay yeri uzmanı (`woman_Worker`, şablonda `female: true`) olarak tanımlı. Tasarım promptu "Erkek, yetişkin" diyor. Bu bir çelişki; değiştirmek tüm bölümlerdeki replik ve hitapları etkileyebilir. Kullanıcı onayı bekleniyor (bkz. `DEVELOPMENT_PROGRESS.md`).

## Şüpheliler (bölüme özgü)

| id | Adı | Bölüm | Rol | Kafa | Plan kademesi |
|---|---|---|---|---|---|
| zafer | Zafer Yılmaz | 01 | Şantiye şefi, baretli | var | İkincil |
| tarik | Tarık Soylu | 01 | İnşaat patronu, altın saat | var | İkincil |
| mert | Mert Aksoy | 02 | Asistan | var | İkincil |
| haldun | Prof. Dr. Haldun Erk | 02 | Hukuk profesörü | var | İkincil |
| nevzat | Nevzat Şahin | 03 | Pavyon muhasebecisi | var | İkincil |
| idris | İdris | 03 | Pavyon sahibi, altın saat | var | İkincil |
| riza | Rıza Koç | 04 | Eczacının kocası (SITE_CHIEF gövdesi) | **yok** | İkincil (eksik) |
| selim | Selim Baran | 04 | İlaç deposu sahibi | **yok** | İkincil (eksik) |
| yavuz | Yavuz Erten | 05 | Polis (POLICE gövdesi) | **yok** | İkincil (eksik) |
| adil | Adil Korkmaz | 05 | Kulüp sahibi | **yok** | İkincil (eksik) |

## Yalnız metinde geçenler (model gerekmez)

Kurbanlar (Emre Karaca, Selin Aydın, Gonca Demir, Nermin Koç, Kemal Sönmez) sahnede **ceset olarak** görünüyor (`crime_scene_3d.gd`, branda altında). Tanıklar (nöbetçi, kapıcı, komşu, barmen, garaj bekçisi…) yalnız ifade metni olarak var.

**Karar:** Kurbanlar için tek bir ortak, yüzü görünmeyen ceset modeli yeterli (branda altında). Tanıklar için model üretilmeyecek.
