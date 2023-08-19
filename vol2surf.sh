#!/bin/sh
dataDIR=/mnt/bic/internal/MRIL/Yuhui_Chai/LayMovie
batchDir=/mnt/bic/internal/MRIL/Yuhui_Chai/LayMovieBatch

cd ${dataDIR}

for patID in xxx.movie; do
{	
	echo "***************************** start with ${patID} *********************"
	patDir=${dataDIR}/${patID}
	anatDIR=${dataDIR}/${patID}/mt.sft
	funcDIR=${dataDIR}/${patID}/vaper.sft
	sumaDir=${dataDIR}/${patID}/mt.sft/SUMA

	# ************************************************************************************************************************
	# echo "++ creates equivolumetric surfaces based on the ratio of areas of the mesh surfaces ..." 	
	cd ${anatDIR}
	export SUBJECTS_DIR=${anatDIR}

	template=mean.sub_d_dant.beta100.masked.denoised.nii.gz
	delta_x=$(3dinfo -adi $template)
	delta_y=$(3dinfo -adj $template)
	delta_z=$(3dinfo -adk $template)

	for us in 5; do
	{
		sdelta_x=$(echo "(($delta_x / $us))"|bc -l)
		sdelta_y=$(echo "(($delta_x / $us))"|bc -l)
		sdelta_z=$(echo "(($delta_z / $us))"|bc -l)
		3dresample -dxyz $sdelta_x $sdelta_y $sdelta_z -rmode Bk -overwrite -prefix scaled${us}_$template -input $template

		for surf in Surf_beta100; do
		{
			fslregister --mov scaled${us}_$template --s ${surf} \
				--reg ${surf}.register_s${us}meanmt.dat
		}&
		done
		wait 
	}&
	done
	wait

	for surf in Surf_beta100; do
		for hemi in lh rh; do
		{
			python3 ~/surface_tools/equivolumetric_surfaces/generate_equivolumetric_surfaces.py \
				--smoothing 0 ${surf}/surf/${hemi}.pial ${surf}/surf/${hemi}.white 18 ${hemi}.equi18_ \
				--software freesurfer --subject_id ${surf}
			
		}&
		done
		wait

		cd ${anatDIR}/${surf}/surf
		for hemi in lh rh; do
		{
			depth0=0
			for dep in 0.0 0.058823529411764705 0.11764705882352941 0.17647058823529413 0.23529411764705882  0.29411764705882354 0.35294117647058826 0.4117647058823529 0.47058823529411764 0.5294117647058824 0.5882352941176471 0.6470588235294118 0.7058823529411765 0.7647058823529411 0.8235294117647058 0.8823529411764706 0.9411764705882353 1.0; do
				let "depth0+=1"
				if [ ${#depth0} = 1 ]; then
					depth=0${depth0}
				else
					depth=${depth0}
				fi

				depth_file=${hemi}.equi18_${dep}.pial

				echo "++ depth = ${depth}, cp ${depth_file} to ${hemi}.equi18_depth${depth}"
				cp ${depth_file} ${hemi}.equi18_depth${depth}


				for iter in 1; do
				{
					mris_mesh_subdivide --surf ${hemi}.equi18_depth${depth} --out ${hemi}.iter${iter}.equi18_depth${depth} \
						--method butterfly --iter ${iter}

				}&
				done
				wait

				if [ ! -f ${hemi}.iter1.equi18_depth${depth} ]; then
					# echo "++ depth${depth} for ${hemi} in ${patID} is not created ...."
					echo "++ ${hemi}.iter1.equi18_depth${depth} in ${patID} is not created ...."
				fi

			done
		}&
		done
		wait
		cd ${anatDIR}

	done

	# ************************************************************************************************************************
	echo "++ convert ts from volume into surface space ..." 
	cd ${funcDIR}

	
	for subj in rbold sub_d_bold; do
	{
		nVol=`3dinfo -nv errts.motion.norm.bp.fanaticor.${subj}.nii.gz`
		let "nvol0=${nVol}-1"


		if [ ! -f Surf_depth18_lh.scaled5.errts.motion.norm.bp.fanaticor.${subj}.gii ]; then
			for volbgn in `seq 0 108 ${nvol0}`; do
			{
				let "volend=${volbgn}+102"
				if [ "$volend" -gt "${nvol0}" ]; then
					volend=${nvol0}
				fi

				for vol0 in `seq ${volbgn} 6 ${volend}`; do
				{
					let "VolEnd=${vol0}+5"
					if [ "${VolEnd}" -gt "${nvol0}" ]; then
						VolEnd=${nvol0}
					fi

					if [ ${#vol0} = 1 ]; then
						volIdx=00${vol0}
					elif [ ${#vol0} = 2 ]; then
						volIdx=0${vol0}
					else
						volIdx=${vol0}
					fi

					echo "++ processing ${vol0}..${VolEnd} of ${nvol0} for ${subj} ......................"
					# file size too large that not possible to process it as a whole
					3dresample -master ${anatDIR}/scaled5_mean.sub_d_dant.beta100.masked.denoised.nii.gz \
						-rmode Bk -overwrite -prefix scaled5.errts.motion.norm.bp.fanaticor.${subj}_${volIdx}.nii.gz \
						-input errts.motion.norm.bp.fanaticor.${subj}.nii.gz[${vol0}..${VolEnd}]
				}&
				done
				wait
			}
			done
			wait

			for vol0 in `seq 0 6 ${nvol0}`; do
			{
				let "VolEnd=${vol0}+5"
				if [ "${VolEnd}" -gt "${nvol0}" ]; then
					VolEnd=${nvol0}
				fi

				if [ ${#vol0} = 1 ]; then
					volIdx=00${vol0}
				elif [ ${#vol0} = 2 ]; then
					volIdx=0${vol0}
				else
					volIdx=${vol0}
				fi

				echo "++ processing ${vol0}..${VolEnd} of ${nvol0} for ${subj} ......................"

				for depth in `seq 1 18`; do # 1 18
				{
					if [ ${#depth} = 1 ]; then
						depth=0${depth}
					fi

					for hemi in lh rh; do #
					{
						cd ${SUBJECTS_DIR}

						mri_vol2surf --src ${funcDIR}/scaled5.errts.motion.norm.bp.fanaticor.${subj}_${volIdx}.nii.gz \
							--out ${funcDIR}/Surf_depth${depth}_${hemi}.scaled5.errts.motion.norm.bp.fanaticor.${subj}_${volIdx}.gii \
							--hemi ${hemi} --srcreg ${anatDIR}/Surf_beta100.register_s5meanmt.dat \
							--interp trilinear --surf iter1.equi18_depth${depth} --out_type giib64gz

						cd ${funcDIR}
					}
					done
					wait
				}&
				done
				wait
				rm ${funcDIR}/scaled5.errts.motion.norm.bp.fanaticor.${subj}_${volIdx}.nii.gz
			}
			done
			wait
			for depth in `seq 1 18`; do # 1 18
			{
				if [ ${#depth} = 1 ]; then
					depth=0${depth}
				fi

				for hemi in lh rh; do #
				{
					3dbucket -overwrite -prefix Surf_depth${depth}_${hemi}.scaled5.errts.motion.norm.bp.fanaticor.${subj}.gii \
						Surf_depth${depth}_${hemi}.scaled5.errts.motion.norm.bp.fanaticor.${subj}_*.gii

					sleep 1
					rm Surf_depth${depth}_${hemi}.scaled5.errts.motion.norm.bp.fanaticor.${subj}_*.gii
				}&
				done
				wait
			}&
			done
			wait

		fi

	}
	done
	wait

}
done
wait





