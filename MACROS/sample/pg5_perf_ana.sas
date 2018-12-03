options compress=yes ls=max ps=max pageno=1 errors=10 nocenter  /*symbolgen mlogic mprint obs=10000 */; 
%put NOTE: PID of this session is &sysjobid..;


libname raw './data';

%let ind = jun;

%macro dd;
data raw.ebay_usar_perf_all_&ind;
set raw.ebay_usar_perf_&ind;


if (rat_gloss_30d >= 25 or rat_gloss_30d in (.D,.F)) and perf_gross_loss_30 > 25 then flag_rat_gloss_30d = 1;
else flag_rat_gloss_30d = 0;

if (rat_amt_esc_30d >= 25 or rat_amt_esc_30d in (.D,.F)) and perf_amt_esc_claim_30d >25 then flag_rat_amt_esc_30d = 1;
else flag_rat_amt_esc_30d = 0;

if flag_rat_gloss_30d = 1 or flag_rat_amt_esc_30d = 1 then perf_flag_30d = 1;
else perf_flag_30d =0;

if (rat_netloss_30d >= 5 or rat_netloss_30d in (.D,.F)) and perf_net_loss_30d > 25 then flag_rat_netloss_30d = 1;
else flag_rat_netloss_30d = 0;

if flag_rat_netloss_30d = 1 or flag_rat_amt_esc_30d = 1 then perf_flag_nloss_30d = 1;
else perf_flag_nloss_30d =0;

/** val **/
if (perf_gross_loss_30 >0 and perf_gmv_30d <=0) or divide(perf_gross_loss_30,perf_gmv_30d)>=0.25 then flag_perf_gloss_test_30d = 1;
 else flag_perf_gloss_test_30d = 0;
 
if (perf_net_loss_30d >0 and perf_gmv_30d <=0) or divide(perf_net_loss_30d,perf_gmv_30d)>=0.05 then flag_perf_nloss_test_30d = 1;
 else flag_perf_nloss_test_30d = 0; 

if (rat_gloss_30d >= 25 or rat_gloss_30d in (.D,.F)) then flag_rat_gloss_woamt_30d = 1;
else flag_rat_gloss_woamt_30d = 0;

if (rat_netloss_30d >= 5 or rat_netloss_30d in (.D,.F)) then flag_rat_netloss_woamt_30d = 1;
else flag_rat_netloss_woamt_30d = 0; 
 
/*** 60 ****/

if (rat_gloss_60d >= 25 or rat_gloss_60d in (.D,.F)) and perf_gross_loss_60 > 25 then flag_rat_gloss_60d = 1;
else flag_rat_gloss_60d = 0;

if (rat_amt_esc_60d >= 25 or rat_amt_esc_60d in (.D,.F)) and perf_amt_esc_claim_60d >25 then flag_rat_amt_esc_60d = 1;
else flag_rat_amt_esc_60d = 0;

if flag_rat_gloss_60d = 1 or flag_rat_amt_esc_60d = 1 then perf_flag_60d = 1;
else perf_flag_60d =0;

if (rat_netloss_60d >= 5 or rat_netloss_60d in (.D,.F)) and perf_net_loss_60d > 25 then flag_rat_netloss_60d = 1;
else flag_rat_netloss_60d = 0;

if flag_rat_netloss_60d = 1 or flag_rat_amt_esc_60d = 1 then perf_flag_nloss_60d = 1;
else perf_flag_nloss_60d =0;

/** val **/
 if (perf_net_loss_60d >0 and perf_gmv_60d <=0) or divide(perf_net_loss_60d,perf_gmv_60d)>=0.05 then flag_perf_nloss_test_60d = 1;
 else flag_perf_nloss_test_60d = 0; 

if (perf_amt_esc_claim_60d >0 and perf_gmv_60d <=0) or divide(perf_amt_esc_claim_60d,perf_gmv_60d)>=0.25 then flag_perf_esc_test_60d = 1;
 else flag_perf_esc_test_60d = 0; 

 if flag_perf_nloss_test_60d = 1 or flag_perf_esc_test_60d = 1 then flag_perf_test_60d = 1;
 else flag_perf_test_60d = 0;
 
 
