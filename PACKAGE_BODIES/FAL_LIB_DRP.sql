--------------------------------------------------------
--  DDL for Package Body FAL_LIB_DRP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_DRP" 
is
  procedure EvtSeekDistribUnitToDeliver(iDate in date, iDIUList out varchar)
  is
    lDeliveryPlanId STM_DELIVERY_PLAN.STM_DELIVERY_PLAN_ID%type;
    lTempVar        varchar(20);

    cursor document
    is
      select distinct sdu.STM_DISTRIBUTION_UNIT_ID
                 from STM_DISTRIBUTION_UNIT sdu
                    , STM_DELIVERY_S_DIU sdsd
                    , STM_DELIVERY_DAY sdd
                where (    sdu.STM_DISTRIBUTION_UNIT_ID = sdsd.STM_DISTRIBUTION_UNIT_ID
                       and sdsd.STM_DELIVERY_S_DIU_ID = sdd.STM_DELIVERY_S_DIU_ID
                       and (   sdd.DED_DATE = trunc(sysdate + nvl(sdu.DIU_PREPARE_TIME, 0) )
                            or sdd.DED_DATE = trunc(sysdate) )
                      );
  begin
    iDIUList  := '';

    begin
      select STM_DELIVERY_PLAN_ID
        into lDeliveryPlanId
        from STM_DELIVERY_PLAN
       where DPL_YEAR = to_char(nvl(iDate, sysdate), 'YYYY');
    exception
      when no_data_found then
        return;
    end;

    open document;

    fetch document
     into lTempVar;

    while document%found loop
      iDIUList  := concat(concat(iDIUList, lTempVar), ',');

      fetch document
       into lTempVar;
    end loop;

    select substr(iDIUList, 1, length(iDIUList) - 1)
      into iDIUList
      from dual;

    close document;
  end EvtSeekDistribUnitToDeliver;

  function IsDeliveryUnitValid(iDate in date, iDIU in STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type)
    return integer
  is
    lDeliveryPlan STM_DELIVERY_PLAN.STM_DELIVERY_PLAN_ID%type;
    lDIU          STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type;
  begin
    -- If there's no plan for the given date, return invalid
    begin
      select STM_DELIVERY_PLAN_ID
        into lDeliveryPlan
        from STM_DELIVERY_PLAN
       where DPL_YEAR = to_char(nvl(iDate, sysdate), 'YYYY');
    exception
      when no_data_found then
        return 0;
    end;

    -- If given Distribution Unit is blocked or nonexistent, return invalid
    begin
      select distinct sdu.STM_DISTRIBUTION_UNIT_ID
                 into lDIU
                 from STM_DISTRIBUTION_UNIT sdu
                    , STM_DELIVERY_S_DIU sdsd
                    , STM_DELIVERY_DAY sdd
                where (    sdu.STM_DISTRIBUTION_UNIT_ID = sdsd.STM_DISTRIBUTION_UNIT_ID
                       and sdsd.STM_DELIVERY_S_DIU_ID = sdd.STM_DELIVERY_S_DIU_ID
                       and (   sdd.DED_DATE = trunc(sysdate + nvl(sdu.DIU_PREPARE_TIME, 0) )
                            or sdd.DED_DATE = trunc(sysdate) )
                       and sdu.STM_DISTRIBUTION_UNIT_ID = iDIU
                      );
    exception
      when no_data_found then
        return 0;
    end;

    -- Given Distribution Unit is valid
    return 1;
  end IsDeliveryUnitValid;

/* ----------------------------------------------------------------------------------------------------------------------- */
  function GetStockAvailable(aGCO_GOOD_ID in number, aSTM_STOCK_ID in number, aSTM_LOCATION_ID in number)
    return number
  is
    vQty number;
  begin
    select nvl(sum(SPO.SPO_AVAILABLE_QUANTITY), 0)
      into vQty
      from STM_STOCK_POSITION SPO
         , STM_ELEMENT_NUMBER SEM
     where SPO.GCO_GOOD_ID(+) = aGCO_GOOD_ID
       and SPO.STM_STOCK_ID(+) = aSTM_STOCK_ID
       and SPO.STM_LOCATION_ID(+) = aSTM_LOCATION_ID
       and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID(+)
       and STM_I_LIB_MOVEMENT.VerifyForecastStockPosCond(iGoodId            => SPO.GCO_GOOD_ID
                                                       , iPiece             => SPO.SPO_PIECE
                                                       , iSet               => SPO.SPO_SET
                                                       , iVersion           => SPO.SPO_VERSION
                                                       , iChronological     => SPO.SPO_CHRONOLOGICAL
                                                       , iQualityStatusId   => SEM.GCO_QUALITY_STATUS_ID
                                                        ) is not null;

    return vQty;
  end GetStockAvailable;

