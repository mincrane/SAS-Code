option nodate nonumber symbolgen mprint mlogic;


libname here ".";    

%let seg1 = /sas/pprd/austin/projects/exposure/investigate/model/modeling/seg1/iteration9;      
%let seg2 = /sas/pprd/austin/projects/exposure/investigate/model/modeling/seg2/iteration3;    
%let seg3 = /sas/pprd/austin/projects/exposure/investigate/model/modeling/seg3/iteration9;    



%macro summary_seg(segNum= );

PROC DATASETS Library=here nolist;
DELETE varlist modelstat;
RUN; 


%do i =1 %to &segNum;


%IF %sysfunc(fileexist("&&seg&i")) = 1 %THEN %DO;

/*** reset Macro variables **/

 %let seed= ;
 %let build=0;
 %let wb=0;
 %let valid=0;
 %let wv=0;
 %let ks_dev=0;
 %let iv_dev=0;
 %let ks_val=0;
 %let iv_val=0;
 %let ks_tot=0;
 %let iv_tot=0;
 %let varNum=0;
 %let mvif=0;
 %let startP=0; 
 %let bad_rate=0;
 %let deci10=0;
 %let deci9=0;
 %let deci8=0;
 
 

filename iter&i "&&seg&i./results.txt";


DATA varlist vif rankorder;
 INFILE iter&i dlm='0D'x dsd ls=1000 recfm=v length=long missover; 
 input @1 _line $varying200. long;
 
 RETAIN var_start_ind  N VIF I rank_order;
 
 
 IF Index(_line,'Iteration')>0 THEN I=1;
 
 /*
 IF index(_line,'Sampling Method:')>0 THEN SM=1;
 IF index(_line,'Sampling Seed')>0 THEN SS=1;
 IF index(_line,'Build Sample Volume')>0 THEN BSV=1;
  IF index(_line,'Weighted Sample Volume')>0 THEN WSV+1;
 IF index(_line,'Validation Sample Volume')>0 THEN VSV=1;
 */
  
 IF I=1 then SampVol+1; 
  
 /** model statistics  **/
 
 IF Index(_line,'Model Summary Statistics')>0 THEN DO;
   N=1;
   I=0;
   SampVol=0;
 END;
 
/** varable list  ***/  
  
 IF Index(_line,'Parameter Estimates')>0 THEN DO;
 	var_start_ind=1;
 	N=0;
 	END;
 	
 IF var_start_ind=1 THEN T+1;
 
 
 IF Index(_line,'Variance Inflation Factor')>0 THEN DO;
 	var_start_ind=0;
 	VIF=1;
 	T=0;
 	END;
 
 /** VIF  **/  
 
 IF VIF=1 THEN F+1;
 IF Index(_line,'*Weight')>0 THEN DO;
 	VIF=0;
  F=0;
  /*STOP;*/ 
 END;
 
 
 /** Rank Order  **/  
 
 IF Index(_line,'Score Distribution (unit)')>0 THEN DO;
 	rank_order=1;
 END;
 	
 IF rank_order=1 THEN ro+1;
 IF rank_order=1 and ro>10 and Missing(_line)=1 THEN STOP;
 
 
 
/*** counts ***/
IF I=1 THEN DO;
	IF Sampvol = 2 THEN call symput ('Samp',scan(_line,2,":"));
	IF Sampvol = 3 THEN call symput ('SEED',scan(_line,2,":"));
	IF Sampvol = 4 THEN call symput ('build',compress(scan(_line,2,":")));
  IF Sampvol = 5 THEN call symput ('wb',scan(_line,2,":"));
	IF Sampvol = 6 THEN call symput ('valid',compress(scan(_line,2,":")));
	IF Sampvol = 7 THEN call symput ('wv',scan(_line,2,":"));
END;

/** statistics **/
 
 IF N=1 THEN DO;
   IF index(_line,'Development')>0 THEN DO; 
     call symput ('ks_dev',scan(_line,2," "));
     call symput ('IV_dev',scan(_line,3," "));
   END; 
    
   IF  index(_line,'Validation')>0 THEN DO;
     call symput ('ks_val',scan(_line,2," "));
     call symput ('IV_val',scan(_line,3," "));
   END;
   
  IF index(_line,'Total')>0 THEN DO;  
    call symput ('ks_tot',scan(_line,2," "));
    call symput ('IV_tot',scan(_line,3," "));
  END;
   
 END;  /** end n=1 **/
 

/***  varlist  VIF Rank Order****/

 IF var_start_ind=1 and T > 5 and missing(_line)=0 THEN OUTPUT varlist;
 IF vif =1 and F>5 and missing(_line) = 0 THEN OUTPUT VIF; 
 IF rank_order = 1 and RO>7 and missing(_line) = 0 THEN OUTPUT RankOrder;
 
RUN;


