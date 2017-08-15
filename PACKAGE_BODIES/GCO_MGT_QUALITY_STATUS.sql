--------------------------------------------------------
--  DDL for Package Body GCO_MGT_QUALITY_STATUS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_MGT_QUALITY_STATUS" 
is
  /**
  * function deleteQUALITY_STATUS
  * Description
  * Code métier de l'effacement d'un statut qualité
  * @created JFR 14.03.2014
  * @lastUpdate
  * @public
  * @param iotQualityStatus : GCO_QUALITY_STATUS de type T_CRUD_DEF
  * @return ROWID
  */
  function deleteQUALITY_STATUS(iotQualityStatus in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    FWK_I_MGT_ENTITY.DeleteChildren(iv_child_name     => 'GCO_QUALITY_STAT_DESCR'
                              , iv_parent_key_name    => 'GCO_QUALITY_STATUS_ID'
                              , iv_parent_key_value   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotQualityStatus, 'GCO_QUALITY_STATUS_ID'));

    lResult  := FWK_I_DML_TABLE.CRUD(iotQualityStatus);
    return null;
  end deleteQUALITY_STATUS;

end GCO_MGT_QUALITY_STATUS;
