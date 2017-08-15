--------------------------------------------------------
--  DDL for Package Body FAL_LIB_PAIRING
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_PAIRING" 
is
  /**
  * Description
  *    Retourne l'ID de l'entrée Atelier pour le numéro de pièce du CPT du lot transmis en
  *    paramètre s'il reste de la quantité à appairer. Sinon Renvoie 0. Si plusieurs entrées
  *    atelier correspondent à ce numéro (Plusieurs composants avec le même numéro de série
  *    existent), retourne -1
  */
  function getFactoryInID(iLotID in FAL_LOT_DETAIL.FAL_LOT_ID%type,
    iCptPiece in FAL_FACTORY_IN.IN_PIECE%type default null,
    iCptLot in FAL_FACTORY_IN.IN_LOT%type default null,
    iCptVersion in FAL_FACTORY_IN.IN_VERSION%type default null,
    iCptChronology in FAL_FACTORY_IN.IN_CHRONOLOGY%type default null)
    return FAL_FACTORY_IN.FAL_FACTORY_IN_ID%type
  as
    lFactoryInID FAL_FACTORY_IN.FAL_FACTORY_IN_ID%type;
  begin
    select ffi.FAL_FACTORY_IN_ID
      into lFactoryInID
      from FAL_FACTORY_IN ffi
     where ffi.FAL_LOT_ID = iLotID
       and NVL(ffi.IN_PIECE, ' ') = NVL(iCptPiece, ' ')
       and NVL(ffi.IN_LOT, ' ') = NVL(iCptLot, ' ')
       and NVL(ffi.IN_VERSION, ' ') = NVL(iCptVersion, ' ')
       and NVL(ffi.IN_CHRONOLOGY, ' ') = NVL(iCptChronology, ' ')
       and (ffi.IN_BALANCE - (select nvl(sum(ldl.LDL_QTY), 0)
                                from FAL_LOT_DETAIL_LINK ldl
                               where ldl.FAL_FACTORY_IN_ID = ffi.FAL_FACTORY_IN_ID) ) > 0;

    return lFactoryInID;
  exception
    when no_data_found then
      return 0;   -- Plus de quantité à appairer ou entrée inexisante
    when too_many_rows then
      return -1;   -- Plusieurs composants avec le même numéro de série existent
  end getFactoryInID;

  /**
  * Description
  *    Retourne l'ID de la position de stock pour le numéro de pièce du CPT du lot transmis en
  *    paramètre s'il reste de la quantité à appairer. Sinon Renvoie 0. Si plusieurs positions
  *    de stock correspondent à ce numéro (Plusieurs composants avec le même numéro de série
  *    existent), retourne -1
  */
  function getStockPositionID(iLotID in FAL_LOT_DETAIL.FAL_LOT_ID%type,
    iCptPiece in STM_STOCK_POSITION.SPO_PIECE%type default null,
    iCptLot in STM_STOCK_POSITION.SPO_SET%type default null,
    iCptVersion in STM_STOCK_POSITION.SPO_VERSION%type default null,
    iCptChronology in STM_STOCK_POSITION.SPO_CHRONOLOGICAL%type default null)
    return STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type
  as
    lStockPositionID STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type;
  begin
    select spo.STM_STOCK_POSITION_ID
      into lStockPositionID
      from STM_STOCK_POSITION spo
     where spo.STM_STOCK_ID = FAL_I_LIB_SUBCONTRACTP.GetStockSubcontractP(iFalLotId => iLotID)
       and NVL(spo.SPO_PIECE, ' ') = NVL(iCptPiece, ' ')
       and NVL(spo.SPO_SET, ' ') = NVL(iCptLot, ' ')
       and NVL(spo.SPO_VERSION, ' ') = NVL(iCptVersion, ' ')
       and NVL(spo.SPO_CHRONOLOGICAL, ' ') = NVL(iCptChronology, ' ')
       and ( (spo.SPO_AVAILABLE_QUANTITY + FAL_LIB_ATTRIB.getAttribQty(iLotID => iLotID, iStockPositionID => spo.STM_STOCK_POSITION_ID) ) -
            getAlignedQtyByStockPosition(iStockPositionID => spo.STM_STOCK_POSITION_ID)
           ) > 0;

    return lStockPositionID;
  exception
    when no_data_found then
      return 0;   -- Plus de quantité à appairer ou entrée inexisante
    when too_many_rows then
      return -1;   -- Plusieurs composants avec le même numéro de série existent
  end getStockPositionID;

  /**
  * Description
  *    Retourne la quantité appairée sur la position de stock transmise en paramètre.
  */
  function getAlignedQtyByStockPosition(iStockPositionID in STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type)
    return FAL_LOT_DETAIL_LINK.LDL_QTY%type
  as
    lLdlQty FAL_LOT_DETAIL_LINK.LDL_QTY%type;
  begin
    select nvl(sum(LDL_QTY), 0)
      into lLdlQty
      from FAL_LOT_DETAIL_LINK
     where STM_STOCK_POSITION_ID = iStockPositionID;

    return lLdlQty;
  end getAlignedQtyByStockPosition;

  /**
  * Description
  *    Retourne la quantité appairée sur le composant du détail de lot. (toutes
  *    positions de ce composant confondues). Les composants sont dans le stock STT
  */
  function getAlignedQtyFromStockPosition(iLotDetailID in FAL_LOT_DETAIL.FAL_LOT_DETAIL_ID%type, iCptGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return FAL_LOT_DETAIL_LINK.LDL_QTY%type
  as
    lLdlQty FAL_LOT_DETAIL_LINK.LDL_QTY%type;
  begin
    select nvl(sum(LDL_QTY), 0)
      into lLdlQty
      from FAL_LOT_DETAIL_LINK ldl
         , STM_STOCK_POSITION spo
         , FAL_LOT_DETAIL lde
     where ldl.STM_STOCK_POSITION_ID = spo.STM_STOCK_POSITION_ID
       and ldl.FAL_LOT_DETAIL_ID = lde.FAL_LOT_DETAIL_ID
       and lde.FAL_LOT_DETAIL_ID = iLotDetailID
       and spo.STM_STOCK_ID = FAL_I_LIB_SUBCONTRACTP.GetStockSubcontractP(iFalLotId => lde.FAL_LOT_ID)
       and spo.GCO_GOOD_ID = iCptGoodID;

    return lLdlQty;
  end getAlignedQtyFromStockPosition;

  /**
  * Description
  *    Retourne la quantité appairée sur le composant du détail de lot (toutes
  *    entrées ateliers confondues). Les composants sont dans le stock Atelier.
  */
  function getAlignedQtyFromFactoryIn(
    iLotDetailID       in FAL_LOT_DETAIL.FAL_LOT_DETAIL_ID%type
  , iLotMaterialLinkID in FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type
  )
    return FAL_LOT_DETAIL_LINK.LDL_QTY%type
  as
    lLdlQty FAL_LOT_DETAIL_LINK.LDL_QTY%type;
  begin
    select nvl(sum(LDL.LDL_QTY), 0)
      into lLdlQty
      from FAL_LOT_DETAIL_LINK ldl
         , FAL_FACTORY_IN ffi
     where ldl.FAL_LOT_DETAIL_ID = iLotDetailID
       and ffi.FAL_FACTORY_IN_ID = ldl.FAL_FACTORY_IN_ID
       and ffi.FAL_LOT_MATERIAL_LINK_ID = iLotMaterialLinkID;

    return lLdlQty;
  end getAlignedQtyFromFactoryIn;

  /**
  * Description
  *    Retourne l'ID du bien et la somme des coefficients d'utilisation pour le(les)
  *    composant(s) du lot de fabrication correspondant à celui de la position
  *    de stock.
  */
  procedure getCptDataByStockPosAndLot(
    iStockPositionID in     STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type
  , iLotID           in     FAL_LOT.FAL_LOT_ID%type
  , oCptGoodID       out    FAL_LOT_MATERIAL_LINK.GCO_GOOD_ID%type
  , oUtilCoef        out    FAL_LOT_MATERIAL_LINK.LOM_UTIL_COEF%type
  )
  as
    lLotMaterialLinkID FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type;
  begin
    select   lom.GCO_GOOD_ID
           , nvl(sum(lom.LOM_UTIL_COEF), 0)
        into oCptGoodID
           , oUtilCoef
        from FAL_LOT_MATERIAL_LINK lom
           , STM_STOCK_POSITION spo
       where lom.GCO_GOOD_ID = spo.GCO_GOOD_ID
         and lom.FAL_LOT_ID = iLotID
         and spo.STM_STOCK_POSITION_ID = iStockPositionID
    group by lom.GCO_GOOD_ID;
  exception
    when no_data_found then
      oCptGoodID  := 0;
      oUtilCoef   := 0;
  end getCptDataByStockPosAndLot;

  /**
  * Description
  *    Retourne le bien et le coéfficient d'utilisation du composant de lot selon
  *    l'entrée atelier transmise en paramètre.
  */
  procedure getCptDataByFactoryIn(
    iFactoryInID in     FAL_FACTORY_IN.FAL_FACTORY_IN_ID%type
  , oCptGoodID   out    FAL_LOT_MATERIAL_LINK.GCO_GOOD_ID%type
  , oUtilCoef    out    FAL_LOT_MATERIAL_LINK.LOM_UTIL_COEF%type
  )
  as
    lLotMaterialLinkID FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type;
  begin
    /* Récupération de l'ID du composant de lot */
    lLotMaterialLinkID  :=
           FWK_I_LIB_ENTITY.getNumberFieldFromPk(iv_entity_name   => 'FAL_FACTORY_IN', iv_column_name => 'FAL_LOT_MATERIAL_LINK_ID'
                                               , it_pk_value      => iFactoryInID);
    FAL_LIB_LOT_MATERIAL_LINK.getCptData(iLotMaterialLinkID => lLotMaterialLinkID, oCptGoodID => oCptGoodID, oUtilCoef => oUtilCoef);
  exception
    when no_data_found then
      oCptGoodID  := 0;
      oUtilCoef   := 0;
  end getCptDataByFactoryIn;

  /**
  * Description
  *    Retourne l'ID de l'appairage par sa quantité et la clef secondaire de la
  *    position de stock.
  */
  function getLotDetailLinkIDByStockPos(
    iLotID                  in FAL_LOT_DETAIL.FAL_LOT_ID%type
  , iCptGoodID              in STM_STOCK_POSITION.GCO_GOOD_ID%type
  , iQty                    in FAL_LOT_DETAIL_LINK.LDL_QTY%type
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
  )
    return ID_TABLE_TYPE
  as
    lLotDetailLinkListID ID_TABLE_TYPE := ID_TABLE_TYPE();
  begin
    for ltplLotDetailLink in
      (select ldl.FAL_LOT_DETAIL_LINK_ID
         from FAL_LOT_DETAIL_LINK ldl
            , FAL_LOT_DETAIL fad
        where fad.FAL_LOT_DETAIL_ID = ldl.FAL_LOT_DETAIL_ID
          and fad.FAL_LOT_ID = iLotID
          and ldl.LDL_QTY = iQty
          and nvl(ldl.STM_STOCK_POSITION_ID, 0) =
                STM_FUNCTIONS.getPositionId
                                (aGoodId       => iCptGoodID
                               , aLocationId   => STM_FUNCTIONS.GetDefaultLocationId
                                                                                    (aStockId   => FAL_LIB_SUBCONTRACTP.GetStockSubcontractP
                                                                                                                                            (iFalLotId   => iLotID) )
                               , aCharId1      => iCharacterizationID1
                               , aCharId2      => iCharacterizationID2
                               , aCharId3      => iCharacterizationID3
                               , aCharId4      => iCharacterizationID4
                               , aCharId5      => iCharacterizationID5
                               , aCharVal1     => iCharacterizationValue1
                               , aCharVal2     => iCharacterizationValue2
                               , aCharVal3     => iCharacterizationValue3
                               , aCharVal4     => iCharacterizationValue4
                               , aCharVal5     => iCharacterizationValue5
                                ) ) loop
      lLotDetailLinkListID.extend(1);
      lLotDetailLinkListID(lLotDetailLinkListID.count)  := ltplLotDetailLink.FAL_LOT_DETAIL_LINK_ID;
    end loop;

    return lLotDetailLinkListID;
  end getLotDetailLinkIDByStockPos;

  /**
  * Description
  *    Retourne l'ID de l'entrée atelier par sa quantité et sa clef secondaire
  */
  function getFactoryInIDByStockPos(
    iLotID                  in FAL_FACTORY_IN.FAL_LOT_ID%type
  , iCptGoodID              in FAL_FACTORY_IN.GCO_GOOD_ID%type
  , iQty                    in FAL_FACTORY_IN.IN_IN_QTE%type
  , iCharacterizationValue1 in FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_1%type
  , iCharacterizationValue2 in FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_2%type
  , iCharacterizationValue3 in FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_3%type
  , iCharacterizationValue4 in FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_4%type
  , iCharacterizationValue5 in FAL_FACTORY_IN.IN_CHARACTERIZATION_VALUE_5%type
  )
    return FAL_FACTORY_IN.FAL_FACTORY_IN_ID%type
  as
    lFactoryInID FAL_FACTORY_IN.FAL_FACTORY_IN_ID%type;
  begin
    select max(FAL_FACTORY_IN_ID)
      into lFactoryInID
      from FAL_FACTORY_IN
     where FAL_LOT_ID = iLotID
       and GCO_GOOD_ID = iCptGoodID
       and IN_IN_QTE = iQty
       and nvl(IN_CHARACTERIZATION_VALUE_1, 0) = nvl(iCharacterizationValue1, 0)
       and nvl(IN_CHARACTERIZATION_VALUE_2, 0) = nvl(iCharacterizationValue2, 0)
       and nvl(IN_CHARACTERIZATION_VALUE_3, 0) = nvl(iCharacterizationValue3, 0)
       and nvl(IN_CHARACTERIZATION_VALUE_4, 0) = nvl(iCharacterizationValue4, 0)
       and nvl(IN_CHARACTERIZATION_VALUE_5, 0) = nvl(iCharacterizationValue5, 0);

    return lFactoryInID;
  exception
    when no_data_found then
      return null;
  end getFactoryInIDByStockPos;

  /**
  * Description
  *    Retourne 1 si un ou plusieurs appairage sont existants pour le Cpt du lot
  */
  function hasPairing(iLotID in FAL_LOT_MATERIAL_LINK.FAL_LOT_ID%type, iCptGoodID in FAL_LOT_MATERIAL_LINK.GCO_GOOD_ID%type)
    return number
  as
    lhasPairing number;
  begin
    select sign(count(FAL_LOT_DETAIL_LINK_ID) )
      into lhasPairing
      from FAL_LOT_DETAIL_LINK ldl
         , FAL_LOT_DETAIL fad
         , STM_STOCK_POSITION spo
     where ldl.FAL_LOT_DETAIL_ID = fad.FAL_LOT_DETAIL_ID
       and fad.FAL_LOT_ID = iLotID
       and spo.STM_STOCK_POSITION_ID = ldl.STM_STOCK_POSITION_ID
       and spo.STM_STOCK_ID = FAL_I_LIB_SUBCONTRACTP.GetStockSubcontractP(iFalLotId => fad.FAL_LOT_ID)
       and spo.GCO_GOOD_ID = iCptGoodID;

    return lhasPairing;
  exception
    when no_data_found then
      return 0;
  end hasPairing;

  /**
  * Description
  *    Retourne 1 si toute la quantité de la position de stock est appairée.
  */
  function isStockPosPaired(
    iLotID              in FAL_LOT_DETAIL.FAL_LOT_ID%type
  , iCptStockPositionID in FAL_NETWORK_LINK.STM_STOCK_POSITION_ID%type
  , iQtyAttrib          in FAL_NETWORK_LINK.FLN_QTY%type
  )
    return number
  as
    lQtyPaired number;
  begin
    /* Quantité appairée pour le lot et la position de stock */
    select nvl(sum(ldl.LDL_QTY), 0)
      into lQtyPaired
      from FAL_LOT_DETAIL_LINK ldl
         , FAL_LOT_DETAIL fad
         , STM_STOCK_POSITION spo
     where ldl.FAL_LOT_DETAIL_ID = fad.FAL_LOT_DETAIL_ID
       and fad.FAL_LOT_ID = iLotID
       and spo.STM_STOCK_POSITION_ID = ldl.STM_STOCK_POSITION_ID
       and spo.STM_STOCK_POSITION_ID = iCptStockPositionID
       and spo.STM_STOCK_ID = FAL_I_LIB_SUBCONTRACTP.GetStockSubcontractP(iFalLotId => fad.FAL_LOT_ID);

    /* Si la quantité attribuée de la position = la quantié appairée de la position */
    if iQtyAttrib = lQtyPaired then
      return 1;
    end if;

    return 0;
  end isStockPosPaired;

  /**
  * Description
  *    Retourne 1 s'il reste des positions attribuées non appairées pour le composant de lot
  */
  function isAttribPosNotPairedRemaining(
    iLotID             in FAL_LOT_MATERIAL_LINK.FAL_LOT_ID%type
  , iLotMaterialLinkID in FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type
  )
    return number
  as
    i number := 0;
  begin
    /* Pour chaque position attribuée du composant de lot */
    for ltplAttribCpt in (select spo.STM_STOCK_POSITION_ID
                               , fln.FLN_QTY
                            from FAL_NETWORK_LINK fln
                               , FAL_NETWORK_NEED fnn
                               , STM_STOCK_POSITION spo
                           where fln.FAL_NETWORK_NEED_ID = fnn.FAL_NETWORK_NEED_ID
                             and spo.STM_STOCK_POSITION_ID = fln.STM_STOCK_POSITION_ID
                             and fnn.FAL_LOT_MATERIAL_LINK_ID = iLotMaterialLinkID) loop
      /* Si elle n'est pas appairée */
      if isStockPosPaired(iLotID => iLotID, iCptStockPositionID => ltplAttribCpt.STM_STOCK_POSITION_ID, iQtyAttrib => ltplAttribCpt.FLN_QTY) = 0 then
        return 1;
      end if;
    end loop;

    return 0;
  end isAttribPosNotPairedRemaining;
end FAL_LIB_PAIRING;