if (rat_amt_esc_60d >= 25 or rat_amt_esc_60d in (.D,.F)) then flag_rat_amt_esc_woamt_60d = 1;
else flag_rat_amt_esc_woamt_60d = 0;
 
 if (rat_netloss_60d >= 5 or rat_netloss_60d in (.D,.F)) then flag_rat_netloss_woamt_60d = 1;
else flag_rat_netloss_woamt_60d = 0; 

if flag_rat_amt_esc_woamt_60d =1 or flag_rat_netloss_woamt_60d=1 then flag_perf_woamt_60d = 1;
else flag_perf_woamt_60d = 0;

/** 100 dollar **/

if (rat_amt_esc_60d >= 25 or rat_amt_esc_60d in (.D,.F)) and perf_amt_esc_claim_60d >100 then flag_rat_amt_esc_gt100_60d = 1;
else flag_rat_amt_esc_gt100_60d = 0;

if (rat_netloss_60d >= 5 or rat_netloss_60d in (.D,.F)) and perf_net_loss_60d > 100 then flag_rat_netloss_gt100_60d = 1;
else flag_rat_netloss_gt100_60d = 0;

if flag_rat_netloss_gt100_60d = 1 or flag_rat_amt_esc_gt100_60d = 1 then perf_flag_nloss_gt100_60d = 1;
else perf_flag_nloss_gt100_60d =0;


if hist_gmv_30d >=1000 and CNT_HIST_TXN_30D >25 and orig_mob >12 then seg_flag = 1;
else if hist_gmv_30d>=1000 and cnt_hist_txn_30d>25 and orig_mob <=12 then seg_flag = 2;
else if hist_gmv_30d>=1000 and cnt_hist_txn_30d<=25 and orig_mob>12 then seg_flag = 3;
else if hist_gmv_30d>=1000 and cnt_hist_txn_30d<=25 and orig_mob<=12 then seg_flag = 4;
else seg_flag = 5;

if (perf_flag_nloss_gt100_60d = 0 and flag_perf_woamt_60d = 1) or flag_susp_hist=1 then flag_exc = 1;
else flag_exc = 0;


if seg_flag = 1 then seg_cd = 'txn gt25 & mob gt 12';
if seg_flag = 2 then seg_cd = 'txn gt25 & mob le 12';
if seg_flag = 3 then seg_cd = 'txn le25 & mob gt 12';
if seg_flag = 4 then seg_cd = 'txn le25 & mob le 12';
if seg_flag = 5 then seg_cd = 'GMV lt 1000';

if net_loss_m0 >1000 or perf_net_loss_60d > 1000 then flag_large_loss = 1;
else flag_large_loss = 0; 

if orig_mob >12 then flag_mob = '>12';
else flag_mob = '<=12';

/*** 90 ****/
if (rat_gloss_90d >= 25 or rat_gloss_90d in (.D,.F)) and perf_gross_loss_90 > 25 then flag_rat_gloss_90d = 1;
else flag_rat_gloss_90d = 0;

if (rat_amt_esc_90d >= 25 or rat_amt_esc_90d in (.D,.F)) and perf_amt_esc_claim_90d >25 then flag_rat_amt_esc_90d = 1;
else flag_rat_amt_esc_90d = 0;

if flag_rat_gloss_90d = 1 or flag_rat_amt_esc_90d = 1 then perf_flag_90d = 1;
else perf_flag_90d =0;

if (rat_netloss_90d >= 5 or rat_netloss_90d in (.D,.F)) and perf_net_loss_90d > 25 then flag_rat_netloss_90d = 1;
else flag_rat_netloss_90d = 0;

if flag_rat_netloss_90d = 1 or flag_rat_amt_esc_90d = 1 then perf_flag_nloss_90d = 1;
else perf_flag_nloss_90d =0;


/***************************************************************************************************/

if (rat_hist_amt_esc_30d >=25 or rat_hist_amt_esc_30d = .F) then flag_hist_amt_esc_30d = 1;
else flag_hist_amt_esc_30d = 0;
 
