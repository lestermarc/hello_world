--------------------------------------------------------
--  DDL for Package Body FAL_DRP_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_DRP_FUNCTIONS" 
is
  /**
  * Description
  *     WRAPPER: Insertion d'une demande de réapprovisionnement (FAL_DOC_PROP)
  */
  procedure InsertMovementRequest(
    aGoodId                in     FAL_DOC_PROP.GCO_GOOD_ID%type
  , aStockMovementId       in     FAL_DOC_PROP.STM_STOCK_MOVEMENT_ID%type
  , aDiuId                 in     STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type
  , aDicDistribComplData   in     GCO_COMPL_DATA_DISTRIB.DIC_DISTRIB_COMPL_DATA_ID%type
  , aQuantity              in     FAL_DOC_PROP.FDP_BASIS_QTY%type
  , aBasisDelay            in     FAL_DOC_PROP.FDP_BASIS_DELAY%type
  , aDocRecordId           in     STM_STOCK_MOVEMENT.doc_record_id%type
  , aGcoChar1              in     FAL_DOC_PROP.GCO_CHARACTERIZATION1_ID%type
  , aGcoChar2              in     FAL_DOC_PROP.GCO_CHARACTERIZATION2_ID%type
  , aGcoChar3              in     FAL_DOC_PROP.GCO_CHARACTERIZATION3_ID%type
  , aGcoChar4              in     FAL_DOC_PROP.GCO_CHARACTERIZATION4_ID%type
  , aGcoChar5              in     FAL_DOC_PROP.GCO_CHARACTERIZATION5_ID%type
  , aFdpChar1              in     FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1%type
  , aFdpChar2              in     FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_2%type
  , aFdpChar3              in     FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_3%type
  , aFdpChar4              in     FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_4%type
  , aFdpChar5              in     FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_5%type
  , aResult                out    integer
  , aFAL_SUPPLY_REQUEST_ID in     FAL_DOC_PROP.FAL_SUPPLY_REQUEST_ID%type default null
  )
  is
  begin
    FAL_PRC_DRP.InsertMovementRequest(aGoodId
                                    , aStockMovementId
                                    , aDiuId
                                    , aDicDistribComplData
                                    , aQuantity
                                    , aBasisDelay
                                    , aDocRecordId
                                    , aGcoChar1
                                    , aGcoChar2
                                    , aGcoChar3
                                    , aGcoChar4
                                    , aGcoChar5
                                    , aFdpChar1
                                    , aFdpChar2
                                    , aFdpChar3
                                    , aFdpChar4
                                    , aFdpChar5
                                    , aResult
                                    , aFAL_SUPPLY_REQUEST_ID
                                     );
  end;

  /**
  * Description
  *     Insertion d'une demande de réapprovisionnement (FAL_DOC_PROP)
  */
  function InsertMovementRequest(
    aGoodId                in FAL_DOC_PROP.GCO_GOOD_ID%type
  , aStockMovementId       in FAL_DOC_PROP.STM_STOCK_MOVEMENT_ID%type
  , aDiuId                 in STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type
  , aDicDistribComplData   in GCO_COMPL_DATA_DISTRIB.DIC_DISTRIB_COMPL_DATA_ID%type
  , aQuantity              in FAL_DOC_PROP.FDP_BASIS_QTY%type
  , aBasisDelay            in FAL_DOC_PROP.FDP_BASIS_DELAY%type
  , aDocRecordId           in STM_STOCK_MOVEMENT.doc_record_id%type
  , aGcoChar1              in FAL_DOC_PROP.GCO_CHARACTERIZATION1_ID%type
  , aGcoChar2              in FAL_DOC_PROP.GCO_CHARACTERIZATION2_ID%type
  , aGcoChar3              in FAL_DOC_PROP.GCO_CHARACTERIZATION3_ID%type
  , aGcoChar4              in FAL_DOC_PROP.GCO_CHARACTERIZATION4_ID%type
  , aGcoChar5              in FAL_DOC_PROP.GCO_CHARACTERIZATION5_ID%type
  , aFdpChar1              in FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1%type
  , aFdpChar2              in FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_2%type
  , aFdpChar3              in FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_3%type
  , aFdpChar4              in FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_4%type
  , aFdpChar5              in FAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_5%type
  , aFAL_SUPPLY_REQUEST_ID in FAL_DOC_PROP.FAL_SUPPLY_REQUEST_ID%type default null
  )
    return boolean
  is
  begin
    return FAL_PRC_DRP.InsertMovementRequest(aGoodId
                                           , aStockMovementId
                                           , aDiuId
                                           , aDicDistribComplData
                                           , aQuantity
                                           , aBasisDelay
                                           , aDocRecordId
                                           , aGcoChar1
                                           , aGcoChar2
                                           , aGcoChar3
                                           , aGcoChar4
                                           , aGcoChar5
                                           , aFdpChar1
                                           , aFdpChar2
                                           , aFdpChar3
                                           , aFdpChar4
                                           , aFdpChar5
                                           , aFAL_SUPPLY_REQUEST_ID
                                            );
  end InsertMovementRequest;

  /**
  * Description
  *     Création DRA
  */
  procedure EvtsGenDRA(
    aStockMovement in STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type
  , adiu           in STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type
  )
  is
  begin
    FAL_PRC_DRP.EvtsGenDRA(aStockMovement, adiu);
  end EvtsGenDRA;

  procedure EvtsMajDRA(
    aDRA      in FAL_DOC_PROP.FAL_DOC_PROP_ID%type
  , aType     in varchar2
  , aQte      in number
  , aReliquat in GCO_COMPL_DATA_DISTRIB.C_DRP_RELIQUAT%type
  , aDoc      in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  )
  is
  begin
    FAL_PRC_DRP.EvtsMajDRA(aDRA, aType, aQte, aReliquat, aDoc);
  end;

  procedure EvtsSupprDRA(
    aDRA  in FAL_DOC_PROP.FAL_DOC_PROP_ID%type
  , aType in varchar
  , aQte  in number
  , aDoc  in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  )
  is
  begin
    FAL_PRC_DRP.EvtsSupprDRA(aDRA, aType, aQte, aDoc);
  end;

  procedure EvtsGenDRAStockMini
  is
  begin
    FAL_PRC_DRP.EvtsGenDRAStockMini;
  end;

  procedure EvtSeekDistribUnitToDeliver(aDate in date, aDIU_List out varchar)
  is
  begin
    FAL_LIB_DRP.EvtSeekDistribUnitToDeliver(aDate, aDIU_List);
  end;

  function IsDeliveryUnitValid(aDate in date, aDIU in STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type)
    return integer
  is
  begin
    return FAL_LIB_DRP.IsDeliveryUnitValid(aDate, aDIU);
  end;

