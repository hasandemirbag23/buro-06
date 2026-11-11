# Tripo API rig çıktısını glTF yönüne çevirir: kök Armature düğümüne -90° Y dönüşü.
# Tripo rig GLB +X yönüne bakar; düzeltilmezse Godot fix_silhouette başı yana/yukarı döndürür.
# Kullanım: python3 face_z.py <karakter.glb>   (dosyayı yerinde değiştirir; iki kez çalıştırma — betik engeller)
import json,struct,sys,math
p=sys.argv[1]
b=open(p,'rb').read(); L=struct.unpack('<I',b[12:16])[0]; j=json.loads(b[20:20+L]); rest=b[20+L:]
sc=j['scenes'][j.get('scene',0)]
assert len(sc['nodes'])==1 and j['nodes'][sc['nodes'][0]]['name']=='Armature', sc
n=j['nodes'][sc['nodes'][0]]
assert 'rotation' not in n and 'matrix' not in n, n
h=math.sqrt(0.5)
n['rotation']=[0.0,-h,0.0,h]   # -90° Y: Tripo +X yüzünü glTF +Z'ye çevirir
js=json.dumps(j,separators=(',',':')).encode(); js+=b' '*((-len(js))%4)
out=struct.pack('<III',0x46546C67,2,12+8+len(js)+len(rest))+struct.pack('<I',len(js))+b'JSON'+js+rest
open(p,'wb').write(out); print('ok',p)
