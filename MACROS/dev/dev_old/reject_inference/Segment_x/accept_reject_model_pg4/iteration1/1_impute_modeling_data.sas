options nocenter formdlim='-' ps=95;
libname mdl '/sas/pprd/austin/models/dev/behavioral/data/ebay_agg/' access=readonly;

%include '../parameters_pg1.sas';
%include "autoexec.sas";
%include "&_macropath./general/impute_truncate.sas";
%include "&_macropath./general/impute_special_wrapper.sas";

data for_impute;
  set dat.&build_set_ap&segment_number
      dat.&valid_set_ap&segment_number ;

  
  %include "drop_list.txt"; 

run;

%dataclean(dset=for_impute,wghtvar=&weight ,imputetype=ZERO,lo=,hi=99,missflag=NO,sqflag=NO);


%write_gensq;
