%macro scoredist_unit(dset=,perfvar=,wghtvar=,scrvar=,eval=,neval=,fmtname=,distname=,debug=NO,alert=NO);

%local epsilon;
%let epsilon = 1.0E-10;

data scored;
	set &dset.;
	
	event=    (&perfvar.= &eval.);
	nonevent= (&perfvar.= &neval.);
	
	%IF %length(&wghtvar.)= 0 %THEN %DO;
	  _wght= 1;
	  call symput('wghtvar','_wght');
	%END;
	
run;

proc means data=scored noprint;
	class &scrvar.;
	var event nonevent &scrvar.;
	weight &wghtvar.;
	output out=_means sumwgt(&wghtvar.)=_n sum(event nonevent)=sum_event sum_nonevent
	                                       max(&scrvar.)=MaxScore min(&scrvar.)=Minscore;
	format &scrvar. &fmtname..;
run;

data _means;
	if _n_=1 then do;
	  set _means;
	    retain total tot_event tot_nonevent;
	    if _type_=0 then do;
	  	  total= _n; tot_event= sum_event; tot_nonevent=sum_nonevent;
      end;
  end;
  set _means end=last;
    where _type_=1;
    retain align_alert_count reversal_alert_count  cum_event cum_nonevent ks iv_tot 0;
    cum_total+_n;
    cum_event+sum_event;
    cum_nonevent+sum_nonevent;
    
    int_event= sum_event/_n;
    int_nonevent= sum_nonevent/_n;
    
    if int_event>Maxscore OR int_event<Minscore THEN do;
    	  align_Alert="*";
        align_Alert_Count+1;
    end;   
    
    if lag(int_event)>int_event THEN 
     do; 
     	  reversal_alert_count+1;
     	  reversal_alert="*";
     end;	  
    
    cum_total_pct= cum_total/total;
    cum_event_pct= cum_event/tot_event;
    cum_nonevent_pct= cum_nonevent/tot_nonevent;
    cum_event_rate= cum_event/cum_total;
    cum_nonevent_rate= cum_nonevent/cum_total;
    odds =sum_event/sum_nonevent;
    ks= max(ks,abs(cum_event_pct - cum_nonevent_pct));
    
    _pevent= sum_event/tot_event;
    _pnonevent= sum_nonevent/tot_nonevent;
    woe= log((_pevent+&epsilon)/(_pnonevent+&epsilon));
    iv= (_pevent - _pnonevent)*woe;
    iv_tot+iv;
    
    if last then do;
    	call symput('ksval',ks*100);
    	call symput('ival',iv_tot);
    	call symput('Align',align_alert_count);
    	call symput('Rvrsl',reversal_alert_count);
    end;
    
    drop _type_ _freq_ total tot_event tot_nonevent _pevent _pnonevent ks iv_tot;
run;

%IF &debug. = YES %THEN %DO;  
  proc print data=_means;
  run; 
%END;

title1 justify=L "Score Distribution (unit): &distname.";
title2 justify=L "KS = %sysfunc(trim(%sysfunc(putn(&ksval.,8.2))))";
title3 justify=L "IV = %sysfunc(trim(%sysfunc(putn(&ival.,8.3))))";
                    
                   
                
proc report data=_means nowd split='*' headline headskip missing;
	column &scrvar.  %IF "&Alert"~="NO" %THEN %DO; reversal_alert align_Alert  %END; _n sum_event sum_nonevent odds cum_total_pct cum_event_pct cum_nonevent_pct
	       int_event int_nonevent cum_event_rate cum_nonevent_rate
	        ;
	
	define &scrvar.          /group id 'Score*Interval' width=20 left order=internal;
	define _n                /'Unit*Total' right format=COMMA10.;
	define sum_event         /'Unit*Event' right format=COMMA10.;
	define odds              /'Odds' right format=10.2;
	define sum_nonevent      /'Unit*Non Event' right format=COMMA10.;
	define cum_total_pct     /display 'Cum. Pct*Total' right format=PERCENT8.2;
	define cum_event_pct     /display 'Cum. Pct*Event' right format=PERCENT8.2;
	define cum_nonevent_pct  /display 'Cum. Pct*Non Event' right format=PERCENT8.2;
	define int_event         /display 'Interval*Event' right format=PERCENT8.2;
	define int_nonevent      /display 'Interval*Non Event' right format=PERCENT8.2;
	define cum_event_rate    /display 'Cum Rate*Event' right format=PERCENT8.2;
	define cum_nonevent_rate /display 'Cum Rate*Non Event' right format=PERCENT8.2;
	%IF "&Alert"~="NO" %THEN %DO;
  define reversal_alert /display 'Rvrsl*Alert' center format=$5.;
  define align_Alert  /display 'Align*Alert' center format=$5.;
  %END;
  rbreak after /summarize skip ol;
  
  compute after;
    odds=' ';
  endcomp;
  	
quit;
run;

title3;
title2;
title1;


DATA _alert;
	format dset $50.;
	DSET="&distname Reversal Count:" ;
	Count=&Rvrsl;
	output;
	DSET="&distname Alignment Alert Count:";
	Count=&Align;
	output;
RUN;

 PROC APPEND BASE=alert DATA=_alert FORCE;
 RUN;	
	

%mend scoredist_unit;