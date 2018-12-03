options compress=yes obs=max ls=max ps=max pageno=1 errors=10 nocenter NODATE NONOTES nonumber; * symbolgen mlogic mprint;
%put NOTE: PID of this session is &sysjobid..;

libname raw  '/ebaysr/projects/arus/data';

%include '/ebaysr/MACROS/MACROS_OLD_BACKUP/score_dist_fmt.sas';


PROC FORMAT;
PICTURE PCTPIC 0-high='009.999%';
PICTURE BPSPIC low-<0.1 = '9.9'(mult=1000)
               0.1-<  1 = '99' (mult=100)
				       1 -< 10 ='999'  (mult=100)
               10 - high ='9,999' (mult=100);

RUN;



%macro scoredist(datin = ,score_code= ,numbin= );

title "&datin.";

data seg;
set &datin. ;
%include "&score_code.";
weighted_cnt = 1;
wgt=1;
run;

%scrfmt(datin = seg, perfvar = flag_perf_60d, bad = 1,wgt = samplingweight,scrvar = score ,bins = &numbin.) ;

title "KS = &ks     IV = &IV"; 

proc tabulate data = seg missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;  
      
	  class  score seg_flag seg_cd flag_mob CNT_HIST_TXN_30D/style= [background = light bule];                                                                                                                                                                  
      var    perf_amt_esc_claim_60d perf_net_loss_60d perf_gmv_60d perf_cnt_txn_60d hist_gmv_30d flag_perf_60d perf_gross_loss_60 weighted_cnt
	         /s=[background=light blue];                                   
    /*** performance summary ***/                       
    table   (score =""  all =[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			 
			  weighted_cnt = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<weighted_cnt> = '% of total weighted' )
              flag_perf_60d = 'Unit Event'*(sum='bads #'*f=comma8.0 colpctsum<flag_perf_60d> = 'bad % of Total Bad' mean='Interval bad Rate'*f=percent8.2*[s=[background = yellow]])			 
              perf_cnt_txn_60d = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              perf_gmv_60d  = 'Perf GMV 60d'*(sum = 'Total Amount'*f=comma18.0 colpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0)
			  perf_net_loss_60d  = 'Perf Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<perf_net_loss_60d> ='% of net loss' rowpctsum<perf_gmv_60d>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) 
			  perf_amt_esc_claim_60d = 'PERF CLAIM AMT 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_amt_esc_claim_60d >='% of esc claim' rowpctsum<perf_gmv_60d> ='% of GMV' mean*f=comma8.0) 
			  perf_gross_loss_60 = 'Perf Gross Loss 60d' * (sum = 'Total Num'*f=comma10.0 colpctsum<perf_gross_loss_60>='% of esc claim' rowpctsum<perf_gmv_60d> ='BPS'*f=bpspic. /*mean*f=comma8.0 */) 
			 
	        )     /Box="&datin. Score" row=float RTS=25 /*misstext = '0'*/;  
			
weight samplingweight;    
format score binfmt. ;	
run;

/*
proc means data = seg n nmiss mean min p1 p5 p25 p50 p75 p90 p95 p99 max sum;
weight samplingweight;
run;
*/

%mend;

ods html file = 'usar_score_dist_pct.xls';
*%scoredist(datin = raw.seg1_gt25_gt12, score_code = ./SEG_MODEL/Model_seg1_ver_7.sas, numbin = 100);
*%scoredist(datin = raw.seg2_gt25_le12, score_code = ./SEG_MODEL/Model_seg2_ver_13.sas, numbin = 100);
*%scoredist(datin = raw.seg2_gt25_le12, score_code = ./SEG_MODEL/Model_seg2_ver_36.sas, numbin = 100);
%scoredist(datin = raw.seg3_le25_gt12, score_code = ./SEG_MODEL/Model_seg3_ver_2.sas, numbin = 10);
%scoredist(datin = raw.seg3_le25_gt12, score_code = ./SEG_MODEL/Model_seg3_ver_4.sas, numbin = 10);
*%scoredist(datin = raw.seg4_le25_le12, score_code = ./SEG_MODEL/Model_seg4_ver_14.sas, numbin = 100);
*%scoredist(datin = raw.seg5_le1k, score_code = ./SEG_MODEL/Model_seg5_ver_2.sas, numbin = 100);
ods html close;
