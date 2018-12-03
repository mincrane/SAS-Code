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


libname raw  '/ebaysr/projects/QP_MODEL/data';



/*********************** listing  daily      ********************/
%macro pull_ebay_qp_daily(drv = , rundt= ,ind= );


*%include "risk_cat_daily.sas";  /** created by risk grouping code **/


proc sql;
  connect to teradata as td(user=&sysuserid password="&tdbpass." tdpid="mz2" database=access_views);


 %macro norun;
create table  raw.qp_tran_&ind as select * from connection to td
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
,sum(case when bbe.EBAY_ODR_SRC_CRE_DT between &rundt. -1  and &rundt. and (EBAY_SNAD_IND = 'Y' or EBAY_INR_IND = 'Y') then 1 else 0 end) as CNT_Ebay_CLAIM_1D  
,sum(case when bbe.EBAY_ODR_SRC_CRE_DT between &rundt. -3  and &rundt. and (EBAY_SNAD_IND = 'Y' or EBAY_INR_IND = 'Y') then 1 else 0 end) as CNT_Ebay_CLAIM_3D  
,sum(case when bbe.EBAY_ODR_SRC_CRE_DT between &rundt. -7  and &rundt. and (EBAY_SNAD_IND = 'Y' or EBAY_INR_IND = 'Y') then 1 else 0 end) as CNT_Ebay_CLAIM_7D  
,sum(case when bbe.EBAY_ODR_SRC_CRE_DT between &rundt. -30 and &rundt. and (EBAY_SNAD_IND = 'Y' or EBAY_INR_IND = 'Y') then 1 else 0 end) as CNT_Ebay_CLAIM_30D  

,sum(case when bbe.paypal_case_open_dt between &rundt. -1  and &rundt. and (PAYPAL_SNAD_IND = 'Y' or PAYPAL_INR_IND = 'Y') then 1 else 0 end) as CNT_PAYPAL_CLAIM_1D  
,sum(case when bbe.paypal_case_open_dt between &rundt. -3  and &rundt. and (PAYPAL_SNAD_IND = 'Y' or PAYPAL_INR_IND = 'Y') then 1 else 0 end) as CNT_PAYPAL_CLAIM_3D  
,sum(case when bbe.paypal_case_open_dt between &rundt. -7  and &rundt. and (PAYPAL_SNAD_IND = 'Y' or PAYPAL_INR_IND = 'Y') then 1 else 0 end) as CNT_PAYPAL_CLAIM_7D  
,sum(case when bbe.paypal_case_open_dt between &rundt. -30 and &rundt. and (PAYPAL_SNAD_IND = 'Y' or PAYPAL_INR_IND = 'Y') then 1 else 0 end) as CNT_PAYPAL_CLAIM_30D  

,sum(case when bbe.CPS_FIRST_ESC_DT between &rundt. -1  and &rundt. and CPS_CLAIM_TYPE_CD in (1,2) then 1 else 0 end) as CNT_CPS_ESC_CLAIM_1D  
,sum(case when bbe.CPS_FIRST_ESC_DT between &rundt. -3  and &rundt. and CPS_CLAIM_TYPE_CD in (1,2) then 1 else 0 end) as CNT_CPS_ESC_CLAIM_3D  
,sum(case when bbe.CPS_FIRST_ESC_DT between &rundt. -7  and &rundt. and CPS_CLAIM_TYPE_CD in (1,2) then 1 else 0 end) as CNT_CPS_ESC_CLAIM_7D  
,sum(case when bbe.CPS_FIRST_ESC_DT between &rundt. -30 and &rundt. and CPS_CLAIM_TYPE_CD in (1,2) then 1 else 0 end) as CNT_CPS_ESC_CLAIM_30D  

,sum(case when bbe.CPS_CLAIM_OPEN_DT between &rundt. -1  and &rundt. and CPS_CLAIM_TYPE_CD in (1,2) then 1 else 0 end) as CNT_CPS_OPEN_CLAIM_1D  
,sum(case when bbe.CPS_CLAIM_OPEN_DT between &rundt. -3  and &rundt. and CPS_CLAIM_TYPE_CD in (1,2) then 1 else 0 end) as CNT_CPS_OPEN_CLAIM_3D  
,sum(case when bbe.CPS_CLAIM_OPEN_DT between &rundt. -7  and &rundt. and CPS_CLAIM_TYPE_CD in (1,2) then 1 else 0 end) as CNT_CPS_OPEN_CLAIM_7D  
,sum(case when bbe.CPS_CLAIM_OPEN_DT between &rundt. -30 and &rundt. and CPS_CLAIM_TYPE_CD in (1,2) then 1 else 0 end) as CNT_CPS_OPEN_CLAIM_30D  

,sum(case when bbe.rtrn_open_DT between &rundt. -1  and &rundt. and rtrn_id is not null and rtrn_rsn_cd in (4,5,6,8,9,10,14,15,16) then 1 else 0 end) as cnt_rtrn_claim_1D  
,sum(case when bbe.rtrn_open_DT between &rundt. -3  and &rundt. and rtrn_id is not null and rtrn_rsn_cd in (4,5,6,8,9,10,14,15,16) then 1 else 0 end) as cnt_rtrn_claim_3D  
,sum(case when bbe.rtrn_open_DT between &rundt. -7  and &rundt. and rtrn_id is not null and rtrn_rsn_cd in (4,5,6,8,9,10,14,15,16) then 1 else 0 end) as cnt_rtrn_claim_7D  
,sum(case when bbe.rtrn_open_DT between &rundt. -30 and &rundt. and rtrn_id is not null and rtrn_rsn_cd in (4,5,6,8,9,10,14,15,16) then 1 else 0 end) as cnt_rtrn_claim_30D  

/** esc snad **/
,sum(
  case when BBE.EBAY_SNAD_IND = 'Y'      and BBE.EBAY_ODR_SRC_CRE_DT between &rundt. -1  and &rundt. THEN 1
	   when BBE.PAYPAL_SNAD_IND = 'Y'    and BBE.PAYPAL_CASE_OPEN_DT between &rundt. -1  and &rundt. THEN 1 
	   when BBE.CPS_CLAIM_TYPE_CD = 2    and BBE.CPS_FIRST_ESC_DT    between &rundt. -1  and &rundt. THEN 1
	else 0 end) as CNT_ESC_SNAD_CLAIM_1D

,sum(
  case when BBE.EBAY_SNAD_IND = 'Y'      and BBE.EBAY_ODR_SRC_CRE_DT between &rundt. -3  and &rundt. THEN 1
	   when BBE.PAYPAL_SNAD_IND = 'Y'    and BBE.PAYPAL_CASE_OPEN_DT between &rundt. -3  and &rundt. THEN 1 
	   when BBE.CPS_CLAIM_TYPE_CD = 2    and BBE.CPS_FIRST_ESC_DT    between &rundt. -3  and &rundt. THEN 1
	else 0 end) as CNT_ESC_SNAD_CLAIM_3D
 
,sum(
  case when BBE.EBAY_SNAD_IND = 'Y'      and BBE.EBAY_ODR_SRC_CRE_DT between &rundt. -7  and &rundt. THEN 1
	   when BBE.PAYPAL_SNAD_IND = 'Y'    and BBE.PAYPAL_CASE_OPEN_DT between &rundt. -7  and &rundt. THEN 1 
	   when BBE.CPS_CLAIM_TYPE_CD = 2    and BBE.CPS_FIRST_ESC_DT    between &rundt. -7  and &rundt. THEN 1
	else 0 end) as CNT_ESC_SNAD_CLAIM_7D

,sum(
  case when BBE.EBAY_SNAD_IND = 'Y'      and BBE.EBAY_ODR_SRC_CRE_DT between &rundt. -30  and &rundt. THEN 1
	   when BBE.PAYPAL_SNAD_IND = 'Y'    and BBE.PAYPAL_CASE_OPEN_DT between &rundt. -30  and &rundt. THEN 1 
	   when BBE.CPS_CLAIM_TYPE_CD = 2    and BBE.CPS_FIRST_ESC_DT    between &rundt. -30  and &rundt. THEN 1
	else 0 end) as CNT_ESC_SNAD_CLAIM_30D


,sum(
  case when BBE.EBAY_INR_IND = 'Y'      and BBE.EBAY_ODR_SRC_CRE_DT between &rundt. -1  and &rundt. THEN 1
	   when BBE.PAYPAL_INR_IND = 'Y'    and BBE.PAYPAL_CASE_OPEN_DT between &rundt. -1  and &rundt. THEN 1 
	   when BBE.CPS_CLAIM_TYPE_CD = 1    and BBE.CPS_FIRST_ESC_DT   between &rundt. -1  and &rundt. THEN 1
	else 0 end) as CNT_ESC_INR_CLAIM_1D
	
