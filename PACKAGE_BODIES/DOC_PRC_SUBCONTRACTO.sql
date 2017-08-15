--------------------------------------------------------
--  DDL for Package Body DOC_PRC_SUBCONTRACTO
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PRC_SUBCONTRACTO" 
is
  /**
  * procedure CreateDocLog
  * Description
  *   Insert de l'id du document créé dans une table de log (COM_LIST_ID_TEMP)
  */
  procedure CreateDocLog(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    ltComListTmp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'COM_LIST_ID_TEMP_ID', iDocumentID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_CODE', 'DOC_DOCUMENT_ID');
    FWK_I_MGT_ENTITY.InsertEntity(ltComListTmp);
    FWK_I_MGT_ENTITY.Release(ltComListTmp);
  end CreateDocLog;

  /**
  * procedure ResetDocInfo
  * Description
  *   Supprimer l'id du document créé dans une table de log (COM_LIST_ID_TEMP)
  */
  procedure ResetDocInfo(iFalScheduleStepID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
  is
    ltComListTmp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'COM_LIST_ID_TEMP_ID', iFalScheduleStepID);
    FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltComListTmp, 'LID_FREE_NUMBER_5');
    FWK_I_MGT_ENTITY.UpdateEntity(ltComListTmp);
    FWK_I_MGT_ENTITY.Release(ltComListTmp);
  end ResetDocInfo;

  /**
  * procedure UpdateDocInfo
  * Description
  *   Insert de l'id du document créé dans une table de log (COM_LIST_ID_TEMP)
  */
  procedure UpdateDocInfo(
    iFalScheduleStepID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , iDocumentID        in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , iErrorMsg          in varchar2 default null
  )
  is
    ltComListTmp FWK_I_TYP_DEFINITION.t_crud_def;
    lvFreeMemo1  varchar2(4000);
    lvErrorMsg   varchar2(4000);
  begin
    begin
      select LID_FREE_MEMO_1
        into lvFreeMemo1
        from COM_LIST_ID_TEMP
       where COM_LIST_ID_TEMP_ID = iFalScheduleStepID;
    exception
      when no_data_found then
        lvFreeMemo1  := null;
    end;

    if lvFreeMemo1 is not null then
      lvErrorMsg  := lvFreeMemo1 || co.cLineBreak || iErrorMsg;
    else
      lvErrorMsg  := iErrorMsg;
    end if;

    FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'COM_LIST_ID_TEMP_ID', iFalScheduleStepID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_NUMBER_5', iDocumentID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_MEMO_1', substrb(lvErrorMsg, 1, 4000) );
    FWK_I_MGT_ENTITY.UpdateEntity(ltComListTmp);
    FWK_I_MGT_ENTITY.Release(ltComListTmp);
  end UpdateDocInfo;

  /**
  * procedure UpdateToolInfo
  * Description
  *   Insert de l'id du document créé dans une table de log (COM_LIST_ID_TEMP)
  */
  procedure UpdateToolInfo(
    iFalScheduleStepID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , iTool1Id           in PPS_TOOLS.GCO_GOOD_ID%type
  , iTool2Id           in PPS_TOOLS.GCO_GOOD_ID%type
  , iTool3Id           in PPS_TOOLS.GCO_GOOD_ID%type
  , iTool4Id           in PPS_TOOLS.GCO_GOOD_ID%type
  , iTool5Id           in PPS_TOOLS.GCO_GOOD_ID%type
  , iTool6Id           in PPS_TOOLS.GCO_GOOD_ID%type
  , iTool7Id           in PPS_TOOLS.GCO_GOOD_ID%type
  , iTool8Id           in PPS_TOOLS.GCO_GOOD_ID%type
  , iTool9Id           in PPS_TOOLS.GCO_GOOD_ID%type
  , iTool10Id          in PPS_TOOLS.GCO_GOOD_ID%type
  , iTool11Id          in PPS_TOOLS.GCO_GOOD_ID%type
  , iTool12Id          in PPS_TOOLS.GCO_GOOD_ID%type
  , iTool13Id          in PPS_TOOLS.GCO_GOOD_ID%type
  , iTool14Id          in PPS_TOOLS.GCO_GOOD_ID%type
  , iTool15Id          in PPS_TOOLS.GCO_GOOD_ID%type
  )
  is
    ltComListTmp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'COM_LIST_ID_TEMP_ID', iFalScheduleStepID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp
                                  , 'LID_FREE_NUMBER_3'
                                  , sign(nvl(iTool1Id, 0) ) +
                                    sign(nvl(iTool2Id, 0) ) +
                                    sign(nvl(iTool3Id, 0) ) +
                                    sign(nvl(iTool4Id, 0) ) +
                                    sign(nvl(iTool5Id, 0) ) +
                                    sign(nvl(iTool6Id, 0) ) +
                                    sign(nvl(iTool7Id, 0) ) +
                                    sign(nvl(iTool8Id, 0) ) +
                                    sign(nvl(iTool9Id, 0) ) +
                                    sign(nvl(iTool10Id, 0) ) +
                                    sign(nvl(iTool11Id, 0) ) +
                                    sign(nvl(iTool12Id, 0) ) +
                                    sign(nvl(iTool13Id, 0) ) +
                                    sign(nvl(iTool14Id, 0) ) +
                                    sign(nvl(iTool15Id, 0) )
                                   );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_NUMBER_4', iTool2Id);
    FWK_I_MGT_ENTITY.UpdateEntity(ltComListTmp);
    FWK_I_MGT_ENTITY.Release(ltComListTmp);
  end UpdateToolInfo;

  /**
  * procedure ClearProcessData
  * Description
  *   Effacement des données la table COM_LIST_ID_TEMP liées au processus de génération des cmds sous-traitance
  */
  procedure ClearProcessData
  is
  begin
    COM_PRC_LIST_ID_TEMP.DeleteIDList(aCode => 'FAL_SCHEDULE_STEP_ID');
    COM_PRC_LIST_ID_TEMP.DeleteIDList(aCode => 'DOC_DOCUMENT_ID');
  end;

  /**
  * procedure ClearDocumentData
  * Description
  *   Effacement des données la table COM_LIST_ID_TEMP contenant la liste des documents générés
  */
  procedure ClearDocumentData
  is
  begin
    COM_PRC_LIST_ID_TEMP.DeleteIDList(aCode => 'DOC_DOCUMENT_ID');
  end;

  /**
  * Description
  *   Effacement des données la table COM_LIST_ID_TEMP contenant la liste des opérations de lot
  *   et de propositions de lots pour la création de PCST ( prévision de commandes de sous-traitance )
  */
  procedure ClearPCSTData
  is
  begin
    COM_PRC_LIST_ID_TEMP.DeleteIDList(aCode => 'PCST_BATCH');
    COM_PRC_LIST_ID_TEMP.DeleteIDList(aCode => 'PCST_PROP');
  end ClearPCSTData;

  /**
  * Description
  *   Effacement des erreurs de la table COM_LIST_ID_TEMP avant la confirmation des PCST
  */
  procedure ClearPCSTErrorMessage
  is
  begin
    -- Mise à jour du message d'erreur
    update COM_LIST_ID_TEMP
       set LID_FREE_TEXT_1 = null
         , LID_FREE_MEMO_1 = null
     where LID_CODE = 'PCST_BATCH'
        or LID_CODE = 'PCST_PROP';
  end;

  /**
  * Description
  *   Effacement des erreurs de la table COM_LIST_ID_TEMP avant la confirmation des PCST
  */
  procedure ClearCSTErrorMessage
  as
  begin
    update COM_LIST_ID_TEMP
       set LID_FREE_MEMO_1 = null
     where LID_CODE = 'FAL_SCHEDULE_STEP_ID';
  end ClearCSTErrorMessage;

  /*
  * procedure GeneratePCST
  * Description
  *   Création des prévisions de commande sous-traitance en se basant sur une sélection d'opérations listée dans la table COM_LIST_ID_TE
  */
  procedure GeneratePCST(iRegroupMode in integer default 1)
  is
    lcGaugeNumberID   DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID%type;
    lvPCSTNumber      DOC_DOCUMENT.DMT_NUMBER%type;
    lnPcstExist       number;
    ltFalTaskLink     FWK_I_TYP_DEFINITION.t_crud_def;
    ltFalTaskLinkProp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- iRegroupMode =
    -- 1 : Une prévision par opération
    -- 2 : Une prévision par fournisseur

    -- Génération des cmds sous-traitance
    for ltplPCST in (select   PAC_SUPPLIER_PARTNER_ID
                            , min(FAL_SCHEDULE_STEP_ID) as FAL_SCHEDULE_STEP_ID
                         from (select TAL.PAC_SUPPLIER_PARTNER_ID
                                    , TAL.FAL_SCHEDULE_STEP_ID as FAL_SCHEDULE_STEP_ID
                                 from COM_LIST_ID_TEMP LID
                                    , FAL_TASK_LINK TAL
                                where LID.COM_LIST_ID_TEMP_ID = TAL.FAL_SCHEDULE_STEP_ID
                                  and LID.LID_CODE = 'PCST_BATCH'
                                  and TAL.TAL_PCST_NUMBER is null
                                  and LID.LID_SELECTION = 1
                               union
                               select TAL.PAC_SUPPLIER_PARTNER_ID
                                    , TAL.FAL_TASK_LINK_PROP_ID as FAL_SCHEDULE_STEP_ID
                                 from COM_LIST_ID_TEMP LID
                                    , FAL_TASK_LINK_PROP TAL
                                where LID.COM_LIST_ID_TEMP_ID = TAL.FAL_TASK_LINK_PROP_ID
                                  and LID.LID_CODE = 'PCST_PROP'
                                  and TAL.TAL_PCST_NUMBER is null
                                  and LID.LID_SELECTION = 1)
                     group by PAC_SUPPLIER_PARTNER_ID
                            , case
                                when iRegroupMode = 1 then FAL_SCHEDULE_STEP_ID
                                else null
                              end) loop
      -- Récupérer la numérotation dans la config
      lnPcstExist  := 1;

      begin
        while lnPcstExist = 1 loop
          select DOC_GAUGE_NUMBERING_ID
            into lcGaugeNumberID
            from DOC_GAUGE_NUMBERING
           where GAN_DESCRIBE = PCS.PC_CONFIG.GetConfig('DOC_SUBCONTRACT_GAUGE_NUMBER');

          -- Récupérer le prochain numéro de PCST
          DOC_DOCUMENT_FUNCTIONS.GetDocumentNumber(null, lcGaugeNumberID, lvPCSTNumber);

          select count(TAL_PCST_NUMBER)
            into lnPcstExist
            from (select TAL.TAL_PCST_NUMBER
                    from FAL_TASK_LINK TAL
                  union
                  select TAL.TAL_PCST_NUMBER
                    from FAL_TASK_LINK_PROP TAL)
           where TAL_PCST_NUMBER = lvPCSTNumber;
        end loop;
      exception
        when no_data_found then
          -- Pas de numérotation dans la config
          -- Valeur par défaut : PCST-YYYY-000000
          -- Récupérer le numéro en fonction de ce qui existe déjà
          lvPCSTNumber  := 'PCST-' || to_char(sysdate, 'YYYY') || '-';

          select lvPCSTNumber || ltrim(to_char(nvl(max(replace(TAL_PCST_NUMBER, lvPCSTNumber) ), 0) + 1, '000000'), ' ')
            into lvPCSTNumber
            from (select TAL.TAL_PCST_NUMBER
                    from FAL_TASK_LINK TAL
                  union
                  select TAL.TAL_PCST_NUMBER
                    from FAL_TASK_LINK_PROP TAL)
           where TAL_PCST_NUMBER like like_param(lvPCSTNumber);
      end;

      -- Mise à jour des opérations avec le numéro et la date de la PCST
      if iRegroupMode = 1 then
        -- Une prévision par opération
        FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_TYP_FAL_ENTITY.gcFalTaskLink, iot_crud_definition => ltFalTaskLink
                           , iv_primary_col        => 'FAL_SCHEDULE_STEP_ID');
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFalTaskLink, 'FAL_SCHEDULE_STEP_ID', ltplPCST.FAL_SCHEDULE_STEP_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFalTaskLink, 'TAL_PCST_NUMBER', lvPCSTNumber);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFalTaskLink, 'TAL_PCST_DATE', sysdate);
        FWK_I_MGT_ENTITY.UpdateEntity(ltFalTaskLink);
        FWK_I_MGT_ENTITY.Release(ltFalTaskLink);
        -- Mise à jour de de la proposition d'opération
        FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcFalTaskLinkProp, iot_crud_definition => ltFalTaskLinkProp);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFalTaskLinkProp, 'FAL_TASK_LINK_PROP_ID', ltplPCST.FAL_SCHEDULE_STEP_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFalTaskLinkProp, 'TAL_PCST_NUMBER', lvPCSTNumber);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltFalTaskLinkProp, 'TAL_PCST_DATE', sysdate);
        FWK_I_MGT_ENTITY.UpdateEntity(ltFalTaskLinkProp);
        FWK_I_MGT_ENTITY.Release(ltFalTaskLinkProp);
      else
        -- Une prévision par fournisseur
        -- Opérations
        for ltplUpdatePCST in (select TAL.FAL_SCHEDULE_STEP_ID
                                 from COM_LIST_ID_TEMP LID
                                    , FAL_TASK_LINK TAL
                                where LID.COM_LIST_ID_TEMP_ID = TAL.FAL_SCHEDULE_STEP_ID
                                  and TAL.PAC_SUPPLIER_PARTNER_ID = ltplPCST.PAC_SUPPLIER_PARTNER_ID
                                  and LID.LID_CODE = 'PCST_BATCH'
                                  and TAL.TAL_PCST_NUMBER is null
                                  and LID.LID_SELECTION = 1) loop
          -- Mise à jour de l'opération
          FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_TYP_FAL_ENTITY.gcFalTaskLink
                             , iot_crud_definition   => ltFalTaskLink
                             , iv_primary_col        => 'FAL_SCHEDULE_STEP_ID'
                              );
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltFalTaskLink, 'FAL_SCHEDULE_STEP_ID', ltplUpdatePCST.FAL_SCHEDULE_STEP_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltFalTaskLink, 'TAL_PCST_NUMBER', lvPCSTNumber);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltFalTaskLink, 'TAL_PCST_DATE', sysdate);
          FWK_I_MGT_ENTITY.UpdateEntity(ltFalTaskLink);
          FWK_I_MGT_ENTITY.Release(ltFalTaskLink);
        end loop;

        -- Propositions d'opérations
        for ltplUpdatePCST in (select TAL.FAL_TASK_LINK_PROP_ID
                                 from COM_LIST_ID_TEMP LID
                                    , FAL_TASK_LINK_PROP TAL
                                where LID.COM_LIST_ID_TEMP_ID = TAL.FAL_TASK_LINK_PROP_ID
                                  and TAL.PAC_SUPPLIER_PARTNER_ID = ltplPCST.PAC_SUPPLIER_PARTNER_ID
                                  and LID.LID_CODE = 'PCST_PROP'
                                  and TAL.TAL_PCST_NUMBER is null
                                  and LID.LID_SELECTION = 1) loop
          -- Mise à jour de de la proposition d'opération
          FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcFalTaskLinkProp, iot_crud_definition => ltFalTaskLinkProp);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltFalTaskLinkProp, 'FAL_TASK_LINK_PROP_ID', ltplUpdatePCST.FAL_TASK_LINK_PROP_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltFalTaskLinkProp, 'TAL_PCST_NUMBER', lvPCSTNumber);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltFalTaskLinkProp, 'TAL_PCST_DATE', sysdate);
          FWK_I_MGT_ENTITY.UpdateEntity(ltFalTaskLinkProp);
          FWK_I_MGT_ENTITY.Release(ltFalTaskLinkProp);
        end loop;
      end if;
    end loop;
  end GeneratePCST;

  /**
  * procedure pGenerateOrderDoc
  * Description
  *   Création d'une commande de sous-traitance en se basant sur une opération (pour obtenir les infos)
  * @created NGV 14.05.2012
  * @lastUpdate AGE 10.06.2013
  * @private
  * @param iRegroupMode       : Mode de regroupement
  *                              1 : Une commande par opération
  *                              2 : Une commande par sous-traitant
  * @param iFalScheduleStepID : ID de l'opération
  * @param iSupplierID        : ID du sous-traitant
  * @param iGaugeID           : ID du gabarit Commande sous-traitance
  * @param iDocumentDate      : Date pour la commande sous-traitance
  * @param oDocumentID        : ID du document créé
  */
  procedure pGenerateOrderDoc(
    iRegroupMode       in     integer default 1
  , iFalScheduleStepID in     FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , iSupplierID        in     FAL_TASK_LINK.PAC_SUPPLIER_PARTNER_ID%type default null
  , iGaugeID           in     DOC_GAUGE.DOC_GAUGE_ID%type default null
  , iDocumentDate      in     DOC_DOCUMENT.DMT_DATE_DOCUMENT%type default null
  , oDocumentID        out    DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , oErrorMsg          out    varchar2
  )
  is
    lnGaugeID    DOC_GAUGE.DOC_GAUGE_ID%type;
    lnSupplierID PAC_SUPPLIER_PARTNER.PAC_SUPPLIER_PARTNER_ID%type;
    lnRecordID   DOC_RECORD.DOC_RECORD_ID%type;
  begin
    -- Utiliser l'id pour le gabarit si passé en param ou
    -- Lecture de la config contenant le gabarit Commande sous-traitance
    lnGaugeID  := nvl(iGaugeID, DOC_LIB_SUBCONTRACTO.getOrderGaugeID);

    if lnGaugeID is null then
      PCS.RA(PCS.PC_FUNCTIONS.TranslateWord('Le gabarit "Commande sous-traitance" n''a pas été trouvé!') );
    end if;

    -- Infos pour la création du document
    select nvl(iSupplierId, TAL.PAC_SUPPLIER_PARTNER_ID)
         , LOT.DOC_RECORD_ID
      into lnSupplierID
         , lnRecordID
      from FAL_TASK_LINK TAL
         , FAL_LOT LOT
     where TAL.FAL_SCHEDULE_STEP_ID = iFalScheduleStepID
       and TAL.FAL_LOT_ID = LOT.FAL_LOT_ID;

    begin
      -- Création document. Si regroupement = 2 (par sous-traitant), on ne transmet par l'ID de l'opération car il y en a potentiellement plusieurs.
      DOC_DOCUMENT_GENERATE.GenerateDocument(aNewDocumentID       => oDocumentID
                                           , aErrorMsg            => oErrorMsg
                                           , aMode                => '120'
                                           , aGaugeID             => lnGaugeID
                                           , aThirdID             => lnSupplierID
                                           , aRecordID            => lnRecordID
                                           , aDocDate             => iDocumentDate
                                           , aFalScheduleStepID   => case iRegroupMode
                                               when 1 then iFalScheduleStepID
                                               else null
                                             end
                                            );
    exception
      when others then
        oErrorMsg  := sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    end;
  end pGenerateOrderDoc;

  /**
  * procedure pGenerateOrderPos
  * Description
  *   Création d'une position pour une commande de sous-traitance en se basant sur une opération (pour obtenir les infos)
  * @created NGV 14.05.2012
  * @lastUpdate age 10.06.2015
  * @private
  * @param iFalScheduleStepID : ID de l'opération
  * @param iDocumentID        : ID de la cmd sous-traitante
  * @param iQty               : Quantité à mettre à jour
  * @param iSupplierID        : ID du sous-traitant
  * @param iServiceID         : ID du service lié à l'opération externe.
  * @param oPositionID        : ID de la position créée
  */
  procedure pGenerateOrderPos(
    iFalScheduleStepID in     FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , iDocumentID        in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , iQty               in     DOC_POSITION.POS_BASIS_QUANTITY%type default null
  , iSupplierID        in     FAL_TASK_LINK.PAC_SUPPLIER_PARTNER_ID%type default null
  , iServiceID         in     FAL_TASK_LINK.GCO_GCO_GOOD_ID%type default null
  , oPositionID        out    DOC_POSITION.DOC_POSITION_ID%type
  , oErrorMsg          out    varchar2
  )
  is
    lnStockID            STM_STOCK.STM_STOCK_ID%type;
    lnTraStockID         STM_STOCK.STM_STOCK_ID%type;
    lnTraLocationID      STM_LOCATION.STM_LOCATION_ID%type;
    lnQuantity           DOC_POSITION.POS_BASIS_QUANTITY%type;
    lnQuantitySU         DOC_POSITION.POS_BASIS_QUANTITY%type;
    lnGoodID             GCO_GOOD.GCO_GOOD_ID%type;
    lnManufacturedGoodID GCO_GOOD.GCO_GOOD_ID%type;
    lnRecordID           DOC_RECORD.DOC_RECORD_ID%type;
    ldFinalDelay         DOC_POSITION_DETAIL.PDE_FINAL_DELAY%type;
    lnConvertFactor      GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type;
    lnCdaDecimal         GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
    lnTools1ID           FAL_TASK_LINK.PPS_TOOLS1_ID%type;
    lnTools2ID           FAL_TASK_LINK.PPS_TOOLS2_ID%type;
    lnTools3ID           FAL_TASK_LINK.PPS_TOOLS3_ID%type;
    lnTools4ID           FAL_TASK_LINK.PPS_TOOLS4_ID%type;
    lnTools5ID           FAL_TASK_LINK.PPS_TOOLS5_ID%type;
    lnTools6ID           FAL_TASK_LINK.PPS_TOOLS6_ID%type;
    lnTools7ID           FAL_TASK_LINK.PPS_TOOLS7_ID%type;
    lnTools8ID           FAL_TASK_LINK.PPS_TOOLS8_ID%type;
    lnTools9ID           FAL_TASK_LINK.PPS_TOOLS9_ID%type;
    lnTools10ID          FAL_TASK_LINK.PPS_TOOLS10_ID%type;
    lnTools11ID          FAL_TASK_LINK.PPS_TOOLS11_ID%type;
    lnTools12ID          FAL_TASK_LINK.PPS_TOOLS12_ID%type;
    lnTools13ID          FAL_TASK_LINK.PPS_TOOLS13_ID%type;
    lnTools14ID          FAL_TASK_LINK.PPS_TOOLS14_ID%type;
    lnTools15ID          FAL_TASK_LINK.PPS_TOOLS15_ID%type;
    lnTools1Qty          DOC_POSITION.POS_BASIS_QUANTITY%type                 default 1;
    lnTools2Qty          DOC_POSITION.POS_BASIS_QUANTITY%type                 default 1;
    lnTools3Qty          DOC_POSITION.POS_BASIS_QUANTITY%type                 default 1;
    lnTools4Qty          DOC_POSITION.POS_BASIS_QUANTITY%type                 default 1;
    lnTools5Qty          DOC_POSITION.POS_BASIS_QUANTITY%type                 default 1;
    lnTools6Qty          DOC_POSITION.POS_BASIS_QUANTITY%type                 default 1;
    lnTools7Qty          DOC_POSITION.POS_BASIS_QUANTITY%type                 default 1;
    lnTools8Qty          DOC_POSITION.POS_BASIS_QUANTITY%type                 default 1;
    lnTools9Qty          DOC_POSITION.POS_BASIS_QUANTITY%type                 default 1;
    lnTools10Qty         DOC_POSITION.POS_BASIS_QUANTITY%type                 default 1;
    lnTools11Qty         DOC_POSITION.POS_BASIS_QUANTITY%type                 default 1;
    lnTools12Qty         DOC_POSITION.POS_BASIS_QUANTITY%type                 default 1;
    lnTools13Qty         DOC_POSITION.POS_BASIS_QUANTITY%type                 default 1;
    lnTools14Qty         DOC_POSITION.POS_BASIS_QUANTITY%type                 default 1;
    lnTools15Qty         DOC_POSITION.POS_BASIS_QUANTITY%type                 default 1;
    lnPosID              DOC_POSITION.DOC_POSITION_ID%type;
  begin
    -- Rechercher le stock par défaut
    select max(STM_STOCK_ID)
      into lnStockID
      from STM_STOCK
     where C_ACCESS_METHOD = 'DEFAULT';

    -- Infos pour la création de la position
    select nvl(iServiceID, TAL.GCO_GCO_GOOD_ID) as GCO_GOOD_ID
         , LOT.GCO_GOOD_ID as GCO_MANUFACTURED_GOOD_ID
         , nvl(iQty, TAL.TAL_DUE_QTY - nvl(TAL_SUBCONTRACT_QTY, 0) ) TAL_DUE_QTY
         , case C_SCHEDULE_PLANNING
             when '1' then FAL_SCHEDULE_FUNCTIONS.GetDecalage(aPAC_SUPPLIER_PARTNER_ID   => tal.PAC_SUPPLIER_PARTNER_ID
                                                            , aFromDate                  => lid.LID_FREE_DATE_1
                                                            , aDecalage                  => nvl(tal.TAL_PLAN_RATE, 0)
                                                             )
             else tal.TAL_END_PLAN_DATE
           end
         , LOT.DOC_RECORD_ID
         , (select nvl(max(CDA_CONVERSION_FACTOR), 1)
              from GCO_COMPL_DATA_PURCHASE
             where GCO_COMPL_DATA_PURCHASE_ID =
                                 GCO_LIB_COMPL_DATA.GetComplDataPurchaseId(nvl(iServiceId, TAL.GCO_GCO_GOOD_ID), nvl(iSupplierId, TAL.PAC_SUPPLIER_PARTNER_ID) ) )
                                                                                                                                             CDA_CONVERT_FACTOR
         , nvl(GCO_LIB_COMPL_DATA.GetCDADecimal(nvl(iServiceID, TAL.GCO_GCO_GOOD_ID), 'PURCHASE', nvl(iSupplierID, TAL.PAC_SUPPLIER_PARTNER_ID) ), 0)
                                                                                                                                                    CDA_DECIMAL
         , TAL.PPS_TOOLS1_ID
         , TAL.PPS_TOOLS2_ID
         , TAL.PPS_TOOLS3_ID
         , TAL.PPS_TOOLS4_ID
         , TAL.PPS_TOOLS5_ID
         , TAL.PPS_TOOLS6_ID
         , TAL.PPS_TOOLS7_ID
         , TAL.PPS_TOOLS8_ID
         , TAL.PPS_TOOLS9_ID
         , TAL.PPS_TOOLS10_ID
         , TAL.PPS_TOOLS11_ID
         , TAL.PPS_TOOLS12_ID
         , TAL.PPS_TOOLS13_ID
         , TAL.PPS_TOOLS14_ID
         , TAL.PPS_TOOLS15_ID
      into lnGoodID
         , lnManufacturedGoodID
         , lnQuantitySU
         , ldFinalDelay
         , lnRecordID
         , lnConvertFactor
         , lnCdaDecimal
         , lnTools1ID
         , lnTools2ID
         , lnTools3ID
         , lnTools4ID
         , lnTools5ID
         , lnTools6ID
         , lnTools7ID
         , lnTools8ID
         , lnTools9ID
         , lnTools10ID
         , lnTools11ID
         , lnTools12ID
         , lnTools13ID
         , lnTools14ID
         , lnTools15ID
      from FAL_TASK_LINK TAL
         , FAL_LOT LOT
         , COM_LIST_ID_TEMP LID
     where TAL.FAL_SCHEDULE_STEP_ID = iFalScheduleStepID
       and TAL.FAL_LOT_ID = LOT.FAL_LOT_ID
       and LID.COM_LIST_ID_TEMP_ID = TAL.FAL_SCHEDULE_STEP_ID
       and LID.LID_CODE = 'FAL_SCHEDULE_STEP_ID';

    -- Convertir la qté stock en qté en unité d'achat
    lnQuantity  := ACS_FUNCTION.RoundNear(aValue => lnQuantitySU / lnConvertFactor, aRound => 1 / power(10, lnCdaDecimal), aMode => 0);
    -- Création de la position
    DOC_POSITION_GENERATE.GeneratePosition(aPositionID           => oPositionID
                                         , aErrorMsg             => oErrorMsg
                                         , aDocumentID           => iDocumentID
                                         , aPosCreateMode        => '120'
                                         , aTypePos              => '1'
                                         , aGoodID               => lnGoodID
                                         , aBasisQuantity        => lnQuantity
                                         , aFinalDelay           => ldFinalDelay
                                         , aRecordID             => lnRecordID
                                         , aStockID              => lnStockID
                                         , aFalScheduleStepID    => iFalScheduleStepID
                                         , aManufacturedGoodID   => lnManufacturedGoodID
                                          );
    -- Mise à jour de l'opération liée
    FAL_PRC_SUBCONTRACTO.updateOpAtPosGeneration(iFalScheduleStepID, lnQuantitySU, ldFinalDelay);
    -- Mise à jour des informations nécessaire à la création des positon outils
    UpdateToolInfo(iFalScheduleStepID   => iFalScheduleStepID
                 , iTool1Id             => lnTools1ID
                 , iTool2Id             => lnTools2ID
                 , iTool3Id             => lnTools3ID
                 , iTool4Id             => lnTools4ID
                 , iTool5Id             => lnTools5ID
                 , iTool6Id             => lnTools6ID
                 , iTool7Id             => lnTools7ID
                 , iTool8Id             => lnTools8ID
                 , iTool9Id             => lnTools9ID
                 , iTool10Id            => lnTools10ID
                 , iTool11Id            => lnTools11ID
                 , iTool12Id            => lnTools12ID
                 , iTool13Id            => lnTools13ID
                 , iTool14Id            => lnTools14ID
                 , iTool15Id            => lnTools15ID
                  );

    if oPositionID is not null then
      -- Création des positions de type Outil
      if PCS.PC_CONFIG.GetConfig('DOC_TOOLS_SUBCONTRACT') = '1' then
        -- Recherche du stock de transfert pour la position de type Outil
        select max(STM_STOCK_ID)
          into lnTraStockID
          from STM_STOCK
         where STO_DESCRIPTION = PCS.PC_CONFIG.GetConfig('DOC_STOCK_SUBCONTRACT')
           and C_ACCESS_METHOD = 'PRIVATE';

        -- Recherche de l'emplacement de transfert pour la position de type Outil
        select max(STM_LOCATION_ID)
          into lnTraLocationID
          from STM_LOCATION
         where LOC_DESCRIPTION = PCS.PC_CONFIG.GetConfig('DOC_LOCATION_SUBCONTRACT')
           and STM_STOCK_ID = nvl(lnTraStockID, STM_STOCK_ID);

        if     (lnTools1ID is not null)
           and (lnTools1Qty > 0) then
          -- Création de la position Outil 1
          lnPosID  := null;
          DOC_POSITION_GENERATE.GeneratePosition(aPositionID          => lnPosID
                                               , aErrorMsg            => oErrorMsg
                                               , aDocumentID          => iDocumentID
                                               , aPosCreateMode       => '120'
                                               , aTypePos             => '3'
                                               , aGoodID              => lnTools1ID
                                               , aBasisQuantity       => lnTools1Qty
                                               , aFinalDelay          => ldFinalDelay
                                               , aRecordID            => lnRecordID
                                               , aTraStockID          => lnTraStockID
                                               , aTraLocationID       => lnTraLocationID
                                               , aFalScheduleStepID   => iFalScheduleStepID
                                                );
        end if;

        if     (lnTools2ID is not null)
           and (lnTools2Qty > 0) then
          -- Création de la position Outil 2
          lnPosID  := null;
          DOC_POSITION_GENERATE.GeneratePosition(aPositionID          => lnPosID
                                               , aErrorMsg            => oErrorMsg
                                               , aDocumentID          => iDocumentID
                                               , aPosCreateMode       => '120'
                                               , aTypePos             => '3'
                                               , aGoodID              => lnTools2ID
                                               , aBasisQuantity       => lnTools2Qty
                                               , aFinalDelay          => ldFinalDelay
                                               , aRecordID            => lnRecordID
                                               , aTraStockID          => lnTraStockID
                                               , aTraLocationID       => lnTraLocationID
                                               , aFalScheduleStepID   => iFalScheduleStepID
                                                );
        end if;

        if     (lnTools3ID is not null)
           and (lnTools3Qty > 0) then
          -- Création de la position Outil 3
          lnPosID  := null;
          DOC_POSITION_GENERATE.GeneratePosition(aPositionID          => lnPosID
                                               , aErrorMsg            => oErrorMsg
                                               , aDocumentID          => iDocumentID
                                               , aPosCreateMode       => '120'
                                               , aTypePos             => '3'
                                               , aGoodID              => lnTools3ID
                                               , aBasisQuantity       => lnTools3Qty
                                               , aFinalDelay          => ldFinalDelay
                                               , aRecordID            => lnRecordID
                                               , aTraStockID          => lnTraStockID
                                               , aTraLocationID       => lnTraLocationID
                                               , aFalScheduleStepID   => iFalScheduleStepID
                                                );
        end if;

        if     (lnTools4ID is not null)
           and (lnTools4Qty > 0) then
          -- Création de la position Outil 4
          lnPosID  := null;
          DOC_POSITION_GENERATE.GeneratePosition(aPositionID          => lnPosID
                                               , aErrorMsg            => oErrorMsg
                                               , aDocumentID          => iDocumentID
                                               , aPosCreateMode       => '120'
                                               , aTypePos             => '3'
                                               , aGoodID              => lnTools4ID
                                               , aBasisQuantity       => lnTools4Qty
                                               , aFinalDelay          => ldFinalDelay
                                               , aRecordID            => lnRecordID
                                               , aTraStockID          => lnTraStockID
                                               , aTraLocationID       => lnTraLocationID
                                               , aFalScheduleStepID   => iFalScheduleStepID
                                                );
        end if;

        if     (lnTools5ID is not null)
           and (lnTools5Qty > 0) then
          -- Création de la position Outil 5
          lnPosID  := null;
          DOC_POSITION_GENERATE.GeneratePosition(aPositionID          => lnPosID
                                               , aErrorMsg            => oErrorMsg
                                               , aDocumentID          => iDocumentID
                                               , aPosCreateMode       => '120'
                                               , aTypePos             => '3'
                                               , aGoodID              => lnTools5ID
                                               , aBasisQuantity       => lnTools5Qty
                                               , aFinalDelay          => ldFinalDelay
                                               , aRecordID            => lnRecordID
                                               , aTraStockID          => lnTraStockID
                                               , aTraLocationID       => lnTraLocationID
                                               , aFalScheduleStepID   => iFalScheduleStepID
                                                );
        end if;

        if     (lnTools6ID is not null)
           and (lnTools6Qty > 0) then
          -- Création de la position Outil 6
          lnPosID  := null;
          DOC_POSITION_GENERATE.GeneratePosition(aPositionID          => lnPosID
                                               , aErrorMsg            => oErrorMsg
                                               , aDocumentID          => iDocumentID
                                               , aPosCreateMode       => '120'
                                               , aTypePos             => '3'
                                               , aGoodID              => lnTools6ID
                                               , aBasisQuantity       => lnTools6Qty
                                               , aFinalDelay          => ldFinalDelay
                                               , aRecordID            => lnRecordID
                                               , aTraStockID          => lnTraStockID
                                               , aTraLocationID       => lnTraLocationID
                                               , aFalScheduleStepID   => iFalScheduleStepID
                                                );
        end if;

        if     (lnTools7ID is not null)
           and (lnTools7Qty > 0) then
          -- Création de la position Outil 7
          lnPosID  := null;
          DOC_POSITION_GENERATE.GeneratePosition(aPositionID          => lnPosID
                                               , aErrorMsg            => oErrorMsg
                                               , aDocumentID          => iDocumentID
                                               , aPosCreateMode       => '120'
                                               , aTypePos             => '3'
                                               , aGoodID              => lnTools7ID
                                               , aBasisQuantity       => lnTools7Qty
                                               , aFinalDelay          => ldFinalDelay
                                               , aRecordID            => lnRecordID
                                               , aTraStockID          => lnTraStockID
                                               , aTraLocationID       => lnTraLocationID
                                               , aFalScheduleStepID   => iFalScheduleStepID
                                                );
        end if;

        if     (lnTools8ID is not null)
           and (lnTools8Qty > 0) then
          -- Création de la position Outil 8
          lnPosID  := null;
          DOC_POSITION_GENERATE.GeneratePosition(aPositionID          => lnPosID
                                               , aErrorMsg            => oErrorMsg
                                               , aDocumentID          => iDocumentID
                                               , aPosCreateMode       => '120'
                                               , aTypePos             => '3'
                                               , aGoodID              => lnTools8ID
                                               , aBasisQuantity       => lnTools8Qty
                                               , aFinalDelay          => ldFinalDelay
                                               , aRecordID            => lnRecordID
                                               , aTraStockID          => lnTraStockID
                                               , aTraLocationID       => lnTraLocationID
                                               , aFalScheduleStepID   => iFalScheduleStepID
                                                );
        end if;

        if     (lnTools9ID is not null)
           and (lnTools9Qty > 0) then
          -- Création de la position Outil 9
          lnPosID  := null;
          DOC_POSITION_GENERATE.GeneratePosition(aPositionID          => lnPosID
                                               , aErrorMsg            => oErrorMsg
                                               , aDocumentID          => iDocumentID
                                               , aPosCreateMode       => '120'
                                               , aTypePos             => '3'
                                               , aGoodID              => lnTools9ID
                                               , aBasisQuantity       => lnTools9Qty
                                               , aFinalDelay          => ldFinalDelay
                                               , aRecordID            => lnRecordID
                                               , aTraStockID          => lnTraStockID
                                               , aTraLocationID       => lnTraLocationID
                                               , aFalScheduleStepID   => iFalScheduleStepID
                                                );
        end if;

        if     (lnTools10ID is not null)
           and (lnTools10Qty > 0) then
          -- Création de la position Outil 10
          lnPosID  := null;
          DOC_POSITION_GENERATE.GeneratePosition(aPositionID          => lnPosID
                                               , aErrorMsg            => oErrorMsg
                                               , aDocumentID          => iDocumentID
                                               , aPosCreateMode       => '120'
                                               , aTypePos             => '3'
                                               , aGoodID              => lnTools10ID
                                               , aBasisQuantity       => lnTools10Qty
                                               , aFinalDelay          => ldFinalDelay
                                               , aRecordID            => lnRecordID
                                               , aTraStockID          => lnTraStockID
                                               , aTraLocationID       => lnTraLocationID
                                               , aFalScheduleStepID   => iFalScheduleStepID
                                                );
        end if;

        if     (lnTools11ID is not null)
           and (lnTools11Qty > 0) then
          -- Création de la position Outil 11
          lnPosID  := null;
          DOC_POSITION_GENERATE.GeneratePosition(aPositionID          => lnPosID
                                               , aErrorMsg            => oErrorMsg
                                               , aDocumentID          => iDocumentID
                                               , aPosCreateMode       => '120'
                                               , aTypePos             => '3'
                                               , aGoodID              => lnTools11ID
                                               , aBasisQuantity       => lnTools11Qty
                                               , aFinalDelay          => ldFinalDelay
                                               , aRecordID            => lnRecordID
                                               , aTraStockID          => lnTraStockID
                                               , aTraLocationID       => lnTraLocationID
                                               , aFalScheduleStepID   => iFalScheduleStepID
                                                );
        end if;

        if     (lnTools12ID is not null)
           and (lnTools12Qty > 0) then
          -- Création de la position Outil 12
          lnPosID  := null;
          DOC_POSITION_GENERATE.GeneratePosition(aPositionID          => lnPosID
                                               , aErrorMsg            => oErrorMsg
                                               , aDocumentID          => iDocumentID
                                               , aPosCreateMode       => '120'
                                               , aTypePos             => '3'
                                               , aGoodID              => lnTools12ID
                                               , aBasisQuantity       => lnTools12Qty
                                               , aFinalDelay          => ldFinalDelay
                                               , aRecordID            => lnRecordID
                                               , aTraStockID          => lnTraStockID
                                               , aTraLocationID       => lnTraLocationID
                                               , aFalScheduleStepID   => iFalScheduleStepID
                                                );
        end if;

        if     (lnTools13ID is not null)
           and (lnTools13Qty > 0) then
          -- Création de la position Outil 13
          lnPosID  := null;
          DOC_POSITION_GENERATE.GeneratePosition(aPositionID          => lnPosID
                                               , aErrorMsg            => oErrorMsg
                                               , aDocumentID          => iDocumentID
                                               , aPosCreateMode       => '120'
                                               , aTypePos             => '3'
                                               , aGoodID              => lnTools13ID
                                               , aBasisQuantity       => lnTools13Qty
                                               , aFinalDelay          => ldFinalDelay
                                               , aRecordID            => lnRecordID
                                               , aTraStockID          => lnTraStockID
                                               , aTraLocationID       => lnTraLocationID
                                               , aFalScheduleStepID   => iFalScheduleStepID
                                                );
        end if;

        if     (lnTools14ID is not null)
           and (lnTools14Qty > 0) then
          -- Création de la position Outil 14
          lnPosID  := null;
          DOC_POSITION_GENERATE.GeneratePosition(aPositionID          => lnPosID
                                               , aErrorMsg            => oErrorMsg
                                               , aDocumentID          => iDocumentID
                                               , aPosCreateMode       => '120'
                                               , aTypePos             => '3'
                                               , aGoodID              => lnTools14ID
                                               , aBasisQuantity       => lnTools14Qty
                                               , aFinalDelay          => ldFinalDelay
                                               , aRecordID            => lnRecordID
                                               , aTraStockID          => lnTraStockID
                                               , aTraLocationID       => lnTraLocationID
                                               , aFalScheduleStepID   => iFalScheduleStepID
                                                );
        end if;

        if     (lnTools15ID is not null)
           and (lnTools15Qty > 0) then
          -- Création de la position Outil 15
          lnPosID  := null;
          DOC_POSITION_GENERATE.GeneratePosition(aPositionID          => lnPosID
                                               , aErrorMsg            => oErrorMsg
                                               , aDocumentID          => iDocumentID
                                               , aPosCreateMode       => '120'
                                               , aTypePos             => '3'
                                               , aGoodID              => lnTools15ID
                                               , aBasisQuantity       => lnTools15Qty
                                               , aFinalDelay          => ldFinalDelay
                                               , aRecordID            => lnRecordID
                                               , aTraStockID          => lnTraStockID
                                               , aTraLocationID       => lnTraLocationID
                                               , aFalScheduleStepID   => iFalScheduleStepID
                                                );
        end if;
      end if;
    end if;
  exception
    when others then
      oErrorMsg  := sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
  end pGenerateOrderPos;

  /**
  * procedure GenerateOrders
  * Description
  *   Création des commandes de sous-traitance en se basant sur une sélection d'opérations listées dans la table COM_LIST_ID_TEMP
  */
  procedure GenerateOrders(
    iRegroupMode   in integer default 1
  , iGaugeID       in DOC_GAUGE.DOC_GAUGE_ID%type default null
  , iDocumentDate  in DOC_DOCUMENT.DMT_DATE_DOCUMENT%type default null
  , iOrderByClause in varchar2 default null
  )
  is
    lnDocID          DOC_DOCUMENT.DOC_DOCUMENT_ID%type            := null;
    lnPosID          DOC_POSITION.DOC_POSITION_ID%type            := null;
    lnLastSupplierID FAL_TASK_LINK.PAC_SUPPLIER_PARTNER_ID%type   := 0;
    lvErrorMsg       varchar2(32000);

    type ltData is record(
      PAC_SUPPLIER_PARTNER_ID FAL_TASK_LINK.PAC_SUPPLIER_PARTNER_ID%type
    , GCO_GCO_GOOD_ID         FAL_TASK_LINK.GCO_GCO_GOOD_ID%type
    , QTY_TO_SEND             COM_LIST_ID_TEMP.LID_FREE_NUMBER_2%type
    , FAL_SCHEDULE_STEP_ID    FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
    );

    type lttData is table of ltData;

    ltplData         lttData;
    lvDataQuery      varchar2(32767);
    lvOrderByClause  varchar2(32767);
    i                binary_integer;
  begin
    if iOrderByClause is null then
      lvORderByClause  := ' order by PAC_PERSON.PER_NAME, COM_LIST_ID_TEMP.LID_ID_1, FAL_LOT.LOT_REFCOMPL, FAL_TASK_LINK.SCS_STEP_NUMBER';
    elsif iRegroupMode = 2 then   -- 1 cde par sous-traitant
      lvOrderByClause  := ' order by PAC_PERSON.PER_NAME, COM_LIST_ID_TEMP.LID_ID_1,' || replace(iOrderByClause, ';', ',');
    else   -- 1 cde par opération
      lvOrderByClause  := ' order by ' || replace(iOrderByClause, ';', ',');
    end if;

    lvDataQuery  :=
      'select COM_LIST_ID_TEMP.LID_ID_1 PAC_SUPPLIER_PARTNER_ID' ||
      '     , COM_LIST_ID_TEMP.LID_ID_2 GCO_GCO_GOOD_ID' ||
      '     , COM_LIST_ID_TEMP.LID_FREE_NUMBER_2 QTY_TO_SEND' ||
      '     , FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID' ||
      '  from COM_LIST_ID_TEMP' ||
      '     , FAL_TASK_LINK' ||
      '     , FAL_LOT' ||
      '     , PAC_PERSON' ||
      ' where COM_LIST_ID_TEMP.COM_LIST_ID_TEMP_ID = FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID' ||
      '   and COM_LIST_ID_TEMP.LID_ID_1 = PAC_PERSON.PAC_PERSON_ID' ||
      '   and FAL_TASK_LINK.FAL_LOT_ID = FAL_LOT.FAL_LOT_ID' ||
      '   and COM_LIST_ID_TEMP.LID_CODE = ''FAL_SCHEDULE_STEP_ID''' ||
      '   and COM_LIST_ID_TEMP.LID_SELECTION = 1' ||
      '   and COM_LIST_ID_TEMP.LID_FREE_MEMO_1 is null' ||
      lvOrderByClause;

    execute immediate lvDataQuery
    bulk collect into ltplData;

    i            := ltplData.first;

    while i is not null loop
      if    (lnLastSupplierID <> ltplData(i).PAC_SUPPLIER_PARTNER_ID)
         or (iRegroupMode = 1) then
        lnLastSupplierID  := ltplData(i).PAC_SUPPLIER_PARTNER_ID;

        if lnDocID is not null then
          -- Finaliser le document
          DOC_FINALIZE.FinalizeDocument(aDocumentId => lnDocID);
          -- Insert de l'id du document créé dans une table de log (COM_LIST_ID_TEMP)
          CreateDocLog(iDocumentID => lnDocID);
        end if;

        lvErrorMsg        := null;
        pGenerateOrderDoc(iRegroupMode         => iRegroupMode
                        , iFalScheduleStepID   => ltplData(i).FAL_SCHEDULE_STEP_ID
                        , iSupplierID          => ltplData(i).PAC_SUPPLIER_PARTNER_ID
                        , iGaugeID             => iGaugeID
                        , iDocumentDate        => iDocumentDate
                        , oDocumentID          => lnDocID
                        , oErrorMsg            => lvErrorMsg
                         );
      end if;

      if lnDocID is null then
        UpdateDocInfo(iFalScheduleStepID => ltplData(i).FAL_SCHEDULE_STEP_ID, iDocumentID => lnDocID, iErrorMsg => lvErrorMsg);
      else
        lvErrorMsg  := null;
        ResetDocInfo(iFalScheduleStepID => ltplData(i).FAL_SCHEDULE_STEP_ID);
        pGenerateOrderPos(iFalScheduleStepID   => ltplData(i).FAL_SCHEDULE_STEP_ID
                        , iSupplierID          => ltplData(i).PAC_SUPPLIER_PARTNER_ID
                        , iServiceID           => ltplData(i).GCO_GCO_GOOD_ID
                        , iDocumentID          => lnDocID
                        , iQty                 => ltplData(i).QTY_TO_SEND
                        , oPositionID          => lnPosID
                        , oErrorMsg            => lvErrorMsg
                         );
        UpdateDocInfo(iFalScheduleStepID => ltplData(i).FAL_SCHEDULE_STEP_ID, iDocumentID => lnDocID, iErrorMsg => lvErrorMsg);
        UpdateCSTDelay(iFalOperId => ltplData(i).FAL_SCHEDULE_STEP_ID);
      end if;

      i  := ltplData.next(i);
    end loop;

    if lnDocID is not null then
      -- Finaliser le document
      DOC_FINALIZE.FinalizeDocument(aDocumentId => lnDocID);
      -- Insert de l'id du document créé dans une table de log (COM_LIST_ID_TEMP)
      CreateDocLog(iDocumentID => lnDocID);
    end if;
  end GenerateOrders;

  /**
  * procedure GenDeliveryCompDocs
  * Description
  *   Création des docs de livraison des composants au sous-traitant (BLST)
  */
  procedure GenDeliveryCompDocs(iSession in varchar2)
  is
  begin
    DOC_I_PRC_SUBCONTRACT.GenCompDocuments(iSession => iSession, iTransfertMode => 'DELIVERY', iSubContractOper => 1);
  end GenDeliveryCompDocs;

  /**
  * procedure GenReturnCompDocs
  * Description
  *   Création des docs de retour des composants du sous-traitant (BLRST)
  */
  procedure GenReturnCompDocs(iSession in varchar2, iReturnLocationID in number default null, iTrashLocationID in number default null)
  is
  begin
    DOC_I_PRC_SUBCONTRACT.GenCompDocuments(iSession            => iSession
                                         , iTransfertMode      => 'RETURN'
                                         , iSubContractOper    => 1
                                         , iReturnLocationId   => iReturnLocationId
                                         , iTrashLocationId    => iTrashLocationId
                                          );
  end GenReturnCompDocs;

   /**
  * procedure UpdateCST
  * Description
  *    Mise à jour de la quantité des CST liées à l'opération en cas d'augmentation de quantité. En cas de diminution de la quantité,
  *    un message d'erreur est retourné indiquant l'impossibilité de mettre à jour les CST liées. Cette procédure n'est appelées QUE
  *    pour un OF lancé avec une première opération principale de type externe et uniquement si la config FAL_SUBCONTRACT_LAUNCH = 1.
  *    Si la config est à 2, la mise à jour se fait via Delphi après avoir choisi les op. pour lesquelles on veut générer les CST.
  *    (cf FAL_TR_GENE_COMMANDE_SS_TRAITANT.GenerateOrdersOnLaunch(...) qui appelle DOC_I_PRC_SUBCONTRACTO.GenerateOrders(...)).
  *    Si la config est à 0, aucune mise à jour automatique n'est effectuée.
  */
  procedure UpdateCST(
    iFalScheduleStepID in     FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , iQty               in     FAL_TASK_LINK.TAL_PLAN_QTY%type
  , oDeltaQty          out    number
  , oError             out    varchar2
  )
  is
    lQtyCstPU           number;   -- Qté en cours de report en unité d'achat
    lDeltaQtySU         number;   -- Qté solde à reporter en unité de stockage
    lnDocID             DOC_DOCUMENT.DOC_DOCUMENT_ID%type;
    lnPosID             DOC_POSITION.DOC_POSITION_ID%type;
    lErrorCode          varchar2(4000);
    lErrorText          varchar2(4000);
    lvErrorMsg          varchar2(32000);
    lbConvertedModified boolean                             := false;
  begin
    -- Au départ, aucune quantité reportée sur les CST.
    oDeltaQty  := 0;

    -- Si la config est <> de '1', rien à faire.
    if PCS.PC_CONFIG.GetConfig('FAL_SUBCONTRACT_LAUNCH') <> '1' then
      return;
    end if;

    -- Récupération de la quantité restante à reporter.
    select iQty - sum(POS.POS_BASIS_QUANTITY_SU)
      into lDeltaQtySU
      from DOC_POSITION POS
         , DOC_DOCUMENT DOC
     where POS.FAL_SCHEDULE_STEP_ID = iFalScheduleStepID
       and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
       and POS.C_GAUGE_TYPE_POS = '1'
       and POS.STM_MOVEMENT_KIND_ID is null;   -- prend que les CST et pas les BST/FST

    -- Si aucune quantité à reporter, rien à faire.
    if lDeltaQtySU = 0 then
      return;
    end if;

    oDeltaQty  := lDeltaQtySU;

    -- On essaie de reporter la quantité sur une position non confirmée d'un document non verrouillé.
    for ltplPos in (select   DOC.DOC_DOCUMENT_ID
                           , DOC.DMT_NUMBER
                           , POS.DOC_POSITION_ID
                           , POS.POS_NUMBER
                           , POS.POS_BASIS_QUANTITY
                           , POS.POS_BALANCE_QUANTITY
                           , POS.POS_GROSS_UNIT_VALUE
                           , DOC.DMT_DATE_DOCUMENT
                           , (select nvl(max(CDA_CONVERSION_FACTOR), 1)
                                from GCO_COMPL_DATA_PURCHASE
                               where GCO_COMPL_DATA_PURCHASE_ID = GCO_LIB_COMPL_DATA.GetComplDataPurchaseId(TAL.GCO_GCO_GOOD_ID, TAL.PAC_SUPPLIER_PARTNER_ID) )
                                                                                                                                             CDA_CONVERT_FACTOR
                           , nvl(GCO_LIB_COMPL_DATA.GetCDADecimal(TAL.GCO_GCO_GOOD_ID, 'PURCHASE', TAL.PAC_SUPPLIER_PARTNER_ID), 0) CDA_DECIMAL
                        from DOC_POSITION POS
                           , DOC_DOCUMENT DOC
                           , FAL_TASK_LINK TAL
                       where POS.FAL_SCHEDULE_STEP_ID = TAL.FAL_SCHEDULE_STEP_ID
                         and TAL.FAL_SCHEDULE_STEP_ID = iFalScheduleStepID
                         and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
                         and POS.C_GAUGE_TYPE_POS = '1'   -- uniquement position bien
                         and POS.STM_MOVEMENT_KIND_ID is null   -- prend que les CST et pas les BST/FST
                         and POS.C_DOC_POS_STATUS = '01'
                         and DOC.C_DOCUMENT_STATUS = '01'
                         and doc.DMT_PROTECTED = '0'
                    order by POS.A_DATECRE desc) loop
      lvErrorMsg  := null;
      lErrorCode  := null;
      lErrorText  := null;
      -- Convertir la qté stock en qté en unité d'achat
      lQtyCstPU   := ACS_FUNCTION.RoundNear(aValue => lDeltaQtySU / ltplPos.CDA_CONVERT_FACTOR, aRound => 1 / power(10, ltplPos.CDA_DECIMAL), aMode => 0);

      -- Si la quantité solde est négative et que la quantité solde sur la position n'est pas suffisante, calcul de la différence
      if     (lDeltaQtySU < 0)
         and (ltplPos.POS_BALANCE_QUANTITY <(lQtyCstPU * -1) ) then
        lQtyCstPU            := ltplPos.POS_BALANCE_QUANTITY * -1;
        -- La quantité à été modifiée, il faudra donc refaire une conversion inverse pour obtenir la quantité solde à reporter en US.
        lbConvertedModified  := true;
      end if;

      -- On essaie de reporter la quantité sur la position courante.
      DOC_PRC_DOCUMENT.UpdatePositionQtyUnitPrice(inPositionID   => ltplPos.DOC_POSITION_ID
                                                , inQuantity     => ltplPos.POS_BASIS_QUANTITY + lQtyCstPU
                                                , inUnitPrice    => ltplPos.POS_GROSS_UNIT_VALUE
                                                , outErrorCode   => lErrorCode
                                                , outErrorText   => lErrorText
                                                 );

      if lErrorCode is null then
        -- Si ok, mise à jour de l'opération externe en cas de modification de la quantité de la position...
        FAL_I_PRC_SUBCONTRACTO.UpdateOpAtPosGeneration(iScheduleStepID   => iFalScheduleStepID
                                                     , iSendingQty       => lDeltaQtySU
                                                     , iDocumentDate     => ltplPos.DMT_DATE_DOCUMENT
                                                      );

        -- ...et mise à jour de la quantité solde à reporter.
        if not lbConvertedModified then
          -- La quantité convertie n'a pas été modifiée, on a donc reporté la totalité de la quantité solde.
          lDeltaQtySU  := 0;
        else
          -- La quantité convertie a été modifiée, conversion inverse pour obtenir le solde de la quantité à reporter.
          lDeltaQtySU  :=
               lDeltaQtySU - ACS_FUNCTION.RoundNear(aValue   => lQtyCstPU * ltplPos.CDA_CONVERT_FACTOR, aRound => 1 / power(10, ltplPos.CDA_DECIMAL)
                                                  , aMode    => 0);   -- /! Conversion !!!\
        end if;
      elsif lDeltaQtySU > 0 then
        -- En cas d'erreur, si la quantité solde à reporter est > 0, on essaie de reporter la quantité sur une
        -- nouvelle position du premier document non verrouillé.
        lnPosID  := null;
        pGenerateOrderPos(iFalScheduleStepID   => iFalScheduleStepID
                        , iDocumentID          => ltplPos.DOC_DOCUMENT_ID
                        , iQty                 => lDeltaQtySU
                        , oPositionID          => lnPosID
                        , oErrorMsg            => lvErrorMsg
                         );

        -- Si la génération de la nouvelle position s'est bien déroulée, finalisation du document...
        if lvErrorMsg is null then
          DOC_FINALIZE.FinalizeDocument(aDocumentId => ltplPos.DOC_DOCUMENT_ID);
          -- ...et mise à jour de la quantité solde. A zéro car toute la qté a été assignée sur la nouvelle position.
          lDeltaQtySU  := 0;
        end if;
      end if;
    end loop;

    -- Si la quantité solide n'a pas pu être totalement reportées sur un document existant et qu'elle est positilve,
    -- on génère une nouvelle CST avec la quantité solde.
    if lDeltaQtySU > 0 then
      lvErrorMsg  := null;
      lnDocId     := null;
      pGenerateOrderDoc(iFalScheduleStepID => iFalScheduleStepID, oDocumentID => lnDocID, oErrorMsg => lvErrorMsg);

      -- Si la génération du document s'est bien déroulée, on génère la position
      if     lnDocID is not null
         and lvErrorMsg is null then
        lnPosID  := null;
        pGenerateOrderPos(iFalScheduleStepID   => iFalScheduleStepID
                        , iDocumentID          => lnDocID
                        , iQty                 => lDeltaQtySU
                        , oPositionID          => lnPosID
                        , oErrorMsg            => lvErrorMsg
                         );

        if lvErrorMsg is null then
          -- Si la génération de la nouvelle position s'est bien déroulée, finalisation du document...
          DOC_FINALIZE.FinalizeDocument(aDocumentId => lnDocId);
          lDeltaQtySU  := 0;
        end if;
      end if;
    elsif lDeltaQtySU < 0 then
      -- La quantité solde est négatite et n'a pas pu être totalement reportées sur les CST existantes. Message d'erreur.
      oError     :=
          replace(pcs.PC_FUNCTIONS.translateWord('La diminution de [XXX] unité(s) n'' pas pu être reportée sur les CST de l''opération'), '[XXX]', lDeltaQtySU);
      -- Calcul de la quantité reportées sur la/les CST (Qté initiale - qté restante)
      oDeltaQty  := oDeltaQty - lDeltaQtySU;
    end if;
  end UpdateCST;

  procedure DeletePosCST(
    iJobProgramId FAL_JOB_PROGRAM.FAL_JOB_PROGRAM_ID%type default null
  , iOrderId      FAL_ORDER.FAL_ORDER_ID%type default null
  , iLotId        fal_lot.fal_lot_id%type default null
  , iOperId       FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type default null
  )
  is
  begin
    -- Lecture de la config contenant le gabarit Commande sous-traitance
    for tplCheckExistsCST in (select distinct DOC.DMT_NUMBER
                                            , DOC.DOC_DOCUMENT_ID
                                            , POS.DOC_POSITION_ID
                                         from DOC_DOCUMENT DOC
                                            , DOC_POSITION POS
                                        where
                                              -- position lié à des opérations externes du lot
                                              (    (    iJobProgramId is not null
                                                    and iOrderId is null
                                                    and iLotId is null
                                                    and iOperId is null
                                                    and POS.FAL_SCHEDULE_STEP_ID in(
                                                          select FAL_SCHEDULE_STEP_ID
                                                            from FAL_TASK_LINK TAL
                                                               , FAL_LOT LOT
                                                           where TAL.FAL_LOT_ID = LOT.FAL_LOT_ID
                                                             and LOT.FAL_JOB_PROGRAM_ID = iJobProgramId
                                                             and TAL.C_TASK_TYPE = '2')
                                                   )
                                               or (    iOrderId is not null
                                                   and iLotId is null
                                                   and iOperId is null
                                                   and POS.FAL_SCHEDULE_STEP_ID in(
                                                                 select FAL_SCHEDULE_STEP_ID
                                                                   from FAL_TASK_LINK TAL
                                                                      , FAL_LOT LOT
                                                                  where TAL.FAL_LOT_ID = LOT.FAL_LOT_ID
                                                                    and LOT.FAL_ORDER_ID = iOrderId
                                                                    and TAL.C_TASK_TYPE = '2')
                                                  )
                                               or (    iLotId is not null
                                                   and iOperId is null
                                                   and POS.FAL_SCHEDULE_STEP_ID in(select FAL_SCHEDULE_STEP_ID
                                                                                     from FAL_TASK_LINK TAL
                                                                                    where TAL.FAL_LOT_ID = iLotId
                                                                                      and TAL.C_TASK_TYPE = '2')
                                                  )
                                               or (    iOperId is not null
                                                   and POS.FAL_SCHEDULE_STEP_ID = iOperId)
                                              )
                                          and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
                                          and DOC_LIB_SUBCONTRACTO.IsSUOOGauge(DOC.DOC_GAUGE_ID) = 1
                                     order by DOC.DMT_NUMBER) loop
      DOC_DELETE.DeletePosition(tplCheckExistsCST.DOC_POSITION_ID, true);

      -- Mémoriser les documents contenant les différentes postions éffacées
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_ID_1
                 , LID_CODE
                  )
           values (INIT_ID_SEQ.nextval
                 , tplCheckExistsCST.DOC_DOCUMENT_ID
                 , 'DELETE_DOCUMENT'
                  );
    end loop;

    for ltplDoc in (select DOC.DOC_DOCUMENT_ID
                      from COM_LIST_ID_TEMP LID
                         , DOC_DOCUMENT DOC
                     where DOC.DOC_DOCUMENT_ID = LID.LID_ID_1
                       and LID.LID_CODE = 'DELETE_DOCUMENT'
                       and not exists(select 1
                                        from DOC_POSITION POS
                                       where POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID) ) loop
      DOC_DELETE.deleteDocument(ltplDoc.DOC_DOCUMENT_ID, 0);
    end loop;
  end DeletePosCST;

  /**
  * Description
  *   Ajouter les opérations à imprimer dans la table COM_LIST
  */
  procedure InsertComListToPrint(iJobId in out COM_LIST.LIS_JOB_ID%type)
  is
    lcSessionID COM_LIST.LIS_SESSION_ID%type;
  begin
    -- Récupération du job
    select INIT_TEMP_ID_SEQ.nextval
      into iJobId
      from dual;

    -- insertion des opérations et des propositions
    for ltplPrint in (select LID.COM_LIST_ID_TEMP_ID
                           , LID.LID_CODE
                        from COM_LIST_ID_TEMP LID
                       where (   LID.LID_CODE = 'PCST_BATCH'
                              or LID.LID_CODE = 'PCST_PROP')
                         and LID.LID_SELECTION = 1) loop
      COM_PRC_LIST.InsertIDList(ltplPrint.COM_LIST_ID_TEMP_ID, ltplPrint.LID_CODE, 'Impression des PCST', iJobId, lcSessionID);
    end loop;
  end InsertComListToPrint;

  /**
  * Description
  *   Mise à jour de la date d'impression des PCST des opérations
  */
  procedure UpdateTalPcstPrintDate(iContext in varchar2, iFalScheduleStepId FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
  is
    ltFalTaskLink     FWK_I_TYP_DEFINITION.t_crud_def;
    ltFalTaskLinkProp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    if (iContext = 'PCST_BATCH') then
      FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_FAL_ENTITY.gcFalTaskLink, iot_crud_definition => ltFalTaskLink, iv_primary_col => 'FAL_SCHEDULE_STEP_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFalTaskLink, 'FAL_SCHEDULE_STEP_ID', iFalScheduleStepId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFalTaskLink, 'TAL_PCST_PRINT_DATE', sysdate);
      FWK_I_MGT_ENTITY.UpdateEntity(ltFalTaskLink);
      FWK_I_MGT_ENTITY.Release(ltFalTaskLink);
    else
      -- Mise à jour de de la proposition d'opération
      FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcFalTaskLinkProp, iot_crud_definition => ltFalTaskLinkProp);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFalTaskLinkProp, 'FAL_TASK_LINK_PROP_ID', iFalScheduleStepId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltFalTaskLinkProp, 'TAL_PCST_PRINT_DATE', sysdate);
      FWK_I_MGT_ENTITY.UpdateEntity(ltFalTaskLinkProp);
      FWK_I_MGT_ENTITY.Release(ltFalTaskLinkProp);
    end if;
  end UpdateTalPcstPrintDate;

   /**
  * procedure UpdateCSTBasisDelay
  * Description
  *   Modification du délai de base avec recalcul des délais intermédiaire/final
  *     du détail de position de la CST lié au lot de fabrication
  * @created AGA
  * @lastUpdate
  * @public
  * @param iFalOperID : ID de l'opération qui a généré la CST
  * @param iNewDelay : nouveau délai de base du détail
  */
  procedure UpdateCSTBasisDelay(iFalOperID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type, iNewDelay in date)
  is
  begin
    DOC_PRC_SUBCONTRACT.UpdatePOSDelay(iFalOperId => iFalOperID, iNewDelay => iNewDelay, iUpdatedDelay => 'BASIS');
  end UpdateCSTBasisDelay;

  /**
  * procedure UpdateCSTFinalDelay
  * Description
  *   Modification du délai final avec recalcul des délais intermédiaire/base
  *     du détail de position de la CST lié au lot de fabrication
  * @created AGA
  * @lastUpdate
  * @public
  * @param iFalOperID : ID de l'opération qui a généré la CST
  * @param iNewDelay : nouveau délai de base final
  */
  procedure UpdateCSTFinalDelay(iFalOperID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type, iNewDelay in date)
  is
  begin
    DOC_PRC_SUBCONTRACT.UpdatePOSDelay(iFalOperId => iFalOperID, iNewDelay => iNewDelay, iUpdatedDelay => 'FINAL');
  end UpdateCSTFinalDelay;

  /**
  * procedure UpdateCSTDelay
  * Description
  *   Update the delays of the detail position linked to the operation
  */
  procedure UpdateCSTDelay(iFalOperID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type)
  is
    ltDetail FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for ltplOpe in (select PDE.DOC_POSITION_DETAIL_ID
                         , OPE.TAL_BEGIN_PLAN_DATE
                         , OPE.TAL_END_PLAN_DATE
                      from DOC_POSITION_DETAIL PDE
                         , FAL_TASK_LINK OPE
                         , FAL_LOT lot
                     where PDE.FAL_SCHEDULE_STEP_ID = iFalOperID
                       and OPE.FAL_SCHEDULE_STEP_ID = PDE.FAL_SCHEDULE_STEP_ID
                       and lot.FAL_LOT_ID = ope.FAL_LOT_ID
                       and lot.C_SCHEDULE_PLANNING <> '1') loop
      FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocPositionDetail, ltDetail);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltDetail, 'DOC_POSITION_DETAIL_ID', ltplOpe.DOC_POSITION_DETAIL_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltDetail, 'PDE_BASIS_DELAY', ltplOpe.TAL_BEGIN_PLAN_DATE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltDetail, 'PDE_INTERMEDIATE_DELAY', ltplOpe.TAL_END_PLAN_DATE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltDetail, 'PDE_FINAL_DELAY', ltplOpe.TAL_END_PLAN_DATE);
      FWK_I_MGT_ENTITY.UpdateEntity(ltDetail);
      FWK_I_MGT_ENTITY.Release(ltDetail);
    end loop;
  end;

  /**
  * Description
  *   Mise à jour des positions des CST et leur(s) enfant(s) concernés après le solde du lot transmis.
  *   Les positions liquidées ou annulées ainsi que les positions enfants de la position ayant provoqué
  *   les mouvements ne seront pas touchées.
  */
  procedure updateCstAfterLotBalance(iLotID in FAL_LOT.FAL_LOT_ID%type)
  as
  begin
    /* Pour chaque positions de type 1 de CST liées à une opération externe du lot */
    for ltplCstPos in (select pos.DOC_POSITION_ID
                            , pos.C_DOC_POS_STATUS
                            , det.DOC_POSITION_DETAIL_ID
                         from table(FAL_I_LIB_BATCH.getUnbalancedCstPosIDs(iLotID => iLotID) ) cstPos
                            , DOC_DOCUMENT dmt
                            , DOC_POSITION pos
                            , DOC_POSITION_DETAIL det
                        where pos.DOC_POSITION_ID = cstPos.column_value
                          and dmt.DOC_DOCUMENT_ID = pos.DOC_DOCUMENT_ID
                          and dmt.DMT_PROTECTED = 0   -- Le document ne dois pas être en cours de modification
                          and det.DOC_POSITION_ID = pos.DOC_POSITION_ID) loop
      -- On efface les positions qui sont à confirmer et on solde celle qui sont à solder. Attention, aucun effacement ou solde de position
      -- ne sera effectué si le document CST est protégé.
      if (ltplCstPos.C_DOC_POS_STATUS = '01') then
        DOC_DELETE.deletePosition(aPositionId => ltplCstPos.DOC_POSITION_ID, aMajDocStatus => true);
      else
        if (DOC_POSITION_FUNCTIONS.canBalancePosition(aPositionId => ltplCstPos.DOC_POSITION_ID, aBalanceMvt => 0) = 1) then
          DOC_POSITION_FUNCTIONS.BalancePosition(aPositionId => ltplCstPos.DOC_POSITION_ID, aBalanceMvt => 0, aUpdateDocStatus => 1);
        end if;
      end if;
    end loop;
  end updateCstAfterLotBalance;

  /**
  * Description
  *   Calcul des nouveaux délais. Le délai des opérations des lots dont le code planification est 'selon produit'
  *   est calculé en fonction de la durée de planification (TAL_PLAN_RATE)
  */
  procedure CalculNewDelay
  is
    lvRelationTaype    varchar2(10);
    ldNewDelay         date;
    lnTalDuration      number       := 0;
    ldTalBeginPlanDate date;
  begin
    -- Mise à jour du message d'erreur
    ClearCSTErrorMessage;

    for ltplTaskLink in (select case C_SCHEDULE_PLANNING
                                  when '1' then LID.LID_FREE_DATE_1
                                  else trunc(LID.LID_FREE_DATE_1) +(TAL_BEGIN_PLAN_DATE - trunc(TAL_BEGIN_PLAN_DATE) )
                                end SEND_DATE
                              , LID.LID_FREE_DATE_2
                              , TAL.TAL_TASK_MANUF_TIME
                              , TAL.PAC_SUPPLIER_PARTNER_ID
                              , TAL.FAL_LOT_ID
                              , TAL.SCS_STEP_NUMBER
                              , TAL.FAL_SCHEDULE_STEP_ID
                              , LOT.LOT_REFCOMPL
                              , LID.COM_LIST_ID_TEMP_ID
                              , TAL.TAL_DUE_QTY
                              , lot.C_SCHEDULE_PLANNING
                              , nvl(tal.TAL_PLAN_RATE, 0) TAL_PLAN_RATE
                           from COM_LIST_ID_TEMP LID
                              , FAL_TASK_LINK TAL
                              , FAL_LOT LOT
                          where LID.COM_LIST_ID_TEMP_ID = TAL.FAL_SCHEDULE_STEP_ID
                            and LID.LID_CODE = 'FAL_SCHEDULE_STEP_ID'
                            and LOT.FAL_LOT_ID = TAL.FAL_LOT_ID
                            and LID.LID_SELECTION = 1) loop
      if ltplTaskLink.C_SCHEDULE_PLANNING = '1' then
        -- Si la gamme est planifiée 'selon produit', le délai est calculé à partir du champ 'planification'.
        ldNewDelay  :=
          FAL_SCHEDULE_FUNCTIONS.GetDecalage(aPAC_SUPPLIER_PARTNER_ID   => ltplTaskLink.PAC_SUPPLIER_PARTNER_ID
                                           , aFromDate                  => ltplTaskLink.SEND_DATE
                                           , aDecalage                  => ltplTaskLink.TAL_PLAN_RATE
                                            );
      else
        FAL_PLANIF.planOneOperation(ltplTaskLink.FAL_LOT_ID   --iBatchOrPropId
                                  , ltplTaskLink.FAL_SCHEDULE_STEP_ID
                                  , ltplTaskLink.PAC_SUPPLIER_PARTNER_ID
                                  , 1   -- aAllInInfiniteCap
                                  , ltplTaskLink.SEND_DATE   -- aDatePlanification
                                  , 1   -- aForward
                                  , ltplTaskLink.TAL_DUE_QTY
                                  , ldTalBeginPlanDate
                                  , ldNewDelay
                                  , lnTalDuration
                                   );
      end if;

      if ldNewDelay is null then   -- Voir si ldNewDeleay peut être null ???
        -- Erreur : Délai n'a pas pu être calculé
        update COM_LIST_ID_TEMP
           set LID_FREE_MEMO_1 =
                 '1 ' ||
                 PCS.PC_FUNCTIONS.TranslateWord('Erreur(s) trouvée(s) :') ||
                 ' ' ||
                 PCS.PC_FUNCTIONS.TranslateWord('Les opérations suivantes ne pourront pas être confirmées délais')
         where COM_LIST_ID_TEMP_ID = ltplTaskLink.COM_LIST_ID_TEMP_ID
           and LID_CODE = 'FAL_SCHEDULE_STEP_ID';
      else
        -- Mise à jour du nouveau délai demandé dans la table COM_LIST_ID_TEMP
        update COM_LIST_ID_TEMP
           set LID_FREE_DATE_2 = ldNewDelay
         where COM_LIST_ID_TEMP_ID = ltplTaskLink.FAL_SCHEDULE_STEP_ID;
      end if;
    end loop;
  end CalculNewDelay;

  /**
  * Description
  *   Génération d'une confirmation sur le traitement des opérations sélectionnées
  */
  procedure GenerateConfirmation
  is
    lvErrorMsg  varchar2(4000);
    lvFreeMemo1 varchar2(4000);
  begin
    for ltplTaskLink in (select TAL.FAL_SCHEDULE_STEP_ID
                              , LID.LID_FREE_DATE_1
                              , LID.LID_FREE_DATE_2
                              , LID.COM_LIST_ID_TEMP_ID
                              , LID.LID_ID_1   --PAC_SUPPLIER_PARTNER_ID
                              , LID.LID_ID_2   --GCO_GCO_GOOD_ID
                           from COM_LIST_ID_TEMP LID
                              , FAL_TASK_LINK TAL
                          where LID.COM_LIST_ID_TEMP_ID = TAL.FAL_SCHEDULE_STEP_ID
                            and LID.LID_CODE = 'FAL_SCHEDULE_STEP_ID'
                            and LID.LID_FREE_DATE_2 is not null
                            and LID.LID_SELECTION = 1) loop
      begin
        -- Mise à jour du sous-traitant et du service
        update FAL_TASK_LINK
           set PAC_SUPPLIER_PARTNER_ID = ltplTaskLink.LID_ID_1
             , GCO_GCO_GOOD_ID = ltplTaskLink.LID_ID_2
         where FAL_SCHEDULE_STEP_ID = ltplTaskLink.FAL_SCHEDULE_STEP_ID;

        -- Application de la confirmation (re-planification)
        FAL_PRC_SUBCONTRACTO.ConfirmExternalTask(aTaskID         => ltplTaskLink.FAL_SCHEDULE_STEP_ID
                                               , aDate           => ltplTaskLink.LID_FREE_DATE_2
                                               , aSendDate       => ltplTaskLink.LID_FREE_DATE_1
                                               , aContext        => FAL_PRC_SUBCONTRACTO.ctxOrderGen
                                               , iConfirmDescr   => PCS.PC_FUNCTIONS.TranslateWord('Délai modifié lors de l''expédition')
                                                );
      exception
        when others then
          if sqlcode = -20001 then
            lvErrorMsg  :=
              PCS.PC_FUNCTIONS.TranslateWord('Cette opération ne pourra pas être confirmée avec cette date.') ||
              co.cLineBreak ||
              PCS.PC_FUNCTIONS.TranslateWord('Incompatibilité avec les dates déjà confirmées des autres opérations externes du lot.');
          else
            -- Unexpected error...
            lvErrorMsg  := sqlerrm;
          end if;

          select LID_FREE_MEMO_1
            into lvFreeMemo1
            from COM_LIST_ID_TEMP
           where COM_LIST_ID_TEMP_ID = ltplTaskLink.COM_LIST_ID_TEMP_ID;

          if lvFreeMemo1 is not null then
            lvErrorMsg  := lvFreeMemo1 || co.cLineBreak || '1 ' || PCS.PC_FUNCTIONS.TranslateWord('Erreur(s) trouvée(s) :') || ' ' || lvErrorMsg;
          else
            lvErrorMsg  := '1 ' || PCS.PC_FUNCTIONS.TranslateWord('Erreur(s) trouvée(s) :') || ' ' || lvErrorMsg;
          end if;

          -- Mise à jour du message d'erreur
          update COM_LIST_ID_TEMP
             set LID_FREE_MEMO_1 = substrb(lvErrorMsg, 1, 4000)
           where COM_LIST_ID_TEMP_ID = ltplTaskLink.COM_LIST_ID_TEMP_ID
             and LID_CODE = 'FAL_SCHEDULE_STEP_ID';
      end;
    end loop;
  end GenerateConfirmation;

  /**
  * Description
  *   Génération d'une confirmation sur le traitement d'une opération à traiter  (PCST)
  */
  procedure GenerateConfirmationPCST(
    iFalScheduleStepID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , iTalEndPlanDate    in FAL_TASK_LINK.TAL_END_PLAN_DATE%type
  , iTalConfirmDescr   in FAL_TASK_LINK.TAL_CONFIRM_DESCR%type
  )
  is
    lErrMsg varchar2(4000);
  begin
    -- Application de la confirmation (re-planification)
    FAL_PRC_SUBCONTRACTO.ConfirmExternalTask(aTaskID         => iFalScheduleStepID
                                           , aDate           => iTalEndPlanDate
                                           , aSendDate       => sysdate
                                           , aContext        => FAL_PRC_SUBCONTRACTO.ctxPortfolio
                                           , iConfirmDescr   => iTalConfirmDescr
                                            );
  exception
    when others then
      if sqlcode = -20001 then
        lErrMsg  :=
          PCS.PC_FUNCTIONS.TranslateWord('Cette opération ne pourra pas être confirmée avec cette date.') ||
          co.cLineBreak ||
          PCS.PC_FUNCTIONS.TranslateWord('Incompatibilité avec les dates déjà confirmées des autres opérations externes du lot.');
      else
        lErrMsg  := sqlerrm;
      end if;

      update COM_LIST_ID_TEMP
         set LID_FREE_MEMO_1 = '1 ' || PCS.PC_FUNCTIONS.TranslateWord('Erreur(s) trouvée(s) :') || ' ' || lErrMsg
       where COM_LIST_ID_TEMP_ID = iFalScheduleStepID;
  end GenerateConfirmationPCST;

  /**
  * Description
  *   Test si des erreurs existent suite au traitement des opérations
  */
  function ErrorExist(iLidCode COM_LIST_ID_TEMP.LID_CODE%type)
    return number
  is
    lnResult number(1);
  begin
    select nvl(max(1), 0)
      into lnResult
      from COM_LIST_ID_TEMP LID
     where LID.LID_CODE = iLidCode
       and LID.LID_SELECTION = 1
       and (   LID.LID_FREE_TEXT_1 is not null
            or LID_FREE_MEMO_1 is not null);

    return lnResult;
  end ErrorExist;

  /**
  * Description
  *   Contrôle des données des opérations sélectionnées avant génération des CST. Les erreurs
  *   sont stockées dans le champ LID_FREE_MEMO_1 de la table COM_LIST_ID_TEMP contenant les
  *   opérations.
  */
  procedure checkData
  as
    lErrorMsg     varchar2(4000)                  := '';
    lErrorCounter number                          := 0;
    ltComListTmp  FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    /* Purge des champs d'erreurs. */
    ClearCSTErrorMessage;

    /* Boucle sur les opérations sélectionnées */
    for ltplTaskLink in (select tal.FAL_SCHEDULE_STEP_ID
                              , tal.TAL_DUE_QTY
                              , tal.TAL_SUBCONTRACT_QTY
                              , per.C_PARTNER_STATUS PER_C_PARTNER_STATUS
                              , addr.C_PARTNER_STATUS ADD_C_PARTNER_STATUS
                              , goo.C_GOOD_STATUS
                              , lid.LID_FREE_NUMBER_2   -- Quantité à expédier
                              , lid.LID_FREE_DATE_1   -- Date d'envoi
                              , lid.LID_FREE_DATE_2   -- Nouveau délai
                              , lot.C_SCHEDULE_PLANNING
                           from COM_LIST_ID_TEMP lid
                              , FAL_TASK_LINK tal
                              , FAL_LOT lot
                              , PAC_PERSON per
                              , PAC_ADDRESS addr
                              , GCO_GOOD goo
                          where lid.COM_LIST_ID_TEMP_ID = tal.FAL_SCHEDULE_STEP_ID
                            and lot.FAL_LOT_ID = tal.FAL_LOT_ID
                            and lid.LID_CODE = 'FAL_SCHEDULE_STEP_ID'
                            and lid.LID_SELECTION = 1
                            and per.PAC_PERSON_ID = lid.LID_ID_1   --PAC_SUPPLIER_PARTNER_ID
                            and addr.PAC_PERSON_ID = per.PAC_PERSON_ID
                            and addr.ADD_PRINCIPAL = 1
                            and goo.GCO_GOOD_ID = lid.LID_ID_2) loop   --GCO_GCO_GOOD_ID
      /* Contrôle du nouveau délai demandé */
      if    ltplTaskLink.LID_FREE_DATE_2 is null
         or (ltplTaskLink.LID_FREE_DATE_2 < ltplTaskLink.LID_FREE_DATE_1) then
        if lErrorCounter > 0 then
          lErrorMsg  := lErrorMsg || co.cLineBreak;
        end if;

        lErrorMsg      := lErrorMsg || PCS.PC_FUNCTIONS.TranslateWord('Erreur de délai : Un nouveau délai demandé ne peut être antérieur à la date d en');   --voi
        lErrorCounter  := lErrorCounter + 1;
      end if;

      /* Contrôle de la quantité à expédier */
      if    (ltplTaskLink.LID_FREE_NUMBER_2 > ltplTaskLink.TAL_DUE_QTY - nvl(ltplTaskLink.TAL_SUBCONTRACT_QTY, 0) )
         or (ltplTaskLink.LID_FREE_NUMBER_2 <= 0) then
        if lErrorCounter > 0 then
          lErrorMsg  := lErrorMsg || co.cLineBreak;
        end if;

        lErrorMsg      := lErrorMsg || PCS.PC_FUNCTIONS.TranslateWord('Erreur de quantité : La quantité à expédier doit être supérieure à 0 et inférieu');   --e ou égale à la quantité disponible !
        lErrorCounter  := lErrorCounter + 1;
      end if;

      /* Contrôle du statut du fournisseur lié à l'opération externe */
      if ltplTaskLink.PER_C_PARTNER_STATUS <> '1' then   -- Actif log / fin
        if lErrorCounter > 0 then
          lErrorMsg  := lErrorMsg || co.cLineBreak;
        end if;

        lErrorMsg      := lErrorMsg || PCS.PC_FUNCTIONS.TranslateWord('Erreur fournisseur : Le fournisseur lié à l opération externe n est pas actif');   -- en logistique !
        lErrorCounter  := lErrorCounter + 1;
      end if;

      /* Contrôle du statut de l'adresse principale du fournisseur lié à l'opération externe */
      if ltplTaskLink.ADD_C_PARTNER_STATUS <> '1' then   -- Actif log / din
        if lErrorCounter > 0 then
          lErrorMsg  := lErrorMsg || co.cLineBreak;
        end if;

        lErrorMsg      := lErrorMsg || PCS.PC_FUNCTIONS.TranslateWord('Erreur fournisseur : L adresse principale du fournisseur lié à l opération exter');   -- ne n''est pas active en logistique !
        lErrorCounter  := lErrorCounter + 1;
      end if;

      /* Contrôle du statut du service lié à l'opération externe */
      if ltplTaskLink.C_GOOD_STATUS <> GCO_I_LIB_CONSTANT.gcGoodStatusActive then   -- différend d'actif
        if lErrorCounter > 0 then
          lErrorMsg  := lErrorMsg || co.cLineBreak;
        end if;

        lErrorMsg      := lErrorMsg || PCS.PC_FUNCTIONS.TranslateWord('Erreur Produit : Le service lié à l opération externe n est pas actif !');
        lErrorCounter  := lErrorCounter + 1;
      end if;

      /* Insertion du(des) message(s) d'erreur */
      if lErrorMsg is not null then
        lErrorMsg      := lErrorCounter || ' ' || PCS.PC_FUNCTIONS.TranslateWord('Erreur(s) trouvée(s) :') || ' ' || lErrorMsg;
        FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'COM_LIST_ID_TEMP_ID', ltplTaskLink.FAL_SCHEDULE_STEP_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_MEMO_1', substrb(lErrorMsg, 1, 4000) );
        FWK_I_MGT_ENTITY.UpdateEntity(ltComListTmp);
        FWK_I_MGT_ENTITY.Release(ltComListTmp);
        lErrorMsg      := '';
        lErrorCounter  := 0;
      end if;
    end loop;
  end checkData;

  /**
  * Description
  *   Mise à jour du flag de sélection du portefeuille
  */
  procedure UpdateFlagSelected
  is
  begin
    -- Lots
    for ltplTaskLink in (select TAL.FAL_SCHEDULE_STEP_ID
                              , LID.LID_SELECTION
                           from COM_LIST_ID_TEMP LID
                              , FAL_TASK_LINK TAL
                          where LID.COM_LIST_ID_TEMP_ID = TAL.FAL_SCHEDULE_STEP_ID
                            and LID.LID_CODE = 'PCST_BATCH') loop
      update FAL_TASK_LINK
         set TAL_SUBCONTRACT_SELECT = ltplTaskLink.LID_SELECTION
       where FAL_SCHEDULE_STEP_ID = ltplTaskLink.FAL_SCHEDULE_STEP_ID;
    end loop;

    -- Propositions de lot
    for ltplTaskLinkProp in (select TAL.FAL_TASK_LINK_PROP_ID
                                  , LID.LID_SELECTION
                               from COM_LIST_ID_TEMP LID
                                  , FAL_TASK_LINK_PROP TAL
                              where LID.COM_LIST_ID_TEMP_ID = TAL.FAL_TASK_LINK_PROP_ID
                                and LID.LID_CODE = 'PCST_PROP') loop
      update FAL_TASK_LINK_PROP
         set TAL_SUBCONTRACT_SELECT = ltplTaskLinkProp.LID_SELECTION
       where FAL_TASK_LINK_PROP_ID = ltplTaskLinkProp.FAL_TASK_LINK_PROP_ID;
    end loop;
  end UpdateFlagSelected;

  /**
  * Description
  *   Flag les positions documents liées à une opération, comme ayant généré les mouvements de composants
  */
  procedure FlagMovementsGenerated(iDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
  begin
    for ltplPosition in (select DOC_POSITION_ID
                           from DOC_POSITION
                          where DOC_DOCUMENT_ID = iDocumentId
                            and FAL_SCHEDULE_STEP_ID is not null
                            and DOC_LIB_SUBCONTRACTO.IsMovementOnPosParent(DOC_POSITION_ID) = 0) loop
      update DOC_POSITION
         set POS_GENERATE_SUBCO_COMP_MVT = 1
       where DOC_POSITION_ID = ltplPosition.DOC_POSITION_ID;
    end loop;
  end FlagMovementsGenerated;
end DOC_PRC_SUBCONTRACTO;
