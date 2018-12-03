
options compress=yes obs=max ls=max ps=max pageno=1 errors=10 nocenter; * symbolgen mlogic mprint;


%include '/ebaysr/MACROS/MACROS_OLD_BACKUP/ebsr_univariate_macro_v1.sas';


libname raw  '/ebaysr/projects/arus/data';


data new;
set raw.seg1_gt25_gt12;

drop
slr_id
run_date
run_dt;

run;

%univ(datin = new, perfvar = flag_perf_60d ,bad = 1 ,wgt = samplingweight, exclout = usar_seg1_univ,datout = univ_seg1);


endsas;

raw.seg2_gt25_le12;
raw.seg3_le25_gt12;
raw.seg4_le25_le12;
raw.seg5_LE1k;