,sum(
  case when BBE.EBAY_INR_IND = 'Y'      and BBE.EBAY_ODR_SRC_CRE_DT between &rundt. -3  and &rundt. THEN 1
	   when BBE.PAYPAL_INR_IND = 'Y'    and BBE.PAYPAL_CASE_OPEN_DT between &rundt. -3  and &rundt. THEN 1 
	   when BBE.CPS_CLAIM_TYPE_CD = 1    and BBE.CPS_FIRST_ESC_DT   between &rundt. -3  and &rundt. THEN 1
	else 0 end) as CNT_ESC_INR_CLAIM_3D

,sum(
  case when BBE.EBAY_INR_IND = 'Y'      and BBE.EBAY_ODR_SRC_CRE_DT between &rundt. -7  and &rundt. THEN 1
	   when BBE.PAYPAL_INR_IND = 'Y'    and BBE.PAYPAL_CASE_OPEN_DT between &rundt. -7  and &rundt. THEN 1 
	   when BBE.CPS_CLAIM_TYPE_CD = 1    and BBE.CPS_FIRST_ESC_DT   between &rundt. -7  and &rundt. THEN 1
	else 0 end) as CNT_ESC_INR_CLAIM_7D	
	
	
,sum(
  case when BBE.EBAY_INR_IND = 'Y'      and BBE.EBAY_ODR_SRC_CRE_DT between &rundt. -30  and &rundt. THEN 1
	   when BBE.PAYPAL_INR_IND = 'Y'    and BBE.PAYPAL_CASE_OPEN_DT between &rundt. -30  and &rundt. THEN 1 
	   when BBE.CPS_CLAIM_TYPE_CD = 1   and BBE.CPS_FIRST_ESC_DT    between &rundt. -30  and &rundt. THEN 1
	else 0 end) as CNT_ESC_INR_CLAIM_30D

/*** Defects  AMT **********/

,sum(case when bbe.EBAY_ODR_SRC_CRE_DT between &rundt. -1  and &rundt. and (EBAY_SNAD_IND = 'Y' or EBAY_INR_IND = 'Y') then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_Ebay_CLAIM_1D  
,sum(case when bbe.EBAY_ODR_SRC_CRE_DT between &rundt. -3  and &rundt. and (EBAY_SNAD_IND = 'Y' or EBAY_INR_IND = 'Y') then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_Ebay_CLAIM_3D  
,sum(case when bbe.EBAY_ODR_SRC_CRE_DT between &rundt. -7  and &rundt. and (EBAY_SNAD_IND = 'Y' or EBAY_INR_IND = 'Y') then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_Ebay_CLAIM_7D  
,sum(case when bbe.EBAY_ODR_SRC_CRE_DT between &rundt. -30 and &rundt. and (EBAY_SNAD_IND = 'Y' or EBAY_INR_IND = 'Y') then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_Ebay_CLAIM_30D  

,sum(case when bbe.paypal_case_open_dt between &rundt. -1  and &rundt. and (PAYPAL_SNAD_IND = 'Y' or PAYPAL_INR_IND = 'Y') then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_PAYPAL_CLAIM_1D
,sum(case when bbe.paypal_case_open_dt between &rundt. -3  and &rundt. and (PAYPAL_SNAD_IND = 'Y' or PAYPAL_INR_IND = 'Y') then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_PAYPAL_CLAIM_3D  
,sum(case when bbe.paypal_case_open_dt between &rundt. -7  and &rundt. and (PAYPAL_SNAD_IND = 'Y' or PAYPAL_INR_IND = 'Y') then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_PAYPAL_CLAIM_7D  
,sum(case when bbe.paypal_case_open_dt between &rundt. -30 and &rundt. and (PAYPAL_SNAD_IND = 'Y' or PAYPAL_INR_IND = 'Y') then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_PAYPAL_CLAIM_30D  

,sum(case when bbe.CPS_FIRST_ESC_DT between &rundt. -1  and &rundt. and CPS_CLAIM_TYPE_CD in (1,2) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_CPS_ESC_CLAIM_1D 
,sum(case when bbe.CPS_FIRST_ESC_DT between &rundt. -3  and &rundt. and CPS_CLAIM_TYPE_CD in (1,2) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_CPS_ESC_CLAIM_3D  
,sum(case when bbe.CPS_FIRST_ESC_DT between &rundt. -7  and &rundt. and CPS_CLAIM_TYPE_CD in (1,2) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_CPS_ESC_CLAIM_7D  
,sum(case when bbe.CPS_FIRST_ESC_DT between &rundt. -30 and &rundt. and CPS_CLAIM_TYPE_CD in (1,2) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_CPS_ESC_CLAIM_30D  

,sum(case when bbe.CPS_CLAIM_OPEN_DT between &rundt. -1  and &rundt. and CPS_CLAIM_TYPE_CD in (1,2) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_CPS_OPEN_CLAIM_1D 
,sum(case when bbe.CPS_CLAIM_OPEN_DT between &rundt. -3  and &rundt. and CPS_CLAIM_TYPE_CD in (1,2) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_CPS_OPEN_CLAIM_3D  
,sum(case when bbe.CPS_CLAIM_OPEN_DT between &rundt. -7  and &rundt. and CPS_CLAIM_TYPE_CD in (1,2) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_CPS_OPEN_CLAIM_7D  
,sum(case when bbe.CPS_CLAIM_OPEN_DT between &rundt. -30 and &rundt. and CPS_CLAIM_TYPE_CD in (1,2) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_CPS_OPEN_CLAIM_30D  

,sum(case when bbe.rtrn_open_DT between &rundt. -1  and &rundt. and rtrn_id is not null and rtrn_rsn_cd in (4,5,6,8,9,10,14,15,16) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_rtrn_claim_1D  
,sum(case when bbe.rtrn_open_DT between &rundt. -3  and &rundt. and rtrn_id is not null and rtrn_rsn_cd in (4,5,6,8,9,10,14,15,16) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_rtrn_claim_3D  
,sum(case when bbe.rtrn_open_DT between &rundt. -7  and &rundt. and rtrn_id is not null and rtrn_rsn_cd in (4,5,6,8,9,10,14,15,16) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_rtrn_claim_7D  
,sum(case when bbe.rtrn_open_DT between &rundt. -30 and &rundt. and rtrn_id is not null and rtrn_rsn_cd in (4,5,6,8,9,10,14,15,16) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_rtrn_claim_30D  



/** esc snad **/
,sum(
  case when BBE.EBAY_SNAD_IND = 'Y'      and BBE.EBAY_ODR_SRC_CRE_DT between &rundt. -1  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2))
	   when BBE.PAYPAL_SNAD_IND = 'Y'    and BBE.PAYPAL_CASE_OPEN_DT between &rundt. -1  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) 
	   when BBE.CPS_CLAIM_TYPE_CD = 2    and BBE.CPS_FIRST_ESC_DT    between &rundt. -1  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2))
	else 0 end) as AMT_ESC_SNAD_CLAIM_1D


,sum(
  case when BBE.EBAY_SNAD_IND = 'Y'      and BBE.EBAY_ODR_SRC_CRE_DT between &rundt. -3  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2))
	   when BBE.PAYPAL_SNAD_IND = 'Y'    and BBE.PAYPAL_CASE_OPEN_DT between &rundt. -3  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) 
	   when BBE.CPS_CLAIM_TYPE_CD = 2    and BBE.CPS_FIRST_ESC_DT    between &rundt. -3  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2))
	else 0 end) as AMT_ESC_SNAD_CLAIM_3D
 
,sum(
  case when BBE.EBAY_SNAD_IND = 'Y'      and BBE.EBAY_ODR_SRC_CRE_DT between &rundt. -7  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2))
	   when BBE.PAYPAL_SNAD_IND = 'Y'    and BBE.PAYPAL_CASE_OPEN_DT between &rundt. -7  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) 
	   when BBE.CPS_CLAIM_TYPE_CD = 2    and BBE.CPS_FIRST_ESC_DT    between &rundt. -7  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2))
	else 0 end) as AMT_ESC_SNAD_CLAIM_7D

,sum(
  case when BBE.EBAY_SNAD_IND = 'Y'      and BBE.EBAY_ODR_SRC_CRE_DT between &rundt. -30  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2))
	   when BBE.PAYPAL_SNAD_IND = 'Y'    and BBE.PAYPAL_CASE_OPEN_DT between &rundt. -30  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) 
	   when BBE.CPS_CLAIM_TYPE_CD = 2    and BBE.CPS_FIRST_ESC_DT    between &rundt. -30  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2))
	else 0 end) as AMT_ESC_SNAD_CLAIM_30D

,sum(
  case when BBE.EBAY_INR_IND = 'Y'      and BBE.EBAY_ODR_SRC_CRE_DT between &rundt. -1  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2))
	   when BBE.PAYPAL_INR_IND = 'Y'    and BBE.PAYPAL_CASE_OPEN_DT between &rundt. -1  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) 
	   when BBE.CPS_CLAIM_TYPE_CD = 1    and BBE.CPS_FIRST_ESC_DT   between &rundt. -1  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2))
	else 0 end) as AMT_ESC_INR_CLAIM_1D

	
