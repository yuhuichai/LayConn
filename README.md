These codes were used in the article of "Unlocking whole brain, layer-specific functional connectivity with 3D VAPER fMRI".

(1) Script used to present the movie stimuli: https://github.com/yuhuichai/LayConn/blob/main/hcpmovie.py. This script reads the video file which can be found in https://drive.google.com/file/d/1UByhA1fKyNXv-ViuTelgWmBrsMwR9BjR/view?usp=sharing. This script runs in PsychoPy 3. The run time is around 16min.

(2) Script used to split original time series into even (CTRL, can be treated as BOLD signal) and odd (DANTE-prepared images in functional runs, or MT-prepared in anatomical run) time points and create mask for motion correction: https://github.com/yuhuichai/LayConn/blob/main/split_ctrl_dant.sh This script read the nifti images of all runs. It is writen in bash shell and depends on AFNI program. The run time is around several minutes.

(3) Script used for motion correction: https://github.com/yuhuichai/LayConn/blob/main/mc_run.m This script read the all functional and anatomical runs, and replace the input in mc_job.m with these nifti names. It runs in MATLAB and depends on the SPM12 and REST (http://restfmri.net/forum/) package. The run time can be up to several hours.

(4) Script used to censor time points whenever the Euclidean norm of the motion derivatives exceeded 0.4 mm or when at least 10% of image voxels were seen as outliers from the trend: https://github.com/yuhuichai/LayConn/blob/main/motion_censor.sh It reads the motion parameters estimated by SPM12 in step 3, and runs AFNI programs as in bash shell. The run time could be 20 mins.

(5) Script used to generate VAPER time series (sub_d_bold1/2/3/....nii.gz) and antomical image (mean.sub_d_dant.beta100.denoised.nii.gz): https://github.com/yuhuichai/LayConn/blob/main/vaper.sh It reads all runs motion corrected by SPM12 and then do subtraction and ratio computation between CTRL and DANTE or MT time series. For anatomical runs, we compute the mean antomical image and denoise it using ANTs (https://github.com/ANTsX/ANTs) program DenoiseImage. This script is writen in bash shell and depends on AFNI programs. The run time could be 20 mins or even more depending on the data size.

(6) The script used to do brain segmentation and cortical surface reconstruction: https://github.com/yuhuichai/LayConn/blob/main/reconall_mtepi.sh For the whole-brain MT-weighted EPI images, WM/GM segments and cortical surface were generated using FreeSurfer program recon-all. The run time could be 12 hours.

(7) Script used to do regression analysis and generate voxelwise beta weights / percent signal changes for each stimulation condition: https://github.com/yuhuichai/Audiovisual_in_PT/blob/main/afni_3ddeconvolve.sh This script is writen in bash shell and depends on AFNI programs. The run time is about 10 mins.

(7) Script used to compute cortical layers and do layer-specific smoothing: https://github.com/yuhuichai/Audiovisual_in_PT/blob/main/layerSmooth_mc.sh It reads the layerMask file, which covers the PT area and are draw in fsleyes (https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FSLeyes). It grows cortical layers and do layer-specific smoothing using LAYNII programs (https://github.com/layerfMRI/LAYNII). The script is writen in bash shell and depends on AFNI programs. The run time can be up to one hour.

(8) Script used to compute cortical columns and extract signal changes across columns: https://github.com/yuhuichai/Audiovisual_in_PT/blob/main/columnProfile.sh It reads the cortical layer nifti generated in step 7 and the landmark mannually draw to indicate the starting and ending boundaries in fsleyes. Tutorials to draw landmark and compute cortical columns is available in https://layerfmri.com/2018/09/26/columns/ This script depends on AFNI programs and outputs coritcal columns and the text files of columnar signal changes.

(9) Script used to extract signal changes across cortical layers: https://github.com/yuhuichai/Audiovisual_in_PT/blob/main/layerProfile_lay.sh It reads the ROI of auditory T2, anterior and posterior PT, and output the laminar-specific signal changes in these ROIs. This script depends on AFNI program.

(10) Script used to perform behavior data analysis: https://github.com/yuhuichai/Audiovisual_in_PT/blob/main/correctRate.m It reads the behavior data from each session of each subject, computes the accuracy rate and response time, then compare across different conditions using anova1 with multicomparison correction. This script runs in MATLAB.
