options nocenter formdlim='-' ps=95 mprint symbolgen;

libname dat "/sas/pprd/austin/projects/alh_offebay/data";
%let _macropath= /sas/pprd/austin/operations/macro_library/dev;
%include "&_macropath./logreg/v6/logreg_6.sas";
%include "&_macropath./general/impute_truncate.sas";
%include "&_macropath./general/macros_general.sas";
%include "&_macropath./coarses/pull_woe_code.sas"; 
  
   
 /*   
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

    if missing(n_phn_l180d_cap) = 1 then n_phn_l180d_cap =0; 

		
    %include '/sas/pprd/austin/projects/alh_offebay/model/NA/seg1/var_keep.txt';
    %include '/sas/pprd/austin/projects/alh_offebay/vargen/zxue/interaction_var_list.txt';
	
    keep mod_wgt_2 sam_wgt wgt_loss bad pp_gross_mer_next_30d_cap gtpv_next_30d_cap;

RUN;
 */
  

 

%let varforced= 
D_PRMRY_ACH_ADDED_CAP
DNSTY_BANK_COUNTRY_CAP
IT_LOW_TXN_30_IP_NEW_90
LATEST_ALL_NB_DOF_CAP
LG_AMT_EMAIL_PMT_60D_CAP
LG_AMT_GTPV_L180D_CAP
N_ACH_90D_CAP
N_ADDRS_60D_CAP
N_DIS_BUY_CTY_30D_CAP
N_LINKED_ACCT_ACX_CAP
N_PHN_L180D_CAP
N_VID_90D_CAP
PCT_IP_NEW_USED_L30D_CAP
PCT_N_EMAIL_30_180D_CAP
RAT_AVG_NEG_BAL_30_90_CAP
WAMT_RVSD_CAP_S1
;


%let varforced= 
D_PRMRY_ACH_ADDED_CAP
DNSTY_BANK_COUNTRY_CAP
IT_LOW_TXN_30_IP_NEW_90
LG_AMT_EMAIL_PMT_60D_CAP
N_ADDRS_60D_CAP
N_LINKED_ACCT_ACX_CAP
N_VID_90D_CAP
PCT_IP_NEW_USED_L30D_CAP
RAT_AVG_NEG_BAL_30_90_CAP
WAMT_RVSD_CAP_S1
wcust_acct_type_code_s1
n_dis_buy_cty_30d_cap
n_ach_90d_cap
pct_n_email_30_180d_cap
d_prmry_cc_vrfd_cap
n_phn_l180d_cap
;

 
%logreg(iteration=45,
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
        varforced=&varforced,                                                                                         
        limitmodel=N,                                                                                       
        limititer=iteration43,                                                                                         
        sampling=PROPORTIONAL,                                                                                        
        sampprop=0.70,                                                                                                
        resample=Y,                                                                                                   
        selection=STEPWISE,                                                                                           
        pentry=.01,                                                                                                  
        pexit=.01,                                                                                                   
        intercept=,                                                                                                   
        linkfunc=LOGIT,                                                                                               
        maxstep=1,                                                                                                   
        maxiter=99,                                                                                                   
        perfgrp=20,                                                                                                   
        modelsub=FALSE,                                                                                               
        NoIterSum=10,
		Finaliter=NO);                                                                                                 
 
 
