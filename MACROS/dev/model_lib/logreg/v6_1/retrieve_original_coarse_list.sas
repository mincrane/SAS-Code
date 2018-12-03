libname param '/sas/pprd/austin/models/dev/behavioral/modeling/models/segment_9/iteration27' access=readonly;
libname mdl '/sas/pprd/austin/models/dev/behavioral/data/modeling/' access=readonly;




%MACRO retrieve_original_coarse_list(modelingset=,parameterset=,outset=);

/********************************************************************************************** 
/* Program Name:		retrieve_original_coarse_list.sas
/* Author: 					Giselle Nevada
/* Creation Date:   7/2/2010
/* Last Modified:   

/* Purpose:         Grabs a model.sas7bdat datset from logreg model and determines which are
                    WOE variables and gets a list of the original variable names.

/* Arguments:      modelingset - name of dataset that logreg is run on
                   parameterset - name of dataset (example : library_name.model)
                   outset - output dataset
								    

/* Notes:           Checks all variables in model.sas7bdat for variables that 
                    start with W. Then, removes W and sees if that matches any variables
                    in modeling set.  If so, outputs the variable name to a temp set.
                    
/* Example call:    %retrieve_original_coarse_list(modelingset=mdl.modeling_data_master,parameterset=param.model,outset=temp);

***************************************************************************************************/ 	

PROC CONTENTS DATA=&modelingset out=contents (KEEP=name type) noprint;
RUN;


DATA woe_list;
	length name $100.;
	 SET &parameterset;
	 where substr(variable,1,1) IN ("w","W");
	 name=substr(variable,2,length(variable));
RUN;

proc sort data=woe_list (KEEP=name);
by name;
run;

proc sort data=contents;
by name;
run;

DATA &outset (RENAME=(name=variable));
	MERGE woe_list (in=ina) contents (in=InB);
	by name;
	if ina and inb;
RUN;
	

	
%MEND retrieve_original_coarse_list;
