--------------------------------------------------------
--  DDL for Package Body ASA_MISSION_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_MISSION_FUNCTIONS" 
as
  /**
  * Description
  *    Calcul la durée de l'intervention selon le calendrier du client
  */
  procedure CalcInterventionPeriod(aMissionID in ASA_INTERVENTION.ASA_MISSION_ID%type, vStartDate in date, vEndDate in date, aNewTime out number)
  is
    vDepartmentID ASA_MISSION.PAC_DEPARTMENT_ID%type;
    vCustomerID   ASA_MISSION.PAC_CUSTOM_PARTNER_ID%type;
    vScheduleID   PAC_SCHEDULE.PAC_SCHEDULE_ID%type;
  begin
    -- Recherche du client et du département relatif à la mission passée en paramètre
    select MIS.PAC_DEPARTMENT_ID
         , MIS.PAC_CUSTOM_PARTNER_ID
      into vDepartmentID
         , vCustomerID
      from ASA_MISSION MIS
     where MIS.ASA_MISSION_ID = aMissionID;

    -- Récupération du calendrier du département le cas échéant
    begin
      if (vDepartmentID is not null) then
        select PAC_SCHEDULE_ID
          into vScheduleID
          from PAC_DEPARTMENT
         where PAC_DEPARTMENT_ID = vDepartmentID;
      end if;
    exception
      when no_data_found then
        vDepartmentId  := null;
    end;

    -- Recherche du calendrier par défaut
    if    (vDepartmentID is null)
       or (vScheduleID is null) then
      vScheduleID  := PAC_I_LIB_SCHEDULE.GetDefaultSchedule;
    end if;

    -- Calcul de la durée d'intervention si on a trouvé un calendrier et que les dates sont renseignées
    if     (vScheduleID is not null)
       and (vStartDate is not null)
       and (vEndDate is not null)
       and (vEndDate > vStartDate) then
      PAC_I_LIB_SCHEDULE.CalcOpenTimeBetween(oTime           => aNewTime
                                           , iScheduleID_1   => vScheduleID
                                           , iScheduleID_2   => PAC_I_LIB_SCHEDULE.GetDefaultSchedule
                                           , iDate_1         => vStartDate
                                           , iDate_2         => vEndDate
                                           , iFilter_1       => 'CUSTOMER'
                                           , iFilterID_1     => vCustomerID
                                            );
    end if;
  end CalcInterventionPeriod;

  /**
  * Description
  *    Recherche des informations du mouvement
  */
  procedure InitMvtInfo(aInterventionID in ASA_INTERVENTION.ASA_INTERVENTION_ID%type)
  is
  begin
    -- Recherche des genres de mouvement
    begin
      select MIT.MIT_TRANS_MVT_KIND_ID
           , MOK.STM_STM_MOVEMENT_KIND_ID
           , MIT.MIT_OUT_MVT_KIND_ID
           , MIT.STM_MVT_KIND_EXCH_IN_ID
           , MIT.STM_MVT_KIND_EXCH_OUT_ID
           , MIS.MIS_NUMBER || ' / ' || ITR.ITR_NUMBER
        into gMvtTraOutID
           , gMvtTraInID
           , gMvtOutMvtID
           , gMvtExchInID
           , gMvtExchOutID
           , gMvtWording
        from ASA_MISSION_TYPE MIT
           , ASA_MISSION MIS
           , ASA_INTERVENTION ITR
           , STM_MOVEMENT_KIND MOK
       where MIT.ASA_MISSION_TYPE_ID = MIS.ASA_MISSION_TYPE_ID
         and MIS.ASA_MISSION_ID = ITR.ASA_MISSION_ID
         and ITR.ASA_INTERVENTION_ID = aInterventionID
         and MOK.STM_MOVEMENT_KIND_ID = MIT.MIT_TRANS_MVT_KIND_ID;
    exception
      when no_data_found then
        gMvtTraOutID  := null;
        gMvtTraInID   := null;
        gMvtOutMvtID  := null;
        gMvtWording   := null;
    end;

    -- Recherche de l'exercice et de la période actifs
    gMvtDate        := STM_FUNCTIONS.GetMovementDate(sysdate);
    gMvtExerciseId  := STM_FUNCTIONS.GetExerciseId(gMvtDate);
    gMvtPeriodId    := STM_FUNCTIONS.GetPeriodId(gMvtDate);
  end InitMvtInfo;

  /**
  * Description
  *    Génération des mouvements de transfert du stock de départ vers le stock de destination
  */
  procedure GenerateTransferMvt(
    aIntervDetID      in     ASA_INTERVENTION_DETAIL.ASA_INTERVENTION_DETAIL_ID%type
  , aStockMovementId  out    STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type
  , aStockMovement2Id out    STM_STOCK_MOVEMENT.STM_STM_STOCK_MOVEMENT_ID%type
  , aGoodID           in     GCO_GOOD.GCO_GOOD_ID%type
  , aStockFromId      in     STM_STOCK_MOVEMENT.STM_STOCK_ID%type
  , aLocationFromId   in     STM_STOCK_MOVEMENT.STM_LOCATION_ID%type
  , aStockToId        in     STM_STOCK_MOVEMENT.STM_STOCK_ID%type
  , aLocationToId     in     STM_STOCK_MOVEMENT.STM_LOCATION_ID%type
  , aMvtQty           in     STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type
  , aUnitPrice        in     STM_STOCK_MOVEMENT.SMO_UNIT_PRICE%type
  , aCharac1Id        in     STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , aCharac2Id        in     STM_STOCK_MOVEMENT.GCO_GCO_CHARACTERIZATION_ID%type
  , aCharac3Id        in     STM_STOCK_MOVEMENT.GCO2_GCO_CHARACTERIZATION_ID%type
  , aCharac4Id        in     STM_STOCK_MOVEMENT.GCO3_GCO_CHARACTERIZATION_ID%type
  , aCharac5Id        in     STM_STOCK_MOVEMENT.GCO4_GCO_CHARACTERIZATION_ID%type
  , aCharVal1         in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type
  , aCharVal2         in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_2%type
  , aCharVal3         in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_3%type
  , aCharVal4         in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_4%type
  , aCharVal5         in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_5%type
  , aError            out    varchar2
  )
  is
    vAvailableQty         STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
    vControlStatus        number;
    vPDT_STOCK_MANAGEMENT GCO_PRODUCT.PDT_STOCK_MANAGEMENT%type;
    vInterventionID       ASA_INTERVENTION.ASA_INTERVENTION_ID%type;
    vMokTransfertAttrib   STM_MOVEMENT_KIND.MOK_TRANSFER_ATTRIB%type;
  begin
    vAvailableQty  := 0;

    select max(ASA_INTERVENTION_ID)
      into vInterventionID
      from ASA_INTERVENTION_DETAIL
     where ASA_INTERVENTION_DETAIL_ID = aIntervDetID;

    -- Contrôle des statuts de la mission et de l'intervention
    select count(*)
      into vControlStatus
      from ASA_MISSION MIS
         , ASA_INTERVENTION ITR
     where MIS.ASA_MISSION_ID = ITR.ASA_MISSION_ID
       and ITR.ASA_INTERVENTION_ID = vInterventionID
       and ITR.C_ASA_ITR_STATUS <> '00'
       and MIS.C_ASA_MIS_STATUS <> '00';

    if vControlStatus > 0 then
      select PDT_STOCK_MANAGEMENT
        into vPDT_STOCK_MANAGEMENT
        from GCO_PRODUCT
       where GCO_GOOD_ID = aGoodId;

      -- Initialisation des infos du mouvement
      InitMvtInfo(vInterventionID);

      if vPDT_STOCK_MANAGEMENT = 1 then
        -- récupère la valeur de l'option "Autoriser transfert d'attribution" du genre de mouvement
        select MOK_TRANSFER_ATTRIB
          into vMokTransfertAttrib
          from STM_MOVEMENT_KIND
         where STM_MOVEMENT_KIND_ID = gMvtTraOutID;

        if vMokTransfertAttrib = 0 then
          -- Contrôle de la disponibilité en stock de l'article à sortir du stock
          vAvailableQty  :=
            STM_I_LIB_STOCK_POSITION.getSumRealStockQty(iGoodID                   => aGoodId
                                                      , iStockID                  => aStockFromId
                                                      , iLocationID               => aLocationFromId
                                                      , iCharacterizationID1      => aCharac1Id
                                                      , iCharacterizationID2      => aCharac2Id
                                                      , iCharacterizationID3      => aCharac3Id
                                                      , iCharacterizationID4      => aCharac4Id
                                                      , iCharacterizationID5      => aCharac5Id
                                                      , iCharacterizationValue1   => aCharVal1
                                                      , iCharacterizationValue2   => aCharVal2
                                                      , iCharacterizationValue3   => aCharVal3
                                                      , iCharacterizationValue4   => aCharVal4
                                                      , iCharacterizationValue5   => aCharVal5
                                                      , iCheckStockCond           => 1
                                                      , iMovementDate             => sysdate
                                                      , iMovementKindId           => gMvtTraOutID
                                                       );
        else
          -- Contrôle de la disponibilité en stock de l'article à sortir du stock
          vAvailableQty  :=
            STM_I_LIB_STOCK_POSITION.getSumStockQty(iGoodID                   => aGoodId
                                                  , iStockID                  => aStockFromId
                                                  , iLocationID               => aLocationFromId
                                                  , iCharacterizationID1      => aCharac1Id
                                                  , iCharacterizationID2      => aCharac2Id
                                                  , iCharacterizationID3      => aCharac3Id
                                                  , iCharacterizationID4      => aCharac4Id
                                                  , iCharacterizationID5      => aCharac5Id
                                                  , iCharacterizationValue1   => aCharVal1
                                                  , iCharacterizationValue2   => aCharVal2
                                                  , iCharacterizationValue3   => aCharVal3
                                                  , iCharacterizationValue4   => aCharVal4
                                                  , iCharacterizationValue5   => aCharVal5
                                                  , iCheckStockCond           => 1
                                                  , iMovementDate             => sysdate
                                                  , iMovementKindId           => gMvtTraOutID
                                                   );
        end if;
      end if;

      -- si la quantité disponible en stock est supérieure ou égale à la quantité à transférer
        -- ou si le produit n'est pas géré en stock, on effectue le transfert
      if    (vAvailableQty >= aMvtQty)
         or (vPDT_STOCK_MANAGEMENT = 0) then
        -- ID des mouvements
        select init_id_seq.nextval
          into aStockMovementId
          from dual;

        select init_id_seq.nextval
          into aStockMovement2Id
          from dual;

        -- Génération du mouvement de transfert de sortie
        STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId   => aStockMovementId
                                        , iGoodId             => aGoodId
                                        , iMovementKindId     => gMvtTraOutID
                                        , iExerciseId         => gMvtExerciseId
                                        , iPeriodId           => gMvtPeriodId
                                        , iMvtDate            => gMvtDate
                                        , iStockId            => aStockFromId
                                        , iLocationId         => aLocationFromId
                                        , iThirdId            => null
                                        , iRecordId           => null
                                        , iChar1Id            => aCharac1Id
                                        , iChar2Id            => aCharac2Id
                                        , iChar3Id            => aCharac3Id
                                        , iChar4Id            => aCharac4Id
                                        , iChar5Id            => aCharac5Id
                                        , iCharValue1         => aCharVal1
                                        , iCharValue2         => aCharVal2
                                        , iCharValue3         => aCharVal3
                                        , iCharValue4         => aCharVal4
                                        , iCharValue5         => aCharVal5
                                        , iMovement2Id        => null
                                        , iWording            => gMvtWording
                                        , iMvtQty             => aMvtQty
                                        , iMvtPrice           => aUnitPrice * aMvtQty
                                        , iUnitPrice          => aUnitPrice
                                        , iRefUnitPrice       => aUnitPrice
                                        , iIntervDetID        => aIntervDetID
                                         );
        -- Génération du mouvement de transfert d'entrée
        STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId   => aStockMovement2Id
                                        , iGoodId             => aGoodId
                                        , iMovementKindId     => gMvtTraInID
                                        , iExerciseId         => gMvtExerciseId
                                        , iPeriodId           => gMvtPeriodId
                                        , iMvtDate            => gMvtDate
                                        , iStockId            => aStockToId
                                        , iLocationId         => aLocationToId
                                        , iThirdId            => null
                                        , iRecordId           => null
                                        , iChar1Id            => aCharac1Id
                                        , iChar2Id            => aCharac2Id
                                        , iChar3Id            => aCharac3Id
                                        , iChar4Id            => aCharac4Id
                                        , iChar5Id            => aCharac5Id
                                        , iCharValue1         => aCharVal1
                                        , iCharValue2         => aCharVal2
                                        , iCharValue3         => aCharVal3
                                        , iCharValue4         => aCharVal4
                                        , iCharValue5         => aCharVal5
                                        , iMovement2Id        => aStockMovementId
                                        , iWording            => gMvtWording
                                        , iMvtQty             => aMvtQty
                                        , iMvtPrice           => aUnitPrice * aMvtQty
                                        , iUnitPrice          => aUnitPrice
                                        , iRefUnitPrice       => aUnitPrice
                                        , iIntervDetID        => aIntervDetID
                                         );
      else
        aError  := '001';   -- Quantité en stock insuffisante
      end if;
    else
      aError  := '004';   -- Statut de la mission ou de l'intervention = "provisoire"
    end if;
  end GenerateTransferMvt;

  /**
  * procedure GenerateTransferMvt
  * Description
  *    Génération des mouvements de transfert du stock de départ vers le stock de destination
  * @created David Saadé 30.03.2006
  */
  procedure GenerateTransferMvt(aIntervDetID in ASA_INTERVENTION_DETAIL.ASA_INTERVENTION_DETAIL_ID%type)
  is
    tplIntervDet      ASA_INTERVENTION_DETAIL%rowtype;
    aStockMovementId  STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
    aStockMovement2Id STM_STOCK_MOVEMENT.STM_STM_STOCK_MOVEMENT_ID%type;
    aError            varchar2(10);
  begin
    -- Récupération des infos du détail d'intervention
    select *
      into tplIntervDet
      from ASA_INTERVENTION_DETAIL
     where ASA_INTERVENTION_DETAIL_ID = aIntervDetID;

    -- Génération du mouvement de transfert
    GenerateTransferMvt(aIntervDetID        => aIntervDetID
                      , aStockMovementId    => aStockMovementId
                      , aStockMovement2Id   => aStockMovement2Id
                      , aGoodID             => tplIntervDet.GCO_GOOD_ID
                      , aStockFromId        => tplIntervDet.AID_STOCK_FROM_ID
                      , aLocationFromId     => tplIntervDet.AID_LOCATION_FROM_ID
                      , aStockToId          => tplIntervDet.AID_STOCK_TO_ID
                      , aLocationToId       => tplIntervDet.AID_LOCATION_TO_ID
                      , aMvtQty             => tplIntervDet.AID_TAKEN_QUANTITY
                      , aUnitPrice          => tplIntervDet.AID_UNIT_PRICE
                      , aCharac1Id          => tplIntervDet.GCO_CHAR1_ID
                      , aCharac2Id          => tplIntervDet.GCO_CHAR2_ID
                      , aCharac3Id          => tplIntervDet.GCO_CHAR3_ID
                      , aCharac4Id          => tplIntervDet.GCO_CHAR4_ID
                      , aCharac5Id          => tplIntervDet.GCO_CHAR5_ID
                      , aCharVal1           => tplIntervDet.AID_CHAR1_VALUE
                      , aCharVal2           => tplIntervDet.AID_CHAR2_VALUE
                      , aCharVal3           => tplIntervDet.AID_CHAR3_VALUE
                      , aCharVal4           => tplIntervDet.AID_CHAR4_VALUE
                      , aCharVal5           => tplIntervDet.AID_CHAR5_VALUE
                      , aError              => aError
                       );

    if     (aStockMovementId is not null)
       and (aStockMovement2Id is not null) then
      update ASA_INTERVENTION_DETAIL
         set AID_TRANSFER_DONE = 1
           , STM_STOCK_MVT_TRSF_ID = aStockMovementId
       where ASA_INTERVENTION_DETAIL_ID = aIntervDetID;
    end if;
  end GenerateTransferMvt;

  /**
  * Description
  *    Génération des mouvements de consommation du détail d'intervention
  */
  procedure GenerateAllMvt(
    aIntervDetID      in     ASA_INTERVENTION_DETAIL.ASA_INTERVENTION_DETAIL_ID%type
  , aStockMovementId  out    STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type   -- mvt retour en sortie
  , aStockMovement2Id out    STM_STOCK_MOVEMENT.STM_STM_STOCK_MOVEMENT_ID%type   -- mvt retour en entrée
  , aStockMovement3Id out    STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type   -- mvt de consommation/Echange en sortie
  , aStkMvtExchInID   out    STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type   -- mvt d'échange en entrée
  , aGoodID           in     GCO_GOOD.GCO_GOOD_ID%type
  , aStockFromId      in     STM_STOCK_MOVEMENT.STM_STOCK_ID%type
  , aLocationFromId   in     STM_STOCK_MOVEMENT.STM_LOCATION_ID%type
  , aStockToId        in     STM_STOCK_MOVEMENT.STM_STOCK_ID%type
  , aLocationToId     in     STM_STOCK_MOVEMENT.STM_LOCATION_ID%type
  , aReturnStockId    in     STM_STOCK_MOVEMENT.STM_STOCK_ID%type
  , aReturnLocationId in     STM_STOCK_MOVEMENT.STM_LOCATION_ID%type
  , aConsumedQty      in     STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type   -- qté consommée ou échangée
  , aReturnQty        in     STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type
  , aUnitPrice        in     STM_STOCK_MOVEMENT.SMO_UNIT_PRICE%type
  , aCharac1Id        in     STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type
  , aCharac2Id        in     STM_STOCK_MOVEMENT.GCO_GCO_CHARACTERIZATION_ID%type
  , aCharac3Id        in     STM_STOCK_MOVEMENT.GCO2_GCO_CHARACTERIZATION_ID%type
  , aCharac4Id        in     STM_STOCK_MOVEMENT.GCO3_GCO_CHARACTERIZATION_ID%type
  , aCharac5Id        in     STM_STOCK_MOVEMENT.GCO4_GCO_CHARACTERIZATION_ID%type
  , aCharVal1         in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type
  , aCharVal2         in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_2%type
  , aCharVal3         in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_3%type
  , aCharVal4         in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_4%type
  , aCharVal5         in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_5%type
  , aExchange         in     ASA_INTERVENTION_DETAIL.AID_EXCHANGE%type default 0
  , aExchGoodId       in     GCO_GOOD.GCO_GOOD_ID%type default null
  , aExchCostPrice    in     STM_STOCK_MOVEMENT.SMO_UNIT_PRICE%type default null
  , aExchStockId      in     STM_STOCK_MOVEMENT.STM_STOCK_ID%type default null
  , aExchLocId        in     STM_STOCK_MOVEMENT.STM_LOCATION_ID%type default null
  , aExchCharac1Id    in     STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type default null
  , aExchCharac2Id    in     STM_STOCK_MOVEMENT.GCO_GCO_CHARACTERIZATION_ID%type default null
  , aExchCharac3Id    in     STM_STOCK_MOVEMENT.GCO2_GCO_CHARACTERIZATION_ID%type default null
  , aExchCharac4Id    in     STM_STOCK_MOVEMENT.GCO3_GCO_CHARACTERIZATION_ID%type default null
  , aExchCharac5Id    in     STM_STOCK_MOVEMENT.GCO4_GCO_CHARACTERIZATION_ID%type default null
  , aExchCharVal1     in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type default null
  , aExchCharVal2     in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_2%type default null
  , aExchCharVal3     in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_3%type default null
  , aExchCharVal4     in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_4%type default null
  , aExchCharVal5     in     STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_5%type default null
  , aError            out    varchar2
  )
  is
    vAvailableQty         STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
    vPDT_STOCK_MANAGEMENT GCO_PRODUCT.PDT_STOCK_MANAGEMENT%type;
    vMokTransfertAttrib   STM_MOVEMENT_KIND.MOK_TRANSFER_ATTRIB%type;
    vMovementKindID       STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
  begin
    if nvl(aReturnQty, 0) > 0 then
      -- Génération du mouvement de retour (transfert stock embarqué vers stock retour)
      GenerateTransferMvt(aIntervDetID        => aIntervDetID
                        , aStockMovementId    => aStockMovementId
                        , aStockMovement2Id   => aStockMovement2Id
                        , aGoodID             => aGoodID
                        , aStockFromId        => aStockToId
                        , aLocationFromId     => aLocationToId
                        , aStockToId          => aReturnStockId
                        , aLocationToId       => aReturnLocationId
                        , aMvtQty             => aReturnQty
                        , aUnitPrice          => aUnitPrice
                        , aCharac1Id          => aCharac1Id
                        , aCharac2Id          => aCharac2Id
                        , aCharac3Id          => aCharac3Id
                        , aCharac4Id          => aCharac4Id
                        , aCharac5Id          => aCharac5Id
                        , aCharVal1           => aCharVal1
                        , aCharVal2           => aCharVal2
                        , aCharVal3           => aCharVal3
                        , aCharVal4           => aCharVal4
                        , aCharVal5           => aCharVal5
                        , aError              => aError
                         );
    end if;

    -- Génération du mouvement de consommation/échange (sortie du stock embarqué)
    if (aError is null) then
      if (nvl(aConsumedQty, 0) > 0) then
        select PDT_STOCK_MANAGEMENT
          into vPDT_STOCK_MANAGEMENT
          from GCO_PRODUCT
         where GCO_GOOD_ID = aGoodId;

        if vPDT_STOCK_MANAGEMENT = 1 then
          -- récupère la valeur de l'option "Autoriser transfert d'attribution" du genre de mouvement
          if aExchange = 0 then
            vMovementKindID  := gMvtOutMvtID;
          else
            vMovementKindID  := gMvtExchOutID;
          end if;

          select MOK_TRANSFER_ATTRIB
            into vMokTransfertAttrib
            from STM_MOVEMENT_KIND
           where STM_MOVEMENT_KIND_ID = vMovementKindID;

          if vMokTransfertAttrib = 0 then
            -- Contrôle de la disponibilité en stock de l'article à sortir du stock
            vAvailableQty  :=
              STM_I_LIB_STOCK_POSITION.getSumRealStockQty(iGoodID                   => aGoodId
                                                        , iStockID                  => aStockToId
                                                        , iLocationID               => aLocationToId
                                                        , iCharacterizationID1      => aCharac1Id
                                                        , iCharacterizationID2      => aCharac2Id
                                                        , iCharacterizationID3      => aCharac3Id
                                                        , iCharacterizationID4      => aCharac4Id
                                                        , iCharacterizationID5      => aCharac5Id
                                                        , iCharacterizationValue1   => aCharVal1
                                                        , iCharacterizationValue2   => aCharVal2
                                                        , iCharacterizationValue3   => aCharVal3
                                                        , iCharacterizationValue4   => aCharVal4
                                                        , iCharacterizationValue5   => aCharVal5
                                                        , iCheckStockCond           => 1
                                                        , iMovementDate             => sysdate
                                                        , iMovementKindId           => vMovementKindID
                                                         );
          else
            -- Contrôle de la disponibilité en stock de l'article à sortir du stock
            vAvailableQty  :=
              STM_I_LIB_STOCK_POSITION.getSumStockQty(iGoodID                   => aGoodId
                                                    , iStockID                  => aStockToId
                                                    , iLocationID               => aLocationToId
                                                    , iCharacterizationID1      => aCharac1Id
                                                    , iCharacterizationID2      => aCharac2Id
                                                    , iCharacterizationID3      => aCharac3Id
                                                    , iCharacterizationID4      => aCharac4Id
                                                    , iCharacterizationID5      => aCharac5Id
                                                    , iCharacterizationValue1   => aCharVal1
                                                    , iCharacterizationValue2   => aCharVal2
                                                    , iCharacterizationValue3   => aCharVal3
                                                    , iCharacterizationValue4   => aCharVal4
                                                    , iCharacterizationValue5   => aCharVal5
                                                    , iCheckStockCond           => 1
                                                    , iMovementDate             => sysdate
                                                    , iMovementKindId           => vMovementKindID
                                                     );
          end if;
        end if;

        -- si la quantité disponible en stock est supérieure ou égale à la quantité à sortir
        -- ou si le produit n'est pas géré en stock, on effectue le mouvement
        if    (vAvailableQty >= nvl(aConsumedQty, 0) )
           or (vPDT_STOCK_MANAGEMENT = 0) then
          -- ID des mouvements
          aStockMovement3Id  := GetNewId;

          -- Génération du mouvement de consommation
          begin
            STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId   => aStockMovement3Id
                                            , iGoodId             => aGoodId
                                            , iMovementKindId     => case
                                                when aExchange = 0 then gMvtOutMvtID
                                                else gMvtExchOutID
                                              end
                                            , iExerciseId         => gMvtExerciseId
                                            , iPeriodId           => gMvtPeriodId
                                            , iMvtDate            => gMvtDate
                                            , iStockId            => aStockToId
                                            , iLocationId         => aLocationToId
                                            , iThirdId            => null
                                            , iRecordId           => null
                                            , iChar1Id            => aCharac1Id
                                            , iChar2Id            => aCharac2Id
                                            , iChar3Id            => aCharac3Id
                                            , iChar4Id            => aCharac4Id
                                            , iChar5Id            => aCharac5Id
                                            , iCharValue1         => aCharVal1
                                            , iCharValue2         => aCharVal2
                                            , iCharValue3         => aCharVal3
                                            , iCharValue4         => aCharVal4
                                            , iCharValue5         => aCharVal5
                                            , iWording            => gMvtWording
                                            , iMvtQty             => aConsumedQty
                                            , iMvtPrice           => aUnitPrice * aConsumedQty
                                            , iUnitPrice          => aUnitPrice
                                            , iRefUnitPrice       => aUnitPrice
                                            , iIntervDetID        => aIntervDetID
                                             );

            if (aStockMovement3Id is null) then
              aError  := '003';   -- Aucun mouvement généré
            end if;
          exception
            when others then
              aError  := '003';   -- Aucun mouvement généré
          end;
        else
          aError  := '001';   -- Quantité en stock insuffisante
        end if;
      elsif nvl(aReturnQty, 0) = 0 then
        -- La quantité consommée doit être supérieure à 0 mais uniquement si la quantité retourné est égale à 0
        aError  := '005';
      end if;
    end if;

    -- Génération du mouvement d'échange (entrée dans stock pour échange)
    if     (aError is null)
       and (aExchange = 1) then
      begin
        -- Vérification de la présence des valeurs des caractérisations. }
        if    (    aExchCharac1Id is not null
               and aExchCharVal1 is null)
           or (    aExchCharac2Id is not null
               and aExchCharVal2 is null)
           or (    aExchCharac3Id is not null
               and aExchCharVal3 is null)
           or (    aExchCharac4Id is not null
               and aExchCharVal4 is null)
           or (    aExchCharac5Id is not null
               and aExchCharVal5 is null) then
          aError  := '006';   -- Valeur de caractérisation manquante.
        else   --
          aStkMvtExchInID  := GetNewID;
          STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId   => aStkMvtExchInID
                                          , iGoodId             => aExchGoodId
                                          , iMovementKindId     => gMvtExchInID
                                          , iExerciseId         => gMvtExerciseId
                                          , iPeriodId           => gMvtPeriodId
                                          , iMvtDate            => gMvtDate
                                          , iStockId            => aExchStockId
                                          , iLocationId         => aExchLocId
                                          , iThirdId            => null
                                          , iRecordId           => null
                                          , iChar1Id            => aExchCharac1Id
                                          , iChar2Id            => aExchCharac2Id
                                          , iChar3Id            => aExchCharac3Id
                                          , iChar4Id            => aExchCharac4Id
                                          , iChar5Id            => aExchCharac5Id
                                          , iCharValue1         => aExchCharVal1
                                          , iCharValue2         => aExchCharVal2
                                          , iCharValue3         => aExchCharVal3
                                          , iCharValue4         => aExchCharVal4
                                          , iCharValue5         => aExchCharVal5
                                          , iWording            => gMvtWording
                                          , iMvtQty             => aConsumedQty
                                          , iMvtPrice           => aExchCostPrice * aConsumedQty
                                          , iUnitPrice          => aExchCostPrice
                                          , iRefUnitPrice       => aExchCostPrice
                                          , iIntervDetID        => aIntervDetID
                                           );
        end if;

        if     (aError is null)
           and (aStkMvtExchInID is null) then
          aError  := '004';   -- Le mouvement d'échange n'a pas pu être généré
        end if;
      exception
        when others then
          aError  := nvl(aError, '004');   -- Le mouvement d'échange n'a pas pu être généré
      end;
    end if;
  end GenerateAllMvt;

  procedure GenerateAllMvt(aASA_INTERVENTION_DETAIL_ID in ASA_INTERVENTION_DETAIL.ASA_INTERVENTION_DETAIL_ID%type, aError out varchar2)
  is
    vStkMvtConsId              ASA_INTERVENTION_DETAIL.STM_STOCK_MVT_CONS_ID%type;
    vStkMvtReturnId            ASA_INTERVENTION_DETAIL.STM_STOCK_MVT_RETURN_ID%type;
    vStkMvtReturn2Id           ASA_INTERVENTION_DETAIL.STM_STOCK_MVT_RETURN_ID%type;
    vStkMvtExchInId            ASA_INTERVENTION_DETAIL.STM_STOCK_MVT_EXCH_IN_ID%type;
    vStkMvtExchOutId           ASA_INTERVENTION_DETAIL.STM_STOCK_MVT_EXCH_OUT_ID%type;
    tplASA_INTERVENTION_DETAIL ASA_INTERVENTION_DETAIL%rowtype;
  begin
    select *
      into tplASA_INTERVENTION_DETAIL
      from ASA_INTERVENTION_DETAIL
     where ASA_INTERVENTION_DETAIL_ID = aASA_INTERVENTION_DETAIL_ID;

    InitMvtInfo(tplASA_INTERVENTION_DETAIL.ASA_INTERVENTION_ID);
    GenerateAllMvt(aIntervDetID        => tplASA_INTERVENTION_DETAIL.ASA_INTERVENTION_DETAIL_ID
                 , aStockMovementId    => vStkMvtReturnId
                 , aStockMovement2Id   => vStkMvtReturn2Id
                 , aStockMovement3Id   => vStkMvtConsId
                 , aStkMvtExchInID     => vStkMvtExchInId
                 , aGoodID             => tplASA_INTERVENTION_DETAIL.GCO_GOOD_ID
                 , aStockFromId        => tplASA_INTERVENTION_DETAIL.AID_STOCK_FROM_ID
                 , aLocationFromId     => tplASA_INTERVENTION_DETAIL.AID_LOCATION_FROM_ID
                 , aStockToId          => tplASA_INTERVENTION_DETAIL.AID_STOCK_TO_ID
                 , aLocationToId       => tplASA_INTERVENTION_DETAIL.AID_LOCATION_TO_ID
                 , aReturnStockId      => tplASA_INTERVENTION_DETAIL.AID_RETURN_STOCK_ID
                 , aReturnLocationId   => tplASA_INTERVENTION_DETAIL.AID_RETURN_LOCATION_ID
                 , aConsumedQty        => tplASA_INTERVENTION_DETAIL.AID_CONSUMED_QUANTITY
                 , aReturnQty          => tplASA_INTERVENTION_DETAIL.AID_RETURNED_QUANTITY
                 , aUnitPrice          => tplASA_INTERVENTION_DETAIL.AID_COST_PRICE
                 , aCharac1Id          => tplASA_INTERVENTION_DETAIL.GCO_CHAR1_ID
                 , aCharac2Id          => tplASA_INTERVENTION_DETAIL.GCO_CHAR2_ID
                 , aCharac3Id          => tplASA_INTERVENTION_DETAIL.GCO_CHAR3_ID
                 , aCharac4Id          => tplASA_INTERVENTION_DETAIL.GCO_CHAR4_ID
                 , aCharac5Id          => tplASA_INTERVENTION_DETAIL.GCO_CHAR5_ID
                 , aCharVal1           => tplASA_INTERVENTION_DETAIL.AID_CHAR1_VALUE
                 , aCharVal2           => tplASA_INTERVENTION_DETAIL.AID_CHAR2_VALUE
                 , aCharVal3           => tplASA_INTERVENTION_DETAIL.AID_CHAR3_VALUE
                 , aCharVal4           => tplASA_INTERVENTION_DETAIL.AID_CHAR4_VALUE
                 , aCharVal5           => tplASA_INTERVENTION_DETAIL.AID_CHAR5_VALUE
                 , aExchange           => tplASA_INTERVENTION_DETAIL.AID_EXCHANGE
                 , aExchGoodId         => tplASA_INTERVENTION_DETAIL.GCO_GOOD_EXCH_ID
                 , aExchCostPrice      => tplASA_INTERVENTION_DETAIL.AID_EXCH_COST_PRICE
                 , aExchStockId        => tplASA_INTERVENTION_DETAIL.STM_EXCH_STOCK_ID
                 , aExchLocId          => tplASA_INTERVENTION_DETAIL.STM_EXCH_LOCATION_ID
                 , aExchCharac1Id      => tplASA_INTERVENTION_DETAIL.GCO_EXCH_CHAR1_ID
                 , aExchCharac2Id      => tplASA_INTERVENTION_DETAIL.GCO_EXCH_CHAR2_ID
                 , aExchCharac3Id      => tplASA_INTERVENTION_DETAIL.GCO_EXCH_CHAR3_ID
                 , aExchCharac4Id      => tplASA_INTERVENTION_DETAIL.GCO_EXCH_CHAR4_ID
                 , aExchCharac5Id      => tplASA_INTERVENTION_DETAIL.GCO_EXCH_CHAR5_ID
                 , aExchCharVal1       => tplASA_INTERVENTION_DETAIL.AID_EXCH_CHAR1_VALUE
                 , aExchCharVal2       => tplASA_INTERVENTION_DETAIL.AID_EXCH_CHAR2_VALUE
                 , aExchCharVal3       => tplASA_INTERVENTION_DETAIL.AID_EXCH_CHAR3_VALUE
                 , aExchCharVal4       => tplASA_INTERVENTION_DETAIL.AID_EXCH_CHAR4_VALUE
                 , aExchCharVal5       => tplASA_INTERVENTION_DETAIL.AID_EXCH_CHAR5_VALUE
                 , aError              => aError
                  );

    if (aError is null) then
      -- mise à jour du détail
      update ASA_INTERVENTION_DETAIL
         set AID_MOVEMENT_DONE = 1
           , STM_STOCK_MVT_CONS_ID = case tplASA_INTERVENTION_DETAIL.AID_EXCHANGE
                                      when 0 then vStkMvtConsId
                                      else null
                                    end
           , STM_STOCK_MVT_RETURN_ID = vStkMvtReturnId
           , STM_STOCK_MVT_EXCH_IN_ID = case tplASA_INTERVENTION_DETAIL.AID_EXCHANGE
                                         when 1 then vStkMvtExchInId
                                         else null
                                       end
           , STM_STOCK_MVT_EXCH_OUT_ID = case tplASA_INTERVENTION_DETAIL.AID_EXCHANGE
                                          when 1 then vStkMvtConsId
                                          else null
                                        end
       where ASA_INTERVENTION_DETAIL_ID = aASA_INTERVENTION_DETAIL_ID;
    end if;
  end GenerateAllMvt;

  /**
  * Description
  *    Mise à jour des infos de l'intervention et génération des mouvements
  */
  procedure UpdateMvtIntervDet(
    aInterventionDetailID in out ASA_INTERVENTION_DETAIL.ASA_INTERVENTION_DETAIL_ID%type
  , aReturnStockId        in     ASA_INTERVENTION_DETAIL.AID_RETURN_STOCK_ID%type
  , aReturnLocationId     in     ASA_INTERVENTION_DETAIL.AID_RETURN_LOCATION_ID%type
  , aConsumedQty          in     ASA_INTERVENTION_DETAIL.AID_CONSUMED_QUANTITY%type
  , aReturnQty            in     ASA_INTERVENTION_DETAIL.AID_RETURNED_QUANTITY%type
  , aKeptQty              in     ASA_INTERVENTION_DETAIL.AID_KEPT_QUANTITY%type
  , aUnitPrice            in     ASA_INTERVENTION_DETAIL.AID_UNIT_PRICE%type
  , aCostPrice            in     ASA_INTERVENTION_DETAIL.AID_COST_PRICE%type
  , aExchange             in     ASA_INTERVENTION_DETAIL.AID_EXCHANGE%type default null
  , aExchGoodId           in     ASA_INTERVENTION_DETAIL.GCO_GOOD_EXCH_ID%type default null
  , aExchCostPrice        in     ASA_INTERVENTION_DETAIL.AID_EXCH_COST_PRICE%type default null
  , aExchStockID          in     ASA_INTERVENTION_DETAIL.STM_EXCH_STOCK_ID%type default null
  , aExchLocID            in     ASA_INTERVENTION_DETAIL.STM_EXCH_LOCATION_ID%type default null
  , aStockToID            in     ASA_INTERVENTION_DETAIL.AID_STOCK_TO_ID%type default null
  , aLocationToID         in     ASA_INTERVENTION_DETAIL.AID_LOCATION_TO_ID%type default null
  , aGenMvt               in     number
  , aModified             in     number
  , aError                out    varchar2
  )
  is
    tplIntervDet      ASA_INTERVENTION_DETAIL%rowtype;
    vStockMovementId  STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
    vStockMovement2Id STM_STOCK_MOVEMENT.STM_STM_STOCK_MOVEMENT_ID%type;
    vStockMovement3Id STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
    vStkMvtExchInId   ASA_INTERVENTION_DETAIL.STM_STOCK_MVT_EXCH_IN_ID%type;
    vControlStatus    number;
  begin
    if aModified = 1 then
      -- Mise à jour de la quantité facturable du détail d'intervention
      UpdateInvoicingQty(aInterventionDetailID, aConsumedQty);

      -- Mise à jour avec les infos saisies par l'utilisateur si différentes
      update ASA_INTERVENTION_DETAIL
         set AID_RETURN_STOCK_ID = case
                                    when aReturnStockId = 0 then null
                                    else aReturnStockId
                                  end
           , AID_RETURN_LOCATION_ID = case
                                       when aReturnLocationId = 0 then null
                                       else aReturnLocationId
                                     end
           , AID_CONSUMED_QUANTITY = aConsumedQty
           , AID_RETURNED_QUANTITY = aReturnQty
           , AID_KEPT_QUANTITY = aKeptQty
           , AID_UNIT_PRICE = aUnitPrice
           , AID_COST_PRICE = aCostPrice
           , AID_EXCHANGE = nvl(aExchange, 0)
           , GCO_GOOD_EXCH_ID = case
                                 when aExchGoodId = 0 then null
                                 else aExchGoodId
                               end
           , STM_EXCH_STOCK_ID = case
                                  when aExchStockID = 0 then null
                                  else aExchStockID
                                end
           , STM_EXCH_LOCATION_ID = case
                                     when aExchLocID = 0 then null
                                     else aExchLocID
                                   end
           , AID_STOCK_TO_ID = case
                                when aStockToID = 0 then null
                                else aStockToID
                              end
           , AID_LOCATION_TO_ID = case
                                   when aLocationToID = 0 then null
                                   else aLocationToID
                                 end
           , AID_EXCH_COST_PRICE = aExchCostPrice
           , A_DATEMOD = sysdate
           , A_IDMOD = pcs.PC_I_LIB_SESSION.GetUserIni
       where ASA_INTERVENTION_DETAIL_ID = aInterventionDetailID
         and (   nvl(AID_RETURN_LOCATION_ID, 0) <> nvl(aReturnLocationId, 0)
              or nvl(AID_CONSUMED_QUANTITY, 0) <> nvl(aConsumedQty, 0)
              or nvl(AID_RETURNED_QUANTITY, 0) <> nvl(aReturnQty, 0)
              or nvl(AID_KEPT_QUANTITY, 0) <> nvl(aKeptQty, 0)
              or nvl(AID_UNIT_PRICE, 0) <> nvl(aUnitPrice, 0)
              or nvl(AID_COST_PRICE, 0) <> nvl(aCostPrice, 0)
              or nvl(AID_EXCHANGE, 0) <> nvl(aExchange, 0)
              or nvl(STM_EXCH_LOCATION_ID, 0) <> nvl(aExchLocID, 0)
              or nvl(STM_EXCH_STOCK_ID, 0) <> nvl(aExchStockID, 0)
              or nvl(AID_EXCH_COST_PRICE, 0) <> nvl(aExchCostPrice, 0)
              or nvl(AID_LOCATION_TO_ID, 0) <> nvl(aLocationToID, 0)
              or nvl(AID_STOCK_TO_ID, 0) <> nvl(aStockToID, 0)
             );
    end if;

    if aGenMvt = 1 then
      -- Récupération des infos du détail
      select *
        into tplIntervDet
        from ASA_INTERVENTION_DETAIL
       where ASA_INTERVENTION_DETAIL_ID = aInterventionDetailID;

      -- si les transferts n'ont pas été effectuée
      if tplIntervDet.AID_TRANSFER_DONE = 0 then
        null;
      end if;

      -- Contrôle des statuts de la mission et de l'intervention
      select count(*)
        into vControlStatus
        from ASA_MISSION MIS
           , ASA_INTERVENTION ITR
       where MIS.ASA_MISSION_ID = ITR.ASA_MISSION_ID
         and ITR.ASA_INTERVENTION_ID = tplIntervDet.ASA_INTERVENTION_ID
         and ITR.C_ASA_ITR_STATUS <> '00'
         and MIS.C_ASA_MIS_STATUS <> '00';

      if vControlStatus = 0 then
        aError  := '004';   -- Statut de la mission ou de l'intervention = "provisoire"
      else
        begin
          if tplIntervDet.AID_MOVEMENT_DONE = 0 then
            -- Génération des mouvements du détail
            GenerateAllMvt(aASA_INTERVENTION_DETAIL_ID => tplIntervDet.ASA_INTERVENTION_DETAIL_ID, aError => aError);
          else
            aError  := '002';   -- Mouvement déjà généré
          end if;
        exception
          when others then
            RAISE_APPLICATION_ERROR(to_number(to_char(-20) || aError), 'PCS error !');
        end;
      end if;
    end if;

    if aError is not null then
      RAISE_APPLICATION_ERROR(to_number(to_char(-20) || aError), 'PCS error !');
    end if;
  end UpdateMvtIntervDet;

  /**
  * Description
  *    Protection ou déprotection de la mission
  */
  procedure ProtectMission(aMissionID in ASA_MISSION.ASA_MISSION_ID%type, aProtect in number default 1, aInvJobID in number default null)
  is
    pragma autonomous_transaction;
  begin
    update ASA_MISSION
       set MIS_PROTECTED = aProtect
         , ASA_INVOICING_JOB_ID = aInvJobID
         , A_DATEMOD = sysdate
         , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where ASA_MISSION_ID = aMissionID;

    commit;   /* Car on utilise une transaction autonome */
  end ProtectMission;

  /**
  * Description
  *    Initialisation de la quantité facturable du détail d'intervention
  */
  procedure InitInvoicingQty(
    aInterventionID in     ASA_INTERVENTION.ASA_INTERVENTION_ID%type
  , aGoodID         in     ASA_INTERVENTION_DETAIL.GCO_GOOD_ID%type
  , aConsumedQty    in     ASA_INTERVENTION_DETAIL.AID_CONSUMED_QUANTITY%type
  , aInvoicingQty   out    ASA_INTERVENTION_DETAIL.AID_INVOICING_QTY%type
  , aCMLDetID       out    CML_POSITION_SERVICE_DETAIL.CML_POSITION_SERVICE_DETAIL_ID%type
  )
  is
    cursor crDetail(aMissionID ASA_MISSION.ASA_MISSION_ID%type)
    is
      select case
               when CPD.C_SERVICE_RENEWAL in('1', '2') then case
                                                             when CPD.CPD_BALANCE_QTY >= aConsumedQty then 0
                                                             else case
                                                             when CPD.CPD_BALANCE_QTY > 0 then aConsumedQty - CPD.CPD_BALANCE_QTY
                                                             else aConsumedQty
                                                           end
                                                           end
               else 0
             end AID_INVOICING_QTY
           , CPD.CML_POSITION_SERVICE_DETAIL_ID
           , CPD.CPD_SQL_CONDITION
        from CML_POSITION CPO
           , CML_POSITION_MACHINE CPM
           , CML_POSITION_SERVICE CPS
           , CML_POSITION_SERVICE_DETAIL CPD
           , GCO_GOOD SER
           , ASA_MISSION MIS
       where MIS.CML_POSITION_ID = CPO.CML_POSITION_ID
         and CPO.CML_POSITION_ID = CPM.CML_POSITION_ID
         and CPO.CML_POSITION_ID = CPS.CML_POSITION_ID
         and CPS.GCO_CML_SERVICE_ID = SER.GCO_GOOD_ID
         and CPS.CML_POSITION_SERVICE_ID = CPD.CML_POSITION_SERVICE_ID
         and CPM.DOC_RCO_MACHINE_ID = MIS.ASA_MACHINE_ID
         and MIS.ASA_MISSION_ID = aMissionID
         and SER.C_SERVICE_KIND = '2'
         and nvl(CPD.CPD_EXPIRY_DATE, sysdate) >= nvl(MIS.MIS_REQUEST_DATE, sysdate)
         and (   CPD.GCO_GOOD_ID = aGoodID
              or CPD.GCO_GOOD_ID is null);

    tplDetail     crDetail%rowtype;
    vMissionID    ASA_MISSION.ASA_MISSION_ID%type;
    vGoodID       GCO_GOOD.GCO_GOOD_ID%type;
    vScriptBuffer varchar2(32767);
    vLength       integer;
    vContinue     number(1);
  begin
    -- Recherche de la mission à laquelle se rapporte l'intervention
    select ASA_MISSION_ID
      into vMissionID
      from ASA_INTERVENTION
     where ASA_INTERVENTION_ID = aInterventionId;

    -- on prend le premier détail de contrat qui remplit les conditions de l'intervention
    open crDetail(vMissionID);

    fetch crDetail
     into tplDetail;

    -- Le bien n'est pas référencé
    aInvoicingQty  := aConsumedQty;
    aCMLDetID      := 0;
    vContinue      := 1;

    while crDetail%found
     and vContinue = 1 loop
      -- Prestations conditionnelle (il faut que le bien vérifie la condition)
      if tplDetail.CPD_SQL_CONDITION is not null then
        vLength  := DBMS_LOB.GetLength(tplDetail.CPD_SQL_CONDITION);

        if vLength > 32767 then
          Raise_application_error(-20001, 'PCS - CONDITION script length out of range !');
        end if;

        if vLength > 0 then
          DBMS_LOB.read(tplDetail.CPD_SQL_CONDITION, vLength, 1, vScriptBuffer);
          vScriptBuffer  := 'select GCO_GOOD_ID' || '  from (' || vScriptBuffer || ')' || ' where GCO_GOOD_ID = ' || aGoodID;

          begin
            execute immediate vScriptBuffer
                         into vGoodID;
          exception
            -- le bien n'est pas référencé
            when no_data_found then
              vGoodID  := null;
            -- la condition est invalide
            when others then
              Raise_application_error(-20001, 'PCS - Mission Management : Invalid application condition (CPD_SQL_CONDITION)!');
          end;

          -- si le bien est référencé on s'arrête à ce détail, sinon on vérifie sur les détails suivants
          if vGoodID is not null then
            vContinue  := 0;
          end if;
        end if;
      else
        -- si la prestation n'est pas conditionnelle, on s'arrête à ce détail
        vContinue  := 0;
      end if;

      if vContinue = 0 then
        aInvoicingQty  := tplDetail.AID_INVOICING_QTY;
        aCMLDetID      := tplDetail.CML_POSITION_SERVICE_DETAIL_ID;
      end if;

      fetch crDetail
       into tplDetail;
    end loop;
  end InitInvoicingQty;

  /**
  * Description
  *   Mise à jour de la quantité facturable du détail d'intervention
  */
  procedure UpdateInvoicingQty(
    aInterventionDetailID in ASA_INTERVENTION_DETAIL.ASA_INTERVENTION_DETAIL_ID%type
  , aConsumedQty          in ASA_INTERVENTION_DETAIL.AID_CONSUMED_QUANTITY%type
  )
  is
    vInterventionID ASA_INTERVENTION.ASA_INTERVENTION_ID%type;
    vGoodID         ASA_INTERVENTION_DETAIL.GCO_GOOD_ID%type;
    vInvoicingQty   ASA_INTERVENTION_DETAIL.AID_INVOICING_QTY%type;
    vCMLDetID       CML_POSITION_SERVICE_DETAIL.CML_POSITION_SERVICE_DETAIL_ID%type;
    vConsumedQty    ASA_INTERVENTION_DETAIL.AID_CONSUMED_QUANTITY%type;
  begin
    -- Initialisation des variables
    select ASA_INTERVENTION_ID
         , nvl(GCO_GOOD_ID, GCO_SERVICE_ID)
         , nvl(AID_CONSUMED_QUANTITY, 0)
      into vInterventionID
         , vGoodID
         , vConsumedQty
      from ASA_INTERVENTION_DETAIL
     where ASA_INTERVENTION_DETAIL_ID = aInterventionDetailID;

    -- La quantité facturable n'est modifiée que si une nouvelle quantité consommée a été saisie
    if vConsumedQty <> aConsumedQty then
      -- Initialisation de la quantité facturable
      InitInvoicingQty(vInterventionID, vGoodID, aConsumedQty, vInvoicingQty, vCMLDetID);

      -- Mise à jour des quantité facturables et du détail de prestation
      update ASA_INTERVENTION_DETAIL
         set AID_CALC_INVOICING_QTY = vInvoicingQty
           , AID_INVOICING_QTY = nvl(AID_INVOICING_QTY, vInvoicingQty)
           , CML_POSITION_SERVICE_DETAIL_ID = case
                                               when nvl(vCMLDetID, 0) <> 0 then vCMLDetID
                                               else CML_POSITION_SERVICE_DETAIL_ID
                                             end
       where ASA_INTERVENTION_DETAIL_ID = aInterventionDetailID;
    end if;
  end UpdateInvoicingQty;

  /**
  * Description
  *    Traitement des prestations contractuelles liées à l'intervention lors de la clôture de celle-ci
  */
  procedure UpdateContractOnTerminate(aInterventionID in ASA_INTERVENTION.ASA_INTERVENTION_ID%type)
  is
    vCPD_CONSUMED_QTY       CML_POSITION_SERVICE_DETAIL.CPD_CONSUMED_QTY%type;
    vCPD_BALANCE_QTY        CML_POSITION_SERVICE_DETAIL.CPD_BALANCE_QTY%type;
    vAID_CALC_INVOICING_QTY ASA_INTERVENTION_DETAIL.AID_CALC_INVOICING_QTY%type;
  begin
    -- Recherche de tous les détails liés à un détail de prestation contrat dont le code de renouvellement <> 3
    for crDetail in (select nvl(AID.AID_CALC_INVOICING_QTY, 0) AID_CALC_INVOICING_QTY
                          , nvl(AID.AID_INVOICING_QTY, 0) AID_INVOICING_QTY
                          , AID.CML_POSITION_SERVICE_DETAIL_ID
                          , nvl(AID.AID_CONSUMED_QUANTITY, 0) AID_CONSUMED_QTY
                          , nvl(CPD.CPD_CONSUMED_QTY, 0) CPD_CONSUMED_QTY
                          , nvl(CPD.CPD_BALANCE_QTY, 0) CPD_BALANCE_QTY
                          , AID.AID_FIXED_INVOICING
                          , AID.ASA_INTERVENTION_DETAIL_ID
                       from ASA_INTERVENTION_DETAIL AID
                          , CML_POSITION_SERVICE_DETAIL CPD
                      where AID.ASA_INTERVENTION_ID = aInterventionID
                        and AID.CML_POSITION_SERVICE_DETAIL_ID = CPD.CML_POSITION_SERVICE_DETAIL_ID
                        and CPD.C_SERVICE_RENEWAL <> '3') loop
      -- Nouvelle qté solde
      vCPD_CONSUMED_QTY  := crDetail.CPD_CONSUMED_QTY + crDetail.AID_CONSUMED_QTY;

      -- Si l'utilisateur a saisi une quantité à facturer
      if crDetail.AID_CALC_INVOICING_QTY <> crDetail.AID_INVOICING_QTY then
        vCPD_BALANCE_QTY  := crDetail.CPD_BALANCE_QTY -(crDetail.AID_CONSUMED_QTY - crDetail.AID_INVOICING_QTY);
      else
        if crDetail.CPD_BALANCE_QTY <(crDetail.AID_CONSUMED_QTY - crDetail.AID_INVOICING_QTY) then
          vAID_CALC_INVOICING_QTY  := crDetail.AID_CONSUMED_QTY - crDetail.CPD_BALANCE_QTY;
          vCPD_BALANCE_QTY         := 0;
        else
          vAID_CALC_INVOICING_QTY  := 0;
          vCPD_BALANCE_QTY         := crDetail.CPD_BALANCE_QTY - crDetail.AID_CONSUMED_QTY;
        end if;
      end if;

      if vCPD_BALANCE_QTY < 0 then
        vCPD_BALANCE_QTY  := 0;
      end if;

      if    (vCPD_CONSUMED_QTY <> crDetail.CPD_CONSUMED_QTY)
         or (vCPD_BALANCE_QTY <> crDetail.CPD_BALANCE_QTY) then
        update CML_POSITION_SERVICE_DETAIL
           set CPD_CONSUMED_QTY = vCPD_CONSUMED_QTY
             , CPD_BALANCE_QTY = vCPD_BALANCE_QTY
         where CML_POSITION_SERVICE_DETAIL_ID = crDetail.CML_POSITION_SERVICE_DETAIL_ID;
      end if;

      -- Mise à jour de la qté solde du détail d'intervention avant mise à jour de la qté solde du détail prestation
      -- Mise à jour de la quantité facturable (calculée et/ou manuelle)
      if crDetail.AID_FIXED_INVOICING = 0 then
        update ASA_INTERVENTION_DETAIL
           set AID_BALANCE_QTY = crDetail.CPD_BALANCE_QTY
             , AID_CALC_INVOICING_QTY = vAID_CALC_INVOICING_QTY
             , AID_INVOICING_QTY = vAID_CALC_INVOICING_QTY
         where ASA_INTERVENTION_DETAIL_ID = crDetail.ASA_INTERVENTION_DETAIL_ID;
      else
        update ASA_INTERVENTION_DETAIL
           set AID_BALANCE_QTY = crDetail.CPD_BALANCE_QTY
             , AID_CALC_INVOICING_QTY = vAID_CALC_INVOICING_QTY
         where ASA_INTERVENTION_DETAIL_ID = crDetail.ASA_INTERVENTION_DETAIL_ID;
      end if;
    end loop;
  end UpdateContractOnTerminate;

  /**
  * Description
  *   Copie du détail de l'intervention
  */
  procedure DuplicateIntervDet(aSrcIntervID in ASA_INTERVENTION.ASA_INTERVENTION_ID%type, aTgtIntervID in ASA_INTERVENTION.ASA_INTERVENTION_ID%type)
  is
    lnSeq ASA_INTERVENTION_DETAIL.AID_NUMBER%type;
  begin
    -- On est obligé de faire une boucle avec ce curseur à cause de la recherche du n° de séquence
    --  Au lieu de faire un insert/select
    for ltplDetail in (select   sign(nvl(AID.GCO_SERVICE_ID, 0) ) DETAIL_SERVICE
                              , AID.*
                           from ASA_INTERVENTION_DETAIL AID
                          where AID.ASA_INTERVENTION_ID = aSrcIntervID
                       order by DETAIL_SERVICE asc
                              , AID.AID_NUMBER asc) loop
      -- N° de séquence
      lnSeq  := GetDetailSequence(iInterventionID => aTgtIntervID, iService => ltplDetail.DETAIL_SERVICE);

      insert into ASA_INTERVENTION_DETAIL
                  (ASA_INTERVENTION_DETAIL_ID
                 , ASA_INTERVENTION_ID
                 , AID_NUMBER
                 , GCO_GOOD_ID
                 , GCO_SERVICE_ID
                 , GCO_CHAR1_ID
                 , GCO_CHAR2_ID
                 , GCO_CHAR3_ID
                 , GCO_CHAR4_ID
                 , GCO_CHAR5_ID
                 , AID_STOCK_FROM_ID
                 , AID_STOCK_TO_ID
                 , AID_LOCATION_FROM_ID
                 , AID_LOCATION_TO_ID
                 , AID_RETURN_STOCK_ID
                 , AID_RETURN_LOCATION_ID
                 , AID_TAKEN_QUANTITY
                 , AID_TRANSFER_DONE
                 , AID_CONSUMED_QUANTITY
                 , AID_RETURNED_QUANTITY
                 , AID_KEPT_QUANTITY
                 , AID_MOVEMENT_DONE
                 , AID_UNIT_PRICE
                 , AID_COST_PRICE
                 , AID_CHAR1_VALUE
                 , AID_CHAR2_VALUE
                 , AID_CHAR3_VALUE
                 , AID_CHAR4_VALUE
                 , AID_CHAR5_VALUE
                 , CML_POSITION_SERVICE_DETAIL_ID
                 , AID_CALC_INVOICING_QTY
                 , AID_BALANCE_QTY
                 , AID_INVOICING_QTY
                 , AID_FIXED_INVOICING
                 , AID_SHORT_DESCR
                 , AID_LONG_DESCR
                 , AID_FREE_DESCR
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (init_id_seq.nextval
                 , aTgtIntervID
                 , lnSeq   -- AID_NUMBER
                 , ltplDetail.GCO_GOOD_ID
                 , ltplDetail.GCO_SERVICE_ID
                 , ltplDetail.GCO_CHAR1_ID
                 , ltplDetail.GCO_CHAR2_ID
                 , ltplDetail.GCO_CHAR3_ID
                 , ltplDetail.GCO_CHAR4_ID
                 , ltplDetail.GCO_CHAR5_ID
                 , ltplDetail.AID_STOCK_FROM_ID
                 , ltplDetail.AID_STOCK_TO_ID
                 , ltplDetail.AID_LOCATION_FROM_ID
                 , ltplDetail.AID_LOCATION_TO_ID
                 , ltplDetail.AID_RETURN_STOCK_ID
                 , ltplDetail.AID_RETURN_LOCATION_ID
                 , ltplDetail.AID_TAKEN_QUANTITY
                 , 0   -- AID_TRANSFER_DONE
                 , ltplDetail.AID_CONSUMED_QUANTITY
                 , ltplDetail.AID_RETURNED_QUANTITY
                 , ltplDetail.AID_KEPT_QUANTITY
                 , 0   -- AID_MOVEMENT_DONE
                 , ltplDetail.AID_UNIT_PRICE
                 , ltplDetail.AID_COST_PRICE
                 , ltplDetail.AID_CHAR1_VALUE
                 , ltplDetail.AID_CHAR2_VALUE
                 , ltplDetail.AID_CHAR3_VALUE
                 , ltplDetail.AID_CHAR4_VALUE
                 , ltplDetail.AID_CHAR5_VALUE
                 , null   -- CML_POSITION_SERVICE_DETAIL_ID
                 , ltplDetail.AID_CALC_INVOICING_QTY
                 , ltplDetail.AID_BALANCE_QTY
                 , ltplDetail.AID_INVOICING_QTY
                 , ltplDetail.AID_FIXED_INVOICING
                 , ltplDetail.AID_SHORT_DESCR
                 , ltplDetail.AID_LONG_DESCR
                 , ltplDetail.AID_FREE_DESCR
                 , sysdate   -- A_DATECRE
                 , pcs.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
                  );
    end loop;
  end DuplicateIntervDet;

  /**
  * Description
  *   Mise à jour de la mission lors de l'attribution des missions
  */
  procedure UpdateMissionOnAllocate(aMissionID in ASA_MISSION.ASA_MISSION_ID%type, aPersonID in ASA_MISSION.MIS_RESPONSIBLE_PERSON_ID%type)
  is
    vBeforeProc ASA_MISSION_TYPE.MIT_PROC_BEFORE_CONFIRM%type;
    vAfterProc  ASA_MISSION_TYPE.MIT_PROC_BEFORE_CONFIRM%type;
    aErrorText  varchar2(4000);
  begin
    select MIT.MIT_PROC_BEFORE_CONFIRM
         , MIT.MIT_PROC_AFTER_CONFIRM
      into vBeforeProc
         , vAfterProc
      from ASA_MISSION_TYPE MIT
         , ASA_MISSION MIS
     where MIT.ASA_MISSION_TYPE_ID = MIS.ASA_MISSION_TYPE_ID
       and MIS.ASA_MISSION_ID = aMissionID;

    -- Procédure avant confirmation
    if vBeforeProc is not null then
      DOC_FUNCTIONS.ExecuteExternProc(aMissionID, vBeforeProc, aErrorText);

      -- Arreter la confirmation si le contrôle utilisateur a échoué
      if instr(aErrorText, '[ABORT]') > 0 then
        aErrorText  := aErrorText || ' - Before confirm';
        raise_application_error(-20000, aErrorText);
      end if;
    end if;

    -- Mise à jour de la mission
    update ASA_MISSION
       set MIS_RESPONSIBLE_PERSON_ID = aPersonID
         , C_ASA_MIS_STATUS = '01'
         , MIS_PC_USER_ID = PCS.PC_I_LIB_SESSION.GETUSERID
         , MIS_ALLOCATION_DATE = sysdate
     where ASA_MISSION_ID = aMissionID;

    -- Procédure après confirmation
    if vAfterProc is not null then
      DOC_FUNCTIONS.ExecuteExternProc(aMissionID, vAfterProc, aErrorText);
    end if;

    -- Mise à jour des interventions
    update ASA_INTERVENTION
       set ITR_PERSON_ID = aPersonID
     where ASA_MISSION_ID = aMissionID
       and ITR_PERSON_ID is null;
  end UpdateMissionOnAllocate;

  /**
  * Description
  *   Ajout d'un nouveau détail
  */
  procedure InsertDetOnDebriefing(
    aInterventionDetailID in ASA_INTERVENTION_DETAIL.ASA_INTERVENTION_DETAIL_ID%type
  , aInterventionID       in ASA_INTERVENTION_DETAIL.ASA_INTERVENTION_ID%type
  , aGoodID               in ASA_INTERVENTION_DETAIL.GCO_GOOD_ID%type
  , aStockToID            in ASA_INTERVENTION_DETAIL.AID_STOCK_TO_ID%type
  , aLocationToID         in ASA_INTERVENTION_DETAIL.AID_LOCATION_TO_ID%type
  , aReturnStockID        in ASA_INTERVENTION_DETAIL.AID_RETURN_STOCK_ID%type
  , aReturnLocationID     in ASA_INTERVENTION_DETAIL.AID_RETURN_LOCATION_ID%type
  , aConsumedQty          in ASA_INTERVENTION_DETAIL.AID_CONSUMED_QUANTITY%type
  , aReturnedQty          in ASA_INTERVENTION_DETAIL.AID_RETURNED_QUANTITY%type
  , aKeptQty              in ASA_INTERVENTION_DETAIL.AID_KEPT_QUANTITY%type
  , aUnitPrice            in ASA_INTERVENTION_DETAIL.AID_UNIT_PRICE%type
  , aCostPrice            in ASA_INTERVENTION_DETAIL.AID_COST_PRICE%type
  , aExchange             in ASA_INTERVENTION_DETAIL.AID_EXCHANGE%type default null
  , aExchGoodId           in ASA_INTERVENTION_DETAIL.GCO_GOOD_EXCH_ID%type default null
  , aExchCostPrice        in ASA_INTERVENTION_DETAIL.AID_EXCH_COST_PRICE%type default null
  , aExchStockID          in ASA_INTERVENTION_DETAIL.STM_EXCH_STOCK_ID%type default null
  , aExchLocID            in ASA_INTERVENTION_DETAIL.STM_EXCH_LOCATION_ID%type default null
  )
  is
    vInvoicingQty         ASA_INTERVENTION_DETAIL.AID_INVOICING_QTY%type;
    vCMLDetID             CML_POSITION_SERVICE_DETAIL.CML_POSITION_SERVICE_DETAIL_ID%type;
    vPDT_STOCK_MANAGEMENT GCO_PRODUCT.PDT_STOCK_MANAGEMENT%type;
    vExchStockMgm         GCO_PRODUCT.PDT_STOCK_MANAGEMENT%type;
    lnSeq                 ASA_INTERVENTION_DETAIL.AID_NUMBER%type;
    lnLangID              PCS.PC_LANG.PC_LANG_ID%type;
    lvShortDescr          ASA_INTERVENTION_DETAIL.AID_SHORT_DESCR%type;
    lvLongDescr           ASA_INTERVENTION_DETAIL.AID_LONG_DESCR%type;
    lvFreeDescr           ASA_INTERVENTION_DETAIL.AID_FREE_DESCR%type;
  begin
    -- Recherche de la quantité facturable
    InitInvoicingQty(aInterventionID, aGoodID, aConsumedQty, vInvoicingQty, vCMLDetID);

    -- Si le bien n'est pas géré en stock, on initialise les stocks avec le stock par défaut
    select nvl(max(PDT_STOCK_MANAGEMENT), 0)
      into vPDT_STOCK_MANAGEMENT
      from GCO_PRODUCT
     where GCO_GOOD_ID = aGoodId;

    -- Si le bien échangé n'est pas géré en stock, on initialise les stocks avec le stock par défaut
    select nvl(max(PDT_STOCK_MANAGEMENT), 0)
      into vExchStockMgm
      from GCO_PRODUCT
     where GCO_GOOD_ID = aExchGoodId;

    -- N° de séquence
    lnSeq  := GetDetailSequence(iInterventionID => aInterventionID, iService => 0);

    -- Langue de la mission pour la recherche des descriptions
    select MIS.PC_LANG_ID
      into lnLangID
      from ASA_MISSION MIS
         , ASA_INTERVENTION ITR
     where ITR.ASA_INTERVENTION_ID = aInterventionID
       and ITR.ASA_MISSION_ID = MIS.ASA_MISSION_ID;

    -- Recherche des descriptions
    ASA_FUNCTIONS.GetGoodDescription(iGoodID       => aGoodID, iLangID => lnLangID, oShortDescr => lvShortDescr, oLongDescr => lvLongDescr
                                   , oFreeDescr    => lvFreeDescr);

    -- Ajout du détail d'intervention
    insert into ASA_INTERVENTION_DETAIL
                (ASA_INTERVENTION_DETAIL_ID
               , ASA_INTERVENTION_ID
               , AID_NUMBER
               , GCO_GOOD_ID
               , AID_STOCK_FROM_ID
               , AID_STOCK_TO_ID
               , AID_LOCATION_TO_ID
               , AID_RETURN_STOCK_ID
               , AID_RETURN_LOCATION_ID
               , AID_CONSUMED_QUANTITY
               , AID_RETURNED_QUANTITY
               , AID_INVOICING_QTY
               , AID_KEPT_QUANTITY
               , AID_UNIT_PRICE
               , AID_COST_PRICE
               , AID_EXCHANGE
               , GCO_GOOD_EXCH_ID
               , AID_EXCH_COST_PRICE
               , STM_EXCH_STOCK_ID
               , STM_EXCH_LOCATION_ID
               , CML_POSITION_SERVICE_DETAIL_ID
               , AID_SHORT_DESCR
               , AID_LONG_DESCR
               , AID_FREE_DESCR
               , A_DATECRE
               , A_IDCRE
                )
         values (aInterventionDetailID
               , aInterventionID
               , lnSeq
               , aGoodID
               , case
                   when vPDT_STOCK_MANAGEMENT = 1 then null
                   else aReturnStockID
                 end   -- AID_STOCK_FROM_ID
               , case
                   when vPDT_STOCK_MANAGEMENT = 1 then aStockToID
                   else aReturnStockID
                 end   -- AID_STOCK_TO_ID
               , case
                   when vPDT_STOCK_MANAGEMENT = 1 then aLocationToID
                   else null
                 end   -- AID_LOCATION_TO_ID
               , case
                   when vPDT_STOCK_MANAGEMENT = 1 then aReturnStockID
                   else aReturnStockID
                 end   -- AID_RETURN_STOCK_ID
               , case
                   when vPDT_STOCK_MANAGEMENT = 1 then aReturnLocationID
                   else null
                 end   -- AID_RETURN_LOCATION_ID
               , aConsumedQty
               , aReturnedQty
               , vInvoicingQty
               , aKeptQty
               , aUnitPrice
               , aCostPrice
               , aExchange
               , aExchGoodId
               , aExchCostPrice
               , case
                   when vExchStockMgm = 1 then aExchStockID
                   else null
                 end   -- STM_EXCH_STOCK_ID
               , case
                   when vExchStockMgm = 1 then aExchLocID
                   else null
                 end   -- STM_EXCH_LOCATION_ID
               , case
                   when vCMLDetID > 0 then vCMLDetID
                   else null
                 end   -- CML_POSITION_SERVICE_DETAIL_ID
               , lvShortDescr   -- AID_SHORT_DESCR
               , lvLongDescr   -- AID_LONG_DESCR
               , lvFreeDescr   -- AID_FREE_DESCR
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end InsertDetOnDebriefing;

  /**
  * Description
  *   Retourne le temps de prise en charge de la mission
  */
  procedure GetInterventionTime(
    aMissionID   in     ASA_MISSION.ASA_MISSION_ID%type
  , aIntervTime  out    ASA_MISSION.MIS_INTERVENTION_TIME%type
  , aRequestDate in     ASA_MISSION.MIS_REQUEST_DATE%type default null
  )
  is
    vStartDate ASA_MISSION.MIS_REQUEST_DATE%type;
    vEndDate   ASA_INTERVENTION.ITR_START_DATE%type;
  begin
    select   case
               when aRequestDate is null then MIS.MIS_REQUEST_DATE
               else aRequestDate
             end
           , min(ITR.ITR_START_DATE)
        into vStartDate
           , vEndDate
        from ASA_MISSION MIS
           , ASA_INTERVENTION ITR
       where ITR.ASA_MISSION_ID = MIS.ASA_MISSION_ID
         and MIS.ASA_MISSION_ID = aMissionID
    group by MIS.MIS_REQUEST_DATE;

    -- Calcul de la durée en heure
    CalcInterventionPeriod(aMissionID, vStartDate, vEndDate, aIntervTime);
  exception
    when no_data_found then
      aIntervTime  := 0;
  end GetInterventionTime;

  /**
  * Description
  *   Retourne le temps de résolution de la mission
  */
  procedure GetResolutionTime(aMissionID in ASA_MISSION.ASA_MISSION_ID%type, aResTime out ASA_MISSION.MIS_RESOLUTION_TIME%type)
  is
    vStartDate ASA_MISSION.MIS_REQUEST_DATE%type;
    vEndDate   ASA_INTERVENTION.ITR_END_DATE%type;
  begin
    select   MIS.MIS_REQUEST_DATE
           , max(ITR.ITR_END_DATE)
        into vStartDate
           , vEndDate
        from ASA_MISSION MIS
           , ASA_INTERVENTION ITR
       where ITR.ASA_MISSION_ID = MIS.ASA_MISSION_ID
         and MIS.ASA_MISSION_ID = aMissionID
    group by MIS.MIS_REQUEST_DATE;

    -- Calcul de la durée en heure
    CalcInterventionPeriod(aMissionID, vStartDate, vEndDate, aResTime);
  exception
    when no_data_found then
      aResTime  := 0;
  end GetResolutionTime;

  /**
  * Description
  *   Retourne le prix unitaire et le prix de revient d'un détail d'intervention
  */
  procedure GetPrices(
    aASA_INTERVENTION_ID   in     ASA_INTERVENTION_DETAIL.ASA_INTERVENTION_ID%type
  , aGCO_GOOD_ID           in     ASA_INTERVENTION_DETAIL.GCO_GOOD_ID%type
  , aAID_CONSUMED_QUANTITY in     ASA_INTERVENTION_DETAIL.AID_CONSUMED_QUANTITY%type
  , aAID_UNIT_PRICE        out    ASA_INTERVENTION_DETAIL.AID_UNIT_PRICE%type
  , aAID_COST_PRICE        out    ASA_INTERVENTION_DETAIL.AID_COST_PRICE%type
  )
  is
    vDIC_TARIFF_ID ASA_MISSION.DIC_TARIFF_ID%type;
  begin
    -- Recherche du code tarif de la mission
    select max(MIS.DIC_TARIFF_ID)
      into vDIC_TARIFF_ID
      from ASA_MISSION MIS
         , ASA_INTERVENTION ITR
     where MIS.ASA_MISSION_ID = ITR.ASA_MISSION_ID
       and ITR.ASA_INTERVENTION_ID = aASA_INTERVENTION_ID;

    if vDIC_TARIFF_ID is null then
      -- Cascade du code tarif de la mission
      select GetTariffID(MIS.ASA_MISSION_TYPE_ID, MIS.CML_POSITION_ID, MIS.PAC_CUSTOM_PARTNER_ID, MIS.PAC_CUSTOM_PARTNER_TARIFF_ID)
        into vDIC_TARIFF_ID
        from ASA_MISSION MIS
           , ASA_INTERVENTION ITR
       where ITR.ASA_MISSION_ID = MIS.ASA_MISSION_ID
         and ITR.ASA_INTERVENTION_ID = aASA_INTERVENTION_ID;
    end if;

    select nvl(GCO_FUNCTIONS.GetGoodPriceForView(aGCO_GOOD_ID
                                               , 2   -- TypePrice
                                               , nvl(MIS.PAC_CUSTOM_PARTNER_TARIFF_ID
                                                   , nvl(CCO.PAC_CUSTOM_PARTNER_TARIFF_ID
                                                       , nvl(CUS.PAC_PAC_THIRD_2_ID
                                                           , nvl(CCO.PAC_CUSTOM_PARTNER_ID, nvl(CUS1.PAC_PAC_THIRD_2_ID, MIS.PAC_CUSTOM_PARTNER_ID) )
                                                            )
                                                        )
                                                    )   -- ThirdId
                                               , MIS.DOC_RECORD_ID
                                               , 0   -- FalScheduleStepId
                                               , vDIC_TARIFF_ID
                                               , aAID_CONSUMED_QUANTITY
                                               , nvl(ITR.ITR_START_DATE, MIS.MIS_REQUEST_DATE)
                                               , MIS.ACS_FINANCIAL_CURRENCY_ID
                                                )
             , 0.0
              )
         , nvl(GCO_FUNCTIONS.GetCostPriceWithManagementMode(aGCO_GOOD_ID
                                                          , nvl(MIS.PAC_CUSTOM_PARTNER_TARIFF_ID
                                                              , nvl(CCO.PAC_CUSTOM_PARTNER_TARIFF_ID
                                                                  , nvl(CUS.PAC_PAC_THIRD_2_ID
                                                                      , nvl(CCO.PAC_CUSTOM_PARTNER_ID, nvl(CUS1.PAC_PAC_THIRD_2_ID, MIS.PAC_CUSTOM_PARTNER_ID) )
                                                                       )
                                                                   )
                                                               )
                                                          , null   -- aManagementMode
                                                          , nvl(ITR.ITR_START_DATE, MIS.MIS_REQUEST_DATE)
                                                           )
             , 0.0
              )
      into aAID_UNIT_PRICE
         , aAID_COST_PRICE
      from ASA_INTERVENTION ITR
         , ASA_MISSION MIS
         , CML_DOCUMENT CCO
         , CML_POSITION CPO
         , PAC_CUSTOM_PARTNER CUS
         , PAC_CUSTOM_PARTNER CUS1
     where ITR.ASA_INTERVENTION_ID = aASA_INTERVENTION_ID
       and MIS.ASA_MISSION_ID = ITR.ASA_MISSION_ID
       and MIS.CML_POSITION_ID = CPO.CML_POSITION_ID(+)
       and CPO.CML_DOCUMENT_ID = CCO.CML_DOCUMENT_ID(+)
       and CUS.PAC_CUSTOM_PARTNER_ID(+) = CCO.PAC_CUSTOM_PARTNER_ID
       and CUS1.PAC_CUSTOM_PARTNER_ID(+) = MIS.PAC_CUSTOM_PARTNER_ID;
  end GetPrices;

  /**
  * Description
  *   Retourne le prix unitaire et le prix de revient d'un détail d'intervention
  */
  procedure GetPricesForUpdate(
    aDIC_TARIFF_ID                in     ASA_MISSION.DIC_TARIFF_ID%type
  , aASA_MISSION_TYPE_ID          in     ASA_MISSION.ASA_MISSION_TYPE_ID%type
  , aCML_POSITION_ID              in     ASA_MISSION.CML_POSITION_ID%type
  , aPAC_CUSTOM_PARTNER_ID        in     ASA_MISSION.PAC_CUSTOM_PARTNER_ID%type
  , aPAC_CUSTOM_PARTNER_TARIFF_ID in     ASA_MISSION.PAC_CUSTOM_PARTNER_TARIFF_ID%type
  , aDOC_RECORD_ID                in     ASA_MISSION.DOC_RECORD_ID%type
  , aMIS_REQUEST_DATE             in     ASA_MISSION.MIS_REQUEST_DATE%type
  , aACS_FINANCIAL_CURRENCY_ID    in     ASA_MISSION.ACS_FINANCIAL_CURRENCY_ID%type
  , aGCO_GOOD_ID                  in     ASA_INTERVENTION_DETAIL.GCO_GOOD_ID%type
  , aAID_CONSUMED_QUANTITY        in     ASA_INTERVENTION_DETAIL.AID_CONSUMED_QUANTITY%type
  , aAID_UNIT_PRICE               out    ASA_INTERVENTION_DETAIL.AID_UNIT_PRICE%type
  , aAID_COST_PRICE               out    ASA_INTERVENTION_DETAIL.AID_COST_PRICE%type
  )
  is
    vDIC_TARIFF_ID                ASA_MISSION.DIC_TARIFF_ID%type;
    vPAC_CUSTOM_PARTNER_TARIFF_ID ASA_MISSION.PAC_CUSTOM_PARTNER_TARIFF_ID%type;
  begin
    vDIC_TARIFF_ID  := aDIC_TARIFF_ID;

    if vDIC_TARIFF_ID is null then
      -- Cascade du code tarif de la mission
      vDIC_TARIFF_ID  := GetTariffID(aASA_MISSION_TYPE_ID, aCML_POSITION_ID, aPAC_CUSTOM_PARTNER_ID, aPAC_CUSTOM_PARTNER_TARIFF_ID);
    end if;

    -- cascade de recherche du tiers tarification
    if     (aPAC_CUSTOM_PARTNER_TARIFF_ID is null)
       and (aCML_POSITION_ID is not null) then
      select max(nvl(CCO.PAC_CUSTOM_PARTNER_TARIFF_ID
                   , nvl(CUS.PAC_PAC_THIRD_2_ID, nvl(CCO.PAC_CUSTOM_PARTNER_ID, nvl(CUS1.PAC_PAC_THIRD_2_ID, aPAC_CUSTOM_PARTNER_ID) ) )
                    )
                )
        into vPAC_CUSTOM_PARTNER_TARIFF_ID
        from CML_DOCUMENT CCO
           , CML_POSITION CPO
           , PAC_CUSTOM_PARTNER CUS
           , PAC_CUSTOM_PARTNER CUS1
       where CPO.CML_POSITION_ID = aCML_POSITION_ID
         and CPO.CML_DOCUMENT_ID = CCO.CML_DOCUMENT_ID
         and CUS.PAC_CUSTOM_PARTNER_ID(+) = CCO.PAC_CUSTOM_PARTNER_ID
         and CUS1.PAC_CUSTOM_PARTNER_ID(+) = aPAC_CUSTOM_PARTNER_ID;
    end if;

    select nvl(GCO_FUNCTIONS.GetGoodPriceForView(aGCO_GOOD_ID
                                               , 2   -- TypePrice
                                               , nvl(aPAC_CUSTOM_PARTNER_TARIFF_ID, nvl(vPAC_CUSTOM_PARTNER_TARIFF_ID, aPAC_CUSTOM_PARTNER_ID) )   -- ThirdId
                                               , aDOC_RECORD_ID
                                               , 0   -- FalScheduleStepId
                                               , vDIC_TARIFF_ID
                                               , aAID_CONSUMED_QUANTITY
                                               , aMIS_REQUEST_DATE
                                               , aACS_FINANCIAL_CURRENCY_ID
                                                )
             , 0.0
              )
         , nvl(GCO_FUNCTIONS.GetCostPriceWithManagementMode(aGCO_GOOD_ID
                                                          , nvl(aPAC_CUSTOM_PARTNER_TARIFF_ID, nvl(vPAC_CUSTOM_PARTNER_TARIFF_ID, aPAC_CUSTOM_PARTNER_ID) )
                                                          , null   -- aManagementMode
                                                          , aMIS_REQUEST_DATE
                                                           )
             , 0.0
              )
      into aAID_UNIT_PRICE
         , aAID_COST_PRICE
      from dual;
  end GetPricesForUpdate;

  /**
  * Description
  *   Mise à jour des prix des détails de l'intervention passé en paramètre
  */
  procedure SetInterventionPrices(
    aASA_INTERVENTION_ID          in ASA_INTERVENTION.ASA_INTERVENTION_ID%type
  , aDIC_TARIFF_ID                in ASA_MISSION.DIC_TARIFF_ID%type
  , aASA_MISSION_TYPE_ID          in ASA_MISSION.ASA_MISSION_TYPE_ID%type
  , aCML_POSITION_ID              in ASA_MISSION.CML_POSITION_ID%type
  , aPAC_CUSTOM_PARTNER_ID        in ASA_MISSION.PAC_CUSTOM_PARTNER_ID%type
  , aPAC_CUSTOM_PARTNER_TARIFF_ID in ASA_MISSION.PAC_CUSTOM_PARTNER_TARIFF_ID%type
  , aDOC_RECORD_ID                in ASA_MISSION.DOC_RECORD_ID%type
  , aMIS_REQUEST_DATE             in ASA_MISSION.MIS_REQUEST_DATE%type
  , aACS_FINANCIAL_CURRENCY_ID    in ASA_MISSION.ACS_FINANCIAL_CURRENCY_ID%type
  , aITR_START_DATE               in ASA_INTERVENTION.ITR_START_DATE%type
  )
  is
    vAID_UNIT_PRICE ASA_INTERVENTION_DETAIL.AID_UNIT_PRICE%type;
    vAID_COST_PRICE ASA_INTERVENTION_DETAIL.AID_COST_PRICE%type;
  begin
    if nvl(aASA_INTERVENTION_ID, 0) <> 0 then
      -- la modification de la date début intervention entraîne la mise à jour des tarifs des détails d'intervention
      for tplIntervalDet in (select AID.ASA_INTERVENTION_DETAIL_ID
                                  , nvl(AID.AID_CONSUMED_QUANTITY, 0) AID_CONSUMED_QUANTITY
                                  , nvl(AID.GCO_GOOD_ID, AID.GCO_SERVICE_ID) GCO_GOOD_ID
                               from ASA_INTERVENTION_DETAIL AID
                              where AID.ASA_INTERVENTION_ID = aASA_INTERVENTION_ID) loop
        GetPricesForUpdate(aDIC_TARIFF_ID                  => aDIC_TARIFF_ID
                         , aASA_MISSION_TYPE_ID            => aASA_MISSION_TYPE_ID
                         , aCML_POSITION_ID                => aCML_POSITION_ID
                         , aPAC_CUSTOM_PARTNER_ID          => aPAC_CUSTOM_PARTNER_ID
                         , aPAC_CUSTOM_PARTNER_TARIFF_ID   => aPAC_CUSTOM_PARTNER_TARIFF_ID
                         , aDOC_RECORD_ID                  => aDOC_RECORD_ID
                         , aMIS_REQUEST_DATE               => nvl(aITR_START_DATE, aMIS_REQUEST_DATE)
                         , aACS_FINANCIAL_CURRENCY_ID      => aACS_FINANCIAL_CURRENCY_ID
                         , aGCO_GOOD_ID                    => tplIntervalDet.GCO_GOOD_ID
                         , aAID_CONSUMED_QUANTITY          => tplIntervalDet.AID_CONSUMED_QUANTITY
                         , aAID_UNIT_PRICE                 => vAID_UNIT_PRICE
                         , aAID_COST_PRICE                 => vAID_COST_PRICE
                          );

        update ASA_INTERVENTION_DETAIL
           set AID_UNIT_PRICE = vAID_UNIT_PRICE
             , AID_COST_PRICE = vAID_COST_PRICE
         where ASA_INTERVENTION_DETAIL_ID = tplIntervalDet.ASA_INTERVENTION_DETAIL_ID;
      end loop;
    end if;
  end SetInterventionPrices;

  /**
  * Description
  *   Mise à jour des prix du détail d'intervention passé en paramètre
  */
  procedure SetPrices(
    aASA_INTERVENTION_DETAIL_ID   in ASA_INTERVENTION_DETAIL.ASA_INTERVENTION_DETAIL_ID%type
  , aDIC_TARIFF_ID                in ASA_MISSION.DIC_TARIFF_ID%type
  , aASA_MISSION_TYPE_ID          in ASA_MISSION.ASA_MISSION_TYPE_ID%type
  , aCML_POSITION_ID              in ASA_MISSION.CML_POSITION_ID%type
  , aPAC_CUSTOM_PARTNER_ID        in ASA_MISSION.PAC_CUSTOM_PARTNER_ID%type
  , aPAC_CUSTOM_PARTNER_TARIFF_ID in ASA_MISSION.PAC_CUSTOM_PARTNER_TARIFF_ID%type
  , aDOC_RECORD_ID                in ASA_MISSION.DOC_RECORD_ID%type
  , aMIS_REQUEST_DATE             in ASA_MISSION.MIS_REQUEST_DATE%type
  , aACS_FINANCIAL_CURRENCY_ID    in ASA_MISSION.ACS_FINANCIAL_CURRENCY_ID%type
  , aITR_START_DATE               in ASA_INTERVENTION.ITR_START_DATE%type
  )
  is
    vGCO_GOOD_ID           ASA_INTERVENTION_DETAIL.GCO_GOOD_ID%type;
    vAID_CONSUMED_QUANTITY ASA_INTERVENTION_DETAIL.AID_CONSUMED_QUANTITY%type;
    vAID_UNIT_PRICE        ASA_INTERVENTION_DETAIL.AID_UNIT_PRICE%type;
    vAID_COST_PRICE        ASA_INTERVENTION_DETAIL.AID_COST_PRICE%type;
  begin
    if nvl(aASA_INTERVENTION_DETAIL_ID, 0) > 0 then
      select nvl(GCO_GOOD_ID, GCO_SERVICE_ID)
           , AID_CONSUMED_QUANTITY
        into vGCO_GOOD_ID
           , vAID_CONSUMED_QUANTITY
        from ASA_INTERVENTION_DETAIL
       where ASA_INTERVENTION_DETAIL_ID = aASA_INTERVENTION_DETAIL_ID;

      GetPricesForUpdate(aDIC_TARIFF_ID                  => aDIC_TARIFF_ID
                       , aASA_MISSION_TYPE_ID            => aASA_MISSION_TYPE_ID
                       , aCML_POSITION_ID                => aCML_POSITION_ID
                       , aPAC_CUSTOM_PARTNER_ID          => aPAC_CUSTOM_PARTNER_ID
                       , aPAC_CUSTOM_PARTNER_TARIFF_ID   => aPAC_CUSTOM_PARTNER_TARIFF_ID
                       , aDOC_RECORD_ID                  => aDOC_RECORD_ID
                       , aMIS_REQUEST_DATE               => nvl(aITR_START_DATE, aMIS_REQUEST_DATE)
                       , aACS_FINANCIAL_CURRENCY_ID      => aACS_FINANCIAL_CURRENCY_ID
                       , aGCO_GOOD_ID                    => vGCO_GOOD_ID
                       , aAID_CONSUMED_QUANTITY          => nvl(vAID_CONSUMED_QUANTITY, 0)
                       , aAID_UNIT_PRICE                 => vAID_UNIT_PRICE
                       , aAID_COST_PRICE                 => vAID_COST_PRICE
                        );

      update ASA_INTERVENTION_DETAIL
         set AID_UNIT_PRICE = vAID_UNIT_PRICE
           , AID_COST_PRICE = vAID_COST_PRICE
       where ASA_INTERVENTION_DETAIL_ID = aASA_INTERVENTION_DETAIL_ID;
    end if;
  end SetPrices;

  /**
  * Description
  *   Retourne la position de contrat associée à la mission
  */
  function GetContractPosId(
    aPAC_CUSTOM_PARTNER_ID in ASA_MISSION.PAC_CUSTOM_PARTNER_ID%type
  , aASA_MACHINE_ID        in ASA_MISSION.ASA_MISSION_ID%type
  , aMIS_REQUEST_DATE      in ASA_MISSION.MIS_REQUEST_DATE%type
  )
    return ASA_MISSION.CML_POSITION_ID%type
  is
    vCML_POSITION_ID ASA_MISSION.CML_POSITION_ID%type;
  begin
    select   max(CPO.CML_POSITION_ID)
        into vCML_POSITION_ID
        from CML_DOCUMENT CCO
           , CML_POSITION CPO
           , PAC_PERSON PER
           , CML_POSITION_MACHINE CPM
       where CCO.CML_DOCUMENT_ID = CPO.CML_DOCUMENT_ID
         and CCO.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
         and CPO.CML_POSITION_ID = CPM.CML_POSITION_ID
         and CPO.C_CML_POS_TYPE = '1'
         and CPO.C_CML_POS_STATUS in('02', '03', '04', '06')
         and CCO.PAC_CUSTOM_PARTNER_ID = aPAC_CUSTOM_PARTNER_ID
         and CPM.DOC_RCO_MACHINE_ID = aASA_MACHINE_ID
         and nvl(CPO.CPO_EFFECTIV_END_DATE, nvl(CPO.CPO_END_EXTENDED_DATE, CPO.CPO_END_CONTRACT_DATE) ) >= aMIS_REQUEST_DATE
    order by CCO.CCO_NUMBER asc
           , CPO.CPO_SEQUENCE asc;

    return vCML_POSITION_ID;
  end GetContractPosId;

  /**
  * Description
  *   Initialisation du code tarif de la mission
  */
  function GetTariffID(
    aASA_MISSION_TYPE_ID          in ASA_MISSION.ASA_MISSION_TYPE_ID%type
  , aCML_POSITION_ID              in ASA_MISSION.CML_POSITION_ID%type
  , aPAC_CUSTOM_PARTNER_ID        in ASA_MISSION.PAC_CUSTOM_PARTNER_ID%type
  , aPAC_CUSTOM_PARTNER_TARIFF_ID in ASA_MISSION.PAC_CUSTOM_PARTNER_TARIFF_ID%type
  )
    return ASA_MISSION.DIC_TARIFF_ID%type
  is
    vDIC_TARIFF_ID                ASA_MISSION.DIC_TARIFF_ID%type;
    vPAC_CUSTOM_PARTNER_TARIFF_ID ASA_MISSION.PAC_CUSTOM_PARTNER_TARIFF_ID%type;
  begin
    -- Recherche du client tarification du type de mission
    select max(DIC_TARIFF_ID)
      into vDIC_TARIFF_ID
      from ASA_MISSION_TYPE
     where ASA_MISSION_TYPE_ID = aASA_MISSION_TYPE_ID;

    if vDIC_TARIFF_ID is null then
      -- Recherche du client tarification de la mission
      vPAC_CUSTOM_PARTNER_TARIFF_ID  := aPAC_CUSTOM_PARTNER_TARIFF_ID;

      if (aPAC_CUSTOM_PARTNER_TARIFF_ID is null) then
        -- Cascade de recherche du client tarification de la mission par rapport à la position de contrat
        if (aCML_POSITION_ID is not null) then
          select nvl(CCO.PAC_CUSTOM_PARTNER_TARIFF_ID, nvl(CUS.PAC_PAC_THIRD_2_ID, CCO.PAC_CUSTOM_PARTNER_ID) )
            into vPAC_CUSTOM_PARTNER_TARIFF_ID
            from CML_DOCUMENT CCO
               , CML_POSITION CPO
               , PAC_CUSTOM_PARTNER CUS
           where CCO.CML_DOCUMENT_ID = CPO.CML_DOCUMENT_ID
             and CPO.CML_POSITION_ID = aCML_POSITION_ID
             and CUS.PAC_CUSTOM_PARTNER_ID = CCO.PAC_CUSTOM_PARTNER_ID;
        else
          select nvl(CUS.PAC_PAC_THIRD_2_ID, CUS.PAC_CUSTOM_PARTNER_ID)
            into vPAC_CUSTOM_PARTNER_TARIFF_ID
            from PAC_CUSTOM_PARTNER CUS
           where CUS.PAC_CUSTOM_PARTNER_ID = aPAC_CUSTOM_PARTNER_ID;
        end if;
      end if;

      -- Recherche du code tarif selon client tarification identifié précédemment
      select DIC_TARIFF_ID
        into vDIC_TARIFF_ID
        from PAC_CUSTOM_PARTNER
       where PAC_CUSTOM_PARTNER_ID = vPAC_CUSTOM_PARTNER_TARIFF_ID;
    end if;

    return vDIC_TARIFF_ID;
  exception
    when no_data_found then
      return null;
  end;

  /**
  * Description
  *   Création d'un détail d'intervention depuis la création en série/corrélation
  */
  procedure InsertDetOnSerialCreate(
    aASA_INTERVENTION_ID    in ASA_INTERVENTION_DETAIL.ASA_INTERVENTION_ID%type
  , aGCO_GOOD_ID            in ASA_INTERVENTION_DETAIL.GCO_GOOD_ID%type
  , aAID_TAKEN_QUANTITY     in ASA_INTERVENTION_DETAIL.AID_TAKEN_QUANTITY%type
  , aAID_STOCK_FROM_ID      in ASA_INTERVENTION_DETAIL.AID_STOCK_FROM_ID%type
  , aAID_LOCATION_FROM_ID   in ASA_INTERVENTION_DETAIL.AID_LOCATION_FROM_ID%type
  , aAID_STOCK_TO_ID        in ASA_INTERVENTION_DETAIL.AID_STOCK_TO_ID%type
  , aAID_LOCATION_TO_ID     in ASA_INTERVENTION_DETAIL.AID_LOCATION_TO_ID%type
  , aAID_RETURN_STOCK_ID    in ASA_INTERVENTION_DETAIL.AID_RETURN_STOCK_ID%type
  , aAID_RETURN_LOCATION_ID in ASA_INTERVENTION_DETAIL.AID_RETURN_LOCATION_ID%type
  , aGCO_CHAR1_ID           in ASA_INTERVENTION_DETAIL.GCO_CHAR1_ID%type
  , aGCO_CHAR2_ID           in ASA_INTERVENTION_DETAIL.GCO_CHAR2_ID%type
  , aGCO_CHAR3_ID           in ASA_INTERVENTION_DETAIL.GCO_CHAR3_ID%type
  , aGCO_CHAR4_ID           in ASA_INTERVENTION_DETAIL.GCO_CHAR4_ID%type
  , aGCO_CHAR5_ID           in ASA_INTERVENTION_DETAIL.GCO_CHAR5_ID%type
  , aAID_CONSUMED_QUANTITY  in ASA_INTERVENTION_DETAIL.AID_CONSUMED_QUANTITY%type
  , aAID_RETURNED_QUANTITY  in ASA_INTERVENTION_DETAIL.AID_RETURNED_QUANTITY%type
  , aAID_KEPT_QUANTITY      in ASA_INTERVENTION_DETAIL.AID_KEPT_QUANTITY%type
  , aAID_CHAR1_VALUE        in ASA_INTERVENTION_DETAIL.AID_CHAR1_VALUE%type
  , aAID_CHAR2_VALUE        in ASA_INTERVENTION_DETAIL.AID_CHAR2_VALUE%type
  , aAID_CHAR3_VALUE        in ASA_INTERVENTION_DETAIL.AID_CHAR3_VALUE%type
  , aAID_CHAR4_VALUE        in ASA_INTERVENTION_DETAIL.AID_CHAR4_VALUE%type
  , aAID_CHAR5_VALUE        in ASA_INTERVENTION_DETAIL.AID_CHAR5_VALUE%type
  , aAID_INVOICING_QTY      in ASA_INTERVENTION_DETAIL.AID_INVOICING_QTY%type
  )
  is
    vAID_UNIT_PRICE ASA_INTERVENTION_DETAIL.AID_UNIT_PRICE%type;
    vAID_COST_PRICE ASA_INTERVENTION_DETAIL.AID_COST_PRICE%type;
    lnSeq           ASA_INTERVENTION_DETAIL.AID_NUMBER%type;
    lnLangID        PCS.PC_LANG.PC_LANG_ID%type;
    lvShortDescr    ASA_INTERVENTION_DETAIL.AID_SHORT_DESCR%type;
    lvLongDescr     ASA_INTERVENTION_DETAIL.AID_LONG_DESCR%type;
    lvFreeDescr     ASA_INTERVENTION_DETAIL.AID_FREE_DESCR%type;
  begin
    -- Recherche du prix unitaire et du prix de revient
    ASA_MISSION_FUNCTIONS.GetPrices(aASA_INTERVENTION_ID     => aASA_INTERVENTION_ID
                                  , aGCO_GOOD_ID             => aGCO_GOOD_ID
                                  , aAID_CONSUMED_QUANTITY   => aAID_CONSUMED_QUANTITY
                                  , aAID_UNIT_PRICE          => vAID_UNIT_PRICE
                                  , aAID_COST_PRICE          => vAID_COST_PRICE
                                   );
    -- N° de séquence
    lnSeq  := GetDetailSequence(iInterventionID => aASA_INTERVENTION_ID, iService => 0);

    -- Langue de la mission pour la recherche des descriptions
    select MIS.PC_LANG_ID
      into lnLangID
      from ASA_MISSION MIS
         , ASA_INTERVENTION ITR
     where ITR.ASA_INTERVENTION_ID = aASA_INTERVENTION_ID
       and ITR.ASA_MISSION_ID = MIS.ASA_MISSION_ID;

    -- Recherche des descriptions
    ASA_FUNCTIONS.GetGoodDescription(iGoodID       => aGCO_GOOD_ID
                                   , iLangID       => lnLangID
                                   , oShortDescr   => lvShortDescr
                                   , oLongDescr    => lvLongDescr
                                   , oFreeDescr    => lvFreeDescr
                                    );

    -- Création du détail
    insert into ASA_INTERVENTION_DETAIL
                (ASA_INTERVENTION_DETAIL_ID
               , ASA_INTERVENTION_ID
               , AID_NUMBER
               , GCO_GOOD_ID
               , AID_TAKEN_QUANTITY
               , AID_STOCK_FROM_ID
               , AID_LOCATION_FROM_ID
               , AID_STOCK_TO_ID
               , AID_LOCATION_TO_ID
               , AID_RETURN_STOCK_ID
               , AID_RETURN_LOCATION_ID
               , GCO_CHAR1_ID
               , GCO_CHAR2_ID
               , GCO_CHAR3_ID
               , GCO_CHAR4_ID
               , GCO_CHAR5_ID
               , AID_CONSUMED_QUANTITY
               , AID_RETURNED_QUANTITY
               , AID_KEPT_QUANTITY
               , AID_CHAR1_VALUE
               , AID_CHAR2_VALUE
               , AID_CHAR3_VALUE
               , AID_CHAR4_VALUE
               , AID_CHAR5_VALUE
               , AID_UNIT_PRICE
               , AID_COST_PRICE
               , AID_INVOICING_QTY
               , AID_SHORT_DESCR
               , AID_LONG_DESCR
               , AID_FREE_DESCR
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval
           , aASA_INTERVENTION_ID
           , lnSeq as AID_NUMBER
           , aGCO_GOOD_ID
           , aAID_TAKEN_QUANTITY
           , aAID_STOCK_FROM_ID
           , aAID_LOCATION_FROM_ID
           , aAID_STOCK_TO_ID
           , aAID_LOCATION_TO_ID
           , aAID_RETURN_STOCK_ID
           , aAID_RETURN_LOCATION_ID
           , aGCO_CHAR1_ID
           , aGCO_CHAR2_ID
           , aGCO_CHAR3_ID
           , aGCO_CHAR4_ID
           , aGCO_CHAR5_ID
           , aAID_CONSUMED_QUANTITY
           , aAID_RETURNED_QUANTITY
           , aAID_KEPT_QUANTITY
           , aAID_CHAR1_VALUE
           , aAID_CHAR2_VALUE
           , aAID_CHAR3_VALUE
           , aAID_CHAR4_VALUE
           , aAID_CHAR5_VALUE
           , vAID_UNIT_PRICE
           , vAID_COST_PRICE
           , aAID_INVOICING_QTY
           , lvShortDescr   -- AID_SHORT_DESCR
           , lvLongDescr   -- AID_LONG_DESCR
           , lvFreeDescr   -- AID_FREE_DESCR
           , sysdate
           , PCS.PC_I_LIB_SESSION.GETUSERINI
        from ASA_MISSION MIS
           , ASA_INTERVENTION ITR
       where ITR.ASA_MISSION_ID = MIS.ASA_MISSION_ID
         and ITR.ASA_INTERVENTION_ID = aASA_INTERVENTION_ID;
  end InsertDetOnSerialCreate;

  /**
  * Description
  *   Création des détails d'intervention selon le type de mission
  */
  procedure InsertDetFromMisType(aASA_INTERVENTION_ID in ASA_INTERVENTION.ASA_INTERVENTION_ID%type)
  is
    vAID_UNIT_PRICE ASA_INTERVENTION_DETAIL.AID_UNIT_PRICE%type;
    vAID_COST_PRICE ASA_INTERVENTION_DETAIL.AID_COST_PRICE%type;
    lnSeq           ASA_INTERVENTION_DETAIL.AID_NUMBER%type;
    lvShortDescr    ASA_INTERVENTION_DETAIL.AID_SHORT_DESCR%type;
    lvLongDescr     ASA_INTERVENTION_DETAIL.AID_LONG_DESCR%type;
    lvFreeDescr     ASA_INTERVENTION_DETAIL.AID_FREE_DESCR%type;
  begin
    for crIntervention in (select MTD.MTD_UTIL_COEF
                                , MTD.GCO_GOOD_ID
                                , MIS.PC_LANG_ID
                             from ASA_MISSION_TYPE_DETAIL MTD
                                , ASA_MISSION MIS
                                , ASA_INTERVENTION ITR
                            where MTD.ASA_MISSION_TYPE_ID = MIS.ASA_MISSION_TYPE_ID
                              and MIS.ASA_MISSION_ID = ITR.ASA_MISSION_ID
                              and ITR.ASA_INTERVENTION_ID = aASA_INTERVENTION_ID) loop
      -- Recherche du prix unitaire et du prix de revient
      ASA_MISSION_FUNCTIONS.GetPrices(aASA_INTERVENTION_ID     => aASA_INTERVENTION_ID
                                    , aGCO_GOOD_ID             => crIntervention.GCO_GOOD_ID
                                    , aAID_CONSUMED_QUANTITY   => crIntervention.MTD_UTIL_COEF
                                    , aAID_UNIT_PRICE          => vAID_UNIT_PRICE
                                    , aAID_COST_PRICE          => vAID_COST_PRICE
                                     );
      -- N° de séquence
      lnSeq  := GetDetailSequence(iInterventionID => aASA_INTERVENTION_ID, iService => 1);
      -- Recherche des descriptions
      ASA_FUNCTIONS.GetGoodDescription(iGoodID       => crIntervention.GCO_GOOD_ID
                                     , iLangID       => crIntervention.PC_LANG_ID
                                     , oShortDescr   => lvShortDescr
                                     , oLongDescr    => lvLongDescr
                                     , oFreeDescr    => lvFreeDescr
                                      );

      -- Création du détail
      insert into ASA_INTERVENTION_DETAIL
                  (ASA_INTERVENTION_DETAIL_ID
                 , ASA_INTERVENTION_ID
                 , AID_NUMBER
                 , GCO_SERVICE_ID
                 , AID_TAKEN_QUANTITY
                 , AID_CONSUMED_QUANTITY
                 , AID_UNIT_PRICE
                 , AID_COST_PRICE
                 , AID_SHORT_DESCR
                 , AID_LONG_DESCR
                 , AID_FREE_DESCR
                 , A_DATECRE
                 , A_IDCRE
                  )
        select init_id_seq.nextval
             , aASA_INTERVENTION_ID
             , lnSeq as AID_NUMBER
             , crIntervention.GCO_GOOD_ID
             , crIntervention.MTD_UTIL_COEF
             , 0
             , vAID_UNIT_PRICE
             , vAID_COST_PRICE
             , lvShortDescr   -- AID_SHORT_DESCR
             , lvLongDescr   -- AID_LONG_DESCR
             , lvFreeDescr   -- AID_FREE_DESCR
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from dual;
    end loop;
  end InsertDetFromMisType;

  /**
  * Description
  *   Extourne du mouvement de transfert
  */
  procedure ReverseTransferMvt(aASA_INTERVENTION_DETAIL_ID in ASA_INTERVENTION_DETAIL.ASA_INTERVENTION_DETAIL_ID%type)
  is
    vTrfMvtId ASA_INTERVENTION_DETAIL.STM_STOCK_MVT_TRSF_ID%type;
  begin
    select max(STM_STOCK_MVT_TRSF_ID)
      into vTrfMvtId
      from ASA_INTERVENTION_DETAIL
     where ASA_INTERVENTION_DETAIL_ID = aASA_INTERVENTION_DETAIL_ID;

    if vTrfMvtId is not null then
      -- extourne du mouvement
      STM_PRC_MOVEMENT.GenerateReversalMvt(vTrfMvtId);

      -- mise à jour du détail
      update ASA_INTERVENTION_DETAIL
         set AID_TRANSFER_DONE = 0
           , STM_STOCK_MVT_TRSF_ID = null
       where ASA_INTERVENTION_DETAIL_ID = aASA_INTERVENTION_DETAIL_ID;
    end if;
  end ReverseTransferMvt;

  /**
  * Description
  *   Extourne des mouvements de consommation (conso/échange, retour)
  */
  procedure ReverseMovements(aASA_INTERVENTION_DETAIL_ID in ASA_INTERVENTION_DETAIL.ASA_INTERVENTION_DETAIL_ID%type)
  is
    vConsMvtId    ASA_INTERVENTION_DETAIL.STM_STOCK_MVT_CONS_ID%type;
    vReturnMvtId  ASA_INTERVENTION_DETAIL.STM_STOCK_MVT_RETURN_ID%type;
    vExchInMvtId  ASA_INTERVENTION_DETAIL.STM_STOCK_MVT_EXCH_IN_ID%type;
    vExchOutMvtId ASA_INTERVENTION_DETAIL.STM_STOCK_MVT_EXCH_OUT_ID%type;
  begin
    select max(STM_STOCK_MVT_CONS_ID)
         , max(STM_STOCK_MVT_RETURN_ID)
         , max(STM_STOCK_MVT_EXCH_IN_ID)
         , max(STM_STOCK_MVT_EXCH_OUT_ID)
      into vConsMvtId
         , vReturnMvtId
         , vExchInMvtId
         , vExchOutMvtId
      from ASA_INTERVENTION_DETAIL
     where ASA_INTERVENTION_DETAIL_ID = aASA_INTERVENTION_DETAIL_ID;

    if vConsMvtId is not null then
      -- extourne du mouvement de consommation
      STM_PRC_MOVEMENT.GenerateReversalMvt(vConsMvtId);
    end if;

    if vReturnMvtId is not null then
      -- extourne du mouvement de retour
      STM_PRC_MOVEMENT.GenerateReversalMvt(vReturnMvtId);
    end if;

    if vExchInMvtId is not null then
      -- extourne du mouvement de sortie du bien pour échange
      STM_PRC_MOVEMENT.GenerateReversalMvt(vExchInMvtId);
      -- extourne du mouvement d'entrée du bien échangé
      STM_PRC_MOVEMENT.GenerateReversalMvt(vExchOutMvtId);
    end if;

    if    (vConsMvtId is not null)
       or (vReturnMvtId is not null)
       or (vExchInMvtId is not null) then
      -- mise à jour du détail
      update ASA_INTERVENTION_DETAIL
         set AID_MOVEMENT_DONE = 0
           , STM_STOCK_MVT_CONS_ID = null
           , STM_STOCK_MVT_RETURN_ID = null
           , STM_STOCK_MVT_EXCH_IN_ID = null
           , STM_STOCK_MVT_EXCH_OUT_ID = null
       where ASA_INTERVENTION_DETAIL_ID = aASA_INTERVENTION_DETAIL_ID;
    end if;
  end ReverseMovements;

  /**
  * procedure ClearMvtInterventionRef
  * Description
  *   Effacer le lien du détail de l'intervention qui est inscrit sur les mvts si celui-ci a été extourné.
  *   Cette procédure est appelée avant l'effacement d'un détail pour que celui-ci puisse être effacé si tous ces mvts ont été extournés
  */
  procedure ClearMvtInterventionRef(iIntervDetID in ASA_INTERVENTION_DETAIL.ASA_INTERVENTION_DETAIL_ID%type)
  is
    lnAllMvts      integer;
    lnReversedMvts integer;
  begin
    -- Lecture du nbre de mvts et du nbre de mvts extournés concernant le détail d'intervention à traiter
    select count(*) as ALL_MVTS
         , count(case
                   when STM2_STM_STOCK_MOVEMENT_ID is not null then 1
                   else 0
                 end) as REVERSED_MVTS
      into lnAllMvts
         , lnReversedMvts
      from STM_STOCK_MOVEMENT
     where ASA_INTERVENTION_DETAIL_ID = iIntervDetID;

    -- S'il y a eu des mvts et que ceux-ci ont tous été extournés
    if     (lnAllMvts > 0)
       and (lnAllMvts = lnReversedMvts) then
      -- Effacer le lien du détail de l'intervention sur le mvt
      update STM_STOCK_MOVEMENT
         set ASA_INTERVENTION_DETAIL_ID = null
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where ASA_INTERVENTION_DETAIL_ID = iIntervDetID;
    end if;
  end ClearMvtInterventionRef;

  /**
  *  function GetDetailSequence
  *  Description
  *    Recherche la nouvelle séquence pour le détail d'intervention
  */
  function GetDetailSequence(iInterventionID in ASA_INTERVENTION.ASA_INTERVENTION_ID%type, iService in number)
    return number
  is
    lnSeq ASA_INTERVENTION_DETAIL.AID_NUMBER%type;
  begin
    -- Rechercher la dernière séquence utilisée
    select nvl(max(AID.AID_NUMBER), 0) as NEXT_SEQ
      into lnSeq
      from ASA_INTERVENTION_DETAIL AID
     where AID.ASA_INTERVENTION_ID = iInterventionID
       and (    (    AID.GCO_SERVICE_ID is not null
                 and iService = 1)
            or (    AID.GCO_GOOD_ID is not null
                and iService = 0) );

    -- Ajouter l'incrément définit dans la config
    return lnSeq + nvl(PCS.PcsToNumber(PCS.PC_CONFIG.GetConfig('ASA_INTERVENTION_DETAIL_SEQ') ), 10);
  end GetDetailSequence;
end ASA_MISSION_FUNCTIONS;
