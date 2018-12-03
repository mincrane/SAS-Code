***************************************************************************;
* newAR_pg9.sas: 9th step of the reject inference process               *;
*                 create swap set analysis using the quick All Good Bad   *;
*                 model developed in model_pg8, by selecting a cut-off    *;
*                 score that keeps the historical acceptance rate         *;
*                 new approval rate at attribute level for each selected  *;
*                 characteristics are generated.  Usually expect to see   *;
*                 the new scorecard will approve more at better attribute *;
*                 and decline more at worse attribute level               *;
* Note: 1. On the macro call of the first variable of choice, put Y to    *;
*          to indicate its the first, and summary swap set will only be   *;
*          generated once (see more notes on newAR_macro.sas)             *;
*       2. The formats for the minimum required list of variables have    *;
*          been generated in formgen.out by coarses_infer_pg7.sas, and is *;
*          included in this program. Look for the variable name and format*;
*          name match in formgen.txt.  For additional variables, either   *;
*          add customized formats in this program or use                  *;
*          coarses_infer_pg7.sas to generate coarses and formats for more *;
*          variables                                                      *;    
*       3. Historical Accepted are booked good + booked bad + ANB         *;
*          AR = (good+bad+ANB) 
* Input: dat.riscores_seg&segment_number                                  *;
*        formgen.out (proc format)                                        *;
*        formgen.txt (variable name and format name matching)             *;
*        newAR_macros.sas                                                 *;
* Output: Swap set for entire population and new acceptance rate at each  *;
*         attribute level for selected variables                          *;
***************************************************************************;

%include 'parameters_pg1.sas';  

%include "macros.sas";

options symbolgen mprint mlogic  formdlim='-' nocenter;

	
/* Macro to create swap table analysis - assumes 0 for bad and 1 for good */
/* Historical or Original Acceptance Rate calculated from good+bad/(good+bad+reject) */

%include 'newAR_macro.sas';

/* Edit to the RI inference at this point ie. wghtfin (for orignal agb) wghtfin_1 etc if tweaking */
%let weight_swap=wghtfin;
%let scored_set=dat.scr_all_agb;

proc sort data=dat.riscores_seg&segment_number;
	by &appid;
run;


data tmpscores(where =(&perf in (&good. &bad. &ANB. &reject.)) );
  MERGE  dat.riscores_seg&segment_number
         &scored_set (KEEP=score_agb_ap &appid);
   by &appid;

  tmpscore =score_agb_ap;
  label  tmpscore = 'Aligned GB Temp Score for Swapset';
run;



/* 
 * Perform swapset comparison of scores for AR_flag and new Accept-Rejects 
 *
 * %newAR(inDS,inVar,inWeight,inScore,outfile);
 * 
 * inDS - temp Data table of scores created above - do not need to edit.
 * inVar - Set variable for swapset analysis  - edit.
 * inWeight - Use weight macro value - do not need to edit.
 * outFile - Name of output text file containing swapset results , edit for each variable analyzed - 
 *           file name should be prefixed with newAR_compare_  and  file type .txt
 *
*/

/* create custom format for grouping the variable requested - change for different desired formats/variables */

%include 'formgen.out';
****************************EDIT AS PER REQUIREMENT ********************************;

%newAR(tmpscores,SBRI_Card_Score            , V158N.,&weight_swap,tmpscore,newAR_compare_&segment_number..txt,Y);
%newAR(tmpscores,SBRI_Lease_Score                    ,V159N. ,&weight_swap,tmpscore,newAR_compare_&segment_number..txt,);
%newAR(tmpscores,SBRI_Loan_Score                 ,V160N.,&weight_swap,tmpscore,newAR_compare_&segment_number..txt,Y);
