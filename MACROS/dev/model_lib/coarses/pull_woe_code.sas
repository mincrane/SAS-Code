%MACRO pull_woe_code(variable=,coarsefile=,outfile=,dropfile=);

DATA _null_;
  INFILE "&coarsefile" ls=1000 recfm=v length=long missover end=last ;
  input @1 line $varying300. long;
  file "&outfile" mod;
  if _n_=1 THEN End_Flag=0;
  Retain End_Flag;
  if upcase(line)="/* &variable  */" and End_Flag=0 THEN DO;
     End_Flag=1;
  END;
  IF compress(line)="" THEN END_Flag=0;
  If End_Flag=1 THEN put line;
 
 RUN; 
 


 
%MEND pull_woe_code;


%MACRO get_vars_needed_for_woe(infile=,coarsefile=,outfile=,dropfile=);
DATA _flag_logic;
	INFILE "&infile";
	input variable :$32.;
	variable=upcase(compress(variable));
	if variable="" THEN DELETE;
RUN;


proc sql noprint;
		select variable
		into: keepwoe  separated by " "
		from _flag_logic
		;
	quit;
	
	%let cntr= &sqlobs.;
	
DATA _null_;
	file "&outfile";
	put "**WOE VARIABLES REQUESTED;";
	put "  ";
RUN;

	
	%DO ii=1 %TO &cntr.;
	  
	 %pull_woe_code(variable=%scan(&keepwoe.,&ii.,%str( )),coarsefile=&coarsefile,outfile=&outfile); 
	%END;

DATA _null_;
file "&dropfile" lrecl=3200;
	if compress("&keepwoe.")~="" THEN put "drop &keepwoe. ;";
	else put "  ";
RUN;

%mend get_vars_needed_for_woe;
