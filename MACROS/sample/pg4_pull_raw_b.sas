options compress=yes obs=max ls=max ps=max pageno=1 errors=10 nocenter; * symbolgen mlogic mprint;
%put NOTE: PID of this session is &sysjobid..;


filename pwfile "~/tera_pwf.txt";

data _null_;
  infile pwfile obs=1 length=l;
  input @;
  input @1 line $varying1024.  l;
  call symput('tdbpass',substr(line,1,l));
  
run;


libname scratch teradata user=&sysuserid PASSWORD="&tdbpass" TDPID="mz2" DATABASE=access_views	OVERRIDE_RESP_LEN=YES DBCOMMIT=0;


libname raw  '/ebaysr/projects/arus/data';


%macro ebay_usar_var360(drv= , rundt = ,ind= );

proc sql;
  connect to teradata as td(user=&sysuserid password="&tdbpass." tdpid="hopper" database=access_views);

%include "risk_cat_daily.sas";  

%macro dd;
create table  raw.ebay_usar_tran_&ind. as select * from connection to td
(sel 
a.slr_id
,&rundt. as run_date  
  
/*** GMV **************/
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '60'  day and run_date then 1 else 0 end) as CNT_HIST_TXN_60D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '90'  day and run_date then 1 else 0 end) as CNT_HIST_TXN_90D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '180'  day and run_date then 1 else 0 end) as CNT_HIST_TXN_180D 
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '360' day and run_date then 1 else 0 end) as CNT_HIST_TXN_360D         

,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '60'  day and run_date then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_GMV_60D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '90'  day and run_date then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_GMV_90D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '180'  day and run_date then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_GMV_180D   
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '360' day and run_date then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_GMV_360D   


,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '60'  day and run_date then ITEM_SOLD_QTY  else 0 end) as HIST_ITEM_SOLD_QTY_60D 
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '90'  day and run_date then ITEM_SOLD_QTY  else 0 end) as HIST_ITEM_SOLD_QTY_90D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '180'  day and run_date then ITEM_SOLD_QTY  else 0 end) as HIST_ITEM_SOLD_QTY_180D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '360' day and run_date then ITEM_SOLD_QTY  else 0 end) as HIST_ITEM_SOLD_QTY_360D  


/*** listing ***/

,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '60'  day and run_date and auct_type_code in (7,9) then 1 else 0 end ) as CNT_HIST_FP_TXN_60D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '90'  day and run_date and auct_type_code in (7,9) then 1 else 0 end ) as CNT_HIST_FP_TXN_90D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '180'  day and run_date and auct_type_code in (7,9) then 1 else 0 end ) as CNT_HIST_FP_TXN_180D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '360'  day and run_date and auct_type_code in (7,9) then 1 else 0 end ) as CNT_HIST_FP_TXN_360D
                                             
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '60'  day and run_date and auct_type_code in (7,9)  then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end ) as AMT_HIST_FP_TXN_60D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '90'  day and run_date and auct_type_code in (7,9)  then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end ) as AMT_HIST_FP_TXN_90D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '180'  day and run_date and auct_type_code in (7,9)  then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end ) as AMT_HIST_FP_TXN_180D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '360'  day and run_date and auct_type_code in (7,9) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end ) as AMT_HIST_FP_TXN_360D
                                             
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '60'  day and run_date and auct_type_code in  (1,2) and bin_price_lc_amt>0  then 1 else 0 end ) as CNT_HIST_BIN_TXN_60D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '90'  day and run_date and auct_type_code in  (1,2) and bin_price_lc_amt>0  then 1 else 0 end ) as CNT_HIST_BIN_TXN_90D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '180'  day and run_date and auct_type_code in  (1,2) and bin_price_lc_amt>0  then 1 else 0 end ) as CNT_HIST_BIN_TXN_180D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '360'  day and run_date and auct_type_code in (1,2) and bin_price_lc_amt>0  then 1 else 0 end ) as CNT_HIST_BIN_TXN_360D
                                                                 
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '60'  day and run_date and auct_type_code in  (1,2) and bin_price_lc_amt>0  then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end ) as AMT_HIST_BIN_TXN_60D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '90'  day and run_date and auct_type_code in  (1,2) and bin_price_lc_amt>0  then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end ) as AMT_HIST_BIN_TXN_90D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '180'  day and run_date and auct_type_code in  (1,2) and bin_price_lc_amt>0  then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end ) as AMT_HIST_BIN_TXN_180D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '360'  day and run_date and auct_type_code in (1,2) and bin_price_lc_amt>0  then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end ) as AMT_HIST_BIN_TXN_360D 
 
 
/*** Defects  CNT **********/

/*** CBT ***/
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '60'   day and run_date and CBT_IND = 1 then 1 else 0 end) as CNT_HIST_CBT_TXN_60D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '90'   day and run_date and CBT_IND = 1 then 1 else 0 end) as CNT_HIST_CBT_TXN_90D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '180'   day and run_date and CBT_IND = 1 then 1 else 0 end) as CNT_HIST_CBT_TXN_180D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '360'  day and run_date and CBT_IND = 1 then 1 else 0 end) as CNT_HIST_CBT_TXN_360D  

,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '60'   day and run_date and CBT_IND = 1 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_CBT_GMV_60D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '90'   day and run_date and CBT_IND = 1 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_CBT_GMV_90D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '180'   day and run_date and CBT_IND = 1 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_CBT_GMV_180D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '360'  day and run_date and CBT_IND = 1 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_CBT_GMV_360D  

/*** ASP ***/
,avg(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '60'   day and run_date then ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) end) as asp_60D  
,avg(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '90'   day and run_date then ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) end) as asp_90D  
,avg(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '180'   day and run_date then ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) end) as asp_180D  
,avg(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '360'  day and run_date then ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) end) as asp_360D

/*** high ASP tran change ***/
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '60'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then 1 else 0 end) as CNT_HASP_TXN_60D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '90'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then 1 else 0 end) as CNT_HASP_TXN_90D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '180'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then 1 else 0 end) as CNT_HASP_TXN_180D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '360'  day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then 1 else 0 end) as CNT_HASP_TXN_360D  

,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '60'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_GMV_60D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '90'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_GMV_90D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '180'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_GMV_180D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '360'  day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_GMV_360D  