/* -------------------------------------------------------------------------- */
  procedure GetStockPrvOutAndAvlQ(
    aGcoGoodId          in     GCO_GOOD.GCO_GOOD_ID%type
  , aStockMovementId    in     fal_doc_prop.stm_stock_movement_id%type
  , aQProvisoryOutput   out    STM_STOCK_POSITION.SPO_PROVISORY_OUTPUT%type
  , aQAvailableQuantity out    STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type
  )
  is
  begin
    FAL_LIB_DRP.GetStockPrvOutAndAvlQ(aGcoGoodId, aStockMovementId, aQProvisoryOutput, aQAvailableQuantity);
  end GetStockPrvOutAndAvlQ;

  function GetStockProvisoryOutput(
    aGcoGoodId     in GCO_GOOD.GCO_GOOD_ID%type
  , aStmStockId    in STM_STOCK.STM_STOCK_ID%type
  , aStmLocationId in STM_LOCATION.STM_LOCATION_ID%type
  )
    return number
  is
  begin
    return FAL_LIB_DRP.GetStockProvisoryOutput(aGcoGoodId, aStmStockId, aStmLocationId);
  end GetStockProvisoryOutput;

  procedure GetDrpValues(
    aDRA             in     number
  , aBalanceQuantity out    FAL_DOC_PROP.FDP_DRP_BALANCE_QUANTITY%type
  , aStockMovementId out    FAL_DOC_PROP.STM_STOCK_MOVEMENT_ID%type
  , aFdpNumber       out    FAL_DOC_PROP.FDP_NUMBER%type
  , aDrpBalanced     out    FAL_DOC_PROP.FDP_DRP_BALANCED%type
  )
  is
  begin
    FAL_LIB_DRP.GetDrpValues(aDRA, aBalanceQuantity, aStockMovementId, aFdpNumber, aDrpBalanced);
  end;

  procedure InsertDrpHistory(
    aDRA             in FAL_DOC_PROP.FAL_DOC_PROP_ID%type
  , aType            in varchar
  , aQte             in number
  , aBalanceQuantity in FAL_DOC_PROP.FDP_DRP_BALANCE_QUANTITY%type
  , aStockMovementId in FAL_DOC_PROP.STM_STOCK_MOVEMENT_ID%type
  , aDoc             in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aFdpNumber       in FAL_DOC_PROP.FDP_NUMBER%type
  , aDrpBalanced     in FAL_DOC_PROP.FDP_DRP_BALANCED%type default 0
  )
  is
  begin
    FAL_PRC_DRP.InsertDrpHistory(aDRA, aType, aQte, aBalanceQuantity, aStockMovementId, aDoc, aFdpNumber, aDrpBalanced);
  end;

  function CalcSumBesoins(
    aGoodId          in GCO_GOOD.GCO_GOOD_ID%type
  , aStockMovementId in fal_doc_prop.stm_stock_movement_id%type
  )
    return number
  is
  begin
    return FAL_LIB_DRP.CalcSumBesoins(aGoodId, aStockMovementId);
  end;

  function CalcSumBesoins(
    aGoodId     in GCO_GOOD.GCO_GOOD_ID%type
  , aLocationId in STM_STOCK_MOVEMENT.STM_LOCATION_ID%type
  , aStockId    in STM_STOCK_MOVEMENT.STM_STOCK_ID%type
  )
    return number
  is
  begin
    return FAL_LIB_DRP.CalcSumBesoins(aGoodId, aLocationId, aStockId);
  end;

  function CalcSumAppro(
    aGoodId          in GCO_GOOD.GCO_GOOD_ID%type
  , aStockMovementId in FAL_DOC_PROP.STM_STOCK_MOVEMENT_ID%type
  )
    return number
  is
  begin
    return FAL_LIB_DRP.CalcSumAppro(aGoodId, aStockMovementId);
  end;

  function CalcSumAppro(
    aGoodId     in GCO_GOOD.GCO_GOOD_ID%type
  , aLocationId in STM_STOCK_MOVEMENT.STM_LOCATION_ID%type
  , aStockId    in STM_STOCK_MOVEMENT.STM_STOCK_ID%type
  )
    return number
  is
  begin
    return FAL_LIB_DRP.CalcSumAppro(aGoodId, aLocationId, aStockId);
  end;

  procedure GetCharacterization(
    aGoodId          in     STM_STOCK_MOVEMENT.GCO_GOOD_ID%type
  , aStockMovementId in     STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type
  , aStockLocationId out    STM_STOCK_MOVEMENT.STM_LOCATION_ID%type
  , aStockId         out    STM_STOCK_MOVEMENT.STM_STOCK_ID%type
  , aGcoChar1        out    STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , aGcoChar2        out    STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , aGcoChar3        out    STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , aGcoChar4        out    STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , aGcoChar5        out    STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  )
  is
  begin
    FAL_LIB_DRP.GetCharacterization(aGoodId
                                  , aStockMovementId
                                  , aStockLocationId
                                  , aStockId
                                  , aGcoChar1
                                  , aGcoChar2
                                  , aGcoChar3
                                  , aGcoChar4
                                  , aGcoChar5
                                   );
  end;

  procedure GetDiuBlocked(
    aDistributionUnit in     STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type
  , aDIUBlockedFrom   out    STM_DISTRIBUTION_UNIT.DIU_BLOCKED_FROM%type
  , aDIUBlockedTo     out    STM_DISTRIBUTION_UNIT.DIU_BLOCKED_TO%type
  , aPrePareTime      out    STM_DISTRIBUTION_UNIT.DIU_PREPARE_TIME%type
  )
  is
  begin
    FAL_LIB_DRP.GetDiuBlocked(aDistributionUnit, aDIUBlockedFrom, aDIUBlockedTo, aPrePareTime);
  end GetDiuBlocked;

  procedure GetCodeBlocked(
    aDicDistribComplData in     GCO_COMPL_DATA_DISTRIB.DIC_DISTRIB_COMPL_DATA_ID%type
  , aDIUBlockedFrom      out    STM_DISTRIBUTION_UNIT.DIU_BLOCKED_FROM%type
  , aDIUBlockedTo        out    STM_DISTRIBUTION_UNIT.DIU_BLOCKED_TO%type
  , aPrePareTime         out    STM_DISTRIBUTION_UNIT.DIU_PREPARE_TIME%type
  )
  is
  begin
    FAL_LIB_DRP.GetCodeBlocked(aDicDistribComplData, aDIUBlockedFrom, aDIUBlockedTo, aPrePareTime);
  end GetCodeBlocked;

  function GetIntermediateDelay(aDistributionUnit in STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type)
    return date
  is
  begin
    return FAL_LIB_DRP.GetIntermediateDelay(aDistributionUnit);
  end;

  procedure CtrlRegleApproSortie(
    aGoodID              in GCO_GOOD.GCO_GOOD_ID%type
  , aDistributionUnit    in STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type
  , aReapproUnit         in STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type
  , aDicDistribComplData in GCO_COMPL_DATA_DISTRIB.DIC_DISTRIB_COMPL_DATA_ID%type
  , aStockMovement       in STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type
  , aCharId1             in STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , aCharId2             in STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , aCharId3             in STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , aCharId4             in STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , aCharId5             in STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , aChar1               in STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type
  , aChar2               in STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type
  , aChar3               in STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type
  , aChar4               in STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type
  , aChar5               in STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type
  , aRecord              in DOC_RECORD.DOC_RECORD_ID%type
  , aMovQuantite         in STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type
  , aMovDate             in STM_STOCK_MOVEMENT.SMO_MOVEMENT_DATE%type
  )
  is
    vEntityMovement FWK_I_TYP_STM_ENTITY.tStockMovement;
  begin
    vEntityMovement.GCO_GOOD_ID                   := aGoodID;
    vEntityMovement.STM_STOCK_MOVEMENT_ID         := aStockMovement;
    vEntityMovement.GCO_CHARACTERIZATION_ID       := aCharId1;
    vEntityMovement.GCO_GCO_CHARACTERIZATION_ID   := aCharId2;
    vEntityMovement.GCO2_GCO_CHARACTERIZATION_ID  := aCharId3;
    vEntityMovement.GCO3_GCO_CHARACTERIZATION_ID  := aCharId4;
    vEntityMovement.GCO4_GCO_CHARACTERIZATION_ID  := aCharId5;
    vEntityMovement.SMO_CHARACTERIZATION_VALUE_1  := aChar1;
    vEntityMovement.SMO_CHARACTERIZATION_VALUE_2  := aChar2;
    vEntityMovement.SMO_CHARACTERIZATION_VALUE_3  := aChar3;
    vEntityMovement.SMO_CHARACTERIZATION_VALUE_4  := aChar4;
    vEntityMovement.SMO_CHARACTERIZATION_VALUE_5  := aChar5;
    vEntityMovement.DOC_RECORD_ID                 := aRecord;
    vEntityMovement.SMO_MOVEMENT_QUANTITY         := aMovQuantite;
    vEntityMovement.SMO_MOVEMENT_DATE             := aMovDate;
    FAL_PRC_DRP.CtrlRegleApproSortie(vEntityMovement
                                   , aDistributionUnit
                                   , aReapproUnit
                                   , aDicDistribComplData
                                    );
  end CtrlRegleApproSortie;

  procedure CtrlRegleApproEntree(
    aGoodID              in GCO_GOOD.GCO_GOOD_ID%type
  , aDistributionUnit    in STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type
  , aReapproUnit         in STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type
  , aDicDistribComplData in GCO_COMPL_DATA_DISTRIB.DIC_DISTRIB_COMPL_DATA_ID%type
  , aCharId1             in STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , aCharId2             in STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , aCharId3             in STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , aCharId4             in STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , aCharId5             in STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , aChar1               in STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type
  , aChar2               in STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type
  , aChar3               in STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type
  , aChar4               in STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type
  , aChar5               in STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type
  , aDocId               in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aQte                 in STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type
  )
  is
    vEntityMovement FWK_I_TYP_STM_ENTITY.tStockMovement;
  begin
    vEntityMovement.GCO_GOOD_ID                   := aGoodID;
    vEntityMovement.GCO_CHARACTERIZATION_ID       := aCharId1;
    vEntityMovement.GCO_GCO_CHARACTERIZATION_ID   := aCharId2;
    vEntityMovement.GCO2_GCO_CHARACTERIZATION_ID  := aCharId3;
    vEntityMovement.GCO3_GCO_CHARACTERIZATION_ID  := aCharId4;
    vEntityMovement.GCO4_GCO_CHARACTERIZATION_ID  := aCharId5;
    vEntityMovement.SMO_CHARACTERIZATION_VALUE_1  := aChar1;
    vEntityMovement.SMO_CHARACTERIZATION_VALUE_2  := aChar2;
    vEntityMovement.SMO_CHARACTERIZATION_VALUE_3  := aChar3;
    vEntityMovement.SMO_CHARACTERIZATION_VALUE_4  := aChar4;
    vEntityMovement.SMO_CHARACTERIZATION_VALUE_5  := aChar5;
    vEntityMovement.SMO_MOVEMENT_QUANTITY         := aQte;
    FAL_PRC_DRP.CtrlRegleApproEntree(vEntityMovement, aDistributionUnit, aReapproUnit, aDicDistribComplData, aDocId);
  end CtrlRegleApproEntree;

  function CheckCaracterization1or2(
    aGoodId    GCO_GOOD.GCO_GOOD_ID%type
  , aCharId in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  )
    return boolean
  is
  begin
    return FAL_LIB_DRP.CheckCaracterization1or2(aGoodId, aCharId);
  end CheckCaracterization1or2;

  procedure DeleteOneDRA(
    aDRA in FAL_DOC_PROP.FAL_DOC_PROP_ID%type
  , aQte in STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type
  )
  is
  begin
    FAL_PRC_DRP.DeleteOneDRA(aDRA, aQte);
  end DeleteOneDRA;
end FAL_DRP_FUNCTIONS;
