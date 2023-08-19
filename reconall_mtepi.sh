#!/bin/sh
dataDIR=/data/LayMovie/
batchDir=/mnt/bic/internal/MRIL/Yuhui_Chai/LayMovieBatch

cd ${dataDIR}

for patID in xxx.movie/mt.sft; do
{	
	patDIR=${dataDIR}/${patID}
	cd ${patDIR}

	echo "***************************** start with ${patID} *********************"

	beta=100

	thr=0.5
	3dAutomask -overwrite -clfrac $thr -prefix brain_mask_aftmc.nii.gz mean.rbold.nii.gz
	if [ -f brain_mask_aftmc.nii.gz ]; then
		epiMask=${patDIR}/brain_mask_aftmc.nii.gz
	else
		if [ -f ${patDIR}/../brain_mask_comb_mc.nii.gz ]; then
			epiMask=${patDIR}/../brain_mask_comb_mc.nii.gz
		else
			epiMask=${patDIR}/../brain_mask_comb.nii.gz
		fi
	fi

	3dcalc -a mean.sub_d_dant.beta${beta}.nii.gz -b ${epiMask} \
		-expr 'step(b)*a' \
		-prefix mean.sub_d_dant.beta${beta}.masked.nii.gz \
		-overwrite

	template=mean.sub_d_dant.beta${beta}.masked.nii.gz

	DenoiseImage -d 3 -n Gaussian -i ${template} -o denoise.${template}

	3dUnifize -input denoise.${template} -prefix uni.denoise.${template} -overwrite

	if [ -f brain2epi_mc.nii.gz ]; then
		3dUnifize -input brain2epi_mc.nii.gz -prefix uni.brain2epi.nii.gz -overwrite
	else
		3dUnifize -input brain2epi.nii.gz -prefix uni.brain2epi.nii.gz -overwrite
	fi

	echo "++ add empty slices on each direction, make sure it matchs with align_anat2func"
	3dZeropad -I 40 -S 40 -A 40 -P 40 -L 40 -R 40 -prefix pad0.uni.denoise.${template} uni.denoise.${template} -overwrite

	if [ -f mean.sub_d_dant_mc.nii.gz ]; then
		3dZeropad -I 40 -S 40 -A 40 -P 40 -L 40 -R 40 -prefix pad0.mean.sub_d_dant.beta100.nii.gz mean.sub_d_dant_mc.nii.gz -overwrite
	else
		3dZeropad -I 40 -S 40 -A 40 -P 40 -L 40 -R 40 -prefix pad0.mean.sub_d_dant.beta100.nii.gz mean.sub_d_dant.beta100.nii.gz -overwrite
	fi

	3dcalc -a pad0.uni.denoise.${template} -b uni.brain2epi.nii.gz -c pad0.mean.sub_d_dant.beta100.nii.gz -expr "a*notzero(c)+b*iszero(c)" \
		-prefix recon.${template} -overwrite

	rm uni.brain2epi.nii.gz uni.brain2epi.nii.gz denoise.${template} uni.denoise.${template} pad0.uni.denoise.${template}

	export SUBJECTS_DIR=${patDIR}

	# A: If your skull-stripped volume does not have the cerebellum, then no. If it does, then yes, however you will have to run the data a bit differently.

	# First you must run only -autorecon1 like this: 
	# recon-all -autorecon1 -noskullstrip -s <subjid>
	recon-all -i recon.${template} -subjid Surf_beta${beta} -autorecon1 -noskullstrip -hires

	echo "++ check alignment betw input and MNI"
	# tkregister2 --mgz --s Surf_beta${beta} --fstal

	#@# Nu Intensity Correction Sat Oct 26 12:25:45 EDT 2019
	cd ${patDIR}/Surf_beta${beta}/mri
	mri_nu_correct.mni --i orig.mgz --o nu.mgz --uchar transforms/talairach.xfm --cm --n 2
	mri_add_xform_to_header -c ${patDIR}/Surf_beta${beta}/mri/transforms/talairach.xfm nu.mgz nu.mgz
	#@# Intensity Normalization Sat Oct 26 12:30:07 EDT 2019
	mri_normalize -g 1 -mprage -noconform nu.mgz T1.mgz


	cd ${patDIR}
	cp Surf_beta${beta}/mri/T1.mgz Surf_beta${beta}/mri/brainmask.auto.mgz
	cp Surf_beta${beta}/mri/T1.mgz Surf_beta${beta}/mri/brainmask.mgz

	# Then you will have to make a symbolic link or copy T1.mgz to brainmask.auto.mgz and a link from brainmask.auto.mgz to brainmask.mgz. 
	# Finally, open this brainmask.mgz file and check that it looks okay 
	# (there is no skull, cerebellum is intact; use the sample subject bert that comes with your FreeSurf_beta${beta}er 
	# installation to make sure it looks comparable). From there you can run the final stages of recon-all: 
	# recon-all -autrecon2 -autorecon3 -s <subjid>
	recon-all -s Surf_beta${beta} -autorecon2 -autorecon3 -hires -parallel -openmp 4 -expert ${batchDir}/reconall.expert100 -xopts-overwrite 


	echo "++++++++++++++++++++++ upsample cortical surfaces for ${patID} ++++++++++++++++++++++++"
	export SUBJECTS_DIR=${patDIR}
	cd ${patDIR}/Surf_beta100/surf
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
	}
	done
	wait
	cd ${patDIR}

	@SUMA_Make_Spec_iter1 -fspath Surf_beta${beta}/surf -sid SUMA -NIFTI -no_ld

	mv Surf_beta${beta}/surf/SUMA ./

}&
done
wait

