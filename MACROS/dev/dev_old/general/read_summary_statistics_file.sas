%MACRO read_summary_stats_file(name=, indir=, outset=);


DATA outfile;

 
  INFILE "&indir/Summary_Statistics.txt" ls=1000 recfm=v length=long missover end=last ;
  input @1 line $varying300. long;

name="&name";
IF INDEX(LINE,'Sampling Method' ) > 0 THEN SamplingMethod = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Sampling Seed' ) > 0 THEN SamplingSeed = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Max VIF' ) > 0 THEN MaxVIF = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Max Corr Coeff' ) > 0 THEN MaxCorrCoeff = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Number of Variables' ) > 0 THEN NumberofVariables = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Total Unweighted BLD Count' ) > 0 THEN TotalUnweightedBLDCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Non-Event Unweighted BLD Count' ) > 0 THEN NonEventUnweightedBLDCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Event Unweighted BLD Count' ) > 0 THEN EventUnweightedBLDCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Unweighted BLD Event Rate' ) > 0 THEN UnweightedBLDEventRate = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Total Weighted BLD Count' ) > 0 THEN TotalWeightedBLDCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Non-Event Weighted BLD Count' ) > 0 THEN NonEventWeightedBLDCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Event Weighted BLD Count' ) > 0 THEN EventWeightedBLDCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Weighted BLD Event Rate' ) > 0 THEN WeightedBLDEventRate = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Total Unweighted VLD Count' ) > 0 THEN TotalUnweightedVLDCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Non-Event Unweighted VLD Count' ) > 0 THEN NonEventUnweightedVLDCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Event Unweighted VLD Count' ) > 0 THEN EventUnweightedVLDCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Unweighted VLD Event Rate' ) > 0 THEN UnweightedVLDEventRate = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Total Weighted VLD Count' ) > 0 THEN TotalWeightedVLDCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Non-Event Weighted VLD Count' ) > 0 THEN NonEventWeightedVLDCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Event Weighted VLD Count' ) > 0 THEN EventWeightedVLDCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Weighted VLD Event Rate' ) > 0 THEN WeightedVLDEventRate = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Total Unweighted TOT Count' ) > 0 THEN TotalUnweightedTOTCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Non-Event Unweighted TOT Count' ) > 0 THEN NonEventUnweightedTOTCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Event Unweighted TOT Count' ) > 0 THEN EventUnweightedTOTCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Unweighted TOT Event Rate' ) > 0 THEN UnweightedTOTEventRate = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Total Weighted TOT Count' ) > 0 THEN TotalWeightedTOTCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Non-Event Weighted TOT Count' ) > 0 THEN NonEventWeightedTOTCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Event Weighted TOT Count' ) > 0 THEN EventWeightedTOTCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Weighted TOT Event Rate' ) > 0 THEN WeightedTOTEventRate = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Development KS' ) > 0 THEN DevelopmentKS = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Development IVAL' ) > 0 THEN DevelopmentIVAL = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Validation KS' ) > 0 THEN ValidationKS = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Validation IVAL' ) > 0 THEN ValidationIVAL = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Total KS' ) > 0 THEN TotalKS = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Total IVAL' ) > 0 THEN TotalIVAL = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Development Reversal Count' ) > 0 THEN DevelopmentReversalCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Development Alignment Alert Count' ) > 0 THEN DevelopmentAlignmentAlertCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Validation Reversal Count' ) > 0 THEN ValidationReversalCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Validation Alignment Alert Count' ) > 0 THEN ValidationAlignmentAlertCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Total Reversal Count' ) > 0 THEN TotalReversalCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'Total Alignment Alert Count' ) > 0 THEN TotalAlignmentAlertCount = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'iteration   ' ) > 0 THEN iteration = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'rootdir     ' ) > 0 THEN rootdir = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'datadir     ' ) > 0 THEN datadir = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'dset        ' ) > 0 THEN dset = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'eventval    ' ) > 0 THEN eventval = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'noneventval ' ) > 0 THEN noneventval = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'perfvar     ' ) > 0 THEN perfvar = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'wghtvar     ' ) > 0 THEN wghtvar = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'tpvvar      ' ) > 0 THEN tpvvar = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'lossvar     ' ) > 0 THEN lossvar = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'varforced   ' ) > 0 THEN varforced = scan(line,2,':');
ELSE IF INDEX(LINE,'sampling    ' ) > 0 THEN sampling = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'sampprop    ' ) > 0 THEN sampprop = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'resample    ' ) > 0 THEN resample = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'selection   ' ) > 0 THEN selection = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'pentry      ' ) > 0 THEN pentry = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'pexit       ' ) > 0 THEN pexit = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'intercept   ' ) > 0 THEN intercept = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'linkfunc    ' ) > 0 THEN linkfunc = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'maxstep     ' ) > 0 THEN maxstep = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'maxiter     ' ) > 0 THEN maxiter = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'perfgrp     ' ) > 0 THEN perfgrp = compress(scan(line,2,':'));
ELSE IF INDEX(LINE,'modelsub    ' ) > 0 THEN modelsub = compress(scan(line,2,':'));


retain _all_;
drop line;
if last;

RUN;

proc datasets LIB=WORK;
	modify outfile;
	format 	length 
SamplingMethod    $25.
SamplingSeed    $25.
MaxVIF    $8.
MaxCorrCoeff    $12.
NumberofVariables    $5.
TotalUnweightedBLDCount    $25.
NonEventUnweightedBLDCount    $25.
EventUnweightedBLDCount    $25.
UnweightedBLDEventRate    $10.
TotalWeightedBLDCount    $25.
NonEventWeightedBLDCount    $25.
EventWeightedBLDCount    $25.
WeightedBLDEventRate    $10.
TotalUnweightedVLDCount    $25.
NonEventUnweightedVLDCount    $25.
EventUnweightedVLDCount    $25.
UnweightedVLDEventRate    $10.
TotalWeightedVLDCount    $25.
NonEventWeightedVLDCount    $25.
EventWeightedVLDCount    $25.
WeightedVLDEventRate    $10.
TotalUnweightedTOTCount    $25.
NonEventUnweightedTOTCount    $25.
EventUnweightedTOTCount    $25.
UnweightedTOTEventRate    $10.
TotalWeightedTOTCount    $25.
NonEventWeightedTOTCount    $25.
EventWeightedTOTCount    $25.
WeightedTOTEventRate    $10.
DevelopmentKS    $10.
DevelopmentIVAL    $10.
ValidationKS    $10.
ValidationIVAL    $10.
TotalKS    $10.
TotalIVAL    $10.
DevelopmentReversalCount    $2.
DevelopmentAlignmentAlertCount    $2.
ValidationReversalCount    $2.
ValidationAlignmentAlertCount    $2.
TotalReversalCount    $2.
TotalAlignmentAlertCount    $2.
iteration    $2.
rootdir    $100.
datadir    $100.
dset    $50.
eventval    $5.
noneventval    $5.
perfvar    $32.
wghtvar    $32.
tpvvar    $32.
lossvar    $32.
varforced    $100.
sampling    $20.
sampprop    $8.
resample    $8.
selection    $10.
pentry    $10.
pexit    $10.
intercept    $10.
linkfunc    $10.
maxstep    $5.
maxiter    $5.
perfgrp    $5.
modelsub    $5.
;
RUN;




 PROC APPEND BASE=&outset DATA=outfile FORCE;
RUN;

%MEND read_summary_stats_file;
