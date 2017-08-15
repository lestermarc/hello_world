--------------------------------------------------------
--  DDL for Package Body STM_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_FUNCTIONS" 
is
-----------------------------------------------------------------------------------------------------------------------
  function GetAvailableQuantity(vGCO_GOOD_ID in number)
    return number
  is
    vQty number;
  begin
    select sum(A.SPO_AVAILABLE_QUANTITY)
      into vQty
      from STM_STOCK_POSITION A
         , STM_STOCK B
     where A.STM_STOCK_ID = B.STM_STOCK_ID
       and B.STO_NEED_CALCULATION = 1
       and A.GCO_GOOD_ID = vGCO_GOOD_ID;

    return vQty;
  end GetAvailableQuantity;

-----------------------------------------------------------------------------------------------------------------------
  function GetAssignQuantity(vGCO_GOOD_ID in number)
    return number
  is
    vQty number;
  begin
    select sum(A.SPO_ASSIGN_QUANTITY)
      into vQty
      from STM_STOCK_POSITION A
         , STM_STOCK B
     where A.STM_STOCK_ID = B.STM_STOCK_ID
       and B.STO_NEED_CALCULATION = 1
       and A.GCO_GOOD_ID = vGCO_GOOD_ID;

    return vQty;
  end GetAssignQuantity;

-----------------------------------------------------------------------------------------------------------------------

  -----------------------------------------------------------------------------------------------------------------------
  function GetStockAvailable(aGCO_GOOD_ID in number, aSTM_STOCK_ID in number, aSTM_LOCATION_ID in number)
    return number
  is
    vQty number;
  begin
    select nvl(sum(A.SPO_AVAILABLE_QUANTITY), 0)
      into vQty
      from STM_STOCK_POSITION A
     where A.GCO_GOOD_ID(+) = aGCO_GOOD_ID
       and A.STM_STOCK_ID(+) = aSTM_STOCK_ID
       and A.STM_LOCATION_ID(+) = aSTM_LOCATION_ID;

    return vQty;
  end GetStockAvailable;

  /**
  * Description :  Fonction de retour de quantité en stock
  *                Retourne la somme de STM_STOCK_POSITION.SPO_STOCK_QUANTITY
  */
  function GetStockQuantity(
    good_id     in STM_STOCK_POSITION.GCO_GOOD_ID%type
  , stock_id    in STM_STOCK_POSITION.STM_STOCK_ID%type default null
  , location_id in STM_STOCK_POSITION.STM_LOCATION_ID%type default null
  , charac1_id  in STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type default null
  , charac2_id  in STM_STOCK_POSITION.GCO_GCO_CHARACTERIZATION_ID%type default null
  , charac3_id  in STM_STOCK_POSITION.GCO2_GCO_CHARACTERIZATION_ID%type default null
  , charac4_id  in STM_STOCK_POSITION.GCO3_GCO_CHARACTERIZATION_ID%type default null
  , charac5_id  in STM_STOCK_POSITION.GCO4_GCO_CHARACTERIZATION_ID%type default null
  , char_val_1  in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type default null
  , char_val_2  in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type default null
  , char_val_3  in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type default null
  , char_val_4  in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type default null
  , char_val_5  in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type default null
  )
    return number
  is
  begin
    return STM_I_LIB_STOCK_POSITION.getSumStockQty(iGoodID                   => good_id
                                                 , iStockID                  => stock_id
                                                 , iLocationID               => location_id
                                                 , iCharacterizationID1      => charac1_id
                                                 , iCharacterizationID2      => charac2_id
                                                 , iCharacterizationID3      => charac3_id
                                                 , iCharacterizationID4      => charac4_id
                                                 , iCharacterizationID5      => charac5_id
                                                 , iCharacterizationValue1   => char_val_1
                                                 , iCharacterizationValue2   => char_val_2
                                                 , iCharacterizationValue3   => char_val_3
                                                 , iCharacterizationValue4   => char_val_4
                                                 , iCharacterizationValue5   => char_val_5
                                                  );
  end GetStockQuantity;

  --fonction permettant d'obtenir la quantité en stock à une date donnée
  function GetStockAtDate(aGoodId in number, aDate in varchar2, aStockId in number default null, aLocationId in number default null)
    return number
  is
    lResult       STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
    lMovementsQty STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type;
    lStockQty     STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
    lDate         date;
  begin
    lDate    := to_date(aDate, 'yyyymmdd');

    select nvl(sum(SPO_STOCK_QUANTITY), 0)
      into lStockQty
      from STM_STOCK_POSITION
     where GCO_GOOD_ID = aGoodId
       and (   STM_STOCK_ID = aStockId
            or aStockId is null)
       and (   STM_LOCATION_ID = aLocationId
            or aLocationId is null);

    select nvl(sum(decode(C_MOVEMENT_SORT, 'ENT', SMO_MOVEMENT_QUANTITY, SMO_MOVEMENT_QUANTITY * -1) ), 0)
      into lMovementsQty
      from STM_STOCK_MOVEMENT STM
         , STM_MOVEMENT_KIND KIND
     where GCO_GOOD_ID = aGoodId
       and (   STM.STM_STOCK_ID = aStockId
            or aStockId is null)
       and (   STM.STM_LOCATION_ID = aLocationId
            or aLocationId is null)
       and STM.STM_MOVEMENT_KIND_ID = KIND.STM_MOVEMENT_KIND_ID
       and C_MOVEMENT_TYPE <> 'EXE'
       and trunc(STM.SMO_MOVEMENT_DATE) > trunc(lDate);

    lResult  := lStockQty - lMovementsQty;

    -- si le produit n'est pas géré en stock on retourne 0
    select decode(PDT_STOCK_MANAGEMENT, 1, 1, 0) * lResult
      into lResult
      from GCO_PRODUCT
     where GCO_GOOD_ID = aGoodId;

    return lResult;
  end GetStockAtDate;

  --fonction permettant d'obtenir la quantité en stock à une date donnée en passant une liste d'id de stock et d'emplacement
  function GetSelectedStockAtDate(aGoodId in number, aDate in varchar2, aStockId in clob default null, aLocationId in clob default null)
    return number
  is
    vResult          STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type      := 0;
    vMovementsQty    STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type;
    vStockQty        STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
    vStockManagement GCO_PRODUCT.PDT_STOCK_MANAGEMENT%type;
    vIsDate          date;
    vLocation        varchar2(4000);
  begin
    select PDT_STOCK_MANAGEMENT
      into vStockManagement
      from GCO_PRODUCT
     where GCO_GOOD_ID = aGoodId;

    -- si le produit n'est pas géré en stock on retourne 0
    if vStockManagement = 1 then
      vIsDate  := to_date(aDate, 'yyyymmdd');

      select nvl(sum(SPO_STOCK_QUANTITY), 0)
        into vStockQty
        from STM_STOCK_POSITION
       where GCO_GOOD_ID = aGoodId
         and (   instr(aStockId, ',' || to_char(STM_STOCK_ID) || ',') > 0
              or aStockId is null)
         and (   instr(',' || aLocationId || ',', ',' || to_char(STM_LOCATION_ID) || ',') > 0
              or aLocationId is null);

      select nvl(sum(decode(C_MOVEMENT_SORT, 'ENT', SMO_MOVEMENT_QUANTITY, SMO_MOVEMENT_QUANTITY * -1) ), 0)
        into vMovementsQty
        from STM_STOCK_MOVEMENT STM
           , STM_MOVEMENT_KIND KIND
       where GCO_GOOD_ID = aGoodId
         and (   instr(aStockId, ',' || to_char(STM.STM_STOCK_ID) || ',') > 0
              or aStockId is null)
         and (   instr(',' || aLocationId || ',', ',' || to_char(STM_LOCATION_ID) || ',') > 0
              or aLocationId is null)
         and STM.STM_MOVEMENT_KIND_ID = KIND.STM_MOVEMENT_KIND_ID
         and C_MOVEMENT_TYPE <> 'EXE'
         and trunc(STM.SMO_MOVEMENT_DATE) > trunc(vIsDate);

      vResult  := vStockQty - vMovementsQty;
    end if;

    return vResult;
  end GetSelectedStockAtDate;

