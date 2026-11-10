# Sokak ve Yol Tasarımı

Hepsi Godot'ta prosedürel (`set_base.gd · road(), sidewalk()` genişletilecek), PBR malzemeyle.

| Öğe | Ölçü | Malzeme | Ayrıntı |
|---|---|---|---|
| Asfalt şerit | 3,5 m / şerit | `asphalt_worn` | yama ve çatlak maskesi, ıslak birikinti maskesi (gece) |
| Yol çizgisi | 0,15 m | beyaz boya, aşınmış | kesik orta çizgi; yaya geçidi zebra |
| Beton bordür | 0,15 × 0,25 m | `concrete_curb` | dibinde koyulaşma |
| Kaldırım | 2–3,5 m | `paving_stone` (Ankara tipi gri kilitli parke) | bordüre doğru eğim yok (basit) |
| Rögar kapağı | Ø 0,6 m | dökme demir dokusu (disk) | yolda her 25 m |
| Yağmur ızgarası | 0,4 × 0,8 m | demir | bordür dibinde |
| Sokak tabelası | 0,6 × 0,2 m | mavi zemin beyaz yazı | `Label3D`, Türkçe karakter (Öveç Sokak, 4. Cadde…) |
| Apartman numarası | 0,25 m | mavi emaye | kapı yanında |
| Trafik levhası | Ø 0,6 m | Türkiye levha dili (DUR, park yasağı) | yazısız sembol + "DUR" |

Tripo'dan gelen sokak eşyası: S1 lamba, S3 konteyner, S4 durak, S5/S6 araçlar.

Kirlilik: hafif — sigara izmariti/yaprak decal'ları, bordürde çamur, duvar dibinde yağmur izi. Harabe yok.
