%MACRO Write_Iteration_Report(inset=,iterationout=);

proc printto print="&iterationout" new;
RUN;

proc report data=&inset nowd split='*' headline headskip missing;
	column   
name	
DevelopmentKS
DevelopmentIVAL
ValidationKS
ValidationIVAL
TotalKS
TotalIVAL
DevelopmentReversalCount
DevelopmentAlignmentAlertCount
ValidationReversalCount
ValidationAlignmentAlertCount
TotalReversalCount
TotalAlignmentAlertCount
SamplingSeed
MaxVIF
MaxCorrCoeff
NumberofVariables
TotalWeightedBLDCount
NonEventWeightedBLDCount
EventWeightedBLDCount
WeightedBLDEventRate
TotalWeightedVLDCount
NonEventWeightedVLDCount
EventWeightedVLDCount
WeightedVLDEventRate
EventUnweightedVLDCount
TotalWeightedTOTCount
NonEventWeightedTOTCount
EventWeightedTOTCount
WeightedTOTEventRate
TotalUnweightedBLDCount
NonEventUnweightedBLDCount
EventUnweightedBLDCount
UnweightedBLDEventRate
TotalUnweightedVLDCount
NonEventUnweightedVLDCount
UnweightedVLDEventRate
TotalUnweightedTOTCount
NonEventUnweightedTOTCount
EventUnweightedTOTCount
UnweightedTOTEventRate
;
define name  /display 'Name' width=10;
define SamplingMethod /display 'Sampling*Method' width=10;
define SamplingSeed /display 'Sampling*Seed' width=10;
define MaxVIF /display 'Max*VIF' width=10;
define MaxCorrCoeff /display 'Max*Corr*Coeff' width=10;
define NumberofVariables /display 'Number*of*Variables' width=10;
define TotalUnweightedBLDCount /display 'Total*Unweighted*BLD*Count' width=10;
define NonEventUnweightedBLDCount /display 'Non-Event*Unweighted*BLD*Count' width=10;
define EventUnweightedBLDCount /display 'Event*Unweighted*BLD*Count' width=10;
define UnweightedBLDEventRate /display 'Unweighted*BLD*Event*Rate' width=10;
define TotalWeightedBLDCount /display 'Total*Weighted*BLD*Count' width=10;
define NonEventWeightedBLDCount /display 'Non-Event*Weighted*BLD*Count' width=10;
define EventWeightedBLDCount /display 'Event*Weighted*BLD*Count' width=10;
define WeightedBLDEventRate /display 'Weighted*BLD*Event*Rate' width=10;
define TotalUnweightedVLDCount /display 'Total*Unweighted*VLD*Count' width=10;
define NonEventUnweightedVLDCount /display 'Non-Event*Unweighted*VLD*Count' width=10;
define EventUnweightedVLDCount /display 'Event*Unweighted*VLD*Count' width=10;
define UnweightedVLDEventRate /display 'Unweighted*VLD*Event*Rate' width=10;
define TotalWeightedVLDCount /display 'Total*Weighted*VLD*Count' width=10;
define NonEventWeightedVLDCount /display 'Non-Event*Weighted*VLD*Count' width=10;
define EventWeightedVLDCount /display 'Event*Weighted*VLD*Count' width=10;
define WeightedVLDEventRate /display 'Weighted*VLD*Event*Rate' width=10;
define TotalUnweightedTOTCount /display 'Total*Unweighted*TOT*Count' width=10;
define NonEventUnweightedTOTCount /display 'Non-Event*Unweighted*TOT*Count' width=10;
define EventUnweightedTOTCount /display 'Event*Unweighted*TOT*Count' width=10;
define UnweightedTOTEventRate /display 'Unweighted*TOT*Event*Rate' width=10;
define TotalWeightedTOTCount /display 'Total*Weighted*TOT*Count' width=10;
define NonEventWeightedTOTCount /display 'Non-Event*Weighted*TOT*Count' width=10;
define EventWeightedTOTCount /display 'Event*Weighted*TOT*Count' width=10;
define WeightedTOTEventRate /display 'Weighted*TOT*Event*Rate' width=10;
define DevelopmentKS /display 'Development*KS' width=11;
define DevelopmentIVAL /display 'Development*IVAL' width=11;
define ValidationKS /display 'Validation*KS' width=10;
define ValidationIVAL /display 'Validation*IVAL' width=10;
define TotalKS /display 'Total*KS' width=10;
define TotalIVAL /display 'Total*IVAL' width=10;
define DevelopmentReversalCount /display 'Development*Reversal*Count' width=11;
define DevelopmentAlignmentAlertCount /display 'Development*Alignment*Alert*Count' width=11;
define ValidationReversalCount /display 'Validation*Reversal*Count' width=10;
define ValidationAlignmentAlertCount /display 'Validation*Alignment*Alert*Count' width=10;
define TotalReversalCount /display 'Total*Reversal*Count' width=10;
define TotalAlignmentAlertCount /display 'Total*Alignment*Alert*Count' width=10;
RUN;



proc report data=&inset nowd split='*' headline headskip missing;
	column   
name	
iteration

eventval
noneventval
perfvar
wghtvar
tpvvar
lossvar
sampling
sampprop
resample
selection
pentry
pexit
intercept
linkfunc
maxstep
maxiter
perfgrp
modelsub
varforced
dset
rootdir
datadir
;
	
define name         /display 'name' width=10;
define iteration    /display 'iteration' width=10;
define dset         /display 'dset'         ;
define eventval     /display 'eventval'   width=10  ;
define noneventval  /display 'noneventval' width=11  ;
define perfvar      /display 'perfvar'    width=10  ;
define wghtvar      /display 'wghtvar'    width=10  ;
define tpvvar       /display 'tpvvar'     width=10 ;
define lossvar      /display 'lossvar'    width=10 ;
define varforced    /display 'varforced'  width=10 ;
define sampling     /display 'sampling'   width=10 ;
define sampprop     /display 'sampprop'   width=10 ;
define resample     /display 'resample'   width=10 ;
define selection    /display 'selection'  width=10 ;
define pentry       /display 'pentry'     width=10 ;
define pexit        /display 'pexit'      width=10 ;
define intercept    /display 'intercept'  width=10 ;
define linkfunc     /display 'linkfunc'   width=10 ;
define maxstep      /display 'maxstep'    width=10 ;
define maxiter      /display 'maxiter'    width=10 ;
define perfgrp      /display 'perfgrp'    width=10 ;
define modelsub     /display 'modelsub'  width=10  ;
define rootdir      /display 'rootdir'     ;
define datadir	    /display 'datadir'	   ;
	

run;



proc printto;
run;	

%MEND Write_Iteration_Report;
	