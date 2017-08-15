--------------------------------------------------------
--  DDL for Package Body DOC_INTERFACE_POSITION_CREATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_INTERFACE_POSITION_CREATE" 
is
  procedure CreateInterfacePosition(
    NewIntPositionID in out DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type
  , aIntPosNumber    in out DOC_INTERFACE_POSITION.DOP_POS_NUMBER%type
  , aInterfaceID     in     DOC_INTERFACE.DOC_INTERFACE_ID%type default null
  , aGaugeID         in     DOC_GAUGE.DOC_GAUGE_ID%type default null
  , aTypePos         in     DOC_POSITION.C_GAUGE_TYPE_POS%type default '1'
  , aGoodID          in     DOC_POSITION.GCO_GOOD_ID%type default null
  , aQuantity        in     DOC_POSITION.POS_FINAL_QUANTITY%type default null
  , aGoodPrice       in     DOC_POSITION.POS_GROSS_UNIT_VALUE%type default null
  , aRecordID        in     DOC_POSITION.DOC_RECORD_ID%type default null
  , aStockID         in     DOC_POSITION.STM_STOCK_ID%type default null
  , aLocationID      in     DOC_POSITION.STM_LOCATION_ID%type default null
  , aTraStockID      in     DOC_POSITION.STM_STM_STOCK_ID%type default null
  , aTraLocationID   in     DOC_POSITION.STM_STM_LOCATION_ID%type default null
  , aNetTariff       in     DOC_POSITION.POS_NET_TARIFF%type default 0
  , aSpecialTariff   in     DOC_POSITION.POS_SPECIAL_TARIFF%type default null
  , aFlatRate        in     DOC_POSITION.POS_FLAT_RATE%type default null
  , aCharID_1        in     DOC_INTERFACE_POSITION.GCO_CHARACTERIZATION_ID%type default null
  , aCharID_2        in     DOC_INTERFACE_POSITION.GCO_GCO_CHARACTERIZATION_ID%type default null
  , aCharID_3        in     DOC_INTERFACE_POSITION.GCO2_GCO_CHARACTERIZATION_ID%type default null
  , aCharID_4        in     DOC_INTERFACE_POSITION.GCO3_GCO_CHARACTERIZATION_ID%type default null
  , aCharID_5        in     DOC_INTERFACE_POSITION.GCO4_GCO_CHARACTERIZATION_ID%type default null
  , aCharValue_1     in     DOC_INTERFACE_POSITION.DOP_CHARACTERIZATION_VALUE_1%type default null
  , aCharValue_2     in     DOC_INTERFACE_POSITION.DOP_CHARACTERIZATION_VALUE_2%type default null
  , aCharValue_3     in     DOC_INTERFACE_POSITION.DOP_CHARACTERIZATION_VALUE_3%type default null
  , aCharValue_4     in     DOC_INTERFACE_POSITION.DOP_CHARACTERIZATION_VALUE_4%type default null
  , aCharValue_5     in     DOC_INTERFACE_POSITION.DOP_CHARACTERIZATION_VALUE_5%type default null
  , aDicPosFree_1    in     DOC_INTERFACE_POSITION.DIC_POS_FREE_TABLE_1_ID%type default null
  , aDicPosFree_2    in     DOC_INTERFACE_POSITION.DIC_POS_FREE_TABLE_2_ID%type default null
  , aDicPosFree_3    in     DOC_INTERFACE_POSITION.DIC_POS_FREE_TABLE_3_ID%type default null
  , aPosDecimal_1    in     DOC_INTERFACE_POSITION.DOP_POS_DECIMAL_1%type default null
  , aPosDecimal_2    in     DOC_INTERFACE_POSITION.DOP_POS_DECIMAL_2%type default null
  , aPosDecimal_3    in     DOC_INTERFACE_POSITION.DOP_POS_DECIMAL_3%type default null
  , aPosText_1       in     DOC_INTERFACE_POSITION.DOP_POS_TEXT_1%type default null
  , aPosText_2       in     DOC_INTERFACE_POSITION.DOP_POS_TEXT_2%type default null
  , aPosText_3       in     DOC_INTERFACE_POSITION.DOP_POS_TEXT_3%type default null
  , aPosDate_1       in     DOC_INTERFACE_POSITION.DOP_POS_DATE_1%type default null
  , aPosDate_2       in     DOC_INTERFACE_POSITION.DOP_POS_DATE_2%type default null
  , aPosDate_3       in     DOC_INTERFACE_POSITION.DOP_POS_DATE_3%type default null
  , aDicPdeFree_1    in     DOC_INTERFACE_POSITION.DIC_PDE_FREE_TABLE_1_ID%type default null
  , aDicPdeFree_2    in     DOC_INTERFACE_POSITION.DIC_PDE_FREE_TABLE_2_ID%type default null
  , aDicPdeFree_3    in     DOC_INTERFACE_POSITION.DIC_PDE_FREE_TABLE_3_ID%type default null
  , aPdeDecimal_1    in     DOC_INTERFACE_POSITION.DOP_PDE_DECIMAL_1%type default null
  , aPdeDecimal_2    in     DOC_INTERFACE_POSITION.DOP_PDE_DECIMAL_2%type default null
  , aPdeDecimal_3    in     DOC_INTERFACE_POSITION.DOP_PDE_DECIMAL_3%type default null
  , aPdeText_1       in     DOC_INTERFACE_POSITION.DOP_PDE_TEXT_1%type default null
  , aPdeText_2       in     DOC_INTERFACE_POSITION.DOP_PDE_TEXT_2%type default null
  , aPdeText_3       in     DOC_INTERFACE_POSITION.DOP_PDE_TEXT_3%type default null
  , aPdeDate_1       in     DOC_INTERFACE_POSITION.DOP_PDE_DATE_1%type default null
  , aPdeDate_2       in     DOC_INTERFACE_POSITION.DOP_PDE_DATE_2%type default null
  , aPdeDate_3       in     DOC_INTERFACE_POSITION.DOP_PDE_DATE_3%type default null
  )
  is
    -- Infos du DOC_INTERFACE
    cursor crInterfaceInfo(cInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
    is
      select PAC_THIRD_ID
           , nvl(PAC_THIRD_ACI_ID, PAC_THIRD_ID) PAC_THIRD_ACI_ID
           , nvl(PAC_THIRD_DELIVERY_ID, PAC_THIRD_ID) PAC_THIRD_DELIVERY_ID
           , DOC_GAUGE_ID
           , PAC_REPRESENTATIVE_ID
           , DOC_RECORD_ID
           , DIC_TYPE_SUBMISSION_ID
           , ACS_VAT_DET_ACCOUNT_ID
           , DIC_POS_FREE_TABLE_1_ID
           , DIC_POS_FREE_TABLE_2_ID
           , DIC_POS_FREE_TABLE_3_ID
           , DOI_TEXT_1
           , DOI_TEXT_2
           , DOI_TEXT_3
           , nvl(DOI_DECIMAL_1, 0) DOI_DECIMAL_1
           , nvl(DOI_DECIMAL_2, 0) DOI_DECIMAL_2
           , nvl(DOI_DECIMAL_3, 0) DOI_DECIMAL_3
           , DOI_DATE_1
           , DOI_DATE_2
           , DOI_DATE_3
        from DOC_INTERFACE
       where DOC_INTERFACE_ID = cInterfaceID;

    tplInterfaceInfo       crInterfaceInfo%rowtype;
    tmpGaugeID             DOC_GAUGE.DOC_GAUGE_ID%type;
    tmpGapIncludeTaxTariff DOC_GAUGE_POSITION.GAP_INCLUDE_TAX_TARIFF%type;
    tmpAcsTaxCodeID        DOC_POSITION.ACS_TAX_CODE_ID%type;
    tmpAdminDomain         DOC_GAUGE.C_ADMIN_DOMAIN%type;
    tmpDicTypeMvtID        DOC_GAUGE_STRUCTURED.DIC_TYPE_MOVEMENT_ID%type;
    tmpProductDeliveryTyp  GCO_PRODUCT.C_PRODUCT_DELIVERY_TYP%type;
  begin
    open crInterfaceInfo(aInterfaceID);

    fetch crInterfaceInfo
     into tplInterfaceInfo;

    if crInterfaceInfo%found then
      if NewIntPositionID is null then
        select INIT_ID_SEQ.nextval
          into NewIntPositionID
          from dual;
      end if;

      -- ID du gabarit passé en param ou bien celui définit dans le DOC_INTERFACE
      tmpGaugeID       := nvl(aGaugeID, tplInterfaceInfo.DOC_GAUGE_ID);

      -- Rechercher le n° de position si pas renseigné
      if aIntPosNumber is null then
        aIntPosNumber  := DOC_INTERFACE_POSITION_FCT.GetNewPosNumber(tmpGaugeID, aInterfaceID);
      end if;

      -- Recherche si position TTC ou HT
      select GAP.GAP_INCLUDE_TAX_TARIFF
           , GAU.C_ADMIN_DOMAIN
           , nvl(GAP.DIC_TYPE_MOVEMENT_ID, GAS.DIC_TYPE_MOVEMENT_ID)
        into tmpGapIncludeTaxTariff
           , tmpAdminDomain
           , tmpDicTypeMvtID
        from DOC_GAUGE_POSITION GAP
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GAS
       where GAU.DOC_GAUGE_ID = tmpGaugeID
         and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID(+)
         and GAU.DOC_GAUGE_ID = GAP.DOC_GAUGE_ID(+)
         and GAP.C_GAUGE_TYPE_POS(+) = aTypePos
         and GAP.GAP_DEFAULT(+) = 1;

      -- Type de livraison du produit
      select PDT.C_PRODUCT_DELIVERY_TYP
        into tmpProductDeliveryTyp
        from GCO_PRODUCT PDT
           , GCO_GOOD GOO
       where GOO.GCO_GOOD_ID = aGoodID
         and GOO.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+);

      -- Code TVA
      tmpAcsTaxCodeID  :=
        ACS_I_LIB_LOGISTIC_FINANCIAL.GetVatCode(iCode              => 1
                                              , iThirdId           => tplInterfaceInfo.PAC_THIRD_ID
                                              , iGoodId            => aGoodID
                                              , iDiscountId        => null
                                              , iChargeId          => null
                                              , iAdminDomain       => tmpAdminDomain
                                              , iSubmissionType    => tplInterfaceInfo.DIC_TYPE_SUBMISSION_ID
                                              , iMovementType      => tmpDicTypeMvtID
                                              , iVatDetAccountId   => tplInterfaceInfo.ACS_VAT_DET_ACCOUNT_ID
                                               );

      insert into DOC_INTERFACE_POSITION
                  (DOC_INTERFACE_POSITION_ID
                 , DOC_INTERFACE_ID
                 , DOP_POS_NUMBER
                 , C_GAUGE_TYPE_POS
                 , C_DOP_INTERFACE_FAIL_REASON
                 , C_DOP_INTERFACE_STATUS
                 , DOC_GAUGE_ID
                 , GCO_GOOD_ID
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , STM_STM_STOCK_ID
                 , STM_STM_LOCATION_ID
                 , DOC_RECORD_ID
                 , PAC_REPRESENTATIVE_ID
                 , DOP_INCLUDE_TAX_TARIFF
                 , DOP_NET_TARIFF
                 , DOP_SPECIAL_TARIFF
                 , DOP_FLAT_RATE
                 , ACS_TAX_CODE_ID
                 , DIC_POS_FREE_TABLE_1_ID
                 , DIC_POS_FREE_TABLE_2_ID
                 , DIC_POS_FREE_TABLE_3_ID
                 , DOP_POS_DECIMAL_1
                 , DOP_POS_DECIMAL_2
                 , DOP_POS_DECIMAL_3
                 , DOP_POS_TEXT_1
                 , DOP_POS_TEXT_2
                 , DOP_POS_TEXT_3
                 , DOP_POS_DATE_1
                 , DOP_POS_DATE_2
                 , DOP_POS_DATE_3
                 , DIC_PDE_FREE_TABLE_1_ID
                 , DIC_PDE_FREE_TABLE_2_ID
                 , DIC_PDE_FREE_TABLE_3_ID
                 , DOP_PDE_DECIMAL_1
                 , DOP_PDE_DECIMAL_2
                 , DOP_PDE_DECIMAL_3
                 , DOP_PDE_TEXT_1
                 , DOP_PDE_TEXT_2
                 , DOP_PDE_TEXT_3
                 , DOP_PDE_DATE_1
                 , DOP_PDE_DATE_2
                 , DOP_PDE_DATE_3
                 , DOP_QTY
                 , DOP_QTY_VALUE
                 , DOP_USE_GOOD_PRICE
                 , DOP_GROSS_UNIT_VALUE
                 , C_PRODUCT_DELIVERY_TYP
                 , GCO_CHARACTERIZATION_ID
                 , GCO_GCO_CHARACTERIZATION_ID
                 , GCO2_GCO_CHARACTERIZATION_ID
                 , GCO3_GCO_CHARACTERIZATION_ID
                 , GCO4_GCO_CHARACTERIZATION_ID
                 , DOP_CHARACTERIZATION_VALUE_1
                 , DOP_CHARACTERIZATION_VALUE_2
                 , DOP_CHARACTERIZATION_VALUE_3
                 , DOP_CHARACTERIZATION_VALUE_4
                 , DOP_CHARACTERIZATION_VALUE_5
                 , A_DATECRE
                 , A_IDCRE
                  )
        select NewIntPositionID
             , aInterfaceID
             , aIntPosNumber
             , aTypePos
             , ''
             , '01'
             , GAU.DOC_GAUGE_ID
             , aGoodID
             , aStockID
             , aLocationID
             , aTraStockID
             , aTraLocationID
             , decode(nvl(GAU.GAU_DOSSIER, 0), 0, null, nvl(aRecordID, tplInterfaceInfo.DOC_RECORD_ID) )
             , decode(nvl(GAU.GAU_TRAVELLER, 0), 0, null, tplInterfaceInfo.PAC_REPRESENTATIVE_ID)
             , tmpGapIncludeTaxTariff
             , nvl(aNetTariff, 0)
             , nvl(aSpecialTariff, 0)
             , nvl(aFlatRate, 0)
             , tmpAcsTaxCodeID
             , nvl(aDicPosFree_1, tplInterfaceInfo.DIC_POS_FREE_TABLE_1_ID)
             , nvl(aDicPosFree_2, tplInterfaceInfo.DIC_POS_FREE_TABLE_2_ID)
             , nvl(aDicPosFree_3, tplInterfaceInfo.DIC_POS_FREE_TABLE_3_ID)
             , nvl(aPosDecimal_1, tplInterfaceInfo.DOI_DECIMAL_1)
             , nvl(aPosDecimal_2, tplInterfaceInfo.DOI_DECIMAL_2)
             , nvl(aPosDecimal_3, tplInterfaceInfo.DOI_DECIMAL_3)
             , nvl(aPosText_1, tplInterfaceInfo.DOI_TEXT_1)
             , nvl(aPosText_2, tplInterfaceInfo.DOI_TEXT_2)
             , nvl(aPosText_3, tplInterfaceInfo.DOI_TEXT_3)
             , nvl(aPosDate_1, tplInterfaceInfo.DOI_DATE_1)
             , nvl(aPosDate_2, tplInterfaceInfo.DOI_DATE_2)
             , nvl(aPosDate_3, tplInterfaceInfo.DOI_DATE_3)
             , aDicPdeFree_1
             , aDicPdeFree_2
             , aDicPdeFree_3
             , aPdeDecimal_1
             , aPdeDecimal_2
             , aPdeDecimal_3
             , aPdeText_1
             , aPdeText_2
             , aPdeText_3
             , aPdeDate_1
             , aPdeDate_2
             , aPdeDate_3
             , aQuantity
             , aQuantity
             , decode(aGoodPrice, null, 0, 1)
             , aGoodPrice
             , tmpProductDeliveryTyp
             , aCharID_1
             , aCharID_2
             , aCharID_3
             , aCharID_4
             , aCharID_5
             , aCharValue_1
             , aCharValue_2
             , aCharValue_3
             , aCharValue_4
             , aCharValue_5
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from DOC_GAUGE GAU
         where GAU.DOC_GAUGE_ID = tmpGaugeID;
    end if;

    close crInterfaceInfo;
  end CreateInterfacePosition;

  /**
  * Description
  *
  *     Création de la position d'interface document pour l'interface passé en
  *     paramètre. Initialise uniquement les champs dépendants de l'en-tête et
  *     les champs indépendant.
  */
  procedure CREATE_INTERFACE_POSITION(
    pInterfaceId       in     DOC_INTERFACE.DOC_INTERFACE_ID%type   /* Id de la l'interface document */
  , pConfigGaugeName   in     DOC_GAUGE.GAU_DESCRIBE%type   /* Gabarit de configuration de l'interface document */
  , pDfltGaugeId       in     DOC_GAUGE.DOC_GAUGE_ID%type   /* ID du gabarit de destination */
  , pPositionType      in     DOC_GAUGE_POSITION.C_GAUGE_TYPE_POS%type   /* Type de position */
  , pNewInterfacePosId in out DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type   /* Id de la nouvelle interface document */
  , c_admin_domain     in     doc_gauge.c_admin_domain%type default '2'
  )
  is
    vInterfaceThirdId            DOC_INTERFACE.PAC_THIRD_ID%type;   /* Tiers de l'interface*/
    vInterfaceRepresentId        DOC_INTERFACE.PAC_REPRESENTATIVE_ID%type;   /* Représentant de l'en-tête*/
    vInterfaceRecordId           DOC_INTERFACE.DOC_RECORD_ID%type;   /* Dossier de l'interface*/
    vInterfaceFreeTable1         DOC_INTERFACE.DIC_POS_FREE_TABLE_1_ID%type;   /* Code tabelle libre 1 de l'en-tête*/
    vInterfaceText1              DOC_INTERFACE.DOI_TEXT_1%type;   /* Champ Texte 1*/
    vInterfaceDecimal1           DOC_INTERFACE.DOI_DECIMAL_1%type;   /* Champ décimal 1 */
    vInterfaceDate1              DOC_INTERFACE.DOI_DATE_1%type;   /* Champ Date 1*/
    vInterfaceFreeTable2         DOC_INTERFACE.DIC_POS_FREE_TABLE_2_ID%type;   /* Code tabelle libre 2 de l'en-tête*/
    vInterfaceText2              DOC_INTERFACE.DOI_TEXT_2%type;   /* Champ Texte 2*/
    vInterfaceDecimal2           DOC_INTERFACE.DOI_DECIMAL_2%type;   /* Champ décimal 2 */
    vInterfaceDate2              DOC_INTERFACE.DOI_DATE_2%type;   /* Champ Date 2*/
    vInterfaceFreeTable3         DOC_INTERFACE.DIC_POS_FREE_TABLE_3_ID%type;   /* Code tabelle libre 3 de l'en-tête*/
    vInterfaceText3              DOC_INTERFACE.DOI_TEXT_3%type;   /* Champ Texte 3*/
    vInterfaceDecimal3           DOC_INTERFACE.DOI_DECIMAL_3%type;   /* Champ décimal 3 */
    vInterfaceDate3              DOC_INTERFACE.DOI_DATE_3%type;   /* Champ Date 3*/
    vConfigGaugeId               DOC_INTERFACE_POSITION.DOC_GAUGE_ID%type;
    vDfltGaugeId                 DOC_INTERFACE_POSITION.DOC_GAUGE_ID%type;
    vConfigGaugeIncludeTaxTariff DOC_GAUGE_POSITION.GAP_INCLUDE_TAX_TARIFF%type;   /* Prix TTC du gabarit position*/
    vConfigGaugeRecord           DOC_GAUGE.GAU_DOSSIER%type;   /* Gestion dossier du gabarit*/
    vConfigGaugeTraveller        DOC_GAUGE.GAU_TRAVELLER%type;   /* Gestion représentant du gabarit*/
  begin
    /* Réception des données de l'en-tête*/
    DOC_INTERFACE_POSITION_FCT.GetInterfaceInfoForCreation(pInterfaceId   /* Interface courant*/
                                                         , vInterfaceThirdId   /* Tiers de l'interface*/
                                                         , vInterfaceRepresentId   /* Représentant de l'en-tête*/
                                                         , vInterfaceRecordId   /* Dossier de l'interface*/
                                                         , vInterfaceFreeTable1   /* Code tabelle libre 1 de l'en-tête*/
                                                         , vInterfaceText1   /* Champ Texte 1*/
                                                         , vInterfaceDecimal1   /* Champ décimal 1 */
                                                         , vInterfaceDate1   /* Champ Date 1*/
                                                         , vInterfaceFreeTable2   /* Code tabelle libre 2 de l'en-tête*/
                                                         , vInterfaceText2   /* Champ Texte 2*/
                                                         , vInterfaceDecimal2   /* Champ décimal 2 */
                                                         , vInterfaceDate2   /* Champ Date 2*/
                                                         , vInterfaceFreeTable3   /* Code tabelle libre 3 de l'en-tête*/
                                                         , vInterfaceText3   /* Champ Texte 3*/
                                                         , vInterfaceDecimal3   /* Champ décimal 3 */
                                                         , vInterfaceDate3   /* Champ Date 3*/
                                                          );
    /* Réception de l'id du gabarit de configuration de l'interface document.
      On reprend le nom du gabarit transmis en paramètre et s'il est null,
      celui de la configuration. */
    vConfigGaugeId  := DOC_INTERFACE_FCT.GetGaugeId(nvl(pConfigGaugeName, PCS.PC_CONFIG.GETCONFIG('DOC_CART_CONFIG_GAUGE') ) );

    /* Réception de l'id du gabarit par défaut. On reprend le gabarit transmis en
       paramètre et s'il et null, celui du partenaire de l'interface document. */
    if    (pDfltGaugeId = 0)
       or (pDfltGaugeId is null) then
      vDfltGaugeId  := null;
    else
      vDfltGaugeId  := pDfltGaugeId;
    end if;

    if c_admin_domain = '1' then
      vDfltGaugeId  := vDfltGaugeId;
    elsif c_admin_domain = '2' then
      vDfltGaugeId  := nvl(vDfltGaugeId, DOC_INTERFACE_FCT.GetDefltGaugeId(vInterfaceThirdId) );
    elsif c_admin_domain = '3' then
      vDfltGaugeId  := vDfltGaugeId;
    end if;

    /*Réception des données du gabarit de config*/
    DOC_INTERFACE_POSITION_FCT.GetConfigGaugeInfo(vConfigGaugeId   /*Gabarit de config*/
                                                , vConfigGaugeIncludeTaxTariff   /*Prix TTC du gabarit position*/
                                                , vConfigGaugeRecord   /*Gestion dossier du gabarit*/
                                                , vConfigGaugeTraveller   /*Gestion représentant du gabarit*/
                                                 );

    if vConfigGaugeRecord is null then
      vInterfaceRecordId  := null;
    end if;

    if vConfigGaugeTraveller is null then
      vInterfaceRepresentId  := null;
    end if;

    select INIT_ID_SEQ.nextval
      into pNewInterfacePosId
      from dual;

    insert into DOC_INTERFACE_POSITION
                (A_DATECRE   /* Date de création*/
               , A_IDCRE   /* ID de création*/
               , C_DOP_INTERFACE_FAIL_REASON   /* Code erreur position interface*/
               , C_DOP_INTERFACE_STATUS   /* Statut de la position*/
               , C_GAUGE_TYPE_POS   /* Type de position*/
               , C_PRODUCT_DELIVERY_TYP   /* Code reliquat du produit*/
               , DIC_POS_FREE_TABLE_1_ID   /* Code tabelle libre 1*/
               , DIC_POS_FREE_TABLE_2_ID   /* Code tabelle libre 2*/
               , DIC_POS_FREE_TABLE_3_ID   /* Code tabelle libre 3*/
               , DOC_GAUGE_ID   /* Gabarit*/
               , DOC_INTERFACE_ID   /* Interface document*/
               , DOC_INTERFACE_POSITION_ID   /* Position interface document*/
               , DOC_RECORD_ID   /* ID dossier*/
               , DOP_INCLUDE_TAX_TARIFF   /* Prix TTC*/
               , DOP_NET_TARIFF   /* Tarif net*/
               , DOP_POS_DECIMAL_1   /* Décimal 1 position*/
               , DOP_POS_DECIMAL_2   /* Décimal 2 position*/
               , DOP_POS_DECIMAL_3   /* Décimal 3 position*/
               , DOP_POS_NUMBER   /* Numéro de position*/
               , DOP_POS_TEXT_1   /* Texte 1 position*/
               , DOP_POS_TEXT_2   /* Texte 2 position*/
               , DOP_POS_TEXT_3   /* Texte 3 position*/
               , DOP_POS_DATE_1   /* Date 1 position*/
               , DOP_POS_DATE_2   /* Date 2 position*/
               , DOP_POS_DATE_3   /* Date 3 position*/
               , DOP_QTY   /* Quantité*/
               , DOP_QTY_VALUE   /* Quantité valorisée*/
               , PAC_REPRESENTATIVE_ID   /* Représentant*/
                )
         values (sysdate   /* Date de création                -> Date système*/
               , PCS.PC_I_LIB_SESSION.GetUserIni   /* ID de création*/
               , ''   /* Code erreur position interface  -> */
               , '01'   /* Statut de la position           -> 'En préparation' */
               , nvl(pPositionType, '1')   /* Type de position                -> Bien */
               , ''   /* Code reliquat du produit        -> */
               , vInterfaceFreeTable1   /* Code tabelle libre 1            -> Repris de l'en-tête*/
               , vInterfaceFreeTable2   /* Code tabelle libre 2            -> Repris de l'en-tête*/
               , vInterfaceFreeTable3   /* Code tabelle libre 3            -> Repris de l'en-tête*/
               , vDfltGaugeId   /* Gabarit                         -> Gabarit par défaut*/
               , pInterfaceId   /* Interface document              -> Initialisé par paramètre entrant*/
               , pNewInterfacePosId   /* Position interface document     -> nouvel Id*/
               , vInterfaceRecordId   /* Dossier                         -> Repris de l'en-tête si géré par gabarit*/
               , vConfigGaugeIncludeTaxTariff   /* Prix TTC                        -> Repris du gabarit de config*/
               , 0   /* Tarif net */
               , vInterfaceDecimal1   /* Décimal 1 position              -> Repris de l'en-tête */
               , vInterfaceDecimal2   /* Décimal 2 position              -> Repris de l'en-tête */
               , vInterfaceDecimal3   /* Décimal 3 position             -> Repris de l'en-tête */
               , DOC_INTERFACE_POSITION_FCT.GetNewPosNumber(vConfigGaugeId, pInterfaceId)   /*Numéro de position*/
               , vInterfaceText1   /* Texte 1 position                -> Repris de l'en-tête*/
               , vInterfaceText2   /* Texte 2 position                -> Repris de l'en-tête*/
               , vInterfaceText3   /* Texte 3 position                -> Repris de l'en-tête*/
               , vInterfaceDate1   /* Date 1 position                -> Repris de l'en-tête*/
               , vInterfaceDate2   /* Date 2 position                -> Repris de l'en-tête*/
               , vInterfaceDate3   /* Date 3 position                -> Repris de l'en-tête*/
               , 0   /* Quantité                        -> */
               , 0   /* Quantité valorisée              -> */
               , vInterfaceRepresentId   /* Représentant  ->  Repris de l'en-tête si géré par gabarit*/
                );
  end CREATE_INTERFACE_POSITION;

  /**
  * Description
  *
  *     Mise à jour des données de la position d'interface iniallement créée
  *     Initialisation des champs dépendant de l'article, des données complémentaires...
  */
  procedure UPDATE_INTERFACE_POSITION(
    pInterfaceId         in DOC_INTERFACE_POSITION.DOC_INTERFACE_ID%type
  , pinterfacepositionid in doc_interface_position.doc_interface_position_id%type
  , pgoodid              in doc_interface_position.gco_good_id%type
  , c_admin_domain       in doc_gauge.c_admin_domain%type default '2'
  )
  is
    vGoodCharId1           GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;   /*Caractérisation 1*/
    vGoodCharId2           GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;   /*Caractérisation 2*/
    vGoodCharId3           GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;   /*Caractérisation 3*/
    vGoodCharId4           GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;   /*Caractérisation 4*/
    vGoodCharId5           GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;   /*Caractérisation 5*/
    vGoodDelivery          GCO_PRODUCT.C_PRODUCT_DELIVERY_TYP%type;   /*Type de livraison du bien*/
    vGoodStockId           STM_STOCK.STM_STOCK_ID%type;   /*Stock données complémentaires*/
    vGoodLocationId        STM_LOCATION.STM_LOCATION_ID%type;   /*Emplacement données complémentaires*/
    vStockId               STM_STOCK.STM_STOCK_ID%type;   /*Stock par défaut de la position*/
    vLocationId            STM_LOCATION.STM_LOCATION_ID%type;   /*Emplacement par défaut de la position*/
    vtargetStockId         STM_STOCK.STM_STOCK_ID%type;   /*Stock transfert par défaut de la position*/
    vTargetLocationId      STM_LOCATION.STM_LOCATION_ID%type;   /*Emplacement transfert par défaut de la position*/
    vGoodStkManagement     GCO_PRODUCT.PDT_STOCK_MANAGEMENT%type;   /*gestion stock*/
    vInitStk               DOC_GAUGE_POSITION.GAP_INIT_STOCK_PLACE%type;   /*initialisation stock et emplacement*/
    vUseMvtStk             DOC_GAUGE_POSITION.GAP_MVT_UTILITY%type;   /*Utilisation du stock du mouvement*/
    vMvtKindId             STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;   /*Genre de mouvement*/
    vInterfaceThirdId      PAC_THIRD.PAC_THIRD_ID%type;   /*Partenaire*/
    vDicComplData          DIC_COMPLEMENTARY_DATA.DIC_COMPLEMENTARY_DATA_ID%type;   /*Code donnée complémenatire*/
    vDicSubmissionId       DIC_TYPE_SUBMISSION.DIC_TYPE_SUBMISSION_ID%type;
    vVatDetAccountId       ACS_VAT_DET_ACCOUNT.ACS_VAT_DET_ACCOUNT_ID%type;
    vDomain                DOC_GAUGE.C_ADMIN_DOMAIN%type;
    vDicMvtType            DIC_TYPE_MOVEMENT.DIC_TYPE_MOVEMENT_ID%type;
    vGaugeType             DOC_GAUGE_POSITION.C_GAUGE_TYPE_POS%type;
    vTaxCodeId             ACS_TAX_CODE.ACS_TAX_CODE_ID%type;
    vGaugeId               doc_gauge.doc_gauge_id%type;
    vPAC_THIRD_ID          PAC_THIRD.PAC_THIRD_ID%type;
    vPAC_THIRD_ACI_ID      PAC_THIRD.PAC_THIRD_ID%type;
    vPAC_THIRD_DELIVERY_ID PAC_THIRD.PAC_THIRD_ID%type;
    vPAC_THIRD_VAT_ID      PAC_THIRD.PAC_THIRD_ID%type;
    vC_GAU_THIRD_VAT       DOC_GAUGE.C_GAU_THIRD_VAT%type;
  begin
    if c_admin_domain = '1' then
      select DOC.PAC_THIRD_ID
           , nvl(DOC.PAC_THIRD_ACI_ID, DOC.PAC_THIRD_ID) PAC_THIRD_ACI_ID
           , nvl(DOC.PAC_THIRD_DELIVERY_ID, DOC.PAC_THIRD_ID) PAC_THIRD_DELIVERY_ID
           , SUP.DIC_COMPLEMENTARY_DATA_ID
           , DOC.DIC_TYPE_SUBMISSION_ID
           , DOC.ACS_VAT_DET_ACCOUNT_ID
        into vPAC_THIRD_ID
           , vPAC_THIRD_ACI_ID
           , vPAC_THIRD_DELIVERY_ID
           , vdiccompldata
           , vdicsubmissionid
           , vvatdetaccountid
        from DOC_INTERFACE DOC
           , PAC_SUPPLIER_PARTNER SUP
       where SUP.PAC_SUPPLIER_PARTNER_ID = DOC.PAC_THIRD_ID
         and DOC.DOC_INTERFACE_ID = pinterfaceid;
    elsif c_admin_domain = '2' then
      select DOC.PAC_THIRD_ID
           , nvl(DOC.PAC_THIRD_ACI_ID, DOC.PAC_THIRD_ID) PAC_THIRD_ACI_ID
           , nvl(DOC.PAC_THIRD_DELIVERY_ID, DOC.PAC_THIRD_ID) PAC_THIRD_DELIVERY_ID
           , PAC.DIC_COMPLEMENTARY_DATA_ID
           , DOC.DIC_TYPE_SUBMISSION_ID
           , DOC.ACS_VAT_DET_ACCOUNT_ID
        into vPAC_THIRD_ID
           , vPAC_THIRD_ACI_ID
           , vPAC_THIRD_DELIVERY_ID
           , vdiccompldata
           , vdicsubmissionid
           , vvatdetaccountid
        from DOC_INTERFACE DOC
           , PAC_CUSTOM_PARTNER PAC
       where PAC.PAC_CUSTOM_PARTNER_ID = DOC.PAC_THIRD_ID
         and DOC.DOC_INTERFACE_ID = pinterfaceid;
    elsif c_admin_domain = '3' then
      vPAC_THIRD_ID           := null;
      vPAC_THIRD_ACI_ID       := null;
      vPAC_THIRD_DELIVERY_ID  := null;
      vdiccompldata           := null;
      vdicsubmissionid        := null;
      vvatdetaccountid        := null;
    end if;

    select doc_gauge_id
         , c_gauge_type_pos
      into vGaugeId
         , vGaugeType
      from doc_interface_position dop
     where dop.doc_interface_position_id = pInterfacePositionId;

    if vGaugeId is not null then
      select GAU.C_ADMIN_DOMAIN
           , GAP.GAP_INIT_STOCK_PLACE
           , GAP.GAP_MVT_UTILITY
           , GAP.STM_MOVEMENT_KIND_ID
           , nvl(GAP.DIC_TYPE_MOVEMENT_ID, GAS.DIC_TYPE_MOVEMENT_ID)
           , GAU.C_GAU_THIRD_VAT
        into vDomain
           , vInitStk
           , vUseMvtStk
           , vMvtKindId
           , vDicMvtType
           , vC_GAU_THIRD_VAT
        from DOC_GAUGE GAU
           , DOC_GAUGE_POSITION GAP
           , DOC_GAUGE_STRUCTURED GAS
       where GAU.DOC_GAUGE_ID = vGaugeId
         and GAS.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and GAP.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
         and GAP.C_GAUGE_TYPE_POS = vGaugeType
         and GAP.GAP_DEFAULT = 1;
    else
      /*Recherche données sur gabarit de config*/
      select GAU.C_ADMIN_DOMAIN
           , GAP.GAP_INIT_STOCK_PLACE
           , GAP.GAP_MVT_UTILITY
           , GAP.STM_MOVEMENT_KIND_ID
           , GAU.C_GAU_THIRD_VAT
        into vDomain
           , vInitStk
           , vUseMvtStk
           , vMvtKindId
           , vC_GAU_THIRD_VAT
        from DOC_GAUGE GAU
           , DOC_GAUGE_POSITION GAP
       where GAU.DOC_GAUGE_ID = DOC_INTERFACE_FCT.GetGaugeId(PCS.PC_CONFIG.GETCONFIG('DOC_CART_CONFIG_GAUGE') )
         and GAP.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and GAP.C_GAUGE_TYPE_POS = '1';

      /*Réception de l'id du gabarit par défaut*/
      select nvl(GAP.DIC_TYPE_MOVEMENT_ID, GAS.DIC_TYPE_MOVEMENT_ID)
        into vDicMvtType
        from DOC_GAUGE_STRUCTURED GAS
           , DOC_GAUGE_POSITION GAP
       where GAS.DOC_GAUGE_ID = DOC_INTERFACE_FCT.GetDefltGaugeId(vInterfaceThirdId)
         and GAP.DOC_GAUGE_ID(+) = GAS.DOC_GAUGE_ID
         and GAP.C_GAUGE_TYPE_POS(+) = PCS.PC_CONFIG.GETCONFIG('DOC_CART_TYP_POS')
         and GAP.GAP_DEFAULT(+) = 1;
    end if;

    /*Réception des données du bien*/
    DOC_INTERFACE_POSITION_FCT.GetGoodInfo(pGoodId
                                         , vGoodCharId1   /*Caractérisation 1*/
                                         , vGoodCharId2   /*Caractérisation 2*/
                                         , vGoodCharId3   /*Caractérisation 3*/
                                         , vGoodCharId4   /*Caractérisation 4*/
                                         , vGoodCharId5   /*Caractérisation 5*/
                                         , vGoodDelivery   /*Type de livraison du bien*/
                                         , vGoodStkManagement   /*Gestion stock*/
                                          );

    /*Réception des données complémenatires achat ou vente */
    if c_admin_domain in('1', '2') then
      DOC_INTERFACE_POSITION_FCT.GetComplData(pGoodId, vInterfaceThirdId, vDicComplData, c_admin_domain, vGaugeType, vGoodStockId, vGoodLocationId);
    end if;

    update DOC_INTERFACE_POSITION
       set GCO_GOOD_ID = pGoodId
         , GCO_CHARACTERIZATION_ID = vGoodCharId1
         , GCO_GCO_CHARACTERIZATION_ID = vGoodCharId2
         , GCO2_GCO_CHARACTERIZATION_ID = vGoodCharId3
         , GCO3_GCO_CHARACTERIZATION_ID = vGoodCharId4
         , GCO4_GCO_CHARACTERIZATION_ID = vGoodCharId5
         , C_PRODUCT_DELIVERY_TYP = vGoodDelivery
         , C_GAUGE_TYPE_POS = nvl(C_GAUGE_TYPE_POS, vGaugeType)
         , DOP_QTY = 0
         , DOP_QTY_VALUE = 0
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_INTERFACE_POSITION_ID = pInterfacePositionId;
  end UPDATE_INTERFACE_POSITION;

  /**
  * Description
  *
  *     Mise à jour des données de la position en fonction de l'interface position.
  *     La procèdure demande le code d'origine de la génération pour garantir
  *     une complatibilité avec la version précédente.
  */
  procedure UpdatePositionFromInterface(
    pInterfacePositionID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type
  , pPositionID          in DOC_POSITION.DOC_POSITION_ID%type
  , pOriginCode          in DOC_INTERFACE.C_DOC_INTERFACE_ORIGIN%type
  )
  is
    cursor crGetPositionProc(cInterfacePositionID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
    is
      select   DOG.DOG_POSITION_PROC
             , DOG.DOG_SUBTYPE
          from DOC_INTERFACE DOI
             , DOC_INTERFACE_CONFIG DOG
             , DOC_INTERFACE_POSITION DIP
         where DIP.DOC_INTERFACE_POSITION_ID = cInterfacePositionID
           and DIP.DOC_INTERFACE_ID = DOI.DOC_INTERFACE_ID
           and DOI.C_DOC_INTERFACE_ORIGIN = DOG.C_DOC_INTERFACE_ORIGIN
      union
      select   DOG.DOG_POSITION_PROC
             , DOG.DOG_SUBTYPE
          from DOC_INTERFACE DOI
             , DOC_INTERFACE_CONFIG DOG
             , DOC_INTERFACE_POSITION DIP
         where DIP.DOC_INTERFACE_POSITION_ID = cInterfacePositionID
           and DIP.DOC_INTERFACE_ID = DOI.DOC_INTERFACE_ID
           and DOI.C_DOC_INTERFACE_ORIGIN = DOG.C_DOC_INTERFACE_ORIGIN
           and DOI.DOI_SUBTYPE = DOG.DOG_SUBTYPE
      order by 2;

    tplGetPositionProc crGetPositionProc%rowtype;
    cid                integer;
    ignore             integer;
    SqlCmd             varchar2(2000);
  begin
    open crGetPositionProc(pInterfacePositionID);

    fetch crGetPositionProc
     into tplGetPositionProc;

    -- Aucune procédure à executer n'a été renseignée
    if tplGetPositionProc.DOG_POSITION_PROC is null then
      -- Mise à jour des données de la position en fonction de l'interface, méthode PCS
      UpdatePositionFromInterfacePCS(pInterfacePositionID, pPositionID, pOriginCode);
    else   -- Executer la procédure utilisateur en DBMS_SQL
      SqlCmd  :=
        'BEGIN ' || tplGetPositionProc.DOG_POSITION_PROC || '(' || to_char(pInterfacePositionID) || ',' || to_char(pPositionID) || ',' || pOriginCode || '); '
        || 'END;';
      -- Ouverture du curseur
      cid     := DBMS_SQL.OPEN_CURSOR;
      DBMS_SQL.PARSE(cid, SqlCmd, DBMS_SQL.v7);
      -- Exécution de la procédure
      ignore  := DBMS_SQL.execute(cid);
      -- Ferme le curseur
      DBMS_SQL.CLOSE_CURSOR(cid);
    end if;

    close crGetPositionProc;
  end UpdatePositionFromInterface;

  /**
  * Description
  *
  *     Mise à jour des données du détail position en fonction de l'interface position.
  */
  procedure UpdatePosDetailFromInterface(
    pInterfacePositionID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type
  , pDetailPositionId    in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , pOriginCode          in DOC_INTERFACE.C_DOC_INTERFACE_ORIGIN%type
  )
  is
    cursor crGetDetailProc(cInterfaceID in DOC_INTERFACE.DOC_INTERFACE_ID%type)
    is
      select   DOG.DOG_POSITION_DETAIL_PROC
             , DOG.DOG_SUBTYPE
          from DOC_INTERFACE DOI
             , DOC_INTERFACE_CONFIG DOG
             , DOC_INTERFACE_POSITION DIP
         where DOI.DOC_INTERFACE_ID = cInterfaceID
           and DOI.C_DOC_INTERFACE_ORIGIN = DOG.C_DOC_INTERFACE_ORIGIN
           and DOI.DOC_INTERFACE_ID = DIP.DOC_INTERFACE_ID
      union
      select   DOG.DOG_POSITION_DETAIL_PROC
             , DOG.DOG_SUBTYPE
          from DOC_INTERFACE DOI
             , DOC_INTERFACE_CONFIG DOG
             , DOC_INTERFACE_POSITION DIP
         where DOI.DOC_INTERFACE_ID = cInterfaceID
           and DOI.C_DOC_INTERFACE_ORIGIN = DOG.C_DOC_INTERFACE_ORIGIN
           and DOI.DOI_SUBTYPE = DOG.DOG_SUBTYPE
           and DOI.DOC_INTERFACE_ID = DIP.DOC_INTERFACE_ID
      order by 2;

    tplGetDetailProc crGetDetailProc%rowtype;
    cid              integer;
    ignore           integer;
    SqlCmd           varchar2(2000);
  begin
    open crGetDetailProc(pInterfacePositionID);

    fetch crGetDetailProc
     into tplGetDetailProc;

    -- Aucune procédure à executer n'a été renseignée
    if tplGetDetailProc.DOG_POSITION_DETAIL_PROC is null then
      -- Mise à jour des données de la position en fonction de l'interface, méthode PCS
      UpdateDetailFromInterfacePCS(pInterfacePositionID, pDetailPositionId, pOriginCode);
    else   -- Executer la procédure utilisateur en DBMS_SQL
      SqlCmd  :=
        'BEGIN ' ||
        tplGetDetailProc.DOG_POSITION_DETAIL_PROC ||
        '(' ||
        to_char(pInterfacePositionID) ||
        ',' ||
        to_char(pDetailPositionId) ||
        ',' ||
        pOriginCode ||
        '); ' ||
        'END;';
      -- Ouverture du curseur
      cid     := DBMS_SQL.OPEN_CURSOR;
      DBMS_SQL.PARSE(cid, SqlCmd, DBMS_SQL.v7);
      -- Exécution de la procédure
      ignore  := DBMS_SQL.execute(cid);
      -- Ferme le curseur
      DBMS_SQL.CLOSE_CURSOR(cid);
    end if;

    close crGetDetailProc;
  end UpdatePosDetailFromInterface;

  /**
  * Description
  *
  *     Mise à jour des données de la position en fonction de l'interface position.
  *     La procèdure demande le code d'origine de la génération pour garantir
  *     une complatibilité avec la version précédente.
  */
  procedure UpdatePositionFromInterfacePCS(
    pInterfacePositionID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type
  , pPositionID          in DOC_POSITION.DOC_POSITION_ID%type
  , pOriginCode          in DOC_INTERFACE.C_DOC_INTERFACE_ORIGIN%type
  )
  is
  begin
    if (pOriginCode = '201') then   /* EDI */
      update DOC_POSITION POS
         set (POS.POS_REFERENCE, POS.C_POS_DELIVERY_TYP, POS.POS_VAT_AMOUNT, POS.POS_VAT_BASE_AMOUNT, POS.POS_VAT_AMOUNT_V
            , POS.POS_GROSS_UNIT_VALUE   -- DOP_GROSS_UNIT_VALUE, INCLUDE_TAX_TARIFF = 0
            , POS.POS_GROSS_UNIT_VALUE_INCL   -- DOP_GROSS_UNIT_VALUE, INCLUDE_TAX_TARIFF = 1
                                           --
              , POS.POS_NET_UNIT_VALUE, POS.POS_NET_UNIT_VALUE_INCL
                                                                   --
              , POS.POS_REF_UNIT_VALUE
                                      --
              , POS.POS_GROSS_VALUE   -- DOP_GROSS_VALUE
                                   , POS.POS_GROSS_VALUE_B, POS.POS_GROSS_VALUE_V, POS.POS_GROSS_VALUE_INCL, POS.POS_GROSS_VALUE_INCL_B
            , POS.POS_GROSS_VALUE_INCL_V, POS.POS_NET_VALUE_EXCL   -- DOP_NET_VALUE_EXCL
                                                                , POS.POS_NET_VALUE_EXCL_B, POS.POS_NET_VALUE_EXCL_V
            , POS.POS_NET_VALUE_INCL   -- DOP_NET_VALUE_INCL
                                    , POS.POS_NET_VALUE_INCL_B, POS.POS_NET_VALUE_INCL_V, POS.POS_INCLUDE_TAX_TARIFF   -- DOP_INCLUDE_TAX_TARIFF
            , POS.POS_NET_TARIFF   -- DOP_NET_TARIFF
                                , POS.POS_DISCOUNT_RATE   -- DOP_DISCOUNT_RATE
                                                       , POS.DOC_RECORD_ID, POS.PAC_REPRESENTATIVE_ID, POS.DIC_POS_FREE_TABLE_1_ID, POS.POS_TEXT_1
            , POS.POS_DECIMAL_1, POS.POS_DATE_1, POS.DIC_POS_FREE_TABLE_2_ID, POS.POS_TEXT_2, POS.POS_DECIMAL_2, POS.POS_DATE_2, POS.DIC_POS_FREE_TABLE_3_ID
            , POS.POS_TEXT_3, POS.POS_DECIMAL_3, POS.POS_DATE_3, POS.POS_SHORT_DESCRIPTION, POS.POS_LONG_DESCRIPTION, POS.POS_FREE_DESCRIPTION
            , POS.PC_APPLTXT_ID, POS.POS_BODY_TEXT) =
               (select nvl(DOP.DOP_MAJOR_REFERENCE, POS.POS_REFERENCE)
                     , nvl(DOP.C_PRODUCT_DELIVERY_TYP, POS.C_POS_DELIVERY_TYP)
                     , DOP.DOP_NET_VALUE_INCL - DOP.DOP_NET_VALUE_EXCL
                     , DOP.DOP_NET_VALUE_INCL - DOP.DOP_NET_VALUE_EXCL
                     , DOP.DOP_NET_VALUE_INCL - DOP.DOP_NET_VALUE_EXCL
                     , decode(DOP.DOP_INCLUDE_TAX_TARIFF, 0, nvl(DOP.DOP_GROSS_UNIT_VALUE, POS.POS_GROSS_UNIT_VALUE), 1, 0)
                     , decode(DOP.DOP_INCLUDE_TAX_TARIFF, 0, 0, 1, nvl(DOP.DOP_GROSS_UNIT_VALUE, POS.POS_GROSS_UNIT_VALUE) )
                     , decode(DOP.DOP_NET_VALUE_EXCL, null, POS.POS_NET_UNIT_VALUE, DOP.DOP_NET_VALUE_EXCL / DOP.DOP_QTY)
                     , decode(DOP.DOP_NET_VALUE_INCL, null, POS.POS_NET_UNIT_VALUE_INCL, DOP.DOP_NET_VALUE_INCL / DOP.DOP_QTY)
                     , 0
                     , decode(DOP.DOP_INCLUDE_TAX_TARIFF, 0, nvl(DOP.DOP_GROSS_VALUE, POS.POS_GROSS_VALUE), 1, 0)
                     , decode(DOP.DOP_INCLUDE_TAX_TARIFF, 0, nvl(DOP.DOP_GROSS_VALUE, POS.POS_GROSS_VALUE), 1, 0)
                     , decode(DOP.DOP_INCLUDE_TAX_TARIFF, 0, nvl(DOP.DOP_GROSS_VALUE, POS.POS_GROSS_VALUE), 1, 0)
                     , decode(DOP.DOP_INCLUDE_TAX_TARIFF, 0, 0, 1, nvl(DOP.DOP_GROSS_VALUE, POS.POS_GROSS_VALUE_INCL) )
                     , decode(DOP.DOP_INCLUDE_TAX_TARIFF, 0, 0, 1, nvl(DOP.DOP_GROSS_VALUE, POS.POS_GROSS_VALUE_INCL) )
                     , decode(DOP.DOP_INCLUDE_TAX_TARIFF, 0, 0, 1, nvl(DOP.DOP_GROSS_VALUE, POS.POS_GROSS_VALUE_INCL) )
                     , nvl(DOP.DOP_NET_VALUE_EXCL, POS.POS_NET_VALUE_EXCL)
                     , nvl(DOP.DOP_NET_VALUE_EXCL, POS.POS_NET_VALUE_EXCL)
                     , nvl(DOP.DOP_NET_VALUE_EXCL, POS.POS_NET_VALUE_EXCL)
                     , nvl(DOP.DOP_NET_VALUE_INCL, POS.POS_NET_VALUE_INCL)
                     , nvl(DOP.DOP_NET_VALUE_INCL, POS.POS_NET_VALUE_INCL)
                     , nvl(DOP.DOP_NET_VALUE_INCL, POS.POS_NET_VALUE_INCL)
                     , nvl(DOP.DOP_INCLUDE_TAX_TARIFF, POS.POS_INCLUDE_TAX_TARIFF)
                     , nvl(DOP.DOP_NET_TARIFF, POS.POS_NET_TARIFF)
                     , nvl(DOP.DOP_DISCOUNT_RATE, POS.POS_DISCOUNT_RATE)
                     , nvl(DOP.DOC_RECORD_ID, POS.DOC_RECORD_ID)
                     , nvl(DOP.PAC_REPRESENTATIVE_ID, POS.PAC_REPRESENTATIVE_ID)
                     , nvl(DOP.DIC_POS_FREE_TABLE_1_ID, POS.DIC_POS_FREE_TABLE_1_ID)
                     , nvl(DOP.DOP_POS_TEXT_1, POS.POS_TEXT_1)
                     , nvl(DOP.DOP_POS_DECIMAL_1, POS.POS_DECIMAL_1)
                     , nvl(DOP.DOP_POS_DATE_1, POS.POS_DATE_1)
                     , nvl(DOP.DIC_POS_FREE_TABLE_2_ID, POS.DIC_POS_FREE_TABLE_2_ID)
                     , nvl(DOP.DOP_POS_TEXT_2, POS.POS_TEXT_2)
                     , nvl(DOP.DOP_POS_DECIMAL_2, POS.POS_DECIMAL_2)
                     , nvl(DOP.DOP_POS_DATE_2, POS.POS_DATE_2)
                     , nvl(DOP.DIC_POS_FREE_TABLE_3_ID, POS.DIC_POS_FREE_TABLE_3_ID)
                     , nvl(DOP.DOP_POS_TEXT_3, POS.POS_TEXT_3)
                     , nvl(DOP.DOP_POS_DECIMAL_3, POS.POS_DECIMAL_3)
                     , nvl(DOP.DOP_POS_DATE_3, POS.POS_DATE_3)
                     , nvl(DOP.DOP_SHORT_DESCRIPTION, POS.POS_SHORT_DESCRIPTION)
                     , nvl(DOP.DOP_LONG_DESCRIPTION, POS.POS_LONG_DESCRIPTION)
                     , nvl(DOP.DOP_FREE_DESCRIPTION, POS.POS_FREE_DESCRIPTION)
                     , decode(DOP.DOP_BODY_TEXT, null, POS.PC_APPLTXT_ID, null)   -- POS.PC_APPLTXT_ID
                     , nvl(DOP.DOP_BODY_TEXT, POS.POS_BODY_TEXT)
                  from DOC_INTERFACE_POSITION DOP
                 where DOP.DOC_INTERFACE_POSITION_ID = pInterfacePositionID)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where POS.DOC_POSITION_ID = pPositionID;
    else   /* Autres */
      update DOC_POSITION POS
         set (POS.DIC_POS_FREE_TABLE_1_ID, POS.POS_TEXT_1, POS.POS_DECIMAL_1, POS.POS_DATE_1, POS.DIC_POS_FREE_TABLE_2_ID, POS.POS_TEXT_2, POS.POS_DECIMAL_2
            , POS.POS_DATE_2, POS.DIC_POS_FREE_TABLE_3_ID, POS.POS_TEXT_3, POS.POS_DECIMAL_3, POS.POS_DATE_3, POS.POS_SHORT_DESCRIPTION
            , POS.POS_LONG_DESCRIPTION, POS.POS_FREE_DESCRIPTION, POS.PC_APPLTXT_ID, POS.POS_BODY_TEXT) =
               (select nvl(DOP.DIC_POS_FREE_TABLE_1_ID, POS.DIC_POS_FREE_TABLE_1_ID)
                     , nvl(DOP.DOP_POS_TEXT_1, POS.POS_TEXT_1)
                     , nvl(DOP.DOP_POS_DECIMAL_1, POS.POS_DECIMAL_1)
                     , nvl(DOP.DOP_POS_DATE_1, POS.POS_DATE_1)
                     , nvl(DOP.DIC_POS_FREE_TABLE_2_ID, POS.DIC_POS_FREE_TABLE_2_ID)
                     , nvl(DOP.DOP_POS_TEXT_2, POS.POS_TEXT_2)
                     , nvl(DOP.DOP_POS_DECIMAL_2, POS.POS_DECIMAL_2)
                     , nvl(DOP.DOP_POS_DATE_2, POS.POS_DATE_2)
                     , nvl(DOP.DIC_POS_FREE_TABLE_3_ID, POS.DIC_POS_FREE_TABLE_3_ID)
                     , nvl(DOP.DOP_POS_TEXT_3, POS.POS_TEXT_3)
                     , nvl(DOP.DOP_POS_DECIMAL_3, POS.POS_DECIMAL_3)
                     , nvl(DOP.DOP_POS_DATE_3, POS.POS_DATE_3)
                     , nvl(DOP.DOP_SHORT_DESCRIPTION, POS.POS_SHORT_DESCRIPTION)
                     , nvl(DOP.DOP_LONG_DESCRIPTION, POS.POS_LONG_DESCRIPTION)
                     , nvl(DOP.DOP_FREE_DESCRIPTION, POS.POS_FREE_DESCRIPTION)
                     , decode(DOP.DOP_BODY_TEXT, null, POS.PC_APPLTXT_ID, null)   -- POS.PC_APPLTXT_ID
                     , nvl(DOP.DOP_BODY_TEXT, POS.POS_BODY_TEXT)
                  from DOC_INTERFACE_POSITION DOP
                 where DOP.DOC_INTERFACE_POSITION_ID = pInterfacePositionID)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where POS.DOC_POSITION_ID = pPositionID;
    end if;
  end UpdatePositionFromInterfacePCS;

  /**
  * Description
  *
  *     Mise à jour des données du détail position en fonction de l'interface position.
  */
  procedure UpdateDetailFromInterfacePCS(
    pInterfacePositionID in DOC_INTERFACE_POSITION.DOC_INTERFACE_POSITION_ID%type
  , pDetailPositionId    in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , pOriginCode          in DOC_INTERFACE.C_DOC_INTERFACE_ORIGIN%type
  )
  is
  begin
    -- Mise à jour des délais individuellement.
    -- Régle :
    -- si gap_delay = 0 -> délai = null
    -- sinon -> si délai interface est null -> délai = date système
    --          sinon -> délai interface
    --
    update DOC_POSITION_DETAIL
       set (PDE_BASIS_DELAY, PDE_INTERMEDIATE_DELAY, PDE_FINAL_DELAY) =
             (select decode(GAP.GAP_DELAY, 0, null, nvl(DOP.DOP_BASIS_DELAY, trunc(sysdate) ) )
                   , decode(GAP.GAP_DELAY, 0, null, nvl(DOP.DOP_INTERMEDIATE_DELAY, trunc(sysdate) ) )
                   , decode(GAP.GAP_DELAY, 0, null, nvl(DOP.DOP_FINAL_DELAY, trunc(sysdate) ) )
                from DOC_INTERFACE_POSITION DOP
                   , DOC_POSITION POS
                   , DOC_POSITION_DETAIL PDE
                   , DOC_GAUGE_POSITION GAP
               where PDE.DOC_POSITION_DETAIL_ID = pDetailPositionId
                 and DOP.DOC_INTERFACE_POSITION_ID = pInterfacePositionId
                 and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                 and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID)
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_POSITION_DETAIL_ID = pDetailPositionId;
  end UpdateDetailFromInterfacePCS;
end DOC_INTERFACE_POSITION_CREATE;
