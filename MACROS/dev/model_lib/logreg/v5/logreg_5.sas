/************************************************************************** 
/* Program Name:		Logreg.sas
/* Author: 					F.Zahradnik
/* Creation Date:   3/31/2008
/* Last Modified:   4/4/2010 - Added UNITDIST parameter to macro call.  
                    3/30/2010 - Removed old score distribution tables with hard coded Good/Bad and replaced
                    with a more generic table.  Also included are two new macro parameters used to create
                    a table recording performance BPS per score interval.
                    
                    4/26/2009 - Fixed bug in varforced parameter that was resetting counter
                    incrementing on single spaces between varforced list.
                    
                    8/27/2008 - Added varforced paramter.  This allows the user to force variables
                    into the logistic model.
                    
                    7/30/2008 - Copy drop_list.txt into iteration folder.
                    Added parameter PERFGRP to control breaks used in gains table.

                    6/15/2008 - Added predictive association statistics to the 
                    report.
                    
                    5/12/2008 - Added arguments goodval, badval to macro call.
                    These allow the user to specify the performance definition
                    for the binary variables.
                    Added resample argument to macro call.  Allows the user to
                    change the seed for holdout validation.
                    Added separate dataset containing details from surveyselect
                    for holdout validation.
                    
										5/5/2008 - Further documentation and manual scoring code
                    added.
                    
                    5/2/2008 - Incorporated code from demo program containing
 										code for reporting.

/* Purpose:         Run logistic regression model and generate model reports and 
										scoring code.        

/* Arguments:       ITERATION - sets counter on iteration folder.  This allows
										for storing several iterations of the model
										ROOTDIR - root directory for the iteration subfolder.  This
										needs to be specified 
										DATADIR - data directory
										DSET - specifies input dataset
										PERFVAR - specifies the performance variable.  This version
										of the macro currently supports only a binary performance
										definition.
										WGHTVAR - specifies the weight variable.
										TPVVAR - optional performance period TPV for score decile BPS report.
                    LOSSVAR - optional performance period losses for score decile BPS report.
                    UNITDIST - Y/N. Run unit score distribution report without using a model weight. Default is N.
										VARFORCED - list of variables to be forced into the model
										EVENTVAL - specifies the definition of the modeling event.  Used as the EVENT
								    value in proc logistic. Defaults to 1.
								    NONEVENTVAL - specified the definition of a non event. Defaults to 0.
								    SAMPLING - Sampling methodology.  Three arguments currently accepted:
								      PROPORTIONAL, FIXED and NOVALID
								    SAMPPROP - Value between 0 and 1 determines holdout validation percentage.
								    Ignored if SAMPLING is not PROPORTIONAL
								    RESAMPLE - Y/N argument re-runs sampling for PROPORTIONAL sampling scheme
								    with a previously defined seed. Defaults to N.
								    SELECTION - variable selection methodology.  Currently supports FORWARD,
								    BACKWARD and STEPWISE
                    PENTRY - value between 0 and 1 specifying variable entry p-value. Default is .01.
                    PEXIT - value between 0 and 1 specifying variable exit p-value.  Default is .01.
			              INTERCEPT - toggle removing intercept from parameter estimation.
			              LINKFUNC - model link function.  As of 3/31, current support for LOGISTIC only.
			              MAXSTEP - maximum number of steps used for Stepwise variable selection.  Defaults to 25.
			              MAXITER - maximum number of iteration to perform.  Ignored if MAXSTEP and SELECTION= STEPWISE
			              Defaults to 99.
			              PERFGRP - Breaks for gains table.  Default is 20.
			              MODELSUB - TRUE/FALSE toggle to generate variable substitution report. Default is FALSE.  
								    

/* Notes:           User defines root directory.  Under the root directory:
										 1. data folder: stores all sets used in modeling process.  This
										 includes development, validation, scored datasets and 
										 score parameter dataset used for out of sample scoring. 
										 
										 2.  iteration folder:  this will be a numbered folder 
										 containing the nth runs model results.  This allows
										 provides a more organized approach to the model development
										 process.
										 
										 3.  drop_list.txt should list all variables that should be dropped from consideration
										 for the model.  
										 
										Process creates several files:
										 1. results.txt: Main output containing summarized model
										 information, including parameter estimates, gains table,
										 and coarses.  Most information coming from existing paypal
										 macros and sas ods output.
										 
										 2. iteration.txt: Redirected SAS output.  Contains stepwise
										 model selection iteration and all corresponding SAS output.
										 
										 3. formats.sas7bdat - dataset containing format definitions for the score distribution.
										 
										 4. replaced_models.txt: Prints model results for model variable
										 substitution macro.  Since running this macro is optional, 
										 this file will not always show up in the iteration folder. 
										 
										 5. formula.txt: Current iteration contains imputation logic
										 and final model formulation.


***************************************************************************/ 
%macro logreg(iteration=,    
	            rootdir=,
	            datadir=,
	            dset=,
	            eventval=1,
	            noneventval=0,
              perfvar=,
              wghtvar=,
              tpvvar=,
              lossvar=,
              unitdist=N,
              varforced=,
              limitmodel=N,
              limititer=,
              sampling=,
              sampprop=,
              resample=N,
              selection=STEPWISE,
              pentry=.01,
              pexit=.01,
			        intercept=,
			        linkfunc=LOGIT,
			        maxstep=25,
			        maxiter=99,
			        perfgrp=20,
			        modelsub=FALSE,
			        NoIterSum=5);

