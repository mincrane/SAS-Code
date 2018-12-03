/********************************************************************************************************
   
These macros were created and standardized from the behavior macros used in previous projects.  
All arrays are assumed to go backwards in time from start to end. 
Time-on-books as well as start and end arguments are required and should never be missing. 
The result argument is always required and is the variable in which to return the macro results.  
For most macros the condition argument is optional. The argument decimal is available for non-counting events. 
This argument rounds the result to the decimal place specified and must be positive or zero or -1. 
If set to zero then no rounding occurs and if set to -1 then integer truncation will be done. 
Otherwise set rounding to 1, 0.1, .01, etc. By default all macros set the decimal argument to zero.

The result variable can use the default or user defined label. 
The label argument specified by the user should not contain single or double quotes, apostrophes, 
commas, or and (&) symbols which will be macro triggers. 
Likewise, the condition argument should not contain commas or the macro will fail with an error message 
that too many arguments were passed.  

Note: all position parameters must be called in order followed by any of the optional keyword arguments,
e.g. label=Mylabel.  Default values will apply if keyword arguments are not passed.


 Macros List:

    %macro CountEvent(arrayev,start,end,tob,condition,result,label=DEFAULT)   
    %macro SumEvent(arrayev,start,end,tob,condition,result,decimal,label=DEFAULT)   
    %macro PercentEvent(arrayev,start,end,tob,condition,result,decimal,label=DEFAULT,countmiss=1)   
    %macro AveEvent(arrayev,start,end,tob,condition,result,decimal,lag=0,ignoreCount=0,label=DEFAULT,countmiss=1)         
    %macro maxEvent(arrayev,start,end,tob,condition,result,decimal,returnMon= ,label=DEFAULT)      
    %macro minEvent(arrayev,start,end,tob,condition,result,decimal,returnMon= ,label=DEFAULT)     
    %macro maEvent(arrayev,start,end,tob,result,decimal,label=DEFAULT)        
    %macro maxconsec(arrayev,start,end,tob,condition,result,label=DEFAULT)      
    %macro mosinceEvent(arrayev,start,end,tob,condition,result,label=DEFAULT)   
    %macro dates_snc(EVENT,NOW,RESULT,TYPE,label=DEFAULT,logFuture= )          
    %macro ratio(num,den,result,factor,decimal,label=DEFAULT)                   
    %macro createFlag(result,condition,trueValue=1,falseValue=0,label=DEFAULT)   
    %macro mosworst(arrayev,start,end,tob,result,label=DEFAULT)        

	 Modified:
	   
 
 ********************************************************************************************************/

**********************************************************************************;
**********************************************************************************;
***  %macro CountEvent(arrayev,start,end,tob,condition,result,label=DEFAULT)   ***;
***                                                                            ***;
***  To calculate # of occurrences of events that satisfy certain condition in ***;
***  the last x months.                                                        ***;
***                                                                            ***;
***  arrayev: array to evaluate.                                               ***;
***  start: start month to evaluate.                                           ***;
***  end: last month to evaluate. (Number of Months since start).              ***;
***  tob: Time on Book.                                                        ***;
***  condition: condition to satisify if array values are counted.             ***;
***             Should not be passed as missing argument.                      ***;
***  result: Output Variable.                                                  ***;
***  Label: Output Variable Label. =DEFAULT to use default label else specify. ***;
***         No Single or Double quotes or Apostrophes or (&) in label.         ***;
***                                                                            ***;
*** EXAMPLE: %CountEvent(bal,1,6,TimeOnbk,gt 0,maxbal1_6,0.1);                 ***;
***                                                                            ***;
*** NOTES: stops searching array at minimum of end or tob.                     ***;
***        Set to .M if start gt end and tob.                                  ***;
***        check for empty array -  if true then set to .B                     ***;
***        Macro will fail if condition contains a comma.                      ***;
***        drops temp variables created: icount                                ***;
***                                                                            ***;
***                                                                            ***;
*** MODIFIED:                                                                  ***;
**********************************************************************************;
**********************************************************************************;
%macro CountEvent(arrayev,start,end,tob,condition,result,label=DEFAULT);

   &result = 0;
	_flag_empty =1;
   if &start > min(&end,&tob) then &result = .M;
   else do icount = &start to min(&end,&tob);
	  if not missing(&arrayev{icount}) then _flag_empty=0;      * found non-missing value *;
      if &arrayev{icount} &condition then &result = &result + 1;
   end;
	if &result = 0 and _flag_empty =1 then &result =.B;   * null array *;

	drop icount _flag_empty;

	%if %nrbquote(%upcase(&label)) eq DEFAULT %then %do;
    label &result = "# Times &ARRAYEV &condition. &start.-&end. months";
	%end;
	%else %if %length(&label)>0 %then %do;
	 label &result = "&label "; 
	%end;

%mend CountEvent;


