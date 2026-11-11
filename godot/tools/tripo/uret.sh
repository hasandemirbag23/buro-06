#!/bin/zsh
# Tripo API üretimi + bütçe defteri.
# Kullanım:
#   uret.sh <id> <kategori> <tahmini_kredi> <tripo make argümanları...>
# Örnek:
#   uret.sh sokak_lambasi street 30 "Ankara street lamp ..." --model tripo-v3.1 -p face_limit=3000
# Çıktı: godot/assets/generated/<kategori>/<id>/  ·  defter: tools/tripo/ledger.csv
# Sınır: API toplamı 950 krediyi aşacaksa hiçbir şey göndermez. Kredi satın almaz.
set -euo pipefail
LIMIT=950
HERE=${0:A:h}
GODOT=${HERE:h:h}
LEDGER=$HERE/ledger.csv
[[ -f $LEDGER ]] || echo "tarih,id,kategori,tahmin,gercek,bakiye_once,bakiye_sonra,task,durum" > $LEDGER

id=$1; cat=$2; est=$3; shift 3
spent=$(awk -F, 'NR>1 && $5!="" {s+=$5} END {print s+0}' $LEDGER)
if (( spent + est > LIMIT )); then
  echo "BUTCE: harcanan $spent + tahmin $est > $LIMIT. Gönderilmedi."; exit 2
fi
bal() { tripo balance --json | python3 -c "import json,sys; print(int(json.load(sys.stdin)['balance']))"; }
b0=$(bal)
(( b0 >= est )) || { echo "Bakiye yetersiz ($b0 < $est)."; exit 3; }

out=$GODOT/assets/generated/$cat/$id
mkdir -p $out
log=$out/tripo_make.json
set +e
tripo make "$@" -o $out --name $id --no-open --yes --json > $log 2> $out/tripo_make.err
rc=$?
set -e
b1=$(bal)
real=$(( b0 - b1 ))
task=$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('task_id') or (d.get('tasks') or [{}])[-1].get('task_id',''))" $log 2>/dev/null || echo "")
state=$([[ $rc == 0 ]] && echo ok || echo "hata$rc")
echo "$(date +%F_%H:%M),$id,$cat,$est,$real,$b0,$b1,$task,$state" >> $LEDGER
echo "$id: $state · gerçek $real kr · bakiye $b1 · toplam $(( spent + real ))/$LIMIT"
ls $out | grep -iE "\.(glb|png|jpg|webp)$" || true
