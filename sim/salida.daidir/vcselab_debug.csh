#!/bin/csh -f

cd /mnt/vol_NFS_rh003/Est_Veri_II2026/PEREZ_SANDOVAL_LEONARDO_VeriII26/Proyecto-1-Verificaci-n-funcional/sim

#This ENV is used to avoid overriding current script in next vcselab run 
setenv SNPS_VCSELAB_SCRIPT_NO_OVERRIDE  1

/mnt/vol_NFS_rh003/tools/vcs/R-2020.12-SP2/linux64/bin/vcselab $* \
    -o \
    salida \
    -nobanner \

cd -

