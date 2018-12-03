options nocenter formdlim='-' ps=95;

%let _macropath= /ebaysr/MACROS/dev/model_lib/;
%include "&_macropath./general/impute_truncate.sas";
%include "&_macropath./general/impute_special_wrapper.sas";

libname dat '../data' access=readonly;


proc contents data = dat.b2c_exist_data_mb;
run;

data for_impute;
  set dat.b2c_exist_data_mb;
  
wgt = 1;  
drop
user_id
;
 
run;

%dataclean(dset=for_impute,wghtvar=wgt,imputetype=ZERO,lo=,hi=99,missflag=NO,sqflag=NO);
%write_gensq;



endsas;
/*** impute special missings **/
data ratio_vars;
	infile 'ratio_var_list.txt';
	input @1 name $32.;
run;

proc print data=ratio_vars;
run;

proc contents data=for_impute out=fi_contents noprint;
run;


proc sql;
	select a.name
	  into: rat_list separated by " "
	from fi_contents a
	inner join ratio_vars b
	on a.name = b.name
	;
quit;


data ratio_vars;
	set mdl.model_all ;
	where segment_flag=1;
	
	keep perf_flag1_new5 model_wght1 &rat_list.;
	
run;

%impute_special_wrapper(dset=ratio_vars,perfvar=perf_flag1_new5,wghtvar=model_wght1);
%impute_special_update;

