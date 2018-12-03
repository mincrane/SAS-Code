/***1. score distribution for numeric score ****/
/***2. summary of score                     ****/
/***3. proc tabulate                        ****/

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


%include '/sas/hemin/CODE/SCOREDIST/scoredist.sas';


data new;
	set raw.onboard_perf_metrix;
	wgt=1;
	where flag_tran>0;
run;

/** create score dist and gini data ***/ 

ods html file = 'ITA_score_dist.xls';

%scoredist(datin = new,perf=provt_flag_d180, scr = LOB_ITA_score,eval =1,neval=0);

ods html close;



/*** summary of score dist and ks iv*****/
%tier_sum(datain= str,tier = risk_sub_indy_n, perf = provt_flag_d180, bad = 1 ,tpv = perf_gtpv_d180 , loss = amt_gloss_d180,tierfmt= ); 

/*** create score distr and ks  ****/

libname raw '/sas/pprd/austin/projects/LN/data';

%include '/sas/pprd/austin/operations/macro_library/dev/general/score_distribution.sas';
%include '/sas/pprd/austin/models/dev/onboard/biz_prem/bureau_data/tier_summary_macro_v2.sas';
%include '/sas/pprd/austin/operations/macro_library/dev/general/scoredist_amt.sas';

data new;
	set raw.onboard_perf_metrix;
	wgt=1;
	where flag_tran>0;
run;


/******** score dist v******/
%macro scoredist(datin = , perf= , scr=, eval= ,neval= , tpv = ,loss = );
	
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

title "KS = &max_ks  iv= &total_iv";
proc print data=score_dist1;
run;

%include "conformat_new.sas";


%scoredist_amt1(dset=&datin,perfvar=&perf,wghtvar=wgt,scrvar=&scr,tpvvar= &tpv,lossvar=&loss,fmtname=display,distname=&datin);

%tier_sum(datain=&datin,tier = &scr , perf =&perf, bad = &eval ,tpv = &tpv , loss = &loss,tierfmt= conformat_new.sas );

%mend;

%scoredist(datin = new,perf=provt_flag_d180, scr = LOB_ITA_score,eval =1,neval=0,tpv = perf_gtpv_d180 , loss = amt_gross_trandt_180d);

endsas;
