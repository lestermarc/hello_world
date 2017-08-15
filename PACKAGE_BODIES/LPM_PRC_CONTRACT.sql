--------------------------------------------------------
--  DDL for Package Body LPM_PRC_CONTRACT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "LPM_PRC_CONTRACT" 
as
  /**
  * procedure CloseReferents
  * description :
  *    Attribue la date de fin de contrat pour les appartenances liée
  *    au contrat pour autant qu'aucune date ne soit définie.
  */
  procedure CloseReferents(iContractId in LPM_CONTRACT.LPM_CONTRACT_ID%type default null, iEndDate in date)
  is
    ltReferents FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for ltplReferents in (select LPM_REFERENTS_ID
                            from LPM_REFERENTS
                           where LPM_CONTRACT_ID = iContractId
                             and LRE_END_DATE is null) loop
      FWK_I_MGT_ENTITY.new(FWK_TYP_LPM_ENTITY.gcLpmReferents, ltReferents);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltReferents, 'LPM_REFERENTS_ID', ltplReferents.LPM_REFERENTS_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltReferents, 'LRE_END_DATE', iEndDate);
      FWK_I_MGT_ENTITY.UpdateEntity(ltReferents);
      FWK_I_MGT_ENTITY.Release(ltReferents);
    end loop;
  end CloseReferents;
end LPM_PRC_CONTRACT;
