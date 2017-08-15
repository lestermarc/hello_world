--------------------------------------------------------
--  DDL for Package Body GAL_PRC_PROJECT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_PRC_PROJECT" 
is
  procedure SetMessage(ioFullMessage in out varchar2, iNewMessage in varchar2)
  is
  begin
    ioFullMessage  := ioFullMessage || PCS.PC_FUNCTIONS.TranslateWord(iNewMessage) || chr(10);
  end;

  /**
  * function CreatePROJECT
  * Description
  *   Création d'un projet
  * @created AGA 16.12.2011
  * @lastUpdate
  * @public
  * @param iPRJ_CODE                     : Code projet
  * @param iPRJ_WORDING                  : Description
  * @return number                       : valeur de GAL_PROJECT_ID de l'enregistrement créé
  */
  function CreatePROJECT(iPRJ_CODE in GAL_PROJECT.PRJ_CODE%type, iPRJ_WORDING in GAL_PROJECT.PRJ_WORDING%type)
    return number
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
    lResult    GAL_PROJECT.GAL_PROJECT_ID%type;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_GAL_ENTITY.gcGalProject, ltCRUD_DEF, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PRJ_CODE', iPRJ_CODE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PRJ_WORDING', iPRJ_WORDING);
    -- DML statement
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    lResult  := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltCRUD_DEF, 'GAL_PROJECT_ID');
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    return lResult;
  end CreatePROJECT;

  /**
   * function CreateDF
   * Description
   *   Création d'un dossier de fabrication lié à une tâche parente d'un projet
   * @created AGA 16.12.2011
   * @lastUpdate
   * @public
   * @return number                       : valeur de GAL_PROJECT_ID de l'enregistrement créé
   */
  function CreateTASK_DF(
    iGAL_FATHER_TASK_ID in GAL_TASK.GAL_FATHER_TASK_ID%type
  , iTAS_QUANTITY       in GAL_TASK.TAS_QUANTITY%type
  , iTAS_START_DATE     in GAL_TASK.TAS_START_DATE%type
  , iTAS_END_DATE       in GAL_TASK.TAS_END_DATE%type
  , iTAS_DESCRIPTION    in GAL_TASK.TAS_DESCRIPTION%type
  , iTAS_COMMENT        in GAL_TASK.TAS_COMMENT%type
  )
    return number
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
    lResult    GAL_TASK.GAL_TASK_ID%type;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_GAL_ENTITY.gcGalTask, ltCRUD_DEF, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GAL_FATHER_TASK_ID', iGAL_FATHER_TASK_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TAS_QUANTITY', iTAS_QUANTITY);

    if iTAS_START_DATE is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TAS_START_DATE', iTAS_START_DATE);
    end if;

    if iTAS_END_DATE is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TAS_END_DATE', iTAS_END_DATE);
    end if;

    if iTAS_DESCRIPTION is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TAS_DESCRIPTION', iTAS_DESCRIPTION);
    end if;

    if iTAS_COMMENT is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TAS_COMMENT', iTAS_COMMENT);
    end if;

    -- DML statement
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    lResult  := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltCRUD_DEF, 'GAL_TASK_ID');
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    return lResult;
  end CreateTASK_DF;

    /**
  * function CreateTASK_LOT
  * Description
  *   Création d'un projet
  * @created AGA 16.12.2011
  * @lastUpdate
  * @public
  * @return number                       : valeur de GAL_PROJECT_ID de l'enregistrement créé
  */
  function CreateTASK_LOT(
    iGAL_TASK_ID  in GAL_TASK_LOT.GAL_TASK_ID%type
  , iGCO_GOOD_ID  in GAL_TASK_LOT.GCO_GOOD_ID%type
  , iGTL_QUANTITY in GAL_TASK_LOT.GTL_QUANTITY%type
  )
    return number
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
    lResult    GAL_TASK_LOT.GAL_TASK_LOT_ID%type;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_GAL_ENTITY.gcGalTaskLot, ltCRUD_DEF, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GAL_TASK_ID', iGAL_TASK_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_GOOD_ID', iGCO_GOOD_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GTL_QUANTITY', iGTL_QUANTITY);
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    lResult  := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltCRUD_DEF, 'GAL_TASK_LOT_ID');
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    return lResult;
  end CreateTASK_LOT;

  /**
  * function CreateTASK_GOOD
  * Description
  *   Création d'un projet
  * @created AGA 16.12.2011
  * @lastUpdate
  * @public
  * @return number                       : valeur de GAL_PROJECT_ID de l'enregistrement créé
  */
  function CreateTASK_GOOD(
    iGAL_TASK_ID         in GAL_TASK_GOOD.GAL_TASK_ID%type
  , iGCO_GOOD_ID         in GAL_TASK_GOOD.GCO_GOOD_ID%type
  , iPPS_NOMENCLATURE_ID in GAL_TASK_GOOD.PPS_NOMENCLATURE_ID%type
  , iGML_QUANTITY        in GAL_TASK_GOOD.GML_QUANTITY%type
  , iGML_DESCRIPTION     in GAL_TASK_GOOD.GML_DESCRIPTION%type
  , iGML_COMMENT         in GAL_TASK_GOOD.GML_COMMENT%type
  )
    return number
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
    lResult    GAL_TASK_GOOD.GAL_TASK_GOOD_ID%type;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_GAL_ENTITY.gcGalTaskGood, ltCRUD_DEF, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GAL_TASK_ID', iGAL_TASK_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_GOOD_ID', iGCO_GOOD_ID);

    if iPPS_NOMENCLATURE_ID is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PPS_NOMENCLATURE_ID', iPPS_NOMENCLATURE_ID);
    end if;

    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GML_QUANTITY', iGML_QUANTITY);

    if iGML_DESCRIPTION is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GML_DESCRIPTION', iGML_DESCRIPTION);
    end if;

    if iGML_COMMENT is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GML_COMMENT ', iGML_COMMENT);
    end if;

    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    lResult  := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltCRUD_DEF, 'GAL_TASK_GOOD_ID');
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    return lResult;
  end CreateTASK_GOOD;

  /**
  * function CreateTASK_LINK
  * Description
  *   Création d'une opération du projet
  * @created AGA 16.12.2011
  * @lastUpdate
  * @public
  * @return number                       : valeur de GAL_PROJECT_ID de l'enregistrement créé
  */
  function CreateTASK_LINK(
    iGAL_TASK_ID              in GAL_TASK_LINK.GAL_TASK_ID%type
  , iFAL_TASK_ID              in GAL_TASK_LINK.FAL_TASK_ID%type
  , iFAL_FACTORY_FLOOR_ID     in GAL_TASK_LINK.FAL_FACTORY_FLOOR_ID%type
  , iFAL_FAL_FACTORY_FLOOR_ID in GAL_TASK_LINK.FAL_FAL_FACTORY_FLOOR_ID%type
  , iSCS_SHORT_DESCR          in GAL_TASK_LINK.SCS_SHORT_DESCR%type
  , iC_TASK_TYPE              in GAL_TASK_LINK.C_TASK_TYPE%type
  , iC_RELATION_TYPE          in GAL_TASK_LINK.C_RELATION_TYPE%type
  , iTAL_DUE_TSK              in GAL_TASK_LINK.TAL_DUE_TSK%type
  )
    return number
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
    lResult    GAL_TASK_LINK.GAL_TASK_LINK_ID%type;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_GAL_ENTITY.gcGalTaskLink, ltCRUD_DEF, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GAL_TASK_ID', iGAL_TASK_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FAL_TASK_ID', iFAL_TASK_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FAL_FACTORY_FLOOR_ID', iFAL_FACTORY_FLOOR_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FAL_FAL_FACTORY_FLOOR_ID', iFAL_FAL_FACTORY_FLOOR_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCS_SHORT_DESCR', iSCS_SHORT_DESCR);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_TASK_TYPE', iC_TASK_TYPE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_RELATION_TYPE', iC_RELATION_TYPE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TAL_DUE_TSK', iTAL_DUE_TSK);
    -- DML statement
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    lResult  := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltCRUD_DEF, 'GAL_TASK_LINK_ID');
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    return lResult;
  end CreateTASK_LINK;

  /**
  * function CreateBUDGET_LINE
  * Description
  *   Création d'une ligne de budget
  * @created AGA 16.12.2011
  * @lastUpdate
  * @public
  * @return number                       : valeur de GAL_PROJECT_ID de l'enregistrement créé
  */
  function CreateOrUpdateBUDGET_LINE(
    iGAL_BUDGET_ID       in GAL_BUDGET_LINE.GAL_BUDGET_ID%type
  , iGAL_COST_CENTER_ID  in GAL_BUDGET_LINE.GAL_COST_CENTER_ID%type
  , iBLI_BUDGET_QUANTITY in GAL_BUDGET_LINE.BLI_BUDGET_QUANTITY%type
  , iBLI_BUDGET_PRICE    in GAL_BUDGET_LINE.BLI_BUDGET_PRICE%type
  )
    return number
  is
    ltCRUD_DEF       FWK_I_TYP_DEFINITION.t_crud_def;
    lResult          GAL_BUDGET_LINE.GAL_BUDGET_LINE_ID%type;
    lCurrentPeriodID GAL_BUDGET_LINE.GAL_BUDGET_PERIOD_ID%type;
    lBudgetLineId    GAL_BUDGET_LINE.GAL_BUDGET_LINE_ID%type;
    lQte             number;
    lAmount          number;
    lPrice           number;
  begin
    select max(GAL_PROJECT.GAL_BUDGET_PERIOD_ID)
      into lCurrentPeriodID
      from GAL_PROJECT
         , GAL_BUDGET
     where GAL_BUDGET.GAL_BUDGET_ID = iGAL_BUDGET_ID
       and GAL_PROJECT.GAL_PROJECT_ID = GAL_BUDGET.GAL_PROJECT_ID
       and GAL_PROJECT.PRJ_BUDGET_PERIOD = 1;

    select max(GAL_BUDGET_LINE_ID)
      into lBudgetLineId
      from GAL_BUDGET_LINE
     where GAL_BUDGET_ID = iGAL_BUDGET_ID
       and GAL_COST_CENTER_ID = iGAL_COST_CENTER_ID
       and nvl(GAL_BUDGET_PERIOD_ID, 0) = nvl(lCurrentPeriodID, 0);

    lQte     := nvl(iBLI_BUDGET_QUANTITY, 0);
    lPrice   := nvl(iBLI_BUDGET_PRICE, 0);
    lAmount  := lQte * lPrice;

    if lBudgetLineId is null then
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GAL_ENTITY.gcGalBudgetLine, ltCRUD_DEF, true);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GAL_BUDGET_ID', iGAL_BUDGET_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GAL_COST_CENTER_ID', iGAL_COST_CENTER_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GAL_BUDGET_PERIOD_ID', lCurrentPeriodId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'BLI_BUDGET_QUANTITY', lQte);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'BLI_BUDGET_PRICE', lPrice);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'BLI_BUDGET_AMOUNT', lAmount);
      -- DML statement
      FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    else
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GAL_ENTITY.gcGalBudgetLine, ltCRUD_DEF, true, lBudgetLineId);
      lQte     := lQte + FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_DEF, 'BLI_BUDGET_QUANTITY');
      lAmount  := lAmount + FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_DEF, 'BLI_BUDGET_AMOUNT');

      if lQte > 0 then
        lPrice  := lAmount / lQte;
      end if;

      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'BLI_BUDGET_QUANTITY', lQte);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'BLI_BUDGET_PRICE', lPrice);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'BLI_BUDGET_AMOUNT', lAmount);
      -- DML statement
      FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    end if;

    lResult  := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltCRUD_DEF, 'GAL_BUDGET_LINE_ID');
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    return lResult;
  end CreateOrUpdateBUDGET_LINE;

  /**
  * procedure CheckPROJECTData
  * Description
  *    Contrôle avant mise à jour du projet
  * @author AGA
  * @created SEP.2011
  * @lastUpdate
  * @public
  * @param   iotPROJECT : Dossier SAV
  */
  procedure CheckPROJECTData(iotPROJECT in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    ltplPROJECT             FWK_TYP_GAL_ENTITY.tPROJECT                       := FWK_TYP_GAL_ENTITY.gttPROJECT(iotPROJECT.entity_id);
    lMessage                varchar2(1000);
    lCount                  number;
    lDOC_GAUGE_NUMBERING_ID DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID%type;
    lGAN_PREFIX             DOC_GAUGE_NUMBERING.GAN_PREFIX%type;
    lDIC_PRJ_BUDGET_PERIOD  DIC_GAL_PRJ_CATEGORY.DIC_PRJ_BUDGET_PERIOD%type;
    lPRJ_CODE               GAL_PROJECT.PRJ_CODE%type;
    lGCO_GOOD_ID            GAL_PROJECT.GCO_GOOD_ID%type;
    lPPS_NOMENCLATURE_ID    GAL_PROJECT.PPS_NOMENCLATURE_ID%type;
    lPRJ_PLAN_NUMBER        GAL_PROJECT.PRJ_PLAN_NUMBER%type;
    lPRJ_PLAN_VERSION       GAL_PROJECT.PRJ_PLAN_VERSION%type;
  begin
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotPROJECT, 'GAL_PROJECT_ID') then
      lMessage  := lMessage || PCS.PC_FUNCTIONS.TranslateWord('Le champ doit avoir une valeur :') || ' "GAL_PROJECT_ID"' || chr(10);
    end if;

    -- Contrôle du code etat du projet
    if (ltplPROJECT.C_PRJ_STATE = '40') then
      SetMessage(lMessage, 'Le code état de l''affaire n''autorise pas cette action');
    end if;

    -- Contrôle maj code de gestion des périodes
    if FWK_I_MGT_ENTITY_DATA.IsModified(iotPROJECT, 'PRJ_BUDGET_PERIOD') then
      select count(*)
        into lCount
        from GAL_BUDGET BDG
           , GAL_BUDGET_LINE BLI
       where BDG.GAL_PROJECT_ID = ltplPROJECT.GAL_PROJECT_ID
         and BDG.GAL_BUDGET_ID = BLI.GAL_BUDGET_ID;

      if lCount > 0 then
        SetMessage(lMessage, 'Le champ "Budgets périodiques" ne peut pas être modifié, car il y a déjà des périodes budgétaires définies !');
      end if;
    end if;

    if lMessage is not null then
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckPROJECTData'
                                         );
    end if;

    -- initialisation valeurs par défaut

    -- initialisation du status du projet
    if ltplPROJECT.C_PRJ_STATE is null then
      ltplPROJECT.C_PRJ_STATE  := '10';
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotPROJECT, 'C_PRJ_STATE', ltplPROJECT.C_PRJ_STATE);
    end if;

    -- traitement des mise à jour
    if FWK_I_MGT_ENTITY_DATA.IsModified(iotPROJECT, 'DIC_GAL_PRJ_CATEGORY_ID') then
      if ltplPROJECT.DIC_GAL_PRJ_CATEGORY_ID is not null then
        select DOC_GAUGE_NUMBERING_ID
             , nvl(DIC_PRJ_BUDGET_PERIOD, 0)
          into lDOC_GAUGE_NUMBERING_ID
             , lDIC_PRJ_BUDGET_PERIOD
          from DIC_GAL_PRJ_CATEGORY
         where DIC_GAL_PRJ_CATEGORY_ID = ltplPROJECT.DIC_GAL_PRJ_CATEGORY_ID;

        if     ltplPROJECT.PRJ_CODE is null
           and lDOC_GAUGE_NUMBERING_ID is not null then
          Doc_document_functions.GetDocumentNumber(null, lDOC_GAUGE_NUMBERING_ID, lPRJ_CODE);
          ltplPROJECT.PRJ_CODE  := lPRJ_CODE;
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotPROJECT, 'PRJ_CODE', ltplPROJECT.PRJ_CODE);
        end if;

        select count(*)
          into lCount
          from GAL_BUDGET
         where GAL_PROJECT_ID = ltplPROJECT.GAL_PROJECT_ID;

        if lCount = 0 then
          ltplPROJECT.PRJ_BUDGET_PERIOD  := lDIC_PRJ_BUDGET_PERIOD;
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotPROJECT, 'PRJ_BUDGET_PERIOD', ltplPROJECT.PRJ_BUDGET_PERIOD);
        end if;
      end if;
    end if;

    -- initialisation CODE TAUX
    if ltplPROJECT.PRJ_BUDGET_PERIOD is null then
      ltplPROJECT.PRJ_BUDGET_PERIOD  := 0;
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotPROJECT, 'PRJ_BUDGET_PERIOD', ltplPROJECT.PRJ_BUDGET_PERIOD);
    end if;

    -- Description par défaut
    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotPROJECT, 'PRJ_CODE')
       and ltplPROJECT.PRJ_WORDING is null then
      ltplPROJECT.PRJ_WORDING  := ltplPROJECT.PRJ_CODE;
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotPROJECT, 'PRJ_WORDING', ltplPROJECT.PRJ_WORDING);
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotPROJECT, 'GCO_GOOD_ID') then
      if ltplPROJECT.PPS_NOMENCLATURE_ID is not null then
        select GCO_GOOD_ID
          into lGCO_GOOD_ID
          from PPS_NOMENCLATURE
         where PPS_NOMENCLATURE_ID = ltplPROJECT.PPS_NOMENCLATURE_ID;

        ltplPROJECT.GCO_GOOD_ID  := lGCO_GOOD_ID;
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotPROJECT, 'GCO_GOOD_ID', ltplPROJECT.GCO_GOOD_ID);
      end if;
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotPROJECT, 'PPS_NOMENCLATURE_ID') then
      select nvl(max(PPS_NOMENCLATURE_ID), 0)
        into lPPS_NOMENCLATURE_ID
        from PPS_NOMENCLATURE
       where PPS_NOMENCLATURE.DOC_RECORD_ID = ltplPROJECT.DOC_RECORD_ID
         and rownum = 1;

      if lPPS_NOMENCLATURE_ID <> nvl(ltplPROJECT.PPS_NOMENCLATURE_ID, 0) then
        SetMessage(lMessage, 'une nomenclature d''installation à déjà été générée');
      end if;

      select count(*)
        into lCount
        from GAL_BUDGET
       where GAL_BUDGET.GAL_PROJECT_ID = ltplPROJECT.GAL_PROJECT_ID
         and GAL_BUDGET.PPS_NOMENCLATURE_ID is not null
         and rownum = 1;

      if lCount > 0 then
        SetMessage(lMessage, 'une nomenclature est déjà liée à un code budget');
      end if;

      select nvl(max(GCO_GOOD_ID), 0)
        into lGCO_GOOD_ID
        from PPS_NOMENCLATURE
       where PPS_NOMENCLATURE_ID = ltplPROJECT.PPS_NOMENCLATURE_ID;

      if lGCO_GOOD_ID = 0 then
        lGCO_GOOD_ID  := ltplPROJECT.GCO_GOOD_ID;
      end if;

      select count(*)
        into lCount
        from GAL_TASK_GOOD
           , GAL_TASK
       where GAL_TASK_GOOD.GAL_TASK_ID = GAL_TASK.GAL_TASK_ID
         and GAL_TASK.GAL_PROJECT_ID = ltplPROJECT.GAL_PROJECT_ID
         and GAL_TASK_GOOD.GCO_GOOD_ID = lGCO_GOOD_ID
         and rownum = 1;

      if lCount > 0 then
        SetMessage(lMessage, 'La tête de nomenclature d''installation ne peut pas être un article directeur de tâche');
      else
        ltplPROJECT.GCO_GOOD_ID  := lGCO_GOOD_ID;
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotPROJECT, 'GCO_GOOD_ID', ltplPROJECT.GCO_GOOD_ID);
      end if;

      if ltplPROJECT.PPS_NOMENCLATURE_ID is null then
        ltplPROJECT.GCO_GOOD_ID       := null;
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotPROJECT, 'GCO_GOOD_ID');
        ltplPROJECT.PRJ_PLAN_NUMBER   := null;
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotPROJECT, 'PRJ_PLAN_NUMBER');
        ltplPROJECT.PRJ_PLAN_VERSION  := null;
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotPROJECT, 'PRJ_PLAN_VERSION');
      else
        begin
          select trim(rpad(CMA_PLAN_NUMBER, 60) )
               , trim(rpad(CMA_PLAN_VERSION, 60) )
            into lPRJ_PLAN_NUMBER
               , lPRJ_PLAN_VERSION
            from GCO_COMPL_DATA_MANUFACTURE
           where CMA_DEFAULT = 1
             and GCO_GOOD_ID = ltplPROJECT.GCO_GOOD_ID;

          ltplPROJECT.PRJ_PLAN_NUMBER   := lPRJ_PLAN_NUMBER;
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotPROJECT, 'PRJ_PLAN_NUMBER', ltplPROJECT.PRJ_PLAN_NUMBER);
          ltplPROJECT.PRJ_PLAN_VERSION  := lPRJ_PLAN_VERSION;
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotPROJECT, 'PRJ_PLAN_VERSION', ltplPROJECT.PRJ_PLAN_VERSION);
        exception
          when no_data_found then
            null;
        end;
      end if;
    end if;

    if lMessage is not null then
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckPROJECTData'
                                         );
    end if;
  end CheckPROJECTData;

  /**
  * procedure CheckCURRENCY_RISKData
  * Description
  *    Contrôle avant mise à jour d'un composant d'une tâche d'un projet
  * @author ECA
  * @created SEP.2011
  * @lastUpdate
  * @public
  * @param   iotCURRENCY_RISK : projet
  */
  procedure CheckCURRENCY_RISKData(iotCURRENCY_RISK in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    ltplCURRENCY_RISK       FWK_TYP_GAL_ENTITY.tCurrencyRisk                  := FWK_TYP_GAL_ENTITY.gttCurrencyRisk(iotCURRENCY_RISK.entity_id);
    ltCRUD_DEF              FWK_I_TYP_DEFINITION.t_crud_def;
    lMessage                varchar2(1000);
    lCount                  number;
    lDOC_GAUGE_NUMBERING_ID DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID%type;

    procedure SetFWErrorMessage(iMessage in varchar2)
    is
      pragma autonomous_transaction;
    begin
      insert into COM_LIST_ID_TEMP
                  (LID_CODE
                 , LID_DESCRIPTION
                 , COM_LIST_ID_TEMP_ID
                  )
           values ('CheckCURRENCY_RISKData'
                 , iMessage
                 , INIT_ID_SEQ.nextval
                  );

      commit;   -- autonomous transaction
    end SetFWErrorMessage;
  begin
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotCURRENCY_RISK, 'GAL_CURRENCY_RISK_ID') then
      lMessage  := lMessage || PCS.PC_FUNCTIONS.TranslateWord('Le champ doit avoir une valeur :') || ' "GAL_CURRENCY_RISK_ID"' || chr(10);
    end if;

    if not(    (ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '01')   -- autocouverture
           or (ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '02')   -- hedge
           or (ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '03')   -- hors-couverture, cours fixe
           or (ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '04')
          ) then   -- hors-couverture, cours spot
      SetMessage(lMessage, 'La saisie du type de couverture est obligatoire');
    end if;

    if (nvl(ltplCURRENCY_RISK.GCK_BASE_PRICE, 0) <= 0) then
      SetMessage(lMessage, 'Le rapport du cours de change doit être supérieur à zéro');
    end if;

    -- Contrôle que le cours de change soit supérieur à 0
    if     (ltplCURRENCY_RISK.C_GAL_RISK_TYPE <> '04')   -- hors-couverture, spot
       and (nvl(ltplCURRENCY_RISK.GCK_RATE_OF_EXCHANGE, 0) <= 0) then
      SetMessage(lMessage, 'Le cours de change doit être supérieur à zéro');
    end if;

    -- Contrôle monnaie de la tranche selon type de couvertu: pour 01,02,03 doit etre différent de la monnaie de base
    if     (    (ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '01')   -- autocouverture
            or (ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '02')   -- hedge
            or (ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '03')
           )   -- hors-couverture, cours fixe
       and (ltplCURRENCY_RISK.ACS_FINANCIAL_CURRENCY_ID = ACS_FUNCTION.GETLOCALCURRENCYID) then
      SetMessage(lMessage, 'Monnaie de base pas autorisée pour les types de couverture 01,02,03');
    end if;

    -- Contrôle monnaie de la tranche selon type de couvertu: pour 01,02,03 doit etre différent de la monnaie de base
    if     (ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '04')   -- hors-couverture, spot
       and (ltplCURRENCY_RISK.ACS_FINANCIAL_CURRENCY_ID <> ACS_FUNCTION.GETLOCALCURRENCYID) then
      SetMessage(lMessage, 'Monnaie de base obligatoire pour le type de couverture 04');
    end if;

    -- Contrôle montant de la tranche selon type de couverture et code 100%
    if (    (     (ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '01')   -- autocouverture
             and (ltplCURRENCY_RISK.GCK_PCENT = 0) )
        or (ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '02')   -- hedge
        or (ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '03')   -- hors-couverture, cours fixe
        or (ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '04')   -- hors-couverture, cours spot
       ) then
      if (nvl(ltplCURRENCY_RISK.GCK_AMOUNT, 0) = 0) then
        SetMessage(lMessage, 'La saisie du montant de la tranche est obligatoire');
      elsif(nvl(ltplCURRENCY_RISK.GCK_AMOUNT, 0) < 0) then
        SetMessage(lMessage, 'Le montant de la tranche ne peut pas être inférieur à zéro');
      end if;
    end if;

    if     (     (ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '01')   -- autocouverture
            and (ltplCURRENCY_RISK.GCK_PCENT = 1) )
       and (nvl(ltplCURRENCY_RISK.GCK_AMOUNT, 0) <> 0) then
      SetMessage(lMessage, 'Le montant n''est pas gèré pour une tranche d''Auto-couverture à 100%');
    end if;

    -- Si type auto-couverture la date d'échéance est obligatoire
    if     (ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '02')   -- hedge
       and (ltplCURRENCY_RISK.GCK_PAYMENT_DATE is null) then
      SetMessage(lMessage, 'La date d''échéance est obligatoire pour une tranche de hedge');
    end if;

    --forcer le code 100% à false pour les traches de hedge et hors couverture
    if     (    (ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '02')   -- hedge
            or (ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '03')   -- hors-couverture, cours fixe
            or (ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '04')   -- hors-couverture, cours spot
           )
       and (ltplCURRENCY_RISK.GCK_PCENT = 1) then
      ltplCURRENCY_RISK.GCK_PCENT  := 0;
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotCURRENCY_RISK, 'GCK_PCENT', ltplCURRENCY_RISK.GCK_PCENT);
    end if;

    --forcer la monnaie locale et taux de change = 1 si le type de couverture = '04' (SPOT)
    if (ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '04') then   --hors-couverture, cours spot
      ltplCURRENCY_RISK.GCK_BASE_PRICE             := 1;
      ltplCURRENCY_RISK.GCK_RATE_OF_EXCHANGE       := 1;
      ltplCURRENCY_RISK.ACS_FINANCIAL_CURRENCY_ID  := ACS_FUNCTION.GETLOCALCURRENCYID;
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotCURRENCY_RISK, 'GCK_BASE_PRICE', 1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotCURRENCY_RISK, 'GCK_RATE_OF_EXCHANGE', 1);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotCURRENCY_RISK, 'ACS_FINANCIAL_CURRENCY_ID', ACS_FUNCTION.GETLOCALCURRENCYID);
    end if;

    -- Si saisie du tranche de hedge
    -- ne peut pas être saisi si il existe déjà une tranche d'autocouverture à 100%
    if (ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '02') then   --hedge
      select count(*)
        into lCount
        from GAL_CURRENCY_RISK
       where GAL_PROJECT_ID = ltplCURRENCY_RISK.GAL_PROJECT_ID
         and GAL_CURRENCY_RISK_ID <> ltplCURRENCY_RISK.GAL_CURRENCY_RISK_ID
         and ACS_FINANCIAL_CURRENCY_ID = ltplCURRENCY_RISK.ACS_FINANCIAL_CURRENCY_ID
         and C_GAL_RISK_DOMAIN = ltplCURRENCY_RISK.C_GAL_RISK_DOMAIN
         and C_GAL_RISK_TYPE = '01'
         and GCK_PCENT = 1;

      if lCount > 0 then
        SetMessage(lMessage, 'Il existe déjà une tranche d''auto-couverture à 100%');
      end if;
    elsif     (ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '01')   --autocouverture
          and (ltplCURRENCY_RISK.GCK_PCENT = 1) then   -- 100%
      -- Si saisie d'une tranche d'auto-couverture à 100%
      -- ne peut pas être saisi si il existe déjà une tranche de hedge
      select count(*)
        into lCount
        from GAL_CURRENCY_RISK
       where GAL_PROJECT_ID = ltplCURRENCY_RISK.GAL_PROJECT_ID
         and GAL_CURRENCY_RISK_ID <> ltplCURRENCY_RISK.GAL_CURRENCY_RISK_ID
         and ACS_FINANCIAL_CURRENCY_ID = ltplCURRENCY_RISK.ACS_FINANCIAL_CURRENCY_ID
         and C_GAL_RISK_DOMAIN = ltplCURRENCY_RISK.C_GAL_RISK_DOMAIN
         and C_GAL_RISK_TYPE = '02';

      if lCount > 0 then
        SetMessage(lMessage, 'Il existe déjà une tranche de hedge');
      end if;

      -- Si saisie d'une tranche d'auto-couverture à 100%
      -- ne peut pas être saisi si il existe déjà une tranche d'auto-couverture à 100%
      select count(*)
        into lCount
        from GAL_CURRENCY_RISK
       where GAL_PROJECT_ID = ltplCURRENCY_RISK.GAL_PROJECT_ID
         and GAL_CURRENCY_RISK_ID <> ltplCURRENCY_RISK.GAL_CURRENCY_RISK_ID
         and ACS_FINANCIAL_CURRENCY_ID = ltplCURRENCY_RISK.ACS_FINANCIAL_CURRENCY_ID
         and C_GAL_RISK_DOMAIN = ltplCURRENCY_RISK.C_GAL_RISK_DOMAIN
         and C_GAL_RISK_TYPE = '01';

      if lCount > 0 then
        SetMessage(lMessage, 'Il existe déjà une tranche d''auto-couverture');
      end if;
    elsif     (ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '01')   --autocouverture
          and (ltplCURRENCY_RISK.GCK_PCENT = 0) then
           -- Si saisie d'une tranche d'auto-couverture sans code 100%
      -- ne peut pas être saisi si il existe déjà une tranche d'auto-couverture à 100%
      select count(*)
        into lCount
        from GAL_CURRENCY_RISK
       where GAL_PROJECT_ID = ltplCURRENCY_RISK.GAL_PROJECT_ID
         and GAL_CURRENCY_RISK_ID <> ltplCURRENCY_RISK.GAL_CURRENCY_RISK_ID
         and ACS_FINANCIAL_CURRENCY_ID = ltplCURRENCY_RISK.ACS_FINANCIAL_CURRENCY_ID
         and C_GAL_RISK_DOMAIN = ltplCURRENCY_RISK.C_GAL_RISK_DOMAIN
         and C_GAL_RISK_TYPE = '01'
         and GCK_PCENT = 1;

      if lCount > 0 then
        SetMessage(lMessage, 'Il existe déjà une tranche d''auto-couverture à 100%');
      end if;
    elsif(ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '03') then
      -- Si type de couverture = '03' (Hors couverture / cours de change fixe)
      -- ne peut pas être saisi si il existe déjà un type de couverture = '04' (Hors couverture / cours de change SPOT)
      select count(*)
        into lCount
        from GAL_CURRENCY_RISK
       where GAL_PROJECT_ID = ltplCURRENCY_RISK.GAL_PROJECT_ID
         and GAL_CURRENCY_RISK_ID <> ltplCURRENCY_RISK.GAL_CURRENCY_RISK_ID
         and C_GAL_RISK_DOMAIN = ltplCURRENCY_RISK.C_GAL_RISK_DOMAIN
         and C_GAL_RISK_TYPE = '04';

      if lCount > 0 then
        SetMessage(lMessage, 'Il existe déjà une tranche hors-couverture/spot');
      end if;
    -- Si type de couverture = '04' (Hors couverture / cours de change SPOT)
    -- ne peut pas être saisi si il existe déjà une tranche hors-couverture
    elsif(ltplCURRENCY_RISK.C_GAL_RISK_TYPE = '04') then
      select count(*)
        into lCount
        from GAL_CURRENCY_RISK
       where GAL_PROJECT_ID = ltplCURRENCY_RISK.GAL_PROJECT_ID
         and GAL_CURRENCY_RISK_ID <> ltplCURRENCY_RISK.GAL_CURRENCY_RISK_ID
         and C_GAL_RISK_DOMAIN = ltplCURRENCY_RISK.C_GAL_RISK_DOMAIN
         and (   C_GAL_RISK_TYPE = '03'
              or C_GAL_RISK_TYPE = '04');

      if lCount > 0 then
        SetMessage(lMessage, 'Il existe déjà une tranche hors-couverture');
      end if;
    end if;

    if lMessage is not null then
      SetFWErrorMessage(lMessage);
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckCURRENCY_RISKData'
                                         );
    end if;
  end CheckCURRENCY_RISKData;

   /**
  * procedure CheckCURRENCY_RISK_VIRTUALData
  * Description
  *    Contrôle avant mise à jour d'une tranche de couverture
  * @author AGA
  * @created JUN.2013
  * @lastUpdate
  * @public
  * @param   iotCURRENCY_RISK : tranche de couverture
  */
  procedure CheckCURRENCY_RISK_VIRTUALData(iotCURRENCY_RISK in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    ltplCURRENCY_RISK FWK_TYP_GAL_ENTITY.tCurrencyRisk                              := FWK_TYP_GAL_ENTITY.gttCurrencyRisk(iotCURRENCY_RISK.entity_id);
    ltCRUD_DEF        FWK_I_TYP_DEFINITION.t_crud_def;
    lMessage          varchar2(1000);
    lListDoc          varchar2(1000);
    lCount            number;
    -- valeurs de base couverture virtuelle avant mise à jour des champs
    lV1_Id            GAL_CURRENCY_RISK_VIRTUAL.GAL_CURRENCY_RISK_VIRTUAL_ID%type;
    lV1_Curr          GAL_CURRENCY_RISK_VIRTUAL.ACS_FINANCIAL_CURRENCY_ID%type;
    lV1_Type          GAL_CURRENCY_RISK_VIRTUAL.C_GAL_RISK_TYPE%type;
    lV1_Domain        GAL_CURRENCY_RISK_VIRTUAL.C_GAL_RISK_DOMAIN%type;
    lV1_PCent         GAL_CURRENCY_RISK_VIRTUAL.GCV_PCENT%type;
    lV1_Amount        GAL_CURRENCY_RISK_VIRTUAL.GCV_AMOUNT%type;
    lV1_Balance       GAL_CURRENCY_RISK_VIRTUAL.GCV_BALANCE%type;
    lV1_Rate          GAL_CURRENCY_RISK_VIRTUAL.GCV_RATE_OF_EXCHANGE%type;
    lV1_Base          GAL_CURRENCY_RISK_VIRTUAL.GCV_BASE_PRICE%type;
    -- valeurs de base couverture virtuelle après mise à jour des champs
    lV2_Id            GAL_CURRENCY_RISK_VIRTUAL.GAL_CURRENCY_RISK_VIRTUAL_ID%type;
    lV2_Curr          GAL_CURRENCY_RISK_VIRTUAL.ACS_FINANCIAL_CURRENCY_ID%type;
    lV2_Type          GAL_CURRENCY_RISK_VIRTUAL.C_GAL_RISK_TYPE%type;
    lV2_Domain        GAL_CURRENCY_RISK_VIRTUAL.C_GAL_RISK_DOMAIN%type;
    lV2_PCent         GAL_CURRENCY_RISK_VIRTUAL.GCV_PCENT%type;
    lV2_Amount        GAL_CURRENCY_RISK_VIRTUAL.GCV_AMOUNT%type;
    lV2_Balance       GAL_CURRENCY_RISK_VIRTUAL.GCV_BALANCE%type;
    lV2_Rate          GAL_CURRENCY_RISK_VIRTUAL.GCV_RATE_OF_EXCHANGE%type;
    lV2_Base          GAL_CURRENCY_RISK_VIRTUAL.GCV_BASE_PRICE%type;
    -- valeurs de l'enregistrement modifié avant mises à jour
    lR1_Id            GAL_CURRENCY_RISK.GAL_CURRENCY_RISK_ID%type;
    lR1_Curr          GAL_CURRENCY_RISK.ACS_FINANCIAL_CURRENCY_ID%type;
    lR1_Type          GAL_CURRENCY_RISK.C_GAL_RISK_TYPE%type;
    lR1_Domain        GAL_CURRENCY_RISK.C_GAL_RISK_DOMAIN%type;
    lR1_PCent         GAL_CURRENCY_RISK.GCK_PCENT%type;
    lR1_Amount        GAL_CURRENCY_RISK.GCK_AMOUNT%type;
    lR1_Balance       GAL_CURRENCY_RISK.GCK_BALANCE%type;
    lR1_Rate          GAL_CURRENCY_RISK.GCK_RATE_OF_EXCHANGE%type;
    lR1_Base          GAL_CURRENCY_RISK.GCK_BASE_PRICE%type;
    lR1_Date          GAL_CURRENCY_RISK.GCK_PAYMENT_DATE%type;
    --valeurs de l'enregistrement modifié avec mises à jour
    lR2_Id            GAL_CURRENCY_RISK.GAL_CURRENCY_RISK_ID%type;
    lR2_Curr          GAL_CURRENCY_RISK.ACS_FINANCIAL_CURRENCY_ID%type;
    lR2_Type          GAL_CURRENCY_RISK.C_GAL_RISK_TYPE%type;
    lR2_Domain        GAL_CURRENCY_RISK.C_GAL_RISK_DOMAIN%type;
    lR2_PCent         GAL_CURRENCY_RISK.GCK_PCENT%type;
    lR2_Amount        GAL_CURRENCY_RISK.GCK_AMOUNT%type;
    lR2_Balance       GAL_CURRENCY_RISK.GCK_BALANCE%type;
    lR2_Rate          GAL_CURRENCY_RISK.GCK_RATE_OF_EXCHANGE%type;
    lR2_Base          GAL_CURRENCY_RISK.GCK_BASE_PRICE%type;
    lR2_Date          GAL_CURRENCY_RISK.GCK_PAYMENT_DATE%type;

    procedure SetFWErrorMessage(iMessage in varchar2)
    is
      pragma autonomous_transaction;
    begin
      insert into COM_LIST_ID_TEMP
                  (LID_CODE
                 , LID_DESCRIPTION
                 , COM_LIST_ID_TEMP_ID
                  )
           values ('CheckCURRENCY_RISK_VIRTUALData'
                 , iMessage
                 , INIT_ID_SEQ.nextval
                  );

      commit;   -- autonomous transaction
    end SetFWErrorMessage;

    procedure UpdateVirtualOnDelete
    is
      ltCRUD_Histo         FWK_I_TYP_DEFINITION.t_crud_def;
      ltCRUD_Virtual_Histo FWK_I_TYP_DEFINITION.t_crud_def;
      lnDocsCount          integer;
    begin
      -- Vérifier si des documents sont liés à la tranche que l'on va effacer
      select count(*)
        into lnDocsCount
        from DOC_DOCUMENT
       where GAL_CURRENCY_RISK_VIRTUAL_ID = lV1_ID;

      if    (lnDocsCount > 0)
         or (     (lV1_PCent = 0)
             and (nvl(lV1_Amount, 0) <> nvl(lV1_Balance, 0) ) ) then
        SetMessage(lMessage, 'Effacement impossible, couverture virtuelle déjà utilisée !');
      else
        FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name         => 'GAL_CURRENCY_RISK_HISTO', iv_parent_key_name => 'GAL_CURRENCY_RISK_ID'
                                      , iv_parent_key_value   => lR1_ID);

        if lV1_ID is not null then
          -- mise à jour de l'historique des couvertures virtuelles, valeurs initiales
          -- Création historique couverture virtuelle
          FWK_I_MGT_ENTITY.new(FWK_I_TYP_GAL_ENTITY.gcGalCurrencyRiskVHisto, ltCRUD_Virtual_Histo, true);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GAL_PROJECT_ID', ltplCURRENCY_RISK.GAL_PROJECT_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GAL_CURRENCY_RISK_VIRTUAL_ID', lV1_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'ACS_FINANCIAL_CURRENCY_ID', lV1_Curr);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'C_GAL_RISK_TYPE1', lV1_Type);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_RATE_OF_EXCHANGE1', lV1_Rate / lV1_Base);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_PCENT1', lV1_PCent);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_AMOUNT1', lV1_Amount);
          --
          LR1_PCent    := nvl(lR1_PCent, 0);
          lR1_Amount   := nvl(lR1_Amount, 0);
          --
          LV1_PCent    := nvl(lV1_PCent, 0);
          lV1_Amount   := nvl(lV1_Amount, 0);
          lV1_Balance  := nvl(lV1_Balance, 0);

          -- calcul du nouveau taux
          if lV1_Amount - lR1_Amount <> 0 then
            lV1_Rate  := ( ( (lV1_amount *(lV1_Rate / lV1_base) ) -(lR1_amount *(lR1_Rate / lR1_base) ) ) /(lV1_Amount - lR1_Amount) ) * lV1_Base;
          end if;

          lV1_Amount   := lV1_Amount - lR1_Amount;
          lV1_Balance  := lV1_Balance - lR1_Amount;

          if lV1_PCent = 1 then
            lV1_Amount   := null;
            lV1_Balance  := null;
          end if;

          -- mise à jour couverture virtuelle
          if     lV1_Amount = 0
             and lV1_Balance = 0 then
            lV1_Amount   := null;
            lV1_Balance  := null;
            lV1_Rate     := lR1_Rate;
          end if;

          if    lV1_Rate <= 0
             or (    nvl(lV1_Amount, 1) <= 0
                 and lV1_PCent = 0)
             or (    nvl(lV1_Balance, 1) <= 0
                 and lV1_PCent = 0) then
            SetMessage(lMessage, 'Le montant, solde et taux calculé de la couverture virtuelle doivent étre supérieur à zéro !');
            FWK_I_MGT_ENTITY.Release(ltCRUD_Virtual_Histo);
          else
            FWK_I_MGT_ENTITY.new(FWK_I_TYP_GAL_ENTITY.gcGalCurrencyRiskVirtual, ltCRUD_DEF, true, lV1_ID);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GAL_CURRENCY_RISK_VIRTUAL_ID', lV1_ID);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCV_RATE_OF_EXCHANGE', lV1_Rate);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCV_PCENT', lV1_PCent);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCV_AMOUNT', lV1_Amount);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCV_BALANCE', lV1_Balance);
            FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
            FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
            -- mise à jour de l'historique des couvertures virtuelles valeurs modifiées
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'C_GAL_RISK_TYPE2', lV1_Type);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_RATE_OF_EXCHANGE2', lV1_Rate / lV1_Base);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_PCENT2', lV1_PCent);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_AMOUNT2', lV1_Amount);
            FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_Virtual_Histo);
            FWK_I_MGT_ENTITY.Release(ltCRUD_Virtual_Histo);
          end if;
        end if;
      end if;
    end;

    procedure UpdateVirtualOnInsert
    is
      ltCRUD_Histo         FWK_I_TYP_DEFINITION.t_crud_def;
      ltCRUD_Virtual_Histo FWK_I_TYP_DEFINITION.t_crud_def;
    begin
      if lV2_ID <> 0 then
        -- mise à jour de l'historique des couvertures virtuelles
        -- Création historique couverture virtuelle valeurs initiales
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_GAL_ENTITY.gcGalCurrencyRiskVHisto, ltCRUD_Virtual_Histo, true);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GAL_PROJECT_ID', ltplCURRENCY_RISK.GAL_PROJECT_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GAL_CURRENCY_RISK_VIRTUAL_ID', lV2_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'ACS_FINANCIAL_CURRENCY_ID', lV2_Curr);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'C_GAL_RISK_TYPE1', lV2_Type);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'C_GAL_RISK_TYPE2', lV2_Type);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_RATE_OF_EXCHANGE1', lV2_Rate / lV2_Base);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_PCENT1', lV2_PCent);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_AMOUNT1', lV2_Amount);
        --
        lV2_Amount   := nvl(lV2_Amount, 0);
        lV2_Balance  := nvl(lV2_Balance, 0);

        if lV2_Balance + lR2_Amount <> 0 then
          lV2_Rate  :=
                  ( ( (greatest(lV2_Balance, 0) *(lV2_Rate / lV2_base) ) +(lR2_amount *(lR2_Rate / lR2_base) ) ) /(greatest(lV2_Balance, 0) + lR2_Amount) )
                  * lV2_Base;
        end if;

        lV2_Amount   := lV2_Amount + lR2_Amount;
        lV2_Balance  := lV2_Balance + lR2_Amount;
        lV2_PCent    := lR2_PCent;

        if lV2_PCent = 1 then
          lV2_Amount   := null;
          lV2_Balance  := null;
          lR2_Amount   := null;
        end if;

        -- mise à jour couverture virtuelle
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_GAL_ENTITY.gcGalCurrencyRiskVirtual, ltCRUD_DEF, true, lV2_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GAL_CURRENCY_RISK_VIRTUAL_ID', lV2_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCV_RATE_OF_EXCHANGE', lV2_Rate);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCV_PCent', lV2_PCent);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCV_AMOUNT', lV2_Amount);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCV_BALANCE', lV2_Balance);
        FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
        FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);

        -- Appelé après insertion dans GAL_CURRENCY_RISK GAL_MGT_PROJECT.insertCURRENCY_RISK
        update GAL_CURRENCY_RISK
           set GAL_CURRENCY_RISK_VIRTUAL_ID = lV2_ID
         where GAL_CURRENCY_RISK_ID = ltplCURRENCY_RISK.GAL_CURRENCY_RISK_ID;

        -- mise à jour de l'historique des couvertures virtuelles valeurs modifiées
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_RATE_OF_EXCHANGE2', lV2_Rate / lV2_Base);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_PCENT2', lV2_PCent);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_AMOUNT2', lV2_Amount);
        FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_Virtual_Histo);
        FWK_I_MGT_ENTITY.Release(ltCRUD_Virtual_Histo);
        -- mise à jour de l'historique des couvertures
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_GAL_ENTITY.gcGalCurrencyRiskHisto, ltCRUD_Histo, true);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'GAL_PROJECT_ID', ltplCURRENCY_RISK.GAL_PROJECT_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'GAL_CURRENCY_RISK_ID', lR2_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'ACS_FINANCIAL_CURRENCY2_ID', lR2_Curr);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'C_GAL_RISK_DOMAIN2', lR2_Domain);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'C_GAL_RISK_TYPE2', lR2_Type);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'GRH_RATE_OF_EXCHANGE2', lR2_Rate / lR2_Base);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'GRH_PCENT2', lR2_PCent);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'GRH_AMOUNT2', lR2_Amount);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'GRH_PAYMENT_DATE2', lR2_Date);
        FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_Histo);
        FWK_I_MGT_ENTITY.Release(ltCRUD_Histo);
      end if;
    end;

    procedure UpdateVirtualOnUpdate
    is
      lRate                GAL_CURRENCY_RISK_VIRTUAL.GCV_RATE_OF_EXCHANGE%type;
      ltCRUD_Histo         FWK_I_TYP_DEFINITION.t_crud_def;
      ltCRUD_Virtual_Histo FWK_I_TYP_DEFINITION.t_crud_def;
      bContinue            boolean;
    begin
      if lV2_ID <> 0 then
        -- mise à jour de l'historique des couvertures virtuelles
        -- Création historique couverture virtuelle valeurs initiales
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_GAL_ENTITY.gcGalCurrencyRiskVHisto, ltCRUD_Virtual_Histo, true);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GAL_PROJECT_ID', ltplCURRENCY_RISK.GAL_PROJECT_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GAL_CURRENCY_RISK_VIRTUAL_ID', lV2_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'ACS_FINANCIAL_CURRENCY_ID', lV2_Curr);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'C_GAL_RISK_TYPE1', lV2_Type);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'C_GAL_RISK_TYPE2', lV2_Type);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_RATE_OF_EXCHANGE1', lV2_Rate / lV2_Base);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_PCENT1', lV2_PCent);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_AMOUNT1', lV2_Amount);
        -- Création historique couverture valeurs initiales
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_GAL_ENTITY.gcGalCurrencyRiskHisto, ltCRUD_Histo, true);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'GAL_PROJECT_ID', ltplCURRENCY_RISK.GAL_PROJECT_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'GAL_CURRENCY_RISK_ID', lR1_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'ACS_FINANCIAL_CURRENCY1_ID', lR1_Curr);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'C_GAL_RISK_DOMAIN1', lR1_Domain);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'C_GAL_RISK_TYPE1', lR1_Type);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'GRH_RATE_OF_EXCHANGE1', lR1_Rate);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'GRH_PCENT1', lR1_PCent);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'GRH_AMOUNT1', lR1_Amount);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'GRH_PAYMENT_DATE1', lR1_Date);
        --
        lR1_PCent    := nvl(lR1_PCent, 0);
        lR1_Amount   := nvl(lR1_Amount, 0);
        --
        lR2_PCent    := nvl(lR2_PCent, 0);
        lR2_Amount   := nvl(lR2_Amount, 0);
        --
        lV2_PCent    := nvl(lV2_PCent, 0);
        lV2_Amount   := nvl(lV2_Amount, 0);
        lV2_Balance  := nvl(lV2_Balance, 0);
        --
        bContinue    := true;

        -- Diminution du montant de la couverture
        if     (lR2_PCent = 0)
           and (lR1_Amount > lR2_Amount) then
          -- Si le solde de la couverture virtuelle était déjà inférieur à zéro, on empêche la diminution du montant
          if lV1_Balance < 0 then
            SetMessage(lMessage, 'Le solde de la couverture virtuelle doit être supérieur à zéro !');
            bContinue  := false;
          -- Le solde de la tranche virtuelle doit rester positif après la diminution du montant de la tranche
          elsif( (lV1_Balance + lR2_Amount - lR1_Amount) <= 0) then
            SetMessage(lMessage, 'Le solde de la couverture virtuelle doit être supérieur à zéro !');
            bContinue  := false;
          end if;
        end if;

        -- Changement du cours de change autorisé uniquement si solde supérieur à 0
        if     (bContinue)
           and (lR2_PCent = 0)
           and (lV1_Rate <> lV2_Rate)
           and (lV1_Balance <= 0) then
          SetMessage(lMessage, 'Le cours de change peut être modifié uniquement si le solde de la couverture virtuelle est supérieur à zéro !');
          bContinue  := false;
        end if;

        -- Changement du cours de change et du montant de la tranche simultanément est interdit si la tranche virtuelle a été consommée
        if     (bContinue)
           and (lR2_PCent = 0)
           and (lV1_Amount <> lV1_Balance)
           and (lR1_Rate <> lR2_Rate)
           and (lR1_Amount <> lR2_Amount) then
          SetMessage(lMessage
                   , 'Le changement du montant et du cours simultanément est interdit lorsque le solde de la couverture virtuelle a déjà été consommé !'
                    );
          bContinue  := false;
        end if;

        if bContinue then
          -- Tranche virtuelle pas encore consommée
          if (lV1_Amount = lV1_Balance) then
            -- Cours de change
            if (lV2_Amount - lR1_Amount + lR2_Amount) <> 0 then
              lRate  :=
                ( ( (lV2_amount *(lV2_Rate / lV2_base) ) -(lR1_amount *(lR1_Rate / lR1_base) ) +(lR2_amount *(lR2_Rate / lR2_base) ) ) /
                 (lV2_Amount - lR1_Amount + lR2_Amount
                 )
                );
            else
              lRate  := lV2_Rate;
            end if;

            lV2_Amount   := lV2_Amount - lR1_Amount + lR2_Amount;
            lV2_Balance  := lV2_Balance - lR1_Amount + lR2_Amount;
            lV2_PCent    := lR2_PCent;

            if lV2_Balance > 0 then
              lV2_Rate  := ( ( ( (lV2_amount * lRate) -( (lV2_Amount - lV2_Balance) *(lV2_Rate / lV2_base) ) ) / lV2_Balance) ) * lV2_Base;
            else
              lV2_Rate  := lRate;
            end if;
          else
            -- Tranche virtuelle déjà consommée
            -- Changement du cours de change
            if lR1_Rate <> lR2_Rate then
              /*
              TN = [(TNS*M)-((M-S)*TO]/S
              Où :
              M : Montant de la tranche virtuelle
              S : Solde de la tranche virtuelle
              TNS :Cours de change de la tranche virtuelle simulé calculé avec le nouveau cours de change simulé (on refait le calcul, comme si on avait les valeurs justes d’entrée)
              TO : Cours de change de la tranche virtuelle avant le changement de cours de change
              TN : Nouveau taux de la tranche virtuelle

              [la formule découle de la réflexion suivante :
              Le nouveau taux, si le solde = montant de la tranche est
              TNS = To + (Mk*Différence de taux de la tranche k)/M

              Dès que l’on a cela on fait un ajustement du taux pour tenir compte que la tranche a déjà été consommée, en posant :
              TNS = ((M-S)*To + S*TN)/M où TN compense le fait qu’une partie de la tranche a été consommé.
              Donc on fait en sorte de compenser le fait qu’une partie de la tranche a été consommée au faux taux]
              */
              -- Calcul du cours de change simulé
              lRate     := (lV1_Rate / lV1_Base) + (lR1_Amount *( (lR2_Rate / lR2_Base) -(lR1_Rate / lR1_Base) ) ) / lV1_Amount;
              -- Calcul du nouveau cours de la tranche virtuelle
              lV2_Rate  := ( (lRate * lV1_Amount) -( (lV1_Amount - lV1_Balance) *(lV1_Rate / lV1_Base) ) ) / lV1_Balance;
            end if;

            -- Changement du montant
            if lR1_Amount <> lR2_Amount then
              -- Solde négatif
              if lV1_Balance < 0 then
                -- Le cours de change de la tranche virtuelle = au nouveau cours
                lV2_Rate  := lR2_Rate;
              else
                lV2_Rate  := ( (lV1_Balance * lV1_Rate) +( (lR2_Amount - lR1_Amount) * lR2_Rate) ) /(lV1_Balance +(lR2_Amount - lR1_Amount) );
              end if;
            end if;

            lV2_Amount   := lV2_Amount - lR1_Amount + lR2_Amount;
            lV2_Balance  := lV2_Balance - lR1_Amount + lR2_Amount;
            lV2_PCent    := lR2_PCent;
          end if;

          if lV2_PCent = 1 then
            lV2_Amount   := null;
            lV2_Balance  := null;
            lR2_Amount   := null;
          end if;

          -- mise à jour couverture virtuelle
          FWK_I_MGT_ENTITY.new(FWK_I_TYP_GAL_ENTITY.gcGalCurrencyRiskVirtual, ltCRUD_DEF, true, lV2_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GAL_CURRENCY_RISK_VIRTUAL_ID', lV2_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCV_RATE_OF_EXCHANGE', lV2_Rate);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCV_PCENT', lV2_PCent);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCV_AMOUNT', lV2_Amount);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCV_BALANCE', lV2_Balance);
          FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
          FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
          -- Appelé avant mise à jour de  GAL_CURRENCY_RISK  GAL_MGT_PROJECT.updateCURRENCY_RISK
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotCURRENCY_RISK, 'GAL_CURRENCY_RISK_VIRTUAL_ID', lV2_ID);
          -- mise à jour de l'historique des couvertures virtuelles valeurs modifiées
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_RATE_OF_EXCHANGE2', lV2_Rate / lV2_Base);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_PCENT2', lV2_PCent);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Virtual_Histo, 'GVH_AMOUNT2', lV2_Amount);
          FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_Virtual_Histo);
          FWK_I_MGT_ENTITY.Release(ltCRUD_Virtual_Histo);
          -- mise à jour de l'historique des couvertures  valeurs modifiées
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'ACS_FINANCIAL_CURRENCY2_ID', lR2_Curr);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'C_GAL_RISK_DOMAIN2', lR2_Domain);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'C_GAL_RISK_TYPE2', lR2_Type);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'GRH_RATE_OF_EXCHANGE2', lR2_Rate);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'GRH_PCENT2', lR2_PCent);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'GRH_AMOUNT2', lR2_Amount);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_Histo, 'GRH_PAYMENT_DATE2', lR2_Date);
          FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_Histo);
          FWK_I_MGT_ENTITY.Release(ltCRUD_Histo);
        end if;
      end if;
    end;
  begin
    -- Insertion de couverture
    -- R1 - Valeurs nulles
    -- R2 - Nouvelle couverture
    -- V1 - Tranche virtuelle si existante, sinon valeurs nulles
    -- V2 - Tranche virtuelle si existante, sinon valeurs de la nouvelle couverture
    --
    -- Modification de couverture
    -- R1 - Couverture valeurs avant modification
    -- R2 - Couverture valeurs après mofication
    -- V1 - Tranche virtuelle
    -- V2 - Tranche virtuelle
    --
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotCURRENCY_RISK, 'GAL_CURRENCY_RISK_ID') then
      lMessage  := lMessage || PCS.PC_FUNCTIONS.TranslateWord('Le champ doit avoir une valeur :') || ' "GAL_CURRENCY_RISK_ID"' || chr(10);
      SetFWErrorMessage(lMessage);
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckCURRENCY_RISK_VIRTUALData'
                                         );
    end if;

    if iotCURRENCY_RISK.update_mode <> fwk_i_typ_definition.inserting then
      begin
        -- recherche de la tranche virtuelle attaché à la tranche réelle avant mise à jour
        select GAL_CURRENCY_RISK_ID
             , A.ACS_FINANCIAL_CURRENCY_ID
             , A.C_GAL_RISK_DOMAIN
             , A.C_GAL_RISK_TYPE
             , A.GCK_PCENT
             , A.GCK_AMOUNT
             , A.GCK_BALANCE
             , A.GCK_RATE_OF_EXCHANGE
             , A.GCK_BASE_PRICE
             , A.GCK_PAYMENT_DATE
             , B.GAL_CURRENCY_RISK_VIRTUAL_ID
             , B.ACS_FINANCIAL_CURRENCY_ID
             , B.C_GAL_RISK_DOMAIN
             , B.C_GAL_RISK_TYPE
             , B.GCV_PCENT
             , B.GCV_AMOUNT
             , B.GCV_BALANCE
             , B.GCV_RATE_OF_EXCHANGE
             , B.GCV_BASE_PRICE
          into lR1_ID
             , lR1_Curr
             , lR1_Domain
             , lR1_Type
             , lR1_PCent
             , lR1_Amount
             , lR1_Balance
             , lR1_Rate
             , lR1_Base
             , lR1_Date
             , lV1_ID
             , lV1_Curr
             , lV1_Domain
             , lV1_Type
             , lV1_PCent
             , lV1_Amount
             , lV1_Balance
             , lV1_Rate
             , lV1_base
          from GAL_CURRENCY_RISK A
             , GAL_CURRENCY_RISK_VIRTUAL B
         where A.GAL_CURRENCY_RISK_ID = ltplCURRENCY_RISK.GAL_CURRENCY_RISK_ID
           and A.GAL_PROJECT_ID = B.GAL_PROJECT_ID
           and A.ACS_FINANCIAL_CURRENCY_ID = B.ACS_FINANCIAL_CURRENCY_ID
           and A.C_GAL_RISK_TYPE = B.C_GAL_RISK_TYPE
           and A.C_GAL_RISK_DOMAIN = B.C_GAL_RISK_DOMAIN;
      exception
        when no_data_found then
          select A.GAL_CURRENCY_RISK_ID
               , A.ACS_FINANCIAL_CURRENCY_ID
               , A.C_GAL_RISK_DOMAIN
               , A.C_GAL_RISK_TYPE
               , A.GCK_PCENT
               , A.GCK_AMOUNT
               , A.GCK_BALANCE
               , A.GCK_RATE_OF_EXCHANGE
               , A.GCK_BASE_PRICE
               , A.GCK_PAYMENT_DATE
            into lR1_ID
               , lR1_Curr
               , lR1_Domain
               , lR1_Type
               , lR1_PCent
               , lR1_Amount
               , lR1_Balance
               , lR1_Rate
               , lR1_Base
               , lR1_Date
            from GAL_CURRENCY_RISK A
               , GAL_CURRENCY_RISK_VIRTUAL B
           where A.GAL_CURRENCY_RISK_ID = ltplCURRENCY_RISK.GAL_CURRENCY_RISK_ID;

          lV1_ID       := null;
          lV1_Curr     := null;
          lV1_Domain   := null;
          lV1_Type     := null;
          lV1_PCent    := 0;
          lV1_Amount   := null;
          lV1_Balance  := null;
          lV1_Rate     := 1;
          lV1_base     := 1;
      end;
    else   -- insertion
      lR1_ID       := null;
      lR1_Curr     := null;
      lR1_Domain   := null;
      lR1_Type     := null;
      lR1_PCent    := 0;
      lR1_Amount   := null;
      lR1_Balance  := null;
      lR1_Rate     := 1;
      lR1_base     := 1;
      lR1_Date     := null;

      begin
        -- recherche de la tranche virtuelle attaché à la tranche réelle
        select GAL_CURRENCY_RISK_VIRTUAL_ID
             , ACS_FINANCIAL_CURRENCY_ID
             , C_GAL_RISK_DOMAIN
             , C_GAL_RISK_TYPE
             , GCV_PCENT
             , GCV_AMOUNT
             , GCV_BALANCE
             , GCV_RATE_OF_EXCHANGE
             , GCV_BASE_PRICE
          into lV1_ID
             , lV1_Curr
             , lV1_Domain
             , lV1_Type
             , lV1_PCent
             , lV1_Amount
             , lV1_Balance
             , lV1_Rate
             , lV1_Base
          from GAL_CURRENCY_RISK_VIRTUAL
         where GAL_PROJECT_ID = ltplCURRENCY_RISK.GAL_PROJECT_ID
           and ACS_FINANCIAL_CURRENCY_ID = ltplCURRENCY_RISK.ACS_FINANCIAL_CURRENCY_ID
           and C_GAL_RISK_TYPE = ltplCURRENCY_RISK.C_GAL_RISK_TYPE
           and C_GAL_RISK_DOMAIN = ltplCURRENCY_RISK.C_GAL_RISK_DOMAIN;
      exception
        when no_data_found then
          lV1_ID       := null;
          lV1_Curr     := null;
          lV1_Domain   := null;
          lV1_Type     := null;
          lV1_PCent    := 0;
          lV1_Amount   := null;
          lV1_Balance  := null;
          lV1_Rate     := 1;
          lV1_base     := 1;
      end;
    end if;

    if iotCURRENCY_RISK.update_mode <> fwk_i_typ_definition.deleting then
      lR2_ID       := ltplCURRENCY_RISK.GAL_CURRENCY_RISK_ID;
      lR2_Curr     := ltplCURRENCY_RISK.ACS_FINANCIAL_CURRENCY_ID;
      lR2_Domain   := ltplCURRENCY_RISK.C_GAL_RISK_DOMAIN;
      lR2_Type     := ltplCURRENCY_RISK.C_GAL_RISK_TYPE;
      lR2_PCent    := ltplCURRENCY_RISK.GCK_PCENT;
      lR2_Amount   := ltplCURRENCY_RISK.GCK_AMOUNT;
      lR2_Balance  := ltplCURRENCY_RISK.GCK_BALANCE;
      lR2_Rate     := ltplCURRENCY_RISK.GCK_RATE_OF_EXCHANGE;
      lR2_Base     := ltplCURRENCY_RISK.GCK_BASE_PRICE;
      lR2_Date     := ltplCURRENCY_RISK.GCK_PAYMENT_DATE;

      begin
        -- recherche de la tranche virtuelle attaché à la tranche réelle après mise à jour
        select GAL_CURRENCY_RISK_VIRTUAL_ID
             , ACS_FINANCIAL_CURRENCY_ID
             , C_GAL_RISK_DOMAIN
             , C_GAL_RISK_TYPE
             , GCV_PCENT
             , GCV_AMOUNT
             , GCV_BALANCE
             , GCV_RATE_OF_EXCHANGE
             , GCV_BASE_PRICE
          into lV2_ID
             , lV2_Curr
             , lV2_Domain
             , lV2_Type
             , lV2_PCent
             , lV2_Amount
             , lV2_Balance
             , lV2_Rate
             , lV2_Base
          from GAL_CURRENCY_RISK_VIRTUAL
         where GAL_PROJECT_ID = ltplCURRENCY_RISK.GAL_PROJECT_ID
           and ACS_FINANCIAL_CURRENCY_ID = ltplCURRENCY_RISK.ACS_FINANCIAL_CURRENCY_ID
           and C_GAL_RISK_TYPE = ltplCURRENCY_RISK.C_GAL_RISK_TYPE
           and C_GAL_RISK_DOMAIN = ltplCURRENCY_RISK.C_GAL_RISK_DOMAIN;
      exception
        when no_data_found then
          lV2_ID       := INIT_ID_SEQ.nextval;
          lV2_Curr     := ltplCURRENCY_RISK.ACS_FINANCIAL_CURRENCY_ID;
          lV2_Domain   := ltplCURRENCY_RISK.C_GAL_RISK_DOMAIN;
          lV2_Type     := ltplCURRENCY_RISK.C_GAL_RISK_TYPE;
          lV2_PCent    := ltplCURRENCY_RISK.GCK_PCENT;
          lV2_Amount   := null;
          lV2_Balance  := null;
          lV2_Rate     := ltplCURRENCY_RISK.GCK_RATE_OF_EXCHANGE;
          lV2_Base     := ltplCURRENCY_RISK.GCK_BASE_PRICE;
          -- Création couverture virtuelle
          FWK_I_MGT_ENTITY.new(FWK_I_TYP_GAL_ENTITY.gcGalCurrencyRiskVirtual, ltCRUD_DEF);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GAL_CURRENCY_RISK_VIRTUAL_ID', lV2_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GAL_PROJECT_ID', ltplCURRENCY_RISK.GAL_PROJECT_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_FINANCIAL_CURRENCY_ID', ltplCURRENCY_RISK.ACS_FINANCIAL_CURRENCY_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_GAL_RISK_TYPE', ltplCURRENCY_RISK.C_GAL_RISK_TYPE);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_GAL_RISK_DOMAIN', ltplCURRENCY_RISK.C_GAL_RISK_DOMAIN);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCV_RATE_OF_EXCHANGE', lV2_Rate);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCV_BASE_PRICE', lV2_Base);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCV_PCENT', lV2_PCent);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCV_AMOUNT', lV2_Amount);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCV_BALANCE', lV2_Balance);
          FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
          FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
      end;
    else   -- effacement
      lR2_ID       := null;
      lR2_Curr     := null;
      lR2_Domain   := null;
      lR2_Type     := null;
      lR2_ID       := null;
      lR2_PCent    := 0;
      lR2_Amount   := 0;
      lR2_Balance  := 0;
      lR2_Rate     := 1;
      lR2_base     := 1;
      lR2_Date     := null;
      lV2_ID       := null;
      lV2_Curr     := null;
      lV2_Domain   := null;
      lV2_Type     := null;
      lV2_PCent    := 0;
      lV2_Amount   := null;
      lV2_Balance  := null;
      lV2_Rate     := 1;
      lV2_base     := 1;
    end if;

    lListdoc  := null;

    for tplDocUsed in (select DMT_NUMBER
                         from DOC_DOCUMENT
                        where (   GAL_CURRENCY_RISK_VIRTUAL_ID = nvl(lV1_ID, 0)
                               or GAL_CURRENCY_RISK_VIRTUAL_ID = nvl(lV2_ID, 0) )
                          and DMT_PROTECTED = 1) loop
      if lListDoc is null then
        lListDoc  := tplDocUsed.DMT_NUMBER;
      else
        lListDoc  := lListDoc || ', ' || tplDocUsed.DMT_NUMBER;
      end if;
    end loop;

    if     (   iotCURRENCY_RISK.update_mode = fwk_i_typ_definition.inserting
            or iotCURRENCY_RISK.update_mode = fwk_i_typ_definition.deleting
            or (    iotCURRENCY_RISK.update_mode = fwk_i_typ_definition.updating
                and (   lR1_Amount <> lR2_Amount
                     or lR1_Balance <> lR2_Balance
                     or lR1_Rate <> lR2_Rate
                     or lR1_Base <> lR2_Base)
               )
           )
       and lListDoc is not null then
      SetMessage(lMessage, 'Documents en cours de saisie, mise à jour du taux pas autorisée');
      lMessage  := lMessage || lListDoc || chr(10);
    else
      -- mise à jour des couvertues virtuelles
      case iotCURRENCY_RISK.update_mode
        when fwk_i_typ_definition.updating then
          -- Changement de type de couverture
          --   Effacement de l'ancienne couverture virtuelle et
          --   création de la nouvelle couverture virtuelle
          if     (lV1_ID <> 0)
             and (lV1_ID <> lV2_ID) then
            UpdateVirtualOnDelete;

            if lMessage is null then
              UpdateVirtualOnInsert;
            end if;
          else
            UpdateVirtualOnUpdate;
          end if;
        when fwk_i_typ_definition.inserting then
          UpdateVirtualOnInsert;
        when fwk_i_typ_definition.deleting then
          UpdateVirtualOnDelete;
      end case;
    end if;

    if lMessage is not null then
      SetFWErrorMessage(lMessage);
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckCURRENCY_RISK_VIRTUALData'
                                         );
    end if;
  end CheckCURRENCY_RISK_VIRTUALData;

  /**
  * procedure CheckTASKData
  * Description
  *    Contrôle avant mise à jour d'un composant d'une tâche d'un projet
  * @author ECA
  * @created SEP.2011
  * @lastUpdate
  * @public
  * @param   iotTASK : projet
  */
  procedure CheckTASKData(iotTASK in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    ltplTASK                FWK_TYP_GAL_ENTITY.tTASK                          := FWK_TYP_GAL_ENTITY.gttTASK(iotTASK.entity_id);
    ltCRUD_DEF              FWK_I_TYP_DEFINITION.t_crud_def;
    lMessage                varchar2(1000);
    lCount                  number;
    lDOC_GAUGE_NUMBERING_ID DOC_GAUGE_NUMBERING.DOC_GAUGE_NUMBERING_ID%type;
  begin
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotTASK, 'GAL_TASK_ID') then
      lMessage  := lMessage || PCS.PC_FUNCTIONS.TranslateWord('Le champ doit avoir une valeur :') || ' "GAL_TASK_ID"' || chr(10);
    end if;

    -- Contrôle du code etat du projet
    if (ltplTASK.C_TAS_STATE = '40') then
      SetMessage(lMessage, 'Le code état de la tâche n''autorise pas cette action');
    end if;

    if lMessage is not null then
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckTASKData'
                                         );
    end if;

    if ltplTASK.C_TAS_STATE is null then
      ltplTASK.C_TAS_STATE  := '10';
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK, 'C_TAS_STATE', ltplTASK.C_TAS_STATE);
    end if;

    if ltplTASK.TAS_CODE is null then
      select DOC_GAUGE_NUMBERING_ID
        into lDOC_GAUGE_NUMBERING_ID
        from DOC_GAUGE_NUMBERING
       where GAN_DESCRIBE = pcs.pc_config.getconfig('GAL_NUMBERING_MANUFACTURE');

      if lDOC_GAUGE_NUMBERING_ID is not null then
        Doc_document_functions.GetDocumentNumber(null, lDOC_GAUGE_NUMBERING_ID, ltplTASK.TAS_CODE);
        ltplTASK.TAS_WORDING  := ltplTASK.TAS_CODE;
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK, 'TAS_CODE', ltplTASK.TAS_CODE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK, 'TAS_WORDING', ltplTASK.TAS_WORDING);
      end if;
    end if;

    if ltplTASK.TAS_TASK_PREPARED is null then
      ltplTASK.TAS_TASK_PREPARED  := 0;
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK, 'TAS_TASK_PREPARED', ltplTASK.TAS_TASK_PREPARED);
    end if;

    if     ltplTASK.GAL_BUDGET_ID is null
       and ltplTASK.GAL_FATHER_TASK_ID is not null then
      select GAL_PROJECT_ID
           , GAL_BUDGET_ID
           , GAL_TASK_CATEGORY_ID
        into ltplTASK.GAL_PROJECT_ID
           , ltplTASK.GAL_BUDGET_ID
           , ltplTASK.GAL_TASK_CATEGORY_ID
        from GAL_TASK
       where GAL_TASK_ID = ltplTASK.GAL_FATHER_TASK_ID;

      FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK, 'GAL_PROJECT_ID', ltplTASK.GAL_PROJECT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK, 'GAL_BUDGET_ID', ltplTASK.GAL_BUDGET_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK, 'GAL_TASK_CATEGORY_ID', ltplTASK.GAL_TASK_CATEGORY_ID);
    end if;

    -- initialisation valeurs par défaut
    if    FWK_I_MGT_ENTITY_DATA.IsModified(iotTASK, 'TAS_START_DATE')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotTASK, 'TAS_END_DATE') then
      if not(    (ltplTASK.TAS_END_DATE >= ltplTASK.TAS_START_DATE)
             or ltplTASK.TAS_END_DATE is null
             or ltplTASK.TAS_START_DATE is null) then
        SetMessage(lMessage, 'La date de début ne peut pas être supérieure à la date de fin !');
      end if;
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotTASK, 'TAS_CODE') then
      ltplTASK.TAS_CODE  := upper(ltplTASK.TAS_CODE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK, 'TAS_CODE', ltplTASK.TAS_CODE);
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotTASK, 'GAL_BUDGET_ID') then
      if ltplTASK.GAL_BUDGET_ID is not null then
        select count(*)
          into lCount
          from GAL_BUDGET_CATEGORY
             , GAL_BUDGET
         where (   GAL_BUDGET_CATEGORY.ACS_FINANCIAL_ACCOUNT_ID is not null
                or GAL_BUDGET_CATEGORY.ACS_DIVISION_ACCOUNT_ID is not null
                or GAL_BUDGET_CATEGORY.ACS_CPN_ACCOUNT_ID is not null
                or GAL_BUDGET_CATEGORY.ACS_CDA_ACCOUNT_ID is not null
                or GAL_BUDGET_CATEGORY.ACS_PF_ACCOUNT_ID is not null
                or GAL_BUDGET_CATEGORY.ACS_PJ_ACCOUNT_ID is not null
               )
           and GAL_BUDGET_CATEGORY.GAL_BUDGET_CATEGORY_ID = GAL_BUDGET.GAL_BUDGET_CATEGORY_ID
           and GAL_BUDGET.GAL_BUDGET_ID = ltplTASK.GAL_BUDGET_ID;

        if lCount > 0 then
          SetMessage(lMessage, 'Ce code budget est lié à des données finanières (Catégorie de budget)');
        end if;

        if (lMessage is null) then
          -- Mise à jour du code budget des dossiers de fabrication
          for tplChild in (select GAL_TASK_ID
                             from GAL_TASK
                            where GAL_FATHER_TASK_ID = ltplTASK.GAL_TASK_ID) loop
            FWK_I_MGT_ENTITY.new(FWK_I_TYP_GAL_ENTITY.gcGalTask, ltCRUD_DEF);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GAL_TASK_ID', tplChild.GAL_TASK_ID);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GAL_BUDGET_ID', ltplTASK.GAL_BUDGET_ID);
            FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
            FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
          end loop;
        end if;
      end if;
    end if;

    if lMessage is not null then
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckTASKData'
                                         );
    end if;
  end CheckTASKData;

  /**
  * procedure CheckTASK_LOTData
  * Description
  *    Contrôle avant mise à jour d'un lot d'une tâche d'un projet
  * @author ECA
  * @created SEP.2011
  * @lastUpdate
  * @public
  * @param   iotTASK_LOT : projet
  */
  procedure CheckTASK_LOTData(iotTASK_LOT in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    ltplTASK_LOT     FWK_TYP_GAL_ENTITY.tTaskLot         := FWK_TYP_GAL_ENTITY.gttTaskLot(iotTASK_LOT.entity_id);
    lMessage         varchar2(1000);
    lDTL_DESCRIPTION GAL_TASK_LOT.DTL_DESCRIPTION%type;
  begin
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotTASK_LOT, 'GAL_TASK_LOT_ID') then
      lMessage  := lMessage || PCS.PC_FUNCTIONS.TranslateWord('Le champ doit avoir une valeur :') || ' "GAL_TASK_LOT_ID"' || chr(10);
    end if;

    if ltplTASK_LOT.GTL_SEQUENCE is null then
      select nvl(max(GTL_SEQUENCE), 0) + 10
        into ltplTASK_LOT.GTL_SEQUENCE
        from GAL_TASK_LOT
       where GAL_TASK_ID = ltplTASK_LOT.GAL_TASK_ID;

      FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LOT, 'GTL_SEQUENCE', ltplTASK_LOT.GTL_SEQUENCE);
    end if;

    if ltplTASK_LOT.GTL_QUANTITY is null then
      ltplTASK_LOT.GTL_QUANTITY  := 1;
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LOT, 'GTL_QUANTITY', ltplTASK_LOT.GTL_QUANTITY);
    end if;

    if ltplTASK_LOT.DTL_DESCRIPTION is null then
      begin
        select trim(substr(DES_LONG_DESCRIPTION, 1, 30) )
          into lDTL_DESCRIPTION
          from GCO_DESCRIPTION
         where PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId
           and GCO_GOOD_ID = ltplTASK_LOT.GCO_GOOD_ID
           and C_DESCRIPTION_TYPE = '01';

        ltplTASK_LOT.DTL_DESCRIPTION  := lDTL_DESCRIPTION;
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LOT, 'DTL_DESCRIPTION', ltplTASK_LOT.DTL_DESCRIPTION);
      exception
        when no_data_found then
          null;
      end;
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotTASK_LOT, 'GCO_GOOD_ID') then
      begin
        select trim(rpad(CMA_PLAN_NUMBER, 60) )
             , trim(rpad(CMA_PLAN_VERSION, 60) )
          into ltplTASK_LOT.GTL_PLAN_NUMBER
             , ltplTASK_LOT.GTL_PLAN_VERSION
          from GCO_COMPL_DATA_MANUFACTURE
         where CMA_DEFAULT = 1
           and GCO_GOOD_ID = ltplTASK_LOT.GCO_GOOD_ID;
      exception
        when no_data_found then
          ltplTASK_LOT.GTL_PLAN_NUMBER   := null;
          ltplTASK_LOT.GTL_PLAN_VERSION  := null;
      end;

      FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LOT, 'GTL_PLAN_NUMBER', ltplTASK_LOT.GTL_PLAN_NUMBER);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LOT, 'GTL_PLAN_VERSION', ltplTASK_LOT.GTL_PLAN_VERSION);
    end if;

    if lMessage is not null then
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckTASK_LOTData'
                                         );
    end if;
  end CheckTASK_LOTData;

  /**
  * procedure CheckTASK_GOODData
  * Description
  *    Contrôle avant mise à jour d'un composant d'une tâche d'un projet
  * @author ECA
  * @created SEP.2011
  * @lastUpdate
  * @public
  * @param   iotTASK_GOOD : projet
  */
  procedure CheckTASK_GOODData(iotTASK_GOOD in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    ltplTASK_GOOD          FWK_TYP_GAL_ENTITY.tTaskGood               := FWK_TYP_GAL_ENTITY.gttTaskGood(iotTASK_GOOD.entity_id);
    lMessage               varchar2(1000);
    lCount                 number;
    lGCO_GOOD_ID           GAL_TASK_GOOD.GCO_GOOD_ID%type;
    lPPS_NOMENCLATURE_ID   GAL_TASK_GOOD.PPS_NOMENCLATURE_ID%type;
    lggo_supply_mode       V_GAL_PCS_GOOD.ggo_supply_mode%type;
    lggo_supply_type       V_GAL_PCS_GOOD.ggo_supply_type%type;
    lC_PROJECT_SUPPLY_MODE GAL_TASK_GOOD.C_PROJECT_SUPPLY_MODE%type;
    lNOM_VERSION           PPS_NOMENCLATURE.NOM_VERSION%type;
  begin
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotTASK_GOOD, 'GAL_TASK_GOOD_ID') then
      lMessage  := lMessage || PCS.PC_FUNCTIONS.TranslateWord('Le champ doit avoir une valeur :') || ' "GAL_TASK_GOOD_ID"' || chr(10);
    end if;

    if lMessage is not null then
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckTASK_GOODData'
                                         );
    end if;

    -- initialisation valeurs par défaut
    if ltplTASK_GOOD.C_PROJECT_SUPPLY_MODE is null then
      ltplTASK_GOOD.C_PROJECT_SUPPLY_MODE  := '2';
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_GOOD, 'C_PROJECT_SUPPLY_MODE', ltplTASK_GOOD.C_PROJECT_SUPPLY_MODE);
    end if;

    if ltplTASK_GOOD.GML_SEQUENCE is null then
      select nvl(max(GML_SEQUENCE), 0) + 10
        into ltplTASK_GOOD.GML_SEQUENCE
        from GAL_TASK_GOOD
       where GAL_TASK_ID = ltplTASK_GOOD.GAL_TASK_ID;

      FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_GOOD, 'GML_SEQUENCE', ltplTASK_GOOD.GML_SEQUENCE);
    end if;

    if ltplTASK_GOOD.GML_DESCRIPTION is null then
      select trim(DES_LONG_DESCRIPTION)
        into ltplTASK_GOOD.GML_DESCRIPTION
        from GCO_DESCRIPTION
       where PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId
         and C_DESCRIPTION_TYPE = '01'
         and GCO_GOOD_ID = ltplTASK_GOOD.GCO_GOOD_ID;

      FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_GOOD, 'GML_DESCRIPTION', ltplTASK_GOOD.GML_DESCRIPTION);
    end if;

    if ltplTASK_GOOD.GML_QUANTITY is null then
      ltplTASK_GOOD.GML_QUANTITY  := 1;
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_GOOD, 'GML_QUANTITY', ltplTASK_GOOD.GML_QUANTITY);
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotTASK_GOOD, 'PPS_NOMENCLATURE_ID') then
      if ltplTASK_GOOD.PPS_NOMENCLATURE_ID is not null then
        select GCO_GOOD_ID
             , NOM_VERSION
          into lGCO_GOOD_ID
             , lNOM_VERSION
          from PPS_NOMENCLATURE
         where PPS_NOMENCLATURE_ID = ltplTASK_GOOD.PPS_NOMENCLATURE_ID;

        ltplTASK_GOOD.GCO_GOOD_ID  := lGCO_GOOD_ID;
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_GOOD, 'GCO_GOOD_ID', ltplTASK_GOOD.GCO_GOOD_ID);
      end if;
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotTASK_GOOD, 'GCO_GOOD_ID') then
      if ltplTASK_GOOD.PPS_NOMENCLATURE_ID is not null then
        select nvl(max(GCO_GOOD_ID), 0)
          into lGCO_GOOD_ID
          from PPS_NOMENCLATURE
         where PPS_NOMENCLATURE_ID = ltplTASK_GOOD.PPS_NOMENCLATURE_ID;

        if lGCO_GOOD_ID <> 0 then
          ltplTASK_GOOD.GCO_GOOD_ID  := lGCO_GOOD_ID;
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_GOOD, 'GCO_GOOD_ID', ltplTASK_GOOD.GCO_GOOD_ID);
        end if;
      else
        select max(PPS_NOMENCLATURE_ID)
          into ltplTASK_GOOD.PPS_NOMENCLATURE_ID
          from PPS_NOMENCLATURE
         where GCO_GOOD_ID = ltplTASK_GOOD.GCO_GOOD_ID
           and NOM_DEFAULT = 1;

        if ltplTASK_GOOD.PPS_NOMENCLATURE_ID is not null then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_GOOD, 'PPS_NOMENCLATURE_ID', ltplTASK_GOOD.PPS_NOMENCLATURE_ID);
        end if;
      end if;

      select gal_project_calculation.GetDeftSupplyMode(ggo_supply_type, ggo_supply_mode)
        into lC_PROJECT_SUPPLY_MODE
        from v_gal_pcs_good
       where gal_good_id = ltplTASK_GOOD.GCO_GOOD_ID;

      ltplTASK_GOOD.C_PROJECT_SUPPLY_MODE  := lC_PROJECT_SUPPLY_MODE;
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_GOOD, 'C_PROJECT_SUPPLY_MODE', ltplTASK_GOOD.C_PROJECT_SUPPLY_MODE);

      begin
        select trim(rpad(CMA_PLAN_NUMBER, 60) )
             , trim(rpad(CMA_PLAN_VERSION, 60) )
          into ltplTASK_GOOD.GML_PLAN_NUMBER
             , ltplTASK_GOOD.GML_PLAN_VERSION
          from GCO_COMPL_DATA_MANUFACTURE
         where CMA_DEFAULT = 1
           and GCO_GOOD_ID = ltplTASK_GOOD.GCO_GOOD_ID;
      exception
        when no_data_found then
          ltplTASK_GOOD.GML_PLAN_NUMBER   := null;
          ltplTASK_GOOD.GML_PLAN_VERSION  := null;
      end;

      FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_GOOD, 'GML_PLAN_NUMBER', ltplTASK_GOOD.GML_PLAN_NUMBER);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_GOOD, 'GML_PLAN_VERSION', ltplTASK_GOOD.GML_PLAN_VERSION);
    end if;

    if    (    FWK_I_MGT_ENTITY_DATA.IsModified(iotTASK_GOOD, 'GML_QUANTITY')
           and (ltplTASK_GOOD.GML_QUANTITY <> 0) )
       or (    FWK_I_MGT_ENTITY_DATA.IsModified(iotTASK_GOOD, 'GML_SEQUENCE')
           and (ltplTASK_GOOD.GML_SEQUENCE <> 0) ) then
      select count(*)
        into lCount
        from GAL_TASK
           , PPS_NOM_TRACABILITY
       where GAL_TASK.GAL_TASK_ID = ltplTASK_GOOD.GAL_TASK_ID
         and GAL_TASK.DOC_RECORD_ID = PPS_NOM_TRACABILITY.DOC_RECORD_ID
         and PPS_NOM_TRACABILITY.PPS_NOMENCLATURE_ID = ltplTASK_GOOD.PPS_NOMENCLATURE_ID;

      if lCount > 0 then
        SetMessage(lMessage, 'Impossible de modifier la quantité : Existence d''une traçabilité');
      end if;
    end if;

    if lMessage is not null then
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckTASK_GOODData'
                                         );
    end if;
  end CheckTASK_GOODData;

  /**
  * procedure CheckTASK_LINKData
  * Description
  *    Contrôle avant mise à jour d'un composant d'une tâche d'un projet
  * @author ECA
  * @created SEP.2011
  * @lastUpdate
  * @public
  * @param   iotTASK_LINK : projet
  */
  procedure CheckTASK_LINKData(iotTASK_LINK in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    ltplTASK_LINK             FWK_TYP_GAL_ENTITY.tTaskLink                      := FWK_TYP_GAL_ENTITY.gttTaskLink(iotTASK_LINK.entity_id);
    lMessage                  varchar2(1000);
    lCount                    number;
    lC_TAS_STATE              GAL_TASK.C_TAS_STATE%type;
    lTAS_START_DATE           GAL_TASK.TAS_START_DATE%type;
    lTAS_END_DATE             GAL_TASK.TAS_END_DATE%type;
    lC_TCA_PLANIFICATION_MODE GAL_TASK_CATEGORY.C_TCA_PLANIFICATION_MODE%type;
    lGAL_FATHER_TASK_ID       GAL_TASK.GAL_FATHER_TASK_ID%type;
    lTAL_HOURLY_RATE          GAL_TASK_LINK.TAL_HOURLY_RATE%type;
  begin
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotTASK_LINK, 'GAL_TASK_LINK_ID') then
      lMessage  := lMessage || PCS.PC_FUNCTIONS.TranslateWord('Le champ doit avoir une valeur :') || ' "GAL_TASK_LINK_ID"' || chr(10);
    end if;

    if lMessage is not null then
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckTASK_LINKData'
                                         );
    end if;

    begin
      select GAL_TASK.C_TAS_STATE
           , GAL_TASK.TAS_START_DATE
           , GAL_TASK.TAS_END_DATE
           , GAL_TASK_CATEGORY.C_TCA_PLANIFICATION_MODE
           , GAL_TASK.GAL_FATHER_TASK_ID
        into lC_TAS_STATE
           , lTAS_START_DATE
           , lTAS_END_DATE
           , lC_TCA_PLANIFICATION_MODE
           , lGAL_FATHER_TASK_ID
        from GAL_TASK
           , GAL_TASK_CATEGORY
       where GAL_TASK_ID = ltplTASK_LINK.GAL_TASK_ID
         and GAL_TASK.GAL_TASK_CATEGORY_ID = GAL_TASK_CATEGORY.GAL_TASK_CATEGORY_ID;
    exception
      when no_data_found then
        lC_TAS_STATE               := '10';
        lC_TCA_PLANIFICATION_MODE  := '1';
        lTAS_START_DATE            := sysdate;
        lTAS_END_DATE              := null;
        lGAL_FATHER_TASK_ID        := null;
    end;

    -- initialisation valeurs par défaut
    if ltplTASK_LINK.SCS_STEP_NUMBER is null then
      select nvl(max(SCS_STEP_NUMBER), 0) + pcs.pc_config.getconfig('PPS_Task_NUMBERING')
        into ltplTASK_LINK.SCS_STEP_NUMBER
        from GAL_TASK_LINK
       where GAL_TASK_ID = ltplTASK_LINK.GAL_TASK_ID;

      FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'SCS_STEP_NUMBER', ltplTASK_LINK.SCS_STEP_NUMBER);
    end if;

    if    ltplTASK_LINK.C_TAL_STATE is null
       or ltplTASK_LINK.TAL_BEGIN_PLAN_DATE is null
       or ltplTASK_LINK.TAL_END_PLAN_DATE is null then
      if ltplTASK_LINK.C_TAL_STATE is null then
        -- Initialisation du code état opération selon le code état de la tâche
        if lC_TAS_STATE = '10' then
          ltplTASK_LINK.C_TAL_STATE  := '10';
        elsif    (lC_TAS_STATE = '20')
              or (lC_TAS_STATE = '30') then
          ltplTASK_LINK.C_TAL_STATE  := '20';
        elsif lC_TAS_STATE = '99' then
          ltplTASK_LINK.C_TAL_STATE  := '99';
        end if;

        FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'C_TAL_STATE', ltplTASK_LINK.C_TAL_STATE);
      end if;

      if ltplTASK_LINK.C_TASK_TYPE is null then
        ltplTASK_LINK.C_TASK_TYPE  := '1';
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'C_TASK_TYPE', ltplTASK_LINK.C_TASK_TYPE);
      elsif FWK_I_MGT_ENTITY_DATA.IsModified(iotTASK_LINK, 'C_TASK_TYPE') then
        select count(*)
          into lCount
          from GAL_HOURS
         where GAL_TASK_LINK_ID = ltplTASK_LINK.GAL_TASK_LINK_ID;

        if lCount > 0 then
          SetMessage(lMessage, 'Pointages d''heures existants pour cette opération');
        end if;
      end if;

      if     (ltplTASK_LINK.C_TASK_TYPE = '1')
         and (ltplTASK_LINK.FAL_FACTORY_FLOOR_ID = 0) then
        SetMessage(lMessage, 'La ressource n°1 est obligatoire pour une opération interne.');
      elsif     (lGAL_FATHER_TASK_ID <> 0)
            and (ltplTASK_LINK.C_TASK_TYPE = '2')
            and (    (ltplTASK_LINK.GCO_GCO_GOOD_ID is null)
                 or (ltplTASK_LINK.PAC_SUPPLIER_PARTNER_ID is null) ) then
        SetMessage(lMessage, 'Bien connecté et Fournisseur obligatoire pour une opération externe.');
      end if;

      -- Initialisation des dates d'opération selon les dates de la tâche
      -- uniquement si la catégorie de tâche a le mode de planification 1 (= dates de tâche)
      if lC_TCA_PLANIFICATION_MODE = '1' then
        if     ltplTASK_LINK.TAL_BEGIN_PLAN_DATE is null
           and lTAS_START_DATE is not null then
          ltplTASK_LINK.TAL_BEGIN_PLAN_DATE  := lTAS_START_DATE;
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'TAL_BEGIN_PLAN_DATE', ltplTASK_LINK.TAL_BEGIN_PLAN_DATE);
        end if;

        if     ltplTASK_LINK.TAL_END_PLAN_DATE is null
           and lTAS_END_DATE is not null then
          ltplTASK_LINK.TAL_END_PLAN_DATE  := lTAS_END_DATE;
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'TAL_END_PLAN_DATE', ltplTASK_LINK.TAL_END_PLAN_DATE);
        end if;
      end if;
    end if;

    if     ltplTASK_LINK.TAL_TSK_BALANCE is null
       and ltplTASK_LINK.TAL_DUE_TSK is not null then
      ltplTASK_LINK.TAL_TSK_BALANCE  := ltplTASK_LINK.TAL_DUE_TSK;
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'TAL_TSK_BALANCE', ltplTASK_LINK.TAL_TSK_BALANCE);
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotTASK_LINK, 'FAL_TASK_ID') then
      for tplTask in (select *
                        from FAL_TASK
                       where FAL_TASK_ID = ltplTASK_LINK.FAL_TASK_ID) loop
        if    lGAL_FATHER_TASK_ID <> 0
           or tplTask.C_TASK_TYPE <> '2' then
          ltplTASK_LINK.SCS_FREE_DESCR                  := tplTASK.TAS_FREE_DESCR;
          ltplTASK_LINK.SCS_LONG_DESCR                  := tplTASK.TAS_LONG_DESCR;
          ltplTASK_LINK.SCS_SHORT_DESCR                 := tplTASK.TAS_SHORT_DESCR;
          ltplTASK_LINK.PPS_OPERATION_PROCEDURE_ID      := tplTASK.PPS_OPERATION_PROCEDURE_ID;
          ltplTASK_LINK.PPS_PPS_OPERATION_PROCEDURE_ID  := tplTASK.PPS_PPS_OPERATION_PROCEDURE_ID;
          ltplTASK_LINK.PPS_TOOLS1_ID                   := tplTASK.PPS_TOOLS1_ID;
          ltplTASK_LINK.PPS_TOOLS2_ID                   := tplTASK.PPS_TOOLS2_ID;
          ltplTASK_LINK.FAL_FACTORY_FLOOR_ID            := tplTASK.FAL_FACTORY_FLOOR_ID;
          ltplTASK_LINK.C_TASK_TYPE                     := tplTASK.C_TASK_TYPE;
          ltplTASK_LINK.PAC_SUPPLIER_PARTNER_ID         := tplTASK.PAC_SUPPLIER_PARTNER_ID;
          ltplTASK_LINK.GCO_GCO_GOOD_ID                 := tplTASK.GCO_GCO_GOOD_ID;
          ltplTASK_LINK.DIC_FREE_TASK_CODE_ID           := tplTASK.DIC_FREE_TASK_CODE_ID;
          ltplTASK_LINK.DIC_FREE_TASK_CODE2_ID          := tplTASK.DIC_FREE_TASK_CODE2_ID;
          ltplTASK_LINK.DIC_FREE_TASK_CODE3_ID          := tplTASK.DIC_FREE_TASK_CODE3_ID;
          ltplTASK_LINK.DIC_FREE_TASK_CODE4_ID          := tplTASK.DIC_FREE_TASK_CODE4_ID;
          ltplTASK_LINK.DIC_FREE_TASK_CODE5_ID          := tplTASK.DIC_FREE_TASK_CODE5_ID;
          ltplTASK_LINK.DIC_FREE_TASK_CODE6_ID          := tplTASK.DIC_FREE_TASK_CODE6_ID;
          ltplTASK_LINK.DIC_FREE_TASK_CODE7_ID          := tplTASK.DIC_FREE_TASK_CODE7_ID;
          ltplTASK_LINK.DIC_FREE_TASK_CODE8_ID          := tplTASK.DIC_FREE_TASK_CODE8_ID;
          ltplTASK_LINK.DIC_FREE_TASK_CODE9_ID          := tplTASK.DIC_FREE_TASK_CODE9_ID;
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'SCS_FREE_DESCR', tplTASK.TAS_FREE_DESCR);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'SCS_LONG_DESCR', tplTASK.TAS_LONG_DESCR);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'SCS_SHORT_DESCR', tplTASK.TAS_SHORT_DESCR);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'PPS_OPERATION_PROCEDURE_ID', ltplTASK_LINK.PPS_OPERATION_PROCEDURE_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'PPS_PPS_OPERATION_PROCEDURE_ID', ltplTASK_LINK.PPS_PPS_OPERATION_PROCEDURE_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'PPS_TOOLS1_ID', ltplTASK_LINK.PPS_TOOLS1_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'PPS_TOOLS2_ID', ltplTASK_LINK.PPS_TOOLS2_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'FAL_FACTORY_FLOOR_ID', ltplTASK_LINK.FAL_FACTORY_FLOOR_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'C_TASK_TYPE', ltplTASK_LINK.C_TASK_TYPE);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'PAC_SUPPLIER_PARTNER_ID', ltplTASK_LINK.PAC_SUPPLIER_PARTNER_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'GCO_GCO_GOOD_ID', ltplTASK_LINK.GCO_GCO_GOOD_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'DIC_FREE_TASK_CODE_ID', ltplTASK_LINK.DIC_FREE_TASK_CODE_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'DIC_FREE_TASK_CODE2_ID', ltplTASK_LINK.DIC_FREE_TASK_CODE2_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'DIC_FREE_TASK_CODE3_ID', ltplTASK_LINK.DIC_FREE_TASK_CODE3_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'DIC_FREE_TASK_CODE4_ID', ltplTASK_LINK.DIC_FREE_TASK_CODE4_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'DIC_FREE_TASK_CODE5_ID', ltplTASK_LINK.DIC_FREE_TASK_CODE5_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'DIC_FREE_TASK_CODE6_ID', ltplTASK_LINK.DIC_FREE_TASK_CODE6_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'DIC_FREE_TASK_CODE7_ID', ltplTASK_LINK.DIC_FREE_TASK_CODE7_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'DIC_FREE_TASK_CODE8_ID', ltplTASK_LINK.DIC_FREE_TASK_CODE8_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'DIC_FREE_TASK_CODE9_ID', ltplTASK_LINK.DIC_FREE_TASK_CODE9_ID);
        end if;
      end loop;
    end if;

    if    FWK_I_MGT_ENTITY_DATA.IsModified(iotTASK_LINK, 'TAL_BEGIN_PLAN_DATE')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotTASK_LINK, 'TAL_END_PLAN_DATE') then
      if not(    (ltplTASK_LINK.TAL_END_PLAN_DATE >= ltplTASK_LINK.TAL_BEGIN_PLAN_DATE)
             or ltplTASK_LINK.TAL_END_PLAN_DATE is null
             or ltplTASK_LINK.TAL_BEGIN_PLAN_DATE is null
            ) then
        SetMessage(lMessage, 'La date de début ne peut pas être supérieure à la date de fin !');
      end if;

      if not ltplTASK_LINK.TAL_BEGIN_PLAN_DATE is null then
        select TAS_START_DATE
             , TAS_END_DATE
          into lTAS_START_DATE
             , lTAS_END_DATE
          from GAL_TASK
         where GAL_TASK_ID = ltplTASK_LINK.GAL_TASK_ID;

        if     lTAS_START_DATE is not null
           and ltplTASK_LINK.TAL_BEGIN_PLAN_DATE < lTAS_START_DATE then
          SetMessage(lMessage, 'La date de début ne peut pas être antérieure à la date de début de tâche');
        end if;

        if     lTAS_END_DATE is not null
           and ltplTASK_LINK.TAL_END_PLAN_DATE > lTAS_END_DATE then
          SetMessage(lMessage, 'La date de fin ne peut pas être supérieure à la date de fin de tâche');
        end if;
      end if;
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotTASK_LINK, 'TAL_DUE_TSK') then
      if nvl(ltplTASK_LINK.TAL_DUE_TSK, 0) - nvl(ltplTASK_LINK.TAL_ACHIEVED_TSK, 0) < 0 then
        ltplTASK_LINK.TAL_TSK_BALANCE  := 0;
      else
        ltplTASK_LINK.TAL_TSK_BALANCE  := ltplTASK_LINK.TAL_DUE_TSK - nvl(ltplTASK_LINK.TAL_ACHIEVED_TSK, 0);
      end if;

      FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'TAL_TSK_BALANCE', ltplTASK_LINK.TAL_TSK_BALANCE);
    end if;

    if    FWK_I_MGT_ENTITY_DATA.IsModified(iotTASK_LINK, 'FAL_FACTORY_FLOOR_ID')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotTASK_LINK, 'FAL_FAL_FACTORY_FLOOR_ID') then
      select GAL_PROJECT_SPENDING.GET_HOURLY_RATE_FROM_RESS_OPE(0
                                                              , ltplTASK_LINK.FAL_FACTORY_FLOOR_ID
                                                              , ltplTASK_LINK.FAL_FAL_FACTORY_FLOOR_ID
                                                              , ltplTASK_LINK.GAL_TASK_ID
                                                              , sysdate
                                                               )
        into lTAL_HOURLY_RATE
        from dual;

      ltplTASK_LINK.TAL_HOURLY_RATE  := lTAL_HOURLY_RATE;
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotTASK_LINK, 'TAL_HOURLY_RATE', ltplTASK_LINK.TAL_HOURLY_RATE);
    end if;

    if lMessage is not null then
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckTASK_LINKData'
                                         );
    end if;
  end CheckTASK_LINKData;

