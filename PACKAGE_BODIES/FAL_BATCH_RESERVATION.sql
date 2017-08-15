--------------------------------------------------------
--  DDL for Package Body FAL_BATCH_RESERVATION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_BATCH_RESERVATION" 
is
  -- ID unique de la session utilisé dans toutes les procédures de (dé)réservation
  cSessionId constant FAL_LOT1.LT1_ORACLE_SESSION%type   := DBMS_SESSION.unique_session_id;

  /**
  * procedure : DeleteBatch
  * Description : Suppression d'un OF en transaction autonome
  * @created CLE
  * @lastUpdate
  * @param    iFalLotId : Lot à supprimer
  */
  procedure DeleteBatch(iFalLotId number)
  is
    pragma autonomous_transaction;
  begin
    begin
      delete      FAL_LOT
            where FAL_LOT_ID = iFalLotId;
    exception
      when others then
        null;
    end;

    commit;
  end;

  /**
  * procedure : DeleteBatchSplitInprogress
  * Description : Suppression des OF en status "en cours d'éclatement" qui ne sont pas réservés
  *               (situation qui ne doit pas pouvoir exister)
  * @created CLE
  * @lastUpdate
  */
  procedure DeleteBatchSplitInprogress
  is
  begin
    for tplBatch in (select FAL_LOT_ID
                       from FAL_LOT LOT
                      where C_FAB_TYPE = '5'
                        and not exists(select *
                                         from FAL_LOT1
                                        where FAL_LOT_ID = LOT.FAL_LOT_ID) ) loop
      DeleteBatch(tplBatch.FAL_LOT_ID);
    end loop;
  end;

  /**
  * procedure : PurgeInactiveBatchReservation
  * Description : Suppression de toutes les réservations faites par des sessions qui pourraient être inactives
  *
  * @created ECA
  * @lastUpdate
  * @public
  */
  procedure PurgeInactiveBatchReservation
  is
    pragma autonomous_transaction;

    cursor crOracleSession
    is
      select distinct LT1_ORACLE_SESSION
                 from FAL_LOT1;
  begin
    for tplOracleSession in crOracleSession loop
      if COM_FUNCTIONS.Is_Session_Alive(tplOracleSession.LT1_ORACLE_SESSION) = 0 then
        -- Suppression des OF en cours d'éclatement liés à une réservation obsolète (OF créés par éclatements mal terminés)
        delete      FAL_LOT LOT
              where C_FAB_TYPE = '5'
                and exists(select *
                             from FAL_LOT1
                            where FAL_LOT_ID = LOT.FAL_LOT_ID
                              and LT1_ORACLE_SESSION = tplOracleSession.LT1_ORACLE_SESSION);

        -- Suppression des réservations obsolètes
        delete      FAL_LOT1
              where LT1_ORACLE_SESSION = tplOracleSession.LT1_ORACLE_SESSION;
      end if;
    end loop;

    commit;
  end;

  /**
  * procedure : InternalBatchReservation
  * Description : Réservation d'un lot de fabrication avec renvoi d'un code d'erreur en cas d'impossibilité de la réservation.
  * @created ECA
  * @lastUpdate
  * @public
  * @param    aFAL_LOT_ID : Lot à réserver
  * @param    aLT1_ORACLE_SESSION : Session oracle.
  * @param    aErrorMsg : Message d'erreur
  */
  procedure InternalBatchReservation(
    aFAL_LOT_ID         in     FAL_LOT.FAL_LOT_ID%type
  , aLT1_ORACLE_SESSION in     FAL_LOT1.LT1_ORACLE_SESSION%type default null
  , aDoCommit           in     boolean
  , aErrorMsg           in out varchar2
  )
  is
    lnCount integer;

    function GetUserOfBatch(aFalLotId number)
      return varchar2
    is
      aresult varchar2(30);
    begin
      select use.USE_NAME
        into aResult
        from fal_lot1 lot
           , pcs.pc_user use
       where lot.fal_lot_id = aFallotid
         and lot.A_IDCRE = use.USE_INI;

      return aresult;
    exception
      when others then
        return PCS.PC_PUBLIC.TranslateWord('Inconnu');
    end;
  begin
    select count(*)
      into lnCount
      from FAL_LOT
     where FAL_LOT_ID = aFAL_LOT_ID;

    if lnCount = 0 then
      aErrorMsg  := '0';
    else
      aErrorMsg  := null;
      -- Suppression d'une éventuelle réservation obsolète
      PurgeInactiveBatchReservation;

      begin
        insert into FAL_LOT1
                    (FAL_LOT1_ID
                   , FAL_LOT_ID
                   , GCO_GOOD_ID
                   , LT1_ORACLE_SESSION
                   , LT1_LOT_REFCOMPL
                   , LT1_SECONDARY_REF
                   , LT1_PSHORT_DESCR
                   , LT1_LOT_PLAN_BEGIN_DTE
                   , LT1_LOT_PLAN_END_DTE
                   , LT1_LOT_TOTAL_QTY
                   , LT1_LOT_MAX_FAB_QTY
                   , DOC_RECORD_ID
                   , C_PRIORITY
                   , DIC_FAMILY_ID
                   , LT1_FREE_QTY
                   , LT1_GIVE_QTY
                   , LT1_USER_ID
                   , LT1_CONTEXT
                   , A_DATECRE
                   , A_IDCRE
                    )
          select GetNewId
               , FAL_LOT_ID
               , GCO_GOOD_ID
               , nvl(aLT1_ORACLE_SESSION, cSessionId)
               , LOT_REFCOMPL
               , LOT_SECOND_REF
               , LOT_PSHORT_DESCR
               , LOT_PLAN_BEGIN_DTE
               , LOT_PLAN_END_DTE
               , LOT_TOTAL_QTY
               , LOT_MAX_PROD_QTY
               , DOC_RECORD_ID
               , C_PRIORITY
               , DIC_FAMILY_ID
               , LOT_FREE_QTY
               , LOT_ALLOCATED_QTY
               , 0   -- LT1_USER_ID
               , 0   -- LT1_CONTEXT
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
            from FAL_LOT
           where FAL_LOT_ID = aFAL_LOT_ID
             and not exists(select 1
                              from fal_lot1 lot1
                             where lot1.FAL_LOT_ID = aFAL_LOT_ID
                               and lot1.LT1_ORACLE_SESSION = nvl(aLT1_ORACLE_SESSION, cSessionId) );

        if aDoCommit then
          commit;
        end if;
      exception
        when dup_val_on_index then
          aErrorMsg  :=
            PCS.PC_PUBLIC.TranslateWord('Attention, ce lot est en cours de modification par un autre utilisateur.') ||
            chr(13) ||
            chr(10) ||
            PCS.PC_PUBLIC.TranslateWord('Ce lot n''est pas modifiable pour le moment.') ||
            chr(13) ||
            chr(10) ||
            PCS.PC_PUBLIC.TranslateWord('Utilisateur') ||
            ' : ' ||
            GetUserOfBatch(aFAL_LOT_ID);
        when others then
          raise;
      end;
    end if;
  end;

   /**
  * procedure : BatchReservation
  * Description : Réservation d'un lot de fabrication avec renvoi d'un code d'erreur en cas d'impossibilité de la réservation.
  *              -> procedure en mode transaction autonome
  * @created ECA
  * @lastUpdate
  * @public
  * @param    aFAL_LOT_ID : Lot à réserver
  * @param    aLT1_ORACLE_SESSION : Session oracle.
  * @param    aErrorMsg : Message d'erreur
  */
  procedure BatchReservation(
    aFAL_LOT_ID         in     FAL_LOT.FAL_LOT_ID%type
  , aLT1_ORACLE_SESSION in     FAL_LOT1.LT1_ORACLE_SESSION%type default null
  , aErrorMsg           in out varchar2
  )
  is
    pragma autonomous_transaction;
  begin
    InternalBatchReservation(aFAL_LOT_ID => aFAL_LOT_ID, aLT1_ORACLE_SESSION => aLT1_ORACLE_SESSION, aDoCommit => true, aErrorMsg => aErrorMsg);

    if aErrorMsg = '0' then
      aErrorMsg  := null;
    end if;
  end;

