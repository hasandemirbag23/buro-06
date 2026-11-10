# Ana Karakterler

Her karakter için: tasarım özeti · Tripo promptu (İngilizce; Tripo İngilizce promptla daha iyi sonuç veriyor) · negatif prompt · ayarlar · kabul ölçütü.

Ortak ayar: `model=v3.1`, `texture_quality=detailed` (30 kr) + `geometry_quality=detailed` (+20 kr) = **50 kr**; ardından rig (maliyet ölçülecek, plan değeri 25 kr — bkz. kredi takibi). Ortak negatif prompt: `cartoon, anime, chibi, toy, plastic, exaggerated proportions, fantasy armor, weapon in hand, text, logo, extra limbs, T-pose`.

Ortak prompt eki: `full body, standing in A-pose, arms 45 degrees from body, feet on ground, realistic human proportions, stylized realism, game character, clean topology, neutral lighting`.

---

## 1. Behzat — Başkomiser

**Özet:** 42–50 yaş, ~180 cm, zayıf-kemikli, hafif kambur. Uzun köşeli yüz, çökük yanak, belirgin elmacık, köşeli çene, kalın hafif çatık kaşlar, derin yerleşimli koyu gözler, ağır üst kapaklar, göz altı yorgunluğu, hafif kemerli burun, belirgin asimetri. Dağınık orta boy koyu kahve saç, kalın koyu bıyık (ortada yoğun, uçlara incelen, hafif aşağı), kirli sakal. Eskimiş siyah deri ceket, koyu gömlek, koyu pantolon, sade kemer, eskimiş koyu deri bot.

**Prompt:** `Turkish police chief inspector, man aged 47, lean bony build, slightly hunched shoulders, long angular face, hollow cheeks, prominent cheekbones, angular jaw, thick slightly frowning eyebrows, deep-set dark tired eyes with heavy upper eyelids and dark circles, slightly hooked nose, asymmetric weathered face with forehead lines, messy medium-length dark brown hair, thick dark brown-black mustache following the upper lip and thinning at the drooping ends, three-day stubble, worn cracked black leather jacket, dark charcoal shirt, dark trousers, plain belt, scuffed dark leather boots` + ortak ek.

**Kabul:** Bıyık normal kamerada ayrı kıl kütlesi olarak okunuyor; ceket deri gibi parlıyor/kırışıyor; yüzde yorgunluk var; rig sonrası omuz ve dirsek kırılmıyor.

## 2. Hayalet — İstihbarat

**Özet:** Yetişkin erkek, Behzat'tan uzun ve ince. Dar çene, ince uzun yüz, belirgin göz çevresi, sessiz gözlemci bakış. Koyu saç, kısa düzgün sakal (bugünkü kafayla uyumlu: gür kara sakal). Kontrollü duruş. Siyah/antrasit/koyu gri: koyu kapüşonlu sweat üstüne antrasit mont, koyu kot, koyu spor ayakkabı.

**Prompt:** `Turkish plainclothes intelligence officer, man aged 34, tall and slender, long narrow face, narrow pointed chin, sunken cheeks, deep-set watchful dark eyes, calm reserved expression, short dark swept-back hair, full short black beard, dark charcoal hooded sweatshirt under an anthracite bomber jacket, dark jeans, black sneakers, controlled upright posture` + ortak ek.

**Kabul:** Siluette Behzat'la karışmıyor (uzun-ince, deri ceket yok, bıyık-sakal farklı).

## 3. Akbaba — Olay Yeri İnceleme

> **Onay bekliyor:** Oyunda Akbaba kadın (`female: true`, kadın sesi/hitap). Prompt erkek diyor. İki tasarım hazır; kullanıcı seçecek. Varsayılan: **oyundaki hâliyle kadın** (senaryoyu bozmamak için).

**Özet (kadın, mevcut):** 42 yaş, kemikli keskin yüz, kısa toplu saç, odaklı bakış. Lacivert olay yeri tulumu, beyaz/gri yelek, mavi nitril eldiven, boyunda fotoğraf makinesi.

**Prompt (kadın):** `Turkish forensic crime scene investigator, woman aged 42, sharp bony face, focused narrow eyes, short tied-back dark hair, no makeup, navy blue forensic coverall, light grey utility vest with pockets, blue nitrile gloves, DSLR camera on a strap around the neck, practical black work shoes` + ortak ek.

**Prompt (erkek, alternatif):** `Turkish forensic crime scene investigator, man aged 45, broad flat face, wide nose, small sharp eyes behind thin glasses, receding short grey-black hair, clean shaven, navy forensic coverall, grey utility vest, blue nitrile gloves, DSLR camera on a strap` + ortak ek.

## 4. Savcı — Nilgün Erdem

**Özet:** 30–40 yaş kadın, doğal anatomi, belirgin ama abartısız elmacık, kendinden emin bakış, düzenli koyu kahve saç (omuz hizası küt veya topuz), sade makyaj, ince çerçeveli gözlük (bugünkü kafada var). Koyu blazer, sade krem bluz, kumaş pantolon, sade topuksuz ayakkabı, minimal aksesuar (saat).

**Prompt:** `Turkish public prosecutor, woman aged 38, natural realistic female anatomy, defined but subtle cheekbones, confident serious gaze, thin round metal glasses, neat shoulder-length dark brown bob hair, minimal makeup, dark navy tailored blazer, plain cream blouse, dark straight trousers, simple low-heel black shoes, slim wristwatch, upright professional posture` + ortak ek.

**Kabul:** Abartılı vücut oranı, ağır makyaj yok; gözlük çerçevesi kırık/erimiş değil (Tripo'da ince çerçeve riskli → kötü çıkarsa gözlüksüz üretilip Godot'taki gözlük nesnesi takılır, `character_styler._glasses`).

## 5. Cevdet — Genç Komiser

> **Oyunda yok.** Model tasarlanıp üretilebilir, ama görünmesi için bir bölüme yazılması gerekir. Önerim: sorgu ve büro sahnelerinde Behzat'ın yanında ikinci komiser olarak; senaryo işi ayrıca planlanmalı.

**Özet:** Genç yetişkin (27–30), düzenli yüz, az yaş çizgisi, orantılı çene, dinç görünüm, düzenli kısa saç, temiz tıraş. Koyu lacivert kısa mont, açık mavi gömlek, koyu pantolon, koyu günlük ayakkabı, belde rozet.

**Prompt:** `Turkish young police detective, man aged 28, fit athletic build, regular symmetrical face, proportional jaw, alert clear eyes, neat short dark hair with a side part, clean shaven, dark navy short padded jacket, light blue shirt, dark trousers, dark casual leather shoes, police badge clipped on the belt, confident straight posture` + ortak ek.

**Kabul:** Behzat'ın deri ceketi ve bıyığından tamamen ayrı; yüzden yaş farkı okunuyor.
