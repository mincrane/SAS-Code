
/*** cluster analysis combining with KS IV *********/



%macro cluster_var(datset=,datout= ,Mclusnum = );
	
	

proc contents data=&datset out=_cont(keep=name type) noprint;
run;

proc sql noprint;
	select name into : allvar separated by " " 
	from _cont
	where type=1;
quit;

proc stdize data=modeling reponly missing= 0 out=imputed;
var &allvar;
run;


ods listing close;
ods output clusterquality=summary rsquare=clusters;

proc varclus data=imputed maxclusters=&MclusNum percent=75 short hi;
var &allvar;
run;
ods listing;

data _null_;
set summary;
call symput('nvar',compress(NumberOfClusters));
run;

proc print data=clusters noobs;
where NumberOfClusters=&nvar;
var Cluster Variable RSquareRatio /*VariableLabel*/;
run;

data clusters;
	 set clusters;
	 where NumberOFclusters=&nvar;
run;


data new;
	set clusters(keep=variable rsquareratio cluster);
	retain clusNum;
	if missing(cluster)^=1 then clusNum= scan(cluster,2);
run;

proc sort data=new;
	by clusNum rsquareratio;
run;

data &datout;
	set new;
	by clusNum rsquareratio;
	if first.clusNum then order_rsq=0;
		order_rsq +1;
run;

%mend;




