--------------------------------------------------------
--  DDL for Package Body PPS_PRC_INTERRO
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PPS_PRC_INTERRO" 
is
  cInitWeightCode constant varchar2(200) := PCS.PC_CONFIG.GetConfig('GMP_INIT_WEIGHT_CODE');
  vSequence                number(12)    default 100000;

  /**
  * procedure pPrepAlloyNomInterro
  * Description
  *   Remplir la table de l'interrogation nomenclature et la table liée des matières précieuses
  * @created fpe 02.03.2012
  * @public
  */
  procedure pPrepAlloyNomInterro(
    iMajorReference in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , iGoodId         in PPS_NOMENCLATURE.GCO_GOOD_ID%type
  , iInactive       in number
  , iSuspended      in number
  )
  is
    lNomenclatureId PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type   := PPS_I_LIB_FUNCTIONS.GetDefaultNomenclature(iGoodId, '2');
  begin
    if lNomenclatureId is not null then
      for ltplRoot in (select vSequence PPS_INTERROGATION_ID
                            , GOO.GOO_MAJOR_REFERENCE || '   ' || GOO.GOO_SECONDARY_REFERENCE PPI_TEXT
                            , 1 PPI_LEVEL
                            , NOM.NOM_VERSION || decode(NOM.NOM_DEFAULT, 1, ' - ' || PCS.PC_FUNCTIONS.TranslateWord('Défaut') ) PPI_NOM_VERSION
                            , iMajorReference PPI_ROOT_REFERENCE
                            , NOM.PPS_NOMENCLATURE_ID PPS_NOMENCLATURE_ID
                            , null PPS_PPS_NOMENCLATURE_ID
                            , NOM.GCO_GOOD_ID
                            , NOM.C_TYPE_NOM
                            , '( ' || DES.GCLCODE || ' ) ' || DES.GCDTEXT1 C_TYPE_NOM_TEXT
                            , 1 COM_REF_QTY
                         from PPS_NOMENCLATURE NOM
                            , GCO_GOOD GOO
                            , PCS.V_PC_DESCODES DES
                        where NOM.PPS_NOMENCLATURE_ID = lNomenclatureId
                          and NOM.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                          and NOM.C_TYPE_NOM = DES.GCLCODE
                          and NOM.NOM_DEFAULT = 1
                          and NOM.C_TYPE_NOM = '2'
                          and DES.GCGNAME = 'C_TYPE_NOM'
                          and GOO.C_GOOD_STATUS in
                                (GCO_I_LIB_CONSTANT.gcGoodStatusActive
                               , decode(iInactive, 1, GCO_I_LIB_CONSTANT.gcGoodStatusInactive, null)
                               , decode(iSuspended, 1, GCO_I_LIB_CONSTANT.gcGoodStatusSuspended, null)
                                )
                          and DES.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID) loop
        -- Insertion de la première ligne correspondant à la nomenclature interrogée
        insert into PPS_INTERROGATION
                    (PPS_INTERROGATION_ID
                   , PPI_TEXT
                   , PPI_LEVEL
                   , PPI_NOM_VERSION
                   , PPI_ROOT_REFERENCE
                   , PPS_NOMENCLATURE_ID
                   , PPS_PPS_NOMENCLATURE_ID
                   , GCO_GOOD_ID
                   , C_TYPE_NOM
                   , C_TYPE_NOM_TEXT
                   , COM_REF_QTY
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (ltplRoot.PPS_INTERROGATION_ID
                   , ltplRoot.PPI_TEXT
                   , ltplRoot.PPI_LEVEL
                   , ltplRoot.PPI_NOM_VERSION
                   , ltplRoot.PPI_ROOT_REFERENCE
                   , ltplRoot.PPS_NOMENCLATURE_ID
                   , ltplRoot.PPS_PPS_NOMENCLATURE_ID
                   , ltplRoot.GCO_GOOD_ID
                   , ltplRoot.C_TYPE_NOM
                   , ltplRoot.C_TYPE_NOM_TEXT
                   , ltplRoot.COM_REF_QTY
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );

        -- Initialisation de la variable de package pour l'execution de la cmd sql de la vue
        PPS_INIT.SetNomId(lNomenclatureId);
        PPS_INIT.SetSuspended(iSuspended);
        PPS_INIT.SetInactive(iInactive);

        -- Insertion des composants de la nomenclature interrogée
        insert into PPS_INTERROGATION
                    (PPS_INTERROGATION_ID
                   , PPI_TEXT
                   , PPI_LEVEL
                   , PPI_NOM_VERSION
                   , PPI_ROOT_REFERENCE
                   , PPS_NOMENCLATURE_ID
                   , PPS_PPS_NOMENCLATURE_ID
                   , PPS_NOM_BOND_ID
                   , PPS_RANGE_OPERATION_ID
                   , GCO_GOOD_ID
                   , STM_STOCK_ID
                   , STM_LOCATION_ID
                   , FAL_SCHEDULE_STEP_ID
                   , C_GOOD_STATUS
                   , C_GOOD_STATUS_TEXT
                   , C_DISCHARGE_COM
                   , C_DISCHARGE_COM_TEXT
                   , C_KIND_COM
                   , C_KIND_COM_TEXT
                   , C_REMPLACEMENT_NOM
                   , C_REMPLACEMENT_NOM_TEXT
                   , C_TYPE_COM
                   , C_TYPE_COM_TEXT
                   , C_TYPE_NOM
                   , C_TYPE_NOM_TEXT
                   , COM_BEG_VALID
                   , COM_END_VALID
                   , COM_INTERVAL
                   , COM_PDIR_COEFF
                   , COM_POS
                   , COM_REC_PCENT
                   , COM_REF_QTY
                   , COM_REMPLACEMENT
                   , COM_RES_NUM
                   , COM_RES_TEXT
                   , COM_SEQ
                   , COM_SUBSTITUT
                   , COM_TEXT
                   , COM_UTIL_COEFF
                   , COM_VAL
                   , A_DATECRE
                   , A_IDCRE
                    )
          select   vSequence + V_PPS.QUERY_ID_SEQ
                 , V_PPS.COM_SEQ ||
                   '   ' ||
                   decode(nvl(GOO.GCO_GOOD_ID, -1)
                        , -1, PCS.PC_FUNCTIONS.TranslateWord('Lien texte')
                        , GOO.GOO_MAJOR_REFERENCE || '   ' || GOO.GOO_SECONDARY_REFERENCE
                         )
                 , V_PPS.LEVEL_NOM + 1
                 , PPS_NOM.NOM_VERSION || decode(PPS_NOM.NOM_DEFAULT, 1, ' - ' || PCS.PC_FUNCTIONS.TranslateWord('Défaut') )
                 , iMajorReference
                 , V_PPS.PPS_NOMENCLATURE_ID
                 , V_PPS.PPS_PPS_NOMENCLATURE_ID
                 , V_PPS.PPS_NOM_BOND_ID
                 , V_PPS.PPS_RANGE_OPERATION_ID
                 , GOO.GCO_GOOD_ID
                 , V_PPS.STM_STOCK_ID
                 , V_PPS.STM_LOCATION_ID
                 , V_PPS.FAL_SCHEDULE_STEP_ID
                 , DES1.GCLCODE C_GOOD_STATUS
                 , decode(nvl(GOO.GCO_GOOD_ID, -1), -1, null, '( ' || DES1.GCLCODE || ' ) ' || DES1.GCDTEXT1) C_GOOD_STATUS_TEXT
                 , DES2.GCLCODE C_DISCHARGE_COM
                 , '( ' || DES2.GCLCODE || ' ) ' || DES2.GCDTEXT1 C_DISCHARGE_COM_TEXT
                 , DES3.GCLCODE C_KIND_COM
                 , '( ' || DES3.GCLCODE || ' ) ' || DES3.GCDTEXT1 C_KIND_COM_TEXT
                 , DES4.GCLCODE C_REMPLACEMENT_NOM
                 , '( ' || DES4.GCLCODE || ' ) ' || DES4.GCDTEXT1 C_REMPLACEMENT_NOM_TEXT
                 , DES5.GCLCODE C_TYPE_COM
                 , '( ' || DES5.GCLCODE || ' ) ' || DES5.GCDTEXT1 C_TYPE_COM_TEXT
                 , null C_TYPE_NOM
                 , null C_TYPE_NOM_TEXT
                 , V_PPS.COM_BEG_VALID
                 , V_PPS.COM_END_VALID
                 , V_PPS.COM_INTERVAL
                 , V_PPS.COM_PDIR_COEFF
                 , V_PPS.COM_POS
                 , V_PPS.COM_REC_PCENT
                 , nvl(V_PPS.COM_REF_QTY, 1)
                 , nvl(V_PPS.COM_REMPLACEMENT, 0)
                 , V_PPS.COM_RES_NUM
                 , V_PPS.COM_RES_TEXT
                 , V_PPS.COM_SEQ
                 , nvl(V_PPS.COM_SUBSTITUT, 0)
                 , V_PPS.COM_TEXT
                 , V_PPS.COM_UTIL_COEFF
                 , V_PPS.COM_VAL
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
              from V_PPS_NOMENCLATURE_INTERRO V_PPS
                 , PPS_NOMENCLATURE NOM
                 , PPS_NOMENCLATURE PPS_NOM
                 , GCO_GOOD GOO
                 , PCS.V_PC_DESCODES DES1
                 , PCS.V_PC_DESCODES DES2
                 , PCS.V_PC_DESCODES DES3
                 , PCS.V_PC_DESCODES DES4
                 , PCS.V_PC_DESCODES DES5
             where V_PPS.PPS_NOMENCLATURE_ID = NOM.PPS_NOMENCLATURE_ID
               and V_PPS.PPS_PPS_NOMENCLATURE_ID = PPS_NOM.PPS_NOMENCLATURE_ID(+)
               and V_PPS.GCO_GOOD_ID = GOO.GCO_GOOD_ID
               and NOM.NOM_DEFAULT = 1
               and NOM.C_TYPE_NOM = '2'
               and PPS_NOM.NOM_DEFAULT(+) = 1
               and PPS_NOM.C_TYPE_NOM(+) = '2'
               and GOO.C_GOOD_STATUS in
                     (GCO_I_LIB_CONSTANT.gcGoodStatusActive
                    , decode(iInactive, 1, GCO_I_LIB_CONSTANT.gcGoodStatusInactive, null)
                    , decode(iSuspended, 1, GCO_I_LIB_CONSTANT.gcGoodStatusSuspended, null)
                     )
               and V_PPS.C_TYPE_COM = '1'
               and V_PPS.C_KIND_COM in('1', '3')
               and DES1.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetUserLangID
               and DES2.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
               and DES3.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
               and DES4.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
               and DES5.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
               and DES1.GCGNAME(+) = 'C_GOOD_STATUS'
               and DES2.GCGNAME = 'C_DISCHARGE_COM'
               and DES3.GCGNAME = 'C_KIND_COM'
               and DES4.GCGNAME = 'C_REMPLACEMENT_NOM'
               and DES5.GCGNAME = 'C_TYPE_COM'
               and DES1.GCLCODE(+) = GOO.C_GOOD_STATUS
               and DES2.GCLCODE = V_PPS.C_DISCHARGE_COM
               and DES3.GCLCODE = V_PPS.C_KIND_COM
               and DES4.GCLCODE = V_PPS.C_REMPLACEMENT_NOM
               and DES5.GCLCODE = V_PPS.C_TYPE_COM
          order by V_PPS.QUERY_ID_SEQ;

        vSequence  := vSequence + 10000;
      end loop;
    -- si le produit n'a pas de nomenclature, on l'insère quand même, comme élément stérile
    else
      insert into PPS_INTERROGATION
                  (PPS_INTERROGATION_ID
                 , PPI_TEXT
                 , PPI_LEVEL
                 , PPI_NOM_VERSION
                 , PPI_ROOT_REFERENCE
                 , PPS_NOMENCLATURE_ID
                 , PPS_PPS_NOMENCLATURE_ID
                 , GCO_GOOD_ID
                 , C_TYPE_NOM
                 , C_TYPE_NOM_TEXT
                 , COM_REF_QTY
                 , A_DATECRE
                 , A_IDCRE
                  )
        select vSequence
             , GOO.GOO_MAJOR_REFERENCE || '   ' || GOO.GOO_SECONDARY_REFERENCE
             , 1 PPI_LEVEL
             , PCS.PC_FUNCTIONS.TranslateWord('Pas de nomenclature.')
             , iMajorReference
             , null
             , null
             , GOO.GCO_GOOD_ID
             , null
             , null
             , 1   -- COM_REF_QTY
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from GCO_GOOD GOO
         where GOO.GCO_GOOD_ID = iGoodId
           and GOO.C_GOOD_STATUS in
                 (GCO_I_LIB_CONSTANT.gcGoodStatusActive
                , decode(iInactive, 1, GCO_I_LIB_CONSTANT.gcGoodStatusInactive, null)
                , decode(iSuspended, 1, GCO_I_LIB_CONSTANT.gcGoodStatusSuspended, null)
                 );

      vSequence  := vSequence + 1;
    end if;
  end pPrepAlloyNomInterro;

  /**
  * procedure pPrepAlloyUCInterro
  * Description
  *
  * @created fp 13.04.2012
  * @lastUpdate
  * @public
  * @param
  */
  procedure pPrepAlloyUCInterro(
    iMajorReference in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , iGoodId         in GCO_GOOD.GCO_GOOD_ID%type
  , iInactive       in number
  , iSuspended      in number
  )
  is
    type T_GOOD_ID is table of number;

    cursor crInterroExist
    is
      select QUERY_ID_SEQ
        from V_PPS_NOM_BOND_INTERRO;

    tplInterroExist crInterroExist%rowtype;
    TabLeafGood     T_GOOD_ID;
  begin
    declare
      lFound boolean := false;
    begin
      -- Le bien n'a pas de nomenclature, on utilise la vue V_PPS_NOM_BOND_INTERRO
      -- Initialisation de la variable de package pour l'execution de la cmd sql de la vue
      PPS_INIT.SetGoodId(iGoodID);

      for tplInterroExist in (select rownum QUERY_ID_SEQ
                                from (select distinct QUERY_GOOD_ID
                                                 from V_PPS_NOM_BOND_INTERRO
                                                where QUERY_GOOD_ID = iGoodId) ) loop
        lFound  := true;
        -- Insertion de la première ligne correspondant à la nomenclature interrogée
        pPrepAlloyNomInterro(iMajorReference, iGoodId, iInactive, iSuspended);

        -- Insertion des nomenclatures des cas d'emplois
        for tplUseCase in (select distinct GOO.GCO_GOOD_ID
                                         , GOO.GOO_MAJOR_REFERENCE
                                      from V_PPS_NOM_BOND_INTERRO V_PPS
                                         , PPS_NOMENCLATURE NOM
                                         , PPS_NOMENCLATURE PPS_NOM
                                         , GCO_GOOD GOO
                                     where V_PPS.PPS_NOMENCLATURE_ID = NOM.PPS_NOMENCLATURE_ID
                                       and V_PPS.PPS_PPS_NOMENCLATURE_ID = PPS_NOM.PPS_NOMENCLATURE_ID(+)
                                       and GOO.GCO_GOOD_ID = NOM.GCO_GOOD_ID
                                       and NOM.NOM_DEFAULT = 1
                                       and NOM.C_TYPE_NOM = '2'
                                       and PPS_NOM.NOM_DEFAULT(+) = 1
                                       and PPS_NOM.C_TYPE_NOM(+) = '2'
                                       and V_PPS.C_TYPE_COM = '1'
                                       and V_PPS.C_KIND_COM in('1', '3')
                                  order by GOO.GOO_MAJOR_REFERENCE) loop
          pPrepAlloyNomInterro(tplUseCase.GOO_MAJOR_REFERENCE, tplUseCase.GCO_GOOD_ID, iInactive, iSuspended);
        end loop;
      end loop;

      -- Si dans aucune nomenclature que ce soit comme composé ou composant
      if not lFound then
        -- Insertion de la première ligne correspondant à la nomenclature interrogée
        pPrepAlloyNomInterro(iMajorReference, iGoodId, iInactive, iSuspended);
      end if;
    end;
  end pPrepAlloyUCInterro;

  /**
  * procedure pPrepAlloyInterroGood
  * Description
  *   Remplir la table d'interrogation des matières précieuses pour un bien
  * @created fpe 29.03.2012
  * @public
  */
  procedure pPrepAlloyInterroGood(iGoodId in PPS_INTERROGATION.GCO_GOOD_ID%type)
  is
  begin
    for ltplInterroAlloy in (select INIT_ID_SEQ.nextval PPS_INTERRO_ALLOY_ID
                                  , GPM.GCO_GOOD_ID
                                  , GCO_ALLOY_ID
                                  , PPS_LIB_INTERRO.cGpmUpdateTypeNone C_GPM_UPDATE_TYPE
                                  , GPM_WEIGHT
                                  , GPM_REAL_WEIGHT
                                  , GPM_THEORICAL_WEIGHT
                                  , GPM_WEIGHT_DELIVER_AUTO
                                  , GPM_WEIGHT_DELIVER
                                  , GPM_WEIGHT_DELIVER_VALUE
                                  , GPM_WEIGHT_INVEST WI
                                  , GPM_WEIGHT_INVEST
                                  , GPM_WEIGHT_INVEST_TOTAL_VALUE
                                  , GPM_WEIGHT_CHIP
                                  , GPM_WEIGHT_CHIP_TOTAL
                                  , GPM_LOSS_UNIT
                                  , GPM_LOSS_PERCENT
                                  , GPM_LOSS_TOTAL
                                  , GPM_STONE_NUMBER
                                  , GPM_WEIGHT_INVEST_VALUE
                                  , GPM_WEIGHT_INVEST_TOTAL
                               from GCO_PRECIOUS_MAT GPM
                                  , GCO_GOOD GOO
                              where GPM.GCO_GOOD_ID = iGoodId
                                and GOO.GCO_GOOD_ID = GPM.GCO_GOOD_ID
                                and GOO.GOO_PRECIOUS_MAT = 1
                                and not exists(select GCO_ALLOY_ID
                                                 from PPS_INTERRO_ALLOY
                                                where GCO_ALLOY_ID = GPM.GCO_ALLOY_ID
                                                  and GCO_GOOD_ID = GPM.GCO_GOOD_ID) ) loop
      -- table temporaire, volontairement pas d'utilisation du framework pour gain de performances
      insert into PPS_INTERRO_ALLOY
                  (PPS_INTERRO_ALLOY_ID
                 , GCO_GOOD_ID
                 , GCO_ALLOY_ID
                 , C_GPM_UPDATE_TYPE
                 , GPM_WEIGHT
                 , GPM_REAL_WEIGHT
                 , GPM_THEORICAL_WEIGHT
                 , GPM_WEIGHT_DELIVER_AUTO
                 , GPM_WEIGHT_DELIVER
                 , GPM_WEIGHT_DELIVER_VALUE
                 , GPM_WEIGHT_INVEST
                 , GPM_WEIGHT_INVEST_TOTAL_VALUE
                 , GPM_WEIGHT_CHIP
                 , GPM_WEIGHT_CHIP_TOTAL
                 , GPM_LOSS_UNIT
                 , GPM_LOSS_PERCENT
                 , GPM_LOSS_TOTAL
                 , GPM_STONE_NUMBER
                 , GPM_WEIGHT_INVEST_VALUE
                 , GPM_WEIGHT_INVEST_TOTAL
                  )
           values (ltplInterroAlloy.PPS_INTERRO_ALLOY_ID
                 , ltplInterroAlloy.GCO_GOOD_ID
                 , ltplInterroAlloy.GCO_ALLOY_ID
                 , ltplInterroAlloy.C_GPM_UPDATE_TYPE
                 , ltplInterroAlloy.GPM_WEIGHT
                 , ltplInterroAlloy.GPM_REAL_WEIGHT
                 , ltplInterroAlloy.GPM_THEORICAL_WEIGHT
                 , ltplInterroAlloy.GPM_WEIGHT_DELIVER_AUTO
                 , ltplInterroAlloy.GPM_WEIGHT_DELIVER
                 , ltplInterroAlloy.GPM_WEIGHT_DELIVER_VALUE
                 , ltplInterroAlloy.GPM_WEIGHT_INVEST
                 , ltplInterroAlloy.GPM_WEIGHT_INVEST_TOTAL_VALUE
                 , ltplInterroAlloy.GPM_WEIGHT_CHIP
                 , ltplInterroAlloy.GPM_WEIGHT_CHIP_TOTAL
                 , ltplInterroAlloy.GPM_LOSS_UNIT
                 , ltplInterroAlloy.GPM_LOSS_PERCENT
                 , ltplInterroAlloy.GPM_LOSS_TOTAL
                 , ltplInterroAlloy.GPM_STONE_NUMBER
                 , ltplInterroAlloy.GPM_WEIGHT_INVEST_VALUE
                 , ltplInterroAlloy.GPM_WEIGHT_INVEST_TOTAL
                  );
    end loop;
  end pPrepAlloyInterroGood;

  /**
  * procedure pPrepAlloyInterro
  * Description
  *   Remplir la table d'interrogation des matières précieuses en fonction des articles
  *   présents dans PPS_INTERROGATION
  * @created fpe 02.03.2012
  * @public
  */
  procedure pPrepAlloyInterro(iInterroType in varchar2)
  is
  begin
    for ltplGood in (select distinct GCO_GOOD_ID
                                from PPS_INTERROGATION) loop
      pPrepAlloyInterroGood(ltplGood.GCO_GOOD_ID);
    end loop;
  end pPrepAlloyInterro;

  /**
  * procedure pMergeGoodInterroAlloy
  * Description
  *
  * @created fp 23.03.2012
  * @lastUpdate
  * @public
  * @param
  */
  procedure pMergeGoodInterroAlloy(iGoodId PPS_INTERRO_ALLOY.GCO_GOOD_ID%type, iAlloyId PPS_INTERRO_ALLOY.GCO_ALLOY_ID%type)
  is
    ltplAlloy        PPS_INTERRO_ALLOY%rowtype;
    lWeight          number(1)                   := substr(cInitWeightCode, 1, 1);
    lRealWeight      number(1)                   := substr(cInitWeightCode, 3, 1);
    lTheoricalWeight number(1)                   := substr(cInitWeightCode, 5, 1);
  begin
    select *
      into ltplAlloy
      from PPS_INTERRO_ALLOY
     where GCO_GOOD_ID = iGoodId
       and GCO_ALLOY_ID = iAlloyId;
  exception
    when no_data_found then
      insert into PPS_INTERRO_ALLOY
                  (PPS_INTERRO_ALLOY_ID
                 , C_GPM_UPDATE_TYPE
                 , GPM_WEIGHT
                 , GPM_REAL_WEIGHT
                 , GPM_THEORICAL_WEIGHT
                 , GPM_WEIGHT_DELIVER_AUTO
                 , GCO_GOOD_ID
                 , GCO_ALLOY_ID
                 , GPM_WEIGHT_DELIVER
                 , GPM_WEIGHT_DELIVER_VALUE
                 , GPM_WEIGHT_CHIP
                 , GPM_WEIGHT_CHIP_TOTAL
                 , GPM_WEIGHT_INVEST
                 , GPM_WEIGHT_INVEST_TOTAL_VALUE
                 , GPM_STONE_NUMBER
                 , GPM_LOSS_TOTAL
                  )
           values (INIT_ID_SEQ.nextval
                 , PPS_LIB_INTERRO.cGpmUpdateTypeInsert
                 , lWeight
                 , lRealWeight
                 , lTheoricalWeight
                 , 1
                 , iGoodId
                 , iAlloyId
                 , 0
                 , 0
                 , 0
                 , 0
                 , 0
                 , 0
                 , 0
                 , 0
                  );
    when too_many_rows then
      ra('PCS - Too many rows Good : ' || iGoodId || ' /  Alloy : ' || iAlloyId || CO.cLineBreak || sqlerrm || CO.cLineBreak
         || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
        );
  end;

  /**
  * procedure pRecoverUpperLevelPreciousMat
  * Description
  *   Initialise les données matières précieuses en reprenant les pesées des composants
  * @created fp 29.03.2012
  * @lastUpdate
  * @public
  * @param iGoodId : bien à traiter
  */
  procedure pRecoverUpperLevelPreciousMat(iGoodId in PPS_INTERROGATION.GCO_GOOD_ID%type)
  is
  begin
    for ltplComponentAlloy in (select   PIA.GCO_ALLOY_ID
                                   from PPS_INTERRO_ALLOY PIA
                                      , GCO_GOOD GOO
                                      , (select distinct GCO_GOOD_ID
                                                       , COM_UTIL_COEFF
                                                       , COM_REF_QTY
                                                    from PPS_INTERROGATION
                                                   where PPS_NOMENCLATURE_ID =
                                                           (select max(distinct nvl(PPS_PPS_NOMENCLATURE_ID, PPS_NOMENCLATURE_ID) )
                                                              from PPS_INTERROGATION PPI
                                                             where GCO_GOOD_ID = iGoodId
                                                               and exists(
                                                                     select GCO_GOOD_ID
                                                                       from PPS_NOMENCLATURE
                                                                      where PPS_NOMENCLATURE_ID = nvl(PPI.PPS_PPS_NOMENCLATURE_ID, PPI.PPS_NOMENCLATURE_ID)
                                                                        and GCO_GOOD_ID = PPI.GCO_GOOD_ID) )
                                                                                                             /*and PPS_PPS_NOMENCLATURE_ID is not null*/
                                        ) CPN
                                  where PIA.GCO_GOOD_ID = CPN.GCO_GOOD_ID
                                    and GOO.GCO_GOOD_ID = PIA.GCO_GOOD_ID
                                    --and GOO.GOO_PRECIOUS_MAT = 1
                               --and PIA.C_GPM_UPDATE_TYPE <> PPS_LIB_INTERRO.cGpmUpdateTypeDelete
                               group by PIA.GCO_ALLOY_ID) loop
      pMergeGoodInterroAlloy(iGoodId, ltplComponentAlloy.GCO_ALLOY_ID);
    end loop;
  end pRecoverUpperLevelPreciousMat;

  /**
  * procedure pManageRoot
  * Description
  *
  * @created fp 29.03.2012
  * @lastUpdate
  * @public
  * @param
  */
  procedure pManageRoot(iNomenclatureId in PPS_INTERROGATION.GCO_GOOD_ID%type)
  is
  begin
    null;
  end pManageRoot;

  /**
  * procedure pInsertComponent
  * Description
  *
  * @created fp 29.03.2012
  * @lastUpdate
  * @public
  * @param
  */
  procedure pInsertComponent(iNomenclatureId in PPS_INTERROGATION.GCO_GOOD_ID%type)
  is
    lPtGoodId              PPS_NOMENCLATURE.GCO_GOOD_ID%type   := FWK_I_LIB_ENTITY.getNumberFieldFromPk('PPS_NOMENCLATURE', 'GCO_GOOD_ID', iNomenclatureId);
    lPreciousMatManagement number(1)                           := FWK_I_LIB_ENTITY.getNumberFieldFromPk('GCO_GOOD', 'GOO_PRECIOUS_MAT', lPtGoodId);
  begin
    -- insertion des composants qui ne sont pas déjà dans la table d'interrogation
    for ltplComponent in (select 3 PPI_LEVEL
                               , V_PPS.PPS_NOMENCLATURE_ID
                               , V_PPS.PPS_PPS_NOMENCLATURE_ID
                               , V_PPS.PPS_NOM_BOND_ID
                               , V_PPS.PPS_RANGE_OPERATION_ID
                               , V_PPS.GCO_GOOD_ID
                               , NOM.GCO_GOOD_ID PT_GOOD_ID
                               , V_PPS.COM_BEG_VALID
                               , V_PPS.COM_END_VALID
                               , V_PPS.COM_INTERVAL
                               , V_PPS.COM_PDIR_COEFF
                               , V_PPS.COM_POS
                               , V_PPS.COM_REC_PCENT
                               , nvl(V_PPS.COM_REF_QTY, 1) COM_REF_QTY
                               , nvl(V_PPS.COM_REMPLACEMENT, 0) COM_REMPLACEMENT
                               , V_PPS.COM_RES_NUM
                               , V_PPS.COM_RES_TEXT
                               , V_PPS.COM_SEQ
                               , nvl(V_PPS.COM_SUBSTITUT, 0) COM_SUBSTITUT
                               , V_PPS.COM_TEXT
                               , nvl(V_PPS.COM_UTIL_COEFF, 1) COM_UTIL_COEFF
                               , V_PPS.COM_VAL
                            from PPS_NOM_BOND V_PPS
                               , PPS_NOMENCLATURE NOM
                           where V_PPS.PPS_NOMENCLATURE_ID = iNomenclatureId
                             and NOM.PPS_NOMENCLATURE_ID = V_PPS.PPS_NOMENCLATURE_ID
                             and PPS_LIB_INTERRO.IsGoodAlreadyThere(V_PPS.PPS_NOMENCLATURE_ID, V_PPS.PPS_NOMENCLATURE_ID, V_PPS.GCO_GOOD_ID) = 0) loop
      insert into PPS_INTERROGATION
                  (PPS_INTERROGATION_ID
                 , PPI_LEVEL
                 , PPS_NOMENCLATURE_ID
                 , PPS_PPS_NOMENCLATURE_ID
                 , PPS_NOM_BOND_ID
                 , PPS_RANGE_OPERATION_ID
                 , GCO_GOOD_ID
                 , COM_BEG_VALID
                 , COM_END_VALID
                 , COM_INTERVAL
                 , COM_PDIR_COEFF
                 , COM_POS
                 , COM_REC_PCENT
                 , COM_REF_QTY
                 , COM_REMPLACEMENT
                 , COM_RES_NUM
                 , COM_RES_TEXT
                 , COM_SEQ
                 , COM_SUBSTITUT
                 , COM_TEXT
                 , COM_UTIL_COEFF
                 , COM_VAL
                 , A_RECSTATUS
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (INIT_ID_SEQ.nextval
                 , ltplComponent.PPI_LEVEL
                 , ltplComponent.PPS_NOMENCLATURE_ID
                 , ltplComponent.PPS_PPS_NOMENCLATURE_ID
                 , ltplComponent.PPS_NOM_BOND_ID
                 , ltplComponent.PPS_RANGE_OPERATION_ID
                 , ltplComponent.GCO_GOOD_ID
                 , ltplComponent.COM_BEG_VALID
                 , ltplComponent.COM_END_VALID
                 , ltplComponent.COM_INTERVAL
                 , ltplComponent.COM_PDIR_COEFF
                 , ltplComponent.COM_POS
                 , ltplComponent.COM_REC_PCENT
                 , ltplComponent.COM_REF_QTY
                 , ltplComponent.COM_REMPLACEMENT
                 , ltplComponent.COM_RES_NUM
                 , ltplComponent.COM_RES_TEXT
                 , ltplComponent.COM_SEQ
                 , ltplComponent.COM_SUBSTITUT
                 , ltplComponent.COM_TEXT
                 , ltplComponent.COM_UTIL_COEFF
                 , ltplComponent.COM_VAL
                 , 2
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      -- Charge les matières précieuses du composant inséré
      pPrepAlloyInterroGood(ltplComponent.GCO_GOOD_ID);

      -- Si le produit a une nomenclature de production par défaut, il faut insérer ses composants
      if ltplComponent.PPS_PPS_NOMENCLATURE_ID is not null then
        pInsertComponent(ltplComponent.PPS_PPS_NOMENCLATURE_ID);
      end if;
    end loop;

    -- si le produit gère les matières précieuses
    if lPreciousMatManagement = 1 then
      pRecoverUpperLevelPreciousMat(lptGoodId);
    end if;
  end pInsertComponent;

  /**
  * procedure pInsertUseCaseGood
  * Description
  *
  * @created fp 28.03.2012
  * @lastUpdate
  * @public
  * @param iNomenclatureId : id nomenclature fils
  * @param iGoodId : id bien fils
  */
  procedure pInsertUseCaseGood(
    iNomenclatureId in PPS_INTERROGATION.PPS_NOMENCLATURE_ID%type default null
  , iGoodId         in PPS_INTERROGATION.GCO_GOOD_ID%type default null
  )
  is
    lFound                 boolean   := false;
    lPreciousMatManagement number(1) := FWK_I_LIB_ENTITY.getNumberFieldFromPk('GCO_GOOD', 'GOO_PRECIOUS_MAT', iGoodId);
  begin
    -- recherche des biens "parent" selon les nomenclatures de production par défaut
    for ltplUseCaseGood in (select NOM.GCO_GOOD_ID
                                 , NOM.PPS_NOMENCLATURE_ID
                              from PPS_NOMENCLATURE NOM
                                 , PPS_NOM_BOND BON
                             where BON.PPS_NOMENCLATURE_ID = NOM.PPS_NOMENCLATURE_ID
                               and BON.GCO_GOOD_ID = iGoodId
                               and NOM.NOM_DEFAULT = 1
                               and NOM.C_TYPE_NOM = PPS_LIB_FUNCTIONS.cTypeNomProd) loop
      declare
        lPresenceMode number(1)                            := PPS_LIB_INTERRO.IsGoodAlreadyThere(ltplUseCaseGood.PPS_NOMENCLATURE_ID, iNomenclatureId, iGoodId);
        lGoodId       PPS_INTERROGATION.GCO_GOOD_ID%type;
      begin
        lFound  := true;

        if lPresenceMode = 0 then
          if iNomenclatureId is null then
            lGoodId  := FWK_I_LIB_ENTITY.getNumberFieldFromPk('PPS_NOMENCLATURE', 'GCO_GOOD_ID', ltplUseCaseGood.PPS_NOMENCLATURE_ID);
          else
            lGoodId  := iGoodId;
          end if;

          -- Insertion de la première ligne correspondant à la nomenclature interrogée
          insert into PPS_INTERROGATION
                      (PPS_INTERROGATION_ID
                     , PPI_LEVEL
                     , PPS_NOMENCLATURE_ID
                     , PPS_PPS_NOMENCLATURE_ID
                     , GCO_GOOD_ID
                     , COM_UTIL_COEFF
                     , A_RECSTATUS
                     , A_DATECRE
                     , A_IDCRE
                      )
               values (vSequence
                     , 0
                     , ltplUseCaseGood.PPS_NOMENCLATURE_ID
                     , iNomenclatureId
                     , lGoodId
                     , 1
                     , '1'
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                      );

          vSequence  := vSequence + 1;
          -- reprise des informations actuelle de GCO_PRECIOUS_MAT
          pPrepAlloyInterroGood(lGoodId);
        end if;

        if lPreciousMatManagement = 1 then
          -- insertion des composants de nomenclature non encore présent dans la table PPS_INTERROGATION (inclu la reprise des matières précieuses)
          pInsertComponent(ltplUseCaseGood.PPS_NOMENCLATURE_ID);
        -- merge des informations reprises des composants
        --pRecoverUpperLevelPreciousMat(lGoodId);
        end if;

        pInsertUseCaseGood(ltplUseCaseGood.PPS_NOMENCLATURE_ID, ltplUseCaseGood.GCO_GOOD_ID);
      end;

      vSequence  := vSequence + 1;
    end loop;

    -- Si on est sur une racine de nomenclature, il faut insérer une ligne sans lien
    if     not lFound
       and PPS_LIB_INTERRO.IsGoodAlreadyThere(iNomenclatureId, null, iGoodId) = 0 then
      insert into PPS_INTERROGATION
                  (PPS_INTERROGATION_ID
                 , PPI_LEVEL
                 , PPS_NOMENCLATURE_ID
                 , GCO_GOOD_ID
                 , COM_UTIL_COEFF
                 , A_RECSTATUS
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (vSequence
                 , 0
                 , iNomenclatureId
                 , iGoodId
                 , 1
                 , '1'
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      pPrepAlloyInterroGood(iGoodId);
      vSequence  := vSequence + 1;
    end if;
  end pInsertUseCaseGood;

  /**
  * procedure pSearchForPt
  * Description
  *   Descente dans les cas d'emplois afin de retrouver les PT et de les insérer dans COM_LIST_ID_TEMP
  * @created fp 13.04.2012
  * @lastUpdate
  * @public
  */
  procedure pSearchForPt(iCptNomenclatureId in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type, iGoodId in PPS_NOMENCLATURE.GCO_GOOD_ID%type)
  is
    lFound boolean := false;
  begin
    for ltplUpperLevel in (select PPS_NOMENCLATURE_ID
                                , GCO_GOOD_ID
                             from PPS_INTERROGATION
                            where PPS_PPS_NOMENCLATURE_ID = iCptNomenclatureId) loop
      lFound  := true;
      pSearchForPt(ltplUpperLevel.PPS_NOMENCLATURE_ID, ltplUpperLevel.GCO_GOOD_ID);
    end loop;

    if not lFound then
      SelectProduct(iGoodId, false);
    end if;
  end pSearchForPt;

  /**
  * procedure pSelectTPGoods
  * Description
  *
  * @created fp 13.04.2012
  * @lastUpdate
  * @public
  */
  procedure pSelectTPGoods
  is
    type tNomList is record(
      PPS_NOMENCLATURE_ID PPS_INTERROGATION.PPS_NOMENCLATURE_ID%type
    , GCO_GOOD_ID         PPS_NOMENCLATURE.GCO_GOOD_ID%type
    );

    type ttNomList is table of tNomList;

    ltNomList ttNomList;
  begin
    -- on vide la liste des biens dans COM_LIST_ID_TEMP ...
    COM_I_PRC_LIST_ID_TEMP.ClearIDList;

    -- supression des données use case (sauf les alliages du PT)
    delete from PPS_INTERRO_ALLOY
          where GCO_GOOD_ID not in(select GCO_GOOD_ID
                                     from PPS_INTERROGATION
                                    where PPI_LEVEL = 1);

    select PPS_NOMENCLATURE_ID
         , GCO_GOOD_ID
    bulk collect into ltNomList
      from PPS_INTERROGATION
     where PPI_LEVEL = 2;

    -- ... et on la remplace par les produits terminés des cas d'emplois
    if ltNomList.count > 0 then
      for i in ltNomList.first .. ltNomList.last loop
        pSearchForPt(ltNomList(i).PPS_NOMENCLATURE_ID, ltNomList(i).GCO_GOOD_ID);
      end loop;
    end if;

    -- clear de la table d'interrogation en mode Use Case
    delete from PPS_INTERROGATION;
  end;

  /**
  * procedure pAddUseCasesInInterro
  * Description
  *   Ajour des cas d'emploi dans la table d'interrogation avant de procéder
  *   à la mise à jour des matières précieuses
  * @created fp 28.03.2012
  * @lastUpdate
  * @public
  */
  procedure pAddUseCasesInInterro
  is
    type tNomList is record(
      PPS_NOMENCLATURE_ID PPS_INTERROGATION.PPS_NOMENCLATURE_ID%type
    , GCO_GOOD_ID         PPS_NOMENCLATURE.GCO_GOOD_ID%type
    );

    type ttNomList is table of tNomList;

    lttNomList ttNomList;
  begin
    /* Sélections des nomenclatures sur lesquelles les modifications ont un impact (PPS_I_LIB_INTERRO.IsAlloyGood(NOM.GCO_GOOD_ID) = 2).
       On sélectionne également les produits présents dans la liste de sélection initiale (COM_LIST_ID_TEMP). L'appel depuis les Produits,
       suite à modification des matières précieuses ne montre aucun changement sur le produit en cours mais aura une répercussion sur ses cas d'emploi. */
    select distinct PPI.PPS_PPS_NOMENCLATURE_ID
                  , PPI.GCO_GOOD_ID
    bulk collect into lttNomList
               from PPS_INTERROGATION PPI
              where PPS_I_LIB_INTERRO.IsAlloyGood(PPI.GCO_GOOD_ID) = 2
                 or exists(select *
                             from COM_LIST_ID_TEMP
                            where LID_CODE = 'GCO_GOOD_ID'
                              and COM_LIST_ID_TEMP_ID = PPI.GCO_GOOD_ID);

    -- pour chaque nomenclature on recherche les cas d'emplois (appel récursif)
    if lttNomList.count > 0 then
      for lIndex in lttNomList.first .. lttNomList.last loop
        pInsertUseCaseGood(lttNomList(lIndex).PPS_NOMENCLATURE_ID, lttNomList(lIndex).GCO_GOOD_ID);
      end loop;
    end if;
  end pAddUseCasesInInterro;

  /**
  * procedure PrepAlloyUpperLevelsInterro
  * Description
  *   Rempli les niveaux supérieurs en remontant les nomenclatures
  * @created fpe 23.03.2012
  * @public
  */
  procedure PrepAlloyUpperLevelsInterro
  is
  begin
    -- Traitement des niveaux de composants
    for ltplGood in (select   PPI.GCO_GOOD_ID
                            , max(PPI.PPI_LEVEL) PPI_LEVEL
                         from PPS_INTERROGATION PPI
                            , GCO_GOOD GOO
                        where PPI.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                          and GOO_PRECIOUS_MAT = 1
                     group by PPI.GCO_GOOD_ID
                     order by 2 desc
                            , 1) loop
      pRecoverUpperLevelPreciousMat(ltplGood.GCO_GOOD_ID);
    end loop;

    -- traitement particulier du premier niveau de nomenclature
    for ltplGood in (select   GCO_GOOD_ID
                            , max(PPI_LEVEL) PPI_LEVEL
                         from PPS_INTERROGATION
                     group by GCO_GOOD_ID
                     order by 2 desc
                            , 1) loop
      for ltplComponentAlloy1stLEvel in (select   PIA.GCO_ALLOY_ID
                                             from PPS_INTERRO_ALLOY PIA
                                                , GCO_GOOD GOO
                                                , (select distinct GCO_GOOD_ID
                                                                 , COM_UTIL_COEFF
                                                                 , COM_REF_QTY
                                                              from PPS_INTERROGATION
                                                             where PPS_NOMENCLATURE_ID = (select max(PPS_NOMENCLATURE_ID)
                                                                                            from PPS_INTERROGATION
                                                                                           where PPI_LEVEL = 1
                                                                                             and GCO_GOOD_ID = ltplGood.GCO_GOOD_ID)
                                                               and PPI_LEVEL = 2) CPN
                                            where PIA.GCO_GOOD_ID = CPN.GCO_GOOD_ID
                                              and GOO.GCO_GOOD_ID = PIA.GCO_GOOD_ID
                                              and GOO.GOO_PRECIOUS_MAT = 1
                                         group by PIA.GCO_ALLOY_ID) loop
        pMergeGoodInterroAlloy(ltplGood.GCO_GOOD_ID, ltplComponentAlloy1stLEvel.GCO_ALLOY_ID);
      end loop;
    end loop;
  end PrepAlloyUpperLevelsInterro;

  /**
  * procedure MergeGoodInterroAlloy
  * Description
  *   Mise à jour de la table de travail de l'interrogation alliage, après calcul
  * @created eca
  * @public
  */
  procedure MergeGoodInterroAlloy(
    iGcoGoodId                     in GCO_PRECIOUS_MAT.GCO_GOOD_ID%type
  , iGcoAlloyId                    in GCO_PRECIOUS_MAT.GCO_ALLOY_ID%type
  , iGPM_WEIGHT_DELIVER            in GCO_PRECIOUS_MAT.GPM_WEIGHT_DELIVER%type default 0
  , iGPM_WEIGHT_DELIVER_VALUE      in GCO_PRECIOUS_MAT.GPM_WEIGHT_DELIVER_VALUE%type default 0
  , iGPM_WEIGHT_INVEST             in GCO_PRECIOUS_MAT.GPM_WEIGHT_INVEST%type default 0
  , iGPM_WEIGHT_INVEST_VALUE       in GCO_PRECIOUS_MAT.GPM_WEIGHT_INVEST_VALUE%type default 0
  , iGPM_WEIGHT_INVEST_TOTAL       in GCO_PRECIOUS_MAT.GPM_WEIGHT_INVEST_TOTAL%type default 0
  , iGPM_WEIGHT_INVEST_TOTAL_VALUE in GCO_PRECIOUS_MAT.GPM_WEIGHT_INVEST_TOTAL_VALUE%type default 0
  , iGPM_WEIGHT_CHIP               in GCO_PRECIOUS_MAT.GPM_WEIGHT_CHIP%type default 0
  , iGPM_WEIGHT_CHIP_TOTAL         in GCO_PRECIOUS_MAT.GPM_WEIGHT_CHIP_TOTAL%type default 0
  , iGPM_LOSS_TOTAL                in GCO_PRECIOUS_MAT.GPM_LOSS_TOTAL%type default 0
  , iGPM_STONE_NUMBER              in GCO_PRECIOUS_MAT.GPM_STONE_NUMBER%type default 0
  )
  is
  begin
    update PPS_INTERRO_ALLOY
       set GPM_WEIGHT_DELIVER = iGPM_WEIGHT_DELIVER
         , GPM_WEIGHT_DELIVER_VALUE = nvl(iGPM_WEIGHT_DELIVER_VALUE, 0)
         , GPM_WEIGHT_INVEST = iGPM_WEIGHT_INVEST
         , GPM_WEIGHT_INVEST_VALUE = nvl(iGPM_WEIGHT_INVEST_VALUE, 0)
         , GPM_WEIGHT_INVEST_TOTAL = nvl(iGPM_WEIGHT_INVEST_TOTAL, 0)
         , GPM_WEIGHT_INVEST_TOTAL_VALUE = nvl(iGPM_WEIGHT_INVEST_TOTAL_VALUE, 0)
         , GPM_WEIGHT_CHIP = nvl(iGPM_WEIGHT_CHIP, 0)
         , GPM_WEIGHT_CHIP_TOTAL = nvl(iGPM_WEIGHT_CHIP_TOTAL, 0)
         , GPM_LOSS_TOTAL = nvl(iGPM_LOSS_TOTAL, 0)
         , GPM_STONE_NUMBER = iGPM_STONE_NUMBER
         , C_GPM_UPDATE_TYPE =
             (case
                when(C_GPM_UPDATE_TYPE = PPS_LIB_INTERRO.cGpmUpdateTypeInsert)
                 or (C_GPM_UPDATE_TYPE = PPS_LIB_INTERRO.cGpmUpdateTypeDelete) then C_GPM_UPDATE_TYPE
                else PPS_LIB_INTERRO.cGpmUpdateTypeUpdate
              end
             )
     where GCO_GOOD_ID = iGcoGoodId
       and GCO_ALLOY_ID = iGcoAlloyId
       and (    (   nvl(GPM_WEIGHT_DELIVER, 0) <> nvl(iGPM_WEIGHT_DELIVER, 0)
                 or nvl(GPM_WEIGHT_DELIVER_VALUE, 0) <> nvl(iGPM_WEIGHT_DELIVER_VALUE, 0)
                 or nvl(GPM_WEIGHT_INVEST, 0) <> nvl(iGPM_WEIGHT_INVEST, 0)
                 or nvl(GPM_WEIGHT_INVEST_VALUE, 0) <> nvl(iGPM_WEIGHT_INVEST_VALUE, 0)
                 or nvl(GPM_WEIGHT_INVEST_TOTAL, 0) <> nvl(iGPM_WEIGHT_INVEST_TOTAL, 0)
                 or nvl(GPM_WEIGHT_INVEST_TOTAL_VALUE, 0) <> nvl(iGPM_WEIGHT_INVEST_TOTAL_VALUE, 0)
                 or nvl(GPM_WEIGHT_CHIP, 0) <> nvl(iGPM_WEIGHT_CHIP, 0)
                 or nvl(GPM_WEIGHT_CHIP_TOTAL, 0) <> nvl(iGPM_WEIGHT_CHIP_TOTAL, 0)
                 or nvl(GPM_LOSS_TOTAL, 0) <> nvl(iGPM_LOSS_TOTAL, 0)
                 or nvl(GPM_STONE_NUMBER, 0) <> nvl(iGPM_STONE_NUMBER, 0)
                )
            or (   GPM_WEIGHT_DELIVER_VALUE is null
                or GPM_WEIGHT_INVEST_VALUE is null)
           );
  end MergeGoodInterroAlloy;

  /**
  * procedure PrepareGcoAlloyCalc
  * Description
  *   Remplir la table de l'interrogation nomenclature en fonction de la liste de biens
  *   contenue dans COM_LIST_ID_TEMP
  * @created fpe 01.03.2012
  * @public
  */
  procedure PrepareGcoAlloyCalc(iInterroType in varchar2, iInactive in number, iSuspended in number, iPurge in number default 0)
  is
  begin
    -- Effacer les données de la table de l'interrogation
    if iPurge = 1 then
      delete from PPS_INTERRO_ALLOY;

      delete from PPS_INTERROGATION;
    end if;

    -- extraction des nomenclatures pour tous les biens contenus dans COM_LIST_ID_TEMP
    for ltplGood in (select distinct COM_LIST_ID_TEMP_ID
                                   , GOO_MAJOR_REFERENCE
                                from COM_LIST_ID_TEMP
                                   , GCO_GOOD GOO
                               where LID_CODE = 'GCO_GOOD_ID'
                                 and GOO.C_GOOD_STATUS in
                                       (GCO_I_LIB_CONSTANT.gcGoodStatusActive
                                      , decode(iInactive, 1, GCO_I_LIB_CONSTANT.gcGoodStatusInactive, null)
                                      , decode(iSuspended, 1, GCO_I_LIB_CONSTANT.gcGoodStatusSuspended, null)
                                       )
                                 and GCO_GOOD_ID = COM_LIST_ID_TEMP_ID) loop
      begin
        -- Interrogation des nomenclatures des produits sélectionnés
        if iInterroType = 'NOM' then
          pPrepAlloyNomInterro(ltplGood.GOO_MAJOR_REFERENCE, ltplGood.COM_LIST_ID_TEMP_ID, iInactive, iSuspended);
        -- Interrogation des nomenclatures des cas d'emplois des produits sélectionnés
        else
          pPrepAlloyUCInterro(ltplGood.GOO_MAJOR_REFERENCE, ltplGood.COM_LIST_ID_TEMP_ID, iInactive, iSuspended);
        end if;
      exception
        when others then
          begin
            if sqlcode = -1436 then
              Raise_application_error(-20001, PCS.PC_FUNCTIONS.TranslateWord('La nomenclature du produit est circulaire :') || ltplGood.GOO_MAJOR_REFERENCE);
            else
              raise;
            end if;
          end;
      end;
    end loop;

    -- Pour tous les biens présents dans l'interro, extraction des données matières précieuses
    pPrepAlloyInterro(iInterroType);
    -- calcul des niveaux du dessous
    PrepAlloyUpperLevelsInterro;
    -- Calcul et reprise des différents poids
    GCO_PRECIOUS_MAT_FUNCTIONS.UpdateWeightAndChip(iInactive, iSuspended);
  --pCopyInterroDebug;
  end PrepareGcoAlloyCalc;

  /**
  * procedure PrepareNomenclatureInterro
  * Description
  *   Remplir la table de l'interrogation nomenclature avec les données concernant
  *     l'interrogation de type : "Interrogation nomenclature"
  */
  procedure PrepareNomenclatureInterro(aNomenclatureID in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type, aPurge in boolean default true)
  is
  begin
    -- Effacer les données de la table de l'interrogation
    if aPurge then
      delete from PPS_INTERROGATION;
    end if;

    -- Insertion de la première ligne correspondant à la nomenclature interrogée
    insert into PPS_INTERROGATION
                (PPS_INTERROGATION_ID
               , PPI_TEXT
               , PPI_LEVEL
               , PPI_NOM_VERSION
               , PPS_NOMENCLATURE_ID
               , PPS_PPS_NOMENCLATURE_ID
               , GCO_GOOD_ID
               , C_TYPE_NOM
               , C_TYPE_NOM_TEXT
               , A_DATECRE
               , A_IDCRE
                )
      select vSequence
           , GOO.GOO_MAJOR_REFERENCE || '   ' || GOO.GOO_SECONDARY_REFERENCE
           , 1 PPI_LEVEL
           , NOM.NOM_VERSION || decode(NOM.NOM_DEFAULT, 1, ' - ' || PCS.PC_FUNCTIONS.TranslateWord('Défaut') )
           , NOM.PPS_NOMENCLATURE_ID
           , null
           , NOM.GCO_GOOD_ID
           , NOM.C_TYPE_NOM
           , '( ' || DES.GCLCODE || ' ) ' || DES.GCDTEXT1 C_TYPE_NOM_TEXT
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from PPS_NOMENCLATURE NOM
           , GCO_GOOD GOO
           , PCS.V_PC_DESCODES DES
       where NOM.PPS_NOMENCLATURE_ID = aNomenclatureID
         and NOM.GCO_GOOD_ID = GOO.GCO_GOOD_ID
         and NOM.C_TYPE_NOM = DES.GCLCODE
         and DES.GCGNAME = 'C_TYPE_NOM'
         and DES.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID;

    vSequence  := vSequence + 10000;
    -- Initialisation de la variable de package pour l'execution de la cmd sql de la vue
    PPS_INIT.SetNomId(aNomenclatureID);

    -- Insertion des composants de la nomenclature interrogée
    insert into PPS_INTERROGATION
                (PPS_INTERROGATION_ID
               , PPI_TEXT
               , PPI_LEVEL
               , PPI_NOM_VERSION
               , PPS_NOMENCLATURE_ID
               , PPS_PPS_NOMENCLATURE_ID
               , PPS_NOM_BOND_ID
               , PPS_RANGE_OPERATION_ID
               , GCO_GOOD_ID
               , STM_STOCK_ID
               , STM_LOCATION_ID
               , FAL_SCHEDULE_STEP_ID
               , C_GOOD_STATUS
               , C_GOOD_STATUS_TEXT
               , C_DISCHARGE_COM
               , C_DISCHARGE_COM_TEXT
               , C_KIND_COM
               , C_KIND_COM_TEXT
               , C_REMPLACEMENT_NOM
               , C_REMPLACEMENT_NOM_TEXT
               , C_TYPE_COM
               , C_TYPE_COM_TEXT
               , C_TYPE_NOM
               , C_TYPE_NOM_TEXT
               , COM_BEG_VALID
               , COM_END_VALID
               , COM_INTERVAL
               , COM_PDIR_COEFF
               , COM_POS
               , COM_REC_PCENT
               , COM_REF_QTY
               , COM_REMPLACEMENT
               , COM_RES_NUM
               , COM_RES_TEXT
               , COM_SEQ
               , COM_SUBSTITUT
               , COM_TEXT
               , COM_UTIL_COEFF
               , COM_VAL
               , A_DATECRE
               , A_IDCRE
                )
      select   vSequence + V_PPS.QUERY_ID_SEQ
             , V_PPS.COM_SEQ ||
               '   ' ||
               decode(nvl(GOO.GCO_GOOD_ID, -1)
                    , -1, PCS.PC_FUNCTIONS.TranslateWord('Lien texte')
                    , GOO.GOO_MAJOR_REFERENCE || '   ' || GOO.GOO_SECONDARY_REFERENCE
                     )
             , V_PPS.LEVEL_NOM + 1
             , PPS_NOM.NOM_VERSION || decode(PPS_NOM.NOM_DEFAULT, 1, ' - ' || PCS.PC_FUNCTIONS.TranslateWord('Défaut') )
             , V_PPS.PPS_NOMENCLATURE_ID
             , V_PPS.PPS_PPS_NOMENCLATURE_ID
             , V_PPS.PPS_NOM_BOND_ID
             , V_PPS.PPS_RANGE_OPERATION_ID
             , GOO.GCO_GOOD_ID
             , V_PPS.STM_STOCK_ID
             , V_PPS.STM_LOCATION_ID
             , V_PPS.FAL_SCHEDULE_STEP_ID
             , DES1.GCLCODE C_GOOD_STATUS
             , decode(nvl(GOO.GCO_GOOD_ID, -1), -1, null, '( ' || DES1.GCLCODE || ' ) ' || DES1.GCDTEXT1) C_GOOD_STATUS_TEXT
             , DES2.GCLCODE C_DISCHARGE_COM
             , '( ' || DES2.GCLCODE || ' ) ' || DES2.GCDTEXT1 C_DISCHARGE_COM_TEXT
             , DES3.GCLCODE C_KIND_COM
             , '( ' || DES3.GCLCODE || ' ) ' || DES3.GCDTEXT1 C_KIND_COM_TEXT
             , DES4.GCLCODE C_REMPLACEMENT_NOM
             , '( ' || DES4.GCLCODE || ' ) ' || DES4.GCDTEXT1 C_REMPLACEMENT_NOM_TEXT
             , DES5.GCLCODE C_TYPE_COM
             , '( ' || DES5.GCLCODE || ' ) ' || DES5.GCDTEXT1 C_TYPE_COM_TEXT
             , null C_TYPE_NOM
             , null C_TYPE_NOM_TEXT
             , V_PPS.COM_BEG_VALID
             , V_PPS.COM_END_VALID
             , V_PPS.COM_INTERVAL
             , V_PPS.COM_PDIR_COEFF
             , V_PPS.COM_POS
             , V_PPS.COM_REC_PCENT
             , V_PPS.COM_REF_QTY
             , nvl(V_PPS.COM_REMPLACEMENT, 0)
             , V_PPS.COM_RES_NUM
             , V_PPS.COM_RES_TEXT
             , V_PPS.COM_SEQ
             , nvl(V_PPS.COM_SUBSTITUT, 0)
             , V_PPS.COM_TEXT
             , V_PPS.COM_UTIL_COEFF
             , V_PPS.COM_VAL
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from V_PPS_NOMENCLATURE_INTERRO V_PPS
             , PPS_NOMENCLATURE NOM
             , PPS_NOMENCLATURE PPS_NOM
             , GCO_GOOD GOO
             , PCS.V_PC_DESCODES DES1
             , PCS.V_PC_DESCODES DES2
             , PCS.V_PC_DESCODES DES3
             , PCS.V_PC_DESCODES DES4
             , PCS.V_PC_DESCODES DES5
         where V_PPS.PPS_NOMENCLATURE_ID = NOM.PPS_NOMENCLATURE_ID
           and V_PPS.PPS_PPS_NOMENCLATURE_ID = PPS_NOM.PPS_NOMENCLATURE_ID(+)
           and V_PPS.GCO_GOOD_ID = GOO.GCO_GOOD_ID(+)
           and DES1.PC_LANG_ID(+) = PCS.PC_I_LIB_SESSION.GetUserLangID
           and DES2.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
           and DES3.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
           and DES4.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
           and DES5.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
           and DES1.GCGNAME(+) = 'C_GOOD_STATUS'
           and DES2.GCGNAME = 'C_DISCHARGE_COM'
           and DES3.GCGNAME = 'C_KIND_COM'
           and DES4.GCGNAME = 'C_REMPLACEMENT_NOM'
           and DES5.GCGNAME = 'C_TYPE_COM'
           and DES1.GCLCODE(+) = GOO.C_GOOD_STATUS
           and DES2.GCLCODE = V_PPS.C_DISCHARGE_COM
           and DES3.GCLCODE = V_PPS.C_KIND_COM
           and DES4.GCLCODE = V_PPS.C_REMPLACEMENT_NOM
           and DES5.GCLCODE = V_PPS.C_TYPE_COM
      order by V_PPS.QUERY_ID_SEQ;

    vSequence  := vSequence + 10000;
  end PrepareNomenclatureInterro;

  /**
  * procedure PrepareGoodInterro
  * Description
  *   Remplir la table de l'interrogation nomenclature avec les données concernant
  *     l'interrogation de type : "Interrogation cas d'emploi produit"
  */
  procedure PrepareGoodInterro(aGoodID in GCO_GOOD.GCO_GOOD_ID%type)
  is
    cursor crInterroExist
    is
      select QUERY_ID_SEQ
        from V_PPS_NOM_BOND_INTERRO;

    tplInterroExist crInterroExist%rowtype;
    iCountNom       integer;
  begin
    -- Effacer les données de la table de l'interrogation
    delete from PPS_INTERROGATION;

    -- Le nbr de nomenclatures du bien à interroger
    select count(PPS_NOMENCLATURE_ID)
      into iCountNom
      from PPS_NOMENCLATURE
     where GCO_GOOD_ID = aGoodID
       and C_TYPE_NOM <> '6';

    -- Si le bien possède des nomenclatures, on balaye les nomenclatures de celui-ci et
    -- on utilise "Interrogation cas d'emploi version nomenclature"
    if iCountNom <> 0 then
      -- Initialisation de la variable de package pour l'execution de la cmd sql de la vue
      for tplNomList in (select   PPS_NOMENCLATURE_ID
                             from PPS_NOMENCLATURE
                            where GCO_GOOD_ID = aGoodID
                         order by NOM_DEFAULT desc
                                , NOM_VERSION) loop
        PrepareGoodNomInterro(tplNomList.PPS_NOMENCLATURE_ID, 0);
        vSequence  := vSequence + 10000;
      end loop;

      PrepareGoodNoLinkNomInterro(aGoodID, 0);
    else
      -- Le bien n'a pas de nomenclature, on utilise la vue V_PPS_NOM_BOND_INTERRO
      -- Initialisation de la variable de package pour l'execution de la cmd sql de la vue
      PPS_INIT.SetGoodId(aGoodID);

      open crInterroExist;

      fetch crInterroExist
       into tplInterroExist;

      if crInterroExist%found then
        -- Insertion de la première ligne correspondant à la nomenclature interrogée
        insert into PPS_INTERROGATION
                    (PPS_INTERROGATION_ID
                   , PPI_TEXT
                   , PPI_LEVEL
                   , PPS_NOMENCLATURE_ID
                   , PPS_PPS_NOMENCLATURE_ID
                   , GCO_GOOD_ID
                   , A_DATECRE
                   , A_IDCRE
                    )
          select vSequence
               , GOO.GOO_MAJOR_REFERENCE
               , 1
               , null
               , null
               , GOO.GCO_GOOD_ID
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
            from GCO_GOOD GOO
           where GOO.GCO_GOOD_ID = aGoodID;

        vSequence  := vSequence + 1;

        -- Insertion des composants de la nomenclature interrogée
        insert into PPS_INTERROGATION
                    (PPS_INTERROGATION_ID
                   , PPI_TEXT
                   , PPI_LEVEL
                   , PPI_NOM_VERSION
                   , PPS_NOMENCLATURE_ID
                   , PPS_PPS_NOMENCLATURE_ID
                   , PPS_NOM_BOND_ID
                   , PPS_RANGE_OPERATION_ID
                   , GCO_GOOD_ID
                   , STM_STOCK_ID
                   , STM_LOCATION_ID
                   , FAL_SCHEDULE_STEP_ID
                   , C_GOOD_STATUS
                   , C_GOOD_STATUS_TEXT
                   , C_DISCHARGE_COM
                   , C_DISCHARGE_COM_TEXT
                   , C_KIND_COM
                   , C_KIND_COM_TEXT
                   , C_REMPLACEMENT_NOM
                   , C_REMPLACEMENT_NOM_TEXT
                   , C_TYPE_COM
                   , C_TYPE_COM_TEXT
                   , C_TYPE_NOM
                   , C_TYPE_NOM_TEXT
                   , COM_BEG_VALID
                   , COM_END_VALID
                   , COM_INTERVAL
                   , COM_PDIR_COEFF
                   , COM_POS
                   , COM_REC_PCENT
                   , COM_REF_QTY
                   , COM_REMPLACEMENT
                   , COM_RES_NUM
                   , COM_RES_TEXT
                   , COM_SEQ
                   , COM_SUBSTITUT
                   , COM_TEXT
                   , COM_UTIL_COEFF
                   , COM_VAL
                   , A_DATECRE
                   , A_IDCRE
                    )
          select   vSequence + V_PPS.QUERY_ID_SEQ
                 , V_PPS.COM_SEQ ||
                   '   ' ||
                   decode(nvl(GOO.GCO_GOOD_ID, -1)
                        , -1, PCS.PC_FUNCTIONS.TranslateWord('Lien texte')
                        , GOO.GOO_MAJOR_REFERENCE || '   ' || GOO.GOO_SECONDARY_REFERENCE
                         )
                 , V_PPS.LEVEL_NOM + 1
                 , NOM.NOM_VERSION
                 , V_PPS.PPS_NOMENCLATURE_ID
                 , V_PPS.PPS_PPS_NOMENCLATURE_ID
                 , V_PPS.PPS_NOM_BOND_ID
                 , V_PPS.PPS_RANGE_OPERATION_ID
                 , GOO.GCO_GOOD_ID
                 , V_PPS.STM_STOCK_ID
                 , V_PPS.STM_LOCATION_ID
                 , V_PPS.FAL_SCHEDULE_STEP_ID
                 , DES1.GCLCODE C_GOOD_STATUS
                 , '( ' || DES1.GCLCODE || ' ) ' || DES1.GCDTEXT1 C_GOOD_STATUS_TEXT
                 , DES2.GCLCODE C_DISCHARGE_COM
                 , '( ' || DES2.GCLCODE || ' ) ' || DES2.GCDTEXT1 C_DISCHARGE_COM_TEXT
                 , DES3.GCLCODE C_KIND_COM
                 , '( ' || DES3.GCLCODE || ' ) ' || DES3.GCDTEXT1 C_KIND_COM_TEXT
                 , DES4.GCLCODE C_REMPLACEMENT_NOM
                 , '( ' || DES4.GCLCODE || ' ) ' || DES4.GCDTEXT1 C_REMPLACEMENT_NOM_TEXT
                 , DES5.GCLCODE C_TYPE_COM
                 , '( ' || DES5.GCLCODE || ' ) ' || DES5.GCDTEXT1 C_TYPE_COM_TEXT
                 , DES6.GCLCODE C_TYPE_NOM
                 , '( ' || DES6.GCLCODE || ' ) ' || DES6.GCDTEXT1 C_TYPE_NOM_TEXT
                 , V_PPS.COM_BEG_VALID
                 , V_PPS.COM_END_VALID
                 , V_PPS.COM_INTERVAL
                 , V_PPS.COM_PDIR_COEFF
                 , V_PPS.COM_POS
                 , V_PPS.COM_REC_PCENT
                 , V_PPS.COM_REF_QTY
                 , nvl(V_PPS.COM_REMPLACEMENT, 0)
                 , V_PPS.COM_RES_NUM
                 , V_PPS.COM_RES_TEXT
                 , V_PPS.COM_SEQ
                 , nvl(V_PPS.COM_SUBSTITUT, 0)
                 , V_PPS.COM_TEXT
                 , V_PPS.COM_UTIL_COEFF
                 , V_PPS.COM_VAL
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
              from V_PPS_NOM_BOND_INTERRO V_PPS
                 , PPS_NOMENCLATURE NOM
                 , GCO_GOOD GOO
                 , PCS.V_PC_DESCODES DES1
                 , PCS.V_PC_DESCODES DES2
                 , PCS.V_PC_DESCODES DES3
                 , PCS.V_PC_DESCODES DES4
                 , PCS.V_PC_DESCODES DES5
                 , PCS.V_PC_DESCODES DES6
             where V_PPS.PPS_NOMENCLATURE_ID = NOM.PPS_NOMENCLATURE_ID
               and GOO.GCO_GOOD_ID = NOM.GCO_GOOD_ID
               and DES1.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
               and DES2.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
               and DES3.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
               and DES4.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
               and DES5.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
               and DES6.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
               and DES1.GCGNAME = 'C_GOOD_STATUS'
               and DES2.GCGNAME = 'C_DISCHARGE_COM'
               and DES3.GCGNAME = 'C_KIND_COM'
               and DES4.GCGNAME = 'C_REMPLACEMENT_NOM'
               and DES5.GCGNAME = 'C_TYPE_COM'
               and DES6.GCGNAME = 'C_TYPE_NOM'
               and DES1.GCLCODE = GOO.C_GOOD_STATUS
               and DES2.GCLCODE = V_PPS.C_DISCHARGE_COM
               and DES3.GCLCODE = V_PPS.C_KIND_COM
               and DES4.GCLCODE = V_PPS.C_REMPLACEMENT_NOM
               and DES5.GCLCODE = V_PPS.C_TYPE_COM
               and DES6.GCLCODE = NOM.C_TYPE_NOM
          order by V_PPS.QUERY_ID_SEQ;

        vSequence  := vSequence + 10000;
      end if;
    end if;
  end PrepareGoodInterro;

  /**
  * procedure PrepareGoodNomInterro
  * Description
  *   Remplir la table de l'interrogation nomenclature avec les données concernant
  *     l'interrogation de type : "Interrogation cas d'emploi version nomenclature"
  */
  procedure PrepareGoodNomInterro(
    aNomenclatureID in PPS_NOMENCLATURE.PPS_NOMENCLATURE_ID%type
  , aClearTable     in integer default 1
  , iRootReference  in GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  )
  is
    cursor crInterroExist
    is
      select QUERY_ID_SEQ
        from V_PPS_NOM_BOND_INTERRO2;

    tplInterroExist crInterroExist%rowtype;
  begin
    if aClearTable = 1 then
      -- Effacer les données de la table de l'interrogation
      delete from PPS_INTERROGATION;
    end if;

    -- Initialisation de la variable de package pour l'execution de la cmd sql de la vue
    PPS_INIT.SetNomId(aNomenclatureID);

    open crInterroExist;

    fetch crInterroExist
     into tplInterroExist;

    if crInterroExist%found then
      -- Insertion de la première ligne correspondant à la nomenclature interrogée
      insert into PPS_INTERROGATION
                  (PPS_INTERROGATION_ID
                 , PPI_TEXT
                 , PPI_LEVEL
                 , PPI_ROOT_REFERENCE
                 , PPS_NOMENCLATURE_ID
                 , PPS_PPS_NOMENCLATURE_ID
                 , GCO_GOOD_ID
                 , COM_REF_QTY
                 , A_DATECRE
                 , A_IDCRE
                  )
        select vSequence
             , GOO.GOO_MAJOR_REFERENCE ||
               ', ' ||
               PCS.PC_FUNCTIONS.TranslateWord('Version') ||
               ': ' ||
               NOM.NOM_VERSION ||
               decode(NOM.NOM_DEFAULT, 1, ' - ' || PCS.PC_FUNCTIONS.TranslateWord('Défaut') )
             , 1
             , iRootReference
             , NOM.PPS_NOMENCLATURE_ID
             , null
             , NOM.GCO_GOOD_ID
             , 1   -- COM_REF_QTY
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from PPS_NOMENCLATURE NOM
             , GCO_GOOD GOO
         where NOM.PPS_NOMENCLATURE_ID = aNomenclatureID
           and NOM.GCO_GOOD_ID = GOO.GCO_GOOD_ID;

      vSequence  := vSequence + 1;

      -- Insertion des composants de la nomenclature interrogée
      insert into PPS_INTERROGATION
                  (PPS_INTERROGATION_ID
                 , PPI_TEXT
                 , PPI_LEVEL
                 , PPI_NOM_VERSION
                 , PPI_ROOT_REFERENCE
                 , PPS_NOMENCLATURE_ID
                 , PPS_PPS_NOMENCLATURE_ID
                 , PPS_NOM_BOND_ID
                 , PPS_RANGE_OPERATION_ID
                 , GCO_GOOD_ID
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , FAL_SCHEDULE_STEP_ID
                 , C_GOOD_STATUS
                 , C_GOOD_STATUS_TEXT
                 , C_DISCHARGE_COM
                 , C_DISCHARGE_COM_TEXT
                 , C_KIND_COM
                 , C_KIND_COM_TEXT
                 , C_REMPLACEMENT_NOM
                 , C_REMPLACEMENT_NOM_TEXT
                 , C_TYPE_COM
                 , C_TYPE_COM_TEXT
                 , C_TYPE_NOM
                 , C_TYPE_NOM_TEXT
                 , COM_BEG_VALID
                 , COM_END_VALID
                 , COM_INTERVAL
                 , COM_PDIR_COEFF
                 , COM_POS
                 , COM_REC_PCENT
                 , COM_REF_QTY
                 , COM_REMPLACEMENT
                 , COM_RES_NUM
                 , COM_RES_TEXT
                 , COM_SEQ
                 , COM_SUBSTITUT
                 , COM_TEXT
                 , COM_UTIL_COEFF
                 , COM_VAL
                 , A_DATECRE
                 , A_IDCRE
                  )
        select   vSequence + V_PPS.QUERY_ID_SEQ
               , V_PPS.COM_SEQ ||
                 '   ' ||
                 decode(nvl(GOO.GCO_GOOD_ID, -1)
                      , -1, PCS.PC_FUNCTIONS.TranslateWord('Lien texte')
                      , GOO.GOO_MAJOR_REFERENCE || '   ' || GOO.GOO_SECONDARY_REFERENCE
                       )
               , V_PPS.LEVEL_NOM + 1
               , NOM.NOM_VERSION
               , iRootReference
               , V_PPS.PPS_NOMENCLATURE_ID
               , V_PPS.PPS_PPS_NOMENCLATURE_ID
               , V_PPS.PPS_NOM_BOND_ID
               , V_PPS.PPS_RANGE_OPERATION_ID
               , GOO.GCO_GOOD_ID
               , V_PPS.STM_STOCK_ID
               , V_PPS.STM_LOCATION_ID
               , V_PPS.FAL_SCHEDULE_STEP_ID
               , DES1.GCLCODE C_GOOD_STATUS
               , '( ' || DES1.GCLCODE || ' ) ' || DES1.GCDTEXT1 C_GOOD_STATUS_TEXT
               , DES2.GCLCODE C_DISCHARGE_COM
               , '( ' || DES2.GCLCODE || ' ) ' || DES2.GCDTEXT1 C_DISCHARGE_COM_TEXT
               , DES3.GCLCODE C_KIND_COM
               , '( ' || DES3.GCLCODE || ' ) ' || DES3.GCDTEXT1 C_KIND_COM_TEXT
               , DES4.GCLCODE C_REMPLACEMENT_NOM
               , '( ' || DES4.GCLCODE || ' ) ' || DES4.GCDTEXT1 C_REMPLACEMENT_NOM_TEXT
               , DES5.GCLCODE C_TYPE_COM
               , '( ' || DES5.GCLCODE || ' ) ' || DES5.GCDTEXT1 C_TYPE_COM_TEXT
               , DES6.GCLCODE C_TYPE_NOM
               , '( ' || DES6.GCLCODE || ' ) ' || DES6.GCDTEXT1 C_TYPE_NOM_TEXT
               , V_PPS.COM_BEG_VALID
               , V_PPS.COM_END_VALID
               , V_PPS.COM_INTERVAL
               , V_PPS.COM_PDIR_COEFF
               , V_PPS.COM_POS
               , V_PPS.COM_REC_PCENT
               , nvl(V_PPS.COM_REF_QTY, 1)
               , nvl(V_PPS.COM_REMPLACEMENT, 0)
               , V_PPS.COM_RES_NUM
               , V_PPS.COM_RES_TEXT
               , V_PPS.COM_SEQ
               , nvl(V_PPS.COM_SUBSTITUT, 0)
               , V_PPS.COM_TEXT
               , nvl(V_PPS.COM_UTIL_COEFF, 1)
               , V_PPS.COM_VAL
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
            from V_PPS_NOM_BOND_INTERRO2 V_PPS
               , PPS_NOMENCLATURE NOM
               , GCO_GOOD GOO
               , PCS.V_PC_DESCODES DES1
               , PCS.V_PC_DESCODES DES2
               , PCS.V_PC_DESCODES DES3
               , PCS.V_PC_DESCODES DES4
               , PCS.V_PC_DESCODES DES5
               , PCS.V_PC_DESCODES DES6
           where V_PPS.PPS_NOMENCLATURE_ID = NOM.PPS_NOMENCLATURE_ID
             and GOO.GCO_GOOD_ID = NOM.GCO_GOOD_ID
             and DES1.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
             and DES2.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
             and DES3.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
             and DES4.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
             and DES5.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
             and DES6.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
             and DES1.GCGNAME = 'C_GOOD_STATUS'
             and DES2.GCGNAME = 'C_DISCHARGE_COM'
             and DES3.GCGNAME = 'C_KIND_COM'
             and DES4.GCGNAME = 'C_REMPLACEMENT_NOM'
             and DES5.GCGNAME = 'C_TYPE_COM'
             and DES6.GCGNAME = 'C_TYPE_NOM'
             and DES1.GCLCODE = GOO.C_GOOD_STATUS
             and DES2.GCLCODE = V_PPS.C_DISCHARGE_COM
             and DES3.GCLCODE = V_PPS.C_KIND_COM
             and DES4.GCLCODE = V_PPS.C_REMPLACEMENT_NOM
             and DES5.GCLCODE = V_PPS.C_TYPE_COM
             and DES6.GCLCODE = NOM.C_TYPE_NOM
        order by V_PPS.QUERY_ID_SEQ;

      vSequence  := vSequence + 10000;
    end if;

    close crInterroExist;
  end PrepareGoodNomInterro;

  /**
  * procedure PrepareGoodNoLinkNomInterro
  * Description
  *   Remplir la table de l'interrogation nomenclature avec les données concernant
  *     l'interrogation de type : "Interrogation cas d'emploi produit"
  *     mais dont le composant n'a pas de lien de version nomenclature
  */
  procedure PrepareGoodNoLinkNomInterro(
    aGoodID        in GCO_GOOD.GCO_GOOD_ID%type
  , aClearTable    in integer default 1
  , iRootReference in GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  )
  is
    cursor crInterroExist
    is
      select QUERY_ID_SEQ
        from V_PPS_NOM_BOND_NOLINK_INTERRO;

    tplInterroExist crInterroExist%rowtype;
  begin
    if aClearTable = 1 then
      -- Effacer les données de la table de l'interrogation
      delete from PPS_INTERROGATION;
    end if;

    -- Initialisation de la variable de package pour l'execution de la cmd sql de la vue
    PPS_INIT.SetGoodId(aGoodID);

    open crInterroExist;

    fetch crInterroExist
     into tplInterroExist;

    if crInterroExist%found then
      -- Insertion de la première ligne correspondant au bien interrogé
      insert into PPS_INTERROGATION
                  (PPS_INTERROGATION_ID
                 , PPI_TEXT
                 , PPI_LEVEL
                 , PPI_ROOT_REFERENCE
                 , PPS_NOMENCLATURE_ID
                 , PPS_PPS_NOMENCLATURE_ID
                 , GCO_GOOD_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select vSequence
             , GOO.GOO_MAJOR_REFERENCE
             , 1
             , iRootReference
             , null
             , null
             , GOO.GCO_GOOD_ID
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from GCO_GOOD GOO
         where GOO.GCO_GOOD_ID = aGoodID;

      vSequence  := vSequence + 1;

      -- Insertion des cas d'emploi du bien interrogé
      insert into PPS_INTERROGATION
                  (PPS_INTERROGATION_ID
                 , PPI_TEXT
                 , PPI_LEVEL
                 , PPI_NOM_VERSION
                 , PPI_ROOT_REFERENCE
                 , PPS_NOMENCLATURE_ID
                 , PPS_PPS_NOMENCLATURE_ID
                 , PPS_NOM_BOND_ID
                 , PPS_RANGE_OPERATION_ID
                 , GCO_GOOD_ID
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , FAL_SCHEDULE_STEP_ID
                 , C_GOOD_STATUS
                 , C_GOOD_STATUS_TEXT
                 , C_DISCHARGE_COM
                 , C_DISCHARGE_COM_TEXT
                 , C_KIND_COM
                 , C_KIND_COM_TEXT
                 , C_REMPLACEMENT_NOM
                 , C_REMPLACEMENT_NOM_TEXT
                 , C_TYPE_COM
                 , C_TYPE_COM_TEXT
                 , C_TYPE_NOM
                 , C_TYPE_NOM_TEXT
                 , COM_BEG_VALID
                 , COM_END_VALID
                 , COM_INTERVAL
                 , COM_PDIR_COEFF
                 , COM_POS
                 , COM_REC_PCENT
                 , COM_REF_QTY
                 , COM_REMPLACEMENT
                 , COM_RES_NUM
                 , COM_RES_TEXT
                 , COM_SEQ
                 , COM_SUBSTITUT
                 , COM_TEXT
                 , COM_UTIL_COEFF
                 , COM_VAL
                 , A_DATECRE
                 , A_IDCRE
                  )
        select   vSequence + V_PPS.QUERY_ID_SEQ
               , V_PPS.COM_SEQ ||
                 '   ' ||
                 decode(nvl(GOO.GCO_GOOD_ID, -1)
                      , -1, PCS.PC_FUNCTIONS.TranslateWord('Lien texte')
                      , GOO.GOO_MAJOR_REFERENCE || '   ' || GOO.GOO_SECONDARY_REFERENCE
                       )
               , V_PPS.LEVEL_NOM + 1
               , NOM.NOM_VERSION
               , iRootReference
               , V_PPS.PPS_NOMENCLATURE_ID
               , V_PPS.PPS_PPS_NOMENCLATURE_ID
               , V_PPS.PPS_NOM_BOND_ID
               , V_PPS.PPS_RANGE_OPERATION_ID
               , GOO.GCO_GOOD_ID
               , V_PPS.STM_STOCK_ID
               , V_PPS.STM_LOCATION_ID
               , V_PPS.FAL_SCHEDULE_STEP_ID
               , DES1.GCLCODE C_GOOD_STATUS
               , '( ' || DES1.GCLCODE || ' ) ' || DES1.GCDTEXT1 C_GOOD_STATUS_TEXT
               , DES2.GCLCODE C_DISCHARGE_COM
               , '( ' || DES2.GCLCODE || ' ) ' || DES2.GCDTEXT1 C_DISCHARGE_COM_TEXT
               , DES3.GCLCODE C_KIND_COM
               , '( ' || DES3.GCLCODE || ' ) ' || DES3.GCDTEXT1 C_KIND_COM_TEXT
               , DES4.GCLCODE C_REMPLACEMENT_NOM
               , '( ' || DES4.GCLCODE || ' ) ' || DES4.GCDTEXT1 C_REMPLACEMENT_NOM_TEXT
               , DES5.GCLCODE C_TYPE_COM
               , '( ' || DES5.GCLCODE || ' ) ' || DES5.GCDTEXT1 C_TYPE_COM_TEXT
               , DES6.GCLCODE C_TYPE_NOM
               , '( ' || DES6.GCLCODE || ' ) ' || DES6.GCDTEXT1 C_TYPE_NOM_TEXT
               , V_PPS.COM_BEG_VALID
               , V_PPS.COM_END_VALID
               , V_PPS.COM_INTERVAL
               , V_PPS.COM_PDIR_COEFF
               , V_PPS.COM_POS
               , V_PPS.COM_REC_PCENT
               , V_PPS.COM_REF_QTY
               , nvl(V_PPS.COM_REMPLACEMENT, 0)
               , V_PPS.COM_RES_NUM
               , V_PPS.COM_RES_TEXT
               , V_PPS.COM_SEQ
               , nvl(V_PPS.COM_SUBSTITUT, 0)
               , V_PPS.COM_TEXT
               , V_PPS.COM_UTIL_COEFF
               , V_PPS.COM_VAL
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
            from V_PPS_NOM_BOND_NOLINK_INTERRO V_PPS
               , PPS_NOMENCLATURE NOM
               , GCO_GOOD GOO
               , PCS.V_PC_DESCODES DES1
               , PCS.V_PC_DESCODES DES2
               , PCS.V_PC_DESCODES DES3
               , PCS.V_PC_DESCODES DES4
               , PCS.V_PC_DESCODES DES5
               , PCS.V_PC_DESCODES DES6
           where V_PPS.PPS_NOMENCLATURE_ID = NOM.PPS_NOMENCLATURE_ID
             and GOO.GCO_GOOD_ID = NOM.GCO_GOOD_ID
             and DES1.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
             and DES2.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
             and DES3.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
             and DES4.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
             and DES5.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
             and DES6.PC_LANG_ID = PCS.PC_I_LIB_SESSION.GetUserLangID
             and DES1.GCGNAME = 'C_GOOD_STATUS'
             and DES2.GCGNAME = 'C_DISCHARGE_COM'
             and DES3.GCGNAME = 'C_KIND_COM'
             and DES4.GCGNAME = 'C_REMPLACEMENT_NOM'
             and DES5.GCGNAME = 'C_TYPE_COM'
             and DES6.GCGNAME = 'C_TYPE_NOM'
             and DES1.GCLCODE = GOO.C_GOOD_STATUS
             and DES2.GCLCODE = V_PPS.C_DISCHARGE_COM
             and DES3.GCLCODE = V_PPS.C_KIND_COM
             and DES4.GCLCODE = V_PPS.C_REMPLACEMENT_NOM
             and DES5.GCLCODE = V_PPS.C_TYPE_COM
             and DES6.GCLCODE = NOM.C_TYPE_NOM
        order by V_PPS.QUERY_ID_SEQ;

      vSequence  := vSequence + 10000;
    end if;

    close crInterroExist;
  end PrepareGoodNoLinkNomInterro;

  /**
  * Description
  *   Supression "logique" d'un alliage dans la table d'interro
  */
  procedure DeleteInterroAlloyRecord(iInterroAlloyId in PPS_INTERRO_ALLOY.PPS_INTERRO_ALLOY_ID%type)
  is
  begin
    update PPS_INTERRO_ALLOY
       set C_GPM_UPDATE_TYPE = '3'
     where PPS_INTERRO_ALLOY_ID = iInterroAlloyId;
  end DeleteInterroAlloyRecord;

  /**
  * Description
  *    Mise à jour des données matières précieuses en fonction des données provisoires
  *    contenues dans les tables d'interrogation
  */
  procedure UpdateAlloyDataFromInterro(iUseCaseUpdate in number default 0, iInactive in integer default 0, iSuspended in integer default 0)
  is
  begin
    -- si demandé, mise à jour des cas d'emploi non présent dans l'interro mais
    -- tout de même touchés par les modifications effectuées
    if iUseCaseUpdate = 1 then
      pAddUseCasesInInterro;
    end if;

    GCO_PRECIOUS_MAT_FUNCTIONS.UpdateWeightAndChip(iInactive, iSuspended);

    -- Mise à jour des matières précieuses
    for ltplInterroAlloy in (select PIA.*
                               from PPS_INTERRO_ALLOY PIA
                                  , GCO_GOOD GOO
                              where C_GPM_UPDATE_TYPE in
                                              (PPS_LIB_INTERRO.cGpmUpdateTypeInsert, PPS_LIB_INTERRO.cGpmUpdateTypeUpdate, PPS_LIB_INTERRO.cGpmUpdateTypeDelete)
                                and GOO.GCO_GOOD_ID = PIA.GCO_GOOD_ID
                                and GOO_PRECIOUS_MAT = 1) loop
      if     ltplInterroAlloy.C_GPM_UPDATE_TYPE = PPS_LIB_INTERRO.cGpmUpdateTypeUpdate
         and GCO_I_LIB_PRECIOUS_MAT.GetPreciousMatId(ltplInterroAlloy.GCO_GOOD_ID, ltplInterroAlloy.GCO_ALLOY_ID) is null then
        ltplInterroAlloy.C_GPM_UPDATE_TYPE  := PPS_LIB_INTERRO.cGpmUpdateTypeInsert;
      end if;

      case
        when ltplInterroAlloy.C_GPM_UPDATE_TYPE = PPS_LIB_INTERRO.cGpmUpdateTypeInsert then
          declare
            ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
          begin
            FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoPreciousMat, ltCRUD_DEF, true);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_GOOD_ID', ltplInterroAlloy.GCO_GOOD_ID);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_ALLOY_ID', ltplInterroAlloy.GCO_ALLOY_ID);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_WEIGHT', ltplInterroAlloy.GPM_WEIGHT);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_REAL_WEIGHT', ltplInterroAlloy.GPM_REAL_WEIGHT);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_THEORICAL_WEIGHT', ltplInterroAlloy.GPM_THEORICAL_WEIGHT);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_WEIGHT_DELIVER_AUTO', ltplInterroAlloy.GPM_WEIGHT_DELIVER_AUTO);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_WEIGHT_DELIVER', ltplInterroAlloy.GPM_WEIGHT_DELIVER);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_WEIGHT_CHIP_TOTAL', ltplInterroAlloy.GPM_WEIGHT_CHIP_TOTAL);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_WEIGHT_CHIP', ltplInterroAlloy.GPM_WEIGHT_CHIP);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_WEIGHT_INVEST', ltplInterroAlloy.GPM_WEIGHT_INVEST);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_WEIGHT_INVEST_VALUE', ltplInterroAlloy.GPM_WEIGHT_INVEST_VALUE);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_WEIGHT_INVEST_TOTAL', ltplInterroAlloy.GPM_WEIGHT_INVEST_TOTAL);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_WEIGHT_INVEST_TOTAL_VALUE', ltplInterroAlloy.GPM_WEIGHT_INVEST_TOTAL_VALUE);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_LOSS_PERCENT', ltplInterroAlloy.GPM_LOSS_PERCENT);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_LOSS_TOTAL', ltplInterroAlloy.GPM_LOSS_TOTAL);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_LOSS_UNIT', ltplInterroAlloy.GPM_LOSS_UNIT);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_STONE_NUMBER', ltplInterroAlloy.GPM_STONE_NUMBER);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_WEIGHT_DELIVER_VALUE', ltplInterroAlloy.GPM_WEIGHT_DELIVER_VALUE);
            FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
          end;
        when ltplInterroAlloy.C_GPM_UPDATE_TYPE = PPS_LIB_INTERRO.cGpmUpdateTypeUpdate then
          declare
            ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
          begin
            FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoPreciousMat, ltCRUD_DEF, true);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF
                                          , 'GCO_PRECIOUS_MAT_ID'
                                          , GCO_I_LIB_PRECIOUS_MAT.GetPreciousMatId(ltplInterroAlloy.GCO_GOOD_ID, ltplInterroAlloy.GCO_ALLOY_ID)
                                           );
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_WEIGHT', ltplInterroAlloy.GPM_WEIGHT);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_REAL_WEIGHT', ltplInterroAlloy.GPM_REAL_WEIGHT);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_THEORICAL_WEIGHT', ltplInterroAlloy.GPM_THEORICAL_WEIGHT);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_WEIGHT_DELIVER_AUTO', ltplInterroAlloy.GPM_WEIGHT_DELIVER_AUTO);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_WEIGHT_DELIVER', ltplInterroAlloy.GPM_WEIGHT_DELIVER);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_WEIGHT_DELIVER_VALUE', ltplInterroAlloy.GPM_WEIGHT_DELIVER_VALUE);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_WEIGHT_CHIP_TOTAL', ltplInterroAlloy.GPM_WEIGHT_CHIP_TOTAL);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_WEIGHT_CHIP', ltplInterroAlloy.GPM_WEIGHT_CHIP);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_LOSS_PERCENT', ltplInterroAlloy.GPM_LOSS_PERCENT);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_LOSS_TOTAL', ltplInterroAlloy.GPM_LOSS_TOTAL);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_LOSS_UNIT', ltplInterroAlloy.GPM_LOSS_UNIT);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_WEIGHT_INVEST', ltplInterroAlloy.GPM_WEIGHT_INVEST);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_WEIGHT_INVEST_TOTAL_VALUE', ltplInterroAlloy.GPM_WEIGHT_INVEST_TOTAL_VALUE);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_STONE_NUMBER', ltplInterroAlloy.GPM_STONE_NUMBER);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_WEIGHT_INVEST_VALUE', ltplInterroAlloy.GPM_WEIGHT_INVEST_VALUE);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GPM_WEIGHT_INVEST_TOTAL', ltplInterroAlloy.GPM_WEIGHT_INVEST_TOTAL);
            FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
          end;
        when ltplInterroAlloy.C_GPM_UPDATE_TYPE = PPS_LIB_INTERRO.cGpmUpdateTypeDelete then
          declare
            ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
          begin
            FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoPreciousMat, ltCRUD_DEF, true);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF
                                          , 'GCO_PRECIOUS_MAT_ID'
                                          , GCO_I_LIB_PRECIOUS_MAT.GetPreciousMatId(ltplInterroAlloy.GCO_GOOD_ID, ltplInterroAlloy.GCO_ALLOY_ID)
                                           );
            FWK_I_MGT_ENTITY.DeleteEntity(ltCRUD_DEF);
          end;
      end case;
    end loop;

    commit;
  end UpdateAlloyDataFromInterro;

  /**
  * Description
  *    Mise à jour des matières précieuses des composés en mode cas d'emploi (use case)
  */
  procedure UpdateUseCaseDataAlloy(iInactive in number, iSuspended in number)
  is
  begin
    pSelectTPGoods;
    PrepareGcoAlloyCalc('NOM', iInactive, iSuspended);
    UpdateAlloyDataFromInterro(iInactive => iInactive, iSuspended => iSuspended);
  end UpdateUseCaseDataAlloy;

  /**
  * Description
  *    Mise à jour des données d'interro à partir des pesées
  *    de matières précieuses
  */
  procedure UpdateAlloyDataFromWeighing(iMaxThreshold in number)
  is
  begin
    -- pas implémenté pour l'instant
    null;
