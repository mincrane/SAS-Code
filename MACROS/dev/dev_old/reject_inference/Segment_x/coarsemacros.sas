**********************************************************;
* coarsemacros.sas: macros used in coarses_infer_pg7.sas *;
* Include: GRABTIT, d_coarse_fct, d_coarse_splt, desc_f  *;
* Initial Release:                                       *;
* Last Update: jie 03/04/2005                            *;
*              copied from the preparation code for      *;
*              LOREAN, deleted the part for generating   *;
*              constraints and others not used in this   *;
*              preliminary model step                    *;
**********************************************************;
 
%macro GRABTIT(dataset,var,numb);	  
%global longname;
data grab;
  length lname $50;
  set &dataset (obs=1);
  call label(&char,lname);
  call symput("longname",put(lname,$50.));
run;
title&numb "&longname";
%mend GRABTIT;

%macro GRABTITN(dataset,var,numb);
data grab;
  length lname $50;
  set &dataset (obs=1);
  call label(&var,lname);
  call symput("longname","&var.: "||left(put(lname,$50.)));
run;
title&numb "&longname";
%mend GRABTITN;

%MACRO d_coarse_fct(DATASET,VAR,TITLE1,RNGBDL,RNGBDH,TITLE2,RNGGDL,RNGGDH,
      MLTPLY,CHAR,FORMAT,droplist,SPECS);

    %global _ks _gamma _concord _discord _tie;



**Read format name from file;

DATA _null_;
 length name $30;
 INFILE "format_names" DLM=",";
 input name $ name_for_format $;
 name=compress(name);
 name_for_format=compress(name_for_format);
 if upcase(name)=upcase("&char") THEN CALL SYMPUT("format_name",name_for_format); 
RUN;

%grabtit (&dataset,&char,3);
PROC FORMAT;
VALUE PRFFMT
&RNGBDL-&RNGBDH=' 0'
&RNGGDL-&RNGGDH=' 1'
OTHER=' 9';
RUN;
PROC FREQ DATA=&DATASET(keep= &var &char &mltply) order=formatted;
TABLES &VAR*&CHAR / NOPRINT OUT=zero;
      %if %length(&mltply) gt 0 %then %do;
      WEIGHT &MLTPLY;
      %end;
FORMAT &CHAR &FORMAT.;
FORMAT &VAR PRFFMT.;
data one;
  set zero;
format &var 4.;
if ( (&var ge &rngbdl) and (&var le &rngbdh) ) then &var=0;
else if ( (&var ge &rnggdl) and (&var le &rnggdh) ) then &var=1;
else delete;
DATA BAD(DROP=NOGOOD) GOOD(DROP=NOBAD);
SET ONE;
IF (&VAR=0) THEN NOBAD=COUNT;
ELSE NOGOOD=COUNT;
IF (&VAR=0) THEN OUTPUT BAD;
ELSE OUTPUT GOOD;
RUN;
PROC MEANS DATA=ONE NOPRINT;
VAR COUNT; BY &VAR;
OUTPUT OUT=SUMMARY SUM=NBYPRF;
PROC SORT DATA=BAD;
BY &CHAR;
PROC SORT DATA=GOOD;
BY &CHAR;
DATA FINAL1;
MERGE GOOD BAD;
BY &CHAR;
DATA FINAL;
SET FINAL1 end=endfl;


retain cumgd cumbd cumngd cumnbd _ks noconc nodisc notie;
IF (NOGOOD LE 0) THEN NOGOOD=0;
IF (NOBAD  LE 0) THEN NOBAD=0;
N=1;
SET SUMMARY POINT=N;
     TOTBAD=NBYPRF;
N=2;
SET SUMMARY POINT=N;
     TOTGOOD=NBYPRF;