**********************************************************************************;
**********************************************************************************;
***   %macro SumEvent(arrayev,start,end,tob,condition,result,decimal,label=DEFAULT) ***;
***                                                                            ***;
***  To calculate Sum of values of events that satisfy certain condition in    ***;
***  the last x months.                                                        ***;
***                                                                            ***;
***  arrayev: array to evaluate.                                               ***;
***  start: start month to evaluate.                                           ***;
***  end: last month to evaluate. (Number of Months since start).              ***;
***  tob: Time on Book.                                                        ***;
***  condition: condition to satisify if array values are to be summed.        ***;
***            Leave missing to check all non-missing values with no condition.***;
***  result: Output Variable.                                                  ***;
***  decimal: decimal parameter when the result is to be rounded.              ***;
***           0 for no rounding. -1 for int truncation. Else between 0 and 1.  ***;
***  Label: Output Variable Label. =DEFAULT to use default label else specify. ***;
***         No Single or Double quotes or Apostrophes in label.                ***;
***                                                                            ***;
*** EXAMPLE: %SumEvent(bal,1,6,TimeOnbk,gt 0,maxbal1_6,0.1);                   ***;
***                                                                            ***;
*** NOTES: stops searching array at minimum of end or tob.                     ***;
***        Set to .M if start gt end and tob.                                  ***;
***        check for empty array -  if true then set to .B                     ***;
***        Macro will fail if condition contains a comma.                      ***;
***        drops temp variables created: icount                                ***;
***                                                                            ***;
***                                                                            ***;
*** MODIFIED:                                                                  ***;
**********************************************************************************;
**********************************************************************************;

%macro SumEvent(arrayev,start,end,tob,condition,result,decimal,label=DEFAULT);

   &result = .B;
   if &start > min(&end,&tob) then &result = .M;
   else do icount = &start to min(&end,&tob);
      if &arrayev(icount) > .z 
		 %if %length(&condition)>0 %then %do;
		    and &arrayev{icount} &condition 
		%end;
		then &RESULT=sum(&RESULT, &arrayev(icount) );
   end;

   %if %sysevalf(&decimal > 0) %then %do;
     if not missing(&result) then &result = round(&result,&decimal); 
	%end;
   %else %if &decimal = -1 %then %do;
     if not missing(&result) then &result = int(&result); 
	%end;


	drop icount ;

	%if %nrbquote(%upcase(&label)) eq DEFAULT %then %do;
     label &result = "Sum &ARRAYEV &condition. &start.-&end. months";
	%end;
	%else %if %length(&label)>0 %then %do;
	  label &result = "&label "; 
	%end;

%mend SumEvent;


**********************************************************************************;
**********************************************************************************;
*** %macro PercentEvent(arrayev,start,end,tob,condition,result,decimal,label=DEFAULT) ***;
***                                                                            ***;
***  To calculate Percentage of occurrences of events that satisfy certain     ***;
***  condition in the last x months.                                           ***;
***                                                                            ***;
***  arrayev: array to evaluate.                                               ***;
***  start: start month to evaluate.                                           ***;
***  end: last month to evaluate. (Number of Months since start).              ***;
***  tob: Time on Book.                                                        ***;
***  condition: condition to satisify if array values are counted.             ***;
***        Should not be passed as missing argument unless counting            ***;
***        number of non-zero and non-missing values.                          ***;
***  result: Output Variable.                                                  ***;
***  decimal: decimal parameter when the result is to be rounded.              ***;
***           0 for no rounding. -1 for int truncation. Else between 0 and 1.  ***;
***  Label: Output Variable Label. =DEFAULT to use default label else specify. ***;
***         No Single or Double quotes or Commas, or Apostrophes in label.     ***;
***  countMiss: DEFAULT=1 to count all array elements for denom. if set to 0  ***;
***   ignores missing array values in denominator count for percentage.        ***;
***                                                                            ***;
*** EXAMPLE: %PercentEvent(bal,1,6,TimeOnbk,gt 0,maxbal1_6,0.1);               ***;
***                                                                            ***;
*** NOTES: stops searching array at minimum of end or tob.                     ***;
***       Set to .M if start gt end and tob. Special missing if zero division. ***;
***        check for empty array -  if true then set to .B                     ***;
***        Macro will fail if condition contains a comma.                      ***;
***        drops temp variables created: icount _num _den                      ***;
***                                                                            ***;
***                                                                            ***;
*** MODIFIED:                                                                  ***;
**********************************************************************************;
**********************************************************************************;

%macro PercentEvent(arrayev,start,end,tob,condition,result,decimal,label=DEFAULT,countMiss=1);

   _num = 0;
   _den = 0;
	_flag_empty=1; 
  
   if &start > min(&end,&tob) then &result = .M;
   else do icount = &start to min(&end,&tob);
	   if not missing(&arrayev{icount} ) then _flag_empty=0;   * non-missing value *;
      if &countMiss then _den = _den + 1;
		else if not missing(&arrayev{icount} ) then _den = _den + 1;
      if &arrayev{icount} &condition then _num = _num + 1;
   end;
   
	if &result ~= .M and _flag_empty =1 then &RESULT = .B;
   else if ( _num eq  0) and ( _den eq  0)  then &RESULT = .E;
   else if ( _num gt 0) and ( _den eq  0)  then &RESULT = .F;
   else do;
	  
  	  &result = 100*(_num/_den);
    %if %sysevalf(&decimal > 0) %then %do;
	  &result = round(&result,&decimal);
	 %end;
    %else %if &decimal = -1 %then %do;
	  &result = int(&result);
	 %end;

	end;
   drop icount _num _den _flag_empty;

	%if %nrbquote(%upcase(&label)) eq DEFAULT %then %do;
     label &result = "% Times &arrayev. &condition. &start.-&end. months";
	%end;
	%else %if %length(&label) > 0 %then %do;
	  label &result = "&label."; 
	%end;

