
/*** pull monthly raw variables ****/

options compress=yes obs=max ls=max ps=max pageno=1 errors=10 nocenter; * symbolgen mlogic mprint;
%put NOTE: PID of this session is &sysjobid..;


filename pwfile "~/tera_pwf.txt";

data _null_;
  infile pwfile obs=1 length=l;
  input @;
  input @1 line $varying1024.  l;
  call symput('tdbpass',substr(line,1,l));
  
run;


libname scratch teradata user=&sysuserid PASSWORD="&tdbpass" TDPID="hopper" DATABASE=access_views	OVERRIDE_RESP_LEN=YES DBCOMMIT=0;
libname raw './data';




/*********************** listing  monthly    May 1373   Dec 1380 ********************/
%macro pull_ebay_mth(drv = , rundt =  , startdt = , enddt = , ind= );

proc sql;
  connect to teradata as td(user=&sysuserid password="&tdbpass." tdpid="hopper" database=access_views);


create table  raw.ebay_usar_&ind as select * from connection to td
(sel 
slr_id
,min(cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) as run_date
,max(case when B2C_C2C_FLAG = 'B2C' then 2 
	          when B2C_C2C_FLAG = 'C2C' then 1
			  else 0 end) as seg

/*** GMV **************/

,count(1) as CNT_HIST_TXN_M  
,sum(ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2))) as gmv_m0  
,sum(ITEM_SOLD_QTY) as HIST_ITEM_SOLD_QTY_M0  
             
/*** CBT ***/  
             
,sum(case when CBT_IND = 1 then 1 else 0 end) as CNT_HIST_CBT_TXN_M0 
,sum(case when CBT_IND = 1 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_CBT_GMV_m0  

/*** loss ***/

,sum(CPS_NET_LOSS_USD_AMT) as net_loss_m0
,sum(case when cps_first_esc_dt >= trans_dt  and cps_claim_type_cd in (1,2) then cps_claim_amt*cast(cps_claim_exchng_rate as decimal(18,2)) else 0 end) as Amt_esc_claim_m0
,sum(case when cps_claim_open_dt >= trans_dt and cps_claim_type_cd in (1,2) then cps_claim_amt*cast(cps_claim_exchng_rate as decimal(18,2)) else 0 end) as Amt_open_claim_m0

,sum(case when cps_first_esc_dt >= trans_dt and cps_claim_type_cd in (1,2) then 1 else 0 end) as cnt_esc_claim_m0
,sum(case when cps_claim_open_dt >= trans_dt and cps_claim_type_cd in (1,2) then 1 else 0 end) as cnt_open_claim_m0


,sum(case when dedup_defect_type_flag in ('ESCALATED INR','ESCALATED SNAD')  then 1 else 0 end ) as cnt_esc_claim_test
,sum(case when dedup_defect_type_flag in ('ESCALATED INR','ESCALATED SNAD')  then cps_claim_amt*cast(cps_claim_exchng_rate as decimal(18,2)) else 0 end ) as amt_esc_claim_test
            
/*** ASP ***/  
               
/*,avg(ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)))  as asp_M  */ 

From   PRS_RESTRICTED_V.EBAY_TRANS_RLTD_EVENT BBE 

where bbe.bbe_elgb_trans_ind = 1  
      and bbe.trans_dt BETWEEN &startdt. and &enddt. 
group by 1)
; 




create table  raw.ebay_usar_mob_&ind as select * from connection to td
(
SELECT 
 a.slr_id
,cast(a.&rundt. as date) as run_dt
,USER_CRE_DATE
,cast((run_dt - CAST(u.user_cre_date as DATE) month(4)) as decimal(5,0))  as orig_mob

FROM &drv a                                                                                                                                                                   
INNER JOIN  access_views.dw_users u
ON a.slr_id = u.user_id;
);

