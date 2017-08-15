--------------------------------------------------------
--  DDL for Package Body DOC_PRC_SUBCONTRACT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PRC_SUBCONTRACT" 
is
  /**
  * procedure CreateDocLog
  * Description
  *   Insert de l'id du document cr�� dans une table de log (COM_LIST_ID_TEMP)
  */
  procedure CreateDocLog(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, iDocType in varchar2)
  is
    ltComListTmp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_CODE', iDocType);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_NUMBER_1', iDocumentID);
    FWK_I_MGT_ENTITY.InsertEntity(ltComListTmp);
    FWK_I_MGT_ENTITY.Release(ltComListTmp);
  end CreateDocLog;

  /**
  * procedure ClearDocLog
  * Description
  *   Effacer les donn�es de la table de log (COM_LIST_ID_TEMP)
  */
  procedure ClearDocLog
  is
  begin
    delete from COM_LIST_ID_TEMP;
  end ClearDocLog;

  /**
  * procedure GenCompDocuments
  * Description
  *   Cr�ation des docs de livraison/r�ception des composants au sous-traitant (BLST) ou (BLRST)
  */
  procedure GenCompDocuments(
    iSession             in varchar2
  , iTransfertMode       in varchar2
  , iSubContractPurchase in number default 0
  , iSubContractOper     in number default 0
  , iReturnLocationID    in number default null
  , iTrashLocationID     in number default null
  )
  is
    lnDOC_ID                   DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    lnPOS1_ID                  DOC_POSITION.DOC_POSITION_ID%type;
    lnPOS2_ID                  DOC_POSITION.DOC_POSITION_ID%type;
    lnPOS3_ID                  DOC_POSITION.DOC_POSITION_ID%type;
    lnPDE_ID                   DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    lvCreateMode               varchar2(10)                                          default '124';
    lvLinkType                 varchar2(10);
    lnGaugeId                  DOC_GAUGE.DOC_GAUGE_ID%type;
    lnDocSrcID                 DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    lnPosSrcID                 DOC_POSITION.DOC_POSITION_ID%type;
    lnPdeSrcID                 DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    lnSTT_StockID              STM_STOCK.STM_STOCK_ID%type;
    lnSTT_LocationID           STM_LOCATION.STM_LOCATION_ID%type;
    lnFAL_LOT_ID               FAL_LOT.FAL_LOT_ID%type;
    lnStockID                  STM_STOCK.STM_STOCK_ID%type;
    lnLocationID               STM_LOCATION.STM_LOCATION_ID%type;
    lnTraStockID               STM_STOCK.STM_STOCK_ID%type;
    lnTraLocationID            STM_LOCATION.STM_LOCATION_ID%type;
    lnReturnLocationID         STM_LOCATION.STM_LOCATION_ID%type;
    lnTrashStockID             STM_STOCK.STM_STOCK_ID%type;
    lnTrashLocationID          STM_LOCATION.STM_LOCATION_ID%type;
    lnLOM_SEQ                  FAL_LOT_MAT_LINK_TMP.LOM_SEQ%type;
    lnGCO_GOOD_ID              FAL_LOT_MAT_LINK_TMP.GCO_GOOD_ID%type;
    lnPAC_SUPPLIER_PARTNER_ID  FAL_TASK_LINK.PAC_SUPPLIER_PARTNER_ID%type;
    lnFAL_LOT_MATERIAL_LINK_ID FAL_LOT_MATERIAL_LINK.FAL_LOT_MATERIAL_LINK_ID%type;

    procedure InitTransferAttrib(iPosId in DOC_POSITION.DOC_POSITION_ID%type)
    is
      lC_ATTRIB_TRSF_KIND      STM_MOVEMENT_KIND.C_ATTRIB_TRSF_KIND%type;
      lSTM_STOCK_POSITION_ID   STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type;
      lSPO_ASSIGN_QUANTITY     STM_STOCK_POSITION.SPO_ASSIGN_QUANTITY%type;
      lSTOCK_QUANTITY          number;
      iListFAL_NETWORK_NEED_ID varchar2(1000);
    begin
      update DOC_POSITION_DETAIL
         set STM_STOCK_MOVEMENT_ID = INIT_ID_SEQ.nextval
       where DOC_POSITION_ID = iPosId;

      for ltplNeed in (select FAL_NETWORK_NEED_ID
                         from FAL_NETWORK_NEED
                        where FAL_LOT_MATERIAL_LINK_ID = lnFAL_LOT_MATERIAL_LINK_ID) loop
        if iListFAL_NETWORK_NEED_ID is null then
          iListFAL_NETWORK_NEED_ID  := ltplNeed.FAL_NETWORK_NEED_ID;
        else
          iListFAL_NETWORK_NEED_ID  := iListFAL_NETWORK_NEED_ID || ',' || ltplNeed.FAL_NETWORK_NEED_ID;
        end if;
      end loop;

      select C_ATTRIB_TRSF_KIND
        into lC_ATTRIB_TRSF_KIND
        from STM_MOVEMENT_KIND
           , DOC_POSITION
       where STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID = DOC_POSITION.STM_MOVEMENT_KIND_ID
         and DOC_POSITION.DOC_POSITION_ID = iPosId;

      -- Liste des d�tails de positions
      for ltplPde in (select STM_STOCK_MOVEMENT_ID
                           , GCO_GOOD_ID
                           , STM_LOCATION_ID
                           , GCO_CHARACTERIZATION_ID
                           , GCO_GCO_CHARACTERIZATION_ID
                           , GCO2_GCO_CHARACTERIZATION_ID
                           , GCO3_GCO_CHARACTERIZATION_ID
                           , GCO4_GCO_CHARACTERIZATION_ID
                           , PDE_CHARACTERIZATION_VALUE_1
                           , PDE_CHARACTERIZATION_VALUE_2
                           , PDE_CHARACTERIZATION_VALUE_3
                           , PDE_CHARACTERIZATION_VALUE_4
                           , PDE_CHARACTERIZATION_VALUE_5
                           , PDE_BASIS_QUANTITY_SU
                        from DOC_POSITION_DETAIL
                       where DOC_POSITION_ID = iPosId) loop
        begin
          select STM_STOCK_POSITION_ID
               , SPO_ASSIGN_QUANTITY
            into lSTM_STOCK_POSITION_ID
               , lSPO_ASSIGN_QUANTITY
            from STM_STOCK_POSITION
           where GCO_GOOD_ID = ltplPde.GCO_GOOD_ID
             and STM_LOCATION_ID = ltplPde.STM_LOCATION_ID
             and (     (   GCO_CHARACTERIZATION_ID = ltplPde.GCO_CHARACTERIZATION_ID
                        or (    ltplPde.GCO_CHARACTERIZATION_ID is null
                            and GCO_CHARACTERIZATION_ID is null)
                       )
                  and (   GCO_GCO_CHARACTERIZATION_ID = ltplPde.GCO_GCO_CHARACTERIZATION_ID
                       or (    ltplPde.GCO_GCO_CHARACTERIZATION_ID is null
                           and GCO_GCO_CHARACTERIZATION_ID is null)
                      )
                  and (   GCO2_GCO_CHARACTERIZATION_ID = ltplPde.GCO2_GCO_CHARACTERIZATION_ID
                       or (    ltplPde.GCO2_GCO_CHARACTERIZATION_ID is null
                           and GCO2_GCO_CHARACTERIZATION_ID is null)
                      )
                  and (   GCO3_GCO_CHARACTERIZATION_ID = ltplPde.GCO3_GCO_CHARACTERIZATION_ID
                       or (    ltplPde.GCO3_GCO_CHARACTERIZATION_ID is null
                           and GCO3_GCO_CHARACTERIZATION_ID is null)
                      )
                  and (   GCO4_GCO_CHARACTERIZATION_ID = ltplPde.GCO4_GCO_CHARACTERIZATION_ID
                       or (    ltplPde.GCO4_GCO_CHARACTERIZATION_ID is null
                           and GCO4_GCO_CHARACTERIZATION_ID is null)
                      )
                  and (   SPO_CHARACTERIZATION_VALUE_1 = ltplPde.PDE_CHARACTERIZATION_VALUE_1
                       or (    ltplPde.PDE_CHARACTERIZATION_VALUE_1 is null
                           and SPO_CHARACTERIZATION_VALUE_1 is null)
                      )
                  and (   SPO_CHARACTERIZATION_VALUE_2 = ltplPde.PDE_CHARACTERIZATION_VALUE_2
                       or (    ltplPde.PDE_CHARACTERIZATION_VALUE_2 is null
                           and SPO_CHARACTERIZATION_VALUE_2 is null)
                      )
                  and (   SPO_CHARACTERIZATION_VALUE_3 = ltplPde.PDE_CHARACTERIZATION_VALUE_3
                       or (    ltplPde.PDE_CHARACTERIZATION_VALUE_3 is null
                           and SPO_CHARACTERIZATION_VALUE_3 is null)
                      )
                  and (   SPO_CHARACTERIZATION_VALUE_4 = ltplPde.PDE_CHARACTERIZATION_VALUE_4
                       or (    ltplPde.PDE_CHARACTERIZATION_VALUE_4 is null
                           and SPO_CHARACTERIZATION_VALUE_4 is null)
                      )
                  and (   SPO_CHARACTERIZATION_VALUE_5 = ltplPde.PDE_CHARACTERIZATION_VALUE_5
                       or (    ltplPde.PDE_CHARACTERIZATION_VALUE_5 is null
                           and SPO_CHARACTERIZATION_VALUE_5 is null)
                      )
                 );
        exception
          when no_data_found then
            lSTM_STOCK_POSITION_ID  := null;
            lSPO_ASSIGN_QUANTITY    := 0;
        end;

        if (    (lC_ATTRIB_TRSF_KIND = '1')
            or (lC_ATTRIB_TRSF_KIND = '2') ) then
          if ltplPde.PDE_BASIS_QUANTITY_SU < lSPO_ASSIGN_QUANTITY then
            lSPO_ASSIGN_QUANTITY  := ltplPde.PDE_BASIS_QUANTITY_SU;
          end if;
        end if;

        if (    (lC_ATTRIB_TRSF_KIND = '2')
            or (lC_ATTRIB_TRSF_KIND = '3') ) then
          FAL_PRC_REPORT_ATTRIB.InitQteApproStock(lSTM_STOCK_POSITION_ID
                                                , ltplPde.STM_STOCK_MOVEMENT_ID
                                                , lC_ATTRIB_TRSF_KIND
                                                , lSPO_ASSIGN_QUANTITY
                                                , iListFAL_NETWORK_NEED_ID
                                                 );
        end if;

        delete from STM_TRANSFER_ATTRIB
              where STA_QTY = 0
                and (   STM_STOCK_MOVEMENT_ID is null
                     or STM_STOCK_MOVEMENT_ID = ltplPde.STM_STOCK_MOVEMENT_ID);
      end loop;
    end InitTransferAttrib;

    procedure InitPositionDetail(iMode in number)
    is
    begin
      -- Liste des d�tails � cr�er
      for ltplPde in (select   LOM.FAL_LOT_ID
                             , LOM.GCO_GOOD_ID
                             , LOM.FAL_LOT_MATERIAL_LINK_ID
                             , TAL.FAL_SCHEDULE_STEP_ID
                             , FCL.STM_LOCATION_ID
                             , LOM.STM_LOCATION_ID LOM_LOCATION_ID
                             , CPT.STM_LOCATION_ID CPT_LOCATION_ID
                             , FCL.FCL_CHARACTERIZATION_VALUE_1
                             , FCL.FCL_CHARACTERIZATION_VALUE_2
                             , FCL.FCL_CHARACTERIZATION_VALUE_3
                             , FCL.FCL_CHARACTERIZATION_VALUE_4
                             , FCL.FCL_CHARACTERIZATION_VALUE_5
                             , STO.STO_DESCRIPTION
                             , LOC.LOC_DESCRIPTION
                             , sum(nvl(FCL_HOLD_QTY, 0) ) HOLD_QTY
                             , sum(nvl(FCL_TRASH_QTY, 0) ) TRASH_QTY
                             , sum(nvl(FCL_RETURN_QTY, 0) ) RETURN_QTY
                          from FAL_LOT_MAT_LINK_TMP LOM
                             , FAL_LOT_MATERIAL_LINK CPT
                             , FAL_COMPONENT_LINK FCL
                             , FAL_TASK_LINK TAL
                             , STM_STOCK STO
                             , STM_LOCATION LOC
                         where LOM.LOM_SESSION = iSession
                           and LOM.FAL_LOT_ID = lnFAL_LOT_ID
                           and LOM.FAL_LOT_ID = TAL.FAL_LOT_ID
                           and nvl(LOM.LOM_TASK_SEQ, PCS.PC_CONFIG.GetConfig('PPS_TASK_NUMBERING') ) = TAL.SCS_STEP_NUMBER
                           and TAL.PAC_SUPPLIER_PARTNER_ID = lnPAC_SUPPLIER_PARTNER_ID
                           and LOM.FAL_LOT_MAT_LINK_TMP_ID = FCL.FAL_LOT_MAT_LINK_TMP_ID
                           and CPT.FAL_LOT_MATERIAL_LINK_ID = LOM.FAL_LOT_MATERIAL_LINK_ID
                           and LOC.STM_LOCATION_ID = FCL.STM_LOCATION_ID
                           and LOC.STM_STOCK_ID = STO.STM_STOCK_ID
                           and LOM.LOM_SEQ = lnLOM_SEQ
                           and LOM.GCO_GOOD_ID = lnGCO_GOOD_ID
                           and LOM.FAL_LOT_MATERIAL_LINK_ID = lnFAL_LOT_MATERIAL_LINK_ID
                           and (   nvl(FCL.FCL_HOLD_QTY, 0) > 0
                                or nvl(FCL.FCL_TRASH_QTY, 0) > 0
                                or nvl(FCL.FCL_RETURN_QTY, 0) > 0)
                      group by LOM.FAL_LOT_ID
                             , LOM.GCO_GOOD_ID
                             , LOM.FAL_LOT_MATERIAL_LINK_ID
                             , FCL.STM_LOCATION_ID
                             , LOM.STM_LOCATION_ID
                             , CPT.STM_LOCATION_ID
                             , TAL.FAL_SCHEDULE_STEP_ID
                             , FCL.FCL_CHARACTERIZATION_VALUE_1
                             , FCL.FCL_CHARACTERIZATION_VALUE_2
                             , FCL.FCL_CHARACTERIZATION_VALUE_3
                             , FCL.FCL_CHARACTERIZATION_VALUE_4
                             , FCL.FCL_CHARACTERIZATION_VALUE_5
                             , STO.STO_DESCRIPTION
                             , LOC.LOC_DESCRIPTION
                      order by STO.STO_DESCRIPTION
                             , LOC.LOC_DESCRIPTION) loop
        -- D�finition des emplacements en fonction livraison/r�ception
        if iTransfertMode = 'DELIVERY' then
          -- Livraison
          -- Stock source = stock public
          -- Stock cible  = stock du sous-traitant
          lnLocationID     := ltplPde.STM_LOCATION_ID;
          lnTraLocationID  := lnSTT_LocationID;
        else
          -- R�ception
          -- Stock source = stock du sous-traitant
          -- Stock cible  = stock public
          lnLocationID     := lnSTT_LocationID;
          lnTraLocationID  := ltplPde.CPT_LOCATION_ID;
        end if;

        ------
        -- Transfert chez le sous-traitant
        --
        if     iMode = 1
           and lnPOS1_ID is not null then
          lnPDE_ID  := null;
          DOC_DETAIL_GENERATE.GenerateDetail(aDetailID         => lnPDE_ID
                                           , aPositionID       => lnPOS1_ID
                                           , aPdeCreateMode    => lvCreateMode
                                           , aQuantitySU       => ltplPde.HOLD_QTY
                                           , aLocationID       => lnLocationID
                                           , aTraLocationID    => lnTraLocationID
                                           , aCharactValue_1   => ltplPde.FCL_CHARACTERIZATION_VALUE_1
                                           , aCharactValue_2   => ltplPde.FCL_CHARACTERIZATION_VALUE_2
                                           , aCharactValue_3   => ltplPde.FCL_CHARACTERIZATION_VALUE_3
                                           , aCharactValue_4   => ltplPde.FCL_CHARACTERIZATION_VALUE_4
                                           , aCharactValue_5   => ltplPde.FCL_CHARACTERIZATION_VALUE_5
                                            );

          if    lnPdeSrcID is not null
             or ltplPde.FAL_LOT_MATERIAL_LINK_ID is not null then
            -- Cr�ation d'un lien entre l'id du d�tail CAST et celui du d�tail du BLST
            DOC_PRC_DOCUMENT.CreateDocLink(iLinkType       => lvLinkType
                                         , iDocSourceID    => lnDocSrcID
                                         , iPosSourceID    => lnPosSrcID
                                         , iPdeSourceID    => lnPdeSrcID
                                         , iDocTargetID    => lnDOC_ID
                                         , iPosTargetID    => lnPOS1_ID
                                         , iPdeTargetID    => lnPDE_ID
                                         , iLotMatLinkID   => ltplPde.FAL_LOT_MATERIAL_LINK_ID
                                          );
          end if;
        end if;

        ------
        -- Retour du sous-traitant avec quantit� d�chet
        --
        if     iMode = 2
           and lnPOS2_ID is not null then
          lnPDE_ID  := null;
          DOC_DETAIL_GENERATE.GenerateDetail(aDetailID         => lnPDE_ID
                                           , aPositionID       => lnPOS2_ID
                                           , aPdeCreateMode    => lvCreateMode
                                           , aQuantitySU       => ltplPde.TRASH_QTY
                                           , aLocationID       => lnLocationID
                                           , aTraLocationID    => lnTrashLocationID
                                           , aCharactValue_1   => ltplPde.FCL_CHARACTERIZATION_VALUE_1
                                           , aCharactValue_2   => ltplPde.FCL_CHARACTERIZATION_VALUE_2
                                           , aCharactValue_3   => ltplPde.FCL_CHARACTERIZATION_VALUE_3
                                           , aCharactValue_4   => ltplPde.FCL_CHARACTERIZATION_VALUE_4
                                           , aCharactValue_5   => ltplPde.FCL_CHARACTERIZATION_VALUE_5
                                            );

          if    lnPdeSrcID is not null
             or ltplPde.FAL_LOT_MATERIAL_LINK_ID is not null then
            -- Cr�ation d'un lien entre l'id du d�tail CAST et celui du d�tail du BLST
            DOC_PRC_DOCUMENT.CreateDocLink(iLinkType       => lvLinkType
                                         , iDocSourceID    => lnDocSrcID
                                         , iPosSourceID    => lnPosSrcID
                                         , iPdeSourceID    => lnPdeSrcID
                                         , iDocTargetID    => lnDOC_ID
                                         , iPosTargetID    => lnPOS2_ID
                                         , iPdeTargetID    => lnPDE_ID
                                         , iLotMatLinkID   => ltplPde.FAL_LOT_MATERIAL_LINK_ID
                                          );
          end if;
        end if;

        ------
        -- Retour du sous-traitant
        --
        if     iMode = 3
           and lnPOS3_ID is not null then
          lnPDE_ID  := null;

          if lnReturnLocationID <> 0 then
            select STM_STOCK_ID
              into lnTraStockId
              from STM_LOCATION
             where STM_LOCATION_ID = lnReturnLocationId;

            lnTraLocationId  := lnReturnLocationId;
          end if;

          DOC_DETAIL_GENERATE.GenerateDetail(aDetailID         => lnPDE_ID
                                           , aPositionID       => lnPOS3_ID
                                           , aPdeCreateMode    => lvCreateMode
                                           , aQuantitySU       => ltplPde.RETURN_QTY
                                           , aLocationID       => lnLocationID
                                           , aTraLocationID    => lnTraLocationID
                                           , aCharactValue_1   => ltplPde.FCL_CHARACTERIZATION_VALUE_1
                                           , aCharactValue_2   => ltplPde.FCL_CHARACTERIZATION_VALUE_2
                                           , aCharactValue_3   => ltplPde.FCL_CHARACTERIZATION_VALUE_3
                                           , aCharactValue_4   => ltplPde.FCL_CHARACTERIZATION_VALUE_4
                                           , aCharactValue_5   => ltplPde.FCL_CHARACTERIZATION_VALUE_5
                                            );

          if    lnPdeSrcID is not null
             or ltplPde.FAL_LOT_MATERIAL_LINK_ID is not null then
            -- Cr�ation d'un lien entre l'id du d�tail CAST et celui du d�tail du BLST
            DOC_PRC_DOCUMENT.CreateDocLink(iLinkType       => lvLinkType
                                         , iDocSourceID    => lnDocSrcID
                                         , iPosSourceID    => lnPosSrcID
                                         , iPdeSourceID    => lnPdeSrcID
                                         , iDocTargetID    => lnDOC_ID
                                         , iPosTargetID    => lnPOS3_ID
                                         , iPdeTargetID    => lnPDE_ID
                                         , iLotMatLinkID   => ltplPde.FAL_LOT_MATERIAL_LINK_ID
                                          );
          end if;
        end if;
      end loop;
    end InitPositionDetail;
  begin
    -- Effacer les donn�es de la table de log (COM_LIST_ID_TEMP)
    ClearDocLog;
    lnTrashLocationID   :=
                  nvl(iTrashLocationID, FWK_I_LIB_ENTITY.getIdfromPk2('STM_LOCATION', 'LOC_DESCRIPTION', PCS.PC_CONFIG.GetConfig('PPS_DefltLOCATION_TRASH') ) );
    lnReturnLocationID  := nvl(iReturnLocationID, 0);

    -- Recherche de l'ID du gabarit du document � cr�er BLST ou BLRST
    if iTransfertMode = 'DELIVERY' then
      if iSubContractPurchase = 1 then
        -- sous traitance d'achat
        lvLinkType  := '01';
        -- Recherche de l'ID du gabarit BLST
        lnGaugeID   :=
          FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name   => 'DOC_GAUGE'
                                      , iv_column_name   => 'GAU_DESCRIBE'
                                      , iv_value         => PCS.PC_CONFIG.GetConfig('DOC_SUBCONTRACTP_DELIV_GAUGE')
                                       );

        if lnGaugeID is null then
          ra(PCS.PC_FUNCTIONS.TranslateWord('PCS - La valeur de la configuration DOC_SUBCONTRACTP_DELIV_GAUGE') );
        end if;
      else
        -- sous traitance op�ratoire
        lvLinkType  := '03';
        -- Recherche de l'ID du gabarit BLST
        lnGaugeID   :=
          FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name   => 'DOC_GAUGE'
                                      , iv_column_name   => 'GAU_DESCRIBE'
                                      , iv_value         => PCS.PC_CONFIG.GetConfig('DOC_SUBCONTRACTO_DELIV_GAUGE')
                                       );

        if lnGaugeID is null then
          ra(PCS.PC_FUNCTIONS.TranslateWord('PCS - La valeur de la configuration DOC_SUBCONTRACTO_DELIV_GAUGE') );
        end if;
      end if;
    else
      if iSubContractPurchase = 1 then
        -- sous traitance d'achat
        lvLinkType  := '02';
        -- Recherche de l'ID du gabarit BLST
        lnGaugeID   :=
          FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name   => 'DOC_GAUGE'
                                      , iv_column_name   => 'GAU_DESCRIBE'
                                      , iv_value         => PCS.PC_CONFIG.GetConfig('DOC_SUBCONTRACTP_RETURN_GAUGE')
                                       );

        if lnGaugeID is null then
          ra(PCS.PC_FUNCTIONS.TranslateWord('PCS - La valeur de la configuration DOC_SUBCONTRACTP_RETURN_GAUGE') );   -- Message complet dans les textes.
        end if;
      else
        -- sous traitance op�ratoire
        lvLinkType  := '04';
        -- Recherche de l'ID du gabarit BLST
        lnGaugeID   :=
          FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name   => 'DOC_GAUGE'
                                      , iv_column_name   => 'GAU_DESCRIBE'
                                      , iv_value         => PCS.PC_CONFIG.GetConfig('DOC_SUBCONTRACTO_RETURN_GAUGE')
                                       );

        if lnGaugeID is null then
          ra(PCS.PC_FUNCTIONS.TranslateWord('PCS - La valeur de la configuration DOC_SUBCONTRACTO_RETURN_GAUGE') );   -- Message complet dans les textes.
        end if;
      end if;
    end if;

    -- Liste des documents � cr�er
    for ltplDoc in (select   TAL.PAC_SUPPLIER_PARTNER_ID
                        from FAL_LOT_MAT_LINK_TMP LOM
                           , FAL_COMPONENT_LINK FCL
                           , FAL_TASK_LINK TAL
                       where LOM.LOM_SESSION = iSession
                         and LOM.FAL_LOT_MAT_LINK_TMP_ID = FCL.FAL_LOT_MAT_LINK_TMP_ID
                         and LOM.FAL_LOT_ID = TAL.FAL_LOT_ID
                         and nvl(LOM.LOM_TASK_SEQ, PCS.PC_CONFIG.GetConfig('PPS_TASK_NUMBERING') ) = TAL.SCS_STEP_NUMBER
                         and (   nvl(FCL.FCL_HOLD_QTY, 0) > 0
                              or nvl(FCL.FCL_TRASH_QTY, 0) > 0
                              or nvl(FCL.FCL_RETURN_QTY, 0) > 0)
                    group by TAL.PAC_SUPPLIER_PARTNER_ID) loop
      -- Rechercher le stock/emplacement du sous-traitant
      STM_LIB_STOCK.getSubCStockAndLocation(iSupplierId => ltplDoc.PAC_SUPPLIER_PARTNER_ID, oStockId => lnSTT_StockID, oLocationId => lnSTT_LocationID);
      -- Cr�ation du document
      lnDOC_ID                   := null;
      DOC_DOCUMENT_GENERATE.GenerateDocument(aNewDocumentID   => lnDOC_ID
                                           , aGaugeID         => lnGaugeID
                                           , aMode            => lvCreateMode
                                           , aThirdID         => ltplDoc.PAC_SUPPLIER_PARTNER_ID
                                            );
      lnPAC_SUPPLIER_PARTNER_ID  := ltplDoc.PAC_SUPPLIER_PARTNER_ID;

      -- Liste des positions � cr�er
      for ltplPos in (select   LOT.FAL_LOT_ID
                             , LOM.LOM_SEQ
                             , LOM.GCO_GOOD_ID
                             , LOM.FAL_LOT_MATERIAL_LINK_ID
                             , TAL.FAL_SCHEDULE_STEP_ID
                             , min(LOM.STM_STOCK_ID) STM_STOCK_ID
                             , min(CPT.STM_STOCK_ID) CPT_STOCK_ID
                             , sum(nvl(FCL.FCL_HOLD_QTY, 0) ) HOLD_QTY
                             , sum(nvl(FCL.FCL_TRASH_QTY, 0) ) TRASH_QTY
                             , sum(nvl(FCL.FCL_RETURN_QTY, 0) ) RETURN_QTY
                          from FAL_LOT_MAT_LINK_TMP LOM
                             , FAL_LOT_MATERIAL_LINK CPT
                             , FAL_COMPONENT_LINK FCL
                             , FAL_TASK_LINK TAL
                             , FAL_LOT LOT
                         where LOM.LOM_SESSION = iSession
                           and LOT.FAL_LOT_ID = LOM.FAL_LOT_ID
                           and LOM.FAL_LOT_ID = TAL.FAL_LOT_ID
                           and nvl(LOM.LOM_TASK_SEQ, PCS.PC_CONFIG.GetConfig('PPS_TASK_NUMBERING') ) = TAL.SCS_STEP_NUMBER
                           and TAL.PAC_SUPPLIER_PARTNER_ID = lnPAC_SUPPLIER_PARTNER_ID
                           and LOM.FAL_LOT_MAT_LINK_TMP_ID = FCL.FAL_LOT_MAT_LINK_TMP_ID
                           and CPT.FAL_LOT_MATERIAL_LINK_ID = LOM.FAL_LOT_MATERIAL_LINK_ID
                           and (   nvl(FCL.FCL_HOLD_QTY, 0) > 0
                                or nvl(FCL.FCL_TRASH_QTY, 0) > 0
                                or nvl(FCL.FCL_RETURN_QTY, 0) > 0)
                      group by LOT.FAL_LOT_ID
                             , LOT.LOT_REFCOMPL
                             , LOM.LOM_SEQ
                             , LOM.GCO_GOOD_ID
                             , LOM.FAL_LOT_MATERIAL_LINK_ID
                             , TAL.FAL_SCHEDULE_STEP_ID
                      order by LOT.LOT_REFCOMPL
                             , LOM.LOM_SEQ) loop
        -- Rechercher les informations d'origine li� au lot de fabrication lors du traitement d'un nouveau lot
        if nvl(lnFAL_LOT_ID, -1) <> ltplPos.FAL_LOT_ID then
          if iSubContractPurchase = 1 then
            -- Recherche la CAST � l'origine du lot de fabrication
            FAL_LIB_SUBCONTRACTP.GetBatchOriginDocument(iFalLotId => ltplPos.FAL_LOT_ID, ioDocDocumentId => lnDocSrcID, ioDocPositionId => lnPosSrcID);
          else
            -- Recherche la CST g�n�rer par l'op�ration externe
            FAL_LIB_SUBCONTRACTO.GetBatchOriginDocument(iFalTaskLinkId    => ltplPos.FAL_SCHEDULE_STEP_ID
                                                      , ioDocDocumentId   => lnDocSrcID
                                                      , ioDocPositionId   => lnPosSrcID
                                                       );
          end if;

          -- Recherche l'id du d�tail de la position de la CAST ou CST (1POS=1DET)
          if lnPosSrcID is not null then
            select max(DOC_POSITION_DETAIL_ID)
              into lnPdeSrcID
              from DOC_POSITION_DETAIL
             where DOC_POSITION_ID = lnPosSrcID;
          else
            lnPdeSrcID  := null;
          end if;

          lnFAL_LOT_ID  := ltplPos.FAL_LOT_ID;
        end if;

        lnLOM_SEQ                   := ltplPos.LOM_SEQ;
        lnGCO_GOOD_ID               := ltplPos.GCO_GOOD_ID;
        lnFAL_LOT_MATERIAL_LINK_ID  := ltplPos.FAL_LOT_MATERIAL_LINK_ID;

        -- D�finition des emplacements en fonction livraison/r�ception
        if iTransfertMode = 'DELIVERY' then
          -- Livraison
          -- Stock source = stock public
          -- Stock cible  = stock du sous-traitant
          lnStockID        := ltplPos.STM_STOCK_ID;
          lnLocationID     := null;
          lnTraStockID     := lnSTT_StockID;
          lnTraLocationID  := lnSTT_LocationID;
        else
          -- R�ception
          -- Stock source = stock du sous-traitant
          -- Stock cible  = stock public
          lnStockID        := lnSTT_StockID;
          lnLocationID     := lnSTT_LocationID;
          lnTraStockID     := ltplPos.CPT_STOCK_ID;
          lnTraLocationID  := null;
        end if;

        lnPOS2_ID                   := null;
        lnPOS2_ID                   := null;

        ------
        -- Transfert chez le sous-traitant
        --
        if ltplPos.HOLD_QTY <> 0 then
          select INIT_ID_SEQ.nextval
            into lnPOS1_ID
            from dual;

          DOC_POSITION_GENERATE.ResetPositionInfo(DOC_POSITION_INITIALIZE.PositionInfo);
          DOC_POSITION_INITIALIZE.PositionInfo.CLEAR_POSITION_INFO  := 0;
          DOC_POSITION_GENERATE.GeneratePosition(aPositionID        => lnPOS1_ID
                                               , aDocumentID        => lnDOC_ID
                                               , aPosCreateMode     => lvCreateMode
                                               , aTypePos           => '1'
                                               , aGoodID            => ltplPos.GCO_GOOD_ID
                                               , aBasisQuantitySU   => ltplPos.HOLD_QTY
                                               , aStockID           => lnStockID
                                               , aLocationID        => lnLocationID
                                               , aTraStockID        => lnTraStockID
                                               , aTraLocationID     => lnTraLocationID
                                               , aGenerateDetail    => 0
                                                );
          InitPositionDetail(1);
          -- Applique l'emplacement du d�tail de position sur la position si tout les d�tails de position portent sur le m�me emplacement.
          DOC_I_PRC_POSITION.SyncPositionDetailLocation(lnPOS1_ID);
          InitTransferAttrib(lnPos1_id);
        end if;

        ------
        -- Retour du sous-traitant avec quantit� d�chet
        --
        if ltplPos.TRASH_QTY <> 0 then
          -- Pour les d�chets, on force le stock et l'emplacement d�chets d�finis dans la configuration. En attendant le solution suivante :
          -- L'utilisateur devrait avoir la possiblit� de saisir le stock et l'emplacement pour la mise en d�chet ou le retour. Pour cela,
          -- il y a deux possibilit�, soit la forme standard de s�lection de la plage des composants des stocks de retour et de d�chets est
          -- affich�e pour les bulletins de retour des composants du sous-traitant. ou la commande permettant de saisir la quantit� d�chet
          -- et la quantit� retour affiche �galement l'emplacement d�chet.
          if lnTrashLocationID <> 0 then
            select STM_STOCK_ID
              into lnTrashStockId
              from STM_LOCATION
             where STM_LOCATION_ID = lnTrashLocationId;
          else
            -- Pas d'emplacement d�chet, on tente par le stock d�chet.
            lnTrashStockId  := FWK_I_LIB_ENTITY.getIdfromPk2('STM_STOCK', 'STO_DESCRIPTION', PCS.PC_CONFIG.GetConfig('PPS_DefltSTOCK_TRASH') );

            -- Premier emplacement par ordre de classement
            select   max(LOC.STM_LOCATION_ID)
                into lnTrashLocationId
                from STM_LOCATION LOC
               where LOC.STM_STOCK_ID = lnTrashStockId
            order by LOC.LOC_CLASSIFICATION asc;
          end if;

          select INIT_ID_SEQ.nextval
            into lnPOS2_ID
            from dual;

          DOC_POSITION_GENERATE.ResetPositionInfo(DOC_POSITION_INITIALIZE.PositionInfo);
          DOC_POSITION_INITIALIZE.PositionInfo.CLEAR_POSITION_INFO  := 0;
          DOC_POSITION_GENERATE.GeneratePosition(aPositionID        => lnPOS2_ID
                                               , aDocumentID        => lnDOC_ID
                                               , aPosCreateMode     => lvCreateMode
                                               , aTypePos           => '1'
                                               , aGoodID            => ltplPos.GCO_GOOD_ID
                                               , aBasisQuantitySU   => ltplPos.TRASH_QTY
                                               , aStockID           => lnStockID
                                               , aLocationID        => lnLocationID
                                               , aTraStockID        => lnTrashStockId
                                               , aTraLocationID     => lnTrashLocationId
                                               , aGenerateDetail    => 0
                                                );
          InitPositionDetail(2);
          InitTransferAttrib(lnPos2_id);
        end if;

        ------
        -- Retour du sous-traitant
        --
        if ltplPos.RETURN_QTY <> 0 then
          if lnReturnLocationID <> 0 then
            select STM_STOCK_ID
              into lnTraStockId
              from STM_LOCATION
             where STM_LOCATION_ID = lnReturnLocationId;

            lnTraLocationId  := lnReturnLocationId;
          end if;

          select INIT_ID_SEQ.nextval
            into lnPOS3_ID
            from dual;

          DOC_POSITION_GENERATE.ResetPositionInfo(DOC_POSITION_INITIALIZE.PositionInfo);
          DOC_POSITION_INITIALIZE.PositionInfo.CLEAR_POSITION_INFO  := 0;
          DOC_POSITION_GENERATE.GeneratePosition(aPositionID        => lnPOS3_ID
                                               , aDocumentID        => lnDOC_ID
                                               , aPosCreateMode     => lvCreateMode
                                               , aTypePos           => '1'
                                               , aGoodID            => ltplPos.GCO_GOOD_ID
                                               , aBasisQuantitySU   => ltplPos.RETURN_QTY
                                               , aStockID           => lnStockID
                                               , aLocationID        => lnLocationID
                                               , aTraStockID        => lnTraStockID
                                               , aTraLocationID     => lnTraLocationId
                                               , aGenerateDetail    => 0
                                                );
          InitPositionDetail(3);
          -- Applique l'emplacement du d�tail de position sur la position si tout les d�tails de position portent sur le m�me emplacement.
          DOC_I_PRC_POSITION.SyncPositionDetailLocation(lnPOS3_ID);
          InitTransferAttrib(lnPos3_id);
        end if;
      end loop;

      DOC_FINALIZE.FinalizeDocument(aDocumentId => lnDOC_ID);
      -- Insert de l'id du document cr�� dans une table de log (COM_LIST_ID_TEMP)
      CreateDocLog(iDocumentID => lnDOC_ID, iDocType => iTransfertMode);
    end loop;
  end GenCompDocuments;

  /**
  * procedure UpdatePOSDelay
  * Description
  *   Modification du d�lai de base ou final avec recalcul des autres d�lais (base/interm�diaire/final)
  *     du d�tail de position de la CAST li� au lot de fabrication
  * @created NGV
  * @lastUpdate age 08.07.2013
  * @public
  * @param iFalLotID : ID du lot de fabrication
  * @param iNewDelay : nouveau d�lai de base final
  * @param iUpdatedDelay : d�lai modifi�  -> BASIS ou FINAL
  */
  procedure UpdatePOSDelay(
    iFalLotID     in FAL_LOT.FAL_LOT_ID%type default null
  , iFalOperID    in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type default null
  , iNewDelay     in date
  , iUpdatedDelay in varchar2
  )
  is
    lnGaugeID      DOC_GAUGE.DOC_GAUGE_ID%type;
    lvBasisDelayMW varchar2(30);
    lvInterDelayMW varchar2(30);
    lvFinalDelayMW varchar2(30);
    ldBasisDelay   date                            := null;
    ldInterDelay   date                            := null;
    ldFinalDelay   date                            := null;
    lnForward      number(1);
    ltDetail       FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    if iFalLotId is not null then
      -- Rechercher l'id du sous-traitant et le gabarit CAST
      select max(DocGauge.column_value)
        into lnGaugeID
        from FAL_LOT LOT
           , FAL_TASK_LINK TAL
           , table(DOC_LIB_SUBCONTRACTP.GetSUPOGaugeId(TAL.PAC_SUPPLIER_PARTNER_ID) ) DocGauge
       where LOT.FAL_LOT_ID = iFalLotID
         and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID;
    else
      -- Rechercher l'id du sous-traitant et le gabarit CST
      select max(DOC_LIB_SUBCONTRACTO.getOrderGaugeID)
        into lnGaugeID
        from FAL_TASK_LINK TAL
       where iFalOperId = TAL.FAL_SCHEDULE_STEP_ID;
    end if;

    -- Pas de gabarit CAST d�fini
    if lnGaugeID is null then
      RA(PCS.PC_FUNCTIONS.TranslateWord('Le gabarit "Commande sous-traitance" n''a pas �t� trouv�!') );
    else
      -- D�finition des variables en fonction du d�lais modifi�
      if iUpdatedDelay = 'BASIS' then
        lnForward     := 1;
        ldBasisDelay  := iNewDelay;
      else
        lnForward     := 0;
        ldFinalDelay  := iNewDelay;
      end if;

      -- Utilisation d'un curseur pour faciliter le select -> pas de N variables � d�clarer
      -- car il n'y a qu'un seul d�tail correspondant aux crit�res de s�lection
      for ltplDetailInfo in (select   PDE.DOC_POSITION_DETAIL_ID
                                    , PDE.PDE_BASIS_QUANTITY
                                    , DMT.PAC_THIRD_ID
                                    , POS.STM_STOCK_ID
                                    , POS.STM_STM_STOCK_ID
                                    , POS.GCO_GOOD_ID
                                    , POS.GCO_COMPL_DATA_ID
                                    , GAU.C_ADMIN_DOMAIN
                                    , GAU.C_GAUGE_TYPE
                                    , GAP.C_GAUGE_SHOW_DELAY
                                    , GAP.GAP_POS_DELAY
                                    , GAP.GAP_TRANSFERT_PROPRIETOR
                                 from DOC_DOCUMENT DMT
                                    , DOC_POSITION POS
                                    , DOC_POSITION_DETAIL PDE
                                    , DOC_GAUGE GAU
                                    , DOC_GAUGE_POSITION GAP
                                where (     (   iFalLotId is null
                                             or PDE.FAL_LOT_ID = iFalLotID)
                                       and (   iFalOperId is null
                                            or PDE.FAL_SCHEDULE_STEP_ID = iFalOperId) )
                                  and POS.C_GAUGE_TYPE_POS in('1', '2', '3')
                                  and POS.C_DOC_POS_STATUS in('01', '02', '03')
                                  and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
                                  and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
                                  and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                                  and GAP.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                                  and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
                                  and (    (    iFalLotId is null
                                            and GAU.DOC_GAUGE_ID = lnGaugeID)
                                       or (    iFalLotId is not null
                                           and GAU.DOC_GAUGE_ID in(
                                                 select DocGauge.column_value
                                                   from FAL_LOT LOT
                                                      , FAL_TASK_LINK TAL
                                                      , table(DOC_LIB_SUBCONTRACTP.GetSUPOGaugeId(TAL.PAC_SUPPLIER_PARTNER_ID) ) DocGauge
                                                  where LOT.FAL_LOT_ID = iFalLotID
                                                    and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID)
                                          )
                                      )
                             order by DMT.DMT_NUMBER
                                    , POS.POS_NUMBER
                                    , PDE.DOC_POSITION_DETAIL_ID) loop
        -- Recalcul du d�lai en fonction du d�lai modifi�
        DOC_POSITION_DETAIL_FUNCTIONS.GetPDEDelay(aShowDelay             => ltplDetailInfo.C_GAUGE_SHOW_DELAY
                                                , aPosDelay              => ltplDetailInfo.GAP_POS_DELAY
                                                , aUpdatedDelay          => iUpdatedDelay
                                                , aForward               => lnForward
                                                , aThirdID               => ltplDetailInfo.PAC_THIRD_ID
                                                , aGoodID                => ltplDetailInfo.GCO_GOOD_ID
                                                , aStockID               => ltplDetailInfo.STM_STOCK_ID
                                                , aTargetStockID         => ltplDetailInfo.STM_STM_STOCK_ID
                                                , aAdminDomain           => ltplDetailInfo.C_ADMIN_DOMAIN
                                                , aGaugeType             => ltplDetailInfo.C_GAUGE_TYPE
                                                , aTransfertProprietor   => ltplDetailInfo.GAP_TRANSFERT_PROPRIETOR
                                                , aBasisDelayMW          => lvBasisDelayMW
                                                , aInterDelayMW          => lvInterDelayMW
                                                , aFinalDelayMW          => lvFinalDelayMW
                                                , aBasisDelay            => ldBasisDelay
                                                , aInterDelay            => ldInterDelay
                                                , aFinalDelay            => ldFinalDelay
                                                , iComplDataId           => ltplDetailInfo.GCO_COMPL_DATA_ID
                                                , iQuantity              => ltplDetailInfo.PDE_BASIS_QUANTITY
                                                , iScheduleStepId        => iFalOperID
                                                 );
        -- M�j des d�lais du d�tail de la CAST li� au lot de fabrication
        FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocPositionDetail, ltDetail);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDetail, 'DOC_POSITION_DETAIL_ID', ltplDetailInfo.DOC_POSITION_DETAIL_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDetail, 'PDE_BASIS_DELAY', ldBasisDelay);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDetail, 'PDE_INTERMEDIATE_DELAY', ldInterDelay);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDetail, 'PDE_FINAL_DELAY', ldFinalDelay);
        FWK_I_MGT_ENTITY.UpdateEntity(ltDetail);
        FWK_I_MGT_ENTITY.Release(ltDetail);
      end loop;
    end if;
  end UpdatePOSDelay;
end DOC_PRC_SUBCONTRACT;
