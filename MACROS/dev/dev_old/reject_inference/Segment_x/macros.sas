%******************************************************************************;
%* CHARACTER TO NUMERIC CONVERSION WITH SPECIAL MISSING VALUES RETAINED	       ;
%* NOTE - If a special missing value appears in the output, _endfl and make    ;
%*        sure it is not a credit bureau key, like K for 1,000.  If so, the    ;
%*        variable needs to be converted differently.  In general, always      ;
%*        understand why a special missing value appears.                      ;
%* Parameter: varin     - Character Variable Input                             ;
%* Parameter: result    - Numeric Variable Output                              ;
%* Parameter: format    - Length and/or Format of Character Var EX: 8., 5.2    ;
%* Parameter: drop      - Y or (N or blank) - to drop varin                    ;
%* Parameter: label     - Label for result variable, (optional)                ;
%* Value: 0+, .A - .Z, ., ._                                                   ;
%******************************************************************************;
%macro convert(varin,result,format,drop,label);

&result = ._; 					/* initialize result */

/******** Search for Blank Values *********************************************/
if &varin = ' ' then &result = .;

/******** Search for Alpha Entries  *******************************************/
else if indexc(&varin,'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz')
        gt 0 then
  do;
        if indexc(&varin,'Xx') gt 0 then &result = .x;
   else if indexc(&varin,'Nn') gt 0 then &result = .n;
   else if indexc(&varin,'Ff') gt 0 then &result = .f;
   else if indexc(&varin,'Mm') gt 0 then &result = .m;
   else if indexc(&varin,'Bb') gt 0 then &result = .b;
   else if indexc(&varin,'Aa') gt 0 then &result = .a;
   else if indexc(&varin,'Cc') gt 0 then &result = .c;
   else if indexc(&varin,'Dd') gt 0 then &result = .d;
   else if indexc(&varin,'Ee') gt 0 then &result = .e;
   else if indexc(&varin,'Gg') gt 0 then &result = .g;
   else if indexc(&varin,'Hh') gt 0 then &result = .h;
   else if indexc(&varin,'Ii') gt 0 then &result = .i;
   else if indexc(&varin,'Jj') gt 0 then &result = .j;
   else if indexc(&varin,'Kk') gt 0 then &result = .k;
   else if indexc(&varin,'Ll') gt 0 then &result = .l;
   else if indexc(&varin,'Oo') gt 0 then &result = .o;
   else if indexc(&varin,'Pp') gt 0 then &result = .p;
   else if indexc(&varin,'Qq') gt 0 then &result = .q;
   else if indexc(&varin,'Rr') gt 0 then &result = .r;
   else if indexc(&varin,'Ss') gt 0 then &result = .s;
   else if indexc(&varin,'Tt') gt 0 then &result = .t;
   else if indexc(&varin,'Uu') gt 0 then &result = .u;
   else if indexc(&varin,'Vv') gt 0 then &result = .v;
   else if indexc(&varin,'Ww') gt 0 then &result = .w;
   else if indexc(&varin,'Yy') gt 0 then &result = .y;
   else if indexc(&varin,'Zz') gt 0 then &result = .z;
 end;

/******** Search for Invalid Entries ******************************************/
/******** AL_low comma, negative, and dollar sign ******************************/

