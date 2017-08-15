--------------------------------------------------------
--  DDL for Package Body DOC_PRC_POSITION_DETAIL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PRC_POSITION_DETAIL" 
is
  /**
  * Description
  *   Mise à jour du statut qualité du détail de position courant en fonction du détail de caractérisation lié.
  */
  procedure SyncDetailQualityStatus(iPositionDetailId in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
  is
    ltPosDet          FWK_I_TYP_DEFINITION.t_crud_def;
    lnElementNumberID STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    lnQualityStatusID GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type;
    lvPDE_PIECE       DOC_POSITION_DETAIL.PDE_PIECE%type;
    lvPDE_SET         DOC_POSITION_DETAIL.PDE_SET%type;
    lvPDE_VERSION     DOC_POSITION_DETAIL.PDE_VERSION%type;
    lnGCO_GOOD_ID     GCO_GOOD.GCO_GOOD_ID%type;
  begin
    -- Seul le detail de positon qui n'ont pas encore de mouvement généré et ayant au moins une caractérisation
    -- et dont le bien possède une gestion des détails de caracterisation sont mis à jour
    begin
      select PDE.GCO_GOOD_ID
           , PDE.PDE_PIECE
           , PDE.PDE_SET
           , PDE.PDE_VERSION
        into lnGCO_GOOD_ID
           , lvPDE_PIECE
           , lvPDE_SET
           , lvPDE_VERSION
        from DOC_POSITION_DETAIL PDE
       where PDE.DOC_POSITION_DETAIL_ID = iPositionDetailId
         and PDE.GCO_CHARACTERIZATION_ID is not null
         and GCO_I_LIB_CHARACTERIZATION.HasQualityStatusManagement(PDE.GCO_GOOD_ID) = 1
         and PDE.PDE_GENERATE_MOVEMENT = 0;
    exception
      when no_data_found then
        lnGCO_GOOD_ID  := null;
    end;

    if lnGCO_GOOD_ID is not null then
      lnElementNumberID  :=
                       STM_I_LIB_ELEMENT_NUMBER.GetDetailElement(iGoodId    => lnGCO_GOOD_ID, iPiece => lvPDE_PIECE, iSet => lvPDE_SET
                                                               , iVersion   => lvPDE_VERSION);

      if lnElementNumberID is not null then
        lnQualityStatusID  := FWK_I_LIB_ENTITY.getNumberFieldFromPk('STM_ELEMENT_NUMBER', 'GCO_QUALITY_STATUS_ID', lnElementNumberID);

        if lnQualityStatusID is not null then
          -- Mise à jour du détail de position avec le statut qualité du détail de caractérisation
          FWK_I_MGT_ENTITY.new(FWK_I_TYP_DOC_ENTITY.gcDocPositionDetail, ltPosDet, false);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltPosDet, 'DOC_POSITION_DETAIL_ID', iPositionDetailId);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltPosDet, 'GCO_QUALITY_STATUS_ID', lnQualityStatusID);
          FWK_I_MGT_ENTITY.UpdateEntity(ltPosDet);
          FWK_I_MGT_ENTITY.release(ltPosDet);
        end if;
      end if;
    end if;
  end SyncDetailQualityStatus;
end DOC_PRC_POSITION_DETAIL;
