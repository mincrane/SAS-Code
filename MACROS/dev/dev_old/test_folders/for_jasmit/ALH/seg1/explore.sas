 /* this is to explore some data to evaluate model performance */

options nocenter formdlim='-' ps=95 mprint symbolgen;

libname dat "/sas/pprd/austin/projects/alh_offebay/data";
%let _macropath= /sas/pprd/austin/operations/macro_library/dev;
%include "&_macropath./logreg/v6/logreg_6.sas";
%include "&_macropath./general/impute_truncate.sas";
%include "&_macropath./general/macros_general.sas";
%include "&_macropath./coarses/pull_woe_code.sas"; 
  
  
data tpv_tof_bad;
    set dat.alh_offebay_all (keep=bad tof gtpv_365d pp_gross_mer_next_30d gtpv_next_30d_cap);
    if tof > 0 then tof_valid_flag =1; else tof_valid_flag=0;
    if gtpv_365d > 0 then tpv_pos_flag =1; else tpv_pos_flag=0;
run;

proc freq data= tpv_tof_bad;
    table bad*tof_valid_flag*tpv_pos_flag/missing;
run;

proc sort data=tpv_tof_bad;
    by bad tof_valid_flag tpv_pos_flag;
run;
 
proc means data=tpv_tof_bad;
    by bad tof_valid_flag tpv_pos_flag;
    var gtpv_365d pp_gross_mer_next_30d gtpv_next_30d_cap;
run;


