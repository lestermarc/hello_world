--------------------------------------------------------
--  DDL for Package Body CLA_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "CLA_FUNCTIONS" 
as
  /**
  * Description
  *   retourne le nom des colonnes formant la primary key d'une table
  *   S'il y a plusieurs colonnes dans la primary key, leur nom sera séparé par des ','
  */
  function GetPKColumnsName(iOwner in varchar2, iTableName in varchar2)
    return varchar2
  is
    lResult varchar2(255);
  begin
    -- look in table columns of the current schema
    lResult := PCS.PC_I_LIB_SQL.GetPKColumnsName(iOwner, iTableName);

    -- try to find it via a synonym
    if lResult is null then
      for ltplColName in (select B.COLUMN_NAME
                            from sys.ALL_CONSTRAINTS A
                               , sys.ALL_CONS_COLUMNS B
                               , sys.ALL_SYNONYMS C
                           where B.TABLE_NAME = A.TABLE_NAME
                             and A.TABLE_NAME = ITABLENAME
                             and B.TABLE_NAME = C.TABLE_NAME
                             and C.OWNER = IOWNER
                             and A.OWNER = C.TABLE_OWNER
                             and B.OWNER = A.OWNER
                             and A.CONSTRAINT_TYPE = 'P'
                             and B.CONSTRAINT_NAME = A.CONSTRAINT_NAME) loop
        select decode(lResult, null, null, lResult || ',') || ltplColName.COLUMN_NAME
          into lResult
          from dual;
      end loop;
    end if;

    if lResult is null then
      raise_application_error(-20097, 'PKColumnName not found. iOwner = ' || iOwner || ', iTableName = '|| iTableName);
    end if;

    return lResult;
  end GetPKColumnsName;

  /**
  * Description
  *    copie d'un noeud (avec tous ses fils) dans la même classification
  */
  function copy_hierarchy(aOldNodeId in number, aNewClassifId in number, aNewParentId in number)
    return number
  is
    vNewNodeId number(12);
  begin
    -- curseur sur le noeud à copier
    for tplSourceNode in (select CLASSIFICATION_ID
                               , CN.CLASSIF_NODE_ID
                               , DES_DESCR
                               , PC_LANG_ID
                               , CLN_CODE
                               , CLN_SQLAUTO
                               , CLN_FREE_CHAR_1
                               , CLN_FREE_NUMBER_1
                               , CLN_FREE_BOOLEAN_1
                            from CLASSIF_NODE cn
                               , CLASSIF_NODE_DESCR cnd
                           where cn.CLASSIF_NODE_ID = aOldNodeId
                             and cnd.CLASSIF_NODE_ID = cn.CLASSIF_NODE_ID
                             and cnd.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangId) loop
      select INIT_ID_SEQ.nextval
        into vNewNodeId
        from dual;

      insert_hierarchy(aNewClassifId
                     , tplSourceNode.CLN_CODE
                     , tplSourceNode.DES_DESCR
                     , aNewParentId
                     , null   -- pc_lang_id
                     , tplSourceNode.CLN_SQLAUTO
                     , vNewNodeId
                     , tplSourceNode.CLN_FREE_CHAR_1
                     , tplSourceNode.CLN_FREE_NUMBER_1
                     , tplSourceNode.CLN_FREE_BOOLEAN_1
                      );
    end loop;

    return vNewNodeId;
  end copy_hierarchy;

  /**
  * Description
  *   Effacement d'un noeud et de ses fils
  */
  procedure delete_hierarchy(aNodeId in integer)
  as
    cursor crDelete(cNodeId number)
    is
      select *
        from CLASSIF_NODE
       where CLN_PARENT_ID = cNodeId;
  begin
    -- curseur sur les noeuds enfants à effacer
    for tplDelete in crDelete(aNodeId) loop
      -- appel récursif pour l'effacement des noeud enfant
      delete_hierarchy(tplDelete.classif_node_id);
    end loop;

    -- effacement du noeud courant
    delete from CLASSIF_NODE
          where classif_node_id = aNodeId;
  end delete_hierarchy;

  /**
  * Description
  *   Dans une classif manuelle, effacement d'un élément
  *   Egalement supression dans la mise à plat si existante
  */
  procedure deleteNodeLeaf(aNodeId in integer, aElementId in integer, aDeleted out integer)
  is
    vSqlAuto CLASSIF_NODE.CLN_SQLAUTO%type;
  begin
    begin
      -- recherche de la commande SQL du noeud
      -- seulement pour les classifs manuelles
      select replace(cln_sqlauto, ', ', ',')
        into vSqlAuto
        from classif_node cln
           , classification cla
       where cln.classif_node_id = aNodeId
         and cla.classification_id = cln.classification_id
         and cla.c_classif_type = '1';

      -- si l'id à effacer est dans la commande SQL du noeud, procedure de suppression
      if instr(vSqlAuto, ',' || aElementId || ',') > 0 then
        aDeleted  := 1;

        -- mise à jour de la commande sql du noeud
        update classif_node
           set cln_sqlauto = replace(vSqlAuto, ',' || aElementId || ',', ',')
         where classif_node_id = aNodeId;

        -- suppression d'une éventuelle occurence dans la mise à plat
        delete from classif_flat
              where cfl_node_id = aNodeId
                and classif_leaf_id = aElementId;
      elsif instr(vSqlAuto, ',' || aElementId || ')') > 0 then
        aDeleted  := 1;

        -- mise à jour de la commande sql du noeud
        update classif_node
           set cln_sqlauto = replace(vSqlAuto, ',' || aElementId || ',', ')')
         where classif_node_id = aNodeId;

        -- suppression d'une éventuelle occurence dans la mise à plat
        delete from classif_flat
              where cfl_node_id = aNodeId
                and classif_leaf_id = aElementId;
      else
        aDeleted  := 0;
      end if;
    exception
      when no_data_found then
        aDeleted  := 0;
    end;
  end deleteNodeLeaf;

  /**
  * Description
  *   Dans une classif manuelle, insertion d'un élément
  */
  procedure insertNodeLeaf(aNodeId in integer, aElementId in integer)
  is
    lSqlAuto          CLASSIF_NODE.CLN_SQLAUTO%type;
    lTableName        CLASSIF_TABLES.CTA_TABLENAME%type;
    lIdFieldName      CLASSIF_TABLES.CTA_TABLENAME%type;
    lClassificationId CLASSIFICATION.CLASSIFICATION_ID%type;
  begin
    begin
      -- recherche de la commande SQL du noeud
      -- seulement pour les classifs manuelles
      select cln.classification_id
           , CleanStr(cln_sqlauto)
        into lClassificationId
           , lSqlAuto
        from classif_node cln
           , classification cla
       where cln.classif_node_id = aNodeId
         and cla.classification_id = cln.classification_id
         and cla.c_classif_type = '1';
      -- test pour éviter un problème avec des classif dont la commande serait erronnée
      if lSqlAuto is null or upper(substr(lSqlAuto,1,6)) <> 'SELECT' then
        select CTA_TABLENAME
          into lTableName
          from CLASSIF_TABLES
         where CLASSIFICATION_ID = lClassificationId;

        lIdFieldName  := PCS.PC_I_LIB_SQL.GetPKColumnsName(PCS.PC_I_LIB_SESSION.GetCompanyOwner, lTableName);
        lSqlAuto      :=
          'SELECT ' || lTableName || '1.' || lIdFieldName || ' FROM ' || lTableName || ' ' || lTableName || '1 WHERE ' || lTableName || '1.' || lIdFieldName
          || ' IN (0,0)';
      end if;

      -- mise à jour de la commande sql du noeud
      update classif_node
         set cln_sqlauto = replace(lSqlAuto, '(0,', '(0,' || aElementId || ',')
       where classif_node_id = aNodeId;
    exception
      when no_data_found then
        ra('PCS - Node not found');
    end;
  end insertNodeLeaf;

  /**
  * Description
  *   Recherche de l'existance d'un élément dans un noeud de classif manuelle
  *   Egalement supression dans la mise à plat si existante
  */
  function existNodeLeaf(aNodeId in integer, aElementId in integer)
    return number
  is
    vSqlAuto CLASSIF_NODE.CLN_SQLAUTO%type;
    vResult  number(1);
  begin
    -- recherche de la commande SQL du noeud
    -- seulement pour les classifs manuelles
    select cln_sqlauto
      into vSqlAuto
      from classif_node cln
         , classification cla
     where cln.classif_node_id = aNodeId
       and cla.classification_id = cln.classification_id
       and cla.c_classif_type = '1';

    -- si l'id à effacer est dans la commande SQL du noeud, procedure de suppression
    if instr(vSqlAuto, ',' || aElementId || ',') > 0 then
      vResult  := 1;
    else
      vResult  := 0;
    end if;

    return vResult;
  end existNodeLeaf;

  /**
  * Description
  *   insertion d'un noeud
  */
  procedure insert_hierarchy(
    aClassificationId in     number
  , aCode             in     varchar2
  , aDescription      in     varchar2
  , aParentId         in     number
  , aLangId           in     number
  , aSqlAuto          in     varchar2
  , aNodeId           in out number
  , aFreeChar         in     varchar2 default ''
  , aFreeNumber       in     number default 0
  , aFreeBoolean      in     number default 0
  )
  is
    lUniqueKey   CLASSIF_NODE.CLN_UNIQUE_KEY%type;
    lSqlAuto     CLASSIF_NODE.CLN_SQLAUTO%type;
    lTableName   CLASSIF_TABLES.CTA_TABLENAME%type;
    lIdFieldName CLASSIF_TABLES.CTA_TABLENAME%type;
  begin
    select init_id_seq.nextval
      into aNodeId
      from dual;

    if aParentId = 0 then
      select CLA_UNIQUE_KEY
        into lUniqueKey
        from CLASSIFICATION
       where CLASSIFICATION_ID = aClassificationId;
    else
      select CLN_UNIQUE_KEY || '.' || aDescription
        into lUniqueKey
        from CLASSIF_NODE
       where CLASSIF_NODE_ID = aParentId;
    end if;

    if aSqlAuto is null then
      select CTA_TABLENAME
        into lTableName
        from CLASSIF_TABLES
       where CLASSIFICATION_ID = aClassificationId;

      lIdFieldName  := PCS.PC_I_LIB_SQL.GetPKColumnsName(PCS.PC_I_LIB_SESSION.GetCompanyOwner, lTableName);
      lSqlAuto      :=
        'SELECT ' || lTableName || '1.' || lIdFieldName || ' FROM ' || lTableName || ' ' || lTableName || '1 WHERE ' || lTableName || '1.' || lIdFieldName
        || ' IN (0,0)';
    else
      lSqlAuto  := aSqlAuto;
    end if;

    -- insertion dans la table classif_node
    insert into CLASSIF_NODE
                (CLASSIF_NODE_ID
               , CLASSIFICATION_ID
               , CLN_CODE
               , CLN_PARENT_ID
               , CLN_SQLAUTO
               , CLN_FREE_CHAR_1
               , CLN_FREE_NUMBER_1
               , CLN_FREE_BOOLEAN_1
               , CLN_NAME
               , CLN_UNIQUE_KEY
               , A_DATECRE
               , A_IDCRE
                )
         values (aNodeId
               , aClassificationId
               , aCode
               , aParentId
               , lSqlAuto
               , aFreeChar
               , aFreeNumber
               , aFreeBoolean
               , aDescription
               , lUniqueKey
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    -- si pas de langue définie, on insère dans toutes les langue sinon dans la langue spécifiée
    if nvl(aLangId, 0) = 0 then
      -- curseur sur les langues actives dans la société
      for tplLanguage in (select PC_LANG_ID
                            from PCS.PC_LANG
                           where LANUSED = 1) loop
        insert into CLASSIF_NODE_DESCR
                    (CLASSIF_NODE_ID
                   , PC_LANG_ID
                   , DES_DESCR
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (aNodeId
                   , tplLanguage.PC_LANG_ID
                   , aDescription
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );
      end loop;
    else
      insert into CLASSIF_NODE_DESCR
                  (CLASSIF_NODE_ID
                 , PC_LANG_ID
                 , DES_DESCR
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (aNodeId
                 , aLangId
                 , aDescription
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end if;
  end insert_hierarchy;

  /**
  * Description
  *     Déplacement d'une branche
  */
  procedure move_hierarchy(aSourceNodeId in integer, aDestNodeId in integer)
  is
  begin
    update CLASSIF_NODE
       set CLN_PARENT_ID = aDestNodeId
     where CLASSIF_NODE_ID = aSourceNodeId;
  end move_hierarchy;

  /**
  * Description
  *      procedure de mise à jour d'un noeud de classification
  */
  procedure update_node(
    aNodeId      in     integer
  , aSqlAuto     in     varchar2
  , aCode        in     varchar2
  , aDescription in     varchar2
  , aFreeChar    in     varchar2
  , aFreeNumber  in     number
  , aFreeBoolean in     number
  , aLangId      in out integer
  )
  is
    vDescrNodeId CLASSIF_NODE.CLASSIF_NODE_ID%type;
  begin
    -- mise à jour de la table classif_node
    update CLASSIF_NODE
       set CLN_SQLAUTO = aSqlAuto
         , CLN_CODE = aCode
         , CLN_FREE_CHAR_1 = aFreeChar
         , CLN_FREE_NUMBER_1 = aFreeNumber
         , CLN_FREE_BOOLEAN_1 = aFreeBoolean
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where CLASSIF_NODE_ID = aNodeId;

    if aLangId = 0 then
      select max(CLASSIF_NODE_ID)
           , max(PC_LANG_ID)
        into vDescrNodeId
           , aLangId
        from CLASSIF_NODE_DESCR
       where CLASSIF_NODE_ID = aNodeId;
    else
      select max(CLASSIF_NODE_ID)
           , max(PC_LANG_ID)
        into vDescrNodeId
           , aLangId
        from CLASSIF_NODE_DESCR
       where CLASSIF_NODE_ID = aNodeId
         and PC_LANG_ID = aLangId;
    end if;

    if (vDescrNodeId > 0) then
      update CLASSIF_NODE_DESCR
         set DES_DESCR = aDescription
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where CLASSIF_NODE_ID = aNodeId
         and PC_LANG_ID = aLangId;
    else
      insert into CLASSIF_NODE_DESCR
                  (CLASSIF_NODE_ID
                 , PC_LANG_ID
                 , DES_DESCR
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (aNodeId
                 , aLangId
                 , aDescription
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end if;
  end update_node;

  /**
  * Description
  *    copie d'un noeud (avec tous ses fils) dans la même classification
  */
  procedure createbranche_hierarchy(aOldClassifId in number, aOldNodeId in number, aNewClassifId in number, aNewParentId in number)
  is
    -- curseur sur un noeud
    cursor crNewNode(old_parent_id number, cOldClassifId number)
    is
      select classif_node_id
           , classif_tables_id
        from CLASSIF_NODE
       where CLN_PARENT_ID = old_parent_id
         and CLASSIFICATION_ID = cOldClassifId;

    ltplNewNode crNewNode%rowtype;
    vNewNodeId  classif_node.classif_node_id%type;
  begin
    -- insertion de la nouvelle racine
    vNewNodeId  := copy_hierarchy(aOldNodeId, aNewClassifId, aNewParentId);

    -- recherche des enfants de la racine
    -- boucle sur les enfants
    for ltplNewNode in crNewNode(aOldNodeId, aOldClassifId) loop
      -- appel récursif de la fonction pour les enfants des enfants
      createbranche_hierarchy(aOldClassifId, ltplNewNode.classif_node_id, aNewClassifId, vNewNodeId);
    end loop;
  end createbranche_hierarchy;

  /**
  * Description
  *   Copie d'une classification complète
  */
  procedure copy_classification(aOldClassifId in number, aNewClassifId in out number, aNewClassifName in out varchar2, aLangId in number, aSqlAuto in varchar2)
  is
  begin
    copyClassifInterCompany(aOldClassifId, null, aNewClassifId, aNewClassifName, aLangId);
  end copy_classification;

  /**
  * Description
  *    copie d'un noeud (avec tous ses fils) dans la même classification
  */
  function copyHierarchyInter(aOldNodeId in number, aNewClassifId in number, aNewParentId in number, aCompOwner in varchar2, aCompDbLink in varchar2)
    return number
  is
    -- curseur sur le noeud à copier
    cursor crSourceNode(cNodeId number)
    is
      select classification_id
           , cn.classif_node_id
           , des_descr
           , pc_lang_id
           , cln_code
           , cln_name
           , cln_unique_key
           , cln_sqlauto
           , cln_free_char_1
           , cln_free_number_1
           , cln_free_boolean_1
        from CLASSIF_NODE cn
           , CLASSIF_NODE_DESCR cnd
       where cn.classif_node_id = cNodeId
         and cnd.classif_node_id = cn.classif_node_id;

    tplSourceNode crSourceNode%rowtype;
    vNewNodeId    number(12);
    vSqlStatement varchar2(10000);
  begin
    -- ouverture du curseur sur le noeud source
    open crSourceNode(aOldNodeId);

    fetch crSourceNode
     into tplSourceNode;

    if crSourceNode%found then
      if aCompDbLink is not null then
        execute immediate 'select ' || aCompOwner || '.INIT_ID_SEQ.NEXTVAL@' || aCompDbLink || ' from DUAL'
                     into vNewNodeId;
      else
        execute immediate 'select ' || aCompOwner || '.INIT_ID_SEQ.NEXTVAL from DUAL'
                     into vNewNodeId;
      end if;

      -- création dans la table CLASSIF_NODE
      -- chargement de la commande SQL
      vSqlStatement  := PCS.PC_FUNCTIONS.GetSql('CLASSIFICATION', 'COPY_INTER', 'CLASSIF_NODE');
      -- remplacement du nom de l'owner de destination
      vSqlStatement  := replace(vSqlStatement, '[DESTINATION_OWNER]', aCompOwner);

      -- remplacement du DB_LINK de destination
      if aCompDbLink is not null then
        vSqlStatement  := replace(vSqlStatement, '@[DESTINATION_DB_LINK]', '@' || aCompDbLink);
      else
        vSqlStatement  := replace(vSqlStatement, '@[DESTINATION_DB_LINK]', ' ');
      end if;

      execute immediate vSqlStatement
                  using vNewNodeId
                      , aNewClassifId
                      , tplSourceNode.cln_code
                      , tplSourceNode.cln_name
                      , tplSourceNode.cln_unique_key
                      , aNewParentId
                      , tplSourceNode.cln_sqlauto
                      , tplSourceNode.cln_free_char_1
                      , tplSourceNode.cln_free_number_1
                      , tplSourceNode.cln_free_boolean_1;

      if aCompDbLink is not null then
        commit;
      end if;

      while crSourceNode%found loop
        -- création dans la table CLASSIF_NODE_DESCR
        -- chargement de la commande SQL
        vSqlStatement  := PCS.PC_FUNCTIONS.GetSql('CLASSIFICATION', 'COPY_INTER', 'CLASSIF_NODE_DESCR');
        -- remplacement du nom de l'owner de destination
        vSqlStatement  := replace(vSqlStatement, '[DESTINATION_OWNER]', aCompOwner);

        -- remplacement du DB_LINK de destination
        if aCompDbLink is not null then
          vSqlStatement  := replace(vSqlStatement, '@[DESTINATION_DB_LINK]', '@' || aCompDbLink);
        else
          vSqlStatement  := replace(vSqlStatement, '@[DESTINATION_DB_LINK]', ' ');
        end if;

        execute immediate vSqlStatement
                    using vNewNodeId, tplSourceNode.pc_lang_id, tplSourceNode.des_descr;

        if aCompDbLink is not null then
          commit;
        end if;

        fetch crSourceNode
         into tplSourceNode;
      end loop;
    end if;

    close crSourceNode;

    return vNewNodeId;
  end copyHierarchyInter;

  /**
  * Description
  *    copie d'un noeud (avec tous ses fils) dans la même classification
  * pour copie inter société
  */
  procedure createBrancheHierarchyInter(
    aOldClassifId in number
  , aOldNodeId    in number
  , aNewClassifId in number
  , aNewParentId  in number
  , aCompOwner    in varchar2
  , aCompDbLink   in varchar2
  )
  is
    -- curseur sur un noeud
    cursor crNewNodeCursor(cOldParentId number, cOldClassifId number)
    is
      select classif_node_id
           , classif_tables_id
        from CLASSIF_NODE
       where cln_parent_id = cOldParentId
         and classification_id = cOldClassifId;

    vNewNodeId classif_node.classif_node_id%type;
  begin
    -- insertion de la nouvelle racine
    vNewNodeId  := copyHierarchyInter(aOldNodeId, aNewClassifId, aNewParentId, aCompOwner, aCompDbLink);

    -- recherche des enfants de la racine
    -- boucle sur les enfants
    for ltplNewNode in crNewNodeCursor(aOldNodeId, aOldClassifId) loop
      -- appel récursif de la fonction pour les enfants des enfants
      createBrancheHierarchyInter(aOldClassifId, ltplNewNode.classif_node_id, aNewClassifId, vNewNodeId, aCompOwner, aCompDbLink);
    end loop;
  end createBrancheHierarchyInter;

  /**
  * Description
  *    Recherche le nom de la nouvelle clasif à créer
  */
  function GetNewClassifName(aSourceClassifID in number, aNewClassifName in varchar2, aCompOwner in varchar2, aCompDbLink in varchar2)
    return varchar2
  is
    vResult        CLASSIFICATION.CLA_DESCR%type;
    vSqlStatement  varchar2(10000);
    vNumDuplicates pls_integer;

    -- "incrémente" le nom de la classification
    function incName(aName varchar2)
      return varchar2
    is
      vResult CLASSIFICATION.CLA_DESCR%type;
    begin
      if     (substr(aName, -3, 1) = '(')
         and (substr(aName, -1, 1) = ')')
         and pcsToNumber(substr(aName, -2, 1) ) is not null then
        return substr(aName, 1, length(aName) - 4) || ' (' || to_char(to_number(substr(aName, -2, 1) ) + 1) || ')';
      else
        return aName || ' (1)';
      end if;
    end incName;
  begin
    if aNewClassifName is null then
      select CLA_DESCR
        into vResult
        from CLASSIFICATION
       where CLASSIFICATION_ID = aSourceClassifId;
    else
      vResult  := aNewClassifName;
    end if;

    vSqlStatement  := PCS.PC_FUNCTIONS.GetSql('CLASSIFICATION', 'COPY_INTER', 'VERIFY_DUPLICATES');
    -- remplacement du nom de l'owner de destination
    vSqlStatement  := replace(vSqlStatement, '[DESTINATION_OWNER]', aCompOwner);

    -- remplacement du DB_LINK de destination
    if aCompDbLink is not null then
      vSqlStatement  := replace(vSqlStatement, '@[DESTINATION_DB_LINK]', '@' || aCompDbLink);
    else
      vSqlStatement  := replace(vSqlStatement, '@[DESTINATION_DB_LINK]', ' ');
    end if;

    execute immediate vSqlStatement
                 into vNumDuplicates
                using aSourceClassifId, vResult;

    if vNumDuplicates = 0 then
      return vResult;
    else
      return GetNewClassifName(aSourceClassifId, incName(vResult), aCompOwner, aCompDbLink);
    end if;
  end GetNewClassifName;

  /**
  * Description
  *   Copie de classification inter sociétés
  */
  procedure copyClassifInterCompany(
    aOldClassifId      in     number
  , aDestinationCompId in     number
  , aNewClassifId      in out number
  , aNewClassifName    in out varchar2
  , aLangId            in     number default null
  )
  is
    -- curseur sur un noeud
    cursor crNewNode(cClassifId number)
    is
      select b.classif_node_id
        from CLASSIF_NODE a
           , CLASSIF_NODE b
       where a.classification_id = cClassifId
         and a.cln_parent_id = 0
         and b.cln_parent_id = a.classif_node_id;

    cursor crSqlDisplay(cOldClassifId number)
    is
      select sql_display_code
           , "SQL"
           , sysdate
           , pcs.PC_I_LIB_SESSION.getuserini
        from CLASSIF_SQL_DISPLAY
           , CLASSIF_TABLES
       where classification_id = cOldClassifId
         and classif_sql_display.classif_tables_id = classif_tables.classif_tables_id;

    vNewNodeId          classif_node.classif_node_id%type;
    ltplSqlDisplay      crSqlDisplay%rowtype;
    vNewClassifTablesId number(12);
    vSqlCode            varchar2(10000);
    vCompOwner          PCS.PC_SCRIP.SCRDBOWNER%type;
    vCompDbLink         PCS.PC_SCRIP.SCRDB_LINK%type;
    vSqlStatement       varchar2(10000);
  begin
    if aDestinationCompId is not null then
      select SCRDBOWNER
           , SCRDB_LINK
        into vCompOwner
           , vCompDbLink
        from PCS.PC_SCRIP SCR
           , PCS.PC_COMP COM
       where SCR.PC_SCRIP_ID = COM.PC_SCRIP_ID
         and COM.PC_COMP_ID = aDestinationCompId;
    else
      vCompOwner  := PCS.PC_I_LIB_SESSION.GetCompanyOwner;
    end if;

    if aNewClassifId is null then
      if vCompDbLink is not null then
        execute immediate 'select ' || vCompOwner || '.INIT_ID_SEQ.NEXTVAL@' || vCompDbLink || ' from DUAL'
                     into aNewClassifId;
      else
        execute immediate 'select ' || vCompOwner || '.INIT_ID_SEQ.NEXTVAL from DUAL'
                     into aNewClassifId;
      end if;
    end if;

    -- recherche du nom de la nouvelle classification
    aNewClassifName  := GetNewClassifName(aOldClassifId, aNewClassifName, vCompOwner, vCompDbLink);
    -- création dans la table CLASSIFICATION
    -- chargement de la commande SQL
    vSqlStatement    := PCS.PC_FUNCTIONS.GetSql('CLASSIFICATION', 'COPY_INTER', 'CLASSIFICATION');
    -- remplacement du nom de l'owner de destination
    vSqlStatement    := replace(vSqlStatement, '[DESTINATION_OWNER]', vCompOwner);

    -- remplacement du DB_LINK de destination
    if vCompDbLink is not null then
      vSqlStatement  := replace(vSqlStatement, '@[DESTINATION_DB_LINK]', '@' || vCompDbLink);
    else
      vSqlStatement  := replace(vSqlStatement, '@[DESTINATION_DB_LINK]', ' ');
    end if;

    -- execution de la commande
    execute immediate vSqlStatement
                using aNewClassifId, aNewClassifName, aOldClassifId;

    if vCompDbLink is not null then
      commit;
    end if;

    select init_id_seq.nextval
      into vNewClassifTablesId
      from dual;

    -- création dans la table CLASSIF_TABLES
    -- chargement de la commande SQL
    vSqlStatement    := PCS.PC_FUNCTIONS.GetSql('CLASSIFICATION', 'COPY_INTER', 'CLASSIF_TABLES');
    -- remplacement du nom de l'owner de destination
    vSqlStatement    := replace(vSqlStatement, '[DESTINATION_OWNER]', vCompOwner);

    -- remplacement du DB_LINK de destination
    if vCompDbLink is not null then
      vSqlStatement  := replace(vSqlStatement, '@[DESTINATION_DB_LINK]', '@' || vCompDbLink);
    else
      vSqlStatement  := replace(vSqlStatement, '@[DESTINATION_DB_LINK]', ' ');
    end if;

    execute immediate vSqlStatement
                using vNewClassifTablesId, aNewClassifId, aOldClassifId;

    if vCompDbLink is not null then
      commit;
    end if;

    open crSqlDisplay(aOldClassifId);

    fetch crSqlDisplay
     into ltplSqlDisplay;

    -- création dans la table cCLASSIF_SQL_DISPLAY
    -- chargement de la commande SQL
    vSqlStatement    := PCS.PC_FUNCTIONS.GetSql('CLASSIFICATION', 'COPY_INTER', 'CLASSIF_SQL_DISPLAY');
    -- remplacement du nom de l'owner de destination
    vSqlStatement    := replace(vSqlStatement, '[DESTINATION_OWNER]', vCompOwner);

    -- remplacement du DB_LINK de destination
    if vCompDbLink is not null then
      vSqlStatement  := replace(vSqlStatement, '@[DESTINATION_DB_LINK]', '@' || vCompDbLink);
    else
      vSqlStatement  := replace(vSqlStatement, '@[DESTINATION_DB_LINK]', ' ');
    end if;

    execute immediate vSqlStatement
                using vNewClassifTablesId, ltplSqlDisplay.sql_display_code, ltplSqlDisplay."SQL";

    if vCompDbLink is not null then
      commit;
    end if;

    close crSqlDisplay;

    -- création dans la table CLASSIF_LEVEL
    -- chargement de la commande SQL
    vSqlStatement    := PCS.PC_FUNCTIONS.GetSql('CLASSIFICATION', 'COPY_INTER', 'CLASSIF_LEVEL');
    -- remplacement du nom de l'owner de destination
    vSqlStatement    := replace(vSqlStatement, '[DESTINATION_OWNER]', vCompOwner);

    -- remplacement du DB_LINK de destination
    if vCompDbLink is not null then
      vSqlStatement  := replace(vSqlStatement, '@[DESTINATION_DB_LINK]', '@' || vCompDbLink);
    else
      vSqlStatement  := replace(vSqlStatement, '@[DESTINATION_DB_LINK]', ' ');
    end if;

    execute immediate vSqlStatement
                using aNewClassifId, aOldClassifId;

    if vCompDbLink is not null then
      commit;
    end if;

    select CLN_SQLAUTO
      into vSqlCode
      from CLASSIF_NODE
     where CLASSIFICATION_ID = aOldClassifId
       and nvl(cln_parent_id, 0) = 0;

    -- création du noeud 0
    -- chargement de la commande SQL
    vSqlStatement    := PCS.PC_FUNCTIONS.GetSql('CLASSIFICATION', 'COPY_INTER', 'CREATE_ROOT_NODE', null, 'ANSI SQL', false);
    -- remplacement du nom de l'owner de destination
    vSqlStatement    := replace(vSqlStatement, '[DESTINATION_OWNER]', vCompOwner);

    -- remplacement du DB_LINK de destination
    if vCompDbLink is not null then
      vSqlStatement  := replace(vSqlStatement, '@[DESTINATION_DB_LINK]', '@' || vCompDbLink);
    else
      vSqlStatement  := replace(vSqlStatement, '@[DESTINATION_DB_LINK]', ' ');
    end if;

    execute immediate vSqlStatement
                using aNewClassifId, aNewClassifName, aLangId, vSqlCode, in out vNewNodeId;

    if vCompDbLink is not null then
      commit;
    end if;

    -- recherche des enfants de la racine
    -- boucle sur les enfants
    for ltplNewNode in crNewNode(aOldClassifId) loop
      -- appel récursif de la fonction pour les enfants des enfants
      createBrancheHierarchyInter(aOldClassifId, ltplNewNode.classif_node_id, aNewClassifId, vNewNodeId, vCompOwner, vCompDbLink);
    end loop;
  end copyClassifInterCompany;

  procedure FormatSqlDisplay(aSqlDisplay in out varchar2)
  is
    i           pls_integer    := 1;
    vFieldExpr  varchar2(1000);
    vFieldName  varchar2(1000);
    vCodeField  varchar2(1000);
    vLangField  varchar2(1000);
    vDescrField varchar2(1000);
    vPosFrom    number;
  begin
    vCodeField   := 'NULL CODE';
    vLangField   := 'NULL PC_LANG_ID';
    vFieldExpr   := trim(PCS.PC_LIB_SQL.GetSqlCommandFieldNoName(aSqlDisplay, i, 0) );
    vFieldName   := trim(nvl(PCS.PC_LIB_SQL.GetSqlCommandFieldNoName(aSqlDisplay, i, 1), PCS.PC_LIB_SQL.GetSqlCommandFieldNoName(aSqlDisplay, i, 0) ) );

    while vFieldExpr is not null loop
      if upper(vFieldName) = 'CODE' then
        vCodeField  := vFieldExpr || ' CODE';
      elsif upper(vFieldName) = 'PC_LANG_ID' then
        vLangField  := vFieldExpr || ' PC_LANG_ID';
      else
        select decode(trim(vDescrField), null, vFieldExpr, vDescrField || '||'' ''||' || vFieldExpr)
          into vDescrField
          from dual;
      end if;

      i           := i + 1;
      vFieldExpr  := trim(PCS.PC_LIB_SQL.GetSqlCommandFieldNoName(aSqlDisplay, i, 0) );
      vFieldName  := trim(nvl(PCS.PC_LIB_SQL.GetSqlCommandFieldNoName(aSqlDisplay, i, 1), PCS.PC_LIB_SQL.GetSqlCommandFieldNoName(aSqlDisplay, i, 0) ) );
    end loop;

    vPosFrom     := instr(upper(replace(replace(replace(aSqlDisplay, chr(10), ' '), chr(13), ' '), chr(9), ' ') ), ' FROM ');
    aSqlDisplay  := 'SELECT ' || vCodeField || ',' || vLangField || ',' || vDescrField || ' DESCRIPTION ' || substr(aSqlDisplay, vPosFrom);
  end FormatSqlDisplay;

  /**
  * Description
  *   procedure de mise à plat d'une classification
  */
  procedure flat_classification(
    aClassificationId in number
  , aParam1           in varchar2 default null
  , aParam2           in varchar2 default null
  , aParam3           in varchar2 default null
  , aParam4           in varchar2 default null
  , aParam5           in varchar2 default null
  )
  is
    vFirstNodeId CLASSIF_NODE.CLASSIF_NODE_ID%type;
    vClassifType CLASSIFICATION.C_CLASSIF_TYPE%type;
    vTableName   varchar2(30);
    vSqlDisplay  varchar2(4000);
    vIdField     varchar2(30);
    i            pls_integer;
    pragma autonomous_transaction;
  begin
    select C_CLASSIF_TYPE
      into vClassifType
      from CLASSIFICATION
     where CLASSIFICATION_ID = aClassificationId;

    -- supression de l'ancienne mise à plat
    delete from classif_flat
          where classification_id = aClassificationId;

    -- recherche de l'id du premier noeud
    select max(classif_node_id)
      into vFirstNodeId
      from classif_node
     where classification_id = aClassificationId
       and cln_parent_id = 0;

    select cta.cta_tablename
         , csd."SQL" SQLCMD
      into vTableName
         , vSqlDisplay
      from classif_tables cta
         , classif_sql_display csd
     where cta.classification_id = aClassificationId
       and csd.classif_tables_id = cta.classif_tables_id;

    -- formatage de la commande vSqlDisplay
    FormatSqlDisplay(vSqlDisplay);

    select LAN.PC_LANG_ID
    bulk collect into tblLanUsed
      from PCS.PC_LANG LAN
     where (    PCS.PC_CONFIG.GetConfigUpper('CLA_Multi_Language') = 'TRUE'
            and LAN.LANUSED = 1)
        or (    PCS.PC_CONFIG.GetConfigUpper('CLA_Multi_Language') = 'FALSE'
            and PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetCompLangId);

    -- si on a trouvé le premier noeud, on lance la mise à plat récursive
    if vFirstNodeId is not null then
      insert into classif_flat
                  (classif_flat_id
                 , classification_id
                 , node01
                 , cfl_node_id
                 , pc_lang_id
                  )
        select init_id_seq.nextval
             , cln.classification_id
             , cast(decode(cln.cln_code, null, null, cln.cln_code || ' ') || cld.des_descr as varchar2(121))
             , cln.classif_node_id
             , cld.pc_lang_id
          from classif_node cln
             , classif_node_descr cld
         where cln.cln_parent_id = 0
           and cld.classif_node_id = cln.classif_node_id
           and classification_id = aClassificationId
           and (   PCS.PC_CONFIG.GetConfigUpper('CLA_Multi_Language') = 'TRUE'
                or (    PCS.PC_CONFIG.GetConfigUpper('CLA_Multi_Language') = 'FALSE'
                    and CLD.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetCompLangId)
               );

      vIdField  := GetPKColumnsName(PCS.PC_I_LIB_SESSION.GetCompanyOwner, vTableName);
      for i in tblLanUsed.first .. tblLanUsed.last loop
        -- Types de classifications manuelles et semi-automatique
        if vClassifType in('1', '2') then
          -- traitement des noeuds enfants
          flat_node(aClassificationId, vFirstNodeId, 2, vSqlDisplay, vTableName, vIdField, tblLanUsed(i), aParam1, aParam2, aParam3, aParam4, aParam5);
        -- classifs automatiques
        else
          flat_node_level(aClassificationId, vFirstNodeId, 0, 0, vSqlDisplay, vTableName, vIdField, tblLanUsed(i), aParam1, aParam2, aParam3, aParam4, aParam5);
        end if;
      end loop;
    end if;

    update classification
       set CLA_LAST_FLAT_DATE = sysdate
     where CLASSIFICATION_ID = aClassificationId;

    commit;
  end flat_classification;

  procedure DefineColumns(aCursor in integer)
  is
    tblColumns DBMS_SQL.desc_tab;
    vColCnt    integer;
    i          integer;
    vDescr     varchar2(150);
  begin
    DBMS_SQL.describe_columns(aCursor, vColCnt, tblColumns);

    for i in tblColumns.first .. tblColumns.last loop
      DBMS_SQL.DEFINE_COLUMN(aCursor, i, vDescr, 150);
    end loop;
  end DefineColumns;

  procedure BindVariables(
    aCursor in integer
  , aParam1 in varchar2 default null
  , aParam2 in varchar2 default null
  , aParam3 in varchar2 default null
  , aParam4 in varchar2 default null
  , aParam5 in varchar2 default null
  )
  is
  begin
    begin
      DBMS_SQL.BIND_VARIABLE_CHAR(aCursor, 'EXTPARAM1', aParam1);
    exception
      when ex.BIND_VARIABLE_NOT_EXISTS then
        null;
    end;

    begin
      DBMS_SQL.BIND_VARIABLE_CHAR(aCursor, 'EXTPARAM2', aParam2);
    exception
      when ex.BIND_VARIABLE_NOT_EXISTS then
        null;
    end;

    begin
      DBMS_SQL.BIND_VARIABLE_CHAR(aCursor, 'EXTPARAM3', aParam3);
    exception
      when ex.BIND_VARIABLE_NOT_EXISTS then
        null;
    end;

    begin
      DBMS_SQL.BIND_VARIABLE_CHAR(aCursor, 'EXTPARAM4', aParam4);
    exception
      when ex.BIND_VARIABLE_NOT_EXISTS then
        null;
    end;

    begin
      DBMS_SQL.BIND_VARIABLE_CHAR(aCursor, 'EXTPARAM5', aParam5);
    exception
      when ex.BIND_VARIABLE_NOT_EXISTS then
        null;
    end;
  end;

  function GetLevelSqlCommand(iClassificationId in number, iTreeLevel in number, iType in varchar2)
    return varchar2
  is
    lResult varchar2(4000);
  begin
    if iType = 'NODE' then
      select CLE_SQL_COMMAND_NODE
        into lResult
        from CLASSIF_LEVEL
       where CLASSIFICATION_ID = iClassificationId
         and CLE_LEVEL = iTreeLevel;
    else
      select CLE_SQL_COMMAND_LEAF
        into lResult
        from CLASSIF_LEVEL
       where CLASSIFICATION_ID = iClassificationId
         and CLE_LEVEL = iTreeLevel;
    end if;

    return lResult;
  exception
    when no_data_found then
      return null;
  end GetLevelSqlCommand;

  procedure FormatSqlNodeLevel(aSqlNodeLevel in out varchar2)
  is
    i             pls_integer    := 1;
    vFieldExpr    varchar2(4000);
    vFieldName    varchar2(4000);
    vRuptureField varchar2(4000);
    vPosFrom      number;
    vPosSelect    number;
  begin
    vFieldExpr  := trim(PCS.PC_LIB_SQL.GetSqlCommandFieldNoName(aSqlNodeLevel, i, 0) );
    vFieldName  :=
             trim(cleanstr(nvl(PCS.PC_LIB_SQL.GetSqlCommandFieldNoName(aSqlNodeLevel, i, 1), PCS.PC_LIB_SQL.GetSqlCommandFieldNoName(aSqlNodeLevel, i, 0) ) ) );

    while vFieldExpr is not null loop
      if instr(upper(vFieldName), 'PC_LANG_ID') = 0 then
        select decode(trim(vRuptureField), null, vFieldExpr, vRuptureField || '||'' ''||' || vFieldExpr)
          into vRuptureField
          from dual;
      end if;

      i           := i + 1;
      vFieldExpr  := trim(PCS.PC_LIB_SQL.GetSqlCommandFieldNoName(aSqlNodeLevel, i, 0) );
      vFieldName  :=
              trim(cleanstr(nvl(PCS.PC_LIB_SQL.GetSqlCommandFieldNoName(aSqlNodeLevel, i, 1), PCS.PC_LIB_SQL.GetSqlCommandFieldNoName(aSqlNodeLevel, i, 0) ) ) );
    end loop;

    if instr(upper(aSqlNodeLevel), 'DISTINCT') > 0 then
      vPosSelect     := instr(upper(aSqlNodeLevel), 'DISTINCT') + 9;
      aSqlNodeLevel  := 'SELECT DISTINCT ' || vRuptureField || ' RUPTURE ,' || substr(aSqlNodeLevel, vPosSelect);
    else
      aSqlNodeLevel  := 'SELECT ' || vRuptureField || ' RUPTURE ,' || substr(aSqlNodeLevel, 7);
    end if;
  end FormatSqlNodeLevel;

  /**
  * Description
  *     Mise à plat d'un noeud de classification (prévu pour appel récursif)
  */
  procedure flat_node_level(
    aClassificationId in number
  , aParentNodeId     in number
  , aParentCursor     in number
  , aTreeLevel        in number
  , aSqlDisplay       in varchar2
  , aTableName        in varchar2
  , aIdField          in varchar2
  , aLangId           in number
  , aParam1           in varchar2 default null
  , aParam2           in varchar2 default null
  , aParam3           in varchar2 default null
  , aParam4           in varchar2 default null
  , aParam5           in varchar2 default null
  )
  is
    type ttblRupture is table of number(1)
      index by varchar2(1000);

    tblRupture     ttblRupture;

    cursor levelchild(parent_node_id in number)
    is
      select cln.classif_node_id
        from classif_node cln
       where cln.cln_parent_id = parent_node_id;

    tplLevelChild  levelchild%rowtype;

    cursor crNodeLevel(cClassificationId number, cLevel number)
    is
      select CLE_SQL_COMMAND_NODE
           , CLE_SQL_COMMAND_LEAF
        from CLASSIF_LEVEL
       where CLASSIFICATION_ID = cClassificationID
         and CLE_LEVEL = cLevel;

    tplNodeLevel   crNodeLevel%rowtype;
    vNodeId        number(12);
    vSqlNode       varchar2(20000);
    vSqlLeaf       varchar2(20000);
    vOldRupture    varchar2(1000);
    vDynamicCursor integer;
    vErrorCursor   integer;
    vIdField       varchar2(30);
    vFieldNo       integer;
    vDescr         CLASSIF_FLAT.NODE02%type;
    vNbField       integer;
    vMoreField     boolean;
    i              integer;
    vLangId        number(12);
    nbc            pls_integer;
  begin
    -- Attribution d'un Handle de curseur
    vDynamicCursor  := DBMS_SQL.open_cursor;

    begin
      -- préparation de la commnande sql des noeuds
      vSqlNode  := GetLevelSqlCommand(aClassificationId, aTreeLevel, 'NODE');

      if vSqlNode is not null then
        -- formattage
        vSqlNode      := PCS.PC_LIB_SQL.ResolvePcsParams(iSqlStmnt => vSqlNode);
        -- remplacement des paramètres
        i             := 1;

        while PCS.PC_LIB_SQL.GetParamName(vSqlNode, i) is not null loop
          if upper(substr(PCS.PC_LIB_SQL.GetParamName(vSqlNode, i), 1, 9) ) = ':EXTPARAM' then
            i  := i + 1;
          elsif PCS.PC_LIB_SQL.ColumnExist(aParentCursor, substr(PCS.PC_LIB_SQL.GetParamName(vSqlNode, i), 2) ) then
            vSqlNode  :=
              replace(vSqlNode
                    , PCS.PC_LIB_SQL.GetParamName(vSqlNode, i)
                    , '''' || PCS.PC_LIB_SQL.GetColumnValue(aParentCursor, substr(PCS.PC_LIB_SQL.GetParamName(vSqlNode, i), 2) ) || ''''
                     );
          else
            i  := i + 1;
          end if;
        end loop;

        FormatSqlNodeLevel(vSqlNode);
        -- Vérification de la syntaxe de la commande SQL
        DBMS_SQL.Parse(vDynamicCursor, vSqlNode, DBMS_SQL.V7);
        DefineColumns(vDynamicCursor);
        BindVariables(vDynamicCursor, aParam1, aParam2, aParam3, aParam4, aParam5);
        -- Exécution de la commande SQL
        vErrorCursor  := DBMS_SQL.execute(vDynamicCursor);
        i             := 1;

        -- Obtenir le tuple suivant
        while DBMS_SQL.fetch_rows(vDynamicCursor) > 0 loop
          -- récupération de la description
          if PCS.PC_LIB_SQL.GetColumnValue(vDynamicCursor, 'CODE') is not null then
            vDescr  := SubStr(PCS.PC_LIB_SQL.GetColumnValue(vDynamicCursor, 'CODE') || ' ' || PCS.PC_LIB_SQL.GetColumnValue(vDynamicCursor, 'DESCRIPTION'), 1, 121);
          else
            vDescr  := SubStr(PCS.PC_LIB_SQL.GetColumnValue(vDynamicCursor, 'DESCRIPTION'), 1, 121);
          end if;

          if    aLangId = PCS.PC_LIB_SQL.GetColumnValue(vDynamicCursor, 'PC_LANG_ID')
             or PCS.PC_LIB_SQL.GetColumnValue(vDynamicCursor, 'PC_LANG_ID') is null then
            for tplPC_LANG in (select PC_LANG_ID
                                 from PCS.PC_LANG
                                where (    LANUSED = 1
                                       and aLangId is null)
                                   or (PC_LANG_ID = aLangId) ) loop
              select init_id_seq.nextval
                into vNodeId
                from dual;

              -- création des positions éléments
              insert into classif_flat
                          (CLASSIF_FLAT_ID
                         , CLASSIFICATION_ID
                         , NODE01
                         , NODE02
                         , NODE03
                         , NODE04
                         , NODE05
                         , NODE06
                         , NODE07
                         , NODE08
                         , NODE09
                         , NODE10
                         , NODE11
                         , NODE12
                         , NODE13
                         , NODE14
                         , NODE15
                         , NODE16
                         , NODE17
                         , NODE18
                         , NODE19
                         , NODE20
                         , CLASSIF_LEAF_ID
                         , CFL_NODE_ID
                         , PC_LANG_ID
                          )
                select init_id_seq.nextval
                     , CLASSIFICATION_ID
                     , NODE01
                     , trim(decode(aTreeLevel, 0, vDescr, NODE02) )
                     , trim(decode(aTreeLevel, 1, vDescr, NODE03) )
                     , trim(decode(aTreeLevel, 2, vDescr, NODE04) )
                     , trim(decode(aTreeLevel, 3, vDescr, NODE05) )
                     , trim(decode(aTreeLevel, 4, vDescr, NODE06) )
                     , trim(decode(aTreeLevel, 5, vDescr, NODE07) )
                     , trim(decode(aTreeLevel, 6, vDescr, NODE08) )
                     , trim(decode(aTreeLevel, 7, vDescr, NODE09) )
                     , trim(decode(aTreeLevel, 8, vDescr, NODE10) )
                     , trim(decode(aTreeLevel, 9, vDescr, NODE11) )
                     , trim(decode(aTreeLevel, 10, vDescr, NODE12) )
                     , trim(decode(aTreeLevel, 11, vDescr, NODE13) )
                     , trim(decode(aTreeLevel, 12, vDescr, NODE14) )
                     , trim(decode(aTreeLevel, 13, vDescr, NODE15) )
                     , trim(decode(aTreeLevel, 14, vDescr, NODE16) )
                     , trim(decode(aTreeLevel, 15, vDescr, NODE17) )
                     , trim(decode(aTreeLevel, 16, vDescr, NODE18) )
                     , trim(decode(aTreeLevel, 17, vDescr, NODE19) )
                     , trim(decode(aTreeLevel, 18, vDescr, NODE20) )
                     , null
                     , vNodeId
                     , PC_LANG_ID
                  from CLASSIF_FLAT
                 where CFL_NODE_ID = aParentNodeId
                   and PC_LANG_ID = tplPC_LANG.PC_LANG_ID
                   and CLASSIF_LEAF_ID is null;

              if not tblRupture.exists(PCS.PC_LIB_SQL.GetColumnValue(vDynamicCursor, 'RUPTURE') ) then
                flat_node_level(aClassificationId
                              , vNodeId
                              , vDynamicCursor
                              , aTreeLevel + 1
                              , asqlDisplay
                              , aTableName
                              , aIdField
                              , aLangId
                              , aParam1
                              , aParam2
                              , aParam3
                              , aParam4
                              , aParam5
                               );
                tblRupture(PCS.PC_LIB_SQL.GetColumnValue(vDynamicCursor, 'RUPTURE') )  := 1;
              end if;

              i  := i + 1;
            end loop;
          end if;
        end loop;
      end if;

      -- Ferme le curseur
      DBMS_SQL.close_cursor(vDynamicCursor);
    exception
      when others then
        -- affichage de la commande sql du noeud en cas d'erreur
        raise_application_error(-20099, 'SQL statement ' || vSqlNode || chr(13) || sqlerrm);
    end;

    -- Préparation de la commande sql des éléments
    vSqlLeaf        := GetLevelSqlCommand(aClassificationId, aTreeLevel, 'LEAF');

    if vSqlLeaf is not null then
      vSqlLeaf  := PCS.PC_LIB_SQL.ResolvePcsParams(iSqlStmnt => vSqlLeaf);
      -- remplacement des paramètres
      i         := 1;

      while PCS.PC_LIB_SQL.GetParamName(vSqlLeaf, i) is not null loop
        if upper(substr(PCS.PC_LIB_SQL.GetParamName(vSqlLeaf, i), 1, 9) ) = ':EXTPARAM' then
          i  := i + 1;
        elsif PCS.PC_LIB_SQL.ColumnExist(aParentCursor, substr(PCS.PC_LIB_SQL.GetParamName(vSqlLeaf, i), 2) ) then
          vSqlLeaf  :=
            replace(vSqlLeaf
                  , PCS.PC_LIB_SQL.GetParamName(vSqlLeaf, i)
                  , '''' || PCS.PC_LIB_SQL.GetColumnValue(aParentCursor, substr(PCS.PC_LIB_SQL.GetParamName(vSqlLeaf, i), 2) ) || ''''
                   );
        else
          i  := i + 1;
        end if;
      end loop;

      -- mise à plat des éléments
      flat_leaf(aClassificationId, aParentNodeId, vSqlLeaf, aSqlDisplay, aTableName, aIdField, aLangId, aParam1, aParam2, aParam3, aParam4, aParam5);
    end if;
  end flat_node_level;

  /**
  * Description
  *     Mise à plat d'un noeud de classification (prévu pour appel récursif)
  */
  procedure flat_node(
    aClassificationId in number
  , aNodeId           in number
  , aTreeLevel        in number
  , aSqlDisplay       in varchar2
  , aTableName        in varchar2
  , aIdField          in varchar2
  , aLangId           in number
  , aParam1           in varchar2 default null
  , aParam2           in varchar2 default null
  , aParam3           in varchar2 default null
  , aParam4           in varchar2 default null
  , aParam5           in varchar2 default null
  )
  is
    cursor crlevelchild(parent_node_id in number)
    is
      select cln.classif_node_id
        from classif_node cln
       where cln.cln_parent_id = parent_node_id;

    tplLevelChild crlevelchild%rowtype;
    vDescription  varchar2(100);

    function getSqlAuto(aNodeId in number)
      return varchar2
    is
      vResult varchar2(4000);
    begin
      select CLN_SQLAUTO
        into vResult
        from CLASSIF_NODE
       where CLASSIF_NODE_ID = aNodeId;

      return vResult;
    end getSqlAuto;
  begin
    -- mise à plat des éléments du noeud
    flat_leaf(aClassificationId, aNodeId, getSqlAuto(aNodeId), aSqlDisplay, aTableName, aIdField, aLangId, aParam1, aParam2, aParam3, aParam4, aParam5);

    for tplLevelChild in crLevelChild(aNodeId) loop
      -- copie du noeud parent
      insert into classif_flat
                  (CLASSIF_FLAT_ID
                 , CLASSIFICATION_ID
                 , NODE01
                 , NODE02
                 , NODE03
                 , NODE04
                 , NODE05
                 , NODE06
                 , NODE07
                 , NODE08
                 , NODE09
                 , NODE10
                 , NODE11
                 , NODE12
                 , NODE13
                 , NODE14
                 , NODE15
                 , NODE16
                 , NODE17
                 , NODE18
                 , NODE19
                 , NODE20
                 , CLASSIF_LEAF_ID
                 , CFL_NODE_ID
                 , PC_LANG_ID
                 , LEAF_DESCR
                  )
        select init_id_seq.nextval
             , CLASSIFICATION_ID
             , NODE01
             , NODE02
             , NODE03
             , NODE04
             , NODE05
             , NODE06
             , NODE07
             , NODE08
             , NODE09
             , NODE10
             , NODE11
             , NODE12
             , NODE13
             , NODE14
             , NODE15
             , NODE16
             , NODE17
             , NODE18
             , NODE19
             , NODE20
             , CLASSIF_LEAF_ID
             , tplLevelChild.classif_node_id
             , PC_LANG_ID
             , LEAF_DESCR
          from CLASSIF_FLAT
         where CFL_NODE_ID = aNodeId
           and PC_LANG_ID = aLangId
           and CLASSIF_LEAF_ID is null;

      -- ajout de la description du noeud aux copies du noeud parent
      update classif_flat
         set (NODE02, NODE03, NODE04, NODE05, NODE06, NODE07, NODE08, NODE09, NODE10, NODE11, NODE12, NODE13, NODE14, NODE15, NODE16, NODE17, NODE18, NODE19
            , NODE20) =
               (select decode(aTreeLevel, 2, cast(trim(decode(cln_code, null, null, cln_code || ' ') || des_descr) as varchar2(121)), classif_flat.NODE02)
                     , decode(aTreeLevel, 3, cast(trim(decode(cln_code, null, null, cln_code || ' ') || des_descr) as varchar2(121)), classif_flat.NODE03)
                     , decode(aTreeLevel, 4, cast(trim(decode(cln_code, null, null, cln_code || ' ') || des_descr) as varchar2(121)), classif_flat.NODE04)
                     , decode(aTreeLevel, 5, cast(trim(decode(cln_code, null, null, cln_code || ' ') || des_descr) as varchar2(121)), classif_flat.NODE05)
                     , decode(aTreeLevel, 6, cast(trim(decode(cln_code, null, null, cln_code || ' ') || des_descr) as varchar2(121)), classif_flat.NODE06)
                     , decode(aTreeLevel, 7, cast(trim(decode(cln_code, null, null, cln_code || ' ') || des_descr) as varchar2(121)), classif_flat.NODE07)
                     , decode(aTreeLevel, 8, cast(trim(decode(cln_code, null, null, cln_code || ' ') || des_descr) as varchar2(121)), classif_flat.NODE08)
                     , decode(aTreeLevel, 9, cast(trim(decode(cln_code, null, null, cln_code || ' ') || des_descr) as varchar2(121)), classif_flat.NODE09)
                     , decode(aTreeLevel, 10, cast(trim(decode(cln_code, null, null, cln_code || ' ') || des_descr) as varchar2(121)), classif_flat.NODE10)
                     , decode(aTreeLevel, 11, cast(trim(decode(cln_code, null, null, cln_code || ' ') || des_descr) as varchar2(121)), classif_flat.NODE11)
                     , decode(aTreeLevel, 12, cast(trim(decode(cln_code, null, null, cln_code || ' ') || des_descr) as varchar2(121)), classif_flat.NODE12)
                     , decode(aTreeLevel, 13, cast(trim(decode(cln_code, null, null, cln_code || ' ') || des_descr) as varchar2(121)), classif_flat.NODE13)
                     , decode(aTreeLevel, 14, cast(trim(decode(cln_code, null, null, cln_code || ' ') || des_descr) as varchar2(121)), classif_flat.NODE14)
                     , decode(aTreeLevel, 15, cast(trim(decode(cln_code, null, null, cln_code || ' ') || des_descr) as varchar2(121)), classif_flat.NODE15)
                     , decode(aTreeLevel, 16, cast(trim(decode(cln_code, null, null, cln_code || ' ') || des_descr) as varchar2(121)), classif_flat.NODE16)
                     , decode(aTreeLevel, 17, cast(trim(decode(cln_code, null, null, cln_code || ' ') || des_descr) as varchar2(121)), classif_flat.NODE17)
                     , decode(aTreeLevel, 18, cast(trim(decode(cln_code, null, null, cln_code || ' ') || des_descr) as varchar2(121)), classif_flat.NODE18)
                     , decode(aTreeLevel, 19, cast(trim(decode(cln_code, null, null, cln_code || ' ') || des_descr) as varchar2(121)), classif_flat.NODE19)
                     , decode(aTreeLevel, 20, cast(trim(decode(cln_code, null, null, cln_code || ' ') || des_descr) as varchar2(121)), classif_flat.NODE20)
                  from classif_node_descr cld
                     , classif_node cln
                 where cln.classif_node_id = tplLevelChild.classif_node_id
                   and cld.classif_node_id = cln.classif_node_id
                   and cld.pc_lang_id = aLangId)
       where cfl_node_id = tplLevelChild.classif_node_id
         and classif_leaf_id is null
         and classif_flat.pc_lang_id = aLangId;

      -- appel récursif
      flat_node(aClassificationId
              , tplLevelChild.classif_node_id
              , aTreeLevel + 1
              , aSqlDisplay
              , aTableName
              , aIdField
              , aLangId
              , aParam1
              , aParam2
              , aParam3
              , aParam4
              , aParam5
               );
    end loop;
  end flat_node;

  /**
  * Description
  *    Mise à plat des éléments d'un noeud
  */
  procedure flat_leaf(
    aClassificationId in number
  , aNodeId           in number
  , aSqlLeaf          in varchar2
  , aSqlDisplay       in varchar2
  , aTableName        in varchar2
  , aIdField          in varchar2
  , aLangId           in number
  , aParam1           in varchar2 default null
  , aParam2           in varchar2 default null
  , aParam3           in varchar2 default null
  , aParam4           in varchar2 default null
  , aParam5           in varchar2 default null
  )
  is
    tblLeafStruct  ttblLeafStruct;
    vSqlTemp       varchar2(5000);
    vDynamicCursor integer;
    vErrorCursor   integer;
    vFieldNo       integer;
    vIdMask        number(12);
    vTempDescr     varchar2(4000);
    vDescr         CLASSIF_FLAT.LEAF_DESCR%type;
    vFullDescr     varchar2(4000);
    vNbField       integer;
    vMoreField     boolean;
    vId            number(12);
    i              pls_integer;
    j              pls_integer;
  begin
    -- test pour savoir si la commande sql du noeud est vide
    if replace(replace(replace(replace(aSqlLeaf, ' '), chr(13) ), chr(10) ), chr(9) ) is not null then
      vSqlTemp        := ltrim(replace(aSqlDisplay, '[' || 'CO].') );
      vSqlTemp        := ltrim(replace(aSqlDisplay, '[' || 'COMPANY_OWNER].') );
      vSqlTemp        := substr(vSqlTemp, 1, instr(upper(vSqlTemp), 'FROM') - 1) || substr(vSqlTemp, instr(upper(vSqlTemp), 'FROM') );
      vSqlTemp        := 'SELECT ' || aTableName || '.' || aIdField || ' ID, ' || substr(vSqlTemp, 8);

      if instr(upper(vSqlTemp), 'WHERE') > 0 then
        vSqlTemp  :=
          vSqlTemp ||
          chr(13) ||
          'AND ' ||
          aTableName ||
          '.' ||
          aIdField ||
          ' IN (' ||
          replace(replace(aSqlLeaf, co.cCompanyOwner || '.'), '[' || 'COMPANY_OWNER].') ||
          ')';
      else
        vSqlTemp  :=
          vSqlTemp ||
          chr(13) ||
          'WHERE ' ||
          aTableName ||
          '.' ||
          aIdField ||
          ' IN (' ||
          replace(replace(aSqlLeaf, co.cCompanyOwner || '.'), '[' || 'COMPANY_OWNER].') ||
          ')';
      end if;

      vSqlTemp        := PCS.PC_LIB_SQL.ResolvePcsParams(iSqlStmnt => vSqlTemp, iUserLangId => aLangId, iCompLangId => aLangId);
      -- Attribution d'un Handle de curseur
      vDynamicCursor  := DBMS_SQL.open_cursor;

      begin
        -- Vérification de la syntaxe de la commande SQL
        DBMS_SQL.Parse(vDynamicCursor, vSqltemp, DBMS_SQL.V7);
        -- Définition des colonnes dont on va stocker les valeurs
        -- Attention : Pour les Varchar, il faut préciser la taille
        DBMS_SQL.Define_column(vDynamicCursor, 1, vId);
        vNbField      := 0;
        vMoreField    := true;

        -- assignation des champs description et recherche du nombre de champs de description
        while vMoreField loop
          begin
            DBMS_SQL.Define_column(vDynamicCursor, vNbField + 2, vDescr, 150);
            vNbField  := vNbField + 1;
          exception
            when ex.VARIABLE_NOT_IN_SELECT_LIST then
              vMoreField  := false;
          end;
        end loop;

        BindVariables(vDynamicCursor, aParam1, aParam2, aParam3, aParam4, aParam5);
        -- Exécution de la commande SQL
        vErrorCursor  := DBMS_SQL.execute(vDynamicCursor);

        -- Obtenir le tuple suivant
        while DBMS_SQL.fetch_rows(vDynamicCursor) > 0 loop
          -- récupération des valeurs des colonnes
          DBMS_SQL.column_value(vDynamicCursor, 1, vId);
          vFullDescr  := '';

          for vFieldNo in 1 .. vNbField loop
            DBMS_SQL.column_value(vDynamicCursor, vFieldNo + 1, vTempDescr);
            vFullDescr  := vFullDescr || ' ' || vTempDescr;
          end loop;

          -- création des positions éléments
          insert into classif_flat
                      (CLASSIF_FLAT_ID
                     , CLASSIFICATION_ID
                     , NODE01
                     , NODE02
                     , NODE03
                     , NODE04
                     , NODE05
                     , NODE06
                     , NODE07
                     , NODE08
                     , NODE09
                     , NODE10
                     , NODE11
                     , NODE12
                     , NODE13
                     , NODE14
                     , NODE15
                     , NODE16
                     , NODE17
                     , NODE18
                     , NODE19
                     , NODE20
                     , CLASSIF_LEAF_ID
                     , CFL_NODE_ID
                     , PC_LANG_ID
                     , LEAF_DESCR
                      )
            select init_id_seq.nextval
                 , CLASSIFICATION_ID
                 , NODE01
                 , NODE02
                 , NODE03
                 , NODE04
                 , NODE05
                 , NODE06
                 , NODE07
                 , NODE08
                 , NODE09
                 , NODE10
                 , NODE11
                 , NODE12
                 , NODE13
                 , NODE14
                 , NODE15
                 , NODE16
                 , NODE17
                 , NODE18
                 , NODE19
                 , NODE20
                 , vId
                 , aNodeId
                 , PC_LANG_ID
                 , cast(trim(vFullDescr) as varchar2(150))
              from CLASSIF_FLAT
             where CFL_NODE_ID = aNodeId
               and PC_LANG_ID = aLangId
               and CLASSIF_LEAF_ID is null;
        end loop;

        -- Ferme le curseur
        DBMS_SQL.close_cursor(vDynamicCursor);
      exception
        when others then
          -- affichage de la commande sql du noeud en cas d'erreur
          raise_application_error(-20099, 'SQL statement ' || vSqltemp || chr(13) || sqlerrm);
      end;
    end if;

    null;
  end flat_leaf;

  /**
  * procedure Auto2Man
  * Description
  *   Transformation d'une classif Auto en classif Manuelle
  * @created fp 08.04.2003
  * @lastUpdate
  * @public
  * @param aClassificationId : id de la classification à transformer
  */
  procedure Auto2Man(aClassificationId in CLASSIFICATION.CLASSIFICATION_ID%type)
  is
    cursor crNodeToUpdate(cClassificationId CLASSIFICATION.CLASSIFICATION_ID%type)
    is
      select classif_node_id
           , cln_sqlauto
        from classif_node
       where classification_id = cClassificationId
         and cleanstr(cln_sqlauto) is not null;

    vSqlTemp       varchar2(5000);
    vSqlNode       varchar2(5000);
    vListId        varchar2(2000);
    vTableName     varchar2(30);
    vDynamicCursor integer;
    vErrorCursor   integer;
    vIdField       varchar2(30);
    vFieldNo       integer;
    vIdMask        number(12);
  begin
    -- recherche de la colonne ID
    select c.CTA_TABLENAME
      into vTableName
      from classif_tables c
     where c.classification_id = aClassificationId;

    vIdField  := GetPKColumnsName(PCS.PC_I_LIB_SESSION.GetCompanyOwner, vTableName);
    vSqlTemp  := 'SELECT ' || vIdField || chr(13);
    vSqlTemp  := vSqlTemp || 'FROM ' || vTableName || chr(13);
    vSqlTemp  := vSqlTemp || 'WHERE ' || vIdField || ' IN (0,LISTID0)';

    for tplNodeToUpdate in crNodeToUpdate(aClassificationId) loop
      vListId         := '';
      -- création de la commande
      vSqlNode        := tplNodeToUpdate.CLN_SQLAUTO;
      -- remplacement des paramètres prédéfinis
      vSqlNode        := replace(vSqlNode, ':PC_LANG_ID', to_char(PCS.PC_I_LIB_SESSION.GetUserLangId) );
      vSqlNode        := replace(vSqlNode, ':USER_LANGUAGE', to_char(PCS.PC_I_LIB_SESSION.GetUserLangId) );
      vSqlNode        := replace(vSqlNode, ':COMPANY_LANGUAGE', to_char(PCS.PC_I_LIB_SESSION.GetUserLangId) );
      vSqlNode        := replace(vSqlNode, ':INSTALLATION_LANGUAGE', to_char(PCS.PC_I_LIB_SESSION.GetUserLangId) );
      vSqlNode        := replace(vSqlNode, ':COMPANY_ID', to_char(PCS.PC_I_LIB_SESSION.GetCompanyId) );
      vSqlNode        := replace(vSqlNode, ':USER_ID', to_char(PCS.PC_I_LIB_SESSION.GetUserId) );
      vSqlNode        := replace(vSqlNode, co.cCompanyOwner || '.', '');
      vSqlNode        := replace(vSqlNode, '[' || 'COMPANY_OWNER].', '');
      vSqlTemp        := replace(vSqlTemp, ':OS_CLIENT_NAME', PCS.PC_I_LIB_SESSION.GetClientName);
      vSqlTemp        := replace(vSqlTemp, ':OS_HOST_NAME', PCS.PC_I_LIB_SESSION.GetHostName);
      -- Attribution d'un Handle de curseur
      vDynamicCursor  := DBMS_SQL.open_cursor;

      begin
        -- Vérification de la syntaxe de la commande SQL
        DBMS_SQL.Parse(vDynamicCursor, vSqlNode, DBMS_SQL.V7);
        -- Définition des colonnes dont on va stocker les valeurs
        -- Attention : Pour les Varchar, il faut préciser la taille
        DBMS_SQL.Define_column(vDynamicCursor, 1, vIdMask);
        -- Exécution de la commande SQL
        vErrorCursor  := DBMS_SQL.execute(vDynamicCursor);

        -- Obtenir le tuple suivant
        while DBMS_SQL.fetch_rows(vDynamicCursor) > 0 loop
          -- récupération des valeurs des colonnes
          DBMS_SQL.column_value(vDynamicCursor, 1, vIdMask);
          -- création liste des id
          vListId  := vListId || to_char(vIdMask) || ',';
        end loop;

        -- Ferme le curseur
        DBMS_SQL.close_cursor(vDynamicCursor);
      exception
        when others then
          -- affichage de la commande sql du noeud en cas d'erreur
          raise_application_error(-20098, 'SQL statement ' || vSqlNode || chr(13) || sqlerrm);
      end;

      -- Commande SQL du noeud
      update CLASSIF_NODE
         set CLN_SQLAUTO = replace(vSqlTemp, 'LISTID', vListId)
       where CLASSIF_NODE_ID = tplNodeToUpdate.CLASSIF_NODE_ID;
    end loop;
  end Auto2Man;

end CLA_FUNCTIONS;
