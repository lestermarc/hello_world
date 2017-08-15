--------------------------------------------------------
--  DDL for Package Body GCO_MGT_COMPL_DATA
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_MGT_COMPL_DATA" 
is
  /**
  * function insertCOMPL_DATA_ASS
  * Description
  *    Code métier de l'insertion d'une donnée compl. de SAV
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataAss : GCO_COMPL_DATA_ASS de type T_CRUD_DEF
  * @return ROWID
  */
  function insertCOMPL_DATA_ASS(iotComplDataAss in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataAss);
    -- retourne le rowid de l'enregistrement créé (obligatoire)
    return lResult;
  end insertCOMPL_DATA_ASS;

  /**
  * function updateCOMPL_DATA_ASS
  * Description
  *    Code métier de la modification d'une donnée compl. de SAV
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataAss : GCO_COMPL_DATA_ASS de type T_CRUD_DEF
  * @return ROWID
  */
  function updateCOMPL_DATA_ASS(iotComplDataAss in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataAss);
    -- retourne le rowid de l'enregistrement modifié (obligatoire)
    return lResult;
  end updateCOMPL_DATA_ASS;

   /**
  * function deleteCOMPL_DATA_ASS
  * Description
  *    Code métier de l'effacement d'une donnée compl. de SAV
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataAss : GCO_COMPL_DATA_ASS de type T_CRUD_DEF
  * @return ROWID
  */
  function deleteCOMPL_DATA_ASS(iotComplDataAss in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataAss);
    return null;
  end deleteCOMPL_DATA_ASS;

  /**
  * function insertCOMPL_DATA_DISTRIB
  * Description
  *    Code métier de l'insertion d'une donnée compl. de distribution
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataDistrib : GCO_COMPL_DATA_DISTRIB de type T_CRUD_DEF
  * @return ROWID
  */
  function insertCOMPL_DATA_DISTRIB(iotComplDataDistrib in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataDistrib);
    -- retourne le rowid de l'enregistrement créé (obligatoire)
    return lResult;
  end insertCOMPL_DATA_DISTRIB;

  /**
  * function updateCOMPL_DATA_DISTRIB
  * Description
  *    Code métier de la modification d'une donnée compl. de distribution
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataDistrib : GCO_COMPL_DATA_DISTRIB de type T_CRUD_DEF
  * @return ROWID
  */
  function updateCOMPL_DATA_DISTRIB(iotComplDataDistrib in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataDistrib);
    -- retourne le rowid de l'enregistrement modifié (obligatoire)
    return lResult;
  end updateCOMPL_DATA_DISTRIB;

  /**
  * function deleteCOMPL_DATA_DISTRIB
  * Description
  *    Code métier de l'effacement d'une donnée compl. de distribution
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataDistrib : GCO_COMPL_DATA_DISTRIB de type T_CRUD_DEF
  * @return ROWID
  */
  function deleteCOMPL_DATA_DISTRIB(iotComplDataDistrib in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataDistrib);
    return null;
  end deleteCOMPL_DATA_DISTRIB;

  /**
  * function insertCOMPL_DATA_EXTERNAL_ASA
  * Description
  *    Code métier de l'insertion d'une donnée compl. de SAV externe
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataExternalAsa : GCO_COMPL_DATA_EXTERNAL_ASA de type T_CRUD_DEF
  * @return ROWID
  */
  function insertCOMPL_DATA_EXTERNAL_ASA(iotComplDataExternalAsa in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataExternalAsa);
    -- retourne le rowid de l'enregistrement créé (obligatoire)
    return lResult;
  end insertCOMPL_DATA_EXTERNAL_ASA;

  /**
  * function updateCOMPL_DATA_EXTERNAL_ASA
  * Description
  *    Code métier de la modification d'une donnée compl. de SAV externe
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataExternalAsa : GCO_COMPL_DATA_EXTERNAL_ASA de type T_CRUD_DEF
  * @return ROWID
  */
  function updateCOMPL_DATA_EXTERNAL_ASA(iotComplDataExternalAsa in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataExternalAsa);
    -- retourne le rowid de l'enregistrement modifié (obligatoire)
    return lResult;
  end updateCOMPL_DATA_EXTERNAL_ASA;

  /**
  * function deleteCOMPL_DATA_EXTERNAL_ASA
  * Description
  *    Code métier de l'effacement d'une donnée compl. de SAV externe
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataExternalAsa : GCO_COMPL_DATA_EXTERNAL_ASA de type T_CRUD_DEF
  * @return ROWID
  */
  function deleteCOMPL_DATA_EXTERNAL_ASA(iotComplDataExternalAsa in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataExternalAsa);
    return null;
  end deleteCOMPL_DATA_EXTERNAL_ASA;

  /**
  * function insertCOMPL_DATA_INVENTORY
  * Description
  *    Code métier de l'insertion d'une donnée compl. d'inventaire
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataInventory : GCO_COMPL_DATA_INVENTORY de type T_CRUD_DEF
  * @return ROWID
  */
  function insertCOMPL_DATA_INVENTORY(iotComplDataInventory in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataInventory);
    -- retourne le rowid de l'enregistrement créé (obligatoire)
    return lResult;
  end insertCOMPL_DATA_INVENTORY;

  /**
  * function updateCOMPL_DATA_INVENTORY
  * Description
  *    Code métier de la modification d'une donnée compl. d'inventaire
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataInventory : GCO_COMPL_DATA_INVENTORY de type T_CRUD_DEF
  * @return ROWID
  */
  function updateCOMPL_DATA_INVENTORY(iotComplDataInventory in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataInventory);
    -- retourne le rowid de l'enregistrement modifié (obligatoire)
    return lResult;
  end updateCOMPL_DATA_INVENTORY;

  /**
  * function deleteCOMPL_DATA_INVENTORY
  * Description
  *    Code métier de l'effacement d'une donnée compl. d'inventaire
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataInventory : GCO_COMPL_DATA_INVENTORY de type T_CRUD_DEF
  * @return ROWID
  */
  function deleteCOMPL_DATA_INVENTORY(iotComplDataInventory in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataInventory);
    return null;
  end deleteCOMPL_DATA_INVENTORY;

  /**
  * function insertCOMPL_DATA_MANUFACTURE
  * Description
  *    Code métier de l'insertion d'une donnée compl. de fabrication
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataManufacture : GCO_COMPL_DATA_MANUFACTURE de type T_CRUD_DEF
  * @return ROWID
  */
  function insertCOMPL_DATA_MANUFACTURE(iotComplDataManufacture in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult    varchar2(40);
    lbContinue boolean;
  begin
    -- Initialisation des données en création
    GCO_PRC_CDA_MANUFACTURE.InitializeData(iotComplDataManufacture => iotComplDataManufacture);
    -- Contrôle de la cohérance des données
    lbContinue  := GCO_PRC_CDA_MANUFACTURE.ControlData(iotComplDataManufacture => iotComplDataManufacture);
    -- execution of CRUD instruction
    lResult     := fwk_i_dml_table.CRUD(iotComplDataManufacture);
    -- Màj du flag sur le bien indiquant qu'il possède ou pas des données compl. de fabrication
    GCO_PRC_CDA_MANUFACTURE.UpdateGoodManufacture
                                           (iGoodID   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotComplDataManufacture
                                                                                             , 'GCO_GOOD_ID'
                                                                                              )
                                           );
    -- retourne le rowid de l'enregistrement créé (obligatoire)
    return lResult;
  end insertCOMPL_DATA_MANUFACTURE;

  /**
  * function updateCOMPL_DATA_MANUFACTURE
  * Description
  *    Code métier de la modification d'une donnée compl. de fabrication
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataManufacture : GCO_COMPL_DATA_MANUFACTURE de type T_CRUD_DEF
  * @return ROWID
  */
  function updateCOMPL_DATA_MANUFACTURE(iotComplDataManufacture in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult    varchar2(40);
    lbContinue boolean;
  begin
    -- Contrôle de la cohérance des données
    lbContinue  := GCO_PRC_CDA_MANUFACTURE.ControlData(iotComplDataManufacture => iotComplDataManufacture);
    -- execution of CRUD instruction
    lResult     := fwk_i_dml_table.CRUD(iotComplDataManufacture);
    -- Màj du flag sur le bien indiquant qu'il possède ou pas des données compl. de fabrication
    GCO_PRC_CDA_MANUFACTURE.UpdateGoodManufacture
                                           (iGoodID   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotComplDataManufacture
                                                                                             , 'GCO_GOOD_ID'
                                                                                              )
                                           );
    -- retourne le rowid de l'enregistrement modifié (obligatoire)
    return lResult;
  end updateCOMPL_DATA_MANUFACTURE;

  /**
  * function deleteCOMPL_DATA_MANUFACTURE
  * Description
  *    Code métier de l'effacement d'une donnée compl. de fabrication
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataManufacture : GCO_COMPL_DATA_MANUFACTURE de type T_CRUD_DEF
  * @return ROWID
  */
  function deleteCOMPL_DATA_MANUFACTURE(iotComplDataManufacture in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataManufacture);
    -- Màj du flag sur le bien indiquant qu'il possède ou pas des données compl. de fabrication
    GCO_PRC_CDA_MANUFACTURE.UpdateGoodManufacture
                                           (iGoodID   => FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotComplDataManufacture
                                                                                             , 'GCO_GOOD_ID'
                                                                                              )
                                           );
    return null;
  end deleteCOMPL_DATA_MANUFACTURE;

  /**
  * function insertCOMPL_DATA_PURCHASE
  * Description
  *    Code métier de l'insertion d'une donnée compl. d'achat
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataPurchase : GCO_COMPL_DATA_PURCHASE de type T_CRUD_DEF
  * @return ROWID
  */
  function insertCOMPL_DATA_PURCHASE(iotComplDataPurchase in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataPurchase);
    -- retourne le rowid de l'enregistrement créé (obligatoire)
    return lResult;
  end insertCOMPL_DATA_PURCHASE;

  /**
  * function updateCOMPL_DATA_PURCHASE
  * Description
  *    Code métier de la modification d'une donnée compl. d'achat
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataPurchase : GCO_COMPL_DATA_PURCHASE de type T_CRUD_DEF
  * @return ROWID
  */
  function updateCOMPL_DATA_PURCHASE(iotComplDataPurchase in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataPurchase);
    -- retourne le rowid de l'enregistrement modifié (obligatoire)
    return lResult;
  end updateCOMPL_DATA_PURCHASE;

  /**
  * function deleteCOMPL_DATA_PURCHASE
  * Description
  *    Code métier de l'effacement d'une donnée compl. d'achat
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataPurchase : GCO_COMPL_DATA_PURCHASE de type T_CRUD_DEF
  * @return ROWID
  */
  function deleteCOMPL_DATA_PURCHASE(iotComplDataPurchase in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataPurchase);
    return null;
  end deleteCOMPL_DATA_PURCHASE;

  /**
  * function insertCOMPL_DATA_SALE
  * Description
  *    Code métier de l'insertion d'une donnée compl. de vente
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataSale : GCO_COMPL_DATA_SALE de type T_CRUD_DEF
  * @return ROWID
  */
  function insertCOMPL_DATA_SALE(iotComplDataSale in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataSale);
    -- retourne le rowid de l'enregistrement créé (obligatoire)
    return lResult;
  end insertCOMPL_DATA_SALE;

  /**
  * function updateCOMPL_DATA_SALE
  * Description
  *    Code métier de la modification d'une donnée compl. de vente
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataSale : GCO_COMPL_DATA_SALE de type T_CRUD_DEF
  * @return ROWID
  */
  function updateCOMPL_DATA_SALE(iotComplDataSale in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataSale);
    -- retourne le rowid de l'enregistrement modifié (obligatoire)
    return lResult;
  end updateCOMPL_DATA_SALE;

  /**
  * function deleteCOMPL_DATA_SALE
  * Description
  *    Code métier de l'effacement d'une donnée compl. de vente
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataSale : GCO_COMPL_DATA_SALE de type T_CRUD_DEF
  * @return ROWID
  */
  function deleteCOMPL_DATA_SALE(iotComplDataSale in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataSale);
    return null;
  end deleteCOMPL_DATA_SALE;

  /**
  * function insertCOMPL_DATA_STOCK
  * Description
  *    Code métier de l'insertion d'une donnée compl. de stock
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataStock : GCO_COMPL_DATA_STOCK de type T_CRUD_DEF
  * @return ROWID
  */
  function insertCOMPL_DATA_STOCK(iotComplDataStock in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataStock);
    -- retourne le rowid de l'enregistrement créé (obligatoire)
    return lResult;
  end insertCOMPL_DATA_STOCK;

  /**
  * function updateCOMPL_DATA_STOCK
  * Description
  *    Code métier de la modification d'une donnée compl. de stock
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataStock : GCO_COMPL_DATA_STOCK de type T_CRUD_DEF
  * @return ROWID
  */
  function updateCOMPL_DATA_STOCK(iotComplDataStock in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataStock);
    -- retourne le rowid de l'enregistrement modifié (obligatoire)
    return lResult;
  end updateCOMPL_DATA_STOCK;

  /**
  * function deleteCOMPL_DATA_STOCK
  * Description
  *    Code métier de l'effacement d'une donnée compl. de stock
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataStock : GCO_COMPL_DATA_STOCK de type T_CRUD_DEF
  * @return ROWID
  */
  function deleteCOMPL_DATA_STOCK(iotComplDataStock in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataStock);
    return null;
  end deleteCOMPL_DATA_STOCK;

  /**
  * function insertCOMPL_DATA_SUBCONTRACT
  * Description
  *    Code métier de l'insertion d'une donnée compl. de sous-traitance
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataSubcontract : GCO_COMPL_DATA_SUBCONTRACT de type T_CRUD_DEF
  * @return ROWID
  */
  function insertCOMPL_DATA_SUBCONTRACT(iotComplDataSubcontract in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataSubcontract);
    -- retourne le rowid de l'enregistrement créé (obligatoire)
    return lResult;
  end insertCOMPL_DATA_SUBCONTRACT;

  /**
  * function updateCOMPL_DATA_SUBCONTRACT
  * Description
  *    Code métier de la modification d'une donnée compl. de sous-traitance
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataSubcontract : GCO_COMPL_DATA_SUBCONTRACT de type T_CRUD_DEF
  * @return ROWID
  */
  function updateCOMPL_DATA_SUBCONTRACT(iotComplDataSubcontract in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataSubcontract);
    -- retourne le rowid de l'enregistrement modifié (obligatoire)
    return lResult;
  end updateCOMPL_DATA_SUBCONTRACT;

  /**
  * function deleteCOMPL_DATA_SUBCONTRACT
  * Description
  *    Code métier de l'effacement d'une donnée compl. de sous-traitance
  * @created NGV 12.2011
  * @lastUpdate
  * @public
  * @param iotComplDataSubcontract : GCO_COMPL_DATA_SUBCONTRACT de type T_CRUD_DEF
  * @return ROWID
  */
  function deleteCOMPL_DATA_SUBCONTRACT(iotComplDataSubcontract in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    -- execution of CRUD instruction
    lResult  := fwk_i_dml_table.CRUD(iotComplDataSubcontract);
    return null;
  end deleteCOMPL_DATA_SUBCONTRACT;
end GCO_MGT_COMPL_DATA;
