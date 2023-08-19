# !/bin/bash

# set data directories
top_dir=/mnt/bic/internal/MRIL/Yuhui_Chai/LayMovie
cd $top_dir

for patDir in *mov*; do
{
	cd ${top_dir}/${patDir}
	echo " ====================== start with ${patDir} ==================== "

	cd ${top_dir}/${patDir}/mt.sft/SUMA
	3dcalc -a aparc+aseg.nii.gz -datum byte \
		-expr 'amongst(a,2,7,41,46,251,252,253,254,255)' \
		-prefix SUMA_WM.nii.gz -overwrite
	3dcalc -a aparc+aseg.nii.gz -datum byte \
		-expr 'amongst(a,4,43)' \
		-prefix SUMA_vent.nii.gz -overwrite
	cd ${top_dir}/${patDir}

	for runDir in vaper.sft; do # 
	{	
		if [ -d ${top_dir}/${patDir}/${runDir} ]; then
			cd ${top_dir}/${patDir}/${runDir}

			run_dsets=($(ls -f ../vaper.sft/dant*.nii.gz))
			run_num=${#run_dsets[@]}
			trdouble=`3dinfo -tr bold1.nii.gz`

			# ================================= vent, wm ==================================
			for roi in vent WM; do
				3dresample -master ../mt.sft/mean.sub_d_dant.beta100.nii.gz -rmode NN \
					-overwrite -prefix ${roi}_resamp.nii.gz -input ../mt.sft/SUMA/SUMA_${roi}.nii.gz

				3dcalc -a ${roi}_resamp.nii.gz -b mean.rbold.nii.gz -c ../brain_mask_comb_mc_rb.nii.gz \
					-expr "step(a-0.5)*step(b)*step(c)" -prefix ${roi}.nii.gz -overwrite

				rm ${roi}_resamp.nii.gz
			done

			# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			3dcalc -a ../brain_mask_comb_mc_rb.nii.gz -b mean.rbold.nii.gz \
				-expr "step(a)*step(b)" -prefix rm.brain_mask.nii.gz -overwrite
			mv rm.brain_mask.nii.gz brain_mask.nii.gz

			# note TRs that were not censored
			ktrs=`1d_tool.py -infile censor_combined.1D -show_trs_uncensored encoded`

			for subj in rbold sub_d_bold; do 
			{		

				# ------------------------------
				# create ROI PC ort sets: vent
				# create a time series dataset to run 3dpc on...
			    3dTproject -mask ../brain_mask_comb_mc_rb.nii.gz \
			    	-polort 5 -overwrite -prefix rm.det.${subj}.nii.gz     \
			    	-censor censor_combined.1D -cenmode KILL                    \
			        -input ${subj}*.nii.gz

				# make ROI PCs : vent
				3dpc -mask vent.nii.gz -pcsave 3                                  \
				     -prefix rm.${subj}.ROIPC.vent -overwrite rm.det.${subj}.nii.gz

				# zero pad censored TRs
				1d_tool.py -censor_fill_parent censor_combined.1D                \
				    -infile rm.${subj}.ROIPC.vent_vec.1D                                           \
				    -write ${subj}.ROIPC.vent.1D -overwrite

				# --------------------------------------------------
				# fast ANATICOR: generate local WM time series averages
				# create catenated volreg dataset
				3dTcat -prefix all_runs.${subj}.nii.gz ${subj}*nii.gz -overwrite

				# mask white matter before blurring
				3dcalc -a all_runs.${subj}.nii.gz -b WM.nii.gz                    \
				       -expr "a*bool(b)" -datum float \
				       -prefix all_runs.wm.${subj}.nii.gz -overwrite

				# generate ANATICOR voxelwise regressors via blur
				3dmerge -1blur_fwhm 30 -doall -prefix Local_WM_rall.${subj}.nii.gz -overwrite                        \
				    all_runs.wm.${subj}.nii.gz

				restinput=${subj}
				mask=../brain_mask_comb_mc_rb.nii.gz

				3dDeconvolve -input ${restinput}*.nii.gz             \
					-mask ${mask}                          \
					-censor censor_combined.1D                    \
					-ortvec ${subj}.ROIPC.vent.1D ${subj}.ROIPC.vent              \
				    -polort 5 -float                              \
				    -jobs 2                                       \
				    -num_stimts 12                                                         \
				    -stim_file 1 motion_demean.bold.1D'[0]' -stim_base 1 -stim_label 1 roll_01  \
				    -stim_file 2 motion_demean.bold.1D'[1]' -stim_base 2 -stim_label 2 pitch_01 \
				    -stim_file 3 motion_demean.bold.1D'[2]' -stim_base 3 -stim_label 3 yaw_01   \
				    -stim_file 4 motion_demean.bold.1D'[3]' -stim_base 4 -stim_label 4 dS_01    \
				    -stim_file 5 motion_demean.bold.1D'[4]' -stim_base 5 -stim_label 5 dL_01    \
				    -stim_file 6 motion_demean.bold.1D'[5]' -stim_base 6 -stim_label 6 dP_01    \
				    -stim_file 7 motion_deriv.bold.1D'[0]' -stim_base 7 -stim_label 7 roll_02   \
				    -stim_file 8 motion_deriv.bold.1D'[1]' -stim_base 8 -stim_label 8 pitch_02  \
				    -stim_file 9 motion_deriv.bold.1D'[2]' -stim_base 9 -stim_label 9 yaw_02 \
				    -stim_file 10 motion_deriv.bold.1D'[3]' -stim_base 10 -stim_label 10 dS_02  \
				    -stim_file 11 motion_deriv.bold.1D'[4]' -stim_base 11 -stim_label 11 dL_02  \
				    -stim_file 12 motion_deriv.bold.1D'[5]' -stim_base 12 -stim_label 12 dP_02  \
				    -nobucket -nofullf_atall -x1D X.motion.xmat.${restinput}.1D -xjpeg X.motion.${restinput}.jpg \
				    -x1D_uncensored X.motion.nocensor.xmat.${restinput}.1D 				\
				    -errts errts.motion.${restinput}.nii.gz 				\
				    -x1D_stop											\
				    -overwrite


				# # # #============================= 3dTproject with norm ===================================
				# # # 3dTproject -mask ${mask} -polort 0 -input ${restinput}*.nii.gz                   \
				# # #            -censor censor_combined.1D -cenmode ZERO              \
				# # #            -dsort Local_WM_rall.${subj}.nii.gz           \
				# # #            -ort X.motion.nocensor.xmat.${restinput}.1D \
				# # #            -prefix errts.motion.norm.fanaticor.${restinput}.nii.gz    \
				# # #            -norm -overwrite

				#============================= 3dTproject with filter ===================================
				3dTproject -mask ${mask} -polort 0 -input ${restinput}*.nii.gz                   \
				           -censor censor_combined.1D -cenmode ZERO              \
				           -dsort Local_WM_rall.${subj}.nii.gz           \
				           -ort X.motion.nocensor.xmat.${restinput}.1D \
				           -prefix errts.motion.norm.bp.fanaticor.${restinput}.nii.gz    \
				           -passband 0.01 0.08 \
				           -norm -overwrite


			}&
			done
			wait
			rm rm* all_runs*

		fi
	}
	done
	wait

}&
done
wait
