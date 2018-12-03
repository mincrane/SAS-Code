/**********************************************************************************
* Macro for creating the baseline for charecteristic stability calculations
* Parameters involved:
					DATASET        	  -- complete path of the dataset for which the baseline statistics
										 			   are to be drawn.
					P_VAR             -- performance variable
					FMTFILENAME       --  Name of the file containing the decile ranges including extension(e.g. xyz.txt)	
					path_fmtfilename  -- Path of where the format should be stored.
					VARGEN_OPT        -- Option to generate the format or use a previous one. (YES/NO). Default is Yes.
					OUTPUT_OPT        -- Option to generate pdf output. Default is YES.
					 
***********************************************************************************/
%macro char_analysis(
				   variable=,
				   data_set=, 
				   p_var_=,
				   path_base=,
				   fmtfilename_=flag_logic,
				   vargen_opt_=yes,
				   require=,
				   where=
				  );
				  
			data _dset;
				set &data_set.;
				%IF %length(&where.) > 0 %THEN %DO;
					where &where.;
				%END;
				  
			%let x=%sysfunc(countw(&variable.)); 

			%do i=1 %to &x.;
			
				%let abc = %scan(&variable.,&i.,%str( ));
			
					proc contents data=_dset out=_contents noprint;
					run;
				
					proc sql noprint;
						select type
						into :_vtype
						from _contents
						where upcase(name) = "%upcase(&abc.)";
					quit;

					data dset_&i.;
						set _dset;																												
					run;
 
				%IF %upcase(&require.)=BASE %THEN %DO;
				
					%base_cs (
							  dataset=dset_&i., 
							  p_var=&p_var_.,
							  path_fmtfilename=&path_base.,
							  fmtfilename=&fmtfilename_.,
							  var1=&abc.,
							  vargen_opt=&vargen_opt_.
							 );
				%END;
				
				%ELSE %IF %upcase(&require.)=CURR %THEN %DO;
					%local epsilon;
					%let epsilon= 1e-10;
					
					data base_counts;
						length no $ 50;
						infile "&path_base.&fmtfilename_..txt" dsd;
						input no $ @;
						if no = "&abc." then
							input vtype lo hi w_variable base_cnt base_percent;
					run;

					data _dset1;
						set dset_&i.;
						%IF &_vtype.= 1 %THEN %DO;
							%include "&path_base.&abc._&fmtfilename_..sas";
						%END;
						%ELSE %IF &_vtype.= 2 %THEN %DO;
							w&abc.= &abc.;
						%END;
						cntr=1;
					run;

					proc means data=_dset1 noprint;
							var cntr;
							class w&abc.;
							output out=_means_comp sumwgt=curr_cnt;
					run;
				/*
					data _means_comp;
						set _means_comp;
						retain curr_totcnt;
						if _TYPE_= 0 then curr_totcnt= curr_cnt; 
						if _TYPE_= 1 then curr_percent= curr_cnt/curr_totcnt;
					run;
					*/
					data _means_comp;
						set _means_comp;
						where _TYPE_=1;
					run;

					proc sql;
						create table char_stab_report as
						select a.lo,a.hi, a.w_variable as WOE, a.base_cnt, a.base_percent, b.curr_cnt, b.curr_cnt/sum(b.curr_cnt) as curr_percent, calculated curr_percent - a.base_percent as delta
						from base_counts as a left join
						_means_comp as b
						on a.w_variable=b.w&abc.
						order by a.lo,a.hi;
					quit;
					
					data _null_;
						set char_stab_report(keep=lo hi) end=eof;
						call symput('low'!!left(put(_n_,2.)),lo);
						call symput('high'!!left(put(_n_,2.)),hi);
						if eof then
							call symput('nums',left(put(_n_,2.)));
					run;
			
					data char_stab_report;
						set char_stab_report;
						length tag $ 30;
						if lo = . and hi = . then tag="MISSING";
						else if lo = . and hi ~= . then tag=catx('-->',"LOW",put(hi,comma10.2));
						else if hi = . and lo ~= . then tag=catx('-->',put(lo,comma10.2),"HIGH");
						else tag=catx('-->',put(lo,comma10.2),put(hi,comma10.2));
						label lo="%upcase(&abc.) Low End" hi="%upcase(&abc.) High End" WOE="Weight of Evidence" base_cnt="Baseline # of Accounts" base_percent="Baseline % of Accounts"
							  curr_cnt="Current # of Accounts" curr_percent= "Current % of Accounts" delta="Difference" tag="%upcase(&abc.) Range";
						format lo hi WOE delta comma10.4 base_cnt curr_cnt comma10.0 base_percent curr_percent percent10.2;
					run;
					
					data char_stab_report_&i.;
						set char_stab_report;
						where WOE ~= .;
					run;
					
				%END;
			%END;
	
