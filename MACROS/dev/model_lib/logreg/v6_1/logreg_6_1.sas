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
						  FINALITER- YES/NO. Yes, if the current iteration is the final one, else no.
								    

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
	            /* New parameters added */
				project_name=,
				population_label=,
				segment=,
	            eventval=,
	            noneventval=,
				event_label=,
				nonevent_label=,
				/* *********************/
              perfvar=,
              wghtvar=,
              modelwgt=,
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
			        NoIterSum=5,
			        /* New parameters added */
					score_out=scaledscore,
					_scoreref=600,
					_PDO=20,
					_odds=20,
					min_scaledscore=1,
					max_scaledscore=1000,
					Finaliter=
					/* ***********************/
					);

%put;
%put -------------------------------------------------------------------------------------;
%put --- Start %upcase(&sysmacroname)                                                     ;
%put -------------------------------------------------------------------------------------;
%put;

options compress=yes linesize=135;

**clean up files;

 x "rm -R iteration&iteration. ";
 x "dos2unix keep_woe_vars.sas > keep_woe_vars.sas";

*include macros required for processing;
%include "&_macropath./general/rdmp_eml.sas";
%include "&_macropath./logreg/v6/coarses_modeling.sas"; /* add GKN version of this codes*/
%include "&_macropath./logreg/v6/modelvar_corr_replacement.sas"; 
%include "&_macropath./logreg/v6/retrieve_original_coarse_list.sas"; 
%include "&_macropath./logreg/v6/get_statistics.sas"; 
%include "&_macropath./general/create_iteration_summary_report.sas"; 
%include "&_macropath./general/scoreformat.sas";
%include "&_macropath./general/scoredist_unit.sas"; /* add GKN version of this code */
%include "&_macropath./general/scoredist_amt.sas";
%include "&_macropath./general/read_summary_statistics_file.sas";
%include "&_macropath./general/create_matrix.sas";
%include "&_macropath./general/population_stability.sas";
%include "&_macropath./general/score_distribution.sas";
%include "&_macropath./general/char_stab_report.sas";
%include "&_macropath./general/score_scaling.sas";

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
      	where upcase(trim(name)) not in ("%upcase(&perfvar)","%upcase(&wghtvar)","SELECTED","%upcase(&modelwgt)")
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
    	%IF %length(&modelwgt) > 0 %THEN %DO;
    	  weight &modelwgt.;
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
      	%IF %length(&modelwgt) > 0 %THEN %DO;
      	  weight &modelwgt.;
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
                eval=&eventval.,neval=&noneventval.,outfile=coarses, report=report);
                
                
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
	
	/* Changed by J. Kohli on 12/08/2011 ****** Added functionality to report scaled score, raw score */
	  
	 /* Score scaling depending on user input */
	%score_scaling(data_in=lrdat.scrtotal,data_out=scaletotal,score_output=&score_out.,scoreRef=&_scoreRef.,PDO=&_PDO.,ODDS=&_ODDS.,variable=totalpred,min=&min_scaledscore.,max=&max_scaledscore.);
	%score_scaling(data_in=lrdat.scrbld,data_out=scalebld,score_output=&score_out.,scoreRef=&_scoreRef.,PDO=&_PDO.,ODDS=&_ODDS.,variable=predicted,min=&min_scaledscore.,max=&max_scaledscore.);
	
	%IF %sysfunc(exist(lrdat.scrVLD)) = 1 %THEN %DO;
	    %score_scaling(data_in=lrdat.scrvld,data_out=scalevld,score_output=&score_out.,scoreRef=&_scoreRef.,PDO=&_PDO.,ODDS=&_ODDS.,variable=p_&eventval.,min=&min_scaledscore.,max=&max_scaledscore.);
    %END;
      
      %scoredist_unit(dset=lrdat.scrbld,perfvar=&perfvar.,wghtvar=&wghtvar.,scrvar=predicted,
                       eval=&eventval.,neval=&noneventval.,fmtname=SCRBLD&iteration.N,distname=Development,Alert=Alert_WBLD);
      
      %IF %upcase(&unitdist.)= Y or %upcase(&unitdist.)= YES %THEN %DO;
        %scoredist_unit(dset=lrdat.scrbld,perfvar=&perfvar.,wghtvar=,scrvar=predicted,
                       eval=&eventval.,neval=&noneventval.,fmtname=SCRBLD&iteration.N,distname=Development - Unweighted);
      %END;
      
      
      %IF %length(&tpvvar.) ^= 0 and %length(&lossvar.) ^= 0 %THEN %DO;
        %scoredist_amt1(dset=lrdat.scrbld,perfvar=&perfvar.,wghtvar=&wghtvar.,scrvar=predicted,
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
           %scoredist_amt1(dset=lrdat.scrvld,perfvar=&perfvar.,wghtvar=&wghtvar.,scrvar=p_&eventval.,
                          tpvvar=&tpvvar.,lossvar=&lossvar.,fmtname=SCRVLD&iteration.N,distname=Validation);
         %END;
    	
    	   %scoredist_unit(dset=lrdat.scrtotal,perfvar=&perfvar.,wghtvar=&wghtvar.,scrvar=totalpred,
                          eval=&eventval.,neval=&noneventval.,fmtname=SCRTOT&iteration.N,distname=Total,Alert=Alert_WTOT);
         
         %IF %upcase(&unitdist.)= Y or %upcase(&unitdist.)= YES %THEN %DO;
           %scoredist_unit(dset=lrdat.scrtotal,perfvar=&perfvar.,wghtvar=,scrvar=totalpred,
                           eval=&eventval.,neval=&noneventval.,fmtname=SCRTOT&iteration.N,distname=Total - Unweighted);
         %END;
         
         %IF %length(&tpvvar.) ^= 0 and %length(&lossvar.) ^= 0 %THEN %DO;
           %scoredist_amt1(dset=lrdat.scrtotal,perfvar=&perfvar.,wghtvar=&wghtvar.,scrvar=totalpred,
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
 /* x "rm &path./model_coarses.txt"; */
    
    
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

    /* Added 5/5/08
      Create text scoring code.  The current iteration requires calls to
      woe flag generation, imputation and truncation */
      
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

/* ***********************************************************************************************************
Business Report and Summary stats for all segments --- Created by J. Kohli - Last modified : 09/07/2011
**************************************************************************************************************/
%IF %upcase(&finaliter.) = YES %THEN %DO;

options pagesize=max;

	%IF %sysfunc(fileexist(Final_Stats)) ^=1 %THEN %DO;
		%put;
		%put %upcase(&sysmacroname): Creating Final_Stats subfolder.;
		%put;
		%sysexec mkdir "Final_Stats" 2>&1 > /dev/null;
	%END;
	
	%IF %sysfunc(fileexist(Final_Stats/Population_Stability)) ^=1 %THEN %DO;
		%put;
		%put %upcase(&sysmacroname): Creating Final_Stats/population_stability subfolder.;
		%put;
		%sysexec mkdir "&rootdir./Final_Stats/Population_Stability" 2>&1 > /dev/null;
	%END;
	
	%IF %sysfunc(fileexist(Final_Stats/Char_analysis)) ^=1 %THEN %DO;
		%put;
		%put %upcase(&sysmacroname): Creating Final_Stats/char_analysis subfolder.;
		%put;
		%sysexec mkdir "&rootdir./Final_Stats/Char_analysis" 2>&1 > /dev/null;
	%END;
	
	%IF %sysfunc(fileexist(Final_Stats/Score_distribution)) ^=1 %THEN %DO;
		%put;
		%put %upcase(&sysmacroname): Creating Final_Stats/score_distribution subfolder.;
		%put;
		%sysexec mkdir "&rootdir./Final_Stats/Score_distribution" 2>&1 > /dev/null;
	%END;
	
	data _null_; 
		call symput('currdate',put(date(),weekdate32.)); 
		call symput('currtime',put(time(),hhmm5.));  
	run;

	
	x cp "&rootdir./iteration&iteration./sampling.sas7bdat" "&rootdir./Final_Stats/"; 
	x cp "&rootdir./iteration&iteration./keep_woe_vars.sas" "&rootdir./Final_Stats/"; 
	x cp "&rootdir./iteration&iteration./include_woe_vars.sas" "&rootdir./Final_Stats/"; 
	x cp "&rootdir./iteration&iteration./genstat.sas7bdat" "&rootdir./Final_Stats/"; 
	x cp "&rootdir./iteration&iteration./gensq_call.sas" "&rootdir./Final_Stats/"; 
	x cp "&rootdir./iteration&iteration./drop_orig_woes.txt" "&rootdir./Final_Stats/"; 
	x cp "&rootdir./iteration&iteration./NULL_WEIGHT.TXT" "&rootdir./Final_Stats/"; 
	x cp "&rootdir./iteration&iteration./formula.txt" "&rootdir./Final_Stats/"; 
	x cp "&rootdir./iteration&iteration./flag_logic.txt" "&rootdir./Final_Stats/"; 
	x cp "&rootdir./iteration&iteration./2_run_model.sas" "&rootdir./Final_Stats/"; 
	x cp "&rootdir./iteration&iteration./1_impute_modeling_data.sas" "&rootdir./Final_Stats/";
	x cp "&rootdir./iteration&iteration./Summary_Statistics.txt" "&rootdir./Final_Stats/";
	x cp "&rootdir./iteration&iteration./results.txt" "&rootdir./Final_Stats/";
	x cp "&rootdir./iteration&iteration./model_coarses.txt" "&rootdir./Final_Stats/";
	x cp "&rootdir./iteration&iteration./formats.sas7bdat" "&rootdir./Final_Stats/";
	x cp "&rootdir./iteration&iteration./model.sas7bdat" "&rootdir./Final_Stats/";
	x cp "&rootdir./iteration&iteration./iteration.txt" "&rootdir./Final_Stats/";
	x cp "&rootdir./iteration&iteration./drop_list.txt" "&rootdir./Final_Stats/";

	libname pop "&rootdir./Final_Stats/Population_Stability";
	libname final "&rootdir./Final_Stats";
	
	
	%gencoarses1(dset=lrdat.scrtotal,estset=wpe,perfvar=&perfvar.,wghtvar=&wghtvar.,
					eval=&eventval.,neval=&noneventval.,report=report);

	proc contents data=lrdat.scrbld out=contents_scrbld noprint;
	run;

	proc contents data=lrdat.scrtotal out=contents_scrtotal noprint;
	run;

	proc sql noprint;

		create table contents_bld1 as
		select a.name as vars_bld
		from contents_scrbld as a, pe as b
		where a.name=b.Variable;

		create table contents_total1 as
		select a.name as vars_total
		from contents_scrtotal as a, pe as b
		where a.name=b.Variable;

		select vars_bld 
		into :varlist_bld separated by " "
		from contents_bld1;
		
		select vars_total
		into :varlist_tot separated by " "
		from contents_total1;
		
		create table info_segment(iteration num, pop_label char(20),rundate char(32),runtime char(20));
		
		insert into info_segment
		values(&iteration.,"&population_label.","&currdate.","&currtime.");
		
		create table pop_stab_ref(tot_iv char(10), implication char(120));
		
		insert into pop_stab_ref
		values("< 0.3","No significance")
		values(".03 - .10","Weak shift")
		values(".10 - .25","Moderate shift - likely the result of only 1 or 2 characteristics")
		values(".25 - .50","Strong shift - likely from a large number of characteristics, indicating a strong population difference")
		values("> 0.50","Extremely strong shift ");
		
		create table index1(contents char(30));
		
		insert into index1
		values("Sum_count")
		values("model_perf")
		values("gini")
		values("sc_vars")
		values("score_dist")
		values("bus_benifits")
		values("coarse classing")
		values("appendix");
	quit;
	
	proc format;
	value $index 	  'Sum_count'='<a href="#summary_counts">Summary Counts</a>'
					  'model_perf'='<a href="#model_perf">Model Performance Statistics</a>'
					  'gini'='<a href="#gini">Gini Distribution</a>'
					  'sc_vars'='<a href="#sc_vars">Scorecard Variables</a>'
					  'score_dist'='<a href="#score_eff">Score Effectiveness</a>'
					  'bus_benifits'='<a href="#bus_benifits">Business Benifits</a>'
					  'coarse classing'='<a href="#coarses">Coarse Classing</a>'
					  'appendix'='<a href="#appendix">Appendix</a>';
	run;				  
	
	data final.info_segment;
		set info_segment;
	run;
	
	%let x=%sysfunc(countw(&varlist_tot.));
	%let z=%sysfunc(countw(&varlist_bld.));
							
    /* population stability */
    %IF %upcase(&score_out.)= SCALEDSCORE %THEN %DO;
    %popstab(req=base,dataset=scaletotal, _var=scaledscore_totalpred,w_var=&wghtvar.,formatfilename=pop_stab_format.sas,fmtname=pop_format,path_base=&rootdir./Final_Stats/Population_Stability,format_opt=yes,base_dataset=baseline_data);
        %END; 
    %ELSE %IF %upcase(&score_out.)= RAWSCORE %THEN %DO; 
        %popstab(req=base,dataset=scaletotal, _var=rawscore_totalpred,w_var=&wghtvar.,formatfilename=pop_stab_format.sas,fmtname=pop_format,path_base=&rootdir./Final_Stats/Population_Stability,format_opt=yes,base_dataset=baseline_data);
    %END;
    
    %ELSE %IF %upcase(&score_out.) ne RAWSCORE or %upcase(&score_out.) ne SCALEDSCORE %THEN %DO; 
        %popstab(req=base,dataset=scaletotal, _var=totalpred,w_var=&wghtvar.,formatfilename=pop_stab_format.sas,fmtname=pop_format,path_base=&rootdir./Final_Stats/Population_Stability,format_opt=yes,base_dataset=baseline_data);
    %END;
    
	data baseline_data_total;
		set pop.baseline_data;
		label %IF %upcase(&score_out.)= SCALEDSCORE %THEN %DO; 
                    scaledscore_totalpred = "Score Range"
               %END; 
               %ELSE %IF %upcase(&score_out.)= RAWSCORE %THEN %DO; 
                    rawscore_totalpred = "Score Range"
               %END;
               %ELSE %IF %upcase(&score_out.) ne RAWSCORE or %upcase(&score_out.) ne SCALEDSCORE %THEN %DO; 
                    totalpred = "Score Range"
               %END;  
			   base_cnt= "Baseline*# of Accounts" base_percent= "Baseline*% of Accounts"
		;
	run;
	
	/* Score distribution on total population */
	%score_dist(
				dataset=scaletotal,
				%IF %upcase(&score_out.)= SCALEDSCORE %THEN %DO; 
	                _var = scaledscore_totalpred 
               %END; 
               %ELSE %IF %upcase(&score_out.)= RAWSCORE %THEN %DO; 
                    _var = rawscore_totalpred
               %END;
               %ELSE %IF %upcase(&score_out.) ne RAWSCORE or %upcase(&score_out.) ne SCALEDSCORE %THEN %DO; 
                    _var = totalpred 
               %END; ,
				breaks=20,
				weight_var=&wghtvar.,
				bad_flag=&perfvar.,
				formatfilename=&rootdir./Final_Stats/Score_distribution/cuts_total.sas,
				fmtname=fmttotal,
				gen_opt=yes,
				where=,
				event=&eventval.,
				non_event=&noneventval.,
				eventlabel=&event_label.,
				noneventlabel=&nonevent_label
			  );
	
	data score_dist_total;
		set score_dist1;
		label %IF %upcase(&score_out.)= SCALEDSCORE %THEN %DO; 
                    scaledscore_totalpred = "Score Range"
               %END; 
               %ELSE %IF %upcase(&score_out.)= RAWSCORE %THEN %DO; 
                    rawscore_totalpred = "Score Range"
               %END;
               %ELSE %IF %upcase(&score_out.) ne RAWSCORE or %upcase(&score_out.) ne SCALEDSCORE %THEN %DO; 
                    totalpred = "Score Range"
               %END; 
               no_of_acc= "Total*# of Accounts" event_acc= "# of &event_label.*Accounts"
				  non_event_acc= "# of &nonevent_label. *Accounts" percent_event= "% of &event_label. *Accounts" percent_non_event= "% of &nonevent_label. *Accounts" delta= "Difference in %"
				  woe= "Weight of *Evidence" cum_non_event= "Cumulative % of * &nonevent_label. Accounts" cum_event= "Cumulative % of * &event_label. Accounts" iv= "Information *Value" ks_spread ="KS Spread";
	run;
	
	
	%char_analysis(variable=&varlist_tot., data_set=lrdat.scrtotal,p_var_=&perfvar.,path_base=&rootdir./Final_Stats/Char_analysis/,fmtfilename_=fl_&segment.,vargen_opt_=yes,require=base, weight_variable=&wghtvar.);
	
	%DO i=1 %TO &x.;
		data final_&i._total;
			set final_&i.; 
			/* label  woe ="Weight*of Evidence" base_cnt="Baseline*# of Accounts" base_percent="Baseline*% of Accounts" tag="%upcase(%scan(&varlist_tot.,&i.,%str( )))*Range"; */
		run;
	%END;
	
	%let x=%sysfunc(countw(&varlist_tot.));
	
	%score_dist(
				dataset=scalebld,
				%IF %upcase(&score_out.)= SCALEDSCORE %THEN %DO; 
	                _var = scaledscore_predicted 
               %END; 
               %ELSE %IF %upcase(&score_out.)= RAWSCORE %THEN %DO; 
                    _var = rawscore_predicted
               %END;
               %ELSE %IF %upcase(&score_out.) ne RAWSCORE or %upcase(&score_out.) ne SCALEDSCORE %THEN %DO; 
                    _var = predicted 
               %END; ,
				breaks=20,
				weight_var=&wghtvar.,
				bad_flag=&perfvar.,
				formatfilename=&rootdir./Final_Stats/Score_distribution/cuts_bld.sas,
				fmtname=fmtbld,
				gen_opt=yes,
				where=,
				event=&eventval.,
				non_event=&noneventval.,
				eventlabel=&event_label.,
				noneventlabel=&nonevent_label
			  );
			  
	data score_dist_bld;
		set score_dist1;
		label %IF %upcase(&score_out.)= SCALEDSCORE %THEN %DO; 
	                scaledscore_predicted = "Score Range"
               %END; 
               %ELSE %IF %upcase(&score_out.)= RAWSCORE %THEN %DO; 
                    rawscore_predicted = 
               %END;
               %ELSE %IF %upcase(&score_out.) ne RAWSCORE or %upcase(&score_out.) ne SCALEDSCORE %THEN %DO; 
                    predicted = "Score Range"
               %END; no_of_acc= "Total*# of Accounts" event_acc= "# of &event_label.*Accounts"
				  non_event_acc= "# of &nonevent_label. *Accounts" percent_event= "% of &event_label. *Accounts" percent_non_event= "% of &nonevent_label. *Accounts" delta= "Difference in %"
				  woe= "Weight of *Evidence" cum_non_event= "Cumulative % of * &nonevent_label. Accounts" cum_event= "Cumulative % of * &event_label. Accounts" iv= "Information *Value" ks_spread ="KS Spread";
	run;
	
	%IF %sysfunc(exist(lrdat.scrVLD)) = 1 %THEN %DO; 

		%score_dist(
				dataset=scalevld,
				%IF %upcase(&score_out.)= SCALEDSCORE %THEN %DO; 
                    _var = scaledscore_p_&eventval.
               %END; 
               %ELSE %IF %upcase(&score_out.)= RAWSCORE %THEN %DO; 
                    _var = rawscore_p_&eventval.
               %END;
               %ELSE %IF %upcase(&score_out.) ne RAWSCORE or %upcase(&score_out.) ne SCALEDSCORE %THEN %DO; 
                    _var = p_&eventval. 
               %END; ,
				breaks=20,
				weight_var=&wghtvar.,
				bad_flag=&perfvar.,
				formatfilename=&rootdir./Final_Stats/Score_distribution/cuts_vld.sas,
				fmtname=fmtvld,
				gen_opt=yes,
				where=,
				event=&eventval.,
				non_event=&noneventval.,
				eventlabel=&event_label.,
				noneventlabel=&nonevent_label
			  );

		data score_dist_vld;
			set score_dist1;
			label %IF %upcase(&score_out.)= SCALEDSCORE %THEN %DO; 
                    scaledscore_p_&eventval. = "Score Range"
               %END; 
               %ELSE %IF %upcase(&score_out.)= RAWSCORE %THEN %DO; 
                    rawscore_p_&eventval. = "Score Range"
               %END;
               %ELSE %IF %upcase(&score_out.) ne RAWSCORE or %upcase(&score_out.) ne SCALEDSCORE %THEN %DO; 
                    p_&eventval. = "Score Range"
               %END; no_of_acc= "Total*# of Accounts" event_acc= "# of &event_label.*Accounts"
				  non_event_acc= "# of &nonevent_label. *Accounts" percent_event= "% of &event_label. *Accounts" percent_non_event= "% of &nonevent_label. *Accounts" delta= "Difference in %"
				  woe= "Weight of *Evidence" cum_non_event= "Cumulative % of * &nonevent_label. Accounts" cum_event= "Cumulative % of * &event_label. Accounts" iv= "Information *Value" ks_spread ="KS Spread";
		run;
		
	%END;
	
	data gini;
		merge score_dist_total(keep=cum_event cum_non_event
							   rename=(cum_event=cum_event_total cum_non_event=cum_non_event_total)
							   ) 
			  score_dist_bld(keep=cum_event cum_non_event 
							 rename=(cum_event=cum_event_bld cum_non_event=cum_non_event_bld)
							 ) 
			  %IF %sysfunc(exist(lrdat.scrVLD)) = 1 %THEN %DO;
				score_dist_vld (keep=cum_event cum_non_event 
								rename=(cum_event=cum_event_vld cum_non_event=cum_non_event_vld)
								)
			  %END;
		  ;
	run;
	
	proc sql;
	create table reference(refx num format=percent10.2,refy num format=percent10.2);
	
	insert into reference
	values(0.0,0.0)
	values(0.1,0.1)
	values(0.4, 0.4)
	values(0.7, 0.7)
	values (1,1);
	quit;
	
	data final.gini;
		merge gini reference;
		if refx=. then refx=0.0;
		if refy=. then refy=0.0;
	run;
	/*
	proc sql;
	insert into final.gini(cum_event_total, cum_non_event_total, cum_event_bld, cum_non_event_bld, cum_event_vld, cum_non_event_vld)
	values(0.0,0.0,0.0,0.0,0.0,0.0);
		*/
	proc sql noprint;
	create table sc_vars as
	select a.Variable, a.estimate, a.WaldChiSq, a.ProbChiSq, b.IVAL, b.KS, b.P1,b.P5, b.P10, b.P20, b.P30, b.P40, b.P50, b.P60, b.P70, b.P80, b.P90, b.P95, b.P99
	from pe as a
		 left join
		 preimpute_univs as b
	on a.Variable=b.varname;
	quit;
	
	data sc_vars;
		set sc_vars;
		label WaldChiSq="Wald*Chi-Square" estimate="Estimate" IVAL="Information*Value" KS="KS" P1="P1" P5="P5" P10="P10" P20="P20" P30="P30" P40="P40" P50="P50" P60="P60" P70="P70" P80="P80" P90="P90" P95="P95" P99="P99";
		format IVAL comma10.3 KS WaldChiSq comma10.1;
	run;
	
	data final.summary_stat;
		set summary_stat;
		label varname="Source" IVAL="Information Value";
	run;

	proc sql noprint;
		select max(abs(KS))
		into :max_KS_ss
		from summary_stat;
		
		select max(abs(KS))
		into :max_KS_sc
		from sc_vars;
		
		select max(abs(ks_spread))
		into :max_KS_sdt
		from score_dist_total;
		
		select max(abs(ks_spread))
		into :max_KS_sdb
		from score_dist_bld;
		
		%IF &vldset ^= 0 %THEN %DO; 
			select max(abs(ks_spread))
			into :max_KS_sdv
			from score_dist_vld;
		%END;
	quit;
	
	data matrix1;
		set matrix(keep=variable iteration&iteration. rename=(iteration&iteration.=iteration));
		where iteration ne .;
	run;
	
	data final.iter_matrix;
		merge matrix1 sc_vars(keep=variable estimate WaldChisq);
		by variable;
		where variable ne "Intercept";
	run;
	
	proc sort data=sc_vars;
	by descending WaldChiSq;
	run;

/* *******************************************************************************************/
	
	data build_event;
		set lrdat.build;
		where &perfvar.=&eventval.;
	run;
	
	proc means data=build_event noprint n sumwgt;
		var &perfvar.;
		weight &wghtvar.;
		output out=_buildstat_event n=n sumwgt=sumwgt;
    run;
    
    data _null_;
    	set _buildstat_event;
    	call symput('_bldsamp_event',n);
    	call symput('_wbldsamp_event',sumwgt);
    run;
	
	%IF &vldset ^= 0 %THEN %DO; 
		data valid_event;
			set lrdat.valid;
			where &perfvar.=&eventval.;
		run;

		proc means data=valid_event noprint n sumwgt;
			var &perfvar.;
			weight &wghtvar.;
			output out=_validstat_event n=n sumwgt=sumwgt;
		run;
    
		data _null_;
			set _validstat_event;
			call symput('_vldsamp_event',n);
			call symput('_wvldsamp_event',sumwgt);
		run;
		
		%let totalsamp= %sysfunc(sum(&_bldsamp.,&_vldsamp.));
		%let wtotalsamp= %sysfunc(sum(&_wbldsamp.,&_wvldsamp.));
	
		%let totalsamp_event= %sysfunc(sum(&_bldsamp_event.,&_vldsamp_event.));
		%let wtotalsamp_event= %sysfunc(sum(&_wbldsamp_event.,&_wvldsamp_event.));
		
		%let _vldsamp_nonevent=%sysfunc(sum(&_vldsamp.,-&_vldsamp_event.)); 
		%let _wvldsamp_nonevent=%sysfunc(sum(&_wvldsamp.,-&_wvldsamp_event.));
	%END;
	
	%ELSE %DO;
		%let totalsamp = &_bldsamp.;
		%let wtotalsamp = &_wbldsamp.;
		
		%let totalsamp_event= &_bldsamp_event.;
		%let wtotalsamp_event= &_wbldsamp_event.;
	%END;
	
	%let totalsamp_nonevent=%sysfunc(sum(&totalsamp.,-&totalsamp_event.));
	%let wtotalsamp_nonevent=%sysfunc(sum(&wtotalsamp.,-&wtotalsamp_event.));
	%let _bldsamp_nonevent=%sysfunc(sum(&_bldsamp.,-&_bldsamp_event.));
	%let _wbldsamp_nonevent=%sysfunc(sum(&_wbldsamp.,-&_wbldsamp_event.));
	
	proc sql;
		create table contents(report char(20));

		insert into contents
		values("psrb")
		values("psdr")
		values("car")
		values("model_perf");
		
		create table contents_pop(report char(20));
		
		insert into contents_pop
		values("total")
		values("bld")
		%IF &vldset ^= 0 %THEN %DO;
			values("vld")
		%END;
		;
		
		create table iter_summary (Data11 char(11) label="Dataset", 
								   type1 char(15),
								   no_acc_tot num,
								   no_acc_event num,
								   no_acc_non_event num
								   );
		
		insert into iter_summary
			values("Development","Unweighted",&_bldsamp., &_bldsamp_event., &_bldsamp_nonevent.)
			%IF &vldset ^= 0 %THEN %DO;
				values("Validation","Unweighted",&_vldsamp., &_vldsamp_event., &_vldsamp_nonevent.)
			%END;
			values("Total","Unweighted",&totalsamp., &totalsamp_event., &totalsamp_nonevent.)
			values("Development","Weighted",&_wbldsamp., &_wbldsamp_event., &_wbldsamp_nonevent.)
			%IF &vldset ^= 0 %THEN %DO;
				values("Validation","Weighted",&_wvldsamp., &_wvldsamp_event., &_wvldsamp_nonevent.)
			%END;
			values("Total","Weighted",&wtotalsamp., &wtotalsamp_event., &wtotalsamp_nonevent.);
	quit;
	
	data final.iter_summary;
		set iter_summary;
		event_rate= no_acc_event/no_acc_tot;
		label event_rate="Event Rate";
	run;
	
	

	proc format;
	value $con "psrb"='<a href="pop_stab.html">Population Stability - Baselines</a>'
			   "psdr"='<a href="score_dist.html">Score Distribution Reports</a>'
			   "car"='<a href="char_analysis.html">Characteristic Analysis Reports</a>'
			   "model_perf"='<a href="model_perf.html">Model Performance Statistics</a>';
	run;
	
	proc format;
	value $conpop "total"='<a href="#IDX1">Total Population</a>'
			   "bld"='<a href="#IDX2">Building Data</a>'
			   "vld"='<a href="#IDX3">Validation Data</a>';
	run;

	data contents;
		set contents;
		format report $con.;
		label report= "Table of Contents";
	run;
	
	data contents_pop;
		set contents_pop;
		format report $conpop.;
		label report= "Table of Contents";
	run; 
	

/* *****************************************************************************************************************
BUSINESS REPORT GENERATION
********************************************************************************************************************/	
	filename reports "&rootdir./Final_Stats/business_doc.html" mod;
	
	data _null_;
		file reports;
		put "<h2>Business Document</h2>";
		put "<b>Project</b>: <i>&project_name.</i><br>";
		put "<b>Population</b>: <i>&population_label.</i><br>";
		put "<b>Run Date</b>: <i>&currdate. at &currtime.</i><br><br>";
	run;
	
	ods html file=reports style=journal;
		proc print data=index1 noobs label;
			label contents="Contents";
			format contents $index.;
		run;
	ods html close;
	
	data _null_;
		file reports;
		put "<p class='MyHeading1' style='text-align:justify'><a name='summary_counts'><b>SUMMARY COUNTS</b></a></p>";
		put "<p style='text-align:justify'>After sampling, exclusions and performance definitions have been defined, a certain percentage of the sample are randomly selected a independent hold out for validation.";
		put "Below show the counts and &nonevent_label. rates that were used to develop &population_label..<br><br>";
	run;
	
	ods html file=reports style=journal;
	proc report data=final.iter_summary nofs split='*';
		column data11 type1,(no_acc_tot no_acc_event no_acc_non_event Event_rate);
		define data11 / group 'Dataset' order=data;
		define type1 / across ' ';
		define no_acc_tot / analysis format=comma10.0 '# Accounts';
		define no_acc_event / analysis format=comma10.0 "# Unit*&event_label. Accounts";
		define no_acc_non_event / analysis format=comma10.0 "# Unit*&nonevent_label. Accounts";
		define Event_rate / analysis format=percent10.1 "&event_label. Rate";
	run;
	ods html close;
	
	data _null_;
		file reports;
		put "<p class='MyHeading1' style='text-align:justify'><a name='model_perf'><b>MODEL PERFORMANCE STATISTICS</b></a></p>";
		put "<p style='text-align:justify'>The K-S statistic is a measure of the maximum difference between the score distributions of &event_label. and &nonevent_label. applications.";
		put "It is a measure of the strength of the scorecard in the score range where the model operates the best. Information Value is a measure of model strength across all scores.";
		put "Information Value is computed by breaking the scored records into 10 intervals, and then considering the effectiveness of the model in each score interval.</p>";
		put "<p style='text-align:justify'>Performance statistics for &population_label. scorecard are shown below. Statistics for the development, validation, and total populations are given.</p>";
	run;

	ods html file=reports style=journal;
		proc print data=summary_stat noobs label;
			format varname $PRFLAB. KS comma10.1 IVAL comma10.3;
			label varname="Source" IVAL="Information Value";
		run;
	ods html close;
	footnote9;
	
	data _null_;
		file reports;
		put "<p class='MyHeading1' style='text-align:justify'><a name='gini'><b>GINI DISTRIBUTION</b></a></p>";
		put "<p style='text-align:justify'>Gini curve is a graphical representation of the rank-ordering performance of the scorecard.";
		put "This graph compares the relationship between the cumulative score distributions of good and bad performers among different scores.";
		put "A few comments are in order:</p>";
		put "<ul><li>The diagonal line represents the performance of a random score that does not separate between good and bad performers, i.e. the likelihood of any account being good";
		put "is equal to its chance of being bad. In this case, the percent of good performers that pass any";
		put "score cut-off is equal to the percent of bad performers that pass.<li>The line running along the x and y axis represents the performance of a score that separates the good";
		put "performers perfectly from the bad performers. This relationship depicts the case where";
		put "100% of the good performers score above all of the bad performers";
		put "<li>As a performance validation measure, the development and validation samples are also rank-ordered.</ul>";
	run;
	
	ods html file=reports style=journal;
	ods listing close;
	ods graphics on /imagefmt=gif imagename="ginicurve_&segment."; 

	proc sgplot data=final.gini;
		title1 'Gini Curve';
		xaxis label="Cumulative &nonevent_label.";
		yaxis label="Cumulative &event_label";
		series x=refx y=refy / legendlabel='Reference'; 
		series x=cum_non_event_total y=cum_event_total / legendlabel='Total';
		series x=cum_non_event_bld y=cum_event_bld / legendlabel='Building';
		series x=cum_non_event_vld y=cum_event_vld / legendlabel='Validation'; 
	run;
	title1;
	ods graphics off;
	ods listing;	
	ods html close;
	
	x cp "&rootdir./ginicurve_&segment..gif" "&rootdir./Final_Stats/ginicurve_&segment..gif";
	
	data _null_;
		file reports;
		put "<p class='MyHeading1' style='text-align:justify'><a name='sc_vars'><b>SCORECARD VARIABLES</b></a></p>";
		put "<p style='text-align:justify'>The table below lists the variables that entered the final scorecard in order of strength as indicated by chi-squares and p-values. P-values are computed by performing a";
		put "chi-squared test between the model including the variable and an alternative model without the variable.  All variables allowed in the model have a p-value lower";
		put "than the exit threshold (&pexit.), and therefore, are significant at the chosen level.</p>";
	run;

	ods html file=reports style=journal;;
		proc print data=sc_vars noobs label split='*';
		where KS is not missing;
		run;
	ods html close;
	
	footnote9;
	
	data _null_;
		file reports;
		put "<p class='MyHeading1' style='text-align:justify'><a name='score_eff'><b>SCORE EFFECTIVENESS</b></a></p>";
		put "<p style='text-align:justify'>The following tables represent the scorecard’s effectiveness by summarizing the proportion of good and bad applicants at each score deciles.";
		put "Specifically, as the score increases, the expected percentage of the &event_label. performers in the population captured at or above the score";
		put "(&event_label. Rate at or above Cut-Off), decreases.</p>";
	run;
	
	ods html file=reports style=journal;
		title H=12pt "Score distribution on Total population";
		footnote9 Justify=L H=11pt "Maximum KS = &max_ks_sdt." ;
		proc print data=score_dist_total noobs label split='*';
		sum no_of_acc non_event_acc event_acc percent_event percent_non_event iv;
		run;
		
		title H=12pt "Score distribution on Development Data" ;
		footnote9 Justify=L H=11pt "Maximum KS = &max_ks_sdb." ;
		proc print data=score_dist_bld noobs label split='*';
			sum no_of_acc non_event_acc event_acc percent_event percent_non_event iv;
		run;
		
		%IF %sysfunc(exist(lrdat.scrVLD)) = 1 %THEN %DO;
			title H=12pt "Score distribution on Validation Data";
			footnote9 Justify=L H=11pt "Maximum KS = &max_ks_sdv." ;
			proc print data=score_dist_vld noobs label split='*';
				sum no_of_acc non_event_acc event_acc percent_event percent_non_event iv;
			run;
		%END;
		footnote9;
		title;
	ods html close;
	
	data _null_;
		file reports;
		put "<p class='MyHeading1' style='text-align:justify'><a name='bus_benifits'><b>BUSINESS BENIFITS</b></a></p>";
		put "<p style='text-align:justify'>The following tables represent the TPV and loss values for all the score ranges:</p><br>";
	run;
	
	%IF %length(&tpvvar.) ^= 0 and %length(&lossvar.) ^= 0 %THEN %DO;
		ods html file=reports style=journal;
		
		    %scoredist_amt1(dset=scaletotal,
		                    perfvar=&perfvar.,
		                    wghtvar=&wghtvar.,
							%IF %upcase(&score_out.)= SCALEDSCORE %THEN %DO; 
								scrvar = scaledscore_totalpred 
							%END; 
							%ELSE %IF %upcase(&score_out.)= RAWSCORE %THEN %DO; 
								scrvar =rawscore_totalpred 
							%END;
							%ELSE %IF %upcase(&score_out.) ne RAWSCORE or %upcase(&score_out.) ne SCALEDSCORE %THEN %DO; 
							   scrvar = totalpred 
							%END; ,
						    tpvvar=&tpvvar.,
						    lossvar=&lossvar.,
						    fmtname=fmttotal,
						    distname=Total
						    );

			%scoredist_amt1(dset=scalebld,
			                perfvar=&perfvar.,
			                wghtvar=&wghtvar.,
							%IF %upcase(&score_out.)= SCALEDSCORE %THEN %DO; 
								scrvar = scaledscore_predicted 
							%END; 
							%ELSE %IF %upcase(&score_out.)= RAWSCORE %THEN %DO; 
								scrvar = rawscore_predicted
							%END;
							%ELSE %IF %upcase(&score_out.) ne RAWSCORE or %upcase(&score_out.) ne SCALEDSCORE %THEN %DO; 
								scrvar = predicted 
							%END; ,
					        tpvvar=&tpvvar.,
					        lossvar=&lossvar.,
					        fmtname=fmtbld,
					        distname=Development
					        );
			
			%IF &vldset ^= 0 %THEN %DO;
			   %scoredist_amt1(dset=scalevld,
			                   perfvar=&perfvar.,
			                   wghtvar=&wghtvar.,
							   %IF %upcase(&score_out.)= SCALEDSCORE %THEN %DO; 
									scrvar = scaledscore_p_&eventval.
								%END; 
								%ELSE %IF %upcase(&score_out.)= RAWSCORE %THEN %DO; 
									scrvar = rawscore_p_&eventval.
								%END;
								%ELSE %IF %upcase(&score_out.) ne RAWSCORE or %upcase(&score_out.) ne SCALEDSCORE %THEN %DO; 
									scrvar = p_&eventval. 
								%END; ,
							   tpvvar=&tpvvar.,
							   lossvar=&lossvar.,
							   fmtname=fmtvld,
							   distname=Validation
							   );
			%END;

		ods html close;	
	%END;
	
	data _null_;
		file reports;
		put "<p class='MyHeading1' style='text-align:justify'><a name='coarses'><b>COARSE CLASSINGS</b></a></p>";
		put "<p style='text-align:justify'>Below are the coarse classings for the variables that entered the model.</p>";
	run;
	
	ods html file=reports style=journal;
		%DO i=3 %TO &x.;
			proc print data=grouped_&i. label noobs split='*';
			VAR %scan(&varlist_tot.,&i.,%str( )) _nogood _rawgood _nobad _rawbad _pgood _pbad _weight _cumgd _cumbd _ivalue _ODDS;
			SUM _ivalue _nogood _nobad _pgood _pbad _rawgood _rawbad;
			title5 "Variable - %scan(&varlist_tot.,&i.,%str( )) ";
			/* title6 "KS Value : &_ks_&ii.   Gamma Value: &_gamma_&ii.  Information Value:  &_ival_&ii. Count_Reversals:&reversals_&ii.";*/
			run;
			title5;
			title6;
		%END;
	ods html close;

	data _null_; 
		file reports;
		put "<p class='MyHeading1' style='text-align:justify'><a name='appendix'><b>APPENDIX</b></a></p>";
		put "<p style='text-align:justify'>Below are the coarse classings for the variables that entered the model.Implicit in the relevance of any statistical model is the assumption that the data on";
		put "which the model was based continues to represent the conditions on which it will be applied. Below serve as the baselines for tracking reports generated in the future.</p>";
		put "<p class='MyHeading1' style='text-align:justify'><a name='_Toc32658345'><b>Population Stability Report</b></a></p>";
		put "<p class='MsoNormal'><b><span style='font-size:11.0pt'>Objective<o:p></o:p></span></b></p>";
		put "<p style='text-align:justify'>This report measures the changes in the percentage of applicants that score in each score range at two different points of time. It can be used to compare the score";
		put "distribution of current applicants against that of the development sample, or another baseline established by the lender. Changes in this report can be a result of external economic changes, programming errors,";
		put "changes in Credit Bureau purchase policies, etc.  Larger shifts in score distribution detected by this report should be closely inspected for its cause.</p>";
		put "<p class='MsoNormal'><b><span style='font-size:11.0pt'>Frequency<o:p></o:p></span></b></p>";
		put "<p style='text-align:justify'>This report should be created as soon as the new scorecard is implemented to detect any change in score distributions between the current application population and the development sample.";
		put "Subsequent reports should be generated on a quarterly basis (if there is adequate application volume) and accumulated for a 12-month period to reduce seasonality.";
		put "If the score distribution of recent applicants is consistently different from that of the baseline and the new score distribution is representative of the on-going";
		put "application population on which the score will be applied, a new baseline may be established.</p>";
		put "<p class='MsoNormal'><b><span style='font-size:11.0pt'>Report Interpretation<o:p></o:p></span></b></p>";
		put "<p style='text-align:justify'>If a large portion of the new population suddenly has higher or lower scores,";
		put "it is an indication of a population distribution shift.A substantial shift in population scores ";
		put "is usually quantified by a total information value of 0.25 or higher. The table below erves as an informal guide for the significance of the changes that occur in the population stability report.";
		put "Observed continual increases in the index value warrant close inspection. If the index value continues to increase overtime, it is an indication that the 'through-the-door'";
		put "population is getting more distant from the development sample.";
		put "This can be the result of internal changes (e.g. changes in cut-off scores) or external economic conditions.</p>";
	run;

	ods html file=reports style=journal;
	title J=L H=10pt "Population Stability Index Shifts and Implications";
		proc print data=pop_stab_ref noobs label;
			label implication="Implication" tot_iv="Total Information Value";
		run;
		title;
	ods html close;
		
	ods html file=reports style=journal;	
		title J=L H=10pt "Baseline for Future Population Stability Reports:" ;
		proc print data=baseline_data_total noobs label split='*';
			var %IF %upcase(&score_out.)= SCALEDSCORE %THEN %DO; 
                    scaledscore_totalpred
               %END; 
               %ELSE %IF %upcase(&score_out.)= RAWSCORE %THEN %DO; 
                    rawscore_totalpred
               %END;
               %ELSE %IF %upcase(&score_out.) ne RAWSCORE or %upcase(&score_out.) ne SCALEDSCORE %THEN %DO; 
                    totalpred
               %END;  base_cnt base_percent;
		    sum base_cnt base_percent;
		run;
	ods html close;
	
	data _null_;
		file reports;
		put "<p class='MyHeading1' style='text-align:justify'><a name='_Toc32658345'><b>Characteristic Analysis Report</b></a></p>";
		put "<p class='MsoNormal'><b><span style='font-size:11.0pt'>Objective<o:p></o:p></span></b></p>";
		put "<p style='text-align:justify'>This report detects shifts that occur in the applicant population at the characteristic level.";
		put "When large shifts in total score distribution occur, this report helps to locate the specific characteristics that have changed in attribute distribution and have a large impact on the total score.";
		put "<p class='MsoNormal'><b><span style='font-size:11.0pt'>Frequency<o:p></o:p></span></b></p>";
		put "<p style='text-align:justify'>This report should be produced with the same frequency as the Population Stability Report.";
		put "When a new baseline is established for the Population Stability Report, a new baseline should also be established for this report.</p>";
		put "<p class='MsoNormal'><b><span style='font-size:11.0pt'>Report Interpretation<o:p></o:p></span></b></p>";
		put "<p style='text-align:justify'>The overall effect of a characteristic is measured by its total index value, which in absolute value grows larger when changes in the variable occur.";
		put "The characteristics with the largest index values are mostly likely to have caused the shift in total score distribution.";
		put "Once the characteristics with the largest impact are identified, column “Difference” should be inspected to determine which attribute was the most affected.";
		put "Watch for continuous increases in the index value overtime, as trends are usually more indicative of population shifts than absolute values.</p>";
	run;
			
	ods html file=reports style=journal;
		%DO i=3 %TO &x.;
			title H=12pt "Variable - %scan(&varlist_tot.,&i.,%str( ))";
			proc print data=final_&i._total label noobs split='*';
				var tag woe base_cnt base_percent;
				sum base_cnt base_percent;
			run;
		%END;		
	ods html close;

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

