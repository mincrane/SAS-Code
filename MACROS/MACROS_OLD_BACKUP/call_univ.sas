
options compress=yes obs=max ls=max ps=max pageno=1 errors=10 nocenter; * symbolgen mlogic mprint;


%include '/sas/ebaysr/MACROS/ebsr_univariate_macro_v1.sas';

data new;
	set raw.ep_sol_var_mb;
	keep perf_bad wgt amt_orig_d3 rat_gloss_m6 rat_a_cb_orig_m6 risk_region cat_level2 true_indy_name acct_type cat_level1;
run;	

%univ(datin = raw.ep_sol_var_mb, perfvar =perf_bad ,bad = 0 ,wgt = wgt, exclout = univ_all,datout = );

