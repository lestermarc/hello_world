--------------------------------------------------------
--  DDL for Package Body PPS_MGT_NOMENCLATURE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PPS_MGT_NOMENCLATURE" 
is
  /**
  * Description
  *    Code métier de l'insertion d'un Bien
  */
  function insertNOMENCLATURE(iotNomenclature in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    PPS_I_PRC_NOMENCLATURE.CheckNomenclatureData(iotNomenclature);
    lResult  := FWK_I_DML_TABLE.CRUD(iotNomenclature);
    return lResult;
  end insertNOMENCLATURE;

  /**
  * Description
  ||
  *    Code métier de l'insertion d'un produit
  */
  function insertNOM_BOND(iotNomBond in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    PPS_I_PRC_NOMENCLATURE.CheckNomBondData(iotNomBond);
    lResult  := FWK_I_DML_TABLE.CRUD(iotNomBond);
    return lResult;
  end insertNOM_BOND;
end PPS_MGT_NOMENCLATURE;
