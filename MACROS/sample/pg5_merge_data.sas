
options compress=yes obs=max ls=max ps=max pageno=1 errors=10 nocenter; * symbolgen mlogic mprint;
%put NOTE: PID of this session is &sysjobid..;


filename pwfile "~/tera_pwf.txt";

data _null_;
  infile pwfile obs=1 length=l;
  input @;
  input @1 line $varying1024.  l;
  call symput('tdbpass',substr(line,1,l));
  
run;


libname scratch teradata user=&sysuserid PASSWORD="&tdbpass" TDPID="mz2" DATABASE=access_views	OVERRIDE_RESP_LEN=YES DBCOMMIT=0;


libname raw  '/ebaysr/projects/arus/data';

/*** create day since ***/
/*
proc sql;
create table raw.max_ms as  
select 
a.*
,max(gmv) as Max_gmv_1
,max(asp) as Max_asp_1
,max(cnt_txn) as max_txn_1
from raw.ebay_usar_all_daily  a
group by slr_id,run_date
order by slr_id, run_date,trans_dt descending 
;
quit;

proc print data = raw.max_ms(obs=1000);
where  slr_id = 6364 ;
run;

data raw.daysince;
set raw.max_ms;
by slr_id run_date descending trans_dt;
retain ds_max_asp ds_max_gmv ds_max_txn 0;
if first.run_date then do;
ds_max_asp=0;
ds_max_gmv=0;
ds_max_txn=0;
end;
if max_asp_1 = asp then ds_max_asp =  datepart(run_date) - trans_dt;  
if max_gmv_1 = gmv then ds_max_gmv =  datepart(run_date) - trans_dt;  
if max_txn_1 = cnt_txn then ds_max_txn =  datepart(run_date) - trans_dt;  
if last.run_date;
run;
*/


data EBAY_USAR_RISKCAT;
set 
RAW.EBAY_USAR_RISKCAT_0_RAW360 
RAW.EBAY_USAR_RISKCAT_1_RAW360; 
run;  

proc sql;
create table raw.ebay_usar_data_raw as
select 
a.slr_id
,a.run_date
,b.*
,c.*
,d.*
,e.*
,f.*
,g.*
,h.*
,i.*
,j.*
,k.*
,l.*
,m.*
,n.max_daily_gmv_360
,n.max_daily_txn_360
,n.max_asp_360
,o.*
,q.ds_max_asp
,q.ds_max_gmv
,q.ds_max_txn
,r.*
,cnt_rev_tot_msg_1d + cnt_snd_tot_msg_1d as cnt_tot_msg_1d
,cnt_rev_tot_msg_3d + cnt_snd_tot_msg_3d as cnt_tot_msg_3d
,cnt_rev_tot_msg_7d + cnt_snd_tot_msg_7d as cnt_tot_msg_7d
,cnt_rev_tot_msg_30d + cnt_snd_tot_msg_30d as cnt_tot_msg_30d
,cnt_rev_tot_msg_60d + cnt_snd_tot_msg_60d as cnt_tot_msg_60d
,cnt_rev_tot_msg_90d + cnt_snd_tot_msg_90d as cnt_tot_msg_90d
,cnt_rev_tot_msg_180d + cnt_snd_tot_msg_180d as cnt_tot_msg_180d
,cnt_rev_tot_msg_360d + cnt_snd_tot_msg_360d as cnt_tot_msg_360d

,cnt_rev_neg_msg_1d   + cnt_snd_neg_msg_1d   as cnt_tot_neg_msg_1d
,cnt_rev_neg_msg_3d   + cnt_snd_neg_msg_3d   as cnt_tot_neg_msg_3d
,cnt_rev_neg_msg_7d   + cnt_snd_neg_msg_7d   as cnt_tot_neg_msg_7d
,cnt_rev_neg_msg_30d  + cnt_snd_neg_msg_30d  as cnt_tot_neg_msg_30d
,cnt_rev_neg_msg_60d  + cnt_snd_neg_msg_60d  as cnt_tot_neg_msg_60d
,cnt_rev_neg_msg_90d  + cnt_snd_neg_msg_90d  as cnt_tot_neg_msg_90d
,cnt_rev_neg_msg_180d + cnt_snd_neg_msg_180d as cnt_tot_neg_msg_180d
,cnt_rev_neg_msg_360d + cnt_snd_neg_msg_360d as cnt_tot_neg_msg_360d


from raw.usar_modeling_drv a
left join RAW.EBAY_USAR_TRAN_RAW30          b  on a.slr_id = b.slr_id and a.run_date = b.run_date        
left join RAW.EBAY_USAR_CLAIM_RAW30         c  on a.slr_id = c.slr_id and a.run_date = c.run_date
left join RAW.EBAY_USAR_LSTG_RAW30          d  on a.slr_id = d.slr_id and a.run_date = d.run_date
left join RAW.EBAY_USAR_MSG_REV_RAW30       e  on a.slr_id = e.slr_id and a.run_date = e.run_date
left join RAW.EBAY_USAR_MSG_SND_RAW30       f  on a.slr_id = f.slr_id and a.run_date = f.run_date
left join RAW.EBAY_USAR_TRAN_RAW360         g  on a.slr_id = g.slr_id and a.run_date = g.run_date
left join RAW.EBAY_USAR_CLAIM_RAW360        h  on a.slr_id = h.slr_id and a.run_date = h.run_date
left join RAW.EBAY_USAR_LSTG_RAW360         i  on a.slr_id = i.slr_id and a.run_date = i.run_date
left join RAW.EBAY_USAR_MSG_REV_RAW360      j  on a.slr_id = j.slr_id and a.run_date = j.run_date
left join RAW.EBAY_USAR_MSG_SND_RAW360      k  on a.slr_id = k.slr_id and a.run_date = k.run_date
left join RAW.EBAY_USAR_HIST_STATUS_RAW360  l  on a.slr_id = l.slr_id and a.run_date = l.run_date
left join RAW.EBAY_USAR_BYR_RAW360          m  on a.slr_id = m.slr_id and a.run_date = m.run_date
left join RAW.EBAY_USAR_MAX                 n  on a.slr_id = n.slr_id and a.run_date = n.run_date
left join EBAY_USAR_RISKCAT                 o  on a.slr_id = o.slr_id and a.run_date = o.run_date
left join RAW.daysince                      q  on a.slr_id = q.slr_id and a.run_date = q.run_date
left join raw.ebay_usar_issue               r  on a.slr_id = r.slr_id and a.run_date = r.run_date 
;
quit;


