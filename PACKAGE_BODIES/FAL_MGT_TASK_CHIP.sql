--------------------------------------------------------
--  DDL for Package Body FAL_MGT_TASK_CHIP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_MGT_TASK_CHIP" 
is
  /**
  * Description
  *    Code m�tier de l'insertion d'un d�tail de r�cup�ration des copeaux sur op�ration
  */
  function insertTASK_CHIP_DETAIL(iotTaskChipDetail in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    /* Contr�le des actions sur l'op�ration. Note : si les deux sont coch�e, la pes�e de copeaux � la priorit�. */
    FAL_PRC_TASK_CHIP.CheckActionsFromTask(iotTaskChipDetail => iotTaskChipDetail);

    lResult  := FWK_I_DML_TABLE.CRUD(iotTaskChipDetail);
    return lResult;
  end insertTASK_CHIP_DETAIL;

  /**
  * Description
  *    Code m�tier de la mise � jour d'un d�tail de r�cup�ration des copeaux sur op�ration
  */
  function updateTASK_CHIP_DETAIL(iotTaskChipDetail in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    /* Contr�le des actions sur l'op�ration. Note : si les deux sont coch�e, la pes�e de copeaux � la priorit�. */
    FAL_PRC_TASK_CHIP.CheckActionsFromTask(iotTaskChipDetail => iotTaskChipDetail);

    lResult  := FWK_I_DML_TABLE.CRUD(iotTaskChipDetail);
    return lResult;
  end updateTASK_CHIP_DETAIL;
end FAL_MGT_TASK_CHIP;
