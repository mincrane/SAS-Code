options nocenter formdlim='-' ps=95 compress = yes; *  obs=30 symbolgen mlogic mprint;


*%include '/sas/pprd/austin/projects/exposure/investigate/model/score_dist_min.sas';	
*%include '/sas/pprd/austin/projects/exposure/investigate/model/macro_decile.sas';	



%macro tier_sum(datain= ,tier = , perf = , bad = 0 ,tpv = , loss = , tierfmt= );
	
%if &bad = 1 %then %do;
 data datain;
 	set &datain;
 	&perf = 1 - &perf.;
 run;
%end;
%else %do;
data datain;
	set &datain;
run;
%end;

 	
%if (%length(&tierFmt)^=0) %then %do;
%include "&tierfmt";
%end;

/*
data datain;
	set &datain;
	score_cutoff = &tier;
run;
*/

	
proc means data= datain noprint;
	class &tier./missing;
	var &perf &tpv &loss;
	output out = summ sum= mean(&tier)= /autoname ;
	%if %length(&tierfmt)^=0 %then %do;
	format &tier display. ;
	%end;
run;

/*
proc print data=summ;
run;
*/

proc format;
	value misfmt
	 . = Total
	 
	 ;
run;

data new1;
	set summ nobs=nobs end=eof;
	*length tier $14 ;
	if _type_ = 0 then do;
		total_cnt = _freq_;
		total_bad = _freq_ - &perf._sum;
		total_tpv = &tpv._sum;
		total_loss= &loss._sum;
		&tier._mean = .;
		
	end;
	
	retain total_cnt total_bad total_tpv total_loss;	
	
	bad = _freq_ - &perf._sum;
	pct_cnt_total = divide(_freq_, total_cnt);
	inv_bad_rat = divide(bad,_freq_);
	pct_bad_total = divide(bad,total_bad);
	pct_tpv_total = divide(&tpv._sum,total_tpv);
	pct_loss_total =divide(&loss._sum,total_loss);
	inv_loss_bps = divide(&loss._sum,&tpv._sum)*10000;  
	good = &perf._sum;  
	
	if _type_ = 1 then do;
		cum_cnt+_freq_;
		cum_tpv+&tpv._sum;
		cum_loss+&loss._sum;
		cum_bad+bad;
		
		pct_cum_tpv = divide(cum_tpv,total_tpv);
	  pct_cum_cnt = divide(cum_cnt,total_cnt);
	  pct_cum_loss = divide(cum_loss,total_loss);
	  pct_cum_bad = divide(cum_bad,total_bad);  
	  
	  rate_cum_bad = divide(cum_bad,cum_cnt);
	  rate_cum_loss = divide(cum_loss,cum_tpv);
	    
	end;
	
	pos=_n_-1;

tot_obs= _n_;
if _type_=0 then tot_obs = nobs+1;	
if _type_=0 then delete;	
format &tier misfmt.;


run;

/*
proc print data=new1;
run;
*/

PROC REPORT DATA = new1 headline nowd split = '/' style(header)=[background=lightblue] missing;

column tot_obs &tier /*&tier._mean*/ _freq_ pct_cnt_total good bad pct_bad_total inv_bad_rat &tpv._sum &loss._sum pct_tpv_total pct_loss_total bps; *inv_loss_bps cum_cnt cum_bad pct_cum_cnt rate_cum_bad rate_cum_loss;



define  tot_obs            /SPACING=2 order width =3 order =internal 'Bin';

define &tier  				     	/SPACING=2 DISPLAY WIDTH=40 
                            %if %length(&tierfmt)^=0 %then %do;
																		format = display.
														%end;				
 														"&tier" Left ;

/*define &tier._mean          /SPACING=2 DISPLAY WIDTH=25 'Score Cutoff ' center 
														%if %length(&tierfmt)^=0 %then %do;
															format = scrfmt.
														%end; ;*/
 
define _freq_     					/SPACING=2 ANALYSIS WIDTH=10 'Applicants' center  ;
define pct_cnt_total				/SPACING=2 ANALYSIS WIDTH=12 format = percent10.2 '% of tot #' center  ;
define good       					/SPACING=2 ANALYSIS WIDTH=10 "Goods #" center  ;
define bad       						/SPACING=2 ANALYSIS WIDTH=10 "Bads #"  center  ;
define pct_bad_total       	/SPACING=4 ANALYSIS WIDTH=12 format = percent10.2 "Bad % of/ Tot Bad"  center  ;
define inv_bad_rat          /SPACING=4 DISPLAY  WIDTH=14 format = percent12.2 "Interval Bad / Rates"  center  ;
define &tpv._sum            /SPACING=4 ANALYSIS WIDTH=14 format = comma14.0 "GTPV / 180 days"  center  ;
define &loss._sum           /SPACING=2 ANALYSIS WIDTH=10 format = comma10.0 "Loss / 180 days"  center  ;
define pct_tpv_total      	/SPACING=2 ANALYSIS WIDTH=11 format = percent11.2 "TPV % of/ Total TPV"  center  ;
define pct_loss_total      	/SPACING=2 ANALYSIS WIDTH=11 format = percent11.2 "Pct Loss of/ Total Loss"  center  ;   
define BPS                  /SPACING=2 COMPUTED  WIDTH=10 format = comma6.0 "BPS"   center  ; 
*define inv_loss_bps         /SPACING=2 DISPLAY  WIDTH=10 format = comma6.0 "BPS"   center  ;


compute bps;                   
  bps= abs(&loss._sum.sum/&tpv._sum.sum)*10000;  
endcomp;                       

rbreak after /summarize skip ol;   
/*
compute after;
       &tier = 'TOTALS:';
endcomp;
*/

run;

%mend;



