**WOE VARIABLES REQUESTED;
  
/* cust_acct_type_code  */
if cust_acct_type_code  > .Z and cust_acct_type_code  <= 0.00 then wcust_acct_type_code  = -0.534011482 ;
if cust_acct_type_code  > 0  and cust_acct_type_code  <= 1.00 then wcust_acct_type_code  = 0.6637003065 ;
if cust_acct_type_code  > 1  and cust_acct_type_code  <= 2.00 then wcust_acct_type_code  = 0.1913051534 ;
if cust_acct_type_code  > 2.00 then wcust_acct_type_code  = 0;
/* amt_email_pmt_14d_cap  */
if amt_email_pmt_14d_cap  = . then wamt_email_pmt_14d_cap  = -1.284303371 ;
if amt_email_pmt_14d_cap  > .Z and amt_email_pmt_14d_cap  <= 0.00 then wamt_email_pmt_14d_cap  = 0.0849751211 ;
if amt_email_pmt_14d_cap  > 0  and amt_email_pmt_14d_cap  <= 54.16 then wamt_email_pmt_14d_cap  = 1.0553986299 ;
if amt_email_pmt_14d_cap  > 54.16  and amt_email_pmt_14d_cap  <= 2299.68 then wamt_email_pmt_14d_cap  = 1.3940410205 ;
if amt_email_pmt_14d_cap  > 2299.68 then wamt_email_pmt_14d_cap  = 0;
/* amt_rvsd_cap  */
if amt_rvsd_cap  > .Z and amt_rvsd_cap  <= 0.00 then wamt_rvsd_cap  = -0.218672672 ;
if amt_rvsd_cap  > 0  and amt_rvsd_cap  <= 3100.00 then wamt_rvsd_cap  = 1.0879347688 ;
if amt_rvsd_cap  > 3100  and amt_rvsd_cap  <= 172642.12 then wamt_rvsd_cap  = 1.6334674535 ;
if amt_rvsd_cap  > 172642.12 then wamt_rvsd_cap  = 0;
/* amt_txn_refund_l180d_cap  */
if amt_txn_refund_l180d_cap  > .Z and amt_txn_refund_l180d_cap  <= 0.00 then wamt_txn_refund_l180d_cap  = -0.124953817 ;
if amt_txn_refund_l180d_cap  > 0  and amt_txn_refund_l180d_cap  <= 151455.05 then wamt_txn_refund_l180d_cap  = 1.2490744841 ;
if amt_txn_refund_l180d_cap  > 151455.05 then wamt_txn_refund_l180d_cap  = 0;
/* amt_avg_balance_l60d_cap  */
if amt_avg_balance_l60d_cap  > .Z and amt_avg_balance_l60d_cap  <= 0.00 then wamt_avg_balance_l60d_cap  = -0.360456505 ;
if amt_avg_balance_l60d_cap  > 0  and amt_avg_balance_l60d_cap  <= 73.85 then wamt_avg_balance_l60d_cap  = 0.5150813364 ;
if amt_avg_balance_l60d_cap  > 73.85  and amt_avg_balance_l60d_cap  <= 218.07 then wamt_avg_balance_l60d_cap  = 0.3314037947 ;
if amt_avg_balance_l60d_cap  > 218.06666667  and amt_avg_balance_l60d_cap  <= 499.28 then wamt_avg_balance_l60d_cap  = 0.3855861865 ;
if amt_avg_balance_l60d_cap  > 499.28333333  and amt_avg_balance_l60d_cap  <= 1067.58 then wamt_avg_balance_l60d_cap  = 0.1009059844 ;
if amt_avg_balance_l60d_cap  > 1067.5833333  and amt_avg_balance_l60d_cap  <= 2397.00 then wamt_avg_balance_l60d_cap  = 0.050923735 ;
if amt_avg_balance_l60d_cap  > 2397  and amt_avg_balance_l60d_cap  <= 6774.75 then wamt_avg_balance_l60d_cap  = -0.084753908 ;
if amt_avg_balance_l60d_cap  > 6774.75  and amt_avg_balance_l60d_cap  <= 98819.35 then wamt_avg_balance_l60d_cap  = -0.300653498 ;
if amt_avg_balance_l60d_cap  > 98819.35 then wamt_avg_balance_l60d_cap  = 0;
/* amt_avg_balance_l14d_cap  */
if amt_avg_balance_l14d_cap  > .Z and amt_avg_balance_l14d_cap  <= 0.00 then wamt_avg_balance_l14d_cap  = -0.236498946 ;
if amt_avg_balance_l14d_cap  > 0  and amt_avg_balance_l14d_cap  <= 100.00 then wamt_avg_balance_l14d_cap  = 0.4337069478 ;
if amt_avg_balance_l14d_cap  > 100  and amt_avg_balance_l14d_cap  <= 392.86 then wamt_avg_balance_l14d_cap  = 0.4293375017 ;
if amt_avg_balance_l14d_cap  > 392.85714286  and amt_avg_balance_l14d_cap  <= 1002.86 then wamt_avg_balance_l14d_cap  = 0.1980057789 ;
if amt_avg_balance_l14d_cap  > 1002.8571429  and amt_avg_balance_l14d_cap  <= 2444.50 then wamt_avg_balance_l14d_cap  = 0.2104868677 ;
if amt_avg_balance_l14d_cap  > 2444.5  and amt_avg_balance_l14d_cap  <= 6742.71 then wamt_avg_balance_l14d_cap  = 0.0351590143 ;
if amt_avg_balance_l14d_cap  > 6742.7142857  and amt_avg_balance_l14d_cap  <= 127296.71 then wamt_avg_balance_l14d_cap  = -0.283336178 ;
if amt_avg_balance_l14d_cap  > 127296.71 then wamt_avg_balance_l14d_cap  = 0;
/* amt_ach_90d_cap  */
if amt_ach_90d_cap  = . then wamt_ach_90d_cap  = -0.081680956 ;
if amt_ach_90d_cap  > .Z and amt_ach_90d_cap  <= 5060.82 then wamt_ach_90d_cap  = 1.6567608032 ;
if amt_ach_90d_cap  > 5060.82 then wamt_ach_90d_cap  = 0;
/* amt_ach_14d_cap  */
if amt_ach_14d_cap  = . then wamt_ach_14d_cap  = -0.081680956 ;
if amt_ach_14d_cap  > .Z and amt_ach_14d_cap  <= 3964.87 then wamt_ach_14d_cap  = 1.6567608032 ;
if amt_ach_14d_cap  > 3964.87 then wamt_ach_14d_cap  = 0;
/* amt_ach_30d_cap  */
if amt_ach_30d_cap  = . then wamt_ach_30d_cap  = -0.081680956 ;
if amt_ach_30d_cap  > .Z and amt_ach_30d_cap  <= 2968.88 then wamt_ach_30d_cap  = 1.6567608032 ;
if amt_ach_30d_cap  > 2968.88 then wamt_ach_30d_cap  = 0;
/* amt_nsf_ach_14d_cap  */
if amt_nsf_ach_14d_cap  = . then wamt_nsf_ach_14d_cap  = -0.081680956 ;
if amt_nsf_ach_14d_cap  > .Z and amt_nsf_ach_14d_cap  <= 3246.80 then wamt_nsf_ach_14d_cap  = 1.6567608032 ;
if amt_nsf_ach_14d_cap  > 3246.80 then wamt_nsf_ach_14d_cap  = 0;
