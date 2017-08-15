--------------------------------------------------------
--  DDL for Package Body FAL_PRC_TASK_CHIP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_TASK_CHIP" 
is
  /**
  * Description
  *    Cette procédure contrôler que soit le "Mouvement de dérivé à l'opération", soit
  *    le "Pesée de copeaux à l'opération", soit aucun, mais pas les deux soient cochés.
  */
  procedure CheckActionsFromTask(iotTaskChipDetail in out nocopy fwk_i_typ_definition.t_crud_def)
  as
  begin
    if FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotTaskChipDetail, 'TCH_WEIGHING_BY_TASK') = 1 then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotTaskChipDetail, 'TCH_MVT_BY_TASK', 0);
    elsif FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotTaskChipDetail, 'TCH_MVT_BY_TASK') = 1 then
      FWK_I_MGT_ENTITY_DATA.setcolumn(iotTaskChipDetail, 'TCH_WEIGHING_BY_TASK', 0);
    end if;
  end CheckActionsFromTask;

  /**
  * Description
  *    Cette procédure permet de copier des définitions de déchet récupérables (copeaux) d'une tâche
  *    à une autre. Il faut impérativement définir le type de tâche source et cible. En fonction du
  *    paramètre boolean ibOnlyIfRefGoodContainsAlloy, on ne copiera ou non que les définitions de
  *    copeaux dont l'alliage est contenu dans le produit fini.
  */
  procedure copyTaskChipInfos(
    inSrcTaskID                  in FAL_TASK_CHIP_DETAIL.FAL_TASK_ID%type
  , inDestTaskID                 in FAL_TASK_CHIP_DETAIL.FAL_TASK_ID%type
  , ivCSrcTaskKind               in varchar2
  , ivCDestTaskKind              in varchar2
  , ibOnlyIfRefGoodContainsAlloy in boolean
  )
  as
    ltCRUD_FalTaskChipDetail FWK_I_TYP_DEFINITION.t_crud_def;

    type tChipInfos is record(
      GCO_ALLOY_ID         FAL_TASK_CHIP_DETAIL.GCO_ALLOY_ID%type
    , TCH_PERCENT          FAL_TASK_CHIP_DETAIL.TCH_PERCENT%type
    , C_WEIGHT_CALCUL_MODE FAL_TASK_CHIP_DETAIL.C_WEIGHT_CALCUL_MODE%type
    , TCH_MVT_BY_TASK      FAL_TASK_CHIP_DETAIL.TCH_MVT_BY_TASK%type
    , TCH_WEIGHING_BY_TASK FAL_TASK_CHIP_DETAIL.TCH_WEIGHING_BY_TASK%type
    );

    type ttChipInfos is table of tChipInfos;

    lttChipInfos             ttChipInfos;
    lvQuery                  varchar2(32767);
  begin
    lvQuery  :=
      'select GCO_ALLOY_ID
                     , TCH_PERCENT
                     , C_WEIGHT_CALCUL_MODE
                     , TCH_MVT_BY_TASK
                     , TCH_WEIGHING_BY_TASK
                  from FAL_TASK_CHIP_DETAIL ';

    case ivCSrcTaskKind
      when '1' then   /* Opération standard */
        lvQuery  := lvQuery || 'where FAL_TASK_ID = :FAL_TASK_ID';
      when '2' then   /* Opéraiton de gamme */
        lvQuery  := lvQuery || 'where FAL_LIST_STEP_LINK_ID = :FAL_LIST_STEP_LINK_ID';
      when '3' then   /* Opération de lot */
        lvQuery  := lvQuery || 'where FAL_TASK_LINK_ID = :FAL_TASK_LINK_ID';
    end case;

    execute immediate lvQuery
    bulk collect into lttChipInfos
                using inSrcTaskID;

    if lttChipInfos.count > 0 then
      for i in lttChipInfos.first .. lttChipInfos.last loop
        /* Si ibOnlyIfRefGoodContainsAlloy = false --> Copie de toutes les infos de récupération de copeaux
           Sinon si ibOnlyIfRefGoodContainsAlloy = true  et type op = 3 ou 4 --> Copie des infos de récupération de copeaux
           dont l'alliage figure dans le bien terminé. Récupération du bien en fonction de ces 2 types d'opérations
           Pour les opérations standards et les opérations de gamme, on copie de toute façon toute les définitions.
         */
        if    (not ibOnlyIfRefGoodContainsAlloy)
           or (     (ibOnlyIfRefGoodContainsAlloy)
               and (    (     (ivCDestTaskKind = '4')
                         and (GCO_I_LIB_PRECIOUS_MAT.goodContainsRealWeightAlloy
                                (inGcoGoodID    => FAL_LIB_LOT_PROP.getGcoGoodID
                                                                    (inFalLotPropID   => FAL_LIB_TASK_LINK_PROP.getLotPropID
                                                                                                                            (inFalTaskLinkPropID   => inDestTaskID) )
                               , inGcoAlloyID   => lttChipInfos(i).GCO_ALLOY_ID
                                ) = 1
                             )
                        )
                    or (     (ivCDestTaskKind = '3')
                        and (GCO_I_LIB_PRECIOUS_MAT.goodContainsRealWeightAlloy
                                        (inGcoGoodID    => FAL_LIB_BATCH.getGcoGoodID
                                                                                  (inFalLotID   => FAL_LIB_TASK_LINK.getFalLotID
                                                                                                                                (inFalTaskLinkID   => inDestTaskID) )
                                       , inGcoAlloyID   => lttChipInfos(i).GCO_ALLOY_ID
                                        ) = 1
                            )
                       )
                   )
              ) then
          FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalTaskChipDetail, ltCRUD_FalTaskChipDetail, false);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalTaskChipDetail, 'GCO_ALLOY_ID', lttChipInfos(i).GCO_ALLOY_ID);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalTaskChipDetail, 'TCH_PERCENT', lttChipInfos(i).TCH_PERCENT);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalTaskChipDetail, 'C_WEIGHT_CALCUL_MODE', lttChipInfos(i).C_WEIGHT_CALCUL_MODE);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalTaskChipDetail, 'TCH_MVT_BY_TASK', lttChipInfos(i).TCH_MVT_BY_TASK);
          FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalTaskChipDetail, 'TCH_WEIGHING_BY_TASK', lttChipInfos(i).TCH_WEIGHING_BY_TASK);

          case ivCDestTaskKind
            when '1' then   /* Opération standard */
              FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalTaskChipDetail, 'FAL_TASK_ID', inDestTaskID);
            when '2' then   /* Opération de gamme */
              FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalTaskChipDetail, 'FAL_LIST_STEP_LINK_ID', inDestTaskID);
            when '3' then   /* Opération de lot */
              FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalTaskChipDetail, 'FAL_TASK_LINK_ID', inDestTaskID);
            when '4' then   /* Opération de proposition de lot */
              FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalTaskChipDetail, 'FAL_TASK_LINK_PROP_ID', inDestTaskID);
          end case;

          FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_FalTaskChipDetail);
          FWK_I_MGT_ENTITY.Release(ltCRUD_FalTaskChipDetail);
        end if;
      end loop;
    end if;
  end copyTaskChipInfos;

  /**
  * Description
  *    Cette procédure va supprimer les informations de déchets récupérables de l'opération de
  *    la gamme opératoire dont la clef primaire est transmise en paramètre.
  */
  procedure deleteOldSchedStepChipDetail(inFalListStepLinkID in FAL_TASK_CHIP_DETAIL.FAL_LIST_STEP_LINK_ID%type)
  as
    ltCRUD_FalTaskChipDetail FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for tplOldChipInfos in (select FAL_TASK_CHIP_DETAIL_ID
                              from FAL_TASK_CHIP_DETAIL
                             where FAL_LIST_STEP_LINK_ID = inFalListStepLinkID) loop
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalTaskChipDetail, ltCRUD_FalTaskChipDetail, true, tplOldChipInfos.FAL_TASK_CHIP_DETAIL_ID);
      FWK_I_MGT_ENTITY.DeleteEntity(ltCRUD_FalTaskChipDetail);
      FWK_I_MGT_ENTITY.Release(ltCRUD_FalTaskChipDetail);
    end loop;
  end deleteOldSchedStepChipDetail;

  /**
  * Description
  *    Cette procédure va supprimer les informations de déchets récupérables de
  *    l'opération de lot dont la clef primaire est transmise en paramètre.
  *    la gamme opératoire
  */
  procedure deleteOldTaskLinkChipDetail(inFalTaskLinkID in FAL_TASK_CHIP_DETAIL.FAL_TASK_LINK_ID%type)
  as
    ltCRUD_FalTaskChipDetail FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for tplOldChipInfos in (select FAL_TASK_CHIP_DETAIL_ID
                              from FAL_TASK_CHIP_DETAIL
                             where FAL_TASK_LINK_ID = inFalTaskLinkID) loop
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalTaskChipDetail, ltCRUD_FalTaskChipDetail, true, tplOldChipInfos.FAL_TASK_CHIP_DETAIL_ID);
      FWK_I_MGT_ENTITY.DeleteEntity(ltCRUD_FalTaskChipDetail);
      FWK_I_MGT_ENTITY.Release(ltCRUD_FalTaskChipDetail);
    end loop;
  end deleteOldTaskLinkChipDetail;
end FAL_PRC_TASK_CHIP;
