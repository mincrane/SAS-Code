options compress=yes ls=max ps=max pageno=1 errors=10 nocenter  /*symbolgen mlogic mprint obs=10000 */; 
%put NOTE: PID of this session is &sysjobid..;


libname raw './data';



*%check_mean(datin = raw.ebay_usar_perf_trans_jun);    /** 1,923,492 **/
*%check_mean(datin = raw.ebay_usar_perf_gloss_jun);
*%check_mean(datin =raw.ebay_usar_status_jun);


%let ind = jun;


proc sql;
create table ebay_usar_perf_&ind as
select 
a.*
,b.*
,c.*
,d.*
,e.*
,f.*
/*
,perf_HIST_TXN_30D as perf_cnt_txn_30d
,perf_HIST_TXN_60D as perf_cnt_txn_60d
,perf_HIST_TXN_90D as perf_cnt_txn_90d
,perf_amt_esc_claim_30  as perf_amt_esc_claim_30d
,perf_cnt_esc_claim_30  as perf_cnt_esc_claim_30d
,perf_amt_esc_claim_60  as perf_amt_esc_claim_60d
,perf_cnt_esc_claim_60  as perf_cnt_esc_claim_60d

,perf_amt_esc_claim_90  as perf_amt_esc_claim_90d
,perf_cnt_esc_claim_90  as perf_cnt_esc_claim_90d
*/
from 
raw.ebay_usar_analy_&ind a                
left join raw.ebay_usar_perf_trans_&ind.  b on a.slr_id = b.slr_id and a.run_dt = b.run_dt
left join raw.ebay_usar_perf_gloss_&ind.  c on a.slr_id = c.slr_id and a.run_dt = c.run_dt
left join raw.ebay_usar_status_&ind.      d on a.slr_id = d.slr_id and a.run_dt = d.run_dt
left join raw.ebay_usar_perf_status_&ind. e on a.slr_id = e.slr_id 
left join raw.ebay_usar_perf_issue_&ind.  f on a.slr_id = f.slr_id and a.run_dt = f.run_dt

;
quit;


data raw.ebay_usar_perf_&ind;
set ebay_usar_perf_&ind.;

%include '/ebaysr/MACROS/release/Beh_Macros.sas';  


%Ratio(perf_gross_loss_30,perf_gmv_30d ,rat_gloss_30d,100,0.01,label= Ratio gross loss last 30 days) ;  
%Ratio(perf_gross_loss_60,perf_gmv_60d ,rat_gloss_60d,100,0.01,label= Ratio gross loss last 60 days) ;  
%Ratio(perf_gross_loss_90,perf_gmv_90d ,rat_gloss_90d,100,0.01,label= Ratio gross loss last 90 days) ;  


%Ratio(perf_net_loss_30d,perf_gmv_30d ,rat_netloss_30d,100,0.01,label= Ratio net loss last 30 days) ;  
%Ratio(perf_net_loss_60d,perf_gmv_60d ,rat_netloss_60d,100,0.01,label= Ratio net loss last 60 days) ;  
%Ratio(perf_net_loss_90d,perf_gmv_90d ,rat_netloss_90d,100,0.01,label= Ratio net loss last 90 days) ;   


%Ratio(perf_total_gloss_30,perf_gmv_30d ,rat_gloss_all_30d,100,0.01,label= Ratio all gross loss last 30 days) ;  
%Ratio(perf_total_gloss_60,perf_gmv_60d ,rat_gloss_all_60d,100,0.01,label= Ratio all gross loss last 60 days) ;  
%Ratio(perf_total_gloss_90,perf_gmv_90d ,rat_gloss_all_90d,100,0.01,label= Ratio all gross loss last 90 days) ;  


%Ratio(perf_cnt_esc_claim_30d,perf_cnt_txn_30d ,rat_cnt_esc_30d,100,0.01,label= Ratio cnt esc claims last 30 days) ;  
%Ratio(perf_cnt_esc_claim_60d,perf_cnt_txn_60d ,rat_cnt_esc_60d,100,0.01,label= Ratio cnt esc claims last 60 days) ;  
%Ratio(perf_cnt_esc_claim_90d,perf_cnt_txn_90d ,rat_cnt_esc_90d,100,0.01,label= Ratio cnt esc claims last 90 days) ;  


