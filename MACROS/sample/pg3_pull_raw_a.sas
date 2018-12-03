/*************************************************************************/
/* Project:         EG Model/Strategy                                   **/ 
/* Author:          Mike Min                                            **/
/* Creation Date:   09/2015                                             **/
/* Last Modified:                                                       **/
/* Purpose:         pull daily raw variables                            **/
/* Notes:						                                        **/
/* Arguments:       None                                                **/
**************************************************************************/


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



/*********************** listing  daily      ********************/
%macro pull_ebay_usar_daily(drv = , rundt= ,ind= );


proc sql;
  connect to teradata as td(user=&sysuserid password="&tdbpass." tdpid="hopper" database=access_views);

  
create table  raw.ebay_usar_tran_&ind. as select * from connection to td
(sel 
a.slr_id
,&rundt. as run_date

/*** GMV **************/
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '1'  day and run_date then 1 else 0 end) as CNT_HIST_TXN_1D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '3'  day and run_date then 1 else 0 end) as CNT_HIST_TXN_3D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '7'  day and run_date then 1 else 0 end) as CNT_HIST_TXN_7D 
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30' day and run_date then 1 else 0 end) as CNT_HIST_TXN_30D         

,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '1'  day and run_date then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_GMV_1D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '3'  day and run_date then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_GMV_3D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '7'  day and run_date then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_GMV_7D   
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30' day and run_date then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_GMV_30D   


,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '1'  day and run_date then ITEM_SOLD_QTY  else 0 end) as HIST_ITEM_SOLD_QTY_1D 
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '3'  day and run_date then ITEM_SOLD_QTY  else 0 end) as HIST_ITEM_SOLD_QTY_3D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '7'  day and run_date then ITEM_SOLD_QTY  else 0 end) as HIST_ITEM_SOLD_QTY_7D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30' day and run_date then ITEM_SOLD_QTY  else 0 end) as HIST_ITEM_SOLD_QTY_30D  


/*** listing ***/

,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '1'  day and run_date and auct_type_code in (7,9) then 1 else 0 end ) as CNT_HIST_FP_TXN_1D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '3'  day and run_date and auct_type_code in (7,9) then 1 else 0 end ) as CNT_HIST_FP_TXN_3D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '7'  day and run_date and auct_type_code in (7,9) then 1 else 0 end ) as CNT_HIST_FP_TXN_7D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date and auct_type_code in (7,9) then 1 else 0 end ) as CNT_HIST_FP_TXN_30D
                                             
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '1'  day and run_date and auct_type_code in (7,9)  then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end ) as AMT_HIST_FP_TXN_1D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '3'  day and run_date and auct_type_code in (7,9)  then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end ) as AMT_HIST_FP_TXN_3D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '7'  day and run_date and auct_type_code in (7,9)  then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end ) as AMT_HIST_FP_TXN_7D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date and auct_type_code in (7,9) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end ) as AMT_HIST_FP_TXN_30D
                                             
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '1'  day and run_date and auct_type_code in  (1,2) and bin_price_lc_amt>0  then 1 else 0 end ) as CNT_HIST_BIN_TXN_1D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '3'  day and run_date and auct_type_code in  (1,2) and bin_price_lc_amt>0  then 1 else 0 end ) as CNT_HIST_BIN_TXN_3D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '7'  day and run_date and auct_type_code in  (1,2) and bin_price_lc_amt>0  then 1 else 0 end ) as CNT_HIST_BIN_TXN_7D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date and auct_type_code in (1,2) and bin_price_lc_amt>0  then 1 else 0 end ) as CNT_HIST_BIN_TXN_30D
                                                                 
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '1'  day and run_date and auct_type_code in  (1,2) and bin_price_lc_amt>0  then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end ) as AMT_HIST_BIN_TXN_1D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '3'  day and run_date and auct_type_code in  (1,2) and bin_price_lc_amt>0  then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end ) as AMT_HIST_BIN_TXN_3D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '7'  day and run_date and auct_type_code in  (1,2) and bin_price_lc_amt>0  then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end ) as AMT_HIST_BIN_TXN_7D
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date and auct_type_code in (1,2) and bin_price_lc_amt>0  then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end ) as AMT_HIST_BIN_TXN_30D 
 
 
 
/*** Defects  CNT **********/

/*** CBT ***/
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '1'   day and run_date and CBT_IND = 1 then 1 else 0 end) as CNT_HIST_CBT_TXN_1D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '3'   day and run_date and CBT_IND = 1 then 1 else 0 end) as CNT_HIST_CBT_TXN_3D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '7'   day and run_date and CBT_IND = 1 then 1 else 0 end) as CNT_HIST_CBT_TXN_7D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date and CBT_IND = 1 then 1 else 0 end) as CNT_HIST_CBT_TXN_30D  

,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '1'   day and run_date and CBT_IND = 1 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_CBT_GMV_1D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '3'   day and run_date and CBT_IND = 1 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_CBT_GMV_3D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '7'   day and run_date and CBT_IND = 1 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_CBT_GMV_7D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date and CBT_IND = 1 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_CBT_GMV_30D  

