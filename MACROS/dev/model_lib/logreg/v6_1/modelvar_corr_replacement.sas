/************************************************************************** 
/* Program Name:		modelvar_corr_replacement.sas
/* Author:    			F.Zahradnik
/* Creation Date: 	4/29/2008
/* Last Modified:   5/5/2008: added path argument for use with other macros.
                    Also, included null step that replaces existing 
                    replaced_model.txt
                    
/* Purpose:  				Substitute model variables with correlated variables
										and generate model statistics comparing results.
/* Arguments:       Requires the rdmp_grpKSIV macro in rdmp_eml.sas 
***************************************************************************/ 
%include "&_macropath./general/rdmp_eml.sas";      
%macro model_corr_replace(dset=,
                          perfvar=,
                          wghtvar=,
                          varlist=,
                          path=,
                          _modKS=,
                          _modIV=,
                          rhothresh=,
                          );
                          
libname debug '.';

%IF %length(&path.) > 0 %THEN %DO;
  filename submod "&path./replaced_models.txt";
%END;
%ELSE %DO;
  filename submod 'replaced_models.txt';
%END;

%IF %sysfunc(exist(&dset.)) %THEN %DO;
  
  /*Remove existing replaced_models.txt*/
  data _null_;
  	file submod;
  run;
  
  /*Create quoted, comma delimited list of variables for sql variable generation*/
  %let qlisttmp= %str(%")%sysfunc(tranwrd(&varlist.,%str( ),%str(",")))%str(%");
  %let qlist= %unquote(&qlisttmp);
  
  /*Flag character variables for removal from dataset and generate
    lists of numeric candidate variables for replacement*/
  proc contents data=&dset out=_contents(keep=name type) noprint;
  run;
  
  proc sql noprint;
  	select name,count(name)
  	  into: _charname separated by " ",
  	      : _ccnt
  	  from _contents
  	  where type= 2
  	;  
  
    select name,count(name)
      into: _nvarlist separated by " ",
          : _ncnt
      from _contents
      where type=1 and name not in ("&perfvar.","&wghtvar.")
    ; 
    
    create table _modcont as
      select name
      from _contents
      where type=1 and name in (&qlist.)
    ;
    
    select name,count(name)
      into: _mvarlist separated by " ",
          : _mcnt
      from _contents
      where type=1 and name in (&qlist.);
    quit;
    
    /* Calculate correlation */
    data _forcorr;
  	  set &dset.;
  	  %IF &_ccnt > 0 %THEN %DO;
  	    drop &_charname;
  	  %END;
    run;
    
    proc corr data= _forcorr pearson outp= _corrmat noprint;
  	  var &_nvarlist.;
    run;
    
    /*Calculate KS/IV statistics for ALL numeric variables.  These are 
      stored in the dataset _varstat and later joined to the correlation
      results */
     *Remaining independent variables;
     %DO ii=1 %TO &_ncnt.;
       %rdmp_grpKSIV(dset=&dset,targvar=%scan(&_nvarlist,&ii),perfvar=&perfvar,wghtvar=&wghtvar,ngroup=10,oset=_varstat);
     %END;
     
     proc sql noprint;
  	   create table _corrmat_stat as
  	   select a.*,b.KS,b.IVAL
  	   from _corrmat as a,
  	        _varstat as b
  	   where upcase(compress(a._name_)) = upcase(compress(b.varname))
  	  ;
     quit;
     
     
     /*The following nested loops are the crux of the macro.  The outer loop iterates through
       each variable in the model and checks the correlation coefficient.  If the coefficient
       is above the rho threshold, then the variable is added to the new candidate list and a 
       counter is incremented.
       
       The inner loop iterates through the candidate list populated in the outer loop and develops
       a replacement model substituting the current model variable with a highly correlated surrogate.
       Each iteration of the inner loop writes the refit model parameter estimates to replaced_models.txt.
       
       A report is generated summarizing the change in KS and IV by replacing the model variable 
       with the surrogate.  
     
     */   
     %local _vKS _vIV _exclist _newmodel;
  
     %DO ii=1 %TO &_mcnt.;
       proc sql noprint;
    	   select KS,IVAL
    	     into: _vKS,
    	         : _vIV
    	     from _corrmat_stat
    	     where upcase(_name_) = "%upcase(%scan(&_mvarlist.,&ii.))"
    	   ;
    	   
    	   select name
    	     into: _exclist separated by " "
    	     from _modcont
    	     where upcase(name) not in ("%upcase(%scan(&_mvarlist.,&ii.,%str( )))")
    	   ;
         	 
       /*construct model statements for current model variable by
         adding a new variable to each variable list*/
    	  select _name_,count(_name_)
    	    into: _newmodel separated by " ",
    	        : _nmcnt
    	    from _corrmat_stat
    	    where _name_ not in (&qlist.)
    	      and _TYPE_= "CORR" 
    	      and abs(%scan(&_mvarlist,&ii.)) >= &rhothresh.
    	  ;
        quit;
       
        /*
        *temporary to verify substitution selection;
        proc sql;
        	select _name_
        	       ,%scan(&_mvarlist,&ii.) label= '#Correlation#Coefficient'
        	from _corrmat_stat
        	where _name_ not in (&qlist.)
        	  and _TYPE_ = "CORR"
        	  and abs(%scan(&_mvarlist.,&ii.)) >= &rhothresh.
        ;
        quit;*/ 
        
        
        data _null_;
          %IF %sysfunc(fexist(submod)) %THEN %DO;
            file submod mod;
          %END;
          %ELSE %DO;
            file submod;
            put @1 "Model Variable Substitution Parameter Estimates";
            put @1 "Base Model KS: &_modKS.";
            put @1 "Base Model IV: &_modIV." / ;
          %END;
          
          %IF &_nmcnt > 0 %THEN %DO;
            put @1 "Model variable to be replaced: %upcase(%scan(&_mvarlist.,&ii.))";
          %END;
          %ELSE %DO;
            put @1 "No surrogate variables found for %upcase(%scan(&_mvarlist.,&ii.)) for given threshold(&rhothresh.)" /;
          %END;   
        run;
          
          
        %IF &_nmcnt > 0 %THEN %DO;
        
           %DO jj=1 %TO &_nmcnt;
             %let _mstrq= %nrstr(&perfvar.(event='1') = %scan(&_newmodel,&jj,%str( )) &_exclist.;);
             %let _mstr= %unquote(&_mstrq.);
  
             ods listing close;
             ods output ParameterEstimates=pe;
             
             proc logistic data=&dset. namelen=32;
             	weight &wghtvar.;
             	model &_mstr.;
             	output out=_results p=phat_%scan(&_newmodel.,&jj.,%str( ));
             run;
             
             ods listing;   
             
             %rdmp_grpKSIV(dset=_results,targvar=phat_%scan(&_newmodel.,&jj.,%str( )),perfvar=&perfvar,wghtvar=&wghtvar,ngroup=10,oset=_mstat);
             
             data _null_;
             	 set pe end=last;
             	 file submod mod;
             	 if _n_=1 then do;
             	   put @1 "Replaced with: %upcase(%scan(&_newmodel.,&jj.,%str( )))" /;
                 put @59 "Standard" @72 "Wald" @83 "Prob.";
  	             put @1 "Variable" @35 "DF" @45 "Estimate" @59 "Error" @72 "Chi Sq." @83 "Chi Sq.";
  	             put @1 95*'-' /;
  	           end; 
  	           
  	           varn= upcase(variable);
               put @1 varn
                   @35 df
                   @45 estimate 8.5
                   @59 stderr 8.4
                   @72 WaldChiSq 8.3
                   @83 probchisq 8.3
               ;
               
               if last then do;
               	put @1 " " //;
               end;  
                           
           %END; /*End jj loop */
           
           data _mstat1;
           	 set _mstat;
           	 tname= trim(substr(varname,6));
           	 matchname= "%upcase(%scan(&_mvarlist.,&ii.))";
           	 delta_ks= KS-&_modKS;
           	 delta_ks_pct= 100*(delta_ks/&_modKS.);
           	 
           	 delta_iv= IVAL-&_modIV;
           	 delta_iv_pct= 100*(delta_iv/&_modIV.);
           	 
           run;
           
           %IF %sysfunc(exist(_mstat2)) %THEN %DO; 
             proc append base=_mstat2 data=_mstat1;
             run;
           %END;
           %ELSE %DO;
             data _mstat2;
             	 set _mstat1;
             run;
           %END;
          
           proc datasets library=work;
             delete _mstat;
             delete _mstat1;
           run;
           
           title "Variable Proxies for %scan(&_mvarlist.,&ii.)";
           title2 "Variable KS: %sysfunc(putn(&_vKS,8.2))";
           title3 "Variable IV: %sysfunc(putn(&_vIV,8.3))";
           
           proc sql;
           	select a._name_ label= 'Variable Name'
           	        ,a.%scan(&_mvarlist,&ii.) label= '#Correlation#Coefficient'
           	        ,a.KS label='#Variable#KS'
           	        ,a.IVAL label='#Variable#IV'
           	        ,b.KS label='#Replacement#Model KS'
           	        ,b.delta_ks label='#Delta#KS'
           	        ,b.delta_ks_pct label='#Delta#KS Pct.'
           	        ,b.IVAL label='#Replacement#Model IV'
           	        ,b.delta_iv label='#Delta#IV'
           	        ,b.delta_iv_pct label='#Delta#IV Pct.'
           	from _corrmat_stat a
           	    ,_mstat2 b
           	where upcase(strip(a._name_)) = upcase(strip(b.tname))
           	  and strip(b.matchname) = "%upcase(%scan(&_mvarlist.,&ii.,%str( )))"
           	  and a._name_ not in (&qlist.)
           	  and a._TYPE_= "CORR"
           	  and abs(a.%scan(&_mvarlist,&ii.)) >= &rhothresh.
           	order by b.delta_iv_pct desc;
           quit;
           title3;
           title2;
           title;
           
         %END;   
             
     %END;  /* End ii loop */ 

%END;
%ELSE %DO;
  %put;
  %put %upcase(&sysmacroname): Dataset &dset not found.;
  %put;
  %goto macroerror;
%END;

%macroerror: %put;
%put -------------------------------------------------------------------------------------;
%put --- %upcase(&sysmacroname) macro terminated.                                         ;
%put -------------------------------------------------------------------------------------;
%mend model_corr_replace;