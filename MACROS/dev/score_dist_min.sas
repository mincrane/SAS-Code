
options symbolgen mprint mlogic formdlim='-' nocenter merror errorabend;

/*
libname here ".";
libname here ".";
libname dat1 "..";
libname dat '/raid01/Consortium_Model/EDS_Model_V1.0/DATA/COMBINED';
*/


%MACRO Score_dist_m(DATASET,VAR,TITLE1,RNGBDL,RNGBDH,TITLE2,RNGGDL,RNGGDH,
      MLTPLY,CHAR,FORMAT);

            %global _ks _ival _concord _discord _tie;
            
      PROC FORMAT;
      VALUE PRFFMT
      &RNGBDL-&RNGBDH=' 0'
      &RNGGDL-&RNGGDH=' 1'
      OTHER=' 9';
      RUN;
      PROC FREQ DATA=&DATASET(keep= &var &char &mltply) order=formatted;
      TABLES &VAR*&CHAR / NOPRINT OUT=zero;
      %if %length(&mltply) gt 0 %then %do;
      WEIGHT &MLTPLY;
      %end;
      FORMAT &CHAR &FORMAT.;
      FORMAT &VAR PRFFMT.;
      
      /** add raw good and raw bad **/
      PROC FREQ DATA=&DATASET(keep= &var &char) ;
      TABLES &VAR*&CHAR / NOPRINT OUT=raw;
      FORMAT &CHAR &FORMAT.;
      FORMAT &VAR PRFFMT.;
      run;
      
            
       proc sort data=raw;
       by &char;
       run;
           
     
     
     proc transpose data=raw out=raw1;
			by  &char;
			var count;
			id  &var;
			run;
      
               
      
      data one;
        set zero;
      format &var 4.;
      if ( (&var ge &rngbdl) and (&var le &rngbdh) ) then &var=0;
      else if ( (&var ge &rnggdl) and (&var le &rnggdh) ) then &var=1;
      else delete;
      DATA BAD(DROP=NOGOOD) GOOD(DROP=NOBAD);
      SET ONE;
      IF (&VAR=0) THEN NOBAD=COUNT;
      ELSE NOGOOD=COUNT;
      IF (&VAR=0) THEN OUTPUT BAD;
      ELSE OUTPUT GOOD;
      RUN;
      PROC MEANS DATA=ONE NOPRINT;
      VAR COUNT; BY &VAR;
      OUTPUT OUT=SUMMARY SUM=NBYPRF;
      PROC SORT DATA=BAD;
      BY &CHAR;
      PROC SORT DATA=GOOD;
      BY &CHAR;
      
      PROC SORT DATA=RAW1;
      BY &CHAR;
      
      DATA FINAL1;
      MERGE GOOD BAD RAW1(keep= _0 _1 &char);
      BY &CHAR;
      
      DATA FINAL;
      SET FINAL1 end=ENDFL;

      retain cumgd cumbd cumngd cumnbd _ks ;

      IF (NOGOOD LE 0) THEN NOGOOD=0;
      IF (NOBAD  LE 0) THEN NOBAD=0;
      N=1;
      SET SUMMARY POINT=N;
           TOTBAD=NBYPRF;
      N=2;
      SET SUMMARY POINT=N;
           TOTGOOD=NBYPRF;
      PGOOD=NOGOOD/TOTGOOD;
      PBAD=NOBAD/TOTBAD;
      CUMGD+PGOOD;
      CUMBD+PBAD;
      CUMNBD+NOBAD;
      CUMNGD+NOGOOD;
      totalObs=TOTBAD+TOTGOOD;
			total=Nogood+Nobad;
      cumtotal+total;	
      badRate=nobad/total; 
      cumPect=cumTotal/totalObs;   
      
      
       if pgood le 0 then pgood=0.00001;                
       if pbad le 0 then pbad=0.00001;                  
        _weight=log(pgood/pbad);                         
        _ivalue = (pgood-pbad)* _weight;                 
        _cumiv+_ivalue; 
        
         absdif =100*abs(CUMGD-CUMBD);
         if  (absdif gt _ks) then _ks = absdif;                                   
        if endfl eq 1 then do;                            
          call symput('_ival',compress(put(_cumiv,12.3))); 
          call symput('_ks',compress(put(_ks,6.1)));
        end;                                               
      
   /*** total passing, effectiveness table *************/
   
  retain tmp_good tmp_bad tmp_tot;
   if _n_=1 then do;
    total_pass = totalObs;
    good_pass = totgood;
    bad_pass = totbad;
    tmp_good = nogood;
    tmp_bad = nobad;
    tmp_tot = total;
   end;
   else do;
   total_pass +(-1*tmp_tot);
   tmp_tot=total;
   good_pass + (-1*tmp_good);
   tmp_good=nogood;
   bad_pass + (-1*tmp_bad);
   tmp_bad = nobad; 
   end;
   
   tot_pass_pct  =total_pass/totalObs;
   good_pass_pct =good_pass/totgood;
   bad_pass_pct  =bad_pass/totbad;
   interval_good_rate=nogood/total;
   interval_bad_rate=nobad/total;
   pass_good_rate= good_pass/total_pass;
   pass_bad_rate = bad_pass/total_pass;
   interval_odds = DIVIDE(interval_good_rate,interval_bad_rate);
   interval_pct= total/totalobs;
 run;
  
  
    proc sort data=final out=grouped; by &char;

     proc print data=grouped split='*';
     var &char nogood nobad pgood pbad _weight cumgd cumbd _ivalue total _0 _1 cumngd cumnbd cumtotal badrate cumpect ;
     label  &char="&char"  nogood="WEIGHTED*&title2" nobad="WEIGHTED &title1"
     pgood="PROB.*&title2" pbad="PROB.*&title1" _weight="WEIGHT*PATTERN"
     cumgd="CUM.*&title2" cumbd="CUM.*&title1" _ivalue="INFORMATION*VALUE" total="TOTAL" _0="Unweighted*&title1" _1="Unweighted*&title2"
     cumngd="CUMNUM.*&title2" cumnbd="CUMNUM.*&title1" CUMtotal="CUM*TOTAL" cumpect="CUM*perc";
     sum _ivalue nogood nobad pgood pbad cumpect _0 _1;
     format nogood nobad _0 _1 total cumngd cumnbd cumtotal best10.0;
     format pgood pbad _weight _ivalue cumgd cumbd badrate cumpect 5.3;
	   * title5 " ";
		 title6 "KS Value : &_ks";
		 *title7 "Gamma Value: &_gamma";
		 title8 "Information Value:  &_ival";
     RUN;
     
     
