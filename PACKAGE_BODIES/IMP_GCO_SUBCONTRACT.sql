--------------------------------------------------------
--  DDL for Package Body IMP_GCO_SUBCONTRACT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IMP_GCO_SUBCONTRACT" 
as
  lcDomain constant varchar2(15) := 'GCO_SUBCTRCT';

  /**
  * Description
  *    importation des données d'Excel dans la table temporaire IMP_GCO_SUBCONTRACT_. Cette procédure est appelée depuis Excel
  */
  procedure IMP_TMP_GCO_SUBCONTRACT(
    pGOO_MAJOR_REFERENCE           varchar2
  , pPER_KEY2                      varchar2
  , pDIC_FAB_CONDITION_ID          varchar2
  , pCSU_DEFAULT_SUBCONTRACTER     varchar2
  , pCSU_VALIDITY_DATE             varchar2
  , pSTO_DESCRIPTION               varchar2
  , pLOC_DESCRIPTION               varchar2
  , pC_TYPE_NOM                    varchar2
  , pC_DISCHARGE_COM               varchar2
  , pCSU_PLAN_NUMBER               varchar2
  , pCSU_PLAN_VERSION              varchar2
  , pOPP_DESCRIBE                  varchar2   -- OPP_REFERENCE !!!
  , pC_GOOD_LITIG                  varchar2
  , pCSU_WEIGH                     varchar2
  , pCSU_WEIGH_MANDATORY           varchar2
  , pSRV_MAJOR_REFERENCE           varchar2
  , pCSU_AMOUNT                    varchar2
  , pC_QTY_SUPPLY_RULE             varchar2
  , pCSU_ECONOMICAL_QUANTITY       varchar2
  , pC_ECONOMIC_CODE               varchar2
  , pC_TIME_SUPPLY_RULE            varchar2
  , pCSU_FIXED_DELAY               varchar2
  , pCSU_SHIFT                     varchar2
  , pCSU_SUBCONTRACTING_DELAY      varchar2
  , pCSU_SECURITY_DELAY            varchar2
  , pCSU_LOT_QUANTITY              varchar2
  , pCSU_FIX_DELAY                 varchar2
  , pCSU_PERCENT_TRASH             varchar2
  , pCSU_FIXED_QUANTITY_TRASH      varchar2
  , pCSU_QTY_REFERENCE_TRASH       varchar2
  , pFREE1                         varchar2
  , pFREE2                         varchar2
  , pFREE3                         varchar2
  , pFREE4                         varchar2
  , pFREE5                         varchar2
  , pFREE6                         varchar2
  , pFREE7                         varchar2
  , pFREE8                         varchar2
  , pFREE9                         varchar2
  , pFREE10                        varchar2
  , pEXCEL_LINE                    integer
  , pRESULT                    out integer
  )
  is
  begin
    --Insertion dans la table IMP_GCO_SUBCONTRACT_
    insert into IMP_GCO_SUBCONTRACT_
                (id
               , EXCEL_LINE
               , GOO_MAJOR_REFERENCE
               , PER_KEY2
               , DIC_FAB_CONDITION_ID
               , CSU_DEFAULT_SUBCONTRACTER
               , CSU_VALIDITY_DATE
               , STO_DESCRIPTION
               , LOC_DESCRIPTION
               , C_TYPE_NOM
               , C_DISCHARGE_COM
               , CSU_PLAN_NUMBER
               , CSU_PLAN_VERSION
               , OPP_DESCRIBE
               , C_GOOD_LITIG
               , CSU_WEIGH
               , CSU_WEIGH_MANDATORY
               , SRV_MAJOR_REFERENCE
               , CSU_AMOUNT
               , C_QTY_SUPPLY_RULE
               , CSU_ECONOMICAL_QUANTITY
               , C_ECONOMIC_CODE
               , C_TIME_SUPPLY_RULE
               , CSU_FIXED_DELAY
               , CSU_SHIFT
               , CSU_SUBCONTRACTING_DELAY
               , CSU_SECURITY_DELAY
               , CSU_LOT_QUANTITY
               , CSU_FIX_DELAY
               , CSU_PERCENT_TRASH
               , CSU_FIXED_QUANTITY_TRASH
               , CSU_QTY_REFERENCE_TRASH
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
               , trim(pDIC_FAB_CONDITION_ID)
               , trim(pCSU_DEFAULT_SUBCONTRACTER)
               , trim(pCSU_VALIDITY_DATE)
               , trim(pSTO_DESCRIPTION)
               , trim(pLOC_DESCRIPTION)
               , trim(pC_TYPE_NOM)
               , trim(pC_DISCHARGE_COM)
               , trim(pCSU_PLAN_NUMBER)
               , trim(pCSU_PLAN_VERSION)
               , trim(pOPP_DESCRIBE)
               , trim(pC_GOOD_LITIG)
               , trim(pCSU_WEIGH)
               , trim(pCSU_WEIGH_MANDATORY)
               , trim(pSRV_MAJOR_REFERENCE)
               , trim(pCSU_AMOUNT)
               , trim(pC_QTY_SUPPLY_RULE)
               , trim(pCSU_ECONOMICAL_QUANTITY)
               , trim(pC_ECONOMIC_CODE)
               , trim(pC_TIME_SUPPLY_RULE)
               , trim(pCSU_FIXED_DELAY)
               , trim(pCSU_SHIFT)
               , trim(pCSU_SUBCONTRACTING_DELAY)
               , trim(pCSU_SECURITY_DELAY)
               , trim(pCSU_LOT_QUANTITY)
               , trim(pCSU_FIX_DELAY)
               , trim(pCSU_PERCENT_TRASH)
               , trim(pCSU_FIXED_QUANTITY_TRASH)
               , trim(pCSU_QTY_REFERENCE_TRASH)
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
  end IMP_TMP_GCO_SUBCONTRACT;

  /**
  * Description
  *    Contrôle des données de la table IMP_GCO_SUBCONTRACT_ avant importation.
  */
  procedure IMP_GCO_SUBCONTRACT_CTRL
  is
    tmp         varchar2(200);
    tmp_int     integer;
    tmp_int2    integer;
    lvTableName varchar2(30)  := 'GCO_COMPL_DATA_SUBCONTRACT';
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
    select count(CSU_DEFAULT_SUBCONTRACTER)
      into tmp_int
      from IMP_GCO_SUBCONTRACT_
     where PER_KEY2 is null
       and CSU_DEFAULT_SUBCONTRACTER > 0;

    if (tmp_int > 0) then
      IMP_PRC_TOOLS.insertError(lcDomain, 0, 0, pcs.pc_functions.TranslateWord('IMP_GCO_DATA_COMPL_FOURN_4') );
    end if;

    --Parcours de tous les biens qui ont des fournisseurs associés
    for tproduct in (select distinct goo_major_reference
                                   , PER_KEY2
                                from IMP_GCO_SUBCONTRACT_
                               where PER_KEY2 is not null) loop
      --Pour chaque bien on parcours tous les fournisseurs et on vérifie qu'ils existent
      for tsupp in (select PER_KEY2
                         , EXCEL_LINE
                         , id
                      from IMP_GCO_SUBCONTRACT_
                     where GOO_MAJOR_REFERENCE = tproduct.GOO_MAJOR_REFERENCE
                       and PER_KEY2 is not null) loop
        --Vérifie que le fournisseur existe
        select count(*)
          into tmp_int
          from PAC_PERSON
         where PER_KEY2 = tsupp.PER_KEY2;

        --S'il n'existe pas, alors on crée une erreur
        if (tmp_int = 0) then
          IMP_PRC_TOOLS.insertError(lcDomain
                                  , tsupp.id
                                  , tsupp.EXCEL_LINE
                                  , pcs.pc_functions.TranslateWord('IMP_SUPPLIER') ||
                                    ' ' ||
                                    tsupp.PER_KEY2 ||
                                    ' ' ||
                                    pcs.pc_functions.TranslateWord('IMP_INEXISTANT')
                                   );
        end if;
      end loop;

      --On vérifie aussi qu'il y a un fournisseur par défaut au minimum et un au maximum
      select sum(IMP_PUBLIC.TONUMBER(CSU_DEFAULT_SUBCONTRACTER) )
        into tmp_int
        from IMP_GCO_SUBCONTRACT_
       where goo_major_reference = tproduct.goo_major_reference;

      if (tmp_int < 1) then
        --Vérifie si dans la base, si ce bien possède déjà une donnée compl par défaut
        begin
          select gco_compl_data_subcontract_id
            into tmp_int2
            from gco_compl_data_subcontract
           where gco_good_id = (select gco_good_id
                                  from gco_good
                                 where goo_major_reference = tproduct.goo_major_reference);
        --Pas de fournisseur par défaut dans la base et pas de fournisseur par défaut dans le fichier !
        exception
          when no_data_found then
            IMP_PRC_TOOLS.insertError(lcDomain, 0, '-', pcs.pc_functions.TranslateWord('IMP_GCO_DATA_COMPL_FOURN') || tproduct.GOO_MAJOR_REFERENCE);
        end;
      end if;

      if (tmp_int > 1) then
        IMP_PRC_TOOLS.insertError(lcDomain, 0, '-', pcs.pc_functions.TranslateWord('IMP_GCO_DATA_COMPL_FOURN') || tproduct.GOO_MAJOR_REFERENCE);
      end if;
    end loop;

    -- Contrôle de la PK2
    --  1  GCO_GOOD_ID               (GOO_MAJOR_REFERENCE dans la table d'import)
    --  2  PAC_SUPPLIER_PARTNER_ID   (PER_KEY2 dans la table d'import)
    --  3  CSU_DEFAULT_SUBCONTRACTER
    --  4  DIC_COMPLEMENTARY_DATA_ID (pas présent dans la table d'import)
    --  5  CSU_VALIDITY_DATE         (pas présent dans la table d'import)
    for ltplCtrlPk2 in (select   GOO_MAJOR_REFERENCE
                               , nvl(PER_KEY2, '-1') as PER_KEY2
                               , nvl(CSU_DEFAULT_SUBCONTRACTER, 0) as CSU_DEFAULT_SUBCONTRACTER
                            from IMP_GCO_SUBCONTRACT_
                        group by GOO_MAJOR_REFERENCE
                               , nvl(PER_KEY2, '-1')
                               , nvl(CSU_DEFAULT_SUBCONTRACTER, 0)
                          having count(*) > 1) loop
      IMP_PRC_TOOLS.insertError(lcDomain, 0, '-', pcs.pc_functions.TranslateWord('IMP_GCO_DATA_COMPL_SUBCONTRACT_PK2') || ltplCtrlPk2.GOO_MAJOR_REFERENCE);
    end loop;

    --Parcours de toutes les lignes de la table IMP_GCO_SUBCONTRACT_
    for tdata in (select *
                    from IMP_GCO_SUBCONTRACT_) loop
      /*******************************************************
      * --> Est-ce que tous les champs obligatoires sont présents ?
      *******************************************************/
      if (   tdata.GOO_MAJOR_REFERENCE is null
          or tdata.PER_KEY2 is null
          or tdata.DIC_FAB_CONDITION_ID is null
          or tdata.CSU_DEFAULT_SUBCONTRACTER is null
          or tdata.SRV_MAJOR_REFERENCE is null
          or tdata.C_QTY_SUPPLY_RULE is null
          or tdata.C_ECONOMIC_CODE is null
          or tdata.C_TIME_SUPPLY_RULE is null
         ) then
        IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_REQUIRED') );
      else
--*******************************************************
--Est-ce que la référence principale existe ?
--*******************************************************
        begin
          select GOO_MAJOR_REFERENCE
            into tmp
            from GCO_GOOD
           where GOO_MAJOR_REFERENCE = tdata.GOO_MAJOR_REFERENCE;
        exception
          when no_data_found then
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_GOO_MAJOR_REFERENCE') );
        end;

--*******************************************************
--Est-ce que la référence du service existe ?
--*******************************************************
        if tdata.SRV_MAJOR_REFERENCE is not null then
          begin
            select goo_major_reference
              into tmp
              from gco_good
             where goo_major_reference = tdata.SRV_MAJOR_REFERENCE;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_GCO_SERVICE_REFERENCE') );
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
--Est-ce que la règle quantitative d'appro est cohérente ?
--*******************************************************
        IMP_PRC_TOOLS.checkDescodeValue('C_QTY_SUPPLY_RULE', tdata.C_QTY_SUPPLY_RULE, '{1,2}', lcDomain, tdata.id, tdata.EXCEL_LINE);
--*******************************************************
--Est-ce que la règle temporelle d'appro est cohérente ?
--*******************************************************
        IMP_PRC_TOOLS.checkDescodeValue('C_TIME_SUPPLY_RULE', tdata.C_TIME_SUPPLY_RULE, '{1,2}', lcDomain, tdata.id, tdata.EXCEL_LINE);
--*******************************************************
--Est-ce que le code quantité économique est cohérent ?
--*******************************************************
        IMP_PRC_TOOLS.checkDescodeValue('C_ECONOMIC_CODE', tdata.C_ECONOMIC_CODE, '{1,2,3,4}', lcDomain, tdata.id, tdata.EXCEL_LINE);

--*******************************************************
--Est-ce que le code décharge est cohérent ?
--*******************************************************
        if tdata.C_DISCHARGE_COM is not null then
          IMP_PRC_TOOLS.checkDescodeValue('C_DISCHARGE_COM', tdata.C_DISCHARGE_COM, '{2,5}', lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
--Est-ce que le code litige est cohérent ?
--*******************************************************
        if tdata.C_GOOD_LITIG is not null then
          IMP_PRC_TOOLS.checkDescodeValue('C_GOOD_LITIG', tdata.C_GOOD_LITIG, '{1,2,3,4}', lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

        /********************************************************
        * --> Est-ce que le code pesée matière précieuse est correcte ?
        ********************************************************/
        IMP_PRC_TOOLS.checkBooleanValue('CSU_WEIGH', nvl(tdata.CSU_WEIGH, 0), lcDomain, tdata.id, tdata.EXCEL_LINE);
        /********************************************************
        * --> Est-ce que le code pesée obligatoire est correcte ?
        ********************************************************/
        IMP_PRC_TOOLS.checkBooleanValue('CSU_WEIGH_MANDATORY', nvl(tdata.CSU_WEIGH_MANDATORY, 0), lcDomain, tdata.id, tdata.EXCEL_LINE);
        /********************************************************
        * --> Est-ce que la durée fixe est correcte ?
        ********************************************************/
        IMP_PRC_TOOLS.checkBooleanValue('CSU_FIX_DELAY', nvl(tdata.CSU_WEIGH_MANDATORY, 1), lcDomain, tdata.id, tdata.EXCEL_LINE);

        /********************************************************
        * --> Est-ce que la procédure opératoire existe ?
        ********************************************************/
        if (tdata.OPP_DESCRIBE is not null) then
          begin
            --Recherche de la procédure opératoire pour le produit
            select OPP_REFERENCE
              into tmp
              from PPS_OPERATION_PROCEDURE
             where OPP_REFERENCE = tdata.OPP_DESCRIBE;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_OPP_DESCRIBE') );
          end;
        end if;

--**************************************************************************
--Est-ce que le type de nomenclature existe ? /!\ PK2 pas complète ici !
--********************************************************************************
        if (tdata.C_TYPE_NOM is not null) then
          --Recherche de type de nomenclature pour le produit
          select count(C_TYPE_NOM)
            into tmp_int
            from PPS_NOMENCLATURE nom
               , GCO_GOOD good
           where nom.GCO_GOOD_ID = good.GCO_GOOD_ID
             and good.GOO_MAJOR_REFERENCE = tdata.GOO_MAJOR_REFERENCE
             and nom.C_TYPE_NOM = tdata.C_TYPE_NOM;

          if tmp_int = 0 then
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_C_TYPE_NOM') );
          end if;
        end if;

--********************************************************************************
--Est-ce que la condition de fabrication existe dans le dictionnaire ?
--********************************************************************************
        if (tdata.DIC_FAB_CONDITION_ID is not null) then
          IMP_PRC_TOOLS.checkDicoValue('DIC_FAB_CONDITION', tdata.DIC_FAB_CONDITION_ID, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
-- Ctrl si valeur cohérente : Montant - CSU_AMOUNT
--*******************************************************
        if (tdata.CSU_AMOUNT is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CSU_AMOUNT', tdata.CSU_AMOUNT, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
-- Ctrl si valeur cohérente : Quantité économique - CSU_ECONOMICAL_QUANTITY
--*******************************************************
        if (tdata.CSU_ECONOMICAL_QUANTITY is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CSU_ECONOMICAL_QUANTITY', tdata.CSU_ECONOMICAL_QUANTITY, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
-- Ctrl si valeur cohérente : Délai fixe - CSU_FIXED_DELAY
--*******************************************************
        if (tdata.CSU_FIXED_DELAY is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CSU_FIXED_DELAY', tdata.CSU_FIXED_DELAY, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
-- Ctrl si valeur cohérente : Décalage - CSU_SHIFT
--*******************************************************
        if (tdata.CSU_SHIFT is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CSU_SHIFT', tdata.CSU_SHIFT, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
-- Ctrl si valeur cohérente : Durée de sous traitance - CSU_SUBCONTRACTING_DELAY
--*******************************************************
        if (tdata.CSU_SUBCONTRACTING_DELAY is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CSU_SUBCONTRACTING_DELAY', tdata.CSU_SUBCONTRACTING_DELAY, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
-- Ctrl si valeur cohérente : Durée de sécurité - CSU_SECURITY_DELAY
--*******************************************************
        if (tdata.CSU_SECURITY_DELAY is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CSU_SECURITY_DELAY', tdata.CSU_SECURITY_DELAY, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

        /********************************************************
        * --> Est-ce que la quantité économique est correcte ?
        ********************************************************/
        if (tdata.CSU_ECONOMICAL_QUANTITY is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CSU_ECONOMICAL_QUANTITY', tdata.CSU_ECONOMICAL_QUANTITY, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
-- Ctrl si valeur cohérente : Quantité Standard - CSU_LOT_QUANTITY
--*******************************************************
        if (tdata.CSU_LOT_QUANTITY is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CSU_LOT_QUANTITY', tdata.CSU_LOT_QUANTITY, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
-- Ctrl si valeur cohérente : Pourcentage de rebut - CSU_PERCENT_TRASH
--*******************************************************
        if (tdata.CSU_PERCENT_TRASH is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CSU_PERCENT_TRASH', tdata.CSU_PERCENT_TRASH, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
-- Ctrl si valeur cohérente : Quantité fixe de rebut - CSU_FIXED_QUANTITY_TRASH
--*******************************************************
        if (tdata.CSU_FIXED_QUANTITY_TRASH is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CSU_FIXED_QUANTITY_TRASH', tdata.CSU_FIXED_QUANTITY_TRASH, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

--*******************************************************
-- Ctrl si valeur cohérente : Quantité de référence rebut - CSU_QTY_REFERENCE_TRASH
--*******************************************************
        if (tdata.CSU_QTY_REFERENCE_TRASH is not null) then
          IMP_PRC_TOOLS.checkNumberValue(lvTableName, 'CSU_QTY_REFERENCE_TRASH', tdata.CSU_QTY_REFERENCE_TRASH, lcDomain, tdata.id, tdata.EXCEL_LINE, true);
        end if;
      end if;
    end loop;

    --Si la table d'erreurs est vide, alors on insère le message repris par le pilotage de contrôle disant qu'il n'y a pas d'erreur
    IMP_PRC_TOOLS.checkErrors(lcDomain);
    commit;
  end IMP_GCO_SUBCONTRACT_CTRL;

  /**
  * Description
  *    Importation des données complémentaires de sous-traitance
  */
  procedure IMP_GCO_SUBCONTRACT_IMPORT
  is
    tmp     integer;
    lGoodID GCO_GOOD.GCO_GOOD_ID%type;
    ltGood  FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    --Contrôle que la table d'erreurs soit vide
    IMP_PRC_TOOLS.checkErrorsBeforeImport(lcDomain);

    --Parcours de toutes les lignes à insérer
    for tdata in (select *
                    from IMP_GCO_SUBCONTRACT_) loop
      -- Récupération ID du bien
      lGoodID  := FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', tdata.GOO_MAJOR_REFERENCE);

      --Insertion des données dans les tables !
      insert into GCO_COMPL_DATA_SUBCONTRACT
                  (GCO_COMPL_DATA_SUBCONTRACT_ID
                 , GCO_GOOD_ID
                 , A_DATECRE
                 , A_IDCRE
                 , PAC_SUPPLIER_PARTNER_ID
                 , DIC_UNIT_OF_MEASURE_ID
                 , CDA_NUMBER_OF_DECIMAL
                 , DIC_FAB_CONDITION_ID
                 , CSU_DEFAULT_SUBCONTRACTER
                 , CSU_VALIDITY_DATE
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , PPS_NOMENCLATURE_ID
                 , C_DISCHARGE_COM
                 , CSU_PLAN_NUMBER
                 , CSU_PLAN_VERSION
                 , PPS_OPERATION_PROCEDURE_ID
                 , C_GOOD_LITIG
                 , CSU_WEIGH
                 , CSU_WEIGH_MANDATORY
                 , GCO_GCO_GOOD_ID
                 , CSU_AMOUNT
                 , C_QTY_SUPPLY_RULE
                 , CSU_ECONOMICAL_QUANTITY
                 , C_ECONOMIC_CODE
                 , C_TIME_SUPPLY_RULE
                 , CSU_FIXED_DELAY
                 , CSU_SHIFT
                 , CSU_SUBCONTRACTING_DELAY
                 , CSU_SECURITY_DELAY
                 , CSU_LOT_QUANTITY
                 , CSU_FIX_DELAY
                 , CSU_PERCENT_TRASH
                 , CSU_FIXED_QUANTITY_TRASH
                 , CSU_QTY_REFERENCE_TRASH
                  )
           values (GetNewId
                 , lGoodID
                 , sysdate   -- A_DATECRE
                 , IMP_LIB_TOOLS.getImportUserIni   -- A_IDCRE
                 , FWK_I_LIB_ENTITY.getIdfromPk2('PAC_PERSON', 'PER_KEY2', tdata.PER_KEY2)
                 , (select DIC_UNIT_OF_MEASURE_ID
                      from GCO_GOOD
                     where GOO_MAJOR_REFERENCE = tdata.GOO_MAJOR_REFERENCE)   -- DIC_UNIT_OF_MEASURE_ID
                 , (select GOO_NUMBER_OF_DECIMAL
                      from GCO_GOOD
                     where GOO_MAJOR_REFERENCE = tdata.GOO_MAJOR_REFERENCE)   -- CDA_NUMBER_OF_DECIMAL
                 , tdata.DIC_FAB_CONDITION_ID
                 , tdata.CSU_DEFAULT_SUBCONTRACTER
                 , to_date(tdata.CSU_VALIDITY_DATE, 'DD.MM.YYYY')   -- CSU_VALIDITY_DATE
                 , FWK_I_LIB_ENTITY.getIdfromPk2('STM_STOCK', 'STO_DESCRIPTION', tdata.STO_DESCRIPTION)
                 , IMP_LIB_TOOLS.getLocationId(tdata.STO_DESCRIPTION, tdata.LOC_DESCRIPTION)
                 , (case
                      when tdata.C_TYPE_NOM is null then null
                      else (select max(PPS_NOMENCLATURE_ID)
                              from (select   NOM_DEFAULT
                                           , PPS_NOMENCLATURE_ID
                                        from GCO_GOOD GOO
                                           , PPS_NOMENCLATURE NOM
                                       where GOO_MAJOR_REFERENCE = tdata.GOO_MAJOR_REFERENCE
                                         and GOO.GCO_GOOD_ID = NOM.GCO_GOOD_ID
                                         and NOM.C_TYPE_NOM = tdata.C_TYPE_NOM
                                    order by NOM.NOM_DEFAULT desc)
                             where rownum = 1)
                    end
                   )   -- PPS_NOMENCLATURE_ID
                 , tdata.C_DISCHARGE_COM
                 , tdata.CSU_PLAN_NUMBER
                 , tdata.CSU_PLAN_VERSION
                 , FWK_I_LIB_ENTITY.getIdfromPk2('PPS_OPERATION_PROCEDURE', 'OPP_REFERENCE', tdata.OPP_DESCRIBE)
                 , tdata.C_GOOD_LITIG
                 , nvl(tdata.CSU_WEIGH, 0)
                 , nvl(tdata.CSU_WEIGH_MANDATORY, 0)
                 , FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', tdata.SRV_MAJOR_REFERENCE)
                 , tdata.CSU_AMOUNT
                 , tdata.C_QTY_SUPPLY_RULE
                 , tdata.CSU_ECONOMICAL_QUANTITY
                 , tdata.C_ECONOMIC_CODE
                 , tdata.C_TIME_SUPPLY_RULE
                 , tdata.CSU_FIXED_DELAY
                 , tdata.CSU_SHIFT
                 , tdata.CSU_SUBCONTRACTING_DELAY
                 , tdata.CSU_SECURITY_DELAY
                 , tdata.CSU_LOT_QUANTITY
                 , nvl(tdata.CSU_FIX_DELAY, 1)
                 , tdata.CSU_PERCENT_TRASH
                 , tdata.CSU_FIXED_QUANTITY_TRASH
                 , tdata.CSU_QTY_REFERENCE_TRASH
                  );

      -- màj du flag sur le bien
      -- Création de l'entité GCO_GOOD
      FWK_I_MGT_ENTITY.new(FWK_TYP_GCO_ENTITY.gcGcoGood, ltGood);
      -- Init de l'id du bien
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGood, 'GCO_GOOD_ID', lGoodID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGood, 'GCO_DATA_SUBCONTRACT', 1);
      FWK_I_MGT_ENTITY.UpdateEntity(ltGood);
      FWK_I_MGT_ENTITY.Release(ltGood);

      --Insertion des données dans les tables !
      insert into IMP_HIST_GCO_SUBCONTRACT
                  (ID_HIST
                 , DATE_HIST
                 , EXCEL_LINE
                 , GOO_MAJOR_REFERENCE
                 , PER_KEY2
                 , DIC_FAB_CONDITION_ID
                 , CSU_DEFAULT_SUBCONTRACTER
                 , CSU_VALIDITY_DATE
                 , STO_DESCRIPTION
                 , LOC_DESCRIPTION
                 , C_TYPE_NOM
                 , C_DISCHARGE_COM
                 , CSU_PLAN_NUMBER
                 , CSU_PLAN_VERSION
                 , OPP_DESCRIBE
                 , C_GOOD_LITIG
                 , CSU_WEIGH
                 , CSU_WEIGH_MANDATORY
                 , SRV_MAJOR_REFERENCE
                 , CSU_AMOUNT
                 , C_QTY_SUPPLY_RULE
                 , CSU_ECONOMICAL_QUANTITY
                 , C_ECONOMIC_CODE
                 , C_TIME_SUPPLY_RULE
                 , CSU_FIXED_DELAY
                 , CSU_SHIFT
                 , CSU_SUBCONTRACTING_DELAY
                 , CSU_SECURITY_DELAY
                 , CSU_LOT_QUANTITY
                 , CSU_FIX_DELAY
                 , CSU_PERCENT_TRASH
                 , CSU_FIXED_QUANTITY_TRASH
                 , CSU_QTY_REFERENCE_TRASH
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
                 , tdata.PER_KEY2
                 , tdata.DIC_FAB_CONDITION_ID
                 , tdata.CSU_DEFAULT_SUBCONTRACTER
                 , tdata.CSU_VALIDITY_DATE
                 , tdata.STO_DESCRIPTION
                 , tdata.LOC_DESCRIPTION
                 , tdata.C_TYPE_NOM
                 , tdata.C_DISCHARGE_COM
                 , tdata.CSU_PLAN_NUMBER
                 , tdata.CSU_PLAN_VERSION
                 , tdata.OPP_DESCRIBE
                 , tdata.C_GOOD_LITIG
                 , nvl(tdata.CSU_WEIGH, 0)
                 , nvl(tdata.CSU_WEIGH_MANDATORY, 0)
                 , tdata.SRV_MAJOR_REFERENCE
                 , tdata.CSU_AMOUNT
                 , tdata.C_QTY_SUPPLY_RULE
                 , tdata.CSU_ECONOMICAL_QUANTITY
                 , tdata.C_ECONOMIC_CODE
                 , tdata.C_TIME_SUPPLY_RULE
                 , tdata.CSU_FIXED_DELAY
                 , tdata.CSU_SHIFT
                 , tdata.CSU_SUBCONTRACTING_DELAY
                 , tdata.CSU_SECURITY_DELAY
                 , tdata.CSU_LOT_QUANTITY
                 , nvl(tdata.CSU_FIX_DELAY, 1)
                 , tdata.CSU_PERCENT_TRASH
                 , tdata.CSU_FIXED_QUANTITY_TRASH
                 , tdata.CSU_QTY_REFERENCE_TRASH
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
  end IMP_GCO_SUBCONTRACT_IMPORT;
end IMP_GCO_SUBCONTRACT;
