--------------------------------------------------------
--  DDL for Package Body DOC_MGT_GAUGE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_MGT_GAUGE" 
is
  /**
  * Description
  *    Code métier de l'insertion d'un avetissement de flux
  */
  function insertGAUGE_FLOW_WARNINGS(iotGaugeFlowWarnings in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- Mise à jour du flag avertissement sur la table DOC_GAUGE_COPY ou DOC_GAUGE_RECEIPT
    DOC_PRC_FLOW_WARNINGS.UpdateFlag(iotGaugeFlowWarnings, 1);
    lResult  := FWK_I_DML_TABLE.CRUD(iotGaugeFlowWarnings);
    -- retourne le rowid de l'enregistrement créé (obligatoire)
    return lResult;
  end insertGAUGE_FLOW_WARNINGS;

  /**
  * function deleteGAUGE_FLOW_WARNINGS
  * Description
  *    Code métier de la suppression d'un avetissement de flux
  */
  function deleteGAUGE_FLOW_WARNINGS(iotGaugeFlowWarnings in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
    lnCount number(10);
  begin
    -- Mise à jour du flag avertissement sur la table DOC_GAUGE_COPY ou DOC_GAUGE_RECEIPT
    DOC_PRC_FLOW_WARNINGS.UpdateFlag(iotGaugeFlowWarnings, 0);
    lResult  := FWK_I_DML_TABLE.CRUD(iotGaugeFlowWarnings);
    return null;
  end deleteGAUGE_FLOW_WARNINGS;
end DOC_MGT_GAUGE;
