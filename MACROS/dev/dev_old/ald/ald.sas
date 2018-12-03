/*
* Author: Shubham Agrawal
* Created date: 22 NOV 2011
* Modifications Needed: code for lifetime cnt and 24 months count 
* Instructions: to be included
* Last Modified Date: 22 NOV 2011
*/

options formdlim="_" error=2 compress="YES";*mprint merror serror symbolgen mlogic obs=5000;

%let tdname=shuagrawal;

filename dt './ALD.csv';

data var_req;
	infile dt delimiter = ',' firstobs = 2 dsd termstr = crlf lrecl=4096 truncover;
	input merch_rsk_txn_grp_key merch_rsk_pmt_flow_fmx_grp_key Varname :$30. unt_varname_d1	
	amt_varname_d1	unt_varname_d3	amt_varname_d3	unt_varname_d7	amt_varname_d7	unt_varname_d14	
	amt_varname_d14	unt_varname_d21	amt_varname_d21	unt_varname_d30	amt_varname_d30	
	_unt_varname_m1	unt_varname_m2	unt_varname_m3	unt_varname_m4	unt_varname_m5	unt_varname_m6	
	unt_varname_m7	unt_varname_m8	unt_varname_m9	unt_varname_m10	unt_varname_m11	unt_varname_m12
	_amt_varname_m1	amt_varname_m2	amt_varname_m3	amt_varname_m4	amt_varname_m5	amt_varname_m6	
	amt_varname_m7	amt_varname_m8	amt_varname_m9	amt_varname_m10	amt_varname_m11	amt_varname_m12
	unt_varname_lt	amt_varname_lt	cnt_varname_m24	amt_varname_m24;
run;
	
proc print data = var_req;
run;

proc contents data = var_req varnum;
run;

data _null_;
Length str $500;
str= "Select a.cust_id ";
file "/sas/shuagrawal/ALD/code_daily.txt";
put str;
run;

data _null_;
set var_req;
Length str $500;
array unt_daily {5} unt_varname_d3 unt_varname_d7 unt_varname_d14 unt_varname_d21 unt_varname_d30;
array amt_daily {5} amt_varname_d3 amt_varname_d7 amt_varname_d14 amt_varname_d21 amt_varname_d30;
array counter {5} (3 7 14 21 30);

if unt_varname_d1 = 1 then do;
str = ",SUM(CASE WHEN b.merch_rsk_txn_grp_key in ("||strip(merch_rsk_txn_grp_key)||") and b.merch_rsk_pmt_flow_fmx_grp_key="||strip(merch_rsk_pmt_flow_fmx_grp_key)||" THEN b.dly_cnt ELSE 0 END) "||"unt_"||strip(varname)||"_d1";
file "/sas/shuagrawal/ALD/code_daily.txt" mod;
put str;
end;

do ii = 1 to 5;

if unt_daily[ii]  = 1 then do;
str = ",SUM(CASE WHEN b.merch_rsk_txn_grp_key in ("||strip(merch_rsk_txn_grp_key)||") and b.merch_rsk_pmt_flow_fmx_grp_key="||strip(merch_rsk_pmt_flow_fmx_grp_key)
       ||" THEN b.rollup_"||strip(counter[ii])||"_day_cnt ELSE 0 END) "||"unt_"||strip(varname)||"_d"||strip(counter[ii]);
file "/sas/shuagrawal/ALD/code_daily.txt" mod;
put str;
end;
end;

if amt_varname_d1 = 1 then do;
str = ",SUM(CASE WHEN b.merch_rsk_txn_grp_key in ("||strip(merch_rsk_txn_grp_key)||") and b.merch_rsk_pmt_flow_fmx_grp_key="||strip(merch_rsk_pmt_flow_fmx_grp_key)||" THEN b.dly_usd_amt ELSE 0 END) "||"amt_"||strip(varname)||"_d1";
file "/sas/shuagrawal/ALD/code_daily.txt" mod;
put str;
end;

do ii = 1 to 5;

