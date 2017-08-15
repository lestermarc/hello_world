--------------------------------------------------------
--  DDL for Package Body REP_LIB_ECC_XML
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REP_LIB_ECC_XML" 
is
  /**
  * fonction pGetEntityCCXmlType
  * Description
  *    Fonction d'encapsulation d'un document XML d'une entité en vue d'une synchronisation
  * @created  age 13.02.2014
  * @lastUpdate
  * @private
  * @param iEntityXML : Document XML de l'entité à synchroniser
  * @return Document XML prêt à être synchronisé.
  */
  function pGetEntityCCXmlType(iEntityXML in xmltype)
    return xmltype
  as
    lxData xmltype;
  begin
    -- Générer le tag principal uniquement s'il y a données
    if (iEntityXML is not null) then
      select XMLElement("EntityCC", XMLAttributes(1.0 as "version"), xmlcomment(REP_UTILS.GetCreationContext), iEntityXML)
        into lxData
        from dual;

      return lxData;
    end if;

    return null;
  end pGetEntityCCXmlType;

  /**
  * fonction pInitSQLCmdPrefix
  * Description
  *    Initialise le préfixe de la commande SQL de génération
  * @created  age 24.02.2014
  * @lastUpdate age 07.03.2014
  * @private
  * @param iEntityName : Nom de l'entité à synchroniser
  * @param iCtxUsage   : Contexte d'utilisation de l'XML.
  * @param iMainCall   : Indique s'il s'agit de l'appel principale de la génération de l'XML.
  * @param iListItem   : Définit si l'entité est multivaluée (1) ou non (0)
  * @return Document XML prêt à être synchronisé.
  */
  function pInitSQLCmdPrefix(
    iEntityName in varchar2
  , iCtxUsage   in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall   in number default 0
  , iListItem   in number default 1
  )
    return varchar2
  as
    lSQLCmdPrefix varchar2(32767);
  begin
    lSQLCmdPrefix  := 'select ';

    if iCtxUsage = REP_LIB_CONSTANT.COMPARISON then
      if iMainCall = 1 then
        lSQLCmdPrefix  := lSQLCmdPrefix || 'XMLElement(' || iEntityName || ',';
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || 'XMLAgg(XMLElement(' || iEntityName || ', XMLConcat(';
    else
      if iListItem = 1 then
        lSQLCmdPrefix  := lSQLCmdPrefix || 'XMLAgg(XMLElement(LIST_ITEM ,';
      end if;

      lSQLCmdPrefix  := lSQLCmdPrefix || 'XMLConcat(';
    end if;

    return lSQLCmdPrefix;
  end pInitSQLCmdPrefix;

  /**
  * fonction pInitSQLCmdSuffix
  * Description
  *    Initialise le suffixe de la commande SQL de génération
  * @created  age 24.02.2014
  * @lastUpdate age 07.03.2014
  * @private
  * @param iCtxUsage : Contexte d'utilisation de l'XML.
  * @param iMainCall : Indique s'il s'agit de l'appel principale de la génération de l'XML.
  * @param iListItem : Définit si l'entité est multivaluée (1) ou non (0)
  * @return Document XML prêt à être synchronisé.
  */
  function pInitSQLCmdSuffix(
    iCtxUsage      in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall      in number default 0
  , iListItem      in number default 1
  , iOrderByClause in varchar2
  )
    return varchar2
  as
    lSQLCmdPrefix varchar2(32767);
  begin
    if iCtxUsage = REP_LIB_CONSTANT.COMPARISON then
      lSQLCmdPrefix  := lSQLCmdPrefix || ')) order by ' || iOrderByClause || ') ';   --'XMLAgg(XMLElement(' || iEntityName || ', XMLConcat(';

      if iMainCall = 1 then
        lSQLCmdPrefix  := lSQLCmdPrefix || ') ';   --XMLElement(
      end if;
    else
      lSQLCmdPrefix  := lSQLCmdPrefix || ') ';   --'XMLConcat('

      if iListItem = 1 then
        lSQLCmdPrefix  := lSQLCmdPrefix || ') order by ' || iOrderByClause || ') ';   --'XMLAgg(XMLElement(LIST_ITEM , ';
      end if;
    end if;

    return lSQLCmdPrefix;
  end pInitSQLCmdSuffix;

  /**
  * fonction getSyncEntityXml
  * Description
  *    Construction de l'instruction SQL retournant l'XML de la liste des champs de l'entité à synchroniser.
  */
  function getSyncEntityXml(
    iEntityName        in varchar2
  , iEntityId          in number
  , iSQLCmdPrefix      in varchar2
  , iSQLCmdSuffix      in varchar2
  , iTableType         in varchar2 default 'AFTER'
  , iIsList            in number default 1
  , iCtxUsage          in number default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall          in number default 0
  , iTableKeyValue     in varchar2 default null
  , iTableMappingValue in varchar2 default null
  , iOrderByClause     in varchar2 default 'null'
  )
    return xmltype
  as
    lxData                     xmltype;
    lSQLCmdPrefix              varchar2(32767);
    lSQLCmdSuffix              varchar2(32767);
    lSQLCmd                    clob;
    lnLength                   number          := 0;
    lnSep                      number          := 1;
    lvtableType                varchar2(32767) := ', XMLElement(TABLE_TYPE, ''' || iTableType || ''')';
    lvTransactionMode constant varchar2(32767) := ', XMLElement(DOC_TRANSACTION_MODE, ''VISIBLE_FIELDS''),';
  begin
    DBMS_LOB.createtemporary(lSQLCmd, true);
    -- Ajout de la partie commune aux préfixes et suffixes transmis
    lSQLCmdPrefix  := pInitSQLCmdPrefix(iEntityName, iCtxUsage, iMainCall, iIsList) || iSQLCmdPrefix;
    lSQLCmdSuffix  := pInitSQLCmdSuffix(iCtxUsage, iMainCall, iIsList, iOrderByClause) || iSQLCmdSuffix;
    -- Ajout de la 1ère partie dynamique de la commande SQL (Clob) du fragment XML contenant les champs de l'entité
    DBMS_LOB.WriteAppend(lSQLCmd, length(lSQLCmdPrefix), lSQLCmdPrefix);
    -- Ajout du type de la table
    DBMS_LOB.WriteAppend(lSQLCmd, length(lvtableType), lvtableType);

    -- Ajout du mode de transaction si nous sommes sur la table principale.
    if iTableType = 'MAIN' then
      DBMS_LOB.WriteAppend(lSQLCmd, length(lvTransactionMode), lvTransactionMode);
    else
      DBMS_LOB.WriteAppend(lSQLCmd, 1, ',');
    end if;

    -- Boucle sur le curseur pour générer la commandes de chaque champ de la table de l'entité source
    for tplFields in (select   a.ATTRIBUTE_NAME
                             , case
                                 when a.DATA_TYPE = 'DATE' then 'to_char(' || a.ENTITY_NAME || '.' || a.ATTRIBUTE_NAME || ')'
                                 else a.ENTITY_NAME || '.' || a.ATTRIBUTE_NAME
                               end ATTRIBUTE_VALUE
                          from table(FWK_I_LIB_METADATA.entity_attributes(iEntityName) ) a
                             , (select   ATTRIBUTE_NAME
                                    from table(FWK_I_LIB_METADATA.entity_attributes(iEntityName) )
                                   where ATTRIBUTE_NAME not like 'A\_%' escape '\'   -- On ne prend pas les attributs techniques A_%
                                     and ATTRIBUTE_NAME <> ENTITY_NAME || '_ID'   -- On ne prend pas la clef primaire
                                minus   -- On ne prend pas les attributs qui sont uniques
                                select   idx_col.COLUMN_NAME ATTRIBUTE_NAME
                                    from ALL_INDEXES idx
                                       , ALL_IND_COLUMNS idx_col
                                   where idx_col.INDEX_OWNER = idx.OWNER
                                     and idx_col.TABLE_NAME = idx.TABLE_NAME
                                     and idx_col.INDEX_NAME = idx.INDEX_NAME
                                     and idx.owner = pcs.PC_I_LIB_SESSION.GetCompanyOwner
                                     and idx.UNIQUENESS = 'UNIQUE'
                                     and idx.TABLE_NAME = iEntityName
                                minus   -- On ne reprend pas les attributs définis dans les exceptions métiers pour la synchronisation de l'entité.
                                select   attribute_name
                                    from table(REP_LIB_ECC_XML.getAttrException(iEntityName, REP_LIB_CONSTANT.SYNCHRONIZATION) )
                                order by ATTRIBUTE_NAME) b
                         where a.ATTRIBUTE_NAME = b.ATTRIBUTE_NAME
                      order by a.ATTRIBUTE_NAME) loop
      lnLength  := 14 +(length(tplFields.ATTRIBUTE_NAME) + length(tplFields.ATTRIBUTE_VALUE) );
      DBMS_LOB.WriteAppend(lSQLCmd, lnLength, 'XMLElement(' || tplFields.ATTRIBUTE_NAME || ',' || tplFields.ATTRIBUTE_VALUE || '),');
    end loop;

    -- Suppression de la dernière virgule
    DBMS_LOB.erase(lSQLCmd, lnSep, DBMS_LOB.getlength(lSQLCmd) );
    -- Ajout de la 2ème partie dynamique de la commande SQL (Clob) du fragment XML contenant les champs de l'entité
    DBMS_LOB.WriteAppend(lSQLCmd, length(lSQLCmdSuffix), lSQLCmdSuffix);

--     pcs.writeLogclob(lSQLCmd);

    -- Exécution de la commande SQL du fragment XML
    execute immediate lSQLCmd
                 into lxData
                using iEntityId;

    -- Libération du CLOB
    DBMS_LOB.freetemporary(lSQLCmd);

    -- Génération du fragment complet
    if lxData is not null then
      if     (iTableType <> 'MAIN')
         and (iCtxUsage = REP_LIB_CONSTANT.SYNCHRONIZATION) then
        select XMLElement(evalname(iEntityName)
                        , XMLConcat(case
                                      when iTableMappingValue is not null then XMLElement(TABLE_MAPPING, iTableMappingValue)
                                    end
                                  , case iIsList
                                      when 0 then lxData
                                      else XMLElement(list, lxData)
                                    end
                                   )
                         )
          into lxData
          from dual;
      end if;

      return lxData;
    elsif iTableType = 'AFTER' then
      -- Dans une table enfant suivant la table principale, si aucune donnée n'est présente dans le bien source, il faut générer un
      -- noeud avec le tag 'EMPTY' afin que le réplicateur puisse traiter ces enregistrements sur le bien cible.
      select XMLElement(evalname(iEntityName)
                      , case iIsList
                          when 1 then XMLConcat(case
                                                  when iTableMappingValue is not null then XMLElement(TABLE_MAPPING, iTableMappingValue)
                                                end
                                              , XMLElement(list
                                                         , XMLElement(LIST_ITEM
                                                                    , XMLConcat(XMLElement(TABLE_KEY, iTableKeyValue), XMLElement(TABLE_TYPE, 'EMPTY') )
                                                                     )
                                                          )
                                               )
                          else XMLConcat(case
                                           when iTableMappingValue is not null then XMLElement(TABLE_MAPPING, iTableMappingValue)
                                         end
                                       , XMLElement(TABLE_KEY, iTableKeyValue)
                                       , XMLElement(TABLE_TYPE, 'EMPTY')
                                        )
                        end
                       )
        into lxData
        from dual;

      return lxData;
    end if;

    return null;
  exception
    when no_data_found then
      DBMS_LOB.freetemporary(lSQLCmd);
      return null;
    when others then
      DBMS_LOB.freetemporary(lSQLCmd);
      raise;
  end getSyncEntityXml;

  /**
   * fonction getVFieldRecordXml
   * Description
   *    Génération d'un fragment XML des champs virtuels d'une entité en vue de sa synchronisation vers une autre entité
   */
  function getVFieldRecordXml(
    iTabName  in COM_VFIELDS_RECORD.VFI_TABNAME%type
  , iRecId    in COM_VFIELDS_RECORD.VFI_REC_ID%type
  , iCtxUsage in REP_LIB_CONSTANT.T_CONTEXT_USAGE default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'COM_VFIELDS_RECORD';
    lcTableKeyValue constant varchar2(32767) := 'VFI_TABNAME,VFI_REC_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(VFI_TABNAME, ' || lcEntityName || '.VFI_TABNAME)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.VFI_TABNAME=''' || iTabName || '''';
    lSQLCmdSuffix  := lSQLCmdSuffix || ' and ' || lcEntityName || '.VFI_REC_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName          => lcEntityName
                                          , iEntityId            => iRecId
                                          , iSQLCmdPrefix        => lSQLCmdPrefix
                                          , iSQLCmdSuffix        => lSQLCmdSuffix
                                          , iCtxUsage            => iCtxUsage
                                          , iMainCall            => iMainCall
                                          , iIsList              => 0
                                          , iTableKeyValue       => lcTableKeyValue
                                          , iTableMappingValue   => 'VFI_REC_ID=' || iTabName || '_ID'
                                           );
  end getVFieldRecordXml;

  /**
   * fonction getVFieldValueXml
   * Description
   *    Génération d'un fragment XML des champs virtuels (ancienne structure) d'une entité en vue de sa synchronisation vers une autre entité
   */
  function getVFieldValueXml(
    iTabName  in COM_VFIELDS_VALUE.CVF_TABNAME%type
  , iRecId    in COM_VFIELDS_VALUE.CVF_REC_ID%type
  , iCtxUsage in REP_LIB_CONSTANT.T_CONTEXT_USAGE default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  )
    return xmltype
  as
    lSQLCmdPrefix            varchar2(32767);
    lSQLCmdSuffix            varchar2(32767);
    lcEntityName    constant varchar2(30)    := 'COM_VFIELDS_VALUE';
    lcTableKeyValue constant varchar2(32767) := 'CVF_TABNAME,CVF_FLDNAME,CVF_REC_ID';
  begin
    -- Préfixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdPrefix  := lSQLCmdPrefix || '  XMLElement(TABLE_KEY, ''' || lcTableKeyValue || ''')';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(CVF_TABNAME, ' || lcEntityName || '.CVF_TABNAME)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(CVF_FLDNAME, ' || lcEntityName || '.CVF_FLDNAME)';
    lSQLCmdPrefix  := lSQLCmdPrefix || ', XMLElement(' || lcEntityName || '_ID, ' || lcEntityName || '.' || lcEntityName || '_ID)';
    -- Suffixe de la commande SQL de génération, spécifique à l'entité.
    lSQLCmdSuffix  := 'from ' || lcEntityName || ' where ' || lcEntityName || '.CVF_TABNAME=''' || iTabName || '''';
    lSQLCmdSuffix  := lSQLCmdSuffix || ' and ' || lcEntityName || '.CVF_REC_ID = :ENTITY_ID';
    -- Génération du fragment XML.
    return REP_LIB_ECC_XML.getSyncEntityXml(iEntityName          => lcEntityName
                                          , iEntityId            => iRecId
                                          , iSQLCmdPrefix        => lSQLCmdPrefix
                                          , iSQLCmdSuffix        => lSQLCmdSuffix
                                          , iCtxUsage            => iCtxUsage
                                          , iMainCall            => iMainCall
                                          , iTableKeyValue       => lcTableKeyValue
                                          , iTableMappingValue   => 'CVF_REC_ID=' || iTabName || '_ID'
                                           );
  end getVFieldValueXml;

  /**
   * fonction getVFieldXml
   * Description
   *    Génération d'un fragment XML des champs virtuels (ancienne et nouvelle structure) d'une entité en vue de sa synchronisation vers une autre entité
   */
  function getVFieldXml(
    iTabName  in COM_VFIELDS_VALUE.CVF_TABNAME%type
  , iRecId    in COM_VFIELDS_VALUE.CVF_REC_ID%type
  , iCtxUsage in REP_LIB_CONSTANT.T_CONTEXT_USAGE default REP_LIB_CONSTANT.SYNCHRONIZATION
  , iMainCall in number default 0
  )
    return xmltype
  as
    lxData1 xmltype;
    lxData2 xmltype;
  begin
    -- Récupération des champs virtuels de l'ancienne structure.
    lxData1  := getVFieldValueXml(iTabName, iRecId, iCtxUsage, iMainCall);
    -- Récupération des champs virtuels de la nouvelle structure.
    lxData2  := getVFieldRecordXml(iTabName, iRecId, iCtxUsage, iMainCall);

    if iCtxUsage = REP_LIB_CONSTANT.COMPARISON then
      select XMLElement("VIRTUAL_FIELDS", XMLConcat(lxData1, lxData2) )
        into lxData1
        from dual;
    else
      select XMLConcat(lxData1, lxData2)
        into lxData1
        from dual;
    end if;

    return lxData1;
  end getVFieldXml;

  /**
  * fonction getGoodXml
  * Description
  *    Fonction de génération d'un document Xml d'un bien en vue d'une synchronisation
  */
  function getGoodXml(iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type, iToGoodId in GCO_GOOD.GCO_GOOD_ID%type, iOptions in clob)
    return clob
  is
  begin
    return REP_LIB_UTILS.XmlToClob(REP_LIB_ECC_XML.getGoodXmlType(iFromGoodId, iToGoodId, iOptions) );
  end getGoodXml;

  /**
  * fonction getGoodXml
  * Description
  *    Fonction de génération d'un document Xml d'un bien en vue d'une synchronisation
  */
  function getGoodXmlType(iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type, iToGoodId in GCO_GOOD.GCO_GOOD_ID%type, iOptions in clob)
    return xmltype
  as
    lxData xmltype;
  begin
    REP_LIB_NLS_PARAMETERS.SetNLSFormat;
    lxData  := pGetEntityCCXmlType(REP_LIB_GCO_ECC_XML.getGoodXmlEntity(iFromGoodId, iToGoodId, iOptions) );
    REP_LIB_NLS_PARAMETERS.ResetNLSFormat;
    return lxData;
  exception
    when others then
      REP_LIB_NLS_PARAMETERS.ResetNLSFormat;
      raise;
  end getGoodXmlType;

  /**
  * procedure pAddEntityAttrException
  * Description
  *    Ajout d'un attribut d'une entité à la liste des exceptions métiers en fonction du contexte
  * @created  age 04.02.2014
  * @lastUpdate
  * @public
  * @param iEntityName    : Nom de l'entité
  * @param iContextName   : Contexte d'utilisation
  * @param iAttributeName : Nom de l'attribut
  */
  procedure pAddEntityAttrException(
    iEntityName    in FWK_I_TYP_DEFINITION.entity_name
  , iContextName   in REP_LIB_CONSTANT.T_CONTEXT_USAGE
  , iAttributeName in FWK_I_TYP_DEFINITION.def_name
  )
  as
    ltEntityAttrEx REP_LIB_CONSTANT.t_entity_attribute_exception;
    lKey           varchar2(106);
  begin
    begin
      lKey            := iEntityName || '/' || iContextName;
      ltEntityAttrEx  := entity_attr_exceptions(lKey);
    exception
      when no_data_found then
        entity_attr_exceptions(lKey).entity_name           := 'DUMMY';
        entity_attr_exceptions(lKey).attribute_exceptions  := REP_LIB_CONSTANT.tt_attributes();
    end;

    entity_attr_exceptions(lKey).attribute_exceptions.extend(1);
    entity_attr_exceptions(lKey).attribute_exceptions(entity_attr_exceptions(lKey).attribute_exceptions.last).attribute_name  := iAttributeName;
  end pAddEntityAttrException;

  /**
  * fonction getAttrException
  * Description
  *    Retourne la liste des exceptions (attributs à ne pas traiter) d'une entité en fonction du contexte
  */
  function getAttrException(iEntityName in FWK_I_TYP_DEFINITION.entity_name, iContextName in REP_LIB_CONSTANT.T_CONTEXT_USAGE)
    return REP_LIB_CONSTANT.tt_attributes pipelined
  as
    lttAttrEx REP_LIB_CONSTANT.tt_attributes;
  begin
    lttAttrEx  := entity_attr_exceptions(iEntityName || '/' || iContextName).attribute_exceptions;

    if lttAttrEx.count > 0 then
      for i in lttAttrEx.first .. lttAttrEx.last loop
        pipe row(lttAttrEx(i) );
      end loop;
    end if;
  exception
    when no_data_needed then
      return;
  end getAttrException;

  procedure addSyncAttrException(iEntityName in FWK_I_TYP_DEFINITION.entity_name, iAttributeName in FWK_I_TYP_DEFINITION.def_name)
  as
  begin
    pAddEntityAttrException(iEntityName => iEntityName, iContextName => REP_LIB_CONSTANT.SYNCHRONIZATION, iAttributeName => iAttributeName);
  end addSyncAttrException;
begin
  -- Ajout des champs ignorés pour la synchronisation de l'entité GCO_GOOD
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'C_GOOD_STATUS');   -- selon analyse FDA - VE
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GCO_MULTIMEDIA_ELEMENT_ID');   -- selon analyse FDA - VE
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GCO_SUBSTITUTION_LIST_ID');   -- selon analyse FDA - VE
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_WEB_PUBLISHED');   -- selon analyse FDA - VE
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_EAN_UCC14_CODE');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_EAN_CODE');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_HIBC_REFERENCE');   -- Non repris lors de la copie de produit
--     addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_HIBC_PRIMARY_CODE'); -- Non repris lors de la copie de produit et déjà enlevé par EntityCC (Index unique)
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GCO_GOOD_OLE_OBJECT');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_VERSION1_ID');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_STD_CHAR1_ID');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_STD_CHAR2_ID');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_STD_CHAR3_ID');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_STD_CHAR4_ID');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_STD_CHAR5_ID');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_PIECE1_ID');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_PIECE2_ID');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_PIECE3_ID');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_SET1_ID');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_SET2_ID');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_SET3_ID');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_CHRONO1_ID');   -- Non repris lors de la copie de produit
--   addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GCO_GOOD_ID'); -- Déjà enlevé par EntityCC (PK1)
--   addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoGood, 'GOO_MAJOR_REFERENCE'); -- Déjà enlevé par EntityCC (Index unique)

  /*********** Ajout des champs ignorés pour la synchronisation de l'entité GCO_PRODUCT **********/
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoProduct, 'PDT_VERSION');   -- selon analyse FDA - VE
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoProduct, 'PDT_VERSION_MANAGEMENT');   -- selon analyse FDA - VE
  /*********** Ajout des champs ignorés pour la synchronisation de l'entité GCO_COMPL_DATA_STOCK **********/
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataStock, 'CDA_COMPLEMENTARY_EAN_CODE');   -- Non repris lors de la copie de produit
  /*********** Ajout des champs ignorés pour la synchronisation de l'entité GCO_COMPL_DATA_INVENTORY **********/
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataInventory, 'CDA_COMPLEMENTARY_EAN_CODE');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataInventory, 'CIN_LAST_INVENTORY_DATE');   -- Traitement particulier lors de la copie
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataInventory, 'CIN_NEXT_INVENTORY_DATE');   -- Traitement particulier lors de la copie
  /*********** Ajout des champs ignorés pour la synchronisation de l'entité GCO_COMPL_DATA_PURCHASE **********/
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataPurchase, 'CDA_COMPLEMENTARY_EAN_CODE');   -- Non repris lors de la copie de produit
  /*********** Ajout des champs ignorés pour la synchronisation de l'entité GCO_COMPL_DATA_SALE **********/
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataSale, 'CDA_COMPLEMENTARY_EAN_CODE');   -- Non repris lors de la copie de produit
  /*********** Ajout des champs ignorés pour la synchronisation de l'entité GCO_COMPL_DATA_ASS **********/
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataAss, 'CDA_COMPLEMENTARY_EAN_CODE');   -- Non repris lors de la copie de produit
  /*********** Ajout des champs ignorés pour la synchronisation de l'entité GCO_COMPL_DATA_EXTERNAL_ASA **********/
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataExternalAsa, 'CDA_COMPLEMENTARY_EAN_CODE');   -- Non repris lors de la copie de produit
  /*********** Ajout des champs ignorés pour la synchronisation de l'entité GCO_COMPL_DATA_MANUFACTURE **********/
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataManufacture, 'CDA_COMPLEMENTARY_EAN_CODE');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataManufacture, 'CMA_MULTIMEDIA_PLAN');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataManufacture, 'PPS_NOMENCLATURE_ID');   -- Traitement métier particulier
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataManufacture, 'FAL_SCHEDULE_PLAN_ID');   -- Traitement métier particulier
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataManufacture, 'PPS_RANGE_ID');   -- Non repris lors de la copie de produit
  /*********** Ajout des champs ignorés pour la synchronisation de l'entité GCO_COMPL_DATA_SUBCONTRACT **********/
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataSubcontract, 'CDA_COMPLEMENTARY_EAN_CODE');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataSubcontract, 'PPS_NOMENCLATURE_ID');   -- Traitement métier particulier
  /*********** Ajout des champs ignorés pour la synchronisation de l'entité GCO_COMPL_DATA_DISTRIB **********/
  addSyncAttrException(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataDistrib, 'CDA_COMPLEMENTARY_EAN_CODE');   -- Non repris lors de la copie de produit
  /*********** Ajout des champs ignorés pour la synchronisation de l'entité PTC_FIXED_COSTPRICE **********/
  addSyncAttrException(FWK_I_TYP_PTC_ENTITY.gcPtcFixedCostPrice, 'CPR_HISTORY_ID');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_PTC_ENTITY.gcPtcFixedCostPrice, 'CPR_PRICE_BEFORE_RECALC');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_PTC_ENTITY.gcPtcFixedCostPrice, 'FAL_ADV_STRUCT_CALC_ID');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_PTC_ENTITY.gcPtcFixedCostPrice, 'FAL_SCHEDULE_PLAN_ID');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_PTC_ENTITY.gcPtcFixedCostPrice, 'PPS_NOMENCLATURE_ID');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_PTC_ENTITY.gcPtcFixedCostPrice, 'GCO_COMPL_DATA_MANUFACTURE_ID');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_PTC_ENTITY.gcPtcFixedCostPrice, 'GCO_COMPL_DATA_PURCHASE_ID');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_PTC_ENTITY.gcPtcFixedCostPrice, 'CPR_MANUFACTURE_ACCOUNTING');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_PTC_ENTITY.gcPtcFixedCostPrice, 'CPR_CALCUL_DATE');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_PTC_ENTITY.gcPtcFixedCostPrice, 'GCO_COMPL_DATA_SUBCONTRACT_ID');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_PTC_ENTITY.gcPtcFixedCostPrice, 'LOT_REFCOMPL');   -- Non repris lors de la copie de produit
  /*********** Ajout des champs ignorés pour la synchronisation de l'entité PTC_CALC_COSTPRICE **********/
  addSyncAttrException(FWK_I_TYP_PTC_ENTITY.gcPtcCalcCostPrice, 'CPR_PRICE');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_PTC_ENTITY.gcPtcCalcCostPrice, 'CCP_ADDED_QUANTITY');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_PTC_ENTITY.gcPtcCalcCostPrice, 'CCP_ADDED_VALUE');   -- Non repris lors de la copie de produit
  addSyncAttrException(FWK_I_TYP_PTC_ENTITY.gcPtcCalcCostPrice, 'CPR_HISTORY_ID');   -- Non repris lors de la copie de produit
  /*********** Ajout des champs ignorés pour la synchronisation de l'entité PTC_TARIFF_TABLE **********/
  addSyncAttrException(FWK_I_TYP_PTC_ENTITY.gcPtcTariffTable, 'PTC_TARIFF_ID');   -- Principe EntityCC : l'ID du parent ne doit pas être repris.
  /*********** Ajout des champs ignorés pour la synchronisation de l'entité PPS_NOMENCLATURE **********/
  addSyncAttrException(FWK_I_TYP_PPS_ENTITY.gcPpsNomenclature, 'GCO_GOOD_ID');   -- Principe EntityCC : l'ID du parent ne doit pas être repris.
  /*********** Ajout des champs ignorés pour la synchronisation de l'entité FAL_LIST_STEP_LINK **********/
  addSyncAttrException(FWK_I_TYP_FAL_ENTITY.gcFalListStepLink, 'FAL_SCHEDULE_STEP_ID');   -- Traitement particulier par trigger
  /*********** Ajout des champs ignorés pour la synchronisation de l'entité FAL_LIST_STEP_USE **********/
  addSyncAttrException(FWK_I_TYP_FAL_ENTITY.gcFalListStepUse, 'FAL_SCHEDULE_STEP_ID');   -- Principe EntityCC : l'ID du parent ne doit pas être repris.
end REP_LIB_ECC_XML;