%mend;
*%pull_ebay_mth(drv = p_riskmodeling_t.usar_drv_201606,rundt = tran_date, startdt = '2016-06-01', enddt = '2016-06-30', ind=&ind );
%pull_ebay_mth(drv = p_riskmodeling_t.usar_drv_201511,rundt = tran_date, startdt = '2015-11-01', enddt = '2015-11-30', ind=nov );





%macro summary(ind=);
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

/********************************************************************************/
/*** loss distribution ***/

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
proc freq data = raw.ebay_usar_analy_&ind ;
table msfs_mob*orig_mob;
format msfs_mob orig_mob mobfmt.;
run;
*/



PROC FORMAT;
PICTURE PCTPIC 0-high='009.999%';
PICTURE BPSPIC low-<0.1 = '9.9'(mult=1000)
               0.1-<  1 = '99' (mult=100)
				       1 -< 10 ='999'  (mult=100)
               10 - high ='9,999' (mult=100);

RUN;

ods html file = "usar_summary_&ind..xls";

/** by gmv &ind **/
proc tabulate data = raw.ebay_usar_analy_&ind missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  tot_gmv_m0 tot_net_loss_m0/style= [background = light bule];                                                                                                                                                                  
      var    net_loss_m0 gmv_m0 num_txn_m0 cnt_esc_claim_m0 /s=[background=light blue];                                   
                           
      table ( tot_gmv_m0  = '' all=[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                       
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
			  /*cnt_txn  = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<cnt_txn> = '% of total weighted' ) */
			                                   
              num_txn_m0 = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              gmv_m0  = 'GMV '*(sum = 'Total Amount'*f=comma18.0 colpctsum<gmv_m0> ='% of GMV' mean*f=comma8.0)  
              net_loss_m0  = 'Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
              cnt_esc_claim_m0 = 'ESC CLAIM' * (sum = 'Total Num'*f=comma10.0 colpctsum<cnt_esc_claim_m0>='% of esc claim' /*rowpctsum<cnt_defects> ='% of Defects'*/)  
			  /*cnt_defects ='Defect #'*(sum = 'Total Num'*f=comma10.0 colpctsum<cnt_defects>='% of defects' rowpctsum<cnt_txn> ='Defect rate' mean*f=comma8.0)   */                                                          
              /*&gross_loss  = 'Gross Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<&gross_loss> ='% of gross loss' rowpctsum<&gmv.>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) */			                            
             			                
            ) 
			  tot_net_loss_m0='Net Loss Cnt'*f=comma8.0 	
			
                                                                                                                                                                                                                     
                          /Box="gmv" row=float RTS=25 /*misstext = '0'*/;  
						  
format tot_gmv_m0 lossfmt. tot_net_loss_m0 lossf.;	
*weight &wghtvar.;					  
run;


/** by loss &ind **/

proc tabulate data = raw.ebay_usar_analy_&ind missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  tot_net_loss_m0 /style= [background = light bule];                                                                                                                                                                  
      var    net_loss_m0 gmv_m0 num_txn_m0 cnt_esc_claim_m0 /s=[background=light blue];                                   
                           
      table ( tot_net_loss_m0  = '' all=[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
			  /*cnt_txn  = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<cnt_txn> = '% of total weighted' ) */
			                                   
              num_txn_m0 = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              gmv_m0  = 'GMV '*(sum = 'Total Amount'*f=comma18.0 colpctsum<gmv_m0> ='% of GMV' mean*f=comma8.0)  
              net_loss_m0  = 'Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
              cnt_esc_claim_m0 = 'ESC CLAIM' * (sum = 'Total Num'*f=comma10.0 colpctsum<cnt_esc_claim_m0>='% of esc claim' /*rowpctsum<cnt_defects> ='% of Defects'*/)  
			  /*cnt_defects ='Defect #'*(sum = 'Total Num'*f=comma10.0 colpctsum<cnt_defects>='% of defects' rowpctsum<cnt_txn> ='Defect rate' mean*f=comma8.0)   */                                                          
              /*&gross_loss  = 'Gross Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<&gross_loss> ='% of gross loss' rowpctsum<&gmv.>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) */			                            
 		                
            )  
				
                                                                                                                                                                                                                     
                          /Box="net loss" row=float RTS=25 /*misstext = '0'*/;  
						  
format tot_net_loss_m0 lossfmt.;	
*weight &wghtvar.;					  
run;



/** by number of tran **/

proc tabulate data = raw.ebay_usar_analy_&ind missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  tot_gmv_m0 tot_num_txn_m0 seg orig_mob msfs_mob tot_net_loss_m0/style= [background = light bule];                                                                                                                                                                  
      var    net_loss_m0 gmv_m0 num_txn_m0 cnt_esc_claim_m0 /s=[background=light blue];                                   
                           
      table ( tot_num_txn_m0  = '' all=[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
			  /*cnt_txn  = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<cnt_txn> = '% of total weighted' ) */
			                                   
              num_txn_m0 = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              gmv_m0  = 'GMV '*(sum = 'Total Amount'*f=comma18.0 colpctsum<gmv_m0> ='% of GMV' mean*f=comma8.0)  
              net_loss_m0  = 'Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
              cnt_esc_claim_m0 = 'ESC CLAIM' * (sum = 'Total Num'*f=comma10.0 colpctsum<cnt_esc_claim_m0>='% of esc claim' /*rowpctsum<cnt_defects> ='% of Defects'*/)  
			  /*cnt_defects ='Defect #'*(sum = 'Total Num'*f=comma10.0 colpctsum<cnt_defects>='% of defects' rowpctsum<cnt_txn> ='Defect rate' mean*f=comma8.0)   */                                                          
              /*&gross_loss  = 'Gross Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<&gross_loss> ='% of gross loss' rowpctsum<&gmv.>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) */			                            
            
			                
            )  
 tot_net_loss_m0='Net Loss Cnt'*f=comma8.0 			
                                                                                                                                                                                                                     
                          /Box="number of trans" row=float RTS=25 /*misstext = '0'*/;  
						  
format tot_num_txn_m0 txnfmt. tot_net_loss_m0 lossf.;	
*weight &wghtvar.;					  
run;

/** by mob **/
proc tabulate data = raw.ebay_usar_analy_&ind missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  tot_gmv_m0 tot_num_txn_m0 seg orig_mob msfs_mob tot_net_loss_m0/style= [background = light bule];                                                                                                                                                                  
      var    net_loss_m0 gmv_m0 num_txn_m0 cnt_esc_claim_m0 /s=[background=light blue];                                   
                           
      table ( orig_mob  = '' all=[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
			  /*cnt_txn  = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<cnt_txn> = '% of total weighted' ) */
			                                   
              num_txn_m0 = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              gmv_m0  = 'GMV '*(sum = 'Total Amount'*f=comma18.0 colpctsum<gmv_m0> ='% of GMV' mean*f=comma8.0)  
              net_loss_m0  = 'Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
              cnt_esc_claim_m0 = 'ESC CLAIM' * (sum = 'Total Num'*f=comma10.0 colpctsum<cnt_esc_claim_m0>='% of esc claim' /*rowpctsum<cnt_defects> ='% of Defects'*/)  
			  /*cnt_defects ='Defect #'*(sum = 'Total Num'*f=comma10.0 colpctsum<cnt_defects>='% of defects' rowpctsum<cnt_txn> ='Defect rate' mean*f=comma8.0)   */                                                          
              /*&gross_loss  = 'Gross Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<&gross_loss> ='% of gross loss' rowpctsum<&gmv.>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) */			                            
            
			                
            )   
 tot_net_loss_m0='Net Loss Cnt'*f=comma8.0 			
                                                                                                                                                                                                                     
                          /Box="Orig Mob" row=float RTS=25 /*misstext = '0'*/;  
						  
format orig_mob mobfmt. tot_net_loss_m0 lossf.;	
					  
run;

proc tabulate data = raw.ebay_usar_analy_&ind missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  tot_gmv_m0 tot_num_txn_m0 seg orig_mob msfs_mob tot_net_loss_m0/style= [background = light bule];                                                                                                                                                                  
      var    net_loss_m0 gmv_m0 num_txn_m0 cnt_esc_claim_m0 /s=[background=light blue];                                   
                           
      table ( msfs_mob  = '' all=[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
			  /*cnt_txn  = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<cnt_txn> = '% of total weighted' ) */
			                                   
              num_txn_m0 = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              gmv_m0  = 'GMV '*(sum = 'Total Amount'*f=comma18.0 colpctsum<gmv_m0> ='% of GMV' mean*f=comma8.0)  
              net_loss_m0  = 'Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
              cnt_esc_claim_m0 = 'ESC CLAIM' * (sum = 'Total Num'*f=comma10.0 colpctsum<cnt_esc_claim_m0>='% of esc claim' /*rowpctsum<cnt_defects> ='% of Defects'*/)  
			  /*cnt_defects ='Defect #'*(sum = 'Total Num'*f=comma10.0 colpctsum<cnt_defects>='% of defects' rowpctsum<cnt_txn> ='Defect rate' mean*f=comma8.0)   */                                                          
              /*&gross_loss  = 'Gross Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<&gross_loss> ='% of gross loss' rowpctsum<&gmv.>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) */			                            
            
			                
            ) 
 tot_net_loss_m0='Net Loss Cnt'*f=comma8.0 			
                                                                                                                                                                                                                     
                          /Box="MSFS MOB" row=float RTS=25 /*misstext = '0'*/;  
						  
format msfs_mob mobfmt. tot_net_loss_m0 lossf.;	
					  
run;

/**** by seg ***/
proc tabulate data = raw.ebay_usar_analy_&ind missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  tot_gmv_m0 tot_num_txn_m0 seg orig_mob msfs_mob seg tot_net_loss_m0/style= [background = light bule];                                                                                                                                                                  
      var    net_loss_m0 gmv_m0 num_txn_m0 cnt_esc_claim_m0 /s=[background=light blue];                                   
                           
      table ( seg  = '' all=[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
			  /*cnt_txn  = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<cnt_txn> = '% of total weighted' ) */
			                                   
              num_txn_m0 = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              gmv_m0  = 'GMV '*(sum = 'Total Amount'*f=comma18.0 colpctsum<gmv_m0> ='% of GMV' mean*f=comma8.0)  
              net_loss_m0  = 'Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
              cnt_esc_claim_m0 = 'ESC CLAIM' * (sum = 'Total Num'*f=comma10.0 colpctsum<cnt_esc_claim_m0>='% of esc claim' /*rowpctsum<cnt_defects> ='% of Defects'*/)  
			  /*cnt_defects ='Defect #'*(sum = 'Total Num'*f=comma10.0 colpctsum<cnt_defects>='% of defects' rowpctsum<cnt_txn> ='Defect rate' mean*f=comma8.0)   */                                                          
              /*&gross_loss  = 'Gross Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<&gross_loss> ='% of gross loss' rowpctsum<&gmv.>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) */			                            
            
			                
            )   
 tot_net_loss_m0='Net Loss Cnt'*f=comma8.0 			
                                                                                                                                                                                                                     
                          /Box="Seg" row=float RTS=25 /*misstext = '0'*/;  
						  
format msfs_mob mobfmt. tot_net_loss_m0 lossf.;	
					  
run;


ods html close;

%mend;

%summary(ind = nov);


endsas;

 



endsas; 
From   &drv  a
left join PRS_RESTRICTED_V.EBAY_TRANS_RLTD_EVENT BBE on a.slr_id = bbe.slr_id
INNER JOIN SYS_CALENDAR.Calendar cal on trans_dt = calendar_date

where bbe.bbe_elgb_trans_ind = 1  
      and bbe.trans_dt BETWEEN &startdt. and &enddt.
      and month_of_calendar BETWEEN &run_mthid - 12 and &run_mthid  	  
group by 1,2,3
order by 1,2,3);

