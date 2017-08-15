--------------------------------------------------------
--  DDL for Package Body LPM_MGT_CONTRACT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LPM_MGT_CONTRACT" 
is
  /**
  * Description
  *    Code métier de l'insertion d'un contrat LPM
  */
  function insertContract(iotContract in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    lResult  := FWK_I_DML_TABLE.CRUD(iotContract);

   -- Suppression du numéro du contrat dans la table doc_free_number
   DOC_PRC_DOCUMENT.DeleteFreeNumber(FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotContract, 'LCT_NUMBER'));

   -- retourne le rowid de l'enregistrement créé (obligatoire)
   return lResult;
  end insertContract;

  /**
  * function deleteContract
  * Description
  * Code métier de l'effacement d'un contrat LPM
  * @return ROWID
  */
  function deleteContract(iotContract in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
    ltplContract FWK_TYP_LPM_ENTITY.tContract := FWK_TYP_LPM_ENTITY.gttContract(iotContract.entity_id);
  begin

    --Libère le numéro du contrat
    DOC_I_PRC_DOCUMENT_NUMBER.AddFreeNumber(iDmtNumber => ltplContract.LCT_NUMBER, iGaugeID => ltplContract.DOC_GAUGE_ID);

    lResult  := FWK_I_DML_TABLE.CRUD(iotContract);
    return null;
  end deleteContract;


end LPM_MGT_CONTRACT;
