--------------------------------------------------------
--  DDL for Package Body FAL_LIB_GANTT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_LIB_GANTT" 
is
  /**
  * Description
  *    Retourne la liste des ID des tâches (lots) liées à la tâche transmise.
  */
  procedure pGetLinkedGanTaskIDs(
    iSessionID         in     FAL_GAN_LINK.FAL_GAN_SESSION_ID%type
  , iGanTaskID         in     FAL_GAN_LINK.FAL_GAN_SUCC_TASK_ID%type
  , ioLinkedGanTaskIDs in out ID_TABLE_TYPE
  )
  as
  begin
    -- Ajout de la tâche traitée dans la liste.
    ioLinkedGanTaskIDs.extend(1);
    ioLinkedGanTaskIDs(ioLinkedGanTaskIDs.count)  := iGanTaskID;

    -- Recherche récursive des tâches (lot) prédécesseurs
    for ltplPredecessor in (select column_value
                              from table(FAL_LIB_GANTT.getPredecessorGanTasksIDs(iSessionID, iGanTaskID, ioLinkedGanTaskIDs) ) ) loop
      pGetLinkedGanTaskIDs(iSessionID, ltplPredecessor.column_value, ioLinkedGanTaskIDs);
    end loop;

    -- Recherche récursive des tâches (lots) sucesseurs
    for ltplSucesseor in (select column_value
                            from table(FAL_LIB_GANTT.getSuccessorGanTasksIDs(iSessionID, iGanTaskID, ioLinkedGanTaskIDs) ) ) loop
      pGetLinkedGanTaskIDs(iSessionID, ltplSucesseor.column_value, ioLinkedGanTaskIDs);
    end loop;
  end pGetLinkedGanTaskIDs;

  /**
  * Description
  *    Retourne la liste des ID des tâches directement liées précédentes de 1er niveau qui ne se trouvent pas dans la liste
  */
  function getPredecessorGanTasksIDs(
    iSessionID        in FAL_GAN_LINK.FAL_GAN_SESSION_ID%type
  , iGanTaskID        in FAL_GAN_LINK.FAL_GAN_SUCC_TASK_ID%type
  , iLinkedGanTaskIDs in ID_TABLE_TYPE
  )
    return ID_TABLE_TYPE pipelined
  as
  begin
    for ltplPredecessor in (select FAL_GAN_PRED_TASK_ID
                              from FAL_GAN_LINK
                             where FAL_GAN_SESSION_ID = iSessionID
                               and FGL_BETWEEN_OP = 0
                               and FAL_GAN_SUCC_TASK_ID = iGanTaskID
                               and not exists(select column_value
                                                from table(PCS.IdTableTypeToTable(iLinkedGanTaskIDs) )
                                               where column_value = FAL_GAN_PRED_TASK_ID) ) loop
      pipe row(ltplPredecessor.FAL_GAN_PRED_TASK_ID);
    end loop;
  exception
    when NO_DATA_NEEDED then
      return;
  end getPredecessorGanTasksIDs;

  /**
  * Description
  *    Retourne la liste des ID des tâches directement liées précédentes de 1er niveau qui ne se trouvent pas dans la liste
  */
  function getSuccessorGanTasksIDs(
    iSessionID        in FAL_GAN_LINK.FAL_GAN_SESSION_ID%type
  , iGanTaskID        in FAL_GAN_LINK.FAL_GAN_SUCC_TASK_ID%type
  , iLinkedGanTaskIDs in ID_TABLE_TYPE
  )
    return ID_TABLE_TYPE pipelined
  as
  begin
    for lptlSuccessor in (select FAL_GAN_SUCC_TASK_ID
                            from FAL_GAN_LINK
                           where FAL_GAN_SESSION_ID = iSessionID
                             and FGL_BETWEEN_OP = 0
                             and FAL_GAN_PRED_TASK_ID = iGanTaskID
                             and not exists(select column_value
                                              from table(PCS.IdTableTypeToTable(iLinkedGanTaskIDs) )
                                             where column_value = FAL_GAN_SUCC_TASK_ID) ) loop
      pipe row(lptlSuccessor.FAL_GAN_SUCC_TASK_ID);
    end loop;
  exception
    when NO_DATA_NEEDED then
      return;
  end getSuccessorGanTasksIDs;

  /**
  * Description
  *    Retourne la liste des ID des tâches (lots) liées à la tâche transmise.
  */
  function getLinkedGanTaskIDs(iSessionID in FAL_GAN_LINK.FAL_GAN_SESSION_ID%type, iGanTaskID in FAL_GAN_LINK.FAL_GAN_SUCC_TASK_ID%type)
    return ID_TABLE_TYPE pipelined
  as
    lttGanLinkedTaskIDs ID_TABLE_TYPE := ID_TABLE_TYPE();
  begin
    pGetLinkedGanTaskIDs(iSessionID => iSessionID, iGanTaskID => iGanTaskID, ioLinkedGanTaskIDs => lttGanLinkedTaskIDs);

    if lttGanLinkedTaskIDs.count > 0 then
      for i in lttGanLinkedTaskIDs.first .. lttGanLinkedTaskIDs.last loop
        pipe row(lttGanLinkedTaskIDs(i) );
      end loop;
    end if;
  exception
    when NO_DATA_NEEDED then
      return;
  end getLinkedGanTaskIDs;

  /**
  * Description
  *    Retourne la priorité d'ordonnancement la plus élevée du planning.
  *    Si pas de priorité définie (-1), retourne 0
  */
  function getHighestTaskPriority(iSessionID in FAL_GAN_TASK.FAL_GAN_SESSION_ID%type)
    return FAL_GAN_TASK.FGT_PRIORITY%type
  as
    lHighestTaskPriority FAL_GAN_TASK.FGT_PRIORITY%type;
  begin
    select greatest(nvl(max(FGT_PRIORITY), 0), 0)
      into lHighestTaskPriority
      from FAL_GAN_TASK
     where FAL_GAN_SESSION_ID = iSessionID;

    return lHighestTaskPriority;
  end getHighestTaskPriority;

  /**
  * Description
  *   Détermine s'il existe un filtre d'affichage dans le gantt
  */
  function GanttDisplayFilter(iSessionID in number)
    return number
  is
    lnResult number(1) := 0;
  begin
    begin
      select sign(nvl(max(FGT.FAL_GAN_TASK_ID), 0) ) FILTER_EXIST
        into lnResult
        from FAL_GAN_TASK FGT
       where FGT.FAL_GAN_SESSION_ID = iSessionID
         and FGT_FILTER = 0;

      return lnResult;
    exception
      when no_data_found then
        -- si pas trouvé
        return 0;
    end;
  end GanttDisplayFilter;

  /**
  * Description
  *   Retourne le nom du client/ fournisseur du tiers pour une Appro ou un besoin liés
  *   (FDP : FAL_DOC_PROP ou DMT : DOC_DOCUMENT)
  */
  function getThirdName(iDescription in FAL_GAN_LINKED_REQUIRT.FLR_DESCRIPTION%type)
    return PAC_PERSON.PER_NAME%type
  is
    lResult PAC_PERSON.PER_NAME%type   := '';
  begin
    begin
      select PER.PER_NAME
        into lResult
        from FAL_DOC_PROP FDP
           , PAC_PERSON PER
       where FDP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID
         and (PCS.PC_FUNCTIONS.GetDescodeCode('C_PREFIX_PROP', FDP.C_PREFIX_PROP, PCS.PC_I_LIB_SESSION.GetCompLangId) || '-' || FDP.FDP_NUMBER) = iDescription;

      return lResult;
    exception
      when no_data_found then
        begin
          select PER.PER_NAME
            into lResult
            from DOC_DOCUMENT DMT
               , PAC_PERSON PER
           where DMT.PAC_THIRD_ID = PER.PAC_PERSON_ID
             and DMT.DMT_NUMBER = iDescription;

          return lResult;
        exception
          when no_data_found then
            -- si pas trouvé
            return '';
        end;
    end;
  end getThirdName;

  /**
  * fonction getStartSessionTime
  * Description
  *    Retourne la date/heure de la création de la session Gantt.
  */
  function getStartSessionTime
    return date
  as
    lRes date;
  begin
    select A_DATECRE
      into lRes
      from FAL_GAN_SESSION
     where FGS_ORACLE_SESSION = DBMS_SESSION.unique_session_id;

    return lRes;
  exception
    when no_data_found then
      return sysdate - 10;
  end getStartSessionTime;

  /**
  * fonction doCalculateRemainingTime
  * Description
  * Si les conditions ci-dessous sont remplies, la durée de l'opération est calculée avec la durée restante en minute
  * depuis l'instant présent (sysdate) jusqu'à iTAL_END_PLAN_DATE.
  * Conditions :
  * 1. l'opération est externe
  * 2. sa date début est dans le passé
  * 3. le lot est lancé
  * 4. il existe au moins un CST liée confirmée (= avec statut différent de 'à confirmer')
  * 5. toutes les opérations précédentes sont réalisées (ou l'opération est en première position) (Somme TAL_DUE_QTY des op. précédente = 0)
  */
  function doCalculateRemainingTime(
    iLotId             in FAL_GAN_TASK.FAL_LOT_ID%type
  , iTaskId            in FAL_GAN_OPERATION.FAL_SCHEDULE_STEP_ID%type
  , itaskType          in FAL_GAN_OPERATION.C_TASK_TYPE%type
  , iTaskBeginPlanDate in FAL_GAN_OPERATION.FGO_PLAN_START_DATE%type
  )
    return number
  as
  begin
    return FAL_LIB_TASK_LINK.doCalculateRemainingTime(iLotId => iLotId, iTaskId => iTaskId, itaskType => itaskType, iTaskBeginPlanDate => iTaskBeginPlanDate);
  end doCalculateRemainingTime;
end FAL_LIB_GANTT;
