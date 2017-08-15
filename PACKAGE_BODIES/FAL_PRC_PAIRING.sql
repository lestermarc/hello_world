--------------------------------------------------------
--  DDL for Package Body FAL_PRC_PAIRING
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_PAIRING" 
is
  /**
  * Description
  *    Création d'un lien d'appairage entre un détail lot et un composant en atelier
  *    ou en stock STT
  */
  procedure AddAlignement(
    iLotDetailID       FAL_LOT_DETAIL.FAL_LOT_DETAIL_ID%type
  , iFactoryInID       FAL_FACTORY_IN.FAL_FACTORY_IN_ID%type
  , iAlignQty          FAL_LOT_DETAIL_LINK.LDL_QTY%type
  , iDescription       FAL_LOT_DETAIL_LINK.LDL_DESCRIPTION%type default null
  , iLotProgressID     FAL_LOT_PROGRESS.FAL_LOT_PROGRESS_ID%type default null
  , iProgressDetailQty FAL_LOT_PROGRESS_DETAIL.LPD_QTY%type default 0
  , iCDetailType       FAL_LOT_PROGRESS_DETAIL.C_LOT_DETAIL_TYPE%type default FAL_LOT_DETAIL_FUNCTIONS.tdRealized
  , iDicRebutId        FAL_LOT_PROGRESS_DETAIL.DIC_REBUT_ID%type default null
  , iRejectDescription FAL_LOT_PROGRESS_DETAIL.LPD_REJECT_DESCRIPTION%type default null
  , iCFabType          FAL_LOT.C_FAB_TYPE%type
  , iStockPositionID   FAL_LOT_DETAIL_LINK.STM_STOCK_POSITION_ID%type default null
  )
  as
    lLotProgressDetailID    FAL_LOT_PROGRESS_DETAIL.FAL_LOT_PROGRESS_DETAIL_ID%type;
    ltCRUD_FalLotDetailLink FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    if nvl(iLotProgressID, 0) <> 0 then
      lLotProgressDetailID  :=
        FAL_LOT_DETAIL_FUNCTIONS.getLotProgressDetailId(iLotProgressId       => iLotProgressID
                                                      , iLotDetailId         => iLotDetailID
                                                      , iQty                 => iProgressDetailQty
                                                      , iCDetailType         => iCDetailType
                                                      , iDicRebutID          => iDicRebutID
                                                      , iRejectDescription   => iRejectDescription
                                                       );
    end if;

    FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalLotDetailLink, ltCRUD_FalLotDetailLink, true);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLotDetailLink, 'FAL_LOT_DETAIL_ID', iLotDetailID);

    if iCFabType = '4' then
      FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLotDetailLink, 'STM_STOCK_POSITION_ID', iStockPositionID);
    else
      FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLotDetailLink, 'FAL_FACTORY_IN_ID', iFactoryInID);
    end if;

    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLotDetailLink, 'LDL_QTY', iAlignQty);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLotDetailLink, 'LDL_DESCRIPTION', iDescription);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLotDetailLink, 'FAL_LOT_PROGRESS_DETAIL_ID', lLotProgressDetailID);
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_FalLotDetailLink);
    FWK_I_MGT_ENTITY.Release(ltCRUD_FalLotDetailLink);
  end AddAlignement;

  /**
  * Description
  *    Mise à jour de la table d'appairage avec l'entrée atelier correspondantes
  *    au positions du stock STT du tableau.
  */
  procedure updAlignementWithFactEntries(ittSTTStockPositionInfos in out nocopy FAL_LIB_PAIRING.ttSTTStockPositionInfos)
  as
    ltCRUD_FalLotDetailLink FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    if (ittSTTStockPositionInfos.count > 0) then
      for i in ittSTTStockPositionInfos.first .. ittSTTStockPositionInfos.last loop
        if     (ittSTTStockPositionInfos(i).FAL_FACTORY_IN_ID is not null)
           and (ittSTTStockPositionInfos(i).FAL_LOT_DETAIL_LINK_ID is not null) then
          /* Mise à jour de l'appairage avec l'ID de l'entrée atelier correspondante */
          FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalLotDetailLink, ltCRUD_FalLotDetailLink, false, ittSTTStockPositionInfos(i).FAL_LOT_DETAIL_LINK_ID);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalLotDetailLink, 'FAL_FACTORY_IN_ID', ittSTTStockPositionInfos(i).FAL_FACTORY_IN_ID);
          FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_FalLotDetailLink);
          FWK_I_MGT_ENTITY.Release(ltCRUD_FalLotDetailLink);
        end if;
      end loop;
    end if;
  end updAlignementWithFactEntries;
end FAL_PRC_PAIRING;
