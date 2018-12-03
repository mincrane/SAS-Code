
%macro check_para(datin = ,perfvar =,scrvar= ,bad = ,wgtvar = );
/** check parameter **/
%IF %sysfunc(exist(&datin))=0 %THEN %DO;   
 DATA _null_;
  file 'ABORT.MESSAGE';
  put "The Data &datin does not exist";
  abort;
 RUN; 
%END;

%let exist_wgt =  ;
%let exist_perf = ;
%let exist_scr = ;
	
data _NULL_;
 length varname $32.;
 set &datin. (obs=1);
 array nmr {*} _numeric_;
 do i=1 to dim(nmr);
   call vname(nmr{i},varname);
   %IF %length(&wgtvar.) > 0 %THEN %DO;
   if upcase(varname) =upcase("&wgtvar.") then 
   call symput('exist_wgt','Y');
   %END;
   if upcase(varname) =upcase("&perfvar.") then 
   call symput('exist_perf','Y');
   if upcase(varname) = upcase("&scrvar.") then 
   call symput('exist_scr','Y');
 
 end;
run;

%if %length(&wgtvar.)>0 and %length(&exist_wgt.) =0  %then %do;
 data _NULL_;
   file "ABORT.MESSAGE";
   put "&wgt is not exist";
   abort;
 run;
%end;
%if %length(&exist_perf.) = 0  %then %do;
 data _NULL_;
   file "ABORT.MESSAGE";
   put " &perfvar is not exist";
   abort;
 run;
%end;
%if %length(&exist_scr.) = 0  %then %do;
 data _NULL_;
   file "ABORT.MESSAGE";
   put " &scrvar is not exist";
   abort;
 run;
%end;

%let bad_value = Y;
%if %length(&bad) = 0 %then %do;
  %let bad_value = N;
%end;   
%else %if &bad ^= 1 and &bad ^= 0 %then %do;
	%let bad_value = N;
%end;

%if &bad_value = N  %then %do;
 data _NULL_;
   file "ABORT.MESSAGE";
   put "Bad can only have value 0 or 1";
   abort;
 run;
%end;

%mend;


/**************************************************************************/
/** Macro to create KS and IV  ********************************************/
%macro dist_ksiv(datin = ,perf =,bad = ,wgt = ,varname = ,fmt = );
	
   %global ks iv;
	
proc freq data = &datin noprint;
 table &varname*&perf /out = _freq outpct missing;
 %IF %length(&wgt.) > 0 %THEN %DO;
  weight &wgt;
 %END; 
 %IF %length(&fmt.) > 0 %THEN %DO;
 format &varname &fmt..;
 %END;
run;

 data one two;
 set _freq;
 %if &bad = 0 %then %do;
 if &perf = 0 then output one;
 if &perf = 1 then output two;
 %end;
 
 %if &bad = 1 %then %do;
 if &perf = 0 then output two;
 if &perf = 1 then output one;
 %end;
 
 run;

  
data three;
 merge one(rename= (count = bad_count PERCENT= tot_pct_bad  pct_col = bad_pct )) two(rename= (count = good_count percent = tot_pct_good pct_col = good_pct));
 by &varname;
 if missing(bad_pct) = 1 then bad_pct = 0;
 if missing(good_pct) = 1 then good_pct = 0;
 if missing(bad_count) = 1 then bad_count = 0;
 if missing(good_pct) = 1 then good_count = 0;
 
 epi = 1e-5 ; 
 
 tot_cnt = good_count+bad_count;
 tot_pct = tot_pct_bad + tot_pct_good;
 
 cum_good+good_count;
 cum_bad+bad_count;
  
 
 cum_goodpct + good_pct;
 cum_badpct + bad_pct;

 _ks = abs(cum_goodpct - cum_badpct);

_weight=log(sum(good_pct,epi)/sum(bad_pct,epi));
_ivalue = (good_pct-bad_pct)/100 * _weight;
_cumiv+_ivalue;
run;

/*
proc print data = three;
run;
*/

proc sql noprint;
	select max(_ks), max(_cumiv) into : KS , :IV
	from three;
quit;	 
%mend;

/******** macro for score fmt for score distribution *********/

%macro scrfmt(datin = , perfvar = ,bad = ,wgt = ,scrvar = ,bins = );

/**************************************************************************************/
/*
%IF %sysfunc(exist(curr.univ_num)) = 1 or %sysfunc(exist(curr.univ_char))= 1 %THEN %DO;
proc datasets lib = curr;
	delete univ_num univ_char univ_char_gt30;
run;
%END;
*/


%let partsize= %sysevalf( 100 / &bins );

PROC UNIVARIATE DATA= &datin.  NOPRINT; 
     VAR &scrvar.; 
     %IF %length(&wgt.) > 0 %THEN %DO;
      weight &wgt;
     %END;
     output out=_univ pctlpre= P pctlpts=  &partsize. to 100 by &partsize.;
run;


/** calculate bins for KS and IV **/
data bin ;
	set _univ(keep = p:);
run;	

proc transpose data = bin out = pct_t;
run;	
	
	
proc sort data=pct_t nodupkey;
  	by col1;
  run;

/*  
proc print data = pct_t;
run;
*/ 
  
 data binfmt;
  	set pct_t(rename=(col1=_end)) end = last;
  	_start= lag1(_end);
  	length label $20;
  	
    start= input(putn(_start,15.4),15.4);
  	end= input(putn(_end,15.4),15.4);
  		
  	retain fmtname "binfmt" type 'n';
  	
  	if _n_=1 then do;
  	  hlo='L'; sexcl='N'; eexcl='N'; label= "LOW  - "||strip(end); output;
    end;
    
    else if not last then do;
    	hlo= ' '; sexcl= 'Y'; eexcl= 'N'; label= strip(start)||" <- "||strip(end); output;
    end;
    
    else if last then do;
    	hlo= 'H'; sexcl='Y'; eexcl= 'N'; label= strip(start)||" <- HIGH"; output;
    	end=.; start= .; hlo= 'O'; label= "MISSING"; output; 
    end;
    
    drop _name_ _start _end ;
    
  run;
  
 proc format library=work cntlin= binfmt;
 run;

/*
proc print data = binfmt;
run;
*/

%dist_ksiv(datin = &datin,perf = &perfvar ,bad = &bad ,wgt =&wgt ,varname = &scrvar. , fmt = binfmt);

%mend;

