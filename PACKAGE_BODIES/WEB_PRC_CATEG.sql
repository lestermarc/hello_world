--------------------------------------------------------
--  DDL for Package Body WEB_PRC_CATEG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_PRC_CATEG" 
is

  /**
  * Description
  *   Mise à 0 du flag Default Categ pour un bienb donné
  */
  procedure SetNoDefaultCategForGood(iGoodId in WEB_GOOD.GCO_GOOD_ID%type)
  is
  begin
    for ltplWebGood in (select WEB_GOOD_ID from WEB_GOOD where GCO_GOOD_ID = iGoodId and WGO_DEFAULT_CATEG = 1) loop
      declare
        ltWEB_GOOD FWK_I_TYP_DEFINITION.t_crud_def;
      begin
        -- Effacer le lien du composant SAV sur les positions de document
        FWK_I_MGT_ENTITY.new(FWK_TYP_WEB_ENTITY.gcWebGood, ltWEB_GOOD);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltWEB_GOOD, 'WEB_GOOD_ID', ltplWebGood.WEB_GOOD_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltWEB_GOOD, 'WGO_DEFAULT_CATEG', 0);
        FWK_I_MGT_ENTITY.UpdateEntity(ltWEB_GOOD);
        FWK_I_MGT_ENTITY.Release(ltWEB_GOOD);
      end;
    end loop;
  end SetNoDefaultCategForGood;

end WEB_PRC_CATEG;