title 'DECILE TABLE';                       
title2 "Date Created:  &sysdate ";                                   
title3 ' ';                                   
title4 "KS Value: &_ks"; 
title6 "INFORMATION VALUE: &_ival";                          
  

PROC REPORT DATA=grouped HEADLINE NOWD SPLIT='/';    
column  &char total total_pass interval_pct tot_pass_pct nobad bad_pass nogood good_pass;
        
define   total   / SPACING=1 DISPLAY WIDTH=10 FORMAT=10.0 'Cell/Count' CENTER ; 		  
define   total_pass /SPACING=1 WIDTH=10 DISPLAY  FORMAT=10.0 '# Total/Passing' CENTER ;
define   interval_Pct / SPACING=1 WIDTH=10 DISPLAY  FORMAT=percent8.2 'Cell/Percent' CENTER ;
define   tot_pass_pct / SPACING=1 WIDTH=10 DISPLAY FORMAT= percent8.2 '% Total/passing' CENTER;
define   nobad /DISPLAY SPACING=1 WIDTH=10 DISPLAY  FORMAT=10.0 "# Bad" CENTER ;
define   bad_pass /DISPLAY SPACING=1 WIDTH=10 DISPLAY  FORMAT=10.0 "# Bad / passing" CENTER ;
define   nogood /DISPLAY SPACING=1 WIDTH=8 DISPLAY  FORMAT=10.0 "# Good" CENTER ;
define   good_pass /DISPLAY SPACING=1 WIDTH=10 DISPLAY  FORMAT=10.1 "# Good/Passing" CENTER ;
define   &char / order order=internal WIDTH=20 CENTER;
*break after &char /skip;
RUN;    
     

