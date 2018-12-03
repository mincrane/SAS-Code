**********************************************************************;
* coarses_infer_pg7.sas: 7th step in reject inference process        *;
*                        Create coarses for All Good vs. All Bad     *;
*                        (booked+inferred) for selected varialbes    *;
*                        Also outputs format used in generating      *;
*                        swap set analysis                           *;
* Input: dat.riscores_seg&segment_number (final dataset)             *;
*         formgen.sas coarsemacros.sas                               *;
* Output: nformgen.out (format to be included in newAR_pg10.sas      *;
*         formgen.txt (intermediate file used to generate format     *;
*         format_names (variable name and associated format names    *;
*                       to be used in newAR_pg10.sas)                *;
* Note: 1. This is a minimun required list of variables for reject   *;
*          inference using standard ALI CB variables, check with PM  *;
*          for additional variables                                  *;
*       2. d_coarse_splt is used for numeric variables               *;
*          d_coarse_fct is to be used for char values or numeric var *;
*          which should be intepreted as character values, for       *;
*          example, worst credit bureau ratings                      *;
* Initial Release:                                                   *;
**********************************************************************;

%include 'parameters_pg1.sas';
%include 'coarsemacros.sas';

%let iteration=0;

options formdlim='-' compress=yes mprint symbolgen;   

x 'rm format_names';
x 'rm formgen.txt';
x 'rm formgen.out';


proc contents data=dat.riscores_seg&segment_number noprint out=content (KEEP=type name varnum);

DATA _null_;
length varnum2 $200.;
set content;
file "format_names" DLM=",";
if type=2 THEN varnum2=compress("V"||varnum||"C");
else varnum2=compress("V"||varnum||"N");
put name varnum2;
RUN;

title "All Good Bad Coarses - Iteration &iteration.";

%d_coarse_splt(dat.riscores_seg&segment_number,perf_post,BAD,0,0,GOOD,1,1,wghtfin ,SBRI_Card_Score            ,10.0,10,D,,);
%d_coarse_splt(dat.riscores_seg&segment_number,perf_post,BAD,0,0,GOOD,1,1,wghtfin ,SBRI_Lease_Score                    ,10.0,10,D,,);
%d_coarse_splt(dat.riscores_seg&segment_number,perf_post,BAD,0,0,GOOD,1,1,wghtfin ,SBRI_Loan_Score                 ,10.0,10,D,,);

%include 'formgen.sas';