%Ratio(perf_amt_esc_claim_30d,perf_gmv_30d ,rat_amt_esc_30d,100,0.01,label= Ratio amt esc claims last 30 days) ;  
%Ratio(perf_amt_esc_claim_60d,perf_gmv_60d ,rat_amt_esc_60d,100,0.01,label= Ratio amt esc claims last 60 days) ;  
%Ratio(perf_amt_esc_claim_90d,perf_gmv_90d ,rat_amt_esc_90d,100,0.01,label= Ratio amt esc claims last 90 days) ;  

/*
%Ratio(hist_cnt_esc_claim_30d,cnt_hist_txn_30d,rat_hist_cnt_esc_30d,100,0.01,label= Ratio hist cnt esc claims last 30 days) ;  
%Ratio(hist_amt_esc_claim_30d,amt_hist_gmv_30d,rat_hist_amt_esc_30d,100,0.01,label= Ratio hist amt esc claims last 30 days) ;
*/

%Ratio(hist_gross_loss_30d, hist_gmv_30d, rat_hist_gross_loss_30d,100,0.01,label= Ratio hist gross loss last 30 days) ;

 
if perf_gmv_90d > 0 then flag_perf_tran = 1;
else flag_perf_tran = 0;

/** forced reversal ***/
%Ratio(PERF_FRCD_RVRSL_USD_AMT_30d,perf_total_gloss_30,rat_amt_FR_gloss_30d,100,0.01,label= Ratio amt force Reversal to total gloss last 30 days) ;  

/*************************/
drop 
PERF_EBAY_PYT_USD_AMT_30d     
PERF_EBAY_PYT_USD_AMT_60d     
PERF_EBAY_PYT_USD_AMT_90d     
     
PERF_SLR_APPL_PYT_USD_AMT_30d 
PERF_SLR_APPL_PYT_USD_AMT_60d 
PERF_SLR_APPL_PYT_USD_AMT_90d 

PERF_BYR_APPL_PYT_USD_AMT_30d 
PERF_BYR_APPL_PYT_USD_AMT_60d 
PERF_BYR_APPL_PYT_USD_AMT_90d 

/*
PERF_FRCD_RVRSL_USD_AMT_30d   
PERF_FRCD_RVRSL_USD_AMT_60d   
*/
PERF_FRCD_RVRSL_USD_AMT_90d   

;

run;


option nolabel;

%include '~/my_macro.sas';
%check_mean(datin = raw.ebay_usar_perf_jun);    /** 1,923,492 **/


endsas;



























proc format;
value lossfmt
low - 25        = 'Low - 25'
25 <- 50        = '25 <- 50' 
50 <- 100       = '50 <-100'
100<- 500       = '100<-500'
500<-1000       = '500<-1000'
1000<-5000      = '1000 <- 5000'
5000<-10000     = '5000 <- 10000'
10000<- high    = '10000 <-high'
;

value ratfmt
low - 5 = 'Low - 5'
5 - 10  = '5<- 10'
10 - 25 = '10<-25'
25 - 35 = '25<-35'
35 - 50 = '35<-50'
50 - 100= '50<-100'
100 - high = '100<-high';
run;


endsas;
proc freq data = raw.qp_final;
table flag_perf_tran rat_netloss_30d rat_netloss_90d rat_gloss_90d rat_gloss_30d rat_gloss_all_30d rat_gloss_all_90d rat_amt_esc_30d rat_amt_esc_90d/missing;
format rat_netloss_30d rat_netloss_90d rat_gloss_90d rat_gloss_30d rat_gloss_all_30d rat_gloss_all_90d rat_amt_esc_30d rat_amt_esc_90d ratfmt.;
run;
  

option nolabel;

%include '~/my_macro.sas';
%check_mean(datin = raw.qp_final);
