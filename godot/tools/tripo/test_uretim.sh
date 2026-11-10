#!/bin/zsh
# AŞAMA 6 test üretimi: Behzat (ana karakter) + demir balkon korkuluğu (çevre modülü).
# Plan: 30 (Behzat, v3.1 detaylı doku) + rig (ölçülecek, plan 25) + 20 (balkon) = ~75 kredi.
# Bakiye yetmezse hiçbir şey göndermez. Kredi satın almaz.
set -euo pipefail
cd "${0:A:h}/../.."   # godot/
OUT=assets/generated
NEED=75

bal=$(tripo balance --json | python3 -c "import json,sys; print(int(json.load(sys.stdin)['balance']))")
echo "API bakiyesi: $bal kredi (gereken ~$NEED)"
if (( bal < NEED )); then
  echo "Bakiye yetersiz; üretim yapılmadı."; exit 1
fi

NEG="cartoon, anime, chibi, toy, plastic, exaggerated proportions, weapon, text, logo, extra limbs, T-pose"

tripo make "Turkish police chief inspector, man aged 47, lean bony build, slightly hunched shoulders, long angular face, hollow cheeks, prominent cheekbones, angular jaw, thick slightly frowning eyebrows, deep-set dark tired eyes with heavy upper eyelids and dark circles, slightly hooked nose, asymmetric weathered face with forehead lines, messy medium-length dark brown hair, thick dark brown-black mustache following the upper lip and thinning at the drooping ends, three-day stubble, worn cracked black leather jacket, dark charcoal shirt, dark trousers, plain belt, scuffed dark leather boots, full body, standing in A-pose, arms 45 degrees from body, feet on ground, realistic human proportions, stylized realism, game character" \
  --model tripo-v3.1 -p texture_quality=detailed -p "negative_prompt=$NEG" \
  --then rig --name behzat_test -o "$OUT/characters/behzat_test" --no-open --yes

tripo make "single wrought iron balcony railing module for an old 1970s Ankara apartment, 1.2 meters wide, simple vertical bars with a flat top rail, painted dark grey with light rust at the joints, realistic game asset, isolated object" \
  --model tripo-v3.1 -p face_limit=2500 -p "negative_prompt=$NEG" \
  --name balkon_korkuluk -o "$OUT/street/balkon_korkuluk" --no-open --yes

echo "--- gerçek harcama ---"
tripo usage --json | head -c 1500
