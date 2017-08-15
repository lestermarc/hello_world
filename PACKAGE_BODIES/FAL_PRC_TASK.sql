--------------------------------------------------------
--  DDL for Package Body FAL_PRC_TASK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_TASK" 
is

  /**
  * Description
  *    Cette function va dupliquer l'opération standard dont la clef primaire est
  *    transmise en paramètre. Elle retourne la clef primaire de la nouvelle opération
  *    standard.
  */
  function duplicateTask(inFalTaskID in FAL_TASK.FAL_TASK_ID%type)
    return FAL_TASK.FAL_TASK_ID%type
  as
    ltCRUD_FalTask FWK_I_TYP_DEFINITION.t_crud_def;
    lnNewFalTaskID FAL_TASK.FAL_TASK_ID%type;
    lNewTasRef     FAL_TASK.TAS_REF%type;
  begin
    lnNewFalTaskID  := getNewId;
    FWK_I_MGT_ENTITY.new(iv_entity_name        => FWK_TYP_FAL_ENTITY.gcFalTask
                       , iot_crud_definition   => ltCRUD_FalTask
                       , iv_primary_col        => 'FAL_TASK_ID'
                       , ib_initialize         => false
                        );
    /* Copie de l'opération standard */
    FWK_I_MGT_ENTITY.prepareDuplicate(iot_crud_definition => ltCRUD_FalTask, ib_initialize => true, in_main_id => inFalTaskID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_FalTask, 'FAL_TASK_ID', lnNewFalTaskID);
    lNewTasRef      := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltCRUD_FalTask, 'TAS_REF');
    lNewTasRef      := FWK_I_LIB_ENTITY.getDuplicateValPk2(iv_entity_name => 'FAL_TASK', iv_column_name => 'TAS_REF', iv_value => lNewTasRef);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_FalTask, 'TAS_REF', lNewTasRef);
    /* Il ne doit exister qu'une seule opération standard pour la sous-traitance achat */
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_FalTask, 'TAS_GENERIC_SUBCONTRACT', 0);
    /* Insertion de la nouvelle opération standard */
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_FalTask);
    FWK_I_MGT_ENTITY.Release(ltCRUD_FalTask);
    /* Copie des informations sur les déchets récupérables */
    FAL_PRC_TASK_CHIP.copyTaskChipInfos(inSrcTaskID                    => inFalTaskID
                                      , inDestTaskID                   => lnNewFalTaskID
                                      , ivCSrcTaskKind                 => '1'   -- Op. standard
                                      , ivCDestTaskKind                => '1'   -- Op. standard
                                      , ibOnlyIfRefGoodContainsAlloy   => false
                                       );
    return lnNewFalTaskID;
  end duplicateTask;

  /**
  * Description
  *    Cette procédure va dupliquer l'opération standard dont la clef primaire est
  *    transmise en paramètre. Elle retourne la clef primaire de la nouvelle opération
  *    standard.
  */
  procedure duplicateTask(inOldFalTaskID in FAL_TASK.FAL_TASK_ID%type, onNewFalTaskID out FAL_TASK.FAL_TASK_ID%type)
  as
  begin
    onNewFalTaskID  := duplicateTask(inFalTaskID => inOldFalTaskID);
  end duplicateTask;
end FAL_PRC_TASK;
