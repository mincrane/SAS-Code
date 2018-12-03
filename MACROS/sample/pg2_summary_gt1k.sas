/*** pull monthly raw variables ****/

options compress=yes obs=max ls=max ps=max pageno=1 errors=10 nocenter; * symbolgen mlogic mprint;
%put NOTE: PID of this session is &sysjobid..;


filename pwfile "~/tera_pwf.txt";

data _null_;
  infile pwfile obs=1 length=l;
  input @;
  input @1 line $varying1024.  l;
  call symput('tdbpass',substr(line,1,l));
  
run;


libname scratch teradata user=&sysuserid PASSWORD="&tdbpass" TDPID="hopper" DATABASE=access_views	OVERRIDE_RESP_LEN=YES DBCOMMIT=0;
libname raw './data';



proc format;
value lossfmt
.                 = 'Missing'
low      -  0     = '     <- 0   '    
0       <-  25    = '0    <- 25  '
25      <-  100   = '25   <- 100 '
100     <-  500   = '100  <- 500 '
500     <-  1000  = '500  <- 1000'
1000    <-  2000  = '1000 <- 2000'
2000    <-  5000  = '2000 <- 5000'
5000    <-  10000 = '5000 <- 10000'
10000   <-  25000 = '10000<- 25000'
25000   <-  high  = '25000 <- High';


value lossf
.             = ' Missing'
low  - 0      = '     <-    0' 
0    <- 100   = '     <-  100'
100  <- 500   = ' 100 <-  500'
500  <- 1000  = ' 500 <- 1000'
1000 <- high  = '1000 -  High';


value txnfmt
0 = '0'
0<-1 = '1'
1<-5 ='1<-5'
5<-25 = '5<-25'
25<-100 = '25<-100'
100<-500 = '100<-500'
500<-high = '>500';

value mobfmt
low-0 = '0'
0<-6 ='0<-6'
6<-12 = '6<-12'
12<-high = '>12'
;


value txnfmtf
0 - 25 = '<=25'
25<-high = '>25';

value mobfmtf
0-12 = '<=12'
12<-high = '>12'
;

quit;    




%macro summary(ind=,bar=,gmv_bar=);

PROC FORMAT;
PICTURE PCTPIC 0-high='009.999%';
PICTURE BPSPIC low-<0.1 = '9.9'(mult=&gmv_bar)
               0.1-<  1 = '99' (mult=100)
				       1 -< 10 ='999'  (mult=100)
               10 - high ='9,999' (mult=100);

RUN;


ods html file = "usar_summary_&bar._&ind..xls";




/** by loss &ind **/