/**
  * procedure : BatchReservation
  * Description : Réservation d'un lot de fabrication, identique à la précédente
  *               , mais avec renvoi d'un code d'erreur en cas d'impossibilité de la réservation.
  *              -> procedure en mode transaction autonome
  * @created ECA
  * @lastUpdate
  * @public
  * @param    aFAL_LOT_ID : Lot à réserver
  * @param    aLT1_ORACLE_SESSION : Session oracle.
  * @param    aErrorMsg : Code erreur
  * @param   aFalLotIdFound : Code lot existant
  */
  procedure BatchReservation(
    aFAL_LOT_ID         in     FAL_LOT.FAL_LOT_ID%type
  , aLT1_ORACLE_SESSION in     FAL_LOT1.LT1_ORACLE_SESSION%type default null
  , aErrorMsg           in out varchar2
  , aFalLotIdFound      in out boolean
  )
  is
    pragma autonomous_transaction;
  begin
    InternalBatchReservation(aFAL_LOT_ID => aFAL_LOT_ID, aLT1_ORACLE_SESSION => aLT1_ORACLE_SESSION, aDoCommit => true, aErrorMsg => aErrorMsg);

    if aErrorMsg = '0' then
      aErrorMsg       := PCS.PC_PUBLIC.TranslateWord('Lot inexistant (Réservation)');
      aFalLotIdFound  := false;
    else
      aFalLotIdFound  := true;
    end if;
  end;

  /**
  * Description : Réservation des lots de fabrications liés à un document de
  *               sous-traitance opératoire
  */
  procedure BatchReservationSubcO(
    aDOC_DOCUMENT_ID    in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type default null
  , aDOC_POSITION_ID    in     DOC_POSITION.DOC_POSITION_ID%type default null
  , aLT1_ORACLE_SESSION in     FAL_LOT1.LT1_ORACLE_SESSION%type default null
  , aErrorMsg           in out varchar2
  )
  is
  begin
    for ltplLots in (select distinct TAL.FAL_LOT_ID
                                from DOC_POSITION POS
                                   , FAL_TASK_LINK TAL
                               where (   POS.DOC_DOCUMENT_ID = aDOC_DOCUMENT_ID
                                      or POS.DOC_POSITION_ID = aDOC_POSITION_ID)
                                 and TAL.FAL_SCHEDULE_STEP_ID = POS.FAL_SCHEDULE_STEP_ID) loop
      BatchReservation(aFAL_LOT_ID => ltplLots.FAL_LOT_ID, aLT1_ORACLE_SESSION => aLT1_ORACLE_SESSION, aErrorMsg => aErrorMsg);
    end loop;
  end BatchReservationSubcO;

  /**
  * Description
  *   Réservation des lots de fabrications planifiés d'une même gamme
  */
  procedure BatchReserveOnSchedulePlan(aSchedulePlanId in number default null, aOracleSession in varchar2 default null)
  is
    lvErrorMsg varchar2(2000);
  begin
    for tplBatch in (select distinct FAL_LOT_ID
                                from FAL_LOT
                               where FAL_SCHEDULE_PLAN_ID = aSchedulePlanId
                                 and C_LOT_STATUS = '1') loop
      BatchReservation(aFAL_LOT_ID => tplBatch.FAL_LOT_ID, aLT1_ORACLE_SESSION => aOracleSession, aErrorMsg => lvErrorMsg);
    end loop;
  end BatchReserveOnSchedulePlan;




  /**
  * Description : Réservation des lots de fabrications planifiés d'une mêmenomenclature
  * @created CLE
  * @lastUpdate
  * @public
  * @param    aNomenclatureId      Id de la nomenclature
  * @param    aOracleSession       Id Session Oracle
  */
  procedure BatchReserveOnNomenclature( aNomenclatureId in number default null, aOracleSession in varchar2 default null)
  is
    lvErrorMsg varchar2(2000);
  begin
    for tplBatch in (select distinct FAL_LOT_ID
                                from FAL_LOT
                               where PPS_NOMENCLATURE_ID = aNomenclatureId
                                 and C_LOT_STATUS = '1') loop
      BatchReservation(aFAL_LOT_ID => tplBatch.FAL_LOT_ID, aLT1_ORACLE_SESSION => aOracleSession, aErrorMsg => lvErrorMsg);
    end loop;
  end BatchReserveOnNomenclature;



  /**
  * procedure : ReleaseReservedbatches
  * Description : Suppression de toutes les réservations faites pour la session en cours
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aSessionId    Session ORACLE qui a fait la réservation
  */
  procedure ReleaseReservedbatches(aSessionId FAL_LOT1.LT1_ORACLE_SESSION%type default null)
  is
    pragma autonomous_transaction;
  begin
    delete from FAL_LOT1
          where LT1_ORACLE_SESSION = nvl(aSessionId, cSessionId);

    commit;
    PurgeInactiveBatchReservation;
    DeleteBatchSplitInprogress;
  end;

  /**
  * procedure : ReleaseBatch
  * Description : Libération du lot
  *
  * @created CLE
  * @lastUpdate JCH 24.09.2007
  * @public
  * @param   aFalLotId     Id du lot à libérer
  * @param   aSessionId    Session ORACLE qui a fait la réservation
  */
  procedure ReleaseBatch(aFalLotId FAL_LOT.FAL_LOT_ID%type, aSessionId FAL_LOT1.LT1_ORACLE_SESSION%type default null)
  is
    pragma autonomous_transaction;
  begin
    delete from FAL_LOT1
          where FAL_LOT_ID = aFalLotId
            and LT1_ORACLE_SESSION = nvl(aSessionId, cSessionId);

    commit;
    PurgeInactiveBatchReservation;
    DeleteBatchSplitInprogress;
  end;

  /**
  * procedure : BatchReservationOnLaunch
  * Description : Réservation d'un lot de fabrication au lancement des lots de fabrication
  * @created CLE
  * @lastUpdate
  * @public
  * @param    aSessionId              Id Session Oracle
  * @param    aErrorMsg               Code erreur retour
  */
  procedure BatchReservationOnLaunch(aSessionId FAL_LOT1.LT1_ORACLE_SESSION%type default null, aErrorMsg in out varchar2)
  is
    pragma autonomous_transaction;
    NbUnInsertedRows pls_integer;
    UnReservedBatchs varchar2(32767);
  begin
    NbUnInsertedRows  := 0;
    FAL_TOOLS.ResetCounter;
    FAL_TOOLS.ResetMsg;
    merge into FAL_LOT1 LOT1
      using (select LOT.FAL_LOT_ID
                  , LOT.GCO_GOOD_ID
                  , LOT.LOT_REFCOMPL
                  , LOT.LOT_SECOND_REF
                  , LOT.LOT_PSHORT_DESCR
                  , LOT.LOT_PLAN_BEGIN_DTE
                  , LOT.LOT_PLAN_END_DTE
                  , LOT.LOT_TOTAL_QTY
                  , LOT.LOT_MAX_PROD_QTY
                  , LOT.DOC_RECORD_ID
                  , LOT.C_PRIORITY
                  , LOT.C_LOT_STATUS
                  , LOT.DIC_FAMILY_ID
                  , LOT.LOT_FREE_QTY
                  , LOT.LOT_ALLOCATED_QTY
               from FAL_LOT LOT
                  , COM_LIST_ID_TEMP CIT
              where LOT.C_LOT_STATUS = '1'
                and CIT.LID_CODE = 'FAL_LOT_ID'
                and LOT.FAL_LOT_ID = CIT.COM_LIST_ID_TEMP_ID) LOT
      on (LOT1.FAL_LOT_ID = LOT.FAL_LOT_ID)
      when matched then
        update
           set LOT1.a_datemod =(case FAL_TOOLS.ConcatMsg(LOT.LOT_REFCOMPL)
                                  when 0 then LOT1.a_datemod
                                end)
      when not matched then
        insert(LOT1.FAL_LOT1_ID, LOT1.LT1_USER_ID, LOT1.FAL_LOT_ID, LOT1.GCO_GOOD_ID, LOT1.LT1_CONTEXT, LOT1.LT1_ORACLE_SESSION, LOT1.LT1_LOT_REFCOMPL
             , LOT1.LT1_SECONDARY_REF, LOT1.LT1_PSHORT_DESCR, LOT1.LT1_LOT_PLAN_BEGIN_DTE, LOT1.LT1_LOT_PLAN_END_DTE, LOT1.LT1_LOT_TOTAL_QTY
             , LOT1.LT1_LOT_MAX_FAB_QTY, LOT1.DOC_RECORD_ID, LOT1.C_PRIORITY, LOT1.C_LOT_STATUS, LOT1.DIC_FAMILY_ID, LOT1.LT1_FREE_QTY, LOT1.LT1_GIVE_QTY
             , LOT1.A_DATECRE, LOT1.A_IDCRE)
        values(case FAL_TOOLS.IncCounter
                 when 0 then GetNewId
               end, 0, LOT.FAL_LOT_ID, LOT.GCO_GOOD_ID, 0, aSessionId, LOT.LOT_REFCOMPL, LOT.LOT_SECOND_REF, LOT.LOT_PSHORT_DESCR, LOT.LOT_PLAN_BEGIN_DTE
             , LOT.LOT_PLAN_END_DTE, LOT.LOT_TOTAL_QTY, LOT.LOT_MAX_PROD_QTY, LOT.DOC_RECORD_ID, LOT.C_PRIORITY, LOT.C_LOT_STATUS, LOT.DIC_FAMILY_ID
             , LOT.LOT_FREE_QTY, LOT.LOT_ALLOCATED_QTY, sysdate, PCS.PC_I_LIB_SESSION.GetUserIni);
    -- Nombres de lignes non insérées car déjà existantes
    NbUnInsertedRows  := sql%rowcount - FAL_TOOLS.GetCounter;
    UnReservedBatchs  := PCS.PC_PUBLIC.TranslateWord('Lots non disponibles')|| ' : ' || chr(13) || chr(10) || FormattedMsgError(FAL_TOOLS.GetMsg,' / ');

    if NbUnInsertedRows > 0 then
      aErrorMsg  :=
        PCS.PC_PUBLIC.TranslateWord('Attention, certains lots sont en cours de modification par un autre utilisateur.') ||
        chr(13) ||
        chr(10) ||
        PCS.PC_PUBLIC.TranslateWord('Ils ne sont pas modifiables pour le moment.') ||
        chr(13) ||
        chr(10) ||
        UnReservedBatchs;
    end if;

    commit;
  exception
    when dup_val_on_index then
      aErrorMsg  :=
        PCS.PC_PUBLIC.TranslateWord('Attention, certains lots sont en cours de modification par un autre utilisateur.') ||
        chr(13) ||
        chr(10) ||
        PCS.PC_PUBLIC.TranslateWord('Ils ne sont pas modifiables pour le moment.');
  end;

  /**
  * procedure : BatchReservationOnAllocation
  * Description : Réservation des lots de fabrication en vue d'affectation de composants
  *               de stock vers lots
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param    aSessionId : Session oracle
  * @param    aGcoGoodId : Composant concerné par l'affectation
  * @param    aFAL_JOB_PROGRAM_ID : Programme de fabrication
  * @param    aC_PRIORITY : Priorité minimale
  * @param    aDOC_RECORD_ID : Dossier
  * @param    aContext : Integer
  * @param    aPriorityDate : Date de priorité
  * @return   aErrorMsg : Message d'erreur si certains lots n'ont pu être réservés.
  */
  procedure BatchReservationOnAllocation(
    aSessionId          in     FAL_LOT1.LT1_ORACLE_SESSION%type default null
  , aGcoGoodId          in     number
  , aFAL_JOB_PROGRAM_ID in     number
  , aC_PRIORITY         in     varchar2
  , aDOC_RECORD_ID      in     number
  , aContext            in     integer
  , aPriorityDate       in     date default null
  , aErrorMsg           in out varchar2
  )
  is
    NbUnInsertedRows pls_integer;
    UnReservedBatchs varchar2(32000);
  begin
    NbUnInsertedRows  := 0;
    FAL_TOOLS.ResetCounter;
    FAL_TOOLS.ResetMsg;
    merge into FAL_LOT1 LOT1
      using (select distinct LOT.FAL_LOT_ID
                           , LOT.GCO_GOOD_ID
                           , LOT.LOT_REFCOMPL
                           , LOT.LOT_SECOND_REF
                           , LOT.LOT_PSHORT_DESCR
                           , LOT.LOT_PLAN_BEGIN_DTE
                           , LOT.LOT_PLAN_END_DTE
                           , LOT.LOT_TOTAL_QTY
                           , LOT.LOT_MAX_PROD_QTY
                           , LOT.DOC_RECORD_ID
                           , LOT.C_PRIORITY
                           , LOT.C_LOT_STATUS
                           , LOT.DIC_FAMILY_ID
                           , LOT.LOT_FREE_QTY
                           , LOT.LOT_ALLOCATED_QTY
                        from FAL_LOT LOT
                           , FAL_LOT_MATERIAL_LINK LOM
                       where LOM.GCO_GOOD_ID = aGcoGoodId
                         and LOM.C_KIND_COM = 1
                         and LOM.C_TYPE_COM = 1
                         and LOM.FAL_LOT_ID = LOT.FAL_LOT_ID
                         and LOT.C_LOT_STATUS = 2
                         and (   nvl(aFAL_JOB_PROGRAM_ID, 0) = 0
                              or LOT.FAL_JOB_PROGRAM_ID = aFAL_JOB_PROGRAM_ID)
                         and (   aC_PRIORITY is null
                              or LOT.C_PRIORITY <= aC_PRIORITY)
                         and (   nvl(aDOC_RECORD_ID, 0) = 0
                              or LOT.DOC_RECORD_ID = aDOC_RECORD_ID)
                         and (    (    acontext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtStockToBatchAllocation
                                   and nvl(LOM.LOM_NEED_QTY, 0) > 0)
                              or (    aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchToStockAllocation
                                  and (nvl(LOM.LOM_CONSUMPTION_QTY, 0) -
                                       nvl(LOM.LOM_REJECTED_QTY, 0) -
                                       nvl(LOM.LOM_BACK_QTY, 0) -
                                       nvl(LOM.LOM_CPT_RECOVER_QTY, 0) -
                                       nvl(LOM.LOM_CPT_REJECT_QTY, 0) -
                                       nvl(LOM.LOM_EXIT_RECEIPT, 0)
                                      ) > 0
                                 )
                             )
                         and (    (aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtStockToBatchAllocation)
                              or (    aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchToStockAllocation
                                  and (   aPriorityDate is null
                                       or (    LOT.LOT_PLAN_END_DTE is not null
                                           and LOM.LOM_NEED_DATE is not null
                                           and LOT.LOT_PLAN_END_DTE > aPriorityDate
                                           and LOM.LOM_NEED_DATE > aPriorityDate
                                          )
                                       or (    LOT.LOT_PLAN_END_DTE is null
                                           and LOM.LOM_NEED_DATE is not null
                                           and LOM.LOM_NEED_DATE > aPriorityDate)
                                       or (    LOT.LOT_PLAN_END_DTE is not null
                                           and LOM.LOM_NEED_DATE is null
                                           and LOT.LOT_PLAN_END_DTE > aPriorityDate)
                                      )
                                 )
                             ) ) LOT
      on (LOT1.FAL_LOT_ID = LOT.FAL_LOT_ID)
      when matched then
        update
           set LOT1.a_datemod =(case FAL_TOOLS.ConcatMsg(LOT.LOT_REFCOMPL)
                                  when 0 then LOT1.a_datemod
                                end)
      when not matched then
        insert(LOT1.FAL_LOT1_ID, LOT1.LT1_USER_ID, LOT1.FAL_LOT_ID, LOT1.GCO_GOOD_ID, LOT1.LT1_CONTEXT, LOT1.LT1_ORACLE_SESSION, LOT1.LT1_LOT_REFCOMPL
             , LOT1.LT1_SECONDARY_REF, LOT1.LT1_PSHORT_DESCR, LOT1.LT1_LOT_PLAN_BEGIN_DTE, LOT1.LT1_LOT_PLAN_END_DTE, LOT1.LT1_LOT_TOTAL_QTY
             , LOT1.LT1_LOT_MAX_FAB_QTY, LOT1.DOC_RECORD_ID, LOT1.C_PRIORITY, LOT1.C_LOT_STATUS, LOT1.DIC_FAMILY_ID, LOT1.LT1_FREE_QTY, LOT1.LT1_GIVE_QTY
             , LOT1.A_DATECRE, LOT1.A_IDCRE)
        values(case FAL_TOOLS.IncCounter
                 when 0 then GetNewId
               end, 0, LOT.FAL_LOT_ID, LOT.GCO_GOOD_ID, 0, aSessionId, LOT.LOT_REFCOMPL, LOT.LOT_SECOND_REF, LOT.LOT_PSHORT_DESCR, LOT.LOT_PLAN_BEGIN_DTE
             , LOT.LOT_PLAN_END_DTE, LOT.LOT_TOTAL_QTY, LOT.LOT_MAX_PROD_QTY, LOT.DOC_RECORD_ID, LOT.C_PRIORITY, LOT.C_LOT_STATUS, LOT.DIC_FAMILY_ID
             , LOT.LOT_FREE_QTY, LOT.LOT_ALLOCATED_QTY, sysdate, PCS.PC_I_LIB_SESSION.GetUserIni);
    -- Nombres de lignes non insérées car déjà existantes
    NbUnInsertedRows  := sql%rowcount - FAL_TOOLS.GetCounter;
    UnReservedBatchs  := PCS.PC_PUBLIC.TranslateWord('Lots non disponibles') || ' : ' || FormattedMsgError(FAL_TOOLS.GetMsg,' / ');


    if NbUnInsertedRows > 0 then
      aErrorMsg  :=
        PCS.PC_PUBLIC.TranslateWord('Attention, certains lots sont en cours de modification par un autre utilisateur.') ||
        chr(13) ||
        chr(10) ||
        PCS.PC_PUBLIC.TranslateWord('Ils ne sont pas modifiables pour le moment.') ||
        chr(13) ||
        chr(10) ||
        UnReservedBatchs;
    end if;
  exception
    when dup_val_on_index then
      aErrorMsg  :=
        PCS.PC_PUBLIC.TranslateWord('Attention, certains lots sont en cours de modification par un autre utilisateur.') ||
        chr(13) ||
        chr(10) ||
        PCS.PC_PUBLIC.TranslateWord('Ils ne sont pas modifiables pour le moment.');
  end;

  /**
  * Description
  *    Retourne 1 si le lot transmis en paramètre est réservé
  */
  function isBatchReserved(iLotID in FAL_LOT.FAL_LOT_ID%type)
    return number
  is
    lIsBatchReserved number := 0;
  begin
    select FAL_LOT_ID
      into lIsBatchReserved
      from FAL_LOT1
     where COM_FUNCTIONS.Is_Session_Alive(LT1_ORACLE_SESSION) = 1
       and FAL_LOT_ID = iLotID;

    return sign(lIsBatchReserved);
  exception
    when no_data_found then
      return 0;
  end isBatchReserved;