/*******************************************************************************************************************************/
/* Retourne la quantité en stock fin de mois                                                                                   */
/*******************************************************************************************************************************/
  function GetQtyMonth(aGoodId gco_good.gco_good_id%type, aYear varchar2, aMonth varchar2)
    return varchar2
  is
    -- Création PAS le 12.07.2001
    result number;
  begin
    select sum(nvl(a.sae_start_quantity, 0) + nvl(a.sae_input_quantity, 0) - nvl(a.sae_output_quantity, 0) )
      into result
      from stm_annual_evolution a
     where a.gco_good_id = aGoodId
       and a.sae_year = to_number(aYear)
       and a.sae_month <= to_number(aMonth);

    return to_char(result * 1000, '9999999999');
  --  return annee||mois;
  exception
    when no_data_found then
      return '0';
  end GetQtyMonth;

/*******************************************************************************************************************************/
/* Retourne la quantité en stock                                                                                               */
/*******************************************************************************************************************************/
  function GetQtyStock(aGoodId gco_good.gco_good_id%type, aStockList in clob default null, aLocationList in clob default null)
    return varchar2
  is
    result number;
  begin
    select sum(A.SPO_STOCK_QUANTITY)
      into result
      from STM_STOCK_POSITION A
     where A.GCO_GOOD_ID = aGoodId
       and (   instr(aStockList, ',' || to_char(A.STM_STOCK_ID) || ',') > 0
            or aStockList is null)
       and (   instr(aLocationList, ',' || to_char(A.STM_LOCATION_ID) || ',') > 0
            or aLocationList is null);

    return to_char(result * 1000, '9999999999');
  --  RETURN ANNEE||MOIS;
  exception
    when no_data_found then
      return '0';
  end GetQtyStock;

/*******************************************************************************************************************************/
/* Retourne la quantité en commande fournisseur                                                                                */
/*******************************************************************************************************************************/
  function GetQtyCF(aGoodId gco_good.gco_good_id%type, aStockList in clob default null, aLocationList in clob default null)
    return varchar2
  is
    result number;
  begin
    select sum(A.FAN_BALANCE_QTY)
      into result
      from FAL_NETWORK_SUPPLY A
     where A.GCO_GOOD_ID = aGoodId
       and A.DOC_POSITION_DETAIL_ID is not null
       and (   instr(aStockList, ',' || to_char(A.STM_STOCK_ID) || ',') > 0
            or aStockList is null)
       and (   instr(aLocationList, ',' || to_char(A.STM_LOCATION_ID) || ',') > 0
            or aLocationList is null);

    return to_char(result * 1000, '9999999999');
  --  RETURN ANNEE||MOIS;
  exception
    when no_data_found then
      return '0';
  end GetQtyCF;

/*******************************************************************************************************************************/
/* Retourne la quantité en commande client                                                                                     */
/*******************************************************************************************************************************/
  function GetQtyCC(aGoodId gco_good.gco_good_id%type, aStockList in clob default null, aLocationList in clob default null)
    return varchar2
  is
    result number;
  begin
    select sum(A.FAN_BALANCE_QTY)
      into result
      from FAL_NETWORK_NEED A
     where A.GCO_GOOD_ID = aGoodId
       and A.DOC_POSITION_DETAIL_ID is not null
       and (   instr(aStockList, ',' || to_char(A.STM_STOCK_ID) || ',') > 0
            or aStockList is null)
       and (   instr(aLocationList, ',' || to_char(A.STM_LOCATION_ID) || ',') > 0
            or aLocationList is null);

    return to_char(result * 1000, '9999999999');
  exception
    when no_data_found then
      return '0';
  end GetQtyCC;

-----------------------------------------------------------------------------------------------------------------------
-- retourne l'id de l'exercice correspondant à la date
  function GetExerciseId(aDate in date)
    return number
  is
    result STM_EXERCISE.STM_EXERCISE_ID%type;
  begin
    select STM_EXERCISE_ID
      into result
      from STM_EXERCISE
     where aDate between EXE_STARTING_EXERCISE and EXE_ENDING_EXERCISE;

    return result;
  exception
    when others then
      return 0;
  end GetExerciseId;

  /**
  * OBSOLETE
  */
  function getActiveExercise
    return number
  is
    result STM_EXERCISE.STM_EXERCISE_ID%type;
  begin
    -- obsolete
    return STM_LIB_EXERCISE.getActiveExercise;
  end getActiveExercise;

-----------------------------------------------------------------------------------------------------------------------
-- retourne l'id de l'exercice correspondant à la période
  function getPeriodExerciseId(aPeriodId in number)
    return number
  is
    result    STM_PERIOD.STM_PERIOD_ID%type;
    actExId   STM_EXERCISE.STM_EXERCISE_ID%type;
    actExFrom date;
    actExTo   date;
    compDate  date;
  begin
    begin
      -- recherche de la période selon la date passée en paramètre
      select STM_EXERCISE_ID
        into result
        from STM_PERIOD
       where STM_PERIOD_ID = aPeriodId;
    exception
      when no_data_found then
        result  := null;
    end;

    return result;
  end GetPeriodExerciseId;

-----------------------------------------------------------------------------------------------------------------------
-- retourne l'id de la période correspondant à la date
  function GetPeriodId(aDate in date)
    return number
  is
    result  STM_PERIOD.STM_PERIOD_ID%type;
    actExId STM_EXERCISE.STM_EXERCISE_ID%type;
  begin
    begin
      -- recherche de la période selon la date passée en paramètre
      select STM_PERIOD_ID
        into result
        from STM_PERIOD
       where aDate between PER_STARTING_PERIOD and PER_ENDING_PERIOD
         and C_PERIOD_STATUS = '02';
    exception
      when no_data_found then
        begin
          select STM_EXERCISE_ID
            into actExId
            from STM_EXERCISE
           where C_EXERCISE_STATUS = '02';

          -- si pas trouvé d'après la date, recherche d'une période active dans l'exercice actif
          select max(STM_PERIOD_ID)
            into result
            from STM_PERIOD
           where STM_PERIOD.STM_EXERCISE_ID = actExId
             and C_PERIOD_STATUS = '02';
        exception
          -- si pas d'exercice actif on retourne null
          when no_data_found then
            result  := null;
        end;
    end;

    return result;
  end GetPeriodId;

-----------------------------------------------------------------------------------------------------------------------
-- OBSOLETE
  function GetMovementDate(aDate in date)
    return date
  is
  begin
    return STM_LIB_EXERCISE.GetActiveDate(aDate);
  end GetMovementDate;

