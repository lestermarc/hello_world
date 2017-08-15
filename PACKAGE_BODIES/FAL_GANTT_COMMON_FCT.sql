--------------------------------------------------------
--  DDL for Package Body FAL_GANTT_COMMON_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_GANTT_COMMON_FCT" 
is
  /**
  * procedure : PurgeTables
  *     Purge des tables de travail.
  *
  * @param iSessionID   Session Oracle
  */
  procedure PurgeTables(iSessionId in number)
  is
  begin
    -- Attention, l'ordre est important
    delete from FAL_GAN_LINKED_REQUIRT
          where FAL_GAN_SESSION_ID = iSessionId;

    delete from FAL_GAN_EXCEPTION
          where FAL_GAN_SESSION_ID = iSessionId;

    delete from FAL_GAN_ASSIGNMENT
          where FAL_GAN_SESSION_ID = iSessionId;

    delete from FAL_GAN_LINK
          where FAL_GAN_SESSION_ID = iSessionId;

    delete from FAL_GAN_OPERATION
          where FAL_GAN_SESSION_ID = iSessionId;

    delete from FAL_GAN_TASK
          where FAL_GAN_SESSION_ID = iSessionId;

    delete from FAL_GAN_WORK_RESOURCE
          where FAL_GAN_SESSION_ID = iSessionId;

    delete from FAL_GAN_TIMING_RESOURCE
          where FAL_GAN_SESSION_ID = iSessionId;

    delete from FAL_GAN_RESOURCE_GROUP
          where FAL_GAN_SESSION_ID = iSessionId;
  end PurgeTables;

  /**
  * procedure : StartSession
  *     Démarrer une session de planification
  *
  * @param   iSessionId   Session Oracle
  * @param  ioFalGanSessionID   ID de session
  * @param  ioFgsUpdateRights    Droits en modification des données
  * @param  ioConnectedUser Si existant, nom de l'utilisateur actuellement connecté au composant Gantt avec les droits de modification.
  */
  procedure StartSession(iSessionId in varchar2, ioFalGanSessionID in out number, ioFgsUpdateRights in out integer, ioConnectedUser in out varchar2)
  is
    cursor crCurrentSession
    is
      select FAL_GAN_SESSION_ID
           , FGS_ORACLE_SESSION
           , FGS_UPDATE_RIGHTS
        from FAL_GAN_SESSION;
  begin
    ioFgsUpdateRights  := 1;

    -- Suppression des sessions éventuellement invalides
    -- (Il y a éventuellement eut problème à la fermeture de l'objet)
    for tplCurrentSession in crCurrentSession loop
      if    COM_FUNCTIONS.Is_Session_Alive(tplCurrentSession.FGS_ORACLE_SESSION) = 0
         or tplCurrentSession.FGS_ORACLE_SESSION = iSessionId then
        EndSession(tplCurrentSession.FAL_GAN_SESSION_ID);
      else
        ioFgsUpdateRights  := ioFgsUpdateRights - tplCurrentSession.FGS_UPDATE_RIGHTS;
      end if;
    end loop;

    -- Insertion de la nouvelle session avec les droits si possible
    insert into FAL_GAN_SESSION
                (FAL_GAN_SESSION_ID
               , FGS_ORACLE_SESSION
               , FGS_UPDATE_RIGHTS
               , A_IDCRE
               , A_DATECRE
                )
         values (FAL_TMP_RECORD_SEQ.nextval
               , DBMS_SESSION.unique_session_id
               , ioFgsUpdateRights
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , sysdate
                )
      returning FAL_GAN_SESSION_ID
           into ioFalGanSessionID;

    -- Si un autre utilisateur est déjà connecté avec les droits de modifications, récupération de son nom d'utilisateur.
    -- FGS_ORACLE_SESSION contient l'identifiant de session unique (DBMS_SESSION.unique_session_id). Cet identifiant est
    -- formé de 3 fois 4 nombres hexadécimaux représentant l'Identifiant et le numéro de série de la session ainsi que le
    -- numéro de l'instance (RAC) Ex : 0097A6790001 -> SID = 151, SERIAL# = 42617 et INS_ID = 1. Sachant cela, on arrive
    -- à retrouver la ligne correspondante dans la vue GV$SESSION à partir d'un identifiant de session unique.
    if ioFgsUpdateRights = 0 then
      select USERNAME
        into ioConnectedUser
        from GV$SESSION
           , FAL_GAN_SESSION
       where sid = to_number(substr(FGS_ORACLE_SESSION, 1, 4), 'XXXX')
         and SERIAL# = to_number(substr(FGS_ORACLE_SESSION, 5, 4), 'XXXX')
         and INST_ID = to_number(substr(FGS_ORACLE_SESSION, 9, 4), 'XXXX')
         and type = 'USER'
         and FGS_UPDATE_RIGHTS = 1;
    end if;
  exception
    when others then
      begin
        ioFalGanSessionID  := null;
        ioFgsUpdateRights  := 0;
        raise;
      end;
  end StartSession;

  /**
  * procedure : EndSession
  *     Termine une session de planification
  *
  * @param iSessionId   Session Oracle
  */
  procedure EndSession(iSessionId in number)
  is
  begin
    -- Suppression des enregistrements de travail
    PurgeTables(iSessionId);

    -- Suppression enregistrement de session
    delete from FAL_GAN_SESSION
          where FAL_GAN_SESSION_ID = iSessionId;
  exception
    when others then
      raise;
  end EndSession;

/**
  * procedure : InsertGanResourceGroup
  * Description : Insertion des données à traiter dans la table GAN_RESOURCE_GROUP
  *               , contenant les informations de ressources groupées de type travail
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iSessionId   Session Oracle
  * @param   ioGroupForMachine Groupe pour les machines seules
  * @param   ioGroupForSupplier Groupe pour les fournisseurs
  * @param   ioGroupForByProduct Groupe par produit pour les DF
  */
  procedure InsertGanResourceGroup(iSessionId in number, ioGroupForMachine in out number, ioGroupForSupplier in out number, ioGroupForByProduct in out number)
  is
  begin
    -- Insertion des groupes de ressources (Ilots)
    insert into FAL_GAN_RESOURCE_GROUP
                (FAL_GAN_RESOURCE_GROUP_ID
               , FAL_FACTORY_FLOOR_ID
               , FAL_GAN_SESSION_ID
               , FGG_REFERENCE
               , FGG_DESCRIPTION
                )
      select FAL_TMP_RECORD_SEQ.nextval
           , FAC.FAL_FACTORY_FLOOR_ID
           , iSessionId
           , FAC.FAC_REFERENCE
           , FAC.FAC_DESCRIBE
        from FAL_FACTORY_FLOOR FAC
       where FAC.FAC_OUT_OF_ORDER = 0
         -- Ilots
         and FAC_IS_BLOCK = 1
         and exists(select 1
                      from FAL_FACTORY_FLOOR FAC2
                     where FAC2.FAL_FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID);

    -- Insertion d'un groupe par défaut pour les machines seules
    select FAL_TMP_RECORD_SEQ.nextval
      into ioGroupForMachine
      from dual;

    insert into FAL_GAN_RESOURCE_GROUP
                (FAL_GAN_RESOURCE_GROUP_ID
               , FAL_FACTORY_FLOOR_ID
               , FAL_GAN_SESSION_ID
               , FGG_REFERENCE
               , FGG_DESCRIPTION
                )
      select ioGroupForMachine
           , null
           , iSessionId
           , PCS.PC_FUNCTIONS.TRANSLATEWORD('Machines')
           , PCS.PC_FUNCTIONS.TRANSLATEWORD('Machines')
        from dual;

    -- Insertion d'un groupe par défaut pour les fournisseurs
    select FAL_TMP_RECORD_SEQ.nextval
      into ioGroupForSupplier
      from dual;

    insert into FAL_GAN_RESOURCE_GROUP
                (FAL_GAN_RESOURCE_GROUP_ID
               , FAL_FACTORY_FLOOR_ID
               , FAL_GAN_SESSION_ID
               , FGG_REFERENCE
               , FGG_DESCRIPTION
                )
      select ioGroupForSupplier
           , null
           , iSessionId
           , PCS.PC_FUNCTIONS.TRANSLATEWORD('Fournisseurs')
           , PCS.PC_FUNCTIONS.TRANSLATEWORD('Fournisseurs')
        from dual;

    -- Insertion d'un groupe par défaut pour les DF par produit
    select FAL_TMP_RECORD_SEQ.nextval
      into ioGroupForByProduct
      from dual;

    insert into FAL_GAN_RESOURCE_GROUP
                (FAL_GAN_RESOURCE_GROUP_ID
               , FAL_FACTORY_FLOOR_ID
               , FAL_GAN_SESSION_ID
               , FGG_REFERENCE
               , FGG_DESCRIPTION
                )
      select ioGroupForByProduct
           , null
           , iSessionId
           , cstResByProductName
           , cstResByProductDescr
        from dual;
  end InsertGanResourceGroup;

  /**
  * procedure : InsertGanTimingResource
  * Description : Insertion des données à traiter dans la table GAN_TIMING_RESOURCE
  *               , contenant les informations de ressources type travail
  * @created ECA
  * @lastUpdate
  * @public
  * @param   iSessionId   Session Oracle
  * @param   iGroupForMachine Groupe pour les machines seules
  * @param   iGroupForSupplier Groupe pour les fournisseurs
  * @param   ioGroupForByProduct Groupe par produit pour les DF
  */
  procedure InsertGanTimingResource(iSessionId in number, iGroupForMachine in number, iGroupForSupplier in number, ioGroupForByProduct in number)
  is
    lnDefltSchedule number;
  begin
    -- Calendrier par défaut
    lnDefltSchedule  := PAC_I_LIB_SCHEDULE.GetDefaultSchedule;

    -- Resources de type machines rattachée à un ilot.
    insert into FAL_GAN_TIMING_RESOURCE
                (FAL_GAN_TIMING_RESOURCE_ID
               , FAL_GAN_RESOURCE_GROUP_ID
               , FAL_GAN_SESSION_ID
               , FAL_FACTORY_FLOOR_ID
               , PAC_SUPPLIER_PARTNER_ID
               , PAC_SCHEDULE_ID
               , FTR_REFERENCE
               , FTR_DESCRIPTION
               , FTR_CALENDAR_NAME
               , FTR_CAPACITY
                )
      select FAL_TMP_RECORD_SEQ.nextval
           , FGG.FAL_GAN_RESOURCE_GROUP_ID
           , iSessionId
           , FAC.FAL_FACTORY_FLOOR_ID
           , null
           , nvl(FAC.PAC_SCHEDULE_ID, lnDefltSchedule)
           , FAC.FAC_REFERENCE
           , FAC.FAC_DESCRIBE
           , 'CAL_' || FAC.FAL_FACTORY_FLOOR_ID
           , nvl(ILOT.FAC_INFINITE_FLOOR, 0) + 1   -- 1 finite capacity 2 infinite capacity (ResourceCapacityTypeFieldIndex, VcResourceScheduler2)
        from FAL_FACTORY_FLOOR FAC
           , FAL_GAN_RESOURCE_GROUP FGG
           , FAL_FACTORY_FLOOR ILOT
       where FAC.FAC_OUT_OF_ORDER = 0
         and FGG.FAL_GAN_SESSION_ID = iSessionId
         and nvl(FAC.FAL_FAL_FACTORY_FLOOR_ID, FAC.FAL_FACTORY_FLOOR_ID) = FGG.FAL_FACTORY_FLOOR_ID(+)
         and (    FAC.FAC_IS_MACHINE = 1
              and FAC.FAL_FAL_FACTORY_FLOOR_ID is not null)
         and FAC.FAL_FAL_FACTORY_FLOOR_ID = ILOT.FAL_FACTORY_FLOOR_ID;

    -- Machines seules
    insert into FAL_GAN_TIMING_RESOURCE
                (FAL_GAN_TIMING_RESOURCE_ID
               , FAL_GAN_RESOURCE_GROUP_ID
               , FAL_GAN_SESSION_ID
               , FAL_FACTORY_FLOOR_ID
               , PAC_SUPPLIER_PARTNER_ID
               , PAC_SCHEDULE_ID
               , FTR_REFERENCE
               , FTR_DESCRIPTION
               , FTR_CALENDAR_NAME
               , FTR_CAPACITY
                )
      select FAL_TMP_RECORD_SEQ.nextval
           , iGroupForMachine
           , iSessionId
           , FAC.FAL_FACTORY_FLOOR_ID
           , null
           , nvl(FAC.PAC_SCHEDULE_ID, lnDefltSchedule)
           , FAC.FAC_REFERENCE
           , FAC.FAC_DESCRIBE
           , 'CAL_' || FAC.FAL_FACTORY_FLOOR_ID
           , nvl(FAC.FAC_INFINITE_FLOOR, 0) + 1
        from FAL_FACTORY_FLOOR FAC
       where FAC.FAC_OUT_OF_ORDER = 0
         and (    (    FAC.FAC_IS_MACHINE = 1
                   and FAC.FAL_FAL_FACTORY_FLOOR_ID is null)
              or (     (FAC.FAC_IS_BLOCK = 1)
                  and not exists(select 1
                                   from FAL_FACTORY_FLOOR FAC2
                                  where FAC2.FAL_FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID) )
             );

    -- Fournisseurs
    insert into FAL_GAN_TIMING_RESOURCE
                (FAL_GAN_TIMING_RESOURCE_ID
               , FAL_GAN_RESOURCE_GROUP_ID
               , FAL_GAN_SESSION_ID
               , FAL_FACTORY_FLOOR_ID
               , PAC_SUPPLIER_PARTNER_ID
               , PAC_SCHEDULE_ID
               , FTR_REFERENCE
               , FTR_DESCRIPTION
               , FTR_CALENDAR_NAME
               , FTR_CAPACITY
                )
      select FAL_TMP_RECORD_SEQ.nextval
           , iGroupForSupplier
           , iSessionId
           , null
           , SUP.PAC_SUPPLIER_PARTNER_ID
           , nvl(SUP.PAC_SCHEDULE_ID, lnDefltSchedule)
           , PER_NAME
           , PER_FORENAME
           , 'CAL_' || SUP.PAC_SUPPLIER_PARTNER_ID
           , 2   -- Capacité infinie
        from PAC_SUPPLIER_PARTNER SUP
           , PAC_PERSON PER
       where SUP.C_PARTNER_STATUS in('1', '2')
         and SUP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID
         and (   exists(select 1
                          from FAL_TASK_LINK TAL
                         where TAL.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID)
              or exists(select 1
                          from FAL_TASK_LINK_PROP TALPROP
                         where TALPROP.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID)
             );

    -- Machine virtuelle pour les éléments fabriqués selon produit
    insert into FAL_GAN_TIMING_RESOURCE
                (FAL_GAN_TIMING_RESOURCE_ID
               , FAL_GAN_RESOURCE_GROUP_ID
               , FAL_GAN_SESSION_ID
               , FAL_FACTORY_FLOOR_ID
               , PAC_SUPPLIER_PARTNER_ID
               , PAC_SCHEDULE_ID
               , FTR_REFERENCE
               , FTR_DESCRIPTION
               , FTR_CALENDAR_NAME
               , FTR_CAPACITY
                )
         values (FAL_TMP_RECORD_SEQ.nextval
               , ioGroupForByProduct
               , iSessionId
               , null
               , null
               , lnDefltSchedule
               , cstResByProductName
               , cstResByProductDescr
               , 'CAL_' || cstResByProductName
               , 2   -- Capacité infinie
                );

    -- Contrôle et modification de l'unicité de la référence des ressources
    for tpldoublons in (select   FTR_REFERENCE
                               , count(*) OCCURRENCE
                            from FAL_GAN_TIMING_RESOURCE
                          having count(*) > 1
                        group by FTR_REFERENCE) loop
      -- Pour chaque éléments, créer l'unicité
      for tplResource in (select   *
                              from FAL_GAN_TIMING_RESOURCE
                             where FTR_REFERENCE = tpldoublons.FTR_REFERENCE
                          order by FTR_REFERENCE) loop
        -- Si un atelier apparait, cela signifie qu'une ref d'atelier = nom de personne
        if tplResource.FAL_FACTORY_FLOOR_ID is not null then
          update FAL_GAN_TIMING_RESOURCE
             set FTR_REFERENCE = substr('(' || tplResource.FAL_FACTORY_FLOOR_ID || ')' || tplResource.FTR_REFERENCE, 0, 60)
           where FAL_GAN_TIMING_RESOURCE_ID = tplResource.FAL_GAN_TIMING_RESOURCE_ID;
        -- Si un fournisseur apparait, on créé l'unicité avec les PER_KEY1 ou PERK_KEY2
        elsif tplResource.PAC_SUPPLIER_PARTNER_ID is not null then
          update FAL_GAN_TIMING_RESOURCE
             set FTR_REFERENCE = substr( (select '(' || nvl(PER.PER_KEY1, PER.PER_KEY2) || ')' || PER.PER_NAME
                                            from PAC_PERSON PER
                                           where PER.PAC_PERSON_ID = tplResource.PAC_SUPPLIER_PARTNER_ID), 0, 60)
           where FAL_GAN_TIMING_RESOURCE_ID = tplResource.FAL_GAN_TIMING_RESOURCE_ID;
        end if;
      end loop;
    end loop;
  end InsertGanTimingResource;

  /**
  * procedure : GetPlanningBounds
  * Description : function qui renvoie les dates début et fin du planning
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   session oracle
  * @param  ioStartDate   Date début planning
  * @param  ioEndDate   Date fin planning
  */
  procedure GetPlanningBounds(iSessionId in number, ioStartDate in out date, ioEndDate in out date)
  is
    ldPlanStartDate date;
    ldReleaseDate   date;
    ldPlanEndDate   date;
    ldDueDate       date;
  begin
    -- Récupération des bornes de l'analyse
    select min(FGT_PLAN_START_DATE)
         , min(nvl(FGT_RELEASE_DATE, FGT_PLAN_START_DATE) )
         , max(FGT_PLAN_END_DATE)
         , max(nvl(FGT_DUE_DATE, FGT_PLAN_END_DATE) )
      into ldPlanStartDate
         , ldReleaseDate
         , ldPlanEndDate
         , ldDueDate
      from FAL_GAN_TASK
     where FAL_GAN_SESSION_ID = iSessionId
       and FGT_FILTER = 1;

    ioStartDate  := least(ldPlanStartDate, ldReleaseDate);
    ioEndDate    := greatest(ldPlanEndDate, ldDueDate);

    if ioStartDate is null then
      ioStartDate  := sysdate;
    end if;

    if ioEndDate is null then
      ioEndDate  := ioStartDate + 365;
    end if;
  exception
    when others then
      begin
        ioStartDate  := sysdate;
        ioEndDate    := sysdate + 365;
      end;
  end GetPlanningBounds;

   /**
  * function : GetGroupResourceByProductID
  * Description : function qui renvoie l'ID du groupe de la resource virtuelle utilisée
  *               pour les lots ou proposition de fabrications "par produit", c-a-d
  *               Dont la durée est indépendante de la gamme
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   session oracle
  */
  function GetGroupResourceByProductID(aSessionId number)
    return number
  is
    result number;
  begin
    select FAL_GAN_RESOURCE_GROUP_ID
      into result
      from FAL_GAN_RESOURCE_GROUP
     where FGG_REFERENCE = cstResByProductName
       and FAL_GAN_SESSION_ID = aSessionId;

    return result;
  exception
    when others then
      return null;
  end GetGroupResourceByProductID;

  /**
  * function : GetTimingResourceByProductID
  * Description : function qui renvoie l'ID de la resource virtuelle utilisée
  *               pour les lots ou proposition de fabrications "par produit", c-a-d
  *               Dont la durée est indépendante de la gamme
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   session oracle
  */
  function GetTimingResourceByProductID(aSessionId number)
    return number
  is
    result number;
  begin
    select FAL_GAN_TIMING_RESOURCE_ID
      into result
      from FAL_GAN_TIMING_RESOURCE
     where FTR_REFERENCE = cstResByProductName
       and FAL_FACTORY_FLOOR_ID is null
       and PAC_SUPPLIER_PARTNER_ID is null
       and FAL_GAN_RESOURCE_GROUP_ID is not null
       and FAL_GAN_SESSION_ID = aSessionId;

    return result;
  exception
    when others then
      return null;
  end GetTimingResourceByProductID;

  /**
  * procedure : InsertCommonResources
  * Description : Insertion des resources communes à tous les thèmes, et correspondant
  *               aux critères de l'interrogation courant
  *               Resources travail (work), machines (timing), groupes de resources...
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   Session Oracle
  */
  procedure InsertCommonResources(iSessionId in number)
  is
    lnGroupForMachine   number;
    lnGroupForSupplier  number;
    lnGroupForByProduct number;
  begin
    -- Insertion des groupes de ressources
    InsertGanResourceGroup(iSessionId, lnGroupForMachine, lnGroupForSupplier, lnGroupForByProduct);
    -- Insertion des ressources travail
    InsertGanTimingResource(iSessionId, lnGroupForMachine, lnGroupForSupplier, lnGroupForByProduct);
  end InsertCommonResources;

  /**
  * Function SetGanttHistory
  * Description
  *   lecture / ajout de l'historique Gantt
  * @param iHistoId         identifiant de l'historique ajouté
  * @param iContent        contenu de l'historique
  * @param iErrorMessages  a string were to return error messages.
  * @return a list of error codes. Detailed error messages are returned in
  *   aErrorMessages.
  */
  function SetGanttHistory(iHistoryId out number, iFormName in varchar2, iDate in date, iContent in blob, iErrorMessages out nocopy varchar2)
    return varchar2
  is
    vBlob      blob;
    vHistoryId number;
  begin
    insert into FAL_GAN_HISTORY
                (FAL_GAN_HISTORY_ID
               , PC_USER_ID
               , FGH_DATE
               , FGH_DESCR
               , FGH_FORM
               , A_DATECRE
               , A_IDCRE
                )
         values (GetNewId
               , PCS.PC_I_LIB_SESSION.GetUserId
               , iDate
               , sysdate
               , iFormName
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                )
      returning FAL_GAN_HISTORY_ID
           into vHistoryId;

    select FGH_DATA
      into vBlob
      from FAL_GAN_HISTORY
     where FAL_GAN_HISTORY_ID = vHistoryId;

    DBMS_LOB.open(vBlob, DBMS_LOB.lob_readwrite);
    DBMS_LOB.copy(vBlob, iContent, DBMS_LOB.getlength(iContent) );
    DBMS_LOB.close(vBlob);
    iHistoryId  := vHistoryId;
    return '';
  exception
    when others then
      iErrorMessages  := sqlerrm;
      return iErrorMessages;
  end SetGanttHistory;

  /**
   * Function GetGanttHistory
   * Description
   *   lecture / ajout de l'historique Gantt
   * @param iHistoId         identifiant de l'historique (-1 = ajout)
   * @param iContent        contenu de l'historique
   * @param iErrorMessages  a string were to return error messages.
   * @return a list of error codes. Detailed error messages are returned in
   *   aErrorMessages.
   */
  function GetGanttHistory(iHistoryId in number, iFormName out varchar2, iContent in out blob, iErrorMessages out nocopy varchar2)
    return varchar2
  is
  begin
    select FGH_DATA
         , FGH_FORM
      into iContent
         , iFormName
      from FAL_GAN_HISTORY
     where FAL_GAN_HISTORY_ID = iHistoryId;

    return '';
  exception
    when others then
      iErrorMessages  := sqlerrm;
      return iErrorMessages;
  end GetGanttHistory;

  /**
  * function : GetTaskCount
  * Description : function qui renvoie le nombre de tâches sélectionnées pour affichage
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   session oracle
  * @return  Nbre de tâches
  */
  function GetTaskCount(aSessionId number)
    return number
  is
    lnTaskCount number;
  begin
    select count(*)
      into lnTaskCount
      from FAL_GAN_TASK
     where FAL_GAN_SESSION_ID = aSessionId;

    return lnTaskCount;
  end;

  /**
  * procedure DeleteExceptions
  * Description : Suppression des enregistrements de la table des exceptions
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iSessionID      Session Oracle
  */
  procedure DeleteException(iSessionID in number)
  is
  begin
    delete from FAL_GAN_EXCEPTION
          where FAL_GAN_SESSION_ID = iSessionID;
  end DeleteException;

  /**
  * procedure InsertException
  * Description : Insertion d'une exception
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iSessionID                  Session Oracle
  * @param   iFGE_MESSAGE                Message explicatif
  * @param   iC_EXCEPTION_CODE           Code exception
  * @param   iFAL_GAN_TIMING_RESOURCE_ID Ressource
  * @param   iFAL_GAN_OPERATION_ID       Operation
  * @param   iFAL_GAN_TASK_ID            Tâche
  * @param   iFAL_GAN_ASSIGNMENT_ID      Assignation);
  */
  procedure InsertException(
    iSessionID                  in number
  , iFGE_MESSAGE                in varchar2
  , iC_EXCEPTION_CODE           in varchar2 default ''
  , iFAL_GAN_TIMING_RESOURCE_ID in number default null
  , iFAL_GAN_OPERATION_ID       in number default null
  , iFAL_GAN_TASK_ID            in number default null
  , iFAL_GAN_ASSIGNMENT_ID      in number default null
  )
  is
  begin
    -- Les exception de type '06' ne sont insérées qu'une seule fois par tâche
    -- (opérations qui sortent de l'horizon de planification)
    insert into FAL_GAN_EXCEPTION
                (FAL_GAN_EXCEPTION_ID
               , FGE_MESSAGE
               , C_EXCEPTION_CODE
               , FAL_GAN_ASSIGNMENT_ID
               , FAL_GAN_TIMING_RESOURCE_ID
               , FAL_GAN_OPERATION_ID
               , FAL_GAN_TASK_ID
               , FAL_GAN_SESSION_ID
                )
      select FAL_TMP_RECORD_SEQ.nextval
           , iFGE_MESSAGE
           , iC_EXCEPTION_CODE
           , iFAL_GAN_ASSIGNMENT_ID
           , iFAL_GAN_TIMING_RESOURCE_ID
           , iFAL_GAN_OPERATION_ID
           , iFAL_GAN_TASK_ID
           , iSessionID
        from dual
       where not exists(select 1
                          from FAL_GAN_EXCEPTION
                         where FAL_GAN_TASK_ID = iFAL_GAN_TASK_ID
                           and C_EXCEPTION_CODE = '06'
                           and FAL_GAN_SESSION_ID = iSessionID);
  end InsertException;

  /**
  * function GetExceptionCount
  * Description : Renvoie le nombre d'exceptions de la session
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iSessionID      Session Oracle
  */
  function GetExceptionCount(iSessionID in number)
    return number
  is
    result number;
  begin
    select count(*)
      into result
      from FAL_GAN_EXCEPTION
     where FAL_GAN_SESSION_ID = iSessionID;

    return result;
  end GetExceptionCount;

  /**
  * function GetTaskID
  * Description : Renvoie l'ID d'une tâche par rapport à sa description
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iSessionID      Session Oracle
  * @param   iTaskDescr      Description tâche
  * @return  ID de la tâche
  */
  function GetTaskID(iSessionID in number, iTaskDescr in varchar2)
    return number
  is
    lnresult number;
  begin
    select max(FAL_GAN_TASK_ID)
      into lnresult
      from FAL_GAN_TASK
     where FGT_REFERENCE like LIKE_PARAM(iTaskDescr);

    return lnresult;
  exception
    when others then
      return null;
  end GetTaskID;

  /**
  * function GetPlanningEndDate
  * Description : Renvoie la date fin du planning à utiliser dans le cas
  *               d'un ordonnancement JIT, date fin de la sélection par défaut.
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iSessionID      Session Oracle
  * @param   iDefltEndDate   Date fin sélection
  * @return  Date fin du planning
  */
  function GetPlanningEndDate(iSessionID in number, iDefltEndDate in date)
    return date
  is
    result date;
  begin
    select max(FGT.FGT_DUE_DATE)
      into result
      from FAL_GAN_TASK FGT
     where FGT.FAL_GAN_SESSION_ID = iSessionID;

    return nvl(result, iDefltEndDate);
  end GetPlanningEndDate;

  /**
  * procedure ResetFilters
  * Description : Remise à 0 des champs filtres
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iSessionID      Session Oracle
  */
  procedure Resetfilters(iSessionID in number)
  is
  begin
    update FAL_GAN_OPERATION FGO
       set FGO_FILTER = 0
     where FGO.FAL_GAN_SESSION_ID = iSessionID;

    update FAL_GAN_TASK FGT
       set FGT_FILTER = 0
     where FGT.FAL_GAN_SESSION_ID = iSessionId;
  end Resetfilters;

  /**
  * procedure UpdateTaskFilters
  * Description : Mise à jour des tâches filtrées
  *
  * @created ECA
  * @lastUpdate
  * @public
  *
  * @param   iSessionID      Session Oracle
  */
  procedure UpdateTaskFilters(iSessionID in number)
  is
  begin
    update FAL_GAN_TASK FGT
       set FGT_FILTER = 1
     where FGT.FAL_GAN_SESSION_ID = iSessionId
       and exists(select FAL_GAN_OPERATION_ID
                    from FAL_GAN_OPERATION FGO
                   where FGO.FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID
                     and FGO.FGO_FILTER = 1);
  end UpdateTaskFilters;
end FAL_GANTT_COMMON_FCT;