title 'EFFECTIVENESS TABLE';                       
title2 "Date Created:  &sysdate ";                                   
title3 ' ';                                   
title4 "KS Value: &_ks"; 
title6 "INFORMATION VALUE: &_ival";                          
  

PROC REPORT DATA=grouped HEADLINE NOWD SPLIT='/';    
column  &char total_pass tot_pass_pct nogood good_pass good_pass_pct nobad bad_pass bad_pass_pct interval_good_rate 
pass_good_rate interval_bad_rate pass_bad_rate interval_odds;
        
*define   total   / SPACING=1 DISPLAY WIDTH=10 FORMAT=10.0 'Cell/Count' CENTER ; 		  
define   total_pass /SPACING=1 WIDTH=15 DISPLAY  FORMAT=10.0 'Total Above Low End' CENTER ;
define   tot_pass_pct / SPACING=1 WIDTH=15 DISPLAY FORMAT= percent8.2 '% Total at or/Above Low End' CENTER;
define   interval_good_rate / SPACING=1 WIDTH=10 DISPLAY  FORMAT=percent8.2 'Interval/Good Rate' CENTER ;
define   interval_bad_rate / SPACING=1 WIDTH=10 DISPLAY  FORMAT=percent8.2 'Interval/Bad Rate' CENTER ;
define   pass_good_rate / SPACING=1 WIDTH=15 DISPLAY  FORMAT=percent8.2 'Good Rate at or/Above Low End' CENTER ;
define   pass_bad_rate / SPACING=1 WIDTH=15 DISPLAY  FORMAT=percent8.2 'Bad Rate at or/Above Low End' CENTER ;
define   interval_odds / SPACING=1 WIDTH=10 DISPLAY  FORMAT=8.1 'Interval/Odds' CENTER ;
define   nobad /DISPLAY SPACING=1 WIDTH=10 DISPLAY  FORMAT=10.0 "# Bad" CENTER ;
define   bad_pass /DISPLAY SPACING=1 WIDTH=15 DISPLAY  FORMAT=10.0 "Bad at or/Above Low End" CENTER ;
define   bad_Pass_Pct / SPACING=1 WIDTH=15 DISPLAY  FORMAT=percent8.2 "% Bad at or/Above Low End" CENTER ;
define   nogood /DISPLAY SPACING=1 WIDTH=8 DISPLAY  FORMAT=10.0 "# Good" CENTER ;
define   good_pass /DISPLAY SPACING=1 WIDTH=15 DISPLAY  FORMAT=10.1 "Good at or/Above Low End" CENTER ;
define    good_pass_pct / SPACING=1 WIDTH=15 DISPLAY  FORMAT=percent8.2 '% Good at or/Above Low End' CENTER ;
define   &char / order order=internal WIDTH=20 CENTER;
*break after &char /skip;
RUN;    

