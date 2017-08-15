--------------------------------------------------------
--  DDL for Package Body FAL_LOT_ARCHIVAGE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LOT_ARCHIVAGE" 
is
  cUseAccounting constant integer := to_number(PCS.PC_CONFIG.GetConfig('FAL_USE_ACCOUNTING') );

  /**
  * procedure InsertWarningMsg
  * Description : Reporting des avertissements d'archivage
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param iBatchRef : Référence lot concerné
  * @param iWarningMsg : Message d'avertissement
  */
  procedure InsertWarningMsg(iBatchRef in varchar2, iWarningMsg in varchar2)
  is
  begin
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
               , LID_FREE_CHAR_1
               , LID_DESCRIPTION
                )
         values (GetNewId
               , 'BATCH_ARCHIVE'
               , iBatchRef
               , iWarningMsg
                );
  end InsertWarningMsg;

  /**
  * procedure ControlBeforeArchive
  * Description : Contrôles effectués avant archivage du lot de fabrication.
  *               Vérifie la possibilité d'archiver le lot ou pas.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iFAL_LOT_ID         Lot
  * @param   iLOT_FULL_REL_DTE   Date fin lot maximum
  * @param   ioDoArchive         Archivage?
  * @param   iPreviousFAL_LOT_ID Lot père dans l'arbre des lots éclatés.
  */
  procedure ControlBeforeArchive(
    iFAL_LOT_ID         in     FAL_LOT.FAL_LOT_ID%type
  , iLOT_FULL_REL_DTE   in     date
  , ioDoArchive         in out boolean
  , iPreviousFAL_LOT_ID in     FAL_LOT.FAL_LOT_ID%type
  )
  is
    DocumentNotFinished   number;
    liLotIsPostCalculated integer;
    lvLotRefcompl         FAL_LOT.LOT_REFCOMPL%type;
  begin
    -- Recherche caractéristiques du lot
    if ioDoArchive then
      begin
        select LOT.LOT_REFCOMPL
             , nvl(LOT.LOT_IS_POSTCALCULATED, 0) LOT_IS_POSTCALCULATED
          into lvLotRefcompl
             , liLotIsPostCalculated
          from FAL_LOT LOT
         where LOT.FAL_LOT_ID = iFAL_LOT_ID;
      exception
        when no_data_found then
          ioDoArchive  := false;
      end;

      -- Lot Compta indus non-postacalculé
      if     (   cUseAccounting = 1
              or cUseAccounting = 2)
         and liLotIsPostCalculated = 0 then
        InsertWarningMsg(lvLotRefcompl, PCS.PC_FUNCTIONS.TranslateWord('Lot utilisé en comptabilité industrielle. Il doit être postcalculé avant archivage!') );
        ioDoArchive  := false;
      end if;

      -- On interdit l'archivage des lots qui ont des opérations liées à des documents
      -- 'à confirmer', 'à solder' ou 'soldé partiellement'
      if ioDoArchive = true then
        select count(DET.DOC_POSITION_DETAIL_ID)
          into DocumentNotFinished
          from DOC_DOCUMENT DOC
             , DOC_POSITION POS
             , DOC_POSITION_DETAIL DET
         where DET.FAL_SCHEDULE_STEP_ID in(select FAL_SCHEDULE_STEP_ID
                                             from FAL_TASK_LINK
                                            where FAL_LOT_ID = iFAL_LOT_ID)
           and POS.DOC_POSITION_ID = DET.DOC_POSITION_ID
           and DOC.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and C_DOCUMENT_STATUS in('01', '02', '03');

        if DocumentNotFinished > 0 then
          InsertWarningMsg(lvLotRefcompl, PCS.PC_FUNCTIONS.TranslateWord('Lot avec opération liée à un document non soldé. Il ne peut être archivé!') );
          ioDoArchive  := false;
        end if;
      end if;

      -- On interdit l'archivage des lots de sous-traitance d'achat liés à des
      -- des documents 'à confirmer', 'à solder' ou 'soldé partiellement'
      if ioDoArchive = true then
        select count(POS.DOC_POSITION_ID)
          into DocumentNotFinished
          from DOC_DOCUMENT DMT
             , DOC_POSITION POS
             , DOC_POSITION_DETAIL PDE
         where PDE.FAL_LOT_ID = iFAL_LOT_ID
           and PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID
           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and DMT.C_DOCUMENT_STATUS in('01', '02', '03');

        if DocumentNotFinished > 0 then
          InsertWarningMsg(lvLotRefcompl, PCS.PC_FUNCTIONS.TranslateWord('Lot sous-traitance d''achat lié à un document non soldé. Il ne peut être archivé!') );
          ioDoArchive  := false;
        end if;
      end if;
    end if;
  end ControlBeforeArchive;

  /**
  * procedure SetHistoLotWithHistoLotHist
  * Description : Switch des historiques de lots sur les lots archivés
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param iFAL_LOT_ID: Lot
  */
  procedure SetHistoLotWithHistoLotHist(iFAL_LOT_ID in number)
  is
  begin
    update FAL_HISTO_LOT
       set FAL_LOT_HIST1_ID = FAL_LOT1_ID
         , FAL_LOT1_ID = null
     where FAL_LOT1_ID = iFAL_LOT_ID;

    update FAL_HISTO_LOT
       set FAL_LOT_HIST4_ID = FAL_LOT4_ID
         , FAL_LOT4_ID = null
     where FAL_LOT4_ID = iFAL_LOT_ID;

    update FAL_HISTO_LOT_HIST
       set FAL_LOT_HIST1_ID = FAL_LOT1_ID
         , FAL_LOT1_ID = null
     where FAL_LOT1_ID = iFAL_LOT_ID;

    update FAL_HISTO_LOT_HIST
       set FAL_LOT_HIST4_ID = FAL_LOT4_ID
         , FAL_LOT4_ID = null
     where FAL_LOT4_ID = iFAL_LOT_ID;
  end SetHistoLotWithHistoLotHist;

  /**
  * procedure SetFalWeighWithLotHist
  * Description : Switch des pesées et pesées archivées sur les lots archivés
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param iFAL_LOT_ID: Lot
  */
  procedure SetFalWeighWithLotHist(iFAL_LOT_ID in number)
  is
    cursor CUR_FAL_SCHEDULE_STEP
    is
      select FAL_SCHEDULE_STEP_ID
           , SCS_STEP_NUMBER
        from FAL_TASK_LINK
       where FAL_LOT_ID = iFAL_LOT_ID;

    cursor CUR_FAL_LOT_PROGRESS
    is
      select FAL_LOT_PROGRESS_ID
        from FAL_LOT_PROGRESS
       where FAL_LOT_ID = iFAL_LOT_ID;

    CurFalLotProgress  CUR_FAL_LOT_PROGRESS%rowtype;
    CurFalScheduleStep CUR_FAL_SCHEDULE_STEP%rowtype;
  begin
    -- Update pesées FAL_LOT_ID -> FAL_LOT_HIST_ID .
    update FAL_WEIGH
       set FAL_LOT_ID = null
         , FAL_LOT_DETAIL_ID = null
         , FAL_LOT_HIST_ID = iFAL_LOT_ID
         , FAL_FAL_LOT_MAT_LINK_HIST_ID = FAL_LOT_MATERIAL_LINK_ID
         , FAL_LOT_MATERIAL_LINK_ID = null
         , LOT_REFCOMPL = null
         , LOT_REFCOMPL_HIST = (select LOT_REFCOMPL
                                  from FAL_LOT
                                 where FAL_LOT_ID = iFAL_LOT_ID)
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_LOT_ID = iFAL_LOT_ID;

    -- Update pesées archivées FAL_LOT_ID -> FAL_LOT_HIST_ID .
    update FAL_WEIGH_HIST
       set FAL_LOT_ID = null
         , FAL_LOT_DETAIL_ID = null
         , FAL_LOT_HIST_ID = iFAL_LOT_ID
         , FAL_FAL_LOT_MAT_LINK_HIST_ID = FAL_LOT_MATERIAL_LINK_ID
         , FAL_LOT_MATERIAL_LINK_ID = null
         , LOT_REFCOMPL = null
         , LOT_REFCOMPL_HIST = (select LOT_REFCOMPL
                                  from FAL_LOT
                                 where FAL_LOT_ID = iFAL_LOT_ID)
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_LOT_ID = iFAL_LOT_ID;

    -- Update FAL_SCHEDULE_STEP_ID.
    for CurFalScheduleStep in CUR_FAL_SCHEDULE_STEP loop
      -- pesées
      update FAL_WEIGH
         set FAL_FAL_SCHEDULE_STEP_ID = CurFalScheduleStep.FAL_SCHEDULE_STEP_ID
           , FAL_SCHEDULE_STEP_ID = null
           , SCS_STEP_NUMBER_HIST = CurFalScheduleStep.SCS_STEP_NUMBER
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_SCHEDULE_STEP_ID = CurFalScheduleStep.FAL_SCHEDULE_STEP_ID;

      -- pesées archivées
      update FAL_WEIGH_HIST
         set FAL_FAL_SCHEDULE_STEP_ID = CurFalScheduleStep.FAL_SCHEDULE_STEP_ID
           , FAL_SCHEDULE_STEP_ID = null
           , SCS_STEP_NUMBER_HIST = CurFalScheduleStep.SCS_STEP_NUMBER
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_SCHEDULE_STEP_ID = CurFalScheduleStep.FAL_SCHEDULE_STEP_ID;
    end loop;

    -- Update FAL_LOT_PROGRESS_ID
    for CurFalLotProgress in CUR_FAL_LOT_PROGRESS loop
      -- pesées
      update FAL_WEIGH
         set FAL_LOT_PROGRESS_HIST_ID = CurFalLotProgress.FAL_LOT_PROGRESS_ID
           , FAL_LOT_PROGRESS_ID = null
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_LOT_PROGRESS_ID = CurFalLotProgress.FAL_LOT_PROGRESS_ID;

      -- pesées archivées
      update FAL_WEIGH_HIST
         set FAL_LOT_PROGRESS_HIST_ID = CurFalLotProgress.FAL_LOT_PROGRESS_ID
           , FAL_LOT_PROGRESS_ID = null
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_LOT_PROGRESS_ID = CurFalLotProgress.FAL_LOT_PROGRESS_ID;
    end loop;
  end SetFalWeighWithLotHist;

-- LOG-A040701-30802 : On supprime la Foreign Key sur le lot hist dans les tables SQM_ANC_XXX
-- afin de permettre la suppression d'un lot sans la suppression de son ANC
  procedure DeleteSqmANCLotConstraint(aFAL_LOT_HIST_ID FAL_LOT_HIST.FAL_LOT_HIST_ID%type)
  is
    cursor CUR_FAL_SCHEDULE_STEP_HIST
    is
      select FAL_SCHEDULE_STEP_ID
        from FAL_TASK_LINK_HIST
       where FAL_LOT_HIST_ID = aFAL_LOT_HIST_ID;

    cursor CUR_FAL_LOT_DETAIL_HIST
    is
      select FAL_LOT_DETAIL_HIST_ID
        from FAL_LOT_DETAIL_HIST
       where FAL_LOT_HIST_ID = aFAL_LOT_HIST_ID;

    CurFalScheduleStepHist CUR_FAL_SCHEDULE_STEP_HIST%rowtype;
    CurFalLotDetailHist    CUR_FAL_LOT_DETAIL_HIST%rowtype;
  begin
    -- Update ANC
    update SQM_ANC
       set FAL_LOT_ID = null
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_LOT_ID = aFAL_LOT_HIST_ID;

    -- Update liens position d'ANC et mesures immédiates
    update SQM_ANC_LINK
       set FAL_LOT_ID = null
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_LOT_ID = aFAL_LOT_HIST_ID;

    -- Update liens position d'ANC et mesures immédiates
    for CurFalScheduleStepHist in CUR_FAL_SCHEDULE_STEP_HIST loop
      update SQM_ANC_LINK
         set FAL_SCHEDULE_STEP2_ID = null
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_SCHEDULE_STEP2_ID = CurFalScheduleStepHist.FAL_SCHEDULE_STEP_ID;
    end loop;

    -- Update liens position d'ANC et mesures immédiates
    for CurFalLotDetailHist in CUR_FAL_LOT_DETAIL_HIST loop
      update SQM_ANC_LINK
         set FAL_LOT_DETAIL_ID = null
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_LOT_DETAIL_ID = CurFalLotDetailHist.FAL_LOT_DETAIL_HIST_ID;
    end loop;
  end DeleteSqmANCLotConstraint;

