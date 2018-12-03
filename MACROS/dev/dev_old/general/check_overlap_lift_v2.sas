/*****************************************************************************************************************************
* Description: To check overlap and lift of a set of rules/models running on the same population
* Parameters:
	1. dsin: input dataset name, including library if not WORK;
	2. rule_list: macro variable containing target rule id, number only; Please rename flags in format: rule_xx;
	3. wgt: weight variable, optional;
	4. tpv: tpv variable, optional;
	5. loss=: loss variable, optional;
	6. perf: performance variable (0/1), optional;
* Usage: %check_overlap_lift(dsin=seg1_strategy, rule_list=&rule_list, wgt=sam_wgt, tpv=gtpv_cap, loss=pp_loss, perf=bad);
* History:
*	11/11/2011 Sean: Per Steve and Lin, added a rule-level summary at top, including bad rate, incremental benefit etc;
*	11/04-07/2011 Sean: Initial write for ALH offebay strategy evaluation, inspired by Mike Min's work on MRM reporting; 
******************************************************************************************************************************/


%macro check_overlap_lift(dsin=, rule_list=, wgt=, tpv=, loss=, perf=);
    Title3 'Overlap And Lift Analysis';

    %IF &rule_list = %str() %THEN %Do;
	%Let exit_code = 1;
    %End;
    %Else %Do;
	%Let counter=0;
	%let curr=%scan(&rule_list,1);
	%Do %While(&curr ^= %str());
	    %let counter=%eval(&counter+1);
	    %let curr=%scan(&rule_list,&counter+1);
	%End;

	%if &counter < 2 %then %Let exit_code = 1;
	%else %Let exit_code = 0;
    %End;


    %IF &exit_code = 1 %THEN %DO;
	%Put %UPCASE(warning): NO rule or only ONE rule is specified , so exit;
	%goto exit_macro;
    %END;	


     * Circulate through all rules in list;
    %Do i=1 %To &counter;

       %Let row=%SCAN(&rule_list, &i);

	* Overlap: unit;
	proc sql;
	    create table &dsin._unit as
	    select 
		rule_&row. 
		%do j=1 %to &counter;
		    %let col=%scan(&rule_list,&j);	
		    %IF &wgt ^= %str() %then %bquote(,sum(round(rule_&col.*&wgt.,1)) as rule&col._fire);
		    %else %bquote(,sum(round(rule_&col.,1)) as rule&col._fire);
		%end;
	    
		,sum(round((1-min(
			%do j=1 %to &counter;
			    %let col=%scan(&rule_list,&j);	
			    %if &i ^= &j %then %str(+rule_&col.);
			    %else %str();
			%end;
		    ,1))
		    %IF &wgt ^= %str() %THEN %str(*&wgt.);
		    %ELSE %str();
		    ,1)) as net_lift
	    
	    from &dsin.
	    where rule_&row. = 1
	    group by rule_&row.
	    order by rule_&row.
	    ;
	quit;

	* for summary;
	data _summ (keep = item_cnt incr_item_cnt);
	    set &dsin._unit;
	    rename rule&row._fire=item_cnt net_lift=incr_item_cnt;
	run;
     
	* Overlap: unit with perf = 1;
	%IF &perf ^= %str() %then %do;
	    proc sql;
		create table &dsin._bad as
		select 
		    rule_&row. 
		    %do j=1 %to &counter;
			%let col=%scan(&rule_list,&j);	
			%IF &wgt ^= %str() %then %bquote(,sum(round(rule_&col.*&wgt.*&perf.,1)) as rule&col._fire);
			%else %bquote(,sum(round(rule_&col.*&perf.,1)) as rule&col._fire);
		    %end;
		
		    ,sum(round((1-min(
			    %do j=1 %to &counter;
				%let col=%scan(&rule_list,&j);	
				%if &i ^= &j %then %str(+rule_&col.);
				%else %str();
			    %end;
			,1))
			%IF &wgt ^= %str() %THEN %str(*&wgt.);
			%ELSE %str();
			*&perf.,1)) as net_lift
		
		from &dsin.
		where rule_&row. = 1
		group by rule_&row.
		order by rule_&row.
		;
	    quit;

	    * for summary;
	    data _summ_bad (keep = bad_item_cnt incr_bad_item_cnt);
		set &dsin._bad;
		rename rule&row._fire=bad_item_cnt net_lift=incr_bad_item_cnt;
	    run;
	    data _summ;
		merge _summ _summ_bad;
	    run;
	%end;


	* Overlap: tpv;
	%IF &tpv ^= %str() %then %do;
	    proc sql;
		create table &dsin._tpv as
		select 
		    rule_&row. 
		    %do j=1 %to &counter;
			    %let col=%scan(&rule_list,&j);	
			    %IF &wgt ^= %str() %then %bquote(,sum(round(rule_&col.*&wgt.*&tpv.,1)) as rule&col._fire);
			    %else %bquote(,sum(round(rule_&col.*&tpv,1)) as rule&col._fire);
		    %end;
		
		    ,sum(round((1-min(
			    %do j=1 %to &counter;
				%let col=%scan(&rule_list,&j);	
				%if &i ^= &j %then %str(+rule_&col.);
				%else %str();
			    %end;
			,1))
			%IF &wgt ^= %str() %THEN %str(*&wgt.);
			%ELSE %str();
			*&tpv.,1)) as net_lift
		
		from &dsin.
		where rule_&row. = 1
		group by rule_&row.
		order by rule_&row.
		;
	    quit;

	    * for summary;
	    data _summ_tpv (keep = tpv incr_tpv);
		set &dsin._tpv;
		rename rule&row._fire=tpv net_lift=incr_tpv;
		format rule&row._fire net_lift comma10.0;
	    run;
	    data _summ;
		merge _summ _summ_tpv;
	    run;
	%end;


	* Overlap: Loss;
	%IF &loss ^= %str() %then %do;
	    proc sql;
		create table &dsin._loss as
		select 
		    rule_&row. 
		    %do j=1 %to &counter;
			    %let col=%scan(&rule_list,&j);	
			    %IF &wgt ^= %str() %then %bquote(,sum(round(rule_&col.*&wgt.*&loss.,1)) as rule&col._fire);
			    %else %bquote(,sum(round(rule_&col.*&loss,1)) as rule&col._fire);
		    %end;
		
		    ,sum(round((1-min(
			    %do j=1 %to &counter;
				%let col=%scan(&rule_list,&j);	
				%if &i ^= &j %then %str(+rule_&col.);
				%else %str();
			    %end;
			,1))
			%IF &wgt ^= %str() %THEN %str(*&wgt.);
			%ELSE %str();
			*&loss.,1)) as net_lift
		
		from &dsin.
		where rule_&row. = 1
		group by rule_&row.
		order by rule_&row.
		;
	    quit;

	    * for summary;
	    data _summ_loss (keep = loss incr_loss);
		set &dsin._loss;
		rename rule&row._fire=loss net_lift=incr_loss;
		* format loss incr_loss comma10.0;
		format rule&row._fire net_lift comma10.0;
	    run;
	    data _summ;
		merge _summ _summ_loss;
	    run;
	%end;
	    
	   
	* process results; 
       %if &i = 1 %then %do;
	    data &dsin._ovlp_unit; 
		set &dsin._unit (drop=rule_&row.);
		curr_rule=&row.;
	    run;

	    %IF &perf ^= %str() %then %do;
		data &dsin._ovlp_bad; 
		    set &dsin._bad (drop=rule_&row.);
		    curr_rule=&row.;
		run;
	    %end;
	    %IF &tpv ^= %str() %then %do;
		data &dsin._ovlp_tpv; 
		    set &dsin._tpv (drop=rule_&row.);
		    curr_rule=&row.;
		run;
	    %end;
	    %IF &loss ^= %str() %then %do;
		data &dsin._ovlp_loss; 
		    set &dsin._loss (drop=rule_&row.);
		    curr_rule=&row.;
		run;
	    %end;
	    data &dsin._ovlp_summ;
	    	set _summ;
		curr_rule=&row.;
	    run;
	%end;
	%else %do;
	    data &dsin._unit; 
		set &dsin._unit (drop=rule_&row.);
		curr_rule=&row.;
	    run;
	    proc append base=&dsin._ovlp_unit data=&dsin._unit; 
	    run;

	    %IF &perf ^= %str() %then %do;
		data &dsin._bad; 
		    set &dsin._bad (drop=rule_&row.);
		    curr_rule=&row.;
		run;
		proc append base=&dsin._ovlp_bad data=&dsin._bad; 
		run;
	    %end;
	    
	    %IF &tpv ^= %str() %then %do;
		data &dsin._tpv; 
		    set &dsin._tpv (drop=rule_&row.);
		    curr_rule=&row.;
		run;
		proc append base=&dsin._ovlp_tpv data=&dsin._tpv; 
		run;
	    %end;

	    %IF &loss ^= %str() %then %do;
		data &dsin._loss ; 
		    set &dsin._loss (drop=rule_&row.);
		    curr_rule=&row.;
		run;
		proc append base=&dsin._ovlp_loss data=&dsin._loss; 
		run;
	    %end;

	    data &dsin._summ;
	    	set _summ;
		curr_rule=&row.;
	    run;
	    proc append base=&dsin._ovlp_summ data=&dsin._summ; 
	    run;
	%end;

    %end;

	* process summary;
    data &dsin._ovlp_summ;
	set &dsin._ovlp_summ;
	%IF &perf ^= %str() %then %do;
	    if item_cnt ^= 0 then bad_rate_unit=round(bad_item_cnt/item_cnt,0.0001);
	    else bad_rate_unit=0;
	%end;
	%IF &tpv ^= %str() AND &loss ^= %str() %then %do;
	    if tpv ^= 0 then bad_rate_dollar =round(loss/tpv,0.0001);
	    else bad_rate_dollar =0;
	%end;
    run;


    * Generate reports;
    title4 "Summary of Rule Performance, Data: &dsin";
    proc print data= &dsin._ovlp_summ noobs split='*';
	var curr_rule item_cnt incr_item_cnt  
	    %IF &perf ^= %str() %then %str(bad_item_cnt incr_bad_item_cnt bad_rate_unit);
	    %IF &tpv ^= %str() %then %str(tpv incr_tpv);
	    %IF &loss ^= %str() %then %str(loss incr_loss);
	    %IF &tpv ^= %str() AND &loss ^= %str() %then %str(bad_rate_dollar);
	;
	label incr_item_cnt='incr_*item_cnt' 
	    %IF &perf ^= %str() %then %str(bad_item_cnt=bad_item*_cnt incr_bad_item_cnt=incr_bad_*item_cnt bad_rate_unit=bad_rate*_unit);
	    %IF &tpv ^= %str() AND &loss ^= %str() %then %str(bad_rate_dollar=bad_rate*_dollar);
	;
    run;

    title4 "Target Variable: COUNT, Data: &dsin";
    proc print data= &dsin._ovlp_unit noobs;
	var curr_rule 
	    %do j=1 %to &counter;
		%let col=%scan(&rule_list,&j);	
		%str(rule&col._fire)
	    %end;
	net_lift;
	sum net_lift;
    run;

    %IF &perf ^= %str() %then %do;
	title4 "Target Variable : BAD COUNT (PERF=1), Data: &dsin";
	proc print data= &dsin._ovlp_bad noobs;
	    var curr_rule 
		%do j=1 %to &counter;
		    %let col=%scan(&rule_list,&j);	
		    %str(rule&col._fire)
		%end;
	    net_lift;
	    sum net_lift;
	run;
    %END;
 
    %IF &tpv ^= %str() %then %do;
	title4 "Target Variable: TPV, Data: &dsin";
	proc print data= &dsin._ovlp_tpv noobs;
	    var curr_rule 
		%do j=1 %to &counter;
		    %let col=%scan(&rule_list,&j);	
		    %str(rule&col._fire)
		%end;
	    net_lift;
	    sum net_lift;
	run;
    %END;

    %IF &loss ^= %str() %then %do;
	title4 "Target Variable: LOSS, Data: &dsin";
	proc print data= &dsin._ovlp_loss noobs;
	    var curr_rule 
		%do j=1 %to &counter;
		    %let col=%scan(&rule_list,&j);	
		    %str(rule&col._fire)
		%end;
	    net_lift;
	    sum net_lift;
	run;
    %END;

 %exit_macro:

%mend check_overlap_lift;


/*********************************************************************************************************************************************
* The following is an example with real data;

option ps = 3000 ls=140;
libname dat '/sas/pprd/austin/projects/alh_offebay/data';

%let dsin=seg3_refit_score; 
 
data dat.&dsin._out; 
    set dat.&dsin; 
    %include "/sas/pprd/austin/projects/alh_offebay/strategy/DE/swapout.txt";
    rename swapout_1-swapout_15=rule_1-rule_15;
run;

%let rule_list =  1 3 6 7 9 10 11 13 15;
 %check_overlap_lift(dsin=dat.&dsin._out, rule_list=&rule_list, wgt=sam_wgt, tpv=gtpv_next_30d_cap, loss=pp_gross_mer_next_30d_cap, perf=bad);
*********************************************************************************************************************************************/