/*
title 'COARSES TABLE';                       
title2 "Date Created:  &sysdate ";                                   
title3 ' ';                                   
title4 "KS Value: &_ks"; 
title6 "INFORMATION VALUE: &_ival";                          
  

PROC REPORT DATA=grouped HEADLINE NOWD SPLIT='/';    
column  &char total_pass tot_pass_pct nogood good_pass good_pass_pct nobad bad_pass bad_pass_pct interval_good_rate 
pass_good_rate interval_bad_rate pass_bad_rate interval_odds;
        
*define   total   / SPACING=1 DISPLAY WIDTH=10 FORMAT=10.0 'Cell/Count' CENTER ; 		  
define   total_pass /SPACING=1 WIDTH=15 DISPLAY  FORMAT=10.0 'Total Above Low End' CENTER ;
define   tot_pass_pct / SPACING=1 WIDTH=15 DISPLAY FORMAT= percent8.2 '% Total at or/Above Low End' CENTER;
define   interval_good_rate / SPACING=1 WIDTH=10 DISPLAY  FORMAT=percent8.2 'Interval/Good Rate' CENTER ;
define   interval_bad_rate / SPACING=1 WIDTH=10 DISPLAY  FORMAT=percent8.2 'Interval/Bad Rate' CENTER ;
define   pass_good_rate / SPACING=1 WIDTH=15 DISPLAY  FORMAT=percent8.2 'Good Rate at or/Above Low End' CENTER ;
define   pass_bad_rate / SPACING=1 WIDTH=15 DISPLAY  FORMAT=percent8.2 'Bad Rate at or/Above Low End' CENTER ;
define   interval_odds / SPACING=1 WIDTH=10 DISPLAY  FORMAT=8.1 'Interval/Odds' CENTER ;
define   nobad /DISPLAY SPACING=1 WIDTH=10 DISPLAY  FORMAT=10.0 "# Bad" CENTER ;
define   bad_pass /DISPLAY SPACING=1 WIDTH=15 DISPLAY  FORMAT=10.0 "Bad at or/Above Low End" CENTER ;
define   bad_Pass_Pct / SPACING=1 WIDTH=15 DISPLAY  FORMAT=percent8.2 "% Bad at or/Above Low End" CENTER ;
define   nogood /DISPLAY SPACING=1 WIDTH=8 DISPLAY  FORMAT=10.0 "# Good" CENTER ;
define   good_pass /DISPLAY SPACING=1 WIDTH=15 DISPLAY  FORMAT=10.1 "Good at or/Above Low End" CENTER ;
define    good_pass_pct / SPACING=1 WIDTH=15 DISPLAY  FORMAT=percent8.2 '% Good at or/Above Low End' CENTER ;
define   &char / order order=internal WIDTH=20 CENTER;
*break after &char /skip;
RUN;    
*/

       
%mend;

/*

proc format;
value totFmt
  low     -  2.53395="low     -  2.53395"
  2.53395 <- 3.11703="2.53395 <- 3.11703"
  3.11703 <- 3.54475="3.11703 <- 3.54475"
  3.54475 <- 3.89923="3.54475 <- 3.89923"
  3.89923 <- 4.21383="3.89923 <- 4.21383"
  4.21383 <- 4.48997="4.21383 <- 4.48997"
  4.48997 <- 4.78292="4.48997 <- 4.78292"
  4.78292 <- 5.09378="4.78292 <- 5.09378"
  5.09378 <- 5.48626="5.09378 <- 5.48626"
  5.48626 <- HIGH   ="5.48626 <- HIGH"
   ;
Value bldfmt 
 low     -  2.50551=" low     -  2.50551"
 2.50551 <- 3.10722=" 2.50551 <- 3.10722"
 3.10722 <- 3.52116=" 3.10722 <- 3.52116"
 3.52116 <- 3.88814=" 3.52116 <- 3.88814"
 3.88814 <- 4.19802=" 3.88814 <- 4.19802"
 4.19802 <- 4.47161=" 4.19802 <- 4.47161"
 4.47161 <- 4.76971=" 4.47161 <- 4.76971"
 4.76971 <- 5.07768=" 4.76971 <- 5.07768"
 5.07768 <- 5.47940=" 5.07768 <- 5.47940"
 5.47940 <- HIGH   =" 5.47940 <- HIGH"  ;
 
run;


data new2;
set here.scorbld here.scorvld;
run;

%score_dist_m(new2,newperf_transwindow_risk,bad,0,0,good,1,1,wgt,score,totfmt.); 

endsas;
Score_dist_m(DATASET,VAR,TITLE1,RNGBDL,RNGBDH,TITLE2,RNGGDL,RNGGDH,MLTPLY,CHAR,FORMAT);

*/

/********************************************************************************************/
/********************************************************************************************/
%macro trash;
proc format cntlout=fmtset; 
value good 
	1='Good' 
	0='Bad'; 
run; 
 
%decile_se(dat.scorbld, &weight, score, &perf, fmtset, 10, dec_bld.out, dec_bld.txt, 1, 
        dec_bld_xls);  

 
