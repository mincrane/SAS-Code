/*************************************************************************************************************************************************************************************************************
* Macro for creating the baseline for population stability report
* Parameters involved:

					Data:
					REQ                   -- BASE/CURR. Option that choses whether user wants to create a baseline or comparison data.
					DATASET               -- complete path of the dataset for which the statistics are to be drawn.
					_VAR    			  -- the score variable.
					W_VAR                 -- weight variable.
					WHERE                 -- Where statement to subset the input data set specific to user.
	
					Format:
					BREAKS                 -- number of breaks to create percentiles.
					FORMAT_OPT 			   -- option to generate new percentile ranges. Defaults to YES (Required only to create baselines, ie, only when REQ=BASE)
					
					Output and display options:
					PATH_BASE         -- location of the base data

**************************************************************************************************************************************************************************************************************/

		%macro popstab(
							  req=,
							  dataset=, 
							  _var=, 
							  w_var=,
							  where=,
							  cutoff=0, 
							  cutoff_opt=,
							  path_base=, 
							  format_opt=yes,
							  base_format_name=
							);
							
			libname gen1 "&path_base.";
							
			data _dset;
				set &dataset;
				%IF %length(&where.) > 0 %THEN %DO;
					where &where.;
				%END;
			run;
							
			%IF %upcase(&req.)=BASE %THEN %DO;
				
				data dset;
					set _dset(keep=&_var.);																												
				run;

				%IF %upcase(&format_opt.)=YES %THEN %DO;
					%IF &cutoff_opt = 0 %THEN %DO;
						%formatgen0(dset=dset,var=&_var.,wghtvar=&w_var, breaks=10,fmtfile_name=&path_base.&base_format_name..csv, cut=&cutoff.);
					%END;
				
					%IF &cutoff_opt = 1 %THEN %DO;
						%formatgen1(dset=dset,var=&_var,wghtvar=&w_var, breaks=10,fmtfile_name=&path_base.&base_format_name..csv, cut=&cutoff.);
					%END;	
				%END;

				data cuts1;
					infile "&path_base.&base_format_name..csv" dlm=',';
					input brk lo hi;
				run;

				proc sql;
						create table abc as 
						select a.&_var, b.brk, 1 as cntr
						from cuts1 as b, dset as a
						where (a.&_var <= b.hi and b.brk=0) or
							  (a.&_var > b.lo AND a.&_var <= b.hi and b.brk ne 0);
				quit;
		
				proc means data=abc noprint;
						var cntr;
						class brk;
						output out=_means_base sumwgt=sumwgt;
				run;
							
				data _means_base;
					set _means_base;
					retain base_totcnt;
				if _TYPE_= 0 then base_totcnt= sumwgt; 
				if _TYPE_= 1 then base_percent= sumwgt/base_totcnt;
				run;

				proc sql noprint;
					create table baseline_data as
					select a.lo as lower_limit,a.hi as upper_limit,a.brk as percentile, b.sumwgt as base_cnt,b.base_percent
					from cuts1 as a, _means_base as b
					where a.brk=b.brk and _TYPE_=1;
				quit;
				
				data gen1.baseline_data;
					set baseline_data;
					format lower_limit upper_limit comma9.8 base_percent percent10.1 base_cnt comma10.0;
					label lower_limit= "Score Low End" upper_limit= "Score High End" 
						  base_cnt= "Baseline # of Accounts" base_percent= "Baseline % of Accounts";
				run;
		  
			%END;
		*/******************************END OF BASELINE DATA *************************************************************/;
		
		%IF %upcase(&req.)=CURR %THEN %DO;
		
			%local epsilon;
			%let epsilon= 1e-10;
			
			data dset;
				set _dset(keep =&_var);																													
			run;

			data cuts1;
				infile "&path_base.&base_format_name..csv" dlm=','; 
				input brk lo hi;
			run;

			proc sql;
				create table def as 
				select a.&_var, b.brk, 1 as cntr
				from cuts1 as b, dset as a
				where (a.&_var <= b.hi and b.brk=0) or
					  (a.&_var > b.lo AND a.&_var <= b.hi and b.brk ne 0);
			quit;

			proc means data=def noprint;
				var cntr;
				class brk;
				output out=_means_1 sumwgt=curr_cnt;
			run;

			data _means_1;
				set _means_1;
				retain curr_totcnt;
				if _TYPE_= 0 then curr_totcnt= curr_cnt; 
				if _TYPE_= 1 then curr_percent= curr_cnt/curr_totcnt;
			run;
			
			data _means_1;
				set _means_1;
				where _TYPE_=1;
			run;

			/*Comparison of datasets*/		
			proc sql;
				create table pop_stab_report as
				select a.lower_limit, a.upper_limit, a.base_cnt, a.base_percent, b.curr_cnt, b.curr_percent
				from gen1.baseline_data as a
				left join
				_means_1 as b
				on a.percentile=b.brk;
			quit;

			data pop_stab_report;
				set pop_stab_report;
				if curr_cnt=. then do;
					curr_cnt=0;
					curr_percent=0;
				end;
				delta= curr_percent - base_percent;
				woe= log(sum(curr_percent,&epsilon.)/sum(base_percent,&epsilon.));
				iv= delta*woe;
				if iv>0.25 then sig_iv="*";
					else if iv>0.5 then sig_iv = "**";
					else sig_iv = " ";
				format curr_percent base_percent percent10.1;
			run;
			
			data pop_stab_report;
				set pop_stab_report;
				format lower_limit upper_limit comma9.8
					   curr_percent base_percent percent10.1
					   curr_cnt base_cnt comma10.0;
				label curr_cnt="Current # of Accounts" curr_percent="Current % of Accounts" delta= "Difference"
					  iv = "Information Value (IV)" woe="Weight of Evidence" sig_iv= "IV Significance level"
					  lower_limit = "Score Low End" upper_limit = " Score High End" base_cnt="Baseline # of Accounts" base_percent="Baseline % of Accounts";
			run;
		%END;
			
		%mend popstab;
		
