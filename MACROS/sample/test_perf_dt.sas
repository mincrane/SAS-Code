

options compress=yes obs=max ls=max ps=max pageno=1 errors=10 nocenter; * symbolgen mlogic mprint;
%put NOTE: PID of this session is &sysjobid..;

libname raw './data';

%let ind = drv;


proc sql;
create table ebay_usar_perf_&ind as
select 
a.*
,b.*
,c.*

from 
            
raw.ebay_usar_perf_trans_&ind.  a
left join raw.ebay_usar_perf_gloss_&ind.  b on a.slr_id = b.slr_id and a.run_dt = b.run_dt
left join  RAW.EBAY_USAR_MOB_DRV c on a.slr_id = c.slr_id and a.run_dt = c.run_dt
;
quit;

data ebay_usar_perf_all_&ind;
set ebay_usar_perf_&ind;

/*** 60 ****/

if ((perf_net_loss_60d >0 and perf_gmv_60d <=0) or divide(perf_net_loss_60d,perf_gmv_60d)>=0.05) and perf_amt_esc_claim_60d >100 then flag_perf_nloss_test_60d = 1;
 else flag_perf_nloss_test_60d = 0; 

if ((perf_amt_esc_claim_60d >0 and perf_gmv_60d <=0) or divide(perf_amt_esc_claim_60d,perf_gmv_60d)>=0.25) and perf_amt_esc_claim_60d >100 then flag_perf_esc_test_60d = 1;
 else flag_perf_esc_test_60d = 0; 

 if flag_perf_nloss_test_60d = 1 or flag_perf_esc_test_60d = 1 then flag_perf_60d = 1;
 else flag_perf_60d = 0;
 

if hist_gmv_30d >=1000 and CNT_HIST_TXN_30D >25 and orig_mob >12 then seg_flag = 1;
else if hist_gmv_30d>=1000 and cnt_hist_txn_30d>25 and orig_mob <=12 then seg_flag = 2;
else if hist_gmv_30d>=1000 and cnt_hist_txn_30d<=25 and orig_mob>12 then seg_flag = 3;
else if hist_gmv_30d>=1000 and cnt_hist_txn_30d<=25 and orig_mob<=12 then seg_flag = 4;
else seg_flag = 5;

/*
if (perf_flag_nloss_gt100_60d = 0 and flag_perf_woamt_60d = 1) or flag_susp_hist=1 then flag_exc = 1;
else flag_exc = 0;
*/

if seg_flag = 1 then seg_cd = 'txn gt25 & mob gt 12';
if seg_flag = 2 then seg_cd = 'txn gt25 & mob le 12';
if seg_flag = 3 then seg_cd = 'txn le25 & mob gt 12';
if seg_flag = 4 then seg_cd = 'txn le25 & mob le 12';
if seg_flag = 5 then seg_cd = 'GMV lt 1000';


if orig_mob >12 then flag_mob = '>12';
else flag_mob = '<=12';


perf_flag_60d = flag_perf_60d;
run;

proc freq data = ebay_usar_perf_all_&ind;
table seg_cd seg_flag*flag_perf_60d;
run;


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


PROC FORMAT;
PICTURE PCTPIC 0-high='009.999%';
PICTURE BPSPIC low-<0.1 = '9.9'(mult=1000)
               0.1-<  1 = '99' (mult=100)
			   1 -< 10 ='999'  (mult=100)
               10 - high ='9,999' (mult=100);

RUN;


proc tabulate data = ebay_usar_perf_all_&ind missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  seg_flag seg_cd flag_mob CNT_HIST_TXN_30D perf_flag_60d/style= [background = light bule];                                                                                                                                                                  
      var    perf_amt_esc_claim_60d perf_net_loss_60d perf_gmv_60d perf_cnt_txn_60d hist_gmv_30d flag_perf_60d
	         
			 /s=[background=light blue];                                   
    /*** performance summary ***/                       
    table   (seg_cd=""*(perf_flag_60d = '' all) all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			 
              flag_perf_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<flag_perf_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]])			 
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			
			 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  
			
			
			
    table   (seg_cd="" all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
              flag_perf_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<flag_perf_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]])			  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			
			 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  			

