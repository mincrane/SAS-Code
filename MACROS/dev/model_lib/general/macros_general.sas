

**********************************************************************************;
**********************************************************************************;  
*** 4. GRABTITL(dataset,var,numb)       					 			                ***;
**********************************************************************************; 
**********************************************************************************;

%macro GRABTITL(dataset,var,numb);
%global longname;
data grab;
  length lname $50;
  set &dataset (obs=1);
  call label(&var,lname);
  call symput("longname",trim(left(put(lname,$50.))));
run;
title&numb "&longname";
%mend GRABTITL;

**********************************************************************************;
**********************************************************************************;  
*** 5. FINESPC(dataset,var,title1,rngbdl,rngbdh,title2,rnggdl,rnggdh,			 ***;
***            mltply,char,format)           			                         ***;
**********************************************************************************; 
**********************************************************************************;
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

		PROC FREQ DATA=&DATASET(keep= &var &char &mltply) order=formatted;
	   tables &var*&char / noprint out = raw_counts(drop = percent);
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


		data rawone (drop = &var);
		set raw_counts ;
		if ( (&var ge &rngbdl) and (&var le &rngbdh) ) then raw_&var=0;
		else if ( (&var ge &rnggdl) and (&var le &rnggdh) ) then raw_&var=1;
		else delete;
		run ;

      DATA RAWBAD(DROP=RAWGOOD) RAWGOOD(DROP=RAWBAD);
       SET rawone;
       IF (raw_&VAR=0) THEN RAWBAD=COUNT;
       ELSE RAWGOOD=COUNT;
       IF (raw_&VAR=0) THEN OUTPUT RAWBAD;
       ELSE OUTPUT RAWGOOD;
      RUN;
		PROC SORT DATA=RAWBAD;
      BY &CHAR;
      PROC SORT DATA=RAWGOOD;
      BY &CHAR;



      DATA FINAL1;
      MERGE GOOD BAD RAWGOOD RAWBAD;
      BY &CHAR;

      DATA FINAL;
      SET FINAL1 end=ENDFL;

      retain cumgd cumbd cumngd cumnbd _ks noconc nodisc notie;

      IF (NOGOOD LE 0) THEN NOGOOD=0;
      IF (NOBAD  LE 0) THEN NOBAD=0;
		IF (RAWGOOD LE 0) THEN RAWGOOD=0;
      IF (RAWBAD  LE 0) THEN RAWBAD=0;

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

      KEEP &CHAR NOGOOD NOBAD CUMGD CUMBD PGOOD PBAD RAWGOOD RAWBAD;
      RUN;

 DATA final;
  SET final (RENAME=(NOGOOD=_NOGOOD NOBAD=_NOBAD PGOOD=_PGOOD PBAD=_PBAD 
                      CUMGD=_CUMGD CUMBD=_CUMBD));
RUN;

%MEND FINESPC; 

**********************************************************************************;
**********************************************************************************;  
*** 6. FINEFCT(dataset,var,title1,rngbdl,rngbdh,title2,rnggdl,rnggdh,			 ***;
***            mltply,char,format)           			                         ***;
**********************************************************************************; 
**********************************************************************************;
**-------------  
| Descrp. Course display macro for character variables   
|                     
| Parameter: dataset    - Input Dataset                          
| Parameter: var        - Performance variable                           
| Parameter: title1     - title for "bad" performance
| Parameter: rngbdl     - Lower limit for "bad" performance          
| Parameter: rngbdh     - Higher limit for "bad" performance 
| Parameter: title2     - title for "good" performance                        
| Parameter: rnggdl     - Lower limit for "good" performance                          
| Parameter: rnggdh     - Higher limit for "good" performance
| Parameter: mltply     - Weight   
| Parameter: char       - ??
| Parameter: format     - ??
**------------- ;


