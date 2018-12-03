%macro scoredist_amt1(dset=,perfvar=,wghtvar=,scrvar=,tpvvar=,lossvar=,fmtname=,distname=);
	


title1 "Score Distribution (dollar): &distname.";


proc report data= &dset nowd split='*' headline headskip missing completerows;
 	column &scrvar. &tpvvar=_tpv tpvpct &lossvar=_loss losspct bps;
 	define &scrvar.    /group id 'Score*Interval' format=&fmtname.. order=internal  left;
 	define _tpv        /analysis sum 'TPV' format=COMMA15.;
 	define tpvpct      /computed 'Percent*TPV' format=PERCENT8.2;
 	define _loss       /analysis 'Loss' format=COMMA15.;
 	define losspct     /computed 'Percent*Loss' format=PERCENT8.2;
 	define bps         /computed 'BPS' format=8.0;
 	
 	rbreak after / summarize skip ol;
 	
 	compute before;
 	  tot_tpv= _tpv;
 	  tot_loss= abs(_loss);
 	endcomp;
 	
 	compute _loss;
 	  _loss=abs(_loss);
 	endcomp;
 	
 	compute tpvpct;
 	  tpvpct= _tpv/tot_tpv;
 	endcomp;
 	
 	compute losspct;
 	  losspct= abs(_loss/tot_loss);
 	endcomp;
 	
 	compute bps;
 	  bps= abs(_loss/_tpv)*10000;
 	endcomp;
 	
quit;
run;
 
title1;
  
%mend scoredist_amt1;