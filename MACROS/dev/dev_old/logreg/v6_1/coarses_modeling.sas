/******************************************************************************************** 
/* Program Name:    coarses_modeling.sas
/* Project:         LOGREG modeling code
/* Author:          F.Zahradnik
/* Creation Date:   2010-06-24
/* Last Modified: 
/* Purpose:         Replace coarses printed in results.txt with 
/* Arguments: 
*********************************************************************************************/ 
%include "&_macropath./general/macros_general.sas";
%macro gencoarses(dset=,estset=,perfvar=,wghtvar=,eval=,neval=,outfile=,report=);
	
	proc sql noprint;
		select variable
		      ,estimate
		      ,type
		into: varlist  separated by " "
		   ,: estlist  separated by " "
		   ,: typelist separated by " "  
		from &estset.
		where upcase(variable) ne "INTERCEPT"
		;
	quit;
	
	%let cntr= &sqlobs.;
	
	proc printto print=&outfile.;
	%DO ii=1 %TO &cntr.;
	  
	  
	  %IF "%scan(&typelist.,&ii.,%str( ))"= "1" %THEN %DO;
	  
	      %IF "%scan(&estlist.,&ii.,%str( ))"= "." %THEN %DO; title2 "Original of WOE Var for Review."; %END;
	      %ELSE %DO; title2 "Parameter: %scan(&estlist.,&ii.,%str( ))";  %END;
	      %finesplt_f(&dset.,&perfvar.,NONEVENT,&neval.,&neval.,EVENT,&eval.,&eval.,&wghtvar.,%scan(&varlist.,&ii.,%str( )),10.2,10,report);
	  
	  %END;
	  %ELSE %DO;
	  	  %IF "%scan(&estlist.,&ii.,%str( ))"= "." %THEN %DO; title2 "Original of WOE Var for Review."; %END;                                 
	  	  %ELSE %DO; title2 "Parameter: %scan(&estlist.,&ii.,%str( ))";  %END;                                                                
	  	  %finefct_f(&dset.,&perfvar.,NONEVENT,&neval.,&neval.,EVENT,&eval.,&eval.,&wghtvar.,%scan(&varlist.,&ii.,%str( )),,report);  
	  %END;	
	  
	  /* Macro call to retrieve global macros vars */
	  
	%END;
	
	

	
	proc printto;		
%mend gencoarses;


/*GENCOARSES1 WAS CREATED BY JASMIT FOR HTML OUTPUT.  CHANGES OUTPUT FILES, otherwise, the same as above */
/*Updated: 9/21/2011*/


%macro gencoarses1(dset=,estset=,perfvar=,wghtvar=,eval=,neval=,report=);
	
	proc sql noprint;
		select variable
		      ,estimate
		      ,type
		into: varlist  separated by " "
		   ,: estlist  separated by " "
		   ,: typelist separated by " "  
		from &estset.
		where upcase(variable) ne "INTERCEPT"
		;
	quit;
	
	%let cntr= &sqlobs.;

	%DO ii=1 %TO &cntr.;
	  
	  
	  %IF "%scan(&typelist.,&ii.,%str( ))"= "1" %THEN %DO;
	  
	      %IF "%scan(&estlist.,&ii.,%str( ))"= "." %THEN %DO; title2 "Original of WOE Var for Review."; 
		  %END;
	      %ELSE %DO; title2 "Parameter: %scan(&estlist.,&ii.,%str( ))";  
		  %END;
	      %finesplt_f(&dset.,&perfvar.,NONEVENT,&neval.,&neval.,EVENT,&eval.,&eval.,&wghtvar.,%scan(&varlist.,&ii.,%str( )),10.2,10,report);
	  
	  %END;
	  %ELSE %DO;
	  	  %IF "%scan(&estlist.,&ii.,%str( ))"= "." %THEN %DO; title2 "Original of WOE Var for Review."; %END;                                 
	  	  %ELSE %DO; title2 "Parameter: %scan(&estlist.,&ii.,%str( ))";  %END;                                                                
	  	  %finefct_f(&dset.,&perfvar.,NONEVENT,&neval.,&neval.,EVENT,&eval.,&eval.,&wghtvar.,%scan(&varlist.,&ii.,%str( )),,report);  
	  %END;	
	  
	  data grouped_&ii.;
		set grouped;
		LABEL %scan(&varlist.,&ii.,%str( ))="HIGH END" _nogood="&event_label." _rawgood="RAW*&event_label." 
		_nobad="&nonevent_label." _rawbad="RAW*&nonevent_label."
      _pgood="PROB.*&event_label." _pbad="PROB.*&nonevent_label." _weight="WEIGHT*PATTERN"
      _cumgd="CUM.*&event_label." _cumbd="CUM.*&nonevent_label." _ivalue="INFORMATION*VALUE" _Odds="Odds";
      FORMAT _nogood _nobad _rawbad _rawgood comma9.0;
      FORMAT _pgood _pbad _weight _ivalue _cumgd _cumbd comma5.3;
      FORMAT _odds  8.1;
	  run;
	  
	  %global _ks_&ii.;
	  %global _gamma_&ii.;
	  %global _ival_&ii.;
	  %global reversals_&ii.;
	  
	  %let _ks_&ii.= &_ks.;
	  %let _gamma_&ii.= &_gamma.;
	  %let _ival_&ii.= &_ival.;
	  %let reversals_&ii. = &reversals.;
	  
	%END;
		
%mend gencoarses1;