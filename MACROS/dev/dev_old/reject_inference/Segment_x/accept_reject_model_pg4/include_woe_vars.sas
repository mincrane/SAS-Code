**WOE VARIABLES REQUESTED;
  
/* STATE  */
if STATE  = "  " then wSTATE  = -0.000060981 ;
if STATE  = "ONED " then wSTATE  = 1.8079498286 ;
/* TIXIE  */
if TIXIE  = "  " then wTIXIE  = 0.0194608405 ;
if TIXIE  = "T " then wTIXIE  = -0.264090573 ;
/* BASECAT  */
if BASECAT  = "  " then wBASECAT  = -0.794327634 ;
if BASECAT  = "R " then wBASECAT  = 0.2157181531 ;
if BASECAT  = "S " then wBASECAT  = -0.155471385 ;
/* DATE_IND  */
if DATE_IND  = "D " then wDATE_IND  = -0.133087396 ;
if DATE_IND  = "I " then wDATE_IND  = 0.2437742907 ;
if DATE_IND  = "T " then wDATE_IND  = -0.173794029 ;
/* FINANCE  */
if FINANCE  = "  " then wFINANCE  = -0.036444339 ;
if FINANCE  = "R " then wFINANCE  = 0.390979942 ;
if FINANCE  = "S " then wFINANCE  = 0.5240893046 ;
/* COMPTYPE  */
if COMPTYPE  = "  " then wCOMPTYPE  = -0.138440052 ;
if COMPTYPE  = "G " then wCOMPTYPE  = -0.132664776 ;
if COMPTYPE  = "H " then wCOMPTYPE  = -0.02139874 ;
if COMPTYPE  = "I " then wCOMPTYPE  = 0.2446777731 ;
/* Decision  */
if Decision  = "  " then wDecision  = 3.5997092979 ;
if Decision  = "Approval " then wDecision  = 11.512559522 ;
if Decision  = "Decline " then wDecision  = -11.45971598 ;
if Decision  = "VT_Decline " then wDecision  = -8.552920015 ;
/* EAA_TYP  */
if EAA_TYP  = "  " then wEAA_TYP  = -0.007434187 ;
if EAA_TYP  = "A " then wEAA_TYP  = 0.511327053 ;
if EAA_TYP  = "B " then wEAA_TYP  = 0.4421469331 ;
if EAA_TYP  = "F " then wEAA_TYP  = 1.8079498286 ;
/* COND_IND  */
if COND_IND  = "  " then wCOND_IND  = -0.008596223 ;
if COND_IND  = "T " then wCOND_IND  = 0.5100155774 ;
if COND_IND  = "U " then wCOND_IND  = 0.4599647764 ;
if COND_IND  = "V " then wCOND_IND  = 0.3649092764 ;
if COND_IND  = "W " then wCOND_IND  = 0.0048377405 ;
/* HISTORY  */
if HISTORY  = "  " then wHISTORY  = -0.13121788 ;
if HISTORY  = "N " then wHISTORY  = 0.2204947078 ;
if HISTORY  = "O " then wHISTORY  = 0.1376257922 ;
if HISTORY  = "P " then wHISTORY  = -0.876803856 ;
if HISTORY  = "Q " then wHISTORY  = -0.951956578 ;
/* Confidence_Code  */
if Confidence_Code  = "04 " then wConfidence_Code  = -0.323456326 ;
if Confidence_Code  = "05 " then wConfidence_Code  = -0.420839149 ;
if Confidence_Code  = "06 " then wConfidence_Code  = -0.336130753 ;
if Confidence_Code  = "07 " then wConfidence_Code  = -0.180780282 ;
if Confidence_Code  = "08 " then wConfidence_Code  = -0.079125004 ;
if Confidence_Code  = "09 " then wConfidence_Code  = 0.1108804056 ;
if Confidence_Code  = "10 " then wConfidence_Code  = 0.2670406611 ;
/* STMT_TYP  */
if STMT_TYP  = "  " then wSTMT_TYP  = -0.013043787 ;
if STMT_TYP  = "A " then wSTMT_TYP  = 0.6562610777 ;
if STMT_TYP  = "B " then wSTMT_TYP  = 0.0233140167 ;
if STMT_TYP  = "H " then wSTMT_TYP  = -3.908529116 ;
if STMT_TYP  = "I " then wSTMT_TYP  = -0.750652571 ;
if STMT_TYP  = "X " then wSTMT_TYP  = -0.308819818 ;
if STMT_TYP  = "Y " then wSTMT_TYP  = 1.7706217234 ;
