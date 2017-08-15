--------------------------------------------------------
--  DDL for Package Body SHP_PRC_PUBLISH
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SHP_PRC_PUBLISH" 
as
  /**
  * Description
  *    Cette fonction insère ou met un élément à jour dans la table SHP_TO_PUBLISH
  *    Retourne 1 si ok, 0 en cas d'erreur.
  */
  function publishRecord(
    inStpRecID      in SHP_TO_PUBLISH.STP_REC_ID%type default null
  , ivStpContext    in SHP_TO_PUBLISH.STP_CONTEXT%type
  , ivGooWebStatus  in SHP_TO_PUBLISH.C_GOO_WEB_STATUS%type
  , ivShopDocStatus in SHP_TO_PUBLISH.STP_SHOP_DOC_STATUS%type default null
  , ivShopDocNumber in SHP_TO_PUBLISH.STP_SHOP_DOC_NUMBER%type default null
  )
    return integer
  is
    lnShpToPublishID    SHP_TO_PUBLISH.SHP_TO_PUBLISH_ID%type;
    ltCRUD_ShpToPublish FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_SHP_ENTITY.gcShpToPublish, ltCRUD_ShpToPublish);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpToPublish, 'STP_REC_ID', inStpRecID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpToPublish, 'STP_CONTEXT', ivStpContext);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpToPublish, 'C_GOO_WEB_STATUS', ivGooWebStatus);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpToPublish, 'STP_SHOP_DOC_STATUS', ivShopDocStatus);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpToPublish, 'STP_SHOP_DOC_NUMBER', ivShopDocNumber);

    begin
      select SHP_TO_PUBLISH_ID
        into lnShpToPublishID
        from SHP_TO_PUBLISH
       where nvl(STP_REC_ID, 0) = nvl(inStpRecID, 0)
         and STP_CONTEXT = ivStpContext;

      -- Mise à jour
      FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpToPublish, 'SHP_TO_PUBLISH_ID', lnShpToPublishID);
      FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_ShpToPublish);
    exception
      when no_data_found then
        -- insertion
        FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_ShpToPublish);
    end;

    FWK_I_MGT_ENTITY.Release(ltCRUD_ShpToPublish);
    return 1;
  exception
    when others then
      return 0;
  end publishRecord;

  /**
  * Description
  *    Cette procédure insère ou met un élément à jour dans la table SHP_PUBLISHED.
  *    Elle supprime également l'élément correspondant dans la table SHP_TO_PUBLISH.
  */
  procedure updatePublishedRecord(inRecId in SHP_PUBLISHED.SPP_REC_ID%type, ivContext in SHP_PUBLISHED.SPP_CONTEXT%type)
  is
    lnShpToPublishID        SHP_TO_PUBLISH.SHP_TO_PUBLISH_ID%type;
    lnShpPublishedProductID SHP_PUBLISHED.SHP_PUBLISHED_ID%type;
    ltCRUD_ShpToPublish     FWK_I_TYP_DEFINITION.t_crud_def;
    ltCRUD_ShpPublished     FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Récupération de l'ID
    select SHP_TO_PUBLISH_ID
      into lnShpToPublishID
      from SHP_TO_PUBLISH
     where STP_REC_ID = inRecId
       and upper(STP_CONTEXT) = ivContext;

    -- Suppression de la table SHP_TO_PUBLISH
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_SHP_ENTITY.gcShpToPublish, ltCRUD_ShpToPublish, true, lnShpToPublishID);
    --FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpToPublish, 'SHP_TO_PUBLISH_ID', lnShpToPublishID);
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_SHP_ENTITY.gcShpPublished, ltCRUD_ShpPublished, false);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpPublished, 'C_GOO_WEB_STATUS', '1');
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpPublished, 'SPP_ERP_DATE_PUBLISHED', sysdate);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpPublished
                                  , 'SPP_SHOP_DOC_STATUS'
                                  , FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltCRUD_ShpToPublish, 'STP_SHOP_DOC_STATUS')
                                   );
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpPublished
                                  , 'SPP_SHOP_DOC_NUMBER'
                                  , FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltCRUD_ShpToPublish, 'STP_SHOP_DOC_NUMBER')
                                   );
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpPublished, 'C_GOO_WEB_STATUS', FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltCRUD_ShpToPublish, 'C_GOO_WEB_STATUS') );
    FWK_I_MGT_ENTITY.DeleteEntity(ltCRUD_ShpToPublish);
    FWK_I_MGT_ENTITY.Release(ltCRUD_ShpToPublish);
    -- Insertion/màj dans la table SHP_PUBLISHED
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpPublished, 'SPP_ERP_DATE_PUBLISHED', sysdate);
    FWK_I_MGT_ENTITY_DATA.setcolumnNull(ltCRUD_ShpPublished, 'SPP_SHOP_DATE_PUBLISHED');

    begin
      select SHP_PUBLISHED_ID
        into lnShpPublishedProductID
        from SHP_PUBLISHED
       where nvl(SPP_REC_ID, 0) = nvl(inRecId, 0)
         and upper(SPP_CONTEXT) = ivContext;

      -- Mise à jour
      FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpPublished, 'SHP_PUBLISHED_ID', lnShpPublishedProductID);
      FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_ShpPublished);
    exception
      when no_data_found then
        -- insertion
        FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpPublished, 'SPP_REC_ID', inRecId);
        FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpPublished, 'SPP_CONTEXT', upper(ivContext) );
        FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_ShpPublished);
    end;

    FWK_I_MGT_ENTITY.Release(ltCRUD_ShpToPublish);
  end updatePublishedRecord;

  /**
  * Description
  *    Cette procédure met à jour le statut d'un élément de la table "SHP_TO_PUBLISH"
  */
  procedure updateToPublishRecordStatus(
    inStpRecID     in SHP_TO_PUBLISH.STP_REC_ID%type
  , ivStpContext   in SHP_TO_PUBLISH.STP_CONTEXT%type
  , ivGooWebStatus in SHP_TO_PUBLISH.C_GOO_WEB_STATUS%type
  )
  as
    lnShpToPublishID    SHP_TO_PUBLISH.SHP_TO_PUBLISH_ID%type;
    ltCRUD_ShpToPublish FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Récupération de l'ID
    select SHP_TO_PUBLISH_ID
      into lnShpToPublishID
      from SHP_TO_PUBLISH
     where STP_REC_ID = inStpRecID
       and STP_CONTEXT = ivStpContext;

    FWK_I_MGT_ENTITY.new(FWK_I_TYP_SHP_ENTITY.gcShpPublished, ltCRUD_ShpToPublish, false);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpToPublish, 'SHP_TO_PUBLISH_ID', lnShpToPublishID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpToPublish, 'C_GOO_WEB_STATUS', ivGooWebStatus);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_ShpToPublish);
    FWK_I_MGT_ENTITY.Release(ltCRUD_ShpToPublish);
  end updateToPublishRecordStatus;

  /**
  * Description
  *    Cette procédure met à jour le statut d'un élément de la table "SHP_PUBLISHED"
  */
  procedure updatePublishedRecordStatus(
    inSppRecID     in SHP_PUBLISHED.SPP_REC_ID%type
  , ivSppContext   in SHP_PUBLISHED.SPP_CONTEXT%type
  , ivGooWebStatus in SHP_PUBLISHED.C_GOO_WEB_STATUS%type
  )
  as
    lnShpPublishedID    SHP_TO_PUBLISH.SHP_TO_PUBLISH_ID%type;
    ltCRUD_ShpPublished FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Récupération de l'ID
    select SHP_TO_PUBLISH_ID
      into lnShpPublishedID
      from SHP_TO_PUBLISH
     where STP_REC_ID = inSppRecID
       and STP_CONTEXT = ivSppContext;

    FWK_I_MGT_ENTITY.new(FWK_I_TYP_SHP_ENTITY.gcShpPublished, ltCRUD_ShpPublished, false);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpPublished, 'SHP_TO_PUBLISH_ID', lnShpPublishedID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpPublished, 'C_GOO_WEB_STATUS', ivGooWebStatus);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_ShpPublished);
    FWK_I_MGT_ENTITY.Release(ltCRUD_ShpPublished);
  end updatePublishedRecordStatus;

  /**
  * procedure updatePublishedElementStatus
  * Description
  *    Cette procédure met à jour le statut d'un élément de la table "SHP_PUBLISHED"
  */
  procedure updatePublishedElementStatus(
    inSppRecID      in SHP_PUBLISHED.SPP_REC_ID%type
  , ivSppContext    in SHP_PUBLISHED.SPP_CONTEXT%type
  , ivElementStatus in SHP_PUBLISHED.C_SHP_ELEMENT_STATUS%type
  , ivErrorMessage  in SHP_PUBLISHED.SPP_SHOP_ERROR_MESSAGE%type
  )
  is
    lnPublishedElementID SHP_PUBLISHED.SHP_PUBLISHED_ID%type;
    ltCRUD_ShpPublished  FWK_I_TYP_DEFINITION.t_crud_def;
    lErrorMsg            varchar2(255);
  begin
    begin
      /* Récupération de l'ID de l'élément à publier */
      select SHP_PUBLISHED_ID
        into lnPublishedElementID
        from SHP_PUBLISHED
       where SPP_REC_ID = inSppRecID
         and SPP_CONTEXT = ivSppContext;
    exception
      when no_data_found then
        lErrorMsg  := PCS.PC_FUNCTIONS.TranslateWord('PCS - Ce produit (ID : [XXXX]) n''existe pas ou n''a pas été exporté !');
        lErrorMsg  := replace(lErrorMsg, '[XXXX]', inSppRecID);
        ra(lErrorMsg);
    end;

    FWK_I_MGT_ENTITY.new(FWK_I_TYP_SHP_ENTITY.gcShpPublished, ltCRUD_ShpPublished, false);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpPublished, 'SHP_PUBLISHED_ID', lnPublishedElementID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpPublished, 'C_SHP_ELEMENT_STATUS', ivElementStatus);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_ShpPublished, 'SPP_SHOP_ERROR_MESSAGE', ivErrorMessage);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_ShpPublished);
    FWK_I_MGT_ENTITY.Release(ltCRUD_ShpPublished);
  end updatePublishedElementStatus;
end SHP_PRC_PUBLISH;