,sum(
  case when BBE.EBAY_INR_IND = 'Y'      and BBE.EBAY_ODR_SRC_CRE_DT between &rundt. -3  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2))
	   when BBE.PAYPAL_INR_IND = 'Y'    and BBE.PAYPAL_CASE_OPEN_DT between &rundt. -3  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) 
	   when BBE.CPS_CLAIM_TYPE_CD = 1    and BBE.CPS_FIRST_ESC_DT   between &rundt. -3  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2))
	else 0 end) as AMT_ESC_INR_CLAIM_3D

,sum(
  case when BBE.EBAY_INR_IND = 'Y'      and BBE.EBAY_ODR_SRC_CRE_DT between &rundt. -7  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2))
	   when BBE.PAYPAL_INR_IND = 'Y'    and BBE.PAYPAL_CASE_OPEN_DT between &rundt. -7  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) 
	   when BBE.CPS_CLAIM_TYPE_CD = 1    and BBE.CPS_FIRST_ESC_DT   between &rundt. -7  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2))
	else 0 end) as AMT_ESC_INR_CLAIM_7D	
	
	
	
,sum(
  case when BBE.EBAY_INR_IND = 'Y'      and BBE.EBAY_ODR_SRC_CRE_DT between &rundt. -30  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2))
	   when BBE.PAYPAL_INR_IND = 'Y'    and BBE.PAYPAL_CASE_OPEN_DT between &rundt. -30  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) 
	   when BBE.CPS_CLAIM_TYPE_CD = 1   and BBE.CPS_FIRST_ESC_DT    between &rundt. -30  and &rundt. then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2))
	else 0 end) as AMT_ESC_INR_CLAIM_30D
	

/*** CBT ***/
,sum(case when bbe.TRANS_DT between &rundt. -1  and &rundt. and CBT_IND = 1 then 1 else 0 end) as CNT_HIST_CBT_TXN_1D  
,sum(case when bbe.TRANS_DT between &rundt. -3  and &rundt. and CBT_IND = 1 then 1 else 0 end) as CNT_HIST_CBT_TXN_3D  
,sum(case when bbe.TRANS_DT between &rundt. -7  and &rundt. and CBT_IND = 1 then 1 else 0 end) as CNT_HIST_CBT_TXN_7D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date and CBT_IND = 1 then 1 else 0 end) as CNT_HIST_CBT_TXN_30D  

,sum(case when bbe.TRANS_DT between &rundt. -1  and &rundt. and CBT_IND = 1 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_CBT_GMV_1D  
,sum(case when bbe.TRANS_DT between &rundt. -3  and &rundt. and CBT_IND = 1 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_CBT_GMV_3D  
,sum(case when bbe.TRANS_DT between &rundt. -7  and &rundt. and CBT_IND = 1 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_CBT_GMV_7D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date and CBT_IND = 1 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as HIST_CBT_GMV_30D  

/*** ASP ***/
,avg(case when bbe.TRANS_DT between &rundt. -1  and &rundt. then ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) end) as asp_1D  
,avg(case when bbe.TRANS_DT between &rundt. -3  and &rundt. then ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) end) as asp_3D  
,avg(case when bbe.TRANS_DT between &rundt. -7  and &rundt. then ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) end) as asp_7D  
,avg(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date then ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) end) as asp_30D

/*** high ASP tran change ***/
,sum(case when bbe.TRANS_DT between &rundt. -1  and &rundt. and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then 1 else 0 end) as CNT_HASP_TXN_1D  
,sum(case when bbe.TRANS_DT between &rundt. -3  and &rundt. and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then 1 else 0 end) as CNT_HASP_TXN_3D  
,sum(case when bbe.TRANS_DT between &rundt. -7  and &rundt. and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then 1 else 0 end) as CNT_HASP_TXN_7D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then 1 else 0 end) as CNT_HASP_TXN_30D  

