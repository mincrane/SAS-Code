/* ***************************************************************************************************
 Created by : Jasmit Kohli  on 10/05/2011
 This macro must be run after developing a model for each segment present in the project. It does two things:
 		1. Creates a Folder structure for the project. Copies all relevant files into the created folder structure
 		2. Generates an executive summary for the developed model in html format
 
 Parameters: 
		proj_name	: Name of the project. (e.g. Behavior models). Will be used in the text embedded in the html
					  file and in naming the folder
		rootdir		: Path of the results folder from logreg
		num_segs 	: Number of segments in the model
		dir			: Location of projects folder

*******************************************************************************************************/
options symbolgen;
%MACRO exec_report(proj_name=, rootdir=, dir=/sas/swteam/austin, num_segs=, event_label=, nonevent_label=);

	libname lrdat "&rootdir./seg1/data/";
	libname final "&rootdir./seg1/Final_Stats";

	%let project = %scan(&proj_name.,1,%str( )) ;
	
	/* Creating necessary folders */ 
	
	%IF %sysfunc(fileexist(&dir./projects)) ^=1 %THEN %DO;
		%put;
		%put %upcase(&sysmacroname): projects folder;
		%put;
		%sysexec mkdir "&dir./projects" 2>&1 > /dev/null;
	%END;
	
	%IF %sysfunc(fileexist(&dir./projects/&project.)) ^=1 %THEN %DO;
		%put;
		%put %upcase(&sysmacroname): Project subfolder;
		%put;
		%sysexec mkdir "&dir./projects/&project." 2>&1 > /dev/null;
	%END;
	
	%IF %sysfunc(fileexist(&dir./projects/&project./documentation)) ^=1 %THEN %DO;
		%put;
		%put %upcase(&sysmacroname): Creating subfolder for documentation files;
		%put;
		%sysexec mkdir "&dir./projects/&project./documentation" 2>&1 > /dev/null;
	%END;
	
	%IF %sysfunc(fileexist(&dir./projects/&project./documentation/html_files)) ^=1 %THEN %DO;
		%put;
		%put %upcase(&sysmacroname): Creating subfolder for html output files;
		%put;
		%sysexec mkdir "&dir./projects/&project./documentation/html_files" 2>&1 > /dev/null;
	%END;
	
	%IF %sysfunc(fileexist(&dir./projects/&project./tracking)) ^=1 %THEN %DO;
		%put;
		%put %upcase(&sysmacroname): Creating subfolder for tracking;
		%put;
		%sysexec mkdir "&dir./projects/&project./tracking" 2>&1 > /dev/null;
	%END;
	
	%IF %sysfunc(fileexist(&dir./projects/&project./tracking/Baselines)) ^=1 %THEN %DO;
		%put;
		%put %upcase(&sysmacroname): Creating subfolder for model baselines;
		%put;
		%sysexec mkdir "&dir./projects/&project./tracking/Baselines" 2>&1 > /dev/null;
	%END;
	
	%IF %sysfunc(fileexist(&dir./projects/&project./tracking/Baselines/Development)) ^=1 %THEN %DO;
		%put;
		%put %upcase(&sysmacroname): Creating subfolder for model baselines at development;
		%put;
		%sysexec mkdir "&dir./projects/&project./tracking/Baselines/Development" 2>&1 > /dev/null;
	%END;
	
	%IF %sysfunc(fileexist(&dir./projects/&project./tracking/Baselines/Development/Population_Stability)) ^=1 %THEN %DO;
		%put;
		%put %upcase(&sysmacroname): Creating Population stability subfolder.;
		%put;
		%sysexec mkdir "&dir./projects/&project./tracking/Baselines/Development/Population_Stability" 2>&1 > /dev/null;
	%END;
	
	%IF %sysfunc(fileexist(&dir./projects/&project./tracking/Baselines/Development/Char_analysis)) ^=1 %THEN %DO;
		%put;
		%put %upcase(&sysmacroname): Creating characteristic analysis subfolder.;
		%put;
		%sysexec mkdir "&dir./projects/&project./tracking/Baselines/Development/Char_analysis" 2>&1 > /dev/null;
	%END;
	
	%IF %sysfunc(fileexist(&dir./projects/&project./tracking/Baselines/Development/Score_distribution)) ^=1 %THEN %DO;
		%put;
		%put %upcase(&sysmacroname): Creating score distribution subfolder.;
		%put;
		%sysexec mkdir "&dir./projects/&project./tracking/Baselines/Development/Score_distribution" 2>&1 > /dev/null;
	%END;
	
	%sysexec cp "&rootdir./seg1/Final_Stats/business_doc.html" "&dir./projects/&project./documentation/html_files/.";
	%sysexec mv "&dir./projects/&project./documentation/html_files/business_doc.html" "&dir./projects/&project./documentation/html_files/business_doc_1.html";
	%sysexec cp "&rootdir./seg1/Final_Stats/ginicurve_seg1.gif" "&dir./projects/&project./documentation/html_files/.";
	
	%sysexec cp "&rootdir./seg1/Final_Stats/Population_Stability/baseline_data.sas7bdat" "&dir./projects/&project./tracking/Baselines/Development/Population_Stability/.";
	%sysexec mv "&dir./projects/&project./tracking/Baselines/Development/Population_Stability/baseline_data.sas7bdat" "&dir./projects/&project./tracking/Baselines/Development/Population_Stability/baseline_data_seg1.sas7bdat";
	%sysexec cp "&rootdir./seg1/Final_Stats/Population_Stability/pop_stab_format.sas" "&dir./projects/&project./tracking/Baselines/Development/Population_Stability/.";
	%sysexec mv "&dir./projects/&project./tracking/Baselines/Development/Population_Stability/pop_stab_format.sas" "&dir./projects/&project./tracking/Baselines/Development/Population_Stability/pop_stab_format_seg1.sas";
	
	%sysexec cp "&rootdir./seg1/Final_Stats/Score_distribution/cuts_total.sas" "&dir./projects/&project./tracking/Baselines/Development/Score_distribution/.";
	%sysexec mv "&dir./projects/&project./tracking/Baselines/Development/Score_distribution/cuts_total.sas" "&dir./projects/&project./tracking/Baselines/Development/Score_distribution/cuts_total_seg1.sas";

	data _null_;
		length variable1 $32;
		set final.iter_matrix(keep=variable) end=eof;
		variable1=compress(variable);
		call symput('pes'!!left(put(_n_,2.)),variable1);
		if eof then
			call symput('pes_num',left(put(_n_,2.)));
	run;
	
	%DO qwe=1 %TO &pes_num;
		%let _pes&qwe.= %trim(&&pes&qwe.);
		%sysexec cp "&rootdir./seg1/Final_Stats/Char_analysis/&&_pes&qwe.._fl_seg1.sas" "&dir./projects/&project./tracking/Baselines/Development/Char_analysis/.";
	%END;
	
	%sysexec cp "&rootdir./seg1/Final_Stats/Char_analysis/fl_seg1.txt" "&dir./projects/&project./tracking/Baselines/Development/Char_analysis/.";
	
	data _null_; 
		call symput('currdate',put(date(),weekdate32.)); 
		call symput('currtime',put(time(),hhmm5.)); 
	run;

	data iter_summary;
		set final.iter_summary; 
		Segment="seg1";
	run;
	
	data iter_matrix;
		set final.iter_matrix;
		Segment="seg1";
	run;
	
	data summary_stat;
		set final.summary_stat;
		Segment="seg1";
	run;
	
	data info_segment;
		set final.info_segment;
		Segment="seg1";
		link="doc_1";
	run;

	%DO i=2 %TO &num_segs.;
		libname final "&rootdir./seg&i./Final_Stats";
		
		%sysexec cp "&rootdir./seg&i./Final_Stats/business_doc.html" "&dir./projects/&project./documentation/html_files/.";
		%sysexec mv "&dir./projects/&project./documentation/html_files/business_doc.html" "&dir./projects/&project./documentation/html_files/business_doc_&i..html";
		%sysexec cp "&rootdir./seg&i./Final_Stats/ginicurve_seg&i..gif" "&dir./projects/&project./documentation/html_files/.";
		
		%sysexec cp "&rootdir./seg&i./Final_Stats/Population_Stability/baseline_data.sas7bdat" "&dir./projects/&project./tracking/Baselines/Development/Population_Stability/.";
		%sysexec mv "&dir./projects/&project./tracking/Baselines/Development/Population_Stability/baseline_data.sas7bdat" "&dir./projects/&project./tracking/Baselines/Development/Population_Stability/baseline_data_seg&i..sas7bdat";
		%sysexec cp "&rootdir./seg&i./Final_Stats/Population_Stability/pop_stab_format.sas" "&dir./projects/&project./tracking/Baselines/Development/Population_Stability/.";
		%sysexec mv "&dir./projects/&project./tracking/Baselines/Development/Population_Stability/pop_stab_format.sas" "&dir./projects/&project./tracking/Baselines/Development/Population_Stability/pop_stab_format_seg&i..sas";
		
		%sysexec cp "&rootdir./seg&i./Final_Stats/Score_distribution/cuts_total.sas" "&dir./projects/&project./tracking/Baselines/Development/Score_distribution/.";
		%sysexec mv "&dir./projects/&project./tracking/Baselines/Development/Score_distribution/cuts_total.sas" "&dir./projects/&project./tracking/Baselines/Development/Score_distribution/cuts_total_seg&i..sas";
		
		data _null_;
			length variable1 $32;
			set final.iter_matrix(keep=variable) end=eof;
			variable1=compress(variable);
			call symput('pes'!!left(put(_n_,2.)),variable1);
			if eof then
				call symput('pes_num',left(put(_n_,2.)));
		run;
		
		%DO qwe=1 %TO &pes_num;
			%let _pes&qwe.= %trim(&&pes&qwe.);
			%sysexec cp "&rootdir./seg&i./Final_Stats/Char_analysis/&&_pes&qwe.._fl_seg&i..sas" "&dir./projects/&project./tracking/Baselines/Development/Char_analysis/.";
		%END;
		
		%sysexec cp "&rootdir./seg&i./Final_Stats/Char_analysis/fl_seg&i..txt" "&dir./projects/&project./tracking/Baselines/Development/Char_analysis/.";
		
		data temp;
			set final.iter_summary;
			Segment="seg&i.";
		run;
		
		PROC APPEND BASE=iter_summary DATA=temp FORCE;
		RUN; 
		
		data temp1;
			set final.iter_matrix;
			Segment="seg&i.";
		run;
		
		PROC APPEND BASE=iter_matrix DATA=temp1 FORCE;
		RUN; 
		
		data temp2;
			set final.summary_stat;
			Segment="seg&i.";
		run;
		
		PROC APPEND BASE=summary_stat DATA=temp2 FORCE;
		RUN; 
		
		data temp3;
			set final.info_segment;
			Segment="seg&i.";
			link="doc_&i.";
		run;
		
		PROC APPEND BASE=info_segment DATA=temp3 FORCE;
		RUN; 
		
	%END;
	
	proc format;
	value $segs %DO i=1 %TO &num_segs.;
					"seg&i." = "Segment &i."
				%END;
				;
	run;

	filename reports "&dir./projects/&project./documentation/html_files/executive_report.html" mod;
	
	proc sql noprint;
	select varname into :name separated by " "
	from final.summary_stat;
	quit;
	
	proc format;
    	value $PRFLAB "%scan(&name.,1,%str( ))"   = "Development"
					%IF %sysfunc(exist(lrdat.scrVLD)) = 1 %THEN %DO;
						"%scan(&name.,2,%str( ))" = "Validation"
						"%scan(&name.,3,%str( ))"   = "Total";
					%END;
    	            %ELSE %DO;
						"%scan(&name.,2,%str( ))"   = "Total";
					%END;
    run;
	
	proc format;
		value $links %DO i=1 %TO &num_segs.;
						"doc_&i." = "<a href='business_doc_&i..html'>Business Document</a>"
					%END;
					;
	run;
	
	data _null_;
		file reports;
		put "<h2>Executive Report</h2>";
		put "<b>Project:</b> Application models<br> <b>Run Date:</b> &currdate.<br> <b>Date Last Modified:</b> &currdate.<br><br>";
		put "<p class='MyHeading1' style='text-align:justify'><a name='_Toc32658345'><b>INTRODUCTION</b></a></p>";
		put "<p style='text-align:justify'>The purpose of this report is to document the procedures used and the results obtained for &proj_name..</p><br>";
		put "<p class='MyHeading1' style='text-align:justify'><a name='_Toc32658345'><b>OBJECTIVE</b></a></p>";
		put "<p style='text-align:justify'>(MANAGERS: PLEASE EDIT THIS SECTION)</p>The objective of this model is stated as follows:<ol>";
		put "<li>Assess and Reduce the Porfolio Losses</li><li>Set MRM Strategy</li><li>etc.</li></ol><br>";
		put "<p class='MyHeading1' style='text-align:justify'><a name='_Toc32658345'><b>SAMPLING</b></a></p>";
		put "<p style='text-align:justify'>(MANAGERS: PLEASE EDIT THIS SECTION)</p>";
		put "<p style='text-align:justify'>For purposes of developing the &proj_name., Risk Detection sampled data from [INSERT TIME FRAME]: Talk about which months you sampled";
		put "from to take into account seasonality. Accounts by Month table might be useful in this section.</p><br>";
		put "<p class='MyHeading1' style='text-align:justify'><a name='_Toc32658345'><b>EXCLUSION CRITERIA</b></a></p>";
		put "<p style='text-align:justify'>(MANAGERS: PLEASE EDIT THIS SECTION)</p>";
		put "<p style='text-align:justify'>The accounts were classified as &event_label. and &nonevent_label. according to the following definition:<br>";
		put "<b>Definition</b>: <ul><li><u>&event_label.</u>: ex. A maximum of 7 days OD during the 35-day performance window.</li>";
		put "<li><u>Indeterminate</u>: ex. 8 to 27 days OD during the 35-day performance window.</li><li><u>&nonevent_label.</u>: ex. 28 or more days OD during the 35-day performance window.</li></ul><br>";
		put "<p class='MyHeading1' style='text-align:justify'><a name='_Toc32658345'><b>SEGMENTATION ANALYSIS</b></a></p>";
		put "<p style='text-align:justify'>A segmentation analysis was performed to define appropriate segments for the population. This practice increases the predictive power of the models within each segment.";
		put "The analysis consists of two stages. In the first stage, the variables and cut-off values that determine breaks (or branches) of the tree were defined using a Knowledge Seeker. In the second stage, risk";
		put "software built completely automated models to determine whether the splits provided a significant lift in predictive power from a baseline model.  Even though the automated models";
		put "are not carefully checked for “patterns”, problems with collinearity, etc, they provide useful information that can be used to determine the best possible “Tree”.Several trees were built and the best one chosen.";
		put "Details below:<br>(MANAGERS: ADD KNOWLEDGE SEEKER TREE HERE)";
		put "<p class='MyHeading1' style='text-align:justify'><a name='_Toc32658345'><b>MODEL DEVELOPMENT COUNTS</b></a></p>";
		put "<p style='text-align:justify'>After sampling, exclusions and performance definitions have been defined, a certain percentage of the sample are randomly selected a independent hold out for validation.";
		put "Below show the counts and &nonevent_label. rates that were used to develop the models.</p>";
	run;
	
	ods html file=reports style=Journal;
		title2 H=12pt "Development Set";
		proc report data=iter_summary nofs split='*';
			column Segment type1,(no_acc_tot no_acc_event no_acc_non_event Event_rate);
			define Segment / group 'Segment' format=$segs.;
			define type1 / across ' ';
			define no_acc_tot / analysis '# Accounts' format=comma10.0;
			define no_acc_event / analysis "# &event_label.*Accounts" format=comma10.0;
			define no_acc_non_event / analysis "# &nonevent_label.*Accounts" format=comma10.0;
			define Event_rate / analysis "&event_label. Rate" format=percent10.2;
			where data11="Development";
		run;
		title;
		
		%IF %sysfunc(exist(lrdat.scrVLD)) = 1 %THEN %DO; 
			title2 H=12pt "Validation Set";
			proc report data=iter_summary nofs split='*';
				column Segment type1,(no_acc_tot no_acc_event no_acc_non_event Event_rate);
				define Segment / group 'Segment' format=$segs.;
				define type1 / across ' ';
				define no_acc_tot / analysis '# Accounts' format=comma10.0;
				define no_acc_event / analysis "# &event_label.*Accounts" format=comma10.0;
				define no_acc_non_event / analysis "# &nonevent_label.*Accounts" format=comma10.0;
				define Event_rate / analysis "&event_label. Rate" format=comma10.2;
				where data11="Validation";
			run;
		%END;
		
		title2 H=12pt "Total Set";
		proc report data=iter_summary nofs split='*';
			column Segment type1,(no_acc_tot no_acc_event no_acc_non_event Event_rate);
			define Segment / group 'Segment' format=$segs.;
			define type1 / across ' ';
			define no_acc_tot / analysis '# Accounts' format=comma10.0;
			define no_acc_event / analysis "# &event_label.*Accounts" format=comma10.0;
			define no_acc_non_event / analysis "# &nonevent_label.*Accounts" format=comma10.0;
			define Event_rate / analysis "&event_label. Rate" format=comma10.2;
			where data11="Total";
		run;
		
	ods html close;
	
	data _null_;
		file reports;
		put "<p class='MyHeading1' style='text-align:justify'><a name='_Toc32658345'><b>MODEL STATISTICS</b></a></p>";
		put "<p style='text-align:justify'>The development process began with all candidate variables prior to any discretion of predictive strength or implementation feasibility and were were constructed by implementing a";
		put "variant to the Stepwise Logistic Regression process described in Hosmer and Lemeshow (1989). A few steps were taken prior to the variables entering the modeling stage (including, but not limited to): ";
		put "<ul><li>Variables with severe missing values were excluded from modeling.</li><li>Variables with extremely low information value were excluded from modeling.</li><li>Variables with missing values had missing";
		put "flags generated and missing values replaced with zero or mean.</li><li>Variables were capped at 1% and 99% value to reduce outliers.</li>";
		put "<li>Variables were transformed to a form (square, square root, reverse, natural log, etc) that better suits the log odds pattern.</li>";
		put "<li>Flags were created for character variables. </li>";
		put "<li>Some variables were dropped from the modeling process for data integrity or implementation considerations.</li>";
		put "<li>The dependent variable, or performance category, was designed to be binary (dichotomous) in the modeling process with &event_label. and &nonevent_label. performers. </li></ul>";
		put "<p style='text-align:justify'>One measure of the model's";
		put "strength are the  the KS and IV Statistics. The K-S statistic is a measure of the maximum difference between the score distributions of &event_label. accounts and &nonevent_label. accounts.  It is a measure of the strength";
		put "of the scorecard in the score range where the model operates the best.  Information Value is a measure of model strength across all scores.  Information Value is computed by breaking the scored records into 10";
		put "intervals, and then considering the effectiveness of the model in each score interval.</p>";
		put "<p style='text-align:justify'>Performance statistics for  the &num_segs. segments are summarized below. Statistics for the development, validation, and total populations are given.</p>";
	run;
	
	ods html file=reports style=Journal;
		title2 H=12pt "Model Statistics";
		proc report data=summary_stat nofs split='*';
			column segment varname,(KS IVAL);			
			define segment / group 'Segment' format=$segs.; 
				define varname / across ' ' format=$PRFLAB. order=data;
				define KS / analysis 'KS' format=comma10.1;
				define IVAL /analysis 'Information*Value' format=comma10.4;
		run;
	ods html close;
	
	data _null_;
		file reports;
		put "<p class='MyHeading1' style='text-align:justify'><a name='_Toc32658345'><b>SCORECARD VARIABLES</b></a></p>";
		put "<p style='text-align:justify'>The final variables that entered the scorecard for each segment, along with their weights and their relative strength are detailed below:";
	run;
	
	ods html file=reports style=Journal;
		title2 H=12pt "Iteration Matrix";
		proc report data=iter_matrix nofs split='*';
			column variable segment,(iteration Estimate WaldChiSq);			
			define variable / group 'Variable'; 
				define segment / across ' ' format=$segs.;
				define iteration/analysis 'Relative*strength';
				define estimate/analysis 'Estimate';
				define WaldChiSq /analysis 'Wald Chi Sq';
		run;
		title2;
	ods html close;
	
	data _null_;
		file reports;
		put "<p class='MyHeading1' style='text-align:justify'><a name='_Toc32658345'><b>APPENDIX</b></a></p>";
	run;
	
	ods html file=reports style=Journal;
		proc print data=info_segment noobs label;
			label pop_label="Population" iteration="Final iteration" rundate="Run Date" link="Link to Business Document";
			format link $links.;
			var pop_label iteration rundate link;
		run;
	ods html close;
	
	
	data _null_;
		file reports;
		put "<p>Note: The underlying files and data to generate this model can be found in: &dir.</p><br>";
		put "<p class='MyHeading1' style='text-align:justify'><a name='_Toc32658345'><b>DOCUMENT LOG</b></a></p>";
		put "<ul><li>Version 1: Produced electronically via logreg on &currdate.</li></ul>";
	run;
	
	
%MEND exec_report;