%MACRO FINEFCT(DATASET,VAR,TITLE1,RNGBDL,RNGBDH,TITLE2,RNGGDL,RNGGDH,
      MLTPLY,CHAR,FORMAT);
      title3 &CHAR;
      %grabtitl (&dataset,&char,4);

      %finespc(&DATASET,&VAR,&TITLE1,&RNGBDL,&RNGBDH,&TITLE2,&RNGGDL,&RNGGDH,
            &MLTPLY,&CHAR,&FORMAT);
      %global _ival _ks _gamma;
      data grouped (rename=(rawgood=_rawgood rawbad=_rawbad));
        set final end=_endfl ;
          _ODDS = _nogood/_NOBAD;
        if _pgood le 0 then _pgood=0.00001;
        if _pbad le 0 then _pbad=0.00001;
        _weight=log(_pgood/_pbad);
        _ivalue = (_pgood-_pbad)* _weight;
        _cumiv+_ivalue;
        if _endfl eq 1 then do;
          call symput('_ival',compress(put(_cumiv,12.3)));
        end;
     run;
     proc sort data=grouped; by &char;
   run;
   
   

   
     proc print data=grouped split='*';
     var &char _nogood _rawgood _nobad  _rawbad _pgood _pbad _weight _cumgd _cumbd _ivalue _ODDS;
     label  &char="&char"  _nogood="&title2" _rawgood = "RAW* &title2" _nobad="&title1"
     _rawbad = "RAW* &title1" _pgood="PROB.* &title2" _pbad="PROB.* &title1" _weight="WEIGHT* PATTERN"
     _cumgd="CUM.* &title2" _cumbd="CUM.* &title1" _ivalue="INFORMATION* VALUE" 
	    _odds="ODDS";
     sum _ivalue _nogood _rawgood _nobad _rawbad _pgood _pbad  ;
     format _nogood _nobad _rawgood _rawbad 9.0 ;
     format _pgood _pbad _weight _ivalue _cumgd _cumbd 5.3;
     format _odds 8.1;
     title5 " ";
	 	title6 "KS Value : &_ks   Gamma Value: &_gamma  Information Value:  &_ival ";
     RUN;
%MEND FINEFCT;

**********************************************************************************;
**********************************************************************************;  
*** 7. FINESPLT(dataset,var,title1,rngbdl,rngbdh,title2,rnggdl,rnggdh,			 ***;
***            mltply,char,format, pieces)      			                      ***;
**********************************************************************************; 
**********************************************************************************;

**-------------  
| Descrp. Course display macro for numeric variables   
|                     
| Parameter: dataset    - Input Dataset                          
| Parameter: var        - Performance variable                           
| Parameter: title1     - title for "bad" performance
| Parameter: rngbdl     - Lower limit for "bad" performance          
| Parameter: rngbdh     - Higher limit for "bad" performance 
| Parameter: title2     - title for "good" performance                        
| Parameter: rnggdl     - Lower limit for "good" performance                          
| Parameter: rnggdh     - Higher limit for "good" performance
| Parameter: mltply     - Score    
| Parameter: char       - ??
| Parameter: format     - ??
| Parameter: pieces     - ??
**------------- ;

%MACRO FINESPLT(DATASET,VAR,TITLE1,RNGBDL,RNGBDH,TITLE2,RNGGDL,RNGGDH,
            MLTPLY,CHAR,FORMAT,PIECES);
      title3 &CHAR;
      %grabtitl (&dataset,&char,4);

      %finespc(&DATASET,&VAR,&TITLE1,&RNGBDL,&RNGBDH,&TITLE2,&RNGGDL,&RNGGDH,
            &MLTPLY,&CHAR,&FORMAT);
      %global _ival _ks reversals;
      data grouped;
        set final end=_endfl ;
        retain _lastind _lastgd _lastbd _lastngd _lastnbd _cntmiss 0 _cumiv 0 _rawgood _rawbad 0;
        if (&CHAR le .z) then _cntmiss+1;
        _indg=_cntmiss+int( (_cumgd+_cumbd)/(2/&pieces) );
        _totngd+_nogood;
        _totnbd+_nobad;

		  _rawgood+rawgood;
		  _rawbad+rawbad;

        if (_indg>_lastind) or (_endfl=1) then do;
          if ( (_indg=_lastind) and (_endfl=1)) then _indg=_indg+1;
          _pgood=(_cumgd-_lastgd+0.00001)/(1+((&pieces/2)*0.00001));
          _pbad= (_cumbd-_lastbd+0.00001)/(1+((&pieces/2)*0.00001));
          if ((_pgood+_pbad)>0.04) or (_endfl=1) or (&char le .z) then do;
            _lastgd=_cumgd;
            _lastbd=_cumbd;
            _nogood=_totngd-_lastngd;
            _nobad=_totnbd-_lastnbd;
            _lastngd=_totngd;
            _lastnbd=_totnbd;
            _weight=LOG(_pgood/_pbad);
            _ivalue = (_pgood-_pbad)* _weight;
            _cumiv+_ivalue;
            if _endfl eq 1 then do;
              call symput('_ival',compress(put(_cumiv,12.3)));
            end;
             _ODDS = _nogood/_NOBAD;
            KEEP &char _indg _nogood _pgood _nobad _pbad _weight _ivalue _cumgd _cumbd _rawgood _rawbad _odds;
            output;
				_rawgood=0;	 
				_rawbad=0;
          end;
        end;
        _lastind=_indg;

        run;

         
  
 *create macro variables to use as arrays in next data step;
  
 %LET reversals=0; 
 %LET CountGroups=0; 
   
 DATA _null_;
 	 set grouped end=last;
 	 where &char > .Z;
 	 N + 1;
 	 if last THEN call symput("CountGroups",n);