*where run_dt >='01jun2016'd; 
*where hist_gmv_30d >=1000;
run;



proc means data = ebay_usar_perf_all_&ind n nmiss mean min p1 p5 p25 p50 p75 p90 p95 p99 max sum;
class seg_cd;
var cnt_hist_txn_1d cnt_hist_txn_30d cnt_hist_txn_90d cnt_hist_txn_180d hist_gmv_30d orig_mob perf_amt_esc_claim_60d perf_net_loss_60d perf_gmv_60d perf_cnt_txn_60d perf_gross_loss_60 hist_gmv_30d ;
where hist_gmv_30d >=1000; 
run;




endsas;



data raw.ebay_usar_perf_dt_jun;
set raw.ebay_usar_analy_jun;
esc_claim_rate = divide(cnt_esc_claim_m0,cnt_hist_txn_m);
if esc_claim_rate>0.25 or loss_rate_m0>0.05 then perf_bad = 1;
else perf_bad = 0;

if esc_claim_rate>0.25 and loss_rate_m0>0.05 then perf_bad_test = 1;
else perf_bad_TEST = 0;



if net_loss_m0 >1000 then perf_large_loss = 1;
else perf_large_loss =0;
run;

proc freq data = raw.ebay_usar_perf_dt_jun;
table perf_bad perf_large_loss;
run;

proc means data = raw.ebay_usar_perf_dt_jun n mean nmiss min p1 p5 p25 p50 p75 p90 p95 p99 max;
run;

endsas;