PGOOD=(NOGOOD+0.00001)/(TOTGOOD+0.0001);
PBAD=(NOBAD+0.00001)/(TOTBAD+0.0001);
WEIGHT=LOG(PGOOD/PBAD);
CUMGD+PGOOD;
CUMBD+PBAD;
IVALUE = (PGOOD-PBAD)* WEIGHT;
CUMNBD+NOBAD;
CUMNGD+NOGOOD;

         absdif =100*abs(CUMGD-CUMBD);
         noconc+(TOTGOOD-CUMNGD)*NOBAD;
         nodisc+(TOTBAD-CUMNBD)*NOGOOD;
         notie+NOGOOD*NOBAD;
          if  (absdif gt _ks) then _ks = absdif;
          if ENDFL then do;
            call symput('_ks',compress(put(_ks,6.1)));
            if (noconc+nodisc) gt 0 then do;
              _gamma=(noconc-nodisc)/(noconc+nodisc);
            end;
            else do;
              _gamma=0;
            end;
            noconc=100*noconc/(TOTGOOD * TOTBAD);
            nodisc=100*nodisc/(TOTGOOD * TOTBAD);
            notie=100*notie/(TOTGOOD * TOTBAD);
            call symput('_gamma',compress(put(_gamma,6.3)));
            call symput('_concord',compress(put(noconc,5.1)));
            call symput('_discord',compress(put(nodisc,5.1)));
            call symput('_tie',compress(put(notie,5.1)));
			  END;
KEEP &CHAR NOGOOD PGOOD NOBAD PBAD WEIGHT IVALUE CUMGD CUMBD ;
RUN;


DATA _null_;
 SET final end=check;
   _cumiv+ ivalue;
   if check eq 1 then do;
      call symput('_ival',compress(put(_cumiv,12.3)));
  end;
RUN;

proc sort data=final; by &CHAR;

 
 title2 &CHAR ":" &longname     ;
 title3 "KS  value: " &_ks  ;
proc print data=final split='*';
var &char nogood nobad pgood pbad weight cumgd cumbd ivalue;
label  &char="&char"  nogood="&title2" nobad="&title1"
pgood="PROB.*&title2" pbad="PROB.*&title1" weight="WEIGHT*PATTERN"
cumgd="CUM.*&title2" cumbd="CUM.*&title1" ivalue="INFORMATION*VALUE";
sum ivalue nogood nobad pgood pbad;
format NOGOOD NOBAD 9.0;
format pgood pbad weight ivalue cumgd cumbd 5.3;
RUN;

%MEND d_coarse_fct;


