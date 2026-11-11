# Çevre Tasarımı — Yaklaşım

| Katman | Araç | Belge |
|---|---|---|
| Şehir kimliği, semtler | — | `ANKARA_WORLD_DESIGN.md` |
| Bina gövdeleri (modüler ızgara) | Godot kod | `BUILDING_DESIGN.md` |
| Sokak, yol, kaldırım | Godot kod + PBR | `STREET_AND_ROAD_DESIGN.md` |
| İç mekânlar | Godot + Tripo nesneler | `INTERIOR_DESIGN.md` |
| Nesneler, sokak eşyası, araçlar | Tripo | `SCENARIO_ASSETS.md` |
| Malzemeler | Godot | `MATERIAL_LIBRARY.md` |

## Uygulama sırası (her set aynı kalıpla)

1. `set_base.gd`'ye yeni yardımcılar: `apartment(tip, genişlik, kat, tohum)`, `storefront()`, `street_sign(ad)`, `building_number(no)`. Kenney `city()` çağrıları bunlarla değiştirilir — **önce yedek** (`*.gd.bak` değil, git dalı).
2. Sokak şeridi (kaldırım + bordür + asfalt) PBR malzemeyle.
3. Tripo nesneleri yerleştirilir (lamba, konteyner, araçlar).
4. Işık senaryosu (`ART_DIRECTION.md`).
5. `tests/scene_test` hotspot ve engel sayıları değişmeden geçmeli (bugün: 72 / 28 / 15 / 13 / 11 engel).

Hotspot konumları, kamera işaretleri ve engel (collision) kutuları korunur; yeni görsel geometri bunların üstüne oturur.
