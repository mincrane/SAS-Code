
options compress=yes obs=max ls=max ps=max pageno=1 errors=10 nocenter; * symbolgen mlogic mprint;


%include '/ebaysr/MACROS/MACROS_OLD_BACKUP/coarse_all.sas' ; 


libname raw  '/ebaysr/projects/arus/data';
libname dat '.';

data new;
set raw.seg1_gt25_gt12;

drop
slr_id
run_date
run_dt;


%include '../drop_list_ks_seg1.sas';
run;

%coarse_var(datin = new, perfvar =flag_perf_60d  ,bad_indg = 1, weight = samplingweight,bin = 10, output_file = seg1_coarse.txt);

endsas;

/**** sample code: single variable coarse ***/
 
%coarse_bin(datin = new, perfvar =perf_boc_d60  ,bad_indg = 1, varname = SUM_a_slr_pyt_6M ,weight = SamplingWeight,bin = 10);
%coarse_bin(datin = new, perfvar =perf_boc_d60  ,bad_indg = 1, varname = rat_CNT_HIST_GMB_6m ,weight = SamplingWeight,bin = 10);


raw.seg2_gt25_le12;
raw.seg3_le25_gt12;
raw.seg4_le25_le12;
raw.seg5_LE1k;