,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '60'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then 1 else 0 end) as CNT_HASP_gt2_TXN_60D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '90'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then 1 else 0 end) as CNT_HASP_gt2_TXN_90D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '180'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then 1 else 0 end) as CNT_HASP_gt2_TXN_180D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '360'  day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then 1 else 0 end) as CNT_HASP_gt2_TXN_360D  

,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '60'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_gt2_GMV_60D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '90'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_gt2_GMV_90D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '180'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_gt2_GMV_180D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '360'  day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_gt2_GMV_360D  


/** Feedback **/
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '60' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID in(1,2,3) or BYR_FDBK_OVRL_RTNG_ID in (1,2,3) ) then 1 else 0 end) as CNT_SLR_TOT_FDBK_60D  
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '90' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID in(1,2,3) or BYR_FDBK_OVRL_RTNG_ID in (1,2,3) ) then 1 else 0 end) as CNT_SLR_TOT_FDBK_90D  
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '180' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID in(1,2,3) or BYR_FDBK_OVRL_RTNG_ID in (1,2,3) ) then 1 else 0 end) as CNT_SLR_TOT_FDBK_180D  
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '360' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID in(1,2,3) or BYR_FDBK_OVRL_RTNG_ID in (1,2,3) ) then 1 else 0 end) as CNT_SLR_TOT_FDBK_360D  

,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '60' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 1 or BYR_FDBK_OVRL_RTNG_ID = 1) then 1 else 0 end) as CNT_SLR_PSTV_FDBK_60D  
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '90' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 1 or BYR_FDBK_OVRL_RTNG_ID = 1) then 1 else 0 end) as CNT_SLR_PSTV_FDBK_90D  
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '180' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 1 or BYR_FDBK_OVRL_RTNG_ID = 1) then 1 else 0 end) as CNT_SLR_PSTV_FDBK_180D 
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '360' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 1 or BYR_FDBK_OVRL_RTNG_ID = 1) then 1 else 0 end) as CNT_SLR_PSTV_FDBK_360D 

,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '60' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 2 or BYR_FDBK_OVRL_RTNG_ID = 2) then 1 else 0 end) as CNT_SLR_NGTV_FDBK_60D  
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '90' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 2 or BYR_FDBK_OVRL_RTNG_ID = 2) then 1 else 0 end) as CNT_SLR_NGTV_FDBK_90D  
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '180' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 2 or BYR_FDBK_OVRL_RTNG_ID = 2) then 1 else 0 end) as CNT_SLR_NGTV_FDBK_180D 
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '360' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 2 or BYR_FDBK_OVRL_RTNG_ID = 2) then 1 else 0 end) as CNT_SLR_NGTV_FDBK_360D 

,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '60' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 3 or BYR_FDBK_OVRL_RTNG_ID = 3) then 1 else 0 end) as CNT_SLR_NTRL_FDBK_60D  
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '90' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 3 or BYR_FDBK_OVRL_RTNG_ID = 3) then 1 else 0 end) as CNT_SLR_NTRL_FDBK_90D  
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '180' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 3 or BYR_FDBK_OVRL_RTNG_ID = 3) then 1 else 0 end) as CNT_SLR_NTRL_FDBK_180D 
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '360' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 3 or BYR_FDBK_OVRL_RTNG_ID = 3) then 1 else 0 end) as CNT_SLR_NTRL_FDBK_360D 

/*** Rating IAD,COM,SHP CHRG and ST ***/
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '60' day and run_date and ORGNL_ITEM_AS_DSCRBD_RTG_NUM > 0 then ORGNL_ITEM_AS_DSCRBD_RTG_NUM end) as AVE_IAD_DSR_60D 
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '90' day and run_date and ORGNL_ITEM_AS_DSCRBD_RTG_NUM > 0 then ORGNL_ITEM_AS_DSCRBD_RTG_NUM end) as AVE_IAD_DSR_90D  
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '180' day and run_date and ORGNL_ITEM_AS_DSCRBD_RTG_NUM > 0 then ORGNL_ITEM_AS_DSCRBD_RTG_NUM end) as AVE_IAD_DSR_180D  
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '360' day and run_date and ORGNL_ITEM_AS_DSCRBD_RTG_NUM > 0 then ORGNL_ITEM_AS_DSCRBD_RTG_NUM end) as AVE_IAD_DSR_360D  

,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '60' day and run_date and ORGNL_COM_RTG_VAL_NUM > 0 then ORGNL_COM_RTG_VAL_NUM end) as AVE_COM_DSR_60D  
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '90' day and run_date and ORGNL_COM_RTG_VAL_NUM > 0 then ORGNL_COM_RTG_VAL_NUM end) as AVE_COM_DSR_90D  
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '180' day and run_date and ORGNL_COM_RTG_VAL_NUM > 0 then ORGNL_COM_RTG_VAL_NUM end) as AVE_COM_DSR_180D  
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '360' day and run_date and ORGNL_COM_RTG_VAL_NUM > 0 then ORGNL_COM_RTG_VAL_NUM end) as AVE_COM_DSR_360D  

,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '60' day and run_date and ORGNL_SHPNG_TM_RTG_VAL_NUM > 0 then ORGNL_SHPNG_TM_RTG_VAL_NUM end) as AVE_ST_DSR_60D 
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '90' day and run_date and ORGNL_SHPNG_TM_RTG_VAL_NUM > 0 then ORGNL_SHPNG_TM_RTG_VAL_NUM end) as AVE_ST_DSR_90D  
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '180' day and run_date and ORGNL_SHPNG_TM_RTG_VAL_NUM > 0 then ORGNL_SHPNG_TM_RTG_VAL_NUM end) as AVE_ST_DSR_180D  
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '360' day and run_date and ORGNL_SHPNG_TM_RTG_VAL_NUM > 0 then ORGNL_SHPNG_TM_RTG_VAL_NUM end) as AVE_ST_DSR_360D  

