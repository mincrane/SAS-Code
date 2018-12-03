/* *************************************************************************************************************
MACRO TO CONVERT PROBABILITY TO RAW SCORE AND SCALED SCORE 
****************************************************************************************************************/

%macro score_scaling(data_in=,
					 data_out=,
					 score_output=SCALEDSCORE,
					 ScoreRef=600,
					 PDO=20,
					 ODDS=20,
					 prob=,
					 min=1,
					 max=1000
					 );
	   
		DATA &data_out.;
			SET &data_in.;
			
			%IF &prob. ne . %THEN %DO;
				odds=&prob./(1-&prob.);
				temp=log(odds);
				%IF %upcase(&score_output.)= RAWSCORE %THEN %DO;
					rawscore_&prob.= temp;
				%END;
				%ELSE %IF %upcase(&score_output.)= SCALEDSCORE %THEN %DO;
					a1 = (&ScoreRef* log(2)/&PDO - log(&ODDS))/(log(2)/&PDO);
					b1 = &PDO/log(2);
					scaledscore_&prob. = round(a1 + b1*temp);
				%END;
			%END;
			
			%ELSE %DO;
				%IF %upcase(&score_output.)= RAWSCORE %THEN %DO;
					rawscore_&prob.=.;
				%END;
				%ELSE %IF %upcase(&score_output.)= SCALEDSCORE %THEN %DO;
					a1 = .;
					b1 = .;
					scaledscore_&prob. = .;
				%END;
			%END;
			if scaledscore_&prob. gt &max. then scaledscore_&prob.=&max.;
			else if scaledscore_&prob. lt &min. then scaledscore_&prob.=&min.;
			drop a1 b1 odds temp;
		RUN;

	%mend score_scaling;
	
	