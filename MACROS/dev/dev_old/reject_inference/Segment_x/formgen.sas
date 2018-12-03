                                                                                                      
filename in 'formgen.txt';                                                                            
filename out 'formgen.out';                                                                           
filename out2 'nformgen.out';                                                                         
                                                                                                      
data one;                                                                                             
  length name $30 line $120;                                                                          
  infile in dlm=';' end=flag;                                                                         
  if flag then stop;                                                                                  
  input name;                                                                                         
  input line ;                                                                                        
  name=upcase(compress(name));                                                                        
RUN;                                                                                                  
                                                                                                      
DATA read_it;                                                                                         
 length name name_for_format $30 ;                                                                    
 INFILE "format_names" DLM=",";                                                                       
 input name $ name_for_format $;                                                                      
 name=upcase(compress(name));                                                                         
 name_for_format=compress(name_for_format);                                                           
RUN;                                                                                                  
                                                                                                      
proc sort data=read_it;                                                                               
by name;                                                                                              
run;                                                                                                  
                                                                                                      
proc sort data=one;                                                                                   
by name;                                                                                              
run;                                                                                                  
                                                                                                      
DATA one;                                                                                             
 MERGE one (IN=InA) read_it;                                                                          
 by name;                                                                                             
 if InA;                                                                                              
RUN;                                                                                                  
                                                                                                      
DATA _null_;                                                                                          
 SET one;                                                                                             
  length  w1-w20 $8;                                                                                  
  array w{*} w1-w20;                                                                                  
  array f(*) f1-f20;                                                                                  
 file out;                                                                                            
  do i=1 to 20;                                                                                       
    f(i)=0;                                                                                           
  end;                                                                                                
  do i=1 to 20;                                                                                       
    w(i)=compress(scan(line, i, ' '));                                                                
    if (w(i)=' ') then go to outloop;                                                                 
    if i=1 and (indexc('#@ABCDEFGHIJKLMNOPQRSTUVWXYZ_',w(i)) = 0) then f(i)=1;                        
    else if i ge 2 then do;                                                                           
      if (indexc('#@ABCDEFGHIJKLMNOPQRSTUVWXYZ_',w(i-1)) gt 0)                                        
      and (indexc('#@ABCDEFGHIJKLMNOPQRSTUVWXYZ_',w(i)) = 0) then f(i)=1;                             
    end;                                                                                              
  end;                                                                                                
outloop:                                                                                              
  nocell=i;                                                                                           
  if indexc(name,'$') gt 0 then nocell=nocell-1;                                                      
  put 'proc format;';                                                                                 
  put 'value  ' name_for_format "/* " name "*/";                                                      
  do i=1 to nocell;                                                                                   
    if w(i)='@' then w(i)=' ' ;                                                                       
    if w(i)='#' then w(i)='.' ;                                                                       
                                                                                                      
                                                                                                      
    if indexc(name,'$') gt 0 then                                                                     
    do;                                                                                               
      put "'" w(i) "'= '" w(i) "'";                                                                   
    end;                                                                                              
    else do;                                                                                          
                                                                                                      
    if f(i) then put 'LOW - ' w(i) "=  '" w(i) "'";                                                   
    else if (i=nocell) then                                                                           
    do;                                                                                               
	  if missing(w(i-1)) or w(i-1)='.' or (indexc('#@ABCDEFGHIJKLMNOPQRSTUVWXYZ_',w(i-1)) gt 0) then do;
	    put "LOW - 0 = ' LOW - 0'";                                                                     
	    put "0 <- HIGH = ' 0 <- HIGH '";                                                                
	  end;                                                                                              
	  else do;                                                                                          
      put w(i-1) " <- HIGH = 'HIGH '";                                                                
	  end;                                                                                              
    end;                                                                                              
    else if (indexc('#@ABCDEFGHIJKLMNOPQRSTUVWXYZ_',w(i)) gt 0)                                       
            or( w(i) in (' ','.')) then do;                                                           
      put w(i)"='"w(i)"'";                                                                            
    end;                                                                                              
    else if i gt 1 then do;                                                                           
      put w(i-1) "<- " w(i) "= '"  w(i) "'";                                                          
    end;                                                                                              
  end;                                                                                                
  end;                                                                                                
  put ';';                                                                                            
