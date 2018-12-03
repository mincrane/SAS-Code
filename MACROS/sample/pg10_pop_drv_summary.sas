
options compress=yes obs=max ls=max ps=max pageno=1 errors=10 nocenter; * symbolgen mlogic mprint;
%put NOTE: PID of this session is &sysjobid..;


filename pwfile "~/tera_pwf.txt";

data _null_;
  infile pwfile obs=1 length=l;
  input @;
  input @1 line $varying1024.  l;
  call symput('tdbpass',substr(line,1,l));
  
run;

libname raw  '/ebaysr/projects/arus/data';
libname val  '/ebaysr/projects/arus/validation/data';

proc freq data = raw.usar_modeling_drv;
table perf_flag_nloss_60d*perf_flag_esc_60d;
weight samplingweight;
run;


data raw.usar_all_raw;
set 
raw.ebay_usar_perf_all_201601
raw.ebay_usar_perf_all_201602
raw.ebay_usar_perf_all_201603
raw.ebay_usar_perf_all_201604
raw.ebay_usar_perf_all_201605
raw.ebay_usar_perf_all_201606
raw.ebay_usar_perf_all_201511
raw.ebay_usar_perf_all_201512
;
run;


PROC FORMAT;
PICTURE PCTPIC 0-high='009.999%';
PICTURE BPSPIC low-<0.1 = '9.9'(mult=1000)
               0.1-<  1 = '99' (mult=100)
			   1 -< 10 ='999'  (mult=100)
               10 - high ='9,999' (mult=100);

RUN;

ods html file = "ebay_usar_pop_summary_drv_all.xls";

data drv;
set raw.usar_modeling_drv;
weighted_cnt = 1;
run; 

title 'Unweighted';
proc tabulate data = drv missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  run_dt seg_flag seg_cd flag_mob CNT_HIST_TXN_30D perf_flag_60d/style= [background = light bule];                                                                                                                                                                  
      var    perf_amt_esc_claim_60d perf_net_loss_60d perf_gmv_60d perf_cnt_txn_60d hist_gmv_30d flag_perf_60d perf_gross_loss_60 weighted_cnt
	         
			 /s=[background=light blue];                                   
    /*** performance summary ***/                       
 			
    table   (seg_cd="" all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  weighted_cnt = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<weighted_cnt> = '% of total weighted' ) 
			  
              flag_perf_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<flag_perf_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]])			  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss 60d'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  			
			
where flag_exc =0;
*weight samplingweight;
run;

title 'Weighted';
proc tabulate data = drv missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  run_dt seg_flag seg_cd flag_mob CNT_HIST_TXN_30D perf_flag_60d/style= [background = light bule];                                                                                                                                                                  
      var    perf_amt_esc_claim_60d perf_net_loss_60d perf_gmv_60d perf_cnt_txn_60d hist_gmv_30d flag_perf_60d perf_gross_loss_60 weighted_cnt
	         
			 /s=[background=light blue];                                   
    /*** performance summary ***/                       
 			
    table   (seg_cd="" all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  weighted_cnt = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<weighted_cnt> = '% of total weighted' ) 
			  
              flag_perf_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<flag_perf_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]])			  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss 60d'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  			
			
where flag_exc =0;
weight samplingweight;
run;


title 'July 2016';
proc tabulate data = val.ebay_usar_datall_val_jul missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  run_dt seg_flag seg_cd CNT_HIST_TXN_30D perf_flag_60d/style= [background = light bule];                                                                                                                                                                  
      var    perf_amt_esc_claim_60d perf_net_loss_60d perf_gmv_60d perf_cnt_txn_60d hist_gmv_30d flag_perf_60d perf_gross_loss_60 
	         
			 /s=[background=light blue];                                   
    /*** performance summary ***/                       
 			
    table   (seg_cd="" all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			 /* weighted_cnt = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<weighted_cnt> = '% of total weighted' )  */
			  
              flag_perf_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<flag_perf_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]])			  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss 60d'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  			
			
run;