%MACRO FINESPC(DATASET,VAR,TITLE1,RNGBDL,RNGBDH,TITLE2,RNGGDL,RNGGDH,
      MLTPLY,CHAR,FORMAT);

    %global _ks _gamma _concord _discord _tie;

      PROC FORMAT;
      VALUE PRFFMT
      &RNGBDL-&RNGBDH=' 0'
      &RNGGDL-&RNGGDH=' 1'
      OTHER=' 9';
      RUN;
      PROC FREQ DATA=&DATASET(keep= &var &char &mltply) order=formatted;
      TABLES &VAR*&CHAR / NOPRINT OUT=zero;
      %if %length(&mltply) gt 0 %then %do;
      WEIGHT &MLTPLY;
      %end;
      FORMAT &CHAR &FORMAT.;
      FORMAT &VAR PRFFMT.;
      data one;
        set zero;
      format &var 4.;
      if ( (&var ge &rngbdl) and (&var le &rngbdh) ) then &var=0;
      else if ( (&var ge &rnggdl) and (&var le &rnggdh) ) then &var=1;
      else delete;
      DATA BAD(DROP=NOGOOD) GOOD(DROP=NOBAD);
      SET ONE;
      IF (&VAR=0) THEN NOBAD=COUNT;
      ELSE NOGOOD=COUNT;
      IF (&VAR=0) THEN OUTPUT BAD;
      ELSE OUTPUT GOOD;
      RUN;
      PROC MEANS DATA=ONE NOPRINT;
      VAR COUNT; BY &VAR;
      OUTPUT OUT=SUMMARY SUM=NBYPRF;
      PROC SORT DATA=BAD;
      BY &CHAR;
      PROC SORT DATA=GOOD;
      BY &CHAR;
      DATA FINAL1;
      MERGE GOOD BAD;
      BY &CHAR;
      DATA FINAL;
      SET FINAL1 end=ENDFL;

      retain cumgd cumbd cumngd cumnbd _ks noconc nodisc notie;

      IF (NOGOOD LE 0) THEN NOGOOD=0;
      IF (NOBAD  LE 0) THEN NOBAD=0;
      N=1;
      SET SUMMARY POINT=N;
           TOTBAD=NBYPRF;
      N=2;
      SET SUMMARY POINT=N;
           TOTGOOD=NBYPRF;
      PGOOD=NOGOOD/TOTGOOD;
      PBAD=NOBAD/TOTBAD;
      CUMGD+PGOOD;
      CUMBD+PBAD;
      CUMNBD+NOBAD;
      CUMNGD+NOGOOD;

         absdif =100*abs(CUMGD-CUMBD);
         noconc+(TOTGOOD-CUMNGD)*NOBAD;
         nodisc+(TOTBAD-CUMNBD)*NOGOOD;
         notie+NOGOOD*NOBAD;
          if  (absdif gt _ks) then _ks = absdif;
          if ENDFL then do;
            call symput('_ks',compress(put(_ks,6.1)));
            if (noconc+nodisc) gt 0 then do;
              _gamma=(noconc-nodisc)/(noconc+nodisc);
            end;
            else do;
              _gamma=0;
            end;
            noconc=100*noconc/(TOTGOOD * TOTBAD);
            nodisc=100*nodisc/(TOTGOOD * TOTBAD);
            notie=100*notie/(TOTGOOD * TOTBAD);
            call symput('_gamma',compress(put(_gamma,6.3)));
            call symput('_concord',compress(put(noconc,5.1)));
            call symput('_discord',compress(put(nodisc,5.1)));
            call symput('_tie',compress(put(notie,5.1)));
         end;

      KEEP &CHAR NOGOOD NOBAD CUMGD CUMBD PGOOD PBAD;
      RUN;

%MEND FINESPC;



