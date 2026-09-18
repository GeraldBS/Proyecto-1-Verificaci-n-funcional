#!/bin/bash
# compila y corre una prueba en vcs
# uso:
#   ./scripts/correr.sh prueba_humo            -> pckg_sz al azar, drvrs=4
#   ./scripts/correr.sh prueba_driver 32       -> pckg_sz=32
#   ./scripts/correr.sh prueba_driver 64 8     -> pckg_sz=64, drvrs=8
#
# el tamano del paquete se escoge aqui, antes de compilar

CFG=/mnt/vol_NFS_rh003/estudiantes/archivos_config/synopsys_tools2.sh
if [ -f "$CFG" ]; then
  source "$CFG"
else
  echo "aviso: no se encontro $CFG"
  echo "si vcs no esta cargado, corra el source a mano"
fi

cd "$(dirname "$0")/.." || exit 1
RAIZ=$(pwd)

PRUEBA=${1:-prueba_humo}
PCKG_SZ=${2:-$(shuf -n1 -e 16 32 64)}
DRVRS=${3:-4}

if [ ! -f "tests/$PRUEBA.sv" ]; then
  echo "error: no existe tests/$PRUEBA.sv"
  echo "pruebas disponibles:"
  ls tests/*.sv 2>/dev/null
  exit 1
fi

mkdir -p sim && cd sim || exit 1
echo "== $PRUEBA con PCKG_SZ=$PCKG_SZ DRVRS=$DRVRS =="

vcs -Mupdate -full64 -sverilog -timescale=1ns/1ps \
    -kdb -lca -debug_acc+all -debug_region+cell+encrypt \
    +lint=TFIPC-L \
    +incdir+$RAIZ/rtl +incdir+$RAIZ/tb \
    +define+PCKG_SZ=$PCKG_SZ +define+DRVRS=$DRVRS \
    $RAIZ/tests/$PRUEBA.sv -o salida -l comp_$PRUEBA.log

if [ $? -ne 0 ]; then
  echo "fallo la compilacion, revise sim/comp_$PRUEBA.log"
  exit 1
fi

./salida -l sim_$PRUEBA.log
