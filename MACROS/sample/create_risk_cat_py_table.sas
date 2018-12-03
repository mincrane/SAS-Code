
/** read risk categories from the results of risk grouping and create monthly variables ***/
/*
%macro create_rg_cat(filein= ,varname= );
data new;
infile "&filein." TRUNCOVER firstobs=2;
input x $ 1-120;
if index(x,'risk') > 0 then delete;
t = compress(x,"'");
run;

data new2;
set new end = last;
file 'risk_cat.sas' dlm= ',' mod; 
if _n_ = 1 then do;
put ',sum(case when CATEG_LVL2_id in ('; 
end;
put t;
if last then do;

put &varname. ; 
end;
run;

%mend;
*/
/** dormant **/
*%create_rg_cat(filein= ./risk_grouping/risk_cat_dormant_g1.sas , varname=  "-11 ) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_LOW_RISK_DOR_M" );
*%create_rg_cat(filein= ./risk_grouping/risk_cat_dormant_g1.sas , varname=  "-11 ) then 1 else 0 end) as CNT_LOW_RISK_DOR_M" );

*%create_rg_cat(filein= ./risk_grouping/risk_cat_dormant_g4.sas , varname=  "-11 ) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HIGH_RISK_DOR_M" );
*%create_rg_cat(filein= ./risk_grouping/risk_cat_dormant_g4.sas , varname=  "-11 ) then 1 else 0 end) as CNT_HIGH_RISK_DOR_M" );

/** B2C **/

*%create_rg_cat(filein= ./risk_grouping/risk_cat_b2c_g1.sas , varname=  "-11 ) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_LOW_RISK_B2C_M" );
*%create_rg_cat(filein= ./risk_grouping/risk_cat_b2c_g1.sas , varname=  "-11 ) then 1 else 0 end) as CNT_LOW_RISK_B2C_M" );

*%create_rg_cat(filein= ./risk_grouping/risk_cat_b2c_g4.sas , varname=  "-11 ) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HIGH_RISK_B2C_M" );
*%create_rg_cat(filein= ./risk_grouping/risk_cat_b2c_g4.sas , varname=  "-11 ) then 1 else 0 end) as CNT_HIGH_RISK_B2C_M" );

/** C2C **/

*%create_rg_cat(filein= ./risk_grouping/risk_cat_c2c_g1.sas , varname=  "-11 ) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_LOW_RISK_C2C_M" );
*%create_rg_cat(filein= ./risk_grouping/risk_cat_c2c_g1.sas , varname=  "-11 ) then 1 else 0 end) as CNT_LOW_RISK_C2C_M" );

*%create_rg_cat(filein= ./risk_grouping/risk_cat_c2c_g4.sas , varname=  "-11 ) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HIGH_RISK_C2C_M" );
*%create_rg_cat(filein= ./risk_grouping/risk_cat_c2c_g4.sas , varname=  "-11 ) then 1 else 0 end) as CNT_HIGH_RISK_C2C_M" );

/** ALL **/

*%create_rg_cat(filein= ./risk_grouping/risk_cat_all_g1.sas , varname=  "-11 ) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_LOW_RISK_all_M" );
*%create_rg_cat(filein= ./risk_grouping/risk_cat_all_g1.sas , varname=  "-11 ) then 1 else 0 end) as CNT_LOW_RISK_all_M" );

*%create_rg_cat(filein= ./risk_grouping/risk_cat_all_g4.sas , varname=  "-11 ) then ITEM_PRICE_NUM  * ITEM_SOLD_QTY  * CAST(LSTG_CRNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_HIGH_RISK_all_M" );
*%create_rg_cat(filein= ./risk_grouping/risk_cat_all_g4.sas , varname=  "-11 ) then 1 else 0 end) as CNT_HIGH_RISK_all_M" );


/******** for daily  ***/

%macro create_rg_cat(filein= ,varname= ,ind = ,day= );
data new;
infile "&filein." TRUNCOVER firstobs=2;
input x $ 1-120;
if index(x,'risk') > 0 then delete;
t = compress(x,"'");
run;

data new2;
set new end = last;
file 'risk_cat_daily_py.txt' dlm= ',' mod; 
if _n_ = 1 then do;
*put '%let ' "&varname.&day._&ind"  '= %str( ' ;   
put ',sum(case when CATEG_LVL2_id in ('; 
end;
put t;
if last then do;
if &ind = 1 then do;
put  ' -11) and ck.created_time between run_date - interval ' "%nrbquote('&day.')" ' day and run_date THEN  ck.item_price * ck.quantity  * CAST(ck.LSTG_CURNCY_EXCHNG_RATE AS DECIMAL(18,2)) else 0 end) as AMT_'  "&varname&day.D "  ' '; 
end;
if &ind = 2 then do;
put  ' -11) and ck.created_time between run_date - interval ' "%nrbquote('&day.')"  ' day and run_date THEN 1 else 0 end) as CNT_'  "&varname.&day.D  "  ' '; 
end;

