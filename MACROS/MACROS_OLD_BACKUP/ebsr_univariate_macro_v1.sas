options compress=yes obs=max ls=max ps=max pageno=1 errors=10; /* nocenter symbolgen mlogic mprint;*/


libname curr '.';

/*
	proc format;
		value $DRPFLG "0" = '0 - Do not drop'
		              "1" = '1 - 99+% missing'
		              "2" = '2 - Constant non-missing value'
		              "3" = '3 - 95% same non-missing value'
		              "4" = '4 - Possible key'
		;
	run;
*/

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


%macro univ(datin = , perfvar = ,bad = ,wgt = ,exclout = ,datout = );

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
	
data _NULL_;
 length varname $32.;
 set &datin. (obs=1);
 array nmr {*} _numeric_;
 do i=1 to dim(nmr);
   call vname(nmr{i},varname);
   %IF %length(&wgt.) > 0 %THEN %DO;
   if upcase(varname) =upcase("&wgt.") then 
   call symput('exist_wgt','Y');
   %END;
   if upcase(varname) =upcase("&perfvar.") then 
   call symput('exist_perf','Y');
 
 end;
run;

%if %length(&wgt.)>0 and %length(&exist_wgt.) =0  %then %do;
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

/**************************************************************************************/
%IF %sysfunc(exist(curr.&datout._num)) = 1 or %sysfunc(exist(curr.&datout._char))= 1 %THEN %DO;
proc datasets lib = curr;
	delete &datout._num &datout._char &datout._char_gt30;
run;
%END;

/** create variable list **/
%let charvar = ;

proc contents data = &datin out = _name(keep = name type) noprint;
run;

proc sql noprint;
	select name into : numvar separated by ' ' 
	from _name
	where type = 1;
quit;

proc sql noprint;
	select name into : charvar separated by ' ' 
	from _name
	where type = 2;
quit;

/**** univariate for Numeric variables *****/
%let listindex = 1;
%do %until (%scan(&numvar,&listindex) eq) ;

%let var_numeric = %scan(&numvar,&listindex);


PROC UNIVARIATE DATA= &datin.  NOPRINT; 
     VAR &var_numeric.; 
     %IF %length(&wgt.) > 0 %THEN %DO;
      weight &wgt;
     %END;
     
     OUTPUT OUT=alluniv SUMWGT= wgtN N=N  NMISS=NMISS STD=STD MEAN=MEAN MAX=MAX MIN=MIN 
     PCTLPTS = 0 1 5 10 20 30 40 50 60 70 80 90 95 99 100 PCTLPRE = P  ;
run;


/** calculate bins for KS and IV **/
data bin ;
	set alluniv(keep = p0 p10 p20 p30 p40 p50 p60 p70 p80 p90 p100);
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
  	
    start= input(putn(_start,18.5),18.5);
  	end= input(putn(_end,18.5),18.5);
	
	end1 = end; /* for special missing **/
  		
  	retain fmtname "binfmt" type 'n';
  	
  	if _n_=1 then do;
	    /** for special missing **/
	
	    start = .A; end =.A ; Label = 'A'; output;
		start = .B; end =.B ; Label = 'B'; output;
		start = .C; end =.C ; Label = 'C'; output;
		start = .D; end =.D ; Label = 'D'; output;
		start = .E; end =.E ; Label = 'E'; output;
		start = .F; end =.F ; Label = 'F'; output;
		start = .M; end =.M ; Label = 'M'; output;
		start = . ; end =.  ; Label = 'Missing'; output;
		end = end1;
	   /***************************/	
	   if end ^=. then do; hlo='L'; sexcl='N'; eexcl='N'; label= "LOW  - "||strip(end); output; end; 
		else  do;  hlo='L'; sexcl='N'; eexcl='N' ;end = 0; label= "LOW  - 0"; output; end; /** all missing **/
    end;
    
    else if not last then do;
    	hlo= ' '; sexcl= 'Y'; eexcl= 'N'; label= strip(start)||" <- "||strip(end); output;
    end;
    
    else if last then do;
    	hlo= 'H'; sexcl='Y'; eexcl= 'N'; label= strip(start)||" <- HIGH"; output;
    	hlo= 'O'; label= "Other"; output; 
	end;
    
    drop _name_ _start _end _label_;
    
  run;
  
 proc format library=work cntlin= binfmt;
 run;

 /*
 proc format;
 value testfmt
 .A = 'A'
 .E = 'E'
 other = [binfmt];
run; 

proc format cntlout = fmtout;
run;

proc print data = fmtout;
run;


proc print data = binfmt;
run;

*/