/*** ASP ***/
,avg(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '1'   day and run_date then ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) end) as asp_1D  
,avg(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '3'   day and run_date then ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) end) as asp_3D  
,avg(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '7'   day and run_date then ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) end) as asp_7D  
,avg(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date then ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) end) as asp_30D

/*** high ASP tran change ***/
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '1'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then 1 else 0 end) as CNT_HASP_TXN_1D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '3'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then 1 else 0 end) as CNT_HASP_TXN_3D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '7'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then 1 else 0 end) as CNT_HASP_TXN_7D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then 1 else 0 end) as CNT_HASP_TXN_30D  

,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '1'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_GMV_1D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '3'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_GMV_3D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '7'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_GMV_7D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_GMV_30D  

,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '1'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then 1 else 0 end) as CNT_HASP_gt2_TXN_1D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '3'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then 1 else 0 end) as CNT_HASP_gt2_TXN_3D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '7'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then 1 else 0 end) as CNT_HASP_gt2_TXN_7D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then 1 else 0 end) as CNT_HASP_gt2_TXN_30D  

,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '1'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_gt2_GMV_1D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '3'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_gt2_GMV_3D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '7'   day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_gt2_GMV_7D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_gt2_GMV_30D  


/** Feedback **/
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '1' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID in(1,2,3) or BYR_FDBK_OVRL_RTNG_ID in (1,2,3) ) then 1 else 0 end) as CNT_SLR_TOT_FDBK_1D  
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '3' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID in(1,2,3) or BYR_FDBK_OVRL_RTNG_ID in (1,2,3) ) then 1 else 0 end) as CNT_SLR_TOT_FDBK_3D  
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '7' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID in(1,2,3) or BYR_FDBK_OVRL_RTNG_ID in (1,2,3) ) then 1 else 0 end) as CNT_SLR_TOT_FDBK_7D  
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '30' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID in(1,2,3) or BYR_FDBK_OVRL_RTNG_ID in (1,2,3) ) then 1 else 0 end) as CNT_SLR_TOT_FDBK_30D  

,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '1' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 1 or BYR_FDBK_OVRL_RTNG_ID = 1) then 1 else 0 end) as CNT_SLR_PSTV_FDBK_1D  
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '3' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 1 or BYR_FDBK_OVRL_RTNG_ID = 1) then 1 else 0 end) as CNT_SLR_PSTV_FDBK_3D  
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '7' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 1 or BYR_FDBK_OVRL_RTNG_ID = 1) then 1 else 0 end) as CNT_SLR_PSTV_FDBK_7D 
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '30' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 1 or BYR_FDBK_OVRL_RTNG_ID = 1) then 1 else 0 end) as CNT_SLR_PSTV_FDBK_30D 

,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '1' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 2 or BYR_FDBK_OVRL_RTNG_ID = 2) then 1 else 0 end) as CNT_SLR_NGTV_FDBK_1D  
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '3' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 2 or BYR_FDBK_OVRL_RTNG_ID = 2) then 1 else 0 end) as CNT_SLR_NGTV_FDBK_3D  
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '7' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 2 or BYR_FDBK_OVRL_RTNG_ID = 2) then 1 else 0 end) as CNT_SLR_NGTV_FDBK_7D 
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '30' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 2 or BYR_FDBK_OVRL_RTNG_ID = 2) then 1 else 0 end) as CNT_SLR_NGTV_FDBK_30D 

,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '1' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 3 or BYR_FDBK_OVRL_RTNG_ID = 3) then 1 else 0 end) as CNT_SLR_NTRL_FDBK_1D  
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '3' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 3 or BYR_FDBK_OVRL_RTNG_ID = 3) then 1 else 0 end) as CNT_SLR_NTRL_FDBK_3D  
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '7' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 3 or BYR_FDBK_OVRL_RTNG_ID = 3) then 1 else 0 end) as CNT_SLR_NTRL_FDBK_7D 
,sum(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '30' day and run_date and (ORGNL_FDBK_OVRL_RTG_ID = 3 or BYR_FDBK_OVRL_RTNG_ID = 3) then 1 else 0 end) as CNT_SLR_NTRL_FDBK_30D 

/*** Rating IAD,COM,SHP CHRG and ST ***/
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '1' day and run_date and ORGNL_ITEM_AS_DSCRBD_RTG_NUM > 0 then ORGNL_ITEM_AS_DSCRBD_RTG_NUM end) as AVE_IAD_DSR_1D 
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '3' day and run_date and ORGNL_ITEM_AS_DSCRBD_RTG_NUM > 0 then ORGNL_ITEM_AS_DSCRBD_RTG_NUM end) as AVE_IAD_DSR_3D  
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '7' day and run_date and ORGNL_ITEM_AS_DSCRBD_RTG_NUM > 0 then ORGNL_ITEM_AS_DSCRBD_RTG_NUM end) as AVE_IAD_DSR_7D  
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '30' day and run_date and ORGNL_ITEM_AS_DSCRBD_RTG_NUM > 0 then ORGNL_ITEM_AS_DSCRBD_RTG_NUM end) as AVE_IAD_DSR_30D  

