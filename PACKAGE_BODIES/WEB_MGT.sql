--------------------------------------------------------
--  DDL for Package Body WEB_MGT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "WEB_MGT" 
is
  /**
  * Description
  *    Code métier de l'insertion d'un bien dans le shop web
  */
  function insertWEB_GOOD(iot_crud_definition in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
  begin
    if FWK_I_MGT_ENTITY_DATA.IsNull(iot_crud_definition, 'WGO_IS_ACTIVE') then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iot_crud_definition, 'WGO_IS_ACTIVE', 1);
    end if;

    FWK_I_MGT_ENTITY_DATA.SetColumn(iot_crud_definition
                                  , 'WGO_DEFAULT_CATEG'
                                  , WEB_LIB_CATEG.CheckCategDefaultIntegrity(iGoodId         => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_crud_definition
                                                                                                                                    , 'GCO_GOOD_ID'
                                                                                                                                     )
                                                                           , iCategArrayId   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_crud_definition
                                                                                                                                    , 'WEB_CATEG_ARRAY_ID'
                                                                                                                                     )
                                                                            )
                                   );
    /***********************************
    ** execution of CRUD instruction
    ***********************************/
    return fwk_i_dml_table.CRUD(iot_crud_definition);
  end insertWEB_GOOD;

  /**
  * function insertWEB_GOOD
  * Description
  *    Code métier de l'insertion d'un bien dans le shop web
  * @created fpe 23.05.2012
  * @lastUpdate
  * @public
  * @param it_crud_definition : voir définition type fwk_i_typ_definition.CRUD_DEF_T
  * @return ROWID
  */
  function updateWEB_GOOD(iot_crud_definition in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
  begin
    /***********************************
    ** execution of CRUD instruction
    ***********************************/
    -- si on défini la catégorie courante comme catégorie par défaut du bien, on s'assure que le bien n'ait pas d'autre catégorie par défaut
    if     FWK_I_MGT_ENTITY_DATA.IsModified(iot_crud_definition, 'WGO_DEFAULT_CATEG')
       and FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_crud_definition, 'WGO_DEFAULT_CATEG') = 1 then
      WEB_PRC_CATEG.SetNoDefaultCategForGood(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_crud_definition, 'GCO_GOOD_ID') );
    end if;

    return fwk_i_dml_table.CRUD(iot_crud_definition);
  end updateWEB_GOOD;
end WEB_MGT;
