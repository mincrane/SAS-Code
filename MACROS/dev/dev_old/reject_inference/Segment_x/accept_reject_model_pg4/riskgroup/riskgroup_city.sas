options nocenter formdlim='-' ps=95;

%include "../autoexec.sas";
%include "&_macropath./general/macros_general.sas";
%include '../../parameters_pg1.sas';

libname dat "&dat" access=readonly;


options nocenter formdlim='-' noreplace obs=max;

%global totalm badm goodm;

/*data set name including the libname*/
%let fname = modeling_data_master;
/*risk group name*/
%let rname = risk_city;
/*variable to be grouped*/
%let rvar = BUSINESSCITY;
/*performance variable*/
%let perf = ar_flag;
/*weight variable*/
%let wgt =  &weight;
/*random number*/
%let random = 899881;
/*probability type - good or bad*/
%let ptype = bad;
/*Percentage in "other" group*/
%let perOther = 0.08;
/* percentage in building Sample */
%let percentBld = 0.70;


/*** industry regrouping ***/

data &fname;
	set dat.&build_set_ap&segment_number (KEEP=&rvar &perf &weight)
      dat.&valid_set_ap&segment_number (KEEP=&rvar &perf &weight) ;
      
      &rvar=compress(compress(&rvar,"'"),'"');
    
run;






/*******************************************************************/
/* Do not change below This                                        */
/*																																 */	
/*******************************************************************/

data bld vld;
   set &fname.;
   &wgt. = 1;
   ran = ranuni(&random.);
   if ran <= &percentBld then output bld;
   else output vld;
run;


/*** counts for each Industry/ZIP/Merchant cat-- no missing ***/
proc sql;
create table model as
select &rvar,&wgt,count(*) as count_t,sum(&perf) as count_b, calculated count_t -calculated count_b as count_g,
calculated count_b/calculated count_t as pbad
from bld
where &perf. in (0,1) and missing(&rvar)=0
group by &rvar,&wgt ;
quit;

/************ create macro variables of total counts ******************/

proc sql;
select count(*) as totalm,sum(&perf) as badm, calculated totalm -calculated badm as goods into : totalm , :badm , :goodm
from bld
where &perf. in (0,1);
quit;

/**** calculate the chi and p for each industry/zip/MCC**************/

data model1;
set model;
chi = (((count_g - count_t*&goodm/&totalm)*(count_g - count_t*&goodm/&totalm))/(count_t*&goodm/&totalm))
         + (((count_b - count_t*&badm/&totalm)*(count_b - count_t*&badm/&totalm))/(count_t*&badm/&totalm));
   p = 1 - probchi(chi,1);
   countAll+count_t; 
   call symput ('totalnm', countALL);
   keep &rvar. p&ptype. p chi count_t count_g count_b ;
run;


proc sort data=model1;
by p;
run;

/*** keep about 8% in other group - neutral group ***/

data model2;
set model1 end=last;
countAll+count_t;
percentP=countALl/&totalnm;
if percentP<= 1-&perOther;
call symput ('totalnmo',countAll);
run;

%put &totalnmo;
/*
proc print data=model2;
var &rvar p countAll percentp;
run;
*/

proc sort data=bld;
	by &rvar;
run;

proc sort data=model2;
	by &rvar;
run;

data test;
	merge bld(in=a) model2(in=b keep=p&ptype. &rvar.);
	by &rvar;
	if a and b then hash_rc=0;
	else hash_rc=1;
	if a;
run;


*%hashfind(bld,model2,test,,p&ptype,&rvar,&rvar,3);
/*
proc freq data=test;
tables p&ptype. /missing;
where missing(&rvar)=0 and hash_rc=0;
format p&ptype 6.5;
weight &wgt.;
run;
*/
proc sql;
create table test1 as
select p&ptype,count(*) as count
from test( where=( missing(&rvar)=0 and hash_rc=0))
group by p&ptype
order by p&ptype;
quit;


data test2;
set test1;
cumC+count;
cumP=cumc/&totalnmo;
pct1=round(abs(0.25-cump)*100000);
pct2=round(abs(0.50-cump)*100000);
pct3=round(abs(0.75-cump)*100000);
run;

proc sql;
select min(pct1),min(pct2),min(pct3) into : pct1, :pct2, :pct3
from test2;
quit;

data test2;
set test2;
if pct1=&pct1 then call symput("p1",p&ptype);
if pct2=&pct2 then call symput("p2",p&ptype);   
if pct3=&pct3 then call symput("p3",p&ptype);   
run;

%put &p1 &p2 &p3;


proc sort data=test;
by &rvar.;
run;


