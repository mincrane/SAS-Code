libname local '.';

%macro dataclean(dset=,wghtvar=,imputetype=ZERO,lo=,hi=,missflag=NO,sqflag=NO);
	
	
  %genstat(dset=&dset.,wghtvar=&wghtvar.);	
  %imputevar(dset=&dset.,imputetype=&imputetype.);
  
  %IF %length(&lo.) > 0 or %length(&hi.) > 0 %THEN %DO;
    %truncvar(dset=&dset.,lo=&lo.,hi=&hi.);
  %END;
  
  %IF %upcase(&missflag.)= YES %THEN %DO;
    %missflag(dset=&dset.,clear=0);
  %END;
  
  %IF %upcase(&sqflag.)= YES %THEN %DO;
    %sqflag(dset=&dset.,clear=0);
  %END;
 
%mend dataclean;

%macro overwrite(vlist=,imputetype=,lo=,hi=,missflag=NO,sqflag=NO);

  %IF %sysfunc(exist(local.genstat)) ~= 1 %THEN %DO;
    %put;
    %put %upcase(%sysmacroname): genstat dataset does not exist.  Statistics need to be computed using the DATACLEAN;
    %put %upcase(%sysmacroname): macro prior to overwriting default values.;
    %put;
    %goto macroend;
  %END;
  
  data varlist;
  	array tmp[*] %sysfunc(compbl(&vlist.));
  run;
  
  %IF %length(&imputetype.) > 0 %THEN %DO;
    %imputevar(dset=varlist,imputetype=&imputetype.);
  %END;
  
  %IF %length(&lo.) > 0 or %length(&hi.) > 0 %THEN %DO;
    %truncvar(dset=varlist,lo=&lo.,hi=&hi.);
  %END;
  
  %IF %upcase(&missflag.)= YES %THEN %DO;
    %missflag(dset=varlist,clear=0);
  %END;
  
  %IF %upcase(&sqflag.)= YES %THEN %DO;
    %sqflag(dset=varlist,clear=0);
  %END;
  
  proc datasets library=work;
  	delete varlist;
  run;
  
%macroend: %put;
%put -------------------------------------------------------------------------------------;
%put --- End %upcase(&sysmacroname)                                                       ;
%put -------------------------------------------------------------------------------------;
%put;
%mend overwrite;

%macro genstat(dset=,wghtvar=);

proc contents data=&dset. out=_contents noprint varnum;
run;

proc means data=&dset. noprint;
	%IF %length(&wghtvar.) > 0 %THEN %DO;
	  weight &wghtvar.;
	%END;
	output out= _means;
run;

proc transpose data=_means out=genstat (rename=(_name_=variable col1=n col2=min col3=max col4=mean col5=std) drop=_label_);
run;

proc sql noprint;
	select name
	into: namelist separated by " "
	from _contents
	where type= 1
	  and name not in ("&wghtvar")
	;
quit;

%DO ii=1 %TO &sqlobs.;
  proc means data=&dset. noprint;
  	var %scan(&namelist.,&ii.,%str( ));
  	%IF %length(&wghtvar.) > 0 %THEN %DO;
	    weight &wghtvar.;
	  %END;
  	output out=_pcts p1=p1 p5=p5 p10=p10 p90=p90 p95=p95 p99=p99;
  run;
  
  data _pcts;
  	length variable $32;
  	set _pcts;
  	variable= "%scan(&namelist.,&ii.,%str( ))";
  run;
  
  proc append base=allpct data=_pcts;
  run;
  
%END;

proc sql;
	create table local.genstat as
	select a.*
	      ,b.p1
	      ,b.p5
	      ,b.p10
	      ,b.p90
	      ,b.p95
	      ,b.p99
	from genstat a
	inner join allpct b
	on a.variable=b.variable
	;
quit;

proc print data=local.genstat;
run;

data local.macro_init;
	length variable $32 imputemv imputeval 8 imputetype $3 tlo thi missflag sqflag 8;
	set local.genstat;
	%IF %length(&wghtvar.) > 0 %THEN %DO;
	  if upcase(variable)= "%upcase(&wghtvar.)" then delete;
	%END;
	keep variable imputeval imputemv imputetype tlo thi missflag sqflag;