title '20160806';
proc tabulate data = val.ebay_usar_datall_val_0806 missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  run_dt seg_flag seg_cd CNT_HIST_TXN_30D perf_flag_60d/style= [background = light bule];                                                                                                                                                                  
      var    perf_amt_esc_claim_60d perf_net_loss_60d perf_gmv_60d perf_cnt_txn_60d hist_gmv_30d flag_perf_60d perf_gross_loss_60 
	         
			 /s=[background=light blue];                                   
    /*** performance summary ***/                       
 			
    table   (seg_cd="" all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			 /* weighted_cnt = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<weighted_cnt> = '% of total weighted' ) */
			  
              flag_perf_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<flag_perf_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]])			  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss 60d'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  			
			
run;


title 'test val samp';
proc tabulate data = val.ebay_usar_datall_val_samp missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  run_dt seg_flag seg_cd CNT_HIST_TXN_30D perf_flag_60d/style= [background = light bule];                                                                                                                                                                  
      var    perf_amt_esc_claim_60d perf_net_loss_60d perf_gmv_60d perf_cnt_txn_60d hist_gmv_30d flag_perf_60d perf_gross_loss_60 
	         
			 /s=[background=light blue];                                   
    /*** performance summary ***/                       
 			
    table   (seg_cd="" all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			 /* weighted_cnt = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<weighted_cnt> = '% of total weighted' ) */ 
			  
              flag_perf_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<flag_perf_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]])			  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss 60d'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  			
			
run;

title 'without tran in perf';

proc tabulate data = val.ebay_usar_datall_val_jul missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  run_dt seg_flag seg_cd CNT_HIST_TXN_30D perf_flag_60d/style= [background = light bule];                                                                                                                                                                  
      var    perf_amt_esc_claim_60d perf_net_loss_60d perf_gmv_60d perf_cnt_txn_60d hist_gmv_30d flag_perf_60d perf_gross_loss_60 
	         
			 /s=[background=light blue];                                   
    /*** performance summary ***/                       
 			
    table   (seg_cd=""*(perf_flag_60d='' all) all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			 /* weighted_cnt = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<weighted_cnt> = '% of total weighted' )  */
			  
              flag_perf_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<flag_perf_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]])			  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss 60d'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  			

where perf_gmv_60d <=0;			
run;

title 'all data no sampling';
proc tabulate data = raw.usar_all_raw missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  run_dt seg_flag seg_cd CNT_HIST_TXN_30D perf_flag_60d/style= [background = light bule];                                                                                                                                                                  
      var    perf_amt_esc_claim_60d perf_net_loss_60d perf_gmv_60d perf_cnt_txn_60d hist_gmv_30d flag_perf_60d perf_gross_loss_60 
	         
			 /s=[background=light blue];                                   
    /*** performance summary ***/                       
 			
    table   (seg_cd="" all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			 /* weighted_cnt = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<weighted_cnt> = '% of total weighted' )  */
			  
              flag_perf_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<flag_perf_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]])			  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss 60d'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  			
			
run;


title 'perf def';
proc tabulate data = drv missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  run_dt seg_flag seg_cd flag_mob CNT_HIST_TXN_30D perf_flag_60d perf_flag_nloss_60d perf_flag_esc_60d/style= [background = light bule];                                                                                                                                                                  
      var    perf_amt_esc_claim_60d perf_net_loss_60d perf_gmv_60d perf_cnt_txn_60d hist_gmv_30d flag_perf_60d perf_gross_loss_60 weighted_cnt
	         
			 /s=[background=light blue];                                   
    /*** performance summary ***/                       
 			
    table   (perf_flag_nloss_60d=''*perf_flag_esc_60d="" all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  weighted_cnt = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<weighted_cnt> = '% of total weighted' ) 
			  
              flag_perf_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<flag_perf_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]])			  
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss 60d'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			 
	        )     /Box="Perf" row=float RTS=25 /*misstext = '0'*/;  			
			
where flag_exc =0;
weight samplingweight;
run;


ods html close;




proc freq data = val.ebay_usar_datall_val_0806;
table seg_cd*flag_perf_60d;
where perf_gmv_60d<=0;
run;


