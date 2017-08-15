--------------------------------------------------------
--  DDL for Package Body ACS_SUBSET_FCT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACS_SUBSET_FCT" 
is

  /**
  * Description
  *    Renvoie C_SUB_SET sur la base de l'ID du sous-ensemble
  **/
  function GetSubSetOfSubSet(pSubSetId ACS_SUB_SET.ACS_SUB_SET_ID%type)
        return ACS_SUB_SET.C_SUB_SET%type
  is
    vSubSet ACS_SUB_SET.C_SUB_SET%type;
  begin
    vSubSet := ACS_FUNCTION.GetSubSetOfSubSet(pSubSetId);
    return vSubSet;
  end GetSubSetOfSubSet;

  /**
  * Description
  *   Renvoie 1 ou 0 selon l'existence ou non d'un sous-ensemble dont la numérotation correspond
  *   au type de clé donné
  */
  function ExistSubSetByKeyFormat(pKeyType PAC_KEY_FORMAT.C_KEY_TYPE%type)
        return number
  is
    vExistSubSet number;
  begin
    select sign(nvl(max(ACS_SUB_SET_ID),0))
    into vExistSubSet
    from ACS_SUB_SET
    where C_TYPE_NUM_AUTO = pKeyType;

    return vExistSubSet;

  end ExistSubSetByKeyFormat;


end ACS_SUBSET_FCT;
