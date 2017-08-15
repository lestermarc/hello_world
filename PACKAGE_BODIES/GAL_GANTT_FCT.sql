--------------------------------------------------------
--  DDL for Package Body GAL_GANTT_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_GANTT_FCT" 
is
  -- Configurations
  /* Spécification de l'utilisation du temps de transfert de l'opération (SCS_TRANSFERT_TIME) */
  cFAL_GANTT_TRANSFERT_TIME constant varchar2(255) := PCS.PC_CONFIG.GetConfigUpper('FAL_GANTT_TRANSFERT_TIME');
  /* Unité de saisie (heures ou minutes) des valeurs de temps associées au Travail */
  cWorkUnits                constant number        := case PCS.PC_CONFIG.GetConfig('PPS_WORK_UNIT')
    when 'M' then 1
    else 60
  end;

  /**
   * procedure : InsertLinkedRequirements
   * Description : Chargement de la table des dates d'achat et d'appro log
   *
   * @created AGA
   * @lastUpdate
   * @public
   *
   * @param   iSessionId      Session Oracle
   */
  procedure InsertLinkedRequirements(iSessionId in number)
  is
  begin
    -- traitement des tâches GAL
    insert into FAL_GAN_LINKED_REQUIRT
                (FAL_GAN_LINKED_REQUIRT_ID
               , FAL_GAN_TASK_ID
               , FAL_GAN_SESSION_ID
               , FLR_REFERENCE
               , FLR_DESCRIPTION
               , FLR_BASIS_START_DATE
               , FLR_BASIS_END_DATE
               , FLR_START_DATE
               , FLR_END_DATE
               , FLR_PIVOT
               , FLR_REQUIREMENT
               , DOC_POSITION_DETAIL_ID
               , FAL_DOC_PROP_ID
               , GAL_TASK_ID
               , DOC_RECORD_ID
                )
      select FAL_TMP_RECORD_SEQ.nextval
           , FAL_GAN_TASK_ID
           , iSessionId
           , FLR_REFERENCE
           , FLR_DESCRIPTION
           , FLR_BASIS_START_DATE
           , FLR_BASIS_END_DATE
           , FLR_START_DATE
           , FLR_END_DATE
           , FLR_PIVOT
           , FLR_REQUIRMENT
           , DOC_POSITION_DETAIL_ID
           , FAL_DOC_PROP_ID
           , GAL_TASK_ID
           , DOC_RECORD_ID
        from (   -- attribution de type lots affaire sur POA
              select FGT.FAL_GAN_TASK_ID
                   , POA.C_PREFIX_PROP || '-' || POA.FDP_NUMBER FLR_REFERENCE
                   , POA.FDP_PSHORT_DESCR FLR_DESCRIPTION
                   , null FLR_BASIS_START_DATE
                   , POA.FDP_BASIS_DELAY FLR_BASIS_END_DATE
                   , null FLR_START_DATE
                   , null FLR_END_DATE
                   , 0 FLR_PIVOT
                   , 0 FLR_REQUIRMENT
                   , null DOC_POSITION_DETAIL_ID
                   , POA.FAL_DOC_PROP_ID
                   , FGT.GAL_TASK_ID
                   , FGT.DOC_RECORD_ID
                from FAL_GAN_TASK FGT
                   , FAL_DOC_PROP POA
               where FGT.FAL_GAN_SESSION_ID = iSessionId
                 and FGT.GAL_TASK_ID is not null
                 and FGT.FAL_DOC_PROP_ID = POA.FAL_DOC_PROP_ID
                 and POA.DOC_RECORD_ID = FGT.DOC_RECORD_ID
                 and PCS.PC_Config.GetConfig('FAL_ORT_SUPPLIER_DELAY') = 2
              union
              -- attribution de type lots affaire sur DOC
              select FGT.FAL_GAN_TASK_ID
                   , DOC.DMT_NUMBER FLR_REFERENCE
                   , null FLR_DESCRIPTION
                   , null FLR_BASIS_START_DATE
                   , PDE.PDE_FINAL_DELAY FLR_BASIS_END_DATE
                   , null FLR_START_DATE
                   , null FLR_END_DATE
                   , 0 FLR_PIVOT
                   , 0 FLR_REQUIRMENT
                   , PDE.DOC_POSITION_DETAIL_ID
                   , null FAL_DOC_PROP_ID
                   , FGT.GAL_TASK_ID
                   , FGT.DOC_RECORD_ID
                from FAL_GAN_TASK FGT
                   , DOC_DOCUMENT DOC
                   , DOC_POSITION DOP
                   , DOC_POSITION_DETAIL PDE
               where FGT.FAL_GAN_SESSION_ID = iSessionId
                 and FGT.GAL_TASK_ID is not null
                 and DOC.DOC_DOCUMENT_ID = PDE.DOC_DOCUMENT_ID
                 and PDE.DOC_POSITION_ID = DOP.DOC_POSITION_ID
                 and DOC.DOC_RECORD_ID = FGT.DOC_RECORD_ID);
  end InsertLinkedRequirements;

  function GetDurationInMinutes(iTAS_START_DATE in GAL_TASK.TAS_START_DATE%type, iTAS_END_DATE in GAL_TASK.TAS_END_DATE%type)
    return number
  is
  begin
    return PAC_I_LIB_SCHEDULE.GetOpenTimeBetween(iTAS_START_DATE, iTAS_END_DATE + 1) * 60;
  end GetDurationInMinutes;

  /**
  * procedure : InsertTask
  * Description : Insertion des données à traiter dans la table des tâches
  *               , contenant les tâches
  * @created AGA
  * @lastUpdate
  * @public
  *
  * @param   iSessionId      Session Oracle
  * @param   iPRPTask       Intégration des lots affaire
  * @param   iDFTask         Intégration des dossier de fabrication affaire
  * @param   iHorizonStart   Début de l'horizon
  * @param   iHorizonEnd     Fin de l'horizon
  * @param   iPlannedBatch   Lot plannifié
  * @param   iLaunchedBatch  Lot lancé
   */
  procedure InsertTask(
    iSessionId     in number
  , iPRPTask       in number
  , iDFTask        in number
  , iHorizonStart  in date
  , iHorizonEnd    in date
  , iPlannedBatch  in integer
  , iLaunchedBatch in integer
  )
  is
  begin
    if iPRPTask = 1 then
      -- Insertion des tâches relatives à la gestion à l'affaire (GAL_TASK.GAL_FATHER_TASK_ID IS NULL)
      insert into FAL_GAN_TASK
                  (FAL_GAN_TASK_ID
                 , DOC_POSITION_DETAIL_ID
                 , FAL_LOT_PROP_ID
                 , FAL_LOT_ID
                 , FAL_DOC_PROP_ID
                 , GAL_TASK_ID
                 , GAL_FATHER_TASK_ID
                 , DOC_RECORD_ID
                 , GCO_GOOD_ID
                 , C_SCHEDULE_PLANNING
                 , C_FAB_TYPE
                 , FGT_REFERENCE
                 , FGT_DESCRIPTION
                 , FGT_PRJ_CODE
                 , FGT_TAS_CODE
                 , FGT_TAS_DF_CODE
                 , FGT_MINIMAL_PLAN_START_DATE
                 , FGT_BASIS_PLAN_START_DATE
                 , FGT_PLAN_START_DATE
                 , FGT_REAL_START_DATE
                 , FGT_BASIS_PLAN_END_DATE
                 , FGT_PLAN_END_DATE
                 , FGT_RESULT_START_DATE
                 , FGT_RESULT_END_DATE
                 , FGT_DURATION
                 , FGT_RESULT_DURATION
                 , FGT_QUANTITY
                 , FGT_LOT_TOTAL_QTY
                 , FGT_PRIORITY
                 , FGT_PROCESS_SEQ
                 , C_SCHEDULE_STRATEGY
                 , FAL_GAN_SESSION_ID
                 , FGT_RELEASE_DATE
                 , FGT_DUE_DATE
                 , FAL_GAN_RESOURCE_GROUP_ID
                 , FGT_FILTER
                  )
        select FAL_TMP_RECORD_SEQ.nextval
             , null
             , null
             , null
             , null
             , TAS.GAL_TASK_ID
             , null
             , TAS.DOC_RECORD_ID
             , TAS.GCO_GOOD_ID
             , '2'   -- C_SCHEDULE_PLANNING : Selon opérations
             , '0'   -- C_FAB_TYPE : Fabrication
             , GPR.PRJ_CODE || ' - ' || TAS.TAS_CODE
             , TAS.TAS_WORDING
             , GPR.PRJ_CODE
             , TAS.TAS_CODE
             , TAS.TAS_CODE
             , decode(FAL_ORTEMS_EXPORT.CheckDelay(TAS.GCO_GOOD_ID)
                    , 0, sysdate
                    , 1, greatest(nvl(TAS.TAS_START_DATE, nvl(GPR.PRJ_LAUNCHING_DATE, nvl(GPR.PRJ_CUSTOMER_ORDER_DATE, sysdate) ) ) -
                                  FAL_ORTEMS_EXPORT.GetDelay(TAS.GCO_GOOD_ID)
                                , sysdate
                                 )
                     )
             , nvl(TAS.TAS_START_DATE, nvl(GPR.PRJ_LAUNCHING_DATE, nvl(GPR.PRJ_CUSTOMER_ORDER_DATE, sysdate) ) )
             , nvl(TAS.TAS_START_DATE, nvl(GPR.PRJ_LAUNCHING_DATE, nvl(GPR.PRJ_CUSTOMER_ORDER_DATE, sysdate) ) )
             , nvl(TAS.TAS_LAUNCHING_DATE, nvl(GPR.PRJ_LAUNCHING_DATE, nvl(GPR.PRJ_CUSTOMER_ORDER_DATE, sysdate) ) )
             , nvl(TAS.TAS_END_DATE, nvl(GPR.PRJ_DELIVERY_DATE, nvl(GPR.PRJ_CUSTOMER_DELIVERY_DATE, sysdate) ) )
             , nvl(TAS.TAS_END_DATE, nvl(GPR.PRJ_DELIVERY_DATE, nvl(GPR.PRJ_CUSTOMER_DELIVERY_DATE, sysdate) ) )
             , nvl(TAS.TAS_ACTUAL_START_DATE, nvl(TAS.TAS_START_DATE, nvl(GPR.PRJ_LAUNCHING_DATE, nvl(GPR.PRJ_CUSTOMER_ORDER_DATE, sysdate) ) ) )
             , nvl(TAS.TAS_END_DATE, nvl(GPR.PRJ_DELIVERY_DATE, nvl(GPR.PRJ_CUSTOMER_DELIVERY_DATE, sysdate) ) )
             , GetDurationInMinutes(nvl(TAS.TAS_START_DATE, nvl(GPR.PRJ_LAUNCHING_DATE, nvl(GPR.PRJ_CUSTOMER_ORDER_DATE, sysdate) ) )
                                  , nvl(TAS.TAS_END_DATE, nvl(GPR.PRJ_DELIVERY_DATE, nvl(GPR.PRJ_CUSTOMER_DELIVERY_DATE, sysdate) ) )
                                   )   -- durée en minutes
             , 0
             , 100
             , nvl(TAS.TAS_QUANTITY, 0)
             , -1
             , 0
             , null
             , iSessionId
             , nvl(TAS.TAS_START_DATE, nvl(GPR.PRJ_LAUNCHING_DATE, nvl(GPR.PRJ_CUSTOMER_ORDER_DATE, sysdate) ) )
             , nvl(TAS.TAS_END_DATE, nvl(GPR.PRJ_DELIVERY_DATE, nvl(GPR.PRJ_CUSTOMER_DELIVERY_DATE, sysdate) ) )
             , (select FGG.FAL_GAN_RESOURCE_GROUP_ID
                  from FAL_GAN_RESOURCE_GROUP FGG
                 where FGG.FAL_FACTORY_FLOOR_ID = TAS.GAL_TASK_FACTORY_FLOOR_ID
                   and FGG.FAL_GAN_SESSION_ID = iSessionId)
             , 0
          from GAL_TASK TAS
             , GAL_PROJECT GPR
         where TAS.GAL_FATHER_TASK_ID is null
           and TAS.GAL_PROJECT_ID = GPR.GAL_PROJECT_ID
           and (   iPlannedBatch = 1
                or iLaunchedBatch = 1)
           and (    (    iPlannedBatch = 1
                     and iLaunchedBatch = 0
                     and TAS.C_TAS_STATE in('10') )   -- '10' = Nouvelle
                or (    iPlannedBatch = 0
                    and iLaunchedBatch = 1
                    and TAS.C_TAS_STATE in('20', '30') )   -- ' '20' = lancée, '30' = commencée
                or (    iPlannedBatch = 1
                    and iLaunchedBatch = 1
                    and TAS.C_TAS_STATE in('10', '20', '30') )   -- '10' = Nouvelle, '20' = lancée, '30' = commencée
               )
           and (   iHorizonStart is null
                or (TAS.TAS_START_DATE between iHorizonStart and iHorizonEnd) );
    end if;

    if iDFTask = 1 then
      -- Insertion des tâches relatives à la gestion à l'affaire (GAL_TASK.GAL_FATHER_TASK_ID IS NOT NULL)  -> DF
      insert into FAL_GAN_TASK
                  (FAL_GAN_TASK_ID
                 , DOC_POSITION_DETAIL_ID
                 , FAL_LOT_PROP_ID
                 , FAL_LOT_ID
                 , FAL_DOC_PROP_ID
                 , GAL_TASK_ID
                 , GAL_FATHER_TASK_ID
                 , DOC_RECORD_ID
                 , GCO_GOOD_ID
                 , C_SCHEDULE_PLANNING
                 , C_FAB_TYPE
                 , FGT_REFERENCE
                 , FGT_DESCRIPTION
                 , FGT_PRJ_CODE
                 , FGT_TAS_CODE
                 , FGT_TAS_DF_CODE
                 , FGT_MINIMAL_PLAN_START_DATE
                 , FGT_BASIS_PLAN_START_DATE
                 , FGT_PLAN_START_DATE
                 , FGT_REAL_START_DATE
                 , FGT_BASIS_PLAN_END_DATE
                 , FGT_PLAN_END_DATE
                 , FGT_RESULT_START_DATE
                 , FGT_RESULT_END_DATE
                 , FGT_DURATION
                 , FGT_RESULT_DURATION
                 , FGT_QUANTITY
                 , FGT_LOT_TOTAL_QTY
                 , FGT_PRIORITY
                 , FGT_PROCESS_SEQ
                 , C_SCHEDULE_STRATEGY
                 , FAL_GAN_SESSION_ID
                 , FGT_RELEASE_DATE
                 , FGT_DUE_DATE
                 , FAL_GAN_RESOURCE_GROUP_ID
                 , FGT_FILTER
                  )
        select FAL_TMP_RECORD_SEQ.nextval
             , null
             , null
             , null
             , null
             , TAS.GAL_TASK_ID
             , TAS.GAL_FATHER_TASK_ID
             , TAS.DOC_RECORD_ID
             , TAS.GCO_GOOD_ID
             , '2'   -- C_SCHEDULE_PLANNING : Selon opérations
             , '0'   -- C_FAB_TYPE : Fabrication
             , GPR.PRJ_CODE || ' - ' || TAS_FATHER.TAS_CODE || ' - ' || TAS.TAS_CODE
             , TAS.TAS_WORDING
             , GPR.PRJ_CODE
             , TAS_FATHER.TAS_CODE
             , TAS.TAS_CODE
             , decode(FAL_ORTEMS_EXPORT.CheckDelay(TAS.GCO_GOOD_ID)
                    , 0, sysdate
                    , 1, greatest(nvl(TAS.TAS_START_DATE, nvl(GPR.PRJ_LAUNCHING_DATE, nvl(GPR.PRJ_CUSTOMER_ORDER_DATE, sysdate) ) ) -
                                  FAL_ORTEMS_EXPORT.GetDelay(TAS.GCO_GOOD_ID)
                                , sysdate
                                 )
                     )
             , nvl(TAS.TAS_START_DATE, nvl(GPR.PRJ_LAUNCHING_DATE, nvl(GPR.PRJ_CUSTOMER_ORDER_DATE, sysdate) ) )
             , nvl(TAS.TAS_START_DATE, nvl(GPR.PRJ_LAUNCHING_DATE, nvl(GPR.PRJ_CUSTOMER_ORDER_DATE, sysdate) ) )
             , nvl(TAS.TAS_LAUNCHING_DATE, nvl(GPR.PRJ_LAUNCHING_DATE, nvl(GPR.PRJ_CUSTOMER_ORDER_DATE, sysdate) ) )
             , nvl(TAS.TAS_END_DATE, nvl(GPR.PRJ_DELIVERY_DATE, nvl(GPR.PRJ_CUSTOMER_DELIVERY_DATE, sysdate) ) )
             , nvl(TAS.TAS_END_DATE, nvl(GPR.PRJ_DELIVERY_DATE, nvl(GPR.PRJ_CUSTOMER_DELIVERY_DATE, sysdate) ) )
             , nvl(TAS.TAS_ACTUAL_START_DATE, nvl(TAS.TAS_START_DATE, nvl(GPR.PRJ_LAUNCHING_DATE, nvl(GPR.PRJ_CUSTOMER_ORDER_DATE, sysdate) ) ) )
             , nvl(TAS.TAS_END_DATE, nvl(GPR.PRJ_DELIVERY_DATE, nvl(GPR.PRJ_CUSTOMER_DELIVERY_DATE, sysdate) ) )
             , GetDurationInMinutes(nvl(TAS.TAS_START_DATE, nvl(GPR.PRJ_LAUNCHING_DATE, nvl(GPR.PRJ_CUSTOMER_ORDER_DATE, sysdate) ) )
                                  , nvl(TAS.TAS_END_DATE, nvl(GPR.PRJ_DELIVERY_DATE, nvl(GPR.PRJ_CUSTOMER_DELIVERY_DATE, sysdate) ) )
                                   )   -- durée en minutes
             , 0
             , 100
             , nvl(TAS.TAS_QUANTITY, 0)
             , -1
             , 0
             , null
             , iSessionId
             , nvl(TAS.TAS_START_DATE, nvl(GPR.PRJ_LAUNCHING_DATE, nvl(GPR.PRJ_CUSTOMER_ORDER_DATE, sysdate) ) )
             , nvl(TAS.TAS_END_DATE, nvl(GPR.PRJ_DELIVERY_DATE, nvl(GPR.PRJ_CUSTOMER_DELIVERY_DATE, sysdate) ) )
             , (select FGG.FAL_GAN_RESOURCE_GROUP_ID
                  from FAL_GAN_RESOURCE_GROUP FGG
                 where FGG.FAL_FACTORY_FLOOR_ID = TAS.GAL_TASK_FACTORY_FLOOR_ID
                   and FGG.FAL_GAN_SESSION_ID = iSessionId)
             , 0
          from GAL_TASK TAS
             , GAL_PROJECT GPR
             , GAL_TASK TAS_FATHER
         where TAS.GAL_FATHER_TASK_ID is not null   -- tâches dossier de fabrication DF
           and TAS_FATHER.GAL_TASK_ID = TAS.GAL_FATHER_TASK_ID
           and TAS.GAL_PROJECT_ID = GPR.GAL_PROJECT_ID
           and (   iPlannedBatch = 1
                or iLaunchedBatch = 1)
           and (    (    iPlannedBatch = 1
                     and iLaunchedBatch = 0
                     and TAS.C_TAS_STATE in('10') )   -- '10' = Nouvelle
                or (    iPlannedBatch = 0
                    and iLaunchedBatch = 1
                    and TAS.C_TAS_STATE in('20', '30') )   -- ' '20' = lancée, '30' = commencée
                or (    iPlannedBatch = 1
                    and iLaunchedBatch = 1
                    and TAS.C_TAS_STATE in('10', '20', '30') )   -- '10' = Nouvelle, '20' = lancée, '30' = commencée
               )
           and (   iHorizonStart is null
                or (TAS.TAS_START_DATE between iHorizonStart and iHorizonEnd) );
    end if;

    if     iPRPTask = 1
       and iDFTask = 1 then
      -- Insertion des tâches père manquante relatives à des dossiers de fabrication
      insert into FAL_GAN_TASK
                  (FAL_GAN_TASK_ID
                 , DOC_POSITION_DETAIL_ID
                 , FAL_LOT_PROP_ID
                 , FAL_LOT_ID
                 , FAL_DOC_PROP_ID
                 , GAL_TASK_ID
                 , GAL_FATHER_TASK_ID
                 , DOC_RECORD_ID
                 , GCO_GOOD_ID
                 , C_SCHEDULE_PLANNING
                 , C_FAB_TYPE
                 , FGT_REFERENCE
                 , FGT_DESCRIPTION
                 , FGT_PRJ_CODE
                 , FGT_TAS_CODE
                 , FGT_TAS_DF_CODE
                 , FGT_BASIS_PLAN_START_DATE
                 , FGT_PLAN_START_DATE
                 , FGT_REAL_START_DATE
                 , FGT_BASIS_PLAN_END_DATE
                 , FGT_PLAN_END_DATE
                 , FGT_RESULT_START_DATE
                 , FGT_RESULT_END_DATE
                 , FGT_DURATION
                 , FGT_RESULT_DURATION
                 , FGT_QUANTITY
                 , FGT_LOT_TOTAL_QTY
                 , FGT_PRIORITY
                 , FGT_PROCESS_SEQ
                 , C_SCHEDULE_STRATEGY
                 , FAL_GAN_SESSION_ID
                 , FGT_RELEASE_DATE
                 , FGT_DUE_DATE
                 , FAL_GAN_RESOURCE_GROUP_ID
                 , FGT_FILTER
                  )
        select FAL_TMP_RECORD_SEQ.nextval
             , null
             , null
             , null
             , null
             , TAS.GAL_TASK_ID
             , null
             , TAS.DOC_RECORD_ID
             , TAS.GCO_GOOD_ID
             , '2'   -- C_SCHEDULE_PLANNING : Selon opérations
             , '0'   -- C_FAB_TYPE : Fabrication
             , GPR.PRJ_CODE || ' - ' || TAS.TAS_CODE
             , TAS.TAS_WORDING
             , GPR.PRJ_CODE
             , TAS.TAS_CODE
             , TAS.TAS_CODE
             , nvl(TAS.TAS_START_DATE, nvl(GPR.PRJ_LAUNCHING_DATE, nvl(GPR.PRJ_CUSTOMER_ORDER_DATE, sysdate) ) )
             , nvl(TAS.TAS_START_DATE, nvl(GPR.PRJ_LAUNCHING_DATE, nvl(GPR.PRJ_CUSTOMER_ORDER_DATE, sysdate) ) )
             , nvl(TAS.TAS_LAUNCHING_DATE, nvl(GPR.PRJ_LAUNCHING_DATE, nvl(GPR.PRJ_CUSTOMER_ORDER_DATE, sysdate) ) )
             , nvl(TAS.TAS_END_DATE, nvl(GPR.PRJ_DELIVERY_DATE, nvl(GPR.PRJ_CUSTOMER_DELIVERY_DATE, sysdate) ) )
             , nvl(TAS.TAS_END_DATE, nvl(GPR.PRJ_DELIVERY_DATE, nvl(GPR.PRJ_CUSTOMER_DELIVERY_DATE, sysdate) ) )
             , nvl(TAS.TAS_ACTUAL_START_DATE, nvl(TAS.TAS_START_DATE, nvl(GPR.PRJ_LAUNCHING_DATE, nvl(GPR.PRJ_CUSTOMER_ORDER_DATE, sysdate) ) ) )
             , nvl(TAS.TAS_END_DATE, nvl(GPR.PRJ_DELIVERY_DATE, nvl(GPR.PRJ_CUSTOMER_DELIVERY_DATE, sysdate) ) )
             , GetDurationInMinutes(nvl(TAS.TAS_START_DATE, nvl(GPR.PRJ_LAUNCHING_DATE, nvl(GPR.PRJ_CUSTOMER_ORDER_DATE, sysdate) ) )
                                  , nvl(TAS.TAS_END_DATE, nvl(GPR.PRJ_DELIVERY_DATE, nvl(GPR.PRJ_CUSTOMER_DELIVERY_DATE, sysdate) ) )
                                   )   -- durée en minutes
             , 0
             , 100
             , nvl(TAS.TAS_QUANTITY, 0)
             , -1
             , 0
             , null
             , iSessionId
             , nvl(TAS.TAS_START_DATE, nvl(GPR.PRJ_LAUNCHING_DATE, nvl(GPR.PRJ_CUSTOMER_ORDER_DATE, sysdate) ) )
             , nvl(TAS.TAS_END_DATE, nvl(GPR.PRJ_DELIVERY_DATE, nvl(GPR.PRJ_CUSTOMER_DELIVERY_DATE, sysdate) ) )
             , (select FGG.FAL_GAN_RESOURCE_GROUP_ID
                  from FAL_GAN_RESOURCE_GROUP FGG
                 where FGG.FAL_FACTORY_FLOOR_ID = TAS.GAL_TASK_FACTORY_FLOOR_ID
                   and FGG.FAL_GAN_SESSION_ID = iSessionId)
             , 0
          from GAL_TASK TAS
             , GAL_PROJECT GPR
         where TAS.GAL_TASK_ID in(select distinct GAT.GAL_FATHER_TASK_ID
                                             from FAL_GAN_TASK GAT
                                            where GAT.GAL_FATHER_TASK_ID is not null
                                              and not exists(select GAL_TASK_ID
                                                               from FAL_GAN_TASK GAT1
                                                              where GAT1.GAL_TASK_ID = GAT.GAL_FATHER_TASK_ID) )
           and TAS.GAL_PROJECT_ID = GPR.GAL_PROJECT_ID;
    end if;

    if iPRPTask = 1 then
      -- Traitement des tâche qui sont liées à un dossier dans DOC_RECORD relatif  à la gestion à l'affaire
      update FAL_GAN_TASK
         set (FGT_PRJ_CODE, FGT_TAS_CODE) = (select RCO_ALPHA_SHORT1
                                                  , RCO_ALPHA_SHORT2
                                               from DOC_RECORD
                                              where DOC_RECORD.DOC_RECORD_ID = FAL_GAN_TASK.DOC_RECORD_ID)
           , FGT_TAS_DF_CODE = FGT_REFERENCE
       where DOC_RECORD_ID is not null
         and FGT_PRJ_CODE is null
         and FAL_GAN_SESSION_ID = iSessionId;
    end if;
  end InsertTask;

   /**
  * procedure : InsertOperation
  * Description : Insertion des données à traiter dans la table FAL_GAN_OPERATION
  *               , contenant les opérations de tâche
  * @created AGA
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   Session Oracle
  * @param   iPRPOperation  Intégration des lots affaire
  * @param   iDFperation    Intégration des dossiers de fabrication DF
  * @param   iPlannedBatch   Lot plannifié
  * @param   iLaunchedBatch  Lot lancé
  */
  procedure InsertOperation(
    iSessionId     in number
  , iPRPOperation  in number
  , iDFOperation   in number
  , iPlannedBatch  in integer default 0
  , iLaunchedBatch in integer default 0
  )
  is
  begin
    -- Insertion des opérations dans la gestion à l'affaire
    -- avec planification selon opération / détaillées
    insert into FAL_GAN_OPERATION
                (FAL_GAN_OPERATION_ID
               , FGO_STEP_NUMBER
               , FGO_DESCRIPTION
               , FGO_PRJ_CODE
               , FGO_TAS_CODE
               , FGO_TAS_DF_CODE
               , FGO_BASIS_PLAN_START_DATE
               , FGO_PLAN_START_DATE
               , FGO_REAL_START_DATE
               , FGO_BASIS_PLAN_END_DATE
               , FGO_PLAN_END_DATE
               , FGO_LOCK_START_DATE
               , FGO_DURATION
               , FGO_PREPARATION_TIME
               , FGO_TRANSFERT_TIME
               , FGO_QUANTITY
               , FGO_PARALLEL
               , FGO_RESULT_STATUS
               , FGO_RESULT_DURATION
               , FGO_COMPLETION_DEGREE
               , FAL_GAN_TASK_ID
               , FAL_GAN_SESSION_ID
               , FAL_GAN_TIMING_RESOURCE_ID
               , FAL_GAN_RESULT_TIMING_RES_ID
               , FAL_GAN_RESOURCE_GROUP_ID
               , FGO_FILTER
               , C_TASK_TYPE
               , C_OPERATION_TYPE
               , GAL_TASK_LINK_ID
               , GAL_FATHER_TASK_ID
                )
      select FAL_TMP_RECORD_SEQ.nextval
           , TAL.SCS_STEP_NUMBER
           , TAL.SCS_STEP_NUMBER || ' - ' || TAL.SCS_SHORT_DESCR
           , FGT.FGT_PRJ_CODE
           , FGT.FGT_TAS_CODE
           , FGT.FGT_TAS_DF_CODE
           , nvl(nvl(TAL.TAL_BEGIN_PLAN_DATE, FGT.FGT_BASIS_PLAN_START_DATE), sysdate)
           , nvl(nvl(TAL.TAL_BEGIN_PLAN_DATE, FGT.FGT_PLAN_START_DATE), sysdate)
           , TAL.TAL_BEGIN_REAL_DATE
           , nvl(nvl(TAL.TAL_END_PLAN_DATE, FGT.FGT_BASIS_PLAN_END_DATE), sysdate)
           , nvl(nvl(TAL.TAL_END_PLAN_DATE, FGT.FGT_PLAN_END_DATE), sysdate)
           , null
           , FAL_GANTT_FCT.GetOperationDuration(iTAL_TSK_AD_BALANCE        => 0
                                              , iTAL_TSK_W_BALANCE         => nvl(TAL.TAL_TSK_BALANCE, TAL.TAL_DUE_TSK)
                                              , iTAL_NUM_UNITS_ALLOCATED   => TAL.TAL_NUM_UNITS_ALLOCATED
                                              , iSCS_TRANSFERT_TIME        => case cFAL_GANTT_TRANSFERT_TIME
                                                  when 'FALSE' then TAL.SCS_TRANSFERT_TIME
                                                  else 0
                                                end
                                              , iSCS_PLAN_PROP             => 0
                                              , iTAL_PLAN_RATE             => 0
                                              , iSCS_PLAN_RATE             => TAL.SCS_PLAN_RATE
                                              , iC_TASK_TYPE               => TAL.C_TASK_TYPE
                                              , iFAL_FACTORY_FLOOR_ID      => TAL.FAL_FACTORY_FLOOR_ID
                                              , iPAC_SUPPLIER_PARTNER_ID   => TAL.PAC_SUPPLIER_PARTNER_ID
                                              , iTAL_BEGIN_PLAN_DATE       => TAL.TAL_BEGIN_PLAN_DATE
                                              , iTAL_END_PLAN_DATE         => TAL.TAL_END_PLAN_DATE
                                              , iTAL_BEGIN_REAL_DATE       => TAL.TAL_BEGIN_REAL_DATE
                                              , iSCS_OPEN_TIME_MACHINE     => null
                                              , iFAC_DAY_CAPACITY          => null
                                              , iTAL_SUBCONTRACT_QTY       => null
                                              , iFAL_LOT_ID                => null
                                              , iFAL_SCHEDULE_STEP_ID      => null
                                               )
           , null
           , case cFAL_GANTT_TRANSFERT_TIME
               when 'TRUE' then(nvl(TAL.SCS_TRANSFERT_TIME, 0) * cWorkUnits)
               else 0
             end   -- transfert
           , 0
           , (case
                when C_RELATION_TYPE in('2', '4', '5') then decode(nvl(TAL.SCS_DELAY, 0), 0, cstParallelFlag, TAL.SCS_DELAY * cWorkUnits)
                else 0
              end)
           , 0
           , 0
           , null
           , FGT.FAL_GAN_TASK_ID
           , iSessionId
           , (select FGR.FAL_GAN_TIMING_RESOURCE_ID
                from FAL_GAN_TIMING_RESOURCE FGR
               where (   FGR.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID
                      or FGR.PAC_SUPPLIER_PARTNER_ID = TAL.PAC_SUPPLIER_PARTNER_ID)
                 and FGR.FAL_GAN_SESSION_ID = iSessionID)
           , (select FGR.FAL_GAN_TIMING_RESOURCE_ID
                from FAL_GAN_TIMING_RESOURCE FGR
               where (   FGR.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID
                      or FGR.PAC_SUPPLIER_PARTNER_ID = TAL.PAC_SUPPLIER_PARTNER_ID)
                 and FGR.FAL_GAN_SESSION_ID = iSessionID)
           , (select FGG.FAL_GAN_RESOURCE_GROUP_ID
                from FAL_GAN_RESOURCE_GROUP FGG
               where FGG.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID
                 and FGG.FAL_GAN_SESSION_ID = iSessionID)
           , 0
           , TAL.C_TASK_TYPE
           , '1'   --C_OPERATION_TYPE = '1' : opération principale
           , TAL.GAL_TASK_LINK_ID
           , TAS.GAL_FATHER_TASK_ID
        from FAL_GAN_TASK FGT
           , GAL_TASK_LINK TAL
           , GAL_TASK TAS
           , FAL_FACTORY_FLOOR FAC
           , GAL_PROJECT GPR
       where FGT.GAL_TASK_ID is not null
         and FGT.GAL_TASK_ID = TAL.GAL_TASK_ID
         and FGT.GAL_TASK_ID = TAS.GAL_TASK_ID
         and GPR.GAL_PROJECT_ID = TAS.GAL_PROJECT_ID
         and (    (    TAS.GAL_FATHER_TASK_ID is null
                   and iPRPOperation = 1)
              or   -- Lots affaire (Tâches)
                 (    TAS.GAL_FATHER_TASK_ID is not null
                  and iDFOperation = 1)
             )   -- Dossiers de fabrication DF affaire
         and FGT.C_SCHEDULE_PLANNING <> '1'
         and (    (    iPlannedBatch = 1
                   and iLaunchedBatch = 0
                   and TAL.C_TAL_STATE in('10') )   -- '10' = Nouvelle
              or (    iPlannedBatch = 0
                  and iLaunchedBatch = 1
                  and TAL.C_TAL_STATE in('20', '30') )   -- ' '20' = lancée, '30' = commencée
              or (    iPlannedBatch = 1
                  and iLaunchedBatch = 1
                  and TAL.C_TAL_STATE in('10', '20', '30') )   -- '10' = Nouvelle, '20' = lancée, '30' = commencée
             )
         and FGT.FAL_GAN_SESSION_ID = iSessionId
         and TAL.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID(+);

    if iPRPOperation = 1 then
      -- Insertion d'une opération virtuelle pour chaque tâche  -> FGO_STEP_NUMBER = 0 and GAL_FATHER_TASK_ID is not null
      insert into FAL_GAN_OPERATION
                  (FAL_GAN_OPERATION_ID
                 , FGO_STEP_NUMBER
                 , FGO_DESCRIPTION
                 , FGO_PRJ_CODE
                 , FGO_TAS_CODE
                 , FGO_TAS_DF_CODE
                 , FGO_BASIS_PLAN_START_DATE
                 , FGO_PLAN_START_DATE
                 , FGO_REAL_START_DATE
                 , FGO_BASIS_PLAN_END_DATE
                 , FGO_PLAN_END_DATE
                 , FGO_LOCK_START_DATE
                 , FGO_DURATION
                 , FGO_PREPARATION_TIME
                 , FGO_TRANSFERT_TIME
                 , FGO_QUANTITY
                 , FGO_PARALLEL
                 , FGO_RESULT_STATUS
                 , FGO_RESULT_DURATION
                 , FGO_COMPLETION_DEGREE
                 , FAL_GAN_TASK_ID
                 , FAL_GAN_SESSION_ID
                 , FAL_GAN_TIMING_RESOURCE_ID
                 , FAL_GAN_RESULT_TIMING_RES_ID
                 , FAL_GAN_RESOURCE_GROUP_ID
                 , FGO_FILTER
                 , C_TASK_TYPE
                 , C_OPERATION_TYPE
                  )
        select FAL_TMP_RECORD_SEQ.nextval
             , 0
             , '00' || ' - ' || FGT.FGT_TAS_DF_CODE
             , FGT.FGT_PRJ_CODE
             , FGT.FGT_TAS_CODE
             , FGT.FGT_TAS_DF_CODE
             , FGT.FGT_BASIS_PLAN_START_DATE
             , FGT.FGT_PLAN_START_DATE
             , FGT.FGT_RESULT_START_DATE
             , FGT.FGT_BASIS_PLAN_END_DATE
             , FGT.FGT_PLAN_END_DATE
             , null
             , decode(FGT.FGT_DURATION, 0, cWorkUnits, FGT.FGT_DURATION)
             , null
             , null
             , 0
             , 0
             , 0
             , 0
             , null
             , FGT.FAL_GAN_TASK_ID
             , iSessionId
             , null
             , null
             , FGT.FAL_GAN_RESOURCE_GROUP_ID
             , 0
             , '1'   --C_TASK_TYPE = '1' : Interne
             , '1'   --C_OPERATION_TYPE = '1' : Principale
          from FAL_GAN_TASK FGT
         where FGT.FAL_GAN_SESSION_ID = iSessionId
           and FGT.GAL_FATHER_TASK_ID is not null
           and FGT.FGT_PRJ_CODE is not null
           and not exists(select FAL_GAN_OPERATION_ID
                            from FAL_GAN_OPERATION FGO
                           where FGO.FGO_TAS_CODE = FGT.FGT_TAS_CODE
                             and FGO.FGO_PRJ_CODE = FGT.FGT_PRJ_CODE
                             and FAL_GAN_SESSION_ID = iSessionId);

      -- Insertion d'une opération virtuelle pour chaque tâche  -> FGO_STEP_NUMBER = 0 and GAL_FATHER_TASK_ID is null
      insert into FAL_GAN_OPERATION
                  (FAL_GAN_OPERATION_ID
                 , FGO_STEP_NUMBER
                 , FGO_DESCRIPTION
                 , FGO_PRJ_CODE
                 , FGO_TAS_CODE
                 , FGO_TAS_DF_CODE
                 , FGO_BASIS_PLAN_START_DATE
                 , FGO_PLAN_START_DATE
                 , FGO_REAL_START_DATE
                 , FGO_BASIS_PLAN_END_DATE
                 , FGO_PLAN_END_DATE
                 , FGO_LOCK_START_DATE
                 , FGO_DURATION
                 , FGO_PREPARATION_TIME
                 , FGO_TRANSFERT_TIME
                 , FGO_QUANTITY
                 , FGO_PARALLEL
                 , FGO_RESULT_STATUS
                 , FGO_RESULT_DURATION
                 , FGO_COMPLETION_DEGREE
                 , FAL_GAN_TASK_ID
                 , FAL_GAN_SESSION_ID
                 , FAL_GAN_TIMING_RESOURCE_ID
                 , FAL_GAN_RESULT_TIMING_RES_ID
                 , FAL_GAN_RESOURCE_GROUP_ID
                 , FGO_FILTER
                 , C_TASK_TYPE
                 , C_OPERATION_TYPE
                  )
        select FAL_TMP_RECORD_SEQ.nextval
             , 0
             , '00' || ' - ' || FGT.FGT_TAS_DF_CODE
             , FGT.FGT_PRJ_CODE
             , FGT.FGT_TAS_CODE
             , FGT.FGT_TAS_DF_CODE
             , FGT.FGT_BASIS_PLAN_START_DATE
             , FGT.FGT_PLAN_START_DATE
             , FGT.FGT_RESULT_START_DATE
             , FGT.FGT_BASIS_PLAN_END_DATE
             , FGT.FGT_PLAN_END_DATE
             , null
             , decode(FGT.FGT_DURATION, 0, cWorkUnits, FGT.FGT_DURATION)
             , null
             , null
             , 0
             , 0
             , 0
             , 0
             , null
             , FGT.FAL_GAN_TASK_ID
             , iSessionId
             , null
             , null
             , FGT.FAL_GAN_RESOURCE_GROUP_ID
             , 0
             , '1'   --C_TASK_TYPE = '1' : Interne
             , '1'   --C_OPERATION_TYPE = '1' : Principale
          from FAL_GAN_TASK FGT
         where FGT.FAL_GAN_SESSION_ID = iSessionId
           and FGT.GAL_FATHER_TASK_ID is null
           and FGT.FGT_PRJ_CODE is not null
           and not exists(select FAL_GAN_OPERATION_ID
                            from FAL_GAN_OPERATION FGO
                           where FGO.FGO_TAS_CODE = FGT.FGT_TAS_CODE
                             and FGO.FGO_PRJ_CODE = FGT.FGT_PRJ_CODE
                             and FAL_GAN_SESSION_ID = iSessionId);
    end if;
  end InsertOperation;

  /**
  * procedure : SelectBatches
  * Description : Sélectionne les affaires pour affichage
  *
  * @created AGA
  * @lastUpdate
  * @public
  *
  * @param   iPRPBatch                                 Code d'inclusion des lots affaires
  * @param   iDFBatch                                  Code d'inclusion des dossiers de fabrications
  * @param   iCFD_GAL_PROJECT_FROM         Affaire de
  * @param   iCFD_GAL_PROJECT_TO           Affaire à
  * @param   iCFD_GAL_TASK_FROM            Tâche de
  * @param   iCFD_GAL_TASK_TO              Tâche à
  * @param   iCFD_RECORD_FROM              Dossier de
  * @param   iCFD_RECORD_TO                Dossier à
  * @param   iDIC_GAL_PRJ_CATEGORY_FROM    Catégorie de
  * @param   iDIC_GAL_PRJ_CATEGORY_TO      Catégorie à
  * @param   iDIC_GAL_PRODUCT_LINE_FROM    Produit de
  * @param   iDIC_GAL_PRODUCT_LINE_TO      Produit à
  * @param   iDIC_GAL_DIVISION_FROM        Division de
  * @param   iDIC_GAL_DIVISION_TO          Division à
  * @param   iDIC_GAL_LOCATION_FROM        Site de
  * @param   iDIC_GAL_LOCATION_TO          Site à
  * @param   iCFD_PER_LAST_NAME_RESP_FROM  Responsable de
  * @param   iCFD_PER_LAST_NAME_RESP_TO    Responsable à
  * @param   iCFD_PER_LAST_NAME_TECH_FROM  Responsable technique de
  * @param   iCFD_PER_LAST_NAME_TECH_TO    Responsable technique à
  * @param   iCFD_CUSTOMER_FROM            Client de
  * @param   iCFD_CUSTOMER_TO              Client à
  * @param   iCFD_CUSTOMER_ORDER_REF_FROM  Référence client de
  * @param   iCFD_CUSTOMER_ORDER_REF_TO    Référence client à
  */
  procedure SelectBatches(
    iPRPBatch                    in number
  , iDFBatch                     in number
  , iPlannedBatch                in integer
  , iLaunchedBatch               in integer
  , iCFD_GAL_PROJECT_FROM        in GAL_PROJECT.PRJ_CODE%type
  , iCFD_GAL_PROJECT_TO          in GAL_PROJECT.PRJ_CODE%type
  , iCFD_GAL_TASK_FROM           in GAL_TASK.TAS_CODE%type
  , iCFD_GAL_TASK_TO             in GAL_TASK.TAS_CODE%type
  , iCFD_RECORD_FROM             in DOC_RECORD.RCO_TITLE%type
  , iCFD_RECORD_TO               in DOC_RECORD.RCO_TITLE%type
  , iDIC_GAL_PRJ_CATEGORY_FROM   in GAL_PROJECT.DIC_GAL_PRJ_CATEGORY_ID%type
  , iDIC_GAL_PRJ_CATEGORY_TO     in GAL_PROJECT.DIC_GAL_PRJ_CATEGORY_ID%type
  , iDIC_GAL_PRODUCT_LINE_FROM   in GAL_PROJECT.DIC_GAL_PRODUCT_LINE_ID%type
  , iDIC_GAL_PRODUCT_LINE_TO     in GAL_PROJECT.DIC_GAL_PRODUCT_LINE_ID%type
  , iDIC_GAL_DIVISION_FROM       in GAL_PROJECT.DIC_GAL_DIVISION_ID%type
  , iDIC_GAL_DIVISION_TO         in GAL_PROJECT.DIC_GAL_DIVISION_ID%type
  , iDIC_GAL_LOCATION_FROM       in GAL_PROJECT.DIC_GAL_LOCATION_ID%type
  , iDIC_GAL_LOCATION_TO         in GAL_PROJECT.DIC_GAL_LOCATION_ID%type
  , iCFD_PER_LAST_NAME_RESP_FROM in HRM_PERSON.PER_LAST_NAME%type
  , iCFD_PER_LAST_NAME_RESP_TO   in HRM_PERSON.PER_LAST_NAME%type
  , iCFD_PER_LAST_NAME_TECH_FROM in HRM_PERSON.PER_LAST_NAME%type
  , iCFD_PER_LAST_NAME_TECH_TO   in HRM_PERSON.PER_LAST_NAME%type
  , iCFD_CUSTOMER_FROM           in PAC_PERSON.PER_NAME%type
  , iCFD_CUSTOMER_TO             in PAC_PERSON.PER_NAME%type
  , iCFD_CUSTOMER_ORDER_REF_FROM in GAL_PROJECT.PRJ_CUSTOMER_ORDER_REF%type
  , iCFD_CUSTOMER_ORDER_REF_TO   in GAL_PROJECT.PRJ_CUSTOMER_ORDER_REF%type
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'GAL_TASK_ID';

    -- Sélection des ID des lots affaires ainsi que des dossiers de fabrication DF à afficher (GAL_TASK)
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct TAS.GAL_TASK_ID
                    , 'GAL_TASK_ID'
                 from GAL_TASK TAS
                    , GAL_PROJECT PRJ
                    , DOC_RECORD RCO
                    , PAC_PERSON PAR
                    , HRM_PERSON RESP
                    , HRM_PERSON TECH
                where TAS.GAL_PROJECT_ID = PRJ.GAL_PROJECT_ID
                  and (   iPlannedBatch = 1
                       or iLaunchedBatch = 1)
                  and (    (    iPlannedBatch = 1
                            and iLaunchedBatch = 0
                            and TAS.C_TAS_STATE in('10') )   -- '10' = Nouvelle
                       or (    iPlannedBatch = 0
                           and iLaunchedBatch = 1
                           and TAS.C_TAS_STATE in('20', '30') )   -- ' '20' = lancée, '30' = commencée
                       or (    iPlannedBatch = 1
                           and iLaunchedBatch = 1
                           and TAS.C_TAS_STATE in('10', '20', '30')
                          )   -- '10' = Nouvelle, '20' = lancée, '30' = commencée
                      )
                  and (    (    TAS.GAL_FATHER_TASK_ID is null
                            and iPRPBatch = 1)
                       or   -- Lots affaire (Tâches)
                          (    TAS.GAL_FATHER_TASK_ID is not null
                           and iDFBatch = 1)
                      )   -- Dossiers de fabrication DF affaire
                  and RCO.DOC_RECORD_ID(+) = PRJ.DOC_RECORD_ID
                  and RESP.HRM_PERSON_ID(+) = PRJ.HRM_PROJECT_PERSON_ID
                  and TECH.HRM_PERSON_ID(+) = PRJ.HRM_TECHNICAL_PERSON_ID
                  and PAR.PAC_PERSON_ID(+) = PRJ.PAC_CUSTOM_PARTNER_ID
                  and (    (    iCFD_GAL_PROJECT_FROM is null
                            and iCFD_GAL_PROJECT_TO is null)
                       or PRJ.PRJ_CODE between nvl(iCFD_GAL_PROJECT_FROM, PRJ.PRJ_CODE) and nvl(iCFD_GAL_PROJECT_TO, PRJ.PRJ_CODE)
                      )
                  and (    (    iCFD_CUSTOMER_ORDER_REF_FROM is null
                            and iCFD_CUSTOMER_ORDER_REF_TO is null)
                       or PRJ.PRJ_CUSTOMER_ORDER_REF between nvl(iCFD_CUSTOMER_ORDER_REF_FROM, PRJ.PRJ_CUSTOMER_ORDER_REF)
                                                         and nvl(iCFD_CUSTOMER_ORDER_REF_TO, PRJ.PRJ_CUSTOMER_ORDER_REF)
                      )
                  and (    (    iDIC_GAL_PRJ_CATEGORY_FROM is null
                            and iDIC_GAL_PRJ_CATEGORY_TO is null)
                       or PRJ.DIC_GAL_PRJ_CATEGORY_ID between nvl(iDIC_GAL_PRJ_CATEGORY_FROM, PRJ.DIC_GAL_PRJ_CATEGORY_ID)
                                                          and nvl(iDIC_GAL_PRJ_CATEGORY_TO, PRJ.DIC_GAL_PRJ_CATEGORY_ID)
                      )
                  and (    (    iDIC_GAL_PRODUCT_LINE_FROM is null
                            and iDIC_GAL_PRODUCT_LINE_TO is null)
                       or PRJ.DIC_GAL_PRODUCT_LINE_ID between nvl(iDIC_GAL_PRODUCT_LINE_FROM, PRJ.DIC_GAL_PRODUCT_LINE_ID)
                                                          and nvl(iDIC_GAL_PRODUCT_LINE_TO, PRJ.DIC_GAL_PRODUCT_LINE_ID)
                      )
                  and (    (    iDIC_GAL_DIVISION_FROM is null
                            and iDIC_GAL_DIVISION_TO is null)
                       or PRJ.DIC_GAL_DIVISION_ID between nvl(iDIC_GAL_DIVISION_FROM, PRJ.DIC_GAL_DIVISION_ID)
                                                      and nvl(iDIC_GAL_DIVISION_TO, PRJ.DIC_GAL_DIVISION_ID)
                      )
                  and (    (    iDIC_GAL_LOCATION_FROM is null
                            and iDIC_GAL_LOCATION_TO is null)
                       or PRJ.DIC_GAL_LOCATION_ID between nvl(iDIC_GAL_LOCATION_FROM, PRJ.DIC_GAL_LOCATION_ID)
                                                      and nvl(iDIC_GAL_LOCATION_TO, PRJ.DIC_GAL_LOCATION_ID)
                      )
                  and (    (    iCFD_GAL_TASK_FROM is null
                            and iCFD_GAL_TASK_TO is null)
                       or TAS.TAS_CODE between nvl(iCFD_GAL_TASK_FROM, TAS.TAS_CODE) and nvl(iCFD_GAL_TASK_TO, TAS.TAS_CODE)
                      )
                  and (    (    iCFD_RECORD_FROM is null
                            and iCFD_RECORD_TO is null)
                       or RCO.RCO_TITLE between nvl(iCFD_RECORD_FROM, RCO.RCO_TITLE) and nvl(iCFD_RECORD_TO, RCO.RCO_TITLE)
                      )
                  and (    (    iCFD_PER_LAST_NAME_RESP_FROM is null
                            and iCFD_PER_LAST_NAME_RESP_TO is null)
                       or RESP.PER_LAST_NAME between nvl(iCFD_PER_LAST_NAME_RESP_FROM, RESP.PER_LAST_NAME) and nvl(iCFD_PER_LAST_NAME_RESP_TO
                                                                                                                 , RESP.PER_LAST_NAME
                                                                                                                  )
                      )
                  and (    (    iCFD_PER_LAST_NAME_TECH_FROM is null
                            and iCFD_PER_LAST_NAME_TECH_TO is null)
                       or TECH.PER_LAST_NAME between nvl(iCFD_PER_LAST_NAME_TECH_FROM, TECH.PER_LAST_NAME) and nvl(iCFD_PER_LAST_NAME_TECH_TO
                                                                                                                 , TECH.PER_LAST_NAME
                                                                                                                  )
                      )
                  and (    (    iCFD_CUSTOMER_FROM is null
                            and iCFD_CUSTOMER_TO is null)
                       or PAR.PER_NAME between nvl(iCFD_CUSTOMER_FROM, PAR.PER_NAME) and nvl(iCFD_CUSTOMER_TO, PAR.PER_NAME)
                      );

    if     iDFBatch = 1
       and iPRPBatch = 1 then
      -- ajout des tâches parent si sélection de DF uniquement
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
        select distinct TDF.GAL_FATHER_TASK_ID
                      , 'GAL_TASK_ID'
                   from GAL_TASK TDF
                      , COM_LIST_ID_TEMP IDT
                  where TDF.GAL_TASK_ID = IDT.COM_LIST_ID_TEMP_ID
                    and IDT.LID_CODE = 'GAL_TASK_ID'
                    and TDF.GAL_FATHER_TASK_ID is not null
                    and not exists(select COM_LIST_ID_TEMP_ID
                                     from COM_LIST_ID_TEMP IDT2
                                    where IDT2.COM_LIST_ID_TEMP_ID = TDF.GAL_FATHER_TASK_ID
                                      and IDT2.LID_CODE = 'GAL_TASK_ID');

      -- Ajout des DF si sélection des tâches uniquement et qu'aucun DF n'a été sélectionnée pour une tâche
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_CODE
                  )
        select distinct TDF.GAL_TASK_ID
                      , 'GAL_TASK_ID'
                   from GAL_TASK TDF
                      , GAL_TASK TAS
                      , COM_LIST_ID_TEMP IDT
                  where TAS.GAL_TASK_ID = IDT.COM_LIST_ID_TEMP_ID
                    and IDT.LID_CODE = 'GAL_TASK_ID'
                    and TDF.GAL_FATHER_TASK_ID = TAS.GAL_TASK_ID
                    and not exists(select COM_LIST_ID_TEMP_ID
                                     from COM_LIST_ID_TEMP IDT2
                                    where IDT2.COM_LIST_ID_TEMP_ID in(select GAL_TASK_ID
                                                                        from GAL_TASK
                                                                       where GAL_FATHER_TASK_ID = TAS.GAL_TASK_ID
                                                                         and IDT2.LID_CODE = 'GAL_TASK_ID') );
    end if;
  end SelectBatches;

  /**
  * procedure : ApplyFilter
  * Description : Sélectionne les opérations à afficher parmis celles à planifier
  *
  * @created AGA
  * @lastUpdate
  * @public
  *
  * @param   iSessionID       Session
  * @param   iPRPTask       Intégration des lots affaire
  */
  procedure ApplyFilter(iSessionId in number, iPRPTask in number)
  is
    cursor crOperations
    is
      -- Recherche des lots et proposition de fabrication liés a une tâche affaires (lien par DOC_RECORD_ID : Dossier)
      --lien entre tâches  FAL_LOT_ID, FAL_LOT_PROP_ID -> GAL_TASK_ID
      select FGT.FAL_GAN_TASK_ID
           , FGO.FAL_GAN_OPERATION_ID
           , FGT1.FGT_REFERENCE
           , FGO1.FAL_GAN_OPERATION_ID FAL_NEXT_OPERATION_ID
        from FAL_GAN_OPERATION FGO
           ,   -- Lot fab, POF
             FAL_GAN_TASK FGT
           , FAL_GAN_OPERATION FGO1
           ,   -- Lot Affaire
             FAL_GAN_TASK FGT1
       where FGT.FAL_GAN_SESSION_ID = iSessionId
         -- Lot fab, POF
         and FGT.GAL_TASK_ID is null
         and (   FGT.FAL_LOT_PROP_ID is not null
              or FGT.FAL_LOT_ID is not null)
         and FGT.FAL_GAN_TASK_ID = FGO.FAL_GAN_TASK_ID
         and FGO.FGO_FILTER = 0
         -- Lot Affaire
         and FGT1.FAL_GAN_SESSION_ID = iSessionId
         and FGT1.GAL_TASK_ID is not null
         and FGT1.FAL_GAN_TASK_ID = FGO1.FAL_GAN_TASK_ID
         and FGO1.FGO_FILTER = 1
         and (FGT.DOC_RECORD_ID = FGT1.DOC_RECORD_ID)   -- lien par le dossier DOC_RECORD_ID
         and (   FGO.FAL_GAN_TIMING_RESOURCE_ID is null
              or (FGO.FAL_GAN_TIMING_RESOURCE_ID in(
                    select FAL_GAN_TIMING_RESOURCE_ID
                      from FAL_GAN_TIMING_RESOURCE FTR
                     where (   nvl(FTR.FAL_FACTORY_FLOOR_ID, PAC_SUPPLIER_PARTNER_ID) is null
                            or nvl(FTR.FAL_FACTORY_FLOOR_ID, PAC_SUPPLIER_PARTNER_ID) in(select COM_LIST_ID_TEMP_ID
                                                                                           from COM_LIST_ID_TEMP
                                                                                          where LID_CODE = 'FAL_GAN_TIMING_RESOURCE_ID')
                           ) )
                 )
              or (   FGO.FAL_GAN_RESOURCE_GROUP_ID is null
                  or (FGO.FAL_GAN_RESOURCE_GROUP_ID in(select FAL_GAN_RESOURCE_GROUP_ID
                                                         from FAL_GAN_RESOURCE_GROUP FGG
                                                        where FGG.FAL_FACTORY_FLOOR_ID in(select COM_LIST_ID_TEMP_ID
                                                                                            from COM_LIST_ID_TEMP
                                                                                           where LID_CODE = 'FAL_GAN_TIMING_RESOURCE_ID') ) )
                 )
             );
  begin
    -- mise à jour du code de filtrage en fonction de la table COM_LIST_ID_TEMP (initialisation par SelectBatches)
    update FAL_GAN_OPERATION FGO
       set FGO_FILTER = 1
     where FGO.FAL_GAN_SESSION_ID = iSessionId
       and FGO.FAL_GAN_OPERATION_ID in(
             select FGO.FAL_GAN_OPERATION_ID
               from FAL_GAN_OPERATION FGO
                  , FAL_GAN_TASK FGT
              where FGT.FAL_GAN_SESSION_ID = iSessionId
                and FGT.FAL_GAN_TASK_ID = FGO.FAL_GAN_TASK_ID
                and FGT.GAL_TASK_ID is not null
                and (FGT.GAL_TASK_ID in(select COM_LIST_ID_TEMP_ID
                                          from COM_LIST_ID_TEMP
                                         where LID_CODE = 'GAL_TASK_ID') ) )
       and (    (FGO.FAL_GAN_TIMING_RESOURCE_ID is null)
            or (FGO.FAL_GAN_TIMING_RESOURCE_ID in(
                  select FAL_GAN_TIMING_RESOURCE_ID
                    from FAL_GAN_TIMING_RESOURCE FTR
                   where (   nvl(FTR.FAL_FACTORY_FLOOR_ID, PAC_SUPPLIER_PARTNER_ID) is null
                          or nvl(FTR.FAL_FACTORY_FLOOR_ID, PAC_SUPPLIER_PARTNER_ID) in(select COM_LIST_ID_TEMP_ID
                                                                                         from COM_LIST_ID_TEMP
                                                                                        where LID_CODE = 'FAL_GAN_TIMING_RESOURCE_ID')
                         ) )
               )
            or (   FGO.FAL_GAN_RESOURCE_GROUP_ID is null
                or (FGO.FAL_GAN_RESOURCE_GROUP_ID in(select FAL_GAN_RESOURCE_GROUP_ID
                                                       from FAL_GAN_RESOURCE_GROUP FGG
                                                      where FGG.FAL_FACTORY_FLOOR_ID in(select COM_LIST_ID_TEMP_ID
                                                                                          from COM_LIST_ID_TEMP
                                                                                         where LID_CODE = 'FAL_GAN_TIMING_RESOURCE_ID') ) )
               )
           );

    if iPRPTask = 1 then
      for tplOperations in crOperations loop
        update FAL_GAN_OPERATION
           set FGO_FILTER = 1
         where FAL_GAN_OPERATION_ID = tplOperations.FAL_GAN_OPERATION_ID;

        update FAL_GAN_TASK
           set FGT_REFERENCE = tplOperations.FGT_REFERENCE || ' - ' || FGT_REFERENCE   -- ajout de la référence du lot Affaire
         where FAL_GAN_TASK_ID = tplOperations.FAL_GAN_TASK_ID;

        -- établissement du lien avec l'affaire
        insert into FAL_GAN_LINK
                    (FAL_GAN_LINK_ID
                   , FAL_NETWORK_LINK_ID
                   , C_LINK_TYPE
                   , FGL_DURATION
                   , FGL_BETWEEN_OP
                   , FAL_GAN_SESSION_ID
                   , FAL_GAN_PRED_TASK_ID
                   , FAL_GAN_SUCC_TASK_ID
                   , FAL_GAN_PRED_OPERATION_ID
                   , FAL_GAN_SUCC_OPERATION_ID
                    )
             values (FAL_TMP_RECORD_SEQ.nextval
                   , null
                   , 'FS'
                   , null
                   , 0
                   , iSessionId
                   , null
                   , null
                   , tplOperations.FAL_GAN_OPERATION_ID
                   , tplOperations.FAL_NEXT_OPERATION_ID
                    );
      end loop;
    end if;

    -- mise à jour du code de filtrage des tâches en fonction des opération qui leurs sont liées et dont le code de filtrage est activé
    update FAL_GAN_TASK FGT
       set FGT_FILTER = 1
     where FGT.FAL_GAN_SESSION_ID = iSessionId
       and exists(select FAL_GAN_OPERATION_ID
                    from FAL_GAN_OPERATION FGO
                   where FGO.FGO_TAS_CODE = FGT.FGT_TAS_CODE
                     and FGO.FGO_PRJ_CODE = FGT.FGT_PRJ_CODE
                     and FGO.FGO_FILTER = 1);
  end Applyfilter;

  /**
  * procedure : InsertAssignment
  * Description : Insertion des données à traiter dans la table des assignations
  *               , contenant les informations d'affectation des ressources aux
  *               opérations.
  * @created AGA
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   Session Oracle
  */
  procedure InsertAssignment(iSessionId number)
  is
  begin
    insert into FAL_GAN_ASSIGNMENT
                (FAL_GAN_ASSIGNMENT_ID
               , FGA_IS_RESULT
               , FAL_GAN_WORK_RESOURCE_ID
               , FAL_GAN_RESOURCE_GROUP_ID
               , FAL_GAN_TIMING_RESOURCE_ID
               , FAL_GAN_OPERATION_ID
               , FAL_GAN_SESSION_ID
                )
      select FAL_TMP_RECORD_SEQ.nextval
           , 0
           , null
           , FGO.FAL_GAN_RESOURCE_GROUP_ID
           , FGO.FAL_GAN_TIMING_RESOURCE_ID
           , FGO.FAL_GAN_OPERATION_ID
           , iSessionId
        from FAL_GAN_OPERATION FGO
           , FAL_GAN_TASK FGT
       where FGO.FAL_GAN_SESSION_ID = iSessionId
         and FGT.FAL_GAN_TASK_ID = FGO.FAL_GAN_TASK_ID
         and FGT.GAL_TASK_ID is not null;
  end InsertAssignment;

  /**
  * procedure : InsertOperationLinks
  * Description : Insertion des données à traiter dans la table GAN_OPERATIONS
  *               , Contenant les liens entre opérations
  *
  * @created AGA
  * @lastUpdate
  * @public
  *
  * @param   iSessionId   Session oracle
  */
  procedure InsertOperationLinks(iSessionId number)
  is
    cursor crOperations
    is
      select   FGO.FAL_GAN_TASK_ID
             , FGO.FAL_GAN_OPERATION_ID
             , FGO.FGO_PARALLEL
          from FAL_GAN_OPERATION FGO
             , FAL_GAN_TASK FGT
         where FGO.FAL_GAN_SESSION_ID = iSessionId
           and FGT.FAL_GAN_TASK_ID = FGO.FAL_GAN_TASK_ID
           and FGT.GAL_TASK_ID is not null
      order by FGO.FAL_GAN_TASK_ID
             , FGO.FGO_STEP_NUMBER;

    nLastTaskId      number(12);
    nLastOperationId number(12);
    vLin_Type        varchar2(10);
  begin
    nLastTaskId       := 0;
    nLastOperationId  := 0;

    for tplOperations in crOperations loop
      if     nLastTaskId <> 0
         and nLastOperationId <> 0
         and nLastTaskId = tplOperations.FAL_GAN_TASK_ID then
        if tplOperations.FGO_PARALLEL = cstParallelFlag then
          vLin_Type  := 'SS';   -- Opération parallèle
        else
          vLin_Type  := 'FS';   -- Opération Successeur
        end if;

        insert into FAL_GAN_LINK
                    (FAL_GAN_LINK_ID
                   , FAL_NETWORK_LINK_ID
                   , C_LINK_TYPE
                   , FGL_DURATION
                   , FGL_BETWEEN_OP
                   , FAL_GAN_SESSION_ID
                   , FAL_GAN_PRED_TASK_ID
                   , FAL_GAN_SUCC_TASK_ID
                   , FAL_GAN_PRED_OPERATION_ID
                   , FAL_GAN_SUCC_OPERATION_ID
                    )
             values (FAL_TMP_RECORD_SEQ.nextval
                   , null
                   , vLin_Type
                   , null
                   , 1
                   , iSessionId
                   , null
                   , null
                   , nLastOperationId
                   , tplOperations.FAL_GAN_OPERATION_ID
                    );
      end if;

      nLastTaskId       := tplOperations.FAL_GAN_TASK_ID;
      nLastOperationId  := tplOperations.FAL_GAN_OPERATION_ID;
    end loop;
  end InsertOperationLinks;

  /**
   * procedure    : InsertTasksLinks
   * Description  : Chargement de la table des liens entre tâches
   *
   * @created AGA
   * @lastUpdate
   * @public
   *
   * @param   iSessionId   Session oracle
   */
  procedure InsertTaskLinks(iSessionId number)
  is
    cursor crTasks
    is
      select   FGT.FAL_GAN_TASK_ID
             , FGT.GAL_TASK_ID
             , GTA.GAL_PROJECT_ID
          from FAL_GAN_TASK FGT
             , GAL_TASK GTA
         where FGT.FAL_GAN_SESSION_ID = iSessionId
           and FGT.GAL_TASK_ID = GTA.GAL_TASK_ID
           and FGT.GAL_TASK_ID is not null
           and FGT.GAL_FATHER_TASK_ID is null   -- ne pas intégrer les dossier de fabrication DF
      order by GTA.GAL_PROJECT_ID
             , GTA.TAS_CODE;

    nLastProjectId number(12);
    nLastTaskId    number(12);
    vLin_Type      varchar2(10);
  begin
    nLastProjectId  := 0;
    nLastTaskId     := 0;

    for tplTasks in crTasks loop
      if     nLastProjectId <> 0
         and nLastTaskId <> 0
         and nLastProjectId = tplTasks.GAL_PROJECT_ID then
        vLin_Type  := 'FS';   -- Opération Successeur

        insert into FAL_GAN_LINK
                    (FAL_GAN_LINK_ID
                   , FAL_NETWORK_LINK_ID
                   , C_LINK_TYPE
                   , FGL_DURATION
                   , FGL_BETWEEN_OP
                   , FAL_GAN_SESSION_ID
                   , FAL_GAN_PRED_TASK_ID
                   , FAL_GAN_SUCC_TASK_ID
                   , FAL_GAN_PRED_OPERATION_ID
                   , FAL_GAN_SUCC_OPERATION_ID
                    )
             values (FAL_TMP_RECORD_SEQ.nextval
                   , null
                   , vLin_Type
                   , null
                   , 0   -- lien entre tâches GAL_TASK_ID d'un même projet  GAL_TASK_ID-> GAL_TASK_ID
                   , iSessionId
                   , nLastTaskId
                   , tplTasks.FAL_GAN_TASK_ID
                   , (select FAL_GAN_OPERATION_ID
                        from FAL_GAN_OPERATION FGO1
                       where FGO1.FAL_GAN_TASK_ID = nLastTaskId
                         and FGO1.FGO_STEP_NUMBER = (select max(FGO2.FGO_STEP_NUMBER)
                                                       from FAL_GAN_OPERATION FGO2
                                                      where FGO2.FAL_GAN_TASK_ID = nLastTaskId) )
                   , (select FAL_GAN_OPERATION_ID
                        from FAL_GAN_OPERATION FGO1
                       where FGO1.FAL_GAN_TASK_ID = tplTasks.FAL_GAN_TASK_ID
                         and FGO1.FGO_STEP_NUMBER = (select min(FGO2.FGO_STEP_NUMBER)
                                                       from FAL_GAN_OPERATION FGO2
                                                      where FGO2.FAL_GAN_TASK_ID = tplTasks.FAL_GAN_TASK_ID) )
                    );
      end if;

      nLastProjectId  := tplTasks.GAL_PROJECT_ID;
      nLastTaskId     := tplTasks.FAL_GAN_TASK_ID;
    end loop;
  end InsertTaskLinks;

   /**
  * procedure : InsertMultiLevelLinks
  * Description : Insertion des données à traiter dans la table GAN_OPERATIONS
  *               , Contenant les liens multiniveaux
  *
  * @created EGA
  * @lastUpdate
  * @public
  * @param
  */
  procedure InsertMultiLevelLinks(iSessionId in number, iPRPOperation in number, iDFOperation in number)
  is
  begin
    if     iPRPOperation = 1
       and iDFOperation = 1 then
      -- Liens entre tâches de l'affaire et tâches d'approvisionnement (GAL_FATHER_TASK_ID IS NOT NULL)
      insert into FAL_GAN_LINK
                  (FAL_GAN_LINK_ID
                 , FAL_NETWORK_LINK_ID
                 , GAL_TASK_ID
                 , C_LINK_TYPE
                 , FGL_DURATION
                 , FGL_BETWEEN_OP
                 , FAL_GAN_SESSION_ID
                 , FAL_GAN_PRED_TASK_ID
                 , FAL_GAN_SUCC_TASK_ID
                 , FAL_GAN_PRED_OPERATION_ID
                 , FAL_GAN_SUCC_OPERATION_ID
                  )
        select FAL_TMP_RECORD_SEQ.nextval
             , null
             , GTA.GAL_TASK_ID
             , 'SS'   -- opération parallèle
             , null
             , 0   -- lien entre tâches et Dossier de fabrication DF :  GAL_TASK_ID -> GAL_FATHER_TASK_ID
             , iSessionId
             , FGT_SUPPLY.FAL_GAN_TASK_ID
             , FGT_NEED.FAL_GAN_TASK_ID
             , FGT_SUPPLY.FAL_GAN_OPERATION_ID
             , FGT_NEED.FAL_GAN_OPERATION_ID
          from GAL_TASK GTA
             , (select FGT.FAL_GAN_TASK_ID
                     , FGO.FAL_GAN_OPERATION_ID
                     , FGT.GAL_TASK_ID
                  from FAL_GAN_TASK FGT
                     , FAL_GAN_OPERATION FGO
                 where FGT.FAL_GAN_SESSION_ID = iSessionId
                   and FGT.FAL_GAN_TASK_ID = FGO.FAL_GAN_TASK_ID
                   and FGT.GAL_TASK_ID is not null
                   and FGT.GAL_FATHER_TASK_ID is null
                   and exists(select FGO.FAL_GAN_OPERATION_ID
                                from FAL_GAN_OPERATION FGO
                                   , FAL_GAN_TASK FGT2
                               where FGT2.GAL_FATHER_TASK_ID = FGT.GAL_TASK_ID
                                 and FGT2.FAL_GAN_TASK_ID = FGO.FAL_GAN_TASK_ID) ) FGT_NEED
             , (select FGT.FAL_GAN_TASK_ID
                     , FGO.FAL_GAN_OPERATION_ID
                     , FGT.GAL_FATHER_TASK_ID
                  from FAL_GAN_TASK FGT
                     , FAL_GAN_OPERATION FGO
                 where FGT.FAL_GAN_TASK_ID = FGO.FAL_GAN_TASK_ID
                   and FGT.FAL_GAN_SESSION_ID = iSessionId
                   and FGT.GAL_TASK_ID is not null
                   and FGT.GAL_FATHER_TASK_ID is not null
                   and (FGO.FGO_STEP_NUMBER = (select min(FGO2.FGO_STEP_NUMBER)
                                                 from FAL_GAN_OPERATION FGO2
                                                where FGO2.FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID) ) ) FGT_SUPPLY
         where GTA.GAL_TASK_ID = FGT_NEED.GAL_TASK_ID
           and GTA.GAL_TASK_ID = FGT_SUPPLY.GAL_FATHER_TASK_ID;
    end if;

    if    iPRPOperation = 1
       or iDFOperation = 1 then
      -- Liens entre tâches affaire et OF/POF
      insert into FAL_GAN_LINK
                  (FAL_GAN_LINK_ID
                 , FAL_NETWORK_LINK_ID
                 , GAL_TASK_ID
                 , C_LINK_TYPE
                 , FGL_DURATION
                 , FGL_BETWEEN_OP
                 , FAL_GAN_SESSION_ID
                 , FAL_GAN_PRED_TASK_ID
                 , FAL_GAN_SUCC_TASK_ID
                 , FAL_GAN_PRED_OPERATION_ID
                 , FAL_GAN_SUCC_OPERATION_ID
                  )
        select FAL_TMP_RECORD_SEQ.nextval
             , null
             , GTA.GAL_TASK_ID
             , 'FS'   -- Opération Successeur
             , null
             , 0   -- lien entre tâches GAL_TASK_ID -> FAL_LOT_ID, FAL_LOT_PROP_ID
             , iSessionId
             , FGT_SUPPLY.FAL_GAN_TASK_ID
             , FGT_NEED.FAL_GAN_TASK_ID
             , FGT_SUPPLY.FAL_GAN_OPERATION_ID
             , FGT_NEED.FAL_GAN_OPERATION_ID
          from GAL_TASK GTA
             , (select FGT.FAL_GAN_TASK_ID
                     , FGT.GAL_TASK_ID
                     , FGO.FAL_GAN_OPERATION_ID
                  from FAL_GAN_TASK FGT
                     , FAL_GAN_OPERATION FGO
                 where FGT.FAL_GAN_SESSION_ID = iSessionId
                   and FGT.FAL_GAN_TASK_ID = FGO.FAL_GAN_TASK_ID
                   and FGT.GAL_TASK_ID is not null) FGT_NEED
             , (select FGT.FAL_GAN_TASK_ID
                     , FGT.DOC_RECORD_ID
                     , FGO.FAL_GAN_OPERATION_ID
                  from FAL_GAN_TASK FGT
                     , FAL_GAN_OPERATION FGO
                 where FGT.FAL_GAN_TASK_ID = FGO.FAL_GAN_TASK_ID
                   and FGT.FAL_GAN_SESSION_ID = iSessionId
                   and FGT.DOC_RECORD_ID is not null
                   and (   FGT.FAL_LOT_ID is not null
                        or FGT.FAL_LOT_PROP_ID is not null)
                   and FGO.FGO_STEP_NUMBER = (select max(FGO2.FGO_STEP_NUMBER)
                                                from FAL_GAN_OPERATION FGO2
                                               where FGO2.FAL_GAN_TASK_ID = FGT.FAL_GAN_TASK_ID) ) FGT_SUPPLY
         where (    (    GTA.GAL_FATHER_TASK_ID is null
                     and iPRPOperation = 1)
                or   -- Lots affaire (Tâches)
                   (    GTA.GAL_FATHER_TASK_ID is not null
                    and iDFOperation = 1)
               )   -- Dossiers de fabrication DF affaire
           and GTA.GAL_TASK_ID = FGT_NEED.GAL_TASK_ID
           and GTA.DOC_RECORD_ID = FGT_SUPPLY.DOC_RECORD_ID;   -- lien par le dossier DOC_RECORD_ID
    end if;
  end InsertMultiLevelLinks;

  /**
  * procedure : InsertDatas
  * Description : Insertion des charges et assignations pour le thème PRP
  *
  * @created AGA
  * @lastUpdate
  * @public
  *
  * @param   iSessionId      Session Oracle
  * @param   iHorizonStart   Début de l'horizon
  * @param   iHorizonEnd     Fin de l'horizon
  * @param   iPlannedBatch   Affaire plannifié
  * @param   iLaunchedBatch  Affaire lancé
  */
  procedure InsertDatas(
    iSessionId     in number
  , iHorizonStart  in date default null
  , iHorizonEnd    in date default null
  , iPlannedBatch  in integer default 0
  , iLaunchedBatch in integer default 0
  )
  is
  begin
    -- Chargement des tâches
    InsertTask(iSessionId, 1, 1, iHorizonStart, iHorizonEnd, iPlannedBatch, iLaunchedBatch);
    -- Chargement table des opérations
    InsertOperation(iSessionId, 1, 1, iPlannedBatch, iLaunchedBatch);
    FAL_GANTT_FCT.FinalizeOperation(iSessionId);
    -- Chargement de la table des assignations
    FAL_GANTT_FCT.InsertAssignment(iSessionId);
    -- Chargement de la table des liens multiniveaux
    InsertMultiLevelLinks(iSessionId, 1, 1);
    -- Chargement de la table des liens entre tâches
    InsertTaskLinks(iSessionId);
    -- Chargement de la table des liens entre opérations
    FAL_GANTT_FCT.InsertOperationLinks(iSessionId);
    -- Chargement de la table des dates d'achat et d'appro log
    InsertLinkedRequirements(iSessionId);
    FAL_GANTT_FCT.FinalizeLinkedRequirements(iSessionID);
    -- Application des filtres
    ApplyFilter(iSessionId, 1);
  end InsertDatas;
end GAL_GANTT_FCT;
