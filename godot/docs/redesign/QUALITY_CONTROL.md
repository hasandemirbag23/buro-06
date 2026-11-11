# Kalite Kontrol

## Her Tripo varlığı için

- [ ] Prompt, negatif prompt, task_id, kredi `TRIPO_CREDIT_TRACKER.md`'ye yazıldı
- [ ] Önizleme (`tripo view <task>`) — oran, eksik parça, erimiş geometri yok
- [ ] Üçgen sayısı bütçe içinde (`GODOT_INTEGRATION.md`)
- [ ] GLB içe aktarıldı, ölçek ve pivot doğru, doku yolu kırık değil
- [ ] Sahne malzemeleriyle renk/pürüzlülük uyumu (yan yana render)
- [ ] Başarısızsa: neden yazıldı, prompt düzeltildi, **aynı prompt tekrar gönderilmedi**

## Ana karakter ek kontrolleri

- [ ] Siluet testi (siyah dolgu) diğer ana karakterlerden ayırt ediliyor
- [ ] `Cam_SuspectCloseUp` yakın çekiminde yüz okunuyor
- [ ] Rig: `GeneralSkeleton` eşleşti; Idle, Walk, Sitting_Idle, Idle_Talking'de omuz/dirsek/diz kırılmıyor
- [ ] `PoseOverlay` aksiyonları (Thinking, Angry, Confession) bozuk poz üretmiyor
- [ ] Ölçek: kapı (2,05 m) ve masa (0,75 m) ile tutarlı

## Sahne kontrolleri

- [ ] `tests/characters_test` → SONUC TAMAM
- [ ] `tests/episodes_test` → EPISODES_OK
- [ ] `tests/scene_test` → SCENE_OK, engel/hotspot sayıları değişmedi
- [ ] Gece / akşam / iç ışık senaryosu render karşılaştırması
- [ ] Kare süresi ölçümü (önce/sonra)
