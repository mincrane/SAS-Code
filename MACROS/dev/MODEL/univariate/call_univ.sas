
options compress=yes obs=max ls=max ps=max pageno=1 errors=10 nocenter; * symbolgen mlogic mprint;


%let _macropath= /ebaysr/MACROS/dev/model_lib/;
%include "&_macropath./ebsr_univariate_macro_v1.sas";

data new;
set raw.b2c_data;

if flag_pop_excl_final = 0;
*wgt = 1;
drop
slr_id
run_date
TRANS_DT       
USER_CNTRY_ID  
USER_CRE_DATE  
USER_CRE_DATE0 
USER_SITE_ID 
run_mth_id
tag_dt  
;

run;

%univ(datin = new, perfvar = perf_eg_bad ,bad = 1 ,wgt = wgt, exclout = eg_b2c_univ,datout = univ_b2c);

/*
%include "&_macropath./univariate/univariate_macro.sas";
%univ(dset=modeling,oset=seg1,perf=perf_bad,weight=wgt);  
*/

