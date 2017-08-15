--------------------------------------------------------
--  DDL for Package Body DOC_IMPUTATION_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_IMPUTATION_FUNCTIONS" 
is
  /**
  * Description
  *    Insère dans la table d'imputation des positions
  */
  procedure insertPositionImputation(aTplPositionImputation in DOC_POSITION_IMPUTATION%rowtype, aSimulation in number)
  is
  begin
    if aSimulation = 0 then
      insert into DOC_POSITION_IMPUTATION
                  (DOC_POSITION_IMPUTATION_ID
                 , DOC_DOCUMENT_ID
                 , DOC_POSITION_ID
                 , DOC_POSITION_CHARGE_ID
                 , DOC_FOOT_CHARGE_ID
                 , DOC_RECORD_ID
                 , POI_RATIO
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , ACS_DIVISION_ACCOUNT_ID
                 , ACS_PJ_ACCOUNT_ID
                 , ACS_PF_ACCOUNT_ID
                 , ACS_CDA_ACCOUNT_ID
                 , ACS_CPN_ACCOUNT_ID
                 , DIC_IMP_FREE1_ID
                 , DIC_IMP_FREE2_ID
                 , DIC_IMP_FREE3_ID
                 , DIC_IMP_FREE4_ID
                 , DIC_IMP_FREE5_ID
                 , POI_IMF_NUMBER_1
                 , POI_IMF_NUMBER_2
                 , POI_IMF_NUMBER_3
                 , POI_IMF_NUMBER_4
                 , POI_IMF_NUMBER_5
                 , POI_IMF_TEXT_1
                 , POI_IMF_TEXT_2
                 , POI_IMF_TEXT_3
                 , POI_IMF_TEXT_4
                 , POI_IMF_TEXT_5
                 , POI_IMF_DATE_1
                 , POI_IMF_DATE_2
                 , POI_IMF_DATE_3
                 , POI_IMF_DATE_4
                 , POI_IMF_DATE_5
                 , C_FAM_TRANSACTION_TYP
                 , FAM_FIXED_ASSETS_ID
                 , HRM_PERSON_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (nvl(aTplPositionImputation.DOC_POSITION_IMPUTATION_ID, INIT_ID_SEQ.nextval)   -- DOC_POSITION_IMPUTATION_ID
                 , aTplPositionImputation.DOC_DOCUMENT_ID   -- DOC_DOCUMENT_ID
                 , aTplPositionImputation.DOC_POSITION_ID   -- DOC_POSITION_ID
                 , aTplPositionImputation.DOC_POSITION_CHARGE_ID   -- DOC_POSITION_CHARGE_ID
                 , aTplPositionImputation.DOC_FOOT_CHARGE_ID   -- DOC_FOOT_CHARGE_ID
                 , aTplPositionImputation.DOC_RECORD_ID   -- DOC_RECORD_ID
                 , aTplPositionImputation.POI_RATIO   -- POI_RATIO
                 , aTplPositionImputation.ACS_FINANCIAL_ACCOUNT_ID   -- ACS_FINANCIAL_ACCOUNT_ID
                 , aTplPositionImputation.ACS_DIVISION_ACCOUNT_ID   -- ACS_DIVISION_ACCOUNT_ID
                 , aTplPositionImputation.ACS_PJ_ACCOUNT_ID   -- ACS_PJ_ACCOUNT_ID
                 , aTplPositionImputation.ACS_PF_ACCOUNT_ID   -- ACS_PF_ACCOUNT_ID
                 , aTplPositionImputation.ACS_CDA_ACCOUNT_ID   -- ACS_CDA_ACCOUNT_ID
                 , aTplPositionImputation.ACS_CPN_ACCOUNT_ID   -- ACS_CPN_ACCOUNT_ID
                 , aTplPositionImputation.DIC_IMP_FREE1_ID   -- DIC_IMP_FREE1_ID
                 , aTplPositionImputation.DIC_IMP_FREE2_ID   -- DIC_IMP_FREE2_ID
                 , aTplPositionImputation.DIC_IMP_FREE3_ID   -- DIC_IMP_FREE3_ID
                 , aTplPositionImputation.DIC_IMP_FREE4_ID   -- DIC_IMP_FREE4_ID
                 , aTplPositionImputation.DIC_IMP_FREE5_ID   -- DIC_IMP_FREE5_ID
                 , aTplPositionImputation.POI_IMF_NUMBER_1   -- POI_IMF_NUMBER_1
                 , aTplPositionImputation.POI_IMF_NUMBER_2   -- POI_IMF_NUMBER_2
                 , aTplPositionImputation.POI_IMF_NUMBER_3   -- POI_IMF_NUMBER_3
                 , aTplPositionImputation.POI_IMF_NUMBER_4   -- POI_IMF_NUMBER_4
                 , aTplPositionImputation.POI_IMF_NUMBER_5   -- POI_IMF_NUMBER_5
                 , aTplPositionImputation.POI_IMF_TEXT_1   -- POI_IMF_TEXT_1
                 , aTplPositionImputation.POI_IMF_TEXT_2   -- POI_IMF_TEXT_2
                 , aTplPositionImputation.POI_IMF_TEXT_3   -- POI_IMF_TEXT_3
                 , aTplPositionImputation.POI_IMF_TEXT_4   -- POI_IMF_TEXT_4
                 , aTplPositionImputation.POI_IMF_TEXT_5   -- POI_IMF_TEXT_5
                 , aTplPositionImputation.POI_IMF_DATE_1   -- POI_IMF_DATE_1
                 , aTplPositionImputation.POI_IMF_DATE_2   -- POI_IMF_DATE_2
                 , aTplPositionImputation.POI_IMF_DATE_3   -- POI_IMF_DATE_3
                 , aTplPositionImputation.POI_IMF_DATE_4   -- POI_IMF_DATE_4
                 , aTplPositionImputation.POI_IMF_DATE_5   -- POI_IMF_DATE_5
                 , aTplPositionImputation.C_FAM_TRANSACTION_TYP   -- C_FAM_TRANSACTION_TYP
                 , aTplPositionImputation.FAM_FIXED_ASSETS_ID   -- FAM_FIXED_ASSETS_ID
                 , aTplPositionImputation.HRM_PERSON_ID   -- HRM_PERSON_ID
                 , aTplPositionImputation.A_DATECRE   -- A_DATECRE
                 , aTplPositionImputation.A_IDCRE   -- A_IDCRE
                  );
    else   -- DOC_EST_POS_IMP_CASH_FLOW
      insert into DOC_EST_POS_IMP_CASH_FLOW
                  (DOC_POSITION_IMPUTATION_ID
                 , DOC_DOCUMENT_ID
                 , DOC_POSITION_ID
                 , DOC_POSITION_CHARGE_ID
                 , DOC_FOOT_CHARGE_ID
                 , DOC_RECORD_ID
                 , POI_RATIO
                 , ACS_FINANCIAL_ACCOUNT_ID
                 , ACS_DIVISION_ACCOUNT_ID
                 , ACS_PJ_ACCOUNT_ID
                 , ACS_PF_ACCOUNT_ID
                 , ACS_CDA_ACCOUNT_ID
                 , ACS_CPN_ACCOUNT_ID
                 , DIC_IMP_FREE1_ID
                 , DIC_IMP_FREE2_ID
                 , DIC_IMP_FREE3_ID
                 , DIC_IMP_FREE4_ID
                 , DIC_IMP_FREE5_ID
                 , POI_IMF_NUMBER_1
                 , POI_IMF_NUMBER_2
                 , POI_IMF_NUMBER_3
                 , POI_IMF_NUMBER_4
                 , POI_IMF_NUMBER_5
                 , POI_IMF_TEXT_1
                 , POI_IMF_TEXT_2
                 , POI_IMF_TEXT_3
                 , POI_IMF_TEXT_4
                 , POI_IMF_TEXT_5
                 , POI_IMF_DATE_1
                 , POI_IMF_DATE_2
                 , POI_IMF_DATE_3
                 , POI_IMF_DATE_4
                 , POI_IMF_DATE_5
                 , C_FAM_TRANSACTION_TYP
                 , FAM_FIXED_ASSETS_ID
                 , HRM_PERSON_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (nvl(aTplPositionImputation.DOC_POSITION_IMPUTATION_ID, INIT_ID_SEQ.nextval)   -- DOC_POSITION_IMPUTATION_ID
                 , aTplPositionImputation.DOC_DOCUMENT_ID   -- DOC_DOCUMENT_ID
                 , aTplPositionImputation.DOC_POSITION_ID   -- DOC_POSITION_ID
                 , aTplPositionImputation.DOC_POSITION_CHARGE_ID   -- DOC_POSITION_CHARGE_ID
                 , aTplPositionImputation.DOC_FOOT_CHARGE_ID   -- DOC_FOOT_CHARGE_ID
                 , aTplPositionImputation.DOC_RECORD_ID   -- DOC_RECORD_ID
                 , aTplPositionImputation.POI_RATIO   -- POI_RATIO
                 , aTplPositionImputation.ACS_FINANCIAL_ACCOUNT_ID   -- ACS_FINANCIAL_ACCOUNT_ID
                 , aTplPositionImputation.ACS_DIVISION_ACCOUNT_ID   -- ACS_DIVISION_ACCOUNT_ID
                 , aTplPositionImputation.ACS_PJ_ACCOUNT_ID   -- ACS_PJ_ACCOUNT_ID
                 , aTplPositionImputation.ACS_PF_ACCOUNT_ID   -- ACS_PF_ACCOUNT_ID
                 , aTplPositionImputation.ACS_CDA_ACCOUNT_ID   -- ACS_CDA_ACCOUNT_ID
                 , aTplPositionImputation.ACS_CPN_ACCOUNT_ID   -- ACS_CPN_ACCOUNT_ID
                 , aTplPositionImputation.DIC_IMP_FREE1_ID   -- DIC_IMP_FREE1_ID
                 , aTplPositionImputation.DIC_IMP_FREE2_ID   -- DIC_IMP_FREE2_ID
                 , aTplPositionImputation.DIC_IMP_FREE3_ID   -- DIC_IMP_FREE3_ID
                 , aTplPositionImputation.DIC_IMP_FREE4_ID   -- DIC_IMP_FREE4_ID
                 , aTplPositionImputation.DIC_IMP_FREE5_ID   -- DIC_IMP_FREE5_ID
                 , aTplPositionImputation.POI_IMF_NUMBER_1   -- POI_IMF_NUMBER_1
                 , aTplPositionImputation.POI_IMF_NUMBER_2   -- POI_IMF_NUMBER_2
                 , aTplPositionImputation.POI_IMF_NUMBER_3   -- POI_IMF_NUMBER_3
                 , aTplPositionImputation.POI_IMF_NUMBER_4   -- POI_IMF_NUMBER_4
                 , aTplPositionImputation.POI_IMF_NUMBER_5   -- POI_IMF_NUMBER_5
                 , aTplPositionImputation.POI_IMF_TEXT_1   -- POI_IMF_TEXT_1
                 , aTplPositionImputation.POI_IMF_TEXT_2   -- POI_IMF_TEXT_2
                 , aTplPositionImputation.POI_IMF_TEXT_3   -- POI_IMF_TEXT_3
                 , aTplPositionImputation.POI_IMF_TEXT_4   -- POI_IMF_TEXT_4
                 , aTplPositionImputation.POI_IMF_TEXT_5   -- POI_IMF_TEXT_5
                 , aTplPositionImputation.POI_IMF_DATE_1   -- POI_IMF_DATE_1
                 , aTplPositionImputation.POI_IMF_DATE_2   -- POI_IMF_DATE_2
                 , aTplPositionImputation.POI_IMF_DATE_3   -- POI_IMF_DATE_3
                 , aTplPositionImputation.POI_IMF_DATE_4   -- POI_IMF_DATE_4
                 , aTplPositionImputation.POI_IMF_DATE_5   -- POI_IMF_DATE_5
                 , aTplPositionImputation.C_FAM_TRANSACTION_TYP   -- C_FAM_TRANSACTION_TYP
                 , aTplPositionImputation.FAM_FIXED_ASSETS_ID   -- FAM_FIXED_ASSETS_ID
                 , aTplPositionImputation.HRM_PERSON_ID   -- HRM_PERSON_ID
                 , aTplPositionImputation.A_DATECRE   -- A_DATECRE
                 , aTplPositionImputation.A_IDCRE   -- A_IDCRE
                  );
    end if;
  end insertPositionImputation;

  /**
  * Description
  *    Fonction de répartition du montant d'une position
  */
  procedure imputePosition(
    aPositionId          DOC_POSITION.DOC_POSITION_ID%type
  , aPositionAmount      DOC_POSITION.POS_GROSS_VALUE%type default null
  , aPositionAmountB     DOC_POSITION.POS_GROSS_VALUE_B%type default null
  , aPositionAmountE     DOC_POSITION.POS_GROSS_VALUE_E%type default null
  , aPositionAmountV     DOC_POSITION.POS_GROSS_VALUE_V%type default null
  , aPositionAmountIncl  DOC_POSITION.POS_GROSS_VALUE_INCL%type default null
  , aPositionAmountInclB DOC_POSITION.POS_GROSS_VALUE_INCL_B%type default null
  , aPositionAmountInclE DOC_POSITION.POS_GROSS_VALUE_INCL_E%type default null
  , aPositionAmountInclV DOC_POSITION.POS_GROSS_VALUE_INCL_V%type default null
  , aIncludeTaxTariff    DOC_POSITION.POS_INCLUDE_TAX_TARIFF%type default null
  , aRoundType           varchar2 default '0'
  , aRoundAmount         number default 0
  )
  is
    vPositionAmount  DOC_POSITION.POS_GROSS_VALUE%type;
    vPositionAmountB DOC_POSITION.POS_GROSS_VALUE_B%type;
    vPositionAmountE DOC_POSITION.POS_GROSS_VALUE_E%type;
    vPositionAmountV DOC_POSITION.POS_GROSS_VALUE_V%type;
    vCumulAmount     DOC_POSITION.POS_GROSS_VALUE%type                         := 0;
    vCumulAmountB    DOC_POSITION.POS_GROSS_VALUE_B%type                       := 0;
    vCumulAmountE    DOC_POSITION.POS_GROSS_VALUE_E%type                       := 0;
    vCumulAmountV    DOC_POSITION.POS_GROSS_VALUE_V%type                       := 0;
    vTotRatio        DOC_POSITION_IMPUTATION.POI_RATIO%type;
    vBigImpId        DOC_POSITION_IMPUTATION.DOC_POSITION_IMPUTATION_ID%type;
  begin
    -- recherche montants de la position pour autant que les informations de la position ne soient pas passés en
    -- paramètre.
    if aPositionAmount is null then
      select decode(POS.POS_INCLUDE_TAX_TARIFF, 0, POS.POS_GROSS_VALUE, POS.POS_GROSS_VALUE_INCL)
           , decode(POS.POS_INCLUDE_TAX_TARIFF, 0, POS.POS_GROSS_VALUE_B, POS.POS_GROSS_VALUE_INCL_B)
           , decode(POS.POS_INCLUDE_TAX_TARIFF, 0, POS.POS_GROSS_VALUE_E, POS.POS_GROSS_VALUE_INCL_E)
           , decode(POS.POS_INCLUDE_TAX_TARIFF, 0, POS.POS_GROSS_VALUE_V, POS.POS_GROSS_VALUE_INCL_V)
        into vPositionAmount
           , vPositionAmountB
           , vPositionAmountE
           , vPositionAmountV
        from DOC_POSITION POS
       where DOC_POSITION_ID = aPositionId;
    else
      -- Utilisation des paramètres d'entrée. Appel à partir d'un trigger sur la table DOC_POSITION.
      select decode(aIncludeTaxTariff, 0, aPositionAmount, aPositionAmountIncl)
           , decode(aIncludeTaxTariff, 0, aPositionAmountB, aPositionAmountInclB)
           , decode(aIncludeTaxTariff, 0, aPositionAmountE, aPositionAmountInclE)
           , decode(aIncludeTaxTariff, 0, aPositionAmountV, aPositionAmountInclV)
        into vPositionAmount
           , vPositionAmountB
           , vPositionAmountE
           , vPositionAmountV
        from dual;
    end if;

    -- Vérifie, si on doit faire un arrondi, que le montant à répartir soit lui-même arrondi.
    if     aRoundType <> '0'
       and ACS_FUNCTION.PcsRound(vPositionAmount, aRoundType, aRoundAmount) <> vPositionAmount then
      raise_application_error(-20000, PCS.PC_FUNCTIONS.TranslateWord('PCS - Le montant de la position doit être arrondi') );
    end if;

    -- Recherche du ratio total
    select sum(POI_RATIO)
      into vTotRatio
      from DOC_POSITION_IMPUTATION
     where DOC_POSITION_Id = aPositionId;

    -- pour chaque imputation
    for tplImputation in (select   POI_RATIO
                                 , DOC_POSITION_IMPUTATION_ID
                              from DOC_POSITION_IMPUTATION
                             where DOC_POSITION_ID = aPositionId
                          order by POI_RATIO) loop
      -- maj du montant de l'imputation (les montants dans les autres monnaies sont mis à jour par trigger
      update DOC_POSITION_IMPUTATION
         set POI_AMOUNT = decode(vTotRatio, 0, 0, ACS_FUNCTION.PcsRound(vPositionAmount * tplImputation.POI_RATIO / vTotRatio, aRoundType, aRoundAmount) )
       where DOC_POSITION_IMPUTATION_ID = tplImputation.DOC_POSITION_IMPUTATION_ID;

      vBigImpId  := tplImputation.DOC_POSITION_IMPUTATION_ID;
    end loop;

    -- recherche des montants cumulés des imputations
    select sum(POI_AMOUNT)
         , sum(POI_AMOUNT_B)
         , sum(POI_AMOUNT_E)
         , sum(POI_AMOUNT_V)
      into vCumulAmount
         , vCumulAmountB
         , vCumulAmountE
         , vCumulAmountV
      from DOC_POSITION_IMPUTATION
     where DOC_POSITION_Id = aPositionId;

    -- mise à jour des différence d'arrondi
    update DOC_POSITION_IMPUTATION
       set POI_AMOUNT = POI_AMOUNT -(vCumulAmount - vPositionAmount)
         , POI_AMOUNT_B = POI_AMOUNT_B -(vCumulAmountB - vPositionAmountB)
         , POI_AMOUNT_E = POI_AMOUNT_E -(vCumulAmountE - vPositionAmountE)
         , POI_AMOUNT_V = POI_AMOUNT_V -(vCumulAmountV - vPositionAmountV)
     where DOC_POSITION_IMPUTATION_ID = vBigImpId;
  end imputePosition;

  /**
  * Description
  *    Fonction de répartition du montant d'une position
  */
  procedure imputeEstimatedPosition(
    aPositionId          DOC_ESTIMATED_POS_CASH_FLOW.DOC_POSITION_ID%type
  , aPositionAmount      DOC_ESTIMATED_POS_CASH_FLOW.POS_GROSS_VALUE%type default null
  , aPositionAmountB     DOC_ESTIMATED_POS_CASH_FLOW.POS_GROSS_VALUE_B%type default null
  , aPositionAmountE     DOC_ESTIMATED_POS_CASH_FLOW.POS_GROSS_VALUE_E%type default null
  , aPositionAmountV     DOC_ESTIMATED_POS_CASH_FLOW.POS_GROSS_VALUE_V%type default null
  , aPositionAmountIncl  DOC_ESTIMATED_POS_CASH_FLOW.POS_GROSS_VALUE_INCL%type default null
  , aPositionAmountInclB DOC_ESTIMATED_POS_CASH_FLOW.POS_GROSS_VALUE_INCL_B%type default null
  , aPositionAmountInclE DOC_ESTIMATED_POS_CASH_FLOW.POS_GROSS_VALUE_INCL_E%type default null
  , aPositionAmountInclV DOC_ESTIMATED_POS_CASH_FLOW.POS_GROSS_VALUE_INCL_V%type default null
  , aIncludeTaxTariff    DOC_ESTIMATED_POS_CASH_FLOW.POS_INCLUDE_TAX_TARIFF%type default null
  , aRoundType           varchar2 default '0'
  , aRoundAmount         number default 0
  )
  is
    vPositionAmount  DOC_ESTIMATED_POS_CASH_FLOW.POS_GROSS_VALUE%type;
    vPositionAmountB DOC_ESTIMATED_POS_CASH_FLOW.POS_GROSS_VALUE_B%type;
    vPositionAmountE DOC_ESTIMATED_POS_CASH_FLOW.POS_GROSS_VALUE_E%type;
    vPositionAmountV DOC_ESTIMATED_POS_CASH_FLOW.POS_GROSS_VALUE_V%type;
    vCumulAmount     DOC_ESTIMATED_POS_CASH_FLOW.POS_GROSS_VALUE%type            := 0;
    vCumulAmountB    DOC_ESTIMATED_POS_CASH_FLOW.POS_GROSS_VALUE_B%type          := 0;
    vCumulAmountE    DOC_ESTIMATED_POS_CASH_FLOW.POS_GROSS_VALUE_E%type          := 0;
    vCumulAmountV    DOC_ESTIMATED_POS_CASH_FLOW.POS_GROSS_VALUE_V%type          := 0;
    vTotRatio        DOC_EST_POS_IMP_CASH_FLOW.POI_RATIO%type;
    vBigImpId        DOC_EST_POS_IMP_CASH_FLOW.DOC_POSITION_IMPUTATION_ID%type;
  begin
    -- recherche montants de la position pour autant que les informations de la position ne soient pas passés en
    -- paramètre.
    if aPositionAmount is null then
      select decode(POS.POS_INCLUDE_TAX_TARIFF, 0, POS.POS_GROSS_VALUE, POS.POS_GROSS_VALUE_INCL)
           , decode(POS.POS_INCLUDE_TAX_TARIFF, 0, POS.POS_GROSS_VALUE_B, POS.POS_GROSS_VALUE_INCL_B)
           , decode(POS.POS_INCLUDE_TAX_TARIFF, 0, POS.POS_GROSS_VALUE_E, POS.POS_GROSS_VALUE_INCL_E)
           , decode(POS.POS_INCLUDE_TAX_TARIFF, 0, POS.POS_GROSS_VALUE_V, POS.POS_GROSS_VALUE_INCL_V)
        into vPositionAmount
           , vPositionAmountB
           , vPositionAmountE
           , vPositionAmountV
        from DOC_ESTIMATED_POS_CASH_FLOW POS
       where DOC_POSITION_ID = aPositionId;
    else
      -- Utilisation des paramètres d'entrée. Appel à partir d'un trigger sur la table DOC_POSITION.
      select decode(aIncludeTaxTariff, 0, aPositionAmount, aPositionAmountIncl)
           , decode(aIncludeTaxTariff, 0, aPositionAmountB, aPositionAmountInclB)
           , decode(aIncludeTaxTariff, 0, aPositionAmountE, aPositionAmountInclE)
           , decode(aIncludeTaxTariff, 0, aPositionAmountV, aPositionAmountInclV)
        into vPositionAmount
           , vPositionAmountB
           , vPositionAmountE
           , vPositionAmountV
        from dual;
    end if;

    -- Vérifie, si on doit faire un arrondi, que le montant à répartir soit lui-même arrondi.
    if     aRoundType <> '0'
       and ACS_FUNCTION.PcsRound(vPositionAmount, aRoundType, aRoundAmount) <> vPositionAmount then
      raise_application_error(-20000, PCS.PC_FUNCTIONS.TranslateWord('PCS - Le montant de la position doit être arrondi') );
    end if;

    -- Recherche du ratio total
    select sum(POI_RATIO)
      into vTotRatio
      from DOC_EST_POS_IMP_CASH_FLOW
     where DOC_POSITION_ID = aPositionId;

    -- pour chaque imputation
    for tplImputation in (select   POI_RATIO
                                 , DOC_POSITION_IMPUTATION_ID
                              from DOC_EST_POS_IMP_CASH_FLOW
                             where DOC_POSITION_ID = aPositionId
                          order by POI_RATIO) loop
      -- maj du montant de l'imputation (les montants dans les autres monnaies sont mis à jour par trigger
      update DOC_EST_POS_IMP_CASH_FLOW
         set POI_AMOUNT = decode(vTotRatio, 0, 0, ACS_FUNCTION.PcsRound(vPositionAmount * tplImputation.POI_RATIO / vTotRatio, aRoundType, aRoundAmount) )
       where DOC_POSITION_IMPUTATION_ID = tplImputation.DOC_POSITION_IMPUTATION_ID;

      vBigImpId  := tplImputation.DOC_POSITION_IMPUTATION_ID;
    end loop;

    -- recherche des montants cumulés des imputations
    select sum(POI_AMOUNT)
         , sum(POI_AMOUNT_B)
         , sum(POI_AMOUNT_E)
         , sum(POI_AMOUNT_V)
      into vCumulAmount
         , vCumulAmountB
         , vCumulAmountE
         , vCumulAmountV
      from DOC_EST_POS_IMP_CASH_FLOW
     where DOC_POSITION_Id = aPositionId;

    -- mise à jour des différence d'arrondi
    update DOC_EST_POS_IMP_CASH_FLOW
       set POI_AMOUNT = POI_AMOUNT -(vCumulAmount - vPositionAmount)
         , POI_AMOUNT_B = POI_AMOUNT_B -(vCumulAmountB - nvl(vPositionAmountB, 0) )
         , POI_AMOUNT_E = POI_AMOUNT_E -(vCumulAmountE - nvl(vPositionAmountE, 0) )
         , POI_AMOUNT_V = POI_AMOUNT_V -(vCumulAmountV - nvl(vPositionAmountV, 0) )
     where DOC_POSITION_IMPUTATION_ID = vBigImpId;
  end imputeEstimatedPosition;

  /**
  * Description
  *    Fonction de répartition du montant d'une remise/taxe de position
  */
  procedure imputePositionCharge(
    aPositionChargeId      DOC_POSITION_CHARGE.DOC_POSITION_CHARGE_ID%type
  , aPositionChargeAmount  DOC_POSITION_CHARGE.PCH_AMOUNT%type default null
  , aPositionChargeAmountB DOC_POSITION_CHARGE.PCH_AMOUNT_B%type default null
  , aPositionChargeAmountE DOC_POSITION_CHARGE.PCH_AMOUNT_E%type default null
  , aPositionChargeAmountV DOC_POSITION_CHARGE.PCH_AMOUNT_V%type default null
  , aRoundType             varchar2 default '0'
  , aRoundAmount           number default 0
  )
  is
    vAmount       DOC_POSITION_CHARGE.PCH_AMOUNT%type;
    vAmountB      DOC_POSITION_CHARGE.PCH_AMOUNT_B%type;
    vAmountE      DOC_POSITION_CHARGE.PCH_AMOUNT_E%type;
    vAmountV      DOC_POSITION_CHARGE.PCH_AMOUNT_V%type;
    vCumulAmount  DOC_POSITION_CHARGE.PCH_AMOUNT%type                       := 0;
    vCumulAmountB DOC_POSITION_CHARGE.PCH_AMOUNT_B%type                     := 0;
    vCumulAmountE DOC_POSITION_CHARGE.PCH_AMOUNT_E%type                     := 0;
    vCumulAmountV DOC_POSITION_CHARGE.PCH_AMOUNT_V%type                     := 0;
    vTotRatio     DOC_POSITION_IMPUTATION.POI_RATIO%type;
    vBigImpId     DOC_POSITION_IMPUTATION.DOC_POSITION_IMPUTATION_ID%type;
  begin
    -- recherche montants de la remise ou taxe de position pour autant que les informations de la charge ne soient pas
    -- passés en paramètre.
    if aPositionChargeAmount is null then
      select PCH.PCH_AMOUNT
           , PCH.PCH_AMOUNT_B
           , PCH.PCH_AMOUNT_E
           , PCH.PCH_AMOUNT_V
        into vAmount
           , vAmountB
           , vAmountE
           , vAmountV
        from DOC_POSITION_CHARGE PCH
       where DOC_POSITION_CHARGE_ID = aPositionChargeId;
    else
      -- Utilisation des paramètres d'entrée. Appel à partir d'un trigger sur la table DOC_POSITION_CHARGE.
      select aPositionChargeAmount
           , aPositionChargeAmountB
           , aPositionChargeAmountE
           , aPositionChargeAmountV
        into vAmount
           , vAmountB
           , vAmountE
           , vAmountV
        from dual;
    end if;

    -- Vérifie, si on doit faire un arrondi, que le montant à répartir soit lui-même arrondi.
    if     aRoundType <> '0'
       and ACS_FUNCTION.PcsRound(vAmount, aRoundType, aRoundAmount) <> vAmount then
      raise_application_error(-20000, PCS.PC_FUNCTIONS.TranslateWord('PCS - Le montant de la remise/taxe doit être arrondi') );
    end if;

    -- Recherche du ratio total
    select sum(POI_RATIO)
      into vTotRatio
      from DOC_POSITION_IMPUTATION
     where DOC_POSITION_CHARGE_ID = aPositionChargeId;

    -- pour chaque imputation
    for tplImputation in (select   POI_RATIO
                                 , DOC_POSITION_IMPUTATION_ID
                              from DOC_POSITION_IMPUTATION
                             where DOC_POSITION_CHARGE_ID = aPositionChargeId
                          order by POI_RATIO) loop
      -- maj du montant de l'imputation (les montants dans les autres monnaies sont mis à jour par trigger
      update DOC_POSITION_IMPUTATION
         set POI_AMOUNT = decode(vTotRatio, 0, 0, ACS_FUNCTION.PcsRound(vAmount * tplImputation.POI_RATIO / vTotRatio, aRoundType, aRoundAmount) )
       where DOC_POSITION_IMPUTATION_ID = tplImputation.DOC_POSITION_IMPUTATION_ID;

      vBigImpId  := tplImputation.DOC_POSITION_IMPUTATION_ID;
    end loop;

    -- recherche des montants cumulés des imputations
    select sum(POI_AMOUNT)
         , sum(POI_AMOUNT_B)
         , sum(POI_AMOUNT_E)
         , sum(POI_AMOUNT_V)
      into vCumulAmount
         , vCumulAmountB
         , vCumulAmountE
         , vCumulAmountV
      from DOC_POSITION_IMPUTATION
     where DOC_POSITION_CHARGE_ID = aPositionChargeId;

    -- mise à jour des différence d'arrondi
    update DOC_POSITION_IMPUTATION
       set POI_AMOUNT = POI_AMOUNT -(vCumulAmount - vAmount)
         , POI_AMOUNT_B = POI_AMOUNT_B -(vCumulAmountB - vAmountB)
         , POI_AMOUNT_E = POI_AMOUNT_E -(vCumulAmountE - vAmountE)
         , POI_AMOUNT_V = POI_AMOUNT_V -(vCumulAmountV - vAmountV)
     where DOC_POSITION_IMPUTATION_ID = vBigImpId;
  end imputePositionCharge;

  /**
  * Description
  *    Fonction de répartition du montant d'une remise/taxe de position
  */
  procedure imputeFootCharge(aFootChargeId DOC_FOOT_CHARGE.DOC_FOOT_CHARGE_ID%type, aRoundType varchar2 default '0', aRoundAmount number default 0)
  is
    vAmount       DOC_FOOT_CHARGE.FCH_EXCL_AMOUNT%type;
    vAmountB      DOC_FOOT_CHARGE.FCH_EXCL_AMOUNT_B%type;
    vAmountE      DOC_FOOT_CHARGE.FCH_EXCL_AMOUNT_E%type;
    vAmountV      DOC_FOOT_CHARGE.FCH_EXCL_AMOUNT_V%type;
    vCumulAmount  DOC_FOOT_CHARGE.FCH_EXCL_AMOUNT%type                      := 0;
    vCumulAmountB DOC_FOOT_CHARGE.FCH_EXCL_AMOUNT_B%type                    := 0;
    vCumulAmountE DOC_FOOT_CHARGE.FCH_EXCL_AMOUNT_E%type                    := 0;
    vCumulAmountV DOC_FOOT_CHARGE.FCH_EXCL_AMOUNT_V%type                    := 0;
    vTotRatio     DOC_POSITION_IMPUTATION.POI_RATIO%type;
    vBigImpId     DOC_POSITION_IMPUTATION.DOC_POSITION_IMPUTATION_ID%type;
  begin
    -- recherche montants de la position
    select FCH_EXCL_AMOUNT
         , FCH_EXCL_AMOUNT_B
         , FCH_EXCL_AMOUNT_E
         , FCH_EXCL_AMOUNT_V
      into vAmount
         , vAmountB
         , vAmountE
         , vAmountV
      from DOC_FOOT_CHARGE
     where DOC_FOOT_CHARGE_ID = aFootChargeId;

    -- Vérifie, si on doit faire un arrondi, que le montant à répartir soit lui-même arrondi.
    if     aRoundType <> '0'
       and ACS_FUNCTION.PcsRound(vAmount, aRoundType, aRoundAmount) <> vAmount then
      raise_application_error(-20000, PCS.PC_FUNCTIONS.TranslateWord('PCS - Le montant de la remise/taxe doit être arrondi') );
    end if;

    -- Recherche du ratio total
    select sum(POI_RATIO)
      into vTotRatio
      from DOC_POSITION_IMPUTATION
     where DOC_FOOT_CHARGE_ID = aFootChargeId;

    -- pour chaque imputation
    for tplImputation in (select   POI_RATIO
                                 , DOC_POSITION_IMPUTATION_ID
                              from DOC_POSITION_IMPUTATION
                             where DOC_FOOT_CHARGE_ID = aFootChargeId
                          order by POI_RATIO) loop
      -- maj du montant de l'imputation (les montants dans les autres monnaies sont mis à jour par trigger
      update DOC_POSITION_IMPUTATION
         set POI_AMOUNT = decode(vTotRatio, 0, 0, ACS_FUNCTION.PcsRound(vAmount * tplImputation.POI_RATIO / vTotRatio, aRoundType, aRoundAmount) )
       where DOC_POSITION_IMPUTATION_ID = tplImputation.DOC_POSITION_IMPUTATION_ID;

      vBigImpId  := tplImputation.DOC_POSITION_IMPUTATION_ID;
    end loop;

    -- recherche des montants cumulés des imputations
    select sum(POI_AMOUNT)
         , sum(POI_AMOUNT_B)
         , sum(POI_AMOUNT_E)
         , sum(POI_AMOUNT_V)
      into vCumulAmount
         , vCumulAmountB
         , vCumulAmountE
         , vCumulAmountV
      from DOC_POSITION_IMPUTATION
     where DOC_FOOT_CHARGE_ID = aFootChargeId;

    -- mise à jour des différence d'arrondi
    update DOC_POSITION_IMPUTATION
       set POI_AMOUNT = POI_AMOUNT -(vCumulAmount - vAmount)
         , POI_AMOUNT_B = POI_AMOUNT_B -(vCumulAmountB - vAmountB)
         , POI_AMOUNT_E = POI_AMOUNT_E -(vCumulAmountE - vAmountE)
         , POI_AMOUNT_V = POI_AMOUNT_V -(vCumulAmountV - vAmountV)
     where DOC_POSITION_IMPUTATION_ID = vBigImpId;
  end imputeFootCharge;

  /**
  * Description
  *    Si le position ne comprend qu'une seule ventilation,
  *    cette procedure remonte les comptes au niveau de la position
  */
  procedure simplifyVentilation(
    aPositionId       DOC_POSITION.DOC_POSITION_ID%type default null
  , aPositionChargeID DOC_POSITION_CHARGE.DOC_POSITION_CHARGE_ID%type default null
  , aFootChargeID     DOC_FOOT_CHARGE.DOC_FOOT_CHARGE_ID%type default null
  , aSimulation       number default 0
  )
  is
    vCheckParam    number(1);
    vNbImputation  pls_integer;
    vTplImputation DOC_POSITION_IMPUTATION%rowtype;
  begin
    vCheckParam  := nvl(sign(aPositionId), 0) + nvl(sign(aPositionChargeID), 0) + nvl(sign(aFootChargeID), 0);

    if vCheckParam = 1 then
      if aSimulation = 0 then
        -- recherche du nombre d'imputations
        case
          when aPositionId is not null then
            select count(*)
              into vNbImputation
              from DOC_POSITION_IMPUTATION
             where DOC_POSITION_ID = aPositionId;
          when aPositionChargeID is not null then
            select count(*)
              into vNbImputation
              from DOC_POSITION_IMPUTATION
             where DOC_POSITION_CHARGE_ID = aPositionChargeID;
          when aFootChargeID is not null then
            select count(*)
              into vNbImputation
              from DOC_POSITION_IMPUTATION
             where DOC_FOOT_CHARGE_ID = aFootChargeID;
        end case;

        -- Si on a qu'une imputation
        if vNbImputation = 1 then
          -- recherche du nonbre d'imputations
          case
            when aPositionId is not null then
              select *
                into vTplImputation
                from DOC_POSITION_IMPUTATION
               where DOC_POSITION_ID = aPositionId;

              update DOC_POSITION
                 set POS_IMPUTATION = 0
                   , DOC_RECORD_ID = vTplImputation.DOC_RECORD_ID
                   , ACS_PJ_ACCOUNT_ID = vTplImputation.ACS_PJ_ACCOUNT_ID
                   , ACS_PF_ACCOUNT_ID = vTplImputation.ACS_PF_ACCOUNT_ID
                   , ACS_FINANCIAL_ACCOUNT_ID = vTplImputation.ACS_FINANCIAL_ACCOUNT_ID
                   , DIC_IMP_FREE1_ID = vTplImputation.DIC_IMP_FREE1_ID
                   , DIC_IMP_FREE2_ID = vTplImputation.DIC_IMP_FREE2_ID
                   , DIC_IMP_FREE3_ID = vTplImputation.DIC_IMP_FREE3_ID
                   , DIC_IMP_FREE4_ID = vTplImputation.DIC_IMP_FREE4_ID
                   , DIC_IMP_FREE5_ID = vTplImputation.DIC_IMP_FREE5_ID
                   , C_FAM_TRANSACTION_TYP = vTplImputation.C_FAM_TRANSACTION_TYP
                   , FAM_FIXED_ASSETS_ID = vTplImputation.FAM_FIXED_ASSETS_ID
                   , HRM_PERSON_ID = vTplImputation.HRM_PERSON_ID
                   , ACS_CDA_ACCOUNT_ID = vTplImputation.ACS_CDA_ACCOUNT_ID
                   , ACS_CPN_ACCOUNT_ID = vTplImputation.ACS_CPN_ACCOUNT_ID
                   , ACS_DIVISION_ACCOUNT_ID = vTplImputation.ACS_DIVISION_ACCOUNT_ID
                   /* , POS_IMF_NUMBER_1=          vTplImputation.POI_IMF_NUMBER_1 */
              ,      POS_IMF_NUMBER_2 = vTplImputation.POI_IMF_NUMBER_2
                   , POS_IMF_NUMBER_3 = vTplImputation.POI_IMF_NUMBER_3
                   , POS_IMF_NUMBER_4 = vTplImputation.POI_IMF_NUMBER_4
                   , POS_IMF_NUMBER_5 = vTplImputation.POI_IMF_NUMBER_5
                   , POS_IMF_TEXT_1 = vTplImputation.POI_IMF_TEXT_1
                   , POS_IMF_TEXT_2 = vTplImputation.POI_IMF_TEXT_2
                   , POS_IMF_TEXT_3 = vTplImputation.POI_IMF_TEXT_3
                   , POS_IMF_TEXT_4 = vTplImputation.POI_IMF_TEXT_4
                   , POS_IMF_TEXT_5 = vTplImputation.POI_IMF_TEXT_5
                   , POS_IMF_DATE_1 = vTplImputation.POI_IMF_DATE_1
                   , POS_IMF_DATE_2 = vTplImputation.POI_IMF_DATE_2
                   , POS_IMF_DATE_3 = vTplImputation.POI_IMF_DATE_3
                   , POS_IMF_DATE_4 = vTplImputation.POI_IMF_DATE_4
                   , POS_IMF_DATE_5 = vTplImputation.POI_IMF_DATE_5
               where DOC_POSITION_ID = aPositionId;
            when aPositionChargeID is not null then
              select *
                into vTplImputation
                from DOC_POSITION_IMPUTATION
               where DOC_POSITION_CHARGE_ID = aPositionChargeID;

              update DOC_POSITION_CHARGE
                 set PCH_IMPUTATION = 0
                   , ACS_PJ_ACCOUNT_ID = vTplImputation.ACS_PJ_ACCOUNT_ID
                   , ACS_PF_ACCOUNT_ID = vTplImputation.ACS_PF_ACCOUNT_ID
                   , ACS_FINANCIAL_ACCOUNT_ID = vTplImputation.ACS_FINANCIAL_ACCOUNT_ID
                   , DIC_IMP_FREE1_ID = vTplImputation.DIC_IMP_FREE1_ID
                   , DIC_IMP_FREE2_ID = vTplImputation.DIC_IMP_FREE2_ID
                   , DIC_IMP_FREE3_ID = vTplImputation.DIC_IMP_FREE3_ID
                   , DIC_IMP_FREE4_ID = vTplImputation.DIC_IMP_FREE4_ID
                   , DIC_IMP_FREE5_ID = vTplImputation.DIC_IMP_FREE5_ID
                   , C_FAM_TRANSACTION_TYP = vTplImputation.C_FAM_TRANSACTION_TYP
                   , FAM_FIXED_ASSETS_ID = vTplImputation.FAM_FIXED_ASSETS_ID
                   , HRM_PERSON_ID = vTplImputation.HRM_PERSON_ID
                   , ACS_CDA_ACCOUNT_ID = vTplImputation.ACS_CDA_ACCOUNT_ID
                   , ACS_CPN_ACCOUNT_ID = vTplImputation.ACS_CPN_ACCOUNT_ID
                   , ACS_DIVISION_ACCOUNT_ID = vTplImputation.ACS_DIVISION_ACCOUNT_ID
                   /* , POS_IMF_NUMBER_1=          vTplImputation.POI_IMF_NUMBER_1 */
              ,      PCH_IMP_NUMBER_2 = vTplImputation.POI_IMF_NUMBER_2
                   , PCH_IMP_NUMBER_3 = vTplImputation.POI_IMF_NUMBER_3
                   , PCH_IMP_NUMBER_4 = vTplImputation.POI_IMF_NUMBER_4
                   , PCH_IMP_NUMBER_5 = vTplImputation.POI_IMF_NUMBER_5
                   , PCH_IMP_TEXT_1 = vTplImputation.POI_IMF_TEXT_1
                   , PCH_IMP_TEXT_2 = vTplImputation.POI_IMF_TEXT_2
                   , PCH_IMP_TEXT_3 = vTplImputation.POI_IMF_TEXT_3
                   , PCH_IMP_TEXT_4 = vTplImputation.POI_IMF_TEXT_4
                   , PCH_IMP_TEXT_5 = vTplImputation.POI_IMF_TEXT_5
                   , PCH_IMP_DATE_1 = vTplImputation.POI_IMF_DATE_1
                   , PCH_IMP_DATE_2 = vTplImputation.POI_IMF_DATE_2
                   , PCH_IMP_DATE_3 = vTplImputation.POI_IMF_DATE_3
                   , PCH_IMP_DATE_4 = vTplImputation.POI_IMF_DATE_4
                   , PCH_IMP_DATE_5 = vTplImputation.POI_IMF_DATE_5
               where DOC_POSITION_CHARGE_ID = aPositionChargeID;
            when aFootChargeID is not null then
              select *
                into vTplImputation
                from DOC_POSITION_IMPUTATION
               where DOC_FOOT_CHARGE_ID = aFootChargeID;

              update DOC_FOOT_CHARGE
                 set FCH_IMPUTATION = 0
                   , ACS_PJ_ACCOUNT_ID = vTplImputation.ACS_PJ_ACCOUNT_ID
                   , ACS_PF_ACCOUNT_ID = vTplImputation.ACS_PF_ACCOUNT_ID
                   , ACS_FINANCIAL_ACCOUNT_ID = vTplImputation.ACS_FINANCIAL_ACCOUNT_ID
                   , DIC_IMP_FREE1_ID = vTplImputation.DIC_IMP_FREE1_ID
                   , DIC_IMP_FREE2_ID = vTplImputation.DIC_IMP_FREE2_ID
                   , DIC_IMP_FREE3_ID = vTplImputation.DIC_IMP_FREE3_ID
                   , DIC_IMP_FREE4_ID = vTplImputation.DIC_IMP_FREE4_ID
                   , DIC_IMP_FREE5_ID = vTplImputation.DIC_IMP_FREE5_ID
                   , C_FAM_TRANSACTION_TYP = vTplImputation.C_FAM_TRANSACTION_TYP
                   , FAM_FIXED_ASSETS_ID = vTplImputation.FAM_FIXED_ASSETS_ID
                   , HRM_PERSON_ID = vTplImputation.HRM_PERSON_ID
                   , ACS_CDA_ACCOUNT_ID = vTplImputation.ACS_CDA_ACCOUNT_ID
                   , ACS_CPN_ACCOUNT_ID = vTplImputation.ACS_CPN_ACCOUNT_ID
                   , ACS_DIVISION_ACCOUNT_ID = vTplImputation.ACS_DIVISION_ACCOUNT_ID
                   /* , POS_IMF_NUMBER_1=          vTplImputation.POI_IMF_NUMBER_1 */
              ,      FCH_IMP_NUMBER_2 = vTplImputation.POI_IMF_NUMBER_2
                   , FCH_IMP_NUMBER_3 = vTplImputation.POI_IMF_NUMBER_3
                   , FCH_IMP_NUMBER_4 = vTplImputation.POI_IMF_NUMBER_4
                   , FCH_IMP_NUMBER_5 = vTplImputation.POI_IMF_NUMBER_5
                   , FCH_IMP_TEXT_1 = vTplImputation.POI_IMF_TEXT_1
                   , FCH_IMP_TEXT_2 = vTplImputation.POI_IMF_TEXT_2
                   , FCH_IMP_TEXT_3 = vTplImputation.POI_IMF_TEXT_3
                   , FCH_IMP_TEXT_4 = vTplImputation.POI_IMF_TEXT_4
                   , FCH_IMP_TEXT_5 = vTplImputation.POI_IMF_TEXT_5
                   , FCH_IMP_DATE_1 = vTplImputation.POI_IMF_DATE_1
                   , FCH_IMP_DATE_2 = vTplImputation.POI_IMF_DATE_2
                   , FCH_IMP_DATE_3 = vTplImputation.POI_IMF_DATE_3
                   , FCH_IMP_DATE_4 = vTplImputation.POI_IMF_DATE_4
                   , FCH_IMP_DATE_5 = vTplImputation.POI_IMF_DATE_5
               where DOC_FOOT_CHARGE_ID = aFootChargeID;
          end case;
        end if;
      end if;
    else
      ra('PCS - One and only one parameter must be passed to procedure simplifyVentilation');
    end if;
  end simplifyVentilation;

  /**
  * Description
  *    Méthode de création des imputations position sur la base des imputations position de référence.
  */
  procedure CreateLikePositionImputations(
    aDocumentID           DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aGaugeID              DOC_GAUGE.DOC_GAUGE_ID%type
  , aThirdID              PAC_THIRD.PAC_THIRD_ID%type
  , aAdminDomain          DOC_GAUGE.C_ADMIN_DOMAIN%type
  , aDateDocument         DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , aPositionID           DOC_POSITION.DOC_POSITION_ID%type
  , aPositionRow          DOC_POSITION%rowtype
  , aPositionChargeID     DOC_POSITION_CHARGE.DOC_POSITION_CHARGE_ID%type
  , aPositionChargeRow    DOC_POSITION_CHARGE%rowtype
  , aFootChargeID         DOC_FOOT_CHARGE.DOC_FOOT_CHARGE_ID%type
  , aFootChargeRow        DOC_FOOT_CHARGE%rowtype
  , aSimulation        in number default 0
  )
  is
    cursor crMasterPositionImputations(cDocumentID number, cPositionID number)
    is
      select   POI.DOC_DOCUMENT_ID
             , POI.DOC_POSITION_ID
             , POI.DOC_RECORD_ID
             , POI.POI_RATIO
             , POI.POI_AMOUNT
             , POI.POI_AMOUNT_B
             , POI.POI_AMOUNT_E
             , POI.POI_AMOUNT_V
             , POI.ACS_FINANCIAL_ACCOUNT_ID
             , POI.ACS_DIVISION_ACCOUNT_ID
             , POI.ACS_PJ_ACCOUNT_ID
             , POI.ACS_PF_ACCOUNT_ID
             , POI.ACS_CDA_ACCOUNT_ID
             , POI.ACS_CPN_ACCOUNT_ID
             , POI.DIC_IMP_FREE1_ID
             , POI.DIC_IMP_FREE2_ID
             , POI.DIC_IMP_FREE3_ID
             , POI.DIC_IMP_FREE4_ID
             , POI.DIC_IMP_FREE5_ID
             , POI.POI_IMF_NUMBER_1
             , POI.POI_IMF_NUMBER_2
             , POI.POI_IMF_NUMBER_3
             , POI.POI_IMF_NUMBER_4
             , POI.POI_IMF_NUMBER_5
             , POI.POI_IMF_TEXT_1
             , POI.POI_IMF_TEXT_2
             , POI.POI_IMF_TEXT_3
             , POI.POI_IMF_TEXT_4
             , POI.POI_IMF_TEXT_5
             , POI.POI_IMF_DATE_1
             , POI.POI_IMF_DATE_2
             , POI.POI_IMF_DATE_3
             , POI.POI_IMF_DATE_4
             , POI.POI_IMF_DATE_5
             , POI.C_FAM_TRANSACTION_TYP
             , POI.FAM_FIXED_ASSETS_ID
             , POI.HRM_PERSON_ID
          from DOC_POSITION_IMPUTATION POI
         where POI.DOC_DOCUMENT_ID = cDocumentID
           and (   POI.DOC_POSITION_ID is null
                or (    cPositionID is not null
                    and POI.DOC_POSITION_ID = cPositionID) )
           and (   POI.DOC_POSITION_ID is not null
                or (    cPositionID is null
                    and POI.DOC_POSITION_ID is null) )
           and POI.DOC_POSITION_CHARGE_ID is null
           and POI.DOC_FOOT_CHARGE_ID is null
      order by DOC_POSITION_IMPUTATION_ID;

    vPositionImputationRow DOC_POSITION_IMPUTATION%rowtype;
    vPositionRow           DOC_POSITION%rowtype;
    searchPositionID       DOC_POSITION.DOC_POSITION_ID%type;
    docPositionID          DOC_POSITION.DOC_POSITION_ID%type;
  begin
    if not(    aPositionID is null
           and aPositionChargeID is null
           and aFootChargeID is null) then
      searchPositionID  := null;
      docPositionID     := aPositionID;

      if aPositionChargeID is not null then
        searchPositionID  := aPositionID;
        docPositionID     := null;
      end if;

      -- pour chaque imputation de référence ou imputation position pour les imputations remises ou taxes de position
      for tplImputation in crMasterPositionImputations(aDocumentID, searchPositionID) loop
        vPositionRow                                   := aPositionRow;

        if aPositionChargeID is not null then
          -- Recherche les comptes de l'imputation de la position pour une éventuelle reprise des comptes de la position
          -- On utilise le record vPositionRow pour inscrire les comptes de l'imputation correspondante. Pour obtenir
          -- la bonne imputation position, on se base sur l'id de l'imputation. En effet, la création des imputations
          -- par copie se fait en tenant compte de l'ordre de création des imputations sources.
          vPositionRow.ACS_FINANCIAL_ACCOUNT_ID  := tplImputation.ACS_FINANCIAL_ACCOUNT_ID;
          vPositionRow.ACS_DIVISION_ACCOUNT_ID   := tplImputation.ACS_DIVISION_ACCOUNT_ID;
          vPositionRow.ACS_PJ_ACCOUNT_ID         := tplImputation.ACS_PJ_ACCOUNT_ID;
          vPositionRow.ACS_PF_ACCOUNT_ID         := tplImputation.ACS_PF_ACCOUNT_ID;
          vPositionRow.ACS_CDA_ACCOUNT_ID        := tplImputation.ACS_CDA_ACCOUNT_ID;
          vPositionRow.ACS_CPN_ACCOUNT_ID        := tplImputation.ACS_CPN_ACCOUNT_ID;
        end if;

        -- Recherche des comptes des imputations position, remise et taxe de position et remise, taxe et frais de pied.
        GetImputationAccounts(aDocumentID
                            , aGaugeID
                            , aThirdID
                            , tplImputation.DOC_RECORD_ID
                            , aAdminDomain
                            , aDateDocument
                            , docPositionID
                            , vPositionRow
                            , aPositionChargeID
                            , aPositionChargeRow
                            , aFootChargeID
                            , aFootChargeRow
                            , vPositionImputationRow
                             );
        vPositionImputationRow.DOC_DOCUMENT_ID         := aDocumentID;   -- DOC_DOCUMENT_ID
        vPositionImputationRow.DOC_POSITION_ID         := docPositionID;   -- DOC_DOCUMENT_ID
        vPositionImputationRow.DOC_POSITION_CHARGE_ID  := aPositionChargeID;   -- DOC_POSITION_CHARGE_ID
        vPositionImputationRow.DOC_FOOT_CHARGE_ID      := aFootChargeID;   -- DOC_FOOT_CHARGE_ID
        vPositionImputationRow.DOC_RECORD_ID           := tplImputation.DOC_RECORD_ID;   -- DOC_RECORD_ID
        vPositionImputationRow.POI_RATIO               := tplImputation.POI_RATIO;   -- POI_RATIO
        vPositionImputationRow.A_DATECRE               := sysdate;   -- A_DATECRE
        vPositionImputationRow.A_IDCRE                 := PCS.PC_I_LIB_SESSION.GetUserIni;   -- A_IDCRE
        insertPositionImputation(vPositionImputationRow, aSimulation);
      end loop;
    end if;
  end CreateLikePositionImputations;

  /**
  * Description
  *    Méthode d'effacement des imputations position
  */
  procedure DeletePositionImputations(
    aPositionID       DOC_POSITION.DOC_POSITION_ID%type default null
  , aPositionChargeID DOC_POSITION_CHARGE.DOC_POSITION_CHARGE_ID%type default null
  , aFootChargeID     DOC_FOOT_CHARGE.DOC_FOOT_CHARGE_ID%type default null
  )
  is
  begin
    if not(    aPositionID is null
           and aPositionChargeID is null
           and aFootChargeID is null) then
      if aPositionID is not null then
        delete from DOC_POSITION_IMPUTATION
              where DOC_POSITION_ID = aPositionID;
      elsif aPositionChargeID is not null then
        delete from DOC_POSITION_IMPUTATION
              where DOC_POSITION_CHARGE_ID = aPositionChargeID;
      elsif aFootChargeID is not null then
        delete from DOC_POSITION_IMPUTATION
              where DOC_FOOT_CHARGE_ID = aFootChargeID;
      end if;
    end if;
  end DeletePositionImputations;

  /**
  * Description
  *    Vérifie l'exactitude des montants des éventuelles imputations position par rapport aux montants des positions.
  */
  procedure CheckImputations(aDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    cursor crPositions(cDocumentID number)
    is
      select POS.DOC_POSITION_ID
           , POS.POS_GROSS_VALUE
           , POS.POS_GROSS_VALUE_B
           , POS.POS_GROSS_VALUE_E
           , POS.POS_GROSS_VALUE_V
           , POS.POS_GROSS_VALUE_INCL
           , POS.POS_GROSS_VALUE_INCL_B
           , POS.POS_GROSS_VALUE_INCL_E
           , POS.POS_GROSS_VALUE_INCL_V
           , POS.POS_INCLUDE_TAX_TARIFF
           , POS.POS_IMPUTATION
        from DOC_POSITION POS
       where POS.DOC_DOCUMENT_ID = cDocumentID;

    nRecord number;
  begin
    if aDocumentID is not null then
      -- pour chaque position qui contient des imputations position
      for tplPositions in crPositions(aDocumentID) loop
        if tplPositions.POS_IMPUTATION = 1 then
          -- Contrôle l'existance d'au moins une imputation position si le flag de la position est à 1
          select count(POI.DOC_POSITION_IMPUTATION_ID)
            into nRecord
            from DOC_POSITION_IMPUTATION POI
           where POI.DOC_POSITION_ID = tplPositions.DOC_POSITION_ID;

          if (nRecord > 0) then
            -- Fonction de répartition du montant d'une position
            imputePosition(tplPositions.DOC_POSITION_ID
                         , tplPositions.POS_GROSS_VALUE
                         , tplPositions.POS_GROSS_VALUE_B
                         , tplPositions.POS_GROSS_VALUE_E
                         , tplPositions.POS_GROSS_VALUE_V
                         , tplPositions.POS_GROSS_VALUE_INCL
                         , tplPositions.POS_GROSS_VALUE_INCL_B
                         , tplPositions.POS_GROSS_VALUE_INCL_E
                         , tplPositions.POS_GROSS_VALUE_INCL_V
                         , tplPositions.POS_INCLUDE_TAX_TARIFF
                          );
            -- Vérifie la correspondance des éventuelles imputations position par rapport aux imputations des remises et
            -- taxes de positions. Activation des imputations.
            CheckChargeImputations(tplPositions.DOC_POSITION_ID, 1);
          else   -- (nRecord = 0)
            -- Aucune imputations n'existent pour le position courante et le flag en indique la présence.
            -- On passe le flag à 0 pour la coéhrence des données.
            update DOC_POSITION POS
               set POS.POS_IMPUTATION = 0
                 , POS.A_DATEMOD = sysdate
                 , POS.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where POS.DOC_POSITION_ID = tplPositions.DOC_POSITION_ID;

            -- Vérifie la correspondance des éventuelles imputations position par rapport aux imputations des remises et
            -- taxes de positions. Suppression des imputations.
            CheckChargeImputations(tplPositions.DOC_POSITION_ID, 0);
          end if;
        else   -- tplPositions.POS_IMPUTATION = 0
          -- Vérifie la correspondance des éventuelles imputations position par rapport aux imputations des remises et
          -- taxes de positions. Suppression des imputations.

          --          -- Contrôle qu'il n'existe pas d'imputation position si le flag de la position est à 0
--          select count(POI.DOC_POSITION_IMPUTATION_ID)
--            into nRecord
--            from DOC_POSITION_IMPUTATION POI
--           where POI.DOC_POSITION_ID = tplPositions.DOC_POSITION_ID;

          --          if (nRecord > 0) then
--            delete from DOC_POSITION_IMPUTATION PCH
--                  where PCH.DOC_POSITION_CHARGE_ID in(select PCH_SRC.DOC_POSITON_CHARGE_ID
--                                                        from DOC_POSITON_CHARGE PCH_SRC
--                                                       where PCH_SRC.DOC_POSITION_ID = tplPositions.DOC_POSITION_ID);
--          end if;
          CheckChargeImputations(tplPositions.DOC_POSITION_ID, 0);

          -- Contrôle qu'il n'existe pas d'imputation position si le flag de la position est à 0
          select count(POI.DOC_POSITION_IMPUTATION_ID)
            into nRecord
            from DOC_POSITION_IMPUTATION POI
           where POI.DOC_POSITION_ID = tplPositions.DOC_POSITION_ID;

          if (nRecord > 0) then
            -- Des imputations n'existent pour le position courante et le flag n'en indique pas la présence.
            -- On passe le flag à 1 pour la coéhrence des données. La vérification de la correspondance des éventuelles
            -- imputations position par rapport aux imputations des remises et taxes de positions se fait par
            --  l'intermédiaire du trigger DOC_POS_AU_IMPUTATION. Lors du passage du flage POS_IMPUTATION de
            --  0 à 1.
            update DOC_POSITION POS
               set POS.POS_IMPUTATION = 1
                 , POS.A_DATEMOD = sysdate
                 , POS.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where POS.DOC_POSITION_ID = tplPositions.DOC_POSITION_ID;
          end if;
        end if;
      end loop;

      -- Vérifie que les dates des imputations soient identiques à celles de leur élément pére
      CheckImputationDates(iDocumentID => aDocumentID);
    end if;
  end CheckImputations;

  /**
  * Description
  *    Vérifie la correspondance des éventuelles imputations position par rapport aux imputations des remises et
  *    taxes de positions.
  */
  procedure CheckChargeImputations(aPositionID DOC_POSITION.DOC_POSITION_ID%type, aImputation DOC_POSITION.POS_IMPUTATION%type)
  is
    nRecord number;
  begin
    if aPositionID is not null then
      -- Demande la vérification de la création des imputations des remises et taxes de positions.
      if aImputation = 1 then
        -- On effectue l'effacement et le création des imputations des remises et taxes pour garantir la cohérence des
        -- données. On garantit le création des imputations sur les remises et taxes de la position par l'intermédiaire du
        -- trigger DOC_PCH_AU_IMPUTATION à la modification du champ PCH_IMPUTATION (passage de 0 à 1).
        update DOC_POSITION_CHARGE PCH
           set PCH.PCH_IMPUTATION = 0
         where PCH.DOC_POSITION_ID = aPositionID;

        update DOC_POSITION_CHARGE PCH
           set PCH.PCH_IMPUTATION = 1
             , PCH.A_DATEMOD = sysdate
             , PCH.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where PCH.DOC_POSITION_ID = aPositionID;
      else   -- aImputation = 0
        -- Garantit la suppression des imputations sur les remises et taxes de la position si la position ne possède
        -- pas d'imputation sur la position. On garantit le suppression des imputations sur les remises et taxes
        -- de la position par l'intermédiaire du trigger DOC_PCH_AU_IMPUTATION à la modification du champ
        -- PCH_IMPUTATION (passage de 1 à 0).
        update DOC_POSITION_CHARGE PCH
           set PCH.PCH_IMPUTATION = 1
         where PCH.DOC_POSITION_ID = aPositionID;

        update DOC_POSITION_CHARGE PCH
           set PCH.PCH_IMPUTATION = 0
             , PCH.A_DATEMOD = sysdate
             , PCH.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where PCH.DOC_POSITION_ID = aPositionID;
      end if;
    end if;
  end CheckChargeImputations;

  /**
  * Description
  *    Méthode de création des imputations position sur la base d'un position source.
  */
  procedure CopyPositionImputations(
    aDocumentID       DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aPositionID       DOC_POSITION.DOC_POSITION_ID%type
  , aDocumentSourceID DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aPositionSourceID DOC_POSITION.DOC_POSITION_ID%type
  )
  is
    cursor crSourcePositionImputations(cPositionID number)
    is
      select   POI.DOC_DOCUMENT_ID
             , POI.DOC_RECORD_ID
             , POI.POI_RATIO
             , POI.POI_AMOUNT
             , POI.POI_AMOUNT_B
             , POI.POI_AMOUNT_E
             , POI.POI_AMOUNT_V
             , POI.ACS_FINANCIAL_ACCOUNT_ID
             , POI.ACS_DIVISION_ACCOUNT_ID
             , POI.ACS_PJ_ACCOUNT_ID
             , POI.ACS_PF_ACCOUNT_ID
             , POI.ACS_CDA_ACCOUNT_ID
             , POI.ACS_CPN_ACCOUNT_ID
             , POI.DIC_IMP_FREE1_ID
             , POI.DIC_IMP_FREE2_ID
             , POI.DIC_IMP_FREE3_ID
             , POI.DIC_IMP_FREE4_ID
             , POI.DIC_IMP_FREE5_ID
             , POI.POI_IMF_NUMBER_1
             , POI.POI_IMF_NUMBER_2
             , POI.POI_IMF_NUMBER_3
             , POI.POI_IMF_NUMBER_4
             , POI.POI_IMF_NUMBER_5
             , POI.POI_IMF_TEXT_1
             , POI.POI_IMF_TEXT_2
             , POI.POI_IMF_TEXT_3
             , POI.POI_IMF_TEXT_4
             , POI.POI_IMF_TEXT_5
             , POI.POI_IMF_DATE_1
             , POI.POI_IMF_DATE_2
             , POI.POI_IMF_DATE_3
             , POI.POI_IMF_DATE_4
             , POI.POI_IMF_DATE_5
             , POI.C_FAM_TRANSACTION_TYP
             , POI.FAM_FIXED_ASSETS_ID
             , POI.HRM_PERSON_ID
          from DOC_POSITION_IMPUTATION POI
         where POI.DOC_POSITION_ID = cPositionID
      order by POI.DOC_POSITION_IMPUTATION_ID;

    nRecord number;
  begin
    -- pour chaque imputation source
    for tplImputation in crSourcePositionImputations(aPositionSourceID) loop
      insert into DOC_POSITION_IMPUTATION POI
                  (POI.DOC_POSITION_IMPUTATION_ID
                 , POI.DOC_DOCUMENT_ID
                 , POI.DOC_POSITION_ID
                 , POI.DOC_POSITION_CHARGE_ID
                 , POI.DOC_FOOT_CHARGE_ID
                 , POI.DOC_RECORD_ID
                 , POI.POI_RATIO
                 , POI.ACS_FINANCIAL_ACCOUNT_ID
                 , POI.ACS_DIVISION_ACCOUNT_ID
                 , POI.ACS_PJ_ACCOUNT_ID
                 , POI.ACS_PF_ACCOUNT_ID
                 , POI.ACS_CDA_ACCOUNT_ID
                 , POI.ACS_CPN_ACCOUNT_ID
                 , POI.DIC_IMP_FREE1_ID
                 , POI.DIC_IMP_FREE2_ID
                 , POI.DIC_IMP_FREE3_ID
                 , POI.DIC_IMP_FREE4_ID
                 , POI.DIC_IMP_FREE5_ID
                 , POI.POI_IMF_NUMBER_1
                 , POI.POI_IMF_NUMBER_2
                 , POI.POI_IMF_NUMBER_3
                 , POI.POI_IMF_NUMBER_4
                 , POI.POI_IMF_NUMBER_5
                 , POI.POI_IMF_TEXT_1
                 , POI.POI_IMF_TEXT_2
                 , POI.POI_IMF_TEXT_3
                 , POI.POI_IMF_TEXT_4
                 , POI.POI_IMF_TEXT_5
                 , POI.POI_IMF_DATE_1
                 , POI.POI_IMF_DATE_2
                 , POI.POI_IMF_DATE_3
                 , POI.POI_IMF_DATE_4
                 , POI.POI_IMF_DATE_5
                 , POI.C_FAM_TRANSACTION_TYP
                 , POI.FAM_FIXED_ASSETS_ID
                 , POI.HRM_PERSON_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        (select INIT_ID_SEQ.nextval   -- DOC_POSITION_IMPUTATION_ID
              , aDocumentID   -- DOC_DOCUMENT_ID
              , aPositionID   -- DOC_POSITION_ID
              , null   -- DOC_POSITION_CHARGE_ID
              , null   -- DOC_FOOT_CHARGE_ID
              , tplImputation.DOC_RECORD_ID   -- DOC_RECORD_ID
              , tplImputation.POI_RATIO   -- POI_RATIO
              , tplImputation.ACS_FINANCIAL_ACCOUNT_ID   -- ACS_FINANCIAL_ACCOUNT_ID
              , tplImputation.ACS_DIVISION_ACCOUNT_ID   -- ACS_DIVISION_ACCOUNT_ID
              , tplImputation.ACS_PJ_ACCOUNT_ID   -- ACS_PJ_ACCOUNT_ID
              , tplImputation.ACS_PF_ACCOUNT_ID   -- ACS_PF_ACCOUNT_ID
              , tplImputation.ACS_CDA_ACCOUNT_ID   -- ACS_CDA_ACCOUNT_ID
              , tplImputation.ACS_CPN_ACCOUNT_ID   -- ACS_CPN_ACCOUNT_ID
              , tplImputation.DIC_IMP_FREE1_ID   -- DIC_IMP_FREE1_ID
              , tplImputation.DIC_IMP_FREE2_ID   -- DIC_IMP_FREE2_ID
              , tplImputation.DIC_IMP_FREE3_ID   -- DIC_IMP_FREE3_ID
              , tplImputation.DIC_IMP_FREE4_ID   -- DIC_IMP_FREE4_ID
              , tplImputation.DIC_IMP_FREE5_ID   -- DIC_IMP_FREE5_ID
              , tplImputation.POI_IMF_NUMBER_1   -- POI_IMF_NUMBER_1
              , tplImputation.POI_IMF_NUMBER_2   -- POI_IMF_NUMBER_2
              , tplImputation.POI_IMF_NUMBER_3   -- POI_IMF_NUMBER_3
              , tplImputation.POI_IMF_NUMBER_4   -- POI_IMF_NUMBER_4
              , tplImputation.POI_IMF_NUMBER_5   -- POI_IMF_NUMBER_5
              , tplImputation.POI_IMF_TEXT_1   -- POI_IMF_TEXT_1
              , tplImputation.POI_IMF_TEXT_2   -- POI_IMF_TEXT_2
              , tplImputation.POI_IMF_TEXT_3   -- POI_IMF_TEXT_3
              , tplImputation.POI_IMF_TEXT_4   -- POI_IMF_TEXT_4
              , tplImputation.POI_IMF_TEXT_5   -- POI_IMF_TEXT_5
              , tplImputation.POI_IMF_DATE_1   -- POI_IMF_DATE_1
              , tplImputation.POI_IMF_DATE_2   -- POI_IMF_DATE_2
              , tplImputation.POI_IMF_DATE_3   -- POI_IMF_DATE_3
              , tplImputation.POI_IMF_DATE_4   -- POI_IMF_DATE_4
              , tplImputation.POI_IMF_DATE_5   -- POI_IMF_DATE_5
              , tplImputation.C_FAM_TRANSACTION_TYP   -- C_FAM_TRANSACTION_TYP
              , tplImputation.FAM_FIXED_ASSETS_ID   -- FAM_FIXED_ASSETS_ID
              , tplImputation.HRM_PERSON_ID   -- HRM_PERSON_ID
--              , POS.ACS_FINANCIAL_ACCOUNT_ID   -- ACS_FINANCIAL_ACCOUNT_ID
--              , POS.ACS_DIVISION_ACCOUNT_ID   -- ACS_DIVISION_ACCOUNT_ID
--              , POS.ACS_PJ_ACCOUNT_ID   -- ACS_PJ_ACCOUNT_ID
--              , POS.ACS_PF_ACCOUNT_ID   -- ACS_PF_ACCOUNT_ID
--              , POS.ACS_CDA_ACCOUNT_ID   -- ACS_CDA_ACCOUNT_ID
--              , POS.ACS_CPN_ACCOUNT_ID   -- ACS_CPN_ACCOUNT_ID
--              , POS.DIC_IMP_FREE1_ID   -- DIC_IMP_FREE1_ID
--              , POS.DIC_IMP_FREE2_ID   -- DIC_IMP_FREE2_ID
--              , POS.DIC_IMP_FREE3_ID   -- DIC_IMP_FREE3_ID
--              , POS.DIC_IMP_FREE4_ID   -- DIC_IMP_FREE4_ID
--              , POS.DIC_IMP_FREE5_ID   -- DIC_IMP_FREE5_ID
--              , null   -- POI_IMF_NUMBER_1
--              , POS.POS_IMF_NUMBER_2   -- POI_IMF_NUMBER_2
--              , POS.POS_IMF_NUMBER_3   -- POI_IMF_NUMBER_3
--              , POS.POS_IMF_NUMBER_4   -- POI_IMF_NUMBER_4
--              , POS.POS_IMF_NUMBER_5   -- POI_IMF_NUMBER_5
--              , POS.POS_IMF_TEXT_1   -- POI_IMF_TEXT_1
--              , POS.POS_IMF_TEXT_2   -- POI_IMF_TEXT_2
--              , POS.POS_IMF_TEXT_3   -- POI_IMF_TEXT_3
--              , POS.POS_IMF_TEXT_4   -- POI_IMF_TEXT_4
--              , POS.POS_IMF_TEXT_5   -- POI_IMF_TEXT_5
--              , POS.C_FAM_TRANSACTION_TYP   -- C_FAM_TRANSACTION_TYP
--              , POS.FAM_FIXED_ASSETS_ID   -- FAM_FIXED_ASSETS_ID
--              , POS.HRM_PERSON_ID   -- HRM_PERSON_ID
         ,      sysdate   -- A_DATECRE
              , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
           from DOC_POSITION POS
          where DOC_POSITION_ID = aPositionID);
    end loop;

    -- Mise à jour du flag d'imputation
    update DOC_POSITION POS
       set POS.POS_IMPUTATION = (select least(count(POI.DOC_POSITION_IMPUTATION_ID), 1)
                                   from DOC_POSITION_IMPUTATION POI
                                  where POI.DOC_POSITION_ID = POS.DOC_POSITION_ID)
     where POS.DOC_POSITION_ID = aPositionID;

    -- Fonction de répartition du montant d'une position
    imputePosition(aPositionID);

    -- Reprise éventuelle des imputations de référence si elle n'existe pas déjà
    select count(POI.DOC_POSITION_IMPUTATION_ID)
      into nRecord
      from DOC_POSITION_IMPUTATION POI
     where POI.DOC_DOCUMENT_ID = aDocumentID
       and POI.DOC_POSITION_ID is null
       and POI.DOC_POSITION_CHARGE_ID is null
       and POI.DOC_FOOT_CHARGE_ID is null;

    if (nRecord = 0) then
      -- pour chaque imputation de référence
      for tplImputation in (select   POI.POI_RATIO
                                   , POI.DOC_RECORD_ID
                                from DOC_POSITION_IMPUTATION POI
                               where POI.DOC_DOCUMENT_ID = aDocumentSourceID
                                 and POI.DOC_POSITION_ID is null
                                 and POI.DOC_POSITION_CHARGE_ID is null
                                 and POI.DOC_FOOT_CHARGE_ID is null
                            order by POI.DOC_POSITION_IMPUTATION_ID) loop
        insert into DOC_POSITION_IMPUTATION
                    (DOC_POSITION_IMPUTATION_ID
                   , DOC_DOCUMENT_ID
                   , DOC_POSITION_ID
                   , DOC_POSITION_CHARGE_ID
                   , DOC_FOOT_CHARGE_ID
                   , DOC_RECORD_ID
                   , POI_RATIO
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (INIT_ID_SEQ.nextval   -- DOC_POSITION_IMPUTATION_ID
                   , aDocumentID   -- DOC_DOCUMENT_ID
                   , null   -- DOC_POSITION_ID
                   , null   -- DOC_POSITION_CHARGE_ID
                   , null   -- DOC_FOOT_CHARGE_ID
                   , tplImputation.DOC_RECORD_ID   -- DOC_RECORD_ID
                   , tplImputation.POI_RATIO   -- POI_RATIO
                   , sysdate   -- A_DATECRE
                   , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                    );
      end loop;
    end if;
  end CopyPositionImputations;

  /**
  * Description
  *    Méthode de réactualisation des imputations position sur la base des imputations position de référence.
  */
  procedure ApplyPositionImputations(aDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
  begin
    -- Vide le champ A_RECSTATUS de toutes les positions du document pour garantir que le A_RECSTATUS ne contiendra
    -- que les valeurs définies par le passage du flag POS_IMPUTATION de 1 à 0.
    update DOC_POSITION
       set A_RECSTATUS = null
     where DOC_DOCUMENT_ID = aDocumentID;

    -- Supprime les imputations position de toutes les positions qui en possèdent (passage du flag POS_IMPUTATION de
    -- 1 à 0). Marque les positions qui sont touchées pour la recréation des imputations position à partir du modèle
    -- d'imputations.
    update DOC_POSITION
       set A_RECSTATUS = 100
         , POS_IMPUTATION = 0
     where DOC_DOCUMENT_ID = aDocumentID
       and nvl(POS_IMPUTATION, 0) = 1;

    -- Créer les imputations position de toutes les positions qui le demande (passage du flag POS_IMPUTATION de
    -- 0 à 1). Supprime la marque sur les positions qui sont touchées.
    update DOC_POSITION
       set A_RECSTATUS = null
         , POS_IMPUTATION = 1
     where DOC_DOCUMENT_ID = aDocumentID
       and nvl(A_RECSTATUS, 0) = 100;
  end ApplyPositionImputations;

  /**
  * Description
  *    Fonction de répartition des montants de toutes les positions avec le flag imputation à 1
  */
  procedure imputeDocument(aDocumentId DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aRoundType varchar2 default '0', aRoundAmount number default 0)
  is
    vPositionAmount  DOC_POSITION.POS_GROSS_VALUE%type;
    vPositionAmountB DOC_POSITION.POS_GROSS_VALUE_B%type;
    vPositionAmountE DOC_POSITION.POS_GROSS_VALUE_E%type;
    vPositionAmountV DOC_POSITION.POS_GROSS_VALUE_V%type;
    vCumulAmount     DOC_POSITION.POS_GROSS_VALUE%type                         := 0;
    vCumulAmountB    DOC_POSITION.POS_GROSS_VALUE_B%type                       := 0;
    vCumulAmountE    DOC_POSITION.POS_GROSS_VALUE_E%type                       := 0;
    vCumulAmountV    DOC_POSITION.POS_GROSS_VALUE_V%type                       := 0;
    vTotRatio        DOC_POSITION_IMPUTATION.POI_RATIO%type;
    vBigImpId        DOC_POSITION_IMPUTATION.DOC_POSITION_IMPUTATION_ID%type;
    nRecord          number;
  begin
    -- recherche montants des positions
    select sum(decode(POS.POS_INCLUDE_TAX_TARIFF, 0, POS.POS_GROSS_VALUE, POS.POS_GROSS_VALUE_INCL) )
         , sum(decode(POS.POS_INCLUDE_TAX_TARIFF, 0, POS.POS_GROSS_VALUE_B, POS.POS_GROSS_VALUE_INCL_B) )
         , sum(decode(POS.POS_INCLUDE_TAX_TARIFF, 0, POS.POS_GROSS_VALUE_E, POS.POS_GROSS_VALUE_INCL_E) )
         , sum(decode(POS.POS_INCLUDE_TAX_TARIFF, 0, POS.POS_GROSS_VALUE_V, POS.POS_GROSS_VALUE_INCL_V) )
         , count(POS.DOC_POSITION_ID)
      into vPositionAmount
         , vPositionAmountB
         , vPositionAmountE
         , vPositionAmountV
         , nRecord
      from DOC_POSITION POS
     where POS.DOC_DOCUMENT_ID = aDocumentId
       and POS.POS_IMPUTATION = 1;

    -- Vérifie l'existance d'au moins une position avec imputation
    if (nRecord > 0) then
      -- Vérifie, si on doit faire un arrondi, que le montant à répartir soit lui-même arrondi.
      if     aRoundType <> '0'
         and ACS_FUNCTION.PcsRound(vPositionAmount, aRoundType, aRoundAmount) <> vPositionAmount then
        raise_application_error(-20000, PCS.PC_FUNCTIONS.TranslateWord('PCS - Le montant de la position doit être arrondi') );
      end if;

      -- Recherche du ratio total
      select sum(POI.POI_RATIO)
        into vTotRatio
        from DOC_POSITION_IMPUTATION POI
       where DOC_DOCUMENT_ID = aDocumentId
         and POI.DOC_POSITION_ID is null
         and POI.DOC_POSITION_CHARGE_ID is null
         and POI.DOC_FOOT_CHARGE_ID is null;

      -- pour chaque imputation
      for tplImputation in (select   POI.POI_RATIO
                                   , POI.DOC_POSITION_IMPUTATION_ID
                                from DOC_POSITION_IMPUTATION POI
                               where POI.DOC_DOCUMENT_ID = aDocumentId
                                 and POI.DOC_POSITION_ID is null
                                 and POI.DOC_POSITION_CHARGE_ID is null
                                 and POI.DOC_FOOT_CHARGE_ID is null
                            order by POI_RATIO) loop
        -- maj du montant de l'imputation (les montants dans les autres monnaies sont mis à jour par trigger
        update DOC_POSITION_IMPUTATION
           set POI_AMOUNT = ACS_FUNCTION.PcsRound(vPositionAmount * tplImputation.POI_RATIO / vTotRatio, aRoundType, aRoundAmount)
         where DOC_POSITION_IMPUTATION_ID = tplImputation.DOC_POSITION_IMPUTATION_ID;

        vBigImpId  := tplImputation.DOC_POSITION_IMPUTATION_ID;
      end loop;

      -- recherche des montants cumulés des imputations
      select sum(POI.POI_AMOUNT)
           , sum(POI.POI_AMOUNT_B)
           , sum(POI.POI_AMOUNT_E)
           , sum(POI.POI_AMOUNT_V)
        into vCumulAmount
           , vCumulAmountB
           , vCumulAmountE
           , vCumulAmountV
        from DOC_POSITION_IMPUTATION POI
       where POI.DOC_DOCUMENT_ID = aDocumentId
         and POI.DOC_POSITION_ID is null
         and POI.DOC_POSITION_CHARGE_ID is null
         and POI.DOC_FOOT_CHARGE_ID is null;

      -- mise à jour des différence d'arrondi
      update DOC_POSITION_IMPUTATION
         set POI_AMOUNT = POI_AMOUNT -(vCumulAmount - vPositionAmount)
           , POI_AMOUNT_B = POI_AMOUNT_B -(vCumulAmountB - vPositionAmountB)
           , POI_AMOUNT_E = POI_AMOUNT_E -(vCumulAmountE - vPositionAmountE)
           , POI_AMOUNT_V = POI_AMOUNT_V -(vCumulAmountV - vPositionAmountV)
       where DOC_POSITION_IMPUTATION_ID = vBigImpId;
    end if;
  end imputeDocument;

  /**
  * Description
  *    Méthode de recherche des comptes des imputations position, remise et taxe de position et remise, taxe et frais de
  *    pied.
  */
  procedure GetImputationAccounts(
    aDocumentID            in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aGaugeID               in     DOC_GAUGE.DOC_GAUGE_ID%type
  , aThirdID               in     PAC_THIRD.PAC_THIRD_ID%type
  , aRecordID              in     DOC_RECORD.DOC_RECORD_ID%type
  , aAdminDomain           in     DOC_GAUGE.C_ADMIN_DOMAIN%type
  , aDateDocument          in     DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , aPositionID            in     DOC_POSITION.DOC_POSITION_ID%type
  , aPositionRow           in     DOC_POSITION%rowtype
  , aPositionChargeID      in     DOC_POSITION_CHARGE.DOC_POSITION_CHARGE_ID%type
  , aPositionChargeRow     in     DOC_POSITION_CHARGE%rowtype
  , aFootChargeID          in     DOC_FOOT_CHARGE.DOC_FOOT_CHARGE_ID%type
  , aFootChargeRow         in     DOC_FOOT_CHARGE%rowtype
  , aPositionImputationRow out    DOC_POSITION_IMPUTATION%rowtype
  )
  is
    vAccountInfo                ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    cElementType                varchar2(2);
    vElementTypeID              GCO_GOOD.GCO_GOOD_ID%type;
    vGoodID                     GCO_GOOD.GCO_GOOD_ID%type;
    vInACS_FINANCIAL_ACCOUNT_ID DOC_POSITION.ACS_FINANCIAL_ACCOUNT_ID%type;
    vInACS_DIVISION_ACCOUNT_ID  DOC_POSITION.ACS_DIVISION_ACCOUNT_ID%type;
    vInACS_CPN_ACCOUNT_ID       DOC_POSITION.ACS_CPN_ACCOUNT_ID%type;
    vInACS_CDA_ACCOUNT_ID       DOC_POSITION.ACS_CDA_ACCOUNT_ID%type;
    vInACS_PF_ACCOUNT_ID        DOC_POSITION.ACS_PF_ACCOUNT_ID%type;
    vInACS_PJ_ACCOUNT_ID        DOC_POSITION.ACS_PJ_ACCOUNT_ID%type;
  begin
    if not(    aPositionID is null
           and aPositionChargeID is null
           and aFootChargeID is null) then
      -- Commence par réinitialiser les variables de retour.
      aPositionImputationRow.ACS_FINANCIAL_ACCOUNT_ID  := null;
      aPositionImputationRow.ACS_DIVISION_ACCOUNT_ID   := null;
      aPositionImputationRow.ACS_CPN_ACCOUNT_ID        := null;
      aPositionImputationRow.ACS_CDA_ACCOUNT_ID        := null;
      aPositionImputationRow.ACS_PF_ACCOUNT_ID         := null;
      aPositionImputationRow.ACS_PJ_ACCOUNT_ID         := null;

      ----
      -- Détermine le type d'élément pour la recherche des comptes
      --   01 = Imputation comptable (en-tête document)
      --   02 = Imputation comptable (contre écriture)
      --   05 = Calcul d'intérêts
      --   10 = Bien (position document)
      --   11 = Bien (mouvement stock)
      --   12 = Bien (stock)
      --   20 = Remise
      --   30 = Taxe
      --   40 = Position valeur
      --   50 = Frais
      if aPositionChargeID is not null then
        if aPositionChargeRow.PTC_CHARGE_ID is not null then
          cElementType                 := '30';
          vElementTypeID               := aPositionChargeRow.PTC_CHARGE_ID;
          vGoodID                      := null;

          -- Reprend les comptes de remise ou taxe si la configuation de reprise des comptes de la position n'est pas
          -- activée. Cela permet de gérer le cas ou les comptes de la remise ou taxe ne sont pas repris sur les imputations
          -- des remises ou taxes.
          if (PCS.PC_CONFIG.GetConfig('FIN_TAXE_GOOD') <> '1') then
            aPositionImputationRow.ACS_FINANCIAL_ACCOUNT_ID  := aPositionChargeRow.ACS_FINANCIAL_ACCOUNT_ID;
          end if;

          if (PCS.PC_CONFIG.GetConfig('FIN_TAXE_GOOD_DIV') <> '1') then
            aPositionImputationRow.ACS_DIVISION_ACCOUNT_ID  := aPositionChargeRow.ACS_DIVISION_ACCOUNT_ID;
          end if;

          if (PCS.PC_CONFIG.GetConfig('FIN_TAXE_GOOD_CPN') <> '1') then
            aPositionImputationRow.ACS_CPN_ACCOUNT_ID  := aPositionChargeRow.ACS_CPN_ACCOUNT_ID;
          end if;

          if (PCS.PC_CONFIG.GetConfig('FIN_TAXE_GOOD_CDA') <> '1') then
            aPositionImputationRow.ACS_CDA_ACCOUNT_ID  := aPositionChargeRow.ACS_CDA_ACCOUNT_ID;
          end if;

          if (PCS.PC_CONFIG.GetConfig('FIN_TAXE_GOOD_PF') <> '1') then
            aPositionImputationRow.ACS_PF_ACCOUNT_ID  := aPositionChargeRow.ACS_PF_ACCOUNT_ID;
          end if;

          if (PCS.PC_CONFIG.GetConfig('FIN_TAXE_GOOD_PJ') <> '1') then
            aPositionImputationRow.ACS_PJ_ACCOUNT_ID  := aPositionChargeRow.ACS_PJ_ACCOUNT_ID;
          end if;

          -- Initialise les comptes utilisés lorsque les configurations de reprise des comptes de la position sont actives
          vInACS_FINANCIAL_ACCOUNT_ID  := aPositionRow.ACS_FINANCIAL_ACCOUNT_ID;
          vInACS_DIVISION_ACCOUNT_ID   := aPositionRow.ACS_DIVISION_ACCOUNT_ID;
          vInACS_CPN_ACCOUNT_ID        := aPositionRow.ACS_CPN_ACCOUNT_ID;
          vInACS_CDA_ACCOUNT_ID        := aPositionRow.ACS_CDA_ACCOUNT_ID;
          vInACS_PF_ACCOUNT_ID         := aPositionRow.ACS_PF_ACCOUNT_ID;
          vInACS_PJ_ACCOUNT_ID         := aPositionRow.ACS_PJ_ACCOUNT_ID;
        else
          cElementType                 := '20';
          vElementTypeID               := aPositionChargeRow.PTC_DISCOUNT_ID;
          vGoodID                      := null;

          -- Reprend les comptes de remise ou taxe si la configuation de reprise des comptes de la position n'est pas
          -- activée. Cela permet de gérer le cas ou les comptes de la remise ou taxe ne sont pas repris sur les imputations
          -- des remises ou taxes.
          if (PCS.PC_CONFIG.GetConfig('FIN_DSCT_GOOD') <> '1') then
            aPositionImputationRow.ACS_FINANCIAL_ACCOUNT_ID  := aPositionChargeRow.ACS_FINANCIAL_ACCOUNT_ID;
          end if;

          if (PCS.PC_CONFIG.GetConfig('FIN_DSCT_GOOD_DIV') <> '1') then
            aPositionImputationRow.ACS_DIVISION_ACCOUNT_ID  := aPositionChargeRow.ACS_DIVISION_ACCOUNT_ID;
          end if;

          if (PCS.PC_CONFIG.GetConfig('FIN_DSCT_GOOD_CPN') <> '1') then
            aPositionImputationRow.ACS_CPN_ACCOUNT_ID  := aPositionChargeRow.ACS_CPN_ACCOUNT_ID;
          end if;

          if (PCS.PC_CONFIG.GetConfig('FIN_DSCT_GOOD_CDA') <> '1') then
            aPositionImputationRow.ACS_CDA_ACCOUNT_ID  := aPositionChargeRow.ACS_CDA_ACCOUNT_ID;
          end if;

          if (PCS.PC_CONFIG.GetConfig('FIN_DSCT_GOOD_PF') <> '1') then
            aPositionImputationRow.ACS_PF_ACCOUNT_ID  := aPositionChargeRow.ACS_PF_ACCOUNT_ID;
          end if;

          if (PCS.PC_CONFIG.GetConfig('FIN_DSCT_GOOD_PJ') <> '1') then
            aPositionImputationRow.ACS_PJ_ACCOUNT_ID  := aPositionChargeRow.ACS_PJ_ACCOUNT_ID;
          end if;

          -- Initialise les comptes utilisés lorsque les configurations de reprise des comptes de la position sont actives
          vInACS_FINANCIAL_ACCOUNT_ID  := aPositionRow.ACS_FINANCIAL_ACCOUNT_ID;
          vInACS_DIVISION_ACCOUNT_ID   := aPositionRow.ACS_DIVISION_ACCOUNT_ID;
          vInACS_CPN_ACCOUNT_ID        := aPositionRow.ACS_CPN_ACCOUNT_ID;
          vInACS_CDA_ACCOUNT_ID        := aPositionRow.ACS_CDA_ACCOUNT_ID;
          vInACS_PF_ACCOUNT_ID         := aPositionRow.ACS_PF_ACCOUNT_ID;
          vInACS_PJ_ACCOUNT_ID         := aPositionRow.ACS_PJ_ACCOUNT_ID;
        end if;
      elsif aFootChargeID is not null then
        if aFootChargeRow.PTC_CHARGE_ID is not null then
          cElementType    := '30';
          vElementTypeID  := aFootChargeRow.PTC_CHARGE_ID;
          vGoodID         := null;
        elsif aFootChargeRow.PTC_DISCOUNT_ID is not null then
          cElementType    := '20';
          vElementTypeID  := aFootChargeRow.PTC_DISCOUNT_ID;
          vGoodID         := null;
        else
          cElementType    := '50';
          vElementTypeID  := null;
          vGoodID         := null;
        end if;
      else
        if aPositionRow.GCO_GOOD_ID is not null then
          cElementType    := '10';
          vElementTypeID  := aPositionRow.GCO_GOOD_ID;
          vGoodID         := aPositionRow.GCO_GOOD_ID;
        else
          cElementType    := '40';
          vElementTypeID  := null;
          vGoodID         := null;
        end if;
      end if;

      vAccountInfo.DEF_HRM_PERSON                      := null;
      vAccountInfo.FAM_FIXED_ASSETS_ID                 := null;
      vAccountInfo.C_FAM_TRANSACTION_TYP               := null;
      vAccountInfo.DEF_DIC_IMP_FREE1                   := null;
      vAccountInfo.DEF_DIC_IMP_FREE2                   := null;
      vAccountInfo.DEF_DIC_IMP_FREE3                   := null;
      vAccountInfo.DEF_DIC_IMP_FREE4                   := null;
      vAccountInfo.DEF_DIC_IMP_FREE5                   := null;
      vAccountInfo.DEF_TEXT1                           := null;
      vAccountInfo.DEF_TEXT2                           := null;
      vAccountInfo.DEF_TEXT3                           := null;
      vAccountInfo.DEF_TEXT4                           := null;
      vAccountInfo.DEF_TEXT5                           := null;
      vAccountInfo.DEF_NUMBER1                         := null;
      vAccountInfo.DEF_NUMBER2                         := null;
      vAccountInfo.DEF_NUMBER3                         := null;
      vAccountInfo.DEF_NUMBER4                         := null;
      vAccountInfo.DEF_NUMBER5                         := null;
      vAccountInfo.DEF_DATE1                           := null;
      vAccountInfo.DEF_DATE2                           := null;
      vAccountInfo.DEF_DATE3                           := null;
      vAccountInfo.DEF_DATE4                           := null;
      vAccountInfo.DEF_DATE5                           := null;
      -- recherche des comptes position ou remise et taxe
      ACS_I_LIB_LOGISTIC_FINANCIAL.GetAccounts(vElementTypeID
                                             , cElementType
                                             , aAdminDomain
                                             , aDateDocument
                                             , vGoodID
                                             , aGaugeID
                                             , aDocumentID
                                             , aPositionID
                                             , aRecordID
                                             , aThirdID
                                             , vInACS_FINANCIAL_ACCOUNT_ID
                                             , vInACS_DIVISION_ACCOUNT_ID
                                             , vInACS_CPN_ACCOUNT_ID
                                             , vInACS_CDA_ACCOUNT_ID
                                             , vInACS_PF_ACCOUNT_ID
                                             , vInACS_PJ_ACCOUNT_ID
                                             , aPositionImputationRow.ACS_FINANCIAL_ACCOUNT_ID
                                             , aPositionImputationRow.ACS_DIVISION_ACCOUNT_ID
                                             , aPositionImputationRow.ACS_CPN_ACCOUNT_ID
                                             , aPositionImputationRow.ACS_CDA_ACCOUNT_ID
                                             , aPositionImputationRow.ACS_PF_ACCOUNT_ID
                                             , aPositionImputationRow.ACS_PJ_ACCOUNT_ID
                                             , vAccountInfo
                                              );
      aPositionImputationRow.FAM_FIXED_ASSETS_ID       := vAccountInfo.FAM_FIXED_ASSETS_ID;
      aPositionImputationRow.C_FAM_TRANSACTION_TYP     := vAccountInfo.C_FAM_TRANSACTION_TYP;
      aPositionImputationRow.HRM_PERSON_ID             := ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(vAccountInfo.DEF_HRM_PERSON);
      aPositionImputationRow.DIC_IMP_FREE1_ID          := vAccountInfo.DEF_DIC_IMP_FREE1;
      aPositionImputationRow.DIC_IMP_FREE2_ID          := vAccountInfo.DEF_DIC_IMP_FREE2;
      aPositionImputationRow.DIC_IMP_FREE3_ID          := vAccountInfo.DEF_DIC_IMP_FREE3;
      aPositionImputationRow.DIC_IMP_FREE4_ID          := vAccountInfo.DEF_DIC_IMP_FREE4;
      aPositionImputationRow.DIC_IMP_FREE5_ID          := vAccountInfo.DEF_DIC_IMP_FREE5;
      aPositionImputationRow.POI_IMF_TEXT_1            := vAccountInfo.DEF_TEXT1;
      aPositionImputationRow.POI_IMF_TEXT_2            := vAccountInfo.DEF_TEXT2;
      aPositionImputationRow.POI_IMF_TEXT_3            := vAccountInfo.DEF_TEXT3;
      aPositionImputationRow.POI_IMF_TEXT_4            := vAccountInfo.DEF_TEXT4;
      aPositionImputationRow.POI_IMF_TEXT_5            := vAccountInfo.DEF_TEXT5;
      aPositionImputationRow.POI_IMF_NUMBER_1          := to_number(vAccountInfo.DEF_NUMBER1);
      aPositionImputationRow.POI_IMF_NUMBER_2          := to_number(vAccountInfo.DEF_NUMBER2);
      aPositionImputationRow.POI_IMF_NUMBER_3          := to_number(vAccountInfo.DEF_NUMBER3);
      aPositionImputationRow.POI_IMF_NUMBER_4          := to_number(vAccountInfo.DEF_NUMBER4);
      aPositionImputationRow.POI_IMF_NUMBER_5          := to_number(vAccountInfo.DEF_NUMBER5);
      aPositionImputationRow.POI_IMF_DATE_1            := vAccountInfo.DEF_DATE1;
      aPositionImputationRow.POI_IMF_DATE_2            := vAccountInfo.DEF_DATE2;
      aPositionImputationRow.POI_IMF_DATE_3            := vAccountInfo.DEF_DATE3;
      aPositionImputationRow.POI_IMF_DATE_4            := vAccountInfo.DEF_DATE4;
      aPositionImputationRow.POI_IMF_DATE_5            := vAccountInfo.DEF_DATE5;
    end if;
  end GetImputationAccounts;

  /**
  * procedure SynchronizePchImpDates
  * Description
  *    Synchronisation des dates des taxes de positions avec celle de la position
  * @created fp 29.04.2014
  * @updated
  * @public
  * @param iPositionId : identifiant de la position à traiter
  */
  procedure SynchronizePchImpDates(iPositionId in DOC_POSITION.DOC_POSITION_ID%type)
  is
    ltPositionCharge FWK_I_TYP_DEFINITION.t_crud_def;
    ldNullDate       date default to_date('31.12.2999', 'DD.MM.YYYY');
  begin
    -- Màj des dates des imputations liées aux remises/taxes de position dont les dates ne correspondent pas
    for ltplPositionCharge in (select PCH.DOC_POSITION_CHARGE_ID
                                    , POS.POS_IMF_DATE_1
                                    , POS.POS_IMF_DATE_2
                                    , POS.POS_IMF_DATE_3
                                    , POS.POS_IMF_DATE_4
                                    , POS.POS_IMF_DATE_5
                                 from DOC_POSITION_CHARGE PCH
                                    , DOC_POSITION POS
                                where POS.DOC_POSITION_ID = iPositionId
                                  and PCH.DOC_POSITION_ID = POS.DOC_POSITION_ID
                                  and (    (nvl(PCH.PCH_IMP_DATE_1, ldNullDate) <> nvl(POS.POS_IMF_DATE_1, ldNullDate) )
                                       or (nvl(PCH.PCH_IMP_DATE_2, ldNullDate) <> nvl(POS.POS_IMF_DATE_2, ldNullDate) )
                                       or (nvl(PCH.PCH_IMP_DATE_3, ldNullDate) <> nvl(POS.POS_IMF_DATE_3, ldNullDate) )
                                       or (nvl(PCH.PCH_IMP_DATE_4, ldNullDate) <> nvl(POS.POS_IMF_DATE_4, ldNullDate) )
                                       or (nvl(PCH.PCH_IMP_DATE_5, ldNullDate) <> nvl(POS.POS_IMF_DATE_5, ldNullDate) )
                                      ) ) loop
      FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocPositionCharge, ltPositionCharge);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltPositionCharge, 'DOC_POSITION_CHARGE_ID', ltplPositionCharge.DOC_POSITION_CHARGE_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltPositionCharge, 'PCH_IMP_DATE_1', ltplPositionCharge.POS_IMF_DATE_1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltPositionCharge, 'PCH_IMP_DATE_2', ltplPositionCharge.POS_IMF_DATE_2);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltPositionCharge, 'PCH_IMP_DATE_3', ltplPositionCharge.POS_IMF_DATE_3);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltPositionCharge, 'PCH_IMP_DATE_4', ltplPositionCharge.POS_IMF_DATE_4);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltPositionCharge, 'PCH_IMP_DATE_5', ltplPositionCharge.POS_IMF_DATE_5);
      FWK_I_MGT_ENTITY.UpdateEntity(ltPositionCharge);
    end loop;
  end SynchronizePchImpDates;


  /**
  * procedure CheckImputationDates
  * Description
  *   Màj (si nécessaire) des dates des imputations ( DOC_POSITION_IMPUTATION.POI_IMF_DATE_1 .. _5 )
  *     Les dates des imputations (DOC_POSITION_IMPUTATION) doivent correspondre à leur élément pére
  *       -> DOC_POSITION , DOC_POSITION_CHARGE ou DOC_FOOT_CHARGE
  */
  procedure CheckImputationDates(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    lnImputations    integer;
    ldNullDate       date default to_date('31.12.2999', 'DD.MM.YYYY');
    ltImputation     FWK_I_TYP_DEFINITION.t_crud_def;
  begin

    -- Synchronisation des dates des taxes de positions avec celle de la position
    for ltplPositions in (select DOC_POSITION_ID from DOC_POSITION where DOC_DOCUMENT_ID = iDocumentId) loop
      SynchronizePchImpDates(ltplPositions.DOC_POSITION_ID);
    end loop;

    -- Vérifier si le document contient des imputations
    begin
      select 1
        into lnImputations
        from dual
       where exists(select DOC_POSITION_IMPUTATION_ID
                      from DOC_POSITION_IMPUTATION
                     where DOC_DOCUMENT_ID = iDocumentID);
    exception
      when no_data_found then
        lnImputations  := 0;
    end;

    if lnImputations = 1 then

      -- Màj des dates des imputations liées aux position dont les dates ne correspondent pas
      for ltplImputation in (select POI.DOC_POSITION_IMPUTATION_ID
                                  , POS.POS_IMF_DATE_1 as POI_IMF_DATE_1
                                  , POS.POS_IMF_DATE_2 as POI_IMF_DATE_2
                                  , POS.POS_IMF_DATE_3 as POI_IMF_DATE_3
                                  , POS.POS_IMF_DATE_4 as POI_IMF_DATE_4
                                  , POS.POS_IMF_DATE_5 as POI_IMF_DATE_5
                               from DOC_POSITION POS
                                  , DOC_POSITION_IMPUTATION POI
                              where POI.DOC_DOCUMENT_ID = iDocumentID
                                and POI.DOC_POSITION_ID = POS.DOC_POSITION_ID
                                and (    (nvl(POI.POI_IMF_DATE_1, ldNullDate) <> nvl(POS.POS_IMF_DATE_1, ldNullDate) )
                                     or (nvl(POI.POI_IMF_DATE_2, ldNullDate) <> nvl(POS.POS_IMF_DATE_2, ldNullDate) )
                                     or (nvl(POI.POI_IMF_DATE_3, ldNullDate) <> nvl(POS.POS_IMF_DATE_3, ldNullDate) )
                                     or (nvl(POI.POI_IMF_DATE_4, ldNullDate) <> nvl(POS.POS_IMF_DATE_4, ldNullDate) )
                                     or (nvl(POI.POI_IMF_DATE_5, ldNullDate) <> nvl(POS.POS_IMF_DATE_5, ldNullDate) )
                                    ) ) loop
        FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocPositionImputation, ltImputation);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltImputation, 'DOC_POSITION_IMPUTATION_ID', ltplImputation.DOC_POSITION_IMPUTATION_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltImputation, 'POI_IMF_DATE_1', ltplImputation.POI_IMF_DATE_1);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltImputation, 'POI_IMF_DATE_2', ltplImputation.POI_IMF_DATE_2);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltImputation, 'POI_IMF_DATE_3', ltplImputation.POI_IMF_DATE_3);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltImputation, 'POI_IMF_DATE_4', ltplImputation.POI_IMF_DATE_4);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltImputation, 'POI_IMF_DATE_5', ltplImputation.POI_IMF_DATE_5);
        FWK_I_MGT_ENTITY.UpdateEntity(ltImputation);
      end loop;

      -- Màj des dates des imputations liées aux remises/taxes de position dont les dates ne correspondent pas
      for ltplImputation in (select POI.DOC_POSITION_IMPUTATION_ID
                                  , PCH.PCH_IMP_DATE_1 as POI_IMF_DATE_1
                                  , PCH.PCH_IMP_DATE_2 as POI_IMF_DATE_2
                                  , PCH.PCH_IMP_DATE_3 as POI_IMF_DATE_3
                                  , PCH.PCH_IMP_DATE_4 as POI_IMF_DATE_4
                                  , PCH.PCH_IMP_DATE_5 as POI_IMF_DATE_5
                               from DOC_POSITION_CHARGE PCH
                                  , DOC_POSITION_IMPUTATION POI
                              where POI.DOC_DOCUMENT_ID = iDocumentID
                                and POI.DOC_POSITION_CHARGE_ID = PCH.DOC_POSITION_CHARGE_ID
                                and (    (nvl(POI.POI_IMF_DATE_1, ldNullDate) <> nvl(PCH.PCH_IMP_DATE_1, ldNullDate) )
                                     or (nvl(POI.POI_IMF_DATE_2, ldNullDate) <> nvl(PCH.PCH_IMP_DATE_2, ldNullDate) )
                                     or (nvl(POI.POI_IMF_DATE_3, ldNullDate) <> nvl(PCH.PCH_IMP_DATE_3, ldNullDate) )
                                     or (nvl(POI.POI_IMF_DATE_4, ldNullDate) <> nvl(PCH.PCH_IMP_DATE_4, ldNullDate) )
                                     or (nvl(POI.POI_IMF_DATE_5, ldNullDate) <> nvl(PCH.PCH_IMP_DATE_5, ldNullDate) )
                                    ) ) loop
        FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocPositionImputation, ltImputation);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltImputation, 'DOC_POSITION_IMPUTATION_ID', ltplImputation.DOC_POSITION_IMPUTATION_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltImputation, 'POI_IMF_DATE_1', ltplImputation.POI_IMF_DATE_1);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltImputation, 'POI_IMF_DATE_2', ltplImputation.POI_IMF_DATE_2);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltImputation, 'POI_IMF_DATE_3', ltplImputation.POI_IMF_DATE_3);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltImputation, 'POI_IMF_DATE_4', ltplImputation.POI_IMF_DATE_4);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltImputation, 'POI_IMF_DATE_5', ltplImputation.POI_IMF_DATE_5);
        FWK_I_MGT_ENTITY.UpdateEntity(ltImputation);
      end loop;

      -- Màj des dates des imputations liées aux remises/taxes de pied du document dont les dates ne correspondent pas
      for ltplImputation in (select POI.DOC_POSITION_IMPUTATION_ID
                                  , FCH.FCH_IMP_DATE_1 as POI_IMF_DATE_1
                                  , FCH.FCH_IMP_DATE_2 as POI_IMF_DATE_2
                                  , FCH.FCH_IMP_DATE_3 as POI_IMF_DATE_3
                                  , FCH.FCH_IMP_DATE_4 as POI_IMF_DATE_4
                                  , FCH.FCH_IMP_DATE_5 as POI_IMF_DATE_5
                               from DOC_FOOT_CHARGE FCH
                                  , DOC_POSITION_IMPUTATION POI
                              where POI.DOC_DOCUMENT_ID = iDocumentID
                                and POI.DOC_FOOT_CHARGE_ID = FCH.DOC_FOOT_CHARGE_ID
                                and (    (nvl(POI.POI_IMF_DATE_1, ldNullDate) <> nvl(FCH.FCH_IMP_DATE_1, ldNullDate) )
                                     or (nvl(POI.POI_IMF_DATE_2, ldNullDate) <> nvl(FCH.FCH_IMP_DATE_2, ldNullDate) )
                                     or (nvl(POI.POI_IMF_DATE_3, ldNullDate) <> nvl(FCH.FCH_IMP_DATE_3, ldNullDate) )
                                     or (nvl(POI.POI_IMF_DATE_4, ldNullDate) <> nvl(FCH.FCH_IMP_DATE_4, ldNullDate) )
                                     or (nvl(POI.POI_IMF_DATE_5, ldNullDate) <> nvl(FCH.FCH_IMP_DATE_5, ldNullDate) )
                                    ) ) loop
        FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocPositionImputation, ltImputation);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltImputation, 'DOC_POSITION_IMPUTATION_ID', ltplImputation.DOC_POSITION_IMPUTATION_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltImputation, 'POI_IMF_DATE_1', ltplImputation.POI_IMF_DATE_1);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltImputation, 'POI_IMF_DATE_2', ltplImputation.POI_IMF_DATE_2);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltImputation, 'POI_IMF_DATE_3', ltplImputation.POI_IMF_DATE_3);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltImputation, 'POI_IMF_DATE_4', ltplImputation.POI_IMF_DATE_4);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltImputation, 'POI_IMF_DATE_5', ltplImputation.POI_IMF_DATE_5);
        FWK_I_MGT_ENTITY.UpdateEntity(ltImputation);
      end loop;
    end if;
  end CheckImputationDates;
end DOC_IMPUTATION_FUNCTIONS;
