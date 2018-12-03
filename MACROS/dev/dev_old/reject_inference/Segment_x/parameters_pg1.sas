

options formdlim='-' compress=yes mprint symbolgen;


%include "/sas/pprd/austin/operations/macro_library/dev/general/macros_general.sas";


/* library where the RI input and output datasets are stored*/

%let  dat =/sas/pprd/austin/models/dev/onboard/us/data/hist;   
%let  outdata =/sas/pprd/austin/operations/macro_library/dev/reject_inference/data/;
	
libname dat "&dat";


%let perf=perf_90;                  /* make sure you have 0,1,3,4 as booked bad, booked good, reject, and approved not booked respectively */
%let perf_ra=ar_flag;                /* Flag for Reject (give a value of zero) and Accepts (give a value of 1) */
%let title_proj= Test Reject Inference;
%let data_name_recent=samp_perf_bur;        /* Recent Bureau data  (CB at recent bureau + application vars) */
%let data_name_application=samp_app_bur;   /* Application data */
%let build_set_re= seg1_bld_re	  ; /* Building set with recent bureau */
%let valid_set_re= seg1_vld_re	  ; /* Validation set with recent bureau */
%let build_set_ap= seg1_bld_ap	  ; /* Building set with bureau at time of application */
%let valid_set_ap= seg1_vld_ap	  ; /* Validation set with bureau at time of application */
%let segment_name= Test Segment;
%let segment_number=1;
%let weight=wgt;   
%let weight_one=wgtone;     
%let appid=customer_id;                 /* unique indetifier */
%let score1=SBRI_Card_Score ;	                   /* add any scores at recent bureau that you might want to compare */
%let score2=SBRI_Lease_Score;	  
%let score3=SBRI_Loan_Score;

%let good=1;
%let bad=0;
%let reject=3;
%let ANB=4;                           /* Leave blank if there is no ANB group */

%let booked=0 1;
%let NOT_booked= 3 4;
%let accepts=0 1 4;

%let valid_perf_AR=0 1 3 4;








