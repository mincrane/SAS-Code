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
