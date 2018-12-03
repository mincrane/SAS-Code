/*** compare bad defination and ITA score validation ***/

options compress=yes obs=max ls=max ps=max pageno=1 errors=10 nocenter; * symbolgen mlogic mprint;
%put NOTE: PID of this session is &sysjobid..;

filename pwfile "~/tera_pwf.txt";

options symbolgen;
data _null_;
  infile pwfile obs=1 length=l;
  input @;
  input @1 line $varying1024.  l;
  call symput('tdbpass',substr(line,1,l));
  
run;

libname scratch teradata user=&sysuserid PASSWORD="&tdbpass" TDPID="mz2" DATABASE=pp_scratch_risk	OVERRIDE_RESP_LEN=YES DBCOMMIT=0;
libname raw '/sas/pprd/austin/projects/LN/data';
 options compress=yes obs=max ls=max ps=max pageno=1 errors=10 nocenter; * symbolgen mlogic mprint;
 %put NOTE: PID of this session is &sysjobid..;
 
 filename pwfile "~/tera_pwf.txt";
 
 data _null_;
   infile pwfile obs=1 length=l;
   input @;
   input @1 line $varying1024.  l;
   call symput('tdbpass',substr(line,1,l));
   
 run;
 
 libname scratch teradata user=&sysuserid PASSWORD="&tdbpass" TDPID="mz2" DATABASE=pp_scratch_risk	OVERRIDE_RESP_LEN=YES DBCOMMIT=0;
 libname datin '/sas/pprd/austin/projects/LN/data';
 
 
 %let drv= onboard_drv;
 %let rundt =signup_upgrde_dt;


%include '/sas/pprd/austin/operations/macro_library/dev/general/scoreformat.sas';
%include '/sas/pprd/austin/operations/macro_library/dev/general/score_distribution.sas';
%include '/sas/pprd/austin/operations/macro_library/dev/general/scoredist_amt.sas';
%include '/sas/pprd/austin/models/dev/onboard/biz_prem/bureau_data/tier_summary_macro_v2.sas';

/******** score dist v******/
%macro scoredist(datin = , perf= , scr=, eval= ,neval= );
	
%scoreformat(dset=&datin,perfvar=&perf,wghtvar=wgt,scrvar=&scr,nbreak=10,eval= &eval ,neval=&neval ,fmtname=display,debug=NO);


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
%tier_sum(datain=&datin,tier = &scr , perf =&perf, bad = &eval ,tpv = perf_gtpv_d180 , loss = paypal_net_loss_amt_d180,tierfmt= conformat_new.sas );


data gini;
	set score_d(keep = pct_inv_evn pct_inv_non_evn);
	length datain scr $18;
	datain = "&datin";
	scr = "&scr";
run;

proc append base=raw.gini data=gini;
run;

data ksiv;
	length datain scr $18;
	datain = "&datin";
	scr = "&scr";
	ks = &max_ks;
	iv = &total_iv;
run;

proc append base=raw.ksiv data=ksiv force;
run;


%mend;

proc datasets lib=raw;
	delete gini ksiv;
run;

data new;
	set raw.onboard_perf_metrix;
	wgt=1;
	where flag_tran>0;
run;

ods html file = 'ITA_score_dist.xls';

%scoredist(datin = new,perf=provt_flag_d180, scr = LOB_ITA_score,eval =1,neval=0);

ods html close;

proc tabulate data = new missing order=formatted;
	class LOB_ITA_score ;
	var perf_gtpv_d180 amt_gross_trandt_180d paypal_net_loss_amt_d180;
  table lob_ita_score=" " all,
                      n="Num"*f=8.0 
	                    perf_gtpv_d180='GTPV'*(sum colpctsum<perf_gtpv_d180> ='% of TPV'*f=5.2 mean) 
	                    amt_gross_trandt_180d='Gloss'*(sum colpctsum<amt_gross_trandt_180d> ='% of Gloss'*f=5.2   rowpctsum<perf_gtpv_d180>='bps'*f=5.2 mean) 
	                                
	                    all
	                   	                    
	                    
	                    /Box="New Tire" row=float RTS=25;

	format lob_ita_score display.;
run;