%put;
%put -------------------------------------------------------------------------------------;
%put --- Start %upcase(&sysmacroname)                                                     ;
%put -------------------------------------------------------------------------------------;
%put;

options compress=yes linesize=135;

*include macros required for processing;
%include "&_macropath./general/rdmp_eml.sas";
%include "&_macropath./logreg/v5/coarses_modeling.sas"; /* add GKN version of this codes*/
%include "&_macropath./logreg/v5/modelvar_corr_replacement.sas"; 
%include "&_macropath./logreg/v5/retrieve_original_coarse_list.sas"; 
%include "&_macropath./logreg/v5/get_statistics.sas"; 
%include "&_macropath./general/create_iteration_summary_report.sas"; 
%include "&_macropath./general/scoreformat.sas";
%include "&_macropath./general/scoredist_unit.sas"; /* add GKN version of this code */
%include "&_macropath./general/scoredist_amt.sas";
%include "&_macropath./general/read_summary_statistics_file.sas";
%include "&_macropath./general/create_matrix.sas";

%local vldset;

%IF %length(&iteration)= 0 or %length(&rootdir)=0 %THEN %DO;
  %put;
  %put %upcase(&sysmacroname): Iteration or Root directory not assigned;
  %put;
  %goto macroend;
%END;

%IF %length(&datadir)= 0 %THEN %DO;
  %let datadir = &rootdir.;
%END;

/*Create program paths for data and reports*/
%IF %sysfunc(fileexist(&rootdir)) ^= 1 %THEN %DO;
  %put;
  %put %upcase(&sysmacroname): Root directory does not exist;
  %put
  %goto macroend;
%END;
%ELSE %DO;
  %IF %sysfunc(fileexist(&datadir./data)) ^= 1 %THEN %DO;
    %put;
    %put %upcase(&sysmacroname): Data subfolder not found.  Creating folder;
    %put;
    %sysexec mkdir "&datadir./data" 2>&1 > /dev/null;
   %END; 
   %IF %sysfunc(fileexist(&rootdir/iteration&iteration)) ^=1 %THEN %DO;
     %put;
     %put %upcase(&sysmacroname): Creating iteration&iteration subfolder.;
     %put;
     %sysexec mkdir "&rootdir/iteration&iteration" 2>&1 > /dev/null;
   %END;
%END;

%let path= &rootdir./iteration&iteration.;

libname lrdat "&datadir/data";
libname iter "&rootdir/iteration&iteration";
libname univs "&rootdir/univariate";


 
%IF %sysfunc(exist(&dset)) ^= 1 %THEN %DO;
  %put %upcase(&sysmacroname): Modeling dataset does not exist.;
  %goto macroend;
