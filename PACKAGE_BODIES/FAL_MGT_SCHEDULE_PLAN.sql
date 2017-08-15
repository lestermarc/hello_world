--------------------------------------------------------
--  DDL for Package Body FAL_MGT_SCHEDULE_PLAN
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_MGT_SCHEDULE_PLAN" 
is
  /**
  * Description
  *    Code métier de l'insertion d'un Bien
  */
  function insertSCHEDULE_PLAN(iotSchedulePlan in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    FAL_I_PRC_SCHEDULE_PLAN.CheckSchedulePlanData(iotSchedulePlan);
    lResult  := FWK_I_DML_TABLE.CRUD(iotSchedulePlan);
    return lResult;
  end insertSCHEDULE_PLAN;

  /**
  * Description
  ||
  *    Code métier de l'insertion d'un produit
  */
  function insertLIST_STEP_LINK(iotListStepLink in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    FAL_I_PRC_SCHEDULE_PLAN.CheckListStepLinkData(iotListStepLink);
    lResult  := FWK_I_DML_TABLE.CRUD(iotListStepLink);
    return lResult;
  end insertLIST_STEP_LINK;
end FAL_MGT_SCHEDULE_PLAN;
