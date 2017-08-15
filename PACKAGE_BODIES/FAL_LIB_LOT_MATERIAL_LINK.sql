--------------------------------------------------------
--  DDL for Package Body FAL_LIB_LOT_MATERIAL_LINK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_LOT_MATERIAL_LINK" 
is

  /**
  * Description
  *    Retourne l'ID du composant du lot correspondant au bien et lot transmis en paramètre.
  */
  function getComponentID(
    iCptGoodID in GCO_GOOD.GCO_GOOD_ID%type
  , iLotID     in FAL_LOT_MATERIAL_LINK.FAL_LOT_ID%type default null
  , iLotPropID in FAL_LOT_MAT_LINK_PROP.FAL_LOT_PROP_ID%type default null
  ) return FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type
  as
    lComponentID FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type;
  begin
    if iLotID is not null then
      select FAL_LOT_MATERIAL_LINK_ID
        into lComponentID
        from FAL_LOT_MATERIAL_LINK
       where GCO_GOOD_ID = iCptGoodID
         and FAL_LOT_ID = iLotID
         and ROWNUM = 1;
    elsif iLotPropID is not null then
      select FAL_LOT_MAT_LINK_PROP_ID
        into lComponentID
        from FAL_LOT_MAT_LINK_PROP
       where GCO_GOOD_ID = iCptGoodID
         and FAL_LOT_PROP_ID = iLotPropID
         and ROWNUM = 1;
    else
      ra('PCS - iLotID or iLotPropID are mandatory to call function FAL_LIB_LOT_MATERIAL_LINK.getComponentID');
    end if;
    RETURN lComponentID;
  end getComponentID;

  /**
  * Description
  *    Cette function retourne la clef primaire du premier composant de lot de type dérivé
  *    contenant l'alliage dont la clef primaire est transmise en paramètre.
  */
  function getDvtKindLotCptWithGivenAlloy(inGcoAlloyID in GCO_ALLOY.GCO_ALLOY_ID%type)
    return FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type
  as
    lnFalLotMaterialLinkID FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type;
  begin
    select lom.FAL_LOT_MATERIAL_LINK_ID
      into lnFalLotMaterialLinkID
      from FAL_LOT_MATERIAL_LINK lom
         , GCO_GOOD goo
         , GCO_PRECIOUS_MAT gpm
         , GCO_ALLOY gal
     where lom.GCO_GOOD_ID = goo.GCO_GOOD_ID
       and gpm.GCO_GOOD_ID = goo.GCO_GOOD_ID
       and gal.GCO_ALLOY_ID = gpm.GCO_ALLOY_ID
       and lom.C_KIND_COM = 2
       and gal.GCO_ALLOY_ID = inGcoAlloyID
       and rownum <= 1;   /* Le 1er enregistrement */

    return lnFalLotMaterialLinkID;
  end getDvtKindLotCptWithGivenAlloy;

  /**
  * Description
  *    Cette function retourne le poids théorique de la matière fine dans le composant
  *    multiplié par la quantité demandée du composant.
  */
  function getPMTheoreticalWeight(
    inLomFullReqQty in FAL_LOT_MATERIAL_LINK.LOM_FULL_REQ_QTY%type
  , inGacRate       in GCO_ALLOY_COMPONENT.GAC_RATE%type
  , inGcoAlloyID    in GCO_ALLOY.GCO_ALLOY_ID%type
  , inGcoGoodID     in FAL_LOT_MATERIAL_LINK.GCO_GOOD_ID%type
  )
    return number
  as
    lnPMTheoreticalWeight number;
  begin
    lnPMTheoreticalWeight  :=
                         inLomFullReqQty * GCO_I_LIB_PRECIOUS_MAT.getWeightDeliver(inGcoGoodID => inGcoGoodID, inGcoAlloyID => inGcoAlloyID)
                         *(inGacRate * 0.01);
    return lnPMTheoreticalWeight;
  end getPMTheoreticalWeight;

  /**
  * Description
  *    Cette function retourne la somme du poids de la matiere fine dans l'ensemble
  *    des composants actifs de type composants du produit terminé du lot.
  */
  function getSumBasisMatInGood(
    inFalLotID   in FAL_LOT_MATERIAL_LINK.FAL_LOT_ID%type
  , inGcoAlloyID in GCO_ALLOY.GCO_ALLOY_ID%type
  , inPercent    in GCO_ALLOY_COMPONENT.GAC_RATE%type
  )
    return number
  as
    lnSumBasisMatInGood number;
  begin
    select nvl(sum(LOM_UTIL_COEF * GCO_I_LIB_PRECIOUS_MAT.getWeightDeliver(inGcoGoodID => GCO_GOOD_ID, inGcoAlloyID => inGcoAlloyID) *(inPercent * 0.01) ), 0)
      into lnSumBasisMatInGood
      from FAL_LOT_MATERIAL_LINK
     where FAL_LOT_ID = inFalLotID
       and C_TYPE_COM = '1'   /* Actif */
       and C_KIND_COM in('1', '2');   /* "Composants" et "Dérivés" */

    return lnSumBasisMatInGood;
  exception
    when no_data_found then
      return 0;
  end getSumBasisMatInGood;

  /**
  * Description
  *    Retourne le besoin lié au composant de lot de fabrication transmis.
  */
  function getNetworkNeedID(iLotMaterialLinkID in FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type)
    return FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type
  as
    lNetworkNeedID FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type;
  begin
    select FAL_NETWORK_NEED_ID
      into lNetworkNeedID
      from FAL_NETWORK_NEED
     where FAL_LOT_MATERIAL_LINK_ID = iLotMaterialLinkID;

    return lNetworkNeedID;
  exception
    when no_data_found then
      return 0;
  end getNetworkNeedID;

  /**
  * Description
  *    Retourne l'ID du besoin lié au composant du lot correspondant au bien transmis en paramètre.
  */
  function getNetworkNeedIDByCptGoodID(iGoodID in FAL_LOT_MATERIAL_LINK.GCO_GOOD_ID%type, iLotID in FAL_LOT_MATERIAL_LINK.FAL_LOT_ID%type)
    return FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type
  as
  begin
    return getNetworkNeedID(iLotMaterialLinkID => getComponentID(iCptGoodID => iGoodID, iLotID => iLotID) );
  end getNetworkNeedIDByCptGoodID;

  /**
  * Description
  *    Retourne le bien et le coefficient d'utilisation du composant de lot dont
  *    l'ID est transmis en paramètre.
  */
  procedure getCptData(
    iLotMaterialLinkID in     FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type
  , oCptGoodID         out    FAL_LOT_MATERIAL_LINK.GCO_GOOD_ID%type
  , oUtilCoef          out    FAL_LOT_MATERIAL_LINK.LOM_UTIL_COEF%type
  )
  as
  begin
    oCptGoodID  :=
           FWK_I_LIB_ENTITY.getNumberFieldFromPk(iv_entity_name   => 'FAL_LOT_MATERIAL_LINK', iv_column_name => 'GCO_GOOD_ID'
                                               , it_pk_value      => iLotMaterialLinkID);
    oUtilCoef   :=
         FWK_I_LIB_ENTITY.getNumberFieldFromPk(iv_entity_name   => 'FAL_LOT_MATERIAL_LINK', iv_column_name => 'LOM_UTIL_COEF'
                                             , it_pk_value      => iLotMaterialLinkID);
  end;

  /**
  *   recherche du stock sous traitant (STO_DESCRIPTION) à partir de la séquence d'opération liée au composant
  */
  function GetSubContractStock(
    iFalLotMatLinkID in FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type default null
  , iFalLotID        in FAL_LOT_MATERIAL_LINK.FAL_LOT_ID%type default null
  , inTaskNum        in FAL_LOT_MATERIAL_LINK.LOM_TASK_SEQ%type default null
  )
    return STM_STOCK.STO_DESCRIPTION%type
  is
    lResult     STM_STOCK.STO_DESCRIPTION%type;
    lFalLotID   FAL_LOT_MATERIAL_LINK.FAL_LOT_ID%type;
    lTaskNum    FAL_LOT_MATERIAL_LINK.LOM_TASK_SEQ%type;
    lSupplierId FAL_TASK_LINK.PAC_SUPPLIER_PARTNER_ID%type;
  begin
    -- recherche des id nécessaires
    if iFalLotID is null then
      if iFalLotMatLinkID is not null then
        select FAL_LOT_ID
             , nvl(inTaskNum, LOM_TASK_SEQ)
          into lFalLotId
             , lTaskNum
          from FAL_LOT_MATERIAL_LINK
         where FAL_LOT_MATERIAL_LINK_ID = iFalLotMatLinkID;
      else
        ra('PCS - iFalLotMatLinkID or iFalLotID are mandatory to call function FAL_LIB_LOT_MATERIAL_LINK.GetSubContractStock');
      end if;
    else
      lTaskNum   := inTaskNum;
      lFalLotId  := iFalLotID;
    end if;

    -- recherche du sous-traitant
    select max(PAC_SUPPLIER_PARTNER_ID)
      into lSupplierId
      from FAL_TASK_LINK
     where FAL_LOT_ID = lFalLotId
       and SCS_STEP_NUMBER = lTaskNum;

    -- si un ss-traitant est trouvé, on retourne la description du stock ou '--' si pas de stock ss-trait
    if lSupplierId is not null then
      return nvl(STM_I_LIB_STOCK.getSubCStockDescription(lSupplierId), '--');
    -- si pas de sous-traitant, on retourne null
    else
      return null;
    end if;
  end GetSubContractStock;

  /**
  * Description
  *    Retourne 1 si le bien est attaché à des opérations externes de l'OF ou de
  *    la proposition d'OF.
  */
  procedure isCptLinkedWithExternalTask(
    iCptGoodID   in     GCO_GOOD.GCO_GOOD_ID%type
  , iLotID       in     FAL_LOT_MATERIAL_LINK.FAL_LOT_Id%type default null
  , iLotPropID   in     FAL_LOT_MAT_LINK_PROP.FAL_LOT_PROP_ID%type default null
  , oIsLinked    out    number
  , oSSTOStockID out    STM_STOCK.STM_STOCK_ID%type
  )
  as
    lIsCptLinkedWithExternalTask number := 0;
  begin
    if iLotID is not null then
      select sign(count(lom.LOM_TASK_SEQ))
        into lIsCptLinkedWithExternalTask
        from FAL_LOT_MATERIAL_LINK lom
           , FAL_TASK_LINK tal
       where lom.LOM_TASK_SEQ = tal.SCS_STEP_NUMBER
         and lom.FAL_LOT_ID = tal.FAL_LOT_ID
         and tal.C_TASK_TYPE = '2'
         and lom.GCO_GOOD_ID = iCptGoodID
         and lom.FAL_LOT_ID = iLotID;
    elsif iLotPropID is not null then
      select sign(count(lom.LOM_TASK_SEQ))
        into lIsCptLinkedWithExternalTask
        from FAL_LOT_MAT_LINK_PROP lom
           , FAL_TASK_LINK_PROP tal
       where lom.LOM_TASK_SEQ = tal.SCS_STEP_NUMBER
         and lom.FAL_LOT_PROP_ID = tal.FAL_LOT_PROP_ID
         and tal.C_TASK_TYPE = '2'
         and lom.GCO_GOOD_ID = iCptGoodID
         and lom.FAL_LOT_PROP_ID = iLotPropID;
    end if;

    if lIsCptLinkedWithExternalTask = 1 then
      oIsLinked     := 1;
      oSSTOStockID  := FAL_LIB_SUBCONTRACTO.getStockSubcontractO(iCptGoodID => iCptGoodID, iLotID => iLotID, iLotPropID => iLotPropID);
    else
      oIsLinked     := 0;
      oSSTOStockID  := 0;
    end if;
  exception
    when no_data_found then
      oIsLinked     := 0;
      oSSTOStockID  := null;
  end isCptLinkedWithExternalTask;

  /**
  * Description
  *    Retourne 1 si le bien est attaché à des opérations externes de l'OF ou de
  *    la proposition d'OF.
  */
  function isCptLinkedWithExternalTask(
    iCptGoodID   in     GCO_GOOD.GCO_GOOD_ID%type
  , iLotID       in     FAL_LOT_MATERIAL_LINK.FAL_LOT_Id%type default null
  , iLotPropID   in     FAL_LOT_MAT_LINK_PROP.FAL_LOT_PROP_ID%type default null
  ) return number deterministic
  as
    lIsLinked    number;
    lSubCOStockID STM_STOCK.STM_STOCK_ID%type;
  begin
    isCptLinkedWithExternalTask(iCptGoodID => iCptGoodID, iLotID => iLotID, iLotPropID => iLotPropID, oIsLinked => lIsLinked, oSSTOStockID => lSubCOStockID);
    return lIsLinked;
  end isCptLinkedWithExternalTask;

  /**
  * Description
  *    Retourne l'ID du lot du composant ou de la proposition de composant.
  */
  function getLotID(
    iCptID in FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type default null
  , iCptPropID in FAL_LOT_MAT_LINK_PROP.FAL_LOT_MAT_LINK_PROP_ID%type default null
  )
  return FAL_LOT.FAL_LOT_ID%type
  as
    lLotID FAL_LOT.FAL_LOT_ID%type;
  begin
    if iCptID is not null then
      lLotID := FWK_I_LIB_ENTITY.getNumberFieldFromPk(iv_entity_name => 'FAL_LOT_MATERIAL_LINK', iv_column_name => 'FAL_LOT_ID', it_pk_value => iCptID);
    elsif iCptPropID is not null then
      lLotID := FWK_I_LIB_ENTITY.getNumberFieldFromPk(iv_entity_name => 'FAL_LOT_MAT_LINK_PROP', iv_column_name => 'FAL_LOT_ID', it_pk_value => iCptID);
    else
      ra('PCS - iCptID or iCptPropID are mandatory to call function FAL_LIB_LOT_MATERIAL_LINK.getLotID');
    end if;
    return lLotID;
  end getLotID;
end FAL_LIB_LOT_MATERIAL_LINK;
