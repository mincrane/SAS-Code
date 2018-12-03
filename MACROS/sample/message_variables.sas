
options compress=yes obs=max ls=max ps=max pageno=1 errors=10 nocenter symbolgen mlogic mprint;
%put NOTE: PID of this session is &sysjobid..;


filename pwfile "~/tera_pwf.txt";

data _null_;
  infile pwfile obs=1 length=l;
  input @;
  input @1 line $varying1024.  l;
  call symput('tdbpass',substr(line,1,l));
  
run;


libname scratch teradata user=&sysuserid PASSWORD="&tdbpass" TDPID="hopper" DATABASE=p_bichang_t  OVERRIDE_RESP_LEN=YES DBCOMMIT=0;

libname raw  '/ebaysr/projects/arus/data';

/*
data raw.message_var_bi_1;
set scratch.arus_samp_senti_vars;
run;

data raw.message_var_bi_2;
set scratch.arus_samp_senti_vars_cot;
run;
*/

/*
proc sql;
create table raw.message_all as
select
a.slr_id
,a.run_Date
,a.flag_perf_60d
,seg_flag
,a.samplingweight
,a.chg_neg_msg_rate_1D_30D          
,a.chg_neg_msg_rate_1D_3D           
,a.chg_neg_msg_rate_1D_7D           
,a.chg_neg_msg_rate_1D_90D          
,a.chg_neg_msg_rate_30D_180D        
,a.chg_neg_msg_rate_30D_360D        
,a.chg_neg_msg_rate_30D_60D         
,a.chg_neg_msg_rate_30D_90D         
,a.chg_neg_msg_rate_3D_30D          
,a.chg_neg_msg_rate_3D_90D          
,a.chg_neg_msg_rate_7D_180D         
,a.chg_neg_msg_rate_7D_30D          
,a.chg_neg_msg_rate_7D_60D          
,a.chg_neg_msg_rate_7D_90D          
,a.cnt_rev_asq_msg_180d             
,a.cnt_rev_asq_msg_1d               
,a.cnt_rev_asq_msg_30d              
,a.cnt_rev_asq_msg_360d             
,a.cnt_rev_asq_msg_3d               
,a.cnt_rev_asq_msg_60d              
,a.cnt_rev_asq_msg_7d               
,a.cnt_rev_asq_msg_90d              
,a.cnt_rev_neg_msg_180d             
,a.cnt_rev_neg_msg_1d               
,a.cnt_rev_neg_msg_30d              
,a.cnt_rev_neg_msg_360d             
,a.cnt_rev_neg_msg_3d               
,a.cnt_rev_neg_msg_60d              
,a.cnt_rev_neg_msg_7d               
,a.cnt_rev_neg_msg_90d              
,a.cnt_rev_tot_msg_180d             
,a.cnt_rev_tot_msg_1d               
,a.cnt_rev_tot_msg_30d              
,a.cnt_rev_tot_msg_360d             
,a.cnt_rev_tot_msg_3d               
,a.cnt_rev_tot_msg_60d              
,a.cnt_rev_tot_msg_7d               
,a.cnt_rev_tot_msg_90d              
,a.cnt_snd_neg_msg_180d             
,a.cnt_snd_neg_msg_1d               
,a.cnt_snd_neg_msg_30d              
,a.cnt_snd_neg_msg_360d             
,a.cnt_snd_neg_msg_3d               
,a.cnt_snd_neg_msg_60d              
,a.cnt_snd_neg_msg_7d               
,a.cnt_snd_neg_msg_90d              
,a.cnt_snd_rsp_msg_180d             
,a.cnt_snd_rsp_msg_1d               
,a.cnt_snd_rsp_msg_30d              
,a.cnt_snd_rsp_msg_360d             
,a.cnt_snd_rsp_msg_3d               
,a.cnt_snd_rsp_msg_60d              
,a.cnt_snd_rsp_msg_7d               
,a.cnt_snd_rsp_msg_90d              
,a.cnt_snd_tot_msg_180d             
,a.cnt_snd_tot_msg_1d               
,a.cnt_snd_tot_msg_30d              
,a.cnt_snd_tot_msg_360d             
,a.cnt_snd_tot_msg_3d               
,a.cnt_snd_tot_msg_60d              
,a.cnt_snd_tot_msg_7d               
,a.cnt_snd_tot_msg_90d              
,a.cnt_tot_msg_180d                 
,a.cnt_tot_msg_1d                   
,a.cnt_tot_msg_30d                  
,a.cnt_tot_msg_360d                 
,a.cnt_tot_msg_3d                   
,a.cnt_tot_msg_60d                  
,a.cnt_tot_msg_7d                   
,a.cnt_tot_msg_90d                  
,a.cnt_tot_neg_msg_180d             
,a.cnt_tot_neg_msg_1d               
,a.cnt_tot_neg_msg_30d              
,a.cnt_tot_neg_msg_360d             
,a.cnt_tot_neg_msg_3d               
,a.cnt_tot_neg_msg_60d              
,a.cnt_tot_neg_msg_7d               
,a.cnt_tot_neg_msg_90d              
,a.rat_CNT_REV_ASQ_MSG_180D         
,a.rat_CNT_REV_ASQ_MSG_1D           
,a.rat_CNT_REV_ASQ_MSG_1D_30D       
,a.rat_CNT_REV_ASQ_MSG_1D_3D        
,a.rat_CNT_REV_ASQ_MSG_1D_7D        
,a.rat_CNT_REV_ASQ_MSG_1D_90D       
,a.rat_CNT_REV_ASQ_MSG_2_180D       
,a.rat_CNT_REV_ASQ_MSG_2_1D         
,a.rat_CNT_REV_ASQ_MSG_2_30D        
,a.rat_CNT_REV_ASQ_MSG_2_360D       
,a.rat_CNT_REV_ASQ_MSG_2_3D         
,a.rat_CNT_REV_ASQ_MSG_2_60D        
,a.rat_CNT_REV_ASQ_MSG_2_7D         
,a.rat_CNT_REV_ASQ_MSG_2_90D        
,a.rat_CNT_REV_ASQ_MSG_30D          
,a.rat_CNT_REV_ASQ_MSG_30D_180D     
,a.rat_CNT_REV_ASQ_MSG_30D_360D     
,a.rat_CNT_REV_ASQ_MSG_30D_60D      
,a.rat_CNT_REV_ASQ_MSG_30D_90D      
,a.rat_CNT_REV_ASQ_MSG_360D         
,a.rat_CNT_REV_ASQ_MSG_3D           
,a.rat_CNT_REV_ASQ_MSG_60D          
,a.rat_CNT_REV_ASQ_MSG_7D           
,a.rat_CNT_REV_ASQ_MSG_7D_180D      
,a.rat_CNT_REV_ASQ_MSG_7D_30D       
,a.rat_CNT_REV_ASQ_MSG_7D_60D       
,a.rat_CNT_REV_ASQ_MSG_7D_90D       
,a.rat_CNT_REV_ASQ_MSG_90D          
,a.rat_CNT_REV_NEG_MSG_180D         
,a.rat_CNT_REV_NEG_MSG_1D           
,a.rat_CNT_REV_NEG_MSG_1D_30D       
,a.rat_CNT_REV_NEG_MSG_1D_3D        
,a.rat_CNT_REV_NEG_MSG_1D_7D        
,a.rat_CNT_REV_NEG_MSG_1D_90D       
,a.rat_CNT_REV_NEG_MSG_30D          
,a.rat_CNT_REV_NEG_MSG_30D_180D     
,a.rat_CNT_REV_NEG_MSG_30D_360D     
,a.rat_CNT_REV_NEG_MSG_30D_60D      
,a.rat_CNT_REV_NEG_MSG_30D_90D      
,a.rat_CNT_REV_NEG_MSG_360D         
,a.rat_CNT_REV_NEG_MSG_3D           
,a.rat_CNT_REV_NEG_MSG_60D          
,a.rat_CNT_REV_NEG_MSG_7D           
,a.rat_CNT_REV_NEG_MSG_7D_180D      
,a.rat_CNT_REV_NEG_MSG_7D_30D       
,a.rat_CNT_REV_NEG_MSG_7D_60D       
,a.rat_CNT_REV_NEG_MSG_7D_90D       
,a.rat_CNT_REV_NEG_MSG_90D          
,a.rat_CNT_REV_TOT_MSG_180D         
,a.rat_CNT_REV_TOT_MSG_1D           
,a.rat_CNT_REV_TOT_MSG_1D_30D       
,a.rat_CNT_REV_TOT_MSG_1D_3D        
,a.rat_CNT_REV_TOT_MSG_1D_7D        
,a.rat_CNT_REV_TOT_MSG_1D_90D       
,a.rat_CNT_REV_TOT_MSG_30D          
,a.rat_CNT_REV_TOT_MSG_30D_180D     
,a.rat_CNT_REV_TOT_MSG_30D_360D     
,a.rat_CNT_REV_TOT_MSG_30D_60D      
,a.rat_CNT_REV_TOT_MSG_30D_90D      
,a.rat_CNT_REV_TOT_MSG_360D         
,a.rat_CNT_REV_TOT_MSG_3D           
,a.rat_CNT_REV_TOT_MSG_60D          
,a.rat_CNT_REV_TOT_MSG_7D           
,a.rat_CNT_REV_TOT_MSG_7D_180D      
,a.rat_CNT_REV_TOT_MSG_7D_30D       
,a.rat_CNT_REV_TOT_MSG_7D_60D       
,a.rat_CNT_REV_TOT_MSG_7D_90D       
,a.rat_CNT_REV_TOT_MSG_90D          
,a.rat_CNT_SND_NEG_MSG_180D         
,a.rat_CNT_SND_NEG_MSG_1D           
,a.rat_CNT_SND_NEG_MSG_1D_30D       
,a.rat_CNT_SND_NEG_MSG_1D_3D        
,a.rat_CNT_SND_NEG_MSG_1D_7D        
,a.rat_CNT_SND_NEG_MSG_1D_90D       
,a.rat_CNT_SND_NEG_MSG_30D          
,a.rat_CNT_SND_NEG_MSG_30D_180D     
,a.rat_CNT_SND_NEG_MSG_30D_360D     
,a.rat_CNT_SND_NEG_MSG_30D_60D      
,a.rat_CNT_SND_NEG_MSG_30D_90D      
,a.rat_CNT_SND_NEG_MSG_360D         
,a.rat_CNT_SND_NEG_MSG_3D           
,a.rat_CNT_SND_NEG_MSG_60D          
,a.rat_CNT_SND_NEG_MSG_7D           
,a.rat_CNT_SND_NEG_MSG_7D_180D      
,a.rat_CNT_SND_NEG_MSG_7D_30D       
,a.rat_CNT_SND_NEG_MSG_7D_60D       
,a.rat_CNT_SND_NEG_MSG_7D_90D       
,a.rat_CNT_SND_NEG_MSG_90D          
,a.rat_CNT_SND_RSP_MSG_180D         
,a.rat_CNT_SND_RSP_MSG_1D           
,a.rat_CNT_SND_RSP_MSG_1D_30D       
,a.rat_CNT_SND_RSP_MSG_1D_3D        
,a.rat_CNT_SND_RSP_MSG_1D_7D        
,a.rat_CNT_SND_RSP_MSG_1D_90D       
,a.rat_CNT_SND_RSP_MSG_30D          
,a.rat_CNT_SND_RSP_MSG_30D_180D     
,a.rat_CNT_SND_RSP_MSG_30D_360D     
,a.rat_CNT_SND_RSP_MSG_30D_60D      
,a.rat_CNT_SND_RSP_MSG_30D_90D      
,a.rat_CNT_SND_RSP_MSG_360D         
,a.rat_CNT_SND_RSP_MSG_3D           
,a.rat_CNT_SND_RSP_MSG_60D          
,a.rat_CNT_SND_RSP_MSG_7D           
,a.rat_CNT_SND_RSP_MSG_7D_180D      
,a.rat_CNT_SND_RSP_MSG_7D_30D       
,a.rat_CNT_SND_RSP_MSG_7D_60D       
,a.rat_CNT_SND_RSP_MSG_7D_90D       
,a.rat_CNT_SND_RSP_MSG_90D          
,a.rat_CNT_SND_TOT_MSG_1D_30D       
,a.rat_CNT_SND_TOT_MSG_1D_3D        
,a.rat_CNT_SND_TOT_MSG_1D_7D        
,a.rat_CNT_SND_TOT_MSG_1D_90D       
,a.rat_CNT_SND_TOT_MSG_30D_180D     
,a.rat_CNT_SND_TOT_MSG_30D_360D     
,a.rat_CNT_SND_TOT_MSG_30D_60D      
,a.rat_CNT_SND_TOT_MSG_30D_90D      
,a.rat_CNT_SND_TOT_MSG_7D_180D      
,a.rat_CNT_SND_TOT_MSG_7D_30D       
,a.rat_CNT_SND_TOT_MSG_7D_60D       
,a.rat_CNT_SND_TOT_MSG_7D_90D       
,a.rat_CNT_TOT_MSG_180D             
,a.rat_CNT_TOT_MSG_1D               
,a.rat_CNT_TOT_MSG_1D_30D           
,a.rat_CNT_TOT_MSG_1D_3D            
,a.rat_CNT_TOT_MSG_1D_7D            
,a.rat_CNT_TOT_MSG_1D_90D           
,a.rat_CNT_TOT_MSG_30D              
,a.rat_CNT_TOT_MSG_30D_180D         
,a.rat_CNT_TOT_MSG_30D_360D         
,a.rat_CNT_TOT_MSG_30D_60D          
,a.rat_CNT_TOT_MSG_30D_90D          
,a.rat_CNT_TOT_MSG_360D             
,a.rat_CNT_TOT_MSG_3D               
,a.rat_CNT_TOT_MSG_60D              
,a.rat_CNT_TOT_MSG_7D               
,a.rat_CNT_TOT_MSG_7D_180D          
,a.rat_CNT_TOT_MSG_7D_30D           
,a.rat_CNT_TOT_MSG_7D_60D           
,a.rat_CNT_TOT_MSG_7D_90D           
,a.rat_CNT_TOT_MSG_90D              
,a.rat_CNT_TOT_NEG_MSG_180D         
,a.rat_CNT_TOT_NEG_MSG_1D           
,a.rat_CNT_TOT_NEG_MSG_1D_30D       
,a.rat_CNT_TOT_NEG_MSG_1D_3D        
,a.rat_CNT_TOT_NEG_MSG_1D_7D        
,a.rat_CNT_TOT_NEG_MSG_1D_90D       
,a.rat_CNT_TOT_NEG_MSG_30D          
,a.rat_CNT_TOT_NEG_MSG_30D_180D     
,a.rat_CNT_TOT_NEG_MSG_30D_360D     
,a.rat_CNT_TOT_NEG_MSG_30D_60D      
,a.rat_CNT_TOT_NEG_MSG_30D_90D      
,a.rat_CNT_TOT_NEG_MSG_360D         
,a.rat_CNT_TOT_NEG_MSG_3D           
,a.rat_CNT_TOT_NEG_MSG_60D          
,a.rat_CNT_TOT_NEG_MSG_7D           
,a.rat_CNT_TOT_NEG_MSG_7D_180D      
,a.rat_CNT_TOT_NEG_MSG_7D_30D       
,a.rat_CNT_TOT_NEG_MSG_7D_60D       
,a.rat_CNT_TOT_NEG_MSG_7D_90D       
,a.rat_CNT_TOT_NEG_MSG_90D  
,b.*
,c.*
from         
raw.usar_all_var a
inner join raw.message_var_bi_1 b on a.slr_id = b.slr_id and a.run_date = b.score_ts
inner join raw.message_var_bi_2 c on a.slr_id = c.slr_id and a.run_date = c.score_ts
;
quit;
*/