%mend char_analysis;


/* *********************************************BASE MACRO ***************************************************************************************************************/

%macro base_cs	(
				 dataset=, 
				 p_var=, 
				 path_fmtfilename=,
				 fmtfilename=,
				 var1=,
				 w_var=,
				 vargen_opt=
				);

			%IF %upcase(&vargen_opt.)=YES %THEN %DO;
				%woe_vargen1(dset=&dataset.,perfvar=&p_var., path=&path_fmtfilename., fname= &fmtfilename.,_var=&var1.,wghtvar=&w_var);  		
			%END;
			
			%IF &_vtype= 1 %THEN %DO;
				data &dataset.;
					set &dataset.;
					%IF &_vtype= 1 %THEN %DO;
						%include "&path_fmtfilename.&var1._&fmtfilename..sas";
					%END;
					cntr=1;
				run;
		
				proc means data=&dataset. noprint;
					var cntr;
					class w&var1.;
					output out=_means_&i. sumwgt=base_cnt;
				run;
				
				data _means_&i.;
						set _means_&i.;
						retain base_totcnt;
					if _TYPE_= 0 then base_totcnt= base_cnt; 
					if _TYPE_= 1 then base_percent= base_cnt/base_totcnt;
				run;
				
				proc sort data=_means_&i.;
				by w&var1.;
				run;
				
				data _means_&i.;
					set _means_&i.;
					record+1;
					where _TYPE_=1;
				run;	
			
			
				proc sql noprint;
					
						select count(*)
						into :con
						from _means_&i.
						where w&var1.=0.0000;
						
						%IF &con. ne 0 %THEN %DO;
							select max(&var1.) 
							into:max
							from _grouped;
							
							insert into _grouped
							set _weight=0, lo=&max.;
						%END;
					
				quit;
			
			
				proc sort data=_grouped;
				by _weight;
				run;
				
				data _grouped;
					set _grouped;
					record+1;
				run;
				
				proc sql noprint;
					create table final_&i. as 
					select a.lo label="%upcase(&var1.) Low End", a.&var1. as hi label="%upcase(&var1.) High End", b.w&var1. as woe label="Weight of Evidence",
						   b.base_cnt label="Baseline # of Accounts", b.base_percent label="Baseline % of Accounts"
					from _grouped as a, _means_&i. as b
					where a.record=b.record;
				quit;
				
				proc sort data =final_&i.;
				by lo hi;
				run;
				
				data _null_;
					set final_&i.;
						var="&var1.";
						vtype=&_vtype.;
						file "&path_fmtfilename.&fmtfilename_..txt" dlm=','
						%IF &i. ne 1 %THEN %DO;
							mod
						%END;
						;
					put var vtype lo hi woe base_cnt base_percent;
				run;
				
				data final_&i.;
					set final_&i.;
					length tag $ 30;
					if lo = . and hi = . then tag="MISSING";
					else if lo = . and hi ~= . then tag=catx('-->',"LOW",put(hi,comma10.2));
					else if hi = . and lo ~= . then tag=catx('-->',put(lo,comma10.2),"HIGH");
					else tag=catx('-->',put(lo,comma10.2),put(hi,comma10.2));
					format lo hi comma10.2 woe comma10.4 base_cnt comma10.0 base_percent percent10.2;
					label tag="%upcase(&var1.)* Range";
				run;
			%END;
			
			%IF &_vtype= 2 %THEN %DO;
			
				proc sql noprint;
				select sum(_nogood),sum(_nobad)
				into :nogood, :nobad
				from grouped;
				quit;
				
				%let nototal= %eval(&nogood+&nobad);
				
				data final_&i.;
					set grouped(rename=(_weight=woe));
					base_cnt=_nogood+_nobad;
					base_percent=base_cnt/&nototal.;
					tag=&var1.;
					if tag=" " then tag="MISSING";
					label base_cnt = "Baseline # of Accounts" base_percent="Baseline % of Accounts"
						  tag="%upcase(&var1.)" woe="Weight of Evidence";
					format base_cnt comma10.0 base_percent percent10.2;
				keep tag woe base_cnt base_percent;
			%END;

%mend base_cs;