%mend PercentEvent;


**********************************************************************************;
**********************************************************************************;
***   %macro AveEvent(arrayev,start,end,tob,condition,result,decimal,lag=0	    ***;
***                  ,ignoreCount=0,label=DEFAULT,countMiss=1)                  ***;
***                                                                            ***;
***  To calculate average of events that satisfy certain condition in          ***;
***  the last x months with or without (DEFAULT) lag.                          ***;
***                                                                            ***;
***  arrayev: array to evaluate.                                               ***;
***  start: start month to evaluate.                                           ***;
***  end: last month to evaluate. (Number of Months since start).              ***;
***  tob: Time on Book.                                                        ***;
***  condition: condition to satisify if array values are counted.             ***;
***             Leave missing to check all values with no condition.           ***;
***  result: Output Variable.                                                  ***;
***  decimal: decimal parameter when the result is to be rounded.              ***;
***           0 for no rounding. -1 for int truncation. Else between 0 and 1.  ***;
***  Lag: Default to zero for nolag or use 1 for lag.                          ***;
***  ignoreCount: used only with condition, Default is 0.  if value does not   ***;
***   satisfy condition then not added to num but is include in denom division.***;
***   if ignoreCount=1 then not added to num or included in denom division.    ***;
***  Label: Output Variable Label. =DEFAULT to use default label else specify. ***;
***         No Single or Double quotes, Commas, or Apostrophes in label.       ***;
***  countMiss: DEFAULT=1 to count all array elements for denom. if set to 0  ***;
***   ignores missing array values in denominator count for percentage.        ***;
***                                                                            ***;
*** EXAMPLE: %AveEvent(bal,1,6,TimeOnbk,,maxbal1_6,0.1,lag=0,ignoreCount=0);   ***;
***                                                                            ***;
*** NOTES: stops searching array at minimum of end or tob.                     ***;
***        Flag set if missing result or if cannot go back num of months.      ***;
***        check for empty array -  if true then set to .B                     ***;
***        also if division by zero then set to .B                             ***;
***        If tob not greater than 0 then will return result as missing.       ***;
***        Macro will fail if condition contains a comma.                      ***;
***        drops temp variables created: icount aux _AVER _count               ***;
***                                                                            ***;
***       If  countMiss=1 then will increment the denominator and              ***;
***       divide by number of elements. If countMiss=0 the denominator count   ***;
***       will increment only for non-missing elements.                        ***;
***       Ex. countMiss=1 to get 3 mos average pay even if missing payments    ***;
***           countMiss=0 to get the average paid when payment made over 3 mos ***;
***                                                                            ***;   
***       If you also have a condition and only want to use elements that      ***;
***       satisfy the condition then set ignoreCount=1.                        ***;
***       If the condition is false then the array element is skipped.         ***;
***                                                                            ***;    
***       If the condition is true or ignoreCount=0 then works that same as    ***;
***       the no condition case. The countMiss=1 will still increment          ***;
***       denominator and divide by number of elements while countMiss=0 will  ***;
***       again only increment denominator count for non-missing elements.     ***;
***       For most conditions to be satisifed, countMiss option will not make  ***;
***       a difference unless condition includes logic for missing values.     ***;
***       Ex. ignoreCount=1 to get average for debits over 3 mos skip credits. ***;
***           ignoreCount=0 gets average of the debit but treats credits as 0. ***;
***           if condition was ge .Z then the countMiss option would matter.   ***;
***                                                                            ***;
***                                                                            ***;
***                                                                            ***;
*** MODIFIED:                                                                  ***;					 
**********************************************************************************;
**********************************************************************************;

%macro AveEvent(arrayev,start,end,tob,condition,result,decimal,lag=0,ignoreCount=0,label=DEFAULT,countMiss=1);
  
  _AVER=.;
  &RESULT=.B;
  _count=0;

 
  if &tob >0 and &start > min(&tob,&end) then &Result=.M;
  else if &end > &tob then do;

    if &tob>0 then aux=&tob;		* array end gt TOB *;		    
    else aux=0;

  end;
  else aux=&end;		* array end le TOB *;
			
  if aux > 0 then do;
	 							  /* lag is 0 or 1 */
		do icount=(&start +&lag) to aux;

		 if &arrayev(icount) > .z then _AVER=sum(_AVER,0);  * found non-missing value*;

		 %if %length(&condition)> 0 & &ignoreCount=1 %then %do;
		                          /* only count if condition satisfied */
		   if &arrayev(icount) &condition then do; 
			  _AVER=sum(_AVER, &arrayev(icount));
			   if &countMiss then _count +1;
				else if &arrayev(icount) > .z then _count = _count + 1;
			end;
		 %end;
		 %else %do;
		   %if %length(&condition)> 0 %then %do;
			       /*  count even if condition not satisfied */
		     if &arrayev(icount) &condition then
			%end;
		      _AVER=sum(_AVER, &arrayev(icount));
			    if &countMiss then _count+1;
				 else if &arrayev(icount) > .z then _count = _count + 1;
		 %end;
			
		end;

		        /* if missing or div by zero set missing flag */
		if _count = 0  or missing(_AVER)  then &result=.B; 
		else  &RESULT=_AVER/(_count);

  end; 
 
  
  %if %sysevalf(&decimal > 0) %then %do;
    if not missing(&result) then &result = round(&result,&decimal);
  %end;
  %else %if &decimal = -1 %then %do;
   if not missing(&result) then &result = int(&result);
  %end;

 drop _AVER icount aux _count;

 %if %nrbquote(%upcase(&label)) eq DEFAULT %then %do;
   %if %sysevalf(&lag > 0) %then %do;
    label &RESULT="Average &arrayev &start-&end mos with &lag lag";
   %end;
    %else %do;
     label &RESULT="Average &arrayev &start-&end mos";
    %end;