,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '60' day and run_date and ORGNL_SHPNG_CHRG_RTG_VAL_NUM > 0 then ORGNL_SHPNG_CHRG_RTG_VAL_NUM end) as AVE_SHPNG_CHRG_DSR_60D  
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '90' day and run_date and ORGNL_SHPNG_CHRG_RTG_VAL_NUM > 0 then ORGNL_SHPNG_CHRG_RTG_VAL_NUM end) as AVE_SHPNG_CHRG_DSR_90D  
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '180' day and run_date and ORGNL_SHPNG_CHRG_RTG_VAL_NUM > 0 then ORGNL_SHPNG_CHRG_RTG_VAL_NUM end) as AVE_SHPNG_CHRG_DSR_180D  
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '360' day and run_date and ORGNL_SHPNG_CHRG_RTG_VAL_NUM > 0 then ORGNL_SHPNG_CHRG_RTG_VAL_NUM end) as AVE_SHPNG_CHRG_DSR_360D  



From   &drv  a
left join PRS_RESTRICTED_V.EBAY_TRANS_RLTD_EVENT BBE on a.slr_id = bbe.slr_id

where bbe.bbe_elgb_trans_ind = 1  
      and bbe.trans_dt BETWEEN &RUNDT. - INTERVAL '450' DAY AND &RUNDT. 
group by 1,2
order by 1,2
);



/**** Gross Loss,CPS claim, refund ******/
create table  raw.ebay_usar_claim_&ind as select * from connection to td
  (sel  
   a.slr_id
   ,&rundt. as run_date 
 /** cps claim **/ 
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '60' day and run_date  THEN 1 ELSE 0 END) AS cnt_cps_open_claim_60D
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '90' day and run_date  THEN 1 ELSE 0 END) AS cnt_cps_open_claim_90D
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '180' day and run_date  THEN 1 ELSE 0 END) AS cnt_cps_open_claim_180D
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '360' day and run_date  THEN 1 ELSE 0 END) AS cnt_cps_open_claim_360D
    
                                           
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '60' day and run_date  THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_claim_60D
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '90' day and run_date  THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_claim_90D
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '180' day and run_date  THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_claim_180D
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '360' day and run_date  THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_claim_360D
                                           
 /*** cps esc claim **/ 
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '60' day and run_date  THEN 1 ELSE 0 END) AS cnt_cps_esc_claim_60D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '90' day and run_date  THEN 1 ELSE 0 END) AS cnt_cps_esc_claim_90D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '180' day and run_date  THEN 1 ELSE 0 END) AS cnt_cps_esc_claim_180D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '360' day and run_date  THEN 1 ELSE 0 END) AS cnt_cps_esc_claim_360D
                           
						   
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '60' day and run_date  THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_claim_60D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '90' day and run_date  THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_claim_90D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '180' day and run_date  THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_claim_180D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '360' day and run_date  THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_claim_360D
  
  /*********first esc party*****/
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '60' day and run_date  and first_esc_party in ('Seller') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_sr_claim_60D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '90' day and run_date  and first_esc_party in ('Seller') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_sr_claim_90D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '180' day and run_date  and first_esc_party in ('Seller') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_sr_claim_180D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '360' day and run_date  and first_esc_party in ('Seller') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_sr_claim_360D
  
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '60' day and run_date  and first_esc_party in ('Buyer') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_byr_claim_60D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '90' day and run_date  and first_esc_party in ('Buyer') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_byr_claim_90D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '180' day and run_date  and first_esc_party in ('Buyer') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_byr_claim_180D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '360' day and run_date  and first_esc_party in ('Buyer') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_byr_claim_360D
  
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '60' day and run_date  and first_esc_party in ('Seller') THEN 1  ELSE 0 END) AS cnt_cps_esc_sr_claim_60D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '90' day and run_date  and first_esc_party in ('Seller') THEN 1  ELSE 0 END) AS cnt_cps_esc_sr_claim_90D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '180' day and run_date  and first_esc_party in ('Seller') THEN 1  ELSE 0 END) AS cnt_cps_esc_sr_claim_180D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '360' day and run_date  and first_esc_party in ('Seller') THEN 1  ELSE 0 END) AS cnt_cps_esc_sr_claim_360D
                                                                                                                               
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '60' day and run_date  and first_esc_party in ('Buyer') THEN 1 ELSE 0 END) AS cnt_cps_esc_byr_claim_60D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '90' day and run_date  and first_esc_party in ('Buyer') THEN 1 ELSE 0 END) AS cnt_cps_esc_byr_claim_90D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '180' day and run_date  and first_esc_party in ('Buyer') THEN 1 ELSE 0 END) AS cnt_cps_esc_byr_claim_180D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '360' day and run_date  and first_esc_party in ('Buyer') THEN 1 ELSE 0 END) AS cnt_cps_esc_byr_claim_360D
  
  
  /** inr **/
  /** cps inr claim **/ 
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '60' day and run_date  and claim_type in ('INR') THEN 1 ELSE 0 END) AS cnt_cps_open_inr_clm_60D
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '90' day and run_date  and claim_type in ('INR') THEN 1 ELSE 0 END) AS cnt_cps_open_inr_clm_90D
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '180' day and run_date  and claim_type in ('INR') THEN 1 ELSE 0 END) AS cnt_cps_open_inr_clm_180D
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '360' day and run_date  and claim_type in ('INR') THEN 1 ELSE 0 END) AS cnt_cps_open_inr_clm_360D
                                                                                                                      
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '60' day and run_date  and claim_type in ('INR') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_inr_clm_60D
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '90' day and run_date  and claim_type in ('INR') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_inr_clm_90D
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '180' day and run_date  and claim_type in ('INR') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_inr_clm_180D
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '360' day and run_date  and claim_type in ('INR') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_inr_clm_360D
                                             
 /*** cps esc inr claim **/ 
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '60' day and run_date  and claim_type in ('INR') THEN 1 ELSE 0 END) AS cnt_cps_esc_inr_clm_60D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '90' day and run_date  and claim_type in ('INR') THEN 1 ELSE 0 END) AS cnt_cps_esc_inr_clm_90D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '180' day and run_date  and claim_type in ('INR') THEN 1 ELSE 0 END) AS cnt_cps_esc_inr_clm_180D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '360' day and run_date  and claim_type in ('INR') THEN 1 ELSE 0 END) AS cnt_cps_esc_inr_clm_360D
                                                                                                            
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '60' day and run_date  and claim_type in ('INR') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_inr_clm_60D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '90' day and run_date  and claim_type in ('INR') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_inr_clm_90D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '180' day and run_date  and claim_type in ('INR') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_inr_clm_180D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '360' day and run_date  and claim_type in ('INR') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_inr_clm_360D
  /** SNAD **/
   /** cps snad claim **/ 
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '60' day and run_date  and claim_type in ('SNAD') THEN 1 ELSE 0 END) AS cnt_cps_open_SNAD_clm_60D
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '90' day and run_date  and claim_type in ('SNAD') THEN 1 ELSE 0 END) AS cnt_cps_open_SNAD_clm_90D
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '180' day and run_date  and claim_type in ('SNAD') THEN 1 ELSE 0 END) AS cnt_cps_open_SNAD_clm_180D
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '360' day and run_date  and claim_type in ('SNAD') THEN 1 ELSE 0 END) AS cnt_cps_open_SNAD_clm_360D
                                                                                                                      
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '60' day and run_date  and claim_type in ('SNAD') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_SNAD_clm_60D
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '90' day and run_date  and claim_type in ('SNAD') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_SNAD_clm_90D
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '180' day and run_date  and claim_type in ('SNAD') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_SNAD_clm_180D
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '360' day and run_date  and claim_type in ('SNAD') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_SNAD_clm_360D
                                             
 /*** cps esc SNAD claim **/ 
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '60' day and run_date  and claim_type in ('SNAD') THEN 1 ELSE 0 END) AS cnt_cps_esc_SNAD_clm_60D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '90' day and run_date  and claim_type in ('SNAD') THEN 1 ELSE 0 END) AS cnt_cps_esc_SNAD_clm_90D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '180' day and run_date  and claim_type in ('SNAD') THEN 1 ELSE 0 END) AS cnt_cps_esc_SNAD_clm_180D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '360' day and run_date  and claim_type in ('SNAD') THEN 1 ELSE 0 END) AS cnt_cps_esc_SNAD_clm_360D
                                                                                                            
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '60' day and run_date  and claim_type in ('SNAD') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_SNAD_clm_60D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '90' day and run_date  and claim_type in ('SNAD') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_SNAD_clm_90D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '180' day and run_date  and claim_type in ('SNAD') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_SNAD_clm_180D
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '360' day and run_date  and claim_type in ('SNAD') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_SNAD_clm_360D 
  
 
   
