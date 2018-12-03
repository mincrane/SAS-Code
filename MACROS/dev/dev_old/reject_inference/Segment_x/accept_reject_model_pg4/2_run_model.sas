options nocenter formdlim='-' ps=95 mprint symbolgen;

%include '../parameters_pg1.sas';   

libname mdl "&dat" access=readonly;
libname outdat "&outdata./seg&segment_number./ar/data";

%include "autoexec.sas";
%include "&_macropath./logreg/v5/logreg_5.sas";
%include "&_macropath./general/impute_truncate.sas";
%include "&_macropath./general/macros_general.sas";
%include "&_macropath./coarses/pull_woe_code.sas"; 


                                                                                                       
  

%get_vars_needed_for_woe(infile=keep_woe_vars.sas,coarsefile=coarses/flag_logic.txt,outfile=include_woe_vars.sas,dropfile=drop_orig_woes.txt);

data outdat.build (drop=BUSINESSCITY);
	set dat.&build_set_ap&segment_number   ;
	where ar_flag in (0,1);
	
	
	 %include 'include_woe_vars.sas';


/*include risk groupings here*/

	  BUSINESSCITY=compress(compress(BUSINESSCITY,"'"),'"');
    %include "riskgroup/risk_city_g1.sas";
   
/*end risk groupings code*/
	
	%include 'gensq_call.sas';

	
RUN;


data outdat.valid (drop=BUSINESSCITY);
	set dat.&valid_set_ap&segment_number   ;
	where ar_flag in (0,1);
	
	
	 %include 'include_woe_vars.sas';


/*include risk groupings here*/

	  BUSINESSCITY=compress(compress(BUSINESSCITY,"'"),'"');
    %include "riskgroup/risk_city_g1.sas";
   
/*end risk groupings code*/
	
	%include 'gensq_call.sas';

	
RUN;

	 


%logreg(iteration=1,                                                                                                  
        rootdir=.,                              
        datadir=&outdata./seg&segment_number./ar,                                      
        dset=outdat.build,                                                                                     
        eventval=1,                                                                                                   
        noneventval=0,                                                                                                
        perfvar=ar_flag,                                                                                      
        wghtvar=&weight,                                                                                          
        tpvvar=,                                                                                      
        lossvar=,                                                                                    
        unitdist=N,                                                                                                   
        varforced=,                                                                                         
        limitmodel=N,                                                                                       
        limititer=,                                                                                         
        sampling=FIXED,                                                                                        
        sampprop=0.55,                                                                                                
        resample=N,                                                                                                   
        selection=STEPWISE,                                                                                           
        pentry=.01,                                                                                                  
        pexit=.01,                                                                                                   
        intercept=,                                                                                                   
        linkfunc=LOGIT,                                                                                               
        maxstep=18,                                                                                                   
        maxiter=99,                                                                                                   
        perfgrp=10,                                                                                                   
        modelsub=FALSE,                                                                                               
        NoIterSum=5);                                                                                                 
                                                                                                          
   
  
  
 
 
  
data dat.scr_all_ra ;
	   
  set outdat.scrbld (Keep=predicted  &perf &weight &appid ar_flag book_flag in=ina rename=(predicted=prob_ra))
       outdat.scrvld (Keep=p_1 &perf &weight &appid ar_flag book_flag in=inb rename=(p_1=prob_ra)) ;
 
  label score_ra = 'Aligned RA score for the Application data'
        prob_ra = 'RA Probability for APplication Data';
        
	score_ra=log(prob_ra/(1-prob_ra));
	

	 
	output dat.scr_all_ra;
run;

proc sort data=dat.scr_all_ra ;
  by &appid;
run;              

title1 "&title_proj RI RA Model. Development Sample.";
%finesplt(outdat.scrbld,AR_flag ,Reject,0,0,Accept,1,1, &weight,predicted   ,10.4,10 );
run;
title1 "&title_proj RI RA Model. Validation Sample.";
%finesplt(outdat.scrvld  ,AR_flag ,Reject,0,0,Accept,1,1,&weight ,p_1  ,10.4,10 );
run;
title1 "&title_proj RI RA Model. Total Sample.";
%finesplt(dat.scr_all_ra,AR_flag,Reject,0,0,Accept,1,1,&weight ,prob_ra     ,10.4,10 );
run;                                                                         