run;

proc datasets library=work nolist;
	delete genstat allpct _pcts _contents _means;
run;

%macroend: %put;
%put -------------------------------------------------------------------------------------;
%put --- End %upcase(&sysmacroname)                                                       ;
%put -------------------------------------------------------------------------------------;
%put;
%mend genstat;

%macro imputevar(dset=,imputetype=);
	
	%let checkimpute= 0;
	%IF %upcase(&imputetype.) eq MEAN or %upcase(&imputetype.) eq ZERO %THEN %DO;
	  %let checkimpute= 1;
	%END;
	
	%IF &checkimpute.= 0 %THEN %DO;
	  %put;
	  %put %upcase(&sysmacroname.): Imputation not defined as ZERO or MEAN.  Macro terminating.;
	  %put %upcase(&sysmacroname.): Imputation defined as &imputetype.;
	  %put;
	  %goto macroend;
	%END;
	
	%IF %sysfunc(exist(local.genstat)) ~= 1 %THEN %DO;
	  %genstat(dset=&dset.);
	%END;
	
	proc contents data=&dset out=_contents noprint;
	run;
	
  %IF %upcase(&imputetype.)= ZERO %THEN %DO;
    proc sql;
    	create table _preimpute as
    	select name
    	      ,0 as imputeval 
    	from _contents
    	where type= 1;
    quit;
  %END;
  
  %IF %upcase(&imputetype.)= MEAN %THEN %DO;
    proc sql;
    	create table _preimpute as 
    	select a.name
    	      ,b.mean as imputeval
    	from _contents a
    	inner join local.genstat b
    	on a.name = b.variable
    	;
    quit;
  %END;
  
  proc sql;
  	  	
  	update local.macro_init as a 
  	  set imputeval = (select b.imputeval
  	                   from _preimpute b
  	                   where a.variable = b.name)
  	     ,imputetype= 'ALL'
  	     ,imputemv= .Z
  	  where a.variable = (select b.name
  	                      from _preimpute b
  	                      where a.variable = b.name);
  quit;
  
  proc datasets library=work nolist;
  	delete _contents _preimpute;
  run;
  
 
%macroend: %put;
%put -------------------------------------------------------------------------------------;
%put --- End %upcase(&sysmacroname)                                                       ;
%put -------------------------------------------------------------------------------------;
%put;
%mend imputevar;

%macro truncvar(dset=,lo=,hi=);
  
  %IF %sysfunc(exist(local.genstat)) ~= 1 %THEN %DO;
	  %genstat(dset=&dset.);
	%END;
  
  proc contents data=&dset out=_contents noprint;
  run;
  
  %IF %length(&lo.) > 0 %THEN %DO;
    
    %IF %upcase(&lo.) ne CLEAR %THEN %DO;
      %let lo= P&lo.;
      proc sql noprint;
      	create table _lotrunc as
      	select a.name
      	      ,b.&lo. as tlo
      	from _contents a
      	inner join local.genstat b
      	on a.name = b.variable
      	;
        
        update local.macro_init as a
          set tlo = (select b.tlo
                     from _lotrunc b
                     where a.variable = b.name)
          where a.variable = (select b.name
  	                          from _lotrunc b
  	                          where a.variable = b.name)
        ;
      quit;
    %END;
    %ELSE %IF %upcase(&lo.) eq CLEAR %THEN %DO;
      proc sql noprint;
      	create table foo as
      	select c.name
      	       ,. as foo
      	from _contents c
      	inner join local.genstat b
      	on c.name = b.variable
      	;
      	
      	update local.macro_init as a
      	  set tlo = (select b.foo
      	             from foo b
      	             where a.variable = b.name)
      	  where a.variable = (select b.name
  	                          from foo b
  	                          where a.variable = b.name)
      	  ;
      quit;
    %END;
  %END;
   
  %IF %length(&hi.) > 0 %THEN %DO;
    
    %IF %upcase(&hi.) ne CLEAR %THEN %DO;
       %let hi= P&hi.;
       proc sql noprint;
       	 create table _hitrunc as
       	 select a.name
       	       ,b.&hi as thi
       	 from _contents a
       	 inner join local.genstat b
       	 on a.name = b.variable
       	 ;
       	 
       	 update local.macro_init as a
       	   set thi= (select b.thi
       	             from _hitrunc b
       	             where a.variable = b.name)
       	   where a.variable = (select b.name
  	                           from _hitrunc b
  	                           where a.variable = b.name)
       	 ;
       quit;
    %END;
    %ELSE %IF %upcase(&hi) eq CLEAR %THEN %DO;
      proc sql noprint;
      	
      	create table foo as
      	select c.name
      	       ,. as foo
      	from _contents c
      	inner join local.genstat b
      	on c.name = b.variable
      	;
      	
      	update local.macro_init as a
      	  set thi = (select b.foo
      	             from foo b
      	             where a.variable = b.name)
      	  where a.variable = (select b.name
  	                          from foo b
  	                          where a.variable = b.name)
      	;
      quit;
    %END;   
  %END;
   
   proc datasets library= work;
   	 delete _lotrunc _hitrunc _contents foo;
   run;
     
