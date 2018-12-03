************************************************************************;
* create_post_pg6.sas: 6th step in reject inference process            *;
*                      Create dataset with application variables and   *;
*                      inferred performance to be used in final model  *;
*                      building                                        *;
* Input: scr_all_ra (dataset with accept/reject score and probability  *;
*                     score and probabilities)                         *;
*        scr_all_gb (dataset with reject inference score and inferred  *;
*                    probabilities)                                    *;
*        application_data_seg&segment_number (app time variables)      *;  
* Output: dat.riscores_seg&segment_number                              *;
*         variables generated:                                         *;
*         - probb_re (prob of being bad)                               *;
*         - perf_post (final good/bad performance)                     *;
*         - wghtfin (final weight - &weight * infered prob)            *;
*         - inferprob (1 for booked, inferred prob for not booked)     *;
*         - perf_status (final performance status)                     *;
* Note: rejected and approved not booked records are parcelled into    *;
*       2 records (one for good and one for bad)                       *;
*       If the data does not contain approved not booked, modify       *;
*       the program accordingly (search for @@@)                       *;
* Initial Release:                                                     *;
* Modifications: Search for (@@@)to account for possible absence of    *;
*                Approved not booked accounts, code was put in place   *;
*		 to check for valid perf categories                    *;
************************************************************************;

%include 'parameters_pg1.sas';

/* Take the score of the rejects and ANB and merge to application data  */
/* Time of application dataset with RA probability, single observations */
/* dataset sorted by appid                                              */

*** KS - added this in because taken out of sample_g2.sas on 10_21_05;

proc sort data= dat.application_data_seg&segment_number;
  by &appid;
run;

data tempbk tempig tempib;
merge dat.scr_all_ra (in=ina keep= prob_ra score_ra  &appid ar_flag book_flag) 
      dat.scr_all_gb (in= inb keep=probg_re score_kgb_re &appid)		
      dat.application_data_seg&segment_number (in=inc);  
      probb_re=1-probg_re;
	
      by &appid;
      if ina and inb and inc;

/* Output booked/non-inferred accounts                  */

      if book_flag in (1,99) then do;  
                                 
       perf_post=&perf;                                                
       label perf_post = 'Final Performance';                         
       wghtfin = &weight;                                             
       inferprob = 1;                                             
       label wghtfin = 'Final Weight';                              
       label inferprob = 'Inferred Prob';                              
       output tempbk;                                             
      end;   

/* Assign Good performance to Rejected Accounts and ANB  */
/* Splitting each record into two records, one gets the  */
/* probability of good times the weight                  */

     if book_flag=0 then do;    
                    
       perf_post=1;                                                   
       label perf_post = 'Final Performance';                         
       wghtfin = &weight*probg_re;                                    
       inferprob = probg_re;                                    
       label wghtfin = 'Final Weight';                              
       label inferprob = 'Inferred Prob';                              
       output tempig;                                             
     end;  

/* Assign Bad performance to Rejected Accounts and ANB  */
/* Splitting each record into two records, one gets the */
/* probability of bad times the weight                  */

   if book_flag=0 then do;   
                         
       perf_post=0;                                                   
       label perf_post = 'Final Performance';                         
       wghtfin = &weight*probb_re;                                    
       inferprob = probb_re;                                    
       label wghtfin = 'Final Weight';                              
       label inferprob = 'Inferred Prob';                              
       output tempib;                                             
     end;
run;                      
                                                                                                              
  
data dat.riscores_seg&segment_number (compress=yes);                                  
  set tempbk tempig tempib;
	length perf_status $5.;
   if ar_flag=1 and book_flag=0 and perf_post=1 then  perf_status='ANB-G'; 
   if ar_flag=1 and book_flag=0 and perf_post=0 then  perf_status='ANB-B'; 
   if ar_flag=0 and book_flag=0 and perf_post=1 then  perf_status='REJ-G'; 
   if ar_flag=0 and book_flag=0 and perf_post=0 then  perf_status='REJ-B'; 
   if ar_flag=1 and book_flag=1 and perf_post=1 then  perf_status='KNW-G'; 
   if ar_flag=1 and book_flag=1 and perf_post=0 then  perf_status='KNW-B'; 
run;    
 
