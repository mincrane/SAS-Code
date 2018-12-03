options compress=yes obs=max ls=max ps=max pageno=1 errors=10 nocenter symbolgen mlogic mprint;
%put NOTE: PID of this session is &sysjobid..;


filename pwfile "~/tera_pwf.txt";

data _null_;
  infile pwfile obs=1 length=l;
  input @;
  input @1 line $varying1024.  l;
  call symput('tdbpass',substr(line,1,l));
  
run;


libname scratch teradata user=&sysuserid PASSWORD="&tdbpass" TDPID="hopper" DATABASE=p_riskmodeling_t  OVERRIDE_RESP_LEN=YES DBCOMMIT=0;
libname raw '../data';

/*** create perf **/


%macro createperf(ind= );
proc sql;
create table ebay_usar_perf_&ind as
select 
a.*
,b.*
,c.*
,e.*
from              
raw.ebay_usar_perf_trans_&ind.  a 
left join raw.ebay_usar_perf_gloss_&ind.  c on a.slr_id = c.slr_id and a.run_dt = c.run_dt
left join raw.ebay_usar_perf_status_&ind. e on a.slr_id = e.slr_id 
left join raw.EBAY_USAR_MOB_&ind. b on a.slr_id = b.slr_id and a.run_dt = b.run_dt
;
quit;


data raw.ebay_usar_perf_all_&ind;
set ebay_usar_perf_&ind;

/*** 60 ****/

if ((perf_net_loss_60d >0 and perf_gmv_60d <=0) or divide(perf_net_loss_60d,perf_gmv_60d)>=0.05) and perf_net_loss_60d >25 then perf_flag_nloss_60d = 1;
 else perf_flag_nloss_60d = 0; 

if ((perf_amt_esc_claim_60d >0 and perf_gmv_60d <=0) or divide(perf_amt_esc_claim_60d,perf_gmv_60d)>=0.25) and perf_amt_esc_claim_60d >100 then perf_flag_esc_60d = 1;
 else perf_flag_esc_60d = 0; 

 if perf_flag_nloss_60d = 1 or perf_flag_esc_60d = 1 then perf_flag_60d = 1;
 else perf_flag_60d = 0;
 
flag_perf_60d = perf_flag_60d;

if hist_gmv_30d >=1000 and CNT_HIST_TXN_30D >25 and orig_mob >12 then seg_flag = 1;
else if hist_gmv_30d>=1000 and cnt_hist_txn_30d>25 and orig_mob <=12 then seg_flag = 2;
else if hist_gmv_30d>=1000 and cnt_hist_txn_30d<=25 and orig_mob>12 then seg_flag = 3;
else if hist_gmv_30d>=1000 and cnt_hist_txn_30d<=25 and orig_mob<=12 then seg_flag = 4;
else seg_flag = 5;

if seg_flag = 1 then seg_cd = 'txn gt25 & mob gt 12';
if seg_flag = 2 then seg_cd = 'txn gt25 & mob le 12';
if seg_flag = 3 then seg_cd = 'txn le25 & mob gt 12';
if seg_flag = 4 then seg_cd = 'txn le25 & mob le 12';
if seg_flag = 5 then seg_cd = 'GMV lt 1000';


if orig_mob >12 then flag_mob = '>12';
else flag_mob = '<=12';


/** exclusion **/
if ((perf_net_loss_60d >0 and perf_gmv_60d <=0) or divide(perf_net_loss_60d,perf_gmv_60d)>=0.05) then flag_perf_nloss_test_60d = 1;
 else flag_perf_nloss_test_60d = 0; 

if ((perf_amt_esc_claim_60d >0 and perf_gmv_60d <=0) or divide(perf_amt_esc_claim_60d,perf_gmv_60d)>=0.25) then flag_perf_esc_test_60d = 1;
 else flag_perf_esc_test_60d = 0; 

 if flag_perf_nloss_test_60d = 1 or flag_perf_esc_test_60d = 1 then flag_perf_test_60d = 1;
 else flag_perf_test_60d = 0;


if (perf_flag_60d = 0 and flag_perf_test_60d = 1) or flag_susp_hist=1 then flag_exc = 1;
else flag_exc = 0;

run;

/**perf summary **/

proc format;
value lossfmt
.                 = 'Missing'
low      -  0     = '     <- 0   '    
0       <-  25    = '0    <- 25  '
25      <-  100   = '25   <- 100 '
100     <-  500   = '100  <- 500 '
500     <-  1000  = '500  <- 1000'
1000    <-  2000  = '1000 <- 2000'
2000    <-  5000  = '2000 <- 5000'
5000    <-  10000 = '5000 <- 10000'
10000   <-  25000 = '10000<- 25000'
25000   <-  high  = '25000 <- High';


