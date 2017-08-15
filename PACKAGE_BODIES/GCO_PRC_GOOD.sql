--------------------------------------------------------
--  DDL for Package Body GCO_PRC_GOOD
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_PRC_GOOD" 
is
  type TLINK_ID is record(
    LINK_ID number(12)
  );

  -- Table mémoire
  type TLINK_MATCH is table of TLINK_ID
    index by varchar2(12);

  -- Indiquer que l'on a effectué la génération automatique de la réf. d'un bien
  procedure pAutoRefGenerated(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, iReference in GCO_GOOD.GOO_MAJOR_REFERENCE%type)
  is
    ltComListIdTemp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    null;
    FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListIdTemp, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListIdTemp, 'COM_LIST_ID_TEMP_ID', iGoodID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListIdTemp, 'LID_CODE', 'GCO_PRC_GOOD.GenerateAutoRef');
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListIdTemp, 'LID_FREE_CHAR_1', iReference);
    FWK_I_MGT_ENTITY.InsertEntity(ltComListIdTemp);
    FWK_I_MGT_ENTITY.Release(ltComListIdTemp);
  end pAutoRefGenerated;

  -- Vérifier si l'on est déjà passé par la génération automatique (pour ne pas le faire plusieurs fois)
  function pAutoRefAlreadyGenerated(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    return boolean
  is
    lnExists integer;
  begin
    select 1
      into lnExists
      from COM_LIST_ID_TEMP
     where COM_LIST_ID_TEMP_ID = iGoodID
       and LID_CODE = 'GCO_PRC_GOOD.GenerateAutoRef';

    return true;
  exception
    when no_data_found then
      return false;
  end pAutoRefAlreadyGenerated;

  /**
  * function CreateGood
  * Description
  *   Création d'un bien
  * @created AGA 16.12.2011
  * @lastUpdate
  * @public
  * @param iGOO_MAJOR_REFERENCE          : Référence principale
  * @param iDES_SHORT_DESCRIPTION        : Description article
  * @param iC_GOOD_STATUS                : Statut du bien
  * @param iDIC_UNIT_OF_MEASURE_ID       : Code unité de mesure
  * @param iGCO_GOOD_CATEGORY_ID         : Catégorie de bien
  * @param iC_MANAGEMENT_MODE            : Mode de gestion
  * @param iGOO_NUMBER_OF_DECIMAL        : Nbre de décimales gérées
  * @return number                       : valeur de GCO_GOOD_ID de l'enregistrement créé
  */
  function CreateGood(
    iGOO_MAJOR_REFERENCE     in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , iGOO_SECONDARY_REFERENCE in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , iDES_SHORT_DESCRIPTION   in GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type
  , iDES_LONG_DESCRIPTION    in GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type
  , iDES_FREE_DESCRIPTION    in GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type
  , iC_GOOD_STATUS           in GCO_GOOD.C_GOOD_STATUS%type
  , iDIC_UNIT_OF_MEASURE_ID  in GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type
  , iGCO_GOOD_CATEGORY_ID    in GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_ID%type
  , iC_MANAGEMENT_MODE       in GCO_GOOD.C_MANAGEMENT_MODE%type
  , iGOO_NUMBER_OF_DECIMAL   in GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type
  )
    return number
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
    lResult    GCO_GOOD.GCO_GOOD_ID%type;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoGood, ltCRUD_DEF, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GOO_MAJOR_REFERENCE', iGOO_MAJOR_REFERENCE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GOO_SECONDARY_REFERENCE', iGOO_SECONDARY_REFERENCE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_GOOD_STATUS', iC_GOOD_STATUS);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_UNIT_OF_MEASURE_ID', iDIC_UNIT_OF_MEASURE_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_GOOD_CATEGORY_ID', iGCO_GOOD_CATEGORY_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_MANAGEMENT_MODE', iC_MANAGEMENT_MODE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GOO_NUMBER_OF_DECIMAL', iGOO_NUMBER_OF_DECIMAL);
    -- DML statement
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    lResult  := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltCRUD_DEF, 'GCO_GOOD_ID');
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);

    for tplLang in (select PC_LANG_ID
                      from PCS.PC_LANG
                     where LANUSED = 1
                       and PC_LANG_ID not in(select PC_LANG_ID
                                               from GCO_DESCRIPTION
                                              where GCO_GOOD_ID = lResult
                                                and C_DESCRIPTION_TYPE = '01') ) loop
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoDescription, ltCRUD_DEF, true);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_GOOD_ID', lResult);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_LANG_ID', tplLang.PC_LANG_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_DESCRIPTION_TYPE', '01');   -- principale
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DES_SHORT_DESCRIPTION', iDES_SHORT_DESCRIPTION);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DES_LONG_DESCRIPTION', iDES_LONG_DESCRIPTION);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DES_FREE_DESCRIPTION', iDES_FREE_DESCRIPTION);
      FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    end loop;

    return lResult;
  end CreateGood;

  /**
  * procedure UpdateGood
  * Description
  *   Création d'un bien
  * @created AGA 16.12.2011
  * @lastUpdate
  * @public
  * @param iGCO_GOOD_ID                  : Identifiant
  * @param iGOO_MAJOR_REFERENCE          : Référence principale
  * @param iDES_SHORT_DESCRIPTION        : Description article
  * @param iC_GOOD_STATUS                : Statut du bien
  * @param iDIC_UNIT_OF_MEASURE_ID       : Code unité de mesure
  * @param iGCO_GOOD_CATEGORY_ID         : Catégorie de bien
  * @param iC_MANAGEMENT_MODE            : Mode de gestion
  * @param iGOO_NUMBER_OF_DECIMAL        : Nbre de décimales gérées
  */
  procedure UpdateGood(
    iGCO_GOOD_ID             in GCO_GOOD.GCO_GOOD_ID%type
  , iGOO_MAJOR_REFERENCE     in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , iGOO_SECONDARY_REFERENCE in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , iDES_SHORT_DESCRIPTION   in GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type
  , iDES_LONG_DESCRIPTION    in GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type
  , iDES_FREE_DESCRIPTION    in GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type
  , iC_GOOD_STATUS           in GCO_GOOD.C_GOOD_STATUS%type
  , iDIC_UNIT_OF_MEASURE_ID  in GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type
  , iGCO_GOOD_CATEGORY_ID    in GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_ID%type
  , iC_MANAGEMENT_MODE       in GCO_GOOD.C_MANAGEMENT_MODE%type
  )
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoGood, ltCRUD_DEF);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_GOOD_ID', iGCO_GOOD_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GOO_MAJOR_REFERENCE', iGOO_MAJOR_REFERENCE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GOO_SECONDARY_REFERENCE', iGOO_SECONDARY_REFERENCE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_GOOD_STATUS', iC_GOOD_STATUS);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_UNIT_OF_MEASURE_ID', iDIC_UNIT_OF_MEASURE_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_GOOD_CATEGORY_ID', iGCO_GOOD_CATEGORY_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_MANAGEMENT_MODE', iC_MANAGEMENT_MODE);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);

    for tplLang in (select PC_LANG_ID
                      from PCS.PC_LANG
                     where LANUSED = 1
                       and PC_LANG_ID not in(select PC_LANG_ID
                                               from GCO_DESCRIPTION
                                              where GCO_GOOD_ID = iGCO_GOOD_ID
                                                and C_DESCRIPTION_TYPE = '01') ) loop
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoDescription, ltCRUD_DEF);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_GOOD_ID', iGCO_GOOD_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_LANG_ID', tplLang.PC_LANG_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_DESCRIPTION_TYPE', '01');   -- principale
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DES_SHORT_DESCRIPTION', iDES_SHORT_DESCRIPTION);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DES_LONG_DESCRIPTION', iDES_LONG_DESCRIPTION);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DES_FREE_DESCRIPTION', iDES_FREE_DESCRIPTION);
      FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    end loop;
  end UpdateGood;

  /**
  * function CreateProduct
  * Description
  *   Création d'un produit
  * @created AGA 16.12.2011
  * @lastUpdate
  * @public
  * @param iGOO_MAJOR_REFERENCE          : Référence principale
  * @param iDES_SHORT_DESCRIPTION        : Description article
  * @param iC_GOOD_STATUS                : Statut du bien
  * @param iDIC_UNIT_OF_MEASURE_ID       : Code unité de mesure
  * @paramiGCO_GOOD_CATEGORY_ID          : Catégorie de bien
  * @param iC_MANAGEMENT_MODE            : Mode de gestion
  * @param iGOO_NUMBER_OF_DECIMAL        : Nombre de décimales
  * @param iC_SUPPLY_MODE                : Mode d'approvisionnement
  * @param iC_SUPPLY_TYPE                : Type d'approvisionnement
  * @param iSTM_STOCK_ID                 : Stock par défaut produit
  * @param iSTM_LOCATION_ID              : Location par défaut produit
  * @return number                       : valeur de GCO_GOOD_ID de l'enregistrement créé
  */
  function CreateProduct(
    iGOO_MAJOR_REFERENCE     in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , iGOO_SECONDARY_REFERENCE in GCO_GOOD.GOO_SECONDARY_REFERENCE%type
  , iDES_SHORT_DESCRIPTION   in GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type
  , iDES_LONG_DESCRIPTION    in GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type
  , iDES_FREE_DESCRIPTION    in GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type
  , iC_GOOD_STATUS           in GCO_GOOD.C_GOOD_STATUS%type
  , iDIC_UNIT_OF_MEASURE_ID  in GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type
  , iGCO_GOOD_CATEGORY_ID    in GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_ID%type
  , iC_MANAGEMENT_MODE       in GCO_GOOD.C_MANAGEMENT_MODE%type
  , iGOO_NUMBER_OF_DECIMAL   in GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type
  , iC_SUPPLY_MODE           in GCO_PRODUCT.C_SUPPLY_MODE%type
  , iC_SUPPLY_TYPE           in GCO_PRODUCT.C_SUPPLY_TYPE%type
  , iSTM_STOCK_ID            in GCO_PRODUCT.STM_STOCK_ID%type
  , iSTM_LOCATION_ID         in GCO_PRODUCT.STM_LOCATION_ID%type
  )
    return number
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
    lResult    GCO_GOOD.GCO_GOOD_ID%type;
  begin
    lResult  :=
      CreateGood(iGOO_MAJOR_REFERENCE
               , iGOO_SECONDARY_REFERENCE
               , iDES_SHORT_DESCRIPTION
               , iDES_LONG_DESCRIPTION
               , iDES_FREE_DESCRIPTION
               , iC_GOOD_STATUS
               , iDIC_UNIT_OF_MEASURE_ID
               , iGCO_GOOD_CATEGORY_ID
               , iC_MANAGEMENT_MODE
               , iGOO_NUMBER_OF_DECIMAL
                );
    -- création d'un produit
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoProduct, ltCRUD_DEF, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_GOOD_ID', lResult);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_SUPPLY_MODE', iC_SUPPLY_MODE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_SUPPLY_TYPE', iC_SUPPLY_TYPE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_STOCK_ID', iSTM_STOCK_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_LOCATION_ID', iSTM_LOCATION_ID);
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    return lResult;
  end CreateProduct;

  /**
  * procedure UpdateProduct
  * Description
  *   Création d'un produit
  * @created AGA 16.12.2011
  * @lastUpdate
  * @public
  * @param iGCO_GOOD_ID                  : Identifiant
  * @param iGOO_MAJOR_REFERENCE          : Référence principale
  * @param iDES_SHORT_DESCRIPTION        : Description article
  * @param iC_GOOD_STATUS                : Statut du bien
  * @param iDIC_UNIT_OF_MEASURE_ID       : Code unité de mesure
  * @paramiGCO_GOOD_CATEGORY_ID          : Catégorie de bien
  * @param iC_MANAGEMENT_MODE            : Mode de gestion
  * @param iGOO_NUMBER_OF_DECIMAL        : Nombre de décimales
  * @param iC_SUPPLY_MODE                : Mode d'approvisionnement
  * @param iC_SUPPLY_TYPE                : Type d'approvisionnement
  * @param iSTM_STOCK_ID                 : Stock par défaut produit
  * @param iSTM_LOCATION_ID              : Location par défaut produit
  */
  procedure UpdateProduct(
    iGCO_GOOD_ID             in GCO_GOOD.GCO_GOOD_ID%type
  , iGOO_MAJOR_REFERENCE     in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , iGOO_SECONDARY_REFERENCE in GCO_GOOD.GOO_SECONDARY_REFERENCE%type
  , iDES_SHORT_DESCRIPTION   in GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type
  , iDES_LONG_DESCRIPTION    in GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type
  , iDES_FREE_DESCRIPTION    in GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type
  , iC_GOOD_STATUS           in GCO_GOOD.C_GOOD_STATUS%type
  , iDIC_UNIT_OF_MEASURE_ID  in GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type
  , iGCO_GOOD_CATEGORY_ID    in GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_ID%type
  , iC_MANAGEMENT_MODE       in GCO_GOOD.C_MANAGEMENT_MODE%type
  , iC_SUPPLY_MODE           in GCO_PRODUCT.C_SUPPLY_MODE%type
  , iC_SUPPLY_TYPE           in GCO_PRODUCT.C_SUPPLY_TYPE%type
  , iSTM_STOCK_ID            in GCO_PRODUCT.STM_STOCK_ID%type
  , iSTM_LOCATION_ID         in GCO_PRODUCT.STM_LOCATION_ID%type
  )
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    UpdateGood(iGCO_GOOD_ID
             , iGOO_MAJOR_REFERENCE
             , iGOO_SECONDARY_REFERENCE
             , iDES_SHORT_DESCRIPTION
             , iDES_LONG_DESCRIPTION
             , iDES_FREE_DESCRIPTION
             , iC_GOOD_STATUS
             , iDIC_UNIT_OF_MEASURE_ID
             , iGCO_GOOD_CATEGORY_ID
             , iC_MANAGEMENT_MODE
              );
    -- Mise à jour d'un produit
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoProduct, ltCRUD_DEF, true, iGCO_GOOD_ID, null, 'GCO_GOOD_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_SUPPLY_MODE', iC_SUPPLY_MODE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_SUPPLY_TYPE', iC_SUPPLY_TYPE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_STOCK_ID', iSTM_STOCK_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_LOCATION_ID', iSTM_LOCATION_ID);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end UpdateProduct;

  /**
  * procedure CheckGoodData
  * Description
  *    Contrôle avant mise à jour du bien
  * @author AGA
  * @created SEP.2011
  * @lastUpdate
  * @public
  * @param   iotGood : Dossier SAV
  */
  procedure CheckGoodData(iotGood in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    ltplGood       FWK_TYP_GCO_ENTITY.tGood := FWK_TYP_GCO_ENTITY.gttGood(iotGood.entity_id);
    lMessage       varchar2(200);
    lInitGoodGroup varchar2(100);
    ltype          varchar2(100);
    lDecim         number;

    procedure SetMessage(iMess in varchar2)
    is
    begin
      if lMessage is null then
        lMessage  := iMess;
      else
        lMessage  := lMessage || chr(13) || iMess;
      end if;
    end;
  begin
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotGood, 'GCO_GOOD_ID') then
      lMessage  := 'GCO_GOOD_ID not defined';
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckGoodData'
                                         );
    end if;

    -- initialisation valeurs par défaut
    -- initialisation du status du bien
    if ltplGood.C_GOOD_STATUS is null then
      if PCS.PC_CONFIG.GetConfig('GCO_INACTIVE_CREATION_GOOD') = '1' then
        -- STATUS_INACTIF = '1';
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGood, 'C_GOOD_STATUS', '1');
      else
        -- STATUS_ACTIF = '2';
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGood, 'C_GOOD_STATUS', '2');
      end if;
    end if;

    -- initialisation CODE TAUX
    if ltplGood.C_MANAGEMENT_MODE is null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGood, 'C_MANAGEMENT_MODE', PCS.PC_CONFIG.GetConfig('GCO_CGood_MANAGEMENT_MODE') );
    end if;

    -- Initialisation Etat de publication (WEB)
    if ltplGood.C_GOO_WEB_STATUS is null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGood, 'C_GOO_WEB_STATUS', '0');
    end if;

    if ltplGood.GOO_NUMBER_OF_DECIMAL is null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGood, 'GOO_NUMBER_OF_DECIMAL ', 0);
    end if;

    -- traitement des mise à jour
    if FWK_I_MGT_ENTITY_DATA.IsModified(iotGood, 'GOO_WEB_PUBLISHED') then
      if (ltplGood.GOO_WEB_PUBLISHED = 1) then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGood, 'C_GOO_WEB_STATUS', '1');   -- à publier
      else
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGood, 'C_GOO_WEB_STATUS', '3');   -- à effacer
      end if;
    end if;

    -- Traitement du code Etat de publication (WEB)
    if (ltplGood.GOO_WEB_PUBLISHED = 1) then
      if (FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iotGood, 'C_GOO_WEB_STATUS') <> '1') then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotGood, 'C_GOO_WEB_STATUS', '2');   -- a modifier
      end if;
    end if;

    -- mise à jour de l' unités de mesures
    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotGood, 'DIC_UNIT_OF_MEASURE_ID')
       and (ltplGood.DIC_UNIT_OF_MEASURE_ID <> '') then
      update GCO_COMPL_DATA_INVENTORY
         set DIC_UNIT_OF_MEASURE_ID = ltplGood.DIC_UNIT_OF_MEASURE_ID
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where GCO_COMPL_DATA_INVENTORY.GCO_GOOD_ID = ltplGood.GCO_GOOD_ID;

      update GCO_COMPL_DATA_MANUFACTURE
         set DIC_UNIT_OF_MEASURE_ID = ltplGood.DIC_UNIT_OF_MEASURE_ID
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where GCO_COMPL_DATA_MANUFACTURE.GCO_GOOD_ID = ltplGood.GCO_GOOD_ID;

      update GCO_COMPL_DATA_STOCK
         set DIC_UNIT_OF_MEASURE_ID = ltplGood.DIC_UNIT_OF_MEASURE_ID
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where GCO_COMPL_DATA_STOCK.GCO_GOOD_ID = ltplGood.GCO_GOOD_ID;
    end if;

    lInitGoodGroup  := PCS.PC_CONFIG.GetConfig('PTC_INIT_GOOD_GROUP');

    if     (lInitGoodGroup <> '')
       and ltplGood.DIC_PTC_GOOD_GROUP_ID is null
       and not ltplGood.GCO_GOOD_ID is not null then
      insert into DIC_PTC_GOOD_GROUP
                  (DIC_PTC_GOOD_GROUP_ID
                 , DCG_DESCRIPTION
                 , A_DATECRE
                 , A_IDCRE
                  )
        select lInitGoodGroup
             , lInitGoodGroup
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from GCO_GOOD
         where GCO_GOOD_ID = ltplGood.GCO_GOOD_ID
           and not exists(select DIC_PTC_GOOD_GROUP_ID
                            from DIC_PTC_GOOD_GROUP
                           where DIC_PTC_GOOD_GROUP_ID = lInitGoodGroup);

      FWK_I_MGT_ENTITY_DATA.SetColumn(iotGood, 'DIC_PTC_GOOD_GROUP_ID', lInitGoodGroup);
    end if;

    -- changement du nombre de décimale
    if FWK_I_MGT_ENTITY_DATA.IsModified(iotGood, 'GOO_NUMBER_OF_DECIMAL') then
      if (ltplGood.GOO_NUMBER_OF_DECIMAL > 0) then
        begin
          select nvl(max(C_CHARACT_TYPE), '')
            into lType
            from GCO_CHARACTERIZATION
           where GCO_CHARACTERIZATION.GCO_GOOD_ID = ltplGood.GCO_GOOD_ID
             and C_CHARACT_TYPE = '3';

          -- le nombre de décimale ne peut etre > 0 pour un article avec charactérisation
          if lType <> '' then
            SetMessage('The number of decimal cannot be greater than 0');
          end if;
        exception
          when no_data_found then
            null;
        end;
      end if;

      begin
        select GOO_NUMBER_OF_DECIMAL
          into lDecim
          from GCO_GOOD
         where GCO_GOOD_ID = ltplGood.GCO_GOOD_ID;

        if     (ltplGood.GOO_NUMBER_OF_DECIMAL < lDecim)
           and (GCO_FUNCTIONS.IsProductInUse(ltplGood.GCO_GOOD_ID) = 1) then
          SetMessage('Product in use, change of number of decimals not allowed');
        end if;
      exception
        when no_data_found then
          null;
      end;
    end if;

    if lMessage is not null then
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckGoodData'
                                         );
    end if;
  end CheckGoodData;

  /**
  * procedure CheckProductData
  * Description
  *    Contrôle avant mise à jour du bien
  * @author AGA
  * @created SEP.2011
  * @lastUpdate
  * @public
  * @param   iotProduct : Dossier SAV
  */
  procedure CheckProductData(iotProduct in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    ltplProduct FWK_TYP_GCO_ENTITY.tProduct      := FWK_TYP_GCO_ENTITY.gttProduct(iotProduct.entity_id);
    lMessage    varchar2(200);
    lId         number;
    lSupplyMode GCO_PRODUCT.C_SUPPLY_MODE%type;

    procedure SetMessage(iMess in varchar2)
    is
    begin
      if lMessage is null then
        lMessage  := iMess;
      else
        lMessage  := lMessage || chr(13) || iMess;
      end if;
    end;
  begin
    if FWK_I_MGT_ENTITY_DATA.IsNull(iotProduct, 'GCO_GOOD_ID') then
      lMessage  := 'GCO_GOOD_ID not defined';
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckProductData'
                                         );
    end if;

    -- initialisation des valeurs par défaut
    if ltplProduct.PDT_CONTINUOUS_INVENTAR is null then
      if upper(PCS.PC_CONFIG.GetConfig('GCO_CProd_CONTINUOUS_INVENT') ) = 'TRUE' then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotProduct, 'PDT_CONTINUOUS_INVENTAR', 1);
      else
        -- STATUS_ACTIF = '2';
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotProduct, 'PDT_CONTINUOUS_INVENTAR', 0);
      end if;
    end if;

    if ltplProduct.C_PRODUCT_TYPE is null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotProduct, 'C_PRODUCT_TYPE', '1');
    end if;

    if ltplProduct.C_PRODUCT_DELIVERY_TYP is null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotProduct, 'C_PRODUCT_DELIVERY_TYP', '0');
    end if;

    if ltplProduct.C_SUPPLY_TYPE is null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(iotProduct, 'C_SUPPLY_TYPE', PCS.PC_CONFIG.GetConfig('GCO_CProd_SUPPLY_TYPE') );
    end if;

    -- traitement des mises à jour (isModified)
    if FWK_I_MGT_ENTITY_DATA.IsModified(iotProduct, 'C_SUPPLY_MODE') then
      if ltplProduct.C_SUPPLY_MODE = '3' then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotProduct, 'C_SUPPLY_TYPE', '2');
      end if;

      if     (ltplProduct.PDT_PIC = 1)
         and (ltplProduct.C_SUPPLY_MODE = '3') then
        SetMessage('PIC management does not allow appro code C_SUPPY_MODE = ''3''');
      end if;
    end if;

    if    FWK_I_MGT_ENTITY_DATA.IsModified(iotProduct, 'PDT_FULL_TRACABILITY')
       or FWK_I_MGT_ENTITY_DATA.IsModified(iotProduct, 'PDT_FULL_TRACABILITY_COEF') then
      if (ltplProduct.PDT_FULL_TRACABILITY = 0) then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotProduct, 'PDT_FULL_TRACABILITY_COEF', 0);
      elsif ltplProduct.PDT_FULL_TRACABILITY_COEF <= 0 then
        -- Si Flag PDT_FULL_TRACABILITY = 1 alors => PDT_FULL_TRACABILITY_COEF doit être non null  et  supérieur à  0
        SetMessage('Error with tracability coef.');
      end if;
    end if;

    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotProduct, 'PDT_ALTERNATIVE_QUANTITY_1')
       and (ltplProduct.PDT_ALTERNATIVE_QUANTITY_1 = 0) then
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotProduct, 'DIC_UNIT_OF_MEASURE_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotProduct, 'PDT_CONVERSION_FACTOR_1');
    end if;

    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotProduct, 'PDT_ALTERNATIVE_QUANTITY_2')
       and (ltplProduct.PDT_ALTERNATIVE_QUANTITY_2 = 0) then
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotProduct, 'DIC_UNIT_OF_MEASURE1_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotProduct, 'PDT_CONVERSION_FACTOR_2');
    end if;

    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotProduct, 'PDT_ALTERNATIVE_QUANTITY_3')
       and (ltplProduct.PDT_ALTERNATIVE_QUANTITY_3) = 0 then
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotProduct, 'DIC_UNIT_OF_MEASURE2_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotProduct, 'PDT_CONVERSION_FACTOR_3');
    end if;

    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotProduct, 'PDT_STOCK_MANAGEMENT')
       and (ltplProduct.PDT_STOCK_MANAGEMENT = 0) then
      select nvl(max(STM_STOCK_POSITION_ID), 0)
        into lId
        from STM_STOCK_POSITION
       where GCO_GOOD_ID = ltplProduct.GCO_GOOD_ID;

      if (lId > 0) then
        SetMessage('Stock position exist for this good');
      else
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotProduct, 'STM_STOCK_ID');
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotProduct, 'STM_LOCATION_ID');
      end if;
    end if;

    if     FWK_I_MGT_ENTITY_DATA.IsModified(iotProduct, 'PAC_SUPPLIER_PARTNER_ID')
       and ltplProduct.PAC_SUPPLIER_PARTNER_ID <> 0 then
      select nvl(max(GCO_GOOD_ID), 0)
        into lId
        from GCO_EQUIVALENCE_GOOD
       where GCO_GCO_GOOD_ID = ltplProduct.GCO_GOOD_ID
         and C_GEG_STATUS = '1';

      if lId > 0 then
        SetMessage('Cannot update supplier, equivalence blocs already exist');
      end if;
    end if;

    if lMessage is not null then
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lMessage
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckProductData'
                                         );
    end if;
  end;

  /**
  * Mise à jour du statut du bien avec celui passé en paramètre
  */
  procedure UpdateStatus(iGoodId GCO_GOOD.GCO_GOOD_ID%type, iGoodStatus GCO_GOOD.C_GOOD_STATUS%type)
  is
  begin
    update GCO_GOOD
       set C_GOOD_STATUS = iGoodStatus
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where GCO_GOOD_ID = iGoodId;
  end updateStatus;

    /**
  * Description
  *    Mise à 0 des compteur PRCS
  */
  procedure resetCostprice(iGoodId GCO_GOOD.GCO_GOOD_ID%type)
  is
  begin
    update GCO_GOOD_CALC_DATA
       set GOO_ADDED_QTY_COST_PRICE = 0
         , GOO_ADDED_VALUE_COST_PRICE = 0
         , GOO_BASE_COST_PRICE = 0
     where GCO_GOOD_ID = iGoodId;
  end resetCostprice;

  /**
  * procedure GenerateAutoRef
  * Description
  *   Génération d'une nouvelle réf. principale du bien en fonction
  *     de la numérotation automatique de la catégorie du bien
  */
  procedure GenerateAutoRef(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    lvNewRef GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    ltGood   FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Vérifier si l'on est déjà passé par la génération automatique (pour ne pas le faire plusieurs fois)
    if not pAutoRefAlreadyGenerated(iGoodID) then
      -- Mise à jour de la référence principale si Numérotation automatique
      GCO_GOOD_NUMBERING_FUNCTIONS.GetNumber(aID => iGoodID, aOriginTable => 'GCO_GOOD_CATEGORY', aNumber => lvNewRef);

      if lvNewRef is not null then
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoGood, ltGood, false);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltGood, 'GCO_GOOD_ID', iGoodID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltGood, 'GOO_MAJOR_REFERENCE', lvNewRef);
        FWK_I_MGT_ENTITY.UpdateEntity(ltGood);
        FWK_I_MGT_ENTITY.Release(ltGood);
        -- Indiquer que l'on a effectué la génération automatique de la réf.
        pAutoRefGenerated(iGoodID, lvNewRef);
      end if;
    end if;
  end GenerateAutoRef;

  procedure pDuplicate_GOOD(
    iSourceGoodID     in GCO_GOOD.GCO_GOOD_ID%type
  , iNewGoodID        in GCO_GOOD.GCO_GOOD_ID%type
  , iNewMajorRef      in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , iNewSecRef        in GCO_GOOD.GOO_SECONDARY_REFERENCE%type
  , iActiveGoodStatus in number
  , iDuplCML          in number default 1
  , iOptions          in GCO_LIB_CONSTANT.gtProductCopySyncOptions default null
  , iRelationTypeID   in GCO_GOOD_LINK.DIC_RELATION_TYPE_ID%type default null
  , iFreeText         in GCO_GOOD_LINK.GLI_FREE_TEXT%type default null
  )
  is
    ltNew           FWK_I_TYP_DEFINITION.t_crud_def;
    lXmlDuplOptions clob;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoGood, ltNew);
    FWK_I_MGT_ENTITY.PrepareDuplicate(ltNew, true, iSourceGoodID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GOO_MAJOR_REFERENCE', iNewMajorRef);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GOO_SECONDARY_REFERENCE', iNewSecRef);

    -- Produit au statut "Actif"
    if iActiveGoodStatus = 1 then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'C_GOOD_STATUS', '2');
    else
      -- Statut "Inactif"
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'C_GOOD_STATUS', '1');
    end if;

    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_DATA_PURCHASE', iOptions.bGCO_COMPL_DATA_PURCHASE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_DATA_SALE', iOptions.bGCO_COMPL_DATA_SALE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_DATA_STOCK', iOptions.bGCO_COMPL_DATA_STOCK);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_DATA_INVENTORY', iOptions.bGCO_COMPL_DATA_INVENTORY);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_DATA_MANUFACTURE', iOptions.bGCO_COMPL_DATA_MANUFACTURE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_DATA_SUBCONTRACT', iOptions.bGCO_COMPL_DATA_SUBCONTRACT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_DATA_SAV', iOptions.bGCO_COMPL_DATA_ASS);
    -- Données NON copiées (utilisation de la valeur par défaut )
    FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GOO_WEB_PUBLISHED');
    FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'C_GOO_WEB_STATUS');
    -- Données NON copiées
    FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GOO_EAN_CODE');
    FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GOO_EAN_UCC14_CODE');
    FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GOO_HIBC_REFERENCE');
    FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GOO_HIBC_PRIMARY_CODE');
    FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GCO_GOOD_OLE_OBJECT');
    FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GOO_VERSION1_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GOO_STD_CHAR1_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GOO_STD_CHAR2_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GOO_STD_CHAR3_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GOO_STD_CHAR4_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GOO_STD_CHAR5_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GOO_PIECE1_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GOO_PIECE2_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GOO_PIECE3_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GOO_SET1_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GOO_SET2_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GOO_SET3_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GOO_CHRONO1_ID');

    -- Données NON copiées (pour un Service si option CML cochée )
    if iDuplCML = 0 then
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'C_SERVICE_RENEWAL');
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'C_SERVICE_GOOD_LINK');
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'DIC_TARIFF_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GOO_CONTRACT_CONDITION');
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'C_SERVICE_KIND');
    end if;

    -- Insertion
    FWK_I_MGT_ENTITY.InsertEntity(ltNew);
    FWK_I_MGT_ENTITY.Release(ltNew);
    -- Générer un xml des options de duplication du produit
    lXmlDuplOptions  := GCO_LIB_FUNCTIONS.loadProductCopySyncOptions(iOptions => iOptions);
    -- Générer le lien entre les produits source - cible dans la table de lien
    CreateGoodLink(iLinkType         => '1'
                 , iSourceGoodID     => iSourceGoodID
                 , iTargetGoodID     => iNewGoodID
                 , iRelationTypeID   => iRelationTypeID
                 , iFreeText         => iFreeText
                 , iOptions          => lXmlDuplOptions
                  );
  end pDuplicate_GOOD;

  procedure pDuplicate_PRODUCT(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltNew FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_I_TYP_GCO_ENTITY.gcGcoProduct, iot_crud_definition => ltNew, iv_primary_col => 'GCO_GOOD_ID');
    FWK_I_MGT_ENTITY.PrepareDuplicate(ltNew, true, iSourceGoodID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
    -- Données NON copiées
    FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'PDT_VERSION_MANAGEMENT');
    FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'PDT_VERSION');
    -- Insertion
    FWK_I_MGT_ENTITY.InsertEntity(ltNew);
    FWK_I_MGT_ENTITY.Release(ltNew);
  end pDuplicate_PRODUCT;

  procedure pDuplicate_DESCRIPTION(
    iSourceGoodID  in GCO_GOOD.GCO_GOOD_ID%type
  , iNewGoodID     in GCO_GOOD.GCO_GOOD_ID%type
  , iNewShortDescr in GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type default null
  , iNewLongDescr  in GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type default null
  , iNewFreeDescr  in GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type default null
  )
  is
    ltNew FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Boucler sur toutes les descriptions du bien source
    for ltplSource in (select   GCO_DESCRIPTION_ID
                           from GCO_DESCRIPTION
                          where GCO_GOOD_ID = iSourceGoodID
                       order by GCO_DESCRIPTION_ID) loop
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoDescription, ltNew);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltNew, true, ltplSource.GCO_DESCRIPTION_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);

      -- Forcer la description courte
      if iNewShortDescr is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'DES_SHORT_DESCRIPTION', iNewShortDescr);
      end if;

      -- Forcer la description longue
      if iNewLongDescr is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'DES_LONG_DESCRIPTION', iNewLongDescr);
      end if;

      -- Forcer la description libre
      if iNewFreeDescr is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'DES_FREE_DESCRIPTION', iNewFreeDescr);
      end if;

      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
    end loop;
  end pDuplicate_DESCRIPTION;

  procedure pDuplicate_CHARACTERIZATION(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltChar     FWK_I_TYP_DEFINITION.t_crud_def;
    ltCharElem FWK_I_TYP_DEFINITION.t_crud_def;
    ltDescLang FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des caractérisations (GCO_CHARACTERIZATION) excepter dans le cas ou le produit est géré en versionning
    -- et que la caractérisation est de type version et que la config n'autorise pas la copie de la version et qu'un
    -- type de relation entre produits existe.
    for ltplChar in (select   CHA.GCO_CHARACTERIZATION_ID
                         from GCO_CHARACTERIZATION CHA
                            , GCO_PRODUCT PDT
                        where CHA.GCO_GOOD_ID = iSourceGoodID
                          and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
                          and GCO_LIB_CHARACTERIZATION.canCopyCharVersion(iSrcGoodID   => iSourceGoodID, iTgtGoodID => iNewGoodID
                                                                        , iCharType    => CHA.C_CHARACT_TYPE) = 1
                     order by CHA.GCO_CHARACTERIZATION_ID asc) loop
      -- GCO_CHARACTERIZATION
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoCharacterization, ltChar);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltChar, true, ltplChar.GCO_CHARACTERIZATION_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltChar, 'GCO_GOOD_ID', iNewGoodID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltChar);

      -- Copie des descriptions des caractérisations (GCO_DESC_LANGUAGE)
      for ltplCharDescr in (select   GCO_DESC_LANGUAGE_ID
                                from GCO_DESC_LANGUAGE
                               where GCO_CHARACTERIZATION_ID = ltplChar.GCO_CHARACTERIZATION_ID
                            order by GCO_DESC_LANGUAGE_ID asc) loop
        -- GCO_DESC_LANGUAGE liés au GCO_CHARACTERIZATION
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoDescLanguage, ltDescLang);
        FWK_I_MGT_ENTITY.PrepareDuplicate(ltDescLang, true, ltplCharDescr.GCO_DESC_LANGUAGE_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltDescLang, 'GCO_CHARACTERIZATION_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltChar, 'GCO_CHARACTERIZATION_ID') );

        -- Données NON copiées
        if FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltChar, 'CHA_AUTOMATIC_INCREMENTATION') = 1 then
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltChar, 'CHA_LAST_USED_INCREMENT', 0);
        else
          FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltChar, 'CHA_LAST_USED_INCREMENT');
        end if;

        -- Insertion
        FWK_I_MGT_ENTITY.InsertEntity(ltDescLang);
        FWK_I_MGT_ENTITY.Release(ltDescLang);
      end loop;

      -- Copie des éléments caractéristiques (GCO_CHARACTERISTIC_ELEMENT)
      for ltplCharElem in (select   GCO_CHARACTERISTIC_ELEMENT_ID
                               from GCO_CHARACTERISTIC_ELEMENT
                              where GCO_CHARACTERIZATION_ID = ltplChar.GCO_CHARACTERIZATION_ID
                           order by GCO_CHARACTERISTIC_ELEMENT_ID asc) loop
        -- GCO_CHARACTERISTIC_ELEMENT
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoCharacteristicElement, ltCharElem);
        FWK_I_MGT_ENTITY.PrepareDuplicate(ltCharElem, true, ltplCharElem.GCO_CHARACTERISTIC_ELEMENT_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCharElem, 'GCO_CHARACTERIZATION_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltChar, 'GCO_CHARACTERIZATION_ID') );
        -- Données NON copiées
        FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltCharElem, 'CHE_EAN_CODE');
        -- Insertion
        FWK_I_MGT_ENTITY.InsertEntity(ltCharElem);

        -- Copie des descriptions des éléments caractéristiques (GCO_DESC_LANGUAGE)
        for ltplCharElemDescr in (select   GCO_DESC_LANGUAGE_ID
                                      from GCO_DESC_LANGUAGE
                                     where GCO_CHARACTERISTIC_ELEMENT_ID = ltplCharElem.GCO_CHARACTERISTIC_ELEMENT_ID
                                  order by GCO_DESC_LANGUAGE_ID asc) loop
          -- GCO_DESC_LANGUAGE liés au GCO_CHARACTERISTIC_ELEMENT
          FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoDescLanguage, ltDescLang);
          FWK_I_MGT_ENTITY.PrepareDuplicate(ltDescLang, true, ltplCharElemDescr.GCO_DESC_LANGUAGE_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltDescLang
                                        , 'GCO_CHARACTERISTIC_ELEMENT_ID'
                                        , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCharElem, 'GCO_CHARACTERISTIC_ELEMENT_ID')
                                         );
          -- Insertion
          FWK_I_MGT_ENTITY.InsertEntity(ltDescLang);
          FWK_I_MGT_ENTITY.Release(ltDescLang);
        end loop;

        FWK_I_MGT_ENTITY.Release(ltCharElem);
      end loop;

      FWK_I_MGT_ENTITY.Release(ltChar);
    end loop;
  end pDuplicate_CHARACTERIZATION;

  procedure pDuplicate_CDA_STOCK(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltNew FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des données compl. de stock (GCO_COMPL_DATA_STOCK)
    for ltplSource in (select   GCO_COMPL_DATA_STOCK_ID
                           from GCO_COMPL_DATA_STOCK
                          where GCO_GOOD_ID = iSourceGoodID
                       order by GCO_COMPL_DATA_STOCK_ID) loop
      -- GCO_COMPL_DATA_STOCK
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataStock, ltNew);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltNew, true, ltplSource.GCO_COMPL_DATA_STOCK_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
      -- Données NON copiées
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'CDA_COMPLEMENTARY_EAN_CODE');
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
    end loop;
  end pDuplicate_CDA_STOCK;

  procedure pDuplicate_CDA_INVENTORY(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltNew           FWK_I_TYP_DEFINITION.t_crud_def;
    ldNextInventory date;
  begin
    -- Copie des données compl. d'inventaire (GCO_COMPL_DATA_INVENTORY)
    for ltplSource in (select   GCO_COMPL_DATA_INVENTORY_ID
                           from GCO_COMPL_DATA_INVENTORY
                          where GCO_GOOD_ID = iSourceGoodID
                       order by GCO_COMPL_DATA_INVENTORY_ID) loop
      -- GCO_COMPL_DATA_INVENTORY
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataInventory, ltNew);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltNew, true, ltplSource.GCO_COMPL_DATA_INVENTORY_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);

      -- Init Date du dernier inventaire et Date prochain inventaire, si pas Inventaire tournant
      if nvl(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltNew, 'CIN_TURNING_INVENTORY'), 0) = 1 then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'CIN_LAST_INVENTORY_DATE', sysdate);

        -- La date du prochain inventaire est le premier jour ouvrable depuis la date système + le décalage en jours (CIN_TURNING_INVENTORY_DELAY)
        if to_char(trunc(sysdate) + FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltNew, 'CIN_TURNING_INVENTORY_DELAY'), 'D') = 1 then
          ldNextInventory  := trunc(sysdate) + FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltNew, 'CIN_TURNING_INVENTORY_DELAY') + 1;
        elsif to_char(trunc(sysdate) + FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltNew, 'CIN_TURNING_INVENTORY_DELAY'), 'D') = 7 then
          ldNextInventory  := trunc(sysdate) + FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltNew, 'CIN_TURNING_INVENTORY_DELAY') + 2;
        else
          ldNextInventory  := trunc(sysdate) + FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltNew, 'CIN_TURNING_INVENTORY_DELAY');
        end if;

        FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'CIN_NEXT_INVENTORY_DATE', ldNextInventory);
      end if;

      -- Données NON copiées
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'CDA_COMPLEMENTARY_EAN_CODE');
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
    end loop;
  end pDuplicate_CDA_INVENTORY;

  procedure pDuplicate_CDA_PURCHASE(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltNew FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des données compl. d'achat (GCO_COMPL_DATA_PURCHASE)
    for ltplSource in (select   GCO_COMPL_DATA_PURCHASE_ID
                           from GCO_COMPL_DATA_PURCHASE
                          where GCO_GOOD_ID = iSourceGoodID
                       order by GCO_COMPL_DATA_PURCHASE_ID) loop
      -- GCO_COMPL_DATA_PURCHASE
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataPurchase, ltNew);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltNew, true, ltplSource.GCO_COMPL_DATA_PURCHASE_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
      -- Données NON copiées
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'CDA_COMPLEMENTARY_EAN_CODE');
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
    end loop;
  end pDuplicate_CDA_PURCHASE;

  procedure pDuplicate_CERTIFICATION(
    iSourceGoodID   in GCO_GOOD.GCO_GOOD_ID%type
  , iNewGoodID      in GCO_GOOD.GCO_GOOD_ID%type
  , iCertifProperty in SQM_CERTIFICATION.C_CERTIFICATION_PROPERTY%type
  )
  is
    ltNew FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des liens entre le bien et les certifications (SQM_CERTIFICATION_S_GOOD)
    for ltplSource in (select   CER.SQM_CERTIFICATION_ID
                           from SQM_CERTIFICATION_S_GOOD SCG
                              , SQM_CERTIFICATION CER
                          where SCG.GCO_GOOD_ID = iSourceGoodID
                            and SCG.SQM_CERTIFICATION_ID = CER.SQM_CERTIFICATION_ID
                            and CER.C_CERTIFICATION_PROPERTY = iCertifProperty
                       order by CER.SQM_CERTIFICATION_ID asc) loop
      -- SQM_CERTIFICATION_S_GOOD
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_SQM_ENTITY.gcSqmCertificationSGood, ltNew);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'SQM_CERTIFICATION_ID', ltplSource.SQM_CERTIFICATION_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
    end loop;
  end pDuplicate_CERTIFICATION;

  procedure pDuplicate_CDA_SALE(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltCdaSale  FWK_I_TYP_DEFINITION.t_crud_def;
    ltPackElem FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des données compl. de vente (GCO_COMPL_DATA_SALE)
    for ltplSource in (select   GCO_COMPL_DATA_SALE_ID
                           from GCO_COMPL_DATA_SALE
                          where GCO_GOOD_ID = iSourceGoodID
                       order by GCO_COMPL_DATA_SALE_ID) loop
      -- GCO_COMPL_DATA_SALE
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataSale, ltCdaSale);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltCdaSale, true, ltplSource.GCO_COMPL_DATA_SALE_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCdaSale, 'GCO_GOOD_ID', iNewGoodID);
      -- Données NON copiées
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltCdaSale, 'CDA_COMPLEMENTARY_EAN_CODE');
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltCdaSale);

      -- Copie des éléments d'emballage de la donnée compl. de vente (GCO_PACKING_ELEMENT)
      for ltplPackElem in (select   GCO_PACKING_ELEMENT_ID
                               from GCO_PACKING_ELEMENT
                              where GCO_COMPL_DATA_SALE_ID = ltplSource.GCO_COMPL_DATA_SALE_ID
                           order by SHI_SEQ asc) loop
        -- GCO_PACKING_ELEMENT liés au GCO_COMPL_DATA_SALE
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoPackingElement, ltPackElem);
        FWK_I_MGT_ENTITY.PrepareDuplicate(ltPackElem, true, ltplPackElem.GCO_PACKING_ELEMENT_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltPackElem, 'GCO_COMPL_DATA_SALE_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCdaSale, 'GCO_COMPL_DATA_SALE_ID') );
        -- Insertion
        FWK_I_MGT_ENTITY.InsertEntity(ltPackElem);
        FWK_I_MGT_ENTITY.Release(ltPackElem);
      end loop;

      FWK_I_MGT_ENTITY.Release(ltCdaSale);
    end loop;
  end pDuplicate_CDA_SALE;

  procedure pDuplicate_CDA_ASS(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltCdaAss      FWK_I_TYP_DEFINITION.t_crud_def;
    ltRetTypeGood FWK_I_TYP_DEFINITION.t_crud_def;
    lnRepTypeID   GCO_COMPL_DATA_ASS.ASA_REP_TYPE_ID%type;
  begin
    -- Copie des données compl. de SAV (GCO_COMPL_DATA_ASS)
    for ltplCdaAss in (select   GCO_COMPL_DATA_ASS_ID
                           from GCO_COMPL_DATA_ASS
                          where GCO_GOOD_ID = iSourceGoodID
                       order by GCO_COMPL_DATA_ASS_ID) loop
      -- GCO_COMPL_DATA_ASS
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataAss, ltCdaAss);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltCdaAss, true, ltplCdaAss.GCO_COMPL_DATA_ASS_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCdaAss, 'GCO_GOOD_ID', iNewGoodID);
      -- Données NON copiées
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltCdaAss, 'CDA_COMPLEMENTARY_EAN_CODE');
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltCdaAss);
      -- Récuperer l'id du type de réparation de la cda (pour utiliser dans le select ci-dessous car pas possible d'utiliser la méthode du FWK dans le select)
      lnRepTypeID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCdaAss, 'ASA_REP_TYPE_ID');

      -- Copie des données des produits à réparer (ASA_REP_TYPE_GOOD)
      for ltplRetTypeGood in (select   ASA_REP_TYPE_GOOD_ID
                                  from ASA_REP_TYPE_GOOD
                                 where GCO_GOOD_TO_REPAIR_ID = iSourceGoodID
                                   and ASA_REP_TYPE_ID = lnRepTypeID
                              order by ASA_REP_TYPE_GOOD_ID) loop
        -- ASA_REP_TYPE_GOOD
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_ASA_ENTITY.gcAsaRepTypeGood, ltRetTypeGood);
        FWK_I_MGT_ENTITY.PrepareDuplicate(ltRetTypeGood, true, ltplRetTypeGood.ASA_REP_TYPE_GOOD_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltRetTypeGood, 'GCO_GOOD_TO_REPAIR_ID', iNewGoodID);
        -- Insertion
        FWK_I_MGT_ENTITY.InsertEntity(ltRetTypeGood);
        FWK_I_MGT_ENTITY.Release(ltRetTypeGood);
      end loop;

      FWK_I_MGT_ENTITY.Release(ltCdaAss);
    end loop;
  end pDuplicate_CDA_ASS;

  procedure pDuplicate_CDA_EXTERNAL_ASA(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltCounter     FWK_I_TYP_DEFINITION.t_crud_def;
    ltCdaExtAsa   FWK_I_TYP_DEFINITION.t_crud_def;
    ltTechnicians FWK_I_TYP_DEFINITION.t_crud_def;
    ltServicePlan FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des compteurs liés au bien (ASA_COUNTER_TYPE_S_GOOD)
    for ltplCounter in (select   ASA_COUNTER_TYPE_S_GOOD_ID
                            from ASA_COUNTER_TYPE_S_GOOD
                           where GCO_GOOD_ID = iSourceGoodID
                        order by ASA_COUNTER_TYPE_S_GOOD_ID) loop
      -- ASA_COUNTER_TYPE_S_GOOD
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_ASA_ENTITY.gcAsaCounterTypeSGood, ltCounter);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltCounter, true, ltplCounter.ASA_COUNTER_TYPE_S_GOOD_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCounter, 'GCO_GOOD_ID', iNewGoodID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltCounter);
      FWK_I_MGT_ENTITY.Release(ltCounter);
    end loop;

    -- Copie des données compl. de SAV externe (GCO_COMPL_DATA_EXTERNAL_ASA)
    for ltplCdaExtAsa in (select   GCO_COMPL_DATA_EXTERNAL_ASA_ID
                              from GCO_COMPL_DATA_EXTERNAL_ASA
                             where GCO_GOOD_ID = iSourceGoodID
                          order by GCO_COMPL_DATA_EXTERNAL_ASA_ID) loop
      -- GCO_COMPL_DATA_EXTERNAL_ASA
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataExternalAsa, ltCdaExtAsa);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltCdaExtAsa, true, ltplCdaExtAsa.GCO_COMPL_DATA_EXTERNAL_ASA_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCdaExtAsa, 'GCO_GOOD_ID', iNewGoodID);
      -- Données NON copiées
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltCdaExtAsa, 'CDA_COMPLEMENTARY_EAN_CODE');
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltCdaExtAsa);

      -- Copie des groupes de techniciens (GCO_COMPL_ASA_EXT_S_HRM_JOB)
      for ltplTechnicians in (select   HRM_JOB_ID
                                  from GCO_COMPL_ASA_EXT_S_HRM_JOB
                                 where GCO_COMPL_DATA_EXTERNAL_ASA_ID = ltplCdaExtAsa.GCO_COMPL_DATA_EXTERNAL_ASA_ID
                              order by HRM_JOB_ID) loop
        -- GCO_COMPL_ASA_EXT_S_HRM_JOB
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoComplAsaExtSHrmJob, ltTechnicians);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltTechnicians
                                      , 'GCO_COMPL_DATA_EXTERNAL_ASA_ID'
                                      , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCdaExtAsa, 'GCO_COMPL_DATA_EXTERNAL_ASA_ID')
                                       );
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltTechnicians, 'HRM_JOB_ID', ltplTechnicians.HRM_JOB_ID);
        -- Insertion
        FWK_I_MGT_ENTITY.InsertEntity(ltTechnicians);
        FWK_I_MGT_ENTITY.Release(ltTechnicians);
      end loop;

      -- Copie des plans de service (GCO_SERVICE_PLAN)
      for ltplServicePlan in (select   (select CTG_TGT.ASA_COUNTER_TYPE_S_GOOD_ID
                                          from ASA_COUNTER_TYPE_S_GOOD CTG_TGT
                                         where CTG_TGT.ASA_COUNTER_TYPE_ID = CTG.ASA_COUNTER_TYPE_ID
                                           and CTG_TGT.GCO_GOOD_ID = iNewGoodID) ASA_COUNTER_TYPE_S_GOOD_ID
                                     , SER.C_ASA_SERVICE_TYPE
                                     , SER.SER_SEQ
                                     , SER.SER_COMMENT
                                     , SER.SER_COUNTER_STATE
                                     , SER.SER_CONVERSION_FACTOR
                                     , SER.SER_PERIODICITY
                                     , SER.SER_WORK_TIME
                                     , SER.C_SERVICE_PLAN_PERIODICITY
                                     , SER.DIC_SERVICE_TYPE_ID
                                     , SER.DIC_SER_UNIT_OF_MEASURE_ID
                                  from GCO_SERVICE_PLAN SER
                                     , ASA_COUNTER_TYPE_S_GOOD CTG
                                 where SER.GCO_COMPL_DATA_EXTERNAL_ASA_ID = ltplCdaExtAsa.GCO_COMPL_DATA_EXTERNAL_ASA_ID
                                   and CTG.ASA_COUNTER_TYPE_S_GOOD_ID(+) = SER.ASA_COUNTER_TYPE_S_GOOD_ID
                              order by SER.SER_SEQ) loop
        -- GCO_SERVICE_PLAN
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoServicePlan, ltServicePlan);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltServicePlan
                                      , 'GCO_COMPL_DATA_EXTERNAL_ASA_ID'
                                      , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCdaExtAsa, 'GCO_COMPL_DATA_EXTERNAL_ASA_ID')
                                       );
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltServicePlan, 'ASA_COUNTER_TYPE_S_GOOD_ID', ltplServicePlan.ASA_COUNTER_TYPE_S_GOOD_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltServicePlan, 'C_ASA_SERVICE_TYPE', ltplServicePlan.C_ASA_SERVICE_TYPE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltServicePlan, 'SER_SEQ', ltplServicePlan.SER_SEQ);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltServicePlan, 'SER_COMMENT', ltplServicePlan.SER_COMMENT);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltServicePlan, 'SER_COUNTER_STATE', ltplServicePlan.SER_COUNTER_STATE);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltServicePlan, 'SER_CONVERSION_FACTOR', ltplServicePlan.SER_CONVERSION_FACTOR);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltServicePlan, 'SER_PERIODICITY', ltplServicePlan.SER_PERIODICITY);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltServicePlan, 'SER_WORK_TIME', ltplServicePlan.SER_WORK_TIME);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltServicePlan, 'C_SERVICE_PLAN_PERIODICITY', ltplServicePlan.C_SERVICE_PLAN_PERIODICITY);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltServicePlan, 'DIC_SERVICE_TYPE_ID', ltplServicePlan.DIC_SERVICE_TYPE_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltServicePlan, 'DIC_SER_UNIT_OF_MEASURE_ID', ltplServicePlan.DIC_SER_UNIT_OF_MEASURE_ID);
        -- Insertion
        FWK_I_MGT_ENTITY.InsertEntity(ltServicePlan);
        FWK_I_MGT_ENTITY.Release(ltServicePlan);
      end loop;

      FWK_I_MGT_ENTITY.Release(ltCdaExtAsa);
    end loop;
  end pDuplicate_CDA_EXTERNAL_ASA;

  procedure pDuplicate_CDA_MANUFACTURE(
    iSourceGoodID         in     GCO_GOOD.GCO_GOOD_ID%type
  , iNewGoodID            in     GCO_GOOD.GCO_GOOD_ID%type
  , iOptions              in     GCO_LIB_CONSTANT.gtProductCopySyncOptions
  , iManufactureLinkMatch out    TLINK_MATCH
  )
  is
    ltCdaManufacture FWK_I_TYP_DEFINITION.t_crud_def;
    ltCoupledGood    FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des données compl. de fabrication (GCO_COMPL_DATA_MANUFACTURE)
    for ltplCdaManufacture in (select   GCO_COMPL_DATA_MANUFACTURE_ID
                                   from GCO_COMPL_DATA_MANUFACTURE
                                  where GCO_GOOD_ID = iSourceGoodID
                               order by GCO_COMPL_DATA_MANUFACTURE_ID) loop
      -- GCO_COMPL_DATA_MANUFACTURE
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataManufacture, ltCdaManufacture);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltCdaManufacture, true, ltplCdaManufacture.GCO_COMPL_DATA_MANUFACTURE_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCdaManufacture, 'GCO_GOOD_ID', iNewGoodID);
      -- Données NON copiées
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltCdaManufacture, 'CDA_COMPLEMENTARY_EAN_CODE');
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltCdaManufacture, 'CMA_MULTIMEDIA_PLAN');
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltCdaManufacture, 'PPS_NOMENCLATURE_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltCdaManufacture, 'PPS_RANGE_ID');
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltCdaManufacture);
      -- Ajouter les id de la CDA source et cible à une table mémoire pour les traitements de match entre (CDA Fab, Gammes et Nomenclatures)
      iManufactureLinkMatch(ltplCdaManufacture.GCO_COMPL_DATA_MANUFACTURE_ID).LINK_ID  :=
                                                                       FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCdaManufacture, 'GCO_COMPL_DATA_MANUFACTURE_ID');

      -- Copie des biens couplés demandée
      if Byte2Bool(iOptions.bGCO_COUPLED_GOOD) then
        -- Copie des biens couplés (GCO_COUPLED_GOOD)
        for ltplCoupledGood in (select   GCO_COUPLED_GOOD_ID
                                    from GCO_COUPLED_GOOD
                                   where GCO_COMPL_DATA_MANUFACTURE_ID = ltplCdaManufacture.GCO_COMPL_DATA_MANUFACTURE_ID
                                order by GCO_COUPLED_GOOD_ID) loop
          -- GCO_COUPLED_GOOD
          FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoCoupledGood, ltCoupledGood);
          FWK_I_MGT_ENTITY.PrepareDuplicate(ltCoupledGood, true, ltplCoupledGood.GCO_COUPLED_GOOD_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCoupledGood
                                        , 'GCO_COMPL_DATA_MANUFACTURE_ID'
                                        , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCdaManufacture, 'GCO_COMPL_DATA_MANUFACTURE_ID')
                                         );
          -- Insertion
          FWK_I_MGT_ENTITY.InsertEntity(ltCoupledGood);
          FWK_I_MGT_ENTITY.Release(ltCoupledGood);
        end loop;
      end if;

      FWK_I_MGT_ENTITY.Release(ltCdaManufacture);
    end loop;
  end pDuplicate_CDA_MANUFACTURE;

  procedure pDuplicate_CDA_SUBCONTRACT(
    iSourceGoodID         in     GCO_GOOD.GCO_GOOD_ID%type
  , iNewGoodID            in     GCO_GOOD.GCO_GOOD_ID%type
  , iSubcontractLinkMatch out    TLINK_MATCH
  )
  is
    ltNew FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des données compl. de Sous-traitance (GCO_COMPL_DATA_SUBCONTRACT)
    for ltplSource in (select   GCO_COMPL_DATA_SUBCONTRACT_ID
                           from GCO_COMPL_DATA_SUBCONTRACT
                          where GCO_GOOD_ID = iSourceGoodID
                       order by GCO_COMPL_DATA_SUBCONTRACT_ID) loop
      -- GCO_COMPL_DATA_SUBCONTRACT
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataSubcontract, ltNew);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltNew, true, ltplSource.GCO_COMPL_DATA_SUBCONTRACT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
      -- Données NON copiées
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'CDA_COMPLEMENTARY_EAN_CODE');
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'PPS_NOMENCLATURE_ID');
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      -- Ajouter les id de la CDA source et cible à une table mémoire pour les traitements de match entre (CDA subcontract et Nomenclatures)
      iSubcontractLinkMatch(ltplSource.GCO_COMPL_DATA_SUBCONTRACT_ID).LINK_ID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltNew, 'GCO_COMPL_DATA_SUBCONTRACT_ID');
      FWK_I_MGT_ENTITY.Release(ltNew);
    end loop;
  end pDuplicate_CDA_SUBCONTRACT;

  procedure pDuplicate_CDA_DISTRIB(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltNew FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des données compl. de distribution (GCO_COMPL_DATA_DISTRIB)
    for ltplSource in (select   GCO_COMPL_DATA_DISTRIB_ID
                           from GCO_COMPL_DATA_DISTRIB
                          where GCO_GOOD_ID = iSourceGoodID
                       order by GCO_COMPL_DATA_DISTRIB_ID) loop
      -- GCO_COMPL_DATA_DISTRIB
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataDistrib, ltNew);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltNew, true, ltplSource.GCO_COMPL_DATA_DISTRIB_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
      -- Données NON copiées
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'CDA_COMPLEMENTARY_EAN_CODE');
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
    end loop;
  end pDuplicate_CDA_DISTRIB;

  procedure pDuplicate_ATTRIBUTE(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltNew FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des attributs (GCO_GOOD_ATTRIBUTE)
    for ltplSource in (select   GCO_GOOD_ID
                           from GCO_GOOD_ATTRIBUTE
                          where GCO_GOOD_ID = iSourceGoodID
                       order by GCO_GOOD_ID) loop
      -- GCO_GOOD_ATTRIBUTE
      FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_I_TYP_GCO_ENTITY.gcGcoGoodAttribute, iot_crud_definition => ltNew, iv_primary_col => 'GCO_GOOD_ID');
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltNew, true, ltplSource.GCO_GOOD_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
    end loop;
  end pDuplicate_ATTRIBUTE;

  procedure pDuplicate_TOOLS(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltNew FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie de l'outil (PPS_TOOLS)
    for ltplSource in (select   GCO_GOOD_ID
                           from PPS_TOOLS
                          where GCO_GOOD_ID = iSourceGoodID
                       order by GCO_GOOD_ID) loop
      -- PPS_TOOLS
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_PPS_ENTITY.gcPpsTools, ltNew);
      FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_I_TYP_PPS_ENTITY.gcPpsTools, iot_crud_definition => ltNew, iv_primary_col => 'GCO_GOOD_ID');
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltNew, true, ltplSource.GCO_GOOD_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
    end loop;
  end pDuplicate_TOOLS;

  procedure pDuplicate_SPECIAL_TOOLS(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltNew FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des outils spéciaux (PPS_SPECIAL_TOOLS)
    for ltplSource in (select   PPS_SPECIAL_TOOLS_ID
                           from PPS_SPECIAL_TOOLS
                          where GCO_GOOD_ID = iSourceGoodID
                       order by PPS_SPECIAL_TOOLS_ID) loop
      -- PPS_SPECIAL_TOOLS
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_PPS_ENTITY.gcPpsSpecialTools, ltNew);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltNew, true, ltplSource.PPS_SPECIAL_TOOLS_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
      -- "Utilisation outil" à NON (pas encore utilisé)
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'SPT_USE', 0);
      -- "Solde utilisation" outil pas encore utilisé -> initialisé avec "Durée de vie"
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'SPT_BALANCE', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltNew, 'SPT_DURATION') );
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
    end loop;
  end pDuplicate_SPECIAL_TOOLS;

  procedure pDuplicate_CONNECTED_GOOD(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltNew FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des corrélations (GCO_CONNECTED_GOOD)
    for ltplSource in (select   GCO_CONNECTED_GOOD_ID
                           from GCO_CONNECTED_GOOD
                          where GCO_GOOD_ID = iSourceGoodID
                       order by GCO_CONNECTED_GOOD_ID) loop
      -- GCO_CONNECTED_GOOD
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoConnectedGood, ltNew);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltNew, true, ltplSource.GCO_CONNECTED_GOOD_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
    end loop;
  end pDuplicate_CONNECTED_GOOD;

  procedure pDuplicate_CONTRACT_DATA(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltContractData    FWK_I_TYP_DEFINITION.t_crud_def;
    ltContractObject  FWK_I_TYP_DEFINITION.t_crud_def;
    ltContractClauses FWK_I_TYP_DEFINITION.t_crud_def;
    ltLink            FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des données de contrat (GCO_CONTRACT_DATA)
    for ltplContractData in (select   GCO_CONTRACT_DATA_ID
                                 from GCO_CONTRACT_DATA
                                where GCO_GOOD_ID = iSourceGoodID
                             order by GCO_CONTRACT_DATA_ID) loop
      -- GCO_CONTRACT_DATA
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoContractData, ltContractData);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltContractData, true, ltplContractData.GCO_CONTRACT_DATA_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltContractData, 'GCO_GOOD_ID', iNewGoodID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltContractData);

      -- Copie des Objets de contrat liés au données de contrat (GCO_CONTRACT_OBJECT)
      for ltplContractObject in (select   GCO_CONTRACT_OBJECT_ID
                                     from GCO_CONTRACT_OBJECT
                                    where GCO_CONTRACT_DATA_ID = ltplContractData.GCO_CONTRACT_DATA_ID
                                 order by GCO_CONTRACT_OBJECT_ID asc) loop
        -- GCO_CONTRACT_OBJECT
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoContractObject, ltContractObject);
        FWK_I_MGT_ENTITY.PrepareDuplicate(ltContractObject, true, ltplContractObject.GCO_CONTRACT_OBJECT_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltContractObject, 'GCO_CONTRACT_DATA_ID'
                                      , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltContractData, 'GCO_CONTRACT_DATA_ID') );
        -- Insertion
        FWK_I_MGT_ENTITY.InsertEntity(ltContractObject);
        FWK_I_MGT_ENTITY.Release(ltContractObject);
      end loop;

      -- Copie des clauses de contrat liés au données de contrat (GCO_CONTRACT_CLAUSES)
      for ltplContractClauses in (select   CLA.GCO_CONTRACT_CLAUSES_ID
                                      from GCO_CONTRACT_CLAUSES CLA
                                         , GCO_DATA_CLAUSES_CONTRACT CLA_CTR
                                     where CLA_CTR.GCO_CONTRACT_DATA_ID = ltplContractData.GCO_CONTRACT_DATA_ID
                                       and CLA_CTR.GCO_CONTRACT_CLAUSES_ID = CLA.GCO_CONTRACT_CLAUSES_ID
                                  order by CLA.GCO_CONTRACT_CLAUSES_ID asc) loop
        -- GCO_CONTRACT_CLAUSES
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoContractClauses, ltContractClauses);
        FWK_I_MGT_ENTITY.PrepareDuplicate(ltContractClauses, true, ltplContractClauses.GCO_CONTRACT_CLAUSES_ID);
        -- Insertion
        FWK_I_MGT_ENTITY.InsertEntity(ltContractClauses);
        -- GCO_DATA_CLAUSES_CONTRACT
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoDataClausesContract, ltLink);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltLink, 'GCO_CONTRACT_DATA_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltContractData, 'GCO_CONTRACT_DATA_ID') );
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltLink, 'GCO_CONTRACT_CLAUSES_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltContractClauses, 'GCO_CONTRACT_CLAUSES_ID') );
        -- Insertion
        FWK_I_MGT_ENTITY.InsertEntity(ltLink);
        FWK_I_MGT_ENTITY.Release(ltLink);
        FWK_I_MGT_ENTITY.Release(ltContractClauses);
      end loop;

      FWK_I_MGT_ENTITY.Release(ltContractData);
    end loop;
  end pDuplicate_CONTRACT_DATA;

  procedure pDuplicate_RESSOURCE(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltRessource FWK_I_TYP_DEFINITION.t_crud_def;
    ltLink      FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des Ressources (GCO_RESSOURCE)
    for ltplRessource in (select   RES.GCO_RESOURCE_ID
                              from GCO_RESOURCE RES
                                 , GCO_SERVICE_RESOURCE GOO_RES
                             where GOO_RES.GCO_GOOD_ID = iSourceGoodID
                               and GOO_RES.GCO_RESOURCE_ID = RES.GCO_RESOURCE_ID
                          order by RES.GCO_RESOURCE_ID) loop
      -- GCO_RESSOURCE
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoResource, ltRessource);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltRessource, true, ltplRessource.GCO_RESOURCE_ID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltRessource);
      -- GCO_SERVICE_RESOURCE
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoServiceResource, ltLink);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltLink, 'GCO_GOOD_ID', iNewGoodID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltLink, 'GCO_RESOURCE_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltRessource, 'GCO_RESOURCE_ID') );
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltLink);
      FWK_I_MGT_ENTITY.Release(ltLink);
      FWK_I_MGT_ENTITY.Release(ltRessource);
    end loop;
  end pDuplicate_RESSOURCE;

  procedure pDuplicate_IMPUT_DOC(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltNew FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des imputations financières document (GCO_IMPUT_DOC)
    for ltplSource in (select   GCO_IMPUT_DOC_ID
                           from GCO_IMPUT_DOC
                          where GCO_GOOD_ID = iSourceGoodID
                       order by GCO_IMPUT_DOC_ID) loop
      -- GCO_IMPUT_DOC
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoImputDoc, ltNew);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltNew, true, ltplSource.GCO_IMPUT_DOC_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
    end loop;
  end pDuplicate_IMPUT_DOC;

  procedure pDuplicate_IMPUT_STOCK(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltNew FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des Imputations financières mouvements de stock (GCO_IMPUT_STOCK)
    for ltplSource in (select   GCO_IMPUT_STOCK_ID
                           from GCO_IMPUT_STOCK
                          where GCO_GOOD_ID = iSourceGoodID
                       order by GCO_IMPUT_STOCK_ID) loop
      -- GCO_IMPUT_STOCK
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoImputStock, ltNew);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltNew, true, ltplSource.GCO_IMPUT_STOCK_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
    end loop;
  end pDuplicate_IMPUT_STOCK;

  procedure pDuplicate_VAT_GOOD(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltNew FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des TVA Bien (GCO_VAT_GOOD)
    for ltplSource in (select   GCO_VAT_GOOD_ID
                           from GCO_VAT_GOOD
                          where GCO_GOOD_ID = iSourceGoodID
                       order by GCO_VAT_GOOD_ID) loop
      -- GCO_VAT_GOOD
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoVatGood, ltNew);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltNew, true, ltplSource.GCO_VAT_GOOD_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
    end loop;
  end pDuplicate_VAT_GOOD;

  procedure pDuplicate_FREE_DATA(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltNew FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des Données libres (GCO_FREE_DATA)
    for ltplSource in (select   GCO_FREE_DATA_ID
                           from GCO_FREE_DATA
                          where GCO_GOOD_ID = iSourceGoodID
                       order by GCO_FREE_DATA_ID) loop
      -- GCO_FREE_DATA
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoFreeData, ltNew);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltNew, true, ltplSource.GCO_FREE_DATA_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
    end loop;

    -- Copie des Codes libres (GCO_FREE_CODE)
    for ltplSource in (select   GCO_FREE_CODE_ID
                           from GCO_FREE_CODE
                          where GCO_GOOD_ID = iSourceGoodID
                       order by GCO_FREE_CODE_ID) loop
      -- GCO_FREE_CODE
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoFreeCode, ltNew);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltNew, true, ltplSource.GCO_FREE_CODE_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
    end loop;
  end pDuplicate_FREE_DATA;

  procedure pDuplicate_MEASUREMENT_WEIGHT(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltNew FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des Mesures et poids (GCO_MEASUREMENT_WEIGHT)
    for ltplSource in (select   GCO_MEASUREMENT_WEIGHT_ID
                           from GCO_MEASUREMENT_WEIGHT
                          where GCO_GOOD_ID = iSourceGoodID
                       order by GCO_MEASUREMENT_WEIGHT_ID) loop
      -- GCO_MEASUREMENT_WEIGHT
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoMeasurementWeight, ltNew);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltNew, true, ltplSource.GCO_MEASUREMENT_WEIGHT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
    end loop;
  end pDuplicate_MEASUREMENT_WEIGHT;

  procedure pDuplicate_MATERIAL(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltNew FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des Matières (GCO_MATERIAL)
    for ltplSource in (select   GCO_MATERIAL_ID
                           from GCO_MATERIAL
                          where GCO_GOOD_ID = iSourceGoodID
                       order by GCO_MATERIAL_ID) loop
      -- GCO_MATERIAL
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoMaterial, ltNew);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltNew, true, ltplSource.GCO_MATERIAL_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
    end loop;
  end pDuplicate_MATERIAL;

  procedure pDuplicate_CUSTOMS_ELEMENT(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltCustomsElement FWK_I_TYP_DEFINITION.t_crud_def;
    ltCustomsPermit  FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des Eléments de douane (GCO_CUSTOMS_ELEMENT)
    for ltplCustomsElement in (select GCO_CUSTOMS_ELEMENT_ID
                                 from GCO_CUSTOMS_ELEMENT
                                where GCO_GOOD_ID = iSourceGoodID) loop
      -- GCO_CUSTOMS_ELEMENT
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoCustomsElement, ltCustomsElement);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltCustomsElement, true, ltplCustomsElement.GCO_CUSTOMS_ELEMENT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCustomsElement, 'GCO_GOOD_ID', iNewGoodID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltCustomsElement);

      -- Copie des Permis douaniers (GCO_CUSTOMS_PERMIT)
      for ltplCustomsPermit in (select GCO_CUSTOMS_PERMIT_ID
                                  from GCO_CUSTOMS_PERMIT
                                 where GCO_CUSTOMS_ELEMENT_ID = ltplCustomsElement.GCO_CUSTOMS_ELEMENT_ID) loop
        -- GCO_CUSTOMS_PERMIT
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoCustomsPermit, ltCustomsPermit);
        FWK_I_MGT_ENTITY.PrepareDuplicate(ltCustomsPermit, true, ltplCustomsPermit.GCO_CUSTOMS_PERMIT_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCustomsPermit
                                      , 'GCO_CUSTOMS_ELEMENT_ID'
                                      , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCustomsElement, 'GCO_CUSTOMS_ELEMENT_ID')
                                       );
        -- Insertion
        FWK_I_MGT_ENTITY.InsertEntity(ltCustomsPermit);
        FWK_I_MGT_ENTITY.Release(ltCustomsPermit);
      end loop;

      FWK_I_MGT_ENTITY.Release(ltCustomsElement);
    end loop;
  end pDuplicate_CUSTOMS_ELEMENT;

  procedure pDuplicate_TARIFF(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltTariff      FWK_I_TYP_DEFINITION.t_crud_def;
    ltTariffTable FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_PTC_ENTITY.gcPtcTariff, ltTariff);
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_PTC_ENTITY.gcPtcTariffTable, ltTariffTable);

    -- Copie des Tarifs (PTC_TARIFF)
    for ltplTarif in (select   PTC_TARIFF_ID
                          from PTC_TARIFF
                         where GCO_GOOD_ID = iSourceGoodID
                      order by PTC_TARIFF_ID) loop
      -- PTC_TARIFF
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltTariff, true, ltplTarif.PTC_TARIFF_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltTariff, 'GCO_GOOD_ID', iNewGoodID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltTariff);

      -- Copie des Tabelles pour le tarif (PTC_TARIFF_TABLE)
      for ltplTarifTable in (select   PTC_TARIFF_TABLE_ID
                                 from PTC_TARIFF_TABLE
                                where PTC_TARIFF_ID = ltplTarif.PTC_TARIFF_ID
                             order by PTC_TARIFF_TABLE_ID asc) loop
        -- PTC_TARIFF_TABLE liés au PTC_TARIFF
        FWK_I_MGT_ENTITY.PrepareDuplicate(ltTariffTable, true, ltplTarifTable.PTC_TARIFF_TABLE_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltTariffTable, 'PTC_TARIFF_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltTariff, 'PTC_TARIFF_ID') );
        -- Insertion
        FWK_I_MGT_ENTITY.InsertEntity(ltTariffTable);
        FWK_I_MGT_ENTITY.clear(ltTariffTable);
      end loop;

      FWK_I_MGT_ENTITY.clear(ltTariff);
    end loop;

    FWK_I_MGT_ENTITY.Release(ltTariffTable);
    FWK_I_MGT_ENTITY.Release(ltTariff);
  end pDuplicate_TARIFF;

  procedure pDuplicate_CALC_COSTPRICE(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltCalcCostprice FWK_I_TYP_DEFINITION.t_crud_def;
    ltPrcStockMvt   FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des Prix de revient calculés (PTC_CALC_COSTPRICE)
    for ltplCalcCostprice in (select   PTC_CALC_COSTPRICE_ID
                                  from PTC_CALC_COSTPRICE
                                 where GCO_GOOD_ID = iSourceGoodID
                              order by PTC_CALC_COSTPRICE_ID) loop
      -- PTC_CALC_COSTPRICE
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_PTC_ENTITY.gcPtcCalcCostprice, ltCalcCostprice);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltCalcCostprice, true, ltplCalcCostprice.PTC_CALC_COSTPRICE_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCalcCostprice, 'GCO_GOOD_ID', iNewGoodID);
      -- Données NON copiées
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltCalcCostprice, 'CPR_PRICE');
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltCalcCostprice, 'CCP_ADDED_QUANTITY');
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltCalcCostprice, 'CCP_ADDED_VALUE');
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltCalcCostprice, 'CPR_HISTORY_ID');
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltCalcCostprice);

      -- Copie des liens entre les PRC et les mvts de stock (PTC_PRC_S_STOCK_MVT)
      for ltplPrcStockMvt in (select   STM_MOVEMENT_KIND_ID
                                  from PTC_PRC_S_STOCK_MVT
                                 where PTC_CALC_COSTPRICE_ID = ltplCalcCostprice.PTC_CALC_COSTPRICE_ID
                              order by STM_MOVEMENT_KIND_ID asc) loop
        -- PTC_TARIFF_TABLE liés au PTC_TARIFF
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_PTC_ENTITY.gcPtcPrcSStockMvt, ltPrcStockMvt);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltPrcStockMvt, 'STM_MOVEMENT_KIND_ID', ltplPrcStockMvt.STM_MOVEMENT_KIND_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltPrcStockMvt, 'PTC_CALC_COSTPRICE_ID'
                                      , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCalcCostprice, 'PTC_CALC_COSTPRICE_ID') );
        -- Insertion
        FWK_I_MGT_ENTITY.InsertEntity(ltPrcStockMvt);
        FWK_I_MGT_ENTITY.Release(ltPrcStockMvt);
      end loop;

      FWK_I_MGT_ENTITY.Release(ltCalcCostprice);
    end loop;
  end pDuplicate_CALC_COSTPRICE;

  procedure pDuplicate_FIXED_COSTPRICE(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltNew FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des Prix de revient fixes (PTC_FIXED_COSTPRICE)
    for ltplSource in (select   PTC_FIXED_COSTPRICE_ID
                           from PTC_FIXED_COSTPRICE
                          where GCO_GOOD_ID = iSourceGoodID
                            and PTC_RECALC_JOB_ID is null
                       order by PTC_FIXED_COSTPRICE_ID) loop
      -- PTC_FIXED_COSTPRICE
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_PTC_ENTITY.gcPtcFixedCostprice, ltNew);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltNew, true, ltplSource.PTC_FIXED_COSTPRICE_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
      -- Données NON copiées
