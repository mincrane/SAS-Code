%macro LR_SCREENER(dataset, Y, Input);

* LR_SCREENER_v06.sas;
* 2015-09-23;
* 2015-05-07;
* 2014-12-27;
* 2015-02-01;

* v06: Changed name to LR_SCREENER to be in sync with SGF paper. 
	Changed documentation for parameter Y. Values are binary (not necessarily 0/1);
* v05: implement "-" in the INPUT parameter;
* v05: moved proc print of "Values before adjustment" to before final Report;
* v05: in final dataset, created "sort_key" to restore original order of variables as entered;
* v05: Used ods html close and ods listing close to suppress all output until Report section at end of macro;

* 2015-02-01;
* Added KEEP = to datasets for PROC MEANS and DATA SET __x_working01;

* Parameters:
	* DATASET: the data set containing the target and predictors;
	* Y: the target variable. Binary numeric. Larger value is modeled. Without missing values;  
	* A list of predictors.  Numeric.  Separate variables by a space;
		* Usage of dash, as in X1 - X6, is implemented;

ods html close;
ods listing close;

data _null_; set &dataset(obs=1);
array xx{*} &input;
call symput("var_num", dim(xx));
	
run;

data _null_;
%put "Var_Num =";
%put &var_num;
run;

%do I = 1 %TO &var_num;
	%do J = 1 %TO 11;
	 	%global label_&I._&J;
 		%end;
	%global min_&I;
	%global max_&I;
	%global p50_&I;
	%global p25_&I;
	%global p75_&I;
	%end;

data _null_; set &dataset(obs=1);
array xx{*} &input;
%do I = 1 %TO &var_num;
	call symput("label_&I", vname(xx(&I)));
	%end;	
run;

data __x_varname; length varname $32;
%do I = 1 %TO &var_num;
	%do J = 1 %TO 11;
		varname = compress("&&label_&I."|| "_p&J");
		call symput("label_&I._&J", varname);
		output;
		%end;
	%end;
	run;

* ... ;

proc means data = &dataset(keep = &Input) noprint;
var &Input;
output out = __x_meanout
min =
%do I = 1 %TO &var_num;
    min_&I
    %end;
max =
%do I = 1 %TO &var_num;
    max_&I
    %end;
p50 =
%do I = 1 %TO &var_num;
    p50_&I
    %end;
p25 =
%do I = 1 %TO &var_num;
    p25_&I
    %end;
p75 =
%do I = 1 %TO &var_num;
    p75_&I
    %end;
    ;
run;

data __x_meanout_report(keep = var_ min_ max_ p50_ p25_ p75_); 
	set __x_meanout;

length var_ $32;

array minx{&var_num}
   %do I = 1 %TO &var_num;
       min_&I
       %end;
       ;
array maxx{&var_num}
   %do I = 1 %TO &var_num;
       max_&I
       %end;
       ;
array p50x{&var_num}
   %do I = 1 %TO &var_num;
       p50_&I
       %end;
       ;
array p75x{&var_num}
   %do I = 1 %TO &var_num;
       p75_&I
       %end;
       ;
array p25x{&var_num}
   %do I = 1 %TO &var_num;
       p25_&I
       %end;
       ;
%do I = 1 %TO &var_num;
	if minx{&I} >= 1 then
 do;
		call symput("min&I",0);
		call symput("max&I", max_&I);
		call symput("p50&I", p50_&I);
		call symput("p75&I", p75_&I);
		call symput("p25&I", p25_&I);
		end;
	else if minx{&I} < 1 then
 do;
		call symput("min&I", -minx{&I} + 1);
		call symput("max&I", max_&I - minx{&I} + 1 );
		call symput("p50&I", p50_&I - minx{&I} + 1 );
		call symput("p75&I", p75_&I - minx{&I} + 1 );
		call symput("p25&I", p25_&I - minx{&I} + 1 );
		end;
	%end;

%do I = 1 %TO &var_num;
	var_ = "&&label_&I";
	min_ = min_&I;
	max_ = max_&I;
	p50_ = p50_&I;
	p25_ = p25_&I;
	p75_ = p75_&I;
	output;
	%end;

run;

data __x_working01; set &dataset(keep = &Y &Input) end=eof;

retain p1 - p7;

keep &Y
%do I = 1 %TO &var_num;
	%do J = 1 %TO 11;
		&&label_&I._&J
		%end;
	%end;
	;