%macro decile_se(indat,weight,var,perf,cntlout,pieces,fileout,frmtout,zerof,frmin);

%global gb_total bad good good_pass bad_pass zerof2;
%let zerof2 = &zerof ;


title2 "Scoring out the dataset: &indat";
title3 "Requested &pieces cells.";

data zero;
  set &indat (keep = &var &perf &weight);
run;

proc means data = zero noprint ;
  %if %length(&weight) gt 0 %then %do;
  weight &weight;
  %end;
  output out=tmpcnt ;
run;

data _null_;
  set tmpcnt;
  %if %length(&weight) gt 0 %then %do;
    if _STAT_ eq 'SUMWGT' then do;
      call symput('nobs',compress(put(&var,18.5)));
    end;
  %end;
  %else %do;
    if _STAT_ eq 'N' then do;
      call symput('nobs',compress(put(&var,12.)));
    end;
  %end;
run;

%put &nobs;

proc sort data=&cntlout out=frmtdt;
by label;

data _null_;
  set frmtdt end=_endfl;
  by label;
  if first.label then do;
    _n+1;
    val=compress('VAL'||put(_n,7.));
    call symput(val,trim(left(label)));
  end;
  if  _endfl then do;
    call symput('NUMGRP',put(_n,7.));
    call symput('PERFMT',compress(FMTNAME));
  end;
run;

proc sort data=zero out=sorted;
 by &var;
run;
%if %length(&weight) eq 0 %then %do;
  %let weight = 1;
%end;

%do i=1 %to &numgrp;
  %let flagp&i = 0 ;
  %let tot&i = 0;
%end;

data one;
  length _temp $40;
  set sorted end=_endfl;
  by &var;
  retain _cellno _outfl _low _cnt _cellgd _cumprb
  %do i=1 %to &numgrp;
    _celln&i 
    _totln&i
  %end;
  ;
  if _n_=1 then do;
    _low=&var;
    _cnt = 0;
    _outfl = 0;
    _cellno = 1;
    _cumprb = 0;
  %do i=1 %to &numgrp;
    _celln&i = 0;
    _totln&i = 0;
  %end;
  end;
  _cnt + &weight;
  _cumprb + (&weight / &nobs);
  _cellprb = _cnt / &nobs;
  _cellprc = 100* _cellprb;
  _high=&var;
  _t1_=int(_cumprb/(1/&pieces));
  %do i=1 %to &numgrp;
    _temp = put(&perf,&perfmt..);
    if  (_temp = "&&val&i") then do;
      _celln&i + &weight;
      _totln&i + &weight;
    end;
  %end;
  if (_t1_ ge _cellno or _endfl) then _outfl = 1;
  if last.&var and _outfl then do;
    output;
    _low=&var;
    _cnt = 0;
    _outfl = 0;
    _cellno = _t1_+1;
    %do i=1 %to &numgrp;
      _celln&i = 0;
    %end;
  end;
  if _endfl then do;
    %do i=1 %to &numgrp;
       if (_totln&i gt 0) then do;
         call symput("flagp&i",'1');
         call symput("tot&i",compress(put(_totln&i,18.5)));
       end;
    %end;
  end;
  keep _low _high _cnt _cellprc
    %do i=1 %to &numgrp;
    _celln&i 
    %end;
  ;
   %do i=1 %to &numgrp;
    label _celln&i  = "&&val&i";
    %end;
   label
     _low = 'Low End'
     _high = 'High End'
     _cnt = 'Cell Count'
     _cellprc = 'Cell Percent'
   ;
 
run;

data two;
  set one;
  retain _cumcnt _cumprob 
  %do i=1 %to &numgrp;
    _cumn&i
  %end;
  0 ;
  _passcnt = &nobs - _cumcnt;
  _cumcnt + _cnt;
  _passprb = 100 - _cumprob;
  _cumprob + _cellprc;
  %do i=1 %to &numgrp;
    _passn&i = "&&tot&i" - _cumn&i;
    _cumn&i + _celln&i;
  %end;
  label 
  _passcnt = '# Total Passing'
  _passprb= '% Total Passing'
  %do i=1 %to &numgrp;
    _passn&i = "# &&val&i Passing"
  %end;
  ;
  drop
  %do i=1 %to &numgrp;
    _cumn&i
  %end;
  _cumcnt _cumprob;
  ;