/*** gross loss ***/
  ,sum(case when ebay_pyt_dt between &rundt. - interval '60' day and &rundt. and EBAY_PYT_USD_AMT > 0  then EBAY_PYT_USD_AMT
             	      when  slr_appl_pyt_dt between &rundt. - interval '60' day and &rundt. and slr_appl_PYT_USD_AMT > 0 then slr_appl_pyt_usd_amt
       			   when  ebay_pyt_dt between &rundt. - interval '60' day and &rundt. and byr_appl_PYT_USD_AMT > 0  then byr_appl_PYT_USD_AMT
       			  else 0 end) as gross_loss_60D
       
       
          ,sum(case when ebay_pyt_dt between &rundt. - interval '90' day and &rundt. and EBAY_PYT_USD_AMT > 0  then EBAY_PYT_USD_AMT
             	      when  slr_appl_pyt_dt between &rundt. - interval '90' day and &rundt. and slr_appl_PYT_USD_AMT > 0 then slr_appl_pyt_usd_amt
       			   when  ebay_pyt_dt between &rundt. - interval '90' day and &rundt. and byr_appl_PYT_USD_AMT > 0  then byr_appl_PYT_USD_AMT
       			  else 0 end) as gross_loss_90D
       
          ,sum(case when ebay_pyt_dt between &rundt. - interval '180' day and &rundt. and EBAY_PYT_USD_AMT > 0  then EBAY_PYT_USD_AMT
             	      when  slr_appl_pyt_dt between &rundt. - interval '180' day and &rundt. and slr_appl_PYT_USD_AMT > 0 then slr_appl_pyt_usd_amt
       			   when  ebay_pyt_dt between &rundt. - interval '180' day and &rundt. and byr_appl_PYT_USD_AMT > 0  then byr_appl_PYT_USD_AMT
       			  else 0 end) as gross_loss_180D
       
         ,sum(case when ebay_pyt_dt between &rundt. - interval '360' day and &rundt. and EBAY_PYT_USD_AMT > 0  then EBAY_PYT_USD_AMT
             	      when  slr_appl_pyt_dt between &rundt. - interval '360' day and &rundt. and slr_appl_PYT_USD_AMT > 0 then slr_appl_pyt_usd_amt
       			   when  ebay_pyt_dt between &rundt. - interval '360' day and &rundt. and byr_appl_PYT_USD_AMT > 0  then byr_appl_PYT_USD_AMT
       			  else 0 end) as gross_loss_360D  			
       			
			  
   
 /*** refund  (seller pyt = force + vlntry ****/ 
 /*
   ,sum(CASE WHEN cps.slr_vlntry_rfnd_dt between &rundt. - 1 and &rundt. THEN 1 ELSE 0 END) AS cnt_vln_rfnd_60D
   ,sum(CASE WHEN cps.slr_vlntry_rfnd_dt between &rundt. - 3 and &rundt. THEN 1 ELSE 0 END) AS cnt_vln_rfnd_90D
   ,sum(CASE WHEN cps.slr_vlntry_rfnd_dt between &rundt. - 7 and &rundt. THEN 1 ELSE 0 END) AS cnt_vln_rfnd_180D
   ,sum(CASE WHEN cps.slr_vlntry_rfnd_dt between &rundt. -30 and &rundt. THEN 1 ELSE 0 END) AS cnt_vln_rfnd_360D
  
   ,sum(CASE WHEN cps.frcd_rvrsl_dt between &rundt. - 1 and &rundt. THEN 1 ELSE 0 END) AS cnt_frcd_rfnd_60D
   ,sum(CASE WHEN cps.frcd_rvrsl_dt between &rundt. - 3 and &rundt. THEN 1 ELSE 0 END) AS cnt_frcd_rfnd_90D
   ,sum(CASE WHEN cps.frcd_rvrsl_dt between &rundt. - 7 and &rundt. THEN 1 ELSE 0 END) AS cnt_frcd_rfnd_180D
   ,sum(CASE WHEN cps.frcd_rvrsl_dt between &rundt. -30 and &rundt. THEN 1 ELSE 0 END) AS cnt_frcd_rfnd_360D
   
   ,sum(CASE WHEN cps.slr_vlntry_rfnd_dt between &rundt. - 1 and &rundt. THEN slr_vlntry_rfnd_usd_amt ELSE 0 END) AS amt_vln_rfnd_60D
   ,sum(CASE WHEN cps.slr_vlntry_rfnd_dt between &rundt. - 3 and &rundt. THEN slr_vlntry_rfnd_usd_amt ELSE 0 END) AS amt_vln_rfnd_90D
   ,sum(CASE WHEN cps.slr_vlntry_rfnd_dt between &rundt. - 7 and &rundt. THEN slr_vlntry_rfnd_usd_amt ELSE 0 END) AS amt_vln_rfnd_180D
   ,sum(CASE WHEN cps.slr_vlntry_rfnd_dt between &rundt. -30 and &rundt. THEN slr_vlntry_rfnd_usd_amt ELSE 0 END) AS amt_vln_rfnd_360D
  
   ,sum(CASE WHEN cps.frcd_rvrsl_dt between &rundt. - 1 and &rundt. THEN frcd_rvrsl_usd_amt ELSE 0 END) AS amt_frcd_rfnd_60D
   ,sum(CASE WHEN cps.frcd_rvrsl_dt between &rundt. - 3 and &rundt. THEN frcd_rvrsl_usd_amt ELSE 0 END) AS amt_frcd_rfnd_90D
   ,sum(CASE WHEN cps.frcd_rvrsl_dt between &rundt. - 7 and &rundt. THEN frcd_rvrsl_usd_amt ELSE 0 END) AS amt_frcd_rfnd_180D
   ,sum(CASE WHEN cps.frcd_rvrsl_dt between &rundt. -30 and &rundt. THEN frcd_rvrsl_usd_amt ELSE 0 END) AS amt_frcd_rfnd_360D
 */

   from &drv a
   inner join PRS_RESTRICTED_V.EBAY_TRANS_RLTD_EVENT BBE on a.slr_id = bbe.slr_id
   inner JOIN  access_views.rsltn_cps cps ON bbe.slr_id=cps.slr_id AND bbe.item_id = cps.item_id AND bbe.trans_id = cps.tran_id
   where CK_TRAN_CRE_DT BETWEEN &RUNDT. - INTERVAL '450' DAY AND &RUNDT. and  bbe.trans_dt BETWEEN &RUNDT. - INTERVAL '450' DAY AND &RUNDT. and bbe.bbe_elgb_trans_ind = 1    
   group by 1,2
   order by 1,2
   );


