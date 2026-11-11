# Godot Entegrasyonu

## İçe aktarma

- Tripo çıktısı GLB → `godot/assets/generated/<kategori>/<ad>/`. Tripo'nun CLI varsayılanı FBX'e çevirmek; **GLB istenecek** (`--then` zincirinden `convert` çıkarılır).
- `.glb.import`: `meshes/generate_lods=true`, `meshes/create_shadow_meshes=true`, karakterlerde `retarget/bone_map` = yeni `bonemap_tripo.tres` (ilk rigli Behzat'tan iskelet adları okunarak yazılacak).
- Ölçek: Tripo modelleri birim boyda gelir; içe aktarmadan sonra gerçek ölçüye (`ART_DIRECTION.md` ölçüleri) `set_base.local()` / `_prop()` `scale` parametresiyle oturtulur. Pivot: ayak/taban merkezi — gerekirse sarmalayıcı `Node3D` ile kaydırılır.
- `godot --headless --import` işini bitirip kapanmıyor; süreç elle sonlandırılır (bkz. proje hafızası).

## Karakterler

`character_rig.gd · _build()` model yolunu `data/characters.json · model`'dan okuyor. Tripo karakteri bu alana yazılır; iskelet adı `GeneralSkeleton` olduğu sürece animasyon, `PoseOverlay`, `FaceRig` (A seçeneğinde kırpmasız) ve boyun harmanlaması değişmeden çalışır. Melez (B) seçenekte `Styler.apply` Tripo kafasını gizleyip prosedürel kafayı takar (bugünkü `head_mesh.visible=false` mantığı; Tripo mesh'i kafa+gövde tek parça olduğu için **kafa bölgesinin ayrılması gerekir** — Godot'ta mesh bölmek mümkün ama zahmetli; Tripo `mesh_segment` ile ayrıştırma ayrıca kredi ister. Behzat testinde ölçülecek).

## Poligon bütçeleri

| Tür | Üçgen | Not |
|---|---:|---|
| Ana karakter | ≤ 40 000 | sorgu yakın çekimi |
| Büyük nesne (araç, tezgâh) | ≤ 10 000 | |
| Orta nesne (masa, lamba) | ≤ 8 000 | |
| Tekrarlanan modül (korkuluk, pencere) | ≤ 2 500 | yüzlerce kopya → `MultiMeshInstance3D` |

## Görünürlük

Tekrarlanan modüller `MultiMeshInstance3D`; uzak apartmanlar için LOD (içe aktarmadan otomatik) + `visibility_range_end`. Occlusion culling iç mekânlarda (`OccluderInstance3D`) — büro ve sorgu küçük olduğu için düşük öncelik.

## Collision

Tripo mesh'lerinden trimesh collision **üretilmeyecek** (pahalı ve gürültülü). Mevcut kutu engeller (`_block`, `_block_prop`) kullanılmaya devam eder.

## Godot'un yapamadıkları (açıkça)

- Tripo rig ağırlıklarını elle düzeltmek.
- Tek parça Tripo mesh'ini kafa/gövde diye temiz biçimde ayırmak (yalnız kodla kaba bölme).
- Tripo dokusundaki boyalı gözü ayrı göz küresine çevirmek (kırpma için gerekli).
