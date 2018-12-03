
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


*libname scratch teradata user=&sysuserid PASSWORD="&tdbpass" TDPID="hopper" DATABASE=access_views	OVERRIDE_RESP_LEN=YES DBCOMMIT=0;
libname raw './data';


%macro pull_ebay_perf(drv = , rundt =  , startdt = , enddt = , ind= );
/******************************************************************************/
/** Acct level, GMV, ISSUE, CLAIM,Gross Loss and Net loss , forced reversal****/ 


proc sql;
  connect to teradata as td(user=&sysuserid password="&tdbpass." tdpid="hopper" database=access_views);
%macro dd;
create table raw.ebay_usar_perf_trans_&ind as select * from connection to td

      (	 
          select a.slr_id
                ,cast(tran_date as date) as run_dt
				,tran_date as run_date
              
		        
				/*** trigger transactions are included in the hist but excluded from Perf ***/
                /*** GMV  Hist**************/
				,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '1'  day and run_date then 1 else 0 end) as CNT_HIST_TXN_1D  
                ,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date then 1 else 0 end) as CNT_HIST_TXN_30D  
                ,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '90'  day and run_date then 1 else 0 end) as CNT_HIST_TXN_90D 
                ,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '180'  day and run_date then 1 else 0 end) as CNT_HIST_TXN_180D  
                ,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '360'  day and run_date then 1 else 0 end) as CNT_HIST_TXN_360D  
				 
			    ,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '1'  day and run_date then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_GMV_1D
                ,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30' day and run_date then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_GMV_30D
                ,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '90' day and run_date then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_GMV_90D   
			    ,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '180' day and run_date then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_GMV_180D
                ,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '360' day and run_date then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_GMV_360D   				
               

                /*** GMV Perf ***************/
				,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date + interval '10' second  and run_date + interval '30'  day  then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as perf_GMV_30D  
                ,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date + interval '10' second  and run_date + interval '60'  day  then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as perf_GMV_60D  
                ,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date + interval '10' second  and run_date + interval '90'  day  then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as perf_GMV_90D  
                                                                                                                                  
                ,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date + interval '10' second  and run_date + interval '30'  day then 1 else 0 end) as perf_CNT_TXN_30D  
                ,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date + interval '10' second  and run_date + interval '60'  day then 1 else 0 end) as perf_CNT_TXN_60D 
                ,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date + interval '10' second  and run_date + interval '90'  day then 1 else 0 end) as perf_CNT_TXN_90D  
               

				/********** QA using Date ***************/
				,sum(case when bbe.TRANS_DT between run_dt -90 and run_dt then 1 else 0 end) as CNT_HIST_TXN_90D_QA  
				,sum(case when trans_dt <= run_dt and trans_dt  >=run_date - interval '90' day  then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else	0 end	) as AMT_HIST_GMV_90d_QA  
                ,sum(case when bbe.TRANS_DT between (run_dt +1 ) and run_dt+90 then 1 else 0 end) as perf_TXN_90D_QA  
				

				/*** Perf Net Loss, Claims ***********/  
				
				,sum(case	when trans_dt > run_dt 	and	trans_dt  <=run_date + interval '30' day then CPS_NET_LOSS_USD_AMT else	0 end	) as PERF_net_loss_30d
				,sum(case	when trans_dt > run_dt 	and	trans_dt  <=run_date + interval '60' day then CPS_NET_LOSS_USD_AMT else	0 end	) as PERF_net_loss_60d
				,sum(case	when trans_dt > run_dt 	and	trans_dt  <=run_date + interval '90' day then CPS_NET_LOSS_USD_AMT else	0 end	) as PERF_net_loss_90d
				
				
                ,sum(case when cps_first_esc_dt  between run_dt +1 and   run_dt +30 and cps_claim_type_cd in (1,2) then cps_claim_amt*cast(cps_claim_exchng_rate as decimal(18,2)) else 0 end) as perf_amt_esc_claim_30d
                ,sum(case when cps_first_esc_dt  between run_dt +1 and   run_dt +30 and cps_claim_type_cd in (1,2) then 1 else 0 end) as perf_cnt_esc_claim_30d

				,sum(case when cps_first_esc_dt  between run_dt +1 and   run_dt +60 and cps_claim_type_cd in (1,2) then cps_claim_amt*cast(cps_claim_exchng_rate as decimal(18,2)) else 0 end) as perf_amt_esc_claim_60d
                ,sum(case when cps_first_esc_dt  between run_dt +1 and   run_dt +60 and cps_claim_type_cd in (1,2) then 1 else 0 end) as perf_cnt_esc_claim_60d
				
				,sum(case when cps_first_esc_dt  between run_dt +1 and   run_dt +90 and cps_claim_type_cd in (1,2) then cps_claim_amt*cast(cps_claim_exchng_rate as decimal(18,2)) else 0 end) as perf_amt_esc_claim_90d
                ,sum(case when cps_first_esc_dt  between run_dt +1 and   run_dt +90 and cps_claim_type_cd in (1,2) then 1 else 0 end) as perf_cnt_esc_claim_90d
				
				,sum(case when cps_claim_open_dt  between run_dt +1 and   run_dt +30 and cps_claim_type_cd in (1,2) then cps_claim_amt*cast(cps_claim_exchng_rate as decimal(18,2)) else 0 end) as perf_amt_open_claim_30d
                ,sum(case when cps_claim_open_dt  between run_dt +1 and   run_dt +30 and cps_claim_type_cd in (1,2) then 1 else 0 end) as perf_cnt_open_claim_30d

				,sum(case when cps_claim_open_dt  between run_dt +1 and   run_dt +60 and cps_claim_type_cd in (1,2) then cps_claim_amt*cast(cps_claim_exchng_rate as decimal(18,2)) else 0 end) as perf_amt_open_claim_60d
                ,sum(case when cps_claim_open_dt  between run_dt +1 and   run_dt +60 and cps_claim_type_cd in (1,2) then 1 else 0 end) as perf_cnt_open_claim_60d
		
                ,sum(case when cps_claim_open_dt  between run_dt +1 and   run_dt +90 and cps_claim_type_cd in (1,2) then cps_claim_amt*cast(cps_claim_exchng_rate as decimal(18,2)) else 0 end) as perf_amt_open_claim_90d
                ,sum(case when cps_claim_open_dt  between run_dt +1 and   run_dt +90 and cps_claim_type_cd in (1,2) then 1 else 0 end) as perf_cnt_open_claim_90d               
		      
 			  
         from  &drv a
         left join PRS_RESTRICTED_V.EBAY_TRANS_RLTD_EVENT BBE on a.slr_id = bbe.slr_id
         
         where bbe.bbe_elgb_trans_ind = 1  
               and bbe.trans_dt BETWEEN '2015-01-01' AND '2016-10-30'   /* fixed date for test - replace with macro var for day 450 */
         group by 1,2,3
         order by 1,2,3
     );