-----------------------------------------------------------------------------------------------------------------------
/**
* Description :
*               retourne la date si elle est dans la période sinon
*               la borne inférieure ou supérieure de la période
*/
  function ValidatePeriodDate(aPeriodId in number, aDate in date)
    return date deterministic
  is
    startDate date;
    endDate   date;
  begin
    select trunc(PER_STARTING_PERIOD)
         , trunc(PER_ENDING_PERIOD) + 0.99999
      into startDate
         , endDate
      from STM_PERIOD
     where STM_PERIOD_ID = aPeriodId;

    if     aDate >= startDate
       and aDate <= enddate then
      return aDate;
    elsif aDate < startDate then
      return StartDate;
    elsif aDate > endDate then
      return EndDate;
    end if;
  end ValidatePeriodDate;

-----------------------------------------------------------------------------------------------------------------------
/**
* retourne l'id du stock si celui ci est public
*/
  function GetPublicStockId(aStoDescription in varchar2)
    return number
  is
    result STM_STOCK.STM_STOCK_ID%type;
  begin
    select STM_STOCK_ID
      into result
      from STM_STOCK
     where STO_DESCRIPTION = aStoDescription
       and C_ACCESS_METHOD = 'PUBLIC';

    return result;
  exception
    when others then
      return 0;
  end GetPublicStockId;

  /**
  * Description  Fonction qui retourne l'ID de l'emplacement par défaut d'un stock
  */
  function GetDefaultLocationId(aStockId in number)
    return number
  is
    cursor def_loc(aStockId number)
    is
      select   STM_LOCATION_ID
          from STM_LOCATION
         where STM_STOCK_ID = aStockId
      order by LOC_CLASSIFICATION;

    result STM_LOCATION.STM_LOCATION_ID%type;
  begin
    open def_loc(aStockId);

    fetch def_loc
     into result;

    close def_loc;

    return result;
  end GetDefaultLocationId;

  /**
  /* Fonction  de retour du statut de l'élément de caractérisation passé en paramètre
  */
  function GetElementStatus(iElementId in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type)
    return STM_ELEMENT_NUMBER.C_ELE_NUM_STATUS%type
  is
    lElemStatus STM_ELEMENT_NUMBER.C_ELE_NUM_STATUS%type;
  begin
    if iElementId is null then
      return '00';
    else
      select C_ELE_NUM_STATUS
        into lElemStatus
        from STM_ELEMENT_NUMBER
       where STM_ELEMENT_NUMBER_ID = iElementId;

      return lElemStatus;
    end if;
  end GetElementStatus;

  procedure GetMovementAccounts(
    aGoodId          in     number
  , aStockId         in     number
  , aMovementKindId  in     number
  , aDateRef         in     date
  , aOutFinancialID  out    number
  , aOutDivisionId   out    number
  , aOutCpnId        out    number
  , aOutCdaId        out    number
  , aOutPfId         out    number
  , aOutPjId         out    number
  , aOutFinancialID2 out    number
  , aOutDivisionId2  out    number
  , aOutCpnId2       out    number
  , aOutCdaId2       out    number
  , aOutPfId2        out    number
  , aOutPjId2        out    number
  , aGestFin         out    number
  , aGestAna         out    number
  )
  is
    strFinancial          varchar2(30);
    strDivision           varchar2(30);
    strCpn                varchar2(30);
    strCda                varchar2(30);
    strPf                 varchar2(30);
    strPj                 varchar2(30);
    strFinMov             varchar2(30);
    strDivMov             varchar2(30);
    strCpnMov             varchar2(30);
    strCdaMov             varchar2(30);
    strPfMov              varchar2(30);
    strPjMov              varchar2(30);
    strFinancial2         varchar2(30);
    strDivision2          varchar2(30);
    strCpn2               varchar2(30);
    strCda2               varchar2(30);
    strPf2                varchar2(30);
    strPj2                varchar2(30);
    strFinMov2            varchar2(30);
    strDivMov2            varchar2(30);
    strCpnMov2            varchar2(30);
    strCdaMov2            varchar2(30);
    strPfMov2             varchar2(30);
    strPjMov2             varchar2(30);
    strActor              varchar2(1);
    qty                   ACS_DEF_ACCOUNT_VALUES.DEF_QTY_ACCOUNT%type;
    cumul                 ACS_DEF_ACC_MOVEMENT.MOV_CUMUL%type;
    strMOV_HRM_PERSON     ACS_DEF_ACCOUNT_VALUES.DEF_HRM_PERSON%type;
    strMOV_NUMBER1        ACS_DEF_ACCOUNT_VALUES.DEF_NUMBER1%type;
    strMOV_NUMBER2        ACS_DEF_ACCOUNT_VALUES.DEF_NUMBER2%type;
    strMOV_NUMBER3        ACS_DEF_ACCOUNT_VALUES.DEF_NUMBER3%type;
    strMOV_NUMBER4        ACS_DEF_ACCOUNT_VALUES.DEF_NUMBER4%type;
    strMOV_NUMBER5        ACS_DEF_ACCOUNT_VALUES.DEF_NUMBER5%type;
    strMOV_TEXT1          ACS_DEF_ACCOUNT_VALUES.DEF_TEXT1%type;
    strMOV_TEXT2          ACS_DEF_ACCOUNT_VALUES.DEF_TEXT2%type;
    strMOV_TEXT3          ACS_DEF_ACCOUNT_VALUES.DEF_TEXT3%type;
    strMOV_TEXT4          ACS_DEF_ACCOUNT_VALUES.DEF_TEXT4%type;
    strMOV_TEXT5          ACS_DEF_ACCOUNT_VALUES.DEF_TEXT5%type;
    strMOV_DIC_IMP_FREE1  ACS_DEF_ACCOUNT_VALUES.DEF_DIC_IMP_FREE1%type;
    strMOV_DIC_IMP_FREE2  ACS_DEF_ACCOUNT_VALUES.DEF_DIC_IMP_FREE2%type;
    strMOV_DIC_IMP_FREE3  ACS_DEF_ACCOUNT_VALUES.DEF_DIC_IMP_FREE3%type;
    strMOV_DIC_IMP_FREE4  ACS_DEF_ACCOUNT_VALUES.DEF_DIC_IMP_FREE4%type;
    strMOV_DIC_IMP_FREE5  ACS_DEF_ACCOUNT_VALUES.DEF_DIC_IMP_FREE5%type;
    strMOV_DATE1          ACS_DEF_ACCOUNT_VALUES.DEF_DATE1%type;
    strMOV_DATE2          ACS_DEF_ACCOUNT_VALUES.DEF_DATE2%type;
    strMOV_DATE3          ACS_DEF_ACCOUNT_VALUES.DEF_DATE3%type;
    strMOV_DATE4          ACS_DEF_ACCOUNT_VALUES.DEF_DATE4%type;
    strMOV_DATE5          ACS_DEF_ACCOUNT_VALUES.DEF_DATE5%type;
    blnContinuousInventar number(1);
  begin
    -- Vérification que le produit ait une gestion d'inventaire permanent
    -- les services et les pseudo biens, n'ont pas d'inventaires permanents
    select nvl(max(PDT_CONTINUOUS_INVENTAR), 0)
      into blnContinuousInventar
      from GCO_PRODUCT
     where GCO_GOOD_ID = aGoodId;

    if blnContinuousInventar = 1 then
      -- Vérification que le genre de mouvement gère la compta financière et analytique
      select MOK_FINANCIAL_IMPUTATION
           , MOK_ANAL_IMPUTATION
        into aGestFin
           , aGestAna
        from STM_MOVEMENT_KIND
       where STM_MOVEMENT_KIND_ID = aMovementKindId;

      -- Il faut que l'on gère la finance sur le mouvement de stock et que
      -- produit ait une gestion d'inventaire permanent
      if (   aGestFin = 1
          or aGestAna = 1) then
