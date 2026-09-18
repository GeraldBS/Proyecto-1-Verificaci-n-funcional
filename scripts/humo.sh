#!/bin/bash
# compila y corre la prueba de humo en vcs
# uso:
#   ./scripts/humo.sh          -> pckg_sz al azar (16, 32 o 64), drvrs=4
#   ./scripts/humo.sh 32       -> pckg_sz=32
#   ./scripts/humo.sh 64 8     -> pckg_sz=64, drvrs=8
# el tamano del paquete se escoge aqui antes de compilar

CFG=/mnt/vol_NFS_rh003/estudiantes/archivos_config/synopsys_tools2.sh
[ -f "$CFG" ] && source "$CFG"

cd "$(dirname "$0")/.." || exit 1

PCKG_SZ=${1:-$(shuf -n1 -e 16 32 64)}
DRVRS=${2:-4}

mkdir -p sim && cd sim || exit 1
echo "prueba de humo con PCKG_SZ=$PCKG_SZ DRVRS=$DRVRS"

vcs -Mupdate -full64 -sverilog -timescale=1ns/1ps \
    +incdir+../rtl +incdir+../tb \
    +define+PCKG_SZ=$PCKG_SZ +define+DRVRS=$DRVRS \
    ../tests/prueba_humo.sv -o humo -l comp_humo.log \
  && ./humo -l sim_humo.log
