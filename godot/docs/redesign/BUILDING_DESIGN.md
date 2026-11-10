# Bina Tasarımı

## Neden binalar Tripo ile üretilmiyor

Tripo tek parça, oransal olarak serbest mesh üretir: kat yüksekliği sabit değildir, pencereler ızgaraya oturmaz, doku döşenmez ve iki parça yan yana koyulunca dikiş görünür. Apartman sırası kurmak için **kenetlenen modüller** gerekir. Bu yüzden:

- **Gövde (duvar, döşeme, kat çizgisi):** Godot'ta kodla (`set_base.gd` içine yeni `apartment()` yardımcısı), ölçüler sabit ızgarada.
- **Ayrıntı modülleri (balkon korkuluğu, pencere doğraması, kepenk, kapı, klima, doğalgaz kutusu):** Tripo ile **bir kez** üretilip yüzlerce kez tekrar kullanılır.

## Izgara

| Ölçü | Değer |
|---|---|
| Kat yüksekliği | 2,90 m |
| Pencere modülü genişliği | 1,20 m (ızgara 1,50 m) |
| Balkon derinliği | 1,10 m |
| Zemin kat (dükkân) | 3,60 m |
| Bina genişliği | 4–8 modül (6–12 m) |
| Kat sayısı | 4–8 |

## Apartman tipleri

| Tip | Dönem | Cephe | Balkon | Zemin | Kullanıldığı yer |
|---|---|---|---|---|---|
| A — Cebeci | 1970'ler | bej sıva, kat bantları beton | kapalı (camlı) + açık demir | apartman girişi + bodrum penceresi | 02, menü |
| B — Bahçelievler | 1980'ler | somon/kiremit sıva | açık, demir korkuluk | dükkân (kepenk, tabela) | 04 |
| C — Maltepe iş hanı | 1970'ler | mozaik/fayans kaplama, bant pencere | yok | dükkân sırası, neon | 03 |
| D — Ulus kamu | 1930–50'ler | taş kaplama, simetrik, yüksek pencere | yok | basamaklı giriş | 05 |
| E — Vadi kule | 2020'ler | cam giydirme + beton çekirdek (şantiye: çıplak beton) | — | şantiye çiti | 01 |

## Kahraman binalar (ayrı tasarlanır)

- **Emniyet binası (büro dış görünüşü, ileride):** D tipinin modern versiyonu, logosuz "POLİS" yazısı.
- **Geceler Gazinosu cephesi:** C tipi + neon "GECELER GAZİNOSU".
- **Nermin Eczanesi:** B tipi + eczane tabelası, nöbetçi eczane levhası.

## Tripo'ya gidecek bina modülleri

Liste ve kredi: `SCENARIO_ASSETS.md` § Mimari modüller.
