
options compress=yes ls=max ps=max pageno=1 errors=10 nocenter  /*symbolgen mlogic mprint obs=10000 */; 
%put NOTE: PID of this session is &sysjobid..;

libname raw  '/ebaysr/projects/arus/data';


data raw.mb_seg1_data;
set raw.b2c_data;
where flag_pop_excl_final = 0;
%include 'keep_list_b2c.sas';
run;

proc freq data = raw.mb_b2c_data;
table perf_eg_bad;
run;

endsas;
raw.seg1_gt25_gt12
raw.seg2_gt25_le12
raw.seg3_le25_gt12
raw.seg4_le25_le12
raw.seg5_LE1k;
