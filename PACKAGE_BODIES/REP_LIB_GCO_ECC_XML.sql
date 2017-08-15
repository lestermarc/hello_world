--------------------------------------------------------
--  DDL for Package Body REP_LIB_GCO_ECC_XML
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_LIB_GCO_ECC_XML" 
is
  pcGetPK2        constant varchar2(39) := 'FWK_I_LIB_ENTITY.getVarchar2FieldFromPk';
  pcGetCDe        constant varchar2(33) := 'PCS.PC_FUNCTIONS.GetDescodeDescr';
  pcSepPK2        constant varchar2(13) := ' || '' '' || ';
  pcShowReference constant boolean      := false;

  /**
  * fonction getGoodXmlEntity
  * Description
  *    Génération d'un fraggment XML d'une entité d'un bien en vue d'une synchronisation vers un autre bien
  */
  function getGoodXmlEntity(iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type, iToGoodId in GCO_GOOD.GCO_GOOD_ID%type, iOptions in clob)
    return xmltype
  as
    lxData   xmltype;
    lOptions GCO_LIB_CONSTANT.gtProductCopySyncOptions;
  begin
    -- Contrôle eds paramètres
    if    (iFromGoodId is null)
       or (iToGoodId is null)
       or (iOptions is null)
       or (DBMS_LOB.getLength(iOptions) = 0) then
      return null;
    end if;

    -- Chargement des options de synchronisation
    lOptions  := GCO_LIB_FUNCTIONS.loadProductCopySyncOptions(iOptions);
    -- Construction du fragment XML pour les données reprises dans tous les cas
    lxData    := getGoodXml(iFromGoodId, iToGoodId);

    -- Génération du fragment complet GCO_GOOD
    if (lxData is not null) then
      select XMLElement(GCO_GOOD
                      , lxData
                      , getGcoProductXml(iFromGoodId)
                      , getGcoDescriptionXml(iFromGoodId)
                      , getGcoEquivalenceGoodXml(iFromGoodId)
                      , getGcoImputDocXml(iFromGoodId)
                      , getGcoImputStockXml(iFromGoodId)
                      , getGcoMeasurementWeightXml(iFromGoodId)
                      , getGcoVatGoodXml(iFromGoodId)
                      , getGcoMaterialXml(iFromGoodId)
                      , decode(lOptions.bGCO_COMPL_DATA_STOCK, 1, getGcoComplDataStockXml(iFromGoodId) )
                      , decode(lOptions.bGCO_COMPL_DATA_INVENTORY, 1, getGcoComplDataInventoryXml(iFromGoodId) )
                      , decode(lOptions.bGCO_COMPL_DATA_PURCHASE, 1, getGcoComplDataPurchaseXml(iFromGoodId, lOptions.bSQM_CERTIFICATION) )
                      , decode(lOptions.bGCO_COMPL_DATA_SALE, 1, getGcoComplDataSaleXml(iFromGoodId) )
                      , decode(lOptions.bGCO_COMPL_DATA_ASS, 1, getGcoComplDataAssXml(iFromGoodId) )
                      , decode(lOptions.bGCO_COMPL_DATA_EXTERNAL_ASA, 1, getGcoComplDataExternalAsaXml(iFromGoodId) )
                      , decode(lOptions.bGCO_COMPL_DATA_MANUFACTURE
                             , 1, getGcoComplDataManufactureXml(iFromGoodId
                                                              , iToGoodId
                                                              , lOptions.bGCO_COUPLED_GOOD
                                                              , lOptions.bSQM_CERTIFICATION
                                                              , lOptions.bPPS_NOMENCLATURE
                                                              , lOptions.bFAL_SCHEDULE_PLAN
                                                               )
                              )
                      , decode(lOptions.bGCO_COMPL_DATA_SUBCONTRACT, 1, getGcoComplDataSubcontractXml(iFromGoodId, iToGoodId, lOptions.bPPS_NOMENCLATURE) )
                      , decode(lOptions.bGCO_GOOD_ATTRIBUTE, 1, getGcoGoodAttributeXml(iFromGoodId) )
                      , decode(lOptions.bGCO_COMPL_DATA_DISTRIB, 1, getGcoComplDataDistribXml(iFromGoodId) )
                      , decode(lOptions.bPTC_FIXED_COSTPRICE, 1, getPtcFixedCostpriceXml(iFromGoodId) )
                      , decode(lOptions.bPTC_CALC_COSTPRICE, 1, getPtcCalcCostpriceXml(iFromGoodId) )
                      , decode(lOptions.bPTC_TARIFF, 1, getPtcTariffXml(iFromGoodId) )
                      , decode(lOptions.bPTC_DISCOUNT, 1, getPtcDiscountGoodLinkXml(iFromGoodId) )
                      , decode(lOptions.bPTC_CHARGE, 1, getPtcChargeGoodLinkXml(iFromGoodId) )
                      , decode(lOptions.bGCO_PRECIOUS_MAT, 1, getGcoPreciousMatXml(iFromGoodId) )
                      , decode(lOptions.bGCO_CONNECTED_GOOD, 1, getGcoConnectedGoodXml(iFromGoodId) )
                      , decode(lOptions.bFREE_DATA, 1, getGcoFreeDataXml(iFromGoodId) )
                      , decode(lOptions.bVIRTUAL_FIELDS, 1, REP_LIB_ECC_XML.getVFieldXml('GCO_GOOD', iFromGoodId) )
                      , decode(lOptions.bPPS_TOOLS, 1, getPpsToolXml(iFromGoodId, lOptions.bPPS_SPECIAL_TOOLS) )
                       )
        into lxData
        from dual;

      return lxData;
    end if;

    return null;
  exception
    when others then
      raise;
      lxData  := XmlErrorDetail(sqlerrm);

      select XMLElement(GCO_GOOD, XMLAttributes(iFromGoodId as "FROM ID", iToGoodId as "TO ID"), xmlcomment(rep_utils.GetCreationContext), lxData)
        into lxData
        from dual;

      return lxData;
  end getGoodXmlEntity;

  /**
  * fonction getGoodXml
  * Description
  *    Génération d'un fragment XML d'un bien en vue d'une synchronisation vers un autre bien
  */
  function getGoodXml(
    iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type
  , iToGoodId   in GCO_GOOD.GCO_GOOD_ID%type
  , iCtxUsage   in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall   in number default 0
  , iToCall     in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lToMajorRef              GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    lFromMajorRef            GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    lcEntityName    constant varchar2(30)                        := 'GCO_GOOD';
    lcTableKeyValue constant varchar2(32767)                     := 'GOO_MAJOR_REFERENCE';
  begin
    lToMajorRef    := FWK_I_LIB_ENTITY.getVarchar2FieldFromPk(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_MAJOR_REFERENCE', iToGoodId);
    lFromMajorRef  := FWK_I_LIB_ENTITY.getVarchar2FieldFromPk(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_MAJOR_REFERENCE', iFromGoodId);
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(GOO_MAJOR_REFERENCE, ''' || lToMajorRef || ''')';

    if iCtxUsage = REP_LIB_CONSTANT.COMPARISON then
      -- Ajoute le header de comparaison
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(HEADER_KEY, ''' || lFromMajorRef || ' --> ' || '' || lToMajorRef || ''')';
      lSQLCmdPrefix  :=
         lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getGcoProductXml(' || lcEntityName || '.' || lcEntityName || '_ID, ' || iCtxUsage || ', 0, ' || iToCall || ')';
      lSQLCmdPrefix  :=
        lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getGcoDescriptionXml(' || lcEntityName || '.' || lcEntityName || '_ID, ' || iCtxUsage || ', 0, ' || iToCall
        || ')';
      lSQLCmdPrefix  :=
        lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getGcoEquivalenceGoodXml(' || lcEntityName || '.' || lcEntityName || '_ID, ' || iCtxUsage || ', 0, ' || iToCall
        || ')';
      lSQLCmdPrefix  :=
        lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getGcoImputDocXml(' || lcEntityName || '.' || lcEntityName || '_ID, ' || iCtxUsage || ', 0, ' || iToCall || ')';
      lSQLCmdPrefix  :=
        lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getGcoImputStockXml(' || lcEntityName || '.' || lcEntityName || '_ID, ' || iCtxUsage || ', 0, ' || iToCall
        || ')';
      lSQLCmdPrefix  :=
        lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getGcoMeasurementWeightXml(' || lcEntityName || '.' || lcEntityName || '_ID, ' || iCtxUsage || ', 0, '
        || iToCall || ')';
      lSQLCmdPrefix  :=
         lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getGcoVatGoodXml(' || lcEntityName || '.' || lcEntityName || '_ID, ' || iCtxUsage || ', 0, ' || iToCall || ')';
      lSQLCmdPrefix  :=
        lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getGcoMaterialXml(' || lcEntityName || '.' || lcEntityName || '_ID, ' || iCtxUsage || ', 0, ' || iToCall || ')';
    end if;

    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iFromGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iTableType       => 'MAIN'
                                          , iIsList          => 0
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                           );
  end getGoodXml;

  /**
  * fonction getProductXml
  * Description
  *    Génération d'un fragment XML d'un produit en vue d'une synchronisation d'un bien vers un autre bien
  */
  function getGcoProductXml(
    iGoodId   in GCO_PRODUCT.GCO_GOOD_ID%type
  , iCtxUsage in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_PRODUCT';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID';
  begin
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    if (iCtxUsage = REP_LIB_CONSTANT.COMPARISON) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.GCO_GOOD_ID)';
    end if;

    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iIsList          => 0
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                           );
  end getGcoProductXml;

  /**
  * fonction getGcoDescriptionXml
  * Description
  *    Génération d'un fragment XML des descriptions du bien en vue de sa synchronisation vers un autre bien
  */
  function getGcoDescriptionXml(
    iGoodId   in GCO_DESCRIPTION.GCO_GOOD_ID%type
  , iCtxUsage in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_DESCRIPTION';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,PC_LANG_ID,C_DESCRIPTION_TYPE';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''PCS.PC_LANG'', ''LANID'', ' || lcEntityName || '.PC_LANG_ID)' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetCDe || '(''C_DESCRIPTION_TYPE'', ' || lcEntityName || '.C_DESCRIPTION_TYPE))';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(PC_LANG_ID, ' || lcEntityName || '.PC_LANG_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(C_DESCRIPTION_TYPE, ' || lcEntityName || '.C_DESCRIPTION_TYPE)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getGcoDescriptionXml;

  /**
  * fonction getGcoEquivalenceGoodXml
  * Description
  *    Génération d'un fragment XML des produits équivalents du bien en vue de sa synchronisation vers un autre bien
  */
  function getGcoEquivalenceGoodXml(
    iGoodId   in GCO_EQUIVALENCE_GOOD.GCO_GOOD_ID%type
  , iCtxUsage in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_EQUIVALENCE_GOOD';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,GCO_GCO_GOOD_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GCO_GOOD_ID))';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(GCO_GCO_GOOD_ID, ' || lcEntityName || '.GCO_GCO_GOOD_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getGcoEquivalenceGoodXml;

  /**
  * fonction getGcoImputDocXml
  * Description
  *    Génération d'un fragment XML des imputations financières des documents du bien en vue de sa synchronisation vers un autre bien
  */
  function getGcoImputDocXml(
    iGoodId   in GCO_IMPUT_DOC.GCO_GOOD_ID%type
  , iCtxUsage in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_IMPUT_DOC';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,C_ADMIN_DOMAIN';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetCDe || '(''C_ADMIN_DOMAIN'', ' || lcEntityName || '.C_ADMIN_DOMAIN))';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(C_ADMIN_DOMAIN, ' || lcEntityName || '.C_ADMIN_DOMAIN)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getGcoImputDocXml;

  /**
  * fonction getGcoImputStockXml
  * Description
  *    Génération d'un fragment XML des imputations financières des mouvements du bien en vue de sa synchronisation vers un autre bien
  */
  function getGcoImputStockXml(
    iGoodId   in GCO_IMPUT_STOCK.GCO_GOOD_ID%type
  , iCtxUsage in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_IMPUT_STOCK';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,STM_MOVEMENT_KIND_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''STM_MOVEMENT_KIND'', ''MOK_ABBREVIATION'', ' || lcEntityName || '.STM_MOVEMENT_KIND_ID))';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(STM_MOVEMENT_KIND_ID, ' || lcEntityName || '.STM_MOVEMENT_KIND_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getGcoImputStockXml;

  /**
  * fonction getGcoMeasurementWeightXml
  * Description
  *    Génération d'un fragment XML des Mesures et poids du bien en vue de sa synchronisation vers un autre bien
  */
  function getGcoMeasurementWeightXml(
    iGoodId   in GCO_MEASUREMENT_WEIGHT.GCO_GOOD_ID%type
  , iCtxUsage in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_MEASUREMENT_WEIGHT';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,DIC_SHAPE_TYPE_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.DIC_SHAPE_TYPE_ID)';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(DIC_SHAPE_TYPE_ID, ' || lcEntityName || '.DIC_SHAPE_TYPE_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getGcoMeasurementWeightXml;

  /**
  * fonction getGcoVatGoodXml
  * Description
  *    Génération d'un fragment XML des Taxes et TVA du bien en vue de sa synchronisation vers un autre bien
  */
  function getGcoVatGoodXml(
    iGoodId   in GCO_VAT_GOOD.GCO_GOOD_ID%type
  , iCtxUsage in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_VAT_GOOD';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,ACS_VAT_DET_ACCOUNT_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      -- Attente d'une clé unique sur la table ACS_VAT_DET_ACCOUNT
      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.ACS_VAT_DET_ACCOUNT_ID)';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(ACS_VAT_DET_ACCOUNT_ID, ' || lcEntityName || '.ACS_VAT_DET_ACCOUNT_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getGcoVatGoodXml;

  /**
  * fonction getGcoMaterialXml
  * Description
  *    Génération d'un fragment XML des Taxes et TVA du bien en vue de sa synchronisation vers un autre bien
  */
  function getGcoMaterialXml(
    iGoodId   in GCO_MATERIAL.GCO_GOOD_ID%type
  , iCtxUsage in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_MATERIAL';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,DIC_MATERIAL_KIND_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.DIC_MATERIAL_KIND_ID)';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(DIC_MATERIAL_KIND_ID, ' || lcEntityName || '.DIC_MATERIAL_KIND_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getGcoMaterialXml;

  /**
  * fonction getGcoComplDataStockXml
  * Description
  *   Génération d'un fragment XML des données complémentaires de stock du bien en vue de sa synchronisation vers un autre bien
  */
  function getGcoComplDataStockXml(
    iGoodId   in GCO_COMPL_DATA_STOCK.GCO_GOOD_ID%type
  , iCtxUsage in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_COMPL_DATA_STOCK';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,STM_STOCK_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''STM_STOCK'', ''STO_DESCRIPTION'', ' || lcEntityName || '.STM_STOCK_ID))';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(STM_STOCK_ID, ' || lcEntityName || '.STM_STOCK_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getGcoComplDataStockXml;

  /**
  * fonction getGcoComplDataInventoryXml
  * Description
  *   Génération d'un fragment XML des données complémentaires d'inventaire du bien en vue de sa synchronisation vers un autre bien
  */
  function getGcoComplDataInventoryXml(
    iGoodId   in GCO_COMPL_DATA_INVENTORY.GCO_GOOD_ID%type
  , iCtxUsage in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_COMPL_DATA_INVENTORY';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,STM_STOCK_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''STM_STOCK'', ''STO_DESCRIPTION'', ' || lcEntityName || '.STM_STOCK_ID))';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(STM_STOCK_ID, ' || lcEntityName || '.STM_STOCK_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getGcoComplDataInventoryXml;

  /**
  * fonction getGcoComplDataPurchaseXml
  * Description
  *    Génération d'un fragment XML des données complémentaires d'achat du bien en vue de sa synchronisation vers un autre bien
  */
  function getGcoComplDataPurchaseXml(
    iGoodId             in GCO_COMPL_DATA_PURCHASE.GCO_GOOD_ID%type
  , doGenerateCertifLnk in integer
  , iCtxUsage           in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall           in number default 0
  , iToCall             in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_COMPL_DATA_PURCHASE';
    lxData                   xmltype;
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,PAC_SUPPLIER_PARTNER_ID,CPU_DEFAULT_SUPPLIER,DIC_COMPLEMENTARY_DATA_ID,GCO_GCO_GOOD_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''PAC_PERSON'', ''PER_NAME'', ' || lcEntityName || '.PAC_SUPPLIER_PARTNER_ID)' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.DIC_COMPLEMENTARY_DATA_ID' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GCO_GOOD_ID))';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(PAC_SUPPLIER_PARTNER_ID, ' || lcEntityName || '.PAC_SUPPLIER_PARTNER_ID)';
--     lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(CPU_DEFAULT_SUPPLIER, CPU_DEFAULT_SUPPLIER)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(DIC_COMPLEMENTARY_DATA_ID, ' || lcEntityName || '.DIC_COMPLEMENTARY_DATA_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(GCO_GCO_GOOD_ID, ' || lcEntityName || '.GCO_GCO_GOOD_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';

    if     (doGenerateCertifLnk = 1)
       and (iCtxUsage = REP_LIB_CONSTANT.COMPARISON) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getSqmCertificationGoodLinkXml(GCO_GOOD_ID, ''1'', ' || iCtxUsage || ')';
    end if;

    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    lxData         :=
      REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                     , iEntityId        => iGoodId
                                     , iSQLCmdPrefix    => lSQLCmdPrefix
                                     , iSQLCmdSuffix    => lSQLCmdSuffix
                                     , iCtxUsage        => iCtxUsage
                                     , iMainCall        => iMainCall
                                     , iTableKeyValue   => lcTableKeyValue
                                     , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                      );

    if     lxData is not null
       and (iCtxUsage <> REP_LIB_CONSTANT.COMPARISON) then
      -- S'il y a des données complémentaire d'achat, on ajoute les liens vers les homologations si l'option a été choisie.
      select XMLConcat(lxData, decode(doGenerateCertifLnk, 1, getSqmCertificationGoodLinkXml(iGoodId, '1', iCtxUsage) ) )
        into lxData
        from dual;
    end if;

    return lxData;
  end getGcoComplDataPurchaseXml;

  /**
  * fonction getGcoComplDataSaleXml
  * Description
  *    Génération d'un fragment XML des données complémentaires de vente du bien en vue de sa synchronisation vers un autre bien
  */
  function getGcoComplDataSaleXml(
    iGoodId   in GCO_COMPL_DATA_SALE.GCO_GOOD_ID%type
  , iCtxUsage in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_COMPL_DATA_SALE';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,PAC_CUSTOM_PARTNER_ID,DIC_COMPLEMENTARY_DATA_ID';
  begin
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''PAC_PERSON'', ''PER_NAME'', ' || lcEntityName || '.PAC_CUSTOM_PARTNER_ID)' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.DIC_COMPLEMENTARY_DATA_ID)';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(PAC_CUSTOM_PARTNER_ID, ' || lcEntityName || '.PAC_CUSTOM_PARTNER_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(DIC_COMPLEMENTARY_DATA_ID, ' || lcEntityName || '.DIC_COMPLEMENTARY_DATA_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getGcoPackingElementXml(' || lcEntityName || '.GCO_COMPL_DATA_SALE_ID, ' || iCtxUsage || ')';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getGcoComplDataSaleXml;

  /**
   * fonction getGcoPackingElementXml
   * Description
   *    Génération d'un fragment XML des données d'emballage des données compl. de vente du bien en vue de sa synchronisation vers un autre bien
   */
  function getGcoPackingElementXml(
    iComplDataSaleId in GCO_COMPL_DATA_SALE.GCO_COMPL_DATA_SALE_ID%type
  , iCtxUsage        in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall        in number default 0
  , iToCall          in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_PACKING_ELEMENT';
    lcTableKeyValue constant varchar2(32767) := 'GCO_COMPL_DATA_SALE_ID,SHI_SEQ';
  begin
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.SHI_SEQ)';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(SHI_SEQ, ' || lcEntityName || '.SHI_SEQ)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_COMPL_DATA_SALE_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iComplDataSaleId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getGcoPackingElementXml;

  /**
  * fonction getGcoComplDataAssXml
  * Description
  *    Génération d'un fragment XML des données complémentaires de SAV interne du bien en vue de sa synchronisation vers un autre bien
  */
  function getGcoComplDataAssXml(
    iGoodId   in GCO_COMPL_DATA_ASS.GCO_GOOD_ID%type
  , iCtxUsage in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_COMPL_DATA_ASS';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,ASA_REP_TYPE_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''ASA_REP_TYPE'', ''RET_REP_TYPE'', ' || lcEntityName || '.ASA_REP_TYPE_ID))';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(ASA_REP_TYPE_ID, ' || lcEntityName || '.ASA_REP_TYPE_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getAsaRepTypeGoodXml(' || lcEntityName || '.GCO_GOOD_ID';
    lSQLCmdPrefix  := lSQLCmdPrefix || '                                         , ' || lcEntityName || '.ASA_REP_TYPE_ID';
    lSQLCmdPrefix  := lSQLCmdPrefix || '                                         , ' || iCtxUsage || ')';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.ASA_REP_TYPE_ID'
                                           );
  end getGcoComplDataAssXml;

  /**
   * fonction getAsaRepTypeGoodXml
   * Description
   *    Génération d'un fragment XML des articles des réparations des données compl. de SAV interne du bien en vue de sa synchronisation vers un autre bien
   */
  function getAsaRepTypeGoodXml(
    iGoodId    in GCO_COMPL_DATA_ASS.GCO_GOOD_ID%type
  , iRepTypeId in GCO_COMPL_DATA_ASS.ASA_REP_TYPE_ID%type
  , iCtxUsage  in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall  in number default 0
  , iToCall    in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'ASA_REP_TYPE_GOOD';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_TO_REPAIR_ID,ASA_REP_TYPE_ID';
  begin
    -- TODO : gestion de la comparaison si iMainCall (ne devrait pas être le cas.)
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_TO_REPAIR_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''ASA_REP_TYPE'', ''RET_REP_TYPE'', ' || lcEntityName || '.ASA_REP_TYPE_ID))';
    end if;

    if (iCtxUsage <> REP_LIB_CONSTANT.COMPARISON) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(GCO_GOOD_TO_REPAIR_ID, ' || lcEntityName || '.GCO_GOOD_TO_REPAIR_ID)';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(ASA_REP_TYPE_ID, ' || lcEntityName || '.ASA_REP_TYPE_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName;
    lSQLCmdSuffix  := lSQLCmdSuffix || ' where ' || lcEntityName || '.GCO_GOOD_TO_REPAIR_ID = :ENTITY_ID';

    if iRepTypeId is null then
      lSQLCmdSuffix  := lSQLCmdSuffix || '   and ' || lcEntityName || '.ASA_REP_TYPE_ID is null';
    else
      lSQLCmdSuffix  := lSQLCmdSuffix || '   and ' || lcEntityName || '.ASA_REP_TYPE_ID = ' || iRepTypeId;
    end if;

    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iIsList          => 0
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getAsaRepTypeGoodXml;

  /**
  * fonction getGcoComplDataExternalAsaXml
  * Description
  *    Génération d'un fragment XML des données complémentaires de SAV externe du bien en vue de sa synchronisation vers un autre bien
  */
  function getGcoComplDataExternalAsaXml(
    iGoodId   in GCO_COMPL_DATA_EXTERNAL_ASA.GCO_GOOD_ID%type
  , iCtxUsage in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_COMPL_DATA_EXTERNAL_ASA';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,DIC_COMPLEMENTARY_DATA_ID';
    lxData                   xmltype;
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.DIC_COMPLEMENTARY_DATA_ID)';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(DIC_COMPLEMENTARY_DATA_ID, ' || lcEntityName || '.DIC_COMPLEMENTARY_DATA_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';

    if iCtxUsage = REP_LIB_CONSTANT.COMPARISON then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getAsaCounterXml(GCO_GOOD_ID, ' || iCtxUsage || ', 0, ' || iToCall || ')';
    end if;

    lSQLCmdPrefix  :=
      lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getAsaServicePlansXml(' || lcEntityName || '.GCO_COMPL_DATA_EXTERNAL_ASA_ID, ' || iCtxUsage || ', 0, ' || iToCall
      || ')';
    lSQLCmdPrefix  :=
      lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getAsaTechniciansXml(' || lcEntityName || '.GCO_COMPL_DATA_EXTERNAL_ASA_ID, ' || iCtxUsage || ', 0, ' || iToCall
      || ')';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    lxData         :=
      REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                     , iEntityId        => iGoodId
                                     , iSQLCmdPrefix    => lSQLCmdPrefix
                                     , iSQLCmdSuffix    => lSQLCmdSuffix
                                     , iCtxUsage        => iCtxUsage
                                     , iMainCall        => iMainCall
                                     , iTableKeyValue   => lcTableKeyValue
                                     , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                      );

    if     lxData is not null
       and (iCtxUsage <> REP_LIB_CONSTANT.COMPARISON) then
      -- S'il y a des données complémentaire de service après-vente externe, on ajoute les compteurs.
      select XMLConcat(lxData, getAsaCounterXml(iGoodId, iCtxUsage) )
        into lxData
        from dual;
    end if;

    return lxData;
  end getGcoComplDataExternalAsaXml;

  /**
   * fonction getAsaCounterXml
   * Description
   *    Génération d'un fragment XML des compteurs des données compl. de SAV externe du bien en vue de sa synchronisation vers un autre bien
   */
  function getAsaCounterXml(
    iGoodId   in ASA_COUNTER_TYPE_S_GOOD.GCO_GOOD_ID%type
  , iCtxUsage in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'ASA_COUNTER_TYPE_S_GOOD';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,ASA_COUNTER_TYPE_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''ASA_COUNTER_TYPE'', ''CTT_KEY'', ' || lcEntityName || '.ASA_COUNTER_TYPE_ID))';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(ASA_COUNTER_TYPE_ID, ' || lcEntityName || '.ASA_COUNTER_TYPE_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
--                                          , iOrderByClause   => lcEntityName || '.ASA_COUNTER_TYPE_ID'
                                           );
  end getAsaCounterXml;

  function getAsaTechniciansXml(
    iComplDataExternalAsaId in GCO_COMPL_DATA_EXTERNAL_ASA.GCO_COMPL_DATA_EXTERNAL_ASA_ID%type
  , iCtxUsage               in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall               in number default 0
  , iToCall                 in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_COMPL_ASA_EXT_S_HRM_JOB';
    lcTableKeyValue constant varchar2(32767) := 'GCO_COMPL_DATA_EXTERNAL_ASA_ID,HRM_JOB_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';
      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''HRM_JOB'', ''JOB_CODE'', ' || lcEntityName || '.HRM_JOB_ID))';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(HRM_JOB_ID, ' || lcEntityName || '.HRM_JOB_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_COMPL_DATA_EXTERNAL_ASA_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iComplDataExternalAsaId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.HRM_JOB_ID'
                                           );
  end getAsaTechniciansXml;

  /**
   * fonction getAsaServicePlansXml
   * Description
   *    Génération d'un fragment XML des plans de service des données compl. de SAV externe du bien en vue de sa synchronisation vers un autre bien
   */
  function getAsaServicePlansXml(
    iComplDataExternalAsaId in GCO_COMPL_DATA_EXTERNAL_ASA.GCO_COMPL_DATA_EXTERNAL_ASA_ID%type
  , iCtxUsage               in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall               in number default 0
  , iToCall                 in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_SERVICE_PLAN';
    lcTableKeyValue constant varchar2(32767) := 'GCO_COMPL_DATA_EXTERNAL_ASA_ID,SER_SEQ';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY, ' || lcEntityName || '.SER_SEQ)';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(SER_SEQ, ' || lcEntityName || '.SER_SEQ)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_COMPL_DATA_EXTERNAL_ASA_ID = :ENTITY_ID';
    -- lSQLCmdSuffix  := lSQLCmdSuffix || ' order by SER_SEQ';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iComplDataExternalAsaId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.SER_SEQ'
                                           );
  end getAsaServicePlansXml;

  /**
   * fonction getGcoComplDataManufactureXml
   * Description
   *    Génération d'un fragment XML des données complémentaires de fabrication du bien en vue de sa synchronisation vers un autre bien
   */
  function getGcoComplDataManufactureXml(
    iFromGoodId             in GCO_COMPL_DATA_MANUFACTURE.GCO_GOOD_ID%type
  , iToGoodId               in GCO_COMPL_DATA_MANUFACTURE.GCO_GOOD_ID%type
  , iDoGenerateCoupledGood  in number
  , iDoGenerateCertifLnk    in number
  , iDoGenerateNomenclature in number
  , iDoGenerateSchedulePlan in number
  , iCtxUsage               in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall               in number default 0
  , iToCall                 in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_COMPL_DATA_MANUFACTURE';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,DIC_FAB_CONDITION_ID';
    lxData                   xmltype;
    lToPps                   varchar2(32767);
    lToSch                   varchar2(32767);
  begin
    /**
     * Synchronisation des données complémentaires de fabrication d'un produit B sur un produit A
     *
     * Gestion du lien vers la gamme opératoire :
     *   Cas 1 : - Le lien n'existe pas sur B (FAL_SCHEDULE_PLAN_ID est null) et n'existe pas sur A : On supprime le lien sur A
     *   Cas 2 : - Le lien n'existe pas sur B (FAL_SCHEDULE_PLAN_ID est null) mais existe sur A : On supprime le lien sur A
     *   Cas 3 : - Le lien existe sur B et sur A : On garde le lien existant sur A
     *           - La gamme opératoire liée sur A est mise à jour avec les données de la gamme liées sur B (sauf SCH_REF)
     *   Cas 4 : - Le lien existe sur B mais pas sur A : On ne fait rien car impossible de connaître la référence de la nouvelle gamme.
     *
     * Gestion du lien vers la nomenclature :
     *   Cas 1 : - Le lien n'existe pas sur B (PPS_NOMENCLATURE_ID est null) et n'existe pas sur A : On supprime le lien sur A
     *   Cas 2 : - Le lien n'existe pas sur B (PPS_NOMENCLATURE_ID est null) mais existe sur A : On supprime le lien sur A
     *   Cas 3 : - Le lien existe sur B et sur A : On garde le lien existant sur A
     *           - La nomenclature liée sur A est mise à jour avec les données de la nomenclature liée sur B
     *           - Si les champs de la PK2 devaient entrer en conflit avec une autre nomenclature de A suite à ce traitement
     *             on accepte, selon directive de FBO du 28.02.2014, qu'une erreur de violation de contrainte unique soit levée.
     *   Cas 4 : - Le lien existe sur B, mais pas sur A (ex : nouvelle donnée compl. sur B) : On lie la nomenclature de A qui
     *             correspond à la nomenclature liée sur la donnée compl. de B (type, version et dossier identique).
     *           - Si cette nomenclature n'existe pas, on la crée.
     */
    lToSch         := 'decode(' || lcEntityName || '.FAL_SCHEDULE_PLAN_ID,null,null,toCma.FAL_SCHEDULE_PLAN_ID)';
    lToPps         := 'decode(' || lcEntityName || '.PPS_NOMENCLATURE_ID,null,null,nvl(toCma.PPS_NOMENCLATURE_ID,toPps.PPS_NOMENCLATURE_ID))';
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.DIC_FAB_CONDITION_ID)';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(DIC_FAB_CONDITION_ID, ' || lcEntityName || '.DIC_FAB_CONDITION_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(FAL_SCHEDULE_PLAN_ID,' || lToSch || ')';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(PPS_NOMENCLATURE_ID, ' || lToPps || ')';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';

    -- Ajout de données de la gamme opératoire liée si l'option est sélectionnée.
    if iDoGenerateSchedulePlan = 1 then
      lSQLCmdPrefix  :=
        lSQLCmdPrefix ||
        ', REP_LIB_GCO_ECC_XML.getFalCdSchedulePlanXml(' ||
        lcEntityName ||
        '.' ||
        lcEntityName ||
        '_ID,' ||
        iToGoodId ||
        ',' ||
        iCtxUsage ||
        ', 0, ' ||
        iToCall ||
        ')';
    end if;

    -- Ajout des données de la nomenclature liée si l'option est sélectionnée.
    if iDoGenerateNomenclature = 1 then
      lSQLCmdPrefix  :=
        lSQLCmdPrefix ||
        ', REP_LIB_GCO_ECC_XML.getPpsCdNomenclatureXml(' ||
        lcEntityName ||
        '.PPS_NOMENCLATURE_ID,' ||
        lToPps ||
        ',' ||
        iCtxUsage ||
        ', 0, ' ||
        iToCall ||
        ')';
    end if;

    -- Ajout des produits couplés si l'option est sélectionnée.
    if iDoGenerateCoupledGood = 1 then
      lSQLCmdPrefix  :=
        lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getGcoCoupledGoodXml(' || lcEntityName || '.' || lcEntityName || '_ID, ' || iCtxUsage || ', 0, ' || iToCall
        || ')';
    end if;

    -- Ajout des liens vers les homologations si l'option est sélectionnée.
    if     (iDoGenerateCertifLnk = 1)
       and (iCtxUsage = REP_LIB_CONSTANT.COMPARISON) then
      lSQLCmdPrefix  :=
        lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getSqmCertificationGoodLinkXml(' || lcEntityName || '.GCO_GOOD_ID, ''1'', ' || iCtxUsage || ', 0, ' || iToCall
        || ')';
    end if;

    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := lSQLCmdSuffix || '     from ' || lcEntityName;
    lSQLCmdSuffix  := lSQLCmdSuffix || '          left outer join ' || lcEntityName || ' toCma';
    lSQLCmdSuffix  := lSQLCmdSuffix || '            on ' || lcEntityName || '.DIC_FAB_CONDITION_ID = toCma.DIC_FAB_CONDITION_ID';
    lSQLCmdSuffix  := lSQLCmdSuffix || '            and toCma.GCO_GOOD_ID = ' || iToGoodId;
    lSQLCmdSuffix  := lSQLCmdSuffix || '          left outer join PPS_NOMENCLATURE fromPps';
    lSQLCmdSuffix  := lSQLCmdSuffix || '            on ' || lcEntityName || '.PPS_NOMENCLATURE_ID = fromPps.PPS_NOMENCLATURE_ID';
    lSQLCmdSuffix  := lSQLCmdSuffix || '          left outer join PPS_NOMENCLATURE toPps';
    lSQLCmdSuffix  := lSQLCmdSuffix || '            on toPps.GCO_GOOD_ID = ' || iToGoodId;
    lSQLCmdSuffix  := lSQLCmdSuffix || '            and fromPps.C_TYPE_NOM = toPps.C_TYPE_NOM';
    lSQLCmdSuffix  := lSQLCmdSuffix || '            and nvl(fromPps.NOM_VERSION, 0) = nvl(toPps.NOM_VERSION, 0)';
    lSQLCmdSuffix  := lSQLCmdSuffix || '            and nvl(fromPps.DOC_RECORD_ID, 0) = nvl(toPps.DOC_RECORD_ID, 0)';
    lSQLCmdSuffix  := lSQLCmdSuffix || '    where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    lSQLCmdSuffix  := lSQLCmdSuffix || ' order by ' || lcEntityName || '.DIC_FAB_CONDITION_ID';
    -- Génération du fragment XML.
    lxData         :=
      REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                     , iEntityId        => iFromGoodId
                                     , iSQLCmdPrefix    => lSQLCmdPrefix
                                     , iSQLCmdSuffix    => lSQLCmdSuffix
                                     , iCtxUsage        => iCtxUsage
                                     , iMainCall        => iMainCall
                                     , iTableKeyValue   => lcTableKeyValue
                                     , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                      );

    if     lxData is not null
       and (iCtxUsage <> REP_LIB_CONSTANT.COMPARISON) then
      -- S'il y a des données complémentaire de fabrication, on ajoute les liens vers les homologations si l'option a été choisie.
      select XMLConcat(lxData, decode(iDoGenerateCertifLnk, 1, getSqmCertificationGoodLinkXml(iFromGoodId, '0', iCtxUsage) ) )
        into lxData
        from dual;
    end if;

    return lxData;
  end getGcoComplDataManufactureXml;

  /**
   * fonction getGcoComplDataSubcontractXml
   * Description
   *    Génération d'un fragment XML des données complémentaires de sous-traitance du bien en vue de sa synchronisation vers un autre bien
   */
  function getGcoComplDataSubcontractXml(
    iFromGoodId             in GCO_COMPL_DATA_SUBCONTRACT.GCO_GOOD_ID%type
  , iToGoodId               in GCO_COMPL_DATA_SUBCONTRACT.GCO_GOOD_ID%type
  , iDoGenerateNomenclature in number
  , iCtxUsage               in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall               in number default 0
  , iToCall                 in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_COMPL_DATA_SUBCONTRACT';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,PAC_SUPPLIER_PARTNER_ID,CSU_DEFAULT_SUBCONTRACTER,DIC_COMPLEMENTARY_DATA_ID,CSU_VALIDITY_DATE';
    lToPps                   varchar2(32767);
  begin
    /**
     * Synchronisation des données complémentaires de sous-traitance d'un produit B sur un produit A
     *
     * Gestion du lien vers la nomenclature :
     *   Cas 1 : - Le lien n'existe pas sur B (PPS_NOMENCLATURE_ID est null) et n'existe pas sur A : On supprime le lien sur A
     *   Cas 2 : - Le lien n'existe pas sur B (PPS_NOMENCLATURE_ID est null) mais existe sur A : On supprime le lien sur A
     *   Cas 3 : - Le lien existe sur B et sur A : On garde le lien existant sur A
     *           - La nomenclature liée sur A est mise à jour avec les données de la nomenclature liée sur B
     *           - Si les champs de la PK2 devaient entrer en conflit avec une autre nomenclature de A suite à ce traitement
     *             on accepte, selon directive de FBO du 28.02.2014, qu'une erreur de violation de contrainte unique soit levée.
     *   Cas 4 : - Le lien existe sur B, mais pas sur A (ex : nouvelle donnée compl. sur B) : On lie la nomenclature de A qui
     *             correspond à la nomenclature liée sur la donnée compl. de B (type, version et dossier identique).
     *           - Si cette nomenclature n'existe pas, on la crée.
     */
    lToPps         := 'decode(' || lcEntityName || '.PPS_NOMENCLATURE_ID,null,null,nvl(toCsu.PPS_NOMENCLATURE_ID,toPps.PPS_NOMENCLATURE_ID))';
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''PAC_PERSON'', ''PER_NAME'', ' || lcEntityName || '.PAC_SUPPLIER_PARTNER_ID)' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.DIC_COMPLEMENTARY_DATA_ID' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || 'to_char(' || lcEntityName || '.CSU_VALIDITY_DATE))';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(PAC_SUPPLIER_PARTNER_ID, ' || lcEntityName || '.PAC_SUPPLIER_PARTNER_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(CSU_DEFAULT_SUBCONTRACTER, ' || lcEntityName || '.CSU_DEFAULT_SUBCONTRACTER)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(DIC_COMPLEMENTARY_DATA_ID, ' || lcEntityName || '.DIC_COMPLEMENTARY_DATA_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(CSU_VALIDITY_DATE, to_char(' || lcEntityName || '.CSU_VALIDITY_DATE))';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(PPS_NOMENCLATURE_ID, ' || lToPps || ')';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';

    -- Ajout des données de la nomenclature liée si l'option est sélectionnée.
    if iDoGenerateNomenclature = 1 then
      lSQLCmdPrefix  :=
              lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getPpsCdNomenclatureXml(' || lcEntityName || '.PPS_NOMENCLATURE_ID,' || lToPps || ',' || iCtxUsage || ')';
    end if;

    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := lSQLCmdSuffix || '  from ' || lcEntityName;
    lSQLCmdSuffix  := lSQLCmdSuffix || '       left outer join ' || lcEntityName || ' toCsu';
    lSQLCmdSuffix  := lSQLCmdSuffix || '         on nvl(' || lcEntityName || '.PAC_SUPPLIER_PARTNER_ID, 0) = nvl(toCsu.PAC_SUPPLIER_PARTNER_ID, 0)';
    lSQLCmdSuffix  := lSQLCmdSuffix || '         and nvl(' || lcEntityName || '.CSU_DEFAULT_SUBCONTRACTER, 0) = nvl(toCsu.CSU_DEFAULT_SUBCONTRACTER, 0)';
    lSQLCmdSuffix  := lSQLCmdSuffix || '         and nvl(' || lcEntityName || '.DIC_COMPLEMENTARY_DATA_ID, 0) = nvl(toCsu.DIC_COMPLEMENTARY_DATA_ID, 0)';
    lSQLCmdSuffix  := lSQLCmdSuffix || '         and nvl(' || lcEntityName || '.CSU_VALIDITY_DATE, '''') = nvl(toCsu.CSU_VALIDITY_DATE, '''')';
    lSQLCmdSuffix  := lSQLCmdSuffix || '         and toCsu.GCO_GOOD_ID = ' || iToGoodId;
    lSQLCmdSuffix  := lSQLCmdSuffix || ' left outer join PPS_NOMENCLATURE fromPps on ' || lcEntityName || '.PPS_NOMENCLATURE_ID = fromPps.PPS_NOMENCLATURE_ID';
    lSQLCmdSuffix  := lSQLCmdSuffix || '       left outer join PPS_NOMENCLATURE toPps';
    lSQLCmdSuffix  := lSQLCmdSuffix || '         on toPps.GCO_GOOD_ID = ' || iToGoodId;
    lSQLCmdSuffix  := lSQLCmdSuffix || '         and fromPps.C_TYPE_NOM = toPps.C_TYPE_NOM';
    lSQLCmdSuffix  := lSQLCmdSuffix || '         and nvl(fromPps.NOM_VERSION, 0) = nvl(toPps.NOM_VERSION, 0)';
    lSQLCmdSuffix  := lSQLCmdSuffix || '         and nvl(fromPps.DOC_RECORD_ID, 0) = nvl(toPps.DOC_RECORD_ID, 0)';
    lSQLCmdSuffix  := lSQLCmdSuffix || ' where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iFromGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getGcoComplDataSubcontractXml;

  /**
   * fonction getGcoGoodAttributeXml
   * Description
   *    Génération d'un fragment XML des attributs du bien en vue de sa synchronisation vers un autre bien
   */
  function getGcoGoodAttributeXml(
    iGoodId   in GCO_GOOD_ATTRIBUTE.GCO_GOOD_ID%type
  , iCtxUsage in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_GOOD_ATTRIBUTE';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iIsList          => 0
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                           );
  end getGcoGoodAttributeXml;

  /**
   * fonction getGcoComplDataDistribXml
   * Description
   *    Génération d'un fragment XML des données complémentaires de distribution du bien en vue de sa synchronisation vers un autre bien
   */
  function getGcoComplDataDistribXml(
    iGoodId   in GCO_COMPL_DATA_DISTRIB.GCO_GOOD_ID%type
  , iCtxUsage in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_COMPL_DATA_DISTRIB';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,GCO_PRODUCT_GROUP_ID,STM_DISTRIBUTION_UNIT_ID,DIC_DISTRIB_COMPL_DATA_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_PRODUCT_GROUP'', ''PRG_NAME'', ' || lcEntityName || '.GCO_PRODUCT_GROUP_ID)' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''STM_DISTRIBUTION_UNIT'', ''DIU_NAME'', ' || lcEntityName || '.STM_DISTRIBUTION_UNIT_ID)' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.DIC_DISTRIB_COMPL_DATA_ID)';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(GCO_PRODUCT_GROUP_ID, ' || lcEntityName || '.GCO_PRODUCT_GROUP_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(STM_DISTRIBUTION_UNIT_ID, ' || lcEntityName || '.STM_DISTRIBUTION_UNIT_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(DIC_DISTRIB_COMPL_DATA_ID, ' || lcEntityName || '.DIC_DISTRIB_COMPL_DATA_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getGcoComplDataDistribXml;

  /**
   * fonction getSqmCertificationGoodLinkXml
   * Description
   *    Génération d'un fragment XML des liens vers les homologations du bien en vue de sa synchronisation vers un autre bien
   */
  function getSqmCertificationGoodLinkXml(
    iGoodId         in GCO_GOOD_ATTRIBUTE.GCO_GOOD_ID%type
  , iCertifProperty in SQM_CERTIFICATION.C_CERTIFICATION_PROPERTY%type
  , iCtxUsage       in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall       in number default 0
  , iToCall         in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'SQM_CERTIFICATION_S_GOOD';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,SQM_CERTIFICATION_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(SQM_CERTIFICATION_ID, ' || lcEntityName || '.SQM_CERTIFICATION_ID)';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''SQM_CERTIFICATION'', ''CER_NUMBER'', SQM_CERTIFICATION.SQM_CERTIFICATION_ID))';
    end if;

    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := ' from ' || lcEntityName || ', SQM_CERTIFICATION ';
    lSQLCmdSuffix  := lSQLCmdSuffix || 'where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    lSQLCmdSuffix  := lSQLCmdSuffix || '  and ' || lcEntityName || '.SQM_CERTIFICATION_ID = SQM_CERTIFICATION.SQM_CERTIFICATION_ID';
    lSQLCmdSuffix  := lSQLCmdSuffix || '  and SQM_CERTIFICATION.C_CERTIFICATION_PROPERTY = ''' || iCertifProperty || '''';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                           );
  end getSqmCertificationGoodLinkXml;

  /**
   * fonction getGcoCoupledGoodXml
   * Description
   *    Génération d'un fragment XML des produits couplés de la donnée compl. de fabrication du bien en vue de sa synchronisation vers un autre bien
   */
  function getGcoCoupledGoodXml(
    iComplDataManufactureId in GCO_COUPLED_GOOD.GCO_COMPL_DATA_MANUFACTURE_ID%type
  , iCtxUsage               in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall               in number default 0
  , iToCall                 in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_COUPLED_GOOD';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,GCO_GCO_GOOD_ID,GCO_COMPL_DATA_MANUFACTURE_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GCO_GOOD_ID))';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(GCO_GCO_GOOD_ID, ' || lcEntityName || '.GCO_GCO_GOOD_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_COMPL_DATA_MANUFACTURE_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iComplDataManufactureId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getGcoCoupledGoodXml;

  /**
   * fonction getPtcFixedCostpriceXml
   * Description
   *    Génération d'un fragment XML des prix de revient fixes du bien en vue de sa synchronisation vers un autre bien
   */
  function getPtcFixedCostpriceXml(
    iGoodId   in PTC_FIXED_COSTPRICE.GCO_GOOD_ID%type
  , iCtxUsage in REP_LIB_CONSTANT.T_CONTEXT_USAGE default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'PTC_FIXED_COSTPRICE';
    lcTableKeyValue constant varchar2(32767)
                 := 'GCO_GOOD_ID,CPR_DEFAULT,C_COSTPRICE_STATUS,DIC_FIXED_COSTPRICE_DESCR_ID,CPR_DESCR,PAC_THIRD_ID,FCP_START_DATE,FCP_END_DATE,CPR_HISTORY_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetCDe || '(''C_COSTPRICE_STATUS'', ' || lcEntityName || '.C_COSTPRICE_STATUS)' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.DIC_FIXED_COSTPRICE_DESCR_ID' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.CPR_DESCR' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''PAC_PERSON'', ''PER_NAME'', ' || lcEntityName || '.PAC_THIRD_ID)' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || 'to_char(' || lcEntityName || '.FCP_START_DATE)' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || 'to_char(' || lcEntityName || '.FCP_END_DATE)' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.CPR_HISTORY_ID)';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(CPR_DEFAULT, ' || lcEntityName || '.CPR_DEFAULT)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(C_COSTPRICE_STATUS, ' || lcEntityName || '.C_COSTPRICE_STATUS)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(DIC_FIXED_COSTPRICE_DESCR_ID, ' || lcEntityName || '.DIC_FIXED_COSTPRICE_DESCR_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(CPR_DESCR, ' || lcEntityName || '.CPR_DESCR)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(PAC_THIRD_ID, ' || lcEntityName || '.PAC_THIRD_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(FCP_START_DATE, to_char(' || lcEntityName || '.FCP_START_DATE))';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(FCP_END_DATE, to_char(' || lcEntityName || '.FCP_END_DATE))';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(CPR_HISTORY_ID, ' || lcEntityName || '.CPR_HISTORY_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getPtcFixedCostpriceXml;

  /**
   * fonction getPtcCalcCostpriceXml
   * Description
   *    Génération d'un fragment XML des prix de revient calculés du bien en vue de sa synchronisation vers un autre bien
   */
  function getPtcCalcCostpriceXml(
    iGoodId   in PTC_CALC_COSTPRICE.GCO_GOOD_ID%type
  , iCtxUsage in REP_LIB_CONSTANT.T_CONTEXT_USAGE default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'PTC_CALC_COSTPRICE';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,CPR_DEFAULT,C_COSTPRICE_STATUS,DIC_CALC_COSTPRICE_DESCR_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetCDe || '(''C_COSTPRICE_STATUS'', ' || lcEntityName || '.C_COSTPRICE_STATUS)' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.DIC_CALC_COSTPRICE_DESCR_ID)';
    end if;

--     lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(GCO_GOOD_ID, ' || lcEntityName || '.GCO_GOOD_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(CPR_DEFAULT, ' || lcEntityName || '.CPR_DEFAULT)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(C_COSTPRICE_STATUS, ' || lcEntityName || '.C_COSTPRICE_STATUS)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(DIC_CALC_COSTPRICE_DESCR_ID, ' || lcEntityName || '.DIC_CALC_COSTPRICE_DESCR_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(CPR_DESCR, ' || lcEntityName || '.CPR_DESCR)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(PAC_THIRD_ID, ' || lcEntityName || '.PAC_THIRD_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(C_UPDATE_CYCLE, ' || lcEntityName || '.C_UPDATE_CYCLE)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getPtcPrcStockMvtXml(' || lcEntityName || '_ID, ' || iCtxUsage || ', 0, ' || iToCall || ')';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getPtcCalcCostpriceXml;

  /**
   * fonction getPtcCalcCostpriceXml
   * Description
   *    Génération d'un fragment XML des liens entre les PRC et les mvts de stock du bien en vue de sa synchronisation vers un autre bien
   */
  function getPtcPrcStockMvtXml(
    iPtcCalCostpriceId in PTC_PRC_S_STOCK_MVT.PTC_CALC_COSTPRICE_ID%type
  , iCtxUsage          in REP_LIB_CONSTANT.T_CONTEXT_USAGE default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall          in number default 0
  , iToCall            in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'PTC_PRC_S_STOCK_MVT';
    lcTableKeyValue constant varchar2(32767) := 'PTC_CALC_COSTPRICE_ID,STM_MOVEMENT_KIND_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';
      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''STM_MOVEMENT_KIND'', ''MOK_ABBREVIATION'', ' || lcEntityName || '.STM_MOVEMENT_KIND_ID))';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(STM_MOVEMENT_KIND_ID, ' || lcEntityName || '.STM_MOVEMENT_KIND_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.PTC_CALC_COSTPRICE_ID = :PTC_CALC_COSTPRICE_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iPtcCalCostpriceId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                           );
  end getPtcPrcStockMvtXml;

  /**
   * fonction getPtcTariffXml
   * Description
   *    Génération d'un fragment XML des tarifs du bien en vue de sa synchronisation vers un autre bien
   */
  function getPtcTariffXml(
    iGoodId   in PTC_TARIFF.GCO_GOOD_ID%type
  , iCtxUsage in REP_LIB_CONSTANT.T_CONTEXT_USAGE default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'PTC_TARIFF';
    lcTableKeyValue constant varchar2(32767)
      := 'GCO_GOOD_ID,DIC_TARIFF_ID,PAC_THIRD_ID,TRF_DESCR,ACS_FINANCIAL_CURRENCY_ID,C_TARIFF_TYPE,C_TARIFFICATION_MODE,DIC_PUR_TARIFF_STRUCT_ID,DIC_SALE_TARIFF_STRUCT_ID,TRF_STARTING_DATE,TRF_ENDING_DATE';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.DIC_TARIFF_ID' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.TRF_DESCR' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''PAC_PERSON'', ''PER_NAME'', ' || lcEntityName || '.PAC_THIRD_ID)' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetCDe || '(''C_TARIFF_TYPE'', ' || lcEntityName || '.C_TARIFF_TYPE)' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetCDe || '(''C_TARIFFICATION_MODE'', ' || lcEntityName || '.C_TARIFFICATION_MODE)' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.DIC_PUR_TARIFF_STRUCT_ID' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.DIC_SALE_TARIFF_STRUCT_ID' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || 'to_char(' || lcEntityName || '.TRF_STARTING_DATE)' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || 'to_char(' || lcEntityName || '.TRF_ENDING_DATE))';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(DIC_TARIFF_ID, ' || lcEntityName || '.DIC_TARIFF_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(PAC_THIRD_ID, ' || lcEntityName || '.PAC_THIRD_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(TRF_DESCR, ' || lcEntityName || '.TRF_DESCR)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(ACS_FINANCIAL_CURRENCY_ID, ' || lcEntityName || '.ACS_FINANCIAL_CURRENCY_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(C_TARIFF_TYPE, ' || lcEntityName || '.C_TARIFF_TYPE)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(C_TARIFFICATION_MODE, ' || lcEntityName || '.C_TARIFFICATION_MODE)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(DIC_PUR_TARIFF_STRUCT_ID, ' || lcEntityName || '.DIC_PUR_TARIFF_STRUCT_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(DIC_SALE_TARIFF_STRUCT_ID, ' || lcEntityName || '.DIC_SALE_TARIFF_STRUCT_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(TRF_STARTING_DATE, to_char(' || lcEntityName || '.TRF_STARTING_DATE))';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(TRF_ENDING_DATE, to_char(' || lcEntityName || '.TRF_ENDING_DATE))';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getPtcTariffTableXml(' || lcEntityName || '_ID, ' || iCtxUsage || ', 0, ' || iToCall || ')';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getPtcTariffXml;

  /**
   * fonction getPtcTariffTableXml
   * Description
   *    Génération d'un fragment XML des Copie des Tabelles pour les tarifs du bien en vue de sa synchronisation vers un autre bien
   */
  function getPtcTariffTableXml(
    iTarifId  in PTC_TARIFF_TABLE.PTC_TARIFF_ID%type
  , iCtxUsage in REP_LIB_CONSTANT.T_CONTEXT_USAGE default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'PTC_TARIFF_TABLE';
    lcTableKeyValue constant varchar2(32767) := 'PTC_TARIFF_ID,TTA_FROM_QUANTITY';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';
      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.TTA_FROM_QUANTITY)';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.PTC_TARIFF_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iTarifId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getPtcTariffTableXml;

  /**
   * fonction getPtcDiscountGoodLinkXml
   * Description
   *    Génération d'un fragment XML des remises du bien en vue de sa synchronisation vers un autre bien
   */
  function getPtcDiscountGoodLinkXml(
    iGoodId   in PTC_DISCOUNT_S_GOOD.GCO_GOOD_ID%type
  , iCtxUsage in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'PTC_DISCOUNT_S_GOOD';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,PTC_DISCOUNT_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''PTC_DISCOUNT'', ''DNT_NAME'', ' || lcEntityName || '.PTC_DISCOUNT_ID))';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(PTC_DISCOUNT_ID, ' || lcEntityName || '.PTC_DISCOUNT_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                           );
  end getPtcDiscountGoodLinkXml;

  /**
   * fonction getPtcChargeGoodLinkXml
   * Description
   *    Génération d'un fragment XML des taxes du bien en vue de sa synchronisation vers un autre bien
   */
  function getPtcChargeGoodLinkXml(
    iGoodId   in PTC_CHARGE_S_GOODS.GCO_GOOD_ID%type
  , iCtxUsage in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'PTC_CHARGE_S_GOODS';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,PTC_CHARGE_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''PTC_CHARGE'', ''CRG_NAME'', ' || lcEntityName || '.PTC_CHARGE_ID))';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(PTC_CHARGE_ID, ' || lcEntityName || '.PTC_CHARGE_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                           );
  end getPtcChargeGoodLinkXml;

  /**
   * fonction getGcoPreciousMatXml
   * Description
   *    Génération d'un fragment XML des matières précieuses du bien en vue de sa synchronisation vers un autre bien
   */
  function getGcoPreciousMatXml(
    iGoodId   in GCO_PRECIOUS_MAT.GCO_GOOD_ID%type
  , iCtxUsage in REP_LIB_CONSTANT.T_CONTEXT_USAGE default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_PRECIOUS_MAT';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,GCO_ALLOY_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_ALLOY'', ''GAL_ALLOY_REF'', ' || lcEntityName || '.GCO_ALLOY_ID))';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(GCO_ALLOY_ID, ' || lcEntityName || '.GCO_ALLOY_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getGcoPreciousMatXml;

  /**
   * fonction getGcoConnectedGoodXml
   * Description
   *    Génération d'un fragment XML des corrélations du bien en vue de sa synchronisation vers un autre bien
   */
  function getGcoConnectedGoodXml(
    iGoodId   in GCO_CONNECTED_GOOD.GCO_GOOD_ID%type
  , iCtxUsage in REP_LIB_CONSTANT.T_CONTEXT_USAGE default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_CONNECTED_GOOD';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,GCO_GCO_GOOD_ID,DIC_CONNECTED_TYPE_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GCO_GOOD_ID)' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.DIC_CONNECTED_TYPE_ID)';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(GCO_GCO_GOOD_ID, ' || lcEntityName || '.GCO_GCO_GOOD_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(DIC_CONNECTED_TYPE_ID, ' || lcEntityName || '.DIC_CONNECTED_TYPE_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getGcoConnectedGoodXml;

  /**
   * fonction getGcoFreeDataXml
   * Description
   *    Génération d'un fragment XML des données libres du bien en vue de sa synchronisation vers un autre bien
   */
  function getGcoFreeDataXml(
    iGoodId   in GCO_FREE_DATA.GCO_GOOD_ID%type
  , iCtxUsage in REP_LIB_CONSTANT.T_CONTEXT_USAGE default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_FREE_DATA';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID';
    lxData                   xmltype;
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';

    if (iCtxUsage = REP_LIB_CONSTANT.COMPARISON) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getGcoFreeCodeXml(GCO_GOOD_ID, ' || iCtxUsage || ', 0, ' || iToCall || ')';
    end if;

    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    lxData         :=
      REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                     , iEntityId        => iGoodId
                                     , iSQLCmdPrefix    => lSQLCmdPrefix
                                     , iSQLCmdSuffix    => lSQLCmdSuffix
                                     , iCtxUsage        => iCtxUsage
                                     , iMainCall        => iMainCall
                                     , iTableKeyValue   => lcTableKeyValue
                                     , iIsList          => 0
                                     , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                      );

    if     lxData is not null
       and (iCtxUsage <> REP_LIB_CONSTANT.COMPARISON) then
      -- Ajout des codes libres.
      select XMLConcat(lxData, getGcoFreeCodeXml(iGoodId, iCtxUsage, iMainCall) )
        into lxData
        from dual;
    end if;

    return lxData;
  end getGcoFreeDataXml;

  /**
   * fonction getGcoFreeCodeXml
   * Description
   *    Génération d'un fragment XML des codes libres du bien en vue de sa synchronisation vers un autre bien
   */
  function getGcoFreeCodeXml(
    iGoodId   in GCO_FREE_CODE.GCO_GOOD_ID%type
  , iCtxUsage in REP_LIB_CONSTANT.T_CONTEXT_USAGE default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'GCO_FREE_CODE';
    lcTableKeyValue constant varchar2(32767)
      := 'GCO_GOOD_ID,DIC_GCO_BOOLEAN_CODE_TYPE_ID,DIC_GCO_CHAR_CODE_TYPE_ID,DIC_GCO_DATE_CODE_TYPE_ID,DIC_GCO_NUMBER_CODE_TYPE_ID,DIC_GCO_MEMO_CODE_TYPE_ID,FCO_BOO_CODE,FCO_CHA_CODE,FCO_DAT_CODE,FCO_NUM_CODE,FCO_MEM_CODE';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';
    -- Les champs ci-dessous de la "PK2" ne doivent pas être ajoutés manuellement car aucun index unique n'est défini sur eux. Ils
    -- seront donc automatiquement ajoutés par la méthode REP_LIB_ECC_XML.getSyncEntityXml. Autre possibilités : les ajouter dans
    -- la liste des exceptions pour cette table et les laisser ici. Peut-être plus claire, a voir...
--     lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(DIC_GCO_BOOLEAN_CODE_TYPE_ID, ' || lcEntityName || '.DIC_GCO_BOOLEAN_CODE_TYPE_ID)';
--     lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(DIC_GCO_CHAR_CODE_TYPE_ID, ' || lcEntityName || '.DIC_GCO_CHAR_CODE_TYPE_ID)';
--     lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(DIC_GCO_DATE_CODE_TYPE_ID, ' || lcEntityName || '.DIC_GCO_DATE_CODE_TYPE_ID)';
--     lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(DIC_GCO_NUMBER_CODE_TYPE_ID, ' || lcEntityName || '.DIC_GCO_NUMBER_CODE_TYPE_ID)';
--     lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(DIC_GCO_MEMO_CODE_TYPE_ID, ' || lcEntityName || '.DIC_GCO_MEMO_CODE_TYPE_ID)';
--     lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(FCO_BOO_CODE, ' || lcEntityName || '.FCO_BOO_CODE)';
--     lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(FCO_CHA_CODE, ' || lcEntityName || '.FCO_CHA_CODE)';
--     lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(FCO_DAT_CODE, ' || lcEntityName || '.FCO_DAT_CODE)';
--     lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(FCO_NUM_CODE, ' || lcEntityName || '.FCO_NUM_CODE)';
--     lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(FCO_MEM_CODE, ' || lcEntityName || '.FCO_MEM_CODE)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getGcoFreeCodeXml;

  /**
   * fonction getPpsToolXml
   * Description
   *    Génération d'un fragment XML de l'outils du bien en vue de sa synchronisation vers un autre bien
   */
  function getPpsToolXml(
    iGoodId                 in PPS_TOOLS.GCO_GOOD_ID%type
  , iDoGenerateSpecialTools in number
  , iCtxUsage               in REP_LIB_CONSTANT.T_CONTEXT_USAGE default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall               in number default 0
  , iToCall                 in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'PPS_TOOLS';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID';
    lxData                   xmltype;
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    if     (iDoGenerateSpecialTools = 1)
       and (iCtxUsage = REP_LIB_CONSTANT.COMPARISON) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getPpsSpecialToolsXml(GCO_GOOD_ID, ' || iCtxUsage || ', 0, ' || iToCall || ')';
    end if;

    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    lxData         :=
      REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                     , iEntityId        => iGoodId
                                     , iSQLCmdPrefix    => lSQLCmdPrefix
                                     , iSQLCmdSuffix    => lSQLCmdSuffix
                                     , iCtxUsage        => iCtxUsage
                                     , iMainCall        => iMainCall
                                     , iTableKeyValue   => lcTableKeyValue
                                     , iIsList          => 0
                                      );

    -- Ajout des outils spéciaux si l'option est sélectionée.
    if     lxData is not null
       and (iCtxUsage <> REP_LIB_CONSTANT.COMPARISON) then
      select XMLConcat(lxData, decode(iDoGenerateSpecialTools, 1, getPpsSpecialToolsXml(iGoodId, iCtxUsage, iMainCall) ) )
        into lxData
        from dual;
    end if;

    return lxData;
  end getPpsToolXml;

  /**
   * fonction getPpsSpecialToolsXml
   * Description
   *    Génération d'un fragment XML des outils spéciaux du bien en vue de sa synchronisation vers un autre bien
   */
  function getPpsSpecialToolsXml(
    iGoodId   in PPS_SPECIAL_TOOLS.GCO_GOOD_ID%type
  , iCtxUsage in REP_LIB_CONSTANT.T_CONTEXT_USAGE default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  , iToCall   in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'PPS_SPECIAL_TOOLS';
    lcTableKeyValue constant varchar2(32767) := 'GCO_GOOD_ID,SPT_REFERENCE';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';

      if pcShowReference then
        lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.SPT_REFERENCE)';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(SPT_REFERENCE, ' || lcEntityName || '.SPT_REFERENCE)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.GCO_GOOD_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGoodId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getPpsSpecialToolsXml;

  /**
  * fonction getPpsCdNomenclatureXml
  * Description
  *    Génération d'un fragment XML de la nomenclature liée à une donnée complémentaire (fabrication ou sous-traitance)
  *    du bien en vue de sa synchronisation vers un autre bien
  */
  function getPpsCdNomenclatureXml(
    iFromCdNomenclatureId in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , iToCdNomenclatureId   in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , iCtxUsage             in REP_LIB_CONSTANT.T_CONTEXT_USAGE default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall             in number default 0
  , iToCall               in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'PPS_NOMENCLATURE';
    lcTableKeyValue constant varchar2(32767) := lcEntityName || '_ID';
    lxData                   xmltype;
  begin
    if iFromCdNomenclatureId is null then
      return null;
    end if;

    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';
      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.NOM_VERSION' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetCDe || '(''C_TYPE_NOM'', ' || lcEntityName || '.C_TYPE_NOM)' || pcSepPK2;
      -- Attention, a voir si c'est utile de distinguer les nomemclatures avec le dossier. Actuellement il y a un risque d'exception car la PK2 est composée
      -- de RCO_TITLE et DOC_PROJECT_DOCUMENT_ID. Une adaptation de la réplication pour ajouter le champ DOC_PROJECT_DOCUMENT_ID est nécessaire.
      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''DOC_RECORD'', ''RCO_TITLE'', ' || lcEntityName || '.DOC_RECORD_ID))';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ''' || iToCdNomenclatureId || ''')';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(NOM_VERSION, ' || lcEntityName || '.NOM_VERSION)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(DOC_RECORD_ID, ' || lcEntityName || '.DOC_RECORD_ID)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(C_TYPE_NOM, ' || lcEntityName || '.C_TYPE_NOM)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getPpsMarkBondXml(' || lcEntityName || '_ID, ' || iCtxUsage || ')';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getPpsNomBondXml(' || lcEntityName || '_ID, ' || iCtxUsage || ')';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.' || lcEntityName || '_ID = :ENTITY_ID';

    -- Génération du fragment XML.
    select XMLConcat(lxData
                   , REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                                    , iEntityId        => iFromCdNomenclatureId
                                                    , iSQLCmdPrefix    => lSQLCmdPrefix
                                                    , iSQLCmdSuffix    => lSQLCmdSuffix
                                                    , iCtxUsage        => iCtxUsage
                                                    , iMainCall        => iMainCall
                                                    , iTableKeyValue   => lcTableKeyValue
                                                    , iIsList          => 0
                                                     )
                    )
      into lxData
      from dual;

    return lxData;
  end getPpsCdNomenclatureXml;

  /*
  * fonction getPpsConfigurablePdtXml
  * Description
  *    Génération d'un fragment XML des repères topologiques de la nomenclature du bien en vue de sa synchronisation vers un autre bien
  */
  function getPpsMarkBondXml(
    iNomenclatureId in PPS_MARK_BOND.PPS_NOMENCLATURE_ID%type
  , iCtxUsage       in REP_LIB_CONSTANT.T_CONTEXT_USAGE default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall       in number default 0
  , iToCall         in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'PPS_MARK_BOND';
    lcTableKeyValue constant varchar2(32767) := 'PPS_NOMENCLATURE_ID,PMB_PREFIX,PMB_NUMBER,PMB_SUFFIX';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';
      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.PMB_PREFIX' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.PMB_NUMBER' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.PMB_SUFFIX)';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(PMB_PREFIX, ' || lcEntityName || '.PMB_PREFIX)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(PMB_NUMBER, ' || lcEntityName || '.PMB_NUMBER)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(PMB_SUFFIX, ' || lcEntityName || '.PMB_SUFFIX)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.PPS_NOMENCLATURE_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iNomenclatureId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getPpsMarkBondXml;

  /**
  * fonction getPpsNomBondXml
  * Description
  *    Génération d'un fragment XML des composants de la nomenclature du bien en vue de sa synchronisation vers un autre bien
  */
  function getPpsNomBondXml(
    iNomenclatureId in PPS_NOM_BOND.PPS_NOMENCLATURE_ID%type
  , iCtxUsage       in REP_LIB_CONSTANT.T_CONTEXT_USAGE default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall       in number default 0
  , iToCall         in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'PPS_NOM_BOND';
    lcTableKeyValue constant varchar2(32767) := 'PPS_NOMENCLATURE_ID,COM_SEQ';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';
      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''GCO_GOOD'', ''GOO_MAJOR_REFERENCE'', ' || lcEntityName || '.GCO_GOOD_ID)' || pcSepPK2;
      lSQLCmdPrefix  := lSQLCmdPrefix || lcEntityName || '.COM_SEQ)';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(COM_SEQ, ' || lcEntityName || '.COM_SEQ)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.PPS_NOMENCLATURE_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iNomenclatureId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getPpsNomBondXml;

  /**
  * fonction getFalCdSchedulePlanXml
  * Description
  *    Génération d'un fragment XML de la gamme opératoire liée à une donnée complémentaire de fabrication du bien en vue de sa synchronisation vers un autre bien
  */
  function getFalCdSchedulePlanXml(
    iGcoComplDataManufactureId in GCO_COMPL_DATA_MANUFACTURE.GCO_COMPL_DATA_MANUFACTURE_ID%type
  , iToGoodId                  in GCO_COMPL_DATA_MANUFACTURE.GCO_GOOD_ID%type
  , iCtxUsage                  in REP_LIB_CONSTANT.T_CONTEXT_USAGE default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall                  in number default 0
  , iToCall                    in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'FAL_SCHEDULE_PLAN';
    lcTableKeyValue constant varchar2(32767) := 'SCH_REF';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY, toSch.SCH_REF)';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(SCH_REF, toSch.SCH_REF)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    lSQLCmdPrefix  :=
      lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getFalListStepLinkXml(' || lcEntityName || '.' || lcEntityName || '_ID,' || iCtxUsage || ', 0, ' || iToCall || ')';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := lSQLCmdSuffix || '  from ' || lcEntityName;
    lSQLCmdSuffix  := lSQLCmdSuffix || '     , GCO_COMPL_DATA_MANUFACTURE fromCma';
    lSQLCmdSuffix  := lSQLCmdSuffix || '     , ' || lcEntityName || ' toSch';
    lSQLCmdSuffix  := lSQLCmdSuffix || '     , GCO_COMPL_DATA_MANUFACTURE toCma';
    lSQLCmdSuffix  := lSQLCmdSuffix || ' where fromCma.' || lcEntityName || '_ID = ' || lcEntityName || '.' || lcEntityName || '_ID';
    lSQLCmdSuffix  := lSQLCmdSuffix || '   and fromCma.GCO_COMPL_DATA_MANUFACTURE_ID = :ENTITY_ID';
    lSQLCmdSuffix  := lSQLCmdSuffix || '   and toCma.' || lcEntityName || '_ID = toSch.' || lcEntityName || '_ID';
    lSQLCmdSuffix  := lSQLCmdSuffix || '   and toCma.GCO_GOOD_ID = ' || iToGoodId;
    lSQLCmdSuffix  := lSQLCmdSuffix || '   and fromCma.DIC_FAB_CONDITION_ID = toCma.DIC_FAB_CONDITION_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iGcoComplDataManufactureId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iIsList          => 0
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getFalCdSchedulePlanXml;

  /**
  * fonction getFalListStepLinkXml
  * Description
  *    Génération d'un fragment XML des opérations d'une gamme opératoire en vue d'une synchronisation vers une autre gamme.
  */
  function getFalListStepLinkXml(
    iSchedulePlanId in FAL_LIST_STEP_LINK.FAL_SCHEDULE_PLAN_ID%type
  , iCtxUsage       in REP_LIB_CONSTANT.T_CONTEXT_USAGE default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall       in number default 0
  , iToCall         in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'FAL_LIST_STEP_LINK';
    lcTableKeyValue constant varchar2(32767) := 'FAL_SCHEDULE_PLAN_ID,SCS_STEP_NUMBER';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,' || lcEntityName || '.SCS_STEP_NUMBER)';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(SCS_STEP_NUMBER, ' || lcEntityName || '.SCS_STEP_NUMBER)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    lSQLCmdPrefix  :=
            lSQLCmdPrefix || ', REP_LIB_GCO_ECC_XML.getFalListStepUseXml(' || lcEntityName || '.FAL_SCHEDULE_STEP_ID,' || iCtxUsage || ', 0, ' || iToCall || ')';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.FAL_SCHEDULE_PLAN_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName      => lcEntityName
                                          , iEntityId        => iSchedulePlanId
                                          , iSQLCmdPrefix    => lSQLCmdPrefix
                                          , iSQLCmdSuffix    => lSQLCmdSuffix
                                          , iCtxUsage        => iCtxUsage
                                          , iMainCall        => iMainCall
                                          , iTableKeyValue   => lcTableKeyValue
                                          , iOrderByClause   => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getFalListStepLinkXml;

  /**
  * fonction getFalListStepUseXml
  * Description
  *    Génération d'un fragment XML des machines utilsables (LMU) d'une opération d'une gamme opératoire en vue d'une synchronisation vers une autre gamme.
  */
  function getFalListStepUseXml(
    iScheduleStepId in FAL_LIST_STEP_USE.FAL_SCHEDULE_STEP_ID%type
  , iCtxUsage       in REP_LIB_CONSTANT.T_CONTEXT_USAGE default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall       in number default 0
  , iToCall         in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'FAL_LIST_STEP_USE';
    lcTableKeyValue constant varchar2(32767) := 'FAL_SCHEDULE_STEP_ID,FAL_FACTORY_FLOOR_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';

    -- Construit la clé d'identification de l'enregistrement
    if     (iCtxUsage = REP_LIB_CONSTANT.COMPARISON)
       and (iToCall = 0) then
      lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VALUE_KEY,';
      lSQLCmdPrefix  := lSQLCmdPrefix || pcGetPK2 || '(''FAL_FACTORY_FLOOR'', ''FAC_REFERENCE'', ' || lcEntityName || '.FAL_FACTORY_FLOOR_ID))';
    end if;

    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.FAL_SCHEDULE_STEP_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName          => lcEntityName
                                          , iEntityId            => iScheduleStepId
                                          , iSQLCmdPrefix        => lSQLCmdPrefix
                                          , iSQLCmdSuffix        => lSQLCmdSuffix
                                          , iCtxUsage            => iCtxUsage
                                          , iMainCall            => iMainCall
                                          , iTableKeyValue       => lcTableKeyValue
                                          , iTableMappingValue   => 'FAL_SCHEDULE_STEP_ID=FAL_LIST_STEP_LINK_ID'
                                          , iOrderByClause       => lcEntityName || '.' || lcEntityName || '_ID'
                                           );
  end getFalListStepUseXml;
end REP_LIB_GCO_ECC_XML;