,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '1' day and run_date and ORGNL_COM_RTG_VAL_NUM > 0 then ORGNL_COM_RTG_VAL_NUM end) as AVE_COM_DSR_1D  
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '3' day and run_date and ORGNL_COM_RTG_VAL_NUM > 0 then ORGNL_COM_RTG_VAL_NUM end) as AVE_COM_DSR_3D  
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '7' day and run_date and ORGNL_COM_RTG_VAL_NUM > 0 then ORGNL_COM_RTG_VAL_NUM end) as AVE_COM_DSR_7D  
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '30' day and run_date and ORGNL_COM_RTG_VAL_NUM > 0 then ORGNL_COM_RTG_VAL_NUM end) as AVE_COM_DSR_30D  

,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '1' day and run_date and ORGNL_SHPNG_TM_RTG_VAL_NUM > 0 then ORGNL_SHPNG_TM_RTG_VAL_NUM end) as AVE_ST_DSR_1D 
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '3' day and run_date and ORGNL_SHPNG_TM_RTG_VAL_NUM > 0 then ORGNL_SHPNG_TM_RTG_VAL_NUM end) as AVE_ST_DSR_3D  
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '7' day and run_date and ORGNL_SHPNG_TM_RTG_VAL_NUM > 0 then ORGNL_SHPNG_TM_RTG_VAL_NUM end) as AVE_ST_DSR_7D  
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '30' day and run_date and ORGNL_SHPNG_TM_RTG_VAL_NUM > 0 then ORGNL_SHPNG_TM_RTG_VAL_NUM end) as AVE_ST_DSR_30D  

,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '1' day and run_date and ORGNL_SHPNG_CHRG_RTG_VAL_NUM > 0 then ORGNL_SHPNG_CHRG_RTG_VAL_NUM end) as AVE_SHPNG_CHRG_DSR_1D  
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '3' day and run_date and ORGNL_SHPNG_CHRG_RTG_VAL_NUM > 0 then ORGNL_SHPNG_CHRG_RTG_VAL_NUM end) as AVE_SHPNG_CHRG_DSR_3D  
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '7' day and run_date and ORGNL_SHPNG_CHRG_RTG_VAL_NUM > 0 then ORGNL_SHPNG_CHRG_RTG_VAL_NUM end) as AVE_SHPNG_CHRG_DSR_7D  
,avg(case when (cast(bbe.BYR_FDBK_RCVD_DT as timestamp(0)) + (bbe.BYR_FDBK_RCVD_TM - time '00:00:00' hour to second)) between run_date - interval '30' day and run_date and ORGNL_SHPNG_CHRG_RTG_VAL_NUM > 0 then ORGNL_SHPNG_CHRG_RTG_VAL_NUM end) as AVE_SHPNG_CHRG_DSR_30D  


From   &drv  a
left join PRS_RESTRICTED_V.EBAY_TRANS_RLTD_EVENT BBE on a.slr_id = bbe.slr_id

where bbe.bbe_elgb_trans_ind = 1  
      and bbe.trans_dt BETWEEN &RUNDT. - INTERVAL '180' DAY AND &RUNDT. 
group by 1,2
order by 1,2
);