RUN;	 
 	  
 %IF &CountGroups>1 %THEN %DO;	  

 proc sql noprint;
  	select _weight
  	into
  	    : weightlist separated by " "
  	from grouped	
  	where &char > .Z;
  quit;
   * create reversals ;
 DATA _null_;
 	  array weight_array {&CountGroups} _temporary_ (&weightlist);
 	  array pattern (&countgroups) ;
 	  reversals=0;
 	  
 	  do i =2 to &Countgroups ;
      pattern(i)=0;
 	  	IF weight_array(i) < weight_array(i-1) THEN Pattern(i)=-1;
 	  	  ELSE IF weight_array(i) > weight_array(i-1) THEN Pattern(i)=1;
 	  	  ELSE IF weight_array(i) = weight_array(i-1) THEN Pattern(i)=0;
 	  	IF (pattern(i)=1 and pattern(i -1)=-1) or (pattern(i)=-1 and pattern(i -1)=1)  THEN reversals=reversals+1;
 	  end;	
 	  
  call symput("reversals", reversals);
 RUN; 
 %END;
 

 
    
 
     PROC PRINT DATA=grouped SPLIT='*' noobs;
      VAR  &char _nogood _rawgood _nobad _rawbad _pgood _pbad _weight _cumgd _cumbd _ivalue _ODDS;
      LABEL  &CHAR="HIGH END" _nogood="&TITLE2" _rawgood="RAW* &TITLE2" 
		_nobad="&TITLE1" _rawbad="RAW* &TITLE1"
      _pgood="PROB.* &TITLE2" _pbad="PROB.* &TITLE1" _weight="WEIGHT* PATTERN"
      _cumgd="CUM.* &TITLE2" _cumbd="CUM.* &TITLE1" _ivalue="INFORMATION* VALUE" Event_Rate="&title2 Rate" _odds="ODDS";
      SUM _ivalue _nogood _nobad _pgood _pbad _rawgood _rawbad;
      FORMAT _nogood _nobad 9.0;
      FORMAT _pgood _pbad _weight _ivalue _cumgd _cumbd 5.3;
      FORMAT _odds 8.1;
	   title5 " ";
		title6 "KS Value : &_ks   Gamma Value: &_gamma  Information Value:  &_ival Count_Reversals:&reversals ";
		
      RUN;
%MEND FINESPLT;



**********************************************************************************;
**********************************************************************************;  
*** 12. GRABTITN(dataset,var,numb)       					 			                ***;
**********************************************************************************; 
**********************************************************************************;

%macro GRABTITN(dataset,var,numb);
data grab;
  length lname $50;
  set &dataset (obs=1);
  call label(&var,lname);
  call symput("longname","&var.: "||left(put(lname,$50.)));
run;
title&numb "&longname";
%mend GRABTITN;







	**********************************************************************************;
**********************************************************************************;  
***  FINESPLT_f(dataset,var,title1,rngbdl,rngbdh,title2,rnggdl,rnggdh,		 ***;
***            mltply,char,format, pieces,report,print_lst)      			                ***;
* "BENEFIT OF USING THIS INSTEAD OF FINESPLT: WILL GIVE KS, IV, GAMMA along with variable coarse";
**********************************************************************************; 
**********************************************************************************;

