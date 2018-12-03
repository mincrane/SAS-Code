/******************************************************************************************** 
/* Program Name:    modeling_univ.sas
/* Project:         SML Behavioral Models 2010
/* Author:          F.Zahradnik
/* Creation Date:   2010-05-22
/* Last Modified: 
/* Purpose:         Univariate statistics Segment 5
/* Arguments: 
*********************************************************************************************/ 
options nocenter formdlim='-' ps=95;
%include '../autoexec.sas';
%include '../../parameters_pg1.sas';

libname mdl "&dat" access=readonly;


%include "&_macropath./univariate/univariate_macro.sas";

data modeling;
  set dat.&build_set_ap&segment_number
      dat.&valid_set_ap&segment_number ;

  
  %include 'univ_drop_list.txt';
  
run;

%univ(dset=modeling,oset=seg,perf=AR_flag,weight=&weight);


