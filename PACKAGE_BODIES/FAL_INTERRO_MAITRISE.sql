--------------------------------------------------------
--  DDL for Package Body FAL_INTERRO_MAITRISE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_INTERRO_MAITRISE" 
is
  gGlobalFAM_SESSION varchar2(2000);

  type trecFAL_LOT is record(
    T_ID               number
  , id                 FAL_LOT.FAL_LOT_ID%type
  , LOT_PLAN_BEGIN_DTE FAL_LOT.LOT_PLAN_BEGIN_DTE%type
  , LOT_PLAN_END_DTE   FAl_LOT.LOT_PLAN_END_DTE%type
  );

  grecCurlotLotProp  trecFAL_LOT;

  type trecFAL_LOT_TRAITE is record(
    C_FAM_TYPE     tDescode
  , FAL_ELEMENT_ID FAL_LOT.FAL_LOT_ID%type
  );

  grecFalLotTraite   trecFAL_LOT_TRAITE;

  type trecATT1 is record(
    FAL_NETWORK_LINK_ID FAL_NETWORK_LINK.FAL_NETWORK_LINK_ID%type
  , FLN_MARGIN          tDecimalSimple
  );

  grecAtt1           trecATT1;

  type trecATT2 is record(
    FAL_NETWORK_LINK_ID FAL_NETWORK_LINK.FAL_NETWORK_LINK_ID%type
  , FLN_MARGIN          tDecimalSimple
  );

  grecAtt2           trecATT2;

  /**
  * procedure pSetControlAvailableQuantity
  * Description
  *   Mise à jour de la qté disponible
  * @created fp 06.12.2013
  * @updated
  * @private
  * @param iGoodId
  * @param iStockVal
  */
  procedure pSetControlAvailableQuantity(iGoodId in GCO_GOOD.GCO_GOOD_ID%type, iStockToConsume in FAL_DISPO_MAITRISE.DIM_AVAILABLE_QTY%type)
  is
    lBalanceToConsume number := iStockToConsume;
  begin
    for ltplDispoMaitrise in (select   FAL_DISPO_MAITRISE_ID
                                     , least(nvl(DIM_LAPSING_DATE, '99999999'), nvl(to_char(DIM_RETEST_DATE, 'YYYYMMDD'), '99999999') ) DIM_REF_DATE
                                     , DIM_AVAILABLE_QTY
                                  from FAL_DISPO_MAITRISE
                                 where GCO_GOOD_ID = iGoodId
                                   and FAM_SESSION = gGlobalFAM_SESSION
                              order by least(nvl(DIM_LAPSING_DATE, '99999999'), nvl(to_char(DIM_RETEST_DATE, 'YYYYMMDD'), '99999999') )
                                     , DIM_AVAILABLE_QTY desc) loop
      update    FAL_DISPO_MAITRISE
            set DIM_AVAILABLE_QTY = greatest(DIM_AVAILABLE_QTY - lBalanceToConsume, 0)
          where FAL_DISPO_MAITRISE_ID = ltplDispoMaitrise.FAL_DISPO_MAITRISE_ID
      returning decode(sign(DIM_AVAILABLE_QTY - lBalanceToConsume), 1, 0, lBalanceToConsume - DIM_AVAILABLE_QTY)
           into lBalanceToConsume;
    end loop;
  end pSetControlAvailableQuantity;

  -- Processus Cpt-Stock et Attribution
  procedure pProcessusCptStockAttrib(
    iC_FAM_TYPE        in tDescode
  , iFAL_ELEMENT_ID    in tPCS_PK_ID
  , iLIEN_COMPOSANT_ID in tPCS_PK_ID
  , iValeurStock       in tDecimalSimple
  , iAtt1              in tPCS_PK_ID
  , iATT2              in tPCS_PK_ID
  , iFAL_MAT_LINK_ID   in tPCS_PK_ID
  )
  is
    lBufffalLotId              tPCS_PK_ID;
    lBuffFalJobProgramId       tPCS_PK_ID;
    lBuffFalLotPropId          tPCS_PK_ID;
    lBuffGcoGoodId             tPCS_PK_ID;
    lBuffDicAccountableGroupId GCO_GOOD.DIC_ACCOUNTABLE_GROUP_ID%type;
    lBuffDocRecordId           tPCS_PK_ID;
    lBuffDicFamilyId           DIC_FAMILY.DIC_FAMILY_ID%type;
    lBuffStmStockId            tPCS_PK_ID;
    lBuffFamDelay              date;
    lBuffFamQtyLink1           tDecimalSimple;
    lBuffFamMargin1            tDecimalSimple;
    lBuffFamQtyLink2           tDecimalSimple;
    lBuffFamMargin2            tDecimalSimple;
    lBuffcFabType              FAL_LOT.C_FAB_TYPE%type;
    lBuffLotRefcompl           FAl_LOT.LOT_REFCOMPL%type;
    lBuffGooMajorReference     GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    lBuffGooSecondaryReference GCO_GOOD.GOO_SECONDARY_REFERENCE%type;
  begin
    lBufffalLotId               := null;
    lBuffcFabType               := null;
    lBuffLotRefcompl            := null;
    lBuffGooMajorReference      := null;
    lBuffGooSecondaryReference  := null;
    lBuffFalJobProgramId        := null;
    lBuffFalLotPropId           := null;
    lBuffDicAccountableGroupId  := null;
    lBuffDocRecordId            := null;
    lBuffDicFamilyId            := null;
    lBuffStmStockId             := null;
    lBuffFamDelay               := null;

    if iC_FAM_TYPE in(0, 1) then
      lBufffalLotId  := iFAL_ELEMENT_ID;

      select STM_STOCK_ID
           , DOC_RECORD_ID
           , DIC_FAMILY_ID
           , FAL_JOB_PROGRAM_ID
           , C_FAB_TYPE
           , LOT_REFCOMPL
        into lBuffStmStockId
           , lBuffDocRecordId
           , lBuffDicFamilyId
           , lBuffFalJobProgramId
           , lBuffcFabType
           , lBuffLotRefcompl
        from FAl_LOT
       where FAL_LOT_ID = iFAL_ELEMENT_ID;

      select trunc(LOM_NEED_DATE)
        into lBuffFamDelay
        from FAL_LOT_MATERIAL_LINK
       where FAL_LOT_MATERIAL_LINK_ID = iFAL_MAT_LINK_ID;
    end if;

    if iC_FAM_TYPE = 2 then
      lBuffFalLotPropId  := iFAL_ELEMENT_ID;

      select STM_STOCK_ID
           , DOC_RECORD_ID
        into lBuffStmStockId
           , lBuffDocRecordId
        from FAl_LOT_PROP
       where FAL_LOT_PROP_ID = iFAL_ELEMENT_ID;

      select trunc(LOM_NEED_DATE)
        into lBuffFamDelay
        from FAL_LOT_MAT_LINK_PROP
       where FAL_LOT_MAT_LINK_PROP_ID = iFAL_MAT_LINK_ID;
    end if;

    select DIC_ACCOUNTABLE_GROUP_ID
         , GOO_MAJOR_REFERENCE
         , GOO_SECONDARY_REFERENCE
      into lBuffDicAccountableGroupId
         , lBuffGooMajorReference
         , lBuffGooSecondaryReference
      from GCo_GOOD
     where GCO_GOOD_ID = iLIEN_COMPOSANT_ID
       and rownum = 1;

    -- On prend la valeur de la config PPS_DefltSTOCK_NETWORK si NULL
    if lBuffStmStockId is null then
      lBuffStmStockId  := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_NETWORK');
    end if;

    -- Il se peut que les 4 requetes ci-dessous ne retourne rien, EST-CE POSSIBLE (Voir avec JPA)
    -- C'est la raison pour laquelle il y le Min(FD-20000402-0306) afin d'obtenir de toute façon un résultat
    -- et ne pas déclancer d'exception
    select min(FLN_QTY)
      into lBuffFamQtyLink1
      from FAL_NETWORK_LINK
     where FAL_NETWORK_LINK_ID = iATT1;

    select min(FLN_QTY)
      into lBuffFamQtyLink2
      from FAL_NETWORK_LINK
     where FAL_NETWORK_LINK_ID = iATT2;

    select min(trunc(FLN_MARGIN) )
      into lBuffFamMargin1
      from FAL_NETWORK_LINK
     where FAL_NETWORK_LINK_ID = iATT1;

    select min(trunc(FLN_MARGIN) )
      into lBuffFamMargin2
      from FAL_NETWORK_LINK
     where FAL_NETWORK_LINK_ID = iATT2;

    insert into FAL_MAITRISE
                (FAL_MAITRISE_ID
               , C_FAM_TYPE
               , FAM_CPT
               , FAL_LOT_ID
               , FAL_JOB_PROGRAM_ID
               , FAL_LOT_PROP_ID
               , FAM_REF
               , GCO_GOOD_ID
               , DIC_ACCOUNTABLE_GROUP_ID
               , DOC_RECORD_ID
               , DIC_FAMILY_ID
               , STM_STOCK_ID
               , FAM_DELAY
               , FAM_DELAY_WEEK
               , FAM_NEED_QTY
               , FAL_NETWORK_LINK1_ID
               , FAM_QTY_LINK_1
               , FAM_MARGIN_1
               , FAL_NETWORK_LINK2_ID
               , FAM_QTY_LINK_2
               , FAM_MARGIN_2
               , C_FAB_TYPE
               , LOT_REFCOMPL
               , GOO_MAJOR_REFERENCE
               , GOO_SECONDARY_REFERENCE
               , A_DATECRE
               , A_IDCRE
               , FAM_SESSION
                )
         values (GetNewId
               , iC_FAM_TYPE
               , 1
               , lBufffalLotId
               , lBuffFalJobProgramId
               , lBuffFalLotPropId
               , lBuffGooMajorReference
               , iLIEN_COMPOSANT_ID
               , lBuffDicAccountableGroupId
               , lBuffDocRecordId
               , lBuffDicFamilyId
               , lBuffStmStockId
               , lBuffFamDelay
               , to_char(lBuffFamDelay, 'IW')
               , abs(iValeurStock)
               , iATT1
               , lBuffFamQtyLink1
               , lBuffFamMargin1
               , iATT2
               , lBuffFamQtyLink2
               , lBuffFamMargin2
               , lBuffcFabType
               , lBuffLotRefcompl
               , lBuffGooMajorReference
               , lBuffGooSecondaryReference
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , gGlobalFAM_SESSION
                );
  end pProcessusCptStockAttrib;

  -- Processus Cpt-Stock
  procedure pProcessusCptStock(
    iC_FAM_TYPE        tDescode
  , iFAL_ELEMENT_ID    tPCS_PK_ID
  , iLIEN_COMPOSANT_ID tPCS_PK_ID
  , iValeurStock       tDecimalSimple
  , iFAL_MAT_LINK_ID   tPCS_PK_ID
  )
  is
    lBufffalLotId              tPCS_PK_ID;
    lBuffFalJobProgramId       tPCS_PK_ID;
    lBuffFalLotPropId          tPCS_PK_ID;
    lBuffGcoGoodId             tPCS_PK_ID;
    lBuffDicAccountableGroupId GCO_GOOD.DIC_ACCOUNTABLE_GROUP_ID%type;
    lBuffDocRecordId           tPCS_PK_ID;
    lBuffDicFamilyId           DIC_FAMILY.DIC_FAMILY_ID%type;
    lBuffStmStockId            tPCS_PK_ID;
    lBuffFamDelay              date;
    lBuffcFabType              FAL_LOT.C_FAB_TYPE%type;
    lBuffLotRefcompl           FAl_LOT.LOT_REFCOMPL%type;
    lBuffGooMajorReference     GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    lBuffGooSecondaryReference GCO_GOOD.GOO_SECONDARY_REFERENCE%type;
  begin
    lBufffalLotId               := null;
    lBuffcFabType               := null;
    lBuffLotRefcompl            := null;
    lBuffGooMajorReference      := null;
    lBuffGooSecondaryReference  := null;
    lBuffFalJobProgramId        := null;
    lBuffFalLotPropId           := null;
    lBuffDicAccountableGroupId  := null;
    lBuffDocRecordId            := null;
    lBuffDicFamilyId            := null;
    lBuffStmStockId             := null;
    lBuffFamDelay               := null;

    if iC_FAM_TYPE in(0, 1) then
      lBufffalLotId  := iFAL_ELEMENT_ID;

      select STM_STOCK_ID
           , FAL_JOB_PROGRAM_ID
           , DOC_RECORD_ID
           , DIC_FAMILY_ID
           , C_FAB_TYPE
           , LOT_REFCOMPL
        into lBuffStmStockId
           , lBuffFalJobProgramId
           , lBuffDocRecordId
           , lBuffDicFamilyId
           , lBuffcFabType
           , lBuffLotRefcompl
        from FAl_LOT
       where FAL_LOT_ID = iFAL_ELEMENT_ID;

      select trunc(LOM_NEED_DATE)
        into lBuffFamDelay
        from FAL_LOT_MATERIAL_LINK
       where FAL_LOT_MATERIAL_LINK_ID = iFAL_MAT_LINK_ID;
    end if;

    if iC_FAM_TYPE = 2 then
      lBuffFalLotPropId  := iFAL_ELEMENT_ID;

      select STM_STOCk_ID
           , DOC_RECORD_ID
        into lBuffStmStockId
           , lBuffDocRecordId
        from FAl_LOT_PROP
       where FAL_LOT_PROP_ID = iFAL_ELEMENT_ID;

      select trunc(LOM_NEED_DATE)
        into lBuffFamDelay
        from FAL_LOT_MAT_LINK_PROP
       where FAL_LOT_MAT_LINK_PROP_ID = iFAL_MAT_LINK_ID;
    end if;

    select DIC_ACCOUNTABLE_GROUP_ID
         , GOO_MAJOR_REFERENCE
         , GOO_SECONDARY_REFERENCE
      into lBuffDicAccountableGroupId
         , lBuffGooMajorReference
         , lBuffGooSecondaryReference
      from GCo_GOOD
     where GCO_GOOD_ID = iLIEN_COMPOSANT_ID
       and rownum = 1;

    -- On prend la valeur de la config PPS_DefltSTOCK_NETWORK si NULL
    if lBuffStmStockId is null then
      lBuffStmStockId  := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_NETWORK');
    end if;

    insert into FAL_MAITRISE
                (FAL_MAITRISE_ID
               , C_FAM_TYPE
               , FAM_CPT
               , FAL_LOT_ID
               , FAL_JOB_PROGRAM_ID
               , FAL_LOT_PROP_ID
               , FAM_REF
               , GCO_GOOD_ID
               , DIC_ACCOUNTABLE_GROUP_ID
               , DOC_RECORD_ID
               , DIC_FAMILY_ID
               , STM_STOCK_ID
               , FAM_DELAY
               , FAM_DELAY_WEEK
               , FAM_NEED_QTY
               , C_FAB_TYPE
               , LOT_REFCOMPL
               , GOO_MAJOR_REFERENCE
               , GOO_SECONDARY_REFERENCE
               , A_DATECRE
               , A_IDCRE
               , FAM_SESSION
                )
         values (GetNewId
               , iC_FAM_TYPE
               , 1
               , lBufffalLotId
               , lBuffFalJobProgramId
               , lBuffFalLotPropId
               , lBuffGooMajorReference
               , iLIEN_COMPOSANT_ID
               , lBuffDicAccountableGroupId
               , lBuffDocRecordId
               , lBuffDicFamilyId
               , lBuffStmStockId
               , lBuffFamDelay
               , to_char(lBuffFamDelay, 'IW')
               , abs(iValeurStock)
               , lBuffcFabType
               , lBuffLotRefcompl
               , lBuffGooMajorReference
               , lBuffGooSecondaryReference
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , gGlobalFAM_SESSION
                );
  end pProcessusCptStock;

  -- pProcessusLOT
  procedure pProcessusLOT(
    iC_FAM_TYPE        tDescode
  , iFAL_ELEMENT_ID    tPCS_PK_ID
  , iCompteurAlerte    integer
  , iCompteurAlerteAtt integer
  , iTotale            tDecimalSimple
  , iQteMaxFAb         tDecimalSimple
  )
  is
    lBufffalLotId              tPCS_PK_ID;
    lBuffFalJobProgramId       tPCS_PK_ID;
    lBuffFalLotPropId          tPCS_PK_ID;
    lBuffFamRef                FAL_MAITRISE.FAM_REF%type;
    lBuffGcoGoodId             tPCS_PK_ID;
    lBuffDicAccountableGroupId GCO_GOOD.DIC_ACCOUNTABLE_GROUP_ID%type;
    lBuffDocRecordId           tPCS_PK_ID;
    lBuffDicFamilyId           DIC_FAMILY.DIC_FAMILY_ID%type;
    lBuffStmStockId            tPCS_PK_ID;
    lBuffFamNeedQty            tDecimalSimple;
    lBuffFamDelay              date;
    lBuffcFabType              FAL_LOT.C_FAB_TYPE%type;
    lBuffLotRefcompl           FAl_LOT.LOT_REFCOMPL%type;
    lBuffGooMajorReference     GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    lBuffGooSecondaryReference GCO_GOOD.GOO_SECONDARY_REFERENCE%type;
  begin
    lBufffalLotId               := null;
    lBuffFalLotPropId           := null;
    lBuffcFabType               := null;
    lBuffLotRefcompl            := null;
    lBuffGooMajorReference      := null;
    lBuffGooSecondaryReference  := null;
    lBuffFalJobProgramId        := null;
    lBuffFamRef                 := null;
    lBuffGcoGoodId              := null;
    lBuffDicAccountableGroupId  := null;
    lBuffDocRecordId            := null;
    lBuffDicFamilyId            := null;
    lBuffStmStockId             := null;
    lBuffFamDelay               := null;
    lBuffFamNeedQty             := null;

    if iC_FAM_TYPE in(0, 1) then
      lBufffalLotId  := iFAL_ELEMENT_ID;

      select LOT_INPROD_QTY
           , trunc(LOT_PLAN_END_DTE)
           , STM_STOCK_ID
           , DOC_RECORD_ID
           , DIC_FAMILY_ID
           , GCO_GOOD_ID
           , FAL_JOB_PROGRAM_ID
           , C_FAB_TYPE
           , LOT_REFCOMPL
        into lBuffFamNeedQty
           , lBuffFamDelay
           , lBuffStmStockId
           , lBuffDocRecordId
           , lBuffDicFamilyId
           , lBuffGcoGoodId
           , lBuffFalJobProgramId
           , lBuffcFabType
           , lBuffLotRefcompl
        from FAl_LOT
       where FAL_LOT_ID = iFAL_ELEMENT_ID;
    end if;

    lBuffFamRef                 := lBuffLotRefcompl;

    if iC_FAM_TYPE = 2 then
      lBuffFalLotPropId  := iFAL_ELEMENT_ID;

      select LOT_TOTAL_QTY
           , trunc(LOT_PLAN_END_DTE)
           , STM_STOCK_ID
           , DOC_RECORD_ID
           , GCO_GOOD_ID
           , PCS.PC_FUNCTIONS.GetDescodeCode('C_PREFIX_PROP', C_PREFIX_PROP, PCS.PC_I_LIB_SESSION.GetCompLangId) || LOT_NUMBER
        into lBuffFamNeedQty
           , lBuffFamDelay
           , lBuffStmStockId
           , lBuffDocRecordId
           , lBuffGcoGoodId
           , lBuffFamRef
        from FAL_LOT_PROP
       where FAL_LOT_PROP_ID = iFAL_ELEMENT_ID;
    end if;

    select DIC_ACCOUNTABLE_GROUP_ID
         , GOO_MAJOR_REFERENCE
         , GOO_SECONDARY_REFERENCE
      into lBuffDicAccountableGroupId
         , lBuffGooMajorReference
         , lBuffGooSecondaryReference
      from GCo_GOOD
     where GCO_GOOD_ID = lBuffGcoGoodId
       and rownum = 1;

    -- On prend la valeur de la config PPS_DefltSTOCK_NETWORK si NULL
    if lBuffStmStockId is null then
      lBuffStmStockId  := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_NETWORK');
    end if;

    insert into FAL_MAITRISE
                (FAL_MAITRISE_ID
               , C_FAM_TYPE
               , FAM_CPT
               , FAL_LOT_ID
               , FAL_JOB_PROGRAM_ID
               , FAL_LOT_PROP_ID
               , FAM_REF
               , GCo_GOOD_ID
               , DIC_ACCOUNTABLE_GROUP_ID
               , DOC_RECORD_ID
               , DIC_FAMILY_ID
               , STM_STOCK_ID
               , FAM_DELAY
               , FAM_DELAY_WEEK
               , FAM_NEED_QTY
               , FAM_ALERT_STOCK_COMPT
               , FAM_ALERT_LINK_COMPT
               , C_FAB_TYPE
               , LOT_REFCOMPL
               , GOO_MAJOR_REFERENCE
               , GOO_SECONDARY_REFERENCE
               , FAM_TOTAL_QTY
               , FAM_MAX_QTY
               , A_DATECRE
               , A_IDCRE
               , FAM_SESSION
                )
         values (GetNewId
               , iC_FAM_TYPE
               , 0
               , lBufffalLotId
               , lBuffFalJobProgramId
               , lBuffFalLotPropId
               , lBuffFamRef
               , lBuffGcoGoodId
               , lBuffDicAccountableGroupId
               , lBuffDocRecordId
               , lBuffDicFamilyId
               , lBuffStmStockId
               , lBuffFamDelay
               , to_char(lBuffFamDelay, 'IW')
               , 0   -- FAM_NEED_QTY
               , iCompteurAlerte
               , iCompteurAlerteAtt
               , lBuffcFabType
               , lBuffLotRefcompl
               , lBuffGooMajorReference
               , lBuffGooSecondaryReference
               , iTotale
               , iQteMaxFAb
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , gGlobalFAM_SESSION
                );
  end pProcessusLOT;   -- Fin de pProcessusLOT

  procedure pGetFirstTwoAllocation(iFalNetworkNeedId tPCS_PK_ID)
  is
    cursor lcurFalNetworkLink
    is
      select   FAL_NETWORK_LINK_ID
             , FLN_MARGIN
          from FAL_NETWORK_LINK
         where FAL_NETWORK_NEED_ID = iFalNetworkNeedId
      order by FLN_MARGIN asc;

    I integer;
  begin
    grecAtt1.FAL_NETWORK_LINK_ID  := null;
    grecAtt1.FLN_MARGIN           := null;
    grecAtt2.FAL_NETWORK_LINK_ID  := null;
    grecAtt2.FLN_MARGIN           := null;

    open lcurFalNetworkLink;

    I                             := 0;

    loop
      I  := I + 1;
      exit when I > 2;

      if I = 1 then   -- 1ere Attrib
        fetch lcurFalNetworkLink
         into grecAtt1;

        exit when lcurFalNetworkLink%notfound;
      end if;

      if I = 2 then   -- 2eme Attrib
        fetch lcurFalNetworkLink
         into grecAtt2;

        exit when lcurFalNetworkLink%notfound;
      end if;
    end loop;

    close lcurFalNetworkLink;
  exception
    when no_data_found then
      null;
  end pGetFirstTwoAllocation;

  function pGetFAN_FREE_QTY_Lot(iComponentId in tPCS_PK_ID)
    return tDecimalSimple
  is
    lResult tDecimalSimple;
  begin
    select FAN_FREE_QTY
      into lResult
      from FAL_NETWORK_NEED
     where FAL_LOT_MATERIAL_LINK_ID = iComponentId;

    return nvl(lResult, 0);
  exception
    when no_data_found then
      return 0;
  end pGetFAN_FREE_QTY_Lot;

  function pGetFAN_NETW_QTY_Lot(iComponentId in tPCS_PK_ID)
    return tDecimalSimple
  is
    lResult tDecimalSimple;
  begin
    select FAN_NETW_QTY
      into lResult
      from FAL_NETWORK_NEED
     where FAL_LOT_MATERIAL_LINK_ID = iComponentId;

    return nvl(lResult, 0);
  exception
    when no_data_found then
      return 0;
  end pGetFAN_NETW_QTY_Lot;

  function pGetFAN_BALANCE_QTY_Lot(iComponentId in tPCS_PK_ID)
    return tDecimalSimple
  is
    lResult tDecimalSimple;
  begin
    select FAN_BALANCE_QTY
      into lResult
      from FAL_NETWORK_NEED
     where FAL_LOT_MATERIAL_LINK_ID = iComponentId;

    return nvl(lResult, 0);
  exception
    when no_data_found then
      return 0;
  end pGetFAN_BALANCE_QTY_Lot;

  function pGetFAN_FREE_QTY_Prop(iComponentId in tPCS_PK_ID)
    return tDecimalSimple
  is
    lResult tDecimalSimple;
  begin
    select FAN_FREE_QTY
      into lResult
      from FAL_NETWORK_NEED
     where FAL_LOT_MAT_LINK_PROP_ID = iComponentId;

    return nvl(lResult, 0);
  exception
    when no_data_found then
      return 0;
  end pGetFAN_FREE_QTY_Prop;

  function pGetFAN_NETW_QTY_Prop(iComponentId in tPCS_PK_ID)
    return tDecimalSimple
  is
    lResult tDecimalSimple;
  begin
    select FAN_NETW_QTY
      into lResult
      from FAL_NETWORK_NEED
     where FAL_LOT_MAT_LINK_PROP_ID = iComponentId;

    return nvl(lResult, 0);
  exception
    when no_data_found then
      return 0;
  end pGetFAN_NETW_QTY_Prop;

  function pGetFAN_BALANCE_QTY_Prop(iComponentId in tPCS_PK_ID)
    return tDecimalSimple
  is
    lResult tDecimalSimple;
  begin
    select FAN_BALANCE_QTY
      into lResult
      from FAL_NETWORK_NEED
     where FAL_LOT_MAT_LINK_PROP_ID = iComponentId;

    return nvl(lResult, 0);
  exception
    when no_data_found then
      return 0;
  end pGetFAN_BALANCE_QTY_Prop;

  function pGetAPPRO_pLOT(iComponentId in tPCS_PK_ID)
    return tDecimalSimple
  is
    lResult              tDecimalSimple;
    iFAL_NETWORK_NEED_ID FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type;
    iGoodId              GCO_GOOD.GCO_GOOD_ID%type;
  begin
    -- Récupérer l'Id du besoin du composant (et le Good pour retrouver après les appros du good!)
    --
    select FAL_NETWORK_NEED_ID
         , GCO_GOOD_ID
      into iFAL_NETWORK_NEED_ID
         , iGoodId
      from FAL_nETWORK_NEED
     where FAL_LOT_MATERIAL_LINK_ID = iComponentId;

    -- Sum des  (Fal_Network_Link -> Fln_Qty)
    -- Pour les attrib entre le besoins et les appros
    select sum(FLN_QTY)
      into lResult
      from FAL_NETWORK_LINK
     where FAL_NETWORK_NEED_ID = iFAL_NETWORK_NEED_ID
       and FAL_NETWORK_SUPPLY_ID in(select FAL_NETWORK_SUPPLY_ID
                                      from FAL_NETWORK_SUPPLY
                                     where GCo_GOOD_ID = iGoodId
                                       and (   FAL_LOT_PROP_ID is not null
                                            or FAL_DOC_PROP_ID is not null) );

    return nvl(lResult, 0);
  exception
    when no_data_found then
      return 0;
  end pGetAPPRO_pLOT;

  function pGetAPPRO_pPROP(iComponentId in tPCS_PK_ID)
    return tDecimalSimple
  is
    lResult              tDecimalSimple;
    lFAL_NETWORK_NEED_ID FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type;
    lGCO_GOOD_ID         GCO_GOOD.GCO_GOOD_ID%type;
  begin
    -- Récupérer l'Id du besoin du composant (et le Good pour retrouver après les appros du good!)
    --
    select FAL_NETWORK_NEED_ID
         , GCO_GOOD_ID
      into lFAL_NETWORK_NEED_ID
         , lGCO_GOOD_ID
      from FAL_nETWORK_NEED
     where FAL_LOT_MAT_LINK_PROP_ID = iComponentId;

    -- Sum des  (Fal_Network_Link -> Fln_Qty)
    -- Pour les attrib entre le besoins et les appros
    select sum(FLN_QTY)
      into lResult
      from FAL_NETWORK_LINK
     where FAL_NETWORK_NEED_ID = lFAL_NETWORK_NEED_ID
       and FAL_NETWORK_SUPPLY_ID in(select FAL_NETWORK_SUPPLY_ID
                                      from FAL_NETWORK_SUPPLY
                                     where GCo_GOOD_ID = lGCO_GOOD_ID
                                       and (   FAL_LOT_PROP_ID is not null
                                            or FAL_DOC_PROP_ID is not null) );

    return nvl(lResult, 0);
  exception
    when no_data_found then
      return 0;
  end pGetAPPRO_pPROP;

  -- Génération Interrogation Maîtrise Stock et Attributions
  procedure pGenerateCtrlStockAndAllocQry(iC_FAM_TYPE tDescode, iFAL_ELEMENT_ID tPCS_PK_ID, iWithPropositionAppro integer)
  is
    -- Curseur: Pour chaque Gco_Good_id de Fal_lot_material_link dont lom_need_qty > 0 et qui n'existe pas deja dans la table Fal_Dispo_Maitrise
    cursor lCurFalLotMaterialLink(iFalLotId tPCS_PK_ID)
    is
      select   FAL_LOT_MATERIAL_LINK_ID
             , LOM.GCO_GOOD_ID
             , LOM_NEED_QTY
             , LOM_NEED_DATE
          from FAL_LOT_MATERIAL_LINK LOM
             , GCO_PRODUCT PDT
         where FAL_LOT_ID = iFalLotId
           and PDT.GCO_GOOD_ID = LOM.GCO_GOOD_ID
           and PDT.PDT_STOCK_MANAGEMENT = 1
           and (LOM_NEED_QTY > 0)
           and (LOM_NEED_QTY is not null)
           and C_KIND_COM not in('4', '5')   -- Qui n'est pas un lien texte, ni fournit par le sous-traitant
      order by LOM_NEED_DATE;

    ltplFalLotMaterialLink lCurFalLotMaterialLink%rowtype;

    -- Curseur: Pour chaque Gco_Good_id de Fal_lot_MAT_LINK_PROP dont lom_need_qty > 0 et qui n'existe pas deja dans la table Fal_Dispo_Maitrise
    cursor lCurFalLotMatLinkProp(iFalLotPropId tPCS_PK_ID)
    is
      select   FAL_LOT_MAT_LINK_PROP_ID
             , GCO_GOOD_ID
             , LOM_NEED_QTY
             , LOM_NEED_DATE
          from FAL_LOT_MAT_LINK_PROP
         where FAL_LOT_PROP_ID = iFalLotPropId
           and (LOM_NEED_QTY > 0)
           and (LOM_NEED_QTY is not null)
           and C_KIND_COM not in('4', '5')   -- Qui n'est pas un lien texte, ni fournit par le sous-traitant
      order by LOM_NEED_DATE;

    ltplFalLotMatLinkProp  lCurFalLotMatLinkProp%rowtype;
    CompteurAlerte         integer;
    CompteurAlerteAtt      integer;
    BesoinComposant        tPCS_PK_ID;
    Libre                  tDecimalSimple;
    QtyDispoMaitrise       tDecimalSimple;
    ValeurStock            tDecimalSimple;
    LesMarges              tDecimalSimple;
    APPROP                 tDecimalSimple;

    function pGetbesoinComposantLot(lComponentId tPCS_PK_ID)
      return tPCS_PK_ID
    is
      lResult tPCS_PK_ID;
    begin
      select FAL_NETWORK_NEED_ID
        into lResult
        from FAL_NETWORK_NEED
       where FAL_LOT_MATERIAL_LINK_ID = lComponentId;

      return lResult;
    exception
      when no_data_found then
        return null;
    end;

    function pGetbesoinComposantProp(lComponentId tPCS_PK_ID)
      return tPCS_PK_ID
    is
      lResult tPCS_PK_ID;
    begin
      select FAL_NETWORK_NEED_ID
        into lResult
        from FAL_NETWORK_NEED
       where FAL_LOT_MAT_LINK_PROP_ID = lComponentId;

      return lResult;
    exception
      when no_data_found then
        return null;
    end;

    -- Indique s'il existe au moins une attrib avec une marge négative (c'est à dire en retard)
    function pAuMoinsUnRetard(iFalNetworkNeedId FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type, iWithPropositionAppro integer)
      return boolean
    is
      X FAL_NETWORK_LINK.FLN_QTY%type;
    begin
      if iFalNetworkNeedId is null then
        -- Pas la peine de chercher les retards, il n'y a pas de besoin
        return false;
      else
        -- On cherche le nombre de retards
        if iWithPropositionAppro = 1 then
          select min(FLN_MARGIN)
            into X
            from FAL_NETWORK_LINK
           where nvl(FAL_NETWORK_NEED_ID, 0) = iFalNetworkNeedId;
        end if;

        if iWithPropositionAppro = 0 then
          DBMS_OUTPUT.put_line('PrmFAL_NETWORK_NEED_ID = ' || iFalNetworkNeedId);

          select min(fln_margin)
            into X
            from fal_network_link l
               , fal_network_supply s
           where l.fal_network_supply_id = s.fal_network_supply_id
             and nvl(fal_network_need_id, 0) = iFalNetworkNeedId
             and (    fal_lot_prop_id is null
                  and fal_doc_prop_id is null);
        end if;
      end if;

      return X < 0;
    end;
  begin
    CompteurAlerte     := 0;
    CompteurAlerteAtt  := 0;

    if iC_FAM_TYPE in(0, 1) then   -- On travail sur des lots et donc sur des Fal_Lot_Material_LInk
      open lCurFalLotMaterialLink(iFAL_ELEMENT_ID);   -- Boucle sur les composants du lot

      loop
        fetch lCurFalLotMaterialLink
         into ltplFalLotMaterialLink;

        exit when lCurFalLotMaterialLink%notfound;
        BesoinComposant  := pGetbesoinComposantLot(ltplFalLotMaterialLink.FAL_LOT_MATERIAL_LINK_ID);
        -- Déterminer le libre
        APPROP           := 0;

        if iWithPropositionAppro = 1 then
          LIBRE  := pGetFAN_FREE_QTY_Lot(ltplFalLotMaterialLink.FAL_LOT_MATERIAL_LINK_ID);
        else
          APPROP  := pGetAPPRO_pLOT(ltplFalLotMaterialLink.FAL_LOT_MATERIAL_LINK_ID);
          LIBRE   := pGetFAN_FREE_QTY_Lot(ltplFalLotMaterialLink.FAL_LOT_MATERIAL_LINK_ID);
          LIBRE   := LIBRE + APPROP;
        end if;

        select sum(DIM_AVAILABLE_QTY)
          into QtyDispoMaitrise
          from FAL_DISPO_MAITRISE
         where GCO_GOOD_ID = ltplFalLotMaterialLink.GCO_GOOD_ID
           and IsControlAvailable(DIM_LAPSING_DATE, DIM_RETEST_DATE, ltplFalLotMaterialLink.LOM_NEED_DATE) = 1
           and FAM_SESSION = gGlobalFAM_SESSION;

        ValeurStock      := nvl(QtyDispoMaitrise, 0) - nvl(LIBRE, 0);

        if ValeurStock < 0 then
          update FAL_DISPO_MAITRISE
             set DIM_AVAILABLE_QTY = 0
           where GCO_GOOD_ID = ltplFalLotMaterialLink.GCO_GOOD_ID
             and FAM_SESSION = gGlobalFAM_SESSION;

          CompteurAlerte  := CompteurAlerte + 1;
          pGetFirstTwoAllocation(BesoinComposant);

          if pAuMoinsUnRetard(BesoinComposant, iWithPropositionAppro) then
            CompteurAlerteAtt  := CompteurAlerteAtt + 1;
            pProcessusCptStockAttrib(iC_FAM_TYPE
                                   , iFAL_ELEMENT_ID
                                   , ltplFalLotMaterialLink.GCO_GOOD_ID
                                   , ValeurStock
                                   , grecAtt1.FAL_NETWORK_LINK_ID
                                   , grecAtt2.FAL_NETWORK_LINK_ID
                                   , ltplFalLotMaterialLink.FAL_LOT_MATERIAL_LINK_ID
                                    );
          else
            pProcessusCptStockAttrib(iC_FAM_TYPE
                                   , iFAL_ELEMENT_ID
                                   , ltplFalLotMaterialLink.GCO_GOOD_ID
                                   , ValeurStock
                                   , null
                                   , null
                                   , ltplFalLotMaterialLink.FAL_LOT_MATERIAL_LINK_ID
                                    );
          end if;   -- les marges sont négatives
        else
          pSetControlAvailableQuantity(iGoodID => ltplFalLotMaterialLink.GCO_GOOD_ID, iStockToConsume => nvl(LIBRE, 0) );
          ValeurStock  := 0;
          pGetFirstTwoAllocation(BesoinComposant);

          if pAuMoinsUnRetard(BesoinComposant, iWithPropositionAppro) then
            CompteurAlerteAtt  := CompteurAlerteAtt + 1;
            pProcessusCptStockAttrib(iC_FAM_TYPE
                                   , iFAL_ELEMENT_ID
                                   , ltplFalLotMaterialLink.GCO_GOOD_ID
                                   , nvl(LIBRE, 0)
                                   , grecAtt1.FAL_NETWORK_LINK_ID
                                   , grecAtt2.FAL_NETWORK_LINK_ID
                                   , ltplFalLotMaterialLink.FAL_LOT_MATERIAL_LINK_ID
                                    );
          end if;
        end if;
      end loop;   -- Fin de Boucle sur les Composants

      pProcessusLOT(iC_FAM_TYPE, iFAL_ELEMENT_ID, CompteurAlerte, CompteurAlerteAtt, null, null);

      close lCurFalLotMaterialLink;
    else   -- On travail sur des propositions et donc sur des Fal_Lot_Mat_LInk_prop
      open lCurFalLotMatLinkProp(iFAL_ELEMENT_ID);   -- Boucle sur les composants de la proposition

      loop
        fetch lCurFalLotMatLinkProp
         into ltplFalLotMatLinkProp;

        exit when lCurFalLotMatLinkProp%notfound;
        BesoinComposant  := pGetbesoinComposantProp(ltplFalLotMatLinkProp.FAL_LOT_MAT_LINK_PROP_ID);
        -- Déterminer le libre
        APPROP           := 0;

        if iWithPropositionAppro = 1 then
          LIBRE  := pGetFAN_FREE_QTY_Prop(ltplFalLotMatLinkProp.FAL_LOT_MAT_LINK_PROP_ID);
        else
          APPROP  := pGetAPPRO_pPROP(ltplFalLotMatLinkProp.FAL_LOT_MAT_LINK_PROP_ID);
          LIBRE   := pGetFAN_FREE_QTY_Prop(ltplFalLotMatLinkProp.FAL_LOT_MAT_LINK_PROP_ID);
          LIBRE   := LIBRE + APPROP;
        end if;

        select sum(DIM_AVAILABLE_QTY)
          into QtyDispoMaitrise
          from FAL_DISPO_MAITRISE
         where GCO_GOOD_ID = ltplFalLotMatLinkProp.GCO_GOOD_ID
           and IsControlAvailable(DIM_LAPSING_DATE, DIM_RETEST_DATE, ltplFalLotMatLinkProp.LOM_NEED_DATE) = 1
           and FAM_SESSION = gGlobalFAM_SESSION;

        ValeurStock      := QtyDispoMaitrise - nvl(LIBRE, 0);

        if ValeurStock < 0 then
          update FAL_DISPO_MAITRISE
             set DIM_AVAILABLE_QTY = 0
           where GCO_GOOD_ID = ltplFalLotMatLinkProp.GCO_GOOD_ID
             and FAM_SESSION = gGlobalFAM_SESSION;

          CompteurAlerte  := CompteurAlerte + 1;
          pGetFirstTwoAllocation(BesoinComposant);

          if pAuMoinsUnRetard(BesoinComposant, iWithPropositionAppro) then
            CompteurAlerteAtt  := CompteurAlerteAtt + 1;
            pProcessusCptStockAttrib(iC_FAM_TYPE
                                   , iFAL_ELEMENT_ID
                                   , ltplFalLotMatLinkProp.GCO_GOOD_ID
                                   , ValeurStock
                                   , grecAtt1.FAL_NETWORK_LINK_ID
                                   , grecAtt2.FAL_NETWORK_LINK_ID
                                   , ltplFalLotMatLinkProp.FAL_LOT_MAT_LINK_PROP_ID
                                    );
          else
            pProcessusCptStockAttrib(iC_FAM_TYPE
                                   , iFAL_ELEMENT_ID
                                   , ltplFalLotMatLinkProp.GCO_GOOD_ID
                                   , ValeurStock
                                   , null
                                   , null
                                   , ltplFalLotMatLinkProp.FAL_LOT_MAT_LINK_PROP_ID
                                    );
          end if;   -- les marges sont négatives
        else
          pSetControlAvailableQuantity(iGoodID => ltplFalLotMaterialLink.GCO_GOOD_ID, iStockToConsume => nvl(LIBRE, 0) );
          ValeurStock  := 0;
          pGetFirstTwoAllocation(BesoinComposant);

          if pAuMoinsUnRetard(BesoinComposant, iWithPropositionAppro) then
            CompteurAlerteAtt  := CompteurAlerteAtt + 1;
            pProcessusCptStockAttrib(iC_FAM_TYPE
                                   , iFAL_ELEMENT_ID
                                   , ltplFalLotMatLinkProp.GCO_GOOD_ID
                                   , nvl(LIBRE, 0)
                                   , grecAtt1.FAL_NETWORK_LINK_ID
                                   , grecAtt2.FAL_NETWORK_LINK_ID
                                   , ltplFalLotMatLinkProp.FAL_LOT_MAT_LINK_PROP_ID
                                    );
          end if;
        end if;
      end loop;   -- Fin de Boucle sur les Composants

      pProcessusLOT(iC_FAM_TYPE, iFAL_ELEMENT_ID, CompteurAlerte, CompteurAlerteAtt, null, null);

      close lCurFalLotMatLinkProp;
    end if;
  end pGenerateCtrlStockAndAllocQry;

  -- génération Interrogation Maîtrise Stock
  procedure pGenerateCtrlStockQry(iC_FAM_TYPE tDescode, iFAL_ELEMENT_ID tPCS_PK_ID, iWithPropositionAppro integer)
  is
    -- Curseur: Pour chaque Gco_Good_id de Fal_lot_material_link dont lom_need_qty > 0 et qui n'existe pas deja dans la table Fal_Dispo_Maitrise
    cursor lCurFalLotMaterialLink(iFalLotId tPCS_PK_ID)
    is
      select   FAL_LOT_MATERIAL_LINK_ID
             , GCO_GOOD_ID
             , LOM_NEED_QTY
             , LOM_UTIL_COEF
             , LOM_NEED_DATE
          from FAL_LOT_MATERIAL_LINK
         where FAL_LOT_ID = iFalLotId
           and (LOM_NEED_QTY > 0)
           and (LOM_NEED_QTY is not null)
           and C_KIND_COM not in('4', '5')
      order by LOM_NEED_DATE;   -- Qui n'est pas un lien texte, ni fournit par le sous-traitant

    ltplFalLotMaterialLink lCurFalLotMaterialLink%rowtype;

    -- Curseur: Pour chaque Gco_Good_id de Fal_lot_MAT_LINK_PROP dont lom_need_qty > 0 et qui n'existe pas deja dans la table Fal_Dispo_Maitrise
    cursor lCurFalLotMatLinkProp(iFalLotPropId tPCS_PK_ID)
    is
      select   FAL_LOT_MAT_LINK_PROP_ID
             , GCO_GOOD_ID
             , LOM_NEED_QTY
             , LOM_UTIL_COEF
             , LOM_NEED_DATE
          from FAL_LOT_MAT_LINK_PROP
         where FAL_LOT_PROP_ID = iFalLotPropId
           and (LOM_NEED_QTY > 0)
           and (LOM_NEED_QTY is not null)
           and C_KIND_COM not in('4', '5')
      order by LOM_NEED_DATE;   -- Qui n'est pas un lien texte, ni fournit par le sous-traitant

    ltplFalLotMatLinkProp  lCurFalLotMatLinkProp%rowtype;
    QtyDispoMaitrise       tDecimalSimple;
    ValeurStock            tDecimalSimple;
    CompteurAlerte         integer;
    CompteurAlerteAtt      integer;
    LIBRE                  FAL_NETWORK_NEED.FAN_FREE_QTY%type;
    QteMaxFab              tDecimalSimple;
    X                      tDecimalSimple;
    TOTALE                 tDecimalSimple;
    APPROP                 tDecimalSimple;
    lnTotalQty             number;
  begin
    CompteurAlerte     := 0;
    CompteurAlerteAtt  := 0;

    if iC_FAM_TYPE in(0, 1) then   -- On travail sur des lots et donc sur des Fal_Lot_Material_LInk
      select nvl(LOT_INPROD_QTY, 0)
        into QteMaxFab
        from FAL_LOT
       where FAL_LOT_ID = iFAL_ELEMENT_ID;

      lnTotalQty  := QteMaxFab;

      open lCurFalLotMaterialLink(iFAL_ELEMENT_ID);   -- Boucle sur les composats

      loop
        fetch lCurFalLotMaterialLink
         into ltplFalLotMaterialLink;

        exit when lCurFalLotMaterialLink%notfound;

        -- Déterminer le Libre
        if iWithPropositionAppro = 1 then
          APPROP  := pGetAPPRO_pLOT(ltplFalLotMaterialLink.FAL_LOT_MATERIAL_LINK_ID);
          LIBRE   :=
            pGetFAN_FREE_QTY_Lot(ltplFalLotMaterialLink.FAL_LOT_MATERIAL_LINK_ID) +
            pGetFAN_NETW_QTY_Lot(ltplFalLotMaterialLink.FAL_LOT_MATERIAL_LINK_ID) -
            APPROP;
        else
          LIBRE  :=
                   pGetFAN_FREE_QTY_Lot(ltplFalLotMaterialLink.FAL_LOT_MATERIAL_LINK_ID)
                   + pGetFAN_NETW_QTY_Lot(ltplFalLotMaterialLink.FAL_LOT_MATERIAL_LINK_ID);
        end if;

        select nvl(sum(DIM_AVAILABLE_QTY), 0)
          into QtyDispoMaitrise
          from FAL_DISPO_MAITRISE
         where GCO_GOOD_ID = ltplFalLotMaterialLink.GCO_GOOD_ID
           and IsControlAvailable(DIM_LAPSING_DATE, DIM_RETEST_DATE, ltplFalLotMaterialLink.LOM_NEED_DATE) = 1
           and FAM_SESSION = gGlobalFAM_SESSION;

        TOTALE       := pGetFAN_BALANCE_QTY_Lot(ltplFalLotMaterialLink.FAL_LOT_MATERIAL_LINK_ID);
        ValeurStock  := QtyDispoMaitrise - LIBRE;

        -- Updater la table FAL_DISPO_MAITRISE
        if valeurStock < 0 then
          update FAL_DISPO_MAITRISE
             set DIM_AVAILABLE_QTY = 0
           where GCO_GOOD_ID = ltplFalLotMaterialLink.GCO_GOOD_ID
             and FAM_SESSION = gGlobalFAM_SESSION;

          CompteurAlerte  := CompteurAlerte + 1;

          if nvl(ltplFalLotMaterialLink.LOM_UTIL_COEF, 0) = 0 then
            X  := TOTALE + ValeurStock;
          else
            X  := FAL_TOOLS.ArrondiInferieur( (TOTALE + ValeurStock) / ltplFalLotMaterialLink.LOM_UTIL_COEF, ltplFalLotMaterialLink.GCO_GOOD_ID);
          end if;

          if X < QteMaxFab then
            QteMaxFab  := X;

            if QteMaxFab < 0 then
              QteMaxFab  := 0;
            end if;
          end if;

          pProcessusCptStock(iC_FAM_TYPE
                           , iFAL_ELEMENT_ID
                           , ltplFalLotMaterialLink.GCO_GOOD_ID
                           , ltplFalLotMaterialLink.LOM_NEED_QTY
                           , ltplFalLotMaterialLink.FAL_LOT_MATERIAL_LINK_ID
                            );
        else
          pSetControlAvailableQuantity(iGoodID => ltplFalLotMaterialLink.GCO_GOOD_ID, iStockToConsume => LIBRE);
        end if;
      end loop;

      pProcessusLOT(iC_FAM_TYPE, iFAL_ELEMENT_ID, CompteurAlerte, CompteurAlerteAtt, lnTotalQty, QteMaxFab);

      close lCurFalLotMaterialLink;
    else   -- On travail sur des propositions et donc des Fal_Lot_Mat_link_Prop
      select nvl(LOT_TOTAL_QTY, 0)
        into QteMaxFab
        from FAL_LOT_PROP
       where FAL_LOT_PROP_ID = iFAL_ELEMENT_ID;

      lnTotalQty  := QteMaxFab;

      open lCurFalLotMatLinkProp(iFAL_ELEMENT_ID);

      loop
        fetch lCurFalLotMatLinkProp
         into ltplFalLotMatLinkProp;

        exit when lCurFalLotMatLinkProp%notfound;

        -- Déterminer le Libre
        if iWithPropositionAppro = 1 then
          APPROP  := pGetAPPRO_pPROP(ltplFalLotMatLinkProp.FAL_LOT_MAT_LINK_PROP_ID);
          LIBRE   :=
            pGetFAN_FREE_QTY_Prop(ltplFalLotMatLinkProp.FAL_LOT_MAT_LINK_PROP_ID) +
            pGetFAN_NETW_QTY_Prop(ltplFalLotMatLinkProp.FAL_LOT_MAT_LINK_PROP_ID) -
            APPROP;
        else
          LIBRE  :=
                   pGetFAN_FREE_QTY_Prop(ltplFalLotMatLinkProp.FAL_LOT_MAT_LINK_PROP_ID)
                   + pGetFAN_NETW_QTY_Prop(ltplFalLotMatLinkProp.FAL_LOT_MAT_LINK_PROP_ID);
        end if;

        select sum(DIM_AVAILABLE_QTY)
          into QtyDispoMaitrise
          from FAL_DISPO_MAITRISE
         where GCO_GOOD_ID = ltplFalLotMatLinkProp.GCO_GOOD_ID
           and IsControlAvailable(DIM_LAPSING_DATE, DIM_RETEST_DATE, ltplFalLotMatLinkProp.LOM_NEED_DATE) = 1
           and FAM_SESSION = gGlobalFAM_SESSION;

        TOTALE       := pGetFAN_BALANCE_QTY_Prop(ltplFalLotMatLinkProp.FAL_LOT_MAT_LINK_PROP_ID);
        ValeurStock  := QtyDispoMaitrise - LIBRE;

        -- Updater la table FAL_DISPO_MAITRISE
        if valeurStock < 0 then
          update FAL_DISPO_MAITRISE
             set DIM_AVAILABLE_QTY = 0
           where GCO_GOOD_ID = ltplFalLotMatLinkProp.GCO_GOOD_ID
             and FAM_SESSION = gGlobalFAM_SESSION;

          CompteurAlerte  := CompteurAlerte + 1;

          if nvl(ltplFalLotMatLinkProp.LOM_UTIL_COEF, 0) = 0 then
            X  := TOTALE + ValeurStock;
          else
            X  := FAL_TOOLS.ArrondiInferieur( (TOTALE + ValeurStock) / ltplFalLotMatLinkProp.LOM_UTIL_COEF, ltplFalLotMatLinkProp.GCO_GOOD_ID);
          end if;

          if X < QteMaxFab then
            QteMaxFab  := X;

            if QteMaxFab < 0 then
              QteMaxFab  := 0;
            end if;
          end if;

          pProcessusCptStock(iC_FAM_TYPE, iFAL_ELEMENT_ID, ltplFalLotMatLinkProp.GCO_GOOD_ID, ValeurStock, ltplFalLotMatLinkProp.FAL_LOT_MAT_LINK_PROP_ID);
        else
          pSetControlAvailableQuantity(iGoodID => ltplFalLotMatLinkProp.GCO_GOOD_ID, iStockToConsume => LIBRE);
        end if;
      end loop;

      pProcessusLOT(iC_FAM_TYPE, iFAL_ELEMENT_ID, CompteurAlerte, CompteurAlerteAtt, lnTotalQty, QteMaxFAB);

      close lCurFalLotMatLinkProp;
    end if;
  end pGenerateCtrlStockQry;

  -- vérifie la présence d'un good id déjà existant dans FAL_DISPo_MAITRISE
  function pGoodIdInDispoMaitrise(iGoodId in FAL_DISPO_MAITRISE.GCO_GOOD_ID%type)
    return boolean
  is
    lId FAL_DISPO_MAITRISE.GCO_GOOD_ID%type;
  begin
    select distinct GCO_GOOD_ID
               into lId
               from FAL_DISPO_MAITRISE
              where GCO_GOOD_ID = iGoodId
                and FAM_SESSION = gGlobalFAM_SESSION;

    return true;
  exception
    when no_data_found then
      return false;
  end pGoodIdInDispoMaitrise;

  -- Initialisation des dispos
  procedure pInitAvailableForBatch(iElementID in tPCS_PK_ID, iC_FAM_TYPE in tDescode, iStkList in varchar2)
  is
    -- Curseur: Pour chaque Gco_Good_id de Fal_lot_material_link dont lom_need_qty > 0 et qui n'existe pas deja dans la table Fal_Dispo_Maitrise
    cursor lCurFalLotMaterialLink(iFalLotId tPCS_PK_ID)
    is
      select GCO_GOOD_ID
           , LOM_NEED_QTY
        from FAL_LOT_MATERIAL_LINK
       where FAL_LOT_ID = iFalLotId
         and LOM_NEED_QTY > 0
         and (LOM_NEED_QTY is not null)
         and C_KIND_COM not in('4', '5');   -- Qui n'est pas un lien texte, ni fournit par le sous-traitant

    ltplFalLotMaterialLink lCurFalLotMaterialLink%rowtype;

    -- Curseur: Pour chaque Gco_Good_id de Fal_lot_MAT_LINK_PROP
    --          dont lom_need_qty > 0
    --          Qui n'est pas un lien texte
    --          et qui n'existe pas deja dans la table Fal_Dispo_Maitrise
    cursor lCurFalLotMatLinkProp(iFalLotPropId tPCS_PK_ID)
    is
      select GCO_GOOD_ID
           , LOM_NEED_QTY
        from FAL_LOT_MAT_LINK_PROP
       where FAL_LOT_PROP_ID = iFalLotPropId
         and LOM_NEED_QTY > 0
         and (LOM_NEED_QTY is not null)
         and C_KIND_COM not in('4', '5');   -- Qui n'est pas un lien texte, ni fournit par le sous-traitant

    ltplFalLotMatLinkProp  lCurFalLotMatLinkProp%rowtype;
  begin
    if iC_FAM_TYPE in(0, 1) then   -- On traite des FAL_LOT_MATERIAl_LINK
      open lCurFalLotMaterialLink(iElementID);

      loop
        fetch lCurFalLotMaterialLink
         into ltplFalLotMaterialLink;

        exit when lCurFalLotMaterialLink%notfound;

        if not pGoodIdInDispoMaitrise(ltplFalLotMaterialLink.GCO_GOOD_ID) then
          SetSumDispoForSelectedStock(iGoodId => ltplFalLotMaterialLink.GCO_GOOD_ID, iListStock => iStkList, iElementId => iElementId);
        end if;
      end loop;

      close lCurFalLotMaterialLink;
    else   -- On traite des FAL_LOT_MAT_LINK_PROP
      open lCurFalLotMatLinkProp(iElementID);

      loop
        fetch lCurFalLotMatLinkProp
         into ltplFalLotMatLinkProp;

        exit when lCurFalLotMatLinkProp%notfound;

        if not pGoodIdInDispoMaitrise(ltplFalLotMatLinkProp.GCO_GOOD_ID) then
          SetSumDispoForSelectedStock(iGoodId => ltplFalLotMatLinkProp.GCO_GOOD_ID, iListStock => iStkList, iElementId => iElementId);
        end if;
      end loop;

      close lCurFalLotMatLinkProp;
    end if;
  end pInitAvailableForBatch;

  -- PutEnr dans la table temporaire de lot ou de la proposition à traiter
  procedure pInsertElemIntoProcessedElem(iC_FAM_TYPE in tDescode)
  is
  begin
    if iC_FAM_TYPE in(0, 1) then
      insert into FAL_LOT_TRAITE
                  (FAL_LOT_TRAITE_ID   -- Générate Value Id
                 , FAL_ELEMENT_ID   -- Le lot ou la Proposition
                 , C_FAM_TYPE   -- Le Type de Maitrise
                 , LOT_PLAN_BEGIN_DTE   -- Date Début Planifiée
                 , LOT_PLAN_END_DTE   -- Date Fin Planifiée
                 , FAM_SESSION   -- Session Utilisateur
                  )
           values (GetNewId
                 ,   -- Générate Value Id
                   grecCurlotLotProp.id
                 ,   -- Le lot ou la Proposition
                   iC_FAM_TYPE
                 ,   -- Lot Lancé 0, Lot Planifié 1, Proposition 2
                   trunc(grecCurlotLotProp.LOT_PLAN_BEGIN_DTE)
                 ,   -- Date Début Planifiée
                   trunc(grecCurlotLotProp.LOT_PLAN_END_DTE)
                 ,   -- Date Fin Planifiée
                   gGlobalFAM_SESSION   -- Session Utilisateur
                  );
    else
      insert into FAL_LOT_TRAITE
                  (FAL_LOT_TRAITE_ID   -- Générate Value Id
                 , FAL_ELEMENT_ID   -- Le lot ou la Proposition
                 , C_FAM_TYPE   -- Le Type de Maitrise
                 , LOT_PLAN_BEGIN_DTE   -- Date Début Planifiée
                 , LOT_PLAN_END_DTE   -- Date Fin Planifiée
                 , FAM_SESSION   -- Session Utilisateur
                  )
           values (GetNewId   -- Générate Value Id
                 , grecCurlotLotProp.id   -- Le lot ou la Proposition
                 , iC_FAM_TYPE   -- Lot Lancé 0, Lot Planifié 1, Proposition 2
                 , trunc(grecCurlotLotProp.LOT_PLAN_BEGIN_DTE)   -- Date Début Planifiée
                 , trunc(grecCurlotLotProp.LOT_PLAN_END_DTE)   -- Date Fin Planifiée
                 , gGlobalFAM_SESSION   -- Session Utilisateur
                  );
    end if;
  end pInsertElemIntoProcessedElem;

  /**
  * Description
  *   détruit tous les tuples de FAL_MAITRISE d'une session qui n'existe plus
  */
  procedure pDeleteAllObsoleteFAL_MAITRISE
  is
    cursor lcrOracleSession
    is
      select distinct FAM_SESSION
                 from FAL_MAITRISE
      union
      select distinct FAM_SESSION
                 from FAL_LOT_TRAITE
      union
      select distinct FAM_SESSION
                 from FAL_DISPO_MAITRISE;
  begin
    for ltplOracleSession in lcrOracleSession loop
      if COM_FUNCTIONS.Is_Session_Alive(ltplOracleSession.FAM_SESSION) = 0 then
        ClearQuery(ltplOracleSession.FAM_SESSION);
      end if;
    end loop;
  end pDeleteAllObsoleteFAL_MAITRISE;

  /**
  * Description : Création des tables permettant l'interrogation de maitrise
  */
  procedure QueryControl(
    iTakeLotLance         in integer
  , iTakeLotPlanifie      in integer
  , iTakePropositionDeFab in integer
  , iStkList              in varchar2
  , iDateFinMax           in date
  , iDateDebutMax         in date
  , iCritereTriDate       in integer
  , iSeuilManquant        in integer
  , iWithPropositionAppro in integer
  , iFAM_SESSION          in FAL_DISPO_MAITRISE.FAM_SESSION%type
  )
  is
    -- Curseur lot lancés + lot planifié + proposition
    cursor lcurLotL_LotP_Prop
    is
      select   0 as T_ID
             , FAL_LOT_ID as id
             , LOT_PLAN_BEGIN_DTE
             , LOT_PLAN_END_DTE
          from FAL_LOT
         where C_LOT_STATUS = 2
           and nvl(C_FAB_TYPE, '0') <> '4'
           and (   trunc(LOT_PLAN_END_DTE) <= iDateFinMax
                or iDateFinMax is null)
           and (   trunc(LOT_PLAN_BEGIN_DTE) <= iDateDebutMax
                or iDateDebutMax is null)
      union
      select   1 as T_ID
             , FAL_LOT_ID as id
             , LOT_PLAN_BEGIN_DTE
             , LOT_PLAN_END_DTE
          from FAL_LOT
         where C_LOT_STATUS = 1
           and nvl(C_FAB_TYPE, '0') <> '4'
           and (   trunc(LOT_PLAN_END_DTE) <= iDateFinMax
                or iDateFinMax is null)
           and (   trunc(LOT_PLAN_BEGIN_DTE) <= iDateDebutMax
                or iDateDebutMax is null)
      union
      select   2 as T_ID
             , FAl_LOT_PROP_ID as id
             , LOT_PLAN_BEGIN_DTE
             , LOT_PLAN_END_DTE
          from FAL_LOT_PROP
         where (   trunc(LOT_PLAN_END_DTE) <= iDateFinMax
                or iDateFinMax is null)
           and (   trunc(LOT_PLAN_BEGIN_DTE) <= iDateDebutMax
                or iDateDebutMax is null)
           and C_PREFIX_PROP <> 'POAST'
           and C_PREFIX_PROP <> 'PDAST'
      order by LOT_PLAN_BEGIN_DTE;

    cursor lcurFAL_LOT_TRAITE_DATE_DEBUT
    is
      select   C_FAM_TYPE
             , FAL_ELEMENT_ID
          from FAL_LOT_TRAITE
         where FAM_SESSION = gGlobalFAM_SESSION
      order by LOT_PLAN_BEGIN_DTE;

    cursor lcurFAL_LOT_TRAITE_DATE_FIN
    is
      select   C_FAM_TYPE
             , FAL_ELEMENT_ID
          from FAL_LOT_TRAITE
         where FAM_SESSION = gGlobalFAM_SESSION
      order by LOT_PLAN_END_DTE;
  begin
    -- On commence par éffacer tous les enregs issus de sessions obsolètes
    -- au cas ou. Cela peut arriver dans le cas de la fermeture brutal d'un objet.
    pDeleteAllObsoleteFAL_MAITRISE;
    -- Récupération de la session utilisateur
    gGlobalFAM_SESSION  := iFAM_SESSION;
    -- Pour éviter d'avoir des enregs issus de la session en cours
    -- C'est ce qui se produit si nous avons une erreur lors de l'éxécution, le programme
    -- n'a paspu appeler la procédure de nettoyage.
    ClearQuery(gGlobalFAM_SESSION);

    open lcurLotL_LotP_Prop;

    loop
      fetch lcurLotL_LotP_Prop
       into grecCurlotLotProp;

      exit when lcurLotL_LotP_Prop%notfound;

      -- Est-ce un lancé ?, les prends t'on ?
      if     grecCurlotLotProp.T_ID = 0
         and iTakeLotLance = 1 then
        pInsertElemIntoProcessedElem(0);   -- Insertion dans la table des lots traités
        pInitAvailableForBatch(grecCurlotLotProp.id, 0, iStkList);   -- Appel de l'initialisation des dispos
      end if;

      -- Est-ce un planifié ?, les prends t'on ?
      if     grecCurlotLotProp.T_ID = 1
         and iTakeLotPlanifie = 1 then
        pInsertElemIntoProcessedElem(1);   -- Insertion dans la table des lots traités
        pInitAvailableForBatch(grecCurlotLotProp.id, 1, iStkList);   -- Appel de l'initialisation des dispos
      end if;

      -- Est-ce une proposition ?, les prends t'on ?
      if     grecCurlotLotProp.T_ID = 2
         and iTakePropositionDeFab = 1 then
        pInsertElemIntoProcessedElem(2);   -- Insertion dans la table des lots traités
        pInitAvailableForBatch(grecCurlotLotProp.id, 2, iStkList);   -- Appel de l'initialisation des dispos
      end if;
    end loop;

    close lcurLotL_LotP_Prop;


    -- Maintenant selon le critère de fin
    if iCritereTriDate = gEndDate then
      -- Tri de FAL_LOT_TRAITE sur Date fin croissant si Paramètre "critère de tri" est date fin
      open lcurFAL_LOT_TRAITE_DATE_FIN;

      loop   -- Boucle sur les éléments traités
        fetch lcurFAL_LOT_TRAITE_DATE_FIN
         into grecFalLotTraite;

        exit when lcurFAL_LOT_TRAITE_DATE_FIN%notfound;

        if iSeuilManquant = gStockCoveringOnly then
          pGenerateCtrlStockQry(grecFalLotTraite.C_FAM_TYPE, grecFalLotTraite.FAL_ELEMENT_ID, iWithPropositionAppro);   -- génération Interrogation Maîtrise Stock
        else
          pGenerateCtrlStockAndAllocQry(grecFalLotTraite.C_FAM_TYPE, grecFalLotTraite.FAL_ELEMENT_ID, iWithPropositionAppro);   -- Génération Interrogation Maîtrise Stcock et Attributions
        end if;
      end loop;

      close lcurFAL_LOT_TRAITE_DATE_FIN;
    else
      open lcurFAL_LOT_TRAITE_DATE_DEBUT;

      -- Tri de FAL_LOT_TRAITE sur Date début croissant si Paramètre "critère de tri" est date Début
      loop   -- Boucle sur les éléments traités
        fetch lcurFAL_LOT_TRAITE_DATE_DEBUT
         into grecFalLotTraite;

        exit when lcurFAL_LOT_TRAITE_DATE_DEBUT%notfound;

        if iSeuilManquant = gStockCoveringOnly then
          pGenerateCtrlStockQry(grecFalLotTraite.C_FAM_TYPE, grecFalLotTraite.FAL_ELEMENT_ID, iWithPropositionAppro);   -- génération Interrogation Maîtrise Stock
        else
          pGenerateCtrlStockAndAllocQry(grecFalLotTraite.C_FAM_TYPE, grecFalLotTraite.FAL_ELEMENT_ID, iWithPropositionAppro);   -- Génération Interrogation Maîtrise Stcock et Attributions
        end if;
      end loop;

      close lcurFAL_LOT_TRAITE_DATE_DEBUT;
    end if;   -- Fin du else sur le critere de tri

    for ltplMaitrise in (select *
                           from FAL_MAITRISE
                          where FAM_CPT = 1
                            and FAM_SESSION = gGlobalFAM_SESSION) loop
      declare
        lQty number;
      begin
        select sum(FAM_NEED_QTY)
          into lQty
          from FAL_MAITRISE B
         where B.GCO_GOOD_ID = ltplMaitrise.GCO_GOOD_ID
           and FAM_CPT = 1
           and FAM_SESSION = gGlobalFAM_SESSION;

        update FAL_MAITRISE A
           set A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             , FAM_NEED_TOTAL_QTY = lQty
         where FAL_MAITRISE_ID = ltplMaitrise.FAL_MAITRISE_ID;
      end;
    end loop;
  end QueryControl;

  /**
  * Description
  *   destruction de tous les enregs pour une session donnée,
  */
  procedure ClearQuery(iFAM_SESSION in FAL_DISPO_MAITRISE.FAM_SESSION%type)
  is
  begin
    delete from FAL_DISPO_MAITRISE
          where FAM_SESSION = iFAM_SESSION;

    delete from FAL_LOT_TRAITE
          where FAM_SESSION = iFAM_SESSION;

    delete from FAL_MAITRISE
          where FAM_SESSION = iFAM_SESSION;
  end ClearQuery;

  /**
  * Description : Retoune la somme des quantités Disponibles et Quantités provisoires
  *               en entrée pour un GCO_GOOD_ID et Une liste de Stock
  */
  function GetSumDispoOnSelectStock(iGoodId in GCO_GOOD.GCO_GOOD_ID%type, iListStock in varchar2, aDateRequest date default sysdate)
    return STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type
  is
    lStockDispo number;
  begin
    select sum(nvl(SPO.SPO_AVAILABLE_QUANTITY, 0) + nvl(SPO.SPO_PROVISORY_INPUT, 0) )
      into lStockDispo
      from STM_STOCK_POSITION SPO
         , STM_ELEMENT_NUMBER SEM
         , table(IdListToTable(iListStock) ) STO
     where SPO.STM_STOCK_ID = STO.column_value
       and SPO.GCO_GOOD_ID = iGoodId
       and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID(+)
       and STM_I_LIB_MOVEMENT.VerifyForecastStockPosCond(iGoodId            => SPO.GCO_GOOD_ID
                                                       , iPiece             => SPO.SPO_PIECE
                                                       , iSet               => SPO.SPO_SET
                                                       , iVersion           => SPO.SPO_VERSION
                                                       , iChronological     => SPO.SPO_CHRONOLOGICAL
                                                       , iQualityStatusId   => SEM.GCO_QUALITY_STATUS_ID
                                                       , iDateRequest       => aDateRequest
                                                        ) is not null;

    return nvl(lStockDispo, 0);
  end GetSumDispoOnSelectStock;

  /**
  * Description : Retoune la somme des quantités Disponibles et Quantités provisoires
  *               en entrée pour un GCO_GOOD_ID et Une liste de Stock
  */
  procedure SetSumDispoForSelectedStock(
    iGoodId      in GCO_GOOD.GCO_GOOD_ID%type
  , iListStock   in varchar2
  , iElementId   in FAL_DISPO_MAITRISE.FAL_ELEMENT_ID%type
  , aDateRequest    date default sysdate
  )
  is
    bfounded boolean := False;
  begin
    for ltplStockPos in (select   SPO.SPO_CHRONOLOGICAL
                                , SEM.SEM_RETEST_DATE
                                , FAL_TOOLS.ProductHasPeremptionDate(SPO.GCO_GOOD_ID) EXPIRY_DATE
                                , nvl(sum(nvl(SPO.SPO_AVAILABLE_QUANTITY, 0) + nvl(SPO.SPO_PROVISORY_INPUT, 0) ), 0) SPO_DISPO
                             from STM_STOCK_POSITION SPO left outer join STM_ELEMENT_NUMBER SEM on(SEM.STM_ELEMENT_NUMBER_ID = SPO.STM_ELEMENT_NUMBER_DETAIL_ID
                                                                                                  )
                                  inner join table(IdListToTable(iListStock) ) STO on(SPO.STM_STOCK_ID = STO.column_value)
                            where SPO.GCO_GOOD_ID = iGoodId
                              and STM_I_LIB_MOVEMENT.VerifyForecastStockPosCond(iGoodId            => SPO.GCO_GOOD_ID
                                                                              , iPiece             => SPO.SPO_PIECE
                                                                              , iSet               => SPO.SPO_SET
                                                                              , iVersion           => SPO.SPO_VERSION
                                                                              , iChronological     => SPO.SPO_CHRONOLOGICAL
                                                                              , iQualityStatusId   => SEM.GCO_QUALITY_STATUS_ID
                                                                              , iDateRequest       => aDateRequest
                                                                               ) is not null
                         group by SPO_CHRONOLOGICAL
                                , FAL_TOOLS.ProductHasPeremptionDate(SPO.GCO_GOOD_ID)
                                , SEM_RETEST_DATE) loop
      bfounded := True;
      insert into FAL_DISPO_MAITRISE
                  (FAL_DISPO_MAITRISE_ID
                 , FAL_ELEMENT_ID
                 , GCO_GOOD_ID
                 , DIM_AVAILABLE_QTY
                 , FAM_SESSION
                 , DIM_LAPSING_DATE
                 , DIM_RETEST_DATE
                  )
           values (GetNewId
                 , iElementID
                 , iGoodId
                 , ltplStockPos.SPO_DISPO
                 , gGlobalFAM_SESSION
                 , (case ltplStockPos.EXPIRY_DATE
                     when 1 then ltplStockPos.SPO_CHRONOLOGICAL
                     else null
                   end)
                 , ltplStockPos.SEM_RETEST_DATE
                  );
    end loop;
    if not bFounded then
       insert into FAL_DISPO_MAITRISE
                  (FAL_DISPO_MAITRISE_ID
                 , FAL_ELEMENT_ID
                 , GCO_GOOD_ID
                 , DIM_AVAILABLE_QTY
                 , FAM_SESSION
                 , DIM_LAPSING_DATE
                 , DIM_RETEST_DATE
                  )
           values (GetNewId
                 , iElementID
                 , iGoodId
                 , 0
                 , gGlobalFAM_SESSION
                 , null
                 , null
                  );
    end if;
  end SetSumDispoForSelectedStock;

  /**
  * Description
  *   Défini si selon les dates de péremption et de retest, une qté maitrise est disponible
  */
  function IsControlAvailable(
    iLapsingDate in FAL_DISPO_MAITRISE.DIM_LAPSING_DATE%type
  , iRetestDate  in FAL_DISPO_MAITRISE.DIM_RETEST_DATE%type
  , iNeedDate    in FAL_LOT_MATERIAL_LINK.LOM_NEED_DATE%type
  )
    return number
  is
    lResult number := 1;
    lRetestDate  date;
    lTestDate    date;
    lLapsingDate date;
  begin
    -- il faut au moins un des deux critères pour qu'on teste. Sinon c'est dispo.
    if    iLapsingDate is not null
       or iRetestDate is not null then
       if iLapsingDate is not null then
         lLapsingDate := to_date(substr(iLapsingDate || '1231', 1, 8), 'YYYYMMDD');
       else
         lLapsingDate := null;
       end if;

        if GCO_I_LIB_CONSTANT.gcCfgRetestPrevMode then
          lRetestDate  := iRetestDate;
        else
          lRetestDate  := lLapsingDate;
        end if;

        -- si la date chronologie ou la date de retest est plus grande que la date besoin, c'est dispo
        lTestDate  := least(nvl(lRetestDate, iNeedDate), nvl(lLapsingDate, iNeedDate) );
        lResult    := Bool2Byte(lTestDate >= iNeedDate);

    end if;

    return lResult;

  end IsControlAvailable;
end FAL_INTERRO_MAITRISE;