--*****************************************
--  COMPTES BILAN
--*****************************************
-- cascade
--   0) comptes préinitialisés passés en paramètre
--   1) STM_STOCK
--   2) a) Comptes par défaut
--      b) Déplacements
--   3) configs
--***********************************************
-- Recherche des comptes dans STM_STOCK
--**********************************************
        select decode(aGestFin, 1, nvl(aOutFinancialId, ACS_FINANCIAL_ACCOUNT_ID) )
             , decode(aGestFin, 1, nvl(aOutDivisionId, ACS_DIVISION_ACCOUNT_ID) )
          --decode(aGestAna,1,NVL(aOutCpnId, ACS_CPN_ACCOUNT_ID)),
          --decode(aGestAna,1,NVL(aOutCdaId, ACS_CDA_ACCOUNT_ID)),
          --decode(aGestAna,1,NVL(aOutPfId, ACS_PF_ACCOUNT_ID)),
          --decode(aGestAna,1,NVL(aOutPjId, ACS_PJ_ACCOUNT_ID))
        into   aOutFinancialId
             , aOutDivisionId
          --aOutCpnId,
          --aOutCdaId,
          --aOutPfId,
          --aOutPjId
        from   STM_STOCK
         where STM_STOCK_ID = aStockId;

        -- recherche des comptes par défaut
        ACS_DEF_ACCOUNT.GetDefaultAccount(aGoodId
                                        , '11'
                                        ,   -- element_type (bien mouvement)
                                          '3'
                                        ,   -- adminDomain (mouvement stock)
                                          aDateRef
                                        , strFinancial
                                        , strDivision
                                        , strCpn
                                        , strCda
                                        , strPf
                                        , strPj
                                        , qty
                                        , strMOV_HRM_PERSON
                                        , strMOV_NUMBER1
                                        , strMOV_NUMBER2
                                        , strMOV_NUMBER3
                                        , strMOV_NUMBER4
                                        , strMOV_NUMBER5
                                        , strMOV_TEXT1
                                        , strMOV_TEXT2
                                        , strMOV_TEXT3
                                        , strMOV_TEXT4
                                        , strMOV_TEXT5
                                        , strMOV_DIC_IMP_FREE1
                                        , strMOV_DIC_IMP_FREE2
                                        , strMOV_DIC_IMP_FREE3
                                        , strMOV_DIC_IMP_FREE4
                                        , strMOV_DIC_IMP_FREE5
                                        , strMOV_DATE1
                                        , strMOV_DATE2
                                        , strMOV_DATE3
                                        , strMOV_DATE4
                                        , strMOV_DATE5
                                         );
        -- déplacement stock
        ACS_DEF_ACCOUNT.GetDefAccMovement(aStockId
                                        , aGoodId
                                        ,   --aCurId
                                          '6'
                                        , '3'
                                        ,   -- aAdminDomain domaine des stock
                                          '11'
                                        ,   -- aElementType bien mouvement
                                          aDateRef
                                        , cumul
                                        , strFinMov
                                        , strDivMov
                                        , strCpnMov
                                        , strCdaMov
                                        , strPfMov
                                        , strPjMov
                                        , qty
                                        , strMOV_HRM_PERSON
                                        , strMOV_NUMBER1
                                        , strMOV_NUMBER2
                                        , strMOV_NUMBER3
                                        , strMOV_NUMBER4
                                        , strMOV_NUMBER5
                                        , strMOV_TEXT1
                                        , strMOV_TEXT2
                                        , strMOV_TEXT3
                                        , strMOV_TEXT4
                                        , strMOV_TEXT5
                                        , strMOV_DIC_IMP_FREE1
                                        , strMOV_DIC_IMP_FREE2
                                        , strMOV_DIC_IMP_FREE3
                                        , strMOV_DIC_IMP_FREE4
                                        , strMOV_DIC_IMP_FREE5
                                        , strMOV_DATE1
                                        , strMOV_DATE2
                                        , strMOV_DATE3
                                        , strMOV_DATE4
                                        , strMOV_DATE5
                                         );
        strFinancial   := ACS_FUNCTION.MovAccount(strFinancial, strFinMov);
        strDivision    := ACS_FUNCTION.MovAccount(strDivision, strDivMov);
        strCpn         := ACS_FUNCTION.MovAccount(strCpn, strCpnMov);
        strCda         := ACS_FUNCTION.MovAccount(strCda, strCdaMov);
        strPf          := ACS_FUNCTION.MovAccount(strPf, strPfMov);
        strPj          := ACS_FUNCTION.MovAccount(strPj, strPjMov);

        -- recherche des id des comptes en fonction du numéro de compte
        -- Compte financier
        if     aOutFinancialId is null
           and aGestFin = 1 then
          aOutFinancialId  := ACS_FUNCTION.GetFinancialAccountId(strFinancial);
        end if;

        if     aOutFinancialId is null
           and aGestFin = 1 then
          aOutFinancialId  := ACS_FUNCTION.GetFinancialAccountId(PCS.PC_CONFIG.GetConfig('FIN_LG_STOCK_FINANCIAL_ACCOUNT') );
        end if;

        -- Compte division
        if     aOutDivisionId is null
           and aGestFin = 1 then
          aOutDivisionId  := ACS_FUNCTION.GetDivisionAccountId(strDivision);
        end if;

        if     aOutDivisionId is null
           and aGestFin = 1 then
          aOutDivisionId  := ACS_FUNCTION.GetDivisionAccountId(PCS.PC_CONFIG.GetConfig('FIN_LG_STOCK_DIVISION_ACCOUNT') );
        end if;

        -- Charges par nature
        if     aOutCpnId is null
           and aGestAna = 1 then
          aOutCpnId  := ACS_FUNCTION.GetCpnAccountId(strCpn);

          if     (aOutCpnId is null)
             and (aOutFinancialId is not null) then
            aOutCpnId  := ACS_FUNCTION.GetCpnOfFinAcc(aOutFinancialId);
          end if;
        end if;

        --Centre d'analyse
        if     aOutCdaId is null
           and aGestAna = 1 then
          aOutCdaId  := ACS_FUNCTION.GetCdaAccountId(strCda);
        end if;

        -- Porteur de frais
        if     aOutPfId is null
           and aGestAna = 1 then
          aOutPfId  := ACS_FUNCTION.GetPfAccountId(strPf);
        end if;

        -- Projet
        if     aOutPjId is null
           and aGestAna = 1 then
          aOutPjId  := ACS_FUNCTION.GetPjAccountId(strPj);
        end if;