%macroend: %put;
%put -------------------------------------------------------------------------------------;
%put --- End %upcase(&sysmacroname)                                                       ;
%put -------------------------------------------------------------------------------------;
%put;
%mend truncvar;

%macro missflag(dset=,clear=0);
	
  %IF %sysfunc(exist(local.genstat)) ~= 1 %THEN %DO;
	  %genstat(dset=&dset.);
	%END;
	
	proc contents data=&dset. out=_contents noprint;
	run;
	
	%IF %upcase(&clear.)= 0 %THEN %DO;
	   proc sql;
	   	create table _misstable as
	   	select a.name
	   	      ,1 as missflag
	   	from _contents a
	   	inner join local.genstat b
	   	on a.name = b.variable
	   ;
	   
	   update local.macro_init as a
	     set missflag = (select b.missflag
	                     from _misstable b
	                     where a.variable = b.name)
	     where a.variable = (select b.name
  	                       from _misstable b
  	                       where a.variable = b.name)
	   ;
	  quit;
  %END;
  %ELSE %IF %upcase(&clear) ~= 0 %THEN %DO;
     proc sql;
	   	create table _misstable as
	   	select a.name
	   	      ,0 as missflag
	   	from _contents a
	   	inner join local.genstat b
	   	on a.name = b.variable
	   ;
	   
	   update local.macro_init as a
	     set missflag = (select b.missflag
	                     from _misstable b
	                     where a.variable = b.name)
	     where a.variable = (select b.name
  	                       from _misstable b
  	                       where a.variable = b.name)
	   ;
	  quit;
	%END; 
  
  proc datasets library=work nolist;
  	delete _contents _misstable;
  run;
    
%macroend: %put;
%put -------------------------------------------------------------------------------------;
%put --- End %upcase(&sysmacroname)                                                       ;
%put -------------------------------------------------------------------------------------;
%put;
%mend missflag;

%macro sqflag(dset=,clear=0);
  %IF %sysfunc(exist(local.genstat)) ~= 1 %THEN %DO;
	  %genstat(dset=&dset.);
	%END;
	
	proc contents data=&dset. out=_contents noprint;
	run;
	
	%IF %upcase(&clear.)= 0 %THEN %DO;
	   proc sql;
	   	create table _sqtable as
	   	select a.name
	   	      ,1 as sqflag
	   	from _contents a
	   	inner join local.genstat b
	   	on a.name = b.variable
	   ;
	   
	   update local.macro_init as a
	     set sqflag = (select b.sqflag
	                     from _sqtable b
	                     where a.variable = b.name)
	     where a.variable = (select b.name
  	                      from _sqtable b
  	                      where a.variable = b.name)
	   ;
	  quit;
  %END;
  %ELSE %IF %upcase(&clear) ~= 0 %THEN %DO;
     proc sql;
	   	create table _sqtable as
	   	select a.name
	   	      ,0 as sqflag
	   	from _contents a
	   	inner join local.genstat b
	   	on a.name = b.variable
	   ;
	   
	   update local.macro_init as a
	     set missflag = (select b.sqflag
	                     from _sqtable b
	                     where a.variable = b.name)
	     where a.variable = (select b.name
  	                      from _sqtable b
  	                      where a.variable = b.name)
	   ;
	  quit;
	%END; 
  
  proc datasets library=work nolist;
  	delete _contents _misstable;
  run;
  
