--------------------------------------------------------
--  DDL for Package Body FAL_NETWORK_DOC
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_NETWORK_DOC" 
is
  /**
  * function IsDOCNetworkEnabled
  * Description : Procédure indiquant si les réseaux sont actifs pour les documents
  *               logistiques
  *
  * @lastUpdate
  * @public
  * @return   booléen
  */
  function IsDOCNetWorkEnabled
    return boolean
  is
  begin
    return upper(PCS.PC_CONFIG.GetConfig('FAL_DOC_NETWORK') ) = 'TRUE';
  end;

  /**
  * function GetPositionGoodID
  * Description : Retourne le bien d'une position de document
  *
  * @lastUpdate
  * @private
  * @param    aPositionID : document
  * @return   ID de bien
  */
  function GetPositionGoodID(aPositionID in TTypeID)
    return TTypeID
  is
    aResult TTypeID;
  begin
    select GCO_GOOD_ID
      into aResult
      from DOC_POSITION
     where DOC_POSITION_ID = aPositionID;

    return aResult;
  end;

  /**
  * function GetPositionDocRecordID
  * Description : Retourne le Dossier d'une position de document
  *
  * @lastUpdate
  * @private
  * @param    aPositionID : document
  * @return   ID de dossier
  */
  function GetPositionDocRecordID(aPositionID in TTypeID)
    return TTypeID
  is
    aResult TTypeID;
  begin
    select DOC_RECORD_ID
      into aResult
      from DOC_POSITION
     where DOC_POSITION_ID = aPositionID;

    return aResult;
  end;

  /**
  * function GetStockIDFromLocation
  * Description : Retourne l'ID de stock d'un emplacement donné.
  *
  * @lastUpdate
  * @private
  * @param    aLocationID : emplacement de stock
  * @return   ID de stock
  */
  function GetStockIDFromLocation(aLocationID in TTypeID)
    return TTypeID
  is
    aResult TTypeID;
  begin
    select STM_STOCK_ID
      into aResult
      from STM_LOCATION
     where STM_LOCATION_ID = aLocationID;

    return aResult;
  exception
    when no_data_found then
      return null;
  end;

  /**
  * function GetPositionConversionFactor
  * Description : Retourne le facteur de convertion d'une position de document
  *
  * @lastUpdate
  * @private
  * @param    aPositionID : position de document
  * @return   Facteur de convertion
  */
  function GetPositionConversionFactor(aPositionID in TTypeID)
    return DOC_POSITION.POS_CONVERT_FACTOR%type
  is
    aResult DOC_POSITION.POS_CONVERT_FACTOR%type;
  begin
    select POS_CONVERT_FACTOR
      into aResult
      from DOC_POSITION
     where DOC_POSITION_ID = aPositionID;

    return aResult;
  end;

  /**
  * function PicIdisNullOfFAL_DOC_PROP
  * Description : Indique si le PIC est renseigné dans la proposition Logistique
  *
  * @lastUpdate
  * @private
  * @param    aFAL_DOC_PROP_ID : proposition d'appro logistique
  * @return   booléen
  */
  function PicIdisNullOfFAL_DOC_PROP(aFAL_DOC_PROP_ID FAL_DOC_PROP.FAL_DOC_PROP_ID%type)
    return boolean
  is
    aFAL_PIC_ID FAL_PIC.FAL_PIC_ID%type;
  begin
    select FAL_PIC_ID
      into aFAL_PIC_ID
      from FAL_DOC_PROP
     where FAL_DOC_PROP_ID = aFAL_DOC_PROP_ID;

    return nvl(aFAL_PIC_ID, 0) <= 0;
  end;

  /**
  * function PicIdisNullOfFAL_LOT_PROP
  * Description : Indique si le PIC est renseigné dans la proposition fab
  *
  * @lastUpdate
  * @private
  * @param    aFAL_LOT_PROP_ID : proposition d'appro logistique
  * @return   booléen
  */
  function PicIdisNullOfFAL_LOT_PROP(aFAL_LOT_PROP_ID FAL_LOT_PROP.FAL_LOT_PROP_ID%type)
    return boolean
  is
    aFAL_PIC_ID FAL_PIC.FAL_PIC_ID%type;
  begin
    select FAL_PIC_ID
      into aFAL_PIC_ID
      from FAL_LOT_PROP
     where FAL_LOT_PROP_ID = aFAL_LOT_PROP_ID;

    return nvl(aFAL_PIC_ID, 0) <= 0;
  end;

  /**
  * procedure GetNetworkInfoFromDocument
  * Description : Déterminations des informations à pousser dans les réseaux
  *               depuis les détails positions et documents
  * @lastUpdate
  * @private
  * @param   aDocumentID          : Document
  * @param   aDocPositionId       : Position
  * @return  aDmtNumber           : Num document
  * @return  aGaugeTitle          : Type de gabarit
  * @return  aGaugeID             : ID gabarit
  * @return  aGoodID              : Bien
  * @return  aDocRecordID         : Dossier
  * @return  aConvertionFactor    : Facteur de conversion
  * @return  aStmStockId          : Stock
  * @return  aStmLocationId       : Emplacement
  * @return  aPacRepresentativeId : Représentant
  */
  procedure GetNetworkInfoFromDocument(
    aDocumentID          in     number
  , aDocPositionId       in     number
  , aDmtNumber           in out varchar2
  , aGaugeTitle          in out varchar2
  , aGaugeID             in out number
  , aThirdID             in out number
  , aGoodID              in out number
  , aDocRecordID         in out number
  , aConversionFactor    in out number
  , aStmStockId          in out number
  , aStmLocationId       in out number
  , aPacRepresentativeId in out number
  )
  is
  begin
    if aDocumentID is null then
      select DOC.DMT_NUMBER
           , GAS.C_GAUGE_TITLE
           , DOC.DOC_GAUGE_ID
           , DOC.PAC_THIRD_ID
           , POS.PAC_REPRESENTATIVE_ID
        into aDmtNumber
           , aGaugeTitle
           , aGaugeID
           , aThirdID
           , aPacRepresentativeId
        from DOC_POSITION POS
           , DOC_DOCUMENT DOC
           , DOC_GAUGE_STRUCTURED GAS
       where POS.DOC_POSITION_ID = aDocPositionId
         and POS.DOC_DOCUMENT_ID = DOC.DOC_DOCUMENT_ID
         and DOC.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID(+);
    else
      select DOC.DMT_NUMBER
           , GAS.C_GAUGE_TITLE
           , DOC.DOC_GAUGE_ID
           , DOC.PAC_THIRD_ID
        into aDmtNumber
           , aGaugeTitle
           , aGaugeID
           , aThirdID
        from DOC_DOCUMENT DOC
           , DOC_GAUGE_STRUCTURED GAS
       where DOC.DOC_DOCUMENT_ID = aDocumentID
         and DOC.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID(+);
    end if;

    if aGoodID is null then
      aGoodID  := GetPositionGoodID(aDocPositionId);
    end if;

    if aDocRecordID is null then
      aDocRecordID  := GetPositionDocRecordID(aDocPositionId);
    elsif aDocRecordID = 0 then
      aDocRecordID  := null;
    end if;

    if aConversionFactor is null then
      aConversionFactor  := GetPositionConversionFactor(aDocPositionId);
    end if;

    if aStmLocationId is null then
      aStmStockID  := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_NETWORK');

      if aStmStockID is not null then
        aStmLocationID  := FAL_TOOLS.GetConfig_LocationID('PPS_DefltLOCATION_NETWORK', aStmStockID);
      end if;
    else
      aStmStockID  := GetStockIDFromLocation(aStmLocationID);
    end if;
  end;

  /**
  * function GetNetworkCharactFromDetail
  * Description : Déterminations des caractérisations des détails position que l'on
  *               doit stocker dans les réseaux
  * @lastUpdate
  * @private
  * @param    aPositionDetail : Détail position
  * @param    aGoodId : bien
  * @return   aCharID1 .. aCharID5 : ID caractérisation 1 à 5
  * @return   aCharValue1 .. aCharValue5 : Valeurs caractérisation 1 à 5
  */
  procedure GetNetworkCharactFromDetail(
    aPositionDetail in     DOC_POSITION_DETAIL%rowtype
  , aCharID1        in out number
  , aCharID2        in out number
  , aCharID3        in out number
  , aCharID4        in out number
  , aCharID5        in out number
  , aCharValue1     in out varchar2
  , aCharValue2     in out varchar2
  , aCharValue3     in out varchar2
  , aCharValue4     in out varchar2
  , aCharValue5     in out varchar2
  , aGoodId         in     number default null
  )
  is
    LocGoodId number;
  begin
    -- Détermination produit
    if nvl(aGoodId, 0) <> 0 then
      LocGoodId  := aGoodId;
    else
      LocGoodId  := GetPositionGoodID(aPositionDetail.DOC_POSITION_ID);
    end if;

    -- Déterminer les caractérisations utiles du produit
    FAL_NETWORK.DefineUtilCharacterizations(LocGoodId, aCharID1, aCharID2, aCharID3, aCharID4, aCharID5);
    -- Déterminer les caractérisations stockées dans les réseaux
    aCharValue1  := null;
    aCharValue2  := null;
    aCharValue3  := null;
    aCharValue4  := null;
    aCharValue5  := null;

    if aCharID1 is not null then
      if aPositionDetail.GCO_CHARACTERIZATION_ID = aCharID1 then
        aCharValue1  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_1;
      elsif aPositionDetail.GCO_GCO_CHARACTERIZATION_ID = aCharID1 then
        aCharValue1  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_2;
      elsif aPositionDetail.GCO2_GCO_CHARACTERIZATION_ID = aCharID1 then
        aCharValue1  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_3;
      elsif aPositionDetail.GCO3_GCO_CHARACTERIZATION_ID = aCharID1 then
        aCharValue1  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_4;
      elsif aPositionDetail.GCO4_GCO_CHARACTERIZATION_ID = aCharID1 then
        aCharValue1  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_5;
      end if;
    end if;

    if aCharID2 is not null then
      if aPositionDetail.GCO_CHARACTERIZATION_ID = aCharID2 then
        aCharValue2  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_1;
      elsif aPositionDetail.GCO_GCO_CHARACTERIZATION_ID = aCharID2 then
        aCharValue2  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_2;
      elsif aPositionDetail.GCO2_GCO_CHARACTERIZATION_ID = aCharID2 then
        aCharValue2  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_3;
      elsif aPositionDetail.GCO3_GCO_CHARACTERIZATION_ID = aCharID2 then
        aCharValue2  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_4;
      elsif aPositionDetail.GCO4_GCO_CHARACTERIZATION_ID = aCharID2 then
        aCharValue2  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_5;
      end if;
    end if;

    if aCharID3 is not null then
      if aPositionDetail.GCO_CHARACTERIZATION_ID = aCharID3 then
        aCharValue3  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_1;
      elsif aPositionDetail.GCO_GCO_CHARACTERIZATION_ID = aCharID3 then
        aCharValue3  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_2;
      elsif aPositionDetail.GCO2_GCO_CHARACTERIZATION_ID = aCharID3 then
        aCharValue3  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_3;
      elsif aPositionDetail.GCO3_GCO_CHARACTERIZATION_ID = aCharID3 then
        aCharValue3  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_4;
      elsif aPositionDetail.GCO4_GCO_CHARACTERIZATION_ID = aCharID3 then
        aCharValue3  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_5;
      end if;
    end if;

    if aCharID4 is not null then
      if aPositionDetail.GCO_CHARACTERIZATION_ID = aCharID4 then
        aCharValue4  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_1;
      elsif aPositionDetail.GCO_GCO_CHARACTERIZATION_ID = aCharID4 then
        aCharValue4  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_2;
      elsif aPositionDetail.GCO2_GCO_CHARACTERIZATION_ID = aCharID4 then
        aCharValue4  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_3;
      elsif aPositionDetail.GCO3_GCO_CHARACTERIZATION_ID = aCharID4 then
        aCharValue4  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_4;
      elsif aPositionDetail.GCO4_GCO_CHARACTERIZATION_ID = aCharID4 then
        aCharValue4  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_5;
      end if;
    end if;

    if aCharID5 is not null then
      if aPositionDetail.GCO_CHARACTERIZATION_ID = aCharID5 then
        aCharValue5  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_1;
      elsif aPositionDetail.GCO_GCO_CHARACTERIZATION_ID = aCharID5 then
        aCharValue5  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_2;
      elsif aPositionDetail.GCO2_GCO_CHARACTERIZATION_ID = aCharID5 then
        aCharValue5  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_3;
      elsif aPositionDetail.GCO3_GCO_CHARACTERIZATION_ID = aCharID5 then
        aCharValue5  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_4;
      elsif aPositionDetail.GCO4_GCO_CHARACTERIZATION_ID = aCharID5 then
        aCharValue5  := aPositionDetail.PDE_CHARACTERIZATION_VALUE_5;
      end if;
    end if;
  end;

  /**
  * function GetNetworkCharactFromPOA
  * Description : Déterminations des caractérisations des propositions d'appro
  *               logistique que l'ondoit stocker dans les réseaux
  * @lastUpdate
  * @private
  * @param    aFAL_DOC_PROP : proposition d'appro logistique
  * @return   aCharID1 .. aCharID5 : ID caractérisation 1 à 5
  * @return   aCharValue1 .. aCharValue5 : Valeurs caractérisation 1 à 5
  */
  procedure GetNetworkCharactFromPOA(
    aFAL_DOC_PROP        FAL_DOC_PROP%rowtype
  , aCharID1      in out number
  , aCharID2      in out number
  , aCharID3      in out number
  , aCharID4      in out number
  , aCharID5      in out number
  , aCharValue1   in out varchar2
  , aCharValue2   in out varchar2
  , aCharValue3   in out varchar2
  , aCharValue4   in out varchar2
  , aCharValue5   in out varchar2
  )
  is
  begin
    -- Déterminer les caractérisations utiles du produit
    FAL_NETWORK.DefineUtilCharacterizations(aFAL_DOC_PROP.GCO_GOOD_ID, aCharID1, aCharID2, aCharID3, aCharID4, aCharID5);
    -- Déterminer les caractérisations stockées dans les réseaux
    aCharValue1  := null;
    aCharValue2  := null;
    aCharValue3  := null;
    aCharValue4  := null;
    aCharValue5  := null;

    if aCharID1 is not null then
      if aFAL_DOC_PROP.GCO_CHARACTERIZATION1_ID = aCharID1 then
        aCharValue1  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1;
      elsif aFAL_DOC_PROP.GCO_CHARACTERIZATION2_ID = aCharID1 then
        aCharValue1  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_2;
      elsif aFAL_DOC_PROP.GCO_CHARACTERIZATION3_ID = aCharID1 then
        aCharValue1  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_3;
      elsif aFAL_DOC_PROP.GCO_CHARACTERIZATION4_ID = aCharID1 then
        aCharValue1  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_4;
      elsif aFAL_DOC_PROP.GCO_CHARACTERIZATION5_ID = aCharID1 then
        aCharValue1  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_5;
      end if;
    end if;

    if aCharID2 is not null then
      if aFAL_DOC_PROP.GCO_CHARACTERIZATION1_ID = aCharID2 then
        aCharValue2  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1;
      elsif aFAL_DOC_PROP.GCO_CHARACTERIZATION2_ID = aCharID2 then
        aCharValue2  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_2;
      elsif aFAL_DOC_PROP.GCO_CHARACTERIZATION3_ID = aCharID2 then
        aCharValue2  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_3;
      elsif aFAL_DOC_PROP.GCO_CHARACTERIZATION4_ID = aCharID2 then
        aCharValue2  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_4;
      elsif aFAL_DOC_PROP.GCO_CHARACTERIZATION5_ID = aCharID2 then
        aCharValue2  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_5;
      end if;
    end if;

    if aCharID3 is not null then
      if aFAL_DOC_PROP.GCO_CHARACTERIZATION1_ID = aCharID3 then
        aCharValue3  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1;
      elsif aFAL_DOC_PROP.GCO_CHARACTERIZATION2_ID = aCharID3 then
        aCharValue3  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_2;
      elsif aFAL_DOC_PROP.GCO_CHARACTERIZATION3_ID = aCharID3 then
        aCharValue3  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_3;
      elsif aFAL_DOC_PROP.GCO_CHARACTERIZATION4_ID = aCharID3 then
        aCharValue3  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_4;
      elsif aFAL_DOC_PROP.GCO_CHARACTERIZATION5_ID = aCharID3 then
        aCharValue3  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_5;
      end if;
    end if;

    if aCharID4 is not null then
      if aFAL_DOC_PROP.GCO_CHARACTERIZATION1_ID = aCharID4 then
        aCharValue4  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1;
      elsif aFAL_DOC_PROP.GCO_CHARACTERIZATION2_ID = aCharID4 then
        aCharValue4  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_2;
      elsif aFAL_DOC_PROP.GCO_CHARACTERIZATION3_ID = aCharID4 then
        aCharValue4  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_3;
      elsif aFAL_DOC_PROP.GCO_CHARACTERIZATION4_ID = aCharID4 then
        aCharValue4  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_4;
      elsif aFAL_DOC_PROP.GCO_CHARACTERIZATION5_ID = aCharID4 then
        aCharValue4  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_5;
      end if;
    end if;

    if aCharID5 is not null then
      if aFAL_DOC_PROP.GCO_CHARACTERIZATION1_ID = aCharID5 then
        aCharValue5  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1;
      elsif aFAL_DOC_PROP.GCO_CHARACTERIZATION2_ID = aCharID5 then
        aCharValue5  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_2;
      elsif aFAL_DOC_PROP.GCO_CHARACTERIZATION3_ID = aCharID5 then
        aCharValue5  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_3;
      elsif aFAL_DOC_PROP.GCO_CHARACTERIZATION4_ID = aCharID5 then
        aCharValue5  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_4;
      elsif aFAL_DOC_PROP.GCO_CHARACTERIZATION5_ID = aCharID5 then
        aCharValue5  := aFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_5;
      end if;
    end if;
  end;

  /**
  * procedure ReseauApproDOC_Creation
  * Description : Création des réseaux pour une appro de type logistique
  *
  * @lastUpdate
  * @public
  * @param   aPositionDetail   : Détail position de document
  * @param   pDocumentID       : Document
  * @param   pGoodID           : Bien du détail position
  * @param   pDocRecordID      : Dossier
  * @param   pConversionFactor : Facteur de conversion
  * Note :
  *   Si pDocumentID NOT NULL, on utilise les fonctions Get...FromDoc(), sinon on utilise les fonctions Get..()
  *   Si pGoodID, pDocRecordID et pConversionFactor NOT NULL, on utilise ces valeurs plutôt qu'aller les rechercher
  *   sur la table DOC_POSITION
  *   Ces précautions ont pour but de contourner l'exception Table (DOC_POSITION) is mutating lors de l'appel de
  *   ReseauApproDOC_Creation() par le trigger AfterUpdate sur DOC_POSITION (aucune requete ne peut porter sur cette table).
  */
  procedure ReseauApproDOC_Creation(
    aPositionDetail   in DOC_POSITION_DETAIL%rowtype
  , pDocumentID       in TTypeID
  , pGoodID           in TTypeID
  , pDocRecordID      in TTypeID
  , pConversionFactor in DOC_POSITION.POS_CONVERT_FACTOR%type
  , iDescription      in varchar2 default null
  )
  is
    aGaugeTitle          DOC_GAUGE_STRUCTURED.C_GAUGE_TITLE%type;
    aGaugeID             TTypeID;
    aThirdID             TTypeID;
    aGoodID              TTypeID;
    aDocRecordID         TTypeID;
    aStockID             TTypeID;
    aLocationID          TTypeID;
    aConversionFactor    DOC_POSITION.POS_CONVERT_FACTOR%type;
    aDocNumber           DOC_DOCUMENT.DMT_NUMBER%type;
    aPacRepresentativeID number;
    aCharValue1          FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type;
    aCharValue2          FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type;
    aCharValue3          FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type;
    aCharValue4          FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type;
    aCharValue5          FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type;
    aUseCharID1          number;
    aUseCharID2          number;
    aUseCharID3          number;
    aUseCharID4          number;
    aUseCharID5          number;
    lnNumberOfDecimal    GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
    lnBalanceQtySU       DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY_SU%type;
  begin
    -- Initialisation des variables
    glbNewApproID         := null;
    aGoodID               := pGoodID;
    aDocRecordID          := pDocRecordID;
    aConversionFactor     := pConversionFactor;
    aLocationID           := aPositionDetail.STM_LOCATION_ID;
    aStockID              := null;
    aPacRepresentativeID  := null;
    -- Récupération des informations du doc, ou de sa position
    GetNetworkInfoFromDocument(pDocumentID
                             , aPositionDetail.DOC_POSITION_ID
                             , aDocNumber
                             , aGaugeTitle
                             , aGaugeID
                             , aThirdID
                             , aGoodID
                             , aDocRecordID
                             , aConversionFactor
                             , aStockId
                             , aLocationId
                             , aPacRepresentativeID
                              );
    -- Déterminer la quantité solde en unité de stockage
    -- Recherche également le nombre de décimal sur le bien pour arrondir supérieure la quantité solde en unité de stockage
    lnNumberOfDecimal     := GCO_I_LIB_FUNCTIONS.GetNumberOfDecimal(aPositionDetail.GCO_GOOD_ID);
    lnBalanceQtySU        := ACS_FUNCTION.RoundNear(aPositionDetail.PDE_BALANCE_QUANTITY * aConversionFactor, 1 / power(10, lnNumberOfDecimal), 1);
    -- Déterminer les caractérisations utilisées dans les réseaux
    GetNetworkCharactFromDetail(aPositionDetail
                              , aUseCharID1
                              , aUseCharID2
                              , aUseCharID3
                              , aUseCharID4
                              , aUseCharID5
                              , aCharValue1
                              , aCharValue2
                              , aCharValue3
                              , aCharValue4
                              , aCharValue5
                              , aGoodId
                               );
    -- Initialisation de la variable ID de l'appro créée
    glbNewApproID         := GetNewId;

    -- Insertion dans FAL_NETWORK_SUPPLY
    insert into FAL_NETWORK_SUPPLY
                (FAL_NETWORK_SUPPLY_ID
               , A_DATECRE
               , A_IDCRE
               , DOC_POSITION_ID   -- Position
               , DOC_POSITION_DETAIL_ID   -- Détail Position
               , DOC_GAUGE_ID   -- Gabarit
               , C_GAUGE_TITLE   -- Intitule Gabarit
               , PAC_THIRD_ID   -- Tiers
               , GCO_GOOD_ID   -- Produit
               , FAN_DESCRIPTION   -- Description
               , DOC_RECORD_ID   -- Dossier
               , STM_STOCK_ID   -- Stock
               , STM_LOCATION_ID   -- Emplacement de stock
               , FAN_BEG_PLAN   -- Debut Planif
               , FAN_END_PLAN   -- Fin Planif
               , FAN_PLAN_PERIOD   -- Duree plannifiee
               , FAN_BEG_PLAN1   -- Debut Planif 1
               , FAN_END_PLAN1   -- Fin Planif 1
               , FAN_PREV_QTY   -- Qte prevue
               , FAN_SCRAP_QTY   -- Qte Rebut prévue
               , FAN_FULL_QTY   -- Qte Totale
               , FAN_DISCHARGE_QTY   -- Qte Dechargée
               , FAN_REALIZE_QTY   -- Qte Realisee
               , FAN_SCRAP_REAL_QTY   -- Qte Rebut Realise
               , FAN_RETURN_QTY   -- Qte Retour
               , FAN_EXCEED_QTY   -- Qte Supplémentaire
               , FAN_BALANCE_QTY   -- Qte Solde
               , FAN_FREE_QTY   -- Qte Libre
               , FAN_STK_QTY   -- Qte Att Stock
               , FAN_NETW_QTY   -- Qte Att Besoin Appro
               , GCO_CHARACTERIZATION1_ID   -- Caracterisations 1
               , GCO_CHARACTERIZATION2_ID   -- Caracterisations 2
               , GCO_CHARACTERIZATION3_ID   -- Caracterisations 3
               , GCO_CHARACTERIZATION4_ID   -- Caracterisations 4
               , GCO_CHARACTERIZATION5_ID   -- Caracterisations 5
               , FAN_CHAR_VALUE1   -- Valeurs de caractérisations 1
               , FAN_CHAR_VALUE2   -- Valeurs de caractérisations 2
               , FAN_CHAR_VALUE3   -- Valeurs de caractérisations 3
               , FAN_CHAR_VALUE4   -- Valeurs de caractérisations 4
               , FAN_CHAR_VALUE5   -- Valeurs de caractérisations 5
                )
         values (glbNewApproID
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , aPositionDetail.DOC_POSITION_ID   -- Position
               , aPositionDetail.DOC_POSITION_DETAIL_ID   -- Détail Position
               , aGaugeID   -- Gabarit
               , aGaugeTitle   -- Intitule Gabarit
               , aThirdID   -- Tiers
               , aGoodID   -- Produit
               , nvl(iDescription, aDocNumber)   -- Description
               , aDocRecordID   -- Dossier
               , aStockID   -- Stock
               , aLocationID   -- Emplacement de stock
               , aPositionDetail.PDE_BASIS_DELAY   -- Debut Planif
               , aPositionDetail.PDE_FINAL_DELAY   -- Fin Planif
               , aPositionDetail.PDE_FINAL_DELAY - aPositionDetail.PDE_BASIS_DELAY   -- Duree plannifiee
               , aPositionDetail.PDE_BASIS_DELAY   -- Debut Planif 1
               , aPositionDetail.PDE_FINAL_DELAY   -- Fin Planif 1
               , aPositionDetail.PDE_BASIS_QUANTITY_SU   -- Qte prevue
               , aPositionDetail.PDE_INTERMEDIATE_QUANTITY_SU   -- Qte Rebut prévue
               , aPositionDetail.PDE_FINAL_QUANTITY_SU   -- Qte Totale
               , 0   -- Qte Dechargée
               , 0   -- Qte Realisee
               , 0   -- Qte Rebut Realise
               , 0   -- Qte Retour
               , 0   -- Qte Supplémentaire
               , lnBalanceQtySU   -- Qte Solde
               , lnBalanceQtySU   -- Qte Libre
               , 0   -- Qte Att Stock
               , 0   -- Qte Att Besoin Appro
               , aUseCharID1   -- Caracterisations
               , aUseCharID2
               , aUseCharID3
               , aUseCharID4
               , aUseCharID5
               , aCharValue1   -- Valeurs de caractérisations
               , aCharValue2
               , aCharValue3
               , aCharValue4
               , aCharValue5
                );
  end;

  /**
  * procedure ReseauApproDOC_MAJ_Dossier
  * Description : Mise àjour du dossier sur l'appro réseau correspondant à une
  *               position de document.
  * @lastUpdate
  * @public
  * @param   aPositionID  : Position de document
  * @param   aDocRecordID : Dossier pour mise à jour
  */
  procedure ReseauApproDOC_MAJ_Dossier(aPositionID in TTypeID, aDocRecordID in TTypeID)
  is
  begin
    update FAL_NETWORK_SUPPLY
       set DOC_RECORD_ID = aDocRecordID
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_POSITION_ID = aPositionID;
  end;

  /**
  * procedure ReseauBesoinDOC_MAJ_Repres
  * Description : Mise à jour du représentant sur le beoin réseau correspondant à une
  *               position de document.
  * @lastUpdate
  * @public
  * @param   aPositionID  : Position de document
  * @param   aPAC_REPRESENTATIVE_ID : représentant
  */
  procedure ReseauBesoinDOC_MAJ_Repres(aPositionID in TTypeID, aPAC_REPRESENTATIVE_ID in TTypeID)
  is
  begin
    update FAL_NETWORK_NEED
       set PAC_REPRESENTATIVE_ID = aPAC_REPRESENTATIVE_ID
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_POSITION_ID = aPositionID;
  end;

  /**
  * procedure ReseauBesoinDOC_MAJ_Dossier
  * Description : Mise à jour du dossier sur le beoin réseau correspondant à une
  *               position de document.
  * @lastUpdate
  * @public
  * @param   aPositionID  : Position de document
  * @param   aDocRecordID : Dossier pour mise à jour
  */
  procedure ReseauBesoinDOC_MAJ_Dossier(aPositionID in TTypeID, aDocRecordID in TTypeID)
  is
  begin
    update FAL_NETWORK_NEED
       set DOC_RECORD_ID = aDocRecordID
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where DOC_POSITION_ID = aPositionID;
  end;

  /**
  * procedure ReseauBesoinDOC_Creation
  * Description : Création des réseaux pour un besoin de type logistique
  *
  * @lastUpdate
  * @public
  * @param   aPositionDetail   : Détail position de document
  * @param   pDocumentID       : Document
  * @param   pGoodID           : Bien du détail position
  * @param   pDocRecordID      : Dossier
  * @param   pConversionFactor : Facteur de conversion
  * @param   pPAC_REPRESENTATIVE_ID : Représentant
  *
  * Note :
  *    Si pDocumentID NOT NULL, on utilise les fonctions Get...FromDoc(), sinon on utilise les fonctions Get..()
  *    Si pGoodID, pDocRecordID et pConversionFactor NOT NULL, on utilise ces valeurs plutôt qu'aller les rechercher
  *    sur la table DOC_POSITION
  *    Ces précautions ont pour but de contourner l'exception Table (DOC_POSITION) is mutating lors de l'appel de
  *    ReseauApproDOC_Creation() par le trigger AfterUpdate sur DOC_POSITION (aucune requete ne peut porter sur cette table).
  */
  procedure ReseauBesoinDOC_Creation(
    aPositionDetail        in DOC_POSITION_DETAIL%rowtype
  , pDocumentID            in TTypeID
  , pGoodID                in TTypeID
  , pDocRecordID           in TTypeID
  , pConversionFactor      in DOC_POSITION.POS_CONVERT_FACTOR%type
  , pPAC_REPRESENTATIVE_ID in TTypeID
  , iDescription           in varchar2 default null
  )
  is
    aGaugeTitle            DOC_GAUGE_STRUCTURED.C_GAUGE_TITLE%type;
    aGaugeID               TTypeID;
    aThirdID               TTypeID;
    aGoodID                TTypeID;
    aDocRecordID           TTypeID;
    aStockID               TTypeID;
    aLocationID            TTypeID;
    aConversionFactor      DOC_POSITION.POS_CONVERT_FACTOR%type;
    aDocNumber             DOC_DOCUMENT.DMT_NUMBER%type;
    aCharValue1            FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type;
    aCharValue2            FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type;
    aCharValue3            FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type;
    aCharValue4            FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type;
    aCharValue5            FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type;
    aUseCharID1            number;
    aUseCharID2            number;
    aUseCharID3            number;
    aUseCharID4            number;
    aUseCharID5            number;
    aPAC_REPRESENTATIVE_ID TTypeID;
    lnNumberOfDecimal      GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
    lnBalanceQtySU         DOC_POSITION_DETAIL.PDE_FINAL_QUANTITY_SU%type;
  begin
    -- Initialisation de la variable ID du besoin
    glbNewBesoinID          := null;
    aGoodID                 := pGoodID;
    aDocRecordID            := pDocRecordID;
    aConversionFactor       := pConversionFactor;
    aLocationID             := aPositionDetail.STM_LOCATION_ID;
    aStockId                := null;
    aPAC_REPRESENTATIVE_ID  := pPAC_REPRESENTATIVE_ID;
    -- Récupération des informations du doc, ou de sa position
    GetNetworkInfoFromDocument(pDocumentID
                             , aPositionDetail.DOC_POSITION_ID
                             , aDocNumber
                             , aGaugeTitle
                             , aGaugeID
                             , aThirdID
                             , aGoodID
                             , aDocRecordID
                             , aConversionFactor
                             , aStockId
                             , aLocationId
                             , aPAC_REPRESENTATIVE_ID
                              );
    -- Déterminer la quantité solde en unité de stockage
    -- Recherche également le nombre de décimal sur le bien pour arrondir supérieure la quantité solde en unité de stockage
    lnNumberOfDecimal       := GCO_I_LIB_FUNCTIONS.GetNumberOfDecimal(aPositionDetail.GCO_GOOD_ID);
    lnBalanceQtySU          := ACS_FUNCTION.RoundNear(aPositionDetail.PDE_BALANCE_QUANTITY * aConversionFactor, 1 / power(10, lnNumberOfDecimal), 1);
    -- Déterminer les caractérisations utilisées dans les réseaux
    GetNetworkCharactFromDetail(aPositionDetail
                              , aUseCharID1
                              , aUseCharID2
                              , aUseCharID3
                              , aUseCharID4
                              , aUseCharID5
                              , aCharValue1
                              , aCharValue2
                              , aCharValue3
                              , aCharValue4
                              , aCharValue5
                              , aGoodId
                               );
    -- Initialisation de la variable ID du besoin créé
    glbNewBesoinID          := GetNewId;

    -- Insertion dans FAL_NETWORK_NEED
    insert into FAL_NETWORK_NEED
                (FAL_NETWORK_NEED_ID   -- ID principal
               , A_DATECRE   -- Date de création
               , A_IDCRE   -- User Création
               , DOC_POSITION_ID   -- Position
               , DOC_POSITION_DETAIL_ID   -- Détail Position
               , DOC_GAUGE_ID   -- Gabarit
               , C_GAUGE_TITLE   -- Intitule Gabarit
               , PAC_THIRD_ID   -- Tiers
               , GCO_GOOD_ID   -- Produit
               , FAN_DESCRIPTION   -- Description
               , DOC_RECORD_ID   -- Dossier
               , STM_STOCK_ID   -- Stock
               , STM_LOCATION_ID   -- Emplacement de stock
               , FAN_BEG_PLAN   -- Debut Planif
               , FAN_END_PLAN   -- Fin Planif
               , FAN_PLAN_PERIOD   -- Duree plannifiee
               , FAN_BEG_PLAN1   -- Debut Planif 1
               , FAN_END_PLAN1   -- Fin Planif 1
               , FAN_PREV_QTY   -- Qte prevue
               , FAN_SCRAP_QTY   -- Qte Rebut prévue
               , FAN_FULL_QTY   -- Qte Totale
               , FAN_DISCHARGE_QTY   -- Qte Dechargée
               , FAN_REALIZE_QTY   -- Qte Realisee
               , FAN_SCRAP_REAL_QTY   -- Qte Rebut Realise
               , FAN_RETURN_QTY   -- Qte Retour
               , FAN_EXCEED_QTY   -- Qte Supplémentaire
               , FAN_BALANCE_QTY   -- Qte Solde
               , FAN_FREE_QTY   -- Qte Libre
               , FAN_STK_QTY   -- Qte Att Stock
               , FAN_NETW_QTY   -- Qte Att Besoin Appro
               , GCO_CHARACTERIZATION1_ID   -- Caracterisations
               , GCO_CHARACTERIZATION2_ID
               , GCO_CHARACTERIZATION3_ID
               , GCO_CHARACTERIZATION4_ID
               , GCO_CHARACTERIZATION5_ID
               , FAN_CHAR_VALUE1   -- Valeurs de caractérisations
               , FAN_CHAR_VALUE2
               , FAN_CHAR_VALUE3
               , FAN_CHAR_VALUE4
               , FAN_CHAR_VALUE5
               , PAC_REPRESENTATIVE_ID
                )
         values (glbNewBesoinID   -- ID principal
               , sysdate   -- Date de création
               , PCS.PC_I_LIB_SESSION.GetUserIni   -- User Création
               , aPositionDetail.DOC_POSITION_ID   -- Position
               , aPositionDetail.DOC_POSITION_DETAIL_ID   -- Détail Position
               , aGaugeID   -- Gabarit
               , aGaugeTitle   -- Intitule Gabarit
               , aThirdID   -- Tiers
               , aGoodID   -- Produit
               , nvl(iDescription, aDocNumber)   -- Description
               , aDocRecordID   -- Dossier
               , aStockID   -- Stock
               , aLocationID   -- Emplacement de stock
               , aPositionDetail.PDE_BASIS_DELAY   -- Debut Planif
               , aPositionDetail.PDE_FINAL_DELAY   -- Fin Planif
               , aPositionDetail.PDE_FINAL_DELAY - aPositionDetail.PDE_BASIS_DELAY   -- Duree plannifiee
               , aPositionDetail.PDE_BASIS_DELAY   -- Debut Planif 1
               , aPositionDetail.PDE_FINAL_DELAY   -- Fin Planif 1
               , aPositionDetail.PDE_BASIS_QUANTITY_SU   -- Qte prevue
               , aPositionDetail.PDE_INTERMEDIATE_QUANTITY_SU   -- Qte Rebut prévue
               , aPositionDetail.PDE_FINAL_QUANTITY_SU   -- Qte Totale
               , 0   -- Qte Dechargée
               , 0   -- Qte Realisee
               , 0   -- Qte Rebut Realise
               , 0   -- Qte Retour
               , 0   -- Qte Supplémentaire
               , lnBalanceQtySU   -- Qte Solde
               , lnBalanceQtySU   -- Qte Libre
               , 0   -- Qte Att Stock
               , 0   -- Qte Att Besoin Appro
               , aUseCharID1   -- Caracterisations
               , aUseCharID2
               , aUseCharID3
               , aUseCharID4
               , aUseCharID5
               , aCharValue1   -- Valeurs de caractérisations
               , aCharValue2
               , aCharValue3
               , aCharValue4
               , aCharValue5
               , aPAC_REPRESENTATIVE_ID
                );
  end;

  /**
  * procedure ReseauApproDOC_MAJ
  * Description : Mise à jour complète d'un réseau appro, à partir des valeurs
  *               avant et après update d'une position de document.
  * @lastUpdate
  * @public
  * @param   aPositionDetailNew  : nouvelles values d'une eregistrement position
  * @param   aPositionDetailOld  : anciennes values d'une eregistrement position
  */
  procedure ReseauApproDOC_MAJ(aPositionDetailNew in DOC_POSITION_DETAIL%rowtype, aPositionDetailOld in DOC_POSITION_DETAIL%rowtype)
  is
    aSupplyRecord     FAL_NETWORK_SUPPLY%rowtype;
    aDocRecordID      TTypeID;
    aStockID          TTypeID;
    aLocationID       TTypeID;
    aConversionFactor DOC_POSITION.POS_CONVERT_FACTOR%type;
    aBeginPlan        TTypeDate;
    aEndPlan          TTypeDate;
    aBeginPlan2       TTypeDate;
    aBeginPlan3       TTypeDate;
    aBeginPlan4       TTypeDate;
    aEndPlan2         TTypeDate;
    aEndPlan3         TTypeDate;
    aEndPlan4         TTypeDate;
    aQteSolde         FAL_NETWORK_SUPPLY.FAN_BALANCE_QTY%type;
    aQteLibre         FAL_NETWORK_SUPPLY.FAN_FREE_QTY%type;
    aQteAttStock      FAL_NETWORK_SUPPLY.FAN_STK_QTY%type;
    aQteAttBesoin     FAL_NETWORK_SUPPLY.FAN_NETW_QTY%type;
    aDateChanged      boolean;
    aValueCarac1      DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac2      DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac3      DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac4      DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac5      DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aUseCharID1       number;
    aUseCharID2       number;
    aUseCharID3       number;
    aUseCharID4       number;
    aUseCharID5       number;
    lnNumberOfDecimal GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
    lnOldBalanceQty   FAL_NETWORK_SUPPLY.FAN_BALANCE_QTY%type;
  begin
    -- Ouvrir le curseur sur FAL_NETWORK_SUPPLY
    open GetSupplyRecordForUpdate(aPositionDetailNew.DOC_POSITION_DETAIL_ID);

    fetch GetSupplyRecordForUpdate
     into aSupplyRecord;

    -- Si l'appro associé au PositionDetailID a été trouvé
    if GetSupplyRecordForUpdate%found then
      -- Déterminer le Dossier ID
      aDocRecordID       := GetPositionDocRecordID(aPositionDetailNew.DOC_POSITION_ID);

      -- Déterminer le Stock et l'emplacement ID
      if aPositionDetailNew.STM_LOCATION_ID is null then
        -- Retrouver les stock et emplacement par défaut associés aux configuration PPS_Deflt..._NETWORK
        aStockID  := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_NETWORK');

        if aStockID is null then
          aLocationID  := null;
        else
          aLocationID  := FAL_TOOLS.GetConfig_LocationID('PPS_DefltLOCATION_NETWORK', aStockID);
        end if;
      else
        -- Récupérer le Stock associé à l'emplacement du détail position
        aLocationID  := aPositionDetailNew.STM_LOCATION_ID;
        aStockID     := GetStockIDFromLocation(aLocationID);
      end if;

      -- Déterminer Begin et End Planif
      aBeginPlan         := aPositionDetailNew.PDE_BASIS_DELAY;
      aEndPlan           := aPositionDetailNew.PDE_FINAL_DELAY;
      -- Initialiser l'historique avec les valeurs actuelles
      aBeginPlan2        := aSupplyRecord.FAN_BEG_PLAN2;
      aBeginPlan3        := aSupplyRecord.FAN_BEG_PLAN3;
      aBeginPlan4        := aSupplyRecord.FAN_BEG_PLAN4;
      aEndPlan2          := aSupplyRecord.FAN_END_PLAN2;
      aEndPlan3          := aSupplyRecord.FAN_END_PLAN3;
      aEndPlan4          := aSupplyRecord.FAN_END_PLAN4;
      -- Déterminer si les dates de PositionDétail ont changés
      aDateChanged       :=
            (aPositionDetailNew.PDE_BASIS_DELAY <> aPositionDetailOld.PDE_BASIS_DELAY)
        and (not(     (aPositionDetailNew.PDE_BASIS_DELAY is null)
                 and (aPositionDetailOld.PDE_BASIS_DELAY is null) ) );

      if not aDateChanged then
        aDateChanged  :=
              (aPositionDetailNew.PDE_FINAL_DELAY <> aPositionDetailOld.PDE_FINAL_DELAY)
          and (not(     (aPositionDetailNew.PDE_FINAL_DELAY is null)
                   and (aPositionDetailOld.PDE_FINAL_DELAY is null) ) );
      end if;

      -- Déterminer l'historique de BeginPlanif
      if aSupplyRecord.FAN_BEG_PLAN2 is null then
        if aDateChanged then
          aBeginPlan2  := aPositionDetailNew.PDE_BASIS_DELAY;
        else
          aBeginPlan2  := null;
        end if;
      end if;

      if aSupplyRecord.FAN_BEG_PLAN2 is not null then
        if aSupplyRecord.FAN_BEG_PLAN3 is null then
          if aDateChanged then
            aBeginPlan3  := aPositionDetailNew.PDE_BASIS_DELAY;
          else
            aBeginPlan3  := null;
          end if;
        end if;
      end if;

      if aSupplyRecord.FAN_BEG_PLAN3 is not null then
        if aDateChanged then
          aBeginPlan4  := aPositionDetailNew.PDE_BASIS_DELAY;
        else
          aBeginPlan4  := null;
        end if;
      end if;

      -- Déterminer l'historique de EndPlanif
      if aSupplyRecord.FAN_END_PLAN2 is null then
        if aDateChanged then
          aEndPlan2  := aPositionDetailNew.PDE_FINAL_DELAY;
          -- Mise à jour Date Appro sur Attributions
          FAL_NETWORK.Attribution_MAJ_DateAppro(aSupplyRecord.FAL_NETWORK_SUPPLY_ID, aEndPlan2);
        else
          aEndPlan2  := null;
        end if;
      end if;

      if aSupplyRecord.FAN_END_PLAN2 is not null then
        if aSupplyRecord.FAN_END_PLAN3 is null then
          if aDateChanged then
            aEndPlan3  := aPositionDetailNew.PDE_FINAL_DELAY;
            -- Mise à jour Date Appro sur Attributions
            FAL_NETWORK.Attribution_MAJ_DateAppro(aSupplyRecord.FAL_NETWORK_SUPPLY_ID, aEndPlan3);
          else
            aEndPlan3  := null;
          end if;
        end if;
      end if;

      if aSupplyRecord.FAN_END_PLAN3 is not null then
        if aDateChanged then
          aEndPlan4  := aPositionDetailNew.PDE_FINAL_DELAY;
          -- Mise à jour Date Appro sur Attributions
          FAL_NETWORK.Attribution_MAJ_DateAppro(aSupplyRecord.FAL_NETWORK_SUPPLY_ID, aEndPlan4);
        end if;
      end if;

      -- Déterminer le facteur de conversion de la position
      aConversionFactor  := GetPositionConversionFactor(aPositionDetailNew.DOC_POSITION_ID);
      -- Déterminer la quantité solde en unité de stockage
      -- Recherche également le nombre de décimal sur le bien 'new' pour arrondir supérieure la quantité solde en unité de stockage.
      -- En considérant qu'un changement de bien doit garantir un nombre de décimal identique
      lnNumberOfDecimal  := GCO_I_LIB_FUNCTIONS.GetNumberOfDecimal(aPositionDetailNew.GCO_GOOD_ID);
      lnOldBalanceQty    := ACS_FUNCTION.RoundNear(aPositionDetailOld.PDE_BALANCE_QUANTITY * aConversionFactor, 1 / power(10, lnNumberOfDecimal), 1);
      aQteSolde          := ACS_FUNCTION.RoundNear(aPositionDetailNew.PDE_BALANCE_QUANTITY * aConversionFactor, 1 / power(10, lnNumberOfDecimal), 1);
      -- Déterminer la quantité libre
      aQteLibre          := aSupplyRecord.FAN_FREE_QTY;

      if aPositionDetailOld.PDE_BASIS_QUANTITY_SU > aPositionDetailNew.PDE_BASIS_QUANTITY_SU then
        if (aSupplyRecord.FAN_NETW_QTY + aSupplyRecord.FAN_STK_QTY) < aQteSolde then
          aQteLibre  := aQteSolde - aSupplyRecord.FAN_NETW_QTY - aSupplyRecord.FAN_STK_QTY;
        else
          aQteLibre  := 0;
        end if;
      elsif aPositionDetailOld.PDE_BASIS_QUANTITY_SU = aPositionDetailNew.PDE_BASIS_QUANTITY_SU then
        if aPositionDetailOld.PDE_BALANCE_QUANTITY > aPositionDetailNew.PDE_BALANCE_QUANTITY then
          if aSupplyRecord.FAN_FREE_QTY >= aQteSolde then
            aQteLibre  := aQteSolde;
          end if;
        end if;

        if aPositionDetailOld.PDE_BALANCE_QUANTITY < aPositionDetailNew.PDE_BALANCE_QUANTITY then
          aQteLibre  := aQteLibre + aQteSolde - lnOldBalanceQty;
        end if;
      elsif aPositionDetailOld.PDE_BASIS_QUANTITY_SU < aPositionDetailNew.PDE_BASIS_QUANTITY_SU then
        aQteLibre  := aQteSolde - aSupplyRecord.FAN_NETW_QTY - aSupplyRecord.FAN_STK_QTY;
      end if;

      -- Déterminer la quantité attribuée sur Stock
      aQteAttStock       := aSupplyRecord.FAN_STK_QTY;

      if aPositionDetailOld.PDE_BASIS_QUANTITY_SU > aPositionDetailNew.PDE_BASIS_QUANTITY_SU then
        if (aSupplyRecord.FAN_NETW_QTY + aSupplyRecord.FAN_STK_QTY) >= aQteSolde then
          if (aSupplyRecord.FAN_NETW_QTY) >= aQteSolde then
            aQteAttStock  := 0;
            -- Suppression Attributions Appro-Stock
            FAL_NETWORK.Attribution_Suppr_ApproStock(aSupplyRecord.FAL_NETWORK_SUPPLY_ID);
          else
            aQteAttStock  := aQteSolde - aSupplyRecord.FAN_NETW_QTY;
            -- Mise à jour Attributions Appro-Stock
            FAL_NETWORK.Attribution_MAJ_ApproStock(aSupplyRecord.FAL_NETWORK_SUPPLY_ID, aSupplyRecord.FAN_STK_QTY, aQteAttStock);
          end if;
        end if;
      elsif aPositionDetailOld.PDE_BASIS_QUANTITY_SU = aPositionDetailNew.PDE_BASIS_QUANTITY_SU then
        if aPositionDetailOld.PDE_BALANCE_QUANTITY > aPositionDetailNew.PDE_BALANCE_QUANTITY then
          if (aSupplyRecord.FAN_FREE_QTY + aSupplyRecord.FAN_NETW_QTY) < aQteSolde then
            aQteAttStock  := aQteSolde - aSupplyRecord.FAN_FREE_QTY - aSupplyRecord.FAN_NETW_QTY;
            -- Mise à jour Attributions Appro-Stock
            FAL_NETWORK.Attribution_MAJ_ApproStock(aSupplyRecord.FAL_NETWORK_SUPPLY_ID, aSupplyRecord.FAN_STK_QTY, aQteAttStock);
          else
            aQteAttStock  := 0;
            -- Suppression Attributions Appro-Stock
            FAL_NETWORK.Attribution_Suppr_ApproStock(aSupplyRecord.FAL_NETWORK_SUPPLY_ID);
          end if;
        end if;
      end if;

      -- Déterminer la quantité attribuée sur besoin
      aQteAttBesoin      := aSupplyRecord.FAN_NETW_QTY;

      if aPositionDetailOld.PDE_BASIS_QUANTITY_SU > aPositionDetailNew.PDE_BASIS_QUANTITY_SU then
        if (aSupplyRecord.FAN_NETW_QTY + aSupplyRecord.FAN_STK_QTY) >= aQteSolde then
          if (aSupplyRecord.FAN_NETW_QTY) >= aQteSolde then
            aQteAttBesoin  := aQteSolde;
            -- Mise à jour Attributions Appro-Besoin
            FAL_NETWORK.Attribution_MAJ_ApproBesoin(aSupplyRecord.FAL_NETWORK_SUPPLY_ID, aSupplyRecord.FAN_NETW_QTY, aQteAttBesoin);
          end if;
        end if;
      elsif aPositionDetailOld.PDE_BASIS_QUANTITY_SU = aPositionDetailNew.PDE_BASIS_QUANTITY_SU then
        if aPositionDetailOld.PDE_BALANCE_QUANTITY > aPositionDetailNew.PDE_BALANCE_QUANTITY then
          if (aSupplyRecord.FAN_FREE_QTY + aSupplyRecord.FAN_NETW_QTY) >= aQteSolde then
            if (aSupplyRecord.FAN_FREE_QTY) < aQteSolde then
              aQteAttBesoin  := aQteSolde - aSupplyRecord.FAN_FREE_QTY;
              -- Mise à jour Attributions Appro-Besoin
              FAL_NETWORK.Attribution_MAJ_ApproBesoin(aSupplyRecord.FAL_NETWORK_SUPPLY_ID, aSupplyRecord.FAN_NETW_QTY, aQteAttBesoin);
            else
              aQteAttBesoin  := 0;
              -- Suppression Attributions Appro-Besoin
              FAL_NETWORK.Attribution_Suppr_ApproBesoin(aSupplyRecord.FAL_NETWORK_SUPPLY_ID);
            end if;
          end if;
        end if;
      end if;

      -- Déterminer les caractérisations utilisées dans les réseaux
      GetNetworkCharactFromDetail(aPositionDetailNew
                                , aUseCharID1
                                , aUseCharID2
                                , aUseCharID3
                                , aUseCharID4
                                , aUseCharID5
                                , aValueCarac1
                                , aValueCarac2
                                , aValueCarac3
                                , aValueCarac4
                                , aValueCarac5
                                 );

      -- Update de FAL_NETWORK_SUPPLY
      update FAL_NETWORK_SUPPLY
         set A_DATEMOD = sysdate   -- Date de modification
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni   -- User modification
           , DOC_RECORD_ID = aDocRecordID   -- Dossier
           , STM_STOCK_ID = aStockID   -- Stock
           , STM_LOCATION_ID = aLocationID   -- Emplacement de stock
           , FAN_CHAR_VALUE1 = aValueCarac1   -- Valeur de caractérisation 1
           , FAN_CHAR_VALUE2 = aValueCarac2   -- Valeur de caractérisation 2
           , FAN_CHAR_VALUE3 = aValueCarac3   -- Valeur de caractérisation 3
           , FAN_CHAR_VALUE4 = aValueCarac4   -- Valeur de caractérisation 4
           , FAN_CHAR_VALUE5 = aValueCarac5   -- Valeur de caractérisation 5
           , GCO_CHARACTERIZATION1_ID = aUseCharID1
           , GCO_CHARACTERIZATION2_ID = aUseCharID2
           , GCO_CHARACTERIZATION3_ID = aUseCharID3
           , GCO_CHARACTERIZATION4_ID = aUseCharID4
           , GCO_CHARACTERIZATION5_ID = aUseCharID5
           , FAN_BEG_PLAN = aBeginPlan   -- Debut Planif
           , FAN_END_PLAN = aEndPlan   -- Fin Planif
           , FAN_PLAN_PERIOD = aEndPlan - aBeginPlan   -- Duree plannifiee
           , FAN_BEG_PLAN2 = aBeginPlan2   -- Debut Planif 2
           , FAN_BEG_PLAN3 = aBeginPlan3   -- Debut Planif 3
           , FAN_BEG_PLAN4 = aBeginPlan4   -- Debut Planif 4
           , FAN_END_PLAN2 = aEndPlan2   -- Fin Planif 2
           , FAN_END_PLAN3 = aEndPlan3   -- Fin Planif 3
           , FAN_END_PLAN4 = aEndPlan4   -- Fin Planif 4
           , FAN_PREV_QTY = aPositionDetailNew.PDE_BASIS_QUANTITY_SU   -- Qte prevue
           , FAN_SCRAP_QTY = aPositionDetailNew.PDE_INTERMEDIATE_QUANTITY_SU   -- Qte Rebut prévue
           , FAN_FULL_QTY = aPositionDetailNew.PDE_FINAL_QUANTITY_SU   -- Qte Totale
           , FAN_BALANCE_QTY = aQteSolde   -- Qte Solde
           , FAN_FREE_QTY = aQteLibre   -- Qte Libre
           , FAN_STK_QTY = aQteAttStock   -- Qte Att Stock
           , FAN_NETW_QTY = aQteAttBesoin   -- Qte Att Besoin Appro
       where current of GetSupplyRecordForUpdate;
    end if;

    close GetSupplyRecordForUpdate;
  exception
    when others then
      close GetSupplyRecordForUpdate;

      raise;
  end;

  /**
  * procedure ReseauBesoinDOC_MAJ
  * Description : Mise à jour complète d'un réseau besoin, à partir des valeurs
  *               avant et après update d'une position de document.
  * @lastUpdate
  * @public
  * @param   aPositionDetailNew  : nouvelles values d'une eregistrement position
  * @param   aPositionDetailOld  : anciennes values d'une eregistrement position
  */
  procedure ReseauBesoinDOC_MAJ(aPositionDetailNew in DOC_POSITION_DETAIL%rowtype, aPositionDetailOld in DOC_POSITION_DETAIL%rowtype)
  is
    aNeedRecord            FAL_NETWORK_NEED%rowtype;
    aDocRecordID           TTypeID;
    aStockID               TTypeID;
    aLocationID            TTypeID;
    aConversionFactor      DOC_POSITION.POS_CONVERT_FACTOR%type;
    aBeginPlan             TTypeDate;
    aEndPlan               TTypeDate;
    aBeginPlan2            TTypeDate;
    aBeginPlan3            TTypeDate;
    aBeginPlan4            TTypeDate;
    aEndPlan2              TTypeDate;
    aEndPlan3              TTypeDate;
    aEndPlan4              TTypeDate;
    aQteSolde              FAL_NETWORK_NEED.FAN_BALANCE_QTY%type;
    aQteLibre              FAL_NETWORK_NEED.FAN_FREE_QTY%type;
    aQteAttStock           FAL_NETWORK_NEED.FAN_STK_QTY%type;
    aQteAttBesoin          FAL_NETWORK_NEED.FAN_NETW_QTY%type;
    aDateChanged           boolean;
    aPAC_REPRESENTATIVE_ID TTypeID;   -- DJ20001114-0181
    aValueCarac1           DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac2           DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac3           DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac4           DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac5           DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aUseCharID1            number;
    aUseCharID2            number;
    aUseCharID3            number;
    aUseCharID4            number;
    aUseCharID5            number;
    lnNumberOfDecimal      GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
    lnOldBalanceQty        FAL_NETWORK_SUPPLY.FAN_BALANCE_QTY%type;
  begin
    -- Ouvrir le curseur sur FAL_NETWORK_NEED
    open GetNeedRecordForUpdate(aPositionDetailNew.DOC_POSITION_DETAIL_ID);

    fetch GetNeedRecordForUpdate
     into aNeedRecord;

    -- Si le besoin associé au PositionDetailID a été trouvé
    if GetNeedRecordForUpdate%found then
      -- Déterminer le Dossier ID
      aDocRecordID       := GetPositionDocRecordID(aPositionDetailNew.DOC_POSITION_ID);

      -- Déterminer le Stock et l'emplacement ID
      if aPositionDetailNew.STM_LOCATION_ID is null then
        -- Retrouver les stock et emplacement par défaut associés aux configuration PPS_Deflt..._NETWORK
        aStockID  := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_NETWORK');

        if aStockID is null then
          aLocationID  := null;
        else
          aLocationID  := FAL_TOOLS.GetConfig_LocationID('PPS_DefltLOCATION_NETWORK', aStockID);
        end if;
      else
        -- Récupérer le Stock associé à l'emplacement du détail position
        aLocationID  := aPositionDetailNew.STM_LOCATION_ID;
        aStockID     := GetStockIDFromLocation(aLocationID);
      end if;

      -- Déterminer Begin et End Planif
      aBeginPlan         := aPositionDetailNew.PDE_BASIS_DELAY;
      aEndPlan           := aPositionDetailNew.PDE_FINAL_DELAY;
      -- Initialiser l'historique avec les valeurs actuelles
      aBeginPlan2        := aNeedRecord.FAN_BEG_PLAN2;
      aBeginPlan3        := aNeedRecord.FAN_BEG_PLAN3;
      aBeginPlan4        := aNeedRecord.FAN_BEG_PLAN4;
      aEndPlan2          := aNeedRecord.FAN_END_PLAN2;
      aEndPlan3          := aNeedRecord.FAN_END_PLAN3;
      aEndPlan4          := aNeedRecord.FAN_END_PLAN4;
      -- Déterminer si les dates de PositionDétail ont changés
      aDateChanged       :=
            (aPositionDetailNew.PDE_BASIS_DELAY <> aPositionDetailOld.PDE_BASIS_DELAY)
        and (not(     (aPositionDetailNew.PDE_BASIS_DELAY is null)
                 and (aPositionDetailOld.PDE_BASIS_DELAY is null) ) );

      if not aDateChanged then
        aDateChanged  :=
              (aPositionDetailNew.PDE_FINAL_DELAY <> aPositionDetailOld.PDE_FINAL_DELAY)
          and (not(     (aPositionDetailNew.PDE_FINAL_DELAY is null)
                   and (aPositionDetailOld.PDE_FINAL_DELAY is null) ) );
      end if;

      -- Déterminer l'historique de BeginPlanif
      if aNeedRecord.FAN_BEG_PLAN2 is null then
        if aDateChanged then
          aBeginPlan2  := aPositionDetailNew.PDE_BASIS_DELAY;
          -- Mise à jour Date Besoin sur Attributions
          FAL_NETWORK.Attribution_MAJ_DateBesoin(aNeedRecord.FAL_NETWORK_NEED_ID, aBeginPlan2);
        else
          aBeginPlan2  := null;
        end if;
      end if;

      if aNeedRecord.FAN_BEG_PLAN2 is not null then
        if aNeedRecord.FAN_BEG_PLAN3 is null then
          if aDateChanged then
            aBeginPlan3  := aPositionDetailNew.PDE_BASIS_DELAY;
            -- Mise à jour Date Besoin sur Attributions
            FAL_NETWORK.Attribution_MAJ_DateBesoin(aNeedRecord.FAL_NETWORK_NEED_ID, aBeginPlan3);
          else
            aBeginPlan3  := null;
          end if;
        end if;
      end if;

      if aNeedRecord.FAN_BEG_PLAN3 is not null then
        if aDateChanged then
          aBeginPlan4  := aPositionDetailNew.PDE_BASIS_DELAY;
          -- Mise à jour Date Besoin sur Attributions
          FAL_NETWORK.Attribution_MAJ_DateBesoin(aNeedRecord.FAL_NETWORK_NEED_ID, aBeginPlan4);
        else
          aBeginPlan4  := null;
        end if;
      end if;

      -- Déterminer l'historique de EndPlanif
      if aNeedRecord.FAN_END_PLAN2 is null then
        if aDateChanged then
          aEndPlan2  := aPositionDetailNew.PDE_FINAL_DELAY;
        else
          aEndPlan2  := null;
        end if;
      end if;

      if aNeedRecord.FAN_END_PLAN2 is not null then
        if aNeedRecord.FAN_END_PLAN3 is null then
          if aDateChanged then
            aEndPlan3  := aPositionDetailNew.PDE_FINAL_DELAY;
          else
            aEndPlan3  := null;
          end if;
        end if;
      end if;

      if aNeedRecord.FAN_END_PLAN3 is not null then
        if aDateChanged then
          aEndPlan4  := aPositionDetailNew.PDE_FINAL_DELAY;
        end if;
      end if;

      -- Déterminer le facteur de conversion de la position
      aConversionFactor  := GetPositionConversionFactor(aPositionDetailNew.DOC_POSITION_ID);
      -- Déterminer la quantité solde en unité de stockage
      -- Recherche également le nombre de décimal sur le bien 'new' pour arrondir supérieure la quantité solde en unité de stockage.
      -- En considérant qu'un changement de bien doit garantir un nombre de décimal identique
      lnNumberOfDecimal  := GCO_I_LIB_FUNCTIONS.GetNumberOfDecimal(aPositionDetailNew.GCO_GOOD_ID);
      lnOldBalanceQty    := ACS_FUNCTION.RoundNear(aPositionDetailOld.PDE_BALANCE_QUANTITY * aConversionFactor, 1 / power(10, lnNumberOfDecimal), 1);
      aQteSolde          := ACS_FUNCTION.RoundNear(aPositionDetailNew.PDE_BALANCE_QUANTITY * aConversionFactor, 1 / power(10, lnNumberOfDecimal), 1);
      -- Déterminer la quantité libre
      aQteLibre          := aNeedRecord.FAN_FREE_QTY;

      if aPositionDetailOld.PDE_FINAL_QUANTITY_SU > aPositionDetailNew.PDE_FINAL_QUANTITY_SU then
        if (aNeedRecord.FAN_NETW_QTY + aNeedRecord.FAN_STK_QTY) < aQteSolde then
          aQteLibre  := aQteSolde - aNeedRecord.FAN_NETW_QTY - aNeedRecord.FAN_STK_QTY;
        else
          aQteLibre  := 0;
        end if;
      elsif aPositionDetailOld.PDE_FINAL_QUANTITY_SU = aPositionDetailNew.PDE_FINAL_QUANTITY_SU then
        if aPositionDetailOld.PDE_BALANCE_QUANTITY > aPositionDetailNew.PDE_BALANCE_QUANTITY then
          if aNeedRecord.FAN_FREE_QTY + aNeedRecord.FAN_NETW_QTY < aQteSolde then
            null;   -- pas de traitement
          end if;

          if aNeedRecord.FAN_FREE_QTY + aNeedRecord.FAN_NETW_QTY >= aQteSolde then
            if aNeedRecord.FAN_NETW_QTY < aQteSolde then
              aQteLibre  := aQteSolde - aNeedRecord.FAN_NETW_QTY;
            end if;

            if aNeedRecord.FAN_NETW_QTY >= aQteSolde then
              aQteLibre  := 0;
            end if;
          end if;
        end if;

        if aPositionDetailOld.PDE_BALANCE_QUANTITY < aPositionDetailNew.PDE_BALANCE_QUANTITY then
          aQteLibre  := aQteLibre + aQteSolde - lnOldBalanceQty;
        end if;
      elsif aPositionDetailOld.PDE_FINAL_QUANTITY_SU < aPositionDetailNew.PDE_FINAL_QUANTITY_SU then
        aQteLibre  := aQteSolde - aNeedRecord.FAN_NETW_QTY - aNeedRecord.FAN_STK_QTY;
      end if;

      -- Déterminer la quantité attribuée sur Stock
      aQteAttStock       := aNeedRecord.FAN_STK_QTY;

      if aPositionDetailOld.PDE_FINAL_QUANTITY_SU > aPositionDetailNew.PDE_FINAL_QUANTITY_SU then
        if (aNeedRecord.FAN_NETW_QTY + aNeedRecord.FAN_STK_QTY) >= aQteSolde then
          if (aNeedRecord.FAN_NETW_QTY) >= aQteSolde then
            aQteAttStock  := 0;
            -- Suppression Attributions Besoin-Stock
            FAL_NETWORK.Attribution_Suppr_BesoinStock(aNeedRecord.FAL_NETWORK_NEED_ID);
          else
            aQteAttStock  := aQteSolde - aNeedRecord.FAN_NETW_QTY;
            -- Mise à jour Attributions Besoin-Stock
            FAL_NETWORK.Attribution_MAJ_BesoinStock(aNeedRecord.FAL_NETWORK_NEED_ID
                                                  , aNeedRecord.FAN_STK_QTY
                                                  , aQteAttStock
                                                  , aPositionDetailNew.FAL_NETWORK_LINK_ID
                                                   );
          end if;
        end if;
      elsif aPositionDetailOld.PDE_FINAL_QUANTITY_SU = aPositionDetailNew.PDE_FINAL_QUANTITY_SU then
        if aPositionDetailOld.PDE_BALANCE_QUANTITY > aPositionDetailNew.PDE_BALANCE_QUANTITY then
          if (aNeedRecord.FAN_FREE_QTY + aNeedRecord.FAN_NETW_QTY) < aQteSolde then
            aQteAttStock  := aQteSolde - aNeedRecord.FAN_FREE_QTY - aNeedRecord.FAN_NETW_QTY;
            -- Mise à jour Attributions Besoin-Stock
            FAL_NETWORK.Attribution_MAJ_BesoinStock(aNeedRecord.FAL_NETWORK_NEED_ID
                                                  , aNeedRecord.FAN_STK_QTY
                                                  , aQteAttStock
                                                  , aPositionDetailNew.FAL_NETWORK_LINK_ID
                                                   );
          else
            aQteAttStock  := 0;
            -- Suppression Attributions Besoin-Stock
            FAL_NETWORK.Attribution_Suppr_BesoinStock(aNeedRecord.FAL_NETWORK_NEED_ID);
          end if;
        end if;
      end if;

      -- Déterminer la quantité attribuée sur besoin
      aQteAttBesoin      := aNeedRecord.FAN_NETW_QTY;

      if aPositionDetailOld.PDE_FINAL_QUANTITY_SU > aPositionDetailNew.PDE_FINAL_QUANTITY_SU then
        if (aNeedRecord.FAN_NETW_QTY + aNeedRecord.FAN_STK_QTY) >= aQteSolde then
          if (aNeedRecord.FAN_NETW_QTY) >= aQteSolde then
            aQteAttBesoin  := aQteSolde;
            -- Mise à jour Attributions Besoin-Appro
            FAL_NETWORK.Attribution_MAJ_BesoinAppro(aNeedRecord.FAL_NETWORK_NEED_ID, aNeedRecord.FAN_NETW_QTY, aQteAttBesoin);
          end if;
        end if;
      elsif aPositionDetailOld.PDE_FINAL_QUANTITY_SU = aPositionDetailNew.PDE_FINAL_QUANTITY_SU then
        if aPositionDetailOld.PDE_BALANCE_QUANTITY > aPositionDetailNew.PDE_BALANCE_QUANTITY then
          if aNeedRecord.FAN_NETW_QTY < aQteSolde then
            null;   -- Pas de traitement
          end if;

          if aNeedRecord.FAN_NETW_QTY = aQteSolde then
            null;   -- Pas de traitement
          end if;

          if aNeedRecord.FAN_NETW_QTY > aQteSolde then
            aQteAttBesoin  := aQteSolde;
            -- Mise à jour Attributions Besoin-Appro
            FAL_NETWORK.Attribution_MAJ_BesoinAppro(aNeedRecord.FAL_NETWORK_NEED_ID, aNeedRecord.FAN_NETW_QTY, aQteAttBesoin);
          end if;
        end if;
      end if;

      -- Déterminer le représentant
      if aPositionDetailNew.DOC_POSITION_ID is not null then
        select pac_representative_id
          into aPAC_REPRESENTATIVE_ID
          from doc_position
         where doc_position_id = aPositionDetailNew.doc_position_id;
      end if;

      -- Déterminer les caractérisations utilisées dans les réseaux
      GetNetworkCharactFromDetail(aPositionDetailNew
                                , aUseCharID1
                                , aUseCharID2
                                , aUseCharID3
                                , aUseCharID4
                                , aUseCharID5
                                , aValueCarac1
                                , aValueCarac2
                                , aValueCarac3
                                , aValueCarac4
                                , aValueCarac5
                                 );

      -- Update de FAL_NETWORK_NEED
      update FAL_NETWORK_NEED
         set A_DATEMOD = sysdate   -- Date de modification
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni   -- User modification
           , DOC_RECORD_ID = aDocRecordID   -- Dossier
           , STM_STOCK_ID = aStockID   -- Stock
           , STM_LOCATION_ID = aLocationID   -- Emplacement de stock
           , FAN_CHAR_VALUE1 = aValueCarac1   -- Valeur de caractérisation 1
           , FAN_CHAR_VALUE2 = aValueCarac2   -- Valeur de caractérisation 2
           , FAN_CHAR_VALUE3 = aValueCarac3   -- Valeur de caractérisation 3
           , FAN_CHAR_VALUE4 = aValueCarac4   -- Valeur de caractérisation 4
           , FAN_CHAR_VALUE5 = aValueCarac5   -- Valeur de caractérisation 5
           , GCO_CHARACTERIZATION1_ID = aUseCharID1
           , GCO_CHARACTERIZATION2_ID = aUseCharID2
           , GCO_CHARACTERIZATION3_ID = aUseCharID3
           , GCO_CHARACTERIZATION4_ID = aUseCharID4
           , GCO_CHARACTERIZATION5_ID = aUseCharID5
           , FAN_BEG_PLAN = aBeginPlan   -- Debut Planif
           , FAN_END_PLAN = aEndPlan   -- Fin Planif
           , FAN_PLAN_PERIOD = aEndPlan - aBeginPlan   -- Duree plannifiee
           , FAN_BEG_PLAN2 = aBeginPlan2   -- Debut Planif 2
           , FAN_BEG_PLAN3 = aBeginPlan3   -- Debut Planif 3
           , FAN_BEG_PLAN4 = aBeginPlan4   -- Debut Planif 4
           , FAN_END_PLAN2 = aEndPlan2   -- Fin Planif 2
           , FAN_END_PLAN3 = aEndPlan3   -- Fin Planif 3
           , FAN_END_PLAN4 = aEndPlan4   -- Fin Planif 4
           , FAN_PREV_QTY = aPositionDetailNew.PDE_BASIS_QUANTITY_SU   -- Qte prevue
           , FAN_SCRAP_QTY = aPositionDetailNew.PDE_INTERMEDIATE_QUANTITY_SU   -- Qte Rebut prévue
           , FAN_FULL_QTY = aPositionDetailNew.PDE_FINAL_QUANTITY_SU   -- Qte Totale
           , FAN_BALANCE_QTY = aQteSolde   -- Qte Solde
           , FAN_FREE_QTY = aQteLibre   -- Qte Libre
           , FAN_STK_QTY = aQteAttStock   -- Qte Att Stock
           , FAN_NETW_QTY = aQteAttBesoin   -- Qte Att Besoin Appro
           , PAC_REPRESENTATIVE_ID = aPAC_REPRESENTATIVE_ID   -- Représentant
       where current of GetNeedRecordForUpdate;
    end if;

    close GetNeedRecordForUpdate;
  exception
    when others then
      close GetNeedRecordForUpdate;

      raise;
  end;

  /**
  * procedure ReseauApproDOC_Suppr
  * Description : Suppression d'une réseau appro lié à un détail de position
  *               de document.
  *
  * @lastUpdate
  * @public
  * @param   aPositionDetailID  : Détail position de document
  * @param   aHistorisation  : Historisation du record.
  */
  procedure ReseauApproDOC_Suppr(aPositionDetailID in TTypeID, aHistorisation in boolean)
  is
    aRecord GetSupplyRecordForUpdate%rowtype;
  begin
    -- Ouvrir le curseur sur FAL_NETWORK_SUPPLY
    open GetSupplyRecordForUpdate(aPositionDetailID);

    fetch GetSupplyRecordForUpdate
     into aRecord;

    if GetSupplyRecordForUpdate%found then
      -- Historisation
      if aHistorisation then
        FAL_NETWORK.ReseauApproFAL_Historisation(aRecord.FAL_NETWORK_SUPPLY_ID);
      end if;

      -- Suppression Attributions Appro-Stock
      FAL_NETWORK.Attribution_Suppr_ApproStock(aRecord.FAL_NETWORK_SUPPLY_ID);
      -- Suppression Attributions Appro-Besoin
      FAL_NETWORK.Attribution_Suppr_ApproBesoin(aRecord.FAL_NETWORK_SUPPLY_ID);

      delete      FAL_NETWORK_SUPPLY
            where current of GetSupplyRecordForUpdate;
    end if;

    close GetSupplyRecordForUpdate;
  exception
    when others then
      close GetSupplyRecordForUpdate;

      raise;
  end;

  /**
  * procedure ReseauBesoinDOC_Suppr
  * Description : Suppression d'une réseau besoin lié à un détail de position
  *               de document.
  *
  * @lastUpdate
  * @public
  * @param   aPositionDetailID  : Détail position de document
  * @param   aHistorisation  : Historisation du record.
  */
  procedure ReseauBesoinDOC_Suppr(aPositionDetailID in TTypeID, aHistorisation in boolean)
  is
    aRecord GetNeedRecordForUpdate%rowtype;
  begin
    open GetNeedRecordForUpdate(aPositionDetailID);

    fetch GetNeedRecordForUpdate
     into aRecord;

    if GetNeedRecordForUpdate%found then
      -- Historisation ?
      if aHistorisation then
        FAL_NETWORK.ReseauBesoinFAL_Historisation(aRecord.FAL_NETWORK_NEED_ID);
      end if;

      -- Suppression Attributions Besoin-Stock
      FAL_NETWORK.Attribution_Suppr_BesoinStock(aRecord.FAL_NETWORK_NEED_ID);
      -- Suppression Attributions Besoin-Appro
      FAL_NETWORK.Attribution_Suppr_BesoinAppro(aRecord.FAL_NETWORK_NEED_ID);

      delete      FAL_NETWORK_NEED
            where current of GetNeedRecordForUpdate;
    end if;

    close GetNeedRecordForUpdate;
  exception
    when others then
      close GetNeedRecordForUpdate;

      raise;
  end;

  /**
  * procedure Update_Doc_Network
  * Description :  Mise à jour des tables réseaux à partir de tous les documents
  *                existants. Utilisée pour mettre à jour les réseaux auprès de
  *                clients installés avant l'implantation des réseaux
  *
  * @lastUpdate
  * @public
  */
  procedure UPDATE_DOC_NETWORK
  is
    cursor GetDetailPositions(aGaugeType in DOC_GAUGE.C_GAUGE_TYPE%type)
    is
      select Detail.*
        from Doc_position_detail Detail
           , Doc_position position
           , Doc_document Doc
           , Doc_gauge Gauge
       where Detail.Doc_position_id = position.Doc_position_id
         and position.Doc_document_id = Doc.Doc_document_id
         and Doc.Doc_gauge_id = Gauge.Doc_gauge_id
         and position.C_DOC_POs_STATUS in('02', '03')
         and position.C_Gauge_Type_Pos in('1', '2', '3', '7', '8', '9', '10', '71', '81', '91', '101')
         and Gauge.c_Gauge_Type = aGaugeType
         and nvl(Detail.PDE_BALANCE_QUANTITY, 0) > 0;

    aCount     integer;
    lvFanDescr FAL_NETWORK_SUPPLY.FAN_DESCRIPTION%type;
  begin
    -- Traitement des Approvisionnements
    for aDetailRecord in GetDetailPositions('2') loop
      -- Vérifier si ce détail position n'existe pas déjà dans les réseaux
      select count(*)
        into aCount
        from FAL_NETWORK_SUPPLY
       where DOC_POSITION_DETAIL_ID = aDetailRecord.DOC_POSITION_DETAIL_ID;

      if aCount = 0 then
        -- Description de l'appro
        select DMT.DMT_NUMBER || ' / ' || POS.POS_NUMBER
          into lvFanDescr
          from DOC_DOCUMENT DMT
             , DOC_POSITION POS
         where POS.DOC_POSITION_ID = aDetailRecord.DOC_POSITION_ID
           and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID;

        -- Réseau inexistant. Processus : Création ReseauxLogAppro
        FAL_NETWORK_DOC.ReseauApproDOC_Creation(aPositionDetail     => aDetailRecord
                                              , pDocumentID         => null
                                              , pGoodID             => null
                                              , pDocRecordID        => null
                                              , pConversionFactor   => null
                                              , iDescription        => lvFanDescr
                                               );
      end if;
    end loop;

    -- Traitement des Besoins
    for aDetailRecord in GetDetailPositions('1') loop
      -- Vérifier si ce détail position n'existe pas déjà dans les réseaux
      select count(*)
        into aCount
        from FAL_NETWORK_NEED
       where DOC_POSITION_DETAIL_ID = aDetailRecord.DOC_POSITION_DETAIL_ID;

      if aCount = 0 then
        -- Description du besoin
        select DMT.DMT_NUMBER || ' / ' || POS.POS_NUMBER
          into lvFanDescr
          from DOC_DOCUMENT DMT
             , DOC_POSITION POS
         where POS.DOC_POSITION_ID = aDetailRecord.DOC_POSITION_ID
           and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID;

        -- Réseau inexistant. Processus : Création ReseauxLogBesoin
        FAL_NETWORK_DOC.ReseauBesoinDOC_Creation(aPositionDetail          => aDetailRecord
                                               , pDocumentID              => null
                                               , pGoodID                  => null
                                               , pDocRecordID             => null
                                               , pConversionFactor        => null
                                               , pPAC_REPRESENTATIVE_ID   => null
                                               , iDescription             => lvFanDescr
                                                );
      end if;
    end loop;
  end;

  /**
  * procedure ReseauBesoinDOC_MAJ_78910
  * Description : Mise à jour des réseaux besoin pour les positions
  *               7, 8, 9, 10
  * @lastUpdate
  * @public
  * @param   aPositionDetailNew : Détail position, nouvelles valeurs
  * @param   aPositionDetailOld : Détail position, anciennes valeurs
  */
  procedure ReseauBesoinDOC_MAJ_78910(aPositionDetailNew in DOC_POSITION_DETAIL%rowtype, aPositionDetailOld in DOC_POSITION_DETAIL%rowtype)
  is
    aNeedRecord            FAL_NETWORK_NEED%rowtype;
    aDocRecordID           TTypeID;
    aStockID               TTypeID;
    aLocationID            TTypeID;
    aConversionFactor      DOC_POSITION.POS_CONVERT_FACTOR%type;
    aBeginPlan             TTypeDate;
    aEndPlan               TTypeDate;
    aBeginPlan2            TTypeDate;
    aBeginPlan3            TTypeDate;
    aBeginPlan4            TTypeDate;
    aEndPlan2              TTypeDate;
    aEndPlan3              TTypeDate;
    aEndPlan4              TTypeDate;
    aQteSolde              FAL_NETWORK_NEED.FAN_BALANCE_QTY%type;
    aQteAttBesoin          FAL_NETWORK_NEED.FAN_NETW_QTY%type;
    aDateChanged           boolean;
    aPAC_REPRESENTATIVE_ID TTypeID;   -- DJ20001114-0181
    aValueCarac1           DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac2           DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac3           DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac4           DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac5           DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aUseCharID1            number;
    aUseCharID2            number;
    aUseCharID3            number;
    aUseCharID4            number;
    aUseCharID5            number;
    lnNumberOfDecimal      GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
  begin
    -- Ouvrir le curseur sur FAL_NETWORK_NEED
    open GetNeedRecordForUpdate(aPositionDetailNew.DOC_POSITION_DETAIL_ID);

    fetch GetNeedRecordForUpdate
     into aNeedRecord;

    -- Si le besoin associé au PositionDetailID a été trouvé
    if GetNeedRecordForUpdate%found then
      -- Déterminer le Dossier ID
      aDocRecordID       := GetPositionDocRecordID(aPositionDetailNew.DOC_POSITION_ID);

      -- Déterminer le Stock et l'emplacement ID
      if aPositionDetailNew.STM_LOCATION_ID is null then
        -- Retrouver les stock et emplacement par défaut associés aux configuration PPS_Deflt..._NETWORK
        aStockID  := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_NETWORK');

        if aStockID is null then
          aLocationID  := null;
        else
          aLocationID  := FAL_TOOLS.GetConfig_LocationID('PPS_DefltLOCATION_NETWORK', aStockID);
        end if;
      else
        -- Récupérer le Stock associé à l'emplacement du détail position
        aLocationID  := aPositionDetailNew.STM_LOCATION_ID;
        aStockID     := GetStockIDFromLocation(aLocationID);
      end if;

      -- Déterminer Begin et End Planif
      aBeginPlan         := aPositionDetailNew.PDE_BASIS_DELAY;
      aEndPlan           := aPositionDetailNew.PDE_FINAL_DELAY;
      -- Initialiser l'historique avec les valeurs actuelles
      aBeginPlan2        := aNeedRecord.FAN_BEG_PLAN2;
      aBeginPlan3        := aNeedRecord.FAN_BEG_PLAN3;
      aBeginPlan4        := aNeedRecord.FAN_BEG_PLAN4;
      aEndPlan2          := aNeedRecord.FAN_END_PLAN2;
      aEndPlan3          := aNeedRecord.FAN_END_PLAN3;
      aEndPlan4          := aNeedRecord.FAN_END_PLAN4;
      -- Déterminer si les dates de PositionDétail ont changés
      aDateChanged       :=
            (aPositionDetailNew.PDE_BASIS_DELAY <> aPositionDetailOld.PDE_BASIS_DELAY)
        and (not(     (aPositionDetailNew.PDE_BASIS_DELAY is null)
                 and (aPositionDetailOld.PDE_BASIS_DELAY is null) ) );

      if not aDateChanged then
        aDateChanged  :=
              (aPositionDetailNew.PDE_FINAL_DELAY <> aPositionDetailOld.PDE_FINAL_DELAY)
          and (not(     (aPositionDetailNew.PDE_FINAL_DELAY is null)
                   and (aPositionDetailOld.PDE_FINAL_DELAY is null) ) );
      end if;

      -- Déterminer l'historique de BeginPlanif
      if aNeedRecord.FAN_BEG_PLAN2 is null then
        if aDateChanged then
          aBeginPlan2  := aPositionDetailNew.PDE_BASIS_DELAY;
          -- Mise à jour Date Besoin sur Attributions
          FAL_NETWORK.Attribution_MAJ_DateBesoin(aNeedRecord.FAL_NETWORK_NEED_ID, aBeginPlan2);
        else
          aBeginPlan2  := null;
        end if;
      end if;

      if aNeedRecord.FAN_BEG_PLAN2 is not null then
        if aNeedRecord.FAN_BEG_PLAN3 is null then
          if aDateChanged then
            aBeginPlan3  := aPositionDetailNew.PDE_BASIS_DELAY;
            -- Mise à jour Date Besoin sur Attributions
            FAL_NETWORK.Attribution_MAJ_DateBesoin(aNeedRecord.FAL_NETWORK_NEED_ID, aBeginPlan3);
          else
            aBeginPlan3  := null;
          end if;
        end if;
      end if;

      if aNeedRecord.FAN_BEG_PLAN3 is not null then
        if aDateChanged then
          aBeginPlan4  := aPositionDetailNew.PDE_BASIS_DELAY;
          -- Mise à jour Date Besoin sur Attributions
          FAL_NETWORK.Attribution_MAJ_DateBesoin(aNeedRecord.FAL_NETWORK_NEED_ID, aBeginPlan4);
        else
          aBeginPlan4  := null;
        end if;
      end if;

      -- Déterminer l'historique de EndPlanif
      if aNeedRecord.FAN_END_PLAN2 is null then
        if aDateChanged then
          aEndPlan2  := aPositionDetailNew.PDE_FINAL_DELAY;
        else
          aEndPlan2  := null;
        end if;
      end if;

      if aNeedRecord.FAN_END_PLAN2 is not null then
        if aNeedRecord.FAN_END_PLAN3 is null then
          if aDateChanged then
            aEndPlan3  := aPositionDetailNew.PDE_FINAL_DELAY;
          else
            aEndPlan3  := null;
          end if;
        end if;
      end if;

      if aNeedRecord.FAN_END_PLAN3 is not null then
        if aDateChanged then
          aEndPlan4  := aPositionDetailNew.PDE_FINAL_DELAY;
        end if;
      end if;

      -- Déterminer le facteur de conversion de la position
      aConversionFactor  := GetPositionConversionFactor(aPositionDetailNew.DOC_POSITION_ID);
      -- Déterminer la quantité solde en unité de stockage
      -- Recherche également le nombre de décimal sur le bien pour arrondir supérieure la quantité solde en unité de stockage
      lnNumberOfDecimal  := GCO_I_LIB_FUNCTIONS.GetNumberOfDecimal(aPositionDetailNew.GCO_GOOD_ID);
      aQteSolde          := ACS_FUNCTION.RoundNear(aPositionDetailNew.PDE_BALANCE_QUANTITY * aConversionFactor, 1 / power(10, lnNumberOfDecimal), 1);

      -- Déterminer le représentant
      if aPositionDetailNew.DOC_POSITION_ID is not null then
        select pac_representative_id
          into aPAC_REPRESENTATIVE_ID
          from doc_position
         where doc_position_id = aPositionDetailNew.doc_position_id;
      end if;

      -- Déterminer les caractérisations utilisées dans les réseaux
      GetNetworkCharactFromDetail(aPositionDetailNew
                                , aUseCharID1
                                , aUseCharID2
                                , aUseCharID3
                                , aUseCharID4
                                , aUseCharID5
                                , aValueCarac1
                                , aValueCarac2
                                , aValueCarac3
                                , aValueCarac4
                                , aValueCarac5
                                 );

      -- Update de FAL_NETWORK_NEED
      update FAL_NETWORK_NEED
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , DOC_RECORD_ID = aDocRecordID
           , STM_STOCK_ID = aStockID
           , STM_LOCATION_ID = aLocationID
           , FAN_CHAR_VALUE1 = aValueCarac1
           , FAN_CHAR_VALUE2 = aValueCarac2
           , FAN_CHAR_VALUE3 = aValueCarac3
           , FAN_CHAR_VALUE4 = aValueCarac4
           , FAN_CHAR_VALUE5 = aValueCarac5
           , GCO_CHARACTERIZATION1_ID = aUseCharID1
           , GCO_CHARACTERIZATION2_ID = aUseCharID2
           , GCO_CHARACTERIZATION3_ID = aUseCharID3
           , GCO_CHARACTERIZATION4_ID = aUseCharID4
           , GCO_CHARACTERIZATION5_ID = aUseCharID5
           , FAN_BEG_PLAN = aBeginPlan
           , FAN_END_PLAN = aEndPlan
           , FAN_PLAN_PERIOD = aEndPlan - aBeginPlan
           , FAN_BEG_PLAN2 = aBeginPlan2
           , FAN_BEG_PLAN3 = aBeginPlan3
           , FAN_BEG_PLAN4 = aBeginPlan4
           , FAN_END_PLAN2 = aEndPlan2
           , FAN_END_PLAN3 = aEndPlan3
           , FAN_END_PLAN4 = aEndPlan4
           , FAN_PREV_QTY = aPositionDetailNew.PDE_BASIS_QUANTITY_SU   -- Qte prevue
           , FAN_SCRAP_QTY = aPositionDetailNew.PDE_INTERMEDIATE_QUANTITY_SU   -- Qte Rebut prévue
           , FAN_FULL_QTY = aPositionDetailNew.PDE_FINAL_QUANTITY_SU   -- Qte Totale
           , FAN_BALANCE_QTY = aQteSolde   -- Qte Solde
           , FAN_NETW_QTY = aQteSolde   -- Qte Att Besoin Appro
           , PAC_REPRESENTATIVE_ID = aPAC_REPRESENTATIVE_ID   -- Représentant
       where current of GetNeedRecordForUpdate;
    end if;

    close GetNeedRecordForUpdate;
  exception
    when others then
      close GetNeedRecordForUpdate;

      raise;
  end;

  /**
  * procedure ReseauApproDOC_MAJ_78910
  * Description : Mise à jour des réseaux appro pour les positions
  *               7, 8, 9, 10
  * @lastUpdate
  * @public
  * @param   aPositionDetailNew : Détail position, nouvelles valeurs
  * @param   aPositionDetailOld : Détail position, anciennes valeurs
  */
  procedure ReseauApproDOC_MAJ_78910(aPositionDetailNew in DOC_POSITION_DETAIL%rowtype, aPositionDetailOld in DOC_POSITION_DETAIL%rowtype)
  is
    aSupplyRecord     FAL_NETWORK_SUPPLY%rowtype;
    aDocRecordID      TTypeID;
    aStockID          TTypeID;
    aLocationID       TTypeID;
    aConversionFactor DOC_POSITION.POS_CONVERT_FACTOR%type;
    aBeginPlan        TTypeDate;
    aEndPlan          TTypeDate;
    aBeginPlan2       TTypeDate;
    aBeginPlan3       TTypeDate;
    aBeginPlan4       TTypeDate;
    aEndPlan2         TTypeDate;
    aEndPlan3         TTypeDate;
    aEndPlan4         TTypeDate;
    aQteSolde         FAL_NETWORK_SUPPLY.FAN_BALANCE_QTY%type;
    aQteAttBesoin     FAL_NETWORK_SUPPLY.FAN_NETW_QTY%type;
    aDateChanged      boolean;
    aValueCarac1      DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac2      DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac3      DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac4      DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac5      DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aUseCharID1       number;
    aUseCharID2       number;
    aUseCharID3       number;
    aUseCharID4       number;
    aUseCharID5       number;
    lnNumberOfDecimal GCO_GOOD.GOO_NUMBER_OF_DECIMAL%type;
  begin
    -- Ouvrir le curseur sur FAL_NETWORK_SUPPLY
    open GetSupplyRecordForUpdate(aPositionDetailNew.DOC_POSITION_DETAIL_ID);

    fetch GetSupplyRecordForUpdate
     into aSupplyRecord;

    -- Si l'appro associé au PositionDetailID a été trouvé
    if GetSupplyRecordForUpdate%found then
      -- Déterminer le Dossier ID
      aDocRecordID       := GetPositionDocRecordID(aPositionDetailNew.DOC_POSITION_ID);

      -- Déterminer le Stock et l'emplacement ID
      if aPositionDetailNew.STM_LOCATION_ID is null then
        -- Retrouver les stock et emplacement par défaut associés aux configuration PPS_Deflt
        aStockID  := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_NETWORK');

        if aStockID is null then
          aLocationID  := null;
        else
          aLocationID  := FAL_TOOLS.GetConfig_LocationID('PPS_DefltLOCATION_NETWORK', aStockID);
        end if;
      else
        -- Récupérer le Stock associé à l'emplacement du détail position
        aLocationID  := aPositionDetailNew.STM_LOCATION_ID;
        aStockID     := GetStockIDFromLocation(aLocationID);
      end if;

      -- Déterminer Begin et End Planif
      aBeginPlan         := aPositionDetailNew.PDE_BASIS_DELAY;
      aEndPlan           := aPositionDetailNew.PDE_FINAL_DELAY;
      -- Initialiser l'historique avec les valeurs actuelles
      aBeginPlan2        := aSupplyRecord.FAN_BEG_PLAN2;
      aBeginPlan3        := aSupplyRecord.FAN_BEG_PLAN3;
      aBeginPlan4        := aSupplyRecord.FAN_BEG_PLAN4;
      aEndPlan2          := aSupplyRecord.FAN_END_PLAN2;
      aEndPlan3          := aSupplyRecord.FAN_END_PLAN3;
      aEndPlan4          := aSupplyRecord.FAN_END_PLAN4;
      -- Déterminer si les dates de PositionDétail ont changés
      aDateChanged       :=
            (aPositionDetailNew.PDE_BASIS_DELAY <> aPositionDetailOld.PDE_BASIS_DELAY)
        and (not(     (aPositionDetailNew.PDE_BASIS_DELAY is null)
                 and (aPositionDetailOld.PDE_BASIS_DELAY is null) ) );

      if not aDateChanged then
        aDateChanged  :=
              (aPositionDetailNew.PDE_FINAL_DELAY <> aPositionDetailOld.PDE_FINAL_DELAY)
          and (not(     (aPositionDetailNew.PDE_FINAL_DELAY is null)
                   and (aPositionDetailOld.PDE_FINAL_DELAY is null) ) );
      end if;

      -- Déterminer l'historique de BeginPlanif
      if aSupplyRecord.FAN_BEG_PLAN2 is null then
        if aDateChanged then
          aBeginPlan2  := aPositionDetailNew.PDE_BASIS_DELAY;
        else
          aBeginPlan2  := null;
        end if;
      end if;

      if aSupplyRecord.FAN_BEG_PLAN2 is not null then
        if aSupplyRecord.FAN_BEG_PLAN3 is null then
          if aDateChanged then
            aBeginPlan3  := aPositionDetailNew.PDE_BASIS_DELAY;
          else
            aBeginPlan3  := null;
          end if;
        end if;
      end if;

      if aSupplyRecord.FAN_BEG_PLAN3 is not null then
        if aDateChanged then
          aBeginPlan4  := aPositionDetailNew.PDE_BASIS_DELAY;
        else
          aBeginPlan4  := null;
        end if;
      end if;

      -- Déterminer l'historique de EndPlanif
      if aSupplyRecord.FAN_END_PLAN2 is null then
        if aDateChanged then
          aEndPlan2  := aPositionDetailNew.PDE_FINAL_DELAY;
          -- Mise à jour Date Appro sur Attributions
          FAL_NETWORK.Attribution_MAJ_DateAppro(aSupplyRecord.FAL_NETWORK_SUPPLY_ID, aEndPlan2);
        else
          aEndPlan2  := null;
        end if;
      end if;

      if aSupplyRecord.FAN_END_PLAN2 is not null then
        if aSupplyRecord.FAN_END_PLAN3 is null then
          if aDateChanged then
            aEndPlan3  := aPositionDetailNew.PDE_FINAL_DELAY;
            -- Mise à jour Date Appro sur Attributions
            FAL_NETWORK.Attribution_MAJ_DateAppro(aSupplyRecord.FAL_NETWORK_SUPPLY_ID, aEndPlan3);
          else
            aEndPlan3  := null;
          end if;
        end if;
      end if;

      if aSupplyRecord.FAN_END_PLAN3 is not null then
        if aDateChanged then
          aEndPlan4  := aPositionDetailNew.PDE_FINAL_DELAY;
          -- Mise à jour Date Appro sur Attributions
          FAL_NETWORK.Attribution_MAJ_DateAppro(aSupplyRecord.FAL_NETWORK_SUPPLY_ID, aEndPlan4);
        end if;
      end if;

      -- Déterminer le facteur de conversion de la position
      aConversionFactor  := GetPositionConversionFactor(aPositionDetailNew.DOC_POSITION_ID);
      -- Déterminer la quantité solde en unité de stockage
      -- Recherche également le nombre de décimal sur le bien pour arrondir supérieure la quantité solde en unité de stockage
      lnNumberOfDecimal  := GCO_I_LIB_FUNCTIONS.GetNumberOfDecimal(aPositionDetailNew.GCO_GOOD_ID);
      aQteSolde          := ACS_FUNCTION.RoundNear(aPositionDetailNew.PDE_BALANCE_QUANTITY * aConversionFactor, 1 / power(10, lnNumberOfDecimal), 1);
      -- Déterminer les caractérisations utilisées dans les réseaux
      GetNetworkCharactFromDetail(aPositionDetailNew
                                , aUseCharID1
                                , aUseCharID2
                                , aUseCharID3
                                , aUseCharID4
                                , aUseCharID5
                                , aValueCarac1
                                , aValueCarac2
                                , aValueCarac3
                                , aValueCarac4
                                , aValueCarac5
                                 );

      -- Update de FAL_NETWORK_SUPPLY
      update FAL_NETWORK_SUPPLY
         set A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , DOC_RECORD_ID = aDocRecordID
           , STM_STOCK_ID = aStockID
           , STM_LOCATION_ID = aLocationID
           , FAN_CHAR_VALUE1 = aValueCarac1
           , FAN_CHAR_VALUE2 = aValueCarac2
           , FAN_CHAR_VALUE3 = aValueCarac3
           , FAN_CHAR_VALUE4 = aValueCarac4
           , FAN_CHAR_VALUE5 = aValueCarac5
           , GCO_CHARACTERIZATION1_ID = aUseCharID1
           , GCO_CHARACTERIZATION2_ID = aUseCharID2
           , GCO_CHARACTERIZATION3_ID = aUseCharID3
           , GCO_CHARACTERIZATION4_ID = aUseCharID4
           , GCO_CHARACTERIZATION5_ID = aUseCharID5
           , FAN_BEG_PLAN = aBeginPlan
           , FAN_END_PLAN = aEndPlan
           , FAN_PLAN_PERIOD = aEndPlan - aBeginPlan
           , FAN_BEG_PLAN2 = aBeginPlan2
           , FAN_BEG_PLAN3 = aBeginPlan3
           , FAN_BEG_PLAN4 = aBeginPlan4
           , FAN_END_PLAN2 = aEndPlan2
           , FAN_END_PLAN3 = aEndPlan3
           , FAN_END_PLAN4 = aEndPlan4
           , FAN_PREV_QTY = aPositionDetailNew.PDE_BASIS_QUANTITY_SU   -- Qte prevue
           , FAN_SCRAP_QTY = aPositionDetailNew.PDE_INTERMEDIATE_QUANTITY_SU   -- Qte Rebut prévue
           , FAN_FULL_QTY = aPositionDetailNew.PDE_FINAL_QUANTITY_SU   -- Qte Totale
           , FAN_BALANCE_QTY = aQteSolde   -- Qte Solde
           , FAN_NETW_QTY = aQteSolde   -- Qte Att Besoin Appro
       where current of GetSupplyRecordForUpdate;
    end if;

    close GetSupplyRecordForUpdate;
  exception
    when others then
      close GetSupplyRecordForUpdate;

      raise;
  end;

  /**
  * procedure Attribution_MAJ_78910
  * Description : Mise à jour des attributions pour les positions
  *               7, 8, 9, 10
  * @lastUpdate
  * @public
  * @param   aDocPosDetailID : Détail position
  */
  procedure Attribution_MAJ_78910(aDocPosDetailID in TTypeID)
  is
    type TNeedRecord is record(
      NeedID   TTypeID
    , NeedDate FAL_NETWORK_NEED.FAN_BEG_PLAN%type
    , NeedQty  FAL_NETWORK_NEED.FAN_NETW_QTY%type
    );

    aNeedRecord TNeedRecord;
  begin
    -- Récupération des infos sur le besoin
    select FAL_NETWORK_NEED_ID
         , FAN_BEG_PLAN
         , FAN_NETW_QTY
      into aNeedRecord
      from FAL_NETWORK_NEED
     where DOC_POSITION_DETAIL_ID = aDocPosDetailID;

    -- Si le besoin a bien été trouvé
    if aNeedRecord.NeedID is not null then
      -- Modification Attribution ...
      update FAL_NETWORK_LINK
         set FLN_SUPPLY_DELAY = aNeedRecord.NeedDate
           , FLN_NEED_DELAY = aNeedRecord.NeedDate
           , FLN_QTY = aNeedRecord.NeedQty
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_NETWORK_NEED_ID = aNeedRecord.NeedID;
    end if;
  exception
    when no_data_found then
      null;
  end;

  /**
  * procedure ReseauApproDOC_MAJ_Date
  * Description : Mise à jour des dates d'un enregistrement dans FAL_NETWORK_SUPPLY
  *               à partir d'une POA donnée
  * @lastUpdate
  * @public
  * @param   aDocPropID : Porposition d'appro logistique
  */
  procedure ReseauApproDOC_MAJ_Date(aDocPropID in TTypeID)
  is
    cursor GetSupplyRecordForDate(aDocPropID in TTypeID)
    is
      select     *
            from FAL_NETWORK_SUPPLY
           where FAL_DOC_PROP_ID = aDocPropID
      for update;

    cursor GetDocPropRecord(aDocPropID in TTypeID)
    is
      select FDP_BASIS_DELAY
           , FDP_FINAL_DELAY
        from FAL_DOC_PROP
       where FAL_DOC_PROP_ID = aDocPropID;

    -- Record de la proposition concernée
    aDocPropConcerne GetDocPropRecord%rowtype;
    -- Record du Appro concerné
    aApproConcerne   GetSupplyRecordForDate%rowtype;
    -- Date debut Planif
    aDebutPlanif     TTypeDate;
    -- Date fin Planif
    aFinPlanif       TTypeDate;
    -- Date debut Planif 2, 3, 4
    aDebutPlanif2    TTypeDate;
    aDebutPlanif3    TTypeDate;
    aDebutPlanif4    TTypeDate;
    -- Date fin Planif 2, 3, 4
    aFinPlanif2      TTypeDate;
    aFinPlanif3      TTypeDate;
    aFinPlanif4      TTypeDate;
  begin
    -- Ouverture du curseur sur la Proposition et renseigner aDocPropConcerne
    open GetDocPropRecord(aDocPropID);

    fetch GetDocPropRecord
     into aDocPropConcerne;

    -- S'assurer qu'il y ai un enregistrement Proposition ...
    if GetDocPropRecord%found then
      -- Ouverture du curseur sur l'appro et renseigner aDocPropConcerne
      open GetSupplyRecordForDate(aDocPropID);

      fetch GetSupplyRecordForDate
       into aApproConcerne;

      -- S'assurer qu'il y ai un enregistrement Appro ...
      if GetSupplyRecordForDate%found then
        -- Initialiser les valeurs
        aDebutPlanif   := aDocPropConcerne.FDP_BASIS_DELAY;
        aFinPlanif     := aDocPropConcerne.FDP_FINAL_DELAY;
        aDebutPlanif2  := aApproConcerne.FAN_BEG_PLAN2;
        aDebutPlanif3  := aApproConcerne.FAN_BEG_PLAN3;
        aDebutPlanif4  := aApproConcerne.FAN_BEG_PLAN4;
        aFinPlanif2    := aApproConcerne.FAN_END_PLAN2;
        aFinPlanif3    := aApproConcerne.FAN_END_PLAN3;
        aFinPlanif4    := aApproConcerne.FAN_END_PLAN4;

        -- Déterminer la date de début plannifiée 2
        if aApproConcerne.FAN_BEG_PLAN2 is null then
          if (    (aApproConcerne.FAN_BEG_PLAN1 <> aDebutPlanif)
              or (aApproConcerne.FAN_END_PLAN1 <> aFinPlanif) ) then
            aDebutPlanif2  := aDebutPlanif;
          else
            aDebutPlanif2  := null;
          end if;
        end if;

        -- Déterminer la date de début plannifiée 3
        if aApproConcerne.FAN_BEG_PLAN2 is not null then
          if aApproConcerne.FAN_BEG_PLAN3 is null then
            if (    (aApproConcerne.FAN_BEG_PLAN2 <> aDebutPlanif)
                or (aApproConcerne.FAN_END_PLAN2 <> aFinPlanif) ) then
              aDebutPlanif3  := aDebutPlanif;
            else
              aDebutPlanif3  := null;
            end if;
          end if;
        end if;

        -- Déterminer la date de début plannifiée 4
        if aApproConcerne.FAN_BEG_PLAN3 is not null then
          if (    (aApproConcerne.FAN_BEG_PLAN3 <> aDebutPlanif)
              or (aApproConcerne.FAN_END_PLAN3 <> aFinPlanif) ) then
            aDebutPlanif4  := aDebutPlanif;
          end if;
        end if;

        -- Déterminer la date de fin plannifiée 2
        if aApproConcerne.FAN_END_PLAN2 is null then
          if (    (aApproConcerne.FAN_BEG_PLAN1 <> aDebutPlanif)
              or (aApproConcerne.FAN_END_PLAN1 <> aFinPlanif) ) then
            aFinPlanif2  := aFinPlanif;
            -- Mise à jour Attribution Date Appro ...
            FAL_NETWORK.Attribution_MAJ_DateAppro(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aFinPlanif);
          else
            aFinPlanif2  := null;
          end if;
        end if;

        -- Déterminer la date de fin plannifiée 3
        if aApproConcerne.FAN_END_PLAN2 is not null then
          if aApproConcerne.FAN_END_PLAN3 is null then
            if (    (aApproConcerne.FAN_BEG_PLAN2 <> aDebutPlanif)
                or (aApproConcerne.FAN_END_PLAN2 <> aFinPlanif) ) then
              aFinPlanif3  := aFinPlanif;
              -- Mise à jour Attribution Date Appro ...
              FAL_NETWORK.Attribution_MAJ_DateAppro(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aFinPlanif);
            else
              aFinPlanif3  := null;
            end if;
          end if;
        end if;

        -- Déterminer la date de fin plannifiée 4
        if aApproConcerne.FAN_END_PLAN3 is not null then
          if (    (aApproConcerne.FAN_BEG_PLAN3 <> aDebutPlanif)
              or (aApproConcerne.FAN_END_PLAN3 <> aFinPlanif) ) then
            aFinPlanif4  := aFinPlanif;
            -- Mise à jour Attribution Date Appro ...
            FAL_NETWORK.Attribution_MAJ_DateAppro(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aFinPlanif);
          end if;
        end if;

        update FAL_NETWORK_SUPPLY
           set A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             , A_DATEMOD = sysdate
             , FAN_BEG_PLAN = aDocPropConcerne.FDP_BASIS_DELAY
             , FAN_END_PLAN = aDocPropConcerne.FDP_FINAL_DELAY
             , FAN_BEG_PLAN2 = aDebutPlanif2
             , FAN_BEG_PLAN3 = aDebutPlanif3
             , FAN_BEG_PLAN4 = aDebutPlanif4
             , FAN_END_PLAN2 = aFinPlanif2
             , FAN_END_PLAN3 = aFinPlanif3
             , FAN_END_PLAN4 = aFinPlanif4
             , FAN_PLAN_PERIOD = aDocPropConcerne.FDP_FINAL_DELAY - aDocPropConcerne.FDP_BASIS_DELAY   -- Duree plannifiee
         where current of GetSupplyRecordForDate;
      end if;

      close GetSupplyRecordForDate;
    end if;

    close GetDocPropRecord;
  end;

  /**
  * procedure CreateReseauApproPropApproLog
  * Description : Création des réseaux appro pour une proposition d'approvisionnement
  *               logistique
  *
  * @lastUpdate
  * @public
  * @param   FalDocPropID : ID de proposition
  * @return  aCreatedSupplyID : ID d'appro réseau créé
  */
  procedure CreateReseauApproPropApproLog(FalDocPropID TTypeID, aCreatedSupplyID out TTypeID)
  is
    cGaugeTitle     DOC_GAUGE_STRUCTURED.C_GAUGE_TITLE%type;
    aGaugeID        FAL_DOC_PROP.DOC_GAUGE_ID%type;
    EnrFAL_DOC_PROP FAL_DOC_PROP%rowtype;
  begin
    select *
      into EnrFAL_DOC_PROP
      from FAL_DOC_PROP
     where FAL_DOC_PROP_ID = FalDocPropID;

    -- Déterminer le nouvel ID Appro ...
    aCreatedSupplyID  := GetNewId;
    -- Récupérer le C_GAUGE_TITLE associée à la proposition ...
    cGaugeTitle       := '';

    if PicIdisNullOfFAL_DOC_PROP(FalDocPropID) then
      select DOC_GAUGE_ID
        into aGaugeID
        from FAL_DOC_PROP
       where FAL_DOC_PROP_ID = FalDocPropID;

      if trim(aGaugeID) is not null then
        select C_GAUGE_TITLE
          into cGaugeTitle
          from DOC_GAUGE_STRUCTURED
         where DOC_GAUGE_ID = aGaugeID;
      end if;
    else
      cGaugeTitle  := PCS.PC_CONFIG.GETCONFIG('FAL_TITLE_PLAN_DIR');
    end if;

    insert into FAL_NETWORK_SUPPLY
                (FAL_NETWORK_SUPPLY_ID
               , FAL_DOC_PROP_ID
               , FAN_DESCRIPTION
               , DOC_GAUGE_ID
               , C_GAUGE_TITLE
               , PAC_THIRD_ID
               , GCO_GOOD_ID
               , DOC_RECORD_ID
               , FAL_PIC_LINE_ID
               , STM_LOCATION_ID
               , STM_STOCK_ID
               , FAN_BEG_PLAN
               , FAN_END_PLAN
               , FAN_PLAN_PERIOD
               , FAN_BEG_PLAN1
               , FAN_END_PLAN1
               , FAN_PREV_QTY
               , FAN_SCRAP_QTY
               , FAN_FULL_QTY
               , FAN_BALANCE_QTY
               , FAN_FREE_QTY
               , FAN_NETW_QTY
               , FAN_STK_QTY
               , GCO_CHARACTERIZATION1_ID
               , GCO_CHARACTERIZATION2_ID
               , GCO_CHARACTERIZATION3_ID
               , GCO_CHARACTERIZATION4_ID
               , GCO_CHARACTERIZATION5_ID
               , FAN_CHAR_VALUE1
               , FAN_CHAR_VALUE2
               , FAN_CHAR_VALUE3
               , FAN_CHAR_VALUE4
               , FAN_CHAR_VALUE5
               , A_DATECRE
               , A_IDCRE
                )
         values (aCreatedSupplyID
               , EnrFAL_DOC_PROP.FAL_DOC_PROP_ID
               , PCS.PC_FUNCTIONS.GetDescodeCode('C_PREFIX_PROP', EnrFAL_DOC_PROP.C_PREFIX_PROP, PCS.PC_I_LIB_SESSION.GetCompLangId)
                 || EnrFAL_DOC_PROP.FDP_NUMBER
               , EnrFAL_DOC_PROP.DOC_GAUGE_ID
               , cGaugeTitle
               , EnrFAL_DOC_PROP.PAC_SUPPLIER_PARTNER_ID
               , EnrFAL_DOC_PROP.GCO_GOOD_ID
               , EnrFAL_DOC_PROP.DOC_RECORD_ID
               , EnrFAL_DOC_PROP.FAL_PIC_LINE_ID
               , EnrFAL_DOC_PROP.STM_STM_LOCATION_ID   -- Appro : Stock de destination ...
               , EnrFAL_DOC_PROP.STM_STM_STOCK_ID
               , EnrFAL_DOC_PROP.FDP_BASIS_DELAY
               , EnrFAL_DOC_PROP.FDP_FINAL_DELAY
               , EnrFAL_DOC_PROP.FDP_FINAL_DELAY - EnrFAL_DOC_PROP.FDP_BASIS_DELAY
               , EnrFAL_DOC_PROP.FDP_BASIS_DELAY
               , EnrFAL_DOC_PROP.FDP_FINAL_DELAY
               , EnrFAL_DOC_PROP.FDP_BASIS_QTY * EnrFAL_DOC_PROP.FDP_CONVERT_FACTOR
               , EnrFAL_DOC_PROP.FDP_INTERMEDIATE_QTY * EnrFAL_DOC_PROP.FDP_CONVERT_FACTOR
               , EnrFAL_DOC_PROP.FDP_FINAL_QTY * EnrFAL_DOC_PROP.FDP_CONVERT_FACTOR
               , EnrFAL_DOC_PROP.FDP_BASIS_QTY * EnrFAL_DOC_PROP.FDP_CONVERT_FACTOR
               , EnrFAL_DOC_PROP.FDP_BASIS_QTY * EnrFAL_DOC_PROP.FDP_CONVERT_FACTOR
               , 0
               , 0
               , EnrFAL_DOC_PROP.GCO_CHARACTERIZATION1_ID
               , EnrFAL_DOC_PROP.GCO_CHARACTERIZATION2_ID
               , EnrFAL_DOC_PROP.GCO_CHARACTERIZATION3_ID
               , EnrFAL_DOC_PROP.GCO_CHARACTERIZATION4_ID
               , EnrFAL_DOC_PROP.GCO_CHARACTERIZATION5_ID
               , EnrFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1
               , EnrFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_2
               , EnrFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_3
               , EnrFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_4
               , EnrFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_5
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end;

  /**
  * procedure CreateReseauBesoinPropApproLog
  * Description : Création des réseaux besoin pour une proposition d'approvisionnement
  *               logistique (POT)
  *
  * @lastUpdate
  * @public
  * @param   FalDocPropID : ID de proposition
  * @return  aCreatedSupplyID : ID d'appro réseau créé
  */
  procedure CreateReseauBesoinPropApproLog(FalDocPropID TTypeID, aCreatedNeedID out TTypeID)
  is
    cGaugeTitle     DOC_GAUGE_STRUCTURED.C_GAUGE_TITLE%type;
    aGaugeID        FAL_DOC_PROP.DOC_GAUGE_ID%type;
    EnrFAL_DOC_PROP FAL_DOC_PROP%rowtype;
  begin
    select *
      into EnrFAL_DOC_PROP
      from FAL_DOC_PROP
     where FAL_DOC_PROP_ID = FalDocPropID;

    -- Déterminer le nouvel ID Appro ...
    aCreatedNeedID  := GetNewId;
    -- Récupérer le C_GAUGE_TITLE associée à la proposition ...
    cGaugeTitle     := '';

    if PicIdisNullOfFAL_DOC_PROP(FalDocPropID) then
      select DOC_GAUGE_ID
        into aGaugeID
        from FAL_DOC_PROP
       where FAL_DOC_PROP_ID = FalDocPropID;

      if trim(aGaugeID) is not null then
        select C_GAUGE_TITLE
          into cGaugeTitle
          from DOC_GAUGE_STRUCTURED
         where DOC_GAUGE_ID = aGaugeID;
      end if;
    else
      cGaugeTitle  := PCS.PC_CONFIG.GETCONFIG('FAL_TITLE_PLAN_DIR');
    end if;

    insert into FAL_NETWORK_NEED
                (FAL_NETWORK_NEED_ID
               , FAL_DOC_PROP_ID
               , FAN_DESCRIPTION
               , DOC_GAUGE_ID
               , C_GAUGE_TITLE
               , PAC_THIRD_ID
               , GCO_GOOD_ID
               , DOC_RECORD_ID
               , FAL_PIC_LINE_ID
               , STM_LOCATION_ID
               , STM_STOCK_ID
               , FAN_BEG_PLAN
               , FAN_END_PLAN
               , FAN_PLAN_PERIOD
               , FAN_BEG_PLAN1
               , FAN_END_PLAN1
               , FAN_PREV_QTY
               , FAN_SCRAP_QTY
               , FAN_FULL_QTY
               , FAN_BALANCE_QTY
               , FAN_FREE_QTY
               , FAN_NETW_QTY
               , FAN_STK_QTY
               , GCO_CHARACTERIZATION1_ID
               , GCO_CHARACTERIZATION2_ID
               , GCO_CHARACTERIZATION3_ID
               , GCO_CHARACTERIZATION4_ID
               , GCO_CHARACTERIZATION5_ID
               , FAN_CHAR_VALUE1
               , FAN_CHAR_VALUE2
               , FAN_CHAR_VALUE3
               , FAN_CHAR_VALUE4
               , FAN_CHAR_VALUE5
               , A_DATECRE
               , A_IDCRE
                )
         values (aCreatedNeedID
               , EnrFAL_DOC_PROP.FAL_DOC_PROP_ID
               , PCS.PC_FUNCTIONS.GetDescodeCode('C_PREFIX_PROP', EnrFAL_DOC_PROP.C_PREFIX_PROP, PCS.PC_I_LIB_SESSION.GetCompLangId)
                 || EnrFAL_DOC_PROP.FDP_NUMBER
               , EnrFAL_DOC_PROP.DOC_GAUGE_ID
               , cGaugeTitle
               , EnrFAL_DOC_PROP.PAC_SUPPLIER_PARTNER_ID
               , EnrFAL_DOC_PROP.GCO_GOOD_ID
               , EnrFAL_DOC_PROP.DOC_RECORD_ID
               , EnrFAL_DOC_PROP.FAL_PIC_LINE_ID
               , EnrFAL_DOC_PROP.STM_LOCATION_ID
               , EnrFAL_DOC_PROP.STM_STOCK_ID
               , EnrFAL_DOC_PROP.FDP_BASIS_DELAY
               , EnrFAL_DOC_PROP.FDP_FINAL_DELAY
               , EnrFAL_DOC_PROP.FDP_FINAL_DELAY - EnrFAL_DOC_PROP.FDP_BASIS_DELAY
               , EnrFAL_DOC_PROP.FDP_BASIS_DELAY
               , EnrFAL_DOC_PROP.FDP_FINAL_DELAY
               , EnrFAL_DOC_PROP.FDP_BASIS_QTY * EnrFAL_DOC_PROP.FDP_CONVERT_FACTOR
               , EnrFAL_DOC_PROP.FDP_INTERMEDIATE_QTY * EnrFAL_DOC_PROP.FDP_CONVERT_FACTOR
               , EnrFAL_DOC_PROP.FDP_FINAL_QTY * EnrFAL_DOC_PROP.FDP_CONVERT_FACTOR
               , EnrFAL_DOC_PROP.FDP_BASIS_QTY * EnrFAL_DOC_PROP.FDP_CONVERT_FACTOR
               , EnrFAL_DOC_PROP.FDP_BASIS_QTY * EnrFAL_DOC_PROP.FDP_CONVERT_FACTOR
               , 0
               , 0
               , EnrFAL_DOC_PROP.GCO_CHARACTERIZATION1_ID
               , EnrFAL_DOC_PROP.GCO_CHARACTERIZATION2_ID
               , EnrFAL_DOC_PROP.GCO_CHARACTERIZATION3_ID
               , EnrFAL_DOC_PROP.GCO_CHARACTERIZATION4_ID
               , EnrFAL_DOC_PROP.GCO_CHARACTERIZATION5_ID
               , EnrFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_1
               , EnrFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_2
               , EnrFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_3
               , EnrFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_4
               , EnrFAL_DOC_PROP.FDP_CHARACTERIZATION_VALUE_5
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end;

  /**
  * procedure CreateReseauApproPropApproFab
  * Description : Création des réseaux appro pour une proposition d'approvisionnement
  *                fabrication
  * @lastUpdate
  * @public
  * @param    FalLotPropID
  * @param    aTOTQteCouple : On passe "aTOTQteCoupl" car il s'agit de pouvoir traiter
  *           les réseaux du détail lot Master. Cf. Analyses des Produits couplés.
  * @return   aCreatedSupplyID : Appro créée
  */
  procedure CreateReseauApproPropApproFab(FalLotPropID TTypeID, aCreatedSupplyID out TTypeID, aTOTQteCouple number)
  is
    EnrFAL_LOT_PROP FAL_LOT_PROP%rowtype;
    aC_GAUGE_TITLE  DOC_GAUGE_STRUCTURED.C_GAUGE_TITLE%type;
  begin
    -- Déterminer le nouvel ID Appro ...
    aCreatedSupplyID  := GetNewId;

    -- Déterminer le C_GAUGE_TITLE
    if PicIdisNullOfFAL_LOT_PROP(FalLotPropID) then
      aC_GAUGE_TITLE  := '13';
    else
      aC_GAUGE_TITLE  := PCS.PC_CONFIG.GETCONFIG('FAL_TITLE_PLAN_DIR');
    end if;

    select *
      into EnrFAL_LOT_PROP
      from FAL_LOT_PROP
     where FAL_LOT_PROP_ID = FalLotPropID;

    insert into FAL_NETWORK_SUPPLY
                (FAL_NETWORK_SUPPLY_ID
               , FAL_LOT_PROP_ID
               , FAN_DESCRIPTION
               , GCO_GOOD_ID
               , DOC_RECORD_ID
               , FAL_PIC_LINE_ID
               , FAN_BEG_PLAN
               , FAN_END_PLAN
               , FAN_PLAN_PERIOD
               , STM_STOCK_ID
               , STM_LOCATION_ID
               , C_GAUGE_TITLE
               , GCO_CHARACTERIZATION1_ID
               , GCO_CHARACTERIZATION2_ID
               , GCO_CHARACTERIZATION3_ID
               , GCO_CHARACTERIZATION4_ID
               , GCO_CHARACTERIZATION5_ID
               , FAN_CHAR_VALUE1
               , FAN_CHAR_VALUE2
               , FAN_CHAR_VALUE3
               , FAN_CHAR_VALUE4
               , FAN_CHAR_VALUE5
               , FAN_PREV_QTY
               , FAN_SCRAP_QTY
               , FAN_FULL_QTY
               , FAN_REALIZE_QTY
               , FAN_EXCEED_QTY
               , FAN_DISCHARGE_QTY
               , FAN_SCRAP_REAL_QTY
               , FAN_RETURN_QTY
               , FAN_BALANCE_QTY
               , FAN_FREE_QTY
               , FAN_STK_QTY
               , FAN_NETW_QTY
               , A_DATECRE
               , A_IDCRE
                )
         values (aCreatedSupplyID
               , EnrFAL_LOT_PROP.FAL_LOT_PROP_ID   -- FAL_LOT_PROP_ID
               , PCS.PC_FUNCTIONS.GetDescodeCode('C_PREFIX_PROP', EnrFAL_LOT_PROP.C_PREFIX_PROP, PCS.PC_I_LIB_SESSION.GetCompLangId) ||
                 EnrFAL_LOT_PROP.LOT_NUMBER   -- FAN_DESCRIPTION
               , EnrFAL_LOT_PROP.GCO_GOOD_ID   -- GCO_GOOD_ID
               , EnrFAL_LOT_PROP.DOC_RECORD_ID   -- DOC_RECORD_ID
               , EnrFAL_LOT_PROP.FAL_PIC_LINE_ID   -- FAL_PIC_LINE_ID
               , EnrFAL_LOT_PROP.LOT_PLAN_BEGIN_DTE   -- FAN_BEG_PLAN
               , EnrFAL_LOT_PROP.LOT_PLAN_END_DTE   -- FAN_END_PLAN
               , EnrFAL_LOT_PROP.LOT_PLAN_LEAD_TIME   -- FAN_PLAN_PERIOD
               , EnrFAL_LOT_PROP.STM_STOCK_ID
               , EnrFAL_LOT_PROP.STM_LOCATION_ID
               , aC_GAUGE_TITLE
               , EnrFAL_LOT_PROP.GCO_CHARACTERIZATION1_ID
               , EnrFAL_LOT_PROP.GCO_CHARACTERIZATION2_ID
               , EnrFAL_LOT_PROP.GCO_CHARACTERIZATION3_ID
               , EnrFAL_LOT_PROP.GCO_CHARACTERIZATION4_ID
               , EnrFAL_LOT_PROP.GCO_CHARACTERIZATION5_ID
               , EnrFAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_1
               , EnrFAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_2
               , EnrFAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_3
               , EnrFAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_4
               , EnrFAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_5
               , EnrFAL_LOT_PROP.LOT_ASKED_QTY - nvl(aTOTQteCouple, 0)   -- FAN_PREV_QTY
               , EnrFAL_LOT_PROP.LOT_REJECT_PLAN_QTY   -- FAN_SCRAP_QTY
               , EnrFAL_LOT_PROP.LOT_TOTAL_QTY - nvl(aTOTQteCouple, 0)   -- FAN_FULL_QTY
               , 0   -- FAN_REALIZE_QTY
               , 0   -- FAN_EXCEED_QTY
               , 0   -- FAN_DISCHARGE_QTY
               , 0   -- FAN_SCRAP_REAL_QTY
               , 0   -- FAN_RETURN_STY
               , EnrFAL_LOT_PROP.LOT_ASKED_QTY - nvl(aTOTQteCouple, 0)   -- FAN_BALANCE_QTY
               , EnrFAL_LOT_PROP.LOT_ASKED_QTY - nvl(aTOTQteCouple, 0)   -- FAN_FREE_QTY
               , 0   -- FAN_STK_QTY
               , 0   -- FAN_NETW_QTY
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end;

  /**
  * procedure CreateReseauApproPropApproFabC
  * Description : Création des réseaux appro pour une proposition d'approvisionnement
  *                fabrication avec produit couplés
  * @lastUpdate
  * @public
  * @param    FalLotPropID
  * @param    aQteCouple : Qté bien couple
  * @param    aGCO_GOOD_ID : Bien couple
  * @return   aCreatedSupplyID : Appro créée
  */
  procedure CreateReseauApproPropApproFabC(FalLotPropID TTypeID, aCreatedSupplyID out TTypeID, aQteCouple number, aGCO_GOOD_ID TTypeID)
  is
    EnrFAL_LOT_PROP FAL_LOT_PROP%rowtype;
    aC_GAUGE_TITLE  DOC_GAUGE_STRUCTURED.C_GAUGE_TITLE%type;
  begin
    -- Déterminer le nouvel ID Appro ...
    aCreatedSupplyID  := GetNewId;

    -- Déterminer le C_GAUGE_TITLE
    if PicIdisNullOfFAL_LOT_PROP(FalLotPropID) then
      aC_GAUGE_TITLE  := '13';
    else
      aC_GAUGE_TITLE  := PCS.PC_CONFIG.GETCONFIG('FAL_TITLE_PLAN_DIR');
    end if;

    select *
      into EnrFAL_LOT_PROP
      from FAL_LOT_PROP
     where FAL_LOT_PROP_ID = FalLotPropID;

    insert into FAL_NETWORK_SUPPLY
                (FAL_NETWORK_SUPPLY_ID
               , FAL_LOT_PROP_ID
               , FAN_DESCRIPTION
               , GCO_GOOD_ID
               , DOC_RECORD_ID
               , FAL_PIC_LINE_ID
               , FAN_BEG_PLAN
               , FAN_END_PLAN
               , FAN_PLAN_PERIOD
               , STM_STOCK_ID
               , STM_LOCATION_ID
               , C_GAUGE_TITLE
               , GCO_CHARACTERIZATION1_ID
               , GCO_CHARACTERIZATION2_ID
               , GCO_CHARACTERIZATION3_ID
               , GCO_CHARACTERIZATION4_ID
               , GCO_CHARACTERIZATION5_ID
               , FAN_CHAR_VALUE1
               , FAN_CHAR_VALUE2
               , FAN_CHAR_VALUE3
               , FAN_CHAR_VALUE4
               , FAN_CHAR_VALUE5
               , FAN_PREV_QTY
               , FAN_SCRAP_QTY
               , FAN_FULL_QTY
               , FAN_REALIZE_QTY
               , FAN_EXCEED_QTY
               , FAN_DISCHARGE_QTY
               , FAN_SCRAP_REAL_QTY
               , FAN_RETURN_QTY
               , FAN_BALANCE_QTY
               , FAN_FREE_QTY
               , FAN_STK_QTY
               , FAN_NETW_QTY
               , A_DATECRE
               , A_IDCRE
                )
         values (aCreatedSupplyID   -- FAL_NETWORK_SUPPLY_ID
               , EnrFAL_LOT_PROP.FAL_LOT_PROP_ID
               , PCS.PC_FUNCTIONS.GetDescodeCode('C_PREFIX_PROP', EnrFAL_LOT_PROP.C_PREFIX_PROP, PCS.PC_I_LIB_SESSION.GetCompLangId) ||
                 EnrFAL_LOT_PROP.LOT_NUMBER   -- FAN_DESCRIPTION
               , aGCO_GOOD_ID
               , EnrFAL_LOT_PROP.DOC_RECORD_ID
               , EnrFAL_LOT_PROP.FAL_PIC_LINE_ID
               , EnrFAL_LOT_PROP.LOT_PLAN_BEGIN_DTE   -- FAN_BEG_PLAN
               , EnrFAL_LOT_PROP.LOT_PLAN_END_DTE   -- FAN_END_PLAN
               , EnrFAL_LOT_PROP.LOT_PLAN_LEAD_TIME   -- FAN_PLAN_PERIOD
               , EnrFAL_LOT_PROP.STM_STOCK_ID
               , EnrFAL_LOT_PROP.STM_LOCATION_ID
               , aC_GAUGE_TITLE
               , null   -- GCO_CHARACTERIZATION1_ID
               , null   -- GCO_CHARACTERIZATION2_ID
               , EnrFAL_LOT_PROP.GCO_CHARACTERIZATION3_ID
               , EnrFAL_LOT_PROP.GCO_CHARACTERIZATION4_ID
               , EnrFAL_LOT_PROP.GCO_CHARACTERIZATION5_ID
               , EnrFAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_1
               , EnrFAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_2
               , EnrFAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_3
               , EnrFAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_4
               , EnrFAL_LOT_PROP.FAD_CHARACTERIZATION_VALUE_5
               , aQteCouple   -- FAN_PREV_QTY
               , 0   -- FAN_SCRAP_QTY
               , aQteCouple   -- FAN_FULL_QTY
               , 0   -- FAN_REALIZE_QTY
               , 0   -- FAN_EXCEED_QTY
               , 0   -- FAN_DISCHARGE_QTY
               , 0   -- FAN_SCRAP_REAL_QTY
               , 0   -- FAN_RETURN_STY
               , aQteCouple   -- FAN_BALANCE_QTY
               , aQteCouple   -- FAN_FREE_QTY
               , 0   -- FAN_STK_QTY
               , 0   -- FAN_NETW_QTY
               , sysdate   -- A_DATECRE
               , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                );
  end;

  /**
  * procedure CreationReseauxBesoinPropComp
  * Description : Création réseaux besoin pour un composant d'une proposition de fabrication
  *
  * @lastUpdate
  * @public
  * @param    aFAL_LOT_PROP_ID : proposition
  * @param    aFAL_LOT_MAT_LINK_PROP_ID : Composant de proposition
  */
  procedure CreationReseauxBesoinPropComp(
    aFAL_LOT_PROP_ID          FAL_LOT_PROP.FAl_LOT_PROP_ID%type
  , aFAL_LOT_MAT_LINK_PROP_ID FAL_LOT_MAT_LINK_PROP.FAL_LOT_MAT_LINK_PROP_ID%type
  )
  is
    aC_GAUGE_TITLE           DOC_GAUGE_STRUCTURED.C_GAUGE_TITLE%type;
    aC_PREFIX_PROP           FAL_LOT_PROP.C_PREFIX_PROP%type;
    aLOT_NUMBER              FAL_LOT_PROP.LOT_NUMBER%type;
    aFAl_PIC_LINE_ID         FAL_LOT_PROP.FAl_PIC_LINE_ID%type;

    cursor Composant
    is
      select FAL_LOT_MAT_LINK_PROP_ID
           , GCo_GOOD_ID
           , DOC_RECORD_ID
           , LOM_NEED_DATE
           , STM_STOCK_ID
           , STm_LOCATION_ID
           , LOM_NEED_QTY
        from FAL_LOT_MAT_LINK_PROP
       where FAL_LOT_MAT_LINK_PROP_ID = aFAL_LOT_MAT_LINK_PROP_ID;

    EnrFAL_LOT_MAT_LINK_PROP Composant%rowtype;
    -- StockID défini pour l'insertion
    aStockID                 TTypeID;
    -- LocationID défini pour l'insertion
    aLocationID              TTypeID;
    idDefaultStockID         TTypeID;
    idDefaultLocationID      TTypeID;
  begin
    -- Détermine le stock et l'emplacement par défaut
    idDefaultStockID  := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_NETWORK');

    if idDefaultStockID is null then
      idDefaultLocationID  := null;
    else
      idDefaultLocationID  := FAL_TOOLS.GetConfig_LocationID('PPS_DefltLOCATION_NETWORK', idDefaultStockID);
    end if;

    open Composant;

    fetch Composant
     into EnrFAL_LOT_MAT_LINK_PROP;

    if Composant%found then
      -- Déterminer le C_GAUGE_TITLE
      if PicIdisNullOfFAL_LOT_PROP(aFAL_LOT_PROP_ID) then
        aC_GAUGE_TITLE  := '13';
      else
        aC_GAUGE_TITLE  := PCS.PC_CONFIG.GETCONFIG('FAL_TITLE_PLAN_DIR');
      end if;

      -- Récupérer le C_PREFIX_PROP, LOT_NUMBER, FAL_PIC_LINE_ID
      select C_PREFIX_PROP
           , LOT_NUMBER
           , FAl_PIC_LINE_ID
        into aC_PREFIX_PROP
           , aLOT_NUMBER
           , aFAl_PIC_LINE_ID
        from FAL_LOT_PROP
       where FAL_LOT_PROP_ID = aFAL_LOT_PROP_ID;

      -- Déterminer le STOCK et l'EMPLACEMENT à stocker dans les réseaux
      aStockID     := EnrFAL_LOT_MAT_LINK_PROP.STM_STOCK_ID;
      aLocationID  := EnrFAL_LOT_MAT_LINK_PROP.STM_LOCATION_ID;
      FAL_NETWORK.SetDefaultStockAndLocation(aStockID, aLocationID, idDefaultStockID, idDefaultLocationID);

      insert into FAL_NETWORK_NEED
                  (FAL_NETWORK_NEED_ID
                 , FAL_LOT_PROP_ID
                 , FAL_LOT_MAT_LINK_PROP_ID
                 , FAN_DESCRIPTION
                 , GCO_GOOD_ID
                 , DOC_RECORD_ID
                 , FAL_PIC_LINE_ID
                 , FAN_BEG_PLAN
                 , FAN_END_PLAN
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , C_GAUGE_TITLE
                 , FAN_BALANCE_QTY
                 , FAN_FREE_QTY
                 , FAN_STK_QTY
                 , FAN_NETW_QTY
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , aFAL_LOT_PROP_ID
                 , EnrFAL_LOT_MAT_LINK_PROP.FAL_LOT_MAT_LINK_PROP_ID
                 , PCS.PC_FUNCTIONS.GetDescodeCode('C_PREFIX_PROP', aC_PREFIX_PROP, PCS.PC_I_LIB_SESSION.GetCompLangId) || aLOT_NUMBER   -- FAN_DESCRIPTION
                 , EnrFAL_LOT_MAT_LINK_PROP.GCO_GOOD_ID
                 , EnrFAL_LOT_MAT_LINK_PROP.DOC_RECORD_ID
                 , aFAL_PIC_LINE_ID
                 , EnrFAL_LOT_MAT_LINK_PROP.LOM_NEED_DATE   -- FAN_BEG_PLAN
                 , EnrFAL_LOT_MAT_LINK_PROP.LOM_NEED_DATE   -- FAN_END_PLAN
                 , aStockID
                 , aLocationID
                 , aC_GAUGE_TITLE
                 , EnrFAL_LOT_MAT_LINK_PROP.LOM_NEED_QTY   -- FAN_BALANCE_QTY
                 , EnrFAL_LOT_MAT_LINK_PROP.LOM_NEED_QTY   -- FAN_FREE_QTY
                 , 0   -- FAN_STK_QTY
                 , 0   -- FAN_NETW_QTY
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end if;

    close Composant;
  end;

  /**
  * procedure CreateReseauBesoinPropApproFab
  * Description : Création réseaux besoin. pour proposition appro. fabrication
  *
  * @lastUpdate
  * @public
  * @param    aFAL_LOT_PROP_ID : proposition
  */
  procedure CreateReseaubesoinPropApproFab(FalLotPropID TTypeID)
  is
    cursor CFAL_LOT_MAT_LINK_PROP
    is
      select FAL_LOT_MAT_LINK_PROP_ID
           , GCO_GOOD_ID
           , DOC_RECORD_ID
           , LOM_NEED_DATE
           , STM_STOCK_ID
           , STM_LOCATION_ID
           , LOM_NEED_QTY
        from FAL_LOT_MAT_LINK_PROP
       where FAL_LOT_PROP_ID = FalLotPropID
         and C_KIND_COM in('1', '3')   -- N'est pas un dérivé, lien texte, ou fournit par un sous traitant
         and LOM_NEED_QTY > 0;

    type TTAB_LOTPROP_COMP is table of CFAL_LOT_MAT_LINK_PROP%rowtype;

    LOT_PROP_COMP_TAB   TTAB_LOTPROP_COMP;
    i                   integer;
    idDefaultStockID    TTypeID;
    idDefaultLocationID TTypeID;
    aC_GAUGE_TITLE      DOC_GAUGE_STRUCTURED.C_GAUGE_TITLE%type;
    aC_PREFIX_PROP      FAL_LOT_PROP.C_PREFIX_PROP%type;
    aLOT_NUMBER         FAL_LOT_PROP.LOT_NUMBER%type;
    aFAl_PIC_LINE_ID    FAL_LOT_PROP.FAl_PIC_LINE_ID%type;
    aFAL_PIC_ID         number;
    -- StockID défini pour l'insertion
    aStockID            TTypeID;
    -- LocationID défini pour l'insertion
    aLocationID         TTypeID;
  begin
    open CFAL_LOT_MAT_LINK_PROP;

    fetch CFAL_LOT_MAT_LINK_PROP
    bulk collect into LOT_PROP_COMP_TAB;

    close CFAL_LOT_MAT_LINK_PROP;

    if LOT_PROP_COMP_TAB.first is not null then
      -- Détermine le stock et l'emplacement par défaut
      idDefaultStockID  := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_NETWORK');

      if idDefaultStockID is null then
        idDefaultLocationID  := null;
      else
        idDefaultLocationID  := FAL_TOOLS.GetConfig_LocationID('PPS_DefltLOCATION_NETWORK', idDefaultStockID);
      end if;

      -- Récupérer le C_PREFIX_PROP, LOT_NUMBER, FAL_PIC_LINE_ID
      select C_PREFIX_PROP
           , LOT_NUMBER
           , FAL_PIC_LINE_ID
           , FAL_PIC_ID
        into aC_PREFIX_PROP
           , aLOT_NUMBER
           , aFAL_PIC_LINE_ID
           , aFAL_PIC_ID
        from FAL_LOT_PROP
       where FAL_LOT_PROP_ID = FalLotPropID;

      if aFAL_PIC_ID is null then
        aC_GAUGE_TITLE  := '13';
      else
        aC_GAUGE_TITLE  := PCS.PC_CONFIG.GETCONFIG('FAL_TITLE_PLAN_DIR');
      end if;

      -- Création reseaux
      for i in LOT_PROP_COMP_TAB.first .. LOT_PROP_COMP_TAB.last loop
        -- Déterminer le STOCK et l'EMPLACEMENT à stocker dans les réseaux
        aStockID     := LOT_PROP_COMP_TAB(i).STM_STOCK_ID;
        aLocationID  := LOT_PROP_COMP_TAB(i).STM_LOCATION_ID;
        FAL_NETWORK.SetDefaultStockAndLocation(aStockID, aLocationID, idDefaultStockID, idDefaultLocationID);

        insert into FAL_NETWORK_NEED
                    (FAL_NETWORK_NEED_ID
                   , FAL_LOT_PROP_ID
                   , FAL_LOT_MAT_LINK_PROP_ID
                   , FAN_DESCRIPTION
                   , GCO_GOOD_ID
                   , DOC_RECORD_ID
                   , FAL_PIC_LINE_ID
                   , FAN_BEG_PLAN
                   , FAN_END_PLAN
                   , STM_STOCK_ID
                   , STM_LOCATION_ID
                   , C_GAUGE_TITLE
                   , FAN_BALANCE_QTY
                   , FAN_FREE_QTY
                   , FAN_STK_QTY
                   , FAN_NETW_QTY
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (GetNewId
                   , FalLotPropId
                   , LOT_PROP_COMP_TAB(i).FAL_LOT_MAT_LINK_PROP_ID
                   , PCS.PC_FUNCTIONS.GetDescodeCode('C_PREFIX_PROP', aC_PREFIX_PROP, PCS.PC_I_LIB_SESSION.GetCompLangId) || aLOT_NUMBER   -- FAN_DESCRIPTION
                   , LOT_PROP_COMP_TAB(i).GCO_GOOD_ID
                   , LOT_PROP_COMP_TAB(i).DOC_RECORD_ID
                   , aFAL_PIC_LINE_ID
                   , LOT_PROP_COMP_TAB(i).LOM_NEED_DATE   -- FAN_BEG_PLAN
                   , LOT_PROP_COMP_TAB(i).LOM_NEED_DATE   -- FAN_END_PLAN
                   , aStockID
                   , aLocationID
                   , aC_GAUGE_TITLE
                   , LOT_PROP_COMP_TAB(i).LOM_NEED_QTY   -- FAN_BALANCE_QTY
                   , LOT_PROP_COMP_TAB(i).LOM_NEED_QTY   -- FAN_FREE_QTY
                   , 0   -- FAN_STK_QTY
                   , 0   -- FAN_NETW_QTY
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );
      end loop;
    end if;
  end;

  /**
  * procedure ReseauMAJ_DOC_NUMBER
  * Description : Mise à jour des appros/besoins logistiques lors d'un changement
  *               du n° de document.
  *
  * @lastUpdate
  * @public
  * @param    aDocumentID : ID du document dont le n° a changé.
  * @param    aDmtNumber : Le nouveau n° de document (passé en param parce que
  *                          cette méthode est appelée dans un trigger sur doc_document)
  */
  procedure ReseauMAJ_DOC_NUMBER(aDocumentID DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aDmtNumber DOC_DOCUMENT.DMT_NUMBER%type)
  is
  begin
    -- Balayer la liste des positions du document pour màj le n° de document
    for tplPos in (select   POS.DOC_POSITION_ID
                          , POS.POS_NUMBER
                       from DOC_POSITION POS
                      where POS.DOC_DOCUMENT_ID = aDocumentID
                   order by POS.POS_NUMBER) loop
      update FAL_NETWORK_SUPPLY
         set FAN_DESCRIPTION = aDmtNumber || ' / ' || tplPos.POS_NUMBER
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_POSITION_ID = tplPos.DOC_POSITION_ID;

      update FAL_NETWORK_NEED
         set FAN_DESCRIPTION = aDmtNumber || ' / ' || tplPos.POS_NUMBER
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_POSITION_ID = tplPos.DOC_POSITION_ID;
    end loop;
  end ReseauMAJ_DOC_NUMBER;

  /**
  * procedure ReseauBesoinPropositionMAJ_DRA
  * Description : Mise à jour des besoins logistiques pour les DRA (demandes de
  *               ré-approvisionnement).
  *
  * @lastUpdate
  * @public
  * @param    aFalDocPropNew : nouvelles values d'une eregistrement de proposition logistique.
  * @param    aFalDocPropOld : anciennes values d'une eregistrement de proposition logistique.
  */
  procedure ReseauBesoinPropositionMAJ_DRA(aFalDocPropNew FAL_DOC_PROP%rowtype, aFalDocPropOld FAL_DOC_PROP%rowtype)
  is
  begin
    null;
  end;

  /**
  * procedure ReseauBesoinPropositionMAJ_POA(
  * Description : Mise à jour des besoins logistiques pour les propositions
  *               d'approvisionnement logistique.
  *
  * @lastUpdate
  * @public
  * @param    aFalDocPropNew : nouvelles values d'une eregistrement de proposition logistique.
  * @param    aFalDocPropOld : anciennes values d'une eregistrement de proposition logistique.
  */
  procedure ReseauBesoinPropositionMAJ_POA(aFalDocPropNew FAL_DOC_PROP%rowtype, aFalDocPropOld FAL_DOC_PROP%rowtype)
  is
    EnrFAL_NETWORK_NEED    FAL_NETWORK_NEED%rowtype;
    aDOC_RECORD_ID         TTypeID;
    aSTM_STOCK_ID          TTypeID;
    aSTM_LOCATION_ID       TTypeID;
    aFDP_CONVERT_FACTOR    FAL_DOC_PROP.FDP_CONVERT_FACTOR%type;
    aBeginPlan             TTypeDate;
    aEndPlan               TTypeDate;
    aBeginPlan2            TTypeDate;
    aBeginPlan3            TTypeDate;
    aBeginPlan4            TTypeDate;
    aEndPlan2              TTypeDate;
    aEndPlan3              TTypeDate;
    aEndPlan4              TTypeDate;
    aQteSolde              FAL_NETWORK_NEED.FAN_BALANCE_QTY%type;
    aQteLibre              FAL_NETWORK_NEED.FAN_FREE_QTY%type;
    aQteAttStock           FAL_NETWORK_NEED.FAN_STK_QTY%type;
    aQteAttBesoin          FAL_NETWORK_NEED.FAN_NETW_QTY%type;
    aDateChanged           boolean;
    aPAC_REPRESENTATIVE_ID TTypeID;
    aValueCarac1           DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac2           DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac3           DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac4           DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac5           DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aUseCharID1            number;
    aUseCharID2            number;
    aUseCharID3            number;
    aUseCharID4            number;
    aUseCharID5            number;

    -- Lecture et lock d'un enregistrement réseau besoin
    cursor CNeed
    is
      select     *
            from FAL_NETWORK_NEED
           where FAL_DOC_PROP_ID = aFalDocPropNew.FAL_DOC_PROP_ID
      for update;
  begin
    open CNeed;

    fetch CNeed
     into EnrFAL_NETWORK_NEED;

    if CNeed%found then
      -- Déterminer le Dossier ID
      aDOC_RECORD_ID       := aFalDocPropNew.DOC_RECORD_ID;

      -- Déterminer le Stock et l'emplacement ID
      if aFalDocPropNew.STM_LOCATION_ID is null then
        -- Retrouver les stock et emplacement par défaut associés aux configuration PPS_Deflt..._NETWORK
        aSTM_STOCK_ID  := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_NETWORK');

        if aSTM_STOCK_ID is null then
          aSTM_LOCATION_ID  := null;
        else
          aSTM_LOCATION_ID  := FAL_TOOLS.GetConfig_LocationID('PPS_DefltLOCATION_NETWORK', aSTM_STOCK_ID);
        end if;
      else
        -- Récupérer le Stock associé à l'emplacement du détail position
        aSTM_LOCATION_ID  := aFalDocPropNew.STM_LOCATION_ID;
        aSTM_STOCK_ID     := GetStockIDFromLocation(aSTM_LOCATION_ID);
      end if;

      -- Déterminer Begin et End Planif
      aBeginPlan           := aFalDocPropNew.FDP_BASIS_DELAY;
      aEndPlan             := aFalDocPropNew.FDP_FINAL_DELAY;
      -- Initialiser l'historique avec les valeurs actuelles
      aBeginPlan2          := EnrFAL_NETWORK_NEED.FAN_BEG_PLAN2;
      aBeginPlan3          := EnrFAL_NETWORK_NEED.FAN_BEG_PLAN3;
      aBeginPlan4          := EnrFAL_NETWORK_NEED.FAN_BEG_PLAN4;
      aEndPlan2            := EnrFAL_NETWORK_NEED.FAN_END_PLAN2;
      aEndPlan3            := EnrFAL_NETWORK_NEED.FAN_END_PLAN3;
      aEndPlan4            := EnrFAL_NETWORK_NEED.FAN_END_PLAN4;
      -- Déterminer si les dates de PositionDétail ont changés
      aDateChanged         :=
            (aFalDocPropNew.FDP_BASIS_DELAY <> aFalDocPropOld.FDP_BASIS_DELAY)
        and (not(     (aFalDocPropNew.FDP_BASIS_DELAY is null)
                 and (aFalDocPropOld.FDP_BASIS_DELAY is null) ) );

      if not aDateChanged then
        aDateChanged  :=
              (aFalDocPropNew.FDP_FINAL_DELAY <> aFalDocPropOld.FDP_FINAL_DELAY)
          and (not(     (aFalDocPropNew.FDP_FINAL_DELAY is null)
                   and (aFalDocPropOld.FDP_FINAL_DELAY is null) ) );
      end if;

      -- Déterminer l'historique de BeginPlanif
      if EnrFAL_NETWORK_NEED.FAN_BEG_PLAN2 is null then
        if aDateChanged then
          aBeginPlan2  := aFalDocPropNew.FDP_BASIS_DELAY;
          -- Mise à jour Date Besoin sur Attributions
          FAL_NETWORK.Attribution_MAJ_DateBesoin(EnrFAL_NETWORK_NEED.FAL_NETWORK_NEED_ID, aBeginPlan2);
        else
          aBeginPlan2  := null;
        end if;
      end if;

      if EnrFAL_NETWORK_NEED.FAN_BEG_PLAN2 is not null then
        if EnrFAL_NETWORK_NEED.FAN_BEG_PLAN3 is null then
          if aDateChanged then
            aBeginPlan3  := aFalDocPropNew.FDP_BASIS_DELAY;
            -- Mise à jour Date Besoin sur Attributions
            FAL_NETWORK.Attribution_MAJ_DateBesoin(EnrFAL_NETWORK_NEED.FAL_NETWORK_NEED_ID, aBeginPlan3);
          else
            aBeginPlan3  := null;
          end if;
        end if;
      end if;

      if EnrFAL_NETWORK_NEED.FAN_BEG_PLAN3 is not null then
        if aDateChanged then
          aBeginPlan4  := aFalDocPropNew.FDP_BASIS_DELAY;
          -- Mise à jour Date Besoin sur Attributions
          FAL_NETWORK.Attribution_MAJ_DateBesoin(EnrFAL_NETWORK_NEED.FAL_NETWORK_NEED_ID, aBeginPlan4);
        else
          aBeginPlan4  := null;
        end if;
      end if;

      -- Déterminer l'historique de EndPlanif
      if EnrFAL_NETWORK_NEED.FAN_END_PLAN2 is null then
        if aDateChanged then
          aEndPlan2  := aFalDocPropNew.FDP_FINAL_DELAY;
        else
          aEndPlan2  := null;
        end if;
      end if;

      if EnrFAL_NETWORK_NEED.FAN_END_PLAN2 is not null then
        if EnrFAL_NETWORK_NEED.FAN_END_PLAN3 is null then
          if aDateChanged then
            aEndPlan3  := aFalDocPropNew.FDP_FINAL_DELAY;
          else
            aEndPlan3  := null;
          end if;
        end if;
      end if;

      if EnrFAL_NETWORK_NEED.FAN_END_PLAN3 is not null then
        if aDateChanged then
          aEndPlan4  := aFalDocPropNew.FDP_FINAL_DELAY;
        end if;
      end if;

      -- Déterminer le facteur de conversion de la position
      aFDP_CONVERT_FACTOR  := aFalDocPropNew.FDP_CONVERT_FACTOR;
      -- Déterminer la quantité solde
      aQteSolde            := aFDP_CONVERT_FACTOR * aFalDocPropNew.FDP_BASIS_QTY;
      -- Déterminer la quantité libre
      aQteLibre            := EnrFAL_NETWORK_NEED.FAN_FREE_QTY;

      if aFalDocPropOld.FDP_BASIS_QTY > aFalDocPropNew.FDP_BASIS_QTY then
        if (EnrFAL_NETWORK_NEED.FAN_NETW_QTY + EnrFAL_NETWORK_NEED.FAN_STK_QTY) < aQteSolde then
          aQteLibre  := aQteSolde - EnrFAL_NETWORK_NEED.FAN_NETW_QTY - EnrFAL_NETWORK_NEED.FAN_STK_QTY;
        else
          aQteLibre  := 0;
        end if;
      elsif aFalDocPropOld.FDP_BASIS_QTY = aFalDocPropNew.FDP_BASIS_QTY then
        null;
      elsif aFalDocPropOld.FDP_BASIS_QTY < aFalDocPropNew.FDP_BASIS_QTY then
        aQteLibre  := aQteSolde - EnrFAL_NETWORK_NEED.FAN_NETW_QTY - EnrFAL_NETWORK_NEED.FAN_STK_QTY;
      end if;

      -- Déterminer la quantité attribuée sur Stock
      aQteAttStock         := EnrFAL_NETWORK_NEED.FAN_STK_QTY;

      if aFalDocPropOld.FDP_BASIS_QTY > aFalDocPropNew.FDP_BASIS_QTY then
        if (EnrFAL_NETWORK_NEED.FAN_NETW_QTY + EnrFAL_NETWORK_NEED.FAN_STK_QTY) >= aQteSolde then
          if (EnrFAL_NETWORK_NEED.FAN_NETW_QTY) >= aQteSolde then
            aQteAttStock  := 0;
            -- Suppression Attributions Besoin-Stock
            FAL_NETWORK.Attribution_Suppr_BesoinStock(EnrFAL_NETWORK_NEED.FAL_NETWORK_NEED_ID);
          else
            aQteAttStock  := aQteSolde - EnrFAL_NETWORK_NEED.FAN_NETW_QTY;
            -- Mise à jour Attributions Besoin-Stock
            FAL_NETWORK.Attribution_MAJ_BesoinStock(EnrFAL_NETWORK_NEED.FAL_NETWORK_NEED_ID, EnrFAL_NETWORK_NEED.FAN_STK_QTY, aQteAttStock, null);
          end if;
        end if;
      elsif aFalDocPropOld.FDP_BASIS_QTY = aFalDocPropNew.FDP_BASIS_QTY then
        null;
      end if;

      -- Déterminer la quantité attribuée sur besoin
      aQteAttBesoin        := EnrFAL_NETWORK_NEED.FAN_NETW_QTY;

      if aFalDocPropOld.FDP_BASIS_QTY > aFalDocPropNew.FDP_BASIS_QTY then
        if (EnrFAL_NETWORK_NEED.FAN_NETW_QTY + EnrFAL_NETWORK_NEED.FAN_STK_QTY) >= aQteSolde then
          if (EnrFAL_NETWORK_NEED.FAN_NETW_QTY) >= aQteSolde then
            aQteAttBesoin  := aQteSolde;
            -- Mise à jour Attributions Besoin-Appro
            FAL_NETWORK.Attribution_MAJ_BesoinAppro(EnrFAL_NETWORK_NEED.FAL_NETWORK_NEED_ID, EnrFAL_NETWORK_NEED.FAN_NETW_QTY, aQteAttBesoin);
          end if;
        end if;
      elsif aFalDocPropOld.FDP_BASIS_QTY = aFalDocPropNew.FDP_BASIS_QTY then
        null;
      end if;

      GetNetworkCharactFromPOA(aFalDocPropNew
                             , aUseCharID1
                             , aUseCharID2
                             , aUseCharID3
                             , aUseCharID4
                             , aUseCharID5
                             , aValueCarac1
                             , aValueCarac2
                             , aValueCarac3
                             , aValueCarac4
                             , aValueCarac5
                              );

      -- Update de FAL_NETWORK_NEED
      update FAL_NETWORK_NEED
         set A_DATEMOD = sysdate   -- Date de modification
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni   -- User modification
           , DOC_RECORD_ID = aDOC_RECORD_ID   -- Dossier
           , STM_STOCK_ID = aSTM_STOCK_ID   -- Stock
           , STM_LOCATION_ID = aSTM_LOCATION_ID   -- Emplacement de stock
           , FAN_CHAR_VALUE1 = aValueCarac1   -- Valeur de caractérisation 1
           , FAN_CHAR_VALUE2 = aValueCarac2   -- Valeur de caractérisation 2
           , FAN_CHAR_VALUE3 = aValueCarac3   -- Valeur de caractérisation 3
           , FAN_CHAR_VALUE4 = aValueCarac4   -- Valeur de caractérisation 4
           , FAN_CHAR_VALUE5 = aValueCarac5   -- Valeur de caractérisation 5
           , GCO_CHARACTERIZATION1_ID = aUseCharID1
           , GCO_CHARACTERIZATION2_ID = aUseCharID2
           , GCO_CHARACTERIZATION3_ID = aUseCharID3
           , GCO_CHARACTERIZATION4_ID = aUseCharID4
           , GCO_CHARACTERIZATION5_ID = aUseCharID5
           , FAN_BEG_PLAN = aBeginPlan   -- Debut Planif
           , FAN_END_PLAN = aEndPlan   -- Fin Planif
           , FAN_PLAN_PERIOD = aEndPlan - aBeginPlan   -- Duree plannifiee
           , FAN_BEG_PLAN2 = aBeginPlan2   -- Debut Planif 2
           , FAN_BEG_PLAN3 = aBeginPlan3   -- Debut Planif 3
           , FAN_BEG_PLAN4 = aBeginPlan4   -- Debut Planif 4
           , FAN_END_PLAN2 = aEndPlan2   -- Fin Planif 2
           , FAN_END_PLAN3 = aEndPlan3   -- Fin Planif 3
           , FAN_END_PLAN4 = aEndPlan4   -- Fin Planif 4
           , FAN_PREV_QTY = aFDP_CONVERT_FACTOR * aFalDocPropNew.FDP_BASIS_QTY   -- Qte prevue
           , FAN_SCRAP_QTY = 0   -- Qte Rebut prévue
           , FAN_FULL_QTY = aFDP_CONVERT_FACTOR * aFalDocPropNew.FDP_BASIS_QTY   -- Qte Totale
           , FAN_BALANCE_QTY = aQteSolde   -- Qte Solde
           , FAN_FREE_QTY = aQteLibre   -- Qte Libre
           , FAN_STK_QTY = aQteAttStock   -- Qte Att Stock
           , FAN_NETW_QTY = aQteAttBesoin   -- Qte Att Besoin Appro
           , PAC_REPRESENTATIVE_ID = null   -- Représentant
       where current of CNeed;
    end if;

    close CNeed;
  exception
    when others then
      close CNeed;

      raise;
  end;

  /**
  * procedure ReseauBesoinPropositionMAJ_DRA
  * Description : Mise à jour des appro logistiques pour les DRA (demandes de
  *               ré-approvisionnement).
  *
  * @lastUpdate
  * @public
  * @param    aFalDocPropNew : nouvelles values d'une eregistrement de proposition logistique.
  * @param    aFalDocPropOld : anciennes values d'une eregistrement de proposition logistique.
  */
  procedure ReseauApproPropositionMAJ_DRA(aFalDocPropNew FAL_DOC_PROP%rowtype, aFalDocPropOld FAL_DOC_PROP%rowtype)
  is
  begin
    null;
  end;

  /**
  * procedure ReseauApproPropositionMAJ_POA(
  * Description : Mise à jour des appros logistiques pour les propositions
  *               d'approvisionnement logistique.
  *
  * @lastUpdate
  * @public
  * @param    aFalDocPropNew : nouvelles values d'une eregistrement de proposition logistique.
  * @param    aFalDocPropOld : anciennes values d'une eregistrement de proposition logistique.
  */
  procedure ReseauApproPropositionMAJ_POA(aFalDocPropNew FAL_DOC_PROP%rowtype, aFalDocPropOld FAL_DOC_PROP%rowtype)
  is
    EnrFAL_NETWORK_SUPPLY FAL_NETWORK_SUPPLY%rowtype;
    aDOC_RECORD_ID        TTypeID;
    aSTM_STOCK_ID         TTypeID;
    aSTM_LOCATION_ID      TTypeID;
    aFDP_CONVERT_FACTOR   FAL_DOC_PROP.FDP_CONVERT_FACTOR%type;
    aBeginPlan            TTypeDate;
    aEndPlan              TTypeDate;
    aBeginPlan2           TTypeDate;
    aBeginPlan3           TTypeDate;
    aBeginPlan4           TTypeDate;
    aEndPlan2             TTypeDate;
    aEndPlan3             TTypeDate;
    aEndPlan4             TTypeDate;
    aQteSolde             FAL_NETWORK_SUPPLY.FAN_BALANCE_QTY%type;
    aQteLibre             FAL_NETWORK_SUPPLY.FAN_FREE_QTY%type;
    aQteAttStock          FAL_NETWORK_SUPPLY.FAN_STK_QTY%type;
    aQteAttBesoin         FAL_NETWORK_SUPPLY.FAN_NETW_QTY%type;
    aDateChanged          boolean;
    aValueCarac1          DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac2          DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac3          DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac4          DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aValueCarac5          DOC_POSITION_DETAIL.PDE_CHARACTERIZATION_VALUE_1%type;
    aUseCharID1           number;
    aUseCharID2           number;
    aUseCharID3           number;
    aUseCharID4           number;
    aUseCharID5           number;

    -- Lecture et lock du réseau d'appro
    cursor CSupply
    is
      select     *
            from FAL_NETWORK_SUPPLY
           where FAL_DOC_PROP_ID = aFalDocPropNew.FAL_DOC_PROP_ID
      for update;
  begin
    open CSupply;

    fetch CSupply
     into EnrFAL_NETWORK_SUPPLY;

    -- Si l'appro associé au PositionDetailID a été trouvé
    if CSupply%found then
      -- Déterminer le Dossier ID
      aDOC_RECORD_ID       := aFalDocPropNew.DOC_RECORD_ID;

      -- Déterminer le Stock et l'emplacement ID
      if aFalDocPropNew.stm_STM_LOCATION_ID is null then
        -- Retrouver les stock et emplacement par défaut associés aux configuration PPS_Deflt..._NETWORK
        aSTM_STOCK_ID  := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_NETWORK');

        if aSTM_STOCK_ID is null then
          aSTM_LOCATION_ID  := null;
        else
          aSTM_LOCATION_ID  := FAL_TOOLS.GetConfig_LocationID('PPS_DefltLOCATION_NETWORK', aSTM_STOCK_ID);
        end if;
      else
        -- Récupérer le Stock associé à l'emplacement du détail position
        aSTM_LOCATION_ID  := aFalDocPropNew.STM_STM_LOCATION_ID;
        aSTM_STOCK_ID     := GetStockIDFromLocation(aSTM_LOCATION_ID);
      end if;

      -- Déterminer Begin et End Planif
      aBeginPlan           := aFalDocPropNew.FDP_BASIS_DELAY;
      aEndPlan             := aFalDocPropNew.FDP_FINAL_DELAY;
      -- Initialiser l'historique avec les valeurs actuelles
      aBeginPlan2          := EnrFAL_NETWORK_SUPPLY.FAN_BEG_PLAN2;
      aBeginPlan3          := EnrFAL_NETWORK_SUPPLY.FAN_BEG_PLAN3;
      aBeginPlan4          := EnrFAL_NETWORK_SUPPLY.FAN_BEG_PLAN4;
      aEndPlan2            := EnrFAL_NETWORK_SUPPLY.FAN_END_PLAN2;
      aEndPlan3            := EnrFAL_NETWORK_SUPPLY.FAN_END_PLAN3;
      aEndPlan4            := EnrFAL_NETWORK_SUPPLY.FAN_END_PLAN4;
      -- Déterminer si les dates de PositionDétail ont changés
      aDateChanged         :=
            (aFalDocPropNew.FDP_BASIS_DELAY <> aFalDocPropOld.FDP_BASIS_DELAY)
        and (not(     (aFalDocPropNew.FDP_BASIS_DELAY is null)
                 and (aFalDocPropOld.FDP_BASIS_DELAY is null) ) );

      if not aDateChanged then
        aDateChanged  :=
              (aFalDocPropNew.FDP_FINAL_DELAY <> aFalDocPropOld.FDP_FINAL_DELAY)
          and (not(     (aFalDocPropNew.FDP_FINAL_DELAY is null)
                   and (aFalDocPropOld.FDP_FINAL_DELAY is null) ) );
      end if;

      -- Déterminer l'historique de BeginPlanif
      if EnrFAL_NETWORK_SUPPLY.FAN_BEG_PLAN2 is null then
        if aDateChanged then
          aBeginPlan2  := aFalDocPropNew.FDP_BASIS_DELAY;
        else
          aBeginPlan2  := null;
        end if;
      end if;

      if EnrFAL_NETWORK_SUPPLY.FAN_BEG_PLAN2 is not null then
        if EnrFAL_NETWORK_SUPPLY.FAN_BEG_PLAN3 is null then
          if aDateChanged then
            aBeginPlan3  := aFalDocPropNew.FDP_BASIS_DELAY;
          else
            aBeginPlan3  := null;
          end if;
        end if;
      end if;

      if EnrFAL_NETWORK_SUPPLY.FAN_BEG_PLAN3 is not null then
        if aDateChanged then
          aBeginPlan4  := aFalDocPropNew.FDP_BASIS_DELAY;
        else
          aBeginPlan4  := null;
        end if;
      end if;

      -- Déterminer l'historique de EndPlanif
      if EnrFAL_NETWORK_SUPPLY.FAN_END_PLAN2 is null then
        if aDateChanged then
          aEndPlan2  := aFalDocPropNew.FDP_FINAL_DELAY;
          -- Mise à jour Date Appro sur Attributions
          FAL_NETWORK.Attribution_MAJ_DateAppro(EnrFAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID, aEndPlan2);
        else
          aEndPlan2  := null;
        end if;
      end if;

      if EnrFAL_NETWORK_SUPPLY.FAN_END_PLAN2 is not null then
        if EnrFAL_NETWORK_SUPPLY.FAN_END_PLAN3 is null then
          if aDateChanged then
            aEndPlan3  := aFalDocPropNew.FDP_FINAL_DELAY;
            -- Mise à jour Date Appro sur Attributions
            FAL_NETWORK.Attribution_MAJ_DateAppro(EnrFAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID, aEndPlan3);
          else
            aEndPlan3  := null;
          end if;
        end if;
      end if;

      if EnrFAL_NETWORK_SUPPLY.FAN_END_PLAN3 is not null then
        if aDateChanged then
          aEndPlan4  := aFalDocPropNew.FDP_FINAL_DELAY;
          -- Mise à jour Date Appro sur Attributions
          FAL_NETWORK.Attribution_MAJ_DateAppro(EnrFAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID, aEndPlan4);
        end if;
      end if;

      -- Déterminer le facteur de conversion de la position
      aFDP_CONVERT_FACTOR  := aFalDocPropNew.FDP_CONVERT_FACTOR;
      -- Déterminer la quantité solde
      aQteSolde            := aFDP_CONVERT_FACTOR * aFalDocPropNew.FDP_BASIS_QTY;
      -- Déterminer la quantité libre
      aQteLibre            := EnrFAL_NETWORK_SUPPLY.FAN_FREE_QTY;

      if aFalDocPropOld.FDP_BASIS_QTY > aFalDocPropNew.FDP_BASIS_QTY then
        if (EnrFAL_NETWORK_SUPPLY.FAN_NETW_QTY + EnrFAL_NETWORK_SUPPLY.FAN_STK_QTY) < aQteSolde then
          aQteLibre  := aQteSolde - EnrFAL_NETWORK_SUPPLY.FAN_NETW_QTY - EnrFAL_NETWORK_SUPPLY.FAN_STK_QTY;
        else
          aQteLibre  := 0;
        end if;
      elsif aFalDocPropOld.FDP_BASIS_QTY = aFalDocPropNew.FDP_BASIS_QTY then
        null;
      elsif aFalDocPropOld.FDP_BASIS_QTY < aFalDocPropNew.FDP_BASIS_QTY then
        aQteLibre  := aQteSolde - EnrFAL_NETWORK_SUPPLY.FAN_NETW_QTY - EnrFAL_NETWORK_SUPPLY.FAN_STK_QTY;
      end if;

      -- Déterminer la quantité attribuée sur Stock
      aQteAttStock         := EnrFAL_NETWORK_SUPPLY.FAN_STK_QTY;

      if aFalDocPropOld.FDP_BASIS_QTY > aFalDocPropNew.FDP_BASIS_QTY then
        if (EnrFAL_NETWORK_SUPPLY.FAN_NETW_QTY + EnrFAL_NETWORK_SUPPLY.FAN_STK_QTY) >= aQteSolde then
          if (EnrFAL_NETWORK_SUPPLY.FAN_NETW_QTY) >= aQteSolde then
            aQteAttStock  := 0;
            -- Suppression Attributions Appro-Stock
            FAL_NETWORK.Attribution_Suppr_ApproStock(EnrFAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID);
          else
            aQteAttStock  := aQteSolde - EnrFAL_NETWORK_SUPPLY.FAN_NETW_QTY;
            -- Mise à jour Attributions Appro-Stock
            FAL_NETWORK.Attribution_MAJ_ApproStock(EnrFAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID, EnrFAL_NETWORK_SUPPLY.FAN_STK_QTY, aQteAttStock);
          end if;
        end if;
      elsif aFalDocPropOld.FDP_BASIS_QTY = aFalDocPropNew.FDP_BASIS_QTY then
        null;
      end if;

      -- Déterminer la quantité attribuée sur besoin
      aQteAttBesoin        := EnrFAL_NETWORK_SUPPLY.FAN_NETW_QTY;

      if aFalDocPropOld.FDP_BASIS_QTY > aFalDocPropNew.FDP_BASIS_QTY then
        if (EnrFAL_NETWORK_SUPPLY.FAN_NETW_QTY + EnrFAL_NETWORK_SUPPLY.FAN_STK_QTY) >= aQteSolde then
          if (EnrFAL_NETWORK_SUPPLY.FAN_NETW_QTY) >= aQteSolde then
            aQteAttBesoin  := aQteSolde;
            -- Mise à jour Attributions Appro-Besoin
            FAL_NETWORK.Attribution_MAJ_ApproBesoin(EnrFAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID, EnrFAL_NETWORK_SUPPLY.FAN_NETW_QTY, aQteAttBesoin);
          end if;
        end if;
      elsif aFalDocPropOld.FDP_BASIS_QTY = aFalDocPropNew.FDP_BASIS_QTY then
        null;
      end if;

      GetNetworkCharactFromPOA(aFalDocPropNew
                             , aUseCharID1
                             , aUseCharID2
                             , aUseCharID3
                             , aUseCharID4
                             , aUseCharID5
                             , aValueCarac1
                             , aValueCarac2
                             , aValueCarac3
                             , aValueCarac4
                             , aValueCarac5
                              );

      -- Update de FAL_NETWORK_SUPPLY
      update FAL_NETWORK_SUPPLY
         set A_DATEMOD = sysdate   -- Date de modification
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni   -- User modification
           , DOC_RECORD_ID = aDOC_RECORD_ID   -- Dossier
           , STM_STOCK_ID = aSTM_STOCK_ID   -- Stock
           , STM_LOCATION_ID = aSTM_LOCATION_ID   -- Emplacement de stock
           , FAN_CHAR_VALUE1 = aValueCarac1   -- Valeur de caractérisation 1
           , FAN_CHAR_VALUE2 = aValueCarac2   -- Valeur de caractérisation 2
           , FAN_CHAR_VALUE3 = aValueCarac3   -- Valeur de caractérisation 3
           , FAN_CHAR_VALUE4 = aValueCarac4   -- Valeur de caractérisation 4
           , FAN_CHAR_VALUE5 = aValueCarac5   -- Valeur de caractérisation 5
           , GCO_CHARACTERIZATION1_ID = aUseCharID1
           , GCO_CHARACTERIZATION2_ID = aUseCharID2
           , GCO_CHARACTERIZATION3_ID = aUseCharID3
           , GCO_CHARACTERIZATION4_ID = aUseCharID4
           , GCO_CHARACTERIZATION5_ID = aUseCharID5
           , FAN_BEG_PLAN = aBeginPlan   -- Debut Planif
           , FAN_END_PLAN = aEndPlan   -- Fin Planif
           , FAN_PLAN_PERIOD = aEndPlan - aBeginPlan   -- Duree plannifiee
           , FAN_BEG_PLAN2 = aBeginPlan2   -- Debut Planif 2
           , FAN_BEG_PLAN3 = aBeginPlan3   -- Debut Planif 3
           , FAN_BEG_PLAN4 = aBeginPlan4   -- Debut Planif 4
           , FAN_END_PLAN2 = aEndPlan2   -- Fin Planif 2
           , FAN_END_PLAN3 = aEndPlan3   -- Fin Planif 3
           , FAN_END_PLAN4 = aEndPlan4   -- Fin Planif 4
           , FAN_PREV_QTY = aFDP_CONVERT_FACTOR * aFalDocPropNew.FDP_BASIS_QTY   -- Qte prevue
           , FAN_SCRAP_QTY = 0   -- Qte Rebut prévue
           , FAN_FULL_QTY = aFDP_CONVERT_FACTOR * aFalDocPropNew.FDP_BASIS_QTY   -- Qte Totale
           , FAN_BALANCE_QTY = aQteSolde   -- Qte Solde
           , FAN_FREE_QTY = aQteLibre   -- Qte Libre
           , FAN_STK_QTY = aQteAttStock   -- Qte Att Stock
           , FAN_NETW_QTY = aQteAttBesoin   -- Qte Att Besoin Appro
       where current of CSupply;
    end if;

    close CSupply;
  exception
    when others then
      close CSupply;

      raise;
  end;

  /***
  * procedure TRT_DOC_PDE_AD_FORNETWORK
  * Description : Ce traitement est appelé depuis le trigger DOC_PDE_AD_FORNETWORK lors de la suppression
  * d'un détail position mais également lors du parcours du curseur des détails position
  * dans le trigger DOC_POS_BD_FORNETWORK
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   PrmDOC_POSITION_DETAIL_ID    : Détail position
  * @param   PrmC_GAUGE_TYPE_POS          : Type de position
  * @param   PrmPOS_TRANSFERT_PROPRIETOR  : Durée de transfert du stock propriétaire
  * @param   PrmSTM_LOCATION_ID           : Emplacement
  * @param   PrmPDE_BASIS_DELAY           : Délais de base
  * @param   PrmPAC_THIRD_ID              : Tier
  * @param   PrmPDE_BALANCE_QUANTITY      : Qté Solde
  * @param   PrmDOC_DOCUMENT_ID           : Document
  * @param   PrmDOC_GAUGE_ID              : Gabarit document
  * @param   PrmGCO_GOOD_ID               : Bien
  * @param   PrmPAC_REPRESENTATIVE_ID     : Représentant
  */
  procedure TRT_DOC_PDE_AD_FORNETWORK(
    PrmDOC_POSITION_DETAIL_ID   DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , PrmC_GAUGE_TYPE_POS         DOC_POSITION.C_GAUGE_TYPE_POS%type
  , PrmPOS_TRANSFERT_PROPRIETOR DOC_POSITION.POS_TRANSFERT_PROPRIETOR%type
  , PrmSTM_LOCATION_ID          STM_LOCATION.STM_LOCATION_ID%type
  , PrmPDE_BASIS_DELAY          DOC_POSITION_DETAIL.PDE_BASIS_DELAY%type
  , PrmPAC_THIRD_ID             PAC_THIRD.PAC_THIRD_ID%type
  , PrmPDE_BALANCE_QUANTITY     DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY%type
  , PrmDOC_DOCUMENT_ID          DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , PrmDOC_GAUGE_ID             DOC_GAUGE.DOC_GAUGE_ID%type
  , PrmGCO_GOOD_ID              GCO_GOOD.GCO_GOOD_ID%type
  , PrmPAC_REPRESENTATIVE_ID    PAC_REPRESENTATIVE.PAC_REPRESENTATIVE_ID%type
  )
  is
    aFAL_NETWORK_NEED_ID  FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type;
    aDIC_PIC_GROUP_ID     DIC_PIC_GROUP.DIC_PIC_GROUP_ID%type;
    aGaugeType            DOC_GAUGE.C_GAUGE_TYPE%type;
    aGasUpdatePicOrderQty DOC_GAUGE_STRUCTURED.GAS_UPDATE_PIC_ORDER_QTY%type;
    aDateValue            date;

    cursor CurFAL_NETWORK_NEED
    is
      select FAL_NETWORK_NEED_ID
        from FAL_NETWORK_NEED
       where DOC_POSITION_DETAIL_ID = PrmDOC_POSITION_DETAIL_ID;
  begin
    -- Récupérer le type de gabarit du document, ainsi que le Flag de MAJ de la Qté commande PIC
    begin
      select GAU.C_GAUGE_TYPE
           , GAS.GAS_UPDATE_PIC_ORDER_QTY
        into aGaugeType
           , aGasUpdatePicOrderQty
        from DOC_GAUGE_STRUCTURED GAS
           , DOC_GAUGE GAU
       where GAU.DOC_GAUGE_ID = PrmDOC_GAUGE_ID
         and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID;
    exception
      when no_data_found then
        begin
          aGaugeType             := '';
          aGasUpdatePicOrderQty  := 0;
        end;
    end;

    if     PrmC_GAUGE_TYPE_POS in('1', '2', '3', '71', '81', '91', '101')
       and PrmPOS_TRANSFERT_PROPRIETOR <> '1'
       and to_number(PCS.PC_CONFIG.GetConfig('FAL_PIC') ) in(2, 3)
       and FAL_TOOLS.IsLocationOnStockNeedPic(PrmSTM_LOCATION_ID)
       and aGasUpdatePicOrderQty = 1 then
      -- Récupération du DIC_PIC_GROUP_ID via le PAC_THIRD_ID
      aDIC_PIC_GROUP_ID  := null;

      if PrmPAC_THIRD_ID is not null then
        select DIC_PIC_GROUP_ID
          into aDIC_PIC_GROUP_ID
          from PAC_CUSTOM_PARTNER
         where PAC_CUSTOM_PARTNER_ID = PrmPAC_THIRD_ID;
      end if;

      -- Gabarit de type besoin
      if aGaugeType = '1' then
        -- Le détail position a généré un besoin (La Qté en commande a été mise à jour)
        open CurFAL_NETWORK_NEED;

        fetch CurFAL_NETWORK_NEED
         into aFAL_NETWORK_NEED_ID;

        if CurFAL_NETWORK_NEED%found then
          -- Ce n'est pas le PDE_FINAL_DELAY qu'il faut prendre mais le PDE_BASIS_DELAY
          FAL_PLAN_DIRECTEUR.ProcessusMajQteCmdPicLine(PrmGCO_GOOD_ID
                                                     , PrmPDE_BASIS_DELAY
                                                     , PrmPAC_THIRD_ID
                                                     , PrmPAC_REPRESENTATIVE_ID
                                                     , -PrmPDE_BALANCE_QUANTITY
                                                     , aDIC_PIC_GROUP_ID
                                                      );
        end if;

        close CurFAL_NETWORK_NEED;
      -- Gabarit de type autre
      elsif aGaugeType = '3' then
        select DMT_DATE_VALUE
          into aDateValue
          from DOC_DOCUMENT
         where DOC_DOCUMENT_ID = PrmDOC_DOCUMENT_ID;

        FAL_PLAN_DIRECTEUR.ProcessusMajQteCmdPicLine(PrmGCO_GOOD_ID
                                                   , aDateValue
                                                   , PrmPAC_THIRD_ID
                                                   , PrmPAC_REPRESENTATIVE_ID
                                                   , -PrmPDE_BALANCE_QUANTITY
                                                   , aDIC_PIC_GROUP_ID
                                                    );
      end if;
    end if;

    -- Processus : Suppresion RéseauxLogBesoin (avec historisation)
    FAL_NETWORK_DOC.ReseauBesoinDOC_Suppr(PrmDOC_POSITION_DETAIL_ID, true);
    -- Processus : Suppresion RéseauxLogAppro (avec historisation)
    FAL_NETWORK_DOC.ReseauApproDOC_Suppr(PrmDOC_POSITION_DETAIL_ID, true);
  end;

  /**
  * procedure DiminuerUnePoaSelonQuantite
  * Description : Diminution de la qté d'une Proposition d'appro logistique
  *
  * @lastUpdate Créée pour Tronico (ne pas supprimer)
  * @public
  * @param   PrmFAL_DOC_PROP_ID : Proposition d'appro logistique
  * @param   PrmQte : Qté à diminuer
  */
  procedure DiminuerUnePoaSelonQuantite(PrmFAL_DOC_PROP_ID FAL_DOC_PROP.FAL_DOC_PROP_ID%type, PrmQte number)
  is
    aFAN_FREE_QTY  FAL_NETWORK_SUPPLY.FAN_FREE_QTY%type;
    aFDP_BASIS_QTY FAL_DOC_PROP.FDP_BASIS_QTY%type;
  begin
    -- Controler que la Qté de la PrmQTE <= Libre de la POA
    select FAN_FREE_QTY
      into aFAN_FREE_QTY
      from FAL_NETWORK_SUPPLY
     where FAL_DOC_PROP_ID = PrmFAL_DOC_PROP_ID;

    -- Quel est la Qté de la POA
    select FDP_BASIS_QTY
      into aFDP_BASIS_QTY
      from FAL_DOC_PROP
     where FAL_DOC_PROP_ID = PrmFAL_DOC_PROP_ID;

    if nvl(PrmQte, 0) <= aFAN_FREE_QTY then
      -- C'est ok on fait la mise à jour
      update FAl_DOC_PROP
         set FDP_BASIS_QTY = FDP_BASIS_QTY - nvl(PrmQTE, 0)
           , FDP_INTERMEDIATE_QTY = 0
           , FDP_FINAL_QTY = FDP_FINAL_QTY - nvl(PrmQTE, 0)
       where FAL_DOC_PROP_ID = PrmFAL_DOC_PROP_ID;
    else
      -- Pas ok => message d'erreur
      Raise_application_error(-20001, 'Qte > Libre POA,  Id de la proposition:' || PrmFAL_DOC_PROP_ID || ' Qte: ' || PrmQTE);
    end if;
  end;

  /**
  * Fonction    : CreateAttribBesoinApproOrStock
  * Description : Procedure de recréation d'attribution, utilisée en décharge de document et
  *          émission de bulletin de transfert de stock
  * @lastUpdate
  * @public
  * @param   aFAL_NETWORK_NEED_ID    : ID Besoin.
  * @param   aFAL_NETWORK_SUPPLY_ID  : ID Approvisionnement.
  * @param   aSTM_STOCk_POSITION_ID  : Position.
  * @param   aFLN_QTY                : Quantité de l'attribution.
  */
  procedure CreateAttribBesoinApproOrStock(
    aFAL_NETWORK_NEED_ID   in FAL_NETWORK_LINK.FAL_NETWORK_NEED_ID%type default null
  , aFAL_NETWORK_SUPPLY_ID in FAL_NETWORK_LINK.FAL_NETWORK_SUPPLY_ID%type default null
  , aSTM_STOCK_POSITION_ID in FAL_NETWORK_LINK.STM_STOCK_POSITION_ID%type default null
  , aFLN_QTY               in FAL_NETWORK_LINK.FLN_QTY%type default null
  )
  is
    nSTM_LOCATION_ID       STM_LOCATION.STM_LOCATION_ID%type;
    nFAL_NETWORK_NEED_ID   FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type;
    nFAL_NETWORK_SUPPLY_ID FAL_NETWORK_LINK.FAL_NETWORK_SUPPLY_ID%type;
    nSTM_STOCK_POSITION_ID FAL_NETWORK_LINK.STM_STOCK_POSITION_ID%type;
    lvErrorCode            varchar2(30);
  begin
    -- Vérification de l'existance du besoin
    begin
      select FAL_NETWORK_NEED_ID
        into nFAL_NETWORK_NEED_ID
        from FAL_NETWORK_NEED
       where FAL_NETWORK_NEED_ID = aFAL_NETWORK_NEED_ID;
    exception
      when no_data_found then
        nFAL_NETWORK_NEED_ID  := null;
    end;

    -- Si le besoin existe et que la quantité à attribuer est supérieure à 0.
    if     (nFAL_NETWORK_NEED_ID is not null)
       and (nvl(aFLN_QTY, 0) > 0) then
      -- Attribution de type besoin logistique sur Appro.
      if aFAL_NETWORK_SUPPLY_ID is not null then
        -- Vérification de l'existance de l'approvisionnement.
        begin
          select FAL_NETWORK_SUPPLY_ID
            into nFAL_NETWORK_SUPPLY_ID
            from FAL_NETWORK_SUPPLY
           where FAL_NETWORK_SUPPLY_ID = aFAL_NETWORK_SUPPLY_ID;
        exception
          when no_data_found then
            nFAL_NETWORK_SUPPLY_ID  := null;
        end;

        -- Si Appro existe
        if nFAL_NETWORK_SUPPLY_ID is not null then
          lvErrorCode  := null;
          FAL_NETWORK.CreateAttribBesoinAppro(nFAL_NETWORK_NEED_ID, nFAL_NETWORK_SUPPLY_ID, aFLN_QTY, lvErrorCode);
        end if;
      -- Attribution de type besoin logistique sur Stock.
      elsif aSTM_STOCK_POSITION_ID is not null then
        -- Vérification de l'existance de la position de stock et récupération de son emplacement.
        begin
          select STM_STOCK_POSITION_ID
               , STM_LOCATION_ID
            into nSTM_STOCK_POSITION_ID
               , nSTM_LOCATION_ID
            from STM_STOCK_POSITION
           where STM_STOCK_POSITION_ID = aSTM_STOCK_POSITION_ID;
        exception
          when no_data_found then
            begin
              nSTM_STOCK_POSITION_ID  := null;
              nSTM_LOCATION_ID        := null;
            end;
        end;

        -- Si la position existe :
        if nSTM_STOCK_POSITION_ID is not null then
          lvErrorCode  := null;
          FAL_NETWORK.CreateAttribBesoinStock(nFAL_NETWORK_NEED_ID, nSTM_STOCK_POSITION_ID, nSTM_LOCATION_ID, aFLN_QTY, lvErrorCode);
        end if;
      end if;
    end if;
  end CreateAttribBesoinApproOrStock;
end FAL_NETWORK_DOC;
