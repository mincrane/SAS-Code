%macro scoreformat(dset=,perfvar=,wghtvar=,scrvar=,nbreak=,eval=,neval=,fmtname=,debug=NO);
	
	%let _nbreak= %sysevalf(100/&nbreak.);
	%put &_nbreak.;
	
  data _foruniv;
  	set &dset;
  	
  	event= (&perfvar.= &eval.);
  	nonevent= (&perfvar.= &neval.);
  run;
  
  ** calculate percentile breaks;
  proc univariate data=_foruniv noprint;
  	var &scrvar.;
  	weight &wghtvar.;
  	output out=pct
  	       pctlpre=p_ pctlpts=0 to 100 by &_nbreak;
  run;
  
  %IF &debug.= YES %THEN %DO;
    proc print data=pct;
    run;
  %END;
  
  proc transpose data=pct out=pct_t(drop=_LABEL_);
  run;
  
  proc sort data=pct_t nodupkey;
  	by col1;
  run;
  
  %IF &debug.= YES %THEN %DO;
    proc print data=pct_t;
    run;
  %END;
  
  data _ctrl;
  	set pct_t(rename=(col1=_end));
  	_start= lag1(_end);
  	
  	if _start > .Z then output;	
  run;
  
  data ctrl;
  	set _ctrl end=last;
  	
  	length label $20;
  	
    start= input(putn(_start,12.9),12.9);
  	end= input(putn(_end,12.9),12.9);
  		
  	retain fmtname "&fmtname." type 'n';
  	
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
    
    drop _name_ _start _end;
    
  run;

  
  proc format library=work cntlin=ctrl;
  run; 
  
  
   
%mend scoreformat;