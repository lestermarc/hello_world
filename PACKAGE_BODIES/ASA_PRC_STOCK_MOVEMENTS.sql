--------------------------------------------------------
--  DDL for Package Body ASA_PRC_STOCK_MOVEMENTS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_PRC_STOCK_MOVEMENTS" 
is
  gcfgWorkStockId      ASA_RECORD_COMP.STM_WORK_STOCK_ID%type
                                         := FWK_I_LIB_ENTITY.getIdFromPk2('STM_STOCK', 'STO_DESCRIPTION', PCS.PC_CONFIG.GetConfig('ASA_WORK_STO_DESCRIPTION') );
  gcfgWorkLocationId   ASA_RECORD_COMP.STM_WORK_STOCK_ID%type
                                      := FWK_I_LIB_ENTITY.getIdFromPk2('STM_LOCATION', 'LOC_DESCRIPTION', PCS.PC_CONFIG.GetConfig('ASA_WORK_LOC_DESCRIPTION') );
  gcfgCompMvtOutKindId STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type
    := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name   => 'STM_MOVEMENT_KIND'
                                   , iv_column_name   => 'MOK_ABBREVIATION'
                                   , iv_value         => PCS.PC_CONFIG.GetConfig('ASA_COMPONENT_KIND_MVT')
                                    );

  /**
  * Description
  *   Indique si il existe des détails dont les mouvements de stock sont déjà générés
  */
  function pIsDetMvtGen(iRecordId in ASA_RECORD.ASA_RECORD_ID%type)
    return boolean
  is
    lCount pls_integer;
  begin
    select count(*)
      into lCount
      from ASA_RECORD_DETAIL
     where ASA_RECORD_ID = iRecordId
       and STM_STOCK_MOVEMENT_ID is not null;

    return lCount > 0;
  end pIsDetMvtGen;

  /**
  * Description
  *   Indique si il existe des détails d'échange dont les mouvements de stock sont déjà générés
  */
  function pIsDetExchMvtGen(iRecordId in ASA_RECORD.ASA_RECORD_ID%type)
    return boolean
  is
    lCount pls_integer;
  begin
    select count(*)
      into lCount
      from ASA_RECORD_DETAIL RED
         , ASA_RECORD_EXCH_DETAIL REX
     where RED.ASA_RECORD_ID = iRecordId
       and REX.ASA_RECORD_DETAIL_ID = RED.ASA_RECORD_DETAIL_ID
       and REX.STM_STOCK_MOVEMENT_ID is not null;

    return lCount > 0;
  end pIsDetExchMvtGen;

  /**
  * Description
  *   Indique si des détails d'échange existent
  */
  function pIsDetExchData(iRecordId in ASA_RECORD.ASA_RECORD_ID%type)
    return boolean
  is
    lCount pls_integer;
  begin
    select count(*)
      into lCount
      from ASA_RECORD_DETAIL RED
         , ASA_RECORD_EXCH_DETAIL REX
     where RED.ASA_RECORD_ID = iRecordId
       and REX.ASA_RECORD_DETAIL_ID = RED.ASA_RECORD_DETAIL_ID;

    return lCount > 0;
  end pIsDetExchData;

