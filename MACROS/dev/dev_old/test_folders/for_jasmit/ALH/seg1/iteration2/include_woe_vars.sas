**WOE VARIABLES REQUESTED;
  
/* amt_ach_14d_cap  */
if amt_ach_14d_cap  = . then wamt_ach_14d_cap  = -0.081680956 ;
if amt_ach_14d_cap  > .Z and amt_ach_14d_cap  <= 3964.87 then wamt_ach_14d_cap  = 1.6567608032 ;
if amt_ach_14d_cap  > 3964.87 then wamt_ach_14d_cap  = 0;