%put &var_numeric.;
%dist_ksiv(datin = &datin,perf = &perfvar ,bad = &bad ,wgt =&wgt ,varname = &var_numeric. , fmt = binfmt);


/** calculate univariate **/
data univ_num;
	set alluniv(keep= wgtn n nmiss std mean min p1 p5 p10 p20 p30 p40 p50 p60 p70 p80 p90 p95 p99 max);
  length varname $32 ;
  pctmiss =100*nmiss/(n+nmiss);
  varname = "&var_numeric.";
  ks = &ks;
  iv = &iv;
  if (nmiss/(n+nmiss)) >= .99 then drop_flag= "1";
	 else if min = max and nmiss=0 then drop_flag= "2";
	 else if min=P95 or P5= max then drop_flag= "3";
	 else if mean = 0 then drop_flag= "4";
	 else drop_flag= "0";

run;
  

proc append base = curr.&datout._num data = univ_num;
run; 

%let listindex = %eval(&listindex+1);
%end;


/**************************************************************************************************/
/**************************************************************************************************/
/**** char univariate ***/
 %IF %length(&charvar.) > 0 %THEN %DO;

%let listindex = 1;
%do %until (%scan(&charvar,&listindex) eq) ;

%let var_char = %scan(&charvar,&listindex);


/*** Char Var freq  ***/
/** Step 1: test if the var is ID;  If more than 30 no coarse output; **/

proc sql noprint;
  select count(*),count(distinct &var_char), sum(case when missing(&var_char.) = 1 then 1 else 0 end) into: totalobs, :NumGroup ,:Num_miss
  from &datin;
quit; 

%if &numgroup <= 30 %then %do;

%dist_ksiv(datin = &datin ,perf = &perfvar,bad = &bad,wgt = &wgt , varname =&var_char , fmt= );

/** calculate group: ks iv numobs numgroup missing top 3 group C1 C2 C3 C4 Other **/


%let p1 = 0;
%let p2 = 0;
%let p3 = 0;
%let p4 = 0;
%let c1 =  ;
%let c2 =  ;
%let c3 =  ;
%let c4 =  ;


proc sql noprint;
	
	select &var_char,good_pct into : c1 - :c4 , :p1- :p4 
	from three
	order by good_pct descending ;
quit;


data univ_char;
	length varname $25 ks iv num_record group missing pctmiss 8 c1 $10 p1 8 c2 $10 p2 3  c3 $10 p3 3 c4 $10 p4 3 c5 $10 p5 3;
	varname = "&var_char.";
	ks = &ks;
	iv = &iv;
	num_record = &totalobs;
	group = &numgroup;
	missing = &num_miss;
	pctmiss = missing/num_record;
	c1 = "&c1";
	p1 = &p1;
	c2 = "&c2";
	p2 = &p2;
	c3 = "&c3";
	p3 = &p3;
	c4 = "&c4";
	p4 = &p4;
	C5  = 'Other';
	p5 = 100- (p1+p2+p3+p4);

run;	

proc append base = curr.&datout._char data = univ_char force;
run; 

%end; /** end numgroup <30 **/
%else %do;
data univ_char_gt30;
	varname = "&var_char.";
	num_record = &totalobs;
	group = &numgroup;
	missing = &num_miss;
	pctmiss = missing/num_record;
run;	

proc append base = curr.&datout._char_gt30 data = univ_char_gt30 force;
run; 

%end;

%let listindex = %eval(&listindex+1);
%end ; 

