# Senaryo ve Çevre Varlıkları — Üretim Listesi

Fiyatlar Tripo v3.1 resmi tarifesinden (bkz. `TRIPO_CREDIT_TRACKER.md`): metinden 3B standart doku **20**, detaylı doku **30**. Tekrarlanan nesnelerde `face_limit` ile poligon sınırlanır (ek ücret yok).

Seçim kuralı: senaryoda **görülen** ve en az bir sahnede kullanılan nesne. Arka planda kalan, kutuyla temsil edilebilen veya Godot'ta yazıyla/dokuyla yapılabilen şey Tripo'ya gitmez.

## Ortak (her bölümde görünen) — öncelik 1

| # | Varlık | Nerede | Doku | Kredi | face_limit |
|---|---|---|---|---:|---:|
| B1 | Eski ahşap kaplama ofis masası | büro (×6) | detaylı | 30 | 8 000 |
| B2 | 4 çekmeceli metal dosya dolabı | büro, eczane | std | 20 | 4 000 |
| B3 | 2000'ler masaüstü bilgisayar + klavye | büro | std | 20 | 5 000 |
| B6 | İnce belli çay bardağı, tabak, çaydanlık seti | büro, sorgu (Behzat'ın çayı) | std | 20 | 3 000 |
| Q1 | Vidalı metal sorgu masası | sorgu | std | 20 | 4 000 |
| Q2 | Metal sorgu sandalyesi | sorgu (×3) | std | 20 | 3 000 |
| N1 | Şeffaf delil torbası (etiketli boş alan) | tüm bölümler, delil düşürme | std | 20 | 2 000 |
| N3 | Ekranı çatlak akıllı telefon | 5 bölüm "maktulün telefonu" | std | 20 | 3 000 |
| C1 | Branda altında ceset kütlesi | 5 bölüm olay yeri | std | 20 | 6 000 |

## Sokak ve mimari modüller — öncelik 2

| # | Varlık | Kullanım | Doku | Kredi | face_limit |
|---|---|---|---|---:|---:|
| M1 | Demir balkon korkuluğu modülü (1,2 m) | tüm apartmanlar | std | 20 | 2 500 |
| M2 | Alüminyum pencere + plastik panjur | tüm apartmanlar | std | 20 | 2 500 |
| M3 | Kepenkli dükkân cephesi (tabelasız) | 03, 04, sokaklar | detaylı | 30 | 6 000 |
| M4 | Apartman giriş kapısı (demir + cam) + saçak | 02, sokaklar | std | 20 | 4 000 |
| S1 | Ankara tipi çift kollu sokak lambası | tüm dış sahneler | std | 20 | 3 000 |
| S3 | Belediye çöp konteyneri (tekerlekli, logosuz) | tüm dış sahneler | std | 20 | 3 000 |
| S4 | Otobüs durağı (cam + metal) | 04, menü | detaylı | 30 | 6 000 |
| S5 | 90'lar Türk tipi sedan (markasız) | park araçlar | detaylı | 30 | 10 000 |
| S6 | Beyaz-lacivert polis aracı (logosuz, "POLİS" yazısı Godot'ta) | 5 olay yeri | detaylı | 30 | 10 000 |

## Bölüme özgü kahraman varlıklar — öncelik 3

| # | Varlık | Bölüm | Doku | Kredi |
|---|---|---|---|---:|
| T1 | Şantiye iskele modülü (boru + tahta) | 01 | detaylı | 30 |
| T2 | Sarı baret + reflektörlü yelek | 01 (Zafer) | std | 20 |
| F1 | Doğalgaz ocağı + sarı hortum | 02 (kesik hortum delili) | std | 20 |
| F2 | 70'ler üçlü koltuk + sehpa | 02 | detaylı | 30 |
| P1 | Gazino masası + sandalye seti | 03 | std | 20 |
| E1 | Eczane tezgâhı + ilaç rafı | 04 | detaylı | 30 |
| G1 | Belediye zabıta vanı (logosuz) | 05 | detaylı | 30 |

**Çevre toplamı: 590 kredi** (27 varlık).

## Tripo'ya gitmeyenler (Godot'ta yapılacak)

Bina gövdeleri, kaldırım, bordür, asfalt, yol çizgisi, rögar (doku + disk), elektrik direği (silindir + doku), floresan armatür (kutu + emisyon), mantar pano ve delil iplikleri (düzlem + `Label3D`), dosya/klasör yığınları (kutu + doku), tüm Türkçe tabelalar (`Label3D` + malzeme), duvar saati, halı, perde (mevcut kit), arşiv rafları (mevcut `Shelf_Large`).

Elenenler ve gerekçe: klima dış ünitesi (arka plan, kutuyla yeterli), ofis koltuğu (Kenney `chairDesk` kabul edilebilir), elektrik direği (silindir), floresan (emisyonlu kutu), arşiv odası (oyunda ayrı sahne değil).
