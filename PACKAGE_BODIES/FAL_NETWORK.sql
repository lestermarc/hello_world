--------------------------------------------------------
--  DDL for Package Body FAL_NETWORK
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_NETWORK" 
is
-- Déclaration des messages traduits utilisés par les exceptions
  excLinkQtyTooHighMsg    constant varchar2(255) := PCS.PC_FUNCTIONS.TranslateWord('La quantité de l''attribution est supérieure à la quantité libre!');
  eLockedNetwExceptionMsg constant varchar2(255) := PCS.PC_FUNCTIONS.TranslateWord('Réseaux en cours de modification par un autre utilisateur!');
  excAvailQtyTooLowMsg    constant varchar2(255) := PCS.PC_FUNCTIONS.TranslateWord('La quantité de l''attribution est supérieure à la quantité disponible!');

  procedure GetNetworkCharactFromProp(
    aFalLotProp in     FAL_LOT_PROP%rowtype
  , aCharID1    in out number
  , aCharID2    in out number
  , aCharID3    in out number
  , aCharID4    in out number
  , aCharID5    in out number
  , aCharValue1 in out varchar2
  , aCharValue2 in out varchar2
  , aCharValue3 in out varchar2
  , aCharValue4 in out varchar2
  , aCharValue5 in out varchar2
  )
  is
  begin
    -- Déterminer les caractérisations utiles du produit
    FAL_NETWORK.DefineUtilCharacterizations(aFalLotProp.GCO_GOOD_ID, aCharID1, aCharID2, aCharID3, aCharID4, aCharID5);
    -- Déterminer les caractérisations stockées dans les réseaux
    aCharValue1  := null;
    aCharValue2  := null;
    aCharValue3  := null;
    aCharValue4  := null;
    aCharValue5  := null;

    if aCharID1 is not null then
      if aFalLotProp.GCO_CHARACTERIZATION1_ID = aCharID1 then
        aCharValue1  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_1;
      elsif aFalLotProp.GCO_CHARACTERIZATION2_ID = aCharID1 then
        aCharValue1  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_2;
      elsif aFalLotProp.GCO_CHARACTERIZATION3_ID = aCharID1 then
        aCharValue1  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_3;
      elsif aFalLotProp.GCO_CHARACTERIZATION4_ID = aCharID1 then
        aCharValue1  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_4;
      elsif aFalLotProp.GCO_CHARACTERIZATION5_ID = aCharID1 then
        aCharValue1  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_5;
      end if;
    end if;

    if aCharID2 is not null then
      if aFalLotProp.GCO_CHARACTERIZATION1_ID = aCharID2 then
        aCharValue2  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_1;
      elsif aFalLotProp.GCO_CHARACTERIZATION2_ID = aCharID2 then
        aCharValue2  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_2;
      elsif aFalLotProp.GCO_CHARACTERIZATION3_ID = aCharID2 then
        aCharValue2  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_3;
      elsif aFalLotProp.GCO_CHARACTERIZATION4_ID = aCharID2 then
        aCharValue2  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_4;
      elsif aFalLotProp.GCO_CHARACTERIZATION5_ID = aCharID2 then
        aCharValue2  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_5;
      end if;
    end if;

    if aCharID3 is not null then
      if aFalLotProp.GCO_CHARACTERIZATION1_ID = aCharID3 then
        aCharValue3  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_1;
      elsif aFalLotProp.GCO_CHARACTERIZATION2_ID = aCharID3 then
        aCharValue3  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_2;
      elsif aFalLotProp.GCO_CHARACTERIZATION3_ID = aCharID3 then
        aCharValue3  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_3;
      elsif aFalLotProp.GCO_CHARACTERIZATION4_ID = aCharID3 then
        aCharValue3  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_4;
      elsif aFalLotProp.GCO_CHARACTERIZATION5_ID = aCharID3 then
        aCharValue3  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_5;
      end if;
    end if;

    if aCharID4 is not null then
      if aFalLotProp.GCO_CHARACTERIZATION1_ID = aCharID4 then
        aCharValue4  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_1;
      elsif aFalLotProp.GCO_CHARACTERIZATION2_ID = aCharID4 then
        aCharValue4  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_2;
      elsif aFalLotProp.GCO_CHARACTERIZATION3_ID = aCharID4 then
        aCharValue4  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_3;
      elsif aFalLotProp.GCO_CHARACTERIZATION4_ID = aCharID4 then
        aCharValue4  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_4;
      elsif aFalLotProp.GCO_CHARACTERIZATION5_ID = aCharID4 then
        aCharValue4  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_5;
      end if;
    end if;

    if aCharID5 is not null then
      if aFalLotProp.GCO_CHARACTERIZATION1_ID = aCharID5 then
        aCharValue5  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_1;
      elsif aFalLotProp.GCO_CHARACTERIZATION2_ID = aCharID5 then
        aCharValue5  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_2;
      elsif aFalLotProp.GCO_CHARACTERIZATION3_ID = aCharID5 then
        aCharValue5  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_3;
      elsif aFalLotProp.GCO_CHARACTERIZATION4_ID = aCharID5 then
        aCharValue5  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_4;
      elsif aFalLotProp.GCO_CHARACTERIZATION5_ID = aCharID5 then
        aCharValue5  := aFalLotProp.FAD_CHARACTERIZATION_VALUE_5;
      end if;
    end if;
  end;

  -- Récupération de la qté en fabrication du lot en cours
  function GetLOT_INPROD_QTY(LotID FAl_LOT.FAL_LOT_ID%type)
    return FAL_LOT.LOT_INPROD_QTY%type
  is
    aLOT_INPROD_QTY FAL_LOT.LOT_INPROD_QTY%type;
  begin
    select nvl(LOT_INPROD_QTY, 0)
      into aLOT_INPROD_QTY
      from FAL_LOT
     where FAL_LOT_ID = LotID;

    return aLOT_INPROD_QTY;
  exception
    when no_data_found then
      return 0;
  end;

  function ExistApproCaracterisePourLot(LotID FAl_LOT.FAL_LOT_ID%type)
    return boolean
  is
    N integer;
  begin
    select count(*)
      into N
      from FAL_NETWORK_SUPPLY
     where FAL_LOT_ID = LotID
       and FAL_LOT_MATERIAL_LINK_ID is null
       and (    FAN_CHAR_VALUE1 is null
            and FAN_CHAR_VALUE2 is null
            and FAN_CHAR_VALUE3 is null
            and FAN_CHAR_VALUE4 is null
            and FAN_CHAR_VALUE5 is null);

    return N <> 0;
  end;

-- FUNCTION GetMinStockLocation ()
-- Retourne pour un Stock donné le plus petit emplacement existant selon LOC_CLASSIFICATION
  function GetMinStockLocation(aStockID in TTypeID)
    return TTypeID
  is
    aMinLoc STM_LOCATION.LOC_CLASSIFICATION%type;
    aResult TTypeID;
  begin
    select min(LOC_CLASSIFICATION)
      into aMinLoc
      from STM_LOCATION
     where STM_STOCK_ID = aStockID;

    if aMinLoc is null then
      aResult  := null;
    else
      select STM_LOCATION_ID
        into aResult
        from STM_LOCATION
       where STM_STOCK_ID = aStockID
         and LOC_CLASSIFICATION = aMinLoc;
    end if;

    return aResult;
  end;