/**
* Description
*   Retourne le message d'erreur formaté sur dix lignes au max, chaque ligne contient cinq références de lot concaténées avec aSeparator
*/

  function FormattedMsgError(iMsgError in varchar2, iSeparator in char)
    return varchar2
  is
    lSplittedMsg   PCS.PC_UTL_SHUTTLE.tVarcharArray;
    lFormattedMsg varchar2(32767);
    lNbrLot number;
  begin
    lSplittedMsg    := PCS.PC_UTL_SHUTTLE.split(replace(iMsgError, chr(10) ), chr(13) );
    -- On n'affiche au maximum que 49 lots
    lNbrLot := least(49, lSplittedMsg.count);
    for i in 1 .. lNbrLot loop
      lFormattedMsg  := lFormattedMsg || lSplittedMsg(i);
      -- Si on ne se trouve pas sur le dernier
      if i < lNbrLot then
        -- Si on est sur un multiple de cinq
        if (mod(i, 5) = 0) then
          lFormattedMsg  := lFormattedMsg || co.cLineBreak;
        else
          lFormattedMsg  := lFormattedMsg || ' ' || iSeparator ||' ';
        end if;
      end if;
    end loop;
    -- S'il y a plus de 49 lots réservés
    if lSplittedMsg.count > 49 then
      lFormattedMsg  := lFormattedMsg || ' ' ||iSeparator || ' ...';
    end if;
    return lFormattedMsg;
  end FormattedMsgError;
end;
