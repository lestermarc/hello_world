--------------------------------------------------------
--  DDL for Package Body IMP_GCO_PURCHASE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IMP_GCO_PURCHASE" 
as
  lcDomain constant varchar2(15) := 'GCO_PURCHASE';

  /**
  * Description
  *    importation des données d'Excel dans la table temporaire IMP_GCO_PURCHASE_. Cette procédure est appelée depuis Excel
  */
  procedure IMP_TMP_GCO_PURCHASE(
    pGOO_MAJOR_REFERENCE              varchar2
  , pPER_KEY2                         varchar2
  , pCPU_DEFAULT_SUPPLIER             varchar2
  , pSTO_DESCRIPTION                  varchar2
  , pLOC_DESCRIPTION                  varchar2
  , pDIC_UNIT_OF_MEASURE_ID           varchar2
  , pCPU_WARRANTY_PERIOD              varchar2
  , pC_ASA_GUARANTY_UNIT              varchar2
  , pC_QTY_SUPPLY_RULE                varchar2
  , pC_TIME_SUPPLY_RULE               varchar2
  , pCDA_NUMBER_OF_DECIMAL            varchar2
  , pCDA_CONVERSION_FACTOR            varchar2
  , pC_ECONOMIC_CODE                  varchar2
  , pCPU_ECONOMICAL_QUANTITY          varchar2
  , pCPU_FIXED_DELAY                  varchar2
  , pCPU_SHIFT                        varchar2
  , pCPU_SUPPLY_DELAY                 varchar2
  , pCPU_CONTROL_DELAY                varchar2
  , pCPU_SECURITY_DELAY               varchar2
  , pCPU_SUPPLY_CAPACITY              varchar2
  , pCPU_QUANTITY_REFERENCE_TRASH     varchar2
  , pCPU_FIXED_QUANTITY_TRASH         varchar2
  , pCPU_PERCENT_TRASH                varchar2
  , pCDA_COMPLEMENTARY_REFERENCE      varchar2
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
    --Insertion dans la table IMP_GCO_PURCHASE_
    insert into IMP_GCO_PURCHASE_
                (id
               , EXCEL_LINE
               , GOO_MAJOR_REFERENCE
               , PER_KEY2
               , CPU_DEFAULT_SUPPLIER
               , STO_DESCRIPTION
               , LOC_DESCRIPTION
               , DIC_UNIT_OF_MEASURE_ID
               , CPU_WARRANTY_PERIOD
               , C_ASA_GUARANTY_UNIT
               , C_QTY_SUPPLY_RULE
               , C_TIME_SUPPLY_RULE
               , CDA_NUMBER_OF_DECIMAL
               , CDA_CONVERSION_FACTOR
               , C_ECONOMIC_CODE
               , CPU_ECONOMICAL_QUANTITY
               , CPU_FIXED_DELAY
               , CPU_SHIFT
               , CPU_SUPPLY_DELAY
               , CPU_CONTROL_DELAY
               , CPU_SECURITY_DELAY
               , CPU_SUPPLY_CAPACITY
               , CPU_QUANTITY_REFERENCE_TRASH
               , CPU_FIXED_QUANTITY_TRASH
               , CPU_PERCENT_TRASH
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
               , trim(pCPU_DEFAULT_SUPPLIER)
               , trim(pSTO_DESCRIPTION)
               , trim(pLOC_DESCRIPTION)
               , trim(pDIC_UNIT_OF_MEASURE_ID)
               , trim(pCPU_WARRANTY_PERIOD)
               , trim(pC_ASA_GUARANTY_UNIT)
               , trim(pC_QTY_SUPPLY_RULE)
               , trim(pC_TIME_SUPPLY_RULE)
               , trim(pCDA_NUMBER_OF_DECIMAL)
               , trim(pCDA_CONVERSION_FACTOR)
               , trim(pC_ECONOMIC_CODE)
               , trim(pCPU_ECONOMICAL_QUANTITY)
               , trim(pCPU_FIXED_DELAY)
               , trim(pCPU_SHIFT)
               , trim(pCPU_SUPPLY_DELAY)
               , trim(pCPU_CONTROL_DELAY)
               , trim(pCPU_SECURITY_DELAY)
               , trim(pCPU_SUPPLY_CAPACITY)
               , trim(pCPU_QUANTITY_REFERENCE_TRASH)
               , trim(pCPU_FIXED_QUANTITY_TRASH)
               , trim(pCPU_PERCENT_TRASH)
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
  end IMP_TMP_GCO_PURCHASE;

  /**
  * Description
  *    Contrôle les données de la table IMP_GCO_PURCHASE_ avant importation
  */
  procedure IMP_GCO_PURCHASE_CTRL
  as
    tmp         varchar2(200);
    tmp_int     integer;
    tmp_int2    integer;
    lvTableName varchar2(30)  := 'GCO_COMPL_DATA_PURCHASE';
  begin
    --Effacement des tables d'erreurs
    IMP_PRC_TOOLS.deleteErrors(lcDomain);

--************************************************************************
--Est-ce qu'il y a le flag fournisseur par défaut sans fournisseur spécifié ?
--Est-ce qu'il y a un ou des fournisseurs pour la donnée complémentaire ?
--Est-ce que ce/ces fournisseur(s) existe(nt) ?
--Est-ce qu'il y a un fournisseur par défaut au minimum et au maximum
--Est-ce qu'il y a deux fois le même fournisseur pour un produit ?
--************************************************************************
--Est-ce qu'il y des données sans fournisseur et avec le flag fournisseur par défaut coché ?
    select count(CPU_DEFAULT_SUPPLIER)
      into tmp_int
      from IMP_GCO_PURCHASE_
     where per_key2 is null
       and CPU_DEFAULT_SUPPLIER > 0;

    if (tmp_int > 0) then
      IMP_PRC_TOOLS.insertError(lcDomain, 0, '-', pcs.pc_functions.TranslateWord('IMP_GCO_DATA_COMPL_FOURN_4') );
    end if;

    --Parcours de tous les biens qui ont des fournisseurs associés
    for tProduct in (select distinct GOO_MAJOR_REFERENCE
                                   , PER_KEY2
                                   , EXCEL_LINE
                                from IMP_GCO_PURCHASE_
                               where PER_KEY2 is not null) loop
      --Pour chaque bien on parcours tous les fournisseurs et on vérifie leur existance
      for tSupplier in (select PER_KEY2
                             , EXCEL_LINE
                             , id
                          from IMP_GCO_SALE_
                         where GOO_MAJOR_REFERENCE = tProduct.GOO_MAJOR_REFERENCE
                           and PER_KEY2 is not null) loop
        -- Vérification de l'existance du fournisseur
        select count(*)
          into tmp_int
          from dual
         where exists(select PAC_PERSON_ID
                        from PAC_PERSON
                           , PAC_SUPPLIER_PARTNER
                       where PAC_PERSON_ID = PAC_SUPPLIER_PARTNER_ID
                         and PER_KEY2 = tSupplier.PER_KEY2);

        --Si inexistant, insertion d'une erreur.
        if (tmp_int = 0) then
          IMP_PRC_TOOLS.insertError(lcDomain
                                  , tSupplier.id
                                  , tSupplier.EXCEL_LINE
                                  , pcs.PC_FUNCTIONS.TranslateWord('IMP_SUPPLIER') ||
                                    ' ' ||
                                    tSupplier.PER_KEY2 ||
                                    ' ' ||
                                    pcs.PC_FUNCTIONS.TranslateWord('IMP_INEXISTANT')
                                   );
        end if;
      end loop;

      --Vérifie qu'il n'y a pas deux fois le même fournisseur pour le même bien
      select   max(count(PER_KEY2) )
          into tmp_int
          from IMP_GCO_PURCHASE_
         where GOO_MAJOR_REFERENCE = tProduct.GOO_MAJOR_REFERENCE
      group by PER_KEY2;

      --Si c'est le cas
      if (tmp_int > 1) then
        IMP_PRC_TOOLS.insertError(lcDomain
                                , 0
                                , tProduct.EXCEL_LINE
                                , pcs.pc_functions.TranslateWord('IMP_GCO_DATA_COMPL_3') ||
                                  ' ' ||
                                  tProduct.goo_major_reference ||
                                  ' ' ||
                                  pcs.pc_functions.TranslateWord('IMP_GCO_DATA_COMPL_FOURN_3')
                                 );
      end if;

      --On vérifie aussi qu'il y a un fournisseur par défaut au minimum et un au maximum
      select nvl(sum(CPU_DEFAULT_SUPPLIER), 0)
        into tmp_int
        from IMP_GCO_PURCHASE_
       where GOO_MAJOR_REFERENCE = tProduct.GOO_MAJOR_REFERENCE;

      if (tmp_int > 1) then
        IMP_PRC_TOOLS.insertError(lcDomain
                                , 0
                                , tProduct.EXCEL_LINE
                                , pcs.pc_functions.TranslateWord('IMP_GCO_DATA_COMPL_FOURN') || ' ' || tProduct.GOO_MAJOR_REFERENCE
                                 );
      else
        --Vérifie dans la base, si ce bien possède déjà une donnée complémentaire achat avec un fournisseur par défaut
        select nvl(sum(CPU_DEFAULT_SUPPLIER), 0)
          into tmp_int2
          from GCO_COMPL_DATA_PURCHASE
         where GCO_GOOD_ID = FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', tProduct.GOO_MAJOR_REFERENCE)
           and CPU_DEFAULT_SUPPLIER = 1;

        if tmp_int + tmp_int2 < 1 then
          IMP_PRC_TOOLS.insertError(lcDomain
                                  , 0
                                  , tProduct.EXCEL_LINE
                                  , pcs.pc_functions.TranslateWord('IMP_GCO_DATA_COMPL_FOURN_LEAST_ONE_DEFAULT') || ' ' || tProduct.GOO_MAJOR_REFERENCE
                                   );
        elsif tmp_int + tmp_int2 > 1 then
          IMP_PRC_TOOLS.insertError(lcDomain
                                  , 0
                                  , tProduct.EXCEL_LINE
                                  , pcs.pc_functions.TranslateWord('IMP_GCO_DATA_COMPL_FOURN') || ' ' || tProduct.GOO_MAJOR_REFERENCE
                                   );
        end if;
      end if;
    end loop;

    --Parcours de tous les biens qui n'ont pas de fournisseurs associés à leur données compl
    for tproduct_ws in (select distinct goo_major_reference
                                      , EXCEL_LINE
                                   from IMP_GCO_PURCHASE_
                                  where per_key2 is null) loop
      --Est-ce qu'il y a plusieurs données compl pour le même produit sans fournisseur ?
      select   count(goo_major_reference)
          into tmp_int
          from imp_gco_purchase_
         where goo_major_reference = tproduct_ws.goo_major_reference
           and per_key2 is null
      group by goo_major_reference;

      --Si c'est le cas
      if (tmp_int > 1) then
        IMP_PRC_TOOLS.insertError(lcDomain
                                , 0
                                , tproduct_ws.EXCEL_LINE
                                , pcs.pc_functions.TranslateWord('IMP_GCO_DATA_COMPL_3') ||
                                  ' ' ||
                                  tproduct_ws.goo_major_reference ||
                                  ' ' ||
                                  pcs.pc_functions.TranslateWord('IMP_GCO_DATA_COMPL_FOURN_2')
                                 );
      end if;
    end loop;

    --Parcours de toutes les lignes de la table IMP_GCO_PURCHASE_
    for tdata in (select *
                    from IMP_GCO_PURCHASE_) loop
      /*******************************************************
      * --> Est-ce que tous les champs obligatoires sont présents ?
      *******************************************************/
      if (   tdata.GOO_MAJOR_REFERENCE is null
          or tdata.CPU_DEFAULT_SUPPLIER is null
          or tdata.DIC_UNIT_OF_MEASURE_ID is null
          or tdata.CDA_NUMBER_OF_DECIMAL is null
          or tdata.CDA_CONVERSION_FACTOR is null
          or tdata.C_QTY_SUPPLY_RULE is null
          or tdata.C_TIME_SUPPLY_RULE is null
          or tdata.C_ECONOMIC_CODE is null
         ) then
        IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_REQUIRED') );
      else
--*******************************************************
--Est-ce que la référence principale existe ?
--*******************************************************
        IMP_PRC_TOOLS.checkGoodExists(tdata.GOO_MAJOR_REFERENCE, lcDomain, tdata.id, tdata.EXCEL_LINE);

--********************************************************************************
--Est-ce qu'une donnée complémentaire existe déjà pour ce bien et ce fournisseur ?
--********************************************************************************
        if (tdata.PER_KEY2 is not null) then
          begin
            --Recherche d'une donnée complémentaire pour le même tiers et le même produit
            select gco_compl_data_purchase_id
              into tmp_int
              from gco_compl_data_purchase
             where pac_supplier_partner_id = FWK_I_LIB_ENTITY.getIdfromPk2('PAC_PERSON', 'PER_KEY2', tdata.PER_KEY2)
               and gco_good_id = FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', tdata.GOO_MAJOR_REFERENCE);

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
            select gco_compl_data_purchase_id
              into tmp_int
              from gco_compl_data_purchase
             where pac_supplier_partner_id is null
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
--Est-ce que la période de garantie est cohérente ?
--*******************************************************
--Si qqch est renseigné
        if (   tdata.CPU_WARRANTY_PERIOD is not null
            or tdata.C_ASA_GUARANTY_UNIT is not null) then
          --Nombre de période dans l'intervalle 1-999 ?
          if not(tdata.CPU_WARRANTY_PERIOD between 1 and 999) then
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_CPU_WARRANTY_PERIOD') );
          end if;

          --Unité de garabtie cohérente ?
          if tdata.C_ASA_GUARANTY_UNIT not in('D', 'M', 'W', 'Y') then
            --Le champ est-il rempli ?
            if (tdata.C_ASA_GUARANTY_UNIT is null) then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_C_ASA_GUARANTY_UNIT') );
            else
              IMP_PRC_TOOLS.insertError(lcDomain
                                      , tdata.id
                                      , tdata.EXCEL_LINE
                                      , pcs.pc_functions.TranslateWord('IMP_C_ASA_GUARANTY_UNIT_2') ||
                                        tdata.C_ASA_GUARANTY_UNIT ||
                                        pcs.pc_functions.TranslateWord('IMP_C_ASA_GUARANTY_UNIT_3')
                                       );
            end if;
          end if;
        end if;

--*******************************************************
--Est-ce que le nombre de décimales est correct?
--*******************************************************
        IMP_PRC_TOOLS.checkDescodeValue('CDA_NUMBER_OF_DECIMAL', tdata.CDA_NUMBER_OF_DECIMAL, '{0,1,2,3,4}', lcDomain, tdata.id, tdata.EXCEL_LINE);
--*******************************************************
--Est-ce que la règle quantitative d'appro est cohérente ?
--*******************************************************
        IMP_PRC_TOOLS.checkDescodeValue('C_QTY_SUPPLY_RULE', tdata.C_QTY_SUPPLY_RULE, '{1,2}', lcDomain, tdata.id, tdata.EXCEL_LINE);
--*******************************************************
--Est-ce que la règle temporelle d'appro est cohérente ?
--*******************************************************
        IMP_PRC_TOOLS.checkDescodeValue('C_TIME_SUPPLY_RULE', tdata.C_TIME_SUPPLY_RULE, '{1,2}', lcDomain, tdata.id, tdata.EXCEL_LINE);
--*******************************************************
--Est-ce que le facteur de conversion est cohérente ?
--*******************************************************
        IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CDA_CONVERSION_FACTOR', tdata.CDA_CONVERSION_FACTOR, lcDomain, tdata.id, tdata.EXCEL_LINE);

        begin
          --Récupération de l'unité de stockage
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

--*******************************************************
--Est-ce que le code quantité économique est cohérent ?
--*******************************************************
        IMP_PRC_TOOLS.checkDescodeValue('C_ECONOMIC_CODE', tdata.C_ECONOMIC_CODE, '{1,2,3,4}', lcDomain, tdata.id, tdata.EXCEL_LINE);

--*******************************************************
--Est-ce que la quantité économique est cohérente ?
--*******************************************************
        if (tdata.CPU_ECONOMICAL_QUANTITY is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CPU_ECONOMICAL_QUANTITY', tdata.CPU_ECONOMICAL_QUANTITY, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
--Est-ce que le nombre de périodicité fixe est cohérent ?
--*******************************************************
        if (tdata.CPU_FIXED_DELAY is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CPU_FIXED_DELAY', tdata.CPU_FIXED_DELAY, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
--Est-ce que le décalage est cohérent ?
--*******************************************************
        if (tdata.CPU_SHIFT is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CPU_SHIFT', tdata.CPU_SHIFT, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
--Est-ce que la durée d'approvisionnement est cohérente ?
--*******************************************************
        if (tdata.CPU_SUPPLY_DELAY is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CPU_SUPPLY_DELAY', tdata.CPU_SUPPLY_DELAY, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
--Est-ce que la durée de contrôle est cohérente ?
--*******************************************************
        if (tdata.CPU_CONTROL_DELAY is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CPU_CONTROL_DELAY', tdata.CPU_CONTROL_DELAY, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
--Est-ce que le délai de sécurité est cohérent ?
--*******************************************************
        if (tdata.CPU_SECURITY_DELAY is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CPU_SECURITY_DELAY', tdata.CPU_SECURITY_DELAY, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
--Est-ce que la capacité d'approvisionnement est cohérente ?
--*******************************************************
        if (tdata.CPU_SUPPLY_CAPACITY is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CPU_SUPPLY_CAPACITY', tdata.CPU_SUPPLY_CAPACITY, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
--Est-ce que la quantité de référence de rebut est cohérente ?
--*******************************************************
        if (tdata.CPU_QUANTITY_REFERENCE_TRASH is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CPU_QUANTITY_REFERENCE_TRASH', tdata.CPU_QUANTITY_REFERENCE_TRASH, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
--Est-ce que la quantité fixe de rebut est cohérente ?
--*******************************************************
        if (tdata.CPU_FIXED_QUANTITY_TRASH is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CPU_FIXED_QUANTITY_TRASH', tdata.CPU_FIXED_QUANTITY_TRASH, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
--Est-ce que le pourcentage de rebut est cohérent ?
--*******************************************************
        if (tdata.CPU_PERCENT_TRASH is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CPU_PERCENT_TRASH', tdata.CPU_PERCENT_TRASH, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;
      end if;
    end loop;

    --Si la table d'erreurs est vide, alors on insère le message repris par le pilotage de contrôle disant qu'il n'y a pas d'erreur
    IMP_PRC_TOOLS.checkErrors(lcDomain);
    commit;
  end IMP_GCO_PURCHASE_CTRL;

  /**
  * Description
  *    Importation des données complémentaires achat
  */
  procedure IMP_GCO_PURCHASE_IMPORT
  is
    tmp     integer;
    lGoodID GCO_GOOD.GCO_GOOD_ID%type;
    ltGood  FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    --Contrôle que la table d'erreurs soit vide
    IMP_PRC_TOOLS.checkErrorsBeforeImport(lcDomain);

    --Parcours de toutes les lignes de la table temporaire IMP_GCO_PURCHASE_ à insérer
    for tdata in (select *
                    from IMP_GCO_PURCHASE_) loop
      -- Récupération ID du bien
      lGoodID  := FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', tdata.GOO_MAJOR_REFERENCE);

      --Insertion des données dans les tables !
      insert into GCO_COMPL_DATA_PURCHASE
                  (GCO_COMPL_DATA_PURCHASE_ID
                 , GCO_GOOD_ID
                 , A_DATECRE
                 , A_IDCRE
                 , DIC_UNIT_OF_MEASURE_ID
                 , CDA_NUMBER_OF_DECIMAL
                 , CDA_CONVERSION_FACTOR
                 , CPU_DEFAULT_SUPPLIER
                 , C_ECONOMIC_CODE
                 , CDA_COMPLEMENTARY_REFERENCE
                 , PAC_SUPPLIER_PARTNER_ID
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , C_ASA_GUARANTY_UNIT
                 , CPU_WARRANTY_PERIOD
                 , CPU_AUTOMATIC_GENERATING_PROP
                 , CPU_SHIFT
                 , CPU_SUPPLY_DELAY
                 , CPU_SECURITY_DELAY
                 , CPU_ECONOMICAL_QUANTITY
                 , CPU_FIXED_DELAY
                 , CPU_SUPPLY_CAPACITY
                 , CPU_CONTROL_DELAY
                 , CPU_PERCENT_TRASH
                 , CPU_FIXED_QUANTITY_TRASH
                 , CPU_QTY_REFERENCE_TRASH
                 , C_QTY_SUPPLY_RULE
                 , C_TIME_SUPPLY_RULE
                  )
           values (GetNewId
                 , lGoodID
                 , sysdate
                 , IMP_LIB_TOOLS.getImportUserIni
                 , tdata.DIC_UNIT_OF_MEASURE_ID
                 , tdata.CDA_NUMBER_OF_DECIMAL
                 , tdata.CDA_CONVERSION_FACTOR
                 , tdata.CPU_DEFAULT_SUPPLIER
                 , tdata.C_ECONOMIC_CODE
                 , tdata.CDA_COMPLEMENTARY_REFERENCE
                 , FWK_I_LIB_ENTITY.getIdfromPk2('PAC_PERSON', 'PER_KEY2', tdata.PER_KEY2)
                 , FWK_I_LIB_ENTITY.getIdfromPk2('STM_STOCK', 'STO_DESCRIPTION', tdata.STO_DESCRIPTION)
                 , IMP_LIB_TOOLS.getLocationId(tdata.STO_DESCRIPTION, tdata.LOC_DESCRIPTION)
                 , nvl(tdata.C_ASA_GUARANTY_UNIT, 'Y')
                 , tdata.CPU_WARRANTY_PERIOD
                 , 1
                 , tdata.CPU_SHIFT
                 , tdata.CPU_SUPPLY_DELAY
                 , tdata.CPU_SECURITY_DELAY
                 , tdata.CPU_ECONOMICAL_QUANTITY
                 , tdata.CPU_FIXED_DELAY
                 , tdata.CPU_SUPPLY_CAPACITY
                 , tdata.CPU_CONTROL_DELAY
                 , tdata.CPU_PERCENT_TRASH
                 , tdata.CPU_FIXED_QUANTITY_TRASH
                 , tdata.CPU_QUANTITY_REFERENCE_TRASH
                 , tdata.C_QTY_SUPPLY_RULE
                 , tdata.C_TIME_SUPPLY_RULE
                  );

      -- màj du flag sur le bien
      -- Création de l'entité GCO_GOOD
      FWK_I_MGT_ENTITY.new(FWK_TYP_GCO_ENTITY.gcGcoGood, ltGood);
      -- Init de l'id du bien
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGood, 'GCO_GOOD_ID', lGoodID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGood, 'GCO_DATA_PURCHASE', 1);
      FWK_I_MGT_ENTITY.UpdateEntity(ltGood);
      FWK_I_MGT_ENTITY.Release(ltGood);

      --Insertion des données dans les tables !
      insert into IMP_HIST_GCO_PURCHASE
                  (ID_HIST
                 , DATE_HIST
                 , EXCEL_LINE
                 , GOO_MAJOR_REFERENCE
                 , DIC_UNIT_OF_MEASURE_ID
                 , CDA_NUMBER_OF_DECIMAL
                 , CDA_CONVERSION_FACTOR
                 , CPU_DEFAULT_SUPPLIER
                 , C_ECONOMIC_CODE
                 , CDA_COMPLEMENTARY_REFERENCE
                 , PER_KEY2
                 , STO_DESCRIPTION
                 , LOC_DESCRIPTION
                 , C_ASA_GUARANTY_UNIT
                 , CPU_WARRANTY_PERIOD
                 , CPU_SHIFT
                 , CPU_SUPPLY_DELAY
                 , CPU_SECURITY_DELAY
                 , CPU_ECONOMICAL_QUANTITY
                 , CPU_FIXED_DELAY
                 , CPU_SUPPLY_CAPACITY
                 , CPU_CONTROL_DELAY
                 , CPU_PERCENT_TRASH
                 , CPU_FIXED_QUANTITY_TRASH
                 , CPU_QUANTITY_REFERENCE_TRASH
                 , C_QTY_SUPPLY_RULE
                 , C_TIME_SUPPLY_RULE
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
                 , tdata.DIC_UNIT_OF_MEASURE_ID
                 , tdata.CDA_NUMBER_OF_DECIMAL
                 , tdata.CDA_CONVERSION_FACTOR
                 , tdata.CPU_DEFAULT_SUPPLIER
                 , tdata.C_ECONOMIC_CODE
                 , tdata.CDA_COMPLEMENTARY_REFERENCE
                 , tdata.PER_KEY2
                 , tdata.STO_DESCRIPTION
                 , tdata.LOC_DESCRIPTION
                 , tdata.C_ASA_GUARANTY_UNIT
                 , tdata.CPU_WARRANTY_PERIOD
                 , tdata.CPU_SHIFT
                 , tdata.CPU_SUPPLY_DELAY
                 , tdata.CPU_SECURITY_DELAY
                 , tdata.CPU_ECONOMICAL_QUANTITY
                 , tdata.CPU_FIXED_DELAY
                 , tdata.CPU_SUPPLY_CAPACITY
                 , tdata.CPU_CONTROL_DELAY
                 , tdata.CPU_PERCENT_TRASH
                 , tdata.CPU_FIXED_QUANTITY_TRASH
                 , tdata.CPU_QUANTITY_REFERENCE_TRASH
                 , tdata.C_QTY_SUPPLY_RULE
                 , tdata.C_TIME_SUPPLY_RULE
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
  end IMP_GCO_PURCHASE_IMPORT;
end IMP_GCO_PURCHASE;
