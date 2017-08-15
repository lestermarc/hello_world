--------------------------------------------------------
--  DDL for Package Body ACT_PRC_MGM_TOT_BY_PERIOD
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_PRC_MGM_TOT_BY_PERIOD" 
is
  /**
  * Description Création d'une position de cumul analytique
  *   selon les paramètres données
  */
  procedure CreateMgmTotPosition(
    ioRecordId      in out ACT_MGM_TOT_BY_PERIOD.ACT_MGM_TOT_BY_PERIOD_ID%type
  , iPeriodId       in     ACT_MGM_TOT_BY_PERIOD.ACS_PERIOD_ID%type
  , iFinAccountId   in     ACT_MGM_TOT_BY_PERIOD.ACS_FINANCIAL_ACCOUNT_ID%type
  , iDivAccountId   in     ACT_MGM_TOT_BY_PERIOD.ACS_DIVISION_ACCOUNT_ID%type
  , iCPNAccountId   in     ACT_MGM_TOT_BY_PERIOD.ACS_CPN_ACCOUNT_ID%type
  , iCDAAccountId   in     ACT_MGM_TOT_BY_PERIOD.ACS_CDA_ACCOUNT_ID%type
  , iPFAccountId    in     ACT_MGM_TOT_BY_PERIOD.ACS_PF_ACCOUNT_ID%type
  , iPJAccountId    in     ACT_MGM_TOT_BY_PERIOD.ACS_PJ_ACCOUNT_ID%type
  , iQTYAccountId   in     ACT_MGM_TOT_BY_PERIOD.ACS_QTY_UNIT_ID%type
  , iDocRecordId    in     ACT_MGM_TOT_BY_PERIOD.DOC_RECORD_ID%type
  , iAmountLCD      in     ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_LC%type
  , iAmountLCC      in     ACT_MGM_TOT_BY_PERIOD.MTO_CREDIT_LC%type
  , iAmountFCD      in     ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_FC%type
  , iAmountFCC      in     ACT_MGM_TOT_BY_PERIOD.MTO_CREDIT_FC%type
  , iAmountEURD     in     ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_EUR%type
  , iAmountEURC     in     ACT_MGM_TOT_BY_PERIOD.MTO_CREDIT_EUR%type
  , iAmountQTYD     in     ACT_MGM_TOT_BY_PERIOD.MTO_QUANTITY_D%type
  , iAmountQTYC     in     ACT_MGM_TOT_BY_PERIOD.MTO_QUANTITY_C%type
  , iFFinCurrencyId in     ACT_MGM_TOT_BY_PERIOD.ACS_FINANCIAL_CURRENCY_ID%type
  , iLFinCurrencyId in     ACT_MGM_TOT_BY_PERIOD.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , iTypeCumul      in     ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type
  , iLevelTag       in     ACT_MGM_TOT_BY_PERIOD.A_RECLEVEL%type default null
  , iCreDate        in     ACT_MGM_TOT_BY_PERIOD.A_DATECRE%type default sysdate
  , iCreUser        in     ACT_MGM_TOT_BY_PERIOD.A_IDCRE%type default gUserIni
  )
  is
  begin
    if    (ioRecordId is null)
       or (ioRecordId = 0) then
      select INIT_ID_SEQ.nextval
        into ioRecordId
        from dual;
    end if;

    insert into ACT_MGM_TOT_BY_PERIOD
                (ACT_MGM_TOT_BY_PERIOD_ID
               , ACS_PERIOD_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_DIVISION_ACCOUNT_ID
               , ACS_CPN_ACCOUNT_ID
               , ACS_CDA_ACCOUNT_ID
               , ACS_PF_ACCOUNT_ID
               , ACS_PJ_ACCOUNT_ID
               , ACS_QTY_UNIT_ID
               , DOC_RECORD_ID
               , MTO_DEBIT_LC
               , MTO_CREDIT_LC
               , MTO_DEBIT_FC
               , MTO_CREDIT_FC
               , MTO_DEBIT_EUR
               , MTO_CREDIT_EUR
               , MTO_QUANTITY_D
               , MTO_QUANTITY_C
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , C_TYPE_CUMUL
               , A_RECLEVEL
               , A_DATECRE
               , A_IDCRE
                )
         values (ioRecordId
               , iPeriodId
               , iFinAccountId
               , iDivAccountId
               , iCPNAccountId
               , iCDAAccountId
               , iPFAccountId
               , iPJAccountId
               , iQTYAccountId
               , iDocRecordId
               , iAmountLCD
               , iAmountLCC
               , nvl(decode(iFFinCurrencyId, iLFinCurrencyId, 0, iAmountFCD), 0)
               , nvl(decode(iFFinCurrencyId, iLFinCurrencyId, 0, iAmountFCC), 0)
               , iAmountEURD
               , iAmountEURC
               , iAmountQTYD
               , iAmountQTYC
               , iFFinCurrencyId
               , iLFinCurrencyId
               , iTypeCumul
               , iLevelTag
               , iCreDate
               , iCreUser
                );

  end CreateMgmTotPosition;
begin
  gUserIni  := PCS.PC_I_LIB_SESSION.GetUserIni;
end ACT_PRC_MGM_TOT_BY_PERIOD;
