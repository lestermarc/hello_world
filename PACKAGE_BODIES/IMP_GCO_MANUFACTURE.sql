--------------------------------------------------------
--  DDL for Package Body IMP_GCO_MANUFACTURE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IMP_GCO_MANUFACTURE" 
as
  lcDomain constant varchar2(15) := 'GCO_MANUFACTURE';

  /**
  * Description
  *    importation des donn�es d'Excel dans la table temporaire IMP_GCO_MANUFACTURE_. Cette proc�dure est appel�e depuis Excel
  */
  procedure IMP_TMP_GCO_MANUFACTURE(
    pGOO_MAJOR_REFERENCE              varchar2
  , pDIC_FAB_CONDITION_ID             varchar2
  , pCMA_DEFAULT                      varchar2
  , pSTO_DESCRIPTION                  varchar2
  , pLOC_DESCRIPTION                  varchar2
  , pC_TYPE_NOM                       varchar2
  , pSCH_REF                          varchar2
  , pCMA_PLAN_NUMBER                  varchar2
  , pCMA_PLAN_VERSION                 varchar2
  , pCMA_LOT_QUANTITY                 varchar2
  , pCMA_MANUFACTURING_DELAY          varchar2
  , pOPP_REFERENCE                    varchar2
  , pCMA_FIX_DELAY                    varchar2
  , pCMA_AUTO_RECEPT                  varchar2
  , pC_QTY_SUPPLY_RULE                varchar2
  , pC_TIME_SUPPLY_RULE               varchar2
  , pCMA_ECONOMICAL_QUANTITY          varchar2
  , pCMA_FIXED_DELAY                  varchar2
  , pC_ECONOMIC_CODE                  varchar2
  , pCMA_SHIFT                        varchar2
  , pCMA_PERCENT_TRASH                varchar2
  , pCMA_FIXED_QUANTITY_TRASH         varchar2
  , pCMA_QUANTITY_REFERENCE_TRASH     varchar2
  , pCMA_WEIGH                        integer
  , pCMA_WEIGH_MANDATORY              integer
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
    --Insertion dans la table IMP_GCO_MANUFACTURE_
    insert into IMP_GCO_MANUFACTURE_
                (id
               , EXCEL_LINE
               , GOO_MAJOR_REFERENCE
               , DIC_FAB_CONDITION_ID
               , CMA_DEFAULT
               , STO_DESCRIPTION
               , LOC_DESCRIPTION
               , DIC_UNIT_OF_MEASURE_ID
               , CDA_NUMBER_OF_DECIMAL
               , CDA_CONVERSION_FACTOR
               , C_TYPE_NOM
               , SCH_REF
               , CMA_PLAN_NUMBER
               , CMA_PLAN_VERSION
               , CMA_LOT_QUANTITY
               , CMA_MANUFACTURING_DELAY
               , OPP_REFERENCE
               , CMA_FIX_DELAY
               , CMA_AUTO_RECEPT
               , C_QTY_SUPPLY_RULE
               , C_TIME_SUPPLY_RULE
               , CMA_ECONOMICAL_QUANTITY
               , CMA_FIXED_DELAY
               , C_ECONOMIC_CODE
               , CMA_SHIFT
               , CMA_PERCENT_TRASH
               , CMA_FIXED_QUANTITY_TRASH
               , CMA_QUANTITY_REFERENCE_TRASH
               , CMA_WEIGH
               , CMA_WEIGH_MANDATORY
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
               , trim(pDIC_FAB_CONDITION_ID)
               , trim(pCMA_DEFAULT)
               , trim(pSTO_DESCRIPTION)
               , trim(pLOC_DESCRIPTION)
               , null
               , null
               , null
               , trim(pC_TYPE_NOM)
               , trim(pSCH_REF)
               , trim(pCMA_PLAN_NUMBER)
               , trim(pCMA_PLAN_VERSION)
               , trim(pCMA_LOT_QUANTITY)
               , trim(pCMA_MANUFACTURING_DELAY)
               , trim(pOPP_REFERENCE)
               , trim(pCMA_FIX_DELAY)
               , trim(pCMA_AUTO_RECEPT)
               , trim(pC_QTY_SUPPLY_RULE)
               , trim(pC_TIME_SUPPLY_RULE)
               , trim(pCMA_ECONOMICAL_QUANTITY)
               , trim(pCMA_FIXED_DELAY)
               , trim(pC_ECONOMIC_CODE)
               , trim(pCMA_SHIFT)
               , trim(pCMA_PERCENT_TRASH)
               , trim(pCMA_FIXED_QUANTITY_TRASH)
               , trim(pCMA_QUANTITY_REFERENCE_TRASH)
               , trim(pCMA_WEIGH)
               , trim(pCMA_WEIGH_MANDATORY)
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

    --Nombre de ligne ins�r�es
    pResult  := 1;
    commit;
  end IMP_TMP_GCO_MANUFACTURE;

  /**
  * Description
  *    Contr�le des donn�es de la table IMP_GCO_MANUFACTURE_ avant importation.
  */
  procedure IMP_GCO_MANUFACTURE_CTRL
  is
    tmp         varchar2(200);
    tmp_int     integer;
    lvTableName varchar2(30)  := 'GCO_COMPL_DATA_MANUFACTURE';
  begin
    --Effacement des tables d'erreurs
    IMP_PRC_TOOLS.deleteErrors(lcDomain);

    --Parcours de toutes les lignes de la table IMP_GCO_MANUFACTURE_
    for tdata in (select *
                    from IMP_GCO_MANUFACTURE_) loop
      /*******************************************************
      * --> Est-ce que tous les champs obligatoires sont pr�sents ?
      *******************************************************/
      if (   tdata.GOO_MAJOR_REFERENCE is null
          or tdata.DIC_FAB_CONDITION_ID is null
          or tdata.CMA_AUTO_RECEPT is null
          or tdata.C_QTY_SUPPLY_RULE is null
          or tdata.C_TIME_SUPPLY_RULE is null
          or tdata.C_ECONOMIC_CODE is null
         ) then
        IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_REQUIRED') );
      else
        /*******************************************************
        * --> Est-ce que la r�f�rence principale existe ?
        ********************************************************/
        IMP_PRC_TOOLS.checkGoodExists(tdata.GOO_MAJOR_REFERENCE, lcDomain, tdata.id, tdata.EXCEL_LINE);
        /*******************************************************
        * --> Est-ce que la condition de fabrication existe dans le dictionnaire ?
        ********************************************************/
        IMP_PRC_TOOLS.checkDicoValue('DIC_FAB_CONDITION', tdata.DIC_FAB_CONDITION_ID, lcDomain, tdata.id, tdata.EXCEL_LINE);

        /*******************************************************
        * --> Est-ce que la condition de fabrication est unique pour le produit ?
        ********************************************************/
        -- Contr�le de l'unicit� dans les donn�es en provenance du fichier Excel
        select count(DIC_FAB_CONDITION_ID)
          into tmp_int
          from IMP_GCO_MANUFACTURE_
         where DIC_FAB_CONDITION_ID = tdata.DIC_FAB_CONDITION_ID
           and GOO_MAJOR_REFERENCE = tdata.GOO_MAJOR_REFERENCE;

        -- S'il n'est pas unique, cr�ation d'une erreur
        if tmp_int > 1 then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_DIC_FAB_CONDITION_ID_1') );
        else
          -- Sinon contr�le de l'unicit� dans l'ERP
          select count(DIC_FAB_CONDITION_ID)
            into tmp_int
            from GCO_COMPL_DATA_MANUFACTURE
           where DIC_FAB_CONDITION_ID = tdata.DIC_FAB_CONDITION_ID
             and GCO_GOOD_ID = (select GCO_GOOD_ID
                                  from GCO_GOOD
                                 where GOO_MAJOR_REFERENCE = tdata.GOO_MAJOR_REFERENCE);

          if tmp_int > 0 then
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_DIC_FAB_CONDITION_ID_2') );
          end if;
        end if;

        /********************************************************
        * --> Est-ce qu'il y a au minimum et au maximum une condition de fabrication par d�faut sur le produit ?
        ********************************************************/
        select (select count(fab.dic_fab_condition_id)
                  from gco_compl_data_manufacture fab
                     , gco_good goo
                 where goo.gco_good_id = fab.gco_good_id
                   and goo.goo_major_reference = tdata.goo_major_reference
                   and fab.cma_default = 1) +
               (select count(fab_tmp.dic_fab_condition_id)
                  from IMP_GCO_MANUFACTURE_ fab_tmp
                     , gco_good goo
                 where goo.goo_major_reference = fab_tmp.goo_major_reference
                   and goo.goo_major_reference = tdata.goo_major_reference
                   and fab_tmp.cma_default = 1)
          into tmp_int
          from dual;

        if (   tmp_int > 1
            or tmp_int < 1) then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_DIC_FAB_CONDITION_ID_3') );
        end if;

        /********************************************************
        * --> Est-ce que le stock logique et l'emplacement existent et sont coh�rents  ?
        ********************************************************/
        if    (tdata.STO_DESCRIPTION is not null)
           or (tdata.LOC_DESCRIPTION is not null) then
          IMP_PRC_TOOLS.checkStockAndLocataion(tdata.STO_DESCRIPTION, tdata.LOC_DESCRIPTION, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

        /********************************************************
        * --> Est-ce que le type de nomenclature existe ?
        ********************************************************/
        if (tdata.c_type_nom is not null) then
          --Recherche de type de nomenclature pour le produit
          select count(c_type_nom)
            into tmp_int
            from pps_nomenclature nom
               , gco_good good
           where nom.gco_good_id = good.gco_good_id
             and good.goo_major_reference = tdata.goo_major_reference
             and c_type_nom = tdata.c_type_nom;

          if tmp_int = 0 then
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_C_TYPE_NOM') );
          end if;
        end if;

        /********************************************************
        * --> Est-ce que la gamme existe ?
        ********************************************************/
        if (tdata.sch_ref is not null) then
          begin
            --Recherche de la gamme pour le produit
            select sch_ref
              into tmp
              from fal_schedule_plan
             where sch_ref = tdata.sch_ref;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_SCH_REF') );
          end;
        end if;

        /********************************************************
        * --> Est-ce que la proc�dure op�ratoire existe ?
        ********************************************************/
        if (tdata.OPP_REFERENCE is not null) then
          begin
            --Recherche de la proc�dure op�ratoire pour le produit
            select OPP_REFERENCE
              into tmp
              from PPS_OPERATION_PROCEDURE
             where OPP_REFERENCE = tdata.OPP_REFERENCE;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_OPP_DESCRIBE') );
          end;
        end if;

        /********************************************************
        * --> Est-ce que la valeur du flag r�ception auto est correcte ?
        ********************************************************/
        IMP_PRC_TOOLS.checkBooleanValue('CMA_AUTO_RECEPT', tdata.CMA_AUTO_RECEPT, lcDomain, tdata.id, tdata.EXCEL_LINE);

        /********************************************************
        * --> Est-ce que la valeur du flag condition par d�faut est correcte ?
        ********************************************************/
        if tdata.CMA_DEFAULT is not null then
          IMP_PRC_TOOLS.checkBooleanValue('CMA_DEFAULT', tdata.CMA_DEFAULT, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

        /********************************************************
        * --> Est-ce que la valeur du flag dur�e fixe est correcte ?
        ********************************************************/
        IMP_PRC_TOOLS.checkBooleanValue('CMA_FIX_DELAY', nvl(tdata.CMA_FIX_DELAY, '0'), lcDomain, tdata.id, tdata.EXCEL_LINE);
        /********************************************************
        * --> Est-ce que le code pes�e mati�re pr�cieuse est correcte ?
        ********************************************************/
        IMP_PRC_TOOLS.checkBooleanValue('CMA_WEIGH', nvl(tdata.CMA_WEIGH, '0'), lcDomain, tdata.id, tdata.EXCEL_LINE);
        /********************************************************
        * --> Est-ce que le code pes�e obligatoire est correcte ?
        ********************************************************/
        IMP_PRC_TOOLS.checkBooleanValue('CMA_WEIGH_MANDATORY', nvl(tdata.CMA_WEIGH_MANDATORY, '0'), lcDomain, tdata.id, tdata.EXCEL_LINE);
        /********************************************************
        * --> Est-ce que le code quantit� �conomique est correcte ?
        ********************************************************/
        IMP_PRC_TOOLS.checkDescodeValue('C_ECONOMIC_CODE', tdata.C_ECONOMIC_CODE, '{1,2,3,4}', lcDomain, tdata.id, tdata.EXCEL_LINE);
        /********************************************************
        * --> Est-ce que la r�gle quantitative d'appro est correcte ?
        ********************************************************/
        IMP_PRC_TOOLS.checkDescodeValue('C_QTY_SUPPLY_RULE', tdata.C_QTY_SUPPLY_RULE, '{1,2}', lcDomain, tdata.id, tdata.EXCEL_LINE);

        /********************************************************
        * --> Est-ce que la Quantit� �conomique est > � 0 et inf�rieur � 999'999'999 ?
        ********************************************************/
        if    (    nvl(tdata.CMA_ECONOMICAL_QUANTITY, 1) < 1
               and nvl(tdata.CMA_ECONOMICAL_QUANTITY, 1) > 999999999)
           or (    tdata.CMA_ECONOMICAL_QUANTITY is null
               and tdata.C_QTY_SUPPLY_RULE = '2') then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('La quantit� �conomique doit �tre sup�rieure � 0 !') );
        end if;

        /********************************************************
        * --> Est-ce que la r�gle temporelle d'appro est correcte ?
        ********************************************************/
        IMP_PRC_TOOLS.checkDescodeValue('C_TIME_SUPPLY_RULE', tdata.C_TIME_SUPPLY_RULE, '{1,2}', lcDomain, tdata.id, tdata.EXCEL_LINE);

        /********************************************************
        * --> Est-ce que le nombre de p�riodicit� fixe est > � 0 et inf�rieur � 999'999'999 ?
        ********************************************************/
        if    (    nvl(tdata.CMA_FIXED_DELAY, 1) < 1
               and nvl(tdata.CMA_FIXED_DELAY, 1) > 999999999)
           or (    tdata.CMA_FIXED_DELAY is null
               and tdata.C_TIME_SUPPLY_RULE = '2') then
          IMP_PRC_TOOLS.insertError(lcDomain
                                  , tdata.id
                                  , tdata.EXCEL_LINE
                                  , pcs.pc_functions.TranslateWord('Le nombre de p�riodicit� fixe doit �tre sup�rieur � 0 !')
                                   );
        end if;
      end if;
    end loop;

    --Si la table d'erreurs est vide, alors on ins�re le message repris par le pilotage de contr�le disant qu'il n'y a pas d'erreur
    IMP_PRC_TOOLS.checkErrors(lcDomain);
    commit;
  end IMP_GCO_MANUFACTURE_CTRL;

  /**
  * Description
  *    Importation des donn�es compl�mentaires de fabrication
  */
  procedure IMP_GCO_MANUFACTURE_IMPORT
  is
    lGoodID GCO_GOOD.GCO_GOOD_ID%type;
    ltGood  FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    --Contr�le que la table d'erreurs soit vide
    IMP_PRC_TOOLS.checkErrorsBeforeImport(lcDomain);

    --Parcours de toutes les lignes de la table temporaire IMP_GCO_FAB_ � ins�rer
    for tdata in (select *
                    from IMP_GCO_MANUFACTURE_) loop
      -- R�cup�ration ID du bien
      lGoodID  := FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', tdata.GOO_MAJOR_REFERENCE);

      --Insertion des donn�es dans les tables !
      insert into GCO_COMPL_DATA_MANUFACTURE
                  (GCO_COMPL_DATA_MANUFACTURE_ID
                 , GCO_GOOD_ID
                 , A_DATECRE
                 , A_IDCRE
                 , DIC_UNIT_OF_MEASURE_ID
                 , CDA_NUMBER_OF_DECIMAL
                 , CDA_CONVERSION_FACTOR
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , DIC_FAB_CONDITION_ID
                 , CMA_DEFAULT
                 , PPS_NOMENCLATURE_ID
                 , FAL_SCHEDULE_PLAN_ID
                 , CMA_PLAN_NUMBER
                 , CMA_PLAN_VERSION
                 , CMA_LOT_QUANTITY
                 , CMA_FIX_DELAY
                 , PPS_OPERATION_PROCEDURE_ID
                 , CMA_FIXED_DELAY
                 , CMA_AUTO_RECEPT
                 , C_QTY_SUPPLY_RULE
                 , C_TIME_SUPPLY_RULE
                 , CMA_ECONOMICAL_QUANTITY
                 , CMA_MANUFACTURING_DELAY
                 , C_ECONOMIC_CODE
                 , CMA_SHIFT
                 , CMA_PERCENT_TRASH
                 , CMA_FIXED_QUANTITY_TRASH
                 , CMA_QTY_REFERENCE_LOSS
                 , CMA_WEIGH
                 , CMA_WEIGH_MANDATORY
                  )
           values (GetNewId
                 , lGoodID
                 , sysdate
                 , IMP_LIB_TOOLS.getImportUserIni
                 , FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('GCO_GOOD', 'DIC_UNIT_OF_MEASURE_ID', lGoodID)
                 , FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('GCO_GOOD', 'GOO_NUMBER_OF_DECIMAL', lGoodID)
                 , 1   --CDA_CONVERSION_FACTOR
                 , FWK_I_LIB_ENTITY.getIdfromPk2('STM_STOCK', 'STO_DESCRIPTION', tdata.STO_DESCRIPTION)
                 , IMP_LIB_TOOLS.getLocationId(tdata.STO_DESCRIPTION, tdata.LOC_DESCRIPTION)
                 , tdata.DIC_FAB_CONDITION_ID
                 , nvl(tdata.CMA_DEFAULT, 0)
                 , (select PPS_NOMENCLATURE_ID
                      from PPS_NOMENCLATURE
                     where NOM_DEFAULT = 1
                       and C_TYPE_NOM = tdata.C_TYPE_NOM
                       and GCO_GOOD_ID = lGoodID)
                 , FWK_I_LIB_ENTITY.getIdfromPk2('FAL_SCHEDULE_PLAN', 'SCH_REF', tdata.SCH_REF)
                 , tdata.CMA_PLAN_NUMBER
                 , tdata.CMA_PLAN_VERSION
                 , nvl(tdata.CMA_LOT_QUANTITY, 1)
                 , nvl(tdata.CMA_FIX_DELAY, 0)
                 , FWK_I_LIB_ENTITY.getIdfromPk2('PPS_OPERATION_PROCEDURE', 'OPP_REFERENCE', tdata.OPP_REFERENCE)
                 , tdata.CMA_FIXED_DELAY
                 , nvl(sign(abs(tdata.CMA_AUTO_RECEPT) ), 0)
                 , tdata.C_QTY_SUPPLY_RULE
                 , tdata.C_TIME_SUPPLY_RULE
                 , tdata.CMA_ECONOMICAL_QUANTITY
                 , tdata.CMA_MANUFACTURING_DELAY
                 , nvl(tdata.C_ECONOMIC_CODE, '1')
                 , tdata.CMA_SHIFT
                 , tdata.CMA_PERCENT_TRASH
                 , tdata.CMA_FIXED_QUANTITY_TRASH
                 , tdata.CMA_QUANTITY_REFERENCE_TRASH
                 , nvl(tdata.CMA_WEIGH, 0)
                 , nvl(tdata.CMA_WEIGH_MANDATORY, 0)
                  );

       -- m�j du flag sur le bien
      -- Cr�ation de l'entit� GCO_GOOD
      FWK_I_MGT_ENTITY.new(FWK_TYP_GCO_ENTITY.gcGcoGood, ltGood);
      -- Init de l'id du bien
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGood, 'GCO_GOOD_ID', lGoodID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGood, 'GCO_DATA_MANUFACTURE', 1);
      FWK_I_MGT_ENTITY.UpdateEntity(ltGood);
      FWK_I_MGT_ENTITY.Release(ltGood);

      --Insertion des donn�es dans les tables !
      insert into IMP_HIST_GCO_MANUFACTURE
                  (ID_HIST
                 , DATE_HIST
                 , EXCEL_LINE
                 , GOO_MAJOR_REFERENCE
                 , DIC_FAB_CONDITION_ID
                 , CMA_DEFAULT
                 , STO_DESCRIPTION
                 , LOC_DESCRIPTION
                 , DIC_UNIT_OF_MEASURE_ID
                 , CDA_NUMBER_OF_DECIMAL
                 , CDA_CONVERSION_FACTOR
                 , C_TYPE_NOM
                 , SCH_REF
                 , CMA_LOT_QUANTITY
                 , CMA_FIXED_DELAY
                 , CMA_AUTO_RECEPT
                 , C_QTY_SUPPLY_RULE
                 , C_TIME_SUPPLY_RULE
                 , CMA_ECONOMICAL_QUANTITY
                 , CMA_MANUFACTURING_DELAY
                 , C_ECONOMIC_CODE
                 , CMA_SHIFT
                 , CMA_PERCENT_TRASH
                 , CMA_FIXED_QUANTITY_TRASH
                 , CMA_QUANTITY_REFERENCE_TRASH
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
                 , CMA_WEIGH
                 , CMA_WEIGH_MANDATORY
                 , CMA_FIX_DELAY
                 , CMA_PLAN_NUMBER
                 , CMA_PLAN_VERSION
                 , OPP_REFERENCE
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , sysdate
                 , tdata.EXCEL_LINE
                 , tdata.GOO_MAJOR_REFERENCE
                 , tdata.DIC_FAB_CONDITION_ID
                 , tdata.CMA_DEFAULT
                 , tdata.STO_DESCRIPTION
                 , tdata.LOC_DESCRIPTION
                 , null   --DIC_UNIT_OF_MEASURE_ID
                 , null   --CDA_NUMBER_OF_DECIMAL
                 , null   --CDA_CONVERSION_FACTOR
                 , tdata.C_TYPE_NOM
                 , tdata.SCH_REF
                 , tdata.CMA_LOT_QUANTITY
                 , tdata.CMA_FIXED_DELAY
                 , tdata.CMA_AUTO_RECEPT
                 , tdata.C_QTY_SUPPLY_RULE
                 , tdata.C_TIME_SUPPLY_RULE
                 , tdata.CMA_ECONOMICAL_QUANTITY
                 , tdata.CMA_MANUFACTURING_DELAY
                 , tdata.C_ECONOMIC_CODE
                 , tdata.CMA_SHIFT
                 , tdata.CMA_PERCENT_TRASH
                 , tdata.CMA_FIXED_QUANTITY_TRASH
                 , tdata.CMA_QUANTITY_REFERENCE_TRASH
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
                 , tdata.CMA_WEIGH
                 , tdata.CMA_WEIGH_MANDATORY
                 , tdata.CMA_FIX_DELAY
                 , tdata.CMA_PLAN_NUMBER
                 , tdata.CMA_PLAN_VERSION
                 , tdata.OPP_REFERENCE
                 , sysdate
                 , pcs.PC_I_LIB_SESSION.GetUserIni
                  );
    end loop;
  end IMP_GCO_MANUFACTURE_IMPORT;
end IMP_GCO_MANUFACTURE;