end;
run;

%mend;


/** C2C **/
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g4.sas , varname=  high_risk_c2c_  ,ind = 1, day = 1);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g4.sas , varname=  high_risk_c2c_  ,ind = 1, day = 3);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g4.sas , varname=  high_risk_c2c_  ,ind = 1, day = 7);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g4.sas , varname=  high_risk_c2c_  ,ind = 1, day = 30);
 
 
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g4.sas , varname=  high_risk_c2c_  ,ind = 2, day = 1);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g4.sas , varname=  high_risk_c2c_  ,ind = 2, day = 3);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g4.sas , varname=  high_risk_c2c_  ,ind = 2, day = 7);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g4.sas , varname=  high_risk_c2c_  ,ind = 2, day = 30);
                      
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g1.sas , varname=  low_risk_c2c_  ,ind = 1, day = 1);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g1.sas , varname=  low_risk_c2c_  ,ind = 1, day = 3);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g1.sas , varname=  low_risk_c2c_  ,ind = 1, day = 7);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g1.sas , varname=  low_risk_c2c_  ,ind = 1, day = 30);
                                                             
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g1.sas , varname=  low_risk_c2c_  ,ind = 2, day = 1);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g1.sas , varname=  low_risk_c2c_  ,ind = 2, day = 3);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g1.sas , varname=  low_risk_c2c_  ,ind = 2, day = 7);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g1.sas , varname=  low_risk_c2c_  ,ind = 2, day = 30);
/**/                  
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g4.sas , varname=  high_risk_c2c_  ,ind = 1, day = 60);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g4.sas , varname=  high_risk_c2c_  ,ind = 1, day = 90);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g4.sas , varname=  high_risk_c2c_  ,ind = 1, day = 180);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g4.sas , varname=  high_risk_c2c_  ,ind = 1, day = 360);
                     
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g4.sas , varname=  high_risk_c2c_  ,ind = 2, day = 60);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g4.sas , varname=  high_risk_c2c_  ,ind = 2, day = 90);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g4.sas , varname=  high_risk_c2c_  ,ind = 2, day = 180);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g4.sas , varname=  high_risk_c2c_  ,ind = 2, day = 360);
                      
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g1.sas , varname=  low_risk_c2c_  ,ind = 1, day = 60);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g1.sas , varname=  low_risk_c2c_  ,ind = 1, day = 90);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g1.sas , varname=  low_risk_c2c_  ,ind = 1, day = 180);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g1.sas , varname=  low_risk_c2c_  ,ind = 1, day = 360);
                                                                                                  
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g1.sas , varname=  low_risk_c2c_  ,ind = 2, day = 60);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g1.sas , varname=  low_risk_c2c_  ,ind = 2, day = 90);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g1.sas , varname=  low_risk_c2c_  ,ind = 2, day = 180);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_c2c_g1.sas , varname=  low_risk_c2c_  ,ind = 2, day = 360);
                       
                       
                       
/** B2C**/             
                       
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g4.sas , varname=  high_risk_b2c_  ,ind = 1, day = 1);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g4.sas , varname=  high_risk_b2c_  ,ind = 1, day = 3);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g4.sas , varname=  high_risk_b2c_  ,ind = 1, day = 7);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g4.sas , varname=  high_risk_b2c_  ,ind = 1, day = 30);
                                                                        
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g4.sas , varname=  high_risk_b2c_  ,ind = 2, day = 1);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g4.sas , varname=  high_risk_b2c_  ,ind = 2, day = 3);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g4.sas , varname=  high_risk_b2c_  ,ind = 2, day = 7);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g4.sas , varname=  high_risk_b2c_  ,ind = 2, day = 30);
                                          
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g1.sas , varname=  low_risk_b2c_  ,ind = 1, day = 1);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g1.sas , varname=  low_risk_b2c_  ,ind = 1, day = 3);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g1.sas , varname=  low_risk_b2c_  ,ind = 1, day = 7);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g1.sas , varname=  low_risk_b2c_  ,ind = 1, day = 30);
                                                                        
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g1.sas , varname=  low_risk_b2c_  ,ind = 2, day = 1);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g1.sas , varname=  low_risk_b2c_  ,ind = 2, day = 3);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g1.sas , varname=  low_risk_b2c_  ,ind = 2, day = 7);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g1.sas , varname=  low_risk_b2c_  ,ind = 2, day = 30);



