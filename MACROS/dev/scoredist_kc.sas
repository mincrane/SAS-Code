/***************************************************/
/* Changes form scoredist.sas to scoredist_ks.sas  */
/* Changed include path                            */
/***************************************************/

%include '/sas/ebaysr/MACROS/dev/scoreformat.sas';
%include '/sas/ebaysr/MACROS/dev/score_distribution.sas';
%include '/sas/ebaysr/MACROS/dev/scoredist_amt.sas';
%include '/sas/ebaysr/MACROS/dev/tier_summary_macro_v2.sas';


libname mraw '.';

proc datasets lib=mraw;
	delete gini ksiv;
run;


/******** score dist v******/
%macro scoredist(datin = , perf= , scr=, eval= ,neval= );
	
*%scoreformat(dset=&datin,perfvar=&perf,wghtvar=wgt,scrvar=&scr,nbreak=10,eval= &eval ,neval=&neval ,fmtname=display,debug=NO);


	%score_dist( dataset=&datin,
								_var=&scr,
								breaks=10,
								weight_var=wgt,
								bad_flag=&perf,
								formatfilename=conformat_new.sas,
								fmtname=display,
								gen_opt=yes,
								where=,
								event=&eval,
								non_event=&neval,
								eventlabel=Bad,
								noneventlabel=Good
							  );


proc sql noprint;
	select sum(event_acc), sum(non_event_acc) into : total_evn , :total_non_even
  from score_dist1;
quit;
  

data score_d;
	set score_dist1;
	retain inv_evn &total_evn inv_non_evn &total_non_even;
	interval_bad_rate = event_acc/no_of_acc;
	inv_non_evn = inv_non_evn - non_event_acc;
	inv_evn  = inv_evn - event_acc;
	pct_inv_evn = lag1(inv_evn/&total_evn);
	pct_inv_non_evn = lag1(inv_non_evn/&total_non_even);
	if pct_inv_evn = . then pct_inv_evn = 1;
	if pct_inv_non_evn = . then pct_inv_non_evn=1;
	total_iv+iv;
	call symput('total_iv',total_iv);
run;
	
title "score distribution for &datin";	
title2 "KS = &max_ks  iv= &total_iv";

proc print data=score_d(drop=delta ks_spread total_iv inv_non_evn inv_evn) noobs;
	format interval_bad_rate percent8.3 ;
	sum event_acc non_event_acc no_of_acc iv;
run;


%include "conformat_new.sas";
*%scoredist_amt1(dset=&datin,perfvar=&perf,wghtvar=wgt,scrvar=&scr,tpvvar=perf_gtpv_d180,lossvar=perf_gross_loss_d180,fmtname=display,distname=&datin);
%scoredist_amt1(dset=&datin,perfvar=&perf,wghtvar=wgt,scrvar=&scr,tpvvar=perf_gtpv_d180,lossvar=amt_gross_trandt_180d,fmtname=display,distname=&datin);

%tier_sum(datain=&datin,tier = &scr , perf =&perf, bad = &eval ,tpv = perf_gtpv_d180 , loss = amt_gross_trandt_180d,tierfmt= conformat_new.sas );
*%tier_sum(datain=&datin,tier = &scr , perf =&perf, bad = &eval ,tpv = perf_gtpv_d180 , loss = paypal_net_loss_amt_d180,tierfmt= conformat_new.sas );


data gini;
	set score_d(keep = pct_inv_evn pct_inv_non_evn);
	length datain scr $18;
	datain = "&datin";
	scr = "&scr";
run;

proc append base=mraw.gini data=gini;
run;

data ksiv;
	length datain scr $18;
	datain = "&datin";
	scr = "&scr";
	ks = &max_ks;
	iv = &total_iv;
run;

proc append base=mraw.ksiv data=ksiv force;
run;


%mend;