--------------------------------------------------------
--  DDL for Package Body GCO_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_FUNCTIONS" 
is
  -- constantes
  -- constantes descodes
  -- C_CHARAC_TYPE
  cCharacTypeVersion        constant char(1) := '1';
  cCharacTypeCharacteristic constant char(1) := '2';
  cCharacTypePiece          constant char(1) := '3';
  cCharacTypeSet            constant char(1) := '4';
  cCharacTypeChrono         constant char(1) := '5';
  -- C_ELEMENT_TYPE
  cElementTypeSet           constant char(2) := '01';
  cElementTypePiece         constant char(2) := '02';
  cElementTypeVersion       constant char(2) := '03';
  -- C_ADMIN_DOMAIN
  cAdminDomainPurchase      constant char(1) := '1';
  cAdminDomainSale          constant char(1) := '2';
  cAdminDomainStock         constant char(1) := '3';
  cAdminDomainFAL           constant char(1) := '4';
  cAdminDomainSubContract   constant char(1) := '5';
  cAdminDomainQuality       constant char(1) := '6';
  cAdminDomainASA           constant char(1) := '7';
  cAdminDomainInventory     constant char(1) := '8';
  -- C_MANAGEMENT_MODE
  cManagementModePRCS       constant char(1) := '1';
  cManagementModePRC        constant char(1) := '2';
  cManagementModePRF        constant char(1) := '3';
  -- C_CHRONOLOGY_TYPE
  cChronologyTypeFifo       constant char(1) := '1';
  cChronologyTypeLifo       constant char(1) := '2';
  cChronologyTypePeremption constant char(1) := '3';
  -- C_UNIT_OF_TIME
  cUnitOfTimeInstantaneous  constant char(1) := '1';
  cUnitOfTimeMinute         constant char(1) := '2';
  cUnitOfTimeHeure          constant char(1) := '3';
  cUnitOfTimeHalfDay        constant char(1) := '4';
  cUnitOfTimeDay            constant char(1) := '5';
  cUnitOfTimeWeek           constant char(1) := '6';
  cUnitOfTimeMonth          constant char(1) := '7';
  cUnitOfTimeQuarter        constant char(1) := '8';
  cUnitOfTimeHalfYear       constant char(1) := '9';
  cUnitOfTimeYear           constant char(2) := '10';

  /*
  * Permet d'insérer les records manquants dans la table GCO_COMPL_DATA_DISTRIB
  * en pour tous les produits d'un groupe de produits
  */
  procedure InsertIntoComplDistrib(aComplDistrId in number)
  is
  begin
    GCO_PRC_COMPL_DATA.InsertIntoComplDistrib(aComplDistrId);
  end InsertIntoComplDistrib;

  /**
  * Description
  *    Return major reference from good ID
  */
  function getMajorReference(aGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return GCO_GOOD.GOO_MAJOR_REFERENCE%type
  is
  begin
    return GCO_LIB_FUNCTIONS.getMajorReference(aGoodId);
  end;

  /**
  * Description
  *    look for good management mode
  */
  function getManagementMode(aGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return GCO_GOOD.C_MANAGEMENT_MODE%type
  is
  begin
    return GCO_LIB_FUNCTIONS.getManagementMode(aGoodId);
  end getManagementMode;

  /**
  * Description
  *    Renvoie le prix de revient par rapport au mode de gestion du produit
  */
  function GetCostPriceWithManagementMode(
    aGCO_GOOD_ID    in GCO_GOOD.GCO_GOOD_ID%type
  , aPAC_THIRD_ID   in number default null
  , aManagementMode in varchar2 default null
  , aDateRef        in date default null
  )
    return number
  is
  begin
    return GCO_LIB_PRICE.GetCostPriceWithManagementMode(aGCO_GOOD_ID, aPAC_THIRD_ID, aManagementMode, aDateRef);
  end GetCostPriceWithManagementMode;

-----------------------------------------------------------------------------------------------------------------------
--Mise à jour du statut du bien avec celui passé en paramètre}
  procedure UPDATE_GOOD_STATUS(GoodId GCO_GOOD.GCO_GOOD_ID%type, GoodStatus GCO_GOOD.C_GOOD_STATUS%type)
  is
  begin
    GCO_PRC_GOOD.updateStatus(GoodId, GoodStatus);
  end UPDATE_GOOD_STATUS;

-----------------------------------------------------------------------------------------------------------------------
--Fonction de retour du flag "Bloquer pour inventaire" des données complémentaires d'inventaire du bien
  function GetFixedStockPosition(
    GoodId     GCO_COMPL_DATA_INVENTORY.GCO_GOOD_ID%type
  , StockId    GCO_COMPL_DATA_INVENTORY.STM_STOCK_ID%type
  , LocationId GCO_COMPL_DATA_INVENTORY.STM_LOCATION_ID%type
  )
    return GCO_COMPL_DATA_INVENTORY.CIN_FIXED_STOCK_POSITION%type
  is
  begin
    return GCO_LIB_COMPL_DATA.GetFixedStockPosition(GoodId, StockId, LocationId);
  end GetFixedStockPosition;

-----------------------------------------------------------------------------------------------------------------------
  function GetQuantityMin(vGCO_GOOD_ID in number)
    return number
  is
  begin
    return GCO_LIB_COMPL_DATA.GetQuantityMin(vGCO_GOOD_ID);
  end GetQuantityMin;

-----------------------------------------------------------------------------------------------------------------------
  function GetPurchaseConvertFactor(aGoodId in number, aThirdId in number)
    return number
  is
  begin
    return PTC_FIND_TARIFF.GetPurchaseConvertFactor(aGoodId, aThirdId);
  end GetPurchaseConvertFactor;

-----------------------------------------------------------------------------------------------------------------------

  /**
  * Description
  *        Retourne l'id des données complémentaires d'achat  liées au couple bien/client
  */
  function GetComplDataPurchaseId(aGoodId in number, aThirdId in number)
    return number
  is
  begin
    return GCO_LIB_COMPL_DATA.GetComplDataPurchaseId(aGoodId, aThirdId);
  end GetComplDataPurchaseId;

-----------------------------------------------------------------------------------------------------------------------

  /**
  * Description
  *        Retourne l'id des données complémentaires de vente  liées au couple bien/client
  */
  function GetComplDataSaleId(aGoodId in number, aThirdId in number)
    return number
  is
  begin
    return GCO_LIB_COMPL_DATA.GetComplDataSaleId(aGoodId, aThirdId);
  end GetComplDataSaleId;

-----------------------------------------------------------------------------------------------------------------------
  function GetSaleConvertFactor(aGoodId in number, aThirdId in number)
    return number
  is
  begin
    return PTC_FIND_TARIFF.GetSaleConvertFactor(aGoodId, aThirdId);
  end GetSaleConvertFactor;

  /**
  * Description
  *   recherche le prix du dernier mouvement d'entrée
  */
  function GetLastInputPrice(aGoodId number)
    return STM_STOCK_MOVEMENT.SMO_UNIT_PRICE%type
  is
  begin
    return GCO_LIB_PRICE.GetLastInputPrice(aGoodId);
  end GetLastInputPrice;

  /**
  * Description
  *       fonction qui renvoie le prix du bien selon le type de prix demandé.
  * Remarque
  *       Cette fonction est destinée à la recherche d'un prix dans des
  *       commmandes SELET, ou des VIEWS.
  */
  function GetGoodPriceForView(
    GoodId            in number
  , TypePrice         in varchar2
  , ThirdId           in number
  , RecordId          in number
  , FalScheduleStepId in number
  , aDicTariff        in varchar2
  , Quantity          in number
  , DateRef           in date
  , CurrencyId        in number
  , aDic_Tariff2      in varchar2 default null
  )
    return number
  is
  begin
    return GCO_LIB_PRICE.GetGoodPriceForView(GoodId, TypePrice, ThirdId, RecordId, FalScheduleStepId, aDicTariff, Quantity, DateRef, CurrencyId, aDic_Tariff2);
  end GetGoodPriceForView;

  /**
  * Description
  *       Recherche du nombre de décimal des données complémentaires
  */
  procedure GetCDANumberOfDecimal(aGoodId in number, aType in varchar2, aThirdId in number, aLangId in number, aNumberOfDecimal out number)
  is
  begin
    GCO_LIB_COMPL_DATA.GetCDANumberOfDecimal(aGoodId, aType, aThirdId, aLangId, aNumberOfDecimal);
  end GetCDANumberOfDecimal;

  /**
  * function GetNumberOfDecimal
  * Description
  *       Recherche du nombre de décimales
  * @created fp 13.11.2003
  * @public
  * @param aGoodId           : id du bien
  * @return : nombre de décimal
  */
  function GetNumberOfDecimal(aGoodId in number)
    return number
  is
  begin
    return GCO_LIB_FUNCTIONS.GetNumberOfDecimal(aGoodId);
  end GetNumberOfDecimal;

  /**
  * Description
  *      Retourne les id de caractérisation selon la position désirée
  *      en supprimant les caractérisations non gérées en stock
  */
  function getStkCharPosId(aGoodId in number, aPos in number)
    return number
  is
  begin
    return GCO_LIB_CHARACTERIZATION.getStkCharPosId(aGoodId, aPos);
  end getStkCharPosId;

  /**
  * procedure getStkCharPosValue
  * Description
  *      Retourne les valeur de caractérisation selon la position désirée
  *      en supprimant les caractérisations non gérées en stock
  */
  function getStkCharPosValue(
    aGoodId       in number
  , aPos          in number
  , aCharacValue1 in varchar2
  , aCharacValue2 in varchar2
  , aCharacValue3 in varchar2
  , aCharacValue4 in varchar2
  , aCharacValue5 in varchar2
  )
    return varchar2
  is
  begin
    return GCO_LIB_CHARACTERIZATION.getStkCharPosValue(aGoodId, aPos, aCharacValue1, aCharacValue2, aCharacValue3, aCharacValue4, aCharacValue5);
  end getStkCharPosValue;

  /**
  * Description
  *    Décorticage des types de caractérisations et renvoi par genre
  */
  procedure ClassifyCharacterizations(
    aCharac1Id     in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharac2Id     in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharac3Id     in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharac4Id     in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharac5Id     in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharValue1    in     varchar2
  , aCharValue2    in     varchar2
  , aCharValue3    in     varchar2
  , aCharValue4    in     varchar2
  , aCharValue5    in     varchar2
  , aPiece         out    varchar2
  , aSet           out    varchar2
  , aVersion       out    varchar2
  , aChronological out    varchar2
  , aCharStd1      out    varchar2
  , aCharStd2      out    varchar2
  , aCharStd3      out    varchar2
  , aCharStd4      out    varchar2
  , aCharStd5      out    varchar2
  )
  is
  begin
    GCO_LIB_CHARACTERIZATION.ClassifyCharacterizations(aCharac1Id
                                                     , aCharac2Id
                                                     , aCharac3Id
                                                     , aCharac4Id
                                                     , aCharac5Id
                                                     , aCharValue1
                                                     , aCharValue2
                                                     , aCharValue3
                                                     , aCharValue4
                                                     , aCharValue5
                                                     , aPiece
                                                     , aSet
                                                     , aVersion
                                                     , aChronological
                                                     , aCharStd1
                                                     , aCharStd2
                                                     , aCharStd3
                                                     , aCharStd4
                                                     , aCharStd5
                                                      );
  end ClassifyCharacterizations;

  /**
  * Description
  *        fonction qui retourne la valeur de caractérisation pour la gestion FIFO/LIFO
  */
  function PropChronologicalFormat(aCharacterizationID in number, aBasisTime date)
    return varchar2
  is
  begin
    return GCO_LIB_CHARACTERIZATION.PropChronologicalFormat(aCharacterizationID, aBasisTime);
  end PropChronologicalFormat;

  /**
  * Description
  *        fonction qui vérifie l'intégrité d'une valeur de caractérisation
  */
  function VerifyCharFormat(
    aCharacterizationID in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aValue              in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  )
    return number
  is
  begin
    return GCO_LIB_CHARACTERIZATION.VerifyCharFormat(aCharacterizationID, aValue);
  end VerifyCharFormat;

  /**
  * Description
  *        fonction qui vérifie l'intégrité d'une valeur de caractérisation
  *        pour la gestion FIFO/LIFO
  */
  function VerifyChronologicalFormat(
    aCharacterizationID in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aValue              in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  )
    return number
  is
  begin
    return GCO_LIB_CHARACTERIZATION.VerifyChronologicalFormat(aCharacterizationID, aValue);
  end VerifyChronologicalFormat;

  /**
  * Description
  *        fonction qui vérifie l'intégrité d'une valeur de caractérisation
  *        pour la gestion FIFO/LIFO
  */
  function VerifyChronologicalFormatCode(
    aChronologyType in GCO_CHARACTERIZATION.C_CHRONOLOGY_TYPE%type
  , aUnitOfTime     in GCO_CHARACTERIZATION.C_UNIT_OF_TIME%type
  , aValue          in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  )
    return number
  is
  begin
    return GCO_LIB_CHARACTERIZATION.VerifyChronologicalFormatCode(aChronologyType, aUnitOfTime, aValue);
  end VerifyChronologicalFormatCode;

  /*
  * procedure GetAutoIncrementInfo
  *   procedure qui retourne la valeur du dernier numéro
  *   de pièce utilisé pour les caractérisations de type
  *   autoincrémental ainsi que la valeur du pas d'incrément
  */
  procedure GetAutoIncrementInfo(
    aCharacterizationID in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aLastUsedNumber     out    number
  , aIncrementStep      out    number
  , aPrefix             out    varchar2
  , aSuffix             out    varchar2
  , aAutoIncFunction    out    number
  , aAutoInc            out    number
  , aUnique             out    number
  , aStockManagement    out    number
  )
  is
    lnLenNumber  GCO_CHARACTERIZATION.CHA_NUMBER%type := 0;
  begin
    GCO_LIB_CHARACTERIZATION.GetAutoIncrementInfo(aCharacterizationID
                                                , aLastUsedNumber
                                                , aIncrementStep
                                                , aPrefix
                                                , lnLenNumber
                                                , aSuffix
                                                , aAutoIncFunction
                                                , aAutoInc
                                                , aUnique
                                                , aStockManagement
                                                 );
  end GetAutoIncrementInfo;

  /**
  * Description
  *        procedure qui retourne la valeur de caractérization suivante
  *        en fonction des information de numérotation automatique
  */
  function GetNextCharValue(
    aCharacterizationID in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aDocPositionId      in number default null
  , aFalLotId           in number default null
  )
    return varchar2
  is
  begin
    return GCO_LIB_CHARACTERIZATION.GetNextCharValue(aCharacterizationID, aDocPositionId, aFalLotId);
  end GetNextCharValue;

  /**
  * Description
  *       Retourne le nombre de décimal des données complémentaires et si pas
  *       trouvé, le nombre de décimal du bien.
  */
  function GetCDADecimal(AGoodId in GCO_GOOD.GCO_GOOD_ID%type, AType in varchar2, AThirdId in number)
    return number
  is
  begin
    return GCO_LIB_COMPL_DATA.GetCDADecimal(AGoodId, AType, AThirdId);
  end GetCDADecimal;

  /**
  * Description
  *    Retourne la prochaine valeur chronologique depuis le stock existant
  *    selon la règle :
  *      Type de chronologie = 2 (LIFO) : sélectionner les caractérisations les
  *        plus récentes disponibles dans l'emplacements du détail de position.
  *      Type de chronologie = 1 (FIFO) : sélectionner les caractérisations les
  *        plus anciennes disponibles dans l'emplacement du détail de position.
  *      Type de chornologie = 3 (Péremption) : sélectionner les lots péremptions
  *        les plus anciens, tout en respectant la marge sur date de péremption.
  */
  procedure getAutoChronoFromStock(
    aCharacterizationId1 in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharacterizationId2 in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharacterizationId3 in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharacterizationId4 in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharacterizationId5 in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aLocationId          in     STM_LOCATION.STM_LOCATION_ID%type
  , aThirdId             in     PAC_THIRD.PAC_THIRD_ID%type default null
  , aQuantity            in     number
  , aDateRef             in     date default sysdate
  , aCharValue1          in out varchar2
  , aCharValue2          in out varchar2
  , aCharValue3          in out varchar2
  , aCharValue4          in out varchar2
  , aCharValue5          in out varchar2
  , aBalanceQuantity     out    number
  )
  is
  begin
    GCO_LIB_CHARACTERIZATION.getAutoChronoFromStock(aCharacterizationId1
                                                  , aCharacterizationId2
                                                  , aCharacterizationId3
                                                  , aCharacterizationId4
                                                  , aCharacterizationId5
                                                  , aLocationId
                                                  , aThirdId
                                                  , aQuantity
                                                  , aDateRef
                                                  , aCharValue1
                                                  , aCharValue2
                                                  , aCharValue3
                                                  , aCharValue4
                                                  , aCharValue5
                                                  , aBalanceQuantity
                                                   );
  end getAutoChronoFromStock;

  /**
  * Description
  *    Retourne la prochaine valeur chronologique depuis le stock existant
  *    selon la règle :
  *      Type de chronologie = 2 (LIFO) : sélectionner les caractérisations les
  *        plus récentes disponibles dans l'emplacements du détail de position.
  *      Type de chronologie = 1 (FIFO) : sélectionner les caractérisations les
  *        plus anciennes disponibles dans l'emplacement du détail de position.
  *      Type de chornologie = 3 (Péremption) : sélectionner les lots péremptions
  *        les plus anciens, tout en respectant la marge sur date de péremption.
  */
  procedure getAutoCharFromStock(
    aGoodId          in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharId1         in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharId2         in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharId3         in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharId4         in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharId5         in     GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aLocationId      in     STM_LOCATION.STM_LOCATION_ID%type
  , aThirdId         in     PAC_THIRD.PAC_THIRD_ID%type default null
  , aQuantity        in     number
  , aDateRef         in     date default sysdate
  , aCharValue1      in out varchar2
  , aCharValue2      in out varchar2
  , aCharValue3      in out varchar2
  , aCharValue4      in out varchar2
  , aCharValue5      in out varchar2
  , aAutoChar        in     DOC_GAUGE_STRUCTURED.GAS_AUTO_CHARACTERIZATION%type
  , aBalanceQuantity out    number
  )
  is
  begin
    GCO_LIB_CHARACTERIZATION.getAutoCharFromStock(aGoodId
                                                , aCharId1
                                                , aCharId2
                                                , aCharId3
                                                , aCharId4
                                                , aCharId5
                                                , aLocationId
                                                , aThirdId
                                                , aQuantity
                                                , aDateRef
                                                , aCharValue1
                                                , aCharValue2
                                                , aCharValue3
                                                , aCharValue4
                                                , aCharValue5
                                                , aAutoChar
                                                , aBalanceQuantity
                                                 );
  end getAutoCharFromStock;

  /**
  * Description
  *       Retourne l'unité de mesure des données complémentaires et si pas
  *       trouvé, l'unité de mesure du bien (unité de gestion).
  */
  function GetCDAUnit(AGoodId in GCO_GOOD.GCO_GOOD_ID%type, AType in varchar2, AThirdId in number)
    return varchar2
  is
  begin
    return GCO_LIB_COMPL_DATA.GetCDAUnit(AGoodId, AType, AThirdId);
  end GetCDAUnit;

  /**
  * Description
  *       Recherche les données complémenaires en relation quantité de stockage
  */
  procedure GetCDAStock(
    AGoodId          in     GCO_GOOD.GCO_GOOD_ID%type
  , AType            in     varchar2
  , AThirdId         in     number
  , AConvertFactor   in out GCO_COMPL_DATA_PURCHASE.CDA_CONVERSION_FACTOR%type
  , ANumberOfDecimal in out GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type
  , AUnitOfMeasure   in out GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type
  )
  is
  begin
    GCO_LIB_COMPL_DATA.GetCDAStock(AGoodId, AType, AThirdId, AConvertFactor, ANumberOfDecimal, AUnitOfMeasure);
  end GetCDAStock;

  --Renvoie la description du bien en fonction de la langue passée en param
  function GetDescription(aGoodId in GCO_GOOD.GCO_GOOD_ID%type, aLang in varchar2, aTypofDescrp in number, aC_Description_Type in varchar2)
    return varchar2
  is
  begin
    return GCO_LIB_FUNCTIONS.GetDescription(aGoodId, aLang, aTypofDescrp, aC_Description_Type);
  end GetDescription;

  --Renvoie la description du bien en fonction de la langue passée en param
  function GetDescription2(aGoodId in GCO_GOOD.GCO_GOOD_ID%type, aLang in number, aTypofDescrp in number, aC_Description_Type in varchar2)
    return varchar2
  is
  begin
    return GCO_LIB_FUNCTIONS.GetDescription2(aGoodId, aLang, aTypofDescrp, aC_Description_Type);
  end GetDescription2;

  function GetCharacDescr(characterization_id GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type, lang_id PCS.PC_LANG.PC_LANG_ID%type)
    return char
  is
    result char(30);
  begin
    return GCO_LIB_CHARACTERIZATION.GetCharacDescr(characterization_id, lang_id);
  end GetCharacDescr;

  /**
  * Description
  *     retourne le type de la caractérisation
  */
  function GetCharacType(characterization_id GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type)
    return char
  is
  begin
    return GCO_LIB_CHARACTERIZATION.GetCharacType(characterization_id);
  end GetCharacType;

  /**
  * Description
  *      Recherche des id et description de caractérization avec gestion stock d'un bien
  */
  procedure GetListOfStkChar(
    aGoodId      in     number
  , aCharac1Id   out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharac2Id   out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharac3Id   out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharac4Id   out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharac5Id   out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aCharacType1 out    varchar2
  , aCharacType2 out    varchar2
  , aCharacType3 out    varchar2
  , aCharacType4 out    varchar2
  , aCharacType5 out    varchar2
  , aCharacDesc1 out    varchar2
  , aCharacDesc2 out    varchar2
  , aCharacDesc3 out    varchar2
  , aCharacDesc4 out    varchar2
  , aCharacDesc5 out    varchar2
  )
  is
  begin
    GCO_LIB_CHARACTERIZATION.GetListOfStkChar(aGoodId
                                            , aCharac1Id
                                            , aCharac2Id
                                            , aCharac3Id
                                            , aCharac4Id
                                            , aCharac5Id
                                            , aCharacType1
                                            , aCharacType2
                                            , aCharacType3
                                            , aCharacType4
                                            , aCharacType5
                                            , aCharacDesc1
                                            , aCharacDesc2
                                            , aCharacDesc3
                                            , aCharacDesc4
                                            , aCharacDesc5
                                             );
  end GetListOfStkChar;

  /**
  * Description
  *      Recherche dus stock et emplacement du bien passé en paramètre
  */
  procedure GetGoodStockLocation(
    pGoodId         GCO_GOOD.GCO_GOOD_ID%type
  , pStockId    out STM_STOCK.STM_STOCK_ID%type
  , pLocationId out STM_LOCATION.STM_LOCATION_ID%type
  )
  is
  begin
    GCO_LIB_FUNCTIONS.GetGoodStockLocation(pGoodId, pStockId, pLocationId);
  end GetGoodStockLocation;

  /**
  * Description
  *      Recherche des qtés alternatives du bien passé en paramètre
  */
  procedure GetGoodAltQty(
    pGoodId       GCO_GOOD.GCO_GOOD_ID%type
  , pAltQty1  out GCO_PRODUCT.PDT_ALTERNATIVE_QUANTITY_1%type
  , pAltQty2  out GCO_PRODUCT.PDT_ALTERNATIVE_QUANTITY_2%type
  , pAltQty3  out GCO_PRODUCT.PDT_ALTERNATIVE_QUANTITY_3%type
  , pAltFac1  out GCO_PRODUCT.PDT_CONVERSION_FACTOR_1%type
  , pAltFac2  out GCO_PRODUCT.PDT_CONVERSION_FACTOR_2%type
  , pAltFac3  out GCO_PRODUCT.PDT_CONVERSION_FACTOR_3%type
  , pAltDesc1 out DIC_UNIT_OF_MEASURE.DIC_UNIT_OF_MEASURE_WORDING%type
  , pAltDesc2 out DIC_UNIT_OF_MEASURE.DIC_UNIT_OF_MEASURE_WORDING%type
  , pAltDesc3 out DIC_UNIT_OF_MEASURE.DIC_UNIT_OF_MEASURE_WORDING%type
  )
  is
  begin
    GCO_LIB_FUNCTIONS.GetGoodAltQty(pGoodId, pAltQty1, pAltQty2, pAltQty3, pAltFac1, pAltFac2, pAltFac3, pAltDesc1, pAltDesc2, pAltDesc3);
  end GetGoodAltQty;

  /**
  * Description
  *   retourne la quantité passée en paramètre formatée
  *   selon le nombre de décimales du bien
  *   Prévu pour un formattage number(15,4)
  */
  function GetGoodQuantityWithDecimals(aGoodId in number, aQuantity in number)
    return varchar2
  is
  begin
    return GCO_LIB_FUNCTIONS.GetGoodQuantityWithDecimals(aGoodId, aQuantity);
  end GetGoodQuantityWithDecimals;

  /**
  * Description
  *   Recherche les informations des données complémentaires
  */
  procedure GetComplementaryData(
    aGoodID             in     number
  , aAdminDomain        in     varchar2
  , aThirdID            in     number
  , aLangID             in     number
  , aOperationID        in     number
  , aTransProprietor    in     number
  , aComplDataID        in     number
  , aStockId            out    number
  , aLocationId         out    number
  , aReference          out    varchar2
  , aSecondaryReference out    varchar2
  , aShortDescription   out    varchar2
  , aLongDescription    out    varchar2
  , aFreeDescription    out    varchar2
  , aEanCode            out    varchar2
  , aEanUCC14Code       out    varchar2
  , aHIBCPrimaryCode    out    varchar2
  , aDicUnitOfMeasure   out    varchar2
  , aConvertFactor      out    number
  , aNumberOfDecimal    out    number
  , aQuantity           out    number
  )
  is
  begin
    GCO_LIB_COMPL_DATA.GetComplementaryData(aGoodID
                                          , aAdminDomain
                                          , aThirdID
                                          , aLangID
                                          , aOperationID
                                          , aTransProprietor
                                          , aComplDataID
                                          , aStockId
                                          , aLocationId
                                          , aReference
                                          , aSecondaryReference
                                          , aShortDescription
                                          , aLongDescription
                                          , aFreeDescription
                                          , aEanCode
                                          , aEanUCC14Code
                                          , aHIBCPrimaryCode
                                          , aDicUnitOfMeasure
                                          , aConvertFactor
                                          , aNumberOfDecimal
                                          , aQuantity
                                           );
  end GetComplementaryData;

  /**
  * Description
  *   Recherche les informations sur les données compl. de Achat
  */
  procedure GetComplDataPurchase(
    aGoodID             in     number
  , aThirdID            in     number
  , aOperationID        in     number
  , aComplDataID        in     number
  , aStockId            out    number
  , aLocationId         out    number
  , aReference          out    varchar2
  , aSecondaryReference out    varchar2
  , aShortDescription   out    varchar2
  , aLongDescription    out    varchar2
  , aFreeDescription    out    varchar2
  , aEanCode            out    varchar2
  , aEanUCC14Code       out    varchar2
  , aHIBCPrimaryCode    out    varchar2
  , aDicUnitOfMeasure   out    varchar2
  , aConvertFactor      out    number
  , aNumberOfDecimal    out    number
  , aQuantity           out    number
  )
  is
  begin
    GCO_LIB_COMPL_DATA.GetComplDataPurchase(aGoodID
                                          , aThirdID
                                          , aOperationID
                                          , aComplDataID
                                          , aStockId
                                          , aLocationId
                                          , aReference
                                          , aSecondaryReference
                                          , aShortDescription
                                          , aLongDescription
                                          , aFreeDescription
                                          , aEanCode
                                          , aEanUCC14Code
                                          , aHIBCPrimaryCode
                                          , aDicUnitOfMeasure
                                          , aConvertFactor
                                          , aNumberOfDecimal
                                          , aQuantity
                                           );
  end GetComplDataPurchase;

  /**
  * Description
  *   Recherche les informations sur les données compl. de Vente
  */
  procedure GetComplDataSale(
    aGoodID             in     number
  , aThirdID            in     number
  , aComplDataID        in     number
  , aStockId            out    number
  , aLocationId         out    number
  , aReference          out    varchar2
  , aSecondaryReference out    varchar2
  , aShortDescription   out    varchar2
  , aLongDescription    out    varchar2
  , aFreeDescription    out    varchar2
  , aEanCode            out    varchar2
  , aEanUCC14Code       out    varchar2
  , aHIBCPrimaryCode    out    varchar2
  , aDicUnitOfMeasure   out    varchar2
  , aConvertFactor      out    number
  , aNumberOfDecimal    out    number
  , aQuantity           out    number
  )
  is
  begin
    GCO_LIB_COMPL_DATA.GetComplDataSale(aGoodID
                                      , aThirdID
                                      , aComplDataID
                                      , aStockId
                                      , aLocationId
                                      , aReference
                                      , aSecondaryReference
                                      , aShortDescription
                                      , aLongDescription
                                      , aFreeDescription
                                      , aEanCode
                                      , aEanUCC14Code
                                      , aHIBCPrimaryCode
                                      , aDicUnitOfMeasure
                                      , aConvertFactor
                                      , aNumberOfDecimal
                                      , aQuantity
                                       );
  end GetComplDataSale;

  /**
  * Description
  *   Recherche les informations sur les données compl. de la Sous-traitance
  */
  procedure GetComplDataSubcontract(
    aGoodID             in     number
  , aThirdID            in     number
  , aComplDataID        in     number
  , aStockId            out    number
  , aLocationId         out    number
  , aReference          out    varchar2
  , aSecondaryReference out    varchar2
  , aShortDescription   out    varchar2
  , aLongDescription    out    varchar2
  , aFreeDescription    out    varchar2
  , aEanCode            out    varchar2
  , aEanUCC14Code       out    varchar2
  , aDicUnitOfMeasure   out    varchar2
  , aConvertFactor      out    number
  , aNumberOfDecimal    out    number
  , aQuantity           out    number
  )
  is
  begin
    GCO_LIB_COMPL_DATA.GetComplDataSubcontract(aGoodID
                                             , aThirdID
                                             , aComplDataID
                                             , aStockId
                                             , aLocationId
                                             , aReference
                                             , aSecondaryReference
                                             , aShortDescription
                                             , aLongDescription
                                             , aFreeDescription
                                             , aEanCode
                                             , aEanUCC14Code
                                             , aDicUnitOfMeasure
                                             , aConvertFactor
                                             , aNumberOfDecimal
                                             , aQuantity
                                              );
  end GetComplDataSubContract;

  /**
  * Description
  *   Recherche les informations sur les données compl. de Stock
  */
  procedure GetComplDataStock(
    aGoodID             in     number
  , aTransProprietor    in     number
  , aComplDataID        in     number
  , aStockId            out    number
  , aLocationId         out    number
  , aReference          out    varchar2
  , aSecondaryReference out    varchar2
  , aShortDescription   out    varchar2
  , aLongDescription    out    varchar2
  , aFreeDescription    out    varchar2
  , aEanCode            out    varchar2
  , aEanUCC14Code       out    varchar2
  , aDicUnitOfMeasure   out    varchar2
  , aConvertFactor      out    number
  , aNumberOfDecimal    out    number
  , aQuantity           out    number
  )
  is
  begin
    GCO_LIB_COMPL_DATA.GetComplDataStock(aGoodID
                                       , aTransProprietor
                                       , aComplDataID
                                       , aStockId
                                       , aLocationId
                                       , aReference
                                       , aSecondaryReference
                                       , aShortDescription
                                       , aLongDescription
                                       , aFreeDescription
                                       , aEanCode
                                       , aEanUCC14Code
                                       , aDicUnitOfMeasure
                                       , aConvertFactor
                                       , aNumberOfDecimal
                                       , aQuantity
                                        );
  end GetComplDataStock;

  /**
  * Description
  *   Recherche les informations sur les données compl. de distribution
  */
  procedure GetOneComplDataDistrib(
    aGoodID              in     GCO_GOOD.GCO_GOOD_ID%type
  , aDistributionUnit    in     STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type
  , aDicDistribComplData in     GCO_COMPL_DATA_DISTRIB.DIC_DISTRIB_COMPL_DATA_ID%type
  , aResult              out    number
  , aDicUnitOfMeasure    out    GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type
  , aConvertFactor       out    GCO_COMPL_DATA_DISTRIB.CDA_CONVERSION_FACTOR%type
  , aNumberOfDecimal     out    GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type
  , aStockMin            out    GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MIN%type
  , aStockMax            out    GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MAX%type
  , aEconQuantity        out    GCO_COMPL_DATA_DISTRIB.CDI_ECONOMICAL_QUANTITY%type
  , aCDDBlockedFrom      out    GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_FROM%type
  , aCDDBlockedTo        out    GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_TO%type
  , aCoverPerCent        out    GCO_COMPL_DATA_DISTRIB.CDI_COVER_PERCENT%type
  , aUseCoverPercent     out    GCO_COMPL_DATA_DISTRIB.C_DRP_USE_COVER_PERCENT%type
  , aPriority            out    GCO_COMPL_DATA_DISTRIB.CDI_PRIORITY_CODE%type
  , aQuantityRule        out    GCO_COMPL_DATA_DISTRIB.C_DRP_QTY_RULE%type
  , aDocMode             out    GCO_COMPL_DATA_DISTRIB.C_DRP_DOC_MODE%type
  , aReliquat            out    GCO_COMPL_DATA_DISTRIB.C_DRP_RELIQUAT%type
  )
  is
  begin
    GCO_LIB_COMPL_DATA.GetOneComplDataDistrib(aGoodID
                                            , aDistributionUnit
                                            , aDicDistribComplData
                                            , aResult
                                            , aDicUnitOfMeasure
                                            , aConvertFactor
                                            , aNumberOfDecimal
                                            , aStockMin
                                            , aStockMax
                                            , aEconQuantity
                                            , aCDDBlockedFrom
                                            , aCDDBlockedTo
                                            , aCoverPerCent
                                            , aUseCoverPercent
                                            , aPriority
                                            , aQuantityRule
                                            , aDocMode
                                            , aReliquat
                                             );
  end GetOneComplDataDistrib;

  procedure GetComplDataDistrib(
    aGoodID              in     GCO_GOOD.GCO_GOOD_ID%type
  , aDistributionUnit    in     STM_DISTRIBUTION_UNIT.STM_DISTRIBUTION_UNIT_ID%type
  , aDicDistribComplData in     GCO_COMPL_DATA_DISTRIB.DIC_DISTRIB_COMPL_DATA_ID%type
  , aResult              out    number
  , aDicUnitOfMeasure    out    GCO_GOOD.DIC_UNIT_OF_MEASURE_ID%type
  , aConvertFactor       out    GCO_COMPL_DATA_DISTRIB.CDA_CONVERSION_FACTOR%type
  , aNumberOfDecimal     out    GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type
  , aStockMin            out    GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MIN%type
  , aStockMax            out    GCO_COMPL_DATA_DISTRIB.CDI_STOCK_MAX%type
  , aEconQuantity        out    GCO_COMPL_DATA_DISTRIB.CDI_ECONOMICAL_QUANTITY%type
  , aCDDBlockedFrom      out    GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_FROM%type
  , aCDDBlockedTo        out    GCO_COMPL_DATA_DISTRIB.CDI_BLOCKED_TO%type
  , aCoverPerCent        out    GCO_COMPL_DATA_DISTRIB.CDI_COVER_PERCENT%type
  , aUseCoverPercent     out    GCO_COMPL_DATA_DISTRIB.C_DRP_USE_COVER_PERCENT%type
  , aPriority            out    GCO_COMPL_DATA_DISTRIB.CDI_PRIORITY_CODE%type
  , aQuantityRule        out    GCO_COMPL_DATA_DISTRIB.C_DRP_QTY_RULE%type
  , aDocMode             out    GCO_COMPL_DATA_DISTRIB.C_DRP_DOC_MODE%type
  , aReliquat            out    GCO_COMPL_DATA_DISTRIB.C_DRP_RELIQUAT%type
  )
  is
  begin
    GCO_LIB_COMPL_DATA.GetComplDataDistrib(aGoodID
                                         , aDistributionUnit
                                         , aDicDistribComplData
                                         , aResult
                                         , aDicUnitOfMeasure
                                         , aConvertFactor
                                         , aNumberOfDecimal
                                         , aStockMin
                                         , aStockMax
                                         , aEconQuantity
                                         , aCDDBlockedFrom
                                         , aCDDBlockedTo
                                         , aCoverPerCent
                                         , aUseCoverPercent
                                         , aPriority
                                         , aQuantityRule
                                         , aDocMode
                                         , aReliquat
                                          );
  end GetComplDataDistrib;

  /**
  * Description
  *   retourne description d'une caractérisation
  *   dans la langue souhaitée
  */
  function GetCharacDescr4Prnt(aCharacterizationId gco_characterization.gco_characterization_id%type, aLanid pcs.pc_lang.lanid%type)
    return gco_desc_language.DLA_DESCRIPTION%type
  is
  begin
    return GCO_LIB_CHARACTERIZATION.GetCharacDescr4Prnt(aCharacterizationId, aLanid);
  end GetCharacDescr4Prnt;

  /**
  * Description
  *   rescherche du code assortiment en fonction du bien et du domain d'application
  */
  function GetTariffSet(aGoodID in GCO_GOOD.GCO_GOOD_ID%type, aAdminDomain DOC_GAUGE.C_ADMIN_DOMAIN%type)
    return varchar2
  is
  begin
    return GCO_LIB_PRICE.GetTariffSet(aGoodID, aAdminDomain);
  end GetTariffSet;

  /**
  * Description
  *   indique si la caractérisation d'un produit est modifiable
  *   utilisée par le trigger GCO_CHA_BIUD_INTEGRITY et par le réplicator
  */
  function IsCharactUpdatable(pOld_Gco_good_id in gco_good.gco_good_id%type, pNew_Gco_good_id in gco_good.gco_good_id%type, pMessageError out varchar2)
    return number
  is
  begin
    return GCO_LIB_CHARACTERIZATION.IsCharactUpdatable(pOld_Gco_good_id, pNew_Gco_good_id, pMessageError);
  end IsCharactUpdatable;

  function GetEquivalentPropComponent(aGCO_GOOD_ID in GCO_GOOD.GCO_GOOD_ID%type)
    return GCO_GOOD.GCO_GOOD_ID%type
  is
  begin
    return GCO_LIB_FUNCTIONS.GetEquivalentPropComponent(aGCO_GOOD_ID);
  end GetEquivalentPropComponent;

  /**
  * Description
  *   Recherche le cours matière précieuse unitaire d'un produit lié à un alliage. Si l'alliage associé contient 100%
  *   d'une matière de base, on considère que c'est une matière de base, par contre, si l'alliage associé contient
  *   plusieurs matières de base, on considère que c'est un alliage.
  */
  function GetGoodMetalRate(
    aGoodID      in GCO_GOOD.GCO_GOOD_ID%type default null
  , aThirdID     in PAC_THIRD.PAC_THIRD_ID%type default null
  , aDate        in date default null
  , aAdminDomain in DOC_GAUGE.C_ADMIN_DOMAIN%type default '3'
  )
    return number
  is
  begin
    return GCO_LIB_FUNCTIONS.GetGoodMetalRate(aGoodID, aThirdID, aDate, aAdminDomain);
  end GetGoodMetalRate;

  /**
  * procedure getCharIDandPos
  * Description
  *      Retourne l'id de caractérisation et la position selon le bien et le type de caractérisation
  */
  procedure getCharIDandPos(
    aGoodId in     GCO_GOOD.GCO_GOOD_ID%type
  , aType   in     GCO_CHARACTERIZATION.C_CHARACT_TYPE%type
  , aCharID out    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , aPos    out    number
  )
  is
  begin
    GCO_LIB_CHARACTERIZATION.getCharIDandPos(aGoodId, aType, aCharID, aPos);
  end getCharIDandPos;

  /**
  * Function GetConvertFactor
  * Description
  *        Retourne la valeur du facteur de conversion pour un domaine, pour un bien et un tiers donné
  */
  function GetConvertFactor(aGoodId in number, aThirdId in number, aAdminDomain in varchar2)
    return number
  is
  begin
    return GCO_LIB_COMPL_DATA.GetConvertFactor(aGoodId, aThirdId, aAdminDomain);
  end GetConvertFactor;

  /**
  * Function GetThirdConvertFactor
  * Description
  *        Retourne la valeur du facteur de conversion calculé pour un bien, un tiers initial et un document
  *        cible donné. La valeur nulle est retournée s'il n'y a pas de changement de partenaire ou que
  *        c'est une position kit ou assemblage.
  */
  function GetThirdConvertFactor(
    aGoodID           in number
  , aSourceThirdID    in number
  , aTypePos          in varchar2
  , aTargetDocumentID in number default null
  , aTargetThirdID    in number default null
  , aAdminDomain      in varchar2 default null
  )
    return number
  is
  begin
    return GCO_LIB_COMPL_DATA.GetThirdConvertFactor(aGoodID, aSourceThirdID, aTypePos, aTargetDocumentID, aTargetThirdID, aAdminDomain);
  end GetThirdConvertFactor;

  /**
   * Function IsProductInUse
   * Description
   *        Recherche si le produit est utilisé dans les domaines spécifiés.
   */
  function IsProductInUse(
    aGoodId                  in GCO_GOOD.GCO_GOOD_ID%type
  , aSearchInStocks          in integer default 1
  , aSearchInDocuments       in integer default 1
  , aSearchInBatches         in integer default 1
  , aSearchInBatchComponents in integer default 1
  , aSearchInBillOfMaterials in integer default 0
  )
    return integer
  is
  begin
    return GCO_LIB_FUNCTIONS.IsProductInUse(aGoodId, aSearchInStocks, aSearchInDocuments, aSearchInBatches, aSearchInBatchComponents, aSearchInBillOfMaterials);
  end IsProductInUse;
end GCO_FUNCTIONS;
