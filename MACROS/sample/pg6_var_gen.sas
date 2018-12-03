
options compress=yes obs=max ls=max ps=max pageno=1 errors=10 nocenter NODATE NONOTES nonumber; * symbolgen mlogic mprint;
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



/*** data  raw.ebay_usar_var_gen    excel: usar_var_gen.xlsx ***/
data new;
set raw.ebay_usar_var_gen ;
where missing(category)^=1 and category ^= 'del'; 

if varlist = 'CNT_TOT_NEG' then do;
varlist = 'CNT_TOT_NEG_MSG';
desciption = 'CNT_TOT_NEG_MSG';
end;
rename Desciption = description 
       varlist = name;
run;


proc print data = new;
run;




%let daily_var_gen = new;


proc sql;

/*** ext **/    
select '%Ratio('||compress(name)||"_1D,"||compress(denominator)||"_1D,rat_"||compress(varname)||"_1D,100,0.01,label= Ratio "||compress(name)||" to "||compress(denominator)||" 1D)" into :ratio_1d separated by ";"
from &daily_var_gen(rename = (description = varname))
where denominator is not null;

select '%Ratio('||compress(name)||"_3D,"||compress(denominator)||"_3D,rat_"||compress(varname)||"_3D,100,0.01,label= Ratio "||compress(name)||" to "||compress(denominator)||" 3D)" into :ratio_3d separated by ";"
from &daily_var_gen (rename = (description = varname))
where denominator is not null;

select '%Ratio('||compress(name)||"_7D,"||compress(denominator)||"_7D,rat_"||compress(varname)||"_7D,100,0.01,label= Ratio "||compress(name)||" to "||compress(denominator)||" 7D)" into :ratio_7d separated by ";"
from &daily_var_gen(rename = (description = varname))
where denominator is not null;

select '%Ratio('||compress(name)||"_30D,"||compress(denominator)||"_30D,rat_"||compress(varname)||"_30D,100,0.01,label= Ratio "||compress(name)||" to "||compress(denominator)||" 30D)" into :ratio_30d separated by ";"
from &daily_var_gen(rename = (description = varname))
where denominator is not null;

select '%Ratio('||compress(name)||"_60D,"||compress(denominator)||"_60D,rat_"||compress(varname)||"_60D,100,0.01,label= Ratio "||compress(name)||" to "||compress(denominator)||" 60D)" into :ratio_60d separated by ";"
from &daily_var_gen(rename = (description = varname))
where denominator is not null;


select '%Ratio('||compress(name)||"_90D,"||compress(denominator)||"_90D,rat_"||compress(varname)||"_90D,100,0.01,label= Ratio "||compress(name)||" to "||compress(denominator)||" 90D)" into :ratio_90D separated by ";"
from &daily_var_gen (rename = (description = varname))
where denominator is not null;

select '%Ratio('||compress(name)||"_180D,"||compress(denominator)||"_180D,rat_"||compress(varname)||"_180D,100,0.01,label= Ratio "||compress(name)||" to "||compress(denominator)||" 180D)" into :ratio_180D separated by ";"
from &daily_var_gen(rename = (description = varname))
where denominator is not null;

select '%Ratio('||compress(name)||"_360D,"||compress(denominator)||"_360D,rat_"||compress(varname)||"_360D,100,0.01,label= Ratio "||compress(name)||" to "||compress(denominator)||" 360D)" into :ratio_360D separated by ";"
from &daily_var_gen(rename = (description = varname))
where denominator is not null;

/*** denominator 2 **/

select '%Ratio('||compress(name)||"_1D,"||compress(denominator2)||"_1D,rat_"||compress(varname)||"_2_1D,100,0.01,label= Ratio "||compress(name)||" to "||compress(denominator2)||" 1D)" into :ratio_1d separated by ";"
from &daily_var_gen(rename = (description = varname))
where denominator2 is not null;


select '%Ratio('||compress(name)||"_3D,"||compress(denominator2)||"_3D,rat_"||compress(varname)||"_2_3D,100,0.01,label= Ratio "||compress(name)||" to "||compress(denominator2)||" 3D)" into :ratio_3d separated by ";"
from &daily_var_gen (rename = (description = varname))
where denominator2 is not null;

select '%Ratio('||compress(name)||"_7D,"||compress(denominator2)||"_7D,rat_"||compress(varname)||"_2_7D,100,0.01,label= Ratio "||compress(name)||" to "||compress(denominator2)||" 7D)" into :ratio_7d separated by ";"
from &daily_var_gen(rename = (description = varname))
where denominator2 is not null;

select '%Ratio('||compress(name)||"_30D,"||compress(denominator2)||"_30D,rat_"||compress(varname)||"_2_30D,100,0.01,label= Ratio "||compress(name)||" to "||compress(denominator2)||" 30D)" into :ratio_30d separated by ";"
from &daily_var_gen(rename = (description = varname))
where denominator2 is not null;

