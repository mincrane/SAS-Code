options mprint symbolgen; *mlogic ;                                                  
                                                                                     
%MACRO SWAPSET(dataset,perfbri,perfari,wghtvar,scorevar,cutoff,outFile);             
data tempset;                                                                        
    set &dataset;                                                                    
run;                                                                                 
                                                                                     
proc freq data=tempset;                                                              
tables &perfbri &perfari / missing;                                                  
weight &wghtvar;                                                                     
run;                                                                                 
                                                                                     
proc sort data=tempset;                                                              
   by descending &scorevar ;                                                         
run;                                                                                 
                                                                                     
proc freq data=tempset;                                                              
tables &scorevar / missing;                                                          
weight &wghtvar;                                                                     
run;                                                                                 
                                                                                     
/**********************************************************************/             
/* Choose score cutoff so that the percentage of applicants           */             
/* falling at or above the cutoff equals the historic acceptance rate */             
/**********************************************************************/             
                                                                                     
data tempaccept tempdecline;                                                         
   set tempset;                                                                      
                                                                                     
   if (&scorevar >= &cutoff) then output tempaccept;                                 
   else output tempdecline;                                                          
run;                                                                                 
                                                                                     
proc freq data=tempaccept;                                                           
tables &perfbri / missing;                                                           
weight &wghtvar; /* e.g. wght - post reject inference weight */                      
title 'New Accepts';                                                                 
run;                                                                                 
                                                                                     
proc freq data=tempdecline;                                                          
tables &perfbri / missing;                                                           
weight &wghtvar;                                                                     
title 'New Declines';                                                                
run;                                                                                 
                                                                             
                                               
                                                                                     
proc freq data=tempaccept;                                                           
tables &perfari * &perfbri / missing out=naout;                                      
weight &wghtvar;                                                                     
title 'New Accepts Performance Frequency';                                           
run;                                                                                 
                                                                                     
*proc contents data=naout;                                                           
*run;                                                                                
*proc print data=naout;                                                              
*run;                                                                                
                                                                                     
data _null_;                                                                         
  set naout;                                                                         
  /* count of new accepts that were booked bads */                                   
  if &perfbri = 0 and &perfari = 0 then call symput('na_bb',round(count,1));         
  /* count of new accepts that were booked goods */                                  
  if &perfbri = 1 and &perfari = 1 then call symput('na_bg',round(count,1));         
  /* count of new accepts that were rejected bads */                                 
  if &perfbri = &reject and &perfari = 0 then call symput('na_rb',round(count,1));
  /* count of new accepts that were rejected goods */                                
  if &perfbri = &reject and &perfari = 1 then call symput('na_rg',round(count,1));
run;                                                                                 
                                                                                     
%put &na_bb;                                                                         
%put &na_bg;                                                                         
%put &na_rb;                                                                         
%put &na_rg;                                                                         
                                                                                     
proc freq data=tempdecline;                                                          
tables &perfari*&perfbri / missing out=ndout;                                        
weight &wghtvar;                                                                     
title 'New Declines Performance Frequency';                                          
run;                                                                                 
                                                                                     
proc contents data=ndout;                                                            
proc print data=ndout;                                                               
                                                                                     
data _null_;                                                                         
  set ndout;                                                                         
  /* count of new declines that were booked bads */                                  
  if &perfbri = 0 and &perfari = 0 then call symput('nd_bb',round(count,1));         
  /* count of new declines that were booked goods */                                 
  if &perfbri = 1 and &perfari = 1 then call symput('nd_bg',round(count,1));         
  /* count of new declines that were rejected bads */                                
  if &perfbri = &reject and &perfari = 0 then call symput('nd_rb',round(count,1));
  /* count of new declines that were rejected goods */                               
  if &perfbri = &reject and &perfari = 1 then call symput('nd_rg',round(count,1));
run;                                                                                 
                                                                                     
%put &nd_bb;                                                                         
%put &nd_bg;                                                                         
%put &nd_rb;                                                                         
%put &nd_rg;                                                                         
                                                                                     
data _null_;                                                                         
                                                                                     
 %if &outFile ne %then %do;                                                          
   file "&outFile" dlm = ',';                                                        
 %end;                                                                               
 %else %do;                                                                          
   file "swapset.out" dlm = ',';                                                     
 %end;                                                                               
                                                                                     
   sum_oa_na = &na_bb + &na_bg ;                                                     
   sum_oa_nr = &nd_bb + &nd_bg ;                                                     
   br_oa_na  = round((&na_bb/(&na_bb + &na_bg)),.0001);                              
   br_oa_nr  = round((&nd_bb/(&nd_bb + &nd_bg)),.0001);                              
                                                                                     
   sum_oa = sum_oa_na + sum_oa_nr;                                                   
   br_oa  = round((br_oa_na*sum_oa_na + br_oa_nr*sum_oa_nr)/sum_oa,.0001);           
                                                                                     
   sum_or_na = &na_rb + &na_rg ;                                                     
   sum_or_nr = &nd_rb + &nd_rg ;                                                     
   br_or_na  = round((&na_rb/(&na_rb + &na_rg)),.0001);                              
   br_or_nr  = round((&nd_rb/(&nd_rb + &nd_rg)),.0001);                              
                                                                                     
   sum_or = sum_or_na + sum_or_nr;                                                   
   br_or  = round((br_or_na*sum_or_na + br_or_nr*sum_or_nr)/sum_or,.0001);           
                                                                                     
   sum_na = sum_oa_na + sum_or_na;                                                   
   sum_nr = sum_oa_nr + sum_or_nr;                                                   
   br_na  = round((br_oa_na*sum_oa_na + br_or_na*sum_or_na)/sum_na,.0001);           
   br_nr  = round((br_oa_nr*sum_oa_nr + br_or_nr*sum_or_nr)/sum_nr,.0001);           
                                                                                     
   put sum_oa_na sum_oa_nr sum_oa;                                                   
   put br_oa_na br_oa_nr br_oa;                                                      
   put sum_or_na sum_or_nr sum_or;                                                   
   put br_or_na br_or_nr br_or;                                                      
   put sum_na sum_nr;                                                                
   put br_na br_nr;                                                                  
                                                                                     
run;                                                                                 
                                                                                     
                                                                        
                                                               
                                                                                     
title;                                                                               
                                                                                     
%MEND SWAPSET;                                                                       