option nolabel;

%include '~/my_macro.sas';

%check_mean(datin = raw.ebay_usar_data_raw       );



/*** create daily raw variables : ***/

proc contents data =  raw.ebay_usar_data_raw out = _name(keep = name) noprint;
run;

data new;
set _name;
len = anydigit(name)-2;
varname = substr(name,1,len);
run;

proc print data = new;
run;

proc sql;
select upcase(varname),count(*) from new
group by 1
order by 1
;
quit;

proc sort data = new nodupkey;
by varname;
run;

proc print data = new;
run;



endsas;



proc contents data = raw.usar_modeling_drv;
run;










%macro checkdat(dataset = );
proc contents data = &dataset.;
run;

proc sort data = &dataset. out = test nodupkey;
by slr_id run_date;
run;
%mend;

*%checkdat(dataset = RAW.EBAY_USAR_TRAN_RAW30         );
*%checkdat(dataset = RAW.EBAY_USAR_CLAIM_RAW30        );
*%checkdat(dataset = RAW.EBAY_USAR_LSTG_RAW30         );
*%checkdat(dataset = RAW.EBAY_USAR_MSG_REV_RAW30      );
*%checkdat(dataset = RAW.EBAY_USAR_MSG_SND_RAW30      );
*%checkdat(dataset = RAW.EBAY_USAR_TRAN_RAW360        );
*%checkdat(dataset = RAW.EBAY_USAR_CLAIM_RAW360       );
*%checkdat(dataset = RAW.EBAY_USAR_LSTG_RAW360        );
*%checkdat(dataset = RAW.EBAY_USAR_MSG_REV_RAW360     );
*%checkdat(dataset = RAW.EBAY_USAR_MSG_SND_RAW360     );
*%checkdat(dataset = RAW.EBAY_USAR_HIST_STATUS_RAW360 );
*%checkdat(dataset = RAW.EBAY_USAR_BYR_RAW360         );
*%checkdat(dataset = RAW.EBAY_USAR_MAX                );
*%checkdat(dataset = RAW.EBAY_USAR_RISKCAT_RAW360     );
*%checkdat(dataset = RAW.EBAY_USAR_RISKCAT_1_RAW360   );


/** result: data_mean.txt **/
option nolabel;

%include '~/my_macro.sas';

%check_mean(datin = RAW.EBAY_USAR_TRAN_RAW30         );
%check_mean(datin = RAW.EBAY_USAR_CLAIM_RAW30        );
%check_mean(datin = RAW.EBAY_USAR_LSTG_RAW30         );
%check_mean(datin = RAW.EBAY_USAR_MSG_REV_RAW30      );
%check_mean(datin = RAW.EBAY_USAR_MSG_SND_RAW30      );
%check_mean(datin = RAW.EBAY_USAR_TRAN_RAW360        );
%check_mean(datin = RAW.EBAY_USAR_CLAIM_RAW360       );
%check_mean(datin = RAW.EBAY_USAR_LSTG_RAW360        );
%check_mean(datin = RAW.EBAY_USAR_MSG_REV_RAW360     );
%check_mean(datin = RAW.EBAY_USAR_MSG_SND_RAW360     );
%check_mean(datin = RAW.EBAY_USAR_HIST_STATUS_RAW360 );
%check_mean(datin = RAW.EBAY_USAR_BYR_RAW360         );
%check_mean(datin = RAW.EBAY_USAR_MAX                );
%check_mean(datin = RAW.EBAY_USAR_RISKCAT_RAW360     );
%check_mean(datin = RAW.EBAY_USAR_RISKCAT_1_RAW360   );

endsas;




endsas;


RAW.EBAY_USAR_TRAN_RAW30         90
RAW.EBAY_USAR_CLAIM_RAW30        70
RAW.EBAY_USAR_LSTG_RAW30         42
RAW.EBAY_USAR_MSG_REV_RAW30      14
RAW.EBAY_USAR_MSG_SND_RAW30      14
RAW.EBAY_USAR_TRAN_RAW360        90
RAW.EBAY_USAR_CLAIM_RAW360       70 
RAW.EBAY_USAR_LSTG_RAW360        42
RAW.EBAY_USAR_MSG_REV_RAW360     14
RAW.EBAY_USAR_MSG_SND_RAW360     14
RAW.EBAY_USAR_HIST_STATUS_RAW360 10
RAW.EBAY_USAR_BYR_RAW360         18
RAW.EBAY_USAR_MAX                   5
RAW.EBAY_USAR_RISKCAT_RAW360         86         
RAW.EBAY_USAR_RISKCAT_1_RAW360       86 /** no 360 **/ 

raw.daysince   5
res            9
























