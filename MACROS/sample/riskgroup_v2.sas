option formdlim="_" error=2 compress="YES"; ** mprint merror serror symbolgen mlogic;

/*** add point -1 to 'put' statement to prevent the space in the output **/
libname raw '/ebaysr/projects/EG/model/data';

/*** zip code, country, mcc code etc. zip only first three ***/
data new;
set raw.qp_all_tran;
where b2c_c2c_flag = 'C2C';
run;


%include '/ebaysr/MACROS/release/macros_general.sas';


%macro HashFInd(DataM,Data2,dataOut,var1,var2,key1,key2,flag);

/** this is for including all variables from data2 **/
%if %length(&var2)=0 %then %do;
%let allvar2="&key2";
%let missvar2=&key2;
%end;
%else %do;

%if %upcase(%sysfunc(compress(&var2))) ^= ALL %then %do; 
proc contents data=&data2(keep=&var2) out=cont noprint;
run;

proc sql noprint;
select '"' ||trim(name) || '"' into : allvar2 separated by ","
from cont; 
/** macro variable var2 for missing call if no input var2 ***/
select trim(name) into: missvar2 separated by ","
from cont;
quit;
%end;

%else %do;

proc contents data=&data2 out=cont noprint;
run;

proc sql noprint;
select '"' ||trim(name) || '"' into : allvar2 separated by ","
from cont; 
/** macro variable var2 for missing call if no input var2 ***/
select trim(name) into: missvar2 separated by ","
from cont;

select trim(name) into : var2 separated by " "
from cont; 
quit;
%end;

%end;


proc format;
value hashFmt
 low - <0 = "Non-Matched"
 0        = "Matched"
 other    = "Other"; 
run;

data &dataOut;

if _N_=1 then do;

if 0 then set &data2(keep=&var2 &key2);

Declare Hash MyLkup(HashExp:8,Dataset:"&data2");
MyLkup.DefineKey("&key2");
MyLkup.DefineData(&allvar2);
myLkup.defineDone();
*call missing(&allvar2);
end;

set &dataM(keep=&var1);

HASH_rc=MyLkup.find(key:&key1.);

if &flag=1 then do;
if HASH_rc=0;
end;

if &flag=2 then do;
if HASH_rc^=0;
call missing(&missvar2);
end;

if &flag=3 then do;
if hash_rc^=0 then call missing(&missvar2);
end;
run;


%if &flag = 3 %then %do;
proc freq data=&dataout;
table hash_rc;
format hash_rc hashFMT.;
run;
%end;

%mend;


options nocenter formdlim='-' noreplace obs=max;

%global totalm badm goodm;

/*data set name*/
%let fname = new;
/*risk group name*/
%let rname = risk_qp_c2c;
/*variable to be grouped*/
%let rvar = categ_lvl2_id; *sap_category_id;
/*performance variable*/
%let perf = perf_bad;
/*weight variable*/
%let wgt =  wgt;
/*random number*/
%let random = 9881;
/*probability type - good or bad*/
%let ptype = good;
/*Percentage in "other" group*/
%let perOther = 0.08;
/* percentage in building Sample */
%let percentBld = 0.70;


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


proc freq data=bld noprint;
	table &rvar.*&perf/missing;
	where missing(&rvar.)=1;
run;

proc freq data=bld;
table /*&rvar.*/  &perf/missing;
run;

proc freq data=vld;
table /*&rvar.*/  &perf/missing;
run;


proc sort data=bld out=test nodupkey;
by &rvar;
run;


/*** counts for each zip/merchant cat-- no missing ***/
proc sql;
create table model as
select &rvar,&wgt,count(*) as count_t,sum(&perf) as count_g, calculated count_t -calculated count_g as count_b,
calculated count_g/calculated count_t as pgood
from bld
where &perf. in (0,1) and missing(&rvar)=0
group by &rvar,&wgt ;
quit;

/************ create macro variables of total counts ******************/

proc sql;
select count(*) as totalm,sum(&perf) as goodm, calculated totalm -calculated goodm as bads into : totalm , :goodm , :badm
from bld
where &perf. in (0,1);
quit;

/**** calculate the chi and p for each zip/merchant cat**************/

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
%hashfind(bld,model2,test,,p&ptype,&rvar,&rvar,3);
/*
proc freq data=test;
tables p&ptype. /missing;
where missing(&rvar)=0 and hash_rc=0;
format pgood 6.5;
weight &wgt.;
run;
*/
proc sql;
create table test1 as
select pgood,count(*) as count
from test( where=( missing(&rvar)=0 and hash_rc=0))
group by pgood
order by pgood;
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
if pct1=&pct1 then call symput("p1",pgood);
if pct2=&pct2 then call symput("p2",pgood);   
if pct3=&pct3 then call symput("p3",pgood);   
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
         file "&rname._gb.sas";put "if compress(&rvar.) in ('',";
         end;
       if t0 = 0 then do;
         file "&rname._go.sas";put "if compress(&rvar.) in (";
         end;       
       if t1 = 0 then do ;
         file "&rname._g1.sas";put "if compress(&rvar.) in ("; 
         end;
       if t2 = 0 then do;
         file "&rname._g2.sas";put "if compress(&rvar.) in (";
         end;
       if t3 = 0 then do;
         file "&rname._g3.sas";put "if compress(&rvar.) in (";
         end;
       if t4 = 0 then do;
         file "&rname._g4.sas";put "if compress(&rvar.) in (";
         end;
     
     end;

     
     if &rvar. in ('') then do;
       &rname.risk = 'BLANK'; 
       file "&rname._gb.sas";
     
       if first.&rvar. then put "'" &rvar. +(-1) "',";
       tb = 1;
     end; 
     else
     if p&ptype <= .z then do;
        &rname.risk = 'OTHER';
        file "&rname._go.sas";
       
        if first.&rvar. then put "'" &rvar. +(-1) "',";
        t0 = 1;
     end;
     else
     if p&ptype. <= &p1. then do;
        &rname.risk = '01';
        file "&rname._g1.sas";
        
        if first.&rvar. then put "'" &rvar. +(-1) "'," ;
        t1 = 1;
     end;
     else
     if p&ptype. <= &p2. then do;
        &rname.risk = '02';
        file "&rname._g2.sas";
       
        if first.&rvar. then put "'" &rvar. +(-1) "',";
        t2 = 1;
     end;
     else
     if p&ptype. <= &p3. then do;
        &rname.risk = '03';
        file "&rname._g3.sas";
       
        if first.&rvar. then put "'" &rvar. +(-1) "',";
        t3 = 1;
     end;
     else do;
        &rname.risk = '04';
        file "&rname._g4.sas";
        
        if first.&rvar. then put "'" &rvar. +(-1) "',";
        t4 = 1;
     end;
     