--**********************
--  COMPTES RESULTAT
--**********************
-- cascade
--   0) comptes préinitialisés passés en paramètre
--   1) GCO_IMPUT_STOCK
--   2) STM_MOVEMENT_KIND
--   3) a) Comptes par défaut
--      b) Déplacements
--   4) configs
--********************************************************************************
-- Recherche des comptes dans GCO_IMPUT_STOCK  et dans STM_MOVEMENT_KIND
--********************************************************************************
        begin
          -- recherche dans GCO_IMPUT_STOCK
          select decode(aGestFin, 1, nvl(aOutFinancialId2, ACS_FINANCIAL_ACCOUNT_ID) )
               , decode(aGestFin, 1, nvl(aOutDivisionId2, ACS_DIVISION_ACCOUNT_ID) )
               , decode(aGestAna, 1, nvl(aOutCpnId2, ACS_CPN_ACCOUNT_ID) )
               , decode(aGestAna, 1, nvl(aOutCdaId2, ACS_CDA_ACCOUNT_ID) )
               , decode(aGestAna, 1, nvl(aOutPfId2, ACS_PF_ACCOUNT_ID) )
               , decode(aGestAna, 1, nvl(aOutPjId2, ACS_PJ_ACCOUNT_ID) )
            into aOutFinancialId2
               , aOutDivisionId2
               , aOutCpnId2
               , aOutCdaId2
               , aOutPfId2
               , aOutPjId2
            from GCO_IMPUT_STOCK
           where GCO_GOOD_ID = aGoodId
             and STM_MOVEMENT_KIND_ID = aMovementKindId;
        exception
          when no_data_found then
            begin
              -- recherche dans STM_MOVEMENT_KIND si pas trouvé dans GCO_IMPUT_STOCK
              select decode(aGestFin, 1, nvl(aOutFinancialId2, ACS_FINANCIAL_ACCOUNT_ID) )
                   , decode(aGestFin, 1, nvl(aOutDivisionId2, ACS_DIVISION_ACCOUNT_ID) )
                --decode(aGestAna,1,NVL(aOutCpnId, ACS_CPN_ACCOUNT_ID)),
                --decode(aGestAna,1,NVL(aOutCdaId, ACS_CDA_ACCOUNT_ID)),
                --decode(aGestAna,1,NVL(aOutPfId, ACS_PF_ACCOUNT_ID)),
                --decode(aGestAna,1,NVL(aOutPjId, ACS_PJ_ACCOUNT_ID))
              into   aOutFinancialId2
                   , aOutDivisionId2
                --aOutCpnId,
                --aOutCdaId,
                --aOutPfId,
                --aOutPjId
              from   STM_MOVEMENT_KIND
               where STM_MOVEMENT_KIND_ID = aMovementKindId;
            exception
              when no_data_found then
                null;
            end;
        end;

        -- recherche des comptes par défaut
        ACS_DEF_ACCOUNT.GetDefaultAccount(aGoodId
                                        , '11'
                                        ,   -- element_type (bien mouvement)
                                          '3'
                                        ,   -- adminDomain (mouvement stock)
                                          aDateRef
                                        , strFinancial2
                                        , strDivision2
                                        , strCpn2
                                        , strCda2
                                        , strPf2
                                        , strPj2
                                        , qty
                                        , strMOV_HRM_PERSON
                                        , strMOV_NUMBER1
                                        , strMOV_NUMBER2
                                        , strMOV_NUMBER3
                                        , strMOV_NUMBER4
                                        , strMOV_NUMBER5
                                        , strMOV_TEXT1
                                        , strMOV_TEXT2
                                        , strMOV_TEXT3
                                        , strMOV_TEXT4
                                        , strMOV_TEXT5
                                        , strMOV_DIC_IMP_FREE1
                                        , strMOV_DIC_IMP_FREE2
                                        , strMOV_DIC_IMP_FREE3
                                        , strMOV_DIC_IMP_FREE4
                                        , strMOV_DIC_IMP_FREE5
                                        , strMOV_DATE1
                                        , strMOV_DATE2
                                        , strMOV_DATE3
                                        , strMOV_DATE4
                                        , strMOV_DATE5
                                         );
        -- déplacement genre de mouvement
        ACS_DEF_ACCOUNT.GetDefAccMovement(aMovementKindId
                                        , aGoodId
                                        ,   -- curId
                                          '5'
                                        , '3'
                                        ,   -- aAdminDomain : stock
                                          '11'
                                        ,   -- aElementType : bien mouvement
                                          aDateRef
                                        , cumul
                                        , strFinMov2
                                        , strDivMov2
                                        , strCpnMov2
                                        , strCdaMov2
                                        , strPfMov2
                                        , strPjMov2
                                        , qty
                                        , strMOV_HRM_PERSON
                                        , strMOV_NUMBER1
                                        , strMOV_NUMBER2
                                        , strMOV_NUMBER3
                                        , strMOV_NUMBER4
                                        , strMOV_NUMBER5
                                        , strMOV_TEXT1
                                        , strMOV_TEXT2
                                        , strMOV_TEXT3
                                        , strMOV_TEXT4
                                        , strMOV_TEXT5
                                        , strMOV_DIC_IMP_FREE1
                                        , strMOV_DIC_IMP_FREE2
                                        , strMOV_DIC_IMP_FREE3
                                        , strMOV_DIC_IMP_FREE4
                                        , strMOV_DIC_IMP_FREE5
                                        , strMOV_DATE1
                                        , strMOV_DATE2
                                        , strMOV_DATE3
                                        , strMOV_DATE4
                                        , strMOV_DATE5
                                         );
        strFinancial2  := ACS_FUNCTION.MovAccount(strFinancial2, strFinMov2);
        strDivision2   := ACS_FUNCTION.MovAccount(strDivision2, strDivMov2);
        strCpn2        := ACS_FUNCTION.MovAccount(strCpn2, strCpnMov2);
        strCda2        := ACS_FUNCTION.MovAccount(strCda2, strCdaMov2);
        strPf2         := ACS_FUNCTION.MovAccount(strPf2, strPfMov2);
        strPj2         := ACS_FUNCTION.MovAccount(strPj2, strPjMov2);

        -- recherche des id des comptes en fonction du numéro de compte
        -- Compte financier
        if     aOutFinancialId2 is null
           and aGestFin = 1 then
          aOutFinancialId2  := ACS_FUNCTION.GetFinancialAccountId(strFinancial2);
        end if;

        if     aOutFinancialId2 is null
           and aGestFin = 1 then
          aOutFinancialId2  := ACS_FUNCTION.GetFinancialAccountId(PCS.PC_CONFIG.GetConfig('FIN_MVT_FINANCIAL_ACCOUNT') );
        end if;

        -- Compte division
        if     aOutDivisionId2 is null
           and aGestFin = 1 then
          aOutDivisionId2  := ACS_FUNCTION.GetDivisionAccountId(strDivision2);
        end if;

        if     aOutDivisionId2 is null
           and aGestFin = 1 then
          aOutDivisionId2  := ACS_FUNCTION.GetDivisionAccountId(PCS.PC_CONFIG.GetConfig('FIN_MVT_DIVISION_ACCOUNT') );
        end if;

        -- Charges par nature
        if     aOutCpnId2 is null
           and aGestAna = 1 then
          aOutCpnId2  := ACS_FUNCTION.GetCpnAccountId(strCpn2);

          if     (aOutCpnId2 is null)
             and (aOutFinancialId2 is not null) then
            aOutCpnId2  := ACS_FUNCTION.GetCpnOfFinAcc(aOutFinancialId2);
          end if;
        end if;

        --Centre d'analyse
        if     aOutCdaId2 is null
           and aGestAna = 1 then
          aOutCdaId2  := ACS_FUNCTION.GetCdaAccountId(strCda2);
        end if;

        -- Porteur de frais
        if     aOutPfId2 is null
           and aGestAna = 1 then
          aOutPfId2  := ACS_FUNCTION.GetPfAccountId(strPf2);
        end if;

        -- Projet
        if     aOutPjId2 is null
           and aGestAna = 1 then
          aOutPjId2  := ACS_FUNCTION.GetPjAccountId(strPj2);
        end if;
      end if;
    else
      aGestFin  := 0;
      aGestAna  := 0;
    end if;
  end GetMovementAccounts;

  /**
  * Description
  *      Cette procédure met à jour les quantités et les sommes de début de périodes
  *       A appeler lors du bouclement d'exercice
  */
  procedure STM_CalcAnnualStartValues(exercise_id in number)
  is
    cursor all_evolutions(exercise_id number)
    is
      select STM_ANNUAL_EVOLUTION_ID
           , SOLDE_QTY_START
           , SOLDE_VALUE_START
        from V_STM_ANNUAL_EVOLUTION
           , STM_EXERCISE
       where STM_EXERCISE_ID = exercise_id
         and SAE_YEAR || ltrim(to_char(SAE_MONTH, '00') ) >= to_char(EXE_STARTING_EXERCISE, 'YYYYMM')
         and SAE_YEAR || ltrim(to_char(SAE_MONTH, '00') ) <= to_char(EXE_ENDING_EXERCISE, 'YYYYMM');

    evolution_tuple all_evolutions%rowtype;
    i               number(12);
  begin
    -- curseur sur les évolutions de stock de l'exercice passé en paramètre
    open all_evolutions(exercise_id);

    fetch all_evolutions
     into evolution_tuple;

    -- compteur pour les commit
    i  := 0;

    while all_evolutions%found loop
      -- mise à jour d'après la vue qui contient les valeurs et quantités de début
      update STM_ANNUAL_EVOLUTION
         set SAE_START_QUANTITY = evolution_tuple.SOLDE_QTY_START
           , SAE_START_VALUE = evolution_tuple.SOLDE_VALUE_START
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where STM_ANNUAL_EVOLUTION_ID = evolution_tuple.STM_ANNUAL_EVOLUTION_ID;

      -- enregistrement suivant
      fetch all_evolutions
       into evolution_tuple;

      -- tout les 100 enregistrements, on fait un commit
      if i > 100 then
        i  := 0;
        commit;
      else
        i  := i + 1;
      end if;
    end loop;

    -- on valide les enregistrements en cours
    commit;

    close all_evolutions;
  end STM_CalcAnnualStartValues;

  /**
  * Description
  *      Recherche du type de mouvement à utiliser pour les services
  */
  procedure GetSagKindId(aMovementKindId in number, aSagMovementKindId out number, aSagStockId out number)
  is
  begin
    select   MOK_TARGET.STM_MOVEMENT_KIND_ID
           , MOK_TARGET.STM_STOCK_ID
        into aSagMovementKindId
           , aSagStockId
        from STM_MOVEMENT_KIND MOK_SOURCE
           , STM_MOVEMENT_KIND MOK_TARGET
       where MOK_SOURCE.STM_MOVEMENT_KIND_ID = aMovementKindId
         and MOK_TARGET.C_MOVEMENT_SORT = MOK_SOURCE.C_MOVEMENT_SORT
         and MOK_TARGET.C_MOVEMENT_TYPE = 'SAG'
    order by MOK_TARGET.C_MOVEMENT_CODE;
  end GetSagKindId;

  /**
  * Description
  *   Retourne true si la caractérisation est déjà en stock pour l'article ou la société
  *   selon les config de gestion de l'unicité au niveau lot ou pièce
  *   Attention, si on a une entrée ou une sortie provisoire sans avoir de quantité effective
  *   la fonction retourne également true.
  */
  function isCharInStock(aGoodId in number, aCharType in varchar2, aValue in varchar2)
    return boolean
  is
    tempId number(12);
  begin
    -- Numéros de pièces
    if aCharType = '3' then
      -- Unicité des numéros de pièces par mandat
      if (upper(PCS.PC_CONFIG.GetConfig('STM_PIECE_SGL_NUMBERING_COMP') ) = 'TRUE') then
        select max(stm_stock_position_id)
          into tempId
          from STM_STOCK_POSITION
         where SPO_PIECE = aValue;
      else
        select max(stm_stock_position_id)
          into tempId
          from STM_STOCK_POSITION
         where GCO_GOOD_ID = aGoodId
           and SPO_PIECE = aValue;
      end if;
    -- Numéros de lots
    elsif aCharType = '4' then
      -- Unicité des numéros de lots par mandat
      if (upper(PCS.PC_CONFIG.GetConfig('STM_SET_SGL_NUMBERING_COMP') ) = 'TRUE') then
        select max(stm_stock_position_id)
          into tempId
          from STM_STOCK_POSITION
         where SPO_SET = aValue;
      else
        select max(stm_stock_position_id)
          into tempId
          from STM_STOCK_POSITION
         where GCO_GOOD_ID = aGoodId
           and SPO_SET = aValue;
      end if;
    -- Version
    elsif aCharType = '1' then
      -- Unicité des numéros de version par mandat
      if (upper(PCS.PC_CONFIG.GetConfig('STM_VERSION_SGL_NUMBERING_COMP') ) = 'TRUE') then
        select max(stm_stock_position_id)
          into tempId
          from STM_STOCK_POSITION
         where SPO_SET = aValue;
      else
        select max(stm_stock_position_id)
          into tempId
          from STM_STOCK_POSITION
         where GCO_GOOD_ID = aGoodId
           and SPO_SET = aValue;
      end if;
    end if;

    return(tempId is not null);
  end isCharInStock;

  /**
  * Description
  *  Wrapper de IsCharInStock, retourne 0 au lieu de False, 1 au lieu de True
  */
  function isCharInStock1(aGoodId in number, aCharType in varchar2, aValue in varchar2)
    return number
  is
  begin
    if IsCharInStock(aGoodId, aCharType, aValue) then
      return 1;
    else
      return 0;
    end if;
  end IsCharInStock1;

  /**
  * Description
  *   Retourne la valeur du champ C_ELE_NUM_STATUS de l'élément correspondant
  *   aux paramètres entrants
  *   Retourne '00' si l'élément n0a pas été trouvé
  */
  function GetElementNumberStatus(aGoodId in number, aCharType in varchar2, aValue in varchar2)
    return varchar2
  is
    result STM_ELEMENT_NUMBER.C_ELE_NUM_STATUS%type;
  begin
    begin
      select c_ele_num_status
        into result
        from STM_ELEMENT_NUMBER
       where SEM_VALUE = aValue
         and GCO_GOOD_ID = aGoodId
         and C_ELEMENT_TYPE = decode(aCharType, '3', '02', '4', '01', '1', '03');
    exception
      when no_data_found then
        result  := '00';
    end;

    return result;
  end GetElementNumberStatus;

  /**
  * Description
  *   Retourne le status de l'élément recherché  (table STM_ELEMENT_NUMBER)
  *   (vide si non trouvé, ce qui permet également de vérifier l'existence)
  */
  function getElementStatus(aGoodId in number, aElementType in varchar2, aValue in varchar2)
    return varchar2
  is
    result varchar2(2);
  begin
    -- Numéros de Pieces
    if aElementType = '2' then
      -- Numérotation pièces unique par mandat. Recherche indépendante du bien
      if (upper(PCS.PC_CONFIG.GetConfig('STM_PIECE_SGL_NUMBERING_COMP') ) = 'TRUE') then
        select max(C_ELE_NUM_STATUS)
          into result
          from STM_ELEMENT_NUMBER
         where SEM_VALUE = aValue
           and C_ELEMENT_TYPE = aElementType;
      -- Numérotation pièces unique par article (obligation pour la gestion des numéros de pièces).
      -- Recherche dépendante du bien
      else
        select max(C_ELE_NUM_STATUS)
          into result
          from STM_ELEMENT_NUMBER
         where SEM_VALUE = aValue
           and GCO_GOOD_ID = aGoodId
           and C_ELEMENT_TYPE = aElementType;
      end if;
    -- Numéros de lots
    elsif aElementType = '1' then
      -- Numérotation lot unique par mandat. Recherche indépendante du bien
      if (upper(PCS.PC_CONFIG.GetConfig('STM_SET_SGL_NUMBERING_COMP') ) = 'TRUE') then
        select max(C_ELE_NUM_STATUS)
          into result
          from STM_ELEMENT_NUMBER
         where SEM_VALUE = aValue
           and C_ELEMENT_TYPE = aElementType;
      -- Numérotation lot unique par bien ou libre. Recherche dépendante du bien
      else
        select max(C_ELE_NUM_STATUS)
          into result
          from STM_ELEMENT_NUMBER
         where SEM_VALUE = aValue
           and GCO_GOOD_ID = aGoodId
           and C_ELEMENT_TYPE = aElementType;
      end if;
    -- Versions
    elsif aElementType = '3' then
      -- Numérotation version unique par mandat. Recherche indépendante du bien
      if (upper(PCS.PC_CONFIG.GetConfig('STM_VERSION_SGL_NUMBERING_COMP') ) = 'TRUE') then
        select max(C_ELE_NUM_STATUS)
          into result
          from STM_ELEMENT_NUMBER
         where SEM_VALUE = aValue
           and C_ELEMENT_TYPE = aElementType;
      -- Numérotation version unique par bien ou libre. Recherche dépendante du bien
      else
        select max(C_ELE_NUM_STATUS)
          into result
          from STM_ELEMENT_NUMBER
         where SEM_VALUE = aValue
           and GCO_GOOD_ID = aGoodId
           and C_ELEMENT_TYPE = aElementType;
      end if;
    end if;

    return result;
  end getElementStatus;

  /**
  * function GetMovementFinImpFlag
  * Description
  *    retourne le flag d'intégration en finance en fonction du genre de mouvement
  * @author FP
  * @created 11/02/2002
  * @lastUpdate
  * @public
  * @param aMovementKindId : genre de mouvement de référence
  */
  function GetMovementFinImpFlag(aMovementkindId in STM_MOVEMENT_KIND.MOK_FINANCIAL_IMPUTATION%type)
    return number
  is
    result STM_MOVEMENT_KIND.MOK_FINANCIAL_IMPUTATION%type;
  begin
    -- si la config autorise les mouvements d'interface finance
    if upper(PCS.PC_CONFIG.GetConfig('STM_FINANCIAL_CHARGING') ) = 'TRUE' then
      -- recherche de la valeur du flag
      select MOK_FINANCIAL_IMPUTATION
        into result
        from STM_MOVEMENT_KIND
       where STM_MOVEMENT_KIND_ID = aMovementKindId;

      return result;
    else
      return 0;
    end if;
  exception
    when no_data_found then
      return null;
  end GetMovementFinImpFlag;

  /**
  * Description
  *   Recherche de l'Id d'une position de stock en fonction de la PK2
  */
  function getPositionId(
    aGoodId     number
  , aLocationId number
  , aCharId1    number
  , aCharId2    number
  , aCharId3    number
  , aCharId4    number
  , aCharId5    number
  , aCharVal1   varchar2
  , aCharVal2   varchar2
  , aCharVal3   varchar2
  , aCharVal4   varchar2
  , aCharVal5   varchar2
  )
    return number
  is
    result STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type;
  begin
    select STM_STOCK_POSITION_ID
      into result
      from STM_STOCK_POSITION
     where GCO_GOOD_ID = aGoodId
       and STM_LOCATION_ID = aLocationId
       and nvl(GCO_CHARACTERIZATION_ID, 0) = nvl(aCharId1, 0)
       and nvl(GCO_GCO_CHARACTERIZATION_ID, 0) = nvl(aCharId2, 0)
       and nvl(GCO2_GCO_CHARACTERIZATION_ID, 0) = nvl(aCharId3, 0)
       and nvl(GCO3_GCO_CHARACTERIZATION_ID, 0) = nvl(aCharId4, 0)
       and nvl(GCO4_GCO_CHARACTERIZATION_ID, 0) = nvl(aCharId5, 0)
       and nvl(SPO_CHARACTERIZATION_VALUE_1, 0) = nvl(aCharVal1, 0)
       and nvl(SPO_CHARACTERIZATION_VALUE_2, 0) = nvl(aCharVal2, 0)
       and nvl(SPO_CHARACTERIZATION_VALUE_3, 0) = nvl(aCharVal3, 0)
       and nvl(SPO_CHARACTERIZATION_VALUE_4, 0) = nvl(aCharVal4, 0)
       and nvl(SPO_CHARACTERIZATION_VALUE_5, 0) = nvl(aCharVal5, 0);

    return result;
  exception
    when no_data_found then
      return null;
  end getPositionId;

  /**
  * Description
  *   Recherche du status d'une position de stock en fonction de la PK2
  */
  function getPositionStatus(
    aGoodId     number
  , aLocationId number
  , aCharId1    number
  , aCharId2    number
  , aCharId3    number
  , aCharId4    number
  , aCharId5    number
  , aCharVal1   varchar2
  , aCharVal2   varchar2
  , aCharVal3   varchar2
  , aCharVal4   varchar2
  , aCharVal5   varchar2
  )
    return varchar2
  is
    result STM_STOCK_POSITION.C_POSITION_STATUS%type;
  begin
    select C_POSITION_STATUS
      into result
      from STM_STOCK_POSITION
     where GCO_GOOD_ID = aGoodId
       and STM_LOCATION_ID = aLocationId
       and nvl(GCO_CHARACTERIZATION_ID, 0) = nvl(aCharId1, 0)
       and nvl(GCO_GCO_CHARACTERIZATION_ID, 0) = nvl(aCharId2, 0)
       and nvl(GCO2_GCO_CHARACTERIZATION_ID, 0) = nvl(aCharId3, 0)
       and nvl(GCO3_GCO_CHARACTERIZATION_ID, 0) = nvl(aCharId4, 0)
       and nvl(GCO4_GCO_CHARACTERIZATION_ID, 0) = nvl(aCharId5, 0)
       and nvl(SPO_CHARACTERIZATION_VALUE_1, 0) = nvl(aCharVal1, 0)
       and nvl(SPO_CHARACTERIZATION_VALUE_2, 0) = nvl(aCharVal2, 0)
       and nvl(SPO_CHARACTERIZATION_VALUE_3, 0) = nvl(aCharVal3, 0)
       and nvl(SPO_CHARACTERIZATION_VALUE_4, 0) = nvl(aCharVal4, 0)
       and nvl(SPO_CHARACTERIZATION_VALUE_5, 0) = nvl(aCharVal5, 0);

    return result;
  exception
    when no_data_found then
      return null;
  end getPositionStatus;

  /**
  * Description :  Fonction de retour de quantité en stock après retrait de la
  *                quantité attribuée. Retourne la somme de
  *                STM_STOCK_POSITION.SPO_STOCK_QUANTITY moins
  *                STM_STOCK_POSITION.SPO_ASSIGN_QUANTITY.
  */
  function GetRealStockQuantity(
    aGoodId         in STM_STOCK_POSITION.GCO_GOOD_ID%type
  , aStockId        in STM_STOCK_POSITION.STM_STOCK_ID%type default null
  , aLocationId     in STM_STOCK_POSITION.STM_LOCATION_ID%type default null
  , aCharac1Id      in STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type default null
  , aCharac2Id      in STM_STOCK_POSITION.GCO_GCO_CHARACTERIZATION_ID%type default null
  , aCharac3Id      in STM_STOCK_POSITION.GCO2_GCO_CHARACTERIZATION_ID%type default null
  , aCharac4Id      in STM_STOCK_POSITION.GCO3_GCO_CHARACTERIZATION_ID%type default null
  , aCharac5Id      in STM_STOCK_POSITION.GCO4_GCO_CHARACTERIZATION_ID%type default null
  , aCharVal1       in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type default null
  , aCharVal2       in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type default null
  , aCharVal3       in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type default null
  , aCharVal4       in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type default null
  , aCharVal5       in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type default null
  , aTransfer       in number default 0
  , iCheckStockCond in number default 1
  )
    return number
  is
  begin
    if aTransfer = '0' then
      return STM_I_LIB_STOCK_POSITION.getSumRealStockQty(iGoodID                   => aGoodId
                                                       , iStockID                  => aStockId
                                                       , iLocationID               => aLocationId
                                                       , iCharacterizationID1      => aCharac1Id
                                                       , iCharacterizationID2      => aCharac2Id
                                                       , iCharacterizationID3      => aCharac3Id
                                                       , iCharacterizationID4      => aCharac4Id
                                                       , iCharacterizationID5      => aCharac5Id
                                                       , iCharacterizationValue1   => aCharVal1
                                                       , iCharacterizationValue2   => aCharVal2
                                                       , iCharacterizationValue3   => aCharVal3
                                                       , iCharacterizationValue4   => aCharVal4
                                                       , iCharacterizationValue5   => aCharVal5
                                                       , iCheckStockCond           => iCheckStockCond
                                                        );
    else
      return STM_I_LIB_STOCK_POSITION.getSumStockQty(iGoodID                   => aGoodId
                                                   , iStockID                  => aStockId
                                                   , iLocationID               => aLocationId
                                                   , iCharacterizationID1      => aCharac1Id
                                                   , iCharacterizationID2      => aCharac2Id
                                                   , iCharacterizationID3      => aCharac3Id
                                                   , iCharacterizationID4      => aCharac4Id
                                                   , iCharacterizationID5      => aCharac5Id
                                                   , iCharacterizationValue1   => aCharVal1
                                                   , iCharacterizationValue2   => aCharVal2
                                                   , iCharacterizationValue3   => aCharVal3
                                                   , iCharacterizationValue4   => aCharVal4
                                                   , iCharacterizationValue5   => aCharVal5
                                                   , iCheckStockCond           => iCheckStockCond
                                                    );
    end if;
  end GetRealStockQuantity;

  /**
  * Description
  *   recherche la date du premier mouvement d'entrée pour un article donné
  */
  function GetFirstMoveDate(aGoodId in varchar2, aMvtSort in varchar2)
    return date
  is
    result date;
  begin
    select min(smo.smo_movement_date)
      into result
      from stm_stock_movement smo
         , stm_movement_kind mok
     where smo.stm_movement_kind_id = mok.stm_movement_kind_id
       and (   aMvtSort is null
            or mok.c_movement_sort = aMvtSort)
       and smo.gco_good_id = aGoodId;

    return result;
  end GetFirstMoveDate;

  /**
  * Description
  *   recherche la date du premier mouvement d'entrée pour un article donné
  */
  function GetLastMoveDate(aGoodId in varchar2, aMvtSort in varchar2)
    return date
  is
    result date;
  begin
    select max(smo.smo_movement_date)
      into result
      from stm_stock_movement smo
         , stm_movement_kind mok
     where smo.stm_movement_kind_id = mok.stm_movement_kind_id
       and (   aMvtSort is null
            or mok.c_movement_sort = aMvtSort)
       and smo.gco_good_id = aGoodId;

    return result;
  end GetLastMoveDate;

  /**
  * function IsVirtualStock
  * Description
  *   Indique si le stock passé en param est un stock virtuel
  */
  function IsVirtualStock(aStockID in number)
    return integer
  is
    result integer;
  begin
    begin
      select decode(upper(C_ACCESS_METHOD), 'DEFAULT', 1, 0)
        into result
        from STM_STOCK
       where STM_STOCK_ID = aStockID;
    exception
      when no_data_found then
        result  := 0;
    end;

    return result;
  end IsVirtualStock;

  /**
  * Function GetQuantity
  * Description :
  *             Retourne la quantité disponible selon le bien/stock/emplacement et les caractérisations
  */
  function GetQuantity(
    good_id     in STM_STOCK_POSITION.GCO_GOOD_ID%type
  , stock_id    in STM_STOCK_POSITION.STM_STOCK_ID%type
  , location_id in STM_STOCK_POSITION.STM_LOCATION_ID%type
  , charac1_id  in STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type
  , charac2_id  in STM_STOCK_POSITION.GCO_GCO_CHARACTERIZATION_ID%type
  , charac3_id  in STM_STOCK_POSITION.GCO2_GCO_CHARACTERIZATION_ID%type
  , charac4_id  in STM_STOCK_POSITION.GCO3_GCO_CHARACTERIZATION_ID%type
  , charac5_id  in STM_STOCK_POSITION.GCO4_GCO_CHARACTERIZATION_ID%type
  , char_val_1  in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , char_val_2  in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type
  , char_val_3  in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type
  , char_val_4  in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type
  , char_val_5  in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type
  , qtyToReturn in varchar2
  )
    return number
  is
  begin
    if qtyToReturn = 'STOCK' then
      return STM_I_LIB_STOCK_POSITION.getSumStockQty(iGoodID                   => good_id
                                                   , iStockID                  => stock_id
                                                   , iLocationID               => location_id
                                                   , iCharacterizationID1      => charac1_id
                                                   , iCharacterizationID2      => charac2_id
                                                   , iCharacterizationID3      => charac3_id
                                                   , iCharacterizationID4      => charac4_id
                                                   , iCharacterizationID5      => charac5_id
                                                   , iCharacterizationValue1   => char_val_1
                                                   , iCharacterizationValue2   => char_val_2
                                                   , iCharacterizationValue3   => char_val_3
                                                   , iCharacterizationValue4   => char_val_4
                                                   , iCharacterizationValue5   => char_val_5
                                                    );
    else
      return STM_I_LIB_STOCK_POSITION.getSumAvailableQty(iGoodID                   => good_id
                                                       , iStockID                  => stock_id
                                                       , iLocationID               => location_id
                                                       , iCharacterizationID1      => charac1_id
                                                       , iCharacterizationID2      => charac2_id
                                                       , iCharacterizationID3      => charac3_id
                                                       , iCharacterizationID4      => charac4_id
                                                       , iCharacterizationID5      => charac5_id
                                                       , iCharacterizationValue1   => char_val_1
                                                       , iCharacterizationValue2   => char_val_2
                                                       , iCharacterizationValue3   => char_val_3
                                                       , iCharacterizationValue4   => char_val_4
                                                       , iCharacterizationValue5   => char_val_5
                                                        );
    end if;
  end GetQuantity;
end STM_FUNCTIONS;
