/******************************************************************************************** 
/* Program Name:    coarses_segment3.sas
/* Project:         SML Behavioral Model 2010
/* Author:          F.Zahradnik
/* Creation Date:   2010-05-22
/* Last Modified:   
/* Purpose:         Coarses 
/* Arguments: 
*********************************************************************************************/ 
options nocenter formdlim='-' ps=95;


libname dat "/sas/pprd/austin/projects/alh_offebay/data" access=readonly;
%let segment_number = 1;
%let _macropath= /sas/pprd/austin/operations/macro_library/dev;
%include "&_macropath./coarses/woe_vargen.sas"; 

data seg1_mod_ds;
    set dat.alh_offebay_na_sample;
    where seg = 'Occasional';

    %include '/sas/pprd/austin/projects/alh_offebay/vargen/zxue/interaction_var.txt';
    * %include '/sas/pprd/austin/projects/alh_offebay/vargen/zxue/interaction_var_list.txt';
    %include "../coarse_drop_list.txt";
run;


title "Segment &segment_number"; 
%woe_vargen(dset=seg1_mod_ds,perfvar=bad,wghtvar=mod_wgt_2,fname=flag_logic.txt);

