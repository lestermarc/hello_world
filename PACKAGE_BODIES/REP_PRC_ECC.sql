--------------------------------------------------------
--  DDL for Package Body REP_PRC_ECC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_PRC_ECC" 
is
  /**
  * fonction synchronizeGood
  * Description
  *    Synchronisation d'un article vers un autre selon les options transmises
  */
  function synchronizeGood(iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type, iToGoodId in GCO_GOOD.GCO_GOOD_ID%type, iOptions in clob, iIsTest number default 0)
    return number
  as
    lTextDocument clob;   -- Fichier XML de synchronisation
  begin
    if    (iFromGoodId is null)
       or (iToGoodId is null)
       or (iOptions is null)
       or (DBMS_LOB.getLength(iOptions) = 0) then
      return -1;
    end if;

    -- Récupération du document.
    lTextDocument  := REP_LIB_ECC_XML.getGoodXml(iFromGoodId, iToGoodId, iOptions);
    -- Envoi au réplicateur.
    return REP_REPLICATE.SynchronizeText(TextDocument => lTextDocument, UseDebug => REP_REPLICATE.DEBUG_COMPLETE, IsTest => iIsTest);
  end synchronizeGood;

  /**
  * fonction SyncError
  * Description
  *    Enregistrement d'une erreur de synchronisation. Utilisation d'un transaction autonome pour éviter d'interférer avec le code métier.
  */
  procedure syncError(
    iMessage  in COM_ECC_ERROR.ECC_ERR_MESSAGE%type
  , iEntity   in COM_ECC_ERROR.ECC_ENTITY_NAME%type
  , iEntityId in COM_ECC_ERROR.ECC_ENTITY_ID%type
  , iDocument in clob
  )
  is
    pragma autonomous_transaction;
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_I_TYP_COM_ENTITY.gcComEccError, iot_crud_definition => lt_crud_def, ib_initialize => true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ECC_XML', iDocument);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ECC_ERR_MESSAGE', iMessage);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ECC_ENTITY_NAME', iEntity);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ECC_ENTITY_ID', iEntityId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'C_ERROR_TYPE', '00');
    FWK_I_MGT_ENTITY.InsertEntity(lt_crud_def);
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
    commit;
  end SyncError;
end REP_PRC_ECC;