else if indexc(&varin,"!@#%^&*()_+={}[]:;'<>?/~`|\") gt 0 then &result = ._;

/******** Search for Absence of Valid Numeric Entries  ************************/
/******** If not Blank, Alpha, or Numeric At This Point, Then Must Be  ********/
/******** Special Character - Make Equal to ._ (as initialized) ***************/

else if indexc(&varin,'0123456789') eq 0 then &result = ._;

/******** Search for Valid Numeric Entries  ***********************************/
/******** Compress out $ and comma, Convert to Numeric ************************/
/******** Length/Format Defaults to 8. ****************************************/

else if indexc(&varin,'01234567890') gt 0 then
 do;
   if indexc(&varin,',$') gt 0 then	     /* look for comma or dollar sign */
       &varin=compress(&varin,',$'); 
   
   %if %length(&format) gt 0 %then
     %do;
       &result = input(&varin,&format);
     %end;
   %else 
     %do;
       &result = input(&varin,8.);
     %end;
 end;

/******** If None of Above Conditions Met ************************************/
/******** Resolves to ._ *****************************************************/

/************** Option to Drop Input Var *************************************/
%if &drop = Y %then 
 %do;
    drop &varin;
 %end;

/************** Option to Add a Label ****************************************/
%if %length(&label) gt 0 %then
 %do;
   label &result = "&label";
%end;  

%mend convert;
%******************************************************************************;

%macro GRABTITL(dataset,var,numb);
%global longname;
data grab;
  length lname $80;
  set &dataset (obs=1);
  call label(&var,lname);
  call symput("longname",compbl(lname));
run;
title&numb %qsysfunc(putc(&longname,$80.));
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
      %global _ival;
      data grouped;
        set final end=_endfl ;
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

     proc print data=grouped split='*';
     var &char _nogood rawgood _nobad  rawbad _pgood _pbad _weight _cumgd _cumbd _ivalue;
     label  &char="&char"  _nogood="&title2" rawgood = "RAW* &title2" _nobad="&title1"
     rawbad = "RAW* &title1" _pgood="PROB.* &title2" _pbad="PROB.* &title1" _weight="WEIGHT* PATTERN"
     _cumgd="CUM.* &title2" _cumbd="CUM.* &title1" _ivalue="INFORMATION* VALUE" 
	    ;
     sum _ivalue _nogood rawgood _nobad rawbad _pgood _pbad  ;
     format _nogood _nobad rawgood rawbad 9.0 ;
     format _pgood _pbad _weight _ivalue _cumgd _cumbd 5.3;
	   title5 " ";
		title6 "KS Value : &_ks";
		title7 "Gamma Value: &_gamma";
		title8 "Information Value:  &_ival";
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
      %global _ival _ks;
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
            KEEP &char _indg _nogood _pgood _nobad _pbad _weight _ivalue _cumgd _cumbd _rawgood _rawbad;
            output;
				_rawgood=0;	 
				_rawbad=0;
          end;
        end;
        _lastind=_indg;

        run;

      PROC PRINT DATA=grouped SPLIT='*';
      VAR _indg &char _nogood _rawgood _nobad _rawbad _pgood _pbad _weight _cumgd _cumbd _ivalue;
      LABEL  _indg="ID OF* GROUP" &CHAR="HIGH END* &CHAR" _nogood="&TITLE2" _rawgood="RAW* &TITLE2" 
		_nobad="&TITLE1" _rawbad="RAW* &TITLE1"
      _pgood="PROB.* &TITLE2" _pbad="PROB.* &TITLE1" _weight="WEIGHT* PATTERN"
      _cumgd="CUM.* &TITLE2" _cumbd="CUM.* &TITLE1" _ivalue="INFORMATION* VALUE"
		  ;
      SUM _ivalue _nogood _rawgood _nobad _rawbad _pgood _pbad  ;
      FORMAT _nogood _nobad  _rawgood _rawbad 9.0;
      FORMAT _pgood _pbad _weight _ivalue _cumgd _cumbd 5.3;
	   title5 " ";
		title6 "KS Value : &_ks";
		title7 "Gamma Value: &_gamma";
		title8 "Information Value:  &_ival";
      RUN;
%MEND FINESPLT;



%macro chrtonum(indat,var,id,numbrk,file,mod=1);

proc sort data=&indat(keep = &var) out=sorted;
by &var;


data _null_;
  set sorted end=_endfl;
  by &var;
  file "&file" 
  %if &mod = 1 %then %do;
       mod;
  %end;
    ;
  if last.&var then do;
    _cnt+1;
    if _cnt=1 then do;
      put ;
      put "****************&var DUMMY GENERATION**************;";
      put;
    end;
    if (not _endfl) or (_endfl and (_cnt gt 2)) then do;
     /* put "label  &id." _cnt " =  '"   "&var" ' = ' '"' &var '"' "' ; " ; */
      put "label  &id." _cnt ' = "' "&var" " =  '" &var "' "  ' ";' ;
      put "if &var = '" &var "' then &id." _cnt " = 1 ; " ;
      put "else  &id." _cnt " = 0 ; " ;
    end;
    if _cnt gt &numbrk then stop;
  end;
  if _endfl then put "drop &var ;";
run;

%mend chrtonum;

%macro genflgm(varin,id);
  if &varin le .z then do;
    &varin = 0;
    &id.0 = 1;
  end;
  else do;
    &id.0 = 0;
  end;
  label &id.0="flag for missing &varin";
%mend genflgm;

%macro gensq(varin,limlo,limhi,id,imputeval);
  %if %length(&limlo) gt 0 %then %do;
     if &varin lt &limlo then &varin=&limlo;
  %end;
  %if %length(&limhi) gt 0 %then %do;
     if &varin gt &limhi then &varin=&limhi;
  %end;
  &id.2=&varin * &varin;
  label &id.2="square of &varin";
%mend gensq;

%macro gensqm(varin,limlo,limhi,id,imputeval);
  if &varin le .z then &id.0=1;
  else &id.0=0;
  if &varin le .z then &varin=&imputeval;
  else do;
    %if %length(&limlo) gt 0 %then %do;
       if &varin lt &limlo then &varin=&limlo;
    %end;
    %if %length(&limhi) gt 0 %then %do;
       if &varin gt &limhi then &varin=&limhi;
    %end;
  end;
  &id.2=&varin * &varin;
  label &id.0="flag for missing &varin";
  label &id.2="square of &varin";
%mend gensqm;


%macro grabcode(root,limm1,filein,fileout,filler);

data _null_;
  file &fileout mod;
  infile &filein ls=1000 recfm=v length=long missover;
  input @1 _line_ $varying200. long;
  **_line_=upcase(_line_);
  hit=0;
  %do i=1 %to &limm1;
     if index(_line_,trim("&&&root.&i")) then hit=1;
  %end;
  if hit then do;
    put &filler _line_;
  end;
run;
%mend grabcode;

%macro grabfile(filein,fileout,filler,first);

%if %length(&first) eq 0 %then %do;
  %let first = 1 ;
%end;
data _null_;
  file &fileout mod;
  infile &filein ls=1000 recfm=v length=long missover;
  input @1 _line_ $varying200. long;
  if (_n_ lt &first) then delete;
  put &filler _line_;
run;
%mend grabfile;

%macro dec_prob(name,namegd,weight,indat,var,denom,pieces,fileout);

title2 "Scoring out the dataset: &name";
title3 "Estimates based on &var divided by &denom.. Requested &pieces cells.";

%global nobs noegd;

proc means data = &indat noprint ;
  %if %length(&weight) gt 0 %then %do;
  weight &weight;
  %end;
  output out=tmpcnt ;
run;

data _null_;
  set tmpcnt;
  %if %length(&weight) gt 0 %then %do;
    if _STAT_ eq 'SUMWGT' then do;
      call symput('nobs',compress(put(&var,12.)));
    end;
  %end;
  %else %do;
    if _STAT_ eq 'N' then do;
      call symput('nobs',compress(put(&var,12.)));
    end;
  %end;
run;

%put &nobs;



proc sort data=&indat(keep = &var &weight) out=sorted;
 by &var;
run;
%if %length(&weight) eq 0 %then %do;
  %let weight = 1;
%end;

data one;
  set sorted end=_endfl;
  by &var;
  retain _outfl _cellno _low _cnt _cellgd _cumprb;
  if _n_=1 then do;
    _low=&var;
    _cnt = 0;
    _cellgd = 0;
    _cellno = 1;
    _cumprb = 0;
    _outfl = 0;
  end;
  _cumgd + &weight * (&var/&denom)	;
  _cnt + &weight;
  _cellgd + &weight * (&var/&denom);
  _cellprb = _cnt / &nobs;
  _cumprb + (&weight / &nobs);
  _high=&var;
  _t1_=int(_cumprb/(1/&pieces));
  if (_t1_ ge _cellno or _endfl) then _outfl = 1;
  if last.&var and _outfl then do;
    output;
    _low=&var;
    _cnt = 0;
    _cellgd = 0;
    _outfl = 0;
    _cellno = _t1_+1;
  end;
  if _endfl then do;
    call symput('noegd',compress(put(_cumgd,22.4)));
  end;
  keep _low _high _cnt _cellgd _cellprb;
run;

data grouped;
  set one end=_endfl;
  retain _cntp _goodp 0;
  _cellgpr=100*_cellgd/_cnt;
  _cumcnt+_cntp;
  _cumgd+_goodp;
  _passcnt = &nobs - _cumcnt;
  _passgd = &noegd - _cumgd;
  _passgdp= 100*_passgd/&noegd;
  _passpct= 100*_passcnt/&nobs;
  _passgdr= 100*_passgd/_passcnt;
  _improve= _passgdr-100*(&noegd/&nobs);
  _imppct= _improve/(&noegd/&nobs);
  _cellprb=100*_cellprb;
  label
    _low = 'Low End of range'
    _high = 'High End of range'
    _cnt = 'Cell Frequency'
    _cellgd="Cell &namegd"
    _cellprb='Cell % of Total'
    _cellgpr ="Cell % &namegd"
    _passcnt ='Passing Frequency'
    _passgd = "Passing # of &namegd"
    _passgdp= "Passing % of &namegd"
    _passpct= 'Passing % of Total'
    _passgdr= "&namegd % of Passing"
    _improve= 'Improvement over Base'
    _imppct= '% Improvement over Base';
  ;
  output;
  _cntp=_cnt;
  _goodp=_cellgd;
  drop _cntp _goodp;
run;
  
proc print data=grouped label split='*';
var _low 
    _high 
    _cnt  
    _passcnt  
    _cellprb  
    _passpct  
    _cellgd
    _cellgpr
    _passgd
    _passgdp
    _passgdr
    _improve
    _imppct  
;
format _low         6.
       _high       6.
       _cnt      10.
       _passcnt    10.
       _cellprb   8.1
       _passpct    8.1
       _cellgd   8.1
       _cellgpr    8.1
       _passgd     8.1
       _passgdp    8.1
       _passgdr    8.1
       _improve   8.1
       _imppct    8.1
  ;

%if %length(fileout) gt 0 %then %do;
  data _null_;
    set grouped;
    file &fileout lrecl=500;
    if _n_ eq 1 then do;
      put 
      '"Low End of range",'
      '"High End of range",'
      '"Cell Frequency",'
      '"Passing Frequency",'
      '"Cell % of Total",'
      '"Passing % of Total",'
      "" "Cell &namegd" "" ','
      "" "Cell % &namegd" "" ','
       "" "Passing # of &namegd" "" ','
      "" "Passing % of &namegd" "" ','
      "" "&namegd % of Passing" "" ','
      '"Improvement over Base"' ','
      '" % Improvement over Base"'
      ;
    end;
    put    _low         6. ','
           _high       6. ','
           _cnt      10. ','
           _passcnt    10. ','
           _cellprb   8.1 ','
           _passpct    8.1 ','
           _cellgd   8.1 ','
           _cellgpr    8.1 ','
           _passgd     8.1 ','
           _passgdp    8.1 ','
           _passgdr    8.1 ','
           _improve   8.1 ','
           _imppct    8.1
      ;
    run;
%end;

%mend dec_prob;

%macro regfct(dataset,weight,depend,indep,indepf);



/***************************************************************************/
/*	grab variable's label from dataset and put it in title  	   */
/***************************************************************************/

      title3 &indep;
      %grabtitl (&dataset,&indep,4);

/***************************************************************************/
/*           generate variables needed for computing statistics            */
/***************************************************************************/
        
data zero; set &dataset (keep= &indep &depend &weight);

%if %length(&indepf) gt 0 %then %do;
  data zero;
    length &indep $40;
    set zero (rename = (&indep= _ttt) );
    &indep = put(_ttt,&indepf.);
  run;
%end;
                                        
proc sort data=zero;
  by &indep;
run;

%global _rsqudsc _ftstdsc _fdg1dsc _fdg2dsc _fprbdsc;

data one;
  retain _count _sum _sumsq 0;
  set zero end=_endfl;
  by &indep;
  if first.&indep then do;
    _count=0;
    _sum=0;
    _sumsq=0;
  end;
  %if %length(&weight) gt 0 %then %do;
     _count+&weight;
     _sum+ (&weight * &depend);
     _sumsq+ (&weight * &depend * &depend);
  %end;
  %else %do;
     _count+1;
     _sum+ &depend;
     _sumsq+ &depend * &depend;
  %end;
  if last.&indep then do;
    _ave=_sum/_count;
    _total+_sum;
    _totsq+_sumsq;
    _tcount+_count;
    _r+1;
    _ut=_sumsq-(_count * _ave *_ave);
    _cut+_ut;
    output;
  end;
  if _endfl then do;
    _df1=_r-1;
    _df2=round(_tcount)-_r;
     if _df1 gt 0 then _nd1=_df2 / _df1;
    else _nd1 = 0;
    _yt=_total/_tcount;
    call symput('_fdg1dsc',compress(put(_df1,16.0)));
    call symput('_fdg2dsc',compress(put(_df2,16.0)));
    call symput('_nd1',compress(put(_nd1,best32.)));
    call symput('_ytc',compress(put(_yt,best32.)));
    call symput('_yt',compress(put(_yt,16.3)));
    call symput('_tna',compress(put(_tcount,best32.)));
    call symput('_cut',compress(put(_cut,best32.)));
  end;
  keep &indep _sum _count _ave _sumsq _ut;
  %if %length(&indepf) gt 0 %then %do;
    keep _ttt;
  %end;
run;

data grouped;
  set one end=_endfl;   
  _wt=_sumsq +  (_count * &_ytc *  &_ytc) - (2 *_count *_ave * &_ytc);
  _cwt+_wt;
  _f=(_wt-_ut)* &_nd1/&_cut;
  _t=sqrt(_f*&_fdg1dsc);
  _probt=2*(1-probt(_t,_count));
  _cf+_f;
  _percnt = 100.0 * _count/&_tna;
  if _endfl then do;
    %if (%eval(&_fdg1dsc) gt 0) and  (%eval(&_fdg2dsc) gt 0) %then %do;
      _probf=1-probf(_cf,&_fdg1dsc,&_fdg2dsc);
    %end;
    %else %do;
      _probf=1.0;
   %end;
    call symput('_ftstdsc',compress(put(_cf,16.2)));
    call symput('_fprbdsc',compress(put(_probf,16.4)));
    _rsqudsc = 1 - ( &_cut / _cwt ) ;
    call symput('_rsqudsc',compress(put(_rsqudsc,6.4)));
  end;
run;


data _null_;
  ftnt1='SUMMARY STATISTICS';
  ftnt2a='CELL AVERAGE R-SQUARED = ';
  ftnt2b="&_rsqudsc";
  ftnt2c=upcase('AVERAGE &depend = ');
  ftnt2d="&_yt";
  ftnt2e=';         ';
  ftnt3a='F-TEST( ';
  ftnt3b="&_ftstdsc";
  ftnt3c=' , ';
  ftnt3d="&_fdg1dsc";
  ftnt3e=' , ';
  ftnt3f="&_fdg2dsc";
  ftnt3g=' );';
  ftnt3h=' PROB > F = ';
  ftnt3i="&_fprbdsc";
  ftnt2= ftnt2a||ftnt2b||ftnt2e||ftnt2c||ftnt2d;
  ftnt3= ftnt3a||compress(ftnt3b||ftnt3c||ftnt3d||ftnt3e||ftnt3f||ftnt3g)||ftnt3h||ftnt3i;
  call symput("foot2",put(ftnt2,$71.));
  call symput("foot3",put(ftnt3,$50.));
  call symput("pages",put((&_fdg1dsc + 22),best.));
run;
footnote;
footnote1 'SUMMARY STATISTICS';
footnote2 ' ';
footnote3 "&&foot2";
footnote4 "&&foot3";

/*****************************************************************************/
/*                            print out table                                */
/*****************************************************************************/ 

options linesize=155 pagesize=&&pages;


%if %length(&indepf) gt 0 %then %do;
  proc sort data=grouped;
    by _ttt;
  run;
%end;
proc print data=grouped split='*' label;
     var &indep _sum _count _percnt _ave _t _probt;
     sum _sum _count _percnt ;
     format _sum 16.2 _count 12.0 _percnt 5.1 _ave 10.3 _t 6.2 _probt 5.3; 
     label
     &indep="formatted *&indep"
     _sum="total *&depend"
     _count="# of * accounts"
     _percnt="% of * accounts"
     _ave="average *&depend"
     _t="|T|-value"
     _probt="prob > * |T|"
;
 run;
footnote;
footnote1;
footnote2;
footnote3;
footnote4;
run;
options pagesize=55;


%mend regfct;



/***************************************************************************/
/*                            macro REGSPLT                                */
/*           Create format for ind and call macro REGFCT                   */
/***************************************************************************/

%macro regsplt(datain,weight,dep,ind,prefmt,pieces);

data zero; 
  set &datain (keep= &ind &dep &weight) end=_endfl;
  %if %length(&weight) gt 0 %then %do;
    _cnt+&weight;
  %end;
  %else %do;
    _cnt+1;
  %end;
  %if %length(&prefmt) gt 0 %then %do;
    &ind=input(put(&ind,&prefmt.),&prefmt.);
  %end;
  if _endfl then do;
    call symput('totfreq',compress(put(_cnt,best32.)));
  end;
  drop _cnt;
run;

proc sort data=zero;
  by &ind;
run;

data one;
  set zero;
  by &ind;
  if first.&ind then do;
    _cnt=0;
  end;
  %if %length(&weight) gt 0 %then %do;
    count+&weight;
  %end;
  %else %do;
    _cnt+1;
  %end;
  if last.&ind then do;
    _percent=100*_cnt/&totfreq;
    output;
  end;
  keep _percent &ind;
run;  

proc contents data=one noprint out=cntout;
data ttt; 
  set cntout;
  namecap=upcase("&ind");
  if name=namecap then do;
    call symput('vtype',put(type,1.));
  end;
run;

%if &vtype=1 %then %do;
  %let fmtval = best20.;
%end;
%else %do;
  %let fmtval = $20.;
%end;
 
%if %length(&prefmt) gt 0 %then %do;
  %let fmtval = &prefmt;
%end;

%let i=1;
%let brkmis=0;
%let breaks=0;
data two;
 set one end=_check;
   retain _curpct 0 _k 0;
 %if &vtype=1 %then %do;
   _oldpct=_curpct;
   _curpct+_percent;
   if &ind le .z then do;
     _k+1;
     _val='end'||trim(left(put(_k,3.)));
     if ( (&ind eq ._) or (&ind ge .a) ) then do;
       call symput(_val,compress('.'||put(&ind,&fmtval)));
     end;
     else do;
       call symput(_val,compress(put(&ind,&fmtval)));
     end;
     output;
     call symput('brkmis',put(_k,best3.));
     _oldpct=0;
     _curpct=0;
   end;
   else if (_curpct ge 100/&pieces and _oldpct lt 100/&pieces) or _check 
   then do;
     _k+1;
     _val='end'||trim(left(put(_k,3.)));
     call symput(_val,compress(put(&ind,&fmtval)));
     output;
     _oldpct=0;
     _curpct=0;
     if _check then call symput('breaks',put(_k,best3.));
   end;
 %end;
 %if &vtype=2 %then %do;
   _oldpct=_curpct;
   _curpct+_percent;
   if (_curpct ge 100/&pieces and _oldpct lt 100/&pieces) or _check 
   then do;
     _k+1;
     _val='end'||trim(left(put(_k,3.)));
     call symput(_val,compress(put(&ind,&fmtval)));
     output;
     _oldpct=0;
     _curpct=0;
     if _check then call symput('breaks',put(_k,best3.));
   end;
 %end;
run;   





%let i=%eval(&i-1);

proc format ;
%if &vtype=1 %then %do;
  value numout
%end;
%else %do;
  value $chrout
%end;

%let jstart=%eval(&brkmis+1);
%do j=1 %to &brkmis;
  &&end&j = "&&end&j "
%end;
%do j=&jstart %to &breaks;
   %let jmin=%eval(&j-1);
   %if &j=&jstart %then %do;
     LOW - &&end&j = "LOW - &&end&j "
   %end;
   %else %if &j=&breaks %then %do;
     &&end&jmin <- HIGH = "&&end&jmin <- HIGH "
   %end;
   %else %do;
     &&end&jmin <- &&end&j = "&&end&jmin <- &&end&j "
   %end;
 %end;
 ;

%if &vtype=1 %then %do;
   %regfct(zero,&weight,&dep,&ind,numout.);
%end;
%else %do;
   %regfct(zero,&weight,&dep,&ind,$chrout.);
%end;


%mend regsplt;

%macro cnt_prob(name,namegd,weight,indat,var,denom,pieces,fileout);

options linesize = 155;
title2 "Scoring out the dataset: &name";
title3 "Estimates based on &var divided by &denom.. Requested &pieces cells.";

%global nobs noegd;

proc means data = &indat noprint ;
  %if %length(&weight) gt 0 %then %do;
  weight &weight;
  %end;
  output out=tmpcnt ;
run;

data _null_;
  set tmpcnt;
  %if %length(&weight) gt 0 %then %do;
    if _STAT_ eq 'SUMWGT' then do;
      call symput('nobs',compress(put(&var,12.)));
    end;
  %end;
  %else %do;
    if _STAT_ eq 'N' then do;
      call symput('nobs',compress(put(&var,12.)));
    end;
  %end;
run;

%put &nobs;



proc sort data=&indat(keep = &var &weight) out=sorted;
 by &var;
run;
%if %length(&weight) eq 0 %then %do;
  %let weight = 1;
%end;

data one;
  set sorted end=_endfl;
  by &var;
  retain _outfl _cellno _low _cnt _cellgd _cumprb;
  if _n_=1 then do;
    _low=&var;
    _cnt = 0;
    _cellgd = 0;
    _outfl = 0;
    _cellno = 1;
    _cumprb = 0;
  end;
  _cumgd + &weight * (&var/&denom)	;
  _cumprb + (&weight / &nobs);
  _cnt + &weight;
  _cellgd + &weight * (&var/&denom);
  _cellprb = _cnt / &nobs;
  _high=&var;
  _t1_=int(_cumprb/(1/&pieces));
  if (_t1_ ge _cellno or _endfl) then _outfl=1;
  if last.&var and _outfl then do;
    output;
    _low=&var;
    _cnt = 0;
    _cellgd = 0;
    _outfl = 0;
    _cellno = _t1_+1;
  end;
  if _endfl then do;
    call symput('noegd',compress(put(_cumgd,22.4)));
  end;
  keep _low _high _cnt _cellgd _cellprb;
run;

data grouped;
  set one end=_endfl;
  retain _cntp _goodp 0;
  _cellgpr=_cellgd/_cnt;
  _cumcnt+_cntp;
  _cumgd+_goodp;
  _passcnt = &nobs - _cumcnt;
  _passgd = &noegd - _cumgd;
  _passgdp= 100*_passgd/&noegd;
  _passpct= 100*_passcnt/&nobs;
  _passgdr= _passgd/_passcnt;
  _improve= 100*((_passgdr*&nobs/&noegd) -1);
  _cellprb=100*_cellprb;
  label
    _low = 'Low End of range'
    _high = 'High End of range'
    _cnt = 'Cell Frequency'
    _cellgd="Cell &namegd"
    _cellprb='Cell % of Total'
    _cellgpr ="Cell average &namegd"
    _passcnt ='Passing Frequency'
    _passgd = "Total passing &namegd"
    _passgdp= "Passing % of total &namegd"
    _passpct= 'Passing % of Total'
    _passgdr= "Average &namegd of Passing"
    _improve= 'Improvement over Base'
   ;
  output;
  _cntp=_cnt;
  _goodp=_cellgd;
  drop _cntp _goodp;
run;
  
proc print data=grouped label split='*';
var _low 
    _high 
    _cnt  
    _passcnt  
    _cellprb  
    _passpct  
    _cellgd
    _cellgpr
    _passgd
    _passgdp
    _passgdr
    _improve
  ;
format _low         12.4
       _high       12.4
       _cnt      8.
       _passcnt    8.
       _cellprb   5.1
       _passpct    5.1
       _cellgd   10.3
       _cellgpr    10.3
       _passgd     10.3
       _passgdp    5.1
       _passgdr    10.3
       _improve   5.1
  ;

%if %length(fileout) gt 0 %then %do;
  data _null_;
    set grouped;
    file &fileout lrecl=500;
    if _n_ eq 1 then do;
      put 
      '"Low End of range",'
      '"High End of range",'
      '"Cell Frequency",'
     '"Passing Frequency",'
      '"Cell % of Total",'
       '"Passing % of Total",'
       "" "Cell &namegd" "" ','
      "" "Cell average &namegd" "" ','
       "" "Total passing &namegd" "" ','
      "" "Passing % of total &namegd" "" ','
      "" "Average &namegd of Passing" "" ','
      '"Improvement over Base"'
      ;
    end;
    put    _low         12.4 ','
           _high       12.4 ','
           _cnt      10. ','
           _passcnt    10. ','
           _cellprb   12.4 ','
           _passpct    8.1 ','
           _cellgd   12.4 ','
           _cellgpr    12.4 ','
           _passgd     12.4 ','
           _passgdp    8.1 ','
           _passgdr    12.4 ','
           _improve   8.1 
      ;
    run;
%end;

%mend cnt_prob;

/********************************************************/
/** Macros decile new used in score_distribution       **/
/********************************************************/

%macro decile_cutoff(indat,weight,var,perf,cntlout,pieces,fileout,frmtout,zerof);
%global gb_total bad good good_pass bad_pass zerof2;
%let zerof2 = &zerof ;


title2 "Scoring out the dataset: &indat";
title3 "Requested &pieces cells.";

data zero;
  set &indat (keep = &var &perf &weight);
run;

proc means data = zero noprint ;
  %if %length(&weight) gt 0 %then %do;
  weight &weight;
  %end;
  output out=tmpcnt ;
run;

data _null_;
  set tmpcnt;
  %if %length(&weight) gt 0 %then %do;
    if _STAT_ eq 'SUMWGT' then do;
      call symput('nobs',compress(put(&var,18.5)));
    end;
  %end;
  %else %do;
    if _STAT_ eq 'N' then do;
      call symput('nobs',compress(put(&var,12.)));
    end;
  %end;
run;

%put &nobs;

proc sort data=&cntlout out=frmtdt;
by label;

data _null_;
  set frmtdt end=_endfl;
  by label;
  if first.label then do;
    _n+1;
    val=compress('VAL'||put(_n,7.));
    call symput(val,trim(left(label)));
  end;
  if  _endfl then do;
    call symput('NUMGRP',put(_n,7.));
    call symput('PERFMT',compress(FMTNAME));
  end;
run;

proc sort data=zero out=sorted;
 by &var;
run;
%if %length(&weight) eq 0 %then %do;
  %let weight = 1;
%end;

%do i=1 %to &numgrp;
  %let flagp&i = 0 ;
  %let tot&i = 0;
%end;

data one;
  length _temp $40;
  set sorted end=_endfl;
  by &var;
  retain _cellno _outfl _low _cnt _cellgd _cumprb
  %do i=1 %to &numgrp;
    _celln&i 
    _totln&i
  %end;
  ;
  if _n_=1 then do;
    _low=&var;
    _cnt = 0;
    _outfl = 0;
    _cellno = 1;
    _cumprb = 0;
  %do i=1 %to &numgrp;
    _celln&i = 0;
    _totln&i = 0;
  %end;
  end;
  _cnt + &weight;
  _cumprb + (&weight / &nobs);
  _cellprb = _cnt / &nobs;
  _cellprc = 100* _cellprb;
  _high=&var;
  _t1_=int(_cumprb/(1/&pieces));
  %do i=1 %to &numgrp;
    _temp = put(&perf,&perfmt..);
    if  (_temp = "&&val&i") then do;
      _celln&i + &weight;
      _totln&i + &weight;
    end;
  %end;
  if (_t1_ ge _cellno or _endfl) then _outfl = 1;
  if last.&var and _outfl then do;
    output;
    _low=&var;
    _cnt = 0;
    _outfl = 0;
    _cellno = _t1_+1;
    %do i=1 %to &numgrp;
      _celln&i = 0;
    %end;
  end;
  if _endfl then do;
    %do i=1 %to &numgrp;
       if (_totln&i gt 0) then do;
         call symput("flagp&i",'1');
         call symput("tot&i",compress(put(_totln&i,18.5)));
       end;
    %end;
  end;
  keep _low _high _cnt _cellprc
    %do i=1 %to &numgrp;
    _celln&i 
    %end;
  ;
   %do i=1 %to &numgrp;
    label _celln&i  = "&&val&i";
    %end;
   label
     _low = 'Low End'
     _high = 'High End'
     _cnt = 'Cell Count'
     _cellprc = 'Cell Percent'
   ;
 
run;

data two;
  set one;
  retain _cumcnt _cumprob 
  %do i=1 %to &numgrp;
    _cumn&i
  %end;
  0 ;
  _passcnt = &nobs - _cumcnt;
  _cumcnt + _cnt;
  _passprb = 100 - _cumprob;
  _cumprob + _cellprc;
  %do i=1 %to &numgrp;
    _passn&i = "&&tot&i" - _cumn&i;
    _cumn&i + _celln&i;
  %end;
  label 
  _passcnt = '# Total Passing'
  _passprb= '% Total Passing'
  %do i=1 %to &numgrp;
    _passn&i = "# &&val&i Passing"
  %end;
  ;
  drop
  %do i=1 %to &numgrp;
    _cumn&i
  %end;
  _cumcnt _cumprob;
  ;

run;

proc sql noprint ;
 create table names as
  select name , label
   from dictionary.columns
    where libname = "WORK" and memname = "TWO" 
          and label in ("&namebd" , "&namegd" , "# &namebd Passing" , "# &namegd Passing");
quit ;

data _null_ ;
 set names ;
if label = "&namebd"            then call symput('BAD'       , name) ;
if label = "&namegd"           then call symput('GOOD'      , name) ;
if label = "# &namebd Passing"  then call symput('BAD_PASS'  , name) ;
if label = "# &namegd Passing" then call symput('GOOD_PASS' , name) ;
run ;

data two_b ;
set two end = eof;
retain good_denom bad_denom;

bad_rate     = round ( (( &BAD       / ( &GOOD + &BAD           ) ) * 100 ) , .1 ) ;
bad_rate_all = round ( (( &BAD_PASS  / ( &GOOD_PASS + &BAD_PASS ) ) * 100 ) , .1 ) ;
actual_odds  = round( ( &GOOD        / &BAD                       ) , .1 ) ;

if ( _n_ = 1 ) then do ;
  good_denom = &GOOD_PASS ;
  bad_denom  = &BAD_PASS  ;
end ;

pct_good = ROUND( ( (&GOOD_PASS / good_denom ) * 100 ) , .1 ) ;
pct_bad  = rOUND( ( (&BAD_PASS  / bad_denom  ) * 100 ) , .1 ) ;

&GOOD      = ROUND( &GOOD      , .1 ) ;
&BAD       = ROUND( &BAD       , .1 ) ;
&GOOD_PASS = ROUND( &GOOD_PASS , .1 ) ;
&BAD_PASS  = ROUND( &BAD_PASS  , .1 ) ;

_CNT     = ROUND( _CNT     , .1 ) ;
_PASSCNT = ROUND( _PASSCNT , .1 ) ;


tot_good + &GOOD ;
tot_bad  + &BAD  ;

if eof then do ;
  gb_total = tot_good + tot_bad ;
  call symput('gb_total',gb_total) ;
end ;
run ;


data _null_ ;
file "&fileout" dlm = ',' ;
set two_b ;

if _n_ = 1 then do ;
put "Score , Interval Good Count , Interval Bad Count , Interval % Total ,  Total at or above Cut-Off , % Total at or above Cut-Off ,";
put "Good at or above Cut-Off , % Good at or above Cut-Off , Bad at or above Cut-Off , % Bad at or Above Cut-Off ,";
put "Bad Rate at or above Cut-Off , Interval Bad Rate , Interval Odds"; 
end ;
    
put _low &GOOD &BAD _cellprc  _passcnt _passprb &GOOD_PASS pct_good &BAD_PASS pct_bad 
    bad_rate_all bad_rate actual_odds ;
    
run ;


data special ;
set two_b (keep =  _low _high &GOOD &BAD _passcnt _passprb _cellprc pct_good &GOOD_PASS pct_bad &BAD_PASS
                   bad_rate_all bad_rate actual_odds ) ;
run ;

proc print data=two_b label;
var _low &GOOD &BAD _passcnt _cellprc _passprb &GOOD_PASS pct_good  &BAD_PASS pct_bad 
    bad_rate_all bad_rate actual_odds ;
 

format _cellprc _passprb 5.1;
label 
  _low         = 'Score'
  bad_rate     = 'Marginal Bad Rate'
  bad_rate_all = 'Bad Rate at or above Cut-Off'
  actual_odds  = 'Interval Odds' 
  _passcnt     = 'Total at or above Cut-Off'
  _cellprc	   = 'Interval % Total'
  _passprb     = '% Total at or above Cut-Off'
  &BAD_PASS    = 'Bad at or above Cut-Off'
  &GOOD_PASS   = 'Good at or above Cut-Off' 
  pct_good     = '% Good at or above Cut-Off'
  pct_bad      = '% Bad at or above Cut-Off';
run ;



%mend decile_cutoff;

%MACRO create_gini(varscr,labeling,scorelabel);

DATA _null_;
 set grouped nobs=nobserv;
 file "report/gini_&labeling.&scorelabel..csv" dlm=",";
 if _n_=1 THEN do;
   nobserv1=nobserv + 1;
   put nobserv1;
   put " &varscr , num_&namegd , num_&namebd, prob_&namegd ,  prob_&namebd, weight,  cum_&namegd ,  cum_&namebd, IV";
   put ", , ,,, , 0, 0,";
  end; 
 put  &varscr _nogood _nobad _pgood _pbad _weight _cumgd _cumbd _ivalue;
RUN;
   
   
data _null_;
    file 'ResponseTech.out' mod;
    put "       &labeling.- &Scorelabel. Set Statistics (&varscr) :";
    put "          Kolmogorov-Smirnov: &_ks.";
    put "          Concordant Pair %: &_concord.";
    put "          Discordant Pair %: &_discord.";
    put "          Tied Pair %: &_tie.";
    put "          Goodman-Kruskal Gamma: &_gamma.";
    put "          Information Value: &_ival.";
    file 'report/model_statistics.txt' mod;
  put "&scorelabel, &varscr ,&_ks.,&_ival.";
  run;   

%MEND create_gini;
**********************************************************************************;
**********************************************************************************;  
*** 34. FINESPLT_odds(dataset,var,title1,rngbdl,rngbdh,title2,rnggdl,rnggdh,	 ***;
***            mltply,char,format, pieces)      			                      ***;
**********************************************************************************; 
**********************************************************************************;

**-------------  
| Descrp. Course display macro for numeric variables
|         Difference between the regular one is that this displays the odds, it is
|         used in the LOREAN process for the score distribution reports  
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

%MACRO FINESPLT_odds(DATASET,VAR,TITLE1,RNGBDL,RNGBDH,TITLE2,RNGGDL,RNGGDH,
            MLTPLY,CHAR,FORMAT,PIECES);
      title3 &CHAR;
      %grabtitl (&dataset,&char,4);

      %finespc(&DATASET,&VAR,&TITLE1,&RNGBDL,&RNGBDH,&TITLE2,&RNGGDL,&RNGGDH,
            &MLTPLY,&CHAR,&FORMAT);
      %global _ival;
      data grouped;
        set final end=_endfl ;
        retain _lastind _lastgd _lastbd _lastngd _lastnbd _cntmiss 0 _cumiv 0;
        if (&CHAR le .z) then _cntmiss+1;
        _indg=_cntmiss+int( (_cumgd+_cumbd)/(2/&pieces) );
        _totngd+_nogood;
        _totnbd+_nobad;
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
				odds=_nogood/_nobad;
				log_odds=log(_nogood/_nobad);
            if _endfl eq 1 then do;
              call symput('_ival',compress(put(_cumiv,12.3)));
            end;
            KEEP &char _indg _nogood _pgood _nobad _pbad _weight _ivalue _cumgd _cumbd odds log_odds;
            output;
          end;
        end;
        _lastind=_indg;

        run;
      PROC PRINT DATA=grouped SPLIT='*';
      VAR _indg &char _nogood _nobad _pgood _pbad _weight _cumgd _cumbd _ivalue odds log_odds;
      LABEL  _indg="ID OF*GROUP" &CHAR="HIGH END*&CHAR" _nogood="&TITLE2" _nobad="&TITLE1"
      _pgood="PROB.*&TITLE2" _pbad="PROB.*&TITLE1" _weight="WEIGHT*PATTERN"
      _cumgd="CUM.*&TITLE2" _cumbd="CUM.*&TITLE1" _ivalue="INFORMATION*VALUE" odds="ODDS" log_odds="LN(ODDS)";
      SUM _ivalue _nogood _nobad _pgood _pbad;
      FORMAT _nogood _nobad 9.0;
      FORMAT _pgood _pbad _weight _ivalue _cumgd _cumbd 5.3;
	   title5 " ";
		title6 "KS Value : &_ks";
		title7 "Gamma Value: &_gamma";
		title8 "Information Value:  &_ival";
      RUN;
%MEND FINESPLT_odds;

******************************************************************************************;
******************************************************************************************;  
*** 11. Decile(indat,weight,var,perf,cntlout,pieces,fileout,frmtout,zerof)**;											 ***;
******************************************************************************************; 
******************************************************************************************;

**-------------  
| Descrp. Creates gains tables by quantile.  Also outputs code for creating a 
|         rank variable.
| indat :  The absolute address of the input dataset. It should 
|          contain the dependent and independent variables      
| weight:  The name of the variable containing observation      
|          weights                                              
| var:     The name of the variable that will define cells      
| perf:    The name of the variable defining performance        
| cntlout: The Proc format cntlout= dataset with the format     
|          for the different performance groups                 
| pieces:  The number of equal size pieces desired              
| fileout: The name of the file containing comma separated      
|          results                                              
| fmtout:  The name of the file containing the SAS format       
| zerof:   If turned on, it starts the initial range at 0      
|          makes sense if we are dealing with  probability                                   
|-----------
| Example                                                       
|                                                               
| proc format cntlout = fmtset                                  
| value rescode                                                 
| 0 = 'Not Attempted'                                           
| 1 = 'Non Contacts'                                            
| 2 - 7 = 'Non Contacts'                                        
| 90 = 'Sales'                                                  
| Other = 'Declines'                                            
|                                                               
| SPECIAL NOTE:  The name of the value (in the example above: rescode) cannot end
|                with a number.                                                                        
|                                                               
**-------------;

%macro decile(indat,weight,var,perf,cntlout,pieces,fileout,frmtout,zerof);

title2 "Scoring out the dataset: &indat";
title3 "Requested &pieces cells.";

data zero;
  set &indat (keep = &var &perf &weight);
run;

proc means data = zero noprint ;
  %if %length(&weight) gt 0 %then %do;
  weight &weight;
  %end;
  output out=tmpcnt ;
run;

data _null_;
  set tmpcnt;
  %if %length(&weight) gt 0 %then %do;
    if _STAT_ eq 'SUMWGT' then do;
      call symput('nobs',compress(put(&var,18.5)));
    end;
  %end;
  %else %do;
    if _STAT_ eq 'N' then do;
      call symput('nobs',compress(put(&var,12.)));
    end;
  %end;
run;

%put &nobs;

proc sort data=&cntlout out=frmtdt;
by label;

data _null_;
  set frmtdt end=_endfl;
  by label;
  if first.label then do;
    _n+1;
    val=compress('VAL'||put(_n,7.));
    call symput(val,trim(left(label)));
  end;
  if  _endfl then do;
    call symput('NUMGRP',put(_n,7.));
    call symput('PERFMT',compress(FMTNAME));
  end;
run;

proc sort data=zero out=sorted;
 by &var;
run;
%if %length(&weight) eq 0 %then %do;
  %let weight = 1;
%end;

%do i=1 %to &numgrp;
  %let flagp&i = 0 ;
  %let tot&i = 0;
%end;

data one;
  length _temp $40;
  set sorted end=_endfl;
  by &var;
  retain _cellno _outfl _low _cnt _cellgd _cumprb
  %do i=1 %to &numgrp;
    _celln&i 
    _totln&i
  %end;
  ;
  if _n_=1 then do;
    _low=&var;
    _cnt = 0;
    _outfl = 0;
    _cellno = 1;
    _cumprb = 0;
  %do i=1 %to &numgrp;
    _celln&i = 0;
    _totln&i = 0;
  %end;
  end;
  _cnt + &weight;
  _cumprb + (&weight / &nobs);
  _cellprb = _cnt / &nobs;
  _cellprc = 100* _cellprb;
  _high=&var;
  _t1_=int(_cumprb/(1/&pieces));
  %do i=1 %to &numgrp;
    _temp = put(&perf,&perfmt..);
    if  (_temp = "&&val&i") then do;
      _celln&i + &weight;
      _totln&i + &weight;
    end;
  %end;
  if (_t1_ ge _cellno or _endfl) then _outfl = 1;
  if last.&var and _outfl then do;
    output;
    _low=&var;
    _cnt = 0;
    _outfl = 0;
    _cellno = _t1_+1;
    %do i=1 %to &numgrp;
      _celln&i = 0;
    %end;
  end;
  if _endfl then do;
    %do i=1 %to &numgrp;
       if (_totln&i gt 0) then do;
         call symput("flagp&i",'1');
         call symput("tot&i",compress(put(_totln&i,18.5)));
       end;
    %end;
  end;
  keep _low _high _cnt _cellprc
    %do i=1 %to &numgrp;
    _celln&i 
    %end;
  ;
   %do i=1 %to &numgrp;
    label _celln&i  = "&&val&i";
    %end;
   label
     _low = 'Low End'
     _high = 'High End'
     _cnt = 'Cell Count'
     _cellprc = 'Cell Percent'
   ;
 
run;

data two;
  set one;
  retain _cumcnt _cumprob 
  %do i=1 %to &numgrp;
    _cumn&i
  %end;
  0 ;
  _passcnt = &nobs - _cumcnt;
  _cumcnt + _cnt;
  _passprb = 100 - _cumprob;
  _cumprob + _cellprc;
  %do i=1 %to &numgrp;
    _passn&i = "&&tot&i" - _cumn&i;
    _cumn&i + _celln&i;
  %end;
  label 
  _passcnt = '# Total Passing'
  _passprb= '% Total Passing'
  %do i=1 %to &numgrp;
    _passn&i = "# &&val&i Passing"
  %end;
  ;
  drop
  %do i=1 %to &numgrp;
    _cumn&i
  %end;
  _cumcnt _cumprob;
  ;

run;


proc print data=two label;
var _low _high _cnt _passcnt _cellprc _passprb
%do i=1 %to &numgrp;
   %if %eval(&&flagp&i) gt 0 %then %do;
     _celln&i _passn&i
   %end;
%end;
;
format _cellprc _passprb 5.1;

data _null_;
  set two end=_endfl;
  file "&frmtout" lrecl=100;
  if _n_ eq 1 then do;
    put 'proc format; ';
    put 'value display';
    %if %length(&zerof) gt 0 %then %do;
      if _low gt 0 then _low=0;
    %end;
    put _low '- ' _high ' = " ' _low '- ' _high '"';
  end;
  else if _endfl THEN DO;
  put _low '<- HIGH  = " ' _low '<-  HIGH"';
  END;
  else do;
    put _low '<- ' _high ' = " ' _low '<- ' _high '"';
  end;
  if _endfl then do;
    put ';' ;
  end;
  file "&fileout" lrecl=1000;
  if _n_ eq 1 then do;
    put '"Low End","High End","Cell Count","#Total Passing","Cell %","% Total Passing"' @;
    put 
    %do i=1 %to &numgrp;
       %if %eval(&&flagp&i) gt 0 %then %do;
      ',"' "# Cell &&val&i" '","' "# &&val&i Passing" '"'
        %end;
    %end;
    ;
  end;
  put _low ',' _high ',' _cnt ',' _passcnt ',' _cellprc 5.1 ',' _passprb 5.1 
  %do i=1 %to &numgrp;
     %if %eval(&&flagp&i) gt 0 %then %do;
       ',' _celln&i ',' _passn&i
     %end;
  %end;
  ;
run;

%do i=1 %to &numgrp;
  %put "&&flagp&i" ;
%end;


%mend decile;