create table  raw.ebay_usar_lstg_&ind as select * from connection to td
  (SEL 
	DRV.slr_id
  ,drv.run_date

  
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '60' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4) THEN 1 ELSE 0 END) AS CNT_NEW_LSTNG_60D    
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '90' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4) THEN 1 ELSE 0 END) AS CNT_NEW_LSTNG_90D 
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '180' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4) THEN 1 ELSE 0 END) AS CNT_NEW_LSTNG_180D 
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '360' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4) THEN 1 ELSE 0 END) AS CNT_NEW_LSTNG_360D 
  
  /** FP listing **/
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '60' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4)  and auct_type_code in (7,9) THEN 1 ELSE 0 END) AS CNT_NEW_FP_LSTNG_60D    
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '90' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4)  and auct_type_code in (7,9) THEN 1 ELSE 0 END) AS CNT_NEW_FP_LSTNG_90D 
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '180' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4)  and auct_type_code in (7,9) THEN 1 ELSE 0 END) AS CNT_NEW_FP_LSTNG_180D 
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '360' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4) and auct_type_code in (7,9) THEN 1 ELSE 0 END) AS CNT_NEW_FP_LSTNG_360D 

  /** BIN listing **/ 
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '60' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4)  and auct_type_code in (1,2) and bin_price_usd>0  THEN 1 ELSE 0 END) AS CNT_NEW_BIN_LSTNG_60D    
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '90' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4)  and auct_type_code in (1,2) and bin_price_usd>0  THEN 1 ELSE 0 END) AS CNT_NEW_BIN_LSTNG_90D 
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '180' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4)  and auct_type_code in (1,2) and bin_price_usd>0  THEN 1 ELSE 0 END) AS CNT_NEW_BIN_LSTNG_180D 
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '360' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4) and auct_type_code in (1,2) and bin_price_usd>0  THEN 1 ELSE 0 END) AS CNT_NEW_BIN_LSTNG_360D 
  
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '60' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_ENDED_LSTNG_60D
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '90' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_ENDED_LSTNG_90D
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '180' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_ENDED_LSTNG_180D
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '360' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_ENDED_LSTNG_360D
   
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '60' DAY AND drv.run_date AND QTY_SOLD>0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_SCSFL_ENDED_LSTNG_60D
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '90' DAY AND drv.run_date AND QTY_SOLD>0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_SCSFL_ENDED_LSTNG_90D
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '180' DAY AND drv.run_date AND QTY_SOLD>0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_SCSFL_ENDED_LSTNG_180D
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '360' DAY AND drv.run_date AND QTY_SOLD>0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_SCSFL_ENDED_LSTNG_360D
   
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '60' DAY AND drv.run_date AND QTY_SOLD=0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_UNSCSFL_ENDED_LSTNG_60D
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '90' DAY AND drv.run_date AND QTY_SOLD=0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_UNSCSFL_ENDED_LSTNG_90D
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '180' DAY AND drv.run_date AND QTY_SOLD=0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_UNSCSFL_ENDED_LSTNG_180D
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '360' DAY AND drv.run_date AND QTY_SOLD=0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_UNSCSFL_ENDED_LSTNG_360D
  	
	/** new listing amt **/
  
	,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '60' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '60' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        else 0 END) AMT_NEW_LSTNG_USD_60D
	 
	,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '90' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '90' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        else 0 END) AMT_NEW_LSTNG_USD_90D
  
    ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '180' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '180' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        else 0 END) AMT_NEW_LSTNG_USD_180D
		
	,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '360' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '360' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        else 0 END) AMT_NEW_LSTNG_USD_360D	
     
