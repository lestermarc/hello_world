--------------------------------------------------------
--  DDL for Package Body ACT_MGT_MGM_TOT_BY_PERIOD
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_MGT_MGM_TOT_BY_PERIOD" 
is
  procedure MgmTotalWrite(
    iCumulType   in ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type
  , iPeriodId    in ACT_MGM_TOT_BY_PERIOD.ACS_PERIOD_ID%type
  , iFCurrencyId in ACT_MGM_TOT_BY_PERIOD.ACS_FINANCIAL_CURRENCY_ID%type
  , iLCurrencyId in ACT_MGM_TOT_BY_PERIOD.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , iCpnAccId    in ACT_MGM_TOT_BY_PERIOD.ACS_CPN_ACCOUNT_ID%type
  , iCdaAccId    in ACT_MGM_TOT_BY_PERIOD.ACS_CDA_ACCOUNT_ID%type
  , iPfAccId     in ACT_MGM_TOT_BY_PERIOD.ACS_PF_ACCOUNT_ID%type
  , iQtyUnitId   in ACT_MGM_TOT_BY_PERIOD.ACS_QTY_UNIT_ID%type
  , iPjAccId     in ACT_MGM_TOT_BY_PERIOD.ACS_PJ_ACCOUNT_ID%type
  , iFinAccId    in ACT_MGM_TOT_BY_PERIOD.ACS_FINANCIAL_ACCOUNT_ID%type
  , iDivAccId    in ACT_MGM_TOT_BY_PERIOD.ACS_DIVISION_ACCOUNT_ID%type
  , iDocRecordId in ACT_MGM_TOT_BY_PERIOD.DOC_RECORD_ID%type
  , iAmountLCD   in ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_LC%type
  , iAmountLCC   in ACT_MGM_TOT_BY_PERIOD.MTO_CREDIT_LC%type
  , iAmountFCD   in ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_FC%type
  , iAmountFCC   in ACT_MGM_TOT_BY_PERIOD.MTO_CREDIT_FC%type
  , iAmountEUD   in ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_EUR%type
  , iAmountEUC   in ACT_MGM_TOT_BY_PERIOD.MTO_CREDIT_EUR%type
  , iQuantityD   in ACT_MGM_TOT_BY_PERIOD.MTO_QUANTITY_D%type
  , iQuantityC   in ACT_MGM_TOT_BY_PERIOD.MTO_QUANTITY_C%type
  , iCpnReportMgt in number default 0
  )
  is
    lRecordId  ACT_MGM_TOT_BY_PERIOD.ACT_MGM_TOT_BY_PERIOD_id%type;
    lPeriodTyp ACS_PERIOD.C_TYPE_PERIOD%type;
    lAmountLCD ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_LC%type;
    lAmountLCC ACT_MGM_TOT_BY_PERIOD.MTO_CREDIT_LC%type;
    lAmountFCD ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_FC%type;
    lAmountFCC ACT_MGM_TOT_BY_PERIOD.MTO_CREDIT_FC%type;
    lAmountEUD ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_EUR%type;
    lAmountEUC ACT_MGM_TOT_BY_PERIOD.MTO_CREDIT_EUR%type;
    lQuantityD ACT_MGM_TOT_BY_PERIOD.mto_quantity_d%type;
    lQuantityC ACT_MGM_TOT_BY_PERIOD.mto_quantity_c%type;

    --------
    function GetC_TYPE_PERIOD(iAcsPeriodId in ACS_PERIOD.ACS_PERIOD_ID%type)
      return ACS_PERIOD.C_TYPE_PERIOD%type
    is
      lResult ACS_PERIOD.C_TYPE_PERIOD%type;
    begin
      select max(C_TYPE_PERIOD)
        into lResult
        from ACS_PERIOD
       where ACS_PERIOD_ID = iAcsPeriodId;

      return lResult;
    end GetC_TYPE_PERIOD;

    --------
    -- Détermination ACT_MGM_TOT_BY_PERIOD_ID en fct de : Période, Monnaies, Cptes..., Type cumul
    function GetTotalByPeriodId(
      iPerId      in     ACT_MGM_TOT_BY_PERIOD.ACS_PERIOD_ID%type
    , iPerTyp     in     ACS_PERIOD.C_TYPE_PERIOD%type
    , iFCurrId    in     ACT_MGM_TOT_BY_PERIOD.ACS_FINANCIAL_CURRENCY_ID%type
    , iLCurrId    in     ACT_MGM_TOT_BY_PERIOD.ACS_ACS_FINANCIAL_CURRENCY_ID%type
    , iCpnId      in     ACT_MGM_TOT_BY_PERIOD.ACS_CPN_ACCOUNT_ID%type
    , iCdaId      in     ACT_MGM_TOT_BY_PERIOD.ACS_CDA_ACCOUNT_ID%type
    , iPfId       in     ACT_MGM_TOT_BY_PERIOD.ACS_PF_ACCOUNT_ID%type
    , iQtyId      in     ACT_MGM_TOT_BY_PERIOD.ACS_QTY_UNIT_ID%type
    , iPjId       in     ACT_MGM_TOT_BY_PERIOD.ACS_PJ_ACCOUNT_ID%type
    , iFinId      in     ACT_MGM_TOT_BY_PERIOD.ACS_FINANCIAL_ACCOUNT_ID%type
    , iDivId      in     ACT_MGM_TOT_BY_PERIOD.ACS_DIVISION_ACCOUNT_ID%type
    , iTypeCumul  in     ACT_MGM_TOT_BY_PERIOD.C_TYPE_CUMUL%type
    , iDocRecId   in     ACT_MGM_TOT_BY_PERIOD.DOC_RECORD_ID%type
    , iLCD_Amount in out ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_LC%type
    , iLCC_Amount in out ACT_MGM_TOT_BY_PERIOD.MTO_CREDIT_LC%type
    , iFCD_Amount in out ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_FC%type
    , iFCC_Amount in out ACT_MGM_TOT_BY_PERIOD.MTO_CREDIT_FC%type
    , iEUD_Amount in out ACT_MGM_TOT_BY_PERIOD.MTO_DEBIT_EUR%type
    , iEUC_Amount in out ACT_MGM_TOT_BY_PERIOD.MTO_CREDIT_EUR%type
    , iQtyD       in out ACT_MGM_TOT_BY_PERIOD.MTO_QUANTITY_D%type
    , iQtyC       in out ACT_MGM_TOT_BY_PERIOD.MTO_QUANTITY_C%type
    )
      return ACT_MGM_TOT_BY_PERIOD.ACT_MGM_TOT_BY_PERIOD_ID%type
    is
      lRecId ACT_MGM_TOT_BY_PERIOD.ACT_MGM_TOT_BY_PERIOD_ID%type;
