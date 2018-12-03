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