run;

proc sql noprint ;
 create table names as
  select name , label
   from dictionary.columns
    where libname = "WORK" and memname = "TWO" 
          and upcase(label) in ('BAD' , 'GOOD' , '# BAD PASSING' , '# GOOD PASSING');
quit ;

data _null_ ;
 set names ;
if upcase(label) = 'BAD'            then call symput('BAD'       , name) ;
if upcase(label) = 'GOOD'           then call symput('GOOD'      , name) ;
if upcase(label) = '# BAD PASSING'  then call symput('BAD_PASS'  , name) ;
if upcase(label)= '# GOOD PASSING' then call symput('GOOD_PASS' , name) ;
run ;

data two_b ;
set two end = eof;
retain good_denom bad_denom;

bad_rate     = round ( (( &BAD       / ( &GOOD + &BAD           ) ) * 100 ) , .1 ) ;
bad_rate_all = round ( (( &BAD_PASS  / ( &GOOD_PASS + &BAD_PASS ) ) * 100 ) , .1 ) ;
if &BAD le 0 then actual_odds  = 999999;
else actual_odds  = round( ( &GOOD        / &BAD                       ) , .1 ) ;
good_rate     = round ( (( &GOOD       / ( &GOOD + &BAD           ) ) * 100 ) , .1 ) ;
good_rate_all = round ( (( &GOOD_PASS  / ( &GOOD_PASS + &BAD_PASS ) ) * 100 ) , .1 ) ;

if ( _n_ = 1 ) then do ;
  good_denom = &GOOD_PASS ;
  bad_denom  = &BAD_PASS  ;
end ;

pct_good = ROUND( ( (&GOOD_PASS / good_denom ) * 100 ) , .1 ) ;
pct_bad  = rOUND( ( (&BAD_PASS  / bad_denom  ) * 100 ) , .1 ) ;

&GOOD      = ROUND( &GOOD      , .1 ) ;
&BAD       = ROUND( &BAD       , .1 ) ;
&GOOD_PASS = ROUND( &GOOD_PASS , .1 ) ;
&BAD_PASS  = ROUND( &BAD_PASS  , .1 ) ;

_CNT     = ROUND( _CNT     , .1 ) ;
_PASSCNT = ROUND( _PASSCNT , .1 ) ;


tot_good + &GOOD ;
tot_bad  + &BAD  ;

if eof then do ;
  gb_total = tot_good + tot_bad ;
  call symput('gb_total',gb_total) ;
end ;
run ;


%if %length(&fileout) > 0 %then %do;

data _null_ ;
file "&fileout..txt" dlm = ',' lrecl=1024 ;
set two_b ;
 
if _n_ = 1 then do ;
put "Low End, High End, Total at or above Low End , % Total at or above Low End , Interval Good Count , Good at or above Low End ,  " @;
put " % Good at or above Low End , Interval Bad Count , Bad at or above Low End , % Bad at or Above Low End ," @;
put " Interval Good Rate, Good Rate at or above Low End , Interval Bad Rate , Bad Rate at or above Low End ,Interval Odds"; 
end ;
    
put _low _high  _passcnt _passprb &GOOD &GOOD_PASS pct_good &BAD &BAD_PASS pct_bad 
     good_rate good_rate_all  bad_rate bad_rate_all actual_odds ;
    
run ;

%end;

	 * in case data needed by calling program - matches old versions of decile macro *;
data special ;
set two_b (keep =  _low _high  _passcnt _passprb &GOOD &GOOD_PASS pct_good &BAD &BAD_PASS pct_bad
                    good_rate good_rate_all bad_rate_all bad_rate actual_odds _cellprc ) ;
run ;




%mend decile_se;
%mend;
