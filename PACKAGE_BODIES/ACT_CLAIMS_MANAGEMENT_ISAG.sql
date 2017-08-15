--------------------------------------------------------
--  DDL for Package Body ACT_CLAIMS_MANAGEMENT_ISAG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_CLAIMS_MANAGEMENT_ISAG" 
is

  -------------------------
  procedure GENERATE_CLAIMS(aCUSTOMER                   number,
                            aACT_JOB_ID                 ACT_JOB.ACT_JOB_ID%type,
                            aACJ_CATALOGUE_DOCUMENT_ID  ACJ_CATALOGUE_DOCUMENT.ACJ_CATALOGUE_DOCUMENT_ID%type,
                            aPAR_REMIND_DATE            date,
                            aACS_SUB_SET_ID             ACS_SUB_SET.ACS_SUB_SET_ID%type,
                            aACC_AUX_NUMBER1            ACS_ACCOUNT.ACC_NUMBER%type,
                            aACC_AUX_NUMBER2            ACS_ACCOUNT.ACC_NUMBER%type,
                            aPAR_BLOCKED_DOCUMENT       number,
                            aCLAIMS                     number,
                            aCOVER                      number)
  is
  begin
    --On met le context du package standard sur 'ISAG' pour permettre d'éventuelles
    -- individualisations
    ACT_CLAIMS_MANAGEMENT.gCall_Context := 'ISAG';

    ACI_ISAG.Init_ISAG_Reminder(aACT_JOB_ID);

    ACT_CLAIMS_MANAGEMENT.GENERATE_CLAIMS(aCUSTOMER, aACT_JOB_ID, aACJ_CATALOGUE_DOCUMENT_ID, aPAR_REMIND_DATE, aACS_SUB_SET_ID, aACC_AUX_NUMBER1,
                                          aACC_AUX_NUMBER2, aPAR_BLOCKED_DOCUMENT, aCLAIMS, aCOVER);

    ACI_ISAG.Process_ISAG_Reminder(aACT_JOB_ID, aPAR_REMIND_DATE);

    --Remise du context en standard
    ACT_CLAIMS_MANAGEMENT.gCall_Context := null;
  exception when OTHERS then
    --Remise du context en standard
    ACT_CLAIMS_MANAGEMENT.gCall_Context := null;
    raise;
  end GENERATE_CLAIMS;

end ACT_CLAIMS_MANAGEMENT_ISAG;
