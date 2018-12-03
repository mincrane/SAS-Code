/* ************************************************************************************************************************************************************************************************************
Macro for creating the baseline for population stability report
Parameters involved:

					Data:
					REQ                   -- BASE/CURR. Option that choses whether user wants to create a baseline or comparison data.
					DATASET               -- name of the dataset (including libname) for which the statistics are to be drawn.
					_VAR    			  -- the score variable.
					W_VAR                 -- weight variable.
					WHERE                 -- Where statement to subset the input data set specific to user.
					FORMATFILENAME		   -- Name of the file generated containing the formats. Defaults to 
					_BREAKS                -- number of breaks to create percentiles.
					FMTNAME 			   -- name of the format generated (or to be generated). Defaults to pop_format
					PATH_BASE        	   -- location of the base data, and format files
					FORMAT_OPT 			   -- Option to generate a new format, else use a previously generated one
					BASE_DATASET		   -- Name of the baseline dataset generated (or to be generated).
	
	*Creates a temporary dataset - work.pop_stab_report. USer has to print this dataset to view results
************************************************************************************************************************************************************************************************************* */

		%macro popstab(
							  req=,
							  dataset=, 
							  _var=, 
							  w_var=,
							  where=,
							  formatfilename=pop_stab_format.sas,
							  _breaks=10,
							  fmtname=pop_format,
							  path_base=, 
							  format_opt=yes,
							  base_dataset=baseline_data
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
					set _dset(keep=&_var. %IF %length(&w_var.) > 0 %THEN %DO;
			                                &w_var.
			                                %END;
			                 );
					cntr=1;
				run;

				%IF %upcase(&format_opt.)=YES %THEN %DO;
					%formatgen0(dset=dset,var=&_var.,wghtvar=&w_var, breaks=&_breaks.,formatname=&fmtname.,format_file=&formatfilename.);
				%END;
				
				%include "&path_base./&formatfilename.";
				
				proc means data=dset noprint;
                    class &_var.;
                    var cntr;
                    %IF %length(&w_var.) > 0 %THEN %DO;
                        weight &w_var.;
                    %END;
                    format &_var. &fmtname..;
                    output out=_means_base sumwgt=base_cnt;
                run;
			
				data _means_base;
					set _means_base;
					retain base_totcnt;
				    if _TYPE_= 0 then base_totcnt= base_cnt; 
				    if _TYPE_= 1 then base_percent= base_cnt/base_totcnt;
				run;

				data gen1.&base_dataset.;
					set _means_base;
					where _TYPE_=1;
					format base_percent percent10.1 base_cnt comma10.0;
					label &_var.="Score Range" base_cnt= "Baseline # of Accounts" base_percent= "Baseline % of Accounts";
					drop _TYPE_ _FREQ_ base_totcnt;
				run;
		  
			%END;
			
		/* *****************************END OF BASELINE DATA *************************************************************/
		
		%IF %upcase(&req.)=CURR %THEN %DO;
		
			%local epsilon;
			%let epsilon= 1e-10;
			
			data dset;
				set _dset(keep=&_var. %IF %length(&w_var.) > 0 %THEN %DO;
			                                &w_var.
			                                %END;
			            );
				cntr=1;																													
			run;
			
			%include "&path_base./&formatfilename.";
				
            proc means data=dset noprint;
                class &_var.;
                var cntr;
                %IF %length(&w_var.) > 0 %THEN %DO;
                    weight &w_var.;
                %END;
                format &_var. &fmtname..;
                output out=_means_curr sumwgt=curr_cnt;
            run;
            
			data _means_curr;
				set _means_curr;
				retain curr_totcnt;
				if _TYPE_= 0 then curr_totcnt= curr_cnt; 
				if _TYPE_= 1 then curr_percent= curr_cnt/curr_totcnt;
			run;
			
			data curr_data;
                set _means_curr;
                where _TYPE_=1;
                format curr_cnt percent10.1 curr_percent comma10.0;
                label &_var.="Score Range" curr_cnt= "Baseline # of Accounts" curr_percent= "Baseline % of Accounts";
                drop _TYPE_ _FREQ_ curr_totcnt;
            run;

			/*Comparison of datasets*/		
			            
            data pop_stab_report;
                merge gen1.&base_dataset. (keep=&_var. base_cnt base_percent) 
                      curr_data (keep= curr_cnt curr_percent) ;
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
				format curr_percent base_percent percent10.1
				       curr_cnt base_cnt comma10.0;
				label curr_cnt="Current # of Accounts" curr_percent="Current % of Accounts" delta= "Difference"
					  iv = "Information Value (IV)" woe="Weight of Evidence" sig_iv= "IV Significance level"
					  base_cnt="Baseline # of Accounts" base_percent="Baseline % of Accounts";
            run;
		%END;
			
%mend popstab;

/* Format generator */

%macro formatgen0(dset=, var=, wghtvar=, breaks=, overwrite=NO, debug=NO,cut=,formatname=,format_file=);
	
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
	
	/* Added on 12/11/2011 */
            data _null_;
                set cuts nobs=nobs; ;
                FILE "&path_base./&format_file.";
                
                if _n_=1 THEN DO;
                        put "proc format;";
                        put "value &formatname."; 
                        put "       LOW -< " hi "=" " 'LOW -< " hi"'";
                end;
                else if _n_ ne 1 and _n_ ne nobs THEN DO;
                        put "       " lo " -< " hi "=" " '" lo " -< " hi"'";
                end;
                
                else if _n_=nobs THEN DO;
                        put "       " lo " - HIGH =" " '" lo " - HIGH' ;";
                        put "run;";
                end;
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