/**
  * procedure CheckBUDGET_LINEData
  * Description
  *    Contrôle avant mise à jour d'une ligne de budget d'un budget d'un projet
  * @author ECA
  * @created SEP.2011
  * @lastUpdate
  * @public
  * @param   iotTASK_LINK : projet
  */
  procedure CheckBUDGET_LINEData(iotBUDGET_LINE in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    ltplBUDGET_LINE    FWK_TYP_GAL_ENTITY.tBudgetLine := FWK_TYP_GAL_ENTITY.gttBudgetLine(iotBUDGET_LINE.entity_id);
    lMessage           varchar2(1000);
    lCount             number;
    lTodayHourlyRate   number;
    lInitialHourlyRate number;

    procedure TauxHoraireDeCentreDeFrais
    is
      lnProjectID GAL_PROJECT.GAL_PROJECT_ID%type;
    begin
      -- Rechercher l'id de l'affaire, utilisé pour la rechercher des taux horaires
      select max(GAL_PROJECT_ID)
        into lnProjectID
        from GAL_BUDGET
       where GAL_BUDGET_ID = ltplBUDGET_LINE.GAL_BUDGET_ID;

      lTodayHourlyRate    := GAL_PROJECT_SPENDING.GET_HOURLY_RATE_FROM_NAT_ANA(ltplBUDGET_LINE.GAL_COST_CENTER_ID, sysdate, '00', lnProjectID);
      lInitialHourlyRate  := 0;

      if ltplBUDGET_LINE.BLI_LAST_REMAINING_DATE is not null then
        lInitialHourlyRate  :=
              GAL_PROJECT_SPENDING.GET_HOURLY_RATE_FROM_NAT_ANA(ltplBUDGET_LINE.GAL_COST_CENTER_ID, ltplBUDGET_LINE.BLI_LAST_REMAINING_DATE, '00', lnProjectID);
      end if;
    end;

    procedure CalculMontantBudget(aQteUpdated in boolean)
    is
    begin
      if     (ltplBUDGET_LINE.BLI_BUDGET_QUANTITY is not null)
         and (ltplBUDGET_LINE.BLI_BUDGET_QUANTITY = 0)
         and (ltplBUDGET_LINE.BLI_BUDGET_PRICE = 0) then
        ltplBUDGET_LINE.BLI_BUDGET_AMOUNT  := 0;
      elsif     aQteUpdated = true
            and (ltplBUDGET_LINE.BLI_BUDGET_QUANTITY = 0) then
        ltplBUDGET_LINE.BLI_BUDGET_AMOUNT  := 0;
      elsif     (ltplBUDGET_LINE.BLI_BUDGET_PRICE is not null)
            and (ltplBUDGET_LINE.BLI_BUDGET_PRICE = 0) then
        ltplBUDGET_LINE.BLI_BUDGET_AMOUNT  := 0;
      elsif     (ltplBUDGET_LINE.BLI_BUDGET_QUANTITY <> 0)
            and (ltplBUDGET_LINE.BLI_BUDGET_PRICE <> 0) then
        ltplBUDGET_LINE.BLI_BUDGET_AMOUNT  := ltplBUDGET_LINE.BLI_BUDGET_QUANTITY * ltplBUDGET_LINE.BLI_BUDGET_PRICE;
      end if;

      FWK_I_MGT_ENTITY_DATA.SetColumn(iotBUDGET_LINE, 'BLI_BUDGET_AMOUNT', ltplBUDGET_LINE.BLI_BUDGET_AMOUNT);
    end;

    procedure CalculQuantiteBudget(aAmountUpdated boolean)
    is
    begin
      if     (ltplBUDGET_LINE.BLI_BUDGET_AMOUNT = 0)
         and (ltplBUDGET_LINE.BLI_BUDGET_PRICE <> 0) then
        ltplBUDGET_LINE.BLI_BUDGET_QUANTITY  := 0;
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotBUDGET_LINE, 'BLI_BUDGET_QUANTITY', ltplBUDGET_LINE.BLI_BUDGET_QUANTITY);
      elsif     aAmountUpdated = true
            and (ltplBUDGET_LINE.BLI_BUDGET_PRICE = 0)
            and (ltplBUDGET_LINE.BLI_BUDGET_AMOUNT = 0) then
        ltplBUDGET_LINE.BLI_BUDGET_QUANTITY  := 1;
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotBUDGET_LINE, 'BLI_BUDGET_QUANTITY', ltplBUDGET_LINE.BLI_BUDGET_QUANTITY);
      elsif     (ltplBUDGET_LINE.BLI_BUDGET_AMOUNT <> 0)
            and (ltplBUDGET_LINE.BLI_BUDGET_PRICE = 0)
            and (ltplBUDGET_LINE.BLI_BUDGET_QUANTITY <> 0) then
        ltplBUDGET_LINE.BLI_BUDGET_PRICE  := ltplBUDGET_LINE.BLI_BUDGET_AMOUNT / ltplBUDGET_LINE.BLI_BUDGET_QUANTITY;
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotBUDGET_LINE, 'BLI_BUDGET_PRICE', ltplBUDGET_LINE.BLI_BUDGET_PRICE);
      elsif     (ltplBUDGET_LINE.BLI_BUDGET_AMOUNT <> 0)
            and (ltplBUDGET_LINE.BLI_BUDGET_PRICE <> 0) then
        ltplBUDGET_LINE.BLI_BUDGET_QUANTITY  := ltplBUDGET_LINE.BLI_BUDGET_AMOUNT / ltplBUDGET_LINE.BLI_BUDGET_PRICE;
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotBUDGET_LINE, 'BLI_BUDGET_QUANTITY', ltplBUDGET_LINE.BLI_BUDGET_QUANTITY);
      end if;
    end;

    procedure MiseAjourDateBudget
    is
    begin
      ltplBUDGET_LINE.BLI_LAST_BUDGET_DATE  := sysdate;
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotBUDGET_LINE, 'BLI_LAST_BUDGET_DATE', ltplBUDGET_LINE.BLI_LAST_BUDGET_DATE);
    end;

    procedure MiseAjourQuantiteFigeBudget
    is
    begin
      ltplBUDGET_LINE.BLI_LAST_ESTIMATION_QUANTITY  := ltplBUDGET_LINE.BLI_BUDGET_QUANTITY;
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotBUDGET_LINE, 'BLI_LAST_ESTIMATION_QUANTITY', ltplBUDGET_LINE.BLI_LAST_ESTIMATION_QUANTITY);
    end;

    procedure MiseAjourMontantFigeBudget
    is
    begin
      ltplBUDGET_LINE.BLI_LAST_ESTIMATION_AMOUNT  := ltplBUDGET_LINE.BLI_BUDGET_AMOUNT;
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotBUDGET_LINE, 'BLI_LAST_ESTIMATION_AMOUNT', ltplBUDGET_LINE.BLI_LAST_ESTIMATION_AMOUNT);
    end;

    procedure CalculMontantReste(aQteUpdated in boolean)
    is
    begin
      if     (ltplBUDGET_LINE.BLI_REMAINING_QUANTITY is not null)
         and (ltplBUDGET_LINE.BLI_REMAINING_QUANTITY = 0)
         and (ltplBUDGET_LINE.BLI_REMAINING_PRICE = 0) then
        ltplBUDGET_LINE.BLI_REMAINING_AMOUNT  := 0;
      elsif     aQteUpdated = true
            and (ltplBUDGET_LINE.BLI_REMAINING_QUANTITY = 0) then
        ltplBUDGET_LINE.BLI_REMAINING_AMOUNT  := 0;
      elsif     (ltplBUDGET_LINE.BLI_REMAINING_PRICE is not null)
            and (ltplBUDGET_LINE.BLI_REMAINING_PRICE = 0) then
        ltplBUDGET_LINE.BLI_REMAINING_AMOUNT  := 0;
      elsif     (ltplBUDGET_LINE.BLI_REMAINING_QUANTITY <> 0)
            and (ltplBUDGET_LINE.BLI_REMAINING_PRICE <> 0) then
        ltplBUDGET_LINE.BLI_REMAINING_AMOUNT  := ltplBUDGET_LINE.BLI_REMAINING_QUANTITY * ltplBUDGET_LINE.BLI_REMAINING_PRICE;
      end if;

      FWK_I_MGT_ENTITY_DATA.SetColumn(iotBUDGET_LINE, 'BLI_REMAINING_AMOUNT', ltplBUDGET_LINE.BLI_REMAINING_AMOUNT);
    end;

    procedure CalculQuantiteReste(aAmountUpdated in boolean)
    is
    begin
      if     (ltplBUDGET_LINE.BLI_REMAINING_AMOUNT = 0)
         and (ltplBUDGET_LINE.BLI_REMAINING_PRICE <> 0) then
        ltplBUDGET_LINE.BLI_REMAINING_QUANTITY  := 0;
      elsif     aAmountUpdated = true
            and (ltplBUDGET_LINE.BLI_REMAINING_AMOUNT = 0) then
        ltplBUDGET_LINE.BLI_REMAINING_QUANTITY  := 0;
      elsif     (ltplBUDGET_LINE.BLI_REMAINING_AMOUNT <> 0)
            and (ltplBUDGET_LINE.BLI_REMAINING_PRICE = 0)
            and (ltplBUDGET_LINE.BLI_REMAINING_QUANTITY <> 0) then
        ltplBUDGET_LINE.BLI_REMAINING_PRICE  := ltplBUDGET_LINE.BLI_REMAINING_AMOUNT / ltplBUDGET_LINE.BLI_REMAINING_QUANTITY;
      elsif     (ltplBUDGET_LINE.BLI_REMAINING_AMOUNT <> 0)
            and (ltplBUDGET_LINE.BLI_REMAINING_PRICE <> 0) then
        ltplBUDGET_LINE.BLI_REMAINING_QUANTITY  := ltplBUDGET_LINE.BLI_REMAINING_AMOUNT / ltplBUDGET_LINE.BLI_REMAINING_PRICE;
      end if;

      FWK_I_MGT_ENTITY_DATA.SetColumn(iotBUDGET_LINE, 'BLI_REMAINING_QUANTITY', ltplBUDGET_LINE.BLI_REMAINING_QUANTITY);
    end;

    procedure MiseAjourDateReste
    is
    begin
      ltplBUDGET_LINE.BLI_LAST_REMAINING_DATE  := sysdate;
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotBUDGET_LINE, 'BLI_LAST_REMAINING_DATE', ltplBUDGET_LINE.BLI_LAST_REMAINING_DATE);
    end;

    procedure MiseAjourQuantiteFigeReste
    is
    begin
      select nvl(sum( (nvl(GSP_COL1_QUANTITY, 0) + nvl(GSP_COL2_QUANTITY, 0) + nvl(GSP_COL3_QUANTITY, 0) + nvl(GSP_COL4_QUANTITY, 0) + nvl(GSP_COL5_QUANTITY, 0) ) )
               , 0
                )
        into ltplBUDGET_LINE.BLI_HANGING_SPENDING_QUANTITY
        from GAL_SPENDING_CONSOLIDATED
       where GAL_BUDGET_ID = ltplBUDGET_LINE.GAL_BUDGET_ID
         and GAL_COST_CENTER_ID = ltplBUDGET_LINE.GAL_COST_CENTER_ID
         and nvl(GAL_BUDGET_PERIOD_ID, 0) = nvl(ltplBUDGET_LINE.GAL_BUDGET_PERIOD_ID, 0);

      if (ltplBUDGET_LINE.BLI_REMAINING_QUANTITY > 0) then
        ltplBUDGET_LINE.BLI_LAST_ESTIMATION_QUANTITY  := ltplBUDGET_LINE.BLI_REMAINING_QUANTITY + ltplBUDGET_LINE.BLI_HANGING_SPENDING_QUANTITY;
      else
        ltplBUDGET_LINE.BLI_LAST_ESTIMATION_QUANTITY  := 0;
      end if;

      FWK_I_MGT_ENTITY_DATA.SetColumn(iotBUDGET_LINE, 'BLI_HANGING_SPENDING_QUANTITY', ltplBUDGET_LINE.BLI_HANGING_SPENDING_QUANTITY);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotBUDGET_LINE, 'BLI_LAST_ESTIMATION_QUANTITY', ltplBUDGET_LINE.BLI_LAST_ESTIMATION_QUANTITY);
    end;

    procedure MiseAjourMontantFigeReste
    is
    begin
      select nvl(sum( (nvl(GSP_COL1_AMOUNT, 0) + nvl(GSP_COL2_AMOUNT, 0) + nvl(GSP_COL3_AMOUNT, 0) + nvl(GSP_COL4_AMOUNT, 0) + nvl(GSP_COL5_AMOUNT, 0) ) ), 0)
        into ltplBUDGET_LINE.BLI_HANGING_SPENDING_AMOUNT
        from GAL_SPENDING_CONSOLIDATED
       where GAL_BUDGET_ID = ltplBUDGET_LINE.GAL_BUDGET_ID
         and GAL_COST_CENTER_ID = ltplBUDGET_LINE.GAL_COST_CENTER_ID
         and nvl(GAL_BUDGET_PERIOD_ID, 0) = nvl(ltplBUDGET_LINE.GAL_BUDGET_PERIOD_ID, 0);

      if (ltplBUDGET_LINE.BLI_REMAINING_AMOUNT > 0) then
        ltplBUDGET_LINE.BLI_LAST_ESTIMATION_AMOUNT  := ltplBUDGET_LINE.BLI_REMAINING_AMOUNT + ltplBUDGET_LINE.BLI_HANGING_SPENDING_AMOUNT;
      else
        ltplBUDGET_LINE.BLI_LAST_ESTIMATION_AMOUNT  := 0;
      end if;

      FWK_I_MGT_ENTITY_DATA.SetColumn(iotBUDGET_LINE, 'BLI_HANGING_SPENDING_AMOUNT', ltplBUDGET_LINE.BLI_HANGING_SPENDING_AMOUNT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotBUDGET_LINE, 'BLI_LAST_ESTIMATION_AMOUNT', ltplBUDGET_LINE.BLI_LAST_ESTIMATION_AMOUNT);
    end;