,sum(case when bbe.TRANS_DT between &rundt. -1  and &rundt. and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_GMV_1D  
,sum(case when bbe.TRANS_DT between &rundt. -3  and &rundt. and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_GMV_3D  
,sum(case when bbe.TRANS_DT between &rundt. -7  and &rundt. and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_GMV_7D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >100 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_GMV_30D  

,sum(case when bbe.TRANS_DT between &rundt. -1  and &rundt. and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then 1 else 0 end) as CNT_HASP_gt2_TXN_1D  
,sum(case when bbe.TRANS_DT between &rundt. -3  and &rundt. and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then 1 else 0 end) as CNT_HASP_gt2_TXN_3D  
,sum(case when bbe.TRANS_DT between &rundt. -7  and &rundt. and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then 1 else 0 end) as CNT_HASP_gt2_TXN_7D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then 1 else 0 end) as CNT_HASP_gt2_TXN_30D  

,sum(case when bbe.TRANS_DT between &rundt. -1  and &rundt. and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_gt2_GMV_1D  
,sum(case when bbe.TRANS_DT between &rundt. -3  and &rundt. and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_gt2_GMV_3D  
,sum(case when bbe.TRANS_DT between &rundt. -7  and &rundt. and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_gt2_GMV_7D  
,sum(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date and ITEM_PRICE_NUM * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) >200 then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HASP_gt2_GMV_30D  



	
/** Feedback **/
,sum(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -1  and &rundt. and (ORGNL_FDBK_OVRL_RTG_ID in(1,2,3) or BYR_FDBK_OVRL_RTNG_ID in (1,2,3) ) then 1 else 0 end) as CNT_SLR_TOT_FDBK_1D  
,sum(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -3  and &rundt. and (ORGNL_FDBK_OVRL_RTG_ID in(1,2,3) or BYR_FDBK_OVRL_RTNG_ID in (1,2,3) ) then 1 else 0 end) as CNT_SLR_TOT_FDBK_3D  
,sum(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -7  and &rundt. and (ORGNL_FDBK_OVRL_RTG_ID in(1,2,3) or BYR_FDBK_OVRL_RTNG_ID in (1,2,3) ) then 1 else 0 end) as CNT_SLR_TOT_FDBK_7D  
,sum(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -30 and &rundt. and (ORGNL_FDBK_OVRL_RTG_ID in(1,2,3) or BYR_FDBK_OVRL_RTNG_ID in (1,2,3) ) then 1 else 0 end) as CNT_SLR_TOT_FDBK_30D  

,sum(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -1  and &rundt. and (ORGNL_FDBK_OVRL_RTG_ID = 1 or BYR_FDBK_OVRL_RTNG_ID = 1) then 1 else 0 end) as CNT_SLR_PSTV_FDBK_1D  
,sum(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -3  and &rundt. and (ORGNL_FDBK_OVRL_RTG_ID = 1 or BYR_FDBK_OVRL_RTNG_ID = 1) then 1 else 0 end) as CNT_SLR_PSTV_FDBK_3D  
,sum(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -7  and &rundt. and (ORGNL_FDBK_OVRL_RTG_ID = 1 or BYR_FDBK_OVRL_RTNG_ID = 1) then 1 else 0 end) as CNT_SLR_PSTV_FDBK_7D 
,sum(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -30 and &rundt. and (ORGNL_FDBK_OVRL_RTG_ID = 1 or BYR_FDBK_OVRL_RTNG_ID = 1) then 1 else 0 end) as CNT_SLR_PSTV_FDBK_30D 

,sum(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -1  and &rundt. and (ORGNL_FDBK_OVRL_RTG_ID = 2 or BYR_FDBK_OVRL_RTNG_ID = 2) then 1 else 0 end) as CNT_SLR_NGTV_FDBK_1D  
,sum(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -3  and &rundt. and (ORGNL_FDBK_OVRL_RTG_ID = 2 or BYR_FDBK_OVRL_RTNG_ID = 2) then 1 else 0 end) as CNT_SLR_NGTV_FDBK_3D  
,sum(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -7  and &rundt. and (ORGNL_FDBK_OVRL_RTG_ID = 2 or BYR_FDBK_OVRL_RTNG_ID = 2) then 1 else 0 end) as CNT_SLR_NGTV_FDBK_7D 
,sum(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -30 and &rundt. and (ORGNL_FDBK_OVRL_RTG_ID = 2 or BYR_FDBK_OVRL_RTNG_ID = 2) then 1 else 0 end) as CNT_SLR_NGTV_FDBK_30D 

,sum(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -1  and &rundt. and (ORGNL_FDBK_OVRL_RTG_ID = 3 or BYR_FDBK_OVRL_RTNG_ID = 3) then 1 else 0 end) as CNT_SLR_NTRL_FDBK_1D  
,sum(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -3  and &rundt. and (ORGNL_FDBK_OVRL_RTG_ID = 3 or BYR_FDBK_OVRL_RTNG_ID = 3) then 1 else 0 end) as CNT_SLR_NTRL_FDBK_3D  
,sum(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -7  and &rundt. and (ORGNL_FDBK_OVRL_RTG_ID = 3 or BYR_FDBK_OVRL_RTNG_ID = 3) then 1 else 0 end) as CNT_SLR_NTRL_FDBK_7D 
,sum(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -30 and &rundt. and (ORGNL_FDBK_OVRL_RTG_ID = 3 or BYR_FDBK_OVRL_RTNG_ID = 3) then 1 else 0 end) as CNT_SLR_NTRL_FDBK_30D 

/*** Rating IAD,COM,SHP CHRG and ST ***/
,avg(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -1  and &rundt. and ORGNL_ITEM_AS_DSCRBD_RTG_NUM > 0 then ORGNL_ITEM_AS_DSCRBD_RTG_NUM end) as AVE_IAD_DSR_1D 
,avg(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -3  and &rundt. and ORGNL_ITEM_AS_DSCRBD_RTG_NUM > 0 then ORGNL_ITEM_AS_DSCRBD_RTG_NUM end) as AVE_IAD_DSR_3D  
,avg(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -7  and &rundt. and ORGNL_ITEM_AS_DSCRBD_RTG_NUM > 0 then ORGNL_ITEM_AS_DSCRBD_RTG_NUM end) as AVE_IAD_DSR_7D  
,avg(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -30 and &rundt. and ORGNL_ITEM_AS_DSCRBD_RTG_NUM > 0 then ORGNL_ITEM_AS_DSCRBD_RTG_NUM end) as AVE_IAD_DSR_30D  

,avg(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -1  and &rundt. and ORGNL_COM_RTG_VAL_NUM > 0 then ORGNL_COM_RTG_VAL_NUM end) as AVE_COM_DSR_1D  
,avg(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -3  and &rundt. and ORGNL_COM_RTG_VAL_NUM > 0 then ORGNL_COM_RTG_VAL_NUM end) as AVE_COM_DSR_3D  
,avg(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -7  and &rundt. and ORGNL_COM_RTG_VAL_NUM > 0 then ORGNL_COM_RTG_VAL_NUM end) as AVE_COM_DSR_7D  
,avg(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -30 and &rundt. and ORGNL_COM_RTG_VAL_NUM > 0 then ORGNL_COM_RTG_VAL_NUM end) as AVE_COM_DSR_30D  

,avg(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -1  and &rundt. and ORGNL_SHPNG_TM_RTG_VAL_NUM > 0 then ORGNL_SHPNG_TM_RTG_VAL_NUM end) as AVE_ST_DSR_1D 
,avg(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -3  and &rundt. and ORGNL_SHPNG_TM_RTG_VAL_NUM > 0 then ORGNL_SHPNG_TM_RTG_VAL_NUM end) as AVE_ST_DSR_3D  
,avg(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -7  and &rundt. and ORGNL_SHPNG_TM_RTG_VAL_NUM > 0 then ORGNL_SHPNG_TM_RTG_VAL_NUM end) as AVE_ST_DSR_7D  
,avg(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -30 and &rundt. and ORGNL_SHPNG_TM_RTG_VAL_NUM > 0 then ORGNL_SHPNG_TM_RTG_VAL_NUM end) as AVE_ST_DSR_30D  

,avg(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -1  and &rundt. and ORGNL_SHPNG_CHRG_RTG_VAL_NUM > 0 then ORGNL_SHPNG_CHRG_RTG_VAL_NUM end) as AVE_SHPNG_CHRG_DSR_1D  
,avg(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -3  and &rundt. and ORGNL_SHPNG_CHRG_RTG_VAL_NUM > 0 then ORGNL_SHPNG_CHRG_RTG_VAL_NUM end) as AVE_SHPNG_CHRG_DSR_3D  
,avg(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -7  and &rundt. and ORGNL_SHPNG_CHRG_RTG_VAL_NUM > 0 then ORGNL_SHPNG_CHRG_RTG_VAL_NUM end) as AVE_SHPNG_CHRG_DSR_7D  
,avg(case when bbe.BYR_FDBK_RCVD_DT between &rundt. -30 and &rundt. and ORGNL_SHPNG_CHRG_RTG_VAL_NUM > 0 then ORGNL_SHPNG_CHRG_RTG_VAL_NUM end) as AVE_SHPNG_CHRG_DSR_30D  


/*** FDBK Score *****/
,avg(case when bbe.TRANS_DT between &rundt. -1  and &rundt. then cast(SLR_FDBK_SCORE_NUM as decimal(18,1)) end) as AVE_SLR_FDBK_SCORE_1D 
,avg(case when bbe.TRANS_DT between &rundt. -3  and &rundt. then cast(SLR_FDBK_SCORE_NUM as decimal(18,1)) end) as AVE_SLR_FDBK_SCORE_3D  
,avg(case when bbe.TRANS_DT between &rundt. -7  and &rundt. then cast(SLR_FDBK_SCORE_NUM as decimal(18,1)) end) as AVE_SLR_FDBK_SCORE_7D  
,avg(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date then cast(SLR_FDBK_SCORE_NUM as decimal(18,1)) end) as AVE_SLR_FDBK_SCORE_30D  

,avg(case when bbe.TRANS_DT between &rundt. -1  and &rundt. then cast(SLR_FDBK_SCORE_AS_SLR_NUM as decimal(18,1) ) end) as AVE_SLR_FDBK_SCORE_AS_SLR_1D                                                                   
,avg(case when bbe.TRANS_DT between &rundt. -3  and &rundt. then cast(SLR_FDBK_SCORE_AS_SLR_NUM as decimal(18,1) ) end) as AVE_SLR_FDBK_SCORE_AS_SLR_3D  
,avg(case when bbe.TRANS_DT between &rundt. -7  and &rundt. then cast(SLR_FDBK_SCORE_AS_SLR_NUM as decimal(18,1) ) end) as AVE_SLR_FDBK_SCORE_AS_SLR_7D  
,avg(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date then cast(SLR_FDBK_SCORE_AS_SLR_NUM as decimal(18,1) ) end) as AVE_SLR_FDBK_SCORE_AS_SLR_30D  

,avg(case when bbe.TRANS_DT between &rundt. -1  and &rundt. then cast(BYR_FDBK_SCORE_NUM as decimal(18,1)) end) as AVE_BYR_FDBK_SCORE_1D                                                                 
,avg(case when bbe.TRANS_DT between &rundt. -3  and &rundt. then cast(BYR_FDBK_SCORE_NUM as decimal(18,1)) end) as AVE_BYR_FDBK_SCORE_3D  
,avg(case when bbe.TRANS_DT between &rundt. -7  and &rundt. then cast(BYR_FDBK_SCORE_NUM as decimal(18,1)) end) as AVE_BYR_FDBK_SCORE_7D  
,avg(case when (cast(bbe.TRANS_DT as timestamp(0)) + (trans_tm - time '00:00:00' hour to second) ) between run_date - interval '30'  day and run_date then cast(BYR_FDBK_SCORE_NUM as decimal(18,1)) end) as AVE_BYR_FDBK_SCORE_30D  

From   &drv  a
left join PRS_RESTRICTED_V.EBAY_TRANS_RLTD_EVENT BBE on a.slr_id = bbe.slr_id

where bbe.bbe_elgb_trans_ind = 1  
      and bbe.trans_dt BETWEEN &RUNDT. - INTERVAL '180' DAY AND &RUNDT. 
group by 1,2
order by 1,2
);

%mend;

/**** Gross Loss,CPS claim, refund ******/
create table  raw.qp_gloss_&ind as select * from connection to td
  (sel  
   a.slr_id
   ,&rundt. as run_date 
 /** cps claim **/ 
   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. - 1 and &rundt. THEN 1 ELSE 0 END) AS cnt_cps_claim_1d
   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. - 3 and &rundt. THEN 1 ELSE 0 END) AS cnt_cps_claim_3d
   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. - 7 and &rundt. THEN 1 ELSE 0 END) AS cnt_cps_claim_7d
   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. -30 and &rundt. THEN 1 ELSE 0 END) AS cnt_cps_claim_30d
   
   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. - 1 and &rundt. and claim_fault_type_txt = 'Seller Fault' THEN 1 ELSE 0 END) AS cnt_cps_sf_claim_1d
   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. - 3 and &rundt. and claim_fault_type_txt = 'Seller Fault' THEN 1 ELSE 0 END) AS cnt_cps_sf_claim_3d
   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. - 7 and &rundt. and claim_fault_type_txt = 'Seller Fault' THEN 1 ELSE 0 END) AS cnt_cps_sf_claim_7d
   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. -30 and &rundt. and claim_fault_type_txt = 'Seller Fault' THEN 1 ELSE 0 END) AS cnt_cps_sf_claim_30d

   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. - 1 and &rundt. and resolution = 'SMIR' THEN 1 ELSE 0 END) AS cnt_cps_smir_claim_1d 
   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. - 3 and &rundt. and resolution = 'SMIR' THEN 1 ELSE 0 END) AS cnt_cps_smir_claim_3d
   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. - 7 and &rundt. and resolution = 'SMIR' THEN 1 ELSE 0 END) AS cnt_cps_smir_claim_7d
   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. -30 and &rundt. and resolution = 'SMIR' THEN 1 ELSE 0 END) AS cnt_cps_smir_claim_30d
   
   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. - 1 and &rundt. THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_claim_1d
   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. - 3 and &rundt. THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_claim_3d
   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. - 7 and &rundt. THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_claim_7d
   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. -30 and &rundt. THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_claim_30d
   
   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. - 1 and &rundt. and claim_fault_type_txt = 'Seller Fault' THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_sf_claim_1d
   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. - 3 and &rundt. and claim_fault_type_txt = 'Seller Fault' THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_sf_claim_3d
   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. - 7 and &rundt. and claim_fault_type_txt = 'Seller Fault' THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_sf_claim_7d
   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. -30 and &rundt. and claim_fault_type_txt = 'Seller Fault' THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_sf_claim_30d

   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. - 1 and &rundt. and resolution = 'SMIR' THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_smir_claim_1d
   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. - 3 and &rundt. and resolution = 'SMIR' THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_smir_claim_3d
   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. - 7 and &rundt. and resolution = 'SMIR' THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_smir_claim_7d
   ,sum(CASE WHEN cps.first_cps_claim_open_dt between &rundt. -30 and &rundt. and resolution = 'SMIR' THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_smir_claim_30d
   
/*** gross loss ***/
   ,sum(case when ebay_pyt_dt between &rundt. - 1 and &rundt. and EBAY_PYT_USD_AMT > 0  then EBAY_PYT_USD_AMT
      	      when  slr_appl_pyt_dt between &rundt. - 1 and &rundt. and slr_appl_PYT_USD_AMT > 0 then slr_appl_pyt_usd_amt 
			   when  ebay_pyt_dt between &rundt. - 1 and &rundt. and byr_appl_PYT_USD_AMT > 0  then byr_appl_PYT_USD_AMT
			  else 0 end) as gross_loss_1d  
   
   
   ,sum(case when ebay_pyt_dt between &rundt. - 3 and &rundt. and EBAY_PYT_USD_AMT > 0  then EBAY_PYT_USD_AMT
      	      when  slr_appl_pyt_dt between &rundt. - 3 and &rundt. and slr_appl_PYT_USD_AMT > 0 then slr_appl_pyt_usd_amt 
			   when  ebay_pyt_dt between &rundt. - 3 and &rundt. and byr_appl_PYT_USD_AMT > 0  then byr_appl_PYT_USD_AMT
			  else 0 end) as gross_loss_3d  

   ,sum(case when ebay_pyt_dt between &rundt. - 7 and &rundt. and EBAY_PYT_USD_AMT > 0  then EBAY_PYT_USD_AMT
      	      when  slr_appl_pyt_dt between &rundt. - 7 and &rundt. and slr_appl_PYT_USD_AMT > 0 then slr_appl_pyt_usd_amt 
			   when  ebay_pyt_dt between &rundt. - 7 and &rundt. and byr_appl_PYT_USD_AMT > 0  then byr_appl_PYT_USD_AMT
			  else 0 end) as gross_loss_7d  

  ,sum(case when ebay_pyt_dt between &rundt. - 30 and &rundt. and EBAY_PYT_USD_AMT > 0  then EBAY_PYT_USD_AMT
      	      when  slr_appl_pyt_dt between &rundt. - 30 and &rundt. and slr_appl_PYT_USD_AMT > 0 then slr_appl_pyt_usd_amt 
			   when  ebay_pyt_dt between &rundt. - 30 and &rundt. and byr_appl_PYT_USD_AMT > 0  then byr_appl_PYT_USD_AMT
			  else 0 end) as gross_loss_30d  			  
			  
   
 /*** refund  (seller pyt = force + vlntry ****/ 
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
 
 
   from &drv a
   left join PRS_RESTRICTED_V.EBAY_TRANS_RLTD_EVENT BBE on a.slr_id = bbe.slr_id
   LEFT JOIN  access_views.rsltn_cps cps ON bbe.slr_id=cps.slr_id AND bbe.item_id = cps.item_id AND bbe.trans_id = cps.tran_id
   where CK_TRAN_CRE_DT BETWEEN &RUNDT. - INTERVAL '180' DAY AND &RUNDT. and  bbe.trans_dt BETWEEN &RUNDT. - INTERVAL '180' DAY AND &RUNDT. and bbe.bbe_elgb_trans_ind = 1    
   group by 1,2
   order by 1,2
   );