%end;
%else %if %length(&label) > 0 %then %do;
	 label &result = "&label."; 
%end;


%mend AveEvent;



**********************************************************************************;
**********************************************************************************;
*** %macro maxEvent(arrayev,start,end,tob,condition,result,decimal 				 ***;
***                ,returnMon= ,label=DEFAULT)                                 ***;
***                                                                            ***;
***  To calculate max value of an array in last x months satisfying a condition***;
***                                                                            ***;
***  arrayev: array to evaluate.                                               ***;
***  start: start month to evaluate.                                           ***;
***  end: last month to evaluate.   (Number of Months since start).            ***;
***  tob: Time on Book.                                                        ***;
***  condition: condition to satisify if array values are counted.             ***;
***             Leave missing to check all values with no condition.           ***;
***  result: Output Variable.                                                  ***;
***  decimal: decimal parameter when the result is to be rounded.              ***;
***           0 for no rounding. -1 for int truncation. Else between 0 and 1.  ***;
***  returnMon: Output Variable to return month of max if specified.           ***;
***             Default is not to return month.                                ***;
***  Label: Output Variable Label. =DEFAULT to use default label else specify. ***;
***         No Single or Double quotes, Commas, or Apostrophes in label.       ***;
***                                                                            ***;
*** EXAMPLE: %maxEvent(bal,1,6,TimeOnbk, >99 ,maxbal1_6,0.1,returnMon=lastmo); ***;
***                                                                            ***;
*** NOTES: stops searching array at minimum of end or tob.                     ***;
***        Set to .M if start gt end and tob. Sets missing flag if missing.    ***;
***        check for empty array -  if true then set to .B  else               ***;
***        if condition never meet then returns zero else returns max.         ***;
***        Macro will fail if condition contains a comma.                      ***;
***        drops temp variables created: icount                                ***;
***                                                                            ***;
***                                                                            ***;
*** MODIFIED:                                                                  ***;
**********************************************************************************;
**********************************************************************************;
%macro maxEvent(arrayev,start,end,tob,condition,result,decimal,returnMon=,label=DEFAULT);

 &result = .z ;
 _flag_empty=1;
 %if %length(&returnMon)> 0  %then %do;
	 &returnMon = 0;
 %end;
    
   if &start > min(&end,&tob) then &result = .M;
   else do icount = &start to min(&end,&tob);

	 if &arrayev{icount} > .z then _flag_empty=1;  * non-missing value *;
      
		if &arrayev{icount} > &result
	   %if %length(&condition)> 0  %then %do;
		     and &arrayev{icount} &condition
		%end;
         then do;

			 &result = &arrayev{icount};				
			 %if %length(&returnMon)> 0  %then %do;
	            &returnMon = icount;
          %end;

			end;
   end;
	
	 if missing(&result) and _flag_empty then &result=.B;	  * all missing or empty array *;
	 else if missing(&result) then &result =0;   			  * non-missing but condition never meet *;

   %if %sysevalf(&decimal > 0) %then %do;
	  if not missing(&result) then &result = round(&result,&decimal); 
	%end;
	%else %if &decimal = -1 %then %do;
     if not missing(&result) then &result = int(&result);
	%end;

   drop icount;

	%if %nrbquote(%upcase(&label)) eq DEFAULT %then %do;
     label &result = "Max &arrayev. &start.-&end. months";
	%end;
	%else %do;
	  label &result = "&label "; 
	%end;
	                                         * option to return when max event occurs *;
	%if %length(&returnMon)> 0  %then %do;
	  %if %nrbquote(%upcase(&label)) eq DEFAULT %then %do;
	   label &returnMon ="Month of Max &arrayev. &start.-&end. months";
	  %end;
	  %else %if %length(&label) > 0 %then %do;
	   label &returnMon ="Month of  &label";
	  %end;
	%end;

%mend maxEvent;


