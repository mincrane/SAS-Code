options nocenter formdlim='-' ps=95 mprint symbolgen;

libname dat "/sas/pprd/austin/projects/alh_offebay/data";
%let _macropath= /sas/pprd/austin/operations/macro_library/dev;
%include "&_macropath./logreg/v6/logreg_6.sas";
%include "&_macropath./general/impute_truncate.sas";
%include "&_macropath./general/macros_general.sas";
%include "&_macropath./coarses/pull_woe_code.sas"; 
                                                                                                     
  
%get_vars_needed_for_woe(infile=keep_woe_vars.sas,coarsefile=coarses/flag_logic.txt,outfile=include_woe_vars.sas,dropfile=drop_orig_woes.txt);

   
data dat.seg1_modeling;
    set dat.alh_offebay_na_sample;
    where seg = 'Occasional' and bad in (0,1);

    %include '/sas/pprd/austin/projects/alh_offebay/model/NA/seg1/special_woe.txt';
    %include '/sas/pprd/austin/projects/alh_offebay/vargen/zxue/interaction_var.txt';
	
    %include 'include_woe_vars.sas';
    %include 'gensq_call.sas';

    if amt_all_txn_90d_cap <=1 then lg_amt_all_txn_90d_cap = 0; else lg_amt_all_txn_90d_cap = log(amt_all_txn_90d_cap);
    if amt_scs_txn_90d_cap <=1 then lg_amt_scs_txn_90d_cap = 0; else lg_amt_scs_txn_90d_cap = log(amt_scs_txn_90d_cap);
    if avg_amt_orig_txn_30d_cap <=1 then lg_avg_amt_orig_txn_30d_cap = 0; else lg_avg_amt_orig_txn_30d_cap = log(avg_amt_orig_txn_30d_cap);
    if amt_suc_wtdr_14d_cap <=1 then lg_amt_suc_wtdr_14d_cap = 0; else lg_amt_suc_wtdr_14d_cap = log(amt_suc_wtdr_14d_cap);
    if avg_amt_req_mon_30d_cap <=1 then lg_avg_amt_req_mon_30d_cap = 0; else lg_avg_amt_req_mon_30d_cap = log(avg_amt_req_mon_30d_cap);
    if amt_scs_txn_60d_cap <=1 then lg_amt_scs_txn_60d_cap = 0; else lg_amt_scs_txn_60d_cap = log(amt_scs_txn_60d_cap);
    if amt_all_txn_30d_cap <=1 then lg_amt_all_txn_30d_cap = 0; else lg_amt_all_txn_30d_cap = log(amt_all_txn_30d_cap);
    if amt_scs_txn_30d_cap <=1 then lg_amt_scs_txn_30d_cap = 0; else lg_amt_scs_txn_30d_cap = log(amt_scs_txn_30d_cap);
    if amt_sigln_30d_cap <=1 then lg_amt_sigln_30d_cap = 0; else lg_amt_sigln_30d_cap = log(amt_sigln_30d_cap);
    if amt_sigln_60d_cap <=1 then lg_amt_sigln_60d_cap = 0; else lg_amt_sigln_60d_cap = log(amt_sigln_60d_cap);
    if amt_gtpv_l120d_cap <=1 then lg_amt_gtpv_l120d_cap = 0; else lg_amt_gtpv_l120d_cap = log(amt_gtpv_l120d_cap);
    if amt_gtpv_l180d_cap <=1 then lg_amt_gtpv_l180d_cap = 0; else lg_amt_gtpv_l180d_cap = log(amt_gtpv_l180d_cap);
    if avg_amt_orig_txn_7d_cap <=1 then lg_avg_amt_orig_txn_7d_cap = 0; else lg_avg_amt_orig_txn_7d_cap = log(avg_amt_orig_txn_7d_cap);
    if amt_req_mon_90d_cap <=1 then lg_amt_req_mon_90d_cap = 0; else lg_amt_req_mon_90d_cap = log(amt_req_mon_90d_cap);
    if avg_amt_suc_wtdr_30d_cap <=1 then lg_avg_amt_suc_wtdr_30d_cap = 0; else lg_avg_amt_suc_wtdr_30d_cap = log(avg_amt_suc_wtdr_30d_cap);
    if amt_all_txn_14d_cap <=1 then lg_amt_all_txn_14d_cap = 0; else lg_amt_all_txn_14d_cap = log(amt_all_txn_14d_cap);
    if amt_email_pmt_14d_cap <=1 then lg_amt_email_pmt_14d_cap = 0; else lg_amt_email_pmt_14d_cap = log(amt_email_pmt_14d_cap);
    if amt_gtpv_l3d_cap <=1 then lg_amt_gtpv_l3d_cap = 0; else lg_amt_gtpv_l3d_cap = log(amt_gtpv_l3d_cap);
    if amt_email_pmt_90d_cap <=1 then lg_amt_email_pmt_90d_cap = 0; else lg_amt_email_pmt_90d_cap = log(amt_email_pmt_90d_cap);
    if avg_amt_sed_mon_90d_cap <=1 then lg_avg_amt_sed_mon_90d_cap = 0; else lg_avg_amt_sed_mon_90d_cap = log(avg_amt_sed_mon_90d_cap);
    if amt_email_pmt_60d_cap <=1 then lg_amt_email_pmt_60d_cap = 0; else lg_amt_email_pmt_60d_cap = log(amt_email_pmt_60d_cap);
    if avg_amt_sed_mon_60d_cap <=1 then lg_avg_amt_sed_mon_60d_cap = 0; else lg_avg_amt_sed_mon_60d_cap = log(avg_amt_sed_mon_60d_cap);

	/*
    if amt_ach_14d_cap <=1 then lg_amt_ach_14d_cap = 0; else lg_amt_ach_14d_cap = log(amt_ach_14d_cap);
    if amt_nsf_ach_14d_cap <=1 then lg_amt_nsf_ach_14d_cap = 0; else lg_amt_nsf_ach_14d_cap = log(amt_nsf_ach_14d_cap);
    if amt_ach_90d_cap <=1 then lg_amt_ach_90d_cap = 0; else lg_amt_ach_90d_cap = log(amt_ach_90d_cap);
    if amt_rvsd_cap <=1 then lg_amt_rvsd_cap = 0; else lg_amt_rvsd_cap = log(amt_rvsd_cap);
    if amt_txn_refund_l180d_cap <=1 then lg_amt_txn_refund_l180d_cap = 0; else lg_amt_txn_refund_l180d_cap = log(amt_txn_refund_l180d_cap);
    if amt_ach_30d_cap <=1 then lg_amt_ach_30d_cap = 0; else lg_amt_ach_30d_cap = log(amt_ach_30d_cap);
    if amt_avg_balance_l60d_cap <=0 then lg_amt_avg_balance_l60d_cap = 0; else lg_amt_avg_balance_l60d_cap = log(amt_avg_balance_l60d_cap);
    if amt_avg_balance_l14d_cap <=0 then lg_amt_avg_balance_l14d_cap = 0; else lg_amt_avg_balance_l14d_cap = log(amt_avg_balance_l14d_cap);
	*/

    %include '/sas/pprd/austin/projects/alh_offebay/model/NA/seg1/var_keep.txt';
    %include '/sas/pprd/austin/projects/alh_offebay/vargen/zxue/interaction_var_list.txt';
    keep mod_wgt_2 sam_wgt wgt_loss bad pp_gross_mer_next_30d_cap gtpv_next_30d_cap;

