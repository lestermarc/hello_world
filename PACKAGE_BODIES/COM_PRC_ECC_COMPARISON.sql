--------------------------------------------------------
--  DDL for Package Body COM_PRC_ECC_COMPARISON
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_PRC_ECC_COMPARISON" 
is
  type TLOOKUP is record(
    TABLE_NAME  varchar2(30)
  , FIELD_NAME  varchar2(30)
  , OBJECT_NAME varchar2(30)
  , GET_SQL     varchar2(32767)
  );

  pcToCall constant number := 1;

  -- Table mémoire
  type TLOOKUP_LIST is table of TLOOKUP
    index by varchar2(100);

  lLookupList TLOOKUP_LIST;

  /**
  * procedure pUpdateDiffLnk
  * Description
  *    Mise à jour des liens parent-enfant de la table COM_ECC_DIFF_DATA une fois les différences insérées.
  * @created  age 21.02.2014
  * @lastUpdate
  * @private
  */
  procedure pUpdateDiffLnk
  as
  begin
    update COM_ECC_DIFF_DATA CHILDREN
       set COM_ECC_DIFF_DATA_PARENT_ID =
                   (select COM_ECC_DIFF_DATA_ID
                      from COM_ECC_DIFF_DATA
                     where CED_TYPE = 'TABLE'
                       and CED_INDEX = CHILDREN.CED_PARENT_INDEX
                       and CED_VALUE = CHILDREN.CED_TABLE_ID
                       and CED_FIELD = CHILDREN.CED_TABLE)
     where COM_ECC_DIFF_DATA_PARENT_ID is null
       and CED_TABLE_ID != 0
       and exists(select 1
                    from COM_ECC_DIFF_DATA
                   where CED_TYPE = 'TABLE'
                     and CED_INDEX = CHILDREN.CED_PARENT_INDEX
                     and CED_VALUE = CHILDREN.CED_TABLE_ID
                     and CED_FIELD = CHILDREN.CED_TABLE);
  end pUpdateDiffLnk;

  /**
  * function pGetLkpGetSql
  * Description
  *    Renvoi le code sql de la commande Get figurant dans la relation en question
  * @created  ngv 12.03.2014
  * @param iTableName : nom du table de la relation
  * @param iFieldName : nom du champ de la relation
  * @return : code sql de la commande Get
  */
  function pGetLkpGetSql(iTableName in varchar2, iFieldName in varchar2)
    return varchar2
  is
    lvSql        varchar2(32767);
    lvLookupName varchar2(100);
  begin
    -- Clé pour la recherche ou ajout dans la liste stackée des cmdes Get
    lvLookupName  := iTableName || '/' || iFieldName || '/' || PCS.PC_I_LIB_SESSION.GetObjectName;

    -- Vérifier si le lookup est déjà dans notre liste stackée (lookup recherché précédement)
    if lLookupList.exists(lvLookupName) then
      -- Utiliser la cmde stackée
      lvSql  := lLookupList(lvLookupName).GET_SQL;
    else
      -- Rechercher la cmde Get dans les relations
      lvSql                                  := PCS.PC_I_LIB_FKLUP.GetFklGetSql(iFkTableName => iTableName, iFkFieldName => iFieldName);
      -- Stacker le lookup
      lLookupList(lvLookupName).TABLE_NAME   := iTableName;
      lLookupList(lvLookupName).FIELD_NAME   := iFieldName;
      lLookupList(lvLookupName).OBJECT_NAME  := PCS.PC_I_LIB_SESSION.GetObjectName;
      lLookupList(lvLookupName).GET_SQL      := lvSql;
    end if;

    return lvSql;
  end pGetLkpGetSql;

  /**
  * procedure pResolveIds
  * Description
  *    Résoud les ids figurants dans les valeurs modifiées (CED_VALUE et CED_VALUE_FROM) en utilisant les relations
  * @created  ngv 12.03.2014
  * @param ioEccDiff : tuple COM_ECC_DIFF_DATA à traiter
  */
  procedure pResolveIds(ioEccDiff in out COM_ECC_DIFF_DATA%rowtype)
  is
    lvSql          varchar2(32767);
    lvParam        varchar2(40);
    lDynamicCursor integer;
    lExecuteCursor integer;
  begin
    ioEccDiff.CED_TEXT_VALUE       := ioEccDiff.CED_VALUE;
    ioEccDiff.CED_TEXT_VALUE_FROM  := ioEccDiff.CED_VALUE_FROM;

    -- Champ ID à convertir en texte
    if     (ioEccDiff.CED_TYPE = 'FIELD')
       and (ioEccDiff.CED_FIELD like '%_ID')
       and (ioEccDiff.CED_TABLE || '_ID' <> ioEccDiff.CED_FIELD)
       and not(ioEccDiff.CED_FIELD like 'DIC%')
       and (    (ioEccDiff.CED_VALUE is not null)
            or (ioEccDiff.CED_VALUE_FROM is not null) ) then
      -- Rechercher de la cmde Get de la relation
      lvSql  := pGetLkpGetSql(iTableName => ioEccDiff.CED_TABLE, iFieldName => ioEccDiff.CED_FIELD);

      -- Commande Get trouvée
      if lvSql is not null then
        -- Parse la commande à la recherche des paramètres standard ProConcept
        lvSql    := PCS.PC_I_LIB_SQL.ResolvePcsParams(iSqlStmnt => lvSql);
        -- Extraire le nom du 1er paramètre
        lvParam  := PCS.PC_LIB_SQL.GetParamName(lvSql);

        -- Valeur 1
        if (ioEccDiff.CED_VALUE is not null) then
          begin
            lDynamicCursor  := DBMS_SQL.OPEN_CURSOR;
            DBMS_SQL.PARSE(lDynamicCursor, lvSql, DBMS_SQL.NATIVE);
            DBMS_SQL.BIND_VARIABLE_CHAR(lDynamicCursor, lvParam, ioEccDiff.CED_VALUE);
            DBMS_SQL.DEFINE_COLUMN(lDynamicCursor, 1, ioEccDiff.CED_TEXT_VALUE, 4000);
            lExecuteCursor  := DBMS_SQL.execute(lDynamicCursor);

            if DBMS_SQL.FETCH_ROWS(lDynamicCursor) > 0 then
              DBMS_SQL.column_value(lDynamicCursor, 1, ioEccDiff.CED_TEXT_VALUE);
            end if;

            DBMS_SQL.CLOSE_CURSOR(lDynamicCursor);
          exception
            when others then
              null;
          end;
        end if;

        -- Valeur 2
        if (ioEccDiff.CED_VALUE_FROM is not null) then
          begin
            lDynamicCursor  := DBMS_SQL.OPEN_CURSOR;
            DBMS_SQL.PARSE(lDynamicCursor, lvSql, DBMS_SQL.NATIVE);
            DBMS_SQL.BIND_VARIABLE_CHAR(lDynamicCursor, lvParam, ioEccDiff.CED_VALUE_FROM);
            DBMS_SQL.DEFINE_COLUMN(lDynamicCursor, 1, ioEccDiff.CED_TEXT_VALUE_FROM, 4000);
            lExecuteCursor  := DBMS_SQL.execute(lDynamicCursor);

            if DBMS_SQL.FETCH_ROWS(lDynamicCursor) > 0 then
              DBMS_SQL.column_value(lDynamicCursor, 1, ioEccDiff.CED_TEXT_VALUE_FROM);
            end if;

            DBMS_SQL.CLOSE_CURSOR(lDynamicCursor);
          exception
            when others then
              null;
          end;
        end if;
      end if;
    end if;
  end pResolveIds;

  /**
  * fonction pProcessComparison
  * Description
  *    Compare les données de l'entité 1 vers l'entité 2. Le résultat est inséré dans la table COM_ECC_DIFF_DATA.
  *    Il indique les différences effectuée pour aller du document 1 au document 2
  * @created  age 21.02.2014
  * @lastUpdate
  * @private
  * @param iDoc1 : Document depuis lequel on compare les données.
  * @param iDoc2 : Document vers lequels on compare les données.
  * @param iOptionType : Type d'option de la comparaison des données.
  * @return : Message d'erreur en cas de problème lors du traitement, rien en cas de réussite.
  */
  function pProcessComparison(iDoc1 in xmltype, iDoc2 in xmltype, iOptionType in varchar2 default null, iDelete in boolean default true)
    return varchar2
  as
    lres      number;
    ltEccDiff COM_ECC_DIFF_DATA%rowtype;
    lcDoc1    clob;
    lcDoc2    clob;
  begin
    -- Initialisation complète (documents, erreurs, classe).
    PC_XML_DIFFGEN.clear;

    -- Suppression des données de la table temporaire
    if iDelete then
      delete from COM_ECC_DIFF_DATA;
    end if;

    if     iDoc1 is null
       and iDoc2 is null then
      return null;
    end if;

    if iDoc1 is null then
      lcDoc1  := empty_clob();
    else
      lcDoc1  := iDoc1.getClobVal();
    end if;

    if iDoc2 is null then
      lcDoc2  := empty_clob();
    else
      lcDoc2  := iDoc2.getClobVal();
    end if;

    -- Chargement des documents dans le moteur de comparaison
    lres  := PC_XML_DIFFGEN.SetDocuments(lcDoc1, lcDoc2);

    if lres = 0 then
      return pcs.PC_FUNCTIONS.translateword('Erreur de chargement.');
    elsif lres = -1 then
      return pcs.PC_FUNCTIONS.translateword('Erreur de chargement du premier document.');
    elsif lres = -2 then
      return pcs.PC_FUNCTIONS.translateword('Erreur de chargement du deuxième document.');
    end if;

    -- Exécution de l'évaluation des deux documents.
    lres  := PC_XML_DIFFGEN.execute;

    if lres <> 0 then
      return pcs.PC_FUNCTIONS.translateword('Erreur lors de l''exécution de l''évaluation des deux documents.');
    end if;

    -- S'il n'y a pas de différence, on sort de la procédure.
    if PC_XML_DIFFGEN.HasDifferences = 0 then
      return null;
    end if;

    -- Génération des différences
    lres  := PC_XML_DIFFGEN.GenerateDifferences;

    if lres <> 0 then
      return pcs.PC_FUNCTIONS.translateword('Erreur lors de l''exécution de la génération des différences');
    end if;

    -- Collecte les différences et insertion dans la table temporaire
    if (PC_XML_DIFFGEN.FindFirstDiff(ltEccDiff.CED_PARENT_INDEX
                                   , ltEccDiff.CED_INDEX
                                   , ltEccDiff.CED_TABLE_ID
                                   , ltEccDiff.CED_TABLE
                                   , ltEccDiff.CED_FIELD
                                   , ltEccDiff.CED_VALUE
                                   , ltEccDiff.CED_VALUE_FROM
                                   , ltEccDiff.CED_MODE
                                   , ltEccDiff.CED_TYPE
                                    ) > 0
       ) then
      loop
        ltEccDiff.COM_ECC_DIFF_DATA_ID  := getNewId;
        ltEccDiff.CED_DATE              := sysdate;
        -- Type d'option (GCO_GOOD, GCO_COMPL_DATA_SALE, etc.)
        ltEccDiff.CED_OPTION_TYPE       := iOptionType;
        -- Conversion des ID en valeur texte
        pResolveIds(ltEccDiff);

        -- Ajout de l'élément dans la table temporaires de différences
        insert into COM_ECC_DIFF_DATA
             values ltEccDiff;

        exit when PC_XML_DIFFGEN.FindNextDiff(ltEccDiff.CED_PARENT_INDEX
                                            , ltEccDiff.CED_INDEX
                                            , ltEccDiff.CED_TABLE_ID
                                            , ltEccDiff.CED_TABLE
                                            , ltEccDiff.CED_FIELD
                                            , ltEccDiff.CED_VALUE
                                            , ltEccDiff.CED_VALUE_FROM
                                            , ltEccDiff.CED_MODE
                                            , ltEccDiff.CED_TYPE
                                             ) = 0;
      end loop;
    end if;

    -- Mise à jour des liens parents-enfants de la table temporaire de différences
    pUpdateDiffLnk;
    -- Libération des ressources utilisées par la recherche des modifications.
    PC_XML_DIFFGEN.FindCloseDiff;
    return '';
  end pProcessComparison;

  /**
  * procedure compareEntity
  * Description
  *    Compare les données d'un article (FromGoodId) avec celles d'un autre (ToGoodId).
  */
  procedure compareEntity(
    iEntityType   in     varchar2
  , iFromMajorRef in     GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , iToMajorRef   in     GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , ioOptions     in out varchar2
  )
  is
    liFromGoodId GCO_GOOD.GCO_GOOD_ID%type;
    liToGoodId   GCO_GOOD.GCO_GOOD_ID%type;
    lvErrorMsg   varchar2(4000);
  begin
    liFromGoodId  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'GCO_GOOD', iv_column_name => 'GOO_MAJOR_REFERENCE', iv_value => iFromMajorRef);
    liToGoodId    := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'GCO_GOOD', iv_column_name => 'GOO_MAJOR_REFERENCE', iv_value => iToMajorRef);
    processEntity(iEntityType => iEntityType, iFromGoodId => liFromGoodId, iToGoodId => liToGoodId, ioOptions => ioOptions, oErrorMsg => lvErrorMsg);

    if lvErrorMsg is not null then
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => lvErrorMsg
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'compareEntity'
                                         );
    end if;
  end compareEntity;

  /**
  * procedure processEntity
  * Description
  *    Compare les données d'un article (FromGoodId) avec celles d'un autre (ToGoodId).
  */
  procedure processEntity(
    iEntityType in     varchar2
  , iFromGoodId in     GCO_GOOD.GCO_GOOD_ID%type
  , iToGoodId   in     GCO_GOOD.GCO_GOOD_ID%type
  , ioOptions   in out clob
  , oErrorMsg   out    varchar2
  )
  is
    lvErrorMsg varchar2(4000);
    lOptions   GCO_I_LIB_CONSTANT.gtProductCopySyncOptions;
    lbDelete   boolean                                     := false;
  begin
    -- Détermine si l'on doit supprimer les données de la table temporaire en fonction du mode d'appel. En mode unitaire, on supprime.
    if iEntityType is not null then
      lbDelete  := true;
    else
      -- TODO : Utiliser la méthode globale avec une adaptation pour la comparaison pour améliorer les performances.
      -- function getGoodXmlEntity(iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type, iToGoodId in GCO_GOOD.GCO_GOOD_ID%type, iOptions in clob)
      --    return xmltype
      null;
    end if;

    -- Charge les options de copie/synchronisation d'un produit dans le type record correspondant
    if ioOptions is not null then
      lOptions  := GCO_I_LIB_FUNCTIONS.loadProductCopySyncOptions(ioOptions);
    end if;

    if (nvl(iEntityType, GCO_I_LIB_CONSTANT.gcGCO_GOOD) = GCO_I_LIB_CONSTANT.gcGCO_GOOD) then
      -- Le premier appel de comparaison demande toujours l'effacement des données de la table temporaire.
      lvErrorMsg  := processGcoGood(iFromGoodId, iToGoodId, true);
    end if;

    if (nvl(iEntityType, GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_STOCK) = GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_STOCK) then
      lvErrorMsg  := lvErrorMsg || processGcoComplDataStock(iFromGoodId, iToGoodId, lbDelete);
    end if;

    if (nvl(iEntityType, GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_INVENTORY) = GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_INVENTORY) then
      lvErrorMsg  := lvErrorMsg || processGcoComplDataInventory(iFromGoodId, iToGoodId, lbDelete);
    end if;

    if (nvl(iEntityType, GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_PURCHASE) = GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_PURCHASE) then
      lvErrorMsg  := lvErrorMsg || processGcoComplDataPurchase(iFromGoodId, iToGoodId, 1   --lOptions.bSQM_CERTIFICATION
                                                                                        , lbDelete);
    end if;

    if (nvl(iEntityType, GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_SALE) = GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_SALE) then
      lvErrorMsg  := lvErrorMsg || processGcoComplDataSale(iFromGoodId, iToGoodId, lbDelete);
    end if;

    if (nvl(iEntityType, GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_ASS) = GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_ASS) then
      lvErrorMsg  := lvErrorMsg || processGcoComplDataAss(iFromGoodId, iToGoodId, lbDelete);
    end if;

    if (nvl(iEntityType, GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_EXTERNAL_ASA) = GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_EXTERNAL_ASA) then
      lvErrorMsg  := lvErrorMsg || processGcoComplDataExternalAsa(iFromGoodId, iToGoodId, lbDelete);
    end if;

    if (nvl(iEntityType, GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_MANUFACTURE) = GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_MANUFACTURE) then
      lvErrorMsg  :=
        lvErrorMsg ||
        processGcoComplDataManufacture(iFromGoodId
                                     , iToGoodId
                                     , 1   --lOptions.bGCO_COUPLED_GOOD
                                     , 1   --lOptions.bSQM_CERTIFICATION
                                     , 1   --lOptions.bPPS_NOMENCLATURE
                                     , 1   --lOptions.bFAL_SCHEDULE_PLAN
                                     , lbDelete
                                      );
    end if;

    if (nvl(iEntityType, GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_SUBCONTRACT) = GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_SUBCONTRACT) then
      lvErrorMsg  := lvErrorMsg || processGcoComplDataSubcontract(iFromGoodId, iToGoodId, 1   --lOptions.bPPS_NOMENCLATURE
                                                                                           , lbDelete);
    end if;

    if (nvl(iEntityType, GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_DISTRIB) = GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_DISTRIB) then
      lvErrorMsg  := lvErrorMsg || processGcoComplDataDistrib(iFromGoodId, iToGoodId, lbDelete);
    end if;

    if (nvl(iEntityType, GCO_I_LIB_CONSTANT.gcGCO_GOOD_ATTRIBUTE) = GCO_I_LIB_CONSTANT.gcGCO_GOOD_ATTRIBUTE) then
      lvErrorMsg  := lvErrorMsg || processGcoGoodAttribute(iFromGoodId, iToGoodId, lbDelete);
    end if;

    if (nvl(iEntityType, GCO_I_LIB_CONSTANT.gcPTC_FIXED_COSTPRICE) = GCO_I_LIB_CONSTANT.gcPTC_FIXED_COSTPRICE) then
      lvErrorMsg  := lvErrorMsg || processPtcFixedCostprice(iFromGoodId, iToGoodId, lbDelete);
    end if;

    if (nvl(iEntityType, GCO_I_LIB_CONSTANT.gcPTC_CALC_COSTPRICE) = GCO_I_LIB_CONSTANT.gcPTC_CALC_COSTPRICE) then
      lvErrorMsg  := lvErrorMsg || processPtcCalcCostprice(iFromGoodId, iToGoodId, lbDelete);
    end if;

    if (nvl(iEntityType, GCO_I_LIB_CONSTANT.gcPTC_TARIFF) = GCO_I_LIB_CONSTANT.gcPTC_TARIFF) then
      lvErrorMsg  := lvErrorMsg || processPtcTariff(iFromGoodId, iToGoodId, lbDelete);
    end if;

    if (nvl(iEntityType, GCO_I_LIB_CONSTANT.gcPTC_DISCOUNT) = GCO_I_LIB_CONSTANT.gcPTC_DISCOUNT) then
      lvErrorMsg  := lvErrorMsg || processPtcDiscountGoodLink(iFromGoodId, iToGoodId, lbDelete);
    end if;

    if (nvl(iEntityType, GCO_I_LIB_CONSTANT.gcPTC_CHARGE) = GCO_I_LIB_CONSTANT.gcPTC_CHARGE) then
      lvErrorMsg  := lvErrorMsg || processPtcChargeGoodLink(iFromGoodId, iToGoodId, lbDelete);
    end if;

    if (nvl(iEntityType, GCO_I_LIB_CONSTANT.gcGCO_PRECIOUS_MAT) = GCO_I_LIB_CONSTANT.gcGCO_PRECIOUS_MAT) then
      lvErrorMsg  := lvErrorMsg || processGcoPreciousMat(iFromGoodId, iToGoodId, lbDelete);
    end if;

    if (nvl(iEntityType, GCO_I_LIB_CONSTANT.gcGCO_CONNECTED_GOOD) = GCO_I_LIB_CONSTANT.gcGCO_CONNECTED_GOOD) then
      lvErrorMsg  := lvErrorMsg || processGcoConnectedGood(iFromGoodId, iToGoodId, lbDelete);
    end if;

    if (nvl(iEntityType, GCO_I_LIB_CONSTANT.gcFREE_DATA) = GCO_I_LIB_CONSTANT.gcFREE_DATA) then
      lvErrorMsg  := lvErrorMsg || processGcoFreeData(iFromGoodId, iToGoodId, lbDelete);
    end if;

