--------------------------------------------------------
--  DDL for Package Body FAL_OUT_COMPO_BARCODE_CONTROL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_OUT_COMPO_BARCODE_CONTROL" 
is
  -- Réservation sur une position de stock d'une certaine quantité
  procedure ReserveOnPosition(aSTM_STOCK_POSITION_ID in TTypeID, aQuantity in TTypeQty)
  is
    -- Lecture du record de STM_STOCK_POSITION selon l'ID
    cursor GetStckPosRecord
    is
      select     *
            from STM_STOCK_POSITION
           where STM_STOCK_POSITION_ID = aSTM_STOCK_POSITION_ID
      for update;

    -- Record concerné
    vStckPos GetStckPosRecord%rowtype;
  begin
    -- Ouverture du curseur
    open GetStckPosRecord;

    fetch GetStckPosRecord
     into vStckPos;

    -- S'assurer qu'il y ai un enregistrement ...
    if GetStckPosRecord%found then
      -- Si il existe assez sur la position de stock
      if (nvl(vStckPos.SPO_AVAILABLE_QUANTITY, 0) - aQuantity) >= 0 then
        -- MAJ de la position de stock
        update STM_STOCK_POSITION
           set SPO_PROVISORY_OUTPUT = SPO_PROVISORY_OUTPUT + aQuantity
             , SPO_AVAILABLE_QUANTITY = SPO_AVAILABLE_QUANTITY - aQuantity
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where current of GetStckPosRecord;
      else
        -- Levé d'une exception
        RAISE_APPLICATION_ERROR(-20001, 'Not enough quantity on stock position');
      end if;
    else
      -- Levé d'une exception
      RAISE_APPLICATION_ERROR(-20002, 'Stock position not found');
    end if;

    -- Fermeture du curseur
    close GetStckPosRecord;
  exception
    when others then
      -- Fermeture du curseur
      close GetStckPosRecord;

      -- En cas de pbs, on laisse l'exception se propager
      raise;
  end;

  -- Contrôle des données pour un enregistrement FAL_OUT_COMPO_BARCODE
  -- retourne le code erreur trouvé
  function ControlRecord(
    aFAL_OUT_COMPO_BARCODE_ID     in TTypeID
  , aFAL_LOT_ID                   in TTypeID
  , aGCO_GOOD_ID                  in TTypeID
  , aFAL_LOT_MATERIAL_LINK_ID     in TTypeID
  , aSTM_STOCK_ID                 in TTypeID
  , aSTM_LOCATION_ID              in TTypeID
  , aGCO_CHARACTERIZATION_ID      in TTypeID
  , aFOC_CHARACTERIZATION_VALUE_1 in TTypeChara
  , aGCO_GCO_CHARACTERIZATION_ID  in TTypeID
  , aFOC_CHARACTERIZATION_VALUE_2 in TTypeChara
  , aGCO2_CHARACTERIZATION_ID     in TTypeID
  , aFOC_CHARACTERIZATION_VALUE_3 in TTypeChara
  , aGCO3_CHARACTERIZATION_ID     in TTypeID
  , aFOC_CHARACTERIZATION_VALUE_4 in TTypeChara
  , aGCO4_CHARACTERIZATION_ID     in TTypeID
  , aFOC_CHARACTERIZATION_VALUE_5 in TTypeChara
  , aFOC_QUANTITY                 in TTypeQty
  )
    return TTypeError
  is
    pragma autonomous_transaction;
    -- Déclaration de la variable pour le stockage du code erreur
    OutCompo_ERROR     TTypeError;
    FalNetworkNeedId   number;
    StmStockPositionId number;

    -- Détermination de la quantité Z (disponibilité de la position de stock concernée)
    function GetQuantityZ
      return TTypeQty
    is
      QuantityZ TTypeQty;
      StkNumber number;
    begin
      if aGCO_CHARACTERIZATION_ID is not null then
        select CHA_STOCK_MANAGEMENT
          into StkNumber
          from GCO_CHARACTERIZATION
         where GCO_CHARACTERIZATION_ID = aGCO_CHARACTERIZATION_ID;

        -- Si la caractérisation est en gestion de stock
        if StkNumber = 1 then
          select sum(SPO_AVAILABLE_QUANTITY)
            into QuantityZ
            from STM_STOCK_POSITION
           where GCO_GOOD_ID = aGCO_GOOD_ID
             and STM_LOCATION_ID = aSTM_LOCATION_ID
             and (   GCO_CHARACTERIZATION_ID = aGCO_CHARACTERIZATION_ID
                  or nvl(aGCO_CHARACTERIZATION_ID, 0) = 0)
             and (   SPO_CHARACTERIZATION_VALUE_1 = aFOC_CHARACTERIZATION_VALUE_1
                  or aFOC_CHARACTERIZATION_VALUE_1 is null)
             and (   GCO_GCO_CHARACTERIZATION_ID = aGCO_GCO_CHARACTERIZATION_ID
                  or nvl(aGCO_GCO_CHARACTERIZATION_ID, 0) = 0)
             and (   SPO_CHARACTERIZATION_VALUE_2 = aFOC_CHARACTERIZATION_VALUE_2
                  or aFOC_CHARACTERIZATION_VALUE_2 is null)
             and (   GCO2_GCO_CHARACTERIZATION_ID = aGCO2_CHARACTERIZATION_ID
                  or nvl(aGCO2_CHARACTERIZATION_ID, 0) = 0)
             and (   SPO_CHARACTERIZATION_VALUE_3 = aFOC_CHARACTERIZATION_VALUE_3
                  or aFOC_CHARACTERIZATION_VALUE_3 is null)
             and (   GCO3_GCO_CHARACTERIZATION_ID = aGCO3_CHARACTERIZATION_ID
                  or nvl(aGCO3_CHARACTERIZATION_ID, 0) = 0)
             and (   SPO_CHARACTERIZATION_VALUE_4 = aFOC_CHARACTERIZATION_VALUE_4
                  or aFOC_CHARACTERIZATION_VALUE_4 is null)
             and (   GCO4_GCO_CHARACTERIZATION_ID = aGCO4_CHARACTERIZATION_ID
                  or nvl(aGCO4_CHARACTERIZATION_ID, 0) = 0)
             and (   SPO_CHARACTERIZATION_VALUE_5 = aFOC_CHARACTERIZATION_VALUE_5
                  or aFOC_CHARACTERIZATION_VALUE_5 is null);
        else
          select sum(SPO_AVAILABLE_QUANTITY)
            into QuantityZ
            from STM_STOCK_POSITION
           where GCO_GOOD_ID = aGCO_GOOD_ID
             and STM_LOCATION_ID = aSTM_LOCATION_ID;
        end if;
      else
        select sum(SPO_AVAILABLE_QUANTITY)
          into QuantityZ
          from STM_STOCK_POSITION
         where GCO_GOOD_ID = aGCO_GOOD_ID
           and STM_LOCATION_ID = aSTM_LOCATION_ID;
      end if;

      if QuantityZ is null then
        QuantityZ  := 0;
      end if;

      return QuantityZ;
    exception
      when no_data_found then
        return 0;
    end;

    -- Check de l'existance de l'OF (il ne doit pas pas être de type sous-traitance
    function BatchExists
      return boolean
    is
      cntBatches integer;
    begin
      select count(*)
        into cntBatches
        from FAL_LOT
       where FAL_LOT_ID = aFAL_LOT_ID
         and nvl(C_FAB_TYPE, '0') <> '4';

      return(cntBatches > 0);
    end;

    -- Détermination de la quantité supérieure à la qté besoin CPT (somme des qtés saisies pour les FAL_OUT_COMPO_BARCODE similaire à celui en cours)
    function IsQtiesSuperior
      return boolean
    is
      NeedQty  TTypeQty;
      Quantity TTypeQty;
    begin
      select LOM_NEED_QTY
        into NeedQty
        from FAL_LOT_MATERIAL_LINK
       where FAL_LOT_MATERIAL_LINK_ID = aFAL_LOT_MATERIAL_LINK_ID;

      if NeedQty is not null then
        begin
          select sum(FOC_QUANTITY)
            into Quantity
            from FAL_OUT_COMPO_BARCODE
           where FAL_OUT_COMPO_BARCODE_ID <> aFAL_OUT_COMPO_BARCODE_ID
             and FAL_LOT_MATERIAL_LINK_ID = aFAL_LOT_MATERIAL_LINK_ID;
        exception
          when no_data_found then
            Quantity  := 0;
        end;

        if Quantity is null then
          Quantity  := 0;
        end if;

        return(Quantity + aFOC_QUANTITY) > NeedQty;
      else
        return true;
      end if;
    exception
      when no_data_found then
        return true;
    end;

    -- Détermination de la quantité inférieure à la qté besoin CPT (somme des qtés saisies pour les FAL_OUT_COMPO_BARCODE similaire à celui en cours)
    function IsQtiesInferior
      return boolean
    is
      NeedQty  TTypeQty;
      Quantity TTypeQty;
    begin
      select LOM_NEED_QTY
        into NeedQty
        from FAL_LOT_MATERIAL_LINK
       where FAL_LOT_MATERIAL_LINK_ID = aFAL_LOT_MATERIAL_LINK_ID;

      if NeedQty is not null then
        begin
          select sum(FOC_QUANTITY)
            into Quantity
            from FAL_OUT_COMPO_BARCODE
           where FAL_OUT_COMPO_BARCODE_ID <> aFAL_OUT_COMPO_BARCODE_ID
             and FAL_LOT_MATERIAL_LINK_ID = aFAL_LOT_MATERIAL_LINK_ID;
        exception
          when no_data_found then
            Quantity  := 0;
        end;

        if Quantity is null then
          Quantity  := 0;
        end if;

        return(Quantity + aFOC_QUANTITY) < NeedQty;
      else
        return true;
      end if;
    exception
      when no_data_found then
        return true;
    end;

    -- Détermination si le lot est bien en statut lancé
    function IsLaunchedLot
      return boolean
    is
      LotStatus FAL_LOT.C_LOT_STATUS%type;
    begin
      select C_LOT_STATUS
        into LotStatus
        from FAL_LOT
       where FAL_LOT_ID = aFAL_LOT_ID;

      if LotStatus is null then
        return false;
      else
        return LotStatus = '2';
      end if;
    exception
      when no_data_found then
        return false;
    end;

    -- Détermination si le lien composant est valide
    function IsValidMatLink
      return boolean
    is
      TypeCom FAL_LOT_MATERIAL_LINK.C_TYPE_COM%type;
      KindCom FAL_LOT_MATERIAL_LINK.C_KIND_COM%type;
      StMngmt FAL_LOT_MATERIAL_LINK.LOM_STOCK_MANAGEMENT%type;
      result  boolean;
    begin
      result  := true;

      if aFAL_LOT_MATERIAL_LINK_ID is not null then
        select C_TYPE_COM
             , C_KIND_COM
             , LOM_STOCK_MANAGEMENT
          into TypeCom
             , KindCom
             , StMngmt
          from FAL_LOT_MATERIAL_LINK
         where FAL_LOT_MATERIAL_LINK_ID = aFAL_LOT_MATERIAL_LINK_ID;

        result  :=     (nvl(TypeCom, '0') = '1')
                   and (nvl(KindCom, '0') = '1')
                   and (nvl(StMngmt, 0) = 1);
      end if;

      return result;
    exception
      when no_data_found then
        return false;
    end;

    function CheckReportAttrib
      return boolean
    is
    begin
      -- Récupération du Stm_Stock_Position_Id
      select STM_STOCK_POSITION_ID
        into StmStockPositionId
        from STM_STOCK_POSITION
       where GCO_GOOD_ID = aGCO_GOOD_ID
         and STM_LOCATION_ID = aSTM_LOCATION_ID
         and (   GCO_CHARACTERIZATION_ID = aGCO_CHARACTERIZATION_ID
              or nvl(aGCO_CHARACTERIZATION_ID, 0) = 0)
         and (   SPO_CHARACTERIZATION_VALUE_1 = aFOC_CHARACTERIZATION_VALUE_1
              or aFOC_CHARACTERIZATION_VALUE_1 is null)
         and (   GCO_GCO_CHARACTERIZATION_ID = aGCO_GCO_CHARACTERIZATION_ID
              or nvl(aGCO_GCO_CHARACTERIZATION_ID, 0) = 0)
         and (   SPO_CHARACTERIZATION_VALUE_2 = aFOC_CHARACTERIZATION_VALUE_2
              or aFOC_CHARACTERIZATION_VALUE_2 is null)
         and (   GCO2_GCO_CHARACTERIZATION_ID = aGCO2_CHARACTERIZATION_ID
              or nvl(aGCO2_CHARACTERIZATION_ID, 0) = 0)
         and (   SPO_CHARACTERIZATION_VALUE_3 = aFOC_CHARACTERIZATION_VALUE_3
              or aFOC_CHARACTERIZATION_VALUE_3 is null)
         and (   GCO3_GCO_CHARACTERIZATION_ID = aGCO3_CHARACTERIZATION_ID
              or nvl(aGCO3_CHARACTERIZATION_ID, 0) = 0)
         and (   SPO_CHARACTERIZATION_VALUE_4 = aFOC_CHARACTERIZATION_VALUE_4
              or aFOC_CHARACTERIZATION_VALUE_4 is null)
         and (   GCO4_GCO_CHARACTERIZATION_ID = aGCO4_CHARACTERIZATION_ID
              or nvl(aGCO4_CHARACTERIZATION_ID, 0) = 0)
         and (   SPO_CHARACTERIZATION_VALUE_5 = aFOC_CHARACTERIZATION_VALUE_5
              or aFOC_CHARACTERIZATION_VALUE_5 is null);

      -- Récupération du Fal_Network_Need_Id
      select max(FAL_NETWORK_NEED_ID)
        into FalNetworkNeedId
        from FAL_NETWORK_NEED
       where FAL_LOT_MATERIAL_LINK_ID = aFAL_LOT_MATERIAL_LINK_ID;

      return FAL_ATTRIB_REPORT.ReportAttribStockOutputBarcode(FalNetworkNeedId, StmStockPositionId, aFOC_QUANTITY);
    exception
      when no_data_found then
        begin
          return false;
        end;
    end;
  begin
    -- Gestion de l'erreur 1
    -- Contrôle sur l'existance du lot
    if not BatchExists then
      -- Erreur Code 01
      OutCompo_ERROR  := '01';
    -- Gestion de l'erreur 2
    -- Contrôle sur l'existance du produit
    elsif aGCO_GOOD_ID is null then
      -- Erreur Code 02
      OutCompo_ERROR  := '02';
    -- Gestion de l'erreur 3
    -- Contrôle sur l'existance du lien composant
    elsif     (aFAL_LOT_MATERIAL_LINK_ID is null)
          and (aFAL_LOT_ID is null)
          and (aGCO_GOOD_ID is null) then
      -- Erreur Code 03
      OutCompo_ERROR  := '03';
    -- Gestion de l'erreur 4
    -- Contrôle sur la saisie de la caractérisation
    elsif     (aFOC_CHARACTERIZATION_VALUE_1 is null)
          and (aGCO_CHARACTERIZATION_ID is not null) then
      -- Erreur Code 04
      OutCompo_ERROR  := '04';
    -- Gestion de l'erreur 5
    -- Contrôle que caractérisation n'est pas inexistante dans le stock spécifié
    elsif     (aGCO_CHARACTERIZATION_ID is not null)
          and (   not CheckReportAttrib
               or (GetQuantityZ <= 0) ) then
      -- Erreur Code 05
      OutCompo_ERROR  := '05';
    -- Gestion de l'erreur 6
    -- Contrôle sur la cohérence du stock informatique et celui physique
    elsif(GetQuantityZ < nvl(aFOC_QUANTITY, 0) ) then
      -- Erreur Code 06
      OutCompo_ERROR  := '06';
    -- Gestion de l'erreur 7
    -- Contrôle que le lot est bien en statut lancé
    elsif not IsLaunchedLot then
      -- Erreur Code 07
      OutCompo_ERROR  := '07';
    -- Gestion de l'erreur 8
    -- Contrôle que le lien composant est valide
    elsif not IsValidMatLink then
      -- Erreur Code 08
      OutCompo_ERROR  := '08';
    -- Gestion de l'erreur 13
    -- Contrôle que le produit n'est pas à peser (Gestion des matières précieuses)
    elsif GCO_PRECIOUS_MAT_FUNCTIONS.IsProductWithPMatWithWeighing(aGCO_GOOD_ID) = 1 then
      OutCompo_ERROR  := '13';
    -- Gestion de l'erreur 9
    -- Contrôle de la quantité supérieure à la qté besoin CPT
    elsif IsQtiesSuperior then
      -- Erreur Code 09
      OutCompo_ERROR  := '09';
    -- Gestion de l'erreur 10
    -- Contrôle de la quantité inférieure à la qté besoin CPT
    elsif IsQtiesInferior then
      -- Erreur Code 10
      OutCompo_ERROR  := '10';
    else
      -- Sinon, tous les contrôles ont été négatifs
      OutCompo_ERROR  := null;
    end if;

    commit;
    -- Retourne le code erreur trouvé
    return OutCompo_ERROR;
  end;

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Contrôle des données pour tous les enregistrements de la table FAL_OUT_COMPO_BARCODE
  procedure ControlOutCompoBarcodeTable(aFalOutCompoBarcodeId number default null)
  is
    -- Curseur sur la table FAL_OUT_COMPO_BARCODE
    cursor crCompobarcode
    is
      select     FAL_OUT_COMPO_BARCODE_ID
               , FAL_LOT_ID
               , GCO_GOOD_ID
               , FAL_LOT_MATERIAL_LINK_ID
               , STM_STOCK_ID
               , STM_LOCATION_ID
               , GCO_CHARACTERIZATION_ID
               , FOC_CHARACTERIZATION_VALUE_1
               , GCO_GCO_CHARACTERIZATION_ID
               , FOC_CHARACTERIZATION_VALUE_2
               , GCO2_GCO_CHARACTERIZATION_ID
               , FOC_CHARACTERIZATION_VALUE_3
               , GCO3_GCO_CHARACTERIZATION_ID
               , FOC_CHARACTERIZATION_VALUE_4
               , GCO4_GCO_CHARACTERIZATION_ID
               , FOC_CHARACTERIZATION_VALUE_5
               , nvl(FOC_QUANTITY, 0) FOC_QUANTITY
               , FOC_ACCEPT
            from FAL_OUT_COMPO_BARCODE
           where (    (aFalOutCompoBarcodeId is null)
                  or (FAL_OUT_COMPO_BARCODE_ID = aFalOutCompoBarcodeId) )
        order by GCO_GOOD_ID
      for update;

    -- Variable de récupération du code d'erreur
    OutCompoError        TTypeError;
  begin
    for tplCompoBarcode in crCompobarcode loop
      -- Récupération du code d'erreur
      OutCompoError  :=
        ControlRecord(tplCompoBarcode.FAL_OUT_COMPO_BARCODE_ID
                    , tplCompoBarcode.FAL_LOT_ID
                    , tplCompoBarcode.GCO_GOOD_ID
                    , tplCompoBarcode.FAL_LOT_MATERIAL_LINK_ID
                    , tplCompoBarcode.STM_STOCK_ID
                    , tplCompoBarcode.STM_LOCATION_ID
                    , tplCompoBarcode.GCO_CHARACTERIZATION_ID
                    , tplCompoBarcode.FOC_CHARACTERIZATION_VALUE_1
                    , tplCompoBarcode.GCO_GCO_CHARACTERIZATION_ID
                    , tplCompoBarcode.FOC_CHARACTERIZATION_VALUE_2
                    , tplCompoBarcode.GCO2_GCO_CHARACTERIZATION_ID
                    , tplCompoBarcode.FOC_CHARACTERIZATION_VALUE_3
                    , tplCompoBarcode.GCO3_GCO_CHARACTERIZATION_ID
                    , tplCompoBarcode.FOC_CHARACTERIZATION_VALUE_4
                    , tplCompoBarcode.GCO4_GCO_CHARACTERIZATION_ID
                    , tplCompoBarcode.FOC_CHARACTERIZATION_VALUE_5
                    , tplCompoBarcode.FOC_QUANTITY
                     );

      -- MAJ du code erreur de l'enregistrement en cours
      UpdateBarcodeRecordError(tplCompoBarcode.FAL_OUT_COMPO_BARCODE_ID, OutCompoError);

    end loop;
  end;

  -- Mise à jour du code erreur d'un enregistrement barcode
  procedure UpdateBarcodeRecordError(iCompoBarcodeId in number, iError in varchar2, iErrorMessage in varchar2 default null)
  is
  begin
    update FAL_OUT_COMPO_BARCODE
       set C_OUT_COMPO_ERROR = iError
         , FOC_ERROR_MESSAGE = iErrorMessage
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , A_DATEMOD = sysdate
     where FAL_OUT_COMPO_BARCODE_ID = iCompoBarcodeId;
  end;
end;
