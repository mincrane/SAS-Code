%include "&_macropath./general/macros_general.sas";


%macro woe_vargen(dset=,perfvar=,wghtvar=,fname=flag_logic.txt);

  proc contents data=&dset. out=_contents noprint;
  run;
  
  proc sql noprint;
  	select name
  	      ,type
  	into: _vname separated by " ",
  	    : _vtype separated by " "
  	from _contents
  	where upcase(name) not in ("%upcase(&perfvar.)","%upcase(&wghtvar.)")
  	;
  quit;
  
  %DO ii=1 %TO &sqlobs.;
     
     %let var = %scan(&_vname,&ii.,%str( ));
     
     %IF %scan(&_vtype.,&ii.,%str( ))= 1 %THEN %DO; 
        %finesplt_f(&dset.,&perfvar.,NONEVENT,0,0,EVENT,1,1,&wghtvar.,&var.,10.2,10,);
        
        title3;
        title2;
        title1;
        
        data _forcont;
        	set grouped;
        	drop _: ; 
        run;
        
        proc contents data=_forcont out=_contents(keep=name) noprint;
        run;
         
        data _grouped;
        	if _n_= 1 then set _contents;
        	set grouped end=last;
        	
        	lo= lag1(&var.);
        	
        	file "&fname."
        	%IF &ii. > 1 %THEN %DO;
        	  mod
        	%END;
        	;
        	
        	if _n_=1 THEN put "/* &var  */ ";
        	if &var. = . then do;
        		put "if " name " = " &var. "then w" name " = " _weight ";";
        	end;
        	else if &var. <= .Z and &var. ne . then do;
        		put "if " name " = ." &var. "then w" name " = " _weight ";";
        	end;
        	else if lo <= .Z and &var. > .Z then do;
        		put "if " name " > .Z and " name " <= " &var. "then w" name " = " _weight ";";
        	end;
        	else do;
        		put "if " name " > " lo " and " name " <= " &var. "then w" name " = " _weight ";";
        	end; 
        	
        	if last then do;
        		if &var. <= .Z and &var. ne . then do;
        			put "if " name " > ." &var. "then w" name " = 0;" //;
        		end;
        		else do;
        		  put "if " name " > " &var. "then w" name " = 0;" //;
        		end;
        	end;
        	 
        run;
        
      %END;
      %ELSE %IF %scan(&_vtype.,&ii.,%str( ))= 2 %THEN %DO;
        
        %finefct_f(&dset.,&perfvar.,NONEVENT,0,0,EVENT,1,1,&wghtvar.,&var.,,);
       
         title3;
         title2;
         title1;
         
         
         
         data _forcont;
         	set grouped;
         	drop _: ; 
         run;
         
         proc contents data=_forcont out=_contents(keep=name) noprint;
         run;
         
         
         
         data _grouped;
         	if _n_= 1 then set _contents;
         	set grouped end=last;
         		
         	file "&fname."
         	%IF &ii. > 1 %THEN %DO;
         	  mod
         	%END;
         	;
         	if _n_=1 THEN put "/* " name " */ ";
         	var2= quote(strip(&var.));
         	
         	put "if " name ' = "' &var '" then w' name " = " _weight ";";
         	
         	if last then do;
         		put " " //;
         	end;
         	 
         run;
       %END;
  %END; 
  
%mend woe_vargen;