run;


proc freq data=test;
tables p&ptype. /missing;
where &rname.risk not in ('OTHER','BLANK');
format pgood 6.5;
weight &wgt.;
run;



data _null_;
   file "&rname._gb.sas" mod;
   put "'_last_') then &rname.gb = '1';";
   put "else &rname.gb = '0';";
run;

data _null_;
   file "&rname._go.sas" mod;
   put "'_last_') then &rname.go = '1';";
   put "else if &rname.gb='0' and &rname.g1='0' and &rname.g2='0' and &rname.g3='0' and &rname.g4='0' then &rname.go='1';";
   put "else &rname.go = '0';";
run;

data _null_;
   file "&rname._g1.sas" mod;
   put "'_last_') then &rname.g1 = '1';";
   put "else &rname.g1 = '0';";
run;

data _null_;
   file "&rname._g2.sas" mod;
   put "'_last_') then &rname.g2 = '1';";
   put "else &rname.g2 = '0';";
run;

data _null_;
   file "&rname._g3.sas" mod;
   put "'_last_') then &rname.g3 = '1';";
   put "else &rname.g3 = '0';";
run;

data _null_;
   file "&rname._g4.sas" mod;
   put "'_last_') then &rname.g4 = '1';";
   put "else &rname.g4 = '0';";
run;


data bld;
   set bld;
   %include "&rname._gb.sas";
   %include "&rname._g1.sas";
   %include "&rname._g2.sas";
	%include "&rname._g3.sas";
   %include "&rname._g4.sas";
   %include "&rname._go.sas";

   if &rname.gb = '1' then &rname.risk = 'BLANK';
   else if &rname.g1 = '1' then &rname.risk = '01';
   else if &rname.g2 = '1' then &rname.risk = '02';
   else if &rname.g3 = '1' then &rname.risk = '03';
   else if &rname.g4 = '1' then &rname.risk = '04';
   else if &rname.go = '1' then &rname.risk = 'OTHER';
run;

title 'Build Test';
%finefct(bld,&perf. ,BAD,0,0,GOOD,1,1,&wgt.,&rname.risk , );
%finefct(bld,&perf. ,BAD,0,0,GOOD,1,1,&wgt.,&rname.gb , );
%finefct(bld,&perf. ,BAD,0,0,GOOD,1,1,&wgt.,&rname.go , );
%finefct(bld,&perf. ,BAD,0,0,GOOD,1,1,&wgt.,&rname.g1 , );
%finefct(bld,&perf. ,BAD,0,0,GOOD,1,1,&wgt.,&rname.g2 , );
%finefct(bld,&perf. ,BAD,0,0,GOOD,1,1,&wgt.,&rname.g3 , );
%finefct(bld,&perf. ,BAD,0,0,GOOD,1,1,&wgt.,&rname.g4 , );


data vld;
   set vld;
   %include "&rname._gb.sas";
   %include "&rname._g1.sas";
   %include "&rname._g2.sas";
	%include "&rname._g3.sas";
   %include "&rname._g4.sas";
   %include "&rname._go.sas";

   if &rname.gb = '1' then &rname.risk = 'BLANK';
   else if &rname.g1 = '1' then &rname.risk = '01';
   else if &rname.g2 = '1' then &rname.risk = '02';
   else if &rname.g3 = '1' then &rname.risk = '03';
   else if &rname.g4 = '1' then &rname.risk = '04';
   else if &rname.go = '1' then &rname.risk = 'OTHER';
run;

title 'Validate Test';
%finefct(vld,&perf. ,BAD,0,0,GOOD,1,1,&wgt.,&rname.risk , );

%finefct(vld,&perf. ,BAD,0,0,GOOD,1,1,&wgt.,&rname.gb , );
%finefct(vld,&perf. ,BAD,0,0,GOOD,1,1,&wgt.,&rname.go , );
%finefct(vld,&perf. ,BAD,0,0,GOOD,1,1,&wgt.,&rname.g1 , );
%finefct(vld,&perf. ,BAD,0,0,GOOD,1,1,&wgt.,&rname.g2 , );
%finefct(vld,&perf. ,BAD,0,0,GOOD,1,1,&wgt.,&rname.g3 , );
%finefct(vld,&perf. ,BAD,0,0,GOOD,1,1,&wgt.,&rname.g4 , );



















endsas;
FTP::CAP\/sas/pprd/austin/projects/caps/2011/behavior_score|pg10_varagg.sas
endsas;

  %include "industry.txt";
   
subindustry_cat 

proc contents data=dat.final_data;
run;


endsas;
	
	
	dat.score_perf_table
	
	
run;

SubIndustry_Cat
subindustry 