RUN;
 
  
%logreg(iteration=14,
        rootdir=/sas/pprd/austin/projects/alh_offebay/model/NA/seg1,
        datadir=,                                      
        dset=dat.seg1_modeling,
		project_name=ALH Off-ebay,
		population_label=Segment 1,
		segment=seg1,
        eventval=1,                                                                                                   
        noneventval=0,                                                                                                
        perfvar=bad,                                                                                      
        wghtvar=sam_wgt,  
        modelwgt=mod_wgt_2,                                                                                        
        tpvvar= gtpv_next_30d_cap,                                                                                      
        lossvar= pp_gross_mer_next_30d_cap,                                                                                    
        unitdist=N,                                                                                                   
        varforced=,                                                                                         
        limitmodel=N,                                                                                       
        limititer=iteration11,                                                                                         
        sampling=PROPORTIONAL,                                                                                        
        sampprop=0.70,                                                                                                
        resample=N,                                                                                                   
        selection=STEPWISE,                                                                                           
        pentry=.01,                                                                                                  
        pexit=.01,                                                                                                   
        intercept=,                                                                                                   
        linkfunc=LOGIT,                                                                                               
        maxstep=22,                                                                                                   
        maxiter=99,                                                                                                   
        perfgrp=20,                                                                                                   
        modelsub=FALSE,                                                                                               
        NoIterSum=10,
		Finaliter=NO);                                                                                                 
 
 