option nolabel;

%include '~/my_macro.sas';
*%check_mean(datin = raw.message_all);


%include '/ebaysr/MACROS/MACROS_OLD_BACKUP/ebsr_univariate_macro_v1.sas';


*%univ(datin = raw.message_all, perfvar = flag_perf_60d ,bad = 1 ,wgt = samplingweight, exclout = usar_msg_univ,datout = univ_msg);
data seg1 seg2 seg3 seg4 seg5;
set raw.message_all;

if seg_flag = 1 then output seg1;
if seg_flag = 2 then output seg2;
if seg_flag = 3 then output seg3;
if seg_flag = 4 then output seg4;
if seg_flag = 5 then output seg5;
run;

%univ(datin = seg1, perfvar = flag_perf_60d ,bad = 1 ,wgt = samplingweight, exclout = usar_msg_seg1_univ,datout = univ_seg1_msg);
%univ(datin = seg2, perfvar = flag_perf_60d ,bad = 1 ,wgt = samplingweight, exclout = usar_msg_seg2_univ,datout = univ_seg2_msg);
%univ(datin = seg3, perfvar = flag_perf_60d ,bad = 1 ,wgt = samplingweight, exclout = usar_msg_seg3_univ,datout = univ_seg3_msg);
%univ(datin = seg4, perfvar = flag_perf_60d ,bad = 1 ,wgt = samplingweight, exclout = usar_msg_seg4_univ,datout = univ_seg4_msg);
%univ(datin = seg5, perfvar = flag_perf_60d ,bad = 1 ,wgt = samplingweight, exclout = usar_msg_seg5_univ,datout = univ_seg5_msg);




