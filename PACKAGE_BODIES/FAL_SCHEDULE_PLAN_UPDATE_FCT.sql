--------------------------------------------------------
--  DDL for Package Body FAL_SCHEDULE_PLAN_UPDATE_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_SCHEDULE_PLAN_UPDATE_FCT" 
is
  -- Types d'opération (C_TASK_TYPE)
  ttInternal constant FAL_TASK.C_TASK_TYPE%type   := '1';   -- Interne
  ttExternal constant FAL_TASK.C_TASK_TYPE%type   := '2';   -- Externe

  /**
   * procedure CalcSchedPlanStats
   * Description
   *   Applique le profil passé en paramètre (le premier paramètre non nul) et
   *   calcule les données pour la mise à jour des gammes
   */
  procedure CalcSchedPlanStats(aProfileID in number default null, aClobProfile in clob default null)
  is
    vClobProfile clob;
    aXmlProfile  xmltype;
    vOptions     TSCUOptions;
  begin
    if aProfileID is not null then
      vOptions  := GetSCUProfileValues(PCS.COM_PROFILE_FUNCTIONS.GetXMLProfile(aProfileID) );
    elsif aClobProfile is not null then
      vOptions  := GetSCUProfileValues(xmltype.CreateXML(aClobProfile) );
    end if;

    ApplySCUOptions(vOptions);
    CalcSchedPlanValues;
  end CalcSchedPlanStats;

  /**
   * procedure ApplySCUOptions
   * Description
   *   Applique les options du profil (sélection des gammes, opérations et lots)
   */
  procedure ApplySCUOptions(aOptions in TSCUOptions)
  is
  begin
    SelectSchedPlans(aSCU_SCHEDULE_PLAN_FROM       => aOptions.SCU_SCHEDULE_PLAN_FROM
                   , aSCU_SCHEDULE_PLAN_TO         => aOptions.SCU_SCHEDULE_PLAN_TO
                   , aSCU_FAB_CONDITION            => aOptions.SCU_FAB_CONDITION
                   , aSCU_GOOD_FROM                => aOptions.SCU_GOOD_FROM
                   , aSCU_GOOD_TO                  => aOptions.SCU_GOOD_TO
                   , aSCU_GOOD_CATEGORY_FROM       => aOptions.SCU_GOOD_CATEGORY_FROM
                   , aSCU_GOOD_CATEGORY_TO         => aOptions.SCU_GOOD_CATEGORY_TO
                   , aSCU_GOOD_FAMILY_FROM         => aOptions.SCU_GOOD_FAMILY_FROM
                   , aSCU_GOOD_FAMILY_TO           => aOptions.SCU_GOOD_FAMILY_TO
                   , aSCU_ACCOUNTABLE_GROUP_FROM   => aOptions.SCU_ACCOUNTABLE_GROUP_FROM
                   , aSCU_ACCOUNTABLE_GROUP_TO     => aOptions.SCU_ACCOUNTABLE_GROUP_TO
                   , aSCU_GOOD_LINE_FROM           => aOptions.SCU_GOOD_LINE_FROM
                   , aSCU_GOOD_LINE_TO             => aOptions.SCU_GOOD_LINE_TO
                   , aSCU_GOOD_GROUP_FROM          => aOptions.SCU_GOOD_GROUP_FROM
                   , aSCU_GOOD_GROUP_TO            => aOptions.SCU_GOOD_GROUP_TO
                   , aSCU_GOOD_MODEL_FROM          => aOptions.SCU_GOOD_MODEL_FROM
                   , aSCU_GOOD_MODEL_TO            => aOptions.SCU_GOOD_MODEL_TO
                    );
    SelectTasks(aSCU_TASK_FROM               => aOptions.SCU_TASK_FROM
              , aSCU_TASK_TO                 => aOptions.SCU_TASK_TO
              , aSCU_FACTORY_FLOOR_FROM      => aOptions.SCU_FACTORY_FLOOR_FROM
              , aSCU_FACTORY_FLOOR_TO        => aOptions.SCU_FACTORY_FLOOR_TO
              , aSCU_OP_FACTORY_FLOOR_FROM   => aOptions.SCU_OP_FACTORY_FLOOR_FROM
              , aSCU_OP_FACTORY_FLOOR_TO     => aOptions.SCU_OP_FACTORY_FLOOR_TO
               );
    SelectLots(aSCU_FULL_REL_DTE_FROM   => aOptions.SCU_FULL_REL_DTE_FROM
             , aSCU_FULL_REL_DTE_TO     => aOptions.SCU_FULL_REL_DTE_TO
             , aSCU_JOB_PROGRAM_FROM    => aOptions.SCU_JOB_PROGRAM_FROM
             , aSCU_JOB_PROGRAM_TO      => aOptions.SCU_JOB_PROGRAM_TO
             , aSCU_ORDER_FROM          => aOptions.SCU_ORDER_FROM
             , aSCU_ORDER_TO            => aOptions.SCU_ORDER_TO
             , aSCU_C_PRIORITY_FROM     => aOptions.SCU_C_PRIORITY_FROM
             , aSCU_C_PRIORITY_TO       => aOptions.SCU_C_PRIORITY_TO
             , aSCU_FAMILY_FROM         => aOptions.SCU_FAMILY_FROM
             , aSCU_FAMILY_TO           => aOptions.SCU_FAMILY_TO
             , aSCU_RECORD_FROM         => aOptions.SCU_RECORD_FROM
             , aSCU_RECORD_TO           => aOptions.SCU_RECORD_TO
              );
  end;

  /**
   * procedure SelectSchedPlan
   * Description
   *   Sélectionne la gamme à mettre à jour
  *
  */
  procedure SelectSchedPlan(aFAL_SCHEDULE_PLAN_ID in FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type)
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_SCHEDULE_PLAN_ID';

    -- Sélection de l'ID de la gamme à traiter
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
         values (aFAL_SCHEDULE_PLAN_ID
               , 'FAL_SCHEDULE_PLAN_ID'
                );
  end SelectSchedPlan;

  /**
   * procedure SelectSchedPlans
   * Description
   *   Sélectionne les gammes à mettre à jour selon les filtres
   */
  procedure SelectSchedPlans(
    aSCU_SCHEDULE_PLAN_FROM     in FAL_SCHEDULE_PLAN.SCH_REF%type
  , aSCU_SCHEDULE_PLAN_TO       in FAL_SCHEDULE_PLAN.SCH_REF%type
  , aSCU_FAB_CONDITION          in DIC_FAB_CONDITION.DIC_FAB_CONDITION_ID%type
  , aSCU_GOOD_FROM              in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , aSCU_GOOD_TO                in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , aSCU_GOOD_CATEGORY_FROM     in GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type
  , aSCU_GOOD_CATEGORY_TO       in GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type
  , aSCU_GOOD_FAMILY_FROM       in DIC_GOOD_FAMILY.DIC_GOOD_FAMILY_ID%type
  , aSCU_GOOD_FAMILY_TO         in DIC_GOOD_FAMILY.DIC_GOOD_FAMILY_ID%type
  , aSCU_ACCOUNTABLE_GROUP_FROM in DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type
  , aSCU_ACCOUNTABLE_GROUP_TO   in DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type
  , aSCU_GOOD_LINE_FROM         in DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type
  , aSCU_GOOD_LINE_TO           in DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type
  , aSCU_GOOD_GROUP_FROM        in DIC_GOOD_GROUP.DIC_GOOD_GROUP_ID%type
  , aSCU_GOOD_GROUP_TO          in DIC_GOOD_GROUP.DIC_GOOD_GROUP_ID%type
  , aSCU_GOOD_MODEL_FROM        in DIC_GOOD_MODEL.DIC_GOOD_MODEL_ID%type
  , aSCU_GOOD_MODEL_TO          in DIC_GOOD_MODEL.DIC_GOOD_MODEL_ID%type
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_SCHEDULE_PLAN_ID';

    -- Sélection des ID de gammes à traiter
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct SCH.FAL_SCHEDULE_PLAN_ID
                    , 'FAL_SCHEDULE_PLAN_ID'
                 from FAL_SCHEDULE_PLAN SCH
                    , GCO_GOOD GOO
                    , GCO_GOOD_CATEGORY CAT
                    , GCO_COMPL_DATA_MANUFACTURE CMA
                where SCH.SCH_REF between nvl(aSCU_SCHEDULE_PLAN_FROM, SCH.SCH_REF) and nvl(aSCU_SCHEDULE_PLAN_TO, SCH.SCH_REF)
                  and SCH.FAL_SCHEDULE_PLAN_ID = CMA.FAL_SCHEDULE_PLAN_ID(+)
                  and SCH.SCH_GENERIC_SUBCONTRACT = 0
                  and (   aSCU_FAB_CONDITION is null
                       or CMA.DIC_FAB_CONDITION_ID = aSCU_FAB_CONDITION)
                  and CMA.GCO_GOOD_ID = GOO.GCO_GOOD_ID(+)
                  and (    (    GOO.GCO_GOOD_ID is null
                            and aSCU_GOOD_FROM is null
                            and aSCU_GOOD_TO is null
                            and aSCU_GOOD_CATEGORY_FROM is null
                            and aSCU_GOOD_CATEGORY_TO is null
                            and aSCU_GOOD_FAMILY_FROM is null
                            and aSCU_GOOD_FAMILY_TO is null
                            and aSCU_ACCOUNTABLE_GROUP_FROM is null
                            and aSCU_ACCOUNTABLE_GROUP_TO is null
                            and aSCU_GOOD_LINE_FROM is null
                            and aSCU_GOOD_LINE_TO is null
                            and aSCU_GOOD_GROUP_FROM is null
                            and aSCU_GOOD_GROUP_TO is null
                            and aSCU_GOOD_MODEL_FROM is null
                            and aSCU_GOOD_MODEL_TO is null
                           )
                       or GOO.GCO_GOOD_ID is not null
                      )
                  and (   GOO.GOO_MAJOR_REFERENCE is null
                       or GOO.GOO_MAJOR_REFERENCE between nvl(aSCU_GOOD_FROM, GOO.GOO_MAJOR_REFERENCE) and nvl(aSCU_GOOD_TO, GOO.GOO_MAJOR_REFERENCE)
                      )
                  and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID(+)
                  and (    (    aSCU_GOOD_CATEGORY_FROM is null
                            and aSCU_GOOD_CATEGORY_TO is null)
                       or CAT.GCO_GOOD_CATEGORY_WORDING between nvl(aSCU_GOOD_CATEGORY_FROM, CAT.GCO_GOOD_CATEGORY_WORDING)
                                                            and nvl(aSCU_GOOD_CATEGORY_TO, CAT.GCO_GOOD_CATEGORY_WORDING)
                      )
                  and (    (    aSCU_GOOD_FAMILY_FROM is null
                            and aSCU_GOOD_FAMILY_TO is null)
                       or GOO.DIC_GOOD_FAMILY_ID between nvl(aSCU_GOOD_FAMILY_FROM, GOO.DIC_GOOD_FAMILY_ID) and nvl(aSCU_GOOD_FAMILY_TO, GOO.DIC_GOOD_FAMILY_ID)
                      )
                  and (    (    aSCU_ACCOUNTABLE_GROUP_FROM is null
                            and aSCU_ACCOUNTABLE_GROUP_TO is null)
                       or GOO.DIC_ACCOUNTABLE_GROUP_ID between nvl(aSCU_ACCOUNTABLE_GROUP_FROM, GOO.DIC_ACCOUNTABLE_GROUP_ID)
                                                           and nvl(aSCU_ACCOUNTABLE_GROUP_TO, GOO.DIC_ACCOUNTABLE_GROUP_ID)
                      )
                  and (    (    aSCU_GOOD_LINE_FROM is null
                            and aSCU_GOOD_LINE_TO is null)
                       or GOO.DIC_GOOD_LINE_ID between nvl(aSCU_GOOD_LINE_FROM, GOO.DIC_GOOD_LINE_ID) and nvl(aSCU_GOOD_LINE_TO, GOO.DIC_GOOD_LINE_ID)
                      )
                  and (    (    aSCU_GOOD_GROUP_FROM is null
                            and aSCU_GOOD_GROUP_TO is null)
                       or GOO.DIC_GOOD_GROUP_ID between nvl(aSCU_GOOD_GROUP_FROM, GOO.DIC_GOOD_GROUP_ID) and nvl(aSCU_GOOD_GROUP_TO, GOO.DIC_GOOD_GROUP_ID)
                      )
                  and (    (    aSCU_GOOD_MODEL_FROM is null
                            and aSCU_GOOD_MODEL_TO is null)
                       or GOO.DIC_GOOD_MODEL_ID between nvl(aSCU_GOOD_MODEL_FROM, GOO.DIC_GOOD_MODEL_ID) and nvl(aSCU_GOOD_MODEL_TO, GOO.DIC_GOOD_MODEL_ID)
                      );
  end SelectSchedPlans;

  /**
   * procedure SelectTasks
   * Description
   *   Sélectionne les opérations à mettre à jour selon les filtres
   */
  procedure SelectTasks(
    aSCU_TASK_FROM             in FAL_TASK.TAS_REF%type
  , aSCU_TASK_TO               in FAL_TASK.TAS_REF%type
  , aSCU_FACTORY_FLOOR_FROM    in FAL_FACTORY_FLOOR.FAC_REFERENCE%type
  , aSCU_FACTORY_FLOOR_TO      in FAL_FACTORY_FLOOR.FAC_REFERENCE%type
  , aSCU_OP_FACTORY_FLOOR_FROM in FAL_FACTORY_FLOOR.FAC_REFERENCE%type
  , aSCU_OP_FACTORY_FLOOR_TO   in FAL_FACTORY_FLOOR.FAC_REFERENCE%type
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_TASK_ID';

    -- Sélection des ID d'opérations à traiter
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct TAS.FAL_TASK_ID
                    , 'FAL_TASK_ID'
                 from FAL_TASK TAS
                    , FAL_FACTORY_FLOOR FAC
                    , FAL_FACTORY_FLOOR FOP
                where TAS.TAS_REF between nvl(aSCU_TASK_FROM, TAS.TAS_REF) and nvl(aSCU_TASK_TO, TAS.TAS_REF)
                  and TAS.C_TASK_TYPE = ttInternal
                  and TAS.TAS_GENERIC_SUBCONTRACT = 0
                  and ( (    TAS.FAL_FACTORY_FLOOR_ID = FAC.FAL_FACTORY_FLOOR_ID(+)
                         and (    (    aSCU_FACTORY_FLOOR_FROM is null
                                   and aSCU_FACTORY_FLOOR_TO is null)
                              or FAC.FAC_REFERENCE between nvl(aSCU_FACTORY_FLOOR_FROM, FAC.FAC_REFERENCE) and nvl(aSCU_FACTORY_FLOOR_TO, FAC.FAC_REFERENCE)
                             )
                        )
                      )
                  and ( (    TAS.FAL_FAL_FACTORY_FLOOR_ID = FOP.FAL_FACTORY_FLOOR_ID(+)
                         and (    (    aSCU_OP_FACTORY_FLOOR_FROM is null
                                   and aSCU_OP_FACTORY_FLOOR_TO is null)
                              or FOP.FAC_REFERENCE between nvl(aSCU_OP_FACTORY_FLOOR_FROM, FOP.FAC_REFERENCE) and nvl(aSCU_OP_FACTORY_FLOOR_TO
                                                                                                                    , FOP.FAC_REFERENCE
                                                                                                                     )
                             )
                        )
                      );
  end SelectTasks;

  /**
   * procedure SelectLot
   * Description
   *   Sélectionne un lot à utiliser pour la mise à jour
   */
  procedure SelectLot(aFAL_LOT_ID in FAL_LOT.FAL_LOT_ID%type)
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_LOT_ID';

    -- Sélection de l'ID du lot à utiliser
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
         values (aFAL_LOT_ID
               , 'FAL_LOT_ID'
                );
  end SelectLot;

  /**
   * procedure SelectLots
   * Description
   *   Sélectionne les lots à utiliser pour la mise à jour
   */
  procedure SelectLots(
    aSCU_FULL_REL_DTE_FROM in FAL_LOT.LOT_FULL_REL_DTE%type
  , aSCU_FULL_REL_DTE_TO   in FAL_LOT.LOT_FULL_REL_DTE%type
  , aSCU_JOB_PROGRAM_FROM  in FAL_JOB_PROGRAM.JOP_REFERENCE%type
  , aSCU_JOB_PROGRAM_TO    in FAL_JOB_PROGRAM.JOP_REFERENCE%type
  , aSCU_ORDER_FROM        in FAL_ORDER.ORD_REF%type
  , aSCU_ORDER_TO          in FAL_ORDER.ORD_REF%type
  , aSCU_C_PRIORITY_FROM   in FAL_LOT.C_PRIORITY%type
  , aSCU_C_PRIORITY_TO     in FAL_LOT.C_PRIORITY%type
  , aSCU_FAMILY_FROM       in DIC_FAMILY.DIC_FAMILY_ID%type
  , aSCU_FAMILY_TO         in DIC_FAMILY.DIC_FAMILY_ID%type
  , aSCU_RECORD_FROM       in DOC_RECORD.RCO_TITLE%type
  , aSCU_RECORD_TO         in DOC_RECORD.RCO_TITLE%type
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_LOT_ID';

    -- Sélection des ID de lots à utiliser
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct LOT.FAL_LOT_ID
                    , 'FAL_LOT_ID'
                 from FAL_LOT LOT
                    , FAL_JOB_PROGRAM JOP
                    , FAL_ORDER ORD
                    , DOC_RECORD RCO
                where LOT.FAL_SCHEDULE_PLAN_ID in(select COM_LIST_ID_TEMP_ID
                                                    from COM_LIST_ID_TEMP
                                                   where LID_CODE = 'FAL_SCHEDULE_PLAN_ID')
                  and LOT.LOT_FULL_REL_DTE is not null
                  and LOT.C_LOT_STATUS = '5'
                  and (    (    aSCU_FULL_REL_DTE_FROM is null
                            and aSCU_FULL_REL_DTE_TO is null)
                       or LOT.LOT_FULL_REL_DTE between nvl(aSCU_FULL_REL_DTE_FROM, LOT.LOT_FULL_REL_DTE) and nvl(aSCU_FULL_REL_DTE_TO, LOT.LOT_FULL_REL_DTE)
                      )
                  and LOT.FAL_JOB_PROGRAM_ID = JOP.FAL_JOB_PROGRAM_ID
                  and (    (    aSCU_JOB_PROGRAM_FROM is null
                            and aSCU_JOB_PROGRAM_TO is null)
                       or JOP.JOP_REFERENCE between nvl(aSCU_JOB_PROGRAM_FROM, JOP.JOP_REFERENCE) and nvl(aSCU_JOB_PROGRAM_TO, JOP.JOP_REFERENCE)
                      )
                  and LOT.FAL_ORDER_ID = ORD.FAL_ORDER_ID
                  and (    (    aSCU_ORDER_FROM is null
                            and aSCU_ORDER_TO is null)
                       or ORD.ORD_REF between nvl(aSCU_ORDER_FROM, ORD.ORD_REF) and nvl(aSCU_ORDER_TO, ORD.ORD_REF)
                      )
                  and (    (    aSCU_C_PRIORITY_FROM is null
                            and aSCU_C_PRIORITY_TO is null)
                       or LOT.C_PRIORITY between nvl(aSCU_C_PRIORITY_FROM, LOT.C_PRIORITY) and nvl(aSCU_C_PRIORITY_TO, LOT.C_PRIORITY)
                      )
                  and (    (    aSCU_FAMILY_FROM is null
                            and aSCU_FAMILY_TO is null)
                       or LOT.DIC_FAMILY_ID between nvl(aSCU_FAMILY_FROM, LOT.DIC_FAMILY_ID) and nvl(aSCU_FAMILY_TO, LOT.DIC_FAMILY_ID)
                      )
                  and LOT.DOC_RECORD_ID = RCO.DOC_RECORD_ID(+)
                  and (    (    aSCU_RECORD_FROM is null
                            and aSCU_RECORD_TO is null)
                       or RCO.RCO_TITLE between nvl(aSCU_RECORD_FROM, RCO.RCO_TITLE) and nvl(aSCU_RECORD_TO, RCO.RCO_TITLE)
                      );
  end SelectLots;

  /**
   * procedure SelectToUpdateLots
   * Description
   *   Sélectionne les lots à mettre à jour selon les gammes mises à jour
   */
  procedure SelectToUpdateLots
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'FAL_LUP_LOT_ID';

    -- Sélection de l'ID du lot à re-planifier
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
               , LID_FREE_NUMBER_1
                )
      select distinct FAL_LOT_ID
                    , 'FAL_LUP_LOT_ID'
                    , 0
                 from FAL_LOT LOT
                where LOT.FAL_SCHEDULE_PLAN_ID in(select SCU.FAL_SCHEDULE_PLAN_ID
                                                    from FAL_SCHEDULE_PLAN_UPDATE SCU
                                                   where SCU.C_SCU_STATUS = '20')
                  and LOT.C_LOT_STATUS = '1';
  end SelectToUpdateLots;

  /**
   * procedure CalcSchedPlanValues
   * Description
   *   Crée les enregistrements temporaires et calcule les données à utiliser
   *   pour la mise à jour des gammes
   */
  procedure CalcSchedPlanValues
  is
    lvProcUpdProcessPlan varchar2(2000) := PCS.PC_CONFIG.GetConfig('FAL_PROC_UPDATE_PROCESS_PLAN');
  begin
    -- Suppression des enregistrements précédents non-traités
    delete from FAL_SCHEDULE_PLAN_UPDATE
          where C_SCU_STATUS = '10';

    if lvProcUpdProcessPlan is not null then
      -- Si une procédure indiv existe, c'est elle qui fait le calcul et création des enregistrements
      execute immediate 'begin ' || lvProcUpdProcessPlan || '; end;';
    else
      -- Insertion des enregistrements à traiter
      insert into FAL_SCHEDULE_PLAN_UPDATE
                  (FAL_SCHEDULE_PLAN_UPDATE_ID
                 , FAL_SCHEDULE_PLAN_ID
                 , FAL_LIST_STEP_LINK_ID
                 , FAL_TASK_ID
                 , C_SCU_STATUS
                 , SCS_ADJUSTING_TIME
                 , SCS_QTY_FIX_ADJUSTING
                 , SCU_ADJUSTING_TIME_AVG
                 , SCU_ADJUSTING_TIME_GAP
                 , SCU_ADJUSTING_TIME_MIN
                 , SCU_ADJUSTING_TIME_MAX
                 , SCS_WORK_TIME
                 , SCS_QTY_REF_WORK
                 , SCU_WORK_TIME_AVG
                 , SCU_WORK_TIME_GAP
                 , SCU_WORK_TIME_MIN
                 , SCU_WORK_TIME_MAX
                 , SCU_QUANTITY_AVG
                 , SCU_QUANTITY_MIN
                 , SCU_QUANTITY_MAX
                 , SCU_LOT_COUNT
                  )
        select PCS.INIT_TEMP_ID_SEQ.nextval   -- FAL_SCHEDULE_PLAN_UPDATE_ID
             , RES.FAL_SCHEDULE_PLAN_ID
             , RES.FAL_LIST_STEP_LINK_ID
             , RES.FAL_TASK_ID
             , /* C_SCU_STATUS */'10'
             , RES.SCS_ADJUSTING_TIME
             , RES.SCS_QTY_FIX_ADJUSTING
             , RES.SCU_ADJUSTING_TIME_AVG
             , case nvl(RES.SCS_ADJUSTING_TIME, 0)
                 when 0 then decode(RES.SCU_ADJUSTING_TIME_AVG, 0, 0, 1)
                 else (RES.SCU_ADJUSTING_TIME_AVG - RES.SCS_ADJUSTING_TIME) / RES.SCS_ADJUSTING_TIME
               end *
               100 SCU_ADJUSTING_TIME_GAP
             , RES.SCU_ADJUSTING_TIME_MIN
             , RES.SCU_ADJUSTING_TIME_MAX
             , RES.SCS_WORK_TIME
             , RES.SCS_QTY_REF_WORK
             , RES.SCU_WORK_TIME_AVG
             , case nvl(RES.SCS_WORK_TIME, 0)
                 when 0 then decode(RES.SCU_WORK_TIME_AVG, 0, 0, 1)
                 else (RES.SCU_WORK_TIME_AVG - RES.SCS_WORK_TIME) / RES.SCS_WORK_TIME
               end *
               100 SCU_WORK_TIME_GAP
             , RES.SCU_WORK_TIME_MIN
             , RES.SCU_WORK_TIME_MAX
             , RES.SCU_QUANTITY_AVG
             , RES.SCU_QUANTITY_MIN
             , RES.SCU_QUANTITY_MAX
             , RES.SCU_LOT_COUNT
          from (select   VAL.FAL_SCHEDULE_PLAN_ID
                       , VAL.FAL_LIST_STEP_LINK_ID
                       , VAL.FAL_TASK_ID
                       , VAL.SCS_ADJUSTING_TIME
                       , VAL.SCS_QTY_FIX_ADJUSTING
                       , round(avg(VAL.SCU_ADJUSTING_TIME), 4) SCU_ADJUSTING_TIME_AVG
                       , round(min(VAL.SCU_ADJUSTING_TIME), 4) SCU_ADJUSTING_TIME_MIN
                       , round(max(VAL.SCU_ADJUSTING_TIME), 4) SCU_ADJUSTING_TIME_MAX
                       , VAL.SCS_WORK_TIME
                       , VAL.SCS_QTY_REF_WORK
                       , round(avg(VAL.SCU_WORK_TIME), 4) SCU_WORK_TIME_AVG
                       , round(min(VAL.SCU_WORK_TIME), 4) SCU_WORK_TIME_MIN
                       , round(max(VAL.SCU_WORK_TIME), 4) SCU_WORK_TIME_MAX
                       , round(avg(VAL.SCU_QUANTITY), 4) SCU_QUANTITY_AVG
                       , round(min(VAL.SCU_QUANTITY), 4) SCU_QUANTITY_MIN
                       , round(max(VAL.SCU_QUANTITY), 4) SCU_QUANTITY_MAX
                       , count(VAL.FAL_LOT_ID) SCU_LOT_COUNT
                    from (select LSL.FAL_SCHEDULE_PLAN_ID
                               , LSL.FAL_LIST_STEP_LINK_ID
                               , TAL.FAL_TASK_ID
                               , LOT.FAL_LOT_ID
                               , LSL.SCS_ADJUSTING_TIME
                               , LSL.SCS_QTY_FIX_ADJUSTING
                               , LSL.SCS_WORK_TIME
                               , LSL.SCS_QTY_REF_WORK
                               , case nvl(LSL.SCS_QTY_FIX_ADJUSTING, 0)
                                   when 0 then nvl(TAL.TAL_ACHIEVED_AD_TSK, 0)
                                   else nvl(TAL.TAL_ACHIEVED_AD_TSK, 0) /
                                        ceil( (nvl(TAL.TAL_RELEASE_QTY, 0) + nvl(TAL.TAL_REJECTED_QTY, 0) ) / LSL.SCS_QTY_FIX_ADJUSTING)
                                 end SCU_ADJUSTING_TIME
                               , nvl(TAL.TAL_ACHIEVED_TSK, 0) /( (nvl(TAL.TAL_RELEASE_QTY, 0) + nvl(TAL.TAL_REJECTED_QTY, 0) ) / nvl(LSL.SCS_QTY_REF_WORK, 1) )
                                                                                                                                                  SCU_WORK_TIME
                               , nvl(TAL.TAL_RELEASE_QTY, 0) + nvl(TAL.TAL_REJECTED_QTY, 0) SCU_QUANTITY
                            from FAL_LIST_STEP_LINK LSL
                               , FAL_TASK_LINK TAL
                               , FAL_LOT LOT
                           where LOT.FAL_SCHEDULE_PLAN_ID = LSL.FAL_SCHEDULE_PLAN_ID
                             and LSL.FAL_SCHEDULE_PLAN_ID in(select COM_LIST_ID_TEMP_ID
                                                               from COM_LIST_ID_TEMP
                                                              where LID_CODE = 'FAL_SCHEDULE_PLAN_ID')
                             and TAL.FAL_TASK_ID = LSL.FAL_TASK_ID
                             and LSL.FAL_TASK_ID in(select COM_LIST_ID_TEMP_ID
                                                      from COM_LIST_ID_TEMP
                                                     where LID_CODE = 'FAL_TASK_ID')
                             and TAL.FAL_LOT_ID = LOT.FAL_LOT_ID
                             and LOT.FAL_LOT_ID in(select COM_LIST_ID_TEMP_ID
                                                     from COM_LIST_ID_TEMP
                                                    where LID_CODE = 'FAL_LOT_ID')
                             and TAL.TAL_SEQ_ORIGIN = LSL.SCS_STEP_NUMBER
                             and TAL.SCS_SHORT_DESCR = LSL.SCS_SHORT_DESCR
                             and TAL.TAL_END_REAL_DATE is not null
                             and (nvl(TAL.TAL_RELEASE_QTY, 0) + nvl(TAL.TAL_REJECTED_QTY, 0) <> 0) ) VAL
                group by VAL.FAL_SCHEDULE_PLAN_ID
                       , VAL.FAL_LIST_STEP_LINK_ID
                       , VAL.FAL_TASK_ID
                       , VAL.SCS_ADJUSTING_TIME
                       , VAL.SCS_QTY_FIX_ADJUSTING
                       , VAL.SCS_WORK_TIME
                       , VAL.SCS_QTY_REF_WORK) RES;
    end if;
  end CalcSchedPlanValues;

  /**
   * procedure InitNewValues
   * Description
   *   Initialise un champ de la table temporaire selon un autre champ ou une
   *   formule
   */
  procedure InitNewValues(aSrcFieldName in varchar2, aDestFieldName in varchar2)
  is
  begin
    -- Mise à jour du champ avec les valeurs positives (0 si négatives)
    execute immediate 'update FAL_SCHEDULE_PLAN_UPDATE set ' || aDestFieldName || ' = greatest(0, ' || aSrcFieldName || ')';
  end InitNewValues;

  /**
   * procedure UpdateSchedPlans
   * Description
   *   Met à jour les gammes (temps opératoires) à partir des données des
   *   enregistrements temporaires
   */
  procedure UpdateSchedPlans(aSCU_GLOBAL_BEFORE_PROC in varchar2, aSCU_DETAIL_BEFORE_PROC in varchar2, aSCU_DETAIL_AFTER_PROC in varchar2)
  is
    cursor crNewValues
    is
      select   FAL_SCHEDULE_PLAN_UPDATE_ID
             , FAL_SCHEDULE_PLAN_ID
             , FAL_LIST_STEP_LINK_ID
             , SCU_ADJUSTING_TIME_NEW
             , SCU_WORK_TIME_NEW
          from FAL_SCHEDULE_PLAN_UPDATE
         where SCU_SELECTION = 1
           and C_SCU_STATUS = '10'
      order by FAL_SCHEDULE_PLAN_ID;

    cursor crSchedPlanTask(aFAL_LIST_STEP_LINK_ID in FAL_LIST_STEP_LINK.FAL_LIST_STEP_LINK_ID%type)
    is
      select     SCH.FAL_SCHEDULE_PLAN_ID
               , LSL.FAL_LIST_STEP_LINK_ID
            from FAL_SCHEDULE_PLAN SCH
               , FAL_LIST_STEP_LINK LSL
           where SCH.FAL_SCHEDULE_PLAN_ID = LSL.FAL_SCHEDULE_PLAN_ID
             and LSL.FAL_LIST_STEP_LINK_ID = aFAL_LIST_STEP_LINK_ID
      for update nowait;

    vSCU_GLOBAL_BEFORE_PROC varchar2(255);
    vSCU_DETAIL_BEFORE_PROC varchar2(255);
    vSCU_DETAIL_AFTER_PROC  varchar2(255);
    vProcResult             integer        := 1;
    vSqlCode                varchar2(10);
    vSqlMsg                 varchar2(4000);
  begin
    -- Recherche des procédures stockées si elles n'ont pas été passées en pramètre
    vSCU_GLOBAL_BEFORE_PROC  := nvl(aSCU_GLOBAL_BEFORE_PROC, PCS.PC_CONFIG.GetConfig('FAL_SCU_GLOBAL_PROC') );
    vSCU_DETAIL_BEFORE_PROC  := nvl(aSCU_DETAIL_BEFORE_PROC, PCS.PC_CONFIG.GetConfig('FAL_SCU_DETAIL_BEFORE_PROC') );
    vSCU_DETAIL_AFTER_PROC   := nvl(aSCU_DETAIL_AFTER_PROC, PCS.PC_CONFIG.GetConfig('FAL_SCU_DETAIL_AFTER_PROC') );

    -- Execution de la procédure stockée globale
    if vSCU_GLOBAL_BEFORE_PROC is not null then
      begin
        execute immediate 'begin :Result :=  ' || vSCU_GLOBAL_BEFORE_PROC || '; end;'
                    using out vProcResult;

        if vProcResult < 1 then
          vSqlCode  := '225';
          vSqlMsg   :=
                    PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée globale a interrompu le traitement. Valeur retournée :') || ' '
                    || to_char(vProcResult);
        end if;
      exception
        when others then
          begin
            vSqlCode  := '220';
            vSqlMsg   :=
                     PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée globale a généré une erreur :') || chr(13) || chr(10)
                     || DBMS_UTILITY.FORMAT_ERROR_STACK;
          end;
      end;
    end if;

    if vSqlCode is not null then
      update FAL_SCHEDULE_PLAN_UPDATE
         set SCU_SELECTION = 0
           , C_SCU_STATUS = '30'
           , C_SCU_ERROR_CODE = vSqlCode
           , SCU_ERROR_MESSAGE = vSqlMsg
       where SCU_SELECTION = 1
         and C_SCU_STATUS = '10';
    else
      -- Pour chaque élément de la table temporaire sélectionné
      for tplNewValues in crNewValues loop
        -- Execution de la procédure stockée de pré-traitement
        if vSCU_DETAIL_BEFORE_PROC is not null then
          begin
            execute immediate 'begin :Result :=  ' || vSCU_DETAIL_BEFORE_PROC || '(:FAL_SCHEDULE_PLAN_UPDATE_ID); end;'
                        using out vProcResult, in tplNewValues.FAL_SCHEDULE_PLAN_UPDATE_ID;

            if vProcResult < 1 then
              vSqlCode  := '245';
              vSqlMsg   :=
                PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée de pré-traitement a interrompu le traitement. Valeur retournée :') ||
                ' ' ||
                to_char(vProcResult);
            end if;
          exception
            when others then
              begin
                vProcResult  := 0;
                vSqlCode     := '240';
                vSqlMsg      :=
                  PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée de pré-traitement a généré une erreur :') ||
                  chr(13) ||
                  chr(10) ||
                  DBMS_UTILITY.FORMAT_ERROR_STACK;
              end;
          end;
        end if;

        if vSqlCode is null then
          begin
            -- Vérification que l'opération n'est pas lockée
            open crSchedPlanTask(tplNewValues.FAL_LIST_STEP_LINK_ID);

            -- Mise à jour des opérations de gamme
            update FAL_LIST_STEP_LINK
               set SCS_ADJUSTING_TIME = nvl(tplNewValues.SCU_ADJUSTING_TIME_NEW, SCS_ADJUSTING_TIME)
                 , SCS_WORK_TIME = nvl(tplNewValues.SCU_WORK_TIME_NEW, SCS_WORK_TIME)
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.USERINI
                 , A_DATEMOD = sysdate
             where FAL_LIST_STEP_LINK_ID = tplNewValues.FAL_LIST_STEP_LINK_ID;

            -- Mise à jour de la gamme
            update FAL_SCHEDULE_PLAN
               set A_IDMOD = PCS.PC_I_LIB_SESSION.USERINI
                 , A_DATEMOD = sysdate
             where FAL_SCHEDULE_PLAN_ID = tplNewValues.FAL_SCHEDULE_PLAN_ID;

            close crSchedPlanTask;
          exception
            when others then
              begin
                case sqlcode
                  when -54 then
                    vSqlCode  := '405';
                    vSqlMsg   := PCS.PC_FUNCTIONS.TranslateWord('La gamme ou l''opération de gamme est cours de modification par un autre utilisateur.');
                  else
                    vSqlCode  := '400';
                    vSqlMsg   :=
                      PCS.PC_FUNCTIONS.TranslateWord('Une erreur s''est produite lors de la mise à jour de l''opération de gamme :') ||
                      chr(13) ||
                      chr(10) ||
                      DBMS_UTILITY.FORMAT_ERROR_STACK;
                end case;
              end;
          end;
        end if;

        if vSqlCode is null then
          begin
            -- Execution de la procédure stockée de post-traitement
            if vSCU_DETAIL_AFTER_PROC is not null then
              execute immediate 'begin :Result :=  ' || vSCU_DETAIL_AFTER_PROC || '(:FAL_SCHEDULE_PLAN_UPDATE_ID); end;'
                          using out vProcResult, in tplNewValues.FAL_SCHEDULE_PLAN_UPDATE_ID;

              if vProcResult < 1 then
                vSqlCode  := '265';
                vSqlMsg   :=
                  PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée de post-traitement a signalé un problème. Valeur retournée') ||
                  ' ' ||
                  to_char(vProcResult);
              end if;
            end if;
          exception
            when others then
              begin
                vProcResult  := 0;
                vSqlCode     := '260';
                vSqlMsg      :=
                  PCS.PC_FUNCTIONS.TranslateWord('La procédure stockée de post-traitement a généré une erreur :') ||
                  chr(13) ||
                  chr(10) ||
                  DBMS_UTILITY.FORMAT_ERROR_STACK;
              end;
          end;
        end if;

        if vSqlCode is null then
          -- Mise à jour du statut dans la table temporaire
          update FAL_SCHEDULE_PLAN_UPDATE
             set SCU_SELECTION = 0
               , C_SCU_STATUS = '20'
           where FAL_SCHEDULE_PLAN_UPDATE_ID = tplNewValues.FAL_SCHEDULE_PLAN_UPDATE_ID;
        else
          -- Mise à jour du statut et des détails de l'erreur dans la table temporaire
          update FAL_SCHEDULE_PLAN_UPDATE
             set SCU_SELECTION = 0
               , C_SCU_STATUS = '30'
               , C_SCU_ERROR_CODE = vSqlCode
               , SCU_ERROR_MESSAGE = vSqlMsg
           where FAL_SCHEDULE_PLAN_UPDATE_ID = tplNewValues.FAL_SCHEDULE_PLAN_UPDATE_ID;

          -- Remise à zero des erreurs pour l'enregistrement suivant
          vSqlCode  := null;
          vSqlMsg   := null;
        end if;
      end loop;
    end if;
  end UpdateSchedPlans;

  /**
   * procedure DeleteScuItems
   * Description
   *   Supprime les enregistrements temporaires déterminés par les paramètres
   */
  procedure DeleteScuItems(aC_SCU_STATUS in FAL_SCHEDULE_PLAN_UPDATE.C_SCU_STATUS%type, aOnlySelected in integer default 0)
  is
  begin
    -- Suppression des enregistrements séléctionnés du statut précisé
    delete from FAL_SCHEDULE_PLAN_UPDATE
          where C_SCU_STATUS = aC_SCU_STATUS
            and (   aOnlySelected = 0
                 or SCU_SELECTION = 1);
  end DeleteScuItems;

  /**
   * function GetSCUProfileValues
   * Description
   *   Extrait les valeurs des options d'un profil xml.
   */
  function GetSCUProfileValues(aXmlProfile xmltype)
    return TSCUOptions
  is
    vOptions TSCUOptions;
  begin
    begin
      -- Initialiser les valeurs du record sortant avec les valeurs stockées dans le xml du profil
      select extractvalue(aXmlProfile, '//SCU_MODE')
           , extractvalue(aXmlProfile, '//SCU_GLOBAL_BEFORE_PROC')
           , extractvalue(aXmlProfile, '//SCU_DETAIL_BEFORE_PROC')
           , extractvalue(aXmlProfile, '//SCU_DETAIL_AFTER_PROC')
           , extractvalue(aXmlProfile, '//SCU_SCHEDULE_PLAN_FROM')
           , extractvalue(aXmlProfile, '//SCU_SCHEDULE_PLAN_TO')
           , extractvalue(aXmlProfile, '//SCU_FAB_CONDITION')
           , extractvalue(aXmlProfile, '//SCU_GOOD_FROM')
           , extractvalue(aXmlProfile, '//SCU_GOOD_TO')
           , extractvalue(aXmlProfile, '//SCU_GOOD_CATEGORY_FROM')
           , extractvalue(aXmlProfile, '//SCU_GOOD_CATEGORY_TO')
           , extractvalue(aXmlProfile, '//SCU_GOOD_FAMILY_FROM')
           , extractvalue(aXmlProfile, '//SCU_GOOD_FAMILY_TO')
           , extractvalue(aXmlProfile, '//SCU_ACCOUNTABLE_GROUP_FROM')
           , extractvalue(aXmlProfile, '//SCU_ACCOUNTABLE_GROUP_TO')
           , extractvalue(aXmlProfile, '//SCU_GOOD_LINE_FROM')
           , extractvalue(aXmlProfile, '//SCU_GOOD_LINE_TO')
           , extractvalue(aXmlProfile, '//SCU_GOOD_GROUP_FROM')
           , extractvalue(aXmlProfile, '//SCU_GOOD_GROUP_TO')
           , extractvalue(aXmlProfile, '//SCU_GOOD_MODEL_FROM')
           , extractvalue(aXmlProfile, '//SCU_GOOD_MODEL_TO')
           , extractvalue(aXmlProfile, '//SCU_TASK_FROM')
           , extractvalue(aXmlProfile, '//SCU_TASK_TO')
           , extractvalue(aXmlProfile, '//SCU_FACTORY_FLOOR_FROM')
           , extractvalue(aXmlProfile, '//SCU_FACTORY_FLOOR_TO')
           , extractvalue(aXmlProfile, '//SCU_OP_FACTORY_FLOOR_FROM')
           , extractvalue(aXmlProfile, '//SCU_OP_FACTORY_FLOOR_TO')
           , PCS.COM_PROFILE_FUNCTIONS.GetDateValue(extractvalue(aXmlProfile, '//SCU_FULL_REL_DTE_FROM') )
           , PCS.COM_PROFILE_FUNCTIONS.GetDateValue(extractvalue(aXmlProfile, '//SCU_FULL_REL_DTE_TO') )
           , extractvalue(aXmlProfile, '//SCU_JOB_PROGRAM_FROM')
           , extractvalue(aXmlProfile, '//SCU_JOB_PROGRAM_TO')
           , extractvalue(aXmlProfile, '//SCU_ORDER_FROM')
           , extractvalue(aXmlProfile, '//SCU_ORDER_TO')
           , extractvalue(aXmlProfile, '//SCU_C_PRIORITY_FROM')
           , extractvalue(aXmlProfile, '//SCU_C_PRIORITY_TO')
           , extractvalue(aXmlProfile, '//SCU_FAMILY_FROM')
           , extractvalue(aXmlProfile, '//SCU_FAMILY_TO')
           , extractvalue(aXmlProfile, '//SCU_RECORD_FROM')
           , extractvalue(aXmlProfile, '//SCU_RECORD_TO')
        into vOptions
        from dual;
    exception
      when others then
        raise_application_error(-20601, PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur durant l''extraction des valeurs du profil!') );
    end;

    return vOptions;
  end GetSCUProfileValues;
end FAL_SCHEDULE_PLAN_UPDATE_FCT;