------------------------------------------------------------------------------------------------------------------------------------
  begin
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotBUDGET_LINE, 'GAL_BUDGET_LINE_ID') then
      lMessage  := lMessage || PCS.PC_FUNCTIONS.TranslateWord('Le champ doit avoir une valeur :') || ' "GAL_BUDGET_LINE_ID"' || chr(10);
    end if;

    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotBUDGET_LINE, 'GAL_BUDGET_PERIOD_ID')
       and ltplBUDGET_LINE.BLI_CLOTURED = 1 then
      SetMessage(lMessage, 'La période ne peut plus être changée, car cette ligne de budget est clôturée !');
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotBUDGET_LINE, 'GAL_COST_CENTER_ID') then
      select count(*)
        into lCount
        from GAL_BUDGET_LINE BLI
           , GAL_BUDGET BDG
           , GAL_PROJECT PRJ
       where BLI.GAL_BUDGET_ID = ltplBUDGET_LINE.GAL_BUDGET_ID
         and BLI.GAL_BUDGET_LINE_ID <> ltplBUDGET_LINE.GAL_BUDGET_LINE_ID
         and BLI.GAL_COST_CENTER_ID = ltplBUDGET_LINE.GAL_COST_CENTER_ID
         and BLI.GAL_BUDGET_ID = BDG.GAL_BUDGET_ID
         and BDG.GAL_PROJECT_ID = PRJ.GAL_PROJECT_ID
         and PRJ.PRJ_BUDGET_PERIOD = 0;

      if lCount > 0 then
        SetMessage(lMessage, 'L''existence d''une autre ligne de budget pour ce budget et cette même nature analytique n''autorise pas cette action');
      end if;
    end if;

    if lMessage is not null then
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckBUDGET_LINEData'
                                         );
    end if;

    if ltplBUDGET_LINE.BLI_SEQUENCE is null then
      select nvl(max(BLI_SEQUENCE), 0) + 10
        into ltplBUDGET_LINE.BLI_SEQUENCE
        from GAL_BUDGET_LINE
       where GAL_BUDGET_ID = ltplBUDGET_LINE.GAL_BUDGET_ID;

      FWK_I_MGT_ENTITY_DATA.SetColumn(iotBUDGET_LINE, 'BLI_SEQUENCE', ltplBUDGET_LINE.BLI_SEQUENCE);
    end if;

    if     ltplBUDGET_LINE.BLI_WORDING is null
       and ltplBUDGET_LINE.GAL_COST_CENTER_ID is not null then
      select GCC_WORDING
        into ltplBUDGET_LINE.BLI_WORDING
        from GAL_COST_CENTER
       where GAL_COST_CENTER_ID = ltplBUDGET_LINE.GAL_COST_CENTER_ID;

      FWK_I_MGT_ENTITY_DATA.SetColumn(iotBUDGET_LINE, 'BLI_WORDING', ltplBUDGET_LINE.BLI_WORDING);
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotBUDGET_LINE, 'GAL_COST_CENTER_ID') then
      TauxHoraireDeCentreDeFrais;

      if     (ltplBUDGET_LINE.BLI_BUDGET_QUANTITY <> 0)
         and (ltplBUDGET_LINE.BLI_BUDGET_PRICE = 0)
         and (lTodayHourlyRate <> 0) then
        ltplBUDGET_LINE.BLI_BUDGET_PRICE  := lTodayHourlyRate;
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotBUDGET_LINE, 'BLI_BUDGET_PRICE', ltplBUDGET_LINE.BLI_BUDGET_PRICE);
      end if;

      CalculMontantBudget(false);

      if     (ltplBUDGET_LINE.BLI_REMAINING_QUANTITY <> 0)
         and (ltplBUDGET_LINE.BLI_REMAINING_PRICE = 0)
         and (lTodayHourlyRate <> 0) then
        ltplBUDGET_LINE.BLI_REMAINING_PRICE  := lTodayHourlyRate;
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotBUDGET_LINE, 'BLI_REMAINING_PRICE', ltplBUDGET_LINE.BLI_REMAINING_PRICE);
      end if;

      CalculMontantReste(false);
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotBUDGET_LINE, 'BLI_BUDGET_QUANTITY') then
      TauxHoraireDeCentreDeFrais;

      if     (ltplBUDGET_LINE.BLI_BUDGET_QUANTITY <> 0)
         and (ltplBUDGET_LINE.BLI_BUDGET_PRICE = 0)
         and (lTodayHourlyRate <> 0) then
        ltplBUDGET_LINE.BLI_BUDGET_PRICE  := lTodayHourlyRate;
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotBUDGET_LINE, 'BLI_BUDGET_PRICE', ltplBUDGET_LINE.BLI_BUDGET_PRICE);
      end if;

      CalculMontantBudget(true);
      MiseAjourDateBudget;
      MiseAjourQuantiteFigeBudget;
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotBUDGET_LINE, 'BLI_BUDGET_PRICE') then
      CalculMontantBudget(false);
      CalculQuantiteBudget(false);
      MiseAjourDateBudget;
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotBUDGET_LINE, 'BLI_BUDGET_AMOUNT') then
      CalculQuantiteBudget(true);
      MiseAjourDateBudget;
      MiseAjourMontantFigeBudget;
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotBUDGET_LINE, 'BLI_REMAINING_QUANTITY') then
      TauxHoraireDeCentreDeFrais;

      if (ltplBUDGET_LINE.BLI_REMAINING_QUANTITY <> 0) then
        if     (ltplBUDGET_LINE.BLI_REMAINING_PRICE = 0)
           and (lTodayHourlyRate <> 0) then
          ltplBUDGET_LINE.BLI_REMAINING_PRICE  := lTodayHourlyRate;
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotBUDGET_LINE, 'BLI_REMAINING_PRICE', ltplBUDGET_LINE.BLI_REMAINING_PRICE);
        elsif     (ltplBUDGET_LINE.BLI_REMAINING_PRICE <> 0)
              and (lInitialHourlyRate = ltplBUDGET_LINE.BLI_REMAINING_PRICE) then
          -- mise à jour de la quantité reste :
          -- contrôle si le prix unitaire du reste initial a été modifie, sinon initialisation selon le taux du jour
          ltplBUDGET_LINE.BLI_REMAINING_PRICE  := lTodayHourlyRate;
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotBUDGET_LINE, 'BLI_REMAINING_PRICE', ltplBUDGET_LINE.BLI_REMAINING_PRICE);
        end if;
      end if;

      CalculMontantReste(true);
      MiseAjourDateReste;
      MiseAjourQuantiteFigeReste;
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotBUDGET_LINE, 'BLI_REMAINING_PRICE') then
      CalculMontantReste(false);
      CalculQuantiteReste(false);
      MiseAjourDateReste;
    end if;

    if FWK_I_MGT_ENTITY_DATA.IsModified(iotBUDGET_LINE, 'BLI_REMAINING_AMOUNT') then
      CalculQuantiteReste(true);
      MiseAjourDateReste;
      MiseAjourMontantFigeReste;
    end if;

    if lMessage is not null then
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckBUDGET_LINEData'
                                         );
    end if;
  end CheckBUDGET_LINEData;

  /**
  * procedure CopyProjectCurrencies
  * Description
  *   Copie des monnaies et des couvertures d'une affaire à une autre
  */
  procedure CopyProjectCurrencies(
    iSrcProjectID in GAL_PROJECT.GAL_PROJECT_ID%type
  , iTgtProjectID in GAL_PROJECT.GAL_PROJECT_ID%type
  , iForceDayRate in integer default 0
  )
  is
  begin
    -- Copie des monnaies de l'affaire
    CopyProjectCURRENCY_RATE(iSrcProjectID, iTgtProjectID, iForceDayRate);
    -- Copie des couvertures de l'affaire
    CopyProjectCURRENCY_RISK(iSrcProjectID, iTgtProjectID, iForceDayRate);
  end CopyProjectCurrencies;

  /**
  * procedure CopyProjectCurrencies
  * Description
  *   Copie des monnaies D'une affaire à une autre
  */
  procedure CopyProjectCURRENCY_RATE(
    iSrcProjectID in GAL_PROJECT.GAL_PROJECT_ID%type
  , iTgtProjectID in GAL_PROJECT.GAL_PROJECT_ID%type
  , iForceDayRate in integer default 0
  )
  is
    ltCRUD         FWK_I_TYP_DEFINITION.t_crud_def;
    lnExchangeRate GAL_CURRENCY_RATE.GCT_RATE_OF_EXCHANGE%type;
    lnBasePrice    GAL_CURRENCY_RATE.GCT_BASE_PRICE%type;
  begin
    -- Copie des monnaies de l'affaire
    if pcs.pc_config.getconfig('GAL_CURRENCY_BASE_RATE') = '1' then
      for ltplCurrRate in (select   GAL_CURRENCY_RATE_ID
                                  , ACS_FINANCIAL_CURRENCY_ID
                               from GAL_CURRENCY_RATE
                              where GAL_PROJECT_ID = iSrcProjectID
                           order by GAL_CURRENCY_RATE_ID) loop
        FWK_I_MGT_ENTITY.new(FWK_TYP_GAL_ENTITY.gcGalCurrencyRate, ltCRUD);
        FWK_I_MGT_ENTITY.load(ltCRUD, ltplCurrRate.GAL_CURRENCY_RATE_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD, 'GAL_CURRENCY_RATE_ID', INIT_ID_SEQ.nextval);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD, 'GAL_PROJECT_ID', iTgtProjectID);

        -- Forcer l'utilisation du cours du jour
        if iForceDayRate = 1 then
          ACS_FUNCTION.GetExchangeRate(aDate           => sysdate
                                     , aCurrency_id    => ltplCurrRate.ACS_FINANCIAL_CURRENCY_ID
                                     , aRateType       => 1
                                     , aExchangeRate   => lnExchangeRate
                                     , aBasePrice      => lnBasePrice
                                      );
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD, 'GCT_RATE_OF_EXCHANGE', lnExchangeRate);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD, 'GCT_BASE_PRICE', lnBasePrice);
        end if;

        FWK_I_MGT_ENTITY_DATA.SetColumnsCreation(ltCRUD, true);   -- Initialise les champs de création A_DATECRE et A_IDMOD
        FWK_I_MGT_ENTITY_DATA.SetColumnsModification(ltCRUD, false);   -- Supprime les valeurs des champs de modification A_DATEMOD et A_IDMOD
        FWK_I_MGT_ENTITY.InsertEntity(ltCRUD);
        FWK_I_MGT_ENTITY.Release(ltCRUD);
      end loop;
    end if;
  end CopyProjectCURRENCY_RATE;

  /**
  * procedure CopyProjectCurrencies
  * Description
  *   Copie des couvertures d'une affaire à une autre
  */
  procedure CopyProjectCURRENCY_RISK(
    iSrcProjectID in GAL_PROJECT.GAL_PROJECT_ID%type
  , iTgtProjectID in GAL_PROJECT.GAL_PROJECT_ID%type
  , iForceDayRate in integer default 0
  )
  is
    ltCRUD         FWK_I_TYP_DEFINITION.t_crud_def;
    lnExchangeRate GAL_CURRENCY_RATE.GCT_RATE_OF_EXCHANGE%type;
    lnBasePrice    GAL_CURRENCY_RATE.GCT_BASE_PRICE%type;
    lnRiskNumber   GAL_CURRENCY_RISK.GCK_NUMBER%type             default 0;
  begin
    -- Copie des couvertures de l'affaire
    if pcs.pc_config.getconfig('COM_CURRENCY_RISK_MANAGE') = '1' then
      for ltplCurrRisk in (select   GAL_CURRENCY_RISK_ID
                                  , ACS_FINANCIAL_CURRENCY_ID
                               from GAL_CURRENCY_RISK
                              where GAL_PROJECT_ID = iSrcProjectID
                                and (   C_GAL_RISK_TYPE = '01'
                                     or C_GAL_RISK_TYPE = '03'
                                     or C_GAL_RISK_TYPE = '04')
                           order by GCK_NUMBER) loop
        -- N° de couverture de 10 en 10
        lnRiskNumber  := lnRiskNumber + 10;
        FWK_I_MGT_ENTITY.new(FWK_TYP_GAL_ENTITY.gcGalCurrencyRisk, ltCRUD);
        FWK_I_MGT_ENTITY.load(ltCRUD, ltplCurrRisk.GAL_CURRENCY_RISK_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD, 'GAL_CURRENCY_RISK_ID', INIT_ID_SEQ.nextval);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD, 'GAL_PROJECT_ID', iTgtProjectID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD, 'GCK_NUMBER', lnRiskNumber);
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltCRUD, 'GCK_BALANCE');

        -- Forcer l'utilisation du cours du jour
        if iForceDayRate = 1 then
          ACS_FUNCTION.GetExchangeRate(aDate           => sysdate
                                     , aCurrency_id    => ltplCurrRisk.ACS_FINANCIAL_CURRENCY_ID
                                     , aRateType       => 1
                                     , aExchangeRate   => lnExchangeRate
                                     , aBasePrice      => lnBasePrice
                                      );
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD, 'GCK_RATE_OF_EXCHANGE', lnExchangeRate);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD, 'GCK_BASE_PRICE', lnBasePrice);
        end if;

        -- Initialise les champs de création A_DATECRE et A_IDMOD
        FWK_I_MGT_ENTITY_DATA.SetColumnsCreation(ltCRUD, true);
        -- Supprime les valeurs des champs de modification A_DATEMOD et A_IDMOD
        FWK_I_MGT_ENTITY_DATA.SetColumnsModification(ltCRUD, false);
        FWK_I_MGT_ENTITY.InsertEntity(ltCRUD);
        FWK_I_MGT_ENTITY.Release(ltCRUD);
      end loop;
    end if;
  end CopyProjectCURRENCY_RISK;
end GAL_PRC_PROJECT;