**-------------  
| Descrp. Course display macro for numeric variables   
|                     
| Parameter: dataset    - Input Dataset                          
| Parameter: var        - Performance variable                           
| Parameter: title1     - title for "bad" performance
| Parameter: rngbdl     - Lower limit for "bad" performance          
| Parameter: rngbdh     - Higher limit for "bad" performance 
| Parameter: title2     - title for "good" performance                        
| Parameter: rnggdl     - Lower limit for "good" performance                          
| Parameter: rnggdh     - Higher limit for "good" performance
| Parameter: mltply     - Score    
| Parameter: char       - ??
| Parameter: format     - ??
| Parameter: pieces     - ??
| Parameter: report     - optional dataset to append stats
| Parameter: print_lst  - N to not print. OTherwise, prints .
**------------- ;

%MACRO FINESPLT_f(DATASET,VAR,TITLE1,RNGBDL,RNGBDH,TITLE2,RNGGDL,RNGGDH,
            MLTPLY,CHAR,FORMAT,PIECES,report,print_lst);
      title3 &CHAR;
      %grabtitl (&dataset,&char,4);
      
%IF %length(&print_lst)=0 %THEN %DO;
DATA _null_;
call symput ("print_lst","Y")  ;
RUN;  
%END;

%grabtitl (&dataset,&char,4);

      %finespc(&DATASET,&VAR,&TITLE1,&RNGBDL,&RNGBDH,&TITLE2,&RNGGDL,&RNGGDH,
            &MLTPLY,&CHAR,&FORMAT);
      %global _ival _ks reversals;
      data grouped;
        set final end=_endfl ;
        retain _lastind _lastgd _lastbd _lastngd _lastnbd _cntmiss 0 _cumiv 0 _rawgood _rawbad 0;
        if (&CHAR le .z) then _cntmiss+1;
        _indg=_cntmiss+int( (_cumgd+_cumbd)/(2/&pieces) );
        _totngd+_nogood;
        _totnbd+_nobad;

		  _rawgood+rawgood;
		  _rawbad+rawbad;

        if (_indg>_lastind) or (_endfl=1) then do;
          if ( (_indg=_lastind) and (_endfl=1)) then _indg=_indg+1;
          _pgood=(_cumgd-_lastgd+0.00001)/(1+((&pieces/2)*0.00001));
          _pbad= (_cumbd-_lastbd+0.00001)/(1+((&pieces/2)*0.00001));
          if ((_pgood+_pbad)>0.04) or (_endfl=1) or (&char le .z) then do;
            _lastgd=_cumgd;
            _lastbd=_cumbd;
            _nogood=_totngd-_lastngd;
            _nobad=_totnbd-_lastnbd;
            _lastngd=_totngd;
            _lastnbd=_totnbd;
            _weight=LOG(_pgood/_pbad);
             _ODDS = _nogood/_NOBAD;
            _ivalue = (_pgood-_pbad)* _weight;
            _cumiv+_ivalue;
            if _endfl eq 1 then do;
              call symput('_ival',compress(put(_cumiv,12.3)));
            end;
            KEEP &char _indg _nogood _pgood _nobad _pbad _weight _ivalue _cumgd _cumbd _rawgood _rawbad _odds;
            output;
				_rawgood=0;	 
				_rawbad=0;
          end;
        end;
        _lastind=_indg;

        run;

     
 *create macro variables to use as arrays in next data step;
  
 %LET reversals=0; 
 %LET CountGroups=0; 
   
 DATA _null_;
 	 set grouped end=last;
 	 where &char > .Z;
 	 N + 1;
 	 if last THEN call symput("CountGroups",n);
