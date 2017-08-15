--------------------------------------------------------
--  DDL for Package Body GCO_PRC_COMPL_DATA
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_PRC_COMPL_DATA" 
is
  /*
  * Permet d'insérer les records manquants dans la table GCO_COMPL_DATA_DISTRIB
  * en pour tous les produits d'un groupe de produits
  */
  procedure InsertIntoComplDistrib(iComplDistrId in number)
  is
    lStmDiuId            number;
    lProductGroupId      number;
    lDicDistrComplDataId varchar2(10);

    cursor lcurReadGood(cProductGroupId number, cStmDiuId number, cDicDistribComplDataId varchar2)
    is
      select *
        from gco_good goo
       where gco_product_group_id = cProductGroupId
         and gco_good_id not in(
               select gco_good_id
                 from gco_compl_data_distrib
                where gco_good_id is not null
                  and (    (    stm_distribution_unit_id is null
                            and dic_distrib_compl_data_id = cDicDistribComplDataId)
                       or (    stm_distribution_unit_id = cStmDiuId
                           and dic_distrib_compl_data_id is null)
                      ) );

    ltplReadGood         lcurReadGood%rowtype;
  begin
    select STM_DISTRIBUTION_UNIT_ID
         , DIC_DISTRIB_COMPL_DATA_ID
         , GCO_PRODUCT_GROUP_ID
      into lStmDiuId
         , lDicDistrComplDataId
         , lProductGroupId
      from GCO_COMPL_DATA_DISTRIB
     where GCO_COMPL_DATA_DISTRIB_ID = iComplDistrId;

    -- Ouverture du curseur
    open lcurReadGood(lProductGroupId, lStmDiuId, lDicDistrComplDataId);

    -- Recherche premier enregistrement
    fetch lcurReadGood
     into ltplReadGood;

    -- Parcours le curseur
    while lcurReadGood%found loop
      -- Insert nouvelle donnée de distribution
      insert into GCO_COMPL_DATA_DISTRIB
                  (GCO_COMPL_DATA_DISTRIB_ID
                 , GCO_GOOD_ID
                 , GCO_PRODUCT_GROUP_ID
                 , STM_DISTRIBUTION_UNIT_ID
                 , DIC_DISTRIB_COMPL_DATA_ID
                 , CDI_PRIORITY_CODE
                 , CDI_COVER_PERCENT
                 , C_DRP_USE_COVER_PERCENT
                 , CDI_BLOCKED_FROM
                 , CDI_BLOCKED_TO
                 , DIC_UNIT_OF_MEASURE_ID
                 , CDI_ECONOMICAL_QUANTITY
                 , C_DRP_QTY_RULE
                 , C_DRP_DOC_MODE
                 , CDI_STOCK_MIN
                 , CDI_STOCK_MAX
                 , C_DRP_RELIQUAT
                 , CDA_COMMENT
                 , CDA_COMPLEMENTARY_EAN_CODE
                 , CDA_COMPLEMENTARY_REFERENCE
                 , CDA_COMPLEMENTARY_UCC14_CODE
                 , CDA_CONVERSION_FACTOR
                 , CDA_NUMBER_OF_DECIMAL
                 , CDA_FREE_ALPHA_1
                 , CDA_FREE_ALPHA_2
                 , CDA_FREE_DEC_1
                 , CDA_FREE_DEC_2
                 , CDA_FREE_DESCRIPTION
                 , CDA_LONG_DESCRIPTION
                 , CDA_SHORT_DESCRIPTION
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (Init_id_seq.nextval   -- GCO_COMPL_DATA_DISTRIB_ID
                 , ltplReadGood.GCO_GOOD_ID   -- GCO_GOOD_ID
                 , null   -- GCO_PRODUCT_GROUP_ID
                 , lStmDiuId   -- STM_DISTRIBUTION_UNIT_ID
                 , lDicDistrComplDataId   -- DIC_DISTRIB_COMPL_DATA_ID
                 , null   -- CDI_PRIORITY_CODE
                 , null   -- CDI_COVER_PERCENT
                 , '0'   -- C_DRP_USE_COVER_PERCENT
                 , null   -- CDI_BLOCKED_FROM
                 , null   -- CDI_BLOCKED_TO
                 , ltplReadGood.DIC_UNIT_OF_MEASURE_ID   -- DIC_UNIT_OF_MEASURE_ID
                 , null   -- CDI_ECONOMICAL_QUANTITY
                 , '0'   -- C_DRP_QTY_RULE
                 , '0'   -- C_DRP_DOC_MODE
                 , null   -- CDI_STOCK_MIN
                 , null   -- CDI_STOCK_MAX
                 , '0'   -- C_DRP_RELIQUAT
                 , null   -- CDA_COMMENT
                 , null   -- CDA_COMPLEMENTARY_EAN_CODE
                 , null   -- CDA_COMPLEMENTARY_REFERENCE
                 , null   -- CDA_COMPLEMENTARY_UCC14_CODE
                 , 1.0   -- CDA_CONVERSION_FACTOR
                 , ltplReadGood.GOO_NUMBER_OF_DECIMAL   -- CDA_NUMBER_OF_DECIMAL
                 , null   -- CDA_FREE_ALPHA_1
                 , null   -- CDA_FREE_ALPHA_2
                 , null   -- CDA_FREE_DEC_1
                 , null   -- CDA_FREE_DEC_2
                 , null   -- CDA_FREE_DESCRIPTION
                 , null   -- CDA_LONG_DESCRIPTION
                 , null   -- CDA_SHORT_DESCRIPTION
                 , sysdate   -- A_DATECRE
                 , pcs.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                  );

      fetch lcurReadGood
       into ltplReadGood;
    end loop;

    -- fermeture du curseur
    close lcurReadGood;
  end;

  /**
  * Description
  *   Mise à jour du lien sur nomenclature pour les données complémentaires
  *   de fabrication
  */
  procedure UpdateManuDataNomLink(
    iComplDataId    in GCO_COMPL_DATA_MANUFACTURE.GCO_COMPL_DATA_MANUFACTURE_ID%type
  , iNomenclatureId in GCO_COMPL_DATA_MANUFACTURE.PPS_NOMENCLATURE_ID%type
  )
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataManufacture, ltCRUD_DEF);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_COMPL_DATA_MANUFACTURE_ID', iComplDataId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PPS_NOMENCLATURE_ID', iNomenclatureId);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end UpdateManuDataNomLink;

  /**
  * Description
  *   Mise à jour du lien sur nomenclature pour les données complémentaires
  *   de sous-traitance
  */
  procedure UpdateSubCDataNomLink(
    iComplDataId    in GCO_COMPL_DATA_SUBCONTRACT.GCO_COMPL_DATA_SUBCONTRACT_ID%type
  , iNomenclatureId in GCO_COMPL_DATA_SUBCONTRACT.PPS_NOMENCLATURE_ID%type
  )
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoComplDataSubContract, ltCRUD_DEF);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_COMPL_DATA_SUBCONTRACT_ID', iComplDataId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PPS_NOMENCLATURE_ID', iNomenclatureId);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end UpdateSubCDataNomLink;

  /**
  * Description
  *   Mise à jour du nombre de décimal pour les données complémentaires
  *   qui ne sont pas modifiable dans l'interface
  *   Stock, Inventaire et fabication
  *   et les données complémentaires qui ont la même unité de mesure
  *   que le produit
  */
  procedure UpdateNumberOfDecimal(
    iGoodId          in GCO_GOOD.GCO_GOOD_ID%type
  , iNumberOfDecimal in GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type
  , iUnitOfMeasure   in GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type
  )
  is
  begin
    -- MAJ du nombre de décimal pour les données complémentaires de stock
    update GCO_COMPL_DATA_STOCK
       set CDA_NUMBER_OF_DECIMAL = iNumberOfDecimal
     where GCO_GOOD_ID = iGoodId;

    -- MAJ du nombre de décimal pour les données complémentaires d'inventaire
    update GCO_COMPL_DATA_INVENTORY
       set CDA_NUMBER_OF_DECIMAL = iNumberOfDecimal
     where GCO_GOOD_ID = iGoodId;

    -- MAJ du nombre de décimal pour les données complémentaires de fabrication
    update GCO_COMPL_DATA_MANUFACTURE
       set CDA_NUMBER_OF_DECIMAL = iNumberOfDecimal
     where GCO_GOOD_ID = iGoodId;

    -- MAJ du nombre de décimal pour les données complémentaires d'achat
    update GCO_COMPL_DATA_PURCHASE
       set CDA_NUMBER_OF_DECIMAL = iNumberOfDecimal
         , CDA_CONVERSION_FACTOR = 1
     where GCO_GOOD_ID = iGoodId
       and DIC_UNIT_OF_MEASURE_ID = iUnitOfMeasure;

    -- MAJ du nombre de décimal pour les données complémentaires de vente
    update GCO_COMPL_DATA_SALE
       set CDA_NUMBER_OF_DECIMAL = iNumberOfDecimal
         , CDA_CONVERSION_FACTOR = 1
     where GCO_GOOD_ID = iGoodId
       and DIC_UNIT_OF_MEASURE_ID = iUnitOfMeasure;

    -- MAJ du nombre de décimal pour les données complémentaires de distribution
    update GCO_COMPL_DATA_DISTRIB
       set CDA_NUMBER_OF_DECIMAL = iNumberOfDecimal
         , CDA_CONVERSION_FACTOR = 1
     where GCO_GOOD_ID = iGoodId
       and DIC_UNIT_OF_MEASURE_ID = iUnitOfMeasure;
  end UpdateNumberOfDecimal;

  /**
  * Description
  *   Mise à jour de l'unité de mesure pour les données complémentaires
  *   qui ne sont pas modifiable dans l'interface
  *   Stock, Inventaire et fabication
  */
  procedure UpdateUnitOfMeasure(iGoodId in GCO_GOOD.GCO_GOOD_ID%type, iUnitOfMeasure in GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type)
  is
  begin
    -- MAJ de l'unité de mesure pour les données complémentaires de stock
    update GCO_COMPL_DATA_STOCK
       set DIC_UNIT_OF_MEASURE_ID = iUnitOfMeasure
     where GCO_GOOD_ID = iGoodId;

    -- MAJ de l'unité de mesure pour les données complémentaires d'inventaire
    update GCO_COMPL_DATA_INVENTORY
       set DIC_UNIT_OF_MEASURE_ID = iUnitOfMeasure
     where GCO_GOOD_ID = iGoodId;

    -- MAJ de l'unité de mesure pour les données complémentaires de fabrication
    update GCO_COMPL_DATA_MANUFACTURE
       set DIC_UNIT_OF_MEASURE_ID = iUnitOfMeasure
     where GCO_GOOD_ID = iGoodId;
  end UpdateUnitOfMeasure;

  /**
  * procedure RenumberPackingElement
  * Description
  *   Rénumérote les données d'emballage d'une donnée compl. de vente
  */
  procedure RenumberPackingElement(iComplSaleID in GCO_COMPL_DATA_SALE.GCO_COMPL_DATA_SALE_ID%type)
  is
    ltPackingElement FWK_I_TYP_DEFINITION.t_crud_def;
    lnIncrement      integer                         := 0;
    lnSeq            integer                         := 0;
  begin
    -- Définition de la valeur d'incrément
    begin
      lnIncrement  := to_number(PCS.PC_CONFIG.GetConfig('GCO_Packing_Numbering') );
    exception
      when others then
        lnIncrement  := 10;
    end;

    if lnIncrement = 0 then
      lnIncrement  := 10;
    end if;

    -- Passer les valeurs des sequences à une valeur négative pour ne pas
    --  avoir de contrainte avec la PK2 unique durant le processus de renumérotation
    for ltplPackingElement in (select   GCO_PACKING_ELEMENT_ID
                                      , SHI_SEQ
                                   from GCO_PACKING_ELEMENT
                                  where GCO_COMPL_DATA_SALE_ID = iComplSaleID
                               order by abs(SHI_SEQ) asc) loop
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoPackingElement, ltPackingElement);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltPackingElement, 'GCO_PACKING_ELEMENT_ID', ltplPackingElement.GCO_PACKING_ELEMENT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltPackingElement, 'SHI_SEQ',(ltplPackingElement.SHI_SEQ * -1) );
      FWK_I_MGT_ENTITY.UpdateEntity(ltPackingElement);
      FWK_I_MGT_ENTITY.Release(ltPackingElement);
    end loop;

    -- Renumérotation en fonction de l'ordre du n° de séquence
    for ltplPackingElement in (select   GCO_PACKING_ELEMENT_ID
                                      , SHI_SEQ
                                   from GCO_PACKING_ELEMENT
                                  where GCO_COMPL_DATA_SALE_ID = iComplSaleID
                               order by abs(SHI_SEQ) asc) loop
      lnSeq  := lnSeq + lnIncrement;
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoPackingElement, ltPackingElement);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltPackingElement, 'GCO_PACKING_ELEMENT_ID', ltplPackingElement.GCO_PACKING_ELEMENT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltPackingElement, 'SHI_SEQ', lnSeq);
      FWK_I_MGT_ENTITY.UpdateEntity(ltPackingElement);
      FWK_I_MGT_ENTITY.Release(ltPackingElement);
    end loop;
  end RenumberPackingElement;

  /**
  * procedure RenumberServicePlan
  * Description
  *   Rénumérote les plans de service d'une donnée compl. de SAV externe
  */
  procedure RenumberServicePlan(iComplExtAsaID in GCO_COMPL_DATA_EXTERNAL_ASA.GCO_COMPL_DATA_EXTERNAL_ASA_ID%type)
  is
    ltServicePlan FWK_I_TYP_DEFINITION.t_crud_def;
    lnIncrement   integer                         := 0;
    lnSeq         integer                         := 0;
  begin
    -- Définition de la valeur d'incrément
    begin
      lnIncrement  := to_number(PCS.PC_CONFIG.GetConfig('GCO_SERVICE_PLAN_NUMBERING') );
    exception
      when others then
        lnIncrement  := 10;
    end;

    if lnIncrement = 0 then
      lnIncrement  := 10;
    end if;

    -- Passer les valeurs des sequences à une valeur négative pour ne pas
    --  avoir de contrainte avec la PK2 unique durant le processus de renumérotation
    for ltplServicePlan in (select   GCO_SERVICE_PLAN_ID
                                   , SER_SEQ
                                from GCO_SERVICE_PLAN
                               where GCO_COMPL_DATA_EXTERNAL_ASA_ID = iComplExtAsaID
                            order by abs(SER_SEQ) asc) loop
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoServicePlan, ltServicePlan);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltServicePlan, 'GCO_SERVICE_PLAN_ID', ltplServicePlan.GCO_SERVICE_PLAN_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltServicePlan, 'SER_SEQ',(ltplServicePlan.SER_SEQ * -1) );
      FWK_I_MGT_ENTITY.UpdateEntity(ltServicePlan);
      FWK_I_MGT_ENTITY.Release(ltServicePlan);
    end loop;

    -- Renumérotation en fonction de l'ordre du n° de séquence
    for ltplServicePlan in (select   GCO_SERVICE_PLAN_ID
                                   , SER_SEQ
                                from GCO_SERVICE_PLAN
                               where GCO_COMPL_DATA_EXTERNAL_ASA_ID = iComplExtAsaID
                            order by abs(SER_SEQ) asc) loop
      lnSeq  := lnSeq + lnIncrement;
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_GCO_ENTITY.gcGcoServicePlan, ltServicePlan);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltServicePlan, 'GCO_SERVICE_PLAN_ID', ltplServicePlan.GCO_SERVICE_PLAN_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltServicePlan, 'SER_SEQ', lnSeq);
      FWK_I_MGT_ENTITY.UpdateEntity(ltServicePlan);
      FWK_I_MGT_ENTITY.Release(ltServicePlan);
    end loop;
  end RenumberServicePlan;
end GCO_PRC_COMPL_DATA;
