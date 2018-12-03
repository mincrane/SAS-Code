***************************************************************;
* newAR: Create new acceptance rate at attribuate level for   *;
*        selected characteristics by keeping the overall      *;
*        acceptance rate using the new score                  *;
* input: inDS - input dataset                                 *;
*        inVar - variable to analyse                          *;
*        grpfmt - format of variable                          *;
*        inWeight - sample weight variable                    *;
*        inScore - new score                                  *;
*        outfile - output file                                *;
*        first - Y indicate the first variable to analyse,    *;
*                summary output will only be generated once   *;
* note: AR_flag is required on the input dataset with 0/1     *;
* example: %newAR(tmpscores,zdel43x,V369N.,&weight_swap,      *;
*           tmpscore,newAR_compare_1.txt,Y);                  *;
* Initial release:                                            *;
* Last Upate: jie 03/04/2005                                  *; 
*             add option 'first' that the summary stats only  *;
*             output once                                     *;
***************************************************************;
                
/* new Accept-Reject Freq - assumes AR_Flag=1 is original accept */

%MACRO newAR(inDS,inVar,grpfmt,inWeight,inScore,outfile,first);

%IF &first=Y %THEN %DO;

/* calculate original acceptance rate */
proc freq data=&inDS;
   tables &perf / missing outcum  out=origperc;
   weight &inWeight;
   where &perf in (&good. &bad. &reject. &ANB.);
Title "Weighted Original Performance Distribution ";
run;

%END;
%ELSE %DO;
proc freq data=&inDS noprint;
   tables &perf / missing outcum  out=origperc;
   where &perf in (&good. &bad. &reject. &ANB.);
   weight &inWeight;
run;
%END;

/* percent sum for subset of accepted */

%let orig_ar=;
data _null_;
 set origperc end=last;
 retain orig_acc_rate 0;
 if &perf in (&good. &bad. &ANB.) then orig_acc_rate = sum(orig_acc_rate,percent);
 if last then do;   * original acceptance rate *;
  put orig_acc_rate;
  call symput('orig_ar',compress(orig_acc_rate));
 end;
run;
%put &orig_ar;

/* score distribution */

proc freq data=&inDS noprint;
   tables &inScore/ missing outcum out=newScore;
   weight &inWeight;
   where &perf in (&good. &bad. &reject. &ANB.);
   Title "Weighted Score Distribution ";
run;

/* lookup score that matches original acceptance rate */
%let newscoreAR=;
data _null_;
 set newScore;
 retain found 0;
 if not found and ( cum_pct >= (100 - &orig_ar) ) then  do;
  call symput('newscoreAR',compress(&inScore ));
  found=1;
  stop;
 end;
run;
%put new score cutoff &newscoreAR for original acceptance rate &orig_ar;

proc format;
   value ar
   0='Reject'
   1='Accept'
;

data &inDS;
   set &inDS;
   if &inScore<&newScoreAR then newar_flag=0;
   else newar_flag=1;
run;

%IF &first=Y %THEN %DO;
proc freq data=&inDS ;
   tables ar_flag*newar_flag/ missing nocol norow ;
   format ar_flag newar_flag ar.;
   label ar_flag="Historical";
   label newar_flag="New";
   weight &inWeight;
   where &perf in (&good. &bad. &reject. &ANB.);
   Title "Swap Set";
run;
%END;

%ELSE %DO;
proc freq data=&inDS noprint;
   tables ar_flag*newar_flag/ missing nocol norow ;
   format ar_flag newar_flag ar.;
   label ar_flag="Historical";
   label newar_flag="New";
   where &perf in (&good. &bad. &reject. &ANB.);
   weight &inWeight;
run;
%END;


%if &newScoreAR ne  %then %do;

proc format;
  value newAR
    low -< &newScoreAR  = 'NR'
    &newScoreAR  - high = 'NA'
    ;
run;

proc freq data=&inDS noprint;
   weight &inWeight;
   table &inVar. * ar_flag /missing  out=origAR outpct ;
   table &inVar. *  &inScore /missing  out=newAR outpct ;
   format &inScore  newAR.  &inVar &grpfmt. ;
   where &perf in (&good. &bad. &reject. &ANB.);
run;

data compare;
   set  origAR(in=a) newAR(in=b);
   by &inVar ;
   length flag $2 ;
   retain totalcnt pct_AR_1 num_AR_1 pct_NA cnt_NA 0 ;
   if a then do;
 	 totalcnt=sum(totalcnt,count);
	 flag=ar_flag;
	 if flag = 1 then do;
            pct_AR_1 = pct_ROW ;
	    num_AR_1= count;
	 end;
  end;
  else if b then do;
   flag=put(&inScore, newAR.); 
	 if flag = 'NA' then do;
    	    pct_NA = pct_ROW ;
	    cnt_NA = count ;
	 end;
  end;

  if last.&inVar then do;
        output;
	totalcnt= 0; pct_AR_1=0; num_AR_1=0; pct_NA=0; cnt_NA =0 ;
  end;
  keep &inVar totalcnt num_AR_1 pct_AR_1 cnt_NA pct_NA ;
  label num_AR_1= "Number Historical Accept" pct_AR_1= "Historical Accept %"
         cnt_NA ="Number New Accept" pct_NA= "New Accept %"  totalcnt="Weighted Total Count"
			;
  run;

  %IF &first=Y %THEN %DO;
     filename csvfile "&outfile";
  %end;
  %else %do;
 	 filename csvfile "&outfile" mod;
  %end;
ODS CSV file=csvfile ;
proc print data=compare label  noobs;
   title "Swapset Analysis - &inVar ";
   sum totalcnt num_AR_1 cnt_NA  ;
run;
ODS CSV CLOSE;


%end;


%MEND newAR;


