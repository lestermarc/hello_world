--------------------------------------------------------
--  DDL for Package Body STM_LIB_STOCK_POSITION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_LIB_STOCK_POSITION" 
is
  cursor crStkChar(
    char1_id  STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type
  , char2_id  STM_STOCK_POSITION.GCO_GCO_CHARACTERIZATION_ID%type
  , char3_id  STM_STOCK_POSITION.GCO2_GCO_CHARACTERIZATION_ID%type
  , char4_id  STM_STOCK_POSITION.GCO3_GCO_CHARACTERIZATION_ID%type
  , char5_id  STM_STOCK_POSITION.GCO4_GCO_CHARACTERIZATION_ID%type
  , char1_val STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , char2_val STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type
  , char3_val STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type
  , char4_val STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type
  , char5_val STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type
  )
  is
    select   GCO_CHARACTERIZATION_ID
           , char1_val char_value
           , 1 ordre
        from GCO_CHARACTERIZATION CHA
           , GCO_PRODUCT PDT
       where GCO_CHARACTERIZATION_ID = char1_id
         and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
         and CHA_STOCK_MANAGEMENT = 1
         and PDT_STOCK_MANAGEMENT = 1
    union
    select   GCO_CHARACTERIZATION_ID
           , char2_val char_value
           , 2 ordre
        from GCO_CHARACTERIZATION CHA
           , GCO_PRODUCT PDT
       where GCO_CHARACTERIZATION_ID = char2_id
         and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
         and CHA_STOCK_MANAGEMENT = 1
         and PDT_STOCK_MANAGEMENT = 1
    union
    select   GCO_CHARACTERIZATION_ID
           , char3_val char_value
           , 3 ordre
        from GCO_CHARACTERIZATION CHA
           , GCO_PRODUCT PDT
       where GCO_CHARACTERIZATION_ID = char3_id
         and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
         and CHA_STOCK_MANAGEMENT = 1
         and PDT_STOCK_MANAGEMENT = 1
    union
    select   GCO_CHARACTERIZATION_ID
           , char4_val char_value
           , 4 ordre
        from GCO_CHARACTERIZATION CHA
           , GCO_PRODUCT PDT
       where GCO_CHARACTERIZATION_ID = char4_id
         and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
         and CHA_STOCK_MANAGEMENT = 1
         and PDT_STOCK_MANAGEMENT = 1
    union
    select   GCO_CHARACTERIZATION_ID
           , char5_val char_value
           , 5 ordre
        from GCO_CHARACTERIZATION CHA
           , GCO_PRODUCT PDT
       where GCO_CHARACTERIZATION_ID = char5_id
         and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
         and CHA_STOCK_MANAGEMENT = 1
         and PDT_STOCK_MANAGEMENT = 1
    order by 3;

  /**
  * Description
  *    Return a tuple of stock position
  */
  function GetStockPositionTuple(iStockPositionId in STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type)
    return STM_STOCK_POSITION%rowtype
  is
    lTplStockPosition STM_STOCK_POSITION%rowtype;
  begin
    select *
      into lTplStockPosition
      from STM_STOCK_POSITION
     where STM_STOCK_POSITION_ID = iStockPositionId;

    return lTplStockPosition;
  exception
    when no_data_found then
      return null;
  end GetStockPositionTuple;

  /**
  * Description
  *    Return a tuple of stock position
  */
  function GetStockPositionTuple(
    iGoodId     in STM_STOCK_POSITION.GCO_GOOD_ID%type
  , iStockId    in STM_STOCK_POSITION.STM_STOCK_ID%type default null
  , iLocationId in STM_STOCK_POSITION.STM_LOCATION_ID%type
  , iDateRef    in date default sysdate
  , iCharValue1 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type default null
  , iCharValue2 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type default null
  , iCharValue3 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type default null
  , iCharValue4 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type default null
  , iCharValue5 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type default null
  )
    return STM_STOCK_POSITION%rowtype
  is
    lTplStockPosition STM_STOCK_POSITION%rowtype;
    lTplResult        STM_STOCK_POSITION%rowtype;
  begin
    for lTplStockPosition in (select *
                                from STM_STOCK_POSITION
                               where GCO_GOOD_ID = iGoodId
                                 and STM_STOCK_ID = nvl(iStockId, STM_STOCK_ID)
                                 and STM_LOCATION_ID = iLocationId
                                 and (    (GCO_I_LIB_CHARACTERIZATION.IsTimeLimitManagement(GCO_GOOD_ID) = 0)
                                      or (trunc(GCO_I_LIB_CHARACTERIZATION.ChronoFormatToDate(SPO_CHRONOLOGICAL
                                                                                            , GCO_I_LIB_CHARACTERIZATION.GetChronoCharID(GCO_GOOD_ID)
                                                                                             )
                                               ) -
                                          GCO_I_LIB_CHARACTERIZATION.getLapsingMarge(GCO_GOOD_ID) -
                                          trunc(iDateRef) >= 0
                                         )
                                     )
                                 and (   nvl(SPO_CHARACTERIZATION_VALUE_1, '[NULL]') = nvl(iCharValue1, '[NULL]')
                                      or iCharValue1 is null)
                                 and (   nvl(SPO_CHARACTERIZATION_VALUE_2, '[NULL]') = nvl(iCharValue2, '[NULL]')
                                      or iCharValue2 is null)
                                 and (   nvl(SPO_CHARACTERIZATION_VALUE_3, '[NULL]') = nvl(iCharValue3, '[NULL]')
                                      or iCharValue3 is null)
                                 and (   nvl(SPO_CHARACTERIZATION_VALUE_4, '[NULL]') = nvl(iCharValue4, '[NULL]')
                                      or iCharValue4 is null)
                                 and (   nvl(SPO_CHARACTERIZATION_VALUE_5, '[NULL]') = nvl(iCharValue5, '[NULL]')
                                      or iCharValue5 is null) ) loop
      if ltplResult.STM_STOCK_POSITION_ID is null then
        lTplResult  := lTplStockPosition;

        if iCharValue1 is null then
          lTplResult.SPO_CHARACTERIZATION_VALUE_1  := null;
        end if;

        if iCharValue2 is null then
          lTplResult.SPO_CHARACTERIZATION_VALUE_2  := null;
        end if;

        if iCharValue3 is null then
          lTplResult.SPO_CHARACTERIZATION_VALUE_3  := null;
        end if;

        if iCharValue4 is null then
          lTplResult.SPO_CHARACTERIZATION_VALUE_4  := null;
        end if;

        if iCharValue5 is null then
          lTplResult.SPO_CHARACTERIZATION_VALUE_5  := null;
        end if;
      else
        lTplResult.SPO_STOCK_QUANTITY         := lTplResult.SPO_STOCK_QUANTITY + lTplStockPosition.SPO_STOCK_QUANTITY;
        lTplResult.SPO_THEORETICAL_QUANTITY   := lTplResult.SPO_THEORETICAL_QUANTITY + lTplStockPosition.SPO_THEORETICAL_QUANTITY;
        lTplResult.SPO_PROVISORY_INPUT        := lTplResult.SPO_PROVISORY_INPUT + lTplStockPosition.SPO_PROVISORY_INPUT;
        lTplResult.SPO_PROVISORY_OUTPUT       := lTplResult.SPO_PROVISORY_OUTPUT + lTplStockPosition.SPO_PROVISORY_OUTPUT;
        lTplResult.SPO_AVAILABLE_QUANTITY     := lTplResult.SPO_AVAILABLE_QUANTITY + lTplStockPosition.SPO_AVAILABLE_QUANTITY;
        lTplResult.SPO_ASSIGN_QUANTITY        := lTplResult.SPO_ASSIGN_QUANTITY + lTplStockPosition.SPO_ASSIGN_QUANTITY;
        lTplResult.SPO_ALTERNATIV_QUANTITY_1  := lTplResult.SPO_ALTERNATIV_QUANTITY_1 + lTplStockPosition.SPO_ALTERNATIV_QUANTITY_1;
        lTplResult.SPO_ALTERNATIV_QUANTITY_2  := lTplResult.SPO_ALTERNATIV_QUANTITY_2 + lTplStockPosition.SPO_ALTERNATIV_QUANTITY_2;
        lTplResult.SPO_ALTERNATIV_QUANTITY_3  := lTplResult.SPO_ALTERNATIV_QUANTITY_3 + lTplStockPosition.SPO_ALTERNATIV_QUANTITY_3;
      end if;
    end loop;

    return lTplResult;
  exception
    when no_data_found then
      return null;
  end GetStockPositionTuple;

  /**
  * Description
  *    Return a tuple of stock position
  */
  function GetStockPositionTable(
    iGoodId     in STM_STOCK_POSITION.GCO_GOOD_ID%type
  , iStockId    in STM_STOCK_POSITION.STM_STOCK_ID%type default null
  , iLocationId in STM_STOCK_POSITION.STM_LOCATION_ID%type
  , iCharValue1 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type default null
  , iCharValue2 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type default null
  , iCharValue3 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type default null
  , iCharValue4 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type default null
  , iCharValue5 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type default null
  )
    return tTblStockPosition pipelined
  is
  begin
    pipe row(GetStockPositionTuple(iGoodId, iStockId, iLocationId, iCharValue1, iCharValue2, iCharValue3, iCharValue4, iCharValue5) );
  end GetStockPositionTable;

  /**
  * Description
  *    Retourne la position de stock
  */
  function GetStockPositionId(
    iGoodId     in STM_STOCK_POSITION.GCO_GOOD_ID%type
  , iLocationId in STM_STOCK_POSITION.STM_LOCATION_ID%type
  , iChar1Id    in STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , iChar2Id    in STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , iChar3Id    in STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , iChar4Id    in STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , iChar5Id    in STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , iCharValue1 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , iCharValue2 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type
  , iCharValue3 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type
  , iCharValue4 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type
  , iCharValue5 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type
  )
    return STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type
  is
    lStockPositionId stm_stock_position.stm_stock_position_id%type;
  begin
    begin
      select stm_stock_position_id
        into lStockPositionId
        from stm_stock_position
       where gco_good_id = iGoodId
         and stm_location_id = iLocationId
         and (     (   gco_characterization_id = iChar1Id
                    or (    iChar1Id is null
                        and gco_characterization_id is null) )
              and (   gco_gco_characterization_id = iChar2Id
                   or (    iChar2Id is null
                       and gco_gco_characterization_id is null) )
              and (   gco2_gco_characterization_id = iChar3Id
                   or (    iChar3Id is null
                       and gco2_gco_characterization_id is null) )
              and (   gco3_gco_characterization_id = iChar4Id
                   or (    iChar4Id is null
                       and gco3_gco_characterization_id is null) )
              and (   gco4_gco_characterization_id = iChar5Id
                   or (    iChar5Id is null
                       and gco4_gco_characterization_id is null) )
              and (   spo_characterization_value_1 = iCharValue1
                   or (    iCharValue1 is null
                       and spo_characterization_value_1 is null) )
              and (   spo_characterization_value_2 = iCharValue2
                   or (    iCharValue2 is null
                       and spo_characterization_value_2 is null) )
              and (   spo_characterization_value_3 = iCharValue3
                   or (    iCharValue3 is null
                       and spo_characterization_value_3 is null) )
              and (   spo_characterization_value_4 = iCharValue4
                   or (    iCharValue4 is null
                       and spo_characterization_value_4 is null) )
              and (   spo_characterization_value_5 = iCharValue5
                   or (    iCharValue5 is null
                       and spo_characterization_value_5 is null) )
             );
    exception
      when no_data_found then
        lStockPositionId  := null;
    end;

    return lStockPositionId;
  end GetStockPositionId;

  /**
  * Description
  *    Return a tuple of stock position
  */
  function TableStockEvolution(
    iGoodId     in STM_STOCK_POSITION.GCO_GOOD_ID%type
  , iStockId    in STM_STOCK_POSITION.STM_STOCK_ID%type default null
  , iLocationId in STM_STOCK_POSITION.STM_LOCATION_ID%type default null
  , iDateRef    in date default sysdate
  , iCharValue1 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type default null
  , iCharValue2 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type default null
  , iCharValue3 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type default null
  , iCharValue4 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type default null
  , iCharValue5 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type default null
  )
    return ttStockQuantityDate pipelined
  is
    lCumulQty STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type   := 0;
  begin
    for lTplStockMovement in (select   SMO.STM_STOCK_MOVEMENT_ID
                                     , SMO.SMO_MOVEMENT_DATE
                                     , MOK.MOK_ABBREVIATION
                                     , MOK.C_MOVEMENT_SORT
                                     , MOK.C_MOVEMENT_TYPE
                                     , MOK.C_MOVEMENT_CODE
                                     , MOK.MOK_COSTPRICE_USE
                                     , MOK.MOK_STANDARD_SIGN
                                     , SMO.SMO_WORDING
                                     , SMO.SMO_MOVEMENT_QUANTITY
                                     , SMO.SMO_MOVEMENT_QUANTITY REAL_MOVEMENT_QUANTITY
                                     , SMO.SMO_MOVEMENT_QUANTITY SPO_STOCK_QUANTITY
                                  from STM_STOCK_MOVEMENT SMO
                                     , STM_MOVEMENT_KIND MOK
                                 where SMO.GCO_GOOD_ID = iGoodId
                                   and MOK.STM_MOVEMENT_KIND_ID = SMO.STM_MOVEMENT_KIND_ID
                                   and SMO.STM_STOCK_ID = nvl(iStockId, SMO.STM_STOCK_ID)
                                   and SMO.STM_LOCATION_ID = nvl(iLocationId, SMO.STM_LOCATION_ID)
                                   and (    (GCO_I_LIB_CHARACTERIZATION.IsTimeLimitManagement(SMO.GCO_GOOD_ID) = 0)
                                        or (to_date(SMO_CHRONOLOGICAL, 'YYYYMMDD') - GCO_I_LIB_CHARACTERIZATION.getLapsingMarge(SMO.GCO_GOOD_ID)
                                            - trunc(iDateRef) >= 0
                                           )
                                       )
                                   and (   nvl(SMO_CHARACTERIZATION_VALUE_1, '[NULL]') = nvl(iCharValue1, '[NULL]')
                                        or iCharValue1 is null)
                                   and (   nvl(SMO_CHARACTERIZATION_VALUE_2, '[NULL]') = nvl(iCharValue2, '[NULL]')
                                        or iCharValue2 is null)
                                   and (   nvl(SMO_CHARACTERIZATION_VALUE_3, '[NULL]') = nvl(iCharValue3, '[NULL]')
                                        or iCharValue3 is null)
                                   and (   nvl(SMO_CHARACTERIZATION_VALUE_4, '[NULL]') = nvl(iCharValue4, '[NULL]')
                                        or iCharValue4 is null)
                                   and (   nvl(SMO_CHARACTERIZATION_VALUE_5, '[NULL]') = nvl(iCharValue5, '[NULL]')
                                        or iCharValue5 is null)
                              order by STM_STOCK_MOVEMENT_ID) loop
      if lTplStockMovement.C_MOVEMENT_TYPE <> 'EXE' then
        if lTplStockMovement.C_MOVEMENT_SORT = 'ENT' then
          lCumulQty                                 := lCumulQty + lTplStockMovement.SMO_MOVEMENT_QUANTITY * lTplStockMovement.MOK_STANDARD_SIGN;
          lTplStockMovement.REAL_MOVEMENT_QUANTITY  := lTplStockMovement.SMO_MOVEMENT_QUANTITY * lTplStockMovement.MOK_STANDARD_SIGN;
        else
          lCumulQty                                 := lCumulQty - lTplStockMovement.SMO_MOVEMENT_QUANTITY * lTplStockMovement.MOK_STANDARD_SIGN;
          lTplStockMovement.REAL_MOVEMENT_QUANTITY  := -lTplStockMovement.SMO_MOVEMENT_QUANTITY * lTplStockMovement.MOK_STANDARD_SIGN;
        end if;

        lTplStockMovement.SPO_STOCK_QUANTITY  := lCumulQty;
        pipe row(lTplStockMovement);
      end if;
    end loop;
  end TableStockEvolution;

  /**
  * Description
  *   Retourne 1 si au moins une position de stock est négative pour le stock
  */
  function HasStockNegativePosition(iStockId in STM_STOCK_POSITION.STM_STOCK_ID%type)
    return number
  is
    lCount pls_integer;
  begin
    select count(*)
      into lCount
      from STM_STOCK_POSITION
     where SPO_STOCK_QUANTITY < 0
       and STM_STOCK_ID = iStockId;

    return sign(lCount);
  end HasStockNegativePosition;

  /**
  * Description
  *   Retourne 1 si au moins une position de stock est négative  pour le bien
  */
  function HasGoodNegativePosition(iGoodId in STM_STOCK_POSITION.GCO_GOOD_ID%type)
    return number
  is
    lCount pls_integer;
  begin
    select count(*)
      into lCount
      from STM_STOCK_POSITION
     where SPO_STOCK_QUANTITY < 0
       and GCO_GOOD_ID = iGoodId;

    return sign(lCount);
  end HasGoodNegativePosition;

  /**
  * Description
  *   Retourne la quantité définie pour le bien. Possibilité de restreindre la
  *   somme sur le stock, la position ou les charactérisations.
  */
  function getSumQuantity(
    iGoodID                 in STM_STOCK_POSITION.GCO_GOOD_ID%type
  , iStockID                in STM_STOCK_POSITION.STM_STOCK_ID%type
  , iLocationID             in STM_STOCK_POSITION.STM_LOCATION_ID%type
  , iCharacterizationID1    in STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type
  , iCharacterizationID2    in STM_STOCK_POSITION.GCO_GCO_CHARACTERIZATION_ID%type
  , iCharacterizationID3    in STM_STOCK_POSITION.GCO2_GCO_CHARACTERIZATION_ID%type
  , iCharacterizationID4    in STM_STOCK_POSITION.GCO3_GCO_CHARACTERIZATION_ID%type
  , iCharacterizationID5    in STM_STOCK_POSITION.GCO4_GCO_CHARACTERIZATION_ID%type
  , iCharacterizationValue1 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , iCharacterizationValue2 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type
  , iCharacterizationValue3 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type
  , iCharacterizationValue4 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type
  , iCharacterizationValue5 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type
  , iQuantityToReturn       in varchar2
  , iCheckStockCond         in number
  , iMovementDate           in date
  , iMovementKindId         in STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type
  )
    return STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type
  as
    lnSumAvailableQty        STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;
    lnSumStockQty            STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
    lnSumRealStockQty        STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
    lnOrdre                  number(1);
    lCharacterizationID1     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharacterizationID2     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharacterizationID3     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharacterizationID4     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharacterizationID5     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lvCharacterizationValue1 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
    lvCharacterizationValue2 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type;
    lvCharacterizationValue3 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type;
    lvCharacterizationValue4 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type;
    lvCharacterizationValue5 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type;
  begin
    -- si on a des caractérisation, vérification qu'elles soient gêrées en stock
    -- pour leur prise en compte dans la recehrche de la quantité
    if (iCharacterizationID1 is not null) then
      open STM_LIB_STOCK_POSITION.crStkChar(iCharacterizationID1
                                          , iCharacterizationID2
                                          , iCharacterizationID3
                                          , iCharacterizationID4
                                          , iCharacterizationID5
                                          , iCharacterizationValue1
                                          , iCharacterizationValue2
                                          , iCharacterizationValue3
                                          , iCharacterizationValue4
                                          , iCharacterizationValue5
                                           );

      fetch crStkChar
       into lCharacterizationID1
          , lvCharacterizationValue1
          , lnOrdre;

      fetch crStkChar
       into lCharacterizationID2
          , lvCharacterizationValue2
          , lnOrdre;

      fetch crStkChar
       into lCharacterizationID3
          , lvCharacterizationValue3
          , lnOrdre;

      fetch crStkChar
       into lCharacterizationID4
          , lvCharacterizationValue4
          , lnOrdre;

      fetch crStkChar
       into lCharacterizationID5
          , lvCharacterizationValue5
          , lnOrdre;

      close crStkChar;
    end if;

    select nvl(sum(SPO.SPO_AVAILABLE_QUANTITY), 0)
         , nvl(sum(SPO.SPO_STOCK_QUANTITY), 0)
         , nvl(sum(SPO.SPO_STOCK_QUANTITY), 0) - nvl(sum(SPO.SPO_ASSIGN_QUANTITY), 0)
      into lnSumAvailableQty
         , lnSumStockQty
         , lnSumRealStockQty
      from STM_STOCK_POSITION SPO
         , STM_ELEMENT_NUMBER SEM
     where SPO.GCO_GOOD_ID = iGoodID
       and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID(+)
       and (   iCheckStockCond = 0
            or STM_I_LIB_MOVEMENT.VerifyStockOutputCond(iGoodId            => SPO.GCO_GOOD_ID
                                                      , iStockId           => SPO.STM_STOCK_ID
                                                      , iLocationId        => SPO.STM_LOCATION_ID
                                                      , iQualityStatusId   => SEM.GCO_QUALITY_STATUS_ID
                                                      , iChronological     => SPO.SPO_CHRONOLOGICAL
                                                      , iPiece             => SPO.SPO_PIECE
                                                      , iSet               => SPO.SPO_SET
                                                      , iVersion           => SPO.SPO_VERSION
                                                      , iMovementKindId    => iMovementKindId
                                                      , iMovementDate      => iMovementDate
                                                       ) is null
           )
       and (   SPO.STM_STOCK_ID = iStockID
            or nvl(iStockID, 0) = 0)
       and (   SPO.STM_LOCATION_ID = iLocationID
            or nvl(iLocationID, 0) = 0)
       and (    (    SPO.GCO_CHARACTERIZATION_ID = lCharacterizationID1
                 and SPO.SPO_CHARACTERIZATION_VALUE_1 = lvCharacterizationValue1)
            or nvl(lCharacterizationID1, 0) = 0
           )
       and (    (    SPO.GCO_GCO_CHARACTERIZATION_ID = lCharacterizationID2
                 and SPO.SPO_CHARACTERIZATION_VALUE_2 = lvCharacterizationValue2)
            or nvl(lCharacterizationID2, 0) = 0
           )
       and (    (    SPO.GCO2_GCO_CHARACTERIZATION_ID = lCharacterizationID3
                 and SPO.SPO_CHARACTERIZATION_VALUE_3 = lvCharacterizationValue3)
            or nvl(lCharacterizationID3, 0) = 0
           )
       and (    (    SPO.GCO3_GCO_CHARACTERIZATION_ID = lCharacterizationID4
                 and SPO.SPO_CHARACTERIZATION_VALUE_4 = lvCharacterizationValue4)
            or nvl(lCharacterizationID4, 0) = 0
           )
       and (    (    SPO.GCO4_GCO_CHARACTERIZATION_ID = lCharacterizationID5
                 and SPO.SPO_CHARACTERIZATION_VALUE_5 = lvCharacterizationValue5)
            or nvl(lCharacterizationID5, 0) = 0
           );

    if upper(iQuantityToReturn) = 'SPO_AVAILABLE_QUANTITY' then
      return lnSumAvailableQty;
    elsif upper(iQuantityToReturn) = 'SPO_STOCK_QUANTITY' then
      return lnSumStockQty;
    elsif upper(iQuantityToReturn) = 'SPO_REAL_STOCK_QUANTITY' then
      return lnSumRealStockQty;
    else
      ra('PCS - Invalid param value when calling function STM_LIB_STOCK_POSITION.getSumQuantity ! Param : iQuantityToReturn');
    end if;
  end getSumQuantity;

  /**
  * Description
  *   Retourne La quantité disponible pour le bien. Possibilité de restreindre la
  *   somme sur le stock, la position ou les charactérisations.
  */
  function getSumAvailableQty(
    iGoodID                 in STM_STOCK_POSITION.GCO_GOOD_ID%type
  , iStockID                in STM_STOCK_POSITION.STM_STOCK_ID%type default null
  , iLocationID             in STM_STOCK_POSITION.STM_LOCATION_ID%type default null
  , iCharacterizationID1    in STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationID2    in STM_STOCK_POSITION.GCO_GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationID3    in STM_STOCK_POSITION.GCO2_GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationID4    in STM_STOCK_POSITION.GCO3_GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationID5    in STM_STOCK_POSITION.GCO4_GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationValue1 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type default null
  , iCharacterizationValue2 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type default null
  , iCharacterizationValue3 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type default null
  , iCharacterizationValue4 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type default null
  , iCharacterizationValue5 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type default null
  , iCheckStockCond         in number default 1
  , iMovementDate           in date default sysdate
  , iMovementKindId         in STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type default null
  )
    return STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type
  as
  begin
    return getSumQuantity(iGoodID                   => iGoodID
                        , iStockID                  => iStockID
                        , iLocationID               => iLocationID
                        , iCharacterizationID1      => iCharacterizationID1
                        , iCharacterizationID2      => iCharacterizationID2
                        , iCharacterizationID3      => iCharacterizationID3
                        , iCharacterizationID4      => iCharacterizationID4
                        , iCharacterizationID5      => iCharacterizationID5
                        , iCharacterizationValue1   => iCharacterizationValue1
                        , iCharacterizationValue2   => iCharacterizationValue2
                        , iCharacterizationValue3   => iCharacterizationValue3
                        , iCharacterizationValue4   => iCharacterizationValue4
                        , iCharacterizationValue5   => iCharacterizationValue5
                        , iQuantityToReturn         => 'SPO_AVAILABLE_QUANTITY'
                        , iCheckStockCond           => iCheckStockCond
                        , iMovementDate             => iMovementDate
                        , iMovementKindId           => iMovementKindId
                         );
  end getSumAvailableQty;

  /**
  * Description
  *   Retourne La quantité en stock pour le bien. Possibilité de restreindre la
  *   somme sur le stock, la position ou les charactérisations.
  */
  function getSumStockQty(
    iGoodID                 in STM_STOCK_POSITION.GCO_GOOD_ID%type
  , iStockID                in STM_STOCK_POSITION.STM_STOCK_ID%type default null
  , iLocationID             in STM_STOCK_POSITION.STM_LOCATION_ID%type default null
  , iCharacterizationID1    in STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationID2    in STM_STOCK_POSITION.GCO_GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationID3    in STM_STOCK_POSITION.GCO2_GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationID4    in STM_STOCK_POSITION.GCO3_GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationID5    in STM_STOCK_POSITION.GCO4_GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationValue1 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type default null
  , iCharacterizationValue2 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type default null
  , iCharacterizationValue3 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type default null
  , iCharacterizationValue4 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type default null
  , iCharacterizationValue5 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type default null
  , iCheckStockCond         in number default 1
  , iMovementDate           in date default sysdate
  , iMovementKindId         in STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type default null
  )
    return STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type
  as
  begin
    return getSumQuantity(iGoodID                   => iGoodID
                        , iStockID                  => iStockID
                        , iLocationID               => iLocationID
                        , iCharacterizationID1      => iCharacterizationID1
                        , iCharacterizationID2      => iCharacterizationID2
                        , iCharacterizationID3      => iCharacterizationID3
                        , iCharacterizationID4      => iCharacterizationID4
                        , iCharacterizationID5      => iCharacterizationID5
                        , iCharacterizationValue1   => iCharacterizationValue1
                        , iCharacterizationValue2   => iCharacterizationValue2
                        , iCharacterizationValue3   => iCharacterizationValue3
                        , iCharacterizationValue4   => iCharacterizationValue4
                        , iCharacterizationValue5   => iCharacterizationValue5
                        , iQuantityToReturn         => 'SPO_STOCK_QUANTITY'
                        , iCheckStockCond           => iCheckStockCond
                        , iMovementDate             => iMovementDate
                        , iMovementKindId           => iMovementKindId
                         );
  end getSumStockQty;

  /**
  * Description
  *   Retourne La quantité en stock - la quantité assignée pour le bien. Possibilité
  *   de restreindre la somme sur le stock, la position ou les charactérisations.
  */
  function getSumRealStockQty(
    iGoodID                 in STM_STOCK_POSITION.GCO_GOOD_ID%type
  , iStockID                in STM_STOCK_POSITION.STM_STOCK_ID%type default null
  , iLocationID             in STM_STOCK_POSITION.STM_LOCATION_ID%type default null
  , iCharacterizationID1    in STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationID2    in STM_STOCK_POSITION.GCO_GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationID3    in STM_STOCK_POSITION.GCO2_GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationID4    in STM_STOCK_POSITION.GCO3_GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationID5    in STM_STOCK_POSITION.GCO4_GCO_CHARACTERIZATION_ID%type default null
  , iCharacterizationValue1 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type default null
  , iCharacterizationValue2 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type default null
  , iCharacterizationValue3 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type default null
  , iCharacterizationValue4 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type default null
  , iCharacterizationValue5 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type default null
  , iCheckStockCond         in number default 1
  , iMovementDate           in date default sysdate
  , iMovementKindId         in STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type default null
  )
    return STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type
  as
  begin
    return getSumQuantity(iGoodID                   => iGoodID
                        , iStockID                  => iStockID
                        , iLocationID               => iLocationID
                        , iCharacterizationID1      => iCharacterizationID1
                        , iCharacterizationID2      => iCharacterizationID2
                        , iCharacterizationID3      => iCharacterizationID3
                        , iCharacterizationID4      => iCharacterizationID4
                        , iCharacterizationID5      => iCharacterizationID5
                        , iCharacterizationValue1   => iCharacterizationValue1
                        , iCharacterizationValue2   => iCharacterizationValue2
                        , iCharacterizationValue3   => iCharacterizationValue3
                        , iCharacterizationValue4   => iCharacterizationValue4
                        , iCharacterizationValue5   => iCharacterizationValue5
                        , iQuantityToReturn         => 'SPO_REAL_STOCK_QUANTITY'
                        , iCheckStockCond           => iCheckStockCond
                        , iMovementDate             => iMovementDate
                        , iMovementKindId           => iMovementKindId
                         );
  end getSumRealStockQty;

  function ControlPieceUnicity(
    iGoodID      in STM_STOCK_POSITION.GCO_GOOD_ID%type
  , iLocationId  in STM_STOCK_POSITION.STM_LOCATION_ID%type
  , iPieceNumber in STM_STOCK_POSITION.SPO_PIECE%type
  )
    return number
  is
    lCount pls_integer;
  begin
    if STM_I_LIB_CONSTANT.gcCfgPieceSglNumberingComp then
      -- recherche si une position de stock possède déjà de la quantité en stock
      select count(*)
        into lCount
        from STM_STOCK_POSITION
       where SPO_PIECE = iPieceNumber
         and SPO_STOCK_QUANTITY > 0;

      if lCount > 0 then
        return 0;
      else
        --recherche si une entrée provisoire est déjà programmée sur un autre stock
        select count(*)
          into lCount
          from STM_STOCK_POSITION
         where STM_LOCATION_ID <> iLocationId
           and SPO_PIECE = iPieceNumber
           and (   SPO_PROVISORY_INPUT > 0
                or SPO_PROVISORY_OUTPUT < 0);

        if lCount > 0 then
          return 0;
        else
          return 1;
        end if;
      end if;
    else
      -- recherche si une position de stock possède déjà de la quantité en stock
      select count(*)
        into lCount
        from STM_STOCK_POSITION
       where GCO_GOOD_ID = iGoodId
         and SPO_PIECE = iPieceNumber
         and SPO_STOCK_QUANTITY > 0;

      if lCount > 0 then
        return 0;
      else
        --recherche si une entrée provisoire est déjà programmée sur un autre stock
        select count(*)
          into lCount
          from STM_STOCK_POSITION
         where GCO_GOOD_ID = iGoodId
           and STM_LOCATION_ID <> iLocationId
           and SPO_PIECE = iPieceNumber
           and (   SPO_PROVISORY_INPUT > 0
                or SPO_PROVISORY_OUTPUT < 0);

        if lCount > 0 then
          return 0;
        else
          return 1;
        end if;
      end if;
    end if;
  end ControlPieceUnicity;

  /**
  * function GetCharactSumQty
  * Description
  *   Retourne La quantité totale d'une seule valeur de caractérisation d'un bien (même s'il en possède plusieurs).
  *     La quantité retournée dépend du paramètre iQuantityToReturn
  */
  function GetCharactSumQty(
    iGoodID           in STM_STOCK_POSITION.GCO_GOOD_ID%type
  , iStockID          in STM_STOCK_POSITION.STM_STOCK_ID%type default null
  , iLocationID       in STM_STOCK_POSITION.STM_LOCATION_ID%type default null
  , iCharID           in STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type default null
  , iCharValue        in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type default null
  , iQuantityToReturn in varchar2
  )
    return number
  is
    lnSumAvailableQty STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;
    lnSumStockQty     STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
    lnSumRealStockQty STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
    lCharID1          STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type;
    lCharID2          STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type;
    lCharID3          STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type;
    lCharID4          STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type;
    lCharID5          STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type;
    lCharValue1       STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
    lCharValue2       STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
    lCharValue3       STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
    lCharValue4       STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
    lCharValue5       STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
  begin
    GCO_LIB_CHARACTERIZATION.GetAllCharactID(iGoodId        => iGoodID
                                           , oCharactID_1   => lCharID1
                                           , oCharactID_2   => lCharID2
                                           , oCharactID_3   => lCharID3
                                           , oCharactID_4   => lCharID4
                                           , oCharactID_5   => lCharID5
                                            );

    -- Effectuer la correspondance de l'ID et valeur de la caractérisation
    if iCharID is not null then
      if iCharID = lCharID1 then
        lCharValue1  := iCharValue;
      elsif iCharID = lCharID2 then
        lCharValue2  := iCharValue;
      elsif iCharID = lCharID3 then
        lCharValue3  := iCharValue;
      elsif iCharID = lCharID4 then
        lCharValue4  := iCharValue;
      elsif iCharID = lCharID5 then
        lCharValue5  := iCharValue;
      end if;
    end if;

    -- Somme des qtés
    select nvl(sum(SPO_AVAILABLE_QUANTITY), 0)
         , nvl(sum(SPO_STOCK_QUANTITY), 0)
         , nvl(sum(SPO_STOCK_QUANTITY), 0) - nvl(sum(SPO_ASSIGN_QUANTITY), 0)
      into lnSumAvailableQty
         , lnSumStockQty
         , lnSumRealStockQty
      from STM_STOCK_POSITION
     where GCO_GOOD_ID = iGoodID
       and (   STM_STOCK_ID = iStockID
            or nvl(iStockID, 0) = 0)
       and (   STM_LOCATION_ID = iLocationID
            or nvl(iLocationID, 0) = 0)
       and coalesce(GCO_CHARACTERIZATION_ID, 0) = coalesce(lCharID1, 0)
       and coalesce(SPO_CHARACTERIZATION_VALUE_1, '[NULL]') = coalesce(lCharValue1, SPO_CHARACTERIZATION_VALUE_1, '[NULL]')
       and coalesce(GCO_GCO_CHARACTERIZATION_ID, 0) = coalesce(lCharID2, 0)
       and coalesce(SPO_CHARACTERIZATION_VALUE_2, '[NULL]') = coalesce(lCharValue2, SPO_CHARACTERIZATION_VALUE_2, '[NULL]')
       and coalesce(GCO2_GCO_CHARACTERIZATION_ID, 0) = coalesce(lCharID3, 0)
       and coalesce(SPO_CHARACTERIZATION_VALUE_3, '[NULL]') = coalesce(lCharValue3, SPO_CHARACTERIZATION_VALUE_3, '[NULL]')
       and coalesce(GCO3_GCO_CHARACTERIZATION_ID, 0) = coalesce(lCharID4, 0)
       and coalesce(SPO_CHARACTERIZATION_VALUE_4, '[NULL]') = coalesce(lCharValue4, SPO_CHARACTERIZATION_VALUE_4, '[NULL]')
       and coalesce(GCO4_GCO_CHARACTERIZATION_ID, 0) = coalesce(lCharID5, 0)
       and coalesce(SPO_CHARACTERIZATION_VALUE_5, '[NULL]') = coalesce(lCharValue5, SPO_CHARACTERIZATION_VALUE_5, '[NULL]');

    if upper(iQuantityToReturn) = 'SPO_AVAILABLE_QUANTITY' then
      return lnSumAvailableQty;
    elsif upper(iQuantityToReturn) = 'SPO_STOCK_QUANTITY' then
      return lnSumStockQty;
    elsif upper(iQuantityToReturn) = 'SPO_REAL_STOCK_QUANTITY' then
      return lnSumRealStockQty;
    else
      ra('PCS - Invalid param value when calling function STM_LIB_STOCK_POSITION.GetSumQuantityCharsDisorder ! Param : iQuantityToReturn');
    end if;
  end GetCharactSumQty;

  /**
  * Description
  *   Recherche la quantité disponible pour un detail de caractérisation
  */
  function GetElementNumberAvailableQty(iElementNumberId in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type)
    return STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type
  is
    lResult STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;
  begin
    select sum(SPO_AVAILABLE_QUANTITY)
      into lResult
      from STM_STOCK_POSITION
     where GCO_GOOD_ID = FWK_I_LIB_ENTITY.getNumberFieldFromPk('STM_ELEMENT_NUMBER', 'GCO_GOOD_ID', iElementNumberId)   -- condition "indexée"
       and iElementNumberId in(STM_ELEMENT_NUMBER_ID, STM_STM_ELEMENT_NUMBER_ID, STM2_STM_ELEMENT_NUMBER_ID);

    return lResult;
  end GetElementNumberAvailableQty;

  /**
  * Description
  *   Détermine si la position de stock est périmée en fonction d'une date spécifiée
  */
  function IsOutdated(iStockPositionId in STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type, iDate in date default sysdate)
    return number
  is
    lResult         number(1)                                   := 0;
    lnGoodId        GCO_GOOD.GCO_GOOD_ID%type;
    lvChronological STM_STOCK_POSITION.SPO_CHRONOLOGICAL%type;
  begin
    begin
      select SPO.GCO_GOOD_ID
           , SPO.SPO_CHRONOLOGICAL
        into lnGoodId
           , lvChronological
        from STM_STOCK_POSITION SPO
       where SPO.STM_STOCK_POSITION_ID = iStockPositionId;
    exception
      when no_data_found then
        null;
    end;

    if lnGoodId is not null then
      lResult  := GCO_I_LIB_CHARACTERIZATION.IsOutdated(iGoodID => lnGoodId, iThirdId => null, iTimeLimitDate => lvChronological, iDate => iDate);
    end if;

    return lResult;
  end IsOutdated;

  /**
  * Description
  *   Détermine si la position de stock a dépassé sa date de ré-analyse en fonction d'une date spécifiée
  */
  function IsRetestNeeded(iStockPositionId in STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type, iDate in date)
    return number
  is
    lResult      number(1)                                 := 0;
    lnGoodId     GCO_GOOD.GCO_GOOD_ID%type;
    ldRetestDate STM_ELEMENT_NUMBER.SEM_RETEST_DATE%type;
  begin
    begin
      select SPO.GCO_GOOD_ID
           , SEM.SEM_RETEST_DATE
        into lnGoodId
           , ldRetestDate
        from STM_STOCK_POSITION SPO
           , STM_ELEMENT_NUMBER SEM
       where SPO.STM_STOCK_POSITION_ID = iStockPositionId
         and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID(+);
    exception
      when no_data_found then
        null;
    end;

    if     lnGoodId is not null
       and GCO_I_LIB_CHARACTERIZATION.IsRetestManagement(lnGoodId) = 1 then
      lResult  := GCO_I_LIB_CHARACTERIZATION.IsRetestNeeded(iGoodID => lnGoodId, iRetestDate => ldRetestDate, iDate => iDate);
    end if;

    return lResult;
  end IsRetestNeeded;

  /**
  * Description
  *   Détermine s'il existe des positions de stock pour un produit
  */
  function GoodWithStockPosition(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    lResult number(1);
  begin
    select sign(count(*) )
      into lResult
      from STM_STOCK_POSITION
     where GCO_GOOD_ID = iGoodId;

    return lResult;
  end GoodWithStockPosition;

  /**
  * Description
  *   Table function that return a list of stock position for the good and version asked
  */
  function GetVersionInProgress(iGoodId in STM_STOCK_POSITION.GCO_GOOD_ID%type, iVersion in STM_STOCK_POSITION.SPO_VERSION%type)
    return ID_TABLE_TYPE
  is
    lResult ID_TABLE_TYPE;
  begin
    select STM_STOCK_POSITION_ID
    bulk collect into lResult
      from STM_STOCK_POSITION SPO
         , STM_STOCK STO
     where SPO.GCO_GOOD_ID = iGoodId
       and STO.STM_STOCK_ID = SPO.STM_STOCK_ID
       and STO.C_ACCESS_METHOD = 'PUBLIC'
       and SPO.SPO_STOCK_QUANTITY <> 0
       and (   SPO_VERSION = iVersion
            or iVersion is null);

    return lResult;
  end GetVersionInProgress;

  /**
  * Description
  *   Return 1 if ther is something of the current version available in stock
  */
  function IsVersionInProgress(iGoodId in STM_STOCK_POSITION.GCO_GOOD_ID%type, iVersion in STM_STOCK_POSITION.SPO_VERSION%type)
    return number
  is
    lResult pls_integer;
  begin
    select sign(count(*) )
      into lResult
      from table(STM_LIB_STOCK_POSITION.GetVersionInProgress(iGoodId, iVersion) );

    return lResult;
  end IsVersionInProgress;
end STM_LIB_STOCK_POSITION;