**********************************************************************************;
**********************************************************************************;
*** %macro minEvent(arrayev,start,end,tob,condition,result,decimal				 ***;
***                ,returnMon= ,label=DEFAULT)                                 ***;
***                                                                            ***;
***  To calculate min value of an array in last x months satisfying a      	 ***;
***  condition. Leave Blank for no condition. Ignores missing values as min.   ***;
***                                                                            ***;
***  arrayev: array to evaluate.                                               ***;
***  start: start month to evaluate.                                           ***;
***  end: last month to evaluate.   (Number of Months since start).            ***;
***  tob: Time on Book.                                                        ***;
***  condition: condition to satisify if array values are counted.             ***;
***             Leave missing to check all values with no condition.           ***;
***  result: Output Variable.                                                  ***;
***  decimal: decimal parameter when the result is to be rounded.              ***;
***           0 for no rounding. -1 for int truncation. Else between 0 and 1.  ***;
***  returnMon: Output Variable to return month of max if specified.           ***;
***             Default is not to return month.                                ***;
***  Label: Output Variable Label. =DEFAULT to use default label else specify. ***;
***         No Single or Double quotes, Commas, or Apostrophes in label.       ***;
***                                                                            ***;
*** EXAMPLE: %minEvent(bal,1,6,TimeOnbk, lt 10,maxbal1_6,0.1,returnMon=lastmo);***;
***                                                                            ***;
*** NOTES: stops searching array at minimum of end or tob.                     ***;  
***        Set to .M if start gt end and tob.                                  ***;
***        Set to .B if empty array or  condition not met.                     ***;
***        Macro will fail if condition contains a comma.                      ***;
***        drops temp variables created: icount                                ***;
***                                                                            ***;
***                                                                            ***;
**********************************************************************************;
**********************************************************************************;
%macro minEvent(arrayev,start,end,tob,condition,result,decimal,returnMon= ,label=DEFAULT);

   &RESULT=999999999;
  
	%if %length(&returnMon)> 0  %then %do;
	 &returnMon = 0;
	%end;

   if &start > min(&end,&tob) then do;
	 &result = .M;
	end;
   else do icount = &start to min(&end,&tob);

	   if not missing(&arrayev{icount}) and ( &arrayev{icount} < &result ) 
	   %if %length(&condition)> 0  %then %do;
		     and &arrayev{icount} &condition
		%end;
         then do;
			 &result = &arrayev{icount};
			 %if %length(&returnMon)> 0  %then %do;
				 &returnMon = icount;
			 %end;
			end;

   end;
	if  (&RESULT=999999999) then do;
	 	 &result = .B;
	end;
	else do;

    %if %sysevalf(&decimal > 0) %then %do;
	   if not missing(&result) then &result = round(&result,&decimal);
	 %end;
  	 %else %if &decimal = -1 %then %do;
      if not missing(&result) then &result = int(&result);
	 %end;

	end;

   drop icount;

	%if %nrbquote(%upcase(&label)) eq DEFAULT %then %do;
    label &result = "Min &arrayev. &start.-&end. months";
	%end;
	%else %if %length(&label) > 0 %then %do;
	 label &result = "&label "; 
	%end;				    

	%if %length(&returnMon)> 0  %then %do;
	  %if %nrbquote(%upcase(&label)) eq DEFAULT %then %do;
      label &returnMon ="Month of Min &arrayev. &start.-&end. months";
	  %end;
	  %else %if %length(&label) > 0 %then %do;
	   label &returnMon ="Month of  &label";
	  %end;
	%end;

%mend minEvent;



**********************************************************************************;
**********************************************************************************;
***    %macro maEvent(arrayev,start,end,tob,result,decimal,label=DEFAULT)      ***;
***                                                                            ***;
***  To calculate moving average of an array in last x months. Ignores missing.***;
***  Averages from the end value forward to the start value of the array.      ***;
***                                                                            ***;
***  arrayev: array to evaluate.                                               ***;
***  start: start month to evaluate.                                           ***;
***  end: last month to evaluate.   (Number of Months since start).            ***;
***  tob: Time on Book.                                                        ***;
***  result: Output Variable.                                                  ***;
***  decimal: decimal parameter when the result is to be rounded.              ***;
***           0 for no rounding. -1 for int truncation. Else between 0 and 1.  ***;
***  Label: Output Variable Label. =DEFAULT to use default label else specify. ***;
***         No Single or Double quotes, Commas, or Apostrophes in label.       ***;
***                                                                            ***;
*** EXAMPLE: %maValue(bal,1,6,TimeOnbk,maxbal1_6,0.1);                         ***;
***                                                                            ***;
*** NOTES: stops searching array at minimum of end or tob.                     ***;
***        Set to .M if start gt end and tob.                                  ***;
***        check for empty array -  if true then set to .B                     ***;
***        Macro will fail if condition contains a comma.                      ***;
***        drops temp variables created: icount  aux                           ***;
***                                                                            ***;
***                                                                            ***;
**********************************************************************************;
**********************************************************************************;
%macro maEvent(arrayev,start,end,tob,result,decimal,label=DEFAULT);
  
   &RESULT =.B;
   if &start > min(&tob,&end) then &Result=.M;
	else if &end > &tob then do;
									   /* unless zero use TOB or if possible TOB+1 */
		if &tob >0 then do;
     		aux=&tob ;
   	 /*	if &arrayev(aux+1)~=0 and not missing( &arrayev(aux+1) ) then aux=aux+1; */

			&result. = &arrayev.(aux);
  			DO icount =aux to (&start+1) by -1;
			  if &arrayev(icount-1) > .z then 
   			&result.=sum(&result. , &arrayev(icount-1))/2;
  	  		end;
	   end;

 	end; 
	else do;
							    /* use array end */
		&result. =&arrayev.(&end);
   	DO icount= &end to (&start+1) by -1;
		  if &arrayev(icount-1) > .z then 
   		&result. = sum(&result. , &arrayev(icount-1))/2;
	   end;		

  end;
  drop icount aux;

  if missing(&RESULT) then &RESULT = .B;

  %if %sysevalf(&DECIMAL gt 0 ) %then %do;
     if not missing(&RESULT) then &RESULT = round(&RESULT, &DECIMAL);	/* calculate result and round */
  %end;
  %else %if &DECIMAL = -1 %then %do;
    if not missing(&RESULT) then &RESULT = int( &RESULT ); 			   	/* calculate int result */
  %end;


 %if %nrbquote(%upcase(&label)) eq DEFAULT  %then %do;
   label &RESULT = "Moving Average &ARRAYEV last &end months";
 %end;
 %else %if %length(&LABEL) gt 0 %then %do;
   label &RESULT = "&LABEL";
 %end;  