/**** Gross Loss,CPS claim, refund ******/
create table  raw.ebay_usar_claim_&ind as select * from connection to td
  (sel  
   a.slr_id
   ,&rundt. as run_date 
 /** cps claim **/ 
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '1' day and run_date  THEN 1 ELSE 0 END) AS cnt_cps_open_claim_1d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '3' day and run_date  THEN 1 ELSE 0 END) AS cnt_cps_open_claim_3d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '7' day and run_date  THEN 1 ELSE 0 END) AS cnt_cps_open_claim_7d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '30' day and run_date  THEN 1 ELSE 0 END) AS cnt_cps_open_claim_30d
    
                                           
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '1' day and run_date  THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_claim_1d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '3' day and run_date  THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_claim_3d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '7' day and run_date  THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_claim_7d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '30' day and run_date  THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_claim_30d
                                           
 /*** cps esc claim **/ 
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '1' day and run_date  THEN 1 ELSE 0 END) AS cnt_cps_esc_claim_1d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '3' day and run_date  THEN 1 ELSE 0 END) AS cnt_cps_esc_claim_3d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '7' day and run_date  THEN 1 ELSE 0 END) AS cnt_cps_esc_claim_7d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '30' day and run_date  THEN 1 ELSE 0 END) AS cnt_cps_esc_claim_30d
                           
						   
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '1' day and run_date  THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_claim_1d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '3' day and run_date  THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_claim_3d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '7' day and run_date  THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_claim_7d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '30' day and run_date  THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_claim_30d
  
  /*********first esc party*****/
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '1' day and run_date  and first_esc_party in ('Seller') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_sr_claim_1d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '3' day and run_date  and first_esc_party in ('Seller') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_sr_claim_3d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '7' day and run_date  and first_esc_party in ('Seller') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_sr_claim_7d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '30' day and run_date  and first_esc_party in ('Seller') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_sr_claim_30d
  
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '1' day and run_date  and first_esc_party in ('Buyer') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_byr_claim_1d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '3' day and run_date  and first_esc_party in ('Buyer') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_byr_claim_3d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '7' day and run_date  and first_esc_party in ('Buyer') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_byr_claim_7d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '30' day and run_date  and first_esc_party in ('Buyer') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_byr_claim_30d
  
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '1' day and run_date  and first_esc_party in ('Seller') THEN 1  ELSE 0 END) AS cnt_cps_esc_sr_claim_1d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '3' day and run_date  and first_esc_party in ('Seller') THEN 1  ELSE 0 END) AS cnt_cps_esc_sr_claim_3d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '7' day and run_date  and first_esc_party in ('Seller') THEN 1  ELSE 0 END) AS cnt_cps_esc_sr_claim_7d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '30' day and run_date  and first_esc_party in ('Seller') THEN 1  ELSE 0 END) AS cnt_cps_esc_sr_claim_30d
                                                                                                                               
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '1' day and run_date  and first_esc_party in ('Buyer') THEN 1 ELSE 0 END) AS cnt_cps_esc_byr_claim_1d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '3' day and run_date  and first_esc_party in ('Buyer') THEN 1 ELSE 0 END) AS cnt_cps_esc_byr_claim_3d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '7' day and run_date  and first_esc_party in ('Buyer') THEN 1 ELSE 0 END) AS cnt_cps_esc_byr_claim_7d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '30' day and run_date  and first_esc_party in ('Buyer') THEN 1 ELSE 0 END) AS cnt_cps_esc_byr_claim_30d
  
  
  /** inr **/
  /** cps inr claim **/ 
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '1' day and run_date  and claim_type in ('INR') THEN 1 ELSE 0 END) AS cnt_cps_open_inr_clm_1d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '3' day and run_date  and claim_type in ('INR') THEN 1 ELSE 0 END) AS cnt_cps_open_inr_clm_3d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '7' day and run_date  and claim_type in ('INR') THEN 1 ELSE 0 END) AS cnt_cps_open_inr_clm_7d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '30' day and run_date  and claim_type in ('INR') THEN 1 ELSE 0 END) AS cnt_cps_open_inr_clm_30d
                                                                                                                      
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '1' day and run_date  and claim_type in ('INR') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_inr_clm_1d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '3' day and run_date  and claim_type in ('INR') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_inr_clm_3d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '7' day and run_date  and claim_type in ('INR') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_inr_clm_7d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '30' day and run_date  and claim_type in ('INR') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_inr_clm_30d
                                             
 /*** cps esc inr claim **/ 
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '1' day and run_date  and claim_type in ('INR') THEN 1 ELSE 0 END) AS cnt_cps_esc_inr_clm_1d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '3' day and run_date  and claim_type in ('INR') THEN 1 ELSE 0 END) AS cnt_cps_esc_inr_clm_3d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '7' day and run_date  and claim_type in ('INR') THEN 1 ELSE 0 END) AS cnt_cps_esc_inr_clm_7d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '30' day and run_date  and claim_type in ('INR') THEN 1 ELSE 0 END) AS cnt_cps_esc_inr_clm_30d
                                                                                                            
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '1' day and run_date  and claim_type in ('INR') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_inr_clm_1d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '3' day and run_date  and claim_type in ('INR') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_inr_clm_3d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '7' day and run_date  and claim_type in ('INR') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_inr_clm_7d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '30' day and run_date  and claim_type in ('INR') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_inr_clm_30d
  /** SNAD **/
   /** cps snad claim **/ 
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '1' day and run_date  and claim_type in ('SNAD') THEN 1 ELSE 0 END) AS cnt_cps_open_SNAD_clm_1d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '3' day and run_date  and claim_type in ('SNAD') THEN 1 ELSE 0 END) AS cnt_cps_open_SNAD_clm_3d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '7' day and run_date  and claim_type in ('SNAD') THEN 1 ELSE 0 END) AS cnt_cps_open_SNAD_clm_7d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '30' day and run_date  and claim_type in ('SNAD') THEN 1 ELSE 0 END) AS cnt_cps_open_SNAD_clm_30d
                                                                                                                      
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '1' day and run_date  and claim_type in ('SNAD') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_SNAD_clm_1d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '3' day and run_date  and claim_type in ('SNAD') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_SNAD_clm_3d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '7' day and run_date  and claim_type in ('SNAD') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_SNAD_clm_7d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '30' day and run_date  and claim_type in ('SNAD') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_open_SNAD_clm_30d
                                             
 /*** cps esc SNAD claim **/ 
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '1' day and run_date  and claim_type in ('SNAD') THEN 1 ELSE 0 END) AS cnt_cps_esc_SNAD_clm_1d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '3' day and run_date  and claim_type in ('SNAD') THEN 1 ELSE 0 END) AS cnt_cps_esc_SNAD_clm_3d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '7' day and run_date  and claim_type in ('SNAD') THEN 1 ELSE 0 END) AS cnt_cps_esc_SNAD_clm_7d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '30' day and run_date  and claim_type in ('SNAD') THEN 1 ELSE 0 END) AS cnt_cps_esc_SNAD_clm_30d
                                                                                                            
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '1' day and run_date  and claim_type in ('SNAD') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_SNAD_clm_1d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '3' day and run_date  and claim_type in ('SNAD') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_SNAD_clm_3d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '7' day and run_date  and claim_type in ('SNAD') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_SNAD_clm_7d
   ,sum(CASE WHEN cps.first_esc_date between run_date - interval '30' day and run_date  and claim_type in ('SNAD') THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_esc_SNAD_clm_30d 
  
 
   
/*** gross loss ***/
  ,sum(case when ebay_pyt_dt between &rundt. - interval '1' day and &rundt. and EBAY_PYT_USD_AMT > 0  then EBAY_PYT_USD_AMT
             	      when  slr_appl_pyt_dt between &rundt. - interval '1' day and &rundt. and slr_appl_PYT_USD_AMT > 0 then slr_appl_pyt_usd_amt
       			   when  ebay_pyt_dt between &rundt. - interval '1' day and &rundt. and byr_appl_PYT_USD_AMT > 0  then byr_appl_PYT_USD_AMT
       			  else 0 end) as gross_loss_1d
       
       
          ,sum(case when ebay_pyt_dt between &rundt. - interval '3' day and &rundt. and EBAY_PYT_USD_AMT > 0  then EBAY_PYT_USD_AMT
             	      when  slr_appl_pyt_dt between &rundt. - interval '3' day and &rundt. and slr_appl_PYT_USD_AMT > 0 then slr_appl_pyt_usd_amt
       			   when  ebay_pyt_dt between &rundt. - interval '3' day and &rundt. and byr_appl_PYT_USD_AMT > 0  then byr_appl_PYT_USD_AMT
       			  else 0 end) as gross_loss_3d
       
          ,sum(case when ebay_pyt_dt between &rundt. - interval '7' day and &rundt. and EBAY_PYT_USD_AMT > 0  then EBAY_PYT_USD_AMT
             	      when  slr_appl_pyt_dt between &rundt. - interval '7' day and &rundt. and slr_appl_PYT_USD_AMT > 0 then slr_appl_pyt_usd_amt
       			   when  ebay_pyt_dt between &rundt. - interval '7' day and &rundt. and byr_appl_PYT_USD_AMT > 0  then byr_appl_PYT_USD_AMT
       			  else 0 end) as gross_loss_7d
       
         ,sum(case when ebay_pyt_dt between &rundt. - interval '30' day and &rundt. and EBAY_PYT_USD_AMT > 0  then EBAY_PYT_USD_AMT
             	      when  slr_appl_pyt_dt between &rundt. - interval '30' day and &rundt. and slr_appl_PYT_USD_AMT > 0 then slr_appl_pyt_usd_amt
       			   when  ebay_pyt_dt between &rundt. - interval '30' day and &rundt. and byr_appl_PYT_USD_AMT > 0  then byr_appl_PYT_USD_AMT
       			  else 0 end) as gross_loss_30d  			
       			
			  
   
 /*** refund  (seller pyt = force + vlntry ****/ 
 /*
   ,sum(CASE WHEN cps.slr_vlntry_rfnd_dt between &rundt. - 1 and &rundt. THEN 1 ELSE 0 END) AS cnt_vln_rfnd_1d
   ,sum(CASE WHEN cps.slr_vlntry_rfnd_dt between &rundt. - 3 and &rundt. THEN 1 ELSE 0 END) AS cnt_vln_rfnd_3d
   ,sum(CASE WHEN cps.slr_vlntry_rfnd_dt between &rundt. - 7 and &rundt. THEN 1 ELSE 0 END) AS cnt_vln_rfnd_7d
   ,sum(CASE WHEN cps.slr_vlntry_rfnd_dt between &rundt. -30 and &rundt. THEN 1 ELSE 0 END) AS cnt_vln_rfnd_30d
  
   ,sum(CASE WHEN cps.frcd_rvrsl_dt between &rundt. - 1 and &rundt. THEN 1 ELSE 0 END) AS cnt_frcd_rfnd_1d
   ,sum(CASE WHEN cps.frcd_rvrsl_dt between &rundt. - 3 and &rundt. THEN 1 ELSE 0 END) AS cnt_frcd_rfnd_3d
   ,sum(CASE WHEN cps.frcd_rvrsl_dt between &rundt. - 7 and &rundt. THEN 1 ELSE 0 END) AS cnt_frcd_rfnd_7d
   ,sum(CASE WHEN cps.frcd_rvrsl_dt between &rundt. -30 and &rundt. THEN 1 ELSE 0 END) AS cnt_frcd_rfnd_30d
   
   ,sum(CASE WHEN cps.slr_vlntry_rfnd_dt between &rundt. - 1 and &rundt. THEN slr_vlntry_rfnd_usd_amt ELSE 0 END) AS amt_vln_rfnd_1d
   ,sum(CASE WHEN cps.slr_vlntry_rfnd_dt between &rundt. - 3 and &rundt. THEN slr_vlntry_rfnd_usd_amt ELSE 0 END) AS amt_vln_rfnd_3d
   ,sum(CASE WHEN cps.slr_vlntry_rfnd_dt between &rundt. - 7 and &rundt. THEN slr_vlntry_rfnd_usd_amt ELSE 0 END) AS amt_vln_rfnd_7d
   ,sum(CASE WHEN cps.slr_vlntry_rfnd_dt between &rundt. -30 and &rundt. THEN slr_vlntry_rfnd_usd_amt ELSE 0 END) AS amt_vln_rfnd_30d
  
   ,sum(CASE WHEN cps.frcd_rvrsl_dt between &rundt. - 1 and &rundt. THEN frcd_rvrsl_usd_amt ELSE 0 END) AS amt_frcd_rfnd_1d
   ,sum(CASE WHEN cps.frcd_rvrsl_dt between &rundt. - 3 and &rundt. THEN frcd_rvrsl_usd_amt ELSE 0 END) AS amt_frcd_rfnd_3d
   ,sum(CASE WHEN cps.frcd_rvrsl_dt between &rundt. - 7 and &rundt. THEN frcd_rvrsl_usd_amt ELSE 0 END) AS amt_frcd_rfnd_7d
   ,sum(CASE WHEN cps.frcd_rvrsl_dt between &rundt. -30 and &rundt. THEN frcd_rvrsl_usd_amt ELSE 0 END) AS amt_frcd_rfnd_30d
 */

   from &drv a
   inner join PRS_RESTRICTED_V.EBAY_TRANS_RLTD_EVENT BBE on a.slr_id = bbe.slr_id
   inner JOIN  access_views.rsltn_cps cps ON bbe.slr_id=cps.slr_id AND bbe.item_id = cps.item_id AND bbe.trans_id = cps.tran_id
   where CK_TRAN_CRE_DT BETWEEN &RUNDT. - INTERVAL '180' DAY AND &RUNDT. and  bbe.trans_dt BETWEEN &RUNDT. - INTERVAL '180' DAY AND &RUNDT. and bbe.bbe_elgb_trans_ind = 1    
   group by 1,2
   order by 1,2
   );


