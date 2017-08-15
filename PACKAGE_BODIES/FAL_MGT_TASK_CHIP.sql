--------------------------------------------------------
--  DDL for Package Body FAL_MGT_TASK_CHIP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_MGT_TASK_CHIP" 
is
  /**
  * Description
  *    Code métier de l'insertion d'un détail de récupération des copeaux sur opération
  */
  function insertTASK_CHIP_DETAIL(iotTaskChipDetail in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    /* Contrôle des actions sur l'opération. Note : si les deux sont cochée, la pesée de copeaux à la priorité. */
    FAL_PRC_TASK_CHIP.CheckActionsFromTask(iotTaskChipDetail => iotTaskChipDetail);

    lResult  := FWK_I_DML_TABLE.CRUD(iotTaskChipDetail);
    return lResult;
  end insertTASK_CHIP_DETAIL;

  /**
  * Description
  *    Code métier de la mise à jour d'un détail de récupération des copeaux sur opération
  */
  function updateTASK_CHIP_DETAIL(iotTaskChipDetail in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    /* Contrôle des actions sur l'opération. Note : si les deux sont cochée, la pesée de copeaux à la priorité. */
    FAL_PRC_TASK_CHIP.CheckActionsFromTask(iotTaskChipDetail => iotTaskChipDetail);

    lResult  := FWK_I_DML_TABLE.CRUD(iotTaskChipDetail);
    return lResult;
  end updateTASK_CHIP_DETAIL;
end FAL_MGT_TASK_CHIP;
