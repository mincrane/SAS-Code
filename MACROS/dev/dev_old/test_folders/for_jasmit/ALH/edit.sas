libname data "/sas/pprd/austin/operations/macro_library/dev/test_folders/for_jasmit/ALH/seg1/Final_Stats";

proc print data=data.iter_matrix;
run;

proc contents data=data.iter_matrix;
run;

data temp;
length variable $40;
set data.iter_matrix;

run;

proc contents data=temp;
run;