/* *******************************************************************************************************************************************************
										Format generator
**********************************************************************************************************************************************************/
%macro woe_vargen1(dset=,perfvar=,wghtvar=,path=,fname=flag_logic.txt,_var=);
   
     
     %IF &_vtype.= 1 %THEN %DO; 
        %finesplt_f1(&dset.,&perfvar.,NONEVENT,0,0,EVENT,1,1,&wghtvar.,&_var.,10.2,10,);
        
        title3;
        title2;
        title1;
        
        data _forcont;
        	set grouped;
        	drop _: ; 
        run;
        
        proc contents data=_forcont out=_contents(keep=name) noprint;
        run;
        
        data _grouped;
        	if _n_= 1 then set _contents;
        	set grouped end=last;
        	
        	lo= lag1(&_var.);
        	
        	file "&path.&_var._&fname..sas"
        /*	%IF &ii. > 1 %THEN %DO;
        	  mod
        	%END; */
        	;
      	
    			if _n_=1 THEN put "/* &_var  */ ";
        	if &_var. = . then do;
        		put "if " name " = " &_var. "then w" name " = " _weight ";";
        	end;
        	else if &_var. <= .Z and &_var. ne . then do;
        		put "if " name " = ." &_var. "then w" name " = " _weight ";";
        	end;
        	else if lo <= .Z and &_var. > .Z then do; 
        		put "if " name " > .Z and " name " <= " &_var. "then w" name " = " _weight ";";
        	end;
        	else do;
        		put "if " name " > " lo " and " name " <= " &_var. "then w" name " = " _weight ";";
        	end; 
        	
        	if last then do;
        		if &_var. <= .Z and &_var. ne . then do;
        			put "if " name " > ." &_var. "then w" name " = 0;" //;
        		end;
        		else do;
        		  put "if " name " > " &_var. "then w" name " = 0;" //;
        		end;
        	end;
        	 
        run;
      %END;
	  
	  %ELSE %IF &_vtype.= 2 %THEN %DO;
		%FINEFCT_f1(&dset., &perfvar., NONEVENT, 0, 0, EVENT, 1, 1, &wghtvar., &_var.,,);
	  %END;
	  
%mend woe_vargen1;

/********************************************************************************************************************************************************
																										FINEFCT_f1
**********************************************************************************************************************************************************/

%MACRO FINEFCT_f1(DATASET,VAR,TITLE1,RNGBDL,RNGBDH,TITLE2,RNGGDL,RNGGDH,
      MLTPLY,CHAR,FORMAT,report);
      /* title3 &CHAR; */
      %grabtitl1 (&dataset,&char,4);

      %finespc1(&DATASET,&VAR,&TITLE1,&RNGBDL,&RNGBDH,&TITLE2,&RNGGDL,&RNGGDH,
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

	/*
     proc print data=grouped split='*';
     var &char _nogood _nobad _pgood _pbad _weight _cumgd _cumbd _ivalue;
     label  &char="&char"  _nogood="&title2" _nobad="&title1"
     _pgood="PROB.*&title2" _pbad="PROB.*&title1" _weight="WEIGHT*PATTERN"
     _cumgd="CUM.*&title2" _cumbd="CUM.*&title1" _ivalue="INFORMATION*VALUE";
     sum _ivalue _nogood _nobad _pgood _pbad;
     format _nogood _nobad 9.0;
     format _pgood _pbad _weight _ivalue _cumgd _cumbd 5.3;
	  title5 " ";
		title6 "KS Value : &_ks   Gamma Value: &_gamma  Information Value:  &_ival";
     RUN;
	
	 

	  Proc freq data=&dataset (keep=&char) noprint;
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
*/
%MEND FINEFCT_f1;

/********************************************************************************************************************************************************
																										finesplt_f1
**********************************************************************************************************************************************************/
%MACRO finesplt_f1(DATASET,VAR,TITLE1,RNGBDL,RNGBDH,TITLE2,RNGGDL,RNGGDH,
            MLTPLY,CHAR,FORMAT,PIECES,report,print_lst);
   
      title3 &char;
      %grabtitl1 (&dataset,&char,4);
      
%IF %length(&print_lst)=0 %THEN %DO;
DATA _null_;
call symput ("print_lst","Y")  ;
RUN;  
%END;

%grabtitl1 (&dataset,&char,4);


      %finespc1(&DATASET,&VAR,&TITLE1,&RNGBDL,&RNGBDH,&TITLE2,&RNGGDL,&RNGGDH,
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

/*
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
    
    */
		
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

%MEND finesplt_f1;

/********************************************************************************************************************
								                                 			grabtitl1
********************************************************************************************************************/

%macro grabtitl1(dataset,var,numb);
%global longname;
data grab;
  length lname $50;
  set &dataset (obs=1);
  call label(&var,lname);
  call symput("longname",trim(left(put(lname,$50.))));
run;
title&numb "&longname";
%mend grabtitl1;


/********************************************************************************************************************
								                                 			finespc1
********************************************************************************************************************/
								                                 			
 %MACRO finespc1(DATASET,VAR,TITLE1,RNGBDL,RNGBDH,TITLE2,RNGGDL,RNGGDH,
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

%MEND finespc1; 
