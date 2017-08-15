--------------------------------------------------------
--  DDL for Package Body STM_PRC_COSTPRICE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_PRC_COSTPRICE" 
is
  /**
  * Description
  *    Mise à jour du prix de revient calculé standard d'un bien
  *    selon un mouvement de stock
  */
  procedure updateWAC(ioMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement, iVirtual in boolean := false, iUpdateMvt in boolean := false)
  is
    lCalcCostpriceID    PTC_CALC_COSTPRICE.PTC_CALC_COSTPRICE_ID%type;
    lTypeMoveSign       number(1);
    lMoveSign           number(1);
    lMovementSort       STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type;
    lMovementType       STM_MOVEMENT_KIND.C_MOVEMENT_TYPE%type;
    lMovementCode       STM_MOVEMENT_KIND.C_MOVEMENT_CODE%type;
    lMovementKindId2    STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
    lTraMvtKindId       STM_MOVEMENT_KIND.STM_STM_MOVEMENT_KIND_ID%type;
    lUpdateCostPrice    STM_MOVEMENT_KIND.MOK_COSTPRICE_USE%type;
    lUpdateCostPriceTra STM_MOVEMENT_KIND.MOK_COSTPRICE_USE%type;
    lResetCostPrice     number(1);
  begin
    -- recherche de la valeur de configuration STM_RESET_COST_PRICE
    lResetCostPrice  := to_number(PCS.PC_CONFIG.GetConfig('STM_RESET_COST_PRICE') );

    -- recherche si on a affaire à une entrée ou une sortie
    select c_movement_sort
         , mok_standard_sign
         , c_movement_type
         , c_movement_code
         , nvl(MOK_COSTPRICE_USE, 0)
         , STM_STM_MOVEMENT_KIND_ID
      into lMovementSort
         , lTypeMoveSign
         , lMovementType
         , lMovementCode
         , lUpdateCostPrice
         , lTraMvtKindId
      from stm_movement_kind
     where stm_movement_kind_id = ioMovementRecord.STM_MOVEMENT_KIND_ID;

    if iUpdateMvt then
      lUpdateCostPrice  := ioMovementRecord.SMO_UPDATE_PRCS;
    end if;

    -- si le produit est fait sur un stock virtuel, pas de maj du PRCS
    if     lUpdateCostPrice = 1
       and STM_LIB_STOCK.IsVirtual(ioMovementRecord.STM_STOCK_ID) = 1 then
      lUpdateCostPrice  := 0;
    end if;

    -- recherche la valeur du flag "Mise à jour PRCS" pour le mouvement de transfert lié, s'il s'agit d'un mouvement de transfert
    if not nvl(lTraMvtKindId, 0) = 0 then
      if nvl(ioMovementRecord.STM_STM_STOCK_MOVEMENT_ID, 0) = 0 then
        -- Traitement du premier mouvement dans un transfert. C'est toujours sur le genre de mouvement que le flag de mise à jour du PRCS
        -- est récupéré
        select MOK_COSTPRICE_USE
          into lUpdateCostPriceTra
          from STM_MOVEMENT_KIND
         where STM_MOVEMENT_KIND_ID = lTraMvtKindId;
      else
        -- Traitement du second mouvement dans un transfert. C'est le flag de mise à jour du PRCS du mouvement lié qui est récupéré.
        select SMO_UPDATE_PRCS
          into lUpdateCostPriceTra
          from STM_STOCK_MOVEMENT
         where STM_STOCK_MOVEMENT_ID = ioMovementRecord.STM_STM_STOCK_MOVEMENT_ID;
      end if;
    end if;

    if not iVirtual then
      -- recherche des anciennes valeurs et quantités cumulées
      select GOO_ADDED_QTY_COST_PRICE
           , GOO_ADDED_VALUE_COST_PRICE
           , GOO_BASE_COST_PRICE
        into ioMovementRecord.SMO_PRCS_ADDED_QUANTITY_BEFORE
           , ioMovementRecord.SMO_PRCS_ADDED_VALUE_BEFORE
           , ioMovementRecord.SMO_PRCS_BEFORE
        from GCO_GOOD_CALC_DATA
       where GCO_GOOD_ID = ioMovementRecord.GCO_GOOD_ID;
    end if;

    --
    -- Voir régles dans diagramme Calcul du PRCS lors du passage d'un mouvement de stock (dev/STM/STM_STOCK_MOVEMENTS/Prix de revient calculé standard/Calculation)
    --
    -- si on a affaire a un mouvement de type EXERCICE, il n'y a pas de mise à jour des positions
    if lMovementType <> 'EXE' then
      -- mise à jour du sign du mouvement
      if lMovementSort = 'ENT' then
        lMoveSign  := lTypeMoveSign;

        -- La valeur du mouvement pour PRCS ne doit pas être déjà renseignée. Elle peut l'être en fabrication dans le cas des
        -- Retour Atelier Vers Dechet et Retour Atelier Vers Stock
        if ioMovementRecord.SMO_PRCS_VALUE is null then
          -- Traitement des mouvements de transfert qui possède le même code de mise à jour du PRCS (MOK_COSTPRICE_USE ou éventuellement SMO_UPDATE_PRCS)
          if     (nvl(lTraMvtKindId, 0) <> 0)
             and (lUpdateCostPrice = lUpdateCostPriceTra) then
            ioMovementRecord.SMO_PRCS_VALUE  := ioMovementRecord.SMO_MOVEMENT_QUANTITY * ioMovementRecord.SMO_PRCS_BEFORE;
          else
            -- Traitement des mouvements d'entrée simple ou de transfert avec un code d'influence du PRCS différent entre les deux mouvements liés.
            --
            -- Utilise comme valeur du mouvement pour PRCS le prix du mouvement
            ioMovementRecord.SMO_PRCS_VALUE  := ioMovementRecord.SMO_MOVEMENT_PRICE;
          end if;
        end if;
      else
        lMoveSign  :=(-1 * lTypeMoveSign);

        -- note de débit ou movement d'inventaire manuel
        if DOC_I_LIB_GAUGE.IsDebitNote(iDetailId => ioMovementRecord.DOC_POSITION_DETAIL_ID) = 1 or
           lMovementCode = '003' then

          ioMovementRecord.SMO_PRCS_VALUE  := ioMovementRecord.SMO_MOVEMENT_PRICE;
        else   -- cas normal lors d'une sortie
          if ioMovementRecord.SMO_PRCS_VALUE is null then
            -- valorisation au PRCS au moment du mouvement
            ioMovementRecord.SMO_PRCS_VALUE  := ioMovementRecord.SMO_MOVEMENT_QUANTITY * ioMovementRecord.SMO_PRCS_BEFORE;
          end if;
        end if;
      end if;

      -- Si le type de mouvement influence le prix de revient  des biens
      if lUpdateCostPrice = 1 then
        ioMovementRecord.SMO_UPDATE_PRCS                := 1;
        -- assignation des valeur de retour pour les nouvelles qtés et les nouvelles valeurs cumulée PRCS
        ioMovementRecord.SMO_PRCS_ADDED_QUANTITY_AFTER  := ioMovementRecord.SMO_PRCS_ADDED_QUANTITY_BEFORE + ioMovementRecord.SMO_MOVEMENT_QUANTITY * lMoveSign;
        ioMovementRecord.SMO_PRCS_ADDED_VALUE_AFTER     := ioMovementRecord.SMO_PRCS_ADDED_VALUE_BEFORE + ioMovementRecord.SMO_PRCS_VALUE * lMoveSign;
        ioMovementRecord.SMO_PRCS_ADDED_VALUE_AFTER     := nvl(ioMovementRecord.SMO_PRCS_ADDED_VALUE_AFTER, 0);
        ioMovementRecord.SMO_PRCS_ADDED_QUANTITY_AFTER  := nvl(ioMovementRecord.SMO_PRCS_ADDED_QUANTITY_AFTER, 0);

        -- Mise à jour normale
        if ioMovementRecord.SMO_PRCS_ADDED_QUANTITY_AFTER <> 0 then
          ioMovementRecord.SMO_PRCS_AFTER  :=(ioMovementRecord.SMO_PRCS_ADDED_VALUE_AFTER / ioMovementRecord.SMO_PRCS_ADDED_QUANTITY_AFTER);
        else   -- si le cumul = 0 => prcs = Prcs ou 0 selon valeur de la config
          select decode(lResetCostPrice, 1, 0, nvl(ioMovementRecord.SMO_PRCS_BEFORE, 0) )
            into ioMovementRecord.SMO_PRCS_AFTER
            from dual;

          ioMovementRecord.SMO_PRCS_ADDED_VALUE_AFTER  := 0;
        end if;

        if not iVirtual then
          update GCO_GOOD_CALC_DATA
             set GOO_ADDED_QTY_COST_PRICE = ioMovementRecord.SMO_PRCS_ADDED_QUANTITY_AFTER
               , GOO_ADDED_VALUE_COST_PRICE = ioMovementRecord.SMO_PRCS_ADDED_VALUE_AFTER
               , GOO_BASE_COST_PRICE = ioMovementRecord.SMO_PRCS_AFTER
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where GCO_GOOD_ID = ioMovementRecord.GCO_GOOD_ID;
        end if;
      else
        ioMovementRecord.SMO_PRCS_ADDED_QUANTITY_AFTER  := nvl(ioMovementRecord.SMO_PRCS_ADDED_QUANTITY_BEFORE, 0);
        ioMovementRecord.SMO_PRCS_ADDED_VALUE_AFTER     := nvl(ioMovementRecord.SMO_PRCS_ADDED_VALUE_BEFORE, 0);
        ioMovementRecord.SMO_PRCS_AFTER                 := nvl(ioMovementRecord.SMO_PRCS_BEFORE, 0);
        ioMovementRecord.SMO_UPDATE_PRCS                := 0;
      end if;
    else
      ioMovementRecord.SMO_PRCS_ADDED_QUANTITY_AFTER  := nvl(ioMovementRecord.SMO_PRCS_ADDED_QUANTITY_BEFORE, 0);
      ioMovementRecord.SMO_PRCS_ADDED_VALUE_AFTER     := nvl(ioMovementRecord.SMO_PRCS_ADDED_VALUE_BEFORE, 0);
      ioMovementRecord.SMO_PRCS_AFTER                 := nvl(ioMovementRecord.SMO_PRCS_BEFORE, 0);
      ioMovementRecord.SMO_UPDATE_PRCS                := 0;
    end if;
  end updateWAC;

  /**
  * procedure updateCCP
  * Description
  *    Mise à jour de tous les prix de revient calculés de la table PTC_CALC_COSTPRICE
  *    d'un bien selon un mouvement de stock
  */
  procedure updateCCP(iMovementRecord in FWK_TYP_STM_ENTITY.tStockMovement)
  is
    -- déclaration d'un curseur qui pointe sur les différents prix à mettre à jour suite au mouvement de stock
    cursor crCalcCostprice(cu_movement_kind_id number, cu_good_id number)
    is
      select PTC_CALC_COSTPRICE.PTC_CALC_COSTPRICE_ID
           , PTC_CALC_COSTPRICE.CCP_ADDED_QUANTITY
           , PTC_CALC_COSTPRICE.CCP_ADDED_VALUE
           , PTC_CALC_COSTPRICE.C_UPDATE_CYCLE
        from PTC_CALC_COSTPRICE
           , PTC_PRC_S_STOCK_MVT
       where PTC_CALC_COSTPRICE.GCO_GOOD_ID = CU_GOOD_ID
         and PTC_PRC_S_STOCK_MVT.PTC_CALC_COSTPRICE_ID = PTC_CALC_COSTPRICE.PTC_CALC_COSTPRICE_ID
         and PTC_PRC_S_STOCK_MVT.STM_MOVEMENT_KIND_ID = CU_MOVEMENT_KIND_ID
         and PTC_CALC_COSTPRICE.C_COSTPRICE_STATUS = 'ACT';

    lMoveSign     number(1);
    lTypeMoveSign number(1);
    lMovementSort STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type;
    lMovementType STM_MOVEMENT_KIND.C_MOVEMENT_TYPE%type;
    lMvtQty       STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type   := iMovementRecord.SMO_MOVEMENT_QUANTITY;
    lMvtPrice     STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type      := iMovementRecord.SMO_MOVEMENT_PRICE;
  begin
    -- recherche du type et du signe du mouvement
    select c_movement_sort
         , mok_standard_sign
         , c_movement_type
      into lMovementSort
         , lTypeMoveSign
         , lMovementType
      from stm_movement_kind
     where stm_movement_kind_id = iMovementRecord.STM_MOVEMENT_KIND_ID;

    -- si on a affaire a un mouvement de type EXERCICE, il n'y a pas de mise à jour des positions
    if lMovementType <> 'EXE' then
      -- mise à jour du sign mouvement
      if lMovementSort = 'ENT' then
        lMoveSign  := lTypeMoveSign;
      else
        lMoveSign  :=(-1 * lTypeMoveSign);
      end if;

      -- tant que l'on n'est EOF. Le test est effectué avec une variable système
      for tplCalcCostPrice in crCalcCostprice(iMovementRecord.STM_MOVEMENT_KIND_ID, iMovementRecord.GCO_GOOD_ID) loop
        -- Si on est en face d'une mise à jour systématique et que le mouvement est une extourne
        if     tplCalcCostPrice.C_UPDATE_CYCLE = 'SYS'
           and iMovementRecord.SMO_EXTOURNE_MVT = 1 then
          -- on recherche dans l'historique des mouvements le dernier mouvement valide pour valoriser le prix
          for ltplLastMvt in (select   SMO_MOVEMENT_QUANTITY
                                     , SMO_MOVEMENT_PRICE
                                  from STM_STOCK_MOVEMENT SMO
                                 where SMO.GCO_GOOD_ID = iMovementRecord.GCO_GOOD_ID
                                   and SMO.STM_MOVEMENT_KIND_ID in(select STM_MOVEMENT_KIND_ID
                                                                     from PTC_PRC_S_STOCK_MVT PSM
                                                                    where PSM.PTC_CALC_COSTPRICE_ID = tplCalcCostPrice.PTC_CALC_COSTPRICE_ID)
                                   and STM_STOCK_MOVEMENT_ID <> iMovementRecord.STM2_STM_STOCK_MOVEMENT_ID
                                   and nvl(SMO_EXTOURNE_MVT, 0) = 0
                                   and STM2_STM_STOCK_MOVEMENT_ID is null
                              order by STM_STOCK_MOVEMENT_ID desc) loop
            lMvtQty    := ltplLastMvt.SMO_MOVEMENT_QUANTITY;
            lMvtPrice  := ltplLastMvt.SMO_MOVEMENT_PRICE;
            exit;
          end loop;
        end if;

        -- si on a une remise à jour systématique
        if tplCalcCostPrice.C_UPDATE_CYCLE = 'SYS' then
          tplCalcCostPrice.CCP_ADDED_QUANTITY  := 0;
          tplCalcCostPrice.CCP_ADDED_VALUE     := 0;
        end if;

        -- Teste pour éviter division par 0 et mise à jour du cumul de la quantité
        -- si le cumul = 0 => prix = 0
        if (tplCalcCostPrice.CCP_ADDED_QUANTITY + lMvtQty * lMoveSign) = 0 then
          update PTC_CALC_COSTPRICE
             set CCP_ADDED_QUANTITY = tplCalcCostPrice.CCP_ADDED_QUANTITY + lMvtQty * lMoveSign
               , CCP_ADDED_VALUE = tplCalcCostPrice.CCP_ADDED_VALUE + lMvtPrice * lMoveSign
               , CPR_PRICE = 0
               , STM_STOCK_MOVEMENT_ID = iMovementRecord.STM_STOCK_MOVEMENT_ID
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where PTC_CALC_COSTPRICE_ID = tplCalcCostPrice.PTC_CALC_COSTPRICE_ID;
        else
          update PTC_CALC_COSTPRICE
             set CCP_ADDED_QUANTITY = tplCalcCostPrice.CCP_ADDED_QUANTITY + lMvtQty * lMoveSign
               , CCP_ADDED_VALUE = tplCalcCostPrice.CCP_ADDED_VALUE + lMvtPrice * lMoveSign
               , CPR_PRICE =( (tplCalcCostPrice.CCP_ADDED_VALUE + lMvtPrice * lMoveSign) /(tplCalcCostPrice.CCP_ADDED_QUANTITY + lMvtQty * lMoveSign) )
               , STM_STOCK_MOVEMENT_ID = iMovementRecord.STM_STOCK_MOVEMENT_ID
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where PTC_CALC_COSTPRICE_ID = tplCalcCostPrice.PTC_CALC_COSTPRICE_ID;
        end if;
      end loop;
    end if;
  end updateCCP;
end STM_PRC_COSTPRICE;
