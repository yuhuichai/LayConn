Codes used in the article "Unlocking whole brain, layer-specific functional connectivity with 3D VAPER fMRI".

(1) Script used to present the movie stimuli: https://github.com/yuhuichai/LayConn/blob/main/hcpmovie.py. This script reads the video file available at: https://drive.google.com/file/d/1UByhA1fKyNXv-ViuTelgWmBrsMwR9BjR/view?usp=sharing. This script is designed to run in PsychoPy 3, and its run time is approximately 16min.

(2) Script used to split the original time series into even (CTRL, can be treated as BOLD signal) and odd (DANTE-prepared images in functional runs or MT-prepared in anatomical runs) time points, and to create a mask for motion correction: https://github.com/yuhuichai/LayConn/blob/main/split_ctrl_dant.sh This script reads the nifti images of all runs and relies on AFNI program. Its run time is around several minutes.

(3) Script used for motion correction: https://github.com/yuhuichai/LayConn/blob/main/mc_run.m This script reads all functional and anatomical runs, replacing the input in mc_job.m with the corresponding nifti names. It depends on SPM12 and REST (http://restfmri.net/forum/) package. The run time can be up to several hours.

(4) Script used to censor time points whenever the Euclidean norm of the motion derivatives exceeded 0.4 mm or when at least 10% of image voxels were seen as outliers from the trend: https://github.com/yuhuichai/LayConn/blob/main/motion_censor.sh It reads the motion parameters estimated by SPM12 and relys on AFNI programs. Its run time could be 20 mins.

(5) Script used to generate VAPER time series (sub_d_bold1/2/3/....nii.gz) and the antomical image (mean.sub_d_dant.beta100.denoised.nii.gz): https://github.com/yuhuichai/LayConn/blob/main/vaper.sh It reads all motion-corrected runs and computes subtraction and ratio operations between CTRL and DANTE or MT time series. For anatomical runs, it computes the mean antomical image and denoise it using ANTs (https://github.com/ANTsX/ANTs) program DenoiseImage. Its run time could be 20 mins or even more depending on the data size.

(6) The script used to do brain segmentation and cortical surface reconstruction: https://github.com/yuhuichai/LayConn/blob/main/reconall_mtepi.sh It relies on AFNI and FreeSurfer programs. Its run time could be 12 hours.

(7) Script used to regress the voxel-wise time series of VAPER against the variables of 6 head motion parameters and their derivatives, slow signal drift modeled with polynomials up to the fifth order, ventricular CSF signal, and voxel-wise local white matter regressors using the ANATICOR method: https://github.com/yuhuichai/LayConn/blob/main/preprocessing.sh It relies on AFNI programs and takes 10-20 mins to execute.

(8) Script used to compute cortical depths and project volumetric functional data to each cortical depth: https://github.com/yuhuichai/LayConn/blob/main/vol2surf.sh It uses the automatically generated cortical surface to compute 18 equi-volume layers through the Surface tools (https://github.com/kwagstyl/surface_tools). The vertex density is further increased by the refinement iteration of 1 for each cortical depth surface. Then the volumetric functional data (time series) is spatically upsampled by a factor of 5 (in all x, y and z directions) and projected to the refined surface of each cortical depth. It relies on AFNI and FreeSurfer programs. Its run time can be 4 hours for one functional time series.

(9) Script used to generate the group-averaged cortical surface and compute the surface registeration between individual and group level: https://github.com/yuhuichai/LayConn/blob/main/surf_reg.sh The script part of generating group-averaging surface is modified from https://surfer.nmr.mgh.harvard.edu/fswiki/SurfaceRegAndTemplates. The resulting surface registration matrix is used specifically for the refined surfaces and can be applied to each cortical depth for a layer-specific surface registration.

(10) A few home-made scripts for common operations in surface space. Convert the FreeSurfer output surface files after mris_mesh_subdivide (upsample surface) into AFNI/SUMA format: https://github.com/yuhuichai/LayConn/blob/main/%40SUMA_Make_Spec_iter1 This script is modified from AFNI/SUMA program @SUMA_Make_Spec_FS. Merge surface files of lh and rh into both hemisphere: https://github.com/yuhuichai/LayConn/blob/main/lrh_merge.sh Split surface file in both hemisphere into lh and rh seperately: https://github.com/yuhuichai/LayConn/blob/main/lrh_split.sh

(11) Script used to compute functional connectivity strength at each cortical depth within
 each network: https://github.com/yuhuichai/LayConn/blob/main/surf_netw_fcs.sh It reads the surface file of functional time series and network mask, and outputs the functional connectivity strength for every vertex across layers within that network. This script depends on AFNI program.

(12) Script used to perform k-means clustering of functional connectivity strength-based layer profiles within each network: https://github.com/yuhuichai/LayConn/blob/main/kmeans_layerhub_k2.m It reads the functional connectivity map across layers and outputs the k-mean clusters based on the similarity of functional connectivity strength across 18 cortical depths. This script runs in MATLAB.

(13) Script used to compute the Dice similarity coefficient for k-means parcellations (k = 2) across different datasets: https://github.com/yuhuichai/LayConn/blob/main/dice_k2.m It reads the k-mean clustering map pairs and outputs the Dice's coefficient value. 