--
    if (nvl(iEntityType, GCO_I_LIB_CONSTANT.gcVIRTUAL_FIELDS) = GCO_I_LIB_CONSTANT.gcVIRTUAL_FIELDS) then
      lvErrorMsg  := lvErrorMsg || processVField(iFromGoodId, iToGoodId, lbDelete);
    end if;

    if (nvl(iEntityType, GCO_I_LIB_CONSTANT.gcPPS_TOOLS) = GCO_I_LIB_CONSTANT.gcPPS_TOOLS) then
      lvErrorMsg  := lvErrorMsg || processPpsTool(iFromGoodId, iToGoodId, 1   --lOptions.bPPS_SPECIAL_TOOLS
                                                                           , lbDelete);
    end if;

    -- Indique, pour chaque option, si des différences existent dans la table temporaire.
    if lvErrorMsg is null then
      lOptions   := loadUpdatedSyncOptions;
      ioOptions  := GCO_I_LIB_FUNCTIONS.loadProductCopySyncOptions(lOptions);
    end if;

    oErrorMsg  := lvErrorMsg;
  end processEntity;

  /**
  * fonction processGcoGood
  * Description
  *    Compare les données d'un article (FromGoodId) avec celles d'un autre (ToGoodId).
  */
  function processGcoGood(iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type, iToGoodId in GCO_GOOD.GCO_GOOD_ID%type, iDelete in boolean default true)
    return varchar2
  is
    lxDoc1 xmltype;
    lxDoc2 xmltype;
  begin
    lxDoc1  := REP_I_LIB_GCO_ECC_XML.getGoodXml(iToGoodId, iToGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1, pcToCall);   --A
    lxDoc2  := REP_I_LIB_GCO_ECC_XML.getGoodXml(iFromGoodId, iToGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1);   --B
    return pProcessComparison(lxDoc1, lxDoc2, GCO_I_LIB_CONSTANT.gcGCO_GOOD, iDelete);
  end processGcoGood;

  /**
  * fonction processGcoComplDataStock
  * Description
  *    Compare les données complémentaires de stock d'un article (FromGoodId) avec celles d'un autre (ToGoodId).
  */
  function processGcoComplDataStock(iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type, iToGoodId in GCO_GOOD.GCO_GOOD_ID%type, iDelete in boolean default true)
    return varchar2
  as
    lxDoc1 xmltype;
    lxDoc2 xmltype;
  begin
    lxDoc1  := REP_I_LIB_GCO_ECC_XML.getGcoComplDataStockXml(iToGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1, pcToCall);   --A
    lxDoc2  := REP_I_LIB_GCO_ECC_XML.getGcoComplDataStockXml(iFromGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1);   --B
    return pProcessComparison(lxDoc1, lxDoc2, GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_STOCK, iDelete);
  end processGcoComplDataStock;

  /**
  * fonction processGcoComplDataInventory
  * Description
  *    Compare les données complémentaires d'inventaire d'un article (FromGoodId) avec celles d'un autre (ToGoodId).
  */
  function processGcoComplDataInventory(iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type, iToGoodId in GCO_GOOD.GCO_GOOD_ID%type, iDelete in boolean default true)
    return varchar2
  as
    lxDoc1 xmltype;
    lxDoc2 xmltype;
  begin
    lxDoc1  := REP_I_LIB_GCO_ECC_XML.getGcoComplDataInventoryXml(iToGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1, pcToCall);   --A
    lxDoc2  := REP_I_LIB_GCO_ECC_XML.getGcoComplDataInventoryXml(iFromGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1);   --B
    return pProcessComparison(lxDoc1, lxDoc2, GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_INVENTORY, iDelete);
  end processGcoComplDataInventory;

  /**
  * fonction processGcoComplDataPurchase
  * Description
  *    Compare les données complémentaires d'achat d'un article (FromGoodId) avec celles d'un autre (ToGoodId).
  */
  function processGcoComplDataPurchase(
    iFromGoodId          in GCO_GOOD.GCO_GOOD_ID%type
  , iToGoodId            in GCO_GOOD.GCO_GOOD_ID%type
  , idoGenerateCertifLnk in integer
  , iDelete              in boolean default true
  )
    return varchar2
  as
    lxDoc1 xmltype;
    lxDoc2 xmltype;
  begin
    lxDoc1  := REP_I_LIB_GCO_ECC_XML.getGcoComplDataPurchaseXml(iToGoodId, idoGenerateCertifLnk, REP_I_LIB_CONSTANT.COMPARISON, 1, pcToCall);   --A
    lxDoc2  := REP_I_LIB_GCO_ECC_XML.getGcoComplDataPurchaseXml(iFromGoodId, idoGenerateCertifLnk, REP_I_LIB_CONSTANT.COMPARISON, 1);   --B
    return pProcessComparison(lxDoc1, lxDoc2, GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_PURCHASE, iDelete);
  end processGcoComplDataPurchase;

  /**
  * fonction processGcoComplDataSale
  * Description
  *    Compare les données complémentaires de vente d'un article (FromGoodId) avec celles d'un autre (ToGoodId).
  */
  function processGcoComplDataSale(iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type, iToGoodId in GCO_GOOD.GCO_GOOD_ID%type, iDelete in boolean default true)
    return varchar2
  as
    lxDoc1 xmltype;
    lxDoc2 xmltype;
  begin
    lxDoc1  := REP_I_LIB_GCO_ECC_XML.getGcoComplDataSaleXml(iToGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1, pcToCall);   --A
    lxDoc2  := REP_I_LIB_GCO_ECC_XML.getGcoComplDataSaleXml(iFromGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1);   --B
    return pProcessComparison(lxDoc1, lxDoc2, GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_SALE, iDelete);
  end processGcoComplDataSale;

  /**
  * fonction processGcoComplDataAss
  * Description
  *    Compare les données complémentaires de service après vente d'un article (FromGoodId) avec celles d'un autre (ToGoodId).
  */
  function processGcoComplDataAss(iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type, iToGoodId in GCO_GOOD.GCO_GOOD_ID%type, iDelete in boolean default true)
    return varchar2
  as
    lxDoc1 xmltype;
    lxDoc2 xmltype;
  begin
    lxDoc1  := REP_I_LIB_GCO_ECC_XML.getGcoComplDataAssXml(iToGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1, pcToCall);   --A
    lxDoc2  := REP_I_LIB_GCO_ECC_XML.getGcoComplDataAssXml(iFromGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1);   --B
    return pProcessComparison(lxDoc1, lxDoc2, GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_ASS, iDelete);
  end processGcoComplDataAss;

  /**
  * fonction processGcoComplDataExternalAsa
  * Description
  *    Compare les données complémentaires de service après vente externe d'un article (FromGoodId) avec celles d'un autre (ToGoodId).
  */
  function processGcoComplDataExternalAsa(iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type, iToGoodId in GCO_GOOD.GCO_GOOD_ID%type, iDelete in boolean default true)
    return varchar2
  as
    lxDoc1 xmltype;
    lxDoc2 xmltype;
  begin
    lxDoc1  := REP_I_LIB_GCO_ECC_XML.getGcoComplDataExternalAsaXml(iToGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1, pcToCall);   --A
    lxDoc2  := REP_I_LIB_GCO_ECC_XML.getGcoComplDataExternalAsaXml(iFromGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1);   --B
    return pProcessComparison(lxDoc1, lxDoc2, GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_EXTERNAL_ASA, iDelete);
  end processGcoComplDataExternalAsa;

  /**
  * fonction processGcoComplDataManufacture
  * Description
  *    Compare les données complémentaires d'achat d'un article (FromGoodId) avec celles d'un autre (ToGoodId).
  */
  function processGcoComplDataManufacture(
    iFromGoodId             in GCO_GOOD.GCO_GOOD_ID%type
  , iToGoodId               in GCO_GOOD.GCO_GOOD_ID%type
  , iDoGenerateCoupledGood  in number
  , iDoGenerateCertifLnk    in number
  , iDoGenerateNomenclature in number
  , iDoGenerateSchedulePlan in number
  , iDelete                 in boolean default true
  )
    return varchar2
  as
    lxDoc1 xmltype;
    lxDoc2 xmltype;
  begin
    lxDoc1  :=
      REP_I_LIB_GCO_ECC_XML.getGcoComplDataManufactureXml(iToGoodId
                                                        , iToGoodId
                                                        , iDoGenerateCoupledGood
                                                        , iDoGenerateCertifLnk
                                                        , iDoGenerateNomenclature
                                                        , iDoGenerateSchedulePlan
                                                        , REP_I_LIB_CONSTANT.COMPARISON
                                                        , 1
                                                        , pcToCall);
    lxDoc2  :=
      REP_I_LIB_GCO_ECC_XML.getGcoComplDataManufactureXml(iFromGoodId
                                                        , iToGoodId
                                                        , iDoGenerateCoupledGood
                                                        , iDoGenerateCertifLnk
                                                        , iDoGenerateNomenclature
                                                        , iDoGenerateSchedulePlan
                                                        , REP_I_LIB_CONSTANT.COMPARISON
                                                        , 1);
    return pProcessComparison(lxDoc1, lxDoc2, GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_MANUFACTURE, iDelete);
  end processGcoComplDataManufacture;

  /**
  * fonction processGcoComplDataSubcontract
  * Description
  *    Compare les données complémentaires de sous-traitance d'un article (FromGoodId) avec celles d'un autre (ToGoodId).
  */
  function processGcoComplDataSubcontract(
    iFromGoodId             in GCO_GOOD.GCO_GOOD_ID%type
  , iToGoodId               in GCO_GOOD.GCO_GOOD_ID%type
  , iDoGenerateNomenclature in integer
  , iDelete                 in boolean default true
  )
    return varchar2
  as
    lxDoc1 xmltype;
    lxDoc2 xmltype;
  begin
    lxDoc1  := REP_I_LIB_GCO_ECC_XML.getGcoComplDataSubcontractXml(iToGoodId, iToGoodId, iDoGenerateNomenclature, REP_I_LIB_CONSTANT.COMPARISON, 1, pcToCall);   --A
    lxDoc2  := REP_I_LIB_GCO_ECC_XML.getGcoComplDataSubcontractXml(iFromGoodId, iToGoodId, iDoGenerateNomenclature, REP_I_LIB_CONSTANT.COMPARISON, 1);   --B
    return pProcessComparison(lxDoc1, lxDoc2, GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_SUBCONTRACT, iDelete);
  end processGcoComplDataSubcontract;

  /**
  * fonction processGcoComplDataDistrib
  * Description
  *    Compare les données complémentaires de sous-traitance d'un article (FromGoodId) avec ceux d'un autre (ToGoodId).
  */
  function processGcoComplDataDistrib(iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type, iToGoodId in GCO_GOOD.GCO_GOOD_ID%type, iDelete in boolean default true)
    return varchar2
  as
    lxDoc1 xmltype;
    lxDoc2 xmltype;
  begin
    lxDoc1  := REP_I_LIB_GCO_ECC_XML.getGcoComplDataDistribXml(iToGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1, pcToCall);   --A
    lxDoc2  := REP_I_LIB_GCO_ECC_XML.getGcoComplDataDistribXml(iFromGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1);   --B
    return pProcessComparison(lxDoc1, lxDoc2, GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_DISTRIB, iDelete);
  end processGcoComplDataDistrib;

  /**
  * fonction processGcoGoodAttribute
  * Description
  *    Compare les attributs d'un article (FromGoodId) avec ceux d'un autre (ToGoodId).
  */
  function processGcoGoodAttribute(iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type, iToGoodId in GCO_GOOD.GCO_GOOD_ID%type, iDelete in boolean default true)
    return varchar2
  as
    lxDoc1 xmltype;
    lxDoc2 xmltype;
  begin
    lxDoc1  := REP_I_LIB_GCO_ECC_XML.getGcoGoodAttributeXml(iToGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1, pcToCall);   --A
    lxDoc2  := REP_I_LIB_GCO_ECC_XML.getGcoGoodAttributeXml(iFromGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1);   --B
    return pProcessComparison(lxDoc1, lxDoc2, GCO_I_LIB_CONSTANT.gcGCO_GOOD_ATTRIBUTE, iDelete);
  end processGcoGoodAttribute;

  /**
  * fonction processPtcFixedCostprice
  * Description
  *    Compare les prix de revient fixes d'un article (FromGoodId) avec ceux d'un autre (ToGoodId).
  */
  function processPtcFixedCostprice(iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type, iToGoodId in GCO_GOOD.GCO_GOOD_ID%type, iDelete in boolean default true)
    return varchar2
  as
    lxDoc1 xmltype;
    lxDoc2 xmltype;
  begin
    lxDoc1  := REP_I_LIB_GCO_ECC_XML.getPtcFixedCostpriceXml(iToGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1, pcToCall);   --A
    lxDoc2  := REP_I_LIB_GCO_ECC_XML.getPtcFixedCostpriceXml(iFromGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1);   --B
    return pProcessComparison(lxDoc1, lxDoc2, GCO_I_LIB_CONSTANT.gcPTC_FIXED_COSTPRICE, iDelete);
  end processPtcFixedCostprice;

  /**
  * fonction processPtcCalcCostprice
  * Description
  *    Compare les prix de revient calculés d'un article (FromGoodId) avec ceux d'un autre (ToGoodId).
  */
  function processPtcCalcCostprice(iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type, iToGoodId in GCO_GOOD.GCO_GOOD_ID%type, iDelete in boolean default true)
    return varchar2
  as
    lxDoc1 xmltype;
    lxDoc2 xmltype;
  begin
    lxDoc1  := REP_I_LIB_GCO_ECC_XML.getPtcCalcCostpriceXml(iToGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1, pcToCall);   --A
    lxDoc2  := REP_I_LIB_GCO_ECC_XML.getPtcCalcCostpriceXml(iFromGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1);   --B
    return pProcessComparison(lxDoc1, lxDoc2, GCO_I_LIB_CONSTANT.gcPTC_CALC_COSTPRICE, iDelete);
  end processPtcCalcCostprice;

  /**
  * fonction processPtcCalcCostprice
  * Description
  *    Compare les tarifs d'un article (FromGoodId) avec ceux d'un autre (ToGoodId).
  */
  function processPtcTariff(iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type, iToGoodId in GCO_GOOD.GCO_GOOD_ID%type, iDelete in boolean default true)
    return varchar2
  as
    lxDoc1 xmltype;
    lxDoc2 xmltype;
  begin
    lxDoc1  := REP_I_LIB_GCO_ECC_XML.getPtcTariffXml(iToGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1, pcToCall);   --A
    lxDoc2  := REP_I_LIB_GCO_ECC_XML.getPtcTariffXml(iFromGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1);   --B
    return pProcessComparison(lxDoc1, lxDoc2, GCO_I_LIB_CONSTANT.gcPTC_TARIFF, iDelete);
  end processPtcTariff;

  /**
  * fonction processPtcDiscountGoodLink
  * Description
  *    Compare les remises d'un article (FromGoodId) avec ceux d'un autre (ToGoodId).
  */
  function processPtcDiscountGoodLink(iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type, iToGoodId in GCO_GOOD.GCO_GOOD_ID%type, iDelete in boolean default true)
    return varchar2
  as
    lxDoc1 xmltype;
    lxDoc2 xmltype;
  begin
    lxDoc1  := REP_I_LIB_GCO_ECC_XML.getPtcDiscountGoodLinkXml(iToGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1, pcToCall);   --A
    lxDoc2  := REP_I_LIB_GCO_ECC_XML.getPtcDiscountGoodLinkXml(iFromGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1);   --B
    return pProcessComparison(lxDoc1, lxDoc2, GCO_I_LIB_CONSTANT.gcPTC_DISCOUNT, iDelete);
  end processPtcDiscountGoodLink;

  /**
  * fonction processPtcChargeGoodLink
  * Description
  *    Compare les taxes d'un article (FromGoodId) avec ceux d'un autre (ToGoodId).
  */
  function processPtcChargeGoodLink(iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type, iToGoodId in GCO_GOOD.GCO_GOOD_ID%type, iDelete in boolean default true)
    return varchar2
  as
    lxDoc1 xmltype;
    lxDoc2 xmltype;
  begin
    lxDoc1  := REP_I_LIB_GCO_ECC_XML.getPtcChargeGoodLinkXml(iToGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1, pcToCall);   --A
    lxDoc2  := REP_I_LIB_GCO_ECC_XML.getPtcChargeGoodLinkXml(iFromGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1);   --B
    return pProcessComparison(lxDoc1, lxDoc2, GCO_I_LIB_CONSTANT.gcPTC_CHARGE, iDelete);
  end processPtcChargeGoodLink;

  /**
  * fonction processGcoPreciousMat
  * Description
  *    Compare les matières précieuses d'un article (FromGoodId) avec ceux d'un autre (ToGoodId).
  */
  function processGcoPreciousMat(iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type, iToGoodId in GCO_GOOD.GCO_GOOD_ID%type, iDelete in boolean default true)
    return varchar2
  as
    lxDoc1 xmltype;
    lxDoc2 xmltype;
  begin
    lxDoc1  := REP_I_LIB_GCO_ECC_XML.getGcoPreciousMatXml(iToGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1, pcToCall);   --A
    lxDoc2  := REP_I_LIB_GCO_ECC_XML.getGcoPreciousMatXml(iFromGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1);   --B
    return pProcessComparison(lxDoc1, lxDoc2, GCO_I_LIB_CONSTANT.gcGCO_PRECIOUS_MAT, iDelete);
  end processGcoPreciousMat;

  /**
  * fonction processGcoConnectedGood
  * Description
  *    Compare les biens connectés d'un article (FromGoodId) avec ceux d'un autre (ToGoodId).
  */
  function processGcoConnectedGood(iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type, iToGoodId in GCO_GOOD.GCO_GOOD_ID%type, iDelete in boolean default true)
    return varchar2
  as
    lxDoc1 xmltype;
    lxDoc2 xmltype;
  begin
    lxDoc1  := REP_I_LIB_GCO_ECC_XML.getGcoConnectedGoodXml(iToGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1, pcToCall);   --A
    lxDoc2  := REP_I_LIB_GCO_ECC_XML.getGcoConnectedGoodXml(iFromGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1);   --B
    return pProcessComparison(lxDoc1, lxDoc2, GCO_I_LIB_CONSTANT.gcGCO_CONNECTED_GOOD, iDelete);
  end processGcoConnectedGood;

  /**
  * fonction processGcoFreeData
  * Description
  *    Compare les données libres d'un article (FromGoodId) avec ceux d'un autre (ToGoodId).
  */
  function processGcoFreeData(iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type, iToGoodId in GCO_GOOD.GCO_GOOD_ID%type, iDelete in boolean default true)
    return varchar2
  as
    lxDoc1 xmltype;
    lxDoc2 xmltype;
  begin
    lxDoc1  := REP_I_LIB_GCO_ECC_XML.getGcoFreeDataXml(iToGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1, pcToCall);   --A
    lxDoc2  := REP_I_LIB_GCO_ECC_XML.getGcoFreeDataXml(iFromGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1);   --B
    return pProcessComparison(lxDoc1, lxDoc2, GCO_I_LIB_CONSTANT.gcFREE_DATA, iDelete);
  end processGcoFreeData;

  /**
  * fonction processVField(
  * Description
  *    Compare les champs virtuels d'un article (FromGoodId) avec ceux d'un autre (ToGoodId).
  */
  function processVField(iFromGoodId in GCO_GOOD.GCO_GOOD_ID%type, iToGoodId in GCO_GOOD.GCO_GOOD_ID%type, iDelete in boolean default true)
    return varchar2
  as
    lxDoc1 xmltype;
    lxDoc2 xmltype;
  begin
    lxDoc1  := REP_I_LIB_ECC_XML.getVFieldXml('GCO_GOOD', iToGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1);
    lxDoc2  := REP_I_LIB_ECC_XML.getVFieldXml('GCO_GOOD', iFromGoodId, REP_I_LIB_CONSTANT.COMPARISON, 1);
    return pProcessComparison(lxDoc1, lxDoc2, GCO_I_LIB_CONSTANT.gcVIRTUAL_FIELDS, iDelete);
  end processVField;

  /**
  * fonction processPpsTool
  * Description
  *    Compare les outils. Inutilisé dans le cadre du FDA.
  */
  function processPpsTool(
    iFromGoodId             in GCO_GOOD.GCO_GOOD_ID%type
  , iToGoodId               in GCO_GOOD.GCO_GOOD_ID%type
  , iDoGenerateSpecialTools in number
  , iDelete                 in boolean default true
  )
    return varchar2
  as
    lxDoc1 xmltype;
    lxDoc2 xmltype;
  begin
    lxDoc1  := REP_I_LIB_GCO_ECC_XML.getPpsToolXml(iToGoodId, iDoGenerateSpecialTools, REP_I_LIB_CONSTANT.COMPARISON, 1, pcToCall);   --A
    lxDoc2  := REP_I_LIB_GCO_ECC_XML.getPpsToolXml(iFromGoodId, iDoGenerateSpecialTools, REP_I_LIB_CONSTANT.COMPARISON, 1);   --B
    return pProcessComparison(lxDoc1, lxDoc2, GCO_I_LIB_CONSTANT.gcPPS_TOOLS, iDelete);
  end processPpsTool;

  /**
  * function loadUpdatedSyncOptions
  * Description
  *   Indique, pour chaque option, si des différences existent dans la table temporaire.
  */
  function loadUpdatedSyncOptions
    return GCO_I_LIB_CONSTANT.gtProductCopySyncOptions
  as
    ltOptions GCO_I_LIB_CONSTANT.gtProductCopySyncOptions;
  begin
    for ltplOption in (select distinct CED.CED_OPTION_TYPE
                                  from V_COM_ECC_DIFF_DATA CED
                                 where COM_LIB_ECC_COMPARISON.isReservedField(CED.CED_FIELD) = 0
                                   and CED.COM_LEVEL = 1
                                   and CED.CED_FIELD <> CED.CED_TABLE || '_ID'
                                   and (   exists(
                                             select CEP.COM_ECC_DIFF_DATA_ID
                                               from V_COM_ECC_DIFF_DATA CEP
                                              where CEP.COM_ECC_DIFF_DATA_PARENT_ID = CED.COM_ECC_DIFF_DATA_ID
                                                and COM_LIB_ECC_COMPARISON.isReservedField(CEP.CED_FIELD) = 0
                                                and CEP.CED_FIELD <> CEP.CED_TABLE || '_ID'
                                                and CEP.CED_TYPE = 'FIELD')
                                        or CED.CED_TYPE = 'FIELD'
                                       )
                              order by CED.CED_OPTION_TYPE) loop
      -- Indique les différences par options
      if ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcFAL_SCHEDULE_PLAN then
        ltOptions.bFAL_SCHEDULE_PLAN  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcFREE_DATA then
        ltOptions.bFREE_DATA  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_ASS then
        ltOptions.bGCO_COMPL_DATA_ASS  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_DISTRIB then
        ltOptions.bGCO_COMPL_DATA_DISTRIB  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_EXTERNAL_ASA then
        ltOptions.bGCO_COMPL_DATA_EXTERNAL_ASA  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_INVENTORY then
        ltOptions.bGCO_COMPL_DATA_INVENTORY  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_MANUFACTURE then
        ltOptions.bGCO_COMPL_DATA_MANUFACTURE  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_PURCHASE then
        ltOptions.bGCO_COMPL_DATA_PURCHASE  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_SALE then
        ltOptions.bGCO_COMPL_DATA_SALE  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_STOCK then
        ltOptions.bGCO_COMPL_DATA_STOCK  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcGCO_COMPL_DATA_SUBCONTRACT then
        ltOptions.bGCO_COMPL_DATA_SUBCONTRACT  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcGCO_CONNECTED_GOOD then
        ltOptions.bGCO_CONNECTED_GOOD  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcGCO_COUPLED_GOOD then
        ltOptions.bGCO_COUPLED_GOOD  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcGCO_GOOD then
        ltOptions.bGCO_GOOD  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcGCO_GOOD_ATTRIBUTE then
        ltOptions.bGCO_GOOD_ATTRIBUTE  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcGCO_PRECIOUS_MAT then
        ltOptions.bGCO_PRECIOUS_MAT  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcPPS_NOMENCLATURE then
        ltOptions.bPPS_NOMENCLATURE  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcPPS_SPECIAL_TOOLS then
        ltOptions.bPPS_SPECIAL_TOOLS  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcPPS_TOOLS then
        ltOptions.bPPS_TOOLS  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcPTC_CALC_COSTPRICE then
        ltOptions.bPTC_CALC_COSTPRICE  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcPTC_CHARGE then
        ltOptions.bPTC_CHARGE  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcPTC_DISCOUNT then
        ltOptions.bPTC_DISCOUNT  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcPTC_FIXED_COSTPRICE then
        ltOptions.bPTC_FIXED_COSTPRICE  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcPTC_TARIFF then
        ltOptions.bPTC_TARIFF  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcSQM_CERTIFICATION then
        ltOptions.bSQM_CERTIFICATION  := 1;
      elsif ltplOption.CED_OPTION_TYPE = GCO_I_LIB_CONSTANT.gcVIRTUAL_FIELDS then
        ltOptions.bVIRTUAL_FIELDS  := 1;
      end if;
    end loop;

    return ltOptions;
  end loadUpdatedSyncOptions;
end COM_PRC_ECC_COMPARISON;