/* -------------------------------------------------------------------------- */
  procedure GetStockPrvOutAndAvlQ(
    iGcoGoodId           in     GCO_GOOD.GCO_GOOD_ID%type
  , iStockMovementId     in     fal_doc_prop.stm_stock_movement_id%type
  , ioQProvisoryOutput   out    STM_STOCK_POSITION.SPO_PROVISORY_OUTPUT%type
  , ioQAvailableQuantity out    STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type
  )
  is
    lLocationId STM_STOCK_MOVEMENT.STM_LOCATION_ID%type;
    lStockId    STM_STOCK_MOVEMENT.STM_STOCK_ID%type;
    lGcoChar1   STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lGcoChar2   STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lGcoChar3   STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lGcoChar4   STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lGcoChar5   STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
  begin
    GetCharacterization(iGcoGoodId, iStockMovementId, lLocationId, lStockId, lGcoChar1, lGcoChar2, lGcoChar3, lGcoChar4, lGcoChar5);

    begin
      select nvl(sum(SPO.SPO_PROVISORY_OUTPUT), 0)
           , nvl(sum(SPO.SPO_AVAILABLE_QUANTITY), 0)
        into ioQProvisoryOutput
           , ioQAvailableQuantity
        from STM_STOCK_POSITION SPO
           , STM_ELEMENT_NUMBER SEM
       where SPO.GCO_GOOD_ID(+) = iGcoGoodId
         and SPO.STM_STOCK_ID(+) = lStockId
         and SPO.STM_LOCATION_ID(+) = lLocationId
         and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID(+)
         and (    (    nvl(lGcoChar1, 0) = 0
                   and SPO.SPO_CHARACTERIZATION_VALUE_1 is null)
              or (    SPO.SPO_CHARACTERIZATION_VALUE_1 = lGcoChar1
                  and nvl(lGcoChar1, 0) <> 0) )
         and (    (    nvl(lGcoChar2, 0) = 0
                   and SPO.SPO_CHARACTERIZATION_VALUE_2 is null)
              or (    SPO.SPO_CHARACTERIZATION_VALUE_2 = lGcoChar2
                  and nvl(lGcoChar2, 0) <> 0) )
         and (    (    nvl(lGcoChar3, 0) = 0
                   and SPO.SPO_CHARACTERIZATION_VALUE_3 is null)
              or (    SPO.SPO_CHARACTERIZATION_VALUE_3 = lGcoChar3
                  and nvl(lGcoChar3, 0) <> 0) )
         and (    (    nvl(lGcoChar4, 0) = 0
                   and SPO.SPO_CHARACTERIZATION_VALUE_4 is null)
              or (    SPO.SPO_CHARACTERIZATION_VALUE_4 = lGcoChar4
                  and nvl(lGcoChar4, 0) <> 0) )
         and (    (    nvl(lGcoChar5, 0) = 0
                   and SPO.SPO_CHARACTERIZATION_VALUE_5 is null)
              or (    SPO.SPO_CHARACTERIZATION_VALUE_5 = lGcoChar5
                  and nvl(lGcoChar5, 0) <> 0) )
         and STM_I_LIB_MOVEMENT.VerifyForecastStockPosCond(iGoodId            => SPO.GCO_GOOD_ID
                                                         , iPiece             => SPO.SPO_PIECE
                                                         , iSet               => SPO.SPO_SET
                                                         , iVersion           => SPO.SPO_VERSION
                                                         , iChronological     => SPO.SPO_CHRONOLOGICAL
                                                         , iQualityStatusId   => SEM.GCO_QUALITY_STATUS_ID
                                                          ) is not null;
    exception
      when no_data_found then
        begin
          ioQProvisoryOutput    := 0;
          ioQAvailableQuantity  := 0;
        end;
    end;
  end GetStockPrvOutAndAvlQ;

  function GetStockProvisoryOutput(
    iGcoGoodId     in GCO_GOOD.GCO_GOOD_ID%type
  , iStmStockId    in STM_STOCK.STM_STOCK_ID%type
  , iStmLocationId in STM_LOCATION.STM_LOCATION_ID%type
  )
    return number
  is
    lQty number;
  begin
    begin
      select nvl(sum(SPO.SPO_PROVISORY_OUTPUT), 0)
        into lQty
        from STM_STOCK_POSITION SPO
           , STM_ELEMENT_NUMBER SEM
       where SPO.GCO_GOOD_ID(+) = iGcoGoodId
         and SPO.STM_STOCK_ID(+) = iStmStockId
         and SPO.STM_LOCATION_ID(+) = iStmLocationId
         and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID(+)
         and STM_I_LIB_MOVEMENT.VerifyForecastStockPosCond(iGoodId            => SPO.GCO_GOOD_ID
                                                         , iPiece             => SPO.SPO_PIECE
                                                         , iSet               => SPO.SPO_SET
                                                         , iVersion           => SPO.SPO_VERSION
                                                         , iChronological     => SPO.SPO_CHRONOLOGICAL
                                                         , iQualityStatusId   => SEM.GCO_QUALITY_STATUS_ID
                                                          ) is not null;
    exception
      when no_data_found then
        lQty  := 0;
    end;

    return lQty;
  end GetStockProvisoryOutput;

  procedure GetDrpValues(
    iDRA             in     number
  , iBalanceQuantity out    FAL_DOC_PROP.FDP_DRP_BALANCE_QUANTITY%type
  , iStockMovementId out    FAL_DOC_PROP.STM_STOCK_MOVEMENT_ID%type
  , iFdpNumber       out    FAL_DOC_PROP.FDP_NUMBER%type
  , iDrpBalanced     out    FAL_DOC_PROP.FDP_DRP_BALANCED%type
  )
  is
  begin
    select nvl(FDP_DRP_BALANCE_QUANTITY, 0)
         , STM_STOCK_MOVEMENT_ID
         , nvl(FDP_NUMBER, 0)
         , nvl(FDP_DRP_BALANCED, 0)
      into iBalanceQuantity
         , iStockMovementId
         , iFdpNumber
         , iDrpBalanced
      from fal_doc_prop
     where fal_doc_prop_id = iDRA;
  exception
    when no_data_found then
      begin
        iBalanceQuantity  := 0;
        iStockMovementId  := null;
        iFdpNumber        := 0;
        iDrpBalanced      := 0;
      end;
  end GetDrpValues;

  function CalcSumBesoins(iGoodId in GCO_GOOD.GCO_GOOD_ID%type, iStockMovementId in fal_doc_prop.stm_stock_movement_id%type)
    return number
  is
    lLocationId STM_STOCK_MOVEMENT.STM_LOCATION_ID%type;
    lStockId    STM_STOCK_MOVEMENT.STM_STOCK_ID%type;
    lGcoChar1   STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lGcoChar2   STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lGcoChar3   STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lGcoChar4   STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lGcoChar5   STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lSumBesoins number;
  begin
    GetCharacterization(iGoodId, iStockMovementId, lLocationId, lStockId, lGcoChar1, lGcoChar2, lGcoChar3, lGcoChar4, lGcoChar5);

    begin
      select nvl(sum(fnn.FAN_BALANCE_QTY), 0)
        into lSumBesoins
        from FAL_NETWORK_NEED fnn
       where fnn.STM_LOCATION_ID = lLocationId
         and fnn.STM_STOCK_ID = lStockId
         and fnn.GCO_GOOD_ID = iGoodId
         and (    (    nvl(lGcoChar1, 0) = 0
                   and FAN_CHAR_VALUE1 is null)
              or (    FAN_CHAR_VALUE1 = lGcoChar1
                  and nvl(lGcoChar1, 0) <> 0) )
         and (    (    nvl(lGcoChar2, 0) = 0
                   and FAN_CHAR_VALUE2 is null)
              or (    FAN_CHAR_VALUE2 = lGcoChar2
                  and nvl(lGcoChar2, 0) <> 0) )
         and (    (    nvl(lGcoChar3, 0) = 0
                   and FAN_CHAR_VALUE3 is null)
              or (    FAN_CHAR_VALUE3 = lGcoChar3
                  and nvl(lGcoChar3, 0) <> 0) )
         and (    (    nvl(lGcoChar4, 0) = 0
                   and FAN_CHAR_VALUE4 is null)
              or (    FAN_CHAR_VALUE4 = lGcoChar4
                  and nvl(lGcoChar4, 0) <> 0) )
         and (    (    nvl(lGcoChar5, 0) = 0
                   and FAN_CHAR_VALUE5 is null)
              or (    FAN_CHAR_VALUE5 = lGcoChar5
                  and nvl(lGcoChar5, 0) <> 0) );
    exception
      when no_data_found then
        lSumBesoins  := 0;
    end;

    return lSumBesoins;
  end CalcSumBesoins;

  function CalcSumBesoins(
    iGoodId     in GCO_GOOD.GCO_GOOD_ID%type
  , iLocationId in STM_STOCK_MOVEMENT.STM_LOCATION_ID%type
  , iStockId    in STM_STOCK_MOVEMENT.STM_STOCK_ID%type
  )
    return number
  is
    lSumBesoins number;
  begin
    begin
      select nvl(sum(fnn.FAN_BALANCE_QTY), 0)
        into lSumBesoins
        from FAL_NETWORK_NEED fnn
       where fnn.STM_LOCATION_ID = iLocationId
         and fnn.STM_STOCK_ID = iStockId
         and fnn.GCO_GOOD_ID = iGoodId;
    exception
      when no_data_found then
        lSumBesoins  := 0;
    end;

    return lSumBesoins;
  end CalcSumBesoins;

  function CalcSumAppro(iGoodId in GCO_GOOD.GCO_GOOD_ID%type, iStockMovementId in FAL_DOC_PROP.STM_STOCK_MOVEMENT_ID%type)
    return number
  is
    lLocationId STM_STOCK_MOVEMENT.STM_LOCATION_ID%type;
    lStockId    STM_STOCK_MOVEMENT.STM_STOCK_ID%type;
    lGcoChar1   STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lGcoChar2   STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lGcoChar3   STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lGcoChar4   STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lGcoChar5   STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lSumAppro   number;
  begin
    GetCharacterization(iGoodId, iStockMovementId, lLocationId, lStockId, lGcoChar1, lGcoChar2, lGcoChar3, lGcoChar4, lGcoChar5);

    begin
      select nvl(sum(fns.FAN_BALANCE_QTY), 0)
        into lSumAppro
        from FAL_NETWORK_SUPPLY fns
       where fns.STM_LOCATION_ID = lLocationId
         and fns.STM_STOCK_ID = lStockId
         and fns.GCO_GOOD_ID = iGoodId
         and (    (    nvl(lGcoChar1, 0) = 0
                   and FAN_CHAR_VALUE1 is null)
              or (    FAN_CHAR_VALUE1 = lGcoChar1
                  and nvl(lGcoChar1, 0) <> 0) )
         and (    (    nvl(lGcoChar2, 0) = 0
                   and FAN_CHAR_VALUE2 is null)
              or (    FAN_CHAR_VALUE2 = lGcoChar2
                  and nvl(lGcoChar2, 0) <> 0) )
         and (    (    nvl(lGcoChar3, 0) = 0
                   and FAN_CHAR_VALUE3 is null)
              or (    FAN_CHAR_VALUE3 = lGcoChar3
                  and nvl(lGcoChar3, 0) <> 0) )
         and (    (    nvl(lGcoChar4, 0) = 0
                   and FAN_CHAR_VALUE4 is null)
              or (    FAN_CHAR_VALUE4 = lGcoChar4
                  and nvl(lGcoChar4, 0) <> 0) )
         and (    (    nvl(lGcoChar5, 0) = 0
                   and FAN_CHAR_VALUE5 is null)
              or (    FAN_CHAR_VALUE5 = lGcoChar5
                  and nvl(lGcoChar5, 0) <> 0) );
    exception
      when no_data_found then
        lSumAppro  := 0;
    end;

    return lSumAppro;
  end CalcSumAppro;

  function CalcSumAppro(
    iGoodId     in GCO_GOOD.GCO_GOOD_ID%type
  , iLocationId in STM_STOCK_MOVEMENT.STM_LOCATION_ID%type
  , iStockId    in STM_STOCK_MOVEMENT.STM_STOCK_ID%type
  )
    return number
  is
    lSumAppro number;
  begin
    begin
      select nvl(sum(fns.FAN_BALANCE_QTY), 0)
        into lSumAppro
        from FAL_NETWORK_SUPPLY fns
       where fns.STM_LOCATION_ID = iLocationId
         and fns.STM_STOCK_ID = iStockId
         and fns.GCO_GOOD_ID = iGoodId;
    exception
      when no_data_found then
        lSumAppro  := 0;
    end;

    return lSumAppro;
  end CalcSumAppro;

  procedure GetCharacterization(
    iGoodId          in     STM_STOCK_MOVEMENT.GCO_GOOD_ID%type
  , iStockMovementId in     STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type
  , iStockLocationId out    STM_STOCK_MOVEMENT.STM_LOCATION_ID%type
  , iStockId         out    STM_STOCK_MOVEMENT.STM_STOCK_ID%type
  , iGcoChar1        out    STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , iGcoChar2        out    STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , iGcoChar3        out    STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , iGcoChar4        out    STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , iGcoChar5        out    STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  )
  is
  begin
    begin
      select STM_LOCATION_ID
           , STM_STOCK_ID
        into iStockLocationId
           , iStockId
        from stm_stock_movement
       where gco_good_id = iGoodId
         and stm_stock_movement_id = iStockMovementId;
    exception
      when no_data_found then
        begin
          iStockLocationId  := null;
          iStockId          := null;
          return;
        end;
    end;

    begin
      select ssm.SMO_CHARACTERIZATION_VALUE_1
        into iGcoChar1
        from stm_stock_movement ssm
           , gco_characterization gcc
       where ssm.gco_good_id = iGoodId
         and ssm.stm_stock_movement_id = iStockMovementId
         and (   gcc.C_CHARACT_TYPE = '1'
              or gcc.C_CHARACT_TYPE = '2')
         and gcc.GCO_CHARACTERIZATION_ID = ssm.GCO_CHARACTERIZATION_ID;
    exception
      when no_data_found then
        begin
          iGcoChar1  := null;
        end;
    end;

    begin
      select ssm.SMO_CHARACTERIZATION_VALUE_2
        into iGcoChar2
        from stm_stock_movement ssm
           , gco_characterization gcc
       where ssm.gco_good_id = iGoodId
         and ssm.stm_stock_movement_id = iStockMovementId
         and (   gcc.C_CHARACT_TYPE = '1'
              or gcc.C_CHARACT_TYPE = '2')
         and gcc.GCO_CHARACTERIZATION_ID = ssm.GCO_GCO_CHARACTERIZATION_ID;
    exception
      when no_data_found then
        begin
          iGcoChar2  := null;
        end;
    end;

    begin
      select ssm.SMO_CHARACTERIZATION_VALUE_3
        into iGcoChar3
        from stm_stock_movement ssm
           , gco_characterization gcc
       where ssm.gco_good_id = iGoodId
         and ssm.stm_stock_movement_id = iStockMovementId
         and (   gcc.C_CHARACT_TYPE = '1'
              or gcc.C_CHARACT_TYPE = '2')
         and gcc.GCO_CHARACTERIZATION_ID = ssm.GCO2_GCO_CHARACTERIZATION_ID;
    exception
      when no_data_found then
        begin
          iGcoChar3  := null;
        end;
    end;

    begin
      select ssm.SMO_CHARACTERIZATION_VALUE_4
        into iGcoChar4
        from stm_stock_movement ssm
           , gco_characterization gcc
       where ssm.gco_good_id = iGoodId
         and ssm.stm_stock_movement_id = iStockMovementId
         and (   gcc.C_CHARACT_TYPE = '1'
              or gcc.C_CHARACT_TYPE = '2')
         and gcc.GCO_CHARACTERIZATION_ID = ssm.GCO3_GCO_CHARACTERIZATION_ID;
    exception
      when no_data_found then
        begin
          iGcoChar4  := null;
        end;
    end;

    begin
      select ssm.SMO_CHARACTERIZATION_VALUE_5
        into iGcoChar5
        from stm_stock_movement ssm
           , gco_characterization gcc
       where ssm.gco_good_id = iGoodId
         and ssm.stm_stock_movement_id = iStockMovementId
         and (   gcc.C_CHARACT_TYPE = '1'
              or gcc.C_CHARACT_TYPE = '2')
         and gcc.GCO_CHARACTERIZATION_ID = ssm.GCO4_GCO_CHARACTERIZATION_ID;
    exception
      when no_data_found then
        begin
          iGcoChar5  := null;
        end;
    end;
  end GetCharacterization;

  procedure GetDiuBlocked(
    iDistributionUnit in     STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type
  , ioDIUBlockedFrom  out    STM_DISTRIBUTION_UNIT.DIU_BLOCKED_FROM%type
  , ioDIUBlockedTo    out    STM_DISTRIBUTION_UNIT.DIU_BLOCKED_TO%type
  , ioPrePareTime     out    STM_DISTRIBUTION_UNIT.DIU_PREPARE_TIME%type
  )
  is
  begin
    ioDIUBlockedFrom  := null;
    ioDIUBlockedTo    := null;
    ioPrePareTime     := null;

    select trunc(DIU_BLOCKED_FROM) DIU_BLOCKED_FROM
         , trunc(DIU_BLOCKED_TO) DIU_BLOCKED_TO
         , DIU_PREPARE_TIME
      into ioDIUBlockedFrom
         , ioDIUBlockedTo
         , ioPrePareTime
      from STM_DISTRIBUTION_UNIT
     where STM_DISTRIBUTION_UNIT_ID = iDistributionUnit;
  end GetDiuBlocked;

  procedure GetCodeBlocked(
    iDicDistribComplData in     GCO_COMPL_DATA_DISTRIB.DIC_DISTRIB_COMPL_DATA_ID%type
  , ioDIUBlockedFrom     out    STM_DISTRIBUTION_UNIT.DIU_BLOCKED_FROM%type
  , ioDIUBlockedTo       out    STM_DISTRIBUTION_UNIT.DIU_BLOCKED_TO%type
  , ioPrePareTime        out    STM_DISTRIBUTION_UNIT.DIU_PREPARE_TIME%type
  )
  is
  begin
    ioDIUBlockedFrom  := null;
    ioDIUBlockedTo    := null;
    ioPrePareTime     := null;

    select trunc(DIU_BLOCKED_FROM) DIU_BLOCKED_FROM
         , trunc(DIU_BLOCKED_TO) DIU_BLOCKED_TO
         , DIU_PREPARE_TIME
      into ioDIUBlockedFrom
         , ioDIUBlockedTo
         , ioPrePareTime
      from STM_DISTRIBUTION_UNIT
     where DIC_DISTRIB_COMPL_DATA_ID = iDicDistribComplData;
  end GetCodeBlocked;

  function GetIntermediateDelay(iDistributionUnit in STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type)
    return date
  is
    lDate date;
  begin
    begin
      select   nvl(min(DED_DATE), trunc(sysdate) )   -- Retouner la date la plus petite si plusieurs sont possibles
          into lDate
          from stm_delivery_day dday
             , stm_delivery_s_diu dsdiu
             , stm_delivery_plan dplan
         where to_char(dplan.dpl_year) = to_number(to_char(sysdate, 'YYYY') )
           and dsdiu.STM_DISTRIBUTION_UNIT_ID = iDistributionUnit
           and dsdiu.STM_DELIVERY_PLAN_ID = dplan.STM_DELIVERY_PLAN_ID
           and dday.STM_DELIVERY_S_DIU_ID = dsdiu.STM_DELIVERY_S_DIU_ID
           and dday.DED_DATE >= trunc(sysdate)
      order by 1 asc;

      return trunc(lDate);
    exception
      when no_data_found then
        begin
          return trunc(sysdate);
        end;
    end;
  end GetIntermediateDelay;

  function CheckCaracterization1or2(iGoodId GCO_GOOD.GCO_GOOD_ID%type, iCharId in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type)
    return boolean
  is
    lCharType GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    lReturn   boolean;
  begin
    if iCharId is not null then
      lReturn  := true;

      begin
        select C_CHARACT_TYPE
          into lCharType
          from GCO_CHARACTERIZATION
         where GCO_CHARACTERIZATION_ID = iCharId
           and GCO_GOOD_ID = iGoodId
           and (   C_CHARACT_TYPE = '1'
                or C_CHARACT_TYPE = '2');
      exception
        when no_data_found then
          lReturn  := false;
      end;
    else
      lReturn  := false;
    end if;

    return lReturn;
  end CheckCaracterization1or2;
end FAL_LIB_DRP;
