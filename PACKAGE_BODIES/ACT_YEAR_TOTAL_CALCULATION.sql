--------------------------------------------------------
--  DDL for Package Body ACT_YEAR_TOTAL_CALCULATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_YEAR_TOTAL_CALCULATION" 
is
  /**
  * Recalcul des cumuls financiers (ACT_TOTAL_BY_PERIOD) par exercice
  **/
  procedure YearFinancialCalculation(
    pFinancialYearId in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pFullCalculation in number
  )
  is
    vPreviousYearId   ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
    vCurrentYearState ACS_FINANCIAL_YEAR.C_STATE_FINANCIAL_YEAR%type;

    function DivisionManagement
      return boolean
    is
      vExistDivision number;
    begin
      select decode(min(ACS_SUB_SET_ID), null, 0, 1)
        into vExistDivision
        from ACS_SUB_SET
       where C_TYPE_SUB_SET = 'DIVI';

      return vExistDivision = 1;
    end DivisionManagement;
  begin
    /** Réception statut de l'exercice **/
    select C_STATE_FINANCIAL_YEAR
      into vCurrentYearState
      from ACS_FINANCIAL_YEAR
     where ACS_FINANCIAL_YEAR_ID = pFinancialYearId;

    /**
    * Ne pas traiter les exercices 'En préparation'
    **/
    if vCurrentYearState <> 'PLA' then
      /**
      * Step 1 ..Suppression de tous les cumuls financiers de l'exercice donné (pFullCalculation =1)
      *          ou seulement des périodes de report (pFullCalculation = 0)
      **/
      DeleteYearFinancialTotals(pFinancialYearId, pFullCalculation);

      /**
      * Step 2 ..Mise à jour des cumuls de l'exercice courant sur la base des
      * imputations financières du même exercice  si calcul complète demandé (pFullCalculation= 1)
      * Se fait en 2 étapes ;
      *   1Ý Création des positions sur la base des imputations auxiliaires ( tuple FIN-DIV-AUX)
      *      Création des positions sur la base des imputations financiaères( tupr FIN-DIV-NULL)
      *   2Ý Regroupement par division des positions du total créées au point 1...ce qui permet
      *      de créer les tuples (FIN_NULL_AUX) et (FIN_NULL_NULL)
      **/
      if pFullCalculation = 1 then
        CalculateFinancialTotal(pFinancialYearId);

        if DivisionManagement then
          CreateDivGroupedPositions(pFinancialYearId);
        end if;
      end if;

      /**
      * Step 3 ..Mise à jour des cumuls financier pour la période de report sur la base des cumuls
      * de l'exercice précédent SI ce dernier n'est pas 'bouclé' (s'il est déjà boucle cela
      * signifie que les reports sont déjà matérialisés par les écritures de bouclement dans
      * l'exercice en cours
      **/
      if GetPreviousYearStatus(pFinancialYearId, vPreviousYearId) = 'ACT' then
        CreateFinancialReportPeriod(pFinancialYearId, vPreviousYearId);
      end if;

      /**
      * Suppression des positions de cumul sans montants
      **/
      DeleteNullFinancialPos;
    end if;
  end YearFinancialCalculation;

  /**
  * Recalcul des cumuls analytiques (ACT_MGM_TOT_BY_PERIOD) par exercice
  **/
  procedure YearAnalyticalCalculation(
    pFinancialYearId in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pFullCalculation in number
  )
  is
    vPreviousYearId   ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type;
    vCurrentYearState ACS_FINANCIAL_YEAR.C_STATE_FINANCIAL_YEAR%type;

    function AnalyticalManagement
      return boolean
    is
      vManAccounting number;
    begin
      select nvl(max(ACS_ACCOUNTING_ID), 0)
        into vManAccounting
        from ACS_ACCOUNTING
       where C_TYPE_ACCOUNTING = 'MAN';

      return vManAccounting <> 0;
    end AnalyticalManagement;
  begin
    /** Réception statut de l'exercice **/
    select C_STATE_FINANCIAL_YEAR
      into vCurrentYearState
      from ACS_FINANCIAL_YEAR
     where ACS_FINANCIAL_YEAR_ID = pFinancialYearId;

    /**
    * Ne pas traiter les exercices 'En préparation'
    **/
    if     (AnalyticalManagement)
       and (vCurrentYearState <> 'PLA') then
      /**
      * Step 1 ..Suppression de tous les cumuls financiers de l'exercice donné (pFullCalculation =1)
      *          ou seulement des périodes de report (pFullCalculation = 0)
      **/
      DeleteYearAnalyticalTotals(pFinancialYearId, pFullCalculation);

      /**
      * Step 2 ..Mise à jour des cumuls de l'exercice courant sur la base des
      *         imputations analytiques du même exercice si calcul complète demandé (pFullCalculation= 1)
      **/
      if pFullCalculation = 1 then
        CalculateAnalyticalTotal(pFinancialYearId);
      end if;

      /**
      * Step 3 ..Mise à jour des cumuls pour la période de report sur la base des cumuls
      * de l'exercice précédent SI ce dernier n'est pas 'bouclé' (s'il est déjà boucle cela
      * signifie que les reports sont déjà matérialisés par les écritures de bouclement dans
      * l'exercice en cours
      **/
      if GetPreviousYearStatus(pFinancialYearId, vPreviousYearId) = 'ACT' then
        CreateAnalyticalReportPeriod(pFinancialYearId, vPreviousYearId);
      end if;

      /**
      * Suppression des positions de cumul sans montants
      **/
      DeleteNullAnalyticalPos;
    end if;
  end YearAnalyticalCalculation;

  /**
  * Effacement de tous les cumuls financiers de l'exercice à traiter et des reports suivants
  **/
  procedure DeleteYearFinancialTotals(
    pFinancialYearId in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pFullCalculation in number
  )
  is
  begin
    if not pFinancialYearId is null then
      if pFullCalculation = 1 then
        /**
        * Suppression des enregistrements de la table des cumuls traitant
        * des périodes de l'exercice courant
        **/
        delete from ACT_TOTAL_BY_PERIOD TOT
              where exists(
                           select 1
                             from ACS_PERIOD PER
                            where PER.ACS_FINANCIAL_YEAR_ID = pFinancialYearId
                              and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID);
      else
        /**
        * Suppression des enregistrements de la table des cumuls traitant
        * des périodes de report de l'exercice courant
        **/
        delete from ACT_TOTAL_BY_PERIOD TOT
              where exists(
                      select 1
                        from ACS_PERIOD PER
                       where PER.ACS_FINANCIAL_YEAR_ID = pFinancialYearId
                         and PER.C_TYPE_PERIOD = '1'
                         and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID);
      end if;

      commit;
    end if;
  end DeleteYearFinancialTotals;

  /**
  * Suppression de tous les cumuls analytiques de l'exercice à traiter et des reports suivants
  **/
  procedure DeleteYearAnalyticalTotals(
    pFinancialYearId in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pFullCalculation in number
  )
  is
  begin
    if not pFinancialYearId is null then
      if pFullCalculation = 1 then
        /**
        * Suppression des enregistrements de la table des cumuls traitant
        * des périodes de l'exercice courant
        **/
        delete from ACT_MGM_TOT_BY_PERIOD TOT
              where exists(
                           select 1
                             from ACS_PERIOD PER
                            where PER.ACS_FINANCIAL_YEAR_ID = pFinancialYearId
                              and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID);
      else
        /**
        * Suppression des enregistrements de la table des cumuls traitant
        * des périodes de report de l'exercice courant
        **/
        delete from ACT_MGM_TOT_BY_PERIOD TOT
              where exists(
                      select 1
                        from ACS_PERIOD PER
                       where PER.ACS_FINANCIAL_YEAR_ID = pFinancialYearId
                         and PER.C_TYPE_PERIOD = '1'
                         and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID);
      end if;

      commit;
    end if;
  end DeleteYearAnalyticalTotals;

  /**
  * Suppression des positions financières sans montants
  **/
  procedure DeleteNullFinancialPos
  is
  begin
    delete from ACT_TOTAL_BY_PERIOD TOT
          where nvl(TOT_DEBIT_LC, 0) = 0
            and nvl(TOT_CREDIT_LC, 0) = 0
            and nvl(TOT_DEBIT_FC, 0) = 0
            and nvl(TOT_CREDIT_FC, 0) = 0;

    commit;
  end DeleteNullFinancialPos;

  /**
  * Suppression des positions analytiques sans montants
  **/
  procedure DeleteNullAnalyticalPos
  is
  begin
    delete from ACT_MGM_TOT_BY_PERIOD TOT
          where nvl(MTO_DEBIT_LC, 0) = 0
            and nvl(MTO_CREDIT_LC, 0) = 0
            and nvl(MTO_DEBIT_FC, 0) = 0
            and nvl(MTO_CREDIT_FC, 0) = 0
            and nvl(MTO_QUANTITY_D, 0) = 0
            and nvl(MTO_QUANTITY_C, 0) = 0;

    commit;
  end DeleteNullAnalyticalPos;

  /**
  * Fonction de retour du statut et de l'id (par variable) de l'exercice précédent l'exercice donné
  **/
  function GetPreviousYearStatus(
    pCurrentFinancialYearId in     ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pPreviousYearId         in out ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  )
    return ACS_FINANCIAL_YEAR.C_STATE_FINANCIAL_YEAR%type
  is
    /* Curseur de recherche des exercice précédent l'exercice donné */
    cursor curPreviousYearsCursor
    is
      select   FYE.ACS_FINANCIAL_YEAR_ID
             , FYE.C_STATE_FINANCIAL_YEAR
          from ACS_FINANCIAL_YEAR FYE
         where exists(
                 select 1
                   from ACS_FINANCIAL_YEAR YEA
                  where YEA.ACS_FINANCIAL_YEAR_ID = pCurrentFinancialYearId
                    and trunc(FYE.FYE_END_DATE) < trunc(YEA.FYE_START_DATE) )
      order by FYE.FYE_NO_EXERCICE desc;

    vResult ACS_FINANCIAL_YEAR.C_STATE_FINANCIAL_YEAR%type;   --Réceptionne valeur de retour
  begin
    pPreviousYearId  := 0.0;

    if not pCurrentFinancialYearId is null then
      /*Ouverture et réception du statut du premier enregistrement des exercices précédents*/
      open curPreviousYearsCursor;

      fetch curPreviousYearsCursor
       into pPreviousYearId
          , vResult;

      close curPreviousYearsCursor;
    end if;

    return vResult;
  end GetPreviousYearStatus;

  /**
  * Mise à jour des périodes de cumul financier de l'exercice traité selon cumuls de l'exercice de base
  **/
  procedure CreateFinancialReportPeriod(
    pTreatedFinancialYearId in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , pBaseFinancialYearId    in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  )
  is
    vCurrentReportPerId ACS_PERIOD.ACS_PERIOD_ID%type;
  begin
    vCurrentReportPerId  := 0;

    if not pTreatedFinancialYearId is null then
      begin
        /* Réception de la période de report de l'exercice traité */
        select PER.ACS_PERIOD_ID
          into vCurrentReportPerId
          from ACS_PERIOD PER
         where PER.ACS_FINANCIAL_YEAR_ID = pTreatedFinancialYearId
           and PER.C_TYPE_PERIOD = '1';
      exception
        when no_data_found then
          vCurrentReportPerId  := 0;
      end;

      if vCurrentReportPerId <> 0 then
        insert into ACT_TOTAL_BY_PERIOD
                    (ACT_TOTAL_BY_PERIOD_ID
                   , ACS_PERIOD_ID
                   , TOT_DEBIT_LC
                   , TOT_DEBIT_FC
                   , TOT_DEBIT_EUR
                   , TOT_CREDIT_LC
                   , TOT_CREDIT_FC
                   , TOT_CREDIT_EUR
                   , ACS_FINANCIAL_ACCOUNT_ID
                   , ACS_DIVISION_ACCOUNT_ID
                   , ACS_AUXILIARY_ACCOUNT_ID
                   , ACS_FINANCIAL_CURRENCY_ID
                   , ACS_ACS_FINANCIAL_CURRENCY_ID
                   , C_TYPE_PERIOD
                   , C_TYPE_CUMUL
                   , A_DATECRE
                   , A_IDCRE
                    )
          select INIT_ID_SEQ.nextval
               , vCurrentReportPerId
               , decode(sign(TOTAL_LC), 1, TOTAL_LC, 0)
               , decode(sign(TOTAL_FC), 1, TOTAL_FC, 0)
               , decode(sign(TOTAL_EUR), 1, TOTAL_EUR, 0)
               , decode(sign(TOTAL_LC), 1, 0, -TOTAL_LC)
               , decode(sign(TOTAL_FC), 1, 0, -TOTAL_FC)
               , decode(sign(TOTAL_EUR), 1, 0, -TOTAL_EUR)
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_DIVISION_ACCOUNT_ID
               , ACS_AUXILIARY_ACCOUNT_ID
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , '1'
               , C_TYPE_CUMUL
               , sysdate
               , userini
            from (select   sum(TOT_DEBIT_LC - TOT_CREDIT_LC) TOTAL_LC
                         , sum(TOT_DEBIT_FC - TOT_CREDIT_FC) TOTAL_FC
                         , sum(TOT_DEBIT_EUR - TOT_CREDIT_EUR) TOTAL_EUR
                         , TOT.ACS_FINANCIAL_ACCOUNT_ID
                         , TOT.ACS_DIVISION_ACCOUNT_ID
                         , TOT.ACS_AUXILIARY_ACCOUNT_ID
                         , TOT.ACS_FINANCIAL_CURRENCY_ID
                         , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                         , TOT.C_TYPE_CUMUL
                      from ACT_TOTAL_BY_PERIOD TOT
                         , ACS_PERIOD PER
                         , ACS_FINANCIAL_ACCOUNT FIN
                     where PER.ACS_FINANCIAL_YEAR_ID = pBaseFinancialYearId
                       and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                       and FIN.ACS_FINANCIAL_ACCOUNT_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID
                       and FIN.C_BALANCE_SHEET_PROFIT_LOSS = 'B'
                       and exists(
                             select 1
                               from ACJ_SUB_SET_CAT SCA
                                  , ACJ_CATALOGUE_DOCUMENT CAT
                              where CAT.C_TYPE_CATALOGUE = '7'
                                and SCA.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
                                and SCA.C_SUB_SET in('ACC', 'REC', 'PAY')
                                and TOT.C_TYPE_CUMUL = SCA.C_TYPE_CUMUL)
                  group by TOT.ACS_FINANCIAL_ACCOUNT_ID
                         , TOT.ACS_DIVISION_ACCOUNT_ID
                         , TOT.ACS_AUXILIARY_ACCOUNT_ID
                         , TOT.ACS_FINANCIAL_CURRENCY_ID
                         , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                         , TOT.C_TYPE_CUMUL);

        commit;
      end if;
    end if;
  end CreateFinancialReportPeriod;

  /**
  * Mise à jour des périodes de cumul analytique de l'exercice traité selon cumuls de l'exercice de base
  **/
  procedure CreateAnalyticalReportPeriod(
    iTreatedFinancialYearId in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  , iBaseFinancialYearId    in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type
  )
  is
    cursor curBasePeriodTotal(iBaseFinYearId ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
    is
      select ACS_FINANCIAL_ACCOUNT_ID
           , ACS_DIVISION_ACCOUNT_ID
           , ACS_CPN_ACCOUNT_ID
           , ACS_CDA_ACCOUNT_ID
           , ACS_PF_ACCOUNT_ID
           , ACS_PJ_ACCOUNT_ID
           , ACS_QTY_UNIT_ID
           , DOC_RECORD_ID
           , decode(sign(TOTAL_LC), 1, TOTAL_LC, 0) TOTAL_LCD
           , decode(sign(TOTAL_FC), 1, TOTAL_FC, 0) TOTAL_FCD
           , decode(sign(TOTAL_EUR), 1, TOTAL_EUR, 0) TOTAL_EUD
           , decode(sign(TOTAL_QTU), 1, TOTAL_QTU, 0) TOTAL_QTD
           , decode(sign(TOTAL_LC), 1, 0, -TOTAL_LC) TOTAL_LCC
           , decode(sign(TOTAL_FC), 1, 0, -TOTAL_FC) TOTAL_FCC
           , decode(sign(TOTAL_EUR), 1, 0, -TOTAL_EUR) TOTAL_EUC
           , decode(sign(TOTAL_QTU), 1, 0, -TOTAL_QTU) TOTAL_QTC
           , ACS_FINANCIAL_CURRENCY_ID
           , ACS_ACS_FINANCIAL_CURRENCY_ID
           , C_TYPE_CUMUL
        from (select   sum(MTO_DEBIT_LC - MTO_CREDIT_LC) TOTAL_LC
                     , sum(MTO_DEBIT_FC - MTO_CREDIT_FC) TOTAL_FC
                     , sum(MTO_DEBIT_EUR - MTO_CREDIT_EUR) TOTAL_EUR
                     , sum(MTO_QUANTITY_D - MTO_QUANTITY_C) TOTAL_QTU
                     , TOT.ACS_CPN_ACCOUNT_ID
                     , case
                         when exists(select 1
                                       from ACS_FINANCIAL_ACCOUNT
                                      where ACS_CPN_ACCOUNT_ID = TOT.ACS_CPN_ACCOUNT_ID
                                        and C_BALANCE_SHEET_PROFIT_LOSS = 'B') then TOT.ACS_CDA_ACCOUNT_ID
                         else null
                       end ACS_CDA_ACCOUNT_ID
                     , case
                         when exists(select 1
                                       from ACS_FINANCIAL_ACCOUNT
                                      where ACS_CPN_ACCOUNT_ID = TOT.ACS_CPN_ACCOUNT_ID
                                        and C_BALANCE_SHEET_PROFIT_LOSS = 'B') then TOT.ACS_PF_ACCOUNT_ID
                         else null
                       end ACS_PF_ACCOUNT_ID
                     , case
                         when exists(select 1
                                       from ACS_PJ_ACCOUNT PJ
                                      where PJ.MGM_TRANSFER = 1
                                        and PJ.ACS_PJ_ACCOUNT_ID = TOT.ACS_PJ_ACCOUNT_ID) then TOT.ACS_PJ_ACCOUNT_ID
                         else null
                       end ACS_PJ_ACCOUNT_ID
                     , TOT.ACS_QTY_UNIT_ID
                     , TOT.DOC_RECORD_ID
                     , TOT.ACS_FINANCIAL_ACCOUNT_ID
                     , TOT.ACS_DIVISION_ACCOUNT_ID
                     , TOT.ACS_FINANCIAL_CURRENCY_ID
                     , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , TOT.C_TYPE_CUMUL
                  from ACT_MGM_TOT_BY_PERIOD TOT
                     , ACS_PERIOD PER
                 where PER.ACS_FINANCIAL_YEAR_ID = iBaseFinYearId
                   and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                   and (   exists(select 1
                                    from ACS_PJ_ACCOUNT PJ
                                   where PJ.MGM_TRANSFER = 1
                                     and PJ.ACS_PJ_ACCOUNT_ID = TOT.ACS_PJ_ACCOUNT_ID)
                        or exists(select 1
                                    from DOC_RECORD
                                   where DOC_RECORD_ID = TOT.DOC_RECORD_ID)
                        or exists(
                             select 1
                               from ACS_FINANCIAL_ACCOUNT FIN
                              where FIN.C_BALANCE_SHEET_PROFIT_LOSS = 'B'
                                and FIN.ACS_CPN_ACCOUNT_ID = TOT.ACS_CPN_ACCOUNT_ID)
                       )
                   and exists(
                         select 1
                           from ACJ_SUB_SET_CAT SCA
                              , ACJ_CATALOGUE_DOCUMENT CAT
                          where CAT.C_TYPE_CATALOGUE = '7'
                            and SCA.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
                            and SCA.C_SUB_SET = 'CPN'
                            and TOT.C_TYPE_CUMUL = SCA.C_TYPE_CUMUL)
              group by TOT.ACS_CPN_ACCOUNT_ID
                     , TOT.ACS_CDA_ACCOUNT_ID
                     , TOT.ACS_PF_ACCOUNT_ID
                     , TOT.ACS_PJ_ACCOUNT_ID
                     , TOT.ACS_QTY_UNIT_ID
                     , TOT.DOC_RECORD_ID
                     , TOT.ACS_FINANCIAL_ACCOUNT_ID
                     , TOT.ACS_DIVISION_ACCOUNT_ID
                     , TOT.ACS_FINANCIAL_CURRENCY_ID
                     , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , TOT.C_TYPE_CUMUL);

    lCurrentReportPerId ACS_PERIOD.ACS_PERIOD_ID%type;
    tplBasePeriodTotal  curBasePeriodTotal%rowtype;
    lRecordId           ACT_MGM_TOT_BY_PERIOD.ACT_MGM_TOT_BY_PERIOD_id%type;
  begin
    if not iTreatedFinancialYearId is null then
      /* Réception de la période de report de l'exercice traité */
      select nvl(max(PER.ACS_PERIOD_ID), 0)
        into lCurrentReportPerId
        from ACS_PERIOD PER
       where PER.ACS_FINANCIAL_YEAR_ID = iTreatedFinancialYearId
         and PER.C_TYPE_PERIOD = '1';

      if lCurrentReportPerId <> 0 then
        /**
        *  Reprise des positions des totaux
        *    des periodes de l annee de base
        *    dont le pj indique un report ou le compte financier lié est de type Bilan
        *    dont les types de cumul correspondent aux types de cumul des catalogues de report (7) analytiques
        **/
        open curBasePeriodTotal(iBaseFinancialYearId);

        fetch curBasePeriodTotal
         into tplBasePeriodTotal;

        while curBasePeriodTotal%found loop
          lRecordId := 0.0;
          ACT_PRC_MGM_TOT_BY_PERIOD.CreateMgmTotPosition(lRecordId
                                                       , lCurrentReportPerId
                                                       , tplBasePeriodTotal.ACS_FINANCIAL_ACCOUNT_ID
                                                       , tplBasePeriodTotal.ACS_DIVISION_ACCOUNT_ID
                                                       , tplBasePeriodTotal.ACS_CPN_ACCOUNT_ID
                                                       , tplBasePeriodTotal.ACS_CDA_ACCOUNT_ID
                                                       , tplBasePeriodTotal.ACS_PF_ACCOUNT_ID
                                                       , tplBasePeriodTotal.ACS_PJ_ACCOUNT_ID
                                                       , tplBasePeriodTotal.ACS_QTY_UNIT_ID
                                                       , tplBasePeriodTotal.DOC_RECORD_ID
                                                       , nvl(tplBasePeriodTotal.TOTAL_LCD, 0)
                                                       , nvl(tplBasePeriodTotal.TOTAL_LCC, 0)
                                                       , nvl(tplBasePeriodTotal.TOTAL_FCD, 0)
                                                       , nvl(tplBasePeriodTotal.TOTAL_FCC, 0)
                                                       , nvl(tplBasePeriodTotal.TOTAL_EUD, 0)
                                                       , nvl(tplBasePeriodTotal.TOTAL_EUC, 0)
                                                       , nvl(tplBasePeriodTotal.TOTAL_QTD, 0)
                                                       , nvl(tplBasePeriodTotal.TOTAL_QTC, 0)
                                                       , tplBasePeriodTotal.ACS_FINANCIAL_CURRENCY_ID
                                                       , tplBasePeriodTotal.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                       , tplBasePeriodTotal.C_TYPE_CUMUL
                                                       , 1
                                                        );
          commit;
          fetch curBasePeriodTotal
           into tplBasePeriodTotal;
        end loop;

        close curBasePeriodTotal;
      end if;
    end if;
  end CreateAnalyticalReportPeriod;

  /**
  *  Mise à jour des cumuls de l'exercice donné sur la base des imputations de ce même exercice
  **/
  procedure CalculateFinancialTotal(pTreatedFinancialYearId in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
  is
  begin
    /**
    * Ajout des positions d'imputations auxiliaires Débiteur
    **/
    insert into ACT_TOTAL_BY_PERIOD
                (ACT_TOTAL_BY_PERIOD_ID
               , ACS_PERIOD_ID
               , TOT_DEBIT_LC
               , TOT_CREDIT_LC
               , TOT_DEBIT_FC
               , TOT_CREDIT_FC
               , TOT_DEBIT_EUR
               , TOT_CREDIT_EUR
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_AUXILIARY_ACCOUNT_ID
               , ACS_DIVISION_ACCOUNT_ID
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , C_TYPE_PERIOD
               , C_TYPE_CUMUL
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval
           , ACS_PERIOD_ID
           , decode(C_TYPE_PERIOD
                  , 1, decode(sign(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C), 1,(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C), 0)
                  , IMF_AMOUNT_LC_D
                   )
           , decode(C_TYPE_PERIOD
                  , 1, decode(sign(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C), 1, 0, -(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C) )
                  , IMF_AMOUNT_LC_C
                   )
           , decode(ACS_FINANCIAL_CURRENCY_ID
                  , ACS_ACS_FINANCIAL_CURRENCY_ID, 0
                  , decode(C_TYPE_PERIOD
                         , 1, decode(sign(IMF_AMOUNT_FC_D - IMF_AMOUNT_FC_C), 1,(IMF_AMOUNT_FC_D - IMF_AMOUNT_FC_C), 0)
                         , IMF_AMOUNT_FC_D
                          )
                   )
           , decode(ACS_FINANCIAL_CURRENCY_ID
                  , ACS_ACS_FINANCIAL_CURRENCY_ID, 0
                  , decode(C_TYPE_PERIOD
                         , 1, decode(sign(IMF_AMOUNT_FC_D - IMF_AMOUNT_FC_C)
                                   , 1, 0
                                   , -(IMF_AMOUNT_FC_D - IMF_AMOUNT_FC_C)
                                    )
                         , IMF_AMOUNT_FC_C
                          )
                   )
           , IMF_AMOUNT_EUR_D
           , IMF_AMOUNT_EUR_C
           , ACS_FINANCIAL_ACCOUNT_ID
           , ACS_AUXILIARY_ACCOUNT_ID
           , IMF_ACS_DIVISION_ACCOUNT_ID
           , ACS_ACS_FINANCIAL_CURRENCY_ID
           , ACS_FINANCIAL_CURRENCY_ID
           , C_TYPE_PERIOD
           , C_TYPE_CUMUL
           , sysdate
           , userini
        from (select   IMP.ACS_PERIOD_ID
                     , decode(CAT.C_TYPE_CATALOGUE
                            , '9', decode(sign(sum(nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0) ) )
                                        , 1, sum(nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0) )
                                        , 0
                                         )
                            , sum(nvl(IMP.IMF_AMOUNT_LC_D, 0) )
                             ) IMF_AMOUNT_LC_D
                     , decode(CAT.C_TYPE_CATALOGUE
                            , '9', decode(sign(sum(nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0) ) )
                                        , 1, 0
                                        , abs(sum(nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0) ) )
                                         )
                            , sum(nvl(IMP.IMF_AMOUNT_LC_C, 0) )
                             ) IMF_AMOUNT_LC_C
                     , decode(CAT.C_TYPE_CATALOGUE
                            , '9', decode(sign(sum(nvl(IMP.IMF_AMOUNT_FC_D, 0) - nvl(IMP.IMF_AMOUNT_FC_C, 0) ) )
                                        , 1, sum(nvl(IMP.IMF_AMOUNT_FC_D, 0) - nvl(IMP.IMF_AMOUNT_FC_C, 0) )
                                        , 0
                                         )
                            , sum(nvl(IMP.IMF_AMOUNT_FC_D, 0) )
                             ) IMF_AMOUNT_FC_D
                     , decode(CAT.C_TYPE_CATALOGUE
                            , '9', decode(sign(sum(nvl(IMP.IMF_AMOUNT_FC_D, 0) - nvl(IMP.IMF_AMOUNT_FC_C, 0) ) )
                                        , 1, 0
                                        , abs(sum(nvl(IMP.IMF_AMOUNT_FC_D, 0) - nvl(IMP.IMF_AMOUNT_FC_C, 0) ) )
                                         )
                            , sum(nvl(IMP.IMF_AMOUNT_FC_C, 0) )
                             ) IMF_AMOUNT_FC_C
                     , decode(CAT.C_TYPE_CATALOGUE
                            , '9', decode(sign(sum(nvl(IMP.IMF_AMOUNT_EUR_D, 0) - nvl(IMP.IMF_AMOUNT_EUR_C, 0) ) )
                                        , 1, sum(nvl(IMP.IMF_AMOUNT_EUR_D, 0) - nvl(IMP.IMF_AMOUNT_EUR_C, 0) )
                                        , 0
                                         )
                            , sum(nvl(IMP.IMF_AMOUNT_EUR_D, 0) )
                             ) IMF_AMOUNT_EUR_D
                     , decode(CAT.C_TYPE_CATALOGUE
                            , '9', decode(sign(sum(nvl(IMP.IMF_AMOUNT_EUR_D, 0) - nvl(IMP.IMF_AMOUNT_EUR_C, 0) ) )
                                        , 1, sum(nvl(IMP.IMF_AMOUNT_EUR_D, 0) - nvl(IMP.IMF_AMOUNT_EUR_C, 0) )
                                        , 0
                                         )
                            , sum(nvl(IMP.IMF_AMOUNT_EUR_C, 0) )
                             ) IMF_AMOUNT_EUR_C
                     , IMP.ACS_FINANCIAL_ACCOUNT_ID
                     , IMP.ACS_AUXILIARY_ACCOUNT_ID
                     , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                     , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , IMP.ACS_FINANCIAL_CURRENCY_ID
                     , CAT.C_TYPE_PERIOD
                     , SCA.C_TYPE_CUMUL
                  from ACJ_CATALOGUE_DOCUMENT CAT
                     , ACS_ACCOUNT AUX
                     , ACS_SUB_SET SUB
                     , ACJ_SUB_SET_CAT SCA
                     , ACT_ETAT_JOURNAL ETA
                     , ACT_DOCUMENT DOC
                     , ACT_FINANCIAL_IMPUTATION IMP
                 where IMP.IMF_ACS_FINANCIAL_YEAR_ID = pTreatedFinancialYearId
                   and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
                   and CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
                   and SCA.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
                   and ETA.C_SUB_SET = SCA.C_SUB_SET
                   and ETA.ACT_JOURNAL_ID = DOC.ACT_JOURNAL_ID
                   and ETA.C_SUB_SET = 'REC'
                   and ETA.C_ETAT_JOURNAL <> 'BRO'
                   and SUB.C_SUB_SET = ETA.C_SUB_SET
                   and AUX.ACS_ACCOUNT_ID = IMP.ACS_AUXILIARY_ACCOUNT_ID
                   and SUB.ACS_SUB_SET_ID = AUX.ACS_SUB_SET_ID
                   and SUB.SSE_TOTAL = 1
              group by IMP.ACS_FINANCIAL_ACCOUNT_ID
                     , IMP.ACS_AUXILIARY_ACCOUNT_ID
                     , IMP.ACS_PERIOD_ID
                     , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , IMP.ACS_FINANCIAL_CURRENCY_ID
                     , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                     , CAT.C_TYPE_CATALOGUE
                     , CAT.C_TYPE_PERIOD
                     , SCA.C_TYPE_CUMUL
              order by IMP.ACS_FINANCIAL_ACCOUNT_ID
                     , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                     , IMP.ACS_AUXILIARY_ACCOUNT_ID
                     , IMP.ACS_PERIOD_ID);

    commit;

    /**
    * Ajout des positions d'imputations auxiliaires Créancier
    **/
    insert into ACT_TOTAL_BY_PERIOD
                (ACT_TOTAL_BY_PERIOD_ID
               , ACS_PERIOD_ID
               , TOT_DEBIT_LC
               , TOT_CREDIT_LC
               , TOT_DEBIT_FC
               , TOT_CREDIT_FC
               , TOT_DEBIT_EUR
               , TOT_CREDIT_EUR
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_AUXILIARY_ACCOUNT_ID
               , ACS_DIVISION_ACCOUNT_ID
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , C_TYPE_PERIOD
               , C_TYPE_CUMUL
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval
           , ACS_PERIOD_ID
           , decode(C_TYPE_PERIOD
                  , 1, decode(sign(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C), 1,(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C), 0)
                  , IMF_AMOUNT_LC_D
                   )
           , decode(C_TYPE_PERIOD
                  , 1, decode(sign(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C), 1, 0, -(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C) )
                  , IMF_AMOUNT_LC_C
                   )
           , decode(ACS_FINANCIAL_CURRENCY_ID
                  , ACS_ACS_FINANCIAL_CURRENCY_ID, 0
                  , decode(C_TYPE_PERIOD
                         , 1, decode(sign(IMF_AMOUNT_FC_D - IMF_AMOUNT_FC_C), 1,(IMF_AMOUNT_FC_D - IMF_AMOUNT_FC_C), 0)
                         , IMF_AMOUNT_FC_D
                          )
                   )
           , decode(ACS_FINANCIAL_CURRENCY_ID
                  , ACS_ACS_FINANCIAL_CURRENCY_ID, 0
                  , decode(C_TYPE_PERIOD
                         , 1, decode(sign(IMF_AMOUNT_FC_D - IMF_AMOUNT_FC_C)
                                   , 1, 0
                                   , -(IMF_AMOUNT_FC_D - IMF_AMOUNT_FC_C)
                                    )
                         , IMF_AMOUNT_FC_C
                          )
                   )
           , IMF_AMOUNT_EUR_D
           , IMF_AMOUNT_EUR_C
           , ACS_FINANCIAL_ACCOUNT_ID
           , ACS_AUXILIARY_ACCOUNT_ID
           , IMF_ACS_DIVISION_ACCOUNT_ID
           , ACS_ACS_FINANCIAL_CURRENCY_ID
           , ACS_FINANCIAL_CURRENCY_ID
           , C_TYPE_PERIOD
           , C_TYPE_CUMUL
           , sysdate
           , userini
        from (select   IMP.ACS_PERIOD_ID
                     , decode(CAT.C_TYPE_CATALOGUE
                            , '9', decode(sign(sum(nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0) ) )
                                        , 1, sum(nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0) )
                                        , 0
                                         )
                            , sum(nvl(IMP.IMF_AMOUNT_LC_D, 0) )
                             ) IMF_AMOUNT_LC_D
                     , decode(CAT.C_TYPE_CATALOGUE
                            , '9', decode(sign(sum(nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0) ) )
                                        , 1, 0
                                        , abs(sum(nvl(IMP.IMF_AMOUNT_LC_D, 0) - nvl(IMP.IMF_AMOUNT_LC_C, 0) ) )
                                         )
                            , sum(nvl(IMP.IMF_AMOUNT_LC_C, 0) )
                             ) IMF_AMOUNT_LC_C
                     , decode(CAT.C_TYPE_CATALOGUE
                            , '9', decode(sign(sum(nvl(IMP.IMF_AMOUNT_FC_D, 0) - nvl(IMP.IMF_AMOUNT_FC_C, 0) ) )
                                        , 1, sum(nvl(IMP.IMF_AMOUNT_FC_D, 0) - nvl(IMP.IMF_AMOUNT_FC_C, 0) )
                                        , 0
                                         )
                            , sum(nvl(IMP.IMF_AMOUNT_FC_D, 0) )
                             ) IMF_AMOUNT_FC_D
                     , decode(CAT.C_TYPE_CATALOGUE
                            , '9', decode(sign(sum(nvl(IMP.IMF_AMOUNT_FC_D, 0) - nvl(IMP.IMF_AMOUNT_FC_C, 0) ) )
                                        , 1, 0
                                        , abs(sum(nvl(IMP.IMF_AMOUNT_FC_D, 0) - nvl(IMP.IMF_AMOUNT_FC_C, 0) ) )
                                         )
                            , sum(nvl(IMP.IMF_AMOUNT_FC_C, 0) )
                             ) IMF_AMOUNT_FC_C
                     , decode(CAT.C_TYPE_CATALOGUE
                            , '9', decode(sign(sum(nvl(IMP.IMF_AMOUNT_EUR_D, 0) - nvl(IMP.IMF_AMOUNT_EUR_C, 0) ) )
                                        , 1, sum(nvl(IMP.IMF_AMOUNT_EUR_D, 0) - nvl(IMP.IMF_AMOUNT_EUR_C, 0) )
                                        , 0
                                         )
                            , sum(nvl(IMP.IMF_AMOUNT_EUR_D, 0) )
                             ) IMF_AMOUNT_EUR_D
                     , decode(CAT.C_TYPE_CATALOGUE
                            , '9', decode(sign(sum(nvl(IMP.IMF_AMOUNT_EUR_D, 0) - nvl(IMP.IMF_AMOUNT_EUR_C, 0) ) )
                                        , 1, sum(nvl(IMP.IMF_AMOUNT_EUR_D, 0) - nvl(IMP.IMF_AMOUNT_EUR_C, 0) )
                                        , 0
                                         )
                            , sum(nvl(IMP.IMF_AMOUNT_EUR_C, 0) )
                             ) IMF_AMOUNT_EUR_C
                     , IMP.ACS_FINANCIAL_ACCOUNT_ID
                     , IMP.ACS_AUXILIARY_ACCOUNT_ID
                     , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                     , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , IMP.ACS_FINANCIAL_CURRENCY_ID
                     , CAT.C_TYPE_PERIOD
                     , SCA.C_TYPE_CUMUL
                  from ACJ_CATALOGUE_DOCUMENT CAT
                     , ACS_ACCOUNT AUX
                     , ACS_SUB_SET SUB
                     , ACJ_SUB_SET_CAT SCA
                     , ACT_ETAT_JOURNAL ETA
                     , ACT_DOCUMENT DOC
                     , ACT_FINANCIAL_IMPUTATION IMP
                 where IMP.IMF_ACS_FINANCIAL_YEAR_ID = pTreatedFinancialYearId
                   and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
                   and CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
                   and SCA.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
                   and ETA.C_SUB_SET = SCA.C_SUB_SET
                   and ETA.ACT_JOURNAL_ID = DOC.ACT_JOURNAL_ID
                   and ETA.C_SUB_SET = 'PAY'
                   and ETA.C_ETAT_JOURNAL <> 'BRO'
                   and SUB.C_SUB_SET = ETA.C_SUB_SET
                   and AUX.ACS_ACCOUNT_ID = IMP.ACS_AUXILIARY_ACCOUNT_ID
                   and SUB.ACS_SUB_SET_ID = AUX.ACS_SUB_SET_ID
                   and SUB.SSE_TOTAL = 1
              group by IMP.ACS_FINANCIAL_ACCOUNT_ID
                     , IMP.ACS_AUXILIARY_ACCOUNT_ID
                     , IMP.ACS_PERIOD_ID
                     , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , IMP.ACS_FINANCIAL_CURRENCY_ID
                     , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                     , CAT.C_TYPE_CATALOGUE
                     , CAT.C_TYPE_PERIOD
                     , SCA.C_TYPE_CUMUL
              order by IMP.ACS_FINANCIAL_ACCOUNT_ID
                     , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                     , IMP.ACS_AUXILIARY_ACCOUNT_ID
                     , IMP.ACS_PERIOD_ID);

    commit;

    /**
    * Ajout des positions d'imputations financières
    **/
    insert into ACT_TOTAL_BY_PERIOD
                (ACT_TOTAL_BY_PERIOD_ID
               , ACS_PERIOD_ID
               , TOT_DEBIT_LC
               , TOT_CREDIT_LC
               , TOT_DEBIT_FC
               , TOT_CREDIT_FC
               , TOT_DEBIT_EUR
               , TOT_CREDIT_EUR
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_DIVISION_ACCOUNT_ID
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , C_TYPE_PERIOD
               , C_TYPE_CUMUL
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval
           , ACS_PERIOD_ID
           , decode(C_TYPE_PERIOD
                  , 1, decode(sign(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C), 1,(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C), 0)
                  , IMF_AMOUNT_LC_D
                   )
           , decode(C_TYPE_PERIOD
                  , 1, decode(sign(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C), 1, 0, -(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C) )
                  , IMF_AMOUNT_LC_C
                   )
           , decode(ACS_FINANCIAL_CURRENCY_ID
                  , ACS_ACS_FINANCIAL_CURRENCY_ID, 0
                  , decode(C_TYPE_PERIOD
                         , 1, decode(sign(IMF_AMOUNT_FC_D - IMF_AMOUNT_FC_C), 1,(IMF_AMOUNT_FC_D - IMF_AMOUNT_FC_C), 0)
                         , IMF_AMOUNT_FC_D
                          )
                   )
           , decode(ACS_FINANCIAL_CURRENCY_ID
                  , ACS_ACS_FINANCIAL_CURRENCY_ID, 0
                  , decode(C_TYPE_PERIOD
                         , 1, decode(sign(IMF_AMOUNT_FC_D - IMF_AMOUNT_FC_C)
                                   , 1, 0
                                   , -(IMF_AMOUNT_FC_D - IMF_AMOUNT_FC_C)
                                    )
                         , IMF_AMOUNT_FC_C
                          )
                   )
           , IMF_AMOUNT_EUR_D
           , IMF_AMOUNT_EUR_C
           , ACS_FINANCIAL_ACCOUNT_ID
           , IMF_ACS_DIVISION_ACCOUNT_ID
           , ACS_ACS_FINANCIAL_CURRENCY_ID
           , ACS_FINANCIAL_CURRENCY_ID
           , C_TYPE_PERIOD
           , C_TYPE_CUMUL
           , sysdate
           , UserIni
        from (select   ACS_PERIOD_ID
                     , sum(IMF_AMOUNT_LC_D) IMF_AMOUNT_LC_D
                     , sum(IMF_AMOUNT_LC_C) IMF_AMOUNT_LC_C
                     , sum(decode(nvl(CURRENCY_ID, 0) + FIN_COLLECTIVE, 0, 0, IMF_AMOUNT_FC_D) ) IMF_AMOUNT_FC_D
                     , sum(decode(nvl(CURRENCY_ID, 0) + FIN_COLLECTIVE, 0, 0, IMF_AMOUNT_FC_C) ) IMF_AMOUNT_FC_C
                     , sum(decode(nvl(CURRENCY_ID, 0) + FIN_COLLECTIVE, 0, 0, IMF_AMOUNT_EUR_D) ) IMF_AMOUNT_EUR_D
                     , sum(decode(nvl(CURRENCY_ID, 0) + FIN_COLLECTIVE, 0, 0, IMF_AMOUNT_EUR_C) ) IMF_AMOUNT_EUR_C
                     , ACS_FINANCIAL_ACCOUNT_ID
                     , IMF_ACS_DIVISION_ACCOUNT_ID
                     , ACS_ACS_FINANCIAL_CURRENCY_ID
                     , decode(nvl(CURRENCY_ID, 0) + FIN_COLLECTIVE
                            , 0, ACS_ACS_FINANCIAL_CURRENCY_ID
                            , ACS_FINANCIAL_CURRENCY_ID
                             ) ACS_FINANCIAL_CURRENCY_ID
                     , C_TYPE_PERIOD
                     , C_TYPE_CUMUL
                  from (select IMP.ACS_FINANCIAL_ACCOUNT_ID
                             , IMP.ACS_PERIOD_ID
                             , (nvl(IMP.IMF_AMOUNT_LC_D, 0) ) IMF_AMOUNT_LC_D
                             , (nvl(IMP.IMF_AMOUNT_LC_C, 0) ) IMF_AMOUNT_LC_C
                             , (nvl(IMP.IMF_AMOUNT_FC_D, 0) ) IMF_AMOUNT_FC_D
                             , (nvl(IMP.IMF_AMOUNT_FC_C, 0) ) IMF_AMOUNT_FC_C
                             , (nvl(IMP.IMF_AMOUNT_EUR_D, 0) ) IMF_AMOUNT_EUR_D
                             , (nvl(IMP.IMF_AMOUNT_EUR_C, 0) ) IMF_AMOUNT_EUR_C
                             , IMP.ACS_FINANCIAL_CURRENCY_ID
                             , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
                             , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                             , CAT.C_TYPE_PERIOD
                             , SCA.C_TYPE_CUMUL
                             , FIN.FIN_COLLECTIVE
                             , (select ACS_FINANCIAL_CURRENCY_ID
                                  from ACS_FIN_ACCOUNT_S_FIN_CURR CUR
                                 where CUR.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                                   and CUR.ACS_FINANCIAL_CURRENCY_ID = IMP.ACS_FINANCIAL_CURRENCY_ID) CURRENCY_ID
                          from ACJ_CATALOGUE_DOCUMENT CAT
                             , ACS_FINANCIAL_ACCOUNT FIN
                             , ACS_ACCOUNT ACC
                             , ACS_SUB_SET SUB
                             , ACJ_SUB_SET_CAT SCA
                             , ACT_ETAT_JOURNAL ETA
                             , ACT_DOCUMENT DOC
                             , ACT_FINANCIAL_IMPUTATION IMP
                         where IMP.IMF_ACS_FINANCIAL_YEAR_ID = pTreatedFinancialYearId
                           and FIN.ACS_FINANCIAL_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
                           and IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                           and CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
                           and CAT.ACJ_CATALOGUE_DOCUMENT_ID = SCA.ACJ_CATALOGUE_DOCUMENT_ID
                           and DOC.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
                           and ETA.C_SUB_SET = SCA.C_SUB_SET
                           and ETA.C_SUB_SET = 'ACC'
                           and ETA.C_ETAT_JOURNAL <> 'BRO'
                           and IMP.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                           and ACC.ACS_SUB_SET_ID = SUB.ACS_SUB_SET_ID
                           and SUB.SSE_TOTAL = 1)
              group by ACS_FINANCIAL_ACCOUNT_ID
                     , ACS_PERIOD_ID
                     , decode(nvl(CURRENCY_ID, 0) + FIN_COLLECTIVE
                            , 0, ACS_ACS_FINANCIAL_CURRENCY_ID
                            , ACS_FINANCIAL_CURRENCY_ID
                             )
                     , ACS_ACS_FINANCIAL_CURRENCY_ID
                     , IMF_ACS_DIVISION_ACCOUNT_ID
                     , C_TYPE_PERIOD
                     , C_TYPE_CUMUL);

    commit;
  end CalculateFinancialTotal;

  /**
  *  Mise à jour des cumuls de l'exercice donné sur la base des imputations de ce même exercice
  **/
  procedure CalculateAnalyticalTotal(pTreatedFinancialYearId in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
  is
    cursor AnalyticalImpCursor
    is
      select   ACS_PERIOD_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , ACS_QTY_UNIT_ID
             , DOC_RECORD_ID
             , sum(DIFLCD) DIFLCD
             , sum(DIFLCC) DIFLCC
             , sum(decode(nvl(CURRENCY_ID, 0), 0, 0, DIFFCD) ) DIFFCD
             , sum(decode(nvl(CURRENCY_ID, 0), 0, 0, DIFFCC) ) DIFFCC
             , sum(decode(nvl(CURRENCY_ID, 0), 0, 0, DIFEURD) ) DIFEURD
             , sum(decode(nvl(CURRENCY_ID, 0), 0, 0, DIFEURC) ) DIFEURC
             , sum(DIFQTYD) DIFQTYD
             , sum(DIFQTYC) DIFQTYC
             , sum(IMM_AMOUNT_LC_D) IMM_AMOUNT_LC_D
             , sum(IMM_AMOUNT_LC_C) IMM_AMOUNT_LC_C
             , sum(decode(nvl(CURRENCY_ID, 0), 0, 0, IMM_AMOUNT_FC_D) ) IMM_AMOUNT_FC_D
             , sum(decode(nvl(CURRENCY_ID, 0), 0, 0, IMM_AMOUNT_FC_C) ) IMM_AMOUNT_FC_C
             , sum(decode(nvl(CURRENCY_ID, 0), 0, 0, IMM_AMOUNT_EUR_D) ) IMM_AMOUNT_EUR_D
             , sum(decode(nvl(CURRENCY_ID, 0), 0, 0, IMM_AMOUNT_EUR_C) ) IMM_AMOUNT_EUR_C
             , sum(IMM_QUANTITY_D) IMM_QUANTITY_D
             , sum(IMM_QUANTITY_C) IMM_QUANTITY_C
             , sum(MGM_AMOUNT_LC_D) MGM_AMOUNT_LC_D
             , sum(MGM_AMOUNT_LC_C) MGM_AMOUNT_LC_C
             , sum(decode(nvl(CURRENCY_ID, 0), 0, 0, MGM_AMOUNT_FC_D) ) MGM_AMOUNT_FC_D
             , sum(decode(nvl(CURRENCY_ID, 0), 0, 0, MGM_AMOUNT_FC_C) ) MGM_AMOUNT_FC_C
             , sum(decode(nvl(CURRENCY_ID, 0), 0, 0, MGM_AMOUNT_EUR_D) ) MGM_AMOUNT_EUR_D
             , sum(decode(nvl(CURRENCY_ID, 0), 0, 0, MGM_AMOUNT_EUR_C) ) MGM_AMOUNT_EUR_C
             , sum(MGM_QUANTITY_D) MGM_QUANTITY_D
             , sum(MGM_QUANTITY_C) MGM_QUANTITY_C
             , ACS_ACS_FINANCIAL_CURRENCY_ID
             , decode(nvl(CURRENCY_ID, 0), 0, ACS_ACS_FINANCIAL_CURRENCY_ID, ACS_FINANCIAL_CURRENCY_ID)
                                                                                              ACS_FINANCIAL_CURRENCY_ID
             , C_TYPE_CUMUL
          from (select IMM.ACS_PERIOD_ID
                     , IMF.ACS_FINANCIAL_ACCOUNT_ID
                     , IMF.IMF_ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID
                     , IMM.ACS_CPN_ACCOUNT_ID
                     , IMM.ACS_CDA_ACCOUNT_ID
                     , IMM.ACS_PF_ACCOUNT_ID
                     , PJ.ACS_PJ_ACCOUNT_ID
                     , IMM.ACS_QTY_UNIT_ID
                     , IMM.DOC_RECORD_ID
                     , (nvl(IMM.IMM_AMOUNT_LC_D, 0) - nvl(MGM.MGM_AMOUNT_LC_D, 0) ) DIFLCD
                     , (nvl(IMM.IMM_AMOUNT_LC_C, 0) - nvl(MGM.MGM_AMOUNT_LC_C, 0) ) DIFLCC
                     , (nvl(IMM.IMM_AMOUNT_FC_D, 0) - nvl(MGM.MGM_AMOUNT_FC_D, 0) ) DIFFCD
                     , (nvl(IMM.IMM_AMOUNT_FC_C, 0) - nvl(MGM.MGM_AMOUNT_FC_C, 0) ) DIFFCC
                     , (nvl(IMM.IMM_AMOUNT_EUR_D, 0) - nvl(MGM.MGM_AMOUNT_EUR_D, 0) ) DIFEURD
                     , (nvl(IMM.IMM_AMOUNT_EUR_C, 0) - nvl(MGM.MGM_AMOUNT_EUR_C, 0) ) DIFEURC
                     , (nvl(IMM.IMM_QUANTITY_D, 0) - nvl(MGM.MGM_QUANTITY_D, 0) ) DIFQTYD
                     , (nvl(IMM.IMM_QUANTITY_C, 0) - nvl(MGM.MGM_QUANTITY_C, 0) ) DIFQTYC
                     , nvl(IMM.IMM_AMOUNT_LC_D, 0) IMM_AMOUNT_LC_D
                     , nvl(IMM.IMM_AMOUNT_LC_C, 0) IMM_AMOUNT_LC_C
                     , nvl(IMM.IMM_AMOUNT_FC_D, 0) IMM_AMOUNT_FC_D
                     , nvl(IMM.IMM_AMOUNT_FC_C, 0) IMM_AMOUNT_FC_C
                     , nvl(IMM.IMM_AMOUNT_EUR_D, 0) IMM_AMOUNT_EUR_D
                     , nvl(IMM.IMM_AMOUNT_EUR_C, 0) IMM_AMOUNT_EUR_C
                     , nvl(IMM.IMM_QUANTITY_D, 0) IMM_QUANTITY_D
                     , nvl(IMM.IMM_QUANTITY_C, 0) IMM_QUANTITY_C
                     , nvl(PJ.MGM_AMOUNT_LC_D, 0) MGM_AMOUNT_LC_D
                     , nvl(PJ.MGM_AMOUNT_LC_C, 0) MGM_AMOUNT_LC_C
                     , nvl(PJ.MGM_AMOUNT_FC_D, 0) MGM_AMOUNT_FC_D
                     , nvl(PJ.MGM_AMOUNT_FC_C, 0) MGM_AMOUNT_FC_C
                     , nvl(PJ.MGM_AMOUNT_EUR_D, 0) MGM_AMOUNT_EUR_D
                     , nvl(PJ.MGM_AMOUNT_EUR_C, 0) MGM_AMOUNT_EUR_C
                     , nvl(PJ.MGM_QUANTITY_D, 0) MGM_QUANTITY_D
                     , nvl(PJ.MGM_QUANTITY_C, 0) MGM_QUANTITY_C
                     , IMM.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , IMM.ACS_FINANCIAL_CURRENCY_ID
                     , SCA.C_TYPE_CUMUL
                     , (select ACS_FINANCIAL_CURRENCY_ID
                          from ACS_CPN_ACCOUNT_CURRENCY CUR
                         where CUR.ACS_CPN_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                           and CUR.ACS_FINANCIAL_CURRENCY_ID = IMM.ACS_FINANCIAL_CURRENCY_ID) CURRENCY_ID
                  from ACS_ACCOUNT ACC
                     , ACT_ETAT_JOURNAL ETA
                     , ACJ_CATALOGUE_DOCUMENT CAT
                     , ACJ_SUB_SET_CAT SCA
                     , ACT_JOB JOB
                     , ACT_DOCUMENT DOC
                     , ACT_FINANCIAL_IMPUTATION IMF
                     , ACT_MGM_IMPUTATION IMM
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
                 where JOB.ACS_FINANCIAL_YEAR_ID = pTreatedFinancialYearId
                   and DOC.ACT_JOB_ID = JOB.ACT_JOB_ID
                   and IMM.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
                   and IMF.ACT_FINANCIAL_IMPUTATION_ID(+) = IMM.ACT_FINANCIAL_IMPUTATION_ID
                   and MGM.ACT_MGM_IMPUTATION_ID(+) = IMM.ACT_MGM_IMPUTATION_ID
                   and PJ.ACT_MGM_IMPUTATION_ID(+) = IMM.ACT_MGM_IMPUTATION_ID
                   and CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
                   and SCA.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
                   and SCA.C_SUB_SET = 'CPN'
                   and ETA.C_SUB_SET = SCA.C_SUB_SET
                   and ETA.C_ETAT_JOURNAL <> 'BRO'
                   and ETA.ACT_JOURNAL_ID = DOC.ACT_ACT_JOURNAL_ID
                   and ACC.ACS_ACCOUNT_ID = IMM.ACS_CPN_ACCOUNT_ID)
      group by ACS_PERIOD_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_DIVISION_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , ACS_QTY_UNIT_ID
             , DOC_RECORD_ID
             , ACS_ACS_FINANCIAL_CURRENCY_ID
             , decode(nvl(CURRENCY_ID, 0), 0, ACS_ACS_FINANCIAL_CURRENCY_ID, ACS_FINANCIAL_CURRENCY_ID)
             , C_TYPE_CUMUL
      order by ACS_PERIOD_ID
             , ACS_FINANCIAL_ACCOUNT_ID
             , ACS_CPN_ACCOUNT_ID
             , ACS_CDA_ACCOUNT_ID
             , ACS_PF_ACCOUNT_ID
             , ACS_PJ_ACCOUNT_ID
             , ACS_QTY_UNIT_ID
             , DOC_RECORD_ID
             , ACS_ACS_FINANCIAL_CURRENCY_ID;

    vAnalyticalImpCursor AnalyticalImpCursor%rowtype;
    lRecordId            ACT_MGM_TOT_BY_PERIOD.ACT_MGM_TOT_BY_PERIOD_id%type;
  begin
    open AnalyticalImpCursor;

    fetch AnalyticalImpCursor
     into vAnalyticalImpCursor;

    while AnalyticalImpCursor%found loop
      lRecordId  := 0;

      /* écritures sans distribution PJ */
      if vAnalyticalImpCursor.ACS_PJ_ACCOUNT_ID is null then
        ACT_PRC_MGM_TOT_BY_PERIOD.CreateMgmTotPosition(lRecordId
                                                     , vAnalyticalImpCursor.ACS_PERIOD_ID
                                                     , vAnalyticalImpCursor.ACS_FINANCIAL_ACCOUNT_ID
                                                     , vAnalyticalImpCursor.ACS_DIVISION_ACCOUNT_ID
                                                     , vAnalyticalImpCursor.ACS_CPN_ACCOUNT_ID
                                                     , vAnalyticalImpCursor.ACS_CDA_ACCOUNT_ID
                                                     , vAnalyticalImpCursor.ACS_PF_ACCOUNT_ID
                                                     , vAnalyticalImpCursor.ACS_PJ_ACCOUNT_ID
                                                     , vAnalyticalImpCursor.ACS_QTY_UNIT_ID
                                                     , vAnalyticalImpCursor.DOC_RECORD_ID
                                                     , vAnalyticalImpCursor.IMM_AMOUNT_LC_D
                                                     , vAnalyticalImpCursor.IMM_AMOUNT_LC_C
                                                     , vAnalyticalImpCursor.IMM_AMOUNT_FC_D
                                                     , vAnalyticalImpCursor.IMM_AMOUNT_FC_C
                                                     , vAnalyticalImpCursor.IMM_AMOUNT_EUR_D
                                                     , vAnalyticalImpCursor.IMM_AMOUNT_EUR_C
                                                     , vAnalyticalImpCursor.IMM_QUANTITY_D
                                                     , vAnalyticalImpCursor.IMM_QUANTITY_C
                                                     , vAnalyticalImpCursor.ACS_FINANCIAL_CURRENCY_ID
                                                     , vAnalyticalImpCursor.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                     , vAnalyticalImpCursor.C_TYPE_CUMUL
                                                     , 2
                                                      );
      else
        /* écritures avec distribution PJ totale */
        if     (vAnalyticalImpCursor.DIFLCD = 0)
           and (vAnalyticalImpCursor.DIFLCC = 0)
           and (vAnalyticalImpCursor.DIFFCD = 0)
           and (vAnalyticalImpCursor.DIFFCC = 0)
           and (vAnalyticalImpCursor.DIFEURD = 0)
           and (vAnalyticalImpCursor.DIFEURC = 0)
           and (vAnalyticalImpCursor.DIFQTYD = 0)
           and (vAnalyticalImpCursor.DIFQTYC = 0) then
          ACT_PRC_MGM_TOT_BY_PERIOD.CreateMgmTotPosition(lRecordId
                                                       , vAnalyticalImpCursor.ACS_PERIOD_ID
                                                       , vAnalyticalImpCursor.ACS_FINANCIAL_ACCOUNT_ID
                                                       , vAnalyticalImpCursor.ACS_DIVISION_ACCOUNT_ID
                                                       , vAnalyticalImpCursor.ACS_CPN_ACCOUNT_ID
                                                       , vAnalyticalImpCursor.ACS_CDA_ACCOUNT_ID
                                                       , vAnalyticalImpCursor.ACS_PF_ACCOUNT_ID
                                                       , vAnalyticalImpCursor.ACS_PJ_ACCOUNT_ID
                                                       , vAnalyticalImpCursor.ACS_QTY_UNIT_ID
                                                       , vAnalyticalImpCursor.DOC_RECORD_ID
                                                       , vAnalyticalImpCursor.MGM_AMOUNT_LC_D
                                                       , vAnalyticalImpCursor.MGM_AMOUNT_LC_C
                                                       , vAnalyticalImpCursor.MGM_AMOUNT_FC_D
                                                       , vAnalyticalImpCursor.MGM_AMOUNT_FC_C
                                                       , vAnalyticalImpCursor.MGM_AMOUNT_EUR_D
                                                       , vAnalyticalImpCursor.MGM_AMOUNT_EUR_C
                                                       , vAnalyticalImpCursor.MGM_QUANTITY_D
                                                       , vAnalyticalImpCursor.MGM_QUANTITY_C
                                                       , vAnalyticalImpCursor.ACS_FINANCIAL_CURRENCY_ID
                                                       , vAnalyticalImpCursor.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                       , vAnalyticalImpCursor.C_TYPE_CUMUL
                                                       , 2
                                                        );
        else     /* écritures avec distribution PJ partielle */
               /* Une première écriture avec les montants PJ et compte PJ */
          ACT_PRC_MGM_TOT_BY_PERIOD.CreateMgmTotPosition(lRecordId
                                                       , vAnalyticalImpCursor.ACS_PERIOD_ID
                                                       , vAnalyticalImpCursor.ACS_FINANCIAL_ACCOUNT_ID
                                                       , vAnalyticalImpCursor.ACS_DIVISION_ACCOUNT_ID
                                                       , vAnalyticalImpCursor.ACS_CPN_ACCOUNT_ID
                                                       , vAnalyticalImpCursor.ACS_CDA_ACCOUNT_ID
                                                       , vAnalyticalImpCursor.ACS_PF_ACCOUNT_ID
                                                       , vAnalyticalImpCursor.ACS_PJ_ACCOUNT_ID
                                                       , vAnalyticalImpCursor.ACS_QTY_UNIT_ID
                                                       , vAnalyticalImpCursor.DOC_RECORD_ID
                                                       , vAnalyticalImpCursor.MGM_AMOUNT_LC_D
                                                       , vAnalyticalImpCursor.MGM_AMOUNT_LC_C
                                                       , vAnalyticalImpCursor.MGM_AMOUNT_FC_D
                                                       , vAnalyticalImpCursor.MGM_AMOUNT_FC_C
                                                       , vAnalyticalImpCursor.MGM_AMOUNT_EUR_D
                                                       , vAnalyticalImpCursor.MGM_AMOUNT_EUR_C
                                                       , vAnalyticalImpCursor.MGM_QUANTITY_D
                                                       , vAnalyticalImpCursor.MGM_QUANTITY_C
                                                       , vAnalyticalImpCursor.ACS_FINANCIAL_CURRENCY_ID
                                                       , vAnalyticalImpCursor.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                       , vAnalyticalImpCursor.C_TYPE_CUMUL
                                                       , 2
                                                        );
          lRecordId  := 0;
          /* Une deuxième écriture avec les montants de différence et sans compte PJ */
          ACT_PRC_MGM_TOT_BY_PERIOD.CreateMgmTotPosition(lRecordId
                                                       , vAnalyticalImpCursor.ACS_PERIOD_ID
                                                       , vAnalyticalImpCursor.ACS_FINANCIAL_ACCOUNT_ID
                                                       , vAnalyticalImpCursor.ACS_DIVISION_ACCOUNT_ID
                                                       , vAnalyticalImpCursor.ACS_CPN_ACCOUNT_ID
                                                       , vAnalyticalImpCursor.ACS_CDA_ACCOUNT_ID
                                                       , vAnalyticalImpCursor.ACS_PF_ACCOUNT_ID
                                                       , vAnalyticalImpCursor.ACS_PJ_ACCOUNT_ID
                                                       , vAnalyticalImpCursor.ACS_QTY_UNIT_ID
                                                       , vAnalyticalImpCursor.DOC_RECORD_ID
                                                       , vAnalyticalImpCursor.DIFLCD
                                                       , vAnalyticalImpCursor.DIFLCC
                                                       , vAnalyticalImpCursor.DIFFCD
                                                       , vAnalyticalImpCursor.DIFFCC
                                                       , vAnalyticalImpCursor.DIFEURD
                                                       , vAnalyticalImpCursor.DIFEURC
                                                       , vAnalyticalImpCursor.DIFQTYD
                                                       , vAnalyticalImpCursor.DIFQTYC
                                                       , vAnalyticalImpCursor.ACS_FINANCIAL_CURRENCY_ID
                                                       , vAnalyticalImpCursor.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                       , vAnalyticalImpCursor.C_TYPE_CUMUL
                                                       , 2
                                                        );
        end if;
      end if;

      fetch AnalyticalImpCursor
       into vAnalyticalImpCursor;
    end loop;

    close AnalyticalImpCursor;
  end CalculateAnalyticalTotal;

  /**
  *  Mise à jour des cumuls financier de l'exercice donné sur la base des positions déjà créées regroupées par division
  **/
  procedure CreateDivGroupedPositions(pTreatedFinancialYearId in ACS_FINANCIAL_YEAR.ACS_FINANCIAL_YEAR_ID%type)
  is
  begin
    insert into ACT_TOTAL_BY_PERIOD
                (ACT_TOTAL_BY_PERIOD_ID
               , ACS_PERIOD_ID
               , TOT_DEBIT_LC
               , TOT_CREDIT_LC
               , TOT_DEBIT_FC
               , TOT_CREDIT_FC
               , TOT_DEBIT_EUR
               , TOT_CREDIT_EUR
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_AUXILIARY_ACCOUNT_ID
               , ACS_FINANCIAL_CURRENCY_ID
               , ACS_ACS_FINANCIAL_CURRENCY_ID
               , C_TYPE_PERIOD
               , C_TYPE_CUMUL
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval
           , ACS_PERIOD_ID
           , TOT_DEBIT_LC
           , TOT_CREDIT_LC
           , TOT_DEBIT_FC
           , TOT_CREDIT_FC
           , TOT_DEBIT_EUR
           , TOT_CREDIT_EUR
           , ACS_FINANCIAL_ACCOUNT_ID
           , ACS_AUXILIARY_ACCOUNT_ID
           , ACS_FINANCIAL_CURRENCY_ID
           , ACS_ACS_FINANCIAL_CURRENCY_ID
           , C_TYPE_PERIOD
           , C_TYPE_CUMUL
           , sysdate
           , UserIni
        from (select   TOT.ACS_PERIOD_ID
                     , sum(nvl(TOT.TOT_DEBIT_LC, 0) ) TOT_DEBIT_LC
                     , sum(nvl(TOT.TOT_CREDIT_LC, 0) ) TOT_CREDIT_LC
                     , sum(nvl(TOT.TOT_DEBIT_FC, 0) ) TOT_DEBIT_FC
                     , sum(nvl(TOT.TOT_CREDIT_FC, 0) ) TOT_CREDIT_FC
                     , sum(nvl(TOT.TOT_DEBIT_EUR, 0) ) TOT_DEBIT_EUR
                     , sum(nvl(TOT.TOT_CREDIT_EUR, 0) ) TOT_CREDIT_EUR
                     , TOT.ACS_FINANCIAL_ACCOUNT_ID
                     , TOT.ACS_AUXILIARY_ACCOUNT_ID
                     , TOT.ACS_FINANCIAL_CURRENCY_ID
                     , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , TOT.C_TYPE_PERIOD
                     , TOT.C_TYPE_CUMUL
                  from ACT_TOTAL_BY_PERIOD TOT
                     , ACS_PERIOD PER
                 where PER.ACS_FINANCIAL_YEAR_ID = pTreatedFinancialYearId
                   and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
              group by TOT.ACS_FINANCIAL_ACCOUNT_ID
                     , TOT.ACS_AUXILIARY_ACCOUNT_ID
                     , TOT.ACS_PERIOD_ID
                     , TOT.ACS_FINANCIAL_CURRENCY_ID
                     , TOT.ACS_ACS_FINANCIAL_CURRENCY_ID
                     , TOT.C_TYPE_PERIOD
                     , TOT.C_TYPE_CUMUL);

    commit;
  end CreateDivGroupedPositions;
begin
  UserIni  := PCS.PC_I_LIB_SESSION.GetUserIni;
end ACT_YEAR_TOTAL_CALCULATION;