%end; /** end char **/

/************ output ****************/
/*
proc sql;
select varname,n as num,nmiss as nmiss,pctmiss,ks,iv,mean as average,min as minvar,p1 as p1,p10,p50,p90,p99,max
from curr.&datout._num;
quit;
*/

ods _all_ close;
ods tagsets.ExcelXP path='.' file= "&exclout..xml" style=Printer;

/*
title "The univarite of data &datin ";
footnote '(this is a test)';
*/
* Set some "global" tagset options that affect all worksheets;
ods tagsets.ExcelXP options(embedded_titles='yes'
embedded_footnotes='yes'
print_header='header'
print_footer='footer'

/*print_header='&C&A&RPage &P of &N'
print_footer='&RPrinted &D at &T' */
autofilter='2-4');


ods tagsets.ExcelXP options(sheet_name='Numeric Univ' );

title "The univariate for data &datin created at &SYSDATE9.";
title2 'The univariate of Numeric Var ';

footnote1 '0 - do not drop';
footnote2 '1 - 99% of missing';
footnote3 '2 - Same value';
footnote4 '3 - 95% same value';



PROC PRINT DATA=curr.&datout._num SPLIT='*' noobs;
      VAR  varname drop_flag ks iv n wgtN nmiss pctmiss mean min p1 p5 p10 p20 p30 p40 p50 p60 p70 p80 p90 p95 p99 max;
      LABEL  varname = "VARIABLE" drop_flag="DROP *FLAG" KS= 'KS  ' iv='Information*Value' n = 'Num' wgtn = 'Weighted *Num' nmiss = '# of Missing' pctmiss = 'Pct Missing'
             mean = 'MEAN' min = 'MIN' p1 = 'P1' p5 ='P5' p10 = 'P10' p20 = 'p20' p30 = 'P30' p40 = 'P40' p50 = 'P50' p60 = 'P60' p70 = 'P70' p80 = 'P80' p90 = 'P90' p95 = 'P95' p99 = 'P99'
             max = 'MAX';			 
      FORMAT n wgtn 9.0;
      FORMAT pctmiss iv 5.3;
      FORMAT ks 8.1;

run;		



%IF %sysfunc(exist(curr.&datout._char))=1 %THEN %DO;
ods tagsets.ExcelXP options(sheet_name='Char Univ');
title 'The univariate of Char Var';
footnote '';


PROC PRINT DATA=curr.&datout._char SPLIT='*' noobs;
      VAR  varname ks iv num_record group missing pctmiss c1 p1 c2 p2 c3 p3 c4 p4 c5 p5;
      LABEL  varname = "VARIABLE" KS= 'KS    ' iv='Information*Value' num_record = 'Num' group = 'GROUP' missing = 'NMISS' pctmiss = 'Pct Missing' C1 = 'CAT1' P1 = 'FREQ1'
      c2 = 'CAT2' p2 = 'FREQ2' c3 = 'CAT3' p3 = 'FREQ3' c4 = 'CAT4' p4 = 'FREQ4' c5 = 'OTHER' p5 = FREQ*OTHER ; 
     
      FORMAT num_record 9.0;
      FORMAT pctmiss iv 5.3;
      FORMAT ks p1 p2 p3 p4 p5 8.1;

run;		
%END;


%IF %sysfunc(exist(curr.&datout._char_gt30))=1 %THEN %DO;
ods tagsets.ExcelXP options(sheet_name='Other');
title 'Char Var has more than 30 unique values';
footnote '(*Run risk grouping first or single var coarse)';


PROC PRINT DATA=curr.&datout._char_gt30 SPLIT='*' noobs;
      VAR  varname num_record group missing pctmiss ;
      LABEL  varname = "VARIABLE" num_record = 'Num' group = 'GROUP' missing = '# of MISS' pctmiss = 'Pct Missing' ; 
      
      FORMAT num_record 9.0;
      FORMAT pctmiss iv 5.3;
      
run;		

%END;

ods tagsets.ExcelXP close;



%MEND;
