/* *************************************************************************************************************
MACRO TO CONVERT PROBABILITY TO RAW SCORE AND SCALED SCORE 
****************************************************************************************************************/

%macro score_scaling(data_in=,
					 data_out=,
					 score_output=,
					 ScoreRef=600,
					 PDO=20,
					 ODDS=20,
					 variable=,
					 min=1,
					 max=1000
					 );
	   
		DATA &data_out.;
			SET &data_in.;
			
			%IF &variable. ne . %THEN %DO;
				odds=&variable./(1-&variable.);
				temp=log(odds);
				%IF %upcase(&score_output.)= RAWSCORE %THEN %DO;
					rawscore_&variable.= temp;
				%END;
				%ELSE %IF %upcase(&score_output.)= SCALEDSCORE %THEN %DO;
					a1 = (&ScoreRef* log(2)/&PDO - log(&ODDS))/(log(2)/&PDO);
					b1 = &PDO/log(2);
					scaledscore_&variable. = round(a1 + b1*temp);
				%END;
				%ELSE %IF %upcase(&score_output.) ne RAWSCORE or %upcase(&score_out.) ne SCALEDSCORE %THEN %DO; 
				    a1=0;b1=0;odds=0;temp=0;
				%END;
			%END;
			
			%ELSE %DO;
				%IF %upcase(&score_output.)= RAWSCORE %THEN %DO;
					rawscore_&variable.=.;
				%END;
				%ELSE %IF %upcase(&score_output.)= SCALEDSCORE %THEN %DO;
					a1 = .;
					b1 = .;
					scaledscore_&variable. = .;
				%END;
				%ELSE %IF %upcase(&score_output.) ne RAWSCORE or %upcase(&score_out.) ne SCALEDSCORE %THEN %DO; 
				    a1=0;b1=0;odds=0;temp=0;
				%END;
			%END;
			
			%IF %upcase(&score_output.)= SCALEDSCORE %THEN %DO;
                if scaledscore_&variable. gt &max. then scaledscore_&variable.=&max.;
                else if scaledscore_&variable. lt &min. then scaledscore_&variable.=&min.;
            %END;
			drop a1 b1 odds temp;
		RUN;

	%mend score_scaling;