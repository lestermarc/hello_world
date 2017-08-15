--------------------------------------------------------
--  DDL for Package Body GAL_MGT_PROJECT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GAL_MGT_PROJECT" 
is
  /**
  * Description
  *    Code métier de l'insertion d'un projet
  */
  function insertPROJECT(iotPROJECT in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    GAL_I_PRC_PROJECT.CheckPROJECTData(iotPROJECT);
    lResult  := FWK_I_DML_TABLE.CRUD(iotPROJECT);
    return lResult;
  end insertPROJECT;

  /**
  * Description
  *    Code métier de l'insertion d'une tranche de couverture
  */
  function insertCURRENCY_RISK(iotCURRENCY_RISK in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    GAL_I_PRC_PROJECT.CheckCURRENCY_RISKData(iotCURRENCY_RISK);
    lResult  := FWK_I_DML_TABLE.CRUD(iotCURRENCY_RISK);
    GAL_I_PRC_PROJECT.CheckCURRENCY_RISK_VIRTUALData(iotCURRENCY_RISK);
    return lResult;
  end insertCURRENCY_RISK;

  /**
  * Description
  *    Code métier de la modification d'une tranche de couverture
  */
  function updateCURRENCY_RISK(iotCURRENCY_RISK in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    GAL_I_PRC_PROJECT.CheckCURRENCY_RISKData(iotCURRENCY_RISK);
    GAL_I_PRC_PROJECT.CheckCURRENCY_RISK_VIRTUALData(iotCURRENCY_RISK);
    lResult  := FWK_I_DML_TABLE.CRUD(iotCURRENCY_RISK);
    return lResult;
  end updateCURRENCY_RISK;

  /**
  * Description
  *    Code métier de la suppression d'une tranche de couverture
  */
  function deleteCURRENCY_RISK(iotCURRENCY_RISK in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    GAL_I_PRC_PROJECT.CheckCURRENCY_RISK_VIRTUALData(iotCURRENCY_RISK);
    lResult  := FWK_I_DML_TABLE.CRUD(iotCURRENCY_RISK);
    return lResult;
  end deleteCURRENCY_RISK;

  /**
  * Description
  *    Code métier de l'insertion d'une tâche
  */
  function insertTASK(iotTASK in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    GAL_I_PRC_PROJECT.CheckTASKData(iotTASK);
    lResult  := FWK_I_DML_TABLE.CRUD(iotTASK);
    return lResult;
  end insertTASK;

  /**
  * Description
  *    Code métier de l'insertion d'un composant
  */
  function insertTASK_GOOD(iotTASK_GOOD in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    GAL_I_PRC_PROJECT.CheckTASK_GOODData(iotTASK_GOOD);
    lResult  := FWK_I_DML_TABLE.CRUD(iotTASK_GOOD);
    return lResult;
  end insertTASK_GOOD;

  /**
  * Description
  *    Code métier de l'insertion d'un composé
  */
  function insertTASK_LOT(iotTASK_LOT in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    GAL_I_PRC_PROJECT.CheckTASK_LOTData(iotTASK_LOT);
    lResult  := FWK_I_DML_TABLE.CRUD(iotTASK_LOT);
    return lResult;
  end insertTASK_LOT;

  /**
  * Description
  *    Code métier de l'insertion d'une opération
  */
  function insertTASK_LINK(iotTASK_LINK in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    GAL_I_PRC_PROJECT.CheckTASK_LINKData(iotTASK_LINK);
    lResult  := FWK_I_DML_TABLE.CRUD(iotTASK_LINK);
    return lResult;
  end insertTASK_LINK;

  /**
  * Description
  *    Code métier de l'insertion d'une ligne de budget
  */
  function insertBUDGET_LINE(iotBUDGET_LINE in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    GAL_I_PRC_PROJECT.CheckBUDGET_LINEData(iotBUDGET_LINE);
    lResult  := FWK_I_DML_TABLE.CRUD(iotBUDGET_LINE);
    return lResult;
  end insertBUDGET_LINE;

/**
  * Description
  *    Code métier de lmise à jour d'une ligne de budget
  */
  function updateBUDGET_LINE(iotBUDGET_LINE in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    GAL_I_PRC_PROJECT.CheckBUDGET_LINEData(iotBUDGET_LINE);
    lResult  := FWK_I_DML_TABLE.CRUD(iotBUDGET_LINE);
    return lResult;
  end updateBUDGET_LINE;
end GAL_MGT_PROJECT;