RUN;	 
 	  
 %IF &CountGroups>1 %THEN %DO;	  

 proc sql noprint;
  	select _weight
  	into
  	    : weightlist separated by " "
  	from grouped	
  	where &char > .Z;
  quit;
   * create reversals ;
 DATA _null_;
 	  array weight_array {&CountGroups} _temporary_ (&weightlist);
 	  array pattern (&countgroups) ;
 	  reversals=0;
 	  
 	  do i =2 to &Countgroups ;
      pattern(i)=0;
 	  	IF weight_array(i) < weight_array(i-1) THEN Pattern(i)=-1;
 	  	  ELSE IF weight_array(i) > weight_array(i-1) THEN Pattern(i)=1;
 	  	  ELSE IF weight_array(i) = weight_array(i-1) THEN Pattern(i)=0;
 	  	IF (pattern(i)=1 and pattern(i -1)=-1) or (pattern(i)=-1 and pattern(i -1)=1)  THEN reversals=reversals+1;
 	  end;	
 	  
  call symput("reversals", reversals);
 RUN; 
 %END;
 

  

     %if &print_lst~=N  %THEN %DO;   
 
     PROC PRINT DATA=grouped SPLIT='*' noobs;
      VAR  &char _nogood _rawgood _nobad _rawbad _pgood _pbad _weight _cumgd _cumbd _ivalue _ODDS;
      LABEL  &CHAR="HIGH END" _nogood="&TITLE2" _rawgood="RAW* &TITLE2" 
		_nobad="&TITLE1" _rawbad="RAW* &TITLE1"
      _pgood="PROB.* &TITLE2" _pbad="PROB.* &TITLE1" _weight="WEIGHT* PATTERN"
      _cumgd="CUM.* &TITLE2" _cumbd="CUM.* &TITLE1" _ivalue="INFORMATION* VALUE" Event_Rate="&title2 Rate" _Odds="Odds";
      SUM _ivalue _nogood _nobad _pgood _pbad _rawgood _rawbad;
      FORMAT _nogood _nobad 9.0;
      FORMAT _pgood _pbad _weight _ivalue _cumgd _cumbd 5.3;
      FORMAT _odds  8.1;
	   title5 " ";
		title6 "KS Value : &_ks   Gamma Value: &_gamma  Information Value:  &_ival Count_Reversals:&reversals ";
		
      RUN;
    %END;
		
		PROC UNIVARIATE DATA=&dataset (KEEP= &char ) NOPRINT;
     VAR &char  ;
     OUTPUT OUT=NT N=N  NMISS=NMISS STD=STD MEAN=MEAN MAX=MAX MIN=MIN
     PCTLPTS = 1 5 10 15 25 50 75 90 95 99
     PCTLPRE = P;

DATA NT ; SET NT ;
LENGTH NAME $30 ;
NAME="&char" ;
 N=sum(N,NMISS);
 IF N > 0 THEN PMISS=(NMISS/N);
KS=&_ks;
IVAL=&_ival;
REVERSALS = &Reversals;
longname="&longname";

 %if %length(&report)>0 %then %do;

   PROC APPEND BASE=&report DATA=NT FORCE;

 %end;

 run;

%MEND FINESPLT_f;


**********************************************************************************;
**********************************************************************************;  
***  FINEFCT_f(dataset,var,title1,rngbdl,rngbdh,title2,rnggdl,rnggdh,			 ***;
***            mltply,char,format,report,print_lst)           			                   ***;
**********************************************************************************; 
**********************************************************************************;
**-------------  
| Descrp. Course display macro for character variables   
|                     
| Parameter: dataset    - Input Dataset                          
| Parameter: var        - Performance variable                           
| Parameter: title1     - title for "bad" performance
| Parameter: rngbdl     - Lower limit for "bad" performance          
| Parameter: rngbdh     - Higher limit for "bad" performance 
| Parameter: title2     - title for "good" performance                        
| Parameter: rnggdl     - Lower limit for "good" performance                          
| Parameter: rnggdh     - Higher limit for "good" performance
| Parameter: mltply     - Weight   
| Parameter: char       - ??
| Parameter: format     - ??
| Parameter: print_lst  - N to not print. OTherwise, prints .
**------------- ;


%MACRO FINEFCT_f(DATASET,VAR,TITLE1,RNGBDL,RNGBDH,TITLE2,RNGGDL,RNGGDH,
      MLTPLY,CHAR,FORMAT,report,print_lst);
      title3 &CHAR;
      %grabtitl (&dataset,&char,4);
      
    %IF %length(&print_lst)=0 %THEN %DO;