create table  raw.ebay_usar_lstg_&ind as select * from connection to td
  (SEL 
	DRV.slr_id
  ,drv.run_date

  
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '1' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4) THEN 1 ELSE 0 END) AS CNT_NEW_LSTNG_1D    
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '3' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4) THEN 1 ELSE 0 END) AS CNT_NEW_LSTNG_3D 
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '7' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4) THEN 1 ELSE 0 END) AS CNT_NEW_LSTNG_7D 
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '30' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4) THEN 1 ELSE 0 END) AS CNT_NEW_LSTNG_30D 
  
  /** FP listing **/
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '1' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4)  and auct_type_code in (7,9) THEN 1 ELSE 0 END) AS CNT_NEW_FP_LSTNG_1D    
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '3' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4)  and auct_type_code in (7,9) THEN 1 ELSE 0 END) AS CNT_NEW_FP_LSTNG_3D 
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '7' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4)  and auct_type_code in (7,9) THEN 1 ELSE 0 END) AS CNT_NEW_FP_LSTNG_7D 
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '30' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4) and auct_type_code in (7,9) THEN 1 ELSE 0 END) AS CNT_NEW_FP_LSTNG_30D 

  /** BIN listing **/ 
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '1' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4)  and auct_type_code in (1,2) and bin_price_usd>0  THEN 1 ELSE 0 END) AS CNT_NEW_BIN_LSTNG_1D    
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '3' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4)  and auct_type_code in (1,2) and bin_price_usd>0  THEN 1 ELSE 0 END) AS CNT_NEW_BIN_LSTNG_3D 
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '7' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4)  and auct_type_code in (1,2) and bin_price_usd>0  THEN 1 ELSE 0 END) AS CNT_NEW_BIN_LSTNG_7D 
   ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN  drv.run_date - INTERVAL '30' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3, 4) and auct_type_code in (1,2) and bin_price_usd>0  THEN 1 ELSE 0 END) AS CNT_NEW_BIN_LSTNG_30D 
  
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '1' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_ENDED_LSTNG_1D
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '3' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_ENDED_LSTNG_3D
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '7' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_ENDED_LSTNG_7D
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '30' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_ENDED_LSTNG_30D
   
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '1' DAY AND drv.run_date AND QTY_SOLD>0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_SCSFL_ENDED_LSTNG_1D
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '3' DAY AND drv.run_date AND QTY_SOLD>0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_SCSFL_ENDED_LSTNG_3D
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '7' DAY AND drv.run_date AND QTY_SOLD>0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_SCSFL_ENDED_LSTNG_7D
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '30' DAY AND drv.run_date AND QTY_SOLD>0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_SCSFL_ENDED_LSTNG_30D
   
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '1' DAY AND drv.run_date AND QTY_SOLD=0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_UNSCSFL_ENDED_LSTNG_1D
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '3' DAY AND drv.run_date AND QTY_SOLD=0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_UNSCSFL_ENDED_LSTNG_3D
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '7' DAY AND drv.run_date AND QTY_SOLD=0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_UNSCSFL_ENDED_LSTNG_7D
   ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '30' DAY AND drv.run_date AND QTY_SOLD=0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_UNSCSFL_ENDED_LSTNG_30D
  	
	/** new listing amt **/
  
	,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '1' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '1' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        else 0 END) AMT_NEW_LSTNG_USD_1D
	 
	,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '3' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '3' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        else 0 END) AMT_NEW_LSTNG_USD_3D
  
    ,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '7' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '7' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        else 0 END) AMT_NEW_LSTNG_USD_7D
		
	,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '30' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '30' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        else 0 END) AMT_NEW_LSTNG_USD_30D	
     
