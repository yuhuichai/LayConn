#!/bin/sh
# combine surf data of lh and rh into both hemisphere
dataDir=$1
datalh=$2 # Surf_meandepth_rh.${subj}.gii
datarh=$3
outpre=$4

cd ${dataDir}

echo "************************************************************" 
echo "***** merge ${datalh} and ${datarh} into ${outpre}.gii ****"
echo "************************************************************"
 
ConvertDset -i ${datalh} -o_1D -overwrite -prefix rm.${outpre}_lh &

ConvertDset -i ${datarh} -o_1D -overwrite -prefix rm.${outpre}_rh &

wait

1dcat rm.${outpre}_lh.1D.dset \
	> ${outpre}.1D.dset
1dcat rm.${outpre}_rh.1D.dset \
	>> ${outpre}.1D.dset
rm rm.${outpre}_*h.1D.dset

ConvertDset -i ${outpre}.1D.dset -o_giib64gz -overwrite -prefix ${outpre}.gii

rm ${outpre}.1D.dset

