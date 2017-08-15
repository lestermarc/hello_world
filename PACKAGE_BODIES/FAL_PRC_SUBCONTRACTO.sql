--------------------------------------------------------
--  DDL for Package Body FAL_PRC_SUBCONTRACTO
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_SUBCONTRACTO" 
is
  lcProgressMvtCpt    constant varchar2(255) := pcs.PC_CONFIG.GetConfig('FAL_PROGRESS_MVT_CPT');
  lcSubcontractLaunch constant varchar2(255) := pcs.PC_CONFIG.GetConfig('FAL_SUBCONTRACT_LAUNCH');

  -- Curseur servant pour la d�claration du type TOperations pour le traitement des op�rations
  cursor crOperations
  is
    select FAL_SCHEDULE_STEP_ID
         , SCS_STEP_NUMBER
         , TAL_TASK_MANUF_TIME
         , C_RELATION_TYPE
         , FAL_FACTORY_FLOOR_ID
         , SCS_OPEN_TIME_MACHINE
         , TAL_TSK_AD_BALANCE
         , TAL_TSK_W_BALANCE
         , 0 FAC_DAY_CAPACITY
         , SCS_TRANSFERT_TIME
         , TAL_NUM_UNITS_ALLOCATED
         , SCS_DELAY
         , TAL_END_PLAN_DATE
         , TAL_BEGIN_PLAN_DATE
      from FAL_TASK_LINK;

  type TOperations is table of crOperations%rowtype
    index by binary_integer;

  /**
  * procedure ClearLotOperationList
  * Description
  *   Vide la table COM_LIST_ID_TEMP de la liste des op�ration externes
  * @created fp 14.05.2012
  * @lastUpdate
  * @public
  */
  procedure ClearLotOperationList
  is
  begin
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_SCHEDULE_STEP_ID';
  end ClearLotOperationList;

  /**
  * procedure PrepareLotOperationList
  * Description
  *   Rempli la table COM_LIST_ID_TEMP avec la liste des op�ration externes
  * @created fp 10.05.2012
  * @lastUpdate
  * @public
  * @param iLotId : lot de fabrication
  */
  procedure PrepareLotOperationList(iLotId in FAL_LOT.FAL_LOT_ID%type)
  is
  begin
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_SCHEDULE_STEP_ID'
            and LID_FREE_NUMBER_1 = iLotId;

    -- mettre les op�ration externe qui n'ont pas encore de CST dans COM_LIST_ID_TEMP
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
               , LID_FREE_NUMBER_1
               , LID_SELECTION
               , LID_ID_1
               , LID_ID_2
               , LID_FREE_CHAR_1
                )
      select FTL.FAL_SCHEDULE_STEP_ID
           , 'FAL_SCHEDULE_STEP_ID'
           , iLotId
           , case lcSubcontractLaunch
               when '1' then 1
               else 0
             end
           , FTL.PAC_SUPPLIER_PARTNER_ID
           , FTL.GCO_GCO_GOOD_ID
           , GOO.GOO_SECONDARY_REFERENCE
        from FAL_TASK_LINK FTL
           , GCO_GOOD GOO
       where FTL.C_TASK_TYPE = '2'
         and FTL.FAL_LOT_ID = iLotId
         and FTL.GCO_GCO_GOOD_ID = GOO.GCO_GOOD_ID
         and (    (    lcSubcontractLaunch = '1'
                   and ftl.TAL_AVALAIBLE_QTY > 0)
              or (lcSubcontractLaunch <> '1') )
         and not exists(select DOC_POSITION_DETAIL_ID
                          from DOC_POSITION
                         where FAL_SCHEDULE_STEP_ID = FTL.FAL_SCHEDULE_STEP_ID);
  end;

  /**
  * procedure AddUpdateOperationList
  * Description
  *   Ajoute une op�ration externe comme proposition de mise � jour dans la table COM_LIST_ID_TEMP
  */
  procedure AddUpdateOperationList(iFalScheduleStepID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type, iDeltaQty number)
  is
  begin
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
               , LID_FREE_NUMBER_1
               , LID_FREE_NUMBER_2
               , LID_SELECTION
               , LID_ID_1
               , LID_ID_2
               , LID_FREE_CHAR_1
                )
      select iFalScheduleStepID
           , 'FAL_SCHEDULE_STEP_ID'
           , FTL.FAL_LOT_ID
           , iDeltaQty
           , 0
           , FTL.PAC_SUPPLIER_PARTNER_ID
           , FTL.GCO_GCO_GOOD_ID
           , GOO.GOO_SECONDARY_REFERENCE
        from FAL_TASK_LINK FTL
           , GCO_GOOD GOO
       where FTL.C_TASK_TYPE = '2'
         and FTL.FAL_SCHEDULE_STEP_ID = iFalScheduleStepID
         and FTL.GCO_GCO_GOOD_ID = GOO.GCO_GOOD_ID;
  end;

  /**
  * Description
  *   R�cup�ration des informations de g�n�ration des commandes sous-traitance
  */
  procedure GetGenerationInformations(oGeneratedDocuments out pls_integer, oProcessedCommands out pls_integer, oProcessedTools out pls_integer)
  is
  begin
    select count(distinct LID_FREE_NUMBER_5)
         , count(distinct COM_LIST_ID_TEMP_ID)
         , sum(nvl(LID_FREE_NUMBER_3, 0) )
      -- r�cup�rer uniquement la valeur qui est �gale au nombre d'outils ins�r�s.
    into   oGeneratedDocuments
         , oProcessedCommands
         , oProcessedTools
      from COM_LIST_ID_TEMP
     where LID_CODE = 'FAL_SCHEDULE_STEP_ID'
       and LID_SELECTION = 1;
  end GetGenerationInformations;

  /**
  * procedure UpdateSubcontractDelay
  * Description
  *
  * @lastUpdate
  * @public
  * @param  iDocPositionDetailId : Id du d�tail position � mettre � jour
  * @param  iNewDelay            : Nouvelle date de mise � jour
  * @param  iUpdatedDelay        : D�lai � mettre � jour (BASIS, INTER ou FINAL)
  */
  procedure UpdateSubcontractDelay(
    iDocPositionDetailId    in number
  , iNewDelay               in date
  , iUpdatedDelay           in varchar2
  , iCGaugeShowDelay        in varchar2
  , iGapPosDelay            in number
  , iPacThirdCdaId          in number
  , iGcoGoodId              in number
  , iStmStockId             in number
  , iStmStmStockId          in number
  , iCAdminDomain           in varchar2
  , iCGaugeType             in varchar2
  , iGapTransfertProprietor in number
  , iGcoComplDataId         in number
  , iPdeBasisQuantity       in number
  , iScheduleStepId         in number default null
  )
  is
    lvBasisDelay varchar2(10);
    lvInterDelay varchar2(10);
    lvFinalDelay varchar2(10);
    ldBasisDelay date;
    ldInterDelay date;
    ldFinalDelay date;
    ltDetail     FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    lvBasisDelay  := null;
    lvInterDelay  := null;
    lvFinalDelay  := null;
    ldBasisDelay  := iNewDelay;
    ldInterDelay  := iNewDelay;
    ldFinalDelay  := iNewDelay;
    -- Recalcul des d�lais � partir du nouveau d�lai
    DOC_POSITION_DETAIL_FUNCTIONS.GetPDEDelay(aShowDelay             => iCGaugeShowDelay
                                            , aPosDelay              => iGapPosDelay
                                            , aUpdatedDelay          => iUpdatedDelay
                                            , aForward               => case iUpdatedDelay
                                                when 'FINAL' then 0
                                                else 1
                                              end
                                            , aThirdID               => iPacThirdCdaId
                                            , aGoodID                => iGcoGoodId
                                            , aStockID               => iStmStockId
                                            , aTargetStockID         => iStmStmStockId
                                            , aAdminDomain           => iCAdminDomain
                                            , aGaugeType             => iCGaugeType
                                            , aTransfertProprietor   => iGapTransfertProprietor
                                            , aBasisDelayMW          => lvBasisDelay
                                            , aInterDelayMW          => lvInterDelay
                                            , aFinalDelayMW          => lvFinalDelay
                                            , aBasisDelay            => ldBasisDelay
                                            , aInterDelay            => ldInterDelay
                                            , aFinalDelay            => ldFinalDelay
                                            , iComplDataId           => iGcoComplDataId
                                            , iQuantity              => iPdeBasisQuantity
                                            , iScheduleStepId        => iScheduleStepId
                                             );
    -- mise � jour des d�lais recalcul�s des positions de document
    FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocPositionDetail, ltDetail, true, iDocPositionDetailId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltDetail, 'PDE_BASIS_DELAY', ldBasisDelay);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltDetail, 'PDE_INTERMEDIATE_DELAY', ldInterDelay);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltDetail, 'PDE_FINAL_DELAY', ldFinalDelay);
    FWK_I_MGT_ENTITY.UpdateEntity(ltDetail);
    FWK_I_MGT_ENTITY.Release(ltDetail);
  end UpdateSubcontractDelay;

  /**
  * procedure UpdateSubcontractDelay
  * Description
  *
  * @lastUpdate
  * @public
  * @param  iDocPositionDetailId : Id du d�tail position � mettre � jour
  * @param  iNewDelay            : Nouvelle date de mise � jour
  * @param  iUpdatedDelay        : D�lai � mettre � jour (BASIS, INTER ou FINAL)
  */
  procedure UpdateSubcontractDelay(iDocPositionDetailId in number, iNewDelay in date, iUpdatedDelay in varchar2 default 'BASIS')
  is
    cursor crDetail
    is
      select PDE.DOC_POSITION_DETAIL_ID
           , GAP.C_GAUGE_SHOW_DELAY
           , GAP.GAP_POS_DELAY
           , DOC.PAC_THIRD_CDA_ID
           , POS.GCO_GOOD_ID
           , POS.STM_STOCK_ID
           , POS.STM_STM_STOCK_ID
           , GAU.C_ADMIN_DOMAIN
           , GAU.C_GAUGE_TYPE
           , GAP.GAP_TRANSFERT_PROPRIETOR
           , POS.GCO_COMPL_DATA_ID
           , PDE.PDE_BASIS_QUANTITY
           , PDE.FAL_SCHEDULE_STEP_ID
        from DOC_POSITION_DETAIL PDE
           , DOC_POSITION POS
           , DOC_DOCUMENT DOC
           , DOC_GAUGE_POSITION GAP
           , DOC_GAUGE GAU
       where POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
         and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
         and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
         and DOC.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and PDE.DOC_POSITION_DETAIL_ID = iDocPositionDetailId;

    lvBasisDelay varchar2(10);
    lvInterDelay varchar2(10);
    lvFinalDelay varchar2(10);
    ldBasisDelay date;
    ldInterDelay date;
    ldFinalDelay date;
    ltDetail     FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    lvBasisDelay  := null;
    lvInterDelay  := null;
    lvFinalDelay  := null;
    ldBasisDelay  := iNewDelay;
    ldInterDelay  := iNewDelay;
    ldFinalDelay  := iNewDelay;

    for tplDetail in crDetail loop
      -- Recalcul des d�lais � partir du nouveau d�lai
      DOC_POSITION_DETAIL_FUNCTIONS.GetPDEDelay(aShowDelay             => tplDetail.C_GAUGE_SHOW_DELAY
                                              , aPosDelay              => tplDetail.GAP_POS_DELAY
                                              , aUpdatedDelay          => iUpdatedDelay
                                              , aForward               => case iUpdatedDelay
                                                  when 'FINAL' then 0
                                                  else 1
                                                end
                                              , aThirdID               => tplDetail.PAC_THIRD_CDA_ID
                                              , aGoodID                => tplDetail.GCO_GOOD_ID
                                              , aStockID               => tplDetail.STM_STOCK_ID
                                              , aTargetStockID         => tplDetail.STM_STM_STOCK_ID
                                              , aAdminDomain           => tplDetail.C_ADMIN_DOMAIN
                                              , aGaugeType             => tplDetail.C_GAUGE_TYPE
                                              , aTransfertProprietor   => tplDetail.GAP_TRANSFERT_PROPRIETOR
                                              , aBasisDelayMW          => lvBasisDelay
                                              , aInterDelayMW          => lvInterDelay
                                              , aFinalDelayMW          => lvFinalDelay
                                              , aBasisDelay            => ldBasisDelay
                                              , aInterDelay            => ldInterDelay
                                              , aFinalDelay            => ldFinalDelay
                                              , iComplDataId           => tplDetail.GCO_COMPL_DATA_ID
                                              , iQuantity              => tplDetail.PDE_BASIS_QUANTITY
                                              , iScheduleStepId        => tplDetail.FAL_SCHEDULE_STEP_ID
                                               );
      -- mise � jour des d�lais recalcul�s des positions de document
      FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocPositionDetail, ltDetail, true, iDocPositionDetailId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltDetail, 'PDE_BASIS_DELAY', ldBasisDelay);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltDetail, 'PDE_INTERMEDIATE_DELAY', ldInterDelay);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltDetail, 'PDE_FINAL_DELAY', ldFinalDelay);
      FWK_I_MGT_ENTITY.UpdateEntity(ltDetail);
      FWK_I_MGT_ENTITY.Release(ltDetail);
    end loop;
  end UpdateSubcontractDelay;

  /**
  * procedure UpdateSubcontractDelay
  * Description
  *
  * @lastUpdate
  * @public
  * @param  iFalTaskLinkId : Id de l'op�ration mise � jour
  * @param  iNewDelay      : Nouvelle date de mise � jour
  * @param  iUpdatedDelay  : D�lai � mettre � jour (BASIS, INTER ou FINAL)
  */
  procedure UpdateSubcontractDelay(iFalTaskLinkId in number, iNewDelay in date, iUpdatedDelay in varchar2 default 'BASIS')
  is
    cursor crDetail
    is
      select PDE.DOC_POSITION_DETAIL_ID
           , GAP.C_GAUGE_SHOW_DELAY
           , GAP.GAP_POS_DELAY
           , DOC.PAC_THIRD_CDA_ID
           , POS.GCO_GOOD_ID
           , POS.STM_STOCK_ID
           , POS.STM_STM_STOCK_ID
           , GAU.C_ADMIN_DOMAIN
           , GAU.C_GAUGE_TYPE
           , GAP.GAP_TRANSFERT_PROPRIETOR
           , POS.GCO_COMPL_DATA_ID
           , PDE.PDE_BASIS_QUANTITY
        from DOC_POSITION_DETAIL PDE
           , DOC_POSITION POS
           , DOC_DOCUMENT DOC
           , DOC_GAUGE_POSITION GAP
           , DOC_GAUGE GAU
       where POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
         and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
         and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
         and DOC.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and DOC_LIB_SUBCONTRACTO.IsSUOOGauge(DOC.DOC_GAUGE_ID) = 1
         and DOC.C_DOCUMENT_STATUS = '01'
         and POS.FAL_SCHEDULE_STEP_ID = iFalTaskLinkId;
  begin
    for tplDetail in crDetail loop
      UpdateSubcontractDelay(iDocPositionDetailId      => tplDetail.DOC_POSITION_DETAIL_ID
                           , iNewDelay                 => iNewDelay
                           , iUpdatedDelay             => iUpdatedDelay
                           , iCGaugeShowDelay          => tplDetail.C_GAUGE_SHOW_DELAY
                           , iGapPosDelay              => tplDetail.GAP_POS_DELAY
                           , iPacThirdCdaId            => tplDetail.PAC_THIRD_CDA_ID
                           , iGcoGoodId                => tplDetail.GCO_GOOD_ID
                           , iStmStockId               => tplDetail.STM_STOCK_ID
                           , iStmStmStockId            => tplDetail.STM_STM_STOCK_ID
                           , iCAdminDomain             => tplDetail.C_ADMIN_DOMAIN
                           , iCGaugeType               => tplDetail.C_GAUGE_TYPE
                           , iGapTransfertProprietor   => tplDetail.GAP_TRANSFERT_PROPRIETOR
                           , iGcoComplDataId           => tplDetail.GCO_COMPL_DATA_ID
                           , iPdeBasisQuantity         => tplDetail.PDE_BASIS_QUANTITY
                           , iScheduleStepId           => iFalTaskLinkId
                            );
    end loop;
  end UpdateSubcontractDelay;

  /**
  * Description
  *    update manufacturing lot when quantity is modified
  */
  procedure UpdateBatch(
    iPositionDetailId in     DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , iScheduleStepId   in     FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , iBasisDelay       in     DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type
  , iFinalDelay       in     DOC_POSITION_DETAIL.PDE_FINAL_DELAY%type
  , oError            out    varchar2
  )
  is
    lPosBasisDelay DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type;
    lPosFinalDelay DOC_POSITION_DETAIL.PDE_FINAL_DELAY%type;
    lOpeDuration   FAL_TASK_LINK.SCS_PLAN_RATE%type;
    ltCRUD_DEF     FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for ltplData in (select lot.FAL_LOT_ID
                          , lot.C_LOT_STATUS
                          , tal.FAL_SCHEDULE_STEP_ID
                          , tal.PAC_SUPPLIER_PARTNER_ID
                          , tal.SCS_STEP_NUMBER
                          , nvl(tal.C_TASK_TYPE, 0) C_TASK_TYPE
                       from FAL_LOT lot
                          , FAL_TASK_LINK tal
                      where tal.FAL_SCHEDULE_STEP_ID = iScheduleStepId
                        and lot.FAL_LOT_ID = tal.FAL_LOT_ID) loop
      -- contr�le si le lot est modifiable
      if ltplData.C_LOT_STATUS not in(FAL_LIB_BATCH.cLotStatusPlanified, FAL_LIB_BATCH.cLotStatusLaunched) then
        oError  := PCS.PC_FUNCTIONS.TranslateWord('Un ordre de fabrication doit �tre au status "Planifi�" ou "Lanc�" pour �tre modifi�');
        return;
      end if;

      -- batch protection
      FAL_BATCH_RESERVATION.BatchReservation(aFAL_LOT_ID           => ltplData.FAL_LOT_ID
                                           , aLT1_ORACLE_SESSION   => DBMS_SESSION.unique_session_id
                                           , aErrorMsg             => oError
                                            );

      -- We do not continue if an errors occurs while batch reservation process.
      if oError is not null then
        return;
      end if;

      lPosBasisDelay  := iBasisDelay;
      lPosFinalDelay  := iFinalDelay;

      -- Si les conditions ci-dessous sont remplies, la date de d�but de l'op�ration (d�lai de commande) est ramen�e � la date du jour.
      -- Conditions :
      -- 1. l'op�ration est externe
      -- 2. le d�lai de commande est dans le pass�
      -- 3. le lot est lanc�
      -- 4. il existe au moins un CST li�e confirm�e (= avec statut diff�rent de '� confirmer')
      -- 5. toutes les op�rations pr�c�dentes sont r�alis�es (ou l'op�ration est en premi�re position) (Somme TAL_DUE_QTY des op. pr�c�dente = 0)
      if (FAL_LIB_TASK_LINK.doCalculateRemainingTime(iLotId               => ltplData.FAL_LOT_ID
                                                   , iTaskId              => ltplData.FAL_SCHEDULE_STEP_ID
                                                   , itaskType            => ltplData.C_TASK_TYPE
                                                   , iTaskBeginPlanDate   => lPosBasisDelay
                                                    ) = 1
         ) then
        lPosBasisDelay  := trunc(sysdate);
      end if;

      -- On compte le nombre de jour ouvr� entre ltplPosition.PDE_BASIS_DELAY et ltplPosition.PDE_FINAL_DELAY Pour ce calendrier ==> C'est la duree
      -- On enl�ve un jour car pour une dur�e de 5 jours, un calcul le delai de commande + 5 jours ouvr�, sans compter le jour du d�lai de commande.
      -- Ex : 03.07.2015, 5 jours, r�sultat = 10.07.2015. FAL_SCHEDULE_FUNCTIONS.GetDuration retourne (� juste titre) 6 jours entre ces deux dates.
      lOpeDuration    :=
        FAL_SCHEDULE_FUNCTIONS.GetDuration(aFAL_FACTORY_FLOOR_ID      => null
                                         , aPAC_SUPPLIER_PARTNER_ID   => ltplData.PAC_SUPPLIER_PARTNER_ID
                                         , aPAC_CUSTOM_PARTNER_ID     => null
                                         , aPAC_DEPARTMENT_ID         => null
                                         , aHRM_PERSON_ID             => null
                                         , aCalendarId                => null
                                         , aBeginDate                 => lPosBasisDelay
                                         , aEndDate                   => lPosFinalDelay
                                          ) -
        1;

      -- retard
      if nvl(lOpeDuration, 1) <= 1 then
        lOpeDuration    := 1;
        lPosFinalDelay  := lPosBasisDelay;
      end if;

      -- Mise � jour des dates d�but/fin planifi�e et dur�e de l'op�ration externe du lot
      FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcFalTaskLink, ltCRUD_DEF, true, ltplData.FAL_SCHEDULE_STEP_ID, null, 'FAL_SCHEDULE_STEP_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TAL_BEGIN_PLAN_DATE', lPosBasisDelay);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TAL_END_PLAN_DATE', lPosFinalDelay);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TAL_TASK_MANUF_TIME', lOpeDuration);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCS_PLAN_RATE', lOpeDuration);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCS_PLAN_PROP', 0);
      FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);

      begin
        --Planification de l'OF en prenant en compte la date de fin de l'op�ration externe.
        FAL_PLANIF.Planification_Lot(PrmFAL_LOT_ID                   => ltplData.FAL_LOT_ID
                                   , DatePlanification               => null   -- d�fini selon date fin de la t�che aSearchBackwardFromTaskLinkId
                                   , SelonDateDebut                  => FAL_PLANIF.ctDateFin
                                   , MAJReqLiensComposantsLot        => 1
                                   , MAJ_Reseaux_Requise             => 1
                                   , aSearchBackwardFromTaskLinkId   => ltplData.FAL_SCHEDULE_STEP_ID
                                    );
      exception
        when others then
          oError  := sqlerrm;
      end;
    end loop;

    -- batch free protection
    FAL_BATCH_RESERVATION.ReleaseReservedBatches(aSessionId => DBMS_SESSION.unique_session_id);
  end UpdateBatch;

  /**
  * Description :
  *    Modification de la planif/dur�e de l'op�ration externe li�e au d�tail de position suite au changemetn de d�lai sur une commande
  *    de sous-traitance op�ratoire (OU achat !). Pas de message de retour.
  */
  procedure updateCstDelay(iDocPosDetailID in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type)
  is
    lMessage varchar2(32767);
  begin
    updateCstDelay(iDocPosDetailID, 0, lMessage);
  end updateCstDelay;

  /**
  * Description
  *    Modification de la planif/dur�e de l'op�ration externe li�e au d�tail de position suite au changemetn de d�lai sur une commande
  *    de sous-traitance op�ratoire (OU achat !) avec retour d'un message d'information si iDoWarning est � 1
  */
  procedure updateCstDelay(iDocPosDetailID in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type, iDoWarning in integer, iMessage in out varchar2)
  is
    loError         varchar2(4000);
    lScheduleStepId FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type;
    lPositionId     DOC_POSITION.DOC_POSITION_ID%type;
  begin
    -- Message d'avertissement utilisateur
    iMessage         := '';

    -- r�cup�ration de l'identifiant de l'op�ration externe (li�e au lot de la position si sous-traitance achat).
    select DOC_POSITION_ID
      into lPositionId
      from DOC_POSITION_DETAIL
     where DOC_POSITION_DETAIL_ID = iDocPosDetailID;

    lScheduleStepId  := DOC_I_LIB_SUBCONTRACT.getSubcontractOperation(lPositionId);

    -- Si l'identifiant est null, c'est que nous ne sommes pas sur une commande de sous-traitance. Inutile de continuer.
    if lScheduleStepId is null then
      return;
    end if;

    for ltplData in (select trunc(pde.PDE_BASIS_DELAY) PDE_BASIS_DELAY
                          , trunc(pde.PDE_FINAL_DELAY) PDE_FINAL_DELAY
                          , trunc(tal.TAL_BEGIN_PLAN_DATE) TAL_BEGIN_PLAN_DATE
                          , nvl(lot.C_FAB_TYPE, 0) C_FAB_TYPE
                          , lot.FAL_LOT_ID
                       from FAL_TASK_LINK tal
                          , FAL_LOT lot
                          , DOC_POSITION_DETAIL pde
                      where pde.DOC_POSITION_DETAIL_ID = iDocPosDetailID
                        and tal.FAL_SCHEDULE_STEP_ID = lScheduleStepId
                        and tal.FAL_LOT_ID = lot.FAL_LOT_ID) loop
      -- En sous-traitance d'achat, mise � jour uniquement de la date de fin du lot en fonction du nouveau d�lai final.
      if ltplData.C_FAB_TYPE = FAL_BATCH_FUNCTIONS.btSubcontract then
        FAL_PRC_SUBCONTRACTP.UpdateBatch(iPositionDetailId => iDocPosDetailID, oError => loError);

        if     iDoWarning = 1
           and loError is not null then
          iMessage  := loError;
        end if;

        return;
      end if;

      -- sous-traitance op�ratoire.
      if ltplData.TAL_BEGIN_PLAN_DATE is null then
        return;   -- Ne devrait pas arriver ?
      end if;

      if     iDoWarning = 1
         and ltplData.PDE_BASIS_DELAY <> ltplData.TAL_BEGIN_PLAN_DATE then
        iMessage  :=
          PCS.PC_FUNCTIONS.TranslateWord('Le nouveau d�lai de la position est diff�rent de la date de l''op�ration li�e.') ||
          ' ' ||
          PCS.PC_FUNCTIONS.TranslateWord('Souhaitez-vous tout de m�me poursuivre ?') ||
          chr(13) ||
          chr(13) ||
          PCS.PC_FUNCTIONS.TranslateWord
            ('Si "Oui" : le lot sera replanifi� en fonction du nouveau d�lai de la position, mais les d�lais des autres commandes sous-traitance ne seront pas mis � jour.'
            ) ||
          ' ' ||
          PCS.PC_FUNCTIONS.TranslateWord
            ('Le lot devra �tre replanifi� manuellement en se basant sur la nouvelle date de d�but planifi�e de l''OF, de fa�on � synchroniser les autres commandes sous-traitance aux op�rations.'
            );
        return;
      end if;

      loError  := null;
      -- En sous-traitance op�ratoire, modification des dates/dur�e de l'op�ration externe selon nouveaux d�lais et replanification.
      FAL_PRC_SUBCONTRACTO.UpdateBatch(iPositionDetailId   => iDocPosDetailID
                                     , iScheduleStepId     => lScheduleStepId
                                     , iBasisDelay         => ltplData.PDE_BASIS_DELAY
                                     , iFinalDelay         => ltplData.PDE_FINAL_DELAY
                                     , oError              => loError
                                      );
    end loop;
  end updateCstDelay;

  /**
  * Description
  *    Mise � jour d'une op�ration de lot � la confirmation d'un document.
  *    Proc�dure appel�e depuis le trigger DOC_PDE_AU_MOVEMENT.
  */
  procedure updateOpAtPosRecept(
    iDocumentID          in DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , iScheduleStepID      in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , iDocPosDetailID      in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , iDocPosID            in DOC_POSITION_DETAIL.DOC_POSITION_ID%type
  , iPdeBalanceQtyParent in DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY_PARENT%type
  , iQty                 in number
  , iAmount              in number
  , iPdeFinalQty         in number
  , iDocGaugeReceiptId   in DOC_POSITION_DETAIL.DOC_GAUGE_RECEIPT_ID%type
  )
  is
    nSupQty             number          := 0;
    nStmStockMovementId number;
    vDummyErrorMsg      varchar2(32767);
    vDummyErrorCode     varchar2(32767);
  begin
    -- Si qt� suppl autoris�e
    if     FAL_I_LIB_CONSTANT.gcCfgAllowIncreaseQtyMan
       and iPdeBalanceQtyParent < 0 then
      nSupQty  := -iPdeBalanceQtyParent;
    end if;

    FAL_SUIVI_OPERATION.AddProcessTracking(aFalScheduleStepId     => iScheduleStepID
                                         , aFlpDate1              => FWK_I_LIB_ENTITY.getDateFieldFromPk('DOC_DOCUMENT', 'DMT_DATE_DOCUMENT', iDocumentID)
                                         , aFlpProductQty         => iQty
                                         , aFlpSupQty             => nSupQty
                                         , aFlpAmount             => iAmount
                                         , aFlpLabelControl       => FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('DOC_DOCUMENT', 'DMT_NUMBER', iDocumentID)
                                         , aSessionId             => DBMS_SESSION.unique_session_id
                                         , aiShutdownExceptions   => 0
                                         , aErrorMsg              => vDummyErrorMsg
                                         , aDocPositionDetailId   => iDocPosDetailID
                                         , aDocPositionId         => iDocPosID
                                         , aDocGaugeReceiptId     => iDocGaugeReceiptId
                                          );

    -- Recherche mouvement pour comptabilisation des �carts en comptabilit� industrielle
    if PCS.PC_CONFIG.GetConfig('FAL_USE_ACCOUNTING') in('1', '2') then
      begin
        select SMO.STM_STOCK_MOVEMENT_ID
          into nStmStockMovementId
          from STM_STOCK_MOVEMENT SMO
             , STM_MOVEMENT_KIND MOK
         where SMO.DOC_POSITION_DETAIL_ID = iDocPosDetailID
           and SMO.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID
           and MOK.MOK_UPDATE_OP = 1;
      exception
        when others then
          nStmStockMovementId  := null;
      end;

      -- Mise � jour des �l�ments de co�t sous traitance
      FAL_ACCOUNTING_FUNCTIONS.InsertCurrentSubctrctEleCost(aFAL_LOT_ID              => FAL_LIB_TASK_LINK.getFalLotID(iScheduleStepID)
                                                          , aFAL_SCHEDULE_STEP_ID    => iScheduleStepID
                                                          , aSTM_STOCK_MOVEMENT_ID   => nStmStockMovementId
                                                          , aAmount                  => iAmount
                                                          , aQty                     => iPdeFinalQty
                                                           );
    end if;

    -- Mouvements automatiques des composants si requis
    if lcProgressMvtCpt = 1 then
      FAL_SUIVI_OPERATION.SortieComposantsAuSuivi(aFAL_SCHEDULE_STEP_ID   => iScheduleStepID
                                                , aErrorCode              => vDummyErrorCode
                                                , aErrorMsg               => vDummyErrorMsg
                                                , aiShutdownExceptions    => 1
                                                 );
    end if;
  end updateOpAtPosRecept;

  /**
  * Description
  *    Mise � jour de l'op�ration de lot lors du solde de la position de document
  */
  procedure updateOpAtPosBalance(
    iDocumentNumber    in DOC_DOCUMENT.DMT_NUMBER%type
  , iDocumentDate      in DOC_DOCUMENT.DMT_DATE_DOCUMENT%type
  , iBalanceQty        in number
  , iScheduleStepID    in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , iDocPosDetailID    in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , iDocPosID          in DOC_POSITION_DETAIL.DOC_POSITION_ID%type
  , iPdeStPtReject     in DOC_POSITION_DETAIL.PDE_ST_PT_REJECT%type
  , iPdeStCptReject    in DOC_POSITION_DETAIL.PDE_ST_CPT_REJECT%type
  , iDocGaugeReceiptId in DOC_POSITION_DETAIL.DOC_GAUGE_RECEIPT_ID%type
  )
  is
    nFlpPTRejectQty  number;
    nFlpCPTRejectQty number;
    vErrorMsg        varchar2(4000);
    vErrorCode       varchar2(4000);
    lbPTReject       boolean;
    lbCPTReject      boolean;
  begin
    -- Traitement des valeurs par d�faut des champs li�s aux modes de gestion des rebuts en sous-traitance.
    if iPdeStPtReject is null then
      lbPTReject  :=(PCS.PC_CONFIG.GetConfig('FAL_SUBCONTRACT_REJECT') = '2');   -- Type rebuts PT demand�
    else
      lbPTReject  :=(iPdeStPtReject = 1);
    end if;

    if iPdeStCptReject is null then
      lbCPTReject  :=(PCS.PC_CONFIG.GetConfig('FAL_SUBCONTRACT_REJECT') = '1');   -- Type rebuts CPT demand�
    else
      lbCPTReject  :=(iPdeStCptReject = 1);
    end if;

    if lbCPTReject then   -- Rebuts CPT (d�montage)
      nFlpPTRejectQty   := 0;
      nFlpCPTRejectQty  := greatest(iBalanceQty, 0);
    elsif lbPTReject then   -- Rebuts PT
      nFlpPTRejectQty   := greatest(iBalanceQty, 0);
      nFlpCPTRejectQty  := 0;
    else
      -- Cas particulier o� la commande sous-traitance est sold�e mais aucun rebut ne doit �tre appliqu�.
      -- L'op�ration li�e revient avec de la quantit� disponible = � la quantit� sold�e. Il est alors
      -- possible de recr�er une commande sous-traitance pour termin� l'op�ration.
      nFlpPTRejectQty  := 0;
      nFlpPTRejectQty  := 0;
      -- Appel de la proc�dure stock�e de mise-�-jour op�ration suppression
      updateOpAtPosDelete(iScheduleStepID, greatest(iBalanceQty, 0) );
    end if;

    --creation avancement operation sous traitance solde
    FAL_SUIVI_OPERATION.AddProcessTracking(aFalScheduleStepId     => iScheduleStepID
                                         , aFlpDate1              => iDocumentDate
                                         , aFlpPtRejectQty        => nFlpPTRejectQty
                                         , aFlpCptRejectQty       => nFlpCPTRejectQty
                                         , aFlpLabelControl       => iDocumentNumber
                                         , aSessionId             => DBMS_SESSION.unique_session_id
                                         , aiShutdownExceptions   => 0
                                         , aErrorMsg              => vErrorMsg
                                         , aDocPositionDetailId   => iDocPosDetailID
                                         , aDocPositionId         => iDocPosID
                                         , aDocGaugeReceiptId     => iDocGaugeReceiptId
                                          );

    -- Mouvements automatiques des composants si requis
    if lcProgressMvtCpt = 1 then
      FAL_SUIVI_OPERATION.SortieComposantsAuSuivi(aFAL_SCHEDULE_STEP_ID   => iScheduleStepID
                                                , aErrorCode              => vErrorCode
                                                , aErrorMsg               => vErrorMsg
                                                , aiShutdownExceptions    => 1
                                                 );
    end if;
  end updateOpAtPosBalance;

  /**
  * Description
  *    Mise � jour de l'op�ration de lot lors de la g�n�ration d'une position de document
  */
  procedure updateOpAtPosGeneration(
    iScheduleStepID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type
  , iSendingQty     in number
  , iDocumentDate   in date
  , iOnlySubcQty    in integer default 0
  )
  is
    lCrudDef FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for tplOpe in (select TAL_SUBCONTRACT_QTY
                        , TAL_BEGIN_REAL_DATE
                        , TAL_CST_DATE
                        , FAL_LOT_ID
                     from FAL_TASK_LINK
                    where FAL_SCHEDULE_STEP_ID = iScheduleStepID) loop
      FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_FAL_ENTITY.gcFalTaskLink, iot_crud_definition => lCrudDef, iv_primary_col => 'FAL_SCHEDULE_STEP_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumn(lCrudDef, 'FAL_SCHEDULE_STEP_ID', iScheduleStepID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lCrudDef, 'TAL_SUBCONTRACT_QTY', nvl(tplOpe.TAL_SUBCONTRACT_QTY, 0) + iSendingQty);

      if iOnlySubcQty = 0 then
        FWK_I_MGT_ENTITY_DATA.SetColumn(lCrudDef, 'TAL_BEGIN_REAL_DATE', nvl(tplOpe.TAL_BEGIN_REAL_DATE, iDocumentDate) );
        FWK_I_MGT_ENTITY_DATA.SetColumn(lCrudDef, 'TAL_CST_EXIST', 1);
        FWK_I_MGT_ENTITY_DATA.SetColumn(lCrudDef, 'TAL_CST_DATE', nvl(tplOpe.TAL_CST_DATE, sysdate) );
      end if;

      FWK_I_MGT_ENTITY.UpdateEntity(lCrudDef);
      FWK_I_MGT_ENTITY.Release(lCrudDef);
      -- Mise � jour des quantit�s dispo du lot
      FAL_I_PRC_TASK_LINK.UpdateAvailQtyOp(tplOpe.FAL_LOT_ID, iScheduleStepID);
    end loop;
  end updateOpAtPosGeneration;

  /**
  * Description
  *    Mise � jour de l'op�ration de sous-traitance li�e � la position
  */
  procedure UpdateSubcontractOperation(iPositionId in DOC_POSITION.DOC_POSITION_ID%type, iDifQty in number)
  is
  begin
    for tplOpe in (select FAL_SCHEDULE_STEP_ID
                     from DOC_POSITION
                    where DOC_POSITION_ID = iPositionId) loop
      updateOpAtPosGeneration(iScheduleStepID => tplOpe.FAL_SCHEDULE_STEP_ID, iSendingQty => -iDifQty, iDocumentDate => null, iOnlySubcQty => 1);
    end loop;
  end UpdateSubcontractOperation;

  /**
  * Description
  *    Mise � jour de l'op�ration de lot lors de la suppression d'une position de document
  */
  procedure updateOpAtPosDelete(iScheduleStepID in FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%type, iBalanceQty in number)
  is
    lnLotID             FAL_LOT.FAL_LOT_ID%type;
    lnSubcontractQty    FAL_TASK_LINK.TAL_SUBCONTRACT_QTY%type;
    lnReleaseQty        FAL_TASK_LINK.TAL_RELEASE_QTY%type;
    lnNewSubcontractQty FAL_TASK_LINK.TAL_SUBCONTRACT_QTY%type;
  begin
    begin
      select TAL.FAL_LOT_ID
           , nvl(TAL.TAL_SUBCONTRACT_QTY, 0)
           , nvl(TAL_RELEASE_QTY, 0)
        into lnLotID
           , lnSubcontractQty
           , lnReleaseQty
        from FAL_TASK_LINK TAL
       where FAL_SCHEDULE_STEP_ID = iScheduleStepID;
    exception
      when no_data_found then
        lnLotID  := null;
    end;

    if lnLotID is not null then
      -- D�termine la nouvelle quantit� en cours
      lnNewSubcontractQty  := greatest(lnSubcontractQty - iBalanceQty, 0);

      update FAL_TASK_LINK
         set TAL_SUBCONTRACT_QTY = lnNewSubcontractQty
           , TAL_BEGIN_REAL_DATE = case lnReleaseQty + lnNewSubcontractQty
                                    when 0 then null
                                    else TAL_BEGIN_REAL_DATE
                                  end
           , TAL_CONFIRM_DATE = case lnNewSubcontractQty
                                 when 0 then null
                                 else TAL_CONFIRM_DATE
                               end
           , TAL_CONFIRM_DESCR = case lnNewSubcontractQty
                                  when 0 then null
                                  else TAL_CONFIRM_DESCR
                                end
           , TAL_CST_EXIST = case lnNewSubcontractQty + lnReleaseQty
                              when 0 then 0
                              else 1
                            end
           , TAL_CST_DATE = case lnNewSubcontractQty + lnReleaseQty
                             when 0 then null
                             else TAL_CST_DATE
                           end
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_SCHEDULE_STEP_ID = iScheduleStepID;

      -- Mise � jour des quantit�s dispo du lot
      FAL_I_PRC_TASK_LINK.UpdateAvailQtyOp(lnLotID, iScheduleStepID);
    end if;
  end updateOpAtPosDelete;

  /**
  * proc�dure pCheckBackwardTasksForShift
  * Description : Recherche en arri�re de la possibilit� de placer le d�calage
  *
  * @public
  * @param   iBatchId       : Id du lot
  * @param   iDeltaDuration : la dur�e repr�sentant le d�calage � placer
  * @param   iSequence      : La s�quence de l'op�ration � confirmer
  */
  function pCheckBackwardTasksForShift(iIsBatch boolean, iBatchOrPropId number, iDeltaDuration number, iSequence number, iTotalQty number)
    return integer
  is
    tplOperations        TOperations;
    i                    integer;
    bFound               boolean                         := false;
    vTaskDurID           number                          := null;
    vWorkMax             number                          := 0;
    vDurationMax         number                          := 0;
    bOPParallele         boolean                         := false;
    vMinSeq              integer                         := null;
    vMaxSeq              integer                         := null;
    lCurrentTaskDuration number;
    vDelay               number;
    lvSql                varchar2(32767);
    ltCRUD_DEF           FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- R�cup�ration de la commande SQL de recherche des op�rations situ�es en amont entre
    -- l'op�ration � confirmer et une �ventuelle op�ration externe confirm�e.
    lvSql  := FAL_LIB_SUBCONTRACTO.getSqlTasks(iIsBatch => iIsBatch, iBackwardSearch => true);

    execute immediate lvSql
    bulk collect into tplOperations
                using iBatchOrPropId, iSequence, iBatchOrPropId, iSequence;

    -- S'il existe une op�ration externe en amont confirm�e, parcours ascendants des op�rations jusqu'� celle-ci.
    if (tplOperations.count > 0) then
      bFound  := true;

      for i in tplOperations.first .. tplOperations.last loop
        -- Calcul arri�re de la dur�e en (fraction de) jours ouvr�s sur le calendrier de l'op�ration
        -- � partir de sa date de fin planifi�e
        lCurrentTaskDuration  :=
          FAL_PLANIF.GetDurationInDay(tplOperations(i).FAL_FACTORY_FLOOR_ID
                                    , null
                                    , tplOperations(i).TAL_END_PLAN_DATE
                                    , FAL_LIB_TASK_LINK.getMinutesWorkBalance(iC_TASK_TYPE               => '1'
                                                                            , iTAL_TSK_AD_BALANCE        => tplOperations(i).TAL_TSK_AD_BALANCE
                                                                            , iTAL_TSK_W_BALANCE         => tplOperations(i).TAL_TSK_W_BALANCE
                                                                            , iTAL_NUM_UNITS_ALLOCATED   => tplOperations(i).TAL_NUM_UNITS_ALLOCATED
                                                                            , iSCS_TRANSFERT_TIME        => tplOperations(i).SCS_TRANSFERT_TIME
                                                                            , iSCS_OPEN_TIME_MACHINE     => tplOperations(i).SCS_OPEN_TIME_MACHINE
                                                                            , iFAC_DAY_CAPACITY          => tplOperations(i).FAC_DAY_CAPACITY
                                                                             )
                                    , 0
                                     );

        if tplOperations(i).C_RELATION_TYPE not in('2', '4', '5') then   -- successeur
          if bOPParallele then   -- Celle d'avant �tait parrall�le, donc on est sur la premi�re du bloc p// qui est sucesseur.
            if lCurrentTaskDuration > vWorkMax then
              vWorkMax  := lCurrentTaskDuration;
            end if;

            if tplOperations(i).TAL_TASK_MANUF_TIME > vDurationMax then
              vTaskDurID    := tplOperations(i).FAL_SCHEDULE_STEP_ID;
              vDurationMax  := tplOperations(i).TAL_TASK_MANUF_TIME;
            end if;

            vMinSeq       := tplOperations(i).SCS_STEP_NUMBER;
            bOPParallele  := false;
          else
            vTaskDurID    := tplOperations(i).FAL_SCHEDULE_STEP_ID;
            vWorkMax      := lCurrentTaskDuration;
            vDurationMax  := tplOperations(i).TAL_TASK_MANUF_TIME;
            vMinSeq       := tplOperations(i).SCS_STEP_NUMBER;
            vMaxSeq       := tplOperations(i).SCS_STEP_NUMBER;
          end if;
        else
          if not bOPParallele then
            vMaxSeq  := tplOperations(i).SCS_STEP_NUMBER;
          end if;

          bOPParallele  := true;

          if lCurrentTaskDuration > vWorkMax then
            vWorkMax  := lCurrentTaskDuration;
          end if;

          -- Ajout du retard au temps de fabrication
          vDelay        :=
            tplOperations(i).TAL_TASK_MANUF_TIME +
            FAL_PLANIF.GetDurationInDay(tplOperations(i).FAL_FACTORY_FLOOR_ID, null, tplOperations(i).TAL_BEGIN_PLAN_DATE, tplOperations(i).SCS_DELAY, 0);

          if vDelay > vDurationMax then
            vTaskDurID    := tplOperations(i).FAL_SCHEDULE_STEP_ID;
            vDurationMax  := vDelay;
          end if;
        end if;
      end loop;
    end if;

    if bFound then
      if iDeltaDuration > 0 then   -- L'op�ration a �t� d�plac�e en avant
        -- MAJ de la dur�e de la t�che avec la plus grande dur�e
        if iIsBatch then
          FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcFalTaskLink, ltCRUD_DEF, true, vTaskDurID, null, 'FAL_SCHEDULE_STEP_ID');
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF
                                        , 'SCS_PLAN_RATE'
                                        , nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_DEF, 'TAL_TASK_MANUF_TIME'), 0) + iDeltaDuration
                                         );
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCS_PLAN_PROP', 0);
          FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
          FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
        else
          FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcFalTaskLinkProp, ltCRUD_DEF, true, vTaskDurID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF
                                        , 'SCS_PLAN_RATE'
                                        , nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_DEF, 'TAL_TASK_MANUF_TIME'), 0) + iDeltaDuration
                                         );
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCS_PLAN_PROP', 0);
          FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
          FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
        end if;

        -- L'attribution du d�calage a �t� effectu� en aval de l'op�ration
        return 1;   -- On a pu placer le d�calage positif en arri�re
      else
        if (vDurationMax - vWorkMax) >= abs(iDeltaDuration) then
          -- MAJ de la dur�e de la t�che
          if iIsBatch then
            for ltplTask in (select FAL_SCHEDULE_STEP_ID
                                  , FAL_FACTORY_FLOOR_ID
                                  , TAL_BEGIN_PLAN_DATE
                                  , nvl(SCS_DELAY, 0) SCS_DELAY
                               from FAL_TASK_LINK
                              where FAL_LOT_ID = iBatchOrPropId
                                and SCS_STEP_NUMBER >= vMinSeq
                                and SCS_STEP_NUMBER <= vMaxSeq
                                and (nvl(TAL_TASK_MANUF_TIME, 0) +
                                     FAL_PLANIF.GetDurationInDay(FAL_FACTORY_FLOOR_ID, null, TAL_BEGIN_PLAN_DATE, nvl(SCS_DELAY, 0), 0)
                                    ) >(vDurationMax - abs(iDeltaDuration) ) ) loop
              FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcFalTaskLink, ltCRUD_DEF, true, ltplTask.FAL_SCHEDULE_STEP_ID, null, 'FAL_SCHEDULE_STEP_ID');
              FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF
                                            , 'SCS_PLAN_RATE'
                                            , vDurationMax -
                                              abs(iDeltaDuration) -
                                              FAL_PLANIF.GetDurationInDay(ltplTask.FAL_FACTORY_FLOOR_ID
                                                                        , null
                                                                        , ltplTask.TAL_BEGIN_PLAN_DATE
                                                                        , ltplTask.SCS_DELAY
                                                                        , 0
                                                                         )
                                             );
              FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCS_PLAN_PROP', 0);
              FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
              FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
            end loop;
          else
            for ltplTask in (select FAL_TASK_LINK_PROP_ID
                                  , FAL_FACTORY_FLOOR_ID
                                  , TAL_BEGIN_PLAN_DATE
                                  , nvl(SCS_DELAY, 0) SCS_DELAY
                               from FAL_TASK_LINK_PROP
                              where FAL_LOT_PROP_ID = iBatchOrPropId
                                and SCS_STEP_NUMBER >= vMinSeq
                                and SCS_STEP_NUMBER <= vMaxSeq
                                and (nvl(TAL_TASK_MANUF_TIME, 0) +
                                     FAL_PLANIF.GetDurationInDay(FAL_FACTORY_FLOOR_ID, null, TAL_BEGIN_PLAN_DATE, nvl(SCS_DELAY, 0), 0)
                                    ) >(vDurationMax - abs(iDeltaDuration) ) ) loop
              FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcFalTaskLinkProp, ltCRUD_DEF, true, ltplTask.FAL_TASK_LINK_PROP_ID);
              FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF
                                            , 'SCS_PLAN_RATE'
                                            , vDurationMax -
                                              abs(iDeltaDuration) -
                                              FAL_PLANIF.GetDurationInDay(ltplTask.FAL_FACTORY_FLOOR_ID
                                                                        , null
                                                                        , ltplTask.TAL_BEGIN_PLAN_DATE
                                                                        , ltplTask.SCS_DELAY
                                                                        , 0
                                                                         )
                                             );
              FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCS_PLAN_PROP', 0);
              FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
              FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
            end loop;
          end if;

          -- L'attribution du d�calage a �t� effectu� en amont de l'op�ration
          return 1;
        else
          -- L'attribution du d�calage n'a pas pu �tre effectu�e en raison d'une autre commande existante..
          raise_application_error(-20001, 'Error - Impossible to confirm the task with this date');
        end if;
      end if;
    end if;

    return 0;
  end pCheckBackwardTasksForShift;

  function pCheckForwardTasksForShift(iIsBatch in boolean, iBatchOrPropId number, iDeltaDuration in number, iSequence in integer, iTotalQty number)
    return integer
  is
    tplOperations        TOperations;
    bFound               boolean                         := false;
    vTaskDurID           number                          := null;
    vWorkMax             number                          := 0;
    vDurationMax         number                          := 0;
    vMinSeq              integer                         := null;
    vMaxSeq              integer                         := null;
    lCurrentTaskDuration number;
    vDelay               number;
    lvSql                varchar2(32000);
    ltCRUD_DEF           FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- R�cup�ration de la commande SQL de recherche des op�rations situ�es en aval entre
    -- l'op�ration � confirmer et une �ventuelle op�ration externe confirm�e.
    lvSql  := FAL_LIB_SUBCONTRACTO.getSqlTasks(iIsBatch => iIsBatch, iBackwardSearch => false);

    execute immediate lvSql
    bulk collect into tplOperations
                using iBatchOrPropId, iSequence, iBatchOrPropId, iSequence;

    -- S'il existe une op�ration externe en aval confirm�e, parcours descendants des op�rations jusqu'� celle-ci.
    if (tplOperations.count > 0) then
      bFound  := true;

      for i in tplOperations.first .. tplOperations.last loop
        -- Calcul avant de la dur�e en (fraction de) jours ouvr�s sur le calendrier de l'op�ration
        -- � partir de sa date de d�but planifi�e
        lCurrentTaskDuration  :=
          FAL_PLANIF.GetDurationInDay(tplOperations(i).FAL_FACTORY_FLOOR_ID
                                    , null
                                    , tplOperations(i).TAL_BEGIN_PLAN_DATE
                                    , FAL_LIB_TASK_LINK.getMinutesWorkBalance(iC_TASK_TYPE               => '1'
                                                                            , iTAL_TSK_AD_BALANCE        => tplOperations(i).TAL_TSK_AD_BALANCE
                                                                            , iTAL_TSK_W_BALANCE         => tplOperations(i).TAL_TSK_W_BALANCE
                                                                            , iTAL_NUM_UNITS_ALLOCATED   => tplOperations(i).TAL_NUM_UNITS_ALLOCATED
                                                                            , iSCS_TRANSFERT_TIME        => tplOperations(i).SCS_TRANSFERT_TIME
                                                                            , iSCS_OPEN_TIME_MACHINE     => tplOperations(i).SCS_OPEN_TIME_MACHINE
                                                                            , iFAC_DAY_CAPACITY          => tplOperations(i).FAC_DAY_CAPACITY
                                                                             )
                                    , 1
                                     );

        if tplOperations(i).C_RELATION_TYPE not in('2', '4', '5') then
          vTaskDurID    := tplOperations(i).FAL_SCHEDULE_STEP_ID;
          vWorkMax      := lCurrentTaskDuration;
          vDurationMax  := tplOperations(i).TAL_TASK_MANUF_TIME;
          vMinSeq       := tplOperations(i).SCS_STEP_NUMBER;
          vMaxSeq       := tplOperations(i).SCS_STEP_NUMBER;
        else
          vMaxSeq  := tplOperations(i).SCS_STEP_NUMBER;

          if lCurrentTaskDuration > vWorkMax then
            vWorkMax  := lCurrentTaskDuration;
          end if;

          -- Ajout du retard au temps de fabrication
          vDelay   :=
            tplOperations(i).TAL_TASK_MANUF_TIME +
            FAL_PLANIF.GetDurationInDay(tplOperations(i).FAL_FACTORY_FLOOR_ID, null, tplOperations(i).TAL_END_PLAN_DATE, nvl(tplOperations(i).SCS_DELAY, 0)
                                      , 1);

          if vDelay > vDurationMax then
            vTaskDurID    := tplOperations(i).FAL_SCHEDULE_STEP_ID;
            vDurationMax  := vDelay;
          end if;
        end if;
      end loop;
    end if;

    if bFound then
      if iDeltaDuration < 0 then   -- L'op�ration a �t� d�plac�e en arri�re
        -- MAJ de la dur�e de la t�che avec la plus grande dur�e
        if iIsBatch then
          FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcFalTaskLink, ltCRUD_DEF, true, vTaskDurID, null, 'FAL_SCHEDULE_STEP_ID');
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF
                                        , 'SCS_PLAN_RATE'
                                        , nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_DEF, 'TAL_TASK_MANUF_TIME'), 0) + abs(iDeltaDuration)
                                         );
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCS_PLAN_PROP', 0);
          FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
          FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
        else
          FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcFalTaskLinkProp, ltCRUD_DEF, true, vTaskDurID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF
                                        , 'SCS_PLAN_RATE'
                                        , nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_DEF, 'TAL_TASK_MANUF_TIME'), 0) + abs(iDeltaDuration)
                                         );
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCS_PLAN_PROP', 0);
          FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
          FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
        end if;

        -- L'attribution du decalage a �t� effectu� en amont de l'op�ration
        return 1;
      else   -- L'op�ration a �t� d�plac�e en avant
        if (vDurationMax - vWorkMax) >= abs(iDeltaDuration) then
          -- MAJ de la dur�e de la t�che
          if iIsBatch then
            for ltplTask in (select FAL_SCHEDULE_STEP_ID
                                  , FAL_FACTORY_FLOOR_ID
                                  , TAL_END_PLAN_DATE
                                  , nvl(SCS_DELAY, 0) SCS_DELAY
                               from FAL_TASK_LINK
                              where FAL_LOT_ID = iBatchOrPropId
                                and SCS_STEP_NUMBER >= vMinSeq
                                and SCS_STEP_NUMBER <= vMaxSeq
                                and (nvl(TAL_TASK_MANUF_TIME, 0) +
                                     FAL_PLANIF.GetDurationInDay(FAL_FACTORY_FLOOR_ID, null, TAL_END_PLAN_DATE, nvl(SCS_DELAY, 0), 1)
                                    ) >(vDurationMax - abs(iDeltaDuration) ) ) loop
              FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcFalTaskLink, ltCRUD_DEF, true, ltplTask.FAL_SCHEDULE_STEP_ID, null, 'FAL_SCHEDULE_STEP_ID');
              FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF
                                            , 'SCS_PLAN_RATE'
                                            , vDurationMax -
                                              abs(iDeltaDuration) -
                                              FAL_PLANIF.GetDurationInDay(ltplTask.FAL_FACTORY_FLOOR_ID
                                                                        , null
                                                                        , ltplTask.TAL_END_PLAN_DATE
                                                                        , ltplTask.SCS_DELAY
                                                                        , 1
                                                                         )
                                             );
              FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCS_PLAN_PROP', 0);
              FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
              FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
            end loop;
          else
            for ltplTask in (select FAL_TASK_LINK_PROP_ID
                                  , FAL_FACTORY_FLOOR_ID
                                  , TAL_END_PLAN_DATE
                                  , nvl(SCS_DELAY, 0) SCS_DELAY
                               from FAL_TASK_LINK_PROP
                              where FAL_LOT_PROP_ID = iBatchOrPropId
                                and SCS_STEP_NUMBER >= vMinSeq
                                and SCS_STEP_NUMBER <= vMaxSeq
                                and (nvl(TAL_TASK_MANUF_TIME, 0) +
                                     FAL_PLANIF.GetDurationInDay(FAL_FACTORY_FLOOR_ID, null, TAL_END_PLAN_DATE, nvl(SCS_DELAY, 0), 1)
                                    ) >(vDurationMax - abs(iDeltaDuration) ) ) loop
              FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcFalTaskLinkProp, ltCRUD_DEF, true, ltplTask.FAL_TASK_LINK_PROP_ID);
              FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF
                                            , 'SCS_PLAN_RATE'
                                            , vDurationMax -
                                              abs(iDeltaDuration) -
                                              FAL_PLANIF.GetDurationInDay(ltplTask.FAL_FACTORY_FLOOR_ID
                                                                        , null
                                                                        , ltplTask.TAL_END_PLAN_DATE
                                                                        , ltplTask.SCS_DELAY
                                                                        , 1
                                                                         )
                                             );
              FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'SCS_PLAN_PROP', 0);
              FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
              FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
            end loop;
          end if;

          -- L'attribution du d�calage a �t� effectu�e en aval de l'op�ration
          return 1;
        else
          -- L'attribution n'a pas pu �tre effectu�e en raison d'une autre commande existante.
          raise_application_error(-20001, 'Error - Impossible to confirm the task with this date');
        end if;
      end if;
    end if;

    return 0;
  end pCheckForwardTasksForShift;

  /**
  * proc�dure ConfirmExternalTask
  * Description : D�termine si le d�calage d'une op�ration externe est possible au moment
  *   de sa confirmation
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aTaskID     : Id op�ration de lot
  * @param   aDate       : Nouveau d�lai confirm�
  * @param   aSendDate   : Date envoi
  * @param   aContext    : Portefeuille ou g�n�ration de commande.
  */
  procedure ConfirmExternalTask(
    aTaskID       in number
  , aDate         in date
  , aSendDate     in date
  , aContext      in number
  , iConfirmDescr in FAL_TASK_LINK.TAL_CONFIRM_DESCR%type default null
  )
  is
    cursor crBatchInfo
    is
      select 1 IS_BATCH
           , OPE.FAL_LOT_ID id
           , OPE.PAC_SUPPLIER_PARTNER_ID
           , OPE.SCS_STEP_NUMBER
           , OPE.TAL_END_PLAN_DATE
           , nvl(LOT.LOT_TOTAL_QTY, 0) LOT_TOTAL_QTY
           , LOT.C_SCHEDULE_PLANNING
        from FAL_TASK_LINK OPE
           , FAL_LOT LOT
       where LOT.FAL_LOT_ID = OPE.FAL_LOT_ID
         and FAL_SCHEDULE_STEP_ID = aTaskID
      union
      select 0 IS_BATCH
           , OPE.FAL_LOT_PROP_ID
           , OPE.PAC_SUPPLIER_PARTNER_ID
           , OPE.SCS_STEP_NUMBER
           , OPE.TAL_END_PLAN_DATE
           , nvl(LOT.LOT_TOTAL_QTY, 0)
           , LOT.C_SCHEDULE_PLANNING
        from FAL_TASK_LINK_PROP OPE
           , FAL_LOT_PROP LOT
       where LOT.FAL_LOT_PROP_ID = OPE.FAL_LOT_PROP_ID
         and FAL_TASK_LINK_PROP_ID = aTaskID;

    tplBatchInfo    crBatchInfo%rowtype;
    vDeltaDuration  number                          := 0;
    ldBatchEndDate  date;
    lBackwardAttrib integer;
    lForwardAttrib  integer;
    ltCRUD_DEF      FWK_I_TYP_DEFINITION.t_crud_def;
    lSavePoint      varchar2(4000)                  := 'FAL_PRC_SUBCONTRACTO-' || to_char(sysdate, 'HH24MISS');
  begin
    savepoint lSavePoint;

    -- R�cup�ration des infos sur l'op�ration � traiter
    open crBatchInfo;

    fetch crBatchInfo
     into tplBatchInfo;

    close crBatchInfo;

    /* if new delay is the same than end date of the task, we do nothing. Nothing has changed */
    if trunc(aDate) <> trunc(tplBatchInfo.TAL_END_PLAN_DATE) then
      -- Calcul d�calage (en jours ouvr�) entre l'ancienne date de fin de l'op�ration et le nouveau d�lai confirm�
      if tplBatchInfo.C_SCHEDULE_PLANNING <> '1' then
        vDeltaDuration  :=
          FAL_PLANIF.GetDurationInDay(FalFactoryFloorId      => null
                                    , PacSupplierPartnerId   => tplBatchInfo.PAC_SUPPLIER_PARTNER_ID
                                    , BeginDate              => nvl(tplBatchInfo.TAL_END_PLAN_DATE, aDate)   -- date d'envoi
                                    , EndDate                => aDate   -- nouveau d�lai confirm�
                                     );
      end if;

      -- V�rification de la n�cessit� d'effectuer un d�calage
      if vDeltaDuration <> 0 then   -- On a d�plac� l'op�ration de X jours
        -- Recherche en arri�re la possibilit� de placer le d�calage
        lBackwardAttrib  :=
          pCheckBackwardTasksForShift(iIsBatch         => (tplBatchInfo.IS_BATCH = 1)
                                    , iBatchOrPropId   => tplBatchInfo.id
                                    , iDeltaDuration   => vDeltaDuration
                                    , iSequence        => tplBatchInfo.SCS_STEP_NUMBER
                                    , iTotalQty        => tplBatchInfo.LOT_TOTAL_QTY
                                     );
        -- Recherche en avant de la possibilit� de placer le d�calage
        lForwardAttrib   :=
          pCheckForwardTasksForShift(iIsBatch         => (tplBatchInfo.IS_BATCH = 1)
                                   , iBatchOrPropId   => tplBatchInfo.id
                                   , iDeltaDuration   => vDeltaDuration
                                   , iSequence        => tplBatchInfo.SCS_STEP_NUMBER
                                   , iTotalQty        => tplBatchInfo.LOT_TOTAL_QTY
                                    );
      end if;

      if lForwardAttrib = 1 then
        -- Planification arri�re pour tenir compte du d�calage
        if tplBatchInfo.IS_BATCH = 1 then
          -- Planification arri�re avec le d�calage (a partir de la date fin de la derni�re op�ration)
          FAL_PLANIF.Planification_Lot(prmFAL_LOT_ID              => tplBatchInfo.id
                                     , DatePlanification          => null
                                     , SelonDateDebut             => 0
                                     , MAJReqLiensComposantsLot   => 1
                                     , MAJ_Reseaux_Requise        => 0
                                     , aDoHistorisationPlanif     => 1
                                     , aSearchFromEndOfDay        => 0
                                      );
        else
          FAL_PLANIF.Planification_Lot_Prop(PrmFAL_LOT_PROP_ID          => tplBatchInfo.id
                                          , DatePlanification           => null
                                          , SelonDateDebut              => 0
                                          , MAJReqLiensComposantsProp   => 1
                                          , MAJ_Reseaux_Requise         => 0
                                           );
        end if;
      else
        ldBatchEndDate  :=
          FAL_PLANIF.searchBatchEndDate(iNewTaskEndDate   => trunc(aDate) +(tplBatchInfo.TAL_END_PLAN_DATE - trunc(tplBatchInfo.TAL_END_PLAN_DATE) )
                                      , iTaskSeq          => tplBatchInfo.SCS_STEP_NUMBER
                                      , iBatchOrPropId    => tplBatchInfo.id
                                       );

        if tplBatchInfo.IS_BATCH = 1 then
          -- Planification arri�re avec le d�calage (a partir de la date fin de l'OF, la date de la derni�re op�ration
          -- n'ayant pas encore �t� mise � jour)
          FAL_PLANIF.Planification_Lot(prmFAL_LOT_ID              => tplBatchInfo.id
                                     , DatePlanification          => ldBatchEndDate
                                     , SelonDateDebut             => 0
                                     , MAJReqLiensComposantsLot   => 1
                                     , MAJ_Reseaux_Requise        => 0
                                     , aDoHistorisationPlanif     => 1
                                     , aSearchFromEndOfDay        => 0
                                      );
        else
          FAL_PLANIF.Planification_Lot_Prop(PrmFAL_LOT_PROP_ID          => tplBatchInfo.id
                                          , DatePlanification           => ldBatchEndDate
                                          , SelonDateDebut              => 0
                                          , MAJReqLiensComposantsProp   => 1
                                          , MAJ_Reseaux_Requise         => 0
                                           );
        end if;
      end if;
    end if;

    if tplBatchInfo.IS_BATCH = 1 then
      FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcFalTaskLink, ltCRUD_DEF, true, aTaskID, null, 'FAL_SCHEDULE_STEP_ID');

      if aContext = ctxOrderGen then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TAL_BEGIN_REAL_DATE', FWK_I_MGT_ENTITY_DATA.GetColumnDate(ltCRUD_DEF, 'TAL_BEGIN_PLAN_DATE') );

        if trunc(aDate) <> trunc(tplBatchInfo.TAL_END_PLAN_DATE) then
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TAL_CONFIRM_DESCR', iConfirmDescr);
        end if;
      else
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TAL_CONFIRM_DESCR', iConfirmDescr);
      end if;

      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TAL_CONFIRM_DATE', sysdate);
      FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    else
      FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcFalTaskLinkProp, ltCRUD_DEF, true, aTaskID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TAL_CONFIRM_DESCR', iConfirmDescr);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'TAL_CONFIRM_DATE', sysdate);
      FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    end if;

    -- Mise � jour R�seaux
    if tplBatchInfo.IS_BATCH = 1 then
      FAL_NETWORK.MiseAJourReseaux(tplBatchInfo.id, FAL_NETWORK.ncPlannificationLot, '');
    else
      FAL_NETWORK.MiseAJourReseaux(tplBatchInfo.id, FAL_NETWORK.ncPlanificationLotProp, '');
    end if;
  exception
    when others then
      rollback to savepoint lSavePoint;
      raise;
  end ConfirmExternalTask;
end FAL_PRC_SUBCONTRACTO;
