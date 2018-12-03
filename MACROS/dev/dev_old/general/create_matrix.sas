%MACRO read_model_for_matrix(name=,dir=,dout=);


libname matrix "&dir";


proc sort data=matrix.model out=&dout (where =(variable~="Intercept"));
by descending WaldChiSq;
run;	
		
DATA &dout (KEEP=&name variable);
	SET &dout;
	&name + 1;
RUN;	

proc sort data=&dout;
by variable;
run;

proc print data=&dout;
run;	

	



%MEND read_model_for_matrix;

%MACRO write_matrix(dset=,matrixout=);
	
proc printto print="&matrixout" new;
RUN;

proc print data=matrix noobs;
RUN;	

proc printto;
run;	
	
%MEND write_matrix;	
	
	
	
	
