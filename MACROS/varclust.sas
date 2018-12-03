/* Variable Clustering                                    */
/*                                                        */
/* Uses PROC VARCLUS to do divisive clustering and output */
/* an 'optimal' number of clusters of variables, as well  */
/* as a listing of what each cluster should be comprised  */
/* of.                                                    */
/*                                                        */
/* Macro by Joe Toner                                     */
/*                                                        */
/* PARAMETERS:                                            */
/*  DATA=    The name of the input dataset.  If not       */
/*           specified, the most recently created dataset */
/*           is used.                                     */
/*                                                        */
/*  INPUTS=  List of input variables.  Best to store this */
/*           in a macro variable and call it.             */
/*                                                        */
/*  WHER=    Subsetting where statement (optional).       */
/*                                                        */
/*  MAXEIG=  Specifies the largest permissible value of   */
/*           the 2nd eigenvalue in each cluster (See      */
/*           SUGI paper on VARCLUS for more details.      */
/*           Another method is to use PERCENT=).  Default */
/*           is to use 0.7.                               */
/*                                                        */
/*  OUTFIL=  Path to write out the keep statement from    */
/*           the automated cluster process which picks a  */
/*           representative variable for each cluster.    */
/*                                                        */
/*                                                        */
/*                                                        */
/*                                                        */
/*                                                        */
/* EXAMPLE:                                               */
/*   %varclust(data=devdata, inputs=&inputs)              */
/*                                                        */
/*                                                        */

%macro varclust(data=_last_,inputs=_NUMERIC_,wher=1,maxeig=.7,
    outfil=./clusterkeep.sas,maxsearch=0,ksiv=,outksiv=);
    
    %let abort = 0;
    %if %upcase(&data) = _LAST_ %then %let data = &syslast;
    %if %upcase(&data) = _NULL_ %then %do;
        %put ERROR: There is no default input data set (_LAST_ is _NULL_);
        %let abort=1;
        %goto DONE;
        %end;

    ods listing close;
    ods output clusterquality=summary
               rsquare(match_all)=clusters;

	%global ncl;

    proc varclus data=&data maxeigen=&maxeig maxsearch=&maxsearch outtree=fortree short hi;
        var &inputs;   /* numeric only */
    run;

    ods listing;

    data _null_;
        set summary;
        call symput('ncl',trim(left(numberofclusters-2)));
    run;

    proc print data=clusters&ncl;
    run;

    axis1 value=(font=tahoma color=blue);

    proc tree data=fortree haxis=axis1;
        *height _MAXEIG_;
        height _propor_;
    run;

	data finalclus(keep=clusternum owncluster nextclosest rsquareratio variable);
		set clusters&ncl;
		retain clusternum;
		if not missing(cluster) then clusternum = cluster;
	run;

    proc sort data=finalclus;
        by clusternum rsquareratio;
    run;

    %if &ksiv eq %then %do;
        /* Unsupervised Clustering */
        data _null_;
            set finalclus;
            file "&outfil";
            by clusternum rsquareratio;
            if _N_ = 1 then put "/* Cluster Representatives (keep statement) */";
            if first.clusternum then put variable;
        run;
    %end;
    %else %do;
        /* For this, you need output of univariate data with KS and IV */
        data finalclus;
            set finalclus;
            by clusternum rsquareratio;
            if first.clusternum then order_rsq=0;
            order_rsq +1;
        run;

        proc sort nodupkey data=&ksiv out=ksiv;
            by varname;
        run;
 
        proc sort data=finalclus out=clusterz;
            by variable;
        run;

        data cluster_ksiv;
            merge clusterz(in=a rename=(variable=varname)) ksiv(in=b keep=varname ks ival);
            by varname;
            if a and b;
        run;

        proc sort data=cluster_ksiv;
            by clusternum descending ks;
        run;
         
        data cluster_ksiv;
            set cluster_ksiv;
            by clusternum descending ks;
            if first.clusternum then order_ks=0;
            order_ks +1;
        run;
         
        proc sort data=cluster_ksiv;
            by clusternum descending ival;
        run;
         
        data cluster_ksiv;
            set cluster_ksiv;
            by clusternum descending ival;
            if first.clusternum then order_iv=0;
            order_iv +1;
        run;

        data cluster_ksiv;
            set cluster_ksiv;
            clusterCandidate=(0<order_rsq<2 or order_ks <2 or 0<order_iv <2);
        run;

        %if &outksiv ne %then %do;
            data &outksiv;
                set cluster_ksiv;
            run;
        %end;

        data _null_;
            set cluster_ksiv;
            file "&outfil";
            if _N_ = 1 then put "/* Cluster Representatives (keep statement) */";
            if order_iv=1 then put varname;
        run;
    %end;

    %done:
    %if &abort %then %put ERROR: The VARCLUST macro ended abnormally.;
%mend varclust;