%END;
%ELSE %DO;
  
  %local dsid;
  %let dsid= %sysfunc(open(&dset));
  
  %IF %sysfunc(varnum(&dsid,&perfvar))=0 %THEN %DO;
    %put;
    %put %upcase(&sysmacroname): %upcase(&perfvar.) not in %upcase(&dset.). Process terminating.;
    %goto macroend;
  %END;
  
  *Look for variables added to the forced in list;
  %local forcecnt;
  %let forcecnt= 0;
  %IF %length(&varforced.) > 0 %THEN %DO;
    %let varforced= %sysfunc(upcase(%sysfunc(compbl(&varforced.))));
    %let forcecnt= %eval(%sysfunc(countc(&varforced.," ")) + 1);
    
    %DO ii=1 %TO &forcecnt.;
      %IF %sysfunc(varnum(&dsid,%scan(&varforced.,&ii.,%str( ))))= 0 %THEN %DO;
        %put;
        %put %upcase(&sysmacroname): %upcase(%scan(&varforced.,&ii.,%str( ))) not in %upcase(&dset.). Process terminating.;
        %put;
        %goto macroend;
      %END;
    %END;
    
  %END;
  
  %local rc;
  %let rc= %sysfunc(close(&dsid.));
    
  proc sql noprint;
    select count(distinct &perfvar)
	  into : __perfcnt
	  from &dset.;
  quit;
  
  %IF &__perfcnt = 1 %THEN %DO;
    %put %upcase(&sysmacroname): One performance category defined.  Processing terminating.;
	  %goto macroend;
  %END;
  %ELSE %IF %upcase(&linkfunc) ne GLOGIT and &__perfcnt > 2 %THEN %DO;
    %put %upcase(&sysmacroname):  Multinomial performance definition found, GLOGIT not specified.;
	%goto macroend;
  %END;
  %ELSE %DO; /*Start performance check BLOCK*/
    
    /* SAMPLING 
       Macro accepts three samping parameter values: PROPORTIONAL, FIXED and NOVALID
       PROPORTIONAL: Uses surveyselect to split input dataset into development and validation data based
         on the sampprop parameter.  This method also allows the sampling seed to be retained between runs
         with the resample argument.  Currently no check to prevent validation set from being created.
       FIXED: Assumes that development/validation sets have been created.  Validation is checked for and not 
         assumed.  Datasets need to exist in the DATA subfolder under root and been named build and valid.
         Datasets still need to contain common variable set including performance and weight variables.
       NOVALID:  No validation dataset is assumed to exist for downsteam calculation.  Dataset specified 
         by dset is used as development set.
    */
    
    %IF %upcase(&sampling) = PROPORTIONAL %THEN %DO;
        
        %IF %sysfunc(exist(lrdat.sampling)) and %upcase(&resample)=N %THEN %DO;
          data _null_;
          	set lrdat.sampling;
          	where upcase(strip(label1))= 'RANDOM NUMBER SEED';
          	call symput('seed',nvalue1);
          run;
          
          ods output Summary =ss_sum;
          proc surveyselect data=&dset out=split seed=&seed. samprate=&sampprop. outall;
          run;
        %END;
        %ELSE %DO;
          ods output Summary =ss_sum;
          proc surveyselect data=&dset out=split samprate=&sampprop. outall;
          run;
          
          data lrdat.sampling;
          	set ss_sum;
          run;
        %END;
        
        data _null_; *symput seed and weight;
        	set ss_sum;
        	
        	if upcase(strip(label1))= 'RANDOM NUMBER SEED' then do;
        	  call symput('sampseed',nvalue1);
        	end;
        	
        run;
        
        data lrdat.build lrdat.valid;
        	set split;
        	if selected=1 then output lrdat.build;
        	else if selected=0 then output lrdat.valid;
        run; 
    %END;
    
    %IF %upcase(&sampling) = FIXED %THEN %DO;
      %IF %sysfunc(exist(lrdat.build)) ^= 1 and %sysfunc(exist(lrdat.valid)) ^= 1 %THEN %DO;
        %put;
        %put %upcase(&sysmacroname): Building/Validation datasets do not exist.;
        %put;
        %goto macroend;
      %END;
      %ELSE %IF %sysfunc(exist(lrdat.build)) ^1 %THEN %DO;
        %put;
        %put %upcase(&sysmacroname): Building dataset does not exist;
        %put;
      %END;
      %ELSE %IF %sysfunc(exist(lrdat.build)) = 1 and %sysfunc(exist(lrdat.valid)) ^= 1 %THEN %DO;
        %put;
        %put %upcase(&sy
        smacroname): No validation set.  Continuing as if NOVALID specified.;
        %put;
        %let vldset= 0;
      %END;
    %END;
    
    %IF %upcase(&sampling) = NOVALID %THEN %DO;
        data lrdat.build;
        	set &dset;
        run; 
        %let vldset= 0;
    %END;
    
    *Set results output filename;
    filename res "&path./results.txt";   
    filename coarses "&path./model_coarses.txt";   
    
    /*Count sample volume*/
    proc means data=lrdat.build noprint n sumwgt;
      var &perfvar.;
      weight &wghtvar.;
      output out=_buildstat n=n sumwgt=sumwgt;
    run;
    
    data _null_;
    	set _buildstat;
    	call symput('_bldsamp',n);
    	call symput('_wbldsamp',sumwgt);
    run;
    
    %IF &vldset ^= 0 %THEN %DO;
      proc means data=lrdat.valid noprint n sumwgt;
      	var &perfvar.;
      	weight &wghtvar.;
      	output out=_validstat n=n sumwgt=sumwgt;
      run;
      
      data _null_;
      	set _validstat;
      	call symput('_vldsamp',n);
      	call symput('_wvldsamp',sumwgt);
      run;
    %END;
    
    
    
    
    
    *Generate dataset containing candidate variables;
    data mod_build;
    	set lrdat.build;
    	%include "&rootdir/drop_list.txt";
    	%include "&rootdir/drop_orig_woes.txt";
    	%IF %length(&varforced.) > 0 %THEN %DO;
    	  drop &varforced.;
    	%END;
    	
    	stop;
    run;
    
    proc contents data=mod_build noprint out=_contents(keep=name type );
    run;
    
    
    *Make sure to remove type=2 (CHAR) Vars gkn 8/5/2010;
    
    DATA _contents (drop=type);
    	 SET _contents;
    	 where type~=2;
    RUN; 	     
          
       
                               
    /* Enable user to limit the model by keeping variables from a prior iteration.
       1. check that the iteration folder specified exists and that there is a copy of model.sas7bdat
       2. keep only the variables used in the model by via inner join onto the _contents temp dataset.
    */
    
    %IF %upcase(&limitmodel.)= Y %THEN %DO;
      
      %IF %sysfunc(fileexist(&limititer.)) ^= 1 %THEN %DO;
        %put;
        %put %upcase(&sysmacroname): Limit model iteration directory does not exist.  Terminating.;
        %put;
        %goto macroend;
      %END;
      
      libname limitlib "&limititer.";
      
      %IF %sysfunc(exist(limitlib.model)) ^= 1 %THEN %DO;
        %put;
        %put %upcase(&sysmacroname): Limit model dataset does not exist.  Terminating.;
        %put;
        %goto macroend;
      %END;
      
      proc sql noprint;
      	  select a.variable 
      	    into: modvars separated by " "
      	  from limitlib.model a
      	  inner join _contents b
      	  on a.variable = b.name
      	  where upcase(a.variable) ne "INTERCEPT"
      	;
      quit;
      
    %END; 
    
    %IF %upcase(&limitmodel.) ^= Y %THEN %DO;
    
      proc sql noprint;
      	select name into: modvars separated by " "
      	from _contents
      	where upcase(trim(name)) not in ("%upcase(&perfvar)","%upcase(&wghtvar)","SELECTED")
      ;
      quit;
    %END;
    
    
    /*Write data header detailing iteration, model description, candidate variable
     and sample volumes. */
    data _null_;
    	x= repeat('*',90);
    	file res linesleft=remain pagesize=80;	
    	
    	put @1 x;
    	put @1 "Iteration &iteration:  ";
    	put @1 "Sampling Method: &sampling.";
    	
    	%IF %upcase(&sampling.)= PROPORTIONAL %THEN %DO;
    	  put @1 "Sampling Seed: &sampseed.";
    	%END;
    	
    	put @1 "Build Sample Volume: %qcmpres(%nrquote(%sysfunc(putn(&_bldsamp.,comma10.))))";
    	put @1 "Weighted Sample Volume: %qcmpres(%nrquote(%sysfunc(putn(&_wbldsamp.,comma10.))))";
    	
    	%IF &vldset ^= 0 %THEN %DO;
    	  put @1 "Validation Sample Volume: %qcmpres(%nrquote(%sysfunc(putn(&_vldsamp.,comma10.))))";
    	  put @1 "Weighted Sample Volume: %qcmpres(%nrquote(%sysfunc(putn(&_wvldsamp.,comma10.))))";
    	%END;
    		
    	put @1 " " //;	
    		
    	if remain < 10 then put _page_;
    run;      
    
    
    
    ods output ModelInfo=modelinfo;
    ods output NObs= nobs;
    ods output ParameterEstimates=pe;
    ods output OddsRatios= odds;
    ods output Association=assoc;
    ods output LackFitChiSq= lackfit;
    ods output LackFitPartition= lackpart; 
    ods output CorrB= corrb;
    ods output CovB= covb;
        
    ods listing file="&rootdir/iteration&iteration./iteration.txt";
    
    proc logistic data=lrdat.build outmodel=lrdat.scoreset namelen=32;
    	%IF %upcase(&limitmodel.) = Y %THEN %DO;
      model &perfvar.(event="&eventval.") = 
    	                %IF %length(&varforced.) > 0 %THEN %DO;
    	                  &varforced.
    	                %END;
    	                &modvars. 
    	        /
      %END;        
    	%ELSE %DO;            	                
    	model &perfvar.(event="&eventval.") = 
    	                %IF %length(&varforced.) > 0 %THEN %DO;
    	                  &varforced.
    	                %END;
    	                &modvars. 
    	      / selection = &selection.
    	        slentry= &pentry.
    	        slstay= &pexit.
    	        %IF %length(&varforced.) > 0 %THEN %DO;
    	          include=&forcecnt.
    	        %END;
    	        %IF %upcase(&selection)= STEPWISE and %length(&maxstep) > 0 %THEN %DO;
    	          maxstep=&maxstep.
    	        %END;
    	        %IF (%upcase(&selection)= FORWARD or %upcase(&selection)= BACKWARD) and %length(&maxstep) > 0 %THEN %DO;
    	          stop= &maxstep.
    	        %END;
      %END;
    	        maxiter= &maxiter.
    	        outroc=bldroc
    	        rsq
    	        lackfit
    	        corrb
    	        covb;
    	output out=lrdat.scrbld p=predicted h=h reschi=reschi resdev=resdev difchisq=difchisq difdev=difdev /*dfbetas=_all_*/;
    	%IF %length(&wghtvar) > 0 %THEN %DO;
    	  weight &wghtvar.;
    	%END; 
    run;
    ods listing;
    
    proc format;
    	value $PRFLAB "PREDICTED"   = "Development"
    	              "P_&eventval." = "Validation"
    	              "TOTALPRED"   = "Total"
    	;
    run;
    
    proc sql noprint;
    select variable
    	  into: _finalmodel separated by " "
    	  from pe
    	  where upcase(compress(variable)) not in ("INTERCEPT")
    	;
    	
    create table iter.model as
      select *
      from pe
    ;
    	
    quit;
    
    *Generate summary statistics for building dataset;
    %rdmp_grpKSIV(dset=lrdat.scrbld,targvar=predicted,perfvar=&perfvar.,wghtvar=&wghtvar.,ngroup=10,supprint=YES,oset=summary_stat);
    
    %scoreformat(dset=lrdat.scrbld,perfvar=&perfvar.,wghtvar=&wghtvar.,scrvar=predicted,
                 nbreak=&perfgrp.,eval=&eventval.,neval=&noneventval.,fmtname=SCRBLD&iteration.N);
    
    
    %IF &vldset ^= 0 %THEN %DO;
      ods listing close;
      proc logistic inmodel=lrdat.scoreset;
      	score data=lrdat.valid out=lrdat.scrvld outroc=vldroc;
      	%IF %length(&wghtvar) > 0 %THEN %DO;
      	  weight &wghtvar.;
      	%END;
      run;
      ods listing;
      
      %rdmp_grpKSIV(dset=lrdat.scrvld,targvar=P_&eventval.,perfvar=&perfvar.,wghtvar=&wghtvar.,ngroup=10,supprint=YES,oset=summary_stat);
      
      %scoreformat(dset=lrdat.scrvld,perfvar=&perfvar.,wghtvar=&wghtvar.,scrvar=p_&eventval.,
                 nbreak=&perfgrp.,eval=&eventval.,neval=&noneventval.,fmtname=SCRVLD&iteration.N);
      
      data lrdat.scrtotal;
      	set lrdat.scrbld (in=a)
      	    lrdat.scrvld (in=b);
      	if a then totalpred= predicted;
      	if b then totalpred= p_&eventval.;
      	  
      run;
      
      %rdmp_grpKSIV(dset=lrdat.scrtotal,targvar=totalpred,perfvar=&perfvar.,wghtvar=&wghtvar.,ngroup=10,supprint=YES,oset=summary_stat);
      %scoreformat(dset=lrdat.scrtotal,perfvar=&perfvar.,wghtvar=&wghtvar.,scrvar=totalpred,
                 nbreak=&perfgrp.,eval=&eventval.,neval=&noneventval.,fmtname=SCRTOT&iteration.N);
      
    %END;
    %ELSE %DO;
      data lrdat.scrtotal;
      	set lrdat.scrbld (in=a);
      	totalpred= predicted;
      	
      run;
    %END;
    
    ** output score formats;
    proc format library=work cntlout=iter.formats;
    run;
    
    
    *Create macro variables and intermediate tables for further calculations;
    proc sql noprint;
    	select KS,IVAL
    	into: __KS separated by " ",
    	    : __IV separated by " "
    	from summary_stat;
     
    quit;
    
    proc sql noprint;
    	select variable,estimate
    	  into: _finalmodel separated by " ",
    	      : _pests separated by " "
    	  from pe
    	  where upcase(compress(variable)) not in ("INTERCEPT")
    	;
    	
    quit;
    
   /* Create table summarizing top 5% correlation values in model.
      Table created for reporting: corrsum */
    %IF %sysfunc(exist(corrb)) %THEN %DO;
      %corrsum(dset=corrb);
    %END;
    
   /*Calculate VIF.  There are two variant calculations, one
     with a weight calculated using p_hat multiplied by 
     1 - p_hat.  Table created for reporting: _vif */
     
    data forvif;
    	set lrdat.scrbld;
    	w= predicted*(1-predicted);
    run;
    
    ods listing close;
    
    ods output ParameterEstimates= vif;
    
    proc reg data=lrdat.scrbld;
    	model &perfvar. = &_finalmodel. /tol vif;
    run;
    
    data _null_; *flush ods path -kludge;
    run;

    
    ods output ParameterEstimates= wvif;
    proc reg data=forvif;
    	weight w;
    	model &perfvar. = &_finalmodel. /tol vif;
    run;
    
    ods listing;
    
    proc sql noprint;
    	create table _vif as
    	  select upcase(a.variable) as variable
    	        ,a.varianceinflation as vif
    	        ,b.varianceinflation as wvif
    	  from vif a,wvif b
    	  where a.variable=b.variable 
    	    and upcase(a.variable) ~= "INTERCEPT"
    	;
    quit;
    /*End VIF calculation*/
    
    
    /*Reporting section*/
    
    *Prints KS/IV statistics;
    data _null_;
    	set summary_stat end=last;
    	file res linesleft=remain pagesize=80 mod;
    	if _n_=1 then do;
    		put @1 "Model Summary Statistics" /;
    		put @1 "Source" @18 "KS" @27 "IV";
    		put @1 35*'-' /;
      end;
      format varname $PRFLAB.;
      put @1 varname @18 KS 8.2 @27 IVAL 8.3;
      
      if last then do;
      	put @1 " " //;
      end;
      
      if remain < 10 then put _page_;
      
    run;
    
    *Print association statistics for development set;
    data _null_;
    	set assoc end=last;
    	file res linesleft=remain pagesize=80 mod;
    	if _n_=1 then do;
    		put @1 "Association of Predicted Probabilities and Observed Responses" //;
    	end;
    	
    	put @1 label1
    	    @22 cvalue1
    	    @34 label2
    	    @46 cvalue2
    	;
    	
    	if last then do;
    		put @1 " " //;
    	end;
    	
    	if remain < 10 then put _page_;
    run;
    
    proc sort data=pe;
    	by descending waldchisq;
    run;
    
    *Print parameter estimates;
    data _null_;
      set pe end=last;
      file res linesleft=remain pagesize=80 mod;
      if _n_=1 then do;
      	put @1 "Parameter Estimates" /;
      	put @59 "Standard" @72 "Wald" @83 "Prob.";
      	put @1 "Variable" @35 "DF" @45 "Estimate" @59 "Error" @72 "Chi Sq." @83 "Chi Sq.";
      	put @1 100*'-' /;
      end;
      
      varn= upcase(variable);
      put @1 varn
          @35 df
          @45 estimate BEST8.
          @59 stderr 8.4
          @72 WaldChiSq 8.3
          @83 probchisq 8.3
      ;
      
      if last then do;
      	put @1 " " //;
      end;
      
      if remain < 10 then put _page_;
      
    run; 
    
    *Print VIF estimates; 
    data _null_;
      set _vif end=last;
      
      file res linesleft=remain pagesize=80 mod;
      
      if _n_=1 then do;
      	put @1 "Variance Inflation Factor" /;
      	put @1 "Variable" @35 "Weighted*" @48 "Unweighted";
      	put @37 "VIF" @52 "VIF";
      	put @1 60*'-';
      end;
      
      put @1 Variable @35 vif 8.3 @48 wvif 8.3;
      
      if last then do;
      	put / @1 "*Weight reflects phat(1-phat) adjustment.";
      	put @1 " "//;
      end;
      
      if remain < 10 then put _page_;
    run;
    
    *Print summarized correlation statistics;
    %IF %sysfunc(exist(corrsum)) %THEN %DO;
    data _null_;
    	set corrsum end=last;
    	
    	_one= upcase(one);
    	_two= upcase(two);
    	
    	file res linesleft=remain pagesize=80 mod;
    	
    	if _n_=1 then do;
    		put @1 "Estimated Correlation Matrix Summarization";
    		put @1 "Examine the top 5% pairwise correlations";
    		put @1 "Full correlation matrix is in the supplemental file ITERATION.TXT" /;
    		
    		put @78 "Correlation";
    		put @1 "Variable 1" @34 "Variable 2" @78 "Coefficient";
    		put @1 90*'-';
    	end;
    	
    	put @1 _one @34 _two @78 corr_val 8.3;
    	
    	if last then do;
    		put @1 " " //;
    	end;
    	
    	if remain < 10 then put _page_;
    	
    run;
    %END;
    
    /* Added Univariates and moved Coarses 8/5/gkn */
  
    %retrieve_original_coarse_list(modelingset=lrdat.build,parameterset=pe,outset=wpe);
    
    DATA wpe;
    	length name $32.;
    	 SET pe (In=InA) wpe (IN=InB);
    	 If inB then do; name=compress("w"||variable); order=2; end;
    	 else do; name=variable; order=1;  type=1; end;
    RUN;	 
    
    proc sort data=wpe out=wpe (drop=name order);
    	by name order;
    RUN;	
   
    	 
    %gencoarses(dset=lrdat.build,estset=wpe,perfvar=&perfvar.,wghtvar=&wghtvar.,
                eval=&eventval.,neval=&noneventval.,outfile=coarses, report=report)
                
                
    **pull pre-impute stats;
  
    proc sort data=wpe (KEEP=variable) out=pe_preimpute (RENAME=(variable=varname)) nodupkey;
    	by variable;
    RUN;
    
    
    proc sort data=univs.seg_numeric out=preimpute_univs;
    	by varname;		
    RUN;
    
    DATA 	preimpute_univs;
    	MERGE pe_preimpute (in=ina) preimpute_univs (in=inB);
    	by varname;
    	if ina and inb;
    RUN;	
                
                
    *Print Univariates;
     proc printto print=res;
    	options nodate nonumber nocenter formdlim= " ";
    	%desc_pre_impute(inset=preimpute_univs,title=PRE-IMPUTATION DESCRIPTIVE STATS);
    	
      proc printto;	           
    
    
    
    
    
    
    **pull post-impute stats;            
    proc printto print=res;
    	options nodate nonumber nocenter formdlim= " ";
    	%DESC_F(report,POST-IMPUTATION DESCRIPTIVE STATS);
    	
    proc printto;	           
    
    options nodate nonumber nocenter formdlim= " ";
    *print score distribution using modified perfgain macro;
    data _null_;
    	file res mod;
    	put "  ";
    	put "  ";
    	put "  ";
    	put @1 "Score Distribution" /;
    run;
    
    proc printto print=res;
    run;
      
      %scoredist_unit(dset=lrdat.scrbld,perfvar=&perfvar.,wghtvar=&wghtvar.,scrvar=predicted,
                       eval=&eventval.,neval=&noneventval.,fmtname=SCRBLD&iteration.N,distname=Development,Alert=Alert_WBLD);
      
      %IF %upcase(&unitdist.)= Y or %upcase(&unitdist.)= YES %THEN %DO;
        %scoredist_unit(dset=lrdat.scrbld,perfvar=&perfvar.,wghtvar=,scrvar=predicted,
                       eval=&eventval.,neval=&noneventval.,fmtname=SCRBLD&iteration.N,distname=Development - Unweighted);
      %END;
      
      
      %IF %length(&tpvvar.) ^= 0 and %length(&lossvar.) ^= 0 %THEN %DO;
        %scoredist_amt(dset=lrdat.scrbld,perfvar=&perfvar.,wghtvar=&wghtvar.,scrvar=predicted,
                       tpvvar=&tpvvar.,lossvar=&lossvar.,fmtname=SCRBLD&iteration.N,distname=Development);
      %END;
      
    	%IF &vldset ^= 0 %THEN %DO;
    	
    	   %scoredist_unit(dset=lrdat.scrvld,perfvar=&perfvar.,wghtvar=&wghtvar.,scrvar=p_&eventval.,
                          eval=&eventval.,neval=&noneventval.,fmtname=SCRVLD&iteration.N,distname=Validation,Alert=Alert_WVLD);
         
         %IF %upcase(&unitdist.)= Y or %upcase(&unitdist.)= YES %THEN %DO;
           %scoredist_unit(dset=lrdat.scrvld,perfvar=&perfvar.,wghtvar=,scrvar=p_&eventval.,
                           eval=&eventval.,neval=&noneventval.,fmtname=SCRVLD&iteration.N,distname=Validation - Unweighted);
         %END;
         
         %IF %length(&tpvvar.) ^= 0 and %length(&lossvar.) ^= 0 %THEN %DO;
           %scoredist_amt(dset=lrdat.scrvld,perfvar=&perfvar.,wghtvar=&wghtvar.,scrvar=p_&eventval.,
                          tpvvar=&tpvvar.,lossvar=&lossvar.,fmtname=SCRVLD&iteration.N,distname=Validation);
         %END;
    	
    	   %scoredist_unit(dset=lrdat.scrtotal,perfvar=&perfvar.,wghtvar=&wghtvar.,scrvar=totalpred,
                          eval=&eventval.,neval=&noneventval.,fmtname=SCRTOT&iteration.N,distname=Total,Alert=Alert_WTOT);
         
         %IF %upcase(&unitdist.)= Y or %upcase(&unitdist.)= YES %THEN %DO;
           %scoredist_unit(dset=lrdat.scrtotal,perfvar=&perfvar.,wghtvar=,scrvar=totalpred,
                           eval=&eventval.,neval=&noneventval.,fmtname=SCRTOT&iteration.N,distname=Total - Unweighted);
         %END;
         
         %IF %length(&tpvvar.) ^= 0 and %length(&lossvar.) ^= 0 %THEN %DO;
           %scoredist_amt(dset=lrdat.scrtotal,perfvar=&perfvar.,wghtvar=&wghtvar.,scrvar=totalpred,
                          tpvvar=&tpvvar.,lossvar=&lossvar.,fmtname=SCRTOT&iteration.N,distname=Total);
         %END;
    	
    	      
    	%END;
    	
    proc printto;
    run;
    options date number;
    
    
    data _null_;
    	if _n_=1 then set lackfit;
    	set lackpart end=last;
    	
    	file res linesleft=remain pagesize=80 mod;
    	
    	if remain < 10 then put _page_;
    	
    	if _n_=1 then do;
    		put @1 //"Development Goodness of Fit";
    		put @1 "Test the null hypothesis that the model fits the data" /;
    		put @35 "Prob.";
    		put @1 "Chi Sq." @22 "DF" @35 "Chi Sq.";
    		put @1 45*"-";
    		put @1 ChiSq @22 DF @35 ProbChiSq /;
    	
        put "Development Goodness of Fit Partition" /;	
    		put @23 "Events" @33 "Events" @42 "Nonevents" @52 "Nonevents";
    		put @1 "Group" @10 "Total" @22 "Observed" @32 "Expected" @42 "Observed" @52 "Expected";
    		put @1 60*'-';
    	end;
    	
    	put @1 group @10 total @22 EventsObserved @32 EventsExpected @42 NoneventsObserved @52 NoneventsExpected;
      
      if last then do;
      	put @1 " " //;
      end;
    run;
    
    
    /* cat coarses from gencoarses call above */
     
    
    %IF %upcase(%trim(&modelsub.))= TRUE %THEN %DO;
    data _null_;
    	file res pagesize=80 mod;
    	put @1 / "Model Variable Substitution Parameter Estimates";
      put @1 "Base Model KS: %sysfunc(putn(%scan(&__KS.,1,%str( )),8.2))";
      put @1 "Base Model IV: %sysfunc(putn(%scan(&__IV.,1,%str( )),8.3))" / ;
    
   
      /* Code creates a list of alternate variables that are close to modeling vars wrt corr value - FZ */
      options nodate nonumber nocenter;
      proc printto print=res;run;
      
      %model_corr_replace(dset=lrdat.build,
                          perfvar=&perfvar.,
                          wghtvar=&wghtvar.,
                          varlist=&_finalmodel.,
                          path=&path.,
                          _modKS=%sysfunc(putn(&__KS.,8.2)),
                          _modIV=%sysfunc(putn(&__IV.,8.3)),
                          rhothresh=.2);   
      proc printto; run;
      options date number; 
    %END;        
    
 /*CREATE SUMMARY OF THIS PLUS PREVIOUS ITERATIONS*/
    
 x "cat &path/results.txt &path./model_coarses.txt  > temp_merge.txt";
 x "mv temp_merge.txt &path/results.txt";
 x "rm &path./model_coarses.txt";
    
    
 %get_statistics;   
 
 ** GET ITERATION NUMBERS ;
 data _null_; 
 if ((%eval(&iteration. lt &NoIterSum.)) )then do;
  call symput ('NoIterSum',compress(put(&iteration. ,12.)) ) ;
  end;
 run;
 
 data _null_;
  call symput('startit',compress(put(%eval(&iteration. -&NoIterSum. +1),12.)));
 run;
 
