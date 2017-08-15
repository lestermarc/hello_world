--------------------------------------------------------
--  DDL for Package Body FAL_COMPONENT_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "FAL_COMPONENT_FUNCTIONS" 
is
  /**
  * Procedure : UpdateFactoryEntries
  * Description : Mise à jour des entrées ateliers lors des mouvements de type sortie d'atelier
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param
  */
  procedure UpdateFactoryEntries(aFCL_SESSION FAL_COMPONENT_LINK.FCL_SESSION%type)
  is
    cursor CUR_FAL_COMPONENT_LINK
    is
      select (FCL_HOLD_QTY + FCL_TRASH_QTY + FCL_RETURN_QTY) OUTPUT_QTY
           , FAL_FACTORY_IN_ID
        from FAL_COMPONENT_LINK
       where FCL_SESSION = aFCL_SESSION
         and (FCL_HOLD_QTY + FCL_TRASH_QTY + FCL_RETURN_QTY) > 0
         and (FAL_FACTORY_IN_ID is not null);

    CurFalComponentLink CUR_FAL_COMPONENT_LINK%rowtype;
  begin
    for CurFalComponentLink in CUR_FAL_COMPONENT_LINK loop
      update FAL_FACTORY_IN
         set IN_OUT_QTE = IN_OUT_QTE + CurFalComponentLink.OUTPUT_QTY
           , IN_BALANCE = IN_IN_QTE -(IN_OUT_QTE + CurFalComponentLink.OUTPUT_QTY)
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GETUSERINI
       where FAL_FACTORY_IN_ID = CurFalComponentLink.FAL_FACTORY_IN_ID;
    end loop;
  end;

  /**
  * procédure CreateCompoLinkFactInOnRecept
  * Description : Création des liens composant sur les entrée atelier
  *    et les composants temporaires qui viennent d'être sortie du stock
  *    à la réception. Ceci ne doit pas être fait dans une transaction
  *    autonome car l'entrée atelier correspondante n'est pas commitée et
  *    doit pouvoir être rollbackée.
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param   aSessionId             ID unique de Session Oracle
  * @param   aFalLotMatLinkTmpId    ID du composant temporaire de lot
  * @param   aFalfactoryInId        ID de l'entrée atelier
  * @param   aHoldQty               Qté Saisie
  */
  procedure CreateCompoLinkFactInOnRecept(
    aSessionId          FAL_COMPONENT_LINK.FCL_SESSION%type
  , aFalLotMatLinkTmpId FAL_LOT_MAT_LINK_TMP.FAL_LOT_MAT_LINK_TMP_ID%type
  , aFalFactoryInId     FAL_FACTORY_IN.FAL_FACTORY_IN_ID%type
  , aHoldQty            FAL_COMPONENT_LINK.FCL_HOLD_QTY%type
  )
  is
  begin
    insert into FAL_COMPONENT_LINK
                (FAL_COMPONENT_LINK_ID
               , FCL_SESSION
               , FAL_LOT_MAT_LINK_TMP_ID
               , FAL_LOT_ID
               , GCO_GOOD_ID
               , FCL_HOLD_QTY
               , GCO_CHARACTERIZATION1_ID
               , GCO_CHARACTERIZATION2_ID
               , GCO_CHARACTERIZATION3_ID
               , GCO_CHARACTERIZATION4_ID
               , GCO_CHARACTERIZATION5_ID
               , FCL_CHARACTERIZATION_VALUE_1
               , FCL_CHARACTERIZATION_VALUE_2
               , FCL_CHARACTERIZATION_VALUE_3
               , FCL_CHARACTERIZATION_VALUE_4
               , FCL_CHARACTERIZATION_VALUE_5
               , STM_STOCK_ID
               , STM_LOCATION_ID
               , FAL_FACTORY_IN_ID
               , FCL_SELECTED
               , A_DATECRE
               , A_IDCRE
                )
      select GetNewId
           , aSessionId
           , aFalLotMatLinkTmpId
           , FLML.FAL_LOT_ID
           , FLML.GCO_GOOD_ID
           , aHoldQty
           , FIN.GCO_CHARACTERIZATION_ID
           , FIN.GCO_GCO_CHARACTERIZATION_ID
           , FIN.GCO2_GCO_CHARACTERIZATION_ID
           , FIN.GCO3_GCO_CHARACTERIZATION_ID
           , FIN.GCO4_GCO_CHARACTERIZATION_ID
           , FIN.IN_CHARACTERIZATION_VALUE_1
           , FIN.IN_CHARACTERIZATION_VALUE_2
           , FIN.IN_CHARACTERIZATION_VALUE_3
           , FIN.IN_CHARACTERIZATION_VALUE_4
           , FIN.IN_CHARACTERIZATION_VALUE_5
           , LOC.STM_STOCK_ID
           , FIN.STM_LOCATION_ID
           , FIN.FAL_FACTORY_IN_ID
           , 0   -- FCL_SELECTED
           , sysdate
           , PCS.PC_I_LIB_SESSION.GetUserIni
        from FAL_LOT_MAT_LINK_TMP FLML
           , FAL_FACTORY_IN FIN
           , STM_LOCATION LOC
       where FLML.FAL_LOT_MAT_LINK_TMP_ID = aFalLotMatLinkTmpId
         and FIN.FAL_FACTORY_IN_ID = aFalFactoryInId
         and FIN.STM_LOCATION_ID = LOC.STM_LOCATION_ID;
  end;

  /**
  * Description
  *   Création des entrées et sorties atelier pour un composant de lot de fabrication.
  */
  procedure CreateFactoryMovement(
    aFAL_LOT_ID               in     number
  , aDOC_DOCUMENT_ID          in     number default null
  , aMATERIAL_LINK_ID         in     number
  , aGCO_GOOD_ID              in     number
  , aSTM_STOCK_POSITION_ID    in     number
  , aSTM_STOCK_ID             in     number
  , aSTM_LOCATION_ID          in     number
  , aOUT_QUANTITY             in     number
  , aLOT_REFCOMPL             in     varchar2
  , aLOM_PRICE                in     number
  , aPreparedStockMovements   in out FAL_STOCK_MOVEMENT_FUNCTIONS.TPreparedStockMovements
  , aFAL_COMPONENT_LINK_ID    in     number default null
  , aOUT_DATE                 in     date
  , aMvtKind                  in     integer
  , aGCO_CHARACTERIZATION1_ID in     number default null
  , aGCO_CHARACTERIZATION2_ID in     number default null
  , aGCO_CHARACTERIZATION3_ID in     number default null
  , aGCO_CHARACTERIZATION4_ID in     number default null
  , aGCO_CHARACTERIZATION5_ID in     number default null
  , aCHARACT_VALUE1           in     varchar2 default null
  , aCHARACT_VALUE2           in     varchar2 default null
  , aCHARACT_VALUE3           in     varchar2 default null
  , aCHARACT_VALUE4           in     varchar2 default null
  , aCHARACT_VALUE5           in     varchar2 default null
  , aC_IN_ORIGINE             in     varchar2 default null
  , aC_OUT_ORIGINE            in     varchar2 default null
  , aC_OUT_TYPE               in     varchar2 default null
  , aFAL_NETWORK_LINK_ID      in     number default null
  , aContext                  in     integer default 0
  , aDIC_COMPONENT_MVT_ID     in     varchar2 default null
  , aLOM_MVT_COMMENT          in     varchar2 default null
  , aFAL_LOT_MAT_LINK_TMP_ID  in     number default null
  , aFactoryInOriginId        in     number default null
  , aSessionId                in     varchar2 default null
  )
  is
    aFullTracability    integer;
    aFAL_FACTORY_OUT_ID integer;
    aFAL_FACTORY_IN_ID  integer;
  begin
    aFAL_FACTORY_OUT_ID  := null;
    aFAL_FACTORY_IN_ID   := null;

    if FAL_TOOLS.IsFullTracability(aGCO_GOOD_ID) then
      aFullTracability  := 1;
    else
      aFullTracability  := 0;
    end if;

    -- Mouvement d'entrée en atelier
    if (aMvtKind = FAL_STOCK_MOVEMENT_FUNCTIONS.mktSortieStockVersAtelier) then
      aFAL_FACTORY_IN_ID  := GetNewId;

      insert into FAL_FACTORY_IN
                  (FAL_FACTORY_IN_ID
                 , FAL_LOT_ID
                 , DOC_DOCUMENT_ID
                 , IN_LOT_REFCOMPL
                 , FAL_LOT_MATERIAL_LINK_ID
                 , IN_IN_QTE
                 , IN_OUT_QTE
                 , IN_BALANCE
                 , GCO_GOOD_ID
                 , IN_FULL_TRACABILITY
                 , STM_LOCATION_ID
                 , STM_STOCK_POSITION_ID
                 , IN_PRICE
                 , C_IN_ORIGINE
                 , GCO_CHARACTERIZATION_ID
                 , GCO_GCO_CHARACTERIZATION_ID
                 , GCO2_GCO_CHARACTERIZATION_ID
                 , GCO3_GCO_CHARACTERIZATION_ID
                 , GCO4_GCO_CHARACTERIZATION_ID
                 , IN_CHARACTERIZATION_VALUE_1
                 , IN_CHARACTERIZATION_VALUE_2
                 , IN_CHARACTERIZATION_VALUE_3
                 , IN_CHARACTERIZATION_VALUE_4
                 , IN_CHARACTERIZATION_VALUE_5
                 , IN_DATE
                 , DIC_COMPONENT_MVT_ID
                 , IN_COMMENT
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (aFAL_FACTORY_IN_ID
                 , aFAL_LOT_ID
                 , aDOC_DOCUMENT_ID
                 , aLOT_REFCOMPL
                 , aMATERIAL_LINK_ID
                 , aOUT_QUANTITY
                 , 0
                 , aOUT_QUANTITY
                 , aGCO_GOOD_ID
                 , aFullTracability
                 , aSTM_LOCATION_ID
                 , aSTM_STOCK_POSITION_ID
                 , aLOM_PRICE
                 , aC_IN_ORIGINE
                 , aGCO_CHARACTERIZATION1_ID
                 , aGCO_CHARACTERIZATION2_ID
                 , aGCO_CHARACTERIZATION3_ID
                 , aGCO_CHARACTERIZATION4_ID
                 , aGCO_CHARACTERIZATION5_ID
                 , aCHARACT_VALUE1
                 , aCHARACT_VALUE2
                 , aCHARACT_VALUE3
                 , aCHARACT_VALUE4
                 , aCHARACT_VALUE5
                 , nvl(aOUT_DATE, sysdate)
                 , aDIC_COMPONENT_MVT_ID
                 , aLOM_MVT_COMMENT
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );

      -- En réception, on reporte le lien entre le composant temporaire et l'entrée atelier
      -- (la suppression du lien sur le stock est supprimé juste après, lors de la création
      -- des liens composants
      if     aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt
         and nvl(aFAL_LOT_MAT_LINK_TMP_ID, 0) <> 0 then
        CreateCompoLinkFactInOnRecept(aSessionId            => aSessionId
                                    , aFalLotMatLinkTmpId   => aFAL_LOT_MAT_LINK_TMP_ID
                                    , aFalFactoryInId       => aFAL_FACTORY_IN_ID
                                    , aHoldQty              => aOUT_QUANTITY
                                     );
      end if;
    -- Mouvement de sortie de l'atelier
    elsif    aMvtKind = FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersDechet
          or aMvtKind = FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersStock
          or aMvtKind = FAL_STOCK_MOVEMENT_FUNCTIONS.mktComposantConsomme
          or aMvtKind = FAL_STOCK_MOVEMENT_FUNCTIONS.mktReceptionProduitDerive
          or aMvtKind = FAL_STOCK_MOVEMENT_FUNCTIONS.mktReceptionProduitTermine
          or aMvtKind = FAL_STOCK_MOVEMENT_FUNCTIONS.mktReceptionRebut
          or aMvtKind = FAL_STOCK_MOVEMENT_FUNCTIONS.mktReceptionProduitDerive then
      aFAL_FACTORY_OUT_ID  := GetNewId;

      insert into FAL_FACTORY_OUT
                  (FAL_FACTORY_OUT_ID
                 , FAL_LOT_ID
                 , OUT_LOT_REFCOMPL
                 , GCO_GOOD_ID
                 , OUT_QTE
                 , GCO_CHARACTERIZATION1_ID
                 , GCO_CHARACTERIZATION2_ID
                 , GCO_CHARACTERIZATION3_ID
                 , GCO_CHARACTERIZATION4_ID
                 , GCO_CHARACTERIZATION5_ID
                 , OUT_CHARACTERIZATION_VALUE_1
                 , OUT_CHARACTERIZATION_VALUE_2
                 , OUT_CHARACTERIZATION_VALUE_3
                 , OUT_CHARACTERIZATION_VALUE_4
                 , OUT_CHARACTERIZATION_VALUE_5
                 , STM_LOCATION_ID
                 , C_OUT_TYPE
                 , C_OUT_ORIGINE
                 , OUT_DATE
                 , OUT_PRICE
                 , DIC_COMPONENT_MVT_ID
                 , OUT_COMMENT
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (aFAL_FACTORY_OUT_ID
                 , aFAL_LOT_ID
                 , aLOT_REFCOMPL
                 , aGCO_GOOD_ID
                 , aOUT_QUANTITY
                 , aGCO_CHARACTERIZATION1_ID
                 , aGCO_CHARACTERIZATION2_ID
                 , aGCO_CHARACTERIZATION3_ID
                 , aGCO_CHARACTERIZATION4_ID
                 , aGCO_CHARACTERIZATION5_ID
                 , aCHARACT_VALUE1
                 , aCHARACT_VALUE2
                 , aCHARACT_VALUE3
                 , aCHARACT_VALUE4
                 , aCHARACT_VALUE5
                 , aSTM_LOCATION_ID
                 , aC_OUT_TYPE
                 , aC_OUT_ORIGINE
                 , nvl(aOUT_DATE, sysdate)
                 , aLOM_PRICE
                 , aDIC_COMPONENT_MVT_ID
                 , aLOM_MVT_COMMENT
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GETUSERINI
                  );
    end if;

    FAL_STOCK_MOVEMENT_FUNCTIONS.addPreparedStockMovements(aPreparedStockMovements     => aPreparedStockMovements
                                                         , aFAL_LOT_ID                 => aFAL_LOT_ID
                                                         , aGCO_GOOD_ID                => aGCO_GOOD_ID
                                                         , aSTM_STOCK_ID               => 0
                                                         , aSTM_LOCATION_ID            => aSTM_LOCATION_ID
                                                         , aOUT_QUANTITY               => aOUT_QUANTITY
                                                         , aLOM_PRICE                  => aLOM_PRICE
                                                         , aOUT_DATE                   => nvl(aOUT_DATE, sysdate)
                                                         , aMvtKind                    => aMvtKind
                                                         , aGCO_CHARACTERIZATION1_ID   => aGCO_CHARACTERIZATION1_ID
                                                         , aGCO_CHARACTERIZATION2_ID   => aGCO_CHARACTERIZATION2_ID
                                                         , aGCO_CHARACTERIZATION3_ID   => aGCO_CHARACTERIZATION3_ID
                                                         , aGCO_CHARACTERIZATION4_ID   => aGCO_CHARACTERIZATION4_ID
                                                         , aGCO_CHARACTERIZATION5_ID   => aGCO_CHARACTERIZATION5_ID
                                                         , aCHARACT_VALUE1             => aCHARACT_VALUE1
                                                         , aCHARACT_VALUE2             => aCHARACT_VALUE2
                                                         , aCHARACT_VALUE3             => aCHARACT_VALUE3
                                                         , aCHARACT_VALUE4             => aCHARACT_VALUE4
                                                         , aCHARACT_VALUE5             => aCHARACT_VALUE5
                                                         , aFAL_COMPONENT_LINK_ID      => aFAL_COMPONENT_LINK_ID
                                                         , aFAL_FACTORY_IN_ID          => aFAL_FACTORY_IN_ID
                                                         , aFAL_FACTORY_OUT_ID         => aFAL_FACTORY_OUT_ID
                                                         , aFAL_NETWORK_LINK_ID        => aFAL_NETWORK_LINK_ID
                                                         , aFactoryInOriginId          => aFactoryInOriginId
                                                         , aFAL_LOT_MATERIAL_LINK_ID   => aMATERIAL_LINK_ID
                                                          );
  end;

  /**
  * Procedure : GetComponentPrice
  * Description : Recherche du prix d'un composant
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param    aGCO_GOOD_ID      Produit
  */
  function GetComponentPrice(aGCO_GOOD_ID number)
    return number
  is
    aDic_Tariff     DIC_TARIFF.DIC_TARIFF_ID%type;
    round_type      varchar2(1);
    round_amount    number;
    aCurrencyId     number;
    aNet            number;
    aSpecial        number;
    CManagementMode gco_good.c_management_mode%type;
    aTypePrice      varchar2(1);
    lFlatRate       number;
    lTariffUnit     number;
  begin
    select max(C_MANAGEMENT_MODE)
      into CManagementMode
      from GCO_GOOD
     where GCO_GOOD_ID = aGCO_GOOD_ID;

    if CManagementMode = 1 then
      aTypePrice  := '3';
    elsif CManagementMode = 2 then
      aTypePrice  := '4';
    elsif CManagementMode = 3 then
      aTypePrice  := '5';
    end if;

    return GCO_I_LIB_PRICE.GetGoodPrice(iGoodId              => aGCO_GOOD_ID
                                      , iTypePrice           => aTypePrice
                                      , iThirdId             => null
                                      , iRecordId            => null
                                      , iFalScheduleStepId   => null
                                      , ioDicTariff          => aDic_Tariff   -- in out
                                      , iQuantity            => 1
                                      , iDateRef             => null
                                      , ioRoundType          => round_type   -- in out
                                      , ioRoundAmount        => round_amount   -- in out
                                      , ioCurrencyId         => aCurrencyId   -- in out
                                      , oNet                 => aNet   -- out
                                      , oSpecial             => aSpecial   -- out
                                      , oFlatRate            => lFlatRate
                                      , oTariffUnit          => lTariffUnit
                                       );
  end;

  /**
  * Function CreateNewComponent
  * Description : Création d'un nouveau composants, inexistant dans la nomenclature du lot de fabrication.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param    aFAL_LOT_ID       Lot de fabrication
  * @param    aGCO_GOOD_ID      Produit
  * @param    aSTM_STOCK_ID     Stock
  * @param    aSTM_LOCATION_ID  Emplacement
  * @param    aFOC_QUANTITY     quantité
  * @param    aLOM_NEED_DATE    date besoin
  * @param    aLOM_UTIL_COEF    coefficient d'utilisation si différent de 1
  */
  function CreateNewComponent(
    aFAL_LOT_ID      number
  , aGCO_GOOD_ID     number
  , aSTM_STOCK_ID    number
  , aSTM_LOCATION_ID number
  , aFOC_QUANTITY    number
  , aLOM_NEED_DATE   date default null
  , aLOM_UTIL_COEF   FAL_LOT_MATERIAL_LINK.LOM_UTIL_COEF%type default null
  )
    return number
  is
    aFAL_LOT_MATERIAL_LINK_ID number;
    aLOM_SEQ                  number;
    aLOT_TOTAL_QTY            number;
    SupInfQty                 number;
    TotBesoinQty              number;
    aC_CHRONOLOGY_TYPE        number;
    aLomPrice                 fal_lot_material_link.lom_price%type;
    vLOM_NEED_DATE            date;
    vCFabType                 fal_lot.c_fab_type%type;
  begin
    aFAL_LOT_MATERIAL_LINK_ID  := GetNewId;

    select nvl(max(LOM_SEQ), 0) + PCS.PC_CONFIG.GetConfig('FAL_COMPONENT_NUMBERING')
      into aLOM_SEQ
      from FAL_LOT_MATERIAL_LINK
     where FAL_LOT_ID = aFAL_LOT_ID;

    select nvl(LOT_TOTAL_QTY, 0)
         , nvl(C_FAB_TYPE, '0')
      into aLOT_TOTAL_QTY
         , vCFabType
      from FAL_LOT
     where FAL_LOT_ID = aFAL_LOT_ID;

    -- La différence de quantité entre le composant et le produit terminé est appliqué sur le coéfficient d'utilisation.
    -- Le calcul est effectué par l'appelant.
    if aLOM_UTIL_COEF is not null then
      SupInfQty     := 0;
      TotBesoinQty  := aFOC_QUANTITY;
    else
      SupInfQty     := round(aFOC_QUANTITY - aLOT_TOTAL_QTY, FAL_TOOLS.GetGoo_Number_Of_Decimal(aGCO_GOOD_ID) );
      TotBesoinQty  := aLOT_TOTAL_QTY + SupInfQty;
    end if;

    -- Retourne le type de chronologie du produit si existant, null si inexistant
    select max(C_CHRONOLOGY_TYPE)
      into aC_CHRONOLOGY_TYPE
      from GCO_CHARACTERIZATION
     where GCO_GOOD_ID = aGCO_GOOD_ID
       and C_CHARACT_TYPE = '5';

    -- Prix du composant
    aLomPrice                  := GetComponentPrice(aGCO_GOOD_ID);

    -- Date Besoin
    if aLOM_NEED_DATE is not null then
      vLOM_NEED_DATE  := aLOM_NEED_DATE;
    else
      begin
        select LOT_PLAN_BEGIN_DTE
          into vLOM_NEED_DATE
          from FAL_LOT
         where FAL_LOT_ID = aFAL_LOT_ID;
      exception
        when others then
          vLOM_NEED_DATE  := sysdate;
      end;
    end if;

    insert into FAL_LOT_MATERIAL_LINK
                (FAL_LOT_MATERIAL_LINK_ID
               , LOM_SEQ
               , LOM_SUBSTITUT
               , C_KIND_COM
               , C_DISCHARGE_COM
               , FAL_LOT_ID
               , LOM_UTIL_COEF
               , C_TYPE_COM
               , STM_STOCK_ID
               , STM_LOCATION_ID
               , GCO_GOOD_ID
               , A_DATECRE
               , A_IDCRE
               , LOM_MISSING
               , LOM_INTERVAL
               , LOM_FRE_NUM
               , LOM_STOCK_MANAGEMENT
               , LOM_PRICE
               , LOM_NEED_QTY
               , LOM_FULL_REQ_QTY
               , LOM_AVAILABLE_QTY
               , LOM_ADJUSTED_QTY
               , LOM_SECONDARY_REF
               , LOM_SHORT_DESCR
               , C_CHRONOLOGY_TYPE
               , LOM_CONSUMPTION_QTY
               , LOM_REJECTED_QTY
               , LOM_BACK_QTY
               , LOM_PT_REJECT_QTY
               , LOM_CPT_TRASH_QTY
               , LOM_CPT_RECOVER_QTY
               , LOM_CPT_REJECT_QTY
               , LOM_EXIT_RECEIPT
               , LOM_MAX_RECEIPT_QTY
               , LOM_MAX_FACT_QTY
               , LOM_BOM_REQ_QTY
               , LOM_ADJUSTED_QTY_RECEIPT
               , LOM_REF_QTY
               , LOM_NEED_DATE
                )
         values (aFAL_LOT_MATERIAL_LINK_ID   -- FAL_LOT_MATERIAL_LINK_ID
               , aLOM_SEQ   -- LOM_SEQ
               , 0   -- LOM_SUBSTITUT
               , '1'   -- C_KIND_COM
               , decode(vCFabType, '4', '2', '1')   -- C_DISCHARGE_COM
               , aFAL_LOT_ID   -- FAL_LOT_ID
               , nvl(aLOM_UTIL_COEF, 1)   -- LOM_UTIL_COEF
               , 1   -- C_TYPE_COM
               , aSTM_STOCK_ID   -- STM_STOCK_ID
               , aSTM_LOCATION_ID   -- STM_LOCATION_ID
               , aGCO_GOOD_ID   -- GCO_GOOD_ID
               , sysdate   -- A_DATECRE
               , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
               , 0   -- LOM_MISSING
               , 0   -- LOM_INTERVAL
               , 0   -- LOM_FRE_NUM
               , 1   -- LOM_STOCK_MANAGEMENT
               , aLomPrice   -- LOM_PRICE
               , aFOC_QUANTITY   -- LOM_NEED_QTY
               , TotBesoinQty   -- LOM_FULL_REQ_QTY
               , 0   -- LOM_AVAILABLE_QTY
               , SupInfQty   -- LOM_ADJUSTED_QTY
               , FAL_TOOLS.GetGOO_SECONDARY_REFERENCE(aGCO_GOOD_ID)   -- LOM_SECONDARY_REF
               , FAL_TOOLS.GetGOO_SHORT_DESCRIPTION(aGCO_GOOD_ID)   -- LOM_SHORT_DESCR
               , aC_CHRONOLOGY_TYPE   -- C_CHRONOLOGY_TYPE
               , 0   -- LOM_CONSUMPTION_QTY
               , 0   -- LOM_REJECTED_QTY
               , 0   -- LOM_BACK_QTY
               , 0   -- LOM_PT_REJECT_QTY
               , 0   -- LOM_CPT_TRASH_QTY
               , 0   -- LOM_CPT_RECOVER_QTY
               , 0   -- LOM_CPT_REJECT_QTY
               , 0   -- LOM_EXIT_RECEIPT
               , 0   -- LOM_MAX_RECEIPT_QTY
               , 0   -- LOM_MAX_FACT_QTY
               , nvl(aLOM_UTIL_COEF, 1) * aLOT_TOTAL_QTY   -- LOM_BOM_REQ_QTY
               , 0   -- LOM_ADJUSTED_QTY_RECEIPT
               , 1   -- LOM_REF_QTY
               , vLOM_NEED_DATE
                );

    return aFAL_LOT_MATERIAL_LINK_ID;
  end;

  /**
  * Procedure : UpdateComponentWithoutStkMngmt
  * Description : Mise à jour des composants du lot de fabrication en fonction des
  *                quantités qui ont été sortie en atelier.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param    aFalLotId        Lot de fabrication
  * @param    aReceptQty       Quantité réceptionnée
  * @param    aDismountedQty   Quantité démontée
  */
  procedure UpdateComponentWithoutStkMngmt(
    aFalLotId      FAL_LOT.FAL_LOT_ID%type
  , aReceptQty     FAL_LOT_MATERIAL_LINK.LOM_EXIT_RECEIPT%type default 0
  , aDismountedQty FAL_LOT_MATERIAL_LINK.LOM_EXIT_RECEIPT%type default 0
  )
  is
  begin
    update FAl_LOT_MATERIAL_LINK
       set LOM_EXIT_RECEIPT = nvl(LOM_EXIT_RECEIPT, 0) +(nvl(aReceptQty, 0) * LOM_UTIL_COEF)
         , LOM_CPT_REJECT_QTY = nvl(LOM_CPT_REJECT_QTY, 0) +(nvl(aDismountedQty, 0) * LOM_UTIL_COEF)
     where FAL_LOT_ID = aFalLotId
       and LOM_STOCK_MANAGEMENT = 0;
  end;

  /**
  * Procedure : UpdateComponentSupplierBySubctor
  * Description : Mise à jour des composants du lot fournis par le sous-traitant
  *                en fonction des quantités qui ont été réceptionnées
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param    aFalLotId        Lot de fabrication
  * @param    aReceptQty       Quantité réceptionnée
  */
  procedure UpdtComponentSuppliedBySubctor(aFalLotId FAL_LOT.FAL_LOT_ID%type, aReceptQty FAL_LOT_MATERIAL_LINK.LOM_EXIT_RECEIPT%type default 0)
  is
  begin
    update FAL_LOT_MATERIAL_LINK
       set LOM_EXIT_RECEIPT = nvl(LOM_EXIT_RECEIPT, 0) +(nvl(aReceptQty, 0) * LOM_UTIL_COEF)
         , LOM_CONSUMPTION_QTY = nvl(LOM_CONSUMPTION_QTY, 0) +(nvl(aReceptQty, 0) * LOM_UTIL_COEF)
     where FAL_LOT_ID = aFalLotId
       and C_KIND_COM = '4';
  end;

  /**
  * Procedure : UpdateFalLotMatLinkafterOutput
  * Description : Mise à jour des composants du lot de fabrication en fonction des
  *                quantités qui ont été sortie en atelier.
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param    aLOM_SESSION               Session oracle
  * @param    aFAL_LOT_ID                Lot de fabrication
  * @param    aFAL_LOT_MATERIAL_LINK_ID  Composant du lot de fabrication
  * @param    aContext                   Context depuis lequel on fait la mise à jour.
  * @param    ReceptionType              Type de réception (rebut ou PT)
  * @param    BatchBalance               Solde du lot ou non
  * @param    aReceptQty                 Quantité en réception ou démontage
  */
  procedure UpdateFalLotMatLinkafterOutput(
    aLOM_SESSION              FAL_LOT_MAT_LINK_TMP.LOM_SESSION%type
  , aFAL_LOT_ID               FAL_LOT_MAT_LINK_TMP.FAL_LOT_ID%type
  , aFAL_LOT_MATERIAL_LINK_ID FAL_LOT_MAT_LINK_TMP.FAL_LOT_MATERIAL_LINK_ID%type default null
  , aContext                  integer
  , ReceptionType             integer default 0
  , BatchBalance              integer default 0
  , aReceptQty                integer default 0
  )
  is
    cursor CurFAL_LOT_MAT_LINK_TMP
    is
      select nvl(TMPLOM.LOM_PRICE, 0) TMPLOM_PRICE
           , nvl(LOM.LOM_PRICE, 0) LOM_PRICE
           , nvl(TMPLOM.LOM_ADJUSTED_QTY, 0) TMPLOM_ADJUSTED_QTY
           , nvl(LOM.LOM_ADJUSTED_QTY, 0) LOM_ADJUSTED_QTY
           , nvl(LOM.LOM_FULL_REQ_QTY, 0) LOM_FULL_REQ_QTY
           , nvl(LOM.LOM_BOM_REQ_QTY, 0) LOM_BOM_REQ_QTY
           , nvl(TMPLOM.LOM_BOM_REQ_QTY, 0) TMPLOM_BOM_REQ_QTY
           , nvl(TMPLOM.LOM_FULL_REQ_QTY, 0) TMPLOM_FULL_REQ_QTY
           , nvl(LOM.LOM_CONSUMPTION_QTY, 0) LOM_CONSUMPTION_QTY
           , nvl(LOM.LOM_REJECTED_QTY, 0) LOM_REJECTED_QTY
           , nvl(LOM.LOM_BACK_QTY, 0) LOM_BACK_QTY
           , nvl(LOM.LOM_NEED_QTY, 0) LOM_NEED_QTY
           , nvl(LOM.LOM_MAX_RECEIPT_QTY, 0) LOM_MAX_RECEIPT_QTY
           , (select nvl(sum(FCL_HOLD_QTY), 0)
                from FAL_COMPONENT_LINK
               where FAL_LOT_MAT_LINK_TMP_ID = TMPLOM.FAL_LOT_MAT_LINK_TMP_ID) FCL_HOLD_QTY
           , (select nvl(sum(FCL_RETURN_QTY), 0)
                from FAL_COMPONENT_LINK
               where FAL_LOT_MAT_LINK_TMP_ID = TMPLOM.FAL_LOT_MAT_LINK_TMP_ID) FCL_RETURN_QTY
           , (select nvl(sum(FCL_TRASH_QTY), 0)
                from FAL_COMPONENT_LINK
               where FAL_LOT_MAT_LINK_TMP_ID = TMPLOM.FAL_LOT_MAT_LINK_TMP_ID) FCL_TRASH_QTY
           , (select nvl(sum(FCL_HOLD_QTY), 0)
                from FAL_COMPONENT_LINK
               where FAL_LOT_MAT_LINK_TMP_ID = TMPLOM.FAL_LOT_MAT_LINK_TMP_ID
                 and FAL_FACTORY_IN_ID is null) FCL_HOLD_QTY_OUT_OF_FACT_IN
           , nvl(LOM.LOM_ADJUSTED_QTY_RECEIPT, 0) LOM_ADJUSTED_QTY_RECEIPT
           , nvl(LOM.LOM_PT_REJECT_QTY, 0) LOM_PT_REJECT_QTY
           , nvl(LOM.LOM_CPT_TRASH_QTY, 0) LOM_CPT_TRASH_QTY
           , nvl(LOM.LOM_CPT_RECOVER_QTY, 0) LOM_CPT_RECOVER_QTY
           , nvl(LOM.LOM_CPT_REJECT_QTY, 0) LOM_CPT_REJECT_QTY
           , nvl(LOM.LOM_EXIT_RECEIPT, 0) LOM_EXIT_RECEIPT
           , nvl(LOM.LOM_UTIL_COEF, 0) LOM_UTIL_COEF
           , nvl(TMPLOM.LOM_UTIL_COEF, 0) TMPLOM_UTIL_COEF
           , nvl(LOM.LOM_REF_QTY, 0) LOM_REF_QTY
           , nvl(LOM.LOM_MAX_FACT_QTY, 0) LOM_MAX_FACT_QTY
           , LOM.FAL_LOT_MATERIAL_LINK_ID
           , nvl(LOT.LOT_INPROD_QTY, 0) LOT_INPROD_QTY
           , LOT.GCO_GOOD_ID
           , LOM.GCO_GOOD_ID LOM_GCO_GOOD_ID
           , LOM.C_KIND_COM
        from FAL_LOT_MAT_LINK_TMP TMPLOM
           , FAL_LOT_MATERIAL_LINK LOM
           , FAL_LOT LOT
       where TMPLOM.LOM_SESSION = aLOM_SESSION
         and TMPLOM.FAL_LOT_ID = aFAL_LOT_ID
         and (   nvl(aFAL_LOT_MATERIAL_LINK_ID, 0) = 0
              or TMPLOM.FAL_LOT_MATERIAL_LINK_ID = aFAL_LOT_MATERIAL_LINK_ID)
         and TMPLOM.FAL_LOT_MATERIAL_LINK_ID = LOM.FAL_LOT_MATERIAL_LINK_ID
         and LOM.FAL_LOT_ID = LOT.FAL_LOT_ID;

    CurFalLotMatLinktmp       CurFAL_LOT_MAT_LINK_TMP%rowtype;
    CalcQtyForManufacturing   FAL_LOT_MATERIAL_LINK.LOM_CONSUMPTION_QTY%type;
    nLOM_CONSUMPTION_QTY      number;
    nLOM_MAX_FACT_QTY         number;
    nLOM_NEED_QTY             number;
    nLOM_MAX_RECEIPT_QTY      number;
    nLOM_REJECTED_QTY         number;
    nLOM_BACK_QTY             number;
    nLOM_PRICE                number;
    nLOM_PT_REJECT_QTY        number;
    nLOM_ADJUSTED_QTY         number;
    nLOM_FULL_REQ_QTY         number;
    nLOM_EXIT_RECEIPT         number;
    nLOM_ADJUSTED_QTY_RECEIPT number;
    nLOM_CPT_RECOVER_QTY      number;
    nLOM_CPT_REJECT_QTY       number;
    nLOM_CPT_TRASH_QTY        number;
    nLOM_UTIL_COEF            number;
    nLOM_BOM_REQ_QTY          number;
  begin
    -- Parcours des composants et liens composants générés
    for CurFalLotMatLinkTmp in CurFAL_LOT_MAT_LINK_TMP loop
      -- Initialisation des valeurs calculées
      nLOM_CONSUMPTION_QTY       := CurFalLotMatLinkTmp.LOM_CONSUMPTION_QTY;
      nLOM_MAX_FACT_QTY          := CurFalLotMatLinkTmp.LOM_MAX_FACT_QTY;
      nLOM_REJECTED_QTY          := CurFalLotMatLinkTmp.LOM_REJECTED_QTY;
      nLOM_BACK_QTY              := CurFalLotMatLinkTmp.LOM_BACK_QTY;
      nLOM_PRICE                 := CurFalLotMatLinkTmp.LOM_PRICE;
      nLOM_PT_REJECT_QTY         := CurFalLotMatLinkTmp.LOM_PT_REJECT_QTY;
      nLOM_ADJUSTED_QTY          := CurFalLotMatLinkTmp.LOM_ADJUSTED_QTY;
      nLOM_FULL_REQ_QTY          := CurFalLotMatLinkTmp.LOM_FULL_REQ_QTY;
      nLOM_EXIT_RECEIPT          := CurFalLotMatLinkTmp.LOM_EXIT_RECEIPT;
      nLOM_ADJUSTED_QTY_RECEIPT  := CurFalLotMatLinkTmp.LOM_ADJUSTED_QTY_RECEIPT;
      nLOM_NEED_QTY              := CurFalLotMatLinkTmp.LOM_NEED_QTY;
      nLOM_MAX_RECEIPT_QTY       := CurFalLotMatLinkTmp.LOM_MAX_RECEIPT_QTY;
      nLOM_CPT_RECOVER_QTY       := CurFalLotMatLinkTmp.LOM_CPT_RECOVER_QTY;
      nLOM_CPT_REJECT_QTY        := CurFalLotMatLinkTmp.LOM_CPT_REJECT_QTY;
      nLOM_CPT_TRASH_QTY         := CurFalLotMatLinkTmp.LOM_CPT_TRASH_QTY;
      nLOM_UTIL_COEF             := CurFalLotMatLinkTmp.LOM_UTIL_COEF;
      nLOM_BOM_REQ_QTY           := CurFalLotMatLinkTmp.LOM_BOM_REQ_QTY;

      -- Sortie de composant
      if    aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtComponentOutput
         or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtSubCOComponentOutput then
        nLOM_CONSUMPTION_QTY  := nLOM_CONSUMPTION_QTY + CurFalLotMatLinkTmp.FCL_HOLD_QTY;
        nLOM_MAX_FACT_QTY     := 0;
        nLOM_PRICE            := CurFalLotMatLinkTmp.TMPLOM_PRICE;
        nLOM_ADJUSTED_QTY     := CurFalLotMatLinkTmp.TMPLOM_ADJUSTED_QTY;
        nLOM_FULL_REQ_QTY     := CurFalLotMatLinkTmp.TMPLOM_FULL_REQ_QTY;
        nLOM_UTIL_COEF        := CurFalLotMatLinkTmp.TMPLOM_UTIL_COEF;
        nLOM_BOM_REQ_QTY      := CurFalLotMatLinkTmp.TMPLOM_BOM_REQ_QTY;
      -- Retour de composants
      elsif    (aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtComponentReturn)
            or (aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchBalance) then
        nLOM_REJECTED_QTY  := nLOM_REJECTED_QTY + CurFalLotMatLinkTmp.FCL_TRASH_QTY;
        nLOM_BACK_QTY      := nLOM_BACK_QTY + CurFalLotMatLinkTmp.FCL_RETURN_QTY;
      -- Affectation de stock -> lots de fabrication
      elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtStockToBatchAllocation then
        nLOM_CONSUMPTION_QTY  := nLOM_CONSUMPTION_QTY + CurFalLotMatLinkTmp.FCL_HOLD_QTY;
      -- Affectation de lots de fabrication -> Stocks
      elsif aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchToStockAllocation then
        nLOM_BACK_QTY  := nLOM_BACK_QTY + CurFalLotMatLinkTmp.FCL_RETURN_QTY;
      -- Remplacement de composants
      elsif    aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtComponentReplacingOut
            or aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtComponentReplacingIn then
        nLOM_REJECTED_QTY     := nLOM_REJECTED_QTY + CurFalLotMatLinkTmp.FCL_TRASH_QTY;
        nLOM_BACK_QTY         := nLOM_BACK_QTY + CurFalLotMatLinkTmp.FCL_RETURN_QTY;
        nLOM_CONSUMPTION_QTY  := nLOM_CONSUMPTION_QTY + CurFalLotMatLinkTmp.FCL_HOLD_QTY;
      -- Réception
      elsif    (aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt)
            or (aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtDerivativeReturn) then
        -- QteRebutPT (uniquement dans le cas d'une Réception Rebut PT ...
        if ReceptionType = FAL_BATCH_FUNCTIONS.rtReject then
          nLOM_PT_REJECT_QTY  := greatest(nLOM_PT_REJECT_QTY - CurFalLotMatLinkTmp.FCL_HOLD_QTY, 0);
        end if;

        -- Qte Sup/Inf
        if BatchBalance = 1 then
          nLOM_ADJUSTED_QTY  := CurFalLotMatLinkTmp.TMPLOM_ADJUSTED_QTY;
        else
          -- Si les Qté sup/inf sont du même signe
          if sign(nLOM_ADJUSTED_QTY) = sign(CurFalLotMatLinkTmp.TMPLOM_ADJUSTED_QTY) then
            if nLOM_ADJUSTED_QTY = CurFalLotMatLinkTmp.LOM_ADJUSTED_QTY_RECEIPT then
              nLOM_ADJUSTED_QTY  := nLOM_ADJUSTED_QTY + CurFalLotMatLinkTmp.TMPLOM_ADJUSTED_QTY;
            else
              nLOM_ADJUSTED_QTY  :=
                                 greatest(abs(nLOM_ADJUSTED_QTY), abs(CurFalLotMatLinkTmp.TMPLOM_ADJUSTED_QTY + CurFalLotMatLinkTmp.LOM_ADJUSTED_QTY_RECEIPT) );

              if CurFalLotMatLinkTmp.TMPLOM_ADJUSTED_QTY < 0 then
                nLOM_ADJUSTED_QTY  := -nLOM_ADJUSTED_QTY;
              end if;
            end if;
          else
            nLOM_ADJUSTED_QTY  := nLOM_ADJUSTED_QTY + CurFalLotMatLinkTmp.TMPLOM_ADJUSTED_QTY;
          end if;
        end if;

        -- QteBesoinTotale
        nLOM_FULL_REQ_QTY          := nLOM_BOM_REQ_QTY + nLOM_ADJUSTED_QTY;

        if ReceptionType = FAL_BATCH_FUNCTIONS.rtDismantling then
          -- Qté retournée
          nLOM_CPT_RECOVER_QTY  := CurFalLotMatLinkTmp.LOM_CPT_RECOVER_QTY + CurFalLotMatLinkTmp.FCL_RETURN_QTY;
          -- Qté déchet
          nLOM_CPT_REJECT_QTY   := CurFalLotMatLinkTmp.LOM_CPT_REJECT_QTY + CurFalLotMatLinkTmp.FCL_TRASH_QTY;
          -- Qté rebut CPT
          nLOM_CPT_TRASH_QTY    := greatest(CurFalLotMatLinkTmp.LOM_CPT_TRASH_QTY - nLOM_BOM_REQ_QTY, 0);
        else
          -- QteConsomme
          if CurFalLotMatLinkTmp.C_KIND_COM = '2' then
            nLOM_CONSUMPTION_QTY  := 0;
          else
            nLOM_CONSUMPTION_QTY  := nLOM_CONSUMPTION_QTY + CurFalLotMatLinkTmp.FCL_HOLD_QTY_OUT_OF_FACT_IN;
          end if;

          -- QteSortieReception
          nLOM_EXIT_RECEIPT  := nLOM_EXIT_RECEIPT + CurFalLotMatLinkTmp.FCL_HOLD_QTY;
        end if;

        -- BesoinCPT
        -- Dérivé ...
        if CurFalLotMatLinkTmp.C_KIND_COM = '2' then
          nLOM_NEED_QTY  := 0;
        -- Composant ...
        else
          -- QteSupInf < 0 ...
          if nLOM_ADJUSTED_QTY < 0 then
            nLOM_NEED_QTY  := nLOM_FULL_REQ_QTY + nLOM_REJECTED_QTY + nLOM_BACK_QTY - nLOM_CONSUMPTION_QTY;
          -- QteSupInf >= 0 ...
          else
            nLOM_NEED_QTY  := nLOM_FULL_REQ_QTY + greatest(nLOM_REJECTED_QTY - nLOM_ADJUSTED_QTY, 0) + nLOM_BACK_QTY - nLOM_CONSUMPTION_QTY;
          end if;
        end if;

        -- QteSubInfEnReception
        nLOM_ADJUSTED_QTY_RECEIPT  := nLOM_ADJUSTED_QTY_RECEIPT + CurFalLotMatLinkTmp.TMPLOM_ADJUSTED_QTY;
        -- QteMaxReceptionnable
        nLOM_MAX_RECEIPT_QTY       :=
          getMaxReceptQty(aGCO_GOOD_ID                => CurFalLotMatLinkTmp.GCO_GOOD_ID
                        , aLOT_INPROD_QTY             => CurFalLotMatLinkTmp.LOT_INPROD_QTY
                        , aLOM_ADJUSTED_QTY           => nLOM_ADJUSTED_QTY
                        , aLOM_CONSUMPTION_QTY        => nLOM_CONSUMPTION_QTY
                        , aLOM_REF_QTY                => CurFalLotMatLinkTmp.LOM_REF_QTY
                        , aLOM_UTIL_COEF              => nLOM_UTIL_COEF
                        , aLOM_ADJUSTED_QTY_RECEIPT   => nLOM_ADJUSTED_QTY_RECEIPT
                        , aLOM_BACK_QTY               => nLOM_BACK_QTY
                        , aLOM_CPT_RECOVER_QTY        => nLOM_CPT_RECOVER_QTY
                        , aLOM_CPT_REJECT_QTY         => nLOM_CPT_REJECT_QTY
                        , aLOM_CPT_TRASH_QTY          => nLOM_CPT_TRASH_QTY
                        , aLOM_EXIT_RECEIPT           => nLOM_EXIT_RECEIPT
                        , aLOM_PT_REJECT_QTY          => nLOM_PT_REJECT_QTY
                        , aLOM_REJECTED_QTY           => nLOM_REJECTED_QTY
                        , aC_KIND_COM                 => CurFalLotMatLinkTmp.C_KIND_COM
                         );
      end if;

      if aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtBatchBalance then
        nLOM_NEED_QTY  := 0;
      elsif     (aContext <> FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt)
            and (aContext <> FAL_COMPONENT_LINK_FUNCTIONS.ctxtDerivativeReturn) then
        -- Si Qté Sup/Inf < 0
        if CurFalLotMatLinkTmp.TMPLOM_ADJUSTED_QTY < 0 then
          -- Qté besoin
          nLOM_NEED_QTY  := CurFalLotMatLinkTmp.TMPLOM_FULL_REQ_QTY + nLOM_REJECTED_QTY + nLOM_BACK_QTY - nLOM_CONSUMPTION_QTY;
        -- Si Qté sup inf >=0
        else
          -- Qté besoin
          nLOM_NEED_QTY  :=
            CurFalLotMatLinkTmp.TMPLOM_FULL_REQ_QTY +
            greatest(nLOM_REJECTED_QTY - CurFalLotMatLinkTmp.TMPLOM_ADJUSTED_QTY, 0) +
            nLOM_BACK_QTY -
            nvl(nLOM_CONSUMPTION_QTY, 0);
        end if;

        -- QteMaxReceptionnable
        nLOM_MAX_RECEIPT_QTY  :=
          getMaxReceptQty(aGCO_GOOD_ID                => CurFalLotMatLinkTmp.GCO_GOOD_ID
                        , aLOT_INPROD_QTY             => CurFalLotMatLinkTmp.LOT_INPROD_QTY
                        , aLOM_ADJUSTED_QTY           => CurFalLotMatLinkTmp.TMPLOM_ADJUSTED_QTY
                        , aLOM_CONSUMPTION_QTY        => nLOM_CONSUMPTION_QTY
                        , aLOM_REF_QTY                => CurFalLotMatLinkTmp.LOM_REF_QTY
                        , aLOM_UTIL_COEF              => nLOM_UTIL_COEF
                        , aLOM_ADJUSTED_QTY_RECEIPT   => CurFalLotMatLinkTmp.LOM_ADJUSTED_QTY_RECEIPT
                        , aLOM_BACK_QTY               => nLOM_BACK_QTY
                        , aLOM_CPT_RECOVER_QTY        => CurFalLotMatLinkTmp.LOM_CPT_RECOVER_QTY
                        , aLOM_CPT_REJECT_QTY         => CurFalLotMatLinkTmp.LOM_CPT_REJECT_QTY
                        , aLOM_CPT_TRASH_QTY          => CurFalLotMatLinkTmp.LOM_CPT_TRASH_QTY
                        , aLOM_EXIT_RECEIPT           => CurFalLotMatLinkTmp.LOM_EXIT_RECEIPT
                        , aLOM_PT_REJECT_QTY          => CurFalLotMatLinkTmp.LOM_PT_REJECT_QTY
                        , aLOM_REJECTED_QTY           => nLOM_REJECTED_QTY
                        , aC_KIND_COM                 => CurFalLotMatLinkTmp.C_KIND_COM
                         );
      end if;

      update FAL_LOT_MATERIAL_LINK
         set GCO_GOOD_ID = CurFalLotMatLinkTmp.LOM_GCO_GOOD_ID
           , LOM_PRICE = nLOM_PRICE
           , LOM_ADJUSTED_QTY = nLOM_ADJUSTED_QTY
           , LOM_FULL_REQ_QTY = nLOM_FULL_REQ_QTY
           , LOM_CONSUMPTION_QTY = nLOM_CONSUMPTION_QTY
           , LOM_MAX_FACT_QTY = nLOM_MAX_FACT_QTY
           , LOM_NEED_QTY = greatest(nLOM_NEED_QTY, 0)
           , LOM_MAX_RECEIPT_QTY = nLOM_MAX_RECEIPT_QTY
           , LOM_REJECTED_QTY = nLOM_REJECTED_QTY
           , LOM_BACK_QTY = nLOM_BACK_QTY
           , LOM_PT_REJECT_QTY = nLOM_PT_REJECT_QTY
           , LOM_EXIT_RECEIPT = nLOM_EXIT_RECEIPT
           , LOM_CPT_RECOVER_QTY = nLOM_CPT_RECOVER_QTY
           , LOM_CPT_REJECT_QTY = nLOM_CPT_REJECT_QTY
           , LOM_CPT_TRASH_QTY = nLOM_CPT_TRASH_QTY
           , LOM_ADJUSTED_QTY_RECEIPT = nLOM_ADJUSTED_QTY_RECEIPT
           , LOM_UTIL_COEF = nLOM_UTIL_COEF
           , LOM_BOM_REQ_QTY = nLOM_BOM_REQ_QTY
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where FAL_LOT_MATERIAL_LINK_ID = CurFalLotMatLinkTmp.FAL_LOT_MATERIAL_LINK_ID;
    end loop;

    -- Mise à jour des composants sans gestion de stock en réception ou démontage
    if     (aReceptQty > 0)
       and (aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt) then
      if ReceptionType = FAL_BATCH_FUNCTIONS.rtDismantling then
        UpdateComponentWithoutStkMngmt(aFalLotId => aFAL_LOT_ID, aDismountedQty => aReceptQty);
      else
        UpdateComponentWithoutStkMngmt(aFalLotId => aFAL_LOT_ID, aReceptQty => aReceptQty);
      end if;
    end if;

    -- Mise à jour des composants Fournis par les sous-traitants en réception
    UpdtComponentSuppliedBySubctor(aFalLotId => aFAL_LOT_ID, aReceptQty => aReceptQty);
  end;

  /**
  * Description
  *   Création de touts les mouvements en atelier pour un lot de fabrication
  */
  procedure CreateAllFactoryMovements(
    aFAL_LOT_ID               in     number
  , aDOC_DOCUMENT_ID          in     number default null
  , aFCL_SESSION              in     varchar2
  , aPreparedStockMovement    in out FAL_STOCK_MOVEMENT_FUNCTIONS.TPreparedStockMovements
  , aOUT_DATE                 in     date
  , aMovementKind             in     integer
  , aC_IN_ORIGINE             in     varchar2 default null
  , aC_OUT_ORIGINE            in     varchar2 default null
  , aFAL_LOT_MATERIAL_LINK_ID in     number default null
  , aContext                  in     integer default 0
  , iCFabType                 in     FAL_LOT.C_FAB_TYPE%type default null
  )
  as
    lttSTTStockPositionInfos FAL_LIB_PAIRING.ttSTTStockPositionInfos;
  begin
    lttSTTStockPositionInfos  := FAL_LIB_PAIRING.ttSTTStockPositionInfos();
    createAllFactoryMovements(aFAL_LOT_ID                 => aFAL_LOT_ID
                            , aDOC_DOCUMENT_ID            => aDOC_DOCUMENT_ID
                            , aFCL_SESSION                => aFCL_SESSION
                            , aPreparedStockMovement      => aPreparedStockMovement
                            , aOUT_DATE                   => aOUT_DATE
                            , aMovementKind               => aMovementKind
                            , aC_IN_ORIGINE               => aC_IN_ORIGINE
                            , aC_OUT_ORIGINE              => aC_OUT_ORIGINE
                            , aFAL_LOT_MATERIAL_LINK_ID   => aFAL_LOT_MATERIAL_LINK_ID
                            , aContext                    => aContext
                            , ittSTTStockPositionInfos    => lttSTTStockPositionInfos
                            , iCFabType                   => iCFabType
                             );
  end CreateAllFactoryMovements;

  /**
  * Description
  *   Création de touts les mouvements en atelier pour un lot de fabrication.
  */
  procedure CreateAllFactoryMovements(
    aFAL_LOT_ID               in            number
  , aDOC_DOCUMENT_ID          in            number
  , aFCL_SESSION              in            varchar2
  , aPreparedStockMovement    in out        FAL_STOCK_MOVEMENT_FUNCTIONS.TPreparedStockMovements
  , aOUT_DATE                 in            date
  , aMovementKind             in            integer
  , aC_IN_ORIGINE             in            varchar2 default null
  , aC_OUT_ORIGINE            in            varchar2 default null
  , aFAL_LOT_MATERIAL_LINK_ID in            number default null
  , aContext                  in            integer default 0
  , ittSTTStockPositionInfos  in out nocopy FAL_LIB_PAIRING.ttSTTStockPositionInfos
  , iCFabType                 in            FAL_LOT.C_FAB_TYPE%type default null
  )
  is
    cursor CUR_FAL_COMPONENT_LINK(aMovtkind integer)
    is
      select FCL.FCL_HOLD_QTY
           , FCL.FCL_TRASH_QTY
           , FCL.FCL_RETURN_QTY
           , FCL.FAL_LOT_ID
           , FCL.STM_STOCK_ID
           , FCL.STM_LOCATION_ID
           , FCL.STM_STOCK_POSITION_ID
           , FCL.FAL_NETWORK_LINK_ID
           , GCO_FUNCTIONS.GetCostPriceWithManagementMode(LML.GCO_GOOD_ID) LOM_PRICE
           , LML.GCO_GOOD_ID
           , LML.FAL_LOT_MATERIAL_LINK_ID
           , LML.C_KIND_COM
           , LOT.LOT_REFCOMPL
           , FNN.FAL_NETWORK_NEED_ID
           , FCL.FAL_COMPONENT_LINK_ID
           , FCL.FAL_FACTORY_IN_ID
           , FIN.IN_PRICE
           , FIN.STM_LOCATION_ID IN_LOCATION_ID
           , FCL.GCO_CHARACTERIZATION1_ID
           , FCL.GCO_CHARACTERIZATION2_ID
           , FCL.GCO_CHARACTERIZATION3_ID
           , FCL.GCO_CHARACTERIZATION4_ID
           , FCL.GCO_CHARACTERIZATION5_ID
           , FCL.FCL_CHARACTERIZATION_VALUE_1
           , FCL.FCL_CHARACTERIZATION_VALUE_2
           , FCL.FCL_CHARACTERIZATION_VALUE_3
           , FCL.FCL_CHARACTERIZATION_VALUE_4
           , FCL.FCL_CHARACTERIZATION_VALUE_5
           , LML.DIC_COMPONENT_MVT_ID
           , LML.LOM_MVT_COMMENT
           , LML.FAL_LOT_MAT_LINK_TMP_ID
        from FAL_COMPONENT_LINK FCL
           , FAL_LOT_MAT_LINK_TMP LML
           , FAL_LOT LOT
           , FAL_NETWORK_NEED FNN
           , FAL_FACTORY_IN FIN
           , STM_STOCK_POSITION SPO
       where LML.FAL_LOT_ID = aFAL_LOT_ID
         and LML.LOM_SESSION = aFCL_SESSION
         and FCL.FCL_SESSION = aFCL_SESSION
         and (   nvl(aFAL_LOT_MATERIAL_LINK_ID, 0) = 0
              or LML.FAL_LOT_MATERIAL_LINK_ID = aFAL_LOT_MATERIAL_LINK_ID)
         and LML.FAL_LOT_MAT_LINK_TMP_ID = FCL.FAL_LOT_MAT_LINK_TMP_ID
         and LML.FAL_LOT_ID = LOT.FAL_LOT_ID
         and LML.FAL_LOT_MATERIAL_LINK_ID = FNN.FAL_LOT_MATERIAL_LINK_ID(+)
         and FCL.FAL_FACTORY_IN_ID = FIN.FAL_FACTORY_IN_ID(+)
         and FCL.STM_STOCK_POSITION_ID = SPO.STM_STOCK_POSITION_ID(+)
         and (   FCL.FCL_HOLD_QTY <> 0
              or FCL.FCL_TRASH_QTY <> 0
              or FCL.FCL_RETURN_QTY <> 0)
         and (    (    aMovtkind <> FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersDechet
                   and aMovtkind <> FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersStock
                   and FCL.FAL_FACTORY_IN_ID is null
                  )
              or (     (   aMovtkind = FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersDechet
                        or aMovtkind = FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersStock
                       )
                  and FCL.FAL_FACTORY_IN_ID is not null
                 )
             )
         and (    (aContext <> FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt)
              or (     (aContext = FAL_COMPONENT_LINK_FUNCTIONS.ctxtManufacturingReceipt)
                  and (LML.C_KIND_COM = '1') )
             );

    CurFalComponentLink    CUR_FAL_COMPONENT_LINK%rowtype;
    aMvtQuantity           FAL_COMPONENT_LINK.FCL_HOLD_QTY%type;
    aMvtPrice              FAL_LOT_MATERIAL_LINK.LOM_PRICE%type;
    aDefltTrashStockID     number;
    aC_OUT_TYPE            varchar2(10);
    lLastIndex             integer;
    lttLotDetailLinkListID ID_TABLE_TYPE;
    lFactoryInID           FAL_FACTORY_IN.FAL_FACTORY_IN_ID%type;
  begin
    -- Parcours des quantités saisies
    for CurFalComponentLink in CUR_FAL_COMPONENT_LINK(aMovementKind) loop
      -- Quantité du mouvement
      if aMovementKind = FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersDechet then
        aMvtQuantity  := CurFalComponentLink.FCL_TRASH_QTY;
      elsif aMovementKind = FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersStock then
        aMvtQuantity  := CurFalComponentLink.FCL_RETURN_QTY;
      elsif aMovementKind = FAL_STOCK_MOVEMENT_FUNCTIONS.mktSortieStockVersAtelier then
        aMvtQuantity  := CurFalComponentLink.FCL_HOLD_QTY;
      else
        aMvtQuantity  := 0;
      end if;

      -- Si Qté du mouvement non nulle
      if aMvtQuantity <> 0 then
        -- Prix du mouvement
        if    aMovementKind = FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersDechet
           or aMovementKind = FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersStock then
          aMvtPrice  := CurFalComponentLink.IN_PRICE;
        elsif aMovementKind = FAL_STOCK_MOVEMENT_FUNCTIONS.mktSortieStockVersAtelier then
          aMvtPrice  := CurFalComponentLink.LOM_PRICE;
        else
          aMvtPrice  := 0;
        end if;

        -- Type de sortie
        if aMovementKind = FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersDechet then
          aC_OUT_TYPE  := '2';
        elsif aMovementKind = FAL_STOCK_MOVEMENT_FUNCTIONS.mktRetourAtelierVersStock then
          aC_OUT_TYPE  := '3';
        else
          aC_OUT_TYPE  := '';
        end if;

        -- Création des entrées et sorties atelier, comprends la préparation des mouvements de stock
        CreateFactoryMovement(aFAL_LOT_ID                 => CurFalComponentLink.FAL_LOT_ID
                            , aDOC_DOCUMENT_ID            => aDOC_DOCUMENT_ID
                            , aMATERIAL_LINK_ID           => CurFalComponentLink.FAL_LOT_MATERIAL_LINK_ID
                            , aGCO_GOOD_ID                => CurFalComponentLink.GCO_GOOD_ID
                            , aSTM_STOCK_POSITION_ID      => CurFalComponentLink.STM_STOCK_POSITION_ID
                            , aSTM_STOCK_ID               => CurFalComponentLink.STM_STOCK_ID
                            , aSTM_LOCATION_ID            => CurFalComponentLink.STM_LOCATION_ID
                            , aOUT_QUANTITY               => aMvtQuantity
                            , aLOT_REFCOMPL               => CurFalComponentLink.LOT_REFCOMPL
                            , aLOM_PRICE                  => aMvtPrice
                            , aPreparedStockMovements     => aPreparedStockMovement
                            , aFAL_COMPONENT_LINK_ID      => CurFalComponentLink.FAL_COMPONENT_LINK_ID
                            , aOUT_DATE                   => aOUT_DATE
                            , aMvtKind                    => aMovementKind
                            , aGCO_CHARACTERIZATION1_ID   => CurFalComponentLink.GCO_CHARACTERIZATION1_ID
                            , aGCO_CHARACTERIZATION2_ID   => CurFalComponentLink.GCO_CHARACTERIZATION2_ID
                            , aGCO_CHARACTERIZATION3_ID   => CurFalComponentLink.GCO_CHARACTERIZATION3_ID
                            , aGCO_CHARACTERIZATION4_ID   => CurFalComponentLink.GCO_CHARACTERIZATION4_ID
                            , aGCO_CHARACTERIZATION5_ID   => CurFalComponentLink.GCO_CHARACTERIZATION5_ID
                            , aCHARACT_VALUE1             => CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_1
                            , aCHARACT_VALUE2             => CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_2
                            , aCHARACT_VALUE3             => CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_3
                            , aCHARACT_VALUE4             => CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_4
                            , aCHARACT_VALUE5             => CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_5
                            , aC_IN_ORIGINE               => aC_IN_ORIGINE
                            , aC_OUT_ORIGINE              => aC_OUT_ORIGINE
                            , aC_OUT_TYPE                 => aC_OUT_TYPE
                            , aFAL_NETWORK_LINK_ID        => CurFalComponentLink.FAL_NETWORK_LINK_ID
                            , aContext                    => aContext
                            , aDIC_COMPONENT_MVT_ID       => CurFalComponentLink.DIC_COMPONENT_MVT_ID
                            , aLOM_MVT_COMMENT            => CurFalComponentLink.LOM_MVT_COMMENT
                            , aFAL_LOT_MAT_LINK_TMP_ID    => CurFalComponentLink.FAL_LOT_MAT_LINK_TMP_ID
                            , aFactoryInOriginId          => CurFalComponentLink.FAL_FACTORY_IN_ID
                            , aSessionId                  => aFCL_SESSION
                             );

        /* Mémorisation de la position de stock STT correspondante si type de stock = 4 (STT)) */
        if     (nvl(iCFabType, '0') = '4')
           and (FAL_LIB_PAIRING.hasPairing(iLotID => CurFalComponentLink.FAL_LOT_ID, iCptGoodID => CurFalComponentLink.GCO_GOOD_ID) = 1) then
          /* Recherche de(des) (l')appairage(s) correspondant à la position courante. */
          lttLotDetailLinkListID  :=
            FAL_LIB_PAIRING.getLotDetailLinkIDByStockPos(iLotID                    => CurFalComponentLink.FAL_LOT_ID
                                                       , iCptGoodID                => CurFalComponentLink.GCO_GOOD_ID
                                                       , iQty                      => aMvtQuantity
                                                       , iCharacterizationID1      => CurFalComponentLink.GCO_CHARACTERIZATION1_ID
                                                       , iCharacterizationID2      => CurFalComponentLink.GCO_CHARACTERIZATION2_ID
                                                       , iCharacterizationID3      => CurFalComponentLink.GCO_CHARACTERIZATION3_ID
                                                       , iCharacterizationID4      => CurFalComponentLink.GCO_CHARACTERIZATION4_ID
                                                       , iCharacterizationID5      => CurFalComponentLink.GCO_CHARACTERIZATION5_ID
                                                       , iCharacterizationValue1   => CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_1
                                                       , iCharacterizationValue2   => CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_2
                                                       , iCharacterizationValue3   => CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_3
                                                       , iCharacterizationValue4   => CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_4
                                                       , iCharacterizationValue5   => CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_5
                                                        );
          /* Recherche de l'entrée atelier qui vient d'être créée correspondant à la position courante */
          lFactoryInID            :=
            FAL_LIB_PAIRING.getFactoryInIDByStockPos(iLotID                    => CurFalComponentLink.FAL_LOT_ID
                                                   , iCptGoodID                => CurFalComponentLink.GCO_GOOD_ID
                                                   , iQty                      => aMvtQuantity
                                                   , iCharacterizationValue1   => CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_1
                                                   , iCharacterizationValue2   => CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_2
                                                   , iCharacterizationValue3   => CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_3
                                                   , iCharacterizationValue4   => CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_4
                                                   , iCharacterizationValue5   => CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_5
                                                    );

          /* Mémorisation dans le tableau des positions STT */
          if lttLotDetailLinkListID.count > 0 then
            for i in lttLotDetailLinkListID.first .. lttLotDetailLinkListID.last loop
              ittSTTStockPositionInfos.extend;
              lLastIndex                                                   := ittSTTStockPositionInfos.last;
              ittSTTStockPositionInfos(lLastIndex).FAL_LOT_DETAIL_LINK_ID  := lttLotDetailLinkListID(i);
              ittSTTStockPositionInfos(lLastIndex).FAL_FACTORY_IN_ID       := lFactoryInID;
            end loop;
          end if;
        end if;
      end if;
    end loop;
  end;

/**
  * Procedure : CreateFactoryMvtsOnRecept
  * Description : Création des sorties atelier pour la réception d'un lot
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param    aFalLotId      Lot de fabrication
  * @param    aSessionId     Session oracle
  * @param    ReceptionType  Type de réception (produit terminé, rebut)
  * @param    aDate          Date de réception
  * @param    aPreparedStockMovement   Tableau des mouvements de stock
  */
  procedure CreateFactoryMvtsOnRecept(
    aFalLotId                      fal_lot.fal_lot_id%type
  , aSessionId                     fal_lot_mat_link_tmp.lom_session%type
  , ReceptionType                  integer default FAL_BATCH_FUNCTIONS.rtFinishedProduct
  , aDate                          fal_lot.lot_plan_end_dte%type
  , aPreparedStockMovements in out FAL_STOCK_MOVEMENT_FUNCTIONS.TPreparedStockMovements
  )
  is
    cursor Cur_COMPO_LINK_ON_RECEPT
    is
      select   FCL.FAL_LOT_ID
             , LOM.FAL_LOT_MATERIAL_LINK_ID
             , FCL.GCO_GOOD_ID
             , null STM_STOCK_POSITION_ID
             , null STM_STOCK_ID
             , case LOM.C_KIND_COM
                 when '1' then null
                 else FCL.STM_LOCATION_ID
               end STM_LOCATION_ID
             , sum(FCL.FCL_HOLD_QTY) FCL_HOLD_QTY
             , (select LOT_REFCOMPL
                  from FAL_LOT
                 where FAL_LOT_ID = FCL.FAL_LOT_ID) LOT_REFCOMPL
             , nvl(FIN.IN_PRICE, LOM.LOM_PRICE) PRICE
             , case LOM.C_KIND_COM
                 when '1' then '1'   -- Consommé
                 else '4'   -- Dérivé
               end C_OUT_TYPE
             , LOM.C_KIND_COM
             , FCL.GCO_CHARACTERIZATION1_ID
             , FCL.GCO_CHARACTERIZATION2_ID
             , FCL.GCO_CHARACTERIZATION3_ID
             , FCL.GCO_CHARACTERIZATION4_ID
             , FCL.GCO_CHARACTERIZATION5_ID
             , FCL.FCL_CHARACTERIZATION_VALUE_1
             , FCL.FCL_CHARACTERIZATION_VALUE_2
             , FCL.FCL_CHARACTERIZATION_VALUE_3
             , FCL.FCL_CHARACTERIZATION_VALUE_4
             , FCL.FCL_CHARACTERIZATION_VALUE_5
             , FCL.FAL_FACTORY_IN_ID
          from FAL_COMPONENT_LINK FCL
             , FAL_LOT_MAT_LINK_TMP LOM
             , FAL_FACTORY_IN FIN
             , STM_STOCK_POSITION SPO
         where LOM.FAL_LOT_MAT_LINK_TMP_ID = FCL.FAL_LOT_MAT_LINK_TMP_ID
           and FCL.FAL_FACTORY_IN_ID = FIN.FAL_FACTORY_IN_ID(+)
           and FCL.STM_STOCK_POSITION_ID = SPO.STM_STOCK_POSITION_ID(+)
           and FCL.FAL_LOT_ID = aFalLotId
           and FCL.FCL_SESSION = aSessionId
      group by FCL.FAL_LOT_ID
             , FCL.GCO_GOOD_ID
             , FCL.STM_LOCATION_ID
             , LOM.FAL_LOT_MATERIAL_LINK_ID
             , nvl(FIN.IN_PRICE, LOM.LOM_PRICE)
             , C_KIND_COM
             , FCL.GCO_CHARACTERIZATION1_ID
             , FCL.GCO_CHARACTERIZATION2_ID
             , FCL.GCO_CHARACTERIZATION3_ID
             , FCL.GCO_CHARACTERIZATION4_ID
             , FCL.GCO_CHARACTERIZATION5_ID
             , FCL.FCL_CHARACTERIZATION_VALUE_1
             , FCL.FCL_CHARACTERIZATION_VALUE_2
             , FCL.FCL_CHARACTERIZATION_VALUE_3
             , FCL.FCL_CHARACTERIZATION_VALUE_4
             , FCL.FCL_CHARACTERIZATION_VALUE_5
             , FCL.FAL_FACTORY_IN_ID;
  begin
    for CurFalComponentLink in Cur_COMPO_LINK_ON_RECEPT loop
      -- Création des sorties atelier, comprends la préparation des mouvements de stock
      -- Les caractérisations type "lot" sont acceptées pour les dérivés (C_KIND_COM = '2').
      -- La caractérisation est alors forcément la 1ère et la valeur est la référence complète du lot.
      CreateFactoryMovement(aFAL_LOT_ID                 => CurFalComponentLink.FAL_LOT_ID
                          , aDOC_DOCUMENT_ID            => null
                          , aMATERIAL_LINK_ID           => CurFalComponentLink.FAL_LOT_MATERIAL_LINK_ID
                          , aGCO_GOOD_ID                => CurFalComponentLink.GCO_GOOD_ID
                          , aSTM_STOCK_POSITION_ID      => CurFalComponentLink.STM_STOCK_POSITION_ID
                          , aSTM_STOCK_ID               => CurFalComponentLink.STM_STOCK_ID
                          , aSTM_LOCATION_ID            => CurFalComponentLink.STM_LOCATION_ID
                          , aOUT_QUANTITY               => CurFalComponentLink.FCL_HOLD_QTY
                          , aLOT_REFCOMPL               => CurFalComponentLink.LOT_REFCOMPL
                          , aLOM_PRICE                  => CurFalComponentLink.PRICE
                          , aPreparedStockMovements     => aPreparedStockMovements
                          , aOUT_DATE                   => aDate
                          , aMvtKind                    => case nvl(CurFalComponentLink.C_KIND_COM, '0')
                              when '2' then FAL_STOCK_MOVEMENT_FUNCTIONS.mktReceptionProduitDerive
                              else FAL_STOCK_MOVEMENT_FUNCTIONS.mktComposantConsomme
                            end
                          , aC_OUT_ORIGINE              => ReceptionType
                          , aC_OUT_TYPE                 => CurFalComponentLink.C_OUT_TYPE
                          , aGCO_CHARACTERIZATION1_ID   => CurFalComponentLink.GCO_CHARACTERIZATION1_ID
                          , aGCO_CHARACTERIZATION2_ID   => CurFalComponentLink.GCO_CHARACTERIZATION2_ID
                          , aGCO_CHARACTERIZATION3_ID   => CurFalComponentLink.GCO_CHARACTERIZATION3_ID
                          , aGCO_CHARACTERIZATION4_ID   => CurFalComponentLink.GCO_CHARACTERIZATION4_ID
                          , aGCO_CHARACTERIZATION5_ID   => CurFalComponentLink.GCO_CHARACTERIZATION5_ID
                          , aCHARACT_VALUE1             => CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_1
                          , aCHARACT_VALUE2             => CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_2
                          , aCHARACT_VALUE3             => CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_3
                          , aCHARACT_VALUE4             => CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_4
                          , aCHARACT_VALUE5             => CurFalComponentLink.FCL_CHARACTERIZATION_VALUE_5
                          , aFactoryInOriginId          => CurFalComponentLink.FAL_FACTORY_IN_ID
                           );
    end loop;
  end;

  /**
  * procedure   : UpdateFalFactoryMvtPrices
  * Description : Procédure de mise à jour des prix en cascade sur les entrées et
  *               sorties atelier (depuis recalcul du PRCS).
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param   aFAL_FACTORY_IN_ID : Entrée Atelier.
  * @param   aNewPrice : Nouveau prix de l'entrée atelier.
  */
  procedure UpdateFalFactoryMvtPrices(aFAL_FACTORY_IN_ID number, aNewPrice number)
  is
    cursor CUR_FAL_FACTORY_IN
    is
      select FAL_LOT_ID
           , IN_PRICE as OLD_PRICE
           , GCO_GOOD_ID
           , IN_DATE
           , IN_CHARACTERIZATION_VALUE_1
           , IN_CHARACTERIZATION_VALUE_2
           , IN_CHARACTERIZATION_VALUE_3
           , IN_CHARACTERIZATION_VALUE_4
           , IN_CHARACTERIZATION_VALUE_5
        from FAL_FACTORY_IN
       where FAL_FACTORY_IN_ID = aFAL_FACTORY_IN_ID;

    cursor CUR_SPLITTED_FAL_FACTORY_IN(
      aFAL_LOT_ID  number
    , aIN_PRICE    number
    , aGCO_GOOD_ID number
    , aIN_DATE     date
    , aIN_CHAR_1   varchar2
    , aIN_CHAR_2   varchar2
    , aIN_CHAR_3   varchar2
    , aIN_CHAR_4   varchar2
    , aIN_CHAR_5   varchar2
    )
    is
      select distinct FAL_FACTORY_IN_ID
                 from FAL_FACTORY_IN FIN
                    , FAL_HISTO_LOT HIL
                where HIL.FAL_LOT5_ID = aFAL_LOT_ID
                  and HIL.C_EVEN_TYPE = '7'
                  and HIL.FAL_LOT4_ID = FIN.FAL_LOT_ID
                  and nvl(FIN.IN_PRICE, 0) = nvl(aIN_PRICE, 0)
                  and FIN.GCO_GOOD_ID = aGCO_GOOD_ID
                  and trunc(nvl(FIN.IN_DATE, sysdate) ) >= trunc(nvl(aIN_DATE, sysdate) )
                  and nvl(FIN.IN_CHARACTERIZATION_VALUE_1, ' ') = nvl(aIN_CHAR_1, ' ')
                  and nvl(FIN.IN_CHARACTERIZATION_VALUE_2, ' ') = nvl(aIN_CHAR_2, ' ')
                  and nvl(FIN.IN_CHARACTERIZATION_VALUE_3, ' ') = nvl(aIN_CHAR_3, ' ')
                  and nvl(FIN.IN_CHARACTERIZATION_VALUE_4, ' ') = nvl(aIN_CHAR_4, ' ')
                  and nvl(FIN.IN_CHARACTERIZATION_VALUE_5, ' ') = nvl(aIN_CHAR_5, ' ');

    CurFalFactoryIn         CUR_FAL_FACTORY_IN%rowtype;
    CurSplittedFalFactoryIn CUR_SPLITTED_FAL_FACTORY_IN%rowtype;
    aSplittedFactoryIn      number;
    vCRUD_DEF               FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    open CUR_FAL_FACTORY_IN;

    fetch CUR_FAL_FACTORY_IN
     into CurFalFactoryIn;

    FWK_I_MGT_ENTITY.new(FWK_I_TYP_STM_ENTITY.gcStmStockMovement, vCRUD_DEF, false, null, null, 'STM_STOCK_MOVEMENT_ID');

    for tplMovement in (select STM_STOCK_MOVEMENT_ID
                             , SMO_MOVEMENT_QUANTITY
                          from STM_STOCK_MOVEMENT
                         where FAL_FACTORY_OUT_ID is not null
                           and FAL_FACTORY_OUT_ID in(
                                 select FAL_FACTORY_OUT_ID
                                   from FAL_FACTORY_OUT
                                  where FAL_LOT_ID = CurFalFactoryIn.FAL_LOT_ID
                                    and nvl(OUT_PRICE, 0) = nvl(CurFalFactoryIn.OLD_PRICE, 0)
                                    and GCO_GOOD_ID = CurFalFactoryIn.GCO_GOOD_ID
                                    and trunc(nvl(OUT_DATE, sysdate) ) >= trunc(nvl(CurFalFactoryIn.IN_DATE, sysdate) )
                                    and nvl(OUT_CHARACTERIZATION_VALUE_1, ' ') = nvl(CurFalFactoryIn.IN_CHARACTERIZATION_VALUE_1, ' ')
                                    and nvl(OUT_CHARACTERIZATION_VALUE_2, ' ') = nvl(CurFalFactoryIn.IN_CHARACTERIZATION_VALUE_2, ' ')
                                    and nvl(OUT_CHARACTERIZATION_VALUE_3, ' ') = nvl(CurFalFactoryIn.IN_CHARACTERIZATION_VALUE_3, ' ')
                                    and nvl(OUT_CHARACTERIZATION_VALUE_4, ' ') = nvl(CurFalFactoryIn.IN_CHARACTERIZATION_VALUE_4, ' ')
                                    and nvl(OUT_CHARACTERIZATION_VALUE_5, ' ') = nvl(CurFalFactoryIn.IN_CHARACTERIZATION_VALUE_5, ' ') ) ) loop
      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'STM_STOCK_MOVEMENT_ID', tplMovement.STM_STOCK_MOVEMENT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_UNIT_PRICE', aNewPrice);
      FWK_I_MGT_ENTITY_DATA.SetColumn(vCRUD_DEF, 'SMO_MOVEMENT_PRICE', aNewPrice * nvl(tplMovement.SMO_MOVEMENT_QUANTITY, 0) );
      FWK_I_MGT_ENTITY.UpdateEntity(vCRUD_DEF);
    end loop;

    FWK_I_MGT_ENTITY.Release(vCRUD_DEF);

    -- Mise à jour des sorties atelier correspondantes sur le lots de fabrication.
    update FAL_FACTORY_OUT
       set OUT_PRICE = aNewPrice
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_LOT_ID = CurFalFactoryIn.FAL_LOT_ID
       and nvl(OUT_PRICE, 0) = nvl(CurFalFactoryIn.OLD_PRICE, 0)
       and GCO_GOOD_ID = CurFalFactoryIn.GCO_GOOD_ID
       and trunc(OUT_DATE) >= trunc(CurFalFactoryIn.IN_DATE)
       and nvl(OUT_CHARACTERIZATION_VALUE_1, ' ') = nvl(CurFalFactoryIn.IN_CHARACTERIZATION_VALUE_1, ' ')
       and nvl(OUT_CHARACTERIZATION_VALUE_2, ' ') = nvl(CurFalFactoryIn.IN_CHARACTERIZATION_VALUE_2, ' ')
       and nvl(OUT_CHARACTERIZATION_VALUE_3, ' ') = nvl(CurFalFactoryIn.IN_CHARACTERIZATION_VALUE_3, ' ')
       and nvl(OUT_CHARACTERIZATION_VALUE_4, ' ') = nvl(CurFalFactoryIn.IN_CHARACTERIZATION_VALUE_4, ' ')
       and nvl(OUT_CHARACTERIZATION_VALUE_5, ' ') = nvl(CurFalFactoryIn.IN_CHARACTERIZATION_VALUE_5, ' ');

    -- Si le lot a fait l'objet d'un (ou plusieurs éclatements), appel récursif
    -- pour MAJ en cascade. sur chacuns des éclatements.
    for CurSplittedFalFactoryIn in CUR_SPLITTED_FAL_FACTORY_IN(CurFalFactoryIn.FAL_LOT_ID
                                                             , CurFalFactoryIn.OLD_PRICE
                                                             , CurFalFactoryIn.GCO_GOOD_ID
                                                             , CurFalFactoryIn.IN_DATE
                                                             , CurFalFactoryIn.IN_CHARACTERIZATION_VALUE_1
                                                             , CurFalFactoryIn.IN_CHARACTERIZATION_VALUE_2
                                                             , CurFalFactoryIn.IN_CHARACTERIZATION_VALUE_3
                                                             , CurFalFactoryIn.IN_CHARACTERIZATION_VALUE_4
                                                             , CurFalFactoryIn.IN_CHARACTERIZATION_VALUE_5
                                                              ) loop
      UpdateFalFactoryMvtPrices(CurSplittedFalFactoryIn.FAL_FACTORY_IN_ID, aNewPrice);
    end loop;

    -- MAJ de l'entrée atelier concernée.
    update FAL_FACTORY_IN
       set IN_PRICE = nvl(aNewPrice, 0)
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where FAL_FACTORY_IN_ID = aFAL_FACTORY_IN_ID;

    -- Insertion d'un historique de lot de fabrication "Recalcul PRCS".
    FAL_BATCH_FUNCTIONS.CreateBatchHistory(CurFalFactoryIn.FAL_LOT_ID, '25');

    close CUR_FAL_FACTORY_IN;
  end;

  /**
  * procedure   : ReserveComponentDischargeCode5
  * Description : Création des les réservation sur stock des composants avec code décharge 5 et 6
  *
  * @created CLE
  * @lastUpdate
  * @public
  * @param    aFalLotId      Lot de fabrication
  * @param    aSessionId     Session oracle
  */
  procedure ReserveComponentDischargeCode5(aFalLotId fal_lot.fal_lot_id%type, aSessionId fal_lot_mat_link_tmp.lom_session%type)
  is
    cursor crComponentCode5
    is
      select FCL.FAL_COMPONENT_LINK_ID
           , TMPLOM.FAL_LOT_MATERIAL_LINK_ID
           , (select FAL_NETWORK_NEED_ID
                from FAL_NETWORK_NEED
               where FAL_LOT_MATERIAL_LINK_ID = TMPLOM.FAL_LOT_MATERIAL_LINK_ID) FAL_NETWORK_NEED_ID
           , FCL.STM_STOCK_POSITION_ID
           , FCL.STM_LOCATION_ID
           , FCL.FAL_NETWORK_LINK_ID
           , FCL.FCL_HOLD_QTY
        from FAL_COMPONENT_LINK FCL
           , FAL_LOT_MAT_LINK_TMP TMPLOM
       where FCL.FAL_LOT_ID = aFalLotId
         and FCL.FCL_SESSION = aSessionId
         and TMPLOM.FAL_LOT_MAT_LINK_TMP_ID = FCL.FAL_LOT_MAT_LINK_TMP_ID
         and (   TMPLOM.C_DISCHARGE_COM = '5'
              or TMPLOM.C_DISCHARGE_COM = '6')
         and (select nvl(PDT_STOCK_ALLOC_BATCH, 0)
                from GCO_PRODUCT
               where GCO_GOOD_ID = TMPLOM.GCO_GOOD_ID) = 1;

    type TTabComponentCode5 is table of crComponentCode5%rowtype
      index by binary_integer;

    TabComponentCode5 TTabComponentCode5;
    idxCompo5         integer;
  begin
    open crComponentCode5;

    fetch crComponentCode5
    bulk collect into TabComponentCode5;

    close crComponentCode5;

    if TabComponentCode5.count > 0 then
      -- Il faut commencer par supprimer tous les liens d'attribution concernés car si plusieurs fois le même composant
      -- apparaît, cette suppression sur le 2ème composant est "deadlocké" par la réservation stock du 1er (d'où le TabComponentCode5)
      for tplComponentCode5 in crComponentCode5 loop
        -- Suppression du lien de réservation du composant temporaire
        FAL_COMPONENT_LINK_FUNCTIONS.DeleteComponentLink(tplComponentCode5.FAL_COMPONENT_LINK_ID);
      end loop;

      for idxCompo5 in TabComponentCode5.first .. TabComponentCode5.last loop
        -- Suppresion des attribs sur appro éventuelles du besoin
        FAL_REDO_ATTRIBS.SuppAttribSurNeedOnSupplies(TabComponentCode5(idxCompo5).FAL_NETWORK_NEED_ID);

        -- Création de la réservation sur stock, uniquement pour les besoins libres.
        if TabComponentCode5(idxCompo5).FAL_NETWORK_LINK_ID is null then
          FAL_NETWORK.CreateAttribBesoinStock(PrmNeedID            => TabComponentCode5(idxCompo5).FAL_NETWORK_NEED_ID
                                            , PrmPositionID        => TabComponentCode5(idxCompo5).STM_STOCK_POSITION_ID
                                            , PrmSTM_LOCATION_ID   => TabComponentCode5(idxCompo5).STM_LOCATION_ID
                                            , PrmA                 => TabComponentCode5(idxCompo5).FCL_HOLD_QTY
                                             );
        end if;
      end loop;
    end if;
  end;

  function getMaxReceptQty(
    aGCO_GOOD_ID              number
  , aLOT_INPROD_QTY           number
  , aLOM_ADJUSTED_QTY         number
  , aLOM_CONSUMPTION_QTY      number
  , aLOM_REF_QTY              number
  , aLOM_UTIL_COEF            number
  , aLOM_ADJUSTED_QTY_RECEIPT number default 0
  , aLOM_BACK_QTY             number default 0
  , aLOM_CPT_RECOVER_QTY      number default 0
  , aLOM_CPT_REJECT_QTY       number default 0
  , aLOM_CPT_TRASH_QTY        number default 0
  , aLOM_EXIT_RECEIPT         number default 0
  , aLOM_PT_REJECT_QTY        number default 0
  , aLOM_REJECTED_QTY         number default 0
  , aLOM_STOCK_MANAGEMENT     number default 1
  , aC_KIND_COM               FAL_LOT_MATERIAL_LINK.C_KIND_COM%type default '1'
  , aC_TYPE_COM               FAL_LOT_MATERIAL_LINK.C_TYPE_COM%type default '1'
  )
    return number
  is
    tmpValue number;
  begin
    -- Composant de type "dérivé" ou "pseudo" (autre que "composant"),
    -- OU composant inactif ou de type "texte"
    -- => la Qté max recept = 0
    if    (aC_KIND_COM <> '1')
       or (aC_TYPE_COM <> '1') then
      return 0;
    end if;

    if    (aLOM_STOCK_MANAGEMENT <> 1)
       or (aLOM_UTIL_COEF = 0) then
      return aLOT_INPROD_QTY;
    end if;

    if aLOM_ADJUSTED_QTY < 0 then
      -- QteSupInf < 0 ...
      tmpValue  := aLOM_CONSUMPTION_QTY - aLOM_ADJUSTED_QTY + aLOM_ADJUSTED_QTY_RECEIPT;
    else
      tmpValue  := aLOM_CONSUMPTION_QTY;
    end if;

    tmpValue  :=
        tmpValue
        -(aLOM_REJECTED_QTY + aLOM_BACK_QTY + aLOM_PT_REJECT_QTY + aLOM_CPT_TRASH_QTY + aLOM_CPT_RECOVER_QTY + aLOM_CPT_REJECT_QTY + aLOM_EXIT_RECEIPT);

    if tmpValue < 0 then
      return 0;
    else
      return FAL_TOOLS.ArrondiInferieur(tmpValue / aLOM_UTIL_COEF * aLOM_REF_QTY, aGCO_GOOD_ID);
    end if;
  end;

  /**
  * function GetFreeQtyForLaunchedBatches
  * Description : Procédure de recherche des quantités libre encore à sortir sur les OFs
  *               déjà lancés.
  * @created ECA
  * @lastUpdate
  * @public
  * @param
  * @return Qté encore à sortir
  */
  function GetFreeQtyForLaunchedBatches(aGCO_GOOD_ID number)
    return number
  is
    aFreeQty number;
  begin
    select sum(FNN.FAN_FREE_QTY + FNN.FAN_NETW_QTY)
      into aFreeQty
      from FAL_NETWORK_NEED FNN
         , FAL_LOT_MATERIAL_LINK LOM
         , FAL_LOT LOT
     where FNN.GCO_GOOD_ID = aGCO_GOOD_ID
       and FNN.FAL_LOT_MATERIAL_LINK_ID = LOM.FAL_LOT_MATERIAL_LINK_ID
       and LOM.FAL_LOT_ID = LOT.FAL_LOT_ID
       and LOT.C_LOT_STATUS = '2';

    return nvl(aFreeQty, 0);
  exception
    when no_data_found then
      return 0;
  end GetFreeQtyForLaunchedBatches;

  /**
  * function GetAvailableComponentQty
  * Description : Procédure de calcul du disponible pour un composant donné
  *
  * @created ECA
  * @lastUpdate
  * @public
  * @param    aGCO_GOOD_ID : Produit
  * @param    aSTM_STOCK_ID : Stock de consommation
  * @param    aSTM_LOCATION_ID : Emplacement de consommation du composant.
  * @param    aUseNeedQtyOnBatches : Tenir des comptes des qtés à sortir sur les lots lancés
  */
  function GetAvailableComponentQty(aGCO_GOOD_ID number, aSTM_STOCK_ID number, aSTM_LOCATION_ID number, aUseNeedQtyOnBatches integer)
    return number
  is
    aSelectionQry varchar2(32000);
    aAvailableQty number;
  begin
    aSelectionQry  := ' select NVL(SUM(SPO.SPO_AVAILABLE_QUANTITY), 0) ';

    -- Si prise en compte des qtés libres sur les OF en cours.
    if aUseNeedQtyOnBatches = 1 then
      aSelectionQry  := aSelectionQry || '      - NVL(FAL_COMPONENT_FUNCTIONS.GetFreeQtyForLaunchedBatches(:aGCO_GOOD_ID), 0) ';
    end if;

    aSelectionQry  :=
      aSelectionQry ||
      '   from STM_STOCK_POSITION SPO ' ||
      '  where SPO.GCO_GOOD_ID = :aGCO_GOOD_ID ' ||
      '    and NVL(SPO.SPO_AVAILABLE_QUANTITY,0) > 0 ' ||
      '    and ((FAL_TOOLS.ProductHasPeremptionDate(SPO.GCO_GOOD_ID) = 0 or SPO.SPO_CHRONOLOGICAL is null or SPO.SPO_CHRONOLOGICAL = ''N/A'' ) ' ||
      '          or ' ||
      '         (FAL_TOOLS.ProductHasPeremptionDate(SPO.GCO_GOOD_ID) = 1 and ' ||
      '           TRUNC(GCO_I_LIB_CHARACTERIZATION.ChronoFormatToDate(SPO.SPO_CHRONOLOGICAL, GCO_I_LIB_CHARACTERIZATION.GetChronoCharID(SPO.GCO_GOOD_ID) )) - ' ||
      '             nvl(FAL_TOOLS.GetCHA_LAPSING_MARGE(SPO.GCO_GOOD_ID) ,0) >= TRUNC(SYSDATE))) ';

    -- Sortie possible sur l'emplacement de consommation du composant uniquement
    if    upper(PCS.PC_CONFIG.GetConfig('FAL_USE_LOCATION_SELECT_LAUNCH') ) = 'FALSE'
       or PCS.PC_CONFIG.GetConfig('FAL_LOCATION_SELECT_LAUNCH') = '1' then
      aSelectionQry  := aSelectionQry || ' and SPO.STM_LOCATION_ID = :aSTM_LOCATION_ID ' || ' group by GCO_GOOD_ID ';

      if aUseNeedQtyOnBatches = 1 then
        execute immediate aSelectionQry
                     into aAvailableQty
                    using aGCO_GOOD_ID, aGCO_GOOD_ID, aSTM_LOCATION_ID;
      else
        execute immediate aSelectionQry
                     into aAvailableQty
                    using aGCO_GOOD_ID, aSTM_LOCATION_ID;
      end if;
    -- Sortie possible sur les emplacements du stock de consommation du composant.
    elsif     upper(PCS.PC_CONFIG.GetConfig('FAL_USE_LOCATION_SELECT_LAUNCH') ) = 'TRUE'
          and PCS.PC_CONFIG.GetConfig('FAL_LOCATION_SELECT_LAUNCH') = '2' then
      aSelectionQry  := aSelectionQry || ' and SPO.STM_STOCK_ID = :aSTM_STOCK_ID ' || ' group by GCO_GOOD_ID ';

      if aUseNeedQtyOnBatches = 1 then
        execute immediate aSelectionQry
                     into aAvailableQty
                    using aGCO_GOOD_ID, aGCO_GOOD_ID, aSTM_STOCK_ID;
      else
        execute immediate aSelectionQry
                     into aAvailableQty
                    using aGCO_GOOD_ID, aSTM_STOCK_ID;
      end if;
    -- Sortie possible sur les positions de stocks des emplacements de stock des stocks " public " gérés dans le calcul des besoins
    elsif     upper(PCS.PC_CONFIG.GetConfig('FAL_USE_LOCATION_SELECT_LAUNCH') ) = 'TRUE'
          and PCS.PC_CONFIG.GetConfig('FAL_LOCATION_SELECT_LAUNCH') = '3' then
      aSelectionQry  :=
        aSelectionQry ||
        ' and SPO.STM_STOCK_ID in (select STM_STOCK_ID ' ||
        '                            from STM_STOCK ' ||
        '                           where C_ACCESS_METHOD = ''PUBLIC'' ' ||
        '                             and STO_NEED_CALCULATION = 1) ' ||
        ' group by GCO_GOOD_ID ';

      if aUseNeedQtyOnBatches = 1 then
        execute immediate aSelectionQry
                     into aAvailableQty
                    using aGCO_GOOD_ID, aGCO_GOOD_ID;
      else
        execute immediate aSelectionQry
                     into aAvailableQty
                    using aGCO_GOOD_ID;
      end if;
    end if;

    if nvl(aAvailableQty, 0) <= 0 then
      aAvailableQty  := 0;
    end if;

    return aAvailableQty;
  exception
    when no_data_found then
      return 0;
    when others then
      raise;
  end;
end FAL_COMPONENT_FUNCTIONS;