proc tabulate data = raw.ebay_usar_analy_&ind missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  tot_net_loss_m0 /style= [background = light bule];                                                                                                                                                                  
      var    net_loss_m0 gmv_m0 num_txn_m0 cnt_esc_claim_m0 /s=[background=light blue];                                   
                           
      table ( tot_net_loss_m0  = '' all=[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
			  /*cnt_txn  = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<cnt_txn> = '% of total weighted' ) */
			                                   
              num_txn_m0 = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              gmv_m0  = 'GMV '*(sum = 'Total Amount'*f=comma18.0 colpctsum<gmv_m0> ='% of GMV' mean*f=comma8.0)  
              net_loss_m0  = 'Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
              cnt_esc_claim_m0 = 'ESC CLAIM' * (sum = 'Total Num'*f=comma10.0 colpctsum<cnt_esc_claim_m0>='% of esc claim' /*rowpctsum<cnt_defects> ='% of Defects'*/)  
			  /*cnt_defects ='Defect #'*(sum = 'Total Num'*f=comma10.0 colpctsum<cnt_defects>='% of defects' rowpctsum<cnt_txn> ='Defect rate' mean*f=comma8.0)   */                                                          
              /*&gross_loss  = 'Gross Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<&gross_loss> ='% of gross loss' rowpctsum<&gmv.>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) */			                            
 		                
            )  
				
                                                                                                                                                                                                                     
                          /Box="net loss" row=float RTS=25 /*misstext = '0'*/;  
						  
format tot_net_loss_m0 lossfmt.;	
where gmv_m0>&gmv_bar;
*weight &wghtvar.;					  
run;



/** by number of tran **/

proc tabulate data = raw.ebay_usar_analy_&ind missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  tot_gmv_m0 tot_num_txn_m0 seg orig_mob msfs_mob tot_net_loss_m0/style= [background = light bule];                                                                                                                                                                  
      var    net_loss_m0 gmv_m0 num_txn_m0 cnt_esc_claim_m0 /s=[background=light blue];                                   
                           
      table ( tot_num_txn_m0  = '' all=[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
			  /*cnt_txn  = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<cnt_txn> = '% of total weighted' ) */
			                                   
              num_txn_m0 = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              gmv_m0  = 'GMV '*(sum = 'Total Amount'*f=comma18.0 colpctsum<gmv_m0> ='% of GMV' mean*f=comma8.0)  
              net_loss_m0  = 'Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
              cnt_esc_claim_m0 = 'ESC CLAIM' * (sum = 'Total Num'*f=comma10.0 colpctsum<cnt_esc_claim_m0>='% of esc claim' /*rowpctsum<cnt_defects> ='% of Defects'*/)  
			  /*cnt_defects ='Defect #'*(sum = 'Total Num'*f=comma10.0 colpctsum<cnt_defects>='% of defects' rowpctsum<cnt_txn> ='Defect rate' mean*f=comma8.0)   */                                                          
              /*&gross_loss  = 'Gross Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<&gross_loss> ='% of gross loss' rowpctsum<&gmv.>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) */			                            
            
			                
            )  
 tot_net_loss_m0='Net Loss Cnt'*f=comma8.0 			
                                                                                                                                                                                                                     
                          /Box="number of trans" row=float RTS=25 /*misstext = '0'*/;  
						  
format tot_num_txn_m0 txnfmt. tot_net_loss_m0 lossf.;	
where gmv_m0>&gmv_bar;
run;

/** by mob **/
proc tabulate data = raw.ebay_usar_analy_&ind missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  tot_gmv_m0 tot_num_txn_m0 seg orig_mob msfs_mob tot_net_loss_m0/style= [background = light bule];                                                                                                                                                                  
      var    net_loss_m0 gmv_m0 num_txn_m0 cnt_esc_claim_m0 /s=[background=light blue];                                   
                           
      table ( orig_mob  = '' all=[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
			  /*cnt_txn  = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<cnt_txn> = '% of total weighted' ) */
			                                   
              num_txn_m0 = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              gmv_m0  = 'GMV '*(sum = 'Total Amount'*f=comma18.0 colpctsum<gmv_m0> ='% of GMV' mean*f=comma8.0)  
              net_loss_m0  = 'Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
              cnt_esc_claim_m0 = 'ESC CLAIM' * (sum = 'Total Num'*f=comma10.0 colpctsum<cnt_esc_claim_m0>='% of esc claim' /*rowpctsum<cnt_defects> ='% of Defects'*/)  
			  /*cnt_defects ='Defect #'*(sum = 'Total Num'*f=comma10.0 colpctsum<cnt_defects>='% of defects' rowpctsum<cnt_txn> ='Defect rate' mean*f=comma8.0)   */                                                          
              /*&gross_loss  = 'Gross Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<&gross_loss> ='% of gross loss' rowpctsum<&gmv.>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) */			                            
            
			                
            )   
 tot_net_loss_m0='Net Loss Cnt'*f=comma8.0 			
                                                                                                                                                                                                                     
                          /Box="Orig Mob" row=float RTS=25 /*misstext = '0'*/;  
						  
format orig_mob mobfmt. tot_net_loss_m0 lossf.;	
where gmv_m0>&gmv_bar;					  
run;

%macro dd;
proc tabulate data = raw.ebay_usar_analy_&ind missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  tot_gmv_m0 tot_num_txn_m0 seg orig_mob msfs_mob tot_net_loss_m0/style= [background = light bule];                                                                                                                                                                  
      var    net_loss_m0 gmv_m0 num_txn_m0 cnt_esc_claim_m0 /s=[background=light blue];                                   
                           
      table ( msfs_mob  = '' all=[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
			  /*cnt_txn  = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<cnt_txn> = '% of total weighted' ) */
			                                   
              num_txn_m0 = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              gmv_m0  = 'GMV '*(sum = 'Total Amount'*f=comma18.0 colpctsum<gmv_m0> ='% of GMV' mean*f=comma8.0)  
              net_loss_m0  = 'Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
              cnt_esc_claim_m0 = 'ESC CLAIM' * (sum = 'Total Num'*f=comma10.0 colpctsum<cnt_esc_claim_m0>='% of esc claim' /*rowpctsum<cnt_defects> ='% of Defects'*/)  
			  /*cnt_defects ='Defect #'*(sum = 'Total Num'*f=comma10.0 colpctsum<cnt_defects>='% of defects' rowpctsum<cnt_txn> ='Defect rate' mean*f=comma8.0)   */                                                          
              /*&gross_loss  = 'Gross Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<&gross_loss> ='% of gross loss' rowpctsum<&gmv.>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) */			                            
            
			                
            ) 
 tot_net_loss_m0='Net Loss Cnt'*f=comma8.0 			
                                                                                                                                                                                                                     
                          /Box="MSFS MOB" row=float RTS=25 /*misstext = '0'*/;  
						  
format msfs_mob mobfmt. tot_net_loss_m0 lossf.;	
					  
run;
%mend;

/**** by seg ***/
proc tabulate data = raw.ebay_usar_analy_&ind missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  tot_gmv_m0 tot_num_txn_m0 seg orig_mob msfs_mob seg tot_net_loss_m0/style= [background = light bule];                                                                                                                                                                  
      var    net_loss_m0 gmv_m0 num_txn_m0 cnt_esc_claim_m0 /s=[background=light blue];                                   
                           
      table ( seg  = '' all=[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
			  /*cnt_txn  = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<cnt_txn> = '% of total weighted' ) */
			                                   
              num_txn_m0 = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              gmv_m0  = 'GMV '*(sum = 'Total Amount'*f=comma18.0 colpctsum<gmv_m0> ='% of GMV' mean*f=comma8.0)  
              net_loss_m0  = 'Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
              cnt_esc_claim_m0 = 'ESC CLAIM' * (sum = 'Total Num'*f=comma10.0 colpctsum<cnt_esc_claim_m0>='% of esc claim' /*rowpctsum<cnt_defects> ='% of Defects'*/)  
			  /*cnt_defects ='Defect #'*(sum = 'Total Num'*f=comma10.0 colpctsum<cnt_defects>='% of defects' rowpctsum<cnt_txn> ='Defect rate' mean*f=comma8.0)   */                                                          
              /*&gross_loss  = 'Gross Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<&gross_loss> ='% of gross loss' rowpctsum<&gmv.>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) */			                            
            
			                
            )   
 tot_net_loss_m0='Net Loss Cnt'*f=comma8.0 			
                                                                                                                                                                                                                     
                          /Box="Seg" row=float RTS=25 /*misstext = '0'*/;  
						  
format msfs_mob mobfmt. tot_net_loss_m0 lossf.;	
where gmv_m0> &gmv_bar;					  
run;

/**********************************************************************************************************/
/**** by num tran Mob ***/
proc tabulate data = raw.ebay_usar_analy_&ind missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  tot_gmv_m0 tot_num_txn_m0 seg orig_mob msfs_mob seg tot_net_loss_m0/style= [background = light bule];                                                                                                                                                                  
      var    net_loss_m0 gmv_m0 num_txn_m0 cnt_esc_claim_m0 /s=[background=light blue];                                   
                           
      table ( tot_num_txn_m0=''*(orig_mob='' all) all=[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
			  /*cnt_txn  = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<cnt_txn> = '% of total weighted' ) */
			                                   
              num_txn_m0 = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              gmv_m0  = 'GMV '*(sum = 'Total Amount'*f=comma18.0 colpctsum<gmv_m0> ='% of GMV' mean*f=comma8.0)  
              net_loss_m0  = 'Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
              cnt_esc_claim_m0 = 'ESC CLAIM' * (sum = 'Total Num'*f=comma10.0 colpctsum<cnt_esc_claim_m0>='% of esc claim' /*rowpctsum<cnt_defects> ='% of Defects'*/)  
			  /*cnt_defects ='Defect #'*(sum = 'Total Num'*f=comma10.0 colpctsum<cnt_defects>='% of defects' rowpctsum<cnt_txn> ='Defect rate' mean*f=comma8.0)   */                                                          
              /*&gross_loss  = 'Gross Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<&gross_loss> ='% of gross loss' rowpctsum<&gmv.>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) */			                            
            
			                
            )   
 tot_net_loss_m0='Net Loss Cnt'*f=comma8.0 			
                                                                                                                                                                                                                     
                          /Box="Num Tran/MOB" row=float RTS=25 /*misstext = '0'*/;  
						  
format orig_mob mobfmt. tot_net_loss_m0 lossf. tot_num_txn_m0 txnfmt.;	
where gmv_m0> &gmv_bar;					  
run;



/**** by seg,MOB ***/
proc tabulate data = raw.ebay_usar_analy_&ind missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  tot_gmv_m0 tot_num_txn_m0 seg orig_mob msfs_mob seg tot_net_loss_m0/style= [background = light bule];                                                                                                                                                                  
      var    net_loss_m0 gmv_m0 num_txn_m0 cnt_esc_claim_m0 /s=[background=light blue];                                   
                           
      table (seg=''*(orig_mob='' all) all=[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
			  /*cnt_txn  = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<cnt_txn> = '% of total weighted' ) */
			                                   
              num_txn_m0 = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              gmv_m0  = 'GMV '*(sum = 'Total Amount'*f=comma18.0 colpctsum<gmv_m0> ='% of GMV' mean*f=comma8.0)  
              net_loss_m0  = 'Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
              cnt_esc_claim_m0 = 'ESC CLAIM' * (sum = 'Total Num'*f=comma10.0 colpctsum<cnt_esc_claim_m0>='% of esc claim' /*rowpctsum<cnt_defects> ='% of Defects'*/)  
			  /*cnt_defects ='Defect #'*(sum = 'Total Num'*f=comma10.0 colpctsum<cnt_defects>='% of defects' rowpctsum<cnt_txn> ='Defect rate' mean*f=comma8.0)   */                                                          
              /*&gross_loss  = 'Gross Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<&gross_loss> ='% of gross loss' rowpctsum<&gmv.>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) */			                            
            
			                
            )   
 tot_net_loss_m0='Net Loss Cnt'*f=comma8.0 			
                                                                                                                                                                                                                     
                          /Box="Seg/MOB" row=float RTS=25 /*misstext = '0'*/;  
						  
format orig_mob mobfmt. tot_net_loss_m0 lossf.;	
where gmv_m0> &gmv_bar;					  
run;



/**** final two segment ***/

/**** by num tran Mob ***/
proc tabulate data = raw.ebay_usar_analy_&ind missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  tot_gmv_m0 tot_num_txn_m0 seg orig_mob msfs_mob seg tot_net_loss_m0/style= [background = light bule];                                                                                                                                                                  
      var    net_loss_m0 gmv_m0 num_txn_m0 cnt_esc_claim_m0 /s=[background=light blue];                                   
                           
      table ( tot_num_txn_m0=''*(orig_mob='' all) all=[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
			  /*cnt_txn  = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<cnt_txn> = '% of total weighted' ) */
			                                   
              num_txn_m0 = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              gmv_m0  = 'GMV '*(sum = 'Total Amount'*f=comma18.0 colpctsum<gmv_m0> ='% of GMV' mean*f=comma8.0)  
              net_loss_m0  = 'Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
              cnt_esc_claim_m0 = 'ESC CLAIM' * (sum = 'Total Num'*f=comma10.0 colpctsum<cnt_esc_claim_m0>='% of esc claim' /*rowpctsum<cnt_defects> ='% of Defects'*/)  
			  /*cnt_defects ='Defect #'*(sum = 'Total Num'*f=comma10.0 colpctsum<cnt_defects>='% of defects' rowpctsum<cnt_txn> ='Defect rate' mean*f=comma8.0)   */                                                          
              /*&gross_loss  = 'Gross Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<&gross_loss> ='% of gross loss' rowpctsum<&gmv.>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) */			                            
            
			                
            )   
 tot_net_loss_m0='Net Loss Cnt'*f=comma8.0 			
                                                                                                                                                                                                                     
                          /Box="Seg" row=float RTS=25 /*misstext = '0'*/;  
						  
format orig_mob mobfmtf. tot_net_loss_m0 lossf. tot_num_txn_m0 txnfmtf.;	
where gmv_m0>&gmv_bar;					  
run;



/**** by seg,MOB ***/
proc tabulate data = raw.ebay_usar_analy_&ind missing /*order=formatted s=[background=light blue]*/ format=pctpic9.1;                                                                                                              
      class  tot_gmv_m0 tot_num_txn_m0 seg orig_mob msfs_mob seg tot_net_loss_m0/style= [background = light bule];                                                                                                                                                                  
      var    net_loss_m0 gmv_m0 num_txn_m0 cnt_esc_claim_m0 /s=[background=light blue];                                   
                           
      table (seg=''*(orig_mob='' all) all=[label ='Total' s=[background=grey font_weight=bold]]),                                                                                                                          
             (n = [label ='# of Accounts' s=[background=light blue]]*f=comma8.0                                                                                                                                
              pctn =[label = "% of Total #" s=[background=light blue]] 
			  
			  /*cnt_txn  = 'weighted' *(sum = 'weighted Num'*f=comma8.0 colpctsum<cnt_txn> = '% of total weighted' ) */
			                                   
              num_txn_m0 = 'count tran'*(sum= 'tot num tran'*f=comma15.0)
              gmv_m0  = 'GMV '*(sum = 'Total Amount'*f=comma18.0 colpctsum<gmv_m0> ='% of GMV' mean*f=comma8.0)  
              net_loss_m0  = 'Net Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<net_loss_m0> ='% of net loss' rowpctsum<gmv_m0>='BPS'*f=bpspic.*[s=[background = yellow]] ) 
              cnt_esc_claim_m0 = 'ESC CLAIM' * (sum = 'Total Num'*f=comma10.0 colpctsum<cnt_esc_claim_m0>='% of esc claim' /*rowpctsum<cnt_defects> ='% of Defects'*/)  
			  /*cnt_defects ='Defect #'*(sum = 'Total Num'*f=comma10.0 colpctsum<cnt_defects>='% of defects' rowpctsum<cnt_txn> ='Defect rate' mean*f=comma8.0)   */                                                          
              /*&gross_loss  = 'Gross Loss'*(sum = 'Total Amount'*f=comma15.0 colpctsum<&gross_loss> ='% of gross loss' rowpctsum<&gmv.>='BPS'*f=bpspic.*[s=[background = yellow]] mean*f=comma8.0) */			                            
            
			                
            )   
 tot_net_loss_m0='Net Loss Cnt'*f=comma8.0 			
                                                                                                                                                                                                                     
                          /Box="Seg/mob" row=float RTS=25 /*misstext = '0'*/;  
						  
format orig_mob mobfmtf. tot_net_loss_m0 lossf.;	
where gmv_m0>&gmv_bar;					  
run;


ods html close;

%mend;
%summary(ind = jun,bar = 1k, gmv_bar=1000);
%summary(ind = nov,bar=1k, gmv_bar=1000);
%summary(ind = jun, bar=2k,gmv_bar=2000);
%summary(ind = nov, bar=2k,gmv_bar=2000);

