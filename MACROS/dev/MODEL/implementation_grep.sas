/*** this code is for grepping score formula, gensq_call and WOE var calculation implementation ***/


option nodate nonumber symbolgen mprint mlogic;


libname here ".";    


%let seg1 = /sas/pprd/austin/models/dev/onboard/us/modeling/RI/seg1/all_good_bad_model_pg8/iteration14;      
%let seg2 = /sas/pprd/austin/models/dev/onboard/us/modeling/RI/seg2/all_good_bad_model_pg8/iteration31;     
%let seg3 = /sas/pprd/austin/models/dev/onboard/us/modeling/RI/seg3/all_good_bad_model_pg8/iteration27;

%let seg4 = /sas/pprd/austin/models/dev/onboard/us/modeling/RI/seg4/all_good_bad_model_pg8/iteration33;   
%let seg5 = /sas/pprd/austin/models/dev/onboard/us/modeling/RI/seg5/all_good_bad_model_pg8/iteration22;   
%let seg6 = /sas/pprd/austin/models/dev/onboard/us/modeling/RI/seg6/all_good_bad_model_pg8/iteration15;   


%macro implementation_grep(segNum= );

/*
PROC DATASETS Library=here nolist;
DELETE varlist modelstat;
RUN; 
*/

/*** initialize model_formula, model_gensq, model_woe and model_all_var ***/

x "rm model_formula";
x "rm model_gensq";
x "rm model_woe";
x "rm model_all_var";




x "echo ' ' >> model_gensq";
x "echo please check model_all_var and 2_run_model.sas for WOE var and manully created vars >> model_gensq";
x "echo ' ' >> model_gensq";
x "echo ' ' >> model_gensq";


%do i =1 %to &segNum;


%IF %sysfunc(fileexist("&&seg&i")) = 1 %THEN %DO;

/*** grep score formula and variable list **/

filename formula&i "&&seg&i./formula.txt";

DATA varlist;
 INFILE formula&i dlm='0D'x dsd ls=1000 recfm=v length=long missover; 
 input @1 _line $varying200. long;
 
 
  if index(_line,'*')> 0 then do;
   var = compress(upcase(scan(_line,2,'*')));
   keep var;
   output;
  end;
run;

proc print data=varlist;
run;  
  
x "echo seg&i : >> model_formula"; 

x "cat &&seg&i/formula.txt  >> model_formula";


/**** grep gensq  *******************/

filename gensq&i  "&&seg&i./gensq_call.sas";

DATA gensq;
 INFILE gensq&i dlm='0D'x dsd ls=1000 recfm=v length=long missover; 
 input @1 _line $varying200. long;
 
 length var_temp $100;
 length var $35;  
  
 var_temp= scan(_line,1,',');
 var=compress(upcase(scan(var_temp,2,'=')));
 keep var _line;
run; 
  

proc sort data=varlist;
	by var;
run;

proc sort data=gensq;
	by var;
run;

data gensq_model;
	merge varlist(in=a) gensq(in=b);
	by var;
	
	if a and b then flag=1;
	if a and b = 0 then flag=2;
	if a=0 and b then flag=3;
	if flag=2 then var1="WOE or manually created Var";
run;


/*****1. create model_all_var      ***/

x "rm allvar";

proc printto print= 'allvar';
run;

title1 " ";
title2 "Seg&i";
title3 ;


PROC REPORT DATA=gensq_model HEADLINE NOWD SPLIT='/';

column var var1; 
define var /SPACING =3 DISPLAY WIDTH=25 'Variable Name' LEFT;
define var1 /SPACING =3 DISPLAY WIDTH= 200 'WOE or Created /at 2_run_model' LEFT;

where flag in (1,2);

run;

proc printto;
run;

x "cat allvar  >> model_all_var";
x "echo       >> model_all_var";




/*** 2. output gensq  for modeling variables***/

x "rm gensq";

proc printto print= 'gensq';
run;

title1 " ";
title2 "Seg&i";
title3 ;

PROC REPORT DATA=gensq_model HEADLINE NOWD SPLIT='/';

column var _line;
define var /SPACING =3 DISPLAY WIDTH=25 'Variable Name' LEFT;
define _line /SPACING =3 DISPLAY WIDTH= 200 'FORMULA' LEFT;

where flag=1;

run;

/*
proc print data=gensq_model noobs label;
	var var _line;
	where flag=1;
run;
*/

proc printto;
run;


x "cat gensq  >> model_gensq";
x "echo       >> model_gensq";


/*** grep WOE Variables  flag =2 ***/

proc sql;
	select substr(var,2) into : woevar separated by  " "
	from gensq_model
	where flag=2; /* and upcase(substr(var,1,1)) = 'W' */
quit;

filename woe&i  "&&seg&i./flag_logic.txt";

DATA woe_all;
 INFILE woe&i dlm='0D'x dsd ls=1000 recfm=v length=long missover; 
 input @1 _line $varying200. long;
 
  
	%let j=1;

		%do %while (%scan(&woevar,&j) ne );
			%let wvar = %scan(&woevar,&j);
		 	if index(upcase(_line), compress(upcase("&wvar"))) > 0 then index_woe = 1;
    	%let j=%eval(&j+1); 
 		%end;
 
 if index_woe =1; 
 keep  _line;

run; 

x "rm woe";

proc printto print= 'woe';
run;

title1 " ";
title2 "Seg&i";
title3 ;

PROC REPORT DATA=woe_all HEADLINE NOWD SPLIT='/';

column _line;

define _line /SPACING =3 DISPLAY WIDTH= 200 'WOE FORMULA' LEFT;

run;


proc printto;
run;


x "cat woe  >> model_woe";
x "echo       >> model_woe";



%end;/** end if ***/

%end;  /*** end i  segment ***/

%mend;

%implementation_grep(segnum=6);

endsas;