select '%Ratio('||compress(name)||"_60D,"||compress(denominator2)||"_60D,rat_"||compress(varname)||"_2_60D,100,0.01,label= Ratio "||compress(name)||" to "||compress(denominator2)||" 60D)" into :ratio_60d separated by ";"
from &daily_var_gen(rename = (description = varname))
where denominator2 is not null;


select '%Ratio('||compress(name)||"_90D,"||compress(denominator2)||"_90D,rat_"||compress(varname)||"_2_90D,100,0.01,label= Ratio "||compress(name)||" to "||compress(denominator2)||" 90D)" into :ratio_90D separated by ";"
from &daily_var_gen (rename = (description = varname))
where denominator2 is not null;

select '%Ratio('||compress(name)||"_180D,"||compress(denominator2)||"_180D,rat_"||compress(varname)||"_2_180D,100,0.01,label= Ratio "||compress(name)||" to "||compress(denominator2)||" 180D)" into :ratio_180D separated by ";"
from &daily_var_gen(rename = (description = varname))
where denominator2 is not null;

select '%Ratio('||compress(name)||"_360D,"||compress(denominator2)||"_360D,rat_"||compress(varname)||"_2_360D,100,0.01,label= Ratio "||compress(name)||" to "||compress(denominator2)||" 360D)" into :ratio_360D separated by ";"
from &daily_var_gen(rename = (description = varname))
where denominator2 is not null;


/* int **/
	
select '%Ratio('||compress(name)||"_1D,"||compress(name)||"_3D,rat_"||compress(varname)||"_1D_3D,100,0.01,label= Ratio 1 day to 3 days "||trim(name)||")" into :defRatio13 separated by ";"
from &daily_var_gen(rename = (description = varname));
 
select '%Ratio('||compress(name)||"_1D,"||compress(name)||"_7D,rat_"||compress(varname)||"_1D_7D,100,0.01,label= Ratio 1 day to 7 days "||trim(name)||")" into :defRatio17 separated by ";"
from &daily_var_gen(rename = (description = varname));

select '%Ratio('||compress(name)||"_1D,"||compress(name)||"_30D,rat_"||compress(varname)||"_1D_30D,100,0.01,label= Ratio 1 day to 30 days "||trim(name)||")" into :defRatio130 separated by ";"
from &daily_var_gen(rename = (description = varname));
	
select '%Ratio('||compress(name)||"_1D,"||compress(name)||"_90D,rat_"||compress(varname)||"_1D_90D,100,0.01,label= Ratio 1 day to 90 days "||trim(name)||")" into :defRatio190 separated by ";"
from &daily_var_gen(rename = (description = varname));
 
select '%Ratio('||compress(name)||"_7D,"||compress(name)||"_30D,rat_"||compress(varname)||"_7D_30D,100,0.01,label= Ratio 7 day to 30 days "||trim(name)||")" into :defRatio730 separated by ";"
from &daily_var_gen(rename = (description = varname));

select '%Ratio('||compress(name)||"_7D,"||compress(name)||"_60D,rat_"||compress(varname)||"_7D_60D,100,0.01,label= Ratio 7 day to 60 days "||trim(name)||")" into :defRatio760 separated by ";"
from &daily_var_gen(rename = (description = varname)); 
 
select '%Ratio('||compress(name)||"_7D,"||compress(name)||"_90D,rat_"||compress(varname)||"_7D_90D,100,0.01,label= Ratio 7 day to 90 days "||trim(name)||")" into :defRatio790 separated by ";"
from &daily_var_gen(rename = (description = varname)); 
  
select '%Ratio('||compress(name)||"_7D,"||compress(name)||"_180D,rat_"||compress(varname)||"_7D_180D,100,0.01,label= Ratio 7 day to 180 days "||trim(name)||")" into :defRatio7180 separated by ";"
from &daily_var_gen(rename = (description = varname));  
 
select '%Ratio('||compress(name)||"_30D,"||compress(name)||"_60D,rat_"||compress(varname)||"_30D_60D,100,0.01,label= Ratio 30 day to 60 days "||trim(name)||")" into :defRatio3060 separated by ";"
from &daily_var_gen(rename = (description = varname));  
  
select '%Ratio('||compress(name)||"_30D,"||compress(name)||"_90D,rat_"||compress(varname)||"_30D_90D,100,0.01,label= Ratio 30 day to 90 days "||trim(name)||")" into :defRatio7180 separated by ";"
from &daily_var_gen(rename = (description = varname));  
  
select '%Ratio('||compress(name)||"_30D,"||compress(name)||"_180D,rat_"||compress(varname)||"_30D_180D,100,0.01,label= Ratio 30 day to 180 days "||trim(name)||")" into :defRatio30180 separated by ";"
from &daily_var_gen(rename = (description = varname));  
  
select '%Ratio('||compress(name)||"_30D,"||compress(name)||"_360D,rat_"||compress(varname)||"_30D_360D,100,0.01,label= Ratio 30 day to 360 days "||trim(name)||")" into :defRatio30360 separated by ";"
from &daily_var_gen(rename = (description = varname));  



 
endsas;
	