/*** new FP listing ***/	 
	,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '60' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,9) 
              THEN QTY_AVAIL * START_PRICE_USD else 0 END) as AMT_NEW_FP_LSTNG_60D
	 
	,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '90' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,9) 
              THEN QTY_AVAIL * START_PRICE_USD else 0 END) as AMT_NEW_FP_LSTNG_90D
			  
	,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '180' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,9) 
              THEN QTY_AVAIL * START_PRICE_USD else 0 END) as AMT_NEW_FP_LSTNG_180D
			  
	,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '360' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,9) 
              THEN QTY_AVAIL * START_PRICE_USD else 0 END) as AMT_NEW_FP_LSTNG_360D
	
/** amt unscsfl_end_lsting_usd **/	
 ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '60' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '60' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        else 0 END) AMT_UNSCSFL_END_LSTNG_USD_60D
	
 ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '90' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '90' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        else 0 END) AMT_UNSCSFL_END_LSTNG_USD_90D

,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '180' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '180' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        else 0 END) AMT_UNSCSFL_END_LSTNG_USD_180D

,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '360' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '360' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        else 0 END) AMT_UNSCSFL_END_LSTNG_USD_360D
		
/** amt unscsfl_end_lsting_usd FP **/	

 ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '60' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,9) 
             THEN QTY_AVAIL * START_PRICE_USD ELSE 0 END) AMT_UNSCSFL_END_FP_LSTNG_60D		
	
 ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '90' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,9) 
             THEN QTY_AVAIL * START_PRICE_USD ELSE 0 END) AMT_UNSCSFL_END_FP_LSTNG_90D		

 ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '180' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,9) 
             THEN QTY_AVAIL * START_PRICE_USD ELSE 0 END) AMT_UNSCSFL_END_FP_LSTNG_180D		

 ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '360' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,9) 
             THEN QTY_AVAIL * START_PRICE_USD ELSE 0 END) AMT_UNSCSFL_END_FP_LSTNG_360D					 
	
  FROM 
	&DRV DRV
  LEFT JOIN 
    ACCESS_VIEWS.DW_LSTG_ITEM LSTG
  ON LSTG.SLR_ID = DRV.slr_id  
    and lstg.AUCT_END_DT >= DATE '2014-11-01' 
    and lstg.AUCT_END_DT BETWEEN drv.run_date - INTERVAL '360' DAY AND drv.run_date
    and AUCT_TYPE_CODE NOT IN (10,12,15)
  LEFT JOIN
    ACCESS_VIEWS.DW_LSTG_ITEM_COLD cold
  ON lstg.item_id = cold.item_id
    and cold.AUCT_END_DT >= DATE '2014-11-01' 
    and cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '360' DAY AND drv.run_date 	

  GROUP BY 1,2); 
  
  
create table  raw.ebay_usar_msg_rev_&ind. as select * from connection to td
(sel 
a.slr_id
,run_date

,sum(case when src_cre_date between run_date - interval '60'  day and run_date then 1 else 0 end) as cnt_rev_tot_msg_60d 
,sum(case when src_cre_date between run_date - interval '90'  day and run_date then 1 else 0 end) as cnt_rev_tot_msg_90d 
,sum(case when src_cre_date between run_date - interval '180' day and run_date then 1 else 0 end) as cnt_rev_tot_msg_180d 
,sum(case when src_cre_date between run_date - interval '360' day and run_date then 1 else 0 end) as cnt_rev_tot_msg_360d 
                                                             
,sum(case when src_cre_date between run_date - interval '60'  day and run_date and email_type_id in (1) then 1 else 0 end) as cnt_rev_asq_msg_60d 
,sum(case when src_cre_date between run_date - interval '90'  day and run_date and email_type_id in (1) then 1 else 0 end) as cnt_rev_asq_msg_90d 
,sum(case when src_cre_date between run_date - interval '180' day and run_date and email_type_id in (1) then 1 else 0 end) as cnt_rev_asq_msg_180d
,sum(case when src_cre_date between run_date - interval '360' day and run_date and email_type_id in (1) then 1 else 0 end) as cnt_rev_asq_msg_360d 
                                                             
,sum(case when src_cre_date between run_date - interval '60'  day and run_date and msg_type_id in (10,12,13,20) then 1 else 0 end) as cnt_rev_neg_msg_60d 
,sum(case when src_cre_date between run_date - interval '90'  day and run_date and msg_type_id in (10,12,13,20) then 1 else 0 end) as cnt_rev_neg_msg_90d 
,sum(case when src_cre_date between run_date - interval '180' day and run_date and msg_type_id in (10,12,13,20) then 1 else 0 end) as cnt_rev_neg_msg_180d
,sum(case when src_cre_date between run_date - interval '360' day and run_date and msg_type_id in (10,12,13,20) then 1 else 0 end) as cnt_rev_neg_msg_360d 


From   &drv  a
left join access_views.dw_ue_email_tracking c on a.slr_id = c.rcpnt_id and item_id >=0 and src_cre_dt between run_dt - interval '360' day and run_dt
group by 1,2
); 