%mend maEvent;


**********************************************************************************;
**********************************************************************************;
***  %macro maxconsec(arrayev,start,end,tob,condition,result,label=DEFAULT)    ***;
***                                                                            ***;
***  To calculate max consecutive months condition satisfied in last x months  ***;
***  of an array.                                                              ***;
***                                                                            ***;
***  arrayev: array to evaluate.                                               ***;
***  start: start month to evaluate.                                           ***;
***  end: last month to evaluate.   (Number of Months since start).            ***;
***  tob: Time on Book.                                                        ***;
***  condition: condition to satisify if array values are counted.             ***;
***             Should not be passed as missing argument.                      ***;
***  result: Output Variable.                                                  ***;
***  Label: Output Variable Label. =DEFAULT to use default label else specify. ***;
***         No Single or Double quotes or Apostrophes in label.                ***;
***                                                                            ***;
*** EXAMPLE: %mosinceEvent(bal,1,6,TimeOnbk, ge 10,maxbal1_6);                 ***;
***                                                                            ***;
*** NOTES: stops searching array at minimum of end or tob.                     ***;
***        Set to .M if start gt end and tob.                                  ***;
***        Set to .B if empty array. Returns zero if condition not met.        ***;
***        Macro will fail if condition contains a comma.                      ***;
***        drops temp variables created: icount _consecRuns                    ***;
***                                                                            ***;
***                                                                            ***;
**********************************************************************************;
**********************************************************************************;

%macro maxconsec(arrayev,start,end,tob,condition,result,label=DEFAULT);

   _consecRuns = 0;
   &result = .B;
	_flag_empty=1;
  
	if &start > min(&end,&tob) then &result=.M;
   do icount = &start to min(&end,&tob);
	  if (&arrayev{icount} > .z ) then _flag_empty=0;
      if (&arrayev{icount} &condition) then _consecRuns + 1;
      if not (&arrayev{icount} &condition) or ( icount=min(&end,&tob) ) then do;
         &result=max(&result, _consecRuns);
         _consecRuns = 0;
      end;
   end;
   if _flag_empty=1 then &result=.B;

   drop icount _consecRuns _flag_empty;

	%if %nrbquote(%upcase(&label)) eq DEFAULT  %then %do;
     label &result = "Max Consecutive &arrayev. &condition. &start.-&end. months";
   %end;
   %else %if %length(&LABEL) gt 0 %then %do;
     label &RESULT = "&LABEL";
   %end; 

  
%mend maxconsec;


**********************************************************************************;
**********************************************************************************;
***  %macro mosinceEvent(arrayev,start,end,tob,condition,result,label=DEFAULT) ***;
***                                                                            ***;
***  To calculate months since condition satisfied in last x months of an array***;
***  Returns first array position offset from start that satisfies condition.  ***;
***  Returns value equal .B if no months found that satisfy condition.         ***;
***   Example if start position meets condition then returns 0.                ***;
***        Error message if no condition specified.                            ***;
***                                                                            ***;
***  arrayev: array to evaluate.                                               ***;
***  start: start month to evaluate.                                           ***;
***  end: last month to evaluate.   (Number of Months since start).            ***;
***  tob: Time on Book.                                                        ***;
***  condition: condition to satisify if array values are counted.             ***;
***             Should not be passed as missing argument.                      ***;
***  result: Output Variable.                                                  ***;
***  Label: Output Variable Label. =DEFAULT to use default label else specify. ***;
***         No Single or Double quotes or Apostrophes in label.                ***;
***                                                                            ***;
*** EXAMPLE: %mosinceEvent(bal,1,6,TimeOnbk, > 10,maxbal1_6);                  ***;
***                                                                            ***;
*** NOTES: stops searching array at minimum of end or tob.                     ***;
***        Set to .M if start gt end and tob.                                  ***;
***        Set to .B if empty array or condition not met.                     ***;
***        Macro will fail if condition contains a comma.                      ***;
***        drops temp variables created: icount                                ***;
***        Error output if no condition specified.                             ***;
***                                                                            ***;
***                                                                            ***;
**********************************************************************************;
**********************************************************************************;
%macro mosinceEvent(arrayev,start,end,tob,condition,result,label=DEFAULT);

 %if %bquote(&condition) ne %then %do;

   &result = .B;

   if &start >  min(&end,&tob) then &result = .M;
   else do icount = &start to min(&end,&tob);
        if &arrayev{icount} &condition then do;
           &result = icount - (&start); 
           icount =  min(&end,&tob) + 1;	  * stop loop*;
        end;
   end;

   drop icount;
	
  %if %nrbquote(%upcase(&label)) eq DEFAULT  %then %do;
    label &RESULT = "Months Since &arrayev. &condition. &start.-&end. months";
  %end;
  %else %if %length(&LABEL) gt 0 %then %do;
    label &RESULT = "&LABEL";
  %end;  

  %end;
  %else %put Error: mosinceEvent condition is missing for &arrayev ;
   

