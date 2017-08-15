--------------------------------------------------------
--  DDL for Package Body ACR_FINANCIAL_CTRL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACR_FINANCIAL_CTRL" 
is
  /**
  * function GetEndPeriodDate
  * Description
  *  Retourne la période active pour une date donnée
  */
  function GetEndPeriodDate(aDate in date)
    return date
  is
    EndDate date;
  begin
    select max(PER_END_DATE)
      into EndDate
      from ACS_PERIOD
     where trunc(aDate) between PER_START_DATE and PER_END_DATE
       and C_TYPE_PERIOD = '2';

    return trunc(EndDate);
  end GetEndPeriodDate;

  /**
  * procedure NewCtrl
  * Description
  *  Ajout d'un nouveau contrôle
  */
  procedure NewCtrl(
    pCTR_DATE                     in     ACR_CTRL.CTR_DATE%type
  , pCTR_DESCR                    in     ACR_CTRL.CTR_DESCR%type
  , pACR_CTRL_ID                  in out ACR_CTRL.ACR_CTRL_ID%type
  , pCTR_UNBALANCED_EXPIRY        in     ACR_CTRL.CTR_UNBALANCED_EXPIRY%type
  , pCTR_NO_EXPIRY                in     ACR_CTRL.CTR_NO_EXPIRY%type
  , pCTR_UNBALANCED_TOT           in     ACR_CTRL.CTR_UNBALANCED_TOT%type
  , pCTR_NO_PARTNER               in     ACR_CTRL.CTR_NO_PARTNER%type
  , pCTR_ADVANCED_PAYMENT         in     ACR_CTRL.CTR_ADVANCED_PAYMENT%type
  , pCTR_IMP_DOC_PERIODS          in     ACR_CTRL.CTR_IMP_DOC_PERIODS%type
  , pCTR_DEBIT_CREDIT             in     ACR_CTRL.CTR_DEBIT_CREDIT%type
  , pCTR_IMP_TAX_BREAKDOWN        in     ACR_CTRL.CTR_IMP_TAX_BREAKDOWN%type
  , pCTR_AUX_ACC_PAYMENT_INVOICE  in     ACR_CTRL.CTR_AUX_ACC_PAYMENT_INVOICE%type
  , pCTR_COLL_ACC_PAYMENT_INVOICE in     ACR_CTRL.CTR_COLL_ACC_PAYMENT_INVOICE%type
  )
  is
    vEndPeriodDate date;
  begin
    vEndPeriodDate  := ACR_FINANCIAL_CTRL.GetEndPeriodDate(pCTR_DATE);

    select INIT_ID_SEQ.nextval
      into pACR_CTRL_ID
      from dual;

    insert into ACR_CTRL
                (ACR_CTRL_ID
               , CTR_DESCR
               , CTR_DATE
               , CTR_UNBALANCED_EXPIRY
               , CTR_NO_EXPIRY
               , CTR_UNBALANCED_TOT
               , CTR_NO_PARTNER
               , CTR_ADVANCED_PAYMENT
               , CTR_IMP_DOC_PERIODS
               , CTR_DEBIT_CREDIT
               , CTR_IMP_TAX_BREAKDOWN
               , CTR_AUX_ACC_PAYMENT_INVOICE
               , CTR_COLL_ACC_PAYMENT_INVOICE
               , A_DATECRE
               , A_IDCRE
                )
         values (pACR_CTRL_ID
               , pCTR_DESCR
               , vEndPeriodDate
               , pCTR_UNBALANCED_EXPIRY
               , pCTR_NO_EXPIRY
               , pCTR_UNBALANCED_TOT
               , pCTR_NO_PARTNER
               , pCTR_ADVANCED_PAYMENT
               , pCTR_IMP_DOC_PERIODS
               , pCTR_DEBIT_CREDIT
               , pCTR_IMP_TAX_BREAKDOWN
               , pCTR_AUX_ACC_PAYMENT_INVOICE
               , pCTR_COLL_ACC_PAYMENT_INVOICE
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end NewCtrl;

  /**
  * procedure SubSetCtrl
  * Description
  *  Contrôle d'un sous-ensemble, à une date
  */
  procedure SubSetCtrl(
    pACR_CTRL_ID                  in ACR_CTRL.ACR_CTRL_ID%type
  , pCTR_DATE                     in ACR_CTRL.CTR_DATE%type
  , pACS_SUB_SET_ID               in ACR_CTRL_SUB_SET.ACS_SUB_SET_ID%type
  , pCTR_UNBALANCED_EXPIRY        in ACR_CTRL.CTR_UNBALANCED_EXPIRY%type
  , pCTR_NO_EXPIRY                in ACR_CTRL.CTR_NO_EXPIRY%type
  , pCTR_UNBALANCED_TOT           in ACR_CTRL.CTR_UNBALANCED_TOT%type
  , pCTR_NO_PARTNER               in ACR_CTRL.CTR_NO_PARTNER%type
  , pCTR_ADVANCED_PAYMENT         in ACR_CTRL.CTR_ADVANCED_PAYMENT%type
  , pCTR_IMP_DOC_PERIODS          in ACR_CTRL.CTR_IMP_DOC_PERIODS%type
  , pCTR_DEBIT_CREDIT             in ACR_CTRL.CTR_DEBIT_CREDIT%type
  , pCTR_IMP_TAX_BREAKDOWN        in ACR_CTRL.CTR_IMP_TAX_BREAKDOWN%type
  , pCTR_AUX_ACC_PAYMENT_INVOICE  in ACR_CTRL.CTR_AUX_ACC_PAYMENT_INVOICE%type
  , pCTR_COLL_ACC_PAYMENT_INVOICE in ACR_CTRL.CTR_COLL_ACC_PAYMENT_INVOICE%type
  )
  is
    vCtrlSubSetId      ACR_CTRL_SUB_SET.ACR_CTRL_SUB_SET_ID%type;
    vErrorCount        number(12);
    vEndPeriodDate     date;
    vC_SUB_SET         ACS_SUB_SET.C_SUB_SET%type;
    vStartExerciceDate ACS_FINANCIAL_YEAR.FYE_START_DATE%type;
    vEndExerciceDate   ACS_FINANCIAL_YEAR.FYE_END_DATE%type;
  begin
    vEndPeriodDate  := ACR_FINANCIAL_CTRL.GetEndPeriodDate(pCTR_DATE);

    select nvl(max(FYE_START_DATE), trunc(sysdate) )
         , nvl(max(FYE_END_DATE), trunc(sysdate) )
      into vStartExerciceDate
         , vEndExerciceDate
      from ACS_FINANCIAL_YEAR
     where pCTR_DATE between FYE_START_DATE and FYE_END_DATE;

    select INIT_ID_SEQ.nextval
      into vCtrlSubSetId
      from dual;

    insert into ACR_CTRL_SUB_SET
                (ACR_CTRL_SUB_SET_ID
               , ACR_CTRL_ID
               , ACS_SUB_SET_ID
               , SUB_OK
               , A_DATECRE
               , A_IDCRE
                )
         values (vCtrlSubSetId
               , pACR_CTRL_ID
               , pACS_SUB_SET_ID
               , 1
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    vC_SUB_SET      := ACS_FUNCTION.GetSubSetOfSubSet(pACS_SUB_SET_ID);

    if vC_SUB_SET in('REC', 'PAY') then
      PartnerAccountsCtrl(vCtrlSubSetId
                        , vStartExerciceDate
                        , vEndPeriodDate   -- => fin de la période
                        , pACS_SUB_SET_ID
                        , pCTR_UNBALANCED_EXPIRY
                        , pCTR_NO_EXPIRY
                        , pCTR_UNBALANCED_TOT
                        , pCTR_ADVANCED_PAYMENT
                         );

      if (pCTR_NO_PARTNER = 1) then
        -- Partenaire manque : C_CTRL_CODE = '03'
        NoPartnerCtrl(vCtrlSubSetId, vStartExerciceDate, vEndPeriodDate, pACS_SUB_SET_ID);   --=> fin de la période
      end if;

      if pCTR_AUX_ACC_PAYMENT_INVOICE = 1 then
        AuxAccPaymentInvoiceCtrl(vCtrlSubSetId, vStartExerciceDate, vEndExerciceDate, pACS_SUB_SET_ID);
      end if;

      if pCTR_COLL_ACC_PAYMENT_INVOICE = 1 then
        CollAccPaymentInvoiceCtrl(vCtrlSubSetId, vStartExerciceDate, vEndExerciceDate, pACS_SUB_SET_ID);
      end if;
    elsif(vC_SUB_SET = 'ACC') then
      if (pCTR_UNBALANCED_TOT = 1) then
        FinAccountCtrl(vCtrlSubSetId, vStartExerciceDate, vEndPeriodDate);   -- => fin de la période
      end if;

      if pCTR_IMP_DOC_PERIODS = 1 then
        ImpDocumentPeriodsCtrl(vCtrlSubSetId, vStartExerciceDate, vEndExerciceDate);
      end if;

      if pCTR_DEBIT_CREDIT = 1 then
        DocumentAmountsCtrl(vCtrlSubSetId, vStartExerciceDate, vEndExerciceDate);
      end if;
    elsif(vC_SUB_SET = 'CPN') then
      if (pCTR_UNBALANCED_TOT = 1) then
        CpnAccountCtrl(vCtrlSubSetId, vStartExerciceDate, vEndPeriodDate);   -- => fin de la période
      end if;
    elsif vC_SUB_SET = 'VAT' then
      if pCTR_IMP_TAX_BREAKDOWN = 1 then
        ImpTaxBreakdownCtrl(vCtrlSubSetId, vStartExerciceDate, vEndExerciceDate);
      end if;
    end if;

    select count(ACR_CTRL_DETAIL_ID)
      into vErrorCount
      from ACR_CTRL_DETAIL
     where ACR_CTRL_SUB_SET_ID = vCtrlSubSetId;

    if vErrorCount > 0 then
      update ACR_CTRL_SUB_SET
         set SUB_OK = 0
       where ACR_CTRL_SUB_SET_ID = vCtrlSubSetId;
    end if;
  end SubSetCtrl;

  /**
  * procedure ImpDocumentPeriodsCtrl
  * Description
  *  Contrôle que les périodes du documents correspondent aux périodes des imputations
  */
  procedure ImpDocumentPeriodsCtrl(
    pACR_CTRL_SUB_SET_ID in ACR_CTRL_SUB_SET.ACR_CTRL_SUB_SET_ID%type
  , pFYE_START_DATE      in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
  , pFYE_END_DATE        in ACS_FINANCIAL_YEAR.FYE_END_DATE%type
  )
  is
  begin
    for tplError in (select DOC.ACT_DOCUMENT_ID
                          , IMP.ACS_PERIOD_ID
                          , IMP.ACS_FINANCIAL_ACCOUNT_ID
                          , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID   --MB
                          , IMP.ACS_FINANCIAL_CURRENCY_ID   --ME
                          , IMP.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
                          , IMP.IMF_AMOUNT_LC
                          , IMP.IMF_AMOUNT_FC
                       from (select   count(distinct(ACS_PERIOD_ID) ) NBPER
                                    , ACT_DOCUMENT_ID
                                    , ACS_PERIOD_ID
                                    , ACS_FINANCIAL_ACCOUNT_ID
                                    , ACS_ACS_FINANCIAL_CURRENCY_ID   --MB
                                    , ACS_FINANCIAL_CURRENCY_ID   --ME
                                    , IMF_ACS_DIVISION_ACCOUNT_ID
                                    , nvl(IMF_AMOUNT_LC_D, 0) - nvl(IMF_AMOUNT_LC_C, 0) IMF_AMOUNT_LC
                                    , nvl(IMF_AMOUNT_FC_D, 0) - nvl(IMF_AMOUNT_FC_C, 0) IMF_AMOUNT_FC
                                 from ACT_FINANCIAL_IMPUTATION
                                where IMF_TRANSACTION_DATE between pFYE_START_DATE and pFYE_END_DATE
                             group by ACT_DOCUMENT_ID
                                    , ACS_PERIOD_ID
                                    , ACS_FINANCIAL_ACCOUNT_ID
                                    , ACS_ACS_FINANCIAL_CURRENCY_ID   --MB
                                    , ACS_FINANCIAL_CURRENCY_ID   --ME
                                    , IMF_ACS_DIVISION_ACCOUNT_ID
                                    , IMF_AMOUNT_LC_D
                                    , IMF_AMOUNT_LC_C
                                    , IMF_AMOUNT_FC_D
                                    , IMF_AMOUNT_FC_C) IMP
                          , ACT_DOCUMENT DOC
                          , ACJ_CATALOGUE_DOCUMENT CAT
                          , ACS_FINANCIAL_CURRENCY CUR
                          , PCS.PC_CURR PCU
                          , ACT_JOURNAL JOUR
                          , ACS_FINANCIAL_YEAR FYE
                      where CUR.PC_CURR_ID = PCU.PC_CURR_ID
                        and DOC.ACS_FINANCIAL_CURRENCY_ID = CUR.ACS_FINANCIAL_CURRENCY_ID
                        and DOC.ACT_JOURNAL_ID = JOUR.ACT_JOURNAL_ID
                        and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
                        and FYE.ACS_FINANCIAL_YEAR_ID = DOC.ACS_FINANCIAL_YEAR_ID
                        and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                        and IMP.NBPER <> 1) loop
      InsertCtrlDetail(aACR_CTRL_SUB_SET_ID             => pACR_CTRL_SUB_SET_ID
                     , aC_CTRL_CODE                     => '070'
                     , aACS_AUXILIARY_ACCOUNT_ID        => null
                     , aCDE_AMOUNT1                     => null
                     , aCDE_AMOUNT2                     => tplError.IMF_AMOUNT_LC
                     , aCDE_AMOUNT1_FC                  => null
                     , aCDE_AMOUNT2_FC                  => tplError.IMF_AMOUNT_FC
                     , aACT_DOCUMENT_ID                 => tplError.ACT_DOCUMENT_ID
                     , aACT_PART_IMPUTATION_ID          => null
                     , aC_TYPE_CUMUL                    => null
                     , aACS_FINANCIAL_CURRENCY_ID       => tplError.ACS_FINANCIAL_CURRENCY_ID   --ME
                     , aACS_DIVISION_ACCOUNT_ID         => tplError.ACS_DIVISION_ACCOUNT_ID
                     , aACS_FINANCIAL_ACCOUNT_ID        => tplError.ACS_FINANCIAL_ACCOUNT_ID
                     , aACS_CPN_ACCOUNT_ID              => null
                     , aACS_CDA_ACCOUNT_ID              => null
                     , aACS_PF_ACCOUNT_ID               => null
                     , aACS_PJ_ACCOUNT_ID               => null
                     , aACS_QTY_UNIT_ID                 => null
                     , aACS_PERIOD_ID                   => tplError.ACS_PERIOD_ID
                     , aACS_ACS_FINANCIAL_CURRENCY_ID   => tplError.ACS_ACS_FINANCIAL_CURRENCY_ID   --MB
                     , aACS_TAX_CODE_ID                 => null
                      );
    end loop;
  end ImpDocumentPeriodsCtrl;

  /**
  * procedure DocumentAmountsCtrl
  * Description
  *  Contrôle que les montants débit et crédit du documents correspondent soient identiques
  */
  procedure DocumentAmountsCtrl(
    pACR_CTRL_SUB_SET_ID in ACR_CTRL_SUB_SET.ACR_CTRL_SUB_SET_ID%type
  , pFYE_START_DATE      in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
  , pFYE_END_DATE        in ACS_FINANCIAL_YEAR.FYE_END_DATE%type
  )
  is
  begin
    for tplError in (select case
                              when(DIV.EXIST_DIV = 0)
                               or (IMP.IMF_AMOUNT_LC_D <> IMP.IMF_AMOUNT_LC_C) then IMP.IMF_AMOUNT_LC_D
                              else IMP.FIN_AMOUNT_LC_D
                            end AMOUNT_LC_D
                          , case
                              when(DIV.EXIST_DIV = 0)
                               or (IMP.IMF_AMOUNT_LC_D <> IMP.IMF_AMOUNT_LC_C) then IMP.IMF_AMOUNT_LC_C
                              else IMP.FIN_AMOUNT_LC_C
                            end AMOUNT_LC_C
                          , case
                              when(DIV.EXIST_DIV = 0)
                               or (IMP.IMF_AMOUNT_FC_D <> IMP.IMF_AMOUNT_FC_C) then IMP.IMF_AMOUNT_FC_D
                              else IMP.FIN_AMOUNT_FC_D
                            end AMOUNT_FC_D
                          , case
                              when(DIV.EXIST_DIV = 0)
                               or (IMP.IMF_AMOUNT_FC_D <> IMP.IMF_AMOUNT_FC_C) then IMP.IMF_AMOUNT_FC_C
                              else IMP.FIN_AMOUNT_FC_C
                            end AMOUNT_FC_C
                          , DOC.ACT_DOCUMENT_ID
                          , (select IMP.ACS_FINANCIAL_CURRENCY_ID
                               from ACT_FINANCIAL_IMPUTATION IMP
                              where IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                                and IMP.IMF_PRIMARY = 1) ACS_FINANCIAL_CURRENCY_ID   --ME
                          , (select IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
                               from ACT_FINANCIAL_IMPUTATION IMP
                              where IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                                and IMP.IMF_PRIMARY = 1) ACS_ACS_FINANCIAL_CURRENCY_ID   --MB
                          , (select IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                               from ACT_FINANCIAL_IMPUTATION IMP
                              where IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                                and IMP.IMF_PRIMARY = 1) ACS_DIVISION_ACCOUNT_ID
                          , (select IMP.ACS_PERIOD_ID
                               from ACT_FINANCIAL_IMPUTATION IMP
                              where IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                                and IMP.IMF_PRIMARY = 1) ACS_PERIOD_ID
                          , (select IMP.ACS_FINANCIAL_ACCOUNT_ID
                               from ACT_FINANCIAL_IMPUTATION IMP
                              where IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                                and IMP.IMF_PRIMARY = 1) ACS_FINANCIAL_ACCOUNT_ID
                       from ACT_DOCUMENT DOC
                          , (select IMP.ACT_DOCUMENT_ID
                                  , sum(nvl(IMP.IMF_AMOUNT_LC_D, 0) ) IMF_AMOUNT_LC_D
                                  , sum(nvl(IMP.IMF_AMOUNT_LC_C, 0) ) IMF_AMOUNT_LC_C
                                  , sum(nvl(IMP.IMF_AMOUNT_FC_D, 0) ) IMF_AMOUNT_FC_D
                                  , sum(nvl(IMP.IMF_AMOUNT_FC_C, 0) ) IMF_AMOUNT_FC_C
                                  , sum(nvl(IMP.FIN_AMOUNT_LC_D, 0) ) FIN_AMOUNT_LC_D
                                  , sum(nvl(IMP.FIN_AMOUNT_LC_C, 0) ) FIN_AMOUNT_LC_C
                                  , sum(nvl(IMP.FIN_AMOUNT_FC_D, 0) ) FIN_AMOUNT_FC_D
                                  , sum(nvl(IMP.FIN_AMOUNT_FC_C, 0) ) FIN_AMOUNT_FC_C
                               from( -- documents sans lissage
                                     select IMP.ACT_DOCUMENT_ID
                                          , nvl(IMP.IMF_AMOUNT_LC_D, 0) IMF_AMOUNT_LC_D
                                          , nvl(IMP.IMF_AMOUNT_LC_C, 0) IMF_AMOUNT_LC_C
                                          , nvl(IMP.IMF_AMOUNT_FC_D, 0) IMF_AMOUNT_FC_D
                                          , nvl(IMP.IMF_AMOUNT_FC_C, 0) IMF_AMOUNT_FC_C
                                          , nvl(DIS.FIN_AMOUNT_LC_D, 0) FIN_AMOUNT_LC_D
                                          , nvl(DIS.FIN_AMOUNT_LC_C, 0) FIN_AMOUNT_LC_C
                                          , nvl(DIS.FIN_AMOUNT_FC_D, 0) FIN_AMOUNT_FC_D
                                          , nvl(DIS.FIN_AMOUNT_FC_C, 0) FIN_AMOUNT_FC_C
                                       from ACT_DOCUMENT DOC
                                          , ACJ_CATALOGUE_DOCUMENT CAT
                                          , ACT_FINANCIAL_IMPUTATION IMP
                                          , ACT_FINANCIAL_DISTRIBUTION DIS
                                      where IMP.ACT_FINANCIAL_IMPUTATION_ID = DIS.ACT_FINANCIAL_IMPUTATION_ID(+)
                                        and CAT.CAT_DEFER_CAT = 0
                                        and IMP.IMF_TRANSACTION_DATE between pFYE_START_DATE and pFYE_END_DATE
                                        and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                                        and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
                                  union all
                                  -- transaction de lissage: prendre toutes les contres-écritures
                                     select IMP.ACT_DOCUMENT_ID
                                          , nvl(IMP.IMF_AMOUNT_LC_D, 0) IMF_AMOUNT_LC_D
                                          , nvl(IMP.IMF_AMOUNT_LC_C, 0) IMF_AMOUNT_LC_C
                                          , nvl(IMP.IMF_AMOUNT_FC_D, 0) IMF_AMOUNT_FC_D
                                          , nvl(IMP.IMF_AMOUNT_FC_C, 0) IMF_AMOUNT_FC_C
                                          , nvl(DIS.FIN_AMOUNT_LC_D, 0) FIN_AMOUNT_LC_D
                                          , nvl(DIS.FIN_AMOUNT_LC_C, 0) FIN_AMOUNT_LC_C
                                          , nvl(DIS.FIN_AMOUNT_FC_D, 0) FIN_AMOUNT_FC_D
                                          , nvl(DIS.FIN_AMOUNT_FC_C, 0) FIN_AMOUNT_FC_C
                                       from ACT_FINANCIAL_IMPUTATION IMP
                                          , ACT_FINANCIAL_DISTRIBUTION DIS
                                      where IMP.ACT_FINANCIAL_IMPUTATION_ID = DIS.ACT_FINANCIAL_IMPUTATION_ID(+)
                                         and exists
                                                (select 1
                                                   from ACT_FINANCIAL_IMPUTATION SIMP
                                                      , ACT_DOCUMENT DOC
                                                      , ACJ_CATALOGUE_DOCUMENT CAT
                                                  where SIMP.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
                                                    and CAT.CAT_DEFER_CAT = 1
                                                    and SIMP.IMF_PRIMARY = 1
                                                    and SIMP.IMF_TRANSACTION_DATE between pFYE_START_DATE and pFYE_END_DATE
                                                    and SIMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                                                    and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID)
                                  ) IMP
                             group by IMP.ACT_DOCUMENT_ID) IMP
                          , (select count(*) EXIST_DIV
                               from ACS_SUB_SET SSE
                              where SSE.C_TYPE_SUB_SET = 'DIVI') DIV
                      where IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                        and (    (IMP.IMF_AMOUNT_LC_D <> IMP.IMF_AMOUNT_LC_C)
                             or (    DIV.EXIST_DIV > 0
                                 and (IMP.FIN_AMOUNT_LC_D <> IMP.FIN_AMOUNT_LC_C) )
                             or (    DIV.EXIST_DIV > 0
                                 and (IMP.FIN_AMOUNT_LC_D <> IMP.IMF_AMOUNT_LC_D) )
                             or (    DIV.EXIST_DIV > 0
                                 and (IMP.FIN_AMOUNT_LC_C <> IMP.IMF_AMOUNT_LC_C) )
                             or (    DIV.EXIST_DIV > 0
                                 and ( (IMP.IMF_AMOUNT_LC_D - IMP.IMF_AMOUNT_LC_C) <>
                                                                             (IMP.FIN_AMOUNT_LC_D - IMP.FIN_AMOUNT_LC_C
                                                                             )
                                     )
                                )
                            ) ) loop
      InsertCtrlDetail(aACR_CTRL_SUB_SET_ID             => pACR_CTRL_SUB_SET_ID
                     , aC_CTRL_CODE                     => '080'
                     , aACS_AUXILIARY_ACCOUNT_ID        => null
                     , aCDE_AMOUNT1                     => tplError.AMOUNT_LC_D
                     , aCDE_AMOUNT2                     => tplError.AMOUNT_LC_C
                     , aCDE_AMOUNT1_FC                  => tplError.AMOUNT_FC_D
                     , aCDE_AMOUNT2_FC                  => tplError.AMOUNT_FC_C
                     , aACT_DOCUMENT_ID                 => tplError.ACT_DOCUMENT_ID
                     , aACT_PART_IMPUTATION_ID          => null
                     , aC_TYPE_CUMUL                    => null
                     , aACS_FINANCIAL_CURRENCY_ID       => tplError.ACS_FINANCIAL_CURRENCY_ID
                     , aACS_DIVISION_ACCOUNT_ID         => tplError.ACS_DIVISION_ACCOUNT_ID
                     , aACS_FINANCIAL_ACCOUNT_ID        => tplError.ACS_FINANCIAL_ACCOUNT_ID
                     , aACS_CPN_ACCOUNT_ID              => null
                     , aACS_CDA_ACCOUNT_ID              => null
                     , aACS_PF_ACCOUNT_ID               => null
                     , aACS_PJ_ACCOUNT_ID               => null
                     , aACS_QTY_UNIT_ID                 => null
                     , aACS_PERIOD_ID                   => tplError.ACS_PERIOD_ID
                     , aACS_ACS_FINANCIAL_CURRENCY_ID   => tplError.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , aACS_TAX_CODE_ID                 => null
                      );
    end loop;
  end DocumentAmountsCtrl;

  /**
  * procedure ImpTaxBreakdownCtrl
  * Description
  *  Contrôle la cohérence entre le montant des imputations et des décompte TVA
  * @param pACR_CTRL_SUB_SET_ID identifiant du contrôle en cours
  */
  procedure ImpTaxBreakdownCtrl(
    pACR_CTRL_SUB_SET_ID in ACR_CTRL_SUB_SET.ACR_CTRL_SUB_SET_ID%type
  , pFYE_START_DATE      in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
  , pFYE_END_DATE        in ACS_FINANCIAL_YEAR.FYE_END_DATE%type
  )
  is
  begin
    for tplError in (select   ACS_TAX_CODE_ID
                            , sum(TAX_VAT_AMOUNT_LC) TAX_VAT_AMOUNT_LC
                            , sum(IMF_AMOUNT) IMF_AMOUNT_LC
                            , ACT_DOCUMENT_ID
                            , ACS_PERIOD_ID
                         from (select to_char(IMF.IMF_TRANSACTION_DATE, 'YYYY-MM') PC_YEAR_MONTH_ID
                                    , nvl(TAX.TAX_LIABLED_AMOUNT, 0) TAX_LIABLED_AMOUNT
                                    , nvl(TAX.TAX_LIABLED_RATE, 0) TAX_LIABLED_RATE
                                    , nvl(TAX.TAX_RATE, 0) TAX_RATE
                                    , case
                                        when ACC_INTEREST <> 1
                                        and TAX_INCLUDED_EXCLUDED <> 'S' then nvl(IMF.IMF_AMOUNT_LC_D, 0) -
                                                                              nvl(IMF.IMF_AMOUNT_LC_C, 0)
                                        else nvl(IM1.IMF_AMOUNT_LC_D, 0) - nvl(IM1.IMF_AMOUNT_LC_C, 0)
                                      end IMF_AMOUNT
                                    , nvl(ACC.ACC_INTEREST, 0) ACC_INTEREST
                                    , nvl(TAX.TAX_INCLUDED_EXCLUDED, ' ') TAX_INCLUDED_EXCLUDED
                                    , nvl(TAX.TAX_VAT_AMOUNT_LC, 0) TAX_VAT_AMOUNT_LC
                                    , nvl(IMF.IMF_AMOUNT_LC_D, 0) - nvl(IMF.IMF_AMOUNT_LC_C, 0) IMF_AMOUNT_LC
                                    , nvl(IM1.IMF_AMOUNT_LC_D, 0) - nvl(IM1.IMF_AMOUNT_LC_C, 0) IMF1_AMOUNT_LC
                                    , IMF.ACT_DOCUMENT_ID
                                    , IMF.ACT_FINANCIAL_IMPUTATION_ID
                                    , IMF.ACS_TAX_CODE_ID
                                    , IMF.ACS_PERIOD_ID
                                 from ACT_DET_TAX TAX
                                    , ACT_DOCUMENT DOC
                                    , ACT_FINANCIAL_IMPUTATION IMF
                                    , ACT_FINANCIAL_IMPUTATION IM1
                                    , ACS_ACCOUNT ACC
                                where IMF.IMF_TRANSACTION_DATE between pFYE_START_DATE and pFYE_END_DATE
                                  and IMF.ACT_FINANCIAL_IMPUTATION_ID = TAX.ACT_FINANCIAL_IMPUTATION_ID
                                  and TAX.ACT_ACT_FINANCIAL_IMPUTATION = IM1.ACT_FINANCIAL_IMPUTATION_ID(+)
                                  and IMF.IMF_TYPE <> 'VAT'
                                  and IMF.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                                  and ACC.ACS_ACCOUNT_ID = IMF.ACS_TAX_CODE_ID)
                        where (    (    ACC_INTEREST <> 1
                                    and TAX_INCLUDED_EXCLUDED <> 'S'
                                    and (TAX_VAT_AMOUNT_LC <> IMF1_AMOUNT_LC)
                                   )
                               or (    ACS_TAX_CODE_ID is not null
                                   and ACT_FINANCIAL_IMPUTATION_ID is null)
                               or (    ACC_INTEREST = 1
                                   and TAX_VAT_AMOUNT_LC = 0
                                   and (IMF_AMOUNT_LC <> 0) )
                              )
                     group by PC_YEAR_MONTH_ID
                            , ACS_TAX_CODE_ID
                            , ACT_DOCUMENT_ID
                            , ACS_PERIOD_ID
                            , TAX_INCLUDED_EXCLUDED) loop
      InsertCtrlDetail(aACR_CTRL_SUB_SET_ID             => pACR_CTRL_SUB_SET_ID
                     , aC_CTRL_CODE                     => '090'
                     , aACS_AUXILIARY_ACCOUNT_ID        => null
                     , aCDE_AMOUNT1                     => tplError.IMF_AMOUNT_LC   --solde = débit - crédit
                     , aCDE_AMOUNT2                     => tplError.TAX_VAT_AMOUNT_LC
                     , aCDE_AMOUNT1_FC                  => null
                     , aCDE_AMOUNT2_FC                  => null
                     , aACT_DOCUMENT_ID                 => tplError.ACT_DOCUMENT_ID
                     , aACT_PART_IMPUTATION_ID          => null
                     , aC_TYPE_CUMUL                    => null
                     , aACS_FINANCIAL_CURRENCY_ID       => null
                     , aACS_DIVISION_ACCOUNT_ID         => null
                     , aACS_FINANCIAL_ACCOUNT_ID        => null
                     , aACS_CPN_ACCOUNT_ID              => null
                     , aACS_CDA_ACCOUNT_ID              => null
                     , aACS_PF_ACCOUNT_ID               => null
                     , aACS_PJ_ACCOUNT_ID               => null
                     , aACS_QTY_UNIT_ID                 => null
                     , aACS_PERIOD_ID                   => tplError.ACS_PERIOD_ID
                     , aACS_ACS_FINANCIAL_CURRENCY_ID   => null
                     , aACS_TAX_CODE_ID                 => tplError.ACS_TAX_CODE_ID
                      );
    end loop;
  end ImpTaxBreakdownCtrl;

  /**
  * procedure AuxAccPaymentInvoiceCtrl
  * Description
  *  Partenaires : comparaison des comptes partenaires pour les montants payés et facturés
  */
  procedure AuxAccPaymentInvoiceCtrl(
    pACR_CTRL_SUB_SET_ID in ACR_CTRL_SUB_SET.ACR_CTRL_SUB_SET_ID%type
  , pFYE_START_DATE      in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
  , pFYE_END_DATE        in ACS_FINANCIAL_YEAR.FYE_END_DATE%type
  , pACS_SUB_SET_ID      in ACR_CTRL_SUB_SET.ACS_SUB_SET_ID%type
  )
  is
  begin
    for tplError in (select distinct ACC.ACS_ACCOUNT_ID ACS_AUXILIARY_ACCOUNT_ID
                                   , DOC.DOC_TOTAL_AMOUNT_DC
                                   , DDO.DOC_TOTAL_AMOUNT_DC DOC_TOTAL_AMOUNT_DC2
                                   , DOC.ACT_DOCUMENT_ID
                                   , IMP.ACS_PERIOD_ID
                                   , IMP.ACS_FINANCIAL_CURRENCY_ID   --ME
                                   , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID   --MB
                                from ACT_DOCUMENT DDO
                                   , ACT_DOCUMENT DOC
                                   , ACT_PART_IMPUTATION PAR
                                   , ACT_FINANCIAL_IMPUTATION IIM
                                   , ACT_EXPIRY exp
                                   , ACT_DET_PAYMENT DET
                                   , ACT_FINANCIAL_IMPUTATION IMP
                                   , ACS_ACCOUNT ACC
                                   , ACS_ACCOUNT AAC
                                   , ACS_FINANCIAL_ACCOUNT AAF
                                   , ACS_FINANCIAL_ACCOUNT ACF
                               where IMP.IMF_TRANSACTION_DATE between pFYE_START_DATE and pFYE_END_DATE
                                 and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                                 and IMP.ACS_FINANCIAL_ACCOUNT_ID = ACF.ACS_FINANCIAL_ACCOUNT_ID
                                 and ACF.FIN_COLLECTIVE = 1
                                 and IMP.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                                 and ACC.ACS_SUB_SET_ID = pACS_SUB_SET_ID
                                 and IMP.ACT_DET_PAYMENT_ID = DET.ACT_DET_PAYMENT_ID
                                 and DET.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
                                 and exp.ACT_PART_IMPUTATION_ID = IIM.ACT_PART_IMPUTATION_ID
                                 and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
                                 and IIM.IMF_TRANSACTION_DATE between pFYE_START_DATE and pFYE_END_DATE
                                 and PAR.ACT_DOCUMENT_ID = DDO.ACT_DOCUMENT_ID
                                 and IIM.ACS_FINANCIAL_ACCOUNT_ID = AAF.ACS_FINANCIAL_ACCOUNT_ID
                                 and AAF.FIN_COLLECTIVE = 1
                                 and IIM.ACS_AUXILIARY_ACCOUNT_ID = AAC.ACS_ACCOUNT_ID
                                 and AAC.ACS_SUB_SET_ID = pACS_SUB_SET_ID
                                 and IIM.ACT_DET_PAYMENT_ID is null
                                 and IMP.ACS_AUXILIARY_ACCOUNT_ID <> IIM.ACS_AUXILIARY_ACCOUNT_ID) loop
      InsertCtrlDetail(aACR_CTRL_SUB_SET_ID             => pACR_CTRL_SUB_SET_ID
                     , aC_CTRL_CODE                     => '100'
                     , aACS_AUXILIARY_ACCOUNT_ID        => tplError.ACS_AUXILIARY_ACCOUNT_ID
                     , aCDE_AMOUNT1                     => tplError.DOC_TOTAL_AMOUNT_DC
                     , aCDE_AMOUNT2                     => tplError.DOC_TOTAL_AMOUNT_DC2
                     , aCDE_AMOUNT1_FC                  => null
                     , aCDE_AMOUNT2_FC                  => null
                     , aACT_DOCUMENT_ID                 => tplError.ACT_DOCUMENT_ID
                     , aACT_PART_IMPUTATION_ID          => null
                     , aC_TYPE_CUMUL                    => null
                     , aACS_FINANCIAL_CURRENCY_ID       => tplError.ACS_FINANCIAL_CURRENCY_ID
                     , aACS_DIVISION_ACCOUNT_ID         => null
                     , aACS_FINANCIAL_ACCOUNT_ID        => null
                     , aACS_CPN_ACCOUNT_ID              => null
                     , aACS_CDA_ACCOUNT_ID              => null
                     , aACS_PF_ACCOUNT_ID               => null
                     , aACS_PJ_ACCOUNT_ID               => null
                     , aACS_QTY_UNIT_ID                 => null
                     , aACS_PERIOD_ID                   => tplError.ACS_PERIOD_ID
                     , aACS_ACS_FINANCIAL_CURRENCY_ID   => tplError.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , aACS_TAX_CODE_ID                 => null
                      );
    end loop;
  end AuxAccPaymentInvoiceCtrl;

  /**
  * procedure CollAccPaymentInvoiceCtrl
  * Description
  *  Partenaires groupe: comparaison des comptes collectifs pour les montants payés et facturés
  */
  procedure CollAccPaymentInvoiceCtrl(
    pACR_CTRL_SUB_SET_ID in ACR_CTRL_SUB_SET.ACR_CTRL_SUB_SET_ID%type
  , pFYE_START_DATE      in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
  , pFYE_END_DATE        in ACS_FINANCIAL_YEAR.FYE_END_DATE%type
  , pACS_SUB_SET_ID      in ACR_CTRL_SUB_SET.ACS_SUB_SET_ID%type
  )
  is
  begin
    for tplError in (select distinct DOC.DOC_TOTAL_AMOUNT_DC
                                   , DDO.DOC_TOTAL_AMOUNT_DC DOC_TOTAL_AMOUNT_DC2
                                   , IMP.ACS_AUXILIARY_ACCOUNT_ID
                                   , DIS.ACS_DIVISION_ACCOUNT_ID
                                   , DOC.ACT_DOCUMENT_ID
                                   , IMP.ACS_PERIOD_ID
                                   , IMP.ACS_FINANCIAL_CURRENCY_ID   --ME
                                   , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID   --MB
                                from ACT_DOCUMENT DDO
                                   , ACT_PART_IMPUTATION PAR
                                   , ACT_FINANCIAL_IMPUTATION IIM
                                   , ACT_FINANCIAL_DISTRIBUTION IDIS
                                   , ACT_EXPIRY exp
                                   , ACT_DET_PAYMENT DET
                                   , ACT_FINANCIAL_IMPUTATION IMP
                                   , ACT_FINANCIAL_DISTRIBUTION DIS
                                   , ACS_ACCOUNT ACC
                                   , ACS_ACCOUNT AAC
                                   , ACS_FINANCIAL_ACCOUNT AAF
                                   , ACS_FINANCIAL_ACCOUNT ACF
                                   , ACS_ACCOUNT FACC
                                   , ACS_ACCOUNT IFACC
                                   , ACS_ACCOUNT DACC
                                   , ACS_ACCOUNT IDACC
                                   , ACT_DOCUMENT DOC
                                   , ACT_JOURNAL JOU
                                   , ACS_FINANCIAL_YEAR FYE
                               where IMP.IMF_TRANSACTION_DATE between pFYE_START_DATE and pFYE_END_DATE
                                 and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                                 and IMP.ACT_FINANCIAL_IMPUTATION_ID = DIS.ACT_FINANCIAL_IMPUTATION_ID(+)
                                 and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
                                 and JOU.ACS_FINANCIAL_YEAR_ID = FYE.ACS_FINANCIAL_YEAR_ID
                                 and IMP.ACS_FINANCIAL_ACCOUNT_ID = ACF.ACS_FINANCIAL_ACCOUNT_ID
                                 and ACF.FIN_COLLECTIVE = 1
                                 and IMP.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                                 and ACC.ACS_SUB_SET_ID = pACS_SUB_SET_ID
                                 and IMP.ACT_DET_PAYMENT_ID = DET.ACT_DET_PAYMENT_ID
                                 and DET.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
                                 and exp.ACT_PART_IMPUTATION_ID = IIM.ACT_PART_IMPUTATION_ID
                                 and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
                                 and IIM.IMF_TRANSACTION_DATE between pFYE_START_DATE and pFYE_END_DATE
                                 and PAR.ACT_DOCUMENT_ID = DDO.ACT_DOCUMENT_ID
                                 and IIM.ACS_FINANCIAL_ACCOUNT_ID = AAF.ACS_FINANCIAL_ACCOUNT_ID
                                 and IIM.ACT_FINANCIAL_IMPUTATION_ID = IDIS.ACT_FINANCIAL_IMPUTATION_ID(+)
                                 and AAF.FIN_COLLECTIVE = 1
                                 and IIM.ACS_AUXILIARY_ACCOUNT_ID = AAC.ACS_ACCOUNT_ID
                                 and AAC.ACS_SUB_SET_ID = pACS_SUB_SET_ID
                                 and IIM.ACT_DET_PAYMENT_ID is null
                                 and IMP.ACS_FINANCIAL_ACCOUNT_ID = FACC.ACS_ACCOUNT_ID
                                 and DIS.ACS_DIVISION_ACCOUNT_ID = DACC.ACS_ACCOUNT_ID(+)
                                 and IIM.ACS_FINANCIAL_ACCOUNT_ID = IFACC.ACS_ACCOUNT_ID
                                 and IDIS.ACS_DIVISION_ACCOUNT_ID = IDACC.ACS_ACCOUNT_ID(+)
                                 and (   IMP.ACS_FINANCIAL_ACCOUNT_ID <> IIM.ACS_FINANCIAL_ACCOUNT_ID
                                      or nvl(DIS.ACS_DIVISION_ACCOUNT_ID, 0) <> nvl(IDIS.ACS_DIVISION_ACCOUNT_ID, 0)
                                     ) ) loop
      InsertCtrlDetail(aACR_CTRL_SUB_SET_ID             => pACR_CTRL_SUB_SET_ID
                     , aC_CTRL_CODE                     => '110'
                     , aACS_AUXILIARY_ACCOUNT_ID        => tplError.ACS_AUXILIARY_ACCOUNT_ID
                     , aCDE_AMOUNT1                     => tplError.DOC_TOTAL_AMOUNT_DC
                     , aCDE_AMOUNT2                     => tplError.DOC_TOTAL_AMOUNT_DC2
                     , aCDE_AMOUNT1_FC                  => null
                     , aCDE_AMOUNT2_FC                  => null
                     , aACT_DOCUMENT_ID                 => tplError.ACT_DOCUMENT_ID
                     , aACT_PART_IMPUTATION_ID          => null
                     , aC_TYPE_CUMUL                    => null
                     , aACS_FINANCIAL_CURRENCY_ID       => tplError.ACS_FINANCIAL_CURRENCY_ID
                     , aACS_DIVISION_ACCOUNT_ID         => null
                     , aACS_FINANCIAL_ACCOUNT_ID        => null
                     , aACS_CPN_ACCOUNT_ID              => null
                     , aACS_CDA_ACCOUNT_ID              => null
                     , aACS_PF_ACCOUNT_ID               => null
                     , aACS_PJ_ACCOUNT_ID               => null
                     , aACS_QTY_UNIT_ID                 => null
                     , aACS_PERIOD_ID                   => tplError.ACS_PERIOD_ID
                     , aACS_ACS_FINANCIAL_CURRENCY_ID   => tplError.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , aACS_TAX_CODE_ID                 => null
                      );
    end loop;
  end CollAccPaymentInvoiceCtrl;

  /**
  * procedure NoPartnerCtrl
  * Description
  *  Contrôle de la présence d'un partenaire dans l'imputation
  */
  procedure NoPartnerCtrl(
    pACR_CTRL_SUB_SET_ID in ACR_CTRL_SUB_SET.ACR_CTRL_SUB_SET_ID%type
  , pFYE_START_DATE      in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
  , pPER_END_DATE        in ACS_PERIOD.PER_END_DATE%type
  , pACS_SUB_SET_ID      in ACR_CTRL_SUB_SET.ACS_SUB_SET_ID%type
  )
  is
    cursor NoPartnerCursor(
      pACS_SUB_SET_ID    ACR_CTRL_SUB_SET.ACS_SUB_SET_ID%type
    , pFYE_START_DATE in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
    , pPER_END_DATE   in ACS_PERIOD.PER_END_DATE%type
    )
    is
      select IMP.ACT_DOCUMENT_ID
           , IMP.ACT_PART_IMPUTATION_ID
           , IMP.ACS_AUXILIARY_ACCOUNT_ID
        from ACT_FINANCIAL_IMPUTATION IMP
           , ACS_ACCOUNT ACC
       where ACC.ACS_SUB_SET_ID = pACS_SUB_SET_ID
         and ACC.ACS_ACCOUNT_ID = IMP.ACS_AUXILIARY_ACCOUNT_ID
         and IMP.ACT_PART_IMPUTATION_ID is not null
         and IMP.IMF_TRANSACTION_DATE between pFYE_START_DATE and pPER_END_DATE
         and IMP.IMF_PAC_CUSTOM_PARTNER_ID is null
         and IMP.IMF_PAC_SUPPLIER_PARTNER_ID is null;

    NoPartner NoPartnerCursor%rowtype;
  begin
    open NoPartnerCursor(pACS_SUB_SET_ID, pFYE_START_DATE, pPER_END_DATE);

    fetch NoPartnerCursor
     into NoPartner;

    while NoPartnerCursor%found loop
      InsertCtrlDetail(aACR_CTRL_SUB_SET_ID             => pACR_CTRL_SUB_SET_ID
                     , aC_CTRL_CODE                     => '030'
                     , aACS_AUXILIARY_ACCOUNT_ID        => NoPartner.ACS_AUXILIARY_ACCOUNT_ID
                     , aCDE_AMOUNT1                     => null
                     , aCDE_AMOUNT2                     => null
                     , aCDE_AMOUNT1_FC                  => null
                     , aCDE_AMOUNT2_FC                  => null
                     , aACT_DOCUMENT_ID                 => NoPartner.ACT_DOCUMENT_ID
                     , aACT_PART_IMPUTATION_ID          => NoPartner.ACT_PART_IMPUTATION_ID
                     , aC_TYPE_CUMUL                    => null
                     , aACS_FINANCIAL_CURRENCY_ID       => null
                     , aACS_DIVISION_ACCOUNT_ID         => null
                     , aACS_FINANCIAL_ACCOUNT_ID        => null
                     , aACS_CPN_ACCOUNT_ID              => null
                     , aACS_CDA_ACCOUNT_ID              => null
                     , aACS_PF_ACCOUNT_ID               => null
                     , aACS_PJ_ACCOUNT_ID               => null
                     , aACS_QTY_UNIT_ID                 => null
                     , aACS_PERIOD_ID                   => null
                     , aACS_ACS_FINANCIAL_CURRENCY_ID   => null
                     , aACS_TAX_CODE_ID                 => null
                      );

      fetch NoPartnerCursor
       into NoPartner;
    end loop;

    close NoPartnerCursor;
  end NoPartnerCtrl;

  /**
  * procedure PartnerAccountsCtrl
  * Description
  *  Partenaires: contrôle d'un client-fournisseur REC-PAY
  */
  procedure PartnerAccountsCtrl(
    aACR_CTRL_SUB_SET_ID   in ACR_CTRL_SUB_SET.ACR_CTRL_SUB_SET_ID%type
  , pFYE_START_DATE        in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
  , pPER_END_DATE          in ACS_PERIOD.PER_END_DATE%type
  , aACS_SUB_SET_ID        in ACR_CTRL_SUB_SET.ACS_SUB_SET_ID%type
  , aCTR_UNBALANCED_EXPIRY in ACR_CTRL.CTR_UNBALANCED_EXPIRY%type
  , aCTR_NO_EXPIRY         in ACR_CTRL.CTR_NO_EXPIRY%type
  , aCTR_UNBALANCED_TOT    in ACR_CTRL.CTR_UNBALANCED_TOT%type
  , aCTR_ADVANCED_PAYMENT  in ACR_CTRL.CTR_ADVANCED_PAYMENT%type
  )
  is
    -- Ramène les comptes d'un sous-ensemble donné
    cursor SubSetAccountsCursor(aACS_SUB_SET_ID ACR_CTRL_SUB_SET.ACS_SUB_SET_ID%type)
    is
      select ACC.ACS_ACCOUNT_ID
           , ACC.ACC_NUMBER
           , SUB.C_SUB_SET
        from ACS_SUB_SET SUB
           , ACS_ACCOUNT ACC
       where ACC.ACS_SUB_SET_ID = aACS_SUB_SET_ID
         and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID;

    SubSetAccounts SubSetAccountsCursor%rowtype;
  begin
    open SubSetAccountsCursor(aACS_SUB_SET_ID);

    fetch SubSetAccountsCursor
     into SubSetAccounts;

    while SubSetAccountsCursor%found loop
      if aCTR_UNBALANCED_EXPIRY = 1 then
        -- Montant échéance incorrect : C_CTRL_CODE = '010'
        AccountExpiriesCtrl(aACR_CTRL_SUB_SET_ID
                          , pFYE_START_DATE
                          , pPER_END_DATE
                          , SubSetAccounts.ACC_NUMBER
                          , SubSetAccounts.ACS_ACCOUNT_ID
                          , SubSetAccounts.C_SUB_SET
                           );
      end if;

      if aCTR_NO_EXPIRY = 1 then
        -- Echéance inexistante : C_CTRL_CODE = '020'
        DocWithoutExpiries(aACR_CTRL_SUB_SET_ID
                         , pFYE_START_DATE
                         , pPER_END_DATE
                         , SubSetAccounts.ACS_ACCOUNT_ID
                         , SubSetAccounts.C_SUB_SET
                          );
      end if;

      if aCTR_UNBALANCED_TOT = 1 then
        -- Cumuls incorrects : C_CTRL_CODE = '04X'
        TotalAccountCtrl(aACR_CTRL_SUB_SET_ID
                       , pFYE_START_DATE
                       , pPER_END_DATE
                       , SubSetAccounts.ACS_ACCOUNT_ID
                       , SubSetAccounts.C_SUB_SET
                        );
      end if;

      if aCTR_ADVANCED_PAYMENT = 1 then
        -- Paiement antérieur à la date de comptabilisation : C_CTRL_CODE = '050'
        AdvancedPaymentCtrl(aACR_CTRL_SUB_SET_ID
                          , pFYE_START_DATE
                          , pPER_END_DATE
                          , SubSetAccounts.ACS_ACCOUNT_ID
                          , SubSetAccounts.C_SUB_SET
                           );
      end if;

      fetch SubSetAccountsCursor
       into SubSetAccounts;
    end loop;

    close SubSetAccountsCursor;
  end PartnerAccountsCtrl;

  /**
  * procedure AccountExpiriesCtrl
  * Description
  *  Partenaires: contrôle des postes ouverts
  */
  procedure AccountExpiriesCtrl(
    aACR_CTRL_SUB_SET_ID in ACR_CTRL_SUB_SET.ACR_CTRL_SUB_SET_ID%type
  , pFYE_START_DATE      in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
  , pPER_END_DATE        in ACS_PERIOD.PER_END_DATE%type
  , aACC_NUMBER          in ACS_ACCOUNT.ACC_NUMBER%type
  , aACS_ACCOUNT_ID      in ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aC_SUB_SET           in ACS_SUB_SET.C_SUB_SET%type
  )
  is
    type ExpiriesCursorTyp is ref cursor;

    -- Ramène les PO d'un compte à une date donnée
    cursor ExpCursor
    is
      select ACT_DOCUMENT_ID
           , ACT_PART_IMPUTATION_ID
           , EXP_AMOUNT_LC
           , EXP_AMOUNT_FC
           , EXP_AMOUNT_EUR
           , DET_PAIED_LC
           , DET_PAIED_FC
           , DET_PAIED_EUR
        from V_ACT_EXPIRY_CUST_CTRL;

    ExpiriesCursorRow    ExpCursor%rowtype;
    ExpiriesCursor       ExpiriesCursorTyp;
    TotExpImputationsLC  ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    TotExpImputationsFC  ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    TotExpImputationsEUR ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    TotPayImputationsLC  ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type;
    TotPayImputationsFC  ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type;
    TotPayImputationsEUR ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type;
    TotExpiriesLC        ACT_EXPIRY.EXP_AMOUNT_LC%type;
    TotExpiriesFC        ACT_EXPIRY.EXP_AMOUNT_FC%type;
    TotExpiriesEUR       ACT_EXPIRY.EXP_AMOUNT_EUR%type;
    SoldeLC              ACT_EXPIRY.EXP_AMOUNT_LC%type;
    PeriodId             ACS_PERIOD.ACS_PERIOD_ID%type;

    -- Retourne le montant total des imputations d'un document partenaire
    procedure ExpImputationsAmounts(
      aACT_PART_IMPUTATION_ID in     ACT_FINANCIAL_IMPUTATION.ACT_PART_IMPUTATION_ID%type
    , aC_SUB_SET              in     ACS_SUB_SET.C_SUB_SET%type
    , aAmountLC               out    ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
    , aAmountFC               out    ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
    , aAmountEUR              out    ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type
    )
    is
    begin
      if aC_SUB_SET = 'REC' then
        select nvl(sum(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C), 0)
             , nvl(sum(IMF_AMOUNT_FC_D - IMF_AMOUNT_FC_C), 0)
             , nvl(sum(IMF_AMOUNT_EUR_D - IMF_AMOUNT_EUR_C), 0)
          into aAmountLC
             , aAmountFC
             , aAmountEUR
          from ACS_FINANCIAL_ACCOUNT FIN
             , ACT_FINANCIAL_IMPUTATION IMP
         where IMP.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and FIN.FIN_COLLECTIVE = 1
           and IMP.ACT_DET_PAYMENT_ID is null;
      else
        select nvl(sum(IMF_AMOUNT_LC_C - IMF_AMOUNT_LC_D), 0)
             , nvl(sum(IMF_AMOUNT_FC_C - IMF_AMOUNT_FC_D), 0)
             , nvl(sum(IMF_AMOUNT_EUR_C - IMF_AMOUNT_EUR_D), 0)
          into aAmountLC
             , aAmountFC
             , aAmountEUR
          from ACS_FINANCIAL_ACCOUNT FIN
             , ACT_FINANCIAL_IMPUTATION IMP
         where IMP.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and FIN.FIN_COLLECTIVE = 1
           and IMP.ACT_DET_PAYMENT_ID is null;
      end if;
    end ExpImputationsAmounts;

    -- Retourne le montant total des imputations de paiement pour un document partenaire
    procedure PayImputationsAmounts(
      aACT_PART_IMPUTATION_ID in     ACT_FINANCIAL_IMPUTATION.ACT_PART_IMPUTATION_ID%type
    , pFYE_START_DATE         in     ACS_FINANCIAL_YEAR.FYE_START_DATE%type
    , pPER_END_DATE           in     ACS_PERIOD.PER_END_DATE%type
    , aC_SUB_SET              in     ACS_SUB_SET.C_SUB_SET%type
    , aAmountLC               out    ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_LC_D%type
    , aAmountFC               out    ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_FC_D%type
    , aAmountEUR              out    ACT_FINANCIAL_IMPUTATION.IMF_AMOUNT_EUR_D%type
    )
    is
    begin
      if aC_SUB_SET = 'REC' then
        select nvl(sum(IMP.IMF_AMOUNT_LC_C - IMP.IMF_AMOUNT_LC_D), 0)
             , nvl(sum(IMP.IMF_AMOUNT_FC_C - IMP.IMF_AMOUNT_FC_D), 0)
             , nvl(sum(IMP.IMF_AMOUNT_EUR_C - IMP.IMF_AMOUNT_EUR_D), 0)
          into aAmountLC
             , aAmountFC
             , aAmountEUR
          from ACT_FINANCIAL_IMPUTATION IMP
             , ACT_DET_PAYMENT PAY
             , ACT_EXPIRY exp
         where exp.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
           and exp.ACT_EXPIRY_ID = PAY.ACT_EXPIRY_ID
           and PAY.ACT_DET_PAYMENT_ID = IMP.ACT_DET_PAYMENT_ID
           and IMP.IMF_TRANSACTION_DATE between pFYE_START_DATE and pPER_END_DATE
           and IMP.ACS_AUXILIARY_ACCOUNT_ID is not null;
      else
        select nvl(sum(IMP.IMF_AMOUNT_LC_D - IMP.IMF_AMOUNT_LC_C), 0)
             , nvl(sum(IMP.IMF_AMOUNT_FC_D - IMP.IMF_AMOUNT_FC_C), 0)
             , nvl(sum(IMP.IMF_AMOUNT_EUR_D - IMP.IMF_AMOUNT_EUR_C), 0)
          into aAmountLC
             , aAmountFC
             , aAmountEUR
          from ACT_FINANCIAL_IMPUTATION IMP
             , ACT_DET_PAYMENT PAY
             , ACT_EXPIRY exp
         where exp.ACT_PART_IMPUTATION_ID = aACT_PART_IMPUTATION_ID
           and exp.ACT_EXPIRY_ID = PAY.ACT_EXPIRY_ID
           and PAY.ACT_DET_PAYMENT_ID = IMP.ACT_DET_PAYMENT_ID
           and IMP.IMF_TRANSACTION_DATE between pFYE_START_DATE and pPER_END_DATE
           and IMP.ACS_AUXILIARY_ACCOUNT_ID is not null;
      end if;
    end PayImputationsAmounts;
  begin
    PeriodId  := ACS_FUNCTION.GetPeriodID(pPER_END_DATE, '2');
    ACT_FUNCTIONS.SetAnalyse_Parameters(to_char(pPER_END_DATE, 'yyyymmdd'), aACC_NUMBER, aACC_NUMBER, '1');

    if aC_SUB_SET = 'REC' then
      open ExpiriesCursor
       for
         select   ACT_DOCUMENT_ID
                , ACT_PART_IMPUTATION_ID
                , sum(EXP_AMOUNT_LC) EXP_AMOUNT_LC
                , sum(EXP_AMOUNT_FC) EXP_AMOUNT_FC
                , sum(EXP_AMOUNT_EUR) EXP_AMOUNT_EUR
                , sum(DET_PAIED_LC) DET_PAIED_LC
                , sum(DET_PAIED_FC) DET_PAIED_FC
                , sum(DET_PAIED_EUR) DET_PAIED_EUR
             from V_ACT_EXPIRY_CUST_CTRL
            where IMF_TRANSACTION_DATE between pFYE_START_DATE and pPER_END_DATE
         group by ACT_DOCUMENT_ID
                , ACT_PART_IMPUTATION_ID;
    else
      open ExpiriesCursor
       for
         select   ACT_DOCUMENT_ID
                , ACT_PART_IMPUTATION_ID
                , sum(EXP_AMOUNT_LC) EXP_AMOUNT_LC
                , sum(EXP_AMOUNT_FC) EXP_AMOUNT_FC
                , sum(EXP_AMOUNT_EUR) EXP_AMOUNT_EUR
                , sum(DET_PAIED_LC) DET_PAIED_LC
                , sum(DET_PAIED_FC) DET_PAIED_FC
                , sum(DET_PAIED_EUR) DET_PAIED_EUR
             from V_ACT_EXPIRY_SUPP_CTRL
            where IMF_TRANSACTION_DATE between pFYE_START_DATE and pPER_END_DATE
         group by ACT_DOCUMENT_ID
                , ACT_PART_IMPUTATION_ID;
    end if;

    fetch ExpiriesCursor
     into ExpiriesCursorRow;

    while ExpiriesCursor%found loop
      ExpImputationsAmounts(ExpiriesCursorRow.ACT_PART_IMPUTATION_ID
                          , aC_SUB_SET
                          , TotExpImputationsLC
                          , TotExpImputationsFC
                          , TotExpImputationsEUR
                           );
      PayImputationsAmounts(ExpiriesCursorRow.ACT_PART_IMPUTATION_ID
                          , pFYE_START_DATE
                          , pPER_END_DATE
                          , aC_SUB_SET
                          , TotPayImputationsLC
                          , TotPayImputationsFC
                          , TotPayImputationsEUR
                           );

      if    (ExpiriesCursorRow.EXP_AMOUNT_LC - ExpiriesCursorRow.DET_PAIED_LC <>
                                                                               TotExpImputationsLC - TotPayImputationsLC
            )
         or (ExpiriesCursorRow.EXP_AMOUNT_FC - ExpiriesCursorRow.DET_PAIED_FC <>
                                                                               TotExpImputationsFC - TotPayImputationsFC
            ) then
        InsertCtrlDetail(aACR_CTRL_SUB_SET_ID             => aACR_CTRL_SUB_SET_ID
                       , aC_CTRL_CODE                     => '010'
                       , aACS_AUXILIARY_ACCOUNT_ID        => aACS_ACCOUNT_ID
                       , aCDE_AMOUNT1                     => ExpiriesCursorRow.EXP_AMOUNT_LC -
                                                             ExpiriesCursorRow.DET_PAIED_LC
                       , aCDE_AMOUNT2                     => TotExpImputationsLC - TotPayImputationsLC
                       , aCDE_AMOUNT1_FC                  => ExpiriesCursorRow.EXP_AMOUNT_FC -
                                                             ExpiriesCursorRow.DET_PAIED_FC
                       , aCDE_AMOUNT2_FC                  => TotExpImputationsFC - TotPayImputationsFC
                       , aACT_DOCUMENT_ID                 => ExpiriesCursorRow.ACT_DOCUMENT_ID
                       , aACT_PART_IMPUTATION_ID          => ExpiriesCursorRow.ACT_PART_IMPUTATION_ID
                       , aC_TYPE_CUMUL                    => null
                       , aACS_FINANCIAL_CURRENCY_ID       => null
                       , aACS_DIVISION_ACCOUNT_ID         => null
                       , aACS_FINANCIAL_ACCOUNT_ID        => null
                       , aACS_CPN_ACCOUNT_ID              => null
                       , aACS_CDA_ACCOUNT_ID              => null
                       , aACS_PF_ACCOUNT_ID               => null
                       , aACS_PJ_ACCOUNT_ID               => null
                       , aACS_QTY_UNIT_ID                 => null
                       , aACS_PERIOD_ID                   => null
                       , aACS_ACS_FINANCIAL_CURRENCY_ID   => null
                       , aACS_TAX_CODE_ID                 => null
                        );
      end if;

      fetch ExpiriesCursor
       into ExpiriesCursorRow;
    end loop;

    close ExpiriesCursor;

    -- On ne tient plus compte des échéances dont les états journaux sont de type BRO !!!
    -- La fonction 'ACS_FUNCTION.PeriodSoldeAmount' se base sur les données de la table ACT_TOTAL_BY_PERIOD
    ACT_FUNCTIONS.SetAnalyse_Parameters(to_char(pPER_END_DATE, 'yyyymmdd'), aACC_NUMBER, aACC_NUMBER, '0');

    -- Si le type cumul de la transaction à la base du PO n'est pas reporté sur l'exercice suivant,
    -- sélection des PO de l'exercice courant uniquement
    if aC_SUB_SET = 'REC' then
      select nvl(sum(EXP_AMOUNT_LC - DET_PAIED_LC), 0)
           , nvl(sum(EXP_AMOUNT_FC - DET_PAIED_FC), 0)
           , nvl(sum(EXP_AMOUNT_EUR - DET_PAIED_EUR), 0)
        into TotExpiriesLC
           , TotExpiriesFC
           , TotExpiriesEUR
        from (select distinct SCA.C_TYPE_CUMUL
                         from ACJ_SUB_SET_CAT SCA
                            , ACJ_CATALOGUE_DOCUMENT CAT
                        where CAT.C_TYPE_CATALOGUE = '7'
                          and CAT.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID) CUM
           , V_ACT_EXPIRY_CUST_CTRL exp
       where exp.C_TYPE_CUMUL = CUM.C_TYPE_CUMUL(+)
         and exp.IMF_TRANSACTION_DATE >= decode(CUM.C_TYPE_CUMUL, null, pFYE_START_DATE, exp.IMF_TRANSACTION_DATE);
    else
      select nvl(sum(EXP_AMOUNT_LC - DET_PAIED_LC), 0) * -1
           , nvl(sum(EXP_AMOUNT_FC - DET_PAIED_FC), 0) * -1
           , nvl(sum(EXP_AMOUNT_EUR - DET_PAIED_EUR), 0) * -1
        into TotExpiriesLC
           , TotExpiriesFC
           , TotExpiriesEUR
        from (select distinct SCA.C_TYPE_CUMUL
                         from ACJ_SUB_SET_CAT SCA
                            , ACJ_CATALOGUE_DOCUMENT CAT
                        where CAT.C_TYPE_CATALOGUE = '7'
                          and CAT.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID) CUM
           , V_ACT_EXPIRY_SUPP_CTRL exp
       where exp.C_TYPE_CUMUL = CUM.C_TYPE_CUMUL(+)
         and exp.IMF_TRANSACTION_DATE >= decode(CUM.C_TYPE_CUMUL, null, pFYE_START_DATE, exp.IMF_TRANSACTION_DATE);
    end if;

    SoldeLC   :=
      ACS_FUNCTION.PeriodSoldeAmount(aACS_ACCOUNT_ID, null, PeriodId, 'EXT', 1, null) +
      ACS_FUNCTION.PeriodSoldeAmount(aACS_ACCOUNT_ID, null, PeriodId, 'INT', 1, null) +
      ACS_FUNCTION.PeriodSoldeAmount(aACS_ACCOUNT_ID, null, PeriodId, 'PRE', 1, null) +
      ACS_FUNCTION.PeriodSoldeAmount(aACS_ACCOUNT_ID, null, PeriodId, 'ENG', 1, null);

    if SoldeLC <> TotExpiriesLC then
      InsertCtrlDetail(aACR_CTRL_SUB_SET_ID             => aACR_CTRL_SUB_SET_ID
                     , aC_CTRL_CODE                     => '060'
                     , aACS_AUXILIARY_ACCOUNT_ID        => aACS_ACCOUNT_ID
                     , aCDE_AMOUNT1                     => TotExpiriesLC
                     , aCDE_AMOUNT2                     => SoldeLC
                     , aCDE_AMOUNT1_FC                  => null
                     , aCDE_AMOUNT2_FC                  => null
                     , aACT_DOCUMENT_ID                 => null
                     , aACT_PART_IMPUTATION_ID          => null
                     , aC_TYPE_CUMUL                    => null
                     , aACS_FINANCIAL_CURRENCY_ID       => null
                     , aACS_DIVISION_ACCOUNT_ID         => null
                     , aACS_FINANCIAL_ACCOUNT_ID        => null
                     , aACS_CPN_ACCOUNT_ID              => null
                     , aACS_CDA_ACCOUNT_ID              => null
                     , aACS_PF_ACCOUNT_ID               => null
                     , aACS_PJ_ACCOUNT_ID               => null
                     , aACS_QTY_UNIT_ID                 => null
                     , aACS_PERIOD_ID                   => null
                     , aACS_ACS_FINANCIAL_CURRENCY_ID   => null
                     , aACS_TAX_CODE_ID                 => null
                      );
    end if;
  end AccountExpiriesCtrl;

  /**
  * procedure DocWithoutExpiries
  * Description
  *  Partenaires: contrôle qu'un document contienne des échéances
  */
  procedure DocWithoutExpiries(
    aACR_CTRL_SUB_SET_ID in ACR_CTRL_SUB_SET.ACR_CTRL_SUB_SET_ID%type
  , pFYE_START_DATE      in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
  , pPER_END_DATE        in ACS_PERIOD.PER_END_DATE%type
  , aACS_ACCOUNT_ID      in ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aC_SUB_SET           in ACS_SUB_SET.C_SUB_SET%type
  )
  is
    type DocWithoutExpiriesCursorTyp is ref cursor;

    DocWithoutExpiriesCursor DocWithoutExpiriesCursorTyp;
    DocumentId               ACT_EXPIRY.ACT_DOCUMENT_ID%type;
    PartImputationId         ACT_EXPIRY.ACT_PART_IMPUTATION_ID%type;
  begin
    if aC_SUB_SET = 'REC' then
      open DocWithoutExpiriesCursor
       for
         select DOC.ACT_DOCUMENT_ID
              , PAR.ACT_PART_IMPUTATION_ID
           from ACT_FINANCIAL_IMPUTATION IMP
              , ACJ_CATALOGUE_DOCUMENT CATA
              , ACT_DOCUMENT DOC
              , ACT_PART_IMPUTATION PAR
              , PAC_CUSTOM_PARTNER CUS
          where CUS.ACS_AUXILIARY_ACCOUNT_ID = aACS_ACCOUNT_ID
            and CUS.PAC_CUSTOM_PARTNER_ID = PAR.PAC_CUSTOM_PARTNER_ID
            and PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
            and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CATA.ACJ_CATALOGUE_DOCUMENT_ID
            and C_TYPE_CATALOGUE <> '8'   -- Transaction de relance
            and PAR.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
            and IMP.IMF_TRANSACTION_DATE between pFYE_START_DATE and pPER_END_DATE
            and IMP.IMF_PRIMARY = 1
            and not exists(select ACT_EXPIRY_ID
                             from ACT_EXPIRY
                            where ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID);
    else
      open DocWithoutExpiriesCursor
       for
         select DOC.ACT_DOCUMENT_ID
              , PAR.ACT_PART_IMPUTATION_ID
           from ACT_FINANCIAL_IMPUTATION IMP
              , ACJ_CATALOGUE_DOCUMENT CATA
              , ACT_DOCUMENT DOC
              , ACT_PART_IMPUTATION PAR
              , PAC_SUPPLIER_PARTNER SUP
          where SUP.ACS_AUXILIARY_ACCOUNT_ID = aACS_ACCOUNT_ID
            and SUP.PAC_SUPPLIER_PARTNER_ID = PAR.PAC_SUPPLIER_PARTNER_ID
            and PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
            and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CATA.ACJ_CATALOGUE_DOCUMENT_ID
            and C_TYPE_CATALOGUE <> '8'   -- Transaction de relance
            and PAR.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
            and IMP.IMF_TRANSACTION_DATE between pFYE_START_DATE and pPER_END_DATE
            and IMP.IMF_PRIMARY = 1
            and not exists(select ACT_EXPIRY_ID
                             from ACT_EXPIRY
                            where ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID);
    end if;

    fetch DocWithoutExpiriesCursor
     into DocumentId
        , PartImputationId;

    while DocWithoutExpiriesCursor%found loop
      InsertCtrlDetail(aACR_CTRL_SUB_SET_ID             => aACR_CTRL_SUB_SET_ID
                     , aC_CTRL_CODE                     => '020'
                     , aACS_AUXILIARY_ACCOUNT_ID        => aACS_ACCOUNT_ID
                     , aCDE_AMOUNT1                     => null
                     , aCDE_AMOUNT2                     => null
                     , aCDE_AMOUNT1_FC                  => null
                     , aCDE_AMOUNT2_FC                  => null
                     , aACT_DOCUMENT_ID                 => DocumentId
                     , aACT_PART_IMPUTATION_ID          => PartImputationId
                     , aC_TYPE_CUMUL                    => null
                     , aACS_FINANCIAL_CURRENCY_ID       => null
                     , aACS_DIVISION_ACCOUNT_ID         => null
                     , aACS_FINANCIAL_ACCOUNT_ID        => null
                     , aACS_CPN_ACCOUNT_ID              => null
                     , aACS_CDA_ACCOUNT_ID              => null
                     , aACS_PF_ACCOUNT_ID               => null
                     , aACS_PJ_ACCOUNT_ID               => null
                     , aACS_QTY_UNIT_ID                 => null
                     , aACS_PERIOD_ID                   => null
                     , aACS_ACS_FINANCIAL_CURRENCY_ID   => null
                     , aACS_TAX_CODE_ID                 => null
                      );

      fetch DocWithoutExpiriesCursor
       into DocumentId
          , PartImputationId;
    end loop;

    close DocWithoutExpiriesCursor;
  end DocWithoutExpiries;

  /**
  * procedure TotalAccountCtrl
  * Description
  *  Partenaires: contrôle que le total des cumuls corresponde au total des imputations
  */
  procedure TotalAccountCtrl(
    aACR_CTRL_SUB_SET_ID in ACR_CTRL_SUB_SET.ACR_CTRL_SUB_SET_ID%type
  , pFYE_START_DATE      in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
  , pPER_END_DATE        in ACS_PERIOD.PER_END_DATE%type
  , aACS_ACCOUNT_ID      in ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , aC_SUB_SET           in ACS_SUB_SET.C_SUB_SET%type
  )
  is
    cursor TotalImputationCursor(
      pACS_FINANCIAL_YEAR_ID    in ACS_PERIOD.ACS_FINANCIAL_YEAR_ID%type
    , pACS_AUXILIARY_ACCOUNT_ID in ACT_FINANCIAL_IMPUTATION.ACS_AUXILIARY_ACCOUNT_ID%type
    , pFYE_START_DATE           in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
    , pPER_END_DATE             in ACS_PERIOD.PER_END_DATE%type
    , pC_SUB_SET                in ACS_SUB_SET.C_SUB_SET%type
    , pPrevYearClosed           in number
    )
    is
      select   SCA.C_TYPE_CUMUL
             , sum(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C) IMF_AMOUNT_LC
             , IMP.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
          from ACJ_SUB_SET_CAT SCA
             , ACT_ETAT_JOURNAL ETA
             , ACJ_CATALOGUE_DOCUMENT CAT
             , ACT_DOCUMENT DOC
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACS_SUB_SET SUB
             , ACS_ACCOUNT AUX
             , ACT_FINANCIAL_IMPUTATION IMP
             , ACS_PERIOD PER
         where PER.ACS_FINANCIAL_YEAR_ID = pACS_FINANCIAL_YEAR_ID
           and PER.ACS_PERIOD_ID = IMP.ACS_PERIOD_ID
           and IMP.ACS_AUXILIARY_ACCOUNT_ID = pACS_AUXILIARY_ACCOUNT_ID
           and IMP.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_ACCOUNT_ID
           and AUX.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
           and SUB.SSE_TOTAL = 1
           and IMP.IMF_TRANSACTION_DATE between pFYE_START_DATE and pPER_END_DATE
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and FIN.FIN_COLLECTIVE = 1
           and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
           and DOC.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
           and ETA.C_SUB_SET = pC_SUB_SET
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
           and SCA.C_SUB_SET = pC_SUB_SET
           and ETA.C_ETAT_JOURNAL <> 'BRO'
           and (   pPrevYearClosed = 1
                or (    pPrevYearClosed = 0
                    and CAT.C_TYPE_PERIOD <> '1') )
      group by SCA.C_TYPE_CUMUL
             , IMP.IMF_ACS_DIVISION_ACCOUNT_ID;

    cursor TotalImputationCursorFC(
      pACS_FINANCIAL_YEAR_ID    in ACS_PERIOD.ACS_FINANCIAL_YEAR_ID%type
    , pACS_AUXILIARY_ACCOUNT_ID in ACT_FINANCIAL_IMPUTATION.ACS_AUXILIARY_ACCOUNT_ID%type
    , pFYE_START_DATE           in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
    , pPER_END_DATE             in ACS_PERIOD.PER_END_DATE%type
    , pC_SUB_SET                in ACS_SUB_SET.C_SUB_SET%type
    , pPrevYearClosed           in number
    )
    is
      select   SCA.C_TYPE_CUMUL
             , sum(IMF_AMOUNT_FC_D - IMF_AMOUNT_FC_C) IMF_AMOUNT_FC
             , IMP.ACS_FINANCIAL_CURRENCY_ID
             , IMP.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
          from ACS_AUX_ACCOUNT_S_FIN_CURR ACU
             , ACJ_SUB_SET_CAT SCA
             , ACT_ETAT_JOURNAL ETA
             , ACJ_CATALOGUE_DOCUMENT CAT
             , ACT_DOCUMENT DOC
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACS_SUB_SET SUB
             , ACS_ACCOUNT AUX
             , ACT_FINANCIAL_IMPUTATION IMP
             , ACS_PERIOD PER
         where PER.ACS_FINANCIAL_YEAR_ID = pACS_FINANCIAL_YEAR_ID
           and PER.ACS_PERIOD_ID = IMP.ACS_PERIOD_ID
           and IMP.ACS_AUXILIARY_ACCOUNT_ID = pACS_AUXILIARY_ACCOUNT_ID
           and IMP.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_ACCOUNT_ID
           and AUX.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
           and SUB.SSE_TOTAL = 1
           and IMP.IMF_TRANSACTION_DATE between pFYE_START_DATE and pPER_END_DATE
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and FIN.FIN_COLLECTIVE = 1
           and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
           and IMP.ACS_FINANCIAL_CURRENCY_ID <> LocalCurrencyId
           and DOC.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
           and ETA.C_SUB_SET = pC_SUB_SET
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
           and SCA.C_SUB_SET = pC_SUB_SET
           and ETA.C_ETAT_JOURNAL <> 'BRO'
           and ACU.ACS_AUXILIARY_ACCOUNT_ID = pACS_AUXILIARY_ACCOUNT_ID
           and ACU.ACS_FINANCIAL_CURRENCY_ID = IMP.ACS_FINANCIAL_CURRENCY_ID
           and (   pPrevYearClosed = 1
                or (    pPrevYearClosed = 0
                    and CAT.C_TYPE_PERIOD <> '1') )
      group by SCA.C_TYPE_CUMUL
             , IMP.ACS_FINANCIAL_CURRENCY_ID
             , IMP.IMF_ACS_DIVISION_ACCOUNT_ID;

    cursor TotalCumulAccountCursor(
      pACS_FINANCIAL_YEAR_ID    in ACS_PERIOD.ACS_FINANCIAL_YEAR_ID%type
    , pACS_AUXILIARY_ACCOUNT_ID in ACT_TOTAL_BY_PERIOD.ACS_AUXILIARY_ACCOUNT_ID%type
    , pFYE_START_DATE           in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
    , pPER_END_DATE             in ACS_PERIOD.PER_END_DATE%type
    , pAllPeriod                in number
    )
    is
      select   nvl(sum(TOT.TOT_DEBIT_LC - TOT.TOT_CREDIT_LC), 0) TOT_DEBIT_LC
             , nvl(sum(TOT.TOT_DEBIT_FC - TOT.TOT_CREDIT_FC), 0) TOT_DEBIT_FC
             , TOT.ACS_FINANCIAL_ACCOUNT_ID
             , TOT.ACS_DIVISION_ACCOUNT_ID
             , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
             , TOT.C_TYPE_CUMUL
          from ACT_TOTAL_BY_PERIOD TOT
             , ACS_PERIOD PER
         where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
           and PER.ACS_FINANCIAL_YEAR_ID = pACS_FINANCIAL_YEAR_ID
           and PER.PER_START_DATE >= pFYE_START_DATE
           and PER.PER_END_DATE <= pPER_END_DATE
           and TOT.ACS_AUXILIARY_ACCOUNT_ID = pACS_AUXILIARY_ACCOUNT_ID
           and (   pAllPeriod = 1
                or (    pAllPeriod = 0
                    and TOT.C_TYPE_PERIOD = '2') )
      group by ACS_FINANCIAL_ACCOUNT_ID
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_ACS_FINANCIAL_CURRENCY_ID
             , C_TYPE_CUMUL;

    TotalImp          TotalImputationCursor%rowtype;
    TotalImpFC        TotalImputationCursorFC%rowtype;
    TotalCumulAccount TotalCumulAccountCursor%rowtype;
    YearId            ACS_PERIOD.ACS_FINANCIAL_YEAR_ID%type;
    vEndPeriodDate    ACS_PERIOD.PER_END_DATE%type;
    TotalAmount       ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
    YearStatus        ACS_FINANCIAL_YEAR.C_STATE_FINANCIAL_YEAR%type;
    AllPeriod         number(1);

    function GetTotalCumul(
      pACS_AUXILIARY_ACCOUNT_ID  in ACT_TOTAL_BY_PERIOD.ACS_AUXILIARY_ACCOUNT_ID%type
    , pACS_DIVISION_ACCOUNT_ID   in ACT_TOTAL_BY_PERIOD.ACS_DIVISION_ACCOUNT_ID%type
    , pACS_FINANCIAL_YEAR_ID     in ACS_PERIOD.ACS_FINANCIAL_YEAR_ID%type
    , pFYE_START_DATE            in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
    , pPER_END_DATE              in ACS_PERIOD.PER_END_DATE%type
    , pC_TYPE_CUMUL              in ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type
    , pACS_FINANCIAL_CURRENCY_ID in ACT_TOTAL_BY_PERIOD.ACS_FINANCIAL_CURRENCY_ID%type
    , pPrevYearClosed            in boolean
    )
      return ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type
    is
      Amount   ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
      AmountLC ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
      AmountFC ACT_TOTAL_BY_PERIOD.TOT_DEBIT_FC%type;
    begin
      if pPrevYearClosed then
        select nvl(sum(TOT_DEBIT_LC - TOT_CREDIT_LC), 0)
             , nvl(sum(TOT_DEBIT_FC - TOT_CREDIT_FC), 0)
          into AmountLC
             , AmountFC
          from ACT_TOTAL_BY_PERIOD TOT
             , ACS_PERIOD PER
         where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
           and TOT.ACS_AUXILIARY_ACCOUNT_ID = pACS_AUXILIARY_ACCOUNT_ID
           and PER.ACS_FINANCIAL_YEAR_ID = pACS_FINANCIAL_YEAR_ID
           and PER.PER_START_DATE >= pFYE_START_DATE
           and PER.PER_END_DATE <= pPER_END_DATE
           and TOT.C_TYPE_CUMUL = pC_TYPE_CUMUL
           and (    (    pACS_DIVISION_ACCOUNT_ID is null
                     and TOT.ACS_DIVISION_ACCOUNT_ID is null)
                or (    pACS_DIVISION_ACCOUNT_ID is not null
                    and TOT.ACS_DIVISION_ACCOUNT_ID = pACS_DIVISION_ACCOUNT_ID)
               )
           and (   pACS_FINANCIAL_CURRENCY_ID is null
                or (    pACS_FINANCIAL_CURRENCY_ID is not null
                    and pACS_FINANCIAL_CURRENCY_ID = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                   )
               );
      else
        select nvl(sum(TOT_DEBIT_LC - TOT_CREDIT_LC), 0)
             , nvl(sum(TOT_DEBIT_FC - TOT_CREDIT_FC), 0)
          into AmountLC
             , AmountFC
          from ACT_TOTAL_BY_PERIOD TOT
             , ACS_PERIOD PER
         where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
           and TOT.ACS_AUXILIARY_ACCOUNT_ID = pACS_AUXILIARY_ACCOUNT_ID
           and PER.ACS_FINANCIAL_YEAR_ID = pACS_FINANCIAL_YEAR_ID
           and PER.PER_START_DATE >= pFYE_START_DATE
           and PER.PER_END_DATE <= pPER_END_DATE
           and TOT.C_TYPE_CUMUL = pC_TYPE_CUMUL
           and TOT.C_TYPE_PERIOD <> '1'
           and (    (    pACS_DIVISION_ACCOUNT_ID is null
                     and TOT.ACS_DIVISION_ACCOUNT_ID is null)
                or (    pACS_DIVISION_ACCOUNT_ID is not null
                    and TOT.ACS_DIVISION_ACCOUNT_ID = pACS_DIVISION_ACCOUNT_ID)
               )
           and (   pACS_FINANCIAL_CURRENCY_ID is null
                or (    pACS_FINANCIAL_CURRENCY_ID is not null
                    and pACS_FINANCIAL_CURRENCY_ID = TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                   )
               );
      end if;

      if pACS_FINANCIAL_CURRENCY_ID is null then
        Amount  := AmountLC;
      else
        Amount  := AmountFC;
      end if;

      return Amount;
    end GetTotalCumul;

    function GetTotalImputations(
      pACS_AUXILIARY_ACCOUNT_ID  in ACT_TOTAL_BY_PERIOD.ACS_AUXILIARY_ACCOUNT_ID%type
    , pACS_FINANCIAL_ACCOUNT_ID  in ACT_TOTAL_BY_PERIOD.ACS_FINANCIAL_ACCOUNT_ID%type
    , pACS_DIVISION_ACCOUNT_ID   in ACT_TOTAL_BY_PERIOD.ACS_DIVISION_ACCOUNT_ID%type
    , pACS_FINANCIAL_YEAR_ID     in ACS_PERIOD.ACS_FINANCIAL_YEAR_ID%type
    , pFYE_START_DATE            in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
    , pPER_END_DATE              in ACS_PERIOD.PER_END_DATE%type
    , pC_SUB_SET                 in ACS_SUB_SET.C_SUB_SET%type
    , pC_TYPE_CUMUL              in ACT_TOTAL_BY_PERIOD.C_TYPE_CUMUL%type
    , pACS_FINANCIAL_CURRENCY_ID in ACT_TOTAL_BY_PERIOD.ACS_FINANCIAL_CURRENCY_ID%type
    )
      return ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type
    is
      Amount ACT_TOTAL_BY_PERIOD.TOT_DEBIT_LC%type;
    begin
      if pACS_FINANCIAL_CURRENCY_ID <> LocalCurrencyId then
        select nvl(sum(IMF_AMOUNT_FC_D - IMF_AMOUNT_FC_C), 0)
          into Amount
          from ACJ_SUB_SET_CAT SCA
             , ACT_ETAT_JOURNAL ETA
             , ACT_DOCUMENT DOC
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACS_SUB_SET SUB
             , ACS_ACCOUNT AUX
             , ACT_FINANCIAL_IMPUTATION IMP
             , ACS_PERIOD PER
         where PER.ACS_FINANCIAL_YEAR_ID = pACS_FINANCIAL_YEAR_ID
           and PER.ACS_PERIOD_ID = IMP.ACS_PERIOD_ID
           and IMP.ACS_AUXILIARY_ACCOUNT_ID = pACS_AUXILIARY_ACCOUNT_ID
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = pACS_FINANCIAL_ACCOUNT_ID
           and IMP.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_ACCOUNT_ID
           and AUX.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
           and SUB.SSE_TOTAL = 1
           and IMP.IMF_TRANSACTION_DATE between pFYE_START_DATE and pPER_END_DATE
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and FIN.FIN_COLLECTIVE = 1
           and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and DOC.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
           and ETA.C_SUB_SET = aC_SUB_SET
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
           and SCA.C_SUB_SET = pC_SUB_SET
           and SCA.C_TYPE_CUMUL = pC_TYPE_CUMUL
           and ETA.C_ETAT_JOURNAL <> 'BRO'
           and (    (    pACS_DIVISION_ACCOUNT_ID is not null
                     and IMP.IMF_ACS_DIVISION_ACCOUNT_ID = pACS_DIVISION_ACCOUNT_ID
                    )
                or pACS_DIVISION_ACCOUNT_ID is null
               )
           and (IMP.ACS_FINANCIAL_CURRENCY_ID = pACS_FINANCIAL_CURRENCY_ID);
      else
        select nvl(sum(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C), 0)
          into Amount
          from ACJ_SUB_SET_CAT SCA
             , ACT_ETAT_JOURNAL ETA
             , ACT_DOCUMENT DOC
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACS_SUB_SET SUB
             , ACS_ACCOUNT AUX
             , ACT_FINANCIAL_IMPUTATION IMP
             , ACS_PERIOD PER
         where PER.ACS_FINANCIAL_YEAR_ID = pACS_FINANCIAL_YEAR_ID
           and PER.ACS_PERIOD_ID = IMP.ACS_PERIOD_ID
           and IMP.ACS_AUXILIARY_ACCOUNT_ID = pACS_AUXILIARY_ACCOUNT_ID
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = pACS_FINANCIAL_ACCOUNT_ID
           and IMP.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_ACCOUNT_ID
           and AUX.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
           and SUB.SSE_TOTAL = 1
           and IMP.IMF_TRANSACTION_DATE between pFYE_START_DATE and pPER_END_DATE
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and FIN.FIN_COLLECTIVE = 1
           and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and DOC.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
           and ETA.C_SUB_SET = pC_SUB_SET
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
           and SCA.C_SUB_SET = pC_SUB_SET
           and SCA.C_TYPE_CUMUL = pC_TYPE_CUMUL
           and ETA.C_ETAT_JOURNAL <> 'BRO'
           and (    (    pACS_DIVISION_ACCOUNT_ID is not null
                     and IMP.IMF_ACS_DIVISION_ACCOUNT_ID = pACS_DIVISION_ACCOUNT_ID
                    )
                or pACS_DIVISION_ACCOUNT_ID is null
               )
           and ( (IMP.ACS_FINANCIAL_CURRENCY_ID = pACS_FINANCIAL_CURRENCY_ID) );
      end if;

      return Amount;
    end GetTotalImputations;
  begin
    YearId          := ACS_FUNCTION.GetFinancialYearId(pPER_END_DATE);
    vEndPeriodDate  := ACR_FINANCIAL_CTRL.GetEndPeriodDate(pPER_END_DATE);
    YearStatus      := ACS_FUNCTION.GetStatePreviousFinancialYear(YearId);

    if    YearStatus is null
       or YearStatus = 'CLO' then
      AllPeriod  := 1;
    else
      AllPeriod  := 0;
    end if;

    -- Contrôle Cumuls -> Imputations -> MB
    open TotalImputationCursor(YearId, aACS_ACCOUNT_ID, pFYE_START_DATE, vEndPeriodDate, aC_SUB_SET, AllPeriod);

    fetch TotalImputationCursor
     into TotalImp;

    while TotalImputationCursor%found loop
      TotalAmount  :=
        GetTotalCumul(aACS_ACCOUNT_ID
                    , TotalImp.ACS_DIVISION_ACCOUNT_ID
                    , YearId
                    , pFYE_START_DATE
                    , vEndPeriodDate
                    , TotalImp.C_TYPE_CUMUL
                    , null
                    , AllPeriod = 1
                     );

      if TotalImp.IMF_AMOUNT_LC <> TotalAmount then
        InsertCtrlDetail(aACR_CTRL_SUB_SET_ID             => aACR_CTRL_SUB_SET_ID
                       , aC_CTRL_CODE                     => '041'
                       , aACS_AUXILIARY_ACCOUNT_ID        => aACS_ACCOUNT_ID
                       , aCDE_AMOUNT1                     => TotalAmount
                       , aCDE_AMOUNT2                     => TotalImp.IMF_AMOUNT_LC
                       , aCDE_AMOUNT1_FC                  => null
                       , aCDE_AMOUNT2_FC                  => null
                       , aACT_DOCUMENT_ID                 => null
                       , aACT_PART_IMPUTATION_ID          => null
                       , aC_TYPE_CUMUL                    => TotalImp.C_TYPE_CUMUL
                       , aACS_FINANCIAL_CURRENCY_ID       => null
                       , aACS_DIVISION_ACCOUNT_ID         => TotalImp.ACS_DIVISION_ACCOUNT_ID
                       , aACS_FINANCIAL_ACCOUNT_ID        => null
                       , aACS_CPN_ACCOUNT_ID              => null
                       , aACS_CDA_ACCOUNT_ID              => null
                       , aACS_PF_ACCOUNT_ID               => null
                       , aACS_PJ_ACCOUNT_ID               => null
                       , aACS_QTY_UNIT_ID                 => null
                       , aACS_PERIOD_ID                   => null
                       , aACS_ACS_FINANCIAL_CURRENCY_ID   => null
                       , aACS_TAX_CODE_ID                 => null
                        );
      end if;

      fetch TotalImputationCursor
       into TotalImp;
    end loop;

    close TotalImputationCursor;

    -- Contrôle Cumuls -> Imputations -> FC
    open TotalImputationCursorFC(YearId, aACS_ACCOUNT_ID, pFYE_START_DATE, vEndPeriodDate, aC_SUB_SET, AllPeriod);

    fetch TotalImputationCursorFC
     into TotalImpFC;

    while TotalImputationCursorFC%found loop
      TotalAmount  :=
        GetTotalCumul(aACS_ACCOUNT_ID
                    , TotalImpFC.ACS_DIVISION_ACCOUNT_ID
                    , YearId
                    , pFYE_START_DATE
                    , vEndPeriodDate
                    , TotalImpFC.C_TYPE_CUMUL
                    , TotalImpFC.ACS_FINANCIAL_CURRENCY_ID
                    , AllPeriod = 1
                     );

      if TotalImpFC.IMF_AMOUNT_FC <> TotalAmount then
        InsertCtrlDetail(aACR_CTRL_SUB_SET_ID             => aACR_CTRL_SUB_SET_ID
                       , aC_CTRL_CODE                     => '042'
                       , aACS_AUXILIARY_ACCOUNT_ID        => aACS_ACCOUNT_ID
                       , aCDE_AMOUNT1                     => null
                       , aCDE_AMOUNT2                     => null
                       , aCDE_AMOUNT1_FC                  => TotalAmount
                       , aCDE_AMOUNT2_FC                  => TotalImpFC.IMF_AMOUNT_FC
                       , aACT_DOCUMENT_ID                 => null
                       , aACT_PART_IMPUTATION_ID          => null
                       , aC_TYPE_CUMUL                    => TotalImpFC.C_TYPE_CUMUL
                       , aACS_FINANCIAL_CURRENCY_ID       => TotalImpFC.ACS_FINANCIAL_CURRENCY_ID
                       , aACS_DIVISION_ACCOUNT_ID         => TotalImpFC.ACS_DIVISION_ACCOUNT_ID
                       , aACS_FINANCIAL_ACCOUNT_ID        => null
                       , aACS_CPN_ACCOUNT_ID              => null
                       , aACS_CDA_ACCOUNT_ID              => null
                       , aACS_PF_ACCOUNT_ID               => null
                       , aACS_PJ_ACCOUNT_ID               => null
                       , aACS_QTY_UNIT_ID                 => null
                       , aACS_PERIOD_ID                   => null
                       , aACS_ACS_FINANCIAL_CURRENCY_ID   => null
                       , aACS_TAX_CODE_ID                 => null
                        );
      end if;

      fetch TotalImputationCursorFC
       into TotalImpFC;
    end loop;

    close TotalImputationCursorFC;

    -- Contrôle Cumuls -> Imputations
    open TotalCumulAccountCursor(YearId, aACS_ACCOUNT_ID, pFYE_START_DATE, vEndPeriodDate, AllPeriod);

    fetch TotalCumulAccountCursor
     into TotalCumulAccount;

    while TotalCumulAccountCursor%found loop
      TotalAmount  :=
        GetTotalImputations(aACS_ACCOUNT_ID
                          , TotalCumulAccount.ACS_FINANCIAL_ACCOUNT_ID
                          , TotalCumulAccount.ACS_DIVISION_ACCOUNT_ID
                          , YearId
                          , pFYE_START_DATE
                          , vEndPeriodDate
                          , aC_SUB_SET
                          , TotalCumulAccount.C_TYPE_CUMUL
                          , TotalCumulAccount.ACS_ACS_FINANCIAL_CURRENCY_ID
                           );

      -- Contrôle FC
      if (    TotalCumulAccount.ACS_ACS_FINANCIAL_CURRENCY_ID <> LocalCurrencyId
          and TotalCumulAccount.TOT_DEBIT_FC <> TotalAmount
         ) then
        InsertCtrlDetail(aACR_CTRL_SUB_SET_ID             => aACR_CTRL_SUB_SET_ID
                       , aC_CTRL_CODE                     => '042'
                       , aACS_AUXILIARY_ACCOUNT_ID        => aACS_ACCOUNT_ID
                       , aCDE_AMOUNT1                     => null
                       , aCDE_AMOUNT2                     => null
                       , aCDE_AMOUNT1_FC                  => TotalCumulAccount.TOT_DEBIT_FC
                       , aCDE_AMOUNT2_FC                  => TotalAmount
                       , aACT_DOCUMENT_ID                 => null
                       , aACT_PART_IMPUTATION_ID          => null
                       , aC_TYPE_CUMUL                    => TotalCumulAccount.C_TYPE_CUMUL
                       , aACS_FINANCIAL_CURRENCY_ID       => TotalCumulAccount.ACS_ACS_FINANCIAL_CURRENCY_ID
                       , aACS_DIVISION_ACCOUNT_ID         => TotalCumulAccount.ACS_DIVISION_ACCOUNT_ID
                       , aACS_FINANCIAL_ACCOUNT_ID        => null
                       , aACS_CPN_ACCOUNT_ID              => null
                       , aACS_CDA_ACCOUNT_ID              => null
                       , aACS_PF_ACCOUNT_ID               => null
                       , aACS_PJ_ACCOUNT_ID               => null
                       , aACS_QTY_UNIT_ID                 => null
                       , aACS_PERIOD_ID                   => null
                       , aACS_ACS_FINANCIAL_CURRENCY_ID   => null
                       , aACS_TAX_CODE_ID                 => null
                        );
      -- Contrôle MB
      elsif(    TotalCumulAccount.ACS_ACS_FINANCIAL_CURRENCY_ID = LocalCurrencyId
            and TotalCumulAccount.TOT_DEBIT_LC <> TotalAmount
           ) then
        InsertCtrlDetail(aACR_CTRL_SUB_SET_ID             => aACR_CTRL_SUB_SET_ID
                       , aC_CTRL_CODE                     => '041'
                       , aACS_AUXILIARY_ACCOUNT_ID        => aACS_ACCOUNT_ID
                       , aCDE_AMOUNT1                     => TotalCumulAccount.TOT_DEBIT_LC
                       , aCDE_AMOUNT2                     => TotalAmount
                       , aCDE_AMOUNT1_FC                  => null
                       , aCDE_AMOUNT2_FC                  => null
                       , aACT_DOCUMENT_ID                 => null
                       , aACT_PART_IMPUTATION_ID          => null
                       , aC_TYPE_CUMUL                    => TotalCumulAccount.C_TYPE_CUMUL
                       , aACS_FINANCIAL_CURRENCY_ID       => null
                       , aACS_DIVISION_ACCOUNT_ID         => TotalCumulAccount.ACS_DIVISION_ACCOUNT_ID
                       , aACS_FINANCIAL_ACCOUNT_ID        => null
                       , aACS_CPN_ACCOUNT_ID              => null
                       , aACS_CDA_ACCOUNT_ID              => null
                       , aACS_PF_ACCOUNT_ID               => null
                       , aACS_PJ_ACCOUNT_ID               => null
                       , aACS_QTY_UNIT_ID                 => null
                       , aACS_PERIOD_ID                   => null
                       , aACS_ACS_FINANCIAL_CURRENCY_ID   => null
                       , aACS_TAX_CODE_ID                 => null
                        );
      end if;

      fetch TotalCumulAccountCursor
       into TotalCumulAccount;
    end loop;

    close TotalCumulAccountCursor;
  end TotalAccountCtrl;

  /**
  * procedure AdvancedPaymentCtrl
  * Description
  *  Partenaires: paiement antérieur à la date de comptabilisation
  */
  procedure AdvancedPaymentCtrl(
    pACR_CTRL_SUB_SET_ID in ACR_CTRL_SUB_SET.ACR_CTRL_SUB_SET_ID%type
  , pFYE_START_DATE      in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
  , pFYE_END_DATE        in ACS_FINANCIAL_YEAR.FYE_END_DATE%type
  , pACS_ACCOUNT_ID      in ACS_ACCOUNT.ACS_ACCOUNT_ID%type
  , pC_SUB_SET           in ACS_SUB_SET.C_SUB_SET%type
  )
  is
    type AdvancedPaymentCursorTyp is ref cursor;

    vAdvancedPaymentCursor AdvancedPaymentCursorTyp;
    vDocumentId            ACT_EXPIRY.ACT_DOCUMENT_ID%type;
    vPartImputationId      ACT_EXPIRY.ACT_PART_IMPUTATION_ID%type;
  begin
    if pC_SUB_SET = 'REC' then
      open vAdvancedPaymentCursor
       for
         select PAY.ACT_DOCUMENT_ID
              , PAY.ACT_PART_IMPUTATION_ID
           from ACT_FINANCIAL_IMPUTATION IMPPAY
              , ACT_DET_PAYMENT PAY
              , ACS_FINANCIAL_ACCOUNT FIN
              , ACT_FINANCIAL_IMPUTATION IMPEXP
              , ACT_EXPIRY exp
          where exp.EXP_PAC_CUSTOM_PARTNER_ID in(select CUS.PAC_CUSTOM_PARTNER_ID
                                                   from PAC_CUSTOM_PARTNER CUS
                                                  where CUS.ACS_AUXILIARY_ACCOUNT_ID = pACS_ACCOUNT_ID)
            and to_number(exp.C_STATUS_EXPIRY) + 0 <> 9
            and exp.EXP_CALC_NET = 1
            and exp.ACT_PART_IMPUTATION_ID = IMPEXP.ACT_PART_IMPUTATION_ID
            and IMPEXP.ACT_DET_PAYMENT_ID is null
            and IMPEXP.ACS_AUXILIARY_ACCOUNT_ID is not null
            and IMPEXP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
            and FIN.FIN_COLLECTIVE = 1
            and exp.ACT_EXPIRY_ID = PAY.ACT_EXPIRY_ID
            and PAY.ACT_DET_PAYMENT_ID = IMPPAY.ACT_DET_PAYMENT_ID
            and IMPPAY.C_GENRE_TRANSACTION = '1'
            and (   IMPEXP.IMF_TRANSACTION_DATE between pFYE_START_DATE and pFYE_END_DATE
                 or IMPPAY.IMF_TRANSACTION_DATE between pFYE_START_DATE and pFYE_END_DATE
                )
            and IMPPAY.IMF_TRANSACTION_DATE < IMPEXP.IMF_TRANSACTION_DATE
            and IMPPAY.ACS_PERIOD_ID <> IMPEXP.ACS_PERIOD_ID;
    else
      open vAdvancedPaymentCursor
       for
         select PAY.ACT_DOCUMENT_ID
              , PAY.ACT_PART_IMPUTATION_ID
           from ACT_FINANCIAL_IMPUTATION IMPPAY
              , ACT_DET_PAYMENT PAY
              , ACS_FINANCIAL_ACCOUNT FIN
              , ACT_FINANCIAL_IMPUTATION IMPEXP
              , ACT_EXPIRY exp
          where exp.EXP_PAC_SUPPLIER_PARTNER_ID in(select SUP.PAC_SUPPLIER_PARTNER_ID
                                                     from PAC_SUPPLIER_PARTNER SUP
                                                    where SUP.ACS_AUXILIARY_ACCOUNT_ID = pACS_ACCOUNT_ID)
            and to_number(exp.C_STATUS_EXPIRY) + 0 <> 9
            and exp.EXP_CALC_NET = 1
            and exp.ACT_PART_IMPUTATION_ID = IMPEXP.ACT_PART_IMPUTATION_ID
            and IMPEXP.ACT_DET_PAYMENT_ID is null
            and IMPEXP.ACS_AUXILIARY_ACCOUNT_ID is not null
            and IMPEXP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
            and FIN.FIN_COLLECTIVE = 1
            and exp.ACT_EXPIRY_ID = PAY.ACT_EXPIRY_ID
            and PAY.ACT_DET_PAYMENT_ID = IMPPAY.ACT_DET_PAYMENT_ID
            and IMPPAY.C_GENRE_TRANSACTION = '1'
            and (   IMPEXP.IMF_TRANSACTION_DATE between pFYE_START_DATE and pFYE_END_DATE
                 or IMPPAY.IMF_TRANSACTION_DATE between pFYE_START_DATE and pFYE_END_DATE
                )
            and IMPPAY.IMF_TRANSACTION_DATE < IMPEXP.IMF_TRANSACTION_DATE
            and IMPPAY.ACS_PERIOD_ID <> IMPEXP.ACS_PERIOD_ID;
    end if;

    fetch vAdvancedPaymentCursor
     into vDocumentId
        , vPartImputationId;

    while vAdvancedPaymentCursor%found loop
      InsertCtrlDetail(aACR_CTRL_SUB_SET_ID             => pACR_CTRL_SUB_SET_ID
                     , aC_CTRL_CODE                     => '050'
                     , aACS_AUXILIARY_ACCOUNT_ID        => pACS_ACCOUNT_ID
                     , aCDE_AMOUNT1                     => null
                     , aCDE_AMOUNT2                     => null
                     , aCDE_AMOUNT1_FC                  => null
                     , aCDE_AMOUNT2_FC                  => null
                     , aACT_DOCUMENT_ID                 => vDocumentId
                     , aACT_PART_IMPUTATION_ID          => vPartImputationId
                     , aC_TYPE_CUMUL                    => null
                     , aACS_FINANCIAL_CURRENCY_ID       => null
                     , aACS_DIVISION_ACCOUNT_ID         => null
                     , aACS_FINANCIAL_ACCOUNT_ID        => null
                     , aACS_CPN_ACCOUNT_ID              => null
                     , aACS_CDA_ACCOUNT_ID              => null
                     , aACS_PF_ACCOUNT_ID               => null
                     , aACS_PJ_ACCOUNT_ID               => null
                     , aACS_QTY_UNIT_ID                 => null
                     , aACS_PERIOD_ID                   => null
                     , aACS_ACS_FINANCIAL_CURRENCY_ID   => null
                     , aACS_TAX_CODE_ID                 => null
                      );

      fetch vAdvancedPaymentCursor
       into vDocumentId
          , vPartImputationId;
    end loop;
  end AdvancedPaymentCtrl;

  /**
  * procedure FinAccountCtrl
  * Description
  *  Contrôle des comptes financiers ACC, cohérence entre cumuls et imputations
  */
  procedure FinAccountCtrl(
    aACR_CTRL_SUB_SET_ID in ACR_CTRL_SUB_SET.ACR_CTRL_SUB_SET_ID%type
  , pFYE_START_DATE      in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
  , pPER_END_DATE        in ACS_PERIOD.PER_END_DATE%type
  )
  is
    cursor SumTotByPeriodCursor(
      pACS_FINANCIAL_YEAR_ID ACS_PERIOD.ACS_FINANCIAL_YEAR_ID%type
    , pFYE_START_DATE        ACS_FINANCIAL_YEAR.FYE_START_DATE%type
    , pPER_END_DATE          ACS_PERIOD.PER_END_DATE%type
    , pAllPeriod             number
    , pExistDivi             number
    )
    is
      select   nvl(sum(TOT.TOT_DEBIT_LC - TOT.TOT_CREDIT_LC), 0) AMOUNT_LC
             , nvl(sum(TOT.TOT_DEBIT_FC - TOT.TOT_CREDIT_FC), 0) AMOUNT_FC
             , nvl(TOT.ACS_FINANCIAL_ACCOUNT_ID, 0) ACS_FINANCIAL_ACCOUNT_ID
             , nvl(TOT.ACS_DIVISION_ACCOUNT_ID, 0) ACS_DIVISION_ACCOUNT_ID
             , TOT.ACS_FINANCIAL_CURRENCY_ID
             , nvl(TOT.ACS_ACS_FINANCIAL_CURRENCY_ID, 0) ACS_ACS_FINANCIAL_CURRENCY_ID
             , TOT.ACS_PERIOD_ID
             , TOT.C_TYPE_CUMUL
             , 0 TREATY
          from ACT_TOTAL_BY_PERIOD TOT
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACS_PERIOD PER
         where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
           and PER.ACS_FINANCIAL_YEAR_ID = pACS_FINANCIAL_YEAR_ID
           and PER.PER_START_DATE >= pFYE_START_DATE
           and PER.PER_END_DATE <= pPER_END_DATE
           and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
           and TOT.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and FIN.C_BALANCE_SHEET_PROFIT_LOSS = 'B'
           and (   pAllPeriod = 1
                or (    pAllPeriod = 0
                    and TOT.C_TYPE_PERIOD <> '1') )
           and (   pExistDivi = 0
                or (    pExistDivi = 1
                    and TOT.ACS_DIVISION_ACCOUNT_ID is not null) )
      group by TOT.ACS_FINANCIAL_ACCOUNT_ID
             , TOT.ACS_DIVISION_ACCOUNT_ID
             , TOT.ACS_PERIOD_ID
             , TOT.ACS_FINANCIAL_CURRENCY_ID
             , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
             , TOT.C_TYPE_CUMUL
      order by TOT.ACS_FINANCIAL_ACCOUNT_ID
             , TOT.ACS_DIVISION_ACCOUNT_ID
             , TOT.ACS_PERIOD_ID
             , TOT.ACS_FINANCIAL_CURRENCY_ID
             , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
             , TOT.C_TYPE_CUMUL;

    type TTblSumTotByPeriod is table of SumTotByPeriodCursor%rowtype;

    cursor SumFinImputationCursor(
      pACS_FINANCIAL_YEAR_ID ACS_PERIOD.ACS_FINANCIAL_YEAR_ID%type
    , pFYE_START_DATE        ACS_FINANCIAL_YEAR.FYE_START_DATE%type
    , pPER_END_DATE          ACS_PERIOD.PER_END_DATE%type
    , pC_SUB_SET             ACS_SUB_SET.C_SUB_SET%type
    , pPrevYearClosed        number
    )
    is
      select   sum(AMOUNT_LC) AMOUNT_LC
             , sum(AMOUNT_FC) AMOUNT_FC
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_FINANCIAL_CURRENCY_ID
             , ACS_ACS_FINANCIAL_CURRENCY_ID
             , ACS_PERIOD_ID
             , C_TYPE_CUMUL
             , 0 TREATY
          from (select nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0) AMOUNT_LC
                     , decode( (select CUR.ACS_FINANCIAL_CURRENCY_ID
                                  from ACS_FIN_ACCOUNT_S_FIN_CURR CUR
                                 where CUR.ACS_FINANCIAL_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
                                   and CUR.ACS_FINANCIAL_CURRENCY_ID = IMP.ACS_FINANCIAL_CURRENCY_ID)
                            , IMP.ACS_FINANCIAL_CURRENCY_ID, nvl(IMP.IMF_AMOUNT_FC_D, 0) - nvl(IMP.IMF_AMOUNT_FC_C, 0)
                            , decode( (select FCOL.ACS_FINANCIAL_ACCOUNT_ID
                                         from ACS_FINANCIAL_ACCOUNT FCOL
                                        where FCOL.ACS_FINANCIAL_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
                                          and FCOL.FIN_COLLECTIVE = 1)
                                   , IMP.ACS_FINANCIAL_ACCOUNT_ID, nvl(IMP.IMF_AMOUNT_FC_D, 0)
                                      - nvl(IMP.IMF_AMOUNT_FC_C, 0)
                                   , 0
                                    )
                             ) AMOUNT_FC
                     , IMP.ACS_FINANCIAL_ACCOUNT_ID
                     , nvl(IMP.IMF_ACS_DIVISION_ACCOUNT_ID, 0) ACS_DIVISION_ACCOUNT_ID
                     , decode( (select CUR.ACS_FINANCIAL_CURRENCY_ID
                                  from ACS_FIN_ACCOUNT_S_FIN_CURR CUR
                                 where CUR.ACS_FINANCIAL_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
                                   and CUR.ACS_FINANCIAL_CURRENCY_ID = IMP.ACS_FINANCIAL_CURRENCY_ID)
                            , IMP.ACS_FINANCIAL_CURRENCY_ID, IMP.ACS_FINANCIAL_CURRENCY_ID
                            , decode( (select FCOL.ACS_FINANCIAL_ACCOUNT_ID
                                         from ACS_FINANCIAL_ACCOUNT FCOL
                                        where FCOL.ACS_FINANCIAL_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
                                          and FCOL.FIN_COLLECTIVE = 1)
                                   , IMP.ACS_FINANCIAL_ACCOUNT_ID, IMP.ACS_FINANCIAL_CURRENCY_ID
                                   , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
                                    )
                             ) ACS_FINANCIAL_CURRENCY_ID
                     , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , IMP.ACS_PERIOD_ID
                     , SCA.C_TYPE_CUMUL
                  from ACJ_SUB_SET_CAT SCA
                     , ACT_ETAT_JOURNAL ETA
                     , ACJ_CATALOGUE_DOCUMENT CAT
                     , ACT_DOCUMENT DOC
                     , ACS_FINANCIAL_ACCOUNT FIN
                     , ACS_ACCOUNT ACC
                     , ACT_FINANCIAL_IMPUTATION IMP
                     , ACS_PERIOD PER
                     , ACS_SUB_SET SUB
                 where PER.ACS_FINANCIAL_YEAR_ID = pACS_FINANCIAL_YEAR_ID
                   and PER.ACS_PERIOD_ID = IMP.ACS_PERIOD_ID
                   and IMP.IMF_TRANSACTION_DATE between pFYE_START_DATE and pPER_END_DATE
                   and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                   and FIN.C_BALANCE_SHEET_PROFIT_LOSS = 'B'
                   and FIN.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                   and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
                   and SUB.SSE_TOTAL = 1
                   and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                   and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
                   and DOC.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
                   and ETA.C_SUB_SET = pC_SUB_SET
                   and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
                   and SCA.C_SUB_SET = pC_SUB_SET
                   and ETA.C_ETAT_JOURNAL <> 'BRO'
                   and (   pPrevYearClosed = 1
                        or (    pPrevYearClosed = 0
                            and CAT.C_TYPE_PERIOD <> '1') ) )
      group by ACS_FINANCIAL_ACCOUNT_ID
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_PERIOD_ID
             , ACS_ACS_FINANCIAL_CURRENCY_ID
             , ACS_FINANCIAL_CURRENCY_ID
             , C_TYPE_CUMUL
      order by ACS_FINANCIAL_ACCOUNT_ID
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_PERIOD_ID
             , ACS_ACS_FINANCIAL_CURRENCY_ID
             , ACS_FINANCIAL_CURRENCY_ID
             , C_TYPE_CUMUL;

    type TTblSumFinImputation is table of SumFinImputationCursor%rowtype;

    vTblSumTotByPeriod   TTblSumTotByPeriod                               := TTblSumTotByPeriod();
    vTblSumFinImputation TTblSumFinImputation                             := TTblSumFinImputation();
    vYearId              ACS_PERIOD.ACS_FINANCIAL_YEAR_ID%type;
    vYearStatus          ACS_FINANCIAL_YEAR.C_STATE_FINANCIAL_YEAR%type;
    vAllPeriod           number(1);   --selon l'exercice précédent, il faut prendre toutes les périodes ou pas
    vExistDivi           number(1);   --dans ACT_TOTAL_BY_PERIOD, une ligne est générée avec le total de toutes les divisions si elles sont gérées

    procedure LinkTotalImp(
      pTotalTable          in out TTblSumTotByPeriod
    , pImputationTable     in out TTblSumFinImputation
    , pACR_CTRL_SUB_SET_ID in     ACR_CTRL_SUB_SET.ACR_CTRL_SUB_SET_ID%type
    , pC_CTRL_CODE         in     ACR_CTRL_DETAIL.C_CTRL_CODE%type
    )
    is
      vTotalIndex      number;
      vImputationIndex number;
    begin
      vImputationIndex  := pImputationTable.first;

      while(vImputationIndex is not null) loop
        vTotalIndex       := pTotalTable.first;

        while(vTotalIndex is not null) loop
          if     (pTotalTable(vTotalIndex).Treaty = 0)
             and (pImputationTable(vImputationIndex).Treaty = 0)
             and (pTotalTable(vTotalIndex).ACS_FINANCIAL_ACCOUNT_ID =
                                                             pImputationTable(vImputationIndex).ACS_FINANCIAL_ACCOUNT_ID
                 )
             and (pTotalTable(vTotalIndex).ACS_DIVISION_ACCOUNT_ID =
                                                              pImputationTable(vImputationIndex).ACS_DIVISION_ACCOUNT_ID
                 )
             and (pTotalTable(vTotalIndex).ACS_PERIOD_ID = pImputationTable(vImputationIndex).ACS_PERIOD_ID)
             and (pTotalTable(vTotalIndex).C_TYPE_CUMUL = pImputationTable(vImputationIndex).C_TYPE_CUMUL)
             and (pTotalTable(vTotalIndex).ACS_FINANCIAL_CURRENCY_ID =
                                                        pImputationTable(vImputationIndex).ACS_ACS_FINANCIAL_CURRENCY_ID
                 )
             and (pTotalTable(vTotalIndex).ACS_ACS_FINANCIAL_CURRENCY_ID =
                                                            pImputationTable(vImputationIndex).ACS_FINANCIAL_CURRENCY_ID
                 ) then
            if     (pTotalTable(vTotalIndex).AMOUNT_LC = pImputationTable(vImputationIndex).AMOUNT_LC)
               and (pTotalTable(vTotalIndex).AMOUNT_FC = pImputationTable(vImputationIndex).AMOUNT_FC) then
              pTotalTable.delete(vTotalIndex);
              pImputationTable.delete(vImputationIndex);
              exit;
            else   --profiter de la paire pour stocker l'erreur
              InsertCtrlDetail(aACR_CTRL_SUB_SET_ID             => pACR_CTRL_SUB_SET_ID
                             , aC_CTRL_CODE                     => pC_CTRL_CODE
                             , aACS_AUXILIARY_ACCOUNT_ID        => null
                             , aCDE_AMOUNT1                     => pTotalTable(vTotalIndex).AMOUNT_LC
                             , aCDE_AMOUNT2                     => pImputationTable(vImputationIndex).AMOUNT_LC
                             , aCDE_AMOUNT1_FC                  => pTotalTable(vTotalIndex).AMOUNT_FC
                             , aCDE_AMOUNT2_FC                  => pImputationTable(vImputationIndex).AMOUNT_FC
                             , aACT_DOCUMENT_ID                 => null
                             , aACT_PART_IMPUTATION_ID          => null
                             , aC_TYPE_CUMUL                    => pTotalTable(vTotalIndex).C_TYPE_CUMUL
                             , aACS_FINANCIAL_CURRENCY_ID       => pTotalTable(vTotalIndex).ACS_ACS_FINANCIAL_CURRENCY_ID
                             , aACS_DIVISION_ACCOUNT_ID         => pTotalTable(vTotalIndex).ACS_DIVISION_ACCOUNT_ID
                             , aACS_FINANCIAL_ACCOUNT_ID        => pTotalTable(vTotalIndex).ACS_FINANCIAL_ACCOUNT_ID
                             , aACS_CPN_ACCOUNT_ID              => null
                             , aACS_CDA_ACCOUNT_ID              => null
                             , aACS_PF_ACCOUNT_ID               => null
                             , aACS_PJ_ACCOUNT_ID               => null
                             , aACS_QTY_UNIT_ID                 => null
                             , aACS_PERIOD_ID                   => pTotalTable(vTotalIndex).ACS_PERIOD_ID
                             , aACS_ACS_FINANCIAL_CURRENCY_ID   => pTotalTable(vTotalIndex).ACS_FINANCIAL_CURRENCY_ID
                             , aACS_TAX_CODE_ID                 => null
                              );
              pTotalTable(vTotalIndex).TREATY            := 1;
              pImputationTable(vImputationIndex).TREATY  := 1;
              exit;
            end if;
          end if;

          vTotalIndex  := pTotalTable.next(vTotalIndex);
        end loop;

        vImputationIndex  := pImputationTable.next(vImputationIndex);
      end loop;
    end LinkTotalImp;

    procedure CheckTotalOrphan(
      pTotalTable          in out TTblSumTotByPeriod
    , pACR_CTRL_SUB_SET_ID in     ACR_CTRL_SUB_SET.ACR_CTRL_SUB_SET_ID%type
    , pC_CTRL_CODE         in     ACR_CTRL_DETAIL.C_CTRL_CODE%type
    )
    is
      vTotalIndex number;
    begin
      --recherche des cumuls orphelins dont les montants <> 0 (Lors de la suppression d'une écriture, les cumuls sont mis à 0)
      vTotalIndex       := pTotalTable.first;

      while vTotalIndex is not null loop
        if     (pTotalTable(vTotalIndex).TREATY = 0)
           and (   pTotalTable(vTotalIndex).AMOUNT_LC <> 0
                or pTotalTable(vTotalIndex).AMOUNT_FC <> 0) then
          InsertCtrlDetail(aACR_CTRL_SUB_SET_ID             => pACR_CTRL_SUB_SET_ID
                         , aC_CTRL_CODE                     => pC_CTRL_CODE
                         , aACS_AUXILIARY_ACCOUNT_ID        => null
                         , aCDE_AMOUNT1                     => pTotalTable(vTotalIndex).AMOUNT_LC
                         , aCDE_AMOUNT2                     => 0
                         , aCDE_AMOUNT1_FC                  => pTotalTable(vTotalIndex).AMOUNT_FC
                         , aCDE_AMOUNT2_FC                  => 0
                         , aACT_DOCUMENT_ID                 => null
                         , aACT_PART_IMPUTATION_ID          => null
                         , aC_TYPE_CUMUL                    => pTotalTable(vTotalIndex).C_TYPE_CUMUL
                         , aACS_FINANCIAL_CURRENCY_ID       => pTotalTable(vTotalIndex).ACS_ACS_FINANCIAL_CURRENCY_ID
                         , aACS_DIVISION_ACCOUNT_ID         => pTotalTable(vTotalIndex).ACS_DIVISION_ACCOUNT_ID
                         , aACS_FINANCIAL_ACCOUNT_ID        => pTotalTable(vTotalIndex).ACS_FINANCIAL_ACCOUNT_ID
                         , aACS_CPN_ACCOUNT_ID              => null
                         , aACS_CDA_ACCOUNT_ID              => null
                         , aACS_PF_ACCOUNT_ID               => null
                         , aACS_PJ_ACCOUNT_ID               => null
                         , aACS_QTY_UNIT_ID                 => null
                         , aACS_PERIOD_ID                   => pTotalTable(vTotalIndex).ACS_PERIOD_ID
                         , aACS_ACS_FINANCIAL_CURRENCY_ID   => pTotalTable(vTotalIndex).ACS_FINANCIAL_CURRENCY_ID
                         , aACS_TAX_CODE_ID                 => null
                          );
        end if;

        vTotalIndex  := pTotalTable.next(vTotalIndex);
      end loop;
    end CheckTotalOrphan;

    procedure CheckImpOrphan(
      pImputationTable     in out TTblSumFinImputation
    , pACR_CTRL_SUB_SET_ID in     ACR_CTRL_SUB_SET.ACR_CTRL_SUB_SET_ID%type
    , pC_CTRL_CODE         in     ACR_CTRL_DETAIL.C_CTRL_CODE%type
    )
    is
      vImputationIndex number;
    begin
      --recherche des imputations orphelines
      vImputationIndex  := pImputationTable.first;

      while vImputationIndex is not null loop
        if     pImputationTable(vImputationIndex).TREATY = 0
           and (   pImputationTable(vImputationIndex).AMOUNT_LC <> 0
                or pImputationTable(vImputationIndex).AMOUNT_FC <> 0) then
          InsertCtrlDetail
                   (aACR_CTRL_SUB_SET_ID             => pACR_CTRL_SUB_SET_ID
                  , aC_CTRL_CODE                     => pC_CTRL_CODE
                  , aACS_AUXILIARY_ACCOUNT_ID        => null
                  , aCDE_AMOUNT1                     => 0
                  , aCDE_AMOUNT2                     => pImputationTable(vImputationIndex).AMOUNT_LC
                  , aCDE_AMOUNT1_FC                  => 0
                  , aCDE_AMOUNT2_FC                  => pImputationTable(vImputationIndex).AMOUNT_FC
                  , aACT_DOCUMENT_ID                 => null
                  , aACT_PART_IMPUTATION_ID          => null
                  , aC_TYPE_CUMUL                    => pImputationTable(vImputationIndex).C_TYPE_CUMUL
                  , aACS_FINANCIAL_CURRENCY_ID       => pImputationTable(vImputationIndex).ACS_FINANCIAL_CURRENCY_ID
                  , aACS_DIVISION_ACCOUNT_ID         => pImputationTable(vImputationIndex).ACS_DIVISION_ACCOUNT_ID
                  , aACS_FINANCIAL_ACCOUNT_ID        => pImputationTable(vImputationIndex).ACS_FINANCIAL_ACCOUNT_ID
                  , aACS_CPN_ACCOUNT_ID              => null
                  , aACS_CDA_ACCOUNT_ID              => null
                  , aACS_PF_ACCOUNT_ID               => null
                  , aACS_PJ_ACCOUNT_ID               => null
                  , aACS_QTY_UNIT_ID                 => null
                  , aACS_PERIOD_ID                   => pImputationTable(vImputationIndex).ACS_PERIOD_ID
                  , aACS_ACS_FINANCIAL_CURRENCY_ID   => pImputationTable(vImputationIndex).ACS_ACS_FINANCIAL_CURRENCY_ID
                  , aACS_TAX_CODE_ID                 => null
                   );
        end if;

        vImputationIndex  := pImputationTable.next(vImputationIndex);
      end loop;
    end CheckImpOrphan;

  begin
    --Principe: 2 cursors contenant certains champs des tables correspondantes
        --l'un la table ACT_TOTAL_BY_PERIOD, SumTotByPeriodCursor
        --l'autre ACT_FINANCIAL_IMPUTATION, SumFinImputationCursor
    --sont insérés dans des tables mémoire
        --TblSumTotByPeriod
        --TblSumFinImputation.
    --Un champ dans chacune des tables permet de repérer des erreurs TREATY
    --Un traitement spécifique est appliqué à TblSumFinImputation pour les monnaies étrangères non gérées dans les cumuls
    --TblSumTotByPeriod est considérée comme référence et contrôlera que pour chacun de ses tuples
    --existe un équivalent dans TblSumFinImputation.
    --Chaque ligne contrôlée OK est effacée des deux tables
    --A la fin du contrôle, chaque table contiendra peut-être des enregistrements dont le champ TREATY sera
      -- = 0: l'équivalent dans l'autre table n'a pas été trouvé (les cumuls entièrement à 0 sont ignorés)
      -- = 1: une erreur de montant débit ou crédit ou LC ou FC a été trouvée entre les deux tables
    vYearId      := ACS_FUNCTION.GetFinancialYearId(pPER_END_DATE);
    vYearStatus  := ACS_FUNCTION.GetStatePreviousFinancialYear(vYearId);

    select decode(nvl(max(ACS_SUB_SET_ID), 0), 0, 0, 1)
      into vExistDivi
      from ACS_SUB_SET
     where C_TYPE_SUB_SET = 'DIVI';

    if    vYearStatus is null
       or vYearStatus = 'CLO' then
      vAllPeriod  := 1;
    else
      vAllPeriod  := 0;
    end if;

    vTblSumTotByPeriod.delete;
    vTblSumFinImputation.delete;

    open SumTotByPeriodCursor(vYearId, pFYE_START_DATE, pPER_END_DATE, vAllPeriod, vExistDivi);

    fetch SumTotByPeriodCursor
    bulk collect into vTblSumTotByPeriod;

    close SumTotByPeriodCursor;

    open SumFinImputationCursor(vYearId, pFYE_START_DATE, pPER_END_DATE, 'ACC', vAllPeriod);

    fetch SumFinImputationCursor
    bulk collect into vTblSumFinImputation;

    close SumFinImputationCursor;

    --1. effacer toutes les paires trouvées et complètes
    --2. Détecter les erreurs de montants
    LinkTotalImp(vTblSumTotByPeriod, vTblSumFinImputation, aACR_CTRL_SUB_SET_ID, '043');
    --3. Resteront les cumuls orphelins
    CheckTotalOrphan(vTblSumTotByPeriod, aACR_CTRL_SUB_SET_ID, '044');
    -- et les imputations orphelines
    CheckImpOrphan(vTblSumFinImputation, aACR_CTRL_SUB_SET_ID, '045');
  end FinAccountCtrl;

  /**
  * procedure CpnAccountCtrl
  * Description
  *  Contrôle des comptes analytiques CPN, cohérence entre cumuls et imputations
  */
  procedure CpnAccountCtrl(
    aACR_CTRL_SUB_SET_ID    ACR_CTRL_SUB_SET.ACR_CTRL_SUB_SET_ID%type
  , pFYE_START_DATE      in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
  , pPER_END_DATE        in ACS_PERIOD.PER_END_DATE%type
  )
  is
    cursor SumMgmTotByPeriodCursor(
      pACS_FINANCIAL_YEAR_ID in ACS_PERIOD.ACS_FINANCIAL_YEAR_ID%type
    , pFYE_START_DATE        in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
    , pPER_END_DATE          in ACS_PERIOD.PER_END_DATE%type
    , pAllPeriod             in number
    )
    is
      select   nvl(sum(TOT.MTO_DEBIT_LC - TOT.MTO_CREDIT_LC), 0) AMOUNT_LC
             , nvl(sum(TOT.MTO_DEBIT_FC - TOT.MTO_CREDIT_FC), 0) AMOUNT_FC
             , nvl(sum(TOT.MTO_QUANTITY_D - TOT.MTO_QUANTITY_C), 0) AMOUNT_QTY
             , TOT.ACS_CPN_ACCOUNT_ID
             , nvl(TOT.ACS_CDA_ACCOUNT_ID, 0) ACS_CDA_ACCOUNT_ID
             , nvl(TOT.ACS_PF_ACCOUNT_ID, 0) ACS_PF_ACCOUNT_ID
             , nvl(TOT.ACS_PJ_ACCOUNT_ID, 0) ACS_PJ_ACCOUNT_ID
             , nvl(TOT.DOC_RECORD_ID, 0) DOC_RECORD_ID
             , nvl(TOT.ACS_QTY_UNIT_ID, 0) ACS_QTY_UNIT_ID
             , TOT.ACS_FINANCIAL_CURRENCY_ID
             , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
             , TOT.ACS_PERIOD_ID
             , TOT.C_TYPE_CUMUL
             , 0 TREATY
          from ACT_MGM_TOT_BY_PERIOD TOT
             , ACS_PERIOD PER
         where TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
           and PER.ACS_FINANCIAL_YEAR_ID = pACS_FINANCIAL_YEAR_ID
           and PER.PER_START_DATE >= pFYE_START_DATE
           and PER.PER_END_DATE <= pPER_END_DATE
           --La tenue des cumuls par dossier est effective...
           --de ce fait les positions de cumul avec uniquement le dossier mais sans CDA / PF / PJ
           --sont générées / reportées .
           --Par contre en bouclement ces positions ne sont pas matérialisées par une imputation de report
           --aussi diff. entre cumul et imputation si contrôle drectement après bouclement
           --sans recalcul.
           and (    (pAllPeriod = 1)
                     and not(    (nvl(TOT.ACS_CDA_ACCOUNT_ID,0) = 0)
                             and (nvl(TOT.ACS_PF_ACCOUNT_ID,0) = 0)
                             and (nvl(TOT.ACS_PJ_ACCOUNT_ID,0) = 0)
                             and (nvl(TOT.DOC_RECORD_ID,0) <> 0)
                            )
                or (    pAllPeriod = 0
                    and PER.C_TYPE_PERIOD <> '1') )
      group by TOT.ACS_CPN_ACCOUNT_ID
             , TOT.ACS_CDA_ACCOUNT_ID
             , TOT.ACS_PF_ACCOUNT_ID
             , TOT.ACS_PJ_ACCOUNT_ID
             , TOT.DOC_RECORD_ID
             , TOT.ACS_QTY_UNIT_ID
             , TOT.ACS_PERIOD_ID
             , TOT.ACS_FINANCIAL_CURRENCY_ID
             , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
             , TOT.C_TYPE_CUMUL
      order by TOT.ACS_CPN_ACCOUNT_ID
             , TOT.ACS_CDA_ACCOUNT_ID
             , TOT.ACS_PF_ACCOUNT_ID
             , TOT.ACS_PJ_ACCOUNT_ID
             , TOT.ACS_QTY_UNIT_ID
             , TOT.ACS_PERIOD_ID
             , TOT.ACS_FINANCIAL_CURRENCY_ID
             , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
             , TOT.C_TYPE_CUMUL;

    cursor SumCpnImputationCursor(
      pACS_FINANCIAL_YEAR_ID    ACS_PERIOD.ACS_FINANCIAL_YEAR_ID%type
    , pFYE_START_DATE        in ACS_FINANCIAL_YEAR.FYE_START_DATE%type
    , pPER_END_DATE          in ACS_PERIOD.PER_END_DATE%type
    )
    is
      select   ACS_PERIOD_ID
             , C_TYPE_CUMUL
             , ACS_ACS_FINANCIAL_CURRENCY_ID
             , ACS_FINANCIAL_CURRENCY_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , DOC_RECORD_ID
             , ACS_QTY_UNIT_ID
             , sum(DIF_AMOUNT_LC) DIF_AMOUNT_LC
             , sum(DIF_AMOUNT_FC) DIF_AMOUNT_FC
             , sum(DIF_AMOUNT_QTY) DIF_AMOUNT_QTY
             , sum(AMOUNT_LC) AMOUNT_LC
             , sum(AMOUNT_FC) AMOUNT_FC
             , sum(AMOUNT_QTY) AMOUNT_QTY
             , sum(MGM_AMOUNT_LC) MGM_AMOUNT_LC
             , sum(MGM_AMOUNT_FC) MGM_AMOUNT_FC
             , sum(MGM_AMOUNT_QTY) MGM_AMOUNT_QTY
             , 0 TREATY
          from (select IMP.ACS_PERIOD_ID
                     , SCA.C_TYPE_CUMUL
                     , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , nvl( (select CUR.ACS_FINANCIAL_CURRENCY_ID
                               from ACS_CPN_ACCOUNT_CURRENCY CUR
                              where CUR.ACS_CPN_ACCOUNT_ID = IMP.ACS_CPN_ACCOUNT_ID
                                and CUR.ACS_FINANCIAL_CURRENCY_ID = IMP.ACS_FINANCIAL_CURRENCY_ID)
                         , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
                          ) ACS_FINANCIAL_CURRENCY_ID
                     , IMP.ACS_CPN_ACCOUNT_ID
                     , nvl(IMP.ACS_CDA_ACCOUNT_ID, 0) ACS_CDA_ACCOUNT_ID
                     , nvl(IMP.ACS_PF_ACCOUNT_ID, 0) ACS_PF_ACCOUNT_ID
                     , nvl(PJ.ACS_PJ_ACCOUNT_ID, 0) ACS_PJ_ACCOUNT_ID
                     , nvl(IMP.DOC_RECORD_ID, 0) DOC_RECORD_ID
                     , nvl(IMP.ACS_QTY_UNIT_ID, 0) ACS_QTY_UNIT_ID
                     , (nvl(IMP.IMM_AMOUNT_LC_D, 0) -
                        nvl(MGM.MGM_AMOUNT_LC_D, 0) -
                        nvl(IMP.IMM_AMOUNT_LC_C, 0) -
                        nvl(MGM.MGM_AMOUNT_LC_C, 0)
                       ) DIF_AMOUNT_LC
                     , decode( (select CUR.ACS_FINANCIAL_CURRENCY_ID
                                  from ACS_CPN_ACCOUNT_CURRENCY CUR
                                 where CUR.ACS_CPN_ACCOUNT_ID = IMP.ACS_CPN_ACCOUNT_ID
                                   and CUR.ACS_FINANCIAL_CURRENCY_ID = IMP.ACS_FINANCIAL_CURRENCY_ID)
                            , IMP.ACS_FINANCIAL_CURRENCY_ID,(nvl(IMP.IMM_AMOUNT_FC_D, 0) -
                                                             nvl(MGM.MGM_AMOUNT_FC_D, 0) -
                                                             nvl(IMP.IMM_AMOUNT_FC_C, 0) -
                                                             nvl(MGM.MGM_AMOUNT_FC_C, 0)
                              )
                            , 0
                             ) DIF_AMOUNT_FC
                     , (nvl(IMP.IMM_QUANTITY_D, 0) -
                        nvl(MGM.MGM_QUANTITY_D, 0) -
                        nvl(IMP.IMM_QUANTITY_C, 0) -
                        nvl(MGM.MGM_QUANTITY_C, 0)
                       ) DIF_AMOUNT_QTY
                     , (nvl(IMP.IMM_AMOUNT_LC_D, 0) - nvl(IMP.IMM_AMOUNT_LC_C, 0) ) AMOUNT_LC
                     , decode( (select CUR.ACS_FINANCIAL_CURRENCY_ID
                                  from ACS_CPN_ACCOUNT_CURRENCY CUR
                                 where CUR.ACS_CPN_ACCOUNT_ID = IMP.ACS_CPN_ACCOUNT_ID
                                   and CUR.ACS_FINANCIAL_CURRENCY_ID = IMP.ACS_FINANCIAL_CURRENCY_ID)
                            , IMP.ACS_FINANCIAL_CURRENCY_ID,(nvl(IMP.IMM_AMOUNT_FC_D, 0) - nvl(IMP.IMM_AMOUNT_FC_C, 0) )
                            , 0
                             ) AMOUNT_FC
                     , (nvl(IMP.IMM_QUANTITY_D, 0) - nvl(IMP.IMM_QUANTITY_C, 0) ) AMOUNT_QTY
                     , (nvl(PJ.MGM_AMOUNT_LC_D, 0) - nvl(PJ.MGM_AMOUNT_LC_C, 0) ) MGM_AMOUNT_LC
                     , decode( (select CUR.ACS_FINANCIAL_CURRENCY_ID
                                  from ACS_CPN_ACCOUNT_CURRENCY CUR
                                 where CUR.ACS_CPN_ACCOUNT_ID = IMP.ACS_CPN_ACCOUNT_ID
                                   and CUR.ACS_FINANCIAL_CURRENCY_ID = IMP.ACS_FINANCIAL_CURRENCY_ID)
                            , IMP.ACS_FINANCIAL_CURRENCY_ID,(nvl(PJ.MGM_AMOUNT_FC_D, 0) - nvl(PJ.MGM_AMOUNT_FC_C, 0) )
                            , 0
                             ) MGM_AMOUNT_FC
                     , (nvl(PJ.MGM_QUANTITY_D, 0) - nvl(PJ.MGM_QUANTITY_C, 0) ) MGM_AMOUNT_QTY
                  from ACJ_SUB_SET_CAT SCA
                     , ACT_ETAT_JOURNAL ETA
                     , ACJ_CATALOGUE_DOCUMENT CAT
                     , ACT_DOCUMENT DOC
                     , ACS_ACCOUNT ACC
                     , ACT_MGM_IMPUTATION IMP
                     , ACS_PERIOD PER
                     , ACS_SUB_SET SUB
                     , (select   MGD.ACT_MGM_IMPUTATION_ID
                               , MGD.ACS_PJ_ACCOUNT_ID
                               , sum(nvl(MGD.MGM_AMOUNT_LC_D, 0) ) MGM_AMOUNT_LC_D
                               , sum(nvl(MGD.MGM_AMOUNT_FC_D, 0) ) MGM_AMOUNT_FC_D
                               , sum(nvl(MGD.MGM_AMOUNT_EUR_D, 0) ) MGM_AMOUNT_EUR_D
                               , sum(nvl(MGD.MGM_AMOUNT_LC_C, 0) ) MGM_AMOUNT_LC_C
                               , sum(nvl(MGD.MGM_AMOUNT_FC_C, 0) ) MGM_AMOUNT_FC_C
                               , sum(nvl(MGD.MGM_AMOUNT_EUR_C, 0) ) MGM_AMOUNT_EUR_C
                               , sum(nvl(MGD.MGM_QUANTITY_D, 0) ) MGM_QUANTITY_D
                               , sum(nvl(MGD.MGM_QUANTITY_C, 0) ) MGM_QUANTITY_C
                            from ACT_MGM_DISTRIBUTION MGD
                        group by MGD.ACT_MGM_IMPUTATION_ID
                               , MGD.ACS_PJ_ACCOUNT_ID) PJ
                     , (select   MGD.ACT_MGM_IMPUTATION_ID
                               , sum(nvl(MGD.MGM_AMOUNT_LC_D, 0) ) MGM_AMOUNT_LC_D
                               , sum(nvl(MGD.MGM_AMOUNT_FC_D, 0) ) MGM_AMOUNT_FC_D
                               , sum(nvl(MGD.MGM_AMOUNT_EUR_D, 0) ) MGM_AMOUNT_EUR_D
                               , sum(nvl(MGD.MGM_AMOUNT_LC_C, 0) ) MGM_AMOUNT_LC_C
                               , sum(nvl(MGD.MGM_AMOUNT_FC_C, 0) ) MGM_AMOUNT_FC_C
                               , sum(nvl(MGD.MGM_AMOUNT_EUR_C, 0) ) MGM_AMOUNT_EUR_C
                               , sum(nvl(MGD.MGM_QUANTITY_D, 0) ) MGM_QUANTITY_D
                               , sum(nvl(MGD.MGM_QUANTITY_C, 0) ) MGM_QUANTITY_C
                            from ACT_MGM_DISTRIBUTION MGD
                        group by MGD.ACT_MGM_IMPUTATION_ID) MGM
                 where PER.ACS_FINANCIAL_YEAR_ID = pACS_FINANCIAL_YEAR_ID
                   and PER.ACS_PERIOD_ID = IMP.ACS_PERIOD_ID
                   and IMP.IMM_TRANSACTION_DATE between pFYE_START_DATE and pPER_END_DATE
                   and IMP.ACS_CPN_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                   and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
                   and SUB.SSE_TOTAL = 1
                   and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                   and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
                   and DOC.ACT_ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
                   and ETA.C_SUB_SET = 'CPN'
                   and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
                   and SCA.C_SUB_SET = 'CPN'
                   and ETA.C_ETAT_JOURNAL <> 'BRO'
                   and IMP.ACT_MGM_IMPUTATION_ID = PJ.ACT_MGM_IMPUTATION_ID(+)
                   and IMP.ACT_MGM_IMPUTATION_ID = MGM.ACT_MGM_IMPUTATION_ID(+))
      group by ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , DOC_RECORD_ID
             , ACS_QTY_UNIT_ID
             , ACS_PERIOD_ID
             , ACS_ACS_FINANCIAL_CURRENCY_ID
             , ACS_FINANCIAL_CURRENCY_ID
             , C_TYPE_CUMUL
      order by ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , ACS_QTY_UNIT_ID
             , ACS_PERIOD_ID
             , ACS_ACS_FINANCIAL_CURRENCY_ID
             , ACS_FINANCIAL_CURRENCY_ID
             , C_TYPE_CUMUL;

    type TTblSumMgmTotByPeriod is table of SumMgmTotByPeriodCursor%rowtype;

    type TTblSumCpnImputation is table of SumCpnImputationCursor%rowtype;

    vYearId               ACS_PERIOD.ACS_FINANCIAL_YEAR_ID%type;   --Exercice de la date de contôle
    vYearStatus           ACS_FINANCIAL_YEAR.C_STATE_FINANCIAL_YEAR%type;   --Statut de l'exercice précédent
    vAllPeriod            number(1);   --Prise en compte de la période de report(1) ou non (0)
    vTblSumMgmTotByPeriod TTblSumMgmTotByPeriod                            := TTblSumMgmTotByPeriod();   --Structure de réception des enregistrements du curseur
    vTblSumCpnImputation  TTblSumCpnImputation                             := TTblSumCpnImputation();   --Structure de réception des enregistrements du curseur

    procedure CheckCpnAccount(
      pTotalTable      in out TTblSumMgmTotByPeriod
    , pImputationTable in out TTblSumCpnImputation
    , pCtrlSubSetId           ACR_CTRL_SUB_SET.ACR_CTRL_SUB_SET_ID%type
    )
    is
      vTotalIndex      number;
      vImputationIndex number;
      vImpAmountLC     ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_D%type;
      vImpAmountFC     ACT_MGM_IMPUTATION.IMM_AMOUNT_LC_D%type;
    begin
      /**
      * 1° Parcours séquentiel des cumuls et des imputations
      * Si position correspondent        ==> mise à -1 du flag
      * Si position ne correspondent pas ==> mise à -2 du flag
      **/
      vImputationIndex  := pImputationTable.first;

      while(vImputationIndex is not null) loop
        vTotalIndex       := pTotalTable.first;

        while(vTotalIndex is not null) loop
          if     (pTotalTable(vTotalIndex).Treaty = 0)
             and (pImputationTable(vImputationIndex).Treaty = 0)
             and (pTotalTable(vTotalIndex).ACS_CPN_ACCOUNT_ID = pImputationTable(vImputationIndex).ACS_CPN_ACCOUNT_ID)
             and (pTotalTable(vTotalIndex).ACS_CDA_ACCOUNT_ID = pImputationTable(vImputationIndex).ACS_CDA_ACCOUNT_ID)
             and (pTotalTable(vTotalIndex).ACS_PF_ACCOUNT_ID = pImputationTable(vImputationIndex).ACS_PF_ACCOUNT_ID)
             and (pTotalTable(vTotalIndex).ACS_PJ_ACCOUNT_ID = pImputationTable(vImputationIndex).ACS_PJ_ACCOUNT_ID)
             and (pTotalTable(vTotalIndex).DOC_RECORD_ID = pImputationTable(vImputationIndex).DOC_RECORD_ID)
             and (pTotalTable(vTotalIndex).ACS_QTY_UNIT_ID = pImputationTable(vImputationIndex).ACS_QTY_UNIT_ID)
             and (pTotalTable(vTotalIndex).ACS_PERIOD_ID = pImputationTable(vImputationIndex).ACS_PERIOD_ID)
             and (pTotalTable(vTotalIndex).C_TYPE_CUMUL = pImputationTable(vImputationIndex).C_TYPE_CUMUL)
             and (pTotalTable(vTotalIndex).ACS_FINANCIAL_CURRENCY_ID =
                                                            pImputationTable(vImputationIndex).ACS_FINANCIAL_CURRENCY_ID
                 )
             and (pTotalTable(vTotalIndex).ACS_ACS_FINANCIAL_CURRENCY_ID =
                                                        pImputationTable(vImputationIndex).ACS_ACS_FINANCIAL_CURRENCY_ID
                 ) then
            vImpAmountLC  := pImputationTable(vImputationIndex).AMOUNT_LC;
            vImpAmountFC  := pImputationTable(vImputationIndex).AMOUNT_FC;

            /** Imputations et cumuls sans axe PJ **/
            if     pImputationTable(vImputationIndex).ACS_PJ_ACCOUNT_ID = 0
               and pTotalTable(vTotalIndex).ACS_PJ_ACCOUNT_ID = 0
               and (pTotalTable(vTotalIndex).AMOUNT_LC = pImputationTable(vImputationIndex).AMOUNT_LC)
               and (pTotalTable(vTotalIndex).AMOUNT_FC = pImputationTable(vImputationIndex).AMOUNT_FC)
               and (pTotalTable(vTotalIndex).AMOUNT_QTY = pImputationTable(vImputationIndex).AMOUNT_QTY) then
              --Imputation + cumul trouvés => effacer les deux écritures de la table virtuelle
              pTotalTable.delete(vTotalIndex);
              pImputationTable.delete(vImputationIndex);
              exit;
            else
              if pTotalTable(vTotalIndex).ACS_PJ_ACCOUNT_ID = 0 then
                vImpAmountLC  := pImputationTable(vImputationIndex).DIF_AMOUNT_LC;
                vImpAmountFC  := pImputationTable(vImputationIndex).DIF_AMOUNT_FC;
              else
                vImpAmountLC  := pImputationTable(vImputationIndex).MGM_AMOUNT_LC;
                vImpAmountFC  := pImputationTable(vImputationIndex).MGM_AMOUNT_FC;
              end if;

              if     (pImputationTable(vImputationIndex).ACS_PJ_ACCOUNT_ID <> 0)
                 and (
                              /** Cumul sans PJ -> Position a réceptionnée différence **/
                             ( pTotalTable(vTotalIndex).ACS_PJ_ACCOUNT_ID = 0)
                         and (     (pTotalTable(vTotalIndex).ACS_PJ_ACCOUNT_ID = 0)
                              and (pTotalTable(vTotalIndex).AMOUNT_LC = pImputationTable(vImputationIndex).DIF_AMOUNT_LC
                                  )
                              and (pTotalTable(vTotalIndex).AMOUNT_FC = pImputationTable(vImputationIndex).DIF_AMOUNT_FC
                                  )
                              and (pTotalTable(vTotalIndex).AMOUNT_QTY =
                                                                       pImputationTable(vImputationIndex).DIF_AMOUNT_QTY
                                  )
                             )
                      or
                         /** Cumul avec PJ -> Position a réceptionnée montant distribution ou montant imputation */
                         (     (pTotalTable(vTotalIndex).ACS_PJ_ACCOUNT_ID <> 0)
                          and (     (pTotalTable(vTotalIndex).AMOUNT_LC =
                                                                        pImputationTable(vImputationIndex).MGM_AMOUNT_LC
                                    )
                               and (pTotalTable(vTotalIndex).AMOUNT_FC =
                                                                        pImputationTable(vImputationIndex).MGM_AMOUNT_FC
                                   )
                               and (pTotalTable(vTotalIndex).AMOUNT_QTY =
                                                                       pImputationTable(vImputationIndex).MGM_AMOUNT_QTY
                                   )
                              )
                         )
                     ) then
                pTotalTable.delete(vTotalIndex);
                pImputationTable.delete(vImputationIndex);
                exit;
              else   --profiter de la paire pour stocker l'erreur
                InsertCtrlDetail(aACR_CTRL_SUB_SET_ID             => pCtrlSubSetId
                               , aC_CTRL_CODE                     => '043'
                               , aACS_AUXILIARY_ACCOUNT_ID        => null
                               , aCDE_AMOUNT1                     => pTotalTable(vTotalIndex).AMOUNT_LC
                               , aCDE_AMOUNT2                     => vImpAmountLC
                               , aCDE_AMOUNT1_FC                  => pTotalTable(vTotalIndex).AMOUNT_FC
                               , aCDE_AMOUNT2_FC                  => vImpAmountFC
                               , aACT_DOCUMENT_ID                 => null
                               , aACT_PART_IMPUTATION_ID          => null
                               , aC_TYPE_CUMUL                    => pTotalTable(vTotalIndex).C_TYPE_CUMUL
                               , aACS_FINANCIAL_CURRENCY_ID       => pTotalTable(vTotalIndex).ACS_ACS_FINANCIAL_CURRENCY_ID
                               , aACS_DIVISION_ACCOUNT_ID         => null
                               , aACS_FINANCIAL_ACCOUNT_ID        => null
                               , aACS_CPN_ACCOUNT_ID              => pTotalTable(vTotalIndex).ACS_CPN_ACCOUNT_ID
                               , aACS_CDA_ACCOUNT_ID              => pTotalTable(vTotalIndex).ACS_CDA_ACCOUNT_ID
                               , aACS_PF_ACCOUNT_ID               => pTotalTable(vTotalIndex).ACS_PF_ACCOUNT_ID
                               , aACS_PJ_ACCOUNT_ID               => pTotalTable(vTotalIndex).ACS_PJ_ACCOUNT_ID
                               , aACS_QTY_UNIT_ID                 => pTotalTable(vTotalIndex).ACS_QTY_UNIT_ID
                               , aACS_PERIOD_ID                   => pTotalTable(vTotalIndex).ACS_PERIOD_ID
                               , aACS_ACS_FINANCIAL_CURRENCY_ID   => pTotalTable(vTotalIndex).ACS_FINANCIAL_CURRENCY_ID
                               , aACS_TAX_CODE_ID                 => null
                                );
                pTotalTable(vTotalIndex).TREATY            := 1;
                pImputationTable(vImputationIndex).TREATY  := 1;
                exit;
              end if;
            end if;
          end if;

          vTotalIndex  := pTotalTable.next(vTotalIndex);
        end loop;

        vImputationIndex  := pImputationTable.next(vImputationIndex);
      end loop;

      --recherche des cumuls orphelins
      vTotalIndex       := pTotalTable.first;

      while vTotalIndex is not null loop
        if     pTotalTable(vTotalIndex).TREATY = 0
           and (   pTotalTable(vTotalIndex).AMOUNT_LC <> 0
                or pTotalTable(vTotalIndex).AMOUNT_FC <> 0
                or pTotalTable(vTotalIndex).AMOUNT_QTY <> 0
               ) then
          InsertCtrlDetail(aACR_CTRL_SUB_SET_ID             => pCtrlSubSetId
                         , aC_CTRL_CODE                     => '044'
                         , aACS_AUXILIARY_ACCOUNT_ID        => null
                         , aCDE_AMOUNT1                     => pTotalTable(vTotalIndex).AMOUNT_LC
                         , aCDE_AMOUNT2                     => 0
                         , aCDE_AMOUNT1_FC                  => pTotalTable(vTotalIndex).AMOUNT_FC
                         , aCDE_AMOUNT2_FC                  => 0
                         , aACT_DOCUMENT_ID                 => null
                         , aACT_PART_IMPUTATION_ID          => null
                         , aC_TYPE_CUMUL                    => pTotalTable(vTotalIndex).C_TYPE_CUMUL
                         , aACS_FINANCIAL_CURRENCY_ID       => pTotalTable(vTotalIndex).ACS_ACS_FINANCIAL_CURRENCY_ID
                         , aACS_DIVISION_ACCOUNT_ID         => null
                         , aACS_FINANCIAL_ACCOUNT_ID        => null
                         , aACS_CPN_ACCOUNT_ID              => pTotalTable(vTotalIndex).ACS_CPN_ACCOUNT_ID
                         , aACS_CDA_ACCOUNT_ID              => pTotalTable(vTotalIndex).ACS_CDA_ACCOUNT_ID
                         , aACS_PF_ACCOUNT_ID               => pTotalTable(vTotalIndex).ACS_PF_ACCOUNT_ID
                         , aACS_PJ_ACCOUNT_ID               => pTotalTable(vTotalIndex).ACS_PJ_ACCOUNT_ID
                         , aACS_QTY_UNIT_ID                 => pTotalTable(vTotalIndex).ACS_QTY_UNIT_ID
                         , aACS_PERIOD_ID                   => pTotalTable(vTotalIndex).ACS_PERIOD_ID
                         , aACS_ACS_FINANCIAL_CURRENCY_ID   => pTotalTable(vTotalIndex).ACS_FINANCIAL_CURRENCY_ID
                         , aACS_TAX_CODE_ID                 => null
                          );
        end if;

        vTotalIndex  := pTotalTable.next(vTotalIndex);
      end loop;

      --recherche des imputations orphelines
      vImputationIndex  := pImputationTable.first;

      while vImputationIndex is not null loop
        if     pImputationTable(vImputationIndex).TREATY = 0
           and (   pImputationTable(vImputationIndex).AMOUNT_LC <> 0
                or pImputationTable(vImputationIndex).AMOUNT_FC <> 0
                or pImputationTable(vImputationIndex).AMOUNT_QTY <> 0
               ) then
          InsertCtrlDetail
                   (aACR_CTRL_SUB_SET_ID             => pCtrlSubSetId
                  , aC_CTRL_CODE                     => '045'
                  , aACS_AUXILIARY_ACCOUNT_ID        => null
                  , aCDE_AMOUNT1                     => 0
                  , aCDE_AMOUNT2                     => pImputationTable(vImputationIndex).AMOUNT_LC
                  , aCDE_AMOUNT1_FC                  => 0
                  , aCDE_AMOUNT2_FC                  => pImputationTable(vImputationIndex).AMOUNT_FC
                  , aACT_DOCUMENT_ID                 => null
                  , aACT_PART_IMPUTATION_ID          => null
                  , aC_TYPE_CUMUL                    => pImputationTable(vImputationIndex).C_TYPE_CUMUL
                  , aACS_FINANCIAL_CURRENCY_ID       => pImputationTable(vImputationIndex).ACS_FINANCIAL_CURRENCY_ID
                  , aACS_DIVISION_ACCOUNT_ID         => null
                  , aACS_FINANCIAL_ACCOUNT_ID        => null
                  , aACS_CPN_ACCOUNT_ID              => pImputationTable(vImputationIndex).ACS_CPN_ACCOUNT_ID
                  , aACS_CDA_ACCOUNT_ID              => pImputationTable(vImputationIndex).ACS_CDA_ACCOUNT_ID
                  , aACS_PF_ACCOUNT_ID               => pImputationTable(vImputationIndex).ACS_PF_ACCOUNT_ID
                  , aACS_PJ_ACCOUNT_ID               => pImputationTable(vImputationIndex).ACS_PJ_ACCOUNT_ID
                  , aACS_QTY_UNIT_ID                 => pImputationTable(vImputationIndex).ACS_QTY_UNIT_ID
                  , aACS_PERIOD_ID                   => pImputationTable(vImputationIndex).ACS_PERIOD_ID
                  , aACS_ACS_FINANCIAL_CURRENCY_ID   => pImputationTable(vImputationIndex).ACS_ACS_FINANCIAL_CURRENCY_ID
                  , aACS_TAX_CODE_ID                 => null
                   );
        end if;

        vImputationIndex  := pImputationTable.next(vImputationIndex);
      end loop;
    end CheckCpnAccount;
  begin
    vYearId      := ACS_FUNCTION.GetFinancialYearId(pPER_END_DATE);
    vYearStatus  := ACS_FUNCTION.GetStatePreviousFinancialYear(vYearId);

    if    vYearStatus is null
       or vYearStatus = 'CLO' then   --L'exercice précédent n'existe pas ou est bouclé
      vAllPeriod  := 1;   --Les ecritures de bouclement sont matérialisées dans la période de report
    else
      vAllPeriod  := 0;
    end if;

    /** Initialisation des structures temporaires de réception des données **/
    vTblSumMgmTotByPeriod.delete;
    vTblSumCpnImputation.delete;

    /** Réception des enregistrements des curseurs **/
    open SumMgmTotByPeriodCursor(vYearId, pFYE_START_DATE, pPER_END_DATE, vAllPeriod);

    fetch SumMgmTotByPeriodCursor
    bulk collect into vTblSumMgmTotByPeriod;

    close SumMgmTotByPeriodCursor;

    open SumCpnImputationCursor(vYearId, pFYE_START_DATE, pPER_END_DATE);

    fetch SumCpnImputationCursor
    bulk collect into vTblSumCpnImputation;

    close SumCpnImputationCursor;

    CheckCpnAccount(vTblSumMgmTotByPeriod, vTblSumCpnImputation, aACR_CTRL_SUB_SET_ID);
  end CpnAccountCtrl;

  /**
  * procedure InsertCtrlDetail
  * Description
  *  Ajout d'une ligne d'erreur
  */
  procedure InsertCtrlDetail(
    aACR_CTRL_SUB_SET_ID           in ACR_CTRL_DETAIL.ACR_CTRL_SUB_SET_ID%type
  , aC_CTRL_CODE                   in ACR_CTRL_DETAIL.C_CTRL_CODE%type
  , aACS_AUXILIARY_ACCOUNT_ID      in ACR_CTRL_DETAIL.ACS_AUXILIARY_ACCOUNT_ID%type
  , aCDE_AMOUNT1                   in ACR_CTRL_DETAIL.CDE_AMOUNT1%type
  , aCDE_AMOUNT2                   in ACR_CTRL_DETAIL.CDE_AMOUNT2%type
  , aCDE_AMOUNT1_FC                in ACR_CTRL_DETAIL.CDE_AMOUNT1_FC%type
  , aCDE_AMOUNT2_FC                in ACR_CTRL_DETAIL.CDE_AMOUNT2_FC%type
  , aACT_DOCUMENT_ID               in ACR_CTRL_DETAIL.ACT_DOCUMENT_ID%type
  , aACT_PART_IMPUTATION_ID        in ACR_CTRL_DETAIL.ACT_PART_IMPUTATION_ID%type
  , aC_TYPE_CUMUL                  in ACR_CTRL_DETAIL.C_TYPE_CUMUL%type
  , aACS_FINANCIAL_CURRENCY_ID     in ACR_CTRL_DETAIL.ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_DIVISION_ACCOUNT_ID       in ACR_CTRL_DETAIL.ACS_DIVISION_ACCOUNT_ID%type
  , aACS_FINANCIAL_ACCOUNT_ID      in ACR_CTRL_DETAIL.ACS_FINANCIAL_ACCOUNT_ID%type
  , aACS_CPN_ACCOUNT_ID            in ACR_CTRL_DETAIL.ACS_CPN_ACCOUNT_ID%type
  , aACS_CDA_ACCOUNT_ID            in ACR_CTRL_DETAIL.ACS_CDA_ACCOUNT_ID%type
  , aACS_PF_ACCOUNT_ID             in ACR_CTRL_DETAIL.ACS_PF_ACCOUNT_ID%type
  , aACS_PJ_ACCOUNT_ID             in ACR_CTRL_DETAIL.ACS_PJ_ACCOUNT_ID%type
  , aACS_QTY_UNIT_ID               in ACR_CTRL_DETAIL.ACS_QTY_UNIT_ID%type
  , aACS_PERIOD_ID                 in ACR_CTRL_DETAIL.ACS_PERIOD_ID%type
  , aACS_ACS_FINANCIAL_CURRENCY_ID in ACR_CTRL_DETAIL.ACS_ACS_FINANCIAL_CURRENCY_ID%type
  , aACS_TAX_CODE_ID               in ACR_CTRL_DETAIL.ACS_TAX_CODE_ID%type
  )
  is
  begin
    insert into ACR_CTRL_DETAIL
                (ACR_CTRL_DETAIL_ID
               , ACR_CTRL_SUB_SET_ID
               , C_CTRL_CODE
               , ACS_AUXILIARY_ACCOUNT_ID
               , CDE_AMOUNT1
               , CDE_AMOUNT2
               , CDE_AMOUNT1_FC
               , CDE_AMOUNT2_FC
               , ACT_DOCUMENT_ID
               , ACT_PART_IMPUTATION_ID
               , C_TYPE_CUMUL
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_DIVISION_ACCOUNT_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_CPN_ACCOUNT_ID
               , ACS_CDA_ACCOUNT_ID
               , ACS_PF_ACCOUNT_ID
               , ACS_PJ_ACCOUNT_ID
               , ACS_QTY_UNIT_ID
               , ACS_PERIOD_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , ACS_TAX_CODE_ID
               , A_DATECRE
               , A_IDCRE
                )
         values (INIT_ID_SEQ.nextval
               , aACR_CTRL_SUB_SET_ID
               , aC_CTRL_CODE
               , decode(aACS_AUXILIARY_ACCOUNT_ID, 0, null, aACS_AUXILIARY_ACCOUNT_ID)
               , aCDE_AMOUNT1
               , aCDE_AMOUNT2
               , aCDE_AMOUNT1_FC
               , aCDE_AMOUNT2_FC
               , decode(aACT_DOCUMENT_ID, 0, null, aACT_DOCUMENT_ID)
               , decode(aACT_PART_IMPUTATION_ID, 0, null, aACT_PART_IMPUTATION_ID)
               , aC_TYPE_CUMUL
               , decode(aACS_FINANCIAL_CURRENCY_ID, 0, null, aACS_FINANCIAL_CURRENCY_ID)
               , decode(aACS_DIVISION_ACCOUNT_ID, 0, null, aACS_DIVISION_ACCOUNT_ID)
               , decode(aACS_FINANCIAL_ACCOUNT_ID, 0, null, aACS_FINANCIAL_ACCOUNT_ID)
               , decode(aACS_CPN_ACCOUNT_ID, 0, null, aACS_CPN_ACCOUNT_ID)
               , decode(aACS_CDA_ACCOUNT_ID, 0, null, aACS_CDA_ACCOUNT_ID)
               , decode(aACS_PF_ACCOUNT_ID, 0, null, aACS_PF_ACCOUNT_ID)
               , decode(aACS_PJ_ACCOUNT_ID, 0, null, aACS_PJ_ACCOUNT_ID)
               , decode(aACS_QTY_UNIT_ID, 0, null, aACS_QTY_UNIT_ID)
               , decode(aACS_PERIOD_ID, 0, null, aACS_PERIOD_ID)
               , decode(aACS_ACS_FINANCIAL_CURRENCY_ID, 0, null, aACS_ACS_FINANCIAL_CURRENCY_ID)
               , aACS_TAX_CODE_ID
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end InsertCtrlDetail;
-- Initialisation des variables pour la session
begin
  LocalCurrencyId  := ACS_FUNCTION.GetLocalCurrencyId;
end ACR_FINANCIAL_CTRL;