create table  raw.qp_LSTG_&ind as select * from connection to td
  (SEL 
	DRV.slr_id
   ,&RUNDT. as run_date
   /*
   ,CASE WHEN AUCT_TYPE_CODE IN (1,2) AND  bin_price_usd > 0  THEN 'BIN'
         WHEN AUCT_TYPE_CODE IN (1,2) THEN 'AUCTION' 
		 WHEN AUCT_TYPE_CODE IN (7) THEN 'SIF' 
		 WHEN AUCT_TYPE_CODE IN (9) THEN 'FP'
		 ELSE 'Other' END as auction_type
    */
   ,SUM(CASE WHEN AUCT_START_DT BETWEEN  &RUNDT. - INTERVAL '1' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3, 4) THEN 1 ELSE NULL END) AS CNT_NEW_LSTNG_1D    
   ,SUM(CASE WHEN AUCT_START_DT BETWEEN  &RUNDT. - INTERVAL '3' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3, 4) THEN 1 ELSE NULL END) AS CNT_NEW_LSTNG_3D 
   ,SUM(CASE WHEN AUCT_START_DT BETWEEN  &RUNDT. - INTERVAL '7' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3, 4) THEN 1 ELSE NULL END) AS CNT_NEW_LSTNG_7D 
   ,SUM(CASE WHEN AUCT_START_DT BETWEEN  &RUNDT. - INTERVAL '30' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3, 4) THEN 1 ELSE NULL END) AS CNT_NEW_LSTNG_30D 
  
  /** FP listing **/
   ,SUM(CASE WHEN AUCT_START_DT BETWEEN  &RUNDT. - INTERVAL '1' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3, 4)  and auct_type_code in (7,9) THEN 1 ELSE NULL END) AS CNT_NEW_FP_LSTNG_1D    
   ,SUM(CASE WHEN AUCT_START_DT BETWEEN  &RUNDT. - INTERVAL '3' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3, 4)  and auct_type_code in (7,9) THEN 1 ELSE NULL END) AS CNT_NEW_FP_LSTNG_3D 
   ,SUM(CASE WHEN AUCT_START_DT BETWEEN  &RUNDT. - INTERVAL '7' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3, 4)  and auct_type_code in (7,9) THEN 1 ELSE NULL END) AS CNT_NEW_FP_LSTNG_7D 
   ,SUM(CASE WHEN AUCT_START_DT BETWEEN  &RUNDT. - INTERVAL '30' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3, 4) and auct_type_code in (7,9) THEN 1 ELSE NULL END) AS CNT_NEW_FP_LSTNG_30D 

  /** BIN listing **/ 
   ,SUM(CASE WHEN AUCT_START_DT BETWEEN  &RUNDT. - INTERVAL '1' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3, 4)  and auct_type_code in (1,2) and bin_price_usd>0  THEN 1 ELSE NULL END) AS CNT_NEW_BIN_LSTNG_1D    
   ,SUM(CASE WHEN AUCT_START_DT BETWEEN  &RUNDT. - INTERVAL '3' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3, 4)  and auct_type_code in (1,2) and bin_price_usd>0  THEN 1 ELSE NULL END) AS CNT_NEW_BIN_LSTNG_3D 
   ,SUM(CASE WHEN AUCT_START_DT BETWEEN  &RUNDT. - INTERVAL '7' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3, 4)  and auct_type_code in (1,2) and bin_price_usd>0  THEN 1 ELSE NULL END) AS CNT_NEW_BIN_LSTNG_7D 
   ,SUM(CASE WHEN AUCT_START_DT BETWEEN  &RUNDT. - INTERVAL '30' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3, 4) and auct_type_code in (1,2) and bin_price_usd>0  THEN 1 ELSE NULL END) AS CNT_NEW_BIN_LSTNG_30D 
  
  
  
   ,SUM(CASE WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '1'  DAY AND &RUNDT AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_ENDED_LSTNG_1D
   ,SUM(CASE WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '3'  DAY AND &RUNDT AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_ENDED_LSTNG_3D
   ,SUM(CASE WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '7'  DAY AND &RUNDT AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_ENDED_LSTNG_7D
   ,SUM(CASE WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '30' DAY AND &RUNDT AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_ENDED_LSTNG_30D
   
   ,SUM(CASE WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '1'  DAY AND &RUNDT AND QTY_SOLD>0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_SCSFL_ENDED_LSTNG_1D
   ,SUM(CASE WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '3'  DAY AND &RUNDT AND QTY_SOLD>0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_SCSFL_ENDED_LSTNG_3D
   ,SUM(CASE WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '7'  DAY AND &RUNDT AND QTY_SOLD>0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_SCSFL_ENDED_LSTNG_7D
   ,SUM(CASE WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '30' DAY AND &RUNDT AND QTY_SOLD>0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_SCSFL_ENDED_LSTNG_30D
   
   ,SUM(CASE WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '1'  DAY AND &RUNDT AND QTY_SOLD=0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_UNSCSFL_ENDED_LSTNG_1D
   ,SUM(CASE WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '3'  DAY AND &RUNDT AND QTY_SOLD=0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_UNSCSFL_ENDED_LSTNG_3D
   ,SUM(CASE WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '7'  DAY AND &RUNDT AND QTY_SOLD=0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_UNSCSFL_ENDED_LSTNG_7D
   ,SUM(CASE WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '30' DAY AND &RUNDT AND QTY_SOLD=0 AND LSTG_STATUS_ID IN (1, 2) THEN 1 ELSE 0 END) AS CNT_UNSCSFL_ENDED_LSTNG_30D
  	
	/** new listing amt **/
	,SUM(CASE WHEN AUCT_START_DT BETWEEN &RUNDT. - INTERVAL '1' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN AUCT_START_DT BETWEEN &RUNDT. - INTERVAL '1' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        END) AMT_NEW_LSTNG_USD_1D
	 
	,SUM(CASE WHEN AUCT_START_DT BETWEEN &RUNDT. - INTERVAL '3' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN AUCT_START_DT BETWEEN &RUNDT. - INTERVAL '3' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        END) AMT_NEW_LSTNG_USD_3D
  
    ,SUM(CASE WHEN AUCT_START_DT BETWEEN &RUNDT. - INTERVAL '7' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN AUCT_START_DT BETWEEN &RUNDT. - INTERVAL '7' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        END) AMT_NEW_LSTNG_USD_7D
		
	,SUM(CASE WHEN AUCT_START_DT BETWEEN &RUNDT. - INTERVAL '30' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN AUCT_START_DT BETWEEN &RUNDT. - INTERVAL '30' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        END) AMT_NEW_LSTNG_USD_30D	
     
/*** new FP listing ***/	 
	,SUM(CASE WHEN AUCT_START_DT BETWEEN &RUNDT. - INTERVAL '1' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,9) 
              THEN QTY_AVAIL * START_PRICE_USD else 0 END) as AMT_NEW_FP_LSTNG_1D
	 
	,SUM(CASE WHEN AUCT_START_DT BETWEEN &RUNDT. - INTERVAL '3' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,9) 
              THEN QTY_AVAIL * START_PRICE_USD else 0 END) as AMT_NEW_FP_LSTNG_3D
			  
	,SUM(CASE WHEN AUCT_START_DT BETWEEN &RUNDT. - INTERVAL '7' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,9) 
              THEN QTY_AVAIL * START_PRICE_USD else 0 END) as AMT_NEW_FP_LSTNG_7D
			  
	,SUM(CASE WHEN AUCT_START_DT BETWEEN &RUNDT. - INTERVAL '30' DAY AND &RUNDT. AND LSTG_STATUS_ID NOT IN (3,4) AND AUCT_TYPE_CODE IN (7,9) 
              THEN QTY_AVAIL * START_PRICE_USD else 0 END) as AMT_NEW_FP_LSTNG_30D


/** amt unscsfl_end_lsting_usd **/	
 ,SUM(CASE WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '1' DAY AND &RUNDT. AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '1' DAY AND &RUNDT. AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        END) AMT_UNSCSFL_END_LSTNG_USD_1D
	
 ,SUM(CASE WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '3' DAY AND &RUNDT. AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '3' DAY AND &RUNDT. AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        END) AMT_UNSCSFL_END_LSTNG_USD_3D

,SUM(CASE WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '7' DAY AND &RUNDT. AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '7' DAY AND &RUNDT. AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        END) AMT_UNSCSFL_END_LSTNG_USD_7D

,SUM(CASE WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '30' DAY AND &RUNDT. AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,8,9) 
             THEN QTY_AVAIL * START_PRICE_USD
             WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '30' DAY AND &RUNDT. AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (1,2,3,5,13) 
             THEN (CASE WHEN RSRV_PRICE_USD = 0.00 THEN QTY_AVAIL * START_PRICE_USD
                    ELSE QTY_AVAIL * RSRV_PRICE_USD END) 
        END) AMT_UNSCSFL_END_LSTNG_USD_30D

		
/** amt unscsfl_end_lsting_usd FP **/	
 ,SUM(CASE WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '1' DAY AND &RUNDT. AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,9) 
             THEN QTY_AVAIL * START_PRICE_USD ELSE 0 END) AMT_UNSCSFL_END_FP_LSTNG_1D		
	
 ,SUM(CASE WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '3' DAY AND &RUNDT. AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,9) 
             THEN QTY_AVAIL * START_PRICE_USD ELSE 0 END) AMT_UNSCSFL_END_FP_LSTNG_3D		

 ,SUM(CASE WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '7' DAY AND &RUNDT. AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,9) 
             THEN QTY_AVAIL * START_PRICE_USD ELSE 0 END) AMT_UNSCSFL_END_FP_LSTNG_7D		

 ,SUM(CASE WHEN AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '30' DAY AND &RUNDT. AND LSTG_STATUS_ID IN (1,2) AND QTY_SOLD=0 AND AUCT_TYPE_CODE IN (7,9) 
             THEN QTY_AVAIL * START_PRICE_USD ELSE 0 END) AMT_UNSCSFL_END_FP_LSTNG_30D					 
		
  FROM 
	&DRV DRV
  INNER JOIN 
    ACCESS_VIEWS.DW_LSTG_ITEM LSTG
  ON LSTG.SLR_ID = DRV.slr_id  
  
  WHERE 
     LSTG.AUCT_END_DT BETWEEN &RUNDT. - INTERVAL '60' DAY AND &RUNDT. 
	 and AUCT_TYPE_CODE NOT IN (10,12,15)
	
  GROUP BY 1,2
  ORDER BY 1,2); 


  
QUIT; 
%mend;



endsas;

   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval ' 1' day and run_date  and claim_fault_type_txt = 'Seller Fault' THEN 1 ELSE 0 END) AS cnt_cps_sf_claim_1d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval ' 3' day and run_date  and claim_fault_type_txt = 'Seller Fault' THEN 1 ELSE 0 END) AS cnt_cps_sf_claim_3d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval ' 7' day and run_date  and claim_fault_type_txt = 'Seller Fault' THEN 1 ELSE 0 END) AS cnt_cps_sf_claim_7d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '30' day and run_date  and claim_fault_type_txt = 'Seller Fault' THEN 1 ELSE 0 END) AS cnt_cps_sf_claim_30d
                                               
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval ' 1' day and run_date  and resolution = 'SMIR' THEN 1 ELSE 0 END) AS cnt_cps_smir_claim_1d 
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval ' 3' day and run_date  and resolution = 'SMIR' THEN 1 ELSE 0 END) AS cnt_cps_smir_claim_3d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval ' 7' day and run_date  and resolution = 'SMIR' THEN 1 ELSE 0 END) AS cnt_cps_smir_claim_7d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '30' day and run_date  and resolution = 'SMIR' THEN 1 ELSE 0 END) AS cnt_cps_smir_claim_30d

   
    ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval ' 1' day and run_date  and claim_fault_type_txt = 'Seller Fault' THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_sf_claim_1d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval ' 3' day and run_date  and claim_fault_type_txt = 'Seller Fault' THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_sf_claim_3d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval ' 7' day and run_date  and claim_fault_type_txt = 'Seller Fault' THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_sf_claim_7d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '30' day and run_date  and claim_fault_type_txt = 'Seller Fault' THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_sf_claim_30d
                                              
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval ' 1' day and run_date  and resolution = 'SMIR' THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_smir_claim_1d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval ' 3' day and run_date  and resolution = 'SMIR' THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_smir_claim_3d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval ' 7' day and run_date  and resolution = 'SMIR' THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_smir_claim_7d
   ,sum(CASE WHEN cps.first_cps_claim_open_date between run_date - interval '30' day and run_date  and resolution = 'SMIR' THEN elgbl_claim_usd_amt ELSE 0 END) AS amt_cps_smir_claim_30d
   
   
   
   ,sum(case when (cast(bbe.EBAY_ODR_SRC_CRE_DT as timestamp(0)) + (bbe.EBAY_ODR_SRC_CRE_TM - time '00:00:00' hour to second) ) between run_date - interval '1' day and run_date  and (EBAY_SNAD_IND = 'Y' or EBAY_INR_IND = 'Y') then 1 else 0 end) as CNT_Ebay_CLAIM_1D  
