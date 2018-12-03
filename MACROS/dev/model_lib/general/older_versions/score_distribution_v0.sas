/* ***********************************************************************************************
* Macro for creating the baseline for population stability calculations
* Parameters involved:

					DATASET -- complete path of the dataset for which the baseline statistics
										 are to be drawn.
					_VAR     -- the score variable.
					FMTFILENAME -- output file name and path containing the percentile ranges. Defaults to cuts.txt in the same folder as the macro.
					GEN_OPT -- option to generate new percentile ranges. Defaults to YES
					BREAKS  -- number of breaks to create percentiles.
					WGHTVAR - weight variable.
					OUTPUT_OPT -- option to ouput the results to an external file. (YES/NO). Default is NO
					OUTPUT_LOC -- Complete location of where the results need to be output including filename and extension.
					DISP   -- option to display results (YES/NO). Default is NO
					WHERE  -- condition to subset the data set
***********************************************************************************************/

		%macro score_dist(
										dataset=,
										_var=,
										breaks=,
										wghtvar=,
										bad_flag=,
										fmtfilename=,
										gen_opt=yes,
										where=,
										event=0,
										non_event=1,
										event_label=Good,
										nonevent_label=Bad
									  );
		
		%let partsize= %sysevalf( 100 / &breaks );
		%local epsilon;
		%let epsilon= 1e-10;
		%global breaks1;
		%let breaks1 = &breaks.;
			/* inputting the bad_definition (when available)*/
			
			data dset;
				set &dataset.;
				acc=&bad_flag.;
				%IF %length(&where.) > 0 %THEN %DO;
					where &where.;
				%END;
			run;
			
			
			/*defining a new column with a bad flag (random generation) */	
			/*
			data dset;
				set &dataset.;
				acc = RAND('UNIFORM');
				where &_var > 0;
				if acc >0.15 then acc=1;
				else acc=0;
			run;
			*/
			
	%IF %upcase(&gen_opt.)=YES %THEN %DO;

		proc univariate data=dset noprint;
			var &_var.;
			%IF %length(&wghtvar.) > 0 %THEN %DO;
			weight &wghtvar.;
			%END;
			output out=_univ pctlpre= P pctlpts= 0 to 100 by &partsize.;
		run;

		data cuts1;
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
		proc sort data=cuts1;
			by lo hi;
		run;
			
		data cuts1;
			set cuts1;
			by lo;
			if last.lo then output;
		run;
		
		data _null_;
			set cuts1;
			FILE "&fmtfilename." DLM=',';
			PUT brk lo hi;
		run;
	
	%END;
	
	data cuts;
		infile "&fmtfilename." dlm=',';
		input brk lo hi;
    run;
			
	proc sql;
		create table abc as 
		select a.&_var, b.lo, b.hi, b.brk,acc, 1 as cntr
		from cuts as b, dset as a
		where a.&_var > b.lo AND a.&_var <= b.hi;
	quit;
	
	proc means data=abc noprint;
		var cntr;
		class brk;
		output out=_means_tot sumwgt=no_of_acc;
	run;
	
	proc means data=abc noprint;
		var cntr;
		class brk;
		where acc=&event.;
		output out=_means_event sumwgt=event_acc;
	run;
	
	proc sql;
		create table _means as
		select a.brk, a.no_of_acc, b.event_acc
		from _means_tot as a, _means_event as b
		where a.brk=b.brk;
	quit;
			
			data score_dist;
				set _means;
				non_event_acc=no_of_acc - event_acc;
				
				retain tot_event;
				if brk=. then tot_event = event_acc;
				
				retain tot_non_event;
				if brk=. then tot_non_event = non_event_acc;
				
				percent_event= event_acc/tot_event;
				percent_non_event = non_event_acc/tot_non_event;
				drop tot_non_event tot_event;
				
				delta= percent_event - percent_non_event;
		    	woe= log(sum(percent_event,&epsilon.)/sum(percent_non_event,&epsilon.));
		    	iv= delta*woe;
			run;
			
			data score_dist;
				set score_dist;
				
				retain cum_event;
	    		retain cum_non_event;
	    		
				cum_event=sum(percent_event,cum_event);
	    		cum_non_event=sum(percent_non_event,cum_non_event);
	    		
	    		ks_spread = abs(cum_non_event - cum_event)*100;
	    		where brk ne .;
	    run;
	    
	    %global max_ks;
		
		proc sql noprint;
			create table score_dist1 as
			select b.lo,b.hi,a.no_of_acc, a.event_acc, a.non_event_acc, a.percent_event, a.percent_non_event, a.delta, a.woe, a.cum_non_event, a.cum_event, a.iv, a.ks_spread
			from score_dist as a,cuts as b
			where a.brk=b.brk;
			
			select max(abs(ks_spread))
			into :max_ks
			from score_dist1;
		quit;
		
		data score_dist1;
			set score_dist1;
			label lo= "Score Low End" hi= "Score High End" no_of_acc= "Total # of Accounts" event_acc= "# of &event_label. accounts"
				  non_event_acc= "# of &nonevent_label. accounts" percent_event= "% of &event_label. Accounts" percent_non_event= "% of &nonevent_label. Accounts" delta= "Difference in %"
				  woe= "Weight of Evidence" cum_non_event= "Cumulative % of &nonevent_label. Accounts" cum_event= "Cumulative % of &event_label. Accounts" iv= "Information Value" ks_spread ="KS Spread";
			format percent_event percent_non_event cum_event cum_non_event percent10.1
				   no_of_acc event_acc non_event_acc comma10.0
				   lo hi comma10.5
				   ks_spread comma10.1 iv comma10.4;
		run;
	
		%mend score_dist;
		
						 
       