options nocenter formdlim='-' ps=95;

%include '../parameters_pg1.sas';
%include "autoexec.sas";
%include "&_macropath./general/impute_truncate.sas";
%include "&_macropath./general/impute_special_wrapper.sas";

data for_impute;
  set dat.&build_set_re&segment_number
      dat.&valid_set_re&segment_number ;

  
  %include "drop_list.txt"; 
  
  /*do not remove*/
  drop &perf;

run;

%dataclean(dset=for_impute,wghtvar=&weight ,imputetype=ZERO,lo=,hi=99,missflag=NO,sqflag=NO);


%write_gensq;