%mend mosinceEvent;


**********************************************************************************;
**********************************************************************************;
***   %macro dates_snc(EVENT,NOW,RESULT,TYPE,label=DEFAULT,logFuture= )        ***;
***                                                                            ***;
***  To calculate number of intervals based on TYPE from EVENT to NOW dates    ***;
***                                                                            ***;
***  EVENT: From Event date in past.                                           ***;
***  NOW: To date.                                                             ***;
***  result: Output Variable.                                                  ***;
***  TYPE: Type of interval units for dates. valid types are (MON,DAY,YEAR,QTR)***;
***         If not valid TYPE then result is set to special missing .I  .      ***;
***  Label: Output Variable Label. =DEFAULT to use default label else specify. ***;
***         No Single or Double quotes or Apostrophes in label.                ***;
***  logFuture: if set to non-missing then put to log any Future Dates to check***;
***             Default (missing) does not check.                              ***;
***                                                                            ***;
*** EXAMPLE: %dates_snc(pastdue,refdate,daysnc,DAY,label=myLabel,logFuture=Y); ***;
***                                                                            ***;
*** NOTES: Missing or Invalid TYPE sets result to .I                           ***;
***        Set to .M if both dates are missing.                                ***;
***        Set to .A if missing NOW date. Set to .B if missing EVENT date.     ***;
***        Set to .N if EVENT is greater than NOW (future date).               ***;
***                                                                            ***;
***                                                                            ***;
**********************************************************************************;
**********************************************************************************;

%macro dates_snc(EVENT,NOW,RESULT,TYPE,label=DEFAULT,logFuture=);

  if (&NOW =.) and (&EVENT =.) then &RESULT=.M;    ** if both dates are missing *;
  else if (&NOW =.) then &RESULT=.A;	         	** if now date is missing *;
  else if (&EVENT =.) then &RESULT=.B;	            ** if event date is missing *;
  else if (&NOW lt &EVENT) then &RESULT=.N;        ** if event is before now *;
  else 
  %if &TYPE eq %then %do;
    &Result = .I;   * Invalid date type *;
  %end;
  %else %if %upcase(%QSUBSTR(&TYPE,1,1)) eq D %then %do;
   &RESULT = &NOW - &EVENT ;
  %end;
  %else %if %upcase(%QSUBSTR(&TYPE,1,1)) eq M %then %do;
   &RESULT=(year(&NOW)-year(&EVENT))*12 + (month(&NOW)-month(&EVENT));
  %end;
  %else %if %upcase(%QSUBSTR(&TYPE,1,1)) eq Y %then %do;
   &RESULT= year(&NOW)-year(&EVENT);
  %end;
  %else %if %upcase(%QSUBSTR(&TYPE,1,1)) eq Q %then %do;
   &RESULT=(year(&NOW)-year(&EVENT))*4 +(qtr(&NOW)-qtr(&EVENT));
  %end;
  %else %do;
    &Result = .I;  * Invalid date type *;
  %end;

  %if %nrbquote(%upcase(&label)) eq DEFAULT %then %do;								
   label &RESULT="&type.S Since &EVENT to &NOW ";
  %end;
  %else %if %length(&LABEL) gt 0 %then %do;
   label &RESULT = "&label";
  %end;

  %if %length(&logFuture) gt 0 %then %do;
								* write Future Dates to Log *;
   if (&RESULT=.N) then do;
     put 'FUTURE DATE CHECK: ' "&EVENT :"  &EVENT yymmdd10. ' NOW: ' &NOW yymmdd10. " &RESULT =>" &RESULT ;		  
   end;

  %end;

%mend dates_snc;




**********************************************************************************;
**********************************************************************************;
***  %macro ratio(num,den,result,factor,decimal,label=DEFAULT)                 ***;
***                                                                            ***;
***  To calculate # of occurrences of events that satisfy certain condition in ***;
***  the last x months.                                                        ***;
***                                                                            ***;
***  num: numerator variable.                                                  ***;
***  den: denominator variable.                                                ***;
***  result: Output Variable.                                                  ***;
***  factor: Multiplying Factor for resulting ratio.                           ***;
***  decimal: decimal parameter when the result is to be rounded.              ***;
***           0 for no rounding. -1 for int truncation. Else between 0 and 1.  ***;
***  Label: Output Variable Label. =DEFAULT to use default label else specify. ***;
***                                                                            ***;
*** EXAMPLE: %ratio(balance,avgBal,ratioBal,100,0.1);                          ***;
***                                                                            ***;
*** NOTES: stops searching array at minimum of end or tob.                     ***;
***        Set to special missing values A - F if num or den is 0 or missing.  ***;
***                                                                            ***;
***                                                                            ***;
**********************************************************************************;
**********************************************************************************;

