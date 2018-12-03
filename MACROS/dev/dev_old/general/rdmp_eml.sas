/*********************************************************************************************
/* Program Name:    Extensible Macro Library
/* Author:          F.Zahradnik
/* Added Date:      3/13/2008 -- rdmp_grpKSIV
/*                  5/1/2008 -- corrsum
/*                  5/5/2008  -- perf   
/* Purpose:         Create a collection of modeling macros that are available
/*                  for use in multiple modeling applications.
/* Arguments:       See individual boilerplates for argument details
*********************************************************************************************/ 

/********************************************************************************************
/*  Macro Name:			rdmp_grpKSIV
/*  Author:					F.Zahradnik
/*  Creation Date:  3/13/2008
/*  Last Modified:	4/15/2008 -- added epsilon to numerator in WOE equation
                    3/21/2008 -- rdmp_grpKSIV:  added check for character variables
                      for KS/Iv calculation
                    3/14/2008 -- rdmp_grpKSIV: fixed issue with weights coming from 
                      proc means driving population counts.
/*                  
/*  Arguments:      dset -- input dataset
										targvar -- variable for summary statistic creation
										perfvar -- binary performance variable
										wghtvar -- weight variable
										ngroup -- # of bins used to calculate KS/IV
										supprint -- suppress printing table used to calculate KS/IV statistics.
										   Default value is YES, suppressing the table.
										oset -- output dataset with variable name and KS/IV statistics
/*
*********************************************************************************************/
%macro rdmp_grpKSIV(dset=,targvar=,perfvar=,wghtvar=,ngroup=,supprint=YES,oset=summary_stat);
  %local epsilon;
  %let epsilon = 1.0E-10;
  
  
  proc contents data=&dset out=_contents(keep=name type) noprint;
  run;
  
  proc sql noprint;
    select type
    into: _type
    from _contents
    where upcase(compress(name)) = "%upcase(&targvar)"
    ;
  quit;
  
  %IF &_type.= 1 %THEN %DO;
    proc rank data=&dset out=_ranks(keep=&targvar. group &perfvar. &wghtvar.) groups= &ngroup.;
      var &targvar;
      ranks group;
    run; 
  %END;
  %ELSE %DO;
    data _ranks;
    	length group $ 32;
    	set &dset;
    	group= upcase(&targvar.);
    	keep &targvar. &perfvar. &wghtvar. group;
    run;
  %END;  	
  
  proc means data=_ranks nway n sumwgt sum noprint;
  	class group /missing;
  	var &perfvar. 
  	    %IF &_type.= 1 %THEN %DO;
  	      &targvar.
  	    %END;
  	;
  	%IF %length(&wghtvar) > 0 %THEN %DO;
  	  weight &wghtvar.;
  	%END;
  	%IF &_type.= 1 %THEN %DO;
  	  output out= _means n=n sumwgt=sumwgt sum(&perfvar.)= p1sum
  	               min(&targvar.)=min max(&targvar.)=max;
  	%END;
  	%ELSE %DO;
  	  output out= _means n=n sumwgt=sumwgt sum(&perfvar.)= p1sum;
  	%END;
  run;
  
  data _means;
  	set _means end=eof;
  	p0sum= sumwgt-p1sum;
  	cum_p0+p0sum;
  	cum_p1+p1sum;
  	
  	if eof then do;
  		call symputx('total_p0',cum_p0);
  		call symputx('total_p1',cum_p1);
  	end;
  	
  run;
  
  data _ivcalc;
  	set _means end=eof;
  	retain ks 0;
  	
  	%IF &_type.= 1 %THEN %DO;
  	  group= _N_;
  	%END;
  	
  	pct0perf= p0sum/(&total_p0. + &epsilon.);
  	pct1perf= p1sum/(&total_p1. + &epsilon.);
  	
  	cumpct_p0= 100*(cum_p0/(&total_p0. + &epsilon.));
  	cumpct_p1= 100*(cum_p1/(&total_p1. + &epsilon.));
  	ks_part= abs(cumpct_p1 - cumpct_p0);
  	if ks_part > ks then ks= ks_part;
  
    woe= log((pct1perf+&epsilon)/(pct0perf+&epsilon.));
    info= (pct1perf - pct0perf)*woe;
    total_info+info;
    
    if eof then do;
    	call symputx('KS',ks);
    	call symputx('IVAL',total_info);
    end;
  run;
  
  %IF %length(&oset) > 0 %THEN %DO;
  
    data _ivsummary;
    	length varname $50;
    	varname= "%upcase(&targvar)";
    	KS= &KS.;
    	IVAL= &IVAL.;
    run;
    
    %IF %sysfunc(exist(&oset)) %THEN %DO;
      proc append base=&oset. data=_ivsummary;
      run;
    %END;
    %ELSE %DO;
      data &oset.;
      	set _ivsummary;
      run;
    %END;
  %END;
    
  %IF %upcase(&supprint.) ne YES %THEN %DO;
    title "%upcase(&targvar.)";
    title2 "KS VALUE: %sysfunc(putn(&KS.,8.2))";
    title3 "INFORMATION: %sysfunc(putn(&IVAL.,8.3))";
    
    proc print data=_ivcalc noobs;
      %IF &_type.= 1 %THEN %DO;
    	  var group min max p1sum pct1perf cumpct_p1 p0sum pct0perf cumpct_p0 ks_part woe info;
    	  format min max best10.;
    	%END;
    	%ELSE %DO;
    	  var group p1sum pct1perf cumpct_p1 p0sum pct0perf cumpct_p0 ks_part woe info;
    	%END;
    run;
    
    title3;
    title2;
    title;
    
  %END;
