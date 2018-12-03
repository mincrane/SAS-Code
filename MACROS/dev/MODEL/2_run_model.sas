options nocenter formdlim='-' ps=95 mprint symbolgen;


%let _macropath= /ebaysr/MACROS/dev/model_lib/;


%include "&_macropath./logreg_5_mike.sas";
%include "&_macropath./general/impute_truncate.sas";
%include "&_macropath./general/macros_general.sas";
*%include "&_macropath./coarses/pull_woe_code.sas"; 
 

libname dat '../data' access=readonly;

*%get_vars_needed_for_woe(infile=keep_woe_vars.sas,coarsefile=coarses/flag_logic.txt,outfile=include_woe_vars.sas,dropfile=drop_orig_woes.txt);


data modeling ;
	set dat.b2c_model_summary;

    wgt=1;

*%include 'include_woe_vars.sas';
%include 'gensq_call.sas';

RUN;

/*
proc contents data = modeling;
run;

proc freq data = modeling;
table flag;
run;
*/	

%logreg(iteration=4,                                                                                                  
        rootdir=/ebaysr/projects/onboard/model/B2C/MODEL/,                              
        datadir=/ebaysr/projects/onboard/model/B2C/MODEL/,                                      
        dset=modeling,                                                                                     
        eventval=1,                                                                                                   
        noneventval=0,                                                                                                
        perfvar=flag,                                                                                      
        wghtvar=wgt,                                                                                          
        tpvvar= perf_gmv_60d,                                                                                      
        lossvar=  perf_net_loss_60d  ,                                                                                    
        unitdist=N,                                                                                                   
        varforced=,                                                                                         
        limitmodel=N,                                                                                       
        limititer=,                                                                                         
        sampling=PROPORTIONAL,                                                                                        
        sampprop=0.66,                                                                                                
        resample=N,                                                                                                   
        selection=STEPWISE,                                                                                           
        pentry=.005,                                                                                                  
        pexit=.001,                                                                                                   
        intercept=,                                                                                                   
        linkfunc=LOGIT,                                                                                               
        maxstep=16,                                                                                                   
        maxiter=25,                                                                                                   
        perfgrp=10,                                                                                                   
        modelsub=FALSE,                                                                                               
        NoIterSum=5);                                                                                                 
                                                                                                          
                                                                                                          
                                                                                              