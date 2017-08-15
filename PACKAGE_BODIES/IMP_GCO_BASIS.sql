--------------------------------------------------------
--  DDL for Package Body IMP_GCO_BASIS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IMP_GCO_BASIS" 
as
  lcDomain constant varchar2(15) := 'GCO';

  /**
  * Description
  *    importation des données d'Excel dans la table temporaire IMP_GCO_GOOD. Cette procédure est appelée depuis Excel
  */
  procedure IMP_TMP_GCO_GOOD(
    pC_GOOD_STATUS                  varchar2
  , pGCO_GOOD_CATEGORY_WORDING      varchar2
  , pGOO_MAJOR_REFERENCE            varchar2
  , pGOO_SECONDARY_REFERENCE        varchar2
  , pC_MANAGEMENT_MODE              varchar2
  , pDIC_UNIT_OF_MEASURE_ID         varchar2
  , pGOO_NUMBER_OF_DECIMAL          varchar2
  , pDES_SHORT_DESCRIPTION_L1       varchar2
  , pDES_LONG_DESCRIPTION_L1        varchar2
  , pDES_FREE_DESCRIPTION_L1        varchar2
  , pDES_SHORT_DESCRIPTION_L2       varchar2
  , pDES_LONG_DESCRIPTION_L2        varchar2
  , pDES_FREE_DESCRIPTION_L2        varchar2
  , pDES_SHORT_DESCRIPTION_L3       varchar2
  , pDES_LONG_DESCRIPTION_L3        varchar2
  , pDES_FREE_DESCRIPTION_L3        varchar2
  , pGOO_EAN_CODE                   varchar2
  , pDIC_GOOD_LINE_ID               varchar2
  , pDIC_GOOD_FAMILY_ID             varchar2
  , pDIC_GOOD_GROUP_ID              varchar2
  , pDIC_GOOD_MODEL_ID              varchar2
  , pDIC_ACCOUNTABLE_GROUP_ID       varchar2
  , pPRG_NAME                       varchar2
  , pGCO_TYPE                       varchar2
  , pGOO_WEB_CAN_BE_ORDERED         integer
  , pGOO_WEB_VISUAL_LEVEL           number
  , pGOO_WEB_ORDERABILITY_LEVEL     number
  , pFREE1                          varchar2
  , pFREE2                          varchar2
  , pFREE3                          varchar2
  , pFREE4                          varchar2
  , pFREE5                          varchar2
  , pFREE6                          varchar2
  , pFREE7                          varchar2
  , pFREE8                          varchar2
  , pFREE9                          varchar2
  , pFREE10                         varchar2
  , pFREE11                         varchar2
  , pFREE12                         varchar2
  , pFREE13                         varchar2
  , pFREE14                         varchar2
  , pFREE15                         varchar2
  , pFREE16                         varchar2
  , pFREE17                         varchar2
  , pFREE18                         varchar2
  , pFREE19                         varchar2
  , pFREE20                         varchar2
  , pFREE21                         varchar2
  , pFREE22                         varchar2
  , pFREE23                         varchar2
  , pFREE24                         varchar2
  , pFREE25                         varchar2
  , pFREE26                         varchar2
  , pFREE27                         varchar2
  , pFREE28                         varchar2
  , pFREE29                         varchar2
  , pFREE30                         varchar2
  , pEXCEL_LINE                     integer
  , pRESULT                     out integer
  )
  is
  begin
    --Insertion dans la table IMP_GCO_GOOD
    insert into IMP_GCO_GOOD
                (id
               , EXCEL_LINE
               , GCO_GOOD_ID
               , C_GOOD_STATUS
               , GCO_GOOD_CATEGORY_WORDING
               , GOO_MAJOR_REFERENCE
               , GOO_SECONDARY_REFERENCE
               , C_MANAGEMENT_MODE
               , DIC_UNIT_OF_MEASURE_ID
               , GOO_NUMBER_OF_DECIMAL
               , DES_SHORT_DESCRIPTION_L1
               , DES_LONG_DESCRIPTION_L1
               , DES_FREE_DESCRIPTION_L1
               , DES_SHORT_DESCRIPTION_L2
               , DES_LONG_DESCRIPTION_L2
               , DES_FREE_DESCRIPTION_L2
               , DES_SHORT_DESCRIPTION_L3
               , DES_LONG_DESCRIPTION_L3
               , DES_FREE_DESCRIPTION_L3
               , GOO_EAN_CODE
               , DIC_GOOD_LINE_ID
               , DIC_GOOD_FAMILY_ID
               , DIC_GOOD_GROUP_ID
               , DIC_GOOD_MODEL_ID
               , DIC_ACCOUNTABLE_GROUP_ID
               , PRG_NAME
               , GCO_TYPE
               , GOO_WEB_CAN_BE_ORDERED
               , GOO_WEB_VISUAL_LEVEL
               , GOO_WEB_ORDERABILITY_LEVEL
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
               , FREE11
               , FREE12
               , FREE13
               , FREE14
               , FREE15
               , FREE16
               , FREE17
               , FREE18
               , FREE19
               , FREE20
               , FREE21
               , FREE22
               , FREE23
               , FREE24
               , FREE25
               , FREE26
               , FREE27
               , FREE28
               , FREE29
               , FREE30
               , A_DATECRE
               , A_IDCRE
                )
         values (GetNewId
               , pEXCEL_LINE
               , GetNewId
               , trim(pC_GOOD_STATUS)
               , trim(pGCO_GOOD_CATEGORY_WORDING)
               , trim(pGOO_MAJOR_REFERENCE)
               , trim(pGOO_SECONDARY_REFERENCE)
               , trim(pC_MANAGEMENT_MODE)
               , trim(pDIC_UNIT_OF_MEASURE_ID)
               , trim(pGOO_NUMBER_OF_DECIMAL)
               , trim(pDES_SHORT_DESCRIPTION_L1)
               , trim(pDES_LONG_DESCRIPTION_L1)
               , trim(pDES_FREE_DESCRIPTION_L1)
               , trim(pDES_SHORT_DESCRIPTION_L2)
               , trim(pDES_LONG_DESCRIPTION_L2)
               , trim(pDES_FREE_DESCRIPTION_L2)
               , trim(pDES_SHORT_DESCRIPTION_L3)
               , trim(pDES_LONG_DESCRIPTION_L3)
               , trim(pDES_FREE_DESCRIPTION_L3)
               , trim(pGOO_EAN_CODE)
               , trim(pDIC_GOOD_LINE_ID)
               , trim(pDIC_GOOD_FAMILY_ID)
               , trim(pDIC_GOOD_GROUP_ID)
               , trim(pDIC_GOOD_MODEL_ID)
               , trim(pDIC_ACCOUNTABLE_GROUP_ID)
               , trim(pPRG_NAME)
               , nvl(trim(pGCO_TYPE), '0')
               , trim(pGOO_WEB_CAN_BE_ORDERED)
               , trim(pGOO_WEB_VISUAL_LEVEL)
               , trim(pGOO_WEB_ORDERABILITY_LEVEL)
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
               , trim(pFREE11)
               , trim(pFREE12)
               , trim(pFREE13)
               , trim(pFREE14)
               , trim(pFREE15)
               , trim(pFREE16)
               , trim(pFREE17)
               , trim(pFREE18)
               , trim(pFREE19)
               , trim(pFREE20)
               , trim(pFREE21)
               , trim(pFREE22)
               , trim(pFREE23)
               , trim(pFREE24)
               , trim(pFREE25)
               , trim(pFREE26)
               , trim(pFREE27)
               , trim(pFREE28)
               , trim(pFREE29)
               , trim(pFREE30)
               , sysdate
               , IMP_LIB_TOOLS.getImportUserIni
                );

    --Nombre de ligne insérées
    pResult  := 1;
    commit;
  end IMP_TMP_GCO_GOOD;

  /**
  * Description
  *    importation des données d'Excel dans la table temporaire IMP_GCO_PRODUCT. Cette procédure est appelée depuis Excel
  */
  procedure IMP_TMP_GCO_PRODUCT(
    pGOO_MAJOR_REFERENCE          varchar2
  , pC_SUPPLY_MODE                varchar2
  , pPDT_STOCK_MANAGEMENT         varchar2
  , pC_SUPPLY_TYPE                varchar2
  , pPDT_CALC_REQUIREMENT_MNGMENT varchar2
  , pSTO_DESCRIPTION              varchar2
  , pLOC_DESCRIPTION              varchar2
  , pPDT_PIC                      varchar2
  , pPDT_CONTINUOUS_INVENTAR      varchar2
  , pPDT_STOCK_OBTAIN_MANAGEMENT  varchar2
  , pPDT_FULL_TRACABILITY         varchar2
  , pPDT_GUARANTY_USE             varchar2
  , pEXCEL_LINE                   integer
  )
  is
  begin
    --Insertion dans la table IMP_GCO_PRODUCT
    insert into IMP_GCO_PRODUCT
                (id
               , EXCEL_LINE
               , GCO_GOOD_ID
               , GOO_MAJOR_REFERENCE
               , C_SUPPLY_MODE
               , C_SUPPLY_TYPE
               , PDT_STOCK_MANAGEMENT
               , PDT_CALC_REQUIREMENT_MNGMENT
               , STO_DESCRIPTION
               , LOC_DESCRIPTION
               , PDT_PIC
               , PDT_CONTINUOUS_INVENTAR
               , PDT_STOCK_OBTAIN_MANAGEMENT
               , PDT_FULL_TRACABILITY
               , PDT_GUARANTY_USE
               , A_DATECRE
               , A_IDCRE
                )
         values (GetNewId
               , pEXCEL_LINE
               , (select nvl( (select max(GCO_GOOD_ID)
                                 from IMP_GCO_GOOD
                                where GOO_MAJOR_REFERENCE = trim(pGOO_MAJOR_REFERENCE) ), 0)
                    from dual)
               , trim(pGOO_MAJOR_REFERENCE)
               , trim(pC_SUPPLY_MODE)
               , trim(pC_SUPPLY_TYPE)
               , trim(pPDT_STOCK_MANAGEMENT)
               , trim(pPDT_CALC_REQUIREMENT_MNGMENT)
               , trim(pSTO_DESCRIPTION)
               , trim(pLOC_DESCRIPTION)
               , trim(pPDT_PIC)
               , trim(pPDT_CONTINUOUS_INVENTAR)
               , trim(pPDT_STOCK_OBTAIN_MANAGEMENT)
               , trim(pPDT_FULL_TRACABILITY)
               , trim(pPDT_GUARANTY_USE)
               , sysdate
               , IMP_LIB_TOOLS.getImportUserIni
                );

    commit;
  end IMP_TMP_GCO_PRODUCT;

  /**
  * Description
  *    Contrôle des données de la table IMP_GCO_GOOD avant importation.
  */
  procedure IMP_GCO_GOOD_CTRL
  is
    tmp     varchar2(200);
    tmp_int integer;
  begin
    --Effacement des tables d'erreurs
    IMP_PRC_TOOLS.deleteErrors(lcDomain);
    --Contrôle de l'existence des langues 'FR', 'GE' et 'EN' dans l'ERP
    IMP_PRC_TOOLS.checkLanguage('FR', lcDomain, 0, '-');
    IMP_PRC_TOOLS.checkLanguage('GE', lcDomain, 0, '-');
    IMP_PRC_TOOLS.checkLanguage('EN', lcDomain, 0, '-');

    --Parcours de toutes les lignes de la table IMP_GCO_GOOD
    for tdata in (select *
                    from IMP_GCO_GOOD) loop
      --> Est-ce que tous les champs obligatoires sont présents ?
      if (   tdata.GOO_MAJOR_REFERENCE is null
          or tdata.GCO_GOOD_CATEGORY_WORDING is null
          or tdata.DES_SHORT_DESCRIPTION_L1 is null
          or tdata.C_MANAGEMENT_MODE is null
          or tdata.DIC_UNIT_OF_MEASURE_ID is null
          or tdata.GOO_NUMBER_OF_DECIMAL is null
          or tdata.C_GOOD_STATUS is null
         ) then
        IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_REQUIRED') );
      else
        /***** Contrôle des boolean *****/
        /***** Contrôle des descode *****/
        --> Mode de gestion
        IMP_PRC_TOOLS.checkDescodeValue('C_MANAGEMENT_MODE', tdata.C_MANAGEMENT_MODE, '{1,2,3}', lcDomain, tdata.id, tdata.EXCEL_LINE);
        --> Statut
        IMP_PRC_TOOLS.checkDescodeValue('C_GOOD_STATUS', tdata.C_GOOD_STATUS, '{1,2,3}', lcDomain, tdata.id, tdata.EXCEL_LINE);
        --> Nombre de décimales
        IMP_PRC_TOOLS.checkDescodeValue('GOO_NUMBER_OF_DECIMAL', tdata.GOO_NUMBER_OF_DECIMAL, '{0,1,2,3,4}', lcDomain, tdata.id, tdata.EXCEL_LINE);
        --> Type de produit
        IMP_PRC_TOOLS.checkDescodeValue('GCO_TYPE', tdata.GCO_TYPE, '{0,1,2}', lcDomain, tdata.id, tdata.EXCEL_LINE);
        /***** Contrôle des dico *****/
        --> Unité de mesure
        IMP_PRC_TOOLS.checkDicoValue('DIC_UNIT_OF_MEASURE', tdata.DIC_UNIT_OF_MEASURE_ID, lcDomain, tdata.id, tdata.EXCEL_LINE);

        --> Ligne de bien
        if (tdata.DIC_GOOD_LINE_ID is not null) then
          IMP_PRC_TOOLS.checkDicoValue('DIC_GOOD_LINE', tdata.DIC_GOOD_LINE_ID, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

        -- Famille de bien
        if (tdata.DIC_GOOD_FAMILY_ID is not null) then
          IMP_PRC_TOOLS.checkDicoValue('DIC_GOOD_FAMILY', tdata.DIC_GOOD_FAMILY_ID, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

        --> Groupe de bien
        if (tdata.DIC_GOOD_GROUP_ID is not null) then
          IMP_PRC_TOOLS.checkDicoValue('DIC_GOOD_GROUP', tdata.DIC_GOOD_GROUP_ID, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

        --> Modèle de bien
        if (tdata.DIC_GOOD_MODEL_ID is not null) then
          IMP_PRC_TOOLS.checkDicoValue('DIC_GOOD_MODEL', tdata.DIC_GOOD_MODEL_ID, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

        --> Groupe de responsables
        if (tdata.DIC_ACCOUNTABLE_GROUP_ID is not null) then
          IMP_PRC_TOOLS.checkDicoValue('DIC_ACCOUNTABLE_GROUP', tdata.DIC_ACCOUNTABLE_GROUP_ID, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

        /***** Contrôle des valeurs numériques *****/
        --> Niveau autorisant l'affichage (Web)
        if (tdata.GOO_WEB_VISUAL_LEVEL is not null) then
          IMP_PRC_TOOLS.checkNumberValue('GCO_GOOD', 'GOO_WEB_VISUAL_LEVEL', tdata.GOO_WEB_VISUAL_LEVEL, lcDomain, tdata.id, tdata.EXCEL_LINE, true);
        end if;

        --> Niveau autorisant la commande (Web)
        if (tdata.GOO_WEB_ORDERABILITY_LEVEL is not null) then
          IMP_PRC_TOOLS.checkNumberValue('GCO_GOOD', 'GOO_WEB_ORDERABILITY_LEVEL', tdata.GOO_WEB_ORDERABILITY_LEVEL, lcDomain, tdata.id, tdata.EXCEL_LINE
                                       , true);
        end if;

        /***** Contrôles métiers *****/
        /*******************************************************
        * --> Est-ce que la référence principale est unique ?
        ********************************************************/
        -- Contrôle de l'unicité dans les données en provenance du fichier Excel
        select count(goo_major_reference)
          into tmp_int
          from IMP_GCO_GOOD
         where GOO_MAJOR_REFERENCE = tdata.GOO_MAJOR_REFERENCE;

        -- S'il n'est pas unique, création d'une erreur
        if (tmp_int > 1) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_GOO_MAJOR_REFERENCE_2') );
        else
          -- Sinon contrôle de l'unicité dans l'ERP
          select count(GCO_GOOD_ID)
            into tmp_int
            from GCO_GOOD
           where GOO_MAJOR_REFERENCE = tdata.GOO_MAJOR_REFERENCE;

          if tmp_int > 0 then
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_GOO_MAJOR_REFERENCE_3') );
          end if;
        end if;

        /*******************************************************
        * --> Est-ce que le code EAN est unique ?
        ********************************************************/
        -- Contrôle de l'unicité dans les données en provenance du fichier Excel
        select count(GOO_EAN_CODE)
          into tmp_int
          from IMP_GCO_GOOD
         where GOO_EAN_CODE = tdata.GOO_EAN_CODE;

        -- S'il n'est pas unique, création d'une erreur
        if tmp_int > 1 then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_GOO_EAN_CODE_1') );
        else
          -- Sinon contrôle de l'unicité dans l'ERP
          select count(GOO_EAN_CODE)
            into tmp_int
            from GCO_GOOD
           where GOO_EAN_CODE = tdata.GOO_EAN_CODE;

          if tmp_int > 0 then
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_GOO_EAN_CODE_2') );
          end if;
        end if;

        /********************************************************
        * --> Est-ce que la catégorie existe ?
        ********************************************************/
        begin
          select GCO_GOOD_CATEGORY_WORDING
            into tmp
            from GCO_GOOD_CATEGORY
           where GCO_GOOD_CATEGORY_WORDING = tdata.GCO_GOOD_CATEGORY_WORDING;
        exception
          when no_data_found then
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_GCO_GOOD_CATEGORY') );
        end;

        /********************************************************
        * --> Est-ce que le groupe de produit existe ?
        ********************************************************/
        if (tdata.PRG_NAME is not null) then
          begin
            --Récupération du nom du groupe de produit
            select PRG_NAME
              into tmp
              from GCO_PRODUCT_GROUP
             where PRG_NAME = tdata.PRG_NAME;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain
                                      , tdata.id
                                      , tdata.EXCEL_LINE
                                      , pcs.pc_functions.TranslateWord('IMP_GCO_PRODUCT_GROUP') ||
                                        ' ' ||
                                        tdata.PRG_NAME ||
                                        ' ' ||
                                        pcs.pc_functions.TranslateWord('IMP_INEXISTANT')
                                       );
          end;
        end if;
      end if;
    end loop;

    --Appel de la procédure de contrôle des champs relatifs à la table IMP_GCO_PRODUCT
    IMP_GCO_PRODUCT_CTRL;
    --Si la table d'erreurs est vide, alors on insère le message repris par le pilotage de contrôle disant qu'il n'y a pas d'erreur
    IMP_PRC_TOOLS.checkErrors(lcDomain);
    commit;
  end IMP_GCO_GOOD_CTRL;

  /**
  * Description
  *    Contrôle des données de la table IMP_GCO_PRODUCT avant importation.
  */
  procedure IMP_GCO_PRODUCT_CTRL
  is
  begin
    --Parcours de toutes les lignes de la table IMP_GCO_PRODCUT
    for tdata in (select *
                    from IMP_GCO_PRODUCT) loop
      --> Est-ce que tous les champs obligatoires sont présents ?
      if (   tdata.GOO_MAJOR_REFERENCE is null
          or tdata.C_SUPPLY_MODE is null) then
        IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_REQUIRED') );
      else
        /***** Contrôle des boolean *****/
        --> CB
        IMP_PRC_TOOLS.checkBooleanValue('PDT_CALC_REQUIREMENT_MNGMENT', nvl(tdata.PDT_CALC_REQUIREMENT_MNGMENT, '1'), lcDomain, tdata.id, tdata.EXCEL_LINE);
        --> PIC
        IMP_PRC_TOOLS.checkBooleanValue('PDT_PIC', nvl(tdata.PDT_PIC, '0'), lcDomain, tdata.id, tdata.EXCEL_LINE);
        --> Inventaire permanent
        IMP_PRC_TOOLS.checkBooleanValue('PDT_CONTINUOUS_INVENTAR', nvl(tdata.PDT_CONTINUOUS_INVENTAR, '0'), lcDomain, tdata.id, tdata.EXCEL_LINE);
        --> Tracabilité complète
        IMP_PRC_TOOLS.checkBooleanValue('PDT_FULL_TRACABILITY', nvl(tdata.PDT_FULL_TRACABILITY, '0'), lcDomain, tdata.id, tdata.EXCEL_LINE);
        --> Stock d'obtention
        IMP_PRC_TOOLS.checkBooleanValue('PDT_STOCK_OBTAIN_MANAGEMENT', nvl(tdata.PDT_STOCK_OBTAIN_MANAGEMENT, '0'), lcDomain, tdata.id, tdata.EXCEL_LINE);
        --> Carte de garantie
        IMP_PRC_TOOLS.checkBooleanValue('PDT_GUARANTY_USE', nvl(tdata.PDT_GUARANTY_USE, '0'), lcDomain, tdata.id, tdata.EXCEL_LINE);
        /***** Contrôle des descode *****/
        --> Mode d'approvisionnement
        IMP_PRC_TOOLS.checkDescodeValue('C_SUPPLY_MODE', tdata.C_SUPPLY_MODE, '{1,2,3,4}', lcDomain, tdata.id, tdata.EXCEL_LINE);
        --> Type d'approvisionnement
        IMP_PRC_TOOLS.checkDescodeValue('C_SUPPLY_TYPE', nvl(tdata.C_SUPPLY_TYPE, '1'), '{1,2}', lcDomain, tdata.id, tdata.EXCEL_LINE);
        --> Gestion stock
        IMP_PRC_TOOLS.checkDescodeValue('PDT_STOCK_MANAGEMENT', nvl(tdata.PDT_STOCK_MANAGEMENT, '1'), '{0,1,2}', lcDomain, tdata.id, tdata.EXCEL_LINE);

        /***** Contrôle des dico *****/
        /***** Contrôle des valeurs numériques *****/
        /***** Contrôles métiers *****/
        /********************************************************
        * --> Est-ce qu'on spécifie des stocks et en même temps le bouléen sans gestion de stock ?
        ********************************************************/
        if (    tdata.PDT_STOCK_MANAGEMENT = '0'
            and tdata.STO_DESCRIPTION is not null) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_PDT_STOCK_MANAGEMENT2') );
        end if;

        /********************************************************
        * --> Est-ce que le stock logique et l'emplacement existent et sont cohérents  ?
        ********************************************************/
        if    (tdata.STO_DESCRIPTION is not null)
           or (tdata.LOC_DESCRIPTION is not null) then
          IMP_PRC_TOOLS.checkStockAndLocataion(tdata.STO_DESCRIPTION, tdata.LOC_DESCRIPTION, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

        /********************************************************
        * --> Est-ce qu'il y a des produits assemblés sur tâche et gérés PIC ?
        ********************************************************/
        if     tdata.C_SUPPLY_MODE = '3'
           and tdata.PDT_PIC = '1' then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_PDT_PIC_2') );
        end if;
      end if;
    end loop;
  end IMP_GCO_PRODUCT_CTRL;

  /**
  * Description
  *    Importation des données biens
  */
  procedure IMP_GCO_GOOD_IMPORT
  is
    tmp integer;
    L1  varchar2(10);
    L2  varchar2(10);
    L3  varchar2(10);
  begin
    --Contrôle que la table d'erreurs soit vide
    IMP_PRC_TOOLS.checkErrorsBeforeImport(lcDomain);

    --Parcours de toutes les lignes à insérer
    for tdata in (select *
                    from IMP_GCO_GOOD) loop
      --Insertion des données dans les tables !
      insert into GCO_GOOD
                  (GCO_GOOD_ID
                 , C_GOOD_STATUS
                 , DIC_UNIT_OF_MEASURE_ID
                 , GCO_GOOD_CATEGORY_ID
                 , C_MANAGEMENT_MODE
                 , GOO_MAJOR_REFERENCE
                 , GOO_SECONDARY_REFERENCE
                 , GOO_NUMBER_OF_DECIMAL
                 , GOO_EAN_CODE
                 , DIC_GOOD_LINE_ID
                 , DIC_GOOD_FAMILY_ID
                 , DIC_GOOD_GROUP_ID
                 , DIC_GOOD_MODEL_ID
                 , DIC_ACCOUNTABLE_GROUP_ID
                 , GCO_PRODUCT_GROUP_ID
                 , GOO_WEB_CAN_BE_ORDERED
                 , GOO_WEB_VISUAL_LEVEL
                 , GOO_WEB_ORDERABILITY_LEVEL
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (tdata.gco_good_id
                 , tdata.c_good_status
                 , tdata.dic_unit_of_measure_id
                 , (select gco_good_category_id
                      from gco_good_category
                     where gco_good_category_wording like tdata.gco_good_category_wording)
                 , (select case
                             when tdata.GCO_TYPE = '0' then tdata.C_MANAGEMENT_MODE
                             else '3'   --(PRF pour les services et les pseudos)
                           end
                      from dual)
                 , tdata.goo_major_reference
                 , tdata.goo_secondary_reference
                 , tdata.goo_number_of_decimal
                 , tdata.goo_ean_code
                 , tdata.DIC_GOOD_LINE_ID
                 , tdata.DIC_GOOD_FAMILY_ID
                 , tdata.DIC_GOOD_GROUP_ID
                 , tdata.DIC_GOOD_MODEL_ID
                 , tdata.DIC_ACCOUNTABLE_GROUP_ID
                 , (select gco_product_group_id
                      from gco_product_group
                     where prg_name = tdata.PRG_NAME)
                 , nvl(tdata.GOO_WEB_CAN_BE_ORDERED, 0)
                 , tdata.GOO_WEB_VISUAL_LEVEL
                 , tdata.GOO_WEB_ORDERABILITY_LEVEL
                 , sysdate
                 , IMP_LIB_TOOLS.getImportUserIni
                  );

      --Correspondance des langues (L1, L2, L3) entre Excel et ProConcept
      --L1 = langue de la société
      --L2 = seconde langue
      --L3 = troisième langue
      select pc_lang_id
        into L1
        from pcs.pc_comp c
           , pcs.pc_scrip s
       where c.pc_scrip_id = s.pc_scrip_id
         and s.SCRDBOWNER = (select COM_CURRENTSCHEMA
                               from dual);

      case L1
        when '1' then
          L2  := '2';
          L3  := '3';
        when '2' then
          L2  := '1';
          L3  := '3';
        when '3' then
          L2  := '1';
          L3  := '2';
      end case;

      --Insertion des descriptions langue 1 s'il y en a
      if (   tdata.des_short_description_l1 is not null
          or tdata.des_long_description_l1 is not null
          or tdata.des_free_description_l1 is not null) then
        insert into GCO_DESCRIPTION
                    (GCO_DESCRIPTION_ID
                   , GCO_GOOD_ID
                   , PC_LANG_ID
                   , GCO_MULTIMEDIA_ELEMENT_ID
                   , C_DESCRIPTION_TYPE
                   , DES_SHORT_DESCRIPTION
                   , DES_LONG_DESCRIPTION
                   , DES_FREE_DESCRIPTION
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (GetNewId
                   , tdata.gco_good_id
                   , L1
                   , null
                   , '01'
                   , tdata.DES_SHORT_DESCRIPTION_L1
                   , tdata.DES_LONG_DESCRIPTION_L1
                   , tdata.DES_FREE_DESCRIPTION_L1
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Insertion des descriptions 2 s'il y en a
      if (   tdata.des_short_description_l2 is not null
          or tdata.des_long_description_l2 is not null
          or tdata.des_free_description_l2 is not null) then
        insert into GCO_DESCRIPTION
                    (GCO_DESCRIPTION_ID
                   , GCO_GOOD_ID
                   , PC_LANG_ID
                   , GCO_MULTIMEDIA_ELEMENT_ID
                   , C_DESCRIPTION_TYPE
                   , DES_SHORT_DESCRIPTION
                   , DES_LONG_DESCRIPTION
                   , DES_FREE_DESCRIPTION
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (GetNewId
                   , tdata.gco_good_id
                   , L2
                   , null
                   , '01'
                   , tdata.DES_SHORT_DESCRIPTION_L2
                   , tdata.DES_LONG_DESCRIPTION_L2
                   , tdata.DES_FREE_DESCRIPTION_L2
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Insertion des descriptions 3 s'il y en a
      if (   tdata.des_short_description_l3 is not null
          or tdata.des_long_description_l3 is not null
          or tdata.des_free_description_l3 is not null) then
        insert into GCO_DESCRIPTION
                    (GCO_DESCRIPTION_ID
                   , GCO_GOOD_ID
                   , PC_LANG_ID
                   , GCO_MULTIMEDIA_ELEMENT_ID
                   , C_DESCRIPTION_TYPE
                   , DES_SHORT_DESCRIPTION
                   , DES_LONG_DESCRIPTION
                   , DES_FREE_DESCRIPTION
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (GetNewId
                   , tdata.gco_good_id
                   , L3
                   , null
                   , '01'
                   , tdata.DES_SHORT_DESCRIPTION_L3
                   , tdata.DES_LONG_DESCRIPTION_L3
                   , tdata.DES_FREE_DESCRIPTION_L3
                   , sysdate
                   , IMP_LIB_TOOLS.getImportUserIni
                    );
      end if;

      --Insertion dans historique
      insert into IMP_HIST_GCO_GOOD
                  (ID_HIST
                 , DATE_HIST
                 , EXCEL_LINE
                 , GCO_GOOD_ID
                 , C_GOOD_STATUS
                 , DIC_UNIT_OF_MEASURE_ID
                 , GCO_GOOD_CATEGORY_WORDING
                 , C_MANAGEMENT_MODE
                 , GOO_MAJOR_REFERENCE
                 , GOO_SECONDARY_REFERENCE
                 , GOO_NUMBER_OF_DECIMAL
                 , DES_SHORT_DESCRIPTION_L1
                 , DES_LONG_DESCRIPTION_L1
                 , DES_FREE_DESCRIPTION_L1
                 , DES_SHORT_DESCRIPTION_L2
                 , DES_LONG_DESCRIPTION_L2
                 , DES_FREE_DESCRIPTION_L2
                 , DES_SHORT_DESCRIPTION_L3
                 , DES_LONG_DESCRIPTION_L3
                 , DES_FREE_DESCRIPTION_L3
                 , GOO_EAN_CODE
                 , DIC_GOOD_LINE_ID
                 , DIC_GOOD_FAMILY_ID
                 , DIC_GOOD_GROUP_ID
                 , DIC_GOOD_MODEL_ID
                 , DIC_ACCOUNTABLE_GROUP_ID
                 , PRG_NAME
                 , GCO_TYPE
                 , GOO_WEB_CAN_BE_ORDERED
                 , GOO_WEB_VISUAL_LEVEL
                 , GOO_WEB_ORDERABILITY_LEVEL
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
                 , FREE11
                 , FREE12
                 , FREE13
                 , FREE14
                 , FREE15
                 , FREE16
                 , FREE17
                 , FREE18
                 , FREE19
                 , FREE20
                 , FREE21
                 , FREE22
                 , FREE23
                 , FREE24
                 , FREE25
                 , FREE26
                 , FREE27
                 , FREE28
                 , FREE29
                 , FREE30
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , sysdate
                 , tdata.EXCEL_LINE
                 , tdata.GCO_GOOD_ID
                 , tdata.C_GOOD_STATUS
                 , tdata.DIC_UNIT_OF_MEASURE_ID
                 , tdata.GCO_GOOD_CATEGORY_WORDING
                 , tdata.C_MANAGEMENT_MODE
                 , tdata.GOO_MAJOR_REFERENCE
                 , tdata.GOO_SECONDARY_REFERENCE
                 , tdata.GOO_NUMBER_OF_DECIMAL
                 , tdata.DES_SHORT_DESCRIPTION_L1
                 , tdata.DES_LONG_DESCRIPTION_L1
                 , tdata.DES_FREE_DESCRIPTION_L1
                 , tdata.DES_SHORT_DESCRIPTION_L2
                 , tdata.DES_LONG_DESCRIPTION_L2
                 , tdata.DES_FREE_DESCRIPTION_L2
                 , tdata.DES_SHORT_DESCRIPTION_L3
                 , tdata.DES_LONG_DESCRIPTION_L3
                 , tdata.DES_FREE_DESCRIPTION_L3
                 , tdata.GOO_EAN_CODE
                 , tdata.DIC_GOOD_LINE_ID
                 , tdata.DIC_GOOD_FAMILY_ID
                 , tdata.DIC_GOOD_GROUP_ID
                 , tdata.DIC_GOOD_MODEL_ID
                 , tdata.DIC_ACCOUNTABLE_GROUP_ID
                 , tdata.PRG_NAME
                 , tdata.GCO_TYPE
                 , tdata.GOO_WEB_CAN_BE_ORDERED
                 , tdata.GOO_WEB_VISUAL_LEVEL
                 , tdata.GOO_WEB_ORDERABILITY_LEVEL
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
                 , tdata.FREE11
                 , tdata.FREE12
                 , tdata.FREE13
                 , tdata.FREE14
                 , tdata.FREE15
                 , tdata.FREE16
                 , tdata.FREE17
                 , tdata.FREE18
                 , tdata.FREE19
                 , tdata.FREE20
                 , tdata.FREE21
                 , tdata.FREE22
                 , tdata.FREE23
                 , tdata.FREE24
                 , tdata.FREE25
                 , tdata.FREE26
                 , tdata.FREE27
                 , tdata.FREE28
                 , tdata.FREE29
                 , tdata.FREE30
                 , sysdate
                 , pcs.PC_I_LIB_SESSION.GetUserIni
                  );

      --En fonction du type de produit on insère les données produit, service ou pseudo
      case tdata.GCO_TYPE
        when '0' then   --Bien --Appel de la procédure d'importation des produits
          begin
            IMP_GCO_PRODUCT_IMPORT(tdata.gco_good_id);
          end;
        when '1' then   --Service
          insert into GCO_SERVICE
                      (GCO_GOOD_ID
                      )
               values (tdata.GCO_GOOD_ID
                      );
        --Pseudo
      when '2' then
          insert into GCO_PSEUDO_GOOD
                      (GCO_GOOD_ID
                      )
               values (tdata.GCO_GOOD_ID
                      );
      end case;
    end loop;
  end IMP_GCO_GOOD_IMPORT;

  /**
  * Description
  *    Importation des données produits
  */
  procedure IMP_GCO_PRODUCT_IMPORT(pGCO_GOOD_ID number)
  is
    tmp integer;
  begin
    --Parcours de toutes les lignes à insérer
    for tdata in (select *
                    from IMP_GCO_PRODUCT
                   where gco_good_id = pGCO_GOOD_ID) loop
      --Insertion des données dans la table des produits
      insert into GCO_PRODUCT
                  (GCO_GOOD_ID
                 , C_SUPPLY_MODE
                 , C_SUPPLY_TYPE
                 , PDT_STOCK_MANAGEMENT
                 , PDT_CALC_REQUIREMENT_MNGMENT
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , PDT_PIC
                 , PDT_CONTINUOUS_INVENTAR
                 , PDT_STOCK_OBTAIN_MANAGEMENT
                 , PDT_FULL_TRACABILITY
                 , PDT_GUARANTY_USE
                 , C_PRODUCT_TYPE
                  )
           values (tdata.GCO_GOOD_ID
                 , tdata.C_SUPPLY_MODE
                 , nvl(tdata.C_SUPPLY_TYPE, '1')
                 , nvl(tdata.PDT_STOCK_MANAGEMENT, 1)
                 , nvl(tdata.PDT_CALC_REQUIREMENT_MNGMENT, 1)
                 , FWK_I_LIB_ENTITY.getIdfromPk2('STM_STOCK', 'STO_DESCRIPTION', tdata.STO_DESCRIPTION)
                 , (case
                      when tdata.LOC_DESCRIPTION is null then null
                      else (select STM_LOCATION_ID
                              from STM_LOCATION loc
                                 , STM_STOCK sto
                             where loc.LOC_DESCRIPTION = tdata.LOC_DESCRIPTION
                               and loc.STM_STOCK_ID = sto.STM_STOCK_ID
                               and sto.STO_DESCRIPTION = tdata.STO_DESCRIPTION)
                    end
                   )
                 , nvl(tdata.PDT_PIC, 0)
                 , nvl(tdata.PDT_CONTINUOUS_INVENTAR, 0)
                 , nvl(tdata.PDT_STOCK_OBTAIN_MANAGEMENT, 0)
                 , nvl(tdata.PDT_FULL_TRACABILITY, 0)
                 , nvl(tdata.PDT_GUARANTY_USE, 0)
                 , 1
                  );

      --Insertion dans historique
      insert into IMP_HIST_GCO_PRODUCT
                  (ID_HIST
                 , DATE_HIST
                 , EXCEL_LINE
                 , GCO_GOOD_ID
                 , C_SUPPLY_MODE
                 , C_SUPPLY_TYPE
                 , PDT_STOCK_MANAGEMENT
                 , PDT_CALC_REQUIREMENT_MNGMENT
                 , STO_DESCRIPTION
                 , LOC_DESCRIPTION
                 , PDT_PIC
                 , PDT_CONTINUOUS_INVENTAR
                 , PDT_STOCK_OBTAIN_MANAGEMENT
                 , PDT_FULL_TRACABILITY
                 , PDT_GUARANTY_USE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , sysdate
                 , tdata.EXCEL_LINE
                 , tdata.GCO_GOOD_ID
                 , tdata.C_SUPPLY_MODE
                 , tdata.C_SUPPLY_TYPE
                 , tdata.PDT_STOCK_MANAGEMENT
                 , tdata.PDT_CALC_REQUIREMENT_MNGMENT
                 , tdata.STO_DESCRIPTION
                 , tdata.LOC_DESCRIPTION
                 , tdata.PDT_PIC
                 , tdata.PDT_CONTINUOUS_INVENTAR
                 , tdata.PDT_STOCK_OBTAIN_MANAGEMENT
                 , tdata.PDT_FULL_TRACABILITY
                 , tdata.PDT_GUARANTY_USE
                 , sysdate
                 , pcs.PC_I_LIB_SESSION.GetUserIni
                  );
    end loop;
  end IMP_GCO_PRODUCT_IMPORT;
end IMP_GCO_BASIS;