-- Suppression des pesées à la suppression du Lot de fabrication archivé
  procedure DeleteFalWeigh(aFAL_LOT_HIST_ID FAL_LOT_HIST.FAL_LOT_HIST_ID%type)
  is
    cursor CUR_FAL_SCHEDULE_STEP_HIST
    is
      select FAL_SCHEDULE_STEP_ID
        from FAL_TASK_LINK_HIST
       where FAL_LOT_HIST_ID = aFAL_LOT_HIST_ID;

    cursor CUR_FAL_LOT_PROGRESS_HIST
    is
      select FAL_LOT_PROGRESS_HIST_ID
        from FAL_LOT_PROGRESS_HIST
       where FAL_LOT_HIST_ID = aFAL_LOT_HIST_ID;

    CurFalLotProgressHist  CUR_FAL_LOT_PROGRESS_HIST%rowtype;
    CurFalScheduleStepHist CUR_FAL_SCHEDULE_STEP_HIST%rowtype;
  begin
    -- suppression pesées
    delete from FAL_WEIGH
          where FAL_LOT_HIST_ID = aFAL_LOT_HIST_ID;

    -- Suppression pesées archivées
    delete from FAL_WEIGH_HIST
          where FAL_LOT_HIST_ID = aFAL_LOT_HIST_ID;

    -- Suppression d'éventuelles pesées liées uniquement à l'opération
    for CurFalScheduleStepHist in CUR_FAL_SCHEDULE_STEP_HIST loop
      -- pesées
      delete from FAL_WEIGH
            where FAL_FAL_SCHEDULE_STEP_ID = CurFalScheduleStepHist.FAL_SCHEDULE_STEP_ID;

      -- pesées archivées
      delete from FAL_WEIGH_HIST
            where FAL_FAL_SCHEDULE_STEP_ID = CurFalScheduleStepHist.FAL_SCHEDULE_STEP_ID;
    end loop;

    -- Suppression d'éventuelles pesées liées uniquement au suivi d'opération .
    for CurFalLotProgressHist in CUR_FAL_LOT_PROGRESS_HIST loop
      -- pesées
      delete from FAL_WEIGH
            where FAL_LOT_PROGRESS_HIST_ID = CurFalLotProgressHist.FAL_LOT_PROGRESS_HIST_ID;

      -- pesées archivées
      delete from FAL_WEIGH_HIST
            where FAL_LOT_PROGRESS_HIST_ID = CurFalLotProgressHist.FAL_LOT_PROGRESS_HIST_ID;
    end loop;
  end DeleteFalWeigh;

  -- creation du programme archive par copie de l'original
  procedure creation_programme(prmFAL_JOB_PROGRAM_ID PCS_PK_ID)
  is
  begin
    insert into FAL_JOB_PROGRAM_HIST
                (FAL_JOB_PROGRAM_HIST_ID
               , DIC_PROG_FREE_CODE_ID
               , DIC_FAMILY_ID
               , DOC_DOCUMENT_ID
               , JOP_REFERENCE
               , JOP_SHORT_DESCR
               , JOP_LONG_DESCR
               , JOP_FREE_DESCR
               , JOP_LARGEST_END_DATE
               , JOP_FREE_NUM
               , JOP_FREE_NUM2
               , DOC_RECORD_ID
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
               , PC_YEAR_WEEK_ID
               , PAC_CUSTOM_PARTNER_ID
               , C_PRIORITY
               , PAC_SUPPLIER_PARTNER_ID
               , C_FAB_TYPE
                )
      select FAL_JOB_PROGRAM_ID
           , DIC_PROG_FREE_CODE_ID
           , DIC_FAMILY_ID
           , DOC_DOCUMENT_ID
           , JOP_REFERENCE
           , JOP_SHORT_DESCR
           , JOP_LONG_DESCR
           , JOP_FREE_DESCR
           , JOP_LARGEST_END_DATE
           , JOP_FREE_NUM
           , JOP_FREE_NUM2
           , DOC_RECORD_ID
           , A_DATECRE
           , A_DATEMOD
           , A_IDCRE
           , A_IDMOD
           , A_RECLEVEL
           , A_RECSTATUS
           , A_CONFIRM
           , PC_YEAR_WEEK_ID
           , PAC_CUSTOM_PARTNER_ID
           , C_PRIORITY
           , PAC_SUPPLIER_PARTNER_ID
           , C_FAB_TYPE
        from FAL_JOB_PROGRAM
       where FAL_JOB_PROGRAM_ID = prmFAL_JOB_PROGRAM_ID
         and not exists(select 1
                          from FAL_JOB_PROGRAM_HIST
                         where FAL_JOB_PROGRAM_HIST_ID = prmFAL_JOB_PROGRAM_ID);
  end;

  -- creation de l'ordre archive par copie de l'original
  procedure creation_ordre(prmFAL_ORDER_ID PCS_PK_ID)
  is
  begin
    --On regarde si l'ordre de ce lot existe deja
    insert into FAL_ORDER_HIST
                (PAC_SUPPLIER_PARTNER_ID
               , FAL_ORDER_HIST_ID
               , FAL_JOB_PROGRAM_HIST_ID
               , DIC_FAMILY_ID
               , DIC_ORDER_CODE2_ID
               , DIC_ORDER_CODE3_ID
               , DOC_DOCUMENT_ID
               , GCO_GOOD_ID
               , ORD_REF
               , ORD_OSHORT_DESCR
               , ORD_OLONG_DESCR
               , ORD_OFREE_DESCR
               , ORD_MAX_RELEASABLE
               , ORD_RELEASED_QTY
               , ORD_OPENED_QTY
               , ORD_STILL_TO_RELEASE_QTY
               , ORD_PLANNED_QTY
               , ORD_END_DATE
               , ORD_PSHORT_DESCR
               , ORD_PLONG_DESCR
               , ORD_PFREE_DESCR
               , ORD_SECOND_REF
               , ORD_RESERVED_NUM1
               , ORD_RESERVED_NUM2
               , DOC_RECORD_ID
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
               , PC_YEAR_WEEK_ID
               , PAC_CUSTOM_PARTNER_ID
               , C_PRIORITY
               , C_FAB_TYPE
               , C_ORDER_STATUS
                )
      select PAC_SUPPLIER_PARTNER_ID
           , FAL_ORDER_ID
           , FAL_JOB_PROGRAM_ID
           , DIC_FAMILY_ID
           , DIC_ORDER_CODE2_ID
           , DIC_ORDER_CODE3_ID
           , DOC_DOCUMENT_ID
           , GCO_GOOD_ID
           , ORD_REF
           , ORD_OSHORT_DESCR
           , ORD_OLONG_DESCR
           , ORD_OFREE_DESCR
           , ORD_MAX_RELEASABLE
           , ORD_RELEASED_QTY
           , ORD_OPENED_QTY
           , ORD_STILL_TO_RELEASE_QTY
           , ORD_PLANNED_QTY
           , ORD_END_DATE
           , ORD_PSHORT_DESCR
           , ORD_PLONG_DESCR
           , ORD_PFREE_DESCR
           , ORD_SECOND_REF
           , ORD_RESERVED_NUM1
           , ORD_RESERVED_NUM2
           , DOC_RECORD_ID
           , A_DATECRE
           , A_DATEMOD
           , A_IDCRE
           , A_IDMOD
           , A_RECLEVEL
           , A_RECSTATUS
           , A_CONFIRM
           , PC_YEAR_WEEK_ID
           , PAC_CUSTOM_PARTNER_ID
           , C_PRIORITY
           , C_FAB_TYPE
           , 4   --Status ordre historié
        from FAL_ORDER
       where FAL_ORDER_ID = prmFAL_ORDER_ID
         and not exists(select 1
                          from FAL_ORDER_HIST
                         where FAL_ORDER_HIST_ID = prmFAL_ORDER_ID);
  end;

-- Regarde si il faut supprimer l'ordre ou le programme du lot *************************************************************************************
  procedure test_suppression_ordre_program(prmFAL_ORDER_ID PCS_PK_ID, prmFAL_JOB_PROGRAM_ID PCS_PK_ID, prmTypeArchivage in integer)
  is
    nblot   integer;
    nbordre integer;
  begin
    select count(FAL_LOT_ID)
      into nblot
      from FAL_LOT
     where FAL_ORDER_ID = prmFAL_ORDER_ID;

    --Si il n'y a plus de lots pour cet ordre, on le supprime
    if nblot = 0 then
      -- Si le type d'archivage est "Lots - Ordres - Programmes" ou "Lots - Ordres"
      if    (prmTypeArchivage = 0)
         or (prmTypeArchivage = 1) then
        delete from FAL_ORDER
              where FAL_ORDER_ID = prmFAL_ORDER_ID;
      end if;
    end if;

    --Test sur le programme
    select count(FAL_ORDER_ID)
      into nbordre
      from FAL_ORDER
     where FAL_JOB_PROGRAM_ID = prmFAL_JOB_PROGRAM_ID;

    --Si il n'y a plus d'ordre pour ce programme on le supprimme
    if nbordre = 0 then
      -- Si le type d'archivage est "Lots - Ordres - Programmes"
      if (prmTypeArchivage = 0) then
        delete from FAL_JOB_PROGRAM
              where FAL_JOB_PROGRAM_ID = prmFAL_JOB_PROGRAM_ID;
      end if;
    end if;
  end;

