
** 3/10/2005  changed so that model_coarses are ordered by descending chi-squared. ;

options  mprint symbolgen nodate formdlim=" ";



*------------------------------------------------------------------------;
* 'OBJECTIVE': GETTING COLLINEARITY STATS ON MODEL VARIABLES;
* PERFORMANCE VARIABLE PASSED AS MACRO VARIABLE;
*------------------------------------------------------------------------;

libname datcoll 'data';

data model_vars(Keep=varname chi RENAME=(varname=name));
  length varname $30;
  infile "./runs/strength" end=stop;
  input varnum varname $30. coeffic chi;
  varname=compress(varname);
  If varname IN ("Intercept") THEN DELETE;
run;


proc sort data=model_vars NODUPKEY;
by name;
RUN;

proc contents data=datcoll.build out =content (KEEP=name type) noprint;




proc sort data=content NODUPKEY; 
by name;
run;



 
data datcoll.model_vars2  ;
  merge model_vars(In=InA) content (In=InB);
   by name;
   if InA ;
run;
 
data model_vars  ;
  merge model_vars(In=InA) content (In=InB);
   by name;
   if InA ;
	If type=2 THEN DELETE;
run;

proc sort data=datcoll.model_vars2 out=sorted_chi;
by descending chi;
run;


data _NULL_;
set modelp;
call symput (name,parametr);
run;




*===============================================;
x "rm model_coarses.sas";
data temp_1;
length type2_1 type2_2 type1_1 type1_2 $80.;
set sorted_chi end=last;

if _N_ =1 then do;
	file "model_coarses.sas" OLD;	
	put " %include '../parameters_pg1.sas' ; %include '../top_portion_mc.txt' ; " ;
end;

	file "model_coarses.sas" MOD;



type2_1='%finefct_f(datcoll.build, &perf_collin. ,BAD,0,0,GOOD,1,1, &weight4coarse. ,';
type2_2=',,datcoll.summary_coarses);';

type1_1='%finesplt_f(datcoll.build, &perf_collin. ,BAD,0,0,GOOD,1,1, &weight4coarse. ,';
type1_2=',10.1,10,datcoll.summary_coarses);';


/*

if type=. then type=1;
put type1_1 name type1_2;
*/

if type=. then do;
	if substr(name,1,2)='DM' then type=2;
	else type=1;
end;


if type=2 then do;
	put 'title2 "PARAMETER: &' name ' ";' ;
	put type2_1 name type2_2;
end;

else if type=1 then do;
	put 'title2 "PARAMETER: &' name ' ";' ;
	put type1_1 name type1_2;
end;


if last then do;
	put '%desc_f(datcoll.summary_coarses);';
end;

run;

*===========================================;



 DATA _null_;
 length name $30;
 SET datcoll.model_vars2 (KEEP=name) end=last;
 file "variables_in";
 name=compress(" "||upcase(name)||" ");
 if _n_=1 THEN put '%let var_in= ';
 if last THEN do;
  put name ";";  
  call symput("counter", _n_);

 end;
 else put   name " ";
 file "renaming";
 if _n_=1 then put 'rename';
 if last then do;  put   "cvar_" _n_  "=" name ";";end;
 else do;  put   "cvar_" _n_ "=" name;end;

RUN;

%include "variables_in";


data correl;
 set datcoll.build (keep= &var_in. &perf_collin. );
run;

proc printto print= 'collin_erase';
run;
ods trace on;
ods output parameterEstimates=param ;

proc reg data=  correl  ;
model &perf_collin  = &var_in. / vif tol collin;
run;
ods trace off;
proc printto print=print;
run;
 x 'rm collin_erase';

proc sort data=param ;
by  descending varianceinflation ;
run;


proc print data=param;
var variable varianceinflation;
where varianceinflation >= &vifthresh.;
title1 "Consider removing the following variables from your model";
title2 "These variables have correlation problems";
title3 "to remove these variables, add them to drop_mod.txt";
run;


data _null_;
set param;
file 'ResponseTech.out' mod;
if _N_=1 then do;
	put "----------------------------";
	put " Collinearity information ";
	put "----------------------------";
	put "Consider removing the following variables from your model";
	put "These variables have correlation problems (VIF threshold = &vifthresh.)";
	put "to remove these variables, add them to drop_mod.txt";
	put "                                                   ";
	put @1 "VARIABLE" @40 "VARIANCE INFLATION";
end;

if varianceinflation >= &vifthresh. then put @1 variable @40 varianceinflation;
run;
   
title1 "The following variables showed up in the Responsetech model";
title2 "	note: the coarses are on the building sample";