create table raw.ebay_usar_perf_gloss_&ind as select * from connection to td
(
sel	
a.slr_id
,cast(tran_date as date) as run_dt
,tran_date as run_date

,sum(case	when EBAY_PYT_DT > run_dt 	and	EBAY_PYT_DT  <=run_dt + interval '30' day then EBAY_PYT_USD_AMT else	0 end	) as PERF_EBAY_PYT_USD_AMT_30d
,sum(case	when EBAY_PYT_DT > run_dt 	and	EBAY_PYT_DT  <=run_dt + interval '60' day then EBAY_PYT_USD_AMT else	0 end	) as PERF_EBAY_PYT_USD_AMT_60d
,sum(case	when EBAY_PYT_DT > run_dt 	and	EBAY_PYT_DT  <=run_dt + interval '90' day then EBAY_PYT_USD_AMT else	0 end	) as PERF_EBAY_PYT_USD_AMT_90d


,sum(case	when SLR_APPL_PYT_DT > run_dt 	and	SLR_APPL_PYT_DT  <=run_dt + interval '30' day then SLR_APPL_PYT_USD_AMT else	0 end	) as PERF_SLR_APPL_PYT_USD_AMT_30d
,sum(case	when SLR_APPL_PYT_DT > run_dt 	and	SLR_APPL_PYT_DT  <=run_dt + interval '60' day then SLR_APPL_PYT_USD_AMT else	0 end	) as PERF_SLR_APPL_PYT_USD_AMT_60d
,sum(case	when SLR_APPL_PYT_DT > run_dt 	and	SLR_APPL_PYT_DT  <=run_dt + interval '90' day then SLR_APPL_PYT_USD_AMT else	0 end	) as PERF_SLR_APPL_PYT_USD_AMT_90d


,sum(case	when ebay_pyt_dt > run_dt 	and	ebay_pyt_dt  <=run_dt + interval '30' day then BYR_APPL_PYT_USD_AMT else	0 end	) as PERF_BYR_APPL_PYT_USD_AMT_30d
,sum(case	when ebay_pyt_dt > run_dt 	and	ebay_pyt_dt  <=run_dt + interval '60' day then BYR_APPL_PYT_USD_AMT else	0 end	) as PERF_BYR_APPL_PYT_USD_AMT_60d
,sum(case	when ebay_pyt_dt > run_dt 	and	ebay_pyt_dt  <=run_dt + interval '90' day then BYR_APPL_PYT_USD_AMT else	0 end	) as PERF_BYR_APPL_PYT_USD_AMT_90d



,sum(case	when FRCD_RVRSL_DT > run_dt 	and	FRCD_RVRSL_DT  <=run_dt + interval '30' day then FRCD_RVRSL_USD_AMT else	0 end	) as PERF_FRCD_RVRSL_USD_AMT_30d
,sum(case	when FRCD_RVRSL_DT > run_dt 	and	FRCD_RVRSL_DT  <=run_dt + interval '60' day then FRCD_RVRSL_USD_AMT else	0 end	) as PERF_FRCD_RVRSL_USD_AMT_60d
,sum(case	when FRCD_RVRSL_DT > run_dt 	and	FRCD_RVRSL_DT  <=run_dt + interval '90' day then FRCD_RVRSL_USD_AMT else	0 end	) as PERF_FRCD_RVRSL_USD_AMT_90d


,PERF_EBAY_PYT_USD_AMT_30d+PERF_SLR_APPL_PYT_USD_AMT_30d+PERF_BYR_APPL_PYT_USD_AMT_30d as perf_gross_loss_30
,PERF_EBAY_PYT_USD_AMT_60d+PERF_SLR_APPL_PYT_USD_AMT_60d+PERF_BYR_APPL_PYT_USD_AMT_60d as perf_gross_loss_60
,PERF_EBAY_PYT_USD_AMT_90d+PERF_SLR_APPL_PYT_USD_AMT_90d+PERF_BYR_APPL_PYT_USD_AMT_90d as perf_gross_loss_90


,perf_gross_loss_30+PERF_FRCD_RVRSL_USD_AMT_30d as perf_total_gloss_30
,perf_gross_loss_60+PERF_FRCD_RVRSL_USD_AMT_60d as perf_total_gloss_60
,perf_gross_loss_90+PERF_FRCD_RVRSL_USD_AMT_90d as perf_total_gloss_90


,sum(case	when ebay_pyt_dt between run_dt+1 and run_dt + 30 	and	EBAY_PYT_USD_AMT > 0  then EBAY_PYT_USD_AMT  
			 when  slr_appl_pyt_dt between run_dt+1 and run_dt + 30  	and	slr_appl_PYT_USD_AMT > 0 then slr_appl_pyt_usd_amt 
               when  ebay_pyt_dt between run_dt+1 and run_dt + 30  	and	byr_appl_PYT_USD_AMT > 0  then byr_appl_PYT_USD_AMT
                  else 0 end) as gross_loss_30d_mike                                    

,sum(case	when ebay_pyt_dt between run_dt - 30 and run_dt and	EBAY_PYT_USD_AMT > 0  then EBAY_PYT_USD_AMT  
			 when  slr_appl_pyt_dt between run_dt - 30  and run_dt 	and	slr_appl_PYT_USD_AMT > 0 then slr_appl_pyt_usd_amt 
               when  ebay_pyt_dt between run_dt - 30 and run_dt   	and	byr_appl_PYT_USD_AMT > 0  then byr_appl_PYT_USD_AMT
                  else 0 end) as hist_gross_loss_30d    				  
				  

			  
From  &drv.  a
left join PRS_RESTRICTED_V.EBAY_TRANS_RLTD_EVENT BBE 
	on	a.slr_id = bbe.slr_id
left join ACCESS_VIEWS.RSLTN_CPS c 
	on	bbe.slr_id=c.slr_id AND bbe.item_id = c.item_id AND bbe.trans_id = c.tran_id
where	bbe.bbe_elgb_trans_ind = 1  
      and bbe.trans_dt BETWEEN run_dt - 90 and	run_dt + 90 
      and CK_TRAN_CRE_DT between run_dt - 90 and	run_dt + 90
	  
group by 1,2,3
order by 1,2,3
) ;
 
 
/**** issue  ****/
create table  raw.ebay_usar_perf_issue_&ind. as select * from connection to td
(sel 
a.slr_id
,cast(tran_date as date) as run_dt
,tran_date  as run_date
,max(case when src_cre_dt > run_dt and src_cre_dt <= run_dt + interval '30' day and scenario_id IN (12, 34, 122, 123, 172, 173, 181, 188, 216, 217, 218, 233, 305, 419) then 1 else 0 end) as perf_flag_res_30d
,max(case when src_cre_dt >=run_dt - interval '30' day and src_cre_dt <= run_dt and scenario_id IN (12, 34, 122, 123, 172, 173, 181, 188, 216, 217, 218, 233, 305, 419) then 1 else 0 end) as hist_flag_res_30d

from  &drv. a 
LEFT JOIN ACCESS_VIEWS.DW_USER_ISSUE issue 
ON  a.slr_id = issue.user_id AND src_cre_dt between run_dt - interval '30' day and run_dt +interval '30' day
group by 1,2,3
order by 1,2,3
);  


