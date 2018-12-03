%include "swapset_macro.sas";           

%include "parameters_pg1.sas";

                                  
                                                                            
%macro acceptrt(inData,inWeight);                                           
                                                                            
 /* Match original acceptance rate swapset */                               
                                                                            
 * calculate original acceptance rate *;  
                                   
proc freq data=&inData;                                                     
tables &perf / missing outcum out=origperc;                            
weight &inWeight;                                                           
Title "Weighted Original Performance Distribution ";                        
run;                                                                        
     * percent sum for subset of good,bad, and maybe uncashed *;            
data _null_;                                                                
 set origperc end=last;                                                     
 retain orig_acc_rate 0;                                                    
 where &perf in (0 1 );                                                                       
 orig_acc_rate = sum(orig_acc_rate,percent);                                
 if last then do;   * original acceptance rate *;                           
  put orig_acc_rate;                                                        
  call symput('orig_ar',compress(orig_acc_rate));                           
 end;                                                                       
run;                                                                        
%put &orig_ar;                                                              
                                                                            
  * score distribution *;                                                   
proc freq data=&inData ;                                                    
tables score_agb_ap  / missing outcum out=newScore;                                 
weight &inWeight;                                                           
Title "Weighted Score Distribution ";                                       
run;                                                                        
                                                                            
  * lookup score that matches original acceptance rate *;                   
%let newscoreAR=;                                                           
data _null_;                                                                
 set newScore;                                                              
 retain found 0;                                                            
 if not found and ( cum_pct >= (100 - &orig_ar) ) then  do;                 
  call symput('newscoreAR',compress(score_agb_ap ));                                
  found=1;                                                                  
  stop;                                                                     
 end;                                                                       
run;                                                                        
%put new score_agb_ap  Acceptance Rate &newscoreAR;                                 
                                                                            
  * Acceptance Rate swapset *;                                              
%if &newscoreAr ne  %then %do;                                              
  %swapset(&inData,&perf,perf_post,&inWeight,score_agb_ap ,&newscoreAR,swapAr.out);
%end;                                                                       
%else %put ERROR: No New Score Matching Original Acceptance Rate ;          
                                                                            
%mend acceptrt;   
%acceptrt(dat.scr_all_agb,wghtfin);                                                          