%MACRO get_counts(inset,labl);

proc summary data=&inset ;
CLASS &perfvar;
output out=unweightstat (RENAME=(_freq_=UnweightedCount));
run;



proc summary data=&inset ;
CLASS &perfvar;
WEIGHT &wghtvar ;
VAR  &wghtvar ;
output out=weightstat sumwgt=WeightedCount;
run;


                                                                             
 

DATA _null_;
	SET unweightstat End=last;
  file sumstat MOD;	
	if &perfvar =  . THEN put "Total Unweighted &labl Count: " UnweightedCount;
	if &perfvar =  1 THEN put "Event Unweighted &labl Count: " UnweightedCount;
	if &perfvar =  0 THEN put "Non-Event Unweighted &labl Count: " UnweightedCount;
	
	retain total event  0;
	If &perfvar=. THEN Total=UnweightedCount;
	IF &perfvar=1 THEN Event=UnweightedCount;
	
	if last THEN Do;
		Event_rate=Event/total;
		put "Unweighted &labl Event Rate:" event_rate percent8.2; 
  end;		
RUN;    


DATA _null_;
	SET weightstat End=last;
  file sumstat MOD;	
	if &perfvar =  . THEN put "Total Weighted &labl Count: " WeightedCount;
	if &perfvar =  1 THEN put "Event Weighted &labl Count: " WeightedCount;
	if &perfvar =  0 THEN put "Non-Event Weighted &labl Count: " WeightedCount;
	
	retain total event  0;
	If &perfvar=. THEN Total=weightedCount;
	IF &perfvar=1 THEN Event=weightedCount;
	
	if last THEN Do;
		Event_rate=Event/total;
		put "Weighted &labl Event Rate:" event_rate percent8.2; 
  end;		
RUN;  

%MEND get_counts;





%MACRO GET_STATISTICS;



FILENAME SumStat "&path/Summary_Statistics.txt";

proc sql noprint;
	select max(vif) into : mvif
	from _VIF;
quit;

proc sql noprint;
select count(variable)into :varNum
from pe;
quit;






	
proc sort data= corrsum out=corrsumt;
	where upcase(one)~="INTERCEPT" AND upcase(two)~="INTERCEPT";
	by descending corr;
RUN;

DATA _null_;
	 SET 	corrsumt;
	 if _n_=1 THEN call symput('corrval',corr_val);
RUN;
	 	

DATA _null_;
 FILE SumStat;
 put "Sampling Method: &Sampling";
 put "Sampling Seed: &sampseed ";
 put "Max VIF: &mvif";
 put "Max Corr Coeff: &corrval";
 put "Number of Variables: %sysfunc(SUM(&varnum-1))";
RUN;





%get_counts(lrdat.scrbld,BLD);

%IF &vldset ^= 0 %THEN %DO;                                                                                
%get_counts(lrdat.scrvld,VLD); 

DATA total_set;
	 SET lrdat.scrvld  lrdat.scrbld;
RUN;	  
%get_counts(total_set, TOT); 

%END; 
%ELSE %DO;
  %get_counts(lrdat.scrbld,TOT);
%END;   
         
DATA _null_;      
   set summary_stat;
      file sumstat MOD;	
      format varname $PRFLAB.;
      put varname  "KS: " KS 8.2;
      put varname  "IVAL: "  IVAL 8.3;
RUN;

DATA _null_;
	 SET ALERT;
	 file sumstat MOD;	
      put dset count;
RUN;

/*model parameters*/
DATA _null_;
	file sumstat MOD;	
put "iteration   : &iteration "; 
put "rootdir     : &rootdir   ";
put "datadir     : &datadir   ";
put "dset        : &dset      ";
put "eventval    : &eventval  ";
put "noneventval : &noneventval";
put "perfvar     : &perfvar   ";
put "wghtvar     : &wghtvar   ";
put "tpvvar      : &tpvvar    ";
put "lossvar     : &lossvar   ";
put "varforced   : &varforced ";
put "sampling    : &sampling  ";
put "sampprop    : &sampprop  ";
put "resample    : &resample  ";
put "selection   : &selection ";
put "pentry      : &pentry    ";
put "pexit       : &pexit     ";
put "intercept   : &intercept ";
put "linkfunc    : &linkfunc  ";
put "maxstep     : &maxstep   ";
put "maxiter     : &maxiter   ";
put "perfgrp     : &perfgrp   ";
put "modelsub    : &modelsub  ";
RUN;
         

%MEND GET_STATISTICS;
       
       
                                                