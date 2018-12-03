 * Impute missing value;

options nocenter formdlim='-' ps=95;

libname dat "/sas/pprd/austin/projects/alh_offebay/data";
%let _macropath= /sas/pprd/austin/operations/macro_library/dev;

%include "&_macropath./general/impute_truncate.sas";
%include "&_macropath./general/impute_special_wrapper.sas";



data dat.seg1_na_occasional;
    set dat.alh_offebay_na_sample;
    where seg = 'Occasional';

    %include '/sas/pprd/austin/projects/alh_offebay/vargen/zxue/interaction_var.txt';
    %include '/sas/pprd/austin/projects/alh_offebay/vargen/zxue/interaction_var_list.txt';
    %include '/sas/pprd/austin/projects/alh_offebay/model/NA/seg1/var_keep.txt';

    keep mod_wgt_2 sam_wgt wgt_loss bad pp_gross_mer_next_30d_cap gtpv_next_30d_cap;
run;


data for_impute;
    set dat.seg1_na_occasional;
  
  %include "drop_list.txt"; 
 /*do not remove*/
run;

%dataclean(dset=for_impute,wghtvar=sam_wgt,imputetype=ZERO,lo=,hi=,missflag=NO,sqflag=NO);

%write_gensq;
