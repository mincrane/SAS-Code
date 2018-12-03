
options compress=yes ls=max ps=max pageno=1 errors=10 nocenter  /*symbolgen mlogic mprint obs=10000 */; 
%put NOTE: PID of this session is &sysjobid..;



libname raw  '/ebaysr/projects/arus/data';
libname dat '.';


libname curdat ".";
libname univ '/ebaysr/projects/arus/model/SEG1/univariate/';



proc freq data = raw.seg2_gt25_le12;
table flag_perf_60d;
run;



%macro cluster_macro(datain = ,perf= ,wghtvar = ,univ_datain =  ,Numofclus = ,drop_list= ,segnum = );


data univ;
set &univ_datain;
rename iv = ival;
run;


/** create drop list based on ks<5 iv<0.01 ***/

proc sql;
	select varname into : dropVar separated by " " 
	from univ
	where ks<5 or IVAL < 0.01 or compress(varname) in ("&perf","&wghtvar");
quit;


data modeling;
	set &datain;
	where &perf in (0,1);
	drop &dropvar;
	%include "&drop_list.";
run;


%include "/home/hemin/CODE/WRKCODE/cluster.sas";

%cluster_var(datset=modeling,datout=curdat.cluster ,Mclusnum = &numofclus.);


proc print data=curdat.cluster (obs=20);
run;

proc sort data=univ out=ksiv;
by varname;
run;

proc sort data=curdat.cluster out=cluster;
by variable;
run;

data new;
merge cluster(in=a rename=(variable=varname)) ksiv(in=b keep=varname ks ival);
by varname;
if b;
run;

proc sort data=new out=devdat;
	by clusNum descending ks;
run;

data ks_order;
	set devdat;
	by clusNum descending ks;
	if first.clusNum then order_ks=0;
		order_ks +1;
run;

proc sort data=ks_order;
	by clusNum descending ival;
run;

data iv_order;
	set ks_order;
	by clusNum descending ival;
	if first.clusNum then order_iv=0;
		order_iv +1;
run;

data curdat.candVar;
 set iv_order;
 if 0<order_rsq<=2 or order_ks <=2 or 0<order_iv <=2 then flag_in=1;
 else flag_in=0;
run;

proc print data=curdat.candVar (obs=20);
run;

ods listing close;
ods csv file = "canVar_seg&segnum..csv";
proc print data=curdat.candVar noobs;
run;
ods html close;
ods listing;

%mend;


*%cluster_macro(datain =raw.seg1_gt25_gt12  ,perf=flag_perf_60d  ,wghtvar =  samplingweight ,univ_datain = univ.seg1_numeric ,Numofclus = 70 ,drop_list= drop_list.txt       ,segnum = 1);
*%cluster_macro(datain =raw.seg2_gt25_le12  ,perf=flag_perf_60d  ,wghtvar =  samplingweight ,univ_datain = univ.na_numeric   ,Numofclus = 70 ,drop_list= drop_list.txt       ,segnum = 2);
*%cluster_macro(datain =raw.seg3_le25_gt12  ,perf=flag_perf_60d  ,wghtvar =  samplingweight ,univ_datain = univ.emea_numeric ,Numofclus = 70 ,drop_list= drop_list.txt       ,segnum = 3);
*%cluster_macro(datain =raw.seg4_le25_le12  ,perf=flag_perf_60d  ,wghtvar =  samplingweight ,univ_datain = univ.univ_b2c_num ,Numofclus = 70 ,drop_list= drop_list_ks_b2c.sas,segnum = 4);
*%cluster_macro(datain =raw.seg5_LE1k       ,perf=flag_perf_60d  ,wghtvar =  samplingweight ,univ_datain = univ.univ_b2c_num ,Numofclus = 70 ,drop_list= drop_list_ks_b2c.sas,segnum = 5);

proc print data = curdat.canvar;
run;





/*
raw.seg1_gt25_gt12
raw.seg2_gt25_le12
raw.seg3_le25_gt12;
raw.seg4_le25_le12;
raw.seg5_LE1k;
*/








