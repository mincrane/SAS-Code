options nocenter formdlim='-' ps=95;


%let _macropath= /ebaysr/MACROS/dev/model_lib/;
%include "&_macropath./coarses/woe_vargen.sas";

libname raw '/ebaysr/projects/EG/model/data' access=readonly;


data modeling;
  set raw.model_all_var;
 
wgt = 1; 
drop 
run_date
customer_id  
CUSTOMER_PRIMARY_RESIDENCE
IND_ID                    
IND_MCC_CODE 
_flag_empty
cust_group              
customer_id
i        
industry
rsrv_flag  
run_date   
subindustry
month_id 
mth_id;
 
run;
  

%woe_vargen(dset=modeling,perfvar=perf_gloss_gt100,wghtvar=model_wght1,fname=flag_logic.txt);