%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g4.sas , varname=  high_risk_b2c_  ,ind = 1, day = 60);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g4.sas , varname=  high_risk_b2c_  ,ind = 1, day = 90);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g4.sas , varname=  high_risk_b2c_  ,ind = 1, day = 180);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g4.sas , varname=  high_risk_b2c_  ,ind = 1, day = 360);
                                                                            
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g4.sas , varname=  high_risk_b2c_  ,ind = 2, day = 60);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g4.sas , varname=  high_risk_b2c_  ,ind = 2, day = 90);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g4.sas , varname=  high_risk_b2c_  ,ind = 2, day = 180);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g4.sas , varname=  high_risk_b2c_  ,ind = 2, day = 360);
                                                                            
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g1.sas , varname=  low_risk_b2c_  ,ind = 1, day = 60);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g1.sas , varname=  low_risk_b2c_  ,ind = 1, day = 90);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g1.sas , varname=  low_risk_b2c_  ,ind = 1, day = 180);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g1.sas , varname=  low_risk_b2c_  ,ind = 1, day = 360);
                                                                             
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g1.sas , varname=  low_risk_b2c_  ,ind = 2, day = 60);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g1.sas , varname=  low_risk_b2c_  ,ind = 2, day = 90);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g1.sas , varname=  low_risk_b2c_  ,ind = 2, day = 180);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_b2c_g1.sas , varname=  low_risk_b2c_  ,ind = 2, day = 360);


/** DOR**/

%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g4.sas , varname=  high_risk_dor_  ,ind = 1, day = 1);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g4.sas , varname=  high_risk_dor_  ,ind = 1, day = 3);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g4.sas , varname=  high_risk_dor_  ,ind = 1, day = 7);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g4.sas , varname=  high_risk_dor_  ,ind = 1, day = 30);
                                                                                 
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g4.sas , varname=  high_risk_dor_  ,ind = 2, day = 1);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g4.sas , varname=  high_risk_dor_  ,ind = 2, day = 3);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g4.sas , varname=  high_risk_dor_  ,ind = 2, day = 7);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g4.sas , varname=  high_risk_dor_  ,ind = 2, day = 30);
                                                                                 
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g1.sas , varname=  low_risk_dor_  ,ind = 1, day = 1);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g1.sas , varname=  low_risk_dor_  ,ind = 1, day = 3);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g1.sas , varname=  low_risk_dor_  ,ind = 1, day = 7);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g1.sas , varname=  low_risk_dor_  ,ind = 1, day = 30);
                                                                                 
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g1.sas , varname=  low_risk_dor_  ,ind = 2, day = 1);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g1.sas , varname=  low_risk_dor_  ,ind = 2, day = 3);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g1.sas , varname=  low_risk_dor_  ,ind = 2, day = 7);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g1.sas , varname=  low_risk_dor_  ,ind = 2, day = 30);
                                                                                  
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g4.sas , varname=  high_risk_dor_  ,ind = 1, day = 60);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g4.sas , varname=  high_risk_dor_  ,ind = 1, day = 90);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g4.sas , varname=  high_risk_dor_  ,ind = 1, day = 180)
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g4.sas , varname=  high_risk_dor_  ,ind = 1, day = 360)
                                                                                
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g4.sas , varname=  high_risk_dor_  ,ind = 2, day = 60);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g4.sas , varname=  high_risk_dor_  ,ind = 2, day = 90);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g4.sas , varname=  high_risk_dor_  ,ind = 2, day = 180)
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g4.sas , varname=  high_risk_dor_  ,ind = 2, day = 360)
                                                                                  
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g1.sas , varname=  low_risk_dor_  ,ind = 1, day = 60);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g1.sas , varname=  low_risk_dor_  ,ind = 1, day = 90);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g1.sas , varname=  low_risk_dor_  ,ind = 1, day = 180);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g1.sas , varname=  low_risk_dor_  ,ind = 1, day = 360);
                                                                                
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g1.sas , varname=  low_risk_dor_  ,ind = 2, day = 60);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g1.sas , varname=  low_risk_dor_  ,ind = 2, day = 90);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g1.sas , varname=  low_risk_dor_  ,ind = 2, day = 180);
%create_rg_cat(filein= /ebaysr/projects/EG/model/risk_grouping/risk_cat_dormant_g1.sas , varname=  low_risk_dor_  ,ind = 2, day = 360);













endsas;