,sum(case when (cast(bbe.EBAY_ODR_SRC_CRE_DT as timestamp(0)) + (bbe.EBAY_ODR_SRC_CRE_TM - time '00:00:00' hour to second) ) between run_date - interval '3' day and run_date  and (EBAY_SNAD_IND = 'Y' or EBAY_INR_IND = 'Y') then 1 else 0 end) as CNT_Ebay_CLAIM_3D  
,sum(case when (cast(bbe.EBAY_ODR_SRC_CRE_DT as timestamp(0)) + (bbe.EBAY_ODR_SRC_CRE_TM - time '00:00:00' hour to second) ) between run_date - interval '7' day and run_date  and (EBAY_SNAD_IND = 'Y' or EBAY_INR_IND = 'Y') then 1 else 0 end) as CNT_Ebay_CLAIM_7D  
,sum(case when (cast(bbe.EBAY_ODR_SRC_CRE_DT as timestamp(0)) + (bbe.EBAY_ODR_SRC_CRE_TM - time '00:00:00' hour to second) ) between run_date - interval '30' day and run_date  and (EBAY_SNAD_IND = 'Y' or EBAY_INR_IND = 'Y') then 1 else 0 end) as CNT_Ebay_CLAIM_30D    


,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '1' day and run_date and CPS_CLAIM_TYPE_CD in (1,2) then 1 else 0 end) as CNT_CPS_ESC_CLAIM_1D  
,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '3' day and run_date and CPS_CLAIM_TYPE_CD in (1,2) then 1 else 0 end) as CNT_CPS_ESC_CLAIM_3D  
,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '7' day and run_date and CPS_CLAIM_TYPE_CD in (1,2) then 1 else 0 end) as CNT_CPS_ESC_CLAIM_7D  
,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '30' day and run_date and CPS_CLAIM_TYPE_CD in (1,2) then 1 else 0 end) as CNT_CPS_ESC_CLAIM_30D  