Create table  raw.ebay_usar_status_&ind. as select * from connection to td
(sel 
a.slr_id
,cast(tran_date as date) as run_dt
,tran_date as run_date

,sum(case when b.change_time BETWEEN run_date + interval '10' second and run_date + interval '30' day and to_state = 0 then 1 else 0 end) as perf_cnt_suspend_30d
,sum(case when b.change_time BETWEEN run_date - interval '30' day and run_date and to_state = 0 then 1 else 0 end) as hist_cnt_suspend_30d
  
from &drv. a
left join ACCESS_VIEWS.DW_USER_STATE_HISTORY b on a.slr_id = b.id

WHERE b.change_time between run_date - interval '30' day and run_date +interval '30' day  
group by 1,2,3
order by 1,2,3
); 

create table raw.ebay_usar_perf_status_&ind. as select * from connection to td
(
sel	 
a.slr_id
,tran_date as run_date
,to_state
,user_sts_code
,case when to_state = 0 then 1 else 0 end as flag_susp_hist
,case when user_sts_code = 0 then 1 else 0 end as flag_susp_cur 

from &drv. a
left join ACCESS_VIEWS.DW_USER_STATE_HISTORY b on a.slr_id = b.id
left join access_views.dw_users c on a.slr_id = c.user_id
WHERE b.change_time < run_date  
qualify rank() over(partition by slr_id order by change_time desc) = 1
);