create table  raw.ebay_usar_msg_snd_&ind. as select * from connection to td
(sel 
a.slr_id
,run_date

,sum(case when src_cre_date between run_date - interval '60'  day and run_date then 1 else 0 end) as cnt_snd_tot_msg_60d 
,sum(case when src_cre_date between run_date - interval '90'  day and run_date then 1 else 0 end) as cnt_snd_tot_msg_90d 
,sum(case when src_cre_date between run_date - interval '180'  day and run_date then 1 else 0 end) as cnt_snd_tot_msg_180d 
,sum(case when src_cre_date between run_date - interval '360' day and run_date then 1 else 0 end) as cnt_snd_tot_msg_360d 

,sum(case when src_cre_date between run_date - interval '60'  day and run_date and email_type_id in (4) then 1 else 0 end) as cnt_snd_rsp_msg_60d 
,sum(case when src_cre_date between run_date - interval '90'  day and run_date and email_type_id in (4) then 1 else 0 end) as cnt_snd_rsp_msg_90d 
,sum(case when src_cre_date between run_date - interval '180'  day and run_date and email_type_id in (4) then 1 else 0 end) as cnt_snd_rsp_msg_180d 
,sum(case when src_cre_date between run_date - interval '360' day and run_date and email_type_id in (4) then 1 else 0 end) as cnt_snd_rsp_msg_360d 

,sum(case when src_cre_date between run_date - interval '60'  day and run_date and msg_type_id in (10,12,13,20) then 1 else 0 end) as cnt_snd_neg_msg_60d 
,sum(case when src_cre_date between run_date - interval '90'  day and run_date and msg_type_id in (10,12,13,20) then 1 else 0 end) as cnt_snd_neg_msg_90d 
,sum(case when src_cre_date between run_date - interval '180'  day and run_date and msg_type_id in (10,12,13,20) then 1 else 0 end) as cnt_snd_neg_msg_180d 
,sum(case when src_cre_date between run_date - interval '360' day and run_date and msg_type_id in (10,12,13,20) then 1 else 0 end) as cnt_snd_neg_msg_360d 


From   &drv  a
left join access_views.dw_ue_email_tracking c on a.slr_id = c.sndr_id and item_id >=0 and src_cre_dt between run_dt - interval '360' day and run_dt
group by 1,2
); 

  
/********* status change ************/
Create table  raw.ebay_usar_hist_status_&ind as select * from connection to td
(sel 
a.slr_id
,a.run_date

,sum(case when change_time BETWEEN run_date - interval '1'   day and run_date and to_state = 0 then 1 else 0 end) as hist_cnt_suspend_1d
,sum(case when change_time BETWEEN run_date - interval '3'   day and run_date and to_state = 0 then 1 else 0 end) as hist_cnt_suspend_3d
,sum(case when change_time BETWEEN run_date - interval '7'   day and run_date and to_state = 0 then 1 else 0 end) as hist_cnt_suspend_7d
,sum(case when change_time BETWEEN run_date - interval '30'  day and run_date and to_state = 0 then 1 else 0 end) as hist_cnt_suspend_30d
,sum(case when change_time BETWEEN run_date - interval '60'  day and run_date and to_state = 0 then 1 else 0 end) as hist_cnt_suspend_60d
,sum(case when change_time BETWEEN run_date - interval '90'  day and run_date and to_state = 0 then 1 else 0 end) as hist_cnt_suspend_90d
,sum(case when change_time BETWEEN run_date - interval '180' day and run_date and to_state = 0 then 1 else 0 end) as hist_cnt_suspend_180d
,sum(case when change_time BETWEEN run_date - interval '360' day and run_date and to_state = 0 then 1 else 0 end) as hist_cnt_suspend_360d

from &drv. a
left join ACCESS_VIEWS.DW_USER_STATE_HISTORY b on a.slr_id = b.id and b.change_time between run_date - interval '360' day and run_date   
group by 1,2
order by 1,2
);  

/*** buyer behavior GMB ****************/

create table  raw.ebay_usar_byr_&ind as select * from connection to td
(sel 
a.slr_id
,&rundt. as run_date

/*** GMB **************/
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '1'   day and run_date then 1 else 0 end) as CNT_HIST_GMB_1D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '3'   day and run_date then 1 else 0 end) as CNT_HIST_GMB_3D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '7'   day and run_date then 1 else 0 end) as CNT_HIST_GMB_7D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date then 1 else 0 end) as CNT_HIST_GMB_30D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '60'   day and run_date then 1 else 0 end) as CNT_HIST_GMB_60D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '90'   day and run_date then 1 else 0 end) as CNT_HIST_GMB_90D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '180'   day and run_date then 1 else 0 end) as CNT_HIST_GMB_180D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '360'  day and run_date then 1 else 0 end) as CNT_HIST_GMB_360D  


,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '1'   day and run_date then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HIST_GMB_1D 
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '3'   day and run_date then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HIST_GMB_3D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '7'   day and run_date then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HIST_GMB_7D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HIST_GMB_30D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '60'  day and run_date then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HIST_GMB_60D 
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '90'  day and run_date then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HIST_GMB_90D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '180' day and run_date then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HIST_GMB_180D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '360' day and run_date then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HIST_GMB_360D  


From   &drv  a
left join PRS_RESTRICTED_V.EBAY_TRANS_RLTD_EVENT BBE on a.slr_id = bbe.byr_id

where bbe.bbe_elgb_trans_ind = 1  
      and bbe.trans_dt BETWEEN &RUNDT. - INTERVAL '360' DAY AND &RUNDT.
   	  
group by 1,2
order by 1,2);

%mend;
 
/** level 2 category **/