if amt_daily[ii]  = 1 then do;
str = ",SUM(CASE WHEN b.merch_rsk_txn_grp_key in ("||strip(merch_rsk_txn_grp_key)||") and b.merch_rsk_pmt_flow_fmx_grp_key="||strip(merch_rsk_pmt_flow_fmx_grp_key)
       ||" THEN b.rollup_"||strip(counter[ii])||"_day_usd_amt ELSE 0 END) "||"amt_"||strip(varname)||"_d"||strip(counter[ii]);
file "/sas/shuagrawal/ALD/code_daily.txt" mod;
put str;
end;
end;

run;

data _null_;
Length str $500;
file "/sas/shuagrawal/ALD/code_daily.txt" mod;
str= "From driver a ";
put str;
str = "INNER JOIN PP_ACCESS_VIEWS.fact_rsk_merch_day_vars b";
put str;
str = "On a.cust_id = b.rsk_merch_id ";
put str;
str = "GROUP BY 1 ";
put str;
run;





data _null_;
Length str $500;
str= "Select a.cust_id ";
file "/sas/shuagrawal/ALD/code_monthly.txt";
put str;
run;

data _null_;
set var_req;
Length str $500;
array unt_mthly {11} unt_varname_m2 - unt_varname_m12;
array amt_mthly {11} amt_varname_m2 - amt_varname_m12;
array counter {11} (2 3 4 5 6 7 8 9 10 11 12);

if _unt_varname_m1 = 1 then do;
str = ",SUM(CASE WHEN b.merch_rsk_txn_grp_key in ("||strip(merch_rsk_txn_grp_key)||") and b.merch_rsk_pmt_flow_fmx_grp_key="||strip(merch_rsk_pmt_flow_fmx_grp_key)||" THEN b.mth_1_cnt
 ELSE 0 END) "||"_unt_"||strip(varname)||"_m1";
file "/sas/shuagrawal/ALD/code_monthly.txt" mod;
put str;
end;

do ii = 1 to 11;

if unt_mthly[ii]  = 1 then do;
str = ",SUM(CASE WHEN b.merch_rsk_txn_grp_key in ("||strip(merch_rsk_txn_grp_key)||") and b.merch_rsk_pmt_flow_fmx_grp_key="||strip(merch_rsk_pmt_flow_fmx_grp_key)
       ||" THEN b.mth_"||strip(counter[ii])||"_cnt ELSE 0 END) "||"unt_"||strip(varname)||"_m"||strip(counter[ii]);
file "/sas/shuagrawal/ALD/code_monthly.txt" mod;
put str;
end;
end;

if _amt_varname_m1 = 1 then do;
str = ",SUM(CASE WHEN b.merch_rsk_txn_grp_key in ("||strip(merch_rsk_txn_grp_key)||") and b.merch_rsk_pmt_flow_fmx_grp_key="||strip(merch_rsk_pmt_flow_fmx_grp_key)||" THEN b.mth_1_usd_amt
 ELSE 0 END) "||"_amt_"||strip(varname)||"_m1";
file "/sas/shuagrawal/ALD/code_monthly.txt" mod;
put str;
end;

do ii = 1 to 11;

if amt_mthly[ii]  = 1 then do;
str = ",SUM(CASE WHEN b.merch_rsk_txn_grp_key in ("||strip(merch_rsk_txn_grp_key)||") and b.merch_rsk_pmt_flow_fmx_grp_key="||strip(merch_rsk_pmt_flow_fmx_grp_key)
       ||" THEN b.mth_"||strip(counter[ii])||"_usd_amt ELSE 0 END) "||"amt_"||strip(varname)||"_m"||strip(counter[ii]);
file "/sas/shuagrawal/ALD/code_monthly.txt" mod;
put str;
end;
end;

run;

* to include lifetime and 24 months variable;

data _null_;
Length str $500;
file "/sas/shuagrawal/ALD/code_monthly.txt" mod;
str= "From driver a ";
put str;
str = "INNER JOIN PP_ACCESS_VIEWS.fact_rsk_merch_mth_vars b";
put str;
str = "On a.cust_id = b.rsk_merch_id ";
put str;
str = "GROUP BY 1 ";
put str;
run;
