--------------------------------------------------------
--  DDL for Package Body ACI_PRC_BLEED
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_PRC_BLEED" 
is
  type tConstraint is record(
    CONSTRAINT_NAME varchar2(30)
  , TABLE_NAME      varchar2(30)
  );

  type ttConstraintList is table of tConstraint
    index by binary_integer;

  type ttTriggerList is table of varchar2(30)
    index by binary_integer;

  gConstraintList ttConstraintList;
  gTriggerList    ttTriggerList;
  gPrefixe        varchar2(7);

  /**
  * Description
  *   Création de tables contenant les données à garder
  */
  procedure CreateTmpTables(iRefDate in date, iDocType in varchar2 default 'ISAG')
  is
    lSql varchar2(2000)
      := 'create table "' ||
         gPrefixe ||
         'ACI_DOCUMENT" as select * from ACI_DOCUMENT where A_DATECRE >= TO_DATE(''' ||
         to_char(iRefDate, 'DD.MM.YYYY') ||
         ''',''DD.MM.YYYY'')' ||
         'or C_INTERFACE_CONTROL <> ''1''';
  begin
    lSql  :=
      lSql ||
      ' OR EXISTS(select ACI_DOCUMENT_ID
                                       from FAL_ELT_COST_DIFF_DET
                                      where ACI_DOCUMENT_ID = ACI_DOCUMENT.ACI_DOCUMENT_ID)';
    lSql  :=
      lSql ||
      ' OR EXISTS(select ACI_DOCUMENT_ID
                                       from FAL_ELT_COST_DIFF_DET_HIST
                                      where ACI_DOCUMENT_ID = ACI_DOCUMENT.ACI_DOCUMENT_ID)';

    -- si on ne purge qu'un type de documents, il y a une clause pour prendre tous les autres
    if iDocType = 'ISAG' then
      lSql  :=
        lSql ||
        ' OR not EXISTS(select ACI_CONVERSION_ID
                                       from ACI_CONVERSION
                                      where ACI_CONVERSION_ID = ACI_DOCUMENT.ACI_CONVERSION_ID and CNV_ISAG_JOB_NUMBER is not null)';
    end if;

    -- on sauvegarde déjà ACI_DOCUMENT, table maître de part les contraintes d'intégrité
    execute immediate lSql;

    execute immediate 'create unique index PK_' || gPrefixe || 'ACI_DOCUMENT ON "' || gPrefixe || 'ACI_DOCUMENT"(ACI_DOCUMENT_ID)';

    -- pour chaque table en lien avec ACI_DOCUMENT, on reprend les données
    for ltplTable in (select column_value TABLE_NAME
                        from table(charListToTable(gcTableListDocLinked) ) ) loop
      lSql  :=
        'create table "' ||
        gPrefixe ||
        ltplTable.TABLE_NAME ||
        '" as select MAIN.* from ' ||
        ltplTable.TABLE_NAME ||
        ' MAIN, "' ||
        gPrefixe ||
        'ACI_DOCUMENT" DOC where MAIN.ACI_DOCUMENT_ID = DOC.ACI_DOCUMENT_ID';

      execute immediate lSql;

      -- si la table reprise est ACI_PART_IMPUTATION, on crée un index PK sur la table de sauvegarde
      -- afin d'accélérer la suite du traitement
      if ltplTable.TABLE_NAME = 'ACI_PART_IMPUTATION' then
        lSql  :=
          'create unique index PK_' || ltplTable.TABLE_NAME || '_' || gPrefixe || ' ON "' || gPrefixe || ltplTable.TABLE_NAME || '"(' || ltplTable.TABLE_NAME
          || '_ID)';

        execute immediate lSql;

        -- pour chaque table en lien avec ACI_PART_IMPUTATION, on reprend les données
        for ltplTable in (select column_value TABLE_NAME
                            from table(charListToTable(gcTableListPartLinked) ) ) loop
          lSql  :=
            'create table "' ||
            gPrefixe ||
            ltplTable.TABLE_NAME ||
            '" as select MAIN.* from ' ||
            ltplTable.TABLE_NAME ||
            ' MAIN, "' ||
            gPrefixe ||
            'ACI_PART_IMPUTATION" PAR where MAIN.ACI_PART_IMPUTATION_ID = PAR.ACI_PART_IMPUTATION_ID';

          execute immediate lSql;
        end loop;
      end if;
    end loop;
  end CreateTmpTables;

  /**
  * procedure pPurgeTables
  * Description
  *   Supression des données et libération de la mémoire disque pour les tables ACI
  * @created fp 30.05.2013
  * @lastUpdate
  * @private
  */
  procedure pPurgeTables
  is
    procedure TruncateTable(iTableName in varchar2)
    is
    begin
      execute immediate 'TRUNCATE TABLE ' || iTableName || ' DROP STORAGE';
    end TruncateTable;
  begin
    TruncateTable('ACI_DOCUMENT');

    for ltplTable in (select column_value TABLE_NAME
                        from table(charListToTable(gcTableListDocLinked) ) ) loop
      TruncateTable(ltplTable.TABLE_NAME);
    end loop;

    for ltplTable in (select column_value TABLE_NAME
                        from table(charListToTable(gcTableListPartLinked) ) ) loop
      TruncateTable(ltplTable.TABLE_NAME);
    end loop;
  end pPurgeTables;

  /**
  * procedure pRecoverSavedData
  * Description
  *   Réinjecte les données mise de côté dans la table que lon vient de trunquer
  * @created fp 30.05.2013
  * @lastUpdate
  * @private
  */
  procedure pRecoverSavedData
  is
    procedure ReinjectData(iTableName in varchar2)
    is
    begin
      execute immediate 'INSERT INTO ' || iTableName || ' SELECT * FROM "' || gPrefixe || iTableName || '"';
    end ReinjectData;
  begin
    ReinjectData('ACI_DOCUMENT');

    for ltplTable in (select column_value TABLE_NAME
                        from table(charListToTable(gcTableListDocLinked) ) ) loop
      ReinjectData(ltplTable.TABLE_NAME);
    end loop;

    for ltplTable in (select column_value TABLE_NAME
                        from table(charListToTable(gcTableListPartLinked) ) ) loop
      ReinjectData(ltplTable.TABLE_NAME);
    end loop;
  end pRecoverSavedData;

  /**
  * procedure pAddContraintInList
  * Description
  *
  * @created fp 31.05.2013
  * @lastUpdate
  * @public
  * @param
  */
  procedure pAddConstraintInList(iConstraintName in varchar2, iTableName in varchar2)
  is
    lIndex binary_integer := gConstraintList.count + 1;
  begin
    gConstraintList(lIndex).CONSTRAINT_NAME  := iConstraintName;
    gConstraintList(lIndex).TABLE_NAME       := iTableName;
  end pAddConstraintInList;

  /**
  * procedure pDisableConstraint
  * Description
  *    Change l'état ENABLE/DISABLE des contraintes référençant une table
  * @created fp 30.05.2013
  * @lastUpdate
  * @public
  * @param iv_entity_name  Nom de l'entité/table.
  */
  procedure pDisableConstraint(iv_entity_name in fwk_i_typ_definition.ENTITY_NAME)
  is
    lPkName varchar2(30);
  begin
    select CONSTRAINT_NAME
      into lPkName
      from USER_CONSTRAINTS
     where TABLE_NAME = iv_entity_name
       and CONSTRAINT_TYPE = 'P';

    for ltplConstraint in (select TABLE_NAME
                                , CONSTRAINT_NAME
                             from USER_CONSTRAINTS
                            where R_CONSTRAINT_NAME = lPkName) loop
      execute immediate 'ALTER TABLE ' || ltplConstraint.TABLE_NAME || ' MODIFY CONSTRAINT ' || ltplConstraint.CONSTRAINT_NAME || ' DISABLE';

      pAddConstraintInList(ltplConstraint.CONSTRAINT_NAME, ltplConstraint.TABLE_NAME);
    end loop;
  end pDisableConstraint;

  /**
  * procedure pAddContraintInList
  * Description
  *
  * @created fp 31.05.2013
  * @lastUpdate
  * @public
  * @param
  */
  procedure pAddTriggerInList(iTriggerName in varchar2)
  is
    lIndex binary_integer := gTriggerList.count + 1;
  begin
    gTriggerList(lIndex)  := iTriggerName;
  end pAddTriggerInList;

  /**
  * procedure pDisableTrigger
  * Description
  *    DISABLE les triggers d'une table
  * @created fp 30.05.2013
  * @lastUpdate
  * @public
  * @param iv_entity_name  Nom de l'entité/table.
  */
  procedure pDisableTrigger(iv_entity_name in fwk_i_typ_definition.ENTITY_NAME)
  is
  begin
    for ltplTrigger in (select TRIGGER_NAME
                             from USER_TRIGGERS
                            where TABLE_NAME = iv_entity_name) loop
      execute immediate 'ALTER TRIGGER ' || ltplTrigger.TRIGGER_NAME || ' DISABLE';

      pAddTriggerInList(ltplTrigger.TRIGGER_NAME);
    end loop;
  end pDisableTrigger;

  /**
  * procedure pDisableTableRefCons
  * Description
  *   Disable les contraintes pointant sur les tables à purger
  * @created fp 30.05.2013
  * @lastUpdate
  * @private
  */
  procedure pDisableTableTrgAndRefCons
  is
  begin
    pDisableConstraint('ACI_DOCUMENT');
    pDisableTrigger('ACI_DOCUMENT');

    for ltplTable in (select column_value TABLE_NAME
                        from table(charListToTable(gcTableListDocLinked) ) ) loop
      pDisableConstraint(ltplTable.TABLE_NAME);
      pDisableTrigger(ltplTable.TABLE_NAME);
    end loop;

    for ltplTable in (select column_value TABLE_NAME
                        from table(charListToTable(gcTableListPartLinked) ) ) loop
      pDisableConstraint(ltplTable.TABLE_NAME);
      pDisableTrigger(ltplTable.TABLE_NAME);
    end loop;
  end pDisableTableTrgAndRefCons;

  /**
  * procedure pEnableTableRefCons
  * Description
  *   Enable les contraintes pointant sur les tables à purger
  * @created fp 30.05.2013
  * @lastUpdate
  * @private
  */
  procedure pEnableTableTrigAndRefCons
  is
    lConstraintList ttConstraintList;
    lTriggerList    ttTriggerList;
  begin
    if gConstraintList.count > 0 then
      for i in gConstraintList.first .. gConstraintList.last loop
        execute immediate 'ALTER TABLE ' || gConstraintList(i).TABLE_NAME || ' MODIFY CONSTRAINT ' || gConstraintList(i).CONSTRAINT_NAME || ' ENABLE NOVALIDATE';
      end loop;

      gConstraintList  := lConstraintList;
    end if;

    if gTriggerList.count > 0 then
      for i in gTriggerList.first .. gTriggerList.last loop
        execute immediate 'ALTER TRIGGER ' || gTriggerList(i) || ' ENABLE';
      end loop;

      gTriggerList  := lTriggerList;
    end if;
  end pEnableTableTrigAndRefCons;

  /**
  * Description
  *   Cette procedure va créer des tables temporaires pour chaque table ACI
  *   et y sauvegarder les données à ne pas supprimer
  *   Ensuite on va vider les tables ACI et les "trunquer" afin de récupérer
  *   l'espace disque.
  *   On va enfin remettre les données sauvegardées dans les tables d'origine
  */
  procedure PurgeAndTruncate(iRefDate in date, iDocType in varchar2 default 'ISAG')
  is
  begin
    --CreateTmpTables(iRefDate, 'ISAG');
    pDisableTableTrgAndRefCons;
    pPurgeTables;
    pRecoverSavedData;
    pEnableTableTrigAndRefCons;
  end PurgeAndTruncate;

  /**
  * Description
  *   Cette procedure permet de créer des tables de sauvegarde pour la totalité du contenu des tables ACI
  *   Ces tables seront préfixées SAVE_ACI*
  */
  procedure CreateSaveTables
  is
  begin
    gPrefixe  := 'SAVE_';
    CreateTmpTables(sysdate-365*100);
    gPrefixe  := to_char(sysdate, 'YYMMDD');
  end CreateSaveTables;

begin
  gPrefixe  := to_char(sysdate, 'YYMMDD');
end ACI_PRC_BLEED;