if ( rat_hist_gross_loss_30d >= 25 or  rat_hist_gross_loss_30d = .F) and hist_gross_loss_30d  > 25 then flag_hist_gloss_30d = 1;
else flag_hist_gloss_all_30d = 0; 

if flag_hist_amt_esc_30d = 1 or flag_hist_gloss_30d = 1 then hist_flag_30d = 1;
else hist_flag_30d = 0;   

perf_flag_final_60d = perf_flag_nloss_gt100_60d;

run;


/*
proc freq data = raw.ebay_usar_perf_all_&ind;
table perf_flag_60d*perf_flag_nloss_60d flag_perf_test_60d*flag_perf_woamt_60d  perf_flag_nloss_60d*(flag_perf_woamt_60d perf_flag_nloss_gt100_60d)
flag_rat_amt_esc_60d*(flag_rat_netloss_60d flag_rat_gloss_60d)  flag_perf_nloss_test_60d*flag_rat_netloss_60d 

;
run;


proc freq data = raw.ebay_usar_perf_all_&ind;
table perf_flag_30d*(perf_flag_60d perf_flag_90d) perf_flag_60d*perf_flag_90d perf_flag_nloss_30d*(perf_flag_nloss_60d perf_flag_nloss_90d) perf_flag_nloss_60d*perf_flag_nloss_90d
;
run;


proc freq data = raw.ebay_usar_perf_all_&ind;
table seg_cd*seg_flag  flag_exc flag_susp_cur*(flag_susp_hist hist_flag_res_30d perf_flag_res_30d) perf_flag_res_30d*hist_flag_res_30d perf_flag_res_30d*perf_flag_nloss_60d flag_large_loss*perf_flag_final_60d;
where hist_gmv_30d >=1000;
run;
*/
proc sql;
select seg_cd,perf_flag_final_60d,flag_large_loss,count(*) 
from raw.ebay_usar_perf_all_&ind
where hist_gmv_30d>=1000
group by 1,2,3;

quit;


proc print data = raw.ebay_usar_perf_all_&ind(obs=50);
where hist_gmv_30d >=1000 and seg_flag = 1 and perf_net_loss_60d>5000 and perf_flag_final_60d = 0;
run;


proc means data = raw.ebay_usar_perf_all_&ind n nmiss mean min p1 p5 p25 p50 p75 p90 p95 p99 max sum;
class perf_flag_final_60d;
var hist_gmv_30d orig_mob perf_amt_esc_claim_60d perf_net_loss_60d perf_gmv_60d perf_cnt_txn_60d perf_gross_loss_60 hist_gmv_30d net_loss_m0 gmv_m0 rat_netloss_60d ;
where hist_gmv_30d >=1000 and seg_flag = 1 and perf_net_loss_60d>500;
run;

proc freq data = raw.ebay_usar_perf_all_&ind;
table flag_large_loss*(perf_flag_res_30d flag_susp_cur)/missing;
where seg_flag = 1 and hist_gmv_30d >=1000 and perf_flag_final_60d = 0;
run;

%mend;


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