-- Regarde si il faut supprimer l'ordre ou le programme du lot archivé *****************************************************************************
  procedure test_sup_ordre_program_hist(prmFAL_ORDER_ID PCS_PK_ID)
  is
    nblot      integer;
    nbordre    integer;
    varProg_id PCS_PK_ID;
  begin
    --Test sur l'ordre
    select count(FAL_LOT_HIST_ID)
      into nblot
      from FAL_LOT_HIST
     where FAL_ORDER_HIST_ID = prmFAL_ORDER_ID;

    select FAL_JOB_PROGRAM_HIST_ID
      into varProg_id
      from FAL_ORDER_HIST
     where FAL_ORDER_HIST_ID = prmFAL_ORDER_ID;

    --Si il n'y a plus de lots pour cet ordre, on le supprime
    if nblot = 0 then
      delete from FAL_ORDER_HIST
            where FAL_ORDER_HIST_ID = prmFAL_ORDER_ID;
    end if;

    --Test sur le programme
    select count(FAL_ORDER_HIST_ID)
      into nbordre
      from FAL_ORDER_HIST
     where FAL_JOB_PROGRAM_HIST_ID = varProg_id;

    --Si il n'y a plus d'ordre pour ce programme on le supprimme
    if nbordre = 0 then
      delete from FAL_JOB_PROGRAM_HIST
            where FAL_JOB_PROGRAM_HIST_ID = varProg_id;
    end if;
  end;

  -- Suppression d'un lot apres son archivage
  procedure Supprime_lot(prmFAL_LOT_ID PCS_PK_ID)
  is
  begin
    delete from FAL_ELT_COST_DIFF_DET
          where FAL_ELT_COST_DIFF_ID in(select FAL_ELT_COST_DIFF_ID
                                          from FAL_ELT_COST_DIFF
                                         where FAL_LOT_ID = prmFAL_LOT_ID);

    delete from FAL_ELEMENT_COST
          where FAL_LOT_ID = prmFAL_LOT_ID;

    delete from FAL_ELT_COST_DIFF
          where FAL_LOT_ID = prmFAL_LOT_ID;

    -- Suppression des lien d'appairage
    delete from FAL_LOT_DETAIL_LINK
          where FAL_LOT_DETAIL_ID in(select FAL_LOT_DETAIL_ID
                                       from FAL_LOT_DETAIL
                                      where FAL_LOT_ID = prmFAL_LOT_ID);

    -- Suppression détail avancement
    delete from FAL_LOT_PROGRESS_DETAIL
          where FAL_LOT_PROGRESS_ID in(select FAL_LOT_PROGRESS_ID
                                         from FAL_LOT_PROGRESS
                                        where FAL_LOT_ID = prmFAL_LOT_ID);

    -- Suppression suivi d'avancement lot.
    delete from FAL_LOT_PROGRESS
          where FAL_LOT_ID = prmFAL_LOT_ID;

    -- Suppression de l'historique d'imputation des heures et des détails (après les suivis)
    delete from FAL_ACI_TIME_HIST_DET
          where FAL_ACI_TIME_HIST_ID in(select FAL_ACI_TIME_HIST_HIST_ID
                                          from FAL_LOT_PROGRESS_HIST
                                         where FAL_LOT_HIST_ID = prmFAL_LOT_ID);

    delete from FAL_ACI_TIME_HIST
          where FAL_ACI_TIME_HIST_ID in(select FAL_ACI_TIME_HIST_HIST_ID
                                          from FAL_LOT_PROGRESS_HIST
                                         where FAL_LOT_HIST_ID = prmFAL_LOT_ID);

    -- Suppression détaillot après son archivage
    delete from FAL_LOT_DETAIL
          where FAL_LOT_ID = prmFAL_LOT_ID;

    -- Suppression des affectables
    delete from FAL_AFFECT
          where FAL_LOT_ID = prmFAL_LOT_ID;

    -- Suppression des opérations
    delete from FAL_TASK_LINK
          where FAL_LOT_ID = prmFAL_LOT_ID;

    -- Suppression des sorties atelier
    delete from FAL_FACTORY_OUT
          where FAL_LOT_ID = prmFAL_LOT_ID;

    -- Suppression des historiques de lot de fabrication
    delete from FAL_HISTO_LOT
          where (FAL_LOT5_ID = prmFAL_LOT_ID);

    -- Suppresion des entrées atelier
    delete from FAL_FACTORY_IN
          where FAL_LOT_ID = prmFAL_LOT_ID;

    -- Suppression des composants
    delete from FAL_LOT_MATERIAL_LINK
          where FAL_LOT_ID = prmFAL_LOT_ID;

    -- Suppression du lot de fabrication
    delete from FAL_LOT
          where FAL_LOT_ID = prmFAL_LOT_ID;
  end;

  procedure Supprime_lot_hist(prmFAL_LOT_ID PCS_PK_ID)
  is
  begin
    delete from FAL_ELT_COST_DIFF_DET_HIST
          where FAL_ELT_COST_DIFF_HIST_ID in(select FAL_ELT_COST_DIFF_HIST_ID
                                               from FAL_ELT_COST_DIFF_HIST
                                              where FAL_LOT_HIST_ID = prmFAL_LOT_ID);

    delete from FAL_ELT_COST_DIFF_HIST
          where FAL_LOT_HIST_ID = prmFAL_LOT_ID;

    delete from FAL_ELEMENT_COST_HIST
          where FAL_LOT_HIST_ID = prmFAL_LOT_ID;

    delete from FAL_LOT_DETAIL_LINK_HIST
          where FAL_LOT_DETAIL_HIST_ID in(select FAL_LOT_DETAIL_HIST_ID
                                            from FAL_LOT_DETAIL_HIST
                                           where FAL_LOT_HIST_ID = prmFAL_LOT_ID);

    delete from FAL_ACI_TIME_HIST_DET_HIST
          where FAL_ACI_TIME_HIST_HIST_ID in(select FAL_ACI_TIME_HIST_HIST_ID
                                               from FAL_LOT_PROGRESS_HIST
                                              where FAL_LOT_HIST_ID = prmFAL_LOT_ID);

    delete from FAL_ACI_TIME_HIST_HIST
          where FAL_ACI_TIME_HIST_HIST_ID in(select FAL_ACI_TIME_HIST_HIST_ID
                                               from FAL_LOT_PROGRESS_HIST
                                              where FAL_LOT_HIST_ID = prmFAL_LOT_ID);

    delete from FAL_LOT_PROGRES_DETAIL_HIST
          where FAL_LOT_PROGRESS_HIST_ID in(select FAL_LOT_PROGRESS_HIST_ID
                                              from FAL_LOT_PROGRESS_HIST
                                             where FAL_LOT_HIST_ID = prmFAL_LOT_ID);

    delete from FAL_LOT_DETAIL_HIST
          where FAL_LOT_HIST_ID = prmFAL_LOT_ID;

    delete from FAL_LOT_PROGRESS_HIST
          where FAL_LOT_HIST_ID = prmFAL_LOT_ID;

    delete from FAL_AFFECT_HIST
          where FAL_LOT_HIST_ID = prmFAL_LOT_ID;

    delete from FAL_TASK_LINK_HIST
          where FAL_LOT_HIST_ID = prmFAL_LOT_ID;

    delete from FAL_FACTORY_OUT_HIST
          where FAL_LOT_HIST_ID = prmFAL_LOT_ID;

    delete from FAL_HISTO_LOT_HIST
          where (FAL_LOT_HIST5_ID = prmFAL_LOT_ID);

    delete from FAL_FACTORY_IN_HIST
          where FAL_LOT_HIST_ID = prmFAL_LOT_ID;

    delete from FAL_LOT_MAT_LINK_HIST
          where FAL_LOT_HIST_ID = prmFAL_LOT_ID;

    delete from FAL_LOT_HIST
          where FAL_LOT_HIST_ID = prmFAL_LOT_ID;
  end;

  /**
  * procedure archive_Lot
  * Description : Archivage d'un lot
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param iFAL_LOT_ID: Lot
  */
  procedure archive_Lot(iFAL_LOT_ID number)
  is
  begin
    insert into FAL_LOT_HIST
                (FAL_LOT_HIST_ID
               , DIC_FAMILY_ID
               , DIC_LOT_CODE2_ID
               , DIC_LOT_CODE3_ID
               , FAL_ORDER_HIST_ID
               , C_LOT_STATUS
               , GCO_GOOD_ID
               , LOT_REF
               , LOT_FUSION_REF
               , LOT_ORIGIN_REF
               , LOT_SHORT_DESCR
               , LOT_LONG_DESCR
               , LOT_FREE_DESCR
               , LOT_TO_BE_RELEASED
               , LOT_ASKED_QTY
               , LOT_REJECT_PLAN_QTY
               , LOT_TOTAL_QTY
               , LOT_PT_REJECT_QTY
               , LOT_CPT_REJECT_QTY
               , LOT_RELEASED_QTY
               , LOT_REJECT_RELEASED_QTY
               , LOT_DISMOUNTED_QTY
               , LOT_INPROD_QTY
               , LOT_MAX_PROD_QTY
               , LOT_MAX_RELEASABLE_QTY
               , LOT_FREE_QTY
               , LOT_ALLOCATED_QTY
               , LOT_PLAN_BEGIN_DTE
               , LOT_PLAN_END_DTE
               , LOT_OPEN__DTE
               , LOT_FULL_REL_DTE
               , LOT_PLAN_LEAD_TIME
               , LOT_TOLERANCE
               , LOT_VERSION_ORIGIN_NUM
               , LOT_PLAN_NUMBER
               , LOT_SECOND_REF
               , LOT_PSHORT_DESCR
               , LOT_PTEXT
               , LOT_PFREE_TEXT
               , LOT_FREE_NUM1
               , LOT_FREE_NUM2
               , C_SCHEDULE_PLANNING
               , LOT_RELEASE_QTY
               , LOT_PLAN_VERSION
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
               , FAL_SCHEDULE_PLAN_ID
               , PC_YEAR_WEEK_ID
               , PC__PC_YEAR_WEEK_ID
               , PC_2_PC_YEAR_WEEK_ID
               , PC_3_PC_YEAR_WEEK_ID
               , STM_LOCATION_ID
               , STM_STM_LOCATION_ID
               , PPS_OPERATION_PROCEDURE_ID
               , DOC_RECORD_ID
               , STM_STOCK_ID
               , STM_STM_STOCK_ID
               , LOT_REFCOMPL
               , LOT_MODIFY
               , C_PRIORITY
               , DIC_FAB_CONDITION_ID
               , PPS_NOMENCLATURE_ID
               , GCO_QUALITY_PRINCIPLE_ID
               , FAL_FAL_SCHEDULE_PLAN_ID
               , C_FAB_TYPE
               , FAL_JOB_PROGRAM_HIST_ID
               , LOT_REF_QTY
               , LOT_ORT_MARKERS
               , LOT_ORT_UPDATE_DELAY
               , LOT_BASIS_BEGIN_DTE
               , LOT_BASIS_END_DTE
               , LOT_BASIS_LEAD_TIME
               , LOT_REAL_LEAD_TIME
               , LOT_UPDATED_COMPONENTS
               , C_LOT_RECEPT_ERROR
               , PTC_FIXED_COSTPRICE_ID
               , LOT_IS_POSTCALCULATED
                )
      select FAL_LOT_ID
           , DIC_FAMILY_ID
           , DIC_LOT_CODE2_ID
           , DIC_LOT_CODE3_ID
           , FAL_ORDER_ID
           , 6
           , GCO_GOOD_ID
           , LOT_REF
           , LOT_FUSION_REF
           , LOT_ORIGIN_REF
           , LOT_SHORT_DESCR
           , LOT_LONG_DESCR
           , LOT_FREE_DESCR
           , LOT_TO_BE_RELEASED
           , LOT_ASKED_QTY
           , LOT_REJECT_PLAN_QTY
           , LOT_TOTAL_QTY
           , LOT_PT_REJECT_QTY
           , LOT_CPT_REJECT_QTY
           , LOT_RELEASED_QTY
           , LOT_REJECT_RELEASED_QTY
           , LOT_DISMOUNTED_QTY
           , LOT_INPROD_QTY
           , LOT_MAX_PROD_QTY
           , LOT_MAX_RELEASABLE_QTY
           , LOT_FREE_QTY
           , LOT_ALLOCATED_QTY
           , LOT_PLAN_BEGIN_DTE
           , LOT_PLAN_END_DTE
           , LOT_OPEN__DTE
           , LOT_FULL_REL_DTE
           , LOT_PLAN_LEAD_TIME
           , LOT_TOLERANCE
           , LOT_VERSION_ORIGIN_NUM
           , LOT_PLAN_NUMBER
           , LOT_SECOND_REF
           , LOT_PSHORT_DESCR
           , LOT_PTEXT
           , LOT_PFREE_TEXT
           , LOT_FREE_NUM1
           , LOT_FREE_NUM2
           , C_SCHEDULE_PLANNING
           , LOT_RELEASE_QTY
           , LOT_PLAN_VERSION
           , A_DATECRE
           , A_DATEMOD
           , A_IDCRE
           , A_IDMOD
           , A_RECLEVEL
           , A_RECSTATUS
           , A_CONFIRM
           , FAL_SCHEDULE_PLAN_ID
           , PC_YEAR_WEEK_ID
           , PC__PC_YEAR_WEEK_ID
           , PC_2_PC_YEAR_WEEK_ID
           , PC_3_PC_YEAR_WEEK_ID
           , STM_LOCATION_ID
           , STM_STM_LOCATION_ID
           , PPS_OPERATION_PROCEDURE_ID
           , DOC_RECORD_ID
           , STM_STOCK_ID
           , STM_STM_STOCK_ID
           , LOT_REFCOMPL
           , LOT_MODIFY
           , C_PRIORITY
           , DIC_FAB_CONDITION_ID
           , PPS_NOMENCLATURE_ID
           , GCO_QUALITY_PRINCIPLE_ID
           , FAL_FAL_SCHEDULE_PLAN_ID
           , C_FAB_TYPE
           , FAL_JOB_PROGRAM_ID
           , LOT_REF_QTY
           , LOT_ORT_MARKERS
           , LOT_ORT_UPDATE_DELAY
           , LOT_BASIS_BEGIN_DTE
           , LOT_BASIS_END_DTE
           , LOT_BASIS_LEAD_TIME
           , LOT_REAL_LEAD_TIME
           , LOT_UPDATED_COMPONENTS
           , C_LOT_RECEPT_ERROR
           , PTC_FIXED_COSTPRICE_ID
           , LOT_IS_POSTCALCULATED
        from FAL_LOT
       where FAL_LOT_ID = iFAL_LOT_ID;

    -- Archivage du détail lot
    insert into FAL_LOT_DETAIL_HIST
                (FAL_LOT_DETAIL_HIST_ID
               , FAL_LOT_HIST_ID
               , GCO_CHARACTERIZATION_ID
               , GCO_GCO_CHARACTERIZATION_ID
               , GCO2_GCO_CHARACTERIZATION_ID
               , GCO3_GCO_CHARACTERIZATION_ID
               , GCO4_GCO_CHARACTERIZATION_ID
               , GCO_GOOD_ID
               , FAD_CHARACTERIZATION_VALUE_1
               , FAD_CHARACTERIZATION_VALUE_2
               , FAD_CHARACTERIZATION_VALUE_3
               , FAD_CHARACTERIZATION_VALUE_4
               , FAD_CHARACTERIZATION_VALUE_5
               , FAD_RECEPT_SELECT
               , FAD_QTY
               , FAD_RECEPT_QTY
               , FAD_BALANCE_QTY
               , FAD_CANCEL_QTY
               , FAD_RECEPT_INPROGRESS_QTY
               , FAD_VERSION
               , FAD_LOT_CHARACTERIZATION
               , FAD_PIECE
               , FAD_LOT_REFCOMPL
               , FAD_MORPHO_REJECT_QTY
               , FAD_CHRONOLOGY
               , FAD_STD_CHAR_1
               , FAD_STD_CHAR_2
               , FAD_STD_CHAR_3
               , FAD_STD_CHAR_4
               , FAD_STD_CHAR_5
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
               , C_LOT_DETAIL
               , GCG_REF_QTY
               , GCG_QTY
               , GCG_INCLUDE_GOOD
               , GCG_TOTAL_QTY
                )
      select FAL_LOT_DETAIL_ID
           , FAL_LOT_ID
           , decode(GCO_CHARACTERIZATION_ID, '0', null, GCO_CHARACTERIZATION_ID)
           , decode(GCO_GCO_CHARACTERIZATION_ID, '0', null, GCO_GCO_CHARACTERIZATION_ID)
           , decode(GCO2_GCO_CHARACTERIZATION_ID, '0', null, GCO2_GCO_CHARACTERIZATION_ID)
           , decode(GCO3_GCO_CHARACTERIZATION_ID, '0', null, GCO3_GCO_CHARACTERIZATION_ID)
           , decode(GCO4_GCO_CHARACTERIZATION_ID, '0', null, GCO4_GCO_CHARACTERIZATION_ID)
           , GCO_GOOD_ID
           , FAD_CHARACTERIZATION_VALUE_1
           , FAD_CHARACTERIZATION_VALUE_2
           , FAD_CHARACTERIZATION_VALUE_3
           , FAD_CHARACTERIZATION_VALUE_4
           , FAD_CHARACTERIZATION_VALUE_5
           , FAD_RECEPT_SELECT
           , FAD_QTY
           , FAD_RECEPT_QTY
           , FAD_BALANCE_QTY
           , FAD_CANCEL_QTY
           , FAD_RECEPT_INPROGRESS_QTY
           , FAD_VERSION
           , FAD_LOT_CHARACTERIZATION
           , FAD_PIECE
           , FAD_LOT_REFCOMPL
           , FAD_MORPHO_REJECT_QTY
           , FAD_CHRONOLOGY
           , FAD_STD_CHAR_1
           , FAD_STD_CHAR_2
           , FAD_STD_CHAR_3
           , FAD_STD_CHAR_4
           , FAD_STD_CHAR_5
           , A_DATECRE
           , A_DATEMOD
           , A_IDCRE
           , A_IDMOD
           , A_RECLEVEL
           , A_RECSTATUS
           , A_CONFIRM
           , C_LOT_DETAIL
           , GCG_REF_QTY
           , GCG_QTY
           , GCG_INCLUDE_GOOD
           , GCG_TOTAL_QTY
        from FAL_LOT_DETAIL DET
       where DET.FAL_LOT_ID = iFAL_LOT_ID;

    --archivage des FAL_LOT_MATERIAL_LINK
    insert into FAL_LOT_MAT_LINK_HIST
                (FAL_LOT_MAT_LINK_HIST_ID
               , LOM_SEQ
               , LOM_SUBSTITUT
               , LOM_STOCK_MANAGEMENT
               , LOM_SECONDARY_REF
               , LOM_SHORT_DESCR
               , C_KIND_COM
               , C_DISCHARGE_COM
               , GCO_GOOD_ID
               , STM_STOCK_ID
               , STM_LOCATION_ID
               , FAL_LOT_HIST_ID
               , PC_YEAR_WEEK_ID
               , LOM_LONG_DESCR
               , LOM_FREE_DECR
               , LOM_POS
               , LOM_FRE_NUM
               , LOM_TEXT
               , LOM_FREE_TEXT
               , LOM_UTIL_COEF
               , LOM_BOM_REQ_QTY
               , LOM_ADJUSTED_QTY
               , LOM_FULL_REQ_QTY
               , LOM_CONSUMPTION_QTY
               , LOM_REJECTED_QTY
               , LOM_BACK_QTY
               , LOM_PT_REJECT_QTY
               , LOM_CPT_TRASH_QTY
               , LOM_CPT_RECOVER_QTY
               , LOM_CPT_REJECT_QTY
               , LOM_EXIT_RECEIPT
               , LOM_NEED_QTY
               , LOM_MAX_RECEIPT_QTY
               , LOM_MAX_FACT_QTY
               , LOM_INTERVAL
               , LOM_NEED_DATE
               , LOM_PRICE
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
               , C_TYPE_COM
               , C_CHRONOLOGY_TYPE
               , LOM_AVAILABLE_QTY
               , LOM_MISSING
               , LOM_TASK_SEQ
               , LOM_REF_QTY
               , LOM_ADJUSTED_QTY_RECEIPT
               , GCO_GCO_GOOD_ID   -- Produit générique
               , LOM_INCREASE_COST
               , LOM_MARK_TOPO
                )
      select FAL_LOT_MATERIAL_LINK_ID
           , LOM_SEQ
           , LOM_SUBSTITUT
           , LOM_STOCK_MANAGEMENT
           , LOM_SECONDARY_REF
           , LOM_SHORT_DESCR
           , C_KIND_COM
           , C_DISCHARGE_COM
           , GCO_GOOD_ID
           , STM_STOCK_ID
           , STM_LOCATION_ID
           , FAL_LOT_ID
           , PC_YEAR_WEEK_ID
           , LOM_LONG_DESCR
           , LOM_FREE_DECR
           , LOM_POS
           , LOM_FRE_NUM
           , LOM_TEXT
           , LOM_FREE_TEXT
           , LOM_UTIL_COEF
           , LOM_BOM_REQ_QTY
           , LOM_ADJUSTED_QTY
           , LOM_FULL_REQ_QTY
           , LOM_CONSUMPTION_QTY
           , LOM_REJECTED_QTY
           , LOM_BACK_QTY
           , LOM_PT_REJECT_QTY
           , LOM_CPT_TRASH_QTY
           , LOM_CPT_RECOVER_QTY
           , LOM_CPT_REJECT_QTY
           , LOM_EXIT_RECEIPT
           , LOM_NEED_QTY
           , LOM_MAX_RECEIPT_QTY
           , LOM_MAX_FACT_QTY
           , LOM_INTERVAL
           , LOM_NEED_DATE
           , LOM_PRICE
           , A_DATECRE
           , A_DATEMOD
           , A_IDCRE
           , A_IDMOD
           , A_RECLEVEL
           , A_RECSTATUS
           , A_CONFIRM
           , C_TYPE_COM
           , C_CHRONOLOGY_TYPE
           , LOM_AVAILABLE_QTY
           , LOM_MISSING
           , LOM_TASK_SEQ
           , LOM_REF_QTY
           , LOM_ADJUSTED_QTY_RECEIPT
           , GCO_GCO_GOOD_ID
           , LOM_INCREASE_COST
           , LOM_MARK_TOPO
        from FAL_LOT_MATERIAL_LINK
       where FAL_LOT_ID = iFAL_LOT_ID;

    --archivage des FAL_TASK_LINK
    insert into FAL_TASK_LINK_HIST
                (FAL_LOT_HIST_ID
               , PPS_TOOLS1_ID
               , PPS_TOOLS2_ID
               , PPS_TOOLS3_ID
               , PPS_TOOLS4_ID
               , PPS_TOOLS5_ID
               , PPS_TOOLS6_ID
               , PPS_TOOLS7_ID
               , PPS_TOOLS8_ID
               , PPS_TOOLS9_ID
               , PPS_TOOLS10_ID
               , PPS_TOOLS11_ID
               , PPS_TOOLS12_ID
               , PPS_TOOLS13_ID
               , PPS_TOOLS14_ID
               , PPS_TOOLS15_ID
               , FAL_SCHEDULE_STEP_ID
               , DOC_DOCUMENT_ID
               , TAL_DUE_TSK
               , TAL_ACHIEVED_TSK
               , TAL_TSK_BALANCE
               , TAL_DUE_AMT
               , TAL_ACHIEVED_AMT
               , TAL_AMT_BALANCE
               , TAL_PLAN_QTY
               , TAL_RELEASE_QTY
               , TAL_REJECTED_QTY
               , TAL_AVALAIBLE_QTY
               , TAL_DUE_QTY
               , TAL_R_METER
               , TAL_BEGIN_PLAN_DATE
               , TAL_END_PLAN_DATE
               , TAL_NUM_UNITS_ALLOCATED
               , TAL_TASK_MANUF_TIME
               , C_TASK_TYPE
               , SCS_STEP_NUMBER
               , SCS_WORK_TIME
               , SCS_QTY_REF_WORK
               , SCS_WORK_RATE
               , SCS_AMOUNT
               , SCS_QTY_REF_AMOUNT
               , SCS_DIVISOR_AMOUNT
               , SCS_PLAN_RATE
               , SCS_SHORT_DESCR
               , SCS_LONG_DESCR
               , SCS_FREE_DESCR
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
               , PAC_SUPPLIER_PARTNER_ID
               , PPS_OPERATION_PROCEDURE_ID
               , PPS_PPS_OPERATION_PROCEDURE_ID
               , GCO_GCO_GOOD_ID
               , FAL_FACTORY_FLOOR_ID
               , FAL_TASK_ID
               , TAL_PLAN_RATE
               , TAL_BEGIN_REAL_DATE
               , TAL_END_REAL_DATE
               , C_OPERATION_TYPE
               , SCS_ADJUSTING_TIME
               , TAL_EAN_CODE
               , TAL_SEQ_ORIGIN
               , DIC_FREE_TASK_CODE_ID
               , DIC_FREE_TASK_CODE2_ID
               , DIC_FREE_TASK_CODE3_ID
               , DIC_FREE_TASK_CODE4_ID
               , DIC_FREE_TASK_CODE5_ID
               , DIC_FREE_TASK_CODE6_ID
               , DIC_FREE_TASK_CODE7_ID
               , DIC_FREE_TASK_CODE8_ID
               , DIC_FREE_TASK_CODE9_ID
               , SCS_PLAN_PROP
               , C_TASK_IMPUTATION
               , SCS_TRANSFERT_TIME
               , SCS_QTY_FIX_ADJUSTING
               , SCS_ADJUSTING_RATE
               , TAL_ACHIEVED_AD_TSK
               , DOC_POSITION_DETAIL_ID
               , TAL_SUBCONTRACT_QTY
               , C_RELATION_TYPE
               , SCS_DELAY
               , TAL_ORT_PRIORITY
               , TAL_SUBCONTRACT_SELECT
               , TAL_SUBCONTRACT_PRINT
               , TAL_SUB_SELECT_DATE
               , TAL_SUB_PRINT_DATE
               , TAL_CONFIRM_DATE
               , TAL_CONFIRM_DESCR
               , TAL_ORT_MARKERS
               , FAL_FAL_FACTORY_FLOOR_ID
               , SCS_ADJUSTING_FLOOR
               , SCS_ADJUSTING_OPERATOR
               , SCS_NUM_ADJUST_OPERATOR
               , SCS_PERCENT_ADJUST_OPER
               , SCS_WORK_FLOOR
               , SCS_WORK_OPERATOR
               , SCS_NUM_WORK_OPERATOR
               , SCS_PERCENT_WORK_OPER
               , TAL_TSK_AD_BALANCE
               , TAL_TSK_W_BALANCE
               , SCS_NUM_FLOOR
               , TAL_BASIS_BEGIN_DATE
               , TAL_BASIS_END_DATE
               , TAL_TASK_BASIS_TIME
               , TAL_TASK_REAL_TIME
               , DIC_UNIT_OF_MEASURE_ID
               , SCS_CONVERSION_FACTOR
               , SCS_QTY_REF2_WORK
               , SCS_FREE_NUM1
               , SCS_FREE_NUM2
               , SCS_FREE_NUM3
               , SCS_FREE_NUM4
               , SCS_OPEN_TIME_MACHINE
                )
      select FAL_LOT_ID
           , PPS_TOOLS1_ID
           , PPS_TOOLS2_ID
           , PPS_TOOLS3_ID
           , PPS_TOOLS4_ID
           , PPS_TOOLS5_ID
           , PPS_TOOLS6_ID
           , PPS_TOOLS7_ID
           , PPS_TOOLS8_ID
           , PPS_TOOLS9_ID
           , PPS_TOOLS10_ID
           , PPS_TOOLS11_ID
           , PPS_TOOLS12_ID
           , PPS_TOOLS13_ID
           , PPS_TOOLS14_ID
           , PPS_TOOLS15_ID
           , FAL_SCHEDULE_STEP_ID
           , DOC_DOCUMENT_ID
           , TAL_DUE_TSK
           , TAL_ACHIEVED_TSK
           , TAL_TSK_BALANCE
           , TAL_DUE_AMT
           , TAL_ACHIEVED_AMT
           , TAL_AMT_BALANCE
           , TAL_PLAN_QTY
           , TAL_RELEASE_QTY
           , TAL_REJECTED_QTY
           , TAL_AVALAIBLE_QTY
           , TAL_DUE_QTY
           , TAL_R_METER
           , TAL_BEGIN_PLAN_DATE
           , TAL_END_PLAN_DATE
           , TAL_NUM_UNITS_ALLOCATED
           , TAL_TASK_MANUF_TIME
           , C_TASK_TYPE
           , SCS_STEP_NUMBER
           , SCS_WORK_TIME
           , SCS_QTY_REF_WORK
           , SCS_WORK_RATE
           , SCS_AMOUNT
           , SCS_QTY_REF_AMOUNT
           , SCS_DIVISOR_AMOUNT
           , SCS_PLAN_RATE
           , SCS_SHORT_DESCR
           , SCS_LONG_DESCR
           , SCS_FREE_DESCR
           , A_DATECRE
           , A_DATEMOD
           , A_IDCRE
           , A_IDMOD
           , A_RECLEVEL
           , A_RECSTATUS
           , A_CONFIRM
           , PAC_SUPPLIER_PARTNER_ID
           , PPS_OPERATION_PROCEDURE_ID
           , PPS_PPS_OPERATION_PROCEDURE_ID
           , GCO_GCO_GOOD_ID
           , FAL_FACTORY_FLOOR_ID
           , FAL_TASK_ID
           , TAL_PLAN_RATE
           , TAL_BEGIN_REAL_DATE
           , TAL_END_REAL_DATE
           , C_OPERATION_TYPE
           , SCS_ADJUSTING_TIME
           , TAL_EAN_CODE
           , TAL_SEQ_ORIGIN
           , DIC_FREE_TASK_CODE_ID
           , DIC_FREE_TASK_CODE2_ID
           , DIC_FREE_TASK_CODE3_ID
           , DIC_FREE_TASK_CODE4_ID
           , DIC_FREE_TASK_CODE5_ID
           , DIC_FREE_TASK_CODE6_ID
           , DIC_FREE_TASK_CODE7_ID
           , DIC_FREE_TASK_CODE8_ID
           , DIC_FREE_TASK_CODE9_ID
           , SCS_PLAN_PROP
           , C_TASK_IMPUTATION
           , SCS_TRANSFERT_TIME
           , SCS_QTY_FIX_ADJUSTING
           , SCS_ADJUSTING_RATE
           , TAL_ACHIEVED_AD_TSK
           , DOC_POSITION_DETAIL_ID
           , TAL_SUBCONTRACT_QTY
           , C_RELATION_TYPE
           , SCS_DELAY
           , TAL_ORT_PRIORITY
           , TAL_SUBCONTRACT_SELECT
           , TAL_SUBCONTRACT_PRINT
           , TAL_SUB_SELECT_DATE
           , TAL_SUB_PRINT_DATE
           , TAL_CONFIRM_DATE
           , TAL_CONFIRM_DESCR
           , TAL_ORT_MARKERS
           , FAL_FAL_FACTORY_FLOOR_ID
           , SCS_ADJUSTING_FLOOR
           , SCS_ADJUSTING_OPERATOR
           , SCS_NUM_ADJUST_OPERATOR
           , SCS_PERCENT_ADJUST_OPER
           , SCS_WORK_FLOOR
           , SCS_WORK_OPERATOR
           , SCS_NUM_WORK_OPERATOR
           , SCS_PERCENT_WORK_OPER
           , TAL_TSK_AD_BALANCE
           , TAL_TSK_W_BALANCE
           , SCS_NUM_FLOOR
           , TAL_BASIS_BEGIN_DATE
           , TAL_BASIS_END_DATE
           , TAL_TASK_BASIS_TIME
           , TAL_TASK_REAL_TIME
           , DIC_UNIT_OF_MEASURE_ID
           , SCS_CONVERSION_FACTOR
           , SCS_QTY_REF2_WORK
           , SCS_FREE_NUM1
           , SCS_FREE_NUM2
           , SCS_FREE_NUM3
           , SCS_FREE_NUM4
           , SCS_OPEN_TIME_MACHINE
        from FAL_TASK_LINK
       where FAL_LOT_ID = iFAL_LOT_ID;

    --archivage des FAL_FACTORY_IN
    insert into FAL_FACTORY_IN_HIST
                (FAL_FACTORY_IN_HIST_ID
               , FAL_LOT_HIST_ID
               , GCO_GOOD_ID
               , STM_LOCATION_ID
               , STM_STOCK_POSITION_ID
               , GCO_CHARACTERIZATION_ID
               , GCO_GCO_CHARACTERIZATION_ID
               , GCO2_GCO_CHARACTERIZATION_ID
               , GCO3_GCO_CHARACTERIZATION_ID
               , GCO4_GCO_CHARACTERIZATION_ID
               , C_IN_ORIGINE
               , IN_DATE
               , IN_LOT_REFCOMPL
               , IN_FULL_TRACABILITY
               , IN_VERSION
               , IN_LOT
               , IN_PIECE
               , IN_CHRONOLOGY
               , IN_STD_CHAR_1
               , IN_STD_CHAR_2
               , IN_STD_CHAR_3
               , IN_STD_CHAR_4
               , IN_STD_CHAR_5
               , IN_CHARACTERIZATION_VALUE_1
               , IN_CHARACTERIZATION_VALUE_2
               , IN_CHARACTERIZATION_VALUE_3
               , IN_CHARACTERIZATION_VALUE_4
               , IN_CHARACTERIZATION_VALUE_5
               , IN_PRICE
               , IN_IN_QTE
               , IN_OUT_QTE
               , IN_BALANCE
               , FAL_LOT_MAT_LINK_HIST_ID
               , DIC_COMPONENT_MVT_ID
               , IN_COMMENT
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
                )
      select FAL_FACTORY_IN_ID
           , FAL_LOT_ID
           , GCO_GOOD_ID
           , STM_LOCATION_ID
           , null   --STM_STOCK_POSITION_ID,
           , GCO_CHARACTERIZATION_ID
           , GCO_GCO_CHARACTERIZATION_ID
           , GCO2_GCO_CHARACTERIZATION_ID
           , GCO3_GCO_CHARACTERIZATION_ID
           , GCO4_GCO_CHARACTERIZATION_ID
           , C_IN_ORIGINE
           , IN_DATE
           , IN_LOT_REFCOMPL
           , IN_FULL_TRACABILITY
           , IN_VERSION
           , IN_LOT
           , IN_PIECE
           , IN_CHRONOLOGY
           , IN_STD_CHAR_1
           , IN_STD_CHAR_2
           , IN_STD_CHAR_3
           , IN_STD_CHAR_4
           , IN_STD_CHAR_5
           , IN_CHARACTERIZATION_VALUE_1
           , IN_CHARACTERIZATION_VALUE_2
           , IN_CHARACTERIZATION_VALUE_3
           , IN_CHARACTERIZATION_VALUE_4
           , IN_CHARACTERIZATION_VALUE_5
           , IN_PRICE
           , IN_IN_QTE
           , IN_OUT_QTE
           , IN_BALANCE
           , FAL_LOT_MATERIAL_LINK_ID
           , DIC_COMPONENT_MVT_ID
           , IN_COMMENT
           , A_DATECRE
           , A_DATEMOD
           , A_IDCRE
           , A_IDMOD
           , A_RECLEVEL
           , A_RECSTATUS
           , A_CONFIRM
        from FAL_FACTORY_IN
       where FAL_LOT_ID = iFAL_LOT_ID;

    --archivage des FAL_FACTORY_OUT
    insert into FAL_FACTORY_OUT_HIST
                (FAL_FACTORY_OUT_HIST_ID
               , FAL_LOT_HIST_ID
               , C_OUT_TYPE
               , C_OUT_ORIGINE
               , GCO_GOOD_ID
               , STM_LOCATION_ID
               , OUT_DATE
               , OUT_QTE
               , OUT_LOT_REFCOMPL
               , OUT_CHRONOLOGY
               , OUT_VERSION
               , OUT_LOT
               , OUT_PIECE
               , OUT_STD_CHAR_1
               , OUT_STD_CHAR_2
               , OUT_STD_CHAR_3
               , OUT_STD_CHAR_4
               , OUT_STD_CHAR_5
               , DIC_COMPONENT_MVT_ID
               , OUT_COMMENT
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
               , OUT_PRICE
               , OUT_POSTCALCULATED
                )
      select FAL_FACTORY_OUT_ID
           , FAL_LOT_ID
           , C_OUT_TYPE
           , C_OUT_ORIGINE
           , GCO_GOOD_ID
           , STM_LOCATION_ID
           , OUT_DATE
           , OUT_QTE
           , OUT_LOT_REFCOMPL
           , OUT_CHRONOLOGY
           , OUT_VERSION
           , OUT_LOT
           , OUT_PIECE
           , OUT_STD_CHAR_1
           , OUT_STD_CHAR_2
           , OUT_STD_CHAR_3
           , OUT_STD_CHAR_4
           , OUT_STD_CHAR_5
           , DIC_COMPONENT_MVT_ID
           , OUT_COMMENT
           , A_DATECRE
           , A_DATEMOD
           , A_IDCRE
           , A_IDMOD
           , A_RECLEVEL
           , A_RECSTATUS
           , A_CONFIRM
           , OUT_PRICE
           , OUT_POSTCALCULATED
        from FAL_FACTORY_OUT
       where FAL_LOT_ID = iFAL_LOT_ID;

    --archivage des FAL_HISTO_LOT
    insert into FAL_HISTO_LOT_HIST
                (FAL_HISTO_LOT_HIST_ID
               , C_EVEN_TYPE
               , FAL_TASK_ID
               , HIS_PLAN_BEGIN_DTE
               , HIS_PLAN_END_DTE
               , HIS_QTE
               , HIS_INPROD_QTE
               , HIS_EVEN_DTE
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
               , HIS_REFCOMPL
               , FAL_LOT1_ID
               , FAL_LOT4_ID
               , FAL_LOT5_ID
               , FAL_LOT_HIST1_ID
               , FAL_LOT_HIST4_ID
               , FAL_LOT_HIST5_ID
                )
      select FAL_HISTO_LOT_ID
           , C_EVEN_TYPE
           , FAL_TASK_ID
           , HIS_PLAN_BEGIN_DTE
           , HIS_PLAN_END_DTE
           , HIS_QTE
           , HIS_INPROD_QTE
           , HIS_EVEN_DTE
           , A_DATECRE
           , A_DATEMOD
           , A_IDCRE
           , A_IDMOD
           , A_RECLEVEL
           , A_RECSTATUS
           , A_CONFIRM
           , HIS_REFCOMPL
           , FAL_LOT1_ID
           , FAL_LOT4_ID
           , null
           , FAL_LOT_HIST1_ID
           , FAL_LOT_HIST4_ID
           , FAL_LOT5_ID
        from FAL_HISTO_LOT
       where (FAL_LOT5_ID = iFAL_LOT_ID);

    --archivage des FAL_AFFECT
    insert into FAL_AFFECT_HIST
                (FAL_AFFECT_HIST_ID
               , FAL_LOT_HIST_ID
               , FAL_SCHEDULE_STEP_ID
               , FAL_TASK_ID
               , GCO_GOOD_ID
               , GCO_GCO_GOOD_ID
               , DIC_OPERATOR_ID
               , DIC_AFFECTABILITY_TYPE_ID
               , FAF_QTY
               , FAF_UNITARY_AMOUNT
               , FAF_TOTAL_AMOUNT
               , FAF_LABEL
               , FAF_DATE1
               , FAF_DATE2
               , FAF_SEQ
               , FAF_SHORT_DESCR
               , FAF_REMARK
               , LOT_REFCOMPL
               , DOC_POSITION_ID
               , DOC_DOCUMENT_ID
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
               , A_TRANSLATE
               , PAC_THIRD_ID
                )
      select FAL_AFFECT_ID
           , FAL_LOT_ID
           , FAL_SCHEDULE_STEP_ID
           , FAL_TASK_ID
           , null   -- GCO_GOOD_ID
           , null   -- GCO_GCO_GOOD_ID
           , DIC_OPERATOR_ID
           , DIC_AFFECTABILITY_TYPE_ID
           , FAF_QTY
           , FAF_UNITARY_AMOUNT
           , FAF_TOTAL_AMOUNT
           , FAF_LABEL
           , FAF_DATE1
           , FAF_DATE2
           , FAF_SEQ
           , FAF_SHORT_DESCR
           , FAF_REMARK
           , LOT_REFCOMPL
           , null   -- DOC_POSITION_ID
           , null   -- DOC_DOCUMENT_ID
           , A_DATECRE
           , A_DATEMOD
           , A_IDCRE
           , A_IDMOD
           , A_RECLEVEL
           , A_RECSTATUS
           , A_CONFIRM
           , A_TRANSLATE
           , PAC_THIRD_ID
        from FAL_AFFECT
       where FAL_LOT_ID = iFAL_LOT_ID;

    -- Archivage des FAL_ACI_TIME_HIST
    insert into FAL_ACI_TIME_HIST_HIST
                (FAL_ACI_TIME_HIST_HIST_ID
               , C_PROGRESS_ORIGIN
               , TIH_VALUE_DATE
               , TIH_PROGRESS_DATE
               , DOC_NUMBER
               , TIH_DESCRIPTION
               , TIH_ENTERED_INTO_WIP
               , TIH_ENTERED_INTO_ACI
               , TIH_ADJ_TIME_OPER_QTY
               , TIH_ADJ_TIME_OPER_RATE
               , TIH_ADJ_TIME_OPER_AMOUNT
               , TIH_ADJ_TIME_MACH_QTY
               , TIH_ADJ_TIME_MACH_RATE
               , TIH_ADJ_TIME_MACH_AMOUNT
               , TIH_WORK_TIME_OPER_QTY
               , TIH_WORK_TIME_OPER_RATE
               , TIH_WORK_TIME_OPER_AMOUNT
               , TIH_WORK_TIME_MACH_QTY
               , TIH_WORK_TIME_MACH_RATE
               , TIH_WORK_TIME_MACH_ADD_AMOUNT
               , TIH_WORK_TIME_MACH_AMOUNT
               , A_DATECRE
               , A_IDCRE
               , A_DATEMOD
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
                )
      select TIH.FAL_ACI_TIME_HIST_ID
           , TIH.C_PROGRESS_ORIGIN
           , TIH.TIH_VALUE_DATE
           , TIH.TIH_PROGRESS_DATE
           , TIH.DOC_NUMBER
           , TIH.TIH_DESCRIPTION
           , TIH.TIH_ENTERED_INTO_WIP
           , TIH.TIH_ENTERED_INTO_ACI
           , TIH.TIH_ADJ_TIME_OPER_QTY
           , TIH.TIH_ADJ_TIME_OPER_RATE
           , TIH.TIH_ADJ_TIME_OPER_AMOUNT
           , TIH.TIH_ADJ_TIME_MACH_QTY
           , TIH.TIH_ADJ_TIME_MACH_RATE
           , TIH.TIH_ADJ_TIME_MACH_AMOUNT
           , TIH.TIH_WORK_TIME_OPER_QTY
           , TIH.TIH_WORK_TIME_OPER_RATE
           , TIH.TIH_WORK_TIME_OPER_AMOUNT
           , TIH.TIH_WORK_TIME_MACH_QTY
           , TIH.TIH_WORK_TIME_MACH_RATE
           , TIH.TIH_WORK_TIME_MACH_ADD_AMOUNT
           , TIH.TIH_WORK_TIME_MACH_AMOUNT
           , TIH.A_DATECRE
           , TIH.A_IDCRE
           , TIH.A_DATEMOD
           , TIH.A_IDMOD
           , TIH.A_RECLEVEL
           , TIH.A_RECSTATUS
           , TIH.A_CONFIRM
        from FAL_ACI_TIME_HIST TIH
           , FAL_LOT_PROGRESS FLP
       where TIH.FAL_ACI_TIME_HIST_ID = FLP.FAL_ACI_TIME_HIST_ID
         and FLP.FAL_LOT_ID = iFAL_LOT_ID;

    -- Archivage des FAL_ACI_TIME_HIST_DET
    insert into FAL_ACI_TIME_HIST_DET_HIST
                (FAL_ACI_TIME_HIST_DET_HIST_ID
               , FAL_ACI_TIME_HIST_HIST_ID
               , C_FAL_ENTRY_TYPE
               , C_FAL_ENTRY_SIGN
               , ACI_DOCUMENT_ID
               , ACT_DOCUMENT_ID
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_DIVISION_ACCOUNT_ID
               , ACS_CPN_ACCOUNT_ID
               , ACS_CDA_ACCOUNT_ID
               , ACS_PF_ACCOUNT_ID
               , ACS_PJ_ACCOUNT_ID
               , ACS_QTY_UNIT_ID
               , DOC_RECORD_ID
               , FAM_FIXED_ASSETS_ID
               , GCO_GOOD_ID
               , HRM_PERSON_ID
               , PAC_PERSON_ID
               , DIC_IMP_FREE1_ID
               , DIC_IMP_FREE2_ID
               , DIC_IMP_FREE3_ID
               , DIC_IMP_FREE4_ID
               , DIC_IMP_FREE5_ID
               , IMF_NUMBER
               , IMF_NUMBER2
               , IMF_NUMBER3
               , IMF_NUMBER4
               , IMF_NUMBER5
               , IMF_TEXT1
               , IMF_TEXT2
               , IMF_TEXT3
               , IMF_TEXT4
               , IMF_TEXT5
               , A_DATECRE
               , A_IDCRE
               , A_DATEMOD
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
                )
      select THD.FAL_ACI_TIME_HIST_DET_ID
           , THD.FAL_ACI_TIME_HIST_ID
           , THD.C_FAL_ENTRY_TYPE
           , THD.C_FAL_ENTRY_SIGN
           , THD.ACI_DOCUMENT_ID
           , THD.ACT_DOCUMENT_ID
           , THD.ACS_FINANCIAL_ACCOUNT_ID
           , THD.ACS_DIVISION_ACCOUNT_ID
           , THD.ACS_CPN_ACCOUNT_ID
           , THD.ACS_CDA_ACCOUNT_ID
           , THD.ACS_PF_ACCOUNT_ID
           , THD.ACS_PJ_ACCOUNT_ID
           , THD.ACS_QTY_UNIT_ID
           , THD.DOC_RECORD_ID
           , THD.FAM_FIXED_ASSETS_ID
           , THD.GCO_GOOD_ID
           , THD.HRM_PERSON_ID
           , THD.PAC_PERSON_ID
           , THD.DIC_IMP_FREE1_ID
           , THD.DIC_IMP_FREE2_ID
           , THD.DIC_IMP_FREE3_ID
           , THD.DIC_IMP_FREE4_ID
           , THD.DIC_IMP_FREE5_ID
           , THD.IMF_NUMBER
           , THD.IMF_NUMBER2
           , THD.IMF_NUMBER3
           , THD.IMF_NUMBER4
           , THD.IMF_NUMBER5
           , THD.IMF_TEXT1
           , THD.IMF_TEXT2
           , THD.IMF_TEXT3
           , THD.IMF_TEXT4
           , THD.IMF_TEXT5
           , THD.A_DATECRE
           , THD.A_IDCRE
           , THD.A_DATEMOD
           , THD.A_IDMOD
           , THD.A_RECLEVEL
           , THD.A_RECSTATUS
           , THD.A_CONFIRM
        from FAL_ACI_TIME_HIST_DET THD
           , FAL_LOT_PROGRESS FLP
       where THD.FAL_ACI_TIME_HIST_ID = FLP.FAL_ACI_TIME_HIST_ID
         and FLP.FAL_LOT_ID = iFAL_LOT_ID;

    -- archivage des FAL_LOT_PROGRESS
    insert into FAL_LOT_PROGRESS_HIST
                (FAL_LOT_PROGRESS_HIST_ID
               , FAL_LOT_HIST_ID
               , FAL_LOT_DETAIL_HIST_ID
               , FAL_SCHEDULE_STEP_ID
               , FAL_TASK_ID
               , FAL_FACTORY_FLOOR_ID
               , FAL_FAL_FACTORY_FLOOR_ID
               , PPS_TOOLS1_ID
               , PPS_TOOLS2_ID
               , PPS_TOOLS3_ID
               , PPS_TOOLS4_ID
               , PPS_TOOLS5_ID
               , PPS_TOOLS6_ID
               , PPS_TOOLS7_ID
               , PPS_TOOLS8_ID
               , PPS_TOOLS9_ID
               , PPS_TOOLS10_ID
               , PPS_TOOLS11_ID
               , PPS_TOOLS12_ID
               , PPS_TOOLS13_ID
               , PPS_TOOLS14_ID
               , PPS_TOOLS15_ID
               , PPS_OPERATION_PROCEDURE_ID
               , PPS_PPS_OPERATION_PROCEDURE_ID
               , DIC_REBUT_ID
               , DIC_WORK_TYPE_ID
               , DIC_OPERATOR_ID
               , LOT_REFCOMPL
               , FLP_PRODUCT_QTY
               , FLP_PT_REJECT_QTY
               , FLP_CPT_REJECT_QTY
               , FLP_ADJUSTING_TIME
               , FLP_WORK_TIME
               , FLP_AMOUNT
               , FLP_SHORT_DESCR
               , FLP_SEQ
               , FLP_LABEL_CONTROL
               , FLP_LABEL_REJECT
               , FLP_DATE1
               , FLP_DATE2
               , FLP_EAN_CODE
               , FLP_RATE
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
               , D_TRANSLATE
               , FLP_SEQ_ORIGIN
               , DIC_FREE_TASK_CODE2_ID
               , DIC_FREE_TASK_CODE_ID
               , FLP_ADJUSTING_RATE
               , FLP_MANUAL
               , DIC_UNIT_OF_MEASURE_ID
               , FLP_QTY_REF2_WORK
               , FLP_PRODUCT_QTY_UOP
               , FLP_PT_REJECT_QTY_UOP
               , FLP_CPT_REJECT_QTY_UOP
               , FLP_CONVERSION_FACTOR
               , FLP_SUP_QTY
               , FAL_ACI_TIME_HIST_HIST_ID
               , FAL_FAL_LOT_PROGRESS_HIST_ID
               , FLP_REVERSAL
                )
      select   FAL_LOT_PROGRESS_ID
             , FAL_LOT_ID
             , FAL_LOT_DETAIL_ID
             , FAL_SCHEDULE_STEP_ID
             , FAL_TASK_ID
             , FAL_FACTORY_FLOOR_ID
             , FAL_FAL_FACTORY_FLOOR_ID
             , PPS_TOOLS1_ID
             , PPS_TOOLS2_ID
             , PPS_TOOLS3_ID
             , PPS_TOOLS4_ID
             , PPS_TOOLS5_ID
             , PPS_TOOLS6_ID
             , PPS_TOOLS7_ID
             , PPS_TOOLS8_ID
             , PPS_TOOLS9_ID
             , PPS_TOOLS10_ID
             , PPS_TOOLS11_ID
             , PPS_TOOLS12_ID
             , PPS_TOOLS13_ID
             , PPS_TOOLS14_ID
             , PPS_TOOLS15_ID
             , PPS_OPERATION_PROCEDURE_ID
             , PPS_PPS_OPERATION_PROCEDURE_ID
             , DIC_REBUT_ID
             , DIC_WORK_TYPE_ID
             , DIC_OPERATOR_ID
             , LOT_REFCOMPL
             , FLP_PRODUCT_QTY
             , FLP_PT_REJECT_QTY
             , FLP_CPT_REJECT_QTY
             , FLP_ADJUSTING_TIME
             , FLP_WORK_TIME
             , FLP_AMOUNT
             , FLP_SHORT_DESCR
             , FLP_SEQ
             , FLP_LABEL_CONTROL
             , FLP_LABEL_REJECT
             , FLP_DATE1
             , FLP_DATE2
             , FLP_EAN_CODE
             , FLP_RATE
             , A_DATECRE
             , A_DATEMOD
             , A_IDCRE
             , A_IDMOD
             , A_RECLEVEL
             , A_RECSTATUS
             , A_CONFIRM
             , D_TRANSLATE
             , FLP_SEQ_ORIGIN
             , DIC_FREE_TASK_CODE2_ID
             , DIC_FREE_TASK_CODE_ID
             , FLP_ADJUSTING_RATE
             , FLP_MANUAL
             , DIC_UNIT_OF_MEASURE_ID
             , FLP_QTY_REF2_WORK
             , FLP_PRODUCT_QTY_UOP
             , FLP_PT_REJECT_QTY_UOP
             , FLP_CPT_REJECT_QTY_UOP
             , FLP_CONVERSION_FACTOR
             , FLP_SUP_QTY
             , FAL_ACI_TIME_HIST_ID
             , FAL_FAL_LOT_PROGRESS_ID
             , FLP_REVERSAL
          from FAL_LOT_PROGRESS
         where FAL_LOT_ID = iFAL_LOT_ID
      order by FAL_LOT_PROGRESS_ID asc;   -- Important pour FAL_FAL_LOT_PROGRESS_ID

    -- Archivage des FAL_LOT_PROGRES_DETAIL
    insert into FAL_LOT_PROGRES_DETAIL_HIST
                (FAL_LOT_PROGRES_DETAIL_HIST_ID
               , C_LOT_DETAIL_TYPE
               , FAL_LOT_PROGRESS_HIST_ID
               , FAL_LOT_DETAIL_HIST_ID
               , DIC_REBUT_ID
               , LPD_QTY
               , LPD_REJECT_DESCRIPTION
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
               , D_TRANSLATE
                )
      select FAL_LOT_PROGRESS_DETAIL_ID
           , C_LOT_DETAIL_TYPE
           , FAL_LOT_PROGRESS_ID
           , FAL_LOT_DETAIL_ID
           , DIC_REBUT_ID
           , LPD_QTY
           , LPD_REJECT_DESCRIPTION
           , A_DATECRE
           , A_DATEMOD
           , A_IDCRE
           , A_IDMOD
           , A_RECLEVEL
           , A_RECSTATUS
           , A_CONFIRM
           , D_TRANSLATE
        from FAL_LOT_PROGRESS_DETAIL
       where FAL_LOT_PROGRESS_ID in(select FAL_LOT_PROGRESS_ID
                                      from FAL_LOT_PROGRESS
                                     where FAL_LOT_ID = iFAL_LOT_ID);

    -- Archivage des FAL_LOT_DETAIL_LINK
    insert into FAL_LOT_DETAIL_LINK_HIST
                (FAL_LOT_DETAIL_LINK_HIST_ID
               , FAL_LOT_PROGRES_DETAIL_HIST_ID
               , FAL_LOT_DETAIL_HIST_ID
               , FAL_FACTORY_IN_HIST_ID
               , LDL_DESCRIPTION
               , LDL_QTY
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
               , D_TRANSLATE
                )
      select FAL_LOT_DETAIL_LINK_ID
           , FAL_LOT_PROGRESS_DETAIL_ID
           , FAL_LOT_DETAIL_ID
           , FAL_FACTORY_IN_ID
           , LDL_DESCRIPTION
           , LDL_QTY
           , A_DATECRE
           , A_DATEMOD
           , A_IDCRE
           , A_IDMOD
           , A_RECLEVEL
           , A_RECSTATUS
           , A_CONFIRM
           , D_TRANSLATE
        from FAL_LOT_DETAIL_LINK
       where FAL_LOT_DETAIL_ID in(select FAL_LOT_DETAIL_ID
                                    from FAL_LOT_DETAIL
                                   where FAL_LOT_ID = iFAL_LOT_ID);

    -- Archivage des FAL_ELT_COST_DIFF
    insert into FAL_ELT_COST_DIFF_HIST
                (FAL_ELT_COST_DIFF_HIST_ID
               , FAL_LOT_HIST_ID
               , PTC_ELEMENT_COST_ID
               , C_COST_ELEMENT_TYPE
               , C_COST_ELEMENT_SUBTYPE
               , DOC_NUMBER
               , CTD_DESCRIPTION
               , CTD_VALUE_DATE
               , CTD_EXPECTED_QTY
               , CTD_EXPECTED_UNIT_VALUE
               , CTD_EXPECTED_COST
               , CTD_REAL_QTY
               , CTD_REAL_UNIT_VALUE
               , CTD_REAL_COST
               , CTD_QTY_COST_DIFF
               , CTD_VALUE_COST_DIFF
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
                )
      select FAL_ELT_COST_DIFF_ID
           , FAL_LOT_ID
           , PTC_ELEMENT_COST_ID
           , C_COST_ELEMENT_TYPE
           , C_COST_ELEMENT_SUBTYPE
           , DOC_NUMBER
           , CTD_DESCRIPTION
           , CTD_VALUE_DATE
           , CTD_EXPECTED_QTY
           , CTD_EXPECTED_UNIT_VALUE
           , CTD_EXPECTED_COST
           , CTD_REAL_QTY
           , CTD_REAL_UNIT_VALUE
           , CTD_REAL_COST
           , CTD_QTY_COST_DIFF
           , CTD_VALUE_COST_DIFF
           , A_DATECRE
           , A_DATEMOD
           , A_IDCRE
           , A_IDMOD
           , A_RECLEVEL
           , A_RECSTATUS
           , A_CONFIRM
        from FAL_ELT_COST_DIFF
       where FAL_LOT_ID = iFAL_LOT_ID;

    -- Archivage des FAL_ELEMENT_COST
    insert into FAL_ELEMENT_COST_HIST
                (FAL_ELEMENT_COST_HIST_ID
               , FAL_LOT_HIST_ID
               , FAL_SCHEDULE_STEP_ID
               , FAL_LOT_MAT_LINK_HIST_ID
               , FAL_ACI_TIME_HIST_HIST_ID
               , C_COST_ELEMENT_TYPE
               , STM_STOCK_MOVEMENT_ID
               , FAL_ELT_COST_DIFF_HIST1_ID
               , FAL_ELT_COST_DIFF_HIST2_ID
               , FEC_CURRENT_AMOUNT
               , FEC_COMPLETED_AMOUNT
               , FEC_CURRENT_QUANTITY
               , FEC_COMPLETED_QUANTITY
               , A_DATECRE
               , A_IDCRE
               , A_DATEMOD
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
                )
      select FAL_ELEMENT_COST_ID
           , FAL_LOT_ID
           , FAL_SCHEDULE_STEP_ID
           , FAL_LOT_MATERIAL_LINK_ID
           , FAL_ACI_TIME_HIST_ID
           , C_COST_ELEMENT_TYPE
           , STM_STOCK_MOVEMENT_ID
           , FAL_ELT_COST_DIFF1_ID
           , FAL_ELT_COST_DIFF2_ID
           , FEC_CURRENT_AMOUNT
           , FEC_COMPLETED_AMOUNT
           , FEC_CURRENT_QUANTITY
           , FEC_COMPLETED_QUANTITY
           , A_DATECRE
           , A_IDCRE
           , A_DATEMOD
           , A_IDMOD
           , A_RECLEVEL
           , A_RECSTATUS
        from FAL_ELEMENT_COST
       where FAL_LOT_ID = iFAL_LOT_ID;

    -- Archivage des FAL_ELT_COST_DIFF_DET_HIST
    insert into FAL_ELT_COST_DIFF_DET_HIST
                (FAL_ELT_COST_DIFF_DET_HIST_ID
               , FAL_ELT_COST_DIFF_HIST_ID
               , ACI_DOCUMENT_ID
               , ACT_DOCUMENT_ID
               , C_FAL_ENTRY_KIND
               , C_FAL_ENTRY_SIGN
               , CDD_AMOUNT
               , ACS_FINANCIAL_ACCOUNT_ID
               , ACS_DIVISION_ACCOUNT_ID
               , ACS_CPN_ACCOUNT_ID
               , ACS_INITIAL_CPN_ACCOUNT_ID
               , ACS_CDA_ACCOUNT_ID
               , ACS_PF_ACCOUNT_ID
               , ACS_PJ_ACCOUNT_ID
               , ACS_QTY_UNIT_ID
               , DOC_RECORD_ID
               , FAM_FIXED_ASSETS_ID
               , C_FAM_TRANSACTION_TYP
               , GCO_GOOD_ID
               , HRM_HRM_PERSON_ID
               , PAC_PERSON_ID
               , PAC_THIRD_ID
               , DIC_IMP_FREE1_ID
               , DIC_IMP_FREE2_ID
               , DIC_IMP_FREE3_ID
               , DIC_IMP_FREE4_ID
               , DIC_IMP_FREE5_ID
               , IMF_NUMBER
               , IMF_NUMBER2
               , IMF_NUMBER3
               , IMF_NUMBER4
               , IMF_NUMBER5
               , IMF_TEXT1
               , IMF_TEXT2
               , IMF_TEXT3
               , IMF_TEXT4
               , IMF_TEXT5
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , A_RECLEVEL
               , A_RECSTATUS
               , A_CONFIRM
                )
      select FAL_ELT_COST_DIFF_DET_ID
           , FAL_ELT_COST_DIFF_ID
           , ACI_DOCUMENT_ID
           , ACT_DOCUMENT_ID
           , C_FAL_ENTRY_KIND
           , C_FAL_ENTRY_SIGN
           , CDD_AMOUNT
           , ACS_FINANCIAL_ACCOUNT_ID
           , ACS_DIVISION_ACCOUNT_ID
           , ACS_CPN_ACCOUNT_ID
           , ACS_INITIAL_CPN_ACCOUNT_ID
           , ACS_CDA_ACCOUNT_ID
           , ACS_PF_ACCOUNT_ID
           , ACS_PJ_ACCOUNT_ID
           , ACS_QTY_UNIT_ID
           , DOC_RECORD_ID
           , FAM_FIXED_ASSETS_ID
           , C_FAM_TRANSACTION_TYP
           , GCO_GOOD_ID
           , HRM_PERSON_ID
           , PAC_PERSON_ID
           , PAC_THIRD_ID
           , DIC_IMP_FREE1_ID
           , DIC_IMP_FREE2_ID
           , DIC_IMP_FREE3_ID
           , DIC_IMP_FREE4_ID
           , DIC_IMP_FREE5_ID
           , IMF_NUMBER
           , IMF_NUMBER2
           , IMF_NUMBER3
           , IMF_NUMBER4
           , IMF_NUMBER5
           , IMF_TEXT1
           , IMF_TEXT2
           , IMF_TEXT3
           , IMF_TEXT4
           , IMF_TEXT5
           , A_DATECRE
           , A_DATEMOD
           , A_IDCRE
           , A_IDMOD
           , A_RECLEVEL
           , A_RECSTATUS
           , A_CONFIRM
        from FAL_ELT_COST_DIFF_DET
       where FAL_ELT_COST_DIFF_ID in(select FAL_ELT_COST_DIFF_ID
                                       from FAL_ELT_COST_DIFF
                                      where FAL_LOT_ID = iFAL_LOT_ID);
  end;

  /**
  * procedure : creation_enreg_historie
  * Description : Création dans fal_histo lot d'un enreg de type historié (16)
  *
  * @created
  * @lastUpdate
  * @public
  * @param prmFAL_LOT : lot de fabrication.
  */
  procedure creation_enreg_historie(iFAL_LOT_ID number)
  is
  begin
    insert into FAL_HISTO_LOT_HIST
                (FAL_HISTO_LOT_HIST_ID
               , FAL_LOT_HIST5_ID
               , HIS_REFCOMPL
               , C_EVEN_TYPE
               , HIS_PLAN_BEGIN_DTE
               , HIS_PLAN_END_DTE
               , HIS_QTE
               , HIS_INPROD_QTE
               , HIS_EVEN_DTE
               , A_DATECRE
               , A_IDCRE
                )
      select GetNewId
           , FAL_LOT_ID
           , LOT_REFCOMPL
           , '16'
           , LOT_PLAN_BEGIN_DTE
           , LOT_PLAN_END_DTE
           , 0
           , 0
           , sysdate
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from FAL_LOT
       where FAL_LOT_ID = iFAL_LOT_ID;
  end;

  /**
  * procedure : BatchArchive
  * Description : Archivage de lots suivant un programme (ou tous) et une date fin
  *
  * @created ECA
  * @lastUpdate KLA 03.10.2013
  * @public
  * @param iFAL_JOB_PROGRAM_ID : Programme fabrication.
  * @param iLOT_FULL_REL_DTE : Date fin lot à considérer
  * @param iTypeArchivage : Type archivage (Lot, Lots\Ordres, Lots\Ordres\Programmes)
  * @param iSubcontractP : Archivage des lots liés à la sous-traitance d'achat
  * @param ioWarningCount : Messages d'erreurs
  * @param ioTotalBatch : Nbre de lots traités total
  */
  procedure BatchArchive(
    iFAL_JOB_PROGRAM_ID in     number
  , iLOT_FULL_REL_DTE   in     date
  , iTypeArchivage      in     integer
  , iSubcontractP       in     integer
  , ioWarningCount      in out integer
  , ioTotalBatch        in out integer
  )
  is
    tplBatches  FAL_LOT%rowtype;
    lbDoArchive boolean;

    cursor crBatches(prmFAL_JOB_PROGRAM_ID PCS_PK_ID, prmLOT_FULL_REL_DTE date, prmSubcontractP integer)
    is
      select   LOT.FAL_LOT_ID
             , LOT.FAL_ORDER_ID
             , LOT.FAL_JOB_PROGRAM_ID
             , LOT.LOT_REFCOMPL
          from FAL_LOT LOT
         where LOT.C_LOT_STATUS = '5'
           and (   nvl(prmFAL_JOB_PROGRAM_ID, 0) = 0
                or LOT.FAL_JOB_PROGRAM_ID = prmFAL_JOB_PROGRAM_ID)
           and LOT.LOT_FULL_REL_DTE <= prmLOT_FULL_REL_DTE
           and prmSubcontractP = (select sign(nvl(max(POS.FAL_LOT_ID), 0) )
                                    from DOC_POSITION POS
                                   where POS.FAL_LOT_ID = LOT.FAL_LOT_ID)
      order by FAL_JOB_PROGRAM_ID
             , FAL_ORDER_ID
             , FAL_LOT_ID;

    /* Récupère le nombre d'erreurs */
    procedure GetWarningCount
    is
    begin
      select count(*)
        into ioWarningCount
        from COM_LIST_ID_TEMP
       where LID_CODE = 'BATCH_ARCHIVE';
    end getWarningCount;
  begin
    ioTotalBatch  := 0;
    lbDoArchive   := true;

    -- Suppression avertissements
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'BATCH_ARCHIVE';

    for tplBatches in crBatches(iFAL_JOB_PROGRAM_ID, iLOT_FULL_REL_DTE, iSubcontractP) loop
      lbDoArchive   := true;
      ioTotalBatch  := ioTotalBatch + 1;
      -- Contrôle l'archivabilité du lot, remonte les évetuels avertissements
      ControlBeforeArchive(tplBatches.FAL_LOT_ID, iLOT_FULL_REL_DTE, lbDoArchive, null);

      -- Archivage
      if lbDoArchive then
        begin
          savepoint SP_BeforeArchive;
          -- Creation du programme si necessaire (on ne fait le test q'une fois)
          Creation_programme(tplBatches.FAL_JOB_PROGRAM_ID);
          -- Creation de l'ordre si necessaire
          Creation_ordre(tplBatches.FAL_ORDER_ID);
          -- Archivage du lot
          Archive_lot(tplBatches.FAL_LOT_ID);
          -- Orientation tables pesées, vers lots et tâches archivées.
          SetFalWeighWithLotHist(tplBatches.FAL_LOT_ID);
          -- Orientation des historique de lot vers les lots historiés
          SetHistoLotWithHistoLotHist(tplBatches.FAL_LOT_ID);
          -- On historie le lot
          Creation_enreg_historie(tplBatches.FAL_LOT_ID);
          -- Suppression du lot
          Supprime_lot(tplBatches.FAL_LOT_ID);
          -- On regarde si il y a lieu de supprimer l'ordre ou le programme du lot
          Test_suppression_ordre_program(tplBatches.FAL_ORDER_ID, tplBatches.FAL_JOB_PROGRAM_ID, iTypeArchivage);
        exception
          when others then
            begin
              rollback to savepoint SP_BeforeArchive;
              -- Erreur non rescencée métier.
              InsertWarningMsg(tplBatches.LOT_REFCOMPL, sqlcode || ' - ' || sqlerrm);
            end;
        end;
      end if;
    end loop;

    -- Nbre d'avertissements générés
    GetWarningCount;
  exception
    when others then
      begin
        -- Erreur non rescencée métier.
        InsertWarningMsg('Unknown', sqlcode || ' - ' || sqlerrm);
        GetWarningCount;
      end;
  end;

  /**
  * procedure : supprime_lots_archives
  * Description : Suppression des lots archivés, en fonction de leur date fin
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param     prmLOT_FULL_REL_DTE : Date fin à partir de laquelle la suppression des lots se fait.
  */
  procedure supprime_lots_archives(prmLOT_FULL_REL_DTE date)
  is
    varFAL_LOT_HIST_ID   FAL_LOT_HIST.FAL_LOT_HIST_ID%type;
    varFAL_ORDER_HIST_ID FAL_LOT_HIST.FAL_ORDER_HIST_ID%type;
    test_programme       integer;
    test_ordre           PCS_PK_ID;

    cursor C_Lot(prmLOT_FULL_REL_DTE date)
    is
      select   FAL_LOT_HIST_ID
             , FAL_ORDER_HIST_ID
          from FAL_LOT_HIST
         where LOT_FULL_REL_DTE <= prmLOT_FULL_REL_DTE
           and   -- il ne faut surtout pas détruire ceux qui serait dans FAL_TRACABILITY
               not exists(select 1
                            from FAL_TRACABILITY
                           where FAL_LOT_ID = FAL_LOT_HIST_ID)
           and   -- il ne faut surtout pas détruire ceux qui serait dans un dossier SAV
               not exists(select 1
                            from ASA_RECORD_EVENTS
                           where FAL_LOT_ID = FAL_LOT_HIST_ID)
           and   -- il ne faut surtout pas détruire ceux qui serait dans les historique de compta indus
               not exists(select 1
                            from FAL_ELEMENT_COST_HIST
                           where FAL_LOT_HIST_ID = FAL_LOT_HIST_ID)
      order by FAL_ORDER_HIST_ID;

    vCRUD_DEF            fwk_i_typ_definition.T_CRUD_DEF;
  begin
    open C_Lot(prmLOT_FULL_REL_DTE);

    loop
      fetch C_Lot
       into varFAL_LOT_HIST_ID
          , varFAL_ORDER_HIST_ID;

      exit when C_Lot%notfound;
      -- Suppression des pesées associées
      DeleteFalWeigh(varFAL_LOT_HIST_ID);
      -- On supprime la Foreign Key sur le lot hist dans les tables SQM_ANC_XXX
      DeleteSqmANCLotConstraint(varFAL_LOT_HIST_ID);

      -- Mise à jours des mouvements de stock relatifs aux entrées/Sorties atelier.
      begin
        for tplMovement in (select STM_STOCK_MOVEMENT_ID
                              from STM_STOCK_MOVEMENT
                             where (    FAL_FACTORY_IN_ID is not null
                                    and FAL_FACTORY_IN_ID in(select FIN.FAL_FACTORY_IN_ID
                                                               from FAL_FACTORY_IN FIN
                                                              where FIN.FAL_LOT_ID = varFAL_LOT_HIST_ID) )
                                or (    FAL_FACTORY_OUT_ID is not null
                                    and FAL_FACTORY_OUT_ID in(select FOU.FAL_FACTORY_OUT_ID
                                                                from FAL_FACTORY_OUT FOU
                                                               where FOU.FAL_LOT_ID = varFAL_LOT_HIST_ID) ) ) loop
          FWK_I_MGT_ENTITY.new(FWK_I_TYP_STM_ENTITY.gcStmStockMovement, vCRUD_DEF);
          FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'STM_STOCK_MOVEMENT_ID', tplMovement.STM_STOCK_MOVEMENT_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'FAL_FACTORY_IN_ID', cast(null as number) );
          FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'FAL_FACTORY_OUT_ID', cast(null as number) );
          FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'FAL_LOT_ID', cast(null as number) );
          FWK_I_MGT_ENTITY.UpdateEntity(vCRUD_DEF);
          FWK_I_MGT_ENTITY.Release(vCRUD_DEF);
        end loop;
      end;

      --Suppression du lot archivés
      Supprime_lot_hist(varFAL_LOT_HIST_ID);
      --On regarde si il y a lieu de supprimer l'ordre ou le programme du lot archivé
      test_sup_ordre_program_hist(varFAL_ORDER_HIST_ID);
    end loop;

    close C_Lot;
  end;
end;