--     for ltplInterroAlloy in (select   WEI.GCO_GOOD_ID
--                                     , WEI.GCO_ALLOY_ID
--                                     , avg(FWE_WEIGHT / FWE_PIECE_QTY) FWE_WEIGHT
--                                  from PPS_INTERROGATION PIN
--                                     , FAL_WEIGH WEI
--                                 where PIN.GCO_GOOD_ID = WEI.GCO_GOOD_ID
--                              group by WEI.GCO_GOOD_ID
--                                     , WEI.GCO_ALLOY_ID) loop
--       pMergeGoodInterroAlloy(ltplInterroAlloy.GCO_GOOD_ID, ltplInterroAlloy.GCO_ALLOY_ID, ltplInterroAlloy.FWE_WEIGHT, 0);
--     end loop;
  end UpdateAlloyDataFromWeighing;

  /**
  * Description
  *   Supression des données dans les tables temporaires (PPS_INTERROGATION, PPS_INTERRO_ALLOY et COM_LIST_ID_TEMP)
  */
  procedure ClearInterroAlloy
  is
  begin
    delete from PPS_INTERRO_ALLOY;

    delete from PPS_INTERROGATION;

    COM_I_PRC_LIST_ID_TEMP.ClearIDList;
  end ClearInterroAlloy;

  /**
   * procedure SelectProduct
   * Description
   *   Sélectionne le produit
   */
  procedure SelectProduct(iGoodId in GCO_GOOD.GCO_GOOD_ID%type, iPurge in boolean default true)
  is
  begin
    -- Suppression des anciennes valeurs
    if iPurge then
      delete from COM_LIST_ID_TEMP
            where LID_CODE = 'GCO_GOOD_ID';
    end if;

    -- Sélection de l'ID du produit traiter
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
         values (iGoodId
               , 'GCO_GOOD_ID'
                );
  exception
    when dup_val_on_index then
      null;
  end SelectProduct;

  /**
   * procedure SelectProducts
   * Description
   *   Sélectionne les produits selon les filtres
   */
  procedure SelectProducts(
    iPRODUCT_FROM           in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , iPRODUCT_TO             in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , iGOOD_CATEGORY_FROM     in GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type
  , iGOOD_CATEGORY_TO       in GCO_GOOD_CATEGORY.GCO_GOOD_CATEGORY_WORDING%type
  , iGOOD_FAMILY_FROM       in DIC_GOOD_FAMILY.DIC_GOOD_FAMILY_ID%type
  , iGOOD_FAMILY_TO         in DIC_GOOD_FAMILY.DIC_GOOD_FAMILY_ID%type
  , iACCOUNTABLE_GROUP_FROM in DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type
  , iACCOUNTABLE_GROUP_TO   in DIC_ACCOUNTABLE_GROUP.DIC_ACCOUNTABLE_GROUP_ID%type
  , iGOOD_LINE_FROM         in DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type
  , iGOOD_LINE_TO           in DIC_GOOD_LINE.DIC_GOOD_LINE_ID%type
  , iGOOD_GROUP_FROM        in DIC_GOOD_GROUP.DIC_GOOD_GROUP_ID%type
  , iGOOD_GROUP_TO          in DIC_GOOD_GROUP.DIC_GOOD_GROUP_ID%type
  , iGOOD_MODEL_FROM        in DIC_GOOD_MODEL.DIC_GOOD_MODEL_ID%type
  , iGOOD_MODEL_TO          in DIC_GOOD_MODEL.DIC_GOOD_MODEL_ID%type
  , iALLOY_FROM             in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , iALLOY_TO               in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  )
  is
  begin
    -- Suppression des anciennes valeurs
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'GCO_GOOD_ID';

    -- Sélection des ID de produits à traiter
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
                )
      select distinct GOO.GCO_GOOD_ID
                    , 'GCO_GOOD_ID'
                 from GCO_GOOD GOO
                    , GCO_PRODUCT PDT
                    , GCO_GOOD_CATEGORY CAT
                where GOO.GOO_MAJOR_REFERENCE between nvl(iPRODUCT_FROM, GOO.GOO_MAJOR_REFERENCE) and nvl(iPRODUCT_TO, GOO.GOO_MAJOR_REFERENCE)
                  and PDT.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                  and GOO.GCO_GOOD_CATEGORY_ID = CAT.GCO_GOOD_CATEGORY_ID(+)
                  and (    (    iGOOD_CATEGORY_FROM is null
                            and iGOOD_CATEGORY_TO is null)
                       or CAT.GCO_GOOD_CATEGORY_WORDING between nvl(iGOOD_CATEGORY_FROM, CAT.GCO_GOOD_CATEGORY_WORDING)
                                                            and nvl(iGOOD_CATEGORY_TO, CAT.GCO_GOOD_CATEGORY_WORDING)
                      )
                  and (    (    iGOOD_FAMILY_FROM is null
                            and iGOOD_FAMILY_TO is null)
                       or GOO.DIC_GOOD_FAMILY_ID between nvl(iGOOD_FAMILY_FROM, GOO.DIC_GOOD_FAMILY_ID) and nvl(iGOOD_FAMILY_TO, GOO.DIC_GOOD_FAMILY_ID)
                      )
                  and (    (    iACCOUNTABLE_GROUP_FROM is null
                            and iACCOUNTABLE_GROUP_TO is null)
                       or GOO.DIC_ACCOUNTABLE_GROUP_ID between nvl(iACCOUNTABLE_GROUP_FROM, GOO.DIC_ACCOUNTABLE_GROUP_ID)
                                                           and nvl(iACCOUNTABLE_GROUP_TO, GOO.DIC_ACCOUNTABLE_GROUP_ID)
                      )
                  and (    (    iGOOD_LINE_FROM is null
                            and iGOOD_LINE_TO is null)
                       or GOO.DIC_GOOD_LINE_ID between nvl(iGOOD_LINE_FROM, GOO.DIC_GOOD_LINE_ID) and nvl(iGOOD_LINE_TO, GOO.DIC_GOOD_LINE_ID)
                      )
                  and (    (    iGOOD_GROUP_FROM is null
                            and iGOOD_GROUP_TO is null)
                       or GOO.DIC_GOOD_GROUP_ID between nvl(iGOOD_GROUP_FROM, GOO.DIC_GOOD_GROUP_ID) and nvl(iGOOD_GROUP_TO, GOO.DIC_GOOD_GROUP_ID)
                      )
                  and (    (    iGOOD_MODEL_FROM is null
                            and iGOOD_MODEL_TO is null)
                       or GOO.DIC_GOOD_MODEL_ID between nvl(iGOOD_MODEL_FROM, GOO.DIC_GOOD_MODEL_ID) and nvl(iGOOD_MODEL_TO, GOO.DIC_GOOD_MODEL_ID)
                      )
                  and (    (    iALLOY_FROM is null
                            and iALLOY_TO is null)
                       or exists(
                            select 1
                              from GCO_PRECIOUS_MAT GPM
                                 , GCO_ALLOY GAL
                             where GPM.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                               and GPM.GCO_ALLOY_ID = GAL.GCO_ALLOY_ID
                               and GAL.GAL_ALLOY_REF between nvl(iALLOY_FROM, GAL.GAL_ALLOY_REF) and nvl(iALLOY_TO, GAL.GAL_ALLOY_REF) )
                      );
  end SelectProducts;
end PPS_PRC_INTERRO;
