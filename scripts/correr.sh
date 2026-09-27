#!/bin/bash
# compila y corre una prueba en vcs
# uso:
#   ./scripts/correr.sh prueba_humo            -> pckg_sz al azar, drvrs=4
#   ./scripts/correr.sh prueba_driver 32       -> pckg_sz=32
#   ./scripts/correr.sh tb_top 64 8            -> la prueba completa
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

# la prueba puede estar en tests/ o ser el tb_top
if   [ -f "tests/$PRUEBA.sv" ];  then TOP=$RAIZ/tests/$PRUEBA.sv
elif [ -f "tb/top/$PRUEBA.sv" ]; then TOP=$RAIZ/tb/top/$PRUEBA.sv
else
  echo "error: no encuentro $PRUEBA.sv"
  echo "disponibles:"
  ls tests/*.sv tb/top/*.sv 2>/dev/null
  exit 1
fi

mkdir -p sim && cd sim || exit 1
echo "== $PRUEBA con PCKG_SZ=$PCKG_SZ DRVRS=$DRVRS =="

vcs -Mupdate -full64 -sverilog -timescale=1ns/1ps \
    -kdb -lca -debug_acc+all -debug_region+cell+encrypt \
    +lint=TFIPC-L \
    +incdir+$RAIZ/rtl +incdir+$RAIZ/tb +incdir+$RAIZ/tests \
    +define+PCKG_SZ=$PCKG_SZ +define+DRVRS=$DRVRS \
    $TOP -o salida -l comp_$PRUEBA.log

if [ $? -ne 0 ]; then
  echo "fallo la compilacion, revise sim/comp_$PRUEBA.log"
  exit 1
fi

./salida -l sim_$PRUEBA.log
