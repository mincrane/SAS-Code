**WOE VARIABLES REQUESTED;
  
/* STATE  */
if STATE  = "  " then wSTATE  = 0.0004359075 ;
if STATE  = "ONED " then wSTATE  = -3.774626943 ;
/* TIXIE  */
if TIXIE  = "  " then wTIXIE  = -0.003652755 ;
if TIXIE  = "T " then wTIXIE  = 0.0539312523 ;
/* BASECAT  */
if BASECAT  = "  " then wBASECAT  = 0.4156601121 ;
if BASECAT  = "R " then wBASECAT  = -0.00685396 ;
if BASECAT  = "S " then wBASECAT  = 0.004663489 ;
/* DATE_IND  */
if DATE_IND  = "D " then wDATE_IND  = -0.032564814 ;
if DATE_IND  = "I " then wDATE_IND  = -0.003470403 ;
if DATE_IND  = "T " then wDATE_IND  = 0.1181552948 ;
/* FINANCE  */
if FINANCE  = "  " then wFINANCE  = 0.0062627414 ;
if FINANCE  = "R " then wFINANCE  = -0.066148599 ;
if FINANCE  = "S " then wFINANCE  = 0.6268687565 ;
/* COMPTYPE  */
if COMPTYPE  = "  " then wCOMPTYPE  = -0.017143976 ;
if COMPTYPE  = "G " then wCOMPTYPE  = -0.007916284 ;
if COMPTYPE  = "H " then wCOMPTYPE  = 0.0070734943 ;
if COMPTYPE  = "I " then wCOMPTYPE  = 0.0237362872 ;
/* Decision  */
if Decision  = "  " then wDecision  = -0.343315075 ;
if Decision  = "Approval " then wDecision  = 0.011160968 ;
if Decision  = "Decline " then wDecision  = -0.036302437 ;
if Decision  = "VT_Decline " then wDecision  = 0.1016944326 ;
/* EAA_TYP  */
if EAA_TYP  = "  " then wEAA_TYP  = -0.001952192 ;
if EAA_TYP  = "A " then wEAA_TYP  = 0.1206200383 ;
if EAA_TYP  = "B " then wEAA_TYP  = 0.1079042547 ;
if EAA_TYP  = "F " then wEAA_TYP  = 1.6031857434 ;
/* COND_IND  */
if COND_IND  = "  " then wCOND_IND  = 0.0042985299 ;
if COND_IND  = "T " then wCOND_IND  = -0.32473568 ;
if COND_IND  = "U " then wCOND_IND  = -0.317572795 ;
if COND_IND  = "V " then wCOND_IND  = 0.2090910321 ;
if COND_IND  = "W " then wCOND_IND  = 0.0824756403 ;
/* HISTORY  */
if HISTORY  = "  " then wHISTORY  = 0.0050502292 ;
if HISTORY  = "N " then wHISTORY  = -0.017698778 ;
if HISTORY  = "O " then wHISTORY  = 0.0101681868 ;
if HISTORY  = "P " then wHISTORY  = 0.3000155441 ;
if HISTORY  = "Q " then wHISTORY  = -0.191535124 ;
/* Confidence_Code  */
if Confidence_Code  = "04 " then wConfidence_Code  = -0.239562099 ;
if Confidence_Code  = "05 " then wConfidence_Code  = -0.150352948 ;
if Confidence_Code  = "06 " then wConfidence_Code  = -0.08185976 ;
if Confidence_Code  = "07 " then wConfidence_Code  = -0.048440788 ;
if Confidence_Code  = "08 " then wConfidence_Code  = -0.065978194 ;
if Confidence_Code  = "09 " then wConfidence_Code  = 0.196800741 ;
if Confidence_Code  = "10 " then wConfidence_Code  = 0.1038204362 ;
/* STMT_TYP  */
if STMT_TYP  = "  " then wSTMT_TYP  = 0.002553062 ;
if STMT_TYP  = "A " then wSTMT_TYP  = -0.024932669 ;
if STMT_TYP  = "B " then wSTMT_TYP  = -0.260526175 ;
if STMT_TYP  = "H " then wSTMT_TYP  = 0.0594931018 ;
if STMT_TYP  = "I " then wSTMT_TYP  = -0.872061034 ;
if STMT_TYP  = "X " then wSTMT_TYP  = 2.5066300899 ;
if STMT_TYP  = "Y " then wSTMT_TYP  = 0.5154328853 ;
