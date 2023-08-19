# # !/bin/bash

top_dir=/media/yuhui/LayConn # replace with your own data directory
cd $top_dir

for patDir in *rest* *movie*; do
{
	cd ${top_dir}/${patDir}
	for runDir in mt.sft vaper.sft; do
	{	
		if [ -d ${top_dir}/${patDir}/${runDir} ]; then
			cd ${top_dir}/${patDir}/${runDir}

			echo "************** start with ${patDir}/${runDir} **********************"

			run_dsets=($(ls -f rbold*.nii.gz))
			run_num=${#run_dsets[@]}

			trdouble=`3dinfo -tr bold1.nii.gz`
			tr=`bc -l <<< "${trdouble}/2"`

			echo "************** actual TR = ${tr} **********************"

			3drefit -TR ${trdouble} rbold*.nii.gz
			3drefit -TR ${trdouble} rdant*.nii.gz

			3drefit -space ORIG rbold*.nii.gz rdant*.nii.gz

			if [[ "$runDir" == *"vaper"* ]]; then
				echo "******************** compute all kinds of contrast ***********************"
				for run in `seq 1 ${run_num}`; do 
				{ 	
					
					datatype=`3dinfo -datum rbold1.nii.gz[0]`
					if [[ "$datatype" == "float" ]]; then
						echo "*********************** data already in float ***********************"
					else
						echo "*********************** convert short to float ***********************"
						3dcalc -a rbold${run}.nii.gz -expr "a" \
							-float -prefix rm.rbold${run}.nii.gz
						mv rm.rbold${run}.nii.gz rbold${run}.nii.gz

						3dcalc -a rdant${run}.nii.gz -expr "a" \
							-float -prefix rm.rdant${run}.nii.gz
						mv rm.rdant${run}.nii.gz rdant${run}.nii.gz
					fi

					NumVolCtrl=`3dinfo -nv rbold${run}.nii.gz`
					NumVolTagd=`3dinfo -nv rdant${run}.nii.gz`

					if [ "$NumVolCtrl" -gt "$NumVolTagd" ]; then
						3dTcat -overwrite -prefix rm.rbold${run}.nii.gz \
							rbold${run}.nii.gz'[0..'`expr $NumVolCtrl - 2`']'
						mv rm.rbold${run}.nii.gz rbold${run}.nii.gz
					elif [ "$NumVolCtrl" -lt "$NumVolTagd" ]; then
						3dTcat -overwrite -prefix rm.rdant${run}.nii.gz \
							rdant${run}.nii.gz'[0..'`expr $NumVolTagd - 2`']'
						mv rm.rdant${run}.nii.gz rdant${run}.nii.gz
					fi
						
					echo "******************** (dant(n)+dant(n+1))/2*bold(n+1) ***********************"
					NumVol=`3dinfo -nv rbold${run}.nii.gz`

					3dcalc -prefix rm.bold_mdant${run}_1vol.nii.gz \
						-a rbold${run}.nii.gz'[0]' \
						-b rdant${run}.nii.gz'[0]' \
						-expr '(a-b)' -float -overwrite

					# Calculate all volumes after the first one
					3dcalc -prefix rm.bold_mdant${run}_othervols.nii.gz \
						-a rdant${run}.nii.gz'[0..'`expr $NumVol - 2`']' \
						-b rdant${run}.nii.gz'[1..$]' \
						-c rbold${run}.nii.gz'[1..$]' \
						-expr '(c-(a+b)/2)' -float -overwrite

					3dTcat -overwrite -prefix bold_mdant$run.nii.gz rm.bold_mdant${run}_1vol.nii.gz rm.bold_mdant${run}_othervols.nii.gz
					3drefit -TR ${trdouble} bold_mdant$run.nii.gz
					
					3dcalc -prefix rm.sub_d_bold${run}_1vol.nii.gz \
						-a rbold${run}.nii.gz'[0]' \
						-b rdant${run}.nii.gz'[0]' \
						-expr '(a-b)/a' -float -overwrite

					3dcalc -prefix rm.sub_d_bold${run}_othervols.nii.gz \
						-a rdant${run}.nii.gz'[0..'`expr $NumVol - 2`']' \
						-b rdant${run}.nii.gz'[1..$]' \
						-c rbold${run}.nii.gz'[1..$]' \
						-expr '(c-(a+b)/2)/c' -float -overwrite

					3dTcat -overwrite -prefix sub_d_bold$run.nii.gz rm.sub_d_bold${run}_1vol.nii.gz rm.sub_d_bold${run}_othervols.nii.gz
					3drefit -TR ${trdouble} sub_d_bold$run.nii.gz

				}&
				done
				wait
			fi
			rm rm*

			if [[ "$runDir" == *"mt"* ]]; then
				for subj in rbold rdant; do
				{	
					if [ ${run_num} == 1 ]; then
						3dTstat -overwrite -mean -prefix mean.${subj}.nii.gz ${subj}1.nii.gz # note TRs that were not censored
					else
						3dTcat -prefix all_runs.${subj}.nii.gz ${subj}*nii.gz -overwrite
						3dTstat -overwrite -mean -prefix mean.${subj}.nii.gz all_runs.$subj.nii.gz # note TRs that were not censored
						rm all_runs.$subj.nii.gz
					fi
				}&
				done
				wait

				3dcalc -a mean.rbold.nii.gz -b mean.rdant.nii.gz \
					-expr "(a-b)/(b+100)" -prefix mean.sub_d_dant.beta100.nii.gz -overwrite

				DenoiseImage -d 3 -n Gaussian -i mean.sub_d_dant.beta100.nii.gz -o mean.sub_d_dant.beta100.denoised.nii.gz

			fi

		fi
	}&
	done
	wait

}&
done
wait
