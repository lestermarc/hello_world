--------------------------------------------------------
--  DDL for Package Body FAL_PRC_ALLOY_INVENTORY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_PRC_ALLOY_INVENTORY" 
is
  /**
  * Description
  *    Cette procedure va créer une position d'inventaire pour l'extraction en cours.
  *    (Test si déjà existante ou non)
  */
  function createInventoryPos(
    inFalPositionID       in FAL_POSITION.FAL_POSITION_ID%type
  , inGcoGoodID           in GCO_GOOD.GCO_GOOD_ID%type
  , inGcoAlloyID          in GCO_ALLOY.GCO_ALLOY_ID%type
  , ivCAlloyInventoryType in FAL_POSITION_INIT_QTY.C_ALLOY_INVENTORY_TYPE%type
  )
    return FAL_POSITION_INIT_QTY.FAL_POSITION_INIT_QTY_ID%type
  as
    lnPosExists            number;
    lnFalPositionInitQtyID FAL_POSITION_INIT_QTY.FAL_POSITION_INIT_QTY_ID%type;
  begin
    /* Recherche de la position */
    lnPosExists  := FAL_LIB_POSITION_INIT_QTY.positionExists(inFalPositionID => inFalPositionID
                                                           , inGcoGoodID => inGcoGoodID
                                                           , inGcoAlloyID => inGcoAlloyID
                                                           , ioFalPosInitQty => lnFalPositionInitQtyID);

    /* Si la position n'existe pas, on la crée. */
    if lnPosExists = 0 then
      FAL_PRC_POSITION_INIT_QTY.CreatePos(inFalPositionID          => inFalPositionID
                                        , inGcoGoodID              => inGcoGoodID
                                        , inGcoAlloyID             => inGcoAlloyID
                                        , ivCAlloyInventoryType    => ivCAlloyInventoryType
                                        , idFpiLastDateInvent      => null
                                        , idFpiNextDateInvent      => null
                                        , inFpiWeightInit          => 0
                                        , inFpiQtyInit             => 0
                                        , onFalPositionInitQtyID   => lnFalPositionInitQtyID
                                         );
    end if;

    return lnFalPositionInitQtyID;
  end createInventoryPos;

  /**
  * Description
  *    Cette procedure va créer une ligne d'inventaire pour l'extraction en cours.
  *    (Test si déjà existante ou non)
  */
  procedure createInventoryLine(
    inFalAlloyInventoryID in FAL_ALLOY_INVENTORY.FAL_ALLOY_INVENTORY_ID%type
  , inFalPositionID       in FAL_POSITION.FAL_POSITION_ID%type
  , inGcoGoodID           in GCO_GOOD.GCO_GOOD_ID%type
  , inGcoAlloyID          in GCO_ALLOY.GCO_ALLOY_ID%type
  , ivDicOperatorID       in FAL_LINE_INVENTORY.DIC_OPERATOR_ID%type
  , idFliDateInvent       in FAL_LINE_INVENTORY.FLI_DATE_INVENT%type
  , inFliQtyInventCalcul  in FAL_LINE_INVENTORY.FLI_QTY_INVENT_CALCUL%type
  , inFliQtyInvent        in FAL_LINE_INVENTORY.FLI_QTY_INVENT%type
  , inFliInventCalcul     in FAL_LINE_INVENTORY.FLI_INVENT_CALCUL%type
  , inFliInvent           in FAL_LINE_INVENTORY.FLI_INVENT%type
  )
  as
  begin
    -- Recherche de la ligne d'inventaire
    if FAL_LIB_LINE_INVENTORY.lineNotHandledAlreadyExists(inFalPositionID         => inFalPositionID
                                                        , inGcoGoodID             => inGcoGoodID
                                                        , inGcoAlloyID            => inGcoAlloyID
                                                        , inFalAlloyInventoryID   => inFalAlloyInventoryID
                                                        , inFalLineInventoryID    => null
                                                         ) = 0 then
      -- Création de la ligne d'inventaire
      FAL_PRC_LINE_INVENTORY.CreateLine(inFalAlloyInventoryID   => inFalAlloyInventoryID
                                      , inFalPositionID         => inFalPositionID
                                      , inGcoGoodID             => inGcoGoodID
                                      , inGcoAlloyID            => inGcoAlloyID
                                      , inFliSelect             => 1
                                      , ivDicOperatorID         => ivDicOperatorID
                                      , idFliDateInvent         => idFliDateInvent
                                      , ivCLineStatus           => 1
                                      , inFliQtyInventCalcul    => inFliQtyInventCalcul
                                      , inFliQtyInvent          => inFliQtyInvent
                                      , inFliInventCalcul       => inFliInventCalcul
                                      , inFliInvent             => inFliInvent
                                       );
    end if;
  end createInventoryLine;

  /**
  * Description
  *    Cette procedure va procéder à l'extraction des lignes d'inventaire de MP
  */
  procedure extractLines(
    inFalAlloyInventoryID     in FAL_ALLOY_INVENTORY.FAL_ALLOY_INVENTORY_ID%type
  , inFalPositionID           in FAL_POSITION.FAL_POSITION_ID%type
  , inGcoGoodID               in GCO_GOOD.GCO_GOOD_ID%type
  , inGcoAlloyID              in GCO_ALLOY.GCO_ALLOY_ID%type
  , ivDicFreePosition1ID      in DIC_FREE_POSITION1.DIC_FREE_POSITION1_ID%type
  , ivDicFreePosition2ID      in DIC_FREE_POSITION2.DIC_FREE_POSITION2_ID%type
  , ivDicFreePosition3ID      in DIC_FREE_POSITION3.DIC_FREE_POSITION3_ID%type
  , ivDicFreePosition4ID      in DIC_FREE_POSITION4.DIC_FREE_POSITION4_ID%type
  , idFpiFromNextDateInvent   in FAL_POSITION_INIT_QTY.FPI_NEXT_DATE_INVENT%type
  , idFpiToNextDateInvent     in FAL_POSITION_INIT_QTY.FPI_NEXT_DATE_INVENT%type
  , ivDicOperatorID           in DIC_OPERATOR.DIC_OPERATOR_ID%type
  , idFaiDateExtract          in FAL_ALLOY_INVENTORY.FAI_DATE_EXTACT%type
  , ivCAlloyInventoryType     in FAL_POSITION_INIT_QTY.C_ALLOY_INVENTORY_TYPE%type
  , ibIsInitialInventory      in boolean
  , ibIsInitFromStockPosition in boolean
  , ibIsInitWeightFromPM      in boolean
  )
  as
    lvCfgFalInitInventoryAlloy PCS.PC_CBASE.CBACVALUE%type;
    lnFliQtyInventCalcul       FAL_LINE_INVENTORY.FLI_QTY_INVENT_CALCUL%type;
    lnFliQtyInvent             FAL_LINE_INVENTORY.FLI_QTY_INVENT%type;
    lnFliInventCalcul          FAL_LINE_INVENTORY.FLI_INVENT_CALCUL%type;
    lnFliInvent                FAL_LINE_INVENTORY.FLI_INVENT%type;
    lnFalPositionInitQtyID     FAL_POSITION_INIT_QTY.FAL_POSITION_INIT_QTY_ID%type;
    lnResult                   number;

    cursor lcurGcoAlloy(inGcoGoodID number)
    is
      select gal.GCO_ALLOY_ID
           , gpm.GPM_WEIGHT_DELIVER
        from GCO_ALLOY gal
           , GCO_PRECIOUS_MAT gpm
       where gpm.gco_alloy_id = gal.gco_alloy_id
         and gpm.gco_good_id = inGcoGoodID
         and (   nvl(inGcoAlloyID, 0) = 0
              or gal.GCO_ALLOY_ID = inGcoAlloyID);

    cursor lcurFalPositionInitQty(
      inFalPositionID in FAL_POSITION.FAL_POSITION_ID%type
    , inGcoGoodID     in GCO_GOOD.GCO_GOOD_ID%type
    , inGcoAlloyID    in GCO_ALLOY.GCO_ALLOY_ID%type
    )
    is
      select FAL_POSITION_INIT_QTY_ID
        from FAL_POSITION_INIT_QTY
       where FAL_POSITION_ID = inFalPositionID   -- ltplFalPositions.FAL_POSITION_ID
         and GCO_ALLOY_ID = inGcoAlloyID   -- ltplGcoAlloy.GCO_ALLOY_ID
         and nvl(GCO_GOOD_ID, 0) = nvl(inGcoGoodID, 0)   -- ltplGcoGood.GCO_GOOD_ID
         and (   FPI_NEXT_DATE_INVENT is null
              or (     (   idFpiFromNextDateInvent is null
                        or FPI_NEXT_DATE_INVENT >= idFpiFromNextDateInvent)
                  and (   idFpiToNextDateInvent is null
                       or FPI_NEXT_DATE_INVENT <= idFpiToNextDateInvent)
                 )
             );
  begin
    /* Récupération valeur config */
    lvCfgFalInitInventoryAlloy  := pcs.pc_config.GetConfig('FAL_INIT_INVENTORY_ALLOY');

    /* Récupération des postes sélectionnés (si param = null ou 0, tous) */
    for ltplFalPositions in (select distinct FAL_POSITION_ID
                                           , STM_STOCK_ID
                                        from FAL_POSITION
                                       where (   nvl(inFalPositionID, 0) = 0
                                              or FAL_POSITION_ID = inFalPositionID)
                                         and (   nvl(ivDicFreePosition1ID, '*') = '*'
                                              or DIC_FREE_POSITION1_ID = ivDicFreePosition1ID)
                                         and (   nvl(ivDicFreePosition2ID, '*') = '*'
                                              or DIC_FREE_POSITION2_ID = ivDicFreePosition2ID)
                                         and (   nvl(ivDicFreePosition3ID, '*') = '*'
                                              or DIC_FREE_POSITION3_ID = ivDicFreePosition3ID)
                                         and (   nvl(ivDicFreePosition4ID, '*') = '*'
                                              or DIC_FREE_POSITION4_ID = ivDicFreePosition4ID) ) loop

      /* Supression des position d'inventaire d'un autre type */
      FAL_PRC_POSITION.deletePostionByInventoryType(inFalPositionID => ltplFalPositions.FAL_POSITION_ID, ivCAlloyInventoryType => ivCAlloyInventoryType);

      /* Si position de stock logique et inventaire de type 2 (Poste/Bien/Alliage) */
      if     (ltplFalPositions.STM_STOCK_ID is not null)
         and (ivCAlloyInventoryType = '2') then
        /* si inventaire inital */
        if ibIsInitialInventory then
          /* Si initialisation depuis les positions de stock */
          if ibIsInitFromStockPosition then
            for ltplGcoGood in (select   sum(spo.SPO_STOCK_QUANTITY) SPO_STOCK_QUANTITY
                                       , spo.GCO_GOOD_ID
                                    from STM_STOCK_POSITION spo
                                       , GCO_GOOD goo
                                   where goo.GCO_GOOD_ID = spo.GCO_GOOD_ID
                                     and goo.GOO_PRECIOUS_MAT = 1
                                     and exists(select gpm.GCO_GOOD_ID
                                                  from GCO_PRECIOUS_MAT gpm
                                                 where gpm.GCO_GOOD_ID = goo.GCO_GOOD_ID)
                                     and (   nvl(inGcoGoodID, 0) = 0
                                          or goo.GCO_GOOD_ID = inGcoGoodID)
                                     and spo.STM_STOCK_ID = ltplFalPositions.STM_STOCK_ID
                                group by spo.GCO_GOOD_ID) loop
              /* Récupération des alliages du bien correspondants à l'alliage sélectionné (si sélectionné) */
              for ltplGcoAlloy in lcurGcoAlloy(inGcoGoodID => ltplGcoGood.GCO_GOOD_ID) loop
                lnFalPositionInitQtyID  :=
                  createInventoryPos(inFalPositionID         => ltplFalPositions.FAL_POSITION_ID
                                   , inGcoGoodID             => ltplGcoGood.GCO_GOOD_ID
                                   , inGcoAlloyID            => ltplGcoAlloy.GCO_ALLOY_ID
                                   , ivCAlloyInventoryType   => ivCAlloyInventoryType
                                    );

                /* Si la position pour le poste / bien  / alliage répond au critère de date de l'extraction */
                for lptlPositionInitQty in lcurFalPositionInitQty(inFalPositionID   => ltplFalPositions.FAL_POSITION_ID
                                                                , inGcoGoodID       => ltplGcoGood.GCO_GOOD_ID
                                                                , inGcoAlloyID      => ltplGcoAlloy.GCO_ALLOY_ID
                                                                 ) loop

                  /* Somme des quantités effectives de position du stock logique pour le produit */
                  lnFliInventCalcul    := 0;
                  lnFliQtyInventCalcul := 0;
                  if ibIsInitWeightFromPM then
                    lnFliQtyInvent  := ltplGcoGood.SPO_STOCK_QUANTITY;
                    lnFliInvent     := ltplGcoAlloy.GPM_WEIGHT_DELIVER * lnFliQtyInvent;
                  else
                    lnFliQtyInvent  := 0;
                    lnFliInvent     := 0;
                  end if;

                  /* Création de la ligne d'inventaire */
                  createInventoryLine(inFalAlloyInventoryID   => inFalAlloyInventoryID
                                    , inFalPositionID         => ltplFalPositions.FAL_POSITION_ID
                                    , inGcoGoodID             => ltplGcoGood.GCO_GOOD_ID
                                    , inGcoAlloyID            => ltplGcoAlloy.GCO_ALLOY_ID
                                    , ivDicOperatorID         => ivDicOperatorID
                                    , idFliDateInvent         => idFaiDateExtract
                                    , inFliQtyInventCalcul    => lnFliQtyInventCalcul
                                    , inFliQtyInvent          => lnFliQtyInvent
                                    , inFliInventCalcul       => lnFliInventCalcul
                                    , inFliInvent             => lnFliInvent
                                     );
                end loop;
              end loop;
            end loop;
          else      /* initialisation depuis les stock logiques */
                 /* Récupération des biens avec matière précieuse et dont le stock logique
                    correspond à celui du poste et correspondant au bien sélectionné (si sélectionné) */
            for ltplGcoGood in (select goo.GCO_GOOD_ID
                                  from GCO_GOOD goo
                                     , GCO_PRODUCT pdt
                                 where goo.GCO_GOOD_ID = pdt.GCO_GOOD_ID
                                   and goo.GOO_PRECIOUS_MAT = 1
                                   and exists(select gpm.GCO_GOOD_ID
                                                from GCO_PRECIOUS_MAT gpm
                                               where gpm.GCO_GOOD_ID = goo.GCO_GOOD_ID)
                                   and (   nvl(inGcoGoodID, 0) = 0
                                        or goo.GCO_GOOD_ID = inGcoGoodID)
                                   and pdt.STM_STOCK_ID = ltplFalPositions.STM_STOCK_ID) loop
              /* Récupération des alliages du bien correspondants à l'alliage sélectionné (si sélectionné) */
              for ltplGcoAlloy in lcurGcoAlloy(inGcoGoodID => ltplGcoGood.GCO_GOOD_ID) loop
                /* Création de la position d'inventaire */
                lnFalPositionInitQtyID  :=
                  createInventoryPos(inFalPositionID         => ltplFalPositions.FAL_POSITION_ID
                                   , inGcoGoodID             => ltplGcoGood.GCO_GOOD_ID
                                   , inGcoAlloyID            => ltplGcoAlloy.GCO_ALLOY_ID
                                   , ivCAlloyInventoryType   => ivCAlloyInventoryType
                                    );

                /* Si la position pour le poste / bien  / alliage répond au critère de date de l'extraction */
                for lptlPositionInitQty in lcurFalPositionInitQty(inFalPositionID   => ltplFalPositions.FAL_POSITION_ID
                                                                , inGcoGoodID       => ltplGcoGood.GCO_GOOD_ID
                                                                , inGcoAlloyID      => ltplGcoAlloy.GCO_ALLOY_ID
                                                                 ) loop
                  /* Création de la ligne d'inventaire */
                  createInventoryLine(inFalAlloyInventoryID   => inFalAlloyInventoryID
                                    , inFalPositionID         => ltplFalPositions.FAL_POSITION_ID
                                    , inGcoGoodID             => ltplGcoGood.GCO_GOOD_ID
                                    , inGcoAlloyID            => ltplGcoAlloy.GCO_ALLOY_ID
                                    , ivDicOperatorID         => ivDicOperatorID
                                    , idFliDateInvent         => idFaiDateExtract
                                    , inFliQtyInventCalcul    => 0
                                    , inFliQtyInvent          => 0
                                    , inFliInventCalcul       => 0
                                    , inFliInvent             => 0
                                     );
                end loop;
              end loop;
            end loop;
          end if;
        else   /* inventaire manuel */
          -- Pour chaque bien comprenant des matières précieuses ou correspondant au bien sélectionné (si sélectionné)
          -- pour lequel il y a des pesées
          for ltplGcoGood in (select distinct goo.GCO_GOOD_ID
                                         from GCO_GOOD goo
                                        where goo.GOO_PRECIOUS_MAT = 1
                                          and exists(select 1
                                                       from FAL_WEIGH FWE
                                                      where FWE.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                                                        and (FAL_LIB_POSITION_INIT_QTY.getLastDateInvent(inFalPositionInitQtyID   => ltplFalPositions.FAL_POSITION_ID) is null
                                                            or FWE.FWE_DATE >= FAL_LIB_POSITION_INIT_QTY.getLastDateInvent(inFalPositionInitQtyID   => ltplFalPositions.FAL_POSITION_ID))
                                                        and (FAL_POSITION1_ID = ltplFalPositions.FAL_POSITION_ID or FAL_POSITION2_ID = ltplFalPositions.FAL_POSITION_ID))
                                          and exists(select gpm.GCO_GOOD_ID
                                                       from GCO_PRECIOUS_MAT gpm
                                                      where gpm.GCO_GOOD_ID = goo.GCO_GOOD_ID)
                                          and (   nvl(inGcoGoodID, 0) = 0
                                               or goo.GCO_GOOD_ID = inGcoGoodID) ) loop
            -- Récupération des alliages du bien correspondants à l'alliage sélectionné (si sélectionné)
            for ltplGcoAlloy in lcurGcoAlloy(inGcoGoodID => ltplGcoGood.GCO_GOOD_ID) loop
              -- Création de la position d'inventaire
              lnFalPositionInitQtyID  :=
                createInventoryPos(inFalPositionID         => ltplFalPositions.FAL_POSITION_ID
                                 , inGcoGoodID             => ltplGcoGood.GCO_GOOD_ID
                                 , inGcoAlloyID            => ltplGcoAlloy.GCO_ALLOY_ID
                                 , ivCAlloyInventoryType   => ivCAlloyInventoryType
                                  );

              /* Si la position pour le poste / bien  / alliage répond au critère de date de l'extraction */
              for lptlPositionInitQty in lcurFalPositionInitQty(inFalPositionID   => ltplFalPositions.FAL_POSITION_ID
                                                              , inGcoGoodID       => ltplGcoGood.GCO_GOOD_ID
                                                              , inGcoAlloyID      => ltplGcoAlloy.GCO_ALLOY_ID
                                                               ) loop
                -- Quantité calculée
                lnFliQtyInventCalcul  :=
                  FAL_LIB_POSITION_INIT_QTY.getLastInventQty(inFalPositionInitQtyID => lnFalPositionInitQtyID) +
                  FAL_I_LIB_WEIGH.getSumQtyInByPosAndDate
                                                 (inFalPositionID   => ltplFalPositions.FAL_POSITION_ID
                                                , inGcoGoodID       => ltplGcoGood.GCO_GOOD_ID
                                                , inGcoAlloyID      => ltplGcoAlloy.GCO_ALLOY_ID
                                                , idDateFrom        => FAL_LIB_POSITION_INIT_QTY.getLastDateInvent
                                                                                                               (inFalPositionInitQtyID   => lnFalPositionInitQtyID)
                                                 ) -
                  FAL_I_LIB_WEIGH.getSumQtyOutByPosAndDate
                                                 (inFalPositionID   => ltplFalPositions.FAL_POSITION_ID
                                                , inGcoGoodID       => ltplGcoGood.GCO_GOOD_ID
                                                , inGcoAlloyID      => ltplGcoAlloy.GCO_ALLOY_ID
                                                , idDateFrom        => FAL_LIB_POSITION_INIT_QTY.getLastDateInvent
                                                                                                               (inFalPositionInitQtyID   => lnFalPositionInitQtyID)
                                                 );
                -- Poids calculé
                lnFliInventCalcul     :=
                  FAL_LIB_POSITION_INIT_QTY.getLastInventWeight(inFalPositionInitQtyID => lnFalPositionInitQtyID) +
                  FAL_I_LIB_WEIGH.getSumWeighInByPosAndDate
                                                 (inFalPositionID   => ltplFalPositions.FAL_POSITION_ID
                                                , inGcoGoodID       => ltplGcoGood.GCO_GOOD_ID
                                                , inGcoAlloyID      => ltplGcoAlloy.GCO_ALLOY_ID
                                                , idDateFrom        => FAL_LIB_POSITION_INIT_QTY.getLastDateInvent
                                                                                                               (inFalPositionInitQtyID   => lnFalPositionInitQtyID)
                                                 ) -
                  FAL_I_LIB_WEIGH.getSumWeighOutByPosAndDate
                                                 (inFalPositionID   => ltplFalPositions.FAL_POSITION_ID
                                                , inGcoGoodID       => ltplGcoGood.GCO_GOOD_ID
                                                , inGcoAlloyID      => ltplGcoAlloy.GCO_ALLOY_ID
                                                , idDateFrom        => FAL_LIB_POSITION_INIT_QTY.getLastDateInvent
                                                                                                               (inFalPositionInitQtyID   => lnFalPositionInitQtyID)
                                                 );

                /* Quantités et poids inventaires */
                if lvCfgFalInitInventoryAlloy = 1 then
                  lnFliQtyInvent  := lnFliQtyInventCalcul;
                  lnFliInvent     := lnFliInventCalcul;
                else
                  lnFliQtyInvent  := 0;
                  lnFliInvent     := 0;
                end if;

                -- Création de la ligne d'inventaire
                createInventoryLine(inFalAlloyInventoryID   => inFalAlloyInventoryID
                                  , inFalPositionID         => ltplFalPositions.FAL_POSITION_ID
                                  , inGcoGoodID             => ltplGcoGood.GCO_GOOD_ID
                                  , inGcoAlloyID            => ltplGcoAlloy.GCO_ALLOY_ID
                                  , ivDicOperatorID         => ivDicOperatorID
                                  , idFliDateInvent         => idFaiDateExtract
                                  , inFliQtyInventCalcul    => lnFliQtyInventCalcul
                                  , inFliQtyInvent          => lnFliQtyInvent
                                  , inFliInventCalcul       => lnFliInventCalcul
                                  , inFliInvent             => lnFliInvent
                                   );
              end loop;
            end loop;
          end loop;
        end if;
      else   /* Inventaire type Poste/Alliage ou Poste pas de type stock */
        for ltplGcoAlloy in (select distinct GAL.GCO_ALLOY_ID
                                        from GCO_ALLOY GAL
                                       where (   nvl(inGcoAlloyID, 0) = 0
                                              or GAL.GCO_ALLOY_ID = inGcoAlloyID) ) loop
         /* Vérification L'existance ou non  de la position d''inventaire (FAL_POSITION_INIT_QTY)
         pour L'alliage et le poste , Et création si inexistante.*/
          lnFalPositionInitQtyID  :=
            createInventoryPos(inFalPositionID         => ltplFalPositions.FAL_POSITION_ID
                             , inGcoGoodID             => null
                             , inGcoAlloyID            => ltplGcoAlloy.GCO_ALLOY_ID
                             , ivCAlloyInventoryType   => ivCAlloyInventoryType
                              );

          /* Si la position pour le poste/alliage répond au critère de date de l'extraction */
          for lptlPositionInitQty in lcurFalPositionInitQty(inFalPositionID   => ltplFalPositions.FAL_POSITION_ID
                                                          , inGcoGoodID       => null
                                                          , inGcoAlloyID      => ltplGcoAlloy.GCO_ALLOY_ID
                                                           ) loop
            /* Poids Calculé = Poids dernier inventaire + Somme pesées entrées - Somme des pesées sorties. */
            lnFliInventCalcul  :=
              nvl(FAL_LIB_POSITION_INIT_QTY.getLastInventWeight(inFalPositionInitQtyID => lnFalPositionInitQtyID), 0) +
              FAL_I_LIB_WEIGH.getSumWeighInByPosAndDate
                                                 (inFalPositionID   => ltplFalPositions.FAL_POSITION_ID
                                                , inGcoGoodID       => null
                                                , inGcoAlloyID      => ltplGcoAlloy.GCO_ALLOY_ID
                                                , idDateFrom        => FAL_LIB_POSITION_INIT_QTY.getLastDateInvent
                                                                                                               (inFalPositionInitQtyID   => lnFalPositionInitQtyID)
                                                 ) -
              FAL_I_LIB_WEIGH.getSumWeighOutByPosAndDate
                                                 (inFalPositionID   => ltplFalPositions.FAL_POSITION_ID
                                                , inGcoGoodID       => null
                                                , inGcoAlloyID      => ltplGcoAlloy.GCO_ALLOY_ID
                                                , idDateFrom        => FAL_LIB_POSITION_INIT_QTY.getLastDateInvent
                                                                                                               (inFalPositionInitQtyID   => lnFalPositionInitQtyID)
                                                 );

            /* Poids inventaire dépendent de la config FAL_INIT_INVENTORY_ALLOY).*/
            if lvCfgFalInitInventoryAlloy = 1 then
              lnFliInvent  := lnFliInventCalcul;
            else
              lnFliInvent  := 0;
            end if;

            /* Création de la ligne d'inventaire */
            createInventoryLine(inFalAlloyInventoryID   => inFalAlloyInventoryID
                              , inFalPositionID         => ltplFalPositions.FAL_POSITION_ID
                              , inGcoGoodID             => null
                              , inGcoAlloyID            => ltplGcoAlloy.GCO_ALLOY_ID
                              , ivDicOperatorID         => ivDicOperatorID
                              , idFliDateInvent         => idFaiDateExtract
                              , inFliQtyInventCalcul    => null
                              , inFliQtyInvent          => null
                              , inFliInventCalcul       => lnFliInventCalcul
                              , inFliInvent             => lnFliInvent
                               );
          end loop;
        end loop;
