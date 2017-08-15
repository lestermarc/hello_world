--------------------------------------------------------
--  DDL for Package Body DOC_PRC_MOVEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_PRC_MOVEMENT" 
is
  gDetailId    DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
  gDocumentQty STM_STOCK_MOVEMENT.SMO_DOCUMENT_QUANTITY%type;

  /**
  * Description
  *   Return report movement ID
  */
  function getReportMovementKindId
    return STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type
  is
    lResult STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
  begin
    -- recherche de l'id du genre de mouvement de report d'exercice
    select STM_MOVEMENT_KIND_ID
      into lResult
      from STM_MOVEMENT_KIND
     where C_MOVEMENT_SORT = 'ENT'
       and C_MOVEMENT_TYPE = 'EXE'
       and C_MOVEMENT_CODE = '004';

    return lResult;
  end getReportMovementKindId;

  /**
  * Description
  *              fonction qui retourne la quantité document pour le mouvement en fonction
  *              de la quantité valeur de la position et des détail précédant
  */
  function GetDocumentQty(
    iPositionId  in doc_position.doc_position_id%type
  , iPosValueQty in doc_position.pos_value_quantity%type
  , iDetailId    in doc_position_detail.doc_position_detail_id%type
  , iDetailQty   in doc_position_detail.pde_final_quantity%type
  )
    return number
  is
    lQtyUsed STM_STOCK_MOVEMENT.SMO_DOCUMENT_QUANTITY%type;
  begin
    if nvl(gDetailId, 0) <> iDetailId then
      gDetailId     := iDetailId;

      select nvl(sum(PDE_FINAL_QUANTITY), 0)
        into lQtyUsed
        from DOC_POSITION_DETAIL PDE
       where PDE.DOC_POSITION_ID = iPositionId
         and PDE.DOC_POSITION_DETAIL_ID < iDetailId;

      gDocumentQty  := least(iPosValueQty - lQtyUsed, iDetailQty);
    end if;

    return gDocumentQty;
  end GetDocumentQty;

  /**
  * Description  Procedure appelée depuis le trigger d'insertion des mouvements
  *              de stock. Elle met à jour la table DOC_PIC_RELEASE_BUFFER
  */
  procedure InsertPicBuffer(itMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
  is
  begin
    -- 1 : Utilisation du Plan Commerciale, Mise à jour des Réalisés
    -- 3 : Utilisation PC et PDP, Mise à jour des Commandes et des Réalisés
    if     itMovementRecord.DOC_POSITION_ID is not null
       and PCS.PC_CONFIG.GetConfig('FAL_PIC') in('1', '3') then
      insert into DOC_PIC_RELEASE_BUFFER
                  (DOC_PIC_RELEASE_BUFFER_ID
                 , PAC_REPRESENTATIVE_ID
                 , PAC_THIRD_ID
                 , GCO_GOOD_ID
                 , GCO_GCO_GOOD_ID
                 , PRB_DATE
                 , PRB_QUANTITY
                 , PRB_VALUE
                 , A_DATECRE
                 , A_IDCRE
                  )
        select getNewId
             , POS.PAC_REPRESENTATIVE_ID
             , POS.PAC_THIRD_ID
             , POS.GCO_GOOD_ID
             , PDT.GCO2_GCO_GOOD_ID
             , itMovementRecord.SMO_MOVEMENT_DATE
             , decode(MOK.C_MOVEMENT_SORT, 'ENT', -1, 'SOR', 1) * itMovementRecord.SMO_MOVEMENT_QUANTITY
             , decode(MOK.C_MOVEMENT_SORT, 'ENT', -1, 'SOR', 1) *
               decode(POS.POS_FINAL_QUANTITY_SU * itMovementRecord.SMO_MOVEMENT_QUANTITY
                    , 0, 0
                    , POS.POS_NET_VALUE_EXCL_B / POS.POS_FINAL_QUANTITY_SU * itMovementRecord.SMO_MOVEMENT_QUANTITY
                     )
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from DOC_POSITION POS
             , STM_MOVEMENT_KIND MOK
             , GCO_PRODUCT PDT
         where POS.DOC_POSITION_ID = itMovementRecord.DOC_POSITION_ID
           and MOK.STM_MOVEMENT_KIND_ID = itMovementRecord.STM_MOVEMENT_KIND_ID
           and MOK.MOK_PIC_USE = 1
           and POS.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+);
    end if;
  end InsertPicBuffer;

  /**
  * Procedure provisoryQuantity
  * Description
  *    procedure de mise à jour des quantités provisoires des position de stock
  */
  procedure provisoryQuantity(
    iGoodId           in gco_good.gco_good_id%type
  , iUpdateMode       in varchar2
  , iMoveSort         in stm_movement_kind.c_movement_sort%type
  , iVerifyChar       in stm_movement_kind.mok_verify_characterization%type
  , iParityMoveKindId in stm_stock_movement.stm_stock_movement_id%type
  , iCharactId1       in stm_stock_movement.gco_characterization_id%type
  , iCharactId2       in stm_stock_movement.gco_gco_characterization_id%type
  , iCharactId3       in stm_stock_movement.gco2_gco_characterization_id%type
  , iCharactId4       in stm_stock_movement.gco3_gco_characterization_id%type
  , iCharactId5       in stm_stock_movement.gco4_gco_characterization_id%type
  , iCharactVal1      in stm_stock_movement.smo_characterization_value_1%type
  , iCharactVal2      in stm_stock_movement.smo_characterization_value_2%type
  , iCharactVal3      in stm_stock_movement.smo_characterization_value_3%type
  , iCharactVal4      in stm_stock_movement.smo_characterization_value_4%type
  , iCharactVal5      in stm_stock_movement.smo_characterization_value_5%type
  , iStockId          in stm_stock_movement.stm_stock_id%type
  , iLocationId       in stm_stock_movement.stm_location_id%type
  , iTransStockId     in stm_stock_movement.stm_stock_id%type
  , iTransLocationId  in stm_stock_movement.stm_location_id%type
  , iMovementQuantity in stm_stock_movement.smo_movement_quantity%type
  )
  is
    lMovementSort           STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type;
    lMvtStockId             STM_STOCK.STM_STOCK_ID%type;
    lMvtLocationId          STM_LOCATION.STM_LOCATION_ID%type;
    lStockPositionId        STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type;
    lElementNumberId1       STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    lElementNumberId2       STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    lElementNumberId3       STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    lOutputQty              STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type;
    lInputQty               STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type;
    lCharacterizationId1    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharacterizationId2    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharacterizationId3    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharacterizationId4    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharacterizationId5    GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    lCharacterizationValue1 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
    lCharacterizationValue2 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type;
    lCharacterizationValue3 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type;
    lCharacterizationValue4 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type;
    lCharacterizationValue5 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type;
    lStockmanagement        GCO_PRODUCT.PDT_STOCK_MANAGEMENT%type;
    lBoucle                 number(1);
    lModemaj                varchar2(2);

    cursor lcurParity(MovementKindId stm_movement_kind.stm_movement_kind_id%type)
    is
      select   STM_LOCATION_ID
             , STM_LOCATION.STM_STOCK_ID
          from STM_LOCATION
             , STM_MOVEMENT_KIND
         where STM_MOVEMENT_KIND_ID = MovementKindId
           and STM_LOCATION.STM_STOCK_ID = STM_MOVEMENT_KIND.STM_STOCK_ID
      order by LOC_CLASSIFICATION;

    cursor lcurStkChar(
      iChar1Id  stm_stock_movement.gco_characterization_id%type
    , iChar2Id  stm_stock_movement.gco_gco_characterization_id%type
    , iChar3Id  stm_stock_movement.gco2_gco_characterization_id%type
    , iChar4Id  stm_stock_movement.gco3_gco_characterization_id%type
    , iChar5Id  stm_stock_movement.gco4_gco_characterization_id%type
    , iChar1Val stm_stock_movement.smo_characterization_value_1%type
    , iChar2Val stm_stock_movement.smo_characterization_value_2%type
    , iChar3Val stm_stock_movement.smo_characterization_value_3%type
    , iChar4Val stm_stock_movement.smo_characterization_value_4%type
    , iChar5Val stm_stock_movement.smo_characterization_value_5%type
    )
    is
      select   GCO_CHARACTERIZATION_ID
             , iChar1Val char_value
             , 1 lOrdre
          from GCO_CHARACTERIZATION CHA
             , GCO_PRODUCT PDT
         where GCO_CHARACTERIZATION_ID = iChar1Id
           and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
           and CHA_STOCK_MANAGEMENT = 1
           and PDT_STOCK_MANAGEMENT = 1
      union
      select   GCO_CHARACTERIZATION_ID
             , iChar2Val char_value
             , 2 lOrdre
          from GCO_CHARACTERIZATION CHA
             , GCO_PRODUCT PDT
         where GCO_CHARACTERIZATION_ID = iChar2Id
           and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
           and CHA_STOCK_MANAGEMENT = 1
           and PDT_STOCK_MANAGEMENT = 1
      union
      select   GCO_CHARACTERIZATION_ID
             , iChar3Val char_value
             , 3 lOrdre
          from GCO_CHARACTERIZATION CHA
             , GCO_PRODUCT PDT
         where GCO_CHARACTERIZATION_ID = iChar3Id
           and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
           and CHA_STOCK_MANAGEMENT = 1
           and PDT_STOCK_MANAGEMENT = 1
      union
      select   GCO_CHARACTERIZATION_ID
             , iChar4Val char_value
             , 4 lOrdre
          from GCO_CHARACTERIZATION CHA
             , GCO_PRODUCT PDT
         where GCO_CHARACTERIZATION_ID = iChar4Id
           and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
           and CHA_STOCK_MANAGEMENT = 1
           and PDT_STOCK_MANAGEMENT = 1
      union
      select   GCO_CHARACTERIZATION_ID
             , iChar5Val char_value
             , 5 lOrdre
          from GCO_CHARACTERIZATION CHA
             , GCO_PRODUCT PDT
         where GCO_CHARACTERIZATION_ID = iChar5Id
           and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
           and CHA_STOCK_MANAGEMENT = 1
           and PDT_STOCK_MANAGEMENT = 1
      order by 3;

    lOrdre                  number(1);
    lStockQuantity          STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
    lAssignQuantity         STM_STOCK_POSITION.SPO_ASSIGN_QUANTITY%type;
    lProvisoryInput         STM_STOCK_POSITION.SPO_PROVISORY_INPUT%type;
    lQualityStatusId        STM_ELEMENT_NUMBER.GCO_QUALITY_STATUS_ID%type;
  begin
    lMovementSort  := iMoveSort;

    if sign(iMovementQuantity) = -1 then
      -- Mode pour la mise à jour des éléments existant
      lModemaj  := '00';
    else
      -- Mode pour la création d'éléments
      lModemaj  := null;
    end if;

    -- Recherche si le produit fait l'objet d'une gestion de stock ou pas
    select max(PDT_STOCK_MANAGEMENT)
      into lStockmanagement
      from GCO_PRODUCT
     where GCO_GOOD_ID = iGoodId;

    if     iGoodId is not null
       and iMovementQuantity <> 0 then
      if iLocationId is not null then
        -- La mise à jour des quantitiés se fait uniquement pour les produits gérés en stock
        if     lStockmanagement is not null
           and (lStockmanagement = 1) then
          open lcurStkChar(iCharactId1
                         , iCharactId2
                         , iCharactId3
                         , iCharactId4
                         , iCharactId5
                         , iCharactVal1
                         , iCharactVal2
                         , iCharactVal3
                         , iCharactVal4
                         , iCharactVal5
                          );

          fetch lcurStkChar
           into lCharacterizationId1
              , lCharacterizationValue1
              , lOrdre;

          fetch lcurStkChar
           into lCharacterizationId2
              , lCharacterizationValue2
              , lOrdre;

          fetch lcurStkChar
           into lCharacterizationId3
              , lCharacterizationValue3
              , lOrdre;

          fetch lcurStkChar
           into lCharacterizationId4
              , lCharacterizationValue4
              , lOrdre;

          fetch lcurStkChar
           into lCharacterizationId5
              , lCharacterizationValue5
              , lOrdre;

          close lcurStkChar;

          -- Mise à jour de la table element_number et récupération des ID
          --
          -- Remarques :
          --
          --  Le status de l'élement est définit dans la fonction (null transmis).
          --
          --  Il faut transmettre les ID et les valeurs de caractérisation sans
          --  tenir compte de l'éventuel non gestion en stock de celles-ci. C'est
          --  pour cela que l'on transmet à la fonction les ID et les valeurs
          --  des paramètres (CHARACT_ID_n et CHARACT_VAL_n).
          --
          if     not(    lCharacterizationId1 is not null
                     and lCharacterizationValue1 is null)
             and not(    lCharacterizationId2 is not null
                     and lCharacterizationValue2 is null)
             and not(    lCharacterizationId3 is not null
                     and lCharacterizationValue3 is null)
             and not(    lCharacterizationId4 is not null
                     and lCharacterizationValue4 is null)
             and not(    lCharacterizationId5 is not null
                     and lCharacterizationValue5 is null) then
            STM_I_PRC_STOCK_POSITION.GetElementNumber(iGoodId                   => iGoodId
                                                    , iUpdateMode               => iUpdateMode
                                                    , iMovementSort             => lMovementSort
                                                    , iCharacterizationId       => iCharactId1
                                                    , iCharacterization2Id      => iCharactId2
                                                    , iCharacterization3Id      => iCharactId3
                                                    , iCharacterization4Id      => iCharactId4
                                                    , iCharacterization5Id      => iCharactId5
                                                    , iCharacterizationValue1   => iCharactVal1
                                                    , iCharacterizationValue2   => iCharactVal2
                                                    , iCharacterizationValue3   => iCharactVal3
                                                    , iCharacterizationValue4   => iCharactVal4
                                                    , iCharacterizationValue5   => iCharactVal5
                                                    , iVerifyChar               => iVerifyChar
                                                    , iElementStatus            => lModemaj
                                                    , ioElementNumberId1        => lElementNumberId1
                                                    , ioElementNumberId2        => lElementNumberId2
                                                    , ioElementNumberId3        => lElementNumberId3
                                                    , ioQualityStatusId         => lQualityStatusId
                                                     );
            -- initialisation de la variable de l'id de localisation
            lMvtLocationId  := iLocationId;
            lMvtStockId     := iStockId;
            --initialisation de la variable de lBoucle
            lBoucle         := 0;

            while lBoucle <= 1 loop
              -- test si on a affaire . une entr'e ou une sortie
              if lMovementSort = 'ENT' then
                lInputQty   := iMovementQuantity;
                lOutputQty  := 0;
              else
                lInputQty   := 0;
                lOutputQty  := iMovementQuantity;
              end if;

              -- recherche si on a d'j. une position de stock
              begin
                select     STM_STOCK_POSITION_ID
                         , SPO_STOCK_QUANTITY
                         , SPO_ASSIGN_QUANTITY
                         , SPO_PROVISORY_INPUT
                      into lStockPositionId
                         , lStockQuantity
                         , lAssignQuantity
                         , lProvisoryInput
                      from STM_STOCK_POSITION
                     where STM_STOCK_ID = lMvtStockId
                       and STM_LOCATION_ID = lMvtLocationId
                       and GCO_GOOD_ID = iGoodId
                       and (    (    GCO_CHARACTERIZATION_ID = lCharacterizationId1
                                 and SPO_CHARACTERIZATION_VALUE_1 = lCharacterizationValue1)
                            or (    GCO_CHARACTERIZATION_ID is null
                                and lCharacterizationId1 is null)
                           )
                       and (    (    GCO_GCO_CHARACTERIZATION_ID = lCharacterizationId2
                                 and SPO_CHARACTERIZATION_VALUE_2 = lCharacterizationValue2)
                            or (    GCO_GCO_CHARACTERIZATION_ID is null
                                and lCharacterizationId2 is null)
                           )
                       and (    (    GCO2_GCO_CHARACTERIZATION_ID = lCharacterizationId3
                                 and SPO_CHARACTERIZATION_VALUE_3 = lCharacterizationValue3)
                            or (    GCO2_GCO_CHARACTERIZATION_ID is null
                                and lCharacterizationId3 is null)
                           )
                       and (    (    GCO3_GCO_CHARACTERIZATION_ID = lCharacterizationId4
                                 and SPO_CHARACTERIZATION_VALUE_4 = lCharacterizationValue4)
                            or (    GCO3_GCO_CHARACTERIZATION_ID is null
                                and lCharacterizationId4 is null)
                           )
                       and (    (    GCO4_GCO_CHARACTERIZATION_ID = lCharacterizationId5
                                 and SPO_CHARACTERIZATION_VALUE_5 = lCharacterizationValue5)
                            or (    GCO4_GCO_CHARACTERIZATION_ID is null
                                and lCharacterizationId5 is null)
                           )
                       and (   STM_ELEMENT_NUMBER_ID = lElementNumberId1
                            or (    STM_ELEMENT_NUMBER_ID is null
                                and lElementNumberId1 is null) )
                       and (   STM_STM_ELEMENT_NUMBER_ID = lElementNumberId2
                            or (    STM_STM_ELEMENT_NUMBER_ID is null
                                and lElementNumberId2 is null) )
                       and (   STM2_STM_ELEMENT_NUMBER_ID = lElementNumberId3
                            or (    STM2_STM_ELEMENT_NUMBER_ID is null
                                and lElementNumberId3 is null) )
                for update;
              exception
                when no_data_found then
                  lStockPositionId  := null;
              end;

              -- test si on a trouv' une position ou s'il faut en cr'er une
              if lStockPositionId is not null then
                -- Lors de la suppression d'une position, on supprime certaine attributions besoin/stock associées
                -- à la position de stock courante pour garantir l'intégrité de la containte entre la quantité
                -- effective et la quantité attribuée
                if     (lMovementSort = 'ENT')
                   and (    (iUpdateMode = 'D')
                        or (iUpdateMode = 'DD') )
                   and (lStockQuantity + lProvisoryInput + lInputQty < lAssignQuantity) then
                  FAL_PRC_REPORT_ATTRIB.CheckAttributionLink(lStockPositionId, lAssignQuantity -(lStockQuantity + lProvisoryInput + lInputQty) );
                end if;

                update STM_STOCK_POSITION
                   set SPO_PROVISORY_INPUT = nvl(SPO_PROVISORY_INPUT, 0) + lInputQty
                     , SPO_PROVISORY_OUTPUT = nvl(SPO_PROVISORY_OUTPUT, 0) + lOutputQty
                     , SPO_AVAILABLE_QUANTITY = nvl(SPO_AVAILABLE_QUANTITY, 0) - lOutputQty
                     , SPO_THEORETICAL_QUANTITY = nvl(SPO_THEORETICAL_QUANTITY, 0) + lInputQty - lOutputQty
                     , A_DATEMOD = sysdate
                     , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
                 where STM_STOCK_POSITION_ID = lStockPositionId;

                -- dans le cas ou il existerait une position d'inventaire, l'effacement est impossible
                -- mais on ne doit pas générer d'exception
                begin
                  delete from STM_STOCK_POSITION
                        where STM_STOCK_POSITION_ID = lStockPositionId
                          and nvl(SPO_STOCK_QUANTITY, 0) = 0
                          and nvl(SPO_ASSIGN_QUANTITY, 0) = 0
                          and nvl(SPO_PROVISORY_INPUT, 0) = 0
                          and nvl(SPO_PROVISORY_OUTPUT, 0) = 0
                          and nvl(SPO_AVAILABLE_QUANTITY, 0) = 0
                          and nvl(SPO_THEORETICAL_QUANTITY, 0) = 0
                          and nvl(SPO_ALTERNATIV_QUANTITY_1, 0) = 0
                          and nvl(SPO_ALTERNATIV_QUANTITY_2, 0) = 0
                          and nvl(SPO_ALTERNATIV_QUANTITY_1, 0) = 0;
                exception
                  when ex.CHILD_RECORD_FOUND then
                    null;
                end;
              -- on ne crée pas de position en mode effacement
              elsif substr(iUpdateMode, 1, 1) <> 'D' then
                --begin
                insert into STM_STOCK_POSITION
                            (STM_STOCK_POSITION_ID
                           , STM_STOCK_ID
                           , STM_LOCATION_ID
                           , C_POSITION_STATUS
                           , GCO_GOOD_ID
                           , STM_ELEMENT_NUMBER_ID
                           , STM_STM_ELEMENT_NUMBER_ID
                           , STM2_STM_ELEMENT_NUMBER_ID
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
                           , SPO_PROVISORY_INPUT
                           , SPO_PROVISORY_OUTPUT
                           , SPO_AVAILABLE_QUANTITY
                           , SPO_THEORETICAL_QUANTITY
                           , A_DATECRE
                           , A_IDCRE
                            )
                     values (init_id_seq.nextval
                           , lMvtStockId
                           , lMvtLocationId
                           , '01'
                           , iGoodId
                           , lElementNumberId1
                           , lElementNumberId2
                           , lElementNumberId3
                           , lCharacterizationId1
                           , lCharacterizationId2
                           , lCharacterizationId3
                           , lCharacterizationId4
                           , lCharacterizationId5
                           , lCharacterizationValue1
                           , lCharacterizationValue2
                           , lCharacterizationValue3
                           , lCharacterizationValue4
                           , lCharacterizationValue5
                           , lInputQty
                           , lOutputQty
                           , -lOutputQty
                           , lInputQty - lOutputQty
                           , sysdate
                           , PCS.PC_I_LIB_SESSION.GetUserIni
                            );
              end if;

              -- on est pas sur un mouvement de type transfert, on ne repasse pas dans la lBoucle
              if    (iParityMoveKindId is null)
                 or (iParityMoveKindId = 0) then
                -- on ne repasse pas dans la lBoucle
                lBoucle  := 2;
              -- si on a affaire . un mouvement de type transfert on va mettre à jour la compensation
              else
                -- si on a pas d'j. pass' dans l'initialisation du transfert
                if lBoucle = 0 then
                  -- recherche de la sorte de mouvement (ENT,SOR) du mouvement de parit'
                  select C_MOVEMENT_SORT
                    into lMovementSort
                    from STM_MOVEMENT_KIND
                   where STM_MOVEMENT_KIND_ID = iParityMoveKindId;

                  if (iTransLocationId is null) then
                    -- recherche l'emplacement par defaut du stock
                    open lcurParity(iParityMoveKindId);

                    fetch lcurParity
                     into lMvtLocationId
                        , lMvtStockId;

                    close lcurParity;
                  else
                    -- recheche de l'id du stock de transfert en fonction de l'emplacament de tranfert
                    select STM_STOCK_ID
                      into lMvtStockId
                      from STM_LOCATION
                     where STM_LOCATION_ID = iTransLocationId;

                    -- traite l'emplacement de transfert
                    lMvtLocationId  := iTransLocationId;
                  end if;
                end if;

                lBoucle  := lBoucle + 1;
              end if;
            end loop;
          end if;
        end if;
      else
        if     iGoodId is not null
           and lStockmanagement is not null
           and (lStockmanagement <> 1) then
          -- Mise à jour de la table element_number et récupération des ID
          --
          -- Remarques :
          --
          --  Le status de l'élement est définit dans la fonction (null transmis).
          --
          --  Il faut transmettre les ID et les valeurs de caractérisation sans
          --  tenir compte de l'éventuel non gestion en stock de celles-ci. C'est
          --  pour cela que l'on transmet à la fonction les ID et les valeurs
          --  des paramètres (CHARACT_ID_n et CHARACT_VAL_n).
          --
          STM_I_PRC_STOCK_POSITION.GetElementNumber(iGoodId                   => iGoodId
                                                  , iUpdateMode               => iUpdateMode
                                                  , iMovementSort             => lMovementSort
                                                  , iCharacterizationId       => iCharactId1
                                                  , iCharacterization2Id      => iCharactId2
                                                  , iCharacterization3Id      => iCharactId3
                                                  , iCharacterization4Id      => iCharactId4
                                                  , iCharacterization5Id      => iCharactId5
                                                  , iCharacterizationValue1   => iCharactVal1
                                                  , iCharacterizationValue2   => iCharactVal2
                                                  , iCharacterizationValue3   => iCharactVal3
                                                  , iCharacterizationValue4   => iCharactVal4
                                                  , iCharacterizationValue5   => iCharactVal5
                                                  , iVerifyChar               => 0
                                                  , iElementStatus            => lModemaj
                                                  , ioElementNumberId1        => lElementNumberId1
                                                  , ioElementNumberId2        => lElementNumberId2
                                                  , ioElementNumberId3        => lElementNumberId3
                                                  , ioQualityStatusId         => lQualityStatusId
                                                   );
        end if;
      end if;
    else
      if     iGoodId is not null
         and lStockmanagement is not null
         and (lStockmanagement <> 1) then
        -- Mise à jour de la table element_number et récupération des ID
        --
        -- Remarques :
        --
        --  Le status de l'élement est définit dans la fonction (null transmis).
        --
        --  Il faut transmettre les ID et les valeurs de caractérisation sans
        --  tenir compte de l'éventuel non gestion en stock de celles-ci. C'est
        --  pour cela que l'on transmet à la fonction les ID et les valeurs
        --  des paramètres (CHARACT_ID_n et CHARACT_VAL_n).
        --
        STM_I_PRC_STOCK_POSITION.GetElementNumber(iGoodId                   => iGoodId
                                                , iUpdateMode               => iUpdateMode
                                                , iMovementSort             => lMovementSort
                                                , iCharacterizationId       => iCharactId1
                                                , iCharacterization2Id      => iCharactId2
                                                , iCharacterization3Id      => iCharactId3
                                                , iCharacterization4Id      => iCharactId4
                                                , iCharacterization5Id      => iCharactId5
                                                , iCharacterizationValue1   => iCharactVal1
                                                , iCharacterizationValue2   => iCharactVal2
                                                , iCharacterizationValue3   => iCharactVal3
                                                , iCharacterizationValue4   => iCharactVal4
                                                , iCharacterizationValue5   => iCharactVal5
                                                , iVerifyChar               => 0
                                                , iElementStatus            => lModemaj
                                                , ioElementNumberId1        => lElementNumberId1
                                                , ioElementNumberId2        => lElementNumberId2
                                                , ioElementNumberId3        => lElementNumberId3
                                                , ioQualityStatusId         => lQualityStatusId
                                                 );
      end if;
    end if;
  end provisoryQuantity;

  procedure DocExtourneOutputMovements(iDocumentId in doc_document.doc_document_id%type)
  is
    cursor lcurExtourneOutput(iDocumentId doc_document.doc_document_id%type)
    is
      select   POS.C_POS_CREATE_MODE
             , STM_FUNCTIONS.GetPeriodExerciseId(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) ) STM_EXERCISE_ID
             , STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) STM_PERIOD_ID
             , SMO.STM_MOVEMENT_KIND_ID
             , SMO.STM_STOCK_ID
             , SMO.GCO_GOOD_ID
             , decode(GAR.GAR_TRANSFERT_MOVEMENT_DATE, 1, SMO.STM_STOCK_MOVEMENT_ID, null) SMO_MOVEMENT_ORDER_KEY
             , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT), DMT.DMT_DATE_DOCUMENT) SMO_MOVEMENT_DATE
             , SMO.SMO_WORDING
             , PDE.PDE_MOVEMENT_QUANTITY +(nvl(PDE.PDE_BALANCE_QUANTITY_PARENT, 0) * POS.POS_CONVERT_FACTOR) PDE_QUANTITY
             , SMO.SMO_MOVEMENT_QUANTITY SMO_QUANTITY
             ,
               -- -LEAST(SMO.SMO_MOVEMENT_QUANTITY,PDE.PDE_MOVEMENT_QUANTITY) SMO_MOVEMENT_QUANTITY,
               SMO.SMO_MOVEMENT_PRICE
             , SMO.SMO_VALUE_DATE
             , PDE.PDE_MOVEMENT_DATE
             ,
               -- -LEAST(SMO.SMO_MOVEMENT_PRICE,PDE.PDE_MOVEMENT_VALUE) SMO_MOVEMENT_PRICE,
               -decode(GAP_VALUE_QUANTITY
                     , 0, PDE_FINAL_QUANTITY
                     , least(decode(sign(POS_FINAL_QUANTITY - POS_VALUE_QUANTITY)
                                  , 1, DOC_PRC_MOVEMENT.GetDocumentQty(POS.DOC_POSITION_ID
                                                                     , POS.POS_VALUE_QUANTITY
                                                                     , PDE.DOC_POSITION_DETAIL_ID
                                                                     , PDE.PDE_FINAL_QUANTITY
                                                                      )
                                  , PDE.PDE_FINAL_QUANTITY
                                   )
                           , SMO.SMO_DOCUMENT_QUANTITY
                            )
                      ) SMO_DOCUMENT_QUANTITY
             , -decode(GAP_VALUE_QUANTITY
                     , 0, PDE_FINAL_QUANTITY *(SMO.SMO_DOCUMENT_PRICE / decode(SMO.SMO_DOCUMENT_QUANTITY, 0, 1, SMO.SMO_DOCUMENT_QUANTITY) )
                     , least(decode(sign(POS_FINAL_QUANTITY - POS_VALUE_QUANTITY)
                                  , 1, DOC_PRC_MOVEMENT.GetDocumentQty(POS.DOC_POSITION_ID
                                                                     , POS.POS_VALUE_QUANTITY
                                                                     , PDE.DOC_POSITION_DETAIL_ID
                                                                     , PDE.PDE_FINAL_QUANTITY
                                                                      )
                                  , PDE.PDE_FINAL_QUANTITY
                                   )
                           , SMO.SMO_DOCUMENT_QUANTITY
                            ) *
                       (SMO_DOCUMENT_PRICE / decode(SMO_DOCUMENT_QUANTITY, 0, 1, SMO_DOCUMENT_QUANTITY) )
                      ) SMO_DOCUMENT_PRICE
             , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_1, 1, PDT.PDT_CONVERSION_FACTOR_1 * PDE.PDE_MOVEMENT_QUANTITY, 0) PDT_ALTERNATIVE_QUANTITY_1
             , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_2, 1, PDT.PDT_CONVERSION_FACTOR_2 * PDE.PDE_MOVEMENT_QUANTITY, 0) PDT_ALTERNATIVE_QUANTITY_2
             , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_3, 1, PDT.PDT_CONVERSION_FACTOR_3 * PDE.PDE_MOVEMENT_QUANTITY, 0) PDT_ALTERNATIVE_QUANTITY_3
             , SMO.SMO_REFERENCE_UNIT_PRICE
             , SMO.SMO_UNIT_PRICE
             , SMO.SMO_FINANCIAL_CHARGING
             , sysdate A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
             , PDE.DOC_POSITION_DETAIL_ID
             , SMO.DOC_POSITION_ID
             , SMO.STM_LOCATION_ID
             , SMO.PAC_THIRD_ID
             , SMO.PAC_THIRD_ACI_ID
             , SMO.PAC_THIRD_DELIVERY_ID
             , SMO.PAC_THIRD_TARIFF_ID
             , SMO.DOC_RECORD_ID
             , SMO.GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_1, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_1, SMO.SMO_CHARACTERIZATION_VALUE_1) SMO_CHARACTERIZATION_VALUE_1
             , SMO.GCO_GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_2, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_2, SMO.SMO_CHARACTERIZATION_VALUE_2) SMO_CHARACTERIZATION_VALUE_2
             , SMO.GCO2_GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_3, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_3, SMO.SMO_CHARACTERIZATION_VALUE_3) SMO_CHARACTERIZATION_VALUE_3
             , SMO.GCO3_GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_4, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_4, SMO.SMO_CHARACTERIZATION_VALUE_4) SMO_CHARACTERIZATION_VALUE_4
             , SMO.GCO4_GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_5, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_5, SMO.SMO_CHARACTERIZATION_VALUE_5) SMO_CHARACTERIZATION_VALUE_5
             , SMO.ACS_FINANCIAL_ACCOUNT_ID
             , SMO.ACS_DIVISION_ACCOUNT_ID
             , SMO.ACS_ACS_FINANCIAL_ACCOUNT_ID
             , SMO.ACS_ACS_DIVISION_ACCOUNT_ID
             , SMO.ACS_CPN_ACCOUNT_ID
             , SMO.ACS_ACS_CPN_ACCOUNT_ID
             , SMO.ACS_CDA_ACCOUNT_ID
             , SMO.ACS_ACS_CDA_ACCOUNT_ID
             , SMO.ACS_PF_ACCOUNT_ID
             , SMO.ACS_ACS_PF_ACCOUNT_ID
             , SMO.ACS_PJ_ACCOUNT_ID
             , SMO.ACS_ACS_PJ_ACCOUNT_ID
             , SMO.FAM_FIXED_ASSETS_ID
             , SMO.C_FAM_TRANSACTION_TYP
             , SMO.HRM_PERSON_ID
             , SMO.DIC_IMP_FREE1_ID
             , SMO.DIC_IMP_FREE2_ID
             , SMO.DIC_IMP_FREE3_ID
             , SMO.DIC_IMP_FREE4_ID
             , SMO.DIC_IMP_FREE5_ID
             , SMO.SMO_IMP_TEXT_1
             , SMO.SMO_IMP_TEXT_2
             , SMO.SMO_IMP_TEXT_3
             , SMO.SMO_IMP_TEXT_4
             , SMO.SMO_IMP_TEXT_5
             , SMO.SMO_IMP_NUMBER_1
             , SMO.SMO_IMP_NUMBER_2
             , SMO.SMO_IMP_NUMBER_3
             , SMO.SMO_IMP_NUMBER_4
             , SMO.SMO_IMP_NUMBER_5
             , 1 SMO_EXTOURNE_MVT
             , 1 A_RECSTATUS
          from STM_STOCK_MOVEMENT SMO
             , DOC_POSITION_DETAIL PDE
             , DOC_POSITION POS
             , STM_MOVEMENT_KIND MOK
             , DOC_DOCUMENT DMT
             , GCO_PRODUCT PDT
             , GCO_GOOD GOO
             , DOC_GAUGE_RECEIPT GAR
             , DOC_GAUGE_POSITION GAP
         where PDE.DOC_DOCUMENT_ID = iDocumentId
           and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and SMO.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID
           and SMO.STM_STM_STOCK_MOVEMENT_ID is null   /* Ne prend que les mouvements principaux */
           and MOK.STM_MOVEMENT_KIND_ID = SMO.STM_MOVEMENT_KIND_ID
           and GAR.DOC_GAUGE_RECEIPT_ID = PDE.DOC_GAUGE_RECEIPT_ID
           and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
           and GOO.GCO_GOOD_ID = POS.GCO_GOOD_ID
           and PDT.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
           and POS.POS_GENERATE_MOVEMENT = 0
           and GAR.GAR_EXTOURNE_MVT = 1
           and MOK.C_MOVEMENT_SORT = 'SOR'
           and nvl(SMO.SMO_EXTOURNE_MVT, 0) = 0
      order by POS.GCO_GOOD_ID
             , SMO.SMO_CHARACTERIZATION_VALUE_1
             , SMO.SMO_CHARACTERIZATION_VALUE_2
             , SMO.SMO_CHARACTERIZATION_VALUE_3
             , SMO.SMO_CHARACTERIZATION_VALUE_4
             , SMO.SMO_CHARACTERIZATION_VALUE_5
             , POS.POS_NUMBER;

    lStockMovementId  STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
    lMovementQuantity STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type;
    lMovementPrice    STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type;
  begin
    for tplExtourneOutput in lcurExtourneOutput(iDocumentId) loop
      /**
      * Initialisation des quantités et valeurs des mouvements à extourner.
      */
      if (abs(tplExtourneOutput.PDE_QUANTITY) = abs(tplExtourneOutput.SMO_QUANTITY) ) then
        /* Cas survenant lorsque le mouvement a été crée à la suite d'une décharge
           complète ou partielle avec solde du parent ou avec dépassement de quantité */
        lMovementQuantity  := -tplExtourneOutput.SMO_QUANTITY;
        lMovementPrice     := -tplExtourneOutput.SMO_MOVEMENT_PRICE;
      elsif(abs(tplExtourneOutput.PDE_QUANTITY) < abs(tplExtourneOutput.SMO_QUANTITY) ) then
        /* Cas survenant lorsque le mouvement a été crée à la suite d'une décharge
           partielle */
        lMovementQuantity  := -tplExtourneOutput.PDE_QUANTITY;
        lMovementPrice     := -tplExtourneOutput.SMO_UNIT_PRICE * tplExtourneOutput.PDE_QUANTITY;
      elsif(abs(tplExtourneOutput.PDE_QUANTITY) > abs(tplExtourneOutput.SMO_QUANTITY) ) then
        /* Cas en principe impossible */
        lMovementQuantity  := -tplExtourneOutput.SMO_QUANTITY;
        lMovementPrice     := -tplExtourneOutput.SMO_MOVEMENT_PRICE;
      end if;

      lStockMovementId  := null;
      -- extournes des mouvements de sortie
      STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => lStockMovementId
                                      , iGoodId                => tplExtourneOutput.GCO_GOOD_ID
                                      , iMovementKindId        => tplExtourneOutput.STM_MOVEMENT_KIND_ID
                                      , iExerciseId            => tplExtourneOutput.STM_EXERCISE_ID
                                      , iPeriodId              => tplExtourneOutput.STM_PERIOD_ID
                                      , iMvtDate               => tplExtourneOutput.SMO_MOVEMENT_DATE
                                      , iValueDate             => tplExtourneOutput.SMO_VALUE_DATE
                                      , iStockId               => tplExtourneOutput.STM_STOCK_ID
                                      , iLocationId            => tplExtourneOutput.STM_LOCATION_ID
                                      , iThirdId               => tplExtourneOutput.PAC_THIRD_ID
                                      , iThirdAciId            => tplExtourneOutput.PAC_THIRD_ACI_ID
                                      , iThirdDeliveryId       => tplExtourneOutput.PAC_THIRD_DELIVERY_ID
                                      , iThirdTariffId         => tplExtourneOutput.PAC_THIRD_TARIFF_ID
                                      , iRecordId              => tplExtourneOutput.DOC_RECORD_ID
                                      , iChar1Id               => tplExtourneOutput.GCO_CHARACTERIZATION_ID
                                      , iChar2Id               => tplExtourneOutput.GCO_GCO_CHARACTERIZATION_ID
                                      , iChar3Id               => tplExtourneOutput.GCO2_GCO_CHARACTERIZATION_ID
                                      , iChar4Id               => tplExtourneOutput.GCO3_GCO_CHARACTERIZATION_ID
                                      , iChar5Id               => tplExtourneOutput.GCO4_GCO_CHARACTERIZATION_ID
                                      , iCharValue1            => tplExtourneOutput.SMO_CHARACTERIZATION_VALUE_1
                                      , iCharValue2            => tplExtourneOutput.SMO_CHARACTERIZATION_VALUE_2
                                      , iCharValue3            => tplExtourneOutput.SMO_CHARACTERIZATION_VALUE_3
                                      , iCharValue4            => tplExtourneOutput.SMO_CHARACTERIZATION_VALUE_4
                                      , iCharValue5            => tplExtourneOutput.SMO_CHARACTERIZATION_VALUE_5
                                      , iMovement2Id           => null
                                      , iMovement3Id           => null
                                      , iWording               => tplExtourneOutput.SMO_WORDING
                                      , iExternalDocument      => null
                                      , iExternalPartner       => null
                                      , iMvtQty                => lMovementQuantity
                                      , iMvtPrice              => lMovementPrice
                                      , iDocQty                => tplExtourneOutput.SMO_DOCUMENT_QUANTITY
                                      , iDocPrice              => tplExtourneOutput.SMO_DOCUMENT_PRICE
                                      , iUnitPrice             => tplExtourneOutput.SMO_UNIT_PRICE
                                      , iRefUnitPrice          => tplExtourneOutput.SMO_REFERENCE_UNIT_PRICE
                                      , iAltQty1               => tplExtourneOutput.PDT_ALTERNATIVE_QUANTITY_1
                                      , iAltQty2               => tplExtourneOutput.PDT_ALTERNATIVE_QUANTITY_2
                                      , iAltQty3               => tplExtourneOutput.PDT_ALTERNATIVE_QUANTITY_3
                                      , iDocPositionDetailId   => tplExtourneOutput.DOC_POSITION_DETAIL_ID
                                      , iDocPositionId         => tplExtourneOutput.DOC_POSITION_ID
                                      , iFinancialAccountId    => tplExtourneOutput.ACS_FINANCIAL_ACCOUNT_ID
                                      , iDivisionAccountId     => tplExtourneOutput.ACS_DIVISION_ACCOUNT_ID
                                      , iAFinancialAccountId   => tplExtourneOutput.ACS_ACS_FINANCIAL_ACCOUNT_ID
                                      , iADivisionAccountId    => tplExtourneOutput.ACS_ACS_DIVISION_ACCOUNT_ID
                                      , iCPNAccountId          => tplExtourneOutput.ACS_CPN_ACCOUNT_ID
                                      , iACPNAccountId         => tplExtourneOutput.ACS_ACS_CPN_ACCOUNT_ID
                                      , iCDAAccountId          => tplExtourneOutput.ACS_CDA_ACCOUNT_ID
                                      , iACDAAccountId         => tplExtourneOutput.ACS_ACS_CDA_ACCOUNT_ID
                                      , iPFAccountId           => tplExtourneOutput.ACS_PF_ACCOUNT_ID
                                      , iAPFAccountId          => tplExtourneOutput.ACS_ACS_PF_ACCOUNT_ID
                                      , iPJAccountId           => tplExtourneOutput.ACS_PJ_ACCOUNT_ID
                                      , iAPJAccountId          => tplExtourneOutput.ACS_ACS_PJ_ACCOUNT_ID
                                      , iFamFixedAssetsId      => tplExtourneOutput.FAM_FIXED_ASSETS_ID
                                      , iFamTransactionTyp     => tplExtourneOutput.C_FAM_TRANSACTION_TYP
                                      , iHrmPersonId           => tplExtourneOutput.HRM_PERSON_ID
                                      , iDicImpfree1Id         => tplExtourneOutput.DIC_IMP_FREE1_ID
                                      , iDicImpfree2Id         => tplExtourneOutput.DIC_IMP_FREE2_ID
                                      , iDicImpfree3Id         => tplExtourneOutput.DIC_IMP_FREE3_ID
                                      , iDicImpfree4Id         => tplExtourneOutput.DIC_IMP_FREE4_ID
                                      , iDicImpfree5Id         => tplExtourneOutput.DIC_IMP_FREE5_ID
                                      , iImpText1              => tplExtourneOutput.SMO_IMP_TEXT_1
                                      , iImpText2              => tplExtourneOutput.SMO_IMP_TEXT_2
                                      , iImpText3              => tplExtourneOutput.SMO_IMP_TEXT_3
                                      , iImpText4              => tplExtourneOutput.SMO_IMP_TEXT_4
                                      , iImpText5              => tplExtourneOutput.SMO_IMP_TEXT_5
                                      , iImpNumber1            => tplExtourneOutput.SMO_IMP_NUMBER_1
                                      , iImpNumber2            => tplExtourneOutput.SMO_IMP_NUMBER_2
                                      , iImpNumber3            => tplExtourneOutput.SMO_IMP_NUMBER_3
                                      , iImpNumber4            => tplExtourneOutput.SMO_IMP_NUMBER_4
                                      , iImpNumber5            => tplExtourneOutput.SMO_IMP_NUMBER_5
                                      , iFinancialCharging     => tplExtourneOutput.SMO_FINANCIAL_CHARGING
                                      , iUpdateProv            => 1
                                      , iExtourneMvt           => 1
                                      , iRecStatus             => 1
                                      , iOrderKey              => tplExtourneOutput.SMO_MOVEMENT_ORDER_KEY
                                       );
    end loop;
  end DocExtourneOutputMovements;

  procedure DocMainMovements(iDocumentId in doc_document.doc_document_id%type, iWording in stm_stock_movement.smo_wording%type)
  is
    cursor lcurMainMovement(
      iDocumentId           doc_document.doc_document_id%type
    , iWording              stm_stock_movement.smo_wording%type
    , iReportMovementKindId stm_movement_kind.stm_movement_kind_id%type
    )
    is
      select   POS.C_POS_CREATE_MODE
             , STM_FUNCTIONS.GetPeriodExerciseId(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) ) STM_EXERCISE_ID
             , STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) STM_PERIOD_ID
             , case
                 when nvl(MOK.STM_STM_MOVEMENT_KIND_ID, 0) <> 0
                 and PDE.PDE_MOVEMENT_QUANTITY < 0 then MOK.STM_STM_MOVEMENT_KIND_ID
                 else POS.STM_MOVEMENT_KIND_ID
               end STM_MOVEMENT_KIND_ID
             , pde.STM_STOCK_MOVEMENT_ID
             ,
               /* Si le stock n'existe pas (LOC.STM_STOCK_ID), il s'agit d'un détail
                  de position sans emplacement et donc d'un bien sans gestion de stock. */
               decode(LOC.STM_STOCK_ID, null, POS.STM_STOCK_ID, LOC.STM_STOCK_ID) STM_STOCK_ID
             , POS.GCO_GOOD_ID
             , decode(GAR.GAR_TRANSFERT_MOVEMENT_DATE, 1, SMO.STM_STOCK_MOVEMENT_ID) SMO_MOVEMENT_ORDER_KEY
             , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT), DMT.DMT_DATE_DOCUMENT) SMO_MOVEMENT_DATE
             , PDE.PDE_MOVEMENT_DATE SMO_VALUE_DATE
             , nvl(iWording, DMT.DMT_NUMBER || decode(POS.POS_NUMBER, 0, null, null, null, ' / ') || to_char(POS.POS_NUMBER) ) SMO_WORDING
             , PDE.PDE_MOVEMENT_QUANTITY
             , PDE.PDE_MOVEMENT_VALUE
             , decode(GAP_VALUE_QUANTITY
                    , 0, PDE_FINAL_QUANTITY
                    , decode(sign(POS_FINAL_QUANTITY - POS_VALUE_QUANTITY)
                           , 1, DOC_PRC_MOVEMENT.GetDocumentQty(POS.DOC_POSITION_ID, POS.POS_VALUE_QUANTITY, PDE.DOC_POSITION_DETAIL_ID, PDE.PDE_FINAL_QUANTITY)
                           , PDE.PDE_FINAL_QUANTITY
                            )
                     ) SMO_DOCUMENT_QUANTITY
             , decode(GAP_VALUE_QUANTITY
                    , 0, PDE_FINAL_QUANTITY
                    , decode(sign(POS_FINAL_QUANTITY - POS_VALUE_QUANTITY)
                           , 1, DOC_PRC_MOVEMENT.GetDocumentQty(POS.DOC_POSITION_ID, POS.POS_VALUE_QUANTITY, PDE.DOC_POSITION_DETAIL_ID, PDE.PDE_FINAL_QUANTITY)
                           , PDE.PDE_FINAL_QUANTITY
                            )
                     ) *
               POS_NET_UNIT_VALUE_INCL SMO_DOCUMENT_PRICE
             , decode(PDT.PDT_ALTERNATIVE_QUANTITY_1, 1, PDT.PDT_CONVERSION_FACTOR_1 * PDE.PDE_MOVEMENT_QUANTITY, 0) SMO_ALTERNATIVE_QUANTITY_1
             , decode(PDT.PDT_ALTERNATIVE_QUANTITY_2, 1, PDT.PDT_CONVERSION_FACTOR_2 * PDE.PDE_MOVEMENT_QUANTITY, 0) SMO_ALTERNATIVE_QUANTITY_2
             , decode(PDT.PDT_ALTERNATIVE_QUANTITY_3, 1, PDT.PDT_CONVERSION_FACTOR_3 * PDE.PDE_MOVEMENT_QUANTITY, 0) SMO_ALTERNATIVE_QUANTITY_3
             , POS.POS_REF_UNIT_VALUE SMO_REFERENCE_UNIT_PRICE
             , PDE_MOVEMENT_VALUE / ZVL(PDE_MOVEMENT_QUANTITY, ZVL(PDE_BASIS_QUANTITY_SU, 1) ) SMO_UNIT_PRICE
             , sign(MOK.MOK_FINANCIAL_IMPUTATION + MOK.MOK_ANAL_IMPUTATION) SMO_FINANCIAL_CHARGING
             , sysdate A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
             , PDE.DOC_POSITION_DETAIL_ID
             , PDE.DOC_POSITION_ID
             , PDE.STM_LOCATION_ID
             , DMT.PAC_THIRD_ID
             , DMT.PAC_THIRD_ACI_ID
             , DMT.PAC_THIRD_DELIVERY_ID
             , DMT.PAC_THIRD_TARIFF_ID
             , POS.DOC_RECORD_ID
             , PDE.GCO_CHARACTERIZATION_ID
             , PDE.PDE_CHARACTERIZATION_VALUE_1
             , PDE.GCO_GCO_CHARACTERIZATION_ID
             , PDE.PDE_CHARACTERIZATION_VALUE_2
             , PDE.GCO2_GCO_CHARACTERIZATION_ID
             , PDE.PDE_CHARACTERIZATION_VALUE_3
             , PDE.GCO3_GCO_CHARACTERIZATION_ID
             , PDE.PDE_CHARACTERIZATION_VALUE_4
             , PDE.GCO4_GCO_CHARACTERIZATION_ID
             , PDE.PDE_CHARACTERIZATION_VALUE_5
             , PDE.DOC2_DOC_POSITION_DETAIL_ID DOC_COPY_POSITION_DETAIL_ID
             , 2 A_RECSTATUS
             , DMT.DOC_DOCUMENT_ID
             , DMT.DMT_DATE_DOCUMENT
          from DOC_DOCUMENT DMT
             , DOC_POSITION POS
             , DOC_POSITION_DETAIL PDE
             , GCO_PRODUCT PDT
             , GCO_GOOD GOO
             , STM_MOVEMENT_KIND MOK
             , DOC_GAUGE_POSITION GAP
             , STM_LOCATION LOC
             , DOC_GAUGE_RECEIPT GAR
             , STM_STOCK_MOVEMENT SMO
         where POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
           and LOC.STM_LOCATION_ID(+) = PDE.STM_LOCATION_ID
           and GOO.GCO_GOOD_ID = POS.GCO_GOOD_ID
           and PDT.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
           and GAR.DOC_GAUGE_RECEIPT_ID(+) = PDE.DOC_GAUGE_RECEIPT_ID
           and SMO.DOC_POSITION_DETAIL_ID(+) = PDE.DOC_DOC_POSITION_DETAIL_ID
           and SMO.STM_STM_STOCK_MOVEMENT_ID(+) is null
           and not SMO.STM_MOVEMENT_KIND_ID(+) = iReportMovementKindId
           and nvl(SMO.SMO_EXTOURNE_MVT(+), 0) = 0
           and POS.POS_GENERATE_MOVEMENT = 0
           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and MOK.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID
           and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
           and PDE.DOC_DOCUMENT_ID = iDocumentId
      order by POS.GCO_GOOD_ID
             , PDE.PDE_CHARACTERIZATION_VALUE_1
             , PDE.PDE_CHARACTERIZATION_VALUE_2
             , PDE.PDE_CHARACTERIZATION_VALUE_3
             , PDE.PDE_CHARACTERIZATION_VALUE_4
             , PDE.PDE_CHARACTERIZATION_VALUE_5
             , POS.POS_NUMBER;

    lStockMovementId     STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
    lFinancialAccountID  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lDivisionAccountID   ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lCPNAccountID        ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lCDAAccountID        ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lPFAccountID         ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lPJAccountID         ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lFinancialAccountID2 ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lDivisionAccountID2  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lCPNAccountID2       ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lCDAAccountID2       ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lPFAccountID2        ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lPJAccountID2        ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lAccountInfo         ACS_LIB_LOGISTIC_FINANCIAL.tAccountInfo;
    lAccountInfo2        ACS_LIB_LOGISTIC_FINANCIAL.tAccountInfo;
    lnNewStockMovementId STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
  begin
    for ltplMainMovement in lcurMainMovement(iDocumentId, iWording, getReportMovementKindId) loop
      lStockMovementId                     := null;
      lFinancialAccountID                  := null;
      lDivisionAccountID                   := null;
      lCPNAccountID                        := null;
      lCDAAccountID                        := null;
      lPFAccountID                         := null;
      lPJAccountID                         := null;
      lFinancialAccountID2                 := null;
      lDivisionAccountID2                  := null;
      lCPNAccountID2                       := null;
      lCDAAccountID2                       := null;
      lPFAccountID2                        := null;
      lPJAccountID2                        := null;
      lAccountInfo.DEF_HRM_PERSON          := null;
      lAccountInfo.FAM_FIXED_ASSETS_ID     := null;
      lAccountInfo.C_FAM_TRANSACTION_TYP   := null;
      lAccountInfo.DEF_DIC_IMP_FREE1       := null;
      lAccountInfo.DEF_DIC_IMP_FREE2       := null;
      lAccountInfo.DEF_DIC_IMP_FREE3       := null;
      lAccountInfo.DEF_DIC_IMP_FREE4       := null;
      lAccountInfo.DEF_DIC_IMP_FREE5       := null;
      lAccountInfo.DEF_TEXT1               := null;
      lAccountInfo.DEF_TEXT2               := null;
      lAccountInfo.DEF_TEXT3               := null;
      lAccountInfo.DEF_TEXT4               := null;
      lAccountInfo.DEF_TEXT5               := null;
      lAccountInfo.DEF_NUMBER1             := null;
      lAccountInfo.DEF_NUMBER2             := null;
      lAccountInfo.DEF_NUMBER3             := null;
      lAccountInfo.DEF_NUMBER4             := null;
      lAccountInfo.DEF_NUMBER5             := null;
      lAccountInfo2.DEF_HRM_PERSON         := null;
      lAccountInfo2.FAM_FIXED_ASSETS_ID    := null;
      lAccountInfo2.C_FAM_TRANSACTION_TYP  := null;
      lAccountInfo2.DEF_DIC_IMP_FREE1      := null;
      lAccountInfo2.DEF_DIC_IMP_FREE2      := null;
      lAccountInfo2.DEF_DIC_IMP_FREE3      := null;
      lAccountInfo2.DEF_DIC_IMP_FREE4      := null;
      lAccountInfo2.DEF_DIC_IMP_FREE5      := null;
      lAccountInfo2.DEF_TEXT1              := null;
      lAccountInfo2.DEF_TEXT2              := null;
      lAccountInfo2.DEF_TEXT3              := null;
      lAccountInfo2.DEF_TEXT4              := null;
      lAccountInfo2.DEF_TEXT5              := null;
      lAccountInfo2.DEF_NUMBER1            := null;
      lAccountInfo2.DEF_NUMBER2            := null;
      lAccountInfo2.DEF_NUMBER3            := null;
      lAccountInfo2.DEF_NUMBER4            := null;
      lAccountInfo2.DEF_NUMBER5            := null;

      /*
      raise_application_error(-20001,
       lFinancialAccountID            || chr(13) ||
       lDivisionAccountID             || chr(13) ||
       lCPNAccountID                  || chr(13) ||
       lCDAAccountID                  || chr(13) ||
       lPFAccountID                   || chr(13) ||
       lPJAccountID                   || chr(13) ||
       lFinancialAccountID2           || chr(13) ||
       lDivisionAccountID2            || chr(13) ||
       lCPNAccountID2                 || chr(13) ||
       lCDAAccountID2                 || chr(13) ||
       lPFAccountID2                  || chr(13) ||
       lPJAccountID2                  || chr(13) ||
       lAccountInfo.DEF_HRM_PERSON    || chr(13) ||
       lAccountInfo.DEF_DIC_IMP_FREE1 || chr(13) ||
       lAccountInfo.DEF_DIC_IMP_FREE2 || chr(13) ||
       lAccountInfo.DEF_DIC_IMP_FREE3 || chr(13) ||
       lAccountInfo.DEF_DIC_IMP_FREE4 || chr(13) ||
       lAccountInfo.DEF_DIC_IMP_FREE5 || chr(13) ||
       lAccountInfo.DEF_TEXT1         || chr(13) ||
       lAccountInfo.DEF_TEXT2         || chr(13) ||
       lAccountInfo.DEF_TEXT3         || chr(13) ||
       lAccountInfo.DEF_TEXT4         || chr(13) ||
       lAccountInfo.DEF_TEXT5         || chr(13) ||
       lAccountInfo.DEF_NUMBER1       || chr(13) ||
       lAccountInfo.DEF_NUMBER2       || chr(13) ||
       lAccountInfo.DEF_NUMBER3       || chr(13) ||
       lAccountInfo.DEF_NUMBER4       || chr(13) ||
       lAccountInfo.DEF_NUMBER5);
      */
      if ltplMainMovement.C_POS_CREATE_MODE in('205', '206') then
        select SMO_MOVEMENT_ORDER_KEY
          into ltplMainMovement.SMO_MOVEMENT_ORDER_KEY
          from STM_STOCK_MOVEMENT
         where DOC_POSITION_DETAIL_ID = ltplMainMovement.DOC_COPY_POSITION_DETAIL_ID
           and STM_STM_STOCK_MOVEMENT_ID(+) is null
           and not STM_MOVEMENT_KIND_ID(+) = getReportMovementKindId
           and SMO_EXTOURNE_MVT = 0;
      end if;

      if ltplMainMovement.STM_STOCK_MOVEMENT_ID is not null then
        lnNewStockMovementId  := PCS.INIT_ID_SEQ.nextval;

        update DOC_POSITION_DETAIL
           set STM_STOCK_MOVEMENT_ID = lnNewStockMovementId
         where STM_STOCK_MOVEMENT_ID = ltplMainMovement.STM_STOCK_MOVEMENT_ID;

        update STM_TRANSFER_ATTRIB
           set STM_STOCK_MOVEMENT_ID = lnNewStockMovementId
         where STM_STOCK_MOVEMENT_ID = ltplMainMovement.STM_STOCK_MOVEMENT_ID;

        lStockMovementId      := lnNewStockMovementId;
      end if;

      STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => lStockMovementId
                                      , iGoodId                => ltplMainMovement.GCO_GOOD_ID
                                      , iMovementKindId        => ltplMainMovement.STM_MOVEMENT_KIND_ID
                                      , iExerciseId            => ltplMainMovement.STM_EXERCISE_ID
                                      , iPeriodId              => ltplMainMovement.STM_PERIOD_ID
                                      , iMvtDate               => ltplMainMovement.SMO_MOVEMENT_DATE
                                      , iValueDate             => ltplMainMovement.SMO_VALUE_DATE
                                      , iStockId               => ltplMainMovement.STM_STOCK_ID
                                      , iLocationId            => ltplMainMovement.STM_LOCATION_ID
                                      , iThirdId               => ltplMainMovement.PAC_THIRD_ID
                                      , iThirdAciId            => ltplMainMovement.PAC_THIRD_ACI_ID
                                      , iThirdDeliveryId       => ltplMainMovement.PAC_THIRD_DELIVERY_ID
                                      , iThirdTariffId         => ltplMainMovement.PAC_THIRD_TARIFF_ID
                                      , iRecordId              => ltplMainMovement.DOC_RECORD_ID
                                      , iChar1Id               => ltplMainMovement.GCO_CHARACTERIZATION_ID
                                      , iChar2Id               => ltplMainMovement.GCO_GCO_CHARACTERIZATION_ID
                                      , iChar3Id               => ltplMainMovement.GCO2_GCO_CHARACTERIZATION_ID
                                      , iChar4Id               => ltplMainMovement.GCO3_GCO_CHARACTERIZATION_ID
                                      , iChar5Id               => ltplMainMovement.GCO4_GCO_CHARACTERIZATION_ID
                                      , iCharValue1            => ltplMainMovement.PDE_CHARACTERIZATION_VALUE_1
                                      , iCharValue2            => ltplMainMovement.PDE_CHARACTERIZATION_VALUE_2
                                      , iCharValue3            => ltplMainMovement.PDE_CHARACTERIZATION_VALUE_3
                                      , iCharValue4            => ltplMainMovement.PDE_CHARACTERIZATION_VALUE_4
                                      , iCharValue5            => ltplMainMovement.PDE_CHARACTERIZATION_VALUE_5
                                      , iMovement2Id           => null   -- STM_STOCK_MOVEMENT.STM_STM_STOCK_MOVEMENT_ID%type,
                                      , iMovement3Id           => null   -- STM_STOCK_MOVEMENT.STM2_STM_STOCK_MOVEMENT_ID%type,
                                      , iWording               => ltplMainMovement.SMO_WORDING
                                      , iExternalDocument      => null   --STM_STOCK_MOVEMENT.SMO_EXTERNAL_DOCUMENT%type,
                                      , iExternalPartner       => null   --STM_STOCK_MOVEMENT.SMO_EXTERNAL_PARTNER%type,
                                      , iMvtQty                => ltplMainMovement.PDE_MOVEMENT_QUANTITY   -- STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type,
                                      , iMvtPrice              => ltplMainMovement.PDE_MOVEMENT_VALUE   -- STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type,
                                      , iDocQty                => ltplMainMovement.SMO_DOCUMENT_QUANTITY
                                      , iDocPrice              => ltplMainMovement.SMO_DOCUMENT_PRICE
                                      , iUnitPrice             => ltplMainMovement.SMO_UNIT_PRICE
                                      , iRefUnitPrice          => ltplMainMovement.SMO_REFERENCE_UNIT_PRICE
                                      , iAltQty1               => ltplMainMovement.SMO_ALTERNATIVE_QUANTITY_1
                                      , iAltQty2               => ltplMainMovement.SMO_ALTERNATIVE_QUANTITY_2
                                      , iAltQty3               => ltplMainMovement.SMO_ALTERNATIVE_QUANTITY_3
                                      , iDocPositionDetailId   => ltplMainMovement.DOC_POSITION_DETAIL_ID
                                      , iDocPositionId         => ltplMainMovement.DOC_POSITION_ID
                                      , iFinancialAccountId    => lFinancialAccountID   -- ACS_FINANCIAL_ACCOUNT_ID,
                                      , iDivisionAccountId     => lDivisionAccountID   -- ACS_DIVISION_ACCOUNT_ID,
                                      , iAFinancialAccountId   => lFinancialAccountID2   -- ACS_ACS_FINANCIAL_ACCOUNT_ID,
                                      , iADivisionAccountId    => lDivisionAccountID2   -- ACS_ACS_DIVISION_ACCOUNT_ID,
                                      , iCPNAccountId          => lCPNAccountID   -- ACS_CPN_ACCOUNT_ID,
                                      , iACPNAccountId         => lCPNAccountID2   -- ACS_ACS_CPN_ACCOUNT_ID,
                                      , iCDAAccountId          => lCDAAccountID   -- ACS_CDA_ACCOUNT_ID,
                                      , iACDAAccountId         => lCDAAccountID2   -- ACS_ACS_CDA_ACCOUNT_ID,
                                      , iPFAccountId           => lPFAccountID   -- ACS_PF_ACCOUNT_ID,
                                      , iAPFAccountId          => lPFAccountID2   -- ACS_ACS_PF_ACCOUNT_ID,
                                      , iPJAccountId           => lPJAccountID   -- ACS_PJ_ACCOUNT_ID,
                                      , iAPJAccountId          => lPJAccountID2   -- ACS_ACS_PJ_ACCOUNT_ID,
                                      , iFamFixedAssetsId      => lAccountInfo.FAM_FIXED_ASSETS_ID
                                      , iFamTransactionTyp     => lAccountInfo.C_FAM_TRANSACTION_TYP
                                      , iHrmPersonId           => ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(lAccountInfo.DEF_HRM_PERSON)
                                      , iDicImpfree1Id         => lAccountInfo.DEF_DIC_IMP_FREE1
                                      , iDicImpfree2Id         => lAccountInfo.DEF_DIC_IMP_FREE2
                                      , iDicImpfree3Id         => lAccountInfo.DEF_DIC_IMP_FREE3
                                      , iDicImpfree4Id         => lAccountInfo.DEF_DIC_IMP_FREE4
                                      , iDicImpfree5Id         => lAccountInfo.DEF_DIC_IMP_FREE5
                                      , iImpText1              => lAccountInfo.DEF_TEXT1
                                      , iImpText2              => lAccountInfo.DEF_TEXT2
                                      , iImpText3              => lAccountInfo.DEF_TEXT3
                                      , iImpText4              => lAccountInfo.DEF_TEXT4
                                      , iImpText5              => lAccountInfo.DEF_TEXT5
                                      , iImpNumber1            => to_number(lAccountInfo.DEF_NUMBER1)
                                      , iImpNumber2            => to_number(lAccountInfo.DEF_NUMBER2)
                                      , iImpNumber3            => to_number(lAccountInfo.DEF_NUMBER3)
                                      , iImpNumber4            => to_number(lAccountInfo.DEF_NUMBER4)
                                      , iImpNumber5            => to_number(lAccountInfo.DEF_NUMBER5)
                                      , iFinancialCharging     => ltplMainMovement.SMO_FINANCIAL_CHARGING
                                      , iUpdateProv            => 1   -- STM_STOCK_MOVEMENT.SMO_UPDATE_PROV%type,
                                      , iExtourneMvt           => 0   -- STM_STOCK_MOVEMENT.SMO_EXTOURNE_MVT%type,
                                      , iRecStatus             => 2   -- STM_STOCK_MOVEMENT.A_RECSTATUS%type
                                      , iOrderKey              => ltplMainMovement.SMO_MOVEMENT_ORDER_KEY
                                       );
    end loop;
  end DocMainMovements;

  procedure DocExtTransfertInputMovements(iDocumentId in doc_document.doc_document_id%type)
  is
    cursor lcurExtourneTransfertInput(iDocumentId doc_document.doc_document_id%type)
    is
      select   SMO.STM_STOCK_MOVEMENT_ID STM_STM_STOCK_MOVEMENT_ID
             , SMO2.STM_STOCK_MOVEMENT_ID STM2_STM_STOCK_MOVEMENT_ID
             , STM_FUNCTIONS.GetPeriodExerciseId(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) ) STM_EXERCISE_ID
             , STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) STM_PERIOD_ID
             , SMO.STM_MOVEMENT_KIND_ID
             , SMO.STM_STOCK_ID
             , SMO.GCO_GOOD_ID
             , decode(GAR.GAR_TRANSFERT_MOVEMENT_DATE, 1, SMO.STM_STOCK_MOVEMENT_ID, null) SMO_MOVEMENT_ORDER_KEY
             , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT), DMT.DMT_DATE_DOCUMENT) SMO_MOVEMENT_DATE
             , SMO.SMO_WORDING
             , PDE.PDE_MOVEMENT_QUANTITY +(nvl(PDE.PDE_BALANCE_QUANTITY_PARENT, 0) * POS.POS_CONVERT_FACTOR) PDE_QUANTITY
             , SMO.SMO_MOVEMENT_QUANTITY SMO_QUANTITY
             , SMO.SMO_MOVEMENT_PRICE
             , PDE.PDE_MOVEMENT_VALUE
             , PDE.PDE_MOVEMENT_DATE
             , -decode(GAP_VALUE_QUANTITY
                     , 0, PDE_FINAL_QUANTITY
                     , least(decode(sign(POS_FINAL_QUANTITY - POS_VALUE_QUANTITY)
                                  , 1, DOC_PRC_MOVEMENT.GetDocumentQty(POS.DOC_POSITION_ID
                                                                     , POS.POS_VALUE_QUANTITY
                                                                     , PDE.DOC_POSITION_DETAIL_ID
                                                                     , PDE.PDE_FINAL_QUANTITY
                                                                      )
                                  , PDE.PDE_FINAL_QUANTITY
                                   )
                           , SMO.SMO_DOCUMENT_QUANTITY
                            )
                      ) SMO_DOCUMENT_QUANTITY
             , -decode(GAP_VALUE_QUANTITY
                     , 0, PDE_FINAL_QUANTITY *(SMO.SMO_DOCUMENT_PRICE / decode(SMO.SMO_DOCUMENT_QUANTITY, 0, 1, SMO.SMO_DOCUMENT_QUANTITY) )
                     , least(decode(sign(POS_FINAL_QUANTITY - POS_VALUE_QUANTITY)
                                  , 1, DOC_PRC_MOVEMENT.GetDocumentQty(POS.DOC_POSITION_ID
                                                                     , POS.POS_VALUE_QUANTITY
                                                                     , PDE.DOC_POSITION_DETAIL_ID
                                                                     , PDE.PDE_FINAL_QUANTITY
                                                                      )
                                  , PDE.PDE_FINAL_QUANTITY
                                   )
                           , SMO.SMO_DOCUMENT_QUANTITY
                            ) *
                       (SMO.SMO_DOCUMENT_PRICE / decode(SMO.SMO_DOCUMENT_QUANTITY, 0, 1, SMO.SMO_DOCUMENT_QUANTITY) )
                      ) SMO_DOCUMENT_PRICE
             , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_1, 1, PDT.PDT_CONVERSION_FACTOR_1 * PDE.PDE_MOVEMENT_QUANTITY, 0) PDT_ALTERNATIVE_QUANTITY_1
             , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_2, 1, PDT.PDT_CONVERSION_FACTOR_2 * PDE.PDE_MOVEMENT_QUANTITY, 0) PDT_ALTERNATIVE_QUANTITY_2
             , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_3, 1, PDT.PDT_CONVERSION_FACTOR_3 * PDE.PDE_MOVEMENT_QUANTITY, 0) PDT_ALTERNATIVE_QUANTITY_3
             , SMO.SMO_REFERENCE_UNIT_PRICE
             , SMO.SMO_UNIT_PRICE
             , SMO.SMO_FINANCIAL_CHARGING
             , sysdate A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
             , PDE.DOC_POSITION_DETAIL_ID
             , SMO.DOC_POSITION_ID
             , SMO.STM_LOCATION_ID
             , SMO.PAC_THIRD_ID
             , SMO.PAC_THIRD_ACI_ID
             , SMO.PAC_THIRD_DELIVERY_ID
             , SMO.PAC_THIRD_TARIFF_ID
             , SMO.DOC_RECORD_ID
             , SMO.GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_1, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_1, SMO.SMO_CHARACTERIZATION_VALUE_1) SMO_CHARACTERIZATION_VALUE_1
             , SMO.GCO_GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_2, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_2, SMO.SMO_CHARACTERIZATION_VALUE_2) SMO_CHARACTERIZATION_VALUE_2
             , SMO.GCO2_GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_3, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_3, SMO.SMO_CHARACTERIZATION_VALUE_3) SMO_CHARACTERIZATION_VALUE_3
             , SMO.GCO3_GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_4, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_4, SMO.SMO_CHARACTERIZATION_VALUE_4) SMO_CHARACTERIZATION_VALUE_4
             , SMO.GCO4_GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_5, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_5, SMO.SMO_CHARACTERIZATION_VALUE_5) SMO_CHARACTERIZATION_VALUE_5
             , SMO.ACS_FINANCIAL_ACCOUNT_ID
             , SMO.ACS_DIVISION_ACCOUNT_ID
             , SMO.ACS_ACS_FINANCIAL_ACCOUNT_ID
             , SMO.ACS_ACS_DIVISION_ACCOUNT_ID
             , SMO.ACS_CPN_ACCOUNT_ID
             , SMO.ACS_ACS_CPN_ACCOUNT_ID
             , SMO.ACS_CDA_ACCOUNT_ID
             , SMO.ACS_ACS_CDA_ACCOUNT_ID
             , SMO.ACS_PF_ACCOUNT_ID
             , SMO.ACS_ACS_PF_ACCOUNT_ID
             , SMO.ACS_PJ_ACCOUNT_ID
             , SMO.ACS_ACS_PJ_ACCOUNT_ID
             , SMO.FAM_FIXED_ASSETS_ID
             , SMO.C_FAM_TRANSACTION_TYP
             , SMO.HRM_PERSON_ID
             , SMO.DIC_IMP_FREE1_ID
             , SMO.DIC_IMP_FREE2_ID
             , SMO.DIC_IMP_FREE3_ID
             , SMO.DIC_IMP_FREE4_ID
             , SMO.DIC_IMP_FREE5_ID
             , SMO.SMO_IMP_TEXT_1
             , SMO.SMO_IMP_TEXT_2
             , SMO.SMO_IMP_TEXT_3
             , SMO.SMO_IMP_TEXT_4
             , SMO.SMO_IMP_TEXT_5
             , SMO.SMO_IMP_NUMBER_1
             , SMO.SMO_IMP_NUMBER_2
             , SMO.SMO_IMP_NUMBER_3
             , SMO.SMO_IMP_NUMBER_4
             , SMO.SMO_IMP_NUMBER_5
             , 1 SMO_EXTOURNE_MVT
             , 4 A_RECSTATUS
          from STM_STOCK_MOVEMENT SMO
             , STM_STOCK_MOVEMENT SMO2
             , DOC_POSITION_DETAIL PDE
             , DOC_POSITION POS
             , DOC_DOCUMENT DMT
             , STM_MOVEMENT_KIND MOK
             , DOC_GAUGE_RECEIPT GAR
             , DOC_GAUGE_POSITION GAP
             , GCO_PRODUCT PDT
             , GCO_GOOD GOO
         where PDE.DOC_DOCUMENT_ID = iDocumentId
           and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and SMO.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID
           and SMO.STM_STM_STOCK_MOVEMENT_ID is not null   /* Ne prend que les mouvements secondaires */
           and MOK.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID
           --AND MOK.STM_MOVEMENT_KIND_ID = SMO.STM_MOVEMENT_KIND_ID
           and SMO.STM_MOVEMENT_KIND_ID = MOK.STM_STM_MOVEMENT_KIND_ID
           and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
           and GAR.DOC_GAUGE_RECEIPT_ID = PDE.DOC_GAUGE_RECEIPT_ID
           and SMO2.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID
           and SMO2.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID
           and GOO.GCO_GOOD_ID = POS.GCO_GOOD_ID
           and PDT.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
           and nvl(MOK.STM_STM_MOVEMENT_KIND_ID, 0) <> 0
           and POS.POS_GENERATE_MOVEMENT = 0
           and GAR.GAR_EXTOURNE_MVT = 1
           and MOK.C_MOVEMENT_SORT = 'SOR'
           and nvl(SMO.SMO_EXTOURNE_MVT, 0) = 0
           and nvl(SMO2.SMO_EXTOURNE_MVT, 0) = 0
      order by POS.GCO_GOOD_ID
             , SMO.SMO_CHARACTERIZATION_VALUE_1
             , SMO.SMO_CHARACTERIZATION_VALUE_2
             , SMO.SMO_CHARACTERIZATION_VALUE_3
             , SMO.SMO_CHARACTERIZATION_VALUE_4
             , SMO.SMO_CHARACTERIZATION_VALUE_5
             , POS.POS_NUMBER;

    lStockMovementId  STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
    lMovementQuantity STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type;
    lMovementPrice    STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type;
  begin
    for tplExtourneTransfertInput in lcurExtourneTransfertInput(iDocumentId) loop
      /**
      * Initialisation des quantités et valeurs des mouvements à extourner.
      */
      if (abs(tplExtourneTransfertInput.PDE_QUANTITY) = abs(tplExtourneTransfertInput.SMO_QUANTITY) ) then
        /* Cas survenant lorsque le mouvement a été crée à la suite d'une décharge
           complète ou partielle avec solde du parent ou avec dépassement de quantité */
        lMovementQuantity  := -tplExtourneTransfertInput.SMO_QUANTITY;
        lMovementPrice     := -tplExtourneTransfertInput.SMO_MOVEMENT_PRICE;
      elsif(abs(tplExtourneTransfertInput.PDE_QUANTITY) < abs(tplExtourneTransfertInput.SMO_QUANTITY) ) then
        /* Cas survenant lorsque le mouvement a été crée à la suite d'une décharge
           partielle */
        lMovementQuantity  := -tplExtourneTransfertInput.PDE_QUANTITY;
        lMovementPrice     := -tplExtourneTransfertInput.SMO_UNIT_PRICE * tplExtourneTransfertInput.PDE_QUANTITY;
      elsif(abs(tplExtourneTransfertInput.PDE_QUANTITY) > abs(tplExtourneTransfertInput.SMO_QUANTITY) ) then
        /* Cas en principe impossible */
        lMovementQuantity  := -tplExtourneTransfertInput.SMO_QUANTITY;
        lMovementPrice     := -tplExtourneTransfertInput.SMO_MOVEMENT_PRICE;
      end if;

      lStockMovementId  := null;
      STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => lStockMovementId
                                      , iGoodId                => tplExtourneTransfertInput.GCO_GOOD_ID
                                      , iMovementKindId        => tplExtourneTransfertInput.STM_MOVEMENT_KIND_ID
                                      , iExerciseId            => tplExtourneTransfertInput.STM_EXERCISE_ID
                                      , iPeriodId              => tplExtourneTransfertInput.STM_PERIOD_ID
                                      , iMvtDate               => tplExtourneTransfertInput.SMO_MOVEMENT_DATE
                                      , iValueDate             => tplExtourneTransfertInput.PDE_MOVEMENT_DATE
                                      , iStockId               => tplExtourneTransfertInput.STM_STOCK_ID
                                      , iLocationId            => tplExtourneTransfertInput.STM_LOCATION_ID
                                      , iThirdId               => tplExtourneTransfertInput.PAC_THIRD_ID
                                      , iThirdAciId            => tplExtourneTransfertInput.PAC_THIRD_ACI_ID
                                      , iThirdDeliveryId       => tplExtourneTransfertInput.PAC_THIRD_DELIVERY_ID
                                      , iThirdTariffId         => tplExtourneTransfertInput.PAC_THIRD_TARIFF_ID
                                      , iRecordId              => tplExtourneTransfertInput.DOC_RECORD_ID
                                      , iChar1Id               => tplExtourneTransfertInput.GCO_CHARACTERIZATION_ID
                                      , iChar2Id               => tplExtourneTransfertInput.GCO_GCO_CHARACTERIZATION_ID
                                      , iChar3Id               => tplExtourneTransfertInput.GCO2_GCO_CHARACTERIZATION_ID
                                      , iChar4Id               => tplExtourneTransfertInput.GCO3_GCO_CHARACTERIZATION_ID
                                      , iChar5Id               => tplExtourneTransfertInput.GCO4_GCO_CHARACTERIZATION_ID
                                      , iCharValue1            => tplExtourneTransfertInput.SMO_CHARACTERIZATION_VALUE_1
                                      , iCharValue2            => tplExtourneTransfertInput.SMO_CHARACTERIZATION_VALUE_2
                                      , iCharValue3            => tplExtourneTransfertInput.SMO_CHARACTERIZATION_VALUE_3
                                      , iCharValue4            => tplExtourneTransfertInput.SMO_CHARACTERIZATION_VALUE_4
                                      , iCharValue5            => tplExtourneTransfertInput.SMO_CHARACTERIZATION_VALUE_5
                                      , iMovement2Id           => tplExtourneTransfertInput.STM_STM_STOCK_MOVEMENT_ID
                                      , iMovement3Id           => tplExtourneTransfertInput.STM2_STM_STOCK_MOVEMENT_ID
                                      , iWording               => tplExtourneTransfertInput.SMO_WORDING
                                      , iExternalDocument      => null   --STM_STOCK_MOVEMENT.SMO_EXTERNAL_DOCUMENT%type,
                                      , iExternalPartner       => null   --STM_STOCK_MOVEMENT.SMO_EXTERNAL_PARTNER%type,
                                      , iMvtQty                => lMovementQuantity   -- STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type,
                                      , iMvtPrice              => lMovementPrice   -- STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type,
                                      , iDocQty                => tplExtourneTransfertInput.SMO_DOCUMENT_QUANTITY
                                      , iDocPrice              => tplExtourneTransfertInput.SMO_DOCUMENT_PRICE
                                      , iUnitPrice             => tplExtourneTransfertInput.SMO_UNIT_PRICE
                                      , iRefUnitPrice          => tplExtourneTransfertInput.SMO_REFERENCE_UNIT_PRICE
                                      , iAltQty1               => tplExtourneTransfertInput.PDT_ALTERNATIVE_QUANTITY_1
                                      , iAltQty2               => tplExtourneTransfertInput.PDT_ALTERNATIVE_QUANTITY_2
                                      , iAltQty3               => tplExtourneTransfertInput.PDT_ALTERNATIVE_QUANTITY_3
                                      , iDocPositionDetailId   => tplExtourneTransfertInput.DOC_POSITION_DETAIL_ID
                                      , iDocPositionId         => tplExtourneTransfertInput.DOC_POSITION_ID
                                      , iFinancialAccountId    => tplExtourneTransfertInput.ACS_FINANCIAL_ACCOUNT_ID
                                      , iDivisionAccountId     => tplExtourneTransfertInput.ACS_DIVISION_ACCOUNT_ID
                                      , iAFinancialAccountId   => tplExtourneTransfertInput.ACS_ACS_FINANCIAL_ACCOUNT_ID
                                      , iADivisionAccountId    => tplExtourneTransfertInput.ACS_ACS_DIVISION_ACCOUNT_ID
                                      , iCPNAccountId          => tplExtourneTransfertInput.ACS_CPN_ACCOUNT_ID
                                      , iaCPNAccountId         => tplExtourneTransfertInput.ACS_ACS_CPN_ACCOUNT_ID
                                      , iCDAAccountId          => tplExtourneTransfertInput.ACS_CDA_ACCOUNT_ID
                                      , iACDAAccountId         => tplExtourneTransfertInput.ACS_ACS_CDA_ACCOUNT_ID
                                      , iPFAccountId           => tplExtourneTransfertInput.ACS_PF_ACCOUNT_ID
                                      , iAPFAccountId          => tplExtourneTransfertInput.ACS_ACS_PF_ACCOUNT_ID
                                      , iPJAccountId           => tplExtourneTransfertInput.ACS_PJ_ACCOUNT_ID
                                      , iAPJAccountId          => tplExtourneTransfertInput.ACS_ACS_PJ_ACCOUNT_ID
                                      , iFamFixedAssetsId      => tplExtourneTransfertInput.FAM_FIXED_ASSETS_ID
                                      , iFamTransactionTyp     => tplExtourneTransfertInput.C_FAM_TRANSACTION_TYP
                                      , iHrmPersonId           => tplExtourneTransfertInput.HRM_PERSON_ID
                                      , iDicImpfree1Id         => tplExtourneTransfertInput.DIC_IMP_FREE1_ID
                                      , iDicImpfree2Id         => tplExtourneTransfertInput.DIC_IMP_FREE2_ID
                                      , iDicImpfree3Id         => tplExtourneTransfertInput.DIC_IMP_FREE3_ID
                                      , iDicImpfree4Id         => tplExtourneTransfertInput.DIC_IMP_FREE4_ID
                                      , iDicImpfree5Id         => tplExtourneTransfertInput.DIC_IMP_FREE5_ID
                                      , iImpText1              => tplExtourneTransfertInput.SMO_IMP_TEXT_1
                                      , iImpText2              => tplExtourneTransfertInput.SMO_IMP_TEXT_2
                                      , iImpText3              => tplExtourneTransfertInput.SMO_IMP_TEXT_3
                                      , iImpText4              => tplExtourneTransfertInput.SMO_IMP_TEXT_4
                                      , iImpText5              => tplExtourneTransfertInput.SMO_IMP_TEXT_5
                                      , iImpNumber1            => tplExtourneTransfertInput.SMO_IMP_NUMBER_1
                                      , iImpNumber2            => tplExtourneTransfertInput.SMO_IMP_NUMBER_2
                                      , iImpNumber3            => tplExtourneTransfertInput.SMO_IMP_NUMBER_3
                                      , iImpNumber4            => tplExtourneTransfertInput.SMO_IMP_NUMBER_4
                                      , iImpNumber5            => tplExtourneTransfertInput.SMO_IMP_NUMBER_5
                                      , iFinancialCharging     => tplExtourneTransfertInput.SMO_FINANCIAL_CHARGING
                                      , iUpdateProv            => 1   -- STM_STOCK_MOVEMENT.SMO_UPDATE_PROV%type,
                                      , iExtourneMvt           => 1   -- STM_STOCK_MOVEMENT.SMO_EXTOURNE_MVT%type,
                                      , iRecStatus             => 4   -- STM_STOCK_MOVEMENT.A_RECSTATUS%type
                                      , iOrderKey              => tplExtourneTransfertInput.SMO_MOVEMENT_ORDER_KEY
                                       );
    end loop;
  end DocExtTransfertInputMovements;

  procedure DocExtourneInputMovements(iDocumentId in doc_document.doc_document_id%type)
  is
    cursor lcurExtourneInput(iDocumentId doc_document.doc_document_id%type, iReportMovementKindId stm_movement_kind.stm_movement_kind_id%type)
    is
      select   STM_FUNCTIONS.GetPeriodExerciseId(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) ) STM_EXERCISE_ID
             , STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) STM_PERIOD_ID
             , SMO.STM_MOVEMENT_KIND_ID
             , SMO.STM_STOCK_ID
             , SMO.GCO_GOOD_ID
             , decode(GAR.GAR_TRANSFERT_MOVEMENT_DATE, 1, SMO.STM_STOCK_MOVEMENT_ID, null) SMO_MOVEMENT_ORDER_KEY
             , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT), DMT.DMT_DATE_DOCUMENT) SMO_MOVEMENT_DATE
             , PDE.PDE_MOVEMENT_DATE SMO_VALUE_DATE
             , SMO.SMO_WORDING
             , PDE.PDE_MOVEMENT_QUANTITY +(nvl(PDE.PDE_BALANCE_QUANTITY_PARENT, 0) * POS.POS_CONVERT_FACTOR) PDE_QUANTITY
             , SMO.SMO_MOVEMENT_QUANTITY SMO_QUANTITY
             ,
               -- -LEAST(SMO.SMO_MOVEMENT_QUANTITY,PDE.PDE_MOVEMENT_QUANTITY) SMO_MOVEMENT_QUANTITY,
               SMO.SMO_MOVEMENT_PRICE
             , PDE.PDE_MOVEMENT_VALUE
             ,
               -- -LEAST(SMO.SMO_MOVEMENT_PRICE,PDE.PDE_MOVEMENT_VALUE) SMO_MOVEMENT_PRICE,
               -decode(GAP_VALUE_QUANTITY
                     , 0, PDE_FINAL_QUANTITY
                     , least(decode(sign(POS_FINAL_QUANTITY - POS_VALUE_QUANTITY)
                                  , 1, DOC_PRC_MOVEMENT.GetDocumentQty(POS.DOC_POSITION_ID
                                                                     , POS.POS_VALUE_QUANTITY
                                                                     , PDE.DOC_POSITION_DETAIL_ID
                                                                     , PDE.PDE_FINAL_QUANTITY
                                                                      )
                                  , PDE.PDE_FINAL_QUANTITY
                                   )
                           , SMO.SMO_DOCUMENT_QUANTITY
                            )
                      ) SMO_DOCUMENT_QUANTITY
             , -decode(GAP_VALUE_QUANTITY
                     , 0, PDE_FINAL_QUANTITY *(SMO.SMO_DOCUMENT_PRICE / decode(SMO.SMO_DOCUMENT_QUANTITY, 0, 1, SMO.SMO_DOCUMENT_QUANTITY) )
                     , least(decode(sign(POS_FINAL_QUANTITY - POS_VALUE_QUANTITY)
                                  , 1, DOC_PRC_MOVEMENT.GetDocumentQty(POS.DOC_POSITION_ID
                                                                     , POS.POS_VALUE_QUANTITY
                                                                     , PDE.DOC_POSITION_DETAIL_ID
                                                                     , PDE.PDE_FINAL_QUANTITY
                                                                      )
                                  , PDE.PDE_FINAL_QUANTITY
                                   )
                           , SMO.SMO_DOCUMENT_QUANTITY
                            ) *
                       (SMO_DOCUMENT_PRICE / decode(SMO_DOCUMENT_QUANTITY, 0, 1, SMO_DOCUMENT_QUANTITY) )
                      ) SMO_DOCUMENT_PRICE
             , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_1, 1, PDT.PDT_CONVERSION_FACTOR_1 * PDE.PDE_MOVEMENT_QUANTITY, 0) PDT_ALTERNATIVE_QUANTITY_1
             , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_2, 1, PDT.PDT_CONVERSION_FACTOR_2 * PDE.PDE_MOVEMENT_QUANTITY, 0) PDT_ALTERNATIVE_QUANTITY_2
             , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_3, 1, PDT.PDT_CONVERSION_FACTOR_3 * PDE.PDE_MOVEMENT_QUANTITY, 0) PDT_ALTERNATIVE_QUANTITY_3
             , SMO.SMO_REFERENCE_UNIT_PRICE
             , SMO.SMO_UNIT_PRICE
             , SMO.SMO_FINANCIAL_CHARGING
             , sysdate A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
             , PDE.DOC_POSITION_DETAIL_ID
             , SMO.DOC_POSITION_ID
             , SMO.STM_LOCATION_ID
             , SMO.PAC_THIRD_ID
             , SMO.PAC_THIRD_ACI_ID
             , SMO.PAC_THIRD_DELIVERY_ID
             , SMO.PAC_THIRD_TARIFF_ID
             , SMO.DOC_RECORD_ID
             , SMO.GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_1, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_1, SMO.SMO_CHARACTERIZATION_VALUE_1) SMO_CHARACTERIZATION_VALUE_1
             , SMO.GCO_GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_2, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_2, SMO.SMO_CHARACTERIZATION_VALUE_2) SMO_CHARACTERIZATION_VALUE_2
             , SMO.GCO2_GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_3, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_3, SMO.SMO_CHARACTERIZATION_VALUE_3) SMO_CHARACTERIZATION_VALUE_3
             , SMO.GCO3_GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_4, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_4, SMO.SMO_CHARACTERIZATION_VALUE_4) SMO_CHARACTERIZATION_VALUE_4
             , SMO.GCO4_GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_5, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_5, SMO.SMO_CHARACTERIZATION_VALUE_5) SMO_CHARACTERIZATION_VALUE_5
             , SMO.ACS_FINANCIAL_ACCOUNT_ID
             , SMO.ACS_DIVISION_ACCOUNT_ID
             , SMO.ACS_ACS_FINANCIAL_ACCOUNT_ID
             , SMO.ACS_ACS_DIVISION_ACCOUNT_ID
             , SMO.ACS_CPN_ACCOUNT_ID
             , SMO.ACS_ACS_CPN_ACCOUNT_ID
             , SMO.ACS_CDA_ACCOUNT_ID
             , SMO.ACS_ACS_CDA_ACCOUNT_ID
             , SMO.ACS_PF_ACCOUNT_ID
             , SMO.ACS_ACS_PF_ACCOUNT_ID
             , SMO.ACS_PJ_ACCOUNT_ID
             , SMO.ACS_ACS_PJ_ACCOUNT_ID
             , 1 SMO_EXTOURNE_MVT
             , 3 A_RECSTATUS
          from STM_STOCK_MOVEMENT SMO
             , DOC_POSITION_DETAIL PDE
             , DOC_POSITION POS
             , DOC_DOCUMENT DMT
             , STM_MOVEMENT_KIND MOK
             , GCO_PRODUCT PDT
             , GCO_GOOD GOO
             , DOC_GAUGE_RECEIPT GAR
             , DOC_GAUGE_POSITION GAP
         where PDE.DOC_DOCUMENT_ID = iDocumentId
           and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and SMO.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID
           and SMO.STM_STM_STOCK_MOVEMENT_ID is null   /* Ne prend que les mouvements principaux */
           and MOK.STM_MOVEMENT_KIND_ID = SMO.STM_MOVEMENT_KIND_ID
           and not MOK.STM_MOVEMENT_KIND_ID = iReportMovementKindId
           and GAR.DOC_GAUGE_RECEIPT_ID = PDE.DOC_GAUGE_RECEIPT_ID
           and GOO.GCO_GOOD_ID = POS.GCO_GOOD_ID
           and PDT.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
           and POS.POS_GENERATE_MOVEMENT = 0
           and GAR.GAR_EXTOURNE_MVT = 1
           and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
           and MOK.C_MOVEMENT_SORT = 'ENT'
           and nvl(SMO.SMO_EXTOURNE_MVT, 0) = 0
      order by POS.GCO_GOOD_ID
             , SMO.SMO_CHARACTERIZATION_VALUE_1
             , SMO.SMO_CHARACTERIZATION_VALUE_2
             , SMO.SMO_CHARACTERIZATION_VALUE_3
             , SMO.SMO_CHARACTERIZATION_VALUE_4
             , SMO.SMO_CHARACTERIZATION_VALUE_5
             , POS.POS_NUMBER;

    lStockMovementId  STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
    lMovementQuantity STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type;
    lMovementPrice    STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type;
  begin
    for tplExtourneInput in lcurExtourneInput(iDocumentId, getReportMovementKindId) loop
      /**
      * Initialisation des quantités et valeurs des mouvements à extourner.
      */
      if (abs(tplExtourneInput.PDE_QUANTITY) = abs(tplExtourneInput.SMO_QUANTITY) ) then
        /* Cas survenant lorsque le mouvement a été crée à la suite d'une décharge
           complète ou partielle avec solde du parent ou avec dépassement de quantité */
        lMovementQuantity  := -tplExtourneInput.SMO_QUANTITY;
        lMovementPrice     := -tplExtourneInput.SMO_MOVEMENT_PRICE;
      elsif(abs(tplExtourneInput.PDE_QUANTITY) < abs(tplExtourneInput.SMO_QUANTITY) ) then
        /* Cas survenant lorsque le mouvement a été crée à la suite d'une décharge
           partielle */
        lMovementQuantity  := -tplExtourneInput.PDE_QUANTITY;
        lMovementPrice     := -tplExtourneInput.SMO_UNIT_PRICE * tplExtourneInput.PDE_QUANTITY;
      elsif(abs(tplExtourneInput.PDE_QUANTITY) > abs(tplExtourneInput.SMO_QUANTITY) ) then
        /* Cas en principe impossible */
        lMovementQuantity  := -tplExtourneInput.SMO_QUANTITY;
        lMovementPrice     := -tplExtourneInput.SMO_MOVEMENT_PRICE;
      end if;

      lStockMovementId  := null;
      STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => lStockMovementId
                                      , iGoodId                => tplExtourneInput.GCO_GOOD_ID
                                      , iMovementKindId        => tplExtourneInput.STM_MOVEMENT_KIND_ID
                                      , iExerciseId            => tplExtourneInput.STM_EXERCISE_ID
                                      , iPeriodId              => tplExtourneInput.STM_PERIOD_ID
                                      , iMvtDate               => tplExtourneInput.SMO_MOVEMENT_DATE
                                      , iValueDate             => tplExtourneInput.SMO_VALUE_DATE
                                      , iStockId               => tplExtourneInput.STM_STOCK_ID
                                      , iLocationId            => tplExtourneInput.STM_LOCATION_ID
                                      , iThirdId               => tplExtourneInput.PAC_THIRD_ID
                                      , iThirdAciId            => tplExtourneInput.PAC_THIRD_ACI_ID
                                      , iThirdDeliveryId       => tplExtourneInput.PAC_THIRD_DELIVERY_ID
                                      , iThirdTariffId         => tplExtourneInput.PAC_THIRD_TARIFF_ID
                                      , iRecordId              => tplExtourneInput.DOC_RECORD_ID
                                      , iChar1Id               => tplExtourneInput.GCO_CHARACTERIZATION_ID
                                      , iChar2Id               => tplExtourneInput.GCO_GCO_CHARACTERIZATION_ID
                                      , iChar3Id               => tplExtourneInput.GCO2_GCO_CHARACTERIZATION_ID
                                      , iChar4Id               => tplExtourneInput.GCO3_GCO_CHARACTERIZATION_ID
                                      , iChar5Id               => tplExtourneInput.GCO4_GCO_CHARACTERIZATION_ID
                                      , iCharValue1            => tplExtourneInput.SMO_CHARACTERIZATION_VALUE_1
                                      , iCharValue2            => tplExtourneInput.SMO_CHARACTERIZATION_VALUE_2
                                      , iCharValue3            => tplExtourneInput.SMO_CHARACTERIZATION_VALUE_3
                                      , iCharValue4            => tplExtourneInput.SMO_CHARACTERIZATION_VALUE_4
                                      , iCharValue5            => tplExtourneInput.SMO_CHARACTERIZATION_VALUE_5
                                      , iMovement2Id           => null   -- STM_STOCK_MOVEMENT.STM_STM_STOCK_MOVEMENT_ID%type,
                                      , iMovement3Id           => null   -- STM_STOCK_MOVEMENT.STM2_STM_STOCK_MOVEMENT_ID%type,
                                      , iWording               => tplExtourneInput.SMO_WORDING
                                      , iExternalDocument      => null   --STM_STOCK_MOVEMENT.SMO_EXTERNAL_DOCUMENT%type,
                                      , iExternalPartner       => null   --STM_STOCK_MOVEMENT.SMO_EXTERNAL_PARTNER%type,
                                      , iMvtQty                => lMovementQuantity   -- STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type,
                                      , iMvtPrice              => lMovementPrice   -- STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type,
                                      , iDocQty                => tplExtourneInput.SMO_DOCUMENT_QUANTITY
                                      , iDocPrice              => tplExtourneInput.SMO_DOCUMENT_PRICE
                                      , iUnitPrice             => tplExtourneInput.SMO_UNIT_PRICE
                                      , iRefUnitPrice          => tplExtourneInput.SMO_REFERENCE_UNIT_PRICE
                                      , iAltQty1               => tplExtourneInput.PDT_ALTERNATIVE_QUANTITY_1
                                      , iAltQty2               => tplExtourneInput.PDT_ALTERNATIVE_QUANTITY_2
                                      , iAltQty3               => tplExtourneInput.PDT_ALTERNATIVE_QUANTITY_3
                                      , iDocPositionDetailId   => tplExtourneInput.DOC_POSITION_DETAIL_ID
                                      , iDocPositionId         => tplExtourneInput.DOC_POSITION_ID
                                      , iFinancialAccountId    => tplExtourneInput.ACS_FINANCIAL_ACCOUNT_ID
                                      , iDivisionAccountId     => tplExtourneInput.ACS_DIVISION_ACCOUNT_ID
                                      , iAFinancialAccountId   => tplExtourneInput.ACS_ACS_FINANCIAL_ACCOUNT_ID
                                      , iADivisionAccountId    => tplExtourneInput.ACS_ACS_DIVISION_ACCOUNT_ID
                                      , iCPNAccountId          => tplExtourneInput.ACS_CPN_ACCOUNT_ID
                                      , iACPNAccountId         => tplExtourneInput.ACS_ACS_CPN_ACCOUNT_ID
                                      , iCDAAccountId          => tplExtourneInput.ACS_CDA_ACCOUNT_ID
                                      , iACDAAccountId         => tplExtourneInput.ACS_ACS_CDA_ACCOUNT_ID
                                      , iPFAccountId           => tplExtourneInput.ACS_PF_ACCOUNT_ID
                                      , iAPFAccountId          => tplExtourneInput.ACS_ACS_PF_ACCOUNT_ID
                                      , iPJAccountId           => tplExtourneInput.ACS_PJ_ACCOUNT_ID
                                      , iAPJAccountId          => tplExtourneInput.ACS_ACS_PJ_ACCOUNT_ID
                                      , iFamFixedAssetsId      => null   -- iFamFixedAssetsId in STM_STOCK_MOVEMENT.FAM_FIXED_ASSETS_ID%type,
                                      , iFamTransactionTyp     => null   -- iFamTransactionTyp in STM_STOCK_MOVEMENT.C_FAM_TRANSACTION_TYP%type,
                                      , iHrmPersonId           => null   -- iHrmPersonId in STM_STOCK_MOVEMENT.HRM_PERSON_ID%type,
                                      , iDicImpfree1Id         => null   -- iDicImpfree1Id in STM_STOCK_MOVEMENT.DIC_IMP_FREE1_ID%type,
                                      , iDicImpfree2Id         => null   -- iDicImpfree2Id in STM_STOCK_MOVEMENT.DIC_IMP_FREE2_ID%type,
                                      , iDicImpfree3Id         => null   -- iDicImpfree3Id in STM_STOCK_MOVEMENT.DIC_IMP_FREE3_ID%type,
                                      , iDicImpfree4Id         => null   -- iDicImpfree4Id in STM_STOCK_MOVEMENT.DIC_IMP_FREE4_ID%type,
                                      , iDicImpfree5Id         => null   -- iDicImpfree5Id in STM_STOCK_MOVEMENT.DIC_IMP_FREE5_ID%type,
                                      , iImpText1              => null   -- iImpText1 in STM_STOCK_MOVEMENT.SMO_IMP_TEXT_1%type,
                                      , iImpText2              => null   -- iImpText2 in STM_STOCK_MOVEMENT.SMO_IMP_TEXT_2%type,
                                      , iImpText3              => null   -- iImpText3 in STM_STOCK_MOVEMENT.SMO_IMP_TEXT_3%type,
                                      , iImpText4              => null   -- iImpText4 in STM_STOCK_MOVEMENT.SMO_IMP_TEXT_4%type,
                                      , iImpText5              => null   -- iImpText5 in STM_STOCK_MOVEMENT.SMO_IMP_TEXT_5%type,
                                      , iImpNumber1            => null   -- iImpNumber1 in STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_1%type,
                                      , iImpNumber2            => null   -- iImpNumber2 in STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_2%type,
                                      , iImpNumber3            => null   -- iImpNumber3 in STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_3%type,
                                      , iImpNumber4            => null   -- iImpNumber4 in STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_4%type,
                                      , iImpNumber5            => null   -- iImpNumber5 in STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_5%type,
                                      , iFinancialCharging     => tplExtourneInput.SMO_FINANCIAL_CHARGING
                                      , iUpdateProv            => 1   -- STM_STOCK_MOVEMENT.SMO_UPDATE_PROV%type,
                                      , iExtourneMvt           => 1   -- STM_STOCK_MOVEMENT.SMO_EXTOURNE_MVT%type,
                                      , iRecStatus             => 3   -- STM_STOCK_MOVEMENT.A_RECSTATUS%type
                                      , iOrderKey              => tplExtourneInput.SMO_MOVEMENT_ORDER_KEY
                                       );
    end loop;
  end DocExtourneInputMovements;

  procedure DocExtTransfertOutputMovements(iDocumentId in doc_document.doc_document_id%type)
  is
    cursor lcurExtourneTransfertOutput(iDocumentId doc_document.doc_document_id%type, iReportMovementKindId stm_movement_kind.stm_movement_kind_id%type)
    is
      select   SMO.STM_STOCK_MOVEMENT_ID STM_STM_STOCK_MOVEMENT_ID
             ,
               --SMO2.STM_STOCK_MOVEMENT_ID STM2_STM_STOCK_MOVEMENT_ID,
               STM_FUNCTIONS.GetPeriodExerciseId(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) ) STM_EXERCISE_ID
             , STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) STM_PERIOD_ID
             , SMO.STM_MOVEMENT_KIND_ID
             , SMO.STM_STOCK_ID
             , SMO.GCO_GOOD_ID
             , decode(GAR.GAR_TRANSFERT_MOVEMENT_DATE, 1, SMO.STM_STOCK_MOVEMENT_ID, null) SMO_MOVEMENT_ORDER_KEY
             , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT), DMT.DMT_DATE_DOCUMENT) SMO_MOVEMENT_DATE
             , SMO.SMO_WORDING
             , PDE.PDE_MOVEMENT_QUANTITY +(nvl(PDE.PDE_BALANCE_QUANTITY_PARENT, 0) * POS.POS_CONVERT_FACTOR) PDE_QUANTITY
             , SMO.SMO_MOVEMENT_QUANTITY SMO_QUANTITY
             ,
               -- -LEAST(SMO.SMO_MOVEMENT_QUANTITY,PDE.PDE_MOVEMENT_QUANTITY) SMO_MOVEMENT_QUANTITY,
               SMO.SMO_MOVEMENT_PRICE
             , PDE.PDE_MOVEMENT_VALUE
             , PDE.PDE_MOVEMENT_DATE SMO_VALUE_DATE
             ,
               -- -LEAST(SMO.SMO_MOVEMENT_PRICE,PDE.PDE_MOVEMENT_VALUE) SMO_MOVEMENT_PRICE,
               -decode(GAP_VALUE_QUANTITY
                     , 0, PDE_FINAL_QUANTITY
                     , least(decode(sign(POS_FINAL_QUANTITY - POS_VALUE_QUANTITY)
                                  , 1, DOC_PRC_MOVEMENT.GetDocumentQty(POS.DOC_POSITION_ID
                                                                     , POS.POS_VALUE_QUANTITY
                                                                     , PDE.DOC_POSITION_DETAIL_ID
                                                                     , PDE.PDE_FINAL_QUANTITY
                                                                      )
                                  , PDE.PDE_FINAL_QUANTITY
                                   )
                           , SMO.SMO_DOCUMENT_QUANTITY
                            )
                      ) SMO_DOCUMENT_QUANTITY
             , -decode(GAP_VALUE_QUANTITY
                     , 0, PDE_FINAL_QUANTITY *(SMO.SMO_DOCUMENT_PRICE / decode(SMO.SMO_DOCUMENT_QUANTITY, 0, 1, SMO.SMO_DOCUMENT_QUANTITY) )
                     , least(decode(sign(POS_FINAL_QUANTITY - POS_VALUE_QUANTITY)
                                  , 1, DOC_PRC_MOVEMENT.GetDocumentQty(POS.DOC_POSITION_ID
                                                                     , POS.POS_VALUE_QUANTITY
                                                                     , PDE.DOC_POSITION_DETAIL_ID
                                                                     , PDE.PDE_FINAL_QUANTITY
                                                                      )
                                  , PDE.PDE_FINAL_QUANTITY
                                   )
                           , SMO.SMO_DOCUMENT_QUANTITY
                            ) *
                       (SMO.SMO_DOCUMENT_PRICE / decode(SMO.SMO_DOCUMENT_QUANTITY, 0, 1, SMO.SMO_DOCUMENT_QUANTITY) )
                      ) SMO_DOCUMENT_PRICE
             , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_1, 1, PDT.PDT_CONVERSION_FACTOR_1 * PDE.PDE_MOVEMENT_QUANTITY, 0) PDT_ALTERNATIVE_QUANTITY_1
             , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_2, 1, PDT.PDT_CONVERSION_FACTOR_2 * PDE.PDE_MOVEMENT_QUANTITY, 0) PDT_ALTERNATIVE_QUANTITY_2
             , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_3, 1, PDT.PDT_CONVERSION_FACTOR_3 * PDE.PDE_MOVEMENT_QUANTITY, 0) PDT_ALTERNATIVE_QUANTITY_3
             , SMO.SMO_REFERENCE_UNIT_PRICE
             , SMO.SMO_UNIT_PRICE
             , SMO.SMO_FINANCIAL_CHARGING
             , sysdate A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
             , PDE.DOC_POSITION_DETAIL_ID
             , SMO.DOC_POSITION_ID
             , SMO.STM_LOCATION_ID
             , SMO.PAC_THIRD_ID
             , SMO.PAC_THIRD_ACI_ID
             , SMO.PAC_THIRD_DELIVERY_ID
             , SMO.PAC_THIRD_TARIFF_ID
             , SMO.DOC_RECORD_ID
             , SMO.GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_1, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_1, SMO.SMO_CHARACTERIZATION_VALUE_1) SMO_CHARACTERIZATION_VALUE_1
             , SMO.GCO_GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_2, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_2, SMO.SMO_CHARACTERIZATION_VALUE_2) SMO_CHARACTERIZATION_VALUE_2
             , SMO.GCO2_GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_3, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_3, SMO.SMO_CHARACTERIZATION_VALUE_3) SMO_CHARACTERIZATION_VALUE_3
             , SMO.GCO3_GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_4, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_4, SMO.SMO_CHARACTERIZATION_VALUE_4) SMO_CHARACTERIZATION_VALUE_4
             , SMO.GCO4_GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_5, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_5, SMO.SMO_CHARACTERIZATION_VALUE_5) SMO_CHARACTERIZATION_VALUE_5
             , SMO.ACS_FINANCIAL_ACCOUNT_ID
             , SMO.ACS_DIVISION_ACCOUNT_ID
             , SMO.ACS_ACS_FINANCIAL_ACCOUNT_ID
             , SMO.ACS_ACS_DIVISION_ACCOUNT_ID
             , SMO.ACS_CPN_ACCOUNT_ID
             , SMO.ACS_ACS_CPN_ACCOUNT_ID
             , SMO.ACS_CDA_ACCOUNT_ID
             , SMO.ACS_ACS_CDA_ACCOUNT_ID
             , SMO.ACS_PF_ACCOUNT_ID
             , SMO.ACS_ACS_PF_ACCOUNT_ID
             , SMO.ACS_PJ_ACCOUNT_ID
             , SMO.ACS_ACS_PJ_ACCOUNT_ID
             , SMO.FAM_FIXED_ASSETS_ID
             , SMO.C_FAM_TRANSACTION_TYP
             , SMO.HRM_PERSON_ID
             , SMO.DIC_IMP_FREE1_ID
             , SMO.DIC_IMP_FREE2_ID
             , SMO.DIC_IMP_FREE3_ID
             , SMO.DIC_IMP_FREE4_ID
             , SMO.DIC_IMP_FREE5_ID
             , SMO.SMO_IMP_TEXT_1
             , SMO.SMO_IMP_TEXT_2
             , SMO.SMO_IMP_TEXT_3
             , SMO.SMO_IMP_TEXT_4
             , SMO.SMO_IMP_TEXT_5
             , SMO.SMO_IMP_NUMBER_1
             , SMO.SMO_IMP_NUMBER_2
             , SMO.SMO_IMP_NUMBER_3
             , SMO.SMO_IMP_NUMBER_4
             , SMO.SMO_IMP_NUMBER_5
             , 1 SMO_EXTOURNE_MVT
             , 6 A_RECSTATUS
          from STM_STOCK_MOVEMENT SMO
             , STM_STOCK_MOVEMENT SMO2
             , DOC_POSITION_DETAIL PDE
             , DOC_POSITION POS
             , DOC_DOCUMENT DMT
             , DOC_GAUGE_POSITION GAP
             , STM_MOVEMENT_KIND MOK
             , DOC_GAUGE_RECEIPT GAR
             , GCO_PRODUCT PDT
             , GCO_GOOD GOO
         where PDE.DOC_DOCUMENT_ID = iDocumentId
           and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and SMO.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID
           and SMO.STM_STM_STOCK_MOVEMENT_ID is not null   /* Ne prend que les mouvements secondaires */
           and MOK.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID
           and SMO.STM_MOVEMENT_KIND_ID = MOK.STM_STM_MOVEMENT_KIND_ID
           and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
           and GAR.DOC_GAUGE_RECEIPT_ID = PDE.DOC_GAUGE_RECEIPT_ID
           and SMO2.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID
           and SMO2.STM_MOVEMENT_KIND_ID = MOK.STM_MOVEMENT_KIND_ID
           and GOO.GCO_GOOD_ID = POS.GCO_GOOD_ID
           and PDT.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
           and nvl(MOK.STM_STM_MOVEMENT_KIND_ID, 0) <> 0
           --AND NOT MOK.STM_MOVEMENT_KIND_ID = iReportMovementKindId
           and POS.POS_GENERATE_MOVEMENT = 0
           and GAR.GAR_EXTOURNE_MVT = 1
           and MOK.C_MOVEMENT_SORT = 'ENT'
           and nvl(SMO.SMO_EXTOURNE_MVT, 0) = 0
           and nvl(SMO2.SMO_EXTOURNE_MVT, 0) = 0
      order by POS.GCO_GOOD_ID
             , SMO.SMO_CHARACTERIZATION_VALUE_1
             , SMO.SMO_CHARACTERIZATION_VALUE_2
             , SMO.SMO_CHARACTERIZATION_VALUE_3
             , SMO.SMO_CHARACTERIZATION_VALUE_4
             , SMO.SMO_CHARACTERIZATION_VALUE_5
             , POS.POS_NUMBER;

    lStockMovementId  STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
    lMovementQuantity STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type;
    lMovementPrice    STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type;
  begin
    for tplExtourneTransfertOutput in lcurExtourneTransfertOutput(iDocumentId, getReportMovementKindId) loop
      /**
      * Initialisation des quantités et valeurs des mouvements à extourner.
      */
      if (abs(tplExtourneTransfertOutput.PDE_QUANTITY) = abs(tplExtourneTransfertOutput.SMO_QUANTITY) ) then
        /* Cas survenant lorsque le mouvement a été crée à la suite d'une décharge
           complète ou partielle avec solde du parent ou avec dépassement de quantité */
        lMovementQuantity  := -tplExtourneTransfertOutput.SMO_QUANTITY;
        lMovementPrice     := -tplExtourneTransfertOutput.SMO_MOVEMENT_PRICE;
      elsif(abs(tplExtourneTransfertOutput.PDE_QUANTITY) < abs(tplExtourneTransfertOutput.SMO_QUANTITY) ) then
        /* Cas survenant lorsque le mouvement a été crée à la suite d'une décharge
           partielle */
        lMovementQuantity  := -tplExtourneTransfertOutput.PDE_QUANTITY;
        lMovementPrice     := -tplExtourneTransfertOutput.SMO_UNIT_PRICE * tplExtourneTransfertOutput.PDE_QUANTITY;
      elsif(abs(tplExtourneTransfertOutput.PDE_QUANTITY) > abs(tplExtourneTransfertOutput.SMO_QUANTITY) ) then
        /* Cas en principe impossible */
        lMovementQuantity  := -tplExtourneTransfertOutput.SMO_QUANTITY;
        lMovementPrice     := -tplExtourneTransfertOutput.SMO_MOVEMENT_PRICE;
      end if;

      lStockMovementId  := null;
      STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => lStockMovementId
                                      , iGoodId                => tplExtourneTransfertOutput.GCO_GOOD_ID
                                      , iMovementKindId        => tplExtourneTransfertOutput.STM_MOVEMENT_KIND_ID
                                      , iExerciseId            => tplExtourneTransfertOutput.STM_EXERCISE_ID
                                      , iPeriodId              => tplExtourneTransfertOutput.STM_PERIOD_ID
                                      , iMvtDate               => tplExtourneTransfertOutput.SMO_MOVEMENT_DATE
                                      , iValueDate             => tplExtourneTransfertOutput.SMO_VALUE_DATE
                                      , iStockId               => tplExtourneTransfertOutput.STM_STOCK_ID
                                      , iLocationId            => tplExtourneTransfertOutput.STM_LOCATION_ID
                                      , iThirdId               => tplExtourneTransfertOutput.PAC_THIRD_ID
                                      , iThirdAciId            => tplExtourneTransfertOutput.PAC_THIRD_ACI_ID
                                      , iThirdDeliveryId       => tplExtourneTransfertOutput.PAC_THIRD_DELIVERY_ID
                                      , iThirdTariffId         => tplExtourneTransfertOutput.PAC_THIRD_TARIFF_ID
                                      , iRecordId              => tplExtourneTransfertOutput.DOC_RECORD_ID
                                      , iChar1Id               => tplExtourneTransfertOutput.GCO_CHARACTERIZATION_ID
                                      , iChar2Id               => tplExtourneTransfertOutput.GCO_GCO_CHARACTERIZATION_ID
                                      , iChar3Id               => tplExtourneTransfertOutput.GCO2_GCO_CHARACTERIZATION_ID
                                      , iChar4Id               => tplExtourneTransfertOutput.GCO3_GCO_CHARACTERIZATION_ID
                                      , iChar5Id               => tplExtourneTransfertOutput.GCO4_GCO_CHARACTERIZATION_ID
                                      , iCharValue1            => tplExtourneTransfertOutput.SMO_CHARACTERIZATION_VALUE_1
                                      , iCharValue2            => tplExtourneTransfertOutput.SMO_CHARACTERIZATION_VALUE_2
                                      , iCharValue3            => tplExtourneTransfertOutput.SMO_CHARACTERIZATION_VALUE_3
                                      , iCharValue4            => tplExtourneTransfertOutput.SMO_CHARACTERIZATION_VALUE_4
                                      , iCharValue5            => tplExtourneTransfertOutput.SMO_CHARACTERIZATION_VALUE_5
                                      , iMovement2Id           => tplExtourneTransfertOutput.STM_STM_STOCK_MOVEMENT_ID
                                      , iMovement3Id           => null   -- STM_STOCK_MOVEMENT.STM2_STM_STOCK_MOVEMENT_ID%type,
                                      , iWording               => tplExtourneTransfertOutput.SMO_WORDING
                                      , iExternalDocument      => null   --STM_STOCK_MOVEMENT.SMO_EXTERNAL_DOCUMENT%type,
                                      , iExternalPartner       => null   --STM_STOCK_MOVEMENT.SMO_EXTERNAL_PARTNER%type,
                                      , iMvtQty                => lMovementQuantity   -- STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type,
                                      , iMvtPrice              => lMovementPrice   -- STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type,
                                      , iDocQty                => tplExtourneTransfertOutput.SMO_DOCUMENT_QUANTITY
                                      , iDocPrice              => tplExtourneTransfertOutput.SMO_DOCUMENT_PRICE
                                      , iUnitPrice             => tplExtourneTransfertOutput.SMO_UNIT_PRICE
                                      , iRefUnitPrice          => tplExtourneTransfertOutput.SMO_REFERENCE_UNIT_PRICE
                                      , iAltQty1               => tplExtourneTransfertOutput.PDT_ALTERNATIVE_QUANTITY_1
                                      , iAltQty2               => tplExtourneTransfertOutput.PDT_ALTERNATIVE_QUANTITY_2
                                      , iAltQty3               => tplExtourneTransfertOutput.PDT_ALTERNATIVE_QUANTITY_3
                                      , iDocPositionDetailId   => tplExtourneTransfertOutput.DOC_POSITION_DETAIL_ID
                                      , iDocPositionId         => tplExtourneTransfertOutput.DOC_POSITION_ID
                                      , iFinancialAccountId    => tplExtourneTransfertOutput.ACS_FINANCIAL_ACCOUNT_ID
                                      , iDivisionAccountId     => tplExtourneTransfertOutput.ACS_DIVISION_ACCOUNT_ID
                                      , iAFinancialAccountId   => tplExtourneTransfertOutput.ACS_ACS_FINANCIAL_ACCOUNT_ID
                                      , iADivisionAccountId    => tplExtourneTransfertOutput.ACS_ACS_DIVISION_ACCOUNT_ID
                                      , iCPNAccountId          => tplExtourneTransfertOutput.ACS_CPN_ACCOUNT_ID
                                      , iACPNAccountId         => tplExtourneTransfertOutput.ACS_ACS_CPN_ACCOUNT_ID
                                      , iCDAAccountId          => tplExtourneTransfertOutput.ACS_CDA_ACCOUNT_ID
                                      , iACDAAccountId         => tplExtourneTransfertOutput.ACS_ACS_CDA_ACCOUNT_ID
                                      , iPFAccountId           => tplExtourneTransfertOutput.ACS_PF_ACCOUNT_ID
                                      , iAPFAccountId          => tplExtourneTransfertOutput.ACS_ACS_PF_ACCOUNT_ID
                                      , iPJAccountId           => tplExtourneTransfertOutput.ACS_PJ_ACCOUNT_ID
                                      , iAPJAccountId          => tplExtourneTransfertOutput.ACS_ACS_PJ_ACCOUNT_ID
                                      , iFamFixedAssetsId      => tplExtourneTransfertOutput.FAM_FIXED_ASSETS_ID
                                      , iFamTransactionTyp     => tplExtourneTransfertOutput.C_FAM_TRANSACTION_TYP
                                      , iHrmPersonId           => tplExtourneTransfertOutput.HRM_PERSON_ID
                                      , iDicImpfree1Id         => tplExtourneTransfertOutput.DIC_IMP_FREE1_ID
                                      , iDicImpfree2Id         => tplExtourneTransfertOutput.DIC_IMP_FREE2_ID
                                      , iDicImpfree3Id         => tplExtourneTransfertOutput.DIC_IMP_FREE3_ID
                                      , iDicImpfree4Id         => tplExtourneTransfertOutput.DIC_IMP_FREE4_ID
                                      , iDicImpfree5Id         => tplExtourneTransfertOutput.DIC_IMP_FREE5_ID
                                      , iImpText1              => tplExtourneTransfertOutput.SMO_IMP_TEXT_1
                                      , iImpText2              => tplExtourneTransfertOutput.SMO_IMP_TEXT_2
                                      , iImpText3              => tplExtourneTransfertOutput.SMO_IMP_TEXT_3
                                      , iImpText4              => tplExtourneTransfertOutput.SMO_IMP_TEXT_4
                                      , iImpText5              => tplExtourneTransfertOutput.SMO_IMP_TEXT_5
                                      , iImpNumber1            => tplExtourneTransfertOutput.SMO_IMP_NUMBER_1
                                      , iImpNumber2            => tplExtourneTransfertOutput.SMO_IMP_NUMBER_2
                                      , iImpNumber3            => tplExtourneTransfertOutput.SMO_IMP_NUMBER_3
                                      , iImpNumber4            => tplExtourneTransfertOutput.SMO_IMP_NUMBER_4
                                      , iImpNumber5            => tplExtourneTransfertOutput.SMO_IMP_NUMBER_5
                                      , iFinancialCharging     => tplExtourneTransfertOutput.SMO_FINANCIAL_CHARGING
                                      , iUpdateProv            => 1   -- STM_STOCK_MOVEMENT.SMO_UPDATE_PROV%type,
                                      , iExtourneMvt           => 1   -- STM_STOCK_MOVEMENT.SMO_EXTOURNE_MVT%type,
                                      , iRecStatus             => 6   -- STM_STOCK_MOVEMENT.A_RECSTATUS%type
                                      , iOrderKey              => tplExtourneTransfertOutput.SMO_MOVEMENT_ORDER_KEY
                                       );
    end loop;
  end DocExtTransfertOutputMovements;

  procedure DocTransfertMovements(iDocumentId in doc_document.doc_document_id%type, iWording in stm_stock_movement.smo_wording%type)
  is
    cursor lcurTransfert(
      iDocumentId           doc_document.doc_document_id%type
    , iWording              stm_stock_movement.smo_wording%type
    , iReportMovementKindId stm_movement_kind.stm_movement_kind_id%type
    )
    is
      select   POS.C_POS_CREATE_MODE
             , SMO.STM_STOCK_MOVEMENT_ID STM_STM_STOCK_MOVEMENT_ID
             , STM_FUNCTIONS.GetPeriodExerciseId(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) ) STM_EXERCISE_ID
             , STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) STM_PERIOD_ID
             , decode(sign(PDE.PDE_MOVEMENT_QUANTITY), -1, MOK.STM_MOVEMENT_KIND_ID, MOK.STM_STM_MOVEMENT_KIND_ID) STM_STM_MOVEMENT_KIND_ID
             ,
               /* Si le stock n'existe pas (LOC.STM_STOCK_ID), il s'agit d'un détail
                  de position sans emplacement et donc d'un bien sans gestion de stock. */
               decode(LOC.STM_STOCK_ID, null, POS.STM_STM_STOCK_ID, LOC.STM_STOCK_ID) STM_STM_STOCK_ID
             , POS.GCO_GOOD_ID
             , decode(GAR.GAR_TRANSFERT_MOVEMENT_DATE, 1, SMO2.STM_STOCK_MOVEMENT_ID) SMO_MOVEMENT_ORDER_KEY
             , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT), DMT.DMT_DATE_DOCUMENT) SMO_MOVEMENT_DATE
             , PDE.PDE_MOVEMENT_DATE SMO_VALUE_DATE
             , nvl(iWording, DMT.DMT_NUMBER || decode(POS.POS_NUMBER, 0, null, null, null, ' / ') || to_char(POS.POS_NUMBER) ) SMO_WORDING
             , PDE.PDE_MOVEMENT_QUANTITY
             , PDE.PDE_MOVEMENT_VALUE
             , decode(GAP_VALUE_QUANTITY
                    , 0, PDE_FINAL_QUANTITY
                    , decode(sign(POS_FINAL_QUANTITY - POS_VALUE_QUANTITY)
                           , 1, DOC_PRC_MOVEMENT.GetDocumentQty(POS.DOC_POSITION_ID, POS.POS_VALUE_QUANTITY, PDE.DOC_POSITION_DETAIL_ID, PDE.PDE_FINAL_QUANTITY)
                           , PDE.PDE_FINAL_QUANTITY
                            )
                     ) SMO_DOCUMENT_QUANTITY
             , decode(GAP_VALUE_QUANTITY
                    , 0, PDE_FINAL_QUANTITY
                    , decode(sign(POS_FINAL_QUANTITY - POS_VALUE_QUANTITY)
                           , 1, DOC_PRC_MOVEMENT.GetDocumentQty(POS.DOC_POSITION_ID, POS.POS_VALUE_QUANTITY, PDE.DOC_POSITION_DETAIL_ID, PDE.PDE_FINAL_QUANTITY)
                           , PDE.PDE_FINAL_QUANTITY
                            )
                     ) *
               POS_NET_UNIT_VALUE_INCL SMO_DOCUMENT_PRICE
             , decode(PDT.PDT_ALTERNATIVE_QUANTITY_1, 1, PDT.PDT_CONVERSION_FACTOR_1 * PDE.PDE_MOVEMENT_QUANTITY, 0) PDT_ALTERNATIVE_QUANTITY_1
             , decode(PDT.PDT_ALTERNATIVE_QUANTITY_2, 1, PDT.PDT_CONVERSION_FACTOR_2 * PDE.PDE_MOVEMENT_QUANTITY, 0) PDT_ALTERNATIVE_QUANTITY_2
             , decode(PDT.PDT_ALTERNATIVE_QUANTITY_3, 1, PDT.PDT_CONVERSION_FACTOR_3 * PDE.PDE_MOVEMENT_QUANTITY, 0) PDT_ALTERNATIVE_QUANTITY_3
             , POS.POS_REF_UNIT_VALUE SMO_REFERENCE_UNIT_PRICE
             , PDE_MOVEMENT_VALUE / ZVL(PDE_MOVEMENT_QUANTITY, ZVL(PDE_BASIS_QUANTITY_SU, 1) ) SMO_UNIT_PRICE
             , sign(MOK2.MOK_FINANCIAL_IMPUTATION + MOK2.MOK_ANAL_IMPUTATION) SMO_FINANCIAL_CHARGING
             , sysdate A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
             , PDE.DOC_POSITION_DETAIL_ID
             , PDE.DOC_POSITION_ID
             , PDE.STM_STM_LOCATION_ID
             , DMT.PAC_THIRD_ID
             , DMT.PAC_THIRD_ACI_ID
             , DMT.PAC_THIRD_DELIVERY_ID
             , DMT.PAC_THIRD_TARIFF_ID
             , POS.DOC_RECORD_ID
             , PDE.GCO_CHARACTERIZATION_ID
             , PDE.PDE_CHARACTERIZATION_VALUE_1
             , PDE.GCO_GCO_CHARACTERIZATION_ID
             , PDE.PDE_CHARACTERIZATION_VALUE_2
             , PDE.GCO2_GCO_CHARACTERIZATION_ID
             , PDE.PDE_CHARACTERIZATION_VALUE_3
             , PDE.GCO3_GCO_CHARACTERIZATION_ID
             , PDE.PDE_CHARACTERIZATION_VALUE_4
             , PDE.GCO4_GCO_CHARACTERIZATION_ID
             , PDE.PDE_CHARACTERIZATION_VALUE_5
             , PDE.DOC2_DOC_POSITION_DETAIL_ID DOC_COPY_POSITION_DETAIL_ID
             , 5 A_RECSTATUS
             , DMT.DOC_DOCUMENT_ID
             , DMT.DMT_DATE_DOCUMENT
          from DOC_DOCUMENT DMT
             , DOC_POSITION POS
             , DOC_POSITION_DETAIL PDE
             , GCO_PRODUCT PDT
             , GCO_GOOD GOO
             , DOC_GAUGE_POSITION GAP
             , DOC_GAUGE_RECEIPT GAR
             , STM_MOVEMENT_KIND MOK
             , STM_MOVEMENT_KIND MOK2
             , STM_STOCK_MOVEMENT SMO
             , STM_STOCK_MOVEMENT SMO2
             , STM_LOCATION LOC
         where POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
           and LOC.STM_LOCATION_ID(+) = PDE.STM_STM_LOCATION_ID
           and GOO.GCO_GOOD_ID = POS.GCO_GOOD_ID
           and PDT.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
           and POS.POS_GENERATE_MOVEMENT = 0
           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and MOK.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID
           and SMO.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
           and SMO.STM_MOVEMENT_KIND_ID = decode(sign(PDE.PDE_MOVEMENT_QUANTITY), -1, MOK.STM_STM_MOVEMENT_KIND_ID, MOK.STM_MOVEMENT_KIND_ID)
           and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
           and GAR.DOC_GAUGE_RECEIPT_ID(+) = PDE.DOC_GAUGE_RECEIPT_ID
           and SMO2.DOC_POSITION_DETAIL_ID(+) = PDE.DOC_DOC_POSITION_DETAIL_ID
           and SMO2.STM_STM_STOCK_MOVEMENT_ID(+) is not null
           and not SMO2.STM_MOVEMENT_KIND_ID(+) = iReportMovementKindId
           and MOK2.STM_MOVEMENT_KIND_ID = MOK.STM_STM_MOVEMENT_KIND_ID
           and not SMO.STM_MOVEMENT_KIND_ID = iReportMovementKindId
           and PDE.DOC_DOCUMENT_ID = iDocumentId
           and nvl(SMO.SMO_EXTOURNE_MVT, 0) = 0
      order by POS.GCO_GOOD_ID
             , SMO.SMO_CHARACTERIZATION_VALUE_1
             , SMO.SMO_CHARACTERIZATION_VALUE_2
             , SMO.SMO_CHARACTERIZATION_VALUE_3
             , SMO.SMO_CHARACTERIZATION_VALUE_4
             , SMO.SMO_CHARACTERIZATION_VALUE_5
             , POS.POS_NUMBER;

    lStockMovementId     STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
    lFinancialAccountID  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lDivisionAccountID   ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lCPNAccountID        ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lCDAAccountID        ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lPFAccountID         ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lPJAccountID         ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lFinancialAccountID2 ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lDivisionAccountID2  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lCPNAccountID2       ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lCDAAccountID2       ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lPFAccountID2        ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lPJAccountID2        ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    lAccountInfo         ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    lAccountInfo2        ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
  begin
    for tplTransfert in lcurTransfert(iDocumentId, iWording, getReportMovementKindId) loop
      lStockMovementId                     := null;
      lFinancialAccountID                  := null;
      lDivisionAccountID                   := null;
      lCPNAccountID                        := null;
      lCDAAccountID                        := null;
      lPFAccountID                         := null;
      lPJAccountID                         := null;
      lFinancialAccountID2                 := null;
      lDivisionAccountID2                  := null;
      lCPNAccountID2                       := null;
      lCDAAccountID2                       := null;
      lPFAccountID2                        := null;
      lPJAccountID2                        := null;
      lAccountInfo.DEF_HRM_PERSON          := null;
      lAccountInfo.FAM_FIXED_ASSETS_ID     := null;
      lAccountInfo.C_FAM_TRANSACTION_TYP   := null;
      lAccountInfo.DEF_DIC_IMP_FREE1       := null;
      lAccountInfo.DEF_DIC_IMP_FREE2       := null;
      lAccountInfo.DEF_DIC_IMP_FREE3       := null;
      lAccountInfo.DEF_DIC_IMP_FREE4       := null;
      lAccountInfo.DEF_DIC_IMP_FREE5       := null;
      lAccountInfo.DEF_TEXT1               := null;
      lAccountInfo.DEF_TEXT2               := null;
      lAccountInfo.DEF_TEXT3               := null;
      lAccountInfo.DEF_TEXT4               := null;
      lAccountInfo.DEF_TEXT5               := null;
      lAccountInfo.DEF_NUMBER1             := null;
      lAccountInfo.DEF_NUMBER2             := null;
      lAccountInfo.DEF_NUMBER3             := null;
      lAccountInfo.DEF_NUMBER4             := null;
      lAccountInfo.DEF_NUMBER5             := null;
      lAccountInfo2.DEF_HRM_PERSON         := null;
      lAccountInfo2.FAM_FIXED_ASSETS_ID    := null;
      lAccountInfo2.C_FAM_TRANSACTION_TYP  := null;
      lAccountInfo2.DEF_DIC_IMP_FREE1      := null;
      lAccountInfo2.DEF_DIC_IMP_FREE2      := null;
      lAccountInfo2.DEF_DIC_IMP_FREE3      := null;
      lAccountInfo2.DEF_DIC_IMP_FREE4      := null;
      lAccountInfo2.DEF_DIC_IMP_FREE5      := null;
      lAccountInfo2.DEF_TEXT1              := null;
      lAccountInfo2.DEF_TEXT2              := null;
      lAccountInfo2.DEF_TEXT3              := null;
      lAccountInfo2.DEF_TEXT4              := null;
      lAccountInfo2.DEF_TEXT5              := null;
      lAccountInfo2.DEF_NUMBER1            := null;
      lAccountInfo2.DEF_NUMBER2            := null;
      lAccountInfo2.DEF_NUMBER3            := null;
      lAccountInfo2.DEF_NUMBER4            := null;
      lAccountInfo2.DEF_NUMBER5            := null;

      if tplTransfert.C_POS_CREATE_MODE in('205', '206') then
        select SMO_MOVEMENT_ORDER_KEY
          into tplTransfert.SMO_MOVEMENT_ORDER_KEY
          from STM_STOCK_MOVEMENT
         where DOC_POSITION_DETAIL_ID = tplTransfert.DOC_COPY_POSITION_DETAIL_ID
           and STM_STM_STOCK_MOVEMENT_ID is not null
           and not STM_MOVEMENT_KIND_ID(+) = getReportMovementKindId
           and SMO_EXTOURNE_MVT = 0;
      end if;

      STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => lStockMovementId
                                      , iGoodId                => tplTransfert.GCO_GOOD_ID
                                      , iMovementKindId        => tplTransfert.STM_STM_MOVEMENT_KIND_ID
                                      , iExerciseId            => tplTransfert.STM_EXERCISE_ID
                                      , iPeriodId              => tplTransfert.STM_PERIOD_ID
                                      , iMvtDate               => tplTransfert.SMO_MOVEMENT_DATE
                                      , iValueDate             => nvl(tplTransfert.SMO_VALUE_DATE, tplTransfert.SMO_MOVEMENT_DATE)   -- STM_STOCK_MOVEMENT.SMO_VALUE_DATE%type,
                                      , iStockId               => tplTransfert.STM_STM_STOCK_ID
                                      , iLocationId            => tplTransfert.STM_STM_LOCATION_ID
                                      , iThirdId               => tplTransfert.PAC_THIRD_ID
                                      , iThirdAciId            => tplTransfert.PAC_THIRD_ACI_ID
                                      , iThirdDeliveryId       => tplTransfert.PAC_THIRD_DELIVERY_ID
                                      , iThirdTariffId         => tplTransfert.PAC_THIRD_TARIFF_ID
                                      , iRecordId              => tplTransfert.DOC_RECORD_ID
                                      , iChar1Id               => tplTransfert.GCO_CHARACTERIZATION_ID
                                      , iChar2Id               => tplTransfert.GCO_GCO_CHARACTERIZATION_ID
                                      , iChar3Id               => tplTransfert.GCO2_GCO_CHARACTERIZATION_ID
                                      , iChar4Id               => tplTransfert.GCO3_GCO_CHARACTERIZATION_ID
                                      , iChar5Id               => tplTransfert.GCO4_GCO_CHARACTERIZATION_ID
                                      , iCharValue1            => tplTransfert.PDE_CHARACTERIZATION_VALUE_1
                                      , iCharValue2            => tplTransfert.PDE_CHARACTERIZATION_VALUE_2
                                      , iCharValue3            => tplTransfert.PDE_CHARACTERIZATION_VALUE_3
                                      , iCharValue4            => tplTransfert.PDE_CHARACTERIZATION_VALUE_4
                                      , iCharValue5            => tplTransfert.PDE_CHARACTERIZATION_VALUE_5
                                      , iMovement2Id           => tplTransfert.STM_STM_STOCK_MOVEMENT_ID
                                      , iMovement3Id           => null   -- STM_STOCK_MOVEMENT.STM2_STM_STOCK_MOVEMENT_ID%type,
                                      , iWording               => tplTransfert.SMO_WORDING
                                      , iExternalDocument      => null   --STM_STOCK_MOVEMENT.SMO_EXTERNAL_DOCUMENT%type,
                                      , iExternalPartner       => null   --STM_STOCK_MOVEMENT.SMO_EXTERNAL_PARTNER%type,
                                      , iMvtQty                => tplTransfert.PDE_MOVEMENT_QUANTITY   -- STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type,
                                      , iMvtPrice              => tplTransfert.PDE_MOVEMENT_VALUE   -- STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type,
                                      , iDocQty                => tplTransfert.SMO_DOCUMENT_QUANTITY
                                      , iDocPrice              => tplTransfert.SMO_DOCUMENT_PRICE
                                      , iUnitPrice             => tplTransfert.SMO_UNIT_PRICE
                                      , iRefUnitPrice          => tplTransfert.SMO_REFERENCE_UNIT_PRICE
                                      , iAltQty1               => tplTransfert.PDT_ALTERNATIVE_QUANTITY_1
                                      , iAltQty2               => tplTransfert.PDT_ALTERNATIVE_QUANTITY_2
                                      , iAltQty3               => tplTransfert.PDT_ALTERNATIVE_QUANTITY_3
                                      , iDocPositionDetailId   => tplTransfert.DOC_POSITION_DETAIL_ID
                                      , iDocPositionId         => tplTransfert.DOC_POSITION_ID
                                      , iFinancialAccountId    => lFinancialAccountID   -- ACS_FINANCIAL_ACCOUNT_ID,
                                      , iDivisionAccountId     => lDivisionAccountID   -- ACS_DIVISION_ACCOUNT_ID,
                                      , iAFinancialAccountId   => lFinancialAccountID2   -- ACS_ACS_FINANCIAL_ACCOUNT_ID,
                                      , iADivisionAccountId    => lDivisionAccountID2   -- ACS_ACS_DIVISION_ACCOUNT_ID,
                                      , iCPNAccountId          => lCPNAccountID   -- ACS_CPN_ACCOUNT_ID,
                                      , iACPNAccountId         => lCPNAccountID2   -- ACS_ACS_CPN_ACCOUNT_ID,
                                      , iCDAAccountId          => lCDAAccountID   -- ACS_CDA_ACCOUNT_ID,
                                      , iACDAAccountId         => lCDAAccountID2   -- ACS_ACS_CDA_ACCOUNT_ID,
                                      , iPFAccountId           => lPFAccountID   -- ACS_PF_ACCOUNT_ID,
                                      , iAPFAccountId          => lPFAccountID2   -- ACS_ACS_PF_ACCOUNT_ID,
                                      , iPJAccountId           => lPJAccountID   -- ACS_PJ_ACCOUNT_ID,
                                      , iAPJAccountId          => lPJAccountID2   -- ACS_ACS_PJ_ACCOUNT_ID,
                                      , iFamFixedAssetsId      => lAccountInfo.FAM_FIXED_ASSETS_ID
                                      , iFamTransactionTyp     => lAccountInfo.C_FAM_TRANSACTION_TYP
                                      , iHrmPersonId           => ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(lAccountInfo.DEF_HRM_PERSON)
                                      , iDicImpfree1Id         => lAccountInfo.DEF_DIC_IMP_FREE1
                                      , iDicImpfree2Id         => lAccountInfo.DEF_DIC_IMP_FREE2
                                      , iDicImpfree3Id         => lAccountInfo.DEF_DIC_IMP_FREE3
                                      , iDicImpfree4Id         => lAccountInfo.DEF_DIC_IMP_FREE4
                                      , iDicImpfree5Id         => lAccountInfo.DEF_DIC_IMP_FREE5
                                      , iImpText1              => lAccountInfo.DEF_TEXT1
                                      , iImpText2              => lAccountInfo.DEF_TEXT2
                                      , iImpText3              => lAccountInfo.DEF_TEXT3
                                      , iImpText4              => lAccountInfo.DEF_TEXT4
                                      , iImpText5              => lAccountInfo.DEF_TEXT5
                                      , iImpNumber1            => to_number(lAccountInfo.DEF_NUMBER1)
                                      , iImpNumber2            => to_number(lAccountInfo.DEF_NUMBER2)
                                      , iImpNumber3            => to_number(lAccountInfo.DEF_NUMBER3)
                                      , iImpNumber4            => to_number(lAccountInfo.DEF_NUMBER4)
                                      , iImpNumber5            => to_number(lAccountInfo.DEF_NUMBER5)
                                      , iFinancialCharging     => tplTransfert.SMO_FINANCIAL_CHARGING
                                      , iUpdateProv            => 1   -- STM_STOCK_MOVEMENT.SMO_UPDATE_PROV%type,
                                      , iExtourneMvt           => 0   -- STM_STOCK_MOVEMENT.SMO_EXTOURNE_MVT%type,
                                      , iRecStatus             => 5   -- STM_STOCK_MOVEMENT.A_RECSTATUS%type
                                      , iOrderKey              => tplTransfert.SMO_MOVEMENT_ORDER_KEY
                                       );
    end loop;
  end DocTransfertMovements;

  /**
  *      Générations des mouvements de stock d'un document
  */
  procedure GenerateDocMovements(
    iDocumentId in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , iWording    in     STM_STOCK_MOVEMENT.SMO_WORDING%type default null
  , iSubCtError out    varchar2
  )
  is
    lDocWithMovements number(1);
    lDocDate          date;
    lIntPos           integer;
    lvError           varchar(4000);
    lDocValidPeriod   date;
  begin
    select sign(nvl(max(doc_position_id), 0) )
      into lDocWithMovements
      from DOC_POSITION
     where DOC_DOCUMENT_ID = iDocumentId
       and STM_MOVEMENT_KIND_ID is not null;

    -- uniquement si le document génère des mouvements de stock
    if lDocWithMovements = 1 then
      savepoint spBeforeGenerateMvts;
      DOC_FUNCTIONS.CreateHistoryInformation(iDocumentId, null,   -- DOC_POSITION_ID
                                             null,   -- no de document
                                             'PL/SQL',   -- DUH_TYPE
                                             'DOCUMENT GENERATE MOVEMENTS', null,   -- description libre
                                             null,   -- status document
                                             null);   -- status position
      -- Mouvements d'extourne des mouvements de sortie (a_recstatus = 1)
      DocExtourneOutputMovements(iDocumentId);
      -- Mouvement normaux (a_recstatus = 2)
      DocMainMovements(iDocumentId, iWording);
      -- Mouvements d'extourne des mouvements lié de type sortie (a_recstatus = 6)
      DocExtTransfertOutputMovements(iDocumentId);
      -- Mouvements d'extourne des mouvements d'entrée (a_recstatus = 3)
      DocExtourneInputMovements(iDocumentId);
      -- Mouvements d'extourne des mouvements lié de type entrée (a_recstatus = 4)
      DocExtTransfertInputMovements(iDocumentId);
      -- Mouvement de transfert (mouvements liés) (a_recstatus = 5)
      DocTransfertMovements(iDocumentId, iWording);
      -- Mouvements des matières précieuses sur le pied du document
      DocFootAlloyMovements(iDocumentId);

      -- Mis à jour du flag de génération des mouvements sur les positions
      update DOC_POSITION
         set POS_GENERATE_MOVEMENT = 1
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_DOCUMENT_ID = iDocumentId
         and STM_MOVEMENT_KIND_ID is not null;

      select DMT_DATE_DOCUMENT
        into lDocDate
        from DOC_DOCUMENT
       where DOC_DOCUMENT_ID = iDocumentId;

      select STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(LDocDate), lDocDate)
        into lDocValidPeriod
        from dual;

      lvError  := null;

      -- Mis à jour du flag de génération des mouvements sur les details de positions
      -- on fait une boucle afin de mettre à jour un seul enregistrement à la fois et de gérer
      -- les exceptions retournées par le trigger DOC_POSITION_DETAIL.DOC_PDE_AU_MOVEMENT
      for tplPos in (select DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID
                          , DOC_POSITION.POS_NUMBER
                       from DOC_POSITION
                          , DOC_POSITION_DETAIL
                      where DOC_POSITION.DOC_DOCUMENT_ID = iDocumentId
                        and DOC_POSITION.DOC_POSITION_ID = DOC_POSITION_DETAIL.DOC_POSITION_ID
                        and DOC_POSITION.STM_MOVEMENT_KIND_ID is not null) loop
        begin
          savepoint spBeforeGenerateOper;

          update DOC_POSITION_DETAIL
             set PDE_GENERATE_MOVEMENT = 1
               , PDE_MOVEMENT_DATE = nvl(PDE_MOVEMENT_DATE, lDocValidPeriod)
               , A_DATEMOD = sysdate
               , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           where DOC_POSITION_DETAIL_ID = tplPos.DOC_POSITION_DETAIL_ID;
        exception
          when others then
            rollback to savepoint spBeforeGenerateOper;

            -- Voir trigger DOC_POSITION_DETAIL.DOC_PDE_AU_MOVEMENT
            if     (sqlcode > -21000)
               and (sqlcode <= -20900) then
              -- Effacement des ORA-.... pour ne garder que le texte utile
              lvError  := replace(sqlerrm, 'ORA' || sqlcode || ': ', '');
              LIntPos  := instr(lvError, 'ORA-');

              if LintPos > 0 then
                lvError  := substr(lvError, 1, LIntPos - 1);
              end if;
            else
              lvError  := sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
            end if;

            if iSubCtError is null then
              iSubCtError  := 'Position  ' || tplPos.POS_NUMBER || ' : ' || lvError;
            else
              iSubCtError  := iSubCtError || chr(13) || chr(10) || 'Position  ' || tplPos.POS_NUMBER || ' : ' || lvError;
            end if;
        end;
      end loop;

      if lvError is not null then
        rollback to savepoint spBeforeGenerateMvts;
      end if;
    end if;
  end GenerateDocMovements;

  /**
  * Description
  *          Génération des mouvements d'extourne lors du solde d'un document
  */
  procedure SoldeDocExtourneMovements(iDocumentId in doc_document.doc_document_id%type)
  is
    cursor lcurSecondaryMovements(iDocumentId doc_document.doc_document_id%type)
    is
      select   STM_FUNCTIONS.GetPeriodExerciseId(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) ) STM_EXERCISE_ID
             , STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) STM_PERIOD_ID
             , SMO.STM_MOVEMENT_KIND_ID
             , SMO.STM_STOCK_ID
             , SMO.GCO_GOOD_ID
             , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT), DMT.DMT_DATE_DOCUMENT) SMO_MOVEMENT_DATE
             , SMO.SMO_VALUE_DATE
             , SMO.SMO_WORDING
             , -least(ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 1 / power(10, GOO.GOO_NUMBER_OF_DECIMAL), 0)
                    , SMO.SMO_MOVEMENT_QUANTITY
                     ) SMO_MOVEMENT_QUANTITY
             , -SMO.SMO_UNIT_PRICE * least(PDE.PDE_BALANCE_QUANTITY, SMO.SMO_MOVEMENT_QUANTITY) SMO_MOVEMENT_PRICE
             , -PDE.PDE_BALANCE_QUANTITY SMO_DOCUMENT_QUANTITY
             , -(SMO_DOCUMENT_PRICE / decode(SMO_DOCUMENT_QUANTITY, 0, 1, SMO_DOCUMENT_QUANTITY) ) * PDE.PDE_BALANCE_QUANTITY SMO_DOCUMENT_PRICE
             , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_1, 1, PDT.PDT_CONVERSION_FACTOR_1 * PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 0)
                                                                                                                                       SMO_MVT_ALTERNATIV_QTY_1
             , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_2, 1, PDT.PDT_CONVERSION_FACTOR_2 * PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 0)
                                                                                                                                       SMO_MVT_ALTERNATIV_QTY_2
             , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_3, 1, PDT.PDT_CONVERSION_FACTOR_3 * PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 0)
                                                                                                                                       SMO_MVT_ALTERNATIV_QTY_3
             , SMO.SMO_REFERENCE_UNIT_PRICE
             , SMO.SMO_UNIT_PRICE
             , SMO.SMO_FINANCIAL_CHARGING
             , sysdate A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
             , PDE.DOC_POSITION_DETAIL_ID
             , SMO.DOC_POSITION_ID
             , SMO.STM_LOCATION_ID
             , SMO.PAC_THIRD_ID
             , SMO.PAC_THIRD_ACI_ID
             , SMO.PAC_THIRD_DELIVERY_ID
             , SMO.PAC_THIRD_TARIFF_ID
             , SMO.DOC_RECORD_ID
             , SMO.GCO_CHARACTERIZATION_ID
             , SMO.SMO_CHARACTERIZATION_VALUE_1
             , SMO.GCO_GCO_CHARACTERIZATION_ID
             , SMO.SMO_CHARACTERIZATION_VALUE_2
             , SMO.GCO2_GCO_CHARACTERIZATION_ID
             , SMO.SMO_CHARACTERIZATION_VALUE_3
             , SMO.GCO3_GCO_CHARACTERIZATION_ID
             , SMO.SMO_CHARACTERIZATION_VALUE_4
             , SMO.GCO4_GCO_CHARACTERIZATION_ID
             , SMO.SMO_CHARACTERIZATION_VALUE_5
             , SMO.ACS_FINANCIAL_ACCOUNT_ID
             , SMO.ACS_DIVISION_ACCOUNT_ID
             , SMO.ACS_ACS_FINANCIAL_ACCOUNT_ID
             , SMO.ACS_ACS_DIVISION_ACCOUNT_ID
             , SMO.ACS_CPN_ACCOUNT_ID
             , SMO.ACS_ACS_CPN_ACCOUNT_ID
             , SMO.ACS_CDA_ACCOUNT_ID
             , SMO.ACS_ACS_CDA_ACCOUNT_ID
             , SMO.ACS_PF_ACCOUNT_ID
             , SMO.ACS_ACS_PF_ACCOUNT_ID
             , SMO.ACS_PJ_ACCOUNT_ID
             , SMO.ACS_ACS_PJ_ACCOUNT_ID
             , SMO.FAM_FIXED_ASSETS_ID
             , SMO.C_FAM_TRANSACTION_TYP
             , SMO.HRM_PERSON_ID
             , SMO.DIC_IMP_FREE1_ID
             , SMO.DIC_IMP_FREE2_ID
             , SMO.DIC_IMP_FREE3_ID
             , SMO.DIC_IMP_FREE4_ID
             , SMO.DIC_IMP_FREE5_ID
             , SMO.SMO_IMP_TEXT_1
             , SMO.SMO_IMP_TEXT_2
             , SMO.SMO_IMP_TEXT_3
             , SMO.SMO_IMP_TEXT_4
             , SMO.SMO_IMP_TEXT_5
             , SMO.SMO_IMP_NUMBER_1
             , SMO.SMO_IMP_NUMBER_2
             , SMO.SMO_IMP_NUMBER_3
             , SMO.SMO_IMP_NUMBER_4
             , SMO.SMO_IMP_NUMBER_5
             , 0 SMO_UPDATE_PROV
             , 1 SMO_EXTOURNE_MVT
          from STM_STOCK_MOVEMENT SMO
             , DOC_POSITION_DETAIL PDE
             , DOC_POSITION POS
             , DOC_DOCUMENT DMT
             , STM_MOVEMENT_KIND MOK
             , GCO_PRODUCT PDT
             , GCO_GOOD GOO
         where PDE.DOC_DOCUMENT_ID = iDocumentId
           and POS.POS_GENERATE_MOVEMENT = 1
           and SMO.SMO_EXTOURNE_MVT = 0
           and PDE.PDE_BALANCE_QUANTITY <> 0
           and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and SMO.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
           and MOK.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID
           and SMO.STM_MOVEMENT_KIND_ID = MOK.STM_STM_MOVEMENT_KIND_ID
           and GOO.GCO_GOOD_ID = POS.GCO_GOOD_ID
           and PDT.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
      order by POS.GCO_GOOD_ID
             , SMO.SMO_CHARACTERIZATION_VALUE_1
             , SMO.SMO_CHARACTERIZATION_VALUE_2
             , SMO.SMO_CHARACTERIZATION_VALUE_3
             , SMO.SMO_CHARACTERIZATION_VALUE_4
             , SMO.SMO_CHARACTERIZATION_VALUE_5
             , POS.POS_NUMBER;

    ltplSecondaryMovement lcurSecondaryMovements%rowtype;

    cursor lcurMainMovements(iDocumentId doc_document.doc_document_id%type)
    is
      select   STM_FUNCTIONS.GetPeriodExerciseId(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) ) STM_EXERCISE_ID
             , STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) STM_PERIOD_ID
             , SMO.STM_MOVEMENT_KIND_ID
             , SMO.STM_STOCK_ID
             , SMO.GCO_GOOD_ID
             , DMT.DMT_DATE_DOCUMENT
             , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT), DMT.DMT_DATE_DOCUMENT) SMO_MOVEMENT_DATE
             , SMO.SMO_VALUE_DATE
             , SMO.SMO_WORDING
             , -least(ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 1 / power(10, GOO.GOO_NUMBER_OF_DECIMAL), 0)
                    , SMO.SMO_MOVEMENT_QUANTITY
                     ) SMO_MOVEMENT_QUANTITY
             , -SMO.SMO_UNIT_PRICE * least(PDE.PDE_BALANCE_QUANTITY, SMO.SMO_MOVEMENT_QUANTITY) SMO_MOVEMENT_PRICE
             , -PDE.PDE_BALANCE_QUANTITY SMO_DOCUMENT_QUANTITY
             , -(SMO_DOCUMENT_PRICE / decode(SMO_DOCUMENT_QUANTITY, 0, 1, SMO_DOCUMENT_QUANTITY) ) * PDE.PDE_BALANCE_QUANTITY SMO_DOCUMENT_PRICE
             , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_1, 1, PDT.PDT_CONVERSION_FACTOR_1 * PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 0)
                                                                                                                                       SMO_MVT_ALTERNATIV_QTY_1
             , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_2, 1, PDT.PDT_CONVERSION_FACTOR_2 * PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 0)
                                                                                                                                       SMO_MVT_ALTERNATIV_QTY_2
             , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_3, 1, PDT.PDT_CONVERSION_FACTOR_3 * PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 0)
                                                                                                                                       SMO_MVT_ALTERNATIV_QTY_3
             , SMO.SMO_REFERENCE_UNIT_PRICE
             , SMO.SMO_UNIT_PRICE
             , SMO.SMO_FINANCIAL_CHARGING
             , sysdate A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
             , PDE.DOC_POSITION_DETAIL_ID
             , SMO.DOC_POSITION_ID
             , SMO.STM_LOCATION_ID
             , SMO.PAC_THIRD_ID
             , SMO.PAC_THIRD_ACI_ID
             , SMO.PAC_THIRD_DELIVERY_ID
             , SMO.PAC_THIRD_TARIFF_ID
             , SMO.DOC_RECORD_ID
             , SMO.GCO_CHARACTERIZATION_ID
             , SMO.SMO_CHARACTERIZATION_VALUE_1
             , SMO.GCO_GCO_CHARACTERIZATION_ID
             , SMO.SMO_CHARACTERIZATION_VALUE_2
             , SMO.GCO2_GCO_CHARACTERIZATION_ID
             , SMO.SMO_CHARACTERIZATION_VALUE_3
             , SMO.GCO3_GCO_CHARACTERIZATION_ID
             , SMO.SMO_CHARACTERIZATION_VALUE_4
             , SMO.GCO4_GCO_CHARACTERIZATION_ID
             , SMO.SMO_CHARACTERIZATION_VALUE_5
             , SMO.ACS_FINANCIAL_ACCOUNT_ID
             , SMO.ACS_DIVISION_ACCOUNT_ID
             , SMO.ACS_ACS_FINANCIAL_ACCOUNT_ID
             , SMO.ACS_ACS_DIVISION_ACCOUNT_ID
             , SMO.ACS_CPN_ACCOUNT_ID
             , SMO.ACS_ACS_CPN_ACCOUNT_ID
             , SMO.ACS_CDA_ACCOUNT_ID
             , SMO.ACS_ACS_CDA_ACCOUNT_ID
             , SMO.ACS_PF_ACCOUNT_ID
             , SMO.ACS_ACS_PF_ACCOUNT_ID
             , SMO.ACS_PJ_ACCOUNT_ID
             , SMO.ACS_ACS_PJ_ACCOUNT_ID
             , SMO.FAM_FIXED_ASSETS_ID
             , SMO.C_FAM_TRANSACTION_TYP
             , SMO.HRM_PERSON_ID
             , SMO.DIC_IMP_FREE1_ID
             , SMO.DIC_IMP_FREE2_ID
             , SMO.DIC_IMP_FREE3_ID
             , SMO.DIC_IMP_FREE4_ID
             , SMO.DIC_IMP_FREE5_ID
             , SMO.SMO_IMP_TEXT_1
             , SMO.SMO_IMP_TEXT_2
             , SMO.SMO_IMP_TEXT_3
             , SMO.SMO_IMP_TEXT_4
             , SMO.SMO_IMP_TEXT_5
             , SMO.SMO_IMP_NUMBER_1
             , SMO.SMO_IMP_NUMBER_2
             , SMO.SMO_IMP_NUMBER_3
             , SMO.SMO_IMP_NUMBER_4
             , SMO.SMO_IMP_NUMBER_5
             , 0 SMO_UPDATE_PROV
             , 1 SMO_EXTOURNE_MVT
          from STM_STOCK_MOVEMENT SMO
             , DOC_POSITION_DETAIL PDE
             , DOC_POSITION POS
             , DOC_DOCUMENT DMT
             , GCO_PRODUCT PDT
             , GCO_GOOD GOO
         where PDE.DOC_DOCUMENT_ID = iDocumentId
           and POS.POS_GENERATE_MOVEMENT = 1
           and SMO.SMO_EXTOURNE_MVT = 0
           and PDE.PDE_BALANCE_QUANTITY <> 0
           and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and SMO.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
           and SMO.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID
           and GOO.GCO_GOOD_ID = POS.GCO_GOOD_ID
           and PDT.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
      order by POS.GCO_GOOD_ID
             , SMO.SMO_CHARACTERIZATION_VALUE_1
             , SMO.SMO_CHARACTERIZATION_VALUE_2
             , SMO.SMO_CHARACTERIZATION_VALUE_3
             , SMO.SMO_CHARACTERIZATION_VALUE_4
             , SMO.SMO_CHARACTERIZATION_VALUE_5
             , POS.POS_NUMBER;

    ltplMainMovement      lcurMainMovements%rowtype;
    lStockMovementId      STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
  begin
    DOC_FUNCTIONS.CreateHistoryInformation(iDocumentId, null,   -- DOC_POSITION_ID
                                           null,   -- no de document
                                           'PL/SQL',   -- DUH_TYPE
                                           'DOCUMENT BALANCE MOVEMENTS', null,   -- description libre
                                           null,   -- status document
                                           null);   -- status position

    -- extourne des mouvements de transfert (mouvement lié, obligatoirement le mouvement de sortie)
    open lcurSecondaryMovements(iDocumentId);

    fetch lcurSecondaryMovements
     into ltplSecondaryMovement;

    while lcurSecondaryMovements%found loop
      lStockMovementId  := null;
      STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => lStockMovementId
                                      , iGoodId                => ltplSecondaryMovement.GCO_GOOD_ID
                                      , iMovementKindId        => ltplSecondaryMovement.STM_MOVEMENT_KIND_ID
                                      , iExerciseId            => ltplSecondaryMovement.STM_EXERCISE_ID
                                      , iPeriodId              => ltplSecondaryMovement.STM_PERIOD_ID
                                      , iMvtDate               => ltplSecondaryMovement.SMO_MOVEMENT_DATE
                                      , iValueDate             => ltplSecondaryMovement.SMO_VALUE_DATE
                                      , iStockId               => ltplSecondaryMovement.STM_STOCK_ID
                                      , iLocationId            => ltplSecondaryMovement.STM_LOCATION_ID
                                      , iThirdId               => ltplSecondaryMovement.PAC_THIRD_ID
                                      , iThirdAciId            => ltplSecondaryMovement.PAC_THIRD_ACI_ID
                                      , iThirdDeliveryId       => ltplSecondaryMovement.PAC_THIRD_DELIVERY_ID
                                      , iThirdTariffId         => ltplSecondaryMovement.PAC_THIRD_TARIFF_ID
                                      , iRecordId              => ltplSecondaryMovement.DOC_RECORD_ID
                                      , iChar1Id               => ltplSecondaryMovement.GCO_CHARACTERIZATION_ID
                                      , iChar2Id               => ltplSecondaryMovement.GCO_GCO_CHARACTERIZATION_ID
                                      , iChar3Id               => ltplSecondaryMovement.GCO2_GCO_CHARACTERIZATION_ID
                                      , iChar4Id               => ltplSecondaryMovement.GCO3_GCO_CHARACTERIZATION_ID
                                      , iChar5Id               => ltplSecondaryMovement.GCO4_GCO_CHARACTERIZATION_ID
                                      , iCharValue1            => ltplSecondaryMovement.SMO_CHARACTERIZATION_VALUE_1
                                      , iCharValue2            => ltplSecondaryMovement.SMO_CHARACTERIZATION_VALUE_2
                                      , iCharValue3            => ltplSecondaryMovement.SMO_CHARACTERIZATION_VALUE_3
                                      , iCharValue4            => ltplSecondaryMovement.SMO_CHARACTERIZATION_VALUE_4
                                      , iCharValue5            => ltplSecondaryMovement.SMO_CHARACTERIZATION_VALUE_5
                                      , iMovement2Id           => null   -- STM_STOCK_MOVEMENT.STM_STM_STOCK_MOVEMENT_ID%type,
                                      , iMovement3Id           => null   -- STM_STOCK_MOVEMENT.STM2_STM_STOCK_MOVEMENT_ID%type,
                                      , iWording               => ltplSecondaryMovement.SMO_WORDING
                                      , iExternalDocument      => null   --STM_STOCK_MOVEMENT.SMO_EXTERNAL_DOCUMENT%type,
                                      , iExternalPartner       => null   --STM_STOCK_MOVEMENT.SMO_EXTERNAL_PARTNER%type,
                                      , iMvtQty                => ltplSecondaryMovement.SMO_MOVEMENT_QUANTITY
                                      , iMvtPrice              => ltplSecondaryMovement.SMO_MOVEMENT_PRICE
                                      , iDocQty                => ltplSecondaryMovement.SMO_DOCUMENT_QUANTITY
                                      , iDocPrice              => ltplSecondaryMovement.SMO_DOCUMENT_PRICE
                                      , iUnitPrice             => ltplSecondaryMovement.SMO_UNIT_PRICE
                                      , iRefUnitPrice          => ltplSecondaryMovement.SMO_REFERENCE_UNIT_PRICE
                                      , iAltQty1               => ltplSecondaryMovement.SMO_MVT_ALTERNATIV_QTY_1
                                      , iAltQty2               => ltplSecondaryMovement.SMO_MVT_ALTERNATIV_QTY_2
                                      , iAltQty3               => ltplSecondaryMovement.SMO_MVT_ALTERNATIV_QTY_3
                                      , iDocPositionDetailId   => ltplSecondaryMovement.DOC_POSITION_DETAIL_ID
                                      , iDocPositionId         => ltplSecondaryMovement.DOC_POSITION_ID
                                      , iFinancialAccountId    => ltplSecondaryMovement.ACS_FINANCIAL_ACCOUNT_ID
                                      , iDivisionAccountId     => ltplSecondaryMovement.ACS_DIVISION_ACCOUNT_ID
                                      , iAFinancialAccountId   => ltplSecondaryMovement.ACS_ACS_FINANCIAL_ACCOUNT_ID
                                      , iADivisionAccountId    => ltplSecondaryMovement.ACS_ACS_DIVISION_ACCOUNT_ID
                                      , iCPNAccountId          => ltplSecondaryMovement.ACS_CPN_ACCOUNT_ID
                                      , iACPNAccountId         => ltplSecondaryMovement.ACS_ACS_CPN_ACCOUNT_ID
                                      , iCDAAccountId          => ltplSecondaryMovement.ACS_CDA_ACCOUNT_ID
                                      , iACDAAccountId         => ltplSecondaryMovement.ACS_ACS_CDA_ACCOUNT_ID
                                      , iPFAccountId           => ltplSecondaryMovement.ACS_PF_ACCOUNT_ID
                                      , iAPFAccountId          => ltplSecondaryMovement.ACS_ACS_PF_ACCOUNT_ID
                                      , iPJAccountId           => ltplSecondaryMovement.ACS_PJ_ACCOUNT_ID
                                      , iAPJAccountId          => ltplSecondaryMovement.ACS_ACS_PJ_ACCOUNT_ID
                                      , iFamFixedAssetsId      => ltplSecondaryMovement.FAM_FIXED_ASSETS_ID
                                      , iFamTransactionTyp     => ltplSecondaryMovement.C_FAM_TRANSACTION_TYP
                                      , iHrmPersonId           => ltplSecondaryMovement.HRM_PERSON_ID
                                      , iDicImpfree1Id         => ltplSecondaryMovement.DIC_IMP_FREE1_ID
                                      , iDicImpfree2Id         => ltplSecondaryMovement.DIC_IMP_FREE2_ID
                                      , iDicImpfree3Id         => ltplSecondaryMovement.DIC_IMP_FREE3_ID
                                      , iDicImpfree4Id         => ltplSecondaryMovement.DIC_IMP_FREE4_ID
                                      , iDicImpfree5Id         => ltplSecondaryMovement.DIC_IMP_FREE5_ID
                                      , iImpText1              => ltplSecondaryMovement.SMO_IMP_TEXT_1
                                      , iImpText2              => ltplSecondaryMovement.SMO_IMP_TEXT_2
                                      , iImpText3              => ltplSecondaryMovement.SMO_IMP_TEXT_3
                                      , iImpText4              => ltplSecondaryMovement.SMO_IMP_TEXT_4
                                      , iImpText5              => ltplSecondaryMovement.SMO_IMP_TEXT_5
                                      , iImpNumber1            => ltplSecondaryMovement.SMO_IMP_NUMBER_1
                                      , iImpNumber2            => ltplSecondaryMovement.SMO_IMP_NUMBER_2
                                      , iImpNumber3            => ltplSecondaryMovement.SMO_IMP_NUMBER_3
                                      , iImpNumber4            => ltplSecondaryMovement.SMO_IMP_NUMBER_4
                                      , iImpNumber5            => ltplSecondaryMovement.SMO_IMP_NUMBER_5
                                      , iFinancialCharging     => ltplSecondaryMovement.SMO_FINANCIAL_CHARGING
                                      , iUpdateProv            => 0   -- STM_STOCK_MOVEMENT.SMO_UPDATE_PROV%type,
                                      , iExtourneMvt           => 1   -- STM_STOCK_MOVEMENT.SMO_EXTOURNE_MVT%type,
                                      , iRecStatus             => null   -- STM_STOCK_MOVEMENT.A_RECSTATUS%type
                                       );

      fetch lcurSecondaryMovements
       into ltplSecondaryMovement;
    end loop;

    -- extournes des mouvements
    -- extournes des mouvements principaux (obligatoirement mouvement d'entrée dans le cas d'un transfert)
    -- y compris pour les éventuels composants de la position
    open lcurMainMovements(iDocumentId);

    fetch lcurMainMovements
     into ltplMainMovement;

    while lcurMainMovements%found loop
      lStockMovementId  := null;
      STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => lStockMovementId
                                      , iGoodId                => ltplMainMovement.GCO_GOOD_ID
                                      , iMovementKindId        => ltplMainMovement.STM_MOVEMENT_KIND_ID
                                      , iExerciseId            => ltplMainMovement.STM_EXERCISE_ID
                                      , iPeriodId              => ltplMainMovement.STM_PERIOD_ID
                                      , iMvtDate               => ltplMainMovement.SMO_MOVEMENT_DATE
                                      , iValueDate             => ltplMainMovement.SMO_VALUE_DATE
                                      , iStockId               => ltplMainMovement.STM_STOCK_ID
                                      , iLocationId            => ltplMainMovement.STM_LOCATION_ID
                                      , iThirdId               => ltplMainMovement.PAC_THIRD_ID
                                      , iThirdAciId            => ltplMainMovement.PAC_THIRD_ACI_ID
                                      , iThirdDeliveryId       => ltplMainMovement.PAC_THIRD_DELIVERY_ID
                                      , iThirdTariffId         => ltplMainMovement.PAC_THIRD_TARIFF_ID
                                      , iRecordId              => ltplMainMovement.DOC_RECORD_ID
                                      , iChar1Id               => ltplMainMovement.GCO_CHARACTERIZATION_ID
                                      , iChar2Id               => ltplMainMovement.GCO_GCO_CHARACTERIZATION_ID
                                      , iChar3Id               => ltplMainMovement.GCO2_GCO_CHARACTERIZATION_ID
                                      , iChar4Id               => ltplMainMovement.GCO3_GCO_CHARACTERIZATION_ID
                                      , iChar5Id               => ltplMainMovement.GCO4_GCO_CHARACTERIZATION_ID
                                      , iCharValue1            => ltplMainMovement.SMO_CHARACTERIZATION_VALUE_1
                                      , iCharValue2            => ltplMainMovement.SMO_CHARACTERIZATION_VALUE_2
                                      , iCharValue3            => ltplMainMovement.SMO_CHARACTERIZATION_VALUE_3
                                      , iCharValue4            => ltplMainMovement.SMO_CHARACTERIZATION_VALUE_4
                                      , iCharValue5            => ltplMainMovement.SMO_CHARACTERIZATION_VALUE_5
                                      , iMovement2Id           => null   -- STM_STOCK_MOVEMENT.STM_STM_STOCK_MOVEMENT_ID%type,
                                      , iMovement3Id           => null   -- STM_STOCK_MOVEMENT.STM2_STM_STOCK_MOVEMENT_ID%type,
                                      , iWording               => ltplMainMovement.SMO_WORDING
                                      , iExternalDocument      => null   --STM_STOCK_MOVEMENT.SMO_EXTERNAL_DOCUMENT%type,
                                      , iExternalPartner       => null   --STM_STOCK_MOVEMENT.SMO_EXTERNAL_PARTNER%type,
                                      , iMvtQty                => ltplMainMovement.SMO_MOVEMENT_QUANTITY
                                      , iMvtPrice              => ltplMainMovement.SMO_MOVEMENT_PRICE
                                      , iDocQty                => ltplMainMovement.SMO_DOCUMENT_QUANTITY
                                      , iDocPrice              => ltplMainMovement.SMO_DOCUMENT_PRICE
                                      , iUnitPrice             => ltplMainMovement.SMO_UNIT_PRICE
                                      , iRefUnitPrice          => ltplMainMovement.SMO_REFERENCE_UNIT_PRICE
                                      , iAltQty1               => ltplMainMovement.SMO_MVT_ALTERNATIV_QTY_1
                                      , iAltQty2               => ltplMainMovement.SMO_MVT_ALTERNATIV_QTY_2
                                      , iAltQty3               => ltplMainMovement.SMO_MVT_ALTERNATIV_QTY_3
                                      , iDocPositionDetailId   => ltplMainMovement.DOC_POSITION_DETAIL_ID
                                      , iDocPositionId         => ltplMainMovement.DOC_POSITION_ID
                                      , iFinancialAccountId    => ltplMainMovement.ACS_FINANCIAL_ACCOUNT_ID
                                      , iDivisionAccountId     => ltplMainMovement.ACS_DIVISION_ACCOUNT_ID
                                      , iAFinancialAccountId   => ltplMainMovement.ACS_ACS_FINANCIAL_ACCOUNT_ID
                                      , iADivisionAccountId    => ltplMainMovement.ACS_ACS_DIVISION_ACCOUNT_ID
                                      , iCPNAccountId          => ltplMainMovement.ACS_CPN_ACCOUNT_ID
                                      , iACPNAccountId         => ltplMainMovement.ACS_ACS_CPN_ACCOUNT_ID
                                      , iCDAAccountId          => ltplMainMovement.ACS_CDA_ACCOUNT_ID
                                      , iACDAAccountId         => ltplMainMovement.ACS_ACS_CDA_ACCOUNT_ID
                                      , iPFAccountId           => ltplMainMovement.ACS_PF_ACCOUNT_ID
                                      , iAPFAccountId          => ltplMainMovement.ACS_ACS_PF_ACCOUNT_ID
                                      , iPJAccountId           => ltplMainMovement.ACS_PJ_ACCOUNT_ID
                                      , iAPJAccountId          => ltplMainMovement.ACS_ACS_PJ_ACCOUNT_ID
                                      , iFamFixedAssetsId      => null   -- iFamFixedAssetsId in STM_STOCK_MOVEMENT.FAM_FIXED_ASSETS_ID%type,
                                      , iFamTransactionTyp     => null   -- iFamTransactionTyp in STM_STOCK_MOVEMENT.C_FAM_TRANSACTION_TYP%type,
                                      , iHrmPersonId           => null   -- iHrmPersonId in STM_STOCK_MOVEMENT.HRM_PERSON_ID%type,
                                      , iDicImpfree1Id         => null   -- iDicImpfree1Id in STM_STOCK_MOVEMENT.DIC_IMP_FREE1_ID%type,
                                      , iDicImpfree2Id         => null   -- iDicImpfree2Id in STM_STOCK_MOVEMENT.DIC_IMP_FREE2_ID%type,
                                      , iDicImpfree3Id         => null   -- iDicImpfree3Id in STM_STOCK_MOVEMENT.DIC_IMP_FREE3_ID%type,
                                      , iDicImpfree4Id         => null   -- iDicImpfree4Id in STM_STOCK_MOVEMENT.DIC_IMP_FREE4_ID%type,
                                      , iDicImpfree5Id         => null   -- iDicImpfree5Id in STM_STOCK_MOVEMENT.DIC_IMP_FREE5_ID%type,
                                      , iImpText1              => null   -- iImpText1 in STM_STOCK_MOVEMENT.SMO_IMP_TEXT_1%type,
                                      , iImpText2              => null   -- iImpText2 in STM_STOCK_MOVEMENT.SMO_IMP_TEXT_2%type,
                                      , iImpText3              => null   -- iImpText3 in STM_STOCK_MOVEMENT.SMO_IMP_TEXT_3%type,
                                      , iImpText4              => null   -- iImpText4 in STM_STOCK_MOVEMENT.SMO_IMP_TEXT_4%type,
                                      , iImpText5              => null   -- iImpText5 in STM_STOCK_MOVEMENT.SMO_IMP_TEXT_5%type,
                                      , iImpNumber1            => null   -- iImpNumber1 in STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_1%type,
                                      , iImpNumber2            => null   -- iImpNumber2 in STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_2%type,
                                      , iImpNumber3            => null   -- iImpNumber3 in STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_3%type,
                                      , iImpNumber4            => null   -- iImpNumber4 in STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_4%type,
                                      , iImpNumber5            => null   -- iImpNumber5 in STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_5%type,
                                      , iFinancialCharging     => ltplMainMovement.SMO_FINANCIAL_CHARGING
                                      , iUpdateProv            => 0   -- STM_STOCK_MOVEMENT.SMO_UPDATE_PROV%type,
                                      , iExtourneMvt           => 1   -- STM_STOCK_MOVEMENT.SMO_EXTOURNE_MVT%type,
                                      , iRecStatus             => null   -- STM_STOCK_MOVEMENT.A_RECSTATUS%type
                                       );

      fetch lcurMainMovements
       into ltplMainMovement;
    end loop;

    close lcurMainMovements;

    close lcurSecondaryMovements;

    update DOC_POSITION_DETAIL PDE
       set PDE.PDE_GENERATE_MOVEMENT = 1
         , PDE.PDE_MOVEMENT_DATE =
             nvl(PDE.PDE_MOVEMENT_DATE
               , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(ltplMainMovement.DMT_DATE_DOCUMENT), ltplMainMovement.DMT_DATE_DOCUMENT)
                )
         , PDE.A_DATEMOD = sysdate
         , PDE.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where PDE.DOC_DOCUMENT_ID = iDocumentId
       and exists(select POS.STM_MOVEMENT_KIND_ID
                    from DOC_POSITION POS
                   where POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                     and POS.STM_MOVEMENT_KIND_ID is not null);

    update DOC_POSITION POS
       set POS.POS_GENERATE_MOVEMENT = 1
         , POS.A_DATEMOD = sysdate
         , POS.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where POS.DOC_DOCUMENT_ID = iDocumentId
       and POS.STM_MOVEMENT_KIND_ID is not null;

    DocExtFootAlloyMovements(iDocumentId);
  end SoldeDocExtourneMovements;

  -- Extourne des mouvements lors du solde d'une position
  procedure SoldePosExtourneMovements(iPositionId in doc_position.doc_position_id%type)
  is
    -- curseur sur les mouvements de transfert
    cursor lcurSecondaryMovement(iPositionId doc_position.doc_position_id%type)
    is
      select   *
          from ( (select STM_FUNCTIONS.GetPeriodExerciseId(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) ) STM_EXERCISE_ID
                       , STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) STM_PERIOD_ID
                       , SMO.STM_MOVEMENT_KIND_ID
                       , SMO.STM_STOCK_ID
                       , SMO.GCO_GOOD_ID
                       , DMT.DMT_DATE_DOCUMENT
                       , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT), DMT.DMT_DATE_DOCUMENT) SMO_MOVEMENT_DATE
                       , SMO.SMO_VALUE_DATE
                       , SMO.SMO_WORDING
                       , -least(ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 1 / power(10, GOO.GOO_NUMBER_OF_DECIMAL), 0)
                              , SMO.SMO_MOVEMENT_QUANTITY
                               ) SMO_MOVEMENT_QUANTITY
                       , -SMO.SMO_UNIT_PRICE *
                         least(ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 1 / power(10, GOO.GOO_NUMBER_OF_DECIMAL), 0)
                             , SMO.SMO_MOVEMENT_QUANTITY
                              ) SMO_MOVEMENT_PRICE
                       , -PDE.PDE_BALANCE_QUANTITY SMO_DOCUMENT_QUANTITY
                       , -(SMO_DOCUMENT_PRICE / decode(SMO_DOCUMENT_QUANTITY, 0, 1, SMO_DOCUMENT_QUANTITY) ) * PDE.PDE_BALANCE_QUANTITY SMO_DOCUMENT_PRICE
                       , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_1, 1, PDT.PDT_CONVERSION_FACTOR_1 * PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 0)
                                                                                                                                     SMO_ALTERNATIVE_QUANTITY_1
                       , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_2, 1, PDT.PDT_CONVERSION_FACTOR_2 * PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 0)
                                                                                                                                     SMO_ALTERNATIVE_QUANTITY_2
                       , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_3, 1, PDT.PDT_CONVERSION_FACTOR_3 * PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 0)
                                                                                                                                     SMO_ALTERNATIVE_QUANTITY_3
                       , SMO.SMO_REFERENCE_UNIT_PRICE
                       , SMO.SMO_UNIT_PRICE
                       , SMO.SMO_FINANCIAL_CHARGING
                       , sysdate A_DATECRE
                       , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
                       , PDE.DOC_POSITION_DETAIL_ID
                       , SMO.DOC_POSITION_ID
                       , SMO.STM_LOCATION_ID
                       , SMO.PAC_THIRD_ID
                       , SMO.PAC_THIRD_ACI_ID
                       , SMO.PAC_THIRD_DELIVERY_ID
                       , SMO.PAC_THIRD_TARIFF_ID
                       , SMO.DOC_RECORD_ID
                       , SMO.GCO_CHARACTERIZATION_ID
                       , SMO.SMO_CHARACTERIZATION_VALUE_1
                       , SMO.GCO_GCO_CHARACTERIZATION_ID
                       , SMO.SMO_CHARACTERIZATION_VALUE_2
                       , SMO.GCO2_GCO_CHARACTERIZATION_ID
                       , SMO.SMO_CHARACTERIZATION_VALUE_3
                       , SMO.GCO3_GCO_CHARACTERIZATION_ID
                       , SMO.SMO_CHARACTERIZATION_VALUE_4
                       , SMO.GCO4_GCO_CHARACTERIZATION_ID
                       , SMO.SMO_CHARACTERIZATION_VALUE_5
                       , SMO.ACS_FINANCIAL_ACCOUNT_ID
                       , SMO.ACS_DIVISION_ACCOUNT_ID
                       , SMO.ACS_ACS_FINANCIAL_ACCOUNT_ID
                       , SMO.ACS_ACS_DIVISION_ACCOUNT_ID
                       , SMO.ACS_CPN_ACCOUNT_ID
                       , SMO.ACS_ACS_CPN_ACCOUNT_ID
                       , SMO.ACS_CDA_ACCOUNT_ID
                       , SMO.ACS_ACS_CDA_ACCOUNT_ID
                       , SMO.ACS_PF_ACCOUNT_ID
                       , SMO.ACS_ACS_PF_ACCOUNT_ID
                       , SMO.ACS_PJ_ACCOUNT_ID
                       , SMO.ACS_ACS_PJ_ACCOUNT_ID
                       , SMO.FAM_FIXED_ASSETS_ID
                       , SMO.C_FAM_TRANSACTION_TYP
                       , SMO.HRM_PERSON_ID
                       , SMO.DIC_IMP_FREE1_ID
                       , SMO.DIC_IMP_FREE2_ID
                       , SMO.DIC_IMP_FREE3_ID
                       , SMO.DIC_IMP_FREE4_ID
                       , SMO.DIC_IMP_FREE5_ID
                       , SMO.SMO_IMP_TEXT_1
                       , SMO.SMO_IMP_TEXT_2
                       , SMO.SMO_IMP_TEXT_3
                       , SMO.SMO_IMP_TEXT_4
                       , SMO.SMO_IMP_TEXT_5
                       , SMO.SMO_IMP_NUMBER_1
                       , SMO.SMO_IMP_NUMBER_2
                       , SMO.SMO_IMP_NUMBER_3
                       , SMO.SMO_IMP_NUMBER_4
                       , SMO.SMO_IMP_NUMBER_5
                       , 0 SMO_UPDATE_PROV
                       , 1 SMO_EXTOURNE_MVT
                    from STM_STOCK_MOVEMENT SMO
                       , DOC_POSITION_DETAIL PDE
                       , DOC_POSITION POS
                       , DOC_DOCUMENT DMT
                       , STM_MOVEMENT_KIND MOK
                       , GCO_PRODUCT PDT
                       , GCO_GOOD GOO
                   where PDE.DOC_POSITION_ID = iPositionId
                     and POS.POS_GENERATE_MOVEMENT = 1
                     and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                     and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                     and SMO.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
                     and MOK.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID
                     and SMO.STM_MOVEMENT_KIND_ID = MOK.STM_STM_MOVEMENT_KIND_ID
                     and GOO.GCO_GOOD_ID = POS.GCO_GOOD_ID
                     and PDT.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID)
                union all
                (select STM_FUNCTIONS.GetPeriodExerciseId(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) ) STM_EXERCISE_ID
                      , STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) STM_PERIOD_ID
                      , SMO.STM_MOVEMENT_KIND_ID
                      , SMO.STM_STOCK_ID
                      , SMO.GCO_GOOD_ID
                      , DMT.DMT_DATE_DOCUMENT
                      , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT), DMT.DMT_DATE_DOCUMENT) SMO_MOVEMENT_DATE
                      , SMO.SMO_VALUE_DATE
                      , SMO.SMO_WORDING
                      , -least(ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 1 / power(10, GOO.GOO_NUMBER_OF_DECIMAL), 0)
                             , SMO.SMO_MOVEMENT_QUANTITY
                              ) SMO_MOVEMENT_QUANTITY
                      , -SMO.SMO_UNIT_PRICE *
                        least(ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 1 / power(10, GOO.GOO_NUMBER_OF_DECIMAL), 0)
                            , SMO.SMO_MOVEMENT_QUANTITY
                             ) SMO_MOVEMENT_PRICE
                      , -PDE.PDE_BALANCE_QUANTITY SMO_DOCUMENT_QUANTITY
                      , -(SMO_DOCUMENT_PRICE / decode(SMO_DOCUMENT_QUANTITY, 0, 1, SMO_DOCUMENT_QUANTITY) ) * PDE.PDE_BALANCE_QUANTITY SMO_DOCUMENT_PRICE
                      , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_1, 1, PDT.PDT_CONVERSION_FACTOR_1 * PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 0)
                                                                                                                                     SMO_ALTERNATIVE_QUANTITY_1
                      , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_2, 1, PDT.PDT_CONVERSION_FACTOR_2 * PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 0)
                                                                                                                                     SMO_ALTERNATIVE_QUANTITY_2
                      , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_3, 1, PDT.PDT_CONVERSION_FACTOR_3 * PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 0)
                                                                                                                                     SMO_ALTERNATIVE_QUANTITY_3
                      , SMO.SMO_REFERENCE_UNIT_PRICE
                      , SMO.SMO_UNIT_PRICE
                      , SMO.SMO_FINANCIAL_CHARGING
                      , sysdate A_DATECRE
                      , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
                      , PDE.DOC_POSITION_DETAIL_ID
                      , SMO.DOC_POSITION_ID
                      , SMO.STM_LOCATION_ID
                      , SMO.PAC_THIRD_ID
                      , SMO.PAC_THIRD_ACI_ID
                      , SMO.PAC_THIRD_DELIVERY_ID
                      , SMO.PAC_THIRD_TARIFF_ID
                      , SMO.DOC_RECORD_ID
                      , SMO.GCO_CHARACTERIZATION_ID
                      , SMO.SMO_CHARACTERIZATION_VALUE_1
                      , SMO.GCO_GCO_CHARACTERIZATION_ID
                      , SMO.SMO_CHARACTERIZATION_VALUE_2
                      , SMO.GCO2_GCO_CHARACTERIZATION_ID
                      , SMO.SMO_CHARACTERIZATION_VALUE_3
                      , SMO.GCO3_GCO_CHARACTERIZATION_ID
                      , SMO.SMO_CHARACTERIZATION_VALUE_4
                      , SMO.GCO4_GCO_CHARACTERIZATION_ID
                      , SMO.SMO_CHARACTERIZATION_VALUE_5
                      , SMO.ACS_FINANCIAL_ACCOUNT_ID
                      , SMO.ACS_DIVISION_ACCOUNT_ID
                      , SMO.ACS_ACS_FINANCIAL_ACCOUNT_ID
                      , SMO.ACS_ACS_DIVISION_ACCOUNT_ID
                      , SMO.ACS_CPN_ACCOUNT_ID
                      , SMO.ACS_ACS_CPN_ACCOUNT_ID
                      , SMO.ACS_CDA_ACCOUNT_ID
                      , SMO.ACS_ACS_CDA_ACCOUNT_ID
                      , SMO.ACS_PF_ACCOUNT_ID
                      , SMO.ACS_ACS_PF_ACCOUNT_ID
                      , SMO.ACS_PJ_ACCOUNT_ID
                      , SMO.ACS_ACS_PJ_ACCOUNT_ID
                      , SMO.FAM_FIXED_ASSETS_ID
                      , SMO.C_FAM_TRANSACTION_TYP
                      , SMO.HRM_PERSON_ID
                      , SMO.DIC_IMP_FREE1_ID
                      , SMO.DIC_IMP_FREE2_ID
                      , SMO.DIC_IMP_FREE3_ID
                      , SMO.DIC_IMP_FREE4_ID
                      , SMO.DIC_IMP_FREE5_ID
                      , SMO.SMO_IMP_TEXT_1
                      , SMO.SMO_IMP_TEXT_2
                      , SMO.SMO_IMP_TEXT_3
                      , SMO.SMO_IMP_TEXT_4
                      , SMO.SMO_IMP_TEXT_5
                      , SMO.SMO_IMP_NUMBER_1
                      , SMO.SMO_IMP_NUMBER_2
                      , SMO.SMO_IMP_NUMBER_3
                      , SMO.SMO_IMP_NUMBER_4
                      , SMO.SMO_IMP_NUMBER_5
                      , 0 SMO_UPDATE_PROV
                      , 1 SMO_EXTOURNE_MVT
                   from STM_STOCK_MOVEMENT SMO
                      , DOC_POSITION_DETAIL PDE
                      , DOC_POSITION POS
                      , DOC_DOCUMENT DMT
                      , STM_MOVEMENT_KIND MOK
                      , GCO_PRODUCT PDT
                      , GCO_GOOD GOO
                  where POS.DOC_DOC_POSITION_ID = iPositionId
                    and POS.POS_GENERATE_MOVEMENT = 1
                    and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                    and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                    and SMO.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
                    and MOK.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID
                    and SMO.STM_MOVEMENT_KIND_ID = MOK.STM_STM_MOVEMENT_KIND_ID
                    and GOO.GCO_GOOD_ID = POS.GCO_GOOD_ID
                    and PDT.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID) )
      order by GCO_GOOD_ID
             , SMO_CHARACTERIZATION_VALUE_1
             , SMO_CHARACTERIZATION_VALUE_2
             , SMO_CHARACTERIZATION_VALUE_3
             , SMO_CHARACTERIZATION_VALUE_4
             , SMO_CHARACTERIZATION_VALUE_5;

    ltplSecondaryMovement lcurSecondaryMovement%rowtype;

    -- curseur sur les mouvements primaires
    cursor lcurMainMovement(iPositionId doc_position.doc_position_id%type)
    is
      select   *
          from ( (select STM_FUNCTIONS.GetPeriodExerciseId(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) ) STM_EXERCISE_ID
                       , STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) STM_PERIOD_ID
                       , SMO.STM_MOVEMENT_KIND_ID
                       , SMO.STM_STOCK_ID
                       , SMO.GCO_GOOD_ID
                       , DMT.DMT_DATE_DOCUMENT
                       , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT), DMT.DMT_DATE_DOCUMENT) SMO_MOVEMENT_DATE
                       , SMO.SMO_VALUE_DATE
                       , SMO.SMO_WORDING
                       , -least(ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 1 / power(10, GOO.GOO_NUMBER_OF_DECIMAL), 0)
                              , SMO.SMO_MOVEMENT_QUANTITY
                               ) SMO_MOVEMENT_QUANTITY
                       , -SMO.SMO_UNIT_PRICE *
                         least(ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 1 / power(10, GOO.GOO_NUMBER_OF_DECIMAL), 0)
                             , SMO.SMO_MOVEMENT_QUANTITY
                              ) SMO_MOVEMENT_PRICE
                       , -PDE.PDE_BALANCE_QUANTITY SMO_DOCUMENT_QUANTITY
                       , -(SMO_DOCUMENT_PRICE / decode(SMO_DOCUMENT_QUANTITY, 0, 1, SMO_DOCUMENT_QUANTITY) ) * PDE.PDE_BALANCE_QUANTITY SMO_DOCUMENT_PRICE
                       , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_1, 1, PDT.PDT_CONVERSION_FACTOR_1 * PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 0)
                                                                                                                                       SMO_MVT_ALTERNATIV_QTY_1
                       , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_2, 1, PDT.PDT_CONVERSION_FACTOR_2 * PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 0)
                                                                                                                                       SMO_MVT_ALTERNATIV_QTY_2
                       , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_3, 1, PDT.PDT_CONVERSION_FACTOR_3 * PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 0)
                                                                                                                                       SMO_MVT_ALTERNATIV_QTY_3
                       , SMO.SMO_REFERENCE_UNIT_PRICE
                       , SMO.SMO_UNIT_PRICE
                       , SMO.SMO_FINANCIAL_CHARGING
                       , sysdate A_DATECRE
                       , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
                       , PDE.DOC_POSITION_DETAIL_ID
                       , SMO.DOC_POSITION_ID
                       , SMO.STM_LOCATION_ID
                       , SMO.PAC_THIRD_ID
                       , SMO.PAC_THIRD_ACI_ID
                       , SMO.PAC_THIRD_DELIVERY_ID
                       , SMO.PAC_THIRD_TARIFF_ID
                       , SMO.DOC_RECORD_ID
                       , SMO.GCO_CHARACTERIZATION_ID
                       , SMO.SMO_CHARACTERIZATION_VALUE_1
                       , SMO.GCO_GCO_CHARACTERIZATION_ID
                       , SMO.SMO_CHARACTERIZATION_VALUE_2
                       , SMO.GCO2_GCO_CHARACTERIZATION_ID
                       , SMO.SMO_CHARACTERIZATION_VALUE_3
                       , SMO.GCO3_GCO_CHARACTERIZATION_ID
                       , SMO.SMO_CHARACTERIZATION_VALUE_4
                       , SMO.GCO4_GCO_CHARACTERIZATION_ID
                       , SMO.SMO_CHARACTERIZATION_VALUE_5
                       , SMO.ACS_FINANCIAL_ACCOUNT_ID
                       , SMO.ACS_DIVISION_ACCOUNT_ID
                       , SMO.ACS_ACS_FINANCIAL_ACCOUNT_ID
                       , SMO.ACS_ACS_DIVISION_ACCOUNT_ID
                       , SMO.ACS_CPN_ACCOUNT_ID
                       , SMO.ACS_ACS_CPN_ACCOUNT_ID
                       , SMO.ACS_CDA_ACCOUNT_ID
                       , SMO.ACS_ACS_CDA_ACCOUNT_ID
                       , SMO.ACS_PF_ACCOUNT_ID
                       , SMO.ACS_ACS_PF_ACCOUNT_ID
                       , SMO.ACS_PJ_ACCOUNT_ID
                       , SMO.ACS_ACS_PJ_ACCOUNT_ID
                       , SMO.FAM_FIXED_ASSETS_ID
                       , SMO.C_FAM_TRANSACTION_TYP
                       , SMO.HRM_PERSON_ID
                       , SMO.DIC_IMP_FREE1_ID
                       , SMO.DIC_IMP_FREE2_ID
                       , SMO.DIC_IMP_FREE3_ID
                       , SMO.DIC_IMP_FREE4_ID
                       , SMO.DIC_IMP_FREE5_ID
                       , SMO.SMO_IMP_TEXT_1
                       , SMO.SMO_IMP_TEXT_2
                       , SMO.SMO_IMP_TEXT_3
                       , SMO.SMO_IMP_TEXT_4
                       , SMO.SMO_IMP_TEXT_5
                       , SMO.SMO_IMP_NUMBER_1
                       , SMO.SMO_IMP_NUMBER_2
                       , SMO.SMO_IMP_NUMBER_3
                       , SMO.SMO_IMP_NUMBER_4
                       , SMO.SMO_IMP_NUMBER_5
                       , 0 SMO_UPDATE_PROV
                       , 1 SMO_EXTOURNE_MVT
                    from STM_STOCK_MOVEMENT SMO
                       , DOC_POSITION_DETAIL PDE
                       , DOC_POSITION POS
                       , DOC_DOCUMENT DMT
                       , GCO_PRODUCT PDT
                       , GCO_GOOD GOO
                   where PDE.DOC_POSITION_ID = iPositionId
                     and POS.POS_GENERATE_MOVEMENT = 1
                     and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                     and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                     and SMO.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
                     and SMO.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID
                     and GOO.GCO_GOOD_ID = POS.GCO_GOOD_ID
                     and PDT.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID)
                union all
                (select STM_FUNCTIONS.GetPeriodExerciseId(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) ) STM_EXERCISE_ID
                      , STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) STM_PERIOD_ID
                      , SMO.STM_MOVEMENT_KIND_ID
                      , SMO.STM_STOCK_ID
                      , SMO.GCO_GOOD_ID
                      , DMT.DMT_DATE_DOCUMENT
                      , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT), DMT.DMT_DATE_DOCUMENT) SMO_MOVEMENT_DATE
                      , SMO.SMO_VALUE_DATE
                      , SMO.SMO_WORDING
                      , -least(ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 1 / power(10, GOO.GOO_NUMBER_OF_DECIMAL), 0)
                             , SMO.SMO_MOVEMENT_QUANTITY
                              ) SMO_MOVEMENT_QUANTITY
                      , -SMO.SMO_UNIT_PRICE *
                        least(ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 1 / power(10, GOO.GOO_NUMBER_OF_DECIMAL), 0)
                            , SMO.SMO_MOVEMENT_QUANTITY
                             ) SMO_MOVEMENT_PRICE
                      , -PDE.PDE_BALANCE_QUANTITY SMO_DOCUMENT_QUANTITY
                      , -(SMO_DOCUMENT_PRICE / decode(SMO_DOCUMENT_QUANTITY, 0, 1, SMO_DOCUMENT_QUANTITY) ) * PDE.PDE_BALANCE_QUANTITY SMO_DOCUMENT_PRICE
                      , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_1, 1, PDT.PDT_CONVERSION_FACTOR_1 * PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 0)
                                                                                                                                       SMO_MVT_ALTERNATIV_QTY_1
                      , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_2, 1, PDT.PDT_CONVERSION_FACTOR_2 * PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 0)
                                                                                                                                       SMO_MVT_ALTERNATIV_QTY_2
                      , -decode(PDT.PDT_ALTERNATIVE_QUANTITY_3, 1, PDT.PDT_CONVERSION_FACTOR_3 * PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 0)
                                                                                                                                       SMO_MVT_ALTERNATIV_QTY_3
                      , SMO.SMO_REFERENCE_UNIT_PRICE
                      , SMO.SMO_UNIT_PRICE
                      , SMO.SMO_FINANCIAL_CHARGING
                      , sysdate A_DATECRE
                      , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
                      , PDE.DOC_POSITION_DETAIL_ID
                      , SMO.DOC_POSITION_ID
                      , SMO.STM_LOCATION_ID
                      , SMO.PAC_THIRD_ID
                      , SMO.PAC_THIRD_ACI_ID
                      , SMO.PAC_THIRD_DELIVERY_ID
                      , SMO.PAC_THIRD_TARIFF_ID
                      , SMO.DOC_RECORD_ID
                      , SMO.GCO_CHARACTERIZATION_ID
                      , SMO.SMO_CHARACTERIZATION_VALUE_1
                      , SMO.GCO_GCO_CHARACTERIZATION_ID
                      , SMO.SMO_CHARACTERIZATION_VALUE_2
                      , SMO.GCO2_GCO_CHARACTERIZATION_ID
                      , SMO.SMO_CHARACTERIZATION_VALUE_3
                      , SMO.GCO3_GCO_CHARACTERIZATION_ID
                      , SMO.SMO_CHARACTERIZATION_VALUE_4
                      , SMO.GCO4_GCO_CHARACTERIZATION_ID
                      , SMO.SMO_CHARACTERIZATION_VALUE_5
                      , SMO.ACS_FINANCIAL_ACCOUNT_ID
                      , SMO.ACS_DIVISION_ACCOUNT_ID
                      , SMO.ACS_ACS_FINANCIAL_ACCOUNT_ID
                      , SMO.ACS_ACS_DIVISION_ACCOUNT_ID
                      , SMO.ACS_CPN_ACCOUNT_ID
                      , SMO.ACS_ACS_CPN_ACCOUNT_ID
                      , SMO.ACS_CDA_ACCOUNT_ID
                      , SMO.ACS_ACS_CDA_ACCOUNT_ID
                      , SMO.ACS_PF_ACCOUNT_ID
                      , SMO.ACS_ACS_PF_ACCOUNT_ID
                      , SMO.ACS_PJ_ACCOUNT_ID
                      , SMO.ACS_ACS_PJ_ACCOUNT_ID
                      , SMO.FAM_FIXED_ASSETS_ID
                      , SMO.C_FAM_TRANSACTION_TYP
                      , SMO.HRM_PERSON_ID
                      , SMO.DIC_IMP_FREE1_ID
                      , SMO.DIC_IMP_FREE2_ID
                      , SMO.DIC_IMP_FREE3_ID
                      , SMO.DIC_IMP_FREE4_ID
                      , SMO.DIC_IMP_FREE5_ID
                      , SMO.SMO_IMP_TEXT_1
                      , SMO.SMO_IMP_TEXT_2
                      , SMO.SMO_IMP_TEXT_3
                      , SMO.SMO_IMP_TEXT_4
                      , SMO.SMO_IMP_TEXT_5
                      , SMO.SMO_IMP_NUMBER_1
                      , SMO.SMO_IMP_NUMBER_2
                      , SMO.SMO_IMP_NUMBER_3
                      , SMO.SMO_IMP_NUMBER_4
                      , SMO.SMO_IMP_NUMBER_5
                      , 0 SMO_UPDATE_PROV
                      , 1 SMO_EXTOURNE_MVT
                   from STM_STOCK_MOVEMENT SMO
                      , DOC_POSITION_DETAIL PDE
                      , DOC_POSITION POS
                      , DOC_DOCUMENT DMT
                      , GCO_PRODUCT PDT
                      , GCO_GOOD GOO
                  where POS.DOC_DOC_POSITION_ID = iPositionId
                    and POS.POS_GENERATE_MOVEMENT = 1
                    and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                    and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                    and SMO.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
                    and SMO.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID
                    and GOO.GCO_GOOD_ID = POS.GCO_GOOD_ID
                    and PDT.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID) )
      order by GCO_GOOD_ID
             , SMO_CHARACTERIZATION_VALUE_1
             , SMO_CHARACTERIZATION_VALUE_2
             , SMO_CHARACTERIZATION_VALUE_3
             , SMO_CHARACTERIZATION_VALUE_4
             , SMO_CHARACTERIZATION_VALUE_5;

    ltplMainMovement      lcurMainMovement%rowtype;
    lStockMovementId      STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
  begin
    -- extourne des mouvements de transfert  (mouvement lié, obligatoirement le mouvement de sortie)
    -- y compris pour les éventuels composants de la position
    open lcurSecondaryMovement(iPositionId);

    fetch lcurSecondaryMovement
     into ltplSecondaryMovement;

    while lcurSecondaryMovement%found loop
      lStockMovementId  := null;
      STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => lStockMovementId
                                      , iGoodId                => ltplSecondaryMovement.GCO_GOOD_ID
                                      , iMovementKindId        => ltplSecondaryMovement.STM_MOVEMENT_KIND_ID
                                      , iExerciseId            => ltplSecondaryMovement.STM_EXERCISE_ID
                                      , iPeriodId              => ltplSecondaryMovement.STM_PERIOD_ID
                                      , iMvtDate               => ltplSecondaryMovement.SMO_MOVEMENT_DATE
                                      , iValueDate             => ltplSecondaryMovement.SMO_VALUE_DATE
                                      , iStockId               => ltplSecondaryMovement.STM_STOCK_ID
                                      , iLocationId            => ltplSecondaryMovement.STM_LOCATION_ID
                                      , iThirdId               => ltplSecondaryMovement.PAC_THIRD_ID
                                      , iThirdAciId            => ltplSecondaryMovement.PAC_THIRD_ACI_ID
                                      , iThirdDeliveryId       => ltplSecondaryMovement.PAC_THIRD_DELIVERY_ID
                                      , iThirdTariffId         => ltplSecondaryMovement.PAC_THIRD_TARIFF_ID
                                      , iRecordId              => ltplSecondaryMovement.DOC_RECORD_ID
                                      , iChar1Id               => ltplSecondaryMovement.GCO_CHARACTERIZATION_ID
                                      , iChar2Id               => ltplSecondaryMovement.GCO_GCO_CHARACTERIZATION_ID
                                      , iChar3Id               => ltplSecondaryMovement.GCO2_GCO_CHARACTERIZATION_ID
                                      , iChar4Id               => ltplSecondaryMovement.GCO3_GCO_CHARACTERIZATION_ID
                                      , iChar5Id               => ltplSecondaryMovement.GCO4_GCO_CHARACTERIZATION_ID
                                      , iCharValue1            => ltplSecondaryMovement.SMO_CHARACTERIZATION_VALUE_1
                                      , iCharValue2            => ltplSecondaryMovement.SMO_CHARACTERIZATION_VALUE_2
                                      , iCharValue3            => ltplSecondaryMovement.SMO_CHARACTERIZATION_VALUE_3
                                      , iCharValue4            => ltplSecondaryMovement.SMO_CHARACTERIZATION_VALUE_4
                                      , iCharValue5            => ltplSecondaryMovement.SMO_CHARACTERIZATION_VALUE_5
                                      , iMovement2Id           => null   -- STM_STOCK_MOVEMENT.STM_STM_STOCK_MOVEMENT_ID%type,
                                      , iMovement3Id           => null   -- STM_STOCK_MOVEMENT.STM2_STM_STOCK_MOVEMENT_ID%type,
                                      , iWording               => ltplSecondaryMovement.SMO_WORDING
                                      , iExternalDocument      => null   --STM_STOCK_MOVEMENT.SMO_EXTERNAL_DOCUMENT%type,
                                      , iExternalPartner       => null   --STM_STOCK_MOVEMENT.SMO_EXTERNAL_PARTNER%type,
                                      , iMvtQty                => ltplSecondaryMovement.SMO_MOVEMENT_QUANTITY
                                      , iMvtPrice              => ltplSecondaryMovement.SMO_MOVEMENT_PRICE
                                      , iDocQty                => ltplSecondaryMovement.SMO_DOCUMENT_QUANTITY
                                      , iDocPrice              => ltplSecondaryMovement.SMO_DOCUMENT_PRICE
                                      , iUnitPrice             => ltplSecondaryMovement.SMO_UNIT_PRICE
                                      , iRefUnitPrice          => ltplSecondaryMovement.SMO_REFERENCE_UNIT_PRICE
                                      , iAltQty1               => ltplSecondaryMovement.SMO_ALTERNATIVE_QUANTITY_1
                                      , iAltQty2               => ltplSecondaryMovement.SMO_ALTERNATIVE_QUANTITY_2
                                      , iAltQty3               => ltplSecondaryMovement.SMO_ALTERNATIVE_QUANTITY_3
                                      , iDocPositionDetailId   => ltplSecondaryMovement.DOC_POSITION_DETAIL_ID
                                      , iDocPositionId         => ltplSecondaryMovement.DOC_POSITION_ID
                                      , iFinancialAccountId    => ltplSecondaryMovement.ACS_FINANCIAL_ACCOUNT_ID
                                      , iDivisionAccountId     => ltplSecondaryMovement.ACS_DIVISION_ACCOUNT_ID
                                      , iAFinancialAccountId   => ltplSecondaryMovement.ACS_ACS_FINANCIAL_ACCOUNT_ID
                                      , iADivisionAccountId    => ltplSecondaryMovement.ACS_ACS_DIVISION_ACCOUNT_ID
                                      , iCPNAccountId          => ltplSecondaryMovement.ACS_CPN_ACCOUNT_ID
                                      , iACPNAccountId         => ltplSecondaryMovement.ACS_ACS_CPN_ACCOUNT_ID
                                      , iCDAAccountId          => ltplSecondaryMovement.ACS_CDA_ACCOUNT_ID
                                      , iACDAAccountId         => ltplSecondaryMovement.ACS_ACS_CDA_ACCOUNT_ID
                                      , iPFAccountId           => ltplSecondaryMovement.ACS_PF_ACCOUNT_ID
                                      , iAPFAccountId          => ltplSecondaryMovement.ACS_ACS_PF_ACCOUNT_ID
                                      , iPJAccountId           => ltplSecondaryMovement.ACS_PJ_ACCOUNT_ID
                                      , iAPJAccountId          => ltplSecondaryMovement.ACS_ACS_PJ_ACCOUNT_ID
                                      , iFamFixedAssetsId      => null   -- iFamFixedAssetsId in STM_STOCK_MOVEMENT.FAM_FIXED_ASSETS_ID%type,
                                      , iFamTransactionTyp     => null   -- iFamTransactionTyp in STM_STOCK_MOVEMENT.C_FAM_TRANSACTION_TYP%type,
                                      , iHrmPersonId           => null   -- iHrmPersonId in STM_STOCK_MOVEMENT.HRM_PERSON_ID%type,
                                      , iDicImpfree1Id         => null   -- iDicImpfree1Id in STM_STOCK_MOVEMENT.DIC_IMP_FREE1_ID%type,
                                      , iDicImpfree2Id         => null   -- iDicImpfree2Id in STM_STOCK_MOVEMENT.DIC_IMP_FREE2_ID%type,
                                      , iDicImpfree3Id         => null   -- iDicImpfree3Id in STM_STOCK_MOVEMENT.DIC_IMP_FREE3_ID%type,
                                      , iDicImpfree4Id         => null   -- iDicImpfree4Id in STM_STOCK_MOVEMENT.DIC_IMP_FREE4_ID%type,
                                      , iDicImpfree5Id         => null   -- iDicImpfree5Id in STM_STOCK_MOVEMENT.DIC_IMP_FREE5_ID%type,
                                      , iImpText1              => null   -- iImpText1 in STM_STOCK_MOVEMENT.SMO_IMP_TEXT_1%type,
                                      , iImpText2              => null   -- iImpText2 in STM_STOCK_MOVEMENT.SMO_IMP_TEXT_2%type,
                                      , iImpText3              => null   -- iImpText3 in STM_STOCK_MOVEMENT.SMO_IMP_TEXT_3%type,
                                      , iImpText4              => null   -- iImpText4 in STM_STOCK_MOVEMENT.SMO_IMP_TEXT_4%type,
                                      , iImpText5              => null   -- iImpText5 in STM_STOCK_MOVEMENT.SMO_IMP_TEXT_5%type,
                                      , iImpNumber1            => null   -- iImpNumber1 in STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_1%type,
                                      , iImpNumber2            => null   -- iImpNumber2 in STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_2%type,
                                      , iImpNumber3            => null   -- iImpNumber3 in STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_3%type,
                                      , iImpNumber4            => null   -- iImpNumber4 in STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_4%type,
                                      , iImpNumber5            => null   -- iImpNumber5 in STM_STOCK_MOVEMENT.SMO_IMP_NUMBER_5%type,
                                      , iFinancialCharging     => ltplSecondaryMovement.SMO_FINANCIAL_CHARGING
                                      , iUpdateProv            => 0   -- STM_STOCK_MOVEMENT.SMO_UPDATE_PROV%type,
                                      , iExtourneMvt           => 1   -- STM_STOCK_MOVEMENT.SMO_EXTOURNE_MVT%type,
                                      , iRecStatus             => null   -- STM_STOCK_MOVEMENT.A_RECSTATUS%type
                                       );

      fetch lcurSecondaryMovement
       into ltplSecondaryMovement;
    end loop;

    close lcurSecondaryMovement;

    -- extournes des mouvements principaux (obligatoirement mouvement d'entrée dans le cas d'un transfert)
    -- y compris pour les éventuels composants de la position
    open lcurMainMovement(iPositionId);

    fetch lcurMainMovement
     into ltplMainMovement;

    while lcurMainMovement%found loop
      lStockMovementId  := null;
      STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => lStockMovementId
                                      , iGoodId                => ltplMainMovement.GCO_GOOD_ID
                                      , iMovementKindId        => ltplMainMovement.STM_MOVEMENT_KIND_ID
                                      , iExerciseId            => ltplMainMovement.STM_EXERCISE_ID
                                      , iPeriodId              => ltplMainMovement.STM_PERIOD_ID
                                      , iMvtDate               => ltplMainMovement.SMO_MOVEMENT_DATE
                                      , iValueDate             => ltplMainMovement.SMO_VALUE_DATE
                                      , iStockId               => ltplMainMovement.STM_STOCK_ID
                                      , iLocationId            => ltplMainMovement.STM_LOCATION_ID
                                      , iThirdId               => ltplMainMovement.PAC_THIRD_ID
                                      , iThirdAciId            => ltplMainMovement.PAC_THIRD_ACI_ID
                                      , iThirdDeliveryId       => ltplMainMovement.PAC_THIRD_DELIVERY_ID
                                      , iThirdTariffId         => ltplMainMovement.PAC_THIRD_TARIFF_ID
                                      , iRecordId              => ltplMainMovement.DOC_RECORD_ID
                                      , iChar1Id               => ltplMainMovement.GCO_CHARACTERIZATION_ID
                                      , iChar2Id               => ltplMainMovement.GCO_GCO_CHARACTERIZATION_ID
                                      , iChar3Id               => ltplMainMovement.GCO2_GCO_CHARACTERIZATION_ID
                                      , iChar4Id               => ltplMainMovement.GCO3_GCO_CHARACTERIZATION_ID
                                      , iChar5Id               => ltplMainMovement.GCO4_GCO_CHARACTERIZATION_ID
                                      , iCharValue1            => ltplMainMovement.SMO_CHARACTERIZATION_VALUE_1
                                      , iCharValue2            => ltplMainMovement.SMO_CHARACTERIZATION_VALUE_2
                                      , iCharValue3            => ltplMainMovement.SMO_CHARACTERIZATION_VALUE_3
                                      , iCharValue4            => ltplMainMovement.SMO_CHARACTERIZATION_VALUE_4
                                      , iCharValue5            => ltplMainMovement.SMO_CHARACTERIZATION_VALUE_5
                                      , iMovement2Id           => null   -- STM_STOCK_MOVEMENT.STM_STM_STOCK_MOVEMENT_ID%type,
                                      , iMovement3Id           => null   -- STM_STOCK_MOVEMENT.STM2_STM_STOCK_MOVEMENT_ID%type,
                                      , iWording               => ltplMainMovement.SMO_WORDING
                                      , iExternalDocument      => null   --STM_STOCK_MOVEMENT.SMO_EXTERNAL_DOCUMENT%type,
                                      , iExternalPartner       => null   --STM_STOCK_MOVEMENT.SMO_EXTERNAL_PARTNER%type,
                                      , iMvtQty                => ltplMainMovement.SMO_MOVEMENT_QUANTITY
                                      , iMvtPrice              => ltplMainMovement.SMO_MOVEMENT_PRICE
                                      , iDocQty                => ltplMainMovement.SMO_DOCUMENT_QUANTITY
                                      , iDocPrice              => ltplMainMovement.SMO_DOCUMENT_PRICE
                                      , iUnitPrice             => ltplMainMovement.SMO_UNIT_PRICE
                                      , iRefUnitPrice          => ltplMainMovement.SMO_REFERENCE_UNIT_PRICE
                                      , iAltQty1               => ltplMainMovement.SMO_MVT_ALTERNATIV_QTY_1
                                      , iAltQty2               => ltplMainMovement.SMO_MVT_ALTERNATIV_QTY_2
                                      , iAltQty3               => ltplMainMovement.SMO_MVT_ALTERNATIV_QTY_3
                                      , iDocPositionDetailId   => ltplMainMovement.DOC_POSITION_DETAIL_ID
                                      , iDocPositionId         => ltplMainMovement.DOC_POSITION_ID
                                      , iFinancialAccountId    => ltplMainMovement.ACS_FINANCIAL_ACCOUNT_ID
                                      , iDivisionAccountId     => ltplMainMovement.ACS_DIVISION_ACCOUNT_ID
                                      , iAFinancialAccountId   => ltplMainMovement.ACS_ACS_FINANCIAL_ACCOUNT_ID
                                      , iADivisionAccountId    => ltplMainMovement.ACS_ACS_DIVISION_ACCOUNT_ID
                                      , iCPNAccountId          => ltplMainMovement.ACS_CPN_ACCOUNT_ID
                                      , iACPNAccountId         => ltplMainMovement.ACS_ACS_CPN_ACCOUNT_ID
                                      , iCDAAccountId          => ltplMainMovement.ACS_CDA_ACCOUNT_ID
                                      , iACDAAccountId         => ltplMainMovement.ACS_ACS_CDA_ACCOUNT_ID
                                      , iPFAccountId           => ltplMainMovement.ACS_PF_ACCOUNT_ID
                                      , iAPFAccountId          => ltplMainMovement.ACS_ACS_PF_ACCOUNT_ID
                                      , iPJAccountId           => ltplMainMovement.ACS_PJ_ACCOUNT_ID
                                      , iAPJAccountId          => ltplMainMovement.ACS_ACS_PJ_ACCOUNT_ID
                                      , iFamFixedAssetsId      => ltplMainMovement.FAM_FIXED_ASSETS_ID
                                      , iFamTransactionTyp     => ltplMainMovement.C_FAM_TRANSACTION_TYP
                                      , iHrmPersonId           => ltplMainMovement.HRM_PERSON_ID
                                      , iDicImpfree1Id         => ltplMainMovement.DIC_IMP_FREE1_ID
                                      , iDicImpfree2Id         => ltplMainMovement.DIC_IMP_FREE2_ID
                                      , iDicImpfree3Id         => ltplMainMovement.DIC_IMP_FREE3_ID
                                      , iDicImpfree4Id         => ltplMainMovement.DIC_IMP_FREE4_ID
                                      , iDicImpfree5Id         => ltplMainMovement.DIC_IMP_FREE5_ID
                                      , iImpText1              => ltplMainMovement.SMO_IMP_TEXT_1
                                      , iImpText2              => ltplMainMovement.SMO_IMP_TEXT_2
                                      , iImpText3              => ltplMainMovement.SMO_IMP_TEXT_3
                                      , iImpText4              => ltplMainMovement.SMO_IMP_TEXT_4
                                      , iImpText5              => ltplMainMovement.SMO_IMP_TEXT_5
                                      , iImpNumber1            => ltplMainMovement.SMO_IMP_NUMBER_1
                                      , iImpNumber2            => ltplMainMovement.SMO_IMP_NUMBER_2
                                      , iImpNumber3            => ltplMainMovement.SMO_IMP_NUMBER_3
                                      , iImpNumber4            => ltplMainMovement.SMO_IMP_NUMBER_4
                                      , iImpNumber5            => ltplMainMovement.SMO_IMP_NUMBER_5
                                      , iFinancialCharging     => ltplMainMovement.SMO_FINANCIAL_CHARGING
                                      , iUpdateProv            => 0   -- STM_STOCK_MOVEMENT.SMO_UPDATE_PROV%type,
                                      , iExtourneMvt           => 1   -- STM_STOCK_MOVEMENT.SMO_EXTOURNE_MVT%type,
                                      , iRecStatus             => null   -- STM_STOCK_MOVEMENT.A_RECSTATUS%type
                                       );

      fetch lcurMainMovement
       into ltplMainMovement;
    end loop;

    close lcurMainMovement;

    update DOC_POSITION_DETAIL PDE
       set PDE.PDE_GENERATE_MOVEMENT = 1
         , PDE.PDE_MOVEMENT_DATE =
             nvl(PDE.PDE_MOVEMENT_DATE
               , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(ltplMainMovement.DMT_DATE_DOCUMENT), ltplMainMovement.DMT_DATE_DOCUMENT)
                )
         , PDE.A_DATEMOD = sysdate
         , PDE.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where PDE.DOC_POSITION_ID = iPositionId
       and exists(select POS.STM_MOVEMENT_KIND_ID
                    from DOC_POSITION POS
                   where POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                     and POS.STM_MOVEMENT_KIND_ID is not null);

    update DOC_POSITION POS
       set POS.POS_GENERATE_MOVEMENT = 1
         , POS.A_DATEMOD = sysdate
         , POS.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where POS.DOC_POSITION_ID = iPositionId
       and POS.STM_MOVEMENT_KIND_ID is not null;
  end SoldePosExtourneMovements;

  /**
  * Description  Procedure appelée depuis le trigger d'insertion des mouvements
  *              de stock. Elle met à jour la table des cartes de garantie
  *              ASA_GUARANTY_CARDS.
  */
  procedure InsertGuarantyCards(itMovementRecord in out FWK_TYP_STM_ENTITY.tStockMovement)
  is
    lDistributionMode PCS.PC_CBASE.CBACNAME%type;
  begin
    /* Le remplissage est autorisé que si la configuration + le genre de
       mouvement + le bien le permettent. */
    if (PCS.PC_CONFIG.GetConfig('ASA_GUARANTY_MANAGEMENT') = '1') then
      lDistributionMode  := nvl(PCS.PC_CONFIG.GetConfig('ASA_DISTRIBUTION_MODE'), '0');

      /*
      Cicuit de distribution :
      1: Vente à l'agent
         Vente au détaillant
         Vente au client final
      2: Vente au détaillant
         Vente au client final
      3: Vente directe au client final
      */
      insert into ASA_GUARANTY_CARDS
                  (ASA_GUARANTY_CARDS_ID
                 , AGC_NUMBER
                 , GCO_GOOD_ID
                 , GCO_CHAR1_ID
                 , GCO_CHAR2_ID
                 , GCO_CHAR3_ID
                 , GCO_CHAR4_ID
                 , GCO_CHAR5_ID
                 , AGC_CHAR1_VALUE
                 , AGC_CHAR2_VALUE
                 , AGC_CHAR3_VALUE
                 , AGC_CHAR4_VALUE
                 , AGC_CHAR5_VALUE
                 , PAC_ASA_AGENT_ID
                 , PC_ASA_AGENT_LANG_ID
                 , PAC_ASA_AGENT_ADDR_ID
                 , AGC_ADDRESS_AGENT
                 , AGC_POSTCODE_AGENT
                 , AGC_TOWN_AGENT
                 , AGC_STATE_AGENT
                 , AGC_FORMAT_CITY_AGENT
                 , PC_ASA_AGENT_CNTRY_ID
                 , AGC_SALEDATE_AGENT
                 , PAC_ASA_DISTRIB_ID
                 , PC_ASA_DISTRIB_LANG_ID
                 , PAC_ASA_DISTRIB_ADDR_ID
                 , AGC_ADDRESS_DISTRIB
                 , AGC_POSTCODE_DISTRIB
                 , AGC_TOWN_DISTRIB
                 , AGC_STATE_DISTRIB
                 , AGC_FORMAT_CITY_DISTRIB
                 , PC_ASA_DISTRIB_CNTRY_ID
                 , AGC_SALEDATE_DET
                 , PAC_ASA_FIN_CUST_ID
                 , PC_ASA_FIN_CUST_LANG_ID
                 , PAC_ASA_FIN_CUST_ADDR_ID
                 , AGC_ADDRESS_FIN_CUST
                 , AGC_POSTCODE_FIN_CUST
                 , AGC_TOWN_FIN_CUST
                 , AGC_STATE_FIN_CUST
                 , AGC_FORMAT_CITY_FIN_CUST
                 , PC_ASA_FIN_CUST_CNTRY_ID
                 , AGC_SALEDATE
                 , AGC_BEGIN
                 , AGC_DAYS
                 , C_ASA_GUARANTY_UNIT
                 , DOC_POSITION_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select init_id_seq.nextval   -- ASA_GUARANTY_CARDS_ID
             , substr(DMT.DMT_NUMBER, 1, 15) || '/' || lpad(to_char(POS.POS_NUMBER), 5, '0') || '/'
               || lpad(to_char(asa_guaranty_seq.nextval), 8, '0')   -- AGC_NUMBER
             , itMovementRecord.GCO_GOOD_ID
             , PDE.GCO_CHARACTERIZATION_ID
             , PDE.GCO_GCO_CHARACTERIZATION_ID
             , PDE.GCO2_GCO_CHARACTERIZATION_ID
             , PDE.GCO3_GCO_CHARACTERIZATION_ID
             , PDE.GCO4_GCO_CHARACTERIZATION_ID
             , PDE.PDE_CHARACTERIZATION_VALUE_1
             , PDE.PDE_CHARACTERIZATION_VALUE_2
             , PDE.PDE_CHARACTERIZATION_VALUE_3
             , PDE.PDE_CHARACTERIZATION_VALUE_4
             , PDE.PDE_CHARACTERIZATION_VALUE_5
             , decode(lDistributionMode, '1', itMovementRecord.PAC_THIRD_ID, null)   -- PAC_ASA_AGENT_ID
             , decode(lDistributionMode, '1', DMT.PC_LANG_ID, null)   -- PC_ASA_AGENT_LANG_ID
             , decode(lDistributionMode, '1', DMT.PAC_ADDRESS_ID, null)   -- PAC_ASA_AGENT_ADDR_ID
             , decode(lDistributionMode, '1', DMT.DMT_ADDRESS1, null)   -- AGC_ADDRESS_AGENT
             , decode(lDistributionMode, '1', DMT.DMT_POSTCODE1, null)   -- AGC_POSTCODE_AGENT
             , decode(lDistributionMode, '1', DMT.DMT_TOWN1, null)   -- AGC_TOWN_AGENT
             , decode(lDistributionMode, '1', DMT.DMT_STATE1, null)   -- AGC_STATE_AGENT
             , decode(lDistributionMode, '1', DMT.DMT_FORMAT_CITY1, null)   -- AGC_FORMAT_CITY_AGENT
             , decode(lDistributionMode, '1', DMT.PC_CNTRY_ID, null)   -- PC_ASA_AGENT_CNTRY_ID
             , decode(lDistributionMode, '1', DMT.DMT_DATE_DOCUMENT, null)   -- AGC_SALEDATE_AGENT
             , decode(lDistributionMode, '2', itMovementRecord.PAC_THIRD_ID, null)   -- PAC_ASA_DISTRIB_ID
             , decode(lDistributionMode, '2', DMT.PC_LANG_ID, null)   -- PC_ASA_DISTRIB_LANG_ID
             , decode(lDistributionMode, '2', DMT.PAC_ADDRESS_ID, null)   -- PAC_ASA_DISTRIB_ADDR_ID
             , decode(lDistributionMode, '2', DMT.DMT_ADDRESS1, null)   -- AGC_ADDRESS_DISTRIB
             , decode(lDistributionMode, '2', DMT.DMT_POSTCODE1, null)   -- AGC_POSTCODE_DISTRIB
             , decode(lDistributionMode, '2', DMT.DMT_TOWN1, null)   -- AGC_TOWN_DISTRIB
             , decode(lDistributionMode, '2', DMT.DMT_STATE1, null)   -- AGC_STATE_DISTRIB
             , decode(lDistributionMode, '2', DMT.DMT_FORMAT_CITY1, null)   -- AGC_FORMAT_CITY_DISTRIB
             , decode(lDistributionMode, '2', DMT.PC_CNTRY_ID, null)   -- PC_ASA_DISTRIB_CNTRY_ID
             , decode(lDistributionMode, '2', DMT.DMT_DATE_DOCUMENT, null)   -- AGC_SALEDATE_DET
             , decode(lDistributionMode, '3', itMovementRecord.PAC_THIRD_ID, null)   -- PAC_ASA_FIN_CUST_ID
             , decode(lDistributionMode, '3', DMT.PC_LANG_ID, null)   -- PC_ASA_FIN_CUST_LANG_ID
             , decode(lDistributionMode, '3', DMT.PAC_ADDRESS_ID, null)   -- PAC_ASA_FIN_CUST_ADDR_ID
             , decode(lDistributionMode, '3', DMT.DMT_ADDRESS1, null)   -- AGC_ADDRESS_FIN_CUST
             , decode(lDistributionMode, '3', DMT.DMT_POSTCODE1, null)   -- AGC_POSTCODE_FIN_CUST
             , decode(lDistributionMode, '3', DMT.DMT_TOWN1, null)   -- AGC_TOWN_FIN_CUST
             , decode(lDistributionMode, '3', DMT.DMT_STATE1, null)   -- AGC_STATE_FIN_CUST
             , decode(lDistributionMode, '3', DMT.DMT_FORMAT_CITY1, null)   -- AGC_FORMAT_CITY_FIN_CUST
             , decode(lDistributionMode, '3', DMT.PC_CNTRY_ID, null)   -- PC_ASA_FIN_CUST_CNTRY_ID
             , decode(lDistributionMode, '3', DMT.DMT_DATE_DOCUMENT, null)   -- AGC_SALEDATE
             , decode(lDistributionMode, '3', DMT.DMT_DATE_DOCUMENT, null)   -- AGC_BEGIN
             , ASA.CAS_GUARANTEE_DELAY
             , ASA.C_ASA_GUARANTY_UNIT
             , POS.DOC_POSITION_ID
             , sysdate   -- A_DATECRE
             , PCS.PC_I_LIB_SESSION.GetUserIni   -- A_IDCRE
          from DOC_DOCUMENT DMT
             , DOC_POSITION POS
             , DOC_POSITION_DETAIL PDE
             , STM_MOVEMENT_KIND MOK
             , GCO_PRODUCT PDT
             , GCO_COMPL_DATA_ASS ASA
         where PDT.GCO_GOOD_ID = itMovementRecord.GCO_GOOD_ID
           and PDT.PDT_GUARANTY_USE = 1
           and MOK.STM_MOVEMENT_KIND_ID = itMovementRecord.STM_MOVEMENT_KIND_ID
           and MOK_GUARANTY_USE = 1
           and PDE.DOC_POSITION_DETAIL_ID = itMovementRecord.DOC_POSITION_DETAIL_ID
           and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
           and DMT.DOC_DOCUMENT_ID = PDE.DOC_DOCUMENT_ID
           and PDT.GCO_GOOD_ID = ASA.GCO_GOOD_ID(+)
           and ASA.ASA_REP_TYPE_ID is null;
    end if;
  end InsertGuarantyCards;

  /**
  * Description
  *   Génération des mouvements sur les matières précieuses du pied de document
  */
  procedure DocFootAlloyMovements(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    -- Informations sur les matières précieuses sur le pied de document
    cursor lcurFootAlloy(iDocumentID in number, iDefStockID in number, iMngtMode in varchar2)
    is
      select   DFA.DOC_FOOT_ALLOY_ID
             , GAL.GCO_GOOD_ID
             , (DMT.DMT_NUMBER || ' / ' || decode(iMngtMode, '1', GAL.GAL_ALLOY_REF, DFA.DIC_BASIS_MATERIAL_ID) ) SMO_WORDING
             , LOC.STM_STOCK_ID
             , LOC.STM_LOCATION_ID
             , DOC_FOOT_ALLOY_FUNCTIONS.GetAdvanceWeight(iDocumentID, null, null, DFA.DFA_WEIGHT_DELIVERY, DFA.DFA_LOSS, DFA.DFA_WEIGHT_INVEST)
                                                                                                                                          SMO_MOVEMENT_QUANTITY
             , DFA.DFA_AMOUNT SMO_MOVEMENT_PRICE
          from DOC_DOCUMENT DMT
             , DOC_FOOT_ALLOY DFA
             , STM_LOCATION LOC
             , GCO_ALLOY GAL
         where DMT.DOC_DOCUMENT_ID = iDocumentID
           and DFA.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID
           and LOC.STM_STOCK_ID = DFA.STM_STOCK_ID
           and LOC.LOC_CLASSIFICATION = (select min(LOC_CLASSIFICATION)
                                           from STM_LOCATION
                                          where STM_STOCK_ID = LOC.STM_STOCK_ID)
           and (    (     (iMngtMode = '1')
                     and (DFA.GCO_ALLOY_ID is not null) )
                or (     (iMngtMode = '2')
                    and (DFA.DIC_BASIS_MATERIAL_ID is not null) ) )
           and GAL.GCO_ALLOY_ID =
                             decode(iMngtMode
                                  , '1', DFA.GCO_ALLOY_ID
                                  , '2', (select max(GAC.GCO_ALLOY_ID)
                                            from GCO_ALLOY_COMPONENT GAC
                                           where GAC.DIC_BASIS_MATERIAL_ID = DFA.DIC_BASIS_MATERIAL_ID
                                             and GAC.GAC_RATE = 100)
                                   )
      order by DFA.DOC_FOOT_ALLOY_ID;

    lTplFootAlloy              lcurFootAlloy%rowtype;
    lTmpCMATERIALMGNTMODE      PAC_CUSTOM_PARTNER.C_MATERIAL_MGNT_MODE%type;
    lTmpTHIRDMETALACCOUNT      PAC_CUSTOM_PARTNER.CUS_METAL_ACCOUNT%type;
    lTmpSTMSTOCKMOVEMENTID     STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
    lTmpGASWEIGHTMAT           DOC_GAUGE_STRUCTURED.GAS_WEIGHT_MAT%type;
    lTmpGASMETALACCOUNTMGM     DOC_GAUGE_STRUCTURED.GAS_METAL_ACCOUNT_MGM%type;
    lTmpSTMMOVEMENTKINDID      DOC_GAUGE_POSITION.STM_MOVEMENT_KIND_ID%type;
    lTmpSMOFINANCIALCHARGING   STM_STOCK_MOVEMENT.SMO_FINANCIAL_CHARGING%type;
    lTmpDMTNUMBER              DOC_DOCUMENT.DMT_NUMBER%type;
    lTmpDOCRECORDID            DOC_DOCUMENT.DOC_RECORD_ID%type;
    lTmpPACTHIRDID             DOC_DOCUMENT.PAC_THIRD_ID%type;
    lTmpPACTHIRDACIID          DOC_DOCUMENT.PAC_THIRD_ACI_ID%type;
    lTmpPACTHIRDDELIVERYID     DOC_DOCUMENT.PAC_THIRD_DELIVERY_ID%type;
    lTmpPACTHIRDTARIFFID       DOC_DOCUMENT.PAC_THIRD_TARIFF_ID%type;
    lTmpDMTDATEDOCUMENT        DOC_DOCUMENT.DMT_DATE_DOCUMENT%type;
    lTmpDMTRATEOFEXCHANGE      DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    lTmpDMTBASEPRICE           DOC_DOCUMENT.DMT_BASE_PRICE%type;
    lTmpACSFINANCIALCURRENCYID DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
    lTmpACSLOCALCURRENCYID     DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
    lTmpSTMEXERCISEID          STM_STOCK_MOVEMENT.STM_EXERCISE_ID%type;
    lTmpSTMPERIODID            STM_STOCK_MOVEMENT.STM_PERIOD_ID%type;
    lTmpSMOMOVEMENTDATE        STM_STOCK_MOVEMENT.SMO_MOVEMENT_DATE%type;
    lTmpDEFMATSTMSTOCKID       STM_STOCK.STM_STOCK_ID%type;
    lTmpSMOUNITPRICE           STM_STOCK_MOVEMENT.SMO_UNIT_PRICE%type;
    lTmpSMOALTQTY1             STM_STOCK_MOVEMENT.SMO_MVT_ALTERNATIV_QTY_1%type;
    lTmpSMOALTQTY2             STM_STOCK_MOVEMENT.SMO_MVT_ALTERNATIV_QTY_2%type;
    lTmpSMOALTQTY3             STM_STOCK_MOVEMENT.SMO_MVT_ALTERNATIV_QTY_3%type;
    lTmpCADMINDOMAIN           DOC_GAUGE.C_ADMIN_DOMAIN%type;
    lTmpSMOMOVEMENTPRICEB      STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type;
    lTmpSMOMOVEMENTPRICEE      STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type;
  begin
    -- Gestion des comptes poids matières précieuses
    if PCS.PC_CONFIG.GetConfig('DOC_METAL_ACCOUNT') = '1' then
      begin
        -- Recherche globale d'informations pour la génération des mouvements
        select nvl(GAS.GAS_WEIGHT_MAT, 0)
             , nvl(GAS.GAS_METAL_ACCOUNT_MGM, 0)
             , MOK.STM_MOVEMENT_KIND_ID
             , sign(MOK.MOK_FINANCIAL_IMPUTATION + MOK.MOK_ANAL_IMPUTATION) SMO_FINANCIAL_CHARGING
             , DMT.DOC_RECORD_ID
             , DMT.PAC_THIRD_ID
             , DMT.PAC_THIRD_ACI_ID
             , DMT.PAC_THIRD_DELIVERY_ID
             , DMT.PAC_THIRD_TARIFF_ID
             , DMT.DMT_DATE_DOCUMENT
             , DMT.ACS_FINANCIAL_CURRENCY_ID
             , DMT.DMT_RATE_OF_EXCHANGE
             , DMT_BASE_PRICE
             , STM_FUNCTIONS.GetPeriodExerciseId(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) ) STM_EXERCISE_ID
             , STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT) STM_PERIOD_ID
             , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT), DMT.DMT_DATE_DOCUMENT) SMO_MOVEMENT_DATE
             , decode(GAU.C_ADMIN_DOMAIN
                    , 1, SUP.C_MATERIAL_MGNT_MODE
                    , 2, CUS.C_MATERIAL_MGNT_MODE
                    , 5, SUP.C_MATERIAL_MGNT_MODE
                    , nvl(CUS.C_MATERIAL_MGNT_MODE, SUP.C_MATERIAL_MGNT_MODE)
                     ) C_MATERIAL_MGNT_MODE
             , nvl(decode(GAU.C_ADMIN_DOMAIN
                        , 1, SUP.CRE_METAL_ACCOUNT
                        , 2, CUS.CUS_METAL_ACCOUNT
                        , 5, SUP.CRE_METAL_ACCOUNT
                        , nvl(CUS.CUS_METAL_ACCOUNT, SUP.CRE_METAL_ACCOUNT)
                         )
                 , 0
                  ) METAL_ACCOUNT
             , GAU.C_ADMIN_DOMAIN
          into lTmpGASWEIGHTMAT
             , lTmpGASMETALACCOUNTMGM
             , lTmpSTMMOVEMENTKINDID
             , lTmpSMOFINANCIALCHARGING
             , lTmpDOCRECORDID
             , lTmpPACTHIRDID
             , lTmpPACTHIRDACIID
             , lTmpPACTHIRDDELIVERYID
             , lTmpPACTHIRDTARIFFID
             , lTmpDMTDATEDOCUMENT
             , lTmpACSFINANCIALCURRENCYID
             , lTmpDMTRATEOFEXCHANGE
             , lTmpDMTBASEPRICE
             , lTmpSTMEXERCISEID
             , lTmpSTMPERIODID
             , lTmpSMOMOVEMENTDATE
             , lTmpCMATERIALMGNTMODE
             , lTmpTHIRDMETALACCOUNT
             , lTmpCADMINDOMAIN
          from DOC_DOCUMENT DMT
             , DOC_GAUGE GAU
             , DOC_GAUGE_STRUCTURED GAS
             , DOC_GAUGE_POSITION GAP
             , STM_MOVEMENT_KIND MOK
             , PAC_SUPPLIER_PARTNER SUP
             , PAC_CUSTOM_PARTNER CUS
         where DMT.DOC_DOCUMENT_ID = iDocumentID
           and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
           and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
           and GAS.DOC_GAUGE_ID = GAP.DOC_GAUGE_ID
           and GAP.GAP_DEFAULT = 1
           and GAP.C_GAUGE_TYPE_POS = '1'
           and nvl(GAP.STM_MA_MOVEMENT_KIND_ID, GAP.STM_MOVEMENT_KIND_ID) = MOK.STM_MOVEMENT_KIND_ID
           and DMT.PAC_THIRD_ID = SUP.PAC_SUPPLIER_PARTNER_ID(+)
           and DMT.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+);
      exception
        when no_data_found then
          return;
      end;

      -- Recherche le compte poids par défaut
      begin
        select STO.STM_STOCK_ID DEFAULT_STOCK
          into lTmpDEFMATSTMSTOCKID
          from STM_STOCK STO
         where nvl(STO.STO_METAL_ACCOUNT, 0) = 1
           and nvl(STO.STO_DEFAULT_METAL_ACCOUNT, 0) = 1;
      exception
        when no_data_found then
          lTmpDEFMATSTMSTOCKID  := null;
      end;

      -- Recherche la monnaie de base
      lTmpACSLOCALCURRENCYID  := ACS_FUNCTION.GetLocalCurrencyId;

      -- Gabarit si "Gestion des poids des matières précieuses" = OUI
      -- Gabarit si "Mise à jour compte poids matières précieuses" = OUI
      -- Tiers si "Gestion compte poids" = 1
      -- Type de mouvement trouvé sur le gabarit position type '1'
      -- Si Mode de gestion matières précieuses du Tiers renseigné
      if     (lTmpGASWEIGHTMAT = 1)
         and (lTmpGASMETALACCOUNTMGM = 1)
         and (lTmpTHIRDMETALACCOUNT = 1)
         and (lTmpSTMMOVEMENTKINDID is not null)
         and (lTmpCMATERIALMGNTMODE is not null) then
        open lcurFootAlloy(iDocumentID, lTmpDEFMATSTMSTOCKID, lTmpCMATERIALMGNTMODE);

        fetch lcurFootAlloy
         into lTplFootAlloy;

        -- Balayer les matières précieuses sur le pied de document
        while lcurFootAlloy%found loop
          -- Vérifier qu'il y a un bien lié à l'alliage
          if lTplFootAlloy.GCO_GOOD_ID is null then
            raise_application_error(-20928, PCS.PC_FUNCTIONS.TranslateWord('PCS - Le bien n''est pas défini sur l''alliage !') );
          else
            lTmpSTMSTOCKMOVEMENTID  := null;

            -- Rechercher les qtés alternatives
            select decode(PDT.PDT_ALTERNATIVE_QUANTITY_1, 1, PDT.PDT_CONVERSION_FACTOR_1 * lTplFootAlloy.SMO_MOVEMENT_QUANTITY, 0) SMO_ALTERNATIVE_QUANTITY_1
                 , decode(PDT.PDT_ALTERNATIVE_QUANTITY_2, 1, PDT.PDT_CONVERSION_FACTOR_2 * lTplFootAlloy.SMO_MOVEMENT_QUANTITY, 0) SMO_ALTERNATIVE_QUANTITY_2
                 , decode(PDT.PDT_ALTERNATIVE_QUANTITY_3, 1, PDT.PDT_CONVERSION_FACTOR_3 * lTplFootAlloy.SMO_MOVEMENT_QUANTITY, 0) SMO_ALTERNATIVE_QUANTITY_3
              into lTmpSMOALTQTY1
                 , lTmpSMOALTQTY2
                 , lTmpSMOALTQTY3
              from GCO_PRODUCT PDT
             where PDT.GCO_GOOD_ID = lTplFootAlloy.GCO_GOOD_ID;

            -- Détermine le prix du mouvement.
            if (lTmpACSFINANCIALCURRENCYID <> lTmpACSLOCALCURRENCYID) then
              -- Convertit le montant facturé de la monnaie du document en monnaie de base pour valorisé le mouvement
              -- de stock du compte poids.
              ACS_FUNCTION.ConvertAmount(nvl(lTplFootAlloy.SMO_MOVEMENT_PRICE, 0)
                                       , lTmpACSFINANCIALCURRENCYID
                                       , lTmpACSLOCALCURRENCYID
                                       , lTmpDMTDATEDOCUMENT
                                       , lTmpDMTRATEOFEXCHANGE
                                       , lTmpDMTBASEPRICE
                                       , 0
                                       , lTmpSMOMOVEMENTPRICEE
                                       , lTmpSMOMOVEMENTPRICEB
                                        );
            else
              lTmpSMOMOVEMENTPRICEB  := nvl(lTplFootAlloy.SMO_MOVEMENT_PRICE, 0);
            end if;

            -- calcul du Prix unitaire du mouvement
            select decode(lTplFootAlloy.SMO_MOVEMENT_QUANTITY
                        , 0, lTplFootAlloy.SMO_MOVEMENT_QUANTITY
                        , lTmpSMOMOVEMENTPRICEB / lTplFootAlloy.SMO_MOVEMENT_QUANTITY
                         ) SMO_UNIT_PRICE
              into lTmpSMOUNITPRICE
              from dual;

            -- Création du mouvement
            STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId    => lTmpSTMSTOCKMOVEMENTID
                                            , iGoodId              => lTplFootAlloy.GCO_GOOD_ID
                                            , iMovementKindId      => lTmpSTMMOVEMENTKINDID
                                            , iExerciseId          => lTmpSTMEXERCISEID
                                            , iPeriodId            => lTmpSTMPERIODID
                                            , iMvtDate             => lTmpSMOMOVEMENTDATE
                                            , iValueDate           => lTmpSMOMOVEMENTDATE
                                            , iStockId             => lTplFootAlloy.STM_STOCK_ID
                                            , iLocationId          => lTplFootAlloy.STM_LOCATION_ID
                                            , iThirdId             => lTmpPACTHIRDID
                                            , iThirdAciId          => lTmpPACTHIRDACIID
                                            , iThirdDeliveryId     => lTmpPACTHIRDDELIVERYID
                                            , iThirdTariffId       => lTmpPACTHIRDTARIFFID
                                            , iRecordId            => lTmpDOCRECORDID
                                            , iWording             => lTplFootAlloy.SMO_WORDING
                                            , iMvtQty              => lTplFootAlloy.SMO_MOVEMENT_QUANTITY
                                            , iMvtPrice            => lTmpSMOMOVEMENTPRICEB
                                            , iUnitPrice           => lTmpSMOUNITPRICE
                                            , iAltQty1             => lTmpSMOALTQTY1
                                            , iAltQty2             => lTmpSMOALTQTY2
                                            , iAltQty3             => lTmpSMOALTQTY3
                                            , iFinancialCharging   => lTmpSMOFINANCIALCHARGING
                                            , iUpdateProv          => 1
                                            , iExtourneMvt         => 0
                                            , iRecStatus           => 11
                                            , iDocFootAlloyID      => lTplFootAlloy.DOC_FOOT_ALLOY_ID
                                             );
          end if;

          fetch lcurFootAlloy
           into lTplFootAlloy;
        end loop;

        close lcurFootAlloy;
      end if;
    end if;
  end DocFootAlloyMovements;

  /**
  * Description
  *   Extourne des mouvements sur les matières précieuses du pied de document
  */
  procedure DocExtFootAlloyMovements(iDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    cursor lcurExtourneAlloy(iFootAlloyId DOC_FOOT_ALLOY.DOC_FOOT_ALLOY_ID%type, iReportMvtId STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_Id%type)
    is
      select   SMO.STM_STOCK_MOVEMENT_ID
          from STM_STOCK_MOVEMENT SMO
             , STM_MOVEMENT_KIND MOK
             , DOC_DOCUMENT DMT
             , DOC_FOOT_ALLOY DFA
         where DMT.DOC_DOCUMENT_ID = iDocumentId
           and DFA.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID
           and SMO.DOC_FOOT_ALLOY_ID = DFA.DOC_FOOT_ALLOY_ID
           and SMO.STM_STM_STOCK_MOVEMENT_ID is null   /* only main movements */
           and SMO.STM_MOVEMENT_KIND_ID <> iReportMvtId   /* do not take care of report movements  */
           and MOK.STM_MOVEMENT_KIND_ID = SMO.STM_MOVEMENT_KIND_ID
           and not exists(select STM_STOCK_MOVEMENT_ID
                            from STM_STOCK_MOVEMENT
                           where DOC_FOOT_ALLOY_ID = DFA.DOC_FOOT_ALLOY_ID
                             and SMO_EXTOURNE_MVT = 1)   /* do not take already extourned movements */
      order by SMO.GCO_GOOD_ID
             , SMO.SMO_CHARACTERIZATION_VALUE_1
             , SMO.SMO_CHARACTERIZATION_VALUE_2
             , SMO.SMO_CHARACTERIZATION_VALUE_3
             , SMO.SMO_CHARACTERIZATION_VALUE_4
             , SMO.SMO_CHARACTERIZATION_VALUE_5
             , DFA.DOC_FOOT_ALLOY_ID;
  begin
    -- Gestion des comptes poids matières précieuses
    if PCS.PC_CONFIG.GetConfig('DOC_METAL_ACCOUNT') = '1' then
      for tplExtourneAlloy in lcurExtourneAlloy(iDocumentID, getReportMovementKindId) loop
        -- Création du mouvement
        STM_PRC_MOVEMENT.GenerateReversalMvt(tplExtourneAlloy.STM_STOCK_MOVEMENT_ID);
      end loop;
    end if;
  end DocExtFootAlloyMovements;
end DOC_PRC_MOVEMENT;