create table  raw.ebay_usar_riskcat_0_&ind as select * from connection to td
(sel 
 drv.slr_id
,drv.run_date
/**********************/
&low_risk_b2c_1_1
&low_risk_b2c_3_1
&low_risk_b2c_7_1
&low_risk_b2c_30_1
&low_risk_b2c_60_1
&low_risk_b2c_90_1

&low_risk_b2c_1_2
&low_risk_b2c_3_2
&low_risk_b2c_7_2
&low_risk_b2c_30_2
&low_risk_b2c_60_2
&low_risk_b2c_90_2


&high_risk_b2c_1_1
&high_risk_b2c_3_1
&high_risk_b2c_7_1
&high_risk_b2c_30_1
&high_risk_b2c_60_1
&high_risk_b2c_90_1

&high_risk_b2c_1_2
&high_risk_b2c_3_2
&high_risk_b2c_7_2
&high_risk_b2c_30_2
&high_risk_b2c_60_2
&high_risk_b2c_90_2


/**/
&low_risk_c2c_1_1
&low_risk_c2c_3_1
&low_risk_c2c_7_1
&low_risk_c2c_30_1
&low_risk_c2c_60_1
&low_risk_c2c_90_1

&low_risk_c2c_1_2
&low_risk_c2c_3_2
&low_risk_c2c_7_2
&low_risk_c2c_30_2
&low_risk_c2c_60_2
&low_risk_c2c_90_2



&high_risk_c2c_1_1
&high_risk_c2c_3_1
&high_risk_c2c_7_1
&high_risk_c2c_30_1
&high_risk_c2c_60_1
&high_risk_c2c_90_1

&high_risk_c2c_1_2
&high_risk_c2c_3_2
&high_risk_c2c_7_2
&high_risk_c2c_30_2
&high_risk_c2c_60_2
&high_risk_c2c_90_2

/**/
&low_risk_dor_1_1
&low_risk_dor_3_1
&low_risk_dor_7_1
&low_risk_dor_30_1
&low_risk_dor_60_1
&low_risk_dor_90_1

&low_risk_dor_1_2
&low_risk_dor_3_2
&low_risk_dor_7_2
&low_risk_dor_30_2
&low_risk_dor_60_2
&low_risk_dor_90_2

&high_risk_dor_1_1
&high_risk_dor_3_1
&high_risk_dor_7_1
&high_risk_dor_30_1
&high_risk_dor_60_1
&high_risk_dor_90_1

&high_risk_dor_1_2
&high_risk_dor_3_2
&high_risk_dor_7_2
&high_risk_dor_30_2
&high_risk_dor_60_2
&high_risk_dor_90_2


&low_risk_c2c_180_1
&low_risk_b2c_180_1
&low_risk_b2c_180_2
&high_risk_b2c_180_2
&low_risk_c2c_180_2
&high_risk_c2c_180_1
&high_risk_c2c_180_2
&low_risk_dor_180_1
&low_risk_dor_180_2
&high_risk_dor_180_2
&high_risk_dor_180_1
&high_risk_b2c_180_1


&low_risk_b2c_360_1
&low_risk_b2c_360_2
&high_risk_b2c_360_2
&low_risk_c2c_360_2
&high_risk_c2c_360_1
&high_risk_c2c_360_2
&low_risk_dor_360_1
&low_risk_dor_360_2
&high_risk_dor_360_2
&high_risk_dor_360_1
&high_risk_b2c_360_1
&low_risk_c2c_360_1


From   &drv drv
left join PRS_RESTRICTED_V.EBAY_TRANS_RLTD_EVENT BBE
  on drv.slr_id = bbe.slr_id
  and bbe.bbe_elgb_trans_ind = 1 
  and bbe.trans_dt >= DATE '2015-02-01' 
  and bbe.trans_dt BETWEEN drv.run_date - INTERVAL '180' DAY AND drv.run_date 

left join access_views.DW_CATEGORY_GROUPINGS GRP
  ON BBE.LEAF_CATEG_ID=GRP.LEAF_CATEG_ID
  AND BBE.ITEM_LSTD_SITE_ID  =GRP.SITE_ID 
where drv.slr_id mod 2 = 0
group by 1,2);

quit;

%mend;

%ebay_usar_var360(drv= P_riskmodeling_t.ebay_usar_samp_drv , rundt = run_date,ind= raw360 );


endsas;
%macro dd;
proc sql;
  connect to teradata as td(user=&sysuserid password="&tdbpass." tdpid="hopper" database=access_views);

/** for creating _1d/max **/
create table  raw.ebay_usar_max as select * from connection to td
(sel 
slr_id
,run_date
,max(gmv) as max_daily_gmv_360
,max(cnt_txn) as max_daily_txn_360
,max(asp) as max_asp_360
from 
(sel drv.slr_id,run_date,trans_dt
,sum(ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2))) as GMV
,avg(ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2))) as ASP
,count(1) as cnt_txn
from P_riskmodeling_t.ebay_usar_samp_drv drv 
inner join prs_restricted_v.ebay_trans_rltd_event bbe on drv.slr_id = bbe.slr_id  
and bbe.bbe_elgb_trans_ind = 1 and bbe.trans_dt BETWEEN run_dt - 360 AND run_dt - 1 
group by 1,2,3
) a
group by 1,2);

/** for creating days since **/
create table  raw.ebay_usar_all_daily as select * from connection to td
(sel drv.slr_id
,run_date
,trans_dt
,sum(ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2))) as GMV
,avg(ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2))) as ASP
,count(1) as cnt_txn
from P_riskmodeling_t.ebay_usar_samp_drv drv 
inner join prs_restricted_v.ebay_trans_rltd_event bbe on drv.slr_id = bbe.slr_id  
and bbe.bbe_elgb_trans_ind = 1 and bbe.trans_dt BETWEEN run_dt - 365 AND run_dt  
group by 1,2,3
);

quit;
/***********/
%mend;

proc sql;
  connect to teradata as td(user=&sysuserid password="&tdbpass." tdpid="mz2" database=access_views);

create table  raw.ebay_usar_issue as select * from connection to td
(sel 
a.slr_id
,run_date

,max(case when src_cre_date between run_date - interval '1' day and run_date and scenario_id IN (12, 34, 122, 123, 172, 173, 181, 188, 216, 217, 218, 233, 305, 419) then 1 else 0 end) as hist_flag_res_1d
,max(case when src_cre_date between run_date - interval '3' day and run_date and scenario_id IN (12, 34, 122, 123, 172, 173, 181, 188, 216, 217, 218, 233, 305, 419) then 1 else 0 end) as hist_flag_res_3d
,max(case when src_cre_date between run_date - interval '7' day and run_date and scenario_id IN (12, 34, 122, 123, 172, 173, 181, 188, 216, 217, 218, 233, 305, 419) then 1 else 0 end) as hist_flag_res_7d
,max(case when src_cre_date between run_date - interval '30' day and run_date and scenario_id IN (12, 34, 122, 123, 172, 173, 181, 188, 216, 217, 218, 233, 305, 419) then 1 else 0 end) as hist_flag_res_30d
,max(case when src_cre_date between run_date - interval '60' day and run_date and scenario_id IN (12, 34, 122, 123, 172, 173, 181, 188, 216, 217, 218, 233, 305, 419) then 1 else 0 end) as hist_flag_res_60d
,max(case when src_cre_date between run_date - interval '90' day and run_date and scenario_id IN (12, 34, 122, 123, 172, 173, 181, 188, 216, 217, 218, 233, 305, 419) then 1 else 0 end) as hist_flag_res_90d
,max(case when src_cre_date between run_date - interval '180' day and run_date and scenario_id IN (12, 34, 122, 123, 172, 173, 181, 188, 216, 217, 218, 233, 305, 419) then 1 else 0 end) as hist_flag_res_180d

from  P_riskdecision_t.ebay_usar_samp_drv a 
LEFT JOIN ACCESS_VIEWS.DW_USER_ISSUE issue 
ON  a.slr_id = issue.user_id AND src_cre_dt between run_dt - interval '180' day and run_dt 
group by 1,2
order by 1,2
);  
quit;

endsas;

