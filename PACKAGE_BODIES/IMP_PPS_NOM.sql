--------------------------------------------------------
--  DDL for Package Body IMP_PPS_NOM
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "IMP_PPS_NOM" 
as
  lcDomain constant varchar2(15) := 'PPS_NOM';

  /**
  * procedure pUpdateLevel
  * Description
  *    Mise à jour des nomenclatures (PPS_PPS_NOMENCLATURE_ID) sur les composants des nomenclatures importées.
  *    On prend la nomenclature du même type et de même version. Si inexistant, on prend la nomenclature par défaut
  *    du même type. Si inexistant, on ne prend rien.
  * @created AGE 17.07.2013
  * @lastUpdate
  * @private
  */
  procedure pUpdateLevel
  as
  begin
    -- Pour chaque composant des nomenclatures importées
    for ltplNomBond in (select bom.PPS_NOM_BOND_ID
                             , bom.GCO_GOOD_ID
                             , nom.C_TYPE_NOM
                             , nom.NOM_VERSION
                          from PPS_NOM_BOND bom
                             , IMP_PPS_NOMENCLATURE nom
                         where bom.PPS_NOMENCLATURE_ID = nom.PPS_NOMENCLATURE_ID
                           and GCO_GOOD_ID is not null
                           and PPS_PPS_NOMENCLATURE_ID is null) loop
      -- On va récupérer la nomenclature de ce bien du même type de même version si existant, pas défaut sinon, ou sinon aucun
      update PPS_NOM_BOND
         set PPS_PPS_NOMENCLATURE_ID =
               (select PPS_NOMENCLATURE_ID
                  from (select   PPS_NOMENCLATURE_ID
                               , '1' PRIORITY
                            from PPS_NOMENCLATURE
                           where GCO_GOOD_ID = ltplNomBond.GCO_GOOD_ID
                             and C_TYPE_NOM = ltplNomBond.C_TYPE_NOM
                             and nvl(NOM_VERSION, -1) = nvl(ltplNomBond.NOM_VERSION, -1)
                             and DOC_RECORD_ID is null
                        union
                        select   PPS_NOMENCLATURE_ID
                               , '2' PRIORITY
                            from PPS_NOMENCLATURE
                           where GCO_GOOD_ID = ltplNomBond.GCO_GOOD_ID
                             and C_TYPE_NOM = ltplNomBond.C_TYPE_NOM
                             and NOM_DEFAULT = 1
                             and DOC_RECORD_ID is null
                        order by PRIORITY)
                 where rownum = 1)
       where PPS_NOM_BOND_ID = ltplNomBond.PPS_NOM_BOND_ID;
    end loop;
  end pUpdateLevel;

  /**
  * Description
  *    Importation des données d'Excel dans la table temporaire IMP_PPS_NOMENCLATURE. Les nomenclatures (identifiées par
  *    le trio (GCO_MAJOR_REFERENCE/C_TYPE_NOM/NOM_VERSION) ne sont insérées qu'une seule fois dans la table. Seule le 1er trio
  *    est inséré).
  *    Cette procédure est appelée depuis Excel
  */
  procedure IMP_TMP_PPS_NOMENCLATURE(
    pGOO_MAJOR_REFERENCE  in     IMP_PPS_NOMENCLATURE.GOO_MAJOR_REFERENCE%type
  , pC_TYPE_NOM           in     IMP_PPS_NOMENCLATURE.C_TYPE_NOM%type
  , iNomDefault           in     IMP_PPS_NOMENCLATURE.NOM_DEFAULT%type
  , iNomVersion           in     IMP_PPS_NOMENCLATURE.NOM_VERSION%type
  , pNOM_REF_QTY          in     IMP_PPS_NOMENCLATURE.NOM_REF_QTY%type
  , pFAL_SCHEDULE_PLAN_ID in     IMP_PPS_NOMENCLATURE.FAL_SCHEDULE_PLAN_ID%type
  , iFree1                in     IMP_PPS_NOMENCLATURE.FREE1%type
  , iFree2                in     IMP_PPS_NOMENCLATURE.FREE2%type
  , iFree3                in     IMP_PPS_NOMENCLATURE.FREE3%type
  , iFree4                in     IMP_PPS_NOMENCLATURE.FREE4%type
  , iFree5                in     IMP_PPS_NOMENCLATURE.FREE5%type
  , pEXCEL_LINE           in     IMP_PPS_NOMENCLATURE.EXCEL_LINE%type
  , pRESULT               out    integer
  )
  as
  begin
    --Insertion dans la table IMP_PPS_NOMENCLATURE.
    -- Les nomenclature ne sont insérées qu'une seule fois. C'est la première
    -- nomenclature (trio GCO_MAJOR_REFERNCE/C_TYPE_NOM/NOM_VERSION) qui est insérée.
    insert into IMP_PPS_NOMENCLATURE
                (id
               , EXCEL_LINE
               , PPS_NOMENCLATURE_ID
               , GOO_MAJOR_REFERENCE
               , C_TYPE_NOM
               , FAL_SCHEDULE_PLAN_ID
               , NOM_BEG_VALID
               , NOM_REF_QTY
               , NOM_DEFAULT
               , NOM_VERSION
               , FREE1
               , FREE2
               , FREE3
               , FREE4
               , FREE5
               , A_DATECRE
               , A_IDCRE
                )
      select GetNewId
           , pEXCEL_LINE
           , GetNewId
           , trim(pGOO_MAJOR_REFERENCE)
           , trim(pC_TYPE_NOM)
           , trim(pFAL_SCHEDULE_PLAN_ID)
           , null
           , trim(pNOM_REF_QTY)
           , trim(iNomDefault)
           , trim(iNomVersion)
           , trim(iFree1)
           , trim(iFree2)
           , trim(iFree3)
           , trim(iFree4)
           , trim(iFree5)
           , sysdate
           , IMP_LIB_TOOLS.getImportUserIni
        from dual
       where not exists(
                      select id
                        from IMP_PPS_NOMENCLATURE
                       where GOO_MAJOR_REFERENCE = trim(pGOO_MAJOR_REFERENCE)
                         and C_TYPE_NOM = trim(pC_TYPE_NOM)
                         and nvl(NOM_VERSION, -1) = nvl(trim(iNomVersion), -1) );

    --Nombre de ligne insérées
    pResult  := 1;
    commit;
  end IMP_TMP_PPS_NOMENCLATURE;

  /**
  * Description
  *    Importation des données d'Excel dans la table temporaire IMP_PPS_NOM_BOND
  *    Cette procédure est appelée depuis Excel
  */
  procedure IMP_TMP_PPS_NOM_BOND(
    pGOO_MAJOR_REFERENCE      in IMP_PPS_NOM_BOND.GOO_MAJOR_REFERENCE%type
  , iCTypeNom                 in IMP_PPS_NOMENCLATURE.C_TYPE_NOM%type
  , iNomDefault               in IMP_PPS_NOMENCLATURE.NOM_DEFAULT%type
  , iNomVersion               in IMP_PPS_NOMENCLATURE.NOM_VERSION%type
  , pGOO_MAJOR_REFERENCE_COMP in IMP_PPS_NOM_BOND.GOO_MAJOR_REFERENCE_COMP%type
  , pCOM_UTIL_COEFF           in IMP_PPS_NOM_BOND.COM_UTIL_COEFF%type
  , iComPdirCoeff             in IMP_PPS_NOM_BOND.COM_PDIR_COEFF%type
  , pCOM_SEQ                  in IMP_PPS_NOM_BOND.COM_SEQ%type
  , iComPos                   in IMP_PPS_NOM_BOND.COM_POS%type
  , pC_TYPE_COM               in IMP_PPS_NOM_BOND.C_TYPE_COM%type
  , pC_KIND_COM               in IMP_PPS_NOM_BOND.C_KIND_COM%type
  , pC_DISCHARGE_COM          in IMP_PPS_NOM_BOND.C_DISCHARGE_COM%type
  , iComInterval              in IMP_PPS_NOM_BOND.COM_INTERVAL%type
  , iStoDescription           in IMP_PPS_NOM_BOND.STO_DESCRIPTION%type
  , iLocDescription           in IMP_PPS_NOM_BOND.LOC_DESCRIPTION%type
  , iComPercentWaste          in IMP_PPS_NOM_BOND.COM_PERCENT_WASTE%type
  , iComFixedQuantityWaste    in IMP_PPS_NOM_BOND.COM_FIXED_QUANTITY_WASTE%type
  , iComQtyReferenceLoss      in IMP_PPS_NOM_BOND.COM_QTY_REFERENCE_LOSS%type
  , pCOM_INCREASE_COST        in IMP_PPS_NOM_BOND.COM_INCREASE_COST%type
  , pCOM_WEIGHING             in IMP_PPS_NOM_BOND.COM_WEIGHING%type
  , pCOM_WEIGHING_MANDATORY   in IMP_PPS_NOM_BOND.COM_WEIGHING_MANDATORY%type
  , pFAL_SCHEDULE_STEP_ID     in IMP_PPS_NOM_BOND.FAL_SCHEDULE_STEP_ID%type
  , iFree1                    in IMP_PPS_NOM_BOND.FREE1%type
  , iFree2                    in IMP_PPS_NOM_BOND.FREE2%type
  , iFree3                    in IMP_PPS_NOM_BOND.FREE3%type
  , iFree4                    in IMP_PPS_NOM_BOND.FREE4%type
  , iFree5                    in IMP_PPS_NOM_BOND.FREE5%type
  , pEXCEL_LINE               in integer
  )
  as
  begin
    --Insertion dans la table IMP_PPS_NOM_BOND
    insert into IMP_PPS_NOM_BOND
                (id
               , EXCEL_LINE
               , PPS_NOM_BOND_ID
               , PPS_NOMENCLATURE_ID
               , GOO_MAJOR_REFERENCE
               , GOO_MAJOR_REFERENCE_COMP
               , COM_UTIL_COEFF
               , COM_SEQ
               , C_TYPE_COM
               , C_KIND_COM
               , C_DISCHARGE_COM
               , FAL_SCHEDULE_STEP_ID
               , COM_INCREASE_COST
               , COM_WEIGHING
               , COM_WEIGHING_MANDATORY
               , COM_PDIR_COEFF
               , COM_POS
               , COM_INTERVAL
               , STO_DESCRIPTION
               , LOC_DESCRIPTION
               , COM_PERCENT_WASTE
               , COM_FIXED_QUANTITY_WASTE
               , COM_QTY_REFERENCE_LOSS
               , FREE1
               , FREE2
               , FREE3
               , FREE4
               , FREE5
               , A_DATECRE
               , A_IDCRE
                )
         values (GetNewId
               , pEXCEL_LINE
               , GetNewId
               , (select PPS_NOMENCLATURE_ID
                    from IMP_PPS_NOMENCLATURE
                   where GOO_MAJOR_REFERENCE = trim(pGOO_MAJOR_REFERENCE)
                     and C_TYPE_NOM = trim(iCTypeNom)
                     and nvl(NOM_VERSION, -1) = nvl(trim(iNomVersion), -1) )
               , trim(pGOO_MAJOR_REFERENCE)
               , trim(pGOO_MAJOR_REFERENCE_COMP)
               , trim(pCOM_UTIL_COEFF)
               , trim(pCOM_SEQ)
               , trim(pC_TYPE_COM)
               , trim(pC_KIND_COM)
               , trim(pC_DISCHARGE_COM)
               , trim(pFAL_SCHEDULE_STEP_ID)
               , trim(pCOM_INCREASE_COST)
               , trim(pCOM_WEIGHING)
               , trim(pCOM_WEIGHING_MANDATORY)
               , trim(iComPdirCoeff)
               , trim(iComPos)
               , trim(iComInterval)
               , trim(iStoDescription)
               , trim(iLocDescription)
               , trim(iComPercentWaste)
               , trim(iComFixedQuantityWaste)
               , trim(iComQtyReferenceLoss)
               , trim(iFree1)
               , trim(iFree2)
               , trim(iFree3)
               , trim(iFree4)
               , trim(iFree5)
               , sysdate
               , IMP_LIB_TOOLS.getImportUserIni
                );

    commit;
  end IMP_TMP_PPS_NOM_BOND;

  /**
  * Description
  *    Contrôle des données de la table IMP_PPS_NOMENCLATURE avant importation.
  */
  procedure IMP_PPS_NOMENCLATURE_CTRL
  as
    lTmpNumber number;
  begin
    --Effacement des tables d'erreurs
    IMP_PRC_TOOLS.deleteErrors(lcDomain);

    --Parcours de toutes les lignes de la table IMP_PPS_NOMENCLATURE
    for tdata in (select id
                       , EXCEL_LINE
                       , GOO_MAJOR_REFERENCE
                       , C_TYPE_NOM
                       , FAL_SCHEDULE_PLAN_ID as SCH_REF
                       , NOM_REF_QTY
                       , NOM_VERSION
                       , NOM_DEFAULT
                    from IMP_PPS_NOMENCLATURE) loop
      /*******************************************************
      * --> Est-ce que tous les champs obligatoires sont présents ?
      *******************************************************/
      if (   tdata.GOO_MAJOR_REFERENCE is null
          or tdata.C_TYPE_NOM is null
          or tdata.NOM_REF_QTY is null
          or tdata.NOM_DEFAULT is null) then
        IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_PPS_NOM_REQUIRED') );
      else
        /* Contrôle des boolean */
        IMP_PRC_TOOLS.checkBooleanValue('NOM_DEFAULT', tdata.NOM_DEFAULT, lcDomain, tdata.id, tdata.EXCEL_LINE);
        /* Contrôle des descods */
        IMP_PRC_TOOLS.checkDescodeValue('C_TYPE_NOM', tdata.C_TYPE_NOM, '{1,2,5,7,8}', lcDomain, tdata.id, tdata.EXCEL_LINE);
        /* Contrôle des dico */
        /* Contrôle des valeurs numériques */
        IMP_PRC_TOOLS.checkNumberValue('PPS_NOMENCLATURE', 'NOM_REF_QTY', tdata.NOM_REF_QTY, lcDomain, tdata.id, tdata.EXCEL_LINE);
        /* Contrôles métiers */

        /* --> Est-ce que le bien existe dans l'ERP ? */
        IMP_PRC_TOOLS.checkGoodExists(tdata.GOO_MAJOR_REFERENCE, lcDomain, tdata.id, tdata.EXCEL_LINE);

        /*******************************************************
        * --> Est-ce que la gamme opératoire existe dans l'ERP ?
        *******************************************************/
        if tdata.SCH_REF is not null then
          begin
            select FAL_SCHEDULE_PLAN_ID
              into lTmpNumber
              from FAL_SCHEDULE_PLAN
             where SCH_REF = tdata.SCH_REF;
          exception
            when no_data_found then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_SCH_REF') );
          end;
        end if;

        /*******************************************************
        * --> Est-ce que la nomenclature de ce type existe dans l'ERP pour ce bien ?
        * /!\ En réalité, l'identifiant métier unique d'une nomenclature est constituté :
        *      - du bien (GCO_GOOD_ID)
        *      - du type (C_TYPE_NOM)
        *      - de la version (NOM_VERSION)
        *      - du dossier (DOC_RECORD_ID)
        *******************************************************/
        begin
          select max(PPS_NOMENCLATURE_ID)
            into lTmpNumber
            from PPS_NOMENCLATURE
           where GCO_GOOD_ID = FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', tdata.GOO_MAJOR_REFERENCE)
             and C_TYPE_NOM = tdata.C_TYPE_NOM
             and nvl(NOM_VERSION, -1) = nvl(tdata.NOM_VERSION, -1);

          -- déjà existante !
          if nvl(lTmpNumber, 0) > 0 then
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_GOO_MAJOR_REFERENCE_MAIN_3') );
          end if;
        exception
          when no_data_found then
            null;
        end;

        /*******************************************************
        * --> Si par défaut, une seule nomenclature par défaut par bien et par type.
        ********************************************************/
        if tdata.NOM_DEFAULT = 1 then
          select count(NOM_DEFAULT)
            into lTmpNumber
            from IMP_PPS_NOMENCLATURE
           where GOO_MAJOR_REFERENCE = tdata.GOO_MAJOR_REFERENCE
             and C_TYPE_NOM = tdata.C_TYPE_NOM
             and NOM_DEFAULT = 1;

          -- S'il n'est pas unique, création d'une erreur
          if (lTmpNumber > 1) then   -- Il existe plusieurs nomenclatures par défaut du même type pour le même produit dans le fichier Excel.
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_NOM_DEFAULT_1') );
          else
            -- Sinon contrôle de l'unicité dans l'ERP
            select count(NOM_DEFAULT)
              into lTmpNumber
              from PPS_NOMENCLATURE
             where GCO_GOOD_ID = FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', tdata.GOO_MAJOR_REFERENCE)
               and C_TYPE_NOM = tdata.C_TYPE_NOM
               and NOM_DEFAULT = 1;

            if lTmpNumber > 0 then   -- Il existe déjà une nomenclatures par défaut du même type pour le même produit dans l'ERP.
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_NOM_DEFAULT_2') );
            end if;
          end if;
        end if;
      end if;
    end loop;

    --Appel de la procédure de contrôle des champs relatifs à la table IMP_PPS_NOM_BOND
    IMP_PPS_NOM_BOND_CTRL;
    --Si la table d'erreurs est vide, alors on insère le message repris par le pilotage de contrôle disant qu'il n'y a pas d'erreur
    IMP_PRC_TOOLS.checkErrors(lcDomain);
    -- Validation des contrôles.
    commit;
  end IMP_PPS_NOMENCLATURE_CTRL;

  /**
  * Description
  *    Contrôle des données de la table PPS_NOM_BOND avant importation.
  */
  procedure IMP_PPS_NOM_BOND_CTRL
  as
    lGoodMajorRef GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    lTmpNumber    number;
    lSchRef       FAL_SCHEDULE_PLAN.SCH_REF%type;
  begin
    --Parcours de toutes les lignes de la table IMP_PPS_NOM_BOND
    for tdata in (select *
                    from IMP_PPS_NOM_BOND) loop
      --> Est-ce que tous les champs obligatoires sont présents ?
      if    tdata.GOO_MAJOR_REFERENCE is null
         or tdata.GOO_MAJOR_REFERENCE_COMP is null
         or tdata.COM_UTIL_COEFF is null
         or tdata.COM_SEQ is null
         or tdata.C_TYPE_COM is null
         or tdata.C_KIND_COM is null
         or tdata.C_DISCHARGE_COM is null
         or tdata.COM_INCREASE_COST is null then
        IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_PPS_NOM_REQUIRED') );
      else
        /****** Contrôle des booleans ******/
        --> Coûts valorisables
        IMP_PRC_TOOLS.checkBooleanValue('COM_INCREASE_COST', tdata.COM_INCREASE_COST, lcDomain, tdata.id, tdata.EXCEL_LINE);

        --> Pesée matière précieuse
        if tdata.COM_WEIGHING is not null then
          IMP_PRC_TOOLS.checkBooleanValue('COM_WEIGHING', tdata.COM_WEIGHING, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

        --> Pesée matières précieuse obligatoire
        if tdata.COM_WEIGHING_MANDATORY is not null then
          IMP_PRC_TOOLS.checkBooleanValue('COM_WEIGHING_MANDATORY', tdata.COM_WEIGHING_MANDATORY, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;

        /****** Contrôle des descodes ******/
        --> Type de lien
        IMP_PRC_TOOLS.checkDescodeValue('C_TYPE_COM', tdata.C_TYPE_COM, '{1,2}', lcDomain, tdata.id, tdata.EXCEL_LINE);
        --> Genre de lien
        IMP_PRC_TOOLS.checkDescodeValue('C_KIND_COM', tdata.C_KIND_COM, '{1,2,3,4,5}', lcDomain, tdata.id, tdata.EXCEL_LINE);
        --> Décharge
        IMP_PRC_TOOLS.checkDescodeValue('C_DISCHARGE_COM', tdata.C_DISCHARGE_COM, '{1,2,3,4,5}', lcDomain, tdata.id, tdata.EXCEL_LINE);
        /****** Contrôle des dicos ******/
        /****** Contrôle des valeurs numériques ******/
        --> Coéfficient utilisation
        IMP_PRC_TOOLS.checkNumberValue('PPS_NOM_BOND', 'COM_UTIL_COEFF', tdata.COM_UTIL_COEFF, lcDomain, tdata.id, tdata.EXCEL_LINE, true);
        --> Coéfficient utilisation plan directeur
        IMP_PRC_TOOLS.checkNumberValue('PPS_NOM_BOND', 'COM_PDIR_COEFF', tdata.COM_PDIR_COEFF, lcDomain, tdata.id, tdata.EXCEL_LINE, true);

        --> Décalage
        if tdata.COM_INTERVAL is not null then
          IMP_PRC_TOOLS.checkNumberValue('PPS_NOM_BOND', 'COM_INTERVAL', tdata.COM_INTERVAL, lcDomain, tdata.id, tdata.EXCEL_LINE, true);
        end if;

        --> Pourcentage de déchets
        if tdata.COM_PERCENT_WASTE is not null then
          IMP_PRC_TOOLS.checkNumberValue('PPS_NOM_BOND', 'COM_PERCENT_WASTE', tdata.COM_PERCENT_WASTE, lcDomain, tdata.id, tdata.EXCEL_LINE, true);
        end if;

        --> Quantité fixe de déchets
        if tdata.COM_FIXED_QUANTITY_WASTE is not null then
          IMP_PRC_TOOLS.checkNumberValue('PPS_NOM_BOND', 'COM_FIXED_QUANTITY_WASTE', tdata.COM_FIXED_QUANTITY_WASTE, lcDomain, tdata.id, tdata.EXCEL_LINE
                                       , true);
        end if;

        --> Quantité de référence déchets
        if tdata.COM_QTY_REFERENCE_LOSS is not null then
          IMP_PRC_TOOLS.checkNumberValue('PPS_NOM_BOND', 'COM_QTY_REFERENCE_LOSS', tdata.COM_QTY_REFERENCE_LOSS, lcDomain, tdata.id, tdata.EXCEL_LINE, true);
        end if;

        /****** Contrôles métiers ******/
        /*******************************************************
        *  --> Existe-il des doublons dans les composants de la nomenclature du produit ?
        *      Unicité sur - ID de la nomenclature (PPS_NOMENCLATURE_ID)
        *                  - ID du composants
        *                  - Séquence du Composant
        ********************************************************/
        select count(id)
          into lTmpNumber
          from IMP_PPS_NOM_BOND
         where PPS_NOMENCLATURE_ID = tdata.PPS_NOMENCLATURE_ID
           and GOO_MAJOR_REFERENCE_COMP = tdata.GOO_MAJOR_REFERENCE_COMP
           and COM_SEQ = tdata.COM_SEQ;

        if lTmpNumber > 1 then
          IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_GOO_MAJOR_REFERENCE_COMP_2') );
        end if;

        --> Est-ce que le composant existe dans l'ERP ?
        begin
          select GOO_MAJOR_REFERENCE
            into lGoodMajorRef
            from GCO_GOOD
           where GOO_MAJOR_REFERENCE = tdata.GOO_MAJOR_REFERENCE_COMP;
        exception
          when no_data_found then
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_GOO_MAJOR_REFERENCE_COMP') );
        end;

        --> Est-ce que le composant est différent du produit fabriqué ?
        select count(id)
          into lTmpNumber
          from IMP_PPS_NOMENCLATURE
         where upper(GOO_MAJOR_REFERENCE) = tdata.GOO_MAJOR_REFERENCE_COMP
           and PPS_NOMENCLATURE_ID = tdata.PPS_NOMENCLATURE_ID;

        if lTmpNumber > 0 then
          IMP_PRC_TOOLS.insertError(lcDomain
                                  , tdata.id
                                  , tdata.EXCEL_LINE
                                  , replace(pcs.pc_functions.TranslateWord('Le composant ne doit pas être identique au produit fabriqué ([XXX])')
                                          , '[XXX]'
                                          , tdata.GOO_MAJOR_REFERENCE_COMP
                                           )
                                   );
        end if;

        --> Si une opération est définie, est-ce qu'une gamme a été définie sur la nomenclature ?
        if tdata.FAL_SCHEDULE_STEP_ID is not null then
          select FAL_SCHEDULE_PLAN_ID
            into lSchRef
            from IMP_PPS_NOMENCLATURE
           where PPS_NOMENCLATURE_ID = tdata.PPS_NOMENCLATURE_ID;

          if lSchRef is null then
            IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_SCH_REF_MISSING') );
          else
            --> Est-ce que L'opération existe dans la gamme définie dans la nomenclature ?
            select count('x')
              into lTmpNumber
              from dual
             where exists(
                     select FAL_SCHEDULE_STEP_ID
                       from FAL_LIST_STEP_LINK tal
                          , FAL_SCHEDULE_PLAN sch
                      where sch.FAL_SCHEDULE_PLAN_ID = tal.FAL_SCHEDULE_PLAN_ID
                        and upper(sch.SCH_REF) = upper(lSchRef)
                        and upper(tal.SCS_STEP_NUMBER) = upper(tdata.FAL_SCHEDULE_STEP_ID) );

            if lTmpNumber = 0 then
              IMP_PRC_TOOLS.insertError(lcDomain, tdata.id, tdata.EXCEL_LINE, pcs.pc_functions.TranslateWord('IMP_SCS_STEP_NUMBER') );
            end if;
          end if;
        end if;

        --> Est-ce que le stock logique et l'emplacement existent et sont cohérents  ?
        if    (tdata.STO_DESCRIPTION is not null)
           or (tdata.LOC_DESCRIPTION is not null) then
          IMP_PRC_TOOLS.checkStockAndLocataion(tdata.STO_DESCRIPTION, tdata.LOC_DESCRIPTION, lcDomain, tdata.id, tdata.EXCEL_LINE);
        end if;
      end if;
    end loop;
  end IMP_PPS_NOM_BOND_CTRL;

  /**
  * Description
  *    Importation des données nomenclature de la table IMP_PPS_NOMENCLATURE dans l'ERP.
  */
  procedure IMP_PPS_NOMENCLATURE_IMPORT
  as
  begin
    --Contrôle que la table d'erreurs soit vide
    IMP_PRC_TOOLS.checkErrorsBeforeImport(lcDomain);

    --Parcours de toutes les lignes à insérer
    for tdata in (select PPS_NOMENCLATURE_ID
                       , EXCEL_LINE
                       , GOO_MAJOR_REFERENCE
                       , C_TYPE_NOM
                       , FAL_SCHEDULE_PLAN_ID SCH_REF
                       , null NOM_BEG_VALID
                       , NOM_REF_QTY
                       , NOM_DEFAULT
                       , NOM_VERSION
                       , FREE1
                       , FREE2
                       , FREE3
                       , FREE4
                       , FREE5
                    from IMP_PPS_NOMENCLATURE) loop
      --Insertion des données dans les tables !
      insert into PPS_NOMENCLATURE
                  (PPS_NOMENCLATURE_ID
                 , GCO_GOOD_ID
                 , C_TYPE_NOM
                 , NOM_REF_QTY
                 , NOM_VERSION
                 , C_REMPLACEMENT_NOM
                 , NOM_DEFAULT
                 , NOM_MARK_NOMENCLATURE
                 , NOM_REMPL_PART
                 , FAL_SCHEDULE_PLAN_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (tdata.PPS_NOMENCLATURE_ID
                 , FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', tdata.GOO_MAJOR_REFERENCE)
                 , tdata.C_TYPE_NOM
                 , tdata.NOM_REF_QTY
                 , tdata.NOM_VERSION
                 , '2'   -- C_REMPLACEMENT_NOM
                 , tdata.NOM_DEFAULT
                 , '0'   -- NOM_MARK_NOMENCLATURE
                 , '1'   -- NOM_REMPL_PART
                 , FWK_I_LIB_ENTITY.getIdfromPk2('FAL_SCHEDULE_PLAN', 'SCH_REF', tdata.SCH_REF)
                 , sysdate
                 , IMP_LIB_TOOLS.getImportUserIni
                  );

      --Insertion dans historique
      insert into IMP_HIST_PPS_NOMENCLATURE
                  (ID_HIST
                 , DATE_HIST
                 , EXCEL_LINE
                 , PPS_NOMENCLATURE_ID
                 , GOO_MAJOR_REFERENCE
                 , C_TYPE_NOM
                 , FAL_SCHEDULE_PLAN_ID
                 , NOM_BEG_VALID
                 , NOM_REF_QTY
                 , NOM_DEFAULT
                 , NOM_VERSION
                 , FREE1
                 , FREE2
                 , FREE3
                 , FREE4
                 , FREE5
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , sysdate
                 , tdata.EXCEL_LINE
                 , tdata.PPS_NOMENCLATURE_ID
                 , tdata.GOO_MAJOR_REFERENCE
                 , tdata.C_TYPE_NOM
                 , tdata.SCH_REF
                 , null
                 , tdata.NOM_REF_QTY
                 , tdata.NOM_DEFAULT
                 , tdata.NOM_VERSION
                 , tdata.FREE1
                 , tdata.FREE2
                 , tdata.FREE3
                 , tdata.FREE4
                 , tdata.FREE5
                 , sysdate
                 , pcs.PC_I_LIB_SESSION.GetUserIni
                  );
    end loop;

    --Appel de la procédure d'importation des comporant des nomenclatures.
    IMP_PPS_NOM_BOND_IMPORT;
    /* Mise à jour de la nomenclature sur les biens des composants des nomenclatures importées */
    pUpdateLevel;
  end IMP_PPS_NOMENCLATURE_IMPORT;

  /**
  * Description
  *    Importation des données composants de la table IMP_PPS_NOM_BOND dans l'ERP.
  */
  procedure IMP_PPS_NOM_BOND_IMPORT
  as
  begin
    --Parcours de toutes les lignes à insérer
    for tdata in (select *
                    from IMP_PPS_NOM_BOND) loop
      --Insertion des données dans les tables !
      insert into PPS_NOM_BOND
                  (PPS_NOM_BOND_ID
                 , PPS_NOMENCLATURE_ID
                 , GCO_GOOD_ID
                 , C_REMPLACEMENT_NOM
                 , C_TYPE_COM
                 , C_DISCHARGE_COM
                 , C_KIND_COM
                 , COM_SEQ
                 , COM_POS
                 , COM_VAL
                 , COM_SUBSTITUT
                 , COM_UTIL_COEFF
                 , COM_PDIR_COEFF
                 , COM_REMPLACEMENT
                 , COM_INCREASE_COST
                 , COM_WEIGHING
                 , COM_WEIGHING_MANDATORY
                 , FAL_SCHEDULE_STEP_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (tdata.PPS_NOM_BOND_ID
                 , tdata.PPS_NOMENCLATURE_ID
                 , FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', tdata.GOO_MAJOR_REFERENCE_COMP)
                 , '2'   --C_REMPLACEMENT_NOM
                 , tdata.C_TYPE_COM
                 , case
                     when trim(tdata.FAL_SCHEDULE_STEP_ID) is null then tdata.C_DISCHARGE_COM
                     else '6'
                   end   -- Si un lien vers une opération existe, on insère le code décharge 6, quelque soit la valeur fournie par le fichier Excel (DEVERP-20207).
                 , tdata.C_KIND_COM
                 , tdata.COM_SEQ
                 , tdata.COM_POS
                 , 1   --COM_VAL
                 , 0   --COM_SUBSTITUT
                 , tdata.COM_UTIL_COEFF
                 , tdata.COM_PDIR_COEFF
                 , 0   --COM_REMPLACEMENT
                 , tdata.com_increase_cost
                 , nvl(tdata.COM_WEIGHING, 0)
                 , nvl(tdata.COM_WEIGHING_MANDATORY, 0)
                 , (select tal.FAL_SCHEDULE_STEP_ID
                      from FAL_LIST_STEP_LINK tal
                         , FAL_SCHEDULE_PLAN sch
                     where tal.FAL_SCHEDULE_PLAN_ID = sch.FAL_SCHEDULE_PLAN_ID
                       and upper(sch.SCH_REF) = (select upper(FAL_SCHEDULE_PLAN_ID)
                                                   from IMP_PPS_NOMENCLATURE
                                                  where PPS_NOMENCLATURE_ID = tdata.PPS_NOMENCLATURE_ID)
                       and tal.SCS_STEP_NUMBER = tdata.FAL_SCHEDULE_STEP_ID)
                 , sysdate
                 , IMP_LIB_TOOLS.getImportUserIni
                  );

      --Insertion dans historique
      insert into IMP_HIST_PPS_NOM_BOND
                  (ID_HIST
                 , DATE_HIST
                 , EXCEL_LINE
                 , PPS_NOM_BOND_ID
                 , PPS_NOMENCLATURE_ID
                 , GOO_MAJOR_REFERENCE
                 , GOO_MAJOR_REFERENCE_COMP
                 , COM_UTIL_COEFF
                 , COM_SEQ
                 , C_TYPE_COM
                 , C_KIND_COM
                 , C_DISCHARGE_COM
                 , FAL_SCHEDULE_STEP_ID
                 , COM_INCREASE_COST
                 , COM_WEIGHING
                 , COM_WEIGHING_MANDATORY
                 , COM_PDIR_COEFF
                 , COM_POS
                 , COM_INTERVAL
                 , STO_DESCRIPTION
                 , LOC_DESCRIPTION
                 , COM_PERCENT_WASTE
                 , COM_FIXED_QUANTITY_WASTE
                 , COM_QTY_REFERENCE_LOSS
                 , FREE1
                 , FREE2
                 , FREE3
                 , FREE4
                 , FREE5
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , sysdate
                 , tdata.EXCEL_LINE
                 , tdata.PPS_NOM_BOND_ID
                 , tdata.PPS_NOMENCLATURE_ID
                 , tdata.GOO_MAJOR_REFERENCE
                 , tdata.GOO_MAJOR_REFERENCE_COMP
                 , tdata.COM_UTIL_COEFF
                 , tdata.COM_SEQ
                 , tdata.C_TYPE_COM
                 , tdata.C_KIND_COM
                 , tdata.C_DISCHARGE_COM
                 , tdata.FAL_SCHEDULE_STEP_ID
                 , tdata.COM_INCREASE_COST
                 , tdata.COM_WEIGHING
                 , tdata.COM_WEIGHING_MANDATORY
                 , tdata.COM_PDIR_COEFF
                 , tdata.COM_POS
                 , tdata.COM_INTERVAL
                 , tdata.STO_DESCRIPTION
                 , tdata.LOC_DESCRIPTION
                 , tdata.COM_PERCENT_WASTE
                 , tdata.COM_FIXED_QUANTITY_WASTE
                 , tdata.COM_QTY_REFERENCE_LOSS
                 , tdata.FREE1
                 , tdata.FREE2
                 , tdata.FREE3
                 , tdata.FREE4
                 , tdata.FREE5
                 , sysdate
                 , pcs.PC_I_LIB_SESSION.GetUserIni
                  );
    end loop;
  end IMP_PPS_NOM_BOND_IMPORT;
end IMP_PPS_NOM;