*%macro dd;
proc tabulate data = raw.ebay_usar_perf_all_&ind missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  perf_flag_60d perf_flag_nloss_60d flag_perf_woamt_60d perf_flag_nloss_gt100_60d flag_rat_amt_esc_60d flag_rat_netloss_60d CNT_HIST_TXN_30D /style= [background = light bule];                                                                                                                                                                  
      var    perf_amt_esc_claim_60d perf_net_loss_60d perf_gmv_60d perf_cnt_txn_60d perf_gross_loss_60 hist_gmv_30d net_loss_m0 gmv_m0
	         
			 /s=[background=light blue];                                   
    /*** performance summary ***/                       
    table   (perf_flag_nloss_60d=""*(flag_perf_woamt_60d = '' all) all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  			  		                                   
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  

			
   table   (perf_flag_nloss_60d=""*(perf_flag_nloss_gt100_60d = '' all) all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  			  		                                   
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  			
			
	table   (perf_flag_60d=""*(perf_flag_nloss_60d = '' all) all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  			  		                                   
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  
    


	table   (CNT_HIST_TXN_30D ="" all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  			  		                                   
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  net_loss_m0  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  	

	
	table   (CNT_HIST_TXN_30D =""*(perf_flag_nloss_60d='' all) all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  			  		                                   
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  net_loss_m0  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  	
	
		
			
where hist_gmv_30d>=1000;			
			
			
format 	cnt_hist_txn_30d txnfmt.;		
			
			
run;


/** performance summary **/
ods html file = 'ebay_usar_perf_summary.xls';

proc tabulate data = raw.ebay_usar_perf_all_&ind missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  perf_flag_60d perf_flag_nloss_60d flag_perf_woamt_60d perf_flag_nloss_gt100_60d flag_rat_amt_esc_60d flag_rat_netloss_60d CNT_HIST_TXN_30D seg_cd/style= [background = light bule];                                                                                                                                                                  
      var    perf_amt_esc_claim_60d perf_net_loss_60d perf_gmv_60d perf_cnt_txn_60d perf_gross_loss_60 hist_gmv_30d net_loss_m0 gmv_m0
	         perf_flag_final_60d
			 /s=[background=light blue];                                   
    /*** performance summary ***/
     table   (perf_flag_nloss_gt100_60d='' all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
              perf_flag_final_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<perf_flag_final_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]]) 				  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  net_loss_m0  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0)
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  	

	
    table   (seg_cd='' all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
              perf_flag_final_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<perf_flag_final_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]]) 				  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  net_loss_m0  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0)
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  

			
   table   (seg_cd =''*(perf_flag_nloss_gt100_60d='' all) all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
              perf_flag_final_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<perf_flag_final_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]]) 				  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  net_loss_m0  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0)
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  			
			
	


	
where hist_gmv_30d>=1000 and flag_exc = 0;		
run;
*%mend;

/*** perf validation ***/


proc tabulate data = raw.ebay_usar_perf_all_&ind missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  perf_flag_60d perf_flag_nloss_60d flag_perf_woamt_60d perf_flag_nloss_gt100_60d flag_rat_amt_esc_60d flag_rat_netloss_60d CNT_HIST_TXN_30D seg_cd perf_flag_nloss_30d seg orig_mob flag_mob/style= [background = light bule];                                                                                                                                                                  
      var    perf_amt_esc_claim_60d perf_net_loss_60d perf_gmv_60d perf_cnt_txn_60d perf_gross_loss_60 hist_gmv_30d net_loss_m0 gmv_m0 perf_net_loss_30d
	         perf_flag_final_60d
			 /s=[background=light blue];                                   
    /*** performance summary ***/
     table   (perf_flag_nloss_gt100_60d='' all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
              perf_flag_final_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<perf_flag_final_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]]) 				  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  net_loss_m0  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0)
	          perf_net_loss_30d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_30d> ='% of net loss' rowpctsum<perf_gmv_30d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 

		  )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  	


   table   (perf_flag_nloss_30d='' all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
              perf_flag_final_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<perf_flag_final_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]]) 				  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  net_loss_m0  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0)
              perf_net_loss_30d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_30d> ='% of net loss' rowpctsum<perf_gmv_30d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 	       

		   )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  	


   table   (flag_perf_woamt_60d ='' all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
              perf_flag_final_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<perf_flag_final_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]]) 				  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  net_loss_m0  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0)
              perf_net_loss_30d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_30d> ='% of net loss' rowpctsum<perf_gmv_30d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 	      
		  )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  	


   table   (perf_flag_60d ='' all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
              perf_flag_final_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<perf_flag_final_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]]) 				  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss 60d'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  net_loss_m0  = 'Perf Net Loss M0'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0)
              perf_net_loss_30d  = 'Perf Net Loss 30d'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_30d> ='% of net loss' rowpctsum<perf_gmv_30d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 	      
		  )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  			   
	

   	 table   (seg =''*(orig_mob='' all) all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
              perf_flag_final_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<perf_flag_final_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]]) 				  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  net_loss_m0  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0)
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  	


  	 table   (seg =''*(orig_mob='' * (perf_flag_nloss_gt100_60d='' all) all) all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
              perf_flag_final_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<perf_flag_final_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]]) 				  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  net_loss_m0  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0)
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  	
 
 
    table   (seg =''*(flag_mob='' * (perf_flag_nloss_gt100_60d='' all) all) all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
              perf_flag_final_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<perf_flag_final_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]]) 				  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  net_loss_m0  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0)
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  	
 
 
   table   (seg =''*(flag_mob='' all) all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
              perf_flag_final_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<perf_flag_final_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]]) 				  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  net_loss_m0  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0)
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  	
 

	  
*where hist_gmv_30d>=1000 and flag_exc = 0;		
format orig_mob mobfmt.;
run;



