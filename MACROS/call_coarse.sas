options compress=yes obs=max ls=max ps=max pageno=1 errors=2 nocenter symbolgen mlogic mprint;

/*** create coarse classification for all variables in a dataset **/

%include '/sas/ebaysr/MACROS/coarse_all.sas' ;       /*** coarse for all varialbes **/
*%include '/sas/ebaysr/MACROS/coarse_var.sas';       /*** coarse for single variables **/      

libname raw '/sas/hemin/working_macro';


/*** sample code : coarse for all variables **/

data new;
 set raw.ep_sol_var_mb;
 keep perf_bad rat_gloss_m6 rat_a_cb_orig_m6 amt_orig_d3 true_indy_name wght wgt risk_region cat_level2 ;
run;
 
	
%coarse_var(datin = new, perfvar = perf_bad ,bad_indg = 0, weight = ,bin = 10, output_file = ep_seg1_coarse.txt);

endsas;

/**** sample code: single variable coarse ***/

data new;
 set raw.ep_sol_var_mb;
 wght = 1;
 keep perf_bad rat_gloss_m6 rat_a_cb_orig_m6 amt_orig_d3 true_indy_name wght wgt risk_region cat_level2 ;
run;
 
	
%coarse_bin(datin = new, perfvar = perf_bad ,bad_indg = 0,varname = cat_level2 , weight = wgt ,bin = 10);
%coarse_bin(datin = new, perfvar = perf_bad ,bad_indg = 0,varname = true_indy_name , weight = wgt ,bin = 10);
%coarse_bin(datin = new, perfvar = perf_bad ,bad_indg = 0,varname = rat_gloss_m6 , weight = wgt ,bin = 10);
