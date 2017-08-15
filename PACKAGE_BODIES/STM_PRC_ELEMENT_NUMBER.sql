--------------------------------------------------------
--  DDL for Package Body STM_PRC_ELEMENT_NUMBER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_PRC_ELEMENT_NUMBER" 
is
  /**
  * procedure pCreateNewSplitDetail
  * Description
  *   Méthode de création de detail par split, se baser sur cette signature pour créer une indiv
  * @created fp 11.10.2013
  * @updated
  * @public
  * @param iSourceElementNumberId : element source
  * @param iNewValue              : nouvelle valeur de caractérisation
  * @param iQualityStatusId       : status qualité  (facultatif)
  */
  procedure pCreateNewSplitDetail(
    iSourceElementNumberId in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , iNewValue              in STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iQualityStatusId       in STM_ELEMENT_NUMBER.GCO_QUALITY_STATUS_ID%type default null
  , iCopyOrigin            in number
  )
  is
    lElementNumberId STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    lGoodId          GCO_GOOD.GCO_GOOD_ID%type            := FWK_I_LIB_ENTITY.getNumberFieldFromPk('STM_ELEMENT_NUMBER', 'GCO_GOOD_ID', iSourceElementNumberId);
    lQualityStatusId GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type   := iQualityStatusId;
  begin
    -- Recherche du status qualité si non défini
    if GCO_I_LIB_CHARACTERIZATION.HasQualityStatusManagement(lGoodId) = 1 then
      if lQualityStatusId is null then
        lQualityStatusId  :=
          nvl(FWK_I_LIB_ENTITY.getNumberFieldFromPk('STM_ELEMENT_NUMBER', 'GCO_QUALITY_STATUS_ID', iSourceElementNumberId)
            , GCO_I_LIB_QUALITY_STATUS.GetReceiptStatus(lGoodId)
             );
      end if;
    else
      lQualityStatusId  := null;
    end if;

    if iCopyOrigin = 1 then
      -- Création par copie du detail d'origine
      CopyDetail(iSourceElementNumberId   => iSourceElementNumberId
               , iNewStatus               => STM_I_LIB_CONSTANT.gcEleNumStatusInactive
               , iNewValue                => iNewValue
               , iQualityStatusId         => lQualityStatusId
                );
    else
      -- pas de reprise des attributs du détail caractérisation source, création avec les valeurs par défaut
      declare
        lElementType STM_ELEMENT_NUMBER.C_ELEMENT_TYPE%type
                                                       := FWK_I_LIB_ENTITY.getNumberFieldFromPk('STM_ELEMENT_NUMBER', 'C_ELEMENT_TYPE', iSourceElementNumberId);
      begin
        CreateDetail(oElementNumberId    => lElementNumberId
                   , iGoodId             => lGoodId
                   , iStatus             => STM_I_LIB_CONSTANT.gcEleNumStatusInactive
                   , iValue              => iNewValue
                   , iElementType        => lElementType
                   , iRetestDate         => null
                   , ioQualityStatusId   => lQualityStatusId
                    );
      end;
    end if;
  end pCreateNewSplitDetail;

  /**
  * Description
  *   Méthode de création de detail par copie
  */
  procedure CopyDetail(
    iSourceElementNumberId in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , iNewStatus             in STM_ELEMENT_NUMBER.C_ELE_NUM_STATUS%type default STM_I_LIB_CONSTANT.gcEleNumStatusActive
  , iNewValue              in STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iQualityStatusId       in STM_ELEMENT_NUMBER.GCO_QUALITY_STATUS_ID%type
  )
  is
    ltCRUD_DEF       FWK_I_TYP_DEFINITION.t_crud_def;
    lElementNumberId STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
  begin
    lElementNumberId  := GetNewId;
    FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_STM_ENTITY.gcStmElementNumber, iot_crud_definition => ltCRUD_DEF);
    FWK_I_MGT_ENTITY.PrepareDuplicate(iot_crud_definition => ltCRUD_DEF, ib_initialize => true, in_main_id => iSourceElementNumberId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_ELEMENT_NUMBER_ID', lElementNumberId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_ELE_NUM_STATUS', iNewStatus);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SEM_VALUE', iNewValue);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_QUALITY_STATUS_ID', iQualityStatusId);
    FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltCRUD_DEF, 'C_OLD_ELE_NUM_STATUS');
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    -- Copie des champs vituels
    COM_VFIELDS.DuplicateVirtualField(FWK_TYP_STM_ENTITY.gcStmElementNumber
                                    , null   -- aFieldName.  NULL -> Copie de tous le champs virtuels
                                    , iSourceElementNumberId
                                    , lElementNumberId
                                     );
  end CopyDetail;

  /**
  * Description
  *   Méthode de création de detai
  */
  procedure CreateDetail(
    oElementNumberId  out    STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , iGoodId           in     STM_ELEMENT_NUMBER.GCO_GOOD_ID%type
  , iStatus           in     STM_ELEMENT_NUMBER.C_ELE_NUM_STATUS%type default STM_I_LIB_CONSTANT.gcEleNumStatusActive
  , iOldStatus        in     STM_ELEMENT_NUMBER.C_OLD_ELE_NUM_STATUS%type default null
  , iElementType      in     STM_ELEMENT_NUMBER.C_ELEMENT_TYPE%type
  , iValue            in     STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iRetestDate       in     STM_ELEMENT_NUMBER.SEM_RETEST_DATE%type
  , ioQualityStatusId in out STM_ELEMENT_NUMBER.GCO_QUALITY_STATUS_ID%type
  )
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_STM_ENTITY.gcStmElementNumber, iot_crud_definition => ltCRUD_DEF);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_GOOD_ID', iGoodId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_ELE_NUM_STATUS', nvl(iStatus, STM_I_LIB_CONSTANT.gcEleNumStatusActive) );

    if iOldStatus is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_OLD_ELE_NUM_STATUS', iOldStatus);
    end if;

    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_ELEMENT_TYPE', iElementType);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SEM_VALUE', iValue);

    if iRetestDate is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SEM_RETEST_DATE', iRetestDate);
    end if;

    if ioQualityStatusId is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_QUALITY_STATUS_ID', ioQualityStatusId);
    end if;

    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    -- Récupérer certaines valeurs du détail de caractérisation
    oElementNumberId   := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_DEF, 'STM_ELEMENT_NUMBER_ID');
    ioQualityStatusId  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_DEF, 'GCO_QUALITY_STATUS_ID');
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end CreateDetail;

  /**
  * procedure AfterCreateDetail
  * Description
  *   Méthode pour l'execution de la procédure indiv de création de détail de caractérisation
  */
  procedure AfterCreateDetail(iElementNumberId in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type)
  is
    lvIndivProc varchar2(61);
  begin
    lvIndivProc  := PCS.PC_CONFIG.GetConfigUpper('STM_ELE_NUM_AFTER_CREATE');

    if lvIndivProc is not null then
      execute immediate 'begin' || CO.cLineBreak || lvIndivProc || '(:iElementNumberId);' || CO.cLineBreak || 'end;'
                  using in iElementNumberId;
    end if;
  end AfterCreateDetail;

  /**
  * Description
  *   Méthode de mise à jour du statut su détail de caractérisation
  */
  procedure UpdateElementNumber(
    iElementNumberID in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , iStatus          in STM_ELEMENT_NUMBER.C_ELE_NUM_STATUS%type
  , iRetestDate      in STM_ELEMENT_NUMBER.SEM_RETEST_DATE%type default null
  , ioldStatus       in STM_ELEMENT_NUMBER.C_OLD_ELE_NUM_STATUS%type default null
  )
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    if iRetestDate is null then
      FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_STM_ENTITY.gcStmElementNumber, iot_crud_definition => ltCRUD_DEF);
    else
      FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_TYP_STM_ENTITY.gcStmElementNumber
                         , iot_crud_definition   => ltCRUD_DEF
                         , ib_initialize         => true
                         , in_main_id            => iElementNumberID
                          );

      if FWK_I_MGT_ENTITY_DATA.IsNull(it_crud_definition => ltCRUD_DEF, iv_column_name => 'SEM_RETEST_DATE') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SEM_RETEST_DATE', iRetestDate);
      end if;
    end if;

    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_ELEMENT_NUMBER_ID', iElementNumberID);

    -- si on ne donne pas de status, alors, on ne le modifie pas
    if iStatus is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_ELE_NUM_STATUS', iStatus);

      if iOldStatus = 'CLEAR' then
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltCRUD_DEF, 'C_OLD_ELE_NUM_STATUS');
      elsif iOldStatus is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_OLD_ELE_NUM_STATUS', iOldStatus);
      end if;
    end if;

    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end UpdateElementNumber;

    /**
  * Description
  *   Méthode de suprresion de detail
  */
  procedure DeleteDetail(
    iElementNumberID in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type default null
  , iGoodID          in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type default null
  , iElementType     in STM_ELEMENT_NUMBER.C_ELEMENT_TYPE%type default null
  )
  is
    lnError    integer;
    lvError    varchar2(2000);
    ltCRUD_DEF fwk_i_typ_definition.t_crud_def;
  begin
    for tplElementNumber in (select STM_ELEMENT_NUMBER_ID
                               from STM_ELEMENT_NUMBER
                              where (    iElementNumberId is not null
                                     and STM_ELEMENT_NUMBER_ID = iElementNumberId)
                                 or     (    iGoodId is not null
                                         and GCO_GOOD_ID = iGoodId)
                                    and (   iElementType is null
                                         or C_ELEMENT_TYPE = iElementType) ) loop
      FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_STM_ENTITY.gcStmElementNumber, iot_crud_definition => ltCRUD_DEF);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_ELEMENT_NUMBER_ID', tplElementNumber.STM_ELEMENT_NUMBER_ID);
      FWK_I_MGT_ENTITY.DeleteEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    end loop;
  end DeleteDetail;

  /**
  * Methode  de création d'un nouveau detail à partir d'un autre déjà existant
  */
  procedure SplitDetail(
    iElementNumberId in     STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , iNewValue        in     STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iCopyOrigin      in     number
  , iMergeAuthorized in     number
  , iQualityStatusId in     STM_ELEMENT_NUMBER.GCO_QUALITY_STATUS_ID%type default null
  , oError           out    varchar2
  )
  is
    lGoodId          GCO_GOOD.GCO_GOOD_ID%type                  := FWK_I_LIB_ENTITY.getNumberFieldFromPk('STM_ELEMENT_NUMBER', 'GCO_GOOD_ID', iElementNumberId);
    lTargetElementID STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type   := STM_I_LIB_ELEMENT_NUMBER.GetDetailElementFromValue(lGoodId, iNewValue);
  begin
    if lTargetElementID is not null then
      if iMergeAuthorized = 0 then
        -- élément existant et pas de merge autorisé => Erreur
        oError  := PCS.PC_FUNCTIONS.TranslateWord('Detail caractérisation cible déjà existant.');
      else
        -- Si le detail de caractérisation existe déjà, on ne fait rien (homogéïté des lots)
        null;
      end if;
    else
      declare
        lIndivProc varchar2(61) := PCS.PC_CONFIG.GetConfigUpper('STM_ELE_NUM_SPLIT_DETAIL');
      begin
        -- si une procedure indiv est déclarée, c'est elle qui se charge de la création du nouveau détail
        if lIndivProc is not null then
          execute immediate 'begin' || chr(13) || lIndivProc || '(:iElementNumberId, :iNewValue, :iNewStatus, :iCopyOrigin);' || chr(13) || 'end;'
                      using iElementNumberId, iNewValue, iQualityStatusId, iCopyOrigin;
        else
          -- Création du detail caracterisation
          pCreateNewSplitDetail(iElementNumberId, iNewValue, iQualityStatusId, iCopyOrigin);
        end if;
      end;
    end if;
  end SplitDetail;

  /**
  * Description
  *   Execution of the control method optionnally defined by the STM_BEFORE_BATCH_SPLITTING
  *   configuration. This method can return an error message if one of it controls failed.
  *   If the message contains the reserved word "[ABORT]", the treatment will be aborted,
  *   otherwise a warning message will be displayed and the user will decide if he continues.
  */
  procedure ExecuteBeforeBatchSplitting(
    iProcName         in     varchar2
  , iCharactId1       in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharactId2       in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharactId3       in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharactId4       in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharactId5       in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iSrcCharactValue1 in     STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iSrcCharactValue2 in     STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iSrcCharactValue3 in     STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iSrcCharactValue4 in     STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iSrcCharactValue5 in     STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iDstCharactValue1 in     STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iDstCharactValue2 in     STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iDstCharactValue3 in     STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iDstCharactValue4 in     STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iDstCharactValue5 in     STM_ELEMENT_NUMBER.SEM_VALUE%type
  , iSrcLocationId    in     STM_LOCATION.STM_LOCATION_ID%type
  , iDstLocationId    in     STM_LOCATION.STM_LOCATION_ID%type
  , iBatchMerge       in     integer
  , iCopyDetail       in     integer
  , oMessage          out    varchar2
  )
  is
  begin
    -- si une procedure indiv est déclarée, c'est elle qui se charge de la création du nouveau détail
    if iProcName is not null then
      execute immediate 'begin' ||
                        chr(13) ||
                        iProcName ||
                        '(:iCharactId1, :iCharactId2, :iCharactId3, :iCharactId4, :iCharactId5, :iSrcCharactValue1, :iSrcCharactValue2, :iSrcCharactValue3, :iSrcCharactValue4, :iSrcCharactValue5,:iDstCharactValue1,:iDstCharactValue2,:iDstCharactValue3,:iDstCharactValue4,:iDstCharactValue5 ,:iSrcLocationId,:iDstLocationId,:iBatchMerge,:iCopyDetail,:oMessage); end;'
                  using     iCharactId1
                      ,     iCharactId2
                      ,     iCharactId3
                      ,     iCharactId4
                      ,     iCharactId5
                      ,     iSrcCharactValue1
                      ,     iSrcCharactValue2
                      ,     iSrcCharactValue3
                      ,     iSrcCharactValue4
                      ,     iSrcCharactValue5
                      ,     iDstCharactValue1
                      ,     iDstCharactValue2
                      ,     iDstCharactValue3
                      ,     iDstCharactValue4
                      ,     iDstCharactValue5
                      ,     iSrcLocationId
                      ,     iDstLocationId
                      ,     iBatchMerge
                      ,     iCopyDetail
                      , out oMessage;
    end if;
  exception
    when others then
      oMessage  :=
        PCS.PC_FUNCTIONS.TranslateWord('Erreur à l''exécution de la procedure individualisée de contrôle avant split de lot :') || '[ABORT]' || chr(13)
        || sqlerrm;
  end;

  /**
  * procedure CloseBatch
  * Description
  *   Méthode pour la cloture d'un lot
  */
  procedure CloseBatch(
    iGoodID          in     GCO_GOOD.GCO_GOOD_ID%type
  , iCharID          in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iElementNumberID in     STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , iBatchValue      in     STM_ELEMENT_NUMBER.SEM_VALUE%type
  , oMessage         out    varchar2
  )
  is
    lProcIndiv    varchar2(100);
    lAllowClosing boolean;
  begin
    lAllowClosing  := true;
    -- Procédure indiv pour indiquer si l'on peut cloturer un lot ou pas
    lProcIndiv     := PCS.PC_CONFIG.GetConfig('STM_PRC_BATCH_CLOSING');

    if lProcIndiv is not null then
      execute immediate 'begin ' || CO.cLineBreak || lProcIndiv || '(:iGoodID, :iCharID, :iBatchValue, :oMessage); ' || CO.cLineBreak || ' end;'
                  using in iGoodID, in iCharID, in iBatchValue, out oMessage;

      -- Clôture du lot non-autorisée si trouvé la macro [ABORT] dans le message de retour
      lAllowClosing  := nvl(instr(oMessage, '[ABORT]'), 0) = 0;
    end if;

    -- Clôture du lot autorisée
    if lAllowClosing then
      -- Ajout d'un événement de type clôture de lot au cycle de vie
      STM_PRC_ELEMENT_NUMBER.CreateElementEvent(iElementNumberID => iElementNumberID, iEventType => '04');
    end if;
  end CloseBatch;

  /**
  * procedure CreateElementEvent
  * Description
  *   Méthode pour la création d'un événement pour un détail de caractérisation
  */
  procedure CreateElementEvent(
    iElementNumberID in STM_ELEMENT_NUMBER_EVENT.STM_ELEMENT_NUMBER_ID%type
  , iEventType       in STM_ELEMENT_NUMBER_EVENT.C_STM_ELE_NUM_EVENT_TYPE%type
  , iQualityStatusID in STM_ELEMENT_NUMBER_EVENT.GCO_QUALITY_STATUS_ID%type default null
  , iStockMvtID      in STM_ELEMENT_NUMBER_EVENT.STM_STOCK_MOVEMENT_ID%type default null
  , iEventQty        in STM_ELEMENT_NUMBER_EVENT.ENE_QTY%type default null
  , iEventDate       in STM_ELEMENT_NUMBER_EVENT.ENE_DATE%type default null
  , iRetestDate      in STM_ELEMENT_NUMBER_EVENT.ENE_NEW_RETEST_DATE%type default null
  , iTimeLimitDate   in STM_ELEMENT_NUMBER_EVENT.ENE_NEW_PEREMP_DATE%type default null
  , iComment         in STM_ELEMENT_NUMBER_EVENT.ENE_COMMENT%type default null
  )
  is
    ltEvent fwk_i_typ_definition.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_TYP_STM_ENTITY.gcStmElementNumberEvent, ltEvent);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltEvent, 'STM_ELEMENT_NUMBER_ID', iElementNumberID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltEvent, 'C_STM_ELE_NUM_EVENT_TYPE', iEventType);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltEvent, 'GCO_QUALITY_STATUS_ID', iQualityStatusID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltEvent, 'STM_STOCK_MOVEMENT_ID', iStockMvtID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltEvent, 'ENE_QTY', iEventQty);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltEvent, 'ENE_DATE', coalesce(iEventDate, sysdate) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltEvent, 'ENE_NEW_RETEST_DATE', iRetestDate);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltEvent, 'ENE_NEW_PEREMP_DATE', iTimeLimitDate);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltEvent, 'ENE_COMMENT', iComment);
    FWK_I_MGT_ENTITY.InsertEntity(ltEvent);
    FWK_I_MGT_ENTITY.Release(ltEvent);
  end CreateElementEvent;

  /**
  * procedure RetestElement
  * Description
  *   Méthode pour l'execution de la procédure indiv de ré-analyse d'un détail de caractérisation
  */
  procedure RetestElement(iElementNumberID in STM_ELEMENT_NUMBER_EVENT.STM_ELEMENT_NUMBER_ID%type, ioRetestPos in out number, ioErrorMessage in out varchar2)
  is
    lvIndivProc varchar2(61);
  begin
    lvIndivProc  := PCS.PC_CONFIG.GetConfigUpper('STM_RETEST_BEFORE_VALIDATION');

    if lvIndivProc is not null then
      execute immediate 'begin' || CO.cLineBreak || lvIndivProc || '(:iElementNumberId, :ioRetestPos, :ioErrorMessage);' || CO.cLineBreak || 'end;'
                  using in iElementNumberId, in out ioRetestPos, in out ioErrorMessage;
    end if;
  end RetestElement;

  /**
  * procedure ExecExternProcAfterRetest
  * Description
  *   Execution de la procédure indiv après la validation de la ré-analyse d'un détail de caractérisation
  */
  procedure ExecExternProcAfterRetest(iElementNumberID in STM_ELEMENT_NUMBER_EVENT.STM_ELEMENT_NUMBER_ID%type)
  is
    lvIndivProc varchar2(61);
  begin
    lvIndivProc  := PCS.PC_CONFIG.GetConfigUpper('STM_RETEST_AFTER_VALIDATION');

    if lvIndivProc is not null then
      execute immediate 'begin' || CO.cLineBreak || lvIndivProc || '(:iElementNumberId);' || CO.cLineBreak || 'end;'
                  using in iElementNumberId;
    end if;
  end ExecExternProcAfterRetest;

  /**
  * procedure ValidateChangeStatus
  * Description
  *   Méthode pour l'execution de la procédure indiv de changement du statut qualité
  */
  procedure ValidateChangeStatus(
    iQualityFlowID     in     GCO_QUALITY_STAT_FLOW.GCO_QUALITY_STAT_FLOW_ID%type
  , iElementNumberID   in     STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , iQualityStatFromID in     GCO_QUALITY_STAT_FLOW_DET.GCO_QUALITY_STAT_FROM_ID%type
  , iQualityStatToID   in     GCO_QUALITY_STAT_FLOW_DET.GCO_QUALITY_STAT_TO_ID%type
  , ioErrorMessage     in out varchar2
  )
  is
    lvIndivProc GCO_QUALITY_STAT_FLOW_DET.QSF_PROC_BEFORE_VALIDATION%type;
  begin
    select QSF_PROC_BEFORE_VALIDATION
      into lvIndivProc
      from GCO_QUALITY_STAT_FLOW_DET
     where GCO_QUALITY_STAT_FLOW_ID = iQualityFlowId
       and GCO_QUALITY_STAT_FROM_ID = iQualityStatFromId
       and GCO_QUALITY_STAT_TO_ID = iQualityStatToId;

    if lvIndivProc is not null then
      execute immediate 'begin' ||
                        CO.cLineBreak ||
                        lvIndivProc ||
                        '(:iElementNumberId, :iQualityStatFromId, :iQualityStatToId, :ioErrorMessage);' ||
                        CO.cLineBreak ||
                        'end;'
                  using in iElementNumberId, in iQualityStatFromId, in iQualityStatToId, in out ioErrorMessage;
    end if;
  end ValidateChangeStatus;

  /**
  * procedure ExecExternProcAfterChangeStat
  * Description
  *   Execution de la procédure indiv après la validation de changement du statut qualité
  */
  procedure ExecExternProcAfterChangeStat(
    iQualityFlowID     in GCO_QUALITY_STAT_FLOW.GCO_QUALITY_STAT_FLOW_ID%type
  , iElementNumberID   in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , iQualityStatFromID in GCO_QUALITY_STAT_FLOW_DET.GCO_QUALITY_STAT_FROM_ID%type
  , iQualityStatToID   in GCO_QUALITY_STAT_FLOW_DET.GCO_QUALITY_STAT_TO_ID%type
  )
  is
    lvIndivProc GCO_QUALITY_STAT_FLOW_DET.QSF_PROC_AFTER_VALIDATION%type;
  begin
    select QSF_PROC_AFTER_VALIDATION
      into lvIndivProc
      from GCO_QUALITY_STAT_FLOW_DET
     where GCO_QUALITY_STAT_FLOW_ID = iQualityFlowId
       and GCO_QUALITY_STAT_FROM_ID = iQualityStatFromId
       and GCO_QUALITY_STAT_TO_ID = iQualityStatToId;

    if lvIndivProc is not null then
      execute immediate 'begin' || CO.cLineBreak || lvIndivProc || '(:iElementNumberId, :iQualityStatFromId, :iQualityStatToId);' || CO.cLineBreak || 'end;'
                  using in iElementNumberId, in iQualityStatFromId, iQualityStatToId;
    end if;
  end ExecExternProcAfterChangeStat;

  /**
  * procedure CreateEventMovement
  * Description
  *   Création d'un événement pour un mouvement de stock
  */
  procedure CreateEventMovement(iotMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
  is
    lElementNumberId STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    lStockMovementId STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
    lPositionStockId STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type;
    lQualityStatutId GCO_QUALITY_STATUS.GCO_QUALITY_STATUS_ID%type;
  begin
    if     (PCS.PC_CONFIG.GetConfigUpper('GCO_CHA_USE_DETAIL') = '1')
       and (GCO_I_LIB_CHARACTERIZATION.GoodUseDetail(iotMovementRecord.GCO_GOOD_ID) = 1) then
      lStockMovementId  := iotMovementRecord.STM_STOCK_MOVEMENT_ID;
      lElementNumberId  := STM_LIB_ELEMENT_NUMBER.GetDetailElementFromStockMov(lStockMovementId);

      if lElementNumberId is not null then
        if (PCS.PC_CONFIG.GetConfigUpper('STM_USE_QUALITY_STATUS') = '1') then
          lPositionStockId  :=
            STM_LIB_STOCK_POSITION.GetStockPositionId(iGoodId       => iotMovementRecord.GCO_GOOD_ID
                                                    , iLocationId   => iotMovementRecord.STM_LOCATION_ID
                                                    , iChar1Id      => iotMovementRecord.GCO_CHARACTERIZATION_ID
                                                    , iChar2Id      => iotMovementRecord.GCO_GCO_CHARACTERIZATION_ID
                                                    , iChar3Id      => iotMovementRecord.GCO2_GCO_CHARACTERIZATION_ID
                                                    , iChar4Id      => iotMovementRecord.GCO3_GCO_CHARACTERIZATION_ID
                                                    , iChar5Id      => iotMovementRecord.GCO4_GCO_CHARACTERIZATION_ID
                                                    , iCharValue1   => iotMovementRecord.SMO_CHARACTERIZATION_VALUE_1
                                                    , iCharValue2   => iotMovementRecord.SMO_CHARACTERIZATION_VALUE_2
                                                    , iCharValue3   => iotMovementRecord.SMO_CHARACTERIZATION_VALUE_3
                                                    , iCharValue4   => iotMovementRecord.SMO_CHARACTERIZATION_VALUE_4
                                                    , iCharValue5   => iotMovementRecord.SMO_CHARACTERIZATION_VALUE_5
                                                     );

          -- Récupérer le statut qualité sur la position touchée
          select max(SEM.GCO_QUALITY_STATUS_ID)
            into lQualityStatutId
            from STM_STOCK_POSITION SPO
               , STM_ELEMENT_NUMBER SEM
           where SPO.STM_STOCK_POSITION_ID = lPositionStockId
             and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID(+);

          CreateElementEvent(iElementNumberID => lElementNumberId, iEventType => '01', iStockMvtID => lStockMovementId, iQualityStatusID => lQualityStatutId);
        else
          CreateElementEvent(iElementNumberID => lElementNumberId, iEventType => '01', iStockMvtID => lStockMovementId);
        end if;
      end if;
    end if;
  end CreateEventMovement;

    /**
  * procedure RecalcAnalyzeDate
  * Description
  *   Recalcul de la date d'analyse
  */
  procedure RecalcAnalyzeDate(iElementNumberID in STM_ELEMENT_NUMBER_EVENT.STM_ELEMENT_NUMBER_ID%type)
  is
    ltElement   fwk_i_typ_definition.t_crud_def;
    lRetestDate date;
  begin
    -- recalcul de la nouvelle date d'analyse
    select nvl(SEM.SEM_RETEST_DATE, trunc(sysdate) ) + nvl(CHA_RETEST_DELAY, 0)
      into lRetestDate
      from GCO_CHARACTERIZATION CHA
         , STM_ELEMENT_NUMBER SEM
     where SEM.STM_ELEMENT_NUMBER_ID = iElementNumberID
       and CHA.GCO_CHARACTERIZATION_ID = STM_LIB_ELEMENT_NUMBER.GetCharFromDetailElement(SEM.STM_ELEMENT_NUMBER_ID);

    -- Màj de la date d'analyse
    ChangeRetestDate(iElementNumberID, lRetestDate);
    -- Ajout d'un événement lié au changement de la date de ré-analyse
    CreateElementEvent(iElementNumberID => iElementNumberID, iEventType => '02', iRetestDate => lRetestDate);
  end RecalcAnalyzeDate;

  /**
  * procedure ChangeStatus
  * Description
  *   Mise à jour du statut qualité
  */
  procedure ChangeStatus(
    iElementNumberID in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , iQualityStatusID in STM_ELEMENT_NUMBER.GCO_QUALITY_STATUS_ID%type
  )
  is
    ltElement             fwk_i_typ_definition.t_crud_def;
    lnQualityStatusFromID STM_ELEMENT_NUMBER.GCO_QUALITY_STATUS_ID%type;
    lnGoodID              GCO_GOOD.GCO_GOOD_ID%type;
    lnDeleteLink          GCO_QUALITY_STAT_FLOW_DET.QSF_DELETE_NETWORK_LINK%type;
    lnUpdateLink          GCO_QUALITY_STAT_FLOW_DET.QSF_UPDATE_LINK%type;
    lnRefreshNetworkLink  number(1);
  begin
    -- Màj du statut qualité
    FWK_I_MGT_ENTITY.new(FWK_TYP_STM_ENTITY.gcStmElementNumber, ltElement, true, iElementNumberID);
    -- Récupère le bien et l'ancien statut qualité lié au détail de caractérisation courant.
    lnGoodID               := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltElement, 'GCO_GOOD_ID');
    lnQualityStatusFromID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltElement, 'GCO_QUALITY_STATUS_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltElement, 'GCO_QUALITY_STATUS_ID', iQualityStatusID);
    FWK_I_MGT_ENTITY.UpdateEntity(ltElement);
    FWK_I_MGT_ENTITY.Release(ltElement);
    -- Recherche si le flux qualité demande le rafraichissement des attributions
    lnRefreshNetworkLink   :=
      GCO_LIB_QUALITY_STATUS.getRefreshNetworkLink(iGoodId                => lnGoodID
                                                 , iQualityFlowId         => null
                                                 , iQualityStatusFromId   => lnQualityStatusFromID
                                                 , iQualityStatusToId     => iQualityStatusID
                                                 , ioDeleteLink           => lnDeleteLink
                                                 , ioUpdateLink           => lnUpdateLink
                                                  );

    -- Rafraichit les attributions lié au détail de caractérisation courant et au nouveau statut qualité
    if lnRefreshNetworkLink = 1 then
      FAL_I_PRC_ATTRIB.RefreshStockNetworkLink(iElementNumberId => iElementNumberId, iDeleteLink => lnDeleteLink, iRefreshLink => lnUpdateLink);
    end if;
  end ChangeStatus;

  /**
  * procedure ChangRetestDate
  * Description
  *   Mise à jour du statut qualité
  */
  procedure ChangeRetestDate(iElementNumberID in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type, iRetestDate in STM_ELEMENT_NUMBER.SEM_RETEST_DATE%type)
  is
    ltElement   fwk_i_typ_definition.t_crud_def;
    lRetestDate date;
  begin
    -- Màj du statut qualité
    FWK_I_MGT_ENTITY.new(FWK_TYP_STM_ENTITY.gcStmElementNumber, ltElement);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltElement, 'STM_ELEMENT_NUMBER_ID', iElementNumberID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltElement, 'SEM_RETEST_DATE', iRetestDate);
    FWK_I_MGT_ENTITY.UpdateEntity(ltElement);
    FWK_I_MGT_ENTITY.Release(ltElement);
  end ChangeRetestDate;

  /**
  * procedure PublishElementNumber
  * Description
  *    Ajout si besoin de l' ID de l'élément concerné dans la table SHP_TO_PUBLISH pour (re)publication
  */
  procedure PublishElementNumber(iotElementNumber in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lResult  integer;
    lContext varchar2(15) := 'PRODUCT_CHARS';
  begin
    if PCS.PC_CONFIG.GetConfig(aConfigName => 'SHP_SHOP_VERSION', aCompanyID => PCS.PC_I_LIB_SESSION.GetCompanyId, aConliID => null) =
                                                                                                                  SHP_I_LIB_TYPES.gcvExternalShopConnectorValue then
      if iotElementNumber.update_mode = fwk_i_typ_definition.updating then
        if     FWK_I_MGT_ENTITY_DATA.IsModified(iotElementNumber, 'SEM_VALUE')
           and FWK_I_MGT_ENTITY_DATA.IsModified(iotElementNumber, 'C_ELEMENT_TYPE') then
          lResult  :=
            SHP_PRC_PUBLISH.publishRecord(inStpRecID       => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotElementNumber, 'STM_ELEMENT_NUMBER_ID')
                                        , ivStpContext     => lContext
                                        , ivGooWebStatus   => '1'
                                         );
        end if;
      elsif iotElementNumber.update_mode = fwk_i_typ_definition.inserting then
        if     FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotElementNumber, 'C_ELE_NUM_STATUS') in('01', '02', '04')
           and FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotElementNumber, 'C_ELEMENT_TYPE') in('01', '02', '03') then
          lResult  :=
            SHP_PRC_PUBLISH.publishRecord(inStpRecID       => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotElementNumber, 'STM_ELEMENT_NUMBER_ID')
                                        , ivStpContext     => lContext
                                        , ivGooWebStatus   => '1'
                                         );
        end if;
      end if;
    end if;
  end PublishElementNumber;

  /**
  * procedure DeleteStockPosition
  * Description
  *    Suppression des positions de stock du détail de caractérisation supprimé
  */
  procedure DeleteStockPosition(iotElementNumber in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    ltStockPosition  fwk_i_typ_definition.t_crud_def;
    lElementNumberID STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
  begin
    lElementNumberID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotElementNumber, 'STM_ELEMENT_NUMBER_ID');

    -- Parcours et suppression des positions de stock utilisant le numéro de
    -- pièce lot ou version en cours de suppression.
    for tplStockPosition in (select   STM_STOCK_POSITION_ID
                                 from STM_STOCK_POSITION
                                where STM_ELEMENT_NUMBER_ID = lElementNumberID
                                   or STM_STM_ELEMENT_NUMBER_ID = lElementNumberID
                                   or STM2_STM_ELEMENT_NUMBER_ID = lElementNumberID
                             order by GCO_GOOD_ID
                                    , SPO_CHARACTERIZATION_VALUE_1
                                    , SPO_CHARACTERIZATION_VALUE_2
                                    , SPO_CHARACTERIZATION_VALUE_3
                                    , SPO_CHARACTERIZATION_VALUE_4
                                    , SPO_CHARACTERIZATION_VALUE_5
                                    , STM_STOCK_ID
                                    , STM_LOCATION_ID) loop
      FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_STM_ENTITY.gcStmStockPosition, iot_crud_definition => ltStockPosition);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltStockPosition, 'STM_STOCK_POSITION_ID', tplStockPosition.STM_STOCK_POSITION_ID);
      FWK_I_MGT_ENTITY.DeleteEntity(ltStockPosition);
      FWK_I_MGT_ENTITY.Release(ltStockPosition);
    end loop;
  end DeleteStockPosition;

  /**
  * procedure UpdateOldStatus
  * Description
  *    Maj du champ ancien status
  */
  procedure UpdateOldStatus(iotElementNumber in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    lElementNumberID STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    lStatus          STM_ELEMENT_NUMBER.C_ELE_NUM_STATUS%type;
  begin
    lElementNumberID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotElementNumber, 'STM_ELEMENT_NUMBER_ID');

    -- Récupération du statut avant la modification
    select C_ELE_NUM_STATUS
      into lStatus
      from STM_ELEMENT_NUMBER
     where STM_ELEMENT_NUMBER_ID = lElementNumberID;

    -- le status "inactif" n'est pas historié afin que l'élément soit supprimé en cas d'annulation
    if lStatus <> STM_I_LIB_CONSTANT.gcEleNumStatusInactive then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotElementNumber, 'C_OLD_ELE_NUM_STATUS', lStatus);
    end if;
  end;

  /**
  * Description
  *    Dénormalisation du champ STM_ELEMENT_NUMBER_DETAIL_ID sur la position de stock
  */
  procedure DenormalizeElementNumber(iElementNumberId in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type)
  is
    ltStockPosition        fwk_i_typ_definition.t_crud_def;
    lElementNumberDetailId STM_STOCK_POSITION.STM_ELEMENT_NUMBER_DETAIL_ID%type;
  begin
    for tplStockPos in (select STM_STOCK_POSITION_ID
                             , GCO_GOOD_ID
                             , STM_ELEMENT_NUMBER_ID
                             , STM_STM_ELEMENT_NUMBER_ID
                             , STM2_STM_ELEMENT_NUMBER_ID
                          from STM_STOCK_POSITION
                         where iElementNumberId in(STM_ELEMENT_NUMBER_ID, STM_STM_ELEMENT_NUMBER_ID, STM2_STM_ELEMENT_NUMBER_ID) ) loop
      -- Récupérer l'id du détail de caractérisation gérant le détail
      lElementNumberDetailId  :=
        STM_I_LIB_ELEMENT_NUMBER.GetDetailElement(iGoodID    => tplStockPos.GCO_GOOD_ID
                                                , iDetail1   => tplStockPos.STM_ELEMENT_NUMBER_ID
                                                , iDetail2   => tplStockPos.STM_STM_ELEMENT_NUMBER_ID
                                                , iDetail3   => tplStockPos.STM2_STM_ELEMENT_NUMBER_ID
                                                 );
      FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_STM_ENTITY.gcStmStockPosition, iot_crud_definition => ltStockPosition);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltStockPosition, 'STM_STOCK_POSITION_ID', tplStockPos.STM_STOCK_POSITION_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltStockPosition, 'STM_ELEMENT_NUMBER_DETAIL_ID', lElementNumberDetailId);
      FWK_I_MGT_ENTITY.UpdateEntity(ltStockPosition);
      FWK_I_MGT_ENTITY.Release(ltStockPosition);
    end loop;
  end DenormalizeElementNumber;
end STM_PRC_ELEMENT_NUMBER;