%mend;

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


quit;

%mend;

*%pull_ebay_perf(drv = p_riskmodeling_t.usar_drv_201606, rundt = tran_date , startdt = '2015-01-01', enddt = '2016-10-30', ind= jun );
*%pull_ebay_perf(drv = p_ebay_eg_t.usar_drv_201606, rundt = tran_date , startdt = '2015-01-01', enddt = '2016-10-30', ind= jun );  /** mz driver **/

%pull_ebay_perf(drv = p_riskmodeling_t.usar_drv_1, rundt = tran_date , startdt = '2015-01-01', enddt = '2016-10-30', ind= drv );
endsas;
option nolabel;

%include '~/my_macro.sas';
%check_mean(datin = raw.ebay_usar_perf_trans_jun);    /** 1,923,492 **/
%check_mean(datin = raw.ebay_usar_perf_gloss_jun);
%check_mean(datin =raw.ebay_usar_status_jun);



%let ind = jun;
proc freq data = raw.ebay_usar_perf_status_&ind.;
table flag_susp_hist*flag_susp_cur;
run;


	 
endsas;
/************************************************************************/	 
	 
	     /** Feedback **/
                
                ,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (BYR_FDBK_RCVD_TM - time '00:00:00' hour to second) ) between run_date - interval '3'   day and run_date and (ORGNL_FDBK_OVRL_RTG_ID in(1,2,3) or BYR_FDBK_OVRL_RTNG_ID in (1,2,3) ) then 1 else 0 end) as CNT_SLR_TOT_FDBK_3D  
                ,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (BYR_FDBK_RCVD_TM - time '00:00:00' hour to second) ) between run_date - interval '7'   day and run_date and (ORGNL_FDBK_OVRL_RTG_ID in(1,2,3) or BYR_FDBK_OVRL_RTNG_ID in (1,2,3) ) then 1 else 0 end) as CNT_SLR_TOT_FDBK_7D  
                ,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (BYR_FDBK_RCVD_TM - time '00:00:00' hour to second) ) between run_date - interval '60'  day and run_date and (ORGNL_FDBK_OVRL_RTG_ID in(1,2,3) or BYR_FDBK_OVRL_RTNG_ID in (1,2,3) ) then 1 else 0 end) as CNT_SLR_TOT_FDBK_60D 
                ,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (BYR_FDBK_RCVD_TM - time '00:00:00' hour to second) ) between run_date - interval '360' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID in(1,2,3) or BYR_FDBK_OVRL_RTNG_ID in (1,2,3) ) then 1 else 0 end) as CNT_SLR_TOT_FDBK_360D    
                ,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (BYR_FDBK_RCVD_TM - time '00:00:00' hour to second) ) between run_date - interval '3'   day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 1 or BYR_FDBK_OVRL_RTNG_ID = 1) then 1 else 0 end) as CNT_SLR_PSTV_FDBK_3D  
                ,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (BYR_FDBK_RCVD_TM - time '00:00:00' hour to second) ) between run_date - interval '60'  day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 1 or BYR_FDBK_OVRL_RTNG_ID = 1) then 1 else 0 end) as CNT_SLR_PSTV_FDBK_60D 
                ,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (BYR_FDBK_RCVD_TM - time '00:00:00' hour to second) ) between run_date - interval '360' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 1 or BYR_FDBK_OVRL_RTNG_ID = 1) then 1 else 0 end) as CNT_SLR_PSTV_FDBK_360D 
                ,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (BYR_FDBK_RCVD_TM - time '00:00:00' hour to second) ) between run_date - interval '7'   day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 2 or BYR_FDBK_OVRL_RTNG_ID = 2) then 1 else 0 end) as CNT_SLR_NGTV_FDBK_7D 
                ,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (BYR_FDBK_RCVD_TM - time '00:00:00' hour to second) ) between run_date - interval '60'  day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 2 or BYR_FDBK_OVRL_RTNG_ID = 2) then 1 else 0 end) as CNT_SLR_NGTV_FDBK_60D 
         
				,sum(case when bbe.BYR_FDBK_RCVD_DT between case_dt -60 and case_dt and (ORGNL_FDBK_OVRL_RTG_ID = 1 or BYR_FDBK_OVRL_RTNG_ID = 1) then 1 else 0 end) as CNT_SLR_PSTV_FDBK_60D_bbedt
         