Variable                 Label                          N            Mean     N Miss         Minimum        1st Pctl        5th Pctl       25th Pctl       50th Pctl       75th Pctl       90th Pctl       95th Pctl       99th Pctl         Maximum
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SLR_ID                   SLR_ID                   2047230       594065171          0      36.0000000       648429.00      4492626.00     62287559.00       482654018      1112959394      1289974690      1386238628      1426246975      1434279967
run_date                 run_date                 2047230      1762774354          0      1761955200      1761962731      1761984750      1762096503      1762525366      1763316921      1764009808      1764325642      1764510529      1764547198
seg                      seg                      2047230       1.1274322          0       1.0000000       1.0000000       1.0000000       1.0000000       1.0000000       1.0000000       2.0000000       2.0000000       2.0000000       2.0000000
CNT_HIST_TXN_M           CNT_HIST_TXN_M           2047230      25.3572149          0       1.0000000       1.0000000       1.0000000       1.0000000       3.0000000      10.0000000      34.0000000      71.0000000     326.0000000       154068.00
gmv_m0                   gmv_m0                   2047230         1258.27          0       0.0100000       3.3400000      10.5000000      54.0000000     171.6400000     533.5500000         1580.00         3228.00        15004.00     27615647.01
HIST_ITEM_SOLD_QTY_M0    HIST_ITEM_SOLD_QTY_M0    2047230      28.4669363          0       1.0000000       1.0000000       1.0000000       1.0000000       3.0000000      10.0000000      36.0000000      77.0000000     373.0000000       164646.00
CNT_HIST_CBT_TXN_M0      CNT_HIST_CBT_TXN_M0      2047230       2.1600367          0               0               0               0               0               0       1.0000000       2.0000000       5.0000000      29.0000000        30459.00
HIST_CBT_GMV_m0          HIST_CBT_GMV_m0          2047230     134.4688423          0               0               0               0               0               0      11.9700000     149.9900000     380.0000000         1947.18      6485340.80
net_loss_m0              net_loss_m0               193008      33.4628945    1854222    -710.0000000               0               0               0               0               0      27.4100000     111.2000000     551.5800000       561169.95
Amt_esc_claim_m0         Amt_esc_claim_m0         2047230      13.8292613          0    -467.5300000               0               0               0               0               0               0      14.9900000     274.9500000       893234.76
Amt_open_claim_m0        Amt_open_claim_m0        2047223      21.0867491          7    -440.7600000               0               0               0               0               0               0      49.9900000     387.0000000      1028120.05
cnt_esc_claim_m0         cnt_esc_claim_m0         2047230       0.1200832          0               0               0               0               0               0               0               0       1.0000000       2.0000000         2709.00
cnt_open_claim_m0        cnt_open_claim_m0        2047230       0.2305076          0               0               0               0               0               0               0               0       1.0000000       3.0000000         3124.00
cnt_esc_claim_test       cnt_esc_claim_test       2047230       0.1047044          0               0               0               0               0               0               0               0       1.0000000       2.0000000         2637.00
amt_esc_claim_test       amt_esc_claim_test       2047230      12.2304252          0    -619.8600000               0               0               0               0               0               0       6.4900000     244.5000000       870605.56
run_dt                   run_dt                   2047230        20401.92          0        20393.00        20393.00        20393.00        20394.00        20399.00        20408.00        20416.00        20420.00        20422.00        20422.00
msfs_mob                 msfs_mob                 2047230     -43.8840848          0        -1009.00        -1009.00        -1009.00      18.0000000      62.0000000     128.0000000     168.0000000     183.0000000     188.0000000     188.0000000
USER_CRE_DATE            USER_CRE_DATE            2047230      1492834021          0       631152000      1206694798      1238260626      1345293712      1481535618      1652432819      1728411258      1751224330      1762368077      1764534389
orig_mob                 orig_mob                 2047230     102.8296332          0               0               0       5.0000000      42.0000000     107.0000000     159.0000000     190.0000000     200.0000000     212.0000000     430.0000000
loss_rate_m0                                       193008       0.0535609    1854222      -1.5233333               0               0               0               0               0       0.0283700       0.2435896       1.0476667     756.0000000
tot_net_loss_m0          net_loss_m0               193008      33.4628945    1854222    -710.0000000               0               0               0               0               0      27.4100000     111.2000000     551.5800000       561169.95
num_txn_m0               CNT_HIST_TXN_M           2047230      25.3572149          0       1.0000000       1.0000000       1.0000000       1.0000000       3.0000000      10.0000000      34.0000000      71.0000000     326.0000000       154068.00
tot_gmv_m0               gmv_m0                   2047230         1258.27          0       0.0100000       3.3400000      10.5000000      54.0000000     171.6400000     533.5500000         1580.00         3228.00        15004.00     27615647.01
tot_num_txn_m0           CNT_HIST_TXN_M           2047230      25.3572149          0       1.0000000       1.0000000       1.0000000       1.0000000       3.0000000      10.0000000      34.0000000      71.0000000     326.0000000       154068.00
--------------------------------------------------------------------------



proc sql;
create table raw.ebay_usar_analy_&ind as
select 
a.*
,b.*
,c.*
,net_loss_m0/gmv_m0 as loss_rate_m0
,net_loss_m0 as tot_net_loss_m0
,cnt_hist_txn_m as num_txn_m0
,gmv_m0 as tot_gmv_m0
,cnt_hist_txn_m as tot_num_txn_m0
from raw.ebay_usar_&ind a
inner join raw.ebay_usar_fs_&ind b on a.slr_id = b.slr_id
inner join raw.ebay_usar_mob_&ind c on a.slr_id = c.slr_id
;

proc print data = raw.ebay_usar_analy_&ind(obs=10);
where loss_rate_m0> 1;
run;

proc means data = raw.ebay_usar_analy_&ind n mean nmiss min p1 p5 p25 p50 p75 p90 p95 p99 max;
run;