%do i=&startit %to &iteration;
    %read_summary_stats_file(name=&i.,indir=&rootdir./iteration&i.,outset=_summarystats);
%end;
 
%Write_Iteration_Report(inset=_summarystats,iterationout=&rootdir./iteration_summary.txt);

%do i=&startit %to &iteration;
 %read_model_for_matrix(name=Iteration&i,dir=&rootdir./iteration&i.,dout=iter&i.);
%end;

DATA matrix;
	MERGE %do i=&startit %to &iteration;
	           Iter&i          
	      %end; ;
	      
	 by variable;     	
RUN;	
 
%write_matrix(dset=matrix,matrixout=&rootdir./iteration_matrix.txt);
 
*********************************************************************;
** START CREATING OUTPUT FOR IMPLEMENTATION                        **;
*********************************************************************;    

  /* OUTPUT NULL WEIGHT TABLE  Added 8/11/2010 */
    
  proc sort data=report (keep=name mean) out=report_null (rename=(name=variable));
  	by name;
  RUN;	
  
  proc sort data=pe;
  	by variable;
  RUN;	
  
  DATA null_weight_table;
  	 MERGE pe (In=Ina KEEP=variable) report_null;
  	 by variable;
  	 if InA;
  	 file "&path./NULL_WEIGHT.TXT" dlm=",";
  	 if _n_=1 THEN PUT "Variable, Null Weight";
  	 if variable~="Intercept" THEN put Variable mean;
  RUN; 	 
  	 
     	





    /*Added 5/5/08
      Create text scoring code.  The current iteration requires calls to
      woe flag generation, imputation and truncation*/
      
    data _null_;
    	length cest $ 32 param $ 100;
    	set pe(keep=variable estimate) end=last;
    	if estimate < 0 then sgn= '-';
    	else sgn= '+';
    	aest= abs(estimate);	
    	cest= putc(aest,32.);
    	
    	if upcase(variable)= "INTERCEPT" then param= trim(sgn||" "||abs(estimate));
      else param= trim(sgn||" "||trim(cest)||"*"||trim(upcase(variable)));
    	
    	file "&path./formula.txt";
    	format estimate 10.8;
    	if _n_ = 1 then do;
    		put @1 "score= ";
    	end;
    	put @5 param;
    	if last then put @1 ";";
    run;
    
  %END; /* Performance definition check */
