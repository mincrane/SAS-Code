options nocenter formdlim='-' ps=95 mprint symbolgen;

%include '../parameters_pg1.sas';   

libname mdl "&dat" access=readonly;
libname outdat "&outdata./seg&segment_number./agb/data";

%include "autoexec.sas";
%include "&_macropath./logreg/v5/logreg_5.sas";
%include "&_macropath./general/impute_truncate.sas";
%include "&_macropath./general/macros_general.sas";
%include "&_macropath./coarses/pull_woe_code.sas"; 


                                                                                                       
  

%get_vars_needed_for_woe(infile=keep_woe_vars.sas,coarsefile=coarses/flag_logic.txt,outfile=include_woe_vars.sas,dropfile=drop_orig_woes.txt);

data modeling_set_agb (drop=BUSINESSCITY);
	set dat.riscores_seg&segment_number   ;
	where perf_post in (0,1);
	
	
	 %include 'include_woe_vars.sas';


/*include risk groupings here*/

	  BUSINESSCITY=compress(compress(BUSINESSCITY,"'"),'"');
    %include "riskgroup/risk_city_g1.sas";
   
/*end risk groupings code*/
	
	%include 'gensq_call.sas';

	
RUN;




%logreg(iteration=1,                                                                                                  
        rootdir=.,                              
        datadir=&outdata./seg&segment_number./agb,                                      
        dset=modeling_set_agb,                                                                                     
        eventval=1,                                                                                                   
        noneventval=0,                                                                                                
        perfvar=perf_post,                                                                                      
        wghtvar=wghtfin,                                                                                          
        tpvvar=,                                                                                      
        lossvar=,                                                                                    
        unitdist=N,                                                                                                   
        varforced=,                                                                                         
        limitmodel=N,                                                                                       
        limititer=,                                                                                         
        sampling=PROPORTIONAL,                                                                                        
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
                                                                                                          
   
***********************************************;
%************"(@@@)ADDED for ANB modification"*;
***********************************************;
%MACRO create_logodds;
		
%if &ANB NE  %then %do;
 data  book rej  anb dat.scr_all_agb;
%end;
%if &ANB EQ  %then %do;
 data  book rej  dat.scr_all_agb;
%end;
    set   outdat.scrbld (Keep=predicted  perf_post wghtfin inferprob &appid &perf in=ina rename=(predicted=probag_ap))
       outdat.scrvld (Keep=p_1        perf_post wghtfin inferprob &appid &perf in=inb rename=(p_1=probag_ap)) ;
   

    score_agb_ap = log(probag_ap/(1-probag_ap));
    label score_agb_ap = 'Aligned GB Score from AGB Model at Application data';
    label probag_ap = 'Probability of Good Bad from AGB Model at Application Bureau';
	
***********************************************;
%************"(@@@)ADDED for ANB modification"*;
***********************************************;

    if &perf in (&good. &bad.) then output book ;
    if &perf in (&reject.) then output rej ;
    %if &ANB NE  %then %do;
       if &perf in (&ANB.) then output anb ;
    %end;
    output dat.scr_all_agb ;

 run;

 proc sort data=dat.scr_all_agb ;
    by &appid;
 run;
	 

	   
 /* The following code creates the plots that will be read by Macro formatting, to get the charts of Score VS Log(odds) */
 /* The macros cuts the tails, if your chart looks 'too bumpy', the reason is that there are not enough counts to create*/
 /* a score distributions with 20 breaks (default), so in those cases, you might want to rerun with less breaks         */
 /* especifically when there are not enough counts of a given performance group                                         */


 /*** Total ***/

 title1 "FOR PLOT ONLY ";
 title2 "&title_proj RI ALL Good-Bad Model.  ";

 %finesplt(dat.scr_all_agb,perf_post ,AllBad,0,0,AllGood,1,1, wghtfin,score_agb_ap ,10.4,20 );

 data temp_group ;
   set grouped end=last;
   log_odds=log(_nogood/_nobad);
   if _n_=1 then delete;
   if last then delete;
 run;

 
 data _null_;
   set temp_group;
   file 'all_odds.csv';
   if _n_=1 then put 'score, ALL';
   put  score_agb_ap','  log_odds;
 run;

 /* Booked Good Bad */

 title1 "FOR PLOT ONLY ";
 title2 "&title_proj RI ALL Good-Bad Model." ;
 
 %finesplt(book,perf_post ,KnwBad,0,0,KnwGood,1,1, wghtfin,score_agb_ap  ,10.4,20 );

 data temp_group ;
   set grouped end=last;
   log_odds=log(_nogood/_nobad);
   if _n_=1 then delete;
   if last then delete;
 run;


 data _null_;
   set temp_group;
   file 'knw_odds.csv';
   if _n_=1 then put 'score, KNOWN';
   put  score_agb_ap ','  log_odds;
 run;

***********************************************;
%************"(@@@)ADDED for ANB modification"*;
***********************************************;

%if &ANB NE  %then %do;
 /*** ANB ***/

 title1 "FOR PLOT ONLY ";
 title2 "&title_proj RI ALL Good-Bad Model.  ";

 %finesplt(anb,perf_post ,InfBad,0,0,InfGood,1,1, wghtfin,score_agb_ap ,10.4,20 );

 data temp_group ;
   set grouped end=last;
   log_odds=log(_nogood/_nobad);
   if _n_=1 then delete;
   if last then delete;
 run;

 data _null_;
   set temp_group;
   file 'anb_odds.csv';
   if _n_=1 then put 'score, ANB';
   put  score_agb_ap ','  log_odds;
 run;	  

%end;


 /*** rejects ***/

 title1 "FOR PLOT ONLY ";
 title2 "&title_proj RI ALL Good-Bad Model.  ";

 %finesplt(rej,perf_post ,InfBad,0,0,InfGood,1,1, wghtfin,score_agb_ap ,10.4,20 );

 data temp_group ;
   set grouped end=last;
   log_odds=log(_nogood/_nobad);
   if _n_=1 then delete;
   if last then delete;
 run;
 
 data _null_;
   set temp_group;
   file 'rejects_odds.csv';
   if _n_=1 then put 'score, REJECTS';
   put  score_agb_ap','  log_odds;
 run;
  
 
 
%MEND;

%create_logodds;                                                 