----
    begin
      begin
        select     ACT_MGM_TOT_BY_PERIOD_ID
                 , nvl(decode(iPerTyp
                            , '1', decode(sign(MTO_DEBIT_LC - MTO_CREDIT_LC + iLCD_Amount - iLCC_Amount)
                                        , 1, MTO_DEBIT_LC - MTO_CREDIT_LC + iLCD_Amount - iLCC_Amount
                                        , 0
                                         )
                            , iLCD_Amount
                             )
                     , 0
                      )
                 , nvl(decode(iPerTyp
                            , '1', decode(sign(MTO_DEBIT_LC - MTO_CREDIT_LC + iLCD_Amount - iLCC_Amount)
                                        , -1, abs(MTO_DEBIT_LC - MTO_CREDIT_LC + iLCD_Amount - iLCC_Amount)
                                        , 0
                                         )
                            , iLCC_Amount
                             )
                     , 0
                      )
                 , nvl(decode(iPerTyp
                            , '1', decode(sign(MTO_DEBIT_FC - MTO_CREDIT_FC + iFCD_Amount - iFCC_Amount)
                                        , 1, MTO_DEBIT_FC - MTO_CREDIT_FC + iFCD_Amount - iFCC_Amount
                                        , 0
                                         )
                            , iFCD_Amount
                             )
                     , 0
                      )
                 , nvl(decode(iPerTyp
                            , '1', decode(sign(MTO_DEBIT_FC - MTO_CREDIT_FC + iFCD_Amount - iFCC_Amount)
                                        , -1, abs(MTO_DEBIT_FC - MTO_CREDIT_FC + iFCD_Amount - iFCC_Amount)
                                        , 0
                                         )
                            , iFCC_Amount
                             )
                     , 0
                      )
                 , nvl(decode(iPerTyp
                            , '1', decode(sign(MTO_DEBIT_EUR - MTO_CREDIT_EUR + iEUD_Amount - iEUC_Amount)
                                        , 1, MTO_DEBIT_EUR - MTO_CREDIT_EUR + iEUD_Amount - iEUC_Amount
                                        , 0
                                         )
                            , iEUD_Amount
                             )
                     , 0
                      )
                 , nvl(decode(iPerTyp
                            , '1', decode(sign(MTO_DEBIT_EUR - MTO_CREDIT_EUR + iEUD_Amount - iEUC_Amount)
                                        , -1, abs(MTO_DEBIT_EUR - MTO_CREDIT_EUR + iEUD_Amount - iEUC_Amount)
                                        , 0
                                         )
                            , iEUC_Amount
                             )
                     , 0
                      )
                 , nvl(decode(iPerTyp
                            , '1', decode(sign(MTO_QUANTITY_D - MTO_QUANTITY_C + iQtyD - iQtyC)
                                        , 1, MTO_QUANTITY_D - MTO_QUANTITY_C + iQtyD - iQtyC
                                        , 0
                                         )
                            , iQtyD
                             )
                     , 0
                      )
                 , nvl(decode(iPerTyp
                            , '1', decode(sign(MTO_QUANTITY_D - MTO_QUANTITY_C + iQtyD - iQtyC)
                                        , -1, abs(MTO_QUANTITY_D - MTO_QUANTITY_C + iQtyD - iQtyC)
                                        , 0
                                         )
                            , iQtyC
                             )
                     , 0
                      )
              into lRecId
                 , iLCD_Amount
                 , iLCC_Amount
                 , iFCD_Amount
                 , iFCC_Amount
                 , iEUD_Amount
                 , iEUC_Amount
                 , iQtyD
                 , iQtyC
              from ACT_MGM_TOT_BY_PERIOD
             where ACS_PERIOD_ID = iPerId
               and ACS_FINANCIAL_CURRENCY_ID = iFCurrId
               and ACS_ACS_FINANCIAL_CURRENCY_ID = iLCurrId
               and ACS_CPN_ACCOUNT_ID = iCpnId
               and (   ACS_CDA_ACCOUNT_ID = iCdaId
                    or (    iCdaId is null
                        and ACS_CDA_ACCOUNT_ID is null) )
               and (   ACS_PF_ACCOUNT_ID = iPfId
                    or (    iPfId is null
                        and ACS_PF_ACCOUNT_ID is null) )
               and (   ACS_PJ_ACCOUNT_ID = iPjId
                    or (    iPjId is null
                        and ACS_PJ_ACCOUNT_ID is null) )
               and (   ACS_QTY_UNIT_ID = iQtyId
                    or (    iQtyId is null
                        and ACS_QTY_UNIT_ID is null) )
               and (   ACS_FINANCIAL_ACCOUNT_ID = iFinId
                    or (    iFinId is null
                        and ACS_FINANCIAL_ACCOUNT_ID is null) )
               and (   ACS_DIVISION_ACCOUNT_ID = iDivId
                    or (    iDivId is null
                        and ACS_DIVISION_ACCOUNT_ID is null) )
               and (   DOC_RECORD_ID = iDocRecId
                    or (    iDocRecId is null
                        and DOC_RECORD_ID is null) )
               and C_TYPE_CUMUL = iTypeCumul
        for update;
      exception
        when others then
          lRecId  := null;
      end;

      if     lRecId is null
         and iPerTyp = '1' then
        if (iLCD_Amount - iLCC_Amount) > 0 then
          iLCD_Amount  := iLCD_Amount - iLCC_Amount;
          iLCC_Amount  := 0;
        else
          iLCC_Amount  := abs(iLCD_Amount - iLCC_Amount);
          iLCD_Amount  := 0;
        end if;

        if (iFCD_Amount - iFCC_Amount) > 0 then
          iFCD_Amount  := iFCD_Amount - iFCC_Amount;
          iFCC_Amount  := 0;
        else
          iFCC_Amount  := abs(iFCD_Amount - iFCC_Amount);
          iFCD_Amount  := 0;
        end if;

        if (iEUD_Amount - iEUC_Amount) > 0 then
          iEUD_Amount  := iEUD_Amount - iEUC_Amount;
          iEUC_Amount  := 0;
        else
          iEUC_Amount  := abs(iEUD_Amount - iEUC_Amount);
          iEUD_Amount  := 0;
        end if;

        if (iQtyD - iQtyC) > 0 then
          iQtyD  := iQtyD - iQtyC;
          iQtyC  := 0;
        else
          iQtyC  := abs(iQtyD - iQtyC);
          iQtyD  := 0;
        end if;
      end if;

      return lRecId;
    end GetTotalByPeriodId;
  -----
  begin
    if     not(iPeriodId is null)
       and ( not(    iCdaAccId is null
                 and iPfAccId is null
                 and iPjAccId is null
                 and iDocRecordId is null) or
            (iCpnReportMgt = 1)
            )  then
      lPeriodTyp  := GetC_TYPE_PERIOD(iPeriodId);
      lAmountLCD  := iAmountLCD;
      lAmountLCC  := iAmountLCC;
      lAmountFCD  := iAmountFCD;
      lAmountFCC  := iAmountFCC;
      lAmountEUD  := iAmountEUD;
      lAmountEUC  := iAmountEUC;
      lQuantityD  := iQuantityD;
      lQuantityC  := iQuantityC;
      lRecordId   :=
        GetTotalByPeriodId(iPeriodId
                         , lPeriodTyp
                         , iFCurrencyId
                         , iLCurrencyId
                         , iCpnAccId
                         , iCdaAccId
                         , iPfAccId
                         , iQtyUnitId
                         , iPjAccId
                         , iFinAccId
                         , iDivAccId
                         , iCumulType
                         , iDocRecordId
                         , lAmountLCD
                         , lAmountLCC
                         , lAmountFCD
                         , lAmountFCC
                         , lAmountEUD
                         , lAmountEUC
                         , lQuantityD
                         , lQuantityC
                          );

      if lRecordId is null then
        ACT_PRC_MGM_TOT_BY_PERIOD.CreateMgmTotPosition(lRecordId
                                                     , iPeriodId
                                                     , iFinAccId
                                                     , iDivAccId
                                                     , iCpnAccId
                                                     , iCdaAccId
                                                     , iPfAccId
                                                     , iPjAccId
                                                     , iQtyUnitId
                                                     , iDocRecordId
                                                     , nvl(lAmountLCD, 0)
                                                     , nvl(lAmountLCC, 0)
                                                     , nvl(lAmountFCD, 0)
                                                     , nvl(lAmountFCC, 0)
                                                     , nvl(lAmountEUD, 0)
                                                     , nvl(lAmountEUC, 0)
                                                     , nvl(lQuantityD, 0)
                                                     , nvl(lQuantityC, 0)
                                                     , iFCurrencyId
                                                     , iLCurrencyId
                                                     , iCumulType
                                                      );
      else
        if lPeriodTyp = '1' then
          update ACT_MGM_TOT_BY_PERIOD
             set MTO_DEBIT_LC = nvl(lAmountLCD, 0)
               , MTO_CREDIT_LC = nvl(lAmountLCC, 0)
               , MTO_DEBIT_FC = nvl(decode(iFCurrencyId, iLCurrencyId, 0, lAmountFCD), 0)
               , MTO_CREDIT_FC = nvl(decode(iFCurrencyId, iLCurrencyId, 0, lAmountFCC), 0)
               , MTO_DEBIT_EUR = nvl(lAmountEUD, 0)
               , MTO_CREDIT_EUR = nvl(lAmountEUC, 0)
               , MTO_QUANTITY_D = nvl(lQuantityD, 0)
               , MTO_QUANTITY_C = nvl(lQuantityC, 0)
               , A_DATEMOD = sysdate
               , A_IDMOD = gUserIni
           where ACT_MGM_TOT_BY_PERIOD_ID = lRecordId;
        else
          update ACT_MGM_TOT_BY_PERIOD
             set MTO_DEBIT_LC = nvl(MTO_DEBIT_LC, 0) + nvl(lAmountLCD, 0)
               , MTO_CREDIT_LC = nvl(MTO_CREDIT_LC, 0) + nvl(lAmountLCC, 0)
               , MTO_DEBIT_FC = nvl(MTO_DEBIT_FC, 0) + nvl(decode(iFCurrencyId, iLCurrencyId, 0, lAmountFCD), 0)
               , MTO_CREDIT_FC = nvl(MTO_CREDIT_FC, 0) + nvl(decode(iFCurrencyId, iLCurrencyId, 0, lAmountFCC), 0)
               , MTO_DEBIT_EUR = nvl(MTO_DEBIT_EUR, 0) + nvl(lAmountEUD, 0)
               , MTO_CREDIT_EUR = nvl(MTO_CREDIT_EUR, 0) + nvl(lAmountEUC, 0)
               , MTO_QUANTITY_D = nvl(MTO_QUANTITY_D, 0) + nvl(lQuantityD, 0)
               , MTO_QUANTITY_C = nvl(MTO_QUANTITY_C, 0) + nvl(lQuantityC, 0)
               , A_DATEMOD = sysdate
               , A_IDMOD = gUserIni
           where ACT_MGM_TOT_BY_PERIOD_ID = lRecordId;
        end if;
      end if;
    end if;
  end MgmTotalWrite;
begin
  gUserIni  := PCS.PC_I_LIB_SESSION.GetUserIni;
end ACT_MGT_MGM_TOT_BY_PERIOD;