/** var list ****************************/
data varlist(keep=varName chisqr Seg ce);
set varlist;
length Seg $11;
varName=compress(scan(_line,1," "));
chisqr = input(compress(scan(_line,5," ")),9.4);
ce = input(compress(scan(_line,3," ")),8.4);
Seg= "Seg&i";
run;

proc print data=varlist;
run;

proc sort data = varlist;
	by descending chisqr;
run;

data varlist;
	set varlist;
	order=_n_;
	*drop chisqr;
run;


proc append base=here.varlist data=varlist force;
run;

proc print data=varlist;
run;


proc sql noprint;
select count(varName)into :varNum
from varlist;
quit;
/***************************/
/** VIF ********************/

data VIF(keep=varName Seg vif);
	set VIF;
	length Seg $11.;
	Seg="Seg&i";
	varName = compress(scan(_line,1," "));
	VIF = scan(_line,3," ");
run;

proc sql noprint;
	select max(vif) into : mvif
	from VIF;
quit;

/****************************/
/*** total rank order     **/
x "rm rank_order";

data _null_;
	set rankorder end=last;
	if last;
	total = input(scan(_line,1," "),comma9.);
	event = input(scan(_line,2," "),comma9.);
	non_event = input(scan(_line,3," "),comma9.);
	bad_rate = event/total;
  call symput('bad_rate',bad_rate);
run;


/*
data _NULL_;
	set rankorder;
	file "rank_order";
	put _line;
run;

data rank1 (keep= order1 event_rate);
	infile "rank_order" dlm=" " truncover;
	input a$  b$ c$ total : comma9. event : comma9.  non_eve : comma9. ;
	if missing(total) then delete;
	If total ^= event+non_eve then do;
		put "total counts are not equal to event + no event ";
		Put "Macro Failure ";
		ABORT;
	end;
	
	cum_tot+total;
	cum_event+event;
	cum_noneve+non_eve;
	bad_rate=cum_event/cum_tot;
	event_rate=event/total;
	order1 = _n_;
	call symput('bad_rate',bad_rate);
run;

proc print data=rank1;
run;



proc sort data=rank1 ;
	by  DESCENDING order1; 

run;


data _NULL_;
	set rank1 nobs=nobs;
	if order1=nobs then call symput('deci10',event_rate);
	if order1=nobs-1 then call symput('deci9',event_rate);
	if order1=nobs-2 then call symput('deci8',event_rate);
run;
*/



/******************************/

/*** append seg ks iv ****/

data Modelstat;
length Seg $11;
Seg = "Seg&i"; 
ks_dev=&ks_dev;
iv_dev=&iv_dev;
ks_val=&ks_val;
iv_val=&iv_val;
ks_tot=&ks_tot;
iv_tot=&iv_tot;
varNum=&varNum;
maxVif=&mvif;
bld = input("&build",comma10.);
vld = input("&valid",comma10.);
total = bld+vld;
bad_rate = &bad_rate;
/*
Decile10 = &deci10;
Decile9 = &deci9;
Decile8 = &deci8;
*/
run;


proc append base=here.Modelstat data=Modelstat force;
run;

%END;

%END; /***end iter loop **/

/****************************************************************************************/


proc sort data=here.varlist;
by varName descending order;
run;


proc print data=here.varlist;
run;

proc contents data=here.varlist;

proc transpose data=here.varlist(keep=varName Seg order) out=varTable let;
by VarName;
id Seg;
var order;
run;

proc transpose data=here.varlist(keep=varName Seg ce) out=varTable1 let;
by VarName;
id Seg;
var ce;
run;

proc print data= vartable;
run;

proc print data= vartable1;
run;

data new;
	set vartable;
	keep varname;
run;

%do j = 1 %to &segNum;
	proc sql;
	 create table segm&j as
	 select  a.varname, 
	 (case when a.seg&j ^=. then put(a.seg&j,8.4)||"("||put(b.seg&j,3.)||")"  else " " end) as seg&j 
	 	 from vartable1  a
	 inner join vartable b
	 on a.varName = b.varName;
	quit;
	
 proc sql;
 	create table new as
 	select * from segm&j a
 	right join 
 	new b on 	b.varname = a.varname;
 quit;
	
%end;


proc print data=new;
run;

ods html file="summary_new.xls";

x "rm varlist";

PROC PRINTTO print="varlist";
RUN;
title1;
title2;
title3 "The list of variables in each segment";

data varlist;
length varName $25  Seg1-Seg&i $20;
set new;
run;

proc print data=varlist noobs;
run;

proc printto;
run;

x "rm modelStat";

PROC PRINTTO print="modelStat";
RUN;
title "The statistics of each segment";

proc print data=here.modelstat noobs;
run;

proc printto;
run;

*ods html close;

x "rm Summary_seg";
x "cat modelStat varlist  >> Summary_seg";


x "rm rank_order";

%mend;


%summary_seg(segnum=3);

ods html file = "summary_seg.xls";

proc print data=varlist noobs;
run;

ods html close;
endsas;







/*****************************************************************************/