%mend rdmp_grpKSIV;

%macro corrsum(dset=);
	%local fullmodel cnt ii;
	
	proc sql noprint;
	  select parameter
		  into: fullmodel separated by " "
		  from &dset.
	  ;
	  
	  select count(*)
	    into: cnt
	    from &dset.
	  ;
	  
	  create table modelvars as
	    select a.parameter as one, b.parameter as two
	    from &dset. a,
	         &dset. b
	  ;
	quit;
	
	%DO ii=1 %TO &cnt;
	  data _ctemp(keep=corr_val);
	  	set &dset;
	  	corr_val= %scan(&fullmodel,&ii,%str( ));
    run;
    
    proc append base=corrvals data=_ctemp;
    run;
	%END;
	 
	 
  data modelvars;
	  merge modelvars corrvals;
	  if one = two then delete;
  run;
  
  proc sort data=modelvars;
  	by one;
  run;
  
  data modelvars;
  	set modelvars;
  	by one;
  	retain local_cnt total_cnt 0;
  	if first.one then do;
  		local_cnt= 0;
  		total_cnt+1;
  	end;
  	
  	local_cnt+1;
  	
  	corr= abs(corr_val);
  	
  	if local_cnt => total_cnt then output;
  run; 
  
  proc means data=modelvars p95 noprint;
  	var corr;
  	output out=_corr95 p95=p95;
  run;
  
  data _null_;
  	set _corr95;
  	call symputx('cp95',p95);
  run;
  
  proc sql;
  	create table corrsum as 
  	select one,two,corr_val,corr
  	from modelvars
  	where corr ge &cp95
  	order by corr desc
  ;
  quit;
  
%mend corrsum;

%macro HL_goodness(dset=,perfvar=,predvar=,wghtvar=,suppress=NO);
	 
	 %IF %sysfunc(exist(&dset)) %THEN %DO;
	   proc sort data=&dset. nodupkey out=_dsortedfit;
	     by &predvar.;
	   run;
	   
	   proc sort data=&dset. out=_sortedfit;
	   	 by &predvar.;
	   run;
	   
	   data _null_;
	   	 set _dsortedfit end=last nobs=n;
	   	 
	   	 if last then do;
	   	 	 grpsize= ceil(0.1*n + 0.5);
	   	 	 call symputx('grpsize',grpsize);
	   	 end;
	   run;
	   
	   data _dgroupfit;
	   	 set _dsortedfit;
	   	 retain grp;
	   	 
	   	 if _n_=1 then do;
	   	 	 grp= 1;
	   	 end;
	   	 
	   	 if mod(_n_,&grpsize) = 0 then grp+1;
	   	 keep &predvar. grp;
	   run;	 
	   
	   data _groupfit;
	   	 merge _sortedfit _dgroupfit;
	   	 by &predvar.;
	   run;
	   
	   proc means data=_groupfit n sumwgt sum mean min max ;
	   	 var &perfvar &predvar;
	   	 class grp;
	   	 weight &wghtvar;
	   	 output out=_statfit n(&perfvar)= nperf mean(&predvar)= pi_bar
	   	                     sum(&perfvar)=sum_p1 sumwgt(&perfvar)=sumwgt
	   	                     ;
	   run;  
	  
	   data _statfit;
	     set _statfit;
	     where _type_ =1;
	     
	     sum_p0= sumwgt-sum_p1;
	     expected_p1= pi_bar*sumwgt;
	     expected_p0= (1-pi_bar)*sumwgt;
	     
	     stat= (sum_p1 - (pi_bar*sumwgt))**2 / (sumwgt*pi_bar*(1-pi_bar));
	   run;
	   
	   proc print data=_statfit;
	   	 *var grp nperf sumwgt pi_bar sum_p1;
	   run;
	    
	 %END;
