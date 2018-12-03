/******************************************************************************************** 
/* Program Name:		impute_special_missings.sas
/* Author: 					G. Nevada
/* Creation Date:   5/21/2010
/* Last Modified:   5/21/2010   
/* Purpose:         Impute special missing values with midpoint value of 
                    variable with closest WOE. 
/* Arguments:       VARIABLE- name of variable. Must be numeric
                    PERF- variable containing performance
                    WEIGHT - weight
                    DATASET - Input Dataset
/* Output:          temporary data set called IMPUTE_SPECIAL_MISSING
                    containing 3 variables:   VARNAME RAW_MISSING IMPUTE_VALUE                   
								    

/* Assumptions/:    Missing breaks that have less than 20 goods and 20 bads
   Notes            are combined into 1 break.
                    Imputed into to each of the missings is the unweighted midpoint 
                    of the range of real value  to the closest WOE value of the same sign.  
                    For the lowest break, the high point is taken. 
                    If there is any other WOE that is within 10% of the closest WOE value 
                    that have more than combined goods + bads of 100, we impute with the one 
                    that is most locally monotonic.
                    If there are NO non-missing breaks with the same sign as the WOE of the 
                    missing value, impute with 0.
***********************************************************************************************/
%include "&_macropath./general/macros_general.sas";

%MACRO impute_special_missings(variable=, perf=, weight=, dataset=);
		
%finesplt_f(&dataset,&perf,good,1,1,bad,0,0,&weight,&variable,10.2,10,);

title1;

DATA _null_;
	 SET grouped end=last;
	 if _n_=1 AND &variable > .Z THEN CALL SYMPUT('NoMissing',1);
	 ELSE  CALL SYMPUT('NoMissing',0);
	 if last and &variable <= .Z THEN CALL SYMPUT('AllMissing',1);
	 ELSE  CALL SYMPUT('AllMissing',0);
RUN;

%IF &NoMissing=0 and &allMissing=0 %THEN %DO;	 

DATA grouped ;
	 SET grouped (KEEP=&variable _nogood _nobad _weight) end=last;
	 
	 *Create Low End for Range;
	 low_end=lag1(&variable);
	 if low_end<=.Z THEN low_end=&variable;
	 
	 *Get MidPoint;
	 if low_end>.Z AND &variable>.Z THEN Midpoint=(&variable - low_end)/2 + low_end;
	 
	 *create flag for small breaks;
	  
	   Flag_Small=(_nogood+_nobad<=100);  
  
	 
	 *create varname with combined small missing cells;
	 if _NoGood <=20 AND _NoBad<=20 and &variable<=.Z THEN  New_Varname=._;
	 else New_Varname=&variable; 
	 
	 if _n_=1 THEN DO; 
	   Comb_SP_Good=0;
	   Comb_SP_Bad=0;
	 end;
	 
	 If New_Varname=._ THEN 
	  do; 
	  	Comb_SP_Good + _nogood;
	    Comb_SP_Bad + _nobad; 
	  end;  
	 
	 if last then do;
	 	 call symput('SpGood',Comb_SP_Good);
	 	 call Symput('SPBad',Comb_SP_Bad); 
	 end;
	 
	 *create cumulative goods and bads and count the number of non-missing breaks;
	 if _n_=1 THEN DO;
	 	Cum_Goods=0; Cum_Bads=0;
	 	Non_Missing_Breaks=0;
	 	
	 end;
	  Cum_Goods + _nogood;
	  Cum_Bads + _nobad;
	 if low_end>.Z THEN Non_Missing_Breaks + 1;
	 if last then do;
	   call symput('Cgood',Cum_Goods);
	   call symput('Cbad',Cum_Bads);	
	   call symput('nmb',Non_Missing_Breaks);	
	 end;	
	 
	 
	 
	 *count monotonic. count increases if monotonic, gets sent back to 0 if pattern reverses;
	    if low_end >.Z THEN lag_weight=lag1(ROUND(_weight,0.001));
	    
	    if _n_=1 THEN do;
	    	  Monotonic=0;
	    	  Sign=" ";
	    end;   
	    
	    If Lag_Weight<_Weight and &variable>.Z THEN Sign="+"; 
	    ELSE If Lag_Weight > _Weight  and &variable>.Z THEN Sign="-";
	    ELSE if &variable>.Z AND Lag_Weight = _Weight THEN  Sign=Lag_Sign;
	    
	    lag_sign=lag1(sign);	
	    
	    If Sign=Lag_Sign THEN Monotonic + 1;
	    ELSE Monotonic=0;
	    
	  
 