array gx{&var_num} &Input;
array p{7} p1 - p7;

if _n_ = 1
then
do;
	p1 = 1;
	p2 = -2;
	p3 = -1;
	p4 = -0.5;
	p5 = 0.5;
	p6 = 2;
	p7 = 3;
	end;

%do I = 1 %TO &var_num;
	&&label_&I._1 = gx{&I} + &&min&I;
	&&label_&I._8  = log(&&label_&I._1);
 	&&label_&I._9  = (&&label_&I._1 - &&p50&I) ** p{6};
	&&label_&I._10 = (&&label_&I._1 - &&p75&I) ** p{6};
	&&label_&I._11 = (&&label_&I._1 - &&p25&I) ** p{6};
	%end;

%do I = 1 %TO &var_num;
	%do J = 2 %TO 7;
		&&label_&I._&J = &&label_&I._1 ** p{&J};
		%end;
	%end;

run;

ods output TTests = __x_TT;
ods output Statistics = __x_STAT;
ods exclude TTests;
ods exclude ConfLimits;
ods exclude Equality;
ods exclude EquivLimits;
ods exclude EquivTests;
ods exclude Statistics;

proc ttest data = __x_working01 plots = none;
   class &Y;
	var
	%do I = 1 %TO &var_num;
		%do J = 1 %TO 11;
			&&label_&I._&J
			%end;
		%end;
		;
run;

proc sort data = __x_STAT; by variable class;
run;

data __x_STAT_2; length variable $32; set __x_STAT; 
	by variable;

	keep n1 n2 sp variable mean1 mean2 min_value max_value;
	retain n1 n2 mean1 mean2 min_value max_value;

	if first.variable
	then
	do;
		min_value = .;
		max_value = .;
		end;
	if last.variable = 0
	then
	do;
		min_value = min(min_value,minimum);
		max_value = max(max_value,maximum);
		end;
	if first.variable then n1 = n;
	if first.variable then mean1 = mean;
	if first.variable + last.variable = 0 then n2 = n;
	if first.variable + last.variable = 0 then mean2 = mean;
	if last.variable
	then
	do;
		sp = stddev;
		output;
		end;
run;

proc sort data = __x_TT; by variable;
	where method = "Pooled";
run;

data __x_TT_2; merge __x_STAT_2 __x_TT ; by variable;
	length p1 - p11 $12 sort_key 4;
	length original_name $32;
	array px{11} $ p1 - p11;

	*retain var_ID 0;

	retain p1 "linear";
	retain p2 "x**-2";
	retain p3 "x**-1";
	retain p4 "x**-0.5";
	retain p5 "x**0.5";
	retain p6 "x**2";
	retain p7 "x**3";
	retain p8 "log(x)";
	retain p9 "(x-p50)**2";
	retain p10 "(x-p75)**2";
	retain p11 "(x-p25)**2";

%do I = 1 %TO &var_num;
	%do J = 1 %TO 11;
		if variable = trim("&&label_&I._&J") 
		then 
		do;
			transform = px{&J};
			sort_key = &I;
			original_name = trim("&&label_&I"); 
			end;
		%end;
	%end;

	*if transform = "linear" then var_ID + 1;

	tValue = -tValue;  /* modeling descending */
	b1D = tValue*(1/sp)*(sqrt(1/n1 + 1/n2));
	b0D = -(mean1**2 - mean2**2)/(2*sp**2) + log(n1/n2);
	chisq_D = tValue**2;
	label Probt = "Prob ChiSq";
	label sp = "pooled std dev";
	label min_value = "min (after adjustment)";
	label max_value = "max (after adjustment)";
run;

proc sort data = __x_TT_2; by /*var_ID*/ sort_key  descending chisq_D; run;

ods html;
ods listing;

proc print data = __x_meanout_report;
Title1 "Values before adjustment";
run;
title;
run;

options ls = 180;
proc print data = __x_TT_2 label;
var Original_Name Variable Transform n1 n2 min_value max_value tValue sp b0D b1D chisq_D Probt;
format min_value max_value 12.4 b0D b1D ProbT 8.5;
Title1 "LR_SCREENER (06) Report";
Title2 "Variables in same order as entered";
Title3 "Within Variable: Observations are sorted by descending ChiSq";
run;
Title;
run;
%mend; 