run;                                                                                                  
                                                                                                      
                                                                                                      
 /*                                                                                                   
data one;                                                                                             
  length name $30 line $120 ;                                                                         
  infile in dlm=';' end=flag;                                                                         
  if flag then stop;                                                                                  
  input name;                                                                                         
  input line ;                                                                                        
  name=upcase(compress(name));                                                                        
RUN;                                                                                                  
                                                                                                      
proc sort data=one;                                                                                   
by name;                                                                                              
run;                                                                                                  
                                                                                                      
DATA one;                                                                                             
 MERGE one (IN=InA) read_it;                                                                          
 by name;                                                                                             
 if InA;                                                                                              
RUN;                                                                                                  
                                                                                                      
*/                                                                                                    
                                                                                                      
                                                                                                      
DATA _null_;                                                                                          
 SET one;                                                                                             
  length w1-w20 $8;                                                                                   
  array w{*} w1-w20;                                                                                  
  array f(*) f1-f20;                                                                                  
  file out2;                                                                                          
  do i=1 to 20;                                                                                       
    f(i)=0;                                                                                           
  end;                                                                                                
  do i=1 to 20;                                                                                       
    w(i)=compress(scan(line, i, ' '));                                                                
    if (w(i)=' ') then go to outloop;                                                                 
    if i=1 and (indexc('#@ABCDEFGHIJKLMNOPQRSTUVWXYZ_',w(i)) = 0) then f(i)=1;                        
    else if i ge 2 then do;                                                                           
      if (indexc('#@ABCDEFGHIJKLMNOPQRSTUVWXYZ_',w(i-1)) gt 0)                                        
      and (indexc('#@ABCDEFGHIJKLMNOPQRSTUVWXYZ_',w(i)) = 0) then f(i)=1;                             
    end;                                                                                              
  end;                                                                                                
outloop:                                                                                              
  nocell=i;                                                                                           
  if indexc(name,'$') gt 0 then nocell=nocell-1;                                                      
  put 'proc format;';                                                                                 
  put 'value  ' name_for_format "/* " name "*/";                                                      
  do i=1 to nocell;                                                                                   
    if w(i)='@' then w(i)=' ' ;                                                                       
    if w(i)='#' then w(i)='.' ;                                                                       
                                                                                                      
                                                                                                      
    if indexc(name,'$') gt 0 then                                                                     
    do;                                                                                               
      put "'" w(i) "'= '" w(i) "'";                                                                   
    end;                                                                                              
    else do;                                                                                          
                                                                                                      
    if f(i) then put 'LOW - ' w(i) "= 'LOW - " w(i) "'";                                              
    else if (i=nocell) then                                                                           
    do;                                                                                               
                                                                                                      
	  /* check if next to last value was a missing value */                                             
	  if missing(w(i-1)) or w(i-1)='.' or (indexc('#@ABCDEFGHIJKLMNOPQRSTUVWXYZ_',w(i-1)) gt 0) then do;
	    put "LOW - 0 = ' LOW - 0'";                                                                     
	    put "0 <- HIGH = ' 0 <- HIGH '";                                                                
	  end;                                                                                              
	  else do;                                                                                          
      put w(i-1) " <- HIGH" " = '"w(i-1) " <- HIGH '";                                                
	  end;                                                                                              
                                                                                                      
	 end;                                                                                               
    else if (indexc('#@ABCDEFGHIJKLMNOPQRSTUVWXYZ_',w(i)) gt 0)                                       
            or( w(i) in (' ','.')) then do;                                                           
      put w(i)"='"w(i)"'";                                                                            
    end;                                                                                              
    else if i gt 1 then do;                                                                           
      put w(i-1) "<- " w(i) "= '"w(i-1) "<- "  w(i) "'";                                              
    end;                                                                                              
  end;                                                                                                
  end;                                                                                                
  put ';';                                                                                            
run;                                                                                                  