
libname scratch teradata user=&sysuserid PASSWORD="&tdbpass" TDPID="mz2" DATABASE=p_ebay_eg_t	OVERRIDE_RESP_LEN=YES DBCOMMIT=0;

libname raw  '/ebaysr/projects/QP_MODEL/data';

%let ind=0131;

data new;

input name1 : $32. description1 : $30. ; 
datalines;
rat_AMT_ESC_BYR_clm   chg_a_esc_byr_clm_rate      
rat_AMT_ESC_clm       chg_a_esc_clm_rate  
rat_AMT_OPEN_clm      chg_a_open_clm_rate  
rat_AMT_HASP_GT2_GMV  chg_a_HASP2_Rate  
rat_AMT_HASP_GMV      chg_a_HASP_Rate  
rat_AMT_HIGH_RISK_B2C chg_a_high_risk_b2c  
rat_AMT_HIGH_RISK_C2C chg_a_high_risk_c2c  
rat_AMT_HIGH_RISK_DOR chg_a_high_risk_dor  
rat_CNT_ESC_BYR_clm   chg_c_esc_byr_clm_rate  
rat_CNT_ESC_clm       chg_c_esc_clm_rate  
rat_CNT_OPEN_clm      chg_c_open_clm_rate  
rat_CNT_HASP_GT2_TXN  chg_c_hasp2_rate  
rat_CNT_HASP_TXN      chg_c_hasp_rate  
rat_CNT_HIGH_RISK_C2C chg_c_high_risk_c2c  
rat_CNT_HIGH_RISK_B2C chg_c_high_risk_b2c  
rat_CNT_HIGH_RISK_DOR chg_c_high_risk_dor  
rat_CNT_REV_NEG_MSG   chg_neg_msg_rate  
rat_CNT_SLR_NGTV_FDBK chg_neg_fb_rate  
;
run;

proc print data =new;
run;

data new1;
set new;
name = compress(trimn(name1),'');
description = strip(description1);
t = name||'_3D';
run;

proc print data = new1;
run;

%let daily_var_gen = new1;

proc sql;

/* int **/
	
select '%Ratio('||compress(name)||"_1D,"||compress(name)||"_3D,"||compress(varname)||"_1D_3D,100,0.01,label= Ratio 1 day to 3 days "||trim(name)||")" into :defRatio13 separated by ";"
from &daily_var_gen(rename = (description = varname));
 
select '%Ratio('||compress(name)||"_1D,"||compress(name)||"_7D,"||compress(varname)||"_1D_7D,100,0.01,label= Ratio 1 day to 7 days "||trim(name)||")" into :defRatio17 separated by ";"
from &daily_var_gen(rename = (description = varname));

select '%Ratio('||compress(name)||"_1D,"||compress(name)||"_30D,"||compress(varname)||"_1D_30D,100,0.01,label= Ratio 1 day to 30 days "||trim(name)||")" into :defRatio130 separated by ";"
from &daily_var_gen(rename = (description = varname));

select '%Ratio('||compress(name)||"_1D,"||compress(name)||"_90D,"||compress(varname)||"_1D_90D,100,0.01,label= Ratio 1 day to 90 days "||trim(name)||")" into :defRatio190 separated by ";"
from &daily_var_gen(rename = (description = varname));


select '%Ratio('||compress(name)||"_3D,"||compress(name)||"_30D,"||compress(varname)||"_3D_30D,100,0.01,label= Ratio 3 day to 30 days "||trim(name)||")" into :defRatio330 separated by ";"
from &daily_var_gen(rename = (description = varname));
 
select '%Ratio('||compress(name)||"_3D,"||compress(name)||"_90D,"||compress(varname)||"_3D_90D,100,0.01,label= Ratio 3 day to 90 days "||trim(name)||")" into :defRatio390 separated by ";"
from &daily_var_gen(rename = (description = varname));

 select '%Ratio('||compress(name)||"_7D,"||compress(name)||"_30D,"||compress(varname)||"_7D_30D,100,0.01,label= Ratio 7 day to 30 days "||trim(name)||")" into :defRatio730 separated by ";"
from &daily_var_gen(rename = (description = varname));

select '%Ratio('||compress(name)||"_7D,"||compress(name)||"_60D,"||compress(varname)||"_7D_60D,100,0.01,label= Ratio 7 day to 60 days "||trim(name)||")" into :defRatio760 separated by ";"
from &daily_var_gen(rename = (description = varname)); 
 
select '%Ratio('||compress(name)||"_7D,"||compress(name)||"_90D,"||compress(varname)||"_7D_90D,100,0.01,label= Ratio 7 day to 90 days "||trim(name)||")" into :defRatio790 separated by ";"
from &daily_var_gen(rename = (description = varname)); 
  
select '%Ratio('||compress(name)||"_7D,"||compress(name)||"_180D,"||compress(varname)||"_7D_180D,100,0.01,label= Ratio 7 day to 180 days "||trim(name)||")" into :defRatio7180 separated by ";"
from &daily_var_gen(rename = (description = varname));  
 
select '%Ratio('||compress(name)||"_30D,"||compress(name)||"_60D,"||compress(varname)||"_30D_60D,100,0.01,label= Ratio 30 day to 60 days "||trim(name)||")" into :defRatio3060 separated by ";"
from &daily_var_gen(rename = (description = varname));  
  
select '%Ratio('||compress(name)||"_30D,"||compress(name)||"_90D,"||compress(varname)||"_30D_90D,100,0.01,label= Ratio 30 day to 90 days "||trim(name)||")" into :defRatio7180 separated by ";"
from &daily_var_gen(rename = (description = varname));  
  
select '%Ratio('||compress(name)||"_30D,"||compress(name)||"_180D,"||compress(varname)||"_30D_180D,100,0.01,label= Ratio 30 day to 180 days "||trim(name)||")" into :defRatio30180 separated by ";"
from &daily_var_gen(rename = (description = varname));  
  
select '%Ratio('||compress(name)||"_30D,"||compress(name)||"_360D,"||compress(varname)||"_30D_360D,100,0.01,label= Ratio 30 day to 360 days "||trim(name)||")" into :defRatio30360 separated by ";"
from &daily_var_gen(rename = (description = varname));  

 
endsas;
	


