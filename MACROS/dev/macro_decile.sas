%macro decile(indat,weight,var,perf,cntlout,pieces,fileout,frmtout,zerof);

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


proc print data=two label;
var _low _high _cnt _passcnt _cellprc _passprb
%do i=1 %to &numgrp;
   %if %eval(&&flagp&i) gt 0 %then %do;
     _celln&i _passn&i
   %end;
%end;
;
format _cellprc _passprb 5.1;

data _null_;
  set two end=_endfl;
  file "&frmtout" lrecl=100;
  if _n_ eq 1 then do;
    put 'proc format; ';
    put 'value display';
    %if %length(&zerof) gt 0 %then %do;
      if _low gt 0 then _low=0;
    %end;
    put _low '- ' _high ' = " ' _low '- ' _high '"';
  end;
  else do;
    put _low '<- ' _high ' = " ' _low '<- ' _high '"';
  end;
  if _endfl then do;
    put ';' ;
  end;
  file "&fileout" lrecl=1000;
  if _n_ eq 1 then do;
    put '"Low End","High End","Cell Count","#Total Passing","Cell %","% Total Passing"' @;
    put 
    %do i=1 %to &numgrp;
       %if %eval(&&flagp&i) gt 0 %then %do;
      ',"' "# Cell &&val&i" '","' "# &&val&i Passing" '"'
        %end;
    %end;
    ;
  end;
  put _low ',' _high ',' _cnt ',' _passcnt ',' _cellprc 5.1 ',' _passprb 5.1 
  %do i=1 %to &numgrp;
     %if %eval(&&flagp&i) gt 0 %then %do;
       ',' _celln&i ',' _passn&i
     %end;
  %end;
  ;
run;

%do i=1 %to &numgrp;
  %put "&&flagp&i" ;
%end;


%mend decile;