/*** new FP listing ***/	 
	,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '1' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,9) 
              THEN QTY_AVAIL * START_PRICE_USD else 0 END) as AMT_NEW_FP_LSTNG_1D
	 
	,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '3' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,9) 
              THEN QTY_AVAIL * START_PRICE_USD else 0 END) as AMT_NEW_FP_LSTNG_3D
			  
	,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '7' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,9) 
              THEN QTY_AVAIL * START_PRICE_USD else 0 END) as AMT_NEW_FP_LSTNG_7D
			  
	,SUM(CASE WHEN cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '30' DAY AND drv.run_date AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,9) 
              THEN QTY_AVAIL * START_PRICE_USD else 0 END) as AMT_NEW_FP_LSTNG_30D
	
/** amt unscsfl_end_lsting_usd **/	
 ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '1' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '1' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        else 0 END) AMT_UNSCSFL_END_LSTNG_USD_1D
	
 ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '3' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '3' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        else 0 END) AMT_UNSCSFL_END_LSTNG_USD_3D

,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '7' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '7' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        else 0 END) AMT_UNSCSFL_END_LSTNG_USD_7D

,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '30' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '30' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        else 0 END) AMT_UNSCSFL_END_LSTNG_USD_30D
		
/** amt unscsfl_end_lsting_usd FP **/	

 ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '1' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,9) 
             THEN QTY_AVAIL * START_PRICE_USD ELSE 0 END) AMT_UNSCSFL_END_FP_LSTNG_1D		
	
 ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '3' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,9) 
             THEN QTY_AVAIL * START_PRICE_USD ELSE 0 END) AMT_UNSCSFL_END_FP_LSTNG_3D		

 ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '7' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,9) 
             THEN QTY_AVAIL * START_PRICE_USD ELSE 0 END) AMT_UNSCSFL_END_FP_LSTNG_7D		

 ,SUM(CASE WHEN lstg.AUCT_END_DATE BETWEEN drv.run_date - INTERVAL '30' DAY AND drv.run_date AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,9) 
             THEN QTY_AVAIL * START_PRICE_USD ELSE 0 END) AMT_UNSCSFL_END_FP_LSTNG_30D					 
	
  FROM 
	&DRV DRV
  LEFT JOIN 
    ACCESS_VIEWS.DW_LSTG_ITEM LSTG
  ON LSTG.SLR_ID = DRV.slr_id  
    and lstg.AUCT_END_DT >= DATE '2015-11-01' - INTERVAL '180' DAY
    and lstg.AUCT_END_DT BETWEEN drv.run_date - INTERVAL '180' DAY AND drv.run_date
    and AUCT_TYPE_CODE NOT IN (10,12,15)
  LEFT JOIN
    ACCESS_VIEWS.DW_LSTG_ITEM_COLD cold
  ON lstg.item_id = cold.item_id
    and cold.AUCT_END_DT >= DATE '2015-11-01' - INTERVAL '180' DAY
    and cold.AUCT_START_DATE BETWEEN drv.run_date - INTERVAL '180' DAY AND drv.run_date 	

  GROUP BY 1,2); 