%MACRO d_coarse_splt(DATASET,VAR,TITLE1,RNGBDL,RNGBDH,TITLE2,RNGGDL,RNGGDH,
            MLTPLY,CHAR,FORMAT,PIECES,DROPLIST,SPECS,ROUND_VAR);
      

		**Read format name from file;

		DATA _null_;
		   length name $30;
 			INFILE "format_names" DLM=",";
 			input name $ name_for_format $;
		   name=compress(name);
 			name_for_format=compress(name_for_format);
 			if upcase(name)=upcase("&char") THEN CALL SYMPUT("format_name",name_for_format); 
		RUN;

      %grabtit (&dataset,&char,3);

      %finespc(&DATASET,&VAR,&TITLE1,&RNGBDL,&RNGBDH,&TITLE2,&RNGGDL,&RNGGDH,
            &MLTPLY,&CHAR,&FORMAT);
      data grouped;
        set final end=check ;
        retain lastind lastgd lastbd lastngd lastnbd cntmiss 0 _cumiv;
        if (&CHAR le .z) then cntmiss+1;
        indg=cntmiss+int( (cumgd+cumbd)/(2/&pieces) );
        totngd+nogood;
        totnbd+nobad;
        if (indg>lastind) or (check=1) then do;
          if ( (indg=lastind) and (check=1)) then indg=indg+1;
           pgood=(cumgd-lastgd+0.00001)/(1+((&pieces/2)*0.00001));
           pbad= (cumbd-lastbd+0.00001)/(1+((&pieces/2)*0.00001));
         if ((pgood+pbad)>0.04) or (check=1) or (&char le .z) then do;
           lastgd=cumgd;
           lastbd=cumbd;
           nogood=totngd-lastngd;
           nobad=totnbd-lastnbd;
           lastngd=totngd;
           lastnbd=totnbd;
           WEIGHT=LOG(PGOOD/PBAD);
           IVALUE = (PGOOD-PBAD)* WEIGHT;
			   _cumiv+ ivalue;
            if check eq 1 then do;
              call symput('_ival',compress(put(_cumiv,12.3)));
            end;

           KEEP &char indg NOGOOD PGOOD NOBAD PBAD WEIGHT IVALUE CUMGD CUMBD;
           output;
         end;
        end;
        lastind=indg;

        run;
		  title2 &CHAR ":" &longname ;   
	     title3 "KS  value: " &_ks  ;
      PROC PRINT DATA=grouped SPLIT='*';
      VAR indg &char nogood nobad pgood pbad weight cumgd cumbd ivalue;
      LABEL  indg="ID OF*GROUP" &CHAR="HIGH END*&CHAR" NOGOOD="&TITLE2" NOBAD="&TITLE1"
      PGOOD="PROB.*&TITLE2" PBAD="PROB.*&TITLE1" WEIGHT="WEIGHT*PATTERN"
      CUMGD="CUM.*&TITLE2" CUMBD="CUM.*&TITLE1" IVALUE="INFORMATION*VALUE";
      SUM IVALUE NOGOOD NOBAD PGOOD PBAD;
      FORMAT NOGOOD NOBAD 9.0;
      FORMAT PGOOD PBAD WEIGHT IVALUE CUMGD CUMBD 5.3;
      RUN;


	PROC UNIVARIATE DATA=&dataset (KEEP= &char ) NOPRINT;
     VAR &char  ;
     OUTPUT OUT=NT N=N  NMISS=NMISS STD=STD MEAN=MEAN MAX=MAX MIN=MIN
     PCTLPTS = 1 5 10 15 25 50 75 90 95 99
     PCTLPRE = P;

DATA NT ; SET NT ;
LENGTH NAME $30 ;
NAME="&char" ;
PMISS=(NMISS/N);
KS=&_ks;
IVAL=&_ival;
longname="&longname";




	   DATA _null_;
		  length char $32;
		  format &char 32.;
		  SET grouped (keep=&char) end=final ;
		  file "formgen.txt" mod;
		  IF NOT ( _n_=1 AND final=1)  THEN DO;
		  if _n_=1 /* AND "&round_var"="Y" */ THEN put "&char";
		  if &char=. THEN char="#";
		  else if &char<=.z THEN  char=compress("."||put(&char,32.));
/*
		  else if &char<-1000 THEN char=put(round(&char,50),32.);
		  else if &char<-500 THEN char=put(round(&char,10),32.);
		  else if &char<10 THEN char=put(&char,32.);
		  else if &char<500 THEN char=put(round(&char,10),32.);
		  else if &char<1000 THEN char=put(round(&char,50),32.);
		  else char=put(round(&char,100),32.);
*/
		  else char=put(&char,32.);
                 
			char=compress(char);
		  if final~=1 /* AND "&round_var"="Y" */ THEN put char @;
		  END;
 	  RUN;

	  

%MEND d_coarse_splt;

%MACRO desc_f(name_r);
PROC SORT DATA=dat2.&name_r;
  BY DESCENDING KS;
  RUN;

   PROC PRINT data=dat2.&name_r UNIFORM NOOBS;
   VAR NAME LONGNAME KS IVAL N  NMISS MEAN MIN P25
                               P50 P75 P95 P99 MAX;
   WHERE NAME NE '        ';
   FORMAT NAME   $15.


		  PMISS             percent6.1
		  MEAN                6.2
		  STD                 6.2
        P1 P5  P25          3.0
        P50 P75             4.0
        P90 P95 P99         6.0;
		  
   TITLE1 'DESCRIPTIVE STATISTICS';

%MEND desc_f;