%macroend: %put;
%put -------------------------------------------------------------------------------------;
%put --- End %upcase(&sysmacroname)                                                       ;
%put -------------------------------------------------------------------------------------;
%put;
%mend sqflag;

%macro write_gensq;
	
	/* gensqm call gensqm(varin=,limlo=,limhi=,id=,imputeval=,missval=,sqval=); */
	
	%IF %sysfunc(exist(local.macro_init)) = 0 %THEN %DO;
	  %put;
	  %put %upcase(&sysmacroname.): macro_init dataset does not exist.  GENSQ calls will not be written.;
	  %put %upcase(&sysmacroname.): Process Terminating;
	  %put;
	  %goto macroend;
	%END;
	
	data _null_;
		set local.macro_init; 
		file 'gensq_call.sas';
		if imputetype='ALL' then do;		
		  put @1 '%gensqm(varin=' variable ',limlo=' tlo ',limhi=' thi ',id=' variable ',imputeval=' imputeval ',missval=' missflag ',sqval=' sqflag ');';
	  end;
	  else if imputetype='VAL' then do;
	  	put @1 '%gensqr(varin=' variable ',limlo=' tlo ',limhi=' thi ',id=' variable ',imputemv=' imputemv ',imputeval=' imputeval ',missval=' missflag ',sqval=' sqflag ');';
	  end;
	  
	run;
	

%macroend: %put;
%put -------------------------------------------------------------------------------------;
%put --- End %upcase(&sysmacroname)                                                       ;
%put -------------------------------------------------------------------------------------;
%put;
%mend write_gensq;

%macro gensq(varin=,limlo=,limhi=,id=,imputeval=,sqval=);
  %IF %length(&limlo) gt 0 %THEN %DO;
     if &varin lt &limlo then &varin=&limlo;
  %END;
  
  %IF %length(&limhi) gt 0 %THEN %DO;
     if &varin gt &limhi then &varin=&limhi;
  %END;
  
  %IF &sqval= 1 %THEN %DO; 
    &id._2=&varin * &varin;
    label &id._2="square of &varin";
  %END;
%mend gensq;

%macro gensqm(varin=,limlo=,limhi=,id=,imputeval=,missval=,sqval=);
   
   %IF &missval= 1 %THEN %DO;
     if &varin le .z then &id._0=1;
     else &id._0=0;
     label &id._0="flag for missing &varin";
   %END;
   
   if &varin le .z then &varin=&imputeval;
   else do;
   	
   %IF %length(&limlo) gt 0 %THEN %DO;
     if &limlo > .Z then do;
       if &varin lt &limlo then &varin=&limlo;
     end;
   %END;
   %IF %length(&limhi) gt 0 %THEN %DO;
     if &limhi. > .Z then do;
       if &varin gt &limhi then &varin=&limhi;
     end;
   %END;
  end;
  
  %IF &sqval= 1 %THEN %DO;
    &id._2=&varin * &varin;
    label &id._2="square of &varin";
  %END;
   
%mend gensqm;

** for ratio imputation;
%macro gensqr(varin=,limlo=,limhi=,id=,imputemv=,imputeval=,missval=,sqval=);
   
   %IF &missval= 1 %THEN %DO;
     if &varin le .z then &id._0=1;
     else &id._0=0;
     label &id._0="flag for missing &varin";
   %END;
   
   %IF &imputemv. ^= . %THEN %DO;
     %let imputemv = .&imputemv.;
   %END;
   
   if &varin = &imputemv. then &varin=&imputeval;
   else do;
   
   %IF %length(&limlo) gt 0 %THEN %DO;
     if &limlo > .Z then do;
       if &varin lt &limlo then &varin=&limlo;
     end;
   %END;
   %IF %length(&limhi) gt 0 %THEN %DO;
     if &limhi. > .Z then do;
       if &varin gt &limhi then &varin=&limhi;
     end;
   %END;
  end;
  
  %IF &sqval= 1 %THEN %DO;
    &id._2=&varin * &varin;
    label &id._2="square of &varin";
  %END;
   
%mend gensqr;