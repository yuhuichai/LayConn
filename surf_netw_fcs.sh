#!/bin/sh
dataDir=/mnt/bic/internal/MRIL/Yuhui_Chai/LayMovie
batchDir=/mnt/bic/internal/MRIL/Yuhui_Chai/LayMovieBatch

cd ${dataDir}

for patID in *mov*; do  #  
{	
	echo "***************************** start with ${patID} *********************"
	anatDir=${dataDir}/${patID}/mt.sft
	funcDir=${dataDir}/${patID}/vaper.sft
	sumaDir=${dataDir}/${patID}/mt.sft/SUMA

	tmpFuncDir=/data/tmp/${patID}
	mkdir ${tmpFuncDir}

	patnm=All

	cd ${sumaDir}
	n_lh=`3dinfo -ni Surf_lh.brain_mask_gm.gii`
	n_rh=`3dinfo -ni Surf_rh.brain_mask_gm.gii`
	echo "++++ n = ${n_lh} for lh, ${n_rh} for rh ........"

	n_lh1=`bc -l <<< "${n_lh}-1"`
	echo "++++ n_lh1 = ${n_lh1} ........"


	# ************************************************************************************************************************	
	cd ${funcDir}
	#  Create network File Directory only if not Exists
	[ ! -d hub  ] && mkdir hub
	trdouble=`3dinfo -tr bold1.nii.gz`

	# note TRs that were not censored
	ktrs=`1d_tool.py -infile censor_combined.1D -show_trs_uncensored encoded`
	echo $ktrs

	for subj in sub_d_bold_blur0_sm3; do #  
	{
		cd ${funcDir}

		cd ${sumaDir}

		for netw in Surf.RefMeanInvAll.both.icabluryeo_default.gii; do
		{
			netwPre=${netw%.gii}
			netwPre=${netwPre#*both.}
			netwPre=InvAll.${netwPre}

			echo "++++ hub analysis in ${netwPre} ..."

			cd ${funcDir}

			if [ ! -f ${funcDir}/hub/hubpos.${netwPre}.column.alldepth_${subj}.rh.gii ] && [ -f ${sumaDir}/${netw} ]; then

				3dcalc -a ${sumaDir}/${netw} -b ${sumaDir}/Surf_both.column5000.gii \
					-c ${sumaDir}/Surf_both.brain_mask_novessel.gii \
					-expr "step(a)*b*step(c)" -prefix rm.column5000.${netw} -overwrite

				# use columns larger than 30 voxels
				3dROIstats -nomeanout -nzvoxels -quiet \
					-mask rm.column5000.${netw} rm.column5000.${netw} \
					> rm.nvxl.${netwPre}.1D
				1deval -a rm.nvxl.${netwPre}.1D\' -expr "step(a-30)" > rm.nvxl_thr.${netwPre}.1D
				rm rm.nvxl.${netwPre}.1D
				krois=`1d_tool.py -infile rm.nvxl_thr.${netwPre}.1D -show_trs_uncensored encoded`
				rm rm.nvxl_thr.${netwPre}.1D

				# extract tc from columns larger than 30voxels
				3dROIstats -nomeanout -nzmean -quiet -mask rm.column5000.${netw} \
					Surf_meandepth_both.${subj}.gii"[$ktrs]" > tc_meandepth_${subj}_${netwPre}.1D
				1dcat tc_meandepth_${subj}_${netwPre}.1D[$krois] > tcthr_meandepth_${subj}_${netwPre}.1D
				rm tc_meandepth_${subj}_${netwPre}.1D

			
				for depth in `seq 1 18`; do
				{
					if [ ${#depth} = 1 ]; then
						depth=0${depth}
					fi
					
					echo "******************* compute hub for depth = ${depth} ************************"
			
					cd ${tmpFuncDir}
					3dTcorr1D -overwrite -Fisher \
						-prefix rm.${netwPre}.column.depth${depth}_${subj}.both.gii \
						-mask ${sumaDir}/${netw}  \
						${funcDir}/Surf_depth${depth}_both.${subj}.gii"[$ktrs]" \
						${funcDir}/tcthr_meandepth_${subj}_${netwPre}.1D 

					# hubpos #######
					3dcalc -a rm.${netwPre}.column.depth${depth}_${subj}.both.gii \
						-expr "a*step(a)" -overwrite \
						-prefix ${netwPre}.column_pos.depth${depth}_${subj}.both.gii
					rm rm.${netwPre}.column.depth${depth}_${subj}.both.gii

					3dTstat -overwrite -nzmean -prefix hubpos.${netwPre}.column.depth${depth}_${subj}.both.gii \
						${netwPre}.column_pos.depth${depth}_${subj}.both.gii	 
					rm ${netwPre}.column_pos.depth${depth}_${subj}.both.gii

					bash ${batchDir}/lrh_split.sh ${tmpFuncDir} hubpos.${netwPre}.column.depth${depth}_${subj}.both.gii \
						${n_lh} hubpos.${netwPre}.column.depth${depth}_${subj}
					rm hubpos.${netwPre}.column.depth${depth}_${subj}.both.gii

					cd ${funcDir}
					mv ${tmpFuncDir}/hubpos.${netwPre}.column.depth${depth}_${subj}.*h.gii ./


				}&
				done
				wait

				rm rm.column5000.${netw}

				3dbucket -overwrite -prefix hubpos.${netwPre}.column.alldepth_${subj}.lh.gii hubpos.${netwPre}.column.depth*_${subj}.lh.gii
				3dbucket -overwrite -prefix hubpos.${netwPre}.column.alldepth_${subj}.rh.gii hubpos.${netwPre}.column.depth*_${subj}.rh.gii
				mv -f hubpos.${netwPre}.column.alldepth_${subj}.*h.gii hub/
				rm hubpos.${netwPre}.column.depth*_${subj}.lh.gii hubpos.${netwPre}.column.depth*_${subj}.rh.gii


			fi

		}&
		done
		wait

	}
	done
	wait

	rm -rf ${tmpFuncDir}

}
done
wait