endsas;
option nolabel;

%include '~/my_macro.sas';
%check_mean(datin = raw.ebay_usar_perf_all_jun);    /** 1,923,492 **/

endsas;











endsas;



/*************************************************************************************/
/*** waterfall                                                                      **/
if perf_cnt_suspend_30d > 0 then flag_perf_other_sus = 1;
else flag_perf_other_sus = 0;

if hist_cnt_suspend_30d > 0 then flag_hist_other_sus = 1;
else flag_hist_other_sus = 0;

if perf_flag_30d = 1 then waterfall = '1. High Exposure';
else if action_cd = 'Suspension' then waterfall = '2. SRM Suspension';
else if action_cd = 'High Restriction' then waterfall = '3. SRM High Restriction';
else if flag_perf_other_sus = 1 then waterfall = '4. Other Suspension';
else if action_cd = 'Low_restriction' then waterfall = '5. SRM low Restriction';
else if perf_flag_res_30d = 1 then waterfall = '6. Other issue';
else waterfall = '7. No Issue';

perf_gmv_30_60 = sum(perf_gmv_60d, -perf_gmv_30d); 

if AMT_HIST_GMV_90d > 0 then flag_hist_tran_90d = 1;
else flag_hist_tran_90d = 0;

if perf_gmv_90d > 0 then flag_perf_tran_90d = 1;
else flag_perf_tran_90d = 0;

if flag_cur_status = 'Suspended' then flag_susp_cur_all = 1;
else flag_susp_cur_all = 0; 


perf_flag_30d_1 = perf_flag_30d;
perf_flag_30d_2 = perf_flag_30d;

/*** perf indetermined **/

if waterfall = '1. High Exposure' then perf_qp_flag_30d = 1;
else if waterfall = '7. No Issue' then perf_qp_flag_30d = 0;
else perf_qp_flag_30d = .;

perf_qp_flag_30d_1 = perf_qp_flag_30d;

run;

*%mend;

/*** roll rate ****/
/*
proc freq data = raw.qp_final_perf;
table perf_flag_30d*(flag_action perf_flag_res_30d perf_cnt_suspend_30d) flag_action* (perf_flag_res_30d) perf_cnt_suspend_30d*flag_action hist_flag_30d*perf_flag_30d/missing;
run;

proc freq data = new;
table perf_flag_res_30d*perf_cnt_suspend_30d/missing;
where flag_action<=5;
run;
*/
/** roll rate **/

proc freq data = raw.qp_final_perf;
table perf_flag_15d*(perf_flag_30d perf_flag_45d perf_flag_60d perf_flag_90d) perf_flag_30d*(perf_flag_45d perf_flag_60d perf_flag_90d) perf_flag_45d*(perf_flag_60d perf_flag_90d) perf_flag_60d*perf_flag_90d;
run;


proc freq data = raw.qp_final_perf;
table waterfall*flag_cur_status   flag_susp_cur*(flag_susp_hist flag_cur_status) perf_qp_flag_30d/missing;
run;

/*
proc print data = raw.qp_final_perf(obs=30);
where waterfall = '4. Other Suspension' and perf_gmv_30d >5000;
run;
*/

proc format;
value lossfmt
.                 = 'Missing'
low      -  0     = '     <- 0   '    
0       <-  1000    = '0    <- 1000  '
1000    <-  2000  = '1000 <- 2000'
2000    <-  5000  = '2000 <- 5000'
5000    <-  10000 = '5000 <- 10000'
10000   <-  25000 = '10000<- 25000'
25000   <-  high  = '25000 <- High';

