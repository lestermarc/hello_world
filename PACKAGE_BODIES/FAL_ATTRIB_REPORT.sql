--------------------------------------------------------
--  DDL for Package Body FAL_ATTRIB_REPORT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_ATTRIB_REPORT" 
is
  function IsProductInFullTracability(StmStockPositionId number)
    return boolean
  is
    cursor cur_Tracability
    is
      select nvl(PDT_FULL_TRACABILITY, 0)
        from GCO_PRODUCT
       where GCO_GOOD_ID = (select GCO_GOOD_ID
                              from STM_STOCK_POSITION
                             where STM_STOCK_POSITION_ID = StmStockPositionId);

    aTracability number;
  begin
    open cur_Tracability;

    fetch cur_Tracability
     into aTracability;

    close cur_Tracability;

    return(aTracability = 1);
  end;

  function HasCharactFifoLifoOrPerempt(StmStockPositionId number)
    return boolean
  is
    cntCaract number;
  begin
    select count(*)
      into cntCaract
      from GCO_CHARACTERIZATION
     where (    C_CHARACT_TYPE = '5'
            and (   C_CHRONOLOGY_TYPE = '1'
                 or C_CHRONOLOGY_TYPE = '2'
                 or C_CHRONOLOGY_TYPE = '3') )
       and GCO_GOOD_ID = (select GCO_GOOD_ID
                            from STM_STOCK_POSITION
                           where STM_STOCK_POSITION_ID = StmStockPositionId);

    return(cntCaract > 0);
  end;

  function ReportAttribStockOutputBarcode(falNetworkNeedId number, StmStockPositionId number, OutputQty number)
    return boolean
  is
    cursor cur_FAL_NETWORK_LINK
    is
      select FAL_NETWORK_LINK_ID
           , FAL_NETWORK_NEED_ID
           , FAL_NETWORK_SUPPLY_ID
           , STM_STOCK_POSITION_ID
           , STM_LOCATION_ID
           , nvl(FLN_QTY, 0) FLN_QTY
        from FAL_NETWORK_LINK
       where STM_STOCK_POSITION_ID = StmStockPositionId
         and FAL_NETWORK_NEED_ID = falNetworkNeedId;

    cursor cur_NEED_ATTRIB_ON_STOCK
    is
      select   FAL_NETWORK_LINK_ID
             , FAL_NETWORK_NEED_ID
             , FAL_NETWORK_SUPPLY_ID
             , STM_STOCK_POSITION_ID
             , STM_LOCATION_ID
             , nvl(FLN_QTY, 0) FLN_QTY
          from FAL_NETWORK_LINK
         where STM_STOCK_POSITION_ID = StmStockPositionId
           and FAL_NETWORK_NEED_ID is not null
      order by FLN_QTY desc;

    cursor cur_STOCK_POSITION
    is
      select   FAL_NETWORK_LINK_ID
             , FAL_NETWORK_NEED_ID
             , FAL_NETWORK_SUPPLY_ID
             , STM_STOCK_POSITION_ID
             , STM_LOCATION_ID
             , nvl(FLN_QTY, 0) FLN_QTY
          from FAL_NETWORK_LINK
         where FAL_NETWORK_NEED_ID = falNetworkNeedId
           and STM_STOCK_POSITION_ID is not null
      order by FLN_QTY desc;

    aQty                  number;
    aContinue             boolean;
    aOutputQty            number;
    Q                     number;
    R                     number;
    ReleasedNeeds         TRecords;
    ReleasedNeedsCnt      integer                        := 0;
    ReleasedStockPosition TRecords;
    ReleasedStockPosCnt   integer                        := 0;
    iPosStock             integer;
    iNeeds                integer;
    curFAL_NETWORK_LINK   cur_FAL_NETWORK_LINK%rowtype;
  begin
    aOutputQty  := OutputQty;

    -- Vérification de disponibilité sur la Position de stock
    select     nvl(SPO_AVAILABLE_QUANTITY, 0)
          into aQty
          from STM_STOCK_POSITION
         where STM_STOCK_POSITION_ID = StmStockPositionId
    for update;

    if aQty >= aOutputQty then
      -- Traitement standard
      return true;
    else
      aOutputQty  := aOutputQty - aQty;
    end if;

    if falNetworkNeedId is null then
      -- Traitement standard (erreur '5'...)
      return false;
    end if;

    -- Vérification que le besoin est attribuée sur stock
    select     nvl(FAN_STK_QTY, 0)
          into aQty
          from FAL_NETWORK_NEED
         where FAL_NETWORK_NEED_ID = falNetworkNeedId
    for update;

    if aQty < aOutputQty then
      -- Traitement standard (erreur '5'...)
      return false;
    end if;

    -- Il existe une attribution sur stock du besoin sur la position de stock
    open cur_FAL_NETWORK_LINK;

    fetch cur_FAL_NETWORK_LINK
     into curFAL_NETWORK_LINK;

    aContinue   := false;

    if cur_FAL_NETWORK_LINK%found then
      -- Qté de l'attribution couvre la "Quantité"
      if curFAL_NETWORK_LINK.FLN_QTY = aOutputQty then
        -- Suppression Attribution
        FAL_REDO_ATTRIBS.SuppressionAttribution(curFAL_NETWORK_LINK.FAL_NETWORK_LINK_ID
                                              , curFAL_NETWORK_LINK.FAL_NETWORK_NEED_ID
                                              , curFAL_NETWORK_LINK.FAL_NETWORK_SUPPLY_ID
                                              , curFAL_NETWORK_LINK.STM_STOCK_POSITION_ID
                                              , curFAL_NETWORK_LINK.STM_LOCATION_ID
                                              , curFAL_NETWORK_LINK.FLN_QTY
                                               );

        close cur_FAL_NETWORK_LINK;

        return true;
      elsif curFAL_NETWORK_LINK.FLN_QTY > aOutputQty then
        -- MAJ "Qte" Attribution sur attribution
        update FAL_NETWORK_LINK
           set FLN_QTY = FLN_QTY - aOutputQty
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where FAL_NETWORK_LINK_ID = curFAL_NETWORK_LINK.FAL_NETWORK_LINK_ID;

        -- Mise à jour  Position de stock
        update STM_STOCK_POSITION
           set SPO_ASSIGN_QUANTITY = SPO_ASSIGN_QUANTITY - aOutputQty
             , SPO_AVAILABLE_QUANTITY = SPO_AVAILABLE_QUANTITY + aOutputQty
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where STM_STOCK_POSITION_ID = StmStockPositionId;

        -- Mise à jour  Reseau Besoin
        update FAL_NETWORK_NEED
           set FAN_FREE_QTY = FAN_FREE_QTY + aOutputQty
             , FAN_STK_QTY = FAN_STK_QTY - aOutputQty
             , A_DATEMOD = sysdate
             , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         where FAL_NETWORK_NEED_ID = falNetworkNeedId;

        close cur_FAL_NETWORK_LINK;

        return true;
      elsif curFAL_NETWORK_LINK.FLN_QTY < aOutputQty then
        -- Le produit (Position de stock -> Produit) est géré en FIFO, LIFO,
        -- Péremption, Traçabilité complète ?
        if    IsProductInFullTracability(StmStockPositionId)
           or HasCharactFifoLifoOrPerempt(StmStockPositionId) then
          aContinue  := false;

          close cur_FAL_NETWORK_LINK;

          return false;
        else
          aContinue  := true;
        end if;

        aOutputQty  := aOutputQty - curFAL_NETWORK_LINK.FLN_QTY;
        FAL_REDO_ATTRIBS.SuppressionAttribution(curFAL_NETWORK_LINK.FAL_NETWORK_LINK_ID
                                              , curFAL_NETWORK_LINK.FAL_NETWORK_NEED_ID
                                              , curFAL_NETWORK_LINK.FAL_NETWORK_SUPPLY_ID
                                              , curFAL_NETWORK_LINK.STM_STOCK_POSITION_ID
                                              , curFAL_NETWORK_LINK.STM_LOCATION_ID
                                              , curFAL_NETWORK_LINK.FLN_QTY
                                               );
        aContinue   := true;
      end if;
    else
      -- Le produit (Position de stock -> Produit) est géré en FIFO, LIFO,
      -- Péremption, Traçabilité complète ?
      if    IsProductInFullTracability(StmStockPositionId)
         or HasCharactFifoLifoOrPerempt(StmStockPositionId) then
        aContinue  := false;

        close cur_FAL_NETWORK_LINK;

        return false;
      else
        aContinue  := true;
      end if;
    end if;

    close cur_FAL_NETWORK_LINK;

    if aContinue then
      Q  := aOutputQty;

      -- Pour chaque Besoin attribué à "Position de stock"
      -- trié dans l'ordre des qté attribué décroissante
      for curNEED_ATTRIB_ON_STOCK in cur_NEED_ATTRIB_ON_STOCK loop
        if curNEED_ATTRIB_ON_STOCK.FLN_QTY > Q then
          -- Enregistrement du Besoin dans une table temporaire "Besoin Libéré"
          ReleasedNeedsCnt                          := ReleasedNeedsCnt + 1;
          ReleasedNeeds(ReleasedNeedsCnt).id        := curNEED_ATTRIB_ON_STOCK.FAL_NETWORK_NEED_ID;
          ReleasedNeeds(ReleasedNeedsCnt).Quantity  := Q;

          -- MAJ "Qte" Attribution sur attribution
          update FAL_NETWORK_LINK
             set FLN_QTY = FLN_QTY - Q
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where FAL_NETWORK_LINK_ID = curNEED_ATTRIB_ON_STOCK.FAL_NETWORK_LINK_ID;

          -- Mise à jour  Position de stock
          update STM_STOCK_POSITION
             set SPO_ASSIGN_QUANTITY = SPO_ASSIGN_QUANTITY - Q
               , SPO_AVAILABLE_QUANTITY = SPO_AVAILABLE_QUANTITY + Q
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where STM_STOCK_POSITION_ID = StmStockPositionId;

          -- Mise à jour  Reseau Besoin
          update FAL_NETWORK_NEED
             set FAN_FREE_QTY = FAN_FREE_QTY + Q
               , FAN_STK_QTY = FAN_STK_QTY - Q
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where FAL_NETWORK_NEED_ID = curNEED_ATTRIB_ON_STOCK.FAL_NETWORK_NEED_ID;

          -- On sort de la boucle
          exit;
        elsif curNEED_ATTRIB_ON_STOCK.FLN_QTY = Q then
          -- Enregistrement du Besoin dans une table temporaire "Besoin Libéré"
          ReleasedNeedsCnt                          := ReleasedNeedsCnt + 1;
          ReleasedNeeds(ReleasedNeedsCnt).id        := curNEED_ATTRIB_ON_STOCK.FAL_NETWORK_NEED_ID;
          ReleasedNeeds(ReleasedNeedsCnt).Quantity  := Q;
          -- Suppression Attribution
          FAL_REDO_ATTRIBS.SuppressionAttribution(curNEED_ATTRIB_ON_STOCK.FAL_NETWORK_LINK_ID
                                                , curNEED_ATTRIB_ON_STOCK.FAL_NETWORK_NEED_ID
                                                , curNEED_ATTRIB_ON_STOCK.FAL_NETWORK_SUPPLY_ID
                                                , curNEED_ATTRIB_ON_STOCK.STM_STOCK_POSITION_ID
                                                , curNEED_ATTRIB_ON_STOCK.STM_LOCATION_ID
                                                , curNEED_ATTRIB_ON_STOCK.FLN_QTY
                                                 );
          -- On sort de la boucle
          exit;
        else
          -- Enregistrement du Besoin dans une table temporaire "Besoin Libéré"
          ReleasedNeedsCnt                          := ReleasedNeedsCnt + 1;
          ReleasedNeeds(ReleasedNeedsCnt).id        := curNEED_ATTRIB_ON_STOCK.FAL_NETWORK_NEED_ID;
          ReleasedNeeds(ReleasedNeedsCnt).Quantity  := curNEED_ATTRIB_ON_STOCK.FLN_QTY;
          -- Suppression Attribution
          FAL_REDO_ATTRIBS.SuppressionAttribution(curNEED_ATTRIB_ON_STOCK.FAL_NETWORK_LINK_ID
                                                , curNEED_ATTRIB_ON_STOCK.FAL_NETWORK_NEED_ID
                                                , curNEED_ATTRIB_ON_STOCK.FAL_NETWORK_SUPPLY_ID
                                                , curNEED_ATTRIB_ON_STOCK.STM_STOCK_POSITION_ID
                                                , curNEED_ATTRIB_ON_STOCK.STM_LOCATION_ID
                                                , curNEED_ATTRIB_ON_STOCK.FLN_QTY
                                                 );
          Q                                         := Q - curNEED_ATTRIB_ON_STOCK.FLN_QTY;
        end if;
      end loop;

      R  := aOutputQty;

      for curSTOCK_POSITION in cur_STOCK_POSITION loop
        if curSTOCK_POSITION.FLN_QTY > R then
          -- Enregistrement de la position de stock dans une table temporaire "Position Stock Libéré"
          ReleasedStockPosCnt                                       := ReleasedStockPosCnt + 1;
          ReleasedStockPosition(ReleasedStockPosCnt).id             := curSTOCK_POSITION.STM_STOCK_POSITION_ID;
          ReleasedStockPosition(ReleasedStockPosCnt).Quantity       := R;
          ReleasedStockPosition(ReleasedStockPosCnt).StmLocationId  := curSTOCK_POSITION.STM_LOCATION_ID;

          -- MAJ "Qte" Attribution sur attribution
          update FAL_NETWORK_LINK
             set FLN_QTY = FLN_QTY - R
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where FAL_NETWORK_LINK_ID = curSTOCK_POSITION.FAL_NETWORK_LINK_ID;

          -- Mise à jour  Position de stock
          update STM_STOCK_POSITION
             set SPO_ASSIGN_QUANTITY = SPO_ASSIGN_QUANTITY - R
               , SPO_AVAILABLE_QUANTITY = SPO_AVAILABLE_QUANTITY + R
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where STM_STOCK_POSITION_ID = curSTOCK_POSITION.STM_STOCK_POSITION_ID;

          -- Mise à jour  Reseau Besoin
          update FAL_NETWORK_NEED
             set FAN_FREE_QTY = FAN_FREE_QTY + R
               , FAN_STK_QTY = FAN_STK_QTY - R
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where FAL_NETWORK_NEED_ID = falNetworkNeedId;

          -- On sort de la boucle
          exit;
        elsif curSTOCK_POSITION.FLN_QTY = R then
          -- Enregistrement de la position de stock dans une table temporaire "Position Stock Libéré"
          ReleasedStockPosCnt                                       := ReleasedStockPosCnt + 1;
          ReleasedStockPosition(ReleasedStockPosCnt).id             := curSTOCK_POSITION.STM_STOCK_POSITION_ID;
          ReleasedStockPosition(ReleasedStockPosCnt).Quantity       := R;
          ReleasedStockPosition(ReleasedStockPosCnt).StmLocationId  := curSTOCK_POSITION.STM_LOCATION_ID;
          -- Suppression Attribution
          FAL_REDO_ATTRIBS.SuppressionAttribution(curSTOCK_POSITION.FAL_NETWORK_LINK_ID
                                                , curSTOCK_POSITION.FAL_NETWORK_NEED_ID
                                                , curSTOCK_POSITION.FAL_NETWORK_SUPPLY_ID
                                                , curSTOCK_POSITION.STM_STOCK_POSITION_ID
                                                , curSTOCK_POSITION.STM_LOCATION_ID
                                                , curSTOCK_POSITION.FLN_QTY
                                                 );
          -- On sort de la boucle
          exit;
        else
          -- Enregistrement de la position de stock dans une table temporaire "Position Stock Libéré"
          ReleasedStockPosCnt                                       := ReleasedStockPosCnt + 1;
          ReleasedStockPosition(ReleasedStockPosCnt).id             := curSTOCK_POSITION.STM_STOCK_POSITION_ID;
          ReleasedStockPosition(ReleasedStockPosCnt).Quantity       := curSTOCK_POSITION.FLN_QTY;
          ReleasedStockPosition(ReleasedStockPosCnt).StmLocationId  := curSTOCK_POSITION.STM_LOCATION_ID;
          -- Suppression Attribution
          FAL_REDO_ATTRIBS.SuppressionAttribution(curSTOCK_POSITION.FAL_NETWORK_LINK_ID
                                                , curSTOCK_POSITION.FAL_NETWORK_NEED_ID
                                                , curSTOCK_POSITION.FAL_NETWORK_SUPPLY_ID
                                                , curSTOCK_POSITION.STM_STOCK_POSITION_ID
                                                , curSTOCK_POSITION.STM_LOCATION_ID
                                                , curSTOCK_POSITION.FLN_QTY
                                                 );
          R                                                         := R - curSTOCK_POSITION.FLN_QTY;
        end if;
      end loop;

      for iPosStock in 1 .. ReleasedStockPosCnt loop
        if ReleasedStockPosition(iPosStock).Quantity > 0 then
          for iNeeds in 1 .. ReleasedNeedsCnt loop
            if ReleasedNeeds(iNeeds).Quantity > 0 then
              -- dans l'analyse =>  R > Q
              if ReleasedStockPosition(iPosStock).Quantity > ReleasedNeeds(iNeeds).Quantity then
                -- Création Attribution Besoin Fab sur stock
                FAL_NETWORK.CreateAttribBesoinStock(ReleasedNeeds(iNeeds).id
                                                  , ReleasedStockPosition(iPosStock).id
                                                  , ReleasedStockPosition(ReleasedStockPosCnt).StmLocationId
                                                  , ReleasedNeeds(iNeeds).Quantity
                                                   );
                ReleasedStockPosition(iPosStock).Quantity  := ReleasedStockPosition(iPosStock).Quantity - ReleasedNeeds(iNeeds).Quantity;
                ReleasedNeeds(iNeeds).Quantity             := 0;
              -- dans l'analyse =>  R = Q
              elsif ReleasedStockPosition(iPosStock).Quantity = ReleasedNeeds(iNeeds).Quantity then
                -- Création Attribution Besoin Fab sur stock
                FAL_NETWORK.CreateAttribBesoinStock(ReleasedNeeds(iNeeds).id
                                                  , ReleasedStockPosition(iPosStock).id
                                                  , ReleasedStockPosition(ReleasedStockPosCnt).StmLocationId
                                                  , ReleasedNeeds(iNeeds).Quantity
                                                   );
                -- Mise à jour enregistrement "Besoin Libéré"
                ReleasedNeeds(iNeeds).Quantity             := 0;
                ReleasedStockPosition(iPosStock).Quantity  := 0;
                -- On sort de la boucle sur les besoins
                exit;
              -- dans l'analyse =>  R < Q
              else
                -- Création Attribution Besoin Fab sur stock
                FAL_NETWORK.CreateAttribBesoinStock(ReleasedNeeds(iNeeds).id
                                                  , ReleasedStockPosition(iPosStock).id
                                                  , ReleasedStockPosition(ReleasedStockPosCnt).StmLocationId
                                                  , ReleasedStockPosition(iPosStock).Quantity
                                                   );
                -- Mise à jour enregistrement "Besoin Libéré"
                ReleasedNeeds(iNeeds).Quantity             := ReleasedNeeds(iNeeds).Quantity - ReleasedStockPosition(iPosStock).Quantity;
                ReleasedStockPosition(iPosStock).Quantity  := 0;
                -- On sort de la boucle sur les besoins
                exit;
              end if;
            end if;
          end loop;
        end if;
      end loop;
    end if;

    return true;
  end;
end;