create table  raw.ebay_usar_msg_rev_&ind. as select * from connection to td
(sel 
a.slr_id
,run_date

,sum(case when src_cre_date between run_date - interval '1'  day and run_date then 1 else 0 end) as cnt_rev_tot_msg_1d 
,sum(case when src_cre_date between run_date - interval '3'  day and run_date then 1 else 0 end) as cnt_rev_tot_msg_3d 
,sum(case when src_cre_date between run_date - interval '7'  day and run_date then 1 else 0 end) as cnt_rev_tot_msg_7d 
,sum(case when src_cre_date between run_date - interval '30' day and run_date then 1 else 0 end) as cnt_rev_tot_msg_30d 

,sum(case when src_cre_date between run_date - interval '1'  day and run_date and email_type_id in (1) then 1 else 0 end) as cnt_rev_asq_msg_1d 
,sum(case when src_cre_date between run_date - interval '3'  day and run_date and email_type_id in (1) then 1 else 0 end) as cnt_rev_asq_msg_3d 
,sum(case when src_cre_date between run_date - interval '7'  day and run_date and email_type_id in (1) then 1 else 0 end) as cnt_rev_asq_msg_7d 
,sum(case when src_cre_date between run_date - interval '30' day and run_date and email_type_id in (1) then 1 else 0 end) as cnt_rev_asq_msg_30d 

,sum(case when src_cre_date between run_date - interval '1'  day and run_date and msg_type_id in (10,12,13,20) then 1 else 0 end) as cnt_rev_neg_msg_1d 
,sum(case when src_cre_date between run_date - interval '3'  day and run_date and msg_type_id in (10,12,13,20) then 1 else 0 end) as cnt_rev_neg_msg_3d 
,sum(case when src_cre_date between run_date - interval '7'  day and run_date and msg_type_id in (10,12,13,20) then 1 else 0 end) as cnt_rev_neg_msg_7d 
,sum(case when src_cre_date between run_date - interval '30' day and run_date and msg_type_id in (10,12,13,20) then 1 else 0 end) as cnt_rev_neg_msg_30d 


From   &drv  a
left join access_views.dw_ue_email_tracking c on a.slr_id = c.rcpnt_id and item_id >=0 and src_cre_dt between run_dt - interval '30' day and run_dt
group by 1,2
); 



