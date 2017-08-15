--------------------------------------------------------
--  DDL for Package Body STM_PRC_STOCK_POSITION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "STM_PRC_STOCK_POSITION" 
is
  -- Insertion d'une position avec quantités nulles
  procedure pInsertNullPosition(
    iStockId                in STM_STOCK.STM_STOCK_ID%type
  , iLocationId             in STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type
  , iGoodId                 in GCO_GOOD.GCO_GOOD_ID%type
  , iCharacterization1Id    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterization2Id    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterization3Id    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterization4Id    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterization5Id    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterizationValue1 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , iCharacterizationValue2 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type
  , iCharacterizationValue3 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type
  , iCharacterizationValue4 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type
  , iCharacterizationValue5 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type
  , iElementNumber1         in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , iElementNumber2         in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , iElementNumber3         in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , iElementNumberDetail    in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  )
  is
  begin
    insert into STM_STOCK_POSITION
                (STM_STOCK_POSITION_ID
               , STM_STOCK_ID
               , STM_LOCATION_ID
               , C_POSITION_STATUS
               , GCO_GOOD_ID
               , GCO_CHARACTERIZATION_ID
               , GCO_GCO_CHARACTERIZATION_ID
               , GCO2_GCO_CHARACTERIZATION_ID
               , GCO3_GCO_CHARACTERIZATION_ID
               , GCO4_GCO_CHARACTERIZATION_ID
               , SPO_CHARACTERIZATION_VALUE_1
               , SPO_CHARACTERIZATION_VALUE_2
               , SPO_CHARACTERIZATION_VALUE_3
               , SPO_CHARACTERIZATION_VALUE_4
               , SPO_CHARACTERIZATION_VALUE_5
               , STM_ELEMENT_NUMBER_ID
               , STM_STM_ELEMENT_NUMBER_ID
               , STM2_STM_ELEMENT_NUMBER_ID
               , STM_ELEMENT_NUMBER_DETAIL_ID
               , SPO_STOCK_QUANTITY
               , SPO_ASSIGN_QUANTITY
               , SPO_AVAILABLE_QUANTITY
               , SPO_PROVISORY_OUTPUT
               , SPO_PROVISORY_INPUT
               , SPO_THEORETICAL_QUANTITY
               , SPO_ALTERNATIV_QUANTITY_1
               , SPO_ALTERNATIV_QUANTITY_2
               , SPO_ALTERNATIV_QUANTITY_3
               , A_DATECRE
               , A_IDCRE
                )
         values (init_id_seq.nextval
               , iStockId
               , iLocationId
               , '01'
               , iGoodId
               , iCharacterization1Id
               , iCharacterization2Id
               , iCharacterization3Id
               , iCharacterization4Id
               , iCharacterization5Id
               , iCharacterizationValue1
               , iCharacterizationValue2
               , iCharacterizationValue3
               , iCharacterizationValue4
               , iCharacterizationValue5
               , iElementNumber1
               , iElementNumber2
               , iElementNumber3
               , iElementNumberDetail
               , 0
               , 0
               , 0
               , 0
               , 0
               , 0
               , 0
               , 0
               , 0
               , sysdate
               , PCS.PC_I_LIB_SESSION.GetUserIni
                );
  end pInsertNullPosition;

  -- Insertion d'une position avec quantités nulles dans une transaction autonome
  procedure pInsertNullPositionAutonom(
    iStockId                in STM_STOCK.STM_STOCK_ID%type
  , iLocationId             in STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type
  , iGoodId                 in GCO_GOOD.GCO_GOOD_ID%type
  , iCharacterization1Id    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterization2Id    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterization3Id    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterization4Id    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterization5Id    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterizationValue1 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , iCharacterizationValue2 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type
  , iCharacterizationValue3 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type
  , iCharacterizationValue4 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type
  , iCharacterizationValue5 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type
  , iElementNumber1         in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , iElementNumber2         in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , iElementNumber3         in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , iElementNumberDetail    in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  )
  is
    pragma autonomous_transaction;
  begin
    pInsertNullPosition(iStockId
                      , iLocationId
                      , iGoodId
                      , iCharacterization1Id
                      , iCharacterization2Id
                      , iCharacterization3Id
                      , iCharacterization4Id
                      , iCharacterization5Id
                      , iCharacterizationValue1
                      , iCharacterizationValue2
                      , iCharacterizationValue3
                      , iCharacterizationValue4
                      , iCharacterizationValue5
                      , iElementNumber1
                      , iElementNumber2
                      , iElementNumber3
                      , iElementNumberDetail
                       );
    commit;
  end pInsertNullPositionAutonom;

  -- Insertion d'une position avec quantités nulles
  procedure InsertNullPosition(
    iStockId                in STM_STOCK.STM_STOCK_ID%type
  , iLocationId             in STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type
  , iGoodId                 in GCO_GOOD.GCO_GOOD_ID%type
  , iCharacterization1Id    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterization2Id    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterization3Id    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterization4Id    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterization5Id    in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , iCharacterizationValue1 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
  , iCharacterizationValue2 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type
  , iCharacterizationValue3 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type
  , iCharacterizationValue4 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type
  , iCharacterizationValue5 in STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type
  , iElementNumber1         in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , iElementNumber2         in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , iElementNumber3         in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  , iElementNumberDetail    in STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type
  )
  is
  begin
    if GCO_I_PRC_CHARACTERIZATION.gCharManagementMode = 0 then
      pInsertNullPositionAutonom(iStockId
                               , iLocationId
                               , iGoodId
                               , iCharacterization1Id
                               , iCharacterization2Id
                               , iCharacterization3Id
                               , iCharacterization4Id
                               , iCharacterization5Id
                               , iCharacterizationValue1
                               , iCharacterizationValue2
                               , iCharacterizationValue3
                               , iCharacterizationValue4
                               , iCharacterizationValue5
                               , iElementNumber1
                               , iElementNumber2
                               , iElementNumber3
                               , iElementNumberDetail
                                );
    else
      pInsertNullPosition(iStockId
                        , iLocationId
                        , iGoodId
                        , iCharacterization1Id
                        , iCharacterization2Id
                        , iCharacterization3Id
                        , iCharacterization4Id
                        , iCharacterization5Id
                        , iCharacterizationValue1
                        , iCharacterizationValue2
                        , iCharacterizationValue3
                        , iCharacterizationValue4
                        , iCharacterizationValue5
                        , iElementNumber1
                        , iElementNumber2
                        , iElementNumber3
                        , iElementNumberDetail
                         );
    end if;
  exception
    when ex.DEADLOCK_DETECTED then
      pInsertNullPosition(iStockId
                        , iLocationId
                        , iGoodId
                        , iCharacterization1Id
                        , iCharacterization2Id
                        , iCharacterization3Id
                        , iCharacterization4Id
                        , iCharacterization5Id
                        , iCharacterizationValue1
                        , iCharacterizationValue2
                        , iCharacterizationValue3
                        , iCharacterizationValue4
                        , iCharacterizationValue5
                        , iElementNumber1
                        , iElementNumber2
                        , iElementNumber3
                        , iElementNumberDetail
                         );
  end InsertNullPosition;

  -- Cette procedure met à jour la table des positions de stock en fonction des caractéristiques
  -- des mouvements de stock
  procedure updatePosition(iotMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
  is
    -- Curseur sur les caractérisations gêrées en stock
    cursor lcurCharacStk(iCrCharacId1 number, iCrCharacId2 number, iCrCharacId3 number, iCrCharacId4 number, iCrCharacId5 number)
    is
      select   GCO_CHARACTERIZATION_ID
          from GCO_CHARACTERIZATION
         where (   GCO_CHARACTERIZATION_ID = iCrCharacId1
                or GCO_CHARACTERIZATION_ID = iCrCharacId2
                or GCO_CHARACTERIZATION_ID = iCrCharacId3
                or GCO_CHARACTERIZATION_ID = iCrCharacId4
                or GCO_CHARACTERIZATION_ID = iCrCharacId5
               )
           and CHA_STOCK_MANAGEMENT = 1
      order by decode(GCO_CHARACTERIZATION_ID, iCrCharacId1, '1', iCrCharacId2, '2', iCrCharacId3, '3', iCrCharacId4, '4', iCrCharacId5, '5');

    type tCharacTwist is record(
      id    STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type
    , value STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type
    );

    type ttCharacValueList is table of tCharacTwist
      index by binary_integer;

    lCharacIdList           varchar2(64)                                           default ',';
    lCharacterizationId     STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lCharacterization2Id    STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lCharacterization3Id    STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lCharacterization4Id    STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lCharacterization5Id    STM_STOCK_MOVEMENT.GCO_CHARACTERIZATION_ID%type;
    lCharacterizationValue1 STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    lCharacterizationValue2 STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    lCharacterizationValue3 STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    lCharacterizationValue4 STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    lCharacterizationValue5 STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type;
    lCharacValueList        ttCharacValueList;
    lMovementSort           STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type;
    lMovementType           STM_MOVEMENT_KIND.C_MOVEMENT_TYPE%type;
    lMovementCode           STM_MOVEMENT_KIND.C_MOVEMENT_CODE%type;
    lUpdateMode             varchar2(2);
    lMvtQuantity            STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type;
    lStockPositionId        STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type;
    lElementNumber1         STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    lElementNumber2         STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    lElementNumber3         STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    lQualityStatusId        STM_ELEMENT_NUMBER.GCO_QUALITY_STATUS_ID%type;
    lCharacId               GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharacType             GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    lMvtAltQty1             STM_STOCK_POSITION.SPO_ALTERNATIV_QUANTITY_1%type;
    lMvtAltQty2             STM_STOCK_POSITION.SPO_ALTERNATIV_QUANTITY_2%type;
    lMvtAltQty3             STM_STOCK_POSITION.SPO_ALTERNATIV_QUANTITY_3%type;
    lMvtProvInput           STM_STOCK_POSITION.SPO_PROVISORY_INPUT%type            default 0;
    lMvtProvOutput          STM_STOCK_POSITION.SPO_PROVISORY_OUTPUT%type           default 0;
    lStockManagement        GCO_PRODUCT.PDT_STOCK_MANAGEMENT%type;
    lVerifyChar             STM_MOVEMENT_KIND.MOK_VERIFY_CHARACTERIZATION%type;
    lTmpMvtType             STM_MOVEMENT_KIND.C_MOVEMENT_TYPE%type                 default null;
    lIndex                  integer;
    lTransfert              integer                                                := 0;

    procedure GetStockPositionId
    is
    begin
      lStockPositionId  := null;

      -- teste si on a déjà une position de stock correspondant au mouvement que l'on passe
      -- sinon on en crée une avec des quantités nulles dans une transaction autonome
      -- pour éviter les problèmes de multiuser
      while lStockPositionId is null loop
        begin
          select     STM_STOCK_POSITION_ID
                into lStockPositionId
                from STM_STOCK_POSITION
               where STM_STOCK_POSITION_ID =
                       STM_LIB_STOCK_POSITION.GetStockPositionId(iGoodId       => iotMovementRecord.GCO_GOOD_ID
                                                               , iLocationId   => iotMovementRecord.STM_LOCATION_ID
                                                               , iChar1Id      => lCharacterizationId
                                                               , iChar2Id      => lCharacterization2Id
                                                               , iChar3Id      => lCharacterization3Id
                                                               , iChar4Id      => lCharacterization4Id
                                                               , iChar5Id      => lCharacterization5Id
                                                               , iCharValue1   => lCharacterizationValue1
                                                               , iCharValue2   => lCharacterizationValue2
                                                               , iCharValue3   => lCharacterizationValue3
                                                               , iCharValue4   => lCharacterizationValue4
                                                               , iCharValue5   => lCharacterizationValue5
                                                                )
          for update;
        exception
          when no_data_found then
            lStockPositionId  := null;
        end;

        -- si la position de stock n'existe pas, on la crée avec des valeurs nulles
        if lStockPositionId is null then
          begin
            InsertNullPosition(iotMovementRecord.STM_STOCK_ID
                             , iotMovementRecord.STM_LOCATION_ID
                             , iotMovementRecord.GCO_GOOD_ID
                             , lCharacterizationId
                             , lCharacterization2Id
                             , lCharacterization3Id
                             , lCharacterization4Id
                             , lCharacterization5Id
                             , lCharacterizationValue1
                             , lCharacterizationValue2
                             , lCharacterizationValue3
                             , lCharacterizationValue4
                             , lCharacterizationValue5
                             , lElementNumber1
                             , lElementNumber2
                             , lElementNumber3
                             , STM_I_LIB_ELEMENT_NUMBER.GetDetailElement(iGoodID    => iotMovementRecord.GCO_GOOD_ID
                                                                       , iDetail1   => lElementNumber1
                                                                       , iDetail2   => lElementNumber2
                                                                       , iDetail3   => lElementNumber3
                                                                        )
                              );
          exception
            when others then
              if (iotMovementRecord.STM_LOCATION_ID is null) then
                raise_application_error(-20900, PCS.PC_FUNCTIONS.TranslateWord('PCS - L''emplacement de stock n''est pas renseigné') );
              else
                raise_application_error(-20000
                                      , 'Insert null position before update' ||
                                        ' MoveQty=' ||
                                        lMovementSort ||
                                        '/' ||
                                        iotMovementRecord.SMO_MOVEMENT_QUANTITY ||
                                        '/' ||
                                        lElementNumber1 ||
                                        chr(13) ||
                                        sqlerrm
                                       );
              end if;
          end;
        end if;
      end loop;

      if lStockPositionId is null then
        raise_application_error(-20950, PCS.PC_FUNCTIONS.TranslateWord('PCS - Erreur lors de la création de la position de stock') );
      end if;
    end GetStockPositionId;
  begin
    --Recherche si le produit fait l'objet d'une gestion de stock ou pas
    select max(PDT_STOCK_MANAGEMENT)
      into lStockManagement
      from GCO_PRODUCT
     where GCO_GOOD_ID = iotMovementRecord.GCO_GOOD_ID;

    -- Recherche des caractérisations gêrées en stock
    open lcurCharacStk(iotMovementRecord.GCO_CHARACTERIZATION_ID
                     , iotMovementRecord.GCO_GCO_CHARACTERIZATION_ID
                     , iotMovementRecord.GCO2_GCO_CHARACTERIZATION_ID
                     , iotMovementRecord.GCO3_GCO_CHARACTERIZATION_ID
                     , iotMovementRecord.GCO4_GCO_CHARACTERIZATION_ID
                      );

    fetch lcurCharacStk
     into lCharacId;

    -- construction de la liste des caractérisations gêrées en stock, parmi les charac du mouvement
    while lcurCharacStk%found loop
      lCharacIdList  := lCharacIdList || to_char(lCharacId) || ',';

      fetch lcurCharacStk
       into lCharacId;
    end loop;

    lIndex  := 0;

    -- Chaque caractérisation gêrée en stock est isolée dans un tableau
    if instr(lCharacIdList, ',' || to_char(iotMovementRecord.GCO_CHARACTERIZATION_ID) || ',') > 0 then
      lIndex                          := lIndex + 1;
      lCharacValueList(lIndex).id     := iotMovementRecord.GCO_CHARACTERIZATION_ID;
      lCharacValueList(lIndex).value  := iotMovementRecord.SMO_CHARACTERIZATION_VALUE_1;
    end if;

    if instr(lCharacIdList, ',' || to_char(iotMovementRecord.GCO_GCO_CHARACTERIZATION_ID) || ',') > 0 then
      lIndex                          := lIndex + 1;
      lCharacValueList(lIndex).id     := iotMovementRecord.GCO_GCO_CHARACTERIZATION_ID;
      lCharacValueList(lIndex).value  := iotMovementRecord.SMO_CHARACTERIZATION_VALUE_2;
    end if;

    if instr(lCharacIdList, ',' || to_char(iotMovementRecord.GCO2_GCO_CHARACTERIZATION_ID) || ',') > 0 then
      lIndex                          := lIndex + 1;
      lCharacValueList(lIndex).id     := iotMovementRecord.GCO2_GCO_CHARACTERIZATION_ID;
      lCharacValueList(lIndex).value  := iotMovementRecord.SMO_CHARACTERIZATION_VALUE_3;
    end if;

    if instr(lCharacIdList, ',' || to_char(iotMovementRecord.GCO3_GCO_CHARACTERIZATION_ID) || ',') > 0 then
      lIndex                          := lIndex + 1;
      lCharacValueList(lIndex).id     := iotMovementRecord.GCO3_GCO_CHARACTERIZATION_ID;
      lCharacValueList(lIndex).value  := iotMovementRecord.SMO_CHARACTERIZATION_VALUE_4;
    end if;

    if instr(lCharacIdList, ',' || to_char(iotMovementRecord.GCO4_GCO_CHARACTERIZATION_ID) || ',') > 0 then
      lIndex                          := lIndex + 1;
      lCharacValueList(lIndex).id     := iotMovementRecord.GCO4_GCO_CHARACTERIZATION_ID;
      lCharacValueList(lIndex).value  := iotMovementRecord.SMO_CHARACTERIZATION_VALUE_5;
    end if;

    -- Mise à jour de variables avec les id et les valeurs des caractérisations gêrées en stock
    if lIndex > 0 then
      lCharacterizationValue1  := lCharacValueList(1).value;
      lCharacterizationId      := lCharacValueList(1).id;
    else
      lCharacterizationValue1  := null;
      lCharacterizationId      := null;
    end if;

    if lIndex > 1 then
      lCharacterizationValue2  := lCharacValueList(2).value;
      lCharacterization2Id     := lCharacValueList(2).id;
    else
      lCharacterizationValue2  := null;
      lCharacterization2Id     := null;
    end if;

    if lIndex > 2 then
      lCharacterizationValue3  := lCharacValueList(3).value;
      lCharacterization3Id     := lCharacValueList(3).id;
    else
      lCharacterizationValue3  := null;
      lCharacterization3Id     := null;
    end if;

    if lIndex > 3 then
      lCharacterizationValue4  := lCharacValueList(4).value;
      lCharacterization4Id     := lCharacValueList(4).id;
    else
      lCharacterizationValue4  := null;
      lCharacterization4Id     := null;
    end if;

    if lIndex > 4 then
      lCharacterizationValue5  := lCharacValueList(5).value;
      lCharacterization5Id     := lCharacValueList(5).id;
    else
      lCharacterizationValue5  := null;
      lCharacterization5Id     := null;
    end if;

    if lStockManagement = 2 then
      -- Recherche genre de mvt
      select max(c_movement_type)
        into lTmpMvtType
        from stm_movement_kind
       where stm_movement_kind_id = iotMovementRecord.STM_MOVEMENT_KIND_ID;
    end if;

    --La mise à jour des positions se fait uniquement pour les produits gérés en stock
    if     lStockManagement is not null
       and (    (lStockManagement = 1)
            or (     (lStockManagement = 2)
                and (lTmpMvtType = 'INV') ) ) then
      -- recherche le type afin de savoir si on a affaire à une entrée ou une sortie pour mettre un signe à la quantité
      select C_MOVEMENT_SORT
           , C_MOVEMENT_TYPE
           , C_MOVEMENT_CODE
           , MOK_VERIFY_CHARACTERIZATION
           , decode(C_MOVEMENT_TYPE, 'EXE', 'ME', decode(MOK_RETURN, 1, 'MR', 0, 'M') )   -- type d'update MR si le mouvement est un retour
           , decode(substr(C_MOVEMENT_TYPE, 1, 2), 'TR', 1, 0)
        into lMovementSort
           , lMovementType
           , lMovementCode
           , lVerifyChar
           , lUpdateMode
           , lTransfert
        from STM_MOVEMENT_KIND
       where STM_MOVEMENT_KIND_ID = iotMovementRecord.STM_MOVEMENT_KIND_ID;

      -- mise à jour de la table element_number et récupération des ID
      GetElementNumber(iGoodId                   => iotMovementRecord.GCO_GOOD_ID
                     , iUpdateMode               => lUpdateMode
                     , iMovementSort             => lMovementSort
                     , iMovementCode             => lMovementCode
                     , iCharacterizationId       => iotMovementRecord.GCO_CHARACTERIZATION_ID
                     , iCharacterization2Id      => iotMovementRecord.GCO_GCO_CHARACTERIZATION_ID
                     , iCharacterization3Id      => iotMovementRecord.GCO2_GCO_CHARACTERIZATION_ID
                     , iCharacterization4Id      => iotMovementRecord.GCO3_GCO_CHARACTERIZATION_ID
                     , iCharacterization5Id      => iotMovementRecord.GCO4_GCO_CHARACTERIZATION_ID
                     , iCharacterizationValue1   => iotMovementRecord.SMO_CHARACTERIZATION_VALUE_1
                     , iCharacterizationValue2   => iotMovementRecord.SMO_CHARACTERIZATION_VALUE_2
                     , iCharacterizationValue3   => iotMovementRecord.SMO_CHARACTERIZATION_VALUE_3
                     , iCharacterizationValue4   => iotMovementRecord.SMO_CHARACTERIZATION_VALUE_4
                     , iCharacterizationValue5   => iotMovementRecord.SMO_CHARACTERIZATION_VALUE_5
                     , iVerifyChar               => lVerifyChar
                     , iElementStatus            => '02'
                     , ioElementNumberId1        => lElementNumber1
                     , ioElementNumberId2        => lElementNumber2
                     , ioElementNumberId3        => lElementNumber3
                     , ioQualityStatusId         => lQualityStatusId
                     , iDateMovement             => iotMovementRecord.SMO_MOVEMENT_DATE
                     , iTransfert                => lTransfert
                     , iExtourne                 => iotMovementRecord.SMO_EXTOURNE_MVT
                      );

      -- si on a affaire a un mouvement de type EXERCICE, il n'y a pas de mise à jour des positions
      -- pas de maj non plus pour les mouvements de type valeur 28.01.98 sk
      -- pas de maj non plus pour les corrections d'inventaire en valeur défini par une qté = 0 mais Val <> 0
      if     (lMovementType <> 'EXE')
         and (lMovementType <> 'VAL')
         and (    (iotMovementRecord.SMO_MOVEMENT_QUANTITY <> 0)
              or (iotMovementRecord.SMO_MVT_ALTERNATIV_QTY_1 <> 0)
              or (iotMovementRecord.SMO_MVT_ALTERNATIV_QTY_2 <> 0)
              or (iotMovementRecord.SMO_MVT_ALTERNATIV_QTY_3 <> 0)
             ) then
        -- mise à jour du signe de la quantité en fonction du tape de mouvement
        -- Suppression de move_sign 04.05.98 sk
        if lMovementSort = 'ENT' then
          lMvtQuantity  := iotMovementRecord.SMO_MOVEMENT_QUANTITY;
          lMvtAltQty1   := iotMovementRecord.SMO_MVT_ALTERNATIV_QTY_1;
          lMvtAltQty2   := iotMovementRecord.SMO_MVT_ALTERNATIV_QTY_2;
          lMvtAltQty3   := iotMovementRecord.SMO_MVT_ALTERNATIV_QTY_3;

          if     iotMovementRecord.DOC_POSITION_DETAIL_ID is not null
             and (iotMovementRecord.SMO_UPDATE_PROV = 1) then
            lMvtProvInput  := iotMovementRecord.SMO_MOVEMENT_QUANTITY;
          end if;
        else
          lMvtQuantity  := (-1) * iotMovementRecord.SMO_MOVEMENT_QUANTITY;
          lMvtAltQty1   := iotMovementRecord.SMO_MVT_ALTERNATIV_QTY_1 *(-1);
          lMvtAltQty2   := iotMovementRecord.SMO_MVT_ALTERNATIV_QTY_2 *(-1);
          lMvtAltQty3   := iotMovementRecord.SMO_MVT_ALTERNATIV_QTY_3 *(-1);

          if     iotMovementRecord.DOC_POSITION_DETAIL_ID is not null
             and (iotMovementRecord.SMO_UPDATE_PROV = 1) then
            lMvtProvOutput  := iotMovementRecord.SMO_MOVEMENT_QUANTITY;
          end if;
        end if;

        GetStockPositionId;

        if lStockPositionId is not null then
          -- Characterization denormalization. Only characterization with stock management mode
          GCO_LIB_CHARACTERIZATION.ClassifyCharacterizations(lCharacterizationId
                                                           , lCharacterization2Id
                                                           , lCharacterization3Id
                                                           , lCharacterization4Id
                                                           , lCharacterization5Id
                                                           , lCharacterizationValue1
                                                           , lCharacterizationValue2
                                                           , lCharacterizationValue3
                                                           , lCharacterizationValue4
                                                           , lCharacterizationValue5
                                                           , iotMovementRecord.SMO_PIECE
                                                           , iotMovementRecord.SMO_SET
                                                           , iotMovementRecord.SMO_VERSION
                                                           , iotMovementRecord.SMO_CHRONOLOGICAL
                                                           , iotMovementRecord.SMO_STD_CHAR_1
                                                           , iotMovementRecord.SMO_STD_CHAR_2
                                                           , iotMovementRecord.SMO_STD_CHAR_3
                                                           , iotMovementRecord.SMO_STD_CHAR_4
                                                           , iotMovementRecord.SMO_STD_CHAR_5
                                                            );

          begin
            -- dans ce cas, la position existe déjà et on a recours . une mise à jour
            update stm_stock_position
               set spo_stock_quantity =(spo_stock_quantity + lMvtQuantity)
                 , spo_available_quantity =(spo_stock_quantity + lMvtQuantity - spo_assign_quantity - spo_provisory_output + lMvtProvOutput)
                 , spo_theoretical_quantity =
                         (spo_stock_quantity + lMvtQuantity - spo_assign_quantity + spo_provisory_input - spo_provisory_output - lMvtProvInput + lMvtProvOutput
                         )
                 , spo_provisory_input = spo_provisory_input - lMvtProvInput
                 , spo_provisory_output = spo_provisory_output - lMvtProvOutput
                 , spo_alternativ_quantity_1 =(spo_alternativ_quantity_1 + lMvtAltQty1)
                 , spo_alternativ_quantity_2 =(spo_alternativ_quantity_2 + lMvtAltQty2)
                 , spo_alternativ_quantity_3 =(spo_alternativ_quantity_3 + lMvtAltQty3)
                 , STM_LAST_STOCK_MOVE_ID = iotMovementRecord.STM_STOCK_MOVEMENT_ID
                 , spo_last_inventory_date = decode(lMovementType, 'INV', iotMovementRecord.SMO_MOVEMENT_DATE, spo_last_inventory_date)
                 , SPO_PIECE = iotMovementRecord.SMO_PIECE
                 , SPO_SET = iotMovementRecord.SMO_SET
                 , SPO_VERSION = iotMovementRecord.SMO_VERSION
                 , SPO_CHRONOLOGICAL = iotMovementRecord.SMO_CHRONOLOGICAL
                 , SPO_STD_CHAR_1 = iotMovementRecord.SMO_STD_CHAR_1
                 , SPO_STD_CHAR_2 = iotMovementRecord.SMO_STD_CHAR_2
                 , SPO_STD_CHAR_3 = iotMovementRecord.SMO_STD_CHAR_3
                 , SPO_STD_CHAR_4 = iotMovementRecord.SMO_STD_CHAR_4
                 , SPO_STD_CHAR_5 = iotMovementRecord.SMO_STD_CHAR_5
                 , a_datemod = sysdate
                 , a_idmod = PCS.PC_I_LIB_SESSION.GetUserIni
             where stm_stock_position_id = lStockPositionId;
          exception
            when others then
              raise_application_error(-20000
                                    , 'Update Position=' || lStockPositionId || ' MoveQty=' || lMovementSort || '/' || lMvtQuantity || chr(13) || sqlerrm
                                     );
          end;

          DeleteNullPosition(lStockPositionId);
        end if;
      end if;
    end if;
  end updatePosition;

  /**
  * Description
  *    Mise à jour de la table des éléments et renvoie les ID touchés
  */
  procedure GetElementNumber(
    iGoodId                     in     number
  , iUpdateMode                 in     varchar2
  , iMovementSort               in     varchar2
  , iCharacterizationId         in     number
  , iCharacterization2Id        in     number
  , iCharacterization3Id        in     number
  , iCharacterization4Id        in     number
  , iCharacterization5Id        in     number
  , iCharacterizationValue1     in     varchar2
  , iCharacterizationValue2     in     varchar2
  , iCharacterizationValue3     in     varchar2
  , iCharacterizationValue4     in     varchar2
  , iCharacterizationValue5     in     varchar2
  , iVerifyChar                 in     number
  , iElementStatus              in     varchar2
  , ioElementNumberId1          in out number
  , ioElementNumberId2          in out number
  , ioElementNumberId3          in out number
  , ioQualityStatusId           in out number
  , iDateMovement               in     date default null
  , iTransfert                  in     number default 0
  , iExtourne                   in     number default 0
  , iCharacterizationTwinValue1 in     varchar2 default null
  , iCharacterizationTwinValue2 in     varchar2 default null
  , iCharacterizationTwinValue3 in     varchar2 default null
  , iCharacterizationTwinValue4 in     varchar2 default null
  , iCharacterizationTwinValue5 in     varchar2 default null
  , iMovementCode               in     varchar2 default '000'
  )
  is
    lCharacId        GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharacType      GCO_CHARACTERIZATION.C_CHARACT_TYPE%type;
    lCharacAutoinc   GCO_CHARACTERIZATION.CHA_AUTOMATIC_INCREMENTATION%type;
    lCharacIncstep   GCO_CHARACTERIZATION.CHA_INCREMENT_STE%type;
    lStockManagement GCO_CHARACTERIZATION.CHA_STOCK_MANAGEMENT%type;
    lSemvalue        STM_ELEMENT_NUMBER.SEM_VALUE%type;
    lSemstatus       STM_ELEMENT_NUMBER.C_ELE_NUM_STATUS%type;
    lQualityStatusId STM_ELEMENT_NUMBER.GCO_QUALITY_STATUS_ID%type;
    lAlreadyExist    number(1);
    lUpdateMode      varchar2(3);

    cursor lcurElementNumber(iCharac1 number, iCharac2 number, iCharac3 number, iCharac4 number, iCharac5 number)
    is
      select   GCO_CHARACTERIZATION_ID
             , C_CHARACT_TYPE
             , decode(PDT_STOCK_MANAGEMENT, 1, CHA_STOCK_MANAGEMENT, 0) CHA_STOCK_MANAGEMENT
             , decode(GCO_CHAR_AUTONUM_FUNC_ID, null, CHA_AUTOMATIC_INCREMENTATION, 0)
             , CHA_INCREMENT_STE
          from GCO_CHARACTERIZATION CHA
             , GCO_PRODUCT PDT
         where (   GCO_CHARACTERIZATION_ID = iCharac1
                or GCO_CHARACTERIZATION_ID = iCharac2
                or GCO_CHARACTERIZATION_ID = iCharac3
                or GCO_CHARACTERIZATION_ID = iCharac4
                or GCO_CHARACTERIZATION_ID = iCharac5
               )
           and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
           and C_CHARACT_TYPE in(STM_I_LIB_CONSTANT.gcCharacTypeVersion, STM_I_LIB_CONSTANT.gcCharacTypePiece, STM_I_LIB_CONSTANT.gcCharacTypeSet)
      order by GCO_CHARACTERIZATION_ID asc;
  begin
    -- Positionnement sur  premier tuple du curseur
    open lcurElementNumber(iCharacterizationId, iCharacterization2Id, iCharacterization3Id, iCharacterization4Id, iCharacterization5Id);

    -- Recherche l'ID et le type de la première caractérisation (pièce, lot ou version)
    fetch lcurElementNumber
     into lCharacId
        , lCharacType
        , lStockManagement
        , lCharacAutoinc
        , lCharacIncstep;

    if lcurElementNumber%found then
      lUpdateMode  := iUpdateMode;

      -- Recherche la valeur de l'élement de la première caractérisation (pièce, lot ou version)
      if lCharacId = iCharacterizationId then
        lSemvalue  := iCharacterizationValue1;

        if     lUpdateMode = 'DU'
           and iCharacterizationValue1 = iCharacterizationTwinValue1 then
          lUpdateMode  := 'I';
        end if;
      else
        if lCharacId = iCharacterization2Id then
          lSemvalue  := iCharacterizationValue2;

          if     lUpdateMode = 'DU'
             and iCharacterizationValue2 = iCharacterizationTwinValue2 then
            lUpdateMode  := 'I';
          end if;
        else
          if lCharacId = iCharacterization3Id then
            lSemvalue  := iCharacterizationValue3;

            if     lUpdateMode = 'DU'
               and iCharacterizationValue3 = iCharacterizationTwinValue3 then
              lUpdateMode  := 'I';
            end if;
          else
            if lCharacId = iCharacterization4Id then
              lSemvalue  := iCharacterizationValue4;

              if     lUpdateMode = 'DU'
                 and iCharacterizationValue4 = iCharacterizationTwinValue4 then
                lUpdateMode  := 'I';
              end if;
            else
              if lCharacId = iCharacterization5Id then
                lSemvalue  := iCharacterizationValue5;

                if     lUpdateMode = 'DU'
                   and iCharacterizationValue5 = iCharacterizationTwinValue5 then
                  lUpdateMode  := 'I';
                end if;
              end if;
            end if;
          end if;
        end if;
      end if;

      -- Définition du statut de l'élement à mettre à jour.
      --
      -- Le statut est définit avec:
      --
      --   1. le paramètre transmit si pas null.
      --   2. la valeur <réservé> ('03') si la caractérisation est gérée en stock.
      --   3. la valeur <inactif> ('01') si la caractérisation n'est pas gérée en stock.
      --
      lSemstatus   := iElementStatus;

      if (lSemstatus is null) then
        if lStockManagement = 1 then
          lSemstatus  := STM_I_LIB_CONSTANT.gcEleNumStatusReserved;
        else
          lSemstatus  := STM_I_LIB_CONSTANT.gcEleNumStatusInactive;
        end if;
      end if;

      if     (lSemstatus = '00')
         and (lStockManagement = 1) then
        lSemstatus  := STM_I_LIB_CONSTANT.gcEleNumStatusActive;
      end if;

      if     lSemvalue is not null
         and (lSemvalue <> 'N/A') then
        lQualityStatusId  := null;
        -- mise à jour de la table stm_element_number avec la valeur trouvée
        ManageElementNumber(iGoodId             => iGoodId
                          , iCharId             => lCharacId
                          , iStockManagement    => lStockManagement
                          , iUpdateMode         => lUpdateMode
                          , iMovementSort       => iMovementSort
                          , iMovementCode       => iMovementCode
                          , iCharacType         => lCharacType
                          , iSemValue           => lSemvalue
                          , iElementStatus      => lSemstatus
                          , iVerifyChar         => iVerifyChar
                          , iAutoInc            => lCharacAutoinc
                          , iIncStep            => lCharacIncstep
                          , oElementNumber      => ioElementNumberId1
                          , ioQualityStatusId   => lQualityStatusId
                          , oAlreadyExist       => lAlreadyExist
                          , iDateMovement       => iDateMovement
                          , iTransfert          => iTransfert
                          , iExtourne           => iExtourne
                           );

        -- Retourne le statut qualité
        if lQualityStatusId is not null then
          ioQualityStatusId  := lQualityStatusId;
        end if;
      end if;

      if lStockManagement <> 1 then
        ioElementNumberId1  := null;
      end if;

      -- Recherche l'ID et le type de la deuxième caractérisation (pièce, lot ou version)
      fetch lcurElementNumber
       into lCharacId
          , lCharacType
          , lStockManagement
          , lCharacAutoinc
          , lCharacIncstep;

      if lcurElementNumber%found then
        lUpdateMode  := iUpdateMode;

        -- Recherche la valeur de l'élement de la première caractérisation (pièce, lot ou version)
        if lCharacId = iCharacterizationId then
          lSemvalue  := iCharacterizationValue1;

          if     lUpdateMode = 'DU'
             and iCharacterizationValue1 = iCharacterizationTwinValue1 then
            lUpdateMode  := 'I';
          end if;
        else
          if lCharacId = iCharacterization2Id then
            lSemvalue  := iCharacterizationValue2;

            if     lUpdateMode = 'DU'
               and iCharacterizationValue2 = iCharacterizationTwinValue2 then
              lUpdateMode  := 'I';
            end if;
          else
            if lCharacId = iCharacterization3Id then
              lSemvalue  := iCharacterizationValue3;

              if     lUpdateMode = 'DU'
                 and iCharacterizationValue3 = iCharacterizationTwinValue3 then
                lUpdateMode  := 'I';
              end if;
            else
              if lCharacId = iCharacterization4Id then
                lSemvalue  := iCharacterizationValue4;

                if     lUpdateMode = 'DU'
                   and iCharacterizationValue4 = iCharacterizationTwinValue4 then
                  lUpdateMode  := 'I';
                end if;
              else
                if lCharacId = iCharacterization5Id then
                  lSemvalue  := iCharacterizationValue5;

                  if     lUpdateMode = 'DU'
                     and iCharacterizationValue5 = iCharacterizationTwinValue5 then
                    lUpdateMode  := 'I';
                  end if;
                end if;
              end if;
            end if;
          end if;
        end if;

        -- Définition du statut de l'élement à mettre à jour.
        --
        -- Le statut est définit avec:
        --
        --   1. le paramètre transmit si pas null.
        --   2. la valeur <réservé> ('03') si la caractérisation est gérée en stock.
        --   3. la valeur <inactif> ('01') si la caractérisation n'est pas gérée en stock.
        --
        lSemstatus   := iElementStatus;

        if (lSemstatus is null) then
          if lStockManagement = 1 then
            lSemstatus  := STM_I_LIB_CONSTANT.gcEleNumStatusReserved;
          else
            lSemstatus  := STM_I_LIB_CONSTANT.gcEleNumStatusInactive;
          end if;
        end if;

        if     (lSemstatus = '00')
           and (lStockManagement = 1) then
          lSemstatus  := STM_I_LIB_CONSTANT.gcEleNumStatusActive;
        end if;

        if     lSemvalue is not null
           and (lSemvalue <> 'N/A') then
          lQualityStatusId  := null;
          -- mise à jour de la table stm_element_number avec la valeur trouvée
          ManageElementNumber(iGoodId             => iGoodId
                            , iCharId             => lCharacId
                            , iStockManagement    => lStockManagement
                            , iUpdateMode         => lUpdateMode
                            , iMovementSort       => iMovementSort
                            , iMovementCode       => iMovementCode
                            , iCharacType         => lCharacType
                            , iSemValue           => lSemvalue
                            , iElementStatus      => lSemstatus
                            , iVerifyChar         => iVerifyChar
                            , iAutoInc            => lCharacAutoinc
                            , iIncStep            => lCharacIncstep
                            , oElementNumber      => ioElementNumberId2
                            , ioQualityStatusId   => lQualityStatusId
                            , oAlreadyExist       => lAlreadyExist
                            , iDateMovement       => iDateMovement
                            , iTransfert          => iTransfert
                            , iExtourne           => iExtourne
                             );

          -- Retourne le statut qualité
          if lQualityStatusId is not null then
            ioQualityStatusId  := lQualityStatusID;
          end if;
        end if;

        if lStockManagement <> 1 then
          ioElementNumberId2  := null;
        end if;

        -- Recherche l'ID et le type de la troisième caractérisation (pièce, lot ou version)
        fetch lcurElementNumber
         into lCharacId
            , lCharacType
            , lStockManagement
            , lCharacAutoinc
            , lCharacIncstep;

        if lcurElementNumber%found then
          lUpdateMode  := iUpdateMode;

          -- Recherche la valeur de l'élement de la première caractérisation (pièce, lot ou version)
          if lCharacId = iCharacterizationId then
            lSemvalue  := iCharacterizationValue1;

            if     lUpdateMode = 'DU'
               and iCharacterizationValue1 = iCharacterizationTwinValue1 then
              lUpdateMode  := 'I';
            end if;
          else
            if lCharacId = iCharacterization2Id then
              lSemvalue  := iCharacterizationValue2;

              if     lUpdateMode = 'DU'
                 and iCharacterizationValue2 = iCharacterizationTwinValue2 then
                lUpdateMode  := 'I';
              end if;
            else
              if lCharacId = iCharacterization3Id then
                lSemvalue  := iCharacterizationValue3;

                if     lUpdateMode = 'DU'
                   and iCharacterizationValue3 = iCharacterizationTwinValue3 then
                  lUpdateMode  := 'I';
                end if;
              else
                if lCharacId = iCharacterization4Id then
                  lSemvalue  := iCharacterizationValue4;

                  if     lUpdateMode = 'DU'
                     and iCharacterizationValue4 = iCharacterizationTwinValue4 then
                    lUpdateMode  := 'I';
                  end if;
                else
                  if lCharacId = iCharacterization5Id then
                    lSemvalue  := iCharacterizationValue5;

                    if     lUpdateMode = 'DU'
                       and iCharacterizationValue5 = iCharacterizationTwinValue5 then
                      lUpdateMode  := 'I';
                    end if;
                  end if;
                end if;
              end if;
            end if;
          end if;

          -- Définition du statut de l'élement à mettre à jour.
          --
          -- Le statut est définit avec:
          --
          --   1. le paramètre transmit si pas null.
          --   2. la valeur <réservé> ('03') si la caractérisation est gérée en stock.
          --   3. la valeur <inactif> ('01') si la caractérisation n'est pas gérée en stock.
          --
          lSemstatus   := iElementStatus;

          if (lSemstatus is null) then
            if lStockManagement = 1 then
              lSemstatus  := STM_I_LIB_CONSTANT.gcEleNumStatusReserved;
            else
              lSemstatus  := STM_I_LIB_CONSTANT.gcEleNumStatusInactive;
            end if;
          end if;

          if     (lSemstatus = '00')
             and (lStockManagement = 1) then
            lSemstatus  := STM_I_LIB_CONSTANT.gcEleNumStatusActive;
          end if;

          if     lSemvalue is not null
             and (lSemvalue <> 'N/A') then
            lQualityStatusId  := null;
            -- mise à jour de la table stm_element_number avec la valeur trouvée
            ManageElementNumber(iGoodId             => iGoodId
                              , iCharId             => lCharacId
                              , iStockManagement    => lStockManagement
                              , iUpdateMode         => lUpdateMode
                              , iMovementSort       => iMovementSort
                              , iMovementCode       => iMovementCode
                              , iCharacType         => lCharacType
                              , iSemValue           => lSemvalue
                              , iElementStatus      => lSemstatus
                              , iVerifyChar         => iVerifyChar
                              , iAutoInc            => lCharacAutoinc
                              , iIncStep            => lCharacIncstep
                              , oElementNumber      => ioElementNumberId3
                              , ioQualityStatusId   => lQualityStatusId
                              , oAlreadyExist       => lAlreadyExist
                              , iDateMovement       => iDateMovement
                              , iTransfert          => iTransfert
                              , iExtourne           => iExtourne
                               );

            -- Retourne le statut qualité
            if lQualityStatusId is not null then
              ioQualityStatusId  := lQualityStatusId;
            end if;
          end if;

          if lStockManagement <> 1 then
            ioElementNumberId3  := null;
          end if;
        end if;
      end if;

      -- Supprime les "trous" dans les id des élements.
      if     ioElementNumberId1 is null
         and ioElementNumberId2 is null then
        ioElementNumberId1  := ioElementNumberId3;
        ioElementNumberId3  := null;
      else
        if     ioElementNumberId1 is null
           and ioElementNumberId2 is not null then
          ioElementNumberId1  := ioElementNumberId2;
          ioElementNumberId2  := null;
        end if;
      end if;

      if     ioElementNumberId2 is null
         and ioElementNumberId3 is not null then
        ioElementNumberId2  := ioElementNumberId3;
        ioElementNumberId3  := null;
      end if;
    end if;

    close lcurElementNumber;
  end GetElementNumber;

  /**
  * Description
  *    Maj et interrogation de la table de gestion des lots, numéros de séries
  *    Utilise une trasaction autonome
  */
  procedure ManageElementNumber(
    iGoodId           in     number
  , iCharId           in     number
  , iStockManagement  in     number
  , iUpdateMode       in     varchar2
  , iMovementSort     in     varchar2
  , iMovementCode     in     varchar2 default '000'
  , iCharacType       in     varchar2
  , iSemValue         in     varchar2
  , iElementStatus    in     varchar2
  , iVerifyChar       in     number
  , iAutoInc          in     number
  , iIncStep          in     number
  , oElementNumber    out    number
  , ioQualityStatusId in out number
  , oAlreadyExist     out    number
  , iDateRetest       in     date default null
  , iDateMovement     in     date default null
  , iTransfert        in     number default 0
  , iExtourne         in     number default 0
  )
  is
    lElementNumberId          STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    lElementType              STM_ELEMENT_NUMBER.C_ELEMENT_TYPE%type;
    lEleNumStatus             STM_ELEMENT_NUMBER.C_ELE_NUM_STATUS%type;
    lOldEleNumStatus          STM_ELEMENT_NUMBER.C_OLD_ELE_NUM_STATUS%type;
    lOldStatus                STM_ELEMENT_NUMBER.C_OLD_ELE_NUM_STATUS%type;
    lNewEleNumStatus          STM_ELEMENT_NUMBER.C_ELE_NUM_STATUS%type;
    lEleNumStatusFctStat      STM_ELEMENT_NUMBER.C_ELE_NUM_STATUS%type;
    lEleNumStatusFctUnique    STM_ELEMENT_NUMBER.C_ELE_NUM_STATUS%type;
    lEleNumStatusFctTypePiece STM_ELEMENT_NUMBER.C_ELE_NUM_STATUS%type;
    lEleGoodId                STM_ELEMENT_NUMBER.GCO_GOOD_ID%type;
    lRetestDate               STM_ELEMENT_NUMBER.SEM_RETEST_DATE%type         := null;
    lEleMajorReference        GCO_GOOD.GOO_MAJOR_REFERENCE%type;
    lControlMode              number(1);
    lUniqueCompany            boolean;
    lUniqueness               number(1);
    lElementDescr             varchar2(10);
  begin
    if iSemValue <> 'N/A' then
      -- conversion de charact_type en lElementType
      if iCharacType = STM_I_LIB_CONSTANT.gcCharacTypeVersion then
        lElementType    := STM_I_LIB_CONSTANT.gcElementTypeVersion;   -- version
        lElementDescr   := PCS.PC_FUNCTIONS.TranslateWord('version');
        lUniqueCompany  := STM_I_LIB_CONSTANT.gcCfgVersionSglNumberingComp;

        if    STM_I_LIB_CONSTANT.gcCfgVersionSglNumberingComp
           or STM_I_LIB_CONSTANT.gcCfgVersionSglNumberingGood
           or STM_I_LIB_CONSTANT.gcCfgVersionSglNumberingDet then
          lUniqueness  := 1;
        end if;
      elsif iCharacType = STM_I_LIB_CONSTANT.gcCharacTypePiece then
        lElementType    := STM_I_LIB_CONSTANT.gcElementTypePiece;   -- pièces
        lElementDescr   := PCS.PC_FUNCTIONS.TranslateWord('pièce');
        lUniqueCompany  := STM_I_LIB_CONSTANT.gcCfgPieceSglNumberingComp;
        lUniqueness     := 1;
      elsif iCharacType = STM_I_LIB_CONSTANT.gcCharacTypeSet then
        lElementType    := STM_I_LIB_CONSTANT.gcElementTypeSet;   -- lots
        lElementDescr   := PCS.PC_FUNCTIONS.TranslateWord('lot');
        lUniqueCompany  := STM_I_LIB_CONSTANT.gcCfgSetSglNumberingComp;

        if    STM_I_LIB_CONSTANT.gcCfgSetSglNumberingComp
           or STM_I_LIB_CONSTANT.gcCfgSetSglNumberingGood
           or STM_I_LIB_CONSTANT.gcCfgSetSglNumberingDet then
          lUniqueness  := 1;
        end if;
      end if;

      -- Initialisation de la date de ré-analyse ( en fonction de la date du mouvement )
      lRetestDate     := iDateRetest;

      if     lRetestDate is null
         and iDateMovement is not null
         and GCO_I_LIB_CHARACTERIZATION.charUseRetestDate(iCharId) = 1 then
        lRetestDate  := iDateMovement + GCO_I_LIB_CHARACTERIZATION.GetRetestDelay(iGoodId);
      end if;

      -- recherche d'un element number existant (attention config)
      if lUniqueCompany then
        begin
          select ele.stm_element_number_id
               , ele.c_ele_num_status
               , ele.c_old_ele_num_status
               , ele.gco_good_id
               , nvl(ioQualityStatusId, ele.GCO_QUALITY_STATUS_ID)
               , goo.goo_major_reference
            into lElementNumberId
               , lEleNumStatus
               , lOldEleNumStatus
               , lEleGoodId
               , ioQualityStatusId
               , lEleMajorReference
            from stm_element_number ele
               , gco_good goo
           where ele.c_element_type = lElementType
             and ele.gco_good_id = goo.gco_good_id
             and sem_value = iSemValue
             and (    (    (iMovementSort = 'ENT')
                       or (    iMovementSort = 'SOR'
                           and iStockManagement = 0) )
                  or ele.gco_good_id = iGoodId);

          if lEleGoodId <> iGoodId then   -- si le numéro est déjà affecté à un autre bien
            raise_application_error
              (-20082
             , replace
                 (replace
                    (replace
                       (PCS.PC_FUNCTIONS.TranslateWord
                                                    ('PCS - Ce numéro de ELEMENT_DESCR existe déjà pour le bien : MAJOR_REFERENCE. Numéro incriminé : SEMVALUE.')
                      , 'ELEMENT_DESCR'
                      , lElementDescr
                       )
                   , 'MAJOR_REFERENCE'
                   , lEleMajorReference
                    )
                , 'SEMVALUE'
                , iSemValue
                 )
              );
          end if;

          oAlreadyExist  := 1;
        exception
          when no_data_found then
            lElementNumberId  := null;
            lEleGoodId        := null;
            oAlreadyExist     := 0;
            lEleNumStatus     := '00';
          when too_many_rows then
            raise_application_error
              (-20080
             , replace
                 (replace
                    (replace
                       (PCS.PC_FUNCTIONS.TranslateWord
                                          ('PCS - Double utilisation d''un numéro de ELEMENT_DESCR pour le bien : MAJOR_REFERENCE. Numéro incriminé : SEMVALUE.')
                      , 'ELEMENT_DESCR'
                      , lElementDescr
                       )
                   , 'MAJOR_REFERENCE'
                   , lEleMajorReference
                    )
                , 'SEMVALUE'
                , iSemValue
                 )
              );
        end;
      else
        begin
          select ele.stm_element_number_id
               , ele.c_ele_num_status
               , ele.c_old_ele_num_status
               , ele.gco_good_id
               , nvl(ioQualityStatusId, ele.GCO_QUALITY_STATUS_ID)
               , goo.goo_major_reference
            into lElementNumberId
               , lEleNumStatus
               , lOldEleNumStatus
               , lEleGoodId
               , ioQualityStatusId
               , lEleMajorReference
            from stm_element_number ele
               , gco_good goo
           where goo.gco_good_id = iGoodId
             and ele.gco_good_id = goo.gco_good_id
             and c_element_type = lElementType
             and sem_value = iSemValue;

          oAlreadyExist  := 1;
        exception
          when no_data_found then
            lElementNumberId  := null;
            lEleGoodId        := null;
            oAlreadyExist     := 0;
            lEleNumStatus     := '00';
          when too_many_rows then
            raise_application_error
              (-20081
             , replace
                 (replace
                    (replace
                       (PCS.PC_FUNCTIONS.TranslateWord
                          ('PCS - Double utilisation d''un numéro de ELEMENT_DESCR pour le même bien. Référence bien : MAJOR_REFERENCE. Numéro incriminé : SEMVALUE.'
                          )
                      , 'ELEMENT_DESCR'
                      , lElementDescr
                       )
                   , 'SEMVALUE'
                   , iSemValue
                    )
                , 'MAJOR_REFERENCE'
                , lEleMajorReference
                 )
              );
        end;
      end if;

      -- Initialisation des statuts pour l'insertion / mise à jour
      if lUniqueness = 1 then
        lEleNumStatusFctUnique  := STM_I_LIB_CONSTANT.gcEleNumStatusReserved;
      else
        lEleNumStatusFctUnique  := STM_I_LIB_CONSTANT.gcEleNumStatusActive;
      end if;

      if iCharacType = STM_I_LIB_CONSTANT.gcCharacTypePiece then
        lEleNumStatusFctTypePiece  := STM_I_LIB_CONSTANT.gcEleNumStatusReserved;
      else
        lEleNumStatusFctTypePiece  := STM_I_LIB_CONSTANT.gcEleNumStatusActive;
      end if;

      if lEleNumStatus = STM_LIB_CONSTANT.gcEleNumStatusInactive then
        lEleNumStatusFctStat  := lOldEleNumStatus;
      else
        lEleNumStatusFctStat  := lEleNumStatus;
      end if;

      -- Mode création
      if iUpdateMode in('I', 'IR', 'IW') then
        -- Maj ev. du dernier incrément utilisé pour les pièces et les lots
        if     iAutoInc = 1
           and not(    iCharacType = STM_I_LIB_CONSTANT.gcCharacTypeVersion
                   and GCO_LIB_CHARACTERIZATION.IsVersioningManagement(iGoodId) = 1) then
          GCO_PRC_CHARACTERIZATION.UpdateCharLastUsedNumber(iCharId, iSemValue);
        end if;

        -- Mouvement d'entrée
        if iMovementSort = 'ENT' then
          -- recherche de la valeur de controle
          lControlMode  := GetControlMode(iGoodId, iCharacType, iSemValue);

          if iUpdateMode = 'IW' then
            lOldStatus  := lEleNumStatusFctUnique;
          end if;

          -- Caractérisation gérée en stock
          if iStockManagement = 1 then
            -- vérification de la caractérisation (STM_MOVEMENT_KIND.MOK_VERIFY_CHARACTERIZATION = 1)
            if iVerifyChar = 1 then
              if (lControlMode = 0) then
                if lElementNumberId is null then
                  -- Insertion d'un nouveau détail de caractérisation
                  STM_PRC_ELEMENT_NUMBER.CreateDetail(oElementNumberId    => lElementNumberId
                                                    , iGoodId             => iGoodId
                                                    , iStatus             => lEleNumStatusFctUnique
                                                    , iOldStatus          => lOldStatus
                                                    , iElementType        => lElementType
                                                    , iValue              => iSemValue
                                                    , iRetestDate         => lRetestDate
                                                    , ioQualityStatusId   => ioQualityStatusId
                                                     );
                else
                  if iTransfert = 0 then
                    STM_PRC_ELEMENT_NUMBER.UpdateElementNumber(iElementNumberID   => lElementNumberId
                                                             , iStatus            => STM_I_LIB_CONSTANT.gcEleNumStatusReserved
                                                             , iRetestDate        => lRetestDate
                                                              );
                  end if;
                end if;
              else
                if iTransfert = 0 then
                  STM_PRC_ELEMENT_NUMBER.UpdateElementNumber(iElementNumberID   => lElementNumberId
                                                           , iStatus            => lEleNumStatusFctTypePiece
                                                           , iRetestDate        => lRetestDate
                                                            );
                end if;
              end if;
            else
              if (lControlMode = 0) then
                if lElementNumberId is null then
                  -- Insertion d'un nouveau détail de caractérisation
                  STM_PRC_ELEMENT_NUMBER.createDetail(oElementNumberId    => lElementNumberId
                                                    , iGoodId             => iGoodId
                                                    , iStatus             => lEleNumStatusFctUnique
                                                    , iOldStatus          => lOldStatus
                                                    , iElementType        => lElementType
                                                    , iValue              => iSemValue
                                                    , iRetestDate         => lRetestDate
                                                    , ioQualityStatusId   => ioQualityStatusId
                                                     );
                else
                  if iTransfert = 0 then
                    STM_PRC_ELEMENT_NUMBER.UpdateElementNumber(iElementNumberID   => lElementNumberId
                                                             , iStatus            => STM_I_LIB_CONSTANT.gcEleNumStatusReserved
                                                             , iRetestDate        => lRetestDate
                                                              );
                  end if;
                end if;
              else
                if iTransfert = 0 then
                  STM_PRC_ELEMENT_NUMBER.UpdateElementNumber(iElementNumberID   => lElementNumberId
                                                           , iStatus            => lEleNumStatusFctTypePiece
                                                           , iRetestDate        => lRetestDate
                                                            );
                end if;
              end if;
            end if;
          elsif iStockManagement = 0 then
            if     lElementNumberId is null
               and iCharacType <> STM_I_LIB_CONSTANT.gcCharacTypePiece then
              -- Insertion d'un nouveau détail de caractérisation
              STM_PRC_ELEMENT_NUMBER.createDetail(oElementNumberId    => lElementNumberId
                                                , iGoodId             => iGoodId
                                                , iStatus             => STM_I_LIB_CONSTANT.gcEleNumStatusActive
                                                , iOldStatus          => lOldStatus
                                                , iElementType        => lElementType
                                                , iValue              => iSemValue
                                                , iRetestDate         => lRetestDate
                                                , ioQualityStatusId   => ioQualityStatusId
                                                 );
            elsif lElementNumberId is not null then
              if iTransfert = 0 then
                STM_PRC_ELEMENT_NUMBER.UpdateElementNumber(iElementNumberID   => lElementNumberId
                                                         , iStatus            => lEleNumStatusFctTypePiece
                                                         , iRetestDate        => lRetestDate
                                                          );
              end if;
            end if;
          end if;
        elsif iMovementSort = 'SOR' then
          -- Caractérisation gérée en stock
          if iStockManagement = 1 then
            if     lElementNumberId is not null
               and iCharacType in(STM_I_LIB_CONSTANT.gcCharacTypePiece) then
              if iTransfert = 0 then
                STM_PRC_ELEMENT_NUMBER.UpdateElementNumber(iElementNumberID => lElementNumberId, iStatus => STM_I_LIB_CONSTANT.gcEleNumStatusReserved);
              end if;
            elsif     lElementNumberId is not null
                  and iCharacType in(STM_I_LIB_CONSTANT.gcCharacTypeSet, STM_I_LIB_CONSTANT.gcCharacTypeVersion) then
              if iTransfert = 0 then
                STM_PRC_ELEMENT_NUMBER.UpdateElementNumber(iElementNumberID => lElementNumberId, iStatus => STM_I_LIB_CONSTANT.gcEleNumStatusActive);
              end if;
            elsif lElementNumberId is null then
              -- Insertion d'un nouveau détail de caractérisation
              STM_PRC_ELEMENT_NUMBER.createDetail(oElementNumberId    => lElementNumberId
                                                , iGoodId             => iGoodId
                                                , iStatus             => lEleNumStatusFctUnique
                                                , iElementType        => lElementType
                                                , iValue              => iSemValue
                                                , iRetestDate         => lRetestDate
                                                , ioQualityStatusId   => ioQualityStatusId
                                                 );
            end if;
          -- Caractérisation non gérée en stock
          elsif iStockManagement = 0 then
            lControlMode  := GetControlMode(iGoodId, iCharacType, iSemValue);

            -- vérification de la caractérisation (STM_MOVEMENT_KIND.MOK_VERIFY_CHARACTERIZATION = 1)
            if iVerifyChar = 1 then
              if (lControlMode = 0) then
                if lElementNumberId is null then
                  -- Insertion d'un nouveau détail de caractérisation
                  STM_PRC_ELEMENT_NUMBER.createDetail(oElementNumberId    => lElementNumberId
                                                    , iGoodId             => iGoodId
                                                    , iStatus             => lEleNumStatusFctUnique
                                                    , iElementType        => lElementType
                                                    , iValue              => iSemValue
                                                    , iRetestDate         => lRetestDate
                                                    , ioQualityStatusId   => ioQualityStatusId
                                                     );
                else
                  if iTransfert = 0 then
                    STM_PRC_ELEMENT_NUMBER.UpdateElementNumber(iElementNumberID => lElementNumberId, iStatus => lEleNumStatusFctUnique);
                  end if;
                end if;
              else
                if iTransfert = 0 then
                  STM_PRC_ELEMENT_NUMBER.UpdateElementNumber(iElementNumberID => lElementNumberId, iStatus => STM_I_LIB_CONSTANT.gcEleNumStatusActive);
                end if;
              end if;
            end if;
          end if;
        end if;
      -- Mode entrée pour historique (vieux numéros de série).
      -- Pas lié à une entrée en stock
      elsif iUpdateMode = 'H' then
        -- recherche de la valeur de controle
        lControlMode  := GetControlMode(iGoodId, iCharacType, iSemValue);

        -- Maj ev. du dernier incrément utilisé pour les pièces et les lots
        if     iAutoInc = 1
           and not(    iCharacType = STM_I_LIB_CONSTANT.gcCharacTypeVersion
                   and GCO_LIB_CHARACTERIZATION.IsVersioningManagement(iGoodId) = 1) then
          GCO_PRC_CHARACTERIZATION.UpdateCharLastUsedNumber(iCharId, iSemValue);
        end if;

        if (lControlMode = 0) then
          if lElementNumberId is null then
            -- Insertion d'un nouveau détail de caractérisation
            STM_PRC_ELEMENT_NUMBER.createDetail(oElementNumberId    => lElementNumberId
                                              , iGoodId             => iGoodId
                                              , iStatus             => STM_I_LIB_CONSTANT.gcEleNumStatusActive
                                              , iElementType        => lElementType
                                              , iValue              => iSemValue
                                              , iRetestDate         => lRetestDate
                                              , ioQualityStatusId   => ioQualityStatusId
                                               );
          else
            if    lEleNumStatus <> STM_I_LIB_CONSTANT.gcEleNumStatusActive
               or lOldEleNumStatus is null then
              STM_PRC_ELEMENT_NUMBER.UpdateElementNumber(iElementNumberID   => lElementNumberId
                                                       , iStatus            => STM_I_LIB_CONSTANT.gcEleNumStatusActive
                                                       , iOldStatus         => STM_I_LIB_CONSTANT.gcEleNumStatusActive
                                                        );
            end if;
          end if;
        else
          if lEleNumStatus <> STM_I_LIB_CONSTANT.gcEleNumStatusActive then
            STM_PRC_ELEMENT_NUMBER.UpdateElementNumber(iElementNumberID   => lElementNumberId
                                                     , iStatus            => STM_I_LIB_CONSTANT.gcEleNumStatusActive
                                                     , iOldStatus         => lEleNumStatusFctStat
                                                      );
          end if;
        end if;
      -- Effacement d'un détail crée par décharge
      elsif iUpdateMode = 'DD' then
        null;
      -- Effacement d'un détail lors d'un archivage
      elsif iUpdateMode = 'DA' then
        null;
      -- Effacement
      elsif iUpdateMode in('D', 'DU') then
        if lOldEleNumStatus is null then
          STM_PRC_ELEMENT_NUMBER.DeleteDetail(iElementNumberID => lElementNumberId);
          lElementNumberId  := null;
        else
          STM_PRC_ELEMENT_NUMBER.UpdateElementNumber(iElementNumberID => lElementNumberId, iStatus => lOldEleNumStatus);
        end if;
      -- Confirmation document (génération du mouvement de stock)
      elsif iUpdateMode in('M', 'MR') then
        if     lElementNumberId is not null
           and lUniqueness = 1
           and iUpdateMode = 'MR' then
          if iExtourne = 1 then
            lNewEleNumStatus  := null;
          else
            lNewEleNumStatus  := STM_I_LIB_CONSTANT.gcEleNumStatusReturned;
          end if;
        else
          if iExtourne = 1 then
            lNewEleNumStatus  := null;
          else
            lNewEleNumStatus  := STM_I_LIB_CONSTANT.gcEleNumStatusActive;
          end if;
        end if;

        -- Maj ev. du dernier incrément utilisé pour les pièces et les lots
        if     iAutoInc = 1
           and not(    iCharacType = STM_I_LIB_CONSTANT.gcCharacTypeVersion
                   and GCO_LIB_CHARACTERIZATION.IsVersioningManagement(iGoodId) = 1) then
          GCO_PRC_CHARACTERIZATION.UpdateCharLastUsedNumber(iCharId, iSemValue);
        end if;

        --raise_application_error(-20000,iUpdateMode||'/'||vNewEleNumStatus||'/'||vUniqueness||'/'||vElementNumberId);
        if iVerifyChar = 1 then
          -- Caractérisation gérée en stock
          if iStockManagement = 1 then
            -- Mouvement d'entrée
            if iMovementSort = 'ENT' then
              if lElementNumberId is null then
                -- Insertion d'un nouveau détail de caractérisation
                STM_PRC_ELEMENT_NUMBER.createDetail(oElementNumberId    => lElementNumberId
                                                  , iGoodId             => iGoodId
                                                  , iStatus             => lNewEleNumStatus
                                                  , iOldStatus          => STM_I_LIB_CONSTANT.gcEleNumStatusActive
                                                  , iElementType        => lElementType
                                                  , iValue              => iSemValue
                                                  , iRetestDate         => lRetestDate
                                                  , ioQualityStatusId   => ioQualityStatusId
                                                   );
              else
                -- if manual input
                if iMovementCode = '006' then
                  -- if still provisory output then status remains the same
                  lNewEleNumStatus      := lEleNumStatus;
                  lEleNumStatusFctStat  := STM_I_LIB_CONSTANT.gcEleNumStatusActive;
                elsif lOldEleNumStatus is not null then
                  if iExtourne = 1 then
                    lNewEleNumStatus  := STM_I_LIB_CONSTANT.gcEleNumStatusActive;
                    lEleNumStatusFctStat := Null;
                  else
                    lNewEleNumStatus  := lOldEleNumStatus;
                  end if;
                end if;
                STM_PRC_ELEMENT_NUMBER.UpdateElementNumber(iElementNumberID   => lElementNumberId
                                                         , iStatus            => lNewEleNumStatus
                                                         , iOldStatus         => lEleNumStatusFctStat
                                                         , iRetestDate        => lRetestDate
                                                          );
              end if;
            -- Mouvement de sortie
            elsif iMovementSort = 'SOR' then
              if iTransfert = 0 then
                STM_PRC_ELEMENT_NUMBER.UpdateElementNumber(iElementNumberID => lElementNumberId, iStatus => lNewEleNumStatus, iOldStatus => 'CLEAR');
              end if;
            end if;
          -- Caractérisation non gérée en stock
          elsif iStockManagement = 0 then
            -- Mouvement de sortie
            if iMovementSort = 'ENT' then
              if lUniqueness = 1 then
                -- on ne crée le numéro que dans le cas d'un retour
                -- si le numéro n'existait pas encore dans la liste
                if     lElementNumberId is null
                   and iUpdateMode = 'MR' then
                  -- Insertion d'un nouveau détail de caractérisation
                  STM_PRC_ELEMENT_NUMBER.createDetail(oElementNumberId    => lElementNumberId
                                                    , iGoodId             => iGoodId
                                                    , iStatus             => lNewEleNumStatus
                                                    , iOldStatus          => STM_I_LIB_CONSTANT.gcEleNumStatusActive
                                                    , iElementType        => lElementType
                                                    , iValue              => iSemValue
                                                    , iRetestDate         => lRetestDate
                                                    , ioQualityStatusId   => ioQualityStatusId
                                                     );
                else
                  STM_PRC_ELEMENT_NUMBER.UpdateElementNumber(iElementNumberID   => lElementNumberId
                                                           , iStatus            => lNewEleNumStatus
                                                           , iOldStatus         => lEleNumStatusFctStat
                                                           , iRetestDate        => lRetestDate
                                                            );
                end if;
              end if;
            elsif iMovementSort = 'SOR' then
              if iTransfert = 1 then
                STM_PRC_ELEMENT_NUMBER.UpdateElementNumber(iElementNumberID   => lElementNumberId
                                                         , iStatus            => lNewEleNumStatus
                                                         , iOldStatus         => lEleNumStatusFctStat
                                                          );
              end if;
            end if;
          end if;
        elsif iVerifyChar = 0 then
          -- Caractérisation gérée en stock
          if iStockManagement = 1 then
            -- Mouvement d'entrée
            if iMovementSort = 'ENT' then
              if lElementNumberId is null then
                -- Insertion d'un nouveau détail de caractérisation
                STM_PRC_ELEMENT_NUMBER.createDetail(oElementNumberId    => lElementNumberId
                                                  , iGoodId             => iGoodId
                                                  , iStatus             => lNewEleNumStatus
                                                  , iOldStatus          => STM_I_LIB_CONSTANT.gcEleNumStatusActive
                                                  , iElementType        => lElementType
                                                  , iValue              => iSemValue
                                                  , iRetestDate         => lRetestDate
                                                  , ioQualityStatusId   => ioQualityStatusId
                                                   );
              else
                -- if manual input
                if iMovementCode = '006' then
                  -- if still provisory output then status remains the same
                  lNewEleNumStatus      := lEleNumStatus;
                  lEleNumStatusFctStat  := STM_I_LIB_CONSTANT.gcEleNumStatusActive;
                elsif lOldEleNumStatus is not null then
                  if iExtourne = 1 then
                    lNewEleNumStatus  := STM_I_LIB_CONSTANT.gcEleNumStatusActive;
                    lEleNumStatusFctStat := Null;
                  else
                    lNewEleNumStatus  := lOldEleNumStatus;
                  end if;
                end if;
                STM_PRC_ELEMENT_NUMBER.UpdateElementNumber(iElementNumberID   => lElementNumberId
                                                         , iStatus            => lNewEleNumStatus
                                                         , iOldStatus         => lEleNumStatusFctStat
                                                         , iRetestDate        => lRetestDate
                                                          );
              end if;
            -- Mouvement de sortie
            elsif iMovementSort = 'SOR' then
              if lElementNumberId is null then
                -- Insertion d'un nouveau détail de caractérisation
                STM_PRC_ELEMENT_NUMBER.createDetail(oElementNumberId    => lElementNumberId
                                                  , iGoodId             => iGoodId
                                                  , iStatus             => lNewEleNumStatus
                                                  , iOldStatus          => STM_I_LIB_CONSTANT.gcEleNumStatusActive
                                                  , iElementType        => lElementType
                                                  , iValue              => iSemValue
                                                  , iRetestDate         => lRetestDate
                                                  , ioQualityStatusId   => ioQualityStatusId
                                                   );
              else
                if iTransfert = 0 then
                  STM_PRC_ELEMENT_NUMBER.UpdateElementNumber(iElementNumberID => lElementNumberId, iStatus => lNewEleNumStatus, iOldStatus => 'CLEAR');
                else
                  STM_PRC_ELEMENT_NUMBER.UpdateElementNumber(iElementNumberID   => lElementNumberId
                                                           , iStatus            => lNewEleNumStatus
                                                           , iOldStatus         => lEleNumStatusFctStat
                                                            );
                end if;
              end if;
            end if;
          elsif iStockManagement = 0 then
            STM_PRC_ELEMENT_NUMBER.UpdateElementNumber(iElementNumberID => lElementNumberId, iStatus => lNewEleNumStatus);
          end if;
        end if;
      end if;

      -- assignation du paramètre de retour
      oElementNumber  := lElementNumberId;
    else
      -- cas ou la valeur est N/A
      oElementNumber  := null;
      oAlreadyExist   := 0;
    end if;
  end ManageElementNumber;

  /**
  *  fonction qui renvoie le code de controle selon analyse
  */
  function GetControlMode(iGoodId in number, iCharacType in varchar2, iSemValue in varchar2)
    return number
  is
    lResult number(1);
  begin
    -- Gestion de pièces
    if iCharacType = STM_I_LIB_CONSTANT.gcCharacTypePiece then
      if STM_I_LIB_CONSTANT.gcCfgPieceSglNumberingComp then
        select sign(nvl(max(STM_ELEMENT_NUMBER_ID), 0) )
          into lResult
          from stm_element_number
         where sem_value = iSemValue
           and c_ele_num_status not in(STM_I_LIB_CONSTANT.gcEleNumStatusReturned, STM_I_LIB_CONSTANT.gcEleNumStatusReserved)
           and c_element_type = STM_I_LIB_CONSTANT.gcElementTypePiece;
      else
        select sign(nvl(max(STM_ELEMENT_NUMBER_ID), 0) )
          into lResult
          from stm_element_number
         where gco_good_id = iGoodId
           and c_element_type = STM_I_LIB_CONSTANT.gcElementTypePiece
           and c_ele_num_status not in(STM_I_LIB_CONSTANT.gcEleNumStatusReturned, STM_I_LIB_CONSTANT.gcEleNumStatusReserved)
           and sem_value = iSemValue;
      end if;
    -- gestion de lots
    elsif iCharacType = STM_I_LIB_CONSTANT.gcCharacTypeSet then
      if STM_I_LIB_CONSTANT.gcCfgSetSglNumberingGood then
        select sign(nvl(max(STM_ELEMENT_NUMBER_ID), 0) )
          into lResult
          from stm_element_number
         where gco_good_id = iGoodId
           and sem_value = iSemValue
           and c_ele_num_status not in(STM_I_LIB_CONSTANT.gcEleNumStatusReturned)
           and c_element_type = STM_I_LIB_CONSTANT.gcElementTypeSet;
      else
        if STM_I_LIB_CONSTANT.gcCfgSetSglNumberingComp then
          select sign(nvl(max(STM_ELEMENT_NUMBER_ID), 0) )
            into lResult
            from stm_element_number
           where sem_value = iSemValue
             and c_ele_num_status not in(STM_I_LIB_CONSTANT.gcEleNumStatusReturned)
             and c_element_type = STM_I_LIB_CONSTANT.gcElementTypeSet;
        else
          select 2 * sign(nvl(max(STM_ELEMENT_NUMBER_ID), 0) )
            into lResult
            from stm_element_number
           where gco_good_id = iGoodId
             and sem_value = iSemValue
             and c_ele_num_status not in(STM_I_LIB_CONSTANT.gcEleNumStatusReturned)
             and c_element_type = STM_I_LIB_CONSTANT.gcElementTypeSet;
        end if;
      end if;
    -- gestion de version
    elsif iCharacType = STM_I_LIB_CONSTANT.gcCharacTypeVersion then
      if STM_I_LIB_CONSTANT.gcCfgVersionSglNumberingGood then
        select sign(nvl(max(STM_ELEMENT_NUMBER_ID), 0) )
          into lResult
          from stm_element_number
         where gco_good_id = iGoodId
           and sem_value = iSemValue
           and c_ele_num_status not in(STM_I_LIB_CONSTANT.gcEleNumStatusReturned)
           and c_element_type = STM_I_LIB_CONSTANT.gcElementTypeVersion;
      else
        if STM_I_LIB_CONSTANT.gcCfgVersionSglNumberingComp then
          select sign(nvl(max(STM_ELEMENT_NUMBER_ID), 0) )
            into lResult
            from stm_element_number
           where sem_value = iSemValue
             and c_ele_num_status not in(STM_I_LIB_CONSTANT.gcEleNumStatusReturned)
             and c_element_type = STM_I_LIB_CONSTANT.gcElementTypeVersion;
        else
          select 2 * sign(nvl(max(STM_ELEMENT_NUMBER_ID), 0) )
            into lResult
            from stm_element_number
           where gco_good_id = iGoodId
             and sem_value = iSemValue
             and c_ele_num_status not in(STM_I_LIB_CONSTANT.gcEleNumStatusReturned)
             and c_element_type = STM_I_LIB_CONSTANT.gcElementTypeVersion;
        end if;
      end if;
    end if;

    -- valeur de retour
    return lResult;
  end GetControlMode;

  /**
  * Description
  *   Recherche l'origine de la réservation pour un élément réservé (pièce, lot ou version)
  */
  procedure findElementReservation(iCharId number, iCharValue string, ioTableName out string, ioReservingId out number)
  is
    lNbChar number(1);
  begin
    -- recherche du nombre de caractérisations du bien afin de limiter le nombre de commandes de recherche
    select count(*)
      into lNbChar
      from GCO_CHARACTERIZATION
     where GCO_GOOD_ID = (select GCO_GOOD_ID
                            from GCO_CHARACTERIZATION
                           where GCO_CHARACTERIZATION_ID = iCharId);

--*********************************************
-- 1ère recherche dans les documents logistique
--*********************************************
-- caractérisation 1
    begin
      select DOC_POSITION_DETAIL_ID
        into ioReservingId
        from DOC_POSITION_DETAIL
       where GCO_CHARACTERIZATION_ID = iCharId
         and PDE_CHARACTERIZATION_VALUE_1 = iCharValue
         and PDE_GENERATE_MOVEMENT = 0;

      ioTableName  := 'DOC_POSITION_DETAIL';
      return;
    exception
      when no_data_found then
        null;
      when too_many_rows then
        select max(DOC_POSITION_DETAIL_ID)
          into ioReservingId
          from DOC_POSITION_DETAIL
         where GCO_CHARACTERIZATION_ID = iCharId
           and PDE_CHARACTERIZATION_VALUE_1 = iCharValue
           and PDE_GENERATE_MOVEMENT = 0;

        ioTableName  := 'DOC_POSITION_DETAIL';
        return;
    end;

    -- caractérisation 2
    if lNbChar >= 2 then
      begin
        select DOC_POSITION_DETAIL_ID
          into ioReservingId
          from DOC_POSITION_DETAIL
         where GCO_GCO_CHARACTERIZATION_ID = iCharId
           and PDE_CHARACTERIZATION_VALUE_2 = iCharValue
           and PDE_GENERATE_MOVEMENT = 0;

        ioTableName  := 'DOC_POSITION_DETAIL';
        return;
      exception
        when no_data_found then
          null;
        when too_many_rows then
          select max(DOC_POSITION_DETAIL_ID)
            into ioReservingId
            from DOC_POSITION_DETAIL
           where GCO_GCO_CHARACTERIZATION_ID = iCharId
             and PDE_CHARACTERIZATION_VALUE_2 = iCharValue
             and PDE_GENERATE_MOVEMENT = 0;

          ioTableName  := 'DOC_POSITION_DETAIL';
          return;
      end;
    end if;

    -- caractérisation 3
    if lNbChar >= 3 then
      begin
        select DOC_POSITION_DETAIL_ID
          into ioReservingId
          from DOC_POSITION_DETAIL
         where GCO2_GCO_CHARACTERIZATION_ID = iCharId
           and PDE_CHARACTERIZATION_VALUE_3 = iCharValue
           and PDE_GENERATE_MOVEMENT = 0;

        ioTableName  := 'DOC_POSITION_DETAIL';
        return;
      exception
        when no_data_found then
          null;
        when too_many_rows then
          select max(DOC_POSITION_DETAIL_ID)
            into ioReservingId
            from DOC_POSITION_DETAIL
           where GCO2_GCO_CHARACTERIZATION_ID = iCharId
             and PDE_CHARACTERIZATION_VALUE_3 = iCharValue
             and PDE_GENERATE_MOVEMENT = 0;

          ioTableName  := 'DOC_POSITION_DETAIL';
          return;
      end;
    end if;

    -- caractérisation 4
    if lNbChar >= 4 then
      begin
        select DOC_POSITION_DETAIL_ID
          into ioReservingId
          from DOC_POSITION_DETAIL
         where GCO3_GCO_CHARACTERIZATION_ID = iCharId
           and PDE_CHARACTERIZATION_VALUE_4 = iCharValue
           and PDE_GENERATE_MOVEMENT = 0;

        ioTableName  := 'DOC_POSITION_DETAIL';
        return;
      exception
        when no_data_found then
          null;
        when too_many_rows then
          select max(DOC_POSITION_DETAIL_ID)
            into ioReservingId
            from DOC_POSITION_DETAIL
           where GCO3_GCO_CHARACTERIZATION_ID = iCharId
             and PDE_CHARACTERIZATION_VALUE_4 = iCharValue
             and PDE_GENERATE_MOVEMENT = 0;

          ioTableName  := 'DOC_POSITION_DETAIL';
          return;
      end;
    end if;

    -- caractérisation 5
    if lNbChar >= 5 then
      begin
        select DOC_POSITION_DETAIL_ID
          into ioReservingId
          from DOC_POSITION_DETAIL
         where GCO4_GCO_CHARACTERIZATION_ID = iCharId
           and PDE_CHARACTERIZATION_VALUE_5 = iCharValue
           and PDE_GENERATE_MOVEMENT = 0;

        ioTableName  := 'DOC_POSITION_DETAIL';
        return;
      exception
        when no_data_found then
          null;
        when too_many_rows then
          select max(DOC_POSITION_DETAIL_ID)
            into ioReservingId
            from DOC_POSITION_DETAIL
           where GCO4_GCO_CHARACTERIZATION_ID = iCharId
             and PDE_CHARACTERIZATION_VALUE_5 = iCharValue
             and PDE_GENERATE_MOVEMENT = 0;

          ioTableName  := 'DOC_POSITION_DETAIL';
          return;
      end;
    end if;

--***********************************************
-- 2ème recherche dans les ordres de fabrication
--***********************************************
-- caractérisation 1
    begin
      select FAL_LOT_DETAIL_ID
        into ioReservingId
        from FAL_LOT_DETAIL
       where GCO_CHARACTERIZATION_ID = iCharId
         and FAD_CHARACTERIZATION_VALUE_1 = iCharValue
         and FAD_BALANCE_QTY != 0;

      ioTableName  := 'FAL_LOT_DETAIL';
      return;
    exception
      when no_data_found then
        null;
      when too_many_rows then
        select max(FAL_LOT_DETAIL_ID)
          into ioReservingId
          from FAL_LOT_DETAIL
         where GCO_CHARACTERIZATION_ID = iCharId
           and FAD_CHARACTERIZATION_VALUE_1 = iCharValue
           and FAD_BALANCE_QTY != 0;

        ioTableName  := 'FAL_LOT_DETAIL';
        return;
    end;

    -- caractérisation 2
    if lNbChar >= 2 then
      begin
        select FAL_LOT_DETAIL_ID
          into ioReservingId
          from FAL_LOT_DETAIL
         where GCO_GCO_CHARACTERIZATION_ID = iCharId
           and FAD_CHARACTERIZATION_VALUE_2 = iCharValue
           and FAD_BALANCE_QTY != 0;

        ioTableName  := 'FAL_LOT_DETAIL';
        return;
      exception
        when no_data_found then
          null;
        when too_many_rows then
          select max(FAL_LOT_DETAIL_ID)
            into ioReservingId
            from FAL_LOT_DETAIL
           where GCO_GCO_CHARACTERIZATION_ID = iCharId
             and FAD_CHARACTERIZATION_VALUE_1 = iCharValue
             and FAD_BALANCE_QTY != 0;

          ioTableName  := 'FAL_LOT_DETAIL';
          return;
      end;
    end if;

    -- caractérisation 3
    if lNbChar >= 3 then
      begin
        select FAL_LOT_DETAIL_ID
          into ioReservingId
          from FAL_LOT_DETAIL
         where GCO2_GCO_CHARACTERIZATION_ID = iCharId
           and FAD_CHARACTERIZATION_VALUE_3 = iCharValue
           and FAD_BALANCE_QTY != 0;

        ioTableName  := 'FAL_LOT_DETAIL';
        return;
      exception
        when no_data_found then
          null;
        when too_many_rows then
          select max(FAL_LOT_DETAIL_ID)
            into ioReservingId
            from FAL_LOT_DETAIL
           where GCO2_GCO_CHARACTERIZATION_ID = iCharId
             and FAD_CHARACTERIZATION_VALUE_3 = iCharValue
             and FAD_BALANCE_QTY != 0;

          ioTableName  := 'FAL_LOT_DETAIL';
          return;
      end;
    end if;

    -- caractérisation 4
    if lNbChar >= 4 then
      begin
        select FAL_LOT_DETAIL_ID
          into ioReservingId
          from FAL_LOT_DETAIL
         where GCO3_GCO_CHARACTERIZATION_ID = iCharId
           and FAD_CHARACTERIZATION_VALUE_4 = iCharValue
           and FAD_BALANCE_QTY != 0;

        ioTableName  := 'FAL_LOT_DETAIL';
        return;
      exception
        when no_data_found then
          null;
        when too_many_rows then
          select max(FAL_LOT_DETAIL_ID)
            into ioReservingId
            from FAL_LOT_DETAIL
           where GCO3_GCO_CHARACTERIZATION_ID = iCharId
             and FAD_CHARACTERIZATION_VALUE_4 = iCharValue
             and FAD_BALANCE_QTY != 0;

          ioTableName  := 'FAL_LOT_DETAIL';
          return;
      end;
    end if;

    -- caractérisation 5
    if lNbChar >= 5 then
      begin
        select FAL_LOT_DETAIL_ID
          into ioReservingId
          from FAL_LOT_DETAIL
         where GCO4_GCO_CHARACTERIZATION_ID = iCharId
           and FAD_CHARACTERIZATION_VALUE_5 = iCharValue
           and FAD_BALANCE_QTY != 0;

        ioTableName  := 'FAL_LOT_DETAIL';
        return;
      exception
        when no_data_found then
          null;
        when too_many_rows then
          select max(FAL_LOT_DETAIL_ID)
            into ioReservingId
            from FAL_LOT_DETAIL
           where GCO4_GCO_CHARACTERIZATION_ID = iCharId
             and FAD_CHARACTERIZATION_VALUE_5 = iCharValue
             and FAD_BALANCE_QTY != 0;

          ioTableName  := 'FAL_LOT_DETAIL';
          return;
      end;
    end if;

--***********************************************
-- 3ème recherche dans le SAV (composants)
--***********************************************
-- caractérisation 1
    begin
      select ASA_RECORD_COMP_ID
        into ioReservingId
        from ASA_RECORD_COMP ARC
           , ASA_RECORD are
       where ARC.GCO_CHAR1_ID = iCharId
         and ARC.ARC_CHAR1_VALUE = iCharValue
         and are.ASA_RECORD_ID = ARC.ASA_RECORD_ID
         and are.C_ASA_REP_STATUS not in('10', '11');

      ioTableName  := 'ASA_RECORD_COMP';
      return;
    exception
      when no_data_found then
        null;
      when too_many_rows then
        select max(ASA_RECORD_COMP_ID)
          into ioReservingId
          from ASA_RECORD_COMP ARC
             , ASA_RECORD are
         where ARC.GCO_CHAR1_ID = iCharId
           and ARC.ARC_CHAR1_VALUE = iCharValue
           and are.ASA_RECORD_ID = ARC.ASA_RECORD_ID
           and are.C_ASA_REP_STATUS not in('10', '11');

        ioTableName  := 'ASA_RECORD_COMP';
        return;
    end;

    -- caractérisation 2
    if lNbChar >= 2 then
      begin
        select ASA_RECORD_COMP_ID
          into ioReservingId
          from ASA_RECORD_COMP ARC
             , ASA_RECORD are
         where ARC.GCO_CHAR2_ID = iCharId
           and ARC.ARC_CHAR2_VALUE = iCharValue
           and are.ASA_RECORD_ID = ARC.ASA_RECORD_ID
           and are.C_ASA_REP_STATUS not in('10', '11');

        ioTableName  := 'ASA_RECORD_COMP';
        return;
      exception
        when no_data_found then
          null;
        when too_many_rows then
          select max(ASA_RECORD_COMP_ID)
            into ioReservingId
            from ASA_RECORD_COMP ARC
               , ASA_RECORD are
           where ARC.GCO_CHAR2_ID = iCharId
             and ARC.ARC_CHAR2_VALUE = iCharValue
             and are.ASA_RECORD_ID = ARC.ASA_RECORD_ID
             and are.C_ASA_REP_STATUS not in('10', '11');

          ioTableName  := 'ASA_RECORD_COMP';
          return;
      end;
    end if;

    -- caractérisation 3
    if lNbChar >= 3 then
      begin
        select ASA_RECORD_COMP_ID
          into ioReservingId
          from ASA_RECORD_COMP ARC
             , ASA_RECORD are
         where ARC.GCO_CHAR3_ID = iCharId
           and ARC.ARC_CHAR3_VALUE = iCharValue
           and are.ASA_RECORD_ID = ARC.ASA_RECORD_ID
           and are.C_ASA_REP_STATUS not in('10', '11');

        ioTableName  := 'ASA_RECORD_COMP';
        return;
      exception
        when no_data_found then
          null;
        when too_many_rows then
          select max(ASA_RECORD_COMP_ID)
            into ioReservingId
            from ASA_RECORD_COMP ARC
               , ASA_RECORD are
           where ARC.GCO_CHAR3_ID = iCharId
             and ARC.ARC_CHAR3_VALUE = iCharValue
             and are.ASA_RECORD_ID = ARC.ASA_RECORD_ID
             and are.C_ASA_REP_STATUS not in('10', '11');

          ioTableName  := 'ASA_RECORD_COMP';
          return;
      end;
    end if;

    -- caractérisation 4
    if lNbChar >= 4 then
      begin
        select ASA_RECORD_COMP_ID
          into ioReservingId
          from ASA_RECORD_COMP ARC
             , ASA_RECORD are
         where ARC.GCO_CHAR4_ID = iCharId
           and ARC.ARC_CHAR4_VALUE = iCharValue
           and are.ASA_RECORD_ID = ARC.ASA_RECORD_ID
           and are.C_ASA_REP_STATUS not in('10', '11');

        ioTableName  := 'ASA_RECORD_COMP';
        return;
      exception
        when no_data_found then
          null;
        when too_many_rows then
          select max(ASA_RECORD_COMP_ID)
            into ioReservingId
            from ASA_RECORD_COMP ARC
               , ASA_RECORD are
           where ARC.GCO_CHAR4_ID = iCharId
             and ARC.ARC_CHAR4_VALUE = iCharValue
             and are.ASA_RECORD_ID = ARC.ASA_RECORD_ID
             and are.C_ASA_REP_STATUS not in('10', '11');

          ioTableName  := 'ASA_RECORD_COMP';
          return;
      end;
    end if;

    -- caractérisation 5
    if lNbChar >= 5 then
      begin
        select ASA_RECORD_COMP_ID
          into ioReservingId
          from ASA_RECORD_COMP ARC
             , ASA_RECORD are
         where ARC.GCO_CHAR5_ID = iCharId
           and ARC.ARC_CHAR5_VALUE = iCharValue
           and are.ASA_RECORD_ID = ARC.ASA_RECORD_ID
           and are.C_ASA_REP_STATUS not in('10', '11');

        ioTableName  := 'ASA_RECORD_COMP';
        return;
      exception
        when no_data_found then
          null;
        when too_many_rows then
          select max(ASA_RECORD_COMP_ID)
            into ioReservingId
            from ASA_RECORD_COMP ARC
               , ASA_RECORD are
           where ARC.GCO_CHAR5_ID = iCharId
             and ARC.ARC_CHAR5_VALUE = iCharValue
             and are.ASA_RECORD_ID = ARC.ASA_RECORD_ID
             and are.C_ASA_REP_STATUS not in('10', '11');

          ioTableName  := 'ASA_RECORD_COMP';
          return;
      end;
    end if;
  end findElementReservation;

  procedure DeleteNullPosition(iStockPositionId in STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type)
  is
  begin
    if STM_I_LIB_CONSTANT.gcCfgIndependantAlternative then
      delete from stm_stock_position
            where stm_stock_position_id = iStockPositionId
              and spo_stock_quantity = 0
              and spo_assign_quantity = 0
              and spo_provisory_output = 0
              and spo_provisory_input = 0
              and spo_available_quantity = 0
              and spo_alternativ_quantity_1 = 0
              and spo_alternativ_quantity_2 = 0
              and spo_alternativ_quantity_3 = 0;
    else
      delete from stm_stock_position
            where stm_stock_position_id = iStockPositionId
              and spo_stock_quantity = 0
              and spo_assign_quantity = 0
              and spo_provisory_output = 0
              and spo_provisory_input = 0
              and spo_available_quantity = 0;
    end if;
  end DeleteNullPosition;

  /**
  * procedure DeleteAllNullPositions
  * Description
  *    Suppression de toutes les positions de stock dont les compteurs sont à 0
  * @created JCH 24.09.2007
  * @lastUpdate
  * @public
  */
  procedure DeleteAllNullPositions
  is
    cursor crNullStockPositions(iIndepAlternative pls_integer)
    is
      select   STM_STOCK_POSITION_ID
          from STM_STOCK_POSITION
         where SPO_STOCK_QUANTITY = 0
           and SPO_ASSIGN_QUANTITY = 0
           and SPO_PROVISORY_OUTPUT = 0
           and SPO_PROVISORY_INPUT = 0
           and SPO_AVAILABLE_QUANTITY = 0
           and (   iIndepAlternative = 0
                or (    SPO_ALTERNATIV_QUANTITY_1 = 0
                    and SPO_ALTERNATIV_QUANTITY_2 = 0
                    and SPO_ALTERNATIV_QUANTITY_3 = 0) )
      order by GCO_GOOD_ID
             , SPO_CHARACTERIZATION_VALUE_1
             , SPO_CHARACTERIZATION_VALUE_2
             , SPO_CHARACTERIZATION_VALUE_3
             , SPO_CHARACTERIZATION_VALUE_4
             , SPO_CHARACTERIZATION_VALUE_5
             , STM_STOCK_ID
             , STM_LOCATION_ID;

    lIndepAlternative pls_integer;
  begin
    /* Suppression de toutes les positions de stock dont les compteurs sont à 0
       en tenant compte de la config STM_INDEPENDENT_ALTERNATIVE */
    if STM_I_LIB_CONSTANT.gcCfgIndependantAlternative then
      lIndepAlternative  := 1;
    else
      lIndepAlternative  := 0;
    end if;

    for tplNullStockPosition in crNullStockPositions(lIndepAlternative) loop
      DeleteNullPosition(tplNullStockPosition.STM_STOCK_POSITION_ID);
    end loop;
  end DeleteAllNullPositions;

  /**
  * procedure CheckUniqueChar
  * Description
  *   Check unity of the characterization
  * @created fp 03.08.2010
  * @lastUpdate
  * @public
  * @param iotMovementRecord : tuple du mouvement
  */
  function CheckUniqueChar(iotMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
    return boolean
  is
    lMovementSort STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type;
    lMovementType STM_MOVEMENT_KIND.C_MOVEMENT_TYPE%type;
    lTotQty       STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
    lResult       boolean;
  begin
    if     iotMovementRecord.SMO_MOVEMENT_QUANTITY > 0
       and GCO_LIB_CHARACTERIZATION.IsPieceChar(iotMovementRecord.GCO_GOOD_ID) = 1 then
      -- if movement is an input
      select C_MOVEMENT_SORT
           , C_MOVEMENT_TYPE
        into lMovementSort
           , lMovementType
        from STM_MOVEMENT_KIND
       where STM_MOVEMENT_KIND_ID = iotMovementRecord.STM_MOVEMENT_KIND_ID;

      if     (    (    lMovementSort = 'ENT'
                   and iotMovementRecord.SMO_EXTOURNE_MVT = 0)
              or (    lMovementSort = 'SOR'
                  and iotMovementRecord.SMO_EXTOURNE_MVT = 1) )
         and lMovementType <> 'EXE' then
        -- Check quantity
        if STM_I_LIB_CONSTANT.gcCfgPieceSglNumberingComp then
          select nvl(sum(SPO_STOCK_QUANTITY), 0)
            into lTotQty
            from STM_STOCK_POSITION
           where SPO_PIECE = iotMovementRecord.SMO_PIECE;
        else
          select nvl(sum(SPO_STOCK_QUANTITY), 0)
            into lTotQty
            from STM_STOCK_POSITION
           where GCO_GOOD_ID = iotMovementRecord.GCO_GOOD_ID
             and SPO_PIECE = iotMovementRecord.SMO_PIECE;
        end if;

        lResult  :=(lTotQty = 0);
        return lResult;
      else
        return true;
      end if;
    else
      return true;
    end if;
  end CheckUniqueChar;

  /**
   * Description
   *    procedure de contrôle de la quantité disponible. Porvoque une exception en cas d'erreur
   */
  procedure checkAssignedQuantity(
    iGoodId         STM_STOCK_POSITION.GCO_GOOD_ID%type
  , iStockId        STM_STOCK_POSITION.STM_STOCK_ID%type
  , iStockQty       STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type
  , iAssignQuantity STM_STOCK_POSITION.SPO_ASSIGN_QUANTITY%type
  , iProvisoryInput STM_STOCK_POSITION.SPO_PROVISORY_INPUT%type
  )
  is
  begin
    if     iStockQty + iProvisoryInput < iAssignQuantity
       and DOC_I_LIB_ALLOY.StockDeficitControl(iStockId, iGoodId) > 0 then
      raise_application_error(-20000, PCS.PC_FUNCTIONS.TranslateWord('PCS - Problème d''intégrité avec la quantité disponible en stock') );
    end if;
  end checkAssignedQuantity;

  /**
  * Description
  *    procedure de contrôle de la quantité disponible. Provoque une exception en cas d'erreur
  */
  procedure checkAssignedQuantity(iStockPositionId STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type)
  is
  begin
    for tplStockPosition in (select GCO_GOOD_ID
                                  , SPO.STM_STOCK_ID
                                  , SPO_STOCK_QUANTITY
                                  , SPO_ASSIGN_QUANTITY
                                  , SPO_PROVISORY_INPUT
                               from STM_STOCK_POSITION SPO
                                  , STM_STOCK STO
                              where STM_STOCK_POSITION_ID = iStockPositionId
                                and STO.STM_STOCK_ID = SPO.STM_STOCK_ID
                                and STO.C_ACCESS_METHOD <> 'PRIVATE') loop
      STM_PRC_STOCK_POSITION.checkAssignedQuantity(tplStockPosition.GCO_GOOD_ID
                                                 , tplStockPosition.STM_STOCK_ID
                                                 , tplStockPosition.SPO_STOCK_QUANTITY
                                                 , tplStockPosition.SPO_ASSIGN_QUANTITY
                                                 , tplStockPosition.SPO_PROVISORY_INPUT
                                                  );
    end loop;
  end checkAssignedQuantity;

  /**
  * Description : Procédure de construction de la requête de sélection des
  *               positions de stock sur lesquelles générer les liens vers les composants
  */
  procedure BuildSTM_STOCK_POSITIONQuery(
    oSQLQuery           out    varchar2
  , iLocationId         in     STM_LOCATION.STM_LOCATION_ID%type
  , iGoodId             in     GCO_GOOD.GCO_GOOD_ID%type
  , iForceLocation      in     pls_integer
  , iLotId              in     FAL_LOT.FAL_LOT_ID%type
  , iAutoChar           in     DOC_GAUGE_STRUCTURED.GAS_AUTO_CHARACTERIZATION%type default 1
  , iThirdId            in     PAC_THIRD.PAC_THIRD_ID%type default null
  , iDateRef            in     date default sysdate
  , iInStrLocationList  in     varchar2 default null
  , iPriorityToAttribs  in     pls_integer default 1
  , iOnlyOrderBy        in     pls_integer default 0
  , iPriorityLocationId in     STM_LOCATION.STM_LOCATION_ID%type default null
  )
  is
    lSTM_STOCK_ID             STM_STOCK.STM_STOCK_ID%type;
    lStrSQLQuerySelect        varchar2(4000);
    lStrSQLQueryFrom          varchar2(4000);
    lStrSQLQueryWhere         varchar2(4000);
    lStrSQLQueryOrderby       varchar2(4000);
    lStrSQLQuerySearchOrderby varchar2(4000);
    lPDT_STOCK_ALLOC_BATCH    GCO_PRODUCT.PDT_STOCK_ALLOC_BATCH%type;
    lPDTHasPeremptionDate     pls_integer;
    lC_CHRONOLOGY_TYPE        GCO_CHARACTERIZATION.C_CHRONOLOGY_TYPE%type;
    lIS_FULL_TRACABILITY      pls_integer;
    lNbChar                   pls_integer;
    lNbCharStock              pls_integer;
    lStrThirdId               varchar2(12)                                  := case nvl(iThirdId, 0)
      when 0 then 'NULL'
      else to_char(iThirdId)
    end;
    lStrDateRef               varchar2(100)                                 := 'to_date(''' || to_char(trunc(iDateRef), 'DD.MM.YYYY') || ''',''DD.MM.YYYY'')';
    lStrChronoValue           varchar2(250);
    lFound                    boolean                                       := true;
    lShowQualityStatus        pls_integer;
    lShowRetestDate           pls_integer;
  begin
    begin
      select PDT.PDT_STOCK_ALLOC_BATCH
           , GCO_I_LIB_CHARACTERIZATION.IsTimeLimitManagement(GCO_GOOD_ID)
           , FAL_TOOLS.PrcIsFullTracability(GCO_GOOD_ID)
           , GCO_I_LIB_CHARACTERIZATION.HasQualityStatusManagement(GCO_GOOD_ID)
           , GCO_I_LIB_CHARACTERIZATION.IsRetestManagement(GCO_GOOD_ID)
           , (select count(*)
                from GCO_CHARACTERIZATION
               where GCO_GOOD_ID = PDT.GCO_GOOD_ID) NB_CHARACT
           , (select count(*)
                from GCO_CHARACTERIZATION
               where GCO_GOOD_ID = PDT.GCO_GOOD_ID
                 and CHA_STOCK_MANAGEMENT = 1) NB_CHARACT_STOCK
           , (select C_CHRONOLOGY_TYPE
                from GCO_CHARACTERIZATION
               where GCO_GOOD_ID = PDT.GCO_GOOD_ID
                 and C_CHARACT_TYPE = '5') C_CHRONOLOGY_TYPE
        into lPDT_STOCK_ALLOC_BATCH
           , lPDTHasPeremptionDate
           , lIS_FULL_TRACABILITY
           , lShowQualityStatus
           , lShowRetestDate
           , lNbChar
           , lNbCharStock
           , lC_CHRONOLOGY_TYPE
        from GCO_PRODUCT PDT
       where PDT.PDT_STOCK_MANAGEMENT = 1
         and PDT.GCO_GOOD_ID = iGoodId;
    exception
      when no_data_found then
        lFound  := false;
    end;

    if iOnlyOrderBy = 0 then
      -- Initialisation de la valeur de chronologie en tenant compte directement de la marge (sert à tester la péremption et à initialiser l'order by)
      lStrChronoValue     :=
                  ' trunc(GCO_I_LIB_CHARACTERIZATION.ChronoFormatToDate(SPO.SPO_CHRONOLOGICAL, GCO_I_LIB_CHARACTERIZATION.GetChronoCharID(SPO.GCO_GOOD_ID) ) )';
      lStrChronoValue     := lStrChronoValue || ' - nvl(GCO_CHARACTERIZATION_FUNCTIONS.getLapsingMarge(SPO.GCO_GOOD_ID,' || lStrThirdId || '), 0)';
      --
      oSQLQuery           := '';
      lStrSQLQuerySelect  :=
        ' SELECT DISTINCT ' ||
        '         SPO.SPO_AVAILABLE_QUANTITY ' ||
        '       , SPO.STM_STOCK_POSITION_ID ' ||
        '       , SPO.SPO_CHARACTERIZATION_VALUE_1 ' ||
        '       , SPO.SPO_CHARACTERIZATION_VALUE_2 ' ||
        '       , SPO.SPO_CHARACTERIZATION_VALUE_3 ' ||
        '       , SPO.SPO_CHARACTERIZATION_VALUE_4 ' ||
        '       , SPO.SPO_CHARACTERIZATION_VALUE_5 ' ||
        '       , SPO.GCO_CHARACTERIZATION_ID ' ||
        '       , SPO.GCO_GCO_CHARACTERIZATION_ID ' ||
        '       , SPO.GCO2_GCO_CHARACTERIZATION_ID ' ||
        '       , SPO.GCO3_GCO_CHARACTERIZATION_ID ' ||
        '       , SPO.GCO4_GCO_CHARACTERIZATION_ID ' ||
        '       , SPO.SPO_VERSION ' ||
        '       , SPO.SPO_SET ' ||
        '       , SPO.SPO_PIECE ' ||
        '       , SPO.SPO_CHRONOLOGICAL ' ||
        '       , SPO.SPO_STD_CHAR_1 ' ||
        '       , SPO.SPO_STD_CHAR_2 ' ||
        '       , SPO.SPO_STD_CHAR_3 ' ||
        '       , SPO.SPO_STD_CHAR_4 ' ||
        '       , SPO.SPO_STD_CHAR_5 ' ||
        '       , SPO.STM_LOCATION_ID ' ||
        '       , decode(SPO.STM_LOCATION_ID, ' ||
        to_char(nvl(nvl(iPriorityLocationId, iLocationId), 0) ) ||
        ', 0, 1) LOCATION_ORDER_BY ' ||

        /* Ordre de la péremption (test de lStrChronoValue - lStrDateRef)
           - 0 si la valeur de chrono est supérieure à la date de référence (non périmée)
           - 1 si les dates sont égales
           - 2 si la date de référence est supérieure (périmé) */
        '       , decode(sign(' ||
        lStrChronoValue ||
        ' - ' ||
        lStrDateRef ||
        '), 1, 0, 0, 1, 2) TIME_LIMIT_ORDER_BY';
      lStrSQLQueryFrom    := lStrSQLQueryFrom || '    FROM STM_STOCK_POSITION SPO ';
      lStrSQLQueryFrom    := lStrSQLQueryFrom || '       , STM_ELEMENT_NUMBER SEM ';
      lStrSQLQueryWhere   := lStrSQLQueryWhere || '  WHERE SPO.GCO_GOOD_ID = ' || to_char(iGoodId) || '    AND SPO.C_POSITION_STATUS <> 03 ';
      lStrSQLQueryWhere   := lStrSQLQueryWhere || '    and SPO.STM_ELEMENT_NUMBER_DETAIL_ID = SEM.STM_ELEMENT_NUMBER_ID (+) ';
      lStrSQLQueryWhere   := lStrSQLQueryWhere || '    AND STM_FUNCTIONS.GetElementStatus(SPO.STM_ELEMENT_NUMBER_ID) in (''00'',''02'',''04'') ';
      lStrSQLQueryWhere   := lStrSQLQueryWhere || '    AND STM_FUNCTIONS.GetElementStatus(SPO.STM_STM_ELEMENT_NUMBER_ID) in (''00'',''02'',''04'') ';
      lStrSQLQueryWhere   := lStrSQLQueryWhere || '    AND STM_FUNCTIONS.GetElementStatus(SPO.STM2_STM_ELEMENT_NUMBER_ID) in (''00'',''02'',''04'') ';

      if     lPDT_STOCK_ALLOC_BATCH = 1
         and iPriorityToAttribs = 1 then
        lStrSQLQuerySelect  := lStrSQLQuerySelect || '  , FNN.FAL_LOT_ID ';
        lStrSQLQueryFrom    := lStrSQLQueryFrom || '    , FAL_NETWORK_LINK FNL, FAL_NETWORK_NEED FNN ';
        lStrSQLQueryWhere   :=
          lStrSQLQueryWhere ||
          '    AND SPO.STM_STOCK_POSITION_ID = FNL.STM_STOCK_POSITION_ID (+) ' ||
          '    AND FNL.FAL_NETWORK_NEED_ID = FNN.FAL_NETWORK_NEED_ID (+) ' ||
          '    AND NVL(FNN.FAL_LOT_ID,' ||
          to_char(iLotId) ||
          ') in (' ||
          to_char(iLotId) ||
          ',FNN.FAL_LOT_ID)' ||
          '    AND NVL(SPO.SPO_AVAILABLE_QUANTITY,0) + NVL(SPO.SPO_ASSIGN_QUANTITY,0) > 0 ';
      else
        lStrSQLQuerySelect  := lStrSQLQuerySelect || '       , 0 as FAL_LOT_ID ';
        lStrSQLQueryWhere   := lStrSQLQueryWhere || '    AND NVL(SPO.SPO_AVAILABLE_QUANTITY,0) > 0 ';
      end if;

      -- Si on est pas dans le cas d'une affectation automatique demandé par le gabarit ou que le nombre de caratérisation géré en stock
      -- est supérieure à 1 ou que l'article n'est pas géré en stock, rien n'est proposé.
      if    not(    (    lNbCharStock = 1
                     and lC_CHRONOLOGY_TYPE is not null)
                or (iAutoChar = 1) )
         or not lFound then
        lStrSQLQueryWhere  := lStrSQLQueryWhere || '    AND 1 = 0 ';
      end if;

      -- Si Existance de Charactérisation
      if     (lPDTHasPeremptionDate = 1)
         and (nvl(iThirdId, 0) <> 0) then
        lStrSQLQueryWhere  := lStrSQLQueryWhere || ' AND (SPO.SPO_CHRONOLOGICAL is null  OR ' || lStrChronoValue || ' >= ' || lStrDateRef || ') ';
      else
        if STM_I_LIB_CONSTANT.gcCfgUseQualityStatus then
          lStrSQLQueryFrom   :=
            lStrSQLQueryFrom ||
            ' , (select FAL_TOOLS.GetConfig_StockID(''PPS_DefltSTOCK_FLOOR'') StockWorkshopId ' ||
            '         , FAL_TOOLS.GetConfig_LocationID(''PPS_DefltLOCATION_FLOOR'', FAL_TOOLS.GetConfig_StockID(''PPS_DefltSTOCK_FLOOR'')) LocationWorkshopId ' ||
            '         , FAL_STOCK_MOVEMENT_FUNCTIONS.GetMvtKindCompoStockOut MvtKindCompoStockOut ' ||
            '         , FAL_STOCK_MOVEMENT_FUNCTIONS.GetMvtKindCompoWorkshopIn MvtKindCompoWorkshopIn ' ||
            '      from dual) CONST ';
          -- Vérifie si le genre de mouvement sortie est autorisé pour la position de stock
          lStrSQLQueryWhere  :=
            lStrSQLQueryWhere ||
            '   and STM_LIB_MOVEMENT.VerifyStockOutputCond(SPO.GCO_GOOD_ID ' ||
            '         , SPO.STM_STOCK_ID ' ||
            '         , SPO.STM_LOCATION_ID ' ||
            '         , SEM.GCO_QUALITY_STATUS_ID ' ||
            '         , SPO.SPO_CHRONOLOGICAL ' ||
            '         , SPO.SPO_PIECE ' ||
            '         , SPO.SPO_SET ' ||
            '         , SPO.SPO_VERSION ' ||
            '         , CONST.MvtKindCompoStockOut ' ||
            ' , ' ||
            lStrDateRef ||
            ', 0) is null ';
          -- Vérifie si le genre de mouvement entrée atelier est autorisé pour la position de stock
          lStrSQLQueryWhere  :=
            lStrSQLQueryWhere ||
            '   and STM_LIB_MOVEMENT.VerifyStockOutputCond(SPO.GCO_GOOD_ID ' ||
            '         , CONST.StockWorkshopId ' ||
            '         , CONST.LocationWorkshopId ' ||
            '         , SEM.GCO_QUALITY_STATUS_ID ' ||
            '         , SPO.SPO_CHRONOLOGICAL ' ||
            '         , SPO.SPO_PIECE ' ||
            '         , SPO.SPO_SET ' ||
            '         , SPO.SPO_VERSION ' ||
            '         , CONST.MvtKindCompoWorkshopIn ' ||
            ' , ' ||
            lStrDateRef ||
            ', 0) is null ';
        end if;
      end if;

      -- Détermination des emplacements de stock à prendre en compte selon les configurations
      -- FAL_LOCATION_SELECT_LAUNCH et FAL_USE_LOCATION_SELECT_LAUNCH
      if iPriorityLocationId is not null then
        -- Si un stock prioritaire est définit, on propose tous les stocks géré dans le calcul des besoins qu'elle que soit les configurations
        lStrSQLQueryWhere  :=
          lStrSQLQueryWhere ||
          ' AND SPO.STM_STOCK_ID IN (SELECT STM_STOCK_ID ' ||
          '                            FROM STM_STOCK ' ||
          '                           WHERE C_ACCESS_METHOD = ''PUBLIC'' ' ||
          '                             AND STO_NEED_CALCULATION = 1)';
      elsif     nvl(iForceLocation, 0) = 0
            and FAL_I_LIB_CONSTANT.gCfgUseLocationSelectLaunch then
        -- Utilisation des positions de stocks de l'emplacement de stock du composant
        if FAL_I_LIB_CONSTANT.gCfgLocationSelectLaunch = 1 then
          lStrSQLQueryWhere  := lStrSQLQueryWhere || ' AND SPO.STM_LOCATION_ID = ' || to_char(nvl(iLocationId, 0) );
        -- Utilisation des positions de stocks des emplacements de stock du stock du composant
        elsif FAL_I_LIB_CONSTANT.gCfgLocationSelectLaunch = 2 then
          lStrSQLQueryWhere  :=
            lStrSQLQueryWhere ||
            ' AND SPO.STM_STOCK_ID = (select MAX(STM_STOCK_ID) ' ||
            '                           from STM_LOCATION ' ||
            '                          where STM_LOCATION_ID = ' ||
            to_char(nvl(iLocationId, 0) ) ||
            ') ';
        -- utilisation des positions de stocks des emplacements de stock des stocks " public " gérés dans le calcul des besoins.
        elsif FAL_I_LIB_CONSTANT.gCfgLocationSelectLaunch = 3 then
          lStrSQLQueryWhere  :=
            lStrSQLQueryWhere ||
            ' AND SPO.STM_STOCK_ID IN (SELECT STM_STOCK_ID ' ||
            '                            FROM STM_STOCK ' ||
            '                           WHERE C_ACCESS_METHOD = ''PUBLIC'' ' ||
            '                             AND STO_NEED_CALCULATION = 1)';
        end if;
      elsif iInStrLocationList is not null then
        lStrSQLQueryWhere  := lStrSQLQueryWhere || 'AND SPO.STM_LOCATION_ID in (' || iInStrLocationList || ')';
      elsif nvl(iLocationId, 0) <> 0 then
        lStrSQLQueryWhere  := lStrSQLQueryWhere || 'AND SPO.STM_LOCATION_ID = ' || to_char(iLocationId);
      end if;
    end if;

    -- Si Aucune caractérisation ou position existante, tri en prenant l'emplacement passé en paramètre en premier
    -- puis par disponible max descendant
    if lNbChar = 0 then
      lStrSQLQueryOrderby  := ' ORDER BY ';

      -- Priorisation des emplacements de stock
      if iOnlyOrderBy = 0 then
        lStrSQLQueryOrderby  := lStrSQLQueryOrderby || 'LOCATION_ORDER_BY, ';
      end if;

      lStrSQLQueryOrderby  := lStrSQLQueryOrderby || '  SPO.SPO_AVAILABLE_QUANTITY DESC';
    else
      -- Si attribution des besoins Fabrication sur stock
      if     lPDT_STOCK_ALLOC_BATCH = 1
         and iPriorityToAttribs = 1 then
        lStrSQLQueryOrderby  := lStrSQLQueryOrderby || ' ORDER BY FAL_TOOLS.IDENTICAL(FNN.FAL_LOT_ID,' || iLotId || ') DESC';
      else
        lStrSQLQueryOrderby  := lStrSQLQueryOrderby || ' ORDER BY NULL';
      end if;

      -- Priorisation des emplacements de stock
      if     (iOnlyOrderBy = 0)
         and (lC_CHRONOLOGY_TYPE <> '3') then
        lStrSQLQueryOrderby  := lStrSQLQueryOrderby || ', LOCATION_ORDER_BY ';
      end if;

      -- Si chronologie FIFO
      if lC_CHRONOLOGY_TYPE = '1' then
        -- Tri par chrono ascendante
        lStrSQLQueryOrderby  := lStrSQLQueryOrderby || ', SPO.SPO_CHRONOLOGICAL ASC ';
      -- Chronologie de type LIFO
      elsif lC_CHRONOLOGY_TYPE = '2' then
        -- Tri par chrono descendante
        lStrSQLQueryOrderby  := lStrSQLQueryOrderby || ', SPO.SPO_CHRONOLOGICAL DESC ';
      -- Chronologie de type péremption
      elsif lC_CHRONOLOGY_TYPE = '3' then
        -- Tri par chrono ascendante mais les périmés en dernier
        if iOnlyOrderBy = 0 then
          lStrSQLQueryOrderby  := lStrSQLQueryOrderby || ', TIME_LIMIT_ORDER_BY || LOCATION_ORDER_BY || SPO.SPO_CHRONOLOGICAL ASC ';
        else
          lStrSQLQueryOrderby  := lStrSQLQueryOrderby || ', TIME_LIMIT_ORDER_BY || SPO.SPO_CHRONOLOGICAL ASC ';
        end if;
      end if;

      -- Si tracabilité complète
      if lIS_FULL_TRACABILITY = 1 then
        -- Tri par lot, version, pièce ASC
        lStrSQLQueryOrderby  := lStrSQLQueryOrderby || ', PcsToNumber(SPO.SPO_SET) ASC ';
        lStrSQLQueryOrderby  := lStrSQLQueryOrderby || ', SPO.SPO_SET ASC ';
        lStrSQLQueryOrderby  := lStrSQLQueryOrderby || ', PCsToNumber(SPO.SPO_VERSION) ASC ';
        lStrSQLQueryOrderby  := lStrSQLQueryOrderby || ', SPO.SPO_VERSION ASC ';
        lStrSQLQueryOrderby  := lStrSQLQueryOrderby || ', PcsToNumber(SPO.SPO_PIECE) ASC ';
        lStrSQLQueryOrderby  := lStrSQLQueryOrderby || ', SPO.SPO_PIECE ASC ';
      else
        -- Tri par version, lot, pièce ASC
        lStrSQLQueryOrderby  := lStrSQLQueryOrderby || ', PCsToNumber(SPO.SPO_VERSION) ASC ';
        lStrSQLQueryOrderby  := lStrSQLQueryOrderby || ', SPO.SPO_VERSION ASC ';
        lStrSQLQueryOrderby  := lStrSQLQueryOrderby || ', PcsToNumber(SPO.SPO_SET) ASC ';
        lStrSQLQueryOrderby  := lStrSQLQueryOrderby || ', SPO.SPO_SET ASC ';
        lStrSQLQueryOrderby  := lStrSQLQueryOrderby || ', PcsToNumber(SPO.SPO_PIECE) ASC ';
        lStrSQLQueryOrderby  := lStrSQLQueryOrderby || ', SPO.SPO_PIECE ASC ';
      end if;

      lStrSQLQueryOrderby  := lStrSQLQueryOrderby || ' , SPO.SPO_AVAILABLE_QUANTITY DESC';
    end if;

    -- Contruction finale de la requête
    oSQLQuery  := lStrSQLQuerySelect || lStrSQLQueryFrom || lStrSQLQueryWhere || lStrSQLQueryOrderby;
  end BuildSTM_STOCK_POSITIONQuery;

  /**
  * procedure ChangeTimeLimit
  * Description
  *   Modifie la date de péremtion d'une position de stock (effectue un mvt de transformation de caractérisation )
  */
  procedure ChangeTimeLimit(iStockPositionID in STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type, iNewTimeLimit in varchar2)
  is
    lTimeLimitCharID GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lInMvtKindID     STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
    lOutMvtKindID    STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
    lInMvtID         STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
    lOutMvtID        STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
    lExerciseID      STM_EXERCISE.STM_EXERCISE_ID%type;
    lPeriodID        STM_PERIOD.STM_PERIOD_ID%type;
    lGoodID          STM_STOCK_POSITION.GCO_GOOD_ID%type;
    lStockID         STM_STOCK_POSITION.STM_STOCK_ID%type;
    lLocationID      STM_STOCK_POSITION.STM_LOCATION_ID%type;
    lChar1ID         STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type;
    lChar2ID         STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type;
    lChar3ID         STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type;
    lChar4ID         STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type;
    lChar5ID         STM_STOCK_POSITION.GCO_CHARACTERIZATION_ID%type;
    lCharValue1      STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
    lCharValue2      STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type;
    lCharValue3      STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type;
    lCharValue4      STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type;
    lCharValue5      STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type;
    lNewCharValue1   STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
    lNewCharValue2   STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type;
    lNewCharValue3   STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type;
    lNewCharValue4   STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type;
    lNewCharValue5   STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type;
    lQuantity        STM_STOCK_POSITION.SPO_AVAILABLE_QUANTITY%type;
  begin
    -- Récuperer les données de la position de stock à traiter
    select GCO_GOOD_ID
         , STM_STOCK_ID
         , STM_LOCATION_ID
         , GCO_CHARACTERIZATION_ID
         , GCO_GCO_CHARACTERIZATION_ID
         , GCO2_GCO_CHARACTERIZATION_ID
         , GCO3_GCO_CHARACTERIZATION_ID
         , GCO4_GCO_CHARACTERIZATION_ID
         , SPO_CHARACTERIZATION_VALUE_1
         , SPO_CHARACTERIZATION_VALUE_2
         , SPO_CHARACTERIZATION_VALUE_3
         , SPO_CHARACTERIZATION_VALUE_4
         , SPO_CHARACTERIZATION_VALUE_5
         , SPO_AVAILABLE_QUANTITY
      into lGoodID
         , lStockID
         , lLocationID
         , lChar1ID
         , lChar2ID
         , lChar3ID
         , lChar4ID
         , lChar5ID
         , lCharValue1
         , lCharValue2
         , lCharValue3
         , lCharValue4
         , lCharValue5
         , lQuantity
      from STM_STOCK_POSITION
     where STM_STOCK_POSITION_ID = iStockPositionID;

    lNewCharValue1  := lCharValue1;
    lNewCharValue2  := lCharValue2;
    lNewCharValue3  := lCharValue3;
    lNewCharValue4  := lCharValue4;
    lNewCharValue5  := lCharValue5;

    -- Recherche l'id de la caractérisation
    select max(GCO_CHARACTERIZATION_ID)
      into lTimeLimitCharID
      from GCO_CHARACTERIZATION
     where GCO_GOOD_ID = lGoodID
       and C_CHARACT_TYPE = GCO_I_LIB_CONSTANT.gcCharacTypeChrono
       and C_CHRONOLOGY_TYPE = GCO_I_LIB_CONSTANT.gcChronologyTypePeremption;

    if lTimeLimitCharID is not null then
      -- Rechercher les ids du type de mvt d'entrée/sortie pour la transformation de caractérisation
      STM_LIB_MOVEMENT.GetTransfCharMvtKind(oInMvtKindID => lInMvtKindID, oOutMvtKindID => lOutMvtKindID);

      -- Type de mvt pour la transformation défini
      if     (lInMvtKindID is not null)
         and (lOutMvtKindID is not null) then
        -- Trouver et initialiser la  valeur de caractérisation correspondant au type péremption
        if     (lChar1ID is not null)
           and (lChar1ID = lTimeLimitCharID) then
          lNewCharValue1  := iNewTimeLimit;
        elsif     (lChar2ID is not null)
              and (lChar2ID = lTimeLimitCharID) then
          lNewCharValue2  := iNewTimeLimit;
        elsif     (lChar3ID is not null)
              and (lChar3ID = lTimeLimitCharID) then
          lNewCharValue3  := iNewTimeLimit;
        elsif     (lChar4ID is not null)
              and (lChar4ID = lTimeLimitCharID) then
          lNewCharValue4  := iNewTimeLimit;
        elsif     (lChar5ID is not null)
              and (lChar5ID = lTimeLimitCharID) then
          lNewCharValue5  := iNewTimeLimit;
        end if;

        -- retourne l'id de la période correspondant à la date
        lPeriodID    := STM_FUNCTIONS.GetPeriodId(trunc(sysdate) );
        lExerciseID  := STM_FUNCTIONS.getPeriodExerciseId(lPeriodID);
        -- Mvt de sortie
        STM_I_PRC_MOVEMENT.GenerateMovement(ioStockMovementId   => lOutMvtID
                                          , iGoodId             => lGoodID
                                          , iMovementKindId     => lOutMvtKindID
                                          , iExerciseId         => lExerciseID
                                          , iPeriodId           => lPeriodID
                                          , iMvtDate            => trunc(sysdate)
                                          , iValueDate          => trunc(sysdate)
                                          , iStockId            => lStockID
                                          , iLocationId         => lLocationID
                                          , iChar1Id            => lChar1ID
                                          , iChar2Id            => lChar2ID
                                          , iChar3Id            => lChar3ID
                                          , iChar4Id            => lChar4ID
                                          , iChar5Id            => lChar5ID
                                          , iCharValue1         => lCharValue1
                                          , iCharValue2         => lCharValue2
                                          , iCharValue3         => lCharValue3
                                          , iCharValue4         => lCharValue4
                                          , iCharValue5         => lCharValue5
                                          , iMvtQty             => lQuantity
                                          , iMvtPrice           => 0
                                          , iDocQty             => 0
                                          , iDocPrice           => 0
                                          , iUnitPrice          => 0
                                          , iRecStatus          => 8
                                           );

        if lOutMvtID is not null then
          -- Génération du mvt d'entrée
          STM_I_PRC_MOVEMENT.GenerateMovement(ioStockMovementId   => lInMvtID
                                            , iGoodId             => lGoodID
                                            , iMovementKindId     => lInMvtKindID
                                            , iExerciseId         => lExerciseID
                                            , iPeriodId           => lPeriodID
                                            , iMvtDate            => trunc(sysdate)
                                            , iValueDate          => trunc(sysdate)
                                            , iStockId            => lStockID
                                            , iLocationId         => lLocationID
                                            , iChar1Id            => lChar1ID
                                            , iChar2Id            => lChar2ID
                                            , iChar3Id            => lChar3ID
                                            , iChar4Id            => lChar4ID
                                            , iChar5Id            => lChar5ID
                                            , iCharValue1         => lNewCharValue1
                                            , iCharValue2         => lNewCharValue2
                                            , iCharValue3         => lNewCharValue3
                                            , iCharValue4         => lNewCharValue4
                                            , iCharValue5         => lNewCharValue5
                                            , iMovement2ID        => lOutMvtID
                                            , iMvtQty             => lQuantity
                                            , iMvtPrice           => 0
                                            , iDocQty             => 0
                                            , iDocPrice           => 0
                                            , iUnitPrice          => 0
                                            , iRecStatus          => 8
                                             );
          -- Création des informations de tracabilité liée au mouvements de transformation
          STM_PRC_MOVEMENT.AddTrsfTracability(iMovementId   => lOutMvtID
                                            , iGoodId       => lGoodID
                                            , iCharId1      => lChar1ID
                                            , iCharId2      => lChar2ID
                                            , iCharId3      => lChar3ID
                                            , iCharId4      => lChar4ID
                                            , iCharId5      => lChar5ID
                                            , iOldChar1     => lCharValue1
                                            , iNewChar1     => lNewCharValue1
                                            , iOldChar2     => lCharValue2
                                            , iNewChar2     => lNewCharValue2
                                            , iOldChar3     => lCharValue3
                                            , iNewChar3     => lNewCharValue3
                                            , iOldChar4     => lCharValue4
                                            , iNewChar4     => lNewCharValue4
                                            , iOldChar5     => lCharValue5
                                            , iNewChar5     => lNewCharValue5
                                             );
        end if;
      end if;
    end if;
  end ChangeTimeLimit;

  /**
  * procedure pGenerateRecyclingDocument
  * Description
  *    Création du document de sortie/transfert des lots périmés
  */
  procedure pGenerateRecyclingDocument(
    ioDocumentID in out DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , iGaugeID     in     DOC_GAUGE.DOC_GAUGE_ID%type
  , iThirdID     in     PAC_THIRD.PAC_THIRD_ID%type
  , iStockID     in     STM_STOCK.STM_STOCK_ID%type
  , iLocationID  in     STM_LOCATION.STM_LOCATION_ID%type
  , iHeadingText in     DOC_DOCUMENT.DMT_HEADING_TEXT%type
  , iFootText    in     DOC_FOOT.FOO_FOOT_TEXT%type
  )
  is
    cursor lcrPos
    is
      select   SPO.GCO_GOOD_ID
             , sum(SPO.SPO_AVAILABLE_QUANTITY) as SPO_AVAILABLE_QUANTITY
             , min(SPO.STM_LOCATION_ID) as STM_LOCATION_ID
          from COM_LIST_ID_TEMP LID
             , STM_STOCK_POSITION SPO
             , GCO_GOOD GOO
         where LID.COM_LIST_ID_TEMP_ID = SPO.STM_STOCK_POSITION_ID
           and LID.LID_CODE = 'STM_STOCK_RECYCLING'
           and SPO.GCO_GOOD_ID = GOO.GCO_GOOD_ID
      group by SPO.GCO_GOOD_ID
             , GOO.GOO_MAJOR_REFERENCE
      order by GOO.GOO_MAJOR_REFERENCE asc;

    cursor lcrDetail(iGoodID in GCO_GOOD.GCO_GOOD_ID%type)
    is
      select   SPO.GCO_GOOD_ID
             , SPO.SPO_AVAILABLE_QUANTITY
             , SPO.SPO_CHARACTERIZATION_VALUE_1
             , SPO.SPO_CHARACTERIZATION_VALUE_2
             , SPO.SPO_CHARACTERIZATION_VALUE_3
             , SPO.SPO_CHARACTERIZATION_VALUE_4
             , SPO.SPO_CHARACTERIZATION_VALUE_5
             , SPO.STM_STOCK_ID
             , SPO.STM_LOCATION_ID
          from COM_LIST_ID_TEMP LID
             , STM_STOCK_POSITION SPO
         where LID.COM_LIST_ID_TEMP_ID = SPO.STM_STOCK_POSITION_ID
           and LID.LID_CODE = 'STM_STOCK_RECYCLING'
           and SPO.GCO_GOOD_ID = iGoodID
      order by SPO.SPO_CHARACTERIZATION_VALUE_1
             , SPO.SPO_CHARACTERIZATION_VALUE_2
             , SPO.SPO_CHARACTERIZATION_VALUE_3
             , SPO.SPO_CHARACTERIZATION_VALUE_4
             , SPO.SPO_CHARACTERIZATION_VALUE_5;

    lnPositionID    DOC_POSITION.DOC_POSITION_ID%type;
    lnDetailID      DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    lnStockID       STM_STOCK.STM_STOCK_ID%type;
    lnLocationID    STM_LOCATION.STM_LOCATION_ID%type;
    lnTraStockID    STM_STOCK.STM_STOCK_ID%type;
    lnTraLocationID STM_LOCATION.STM_LOCATION_ID%type;
    lnTraMvt        integer;
  begin
    -- Effacement des attributions sur les positions de stock sélectionnées
    for ltplSpo in (select FNL.FAL_NETWORK_LINK_ID
                         , FNL.FAL_NETWORK_NEED_ID
                         , FNL.FAL_NETWORK_SUPPLY_ID
                         , SPO.STM_STOCK_POSITION_ID
                         , FNL.STM_LOCATION_ID
                         , FNL.FLN_QTY
                      from COM_LIST_ID_TEMP LID
                         , STM_STOCK_POSITION SPO
                         , FAL_NETWORK_LINK FNL
                     where LID.COM_LIST_ID_TEMP_ID = SPO.STM_STOCK_POSITION_ID
                       and LID.LID_CODE = 'STM_STOCK_RECYCLING'
                       and FNL.STM_STOCK_POSITION_ID = SPO.STM_STOCK_POSITION_ID) loop
      -- Suppression de l'attrib
      FAL_PRC_ATTRIB.deleteAttrib(iNetworkLinkID     => ltplSpo.FAL_NETWORK_LINK_ID
                                , iNetworkNeedID     => ltplSpo.FAL_NETWORK_NEED_ID
                                , iNetworkSupplyID   => ltplSpo.FAL_NETWORK_SUPPLY_ID
                                , iStockPositionID   => ltplSpo.STM_STOCK_POSITION_ID
                                , iLocationID        => ltplSpo.STM_LOCATION_ID
                                , iQty               => ltplSpo.FLN_QTY
                                 );
    end loop;

    --
    -- Effacer les données de la variable
    DOC_DOCUMENT_GENERATE.ResetDocumentInfo(DOC_DOCUMENT_INITIALIZE.DocumentInfo);
    -- La variable ne doit pas être réinitialisée dans la méthode de création
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.CLEAR_DOCUMENT_INFO   := 0;
    -- Texte d'entête du document
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_DMT_HEADING_TEXT  := 1;
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.DMT_HEADING_TEXT      := iHeadingText;
    -- Texte de pied du document
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.USE_FOO_FOOT_TEXT     := 1;
    DOC_DOCUMENT_INITIALIZE.DocumentInfo.FOO_FOOT_TEXT         := iFootText;
    -- Création du document
    DOC_DOCUMENT_GENERATE.GenerateDocument(aNewDocumentID => ioDocumentID, aMode => '131', aGaugeID => iGaugeID, aThirdID => iThirdID);

    -- Définir si le mvt effectué par le document est un mvt de transfert
    --  Si mvt de transfert, alors il faut utiliser les id de stoc/emplacement passsés en param pour le mvt
    select sign(nvl(max(MOK.STM_STM_MOVEMENT_KIND_ID), 0) )
      into lnTraMvt
      from DOC_GAUGE_POSITION GAP
         , STM_MOVEMENT_KIND MOK
     where GAP.DOC_GAUGE_ID = iGaugeID
       and GAP.C_GAUGE_TYPE_POS = '1'
       and GAP.GAP_DEFAULT = 1
       and GAP.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID;

    for ltplPos in lcrPos loop
      lnPositionID  := null;
      -- Stock/Emplacement actuel du produit
      lnStockID     := FWK_I_LIB_ENTITY.getNumberFieldFromPk('STM_LOCATION', 'STM_STOCK_ID', ltplPos.STM_LOCATION_ID);
      lnLocationID  := ltplPos.STM_LOCATION_ID;

      -- Mvt de transfert
      if lnTraMvt = 1 then
        lnTraStockID     := iStockID;
        lnTraLocationID  := iLocationID;
      else
        lnStockID     := null;
        lnLocationID  := null;
      end if;

      DOC_POSITION_GENERATE.GeneratePosition(aPositionID           => lnPositionID
                                           , aDocumentID           => ioDocumentID
                                           , aPosCreateMode        => '131'
                                           , aTypePos              => '1'
                                           , aGoodID               => ltplPos.GCO_GOOD_ID
                                           , aBasisQuantity        => ltplPos.SPO_AVAILABLE_QUANTITY
                                           , aForceStockLocation   => 1
                                           , aStockID              => lnStockID
                                           , aLocationID           => lnLocationID
                                           , aTraStockID           => lnTraStockID
                                           , aTraLocationID        => lnTraLocationID
                                           , aGenerateDetail       => 0
                                            );

      for ltplDetail in lcrDetail(ltplPos.GCO_GOOD_ID) loop
        lnDetailID    := null;
        -- Emplacement actuel du produit
        lnLocationID  := ltplDetail.STM_LOCATION_ID;

        -- Mvt de transfert
        if lnTraMvt = 1 then
          lnTraLocationID  := iLocationID;
        else
          lnTraLocationID  := null;
        end if;

        -- Création du détail
        DOC_DETAIL_GENERATE.GenerateDetail(aDetailID         => lnDetailID
                                         , aPositionID       => lnPositionID
                                         , aPdeCreateMode    => '131'
                                         , aQuantity         => ltplDetail.SPO_AVAILABLE_QUANTITY
                                         , aLocationID       => lnLocationID
                                         , aTraLocationID    => lnTraLocationID
                                         , aCharactValue_1   => ltplDetail.SPO_CHARACTERIZATION_VALUE_1
                                         , aCharactValue_2   => ltplDetail.SPO_CHARACTERIZATION_VALUE_2
                                         , aCharactValue_3   => ltplDetail.SPO_CHARACTERIZATION_VALUE_3
                                         , aCharactValue_4   => ltplDetail.SPO_CHARACTERIZATION_VALUE_4
                                         , aCharactValue_5   => ltplDetail.SPO_CHARACTERIZATION_VALUE_5
                                          );
      end loop;
    end loop;

    -- Mise à jour des totaux de document, des remises/taxes de pieds,
    --  de l'arrondi TVA et des échéances avant la libération (fin d'édition) du document
    DOC_FINALIZE.FinalizeDocument(ioDocumentID);
  end pGenerateRecyclingDocument;

  /**
  * procedure GenerateRecyclingDocument
  * Description
  *    Création du document de sortie/transfert des lots périmés
  */
  procedure GenerateRecyclingDocument(
    ioDocumentID in out DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , iGaugeID     in     DOC_GAUGE.DOC_GAUGE_ID%type
  , iThirdID     in     PAC_THIRD.PAC_THIRD_ID%type
  , iStockID     in     STM_STOCK.STM_STOCK_ID%type
  , iLocationID  in     STM_LOCATION.STM_LOCATION_ID%type
  , iHeadingText in     DOC_DOCUMENT.DMT_HEADING_TEXT%type
  , iFootText    in     DOC_FOOT.FOO_FOOT_TEXT%type
  )
  is
    lvProcIndiv varchar2(100)   := PCS.PC_CONFIG.GetConfig('STM_PEREMP_IND_GEN_DOC');
    lvSql       varchar2(32000);
  begin
    -- Execution de la procédure indiv de création du document si existante
    if lvProcIndiv is not null then
      lvSql  := ' begin ' || lvProcIndiv || '(:ioDocumenID, :iGaugeID, :iThirdID, :iStockID, :iLocationID, :iHeadingText, :iFootText); ' || ' end;';

      execute immediate lvSql
                  using in out ioDocumentID, in iGaugeID, in iThirdID, in iStockID, in iLocationID, in iHeadingText, in iFootText;
    else
      pGenerateRecyclingDocument(ioDocumentID   => ioDocumentID
                               , iGaugeID       => iGaugeID
                               , iThirdID       => iThirdID
                               , iStockID       => iStockID
                               , iLocationID    => iLocationID
                               , iHeadingText   => iHeadingText
                               , iFootText      => iFootText
                                );
    end if;

    -- Effacement des données de la table temp
    delete from COM_LIST_ID_TEMP
          where LID_CODE = 'STM_STOCK_RECYCLING';
  end GenerateRecyclingDocument;
end STM_PRC_STOCK_POSITION;