--         /* Appel de l'extraction d'inventaire de type 1 (par poste / alliage) */
--         FAL_POSITION_FUNCTIONS.EXTRACT_INVENTORY(PrmFAL_ALLOY_INVENTORY_ID     => inFalAlloyInventoryID
--                                                , PrmFAL_POSITION_ID            => inFalPositionID
--                                                , PrmGCO_ALLOY_ID               => inGcoAlloyID
--                                                , PrmDIC_FREE_POSITION1_ID      => ivDicFreePosition1ID
--                                                , PrmDIC_FREE_POSITION2_ID      => ivDicFreePosition2ID
--                                                , PrmDIC_FREE_POSITION3_ID      => ivDicFreePosition3ID
--                                                , PrmDIC_FREE_POSITION4_ID      => ivDicFreePosition4ID
--                                                , PrmFromFPI_NEXT_DATE_INVENT   => idFpiFromNextDateInvent
--                                                , PrmToFPI_NEXT_DATE_INVENT     => idFpiToNextDateInvent
--                                                , PrmDIC_OPERATOR_ID            => ivDicOperatorID
--                                                , PrmFAI_DATE_EXTRACT           => idFaiDateExtract
--                                                , aResultat                     => lnResult
--                                                 );
      end if;
    end loop;
  end extractLines;

  /**
  * Description
  *    Cette procedure va clore l'inventaire dont la clef primaire est transmise
  *    en paramètre (toutes ses lignes et lui-même sont mise en statut "traité)
  */
  procedure closeAlloyInventory(inFalAlloyInventoryID in FAL_ALLOY_INVENTORY.FAL_ALLOY_INVENTORY_ID%type)
  as
  begin
    /* Pour chaque ligne de l'inventaire */
    for ltplInventoryLine in (select FAL_LINE_INVENTORY_ID
                                from FAL_LINE_INVENTORY
                               where FAL_ALLOY_INVENTORY_ID = inFalAlloyInventoryID
                                 and C_LINE_STATUS <> '3') loop
      FAL_PRC_LINE_INVENTORY.closeInventoryLineStatus(inFalLineInventoryID => ltplInventoryLine.FAL_LINE_INVENTORY_ID);
    end loop;

    /* Nouveau statut = "traité" */
    updateInventoryStatus(inFalAlloyInventoryID => inFalAlloyInventoryID, ivCInventoryStatus => '05');
  end closeAlloyInventory;

  /**
  * Description
  *    Cette procedure va procéder au traitement de l'inventaire transmis en paramètre.
  *    Si une ligne est transmise en paramètre, on ne traitera que celle-ci.
  */
  procedure processAlloyInventory(
    inFalAlloyInventoryID in FAL_ALLOY_INVENTORY.FAL_ALLOY_INVENTORY_ID%type
  , inFalLineInventoryID  in FAL_LINE_INVENTORY.FAL_LINE_INVENTORY_ID%type default null
  )
  as
    lnFalPositionInitQtyID FAL_POSITION_INIT_QTY.FAL_POSITION_INIT_QTY_ID%type;
    lnFaiCommentaire       FAL_ALLOY_INVENTORY.FAI_COMMENTAIRE%type;
    lnExists               number;
  begin
    /* Pour chaque ligne d'inventaire sélectionnée et non traitée */
    for ltplInventoryLine in (select fli.FAL_LINE_INVENTORY_ID
                                   , fli.FAL_POSITION_ID
                                   , fli.GCO_GOOD_ID
                                   , fli.GCO_ALLOY_ID
                                   , fli.DIC_OPERATOR_ID
                                   , fli.FLI_DATE_INVENT
                                   , fli.FLI_INVENT
                                   , fli.FLI_CORRECT
                                   , fli.FLI_QTY_INVENT
                                   , fli.FLI_QTY_CORRECT
                                   , fai.FAI_COMMENTAIRE
                                from FAL_LINE_INVENTORY fli
                                   , FAL_ALLOY_INVENTORY fai
                               where fai.FAL_ALLOY_INVENTORY_ID = fli.FAL_ALLOY_INVENTORY_ID
                                 and fli.FAL_ALLOY_INVENTORY_ID = inFalAlloyInventoryID
                                 and (   nvl(inFalLineInventoryID, 0) = 0
                                      or fli.FAL_LINE_INVENTORY_ID = inFalLineInventoryID)
                                 and fli.C_LINE_STATUS <> '3'
                                 and fli.FLI_SELECT = 1) loop

      /* Génération pesée de correction de quantité si correction <> 0 */
      if (ltplInventoryLine.FLI_QTY_CORRECT <> 0) then
        FAL_PRC_WEIGH.createQtyCorrWeigh4AlloyInvent(inFalPositionID    => ltplInventoryLine.FAL_POSITION_ID
                                                   , inGcoGoodID        => ltplInventoryLine.GCO_GOOD_ID
                                                   , inGcoAlloyID       => ltplInventoryLine.GCO_ALLOY_ID
                                                   , inDicOperatorID    => ltplInventoryLine.DIC_OPERATOR_ID
                                                   , idFliDateInvent    => ltplInventoryLine.FLI_DATE_INVENT
                                                   , inFliQtyCorrect    => ltplInventoryLine.FLI_QTY_CORRECT
                                                   , ivFaiCommentaire   => ltplInventoryLine.FAI_COMMENTAIRE
                                                    );
      end if;

      /* Génération pesée de correction de poids si correction <> 0 */
      if (ltplInventoryLine.FLI_CORRECT <> 0) then
        FAL_PRC_WEIGH.createCorrWeigh4AlloyInvent(inFalPositionID    => ltplInventoryLine.FAL_POSITION_ID
                                                , inGcoGoodID        => ltplInventoryLine.GCO_GOOD_ID
                                                , inGcoAlloyID       => ltplInventoryLine.GCO_ALLOY_ID
                                                , inDicOperatorID    => ltplInventoryLine.DIC_OPERATOR_ID
                                                , idFliDateInvent    => ltplInventoryLine.FLI_DATE_INVENT
                                                , inFliCorrect       => ltplInventoryLine.FLI_CORRECT
                                                , ivFaiCommentaire   => ltplInventoryLine.FAI_COMMENTAIRE
                                                 );
      end if;

      /* Récupération ID position d'inventaire */
      lnExists := FAL_LIB_POSITION_INIT_QTY.getPositionInitQtyID(inFalPositionID          => ltplInventoryLine.FAL_POSITION_ID
                                        , inGcoGoodID              => ltplInventoryLine.GCO_GOOD_ID
                                        , inGcoAlloyID             => ltplInventoryLine.GCO_ALLOY_ID
                                         );
      /* Mise à jour position d'inventaire */
      FAL_PRC_POSITION_INIT_QTY.updatePosByInventoryProcess(inFalPositionInitQtyID   => lnExists
                                                          , idFliDateInvent          => ltplInventoryLine.FLI_DATE_INVENT
                                                          , inFpiWeightInit          => ltplInventoryLine.FLI_INVENT
                                                          , inFpiQtyInit             => ltplInventoryLine.FLI_QTY_INVENT
                                                           );
      /* Mise à jour du statut de la ligne */
      FAL_PRC_LINE_INVENTORY.updateLineInventoryStatus(inFalLineInventoryID => ltplInventoryLine.FAL_LINE_INVENTORY_ID, ivCLineStatus => '3');
    end loop;

    /* S'il ne reste plus de lignes non traitées */
    if FAL_LIB_LINE_INVENTORY.hasLinesNotHandled(inFalAlloyInventoryID => inFalAlloyInventoryID) = 0 then
      /* Mise à jour du statut de l'inventaire à "traité" */
      updateInventoryStatus(inFalAlloyInventoryID => inFalAlloyInventoryID, ivCInventoryStatus => '05');
    end if;
  end processAlloyInventory;

  /**
  * Description
  *    Cette procedure va mettre à jour le statut de l'inventaire dont la clef primaire
  *    est transmise en paramètre avec le statut reçu en paramètre.
  */
  procedure updateInventoryStatus(
    inFalAlloyInventoryID in FAL_ALLOY_INVENTORY.FAL_ALLOY_INVENTORY_ID%type
  , ivCInventoryStatus    in FAL_ALLOY_INVENTORY.C_INVENTORY_STATUS%type
  )
  as
    ltCRUD_FalAlloyInventory FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_FAL_ENTITY.gcFalAlloyInventory, ltCRUD_FalAlloyInventory, false, inFalAlloyInventoryID);
    FWK_I_MGT_ENTITY_DATA.setcolumn(ltCRUD_FalAlloyInventory, 'C_INVENTORY_STATUS', ivCInventoryStatus);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_FalAlloyInventory);
    FWK_I_MGT_ENTITY.Release(ltCRUD_FalAlloyInventory);
  end updateInventoryStatus;
end FAL_PRC_ALLOY_INVENTORY;