value lossf
.            = ' Missing'
low  - 0     = '     <-    0' 
0    <- 1000 = '     <- 1000'
1000 <- 2000 = '1000 -  High'
2000 <- high = '1000 -  High'
;

value gmvfmt
.            = ' Missing'
low - 0 = '<-0'
0  <- 1000 = '0<- 1000'
1000<- 2000 ='1000 <- 2000'
2000<- high ='>2000'
; 


value mobfmt
. = 'Missing'
low  - 5 = '0 - 5'
5<- high ='>5'
; 
quit;    


PROC FORMAT;
PICTURE PCTPIC 0-high='009.999%';
PICTURE BPSPIC low-<0.1 = '9.9'(mult=1000)
               0.1-<  1 = '99' (mult=100)
			   1 -< 10 ='999'  (mult=100)
               10 - high ='9,999' (mult=100);

RUN;

ods html file = 'pop_perf_summary.xls';
/*** exclusion **/
proc tabulate data = raw.qp_final_perf missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  flag_susp_hist waterfall action_cd flag_action perf_flag_res_30d perf_cnt_suspend_30d perf_flag_30d/style= [background = light bule];                                                                                                                                                                  
      var    perf_flag_30d_2 perf_amt_esc_30d perf_net_loss_30d perf_gmv_30d perf_cnt_txn_30d perf_net_loss_30d gross_loss_30 perf_gmv_30_60 perf_amt_open_clm_30d
	          perf_flag_30d_1
			 /s=[background=light blue];                                   
    /*** performance summary ***/                       
    table   (flag_susp_hist = '' all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  			  		                                   
              perf_cnt_txn_30d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_30d  = 'Perf GMV 30d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_30d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_30d> ='% of net loss' rowpctsum<perf_gmv_30d>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
			  perf_amt_esc_30d = 'PERF ESC CLAIM AMT 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_30d >='% of esc claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  gross_loss_30 = 'Perf Gross Loss 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<gross_loss_30>='% of esc claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  perf_amt_open_clm_30d = 'PERF OPEN CLAIM AMT 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_open_clm_30d >='% of open claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  waterfall=''*f=comma8.
			  
	        )     /Box="Perf Waterfall" row=float RTS=25 /*misstext = '0'*/;  

run;


%macro norun;
title 'without exclusion';

proc tabulate data = raw.qp_final_perf missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  waterfall action_cd flag_action perf_flag_res_30d perf_cnt_suspend_30d perf_flag_30d flag_susp_cur/style= [background = light bule];                                                                                                                                                                  
      var    perf_flag_30d_2 perf_amt_esc_30d perf_net_loss_30d perf_gmv_30d perf_cnt_txn_30d perf_net_loss_30d gross_loss_30 perf_gmv_30_60 perf_amt_open_clm_30d
	         perf_flag_30d_1
			 /s=[background=light blue];                                   
    /*** performance summary ***/                       
    table   (perf_flag_30d = '' all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
			  		                                   
              perf_cnt_txn_30d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_30d  = 'Perf GMV 30d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_30d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_30d> ='% of net loss' rowpctsum<perf_gmv_30d>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
			  perf_amt_esc_30d = 'PERF CLAIM AMT 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_30d >='% of esc claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  gross_loss_30 = 'Perf Gross Loss 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<gross_loss_30>='% of esc claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  perf_amt_open_clm_30d = 'PERF OPEN CLAIM AMT 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_open_clm_30d >='% of open claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  

 
 table   (waterfall = ''  all =[label ='Total' s=[background=grey font_weight=bold]]), 
              
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  perf_flag_30d_2 = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<perf_flag_30d_1> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]])    		                                   
              perf_cnt_txn_30d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_30d  = 'Perf GMV 30d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0)  
			 
			  perf_net_loss_30d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_30d> ='% of net loss' rowpctsum<perf_gmv_30d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_30d = 'PERF CLAIM AMT 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_30d >='% of esc claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  gross_loss_30 = 'Perf Gross Loss 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<gross_loss_30>='% of esc claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  perf_amt_open_clm_30d = 'PERF OPEN CLAIM AMT 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_open_clm_30d >='% of open claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
	        )     /Box="Perf Waterfall" row=float RTS=25 /*misstext = '0'*/;  

 table   (action_cd = '' all =[label ='Total' s=[background=grey font_weight=bold]]), 
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
			  perf_flag_30d_2 = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<perf_flag_30d_1> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]]) 		                                   
              perf_cnt_txn_30d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_30d  = 'Perf GMV 30d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0)  
			
			  perf_net_loss_30d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_30d> ='% of net loss' rowpctsum<perf_gmv_30d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_30d = 'PERF CLAIM AMT 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_30d >='% of esc claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  gross_loss_30 = 'Perf Gross Loss 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<gross_loss_30>='% of esc claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  perf_amt_open_clm_30d = 'PERF OPEN CLAIM AMT 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_open_clm_30d >='% of open claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
	        )     /Box="Action Code" row=float RTS=25 /*misstext = '0'*/;  


		