--   /**
--   * Description
--   *   génération des mouvements de consomation des composants
--   */
--   procedure CpMvt(iRecordCompId in ASA_RECORD_COMP.ASA_RECORD_COMP_ID%type, iInvert in number default 0, oErrMess out varchar2)
--   is
--   begin
--     if    not gcfgASA_WORK_STOCK_MNG
--        or iInvert = 1 then
--       -- sortie de stock
--       CpSimpleOutputMvt(iRecordCompId, oErrMess);
--     else
--       -- transfert en atelier
--       CpFactoryTransfertMvt(iRecordCompId, oErrMess);
--     end if;
--   end CpMvt;

  /**
  * Description
  *   génération des mouvements de transfert des composants en atelier
  */
  procedure CpFactoryTransfertMvt(iRecordCompId in ASA_RECORD_COMP.ASA_RECORD_COMP_ID%type, oErrMess out varchar2)
  is
    ltplRecord      ASA_RECORD%rowtype;
    lMovementKindId ASA_RECORD_COMP.STM_COMP_MVT_KIND_ID%type
                          := FWK_I_LIB_ENTITY.getIdFromPk2('STM_MOVEMENT_KIND', 'MOK_ABBREVIATION', PCS.PC_CONFIG.GetConfig('ASA_COMPONENT_KIND_MVT_OUT_TRA') );
  begin
    select are.*
      into ltplRecord
      from ASA_RECORD are
         , ASA_RECORD_COMP ARC
     where are.ASA_RECORD_ID = ARC.ASA_RECORD_ID
       and ARC.ASA_RECORD_COMP_ID = iRecordCompId;

    for ltplComp in (select *
                       from ASA_RECORD_COMP
                      where ASA_RECORD_COMP_ID = iRecordCompId) loop
      declare
        -- prix de revient
        lCostPrice     ASA_RECORD_COMP.ARC_COST_PRICE%type
                                                     := ASA_I_LIB_RECORD.GetGoodCostPrice(ltplComp.GCO_COMPONENT_ID, ltplRecord.PAC_CUSTOM_PARTNER_ID, sysdate);
        lStockQty      STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
        lMovementId    STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type   := getNewId;
        lMovementTraId STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type   := getNewId;
        lMovementDate  date                                            := STM_I_LIB_EXERCISE.GetActiveDate(trunc(nvl(ltplComp.ARC_MOVEMENT_DATE, sysdate) ) );
        lCharId1       ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
        lCharId2       ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
        lCharId3       ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
        lCharId4       ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
        lCharId5       ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
      begin
        -- recherche des id de caractérisations car ils ne sont pas initialisé si aucune valeur n'est donnée
        GCO_I_LIB_CHARACTERIZATION.GetAllCharactID(iGoodId        => ltplComp.GCO_COMPONENT_ID
                                                 , iNoStkChar     => 0
                                                 , oCharactID_1   => lCharId1
                                                 , oCharactID_2   => lCharId2
                                                 , oCharactID_3   => lCharId3
                                                 , oCharactID_4   => lCharId4
                                                 , oCharactID_5   => lCharId5
                                                  );

        -- contrôle
        if ltplComp.STM_COMP_STOCK_MVT_ID is not null then
          oErrMess  := PCS.PC_FUNCTIONS.TranslateWord('Mouvement de stock déjà effectué.');
          return;
        end if;

        -- contrôle qu'un stock atelier soit défini
        if nvl(ltplComp.STM_WORK_STOCK_ID, gcfgWorkStockId) is null then
          oErrMess  := PCS.PC_FUNCTIONS.TranslateWord('Stock atelier non défini. Vérifiez la configuration ''ASA_WORK_STO_DESCRIPTION''.');
          return;
        end if;

        if     ltplComp.ARC_CDMVT = 1
           and (   ltplComp.ARC_OPTIONAL = 0
                or ltplComp.C_ASA_ACCEPT_OPTION = '2') then
          -- contrôle des valeurs de caractérisations
          if    (    lCharId1 is not null
                 and ltplComp.ARC_CHAR1_VALUE is null)
             or (    lCharId2 is not null
                 and ltplComp.ARC_CHAR2_VALUE is null)
             or (    lCharId3 is not null
                 and ltplComp.ARC_CHAR3_VALUE is null)
             or (    lCharId4 is not null
                 and ltplComp.ARC_CHAR4_VALUE is null)
             or (    lCharId5 is not null
                 and ltplComp.ARC_CHAR5_VALUE is null) then
            oErrMess  := PCS.PC_FUNCTIONS.TranslateWord('Valeur de caractérisation manquante sur le composant.');
            return;
          end if;

          -- contrôle quantité en stock
          lStockQty  :=
            ASA_FUNCTIONS.GetQuantity(ltplComp.GCO_COMPONENT_ID
                                    , ltplComp.STM_COMP_STOCK_ID
                                    , ltplComp.STM_COMP_LOCATION_ID
                                    , ltplComp.GCO_CHAR1_ID
                                    , ltplComp.GCO_CHAR2_ID
                                    , ltplComp.GCO_CHAR3_ID
                                    , ltplComp.GCO_CHAR4_ID
                                    , ltplComp.GCO_CHAR5_ID
                                    , ltplComp.ARC_CHAR1_VALUE
                                    , ltplComp.ARC_CHAR2_VALUE
                                    , ltplComp.ARC_CHAR3_VALUE
                                    , ltplComp.ARC_CHAR4_VALUE
                                    , ltplComp.ARC_CHAR5_VALUE
                                    , 'AVAILABLE'
                                    , ltplComp.ASA_RECORD_COMP_ID
                                     );

          if lStockQty < ltplComp.ARC_QUANTITY then
            oErrMess  :=
              replace
                (replace
                   (replace
                      (PCS.PC_FUNCTIONS.TranslateWord
                                           ('Quantité en stock insuffisante pour le composant ''[GOOD]'' dans le stock ''[STOCK]'', emplacement ''[LOCATION]''.')
                     , '[STOCK]'
                     , FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('STM_STOCK', 'STO_DESCRIPTION', ltplComp.STM_COMP_STOCK_ID)
                      )
                  , '[LOCATION]'
                  , FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('STM_LOCATION', 'LOC_DESCRIPTION', ltplComp.STM_COMP_LOCATION_ID)
                   )
               , '[GOOD]'
               , FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('GCO_GOOD', 'GOO_MAJOR_REFERENCE', ltplComp.GCO_COMPONENT_ID)
                );
            return;
          end if;

          -- suppression des attributions
          if ltplComp.DOC_ATTRIB_POSITION_ID is not null then
            ASA_RECORD_GENERATE_DOC.DeleteAttribComponent(ltplComp.DOC_ATTRIB_POSITION_ID);
          end if;

          begin
            -- consommation stock
            STM_I_PRC_MOVEMENT.GenerateMovement(ioStockMovementId   => lMovementId
                                              , iGoodId             => ltplComp.GCO_COMPONENT_ID
                                              , iMovementKindId     => lMovementKindId
                                              , iExerciseId         => STM_I_LIB_EXERCISE.GetActiveExercise
                                              , iPeriodId           => STM_I_LIB_EXERCISE.GetPeriodId(lMovementDate)
                                              , iMvtDate            => lMovementDate
                                              , iValueDate          => lMovementDate
                                              , iStockId            => ltplComp.STM_COMP_STOCK_ID
                                              , iLocationId         => ltplComp.STM_COMP_LOCATION_ID
                                              , iThirdId            => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                              , iThirdAciId         => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                              , iThirdDeliveryId    => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                              , iThirdTariffId      => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                              , iRecordId           => ltplRecord.DOC_RECORD_ID
                                              , iChar1Id            => ltplComp.GCO_CHAR1_ID
                                              , iChar2Id            => ltplComp.GCO_CHAR2_ID
                                              , iChar3Id            => ltplComp.GCO_CHAR3_ID
                                              , iChar4Id            => ltplComp.GCO_CHAR4_ID
                                              , iChar5Id            => ltplComp.GCO_CHAR5_ID
                                              , iCharValue1         => ltplComp.ARC_CHAR1_VALUE
                                              , iCharValue2         => ltplComp.ARC_CHAR2_VALUE
                                              , iCharValue3         => ltplComp.ARC_CHAR3_VALUE
                                              , iCharValue4         => ltplComp.ARC_CHAR4_VALUE
                                              , iCharValue5         => ltplComp.ARC_CHAR5_VALUE
                                              , iWording            => ltplRecord.ARE_NUMBER || ' / ' || lpad(ltplComp.ARC_POSITION, 4, '0')
                                              , iMvtQty             => ltplComp.ARC_QUANTITY
                                              , iMvtPrice           => ltplComp.ARC_QUANTITY * lCostPrice
                                              , iDocQty             => 0
                                              , iDocPrice           => 0
                                              , iUnitPrice          => lCostPrice
                                              , iRefUnitPrice       => lCostPrice
                                              , iAltQty1            => 0
                                              , iAltQty2            => 0
                                              , iAltQty3            => 0
                                              , iImpNumber1         => 0
                                              , iImpNumber2         => 0
                                              , iImpNumber3         => 0
                                              , iImpNumber4         => 0
                                              , iImpNumber5         => 0
                                              , iUpdateProv         => 0
                                              , iExtourneMvt        => 0
                                              , iRecStatus          => 9
                                               );
            -- entrée atelier
            STM_I_PRC_MOVEMENT.GenerateMovement(ioStockMovementId   => lMovementTraId
                                              , iGoodId             => ltplComp.GCO_COMPONENT_ID
                                              , iMovementKindId     => FWK_I_LIB_ENTITY.getNumberFieldFromPk('STM_MOVEMENT_KIND'
                                                                                                           , 'STM_STM_MOVEMENT_KIND_ID'
                                                                                                           , lMovementKindId
                                                                                                            )
                                              , iExerciseId         => STM_I_LIB_EXERCISE.GetActiveExercise
                                              , iPeriodId           => STM_I_LIB_EXERCISE.GetPeriodId(lMovementDate)
                                              , iMvtDate            => lMovementDate
                                              , iValueDate          => lMovementDate
                                              , iStockId            => gcfgWorkStockId
                                              , iLocationId         => gcfgWorkLocationId
                                              , iThirdId            => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                              , iThirdAciId         => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                              , iThirdDeliveryId    => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                              , iThirdTariffId      => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                              , iRecordId           => ltplRecord.DOC_RECORD_ID
                                              , iChar1Id            => ltplComp.GCO_CHAR1_ID
                                              , iChar2Id            => ltplComp.GCO_CHAR2_ID
                                              , iChar3Id            => ltplComp.GCO_CHAR3_ID
                                              , iChar4Id            => ltplComp.GCO_CHAR4_ID
                                              , iChar5Id            => ltplComp.GCO_CHAR5_ID
                                              , iCharValue1         => ltplComp.ARC_CHAR1_VALUE
                                              , iCharValue2         => ltplComp.ARC_CHAR2_VALUE
                                              , iCharValue3         => ltplComp.ARC_CHAR3_VALUE
                                              , iCharValue4         => ltplComp.ARC_CHAR4_VALUE
                                              , iCharValue5         => ltplComp.ARC_CHAR5_VALUE
                                              , iMovement2Id        => lMovementId   -- lien de transfert
                                              , iWording            => ltplRecord.ARE_NUMBER || ' / ' || lpad(ltplComp.ARC_POSITION, 4, '0')
                                              , iMvtQty             => ltplComp.ARC_QUANTITY
                                              , iMvtPrice           => ltplComp.ARC_QUANTITY * lCostPrice
                                              , iDocQty             => 0
                                              , iDocPrice           => 0
                                              , iUnitPrice          => lCostPrice
                                              , iRefUnitPrice       => lCostPrice
                                              , iAltQty1            => 0
                                              , iAltQty2            => 0
                                              , iAltQty3            => 0
                                              , iImpNumber1         => 0
                                              , iImpNumber2         => 0
                                              , iImpNumber3         => 0
                                              , iImpNumber4         => 0
                                              , iImpNumber5         => 0
                                              , iUpdateProv         => 0
                                              , iExtourneMvt        => 0
                                              , iRecStatus          => 9
                                               );
          end;

          -- maj infos sur composant
          declare
            ltRecordComp FWK_I_TYP_DEFINITION.t_crud_def;
          begin
            FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordComp, ltRecordComp);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComp, 'ASA_RECORD_COMP_ID', ltplComp.ASA_RECORD_COMP_ID);
            -- prix de revient
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComp, 'ARC_COST_PRICE', lCostPrice);
            -- genre de mouvement
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComp, 'STM_COMP_MVT_KIND_ID', lMovementKindId);
            -- mouvement généré
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComp, 'STM_COMP_STOCK_MVT_ID', lMovementId);
            -- stock atelier
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComp, 'STM_WORK_STOCK_ID', gcfgWorkStockId);
            -- emplacement atelier
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComp, 'STM_WORK_LOCATION_ID', gcfgWorkLocationId);
            -- date du mouvement généré
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComp, 'ARC_MOVEMENT_DATE', lMovementDate);
            FWK_I_MGT_ENTITY.UpdateEntity(ltRecordComp);
            FWK_I_MGT_ENTITY.Release(ltRecordComp);
          end;
        end if;

        -- génération
        if PCS.PC_CONFIG.GetBooleanConfig('ASA_WORK_STOCK_MNG') then
          null;
        else
          null;
        end if;
      end;
    end loop;
  end CpFactoryTransfertMvt;

  /**
  * Description
  *   génération des mouvements de sortie de composants
  */
  procedure CpSimpleOutputMvt(iRecordCompId in ASA_RECORD_COMP.ASA_RECORD_COMP_ID%type, oErrMess out varchar2)
  is
    ltplRecord ASA_RECORD%rowtype;
    lCharId1   ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
    lCharId2   ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
    lCharId3   ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
    lCharId4   ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
    lCharId5   ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
    lMvtSort   STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type;
  begin
    select are.*
      into ltplRecord
      from ASA_RECORD are
         , ASA_RECORD_COMP ARC
     where are.ASA_RECORD_ID = ARC.ASA_RECORD_ID
       and ARC.ASA_RECORD_COMP_ID = iRecordCompId;

    for ltplComp in (select *
                       from ASA_RECORD_COMP
                      where ASA_RECORD_COMP_ID = iRecordCompId) loop
      declare
        -- prix de revient
        lCostPrice    ASA_RECORD_COMP.ARC_COST_PRICE%type
                                                     := ASA_I_LIB_RECORD.GetGoodCostPrice(ltplComp.GCO_COMPONENT_ID, ltplRecord.PAC_CUSTOM_PARTNER_ID, sysdate);
        lStockQty     STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
        lMovementId   STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type   := getNewId;
        lMovementDate date                                            := STM_I_LIB_EXERCISE.GetActiveDate(trunc(nvl(ltplComp.ARC_MOVEMENT_DATE, sysdate) ) );
      begin
        -- recherche des id de caractérisations car ils ne sont pas initialisé si aucune valeur n'est donnée
        GCO_I_LIB_CHARACTERIZATION.GetAllCharactID(iGoodId        => ltplComp.GCO_COMPONENT_ID
                                                 , iNoStkChar     => 0
                                                 , oCharactID_1   => lCharId1
                                                 , oCharactID_2   => lCharId2
                                                 , oCharactID_3   => lCharId3
                                                 , oCharactID_4   => lCharId4
                                                 , oCharactID_5   => lCharId5
                                                  );

        -- contrôle
        if ltplComp.STM_COMP_STOCK_MVT_ID is not null then
          oErrMess  := PCS.PC_FUNCTIONS.TranslateWord('Mouvement de stock déjà effectué.');
          return;
        end if;

        if     ltplComp.ARC_CDMVT = 1
           and (   ltplComp.ARC_OPTIONAL = 0
                or ltplComp.C_ASA_ACCEPT_OPTION = '2') then
          -- contrôle des valeurs de caractérisations
          if    (    lCharId1 is not null
                 and ltplComp.ARC_CHAR1_VALUE is null)
             or (    lCharId2 is not null
                 and ltplComp.ARC_CHAR2_VALUE is null)
             or (    lCharId3 is not null
                 and ltplComp.ARC_CHAR3_VALUE is null)
             or (    lCharId4 is not null
                 and ltplComp.ARC_CHAR4_VALUE is null)
             or (    lCharId5 is not null
                 and ltplComp.ARC_CHAR5_VALUE is null) then
            oErrMess  := PCS.PC_FUNCTIONS.TranslateWord('Valeur de caractérisation manquante sur le composant.');
            return;
          end if;

          lMvtSort  := FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('STM_MOVEMENT_KIND', 'C_MOVEMENT_SORT', ltplComp.STM_COMP_MVT_KIND_ID);

          -- contrôle quantité pour les mouvements de sortie
          if lMvtSort = 'SOR' then
            lStockQty  :=
              ASA_FUNCTIONS.GetQuantity(ltplComp.GCO_COMPONENT_ID
                                      , ltplComp.STM_COMP_STOCK_ID
                                      , ltplComp.STM_COMP_LOCATION_ID
                                      , ltplComp.GCO_CHAR1_ID
                                      , ltplComp.GCO_CHAR2_ID
                                      , ltplComp.GCO_CHAR3_ID
                                      , ltplComp.GCO_CHAR4_ID
                                      , ltplComp.GCO_CHAR5_ID
                                      , ltplComp.ARC_CHAR1_VALUE
                                      , ltplComp.ARC_CHAR2_VALUE
                                      , ltplComp.ARC_CHAR3_VALUE
                                      , ltplComp.ARC_CHAR4_VALUE
                                      , ltplComp.ARC_CHAR5_VALUE
                                      , 'AVAILABLE'
                                      , ltplComp.ASA_RECORD_COMP_ID
                                       );

            if lStockQty < ltplComp.ARC_QUANTITY then
              oErrMess  :=
                replace
                  (replace
                     (replace
                        (PCS.PC_FUNCTIONS.TranslateWord
                                           ('Quantité en stock insuffisante pour le composant ''[GOOD]'' dans le stock ''[STOCK]'', emplacement ''[LOCATION]''.')
                       , '[STOCK]'
                       , FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('STM_STOCK', 'STO_DESCRIPTION', ltplComp.STM_COMP_STOCK_ID)
                        )
                    , '[LOCATION]'
                    , FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('STM_LOCATION', 'LOC_DESCRIPTION', ltplComp.STM_COMP_LOCATION_ID)
                     )
                 , '[GOOD]'
                 , FWK_I_LIB_ENTITY.getVarchar2FieldFromPk('GCO_GOOD', 'GOO_MAJOR_REFERENCE', ltplComp.GCO_COMPONENT_ID)
                  );
              return;
            end if;
          end if;

          -- suppression des attributions
          if ltplComp.DOC_ATTRIB_POSITION_ID is not null then
            ASA_RECORD_GENERATE_DOC.DeleteAttribComponent(ltplComp.DOC_ATTRIB_POSITION_ID);
          end if;

          begin
            -- consommation composant
            STM_I_PRC_MOVEMENT.GenerateMovement(ioStockMovementId   => lMovementId
                                              , iGoodId             => ltplComp.GCO_COMPONENT_ID
                                              , iMovementKindId     => ltplComp.STM_COMP_MVT_KIND_ID
                                              , iExerciseId         => STM_I_LIB_EXERCISE.GetActiveExercise
                                              , iPeriodId           => STM_I_LIB_EXERCISE.GetPeriodId(lMovementDate)
                                              , iMvtDate            => lMovementDate
                                              , iValueDate          => lMovementDate
                                              , iStockId            => ltplComp.STM_COMP_STOCK_ID
                                              , iLocationId         => ltplComp.STM_COMP_LOCATION_ID
                                              , iThirdId            => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                              , iThirdAciId         => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                              , iThirdDeliveryId    => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                              , iThirdTariffId      => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                              , iRecordId           => ltplRecord.DOC_RECORD_ID
                                              , iChar1Id            => ltplComp.GCO_CHAR1_ID
                                              , iChar2Id            => ltplComp.GCO_CHAR2_ID
                                              , iChar3Id            => ltplComp.GCO_CHAR3_ID
                                              , iChar4Id            => ltplComp.GCO_CHAR4_ID
                                              , iChar5Id            => ltplComp.GCO_CHAR5_ID
                                              , iCharValue1         => ltplComp.ARC_CHAR1_VALUE
                                              , iCharValue2         => ltplComp.ARC_CHAR2_VALUE
                                              , iCharValue3         => ltplComp.ARC_CHAR3_VALUE
                                              , iCharValue4         => ltplComp.ARC_CHAR4_VALUE
                                              , iCharValue5         => ltplComp.ARC_CHAR5_VALUE
                                              , iWording            => ltplRecord.ARE_NUMBER || ' / ' || lpad(ltplComp.ARC_POSITION, 4, '0')
                                              , iMvtQty             => ltplComp.ARC_QUANTITY
                                              , iMvtPrice           => ltplComp.ARC_QUANTITY * lCostPrice
                                              , iDocQty             => 0
                                              , iDocPrice           => 0
                                              , iUnitPrice          => lCostPrice
                                              , iRefUnitPrice       => lCostPrice
                                              , iAltQty1            => 0
                                              , iAltQty2            => 0
                                              , iAltQty3            => 0
                                              , iImpNumber1         => 0
                                              , iImpNumber2         => 0
                                              , iImpNumber3         => 0
                                              , iImpNumber4         => 0
                                              , iImpNumber5         => 0
                                              , iUpdateProv         => 0
                                              , iExtourneMvt        => 0
                                              , iRecStatus          => 9
                                               );
          end;

          -- maj infos sur composant
          declare
            ltRecordComp FWK_I_TYP_DEFINITION.t_crud_def;
          begin
            FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordComp, ltRecordComp);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComp, 'ASA_RECORD_COMP_ID', ltplComp.ASA_RECORD_COMP_ID);
            -- prix de revient
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComp, 'ARC_COST_PRICE', lCostPrice);
            -- mouvement généré
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComp, 'STM_COMP_STOCK_MVT_ID', lMovementId);
            -- date du mouvement généré
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComp, 'ARC_MOVEMENT_DATE', lMovementDate);
            FWK_I_MGT_ENTITY.UpdateEntity(ltRecordComp);
            FWK_I_MGT_ENTITY.Release(ltRecordComp);
          end;
        end if;

        -- génération
        if PCS.PC_CONFIG.GetBooleanConfig('ASA_WORK_STOCK_MNG') then
          null;
        else
          null;
        end if;
      end;
    end loop;
  end CpSimpleOutputMvt;

  /**
  * Description
  *   génération des mouvements de sortie de composants
  */
  procedure CpFactoryOutputMvt(iRecordCompId in ASA_RECORD_COMP.ASA_RECORD_COMP_ID%type, oErrMess out varchar2)
  is
    ltplRecord ASA_RECORD%rowtype;
    lCharId1   ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
    lCharId2   ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
    lCharId3   ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
    lCharId4   ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
    lCharId5   ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
  begin
    select are.*
      into ltplRecord
      from ASA_RECORD are
         , ASA_RECORD_COMP ARC
     where are.ASA_RECORD_ID = ARC.ASA_RECORD_ID
       and ARC.ASA_RECORD_COMP_ID = iRecordCompId;

    for ltplComp in (select *
                       from ASA_RECORD_COMP
                      where ASA_RECORD_COMP_ID = iRecordCompId) loop
      declare
        -- prix de revient
        lCostPrice    ASA_RECORD_COMP.ARC_COST_PRICE%type
                                                     := ASA_I_LIB_RECORD.GetGoodCostPrice(ltplComp.GCO_COMPONENT_ID, ltplRecord.PAC_CUSTOM_PARTNER_ID, sysdate);
        lMovementId   STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type   := getNewId;
        lMovementDate date                                            := STM_I_LIB_EXERCISE.GetActiveDate(trunc(nvl(ltplComp.ARC_MOVEMENT_DATE, sysdate) ) );
      begin
        -- contrôle que le mouvement n'ait pas déjà été effectué
        if ltplComp.STM_WORK_STOCK_MOVEMENT_ID is not null then
          oErrMess  := PCS.PC_FUNCTIONS.TranslateWord('Mouvement de stock déjà effectué.');
          return;
        end if;

        -- contrôle que le mouvement de transfert en atelier ait été effectué
        if ltplComp.STM_COMP_STOCK_MVT_ID is null then
          oErrMess  := PCS.PC_FUNCTIONS.TranslateWord('Le composant n''a pas été transféré dans le stock atelier.');
          return;
        end if;

        -- contrôle qu'un stock atelier soit défini
        if nvl(ltplComp.STM_WORK_STOCK_ID, gcfgWorkStockId) is null then
          oErrMess  := PCS.PC_FUNCTIONS.TranslateWord('Stock atelier non défini. Vérifiez la configuration ''ASA_WORK_STO_DESCRIPTION''.');
          return;
        end if;

        if     ltplComp.ARC_CDMVT = 1
           and (   ltplComp.ARC_OPTIONAL = 0
                or ltplComp.C_ASA_ACCEPT_OPTION = '2') then
          -- recherche des id de caractérisations car ils ne sont pas initialisé si aucune valeur n'est donnée
          GCO_I_LIB_CHARACTERIZATION.GetAllCharactID(iGoodId        => ltplComp.GCO_COMPONENT_ID
                                                   , iNoStkChar     => 0
                                                   , oCharactID_1   => lCharId1
                                                   , oCharactID_2   => lCharId2
                                                   , oCharactID_3   => lCharId3
                                                   , oCharactID_4   => lCharId4
                                                   , oCharactID_5   => lCharId5
                                                    );

          -- contrôle des valeurs de caractérisations
          if    (    lCharId1 is not null
                 and ltplComp.ARC_CHAR1_VALUE is null)
             or (    lCharId2 is not null
                 and ltplComp.ARC_CHAR2_VALUE is null)
             or (    lCharId3 is not null
                 and ltplComp.ARC_CHAR3_VALUE is null)
             or (    lCharId4 is not null
                 and ltplComp.ARC_CHAR4_VALUE is null)
             or (    lCharId5 is not null
                 and ltplComp.ARC_CHAR5_VALUE is null) then
            oErrMess  := PCS.PC_FUNCTIONS.TranslateWord('Valeur de caractérisation manquante sur le composant.');
            return;
          end if;

          -- sortie atelier
          STM_I_PRC_MOVEMENT.GenerateMovement(ioStockMovementId   => lMovementId
                                            , iGoodId             => ltplComp.GCO_COMPONENT_ID
                                            , iMovementKindId     => gcfgCompMvtOutKindId
                                            , iExerciseId         => STM_I_LIB_EXERCISE.GetActiveExercise
                                            , iPeriodId           => STM_I_LIB_EXERCISE.GetPeriodId(lMovementDate)
                                            , iMvtDate            => lMovementDate
                                            , iValueDate          => lMovementDate
                                            , iStockId            => nvl(ltplComp.STM_WORK_STOCK_ID, gcfgWorkStockId)
                                            , iLocationId         => nvl(ltplComp.STM_WORK_LOCATION_ID, gcfgWorkLocationId)
                                            , iThirdId            => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                            , iThirdAciId         => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                            , iThirdDeliveryId    => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                            , iThirdTariffId      => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                            , iRecordId           => ltplRecord.DOC_RECORD_ID
                                            , iChar1Id            => ltplComp.GCO_CHAR1_ID
                                            , iChar2Id            => ltplComp.GCO_CHAR2_ID
                                            , iChar3Id            => ltplComp.GCO_CHAR3_ID
                                            , iChar4Id            => ltplComp.GCO_CHAR4_ID
                                            , iChar5Id            => ltplComp.GCO_CHAR5_ID
                                            , iCharValue1         => ltplComp.ARC_CHAR1_VALUE
                                            , iCharValue2         => ltplComp.ARC_CHAR2_VALUE
                                            , iCharValue3         => ltplComp.ARC_CHAR3_VALUE
                                            , iCharValue4         => ltplComp.ARC_CHAR4_VALUE
                                            , iCharValue5         => ltplComp.ARC_CHAR5_VALUE
                                            , iWording            => ltplRecord.ARE_NUMBER || ' / ' || lpad(ltplComp.ARC_POSITION, 4, '0')
                                            , iMvtQty             => ltplComp.ARC_QUANTITY
                                            , iMvtPrice           => ltplComp.ARC_QUANTITY * lCostPrice
                                            , iDocQty             => 0
                                            , iDocPrice           => 0
                                            , iUnitPrice          => lCostPrice
                                            , iRefUnitPrice       => lCostPrice
                                            , iAltQty1            => 0
                                            , iAltQty2            => 0
                                            , iAltQty3            => 0
                                            , iImpNumber1         => 0
                                            , iImpNumber2         => 0
                                            , iImpNumber3         => 0
                                            , iImpNumber4         => 0
                                            , iImpNumber5         => 0
                                            , iUpdateProv         => 0
                                            , iExtourneMvt        => 0
                                            , iRecStatus          => 9
                                             );

          -- maj infos sur composant
          declare
            ltRecordComp FWK_I_TYP_DEFINITION.t_crud_def;
          begin
            FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordComp, ltRecordComp);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComp, 'ASA_RECORD_COMP_ID', ltplComp.ASA_RECORD_COMP_ID);
            -- prix de revient
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComp, 'ARC_COST_PRICE', lCostPrice);
            -- mouvement généré
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComp, 'STM_WORK_STOCK_MOVEMENT_ID', lMovementId);
            -- stock atelier
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComp, 'STM_WORK_STOCK_ID', nvl(ltplComp.STM_WORK_STOCK_ID, gcfgWorkStockId) );
            -- emplacement atelier
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComp, 'STM_WORK_LOCATION_ID', nvl(ltplComp.STM_WORK_LOCATION_ID, gcfgWorkLocationId) );
            FWK_I_MGT_ENTITY.UpdateEntity(ltRecordComp);
            FWK_I_MGT_ENTITY.Release(ltRecordComp);
          end;
        end if;
      end;
    end loop;
  end CpFactoryOutputMvt;

  /**
  * procedure PdtRepairMvt
  * Description
  *   génération du mouvement d'entrée du produit défectueux
  * @created fp 06.10.2011
  * @lastUpdate
  * @public
  * @param  iRecordId : dossier SAV
  */
  procedure PdtRepairMvt(iRecordId in ASA_RECORD.ASA_RECORD_ID%type, oErrMess out varchar2)
  is
    -- prix de revient
    lCostPrice    ASA_RECORD_COMP.ARC_COST_PRICE%type;
    lMovementDate date                                  := STM_I_LIB_EXERCISE.GetActiveDate(trunc(sysdate) );
    lCharId1      ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
    lCharId2      ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
    lCharId3      ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
    lCharId4      ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
    lCharId5      ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;

    /**
    * Description
    *   Contrôle de parité des caractérisations sur les détails
    */
    function CtrlCharDet(iRecordId in ASA_RECORD.ASA_RECORD_ID%type)
      return boolean
    is
      lCount pls_integer;
    begin
      select count(*)
        into lCount
        from ASA_RECORD_DETAIL RED
       where RED.ASA_RECORD_ID = iRecordId
         and (    (    lCharId1 is not null
                   and (   RED.RED_CHAR1_VALUE is null
                        or RED.RED_CHAR1_VALUE = 'N/A') )
              or (    lCharId2 is not null
                  and (   RED.RED_CHAR2_VALUE is null
                       or RED.RED_CHAR2_VALUE = 'N/A') )
              or (    lCharId3 is not null
                  and (   RED.RED_CHAR3_VALUE is null
                       or RED.RED_CHAR3_VALUE = 'N/A') )
              or (    lCharId4 is not null
                  and (   RED.RED_CHAR4_VALUE is null
                       or RED.RED_CHAR4_VALUE = 'N/A') )
              or (    lCharId5 is not null
                  and (   RED.RED_CHAR5_VALUE is null
                       or RED.RED_CHAR5_VALUE = 'N/A') )
             );

      return lCount = 0;
    end CtrlCharDet;
  begin
    for ltplRecord in (select *
                         from ASA_RECORD
                        where ASA_RECORD_ID = iRecordId) loop
      -- recherche des id de caractérisations car ils ne sont pas initialisé si aucune valeur n'est donnée
      GCO_I_LIB_CHARACTERIZATION.GetAllCharactID(iGoodId        => ltplRecord.GCO_ASA_TO_REPAIR_ID
                                               , iNoStkChar     => 0
                                               , oCharactID_1   => lCharId1
                                               , oCharactID_2   => lCharId2
                                               , oCharactID_3   => lCharId3
                                               , oCharactID_4   => lCharId4
                                               , oCharactID_5   => lCharId5
                                                );
      -- prix de revient
      lCostPrice  := ASA_I_LIB_RECORD.GetGoodCostPrice(ltplRecord.GCO_ASA_TO_REPAIR_ID, ltplRecord.PAC_CUSTOM_PARTNER_ID, sysdate);

      -- contrôle que le mouvement n'ait pas déjà été effectué
      if    ltplRecord.STM_ASA_DEFECT_MVT_ID is not null
         or pIsDetMvtGen(iRecordId) then
        oErrMess  := PCS.PC_FUNCTIONS.TranslateWord('Mouvement de stock déjà effectué.');
        return;
      end if;

      -- contrôle des valeurs de caractérisations si pas de détails
      if     not FWK_I_LIB_ENTITY.RecordsExists('ASA_RECORD_DETAIL', 'ASA_RECORD_ID', iRecordId)
         and (    (    lCharId1 is not null
                   and (   ltplRecord.ARE_CHAR1_VALUE is null
                        or ltplRecord.ARE_CHAR1_VALUE = 'N/A') )
              or (    lCharId2 is not null
                  and (   ltplRecord.ARE_CHAR2_VALUE is null
                       or ltplRecord.ARE_CHAR2_VALUE = 'N/A') )
              or (    lCharId3 is not null
                  and (   ltplRecord.ARE_CHAR3_VALUE is null
                       or ltplRecord.ARE_CHAR3_VALUE = 'N/A') )
              or (    lCharId4 is not null
                  and (   ltplRecord.ARE_CHAR4_VALUE is null
                       or ltplRecord.ARE_CHAR4_VALUE = 'N/A') )
              or (    lCharId5 is not null
                  and (   ltplRecord.ARE_CHAR5_VALUE is null
                       or ltplRecord.ARE_CHAR5_VALUE = 'N/A') )
             ) then
        oErrMess  := PCS.PC_FUNCTIONS.TranslateWord('Valeur de caractérisation manquante sur le produit à réparer.');
        return;
      end if;

      -- contrôle des valeurs de caractérisations sur les détails
      if     FWK_I_LIB_ENTITY.RecordsExists('ASA_RECORD_DETAIL', 'ASA_RECORD_ID', iRecordId)
         and not CtrlCharDet(iRecordId) then
        oErrMess  := PCS.PC_FUNCTIONS.TranslateWord('Valeur de caractérisation manquante dans les détails du produit à réparer.');
        return;
      end if;

      if not FWK_I_LIB_ENTITY.RecordsExists('ASA_RECORD_DETAIL', 'ASA_RECORD_ID', iRecordId) then
        declare
          lMovementId STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type   := getNewId;
        begin
          -- entrée en stock déchet
          STM_I_PRC_MOVEMENT.GenerateMovement(ioStockMovementId   => lMovementId
                                            , iGoodId             => ltplRecord.GCO_ASA_TO_REPAIR_ID
                                            , iMovementKindId     => ltplRecord.STM_REPAIR_MVT_KIND_ID
                                            , iExerciseId         => STM_I_LIB_EXERCISE.GetActiveExercise
                                            , iPeriodId           => STM_I_LIB_EXERCISE.GetPeriodId(lMovementDate)
                                            , iMvtDate            => lMovementDate
                                            , iValueDate          => lMovementDate
                                            , iStockId            => ltplRecord.STM_ASA_DEFECT_STK_ID
                                            , iLocationId         => ltplRecord.STM_ASA_DEFECT_LOC_ID
                                            , iThirdId            => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                            , iThirdAciId         => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                            , iThirdDeliveryId    => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                            , iThirdTariffId      => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                            , iRecordId           => ltplRecord.DOC_RECORD_ID
                                            , iChar1Id            => ltplRecord.GCO_CHAR1_ID
                                            , iChar2Id            => ltplRecord.GCO_CHAR2_ID
                                            , iChar3Id            => ltplRecord.GCO_CHAR3_ID
                                            , iChar4Id            => ltplRecord.GCO_CHAR4_ID
                                            , iChar5Id            => ltplRecord.GCO_CHAR5_ID
                                            , iCharValue1         => ltplRecord.ARE_CHAR1_VALUE
                                            , iCharValue2         => ltplRecord.ARE_CHAR2_VALUE
                                            , iCharValue3         => ltplRecord.ARE_CHAR3_VALUE
                                            , iCharValue4         => ltplRecord.ARE_CHAR4_VALUE
                                            , iCharValue5         => ltplRecord.ARE_CHAR5_VALUE
                                            , iWording            => ltplRecord.ARE_NUMBER
                                            , iMvtQty             => ltplRecord.ARE_REPAIR_QTY
                                            , iMvtPrice           => ltplRecord.ARE_REPAIR_QTY * lCostPrice
                                            , iDocQty             => 0
                                            , iDocPrice           => 0
                                            , iUnitPrice          => lCostPrice
                                            , iRefUnitPrice       => lCostPrice
                                            , iAltQty1            => 0
                                            , iAltQty2            => 0
                                            , iAltQty3            => 0
                                            , iImpNumber1         => 0
                                            , iImpNumber2         => 0
                                            , iImpNumber3         => 0
                                            , iImpNumber4         => 0
                                            , iImpNumber5         => 0
                                            , iUpdateProv         => 0
                                            , iExtourneMvt        => 0
                                            , iRecStatus          => 9
                                             );

          -- maj infos sur produit à réparer
          declare
            ltRecord FWK_I_TYP_DEFINITION.t_crud_def;
          begin
            FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecord, ltRecord);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecord, 'ASA_RECORD_ID', ltplRecord.ASA_RECORD_ID);
            -- mouvement généré
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecord, 'STM_ASA_DEFECT_MVT_ID', lMovementId);
            FWK_I_MGT_ENTITY.UpdateEntity(ltRecord);
            FWK_I_MGT_ENTITY.Release(ltRecord);
          end;
        end;
      else
        for ltplRecordDetail in (select *
                                   from ASA_RECORD_DETAIL
                                  where ASA_RECORD_ID = iRecordId) loop
          declare
            lMovementId STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type   := getNewId;
          begin
            -- entrée en stock déchet
            STM_I_PRC_MOVEMENT.GenerateMovement(ioStockMovementId   => lMovementId
                                              , iGoodId             => ltplRecord.GCO_ASA_TO_REPAIR_ID
                                              , iMovementKindId     => ltplRecord.STM_REPAIR_MVT_KIND_ID
                                              , iExerciseId         => STM_I_LIB_EXERCISE.GetActiveExercise
                                              , iPeriodId           => STM_I_LIB_EXERCISE.GetPeriodId(lMovementDate)
                                              , iMvtDate            => lMovementDate
                                              , iValueDate          => lMovementDate
                                              , iStockId            => ltplRecord.STM_ASA_DEFECT_STK_ID
                                              , iLocationId         => ltplRecord.STM_ASA_DEFECT_LOC_ID
                                              , iThirdId            => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                              , iThirdAciId         => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                              , iThirdDeliveryId    => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                              , iThirdTariffId      => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                              , iRecordId           => ltplRecord.DOC_RECORD_ID
                                              , iChar1Id            => ltplRecordDetail.GCO_CHAR1_ID
                                              , iChar2Id            => ltplRecordDetail.GCO_CHAR2_ID
                                              , iChar3Id            => ltplRecordDetail.GCO_CHAR3_ID
                                              , iChar4Id            => ltplRecordDetail.GCO_CHAR4_ID
                                              , iChar5Id            => ltplRecordDetail.GCO_CHAR5_ID
                                              , iCharValue1         => ltplRecordDetail.RED_CHAR1_VALUE
                                              , iCharValue2         => ltplRecordDetail.RED_CHAR2_VALUE
                                              , iCharValue3         => ltplRecordDetail.RED_CHAR3_VALUE
                                              , iCharValue4         => ltplRecordDetail.RED_CHAR4_VALUE
                                              , iCharValue5         => ltplRecordDetail.RED_CHAR5_VALUE
                                              , iWording            => ltplRecord.ARE_NUMBER
                                              , iMvtQty             => ltplRecordDetail.RED_QTY_TO_REPAIR
                                              , iMvtPrice           => ltplRecordDetail.RED_QTY_TO_REPAIR * lCostPrice
                                              , iDocQty             => 0
                                              , iDocPrice           => 0
                                              , iUnitPrice          => lCostPrice
                                              , iRefUnitPrice       => lCostPrice
                                              , iAltQty1            => 0
                                              , iAltQty2            => 0
                                              , iAltQty3            => 0
                                              , iImpNumber1         => 0
                                              , iImpNumber2         => 0
                                              , iImpNumber3         => 0
                                              , iImpNumber4         => 0
                                              , iImpNumber5         => 0
                                              , iUpdateProv         => 0
                                              , iExtourneMvt        => 0
                                              , iRecStatus          => 9
                                               );

            -- maj infos sur le détail du produit à réparer
            declare
              ltRecordDetail FWK_I_TYP_DEFINITION.t_crud_def;
            begin
              FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordDetail, ltRecordDetail);
              FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordDetail, 'ASA_RECORD_DETAIL_ID', ltplRecordDetail.ASA_RECORD_DETAIL_ID);
              -- mouvement généré
              FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordDetail, 'STM_STOCK_MOVEMENT_ID', lMovementId);
              FWK_I_MGT_ENTITY.UpdateEntity(ltRecordDetail);
              FWK_I_MGT_ENTITY.Release(ltRecordDetail);
            end;
          end;
        end loop;
      end if;
    end loop;
  end PdtRepairMvt;

  /**
  * Description
  *   génération du mouvement de sortie du produit à échanger
  */
  procedure PdtExchMvt(iRecordId in ASA_RECORD.ASA_RECORD_ID%type, oErrMess out varchar2)
  is
    -- prix de revient
    lCostPrice    ASA_RECORD_COMP.ARC_COST_PRICE%type;
    lMovementDate date                                  := STM_I_LIB_EXERCISE.GetActiveDate(trunc(sysdate) );
    lCharId1      ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
    lCharId2      ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
    lCharId3      ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
    lCharId4      ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;
    lCharId5      ASA_RECORD_DETAIL.GCO_CHAR1_ID%type;

    /**
    * Description
    *   Contrôle de parité des caractérisations sur les détails
    */
    function CtrlCharDetExch(iRecordId in ASA_RECORD.ASA_RECORD_ID%type)
      return boolean
    is
      lCount pls_integer;
    begin
      select count(*)
        into lCount
        from ASA_RECORD_DETAIL RED
           , ASA_RECORD_EXCH_DETAIL REX
       where RED.ASA_RECORD_ID = iRecordId
         and REX.ASA_RECORD_DETAIL_ID = RED.ASA_RECORD_DETAIL_ID
         and (    (    lCharId1 is not null
                   and (   REX.REX_EXCH_CHAR1_VALUE is null
                        or REX.REX_EXCH_CHAR1_VALUE = 'N/A') )
              or (    lCharId2 is not null
                  and (   REX.REX_EXCH_CHAR2_VALUE is null
                       or REX.REX_EXCH_CHAR2_VALUE = 'N/A') )
              or (    lCharId3 is not null
                  and (   REX.REX_EXCH_CHAR3_VALUE is null
                       or REX.REX_EXCH_CHAR3_VALUE = 'N/A') )
              or (    lCharId4 is not null
                  and (   REX.REX_EXCH_CHAR4_VALUE is null
                       or REX.REX_EXCH_CHAR4_VALUE = 'N/A') )
              or (    lCharId5 is not null
                  and (   REX.REX_EXCH_CHAR5_VALUE is null
                       or REX.REX_EXCH_CHAR5_VALUE = 'N/A') )
             );

      return lCount = 0;
    end CtrlCharDetExch;
  begin
    for ltplRecord in (select *
                         from ASA_RECORD
                        where ASA_RECORD_ID = iRecordId) loop
      -- recherche des id de caractérisations car ils ne sont pas initialisé si aucune valeur n'est donnée
      GCO_I_LIB_CHARACTERIZATION.GetAllCharactID(iGoodId        => ltplRecord.GCO_ASA_EXCHANGE_ID
                                               , iNoStkChar     => 0
                                               , oCharactID_1   => lCharId1
                                               , oCharactID_2   => lCharId2
                                               , oCharactID_3   => lCharId3
                                               , oCharactID_4   => lCharId4
                                               , oCharactID_5   => lCharId5
                                                );
      -- prix de revient
      lCostPrice  := ASA_I_LIB_RECORD.GetGoodCostPrice(ltplRecord.GCO_ASA_EXCHANGE_ID, ltplRecord.PAC_CUSTOM_PARTNER_ID, sysdate);

      -- contrôle que le mouvement n'ait pas déjà été effectué
      if    ltplRecord.STM_ASA_EXCH_MVT_ID is not null
         or pIsDetExchMvtGen(iRecordId) then
        oErrMess  := PCS.PC_FUNCTIONS.TranslateWord('Mouvement de stock déjà effectué.');
        return;
      end if;

      -- contrôle des valeurs de caractérisations si pas de détails
      if     not pIsDetExchData(iRecordId)
         and (    (    lCharId1 is not null
                   and (   ltplRecord.ARE_EXCH_CHAR1_VALUE is null
                        or ltplRecord.ARE_EXCH_CHAR1_VALUE = 'N/A') )
              or (    lCharId2 is not null
                  and (   ltplRecord.ARE_EXCH_CHAR2_VALUE is null
                       or ltplRecord.ARE_EXCH_CHAR2_VALUE = 'N/A') )
              or (    lCharId3 is not null
                  and (   ltplRecord.ARE_EXCH_CHAR3_VALUE is null
                       or ltplRecord.ARE_EXCH_CHAR3_VALUE = 'N/A') )
              or (    lCharId4 is not null
                  and (   ltplRecord.ARE_EXCH_CHAR4_VALUE is null
                       or ltplRecord.ARE_EXCH_CHAR4_VALUE = 'N/A') )
              or (    lCharId5 is not null
                  and (   ltplRecord.ARE_EXCH_CHAR5_VALUE is null
                       or ltplRecord.ARE_EXCH_CHAR5_VALUE = 'N/A') )
             ) then
        oErrMess  := PCS.PC_FUNCTIONS.TranslateWord('Valeur de caractérisation manquante sur le produit à échanger.');
        return;
      end if;

      -- contrôle des valeurs de caractérisations sur les détails
      if     pIsDetExchData(iRecordId)
         and not CtrlCharDetExch(iRecordId) then
        oErrMess  := PCS.PC_FUNCTIONS.TranslateWord('Valeur de caractérisation manquante dans les détails du produit à échanger.');
        return;
      end if;

      if not pIsDetExchData(iRecordId) then
        declare
          lMovementId STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type   := getNewId;
        begin
          -- entrée en stock déchet
          STM_I_PRC_MOVEMENT.GenerateMovement(ioStockMovementId   => lMovementId
                                            , iGoodId             => ltplRecord.GCO_ASA_EXCHANGE_ID
                                            , iMovementKindId     => ltplRecord.STM_EXCH_MVT_KIND_ID
                                            , iExerciseId         => STM_I_LIB_EXERCISE.GetActiveExercise
                                            , iPeriodId           => STM_I_LIB_EXERCISE.GetPeriodId(lMovementDate)
                                            , iMvtDate            => lMovementDate
                                            , iValueDate          => lMovementDate
                                            , iStockId            => ltplRecord.STM_ASA_EXCH_STK_ID
                                            , iLocationId         => ltplRecord.STM_ASA_EXCH_LOC_ID
                                            , iThirdId            => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                            , iThirdAciId         => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                            , iThirdDeliveryId    => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                            , iThirdTariffId      => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                            , iRecordId           => ltplRecord.DOC_RECORD_ID
                                            , iChar1Id            => ltplRecord.GCO_EXCH_CHAR1_ID
                                            , iChar2Id            => ltplRecord.GCO_EXCH_CHAR2_ID
                                            , iChar3Id            => ltplRecord.GCO_EXCH_CHAR3_ID
                                            , iChar4Id            => ltplRecord.GCO_EXCH_CHAR4_ID
                                            , iChar5Id            => ltplRecord.GCO_EXCH_CHAR5_ID
                                            , iCharValue1         => ltplRecord.ARE_EXCH_CHAR1_VALUE
                                            , iCharValue2         => ltplRecord.ARE_EXCH_CHAR2_VALUE
                                            , iCharValue3         => ltplRecord.ARE_EXCH_CHAR3_VALUE
                                            , iCharValue4         => ltplRecord.ARE_EXCH_CHAR4_VALUE
                                            , iCharValue5         => ltplRecord.ARE_EXCH_CHAR5_VALUE
                                            , iWording            => ltplRecord.ARE_NUMBER
                                            , iMvtQty             => ltplRecord.ARE_EXCH_QTY
                                            , iMvtPrice           => ltplRecord.ARE_EXCH_QTY * lCostPrice
                                            , iDocQty             => 0
                                            , iDocPrice           => 0
                                            , iUnitPrice          => lCostPrice
                                            , iRefUnitPrice       => lCostPrice
                                            , iAltQty1            => 0
                                            , iAltQty2            => 0
                                            , iAltQty3            => 0
                                            , iImpNumber1         => 0
                                            , iImpNumber2         => 0
                                            , iImpNumber3         => 0
                                            , iImpNumber4         => 0
                                            , iImpNumber5         => 0
                                            , iUpdateProv         => 0
                                            , iExtourneMvt        => 0
                                            , iRecStatus          => 9
                                             );

          -- maj infos sur produit à réparer
          declare
            ltRecord FWK_I_TYP_DEFINITION.t_crud_def;
          begin
            FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecord, ltRecord);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecord, 'ASA_RECORD_ID', ltplRecord.ASA_RECORD_ID);
            -- mouvement généré
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecord, 'STM_ASA_EXCH_MVT_ID', lMovementId);
            FWK_I_MGT_ENTITY.UpdateEntity(ltRecord);
            FWK_I_MGT_ENTITY.Release(ltRecord);
          end;
        end;
      else
        for ltplRecordExchDetail in (select REX.*
                                       from ASA_RECORD_DETAIL RED
                                          , ASA_RECORD_EXCH_DETAIL REX
                                      where RED.ASA_RECORD_ID = iRecordId
                                        and REX.ASA_RECORD_DETAIL_ID = RED.ASA_RECORD_DETAIL_ID) loop
          declare
            lMovementId STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type   := getNewId;
          begin
            -- entrée en stock déchet
            STM_I_PRC_MOVEMENT.GenerateMovement(ioStockMovementId   => lMovementId
                                              , iGoodId             => ltplRecord.GCO_ASA_EXCHANGE_ID
                                              , iMovementKindId     => ltplRecord.STM_EXCH_MVT_KIND_ID
                                              , iExerciseId         => STM_I_LIB_EXERCISE.GetActiveExercise
                                              , iPeriodId           => STM_I_LIB_EXERCISE.GetPeriodId(lMovementDate)
                                              , iMvtDate            => lMovementDate
                                              , iValueDate          => lMovementDate
                                              , iStockId            => ltplRecord.STM_ASA_EXCH_STK_ID
                                              , iLocationId         => ltplRecord.STM_ASA_EXCH_LOC_ID
                                              , iThirdId            => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                              , iThirdAciId         => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                              , iThirdDeliveryId    => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                              , iThirdTariffId      => ltplRecord.PAC_CUSTOM_PARTNER_ID
                                              , iRecordId           => ltplRecord.DOC_RECORD_ID
                                              , iChar1Id            => ltplRecordExchDetail.GCO_EXCH_CHAR1_ID
                                              , iChar2Id            => ltplRecordExchDetail.GCO_EXCH_CHAR2_ID
                                              , iChar3Id            => ltplRecordExchDetail.GCO_EXCH_CHAR3_ID
                                              , iChar4Id            => ltplRecordExchDetail.GCO_EXCH_CHAR4_ID
                                              , iChar5Id            => ltplRecordExchDetail.GCO_EXCH_CHAR5_ID
                                              , iCharValue1         => ltplRecordExchDetail.REX_EXCH_CHAR1_VALUE
                                              , iCharValue2         => ltplRecordExchDetail.REX_EXCH_CHAR2_VALUE
                                              , iCharValue3         => ltplRecordExchDetail.REX_EXCH_CHAR3_VALUE
                                              , iCharValue4         => ltplRecordExchDetail.REX_EXCH_CHAR4_VALUE
                                              , iCharValue5         => ltplRecordExchDetail.REX_EXCH_CHAR5_VALUE
                                              , iWording            => ltplRecord.ARE_NUMBER
                                              , iMvtQty             => ltplRecordExchDetail.REX_QTY_EXCHANGED
                                              , iMvtPrice           => ltplRecordExchDetail.REX_QTY_EXCHANGED * lCostPrice
                                              , iDocQty             => 0
                                              , iDocPrice           => 0
                                              , iUnitPrice          => lCostPrice
                                              , iRefUnitPrice       => lCostPrice
                                              , iAltQty1            => 0
                                              , iAltQty2            => 0
                                              , iAltQty3            => 0
                                              , iImpNumber1         => 0
                                              , iImpNumber2         => 0
                                              , iImpNumber3         => 0
                                              , iImpNumber4         => 0
                                              , iImpNumber5         => 0
                                              , iUpdateProv         => 0
                                              , iExtourneMvt        => 0
                                              , iRecStatus          => 9
                                               );

            -- maj infos sur le détail du produit à réparer
            declare
              ltRecordExchDetail FWK_I_TYP_DEFINITION.t_crud_def;
            begin
              FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordExchDetail, ltRecordExchDetail);
              FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordExchDetail, 'ASA_RECORD_EXCH_DETAIL_ID', ltplRecordExchDetail.ASA_RECORD_EXCH_DETAIL_ID);
              -- mouvement généré
              FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordExchDetail, 'STM_STOCK_MOVEMENT_ID', lMovementId);
              FWK_I_MGT_ENTITY.UpdateEntity(ltRecordExchDetail);
              FWK_I_MGT_ENTITY.Release(ltRecordExchDetail);
            end;
          end;
        end loop;
      end if;
    end loop;
  end PdtExchMvt;

  /**
  * Description
  *   Extourne des mouvements de composants
  */
  procedure ReverseCpMvt(iRecordCompId in ASA_RECORD_COMP.ASA_RECORD_COMP_ID%type, oErrMess out varchar2)
  is
  begin
    for ltplComp in (select ASA_RECORD_COMP_ID
                          , STM_COMP_STOCK_MVT_ID
                       from ASA_RECORD_COMP
                      where ASA_RECORD_COMP_ID = iRecordCompId) loop
      -- génération du mouvement d'extourne
      STM_I_PRC_MOVEMENT.GenerateReversalMvt(ltplComp.STM_COMP_STOCK_MVT_ID);

      -- maj infos sur composant
      declare
        ltRecordComp FWK_I_TYP_DEFINITION.t_crud_def;
      begin
        FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordComp, ltRecordComp);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComp, 'ASA_RECORD_COMP_ID', ltplComp.ASA_RECORD_COMP_ID);
        -- reset du mouvement
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltRecordComp, 'STM_COMP_STOCK_MVT_ID');
        FWK_I_MGT_ENTITY.UpdateEntity(ltRecordComp);
        FWK_I_MGT_ENTITY.Release(ltRecordComp);
      end;
    end loop;
  end ReverseCpMvt;

  /**
  * Description
  *   Extourne des mouvements de sortie de composants de l'atelier
  */
  procedure ReverseCpFactoryOutputMvt(iRecordCompId in ASA_RECORD_COMP.ASA_RECORD_COMP_ID%type, oErrMess out varchar2)
  is
  begin
    for ltplComp in (select ASA_RECORD_COMP_ID
                          , STM_WORK_STOCK_MOVEMENT_ID
                       from ASA_RECORD_COMP
                      where ASA_RECORD_COMP_ID = iRecordCompId
                        and STM_WORK_STOCK_MOVEMENT_ID is not null) loop
      -- génération du mouvement d'extourne
      STM_I_PRC_MOVEMENT.GenerateReversalMvt(ltplComp.STM_WORK_STOCK_MOVEMENT_ID);

      -- maj infos sur composant
      declare
        ltRecordComp FWK_I_TYP_DEFINITION.t_crud_def;
      begin
        FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordComp, ltRecordComp);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComp, 'ASA_RECORD_COMP_ID', ltplComp.ASA_RECORD_COMP_ID);
        -- reset du mouvement
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltRecordComp, 'STM_WORK_STOCK_MOVEMENT_ID');
        FWK_I_MGT_ENTITY.UpdateEntity(ltRecordComp);
        FWK_I_MGT_ENTITY.Release(ltRecordComp);
      end;
    end loop;
  end ReverseCpFactoryOutputMvt;

  /**
  * procedure ReversePdtRepairMvt
  * Description
  *   extourne du mouvement d'entrée du produit défectueux
  * @created fp 06.10.2011
  * @lastUpdate
  * @public
  * @param  iRecordId : dossier SAV
  */
  procedure ReversePdtRepairMvt(iRecordId in ASA_RECORD.ASA_RECORD_ID%type, oErrMess out varchar2)
  is
  begin
    -- si on a des informations présente dans les détails
    if FWK_I_LIB_ENTITY.RecordsExists('ASA_RECORD_DETAIL', 'ASA_RECORD_ID', iRecordId) then
      -- si on a des mouvements générés
      if pIsDetMvtGen(iRecordId) then
        for ltplRecordDetail in (select ASA_RECORD_DETAIL_ID
                                      , STM_STOCK_MOVEMENT_ID
                                   from ASA_RECORD_DETAIL
                                  where ASA_RECORD_ID = iRecordId
                                    and STM_STOCK_MOVEMENT_ID is not null) loop
          -- génération du mouvement d'extourne
          STM_I_PRC_MOVEMENT.GenerateReversalMvt(ltplRecordDetail.STM_STOCK_MOVEMENT_ID);

          -- maj infos sur le ddetail de dossier
          declare
            ltRecordDetail FWK_I_TYP_DEFINITION.t_crud_def;
          begin
            FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordDetail, ltRecordDetail);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordDetail, 'ASA_RECORD_DETAIL_ID', ltplRecordDetail.ASA_RECORD_DETAIL_ID);
            -- reset du mouvement
            FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltRecordDetail, 'STM_STOCK_MOVEMENT_ID');
            FWK_I_MGT_ENTITY.UpdateEntity(ltRecordDetail);
            FWK_I_MGT_ENTITY.Release(ltRecordDetail);
          end;
        end loop;
      else
        null;
      end if;
    -- pas de détails
    else
      for ltplRecord in (select STM_ASA_DEFECT_MVT_ID
                           from ASA_RECORD
                          where ASA_RECORD_ID = iRecordId
                            and STM_ASA_DEFECT_MVT_ID is not null) loop
        -- si on a un mouvement à extourner
        if ltplRecord.STM_ASA_DEFECT_MVT_ID is not null then
          -- génération du mouvement d'extourne
          STM_I_PRC_MOVEMENT.GenerateReversalMvt(ltplRecord.STM_ASA_DEFECT_MVT_ID);

          -- maj infos sur dossier
          declare
            ltRecord FWK_I_TYP_DEFINITION.t_crud_def;
          begin
            FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecord, ltRecord);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecord, 'ASA_RECORD_ID', iRecordId);
            -- reset du mouvement
            FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltRecord, 'STM_ASA_DEFECT_MVT_ID');
            FWK_I_MGT_ENTITY.UpdateEntity(ltRecord);
            FWK_I_MGT_ENTITY.Release(ltRecord);
          end;
        else
          null;
        end if;
      end loop;
    end if;
  end ReversePdtRepairMvt;

  /**
  * Description
  *   extourne du mouvement d'entrée du produit défectueux
  */
  procedure ReversePdtExchMvt(iRecordId in ASA_RECORD.ASA_RECORD_ID%type, oErrMess out varchar2)
  is
  begin
    -- si on a des informations présente dans les détails
    if pIsDetExchData(iRecordId) then
      -- si des mouvements sont générés
      if pIsDetExchMvtGen(iRecordId) then
        for ltplRecordExchDetail in (select REX.ASA_RECORD_EXCH_DETAIL_ID
                                          , REX.STM_STOCK_MOVEMENT_ID
                                       from ASA_RECORD_DETAIL RED
                                          , ASA_RECORD_EXCH_DETAIL REX
                                      where RED.ASA_RECORD_ID = iRecordId
                                        and REX.ASA_RECORD_DETAIL_ID = RED.ASA_RECORD_DETAIL_ID
                                        and REX.STM_STOCK_MOVEMENT_ID is not null) loop
          -- génération du mouvement d'extourne
          STM_I_PRC_MOVEMENT.GenerateReversalMvt(ltplRecordExchDetail.STM_STOCK_MOVEMENT_ID);

          -- maj infos sur le détail du produit à réparer
          declare
            ltRecordExchDetail FWK_I_TYP_DEFINITION.t_crud_def;
          begin
            FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordExchDetail, ltRecordExchDetail);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordExchDetail, 'ASA_RECORD_EXCH_DETAIL_ID', ltplRecordExchDetail.ASA_RECORD_EXCH_DETAIL_ID);
            -- mouvement généré
            FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltRecordExchDetail, 'STM_STOCK_MOVEMENT_ID');
            FWK_I_MGT_ENTITY.UpdateEntity(ltRecordExchDetail);
            FWK_I_MGT_ENTITY.Release(ltRecordExchDetail);
          end;
        end loop;
      else
        null;
      end if;
    -- pas de détails
    else
      for ltplRecord in (select STM_ASA_EXCH_MVT_ID
                           from ASA_RECORD
                          where ASA_RECORD_ID = iRecordId
                            and STM_ASA_EXCH_MVT_ID is not null) loop
        -- si il  y a un mouvement à extourner
        if ltplRecord.STM_ASA_EXCH_MVT_ID is not null then
          -- génération du mouvement d'extourne
          STM_I_PRC_MOVEMENT.GenerateReversalMvt(ltplRecord.STM_ASA_EXCH_MVT_ID);

          -- maj infos sur dossier
          declare
            ltRecord FWK_I_TYP_DEFINITION.t_crud_def;
          begin
            FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecord, ltRecord);
            FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecord, 'ASA_RECORD_ID', iRecordId);
            -- reset du mouvement
            FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltRecord, 'STM_ASA_EXCH_MVT_ID');
            FWK_I_MGT_ENTITY.UpdateEntity(ltRecord);
            FWK_I_MGT_ENTITY.Release(ltRecord);
          end;
        else
          null;
        end if;
      end loop;
    end if;
  end ReversePdtExchMvt;
end ASA_PRC_STOCK_MOVEMENTS;
