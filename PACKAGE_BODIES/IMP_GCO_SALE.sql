--------------------------------------------------------
--  DDL for Package Body IMP_GCO_SALE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IMP_GCO_SALE" 
as
  lcDomain constant varchar2(15) := 'GCO_SALE';

  /**
   * Description
   *    Importation des données d'Excel dans la table temporaire IMP_GCO_SALE_. Cette procédure est appelée depuis Excel
   */
  procedure IMP_TMP_GCO_SALE(
    pGOO_MAJOR_REFERENCE             varchar2
  , pPER_KEY2                        varchar2
  , pSTO_DESCRIPTION                 varchar2
  , pLOC_DESCRIPTION                 varchar2
  , pDIC_UNIT_OF_MEASURE_ID          varchar2
  , pCDA_NUMBER_OF_DECIMAL           varchar2
  , pCDA_CONVERSION_FACTOR           varchar2
  , pCSA_TH_SUPPLY_DELAY             varchar2
  , pCSA_DISPATCHING_DELAY           varchar2
  , pCSA_DELIVERY_DELAY              varchar2
  , pCSA_QTY_CONDTIONING             varchar2
  , pCSA_SCALE_LINK                  varchar2
  , pCSA_LAPSING_MARGE               varchar2
  , pCDA_COMPLEMENTARY_REFERENCE     varchar2
  , pFREE1                           varchar2
  , pFREE2                           varchar2
  , pFREE3                           varchar2
  , pFREE4                           varchar2
  , pFREE5                           varchar2
  , pFREE6                           varchar2
  , pFREE7                           varchar2
  , pFREE8                           varchar2
  , pFREE9                           varchar2
  , pFREE10                          varchar2
  , pEXCEL_LINE                      integer
  , pRESULT                      out integer
  )
  is
  begin
    --Insertion dans la table IMP_GCO_SALE_
    insert into IMP_GCO_SALE_
                (id
               , excel_line
               , GOO_MAJOR_REFERENCE
               , PER_KEY2
               , STO_DESCRIPTION
               , LOC_DESCRIPTION
               , DIC_UNIT_OF_MEASURE_ID
               , CDA_NUMBER_OF_DECIMAL
               , CDA_CONVERSION_FACTOR
               , CSA_TH_SUPPLY_DELAY
               , CSA_DISPATCHING_DELAY
               , CSA_DELIVERY_DELAY
               , CSA_QTY_CONDITIONING
               , CSA_SCALE_LINK
               , CSA_LAPSING_MARGE
               , CDA_COMPLEMENTARY_REFERENCE
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
               , trim(pPER_KEY2)
               , trim(pSTO_DESCRIPTION)
               , trim(pLOC_DESCRIPTION)
               , trim(pDIC_UNIT_OF_MEASURE_ID)
               , trim(pCDA_NUMBER_OF_DECIMAL)
               , trim(pCDA_CONVERSION_FACTOR)
               , trim(pCSA_TH_SUPPLY_DELAY)
               , trim(pCSA_DISPATCHING_DELAY)
               , trim(pCSA_DELIVERY_DELAY)
               , trim(pCSA_QTY_CONDTIONING)
               , trim(pCSA_SCALE_LINK)
               , trim(pCSA_LAPSING_MARGE)
               , trim(pCDA_COMPLEMENTARY_REFERENCE)
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
  end IMP_TMP_GCO_SALE;

  /**
  * Description
  *    Contrôle des données de la table IMP_GCO_SALE_ avant importation.
  */
  procedure IMP_GCO_SALE_CTRL
  is
    tmp         varchar2(200);
    tmp_int     integer;
    lvTableName varchar2(30)  := 'GCO_COMPL_DATA_SALE';
  begin
    --Effacement des tables d'erreurs
    IMP_PRC_TOOLS.deleteErrors(lcDomain);

--************************************************************************
--Est-ce qu'il y a un ou des clients pour la donnée complémentaire ?
--Est-ce que ce/ces client(s) existe(nt) ?
--Est-ce qu'il y a un client par défaut au minimum et au maximum
--Est-ce qu'il y a deux fois le même client pour un produit ?
--************************************************************************
--Parcours de tous les biens qui ont des clients associés
    for tProduct in (select distinct GOO_MAJOR_REFERENCE
                                from IMP_GCO_SALE_
                               where PER_KEY2 is not null) loop
      --Pour chaque bien on parcours tous les clients et on vérifie leur existance
      for tCustomer in (select PER_KEY2
                             , EXCEL_LINE
                             , id
                          from IMP_GCO_SALE_
                         where GOO_MAJOR_REFERENCE = tProduct.GOO_MAJOR_REFERENCE
                           and PER_KEY2 is not null) loop
        -- Vérification de l'existance du client
        select count(*)
          into tmp_int
          from dual
         where exists(select PAC_PERSON_ID
                        from PAC_PERSON
                           , PAC_CUSTOM_PARTNER
                       where PAC_PERSON_ID = PAC_CUSTOM_PARTNER_ID
                         and PER_KEY2 = tCustomer.PER_KEY2);

        --Si inexistant, insertion d'une erreur.
        if (tmp_int = 0) then
          IMP_PRC_TOOLS.insertError(lcDomain
                                  , tCustomer.id
                                  , tCustomer.EXCEL_LINE
                                  , pcs.PC_FUNCTIONS.TranslateWord('IMP_CUSTOMER') ||
                                    ' ' ||
                                    tCustomer.PER_KEY2 ||
                                    ' ' ||
                                    pcs.PC_FUNCTIONS.TranslateWord('IMP_INEXISTANT')
                                   );
        end if;
      end loop;

      --Vérifie qu'il n'y a pas deux fois le même client pour le même bien
      select   max(count(PER_KEY2) )
          into tmp_int
          from IMP_GCO_SALE_
         where GOO_MAJOR_REFERENCE = tProduct.GOO_MAJOR_REFERENCE
      group by PER_KEY2;

      --Si c'est le cas
      if (tmp_int > 1) then
        IMP_PRC_TOOLS.insertError(lcDomain
                                , 0
                                , '-'
                                , pcs.pc_functions.TranslateWord('IMP_GCO_DATA_COMPL_3') ||
                                  tproduct.goo_major_reference ||
                                  pcs.pc_functions.TranslateWord('IMP_GCO_DATA_COMPL_CLIENT')
                                 );
      end if;
    end loop;

    --Parcours de tous les biens qui n'ont pas de clients associés à leur données compl
    for tproduct_ws in (select distinct goo_major_reference
                                   from IMP_GCO_SALE_
                                  where per_key2 is null) loop
      --Est-ce qu'il y a plusieurs données compl pour le même produit sans client ?
      select   count(goo_major_reference)
          into tmp_int
          from imp_gco_SALE_
         where goo_major_reference = tproduct_ws.goo_major_reference
           and per_key2 is null
      group by goo_major_reference;

      --Si c'est le cas
      if (tmp_int > 1) then
        IMP_PRC_TOOLS.insertError(lcDomain
                                , 0
                                , '-'
                                , pcs.pc_functions.TranslateWord('IMP_GCO_DATA_COMPL_3') ||
                                  tproduct_ws.goo_major_reference ||
                                  pcs.pc_functions.TranslateWord('IMP_GCO_DATA_COMPL_CLIENT_2')
                                 );
      end if;
    end loop;

    --Parcours de toutes les lignes de la table IMP_GCO_SALE_
    for tdata in (select *
                    from IMP_GCO_SALE_) loop
      /*******************************************************
      * --> Est-ce que tous les champs obligatoires sont présents ?
      *******************************************************/
      if (   tdata.GOO_MAJOR_REFERENCE is null
          or tdata.DIC_UNIT_OF_MEASURE_ID is null
          or tdata.CDA_NUMBER_OF_DECIMAL is null
          or tdata.CDA_CONVERSION_FACTOR is null
         ) then
        IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_REQUIRED') );
      else
--*******************************************************
--Est-ce que la référence principale existe ?
--*******************************************************
        IMP_PRC_TOOLS.checkGoodExists(tdata.GOO_MAJOR_REFERENCE, lcDomain, tdata.id, tdata.EXCEL_LINE);

--********************************************************************************
--Est-ce qu'une donnée complémentaire existe déjà pour ce bien et ce client ?
--********************************************************************************
        if (tdata.PER_KEY2 is not null) then
          begin
            --Recherche d'une donnée complémentaire pour le même tiers et le même produit
            select GCO_COMPL_DATA_SALE_ID
              into tmp_int
              from GCO_COMPL_DATA_SALE
             where PAC_CUSTOM_PARTNER_ID = FWK_I_LIB_ENTITY.getIdfromPk2('PAC_PERSON', 'PER_KEY2', tdata.PER_KEY2)
               and GCO_GOOD_ID = FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', tdata.GOO_MAJOR_REFERENCE);

            --Si on en trouve une, c'est qu'il y a un doublon
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_GCO_DATA_COMPL') );
          exception
            when no_data_found then
              null;
          end;
        end if;

        if (tdata.per_key2 is null) then
          begin
            --Recherche d'une donnée complémentaire sans tiers et le même produit
            select gco_compl_data_SALE_id
              into tmp_int
              from gco_compl_data_SALE
             where pac_custom_partner_id is null
               and gco_good_id = FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', tdata.GOO_MAJOR_REFERENCE);

            --Si on en trouve une, c'est qu'il y a un doublon
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_GCO_DATA_COMPL_2') );
          exception
            when no_data_found then
              null;
          end;
        end if;

        /********************************************************
        * --> Est-ce que le stock logique et l'emplacement existent et sont cohérents  ?
        ********************************************************/
        if    (tdata.STO_DESCRIPTION is not null)
           or (tdata.LOC_DESCRIPTION is not null) then
          IMP_PRC_TOOLS.checkStockAndLocataion(tdata.STO_DESCRIPTION, tdata.LOC_DESCRIPTION, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
--Est-ce que le dictionnaire des unités de mesure existe ?
--*******************************************************
        IMP_PRC_TOOLS.checkDicoValue('DIC_UNIT_OF_MEASURE', tdata.DIC_UNIT_OF_MEASURE_ID, lcDomain, tdata.id, tdata.EXCEL_LINE);
--*******************************************************
--Est-ce que le nombre de décimales est correct?
--*******************************************************
        IMP_PRC_TOOLS.checkDescodeValue('CDA_NUMBER_OF_DECIMAL', tdata.CDA_NUMBER_OF_DECIMAL, '{0,1,2,3,4}', lcDomain, tdata.id, tdata.EXCEL_LINE);
--*******************************************************
--Est-ce que le facteur de conversion est cohérente ?
--*******************************************************
        IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CDA_CONVERSION_FACTOR', tdata.CDA_CONVERSION_FACTOR, lcDomain, tdata.id, tdata.EXCEL_LINE);

        --Récupération de l'unité de stockage
        begin
          select DIC_UNIT_OF_MEASURE_ID
            into tmp
            from GCO_GOOD
           where GOO_MAJOR_REFERENCE = tdata.GOO_MAJOR_REFERENCE;

          --Si l'unité de stockage est la même que l'unité de la donnée complémentaire
          if     (tdata.DIC_UNIT_OF_MEASURE_ID = tmp)
             and (tdata.CDA_CONVERSION_FACTOR > 1) then
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_CDA_CONVERSION_FACTOR_2') );
          end if;
        exception
          when no_data_found then
            null;
        end;

--*****************************************************************
--Est-ce que la durée théorique d'approvisionnement est cohérente ?
--*****************************************************************
        if (tdata.CSA_TH_SUPPLY_DELAY is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CSA_TH_SUPPLY_DELAY', tdata.CSA_TH_SUPPLY_DELAY, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*****************************************************************
--Est-ce que la durée d'expédition est cohérente ?
--*****************************************************************
        if (tdata.CSA_DISPATCHING_DELAY is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CSA_DISPATCHING_DELAY', tdata.CSA_DISPATCHING_DELAY, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*****************************************************************
--Est-ce que la durée de livraison est cohérente ?
--*****************************************************************
        if (tdata.CSA_DELIVERY_DELAY is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CSA_DELIVERY_DELAY', tdata.CSA_DELIVERY_DELAY, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*****************************************************************
--Est-ce que la qté de conditionnement est cohérente ?
--*****************************************************************
        if (tdata.CSA_QTY_CONDITIONING is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CSA_QTY_CONDITIONING', tdata.CSA_QTY_CONDITIONING, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*****************************************************************
--Est-ce que l'horizon de réservation sur stock est cohérent ?
--*****************************************************************
        if (tdata.CSA_SCALE_LINK is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CSA_SCALE_LINK', tdata.CSA_SCALE_LINK, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*****************************************************************
--Est-ce que la marge sur date de péremption est cohérente ?
--*****************************************************************
        if (tdata.CSA_LAPSING_MARGE is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CSA_LAPSING_MARGE', tdata.CSA_LAPSING_MARGE, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;
      end if;
    end loop;

    --Si la table d'erreurs est vide, alors on insère le message repris par le pilotage de contrôle disant qu'il n'y a pas d'erreur
    IMP_PRC_TOOLS.checkErrors(lcDomain);
    commit;
  end IMP_GCO_SALE_CTRL;

  /**
  * Description
  *    Importation des données complémentaires de vente
  */
  procedure IMP_GCO_SALE_IMPORT
  is
    tmp     integer;
    lGoodID GCO_GOOD.GCO_GOOD_ID%type;
    ltGood  FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    --Contrôle que la table d'erreurs soit vide
    IMP_PRC_TOOLS.checkErrorsBeforeImport(lcDomain);

    --Parcours de toutes les lignes de la table temporaire IMP_GCO_SALE_ à insérer
    for tdata in (select *
                    from IMP_GCO_SALE_) loop
      -- Récupération ID du bien
      lGoodID  := FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', tdata.GOO_MAJOR_REFERENCE);

      --Insertion des données dans les tables !
      insert into GCO_COMPL_DATA_SALE
                  (GCO_COMPL_DATA_SALE_ID
                 , GCO_GOOD_ID
                 , A_DATECRE
                 , A_IDCRE
                 , DIC_UNIT_OF_MEASURE_ID
                 , CDA_NUMBER_OF_DECIMAL
                 , CDA_CONVERSION_FACTOR
                 , CSA_TH_SUPPLY_DELAY
                 , CSA_DISPATCHING_DELAY
                 , CSA_DELIVERY_DELAY
                 , CSA_QTY_CONDITIONING
                 , CSA_SCALE_LINK
                 , CSA_LAPSING_MARGE
                 , CDA_COMPLEMENTARY_REFERENCE
                 , PAC_CUSTOM_PARTNER_ID
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , CDA_FREE_DESCRIPTION
                  )
           values (GetNewId
                 , lGoodID
                 , sysdate
                 , IMP_LIB_TOOLS.getImportUserIni
                 , tdata.DIC_UNIT_OF_MEASURE_ID
                 , tdata.CDA_NUMBER_OF_DECIMAL
                 , tdata.CDA_CONVERSION_FACTOR
                 , tdata.CSA_TH_SUPPLY_DELAY
                 , tdata.CSA_DISPATCHING_DELAY
                 , tdata.CSA_DELIVERY_DELAY
                 , tdata.CSA_QTY_CONDITIONING
                 , tdata.CSA_SCALE_LINK
                 , tdata.CSA_LAPSING_MARGE
                 , tdata.CDA_COMPLEMENTARY_REFERENCE
                 , FWK_I_LIB_ENTITY.getIdfromPk2('PAC_PERSON', 'PER_KEY2', tdata.PER_KEY2)
                 , FWK_I_LIB_ENTITY.getIdfromPk2('STM_STOCK', 'STO_DESCRIPTION', tdata.STO_DESCRIPTION)
                 , IMP_LIB_TOOLS.getLocationId(tdata.STO_DESCRIPTION, tdata.LOC_DESCRIPTION)
                 , tdata.FREE1
                  );

      -- màj du flag sur le bien
      -- Création de l'entité GCO_GOOD
      FWK_I_MGT_ENTITY.new(FWK_TYP_GCO_ENTITY.gcGcoGood, ltGood);
      -- Init de l'id du bien
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGood, 'GCO_GOOD_ID', lGoodID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGood, 'GCO_DATA_SALE', 1);
      FWK_I_MGT_ENTITY.UpdateEntity(ltGood);
      FWK_I_MGT_ENTITY.Release(ltGood);

      --Insertion des données dans les tables !
      insert into IMP_HIST_GCO_SALE
                  (ID_HIST
                 , DATE_HIST
                 , EXCEL_LINE
                 , GOO_MAJOR_REFERENCE
                 , DIC_UNIT_OF_MEASURE_ID
                 , CDA_NUMBER_OF_DECIMAL
                 , CDA_CONVERSION_FACTOR
                 , CSA_TH_SUPPLY_DELAY
                 , CSA_DISPATCHING_DELAY
                 , CSA_DELIVERY_DELAY
                 , CSA_QTY_CONDITIONING
                 , CSA_SCALE_LINK
                 , CSA_LAPSING_MARGE
                 , CDA_COMPLEMENTARY_REFERENCE
                 , PER_KEY2
                 , STO_DESCRIPTION
                 , LOC_DESCRIPTION
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
                 , tdata.excel_line
                 , tdata.goo_major_reference
                 , tdata.DIC_UNIT_OF_MEASURE_ID
                 , tdata.CDA_NUMBER_OF_DECIMAL
                 , tdata.CDA_CONVERSION_FACTOR
                 , tdata.CSA_TH_SUPPLY_DELAY
                 , tdata.CSA_DISPATCHING_DELAY
                 , tdata.CSA_DELIVERY_DELAY
                 , tdata.CSA_QTY_CONDITIONING
                 , tdata.CSA_SCALE_LINK
                 , tdata.CSA_LAPSING_MARGE
                 , tdata.CDA_COMPLEMENTARY_REFERENCE
                 , tdata.per_key2
                 , tdata.STO_DESCRIPTION
                 , tdata.LOC_DESCRIPTION
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

    commit;
  end IMP_GCO_SALE_IMPORT;
end IMP_GCO_SALE;