,sum(case when (cast(bbe.CPS_CLAIM_OPEN_DT as timestamp(0)) + (bbe.CPS_CLAIM_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '1' day  and run_date and CPS_CLAIM_TYPE_CD in (1,2) then 1 else 0 end) as CNT_CPS_OPEN_CLAIM_1D  
,sum(case when (cast(bbe.CPS_CLAIM_OPEN_DT as timestamp(0)) + (bbe.CPS_CLAIM_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '3' day  and run_date and CPS_CLAIM_TYPE_CD in (1,2) then 1 else 0 end) as CNT_CPS_OPEN_CLAIM_3D  
,sum(case when (cast(bbe.CPS_CLAIM_OPEN_DT as timestamp(0)) + (bbe.CPS_CLAIM_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '7' day  and run_date and CPS_CLAIM_TYPE_CD in (1,2) then 1 else 0 end) as CNT_CPS_OPEN_CLAIM_7D  
,sum(case when (cast(bbe.CPS_CLAIM_OPEN_DT as timestamp(0)) + (bbe.CPS_CLAIM_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '30' day and run_date and CPS_CLAIM_TYPE_CD in (1,2) then 1 else 0 end) as CNT_CPS_OPEN_CLAIM_30D  

,sum(case when (cast(bbe.RTRN_OPEN_DT as timestamp(0)) + (bbe.RTRN_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '1' day  and run_date and rtrn_id is not null and rtrn_rsn_cd in (4,5,6,8,9,10,14,15,16) then 1 else 0 end) as cnt_rtrn_claim_1D  
,sum(case when (cast(bbe.RTRN_OPEN_DT as timestamp(0)) + (bbe.RTRN_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '3' day  and run_date and rtrn_id is not null and rtrn_rsn_cd in (4,5,6,8,9,10,14,15,16) then 1 else 0 end) as cnt_rtrn_claim_3D  
,sum(case when (cast(bbe.RTRN_OPEN_DT as timestamp(0)) + (bbe.RTRN_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '7' day  and run_date and rtrn_id is not null and rtrn_rsn_cd in (4,5,6,8,9,10,14,15,16) then 1 else 0 end) as cnt_rtrn_claim_7D  
,sum(case when (cast(bbe.RTRN_OPEN_DT as timestamp(0)) + (bbe.RTRN_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '30' day and run_date and rtrn_id is not null and rtrn_rsn_cd in (4,5,6,8,9,10,14,15,16) then 1 else 0 end) as cnt_rtrn_claim_30D  

/** open/esc inr/snad **/

,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '1'  day and run_date and CPS_CLAIM_TYPE_CD in (1)  then 1 else 0 end) as CNT_CPS_ESC_INR_CLAIM_1D  
,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '3'  day and run_date and CPS_CLAIM_TYPE_CD in (1)  then 1 else 0 end) as CNT_CPS_ESC_INR_CLAIM_3D  
,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '7'  day and run_date and CPS_CLAIM_TYPE_CD in (1)  then 1 else 0 end) as CNT_CPS_ESC_INR_CLAIM_7D  
,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '30' day and run_date and CPS_CLAIM_TYPE_CD in (1)  then 1 else 0 end) as CNT_CPS_ESC_INR_CLAIM_30D  


,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '1'  day and run_date and CPS_CLAIM_TYPE_CD in (2)  then 1 else 0 end) as CNT_CPS_ESC_SNAD_CLAIM_1D  
,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '3'  day and run_date and CPS_CLAIM_TYPE_CD in (2)  then 1 else 0 end) as CNT_CPS_ESC_SNAD_CLAIM_3D  
,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '7'  day and run_date and CPS_CLAIM_TYPE_CD in (2)  then 1 else 0 end) as CNT_CPS_ESC_SNAD_CLAIM_7D  
,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '30' day and run_date and CPS_CLAIM_TYPE_CD in (2)  then 1 else 0 end) as CNT_CPS_ESC_SNAD_CLAIM_30D  


,sum(case when (cast(bbe.CPS_CLAIM_OPEN_DT as timestamp(0)) + (bbe.CPS_CLAIM_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '1'  day and run_date and CPS_CLAIM_TYPE_CD in (1) then 1 else 0 end) as CNT_CPS_OPEN_INR_CLAIM_1D  
,sum(case when (cast(bbe.CPS_CLAIM_OPEN_DT as timestamp(0)) + (bbe.CPS_CLAIM_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '3'  day and run_date and CPS_CLAIM_TYPE_CD in (1) then 1 else 0 end) as CNT_CPS_OPEN_INR_CLAIM_3D  
,sum(case when (cast(bbe.CPS_CLAIM_OPEN_DT as timestamp(0)) + (bbe.CPS_CLAIM_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '7'  day and run_date and CPS_CLAIM_TYPE_CD in (1) then 1 else 0 end) as CNT_CPS_OPEN_INR_CLAIM_7D  
,sum(case when (cast(bbe.CPS_CLAIM_OPEN_DT as timestamp(0)) + (bbe.CPS_CLAIM_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '30' day and run_date and CPS_CLAIM_TYPE_CD in (1) then 1 else 0 end) as CNT_CPS_OPEN_INR_CLAIM_30D  

,sum(case when (cast(bbe.CPS_CLAIM_OPEN_DT as timestamp(0)) + (bbe.CPS_CLAIM_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '1'  day  and run_date and CPS_CLAIM_TYPE_CD in (2) then 1 else 0 end) as CNT_CPS_OPEN_SNAD_CLAIM_1D  
,sum(case when (cast(bbe.CPS_CLAIM_OPEN_DT as timestamp(0)) + (bbe.CPS_CLAIM_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '3'  day  and run_date and CPS_CLAIM_TYPE_CD in (2) then 1 else 0 end) as CNT_CPS_OPEN_SNAD_CLAIM_3D  
,sum(case when (cast(bbe.CPS_CLAIM_OPEN_DT as timestamp(0)) + (bbe.CPS_CLAIM_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '7'  day  and run_date and CPS_CLAIM_TYPE_CD in (2) then 1 else 0 end) as CNT_CPS_OPEN_SNAD_CLAIM_7D  
,sum(case when (cast(bbe.CPS_CLAIM_OPEN_DT as timestamp(0)) + (bbe.CPS_CLAIM_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '30' day  and run_date and CPS_CLAIM_TYPE_CD in (2) then 1 else 0 end) as CNT_CPS_OPEN_SNAD_CLAIM_30D  



/*** Defects  AMT **********/

,sum(case when (cast(bbe.EBAY_ODR_SRC_CRE_DT as timestamp(0)) + (bbe.EBAY_ODR_SRC_CRE_TM - time '00:00:00' hour to second) ) between run_date - interval '1' day and run_date  and (EBAY_SNAD_IND = 'Y' or EBAY_INR_IND = 'Y') then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_Ebay_CLAIM_1D  
,sum(case when (cast(bbe.EBAY_ODR_SRC_CRE_DT as timestamp(0)) + (bbe.EBAY_ODR_SRC_CRE_TM - time '00:00:00' hour to second) ) between run_date - interval '3' day and run_date  and (EBAY_SNAD_IND = 'Y' or EBAY_INR_IND = 'Y') then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_Ebay_CLAIM_3D  
,sum(case when (cast(bbe.EBAY_ODR_SRC_CRE_DT as timestamp(0)) + (bbe.EBAY_ODR_SRC_CRE_TM - time '00:00:00' hour to second) ) between run_date - interval '7' day and run_date  and (EBAY_SNAD_IND = 'Y' or EBAY_INR_IND = 'Y') then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_Ebay_CLAIM_7D  
,sum(case when (cast(bbe.EBAY_ODR_SRC_CRE_DT as timestamp(0)) + (bbe.EBAY_ODR_SRC_CRE_TM - time '00:00:00' hour to second) ) between run_date - interval '30' day and run_date  and (EBAY_SNAD_IND = 'Y' or EBAY_INR_IND = 'Y') then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_Ebay_CLAIM_30D  


,sum(case when ,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '1' day and run_date and CPS_CLAIM_TYPE_CD in (1,2) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_CPS_ESC_CLAIM_1D 
,sum(case when ,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '3' day and run_date and CPS_CLAIM_TYPE_CD in (1,2) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_CPS_ESC_CLAIM_3D  
,sum(case when ,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '7' day and run_date and CPS_CLAIM_TYPE_CD in (1,2) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_CPS_ESC_CLAIM_7D  
,sum(case when ,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '30' day and run_date and CPS_CLAIM_TYPE_CD in (1,2) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_CPS_ESC_CLAIM_30D  


,sum(case when bbe.CPS_CLAIM_OPEN_DT between &rundt. -1  and &rundt. and CPS_CLAIM_TYPE_CD in (1,2) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_CPS_OPEN_CLAIM_1D 
,sum(case when bbe.CPS_CLAIM_OPEN_DT between &rundt. -3  and &rundt. and CPS_CLAIM_TYPE_CD in (1,2) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_CPS_OPEN_CLAIM_3D  
,sum(case when bbe.CPS_CLAIM_OPEN_DT between &rundt. -7  and &rundt. and CPS_CLAIM_TYPE_CD in (1,2) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_CPS_OPEN_CLAIM_7D  
,sum(case when bbe.CPS_CLAIM_OPEN_DT between &rundt. -30 and &rundt. and CPS_CLAIM_TYPE_CD in (1,2) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_CPS_OPEN_CLAIM_30D  

,sum(case when (cast(bbe.RTRN_OPEN_DT as timestamp(0)) + (bbe.RTRN_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '1' day  and run_date and rtrn_id is not null and rtrn_rsn_cd in (4,5,6,8,9,10,14,15,16) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_rtrn_claim_1D  
,sum(case when (cast(bbe.RTRN_OPEN_DT as timestamp(0)) + (bbe.RTRN_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '3' day  and run_date and rtrn_id is not null and rtrn_rsn_cd in (4,5,6,8,9,10,14,15,16) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_rtrn_claim_3D  
,sum(case when (cast(bbe.RTRN_OPEN_DT as timestamp(0)) + (bbe.RTRN_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '7' day  and run_date and rtrn_id is not null and rtrn_rsn_cd in (4,5,6,8,9,10,14,15,16) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_rtrn_claim_7D  
,sum(case when (cast(bbe.RTRN_OPEN_DT as timestamp(0)) + (bbe.RTRN_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '30' day and run_date and rtrn_id is not null and rtrn_rsn_cd in (4,5,6,8,9,10,14,15,16) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_rtrn_claim_30D  


/** AMT esc/open snad/INR **/
,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '1'  day and run_date and CPS_CLAIM_TYPE_CD in (1)  then cps_claim_amt*cps_claim_exchng_rate else 0 end) as AMT_CPS_ESC_INR_CLAIM_1D  
,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '3'  day and run_date and CPS_CLAIM_TYPE_CD in (1)  then cps_claim_amt*cps_claim_exchng_rate else 0 end) as AMT_CPS_ESC_INR_CLAIM_3D  
,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '7'  day and run_date and CPS_CLAIM_TYPE_CD in (1)  then cps_claim_amt*cps_claim_exchng_rate else 0 end) as AMT_CPS_ESC_INR_CLAIM_7D  
,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '30' day and run_date and CPS_CLAIM_TYPE_CD in (1)  then cps_claim_amt*cps_claim_exchng_rate else 0 end) as AMT_CPS_ESC_INR_CLAIM_30D  


,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '1'  day and run_date and CPS_CLAIM_TYPE_CD in (2)  then cps_claim_amt*cps_claim_exchng_rate else 0 end) as AMT_CPS_ESC_SNAD_CLAIM_1D  
,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '3'  day and run_date and CPS_CLAIM_TYPE_CD in (2)  then cps_claim_amt*cps_claim_exchng_rate else 0 end) as AMT_CPS_ESC_SNAD_CLAIM_3D  
,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '7'  day and run_date and CPS_CLAIM_TYPE_CD in (2)  then cps_claim_amt*cps_claim_exchng_rate else 0 end) as AMT_CPS_ESC_SNAD_CLAIM_7D  
,sum(case when (cast(bbe.CPS_FIRST_ESC_DT as timestamp(0)) + (bbe.CPS_FIRST_ESC_TM - time '00:00:00' hour to second)) between run_date - interval '30' day and run_date and CPS_CLAIM_TYPE_CD in (2)  then cps_claim_amt*cps_claim_exchng_rate else 0 end) as AMT_CPS_ESC_SNAD_CLAIM_30D  


,sum(case when (cast(bbe.CPS_CLAIM_OPEN_DT as timestamp(0)) + (bbe.CPS_CLAIM_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '1'  day and run_date and CPS_CLAIM_TYPE_CD in (1) then cps_claim_amt*cps_claim_exchng_rate else 0 end) as AMT_CPS_OPEN_INR_CLAIM_1D  
,sum(case when (cast(bbe.CPS_CLAIM_OPEN_DT as timestamp(0)) + (bbe.CPS_CLAIM_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '3'  day and run_date and CPS_CLAIM_TYPE_CD in (1) then cps_claim_amt*cps_claim_exchng_rate else 0 end) as AMT_CPS_OPEN_INR_CLAIM_3D  
,sum(case when (cast(bbe.CPS_CLAIM_OPEN_DT as timestamp(0)) + (bbe.CPS_CLAIM_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '7'  day and run_date and CPS_CLAIM_TYPE_CD in (1) then cps_claim_amt*cps_claim_exchng_rate else 0 end) as AMT_CPS_OPEN_INR_CLAIM_7D  
,sum(case when (cast(bbe.CPS_CLAIM_OPEN_DT as timestamp(0)) + (bbe.CPS_CLAIM_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '30' day and run_date and CPS_CLAIM_TYPE_CD in (1) then cps_claim_amt*cps_claim_exchng_rate else 0 end) as AMT_CPS_OPEN_INR_CLAIM_30D  

,sum(case when (cast(bbe.CPS_CLAIM_OPEN_DT as timestamp(0)) + (bbe.CPS_CLAIM_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '1'  day  and run_date and CPS_CLAIM_TYPE_CD in (2) then cps_claim_amt*cps_claim_exchng_rate else 0 end) as AMT_CPS_OPEN_SNAD_CLAIM_1D  
,sum(case when (cast(bbe.CPS_CLAIM_OPEN_DT as timestamp(0)) + (bbe.CPS_CLAIM_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '3'  day  and run_date and CPS_CLAIM_TYPE_CD in (2) then cps_claim_amt*cps_claim_exchng_rate else 0 end) as AMT_CPS_OPEN_SNAD_CLAIM_3D  
,sum(case when (cast(bbe.CPS_CLAIM_OPEN_DT as timestamp(0)) + (bbe.CPS_CLAIM_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '7'  day  and run_date and CPS_CLAIM_TYPE_CD in (2) then cps_claim_amt*cps_claim_exchng_rate else 0 end) as AMT_CPS_OPEN_SNAD_CLAIM_7D  
,sum(case when (cast(bbe.CPS_CLAIM_OPEN_DT as timestamp(0)) + (bbe.CPS_CLAIM_OPEN_TM - time '00:00:00' hour to second)) between run_date - interval '30' day  and run_date and CPS_CLAIM_TYPE_CD in (2) then cps_claim_amt*cps_claim_exchng_rate else 0 end) as AMT_CPS_OPEN_SNAD_CLAIM_30D  
	

   
   
   
   
   
   

