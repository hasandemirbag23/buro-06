# Ses ve model lisansları (hepsi CC0 / Public Domain)

| Dosya | Kaynak | Yazar | Lisans |
|---|---|---|---|
| `ambient/rain_loop.ogg` | [AMB Rain Loop 1](https://opengameart.org/content/amb-rain-loop-1) (OpenGameArt) | Kresiek the Furry | CC0 |
| `music/dark_place.ogg` | [Dark Place (loop)](https://opengameart.org/content/dark-place-loop) (OpenGameArt) | Skyle the French | CC0 |
| `music/hallway.ogg` | [Hallway](https://opengameart.org/content/hallway) (OpenGameArt) | thenewkgb | CC0 |
| `music/interrogation_drone.ogg` | [Ambient Horror Track 01](https://opengameart.org/content/ambient-horror-track-01) (OpenGameArt) | Cleyton Kauffman | CC0 |
| `sfx/footstep_*.ogg`, `sfx/impact*.ogg` | [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds) | Kenney | CC0 |
| `sfx/doorClose_1.ogg`, `sfx/cloth1.ogg`, `sfx/book*.ogg` | [Kenney RPG Audio](https://kenney.nl/assets/rpg-audio) | Kenney | CC0 |
| `sfx/open_001.ogg`, `sfx/close_001.ogg`, `sfx/click_001.ogg`, `sfx/confirmation_*.ogg`, `sfx/error_001.ogg`, `sfx/back_001.ogg` | [Kenney Interface Sounds](https://kenney.nl/assets/interface-sounds) | Kenney | CC0 |
| `../city/**` (modeller) | [Kenney City Kit: Commercial, Suburban, Roads](https://kenney.nl/assets/city-kit-commercial) | Kenney | CC0 |

CC0 lisansı atıf gerektirmez; yine de kaynaklar yukarıda belirtilmiştir.

## Ses düzeni

- Bus'lar: `Master` → `Music`, `Ambient`, `SFX`, `Voice` (`default_bus_layout.tres` yerine `autoload/audio.gd` çalışma anında kurar).
- Ses seviyeleri `user://settings.cfg` içinde saklanır (Ayarlar menüsünden değişir).
- Diyalog seslendirme: `assets/audio/voice/<dosya_id>/<düğüm_id>.ogg` dosyası varsa otomatik çalınır.
  Örnek: `voice/episode_01/zafer_start.ogg`. Dosya yoksa oyun sessiz devam eder.
