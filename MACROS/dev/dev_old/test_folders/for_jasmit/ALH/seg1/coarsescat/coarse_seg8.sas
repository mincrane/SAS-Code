libname dat '/sas/pprd/austin/projects/alh_offebay/data';
options nocenter formdlim='-';
title1 'ALH offebay Seg1';
%include '/sas/pprd/austin/operations/misc/saspp/Macros_General/macros_general.sas';
data summary_coarses;
length longname $50 name $50;
N=0; NMISS=0; MEAN=0; MAX=0; MIN=0; NAME='        ';
run;


data seg8; 
	set dat.alh_offebay_na_sample;
	where seg = 'Occasional';
	
	%include '/sas/pprd/austin/projects/alh_offebay/model/NA/seg1/cat_var_list.txt';
	
	keep sam_wgt bad ;
run;

 
%finefct_f(seg8,bad,BAD ,0,0,GOOD ,1,1,sam_wgt ,biz_cat_name_risk                                 ,,summary_coarses);/* length of 2 */
%finefct_f(seg8,bad,BAD ,0,0,GOOD ,1,1,sam_wgt ,eby_cat_name_risk                                 ,,summary_coarses);/* length of 2 */
%finefct_f(seg8,bad,BAD ,0,0,GOOD ,1,1,sam_wgt ,meta_cat_name_risk                                ,,summary_coarses);/* length of 2 */
%finefct_f(seg8,bad,BAD ,0,0,GOOD ,1,1,sam_wgt ,pp_cat_name_risk                                  ,,summary_coarses);/* length of 2 */
%finefct_f(seg8,bad,BAD ,0,0,GOOD ,1,1,sam_wgt ,web_cat_name_risk                                 ,,summary_coarses);/* length of 2 */
%finefct_f(seg8,bad,BAD ,0,0,GOOD ,1,1,sam_wgt ,prmry_reside_cntry_code                           ,,summary_coarses);/* length of 3 */
%finefct_f(seg8,bad,BAD ,0,0,GOOD ,1,1,sam_wgt ,seg                                               ,,summary_coarses);/* length of 10 */
%finefct_f(seg8,bad,BAD ,0,0,GOOD ,1,1,sam_wgt ,cont_slr_flag                                     ,,summary_coarses);/* length of 21 */
%finefct_f(seg8,bad,BAD ,0,0,GOOD ,1,1,sam_wgt ,acct_cat_name                                     ,,summary_coarses);/* length of 50 */
%finefct_f(seg8,bad,BAD ,0,0,GOOD ,1,1,sam_wgt ,biz_cat_name                                      ,,summary_coarses);/* length of 50 */
%finefct_f(seg8,bad,BAD ,0,0,GOOD ,1,1,sam_wgt ,ebay_cat_id_2                                     ,,summary_coarses);/* length of 50 */
%finefct_f(seg8,bad,BAD ,0,0,GOOD ,1,1,sam_wgt ,ebay_cat_id_3                                     ,,summary_coarses);/* length of 50 */
%finefct_f(seg8,bad,BAD ,0,0,GOOD ,1,1,sam_wgt ,ebay_cat_name                                     ,,summary_coarses);/* length of 50 */
%finefct_f(seg8,bad,BAD ,0,0,GOOD ,1,1,sam_wgt ,meta_cat_name                                     ,,summary_coarses);/* length of 50 */
%finefct_f(seg8,bad,BAD ,0,0,GOOD ,1,1,sam_wgt ,pp_cat_name                                       ,,summary_coarses);/* length of 50 */
%finefct_f(seg8,bad,BAD ,0,0,GOOD ,1,1,sam_wgt ,web_cat_name                                      ,,summary_coarses);/* length of 50 */

 proc sort data= summary_coarses ; by descending KS name; run; 

%desc_f(summary_coarses);