value lossf
.             = ' Missing'
low  - 0      = '     <-    0' 
0    <- 100   = '     <-  100'
100  <- 500   = ' 100 <-  500'
500  <- 1000  = ' 500 <- 1000'
1000 <- high  = '1000 -  High';


value txnfmt
0 = '0'
0<-1 = '1'
1<-5 ='1<-5'
5<-25 = '5<-25'
25<-100 = '25<-100'
100<-500 = '100<-500'
500<-high = '>500';

value mobfmt
low-0 = '0'
0<-6 ='0<-6'
6<-12 = '6<-12'
12<-high = '>12'
;

quit;    

/*
proc freq data =  raw.ebay_usar_perf_all_&ind;
table orig_mob;
format orig_mob mobfmt.;
run;
*/

;

PROC FORMAT;
PICTURE PCTPIC 0-high='009.999%';
PICTURE BPSPIC low-<0.1 = '9.9'(mult=1000)
               0.1-<  1 = '99' (mult=100)
			   1 -< 10 ='999'  (mult=100)
               10 - high ='9,999' (mult=100);

RUN;


ods html file = "ebay_usar_pop_summary_&ind..xls";
proc tabulate data = raw.ebay_usar_perf_all_&ind missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  seg_flag seg_cd flag_mob CNT_HIST_TXN_30D perf_flag_60d/style= [background = light bule];                                                                                                                                                                  
      var    perf_amt_esc_claim_60d perf_net_loss_60d perf_gmv_60d perf_cnt_txn_60d hist_gmv_30d flag_perf_60d perf_gross_loss_60
	         
			 /s=[background=light blue];                                   
    /*** performance summary ***/                       
    table   (seg_cd=""*(perf_flag_60d = '' all) all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			 
              flag_perf_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<flag_perf_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]])			 
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  
			
			
			
    table   (seg_cd="" all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
              flag_perf_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<flag_perf_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]])			  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss 60d'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  			

where flag_exc =0;
*where hist_gmv_30d >=1000;
run;

ods html close;

/*** sampling ****/

proc freq data = raw.ebay_usar_perf_all_&ind.;
table seg_flag*perf_flag_60d;
where flag_exc = 0;
run;


data seg1 seg2 seg3 seg4 seg5;
set raw.ebay_usar_perf_all_&ind.;
if seg_flag = 1 then output seg1;
if seg_flag = 2 then output seg2;
if seg_flag = 3 then output seg3;
if seg_flag = 4 then output seg4;
if seg_flag = 5 then output seg5;
where flag_exc = 0;
run;

proc surveyselect data = seg5 method = srs samprate = 5 out = seg5_samp seed= 20161209;
run;

proc freq data = seg5_samp;
table perf_flag_60d;
run;


%macro sampling(datin = , datout= , totbad= );

proc sort data = &datin. ;
by perf_flag_60d;
run;


proc sql;
select sum(perf_flag_60d),6*sum(perf_flag_60d)  into : totbad1, :totgood1
from &datin.;
quit;

%if &totbad1 <=1000 %then %do;
%let totbad = &totbad1;
%end;
%else %let totbad = 1000;

%let totgood = %eval(&totbad. *6);

proc surveyselect data = &datin. method = srs n = (&totgood &totbad) seed = 20161209 out = &datout.;
strata perf_flag_60d;
run;

%mend;

%sampling(datin = seg1, datout=seg1_samp);
%sampling(datin = seg2, datout=seg2_samp);
%sampling(datin = seg3, datout=seg3_samp);
%sampling(datin = seg4, datout=seg4_samp);
%sampling(datin = seg5_samp, datout = seg5_samp1);

data raw.usar_modeling_&ind.;
set  seg1_samp seg2_samp seg3_samp seg4_samp seg5_samp1;
run;

proc freq data = raw.usar_modeling_&ind.;
table seg_flag*perf_flag_60d;
weight samplingweight;
run;

proc freq data = raw.usar_modeling_&ind.;
table seg_flag*perf_flag_60d;
run;

proc append base=raw.usar_modeling_drv data=raw.usar_modeling_&ind. force;
run;

%mend;
*%createperf(ind=201601);
*%createperf(ind=201602);
*%createperf(ind=201603);
*%createperf(ind=201604);
*%createperf(ind=201605);
*%createperf(ind=201606);
*%createperf(ind=201511);
*%createperf(ind=201512);


/***********************************************************************************************/
/***********************************************************************************************/

/** summary **/
proc freq data=raw.usar_modeling_drv;
table seg_cd*perf_flag_60d;
run;

proc freq data=raw.usar_modeling_drv;
table seg_cd*perf_flag_60d;
weight samplingweight;
run;