RUN;

*create macro variables to use as arrays in next data step;

 proc sql noprint;
  	select midpoint
  	      ,_weight
  	      ,monotonic
  	      ,flag_small
  	into: midlist separated by " ",
  	    : weightlist separated by " ",
  	    : monlist separated by " ",
  	    : flagsmall separated by " "
  	from grouped
  	where midpoint > .Z;
  	;
  quit;


DATA grouped impute_special_missing (KEEP=VARNAME   RAW_MISSING IMPUTE_VALUE);
	 SET grouped ;
	 
	  array mids {&nmb}  _temporary_  (&midlist);
	  array weight_array {&nmb} _temporary_ (&weightlist);
    array mon {&nmb}  _temporary_  (&monlist);
    array flagsmall {&nmb}  _temporary_  (&flagsmall);
    array mon_transformed {&nmb} _temporary_;
    array candidate (&nmb) _temporary_;
    
    
    *Put maximum length of monotonic string value is part of. For example, if there are 5 breaks that are steadily increasing;
    *all 5 in that string will get the number 5;
    
    do i = &nmb to 2 by -1;
    	if i = &nmb THEN mon_transformed(i)=mon(i);
      if mon(i)>mon(i-1) THEN mon_transformed(i-1)=mon_transformed(i);
      else mon_transformed(i-1)=mon(i-1);
    END;	
    
    
    *Re-Create Weight Variable - needed because of combining small missing values;
	 	if New_Varname=._ THEN DO;
	 		Cell_Good=&SpGood;
	 		Cell_Bad=&SpBad;
	 	END;
	 	ELSE DO;
	 		Cell_Good=_nogood;
	 		Cell_Bad=_nobad;
	 	END;		
	 
	 	WEIGHT  = log(((Cell_Good+0.000001)/&Cgood) / ((Cell_Bad+0.000001)/&Cbad));     
	 	
	 
	  *Find Closest weight value that is same sign and not a small break;
	  Closest_Value=9999999;

	  do i = 1 to &nmb;
	     if flagsmall(i)=0 and weight_array(i)*weight>0 THEN candidate(i)=abs(abs(weight) - abs(weight_array(i)));
	     else candidate(i)=9999999;
	     if candidate(i)<Closest_Value and candidate(i)>.Z THEN do;
	     	  Closest_Value=candidate(i);
	     	  Closest_Value_Index=i;
	     	end;  
	  end;	  
	  
	  
	  *Flag weight values within 10% of Max Value and pick which of those have highest mon_transformed;
	  if closest_value~=9999999 THEN DO;
	  	Closest_value=weight_array(Closest_Value_Index);
	  	highest_Mon_Transformed=mon_transformed(Closest_Value_Index);  
      do i = 1 to &nmb;
      	 percent_diff=abs(abs(closest_value) - abs(weight_array(i)))/abs(closest_value);
	       if percent_diff<=.1 and flagsmall(i)=0 and weight_array(i)*weight>0  THEN DO;
	       	if mon_transformed(i)> highest_Mon_Transformed THEN do;
	          	  highest_Mon_Transformed=mon_transformed(i);
	          	  Closest_Value_Index=i;
	         end;	  
	       	
	      END;
	    end;	
	   
	   Impute_Value= mids(Closest_Value_Index);
	   Which_Weight_Matched=weight_array(Closest_Value_Index);
	  
	 end;
	 Else Impute_Value=0; /*impute w/ zero if there is no weights of the same sign*/
	  
	 varname="&variable";
   Raw_Missing=&variable;
   	
	 if &variable <=.Z then output impute_special_missing ;
	 output grouped;

RUN;	



proc print data=impute_special_missing ;
	var varname Raw_Missing Impute_Value;
RUN; 
	
%END;
%ELSE %DO;
  %IF &NoMissing=1 %THEN %put "No Missing Values to Impute for Variable: &variable";
  %IF &ALLMissing=1 %THEN %put "All Missing Values for Variable: &variable";
%END;
	
%MEND;

