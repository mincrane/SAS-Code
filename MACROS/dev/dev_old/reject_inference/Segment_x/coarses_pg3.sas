***********************************************************************;
* coarses_pg3.sas: 3rd step in reject inference process, this is      *;
*                  the first check point                              *;
*                  Creates good/bad coarses for the booked population *; 
*                  and accept/reject coarses for the overall          *;
*                  at both app time and recent time                   *;
* Input: building and validation datasets defined in parameters1.sas  *;
* Output: coarses for known good vs. known bad at apptim and recent   *;
*         coarses for accept vs. reject at apptime and recent         *;
* Note: the listed variables are minimum requirement for reject inf   *;
*       using standard ALI CB vars, add more vars as requested by PM  *;
***********************************************************************; 



options formdlim='-' compress=yes mprint symbolgen;   

%include 'parameters_pg1.sas';

data temp_app;
  set dat.&build_set_ap&segment_number;
run;

 
data temp_recent;
  set dat.&build_set_re&segment_number;
  if &perf in (&good. &bad. &ANB.) then arflag=1;
  else if &perf in (&reject.) then arflag=0;
run;

proc freq data=temp_recent;
title "testing: arflag";
tables arflag/missing;
run;



/* application time known good bad coarses */ 

title "application time known good bad coarses - Bld Only";
data appknown;
length longname $50 name $30;
longname='  ';
N=0; NMISS=0; MEAN=0; MAX=0; MIN=0; NAME='        '; REVERSALS=0;     
P1=0; P5=0; P10=0; P15=0; P25=0; P50=0; P75=0; P90=0; P95=0; P99=0;STD=0; PMISS=0; KS=0; IVAL=0;
run;

%finesplt_f(temp_app,&perf,BAD,&bad,&bad,GOOD,&good,&good,&weight,SBRI_Card_Score                ,10.0,10,appknown);
%finesplt_f(temp_app,&perf,BAD,&bad,&bad,GOOD,&good,&good,&weight,SBRI_Lease_Score                        ,10.0,10,appknown);
%finesplt_f(temp_app,&perf,BAD,&bad,&bad,GOOD,&good,&good,&weight,SBRI_Loan_Score             ,10.0,10,appknown);

%desc_f(appknown);

/* recent bureau known good bad coarses */ 

title "recent bureau known good bad coarses - Bld Only";
data recknown;
length longname $50 name $30;
longname='  ';
N=0; NMISS=0; MEAN=0; MAX=0; MIN=0; NAME='        ';  REVERSALS=0;     
P1=0; P5=0; P10=0; P15=0; P25=0; P50=0; P75=0; P90=0; P95=0; P99=0;STD=0; PMISS=0; KS=0; IVAL=0;
run;

%finesplt_f(temp_recent,&perf,BAD,&bad,&bad,GOOD,&good,&good,&weight,SBRI_Card_Score                ,10.0,10,recknown);
%finesplt_f(temp_recent,&perf,BAD,&bad,&bad,GOOD,&good,&good,&weight,SBRI_Lease_Score            ,10.0,10,recknown);
%finesplt_f(temp_recent,&perf,BAD,&bad,&bad,GOOD,&good,&good,&weight,SBRI_Loan_Score             ,10.0,10,recknown);

%desc_f(recknown);



/* application time accept reject coarses */ 

title "application time accept reject coarses - Bld Only";
data appar;
length longname $50 name $30;
longname='  ';
N=0; NMISS=0; MEAN=0; MAX=0; MIN=0; NAME='        '; REVERSALS=0;     
P1=0; P5=0; P10=0; P15=0; P25=0; P50=0; P75=0; P90=0; P95=0; P99=0;STD=0; PMISS=0; KS=0; IVAL=0;
run;

%finesplt_f(temp_app,&perf_ra,REJ,0,0,ACPT,1,1,&weight,SBRI_Card_Score          ,10.0,10,appar);
%finesplt_f(temp_app,&perf_ra,REJ,0,0,ACPT,1,1,&weight,SBRI_Lease_Score          ,10.0,10,appar);
%finesplt_f(temp_app,&perf_ra,REJ,0,0,ACPT,1,1,&weight,SBRI_Loan_Score               ,10.0,10,appar);

%desc_f(appar);

 

/* recent bureau accept reject coarses */

title "recent bureau accept reject coarses - Bld Only";
data recar;
length longname $50 name $30;
longname='  ';
N=0; NMISS=0; MEAN=0; MAX=0; MIN=0; NAME='        '; REVERSALS=0;
P1=0; P5=0; P10=0; P15=0; P25=0; P50=0; P75=0; P90=0; P95=0; P99=0;STD=0; PMISS=0; KS=0; IVAL=0;
run;

%finesplt_f(temp_recent,arflag,REJ,0,0,ACPT,1,1,&weight,SBRI_Card_Score            ,10.0,10,recar);
%finesplt_f(temp_recent,arflag,REJ,0,0,ACPT,1,1,&weight,SBRI_Lease_Score            ,10.0,10,recar);
%finesplt_f(temp_recent,arflag,REJ,0,0,ACPT,1,1,&weight,SBRI_Loan_Score                 ,10.0,10,recar);

%desc_f(recar);