%macro ratio(num,den,result,factor,decimal,label=DEFAULT);

     if (&NUM le .Z) and (&DEN le .Z)  then &RESULT = .A;
else if (&NUM le .Z) and (&DEN eq  0)  then &RESULT = .B;
else if (&NUM le .Z) and (&DEN gt .Z)  then &RESULT = .C;
else if (&NUM gt .Z) and (&DEN le .Z)  then &RESULT = .D;
else if (&NUM eq  0) and (&DEN eq  0)  then &RESULT = .E;
else if (&NUM gt .Z) and (&DEN eq  0)  then &RESULT = .F;
else

%if %sysevalf(&DECIMAL gt 0 ) %then %do;
  &RESULT = round((&FACTOR*(&NUM/&DEN)), &DECIMAL);		/* calculate result and round */
%end;
%else %if &DECIMAL = -1 %then %do;
  &RESULT = int( &FACTOR*(&NUM/&DEN) ); 					/* calculate int result */
%end;
%else %do;
  &RESULT = &FACTOR*(&NUM/&DEN); 					/* calculate result */
%end;
     ;

%if %nrbquote(%upcase(&label)) eq DEFAULT  %then %do;
   label &RESULT = "Ratio &NUM to &DEN";
%end;
%else %if %length( &LABEL) gt 0 %then %do;
   label &RESULT = "&LABEL";
%end;  

%mend ratio;


**********************************************************************************;
**********************************************************************************;
***  %macro createFlag(result,condition,trueValue=1,falseValue=0,label=DEFAULT) ***;
***                                                                            ***;
***  To create flag var with trueValue if condition satisifed else falseValue. ***;
***                                                                            ***;
***  result: Output Variable.                                                  ***;
***  trueValue: Value to assign if condition is true.                          ***;
***  falseValue: Value to assign if condition is not true (false).             ***;
***  condition: full condition to satisify if trueValue to be assigned.        ***;
***             Should not be passed as missing argument.                      ***;
***  Label: Output Variable Label. =DEFAULT to use default label else specify. ***;
***                                                                            ***;
*** EXAMPLE: %createFlag(result,condition,trueValue=1,falseValue=0,label=DEFAULT) ***;
***                                                                            ***;
*** NOTES: Error message if no condition is specified.                         ***;
***        Full Condition must be specified - nothing is assumed.              ***;
***        Macro will fail if condition contains a comma.                      ***;
***                                                                            ***;
***                                                                            ***;
**********************************************************************************;
**********************************************************************************;

%macro createFlag(result,condition,trueValue=1,falseValue=0,label=DEFAULT);

 %if %bquote(&condition) ne %then %do;

    if ( &condition ) then &result= &trueValue ;
	 else &result = &falsevalue;

    %if %nrbquote(%upcase(&label)) eq DEFAULT  %then %do;
      label &RESULT = "Flag &condition.";
    %end;
    %else %if %length(&LABEL) gt 0 %then %do;
      label &RESULT = "&LABEL";
	 %end;

 %end; 
 %else %put ERROR: createFlag &result condition &condition is missing;

%mend createFlag;


**********************************************************************************;
**********************************************************************************;
***   %macro mosworst(arrayev,start,end,tob,result,label=DEFAULT)              ***;
***                                                                            ***;
***  To calculate months since worst (MAX) over last x months of an array.     ***;
***                                                                            ***;
***  arrayev: array to evaluate.                                               ***;
***  start: start month to evaluate.                                           ***;
***  end: last month to evaluate.   (Number of Months since start).            ***;
***  tob: Time on Books.                                                       ***;
***  result: Output Variable.                                                  ***;
***  Label: Output Variable Label. =DEFAULT to use default label else specify. ***;
***         No Single or Double quotes, Commas, or Apostrophes in label.       ***;
***                                                                            ***;
*** EXAMPLE: %mosworst(bal,1,6,TimeOnbk,maxbal1_6);                            ***;
***                                                                            ***;
*** NOTES: searchs array from start to minimum of end or tob.                  ***;
***        check for empty array -  if true then set to .B                     ***;
***        Ignores missing values. (ie. compares only non-missing values).     ***;
***        set tob equal to or greater than end if all values to be checked.   ***;
***        drops temp variables created: icount  _worst.                       ***;
***                                                                            ***;
***                                                                            ***;
**********************************************************************************;
**********************************************************************************;
%macro mosworst(arrayev,start,end,tob,result,label=DEFAULT);
  _worst=.;
  if &start > min(&end,&tob) then &result=.M;
  else &result=.B;

  DO icount= &start to min(&end,&tob);

   if  &arrayev(icount) > .z and &arrayev(icount) > _worst  then do;
    _worst=&arrayev(icount);
	 &RESULT=icount;
   end;

  end;
  drop icount  _worst;

  %if %nrbquote(%upcase(&label)) eq DEFAULT %then %do;
     label &RESULT="Month of worst &ARRAYEV &start.-&end. months";
  %end;
  %else %if %length(&label) gt 0 %then %do;
     label &RESULT="&label";
  %end;

%mend mosworst;
