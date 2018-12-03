
options compress=yes obs=max ls=max ps=max pageno=1 errors=10 nocenter; * symbolgen mlogic mprint;
%put NOTE: PID of this session is &sysjobid..;


filename pwfile "~/tera_pwf.txt";

data _null_;
  infile pwfile obs=1 length=l;
  input @;
  input @1 line $varying1024.  l;
  call symput('tdbpass',substr(line,1,l));
  
run;

libname scratch teradata user=&sysuserid PASSWORD="&tdbpass" TDPID="hopper" connection=global;
libname raw '../data';

/** create volatile table **/

proc sql;
   connect to teradata(user=&sysuserid PASSWORD="&tdbpass" TDPID="hopper" connection=global);
   execute (CREATE VOLATILE TABLE temp2 (val INT) 
            ON COMMIT PRESERVE ROWS) by teradata;
   execute (COMMIT WORK) by teradata;
quit;


proc sql;
   connect to teradata(user=&sysuserid PASSWORD="&tdbpass" TDPID="hopper" connection=global);
   execute (INSERT INTO temp2 VALUES(8)) by teradata;
   execute (COMMIT WORK) by teradata;
quit;


proc sql;
connect to teradata (user=&sysuserid PASSWORD="&tdbpass" TDPID="hopper" connection=global); 
select * from connection to teradata 
( select * from temp2);
quit;


proc sql;
connect to teradata (user=&sysuserid PASSWORD="&tdbpass" TDPID="hopper" connection=global); 
create table sas_temp as select * from connection to teradata 
( 
select * from temp2
);
quit;


proc print data=sas_temp;
run;



proc sql;
   connect to teradata(user=&sysuserid PASSWORD="&tdbpass" TDPID="hopper" connection=global);
   execute (create VOLATILE TABLE temp3 as (sel * from temp2 ) with data ) by teradata;
   execute (COMMIT WORK) by teradata;
quit;

proc print data = scratch.temp3;
run;

endsas;



proc sql;
   connect to teradata(server=&server authdomain=&authdomain connection=global);
   execute (CREATE VOLATILE TABLE temp2 (col1 INT) 
            UNIQUE PRIMARY INDEX (col1)
            ON COMMIT PRESERVE ROWS) by teradata;
   execute (COMMIT WORK) by teradata;
quit;


data scratch.ebay_usar_samp_drv(MultiLoad=yes dbcreate_table_opts='primary index(slr_id,run_date)');
 set raw.usar_modeling_drv;
 keep slr_id run_date run_dt;
run;

sftp://localhost:5010/ebaysr/projects/arus/code/analysis/check_volatile.sas
sftp://localhost:5010/ebaysr/projects/arus/code/analysis/check_volatile.sas