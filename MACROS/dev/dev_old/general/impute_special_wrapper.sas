/******************************************************************************************** 
/* Program Name:    impute_special_wrapper.sas       
/* Author:          F.Zahradnik
/* Creation Date:   2010-05-23
/* Last Modified: 
/* Purpose:         Wrapper for impute_special_missing macro 
/* Arguments:       DSET - input dataset
                    PERFVAR - performance definition for WOE evaluation
                    WGHTVAR - modeling weight
*********************************************************************************************/ 
%include "&_macropath./general/impute_special_missings.sas";
libname local '.';

%macro impute_special_wrapper(dset=,perfvar=,wghtvar=);

  proc contents data=&dset out=_contents noprint;
  run;
  
  proc sql noprint;
    select name
      into: varlist separated by " "
    from _contents
    where type=1
      and name not in ("&perfvar","&wghtvar")
    order by 1
  ;
  quit;
  
  data collect_special_missing;
    	length varname $32 raw_missing impute_value 8;
  run;
  
  %DO ii=1 %TO &sqlobs.;
    %impute_special_missings(variable=%scan(&varlist.,&ii.,%str( )), perf=&perfvar., weight=&wghtvar., dataset=&dset.);
    
    proc append base=collect_special_missing data=impute_special_missing;
    run;
    
  %END;
  
  data local.impute_special_missing;
  	set collect_special_missing;
  	where lengthn(varname) > 0;
  run;
  
%mend impute_special_wrapper;

%macro impute_special_update;
	
	** make a temp copy of the macro init table;
	data copy_macro_init;
		set local.macro_init;
	run;
	
	data replace_macro_init;
		set local.macro_init;
	run;
	
	proc sql noprint;
		/* determine which variables need to be replaced */
		create table dropvars as
		select distinct varname
		  from local.impute_special_missing
		;
		
		/* remove multi value imputed variables */
		delete from replace_macro_init a
		where a.variable = (select b.varname
		                    from dropvars b
		                    where a.variable = b.varname)
		;
		
		/* insert MVI variables */
		insert into replace_macro_init
		  select varname as variable
		        ,raw_missing as imputemv
		        ,impute_value as imputeval
		        ,'VAL' as imputetype
		        ,. as tlo
		        ,. as thi
		        ,. as missflag
		        ,. as sqflag
		  from local.impute_special_missing
		;
		
		/* update other fields from copy of original dataset */
		create table local.macro_init as
		  select a.variable
		        ,a.imputemv
		        ,a.imputeval
		        ,a.imputetype
		        ,b.tlo
		        ,b.thi
		        ,b.missflag
		        ,b.sqflag
		  from replace_macro_init a
		  inner join copy_macro_init b
		  on a.variable = b.variable
		;
		
		proc print data=copy_macro_init;
		run;
		
		proc print data=replace_macro_init;
		run;
		
		proc print data=local.macro_init;
		run;
%mend impute_special_update;
    

