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
	
    %include 'include_woe_vars.sas';
    %include 'gensq_call.sas';
    %include '/sas/pprd/austin/projects/alh_offebay/model/NA/seg1/var_keep.txt';

    keep mod_wgt_2 sam_wgt wgt_loss bad pp_gross_mer_next_30d_cap gtpv_next_30d_cap;
RUN;
 
 
%logreg(iteration=5,
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
        limititer=,                                                                                         
        sampling=PROPORTIONAL,                                                                                        
        sampprop=0.70,                                                                                                
        resample=N,                                                                                                   
        selection=STEPWISE,                                                                                           
        pentry=.01,                                                                                                  
        pexit=.01,                                                                                                   
        intercept=,                                                                                                   
        linkfunc=LOGIT,                                                                                               
        maxstep=25,                                                                                                   
        maxiter=99,                                                                                                   
        perfgrp=20,                                                                                                   
        modelsub=FALSE,                                                                                               
        NoIterSum=5,
		Finaliter=NO);                                                                                                 
 
 
 
