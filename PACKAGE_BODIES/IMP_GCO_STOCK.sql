--------------------------------------------------------
--  DDL for Package Body IMP_GCO_STOCK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IMP_GCO_STOCK" 
as
  lcDomain constant varchar2(15) := 'GCO_STOCK';

  /**
   * Description
   *    Importation des données d'Excel dans la table temporaire IMP_GCO_STOCK_. Cette procédure est appelée depuis Excel
   */
  procedure IMP_TMP_GCO_STOCK(
    pGOO_MAJOR_REFERENCE              varchar2
  , pSTO_DESCRIPTION                  varchar2
  , pLOC_DESCRIPTION                  varchar2
  , pCST_QUANTITY_OBTAINING_STOCK     varchar2
  , pCST_QUANTITY_MIN                 varchar2
  , pCST_QUANTITY_MAX                 varchar2
  , pCST_TRIGGER_POINT                varchar2
  , pCST_PERIOD_VALUE                 varchar2
  , pCST_NUMBER_PERIOD                varchar2
  , pCST_OBTAINING_MULTIPLE           varchar2
  , pFREE1                            varchar2
  , pFREE2                            varchar2
  , pFREE3                            varchar2
  , pFREE4                            varchar2
  , pFREE5                            varchar2
  , pFREE6                            varchar2
  , pFREE7                            varchar2
  , pFREE8                            varchar2
  , pFREE9                            varchar2
  , pFREE10                           varchar2
  , pEXCEL_LINE                       integer
  , pRESULT                       out integer
  )
  is
  begin
    --Insertion dans la table IMP_GCO_STOCK_
    insert into IMP_GCO_STOCK_
                (id
               , EXCEL_LINE
               , GOO_MAJOR_REFERENCE
               , STO_DESCRIPTION
               , LOC_DESCRIPTION
               , CST_QUANTITY_OBTAINING_STOCK
               , CST_QUANTITY_MIN
               , CST_QUANTITY_MAX
               , CST_TRIGGER_POINT
               , CST_PERIOD_VALUE
               , CST_NUMBER_PERIOD
               , CST_OBTAINING_MULTIPLE
               , FREE1
               , FREE2
               , FREE3
               , FREE4
               , FREE5
               , FREE6
               , FREE7
               , FREE8
               , FREE9
               , FREE10
               , A_DATECRE
               , A_IDCRE
                )
         values (GetNewId
               , pEXCEL_LINE
               , trim(pGOO_MAJOR_REFERENCE)
               , trim(pSTO_DESCRIPTION)
               , trim(pLOC_DESCRIPTION)
               , trim(pCST_QUANTITY_OBTAINING_STOCK)
               , trim(pCST_QUANTITY_MIN)
               , trim(pCST_QUANTITY_MAX)
               , trim(pCST_TRIGGER_POINT)
               , trim(pCST_PERIOD_VALUE)
               , trim(pCST_NUMBER_PERIOD)
               , trim(pCST_OBTAINING_MULTIPLE)
               , trim(pFREE1)
               , trim(pFREE2)
               , trim(pFREE3)
               , trim(pFREE4)
               , trim(pFREE5)
               , trim(pFREE6)
               , trim(pFREE7)
               , trim(pFREE8)
               , trim(pFREE9)
               , trim(pFREE10)
               , sysdate
               , IMP_LIB_TOOLS.getImportUserIni
                );

    --Nombre de ligne insérées
    pResult  := 1;
    commit;
  end IMP_TMP_GCO_STOCK;

  /**
  * Description
  *    Contrôle des données de la table IMP_GCO_STOCK_ avant importation.
  */
  procedure IMP_GCO_STOCK_CTRL
  is
    tmp_int     integer;
    lvTableName varchar2(30) := 'GCO_COMPL_DATA_STOCK';
  begin
    --Effacement des tables d'erreurs
    IMP_PRC_TOOLS.deleteErrors(lcDomain);

    --Y'a-t-il deux fois le même stock logique pour le même produit ?
    select   max(count(sto_description) )
        into tmp_int
        from IMP_GCO_STOCK_
    group by GOO_MAJOR_REFERENCE
           , STO_DESCRIPTION;

    if (tmp_int > 1) then
      IMP_PRC_TOOLS.insertError(lcDomain, 0, '-', pcs.pc_functions.TranslateWord('IMP_REQUIRED') );
    end if;

    --Parcours de toutes les lignes de la table IMP_GCO_STOCK_
    for tdata in (select *
                    from IMP_GCO_STOCK_) loop
      --> Est-ce que tous les champs obligatoires sont présents ?
      if (   tdata.GOO_MAJOR_REFERENCE is null
          or tdata.STO_DESCRIPTION is null) then
        IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_REQUIRED') );
      else
        --> Est-ce que la référence principale existe ?
        IMP_PRC_TOOLS.checkGoodExists(tdata.GOO_MAJOR_REFERENCE, lcDomain, tdata.id, tdata.EXCEL_LINE);

        --> Est-ce qu'une donnée complémentaire existe déjà ?
        --Recherche d'une donnée complémentaire pour le même tiers et le même produit
        select count(*)
          into tmp_int
          from dual
         where exists(
                 select GCO_COMPL_DATA_STOCK_ID
                   from GCO_COMPL_DATA_STOCK
                  where STM_STOCK_ID = FWK_I_LIB_ENTITY.getIdfromPk2('STM_STOCK', 'STO_DESCRIPTION', tdata.STO_DESCRIPTION)
                    and GCO_GOOD_ID = FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', tdata.GOO_MAJOR_REFERENCE) );

        if tmp_int > 0 then
          --Si on en trouve une, c'est qu'il y a un doublon
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_GCO_DATA_COMPL_4') );
        end if;

        --> Est-ce que le stock logique et l'emplacement (si renseigné) existent et sont cohérents  ?
        IMP_PRC_TOOLS.checkStockAndLocataion(tdata.STO_DESCRIPTION, tdata.LOC_DESCRIPTION, lcDomain, tdata.id, tdata.EXCEL_LINE, false);

        --> Est-ce que la quantité stock d'obtention est cohérente ?
        if (tdata.CST_QUANTITY_OBTAINING_STOCK is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CST_QUANTITY_OBTAINING_STOCK', tdata.CST_QUANTITY_OBTAINING_STOCK, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

        --> Est-ce que la quantité stock min est cohérente ?
        if (tdata.CST_QUANTITY_MIN is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CST_QUANTITY_MIN', tdata.CST_QUANTITY_MIN, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

        --> Est-ce que la quantité stock max est cohérente ?
        if (tdata.CST_QUANTITY_MAX is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CST_QUANTITY_MAX', tdata.CST_QUANTITY_MAX, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

        --> Est-ce que la quantité du point de commande est cohérente ?
        if (tdata.CST_TRIGGER_POINT is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CST_TRIGGER_POINT', tdata.CST_TRIGGER_POINT, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

        --> Est-ce que la valeur de la période est cohérente ?
        if (tdata.CST_PERIOD_VALUE is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CST_PERIOD_VALUE', tdata.CST_PERIOD_VALUE, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

        --> Est-ce que le nombre de période est cohérent ?
        if (tdata.CST_NUMBER_PERIOD is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CST_NUMBER_PERIOD', tdata.CST_NUMBER_PERIOD, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

        --> Est-ce que le multiple du stock d'obtention est cohérent ?
        if (tdata.CST_OBTAINING_MULTIPLE is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CST_OBTAINING_MULTIPLE', tdata.CST_OBTAINING_MULTIPLE, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;
      end if;
    end loop;

    --Si la table d'erreurs est vide, alors on insère le message repris par le pilotage de contrôle disant qu'il n'y a pas d'erreur
    IMP_PRC_TOOLS.checkErrors(lcDomain);
    commit;
  end IMP_GCO_STOCK_CTRL;

  /**
  * Description
  *    Importation des données complémentaires de stock
  */
  procedure IMP_GCO_STOCK_IMPORT
  is
    lGoodID GCO_GOOD.GCO_GOOD_ID%type;
    ltGood  FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    --Contrôle que la table d'erreurs soit vide
    IMP_PRC_TOOLS.checkErrorsBeforeImport(lcDomain);

    --Parcours de toutes les lignes à insérer
    for tdata in (select *
                    from IMP_GCO_STOCK_) loop
      -- Récupération ID du bien
      lGoodID  := FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', tdata.GOO_MAJOR_REFERENCE);

      --Insertion des données dans les tables !
      insert into GCO_COMPL_DATA_STOCK
                  (GCO_COMPL_DATA_STOCK_ID
                 , GCO_GOOD_ID
                 , A_DATECRE
                 , A_IDCRE
                 , DIC_UNIT_OF_MEASURE_ID
                 , CDA_NUMBER_OF_DECIMAL
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , CST_QUANTITY_OBTAINING_STOCK
                 , CST_QUANTITY_MIN
                 , CST_QUANTITY_MAX
                 , CST_TRIGGER_POINT
                 , CST_PERIOD_VALUE
                 , CST_NUMBER_PERIOD
                 , CST_OBTAINING_MULTIPLE
                  )
           values (GetNewId
                 , FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', tdata.GOO_MAJOR_REFERENCE)
                 , sysdate
                 , IMP_LIB_TOOLS.getImportUserIni
                 , FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('GCO_GOOD', 'DIC_UNIT_OF_MEASURE_ID', lGoodID)
                 , FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('GCO_GOOD', 'GOO_NUMBER_OF_DECIMAL', lGoodID)
                 , FWK_I_LIB_ENTITY.getIdfromPk2('STM_STOCK', 'STO_DESCRIPTION', tdata.STO_DESCRIPTION)
                 , IMP_LIB_TOOLS.getLocationId(tdata.STO_DESCRIPTION, tdata.LOC_DESCRIPTION)
                 , tdata.CST_QUANTITY_OBTAINING_STOCK
                 , tdata.CST_QUANTITY_MIN
                 , tdata.CST_QUANTITY_MAX
                 , tdata.CST_TRIGGER_POINT
                 , tdata.CST_PERIOD_VALUE
                 , tdata.CST_NUMBER_PERIOD
                 , tdata.CST_OBTAINING_MULTIPLE
                  );

      -- màj du flag sur le bien
      -- Création de l'entité GCO_GOOD
      FWK_I_MGT_ENTITY.new(FWK_TYP_GCO_ENTITY.gcGcoGood, ltGood);
      -- Init de l'id du bien
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGood, 'GCO_GOOD_ID', lGoodID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGood, 'GCO_DATA_STOCK', 1);
      FWK_I_MGT_ENTITY.UpdateEntity(ltGood);
      FWK_I_MGT_ENTITY.Release(ltGood);

      --Insertion des données dans les tables !
      insert into IMP_HIST_GCO_STOCK
                  (ID_HIST
                 , DATE_HIST
                 , EXCEL_LINE
                 , GOO_MAJOR_REFERENCE
                 , STO_DESCRIPTION
                 , LOC_DESCRIPTION
                 , CST_QUANTITY_OBTAINING_STOCK
                 , CST_QUANTITY_MIN
                 , CST_QUANTITY_MAX
                 , CST_TRIGGER_POINT
                 , CST_PERIOD_VALUE
                 , CST_NUMBER_PERIOD
                 , CST_OBTAINING_MULTIPLE
                 , FREE1
                 , FREE2
                 , FREE3
                 , FREE4
                 , FREE5
                 , FREE6
                 , FREE7
                 , FREE8
                 , FREE9
                 , FREE10
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , sysdate
                 , tdata.EXCEL_LINE
                 , tdata.GOO_MAJOR_REFERENCE
                 , tdata.STO_DESCRIPTION
                 , tdata.LOC_DESCRIPTION
                 , tdata.CST_QUANTITY_OBTAINING_STOCK
                 , tdata.CST_QUANTITY_MIN
                 , tdata.CST_QUANTITY_MAX
                 , tdata.CST_TRIGGER_POINT
                 , tdata.CST_PERIOD_VALUE
                 , tdata.CST_NUMBER_PERIOD
                 , tdata.CST_OBTAINING_MULTIPLE
                 , tdata.FREE1
                 , tdata.FREE2
                 , tdata.FREE3
                 , tdata.FREE4
                 , tdata.FREE5
                 , tdata.FREE6
                 , tdata.FREE7
                 , tdata.FREE8
                 , tdata.FREE9
                 , tdata.FREE10
                 , sysdate
                 , pcs.PC_I_LIB_SESSION.GetUserIni
                  );
    end loop;
  end IMP_GCO_STOCK_IMPORT;
end IMP_GCO_STOCK;
