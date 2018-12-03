options compress=yes obs=max ls=max ps=max pageno=1 errors=10 nocenter NODATE NONOTES nonumber; * symbolgen mlogic mprint;
%put NOTE: PID of this session is &sysjobid..;

libname raw  '/ebaysr/projects/arus/data';


%include '/ebaysr/MACROS/release/Beh_Macros.sas';      

/*** 2016 + 252 **/


*%macro dd;

/** impute missings by 0 **/

data ebay_usar_all;
set raw.ebay_usar_data_raw;
array allvar{*} _numeric_;
do i = 1 to dim(allvar);
if missing(allvar{i}) = 1 then allvar{i} = 0;
end;
run;  


data raw.ebay_usar_genvar;
set ebay_usar_all;
%include 'ebay_usar_daily_var_gen.txt' ;   */source2;

%Ratio(asp_1d,max_asp_360,rat_asp_1d_max,100,0.01,label= Ratio 1 day to max daily asp); 
%Ratio(hist_gmv_1d,max_daily_gmv_360,rat_gmv_1d_max,100,0.01,label= Ratio 1 day to max daily GMV);
%Ratio(cnt_hist_txn_1d,max_daily_txn_360,rat_cnt_txn_1d_max,100,0.01,label= Ratio 1 day to max cnt txn);


drop
rat_CNT_low_risk_b2c_30D_360d
rat_AMT_low_risk_b2c_30D_360d
rat_CNT_low_risk_c2c_30D_360d
rat_AMT_low_risk_c2c_30D_360d
rat_CNT_high_risk_c2c_30D_360d
rat_AMT_high_risk_c2c_30D_360d
rat_CNT_high_risk_b2c_30D_360d
rat_AMT_high_risk_b2c_30D_360d

CNT_low_risk_b2c_360d
AMT_low_risk_b2c_360d
CNT_low_risk_c2c_360d
AMT_low_risk_c2c_360d
CNT_high_risk_c2c_360d
AMT_high_risk_c2c_360d
CNT_high_risk_b2c_360d
AMT_high_risk_b2c_360d


AMT_high_risk_dor_360D            
CNT_high_risk_dor_360D            
chg_a_high_risk_b2c_30D_360D      
chg_a_high_risk_c2c_30D_360D      
chg_a_high_risk_dor_30D_360D      
chg_c_high_risk_b2c_30D_360D      
chg_c_high_risk_c2c_30D_360D      
chg_c_high_risk_dor_30D_360D      
rat_AMT_HIGH_RISK_B2C_360D        
rat_AMT_HIGH_RISK_C2C_360D        
rat_AMT_HIGH_RISK_DOR_30D_360D    
rat_AMT_HIGH_RISK_DOR_360D        
rat_CNT_HIGH_RISK_B2C_360D        
rat_CNT_HIGH_RISK_C2C_360D        
rat_CNT_HIGH_RISK_DOR_30D_360D    
rat_CNT_HIGH_RISK_DOR_360D        
;

run;

*%mend;

proc contents data = raw.ebay_usar_genvar;
run;


option nolabel;

%include '~/my_macro.sas';
%check_mean(datin = raw.ebay_usar_genvar);