/**********************************************************************************************************************************************
																				FORMATGEN FOR Cutoff=1;
*******************************************************************************************************************************/
		
%macro formatgen1(dset=, var=, wghtvar=, breaks=, overwrite=NO, debug=NO, fmtfile_name=,cut=);

	%local epsilon;
	%let epsilon= 1e-10;
	
	proc sql;
		select min(&var.)
		into :min_
		from &dset;
	quit;
		
	data abc;
		set &dset.;
		where &var. > &cut.;
	run;
	
	proc sql noprint;
		select count(*) into :count
		from &dset.
		where &_var. <= &cutoff.;
	quit;
	
	*calculate size of partitions for univariate;
	%let partsize= %sysevalf( 100 / &breaks );
	
	proc univariate data=abc 
										%if %upcase(&debug.)=NO %then %do; 
							noprint 
										%end;
	;
		var &var.;
		%IF %length(&wghtvar.) > 0 %THEN %DO;
		  weight &wghtvar.;
		%END;
		output out=_univ pctlpre= P pctlpts= 0 to 100 by &partsize.;
	run;
	
	data cuts;
		set _univ;
		array p[*] P0 -- P100;
		do i=1 to dim(p)-1;
			brk= i;
			lo= p[i];
			
			hi= p[i+1];
			output;
		end;
		keep brk lo hi;
	run; 
	
	proc sql noprint;
		INSERT INTO cuts
			set brk=0,
				  lo=&min_.,
			      hi=&cutoff.;	      
	quit;
		
	*drop degenerate groups;
	proc sort data=cuts;
		by lo hi;
	run;
		
	data cuts;
		set cuts;
		by lo;
		if last.lo then output;
	run;
	

	data _null_;
		set cuts;
		FILE "&fmtfile_name." DLM=',';
		PUT brk lo hi;
	run;
	
	%if %upcase(&debug.) ^= NO %then %do;
	  proc print data=cuts;
	  run;
	%end;
	
  *clean up;
	proc datasets library=work nolist;
		delete _univ;
	run;
	
%mend formatgen1;

/*******************************************************************************************************************************
																				FORMATGEN FOR Cutoff=0;
*******************************************************************************************************************************/

%macro formatgen0(dset=, var=, wghtvar=, breaks=, overwrite=NO, debug=NO, fmtfile_name=,cut=);
	
	data abc;
		set &dset.;
	run;
	
	*calculate size of partitions for univariate;
	%let partsize= %sysevalf( 100 / &breaks );
	
	proc univariate data=abc 
										%if %upcase(&debug.)=NO %then %do; 
							noprint 
										%end;
	;
		var &var.; 
		%IF %length(&wghtvar.) > 0 %THEN %DO;
		  weight &wghtvar.;
		%END;
		output out=_univ pctlpre= P pctlpts= 0 to 100 by &partsize.;
	run;
	
	data cuts;
		set _univ;
		array p[*] P0 -- P100;
		do i=1 to dim(p)-1;
			brk= i;
			lo= p[i];
			hi= p[i+1];
			output;
		end;
		keep brk lo hi;
	run; 
		
	*drop degenerate groups;
	proc sort data=cuts;
		by lo hi;
	run;
		
	data cuts;
		set cuts;
		by lo;
		if last.lo then output;
	run;

	data _null_;
		set cuts;
		FILE "&fmtfile_name." DLM=',';
		PUT brk lo hi;
	run;
	
	%if %upcase(&debug.) ^= NO %then %do;
	  proc print data=cuts;
	  run;
	%end;
	
  *clean up;
	proc datasets library=work nolist; 
		delete _univ;
	run;
	
%mend formatgen0;
