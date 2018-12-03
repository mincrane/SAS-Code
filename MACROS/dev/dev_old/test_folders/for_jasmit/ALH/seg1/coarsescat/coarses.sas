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


%let _macropath= /sas/pprd/austin/operations/macro_library/dev;

libname dat '/sas/pprd/austin/projects/alh_offebay/data' access=readonly;

%include "&_macropath./coarses/woe_vargen.sas"; 

data modeling; 
	set dat.alh_offebay_na_sample;
	where seg ~= 'Occasional';
	
	*%include '../keeplist.txt';
  %include '/sas/pprd/austin/projects/alh_offebay/vargen/zxue/interaction_var.txt';
  *%include '/sas/pprd/austin/projects/alh_offebay/vargen/zxue/interaction_var_list.txt';
	
	*keep mod_wgt_2 sam_wgt wgt_loss_2 bad;
	
	%include './coarse_drop_list.txt';

run;

title "Segment NA non-occasional";
%woe_vargen(dset=modeling,perfvar=bad,wghtvar=sam_wgt,fname=flag_logic.txt);



