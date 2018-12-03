

%LET titlename= ALH offebay Seg1 ;
%LET summary_file=summary_coarses;			  /* Summary Stats dataset to output - include library name */
%LET library=/sas/pprd/austin/projects/alh_offebay/data;			  /* set to data library and dataset names */
%LET data_in= seg8;
%LET perf_def=bad;							   
%let wgtvar= sam_wgt;
%let GOOD_NAME =GOOD;
%let BAD_NAME =BAD;
%LET outfile= coarse_seg8.sas;					 /* output coarses SAS file */

%let _mgPath=  /sas/pprd/austin/operations/misc/saspp/Macros_General/create_coarses.sas ;		/* set to Macros_General folder path  */

libname dat "&library";
libname local '.';
options nodate ps=8000 formdlim="-" ;


data seg8; 
	set dat.alh_offebay_na_sample;
	where seg = 'Occasional';
	
	%include '/sas/pprd/austin/projects/alh_offebay/model/NA/seg1/cat_var_list.txt';
	
	keep sam_wgt bad ;
run;

 /*
proc stdize data=seg9
	MISSING=0 
	REPONLY 
	out=seg9_mod;
run; 
 */

data data_in;
   set &data_in;
	 drop &perf_def &wgtvar ;
run;                                                                                                      

proc contents data=data_in noprint out=content;  

proc sort data=content;
by descending type length;
run;

data temp;
  set content (keep = name type length) end=last;
  file "&outfile ";
  if _n_ eq 1 then do;
    put "libname dat '" "&library"  "';";
    put "options nocenter formdlim='-';";
    put "title1 '" "&titlename" "';";
    put "%include '" "&_mgPath.macros_general.sas" "';" ;
    put "data &summary_file;";
    put "length longname $50 name $50;";                                                                                        
    put "N=0; NMISS=0; MEAN=0; MAX=0; MIN=0; NAME='        ';";                                                      
    
    put "run;"; 

    put ' ';
  end;
  if (type=1)  
  then do;
    put '%finesplt_f(' "&data_in,&perf_def,&BAD_NAME ,0,0,&GOOD_NAME ,1,1,&wgtvar ," @;
	 put name $50. @;
    put ",10.0,10,&summary_file);";
    end;
   if (type=2) 
	then do;
    put '%finefct_f(' "&data_in,&perf_def,&BAD_NAME ,0,0,&GOOD_NAME ,1,1,&wgtvar ,"@;
    put name $50. @;
    put ",,&summary_file);" "/* length of " length "*/";
  end;   
 if last THEN do;
   put / " proc sort data= &summary_file ; by descending KS name; run; " / ;
   put '%desc_f(' "&summary_file);";
 end;
run;

                                                                                                          