data test;
   set test end = last;
   by &rvar.;
     
     length &rname.risk $15;
     retain  tb t0 t1 t2 t3 t4;
	  if _n_ = 1 then do;
        tb = 0;
        t0 = 0;
        t1 = 0;
        t2 = 0;
        t3 = 0;
        t4 = 0;
          
       if tb = 0 then do;
         file "&rname._gb.sas";put "if &rvar. in ('',";
         end;
       if t0 = 0 then do;
         file "&rname._go.sas";put "if &rvar. in (";
         end;       
       if t1 = 0 then do ;
         file "&rname._g1.sas";put "if &rvar. in ("; 
         end;
       if t2 = 0 then do;
         file "&rname._g2.sas";put "if &rvar. in (";
         end;
       if t3 = 0 then do;
         file "&rname._g3.sas";put "if &rvar. in (";
         end;
       if t4 = 0 then do;
         file "&rname._g4.sas";put "if &rvar. in (";
         end;
     
     end;

     
     if dequote(&rvar.) in ('') then do;
       &rname.risk = 'BLANK'; 
       file "&rname._gb.sas";
     
       if first.&rvar. then put "'" &rvar. "',";
       tb = 1;
     end; 
     else
     if p&ptype <= .z then do;
        &rname.risk = 'OTHER';
        file "&rname._go.sas";
       
        if first.&rvar. then put "'" &rvar. "',";
        t0 = 1;
     end;
     else
     if p&ptype. <= &p1. then do;
        &rname.risk = '01';
        file "&rname._g1.sas";
        
        if first.&rvar. then put "'" &rvar. "',";
        t1 = 1;
     end;
     else
     if p&ptype. <= &p2. then do;
        &rname.risk = '02';
        file "&rname._g2.sas";
       
        if first.&rvar. then put "'" &rvar. "',";
        t2 = 1;
     end;
     else
     if p&ptype. <= &p3. then do;
        &rname.risk = '03';
        file "&rname._g3.sas";
       
        if first.&rvar. then put "'" &rvar. "',";
        t3 = 1;
     end;
     else do;
        &rname.risk = '04';
        file "&rname._g4.sas";
        
        if first.&rvar. then put "'" &rvar. "',";
        t4 = 1;
     end;
     
run;


proc freq data=test;
tables p&ptype. /missing;
where &rname.risk not in ('OTHER','BLANK');
format p&ptype 6.5;
weight &wgt.;
run;



data _null_;
   file "&rname._gb.sas" mod;
   put "'_last_') then &rname.gb = 1;";
   put "else &rname.gb = 0;";
run;

data _null_;
   file "&rname._go.sas" mod;
   put "'_last_') then &rname.go = 1;";
   put "else if &rname.gb=0 and &rname.g1=0 and &rname.g2=0 and &rname.g3=0 and &rname.g4=0 then &rname.go=1;";
   put "else &rname.go = 0;";
run;

data _null_;
   file "&rname._g1.sas" mod;
   put "'_last_') then &rname.g1 = 1;";
   put "else &rname.g1 = 0;";
run;

data _null_;
   file "&rname._g2.sas" mod;
   put "'_last_') then &rname.g2 = 1;";
   put "else &rname.g2 = 0;";
run;

data _null_;
   file "&rname._g3.sas" mod;
   put "'_last_') then &rname.g3 = 1;";
   put "else &rname.g3 = 0;";
run;

data _null_;
   file "&rname._g4.sas" mod;
   put "'_last_') then &rname.g4 = 1;";
   put "else &rname.g4 = 0;";
run;


data bld;
   set bld;
   %include "&rname._gb.sas";
   %include "&rname._g1.sas";
   %include "&rname._g2.sas";
	 %include "&rname._g3.sas";
   %include "&rname._g4.sas";
   %include "&rname._go.sas";

   if &rname.gb = 1 then &rname.risk = 'BLANK';
   else if &rname.g1 = 1 then &rname.risk = '01';
   else if &rname.g2 = 1 then &rname.risk = '02';
   else if &rname.g3 = 1 then &rname.risk = '03';
   else if &rname.g4 = 1 then &rname.risk = '04';
   else if &rname.go = 1 then &rname.risk = 'OTHER';
run;

title 'Build Test';
%finefct(bld,&perf. ,GOOD,0,0,BAD,1,1,&wgt.,&rname.risk , );
%finefct(bld,&perf. ,GOOD,0,0,BAD,1,1,&wgt.,&rname.gb , );
%finefct(bld,&perf. ,GOOD,0,0,BAD,1,1,&wgt.,&rname.go , );
%finefct(bld,&perf. ,GOOD,0,0,BAD,1,1,&wgt.,&rname.g1 , );
%finefct(bld,&perf. ,GOOD,0,0,BAD,1,1,&wgt.,&rname.g2 , );
%finefct(bld,&perf. ,GOOD,0,0,BAD,1,1,&wgt.,&rname.g3 , );
%finefct(bld,&perf. ,GOOD,0,0,BAD,1,1,&wgt.,&rname.g4 , );


data vld;
   set vld;
   %include "&rname._gb.sas";
   %include "&rname._g1.sas";
   %include "&rname._g2.sas";
	%include "&rname._g3.sas";
   %include "&rname._g4.sas";
   %include "&rname._go.sas";

   if &rname.gb = 1 then &rname.risk = 'BLANK';
   else if &rname.g1 = 1 then &rname.risk = '01';
   else if &rname.g2 = 1 then &rname.risk = '02';
   else if &rname.g3 = 1 then &rname.risk = '03';
   else if &rname.g4 = 1 then &rname.risk = '04';
   else if &rname.go = 1 then &rname.risk = 'OTHER';
run;

title 'Validate Test';
%finefct(vld,&perf. ,GOOD,0,0,BAD,1,1,&wgt.,&rname.risk , );
                                      
%finefct(vld,&perf. ,GOOD,0,0,BAD,1,1,&wgt.,&rname.gb , );
%finefct(vld,&perf. ,GOOD,0,0,BAD,1,1,&wgt.,&rname.go , );
%finefct(vld,&perf. ,GOOD,0,0,BAD,1,1,&wgt.,&rname.g1 , );
%finefct(vld,&perf. ,GOOD,0,0,BAD,1,1,&wgt.,&rname.g2 , );
%finefct(vld,&perf. ,GOOD,0,0,BAD,1,1,&wgt.,&rname.g3 , );
%finefct(vld,&perf. ,GOOD,0,0,BAD,1,1,&wgt.,&rname.g4 , );


