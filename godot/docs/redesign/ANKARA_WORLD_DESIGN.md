# Ankara Dünya Tasarımı

Kaynak: Ankara kent dokusu bilgisi (Kızılay, Ulus, Cebeci, Maltepe, Bahçelievler, Çankaya/Vadi). Bu belge için ayrıca web görsel araştırması yapılmadı; referans fotoğraf seti toplu üretimden önce kullanıcıyla birlikte netleştirilmeli.

## Semt kimlikleri (senaryodaki gerçek yerler)

| Semt | Bölüm | Doku | Belirleyici öğeler |
|---|---|---|---|
| **Vadi / Çankaya** | 01 | Yeni cam-beton kuleler, şantiye, geniş yollar | vinç, iskele, şantiye panosu ("YAPI RUHSATI" levhası), beton mikseri, sodyum + LED karışık ışık |
| **Cebeci** | 02 | 70–80'ler 4–6 katlı betonarme apartmanlar, öğrenci evleri, dar sokak | bej/somon sıva, demir balkon korkulukları, alüminyum doğrama, apartman adı levhası, kapı önü paspas, doğalgaz kutusu |
| **Maltepe** | 03 | İş hanları, gece kulübü/gazino cepheleri, otopark | neon tabela (Türkçe), kepenk, yan sokakta park araçlar |
| **Bahçelievler 7. Cadde çevresi / 4. Cadde** | 04 | Orta sınıf cadde, alt katı dükkân apartmanlar | eczane tabelası (beyaz zemin kırmızı E), ağaçlı kaldırım, market/fırın |
| **Ulus** | 05 | Eski Ankara, kamu binaları, belediye tesisleri | taş kaplamalı eski kamu binası, zabıta otoparkı bariyeri, eski iş hanı |

## Sokak bileşen kiti (modüler, tüm setlerde ortak)

Ayrıntı: `STREET_AND_ROAD_DESIGN.md`, `BUILDING_DESIGN.md`.

1. **Apartman modülü** = zemin kat (dükkân veya giriş) + N × normal kat + çatı/korkuluk. Godot'ta kodla dizilir; cephe malzemesi, pencere düzeni, balkon tipi rastgele ama tohumlu.
2. **Kaldırım + bordür + asfalt şeridi** — Godot'ta prosedürel, PBR malzemeli.
3. **Sokak eşyası** — Tripo ile üretilir, sahnelere dağıtılır: sokak lambası, elektrik direği, belediye çöp konteyneri, bank, otobüs durağı, rögar.
4. **Tabela sistemi** — Godot `Label3D`/doku; Türkçe metin veriden gelir (sokak adı, apartman no, dükkân adı). Tripo tabela üretmez (yazıları bozuk çıkar).

## Atmosfer

Gece sahnelerinde sodyum lambalarının altında ışık havuzları, aralarda gece mavisi; apartman pencerelerinin ~%30'u yanık (sıcak/soğuk karışık); asfaltta ıslak yansıma (pürüzlülük haritasında su birikintisi maskesi); ufukta hafif pus ve şehir parıltısı. Her sahne karanlık değil: 04 akşamüstü, büro gündüz floresanı.

## Ana menü silüeti

Kenney gökdelenleri yerine: ön planda Cebeci tipi apartman sırası, arkada Kızılay iş merkezi kütleleri, en arkada Atakule benzeri **özgün** bir kule silüeti (gerçek yapının birebir kopyası değil).
