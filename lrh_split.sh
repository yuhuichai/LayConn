#!/bin/sh
# split the data of both hemisphere into lh and rh
dataDir=$1
databoth=$2
n_lh=$3
outpre=$4

cd ${dataDir}

n_lh1=`bc -l <<< "${n_lh}-1"`
echo "************************************************************" 
echo "++++ split ${databoth} into ${outpre}.lh.gii and ${outpre}.rh.gii ..."
echo "++++ n_lh = ${n_lh}, n_lh1 = ${n_lh1} ........"
echo "************************************************************"
 
ConvertDset -i ${databoth} -o_1D -overwrite -prefix rm.${outpre}

1dcat rm.${outpre}.1D.dset'{0..'$n_lh1'}' > rm.${outpre}.lh.1D.dset
1dcat rm.${outpre}.1D.dset'{'$n_lh'..$}' > rm.${outpre}.rh.1D.dset

rm rm.${outpre}.1D.dset

ConvertDset -i rm.${outpre}.lh.1D.dset -o_giib64gz -overwrite -prefix ${outpre}.lh.gii
ConvertDset -i rm.${outpre}.rh.1D.dset -o_giib64gz -overwrite -prefix ${outpre}.rh.gii

rm rm.${outpre}.*h.1D.dset

