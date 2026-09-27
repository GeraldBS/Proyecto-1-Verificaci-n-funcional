#!/bin/bash
# corrida completa: compila, corre la prueba general y la de esquina,
# y saca el histograma. Los resultados quedan en sim/
#
# uso:
#   ./scripts/run.sh           -> pckg_sz al azar entre 16, 32 y 64
#   ./scripts/run.sh 32 8      -> pckg_sz=32, drvrs=8

cd "$(dirname "$0")/.." || exit 1
RAIZ=$(pwd)

PCKG_SZ=${1:-$(shuf -n1 -e 16 32 64)}
DRVRS=${2:-4}

bash scripts/correr.sh tb_top $PCKG_SZ $DRVRS || exit 1

cd sim || exit 1

# la corrida general deja su csv, se guarda antes de la de esquina
cp reporte.csv reporte_general.csv 2>/dev/null

echo
echo "== casos de esquina =="
./salida +prueba=corner -l sim_corner.log || exit 1
cp reporte.csv reporte_corner.csv 2>/dev/null

echo
echo "== corrida larga para el histograma =="
./salida +min_trans=40 +max_trans=110 +max_delay=15 -l sim_largo.log || exit 1

if command -v gnuplot > /dev/null; then
  gnuplot -e "archivo='reporte.csv'" ../scripts/plot_histograma.gnu
  echo "histograma en sim/histograma.png"
else
  echo "gnuplot no esta disponible, no se genero el histograma"
fi

echo
echo "listo. en sim/ quedaron:"
ls -1 reporte*.csv histograma.png 2>/dev/null
