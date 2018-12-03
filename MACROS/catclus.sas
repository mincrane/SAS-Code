/* Clustering Levels (see p. 57 in SAS Course Notes from  */
/*     Predictive Modeling Using Logistic Regression)     */
/*                                                        */
/* Uses Greenacre's method (1998, 1993)                   */
/*                                                        */
/* This macro provides information that can be used to    */
/* determine optimal clustering of a categorical          */
/* predictor variable.                                    */
/*                                                        */
/* Macro by Joe Toner                                     */
/*                                                        */
/* PARAMETERS:                                            */
/*  DATA=    The name of the input dataset.  If not       */
/*           specified, the most recently created dataset */
/*           is used.                                     */
/*                                                        */
/*  PRED=    Categorical predictor variable that you wish */
/*           to cluster.                                  */
/*                                                        */
/*  RESP=    Response (target) variable in input dataset. */
/*                                                        */
/*  WHER=    Subsetting where statement (optional).       */
/*                                                        */
/* EXAMPLE:                                               */
/*   %catclus(data=devdata, pred=goods_type, resp=bad)    */
/*                                                        */
/*                                                        */


%macro catclus(data=_last_,pred=,resp=,wher=1);
    %let abort = 0;
    %if %upcase(&data) = _LAST_ %then %let data = &syslast;
    %if %upcase(&data) = _NULL_ %then %do;
        %put ERROR: There is no default input data set (_LAST_ is _NULL_);
        %let abort=1;
        %goto DONE;
        %end;

    proc means data=&data(where=(&wher)) noprint nway ;
        class &pred; /* >>> / missing */
        var &resp;
        output out=levels mean=prop;
    run;

    /* See p. 61 in PMULR */
    ods trace on / listing;
    proc cluster data=levels method=ward outtree=fortree;
        freq _freq_;
        var prop;
        id &pred;
    run;
    ods trace off;

    ods listing close;
    ods output clusterhistory=cluster;
    proc cluster data=levels method=ward;
        freq _freq_;
        var prop;
        id &pred;
    run;
    ods listing;

    proc freq data=&data(where=(&wher)) noprint;
        tables &pred*&resp / chisq;
        output out=chi(keep=_pchi_) chisq;
    run;

    data cutoff;
        if _n_=1 then set chi;
        set cluster;
        chisquare=_pchi_*rsquared;
        degfree=numberofclusters-1;
        logpvalue=logsdf('CHISQ',chisquare,degfree);
    run;

    /* See p. 63 in PMULR - optimal area is bottom of "check mark" */
    title1 Log of p-value of Chi-Squared;
    title2 Categorical Variable: %upcase(&pred);
    proc gplot data=cutoff;
        plot logpvalue*numberofclusters;
    run;
    quit;

    proc means data=cutoff noprint;
        var logpvalue;
        output out=small minid(logpvalue(numberofclusters))=ncl;
    run;

    data _null_;
        set small;
        call symput('ncl',compress(ncl));
    run;

    /* Dendrogram showing collapsing methods and associated */
    /* reduction of chi-squared...                          */
    title1 Reduction in Chi-Squared Via Clustering;
    title2 Categorical Variable: %upcase(&pred);
    title3 (Vertical axis represents proportion of chi-squared,;
    title4 Horizontal axis roughly ordered by mean proportion of events in each cluster);
    proc tree data=fortree nclusters=&ncl out=clus h=rsq;
        id &pred;
    run;

    proc sort data=clus;
        by clusname;
    run;

    title1 Recommended Optimal Collapse of %upcase(&pred) Into &ncl Clusters:;
    title2 (Observations with a missing value for %upcase(&pred) discarded);
    proc print data=clus;
        by clusname;
        id clusname;
    run;

    %put The optimum number of clusters for the variable %upcase(&pred) is: &ncl;
    %put (Observations with a missing value for %upcase(&pred) discarded);
    title;
    
    %done:
    %if &abort %then %put ERROR: The CATCLUS macro ended abnormally.;
%mend catclus;
