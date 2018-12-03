
options compress=yes ls=max ps=max pageno=1 errors=10 nocenter ; *symbolgen mlogic mprint;
%put NOTE: PID of this session is &sysjobid..;


filename pwfile "~/tera_pwf.txt";

data _null_;
  infile pwfile obs=1 length=l;
  input @;
  input @1 line $varying1024.  l;
  call symput('tdbpass',substr(line,1,l));
  
run;


libname scratch teradata user=&sysuserid PASSWORD="&tdbpass" TDPID="mz2" DATABASE=p_riskdecision_t	OVERRIDE_RESP_LEN=YES DBCOMMIT=0;
libname raw '/ebaysr/projects/EG/model/data';

/** pull all risk trans **/

%let drv = p_ebay_eg_t.qp_acct_drv_0131;  /** created in pg4_perf **/
 

proc sql;
  connect to teradata as td(user=&sysuserid password="&tdbpass." tdpid="mz2" database=access_views);


create table  raw.qp_all_tran as select * from connection to td
(sel 
a.slr_id
,run_date
,bbe.trans_dt
,B2C_C2C_FLAG
,case when dedup_defect_type_flag in ('ESCALATED INR','ESCALATED SNAD')  or  CPS_NET_LOSS_USD_AMT > 25 then 1 else 0 end as perf_bad
,ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) as GMV  
,ITEM_PRICE_NUM  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) as asp  
,grp.CATEG_LVL2_NAME
,grp.categ_lvl2_id
,grp.leaf_categ_id
,grp.leaf_categ_name
,bbe.sap_category_id
,1 as wgt 
From   &drv  a
left join PRS_RESTRICTED_V.EBAY_TRANS_RLTD_EVENT BBE on a.slr_id = bbe.slr_id
left join access_views.DW_CATEGORY_GROUPINGS GRP ON BBE.LEAF_CATEG_ID=GRP.LEAF_CATEG_ID AND BBE.ITEM_LSTD_SITE_ID  =GRP.SITE_ID
where bbe.bbe_elgb_trans_ind = 1 
	and	trans_dt between '2015-04-01' and '2016-01-31'
	and asp >= 25
); 
quit;

proc freq;
table perf_bad b2c_c2c_flag;
run;

proc sort data = raw.qp_all_tran = test nodupkey;
by slr_id;
run;


endsas;

  
data raw.risk_group_sap;
set scratch.risk_cat;
run;

endsas;