create table  raw.ebay_usar_msg_snd_&ind. as select * from connection to td
(sel 
a.slr_id
,run_date

,sum(case when src_cre_date between run_date - interval '1'  day and run_date then 1 else 0 end) as cnt_snd_tot_msg_1d 
,sum(case when src_cre_date between run_date - interval '3'  day and run_date then 1 else 0 end) as cnt_snd_tot_msg_3d 
,sum(case when src_cre_date between run_date - interval '7'  day and run_date then 1 else 0 end) as cnt_snd_tot_msg_7d 
,sum(case when src_cre_date between run_date - interval '30' day and run_date then 1 else 0 end) as cnt_snd_tot_msg_30d 

,sum(case when src_cre_date between run_date - interval '1'  day and run_date and email_type_id in (4) then 1 else 0 end) as cnt_snd_rsp_msg_1d 
,sum(case when src_cre_date between run_date - interval '3'  day and run_date and email_type_id in (4) then 1 else 0 end) as cnt_snd_rsp_msg_3d 
,sum(case when src_cre_date between run_date - interval '7'  day and run_date and email_type_id in (4) then 1 else 0 end) as cnt_snd_rsp_msg_7d 
,sum(case when src_cre_date between run_date - interval '30' day and run_date and email_type_id in (4) then 1 else 0 end) as cnt_snd_rsp_msg_30d 

,sum(case when src_cre_date between run_date - interval '1'  day and run_date and msg_type_id in (10,12,13,20) then 1 else 0 end) as cnt_snd_neg_msg_1d 
,sum(case when src_cre_date between run_date - interval '3'  day and run_date and msg_type_id in (10,12,13,20) then 1 else 0 end) as cnt_snd_neg_msg_3d 
,sum(case when src_cre_date between run_date - interval '7'  day and run_date and msg_type_id in (10,12,13,20) then 1 else 0 end) as cnt_snd_neg_msg_7d 
,sum(case when src_cre_date between run_date - interval '30' day and run_date and msg_type_id in (10,12,13,20) then 1 else 0 end) as cnt_snd_neg_msg_30d 


From   &drv  a
left join access_views.dw_ue_email_tracking c on a.slr_id = c.sndr_id and item_id >=0 and src_cre_dt between run_dt - interval '30' day and run_dt
group by 1,2
); 
 
 
QUIT; 
%mend;  


%pull_ebay_usar_daily(drv = P_riskmodeling_t.ebay_usar_samp_drv, rundt= run_date,ind= raw30 );

endsas;
NOTE: Compressing data set RAW.EBAY_USAR_TRAN_RAW decreased size by 57.83 percent. 
      Compressed is 1071 pages; un-compressed would require 2540 pages.
NOTE: Table RAW.EBAY_USAR_TRAN_RAW created, with 228557 rows and 90 columns.

NOTE: Compressing data set RAW.EBAY_USAR_CLAIM_RAW decreased size by 86.84 percent. 
      Compressed is 154 pages; un-compressed would require 1170 pages.
NOTE: Table RAW.EBAY_USAR_CLAIM_RAW created, with 135644 rows and 70 columns.

NOTE: Compressing data set RAW.EBAY_USAR_LSTG_RAW decreased size by 57.93 percent. 
      Compressed is 496 pages; un-compressed would require 1179 pages.
NOTE: Table RAW.EBAY_USAR_LSTG_RAW created, with 228557 rows and 42 columns.

NOTE: Compressing data set RAW.EBAY_USAR_RISKCAT_RAW decreased size by 71.14 percent. 
      Compressed is 437 pages; un-compressed would require 1514 pages.
NOTE: Table RAW.EBAY_USAR_RISKCAT_RAW created, with 228557 rows and 54 columns.
/*** message buyer and restriction suspension **/