%mend HL_goodness;

/************************************************************************** 
/* Program Name:   perfgain_ind.sas
/*
/* Author:         Unknown
/*
/* Creation Date:  Unknown
/*
/* Last Modified:  4/16/2008 - F.Zahradnik: Changed to relative parameter
/*                  Added option to suppress printing results for use in
/*                  alternate macros.
/*									Added perfvar argument to specify performance variable
/*									used in calculating KS/IV.  Before, these were assumed 
/*									to be defined as separate variables outside the macro.
/*									These are used in the logic in the _MTEMP set defining
/*									the flags.
/*									Added dname argument to define the score distribution
/*
/* Purpose: 
/* Arguments:      datain -- input dataset
									 varin -- variable summarized by gains table.  This should
									   be a probability or dollar amount
									 wgtvar -- weight variable
									 perfvar -- binary performance variable
									 goodval -- value representing the modeling event
									 badval -- value representing the complement to the modeling
									   event
									 groups -- number of breaks for the gains table
									 suppress -- YES/NO toggle suppressing printing of gains table
									 dname -- name for the distribution used in title statement
***************************************************************************/ 
%MACRO PERF(DATAIN=,VARIN=,WGTVAR=,perfvar=,goodval=1,badval=0,GROUPS=,ORDER=ASC,suppress=NO,dname=);

  %local epsilon;
  %let epsilon = 1.0E-10;
  
  %IF %sysfunc(exist(&datain.)) ^=1 %THEN %DO;
    %put;
    %put %upcase(&sysmacroname.): Dataset %upcase(&datain.) does not exist.;
    %put;
    %goto macroend;
  %END;
  
  %local dsid rc;
  %let dsid = %sysfunc(open(&datain.));
  
  %IF %sysfunc(varnum(&dsid.,&varin.))= 0 %THEN %DO;
    %put;
    %put %upcase(&sysmacroname.): Report variable %upcase(&varin.) does not exist on %upcase(&datain.).;
    %put;
    %goto macroend;
  %END;
  
  %IF %sysfunc(varnum(&dsid.,&perfvar))= 0 %THEN %DO;
    %put;
    %put %upcase(&sysmacroname.): Performance variable %upcase(&perfvar.) does not exist on %upcase(&datain.).;
    %put;
    %goto macroend;
  %END;
  
  %let rc= %sysfunc(close(&dsid.));
  
  /*Step added by fz to remove potential problems with global macro variables
    generated in the driver parent program. */
    
  data _MTEMP;
  	set &datain.;
  	n=1;
  	
  	ngood= (&perfvar. = &goodval.);
  	nbad=  (&perfvar. = &badval.);
  	
  run;
  
 
 TITLE4 "Score Distribution: %upcase(&dname)";
  PROC SORT data=_MTEMP OUT=MTEMP(KEEP=N ngood nbad &VARIN &WGTVAR);
       %IF %upcase(&order.) = ASC %THEN %DO;
         BY &VARIN;
       %END;
       %IF %upcase(&order.) = DESC %THEN %DO;
         BY descending &VARIN.;
       %END;
  RUN;
  
  PROC SUMMARY DATA=MTEMP(KEEP=&WGTVAR) NWAY;
       VAR &WGTVAR;
       OUTPUT OUT=T1 SUM(&WGTVAR)=TOTWGT;
       RUN;
  
  DATA MTEMP;
       IF _N_=1 THEN SET T1;
       SET MTEMP;
       %IF %upcase(&order.) = ASC %THEN %DO;
         BY &VARIN;
       %END;
       %IF %upcase(&order.) = DESC %THEN %DO;
         BY descending &VARIN.;
       %END;
       CUMN+&WGTVAR;
       RETAIN VALUE RANK ;
       IF &VARIN = . THEN RANK= -99;
       IF FIRST.&&VARIN. THEN DO;
          RANK  = INT(&GROUPS*(CUMN- &WGTVAR) / TOTWGT)+ 1;
          VALUE=&VARIN;
       END;
  RUN;
  
  PROC SUMMARY DATA=MTEMP NWAY MISSING;
       CLASS RANK;
       VAR N ngood nbad &VARIN;
       WEIGHT &WGTVAR   ;
       OUTPUT OUT=TOTS SUM(N ngood nbad)=N ngood nbad
                       MIN(&VARIN)=FROM   MAX(&VARIN)=ENDP;
  RUN;
  
  PROC SUMMARY DATA=TOTS(WHERE=(FROM NE .))  NWAY ;
       VAR N ngood nbad ;
       OUTPUT OUT=DOTOTS SUM(N ngood nbad)=SALL sgood sbad ;
  RUN;
  
  DATA DORPT ;
       IF _N_=1 THEN SET DOTOTS ;
       SET TOTS(WHERE=(_TYPE_=1)) END=FINAL;
       TOTPCT=sbad/SALL ;
       pcgood=ngood/N;
       pcbad=nbad/N;
       
       RETAIN KSMAX 0;
       retain ival_tot 0;
       
       TOTAL=N;
       
       IF RANK < 0 THEN RETURN;
       CUMT+TOTAL ;
       cumgood+ngood ;
       cumbad+nbad ;
       nind = total - nbad - ngood ;
       ptotgood=cumgood/sgood;
       ptotbad=cumbad/sbad;
       
       KS=ABS(ptotgood-ptotbad) ;
       KSMAX=MAX(KSMAX,KS);
       
       _pcgood= ngood/sgood;
       _pcbad= nbad/sbad;
       woe= log((_pcgood+&epsilon)/(_pcbad+&epsilon.));
       ival= (_pcgood - _pcbad)*woe;
       ival_tot + ival;
       
       PTOT=CUMT/SALL ;
       Pbad=nbad/TOTAL ;
       cumg=cumgood/CUMT ;
       cumb=cumbad/CUMT ;
       PCGAIN=((cumg-TOTPCT)/TOTPCT);
       VARNAME="&VARIN";
       
       if FINAL then do;
       	 CALL SYMPUT('KSVALUE',PUT(KSMAX,PERCENT8.2)); 
         CALL SYMPUT('IVAL',ival_tot);
       end;
         
       KEEP RANK FROM ENDP TOTAL nind nbad ngood PTOT ptotbad ptotgood
            pcbad cumb KS woe ival _pcgood _pcbad VARNAME;
  RUN;
  
  %IF %upcase(&suppress) ~= YES %THEN %DO;
    PROC PRINT SPLIT='*' NOOBS ;
         VAR RANK FROM ENDP TOTAL nind nbad ngood PTOT ptotbad ptotgood
                  pcbad cumb KS;
         SUM TOTAL nbad ngood ;
         FORMAT TOTAL nind nbad ngood COMMA10.0
                PTOT ptotbad ptotgood pcbad cumb KS PERCENT8.2
                ;
         LABEL RANK    ="*ID*========"
               FROM    ="%upcase(&VARIN)*FROM*========"
               ENDP    ="%upcase(&VARIN)* TO *========"
               TOTAL   ='  # OF  *ACCOUNTS*========'
               nind ='  # OF  * INDET    *========'
               nbad='  # OF  * BAD    *========'
               ngood='  # OF  * GOOD   *========'
               PTOT    =' CUM. % *  TOTAL *========'
               ptotbad   =' CUM. % *  BAD   *========'
               ptotgood   =' CUM. % *  GOOD  *========'
               /*PCGAIN  ='   %    *  GAIN  *========'*/
               pcbad  ='INTERVAL*  BAD  %*========'
               cumb ='  CUM.  *  BAD  %*========'
               KS      ='  K.S.  * SPREAD *========'
               ;
    TITLE5 "KS = &KSVALUE";
    TITLE6 "IV = %sysfunc(putn(&IVAL,8.3))";
  %END;
  
  RUN;
  *cleanup for future calls;
  title4;
  title5;
  title6;

%macroend:
%MEND perf;