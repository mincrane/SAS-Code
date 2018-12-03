data new;
infile datalines missover dlm = '2009'x;
input segment : $4. variable : $32. order impact :$5.;
signs = cats(order,impact);
datalines;
seg5	asp_30D	1	(+)
seg5	orig_mob	2	(-)
seg5	rat_CNT_ENDED_LSTNG_180D	3	(-)
seg5	rat_CNT_OPEN_INR_CLM_360D	4	(+)
seg5	chg_c_hasp_rate_30D_180D	5	(+)
seg5	rat_AMT_OPEN_SNAD_CLM_2_30D	6	(+)
seg5	chg_neg_fb_rate_30D_360D	7	(+)
seg5	rat_AMT_HIGH_RISK_DOR_30D_180D	8	(+)
seg5	cnt_rev_asq_msg_7d	9	(+)
seg5	AMT_NEW_LSTNG_USD_7D	10	(+)
seg3	rat_HIST_GMV_30D_360D	1	(+)
seg3	rat_CNT_OPEN_SNAD_CLM_7D_30D	2	(+)
seg3	rat_AMT_OPEN_INR_CLM_90D	3	(+)
seg3	CNT_SLR_PSTV_FDBK_30D	4	(-)
seg3	rat_CNT_OPEN_clm_360D	5	(+)
seg3	orig_mob	6	(-)
seg3	rat_CNT_REV_TOT_MSG_30D	7	(+)
seg3	rat_CNT_HIGH_RISK_DOR_1D_90D	8	(+)
seg4	rat_CNT_OPEN_INR_CLM_360D	1	(+)
seg4	rat_CNT_NEW_LSTNG_7D_180D	2	(+)
seg4	rat_AMT_OPEN_SNAD_CLM_7D_60D	3	(+)
seg4	rat_CNT_REV_TOT_MSG_7D	4	(+)
seg4	rat_CNT_SLR_PSTV_FDBK_360D	5	(-)
seg4	HIST_GMV_180D	6	(-)
seg4	CNT_HASP_gt2_TXN_30D	7	(+)
seg4	rat_AMT_OPEN_clm_180D	8	(+)
seg2	rat_AMT_NEW_LSTNG_30D_360D	1	(+)
seg2	rat_CNT_REV_TOT_MSG_7D	2	(+)
seg2	rat_CNT_OPEN_INR_CLM_180D	3	(+)
seg2	rat_CNT_OPEN_SNAD_CLM_7D_30D	4	(+)
seg2	rat_CNT_SLR_PSTV_FDBK_360D	5	(-)
seg2	rat_AMT_HIGH_RISK_C2C_7D_180D	6	(+)
seg2	rat_AMT_OPEN_INR_CLM_30D	7	(+)
seg2	rat_AMT_NEW_LSTNG_7D_180D	8	(+)
seg2	rat_asp_1d_max	9	(+-+)
seg2	rat_CNT_SLR_TOT_FDBK_3D	10	(+)
seg1	CNT_SLR_PSTV_FDBK_360D	1	(-)
seg1	rat_AMT_OPEN_SNAD_CLM_360D	2	(+)
seg1	rat_CNT_OPEN_INR_CLM_180D	3	(+)
seg1	rat_gmv_1d_max	4	(+-+)
seg1	cnt_cps_open_inr_clm_60D	5	(+)
seg1	rat_CNT_SLR_PSTV_FDBK_180D	6	(-)
seg1	rat_AMT_OPEN_clm_30D	7	(+)
seg1	rat_AMT_HASP_GT2_GMV_30D_360D	8	(+)
seg1	rat_CNT_REV_TOT_MSG_30D	9	(+)
seg1	orig_mob	10	(+)
seg1	rat_AMT_NEW_FP_LSTNG_30D	11	(+)
seg1	rat_AMT_HIGH_RISK_C2C_7D_180D	12	(+)
;
run;
proc print data =new;
run;

proc sort data = new;
by variable;
run;

proc transpose data = new out = new1 name = impact;
by variable; 
id segment;
var signs;
run;

proc print data = new1;
run;
endsas;
(keep = variable segment signs)
