#!/bin/sh
dataDIR=/mnt/bic/internal/MRIL/Yuhui_Chai/LayMovie
batchDir=/mnt/bic/internal/MRIL/Yuhui_Chai/LayMovieBatch

cd ${dataDIR}
for patID in *movie*; do
{
	patDir=${dataDIR}/${patID}
	anatDIR=${dataDIR}/${patID}/mt.sft
	surfDir=${dataDIR}/${patID}/mt.sft/Surf_beta100

	patPre=${patID%.*}
	mkdir ${dataDIR}/group/Surf_${patPre}
	cp -r ${surfDir}/*  ${dataDIR}/group/Surf_${patPre}
	cd ${dataDIR}/group/Surf_${patPre}/surf
	rm *iter*  
	rm *equi*

}&
done
wait

cd ${dataDIR}/group
SUBJECTS_DIR=${dataDIR}/group
make_average_subject --out All_Surfmean --subjects Surf_*

for patNM in DEG_KAT CLA_DAN EAS_SER LI_SAM; do
{
	make_average_subject --out ${patNM}_Surfmean --subjects Surf_*${patNM}
}&
done
wait

# Register each subject to the new template (do for both lh and rh) Creates lh.sphere.reg.newtemplate and rh.sphere.reg.newtemplate
for subject in Surf_*; do
{
	cd ${dataDIR}/group

	patnm=${subject#*_}
	patnm=${patnm#*_}
	patmean=`ls -d *${patnm}_Surfmean`

	cd ${dataDIR}/group/${subject}

	for hemi in lh rh; do
	{
		for meantype in All_Surfmean ${patmean}; do
		{
			mris_register -curv surf/${hemi}.sphere \
				${dataDIR}/group/${meantype}/${hemi}.reg.template.tif \
				surf/${hemi}.sphere.reg.${meantype}
		}&
		done
		wait
	}&
	done
	wait
	cd ${dataDIR}/group
}&
done
wait

cd ${dataDIR}/group
make_average_subject --out All_Surfmeannew \
	--surf-reg sphere.reg.All_Surfmean \
	--subjects Surf_* &



cd ${dataDIR}/group
echo "++ prepare iter1 for sulc, smoothwm and sphere for Surfmeannew ..."

for meannew in All_Surfmeannew; do
{
	if [ ! -d ${meannew}_iter1 ]; then
		cp -r ${meannew} ${meannew}_iter1
	fi

	meanpre=${meannew%_Surfmeannew}

	cd ${dataDIR}/group/${meannew}_iter1/surf
	for hemi in lh rh; do
	{

		for surf in pial white smoothwm inflated sphere; do # 
		{
			# mris_convert -a -c ${hemi}.${surf} ${hemi}.white ${hemi}.${surf}.asc
			mris_mesh_subdivide --surf ${hemi}.${surf} --out ${hemi}.iter1.${surf} \
				--method butterfly --iter 1 &
			mris_mesh_subdivide --surf ${hemi}.${surf}.asc --out ${hemi}.iter1.${surf}.asc \
				--method butterfly --iter 1 &
			wait
		}&
		done
		wait

		mris_curvature -seed 1234 -thresh .999 -n -a 5 -w -distances 10 10 ${hemi}.iter1.inflated 
		mris_inflate -n 100 -sulc iter1.sulc ${hemi}.iter1.smoothwm ${hemi}.iter1.inflated

		mv ${hemi}.smoothwm ${hemi}.orig.smoothwm
		mv ${hemi}.sulc ${hemi}.orig.sulc
		mv ${hemi}.sphere ${hemi}.orig.sphere

		mv ${hemi}.iter1.smoothwm ${hemi}.smoothwm
		mv ${hemi}.iter1.sulc ${hemi}.sulc
		mv ${hemi}.iter1.sphere ${hemi}.sphere

		cd ${dataDIR}
		mris_register -1 -curv -inflated \
			-infname iter1.inflated \
			group/${meannew}_iter1/surf/${hemi}.sphere \
			group/${meannew}_iter1/surf/${hemi}.sphere \
			group/${meannew}_iter1/surf/${hemi}.${meanpre}.iter1.sphere.reg

		cd ${dataDIR}/group/${meannew}_iter1/surf

	}&
	done
	wait

	cd ${dataDIR}/group/${meannew}/surf
	for surf in pial white smoothwm inflated sphere; do
	{
		for hemi in rh lh; do
		{
			# mris_convert -a -c ${hemi}.${surf} ${hemi}.white ${hemi}.${surf}.asc
			# mris_mesh_subdivide --surf ${hemi}.${surf}.asc --out ${hemi}.iter1.${surf}.asc \
			# 	--method butterfly --iter 1 
			mris_mesh_subdivide --surf ${hemi}.${surf} --out ${hemi}.iter1.${surf} \
				--method butterfly --iter 1 &
			mris_mesh_subdivide --surf ${hemi}.${surf}.asc --out ${hemi}.iter1.${surf}.asc \
				--method butterfly --iter 1 &
			wait
		}&
		done
		wait
	}&
	done
	wait

	cd ${dataDIR}/group
	@SUMA_Make_Spec_iter1 -fspath ${meannew}/surf -sid SUMA -NIFTI -no_ld
	mv ${meannew}/surf/SUMA ${meannew}/

}&
done
wait

cd ${dataDIR}
for patID in *mov*; do
{		
	patDir=${dataDIR}/${patID}
	anatDIR=${dataDIR}/${patID}/mt.sft
	funcDIR=${dataDIR}/${patID}/vaper.sft
	sumaDir=${dataDIR}/${patID}/mt.sft/SUMA


	patnm=All

	# # patNM=${patID%.*}
	# # cp -r Surf_beta100 ../../group/Surf_${patNM}

	export SUBJECTS_DIR=${anatDIR}
	echo "++ create a seperate Surf_iter1 ..."
	cd ${anatDIR}

	if [ ! -d Surf_iter1 ]; then
		cp -r Surf_beta100 Surf_iter1
	fi

	echo "++ prepare iter1 for sulc, smoothwm and sphere ..." 
	cd ${anatDIR}/Surf_iter1/surf
	for hemi in lh rh; do
	{
		mris_curvature -seed 1234 -thresh .999 -n -a 5 -w -distances 10 10 ${hemi}.iter1.inflated 
		mris_inflate -n 100 -sulc iter1.sulc ${hemi}.iter1.smoothwm ${hemi}.iter1.inflated

		mv ${hemi}.smoothwm ${hemi}.orig.smoothwm
		mv ${hemi}.sulc ${hemi}.orig.sulc
		mv ${hemi}.sphere ${hemi}.orig.sphere

		mv ${hemi}.iter1.smoothwm ${hemi}.smoothwm
		mv ${hemi}.iter1.sulc ${hemi}.sulc
		mv ${hemi}.iter1.sphere ${hemi}.sphere
	}&
	done
	wait

	cd ${dataDIR}
	for hemi in lh rh; do
	{
		cd ${dataDIR}
		SUBJECTS_DIR=${dataDIR}

        #######################

        cd ${dataDIR}

		for subj in All; do #  
		{
			if [ -d ${dataDIR}/group/${subj}_Surfmeannew_iter1 ]; then
				mris_register -1 -curv -inflated \
					-infname iter1.inflated \
					${patID}/mt.sft/Surf_iter1/surf/${hemi}.sphere \
					group/${subj}_Surfmeannew_iter1/surf/${hemi}.sphere \
					${patID}/mt.sft/Surf_iter1/surf/${hemi}.${subj}.iter1.sphere.reg

				mri_surf2surf --srcsubject ${patID}/mt.sft/Surf_iter1 \
					--trgsubject group/${subj}_Surfmeannew_iter1 \
					--surfreg ${subj}.iter1.sphere.reg \
					--sval ${patID}/mt.sft/SUMA/Surf_${hemi}.curvature.gii \
					--tval ${patID}/mt.sft/SUMA/Surf.Ref${subj}.${hemi}.curvature.gii \
					--sfmt paint --tfmt paint --hemi ${hemi} --noreshape


				######## ica yeo network masks ########################################################
				for ica in default dorsal frontal somat ye17_default ye17_dorsal ye17_frontal ye17_somat; do
				{
					mri_surf2surf --srcsubject ${patID}/mt.sft/Surf_iter1 \
						--trgsubject group/${subj}_Surfmeannew_iter1 \
						--surfreg ${subj}.iter1.sphere.reg \
						--sval ${patID}/mt.sft/SUMA/icayeo.${ica}.${hemi}.gii \
						--tval ${patID}/mt.sft/SUMA/Surf.Ref${subj}.${hemi}.icayeo_${ica}.gii \
						--sfmt paint --tfmt paint --hemi ${hemi} --noreshape

					# # inverse, from group to individual
					# cd ${dataDIR}
					# mri_surf2surf --srcsubject group/${subj}_Surfmeannew_iter1 \
					# 	--trgsubject ${patID}/mt.sft/Surf_iter1 \
					# 	--surfreg ${subj}.iter1.sphere.reg \
					# 	--sval group/${subj}_Surfmeannew/SUMA/Surf.RefMean${subj}.${hemi}.icayeo_${ica}.gii \
					# 	--tval ${patID}/mt.sft/SUMA/rm.Surf.RefMeanInv${subj}.${hemi}.icayeo_${ica}.gii \
					# 	--sfmt paint --tfmt paint --hemi ${hemi} --noreshape

					# cd ${sumaDir}
					# 3dcalc -a rm.Surf.RefMeanInv${subj}.${hemi}.icayeo_${ica}.gii -expr "step(a-0.5)" \
					# 	-prefix Surf.RefMeanInv${subj}.${hemi}.icayeo_${ica}.gii -overwrite
					# rm rm.Surf.RefMeanInv${subj}.${hemi}.icayeo_${ica}.gii
					# cd ${dataDIR}

				}&
				done
				wait


			fi
		}&
		done
		wait
	}&
	done
	wait


}&
done
wait






