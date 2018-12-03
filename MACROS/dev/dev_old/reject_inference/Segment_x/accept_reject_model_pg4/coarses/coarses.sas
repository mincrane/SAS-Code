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

%include '../autoexec.sas';
%include '../../parameters_pg1.sas';

libname mdl "&dat" access=readonly;

%include "&_macropath./coarses/woe_vargen.sas";

data modeling;
  set dat.&build_set_ap&segment_number
      dat.&valid_set_ap&segment_number ;
  %include 'coarse_drop_list.txt';
   
run;


  

title "Segment &segment_number";
%woe_vargen(dset=modeling,perfvar=AR_flag,wghtvar=&weight,fname=flag_logic.txt);
