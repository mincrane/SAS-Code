**WOE VARIABLES REQUESTED;
  
/* amt_ach_14d_cap  */
if amt_ach_14d_cap  = . then wamt_ach_14d_cap  = -0.081680956 ;
if amt_ach_14d_cap  > .Z and amt_ach_14d_cap  <= 3964.87 then wamt_ach_14d_cap  = 1.6567608032 ;
if amt_ach_14d_cap  > 3964.87 then wamt_ach_14d_cap  = 0;
/* cust_acct_type_code  */
if cust_acct_type_code  > .Z and cust_acct_type_code  <= 0.00 then wcust_acct_type_code  = -0.534011482 ;
if cust_acct_type_code  > 0  and cust_acct_type_code  <= 1.00 then wcust_acct_type_code  = 0.6637003065 ;
if cust_acct_type_code  > 1  and cust_acct_type_code  <= 2.00 then wcust_acct_type_code  = 0.1913051534 ;
if cust_acct_type_code  > 2.00 then wcust_acct_type_code  = 0;
/* amt_gtpv_l3d_cap  */
if amt_gtpv_l3d_cap  > .Z and amt_gtpv_l3d_cap  <= 0.00 then wamt_gtpv_l3d_cap  = -0.136642204 ;
if amt_gtpv_l3d_cap  > 0  and amt_gtpv_l3d_cap  <= 33223.00 then wamt_gtpv_l3d_cap  = 1.2282472103 ;
if amt_gtpv_l3d_cap  > 33223.00 then wamt_gtpv_l3d_cap  = 0;
/* amt_email_pmt_14d_cap  */
if amt_email_pmt_14d_cap  = . then wamt_email_pmt_14d_cap  = -1.284303371 ;
if amt_email_pmt_14d_cap  > .Z and amt_email_pmt_14d_cap  <= 0.00 then wamt_email_pmt_14d_cap  = 0.0849751211 ;
if amt_email_pmt_14d_cap  > 0  and amt_email_pmt_14d_cap  <= 54.16 then wamt_email_pmt_14d_cap  = 1.0553986299 ;
if amt_email_pmt_14d_cap  > 54.16  and amt_email_pmt_14d_cap  <= 2299.68 then wamt_email_pmt_14d_cap  = 1.3940410205 ;
if amt_email_pmt_14d_cap  > 2299.68 then wamt_email_pmt_14d_cap  = 0;
