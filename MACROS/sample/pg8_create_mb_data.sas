options compress=yes obs=max ls=max ps=max pageno=1 errors=10 nocenter NODATE NONOTES nonumber; * symbolgen mlogic mprint;
%put NOTE: PID of this session is &sysjobid..;

libname raw  '/ebaysr/projects/arus/data';

/*
proc contents data = raw.ebay_usar_genvar;
run;
*/

proc sql;
create table raw.usar_all_var as
select 
 a.flag_perf_60d
,a.PERF_net_loss_30d           
,a.PERF_net_loss_60d           
,a.PERF_net_loss_90d           
,a.SLR_ID                      
,a.SamplingWeight              
,a.flag_mob                    
,a.orig_mob                    
,a.perf_CNT_TXN_30D            
,a.perf_CNT_TXN_60D            
,a.perf_CNT_TXN_90D            
,a.perf_GMV_30D                
,a.perf_GMV_60D                
,a.perf_GMV_90D                
,a.perf_amt_esc_claim_30d      
,a.perf_amt_esc_claim_60d      
,a.perf_amt_esc_claim_90d      
,a.perf_amt_open_claim_30d     
,a.perf_amt_open_claim_60d     
,a.perf_amt_open_claim_90d     
,a.perf_cnt_esc_claim_30d      
,a.perf_cnt_esc_claim_60d      
,a.perf_cnt_esc_claim_90d      
,a.perf_cnt_open_claim_30d     
,a.perf_cnt_open_claim_60d     
,a.perf_cnt_open_claim_90d     
,a.perf_flag_60d               
,a.perf_gross_loss_30          
,a.perf_gross_loss_60          
,a.perf_gross_loss_90          
,a.perf_total_gloss_30         
,a.perf_total_gloss_60         
,a.perf_total_gloss_90         
,a.run_date                    
,a.run_dt                      
,a.seg_cd                      
,a.seg_flag
,b.*
from raw.usar_modeling_drv a
inner join raw.ebay_usar_genvar b
on a.slr_id = b.slr_id and a.run_date = b.run_date;
quit;

data raw.seg1_gt25_gt12 raw.seg2_gt25_le12 raw.seg3_le25_gt12 raw.seg4_le25_le12 raw.seg5_LE1k;
set raw.usar_all_var;
if seg_flag = 1 then output raw.seg1_gt25_gt12;
if seg_flag = 2 then output raw.seg2_gt25_le12;
if seg_flag = 3 then output raw.seg3_le25_gt12;
if seg_flag = 4 then output raw.seg4_le25_le12;
if seg_flag = 5 then output raw.seg5_LE1k;
run;

proc freq data = raw.seg1_gt25_gt12;
table flag_perf_60d;
weight samplingweight;
run;


proc freq data = raw.seg1_gt25_gt12;
table flag_perf_60d;
run;


proc freq data = raw.seg2_gt25_le12;
table flag_perf_60d;
weight samplingweight;
run;

proc freq data = raw.seg2_gt25_le12;
table flag_perf_60d;
run;


proc freq data = raw.seg3_le25_gt12;
table flag_perf_60d;
weight samplingweight;
run;

proc freq data = raw.seg3_le25_gt12;
table flag_perf_60d;
run;

proc freq data = raw.seg4_le25_le12;
table flag_perf_60d;
weight samplingweight;
run;

proc freq data = raw.seg4_le25_le12;
table flag_perf_60d;
run;


endsas;
/*********** test message *****************/






                    