run;

%mend;

title 'with exclusion';


proc tabulate data = raw.qp_final_perf missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  waterfall action_cd flag_action perf_flag_res_30d perf_cnt_suspend_30d perf_flag_30d flag_susp_cur_all flag_perf_other_sus /style= [background = light bule];                                                                                                                                                                  
      var    perf_flag_30d_2 perf_amt_esc_30d perf_net_loss_30d perf_gmv_30d perf_cnt_txn_30d perf_net_loss_30d gross_loss_30 perf_gmv_30_60 perf_amt_open_clm_30d
	           perf_flag_30d_1 AMT_HIST_GMV_30d
			 /s=[background=light blue];                                   
  /*** performance summary ***/                       
    table   (perf_flag_30d = '' all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
			  		                                   
              perf_cnt_txn_30d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_30d  = 'Perf GMV 30d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_30d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_30d> ='% of net loss' rowpctsum<perf_gmv_30d>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
			  perf_amt_esc_30d = 'PERF CLAIM AMT 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_30d >='% of esc claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  gross_loss_30 = 'Perf Gross Loss 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<gross_loss_30>='% of esc claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  perf_amt_open_clm_30d = 'PERF OPEN CLAIM AMT 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_open_clm_30d >='% of open claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  

 
 table   (waterfall = ''  all =[label ='Total' s=[background=grey font_weight=bold]]), 
              
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  perf_flag_30d_2 = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<perf_flag_30d_1> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]])    		                                   
              perf_cnt_txn_30d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_30d  = 'Perf GMV 30d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0)  
			 
			  perf_net_loss_30d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_30d> ='% of net loss' rowpctsum<perf_gmv_30d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_30d = 'PERF CLAIM AMT 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_30d >='% of esc claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  gross_loss_30 = 'Perf Gross Loss 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<gross_loss_30>='% of esc claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  perf_amt_open_clm_30d = 'PERF OPEN CLAIM AMT 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_open_clm_30d >='% of open claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  
			  amt_hist_gmv_30d  = 'Hist GMV 30d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<amt_hist_gmv_30d> ='% of GMV' mean*f=comma8.0)
			  
	        )     /Box="Perf Waterfall" row=float RTS=25 /*misstext = '0'*/;  

 table   (action_cd = '' all =[label ='Total' s=[background=grey font_weight=bold]]), 
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
			  perf_flag_30d_2 = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<perf_flag_30d_1> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]]) 		                                   
              perf_cnt_txn_30d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_30d  = 'Perf GMV 30d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0)  
			
			  perf_net_loss_30d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_30d> ='% of net loss' rowpctsum<perf_gmv_30d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_30d = 'PERF CLAIM AMT 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_30d >='% of esc claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  gross_loss_30 = 'Perf Gross Loss 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<gross_loss_30>='% of esc claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  perf_amt_open_clm_30d = 'PERF OPEN CLAIM AMT 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_open_clm_30d >='% of open claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  
			  amt_hist_gmv_30d  = 'Hist GMV 30d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<amt_hist_gmv_30d> ='% of GMV' mean*f=comma8.0)
			  
	        )     /Box="Action Code" row=float RTS=25 /*misstext = '0'*/;  