DATA _null_;
call symput ("print_lst","Y")  ;
RUN;  
%END;

      %finespc(&DATASET,&VAR,&TITLE1,&RNGBDL,&RNGBDH,&TITLE2,&RNGGDL,&RNGGDH,
            &MLTPLY,&CHAR,&FORMAT);
      %global _ival;
      data grouped (rename=(rawgood=_rawgood rawbad=_rawbad));
        set final end=_endfl ;
          _ODDS = _nogood/_NOBAD;
        if _pgood le 0 then _pgood=0.00001;
        if _pbad le 0 then _pbad=0.00001;
        _weight=log(_pgood/_pbad);
        _ivalue = (_pgood-_pbad)* _weight;
        _cumiv+_ivalue;
        if _endfl eq 1 then do;
          call symput('_ival',compress(put(_cumiv,12.3)));
        end;
     run;
     proc sort data=grouped; by &char;
 %if &print_lst~=N %THEN %DO;
     proc print data=grouped split='*';
     var &char _nogood _rawgood _nobad  _rawbad _pgood _pbad _weight _cumgd _cumbd _ivalue _ODDS;
     label  &char="&char"  _nogood="&title2" _rawgood = "RAW* &title2" _nobad="&title1"
     _rawbad = "RAW* &title1" _pgood="PROB.* &title2" _pbad="PROB.* &title1" _weight="WEIGHT* PATTERN"
     _cumgd="CUM.* &title2" _cumbd="CUM.* &title1" _ivalue="INFORMATION* VALUE" _odds="ODDS"
	    ;
     sum _ivalue _nogood _rawgood _nobad _rawbad _pgood _pbad  ;
     format _nogood _nobad _rawgood _rawbad 9.0 ;
     format _pgood _pbad _weight _ivalue _cumgd _cumbd 5.3;
     format _odds 8.1;
	  title5 " ";
		title6 "KS Value : &_ks   Gamma Value: &_gamma  Information Value:  &_ival";
     RUN;
    %END;	
	 

	  Proc freq data=&dataset (keep=&char) noprint  ;
     tables &char/chisq  norow nocol;
     output out=NT  N NMISS;
     run;  

   DATA NT ; 
	 set NT;
    length longname $50 name $30;
    NAME="&char" ;                                                                                        
     MEAN=.; MAX=.; MIN=.;                                                      
    P1=.; P5=.; P10=.; P15=.; P25=.; P50=.; P75=.; P90=.; P95=.; P99=.;STD=.; PMISS=.;    KS=0; IVAL=0;       
	 KS=&_ks;
    IVAL=&_ival;
	 N=sum(N,NMISS);
	 IF N > 0 THEN PMISS=(NMISS/N);
    longname="&longname";

	 
	 %if %length(&report)>0 %then %do;
      PROC APPEND BASE=&report DATA=NT FORCE;

	 %end;
	 run;




%MEND FINEFCT_f;


**********************************************************************************;
**********************************************************************************;  
***  DESC_F(report)	 ***;
**********************************************************************************; 
**********************************************************************************;


%macro desc_f(report,title);

 PROC SORT DATA=&report;
  BY DESCENDING KS;
  RUN;

   PROC PRINT data=&report UNIFORM NOOBS;
   VAR NAME KS IVAL REVERSALS  NMISS MEAN MIN P25
                               P50 P75 P95 P99 MAX;
   WHERE NAME NE '        ';
   FORMAT NAME   $32. 


		  PMISS             percent6.1
		  MEAN                6.2
		  STD                 6.2
        P1 P5  P25          6.0
        P50 P75             6.0
        P90 P95 P99         6.0;
		  
   TITLE1 "&title";
   run;
   
  
%mend desc_f;


%macro desc_pre_impute(inset=,title=);

 PROC SORT DATA=&inset OUT=_pre_impute;
  BY DESCENDING KS;
  RUN;

   PROC PRINT data=_pre_impute UNIFORM NOOBS;
   VAR varname KS IVAL   pct_miss  MIN P1 P5 P30
                               P50 P80 P90 P95 P99 MAX;
   WHERE varname  NE '        ';
   FORMAT varname   $32. 


		   pct_miss 8.1          
		    MIN mAX              6.1
        P1 P5  P30         6.1
        P50 P80            6.1
        P90 P95 P99         6.1;
		  
   TITLE1 "&title";
   run;
   
  
%mend desc_pre_impute;
