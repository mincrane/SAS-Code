options compress=yes obs=max ls=max ps=max pageno=1 errors=2 nocenter;/* symbolgen mlogic mprint; */

/*** create coarse classification for a single variable **/

%macro coarse_bin(datin = ,perfvar = ,bad_indg = , varname = ,weight= ,bin = );

/***** CHECK PARAMETERS ******************************/
%IF %sysfunc(exist(&datin))=0 %THEN %DO;   
 DATA _null_;
  file 'ABORT.MESSAGE';
  put "The Data &datin does not exist";
  abort;
 RUN; 
%END;

%let exist_wgt =  ;
%let exist_perf = ;
%let exist_var = ;
	
data _NULL_;
 length varname $32.;
 set &datin. (obs=1);
 array nmr {*} _numeric_;
 do i=1 to dim(nmr);
   call vname(nmr{i},varname);
   %IF %length(&weight.) > 0 %THEN %DO;
   if upcase(varname) =upcase("&weight.") then 
   call symput('exist_wgt','Y');
   %END;
   if upcase(varname) =upcase("&perfvar.") then 
   call symput('exist_perf','Y');
   
  end;
run;

%if %length(&weight.)>0 and %length(&exist_wgt.) =0  %then %do;
 data _NULL_;
   file "ABORT.MESSAGE";
   put "&weight. is not exist";
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
%if %length(&bad_indg) = 0 %then %do;
  %let bad_value = N;
%end;   
%else %if &bad_indg ^= 1 and &bad_indg ^= 0 %then %do;
	%let bad_value = N;
%end;

%if &bad_value = N  %then %do;
 data _NULL_;
   file "ABORT.MESSAGE";
   put "Bad_indg can only be 0 or 1";
   abort;
 run;
%end;

/**************************************************************************************/


%IF %length(&weight.) = 0 %THEN %DO;
%let weight = 1;
%END;


proc sql noprint;
select count(*) 
      ,sum(&weight)
      ,sum(case when &perfvar.  = 1- &bad_indg  then 1       else 0 end) as raw_good_cnt  
	    ,sum(case when &perfvar.  = &bad_indg     then 1       else 0 end) as raw_bad_cnt 
      ,sum(case when &perfvar.  = 1 - &bad_indg then &weight else 0 end) as wgt_good_cnt  
	    ,sum(case when &perfvar.  = &bad_indg     then &weight else 0 end) as wgt_bad_cnt    
 into : total_raw_cnt, :total_wgt_cnt, :total_raw_good , :total_raw_bad , :tot_wgt_gd , :tot_wgt_bad

from &datin;
quit;

proc sql;
create table coarse1 as
select &varname.
     ,count(*) as total_cnt
	   ,sum(&weight) as wgt_total_cnt
     ,sum(case when &perfvar = 1- &bad_indg    then 1       else 0 end) as raw_good_cnt  
	   ,sum(case when &perfvar = &bad_indg       then 1       else 0 end) as raw_bad_cnt  
	   ,sum(case when &perfvar = 1 - &bad_indg   then &weight else 0 end) as wgt_good_cnt  
	   ,sum(case when &perfvar = &bad_indg       then &weight else 0 end) as wgt_bad_cnt  
from &datin
group by 1
order by 1;
quit;


data coarse2;
set coarse1 end=_endfl;

retain _ks _lastind _lastgd _lastbd _lastngd _lastnbd _cntmiss 0 _cumiv 0 _rawgood _rawbad 0;   

 epi = 0.00001;
 
 pct_gd = wgt_good_cnt/&tot_wgt_gd ;
 pct_bd = wgt_bad_cnt/&tot_wgt_bad;
 cum_pct_gd + pct_gd;
 cum_pct_bd+ pct_bd;

 cum_gd + wgt_good_cnt;
 cum_bd +wgt_bad_cnt;

 cum_raw_gd+raw_good_cnt;
 cum_raw_bd+raw_bad_cnt;


 ks = 100*abs(cum_pct_gd - cum_pct_bd);
 
 if  (ks gt _ks) then _ks = ks;

 if (&varname le .z) then _cntmiss+1;
 _indg=_cntmiss+int( (cum_pct_gd+cum_pct_bd)/(2/&bin) );


 if (_indg>_lastind) or (_endfl=1) then do;
          if ( (_indg=_lastind) and (_endfl=1)) then _indg=_indg+1;
          _pgood=(cum_pct_gd-_lastgd+epi)/(1+((&bin./2)*epi));
          _pbad= (cum_pct_bd-_lastbd+epi)/(1+((&bin./2)*epi));
          if ((_pgood+_pbad)>0.04) or (_endfl=1) or (&varname. le .z) then do;
            _lastgd= cum_pct_gd;
            _lastbd= cum_pct_bd;
            _nogood= cum_gd-_lastngd;
            _nobad = cum_bd -_lastnbd;
            _lastngd= cum_gd;
            _lastnbd= cum_bd;
            _weight=LOG(_pgood/_pbad);
             _ODDS = divide(_nogood,_NOBAD);
            _bad_rate = _nobad/(_nogood+_nobad) ;
            _ivalue = (_pgood-_pbad)* _weight;
            _cumiv+_ivalue;
            if _endfl eq 1 then do;
              call symput('_ival',compress(put(_cumiv,12.3)));
			  call symput('_ks',compress(put(_ks,6.1)));
            end;
            KEEP &varname _indg _nogood _pgood _nobad _pbad _weight _ivalue cum_pct_gd cum_pct_bd cum_raw_gd cum_raw_bd _odds _cumiv _ks _bad_rate _cntmiss;
            output;
				 cum_raw_gd=0;	 
				 cum_raw_bd=0;
          end;
        end;
        _lastind=_indg;
    run;


title %upcase("&varname");

 PROC PRINT DATA=coarse2 SPLIT='*' noobs;
      VAR  &varname _nogood cum_raw_gd _nobad cum_raw_bd _pgood _pbad _weight _ivalue _bad_rate cum_pct_gd cum_pct_bd _ODDS;
      LABEL  &varname = "HIGH END" _nogood="GOOD" cum_raw_gd ="RAW* GOOD" 
		_nobad="BAD" cum_raw_bd="RAW* BAD"
      _pgood="PROB.* GOOD" _pbad="PROB.* BAD" _weight="WOE"
      cum_pct_gd="CUM.* GOOD" cum_pct_bd="CUM.* BAD" _ivalue="INFORMATION* VALUE" _bad_Rate="BAD RATE" _Odds="Odds";
      SUM _ivalue _nogood _nobad _pgood _pbad cum_raw_gd cum_raw_bd;
      FORMAT _nogood _nobad 9.0;
      FORMAT _pgood _pbad _weight _ivalue cum_pct_gd cum_pct_bd _bad_rate 5.3;
      FORMAT _odds  8.1;
	  title4 " ";
	 title5 "KS Value : &_ks.   Information Value:  &_ival ";
run;		

%MEND coarse_bin;