-- PROCEDURE SetDefaultStockAndLocation ()
--
-- Modifie le stock et l'emplacement en fonction des règles appliquées partout dans les réseaux
  procedure SetDefaultStockAndLocation(aStockID in out TTypeID, aLocationID in out TTYpeID, aDefaultStockID in TTypeID, aDefaultLocationID in TTypeID)
  is
  begin
    -- Déterminer la valeur du stock ID ...
    if aStockID is null then
      -- Définir le stock et l'emplacement sur les defauts ...
      aStockID     := nvl(aDefaultStockID, FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_NETWORK') );
      aLocationID  := nvl(aDefaultLocationID, FAL_TOOLS.GetConfig_LocationID('PPS_DefltLOCATION_NETWORK', aStockID) );
    else
      -- Déterminer la valeur de l'emplacement ...
      if aLocationID is null then
        -- Récupérer l'emplacement minimum pour le stock donné
        aLocationID  := GetMinStockLocation(aStockID);
      end if;
    end if;
  end;

-- FUNCTION GetLotGoodID ()
--
-- Retourne l'ID du produit d'un lot donné
  function GetLotGoodID(aLotID in TTypeID)
    return TTypeId
  is
    -- Lecture du GoodID d'un lot donné
    cursor GetLotGoodIDCursor(aLotID in TTypeID)
    is
      select GCO_GOOD_ID
        from FAL_LOT
       where FAL_LOT_ID = aLotID;

    aRecord GetLotGoodIDCursor%rowtype;
    aResult TTypeID;
  begin
    open GetLotGoodIDCursor(aLotID);

    fetch GetLotGoodIDCursor
     into aRecord;

    if GetLotGoodIDCursor%notfound then
      aResult  := null;
    else
      aResult  := aRecord.GCO_GOOD_ID;
    end if;

    close GetLotGoodIDCursor;

    return aResult;
  end;

-- FUNCTION GetLotCompleteReference ()
--
-- Retourne la référence complète d'un lot donné
  function GetLotCompleteReference(aLotID in TTypeID)
    return FAL_LOT.LOT_REFCOMPL%type
  is
    aResult FAL_LOT.LOT_REFCOMPL%type;
  begin
    select LOT_REFCOMPL
      into aResult
      from FAL_LOT
     where FAL_LOT_ID = aLotID;

    return aResult;
  exception
    when no_data_found then
      return null;
  end;

-- PROCEDURE DefineUtilCharacterizations ()
--
-- Retourne 5 booleans indiquant par vrai les charactértisations à prendre en compte dans les reseaux
-- uniquement les caractérisations de type Caractéristique ('2') et de type Version ('1') en gestion de stock
  procedure DefineUtilCharacterizations(
    aGoodID       in     TTypeID
  , aUseCharacID1 out    number
  , aUseCharacID2 out    number
  , aUseCharacID3 out    number
  , aUseCharacID4 out    number
  , aUseCharacID5 out    number
  )
  is
    -- Lecture de GCO_CHARACTERIZATION pour un produit donné
    cursor GetGoodCharacterizations(aGoodID in TTypeID)
    is
      select   GCO_CHARACTERIZATION_ID
             , CHA_STOCK_MANAGEMENT
             , C_CHARACT_TYPE
          from GCO_CHARACTERIZATION
         where GCO_GOOD_ID = aGoodID
      order by GCO_CHARACTERIZATION_ID asc;

    aIndex integer;
  begin
    aUseCharacID1  := null;
    aUseCharacID2  := null;
    aUseCharacID3  := null;
    aUseCharacID4  := null;
    aUseCharacID5  := null;
    aIndex         := 0;

    -- Ouvrir la table GCO_CHARACTERIZATION ...
    for aRecord in GetGoodCharacterizations(aGoodID) loop
      aIndex  := aIndex + 1;

      if     aRecord.CHA_STOCK_MANAGEMENT = 1
         and (   aRecord.C_CHARACT_TYPE = '2'
              or (    aRecord.C_CHARACT_TYPE = '1'
                  and to_number(PCS.PC_CONFIG.GetConfig('FAL_ATTRIB_ON_CHARACT_MODE') ) <> 4) ) then
        if aIndex = 1 then
          aUseCharacID1  := aRecord.GCO_CHARACTERIZATION_ID;
        elsif aIndex = 2 then
          aUseCharacID2  := aRecord.GCO_CHARACTERIZATION_ID;
        elsif aIndex = 3 then
          aUseCharacID3  := aRecord.GCO_CHARACTERIZATION_ID;
        elsif aIndex = 4 then
          aUseCharacID4  := aRecord.GCO_CHARACTERIZATION_ID;
        elsif aIndex = 5 then
          aUseCharacID5  := aRecord.GCO_CHARACTERIZATION_ID;
        end if;
      end if;
    end loop;
  end;

-- FUNCTION IsCharacterizationExists ()
--
-- Retourne Vrai si une ligne de FAL_NETWORK_SUPPLY existe pour le jeu de caractérisation fourni
-- (Attention : ce jeu de caractérisation tient des caractérisations utilisées dans les réseaux (caractéristiques et version)
--  des valeurs peuvent être nulles)
  function IsCharacterizationExists(
    aLotID         in TTypeID
  , aGCO_GOOD_ID   in TTypeID
  , aCharactValue1 in FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type
  , aCharactValue2 in FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type
  , aCharactValue3 in FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type
  , aCharactValue4 in FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type
  , aCharactValue5 in FAL_NETWORK_SUPPLY.FAN_CHAR_VALUE1%type
  )
    return boolean
  is
    aCount integer;
  begin
    select count(*)
      into aCount
      from FAL_NETWORK_SUPPLY
     where FAL_LOT_ID = aLotID
       and GCO_GOOD_ID = aGCO_GOOD_ID
       and (    (aCharactValue1 = FAN_CHAR_VALUE1)
            or (     (aCharactValue1 is null)
                and (FAN_CHAR_VALUE1 is null) ) )
       and (    (aCharactValue2 = FAN_CHAR_VALUE2)
            or (     (aCharactValue2 is null)
                and (FAN_CHAR_VALUE2 is null) ) )
       and (    (aCharactValue3 = FAN_CHAR_VALUE3)
            or (     (aCharactValue3 is null)
                and (FAN_CHAR_VALUE3 is null) ) )
       and (    (aCharactValue4 = FAN_CHAR_VALUE4)
            or (     (aCharactValue4 is null)
                and (FAN_CHAR_VALUE4 is null) ) )
       and (    (aCharactValue5 = FAN_CHAR_VALUE5)
            or (     (aCharactValue5 is null)
                and (FAN_CHAR_VALUE5 is null) ) );

    return(aCount > 0);
  end;

--------------------------------------------------------------------------------
-- IsFALNetWorkEnabled
--------------------------------------------------------------------------------
-- Détermine si la production gère les réseaux
--------------------------------------------------------------------------------
  function IsFALNetworkEnabled
    return boolean
  is
    strWord varchar2(30);
  begin
    strWord  := upper(PCS.PC_CONFIG.GetConfig('FAL_PROD_NETWORK') );
    return(strWord = 'TRUE');
  end;

--------------------------------------------------------------------------------
-- GetLotInProdQty
--------------------------------------------------------------------------------
-- Vérifier la quantité en fabrication du lot
--------------------------------------------------------------------------------
  function GetLotInProdQty(ALotID in TTypeID)
    return number
  is
    numQuantity FAL_LOT.LOT_INPROD_QTY%type;
  begin
    select max(LOT_INPROD_QTY)
      into numQuantity
      from FAL_LOT
     where FAL_LOT_ID = ALotID;

    if numQuantity is null then
      numQuantity  := 0;
    end if;

    return numQuantity;
  end;

--------------------------------------------------------------------------------
-- IsLotExistInNetworkSupply
--------------------------------------------------------------------------------
-- Détermine si le lot existe dans les réseaux appro
--------------------------------------------------------------------------------
  function IsLotExistInNetworkSupply(ALotID in TTypeID)
    return boolean
  is
    idLot FAL_NETWORK_SUPPLY.FAL_LOT_ID%type;
  begin
    select max(FAL_LOT_ID)
      into idLot
      from FAL_NETWORK_SUPPLY
     where FAL_LOT_ID = ALotID;

    if idLot is null then
      idLot  := 0;
    end if;

    return(idLot <> 0);
  end;

  /***
  * Function IsLotHasNetworkDetails
  *
  * Indique si le lot donné à des records dans DetailLot
  * et que le produit est caractérisé selon Version ou Caractéristique
  */
  function IsLotHasNetworkDetails(ALotID in TTypeID)
    return integer
  is
    idLotDetail  FAL_LOT_DETAIL.FAL_LOT_DETAIL_ID%type;
    Resultat     number;
    aGCO_GOOD_ID GCO_GOOD.GCO_GOOD_ID%type;
  begin
    -- Vérifie s'il existe des détails pour le lot
    select max(FAL_LOT_DETAIL_ID)
      into idLotDetail
      from FAL_LOT_DETAIL
     where FAL_LOT_ID = ALotID;

    resultat  := 0;

    -- Vérifie si le produit associé au lot à des caractérisations de type Version
    -- ou Caractéristiques
    if (nvl(idLotDetail, 0) <> 0) then
      select GCO_GOOD_ID
        into aGCO_GOOD_ID
        from FAL_LOT
       where FAL_LOT_ID = ALotID;

      Resultat  := FAL_TOOLS.ProductHasVersionOrCharacteris(aGCO_GOOD_ID);

      if Resultat = 0 then
        -- On considère alors que le lot peut avoir des détails lot de Pdts couplés
        Resultat  := FAL_COUPLED_GOOD.ExistsDetailForCoupledGood(ALotID);
      end if;
    end if;

    return Resultat;
  end;

  /***
  * procedure GetLotDetailSums
  *
  * Sommer dans les tableaux (base 0) les quantités de FAL_LOT_DETAIL selon les caractérisations utiles
  */
  procedure GetLotDetailSums(
    aLotID                    in     TTypeID
  , aGCO_GOOD_ID              in     TTypeID
  , aTabCaracterisationID1    in out TIDArray
  , aTabCaracterisationID2    in out TIDArray
  , aTabCaracterisationID3    in out TIDArray
  , aTabCaracterisationID4    in out TIDArray
  , aTabCaracterisationID5    in out TIDArray
  , aTabCaracterisationValue1 in out TStringArray
  , aTabCaracterisationValue2 in out TStringArray
  , aTabCaracterisationValue3 in out TStringArray
  , aTabCaracterisationValue4 in out TStringArray
  , aTabCaracterisationValue5 in out TStringArray
  , aTabQte                   in out TCurrencyArray
  , aTabQteReceptionne        in out TCurrencyArray
  , aTabQteAnnule             in out TCurrencyArray
  , aTabQteSolde              in out TCurrencyArray
  , aCount                    in out integer
  )
  is
    -- Curseur de parcours des Détails Lot ...
    cursor GetDetailLot
    is
      select FAD_CHARACTERIZATION_VALUE_1
           , FAD_CHARACTERIZATION_VALUE_2
           , FAD_CHARACTERIZATION_VALUE_3
           , FAD_CHARACTERIZATION_VALUE_4
           , FAD_CHARACTERIZATION_VALUE_5
           , GCO_CHARACTERIZATION_ID
           , GCO_GCO_CHARACTERIZATION_ID
           , GCO2_GCO_CHARACTERIZATION_ID
           , GCO3_GCO_CHARACTERIZATION_ID
           , GCO4_GCO_CHARACTERIZATION_ID
           , nvl(FAD_QTY, 0) FAD_QTY
           , nvl(FAD_RECEPT_QTY, 0) FAD_RECEPT_QTY
           , nvl(FAD_CANCEL_QTY, 0) FAD_CANCEL_QTY
           , nvl(FAD_BALANCE_QTY, 0) FAD_BALANCE_QTY
        from FAL_LOT_DETAIL
       where FAL_LOT_ID = aLotID
         and GCO_GOOD_ID = aGCO_GOOD_ID;

    -- Booleans indiquant si une caractérisation est prise en compte dans les réseaux ...
    aUseCaracID1 number;
    aUseCaracID2 number;
    aUseCaracID3 number;
    aUseCaracID4 number;
    aUseCaracID5 number;
    -- Valeurs de caractérisations ...
    aCarac1      FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
    aCarac2      FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
    aCarac3      FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
    aCarac4      FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
    aCarac5      FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
    -- Index de parcours ...
    aIndex       integer;
    aI           integer;
    -- Produit du lot ...
    aGoodId      TTypeID;
  begin
    -- Recherche produit du lot (Pas de probl pour les couplés, ils doivent
    -- posséder les mêmes caract que le produit référent).
    aGoodID  := GetLotGoodID(aLotID);
    -- Définir les caractérisations utiles ...
    DefineUtilCharacterizations(aGoodID, aUseCaracID1, aUseCaracID2, aUseCaracID3, aUseCaracID4, aUseCaracID5);
    aCount   := 0;

    -- Ouverture du curseur et parcours ...
    for aRecord in GetDetailLot loop
      -- Récupération des valeurs de caractérisations utilisée du détail lot
      aCarac1  := null;
      aCarac2  := null;
      aCarac3  := null;
      aCarac4  := null;
      aCarac5  := null;

      if aUseCaracID1 is not null then
        if aRecord.GCO_CHARACTERIZATION_ID = aUseCaracID1 then
          aCarac1  := aRecord.FAD_CHARACTERIZATION_VALUE_1;
        elsif aRecord.GCO_GCO_CHARACTERIZATION_ID = aUseCaracID1 then
          aCarac1  := aRecord.FAD_CHARACTERIZATION_VALUE_2;
        elsif aRecord.GCO2_GCO_CHARACTERIZATION_ID = aUseCaracID1 then
          aCarac1  := aRecord.FAD_CHARACTERIZATION_VALUE_3;
        elsif aRecord.GCO3_GCO_CHARACTERIZATION_ID = aUseCaracID1 then
          aCarac1  := aRecord.FAD_CHARACTERIZATION_VALUE_4;
        elsif aRecord.GCO4_GCO_CHARACTERIZATION_ID = aUseCaracID1 then
          aCarac1  := aRecord.FAD_CHARACTERIZATION_VALUE_5;
        end if;
      end if;

      if aUseCaracID2 is not null then
        if aRecord.GCO_CHARACTERIZATION_ID = aUseCaracID2 then
          aCarac2  := aRecord.FAD_CHARACTERIZATION_VALUE_1;
        elsif aRecord.GCO_GCO_CHARACTERIZATION_ID = aUseCaracID2 then
          aCarac2  := aRecord.FAD_CHARACTERIZATION_VALUE_2;
        elsif aRecord.GCO2_GCO_CHARACTERIZATION_ID = aUseCaracID2 then
          aCarac2  := aRecord.FAD_CHARACTERIZATION_VALUE_3;
        elsif aRecord.GCO3_GCO_CHARACTERIZATION_ID = aUseCaracID2 then
          aCarac2  := aRecord.FAD_CHARACTERIZATION_VALUE_4;
        elsif aRecord.GCO4_GCO_CHARACTERIZATION_ID = aUseCaracID2 then
          aCarac2  := aRecord.FAD_CHARACTERIZATION_VALUE_5;
        end if;
      end if;

      if aUseCaracID3 is not null then
        if aRecord.GCO_CHARACTERIZATION_ID = aUseCaracID3 then
          aCarac3  := aRecord.FAD_CHARACTERIZATION_VALUE_1;
        elsif aRecord.GCO_GCO_CHARACTERIZATION_ID = aUseCaracID3 then
          aCarac3  := aRecord.FAD_CHARACTERIZATION_VALUE_2;
        elsif aRecord.GCO2_GCO_CHARACTERIZATION_ID = aUseCaracID3 then
          aCarac3  := aRecord.FAD_CHARACTERIZATION_VALUE_3;
        elsif aRecord.GCO3_GCO_CHARACTERIZATION_ID = aUseCaracID3 then
          aCarac3  := aRecord.FAD_CHARACTERIZATION_VALUE_4;
        elsif aRecord.GCO4_GCO_CHARACTERIZATION_ID = aUseCaracID3 then
          aCarac3  := aRecord.FAD_CHARACTERIZATION_VALUE_5;
        end if;
      end if;

      if aUseCaracID4 is not null then
        if aRecord.GCO_CHARACTERIZATION_ID = aUseCaracID4 then
          aCarac4  := aRecord.FAD_CHARACTERIZATION_VALUE_1;
        elsif aRecord.GCO_GCO_CHARACTERIZATION_ID = aUseCaracID4 then
          aCarac4  := aRecord.FAD_CHARACTERIZATION_VALUE_2;
        elsif aRecord.GCO2_GCO_CHARACTERIZATION_ID = aUseCaracID4 then
          aCarac4  := aRecord.FAD_CHARACTERIZATION_VALUE_3;
        elsif aRecord.GCO3_GCO_CHARACTERIZATION_ID = aUseCaracID4 then
          aCarac4  := aRecord.FAD_CHARACTERIZATION_VALUE_4;
        elsif aRecord.GCO4_GCO_CHARACTERIZATION_ID = aUseCaracID4 then
          aCarac4  := aRecord.FAD_CHARACTERIZATION_VALUE_5;
        end if;
      end if;

      if aUseCaracID5 is not null then
        if aRecord.GCO_CHARACTERIZATION_ID = aUseCaracID5 then
          aCarac5  := aRecord.FAD_CHARACTERIZATION_VALUE_1;
        elsif aRecord.GCO_GCO_CHARACTERIZATION_ID = aUseCaracID5 then
          aCarac5  := aRecord.FAD_CHARACTERIZATION_VALUE_2;
        elsif aRecord.GCO2_GCO_CHARACTERIZATION_ID = aUseCaracID5 then
          aCarac5  := aRecord.FAD_CHARACTERIZATION_VALUE_3;
        elsif aRecord.GCO3_GCO_CHARACTERIZATION_ID = aUseCaracID5 then
          aCarac5  := aRecord.FAD_CHARACTERIZATION_VALUE_4;
        elsif aRecord.GCO4_GCO_CHARACTERIZATION_ID = aUseCaracID5 then
          aCarac5  := aRecord.FAD_CHARACTERIZATION_VALUE_5;
        end if;
      end if;

      -- Rechercher si une ligne contenant les mêmes valeurs de caractérisations existe ...
      aIndex   := -1;
      aI       := 0;

      while(aI < aCount)
       and (aIndex = -1) loop
        -- Recherche l'égalité des charactérisations ...
        if     (    (aTabCaracterisationValue1(aI) = aCarac1)
                or (     (aTabCaracterisationValue1(aI) is null)
                    and (aCarac1 is null) ) )
           and (    (aTabCaracterisationValue2(aI) = aCarac2)
                or (     (aTabCaracterisationValue2(aI) is null)
                    and (aCarac2 is null) ) )
           and (    (aTabCaracterisationValue3(aI) = aCarac3)
                or (     (aTabCaracterisationValue3(aI) is null)
                    and (aCarac3 is null) ) )
           and (    (aTabCaracterisationValue4(aI) = aCarac4)
                or (     (aTabCaracterisationValue4(aI) is null)
                    and (aCarac4 is null) ) )
           and (    (aTabCaracterisationValue5(aI) = aCarac5)
                or (     (aTabCaracterisationValue5(aI) is null)
                    and (aCarac5 is null) ) ) then
          -- Trouvé
          aIndex  := aI;
        end if;

        aI  := aI + 1;
      end loop;

      -- Si aIndex = -1 alors nouvelle ligne à ajouter ...
      if aIndex = -1 then
        -- Ajouter la ligne aux tableaux de valeurs de Caractérisations .
        aTabCaracterisationID1(aCount)     := aUseCaracID1;
        aTabCaracterisationValue1(aCount)  := aCarac1;
        aTabCaracterisationID2(aCount)     := aUseCaracID2;
        aTabCaracterisationValue2(aCount)  := aCarac2;
        aTabCaracterisationID3(aCount)     := aUseCaracID3;
        aTabCaracterisationValue3(aCount)  := aCarac3;
        aTabCaracterisationID4(aCount)     := aUseCaracID4;
        aTabCaracterisationValue4(aCount)  := aCarac4;
        aTabCaracterisationID5(aCount)     := aUseCaracID5;
        aTabCaracterisationValue5(aCount)  := aCarac5;
        -- Quantités ...
        aTabQte(aCount)                    := aRecord.FAD_QTY;
        aTabQteReceptionne(aCount)         := aRecord.FAD_RECEPT_QTY;
        aTabQteAnnule(aCount)              := aRecord.FAD_CANCEL_QTY;
        aTabQteSolde(aCount)               := aRecord.FAD_BALANCE_QTY;
        -- Incrémenter le nombre de lignes ...
        aCount                             := aCount + 1;
      -- ELSE : if aIndex = -1 ...
      else
        -- Sommer les quantités dans la ligne existante -------------------------------------------------------------
        aTabQte(aIndex)             := aTabQte(aIndex) + aRecord.FAD_QTY;
        aTabQteReceptionne(aIndex)  := aTabQteReceptionne(aIndex) + aRecord.FAD_RECEPT_QTY;
        aTabQteAnnule(aIndex)       := aTabQteAnnule(aIndex) + aRecord.FAD_CANCEL_QTY;
        aTabQteSolde(aIndex)        := aTabQteSolde(aIndex) + aRecord.FAD_BALANCE_QTY;
      -- FIN : if aIndex = -1 ...
      end if;
    -- Fin du curseur ...
    end loop;
  end;

  /***
  * procedure ReseauApproFAL_Detail_SupprNul
  *
  * Procédure générale de mise à jour des réseaux d'approvisionnement
  * (Avec toutes les caractérisations à NULL)
  */
  procedure ReseauApproFAL_Detail_SupprNul(aLotID in TTypeID)
  is
    -- Lecture de plusieurs enregistrement de FAL_NETWORK_SUPPLY selon le LotID - Toutes caractéristiques = NULL
    cursor GetSupplyDetailNullRecords(aLotID in TTypeID)
    is
      select FAL_NETWORK_SUPPLY_ID
        from FAL_NETWORK_SUPPLY
       where FAL_LOT_ID = aLotID
         and (    FAN_CHAR_VALUE1 is null
              and FAN_CHAR_VALUE2 is null
              and FAN_CHAR_VALUE3 is null
              and FAN_CHAR_VALUE4 is null
              and FAN_CHAR_VALUE5 is null);
  begin
    for aSupplyRecord in GetSupplyDetailNullRecords(aLotID) loop
      -- Suppression Attributions Appro Stock ...
      Attribution_Suppr_ApproStock(aSupplyRecord.FAL_NETWORK_SUPPLY_ID);
      -- Suppression Attributions Appro Besoin ...
      Attribution_Suppr_ApproBesoin(aSupplyRecord.FAL_NETWORK_SUPPLY_ID);

      -- Suppression de l'appros détaillés...
      delete from FAL_NETWORK_SUPPLY
            where FAL_NETWORK_SUPPLY_ID = aSupplyRecord.FAL_NETWORK_SUPPLY_ID;
    end loop;
  end;

  /***
  * procedure ReseauApproDetailFAL_MAJ
  *
  * Mise à jour complète d'un enregistrement dans FAL_NETWORK_SUPPLY à partir d'un lot de fabrication donné
  * Le paramètre aUpdateType vaut :
  *  1 : Mise à jour complète
  *  2 : Mise à jour Date
  *  3 : Mise à jour Reception PT
  */
  procedure ReseauApproDetailFAL_MAJ(
    aLotID             in TTypeID
  , aDefaultStockID    in TTypeID
  , aDefaultLocationID in TTypeID
  , aUpdateType        in integer
  , aStockPositionID   in varchar2
  )
  is
    cursor crSupplyWithoutCharact
    is
      select LOT.STM_STOCK_ID
           , LOT.STM_LOCATION_ID
           , LOT.LOT_REJECT_PLAN_QTY
           , LOT.LOT_REJECT_RELEASED_QTY
           , LOT.LOT_DISMOUNTED_QTY
           , LOT.LOT_PT_REJECT_QTY
           , LOT.LOT_CPT_REJECT_QTY
           , LOT.LOT_INPROD_QTY
           , LOT.LOT_ASKED_QTY
           , LOT.LOT_TOTAL_QTY
           , LOT.LOT_PLAN_LEAD_TIME
           , LOT.LOT_OPEN__DTE
           , LOT.LOT_PLAN_END_DTE
           , LOT.LOT_PLAN_BEGIN_DTE
           , LOT.DOC_RECORD_ID
           , LOT.LOT_RELEASED_QTY
           , SUP.FAL_NETWORK_SUPPLY_ID
           , SUP.FAN_BEG_PLAN1
           , SUP.FAN_BEG_PLAN2
           , SUP.FAN_BEG_PLAN3
           , SUP.FAN_BEG_PLAN4
           , SUP.FAN_END_PLAN1
           , SUP.FAN_END_PLAN2
           , SUP.FAN_END_PLAN3
           , SUP.FAN_END_PLAN4
           , SUP.FAN_SCRAP_REAL_QTY
           , SUP.FAN_BALANCE_QTY
           , SUP.FAN_FREE_QTY
           , SUP.FAN_STK_QTY
           , SUP.FAN_NETW_QTY
           , SUP.GCO_GOOD_ID
           , (select sum(FAD_BALANCE_QTY)
                from FAL_LOT_DETAIL
               where FAL_LOT_ID = aLotID
                 and GCO_GOOD_ID = SUP.GCO_GOOD_ID) SUM_FAD_BALANCE_QTY
           , (select max(C_LOT_DETAIL)
                from FAL_LOT_DETAIL
               where FAL_LOT_ID = aLotID
                 and GCO_GOOD_ID = SUP.GCO_GOOD_ID) C_LOT_DETAIL
        from FAL_LOT LOT
           , FAL_NETWORK_SUPPLY SUP
       where LOT.FAL_LOT_ID = aLotID
         and LOT.FAL_LOT_ID = SUP.FAL_LOT_ID
         and SUP.FAL_LOT_MATERIAL_LINK_ID is null
         and SUP.FAN_CHAR_VALUE1 is null
         and SUP.FAN_CHAR_VALUE2 is null
         and SUP.FAN_CHAR_VALUE3 is null
         and SUP.FAN_CHAR_VALUE4 is null
         and SUP.FAN_CHAR_VALUE5 is null;

    -- StockID défini pour l'insertion
    aStockID      TTypeID;
    -- LocationID défini pour l'insertion
    aLocationID   TTypeID;
    aDebutPlanif  TTypeDate;
    aFinPlanif    TTypeDate;
    aDebutPlanif2 TTypeDate;
    aDebutPlanif3 TTypeDate;
    aDebutPlanif4 TTypeDate;
    aFinPlanif2   TTypeDate;
    aFinPlanif3   TTypeDate;
    aFinPlanif4   TTypeDate;
    aRebutRealise FAL_NETWORK_SUPPLY.FAN_SCRAP_REAL_QTY%type;
    aQteSolde     FAL_NETWORK_SUPPLY.FAN_BALANCE_QTY%type;
    aQteLibre     FAL_NETWORK_SUPPLY.FAN_FREE_QTY%type;
    aQteAttStock  FAL_NETWORK_SUPPLY.FAN_STK_QTY%type;
    aQteAttBesoin FAL_NETWORK_SUPPLY.FAN_NETW_QTY%type;
  begin
    for tplSupplyWithoutCharact in crSupplyWithoutCharact loop
      -- Initialiser les valeurs ---------------------------------------------------------------------------------
      aDebutPlanif   := tplSupplyWithoutCharact.LOT_PLAN_BEGIN_DTE;
      aFinPlanif     := tplSupplyWithoutCharact.LOT_PLAN_END_DTE;
      aDebutPlanif2  := tplSupplyWithoutCharact.FAN_BEG_PLAN2;
      aDebutPlanif3  := tplSupplyWithoutCharact.FAN_BEG_PLAN3;
      aDebutPlanif4  := tplSupplyWithoutCharact.FAN_BEG_PLAN4;
      aFinPlanif2    := tplSupplyWithoutCharact.FAN_END_PLAN2;
      aFinPlanif3    := tplSupplyWithoutCharact.FAN_END_PLAN3;
      aFinPlanif4    := tplSupplyWithoutCharact.FAN_END_PLAN4;
      aRebutRealise  := tplSupplyWithoutCharact.FAN_SCRAP_REAL_QTY;

      if nvl(tplSupplyWithoutCharact.C_LOT_DETAIL, '1') = '1' then
        if nvl(tplSupplyWithoutCharact.LOT_REJECT_PLAN_QTY, 0) <=
             (nvl(tplSupplyWithoutCharact.LOT_REJECT_RELEASED_QTY, 0) +
              nvl(tplSupplyWithoutCharact.LOT_DISMOUNTED_QTY, 0) +
              nvl(tplSupplyWithoutCharact.LOT_PT_REJECT_QTY, 0) +
              nvl(tplSupplyWithoutCharact.LOT_CPT_REJECT_QTY, 0)
             ) then
          aQteSolde  := tplSupplyWithoutCharact.LOT_INPROD_QTY - nvl(tplSupplyWithoutCharact.SUM_FAD_BALANCE_QTY, 0);
        else
          aQteSolde  :=
            least(tplSupplyWithoutCharact.LOT_ASKED_QTY - tplSupplyWithoutCharact.LOT_RELEASED_QTY, tplSupplyWithoutCharact.LOT_INPROD_QTY) -
            nvl(tplSupplyWithoutCharact.SUM_FAD_BALANCE_QTY, 0);

          if aQteSolde < 0 then
            aQteSolde  := 0;
          end if;
        end if;
      else
        aQteSolde  := nvl(tplSupplyWithoutCharact.SUM_FAD_BALANCE_QTY, 0);
      end if;

      if aQteSolde = 0 then
        ReseauApproFAL_Detail_SupprNul(aLotID);
      else
        aQteLibre      := tplSupplyWithoutCharact.FAN_FREE_QTY;
        aQteAttStock   := tplSupplyWithoutCharact.FAN_STK_QTY;
        aQteAttBesoin  := tplSupplyWithoutCharact.FAN_NETW_QTY;
        -- Déterminer le STOCK et l'EMPLACEMENT à stocker dans les réseaux -----------------------------------------
        aStockID       := tplSupplyWithoutCharact.STM_STOCK_ID;
        aLocationID    := tplSupplyWithoutCharact.STM_LOCATION_ID;
        SetDefaultStockAndLocation(aStockID, aLocationID, aDefaultStockID, aDefaultLocationID);

        -- Déterminer les valeurs à modifier selon la valeur de aUpdateType (voir en-tête) -------------------------
        if    (aUpdateType = 1)
           or   -- Mise à jour complète ...
              (aUpdateType = 2) then   -- Mise à jour date ...
          -- Déterminer la date de début plannifiée 2 ----------------------------------------------------------------
          if tplSupplyWithoutCharact.FAN_BEG_PLAN2 is null then
            if (    (tplSupplyWithoutCharact.FAN_BEG_PLAN1 <> aDebutPlanif)
                or (tplSupplyWithoutCharact.FAN_END_PLAN1 <> aFinPlanif) ) then
              aDebutPlanif2  := aDebutPlanif;
            else
              aDebutPlanif2  := null;
            end if;
          end if;

          -- Déterminer la date de début plannifiée 3 ----------------------------------------------------------------
          if tplSupplyWithoutCharact.FAN_BEG_PLAN2 is not null then
            if tplSupplyWithoutCharact.FAN_BEG_PLAN3 is null then
              if (    (tplSupplyWithoutCharact.FAN_BEG_PLAN2 <> aDebutPlanif)
                  or (tplSupplyWithoutCharact.FAN_END_PLAN2 <> aFinPlanif) ) then
                aDebutPlanif3  := aDebutPlanif;
              else
                aDebutPlanif3  := null;
              end if;
            end if;
          end if;

          -- Déterminer la date de début plannifiée 4 ----------------------------------------------------------------
          if tplSupplyWithoutCharact.FAN_BEG_PLAN3 is not null then
            if (    (tplSupplyWithoutCharact.FAN_BEG_PLAN3 <> aDebutPlanif)
                or (tplSupplyWithoutCharact.FAN_END_PLAN3 <> aFinPlanif) ) then
              aDebutPlanif4  := aDebutPlanif;
            end if;
          end if;

          -- Déterminer la date de fin plannifiée 2 ----------------------------------------------------------------
          if tplSupplyWithoutCharact.FAN_END_PLAN2 is null then
            if (    (tplSupplyWithoutCharact.FAN_BEG_PLAN1 <> aDebutPlanif)
                or (tplSupplyWithoutCharact.FAN_END_PLAN1 <> aFinPlanif) ) then
              aFinPlanif2  := aFinPlanif;
              -- Mise à jour Attribution Date Appro ...
              Attribution_MAJ_DateAppro(tplSupplyWithoutCharact.FAL_NETWORK_SUPPLY_ID, aFinPlanif);
            else
              aFinPlanif2  := null;
            end if;
          end if;

          -- Déterminer la date de fin plannifiée 3 ----------------------------------------------------------------
          if tplSupplyWithoutCharact.FAN_END_PLAN2 is not null then
            if tplSupplyWithoutCharact.FAN_END_PLAN3 is null then
              if (    (tplSupplyWithoutCharact.FAN_BEG_PLAN2 <> aDebutPlanif)
                  or (tplSupplyWithoutCharact.FAN_END_PLAN2 <> aFinPlanif) ) then
                aFinPlanif3  := aFinPlanif;
                -- Mise à jour Attribution Date Appro ...
                Attribution_MAJ_DateAppro(tplSupplyWithoutCharact.FAL_NETWORK_SUPPLY_ID, aFinPlanif);
              else
                aFinPlanif3  := null;
              end if;
            end if;
          end if;

          -- Déterminer la date de fin plannifiée 4 ----------------------------------------------------------------
          if tplSupplyWithoutCharact.FAN_END_PLAN3 is not null then
            if (    (tplSupplyWithoutCharact.FAN_BEG_PLAN3 <> aDebutPlanif)
                or (tplSupplyWithoutCharact.FAN_END_PLAN3 <> aFinPlanif) ) then
              aFinPlanif4  := aFinPlanif;
              -- Mise à jour Attribution Date Appro ...
              Attribution_MAJ_DateAppro(tplSupplyWithoutCharact.FAL_NETWORK_SUPPLY_ID, aFinPlanif);
            end if;
          end if;
        -- FIN : if (aUpdateType = 1) OR (aUpdateType = 2) ...
        end if;

        -- Déterminer la Qte Rebut Realise -------------------------------------------------------------------------
        if (aUpdateType = 1) then   -- Mise à jour complète ...
          aRebutRealise  :=
            nvl(tplSupplyWithoutCharact.LOT_REJECT_RELEASED_QTY, 0) +
            nvl(tplSupplyWithoutCharact.LOT_DISMOUNTED_QTY, 0) +
            nvl(tplSupplyWithoutCharact.LOT_PT_REJECT_QTY, 0) +
            nvl(tplSupplyWithoutCharact.LOT_CPT_REJECT_QTY, 0);
        end if;

        if (aUpdateType = 1) then   -- Mise à jour complète ...
          -- Déterminer la Qte libre ---------------------------------------------------------------------------------
          if (nvl(tplSupplyWithoutCharact.FAN_FREE_QTY, 0) + nvl(tplSupplyWithoutCharact.FAN_NETW_QTY, 0) + nvl(tplSupplyWithoutCharact.FAN_STK_QTY, 0) ) <
                                                                                                                                              nvl(aQteSolde, 0) then
            aQteLibre  := nvl(aQteSolde, 0) - nvl(tplSupplyWithoutCharact.FAN_NETW_QTY, 0) - nvl(tplSupplyWithoutCharact.FAN_STK_QTY, 0);
          else
            if (nvl(tplSupplyWithoutCharact.FAN_FREE_QTY, 0) + nvl(tplSupplyWithoutCharact.FAN_NETW_QTY, 0) + nvl(tplSupplyWithoutCharact.FAN_STK_QTY, 0) ) >
                                                                                                                                              nvl(aQteSolde, 0) then
              if (nvl(tplSupplyWithoutCharact.FAN_NETW_QTY, 0) + nvl(tplSupplyWithoutCharact.FAN_STK_QTY, 0) ) < nvl(aQteSolde, 0) then
                aQteLibre  := nvl(aQteSolde, 0) - nvl(tplSupplyWithoutCharact.FAN_NETW_QTY, 0) - nvl(tplSupplyWithoutCharact.FAN_STK_QTY, 0);
              else
                aQteLibre  := 0;
              end if;
            end if;
          end if;

          -- Déterminer la Qte attribuée sur Stock -------------------------------------------------------------------
          if (nvl(tplSupplyWithoutCharact.FAN_FREE_QTY, 0) + nvl(tplSupplyWithoutCharact.FAN_NETW_QTY, 0) + nvl(tplSupplyWithoutCharact.FAN_STK_QTY, 0) ) >
                                                                                                                                               nvl(aQteSolde, 0) then
            if (nvl(tplSupplyWithoutCharact.FAN_NETW_QTY, 0) + nvl(tplSupplyWithoutCharact.FAN_STK_QTY, 0) ) >= nvl(aQteSolde, 0) then
              if (nvl(tplSupplyWithoutCharact.FAN_NETW_QTY, 0) ) < nvl(aQteSolde, 0) then
                aQteAttStock  := nvl(aQteSolde, 0) - nvl(tplSupplyWithoutCharact.FAN_NETW_QTY, 0);
                -- Mise à jour Attributions Appro-Stock ...
                Attribution_MAJ_ApproStock(tplSupplyWithoutCharact.FAL_NETWORK_SUPPLY_ID, tplSupplyWithoutCharact.FAN_STK_QTY, aQteAttStock);
              else
                aQteAttStock  := 0;
                -- Suppression Attributions Appro-Stock ...
                Attribution_Suppr_ApproStock(tplSupplyWithoutCharact.FAL_NETWORK_SUPPLY_ID);
              end if;
            end if;
          end if;

          -- Déterminer la Qte attribuée Appro Besoin ----------------------------------------------------------------
          if (nvl(tplSupplyWithoutCharact.FAN_NETW_QTY, 0) ) >= nvl(aQteSolde, 0) then
            aQteAttBesoin  := aQteSolde;
            -- Mise à jour Attributions Appro-Besoin ...
            Attribution_MAJ_ApproBesoin(tplSupplyWithoutCharact.FAL_NETWORK_SUPPLY_ID, tplSupplyWithoutCharact.FAN_NETW_QTY, aQteAttBesoin);
          end if;
        else
          if (aUpdateType = 3) then   -- Mise à jour Réception PT ...
            -- Déterminer la Qte attribuée sur Stock ----------------------------------------------------------------
            if (nvl(tplSupplyWithoutCharact.FAN_FREE_QTY, 0) + nvl(tplSupplyWithoutCharact.FAN_NETW_QTY, 0) ) < nvl(aQteSolde, 0) then
              aQteAttStock  := nvl(aQteSolde, 0) - nvl(tplSupplyWithoutCharact.FAN_FREE_QTY, 0) - nvl(tplSupplyWithoutCharact.FAN_NETW_QTY, 0);
              -- Mise à jour Attributions Appro-Stock ...
              Attribution_MAJ_ApproStock(tplSupplyWithoutCharact.FAL_NETWORK_SUPPLY_ID, tplSupplyWithoutCharact.FAN_STK_QTY, aQteAttStock);
            else
              aQteAttStock  := 0;
              -- Suppression Attributions Appro-Stock ...
              Attribution_Suppr_ApproStock(tplSupplyWithoutCharact.FAL_NETWORK_SUPPLY_ID);
            end if;

            -- Déterminer la Qte attribuée Appro Besoin -------------------------------------------------------------
            if (nvl(tplSupplyWithoutCharact.FAN_FREE_QTY, 0) + nvl(tplSupplyWithoutCharact.FAN_NETW_QTY, 0) ) >= nvl(aQteSolde, 0) then
              if (nvl(tplSupplyWithoutCharact.FAN_FREE_QTY, 0) ) < nvl(aQteSolde, 0) then
                aQteAttBesoin  := nvl(aQteSolde, 0) - nvl(tplSupplyWithoutCharact.FAN_FREE_QTY, 0);
                -- Mise à jour Attributions Appro-Besoin ...
                Attrib_MAJ_ApproBesoin_PT(tplSupplyWithoutCharact.FAL_NETWORK_SUPPLY_ID, tplSupplyWithoutCharact.FAN_NETW_QTY, aQteAttBesoin, aStockPositionID);
              else
                aQteAttBesoin  := 0;
                -- Suppression Attributions Appro-Besoin ...
                Attrib_Suppr_ApproBesoin_PT(tplSupplyWithoutCharact.FAL_NETWORK_SUPPLY_ID, aStockPositionID);
              end if;
            end if;

            -- Déterminer la Qte libre ------------------------------------------------------------------------------
            if (nvl(tplSupplyWithoutCharact.FAN_FREE_QTY, 0) + nvl(tplSupplyWithoutCharact.FAN_NETW_QTY, 0) ) >= nvl(aQteSolde, 0) then
              if (nvl(tplSupplyWithoutCharact.FAN_FREE_QTY, 0) ) >= nvl(aQteSolde, 0) then
                aQteLibre  := aQteSolde;
              end if;
            end if;
          end if;
        end if;

        -- Modification de l'appro chargée -------------------------------------------------------------------------
        -- Updater tout quelque soit aUpdateType ...
        update FAL_NETWORK_SUPPLY
           set DOC_RECORD_ID = tplSupplyWithoutCharact.DOC_RECORD_ID
             , FAN_BEG_PLAN = tplSupplyWithoutCharact.LOT_PLAN_BEGIN_DTE
             , FAN_END_PLAN = tplSupplyWithoutCharact.LOT_PLAN_END_DTE
             , FAN_BEG_PLAN2 = aDebutPlanif2
             , FAN_BEG_PLAN3 = aDebutPlanif3
             , FAN_BEG_PLAN4 = aDebutPlanif4
             , FAN_END_PLAN2 = aFinPlanif2
             , FAN_END_PLAN3 = aFinPlanif3
             , FAN_END_PLAN4 = aFinPlanif4
             , FAN_REAL_BEG = tplSupplyWithoutCharact.LOT_OPEN__DTE
             , FAN_PLAN_PERIOD = tplSupplyWithoutCharact.LOT_PLAN_LEAD_TIME
             , STM_STOCK_ID = aStockID
             , STM_LOCATION_ID = aLocationID
             , FAN_PREV_QTY = tplSupplyWithoutCharact.LOT_ASKED_QTY
             , FAN_SCRAP_QTY = tplSupplyWithoutCharact.LOT_REJECT_PLAN_QTY
             , FAN_FULL_QTY = tplSupplyWithoutCharact.LOT_TOTAL_QTY
             , FAN_REALIZE_QTY = tplSupplyWithoutCharact.LOT_RELEASED_QTY
             , FAN_SCRAP_REAL_QTY = aRebutRealise
             , FAN_BALANCE_QTY = aQteSolde
             , FAN_FREE_QTY = aQteLibre
             , FAN_STK_QTY = aQteAttStock
             , FAN_NETW_QTY = aQteAttBesoin
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             , A_DATEMOD = sysdate
         where FAL_NETWORK_SUPPLY_ID = tplSupplyWithoutCharact.FAL_NETWORK_SUPPLY_ID;
      end if;
    end loop;
  end;

  /***
  * procedure ReseauApproFAL_Detail_MAJ
  *
  * Mise à jour complète d'un enregistrement dans FAL_NETWORK_SUPPLY à partir d'un lot de fabrication donné
  * (DétailLot) ...
  * Le paramètre aUpdateType vaut :
  *  1 : Mise à jour complète
  *  2 : Mise à jour Date
  *  3 : Mise à jour Reception PT
  *  4 : Mise à jour Reception
  *
  * Si aAllowDelete > 0
  *  -> Si la QteSolde associée à un record Appro est = 0 alors suppression de l'appro concernée (avec eventuellement historisation)
  */
  procedure ReseauApproFAL_Detail_MAJ(
    aLotID             in TTypeID
  , aDefaultStockID    in TTypeID
  , aDefaultLocationID in TTypeID
  , aUpdateType        in integer
  , aAllowDelete       in integer
  , aHistorisation     in integer
  , aStockPositionID   in varchar2
  )
  is
    aLotConcerne                  GetLotRecord%rowtype;
    aApproConcerne                GetSupplyRecordForUpdate%rowtype;
    -- StockID défini pour l'insertion
    aStockID                      TTypeID;
    -- LocationID défini pour l'insertion
    aLocationID                   TTypeID;
    aDebutPlanif2                 TTypeDate;
    aDebutPlanif3                 TTypeDate;
    aDebutPlanif4                 TTypeDate;
    aFinPlanif2                   TTypeDate;
    aFinPlanif3                   TTypeDate;
    aFinPlanif4                   TTypeDate;
    aQteSolde                     FAL_NETWORK_SUPPLY.FAN_BALANCE_QTY%type;
    aQteLibre                     FAL_NETWORK_SUPPLY.FAN_FREE_QTY%type;
    aQteAttStock                  FAL_NETWORK_SUPPLY.FAN_STK_QTY%type;
    aQteAttBesoin                 FAL_NETWORK_SUPPLY.FAN_NETW_QTY%type;
    aGoodId                       TTypeID;
    -- Booleans indiquant si une caractérisation est prise en compte dans les réseaux ...
    aUseCarac1                    boolean;
    aUseCarac2                    boolean;
    aUseCarac3                    boolean;
    aUseCarac4                    boolean;
    aUseCarac5                    boolean;
    aCarac1                       FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
    aCarac2                       FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
    aCarac3                       FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
    aCarac4                       FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
    aCarac5                       FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
    -- Index de parcours ...
    aIndex                        integer;
    aI                            integer;
    -- Tables contenant les ID Caractérisations des Détails ...
    aTabCaracterisationID1        TIDArray;
    aTabCaracterisationID2        TIDArray;
    aTabCaracterisationID3        TIDArray;
    aTabCaracterisationID4        TIDArray;
    aTabCaracterisationID5        TIDArray;
    -- Tables contenant les Valeurs Caractérisations des Détails ...
    aTabCaracterisationValue1     TStringArray;
    aTabCaracterisationValue2     TStringArray;
    aTabCaracterisationValue3     TStringArray;
    aTabCaracterisationValue4     TStringArray;
    aTabCaracterisationValue5     TStringArray;
    -- Table contenant la somme Qté des Détails
    aTabQte                       TCurrencyArray;
    -- Table contenant la somme QtéRéceptionnée des Détails
    aTabQteReceptionne            TCurrencyArray;
    -- Table contenant la somme QtéAnnulée des Détails
    aTabQteAnnule                 TCurrencyArray;
    -- Table contenant la somme QtéSolde des Détails
    aTabQteSolde                  TCurrencyArray;
    -- Nombre de lignes des tables ci-dessous
    aTabCount                     integer;

    cursor CChaqueProdOfDetailLot
    is
      select distinct GCO_GOOD_ID
                 from FAL_LOT_DETAIL
                where FAL_LOT_ID = aLotID;

    EnrCChaqueProdOfDetailLot     CChaqueProdOfDetailLot%rowtype;
    cfgFAL_ATTRIB_ON_CHARACT_MODE integer;
  begin
    -- Ouverture du curseur sur le lot et renseigner aLotConcerne
    open GetLotRecord(aLotID);

    fetch GetLotRecord
     into aLotConcerne;

    -- S'assurer qu'il y ai un enregistrement Lot ...
    if GetLotRecord%found then
      -- Pour chaque Good Id des détails lot du lot.
      open CChaqueProdOfDetailLot;

      loop
        fetch CChaqueProdOfDetailLot
         into EnrCChaqueProdOfDetailLot;

        exit when CChaqueProdOfDetailLot%notfound;
        -- Récupérer le produit du lot ...
        aGoodID                        := GetLotGoodID(aLotID);
        -- Définir les caractérisations utiles ...
        -- aUseCaracX vaut True si la caractérisation correspondante est prise en compte dans les réseaux ...
        -- DefineUtilCharacterizations(aGoodID, aUseCarac1, aUseCarac2, aUseCarac3, aUseCarac4, aUseCarac5);
        cfgFAL_ATTRIB_ON_CHARACT_MODE  := to_number(PCS.PC_CONFIG.GetConfig('FAL_ATTRIB_ON_CHARACT_MODE') );
        -- Déterminer les tableaux DétailLot -----------------------------------------------------------------------
        GetLotDetailSums(aLotID
                       , EnrCChaqueProdOfDetailLot.GCO_GOOD_ID
                       , aTabCaracterisationID1
                       , aTabCaracterisationID2
                       , aTabCaracterisationID3
                       , aTabCaracterisationID4
                       , aTabCaracterisationID5
                       , aTabCaracterisationValue1
                       , aTabCaracterisationValue2
                       , aTabCaracterisationValue3
                       , aTabCaracterisationValue4
                       , aTabCaracterisationValue5
                       , aTabQte
                       , aTabQteReceptionne
                       , aTabQteAnnule
                       , aTabQteSolde
                       , aTabCount
                        );

        -- Ouverture du curseur sur les enregistrements Appro et renseigner aLotConcerne
        open GetSupplyRecordForUpdate(aLotID, EnrCChaqueProdOfDetailLot.GCO_GOOD_ID);

        loop
          fetch GetSupplyRecordForUpdate
           into aApproConcerne;

          -- S'assurer qu'il y ai un enregistrement Appro ...
          exit when GetSupplyRecordForUpdate%notfound;

          -- Définir les valeurs de caractérisations ...
          if     aApproConcerne.CHA_STOCK_MANAGEMENT1 = 1
             and (    (    aApproConcerne.C_CHARACT_TYPE1 = '1'
                       and cfgFAL_ATTRIB_ON_CHARACT_MODE <> 4)
                  or aApproConcerne.C_CHARACT_TYPE1 = '2') then
            aCarac1  := aApproConcerne.FAN_CHAR_VALUE1;
          else
            aCarac1  := null;
          end if;

          if     aApproConcerne.CHA_STOCK_MANAGEMENT2 = 1
             and (    (    aApproConcerne.C_CHARACT_TYPE2 = '1'
                       and cfgFAL_ATTRIB_ON_CHARACT_MODE <> 4)
                  or aApproConcerne.C_CHARACT_TYPE2 = '2') then
            aCarac2  := aApproConcerne.FAN_CHAR_VALUE2;
          else
            aCarac2  := null;
          end if;

          if     aApproConcerne.CHA_STOCK_MANAGEMENT3 = 1
             and (    (    aApproConcerne.C_CHARACT_TYPE3 = '1'
                       and cfgFAL_ATTRIB_ON_CHARACT_MODE <> 4)
                  or aApproConcerne.C_CHARACT_TYPE3 = '2') then
            aCarac3  := aApproConcerne.FAN_CHAR_VALUE3;
          else
            aCarac3  := null;
          end if;

          if     aApproConcerne.CHA_STOCK_MANAGEMENT4 = 1
             and (    (    aApproConcerne.C_CHARACT_TYPE4 = '1'
                       and cfgFAL_ATTRIB_ON_CHARACT_MODE <> 4)
                  or aApproConcerne.C_CHARACT_TYPE4 = '2') then
            aCarac4  := aApproConcerne.FAN_CHAR_VALUE4;
          else
            aCarac4  := null;
          end if;

          if     aApproConcerne.CHA_STOCK_MANAGEMENT5 = 1
             and (    (    aApproConcerne.C_CHARACT_TYPE5 = '1'
                       and cfgFAL_ATTRIB_ON_CHARACT_MODE <> 4)
                  or aApproConcerne.C_CHARACT_TYPE5 = '2') then
            aCarac5  := aApproConcerne.FAN_CHAR_VALUE5;
          else
            aCarac5  := null;
          end if;

          -- Rechercher si une ligne contenant les mêmes valeurs de caractérisations existe ...
          aIndex  := -1;
          aI      := 0;

          while(aI < aTabCount)
           and (aIndex = -1) loop
            -- Recherche l'égalité des charactérisations ...
            if     (    (aTabCaracterisationValue1(aI) = aCarac1)
                    or (     (aTabCaracterisationValue1(aI) is null)
                        and (aCarac1 is null) ) )
               and (    (aTabCaracterisationValue2(aI) = aCarac2)
                    or (     (aTabCaracterisationValue2(aI) is null)
                        and (aCarac2 is null) ) )
               and (    (aTabCaracterisationValue3(aI) = aCarac3)
                    or (     (aTabCaracterisationValue3(aI) is null)
                        and (aCarac3 is null) ) )
               and (    (aTabCaracterisationValue4(aI) = aCarac4)
                    or (     (aTabCaracterisationValue4(aI) is null)
                        and (aCarac4 is null) ) )
               and (    (aTabCaracterisationValue5(aI) = aCarac5)
                    or (     (aTabCaracterisationValue5(aI) is null)
                        and (aCarac5 is null) ) ) then
              -- Trouvé !
              aIndex  := aI;
            end if;

            aI  := aI + 1;
          end loop;

          -- Si un Détail Lot a été trouvé pour cet enregistrement d' APPRO ...
          if aIndex > -1 then
            -- Initialiser les valeurs ---------------------------------------------------------------------------------
            aDebutPlanif2  := aApproConcerne.FAN_BEG_PLAN2;
            aDebutPlanif3  := aApproConcerne.FAN_BEG_PLAN3;
            aDebutPlanif4  := aApproConcerne.FAN_BEG_PLAN4;
            aFinPlanif2    := aApproConcerne.FAN_END_PLAN2;
            aFinPlanif3    := aApproConcerne.FAN_END_PLAN3;
            aFinPlanif4    := aApproConcerne.FAN_END_PLAN4;
            aQteSolde      := aApproConcerne.FAN_BALANCE_QTY;
            aQteLibre      := aApproConcerne.FAN_FREE_QTY;
            aQteAttStock   := aApproConcerne.FAN_STK_QTY;
            aQteAttBesoin  := aApproConcerne.FAN_NETW_QTY;
            -- Déterminer la Qte Solde ---------------------------------------------------------------------------------
            aQteSolde      := aTabQteSolde(aIndex);

            -- Faut'il supprimer cet record ? --------------------------------------------------------------------------
            if (     (aAllowDelete > 0)
                and (aQteSolde = 0) ) then
              -- Suppression du record -------------------------------------------------------------------------------

              -- Historisation ...
              if aHistorisation > 0 then
                ReseauApproFAL_Historisation(aApproConcerne.FAL_NETWORK_SUPPLY_ID);
              -- FIN : Historisation ...
              end if;

              -- Suppression Attributions Appro Stock ...
              Attribution_Suppr_ApproStock(aApproConcerne.FAL_NETWORK_SUPPLY_ID);
              -- Suppression Attributions Appro Besoin ...
              Attribution_Suppr_ApproBesoin(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aStockPositionID);

              -- Suppression du record -------------------------------------------------------------------------------
              delete from FAL_NETWORK_SUPPLY
                    where current of GetSupplyRecordForUpdate;
            else
              -- Mise à jour du record -------------------------------------------------------------------------------

              -- Déterminer le STOCK et l'EMPLACEMENT à stocker dans les réseaux -----------------------------------------
              aStockID     := aLotConcerne.STM_STOCK_ID;
              aLocationID  := aLotConcerne.STM_LOCATION_ID;
              SetDefaultStockAndLocation(aStockID, aLocationID, aDefaultStockID, aDefaultLocationID);

              -- Déterminer les valeurs à modifier selon la valeur de aUpdateType (voir en-tête) -------------------------
              if    (aUpdateType = 1)
                 or   -- Mise à jour complète ...
                    (aUpdateType = 2) then   -- Mise à jour date ...
                -- Déterminer la date de début plannifiée 2 ----------------------------------------------------------------
                if aApproConcerne.FAN_BEG_PLAN2 is null then
                  if (    (aApproConcerne.FAN_BEG_PLAN1 <> aApproConcerne.FAN_BEG_PLAN)
                      or (aApproConcerne.FAN_END_PLAN1 <> aApproConcerne.FAN_END_PLAN) ) then
                    aDebutPlanif2  := aApproConcerne.FAN_BEG_PLAN;
                  else
                    aDebutPlanif2  := null;
                  end if;
                end if;

                -- Déterminer la date de début plannifiée 3 ----------------------------------------------------------------
                if aApproConcerne.FAN_BEG_PLAN2 is not null then
                  if aApproConcerne.FAN_BEG_PLAN3 is null then
                    if (    (aApproConcerne.FAN_BEG_PLAN2 <> aApproConcerne.FAN_BEG_PLAN)
                        or (aApproConcerne.FAN_END_PLAN2 <> aApproConcerne.FAN_END_PLAN) ) then
                      aDebutPlanif3  := aApproConcerne.FAN_BEG_PLAN;
                    else
                      aDebutPlanif3  := null;
                    end if;
                  end if;
                end if;

                -- Déterminer la date de début plannifiée 4 ----------------------------------------------------------------
                if aApproConcerne.FAN_BEG_PLAN3 is not null then
                  if (    (aApproConcerne.FAN_BEG_PLAN3 <> aApproConcerne.FAN_BEG_PLAN)
                      or (aApproConcerne.FAN_END_PLAN3 <> aApproConcerne.FAN_END_PLAN) ) then
                    aDebutPlanif4  := aApproConcerne.FAN_BEG_PLAN;
                  end if;
                end if;

                -- Déterminer la date de fin plannifiée 2 ----------------------------------------------------------------
                if aApproConcerne.FAN_END_PLAN2 is null then
                  if (    (aApproConcerne.FAN_BEG_PLAN1 <> aApproConcerne.FAN_BEG_PLAN)
                      or (aApproConcerne.FAN_END_PLAN1 <> aApproConcerne.FAN_END_PLAN) ) then
                    aFinPlanif2  := aApproConcerne.FAN_END_PLAN;
                    -- Mise à jour Attribution Date Appro ...
                    Attribution_MAJ_DateAppro(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aApproConcerne.FAN_END_PLAN);
                  else
                    aFinPlanif2  := null;
                  end if;
                end if;

                -- Déterminer la date de fin plannifiée 3 ----------------------------------------------------------------
                if aApproConcerne.FAN_END_PLAN2 is not null then
                  if aApproConcerne.FAN_END_PLAN3 is null then
                    if (    (aApproConcerne.FAN_BEG_PLAN2 <> aApproConcerne.FAN_BEG_PLAN)
                        or (aApproConcerne.FAN_END_PLAN2 <> aApproConcerne.FAN_END_PLAN) ) then
                      aFinPlanif3  := aApproConcerne.FAN_END_PLAN;
                      -- Mise à jour Attribution Date Appro ...
                      Attribution_MAJ_DateAppro(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aApproConcerne.FAN_END_PLAN);
                    else
                      aFinPlanif3  := null;
                    end if;
                  end if;
                end if;

                -- Déterminer la date de début plannifiée 4 ----------------------------------------------------------------
                if aApproConcerne.FAN_BEG_PLAN3 is not null then
                  if (    (aApproConcerne.FAN_BEG_PLAN3 <> aApproConcerne.FAN_BEG_PLAN)
                      or (aApproConcerne.FAN_END_PLAN3 <> aApproConcerne.FAN_END_PLAN) ) then
                    aFinPlanif4  := aApproConcerne.FAN_END_PLAN;
                    -- Mise à jour Attribution Date Appro ...
                    Attribution_MAJ_DateAppro(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aApproConcerne.FAN_END_PLAN);
                  end if;
                end if;
              -- FIN : if (aUpdateType = 1) OR (aUpdateType = 2) ...
              end if;

              if    (aUpdateType = 1)
                 or   -- Mise à jour Complète ...
                    (aUpdateType = 4) then   -- Mise à jour Réception ...
                -- Déterminer la Qte libre ---------------------------------------------------------------------------------
                if (nvl(aApproConcerne.FAN_FREE_QTY, 0) + nvl(aApproConcerne.FAN_NETW_QTY, 0) + nvl(aApproConcerne.FAN_STK_QTY, 0) ) < nvl(aQteSolde, 0) then
                  aQteLibre  := nvl(aQteSolde, 0) - nvl(aApproConcerne.FAN_NETW_QTY, 0) - nvl(aApproConcerne.FAN_STK_QTY, 0);
                else
                  if (nvl(aApproConcerne.FAN_FREE_QTY, 0) + nvl(aApproConcerne.FAN_NETW_QTY, 0) + nvl(aApproConcerne.FAN_STK_QTY, 0) ) > nvl(aQteSolde, 0) then
                    if (nvl(aApproConcerne.FAN_NETW_QTY, 0) + nvl(aApproConcerne.FAN_STK_QTY, 0) ) < nvl(aQteSolde, 0) then
                      aQteLibre  := nvl(aQteSolde, 0) - nvl(aApproConcerne.FAN_NETW_QTY, 0) - nvl(aApproConcerne.FAN_STK_QTY, 0);
                    else
                      aQteLibre  := 0;
                    end if;
                  end if;
                end if;

                -- Déterminer la Qte attribuée sur Stock -------------------------------------------------------------------
                if (nvl(aApproConcerne.FAN_FREE_QTY, 0) + nvl(aApproConcerne.FAN_NETW_QTY, 0) + nvl(aApproConcerne.FAN_STK_QTY, 0) ) > nvl(aQteSolde, 0) then
                  if (nvl(aApproConcerne.FAN_NETW_QTY, 0) + nvl(aApproConcerne.FAN_STK_QTY, 0) ) >= nvl(aQteSolde, 0) then
                    if (nvl(aApproConcerne.FAN_NETW_QTY, 0) ) < nvl(aQteSolde, 0) then
                      aQteAttStock  := nvl(aQteSolde, 0) - nvl(aApproConcerne.FAN_NETW_QTY, 0);
                      -- Mise à jour Attributions Appro-Stock ...
                      Attribution_MAJ_ApproStock(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aApproConcerne.FAN_STK_QTY, aQteAttStock);
                    else
                      aQteAttStock  := 0;
                      -- Suppression Attributions Appro-Stock ...
                      Attribution_Suppr_ApproStock(aApproConcerne.FAL_NETWORK_SUPPLY_ID);
                    end if;
                  end if;
                end if;

                -- Déterminer la Qte attribuée Appro Besoin ----------------------------------------------------------------
                if (nvl(aApproConcerne.FAN_FREE_QTY, 0) + nvl(aApproConcerne.FAN_NETW_QTY, 0) + nvl(aApproConcerne.FAN_STK_QTY, 0) ) > nvl(aQteSolde, 0) then
                  if (nvl(aApproConcerne.FAN_NETW_QTY, 0) + nvl(aApproConcerne.FAN_STK_QTY, 0) ) >= nvl(aQteSolde, 0) then
                    if (nvl(aApproConcerne.FAN_NETW_QTY, 0) ) >= nvl(aQteSolde, 0) then
                      aQteAttBesoin  := aQteSolde;
                      -- Mise à jour Attributions Appro-Besoin ...
                      Attribution_MAJ_ApproBesoin(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aApproConcerne.FAN_NETW_QTY, aQteAttBesoin);
                    end if;
                  end if;
                end if;
              -- ELSE : IF (aUpdateType = 1 ou 4) THEN ...
              else
                if (aUpdateType = 3) then   -- Mise à jour Réception PT ...
                  -- Déterminer la Qte attribuée sur Stock ----------------------------------------------------------------
                  if (nvl(aApproConcerne.FAN_FREE_QTY, 0) + nvl(aApproConcerne.FAN_NETW_QTY, 0) ) < nvl(aQteSolde, 0) then
                    aQteAttStock  := nvl(aQteSolde, 0) - nvl(aApproConcerne.FAN_FREE_QTY, 0) - nvl(aApproConcerne.FAN_NETW_QTY, 0);
                    -- Mise à jour Attributions Appro-Stock ...
                    Attribution_MAJ_ApproStock(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aApproConcerne.FAN_STK_QTY, aQteAttStock);
                  else
                    aQteAttStock  := 0;
                    -- Suppression Attributions Appro-Stock ...
                    Attribution_Suppr_ApproStock(aApproConcerne.FAL_NETWORK_SUPPLY_ID);
                  end if;

                  -- Déterminer la Qte attribuée Appro Besoin -------------------------------------------------------------
                  if (nvl(aApproConcerne.FAN_FREE_QTY, 0) + nvl(aApproConcerne.FAN_NETW_QTY, 0) ) >= nvl(aQteSolde, 0) then
                    if (nvl(aApproConcerne.FAN_FREE_QTY, 0) ) < nvl(aQteSolde, 0) then
                      aQteAttBesoin  := nvl(aQteSolde, 0) - nvl(aApproConcerne.FAN_FREE_QTY, 0);
                      -- Mise à jour Attributions Appro-Besoin ...
                      Attrib_MAJ_ApproBesoin_PT(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aApproConcerne.FAN_NETW_QTY, aQteAttBesoin, aStockPositionID);
                    else
                      aQteAttBesoin  := 0;
                      -- Suppression Attributions Appro-Besoin ...
                      Attrib_Suppr_ApproBesoin_PT(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aStockPositionID);
                    end if;
                  end if;

                  -- Déterminer la Qte libre ------------------------------------------------------------------------------
                  if (nvl(aApproConcerne.FAN_FREE_QTY, 0) + nvl(aApproConcerne.FAN_NETW_QTY, 0) ) >= nvl(aQteSolde, 0) then
                    if (nvl(aApproConcerne.FAN_FREE_QTY, 0) ) >= nvl(aQteSolde, 0) then
                      aQteLibre  := aQteSolde;
                    end if;
                  end if;
                -- FIN  : IF (aUpdateType = 3) THEN ...
                end if;
              -- FIN  : IF (aUpdateType = 1) THEN ...
              end if;

              -- Modification de l'appro chargée -------------------------------------------------------------------------
              -- Updater tout quelque soit aUpdateType ...
              update FAL_NETWORK_SUPPLY
                 set A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                   , A_DATEMOD = sysdate
                   , DOC_RECORD_ID = aLotConcerne.DOC_RECORD_ID
                   , FAN_BEG_PLAN = aLotConcerne.LOT_PLAN_BEGIN_DTE
                   , FAN_END_PLAN = aLotConcerne.LOT_PLAN_END_DTE
                   , FAN_BEG_PLAN2 = aDebutPlanif2
                   , FAN_BEG_PLAN3 = aDebutPlanif3
                   , FAN_BEG_PLAN4 = aDebutPlanif4
                   , FAN_END_PLAN2 = aFinPlanif2
                   , FAN_END_PLAN3 = aFinPlanif3
                   , FAN_END_PLAN4 = aFinPlanif4
                   , FAN_REAL_BEG = aLotConcerne.LOT_OPEN__DTE
                   , FAN_PLAN_PERIOD = aLotConcerne.LOT_PLAN_LEAD_TIME
                   , STM_STOCK_ID = aStockID
                   , STM_LOCATION_ID = aLocationID
                   , FAN_PREV_QTY = aTabQte(aIndex)
                   , FAN_FULL_QTY = aTabQte(aIndex)
                   , FAN_REALIZE_QTY = aTabQteReceptionne(aIndex) + aTabQteAnnule(aIndex)
                   , FAN_BALANCE_QTY = aQteSolde
                   , FAN_FREE_QTY = aQteLibre
                   , FAN_STK_QTY = aQteAttStock
                   , FAN_NETW_QTY = aQteAttBesoin
               where current of GetSupplyRecordForUpdate;
            end if;
          end if;
        end loop;

        -- Fermeture du curseur sur l'appro
        close GetSupplyRecordForUpdate;
      end loop;

      close CChaqueProdOfDetailLot;
    -- Fin de boucle sur les Good Id des détails lot du lot

    -- FIN : S'assurer qu'il y ai un enregistrement Lot ...
    end if;

    -- fermeture du curseur sur le lot concerné
    close GetLotRecord;
  end;

  /***
  * procedure MiseAJourReseauApproDetail
  *
  * Procédure générale de mise à jour des réseaux d'approvisionnement
  * dans le cas d'un lot avec détail, version ou caractéristique.
  */
  procedure MiseAJourReseauApproDetail(
    ALotID               in TTypeID
  , AContext             in integer
  , ADefaultStockID      in TTypeID
  , ADefaultLocationID   in TTypeID
  , AStockPositionIDList in varchar2
  )
  is
    blnCreation             boolean;
    blnSuppression          boolean;
    blnMiseAJourEdit        boolean;
    blnMiseAJourReceptionPT boolean;
    blnMiseAJourReception   boolean;
    blnMiseAJourDate        boolean;
    lLotInProdQty           FAL_LOT.LOT_INPROD_QTY%type;
    lSumDetailBalanceQty    FAL_LOT_DETAIL.FAD_BALANCE_QTY%type;
    lbCoupledGoodExist      boolean;

    function GetSommeQteSoldeDesDetailsLots(LotID FAl_LOT.FAL_LOT_ID%type)
      return FAL_LOT_DETAIL.FAD_BALANCE_QTY%type
    is
      Somme FAL_LOT_DETAIL.FAD_BALANCE_QTY%type;
    begin
      select sum(FAD_BALANCE_QTY)
        into Somme
        from FAL_LOT_DETAIL
       where FAL_LOT_ID = LotID;

      return nvl(Somme, 0);
    exception
      when no_data_found then
        return 0;
    end;
  begin
    blnCreation              :=
         AContext in
                    (ncCreationLot, ncModificationLot, ncReceptionPT, ncReceptionRebut, ncDemontagePT, ncSuiviAvancementCreation, ncSuiviAvancementSuppression);
    blnSuppression           :=
      AContext in
        (ncModificationLot
       , ncSuppressionLot
       , ncReceptionPT
       , ncSolderLot
       , ncReceptionRebut
       , ncDemontagePT
       , ncSuiviAvancementCreation
       , ncSuiviAvancementSuppression
        );
    blnMiseAJourEdit         := AContext in(ncModificationLot);
    blnMiseAJourReceptionPT  := AContext in(ncReceptionPT);
    blnMiseAJourReception    := AContext in(ncReceptionRebut, ncDemontagePT, ncSuiviAvancementCreation, ncSuiviAvancementSuppression);
    blnMiseAJourDate         := AContext in(ncLancementLot, ncPlannificationLot);
    lLotInProdQty            := GetLOT_INPROD_QTY(aLotID);
    lSumDetailBalanceQty     := GetSommeQteSoldeDesDetailsLots(aLotID);
    lbCoupledGoodExist       :=(FAL_COUPLED_GOOD.ExistsDetailForCoupledGood(aLotID) = 1);

    if     (not blnCreation)
       and (not blnSuppression)
       and (not blnMiseAJourEdit)
       and (not blnMiseAJourReceptionPT)
       and (not blnMiseAJourReception)
       and (blnMiseAJourDate) then
      -- Processus : Mise à jour Date Reseaux Appro Détail ...
      -- Suppression impossible donc sans historisation ...
      ReseauApproFAL_Detail_MAJ(ALotID, ADefaultStockID, ADefaultLocationID, 2, 0, 0, AStockPositionIDList);
    elsif     (not blnCreation)
          and (blnSuppression)
          and (not blnMiseAJourEdit)
          and (not blnMiseAJourReceptionPT)
          and (not blnMiseAJourReception)
          and (not blnMiseAJourDate) then
      -- Processus : Suppression Reseaux Appro Détail ...
      -- avec Historisation ...
      ReseauApproFAL_Detail_SupprAll(ALotID, 1);
    elsif     (blnCreation)
          and (not blnSuppression)
          and (not blnMiseAJourEdit)
          and (not blnMiseAJourReceptionPT)
          and (not blnMiseAJourReception)
          and (not blnMiseAJourDate) then
      -- Processus : Création Reseaux Appro Détail ...
      ReseauApproFAL_Detail_Creation(ALotID, ADefaultStockID, ADefaultLocationID);

      -- Repère: A2
      if     (lLotInProdQty > lSumDetailBalanceQty)
         and (not ExistApproCaracterisePourLot(aLotID) ) then
        ReseauApproFAL_Creation(aLotID, aDefaultStockID, aDefaultLocationID);
        ReseauApproDetailFAL_MAJ(aLotID, aDefaultStockID, aDefaultLocationID, 1, AStockPositionIDList);
      end if;
    elsif     (blnCreation)
          and (blnSuppression)
          and (    (blnMiseAJourEdit)
               or (blnMiseAJourReceptionPT)
               or (blnMiseAJourReception) )
          and (not blnMiseAJourDate) then
      -- Processus : Création Reseaux Appro Détail ...
      -- Uniquement pour les détails n'existant pas déjà dans les réseaux appro ...
      -- La procédure stockée se charge de contrôler l'absence du jeu de caractérisations dans les réseaux ...
      ReseauApproFAL_Detail_Creation(ALotID, ADefaultStockID, ADefaultLocationID);

      -- Repère: A1
      if     (lLotInProdQty > lSumDetailBalanceQty)
         and (not ExistApproCaracterisePourLot(aLotID) ) then
        ReseauApproFAL_Creation(aLotID, aDefaultStockID, aDefaultLocationID);
      end if;

      -- Si la qté en fabrication du lot en cours est > 0
      if lLotInProdQty > 0 then
        --  Processus : Mise à jour (Edit ou Reception ou Reception PT) Reseaux Appro ...
        if    blnMiseAJourEdit
           or blnMiseAJourReception
           or blnMiseAJourReceptionPT then
          -- Repère: A3
          if lLotInProdQty = lSumDetailBalanceQty then
            if not(lbCoupledGoodExist) then
              -- Processus : Suppression Reseaux Appro Détail ...
              -- Uniquement pour les lignes d'appro avec Caractérisations = toutes NULL
              -- avec Historisation ...
              ReseauApproFAL_Detail_SupprNul(aLotID, 1);
            end if;
          else
            ReseauApproDetailFAL_MAJ(aLotID, aDefaultStockID, aDefaultLocationID, 1, AStockPositionIDList);
          end if;
        else
          if blnMiseAJourReceptionPT then
            ReseauApproFAL_MAJ(aLotID, aDefaultStockID, aDefaultLocationID, 3, AStockPositionIDList);
          end if;
        end if;
      else
        -- Processus : Suppression Reseaux Appro Détail ...
        -- Uniquement pour les lignes d'appro avec Caractérisations = toutes NULL
        -- avec Historisation ...
        ReseauApproFAL_Detail_SupprNul(ALotID, 1);
      end if;

      if not(lbCoupledGoodExist) then
        -- Processus : Suppression Reseaux Appro Détail ...
        -- Uniquement pour les lignes d'appro inexistante dans DétailLot ...
        -- La procédure stockée se charge de contrôler l'absence du jeu de caractérisations dans les DétailsLot ...
        ReseauApproFAL_Detail_Suppr(ALotID, 1);
      end if;

      -- Processus : Mise à jour (Edit ou Reception ou Reception PT) Reseaux Appro Détail ...
      -- La procédure stockée se charge de supprimer les records si la QtéSolde = 0
      -- Suppression possible avec historisation ...
      if blnMiseAJourEdit then
        ReseauApproFAL_Detail_MAJ(ALotID, ADefaultStockID, ADefaultLocationID, 1, 1, 1, AStockPositionIDList);
      elsif blnMiseAJourReception then
        ReseauApproFAL_Detail_MAJ(ALotID, ADefaultStockID, ADefaultLocationID, 4, 1, 1, AStockPositionIDList);
      elsif blnMiseAJourReceptionPT then
        ReseauApproFAL_Detail_MAJ(ALotID, ADefaultStockID, ADefaultLocationID, 3, 1, 1, AStockPositionIDList);
      end if;
    end if;
  end;

  /***
  * procedure MiseAJourReseaux
  *
  * Procédure générale de mise à jour des réseaux
  */
  procedure MiseAJourReseaux(ALotID in TTypeID, AContext in integer, AStockPositionIDList in varchar2)
  is
    idDefaultStockID    TTypeID;
    idDefaultLocationID TTypeID;
  begin
    if ALotID is null then
      raise_application_error(-20001, 'LotID must be supplied');
    end if;

    -- Détermine si la production gère les réseaux
    if IsFALNetworkEnabled then
      -- Détermine le stock et l'emplacement par défaut
      idDefaultStockID  := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_NETWORK');

      if idDefaultStockID is null then
        idDefaultLocationID  := null;
      else
        idDefaultLocationID  := FAL_TOOLS.GetConfig_LocationID('PPS_DefltLOCATION_NETWORK', idDefaultStockID);
      end if;

      -- MAJ Réseaux pour une proposition de fabrication
      if    aContext = NcPlanificationLotprop
         or aContext = ncMiseAJourLotProp then
        MiseAJourReseauAppro(ALotID, AContext, idDefaultStockID, idDefaultLocationID, AStockPositionIDList);
      else
        -- MAJ des réseaux pour un lot de fabrication
        -- Création des approvisionnements
        if IsLotHasNetworkDetails(ALotID) = 1 then
          -- Avec détails lots
          MiseAJourReseauApproDetail(ALotID, AContext, idDefaultStockID, idDefaultLocationID, AStockPositionIDList);
        else
          -- Sans détails lots
          MiseAJourReseauAppro(ALotID, AContext, idDefaultStockID, idDefaultLocationID, AStockPositionIDList);
        end if;
      end if;

      -- Création des besoins à partir de FAL_LOT_MATERIAL_LINK
      MiseAJourReseauBesoin(ALotID, AContext, idDefaultStockID, idDefaultLocationID);
    end if;
  end;

--------------------------------------------------------------------------------
-- MiseAJourReseauAppro --------------------------------------------------------
--------------------------------------------------------------------------------
-- Mise à jour des Réseaux Approvisionnement
--------------------------------------------------------------------------------
  procedure MiseAJourReseauAppro(
    ALotID               in TTypeID
  , AContext             in integer
  , ADefaultStockID      in TTypeID
  , ADefaultLocationID   in TTypeID
  , AStockPositionIDList in varchar2
  )
  is
    blnCreation             boolean;
    blnSuppression          boolean;
    blnMiseAJour            boolean;
    blnMiseAJourReceptionPT boolean;
    blnMiseAJourDate        boolean;
    blnMiseAJourDateLotProp boolean;
    blnMiseAJourLotProp     boolean;
  begin
    blnMiseAJourDateLotProp  := Acontext in(ncPlanificationLotProp);
    blnMiseAJourLotProp      := Acontext in(ncMiseAJourLotProp);
    blnCreation              := AContext in(ncCreationLot, ncSuiviAvancementSuppression);
    blnSuppression           := AContext in(ncSuppressionLot, ncReceptionPT, ncSolderLot, ncReceptionRebut, ncDemontagePT, ncSuiviAvancementCreation);
    blnMiseAJour             := AContext in(ncModificationLot, ncReceptionRebut, ncDemontagePT, ncSuiviAvancementCreation, ncSuiviAvancementSuppression);
    blnMiseAJourReceptionPT  := AContext in(ncReceptionPT);
    blnMiseAJourDate         := AContext in(ncLancementLot, ncPlannificationLot);

    -- MAJ des réseaux de proposition de lot
    if    blnMiseAJourDateLotProp
       or blnMiseAJourLotProp then
      ReseauApproPropositionFAL_MAJ(aLotID, aContext);
    elsif     (blnCreation)
          and (not blnSuppression)
          and (not blnMiseAJour)
          and (not blnMiseAJourReceptionPT)
          and (not blnMiseAJourDate)
          and (not blnMiseAJourDateLotProp)
          and (not blnMiseAJourLotProp) then
      -- Processus : Création Réseaux Appro ...
      ReseauApproFAL_Creation(ALotID, ADefaultStockID, ADefaultLocationID);
    elsif     (not blnCreation)
          and (not blnSuppression)
          and (not blnMiseAJour)
          and (not blnMiseAJourReceptionPT)
          and (blnMiseAJourDate)
          and (not blnMiseAJourDateLotProp)
          and (not blnMiseAJourLotProp) then
      -- Processus : Mise à jour Date Réseaux Appro ...
      ReseauApproFAL_MAJ(ALotID, ADefaultStockID, ADefaultLocationID, 2, AStockPositionIDList);
    elsif     (not blnCreation)
          and (not blnSuppression)
          and (blnMiseAJour)
          and (not blnMiseAJourReceptionPT)
          and (not blnMiseAJourDate)
          and (not blnMiseAJourDateLotProp)
          and (not blnMiseAJourLotProp) then
      -- Processus : Suppression sans historisation des DétailLot existants ...
      -- Pas d'historisation ...
      ReseauApproFAL_Detail_SupprAll(ALotID, 0);

      -- Modif pour assistant caractérisation
      -- Si la qté en fabrication du lot en cours est > 0
      if     GetLOT_INPROD_QTY(aLotID) > 0
         and not(ExistApproCaracterisePourLot(aLotID) ) then
        ReseauApproFAL_Creation(aLotID, aDefaultStockID, aDefaultLocationID);
      end if;

      -- Processus : Mise à jour Réseaux Appro ...
      ReseauApproFAL_MAJ(ALotID, ADefaultStockID, ADefaultLocationID, 1, AStockPositionIDList);
    elsif     (not blnCreation)
          and (blnSuppression)
          and (not blnMiseAJour)
          and (not blnMiseAJourReceptionPT)
          and (not blnMiseAJourDate)
          and (not blnMiseAJourDateLotProp)
          and (not blnMiseAJourLotProp) then
      -- Processus : Suppression Réseaux Appro ...
      -- avec historisation ...
      ReseauApproFAL_Suppr(ALotID, 1);
    elsif     (not blnCreation)
          and (blnSuppression)
          and (not blnMiseAJour)
          and (blnMiseAJourReceptionPT)
          and (not blnMiseAJourDate)
          and (not blnMiseAJourDateLotProp)
          and (not blnMiseAJourLotProp) then
      -- Vérifier la quantité en fabrication du lot ...
      if GetLotInProdQty(ALotID) = 0 then
        -- Processus : Mise à Jour Reception PT Reseaux Appro
        ReseauApproFAL_MAJ(ALotID, ADefaultStockID, ADefaultLocationID, 3, AStockPositionIDList);
        -- Processus : Suppression Reseaux Appro
        -- avec historisation ...
        ReseauApproFAL_Suppr(ALotID, 1);
      else
        -- Processus : Mise à Jour Reception PT Reseaux Appro
        ReseauApproFAL_MAJ(ALotID, ADefaultStockID, ADefaultLocationID, 3, AStockPositionIDList);
      end if;
    elsif     (not blnCreation)
          and (blnSuppression)
          and (blnMiseAJour)
          and (not blnMiseAJourReceptionPT)
          and (not blnMiseAJourDate)
          and (not blnMiseAJourDateLotProp)
          and (not blnMiseAJourLotProp) then
      -- Vérifier la quantité en fabrication du lot ...
      if (GetLotInProdQty(ALotID) = 0) then
        -- Processus : Mise à Jour Reseaux Appro
        ReseauApproFAL_MAJ(ALotID, ADefaultStockID, ADefaultLocationID, 1, AStockPositionIDList);
        -- Processus : Suppression Reseaux Appro
        -- avec historisation ...
        ReseauApproFAL_Suppr(ALotID, 1);
      else
        -- Processus : Mise à Jour Reseaux Appro
        ReseauApproFAL_MAJ(ALotID, ADefaultStockID, ADefaultLocationID, 1, AStockPositionIDList);
      end if;
    elsif     (blnCreation)
          and (not blnSuppression)
          and (blnMiseAJour)
          and (not blnMiseAJourReceptionPT)
          and (not blnMiseAJourDate)
          and (not blnMiseAJourDateLotProp)
          and (not blnMiseAJourLotProp) then
      -- Le Lot existe-t'il dans les réseaux appro ? ...
      if IsLotExistInNetworkSupply(ALotID) then
        -- Processus : Mise à Jour Reseaux Appro
        ReseauApproFAL_MAJ(ALotID, ADefaultStockID, ADefaultLocationID, 1, AStockPositionIDList);
      else
        -- Processus : Création Réseaux Appro ...
        ReseauApproFAL_Creation(ALotID, ADefaultStockID, ADefaultLocationID);

        -- Si Création de réseau après suppression de suivi d'avancement, alors mise à jour
        if AContext = ncSuiviAvancementSuppression then
          ReseauApproFAL_MAJ(ALotID, ADefaultStockID, ADefaultLocationID, 1, AStockPositionIDList);

          -- Si Qté en fabrication = 0 --> suppression du réseau
          if (GetLotInProdQty(ALotID) = 0) then
            ReseauApproFAL_Suppr(ALotID, 1);
          end if;
        end if;
      end if;
    end if;
  end;

--------------------------------------------------------------------------------
-- Mise à jour des Réseaux Besoin
--------------------------------------------------------------------------------
  procedure MiseAJourReseauBesoin(ALotID in TTypeID, AContext in integer, ADefaultStockID in TTypeID, ADefaultLocationID in TTypeID)
  is
    blnCreation                  boolean;
    blnSuppressionEnregistrement boolean;
    blnSuppressionTotale         boolean;
    blnMiseAJour                 boolean;
    blnMiseAJourDate             boolean;
    blnMiseAJourDateLotProp      boolean;
  begin
    blnMiseAJourDateLotProp       := Acontext in(ncPlanificationLotProp);
    blnCreation                   :=
      AContext in
        (ncCreationLot
       , ncModificationLot
       , ncReceptionPT
       , ncReceptionRebut
       , ncDemontagePT
       , ncSuiviAvancementSuppression
       , ncSortieComposant
       , ncRetourComposant
       , ncRemplacementComposant
       , ncAffectationComposantLotStock
        );
    blnSuppressionEnregistrement  :=
      AContext in
        (ncModificationLot
       , ncLancementLot
       , ncReceptionPT
       , ncReceptionRebut
       , ncDemontagePT
       , ncSuiviAvancementCreation
       , ncSortieComposant
       , ncRemplacementComposant
       , ncAffectationComposantStockLot
        );
    blnSuppressionTotale          := AContext in(ncSuppressionLot, ncSolderLot);
    blnMiseAJour                  :=
      AContext in
        (ncModificationLot
       , ncLancementLot
       , ncReceptionPT
       , ncReceptionRebut
       , ncDemontagePT
       , ncSuiviAvancementCreation
       , ncSuiviAvancementSuppression
       , ncSortieComposant
       , ncRetourComposant
       , ncRemplacementComposant
       , ncAffectationComposantStockLot
       , ncAffectationComposantLotStock
        );
    blnMiseAJourDate              := AContext in(ncPlannificationLot);

    if blnMiseAJourDateLotProp then
      -- Mise à jour réseaux proposition d'appro Fabrication (Après planification).
      ReseauBesoinPropositionFAL_MAJ(ALotID);
    elsif     (not blnCreation)
          and (not blnSuppressionEnregistrement)
          and (not blnSuppressionTotale)
          and (not blnMiseAJour)
          and (not blnMiseAJourDateLotProp)
          and (blnMiseAJourDate) then
      -- Processus : Mise à jour Date Réseaux Besoins ...
      -- Pous tous les composants ...
      -- Pas de suppression si QteBesoinCPT = 0 ...
      ReseauBesoinFAL_MAJ(ALotID, ADefaultStockID, ADefaultLocationID, 2, 0);
    elsif     (not blnCreation)
          and (not blnSuppressionEnregistrement)
          and (blnSuppressionTotale)
          and (not blnMiseAJour)
          and (not blnMiseAJourDateLotProp)
          and (not blnMiseAJourDate) then
      -- Processus : Suppression totale Réseaux Besoins ...
      ReseauBesoinFAL_SupprAll(ALotID);
    elsif     (blnCreation)
          and (not blnSuppressionEnregistrement)
          and (not blnSuppressionTotale)
          and (not blnMiseAJour)
          and (not blnMiseAJourDateLotProp)
          and (not blnMiseAJourDate) then
      -- Processus : Création Réseaux Besoins ...
      -- pour tous les composants ...
      ReseauBesoinFAL_Creation(ALotID, ADefaultStockID, ADefaultLocationID);
    elsif     (blnCreation)
          and (not blnSuppressionEnregistrement)
          and (not blnSuppressionTotale)
          and (blnMiseAJour)
          and (not blnMiseAJourDateLotProp)
          and (not blnMiseAJourDate) then
      -- Processus : Mise à jour Réseaux Besoins ...
      -- pour tous les composants existants  ...
      -- Pas de suppression si QteBesoinCPT = 0 ...
      ReseauBesoinFAL_MAJ(ALotID, ADefaultStockID, ADefaultLocationID, 1, 0);
      -- Processus : Création Réseaux Besoins ...
      -- pour tous les composants inexistants dans les réseaux besoin...
      -- (la procédure stockée se charge de vérifier l'absence de record dans FAL_NETWORK_NEED)
      ReseauBesoinFAL_Creation(ALotID, ADefaultStockID, ADefaultLocationID);
    elsif     (not blnCreation)
          and (blnSuppressionEnregistrement)
          and (not blnSuppressionTotale)
          and (blnMiseAJour)
          and (not blnMiseAJourDateLotProp)
          and (not blnMiseAJourDate) then
      -- Processus : Mise à jour Réseaux Besoins ...
      -- La procédure stockée se charge de supprimer le record si Composant->QteBesoinCPT = 0
      -- Suppression si QteBesoinCPT = 0 ...
      ReseauBesoinFAL_MAJ(ALotID, ADefaultStockID, ADefaultLocationID, 1, 1);
    elsif     (blnCreation)
          and (blnSuppressionEnregistrement)
          and (not blnSuppressionTotale)
          and (blnMiseAJour)
          and (not blnMiseAJourDateLotProp)
          and (not blnMiseAJourDate) then
      -- Processus : Suppression Réseaux Besoins inexistants...
      -- (Suppression des records de FAL_NETWORK_NEED sans lien avec un composant existant)
      ReseauBesoinFAL_SupprOld(ALotID);
      -- Processus : Mise à jour Réseaux Besoins ...
      -- La procédure stockée se charge de supprimer le record si Composant->QteBesoinCPT <= 0
      -- Suppression si QteBesoinCPT = 0 ...
      ReseauBesoinFAL_MAJ(ALotID, ADefaultStockID, ADefaultLocationID, 1, 1);
      -- Processus : Création Réseaux Besoins ...
      -- pour tous les composants inexistants dans les réseaux besoin...
      -- (la procédure stockée se charge de vérifier l'absence de record dans FAL_NETWORK_NEED)
      ReseauBesoinFAL_Creation(ALotID, ADefaultStockID, ADefaultLocationID);
    end if;
  end;

-- PROCEDURE ReseauApproFAL_Historisation ()
--
-- Insere dans la table d'historisation des Appros un record donné de la table des Appros
  procedure ReseauApproFAL_Historisation(aID in TTypeID)
  is
  begin
    null;
  end;

-- PROCEDURE ReseauBesoinFAL_Historisation ()
--
-- Insere dans la table d'historisation des Besoins un record donné de la table des Besoins
  procedure ReseauBesoinFAL_Historisation(aID in TTypeID)
  is
  begin
    null;
  end;

-- PROCEDURE ReseauApproFAL_Creation ()
--
-- Création d'un enregistrement dans FAL_NETWORK_SUPPLY à partir d'un lot de fabrication
  procedure ReseauApproFAL_Creation(aLotID in TTypeID, aDefaultStockID in TTypeID, aDefaultLocationID in TTypeID)
  is
    -- Record du lot concerné
    aLotConcerne GetLotRecord%rowtype;
    -- StockID défini pour l'insertion
    aStockID     TTypeID;
    -- LocationID défini pour l'insertion
    aLocationID  TTypeID;
    -- Qte Solde
    aQteSolde    FAL_NETWORK_SUPPLY.FAN_BALANCE_QTY%type;
  begin
    -- Ouverture du curseur sur le lot et renseigner aLotConcerne
    open GetLotRecord(aLotID);

    fetch GetLotRecord
     into aLotConcerne;

    -- S'assurer qu'il y ai un enregistrement ...
    -- On ne crée pas d'appro pour les lot de type SAV
    if     GetLotRecord%found
       and (nvl(aLotConcerne.C_FAB_TYPE, '0') <> '3') then
      -- Déterminer le STOCK et l'EMPLACEMENT à stocker dans les réseaux -----------------------------------------
      aStockID     := aLotConcerne.STM_STOCK_ID;
      aLocationID  := aLotConcerne.STM_LOCATION_ID;
      SetDefaultStockAndLocation(aStockID, aLocationID, aDefaultStockID, aDefaultLocationID);

      -- Déterminer la quantité Solde ----------------------------------------------------------------------------
      if nvl(aLotConcerne.LOT_REJECT_PLAN_QTY, 0) <=
           (nvl(aLotConcerne.LOT_REJECT_RELEASED_QTY, 0) +
            nvl(aLotConcerne.LOT_DISMOUNTED_QTY, 0) +
            nvl(aLotConcerne.LOT_PT_REJECT_QTY, 0) +
            nvl(aLotConcerne.LOT_CPT_REJECT_QTY, 0)
           ) then
        aQteSolde  := aLotConcerne.LOT_INPROD_QTY;
      else
        aQteSolde  := aLotConcerne.LOT_ASKED_QTY;
      end if;

      -- Insertion dans FAL_NETWORK_SUPPLY -----------------------------------------------------------------------
      insert into FAL_NETWORK_SUPPLY
                  (
                   -- ID principal
                   FAL_NETWORK_SUPPLY_ID
                 ,
                   -- Date de création
                   A_DATECRE
                 ,
                   -- User Création
                   A_IDCRE
                 ,
                   -- ID Lot
                   FAL_LOT_ID
                 ,
                   -- Produit
                   GCO_GOOD_ID
                 ,
                   -- Description
                   FAN_DESCRIPTION
                 ,
                   -- Dossier
                   DOC_RECORD_ID
                 ,
                   -- Debut Planif
                   FAN_BEG_PLAN
                 ,
                   -- Fin Planif
                   FAN_END_PLAN
                 ,
                   -- Debut Planif 1
                   FAN_BEG_PLAN1
                 ,
                   -- Fin Planif 1
                   FAN_END_PLAN1
                 ,
                   -- Debut Reel
                   FAN_REAL_BEG
                 ,
                   -- Duree plannifiee
                   FAN_PLAN_PERIOD
                 ,
                   -- Stock
                   STM_STOCK_ID
                 ,
                   -- Emplacement de stock
                   STM_LOCATION_ID
                 ,
                   -- Intitule gabarit
                   C_GAUGE_TITLE
                 ,
                   -- Qte prevue
                   FAN_PREV_QTY
                 ,
                   -- Qte Rebut prévue
                   FAN_SCRAP_QTY
                 ,
                   -- Qte Totale
                   FAN_FULL_QTY
                 ,
                   -- Qte Realisee
                   FAN_REALIZE_QTY
                 ,
                   -- Qte Supplémentaire
                   FAN_EXCEED_QTY
                 ,
                   -- Qte Dechargée
                   FAN_DISCHARGE_QTY
                 ,
                   -- Qte Rebut Realise
                   FAN_SCRAP_REAL_QTY
                 ,
                   -- Qte Retour
                   FAN_RETURN_QTY
                 ,
                   -- qte Solde
                   FAN_BALANCE_QTY
                 ,
                   -- Qte Libre
                   FAN_FREE_QTY
                 ,
                   -- Qte Att Stock
                   FAN_STK_QTY
                 ,
                   -- Qte Att Besoin Appro
                   FAN_NETW_QTY
                  )
           values (GetNewId
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                 ,
                   -- ID Lot
                   aLotID
                 ,
                   -- Produit
                   aLotConcerne.GCO_GOOD_ID
                 ,
                   -- Description
                   aLotConcerne.LOT_REFCOMPL
                 ,
                   -- Dossier
                   aLotConcerne.DOC_RECORD_ID
                 ,
                   -- Debut Planif
                   aLotConcerne.LOT_PLAN_BEGIN_DTE
                 ,
                   -- Fin Planif
                   aLotConcerne.LOT_PLAN_END_DTE
                 ,
                   -- Debut Planif 1
                   aLotConcerne.LOT_PLAN_BEGIN_DTE
                 ,
                   -- Fin Planif 1
                   aLotConcerne.LOT_PLAN_END_DTE
                 ,
                   -- Debut Reel
                   aLotConcerne.LOT_OPEN__DTE
                 ,
                   -- Duree plannifiee
                   aLotConcerne.LOT_PLAN_LEAD_TIME
                 ,
                   -- Stock
                   aStockID
                 ,
                   -- Emplacement de stock
                   aLocationID
                 ,
                   -- Intitule gabarit = dcLotFabrication
                   '13'
                 ,
                   -- Qte prevue
                   aLotConcerne.LOT_ASKED_QTY
                 ,
                   -- Qte Rebut prévue
                   aLotConcerne.LOT_REJECT_PLAN_QTY
                 ,
                   -- Qte Totale
                   aLotConcerne.LOT_TOTAL_QTY
                 ,
                   -- Qte Realisee
                   0
                 ,
                   -- Qte Supplémentaire
                   0
                 ,
                   -- Qte Dechargée
                   0
                 ,
                   -- Qte Rebut Realise
                   0
                 ,
                   -- Qte Retour
                   0
                 ,
                   -- Qte Solde
                   aQteSolde
                 ,
                   -- Qte Libre
                   aLotConcerne.LOT_ASKED_QTY
                 ,
                   -- Qte Att Stock
                   0
                 ,
                   -- Qte Att Besoin Appro
                   0
                  );
    -- FIN : S'assurer qu'il y ai un enregistrement ...
    end if;

    -- fermeture du curseur sur le lot concerné
    close GetLotRecord;
  end;

-- PROCEDURE ReseauApproFAL_Suppr ()
--
-- Suppression des enregistrements dans les Appros correspondant au LotID donné avec historisation eventuelle
  procedure ReseauApproFAL_Suppr(iLotID in TTypeID, iHistorisation in integer, iGoodID in TTypeID default null)
  is
    curSupplyRecords sys_refcursor;
    lnSupplyID       FAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID%type;
  begin
    -- Lecture de plusieurs enregistrement de FAL_NETWORK_SUPPLY
    if iGoodID is not null then
      open curSupplyRecords for
        select FAL_NETWORK_SUPPLY_ID
          from FAL_NETWORK_SUPPLY
         where FAL_LOT_ID = iLotID
           and GCO_GOOD_ID = iGoodID;
    else
      open curSupplyRecords for
        select FAL_NETWORK_SUPPLY_ID
          from FAL_NETWORK_SUPPLY
         where FAL_LOT_ID = iLotID;
    end if;

    loop
      fetch curSupplyRecords
       into lnSupplyID;

      exit when curSupplyRecords%notfound;

      -- Historisation ...
      if iHistorisation > 0 then
        -- Historisation de tous les appros concernés ...
        ReseauApproFAL_Historisation(lnSupplyID);
      end if;

      -- Suppression Attributions Appro Stock ...
      Attribution_Suppr_ApproStock(lnSupplyID);
      -- Suppression Attributions Appro Besoin ...
      Attribution_Suppr_ApproBesoin(lnSupplyID);
    end loop;

    close curSupplyRecords;

    -- Suppression des appros ...
    if iGoodID is not null then
      delete from FAL_NETWORK_SUPPLY
            where FAL_LOT_ID = iLotID
              and GCO_GOOD_ID = iGoodID;
    else
      delete from FAL_NETWORK_SUPPLY
            where FAL_LOT_ID = iLotID;
    end if;
  end;

-- PROCEDURE ReseauApproFAL_MAJ ()
--
-- Mise à jour complète d'un enregistrement dans FAL_NETWORK_SUPPLY à partir d'un lot de fabrication donné
-- Le paramètre aUpdateType vaut :
--  1 : Mise à jour complète
--  2 : Mise à jour Date
--  3 : Mise à jour Reception PT
  procedure ReseauApproFAL_MAJ(
    aLotID             in TTypeID
  , aDefaultStockID    in TTypeID
  , aDefaultLocationID in TTypeID
  , aUpdateType        in integer
  , aStockPositionID   in varchar2
  )
  is
    -- Record du lot concerné
    aLotConcerne   GetLotRecord%rowtype;
    -- Record du Appro concerné
    aApproConcerne GetSupplyRecordNullForUpdate%rowtype;
    -- StockID défini pour l'insertion
    aStockID       TTypeID;
    -- LocationID défini pour l'insertion
    aLocationID    TTypeID;
    -- Date debut Planif
    aDebutPlanif   TTypeDate;
    -- Date fin Planif
    aFinPlanif     TTypeDate;
    -- Date debut Planif 2, 3, 4
    aDebutPlanif2  TTypeDate;
    aDebutPlanif3  TTypeDate;
    aDebutPlanif4  TTypeDate;
    -- Date fin Planif 2, 3, 4
    aFinPlanif2    TTypeDate;
    aFinPlanif3    TTypeDate;
    aFinPlanif4    TTypeDate;
    -- Qte Rebut Realise
    aRebutRealise  FAL_NETWORK_SUPPLY.FAN_SCRAP_REAL_QTY%type;
    -- Qte Solde
    aQteSolde      FAL_NETWORK_SUPPLY.FAN_BALANCE_QTY%type;
    -- Qte Libre
    aQteLibre      FAL_NETWORK_SUPPLY.FAN_FREE_QTY%type;
    -- Qte Attribue sur stock
    aQteAttStock   FAL_NETWORK_SUPPLY.FAN_STK_QTY%type;
    -- Qte attribue sur besoin appro
    aQteAttBesoin  FAL_NETWORK_SUPPLY.FAN_NETW_QTY%type;
  begin
    -- Ouverture du curseur sur le lot et renseigner aLotConcerne
    open GetLotRecord(aLotID);

    fetch GetLotRecord
     into aLotConcerne;

    -- S'assurer qu'il y ai un enregistrement Lot ...
    if GetLotRecord%found then
      -- Ouverture du curseur sur l'appro et renseigner aLotConcerne
      open GetSupplyRecordNullForUpdate(aLotID);

      fetch GetSupplyRecordNullForUpdate
       into aApproConcerne;

      -- S'assurer qu'il y ai un enregistrement Appro ...
      if GetSupplyRecordNullForUpdate%found then
        -- Initialiser les valeurs ---------------------------------------------------------------------------------
        aDebutPlanif   := aLotConcerne.LOT_PLAN_BEGIN_DTE;
        aFinPlanif     := aLotConcerne.LOT_PLAN_END_DTE;
        aDebutPlanif2  := aApproConcerne.FAN_BEG_PLAN2;
        aDebutPlanif3  := aApproConcerne.FAN_BEG_PLAN3;
        aDebutPlanif4  := aApproConcerne.FAN_BEG_PLAN4;
        aFinPlanif2    := aApproConcerne.FAN_END_PLAN2;
        aFinPlanif3    := aApproConcerne.FAN_END_PLAN3;
        aFinPlanif4    := aApproConcerne.FAN_END_PLAN4;
        aRebutRealise  := aApproConcerne.FAN_SCRAP_REAL_QTY;
        aQteSolde      := aApproConcerne.FAN_BALANCE_QTY;
        aQteLibre      := aApproConcerne.FAN_FREE_QTY;
        aQteAttStock   := aApproConcerne.FAN_STK_QTY;
        aQteAttBesoin  := aApproConcerne.FAN_NETW_QTY;
        -- Déterminer le STOCK et l'EMPLACEMENT à stocker dans les réseaux -----------------------------------------
        aStockID       := aLotConcerne.STM_STOCK_ID;
        aLocationID    := aLotConcerne.STM_LOCATION_ID;
        SetDefaultStockAndLocation(aStockID, aLocationID, aDefaultStockID, aDefaultLocationID);

        -- Déterminer les valeurs à modifier selon la valeur de aUpdateType (voir en-tête) -------------------------
        if    (aUpdateType = 1)
           or   -- Mise à jour complète ...
              (aUpdateType = 2) then   -- Mise à jour date ...
          -- Déterminer la date de début plannifiée 2 ----------------------------------------------------------------
          if aApproConcerne.FAN_BEG_PLAN2 is null then
            if (    (aApproConcerne.FAN_BEG_PLAN1 <> aDebutPlanif)
                or (aApproConcerne.FAN_END_PLAN1 <> aFinPlanif) ) then
              aDebutPlanif2  := aDebutPlanif;
            else
              aDebutPlanif2  := null;
            end if;
          end if;

          -- Déterminer la date de début plannifiée 3 ----------------------------------------------------------------
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

          -- Déterminer la date de début plannifiée 4 ----------------------------------------------------------------
          if aApproConcerne.FAN_BEG_PLAN3 is not null then
            if (    (aApproConcerne.FAN_BEG_PLAN3 <> aDebutPlanif)
                or (aApproConcerne.FAN_END_PLAN3 <> aFinPlanif) ) then
              aDebutPlanif4  := aDebutPlanif;
            end if;
          end if;

          -- Déterminer la date de fin plannifiée 2 ----------------------------------------------------------------
          if aApproConcerne.FAN_END_PLAN2 is null then
            if (    (aApproConcerne.FAN_BEG_PLAN1 <> aDebutPlanif)
                or (aApproConcerne.FAN_END_PLAN1 <> aFinPlanif) ) then
              aFinPlanif2  := aFinPlanif;
              -- Mise à jour Attribution Date Appro ...
              Attribution_MAJ_DateAppro(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aFinPlanif);
            else
              aFinPlanif2  := null;
            end if;
          end if;

          -- Déterminer la date de fin plannifiée 3 ----------------------------------------------------------------
          if aApproConcerne.FAN_END_PLAN2 is not null then
            if aApproConcerne.FAN_END_PLAN3 is null then
              if (    (aApproConcerne.FAN_BEG_PLAN2 <> aDebutPlanif)
                  or (aApproConcerne.FAN_END_PLAN2 <> aFinPlanif) ) then
                aFinPlanif3  := aFinPlanif;
                -- Mise à jour Attribution Date Appro ...
                Attribution_MAJ_DateAppro(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aFinPlanif);
              else
                aFinPlanif3  := null;
              end if;
            end if;
          end if;

          -- Déterminer la date de fin plannifiée 4 ----------------------------------------------------------------
          if aApproConcerne.FAN_END_PLAN3 is not null then
            if (    (aApproConcerne.FAN_BEG_PLAN3 <> aDebutPlanif)
                or (aApproConcerne.FAN_END_PLAN3 <> aFinPlanif) ) then
              aFinPlanif4  := aFinPlanif;
              -- Mise à jour Attribution Date Appro ...
              Attribution_MAJ_DateAppro(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aFinPlanif);
            end if;
          end if;
        -- FIN : if (aUpdateType = 1) OR (aUpdateType = 2) ...
        end if;

        -- Déterminer la Qte Rebut Realise -------------------------------------------------------------------------
        if (aUpdateType = 1) then   -- Mise à jour complète ...
          aRebutRealise  :=
            nvl(aLotConcerne.LOT_REJECT_RELEASED_QTY, 0) +
            nvl(aLotConcerne.LOT_DISMOUNTED_QTY, 0) +
            nvl(aLotConcerne.LOT_PT_REJECT_QTY, 0) +
            nvl(aLotConcerne.LOT_CPT_REJECT_QTY, 0);
        end if;

        -- Déterminer la Qte Solde ---------------------------------------------------------------------------------
        if    (aUpdateType = 1)
           or   -- Mise à jour complète ...
              (aUpdateType = 3) then   -- Mise à jour Réception PT ...
          if nvl(aLotConcerne.LOT_REJECT_PLAN_QTY, 0) <=
               (nvl(aLotConcerne.LOT_REJECT_RELEASED_QTY, 0) +
                nvl(aLotConcerne.LOT_DISMOUNTED_QTY, 0) +
                nvl(aLotConcerne.LOT_PT_REJECT_QTY, 0) +
                nvl(aLotConcerne.LOT_CPT_REJECT_QTY, 0)
               ) then
            aQteSolde  := aLotConcerne.LOT_INPROD_QTY;
          else
            aQteSolde  := least(aLotConcerne.LOT_ASKED_QTY - aLotConcerne.LOT_RELEASED_QTY, aLotConcerne.LOT_INPROD_QTY);

            if aQteSolde < 0 then
              aQteSolde  := 0;
            end if;
          end if;
        end if;

        if (aUpdateType = 1) then   -- Mise à jour complète ...
          -- Déterminer la Qte libre ---------------------------------------------------------------------------------
          if (nvl(aApproConcerne.FAN_FREE_QTY, 0) + nvl(aApproConcerne.FAN_NETW_QTY, 0) + nvl(aApproConcerne.FAN_STK_QTY, 0) ) < nvl(aQteSolde, 0) then
            aQteLibre  := nvl(aQteSolde, 0) - nvl(aApproConcerne.FAN_NETW_QTY, 0) - nvl(aApproConcerne.FAN_STK_QTY, 0);
          else
            if (nvl(aApproConcerne.FAN_FREE_QTY, 0) + nvl(aApproConcerne.FAN_NETW_QTY, 0) + nvl(aApproConcerne.FAN_STK_QTY, 0) ) > nvl(aQteSolde, 0) then
              if (nvl(aApproConcerne.FAN_NETW_QTY, 0) + nvl(aApproConcerne.FAN_STK_QTY, 0) ) < nvl(aQteSolde, 0) then
                aQteLibre  := nvl(aQteSolde, 0) - nvl(aApproConcerne.FAN_NETW_QTY, 0) - nvl(aApproConcerne.FAN_STK_QTY, 0);
              else
                aQteLibre  := 0;
              end if;
            end if;
          end if;

          -- Déterminer la Qte attribuée sur Stock -------------------------------------------------------------------
          if (nvl(aApproConcerne.FAN_FREE_QTY, 0) + nvl(aApproConcerne.FAN_NETW_QTY, 0) + nvl(aApproConcerne.FAN_STK_QTY, 0) ) > nvl(aQteSolde, 0) then
            if (nvl(aApproConcerne.FAN_NETW_QTY, 0) + nvl(aApproConcerne.FAN_STK_QTY, 0) ) >= nvl(aQteSolde, 0) then
              if (nvl(aApproConcerne.FAN_NETW_QTY, 0) ) < nvl(aQteSolde, 0) then
                aQteAttStock  := nvl(aQteSolde, 0) - nvl(aApproConcerne.FAN_NETW_QTY, 0);
                -- Mise à jour Attributions Appro-Stock ...
                Attribution_MAJ_ApproStock(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aApproConcerne.FAN_STK_QTY, aQteAttStock);
              else
                aQteAttStock  := 0;
                -- Suppression Attributions Appro-Stock ...
                Attribution_Suppr_ApproStock(aApproConcerne.FAL_NETWORK_SUPPLY_ID);
              end if;
            end if;
          end if;

          -- Déterminer la Qte attribuée Appro Besoin ----------------------------------------------------------------
          if (nvl(aApproConcerne.FAN_FREE_QTY, 0) + nvl(aApproConcerne.FAN_NETW_QTY, 0) + nvl(aApproConcerne.FAN_STK_QTY, 0) ) > nvl(aQteSolde, 0) then
            if (nvl(aApproConcerne.FAN_NETW_QTY, 0) + nvl(aApproConcerne.FAN_STK_QTY, 0) ) >= nvl(aQteSolde, 0) then
              if (nvl(aApproConcerne.FAN_NETW_QTY, 0) ) >= nvl(aQteSolde, 0) then
                aQteAttBesoin  := aQteSolde;
                -- Mise à jour Attributions Appro-Besoin ...
                Attribution_MAJ_ApproBesoin(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aApproConcerne.FAN_NETW_QTY, aQteAttBesoin);
              end if;
            end if;
          end if;
        -- ELSE : IF (aUpdateType = 1) THEN ...
        else
          if (aUpdateType = 3) then   -- Mise à jour Réception PT ...
            -- Déterminer la Qte attribuée sur Stock ----------------------------------------------------------------
            if (nvl(aApproConcerne.FAN_FREE_QTY, 0) + nvl(aApproConcerne.FAN_NETW_QTY, 0) ) < nvl(aQteSolde, 0) then
              aQteAttStock  := nvl(aQteSolde, 0) - nvl(aApproConcerne.FAN_FREE_QTY, 0) - nvl(aApproConcerne.FAN_NETW_QTY, 0);
              -- Mise à jour Attributions Appro-Stock ...
              Attribution_MAJ_ApproStock(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aApproConcerne.FAN_STK_QTY, aQteAttStock);
            else
              aQteAttStock  := 0;
              -- Suppression Attributions Appro-Stock ...
              Attribution_Suppr_ApproStock(aApproConcerne.FAL_NETWORK_SUPPLY_ID);
            end if;

            -- Déterminer la Qte attribuée Appro Besoin -------------------------------------------------------------
            if (nvl(aApproConcerne.FAN_FREE_QTY, 0) + nvl(aApproConcerne.FAN_NETW_QTY, 0) ) >= nvl(aQteSolde, 0) then
              if (nvl(aApproConcerne.FAN_FREE_QTY, 0) ) < nvl(aQteSolde, 0) then
                aQteAttBesoin  := nvl(aQteSolde, 0) - nvl(aApproConcerne.FAN_FREE_QTY, 0);
                -- Mise à jour Attributions Appro-Besoin ...
                Attrib_MAJ_ApproBesoin_PT(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aApproConcerne.FAN_NETW_QTY, aQteAttBesoin, aStockPositionID);
              else
                aQteAttBesoin  := 0;
                -- Suppression Attributions Appro-Besoin ...
                Attrib_Suppr_ApproBesoin_PT(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aStockPositionID);
              end if;
            end if;

            -- Déterminer la Qte libre ------------------------------------------------------------------------------
            if (nvl(aApproConcerne.FAN_FREE_QTY, 0) + nvl(aApproConcerne.FAN_NETW_QTY, 0) ) >= nvl(aQteSolde, 0) then
              if (nvl(aApproConcerne.FAN_FREE_QTY, 0) ) >= nvl(aQteSolde, 0) then
                aQteLibre  := aQteSolde;
              end if;
            end if;
          -- FIN  : IF (aUpdateType = 3) THEN ...
          end if;
        -- FIN  : IF (aUpdateType = 1) THEN ...
        end if;

        -- Modification de l'appro chargée -------------------------------------------------------------------------
        -- Updater tout quelque soit aUpdateType ...
        update FAL_NETWORK_SUPPLY
           set A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             , A_DATEMOD = sysdate
             ,
               -- Dossier
               DOC_RECORD_ID = aLotConcerne.DOC_RECORD_ID
             ,
               -- Debut Planif
               FAN_BEG_PLAN = aLotConcerne.LOT_PLAN_BEGIN_DTE
             ,
               -- Fin Planif
               FAN_END_PLAN = aLotConcerne.LOT_PLAN_END_DTE
             ,
               -- Debut Planif 2
               FAN_BEG_PLAN2 = aDebutPlanif2
             ,
               -- Debut Planif 3
               FAN_BEG_PLAN3 = aDebutPlanif3
             ,
               -- Debut Planif 4
               FAN_BEG_PLAN4 = aDebutPlanif4
             ,
               -- Fin Planif 2
               FAN_END_PLAN2 = aFinPlanif2
             ,
               -- Fin Planif 3
               FAN_END_PLAN3 = aFinPlanif3
             ,
               -- Fin Planif 4
               FAN_END_PLAN4 = aFinPlanif4
             ,
               -- Debut Reel
               FAN_REAL_BEG = aLotConcerne.LOT_OPEN__DTE
             ,
               -- Duree plannifiee
               FAN_PLAN_PERIOD = aLotConcerne.LOT_PLAN_LEAD_TIME
             ,
               -- Stock
               STM_STOCK_ID = aStockID
             ,
               -- Emplacement de stock
               STM_LOCATION_ID = aLocationID
             ,
               -- Qte prevue
               FAN_PREV_QTY = aLotConcerne.LOT_ASKED_QTY
             ,
               -- Qte Rebut prévue
               FAN_SCRAP_QTY = aLotConcerne.LOT_REJECT_PLAN_QTY
             ,
               -- Qte Totale
               FAN_FULL_QTY = aLotConcerne.LOT_TOTAL_QTY
             ,
               -- Qte Realisee
               FAN_REALIZE_QTY = aLotConcerne.LOT_RELEASED_QTY
             ,
               -- Qte Rebut Realise
               FAN_SCRAP_REAL_QTY = aRebutRealise
             ,
               -- Qte Solde
               FAN_BALANCE_QTY = aQteSolde
             ,
               -- Qte Libre
               FAN_FREE_QTY = aQteLibre
             ,
               -- Qte Att Stock
               FAN_STK_QTY = aQteAttStock
             ,
               -- Qte Att Besoin Appro
               FAN_NETW_QTY = aQteAttBesoin
         where current of GetSupplyRecordNullForUpdate;
      -- FIN :S'assurer qu'il y ai un enregistrement Appro ...
      end if;

      -- Fermeture du curseur sur l'appro
      close GetSupplyRecordNullForUpdate;
    -- FIN : S'assurer qu'il y ai un enregistrement Lot ...
    end if;

    -- fermeture du curseur sur le lot concerné
    close GetLotRecord;
  end;

  /***
  * procedure ReseauApproFAL_Detail_Creation
  *
  * Création de N enregistrements dans FAL_NETWORK_SUPPLY à partir d'un lot de fabrication et de son DétailLot
  * Vérifie egalement l'abscence dans FAL_NETWORK_SUPPLY d'une ligne existante sur le même jeu de caractérisations
  * avant d'ajouter le record
  */
  procedure ReseauApproFAL_Detail_Creation(aLotID in TTypeID, aDefaultStockID in TTypeID, aDefaultLocationID in TTypeID)
  is
    -- StockID défini pour l'insertion
    aStockID                  TTypeID;
    -- LocationID défini pour l'insertion
    aLocationID               TTypeID;
    aQteSolde                 FAL_NETWORK_SUPPLY.FAN_BALANCE_QTY%type;
    aTabCaracterisationID1    TIDArray;
    aTabCaracterisationID2    TIDArray;
    aTabCaracterisationID3    TIDArray;
    aTabCaracterisationID4    TIDArray;
    aTabCaracterisationID5    TIDArray;
    aTabCaracterisationValue1 TStringArray;
    aTabCaracterisationValue2 TStringArray;
    aTabCaracterisationValue3 TStringArray;
    aTabCaracterisationValue4 TStringArray;
    aTabCaracterisationValue5 TStringArray;
    -- Table contenant la somme Qté des Détails
    aTabQte                   TCurrencyArray;
    -- Table contenant la somme QtéRéceptionnée des Détails
    aTabQteReceptionne        TCurrencyArray;
    -- Table contenant la somme QtéAnnulée des Détails
    aTabQteAnnule             TCurrencyArray;
    -- Table contenant la somme QtéSolde des Détails
    aTabQteSolde              TCurrencyArray;
    -- Nombre de lignes des tables ci-dessous
    aTabCount                 integer;
    -- Index de parcours des tables ci-dessous
    aIndex                    integer;

    cursor crBatchDetails
    is
      select distinct LOT.STM_STOCK_ID
                    , LOT.STM_LOCATION_ID
                    , LOT.LOT_REJECT_PLAN_QTY
                    , LOT.LOT_INPROD_QTY
                    , LOT.LOT_REJECT_RELEASED_QTY
                    , LOT.LOT_DISMOUNTED_QTY
                    , LOT.LOT_PT_REJECT_QTY
                    , LOT.LOT_CPT_REJECT_QTY
                    , LOT.LOT_ASKED_QTY
                    , LOT.LOT_RELEASED_QTY
                    , LOT.LOT_PLAN_LEAD_TIME
                    , LOT.LOT_OPEN__DTE
                    , LOT.LOT_PLAN_END_DTE
                    , LOT.LOT_PLAN_BEGIN_DTE
                    , LOT.DOC_RECORD_ID
                    , LOT.LOT_REFCOMPL
                    , DETAIL.GCO_GOOD_ID
                 from FAL_LOT LOT
                    , FAL_LOT_DETAIL DETAIL
                where LOT.FAL_LOT_ID = aLotID
                  and LOT.FAL_LOT_ID = DETAIL.FAL_LOT_ID;
  begin
    for tplBatchDetails in crBatchDetails loop
      -- Déterminer le STOCK et l'EMPLACEMENT à stocker dans les réseaux
      aStockID     := tplBatchDetails.STM_STOCK_ID;
      aLocationID  := tplBatchDetails.STM_LOCATION_ID;
      SetDefaultStockAndLocation(aStockID, aLocationID, aDefaultStockID, aDefaultLocationID);
      -- Déterminer les tableaux DétailLot
      GetLotDetailSums(aLotID
                     , tplBatchDetails.GCO_GOOD_ID
                     , aTabCaracterisationID1
                     , aTabCaracterisationID2
                     , aTabCaracterisationID3
                     , aTabCaracterisationID4
                     , aTabCaracterisationID5
                     , aTabCaracterisationValue1
                     , aTabCaracterisationValue2
                     , aTabCaracterisationValue3
                     , aTabCaracterisationValue4
                     , aTabCaracterisationValue5
                     , aTabQte
                     , aTabQteReceptionne
                     , aTabQteAnnule
                     , aTabQteSolde
                     , aTabCount
                      );

      -- Déterminer la quantité Solde
      if tplBatchDetails.LOT_REJECT_PLAN_QTY = 0 then
        aQteSolde  := tplBatchDetails.LOT_INPROD_QTY;
      else
        if nvl(tplBatchDetails.LOT_REJECT_PLAN_QTY, 0) <=
             (nvl(tplBatchDetails.LOT_REJECT_RELEASED_QTY, 0) +
              nvl(tplBatchDetails.LOT_DISMOUNTED_QTY, 0) +
              nvl(tplBatchDetails.LOT_PT_REJECT_QTY, 0) +
              nvl(tplBatchDetails.LOT_CPT_REJECT_QTY, 0)
             ) then
          aQteSolde  := tplBatchDetails.LOT_INPROD_QTY;
        else
          aQteSolde  := FAL_TOOLS.GetMaxOf(tplBatchDetails.LOT_ASKED_QTY - tplBatchDetails.LOT_RELEASED_QTY, 0);

          if aQteSolde < 0 then
            aQteSolde  := 0;
          end if;
        end if;
      end if;

      -- Parcourir les tableaux ----------------------------------------------------------------------------------
      for aIndex in 0 ..(aTabCount - 1) loop
        -- Vérifier que le jeu de caractérisations n'existe pas déjà dans la table FAL_NETWORK_SUPPLY
        if not IsCharacterizationExists(aLotID
                                      , tplBatchDetails.GCO_GOOD_ID
                                      , aTabCaracterisationValue1(aIndex)
                                      , aTabCaracterisationValue2(aIndex)
                                      , aTabCaracterisationValue3(aIndex)
                                      , aTabCaracterisationValue4(aIndex)
                                      , aTabCaracterisationValue5(aIndex)
                                       ) then
          -- Insertion dans FAL_NETWORK_SUPPLY -----------------------------------------------------------------------
          insert into FAL_NETWORK_SUPPLY
                      (FAL_NETWORK_SUPPLY_ID
                     , A_DATECRE
                     , A_IDCRE
                     , FAL_LOT_ID
                     , GCO_GOOD_ID
                     , FAN_DESCRIPTION
                     , DOC_RECORD_ID
                     , FAN_BEG_PLAN
                     , FAN_END_PLAN
                     , FAN_BEG_PLAN1
                     , FAN_END_PLAN1
                     , FAN_REAL_BEG
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
                      )
               values (GetNewId
                     , sysdate
                     , PCS.PC_I_LIB_SESSION.GetUserIni
                     , aLotID
                     , tplBatchDetails.GCO_GOOD_ID
                     , tplBatchDetails.LOT_REFCOMPL
                     , tplBatchDetails.DOC_RECORD_ID
                     , tplBatchDetails.LOT_PLAN_BEGIN_DTE
                     , tplBatchDetails.LOT_PLAN_END_DTE
                     , tplBatchDetails.LOT_PLAN_BEGIN_DTE
                     , tplBatchDetails.LOT_PLAN_END_DTE
                     , tplBatchDetails.LOT_OPEN__DTE
                     , tplBatchDetails.LOT_PLAN_LEAD_TIME
                     , aStockID
                     , aLocationID
                     , '13'   -- Intitule gabarit = dcLotFabrication
                     , aTabCaracterisationID1(aIndex)
                     , aTabCaracterisationID2(aIndex)
                     , aTabCaracterisationID3(aIndex)
                     , aTabCaracterisationID4(aIndex)
                     , aTabCaracterisationID5(aIndex)
                     , aTabCaracterisationValue1(aIndex)
                     , aTabCaracterisationValue2(aIndex)
                     , aTabCaracterisationValue3(aIndex)
                     , aTabCaracterisationValue4(aIndex)
                     , aTabCaracterisationValue5(aIndex)
                     , aTabQte(aIndex)   -- Qte prevue
                     , 0   -- Qte Rebut prévue
                     , aTabQte(aIndex)   -- Qte Totale
                     , aTabQteReceptionne(aIndex) + aTabQteAnnule(aIndex)   -- Qte Realisee
                     , 0   -- Qte Supplémentaire
                     , 0   -- Qte Dechargée
                     , 0   -- Qte Rebut Realise
                     , 0   -- Qte Retour
                     , aTabQteSolde(aIndex)   -- Qte Solde
                     , aTabQteSolde(aIndex)   -- Qte Libre
                     , 0   -- Qte Att Stock
                     , 0   -- Qte Att Besoin Appro
                      );
        end if;
      end loop;
    end loop;
  end;

-- PROCEDURE ReseauApproFAL_Detail_SupprAll ()
--
-- Suppression de tous les enregistrements dans les Appros correspondant au LotID donné avec historisation eventuelle
-- (Détails uniquement)
  procedure ReseauApproFAL_Detail_SupprAll(aLotID in TTypeID, aHistorisation in integer)
  is
    -- Lecture de plusieurs enregistrement de FAL_NETWORK_SUPPLY selon le LotID - Détaillés uniquement
    cursor GetSupplyDetailRecords(aLotID in TTypeID)
    is
      select FAL_NETWORK_SUPPLY_ID
        from FAL_NETWORK_SUPPLY
       where FAL_LOT_ID = aLotID
         and (   FAN_CHAR_VALUE1 is not null
              or FAN_CHAR_VALUE2 is not null
              or FAN_CHAR_VALUE3 is not null
              or FAN_CHAR_VALUE4 is not null
              or FAN_CHAR_VALUE5 is not null
              or GCO_GOOD_ID <> (select GCO_GOOD_ID
                                   from FAL_LOT
                                  where FAL_LOT_ID = aLotID)
             );
  begin
    for aSupplyRecord in GetSupplyDetailRecords(aLotID) loop
      -- Historisation ...
      if aHistorisation > 0 then
        -- Historisation de tous les appros concernés ...
        ReseauApproFAL_Historisation(aSupplyRecord.FAL_NETWORK_SUPPLY_ID);
      end if;

      -- Suppression Attributions Appro Stock ...
      Attribution_Suppr_ApproStock(aSupplyRecord.FAL_NETWORK_SUPPLY_ID);
      -- Suppression Attributions Appro Besoin ...
      Attribution_Suppr_ApproBesoin(aSupplyRecord.FAL_NETWORK_SUPPLY_ID);
    end loop;

    -- Suppression des appros détaillés...
    delete from FAL_NETWORK_SUPPLY
          where FAL_LOT_ID = aLotID
            and (   FAN_CHAR_VALUE1 is not null
                 or FAN_CHAR_VALUE2 is not null
                 or FAN_CHAR_VALUE3 is not null
                 or FAN_CHAR_VALUE4 is not null
                 or FAN_CHAR_VALUE5 is not null
                 or GCO_GOOD_ID <> (select GCO_GOOD_ID
                                      from FAL_LOT
                                     where FAL_LOT_ID = aLotID)
                );
  end;

-- PROCEDURE ReseauApproFAL_Detail_SupprNul ()
--
-- Suppression de tous les enregistrements dans les Appros correspondant au LotID donné avec historisation éventuelle
-- (Avec toutes les caractérisations à NULL)
  procedure ReseauApproFAL_Detail_SupprNul(aLotID in TTypeID, aHistorisation in integer)
  is
    -- Lecture de plusieurs enregistrement de FAL_NETWORK_SUPPLY selon le LotID - Toutes caractéristiques = NULL
    cursor GetSupplyDetailNullRecords(aLotID in TTypeID)
    is
      select FAL_NETWORK_SUPPLY_ID
        from FAL_NETWORK_SUPPLY
       where FAL_LOT_ID = aLotID
         and (    FAN_CHAR_VALUE1 is null
              and FAN_CHAR_VALUE2 is null
              and FAN_CHAR_VALUE3 is null
              and FAN_CHAR_VALUE4 is null
              and FAN_CHAR_VALUE5 is null);
  begin
    for aSupplyRecord in GetSupplyDetailNullRecords(aLotID) loop
      -- Historisation ...
      if aHistorisation > 0 then
        -- Historisation de tous les appros concernés ...
        ReseauApproFAL_Historisation(aSupplyRecord.FAL_NETWORK_SUPPLY_ID);
      end if;

      -- Suppression Attributions Appro Stock ...
      Attribution_Suppr_ApproStock(aSupplyRecord.FAL_NETWORK_SUPPLY_ID);
      -- Suppression Attributions Appro Besoin ...
      Attribution_Suppr_ApproBesoin(aSupplyRecord.FAL_NETWORK_SUPPLY_ID);

      -- Suppression de l'appros détaillés...
      delete from FAL_NETWORK_SUPPLY
            where FAL_NETWORK_SUPPLY_ID = aSupplyRecord.FAL_NETWORK_SUPPLY_ID;
    end loop;
  end;

-- PROCEDURE ReseauApproFAL_Detail_Suppr ()
--
-- Suppression des enregistrements appro associés à des détails lot n'existant plus dans FAL_LOT_DETAIL
  procedure ReseauApproFAL_Detail_Suppr(aLotID in TTypeID, aHistorisation in integer)
  is
    -- Record du lot concerné
    aLotConcerne                  GetLotRecord%rowtype;
    -- Record du Appro concerné
    aApproConcerne                GetSupplyRecordForUpdate%rowtype;
    -- Produit du lot ...
    aGoodId                       TTypeID;
    -- Booleans indiquant si une caractérisation est prise en compte dans les réseaux ...
    aUseCarac1                    boolean;
    aUseCarac2                    boolean;
    aUseCarac3                    boolean;
    aUseCarac4                    boolean;
    aUseCarac5                    boolean;
    -- Valeurs de caractérisations ...
    aCarac1                       FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
    aCarac2                       FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
    aCarac3                       FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
    aCarac4                       FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
    aCarac5                       FAL_LOT_DETAIL.FAD_CHARACTERIZATION_VALUE_1%type;
    -- Index de parcours ...
    aIndex                        integer;
    aI                            integer;
    -- Tables contenant les ID Caractérisations des Détails ...
    aTabCaracterisationID1        TIDArray;
    aTabCaracterisationID2        TIDArray;
    aTabCaracterisationID3        TIDArray;
    aTabCaracterisationID4        TIDArray;
    aTabCaracterisationID5        TIDArray;
    -- Tables contenant les Valeurs Caractérisations des Détails ...
    aTabCaracterisationValue1     TStringArray;
    aTabCaracterisationValue2     TStringArray;
    aTabCaracterisationValue3     TStringArray;
    aTabCaracterisationValue4     TStringArray;
    aTabCaracterisationValue5     TStringArray;
    -- Table contenant la somme Qté des Détails
    aTabQte                       TCurrencyArray;
    -- Table contenant la somme QtéRéceptionnée des Détails
    aTabQteReceptionne            TCurrencyArray;
    -- Table contenant la somme QtéAnnulée des Détails
    aTabQteAnnule                 TCurrencyArray;
    -- Table contenant la somme QtéSolde des Détails
    aTabQteSolde                  TCurrencyArray;
    -- Nombre de lignes des tables ci-dessous
    aTabCount                     integer;

    cursor CChaqueProdOfDetailLot
    is
      select distinct GCO_GOOD_ID
                 from FAL_LOT_DETAIL
                where FAL_LOT_ID = aLotID;

    EnrCChaqueProdOfDetailLot     CChaqueProdOfDetailLot%rowtype;
    cfgFAL_ATTRIB_ON_CHARACT_MODE integer;
  begin
    -- Ouverture du curseur sur le lot et renseigner aLotConcerne
    open GetLotRecord(aLotID);

    fetch GetLotRecord
     into aLotConcerne;

    -- S'assurer qu'il y ai un enregistrement Lot ...
    if GetLotRecord%found then
      -- Pour chaque Good Id des détails lot du lot.
      open CChaqueProdOfDetailLot;

      loop
        fetch CChaqueProdOfDetailLot
         into EnrCChaqueProdOfDetailLot;

        exit when CChaqueProdOfDetailLot%notfound;
        -- Récupérer le produit du lot ...
        aGoodID                        := GetLotGoodID(aLotID);
        -- Définir les caractérisations utiles ...
        -- aUseCaracX vaut True si la caractérisation correspondante est prise en compte dans les réseaux ...
        --DefineUtilCharacterizations(aGoodID, aUseCarac1, aUseCarac2, aUseCarac3, aUseCarac4, aUseCarac5);
        cfgFAL_ATTRIB_ON_CHARACT_MODE  := to_number(PCS.PC_CONFIG.GetConfig('FAL_ATTRIB_ON_CHARACT_MODE') );
        -- Déterminer les tableaux DétailLot -----------------------------------------------------------------------
        GetLotDetailSums(aLotID
                       , EnrCChaqueProdOfDetailLot.GCO_GOOD_ID
                       , aTabCaracterisationID1
                       , aTabCaracterisationID2
                       , aTabCaracterisationID3
                       , aTabCaracterisationID4
                       , aTabCaracterisationID5
                       , aTabCaracterisationValue1
                       , aTabCaracterisationValue2
                       , aTabCaracterisationValue3
                       , aTabCaracterisationValue4
                       , aTabCaracterisationValue5
                       , aTabQte
                       , aTabQteReceptionne
                       , aTabQteAnnule
                       , aTabQteSolde
                       , aTabCount
                        );

        -- Ouverture du curseur sur les enregistrements Appro et renseigner aLotConcerne
        open GetSupplyRecordForUpdate(aLotID, EnrCChaqueProdOfDetailLot.GCO_GOOD_ID);

        loop
          fetch GetSupplyRecordForUpdate
           into aApproConcerne;

          -- S'assurer qu'il y ai un enregistrement Appro ...
          exit when GetSupplyRecordForUpdate%notfound;

          -- Définir les valeurs de caractérisations ...
          if     aApproConcerne.CHA_STOCK_MANAGEMENT1 = 1
             and (    (    aApproConcerne.C_CHARACT_TYPE1 = '1'
                       and cfgFAL_ATTRIB_ON_CHARACT_MODE <> 4)
                  or aApproConcerne.C_CHARACT_TYPE1 = '2') then
            aCarac1  := aApproConcerne.FAN_CHAR_VALUE1;
          else
            aCarac1  := null;
          end if;

          if     aApproConcerne.CHA_STOCK_MANAGEMENT2 = 1
             and (    (    aApproConcerne.C_CHARACT_TYPE2 = '1'
                       and cfgFAL_ATTRIB_ON_CHARACT_MODE <> 4)
                  or aApproConcerne.C_CHARACT_TYPE2 = '2') then
            aCarac2  := aApproConcerne.FAN_CHAR_VALUE2;
          else
            aCarac2  := null;
          end if;

          if     aApproConcerne.CHA_STOCK_MANAGEMENT3 = 1
             and (    (    aApproConcerne.C_CHARACT_TYPE3 = '1'
                       and cfgFAL_ATTRIB_ON_CHARACT_MODE <> 4)
                  or aApproConcerne.C_CHARACT_TYPE3 = '2') then
            aCarac3  := aApproConcerne.FAN_CHAR_VALUE3;
          else
            aCarac3  := null;
          end if;

          if     aApproConcerne.CHA_STOCK_MANAGEMENT4 = 1
             and (    (    aApproConcerne.C_CHARACT_TYPE4 = '1'
                       and cfgFAL_ATTRIB_ON_CHARACT_MODE <> 4)
                  or aApproConcerne.C_CHARACT_TYPE4 = '2') then
            aCarac4  := aApproConcerne.FAN_CHAR_VALUE4;
          else
            aCarac4  := null;
          end if;

          if     aApproConcerne.CHA_STOCK_MANAGEMENT5 = 1
             and (    (    aApproConcerne.C_CHARACT_TYPE5 = '1'
                       and cfgFAL_ATTRIB_ON_CHARACT_MODE <> 4)
                  or aApproConcerne.C_CHARACT_TYPE5 = '2') then
            aCarac5  := aApproConcerne.FAN_CHAR_VALUE5;
          else
            aCarac5  := null;
          end if;

          -- Rechercher si une ligne contenant les mêmes valeurs de caractérisations existe ...
          aIndex  := -1;
          aI      := 0;

          while(aI < aTabCount)
           and (aIndex = -1) loop
            -- Pour les Appros n'ayant aucune caractérisation
            if     (aCarac1 is null)
               and (aCarac2 is null)
               and (aCarac3 is null)
               and (aCarac4 is null)
               and (aCarac5 is null) then
              -- Trouvé !
              aIndex  := aI;
            end if;

            -- Recherche l'égalité des charactérisations ...
            if     (    (aTabCaracterisationValue1(aI) = aCarac1)
                    or (     (aTabCaracterisationValue1(aI) is null)
                        and (aCarac1 is null) ) )
               and (    (aTabCaracterisationValue2(aI) = aCarac2)
                    or (     (aTabCaracterisationValue2(aI) is null)
                        and (aCarac2 is null) ) )
               and (    (aTabCaracterisationValue3(aI) = aCarac3)
                    or (     (aTabCaracterisationValue3(aI) is null)
                        and (aCarac3 is null) ) )
               and (    (aTabCaracterisationValue4(aI) = aCarac4)
                    or (     (aTabCaracterisationValue4(aI) is null)
                        and (aCarac4 is null) ) )
               and (    (aTabCaracterisationValue5(aI) = aCarac5)
                    or (     (aTabCaracterisationValue5(aI) is null)
                        and (aCarac5 is null) ) ) then
              -- Trouvé !
              aIndex  := aI;
            end if;

            aI  := aI + 1;
          end loop;

          -- Si aucune Détail Lot n'a été trouvé pour cet enregistrement d' APPRO ...
          -- Supprimer l'appro ...
          if aIndex = -1 then
            -- Historisation éventuelle ...
            if aHistorisation > 0 then
              ReseauApproFAL_Historisation(aApproConcerne.FAL_NETWORK_SUPPLY_ID);
            end if;

            -- Suppression Attributions Appro Stock ...
            Attribution_Suppr_ApproStock(aApproConcerne.FAL_NETWORK_SUPPLY_ID);
            -- Suppression Attributions Appro Besoin ...
            Attribution_Suppr_ApproBesoin(aApproConcerne.FAL_NETWORK_SUPPLY_ID);

            delete from FAL_NETWORK_SUPPLY
                  where current of GetSupplyRecordForUpdate;
          -- END : If aIndex = -1 ...
          end if;
        -- FIN : LOOP sur les enregistrements Appro ...
        end loop;

        -- Fermeture du curseur sur l'appro
        close GetSupplyRecordForUpdate;
      end loop;

      close CChaqueProdOfDetailLot;
    -- Fin de boucle sur les Good Id des détails lot du lot.

    -- FIN : S'assurer qu'il y ai un enregistrement Lot ...
    end if;

    -- fermeture du curseur sur le lot concerné
    close GetLotRecord;
  end;

  /**
  * procedure UpdateBatchNetwDescr
  * Description : Mise à jour de la référence complète d'un lot de fabrication avec
  *               le numéro de document et celui de la position
  * @created ECA
  * @lastUpdate age 18.06.2012
  * @public
  * @param   iFalLotId : Lot de fabrication
  */
  procedure UpdateBatchNetwDescr(iFalLotId in number)
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Réseaux besoin
    for tplNeed in (select FAL_NETWORK_NEED_ID
                         , LOT.LOT_REFCOMPL
                      from FAL_NETWORK_NEED FNN
                         , FAL_LOT LOT
                     where FNN.FAL_LOT_ID = LOT.FAL_LOT_ID
                       and LOT.FAL_LOT_ID = iFalLotId
                       and FNN.FAL_LOT_MATERIAL_LINK_ID is not null) loop
      FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcfalnetworkneed, ltCRUD_DEF, true, tplNeed.FAL_NETWORK_NEED_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FAN_DESCRIPTION', tplNeed.LOT_REFCOMPL);
      FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    end loop;

    -- Réseaux Appro
    for tplSupply in (select FAL_NETWORK_SUPPLY_ID
                           , LOT.LOT_REFCOMPL
                        from FAL_NETWORK_SUPPLY FNS
                           , FAL_LOT LOT
                       where FNS.FAL_LOT_ID = LOT.FAL_LOT_ID
                         and LOT.FAL_LOT_ID = iFalLotId) loop
      FWK_I_MGT_ENTITY.new(FWK_TYP_FAL_ENTITY.gcfalnetworksupply, ltCRUD_DEF, true, tplSupply.FAL_NETWORK_SUPPLY_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'FAN_DESCRIPTION', tplSupply.LOT_REFCOMPL);
      FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    end loop;
  end UpdateBatchNetwDescr;

  /**
  * procedure ReseauBesoinFAL_Creation
  * Description : Création des réseaux besoins pour la fabrication
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aLotID : Lot de fabrication
  * @param   aDefaultStockId : Stock par défaut
  * @param   aDefaultLocationID : Emplacement par défaut
  */
  procedure ReseauBesoinFAL_Creation(aLotID in TTypeID, aDefaultStockID in TTypeID, aDefaultLocationID in TTypeID)
  is
    -- Lecture de N enregistrements de FAL_LOT_MATERIAL_LINK selon le LotID avec NeedQty > 0
    cursor crComponents
    is
      select LOM.FAL_LOT_MATERIAL_LINK_ID
           , LOM.STM_STOCK_ID
           , LOM.STM_LOCATION_ID
           , LOM.LOM_NEED_QTY
           , LOM.LOM_NEED_DATE
           , LOM.GCO_GOOD_ID
           , LOT.DOC_RECORD_ID
        from FAL_LOT_MATERIAL_LINK LOM
           , FAL_LOT LOT
       where LOM.FAL_LOT_ID = aLotID
         and LOM.LOM_NEED_QTY > 0
         and LOM.FAL_LOT_ID = LOT.FAL_LOT_ID
         and not exists(select 1
                          from FAL_NETWORK_NEED FNN
                         where FNN.FAL_LOT_MATERIAL_LINK_ID = LOM.FAL_LOT_MATERIAL_LINK_ID);

    aStockID        TTypeID;
    aLocationID     TTypeID;
    aLotDescription FAL_LOT.LOT_REFCOMPL%type;
  begin
    -- Récupération de la description (RefComplete) du lot ...
    aLotDescription  := GetLotCompleteReference(aLotID);

    -- Ouverture du curseur sur le lot
    for TplComponents in crComponents loop
      -- Déterminer le STOCK et l'EMPLACEMENT à stocker dans les réseaux
      aStockID     := TplComponents.STM_STOCK_ID;
      aLocationID  := TplComponents.STM_LOCATION_ID;
      SetDefaultStockAndLocation(aStockID, aLocationID, aDefaultStockID, aDefaultLocationID);

      -- Insertion dans FAL_NETWORK_NEED
      insert into FAL_NETWORK_NEED
                  (FAL_NETWORK_NEED_ID
                 , A_DATECRE
                 , A_IDCRE
                 , FAL_LOT_ID
                 , FAL_LOT_MATERIAL_LINK_ID
                 , GCO_GOOD_ID
                 , FAN_DESCRIPTION
                 , DOC_RECORD_ID
                 , FAN_BEG_PLAN
                 , FAN_END_PLAN
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , C_GAUGE_TITLE
                 , FAN_BALANCE_QTY
                 , FAN_FREE_QTY
                 , FAN_STK_QTY
                 , FAN_NETW_QTY
                  )
           values (GetNewId
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                 , aLotID
                 , TplComponents.FAL_LOT_MATERIAL_LINK_ID
                 , TplComponents.GCO_GOOD_ID
                 , aLotDescription
                 , TplComponents.DOC_RECORD_ID
                 , TplComponents.LOM_NEED_DATE
                 , TplComponents.LOM_NEED_DATE
                 , aStockID
                 , aLocationID
                 , '13'
                 , TplComponents.LOM_NEED_QTY
                 , TplComponents.LOM_NEED_QTY
                 , 0
                 , 0
                  );
    end loop;
  end;

-- PROCEDURE ReseauBesoinFAL_SupprAll ()
--
-- Suppression de tous les enregistrements dans FAL_NETWORK_NEED pour un lot donné
-- Pas d'historisation des besoins
  procedure ReseauBesoinFAL_SupprAll(aLotID in TTypeID)
  is
  begin
    for aRecord in GetNeedRecordsForUpdate(aLotID) loop
      -- Suppression Attribution Besoin Stock ...
      Attribution_Suppr_BesoinStock(aRecord.FAL_NETWORK_NEED_ID);
      -- Suppression Attribution Besoin Appro ...
      Attribution_Suppr_BesoinAppro(aRecord.FAL_NETWORK_NEED_ID);

      -- Suppression du record ...
      delete from FAL_NETWORK_NEED
            where current of GetNeedRecordsForUpdate;
    end loop;
  end;

-- PROCEDURE ReseauBesoinFAL_SupprOld ()
--
-- Suppression de tous les enregistrements dans FAL_NETWORK_NEED pour un lot donné et pour lesquels il n'y a pas (plus)
-- de composant associé dans FAL_LOT_MATERIAL_LINK ...
  procedure ReseauBesoinFAL_SupprOld(aLotID in TTypeID)
  is
    aRecCount integer;
  begin
    for aRecord in GetNeedRecordsForUpdate(aLotID) loop
      -- Tester l'existence du composant concerné ...
      select count(*)
        into aRecCount
        from FAL_LOT_MATERIAL_LINK
       where FAL_LOT_MATERIAL_LINK_ID = aRecord.FAL_LOT_MATERIAL_LINK_ID;

      if (aRecCount = 0) then
        -- Suppression Attribution Besoin Stock ...
        Attribution_Suppr_BesoinStock(aRecord.FAL_NETWORK_NEED_ID);
        -- Suppression Attribution Besoin Appro ...
        Attribution_Suppr_BesoinAppro(aRecord.FAL_NETWORK_NEED_ID);

        -- Le composant n'existe pas. suppression du record ...
        delete from FAL_NETWORK_NEED
              where current of GetNeedRecordsForUpdate;
      end if;
    end loop;
  end;

-- PROCEDURE ReseauBesoinFAL_MAJ ()
--
-- Modification d'un enregistrement dans FAL_NETWORK_NEED à partir des composants d'un lot de fabrication
-- Le paramètre aUpdateType vaut :
--  1 : Mise à jour complète
--  2 : Mise à jour Date
--
-- Si aAllowDelete > 0
--    -> Si Composant.LOM_NEED_QTY <= 0 alors suppression du record de Fal_Network_Need
  procedure ReseauBesoinFAL_MAJ(aLotID in TTypeID, aDefaultStockID in TTypeID, aDefaultLocationID in TTypeID, aUpdateType in integer, aAllowDelete in integer)
  is
    -- Lecture de N enregistrements de FAL_LOT_MATERIAL_LINK selon le LotID avec NeedQty quelconque
    cursor GetAllComposantRecords(aLotID in TTypeID)
    is
      select FAL_LOT_MATERIAL_LINK_ID
           , LOM_NEED_QTY
           , STM_STOCk_ID
           , STM_LOCATION_ID
           , LOM_NEED_DATE
        from FAL_LOT_MATERIAL_LINK
       where FAL_LOT_ID = aLotID;

    -- Lecture de 1 enregistrement de FAL_NETWORK_NEED selon un composant lot donné (FOR UPDATE)
    cursor GetNeedRecordForUpdate(aComposantID in TTypeID)
    is
      select     FAL_NETWORK_NEED_ID
               , FAN_FREE_QTY
               , FAN_NETW_QTY
               , FAN_STK_QTY
               , FAN_BEG_PLAN
            from FAL_NETWORK_NEED
           where FAL_LOT_MATERIAL_LINK_ID = aComposantID
      for update;

    -- Record des composants concernés
    aComposantConcerne GetAllComposantRecords%rowtype;
    -- Record du need associé au composant
    aNeedRecord        GetNeedRecordForUpdate%rowtype;
    -- StockID défini pour l'insertion
    aStockID           TTypeID;
    -- LocationID défini pour l'insertion
    aLocationID        TTypeID;
    -- DocRecordID du lot ...
    aDocRecordID       TTypeID;
    -- Debut et Fin planif du need
    aBeginEndPlanDate  TTypeDate;
    -- Qte Solde
    aQteSolde          FAL_NETWORK_NEED.FAN_BALANCE_QTY%type;
    -- Qte Libre
    aQteLibre          FAL_NETWORK_NEED.FAN_FREE_QTY%type;
    -- Qte Attribuée sur Stock
    aQteAttStock       FAL_NETWORK_NEED.FAN_STK_QTY%type;
    -- Qte Attribuée Besoin Appro
    aQteAttBesoin      FAL_NETWORK_NEED.FAN_NETW_QTY%type;
  begin
    -- Ouverture du curseur sur le lot et renseigner aLotConcerne
    open GetAllComposantRecords(aLotID);

    loop
      fetch GetAllComposantRecords
       into aComposantConcerne;

      -- S'assurer qu'il y ai un enregistrement ...
      exit when GetAllComposantRecords%notfound;

      -- Récupérer le record de FAL_NETWORK_NEED correspondant ---------------------------------------------------
      open GetNeedRecordForUpdate(aComposantConcerne.FAL_LOT_MATERIAL_LINK_ID);

      fetch GetNeedRecordForUpdate
       into aNeedRecord;

      -- Si trouvé ...
      if GetNeedRecordForUpdate%found then
        -- Initialiser les quantités -------------------------------------------------------------------------------
        aQteSolde      := aComposantConcerne.LOM_NEED_QTY;
        aQteLibre      := aNeedRecord.FAN_FREE_QTY;
        aQteAttBesoin  := aNeedRecord.FAN_NETW_QTY;
        aQteAttStock   := aNeedRecord.FAN_STK_QTY;

        -- Faut-il supprimer ce record de FAL_NETWORK_NEED ? -------------------------------------------------------
        if (     (aAllowDelete > 0)
            and (aComposantConcerne.LOM_NEED_QTY <= 0) ) then   /* PRD-A041021-43532 JPA871 */
          -- Suppression Attribution Besoin Stock ...
          Attribution_Suppr_BesoinStock(aNeedRecord.FAL_NETWORK_NEED_ID);
          -- Suppression Attribution Besoin Appro ...
          Attribution_Suppr_BesoinAppro(aNeedRecord.FAL_NETWORK_NEED_ID);

          -- Supprimer le record ---------------------------------------------------------------------------------
          delete from FAL_NETWORK_NEED
                where current of GetNeedRecordForUpdate;
        else
          -- Modifier le record ----------------------------------------------------------------------------------

          -- Déterminer le STOCK et l'EMPLACEMENT à stocker dans les réseaux -----------------------------------------
          aStockID           := aComposantConcerne.STM_STOCK_ID;
          aLocationID        := aComposantConcerne.STM_LOCATION_ID;
          SetDefaultStockAndLocation(aStockID, aLocationID, aDefaultStockID, aDefaultLocationID);

          -- Déterminer le DocRecord du lot --------------------------------------------------------------------------
          select DOC_RECORD_ID
            into aDocRecordID
            from FAL_LOT
           where FAL_LOT_ID = aLotID;

          -- Déterminer la date de début et de fin planif ------------------------------------------------------------
          aBeginEndPlanDate  := aNeedRecord.FAN_BEG_PLAN;

          if    aBeginEndPlanDate is null
             or aBeginEndPlanDate <> aComposantConcerne.LOM_NEED_DATE then
            aBeginEndPlanDate  := aComposantConcerne.LOM_NEED_DATE;
            -- Mise à jour Attribution Date Besoin ...
            Attribution_MAJ_DateBesoin(aNeedRecord.FAL_NETWORK_NEED_ID, aBeginEndPlanDate);
          end if;

          -- Traiter les quantités si aUpdateType = 1 ----------------------------------------------------------------
          if aUpdateType = 1 then
            if to_number(PCS.PC_CONFIG.GetConfig('FAL_ORDER_ATTRIB_COMP') ) = 1 then
              -- L'ordre est alors: Stock, Appro, Libre

              -- Qte Attribuée sur Stock ---------------------------------------------------------------------------------
              if (nvl(aNeedRecord.FAN_FREE_QTY, 0) + nvl(aNeedRecord.FAN_NETW_QTY, 0) + nvl(aNeedRecord.FAN_STK_QTY, 0) ) > nvl(aQteSolde, 0) then
                if (nvl(aNeedRecord.FAN_NETW_QTY, 0) + nvl(aNeedRecord.FAN_FREE_QTY, 0) ) < nvl(aQteSolde, 0) then
                  aQteAttStock  := aQteSolde -(nvl(aNeedRecord.FAN_NETW_QTY, 0) + nvl(aNeedRecord.FAN_FREE_QTY, 0) );
                  -- Mise à jour Attribution Besoin Stock ...
                  Attribution_MAJ_BesoinStock(aNeedRecord.FAL_NETWORK_NEED_ID, aNeedRecord.FAN_STK_QTY, aQteAttStock, null);
                else
                  aQteAttStock  := 0;
                  -- Suppression Attribution Besoin Stock ...
                  Attribution_Suppr_BesoinStock(aNeedRecord.FAL_NETWORK_NEED_ID);
                end if;
              end if;

              -- Qte Attribuée Besoin Appro ------------------------------------------------------------------------------
              if (nvl(aNeedRecord.FAN_FREE_QTY, 0) + nvl(aNeedRecord.FAN_NETW_QTY, 0) + nvl(aNeedRecord.FAN_STK_QTY, 0) ) > nvl(aQteSolde, 0) then
                if (nvl(aNeedRecord.FAN_FREE_QTY, 0) + nvl(aNeedRecord.FAN_NETW_QTY, 0) ) >= nvl(aQteSolde, 0) then
                  if (nvl(aNeedRecord.FAN_FREE_QTY, 0) ) < nvl(aQteSolde, 0) then
                    aQteAttBesoin  := nvl(aQteSolde, 0) - nvl(aNeedRecord.FAN_FREE_QTY, 0);
                    -- Mise à jour Attribution Besoin Appro ...
                    Attribution_MAJ_BesoinAppro(aNeedRecord.FAL_NETWORK_NEED_ID, aNeedRecord.FAN_NETW_QTY, aQteAttBesoin);
                  else
                    aQteAttBesoin  := 0;
                    -- Suppression Attribution Besoin Appro ...
                    Attribution_Suppr_BesoinAppro(aNeedRecord.FAL_NETWORK_NEED_ID);
                  end if;
                end if;
              end if;

-- Qte Libre -----------------------------------------------------------------------------------------------
              if (nvl(aNeedRecord.FAN_FREE_QTY, 0) + nvl(aNeedRecord.FAN_NETW_QTY, 0) + nvl(aNeedRecord.FAN_STK_QTY, 0) ) < nvl(aQteSolde, 0) then
                aQteLibre  := nvl(aQteSolde, 0) - nvl(aNeedRecord.FAN_NETW_QTY, 0) - nvl(aNeedRecord.FAN_STK_QTY, 0);
              else
                if (nvl(aNeedRecord.FAN_FREE_QTY, 0) + nvl(aNeedRecord.FAN_NETW_QTY, 0) + nvl(aNeedRecord.FAN_STK_QTY, 0) ) > nvl(aQteSolde, 0) then
                  if (nvl(aNeedRecord.FAN_FREE_QTY, 0) ) >= nvl(aQteSolde, 0) then
                    aQteLibre  := aQteSolde;
                  end if;
                end if;
              end if;
            end if;

            if to_number(PCS.PC_CONFIG.GetConfig('FAL_ORDER_ATTRIB_COMP') ) = 2 then
  -- L'ordre est alors: Libre, Appro, STock
-- Qte Libre ---------------------------------------------------------------------------------
              if (nvl(aNeedRecord.FAN_FREE_QTY, 0) + nvl(aNeedRecord.FAN_NETW_QTY, 0) + nvl(aNeedRecord.FAN_STK_QTY, 0) ) < nvl(aQteSolde, 0) then
                aQteLibre  := nvl(aQteSolde, 0) - nvl(aNeedRecord.FAN_NETW_QTY, 0) - nvl(aNeedRecord.FAN_STK_QTY, 0);
              end if;

              if (nvl(aNeedRecord.FAN_FREE_QTY, 0) + nvl(aNeedRecord.FAN_NETW_QTY, 0) + nvl(aNeedRecord.FAN_STK_QTY, 0) ) > nvl(aQteSolde, 0) then
                if (nvl(aNeedRecord.FAN_NETW_QTY, 0) + nvl(aNeedRecord.FAN_STK_QTY, 0) ) < nvl(aQteSolde, 0) then
                  aQteLibre  := aQteSolde -(nvl(aNeedRecord.FAN_NETW_QTY, 0) + nvl(aNeedRecord.FAN_STK_QTY, 0) );
                else
                  aQteLibre  := 0;
                end if;
              end if;

              -- Qte Attribuée Besoin Appro ------------------------------------------------------------------------------
              if (nvl(aNeedRecord.FAN_FREE_QTY, 0) + nvl(aNeedRecord.FAN_NETW_QTY, 0) + nvl(aNeedRecord.FAN_STK_QTY, 0) ) > nvl(aQteSolde, 0) then
                if (nvl(aNeedRecord.FAN_NETW_QTY, 0) + nvl(aNeedRecord.FAN_STK_QTY, 0) ) >= nvl(aQteSolde, 0) then
                  if (nvl(aNeedRecord.FAN_STK_QTY, 0) ) < nvl(aQteSolde, 0) then
                    aQteAttBesoin  := nvl(aQteSolde, 0) - nvl(aNeedRecord.FAN_STK_QTY, 0);
                    -- Mise à jour Attribution Besoin Appro ...
                    Attribution_MAJ_BesoinAppro(aNeedRecord.FAL_NETWORK_NEED_ID, aNeedRecord.FAN_NETW_QTY, aQteAttBesoin);
                  else
                    aQteAttBesoin  := 0;
                    -- Suppression Attribution Besoin Appro ...
                    Attribution_Suppr_BesoinAppro(aNeedRecord.FAL_NETWORK_NEED_ID);
                  end if;
                end if;
              end if;

              -- Qte Attribuée sur Stock--------------------------------------------------------------------------------------
              if (nvl(aNeedRecord.FAN_FREE_QTY, 0) + nvl(aNeedRecord.FAN_NETW_QTY, 0) + nvl(aNeedRecord.FAN_STK_QTY, 0) ) >= nvl(aQteSolde, 0) then
                if (nvl(aNeedRecord.FAN_FREE_QTY, 0) + nvl(aNeedRecord.FAN_NETW_QTY, 0) + nvl(aNeedRecord.FAN_STK_QTY, 0) ) > nvl(aQteSolde, 0) then
                  if (nvl(aNeedRecord.FAN_STK_QTY, 0) ) >= nvl(aQteSolde, 0) then
                    aQteAttStock  := aQteSolde;
                    -- Mise à jour Attribution Besoin Stock ...
                    Attribution_MAJ_BesoinStock(aNeedRecord.FAL_NETWORK_NEED_ID, aNeedRecord.FAN_STK_QTY, aQteAttStock, null);
                  end if;
                end if;
              end if;
            end if;
          -- FIN : If aUpdateType = 1 ...
          end if;

          -- Modifier l'enregistrement NEED ----------------------------------------------------------------------------
          update FAL_NETWORK_NEED
             set A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
               , A_DATEMOD = sysdate
               ,
                 -- Dossier
                 DOC_RECORD_ID = aDocRecordID
               ,
                 -- Debut Planif
                 FAN_BEG_PLAN = aBeginEndPlanDate
               ,
                 -- Fin Planif
                 FAN_END_PLAN = aBeginEndPlanDate
               ,
                 -- Stock
                 STM_STOCK_ID = aStockID
               ,
                 -- Emplacement de stock
                 STM_LOCATION_ID = aLocationID
               ,
                 -- Qte Solde
                 FAN_BALANCE_QTY = aQteSolde
               ,
                 -- Qte Libre
                 FAN_FREE_QTY = aQteLibre
               ,
                 -- Qte Att Stock
                 FAN_STK_QTY = aQteAttStock
               ,
                 -- Qte Att Besoin Appro
                 FAN_NETW_QTY = aQteAttBesoin
           where current of GetNeedRecordForUpdate;
        -- FIN : if ((aAllowDelete > 0) and (aComposantConcerne.LOM_NEED_QTY <= 0)) THEN ...
        end if;
      -- FIN : IF GetNeedRecord%FOUND THEN ...
      end if;

      -- fermeture du curseur GetNeedRecordForUpdate
      close GetNeedRecordForUpdate;
    -- FIN : Boucler sur les composants ...
    end loop;

    -- fermeture du curseur sur les composants concernés
    close GetAllComposantRecords;
  end;

-- Mise à jour réseau besoin pour un composant d'une proposition
-- Note: Ce processus a été créer lorsque nous avons mis en place "Controle bloc équivalence sur stock"
  procedure ReseauBesoinPropCmpMAJ(
    PrmFAL_LOT_PROP_ID          FAL_LOT_PROP.FAL_LOT_PROP_ID%type
  , PrmFAL_LOT_MAT_LINK_PROP_ID FAL_LOT_MAT_LINK_PROP.FAL_LOT_MAT_LINK_PROP_ID%type
  , PrmFAL_DOC_PROP_ID          FAL_DOC_PROP.FAL_DOC_PROP_ID%type default null
  )
  is
    -- Lecture de 1 enregistrement de FAL_NETWORK_NEED selon un composant proposition donné (FOR UPDATE)
    cursor GetNeedRecordForUpdate2(aComposantID in TTypeID)
    is
      select     FAL_NETWORK_NEED_ID
               , FAN_FREE_QTY
               , FAN_NETW_QTY
               , FAN_STK_QTY
               , FAN_BEG_PLAN
            from FAL_NETWORK_NEED
           where FAL_LOT_MAT_LINK_PROP_ID = aComposantID
      for update;

    -- Record des composants concernés
    aComposantConcerne  FAL_LOT_MAT_LINK_PROP%rowtype;
    -- Record du need associé au composant
    aNeedRecord         GetNeedRecordForUpdate2%rowtype;
    -- StockID défini pour l'insertion
    aStockID            TTypeID;
    -- LocationID défini pour l'insertion
    aLocationID         TTypeID;
    -- DocRecordID du lot ...
    aDocRecordID        TTypeID;
    -- Debut et Fin planif du need
    aBeginEndPlanDate   TTypeDate;
    -- Qte Solde
    aQteSolde           FAL_NETWORK_NEED.FAN_BALANCE_QTY%type;
    -- Qte Libre
    aQteLibre           FAL_NETWORK_NEED.FAN_FREE_QTY%type;
    -- Qte Attribuée sur Stock
    aQteAttStock        FAL_NETWORK_NEED.FAN_STK_QTY%type;
    -- Qte Attribuée Besoin Appro
    aQteAttBesoin       FAL_NETWORK_NEED.FAN_NETW_QTY%type;
    idDefaultStockID    TTypeID;
    idDefaultLocationID TTypeID;
  begin
    -- Détermine le stock et l'emplacement par défaut
    idDefaultStockID  := FAL_TOOLS.GetConfig_StockID('PPS_DefltSTOCK_NETWORK');

    if idDefaultStockID is null then
      idDefaultLocationID  := null;
    else
      idDefaultLocationID  := FAL_TOOLS.GetConfig_LocationID('PPS_DefltLOCATION_NETWORK', idDefaultStockID);
    end if;

    select *
      into aComposantConcerne
      from FAL_LOT_MAT_LINK_PROP
     where FAL_LOT_MAT_LINK_PROP_ID = PrmFAL_LOT_MAT_LINK_PROP_ID;

    -- Récupérer le record de FAL_NETWORK_NEED correspondant ---------------------------------------------------
    open GetNeedRecordForUpdate2(aComposantConcerne.FAL_LOT_MAT_LINK_PROP_ID);

    fetch GetNeedRecordForUpdate2
     into aNeedRecord;

    -- Si trouvé ...
    if GetNeedRecordForUpdate2%found then
      -- Initialiser les quantités -------------------------------------------------------------------------------
      aQteSolde      := aComposantConcerne.LOM_NEED_QTY;
      aQteLibre      := aNeedRecord.FAN_FREE_QTY;
      aQteAttBesoin  := aNeedRecord.FAN_NETW_QTY;
      aQteAttStock   := aNeedRecord.FAN_STK_QTY;

      -- Faut-il supprimer ce record de FAL_NETWORK_NEED ? -------------------------------------------------------
      if aComposantConcerne.LOM_NEED_QTY <= 0 then   /* PRD-A041021-43532 JPA871 */
        -- Suppression Attribution Besoin Stock ...
        Attribution_Suppr_BesoinStock(aNeedRecord.FAL_NETWORK_NEED_ID);
        -- Suppression Attribution Besoin Appro ...
        Attribution_Suppr_BesoinAppro(aNeedRecord.FAL_NETWORK_NEED_ID);

        -- Supprimer le record ---------------------------------------------------------------------------------
        delete from FAL_NETWORK_NEED
              where current of GetNeedRecordForUpdate2;
      else
        -- Modifier le record ----------------------------------------------------------------------------------

        -- Déterminer le STOCK et l'EMPLACEMENT à stocker dans les réseaux -----------------------------------------
        aStockID           := aComposantConcerne.STM_STOCK_ID;
        aLocationID        := aComposantConcerne.STM_LOCATION_ID;
        SetDefaultStockAndLocation(aStockID, aLocationID, idDefaultStockID, idDefaultLocationID);

        -- Déterminer le DocRecord du lot --------------------------------------------------------------------------
        select DOC_RECORD_ID
          into aDocRecordID
          from FAL_LOT_PROP
         where FAL_LOT_PROP_ID = PrmFAL_LOT_PROP_ID;

        -- Déterminer la date de début et de fin planif ------------------------------------------------------------
        aBeginEndPlanDate  := aNeedRecord.FAN_BEG_PLAN;

        if (aBeginEndPlanDate <> aComposantConcerne.LOM_NEED_DATE) then
          aBeginEndPlanDate  := aComposantConcerne.LOM_NEED_DATE;
          -- Mise à jour Attribution Date Besoin ...
          Attribution_MAJ_DateBesoin(aNeedRecord.FAL_NETWORK_NEED_ID, aBeginEndPlanDate);
        end if;

        -- Qte Attribuée sur Stock ---------------------------------------------------------------------------------
        if (nvl(aNeedRecord.FAN_FREE_QTY, 0) + nvl(aNeedRecord.FAN_NETW_QTY, 0) + nvl(aNeedRecord.FAN_STK_QTY, 0) ) > nvl(aQteSolde, 0) then
          if (nvl(aNeedRecord.FAN_NETW_QTY, 0) + nvl(aNeedRecord.FAN_FREE_QTY, 0) ) < nvl(aQteSolde, 0) then
            aQteAttStock  := aQteSolde;
            -- Mise à jour Attribution Besoin Stock ...
            Attribution_MAJ_BesoinStock(aNeedRecord.FAL_NETWORK_NEED_ID, aNeedRecord.FAN_STK_QTY, aQteAttStock, null);
          else
            aQteAttStock  := 0;
            -- Suppression Attribution Besoin Stock ...
            Attribution_Suppr_BesoinStock(aNeedRecord.FAL_NETWORK_NEED_ID);
          end if;
        end if;

        -- Qte Attribuée Besoin Appro ------------------------------------------------------------------------------
        if (nvl(aNeedRecord.FAN_FREE_QTY, 0) + nvl(aNeedRecord.FAN_NETW_QTY, 0) + nvl(aNeedRecord.FAN_STK_QTY, 0) ) > nvl(aQteSolde, 0) then
          if (nvl(aNeedRecord.FAN_FREE_QTY, 0) + nvl(aNeedRecord.FAN_NETW_QTY, 0) ) >= nvl(aQteSolde, 0) then
            if (nvl(aNeedRecord.FAN_FREE_QTY, 0) ) < nvl(aQteSolde, 0) then
              aQteAttBesoin  := nvl(aQteSolde, 0) - nvl(aNeedRecord.FAN_FREE_QTY, 0);
              -- Mise à jour Attribution Besoin Appro ...
              AttribMAJBesoinApproDecrPOx(aNeedRecord.FAL_NETWORK_NEED_ID, aNeedRecord.FAN_NETW_QTY, aQteAttBesoin, PrmFAL_DOC_PROP_ID);
            else
              aQteAttBesoin  := 0;
              -- Suppression Attribution Besoin Appro ...
              Attribution_Suppr_BesoinAppro(aNeedRecord.FAL_NETWORK_NEED_ID);
            end if;
          end if;
        end if;

-- Qte Libre -----------------------------------------------------------------------------------------------
        if (nvl(aNeedRecord.FAN_FREE_QTY, 0) + nvl(aNeedRecord.FAN_NETW_QTY, 0) + nvl(aNeedRecord.FAN_STK_QTY, 0) ) < nvl(aQteSolde, 0) then
          aQteLibre  := nvl(aQteSolde, 0) - nvl(aNeedRecord.FAN_NETW_QTY, 0) - nvl(aNeedRecord.FAN_STK_QTY, 0);
        else
          if (nvl(aNeedRecord.FAN_FREE_QTY, 0) + nvl(aNeedRecord.FAN_NETW_QTY, 0) + nvl(aNeedRecord.FAN_STK_QTY, 0) ) > nvl(aQteSolde, 0) then
            if (nvl(aNeedRecord.FAN_FREE_QTY, 0) ) >= nvl(aQteSolde, 0) then
              aQteLibre  := aQteSolde;
            end if;
          end if;
        end if;

        -- Modifier l'enregistrement NEED ----------------------------------------------------------------------------
        update FAL_NETWORK_NEED
           set A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             , A_DATEMOD = sysdate
             ,
               -- Dossier
               DOC_RECORD_ID = aDocRecordID
             ,
               -- Debut Planif
               FAN_BEG_PLAN = aBeginEndPlanDate
             ,
               -- Fin Planif
               FAN_END_PLAN = aBeginEndPlanDate
             ,
               -- Stock
               STM_STOCK_ID = aStockID
             ,
               -- Emplacement de stock
               STM_LOCATION_ID = aLocationID
             ,
               -- Qte Solde
               FAN_BALANCE_QTY = aQteSolde
             ,
               -- Qte Libre
               FAN_FREE_QTY = aQteLibre
             ,
               -- Qte Att Stock
               FAN_STK_QTY = aQteAttStock
             ,
               -- Qte Att Besoin Appro
               FAN_NETW_QTY = aQteAttBesoin
         where current of GetNeedRecordForUpdate2;
      -- FIN : if aComposantConcerne.LOM_NEED_QTY <= 0 THEN ...
      end if;
    -- FIN : IF GetNeedRecord%FOUND THEN ...
    end if;

    -- fermeture du curseur GetNeedRecordForUpdate2
    close GetNeedRecordForUpdate2;
  end;

-- PROCEDURE Attribution_MAJ_DateAppro ()
--
-- Mise à jour de la Date Appro pour les attributions
  procedure Attribution_MAJ_DateAppro(aSupplyID in TTypeID, aEndPlanDate in TTypeDate)
  is
  begin
    if aEndPlanDate is not null then
      -- Modification pour Attribution Non sur Stock ...
      update FAL_NETWORK_LINK
         set FLN_SUPPLY_DELAY = aEndPlanDate
           , FLN_NEED_DELAY =(case
                                when STM_LOCATION_ID is null then FLN_NEED_DELAY
                                else aEndPlanDate
                              end)
           , FLN_MARGIN =(case
                            when STM_LOCATION_ID is null then FLN_NEED_DELAY - aEndPlanDate
                            else 0
                          end)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_NETWORK_SUPPLY_ID = aSupplyID;
    end if;
  end;

-- PROCEDURE Attribution_MAJ_DateBesoin ()
--
-- Mise à jour de la Date Besoin pour les attributions
  procedure Attribution_MAJ_DateBesoin(aNeedID in TTypeID, aBeginPlanDate in TTypeDate)
  is
  begin
    if aBeginPlanDate is not null then
      -- Modification pour Attribution Non sur Stock ...
      update FAL_NETWORK_LINK
         set FLN_NEED_DELAY = aBeginPlanDate
           , FLN_SUPPLY_DELAY =(case
                                  when STM_LOCATION_ID is null then FLN_SUPPLY_DELAY
                                  else aBeginPlanDate
                                end)
           , FLN_MARGIN =(case
                            when STM_LOCATION_ID is null then aBeginPlanDate - FLN_SUPPLY_DELAY
                            else 0
                          end)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_NETWORK_NEED_ID = aNeedID;
    end if;
  end;

-- PROCEDURE Attribution_MAJ_ApproStock ()
--
-- Mise à jour Appro Stock
  procedure Attribution_MAJ_ApproStock(
    aSupplyID  in TTypeID
  , aBeforeQty in FAL_NETWORK_SUPPLY.FAN_STK_QTY%type
  , aAfterQty  in FAL_NETWORK_SUPPLY.FAN_STK_QTY%type
  )
  is
    aLinkRec GetLinks_SupplyStockForUpdate%rowtype;
    X        FAL_NETWORK_SUPPLY.FAN_STK_QTY%type;
    Y        FAL_NETWORK_SUPPLY.FAN_STK_QTY%type;
  begin
    -- Initialiser X ...
    X  := nvl(aBeforeQty, 0) - nvl(aAfterQty, 0);

    if X <> 0 then
      open GetLinks_SupplyStockForUpdate(aSupplyID);

      loop
        fetch GetLinks_SupplyStockForUpdate
         into aLinkRec;

        exit when GetLinks_SupplyStockForUpdate%notfound;
        Y  := X - nvl(aLinkRec.FLN_QTY, 0);

        if Y < 0 then
          -- Mise à jour Attribution Appro ----------------------------------------------------------------
          update FAL_NETWORK_LINK
             set FLN_QTY = -Y
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where current of GetLinks_SupplyStockForUpdate;

          -- Mise à jour Position Stock -------------------------------------------------------------------
          exit;
        -- SINON : IF Y < 0 THEN
        else
          -- Suppression Attribution ----------------------------------------------------------------------
          delete from FAL_NETWORK_LINK
                where current of GetLinks_SupplyStockForUpdate;
        -- Mise à jour Position Stock -------------------------------------------------------------------

        -- FIN : IF Y < 0 THEN
        end if;

        -- Attribution suivante  ...
        X  := Y;
      end loop;

      close GetLinks_SupplyStockForUpdate;
    -- FIN : If X <> 0 THEN
    end if;
  exception
    when others then
      close GetLinks_SupplyStockForUpdate;

      raise;
  end;

-- PROCEDURE Attribution_MAJ_BesoinStock ()
--
-- Mise à jour Besoin Stock
  procedure Attribution_MAJ_BesoinStock(
    aNeedID    in TTypeID
  , aBeforeQty in FAL_NETWORK_NEED.FAN_STK_QTY%type
  , aAfterQty  in FAL_NETWORK_NEED.FAN_STK_QTY%type
  , aAttribID  in FAL_NETWORK_LINK.FAL_NETWORK_LINK_ID%type
  )
  is
    aLinkRec                 GetLinks_NeedStockForUpdate%rowtype;
    X                        FAL_NETWORK_NEED.FAN_STK_QTY%type;
    Y                        FAL_NETWORK_NEED.FAN_STK_QTY%type;
    OldFLN_QTY               FAL_NETWORK_LINK.FLN_QTY%type;
    OldSTM_STOCK_POSITION_ID FAL_NETWORK_LINK.STM_STOCK_POSITION_ID%type;
    bContinue                boolean;
    flnQuantity              FAL_NETWORK_LINK.FLN_QTY%type;
    flnStockPositionID       FAL_NETWORK_LINK.STM_STOCK_POSITION_ID%type;
  begin
    -- Initialiser X ...
    X  := nvl(aBeforeQty, 0) - nvl(aAfterQty, 0);

    if X <> 0 then
      if aAttribID is not null then
        bContinue  := true;

        begin
          select     nvl(FLN.FLN_QTY, 0)
                   , FLN.STM_STOCK_POSITION_ID
                into flnQuantity
                   , flnStockPositionID
                from FAL_NETWORK_LINK FLN
               where FLN.FAL_NETWORK_LINK_ID = aAttribID
          for update;
        exception
          when no_data_found then
            bContinue  := false;
        end;

        if bContinue then
          Y  := X - flnQuantity;

          if (Y < 0) then
            -- Mise à jour Attribution Appro ----------------------------------------------------------------
            update FAL_NETWORK_LINK
               set FLN_QTY = -Y
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where FAL_NETWORK_LINK_ID = aAttribID;

            -- Mise à jour Position Stock 2 -----------------------------------------------------------------
            update STM_STOCK_POSITION
               set SPO_ASSIGN_QUANTITY = nvl(SPO_ASSIGN_QUANTITY, 0) -(flnQuantity -(-Y) )
                 , SPO_AVAILABLE_QUANTITY = nvl(SPO_AVAILABLE_QUANTITY, 0) +(flnQuantity -(-Y) )
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where STM_STOCK_POSITION_ID = flnStockPositionID;
          else
            -- Suppression Attribution ----------------------------------------------------------------------
            delete from FAL_NETWORK_LINK
                  where FAL_NETWORK_LINK_ID = aAttribID;

            -- Mise à jour Position Stock 1 -----------------------------------------------------------------
            update STM_STOCK_POSITION
               set SPO_ASSIGN_QUANTITY = nvl(SPO_ASSIGN_QUANTITY, 0) -(flnQuantity)
                 , SPO_AVAILABLE_QUANTITY = nvl(SPO_AVAILABLE_QUANTITY, 0) +(flnQuantity)
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where STM_STOCK_POSITION_ID = flnStockPositionID;
          end if;
        end if;
      else
        open GetLinks_NeedStockForUpdate(aNeedID);

        loop
          fetch GetLinks_NeedStockForUpdate
           into aLinkRec;

          exit when GetLinks_NeedStockForUpdate%notfound;
          Y                         := X - nvl(aLinkRec.FLN_QTY, 0);
          OldFLN_QTY                := nvl(aLinkRec.FLN_QTY, 0);
          OldSTM_STOCK_POSITION_ID  := aLinkRec.STM_STOCK_POSITION_ID;

          if Y < 0 then
            -- Mise à jour Attribution Appro ----------------------------------------------------------------
            update FAL_NETWORK_LINK
               set FLN_QTY = -Y
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where current of GetLinks_NeedStockForUpdate;

            -- Mise à jour Position Stock 2 -----------------------------------------------------------------
            update STM_STOCK_POSITION
               set SPO_ASSIGN_QUANTITY = nvl(SPO_ASSIGN_QUANTITY, 0) -(OldFLN_QTY -(-Y) )
                 , SPO_AVAILABLE_QUANTITY = nvl(SPO_AVAILABLE_QUANTITY, 0) +(OldFLN_QTY -(-Y) )
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where STM_STOCK_POSITION_ID = OldSTM_STOCK_POSITION_ID;

            exit;
          -- SINON : IF Y < 0 THEN
          else
            -- Suppression Attribution ----------------------------------------------------------------------
            delete from FAL_NETWORK_LINK
                  where current of GetLinks_NeedStockForUpdate;

            -- Mise à jour Position Stock 1 -----------------------------------------------------------------
            update STM_STOCK_POSITION
               set SPO_ASSIGN_QUANTITY = nvl(SPO_ASSIGN_QUANTITY, 0) -(OldFLN_QTY)
                 , SPO_AVAILABLE_QUANTITY = nvl(SPO_AVAILABLE_QUANTITY, 0) +(OldFLN_QTY)
                 , A_DATEMOD = sysdate
                 , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             where STM_STOCK_POSITION_ID = OldSTM_STOCK_POSITION_ID;

            -- Attribution suivante  ...
            X  := Y;
          -- FIN : IF Y < 0 THEN
          end if;
        end loop;

        close GetLinks_NeedStockForUpdate;
      end if;
    -- FIN : If X <> 0 THEN
    end if;
  exception
    when others then
      close GetLinks_NeedStockForUpdate;

      raise;
  end;

-- PROCEDURE Attribution_Suppr_ApproStock ()
--
-- Suppression Appro Stock
  procedure Attribution_Suppr_ApproStock(aSupplyID in TTypeID)
  is
    aLinkRec GetLinks_SupplyStockForUpdate%rowtype;
  begin
    open GetLinks_SupplyStockForUpdate(aSupplyID);

    loop
      fetch GetLinks_SupplyStockForUpdate
       into aLinkRec;

      exit when GetLinks_SupplyStockForUpdate%notfound;

      -- Suppression Attribution ----------------------------------------------------------------------
      delete from FAL_NETWORK_LINK
            where current of GetLinks_SupplyStockForUpdate;
    -- Mise à jour Position Stock -------------------------------------------------------------------
    end loop;

    close GetLinks_SupplyStockForUpdate;
  exception
    when others then
      close GetLinks_SupplyStockForUpdate;

      raise;
  end;

-- PROCEDURE Attribution_Suppr_BesoinStock ()
--
-- Suppression Besoin Stock
  procedure Attribution_Suppr_BesoinStock(aNeedID in TTypeID)
  is
    aLinkRec GetLinks_NeedStockForUpdate%rowtype;
  begin
    open GetLinks_NeedStockForUpdate(aNeedID);

    loop
      fetch GetLinks_NeedStockForUpdate
       into aLinkRec;

      exit when GetLinks_NeedStockForUpdate%notfound;

      -- Mise à jour Position Stock 1 -----------------------------------------------------------------
      update STM_STOCK_POSITION
         set SPO_ASSIGN_QUANTITY = nvl(SPO_ASSIGN_QUANTITY, 0) -(nvl(aLinkRec.FLN_QTY, 0) )
           , SPO_AVAILABLE_QUANTITY = nvl(SPO_AVAILABLE_QUANTITY, 0) +(nvl(aLinkRec.FLN_QTY, 0) )
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where STM_STOCK_POSITION_ID = aLinkRec.STM_STOCK_POSITION_ID;

      -- Suppression Attribution ----------------------------------------------------------------------
      delete from FAL_NETWORK_LINK
            where current of GetLinks_NeedStockForUpdate;
    end loop;

    close GetLinks_NeedStockForUpdate;
  exception
    when others then
      close GetLinks_NeedStockForUpdate;

      raise;
  end;

-- PROCEDURE Attribution_MAJ_ApproBesoin ()
--
-- Mise à jour Appro Besoin
  procedure Attribution_MAJ_ApproBesoin(
    aSupplyID  in TTypeID
  , aBeforeQty in FAL_NETWORK_SUPPLY.FAN_NETW_QTY%type
  , aAfterQty  in FAL_NETWORK_SUPPLY.FAN_NETW_QTY%type
  )
  is
    aLinkRec GetLinks_SupplyNeedForUpdate%rowtype;
    X        FAL_NETWORK_SUPPLY.FAN_NETW_QTY%type;
    Y        FAL_NETWORK_SUPPLY.FAN_NETW_QTY%type;
  begin
    X  := nvl(aBeforeQty, 0) - nvl(aAfterQty, 0);

    if X <> 0 then
      open GetLinks_SupplyNeedForUpdate(aSupplyID);

      loop
        fetch GetLinks_SupplyNeedForUpdate
         into aLinkRec;

        exit when GetLinks_SupplyNeedForUpdate%notfound;
        Y  := X - nvl(aLinkRec.FLN_QTY, 0);

        if Y < 0 then
          -- Mise à jour Attribution Appro ----------------------------------------------------------------
          update FAL_NETWORK_LINK
             set FLN_QTY = -Y
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where current of GetLinks_SupplyNeedForUpdate;

          -- Mise à jour Reseaux Besoin -------------------------------------------------------------------
          update FAL_NETWORK_NEED
             set FAN_NETW_QTY = nvl(FAN_NETW_QTY, 0) - X
               , FAN_FREE_QTY = nvl(FAN_FREE_QTY, 0) + X
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where FAL_NETWORK_NEED_ID = aLinkRec.FAL_NETWORK_NEED_ID;

          exit;
        else
          -- Mise à jour Reseaux Besoin -------------------------------------------------------------------
          update FAL_NETWORK_NEED
             set FAN_NETW_QTY = nvl(FAN_NETW_QTY, 0) - nvl(aLinkRec.FLN_QTY, 0)
               , FAN_FREE_QTY = nvl(FAN_FREE_QTY, 0) + nvl(aLinkRec.FLN_QTY, 0)
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where FAL_NETWORK_NEED_ID = aLinkRec.FAL_NETWORK_NEED_ID;

          -- Suppression Attribution ----------------------------------------------------------------------
          delete from FAL_NETWORK_LINK
                where current of GetLinks_SupplyNeedForUpdate;
        end if;

        -- Attribution suivante  ...
        X  := Y;
      end loop;

      close GetLinks_SupplyNeedForUpdate;
    end if;
  exception
    when others then
      close GetLinks_SupplyNeedForUpdate;

      raise;
  end;

-- PROCEDURE Attrib_MAJ_ApproBesoin_PT ()
-- Mise à jour Appro Besoin pour la réception PT...
  procedure Attrib_MAJ_ApproBesoin_PT(
    aSupplyID        in TTypeID
  , aBeforeQty       in FAL_NETWORK_SUPPLY.FAN_NETW_QTY%type
  , aAfterQty        in FAL_NETWORK_SUPPLY.FAN_NETW_QTY%type
  , aStockPositionID in varchar2
  )
  is
    aLinkRec GetLinks_SupplyNeedForUpdatePT%rowtype;
    X        FAL_NETWORK_SUPPLY.FAN_NETW_QTY%type;
    Y        FAL_NETWORK_SUPPLY.FAN_NETW_QTY%type;
  begin
    -- Initialiser X ...
    X  := nvl(aBeforeQty, 0) - nvl(aAfterQty, 0);

    if X <> 0 then
      open GetLinks_SupplyNeedForUpdatePT(aSupplyID);

      loop
        fetch GetLinks_SupplyNeedForUpdatePT
         into aLinkRec;

        exit when GetLinks_SupplyNeedForUpdatePT%notfound;
        Y  := X - nvl(aLinkRec.FLN_QTY, 0);

        if Y < 0 then
          -- Mise à jour Attribution Appro ----------------------------------------------------------------
          update FAL_NETWORK_LINK
             set FLN_QTY = -Y
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where current of GetLinks_SupplyNeedForUpdatePT;

          -- Mise à jour Reseaux Besoin -------------------------------------------------------------------
          update FAL_NETWORK_NEED
             set FAN_NETW_QTY = nvl(FAN_NETW_QTY, 0) - X
               , FAN_FREE_QTY = nvl(FAN_FREE_QTY, 0) + X
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where FAL_NETWORK_NEED_ID = aLinkRec.FAL_NETWORK_NEED_ID;

          -- Contrôle et création attribution pour le processus de gestion des attributions complètes
          Attribution_Complete(aLinkRec.FAL_NETWORK_NEED_ID, aStockPositionID, X);
          exit;
        -- SINON : IF Y < 0 THEN
        else
          -- Mise à jour Reseaux Besoin -------------------------------------------------------------------
          update FAL_NETWORK_NEED
             set FAN_NETW_QTY = nvl(FAN_NETW_QTY, 0) - nvl(aLinkRec.FLN_QTY, 0)
               , FAN_FREE_QTY = nvl(FAN_FREE_QTY, 0) + nvl(aLinkRec.FLN_QTY, 0)
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where FAL_NETWORK_NEED_ID = aLinkRec.FAL_NETWORK_NEED_ID;

          -- Suppression Attribution ----------------------------------------------------------------------
          delete from FAL_NETWORK_LINK
                where current of GetLinks_SupplyNeedForUpdatePT;

          -- Contrôle et création attribution pour le processus de gestion des attributions complètes
          Attribution_Complete(aLinkRec.FAL_NETWORK_NEED_ID, aStockPositionID, aLinkRec.FLN_QTY);
        -- FIN : IF Y < 0 THEN
        end if;

        -- Attribution suivante  ...
        X  := Y;

        if X = 0 then
          exit;
        end if;
      end loop;

      close GetLinks_SupplyNeedForUpdatePT;
    -- FIN : If X <> 0 THEN
    end if;
  exception
    when others then
      close GetLinks_SupplyNeedForUpdatePT;

      raise;
  end;

-- PROCEDURE Attribution_MAJ_BesoinAppro ()
--
-- Mise à jour Besoin Appro
  procedure Attribution_MAJ_BesoinAppro(
    aNeedID    in TTypeID
  , aBeforeQty in FAL_NETWORK_NEED.FAN_NETW_QTY%type
  , aAfterQty  in FAL_NETWORK_NEED.FAN_NETW_QTY%type
  )
  is
    aLinkRec GetLinks_NeedSupplyForUpdate%rowtype;
    X        FAL_NETWORK_NEED.FAN_NETW_QTY%type;
    Y        FAL_NETWORK_NEED.FAN_NETW_QTY%type;
  begin
    -- Initialiser X ...
    X  := nvl(aBeforeQty, 0) - nvl(aAfterQty, 0);

    if X <> 0 then
      open GetLinks_NeedSupplyForUpdate(aNeedID);

      loop
        fetch GetLinks_NeedSupplyForUpdate
         into aLinkRec;

        exit when GetLinks_NeedSupplyForUpdate%notfound;
        Y  := X - nvl(aLinkRec.FLN_QTY, 0);

        if Y < 0 then
          -- Mise à jour Attribution Appro ----------------------------------------------------------------
          update FAL_NETWORK_LINK
             set FLN_QTY = -Y
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where current of GetLinks_NeedSupplyForUpdate;

          -- Mise à jour Reseaux Appro --------------------------------------------------------------------
          update FAL_NETWORK_SUPPLY
             set FAN_NETW_QTY = nvl(FAN_NETW_QTY, 0) - X
               , FAN_FREE_QTY = nvl(FAN_FREE_QTY, 0) + X
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where FAL_NETWORK_SUPPLY_ID = aLinkRec.FAL_NETWORK_SUPPLY_ID;

          exit;
        -- SINON : IF Y < 0 THEN
        else
          -- Mise à jour Reseaux Appro --------------------------------------------------------------------
          update FAL_NETWORK_SUPPLY
             set FAN_NETW_QTY = nvl(FAN_NETW_QTY, 0) - nvl(aLinkRec.FLN_QTY, 0)
               , FAN_FREE_QTY = nvl(FAN_FREE_QTY, 0) + nvl(aLinkRec.FLN_QTY, 0)
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where FAL_NETWORK_SUPPLY_ID = aLinkRec.FAL_NETWORK_SUPPLY_ID;

          -- Suppression Attribution ----------------------------------------------------------------------
          delete from FAL_NETWORK_LINK
                where current of GetLinks_NeedSupplyForUpdate;
        -- FIN : IF Y < 0 THEN
        end if;

        -- Attribution suivante  ...
        X  := Y;
      end loop;

      close GetLinks_NeedSupplyForUpdate;
    -- FIN : If X <> 0 THEN
    end if;
  exception
    when others then
      close GetLinks_NeedSupplyForUpdate;

      raise;
  end;

/**
* procedure AttribMAJBesoinApproDecrPOA
* Description : Mise à jour des attributions besoins - Appro, avec un ordre de compensation
*               différent de l'ordre classique, c'est à dire que l'on commence par diminuer
*               les PO, et ensuite les appro logistique
* @author ECA
* @lastUpdate
* @public
* @param
*/
  procedure AttribMAJBesoinApproDecrPOx(
    aFAL_NETWORK_NEED_ID in TTypeID
  , aBeforeQty           in FAL_NETWORK_NEED.FAN_NETW_QTY%type
  , aAfterQty            in FAL_NETWORK_NEED.FAN_NETW_QTY%type
  , PrmFAL_DOC_PROP_ID   in FAL_DOC_PROP.FAL_DOC_PROP_ID%type default null
  )
  is
    -- ECA : Sélection des attrib sur appro du besoin FAL_NETWORK_NEED_ID, triés par Type d'appro
    -- (D'abord POx, ensuite les autre appro) et délai décroissant (Utilisation uniquement dans le cadre
    -- du CB avec blocs d'équivalence sur Stock
    cursor GetLinksNeedSupDecPOAForUpdt(aFAL_NETWORK_NEED_ID in TTypeID, aFAL_DOC_PROP_ID in TTypeID default null)
    is
      select     FNL.FAL_NETWORK_NEED_ID
               , FNL.FAL_NETWORK_LINK_ID
               , FNL.FAL_NETWORK_SUPPLY_ID
               , FNL.FLN_QTY
               , decode(nvl(FNS.FAL_DOC_PROP_ID, 0), 0, 0, aFAL_DOC_PROP_ID, 2, 1) FIRST_SORT_ORDER
            from FAL_NETWORK_LINK FNL
               , FAL_NETWORK_SUPPLY FNS
           where FNL.FAL_NETWORK_NEED_ID = aFAL_NETWORK_NEED_ID
             and FNL.FAL_NETWORK_SUPPLY_ID is not null
             and FNL.FAL_NETWORK_SUPPLY_ID = FNS.FAL_NETWORK_SUPPLY_ID
        order by decode(nvl(FNS.FAL_DOC_PROP_ID, 0), 0, 0, aFAL_DOC_PROP_ID, 2, 1) desc
               , FNL.FLN_SUPPLY_DELAY desc
      for update;

    aLinkRec GetLinksNeedSupDecPOAForUpdt%rowtype;
    X        FAL_NETWORK_NEED.FAN_NETW_QTY%type;
    Y        FAL_NETWORK_NEED.FAN_NETW_QTY%type;
  begin
    -- Initialiser X ...
    X  := nvl(aBeforeQty, 0) - nvl(aAfterQty, 0);

    if X <> 0 then
      open GetLinksNeedSupDecPOAForUpdt(aFAL_NETWORK_NEED_ID, PrmFAL_DOC_PROP_ID);

      loop
        fetch GetLinksNeedSupDecPOAForUpdt
         into aLinkRec;

        exit when GetLinksNeedSupDecPOAForUpdt%notfound;
        Y  := X - nvl(aLinkRec.FLN_QTY, 0);

        if Y < 0 then
          -- Mise à jour Attribution Appro ----------------------------------------------------------------
          update FAL_NETWORK_LINK
             set FLN_QTY = -Y
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where FAL_NETWORK_LINK_ID = aLinkRec.FAL_NETWORK_LINK_ID;

          -- Mise à jour Reseaux Appro --------------------------------------------------------------------
          update FAL_NETWORK_SUPPLY
             set FAN_NETW_QTY = nvl(FAN_NETW_QTY, 0) - X
               , FAN_FREE_QTY = nvl(FAN_FREE_QTY, 0) + X
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where FAL_NETWORK_SUPPLY_ID = aLinkRec.FAL_NETWORK_SUPPLY_ID;

          exit;
        -- SINON : IF Y < 0 THEN
        else
          -- Mise à jour Reseaux Appro --------------------------------------------------------------------
          update FAL_NETWORK_SUPPLY
             set FAN_NETW_QTY = nvl(FAN_NETW_QTY, 0) - nvl(aLinkRec.FLN_QTY, 0)
               , FAN_FREE_QTY = nvl(FAN_FREE_QTY, 0) + nvl(aLinkRec.FLN_QTY, 0)
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where FAL_NETWORK_SUPPLY_ID = aLinkRec.FAL_NETWORK_SUPPLY_ID;

          -- Suppression Attribution ----------------------------------------------------------------------
          delete from FAL_NETWORK_LINK
                where FAL_NETWORK_LINK_ID = aLinkRec.FAL_NETWORK_LINK_ID;
        -- FIN : IF Y < 0 THEN
        end if;

        -- Attribution suivante  ...
        X  := Y;
      end loop;

      close GetLinksNeedSupDecPOAForUpdt;
    -- FIN : If X <> 0 THEN
    end if;
  exception
    when others then
      close GetLinksNeedSupDecPOAForUpdt;

      raise;
  end AttribMAJBesoinApproDecrPOx;

-- PROCEDURE Attribution_Suppr_ApproBesoin ()
--
-- Suppression Appro Besoin
  procedure Attribution_Suppr_ApproBesoin(aSupplyID in TTypeID, iStockPositionId in varchar2 default null)
  is
    aLinkRec GetLinks_SupplyNeedForUpdate%rowtype;
  begin
    open GetLinks_SupplyNeedForUpdate(aSupplyID);

    loop
      fetch GetLinks_SupplyNeedForUpdate
       into aLinkRec;

      exit when GetLinks_SupplyNeedForUpdate%notfound;

      -- Mise à jour Reseaux Besoin -------------------------------------------------------------------
      update FAL_NETWORK_NEED
         set FAN_NETW_QTY = nvl(FAN_NETW_QTY, 0) - nvl(aLinkRec.FLN_QTY, 0)
           , FAN_FREE_QTY = nvl(FAN_FREE_QTY, 0) + nvl(aLinkRec.FLN_QTY, 0)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_NETWORK_NEED_ID = aLinkRec.FAL_NETWORK_NEED_ID;

      -- Suppression Attribution ----------------------------------------------------------------------
      delete from FAL_NETWORK_LINK
            where current of GetLinks_SupplyNeedForUpdate;
    end loop;

    /* Report des attribution sur les positions de stock en réception */
    Attribution_Complete(aLinkRec.FAL_NETWORK_NEED_ID, iStockPositionId, aLinkRec.FLN_QTY);

    close GetLinks_SupplyNeedForUpdate;
  exception
    when others then
      close GetLinks_SupplyNeedForUpdate;

      raise;
  end;

-- PROCEDURE Attrib_Suppr_ApproBesoin_PT ()
--
-- Suppression Appro Besoin pour réception PT...
  procedure Attrib_Suppr_ApproBesoin_PT(aSupplyID in TTypeID, aStockPositionID in varchar2)
  is
    aLinkRec GetLinks_SupplyNeedForUpdatePT%rowtype;
  begin
    open GetLinks_SupplyNeedForUpdatePT(aSupplyID);

    loop
      fetch GetLinks_SupplyNeedForUpdatePT
       into aLinkRec;

      exit when GetLinks_SupplyNeedForUpdatePT%notfound;

      -- Mise à jour Reseaux Besoin -------------------------------------------------------------------
      update FAL_NETWORK_NEED
         set FAN_NETW_QTY = nvl(FAN_NETW_QTY, 0) - nvl(aLinkRec.FLN_QTY, 0)
           , FAN_FREE_QTY = nvl(FAN_FREE_QTY, 0) + nvl(aLinkRec.FLN_QTY, 0)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_NETWORK_NEED_ID = aLinkRec.FAL_NETWORK_NEED_ID;

      -- Suppression Attribution ----------------------------------------------------------------------
      delete from FAL_NETWORK_LINK
            where current of GetLinks_SupplyNeedForUpdatePT;

      -- Contrôle et création attribution pour le processus de gestion des attributions complètes
      Attribution_Complete(aLinkRec.FAL_NETWORK_NEED_ID, aStockPositionID, aLinkRec.FLN_QTY);
    end loop;

    close GetLinks_SupplyNeedForUpdatePT;
  exception
    when others then
      close GetLinks_SupplyNeedForUpdatePT;

      raise;
  end;

-- PROCEDURE Attribution_Suppr_BesoinAppro ()
--
-- Suppression Besoin Appro
  procedure Attribution_Suppr_BesoinAppro(aNeedID in TTypeID)
  is
    aLinkRec GetLinks_NeedSupplyForUpdate%rowtype;
  begin
    open GetLinks_NeedSupplyForUpdate(aNeedID);

    loop
      fetch GetLinks_NeedSupplyForUpdate
       into aLinkRec;

      exit when GetLinks_NeedSupplyForUpdate%notfound;

      -- Mise à jour Reseaux Besoin -------------------------------------------------------------------
      update FAL_NETWORK_SUPPLY
         set FAN_NETW_QTY = nvl(FAN_NETW_QTY, 0) - nvl(aLinkRec.FLN_QTY, 0)
           , FAN_FREE_QTY = nvl(FAN_FREE_QTY, 0) + nvl(aLinkRec.FLN_QTY, 0)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_NETWORK_SUPPLY_ID = aLinkRec.FAL_NETWORK_SUPPLY_ID;

      -- Suppression Attribution ----------------------------------------------------------------------
      delete from FAL_NETWORK_LINK
            where current of GetLinks_NeedSupplyForUpdate;
    end loop;

    close GetLinks_NeedSupplyForUpdate;
  exception
    when others then
      close GetLinks_NeedSupplyForUpdate;

      raise;
  end;

  /***
  * procedure CreateAttribBesoinAppro
  *
  * Procédure de création d'une attribution besoin sur approvisionnement.
  */
  procedure CreateAttribBesoinAppro(PrmFAL_NETWORK_NEED_ID TTypeID, PrmId_reseauxApprocree TTypeID, PrmA FAL_LOT.LOT_TOTAL_QTY%type)
  is
    cursor CUR_NETWORK_LOCKING
    is
      select        FNS.FAN_END_PLAN FNS_END_PLAN
                  , FNS.FAN_FREE_QTY FNS_FREE_QTY
                  , FNN.FAN_BEG_PLAN FNN_BEG_PLAN
                  , FNN.FAN_FREE_QTY FNN_FREE_QTY
               from FAL_NETWORK_SUPPLY FNS
                  , FAL_NETWORK_NEED FNN
              where FAL_NETWORK_SUPPLY_ID = PrmId_reseauxApprocree
                and FAL_NETWORK_NEED_ID = PrmFAL_NETWORK_NEED_ID
      for update of FNS.FAN_FREE_QTY, FNN.FAN_FREE_QTY nowait;

    CurNetworkLocking CUR_NETWORK_LOCKING%rowtype;
  begin
    if nvl(PrmA, 0) > 0 then
      -- D'abord récupérer et bloquer les valeurs du FAL_NETWORK_SUPPLY et du FAL_NETWORK_NEED
      open CUR_NETWORK_LOCKING;

      fetch CUR_NETWORK_LOCKING
       into CurNetworkLocking;

      -- Vérification des quantités
      if nvl(PrmA, 0) > nvl(CurNetworkLocking.FNN_FREE_QTY, 0) then
        raise_application_error(-20010
                              , 'PCS - ' ||
                                excLinkQtyTooHighMsg ||
                                co.cLineBreak ||
                                PCS.PC_FUNCTIONS.TranslateWord('Qté à attribuer') ||
                                ' : ' ||
                                PrmA ||
                                co.cLineBreak ||
                                PCS.PC_FUNCTIONS.TranslateWord('Qté libre') ||
                                ' : ' ||
                                CurNetworkLocking.FNN_FREE_QTY
                               );
      end if;

      if nvl(PrmA, 0) > nvl(CurNetworkLocking.FNS_FREE_QTY, 0) then
        raise_application_error(-20010
                              , 'PCS - ' ||
                                excLinkQtyTooHighMsg ||
                                co.cLineBreak ||
                                PCS.PC_FUNCTIONS.TranslateWord('Qté à attribuer') ||
                                ' : ' ||
                                PrmA ||
                                co.cLineBreak ||
                                PCS.PC_FUNCTIONS.TranslateWord('Qté libre') ||
                                ' : ' ||
                                CurNetworkLocking.FNS_FREE_QTY
                               );
      end if;

      -- Processus : Création Attribution Besoin sur Appro
      insert into FAL_NETWORK_LINK
                  (FAL_NETWORK_LINK_ID
                 , FAL_NETWORK_SUPPLY_ID
                 , FAL_NETWORK_NEED_ID
                 , FLN_SUPPLY_DELAY
                 , FLN_NEED_DELAY
                 , FLN_MARGIN
                 , FLN_QTY
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , PrmId_reseauxApprocree
                 , PrmFAL_NETWORK_NEED_ID
                 , CurNetworkLocking.FNS_END_PLAN
                 , CurNetworkLocking.FNN_BEG_PLAN
                 , CurNetworkLocking.FNN_BEG_PLAN - CurNetworkLocking.FNS_END_PLAN
                 , nvl(PrmA, 0)
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      -- Processus : Report sur Réseau Besoin
      update FAL_NETWORK_NEED
         set FAN_FREE_QTY = nvl(FAN_FREE_QTY, 0) - nvl(PrmA, 0)
           , FAN_NETW_QTY = nvl(FAN_NETW_QTY, 0) + nvl(PrmA, 0)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_NETWORK_NEED_ID = PrmFAL_NETWORK_NEED_ID;

      -- Processus : Report sur Réseau Appro
      update FAL_NETWORK_SUPPLY
         set FAN_FREE_QTY = nvl(FAN_FREE_QTY, 0) - nvl(PrmA, 0)
           , FAN_NETW_QTY = nvl(FAN_NETW_QTY, 0) + nvl(PrmA, 0)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_NETWORK_SUPPLY_ID = PrmId_reseauxApprocree;

      close CUR_NETWORK_LOCKING;
    end if;
  exception
    when ex.ROW_LOCKED then
      raise_application_error(-20020, 'PCS - ' || eLockedNetwExceptionMsg);
    when no_data_found then
      null;
    when others then
      raise;
  end;

  /***
  * procedure CreateAttribBesoinAppro
  *
  * Idem procédure précédente avec retour d'un message d'erreur en cas de probl
  */
  procedure CreateAttribBesoinAppro(
    aFAL_NETWORK_NEED_ID   in     TTypeID
  , aFAL_NETWORK_SUPPLY_ID in     TTypeID
  , aQtyToAllocate         in     FAL_LOT.LOT_TOTAL_QTY%type
  , aErrorCode             in out varchar2
  )
  is
  begin
    if nvl(aQtyToAllocate, 0) <> 0 then
      CreateAttribBesoinAppro(aFAL_NETWORK_NEED_ID, aFAL_NETWORK_SUPPLY_ID, aQtyToAllocate);
    end if;
  exception
    when eLockedNetwException then
      aErrorCode  := 'eLockedNetwException';
    when excLinkQtyTooHigh then
      aErrorCode  := 'excLinkQtyTooHigh';
    when no_data_found then
      null;
    when others then
      raise;
  end;

  -- Création Attributions Appro sur stock (location)...
  procedure CreateAttribApproStock(
    PrmId_reseauxApprocree TTypeID
  , PrmLocationID          TTypeID
  , PrmA                   FAL_LOT.LOT_TOTAL_QTY%type
  , aFAN_END_PLAN          FAL_NETWORK_SUPPLY.FAN_END_PLAN%type default null
  , aFAN_FREE_QTY          FAL_NETWORK_SUPPLY.FAN_FREE_QTY%type default null
  )
  is
    cursor CUR_NETWORK_LOCKING
    is
      select        fns.fan_end_plan
                  , fns.fan_free_qty
               from fal_network_supply fns
              where fns.fal_network_supply_id = PrmId_reseauxApprocree
      for update of fns.fan_free_qty nowait;

    CurNetworkLocking CUR_NETWORK_LOCKING%rowtype;
    LocFAN_END_PLAN   FAL_NETWORK_SUPPLY.FAN_END_PLAN%type;
    LocFAN_FREE_QTY   FAL_NETWORK_SUPPLY.FAN_FREE_QTY%type;
  begin
    if nvl(prmA, 0) <> 0 then
      if    (aFAN_END_PLAN is null)
         or (aFAN_FREE_QTY is null) then
        -- D'abord récupérer et bloquer les valeurs du FAL_NETWORK_SUPPLY
        open CUR_NETWORK_LOCKING;

        fetch CUR_NETWORK_LOCKING
         into CurNetworkLocking;

        LocFAN_END_PLAN  := CurNetworkLocking.FAN_END_PLAN;
        LocFAN_FREE_QTY  := CurNetworkLocking.FAN_FREE_QTY;
      else
        LocFAN_END_PLAN  := aFAN_END_PLAN;
        LocFAN_FREE_QTY  := aFAN_FREE_QTY;
      end if;

      -- Vérification ...
      if nvl(PrmA, 0) > nvl(LocFAN_FREE_QTY, 0) then
        raise_application_error(-20010
                              , 'PCS - ' ||
                                excLinkQtyTooHighMsg ||
                                co.cLineBreak ||
                                PCS.PC_FUNCTIONS.TranslateWord('Qté à attribuer') ||
                                ' : ' ||
                                PrmA ||
                                co.cLineBreak ||
                                PCS.PC_FUNCTIONS.TranslateWord('Qté libre') ||
                                ' : ' ||
                                LocFAN_FREE_QTY
                               );
      end if;

      -- Processus : Création Attribution Appro sur Stock ...
      insert into FAL_NETWORK_LINK
                  (FAL_NETWORK_LINK_ID
                 , STM_LOCATION_ID
                 , FAL_NETWORK_SUPPLY_ID
                 , FLN_SUPPLY_DELAY
                 , FLN_NEED_DELAY
                 , FLN_MARGIN
                 , FLN_QTY
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , PrmLocationID
                 , PrmId_reseauxApprocree
                 , LocFAN_END_PLAN
                 , LocFAN_END_PLAN
                 , 0
                 , nvl(PrmA, 0)
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      -- Processus : Report sur Réseau Appro ...
      update FAL_NETWORK_SUPPLY
         set FAN_FREE_QTY = nvl(FAN_FREE_QTY, 0) - nvl(PrmA, 0)
           , FAN_STK_QTY = nvl(FAN_STK_QTY, 0) + nvl(PrmA, 0)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_NETWORK_SUPPLY_ID = PrmId_reseauxApprocree;
    end if;   -- fin de if nvl(prmA,0) <> 0 then
  exception
    when ex.ROW_LOCKED then
      raise_application_error(-20020, 'PCS - ' || eLockedNetwExceptionMsg);
    when others then
      raise;
  end;

  /***
  * procedure CreateAttribApproStock
  *
  * Idem procédure précédente avec retour d'un message d'erreur en cas de problème
  */
  procedure CreateAttribApproStock(PrmId_reseauxApprocree in TTypeID, PrmLocationID in TTypeID, PrmA in FAL_LOT.LOT_TOTAL_QTY%type, aErrorCode in out varchar2)
  is
  begin
    if nvl(PrmA, 0) > 0 then
      CreateAttribApproStock(PrmId_reseauxApprocree, PrmLocationID, PrmA);
    end if;
  exception
    when eLockedNetwException then
      aErrorCode  := 'eLockedNetwException';
    when excLinkQtyTooHigh then
      aErrorCode  := 'excLinkQtyTooHigh';
    when others then
      raise;
  end;

  /**
  * procedure : CreateAttribBesoinStock
  * Description : Procédure de création d'une attribution besoin sur Stock
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param     PrmNeedID                  : Besoin à attribuer
  * @param     PrmPositionID              : Position de stock à  attribuer
  * @param     PrmSTM_LOCATION_ID         : Emplacement à Attribuer
  * @param     PrmA                       : Qté demandée pour l'attribution
  * @param     aAttribOverProvisoryOutput : Attribution sur Qté sortie provisoires ou pas.
  */
  procedure CreateAttribBesoinStock(
    PrmNeedID                  TTypeID
  , PrmPositionID              TTypeID
  , PrmSTM_LOCATION_ID         TTypeID
  , PrmA                       FAL_LOT.LOT_TOTAL_QTY%type
  , aAttribOverProvisoryOutput integer default 0
  )
  is
    cursor CUR_NETWORK_LOCKING
    is
      select        FNN.FAN_BEG_PLAN
                  , FNN.FAN_FREE_QTY
                  , (nvl(SPO.SPO_AVAILABLE_QUANTITY, 0) + nvl(SPO.SPO_PROVISORY_INPUT, 0) ) AVAILABLE_QTY
                  , nvl(SPO.SPO_PROVISORY_OUTPUT, 0) SPO_PROVISORY_OUTPUT
               from FAL_NETWORK_NEED FNN
                  , STM_STOCK_POSITION SPO
              where FNN.FAL_NETWORK_NEED_ID = PrmNeedID
                and SPO.STM_STOCK_POSITION_ID = PrmPositionID
      for update of FNN.FAN_FREE_QTY, SPO.SPO_AVAILABLE_QUANTITY nowait;

    CurNetworkLocking CUR_NETWORK_LOCKING%rowtype;
  begin
    if nvl(prmA, 0) > 0 then
      -- D'abord récupérer et bloquer les valeurs du FAL_NETWORK_NEED et STM_STOCK_POSITION
      open CUR_NETWORK_LOCKING;

      fetch CUR_NETWORK_LOCKING
       into CurNetworkLocking;

      -- Vérification de la quantité libre
      if nvl(PrmA, 0) > nvl(CurNetworkLocking.FAN_FREE_QTY, 0) then
        raise_application_error(-20010
                              , 'PCS - ' ||
                                excLinkQtyTooHighMsg ||
                                co.cLineBreak ||
                                PCS.PC_FUNCTIONS.TranslateWord('Qté à attribuer') ||
                                ' : ' ||
                                PrmA ||
                                co.cLineBreak ||
                                PCS.PC_FUNCTIONS.TranslateWord('Qté libre') ||
                                ' : ' ||
                                CurNetworkLocking.FAN_FREE_QTY
                               );
      end if;

      -- Vérification de la quantité disponible en stock
      if    (    aAttribOverProvisoryOutput = 0
             and nvl(PrmA, 0) > nvl(CurNetworkLocking.AVAILABLE_QTY, 0) )
         or (    aAttribOverProvisoryOutput = 1
             and nvl(PrmA, 0) >(nvl(CurNetworkLocking.AVAILABLE_QTY, 0) + nvl(CurNetworkLocking.SPO_PROVISORY_OUTPUT, 0) ) ) then
        raise_application_error(-20030
                              , 'PCS - ' ||
                                excAvailQtyTooLowMsg ||
                                co.cLineBreak ||
                                PCS.PC_FUNCTIONS.TranslateWord('Qté à attribuer') ||
                                ' : ' ||
                                PrmA ||
                                co.cLineBreak ||
                                PCS.PC_FUNCTIONS.TranslateWord('Qté disponible') ||
                                ' : ' ||
                                CurNetworkLocking.AVAILABLE_QTY
                               );
      end if;

      FAL_NETWORK.gAttribTransfertMode  := true;

      -- Processus : Création Attribution Besoin sur Stock ...
      insert into FAL_NETWORK_LINK
                  (FAL_NETWORK_LINK_ID
                 , STM_STOCK_POSITION_ID
                 , FAL_NETWORK_NEED_ID
                 , FLN_SUPPLY_DELAY
                 , FLN_NEED_DELAY
                 , FLN_MARGIN
                 , FLN_QTY
                 , STM_LOCATION_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (GetNewId
                 , PrmPositionID
                 , PrmNeedID
                 , CurNetworkLocking.FAN_BEG_PLAN
                 , CurNetworkLocking.FAN_BEG_PLAN
                 , 0
                 , nvl(PrmA, 0)
                 , PrmSTM_LOCATION_ID
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      -- Processus : Report sur Réseau Besoin
      update FAL_NETWORK_NEED
         set FAN_FREE_QTY = nvl(FAN_FREE_QTY, 0) - nvl(PrmA, 0)
           , FAN_STK_QTY = nvl(FAN_STK_QTY, 0) + nvl(PrmA, 0)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_NETWORK_NEED_ID = PrmNeedID;

      -- Processus : Report sur Position de stock ...
      update STM_STOCK_POSITION
         set SPO_ASSIGN_QUANTITY = nvl(SPO_ASSIGN_QUANTITY, 0) + nvl(PrmA, 0)
           , SPO_AVAILABLE_QUANTITY = nvl(SPO_AVAILABLE_QUANTITY, 0) - nvl(PrmA, 0)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where STM_STOCK_POSITION_ID = PrmPositionID;

      FAL_NETWORK.gAttribTransfertMode  := false;

      close CUR_NETWORK_LOCKING;
    end if;
  exception
    when ex.ROW_LOCKED then
      FAL_NETWORK.gAttribTransfertMode  := false;
      raise_application_error(-20020, 'PCS - ' || eLockedNetwExceptionMsg);
    when no_data_found then
      FAL_NETWORK.gAttribTransfertMode  := false;
      null;
    when others then
      FAL_NETWORK.gAttribTransfertMode  := false;
      raise;
  end;

  /***
  * procedure CreateAttribBesoinStock
  *
  * Idem procédure précédente avec retour d'un message d'erreur en cas de problème
  */
  procedure CreateAttribBesoinStock(
    PrmNeedID                  in     TTypeID
  , PrmPositionID              in     TTypeID
  , PrmSTM_LOCATION_ID         in     TTypeID
  , PrmA                       in     FAL_LOT.LOT_TOTAL_QTY%type
  , aErrorCode                 in out varchar2
  , aAttribOverProvisoryOutput in     integer default 0
  )
  is
  begin
    if nvl(PrmA, 0) > 0 then
      CreateAttribBesoinStock(PrmNeedID, PrmPositionID, PrmSTM_LOCATION_ID, PrmA, aAttribOverProvisoryOutput);
    end if;
  exception
    when eLockedNetwException then
      aErrorCode  := 'eLockedNetwException';
    when excLinkQtyTooHigh then
      aErrorCode  := 'excLinkQtyTooHigh';
    when excAvailQtyTooLow then
      aErrorCode  := 'excAvailQtyTooLow';
    when no_data_found then
      null;
    when others then
      raise;
  end;

-- PROCEDURE Attribution_Complete()
-- Contrôle et création attribution pour le processus de gestion des attributions complètes
  procedure Attribution_Complete(aFAL_NETWORK_NEED_ID in TTypeID, aSTM_STOCK_POSITION_ID in varchar2, aX in FAL_NETWORK_SUPPLY.FAN_NETW_QTY%type)
  is
    subtype TQty is STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;

    cursor cur_FalNetworkNeed
    is
      select FNN.DOC_POSITION_DETAIL_ID
           , FNN.FAL_LOT_MATERIAL_LINK_ID
           , FNN.FAL_LOT_MAT_LINK_PROP_ID
           , (select nvl(PDT_STOCK_ALLOC_BATCH, 0)
                from GCO_PRODUCT
               where GCO_GOOD_ID = FNN.GCO_GOOD_ID) PDT_STOCK_ALLOC_BATCH
        from FAL_NETWORK_NEED FNN
       where FNN.FAL_NETWORK_NEED_ID = aFAL_NETWORK_NEED_ID;

    curFalNetworkNeed       cur_FalNetworkNeed%rowtype;
    -- Position de stock ID
    vSTM_STOCK_POSITION_ID  TTypeID;
    -- Quantité dispo de la position de stock
    vSPO_AVAILABLE_QUANTITY TQty;
    -- Emplacement de stock
    vSTM_LOCATION_ID        TTypeID;
    -- Variables de calcul
    X                       TQty;
    Y                       TQty;

    -- Permet de récupérer l'ID de la position de stock, sa quantité et son emplacement ID pouvant être attribuée
    procedure GetPosIDAndQtyAndLocID
    is
      Ignore                integer;
      QrySTM_STOCK_POSITION varchar2(32000);
      CurSTM_STOCK_POSITION integer;
    begin
      vSTM_STOCK_POSITION_ID   := null;
      vSPO_AVAILABLE_QUANTITY  := null;
      vSTM_LOCATION_ID         := null;
      -- Sélection selon les positions des mouvements de stock avec une qté libre > 0
      QrySTM_STOCK_POSITION    :=
        ' select STM_STOCK_POSITION_ID ' ||
        '      , SPO_AVAILABLE_QUANTITY + SPO_PROVISORY_OUTPUT as SPO_AVAILABLE_QUANTITY ' ||
        '      , STM_LOCATION_ID ' ||
        '   from STM_STOCK_POSITION ' ||
        '  where STM_STOCK_POSITION_ID in (' ||
        aSTM_STOCK_POSITION_ID ||
        ') ' ||
        '   and SPO_AVAILABLE_QUANTITY + SPO_PROVISORY_OUTPUT > 0 ' ||
        ' order by STM_STOCK_POSITION_ID ';
      CurSTM_STOCK_POSITION    := DBMS_SQL.Open_Cursor;
      DBMS_SQL.Parse(CurSTM_STOCK_POSITION, QrySTM_STOCK_POSITION, DBMS_SQL.V7);
      DBMS_SQL.Define_Column(CurSTM_STOCK_POSITION, 1, vSTM_STOCK_POSITION_ID);
      DBMS_SQL.Define_Column(CurSTM_STOCK_POSITION, 2, vSPO_AVAILABLE_QUANTITY);
      DBMS_SQL.Define_Column(CurSTM_STOCK_POSITION, 3, vSTM_LOCATION_ID);
      Ignore                   := DBMS_SQL.execute(CurSTM_STOCK_POSITION);

      if DBMS_SQL.Fetch_Rows(CurSTM_STOCK_POSITION) > 0 then
        -- Récupération des premières valeurs
        DBMS_SQL.column_value(CurSTM_STOCK_POSITION, 1, vSTM_STOCK_POSITION_ID);
        DBMS_SQL.column_value(CurSTM_STOCK_POSITION, 2, vSPO_AVAILABLE_QUANTITY);
        DBMS_SQL.column_value(CurSTM_STOCK_POSITION, 3, vSTM_LOCATION_ID);
      end if;

      DBMS_SQL.Close_Cursor(CurSTM_STOCK_POSITION);
    exception
      when no_data_found then
        DBMS_SQL.Close_Cursor(CurSTM_STOCK_POSITION);
    end;
  begin
    open cur_FalNetworkNeed;

    fetch cur_FalNetworkNeed
     into curFalNetworkNeed;

    -- Contrôle que l'on souhaite effectuer une attribution complète
    -- Contrôle que l'on a bien au moins une position de stock
    -- Contrôle que l'on travail bien sur une attribution de type logistique pour le produit terminé
    if     (aSTM_STOCK_POSITION_ID is not null)
       and (        (PCS.PC_CONFIG.GetConfig('FAL_LINK_COMPLETE') = 'True')
               and (curFalNetworkNeed.DOC_POSITION_DETAIL_ID is not null)
            or (     (curFalNetworkNeed.PDT_STOCK_ALLOC_BATCH = 1)
                and (   curFalNetworkNeed.FAL_LOT_MATERIAL_LINK_ID is not null
                     or curFalNetworkNeed.FAL_LOT_MAT_LINK_PROP_ID is not null)
               )
           ) then
      -- Initialiser X ...
      X  := aX;

      loop
        -- Récupération de l'ID de la position de stock, de sa quantité et de son emplacement ID
        -- pouvant être attribuée
        GetPosIDAndQtyAndLocID;

        -- Contrôle que l'on a bien trouvé une position de stock
        if (vSTM_STOCK_POSITION_ID is not null) then
          Y  := X - nvl(vSPO_AVAILABLE_QUANTITY, 0);

          -- Détermination de la qté à attribuer
          if Y <= 0 then
            -- Création Attributions Besoin sur stock (Position)...
            CreateAttribBesoinStock(aFAL_NETWORK_NEED_ID, vSTM_STOCK_POSITION_ID, vSTM_LOCATION_ID, X, 1);
            -- Tout a été attribué
            exit;
          else
            -- Création Attributions Besoin sur stock (Position)...
            CreateAttribBesoinStock(aFAL_NETWORK_NEED_ID, vSTM_STOCK_POSITION_ID, vSTM_LOCATION_ID, vSPO_AVAILABLE_QUANTITY, 1);
          end if;

          -- Qté restante à attribuer
          X  := Y;
        else
            -- Normalement on doit avoir assez de qté sur les positions de stock
          -- donc si ce n'est pas le cas alors il y a eu un problème et on doit stopper le processus
          Raise_Application_error(-20024, 'PCS - Abnormal quantity on position');
        end if;
      end loop;
    end if;

    close cur_FalNetworkNeed;
  end;

-- PROCEDURE ReseauApproFAL_CreationPOA ()
--
-- Création d'un enregistrement dans FAL_NETWORK_SUPPLY à partir d'un détail  de position --------------------------------
  procedure ReseauApproFAL_CreationPOA(aDetID in TTypeID, aDefaultStockID in TTypeID, aDefaultLocationID in TTypeID)
  is
    -- Description
    aFAN_DESCRIPTION FAL_NETWORK_SUPPLY.FAN_DESCRIPTION%type;

    -- Lecture d'un détail de position --------------------------------------------------------------------------------------
    -- FP20010719
    cursor GetDetRecord(aDetID in TTypeID)
    is
      select DOC_POSITION_DETAIL.PDE_BASIS_DELAY
           , DOC_POSITION_DETAIL.PDE_FINAL_DELAY
           , DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY
           , DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY
           , DOC_POSITION.GCO_GOOD_ID
           , DOC_POSITION.DOC_RECORD_ID
           , DOC_POSITION.STM_STOCK_ID
        from DOC_POSITION
           , DOC_POSITION_DETAIL
       where DOC_POSITION.DOC_POSITION_ID = DOC_POSITION_DETAIL.DOC_POSITION_ID
         and DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID = aDetId;

      -- FP20010719
    -- Record du lot concerné
    aDetConcerne     GetDetRecord%rowtype;
  begin
    -- Ouverture du curseur sur le lot et renseigner aLotConcerne
    open GetDetRecord(aDetID);

    fetch GetDetRecord
     into aDetConcerne;

    -- S'assurer qu'il y ai un enregistrement ...
    if GetDetRecord%found then
      -- Récupérer la description
      select DMT.DMT_NUMBER || ' / ' || POS.POS_NUMBER
        into aFAN_DESCRIPTION
        from DOC_DOCUMENT DMT
           , DOC_POSITION POS
           , DOC_POSITION_DETAIL PDE
       where DMT.DOC_DOCUMENT_ID = POS.DOC_POSITION_ID
         and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
         and PDE.DOC_POSITION_DETAIL_ID = aDetId;

      -- Insertion dans FAL_NETWORK_SUPPLY -----------------------------------------------------------------------
      insert into FAL_NETWORK_SUPPLY
                  (
                   -- ID principal
                   FAL_NETWORK_SUPPLY_ID
                 ,
                   -- Date de création
                   A_DATECRE
                 ,
                   -- User Création
                   A_IDCRE
                 ,
                   -- ID Détail de document
                   DOC_POSITION_DETAIL_ID
                 ,
                   -- Produit
                   GCO_GOOD_ID
                 ,
                   -- Description
                   FAN_DESCRIPTION
                 ,
                   -- Dossier
                   DOC_RECORD_ID
                 ,
                   -- Debut Planif
                   FAN_BEG_PLAN
                 ,
                   -- Fin Planif
                   FAN_END_PLAN
                 ,
                   -- Debut Planif 1
                   FAN_BEG_PLAN1
                 ,
                   -- Fin Planif 1
                   FAN_END_PLAN1
                 ,
                   -- Debut Reel
                   FAN_REAL_BEG
                 ,
                   -- Duree plannifiee
                   FAN_PLAN_PERIOD
                 ,
                   -- Stock
                   STM_STOCK_ID
                 ,
                   -- Emplacement de stock
                   STM_LOCATION_ID
                 ,
                   -- Intitule gabarit
                   C_GAUGE_TITLE
                 ,
                   -- Qte prevue
                   FAN_PREV_QTY
                 ,
                   -- Qte Rebut prévue
                   FAN_SCRAP_QTY
                 ,
                   -- Qte Totale
                   FAN_FULL_QTY
                 ,
                   -- Qte Realisee
                   FAN_REALIZE_QTY
                 ,
                   -- Qte Supplémentaire
                   FAN_EXCEED_QTY
                 ,
                   -- Qte Dechargée
                   FAN_DISCHARGE_QTY
                 ,
                   -- Qte Rebut Realise
                   FAN_SCRAP_REAL_QTY
                 ,
                   -- Qte Retour
                   FAN_RETURN_QTY
                 ,
                   -- qte Solde
                   FAN_BALANCE_QTY
                 ,
                   -- Qte Libre
                   FAN_FREE_QTY
                 ,
                   -- Qte Att Stock
                   FAN_STK_QTY
                 ,
                   -- Qte Att Besoin Appro
                   FAN_NETW_QTY
                  )
           values (GetNewId
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                 ,
                   -- ID Détail de position
                   aDetId
                 ,
                   -- Produit
                   aDetConcerne.GCO_GOOD_ID
                 ,
                   -- Description
                   aFAN_DESCRIPTION
                 ,
                   -- Dossier
                   aDetConcerne.DOC_RECORD_ID
                 ,
                   -- Debut Planif
                   aDetConcerne.PDE_BASIS_DELAY
                 ,
                   -- Fin Planif
                   aDetConcerne.PDE_FINAL_DELAY
                 ,
                   -- Debut Planif 1
                   aDetConcerne.PDE_BASIS_DELAY
                 ,
                   -- Fin Planif 1
                   aDetConcerne.PDE_FINAL_DELAY
                 ,
                   -- Debut Reel
                   aDetConcerne.PDE_BASIS_DELAY
                 ,
                   -- Duree plannifiee
                   0
                 ,
                   -- Stock
                   aDefaultStockID
                 ,
                   -- Emplacement de stock
                   aDefaultLocationID
                 ,
                   -- Intitule gabarit = dcLotFabrication
                   '13'
                 ,
                   -- Qte prevue
                   aDetConcerne.PDE_BASIS_QUANTITY
                 ,
                   -- Qte Rebut prévue
                   0
                 ,
                   -- Qte Totale
                   aDetConcerne.PDE_BASIS_QUANTITY
                 ,
                   -- Qte Realisee
                   0
                 ,
                   -- Qte Supplémentaire
                   0
                 ,
                   -- Qte Dechargée
                   0
                 ,
                   -- Qte Rebut Realise
                   0
                 ,
                   -- Qte Retour
                   0
                 ,
                   -- Qte Solde
                   aDetConcerne.PDE_BALANCE_QUANTITY
                 ,
                   -- Qte Libre
                   0
                 ,
                   -- Qte Att Stock
                   0
                 ,
                   -- Qte Att Besoin Appro
                   aDetConcerne.PDE_BASIS_QUANTITY
                  );
    -- FIN : S'assurer qu'il y ai un enregistrement ...
    end if;

    -- fermeture du curseur sur le lot concerné
    close GetDetRecord;
  end;

-- PROCEDURE ReseauBesoinFAL_CreationPOA ()
--
-- Création d'un enregistrement dans FAL_NETWORK_NEED à partir d'un détail de position
-- Vérifie l'abscence de record dans FAL_NETWORK_NEED sur le même FAL_LOT_MATERIAL_LINK_ID avant d'ajouter un nouveau record
  procedure ReseauBesoinFAL_CreationPOA(aDetID in TTypeID, aDefaultStockID in TTypeID, aDefaultLocationID in TTypeID)
  is
    -- StockID défini pour l'insertion
    aStockID         TTypeID;
    -- LocationID défini pour l'insertion
    aLocationID      TTypeID;
    -- DocRecordID du lot ...
    aDocRecordID     TTypeID;
    -- Nbre Record existant sur le même ComposantID
    aRecCount        integer;
    -- Référence complète du lot
    aLotDescription  FAL_LOT.LOT_REFCOMPL%type;
    -- Description
    aFAN_DESCRIPTION FAL_NETWORK_SUPPLY.FAN_DESCRIPTION%type;

    -- Lecture d'un détail de position --------------------------------------------------------------------------------------
    cursor GetDetRecord(aDetID in TTypeID)
    is
      select DOC_POSITION_DETAIL.PDE_BASIS_DELAY
           , DOC_POSITION_DETAIL.PDE_FINAL_DELAY
           , DOC_POSITION_DETAIL.PDE_BASIS_QUANTITY
           , DOC_POSITION_DETAIL.PDE_BALANCE_QUANTITY
           , DOC_POSITION_DETAIL.STM_LOCATION_ID
           , DOC_POSITION.GCO_GOOD_ID
           , DOC_POSITION.DOC_RECORD_ID
           , DOC_POSITION.STM_STOCK_ID
        from DOC_POSITION
           , DOC_POSITION_DETAIL
       where DOC_POSITION.DOC_POSITION_ID = DOC_POSITION_DETAIL.DOC_POSITION_ID
         and DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID = aDetId;

    -- Record des composants concernés
    aDetConcerne     GetDetRecord%rowtype;
  begin
    -- Ouverture du curseur sur le détail de position et renseigner aDetConcerne...
    open GetDetRecord(aDetID);

    fetch GetDetRecord
     into aDetConcerne;

    -- S'assurer qu'il y ai un enregistrement ...
    while GetDetRecord%found loop
      -- Récupérer la description
      select DMT.DMT_NUMBER || ' / ' || POS.POS_NUMBER
        into aFAN_DESCRIPTION
        from DOC_DOCUMENT DMT
           , DOC_POSITION POS
           , DOC_POSITION_DETAIL PDE
       where DMT.DOC_DOCUMENT_ID = POS.DOC_POSITION_ID
         and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
         and PDE.DOC_POSITION_DETAIL_ID = aDetId;

      -- Déterminer le STOCK et l'EMPLACEMENT à stocker dans les réseaux -----------------------------------------
      aStockID     := aDetConcerne.STM_STOCK_ID;
      aLocationID  := aDetConcerne.STM_LOCATION_ID;
      SetDefaultStockAndLocation(aStockID, aLocationID, aDefaultStockID, aDefaultLocationID);

      insert into FAL_NETWORK_NEED
                  (FAL_NETWORK_NEED_ID
                 , A_DATECRE
                 , A_IDCRE
                 , DOC_POSITION_DETAIL_ID
                 , FAL_LOT_MATERIAL_LINK_ID
                 , GCO_GOOD_ID
                 , FAN_DESCRIPTION
                 , DOC_RECORD_ID
                 , FAN_BEG_PLAN
                 , FAN_END_PLAN
                 , STM_STOCK_ID
                 , STM_LOCATION_ID
                 , C_GAUGE_TITLE
                 , FAN_BALANCE_QTY
                 , FAN_FREE_QTY
                 , FAN_STK_QTY
                 , FAN_NETW_QTY
                  )
           values (GetNewId
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                 , aDetId
                 , null
                 , aDetConcerne.GCO_GOOD_ID
                 , aFAN_DESCRIPTION
                 , aDetConcerne.DOC_RECORD_ID
                 , aDetConcerne.PDE_FINAL_DELAY
                 , aDetConcerne.PDE_FINAL_DELAY
                 , aStockID
                 , aLocationID
                 , '13'
                 , aDetConcerne.PDE_BASIS_QUANTITY
                 , 0
                 , 0
                 , aDetConcerne.PDE_BASIS_QUANTITY
                  );

      -- FIN : if aRecCount = 0 then ...
           --END IF;
      fetch GetDetRecord
       into aDetConcerne;
    -- FIN : Boucler sur les composants ...
    end loop;

    -- fermeture du curseur sur les composants concernés
    close GetDetRecord;
  end;

  procedure CreateAttribBesoinApproPOA(PrmFAL_NETWORK_NEED_ID TTypeID, PrmId_reseauxApprocree TTypeID, PrmA FAL_LOT.LOT_TOTAL_QTY%type)
  is
    type TFAL_NETWORK_SUPPLY is record(
      FAN_END_PLAN FAL_NETWORK_SUPPLY.FAN_END_PLAN%type
    , FAN_FREE_QTY FAL_NETWORK_SUPPLY.FAN_FREE_QTY%type
    );

    type TFAL_NETWORK_NEED is record(
      FAN_BEG_PLAN FAL_NETWORK_NEED.FAN_BEG_PLAN%type
    , FAN_FREE_QTY FAL_NETWORK_NEED.FAN_FREE_QTY%type
    );

    EnrFAL_NETWORK_SUPPLY TFAL_NETWORK_SUPPLY;
    EnrFAL_NETWORK_NEED   TFAL_NETWORK_NEED;
  begin
    -- D'abord récupérer les valeurs du FAL_NETWORK_SUPPLY et du FAL_NETWORK_NEED
    select FAN_END_PLAN
         , FAN_FREE_QTY
      into EnrFAL_NETWORK_SUPPLY
      from FAL_NETWORK_SUPPLY
     where FAL_NETWORK_SUPPLY_ID = PrmId_reseauxApprocree;

    select FAN_BEG_PLAN
         , FAN_FREE_QTY
      into EnrFAL_NETWORK_NEED
      from FAL_NETWORK_NEED
     where FAL_NETWORK_NEED_ID = PrmFAL_NETWORK_NEED_ID;

    -- Processus : Création Attribution Besoin sur Appro ...
    insert into FAL_NETWORK_LINK
                (FAL_NETWORK_LINK_ID
               , FAL_NETWORK_SUPPLY_ID
               , FAL_NETWORK_NEED_ID
               , FLN_SUPPLY_DELAY
               , FLN_NEED_DELAY
               , FLN_MARGIN
               , FLN_QTY
               , A_DATECRE
               , A_IDCRE
                )
         values (GetNewId
               , PrmId_reseauxApprocree
               , PrmFAL_NETWORK_NEED_ID
               , EnrFAL_NETWORK_SUPPLY.FAN_END_PLAN
               , EnrFAL_NETWORK_NEED.FAN_BEG_PLAN
               , EnrFAL_NETWORK_NEED.FAN_BEG_PLAN - EnrFAL_NETWORK_SUPPLY.FAN_END_PLAN
               , nvl(PrmA, 0)
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );

    -- Processus : Report sur Réseau Besoin ...
    update FAL_NETWORK_NEED
       set FAN_FREE_QTY = nvl(FAN_FREE_QTY, 0) - nvl(PrmA, 0)
         , FAN_NETW_QTY = nvl(FAN_NETW_QTY, 0) + nvl(PrmA, 0)
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_NETWORK_NEED_ID = PrmFAL_NETWORK_NEED_ID;

    -- Processus : Report sur Réseau Appro ...
    update FAL_NETWORK_SUPPLY
       set FAN_FREE_QTY = nvl(FAN_FREE_QTY, 0) - nvl(PrmA, 0)
         , FAN_NETW_QTY = nvl(FAN_NETW_QTY, 0) + nvl(PrmA, 0)
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_NETWORK_SUPPLY_ID = PrmId_reseauxApprocree;
  end;

-- Création Attributions Appro POA sur stock (location)...
  procedure CreateAttribApproStockPOA(PrmId_reseauxApprocree TTypeID, PrmLocationID TTypeID, PrmA FAL_LOT.LOT_TOTAL_QTY%type)
  is
    type TFAL_NETWORK_SUPPLY is record(
      FAN_END_PLAN FAL_NETWORK_SUPPLY.FAN_END_PLAN%type
    , FAN_FREE_QTY FAL_NETWORK_SUPPLY.FAN_FREE_QTY%type
    );

    EnrFAL_NETWORK_SUPPLY TFAL_NETWORK_SUPPLY;
  begin
    -- D'abord récupérer les valeurs du FAL_NETWORK_SUPPLY et du FAL_NETWORK_NEED
    select FAN_END_PLAN
         , FAN_FREE_QTY
      into EnrFAL_NETWORK_SUPPLY
      from FAL_NETWORK_SUPPLY
     where FAL_NETWORK_SUPPLY_ID = PrmId_reseauxApprocree;

    -- Processus : Création Attribution Appro sur Stock ...
    insert into FAL_NETWORK_LINK
                (FAL_NETWORK_LINK_ID
               , STM_LOCATION_ID
               , FAL_NETWORK_SUPPLY_ID
               , FLN_SUPPLY_DELAY
               , FLN_NEED_DELAY
               , FLN_MARGIN
               , FLN_QTY
               , A_DATECRE
               ,   -- Date de Création
                 A_IDCRE   -- Utilisateur
                )
         values (GetNewId
               , PrmLocationID
               , PrmId_reseauxApprocree
               , EnrFAL_NETWORK_SUPPLY.FAN_END_PLAN
               , EnrFAL_NETWORK_SUPPLY.FAN_END_PLAN
               , 0
               , nvl(PrmA, 0)
               , sysdate
               ,   -- Date de cré
                 PCS.PC_I_LIB_SESSION.GetUserIni   -- Id Création
                );

    -- Processus : Report sur Réseau Appro ...
    update FAL_NETWORK_SUPPLY
       set FAN_FREE_QTY = nvl(FAN_FREE_QTY, 0) - nvl(PrmA, 0)
         , FAN_STK_QTY = nvl(FAN_STK_QTY, 0) + nvl(PrmA, 0)
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_NETWORK_SUPPLY_ID = PrmId_reseauxApprocree;
  end;

-- Cette procédure éfface les Needs ou les supplys qui n'auraient pas été détruits
-- Paramètre entrant: InGCO_GOOG_ID
-- si NULL pas de de filtre sur le produit
-- si non  NULL alors on ne traite que les Needs ou Supplys du produit donné
  procedure DeleteObsoleteNeedAndSupply(inGCO_GOOD_ID GCo_GOOD.GCO_GOOD_ID%type)
  is
    procedure DeleteNeedAndSupplyWG
    is
      -- Need de Positions Liquidées ou Annulées
      cursor CNeedOfDocPosition
      is
        select        FAL_NETWORK_NEED_ID
                 from FAL_NETWORK_NEED N
                    , DOC_POSITION P
                where N.GCO_GOOD_ID = inGCO_GOOD_ID
                  and (N.C_NETWORK_ORIGINE = 1)
                  and (N.DOC_POSITION_ID >= 0)   -- Optimisation DJ20031112
                  and P.DOC_POSITION_ID = N.DOC_POSITION_ID
                  and (P.C_DOC_POS_STATUS in(4, 5) )
        for update of N.FAL_NETWORK_NEED_ID;

      -- Need de Lot Soldé (Réception) ou Historiés
      cursor CNeedOfLot
      is
        select        FAL_NETWORK_NEED_ID
                 from fal_network_need N
                    , FAL_LOT L
                where N.GCO_GOOD_ID = inGCO_GOOD_ID
                  and (N.C_NETWORK_ORIGINE = 1)
                  and N.FAL_LOT_ID >= 0   -- Optimisation DJ20031112
                  and L.FAL_LOT_ID = N.FAL_LOT_ID
                  and (L.C_LOT_STATUS in(5, 6) )
        for update of N.FAL_NETWORK_NEED_ID;

      -- Supply de Positions Liquidées ou Annulées
      cursor CSupplyOfDocPosition
      is
        select        FAL_NETWORK_SUPPLY_ID
                 from FAL_NETWORK_SUPPLY S
                    , DOC_POSITION P
                where S.GCO_GOOD_ID = inGCO_GOOD_ID
                  and (S.C_NETWORK_ORIGINE = 1)
                  and S.DOC_POSITION_ID >= 0   -- Optimisation DJ20031112
                  and P.DOC_POSITION_ID = S.DOC_POSITION_ID
                  and (P.C_DOC_POS_STATUS in(4, 5) )
        for update of S.FAL_NETWORK_SUPPLY_ID;

      -- Supply de Lot Soldé (Réception) ou Historiés
      cursor CSupplyOfLot
      is
        select        FAL_NETWORK_SUPPLY_ID
                 from fal_network_SUPPLY S
                    , FAL_LOT L
                where S.GCO_GOOD_ID = inGCO_GOOD_ID
                  and (S.C_NETWORK_ORIGINE = 1)
                  and S.FAL_LOT_ID >= 0   -- Optimisation DJ20031112
                  and L.FAL_LOT_ID = S.FAL_LOT_ID
                  and (L.C_LOT_STATUS in(5, 6) )
        for update of S.FAL_NETWORK_SUPPLY_ID;

      aFAL_NETWORK_NEED_ID   FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type;
      aFAL_NETWORK_SUPPLY_ID FAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID%type;
    begin
      -- Need de Positions Liquidées ou Annulées
      open CNeedOfDocPosition;

      loop
        fetch CNeedOfDocPosition
         into aFAL_NETWORK_NEED_ID;

        exit when CNeedOfDocPosition%notfound;
        -- On supprime d'abord les éventuelles attribs
        Attribution_Suppr_BesoinAppro(aFAL_NETWORK_NEED_ID);
        Attribution_Suppr_BesoinStock(aFAL_NETWORK_NEED_ID);

        -- Suppression du Need...
        delete from FAL_NETWORK_NEED
              where FAL_NETWORK_NEED_ID = aFAL_NETWORK_NEED_ID;
      end loop;

      close CNeedOfDocPosition;

      -- Need de Lot Soldé (Réception) ou Historiés
      open CNeedOfLot;

      loop
        fetch CNeedOfLot
         into aFAL_NETWORK_NEED_ID;

        exit when CNeedOfLot%notfound;
        -- On supprime d'abord les éventuelles attribs
        Attribution_Suppr_BesoinAppro(aFAL_NETWORK_NEED_ID);
        Attribution_Suppr_BesoinStock(aFAL_NETWORK_NEED_ID);

        -- Suppression du Need...
        delete from FAL_NETWORK_NEED
              where FAL_NETWORK_NEED_ID = aFAL_NETWORK_NEED_ID;
      end loop;

      close CNeedOfLot;

      -- Supply de Positions Liquidées ou Annulées
      open CSupplyOfDocPosition;

      loop
        fetch CSupplyOfDocPosition
         into aFAL_NETWORK_SUPPLY_ID;

        exit when CSupplyOfDocPosition%notfound;
        -- On supprime d'abord les éventuelles attribs
        Attribution_Suppr_ApproBesoin(aFAL_NETWORK_SUPPLY_ID);
        Attribution_Suppr_ApproStock(aFAL_NETWORK_SUPPLY_ID);

        -- Suppression du Supply...
        delete from FAL_NETWORK_SUPPLY
              where FAL_NETWORK_SUPPLY_ID = aFAL_NETWORK_SUPPLY_ID;
      end loop;

      close CSupplyOfDocPosition;

      -- Supply de Lot Soldé (Réception) ou Historiés
      open CSupplyOfLot;

      loop
        fetch CSupplyOfLot
         into aFAL_NETWORK_Supply_ID;

        exit when CSupplyOfLot%notfound;
        -- On supprime d'abord les éventuelles attribs
        Attribution_Suppr_ApproBesoin(aFAL_NETWORK_SUPPLY_ID);
        Attribution_Suppr_ApproStock(aFAL_NETWORK_SUPPLY_ID);

        -- Suppression du Supply...
        delete from FAL_NETWORK_SUPPLY
              where FAL_NETWORK_SUPPLY_ID = aFAL_NETWORK_SUPPLY_ID;
      end loop;

      close CSupplyOfLot;
    end;

    procedure DeleteNeedAndSupplyNG
    is
      -- Need de Positions Liquidées ou Annulées
      cursor CNeedOfDocPosition
      is
        select        FAL_NETWORK_NEED_ID
                 from FAL_NETWORK_NEED N
                    , DOC_POSITION P
                where N.DOC_POSITION_ID >= 0   -- Optimisation DJ20031112
                  and P.DOC_POSITION_ID = N.DOC_POSITION_ID
                  and (P.C_DOC_POS_STATUS in(4, 5) )
        for update of N.FAL_NETWORK_NEED_ID;

      -- Need de Lot Soldé (Réception) ou Historiés
      cursor CNeedOfLot
      is
        select        FAL_NETWORK_NEED_ID
                 from fal_network_need N
                    , FAL_LOT L
                where N.FAL_LOT_ID >= 0   -- Optimisation DJ20031112
                  and L.FAL_LOT_ID = N.FAL_LOT_ID
                  and (L.C_LOT_STATUS in(5, 6) )
        for update of N.FAL_NETWORK_NEED_ID;

      -- Supply de Positions Liquidées ou Annulées
      cursor CSupplyOfDocPosition
      is
        select        FAL_NETWORK_SUPPLY_ID
                 from FAL_NETWORK_SUPPLY S
                    , DOC_POSITION P
                where S.DOC_POSITION_ID >= 0   -- Optimisation DJ20031112
                  and P.DOC_POSITION_ID = S.DOC_POSITION_ID
                  and (P.C_DOC_POS_STATUS in(4, 5) )
        for update of S.FAL_NETWORK_SUPPLY_ID;

      -- Supply de Lot Soldé (Réception) ou Historiés
      cursor CSupplyOfLot
      is
        select        FAL_NETWORK_SUPPLY_ID
                 from fal_network_SUPPLY S
                    , FAL_LOT L
                where S.FAL_LOT_ID >= 0   -- Optimisation DJ20031112
                  and L.FAL_LOT_ID = S.FAL_LOT_ID
                  and (L.C_LOT_STATUS in(5, 6) )
        for update of S.FAL_NETWORK_SUPPLY_ID;

      aFAL_NETWORK_NEED_ID   FAL_NETWORK_NEED.FAL_NETWORK_NEED_ID%type;
      aFAL_NETWORK_SUPPLY_ID FAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID%type;
    begin
      -- Need de Positions Liquidées ou Annulées
      open CNeedOfDocPosition;

      loop
        fetch CNeedOfDocPosition
         into aFAL_NETWORK_NEED_ID;

        exit when CNeedOfDocPosition%notfound;
        -- On supprime d'abord les éventuelles attribs
        Attribution_Suppr_BesoinAppro(aFAL_NETWORK_NEED_ID);
        Attribution_Suppr_BesoinStock(aFAL_NETWORK_NEED_ID);

        -- Suppression du Need...
        delete from FAL_NETWORK_NEED
              where FAL_NETWORK_NEED_ID = aFAL_NETWORK_NEED_ID;
      end loop;

      close CNeedOfDocPosition;

      -- Need de Lot Soldé (Réception) ou Historiés
      open CNeedOfLot;

      loop
        fetch CNeedOfLot
         into aFAL_NETWORK_NEED_ID;

        exit when CNeedOfLot%notfound;
        -- On supprime d'abord les éventuelles attribs
        Attribution_Suppr_BesoinAppro(aFAL_NETWORK_NEED_ID);
        Attribution_Suppr_BesoinStock(aFAL_NETWORK_NEED_ID);

        -- Suppression du Need...
        delete from FAL_NETWORK_NEED
              where FAL_NETWORK_NEED_ID = aFAL_NETWORK_NEED_ID;
      end loop;

      close CNeedOfLot;

      -- Supply de Positions Liquidées ou Annulées
      open CSupplyOfDocPosition;

      loop
        fetch CSupplyOfDocPosition
         into aFAL_NETWORK_SUPPLY_ID;

        exit when CSupplyOfDocPosition%notfound;
        -- On supprime d'abord les éventuelles attribs
        Attribution_Suppr_ApproBesoin(aFAL_NETWORK_SUPPLY_ID);
        Attribution_Suppr_ApproStock(aFAL_NETWORK_SUPPLY_ID);

        -- Suppression du Supply...
        delete from FAL_NETWORK_SUPPLY
              where FAL_NETWORK_SUPPLY_ID = aFAL_NETWORK_SUPPLY_ID;
      end loop;

      close CSupplyOfDocPosition;

      -- Supply de Lot Soldé (Réception) ou Historiés
      open CSupplyOfLot;

      loop
        fetch CSupplyOfLot
         into aFAL_NETWORK_Supply_ID;

        exit when CSupplyOfLot%notfound;
        -- On supprime d'abord les éventuelles attribs
        Attribution_Suppr_ApproBesoin(aFAL_NETWORK_SUPPLY_ID);
        Attribution_Suppr_ApproStock(aFAL_NETWORK_SUPPLY_ID);

        -- Suppression du Supply...
        delete from FAL_NETWORK_SUPPLY
              where FAL_NETWORK_SUPPLY_ID = aFAL_NETWORK_SUPPLY_ID;
      end loop;

      close CSupplyOfLot;
    end;
  begin
    if nvl(inGCO_GOOD_ID, 0) <> 0 then
      DeleteNeedAndSupplyWG;
    else
      DeleteNeedAndSupplyNG;
    end if;
  end;

  -- Procéduré créer à la demande de JPA pour R. burglin chez Chatelain
  -- (Hors analyse)
  procedure SupprAllAttribApproStock
  is
    cursor CLink
    is
      select     fal_network_supply_id
               , fln_qty
            from fal_network_link
           where fal_network_supply_id is not null
             and stm_location_id is not null
      for update;

    aLinkRec Clink%rowtype;
  begin
    open Clink;

    loop
      fetch Clink
       into aLinkRec;

      exit when Clink%notfound;

      -- modification de l'appro
      update FAL_NETWORK_SUPPLY
         set FAN_STK_QTY = nvl(FAN_STK_QTY, 0) - nvl(aLinkRec.FLN_QTY, 0)
           , FAN_FREE_QTY = nvl(FAN_FREE_QTY, 0) + nvl(aLinkRec.FLN_QTY, 0)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_NETWORK_SUPPLY_ID = aLinkRec.FAL_NETWORK_SUPPLY_ID;

      -- Suppression de l'attribution
      delete      fal_network_link
            where current of Clink;
    end loop;

    close Clink;
  end;

  -- Fonction de recherche du nombre d'attributions sur stock potentiellement
  -- liées à la quantité stock mini du produit.
  function ExistSupplyLinksForStock(
    aGoodId     in GCO_GOOD.GCO_GOOD_ID%type
  , aStockId    in STM_STOCK.STM_STOCK_ID%type
  , aLocationId in STM_LOCATION.STM_LOCATION_ID%type default null
  )
    return integer
  is
    vResult integer;
  begin
    select count(FAL_NETWORK_LINK_ID)
      into vResult
      from FAL_NETWORK_LINK FNL
         , FAL_NETWORK_SUPPLY FNS
     where FNS.FAL_NETWORK_SUPPLY_ID = FNL.FAL_NETWORK_SUPPLY_ID
       and FNS.GCO_GOOD_ID = aGoodId
       and FNS.STM_STOCK_ID = aStockId
       and FNL.FAL_NETWORK_NEED_ID is null
       and FNL.STM_LOCATION_ID is not null
       and (   nvl(aLocationId, 0) = 0
            or FNL.STM_LOCATION_ID = aLocationId);

    return vResult;
  end ExistSupplyLinksForStock;

  -- Procédure de suppression des attributions sur stock potentiellement liées
  -- à la quantité stock mini du produit.
  procedure DeleteSupplyLinksForStock(
    aGoodId      in     GCO_GOOD.GCO_GOOD_ID%type
  , aStockId     in     STM_STOCK.STM_STOCK_ID%type
  , aLocationId  in     STM_LOCATION.STM_LOCATION_ID%type default null
  , aLinksCount  out    integer
  , aErrorsCount out    integer
  )
  is
    cursor crDelSupplyLinksForStock
    is
      select FAL_NETWORK_LINK_ID
        from FAL_NETWORK_LINK FNL
           , FAL_NETWORK_SUPPLY FNS
       where FNS.FAL_NETWORK_SUPPLY_ID = FNL.FAL_NETWORK_SUPPLY_ID
         and FNS.GCO_GOOD_ID = aGoodId
         and FNS.STM_STOCK_ID = aStockId
         and FNL.FAL_NETWORK_NEED_ID is null
         and FNL.STM_LOCATION_ID is not null
         and (   nvl(aLocationId, 0) = 0
              or FNL.STM_LOCATION_ID = aLocationId);
  begin
    aLinksCount   := 0;
    aErrorsCount  := 0;

    for tplDelSupplyLinksForStock in crDelSupplyLinksForStock loop
      aLinksCount  := aLinksCount + 1;
      savepoint spBeforeDeleteLink;

      begin
        -- Suppression de l'attribution
        LockAndDeleteLink(tplDelSupplyLinksForStock.FAL_NETWORK_LINK_ID);
      exception
        when others then
          rollback to spBeforeDeleteLink;
          aErrorsCount  := aErrorsCount + 1;
      end;
    end loop;
  end DeleteSupplyLinksForStock;

  -- Suppresion enregistrement d'un composant de proposition
  -- Note: Ce processus a été créer lorsque nous avons mis en place "Controle bloc équivalence sur stock"
  procedure ReseauBesoinPropCmpSuppr(aFAL_LOT_MAT_LINK_PROP_ID FAL_LOT_MAT_LINK_PROP.FAL_LOT_MAT_LINK_PROP_ID%type)
  is
    cursor CurNeed
    is
      select     FAL_NETWORK_NEED_ID
            from FAL_NETWORK_NEED
           where FAL_LOT_MAT_LINK_PROP_ID = aFAL_LOT_MAT_LINK_PROP_ID
      for update;
  begin
    for aRecord in CurNeed loop
      -- Suppression Attribution Besoin Stock ...
      Attribution_Suppr_BesoinStock(aRecord.FAL_NETWORK_NEED_ID);
      -- Suppression Attribution Besoin Appro ...
      Attribution_Suppr_BesoinAppro(aRecord.FAL_NETWORK_NEED_ID);

      -- Le composant n'existe pas. suppression du record ...
      delete from FAL_NETWORK_NEED
            where current of CurNeed;
    end loop;
  end;

  /****
  * PROCEDURE ReseauApproPropositionFAL_MAJ
  *
  * Description : Mise à jour Réseau appro pour une proposition de fabrication (Utilisé après replanification).
  *
  */
  procedure ReseauApproPropositionFAL_MAJ(aFAL_LOT_PROP_ID in TTypeID, AContext in integer)
  is
    -- Lecture d'un record de FAL_NETWORK_SUPPLY selon le FalLotPropID (Composant = null) et pas de caractérisations FOR UPDATE
    cursor GetPropSupplyRecordForUpdate(aFalLotPropID in TTypeID)
    is
      select     FAL_NETWORK_SUPPLY_ID
               , FAN_BEG_PLAN2
               , FAN_BEG_PLAN3
               , FAN_BEG_PLAN4
               , FAN_BEG_PLAN1
               , FAN_END_PLAN1
               , FAN_END_PLAN2
               , FAN_END_PLAN3
               , FAN_END_PLAN4
               , FAN_SCRAP_REAL_QTY
               , FAN_BALANCE_QTY
               , FAN_FREE_QTY
               , FAN_STK_QTY
               , FAN_NETW_QTY
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
            from FAL_NETWORK_SUPPLY
           where FAL_LOT_PROP_ID = aFalLotPropID
             and FAL_LOT_MAT_LINK_PROP_ID is null
      for update;

    -- Lecture d'un enregistrement de FAL_LOT_PROP selon le LotPropID
    cursor GetFalLotPropRecord(aFalLotPropID in TTypeID)
    is
      select *
        from FAL_LOT_PROP
       where FAL_LOT_PROP_ID = aFalLotPropID;

    -- Record du lot concerné
    aFalLotPropConcerne GetFalLotPropRecord%rowtype;
    -- Record du Appro concerné
    aApproConcerne      GetPropSupplyRecordForUpdate%rowtype;
    -- Date debut Planif
    aDebutPlanif        TTypeDate;
    -- Date fin Planif
    aFinPlanif          TTypeDate;
    -- Date debut Planif 2, 3, 4
    aDebutPlanif2       TTypeDate;
    aDebutPlanif3       TTypeDate;
    aDebutPlanif4       TTypeDate;
    -- Date fin Planif 2, 3, 4
    aFinPlanif2         TTypeDate;
    aFinPlanif3         TTypeDate;
    aFinPlanif4         TTypeDate;
    -- Caractérisations
    aCaractID1          number;
    aCaractID2          number;
    aCaractID3          number;
    aCaractID4          number;
    aCaractID5          number;
    aCaractValue1       varchar2(30);
    aCaractValue2       varchar2(30);
    aCaractValue3       varchar2(30);
    aCaractValue4       varchar2(30);
    aCaractValue5       varchar2(30);
  begin
    -- Sélection de la proposition
    open GetFalLotPropRecord(aFAL_LOT_PROP_ID);

    fetch GetFalLotPropRecord
     into aFalLotPropConcerne;

    -- S'assurer qu'il y ai un enregistrement de proposition
    if GetFalLotPropRecord%found then
      -- Ouverture du curseur sur l'appro et renseigner aLotConcerne
      open GetPropSupplyRecordForUpdate(aFAL_LOT_PROP_ID);

      fetch GetPropSupplyRecordForUpdate
       into aApproConcerne;

      -- S'assurer qu'il y ai un enregistrement Appro ...
      if GetPropSupplyRecordForUpdate%found then
        loop
          exit when GetPropSupplyRecordForUpdate%notfound;
          -- Initialiser les valeurs
          aDebutPlanif   := aFalLotPropConcerne.LOT_PLAN_BEGIN_DTE;
          aFinPlanif     := aFalLotPropConcerne.LOT_PLAN_END_DTE;
          aDebutPlanif2  := aApproConcerne.FAN_BEG_PLAN2;
          aDebutPlanif3  := aApproConcerne.FAN_BEG_PLAN3;
          aDebutPlanif4  := aApproConcerne.FAN_BEG_PLAN4;
          aFinPlanif2    := aApproConcerne.FAN_END_PLAN2;
          aFinPlanif3    := aApproConcerne.FAN_END_PLAN3;
          aFinPlanif4    := aApproConcerne.FAN_END_PLAN4;
          aCaractID1     := aApproConcerne.GCO_CHARACTERIZATION1_ID;
          aCaractID2     := aApproConcerne.GCO_CHARACTERIZATION2_ID;
          aCaractID3     := aApproConcerne.GCO_CHARACTERIZATION3_ID;
          aCaractID4     := aApproConcerne.GCO_CHARACTERIZATION4_ID;
          aCaractID5     := aApproConcerne.GCO_CHARACTERIZATION5_ID;
          aCaractValue1  := aApproConcerne.FAN_CHAR_VALUE1;
          aCaractValue2  := aApproConcerne.FAN_CHAR_VALUE2;
          aCaractValue3  := aApproConcerne.FAN_CHAR_VALUE3;
          aCaractValue4  := aApproConcerne.FAN_CHAR_VALUE4;
          aCaractValue5  := aApproConcerne.FAN_CHAR_VALUE5;

          -- Mise a jour àprès replanification
          if acontext = ncPlanificationLotProp then
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
                Attribution_MAJ_DateAppro(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aFinPlanif);
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
                  Attribution_MAJ_DateAppro(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aFinPlanif);
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
                Attribution_MAJ_DateAppro(aApproConcerne.FAL_NETWORK_SUPPLY_ID, aFinPlanif);
              end if;
            end if;
          -- Mise à jour après Modification des caractérisations (Assistant Maintenance des caract.)
          elsif acontext = ncMiseAJourLotProp then
            GetNetworkCharactFromProp(aFalLotPropConcerne
                                    , aCaractID1
                                    , aCaractID2
                                    , aCaractID3
                                    , aCaractID4
                                    , aCaractID5
                                    , aCaractValue1
                                    , aCaractValue2
                                    , aCaractValue3
                                    , aCaractValue4
                                    , aCaractValue5
                                     );
          end if;

          update FAL_NETWORK_SUPPLY
             set A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
               , A_DATEMOD = sysdate
               , FAN_BEG_PLAN = aFalLotPropConcerne.LOT_PLAN_BEGIN_DTE
               , FAN_END_PLAN = aFalLotPropConcerne.LOT_PLAN_END_DTE
               , FAN_BEG_PLAN2 = aDebutPlanif2
               , FAN_BEG_PLAN3 = aDebutPlanif3
               , FAN_BEG_PLAN4 = aDebutPlanif4
               , FAN_END_PLAN2 = aFinPlanif2
               , FAN_END_PLAN3 = aFinPlanif3
               , FAN_END_PLAN4 = aFinPlanif4
               , FAN_PLAN_PERIOD = aFalLotPropConcerne.LOT_PLAN_LEAD_TIME
               , GCO_CHARACTERIZATION1_ID = aCaractID1
               , GCO_CHARACTERIZATION2_ID = aCaractID2
               , GCO_CHARACTERIZATION3_ID = aCaractID3
               , GCO_CHARACTERIZATION4_ID = aCaractID4
               , GCO_CHARACTERIZATION5_ID = aCaractID5
               , FAN_CHAR_VALUE1 = aCaractValue1
               , FAN_CHAR_VALUE2 = aCaractValue2
               , FAN_CHAR_VALUE3 = aCaractValue3
               , FAN_CHAR_VALUE4 = aCaractValue4
               , FAN_CHAR_VALUE5 = aCaractValue5
           where current of GetPropSupplyRecordForUpdate;

          fetch GetPropSupplyRecordForUpdate
           into aApproConcerne;
        end loop;
      end if;

      -- Fermeture du curseur sur l'appro
      close GetPropSupplyRecordForUpdate;
    end if;

    -- fermeture du curseur sur le lot concerné
    close GetFalLotPropRecord;
  end ReseauApproPropositionFAL_MAJ;

  /****
  * PROCEDURE ReseauBesoinPropFAL_MAJ ()
  *
  * Description : Mise a jour d'un enregistrement dans FAL_NETWORK_NEED
  *               à partir des composants d'une proposition de fabrication.s
  */
  procedure ReseauBesoinPropositionFAL_MAJ(aFAL_LOT_PROP_ID in TTypeID)
  is
    -- Lecture de N enregistrements de FAL_LOT_MAT_LINK_PROP selon le FAL_LOT_PROP_ID
    cursor GetAllPropComposantRecords(aFAL_LOT_PROP_ID in TTypeID)
    is
      select FAL_LOT_MAT_LINK_PROP_ID
           , LOM_NEED_QTY
           , STM_STOCK_ID
           , STM_LOCATION_ID
           , LOM_NEED_DATE
        from FAL_LOT_MAT_LINK_PROP
       where FAL_LOT_PROP_ID = aFAL_LOT_PROP_ID;

    -- Lecture de 1 enregistrement de FAL_NETWORK_NEED selon un composant de proposition donné (FOR UPDATE)
    cursor GetNeedPropRecordForUpdate(aComposantID in TTypeID)
    is
      select     FAL_NETWORK_NEED_ID
               , FAN_FREE_QTY
               , FAN_NETW_QTY
               , FAN_STK_QTY
               , FAN_BEG_PLAN
            from FAL_NETWORK_NEED
           where FAL_LOT_MAT_LINK_PROP_ID = aComposantID
      for update;

    -- Record des composants concernés
    aComposantConcerne GetAllPropComposantRecords%rowtype;
    -- Record du need associé au composant
    aNeedRecord        GetNeedPropRecordForUpdate%rowtype;
    -- Debut et Fin planif du need
    aBeginEndPlanDate  TTypeDate;
  begin
    -- Ouverture du curseur sur le lot et renseigner aLotConcerne
    open GetAllPropComposantRecords(aFAL_LOT_PROP_ID);

    loop
      fetch GetAllPropComposantRecords
       into aComposantConcerne;

      -- S'assurer qu'il y ai un enregistrement ...
      exit when GetAllPropComposantRecords%notfound;

      -- Récupérer le record de FAL_NETWORK_NEED correspondant ---------------------------------------------------
      open GetNeedPropRecordForUpdate(aComposantConcerne.FAL_LOT_MAT_LINK_PROP_ID);

      fetch GetNeedPropRecordForUpdate
       into aNeedRecord;

      -- Si trouvé ...
      if GetNeedPropRecordForUpdate%found then
        -- Déterminer la date de début et de fin planif
        aBeginEndPlanDate  := aNeedRecord.FAN_BEG_PLAN;

        if (aBeginEndPlanDate <> aComposantConcerne.LOM_NEED_DATE) then
          aBeginEndPlanDate  := aComposantConcerne.LOM_NEED_DATE;
          -- Mise à jour Attribution Date Besoin ...
          Attribution_MAJ_DateBesoin(aNeedRecord.FAL_NETWORK_NEED_ID, aBeginEndPlanDate);
        end if;

        -- Modifier l'enregistrement NEED
        update FAL_NETWORK_NEED
           set A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
             , A_DATEMOD = sysdate
             , FAN_BEG_PLAN = aBeginEndPlanDate
             , FAN_END_PLAN = aBeginEndPlanDate
         where current of GetNeedPropRecordForUpdate;
      end if;

      close GetNeedPropRecordForUpdate;
    end loop;

    -- fermeture du curseur sur les composants concernés
    close GetAllPropComposantRecords;
  end ReseauBesoinPropositionFAL_MAJ;

  /***
  * procedure LockAndDeleteLink
  *
  * Procédure de suppression d'une attribution (avec lock des réseaux correspondants )
  */
  procedure LockAndDeleteLink(aFAL_NETWORK_LINK_ID in TTypeID, aCheckUsedLink integer default 1)
  is
    cursor CUR_LOCK_NETW_FOR_DELETE
    is
      select        FNL.FAL_NETWORK_LINK_ID
                  , FNL.FAL_NETWORK_SUPPLY_ID
                  , FNL.FAL_NETWORK_NEED_ID
                  , FNL.STM_STOCK_POSITION_ID
                  , FNL.STM_LOCATION_ID
                  , FNL.FLN_QTY
                  , (select nvl(max(1), 0)
                       from FAL_COMPONENT_LINK FCL
                      where FCL.FAL_NETWORK_LINK_ID = FNL.FAL_NETWORK_LINK_ID) as USED_IN_OUTPUT_MVT
               from FAL_NETWORK_LINK FNL
                  , FAL_NETWORK_SUPPLY FNS
                  , FAL_NETWORK_NEED FNN
                  , STM_STOCK_POSITION SPO
              where FNL.FAL_NETWORK_LINK_ID = aFAL_NETWORK_LINK_ID
                and FNL.FAL_NETWORK_SUPPLY_ID = FNS.FAL_NETWORK_SUPPLY_ID(+)
                and FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID(+)
                and FNL.STM_STOCK_POSITION_ID = SPO.STM_STOCK_POSITION_ID(+)
      for update of FNL.FLN_QTY, FNN.FAN_FREE_QTY, FNN.FAN_FREE_QTY, SPO.SPO_ASSIGN_QUANTITY nowait;

    CurLockNetwForDelete CUR_LOCK_NETW_FOR_DELETE%rowtype;
  begin
    if nvl(aFAL_NETWORK_LINK_ID, 0) <> 0 then
      open CUR_LOCK_NETW_FOR_DELETE;

      fetch CUR_LOCK_NETW_FOR_DELETE
       into CurLockNetwForDelete;

      if     (aCheckUsedLink = 1)
         and (CurLockNetwForDelete.USED_IN_OUTPUT_MVT = 1) then
        raise_application_error(-20040, 'PCS - ' || eLockedNetwExceptionMsg);
      end if;

      -- Si l'attribution existe
      if CUR_LOCK_NETW_FOR_DELETE%found then
        FAL_REDO_ATTRIBS.SuppressionAttribution(CurLockNetwForDelete.FAL_NETWORK_LINK_ID
                                              , CurLockNetwForDelete.FAL_NETWORK_NEED_ID
                                              , CurLockNetwForDelete.FAL_NETWORK_SUPPLY_ID
                                              , CurLockNetwForDelete.STM_STOCK_POSITION_ID
                                              , CurLockNetwForDelete.STM_LOCATION_ID
                                              , CurLockNetwForDelete.FLN_QTY
                                               );
      end if;

      close CUR_LOCK_NETW_FOR_DELETE;
    end if;
  exception
    when eLockedNetwException then
      raise_application_error(-20020, 'PCS - ' || eLockedNetwExceptionMsg);
    when others then
      raise;
  end;

  /***
  * procedure LockAndDeleteLink
  *
  * Idem proc précédente avec retour d'un code en cas d'erreur
  */
  procedure LockAndDeleteLink(aFAL_NETWORK_LINK_ID in TTypeID, aErrorCode in out varchar2)
  is
  begin
    if nvl(aFAL_NETWORK_LINK_ID, 0) <> 0 then
      LockAndDeleteLink(aFAL_NETWORK_LINK_ID);
    end if;
  exception
    when ex.ROW_LOCKED or eLinkInUseException then
      aErrorCode  := 'eLockedNetwException';
    when others then
      raise;
  end;
end FAL_NETWORK;