/*** other suspension ***/			
table   (flag_perf_other_sus = '' all =[label ='Total' s=[background=grey font_weight=bold]]), 
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
			  perf_flag_30d_2 = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<perf_flag_30d_1> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]]) 		                                   
              perf_cnt_txn_30d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_30d  = 'Perf GMV 30d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0)  
			
			  perf_net_loss_30d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_30d> ='% of net loss' rowpctsum<perf_gmv_30d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_30d = 'PERF CLAIM AMT 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_30d >='% of esc claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  gross_loss_30 = 'Perf Gross Loss 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<gross_loss_30>='% of esc claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  perf_amt_open_clm_30d = 'PERF OPEN CLAIM AMT 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_open_clm_30d >='% of open claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0)

              amt_hist_gmv_30d  = 'Hist GMV 30d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<amt_hist_gmv_30d> ='% of GMV' mean*f=comma8.0)			  
	        )     /Box="Other Suspension" row=float RTS=25 /*misstext = '0'*/;  
		
/*** other issue ***/			
table   (perf_flag_res_30d= '' all =[label ='Total' s=[background=grey font_weight=bold]]), 
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
			  perf_flag_30d_2 = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<perf_flag_30d_1> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]]) 		                                   
              perf_cnt_txn_30d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_30d  = 'Perf GMV 30d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0)  
			
			  perf_net_loss_30d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_30d> ='% of net loss' rowpctsum<perf_gmv_30d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_30d = 'PERF CLAIM AMT 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_30d >='% of esc claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  gross_loss_30 = 'Perf Gross Loss 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<gross_loss_30>='% of esc claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  perf_amt_open_clm_30d = 'PERF OPEN CLAIM AMT 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_open_clm_30d >='% of open claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  
			  amt_hist_gmv_30d  = 'Hist GMV 30d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<amt_hist_gmv_30d> ='% of GMV' mean*f=comma8.0)
			  
	        )     /Box="Other Issue" row=float RTS=25 /*misstext = '0'*/;  
	
			
/*** indetermined ***/			
			

 table   (waterfall = ''*(flag_susp_cur_all='' all)  all =[label ='Total' s=[background=grey font_weight=bold]]), 
              
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  perf_flag_30d_2 = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<perf_flag_30d_1> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]])    		                                   
              perf_cnt_txn_30d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_30d  = 'Perf GMV 30d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0)  
			 
			  perf_net_loss_30d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_30d> ='% of net loss' rowpctsum<perf_gmv_30d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_30d = 'PERF CLAIM AMT 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_30d >='% of esc claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  gross_loss_30 = 'Perf Gross Loss 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<gross_loss_30>='% of esc claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  perf_amt_open_clm_30d = 'PERF OPEN CLAIM AMT 30d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_open_clm_30d >='% of open claim' rowpctsum<perf_gmv_30d> ='% of GMV' mean*f=comma8.0) 
			  
			  amt_hist_gmv_30d  = 'Hist GMV 30d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<amt_hist_gmv_30d> ='% of GMV' mean*f=comma8.0)
			  
	        )     /Box="Perf Waterfall/cur susp" row=float RTS=25 /*misstext = '0'*/;  		
			
		
where  flag_susp_hist ^= 1 ;		
run;

ods html close;


proc freq data =raw.qp_final_perf;
table waterfall*(hist_flag_30d hist_flag_res_30d  flag_hist_other_sus)   flag_cur_status*(flag_hist_other_sus flag_perf_other_sus action_cd) flag_hist_other_sus*(flag_perf_other_sus action_cd);
run; 


endsas;


endsas;




hist_gross_loss_30d   
msfs_mob              
perf_flag_res_30d     
hist_flag_res_30d     
perf_cnt_suspend_30d  
hist_cnt_suspend_30d 


flag_perf_tran rat_netloss_30d rat_netloss_90d rat_gloss_90d rat_gloss_30d rat_gloss_all_30d rat_gloss_all_90d rat_amt_esc_30d rat_amt_esc_90d/missing;