/*** test ***/
/*
proc sort data = raw.usar_modeling_drv out=test1 nodupkey;
by slr_id;
run;

proc freq data=test1;
table seg_cd*perf_flag_60d;
run;

proc freq data=test1;
table seg_cd*perf_flag_60d;
weight samplingweight;
run;

proc sort data = raw.usar_modeling_drv(where =(perf_flag_60d=0)) out=test2 nodupkey;
by slr_id;
run;

proc sort data = raw.usar_modeling_drv(where =(perf_flag_60d=1)) out=test3 nodupkey;
by slr_id;
run;


proc sql outobs = 60;
select slr_id, run_date,seg_cd ,flag_mob, CNT_HIST_TXN_30D, perf_flag_60d, perf_amt_esc_claim_60d, perf_net_loss_60d, perf_gmv_60d, perf_cnt_txn_60d,hist_gmv_30d,perf_gross_loss_60,flag_susp_cur,flag_susp_hist
from raw.usar_modeling_drv(where =(perf_flag_60d=1))
where slr_id in (select slr_id from raw.usar_modeling_drv where perf_flag_60d=1 group by 1 having count(slr_id)>=4)
order by slr_id,run_date;
quit;

proc print data = raw.ebay_usar_perf_status_201603;
where slr_id = 1080538695;
proc print data = raw.ebay_usar_perf_status_201606;
where slr_id = 1080538695;
run;


proc sql;
select sum(flag_susp_cur),sum(1)
from raw.usar_modeling_drv(where =(perf_flag_60d=1))
where slr_id in (select slr_id from raw.usar_modeling_drv where perf_flag_60d=1 group by 1 having count(slr_id)>=2)
order by slr_id;
quit;
*/

proc sql;

select seg_cd,sum(samplingweight) as totnum, sum(perf_gmv_60d*samplingweight) as totgmv60d
from raw.usar_modeling_drv
group by 1;
quit;




%macro summ;
PROC FORMAT;
PICTURE PCTPIC 0-high='009.999%';
PICTURE BPSPIC low-<0.1 = '9.9'(mult=1000)
               0.1-<  1 = '99' (mult=100)
			   1 -< 10 ='999'  (mult=100)
               10 - high ='9,999' (mult=100);

RUN;

ods html file = "ebay_usar_pop_summary_drv.xls";


proc tabulate data = raw.usar_modeling_drv missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  run_dt seg_flag seg_cd flag_mob CNT_HIST_TXN_30D perf_flag_60d/style= [background = light bule];                                                                                                                                                                  
      var    perf_amt_esc_claim_60d perf_net_loss_60d perf_gmv_60d perf_cnt_txn_60d hist_gmv_30d flag_perf_60d perf_gross_loss_60
	         
			 /s=[background=light blue];                                   
    /*** performance summary ***/                       
    table   (run_dt=''*(seg_cd=""*(perf_flag_60d = '' all) all) all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			 
              flag_perf_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<flag_perf_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]])			 
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  
			
			
			
    table   (seg_cd="" all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
              flag_perf_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<flag_perf_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]])			  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss 60d'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  			

	table   (seg_cd=""*(perf_flag_60d='' all) all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
              flag_perf_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<flag_perf_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]])			  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss 60d'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  					
			
			
where flag_exc =0;
format run_dt yymon7.;
run;


proc tabulate data = raw.usar_modeling_drv missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  run_dt seg_flag seg_cd flag_mob CNT_HIST_TXN_30D perf_flag_60d/style= [background = light bule];                                                                                                                                                                  
      var    perf_amt_esc_claim_60d perf_net_loss_60d perf_gmv_60d perf_cnt_txn_60d hist_gmv_30d flag_perf_60d perf_gross_loss_60
	         
			 /s=[background=light blue];                                   
    /*** performance summary ***/                       
    table   (run_dt=''*(seg_cd=""*(perf_flag_60d = '' all) all) all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			 
              flag_perf_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<flag_perf_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]])			 
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  
			
			
			
    table   (seg_cd="" all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
              flag_perf_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<flag_perf_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]])			  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss 60d'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  			

	table   (seg_cd=""*(perf_flag_60d='' all) all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
              flag_perf_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<flag_perf_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]])			  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss 60d'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  					
			
			
where flag_exc =0;
format run_dt yymon7.;
weight samplingweight;
run;

ods html close;
%mend;

/**** upload **/


proc contents data =raw.usar_modeling_drv;
run;


data scratch.ebay_usar_samp_drv(MultiLoad=yes dbcreate_table_opts='primary index(slr_id,run_date)');
 set raw.usar_modeling_drv;
 keep slr_id run_date run_dt;
run;