--       FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'CPR_HISTORY_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'CPR_PRICE_BEFORE_RECALC');
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'FAL_ADV_STRUCT_CALC_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'FAL_SCHEDULE_PLAN_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'PPS_NOMENCLATURE_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GCO_COMPL_DATA_MANUFACTURE_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GCO_COMPL_DATA_PURCHASE_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'CPR_MANUFACTURE_ACCOUNTING');
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'CPR_CALCUL_DATE');
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'GCO_COMPL_DATA_SUBCONTRACT_ID');
      FWK_I_MGT_ENTITY_DATA.SetColumnDefault(ltNew, 'LOT_REFCOMPL');
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
    end loop;
  end pDuplicate_FIXED_COSTPRICE;

  procedure pDuplicate_DISCOUNT(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltNew FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des liens avec les Remises (PTC_DISCOUNT_S_GOOD)
    for ltplSource in (select   DNT.PTC_DISCOUNT_ID
                           from PTC_DISCOUNT_S_GOOD PDG
                              , PTC_DISCOUNT DNT
                          where PDG.GCO_GOOD_ID = iSourceGoodID
                            and PDG.PTC_DISCOUNT_ID = DNT.PTC_DISCOUNT_ID
                            and DNT.C_GOODRELATION_TYPE = '2'
                       order by DNT.PTC_DISCOUNT_ID) loop
      -- PTC_DISCOUNT_S_GOOD
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_PTC_ENTITY.gcPtcDiscountSGood, ltNew);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'PTC_DISCOUNT_ID', ltplSource.PTC_DISCOUNT_ID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
    end loop;
  end pDuplicate_DISCOUNT;

  procedure pDuplicate_CHARGE(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltNew FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des liens avec les Taxes (PTC_CHARGE_S_GOODS)
    for ltplSource in (select   CRG.PTC_CHARGE_ID
                           from PTC_CHARGE_S_GOODS PCG
                              , PTC_CHARGE CRG
                          where PCG.GCO_GOOD_ID = iSourceGoodID
                            and PCG.PTC_CHARGE_ID = CRG.PTC_CHARGE_ID
                            and CRG.C_GOODRELATION_TYPE = '2'
                       order by CRG.PTC_CHARGE_ID) loop
      -- PTC_CHARGE_S_GOODS
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_PTC_ENTITY.gcPtcChargeSGoods, ltNew);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'PTC_CHARGE_ID', ltplSource.PTC_CHARGE_ID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
    end loop;
  end pDuplicate_CHARGE;

  procedure pDuplicate_PRECIOUS_MAT(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltNew        FWK_I_TYP_DEFINITION.t_crud_def;
    bPreciousMat boolean;
  begin
    bPreciousMat  := false;

    -- Copie des matières précieuses (GCO_PRECIOUS_MAT)
    for ltplSource in (select   GCO_PRECIOUS_MAT_ID
                           from GCO_PRECIOUS_MAT
                          where GCO_GOOD_ID = iSourceGoodID
                       order by GCO_PRECIOUS_MAT_ID) loop
      -- GCO_PRECIOUS_MAT
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoPreciousMat, ltNew);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltNew, true, ltplSource.GCO_PRECIOUS_MAT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
      bPreciousMat  := true;
    end loop;

    if bPreciousMat then
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoGood, ltNew);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GOO_PRECIOUS_MAT', 1);
      -- Maj
      FWK_I_MGT_ENTITY.UpdateEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
    end if;
  end pDuplicate_PRECIOUS_MAT;

  procedure pDuplicate_SCHEDULE_PLAN(
    iSourceGoodID          in     GCO_GOOD.GCO_GOOD_ID%type
  , iNewGoodID             in     GCO_GOOD.GCO_GOOD_ID%type
  , iNewMajorRef           in     GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , iSchedulePlanLinkMatch out    TLINK_MATCH
  )
  is
    lstDuplicatedSchedule TLINK_MATCH;
    lvSchRef              FAL_SCHEDULE_PLAN.SCH_REF%type;   -- Varchar2(30)
    lnSchedulePlanID      FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type;
    lnIncrement           integer;
    lnExists              integer;
  begin
    lnIncrement  := 0;

    for ltplCdaManuf in (select   FAL_SCHEDULE_PLAN_ID
                                , DIC_FAB_CONDITION_ID
                                , CMA_DEFAULT
                             from GCO_COMPL_DATA_MANUFACTURE
                            where GCO_GOOD_ID = iSourceGoodID
                              and FAL_SCHEDULE_PLAN_ID is not null
                         order by CMA_DEFAULT desc
                                , DIC_FAB_CONDITION_ID asc
                                , GCO_COMPL_DATA_MANUFACTURE_ID) loop
      -- Vérifier si on a pas déjà dupliqué la gamme
      -- (on n'a pas fait un group by sur FAL_SCHEDULE_PLAN_ID car on doit effectuer un traitement particulier par rapport à la CDA par défaut)
      if not lstDuplicatedSchedule.exists(ltplCdaManuf.FAL_SCHEDULE_PLAN_ID) then
        -- Gamme par défaut - Réf Gamme = Réf Produit
        if ltplCdaManuf.CMA_DEFAULT = 1 then
          lvSchRef  := iNewMajorRef;

          -- Vérifier si la Réf Gamme exist déjà
          select sign(nvl(max(FAL_SCHEDULE_PLAN_ID), 0) )
            into lnExists
            from FAL_SCHEDULE_PLAN
           where SCH_REF = lvSchRef;
        else
          -- Autres gammes - Réf Gamme = Réf Produit + Incrément
          lnExists  := 1;
        end if;

        -- Générer une nouvelle réf gamme avec un incrément
        while lnExists = 1 loop
          lnIncrement  := lnIncrement + 1;
          -- Nouvelle réf gamme avec l'incrément et de taille max de 30 caractères (incrément y compris)
          lvSchRef     := substr(iNewMajorRef, 1, 30 - length('-' || to_char(lnIncrement) ) ) || '-' || to_char(lnIncrement);

          select sign(nvl(max(FAL_SCHEDULE_PLAN_ID), 0) )
            into lnExists
            from FAL_SCHEDULE_PLAN
           where SCH_REF = lvSchRef;
        end loop;

        -- Duplication de Gamme
        FAL_PRC_SCHEDULE_PLAN.DuplicateSchedulePlan(iSrcSchedulePlanID   => ltplCdaManuf.FAL_SCHEDULE_PLAN_ID
                                                  , iNewRef              => lvSchRef
                                                  , oNewSchedulePlanID   => lnSchedulePlanID
                                                   );
        -- Ajouter les id de la Gamme source et cible à une table mémoire pour les traitements de match entre (CDA Fab, Gammes et Nomenclatures)
        iSchedulePlanLinkMatch(ltplCdaManuf.FAL_SCHEDULE_PLAN_ID).LINK_ID  := lnSchedulePlanID;
        -- Ajouter l'id de la Gamme source dans la liste des gammes dupliquées
        lstDuplicatedSchedule(ltplCdaManuf.FAL_SCHEDULE_PLAN_ID).LINK_ID   := ltplCdaManuf.FAL_SCHEDULE_PLAN_ID;
      end if;
    end loop;
  end pDuplicate_SCHEDULE_PLAN;

  procedure pDuplicate_CONFIGURABLE_PDT(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltConfPdt FWK_I_TYP_DEFINITION.t_crud_def;
    ltPdtVar  FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie de la table du Produit configurable
    for ltplConfPdt in (select   GCO_GOOD_ID
                            from PPS_CONFIGURABLE_PRODUCT
                           where GCO_GOOD_ID = iSourceGoodID
                        order by GCO_GOOD_ID) loop
      -- PPS_CONFIGURABLE_PRODUCT
      FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_I_TYP_PPS_ENTITY.gcPpsConfigurableProduct, iot_crud_definition => ltConfPdt, iv_primary_col => 'GCO_GOOD_ID');
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltConfPdt, true, ltplConfPdt.GCO_GOOD_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltConfPdt, 'GCO_GOOD_ID', iNewGoodID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltConfPdt);
      FWK_I_MGT_ENTITY.Release(ltConfPdt);

      -- Variantes du produit configurable
      for ltplPdtVar in (select   PPS_PRODUCT_VARIANT_ID
                             from PPS_PRODUCT_VARIANT
                            where GCO_GOOD_ID = iSourceGoodID
                         order by VAR_PROD_SEQ) loop
        -- PPS_PRODUCT_VARIANT
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_PPS_ENTITY.gcPpsProductVariant, ltPdtVar);
        FWK_I_MGT_ENTITY.PrepareDuplicate(ltPdtVar, true, ltplPdtVar.PPS_PRODUCT_VARIANT_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltPdtVar, 'GCO_GOOD_ID', iNewGoodID);
        -- Insertion
        FWK_I_MGT_ENTITY.InsertEntity(ltPdtVar);
        FWK_I_MGT_ENTITY.Release(ltPdtVar);
      end loop;
    end loop;
  end pDuplicate_CONFIGURABLE_PDT;

  procedure pDuplicate_NOMENCLATURE(
    iSourceGoodID          in     GCO_GOOD.GCO_GOOD_ID%type
  , iNewGoodID             in     GCO_GOOD.GCO_GOOD_ID%type
  , iTypeNom               in     PPS_NOMENCLATURE.C_TYPE_NOM%type default null
  , iNomenclatureLinkMatch out    TLINK_MATCH
  )
  is
    ltNomenclature FWK_I_TYP_DEFINITION.t_crud_def;
    ltBond         FWK_I_TYP_DEFINITION.t_crud_def;
    ltMarkBond     FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des nomenclatures (PPS_NOMENCLATURE)
    for ltplNomenclature in (select   PPS_NOMENCLATURE_ID
                                 from PPS_NOMENCLATURE
                                where GCO_GOOD_ID = iSourceGoodID
                                  and nvl(iTypeNom, C_TYPE_NOM) = C_TYPE_NOM
                             order by C_TYPE_NOM asc
                                    , NOM_DEFAULT desc
                                    , PPS_NOMENCLATURE_ID) loop
      -- PPS_NOMENCLATURE
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_PPS_ENTITY.gcPpsNomenclature, ltNomenclature);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltNomenclature, true, ltplNomenclature.PPS_NOMENCLATURE_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNomenclature, 'GCO_GOOD_ID', iNewGoodID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNomenclature);
      -- Ajouter les id de la Nomenclature source et cible à une table mémoire pour les traitements de match entre (CDA Fab, Gammes et Nomenclatures)
      iNomenclatureLinkMatch(ltplNomenclature.PPS_NOMENCLATURE_ID).LINK_ID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltNomenclature, 'PPS_NOMENCLATURE_ID');

      -- Copie des Repères topologiques de la nomenclature (PPS_MARK_BOND)
      for ltplMarkBond in (select PPS_MARK_BOND_ID
                             from PPS_MARK_BOND
                            where PPS_NOMENCLATURE_ID = ltplNomenclature.PPS_NOMENCLATURE_ID) loop
        -- PPS_MARK_BOND liés au PPS_NOMENCLATURE
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_PPS_ENTITY.gcPpsMarkBond, ltMarkBond);
        FWK_I_MGT_ENTITY.PrepareDuplicate(ltMarkBond, true, ltplMarkBond.PPS_MARK_BOND_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltMarkBond, 'PPS_NOMENCLATURE_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltNomenclature, 'PPS_NOMENCLATURE_ID') );
        -- Insertion
        FWK_I_MGT_ENTITY.InsertEntity(ltMarkBond);
        FWK_I_MGT_ENTITY.Release(ltMarkBond);
      end loop;

      -- Copie des Composants de la nomenclature (PPS_NOM_BOND)
      for ltplBond in (select   PPS_NOM_BOND_ID
                           from PPS_NOM_BOND
                          where PPS_NOMENCLATURE_ID = ltplNomenclature.PPS_NOMENCLATURE_ID
                       order by COM_SEQ asc) loop
        -- PPS_NOM_BOND liés au PPS_NOMENCLATURE
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_PPS_ENTITY.gcPpsNomBond, ltBond);
        FWK_I_MGT_ENTITY.PrepareDuplicate(ltBond, true, ltplBond.PPS_NOM_BOND_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltBond, 'PPS_NOMENCLATURE_ID', FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltNomenclature, 'PPS_NOMENCLATURE_ID') );
        -- Insertion
        FWK_I_MGT_ENTITY.InsertEntity(ltBond);
        FWK_I_MGT_ENTITY.Release(ltBond);
      end loop;

      FWK_I_MGT_ENTITY.Release(ltNomenclature);
    end loop;
  end pDuplicate_NOMENCLATURE;

  procedure pLinkCdaSubcontract(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iSubcontractLinkMatch in TLINK_MATCH, iNomenclatureLinkMatch in TLINK_MATCH)
  is
    lnCdaSubcontractID GCO_COMPL_DATA_SUBCONTRACT.GCO_COMPL_DATA_SUBCONTRACT_ID%type;
    lnNomenclatureID   PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;
    ltCdaSubcontract   FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for ltplCdaSubcontract in (select   GCO_COMPL_DATA_SUBCONTRACT_ID
                                      , PPS_NOMENCLATURE_ID
                                   from GCO_COMPL_DATA_SUBCONTRACT
                                  where GCO_GOOD_ID = iSourceGoodID
                                    and PPS_NOMENCLATURE_ID is not null
                               order by GCO_COMPL_DATA_SUBCONTRACT_ID asc) loop
      begin
        lnCdaSubcontractID  := iSubcontractLinkMatch(ltplCdaSubcontract.GCO_COMPL_DATA_SUBCONTRACT_ID).LINK_ID;
      exception
        when others then
          lnCdaSubcontractID  := null;
      end;

      begin
        lnNomenclatureID  := iNomenclatureLinkMatch(ltplCdaSubcontract.PPS_NOMENCLATURE_ID).LINK_ID;
      exception
        when others then
          lnNomenclatureID  := null;
      end;

      -- Maj de la donnée compl. de sous-traitance du bien cible
      if     (lnCdaSubcontractID is not null)
         and (lnNomenclatureID is not null) then
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataSubcontract, ltCdaSubcontract);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCdaSubcontract, 'GCO_COMPL_DATA_SUBCONTRACT_ID', lnCdaSubcontractID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCdaSubcontract, 'PPS_NOMENCLATURE_ID', lnNomenclatureID);
        FWK_I_MGT_ENTITY.UpdateEntity(ltCdaSubcontract);
        FWK_I_MGT_ENTITY.Release(ltCdaSubcontract);
      end if;
    end loop;
  end pLinkCdaSubcontract;

  procedure pLinkCdaManufacture(
    iSourceGoodID          in GCO_GOOD.GCO_GOOD_ID%type
  , iManufactureLinkMatch  in TLINK_MATCH
  , iNomenclatureLinkMatch in TLINK_MATCH
  , iSchedulePlanLinkMatch in TLINK_MATCH
  )
  is
    lnCdaManufactureID GCO_COMPL_DATA_MANUFACTURE.GCO_COMPL_DATA_MANUFACTURE_ID%type;
    lnNomenclatureID   PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type;
    lnSchedulePlanID   FAL_SCHEDULE_PLAN.FAL_SCHEDULE_PLAN_ID%type;
    ltCdaManufacture   FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for ltplCdaManufacture in (select   GCO_COMPL_DATA_MANUFACTURE_ID
                                      , PPS_NOMENCLATURE_ID
                                      , FAL_SCHEDULE_PLAN_ID
                                   from GCO_COMPL_DATA_MANUFACTURE
                                  where GCO_GOOD_ID = iSourceGoodID
                                    and (   PPS_NOMENCLATURE_ID is not null
                                         or FAL_SCHEDULE_PLAN_ID is not null)
                               order by GCO_COMPL_DATA_MANUFACTURE_ID asc) loop
      begin
        lnCdaManufactureID  := iManufactureLinkMatch(ltplCdaManufacture.GCO_COMPL_DATA_MANUFACTURE_ID).LINK_ID;
      exception
        when others then
          lnCdaManufactureID  := null;
      end;

      begin
        if ltplCdaManufacture.PPS_NOMENCLATURE_ID is not null then
          lnNomenclatureID  := iNomenclatureLinkMatch(ltplCdaManufacture.PPS_NOMENCLATURE_ID).LINK_ID;
        else
          lnNomenclatureID  := null;
        end if;
      exception
        when others then
          lnNomenclatureID  := null;
      end;

      begin
        if ltplCdaManufacture.FAL_SCHEDULE_PLAN_ID is not null then
          lnSchedulePlanID  := iSchedulePlanLinkMatch(ltplCdaManufacture.FAL_SCHEDULE_PLAN_ID).LINK_ID;
        else
          lnSchedulePlanID  := null;
        end if;
      exception
        when others then
          lnSchedulePlanID  := null;
      end;

      -- Maj de la donnée compl. de fabrication du bien cible
      if     (lnCdaManufactureID is not null)
         and (    (lnNomenclatureID is not null)
              or (lnSchedulePlanID is not null) ) then
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataManufacture, ltCdaManufacture);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCdaManufacture, 'GCO_COMPL_DATA_MANUFACTURE_ID', lnCdaManufactureID);

        if lnNomenclatureID is not null then
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCdaManufacture, 'PPS_NOMENCLATURE_ID', lnNomenclatureID);
        end if;

        if lnSchedulePlanID is not null then
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCdaManufacture, 'FAL_SCHEDULE_PLAN_ID', lnSchedulePlanID);
        end if;

        FWK_I_MGT_ENTITY.UpdateEntity(ltCdaManufacture);
        FWK_I_MGT_ENTITY.Release(ltCdaManufacture);
      end if;
    end loop;
  end pLinkCdaManufacture;

  procedure pDuplicateCMLService(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    lvKind GCO_GOOD.C_SERVICE_KIND%type;
    lvLink GCO_GOOD.C_SERVICE_GOOD_LINK%type;
    ltNew  FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    select nvl(C_SERVICE_KIND, 0)
         , nvl(C_SERVICE_GOOD_LINK, 0)
      into lvKind
         , lvLink
      from GCO_GOOD
     where GCO_GOOD_ID = iSourceGoodID;

    -- Droit de consommation compteur
    if lvKind = '1' then
      for ltplSource in (select   ASA_COUNTER_TYPE_ID
                             from GCO_SERVICE_COUNTER_LINK
                            where GCO_SERVICE_ID = iSourceGoodID
                         order by ASA_COUNTER_TYPE_ID) loop
        -- GCO_SERVICE_COUNTER_LINK
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoServiceCounterLink, ltNew);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_SERVICE_ID', iNewGoodID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'ASA_COUNTER_TYPE_ID', ltplSource.ASA_COUNTER_TYPE_ID);
        -- Insertion
        FWK_I_MGT_ENTITY.InsertEntity(ltNew);
        FWK_I_MGT_ENTITY.Release(ltNew);
      end loop;
    -- Droit de consommation ou tarif préférentiel avec sélection manuelle des biens liés
    elsif     (   lvKind = '2'
               or lvKind = '3')
          and (lvLink = '1') then
      for ltplSource in (select   GCO_GOOD_ID
                             from GCO_SERVICE_GOOD_LINK
                            where GCO_SERVICE_ID = iSourceGoodID
                         order by GCO_GOOD_ID) loop
        -- GCO_SERVICE_GOOD_LINK
        FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoServiceGoodLink, ltNew);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_SERVICE_ID', iNewGoodID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', ltplSource.GCO_GOOD_ID);
        -- Insertion
        FWK_I_MGT_ENTITY.InsertEntity(ltNew);
        FWK_I_MGT_ENTITY.Release(ltNew);
      end loop;
    end if;
  end pDuplicateCMLService;

  procedure pDuplicate_EQUIVALENCE_GOOD(iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type, iNewGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    ltNew FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Copie des Produits équivalents (GCO_EQUIVALENCE_GOOD)
    for ltplSource in (select GCO_EQUIVALENCE_GOOD_ID
                         from GCO_EQUIVALENCE_GOOD
                        where GCO_GOOD_ID = iSourceGoodID) loop
      -- GCO_EQUIVALENCE_GOOD
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoEquivalenceGood, ltNew);
      FWK_I_MGT_ENTITY.PrepareDuplicate(ltNew, true, ltplSource.GCO_EQUIVALENCE_GOOD_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
      -- Insertion
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
      FWK_I_MGT_ENTITY.Release(ltNew);
    end loop;
  end pDuplicate_EQUIVALENCE_GOOD;

  procedure pGenerate_GOOD_EAN(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    lvEANCode varchar2(40);
    ltGood    FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    lvEANCode  := GCO_EAN.EAN_Gen(0, iGoodID);
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoGood, ltGood);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGood, 'GOO_EAN_CODE', lvEANCode);
    FWK_I_MGT_ENTITY.UpdateEntity(ltGood);
    FWK_I_MGT_ENTITY.Release(ltGood);
  end pGenerate_GOOD_EAN;

  procedure pGenerate_CDA_PURCHASE_EAN(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    lvEANCode varchar2(40);
    ltCda     FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    lvEANCode  := GCO_EAN.EAN_Gen(0, iGoodID);

    for ltplCda in (select   GCO_COMPL_DATA_PURCHASE_ID
                        from GCO_COMPL_DATA_PURCHASE
                       where GCO_GOOD_ID = iGoodID
                    order by GCO_COMPL_DATA_PURCHASE_ID asc) loop
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataPurchase, ltCda);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCda, 'GCO_COMPL_DATA_PURCHASE_ID', ltplCda.GCO_COMPL_DATA_PURCHASE_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCda, 'CDA_COMPLEMENTARY_EAN_CODE', lvEANCode);
      FWK_I_MGT_ENTITY.UpdateEntity(ltCda);
      FWK_I_MGT_ENTITY.Release(ltCda);
    end loop;
  end pGenerate_CDA_PURCHASE_EAN;

  procedure pGenerate_CDA_SALE_EAN(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    lvEANCode varchar2(40);
    ltCda     FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    lvEANCode  := GCO_EAN.EAN_Gen(0, iGoodID);

    for ltplCda in (select   GCO_COMPL_DATA_SALE_ID
                        from GCO_COMPL_DATA_SALE
                       where GCO_GOOD_ID = iGoodID
                    order by GCO_COMPL_DATA_SALE_ID asc) loop
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataSale, ltCda);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCda, 'GCO_COMPL_DATA_SALE_ID', ltplCda.GCO_COMPL_DATA_SALE_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCda, 'CDA_COMPLEMENTARY_EAN_CODE', lvEANCode);
      FWK_I_MGT_ENTITY.UpdateEntity(ltCda);
      FWK_I_MGT_ENTITY.Release(ltCda);
    end loop;
  end pGenerate_CDA_SALE_EAN;

  /**
  * procedure DuplicateProduct
  * Description
  *   Duplication d'un produit
  */
  procedure DuplicateProduct(
    iSourceGoodID       in     GCO_GOOD.GCO_GOOD_ID%type
  , iNewGoodID          in out GCO_GOOD.GCO_GOOD_ID%type
  , iNewMajorRef        in     GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , iNewSecRef          in     GCO_GOOD.GOO_SECONDARY_REFERENCE%type
  , iNewShortDescr      in     GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type default null
  , iNewLongDescr       in     GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type default null
  , iNewFreeDescr       in     GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type default null
  , iActiveGoodStatus   in     number default 1
  , iPdtGenerator       in     number default 0
  , iRelationTypeID     in     GCO_GOOD_LINK.DIC_RELATION_TYPE_ID%type default null
  , iFreeText           in     GCO_GOOD_LINK.GLI_FREE_TEXT%type default null
  , iDuplStock          in     number default 0
  , iDuplInventory      in     number default 0
  , iDuplPurchase       in     number default 0
  , iDuplSale           in     number default 0
  , iDuplSAV            in     number default 0
  , iDuplExternalASA    in     number default 0
  , iDuplManufacture    in     number default 0
  , iDuplSubcontract    in     number default 0
  , iDuplAttributes     in     number default 0
  , iDuplDistribution   in     number default 0
  , iDuplTool           in     number default 0
  , iDuplNomenclature   in     number default 0
  , iDuplSchedulePlan   in     number default 0
  , iDuplCoupledGoods   in     number default 0
  , iDuplCertifications in     number default 0
  , iDuplPRF            in     number default 0
  , iDuplPRC            in     number default 0
  , iDuplTariff         in     number default 0
  , iDuplDiscount       in     number default 0
  , iDuplCharge         in     number default 0
  , iDuplFreeData       in     number default 0
  , iDuplVirtualFields  in     number default 0
  , iDuplPreciousMat    in     number default 0
  , iDuplSpecialTools   in     number default 0
  , iDuplCorrelation    in     number default 0
  )
  is
    ltOptions GCO_LIB_CONSTANT.gtProductCopySyncOptions;
  begin
    ltOptions.bFAL_SCHEDULE_PLAN            := iDuplSchedulePlan;
    ltOptions.bFREE_DATA                    := iDuplFreeData;
    ltOptions.bGCO_COMPL_DATA_ASS           := iDuplSAV;
    ltOptions.bGCO_COMPL_DATA_DISTRIB       := iDuplDistribution;
    ltOptions.bGCO_COMPL_DATA_EXTERNAL_ASA  := iDuplExternalASA;
    ltOptions.bGCO_COMPL_DATA_INVENTORY     := iDuplInventory;
    ltOptions.bGCO_COMPL_DATA_MANUFACTURE   := iDuplManufacture;
    ltOptions.bGCO_COMPL_DATA_PURCHASE      := iDuplPurchase;
    ltOptions.bGCO_COMPL_DATA_SALE          := iDuplSale;
    ltOptions.bGCO_COMPL_DATA_STOCK         := iDuplStock;
    ltOptions.bGCO_COMPL_DATA_SUBCONTRACT   := iDuplSubcontract;
    ltOptions.bGCO_CONNECTED_GOOD           := iDuplCorrelation;
    ltOptions.bGCO_COUPLED_GOOD             := iDuplCoupledGoods;
    ltOptions.bGCO_GOOD_ATTRIBUTE           := iDuplAttributes;
    ltOptions.bGCO_PRECIOUS_MAT             := iDuplPreciousMat;
    ltOptions.bPPS_NOMENCLATURE             := iDuplNomenclature;
    ltOptions.bPPS_SPECIAL_TOOLS            := iDuplSpecialTools;
    ltOptions.bPPS_TOOLS                    := iDuplTool;
    ltOptions.bPTC_CALC_COSTPRICE           := iDuplPRC;
    ltOptions.bPTC_CHARGE                   := iDuplCharge;
    ltOptions.bPTC_DISCOUNT                 := iDuplDiscount;
    ltOptions.bPTC_FIXED_COSTPRICE          := iDuplPRF;
    ltOptions.bPTC_TARIFF                   := iDuplTariff;
    ltOptions.bSQM_CERTIFICATION            := iDuplCertifications;
    ltOptions.bVIRTUAL_FIELDS               := iDuplVirtualFields;
    -- Duplication du produit
    DuplicateProduct(iSourceGoodID       => iSourceGoodID
                   , iOptions            => ltOptions
                   , iNewGoodID          => iNewGoodID
                   , iNewMajorRef        => iNewMajorRef
                   , iNewSecRef          => iNewSecRef
                   , iNewShortDescr      => iNewShortDescr
                   , iNewLongDescr       => iNewLongDescr
                   , iNewFreeDescr       => iNewFreeDescr
                   , iActiveGoodStatus   => iActiveGoodStatus
                   , iPdtGenerator       => iPdtGenerator
                   , iRelationTypeID     => iRelationTypeID
                   , iFreeText           => iFreeText
                    );
  end DuplicateProduct;

  /**
  * procedure DuplicateProduct
  * Description
  *   Duplication d'un produit
  */
  procedure DuplicateProduct(
    iSourceGoodID     in     GCO_GOOD.GCO_GOOD_ID%type
  , iDuplicateOptions in     clob
  , iNewGoodID        in out GCO_GOOD.GCO_GOOD_ID%type
  , iNewMajorRef      in     GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , iNewSecRef        in     GCO_GOOD.GOO_SECONDARY_REFERENCE%type
  , iNewShortDescr    in     GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type default null
  , iNewLongDescr     in     GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type default null
  , iNewFreeDescr     in     GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type default null
  , iActiveGoodStatus in     number default 1
  , iPdtGenerator     in     number default 0
  , iRelationTypeID   in     GCO_GOOD_LINK.DIC_RELATION_TYPE_ID%type default null
  , iFreeText         in     GCO_GOOD_LINK.GLI_FREE_TEXT%type default null
  )
  is
    ltOptions GCO_LIB_CONSTANT.gtProductCopySyncOptions;
  begin
    -- Charge les options de copie/synchronisation d'un produit dans le type record correspondant
    ltOptions  := GCO_LIB_FUNCTIONS.loadProductCopySyncOptions(iDuplicateOptions);
    -- Duplication du produit
    DuplicateProduct(iSourceGoodID       => iSourceGoodID
                   , iOptions            => ltOptions
                   , iNewGoodID          => iNewGoodID
                   , iNewMajorRef        => iNewMajorRef
                   , iNewSecRef          => iNewSecRef
                   , iNewShortDescr      => iNewShortDescr
                   , iNewLongDescr       => iNewLongDescr
                   , iNewFreeDescr       => iNewFreeDescr
                   , iActiveGoodStatus   => iActiveGoodStatus
                   , iPdtGenerator       => iPdtGenerator
                   , iRelationTypeID     => iRelationTypeID
                   , iFreeText           => iFreeText
                    );
  end DuplicateProduct;

  /**
  * procedure DuplicateProduct
  * Description
  *   Duplication d'un produit
  */
  procedure DuplicateProduct(
    iSourceGoodID     in     GCO_GOOD.GCO_GOOD_ID%type
  , iOptions          in     GCO_LIB_CONSTANT.gtProductCopySyncOptions
  , iNewGoodID        in out GCO_GOOD.GCO_GOOD_ID%type
  , iNewMajorRef      in     GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , iNewSecRef        in     GCO_GOOD.GOO_SECONDARY_REFERENCE%type
  , iNewShortDescr    in     GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type default null
  , iNewLongDescr     in     GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type default null
  , iNewFreeDescr     in     GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type default null
  , iActiveGoodStatus in     number default 1
  , iPdtGenerator     in     number default 0
  , iRelationTypeID   in     GCO_GOOD_LINK.DIC_RELATION_TYPE_ID%type default null
  , iFreeText         in     GCO_GOOD_LINK.GLI_FREE_TEXT%type default null
  )
  is
    lvEANError             varchar2(3);
    lvHIBC                 GCO_GOOD.GOO_HIBC_PRIMARY_CODE%type;
    lSubcontractLinkMatch  TLINK_MATCH;
    lManufactureLinkMatch  TLINK_MATCH;
    lNomenclatureLinkMatch TLINK_MATCH;
    lSchedulePlanLinkMatch TLINK_MATCH;
    lNewMajorRef           GCO_GOOD.GOO_MAJOR_REFERENCE%type;
  begin
    --  1. Duplication des données de la table GCO_GOOD
    --  2. Duplication des données de la table GCO_PRODUCT
    --  3. Duplication des descriptions
    --  4. Duplication des caractérisations
    --  5. Duplication des données complémentaires de stock
    --  6. Duplication des données complémentaires d'inventaire
    --  7. Duplication des données complémentaires d'achat
    --    7.1 Duplication des liens d'homologation achat
    --  8. Duplication des données complémentaires de vente
    --  9. Duplication des données complémentaires du SAV
    -- 10. Duplication des données complémentaires du SAV externe
    -- 11. Duplication des données complémentaires de fabrication
    --   11.1 Duplication des produits couplés
    --   11.2 Duplication des liens d'homologation
    -- 12. Duplication des données complémentaires de Sous-Traitance
    -- 13. Duplication des données complémentaires de disribution
    -- 14. Duplication des données complémentaires des attributs
    -- 15. Duplication des données de l'outil
    --   15.1 Duplication des outils spéciaux
    -- 16. Duplication des corrélations
    -- 17. Duplication de l'imputation comptable Document
    -- 18. Duplication de l'imputation comptable Stock
    -- 19. Duplication des Taxes et TVA
    -- 20. Duplication des Données libres
    -- 21. Duplication des Mesures et poids
    -- 22. Duplication des Matières
    -- 23. Duplication des Elements de douane
    -- 24. Duplication des Tarifs
    -- 25. Duplication des PRC
    -- 26. Duplication des PRF
    -- 27. Duplication des Remises
    -- 28. Duplication des Taxes
    -- 29. Duplication des champs virtuels
    -- 30. Duplication des Matières précieuses
    -- 31. Duplication des gammes
    -- 32. Duplication des Nomenclatures
    -- 33. Génération des codes EAN
    -- 34. Produit équivalent

    -- Recherche l'ID du nouveau bien s'il n'as pas été passé en paramètre
    if nvl(iNewGoodID, 0) = 0 then
      iNewGoodID  := INIT_ID_SEQ.nextval;
    end if;

    --  1. Duplication des données de la table GCO_GOOD
    pDuplicate_GOOD(iSourceGoodID       => iSourceGoodID
                  , iNewGoodID          => iNewGoodID
                  , iNewMajorRef        => iNewMajorRef
                  , iNewSecRef          => iNewSecRef
                  , iActiveGoodStatus   => iActiveGoodStatus
                  , iOptions            => iOptions
                  , iRelationTypeID     => iRelationTypeID
                  , iFreeText           => iFreeText
                   );

    select GOO_MAJOR_REFERENCE
      into lNewMajorRef
      from GCO_GOOD
     where GCO_GOOD_ID = iNewGoodID;

    lNewMajorRef  := nvl(lNewMajorRef, iNewMajorRef);
    --  2. Duplication des données de la table GCO_PRODUCT
    pDuplicate_PRODUCT(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    --  3. Duplication des descriptions
    pDuplicate_DESCRIPTION(iSourceGoodID    => iSourceGoodID
                         , iNewGoodID       => iNewGoodID
                         , iNewShortDescr   => iNewShortDescr
                         , iNewLongDescr    => iNewLongDescr
                         , iNewFreeDescr    => iNewFreeDescr
                          );
    --  4. Duplication des caractérisations
    pDuplicate_CHARACTERIZATION(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);

    -- 5. Duplication des données complémentaires de stock
    if Byte2Bool(iOptions.bGCO_COMPL_DATA_STOCK) then
      pDuplicate_CDA_STOCK(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    end if;

    -- 6. Duplication des données complémentaires d'inventaire
    if Byte2Bool(iOptions.bGCO_COMPL_DATA_INVENTORY) then
      pDuplicate_CDA_INVENTORY(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    end if;

    -- 7. Duplication des données complémentaires d'achat
    if Byte2Bool(iOptions.bGCO_COMPL_DATA_PURCHASE) then
      pDuplicate_CDA_PURCHASE(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);

      -- 7.1 Duplication des liens d'homologation achat
      if Byte2Bool(iOptions.bSQM_CERTIFICATION) then
        pDuplicate_CERTIFICATION(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID, iCertifProperty => '1');
      end if;
    end if;

    -- 8. Duplication des données complémentaires de vente
    if Byte2Bool(iOptions.bGCO_COMPL_DATA_SALE) then
      pDuplicate_CDA_SALE(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    end if;

    -- 9. Duplication des données complémentaires du SAV
    if Byte2Bool(iOptions.bGCO_COMPL_DATA_ASS) then
      pDuplicate_CDA_ASS(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    end if;

    -- 10. Duplication des données complémentaires du SAV externe
    if Byte2Bool(iOptions.bGCO_COMPL_DATA_EXTERNAL_ASA) then
      pDuplicate_CDA_EXTERNAL_ASA(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    end if;

    -- 11. Duplication des données complémentaires de fabrication
    if Byte2Bool(iOptions.bGCO_COMPL_DATA_MANUFACTURE) then
      -- 11. Duplication des données complémentaires de fabrication
      -- 11.1 Duplication des produits couplés
      pDuplicate_CDA_MANUFACTURE(iSourceGoodID           => iSourceGoodID, iNewGoodID => iNewGoodID, iOptions => iOptions
                               , iManufactureLinkMatch   => lManufactureLinkMatch);

      -- 11.2 Duplication des liens d'homologation fabrication
      if Byte2Bool(iOptions.bSQM_CERTIFICATION) then
        pDuplicate_CERTIFICATION(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID, iCertifProperty => '0');
      end if;
    end if;

    -- 12. Duplication des données complémentaires de Sous-Traitance
    if Byte2Bool(iOptions.bGCO_COMPL_DATA_SUBCONTRACT) then
      pDuplicate_CDA_SUBCONTRACT(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID, iSubcontractLinkMatch => lSubcontractLinkMatch);
    end if;

    -- 13. Duplication des données complémentaires de disribution
    if Byte2Bool(iOptions.bGCO_COMPL_DATA_DISTRIB) then
      pDuplicate_CDA_DISTRIB(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    end if;

    -- 14. Duplication des données complémentaires des attributs
    if Byte2Bool(iOptions.bGCO_GOOD_ATTRIBUTE) then
      pDuplicate_ATTRIBUTE(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    end if;

    -- 15. Duplication des données de l'outil
    if Byte2Bool(iOptions.bPPS_TOOLS) then
      pDuplicate_TOOLS(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);

      -- 15.1 Duplication des Outils spéciaux
      if Byte2Bool(iOptions.bPPS_SPECIAL_TOOLS) then
        pDuplicate_SPECIAL_TOOLS(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
      end if;
    end if;

    -- 16. Duplication des corrélations
    if Byte2Bool(iOptions.bGCO_CONNECTED_GOOD) then
      pDuplicate_CONNECTED_GOOD(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    end if;

    -- 17. Duplication de l'imputation comptable Document
    pDuplicate_IMPUT_DOC(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    -- 18. Duplication de l'imputation comptable Stock
    pDuplicate_IMPUT_STOCK(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    -- 19. Duplication des Taxes et TVA
    pDuplicate_VAT_GOOD(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);

    -- 20. Duplication des Données libres
    if Byte2Bool(iOptions.bFREE_DATA) then
      pDuplicate_FREE_DATA(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    end if;

    -- 21. Duplication des Mesures et poids
    pDuplicate_MEASUREMENT_WEIGHT(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    -- 22. Duplication des Matières
    pDuplicate_MATERIAL(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    -- 23. Duplication des Elements de douane
    pDuplicate_CUSTOMS_ELEMENT(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);

    -- 24. Duplication des Tarifs
    if Byte2Bool(iOptions.bPTC_TARIFF) then
      pDuplicate_TARIFF(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    end if;

    -- 25. Duplication des PRC
    if Byte2Bool(iOptions.bPTC_CALC_COSTPRICE) then
      pDuplicate_CALC_COSTPRICE(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    end if;

    -- 26. Duplication des PRF
    if Byte2Bool(iOptions.bPTC_FIXED_COSTPRICE) then
      pDuplicate_FIXED_COSTPRICE(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    end if;

    -- 27. Duplication des Remises
    if Byte2Bool(iOptions.bPTC_DISCOUNT) then
      pDuplicate_DISCOUNT(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    end if;

    -- 28. Duplication des Taxes
    if Byte2Bool(iOptions.bPTC_CHARGE) then
      pDuplicate_CHARGE(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    end if;

    -- 29. Duplication des champs virtuels
    if Byte2Bool(iOptions.bVIRTUAL_FIELDS) then
      COM_VFIELDS.DuplicateVirtualField(aTableName => 'GCO_GOOD', aFieldName => null, aIDRecordSource => iSourceGoodID, aIDRecordTarget => iNewGoodID);
    end if;

    -- 30. Duplication des matières précieuses
    if Byte2Bool(iOptions.bGCO_PRECIOUS_MAT) then
      pDuplicate_PRECIOUS_MAT(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    end if;

    -- 31. Duplication des gammes
    if Byte2Bool(iOptions.bFAL_SCHEDULE_PLAN) then
      pDuplicate_SCHEDULE_PLAN(iSourceGoodID            => iSourceGoodID
                             , iNewGoodID               => iNewGoodID
                             , iNewMajorRef             => lNewMajorRef
                             , iSchedulePlanLinkMatch   => lSchedulePlanLinkMatch
                              );
    end if;

    -- 32. Duplication des Nomenclatures
    if Byte2Bool(iOptions.bPPS_NOMENCLATURE) then
      -- Produits configurés (c'est obligatoire si le produit source possède une nomenclature de vente)
      pDuplicate_CONFIGURABLE_PDT(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
      pDuplicate_NOMENCLATURE(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID, iNomenclatureLinkMatch => lNomenclatureLinkMatch);
    end if;

    -- Si copie des des données compl. de sous-traitance et nomenclatures, effectuer les liens entre elles
    if     Byte2Bool(iOptions.bGCO_COMPL_DATA_SUBCONTRACT)
       and Byte2Bool(iOptions.bPPS_NOMENCLATURE) then
      pLinkCdaSubcontract(iSourceGoodID => iSourceGoodID, iSubcontractLinkMatch => lSubcontractLinkMatch, iNomenclatureLinkMatch => lNomenclatureLinkMatch);
    end if;

    -- Si copie des des données compl. de fabrication et (nomenclatures et/ou gammes), effectuer les liens entre elles
    if     Byte2Bool(iOptions.bGCO_COMPL_DATA_MANUFACTURE)
       and (   Byte2Bool(iOptions.bFAL_SCHEDULE_PLAN)
            or Byte2Bool(iOptions.bPPS_NOMENCLATURE) ) then
      pLinkCdaManufacture(iSourceGoodID            => iSourceGoodID
                        , iManufactureLinkMatch    => lManufactureLinkMatch
                        , iNomenclatureLinkMatch   => lNomenclatureLinkMatch
                        , iSchedulePlanLinkMatch   => lSchedulePlanLinkMatch
                         );
    end if;

    -- 33. Génération des codes EAN/UCC14 et HIBC
    GCO_BARCODE_FUNCTIONS.GenerateEAN_UCC14(paDomain => 0, paGoodId => iNewGoodID, paComplDataId => 0, paError => lvEANError);
    GCO_BARCODE_FUNCTIONS.GenerateAllEAN(paGoodId => iNewGoodID);
    GCO_BARCODE_FUNCTIONS.GenerateHIBC(paGoodId => iNewGoodID, paHIBC => lvHIBC, paError => lvEANError);
    -- 34. Produit équivalent
    pDuplicate_EQUIVALENCE_GOOD(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
  --
  -- Génération de la Réf. du bien si en Réf. automatique (effectué par le GCO_MGT_GOOD.insertGOOD)
  --
  end DuplicateProduct;

  /**
  * procedure CreateGoodLink
  * Description
  *   Création du lien (GCO_GOOD_LINK) entre 2 biens lors de la duplication ou la synchronisation
  */
  procedure CreateGoodLink(
    iLinkType       in GCO_GOOD_LINK.C_GOOD_LINK_TYPE%type
  , iSourceGoodID   in GCO_GOOD_LINK.GCO_GOOD_SOURCE_ID%type
  , iTargetGoodID   in GCO_GOOD_LINK.GCO_GOOD_TARGET_ID%type
  , iRelationTypeID in GCO_GOOD_LINK.DIC_RELATION_TYPE_ID%type default null
  , iFreeText       in GCO_GOOD_LINK.GLI_FREE_TEXT%type default null
  , iOptions        in clob default null
  )
  is
    ltNew        FWK_I_TYP_DEFINITION.t_crud_def;
    lnGoodLinkID GCO_GOOD_LINK.GCO_GOOD_LINK_ID%type;
  begin
    -- Attention, lors de la synchronisation, il est possible qu'un lien existe déjà entre les deux biens si ce n'est pas la première
    -- synchronisation. Dans ce cas, on détermine si le lien de synchronisation existe déjà
    begin
      select GLI.GCO_GOOD_LINK_ID
        into lnGoodLinkID
        from GCO_GOOD_LINK GLI
       where GLI.C_GOOD_LINK_TYPE = iLinkType
         and GLI.GCO_GOOD_SOURCE_ID = iSourceGoodID
         and GLI.GCO_GOOD_TARGET_ID = iTargetGoodID;
    exception
      when no_data_found then
        lnGoodLinkID  := null;
    end;

    FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoGoodLink, ltNew);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'C_GOOD_LINK_TYPE', iLinkType);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_SOURCE_ID', iSourceGoodID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_TARGET_ID', iTargetGoodID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'DIC_RELATION_TYPE_ID', iRelationTypeID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GLI_FREE_TEXT', iFreeText);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GLI_OPTIONS', iOptions);

    if lnGoodLinkID is null then
      FWK_I_MGT_ENTITY.InsertEntity(ltNew);
    else
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_LINK_ID', lnGoodLinkID);
      FWK_I_MGT_ENTITY.UpdateEntity(ltNew);
    end if;

    FWK_I_MGT_ENTITY.Release(ltNew);
  end CreateGoodLink;

  /**
  * procedure DuplicateService
  * Description
  *   Méthode générale pour la duplication d'un service
  */
  procedure DuplicateService(
    iSourceGoodID      in     GCO_GOOD.GCO_GOOD_ID%type
  , iNewGoodID         in out GCO_GOOD.GCO_GOOD_ID%type
  , iNewMajorRef       in     GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , iNewSecRef         in     GCO_GOOD.GOO_SECONDARY_REFERENCE%type
  , iDuplPurchase      in     number default 0
  , iDuplSale          in     number default 0
  , iDuplCML           in     number default 0
  , iDuplPRF           in     number default 0
  , iDuplTariff        in     number default 0
  , iDuplFreeData      in     number default 0
  , iDuplVirtualFields in     number default 0
  , iDuplPreciousMat   in     number default 0
  )
  is
    lnActiveGoodStatus integer;
    ltNew              FWK_I_TYP_DEFINITION.t_crud_def;
    lvEANCode          varchar2(40);
    lOptions           GCO_LIB_CONSTANT.gtProductCopySyncOptions;
  begin
    -- Définir si le service doit être crée avec le statut actif
    if nvl(PCS.PC_CONFIG.GETCONFIG('GCO_INACTIVE_CREATION_GOOD'), '0') = '0' then
      lnActiveGoodStatus  := 1;
    else
      lnActiveGoodStatus  := 0;
    end if;

    -- Recherche l'ID du nouveau bien s'il n'as pas été passé en paramètre
    if nvl(iNewGoodID, 0) = 0 then
      iNewGoodID  := INIT_ID_SEQ.nextval;
    end if;

    -- Init du record contenant les options des éléments à copier avec les params entrants
    lOptions.bGCO_COMPL_DATA_PURCHASE  := iDuplPurchase;
    lOptions.bGCO_COMPL_DATA_SALE      := iDuplSale;
    lOptions.bPTC_FIXED_COSTPRICE      := iDuplPRF;
    lOptions.bPTC_TARIFF               := iDuplTariff;
    lOptions.bFREE_DATA                := iDuplFreeData;
    lOptions.bVIRTUAL_FIELDS           := iDuplVirtualFields;
    lOptions.bGCO_PRECIOUS_MAT         := iDuplPreciousMat;
    --  1. Duplication des données de la table GCO_GOOD
    --  2. Insertion dans la table GCO_SERVICE
    --  3. Duplication des Taxes et TVA
    --  4. Duplication des Données libres
    --  5. Duplication des données complémentaires d'achat
    --  6. Duplication des données complémentaires de vente
    --  7. Duplication des descriptions
    --  8. Duplication des corrélations
    --  9. Duplication des contrats
    -- 10. Duplication des ressources
    -- 11. Duplication de l'imputation comptable Document
    -- 12. Duplication des PRF
    -- 13. Duplication des Tarifs
    -- 14. Duplication des champs virtuels
    -- 15. Génération du code EAN du bien
    -- 16. Génération du code EAN pour les données compl. d'achat
    -- 17. Génération du code EAN pour les données compl. de vente
    -- 18. Duplication des matières précieuses
    -- 19. Duplication des données de prestation

    --  1. Duplication des données de la table GCO_GOOD xxxxxxxxxxxxxxxxxx
    pDuplicate_GOOD(iSourceGoodID       => iSourceGoodID
                  , iNewGoodID          => iNewGoodID
                  , iNewMajorRef        => iNewMajorRef
                  , iNewSecRef          => iNewSecRef
                  , iActiveGoodStatus   => lnActiveGoodStatus
                  , iDuplCML            => iDuplCML
                  , iOptions            => lOptions
                   );
    -- 2. Insertion dans la table GCO_SERVICE
    FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_I_TYP_GCO_ENTITY.gcGcoService, iot_crud_definition => ltNew, iv_primary_col => 'GCO_GOOD_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
    FWK_I_MGT_ENTITY.InsertEntity(ltNew);
    FWK_I_MGT_ENTITY.Release(ltNew);
    --  3. Duplication des Taxes et TVA
    pDuplicate_VAT_GOOD(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);

    --  4. Duplication des Données libres
    if iDuplFreeData = 1 then
      pDuplicate_FREE_DATA(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    end if;

    --  5. Duplication des données complémentaires d'achat
    if iDuplPurchase = 1 then
      pDuplicate_CDA_PURCHASE(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    end if;

    --  6. Duplication des données complémentaires de vente
    if iDuplSale = 1 then
      pDuplicate_CDA_SALE(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    end if;

    --  7. Duplication des descriptions
    pDuplicate_DESCRIPTION(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    --  8. Duplication des corrélations
    pDuplicate_CONNECTED_GOOD(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    --  9. Duplication des contrats
    pDuplicate_CONTRACT_DATA(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    -- 10. Duplication des ressources
    pDuplicate_RESSOURCE(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    -- 11. Duplication de l'imputation comptable Document
    pDuplicate_IMPUT_DOC(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);

    -- 12. Duplication des PRF
    if iDuplPRF = 1 then
      pDuplicate_FIXED_COSTPRICE(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    end if;

    -- 13. Duplication des Tarifs
    if iDuplTariff = 1 then
      pDuplicate_TARIFF(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    end if;

    -- 14. Duplication des champs virtuels
    if iDuplVirtualFields = 1 then
      COM_VFIELDS.DuplicateVirtualField(aTableName => 'GCO_GOOD', aFieldName => null, aIDRecordSource => iSourceGoodID, aIDRecordTarget => iNewGoodID);
    end if;

    -- 15. Génération du code EAN du bien
    pGenerate_GOOD_EAN(iGoodID => iNewGoodID);
    -- 16. Génération du code EAN pour les données compl. d'achat
    pGenerate_CDA_PURCHASE_EAN(iGoodID => iNewGoodID);
    -- 17. Génération du code EAN pour les données compl. de vente
    pGenerate_CDA_SALE_EAN(iGoodID => iNewGoodID);

    -- 18. Duplication des matières précieuses
    if iDuplPreciousMat = 1 then
      pDuplicate_PRECIOUS_MAT(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
    end if;

    -- 19. Duplication des données de prestation
    pDuplicateCMLService(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);
  end DuplicateService;

  /**
  * procedure DuplicatePseudo
  * Description
  *   Méthode générale pour la duplication d'un pseudo bien
  */
  procedure DuplicatePseudo(
    iSourceGoodID      in     GCO_GOOD.GCO_GOOD_ID%type
  , iNewGoodID         in out GCO_GOOD.GCO_GOOD_ID%type
  , iNewMajorRef       in     GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , iNewSecRef         in     GCO_GOOD.GOO_SECONDARY_REFERENCE%type
  , iDuplVirtualFields in     number default 0
  )
  is
    lnActiveGoodStatus integer;
    ltNew              FWK_I_TYP_DEFINITION.t_crud_def;
    lOptions           GCO_LIB_CONSTANT.gtProductCopySyncOptions;
  begin
    -- Définir si le Pseudo doit être crée avec le statut actif
    if nvl(PCS.PC_CONFIG.GETCONFIG('GCO_INACTIVE_CREATION_GOOD'), '0') = '0' then
      lnActiveGoodStatus  := 1;
    else
      lnActiveGoodStatus  := 0;
    end if;

    -- Recherche l'ID du nouveau bien s'il n'as pas été passé en paramètre
    if nvl(iNewGoodID, 0) = 0 then
      iNewGoodID  := INIT_ID_SEQ.nextval;
    end if;

    -- 1. Duplication des données de la table GCO_GOOD
    -- 2. Insertion dans la table GCO_PSEUDO_GOOD
    -- 3. Duplication des descriptions
    -- 4. Duplication des champs virtuels
    -- 5. Génération du code EAN du bien

    --  1. Duplication des données de la table GCO_GOOD
    -- Remarque : l'utilisation de la variable lOptions (non-initialisée ici) sert à utiliser
    --              les valeurs par défaut définies dans le pkg_GCO_LIB_CONSTANT
    pDuplicate_GOOD(iSourceGoodID       => iSourceGoodID
                  , iNewGoodID          => iNewGoodID
                  , iNewMajorRef        => iNewMajorRef
                  , iNewSecRef          => iNewSecRef
                  , iActiveGoodStatus   => lnActiveGoodStatus
                  , iOptions            => lOptions
                   );
    -- 2. Insertion dans la table GCO_PSEUDO_GOOD
    FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_I_TYP_GCO_ENTITY.gcGcoPseudoGood, iot_crud_definition => ltNew, iv_primary_col => 'GCO_GOOD_ID');
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltNew, 'GCO_GOOD_ID', iNewGoodID);
    FWK_I_MGT_ENTITY.InsertEntity(ltNew);
    FWK_I_MGT_ENTITY.Release(ltNew);
    --  3. Duplication des descriptions
    pDuplicate_DESCRIPTION(iSourceGoodID => iSourceGoodID, iNewGoodID => iNewGoodID);

    -- 4. Duplication des champs virtuels
    if iDuplVirtualFields = 1 then
      COM_VFIELDS.DuplicateVirtualField(aTableName => 'GCO_GOOD', aFieldName => null, aIDRecordSource => iSourceGoodID, aIDRecordTarget => iNewGoodID);
    end if;

    -- 5. Génération du code EAN du bien
    pGenerate_GOOD_EAN(iGoodID => iNewGoodID);
  --
  -- Génération de la Réf. du bien si en Réf. automatique (effectué par le GCO_MGT_GOOD.insertGOOD)
  --
  end DuplicatePseudo;

  /**
  * procedure DuplicateGoodNomenclature
  * Description
  *   Duplication des nomenclatures d'un bien source pour un bien cible
   */
  procedure DuplicateGoodNomenclature(
    iSourceGoodID in GCO_GOOD.GCO_GOOD_ID%type
  , iTargetGoodID in GCO_GOOD.GCO_GOOD_ID%type
  , iTypeNom      in PPS_NOMENCLATURE.C_TYPE_NOM%type default null
  )
  is
    lLink TLINK_MATCH;
  begin
    pDuplicate_NOMENCLATURE(iSourceGoodID => iSourceGoodID, iNewGoodID => iTargetGoodID, iTypeNom => iTypeNom, iNomenclatureLinkMatch => lLink);
  end DuplicateGoodNomenclature;

  /**
  * procedure SynchronizeProduct
  * Description
  *   Synchronisation des données d'un bien source sur un bien cible
  */
  procedure SynchronizeProduct(
    iSourceGoodID   in     GCO_GOOD.GCO_GOOD_ID%type
  , iTargetGoodID   in     GCO_GOOD.GCO_GOOD_ID%type
  , iRelationTypeID in     GCO_GOOD_LINK.DIC_RELATION_TYPE_ID%type
  , iFreeText       in     GCO_GOOD_LINK.GLI_FREE_TEXT%type
  , iOptions        in     clob
  , oErrorCode      out    number
  )
  is
  begin
    oErrorCode  := REP_PRC_ECC.SynchronizeGood(iFromGoodId => iSourceGoodID, iToGoodId => iTargetGoodID, iOptions => iOptions);

    -- Générer le lien entre les produits source - cible dans la table de lien
    if oErrorCode = 0 then
      CreateGoodLink(iLinkType         => '2'
                   , iSourceGoodID     => iSourceGoodID
                   , iTargetGoodID     => iTargetGoodID
                   , iRelationTypeID   => iRelationTypeID
                   , iFreeText         => iFreeText
                   , iOptions          => iOptions
                    );
    end if;
  exception
    when others then
      null;
  end SynchronizeProduct;

  /**
  * procedure SetGoodDeleting
  * Description
  *   Indiquer qu'un bien est en train d'être effacé en inserant cette info dans la COM_LIST_ID_TEMP
  *     (Utilisé dans les triggers de réplication pour ne pas générer l'erreur table is muttating )
  */
  procedure SetGoodDeleting(iGoodID in GCO_GOOD.GCO_GOOD_ID%type, iDeleting in boolean)
  is
    ltComListTmp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- D'abord on s'assure que l'entrée n'est pas déjà dans la table temp en l'effaçant préventivement
    FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'COM_LIST_ID_TEMP_ID', iGoodID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_CODE', 'GOOD_DELETING');
    FWK_I_MGT_ENTITY.DeleteEntity(ltComListTmp);

    -- Indiquer que l'on est en train d'effacer le bien en inserant l'info la table temp
    if iDeleting then
      FWK_I_MGT_ENTITY.InsertEntity(ltComListTmp);
    end if;

    FWK_I_MGT_ENTITY.Release(ltComListTmp);
  end SetGoodDeleting;
end GCO_PRC_GOOD;
