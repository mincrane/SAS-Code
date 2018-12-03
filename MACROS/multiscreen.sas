/* Multivariate association screening of input variables */
/* See p. 81 in PMLR notes                               */
%macro multiscreen(inset,target,inputs,varnamelen=30,wgt=);
    ods listing close;
    ods output spearmancorr=spearman
               hoeffdingcorr=hoeffding
               varinformation=varinfo;

    proc corr data=&inset spearman hoeffding rank;
        var &inputs;
        with &target;
		%if &wgt ^= %then %do;
			weight &wgt;
		%end; ;
    run;

    ods listing;

    data _null_;
        set varinfo;
        where VarNames ne "&target";
        call symput('wvars',trim(left(nvars)));
    run;

    data spearman1(keep=variable scorr spvalue ranksp);
        length variable $ &varnamelen;
        set spearman;
        array best{&wvars} best1--best&wvars;
        array r{&wvars} r1--r&wvars;
        array p{&wvars} p1--p&wvars;

        do i=1 to &wvars;
            variable=best(i);
            scorr=r(i);
            spvalue=p(i);
            ranksp=i;
            output;
            end;
    proc sort;
        by variable;
    run;

    data hoeffding1(keep=variable hcorr hpvalue rankho);
        length variable $ &varnamelen;
        set hoeffding;
        array best{&wvars} best1--best&wvars;
        array r{&wvars} r1--r&wvars;
        array p{&wvars} p1--p&wvars;

        do i=1 to &wvars;
            variable=best(i);
            hcorr=r(i);
            hpvalue=p(i);
            rankho=i;
            output;
            end;
    proc sort;
        by variable;
    run;

    data correlations;
        merge spearman1 hoeffding1;
        by variable;
    proc sort;
        by ranksp;
    run;

    title1 Multivariate Association Screening;
    title2 (High S, Low H : Nonlinear Association);
    title3 (Low H, Low H : Linear Association);
    title4 (High S, High H : No Association);

    proc print data=correlations label split='*';
        var variable rankho ranksp scorr spvalue hcorr hpvalue;
        label ranksp  = "Spearman Rank*of Variables"
              scorr   = "Spearman Correlation"
              spvalue = "Spearman p-value"
              rankho  = "Hoeffding rank*of Variables"
              hcorr   = "Hoeffding Correlation"
              hpvalue = "Hoeffding p-value";
        run;
%mend multiscreen;