%END;  /* Dataset existence check */


%sysexec cp "&rootdir./drop_list.txt" "&rootdir./iteration&iteration./.";
%sysexec cp "&rootdir./1_impute_modeling_data.sas" "&rootdir./iteration&iteration./.";
%sysexec cp "&rootdir./2_run_model.sas" "&rootdir./iteration&iteration./.";
%sysexec cp "&rootdir./coarses/flag_logic.txt" "&rootdir./iteration&iteration./.";
%sysexec cp "&rootdir./gensq_call.sas" "&rootdir./iteration&iteration./.";
%sysexec cp "&rootdir./genstat.sas7bdat" "&rootdir./iteration&iteration./.";
%sysexec cp "&rootdir./keep_woe_vars.sas" "&rootdir./iteration&iteration./.";
%sysexec cp "&rootdir./include_woe_vars.sas" "&rootdir./iteration&iteration./.";
%sysexec cp "&rootdir./drop_orig_woes.txt" "&rootdir./iteration&iteration./.";


%IF %upcase(&sampling) ~= FIXED %THEN %DO;

DATA iter.sampling;
  SET lrdat.sampling;
RUN;

%END;



/*Perform some clean up*/
libname lrdat clear;
libname iter clear;




%macroend: %put;
%put -------------------------------------------------------------------------------------;
%put --- End %upcase(&sysmacroname)                                                       ;
%put -------------------------------------------------------------------------------------;
%put;        	
    
%mend logreg;
