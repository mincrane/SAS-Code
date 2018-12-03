********************************************************************;
* sample_pg2.sas: Second step of the reject inference procedure    *;
*                 Create build and validation datasets for both    *;
*                 recent CB datasets (used for building KGB model) *;
*                 and application datasets (for RA model)          *;
* Input: &data_name_recent and &data_name_application defined in   *;
*        parameters1.sas                                           *;
* Output: &build_set_re &valid_set_re &build_set_ap &valid_set_ap  *;
*         defined in parameters1.sas                               *;
*         and application_data_seg&segment_number dataset used     *;
*         to create AGB dataset in AGB directory                   *;
*         No variables are dropped from datasets, to exclude vars  *;
*         from the models, use define_exclude_names in each model  *;
*         directory                                                *;
* Variables created in this program: &perf_ra, book_flag           *;
*                                    &weight_one                   *;
* Changes need to make in this program:                            *;
*         check with the PM to know how the accept/reject and      *;
*         book/not booked are defined in the original performance  *;
*         variable, modify the part below (search for @@@)         *;
********************************************************************;

 
%include 'parameters_pg1.sas';


%macro sample (data_source, label, build_data, valid_data, perf2,label2);
data temp;
  set &data_source;
  &weight_one=1;
run;

proc freq data=temp;
  tables &perf2;
  weight &weight;
  title "Weighted  &label2 for &segment_name &label ";
  title2 "Dataset: &data_source";
run;

proc freq data=temp;
  tables &perf2;
  title "Unweighted &label2 for &segment_name &label";
run;

data &build_data (compress=yes) &valid_data (compress=yes);
  set temp;
%************"ADDED for ANB modification"*************;
*  where &perf in (&valid_perf_AR.) ;
%***************************************************;
  ran= ranuni(853275); 
  if ran <= .7 then output &build_data;
  else output &valid_data   ;
  drop ran;
run;

proc freq data=&build_data;
  tables &perf2 / missing;
  weight &weight;
  title "Weighted &segment_name Building Sample at &label";
  title2 "Dataset: &build_data";
run;

proc freq data=&valid_data ;
  tables &perf2 / missing;
  weight &weight;
  title "Weighted &segment_name Validation Sample at &label";
  title2 "Dataset: &valid_data";
run;

proc freq data=&build_data;
  tables &perf2 / missing;
  title "Un-weighted &segment_name Building Sample at &label";
  title2 "Dataset: &build_data";
run;

proc freq data=&valid_data ;
  tables &perf2 / missing;
  title "Un-weighted &segment_name Validation Sample at &label";
  title2 "Dataset: &valid_data";
run;

%mend;

%sample( dat.&data_name_recent ,Recent, dat.&build_set_re.&segment_number,
    dat.&valid_set_re.&segment_number, &perf, Known Goods Bads );


/* @@@ Create the AR flag************************************/
/* Check with the PM the values that go in each category*/;
/* make sure you subset the application data to the right segment -IF statement-*/

data dat.application_data_seg&segment_number;
  set dat.&data_name_application;
%************"ADDED for ANB modification"*************;
*  where &perf in (&valid_perf_AR.) ;
%***************************************************;

    if &perf in (&reject. &ANB.) then Book_flag=0;
    else if &perf in (&good. &bad.) then Book_flag=1;
    else Book_flag=99;
    if &perf in (&reject.) then AR_flag=0;
    else if &perf in (&good. &bad. &ANB.) then AR_flag=1;
    else AR_flag=99;

run;

*************************************;
*** KS - commented this out 10_21_05;
*proc sort data= dat.application_data_seg&segment_number;
*  by &appid;
*run;

%sample( dat.application_data_seg&segment_number,Application, dat.&build_set_ap.&segment_number ,
      dat.&valid_set_ap.&segment_number , ar_flag, Reject Accepts);


proc freq data=  dat.application_data_seg&segment_number;
  title "Dataset: 	  dat.application_data_seg&segment_number";
  tables book_flag;
run;

proc freq data=  dat.application_data_seg&segment_number;
  title " TIME OF APPLICATION DATA FOR SEGMENT &SEGMENT_NUMBER  -UNWEIGHTED-";
  title2 "Dataset: 	  dat.application_data_seg&segment_number ";
  tables &perf;
run;

proc freq data=  dat.application_data_seg&segment_number;
  title " TIME OF APPLICATION DATA FOR SEGMENT &SEGMENT_NUMBER  -WEIGHTED-";
  title2 "Dataset: 	  dat.application_data_seg&segment_number ";
  weight &weight;
  tables &perf;
run;