proc format;
value prfgrp
&good., &bad = 'KNOWN'
&reject = 'REJ'
&ANB = 'ANB';

	
proc freq data= dat.riscores_seg&segment_number  ;
     tables perf_post*&perf;
     format &perf prfgrp.;
     title 'Time of Application Data, Final Rejected Performance, Unweighted';
     title2 'Check the counts for original raw goods and bads - Rej&ANB doubled';
run;

proc freq data= dat.riscores_seg&segment_number  ;
     tables perf_post*&perf;
     format &perf prfgrp.;
     title 'Time of Application Data, Final Rejected Performance, Weighted with wghtfin';
     title2 'Check the counts for original weighted goods and bads - same as original';
     weight wghtfin;
run;

  
proc freq data=dat.riscores_seg&segment_number  ;
   weight wghtfin;
   tables perf_status /noprint out=status_table;
run;   
  
%let countanbg = 0;
%let countanbb = 0;

data status_table;
   set status_table;
    if  perf_status='ANB-G' then call symput ('countanbg',put(count,7.));                  
    if  perf_status='ANB-B' then call symput ('countanbb',put(count,7.));                                                           
    if  perf_status='REJ-G' then call symput ('countrejg',put(count,7.));       
    if  perf_status='REJ-B' then call symput ('countrejb',put(count,7.));       
    if  perf_status='KNW-G' then call symput ('countknwg',put(count,7.));       
    if  perf_status='KNW-B' then call symput ('countknwb',put(count,7.));  
	 
run;


data status_table;
	set status_table;
	call symput ('gb_known' , round((&countknwg/&countknwb),.01));

	%************"(@@@)ADDED for ANB modification"*************;
	test= "&ANB.";
	if compress(test) NE "" then do;
		call symput ('igb_anb' , round((&countanbg /&countanbb ),.01));
	end;
	%***************************************************;

	call symput ('igb_rej' , round((&countrejg/&countrejb),.01));
	call symput ('allinf' , round(((%eval(&countanbg+&countrejg))/(%eval(&countanbb+&countrejb))),.01));
	call symput ('allodds' , round(((%eval(&countanbg+&countrejg+&countknwg))/(%eval(&countanbb+&countrejb+&countknwb))),.01));
run;

option nocenter;


%************"(@@@) MACRO print_statustab: ADDED for ANB modification"*************;

%MACRO print_statustab();
data _NULL_;
	test= "&ANB.";
	if compress(test) = "" then do;
		call symput ('COMMENT_OUT_REG','*');
		call symput ('COMMENT_OUT_CUST',' ');
	end;
	else 	do;
		call symput ('COMMENT_OUT_REG',' ');
 		call symput ('COMMENT_OUT_CUST','*');
	end;
run;

proc print data=status_table;
	title "                         ";
        title1 " CHECK THE FOLLOWING ODDS AND COUNTS";
	title2 " Known Good Bad Odds = # Known Goods / # Known Bads = &countknwg / &countknwb = &gb_known";
	title3 " Infered Reject Odds = # Inf Reject Goods / # Inf Reject Bads = &countrejg / &countrejb = &igb_rej";
	&COMMENT_OUT_REG.	title4 " Infered ANB Odds = # Inf ANB Goods / # Inf ANB Bads = &countanbg / &countanbb= &igb_anb";
	&COMMENT_OUT_REG.	title5 " All Good Bad Odds(Known+Infered) = # Goods Known+Inf / # Bads Known+Inf = %eval(&countanbg+&countrejg+&countknwg) / %eval(&countanbb+&countrejb+&countknwb) = &allodds";
     where percent~=.;
 run;

%MEND print_statustab;

%print_statustab();


options center;
   

title 'KG/KB Only - KGB Score - WGHTFIN';
%finesplt(dat.riscores_seg&segment_number,&perf,BAD,&bad,&bad,GOOD,&good,&good,wghtfin,score_kgb_re,10.4,10);
title 'All Good/All Bad - KGB Score - WGHTFIN';
%finesplt(dat.riscores_seg&segment_number,perf_post,BAD,0,0,GOOD,1,1,wghtfin,score_kgb_re,10.4,10);
 

title "riscores_seg&segment_number";
proc contents data = dat.riscores_seg&segment_number;
run;

