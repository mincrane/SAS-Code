options nocenter formdlim='-' ps=95 mprint symbolgen;

%include '../parameters_pg1.sas';   

libname mdl "&dat" access=readonly;
libname outdat "&outdata./seg&segment_number./kgb/data";

%include "autoexec.sas";
%include "&_macropath./logreg/v5/logreg_5.sas";
%include "&_macropath./general/impute_truncate.sas";
%include "&_macropath./general/macros_general.sas";
%include "&_macropath./coarses/pull_woe_code.sas"; 


                                                                                                       
  

%get_vars_needed_for_woe(infile=keep_woe_vars.sas,coarsefile=coarses/flag_logic.txt,outfile=include_woe_vars.sas,dropfile=drop_orig_woes.txt);

data outdat.build (drop=BUSINESSCITY) build  (drop=BUSINESSCITY);
	set dat.&build_set_re&segment_number   ;

	
	
	 %include 'include_woe_vars.sas';


/*include risk groupings here*/

	  BUSINESSCITY=compress(compress(BUSINESSCITY,"'"),'"');
    %include "riskgroup/risk_city_g1.sas";
   
/*end risk groupings code*/
	
	%include 'gensq_call.sas';
   output build;
		if &perf in (0,1) then output outdat.build;
RUN;


data outdat.valid (drop=BUSINESSCITY) valid (drop=BUSINESSCITY);
	set dat.&valid_set_re&segment_number   ;
	
	
	
	 %include 'include_woe_vars.sas';


/*include risk groupings here*/

	  BUSINESSCITY=compress(compress(BUSINESSCITY,"'"),'"');
    %include "riskgroup/risk_city_g1.sas";
   
/*end risk groupings code*/
	
	%include 'gensq_call.sas';

	 output valid;
		if &perf in (0,1) then output outdat.valid;
RUN;

	 


%logreg(iteration=1,                                                                                                  
        rootdir=.,                              
        datadir=&outdata./seg&segment_number./kgb,                                      
        dset=outdat.build,                                                                                     
        eventval=1,                                                                                                   
        noneventval=0,                                                                                                
        perfvar=&perf,                                                                                      
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
                                                                                                          
   
  
  
 /*score full set */
 
 
 proc logistic inmodel=outdat.scoreset;
      	score data=valid out=scr_vld;
      run;
 
 
 proc logistic inmodel=outdat.scoreset;
      	score data=build out=scr_bld;
      run;
 
 
  
DATA scr_bld scr_vld dat.scr_all_gb;
	 SET scr_bld (in=ina keep=p_1 &perf &weight &appid rename=(p_1=probg_re ))
	     scr_vld (in=inb keep=p_1 &perf &weight &appid rename=(p_1=probg_re ));
	     
	   label score_kgb_re = 'Aligned KGB score at Recent Bureau'
           probg_re  = 'Probabilty of Good Bad from KGB Model At Recent Bureau';   
     
     score_kgb_re=log(probg_re /(1-probg_re ));    

     if ina then output scr_bld ;
     if inb then output scr_vld;
     output dat.scr_all_gb;
RUN;



proc sort data=dat.scr_all_gb ;
 by &appid;
run;



  

title "RI Known Good-Bad Model. Development Sample.";
%finesplt(scr_bld,&perf ,Bad,&bad.,&bad.,Good,&good.,&good., &weight,probg_re   ,10.3,10 );
title "RI Known Good-Bad Model. Validation Sample.";
%finesplt(scr_vld,&perf ,Bad,&bad.,&bad.,Good,&good.,&good.,&weight ,probg_re   ,10.3,10 );
title "RI Known Good-Bad Model. Total Sample.";
%finesplt(dat.scr_all_gb,&perf ,Bad,&bad.,&bad.,Good,&good.,&good., &weight,probg_re   ,10.3,10 );

proc means data=dat.scr_all_gb ;
class &perf;
var probg_re;
run;

                                                                  