--------------------------------------------------------
--  DDL for Package Body DOC_INIT_MOVEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_INIT_MOVEMENT" 
is
  /**
  * Description
  *   Return report movement ID
  */
  function getReportMovementKindId
    return STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type
  is
    vResult STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
  begin
    -- recherche de l'id du genre de mouvement de report d'exercice
    select stm_movement_kind_id
      into vResult
      from stm_movement_kind
     where c_movement_sort = 'ENT'
       and c_movement_type = 'EXE'
       and c_movement_code = '004';

    return vResult;
  end getReportMovementKindId;

  /**
  * Description
  *              fonction qui retourne la quantité document pour le mouvement en fonction
  *              de la quantité valeur de la position et des détail précédant
  */
  function GetDocumentQty(
    aPositionId  in doc_position.doc_position_id%type
  , aPosValueQty in doc_position.pos_value_quantity%type
  , aDetailId    in doc_position_detail.doc_position_detail_id%type
  , aDetailQty   in doc_position_detail.pde_final_quantity%type
  )
    return number
  is
    qtyUsed STM_STOCK_MOVEMENT.SMO_DOCUMENT_QUANTITY%type;
  begin
    if nvl(detail_id, 0) <> aDetailId then
      detail_id    := aDetailId;

      select nvl(sum(pde_final_quantity), 0)
        into qtyUsed
        from doc_position_detail pde
       where pde.doc_position_id = aPositionId
         and pde.doc_position_detail_id < aDetailId;

      documentQty  := least(aPosValueQty - qtyUsed, aDetailQty);
    end if;

    return documentQty;
  end GetDocumentQty;

  /**
  * Description  Procedure appelée depuis le trigger d'insertion des mouvements
  *              de stock. Elle met à jour la table DOC_PIC_RELEASE_BUFFER
  */
  procedure InsertPicBuffer(
    position_id       in doc_position.doc_position_id%type
  , movement_date     in date
  , movement_quantity in stm_stock_movement.smo_movement_quantity%type
  , movement_kind_id  in stm_movement_kind.stm_movement_kind_id%type
  )
  is
  begin
    -- 1 : Utilisation du Plan Commerciale, Mise à jour des Réalisés
    -- 3 : Utilisation PC et PDP, Mise à jour des Commandes et des Réalisés
    if     position_id is not null
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
        select init_id_seq.nextval
             , POS.PAC_REPRESENTATIVE_ID
             , POS.PAC_THIRD_ID
             , POS.GCO_GOOD_ID
             , PDT.GCO2_GCO_GOOD_ID
             , movement_date
             , decode(MOK.C_MOVEMENT_SORT, 'ENT', -1, 'SOR', 1) * movement_quantity
             , decode(MOK.C_MOVEMENT_SORT, 'ENT', -1, 'SOR', 1) *
               decode(POS.POS_FINAL_QUANTITY_SU * movement_quantity, 0, 0, POS.POS_NET_VALUE_EXCL_B / POS.POS_FINAL_QUANTITY_SU * movement_quantity)
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from DOC_POSITION POS
             , STM_MOVEMENT_KIND MOK
             , GCO_PRODUCT PDT
         where POS.DOC_POSITION_ID = position_id
           and MOK.STM_MOVEMENT_KIND_ID = movement_kind_id
           and MOK.MOK_PIC_USE = 1
           and POS.GCO_GOOD_ID = PDT.GCO_GOOD_ID(+);
    end if;
  end InsertPicBuffer;

  /**
  * Description
  *   Génération des mouvements sur les matières précieuses du pied de document
  */
  procedure pDocPositionAlloyMovements(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    lDEF_MAT_STM_STOCK_ID  STM_STOCK.STM_STOCK_ID%type;
    lACS_LOCAL_CURRENCY_ID DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
    lGAS_WEIGHT_MAT        DOC_GAUGE_STRUCTURED.GAS_WEIGHT_MAT%type;
    lSTM_STOCK_MOVEMENT_ID STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
    lSMO_ALT_QTY_1         STM_STOCK_MOVEMENT.SMO_MVT_ALTERNATIV_QTY_1%type;
    lSMO_ALT_QTY_2         STM_STOCK_MOVEMENT.SMO_MVT_ALTERNATIV_QTY_2%type;
    lSMO_ALT_QTY_3         STM_STOCK_MOVEMENT.SMO_MVT_ALTERNATIV_QTY_3%type;
    lSMO_MOVEMENT_PRICE_B  STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type;
    lSMO_MOVEMENT_PRICE_E  STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type;
    lSMO_MOVEMENT_QUANTITY STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type;

    -- Informations sur les matières précieuses sur les positions du document
    cursor crPositionAlloy(cDocumentID in number, cDefStockID in number, cMngtMode in varchar2)
    is
      select   DPA.DOC_POSITION_ALLOY_ID
             , GAL.GCO_GOOD_ID
             , POS.DOC_POSITION_ID
             , (DMT.DMT_NUMBER || '/' || POS.POS_NUMBER || ' - ' || decode(cMngtMode, '1', GAL.GAL_ALLOY_REF, DPA.DIC_BASIS_MATERIAL_ID) ) SMO_WORDING
             , LOC.STM_STOCK_ID
             , LOC.STM_LOCATION_ID
             , DOC_FOOT_ALLOY_FUNCTIONS.GetAdvanceWeight(cDocumentID, null, null, DPA.DOA_WEIGHT_DELIVERY, DPA.DOA_LOSS, DPA.DOA_WEIGHT_INVEST)
                                                                                                                                          SMO_MOVEMENT_QUANTITY
             , DOC_LIB_ALLOY.GetAlloyRate(cDocumentId, DPA.GCO_ALLOY_ID, DPA.DIC_BASIS_MATERIAL_ID, DPA.DOA_RATE_DATE) SMO_UNIT_PRICE
             , nvl( (select GAR.GAR_INIT_QTY_MVT
                       from DOC_GAUGE_RECEIPT GAR
                      where GAR.DOC_GAUGE_RECEIPT_ID = (select max(PDE.DOC_GAUGE_RECEIPT_ID)
                                                          from DOC_POSITION_DETAIL PDE
                                                         where PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID) ), 1) GAR_INIT_QTY_MVT
             , nvl( (select GAR.GAR_INIT_PRICE_MVT
                       from DOC_GAUGE_RECEIPT GAR
                      where GAR.DOC_GAUGE_RECEIPT_ID = (select max(PDE.DOC_GAUGE_RECEIPT_ID)
                                                          from DOC_POSITION_DETAIL PDE
                                                         where PDE.DOC_POSITION_ID = POS.DOC_POSITION_ID) ), 1) GAR_INIT_PRICE_MVT
          from DOC_DOCUMENT DMT
             , DOC_POSITION_ALLOY DPA
             , DOC_POSITION POS
             , STM_LOCATION LOC
             , GCO_ALLOY GAL
         where DMT.DOC_DOCUMENT_ID = cDocumentID
           and DPA.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID
           and POS.DOC_POSITION_ID = DPA.DOC_POSITION_ID
           and LOC.STM_STOCK_ID = DPA.STM_STOCK_ID
           and LOC.LOC_CLASSIFICATION = (select min(LOC_CLASSIFICATION)
                                           from STM_LOCATION
                                          where STM_STOCK_ID = LOC.STM_STOCK_ID)
           and (    (     (cMngtMode = '1')
                     and (DPA.GCO_ALLOY_ID is not null) )
                or (     (cMngtMode = '2')
                    and (DPA.DIC_BASIS_MATERIAL_ID is not null) ) )
           and (    (    cMngtMode = '1'
                     and GAL.GCO_ALLOY_ID = DPA.GCO_ALLOY_ID)
                or (    cMngtMode = '2'
                    and GAL.GCO_ALLOY_ID = (select max(GAC.GCO_ALLOY_ID)
                                              from GCO_ALLOY_COMPONENT GAC
                                             where GAC.DIC_BASIS_MATERIAL_ID = DPA.DIC_BASIS_MATERIAL_ID
                                               and GAC.GAC_RATE = 100) )
               )
      order by GAL.GCO_GOOD_ID;
  begin
    -- Gestion des comptes poids matières précieuses
    if DOC_I_LIB_CONSTANT.gcCfgMetalInfo then
      -- Recherche globale d'informations pour la génération des mouvements
      for ltplDocInfo in (select nvl(GAS.GAS_WEIGHT_MAT, 0) GAS_WEIGHT_MAT
                               , nvl(GAS.GAS_METAL_ACCOUNT_MGM, 0) GAS_METAL_ACCOUNT_MGM
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
                                    ) THIRD_METAL_ACCOUNT
                               , GAU.C_ADMIN_DOMAIN
                            from DOC_DOCUMENT DMT
                               , DOC_GAUGE GAU
                               , DOC_GAUGE_STRUCTURED GAS
                               , DOC_GAUGE_POSITION GAP
                               , STM_MOVEMENT_KIND MOK
                               , PAC_SUPPLIER_PARTNER SUP
                               , PAC_CUSTOM_PARTNER CUS
                           where DMT.DOC_DOCUMENT_ID = aDocumentID
                             and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
                             and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
                             and GAS.DOC_GAUGE_ID = GAP.DOC_GAUGE_ID
                             and GAP.GAP_DEFAULT = 1
                             and GAP.C_GAUGE_TYPE_POS = '1'
                             and nvl(GAP.STM_MA_MOVEMENT_KIND_ID, GAP.STM_MOVEMENT_KIND_ID) = MOK.STM_MOVEMENT_KIND_ID
                             and DMT.PAC_THIRD_ID = SUP.PAC_SUPPLIER_PARTNER_ID(+)
                             and DMT.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)) loop
        -- Recherche le compte poids par défaut
        begin
          select STO.STM_STOCK_ID DEFAULT_STOCK
            into lDEF_MAT_STM_STOCK_ID
            from STM_STOCK STO
           where nvl(STO.STO_METAL_ACCOUNT, 0) = 1
             and nvl(STO.STO_DEFAULT_METAL_ACCOUNT, 0) = 1;
        exception
          when no_data_found then
            lDEF_MAT_STM_STOCK_ID  := null;
        end;

        -- Recherche la monnaie de base
        lACS_LOCAL_CURRENCY_ID  := ACS_FUNCTION.GetLocalCurrencyId;

        -- Gabarit si "Gestion des poids des matières précieuses" = OUI
        -- Gabarit si "Mise à jour compte poids matières précieuses" = OUI
        -- Tiers si "Gestion compte poids" = 1
        -- Type de mouvement trouvé sur le gabarit position type '1'
        -- Si Mode de gestion matières précieuses du Tiers renseigné
        if     (ltplDocInfo.GAS_WEIGHT_MAT = 1)
           and (ltplDocInfo.GAS_METAL_ACCOUNT_MGM = 1)
           and (ltplDocInfo.THIRD_METAL_ACCOUNT = 1)
           and (ltplDocInfo.STM_MOVEMENT_KIND_ID is not null)
           and (ltplDocInfo.C_MATERIAL_MGNT_MODE is not null) then
          -- Balayer les matières précieuses sur les positions du document
          for tplPositionAlloy in crPositionAlloy(aDocumentID, lDEF_MAT_STM_STOCK_ID, ltplDocInfo.C_MATERIAL_MGNT_MODE) loop
            -- Vérifier qu'il y a un bien lié à l'alliage
            if tplPositionAlloy.GCO_GOOD_ID is null then
              raise_application_error(-20928, PCS.PC_FUNCTIONS.TranslateWord('PCS - Le bien n''est pas défini sur l''alliage !') );
            else
              lSTM_STOCK_MOVEMENT_ID  := null;

              -- Rechercher les qtés alternatives
              select decode(PDT.PDT_ALTERNATIVE_QUANTITY_1, 1, PDT.PDT_CONVERSION_FACTOR_1 * tplPositionAlloy.SMO_MOVEMENT_QUANTITY, 0)
                                                                                                                                     SMO_ALTERNATIVE_QUANTITY_1
                   , decode(PDT.PDT_ALTERNATIVE_QUANTITY_2, 1, PDT.PDT_CONVERSION_FACTOR_2 * tplPositionAlloy.SMO_MOVEMENT_QUANTITY, 0)
                                                                                                                                     SMO_ALTERNATIVE_QUANTITY_2
                   , decode(PDT.PDT_ALTERNATIVE_QUANTITY_3, 1, PDT.PDT_CONVERSION_FACTOR_3 * tplPositionAlloy.SMO_MOVEMENT_QUANTITY, 0)
                                                                                                                                     SMO_ALTERNATIVE_QUANTITY_3
                into lSMO_ALT_QTY_1
                   , lSMO_ALT_QTY_2
                   , lSMO_ALT_QTY_3
                from GCO_PRODUCT PDT
               where PDT.GCO_GOOD_ID = tplPositionAlloy.GCO_GOOD_ID;

              -- Détermine la quantité du mouvement
              if (tplPositionAlloy.GAR_INIT_QTY_MVT = 0) then
                lSMO_MOVEMENT_QUANTITY  := 0;
              else
                lSMO_MOVEMENT_QUANTITY  := tplPositionAlloy.SMO_MOVEMENT_QUANTITY;
              end if;

              -- Détermine le prix du mouvement.
              if tplPositionAlloy.GAR_INIT_PRICE_MVT = 0 then
                lSMO_MOVEMENT_PRICE_B  := 0;
              elsif(ltplDocInfo.ACS_FINANCIAL_CURRENCY_ID <> lACS_LOCAL_CURRENCY_ID) then
                -- Convertit le montant facturé de la monnaie du document en monnaie de base pour valorisé le mouvement
                -- de stock du compte poids.
                ACS_FUNCTION.ConvertAmount(tplPositionAlloy.SMO_MOVEMENT_QUANTITY * nvl(tplPositionAlloy.SMO_UNIT_PRICE, 0)
                                         , ltplDocInfo.ACS_FINANCIAL_CURRENCY_ID
                                         , lACS_LOCAL_CURRENCY_ID
                                         , ltplDocInfo.DMT_DATE_DOCUMENT
                                         , ltplDocInfo.DMT_RATE_OF_EXCHANGE
                                         , ltplDocInfo.DMT_BASE_PRICE
                                         , 0
                                         , lSMO_MOVEMENT_PRICE_E
                                         , lSMO_MOVEMENT_PRICE_B
                                          );
              else
                lSMO_MOVEMENT_PRICE_B  := tplPositionAlloy.SMO_MOVEMENT_QUANTITY * nvl(tplPositionAlloy.SMO_UNIT_PRICE, 0);
              end if;

              -- Création du mouvement
              STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId     => lSTM_STOCK_MOVEMENT_ID
                                              , iGoodId               => tplPositionAlloy.GCO_GOOD_ID
                                              , iMovementKindId       => ltplDocInfo.STM_MOVEMENT_KIND_ID
                                              , iExerciseId           => ltplDocInfo.STM_EXERCISE_ID
                                              , iPeriodId             => ltplDocInfo.STM_PERIOD_ID
                                              , iMvtDate              => ltplDocInfo.SMO_MOVEMENT_DATE
                                              , iValueDate            => ltplDocInfo.SMO_MOVEMENT_DATE
                                              , iStockId              => tplPositionAlloy.STM_STOCK_ID
                                              , iLocationId           => tplPositionAlloy.STM_LOCATION_ID
                                              , iThirdId              => ltplDocInfo.PAC_THIRD_ID
                                              , iThirdAciId           => ltplDocInfo.PAC_THIRD_ACI_ID
                                              , iThirdDeliveryId      => ltplDocInfo.PAC_THIRD_DELIVERY_ID
                                              , iThirdTariffId        => ltplDocInfo.PAC_THIRD_TARIFF_ID
                                              , iRecordId             => ltplDocInfo.DOC_RECORD_ID
                                              , iWording              => tplPositionAlloy.SMO_WORDING
                                              , iMvtQty               => lSMO_MOVEMENT_QUANTITY
                                              , iMvtPrice             => lSMO_MOVEMENT_PRICE_B
                                              , iUnitPrice            => nvl(tplPositionAlloy.SMO_UNIT_PRICE, 0)
                                              , iAltQty1              => lSMO_ALT_QTY_1
                                              , iAltQty2              => lSMO_ALT_QTY_2
                                              , iAltQty3              => lSMO_ALT_QTY_3
                                              , iFinancialCharging    => ltplDocInfo.SMO_FINANCIAL_CHARGING
                                              , iUpdateProv           => 1
                                              , iExtourneMvt          => 0
                                              , iRecStatus            => 11
                                              , iDocPositionId        => tplPositionAlloy.DOC_POSITION_ID
                                              , iDocPositionAlloyID   => tplPositionAlloy.DOC_POSITION_ALLOY_ID
                                               );
            end if;
          end loop;
        end if;
      end loop;
    end if;
  end pDocPositionAlloyMovements;

  /**
  * Procedure DOC_PROV_QTY
  * Description
  *    procedure de mise à jour des quantités provisoires des position de stock
  */
  procedure doc_prov_qty(
    good_id                     in gco_good.gco_good_id%type
  , update_mode                    varchar2
  , move_sort                      stm_movement_kind.c_movement_sort%type
  , verify_char                    stm_movement_kind.mok_verify_characterization%type
  , parity_move_kind_id            stm_stock_movement.stm_stock_movement_id%type
  , charact_id_1                   stm_stock_movement.gco_characterization_id%type
  , charact_id_2                   stm_stock_movement.gco_gco_characterization_id%type
  , charact_id_3                   stm_stock_movement.gco2_gco_characterization_id%type
  , charact_id_4                   stm_stock_movement.gco3_gco_characterization_id%type
  , charact_id_5                   stm_stock_movement.gco4_gco_characterization_id%type
  , charact_val_1                  stm_stock_movement.smo_characterization_value_1%type
  , charact_val_2                  stm_stock_movement.smo_characterization_value_2%type
  , charact_val_3                  stm_stock_movement.smo_characterization_value_3%type
  , charact_val_4                  stm_stock_movement.smo_characterization_value_4%type
  , charact_val_5                  stm_stock_movement.smo_characterization_value_5%type
  , stock_id                       stm_stock_movement.stm_stock_id%type
  , location_id                    stm_stock_movement.stm_location_id%type
  , trans_stock_id                 stm_stock_movement.stm_stock_id%type
  , trans_location_id              stm_stock_movement.stm_location_id%type
  , movement_quantity              stm_stock_movement.smo_movement_quantity%type
  , iCharacterizationTwinValue1 in varchar2 default null
  , iCharacterizationTwinValue2 in varchar2 default null
  , iCharacterizationTwinValue3 in varchar2 default null
  , iCharacterizationTwinValue4 in varchar2 default null
  , iCharacterizationTwinValue5 in varchar2 default null
  )
  is
    movement_sort                 STM_MOVEMENT_KIND.C_MOVEMENT_SORT%type;
    mvt_stock_id                  STM_STOCK.STM_STOCK_ID%type;
    mvt_location_id               STM_LOCATION.STM_LOCATION_ID%type;
    stock_position_id             STM_STOCK_POSITION.STM_STOCK_POSITION_ID%type;
    element_number_id_1           STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    element_number_id_2           STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    element_number_id_3           STM_ELEMENT_NUMBER.STM_ELEMENT_NUMBER_ID%type;
    output_qty                    STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type;
    input_qty                     STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type;
    characterization_id_1         GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    characterization_id_2         GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    characterization_id_3         GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    characterization_id_4         GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    characterization_id_5         GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type;
    characterization_value_1      STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
    characterization_value_2      STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type;
    characterization_value_3      STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type;
    characterization_value_4      STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type;
    characterization_value_5      STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type;
    characterization_twin_value_1 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_1%type;
    characterization_twin_value_2 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_2%type;
    characterization_twin_value_3 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_3%type;
    characterization_twin_value_4 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_4%type;
    characterization_twin_value_5 STM_STOCK_POSITION.SPO_CHARACTERIZATION_VALUE_5%type;
    stockmanagement               GCO_PRODUCT.PDT_STOCK_MANAGEMENT%type;
    boucle                        number(1);
    modemaj                       varchar2(2);

    cursor crParity(idMOVEMENT_KIND stm_movement_kind.stm_movement_kind_id%type)
    is
      select   STM_LOCATION_ID
             , STM_LOCATION.STM_STOCK_ID
          from STM_LOCATION
             , STM_MOVEMENT_KIND
         where STM_MOVEMENT_KIND_ID = idMOVEMENT_KIND
           and STM_LOCATION.STM_STOCK_ID = STM_MOVEMENT_KIND.STM_STOCK_ID
      order by LOC_CLASSIFICATION;

    cursor stk_char(
      char1_id       stm_stock_movement.gco_characterization_id%type
    , char2_id       stm_stock_movement.gco_gco_characterization_id%type
    , char3_id       stm_stock_movement.gco2_gco_characterization_id%type
    , char4_id       stm_stock_movement.gco3_gco_characterization_id%type
    , char5_id       stm_stock_movement.gco4_gco_characterization_id%type
    , char1_val      stm_stock_movement.smo_characterization_value_1%type
    , char2_val      stm_stock_movement.smo_characterization_value_2%type
    , char3_val      stm_stock_movement.smo_characterization_value_3%type
    , char4_val      stm_stock_movement.smo_characterization_value_4%type
    , char5_val      stm_stock_movement.smo_characterization_value_5%type
    , char1_twin_val stm_stock_movement.smo_characterization_value_1%type
    , char2_twin_val stm_stock_movement.smo_characterization_value_2%type
    , char3_twin_val stm_stock_movement.smo_characterization_value_3%type
    , char4_twin_val stm_stock_movement.smo_characterization_value_4%type
    , char5_twin_val stm_stock_movement.smo_characterization_value_5%type
    )
    is
      select   GCO_CHARACTERIZATION_ID
             , char1_val char_value
             , char1_twin_val char_twin_value
             , 1 ordre
          from GCO_CHARACTERIZATION CHA
             , GCO_PRODUCT PDT
         where GCO_CHARACTERIZATION_ID = char1_id
           and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
           and CHA_STOCK_MANAGEMENT = 1
           and PDT_STOCK_MANAGEMENT = 1
      union
      select   GCO_CHARACTERIZATION_ID
             , char2_val char_value
             , char2_twin_val char_twin_value
             , 2 ordre
          from GCO_CHARACTERIZATION CHA
             , GCO_PRODUCT PDT
         where GCO_CHARACTERIZATION_ID = char2_id
           and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
           and CHA_STOCK_MANAGEMENT = 1
           and PDT_STOCK_MANAGEMENT = 1
      union
      select   GCO_CHARACTERIZATION_ID
             , char3_val char_value
             , char3_twin_val char_twin_value
             , 3 ordre
          from GCO_CHARACTERIZATION CHA
             , GCO_PRODUCT PDT
         where GCO_CHARACTERIZATION_ID = char3_id
           and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
           and CHA_STOCK_MANAGEMENT = 1
           and PDT_STOCK_MANAGEMENT = 1
      union
      select   GCO_CHARACTERIZATION_ID
             , char4_val char_value
             , char4_twin_val char_twin_value
             , 4 ordre
          from GCO_CHARACTERIZATION CHA
             , GCO_PRODUCT PDT
         where GCO_CHARACTERIZATION_ID = char4_id
           and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
           and CHA_STOCK_MANAGEMENT = 1
           and PDT_STOCK_MANAGEMENT = 1
      union
      select   GCO_CHARACTERIZATION_ID
             , char5_val char_value
             , char5_twin_val char_twin_value
             , 5 ordre
          from GCO_CHARACTERIZATION CHA
             , GCO_PRODUCT PDT
         where GCO_CHARACTERIZATION_ID = char5_id
           and PDT.GCO_GOOD_ID = CHA.GCO_GOOD_ID
           and CHA_STOCK_MANAGEMENT = 1
           and PDT_STOCK_MANAGEMENT = 1
      order by ordre;

    ordre                         number(1);
    spoStockQuantity              STM_STOCK_POSITION.SPO_STOCK_QUANTITY%type;
    spoAssignQuantity             STM_STOCK_POSITION.SPO_ASSIGN_QUANTITY%type;
    spoProvisoryInput             STM_STOCK_POSITION.SPO_PROVISORY_INPUT%type;
    lQualityStatusId              STM_ELEMENT_NUMBER.GCO_QUALITY_STATUS_ID%type;
  begin
    movement_sort  := MOVE_SORT;

    if sign(MOVEMENT_QUANTITY) = -1 then
      -- Mode pour la mise à jour des éléments existant
      modemaj  := '00';
    else
      -- Mode pour la création d'éléments
      modemaj  := null;
    end if;

    -- Recherche si le produit fait l'objet d'une gestion de stock ou pas
    select max(PDT_STOCK_MANAGEMENT)
      into stockmanagement
      from GCO_PRODUCT
     where GCO_GOOD_ID = GOOD_ID;

    if     good_id is not null
       and movement_quantity <> 0 then
      if location_id is not null then
        -- La mise à jour des quantitiés se fait uniquement pour les produits gérés en stock
        if     stockmanagement is not null
           and (stockmanagement = 1) then
          open stk_char(CHARACT_ID_1
                      , CHARACT_ID_2
                      , CHARACT_ID_3
                      , CHARACT_ID_4
                      , CHARACT_ID_5
                      , charact_val_1
                      , charact_val_2
                      , charact_val_3
                      , charact_val_4
                      , charact_val_5
                      , iCharacterizationTwinValue1
                      , iCharacterizationTwinValue2
                      , iCharacterizationTwinValue3
                      , iCharacterizationTwinValue4
                      , iCharacterizationTwinValue5
                       );

          fetch stk_char
           into characterization_id_1
              , characterization_value_1
              , characterization_twin_value_1
              , ordre;

          fetch stk_char
           into characterization_id_2
              , characterization_value_2
              , characterization_twin_value_2
              , ordre;

          fetch stk_char
           into characterization_id_3
              , characterization_value_3
              , characterization_twin_value_3
              , ordre;

          fetch stk_char
           into characterization_id_4
              , characterization_value_4
              , characterization_twin_value_4
              , ordre;

          fetch stk_char
           into characterization_id_5
              , characterization_value_5
              , characterization_twin_value_5
              , ordre;

          close stk_char;

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
          if    not(    characterization_id_1 is not null
                    and characterization_value_1 is null)
             or not(    characterization_id_2 is not null
                    and characterization_value_2 is null)
             or not(    characterization_id_3 is not null
                    and characterization_value_3 is null)
             or not(    characterization_id_4 is not null
                    and characterization_value_4 is null)
             or not(    characterization_id_5 is not null
                    and characterization_value_5 is null) then
            STM_I_PRC_STOCK_POSITION.GetElementNumber(iGoodId                       => good_id
                                                    , iUpdateMode                   => update_mode
                                                    , iMovementSort                 => movement_sort
                                                    , iCharacterizationId           => CHARACT_ID_1
                                                    , iCharacterization2Id          => CHARACT_ID_2
                                                    , iCharacterization3Id          => CHARACT_ID_3
                                                    , iCharacterization4Id          => CHARACT_ID_4
                                                    , iCharacterization5Id          => CHARACT_ID_5
                                                    , iCharacterizationValue1       => CHARACT_VAL_1
                                                    , iCharacterizationValue2       => CHARACT_VAL_2
                                                    , iCharacterizationValue3       => CHARACT_VAL_3
                                                    , iCharacterizationValue4       => CHARACT_VAL_4
                                                    , iCharacterizationValue5       => CHARACT_VAL_5
                                                    , iVerifyChar                   => VERIFY_CHAR
                                                    , iElementStatus                => modemaj
                                                    , ioElementNumberId1            => element_number_id_1
                                                    , ioElementNumberId2            => element_number_id_2
                                                    , ioElementNumberId3            => element_number_id_3
                                                    , ioQualityStatusId             => lQualityStatusId
                                                    , iCharacterizationTwinValue1   => characterization_twin_value_1
                                                    , iCharacterizationTwinValue2   => characterization_twin_value_2
                                                    , iCharacterizationTwinValue3   => characterization_twin_value_3
                                                    , iCharacterizationTwinValue4   => characterization_twin_value_4
                                                    , iCharacterizationTwinValue5   => characterization_twin_value_5
                                                     );
          end if;

          -- initialisation de la variable de l'id de localisation
          mvt_location_id  := LOCATION_ID;
          mvt_stock_id     := STOCK_ID;
          --initialisation de la variable de boucle
          boucle           := 0;

          while boucle <= 1 loop
            -- test si on a affaire . une entr'e ou une sortie
            if movement_sort = 'ENT' then
              input_qty   := MOVEMENT_QUANTITY;
              output_qty  := 0;
            else
              input_qty   := 0;
              output_qty  := MOVEMENT_QUANTITY;
            end if;

            -- recherche si on a déjà une position de stock
            begin
              select     STM_STOCK_POSITION_ID
                       , SPO_STOCK_QUANTITY
                       , SPO_ASSIGN_QUANTITY
                       , SPO_PROVISORY_INPUT
                    into stock_position_id
                       , spoStockQuantity
                       , spoAssignQuantity
                       , spoProvisoryInput
                    from STM_STOCK_POSITION
                   where STM_STOCK_ID = mvt_stock_id
                     and STM_LOCATION_ID = mvt_location_id
                     and GCO_GOOD_ID = good_id
                     and nvl(SPO_CHARACTERIZATION_VALUE_1, 'NULL') = nvl(characterization_value_1, 'NULL')
                     and nvl(SPO_CHARACTERIZATION_VALUE_2, 'NULL') = nvl(characterization_value_2, 'NULL')
                     and nvl(SPO_CHARACTERIZATION_VALUE_3, 'NULL') = nvl(characterization_value_3, 'NULL')
                     and nvl(SPO_CHARACTERIZATION_VALUE_4, 'NULL') = nvl(characterization_value_4, 'NULL')
                     and nvl(SPO_CHARACTERIZATION_VALUE_5, 'NULL') = nvl(characterization_value_5, 'NULL')
              for update;
            exception
              when no_data_found then
                stock_position_id  := null;
            end;
            -- test si on a trouvé une position ou s'il faut en créer une
            if stock_position_id is not null then
              -- Si on se trouve sur mvt de transfert et que l'emplacement source/cible est le même :
              -- On effectue la màj de la qté entrée prov et qté sortie prov d'un seul coup
              -- Sauf pour le mvt de transfert des positions de type 7 et 8 (code mvt = 021 ou 022)
              if     (nvl(parity_move_kind_id, 0) <> 0)
                 and (location_id = trans_location_id) then
                declare
                  lvMvtCode STM_MOVEMENT_KIND.C_MOVEMENT_CODE%type;
                begin
                  -- Rechercher code mvt
                  select nvl(max(C_MOVEMENT_CODE), '-1')
                    into lvMvtCode
                    from STM_MOVEMENT_KIND
                   where STM_MOVEMENT_KIND_ID = parity_move_kind_id;

                  -- Effectuer la màj d'un seul coup si pas mvt de transfert des pos type 7 et 8
                  if (lvMvtCode not in('021', '022') ) then
                    input_qty   := MOVEMENT_QUANTITY;
                    output_qty  := MOVEMENT_QUANTITY;
                    -- on ne repasse pas dans la boucle
                    boucle      := 2;
                  end if;
                end;
              end if;

              -- Lors de la suppression d'une position, on supprime certaine attributions besoin/stock associées
              -- à la position de stock courante pour garantir l'intégrité de la containte entre la quantité
              -- effective et la quantité attribuée
              if     (movement_sort = 'ENT')
                 and (update_mode like 'D%')
                 and (spoStockQuantity + spoProvisoryInput + input_qty < spoAssignQuantity) then
                FAL_PRC_REPORT_ATTRIB.CheckAttributionLink(stock_position_id, spoAssignQuantity -(spoStockQuantity + spoProvisoryInput + input_qty) );
              end if;

              update STM_STOCK_POSITION
                 set SPO_PROVISORY_INPUT = nvl(SPO_PROVISORY_INPUT, 0) + input_qty
                   , SPO_PROVISORY_OUTPUT = nvl(SPO_PROVISORY_OUTPUT, 0) + output_qty
                   , A_DATEMOD = sysdate
                   , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
               where STM_STOCK_POSITION_ID = stock_position_id;

              -- dans le cas ou il existerait une position d'inventaire, l'effacement est impossible
              -- mais on ne doit pas générer d'exception
              begin
                delete from STM_STOCK_POSITION
                      where STM_STOCK_POSITION_ID = stock_position_id
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
            elsif substr(Update_mode, 1, 1) <> 'D' then
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
                         , A_DATECRE
                         , A_IDCRE
                          )
                   values (init_id_seq.nextval
                         , mvt_stock_id
                         , mvt_location_id
                         , '01'
                         , GOOD_ID
                         , element_number_id_1
                         , element_number_id_2
                         , element_number_id_3
                         , characterization_id_1
                         , characterization_id_2
                         , characterization_id_3
                         , characterization_id_4
                         , characterization_id_5
                         , characterization_value_1
                         , characterization_value_2
                         , characterization_value_3
                         , characterization_value_4
                         , characterization_value_5
                         , input_qty
                         , output_qty
                         , sysdate
                         , PCS.PC_I_LIB_SESSION.GetUserIni
                          );
            end if;

            -- on est pas sur un mouvement de type transfert, on ne repasse pas dans la boucle
            if    (parity_move_kind_id is null)
               or (parity_move_kind_id = 0) then
              -- on ne repasse pas dans la boucle
              boucle  := 2;
            -- si on a affaire . un mouvement de type transfert on va mettre à jour la compensation
            else
              -- si on a pas d'j. pass' dans l'initialisation du transfert
              if boucle = 0 then
                -- recherche de la sorte de mouvement (ENT,SOR) du mouvement de parit'
                select C_MOVEMENT_SORT
                  into movement_sort
                  from STM_MOVEMENT_KIND
                 where STM_MOVEMENT_KIND_ID = parity_move_kind_id;

                if (trans_location_id is null) then
                  -- pas de réservation si cible non définie
                  boucle  := 1;
                else
                  -- recheche de l'id du stock de transfert en fonction de l'emplacament de tranfert
                  select STM_STOCK_ID
                    into mvt_stock_id
                    from STM_LOCATION
                   where STM_LOCATION_ID = trans_location_id;

                  -- traite l'emplacement de transfert
                  mvt_location_id  := trans_location_id;
                end if;
              end if;

              boucle  := boucle + 1;
            end if;
          end loop;
        end if;
      else
        if     good_id is not null
           and stockmanagement is not null
           and (stockmanagement <> 1) then
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
          STM_I_PRC_STOCK_POSITION.GetElementNumber(iGoodId                   => good_id
                                                  , iUpdateMode               => update_mode
                                                  , iMovementSort             => movement_sort
                                                  , iCharacterizationId       => CHARACT_ID_1
                                                  , iCharacterization2Id      => CHARACT_ID_2
                                                  , iCharacterization3Id      => CHARACT_ID_3
                                                  , iCharacterization4Id      => CHARACT_ID_4
                                                  , iCharacterization5Id      => CHARACT_ID_5
                                                  , iCharacterizationValue1   => CHARACT_VAL_1
                                                  , iCharacterizationValue2   => CHARACT_VAL_2
                                                  , iCharacterizationValue3   => CHARACT_VAL_3
                                                  , iCharacterizationValue4   => CHARACT_VAL_4
                                                  , iCharacterizationValue5   => CHARACT_VAL_5
                                                  , iVerifyChar               => 0
                                                  , iElementStatus            => modemaj
                                                  , ioElementNumberId1        => element_number_id_1
                                                  , ioElementNumberId2        => element_number_id_2
                                                  , ioElementNumberId3        => element_number_id_3
                                                  , ioQualityStatusId         => lQualityStatusId
                                                   );
        end if;
      end if;
    else
      if     good_id is not null
         and stockmanagement is not null
         and (stockmanagement <> 1) then
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
        STM_I_PRC_STOCK_POSITION.GetElementNumber(iGoodId                   => good_id
                                                , iUpdateMode               => update_mode
                                                , iMovementSort             => movement_sort
                                                , iCharacterizationId       => CHARACT_ID_1
                                                , iCharacterization2Id      => CHARACT_ID_2
                                                , iCharacterization3Id      => CHARACT_ID_3
                                                , iCharacterization4Id      => CHARACT_ID_4
                                                , iCharacterization5Id      => CHARACT_ID_5
                                                , iCharacterizationValue1   => CHARACT_VAL_1
                                                , iCharacterizationValue2   => CHARACT_VAL_2
                                                , iCharacterizationValue3   => CHARACT_VAL_3
                                                , iCharacterizationValue4   => CHARACT_VAL_4
                                                , iCharacterizationValue5   => CHARACT_VAL_5
                                                , iVerifyChar               => 0
                                                , iElementStatus            => modemaj
                                                , ioElementNumberId1        => element_number_id_1
                                                , ioElementNumberId2        => element_number_id_2
                                                , ioElementNumberId3        => element_number_id_3
                                                , ioQualityStatusId         => lQualityStatusId
                                                 );
      end if;
    end if;
  end DOC_PROV_QTY;

  procedure DocExtourneOutputMovements(documentId in doc_document.doc_document_id%type)
  is
    cursor crExtourneOutput(document_id doc_document.doc_document_id%type)
    is
      select   SMO.STM_STOCK_MOVEMENT_ID
             , PDE.PDE_MOVEMENT_QUANTITY +(nvl(PDE.PDE_BALANCE_QUANTITY_PARENT, 0) * POS.POS_CONVERT_FACTOR) SMO_MOVEMENT_QUANTITY
             , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT), DMT.DMT_DATE_DOCUMENT) SMO_MOVEMENT_DATE
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_1, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_1, SMO.SMO_CHARACTERIZATION_VALUE_1) SMO_CHARACTERIZATION_VALUE_1
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_2, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_2, SMO.SMO_CHARACTERIZATION_VALUE_2) SMO_CHARACTERIZATION_VALUE_2
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_3, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_3, SMO.SMO_CHARACTERIZATION_VALUE_3) SMO_CHARACTERIZATION_VALUE_3
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_4, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_4, SMO.SMO_CHARACTERIZATION_VALUE_4) SMO_CHARACTERIZATION_VALUE_4
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_5, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_5, SMO.SMO_CHARACTERIZATION_VALUE_5) SMO_CHARACTERIZATION_VALUE_5
             , decode(PDE.STM_STM_LOCATION_ID, null, 1, PDE.STM_LOCATION_ID, 0, 1) SMO_UPDATE_PROV
             , PDE.DOC_POSITION_DETAIL_ID
          from STM_STOCK_MOVEMENT SMO
             , DOC_POSITION_DETAIL PDE
             , DOC_POSITION POS
             , STM_MOVEMENT_KIND MOK
             , DOC_DOCUMENT DMT
             , GCO_PRODUCT PDT
             , GCO_GOOD GOO
             , DOC_GAUGE_RECEIPT GAR
             , DOC_GAUGE_POSITION GAP
         where PDE.DOC_DOCUMENT_ID = document_id
           and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and SMO.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID
           and SMO.STM_STOCK_MOVEMENT_ID <= nvl(SMO.STM_STM_STOCK_MOVEMENT_ID, SMO.STM_STOCK_MOVEMENT_ID)   /* Ne prend que les mouvements principaux */
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
  begin
    for tplExtourneOutput in crExtourneOutput(documentId) loop
      -- extournes des mouvements de sortie
      STM_PRC_MOVEMENT.GenerateReversalMvt(iSTM_STOCK_MOVEMENT_ID   => tplExtourneOutput.STM_STOCK_MOVEMENT_ID
                                         , iMvtQty                  => tplExtourneOutput.SMO_MOVEMENT_QUANTITY
                                         , iUpdateProv              => tplExtourneOutput.SMO_UPDATE_PROV
                                         , iCharValue1              => tplExtourneOutput.SMO_CHARACTERIZATION_VALUE_1
                                         , iCharValue2              => tplExtourneOutput.SMO_CHARACTERIZATION_VALUE_2
                                         , iCharValue3              => tplExtourneOutput.SMO_CHARACTERIZATION_VALUE_3
                                         , iCharValue4              => tplExtourneOutput.SMO_CHARACTERIZATION_VALUE_4
                                         , iCharValue5              => tplExtourneOutput.SMO_CHARACTERIZATION_VALUE_5
                                         , iMvtDate                 => tplExtourneOutput.SMO_MOVEMENT_DATE
                                         , iPositionDetailId        => tplExtourneOutput.DOC_POSITION_DETAIL_ID
                                          );
    end loop;
  end DocExtourneOutputMovements;

  procedure DocMainMovements(documentId in doc_document.doc_document_id%type, wording in stm_stock_movement.smo_wording%type)
  is
    cursor crMainMovement(
      document_id           doc_document.doc_document_id%type
    , wording               stm_stock_movement.smo_wording%type
    , reportMovementKind_id stm_movement_kind.stm_movement_kind_id%type
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
             , decode(PDE.STM_STM_LOCATION_ID, null, 1, PDE.STM_LOCATION_ID, 0, 1) SMO_UPDATE_PROV
             , POS.GCO_GOOD_ID
             , decode(GAR.GAR_TRANSFERT_MOVEMENT_DATE, 1, SMO.STM_STOCK_MOVEMENT_ID) SMO_MOVEMENT_ORDER_KEY
             , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT), DMT.DMT_DATE_DOCUMENT) SMO_MOVEMENT_DATE
             , PDE.PDE_MOVEMENT_DATE SMO_VALUE_DATE
             , nvl(wording, DMT.DMT_NUMBER || decode(POS.POS_NUMBER, 0, null, null, null, ' / ') || to_char(POS.POS_NUMBER) ) SMO_WORDING
             , PDE.PDE_MOVEMENT_QUANTITY
             , PDE.PDE_MOVEMENT_VALUE
             , decode(GAP_VALUE_QUANTITY
                    , 0, PDE_FINAL_QUANTITY
                    , decode(sign(POS_FINAL_QUANTITY - POS_VALUE_QUANTITY)
                           , 1, DOC_INIT_MOVEMENT.GetDocumentQty(POS.DOC_POSITION_ID, POS.POS_VALUE_QUANTITY, PDE.DOC_POSITION_DETAIL_ID
                                                               , PDE.PDE_FINAL_QUANTITY)
                           , PDE.PDE_FINAL_QUANTITY
                            )
                     ) SMO_DOCUMENT_QUANTITY
             , decode(GAP_VALUE_QUANTITY
                    , 0, PDE_FINAL_QUANTITY
                    , decode(sign(POS_FINAL_QUANTITY - POS_VALUE_QUANTITY)
                           , 1, DOC_INIT_MOVEMENT.GetDocumentQty(POS.DOC_POSITION_ID, POS.POS_VALUE_QUANTITY, PDE.DOC_POSITION_DETAIL_ID
                                                               , PDE.PDE_FINAL_QUANTITY)
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
           and not SMO.STM_MOVEMENT_KIND_ID(+) = reportMovementKind_id
           and nvl(SMO.SMO_EXTOURNE_MVT(+), 0) = 0
           and POS.POS_GENERATE_MOVEMENT = 0
           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and MOK.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID
           and GAP.DOC_GAUGE_POSITION_ID = POS.DOC_GAUGE_POSITION_ID
           and PDE.DOC_DOCUMENT_ID = document_id
      order by POS.GCO_GOOD_ID
             , PDE.PDE_CHARACTERIZATION_VALUE_1
             , PDE.PDE_CHARACTERIZATION_VALUE_2
             , PDE.PDE_CHARACTERIZATION_VALUE_3
             , PDE.PDE_CHARACTERIZATION_VALUE_4
             , PDE.PDE_CHARACTERIZATION_VALUE_5
             , POS.POS_NUMBER;

    stockMovementId      STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
    vFinancialAccountID  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vDivisionAccountID   ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vCPNAccountID        ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vCDAAccountID        ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vPFAccountID         ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vPJAccountID         ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vFinancialAccountID2 ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vDivisionAccountID2  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vCPNAccountID2       ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vCDAAccountID2       ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vPFAccountID2        ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vPJAccountID2        ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vAccountInfo         ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    vAccountInfo2        ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    lnNewStockMovementId STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
  begin
    for tplMainMovement in crMainMovement(documentId, wording, getReportMovementKindId) loop
      stockMovementId                      := null;
      vFinancialAccountID                  := null;
      vDivisionAccountID                   := null;
      vCPNAccountID                        := null;
      vCDAAccountID                        := null;
      vPFAccountID                         := null;
      vPJAccountID                         := null;
      vFinancialAccountID2                 := null;
      vDivisionAccountID2                  := null;
      vCPNAccountID2                       := null;
      vCDAAccountID2                       := null;
      vPFAccountID2                        := null;
      vPJAccountID2                        := null;
      vAccountInfo.DEF_HRM_PERSON          := null;
      vAccountInfo.FAM_FIXED_ASSETS_ID     := null;
      vAccountInfo.C_FAM_TRANSACTION_TYP   := null;
      vAccountInfo.DEF_DIC_IMP_FREE1       := null;
      vAccountInfo.DEF_DIC_IMP_FREE2       := null;
      vAccountInfo.DEF_DIC_IMP_FREE3       := null;
      vAccountInfo.DEF_DIC_IMP_FREE4       := null;
      vAccountInfo.DEF_DIC_IMP_FREE5       := null;
      vAccountInfo.DEF_TEXT1               := null;
      vAccountInfo.DEF_TEXT2               := null;
      vAccountInfo.DEF_TEXT3               := null;
      vAccountInfo.DEF_TEXT4               := null;
      vAccountInfo.DEF_TEXT5               := null;
      vAccountInfo.DEF_NUMBER1             := null;
      vAccountInfo.DEF_NUMBER2             := null;
      vAccountInfo.DEF_NUMBER3             := null;
      vAccountInfo.DEF_NUMBER4             := null;
      vAccountInfo.DEF_NUMBER5             := null;
      vAccountInfo2.DEF_HRM_PERSON         := null;
      vAccountInfo2.FAM_FIXED_ASSETS_ID    := null;
      vAccountInfo2.C_FAM_TRANSACTION_TYP  := null;
      vAccountInfo2.DEF_DIC_IMP_FREE1      := null;
      vAccountInfo2.DEF_DIC_IMP_FREE2      := null;
      vAccountInfo2.DEF_DIC_IMP_FREE3      := null;
      vAccountInfo2.DEF_DIC_IMP_FREE4      := null;
      vAccountInfo2.DEF_DIC_IMP_FREE5      := null;
      vAccountInfo2.DEF_TEXT1              := null;
      vAccountInfo2.DEF_TEXT2              := null;
      vAccountInfo2.DEF_TEXT3              := null;
      vAccountInfo2.DEF_TEXT4              := null;
      vAccountInfo2.DEF_TEXT5              := null;
      vAccountInfo2.DEF_NUMBER1            := null;
      vAccountInfo2.DEF_NUMBER2            := null;
      vAccountInfo2.DEF_NUMBER3            := null;
      vAccountInfo2.DEF_NUMBER4            := null;
      vAccountInfo2.DEF_NUMBER5            := null;

      /*
      raise_application_error(-20001,
       vFinancialAccountID            || chr(13) ||
       vDivisionAccountID             || chr(13) ||
       vCPNAccountID                  || chr(13) ||
       vCDAAccountID                  || chr(13) ||
       vPFAccountID                   || chr(13) ||
       vPJAccountID                   || chr(13) ||
       vFinancialAccountID2           || chr(13) ||
       vDivisionAccountID2            || chr(13) ||
       vCPNAccountID2                 || chr(13) ||
       vCDAAccountID2                 || chr(13) ||
       vPFAccountID2                  || chr(13) ||
       vPJAccountID2                  || chr(13) ||
       vAccountInfo.DEF_HRM_PERSON    || chr(13) ||
       vAccountInfo.DEF_DIC_IMP_FREE1 || chr(13) ||
       vAccountInfo.DEF_DIC_IMP_FREE2 || chr(13) ||
       vAccountInfo.DEF_DIC_IMP_FREE3 || chr(13) ||
       vAccountInfo.DEF_DIC_IMP_FREE4 || chr(13) ||
       vAccountInfo.DEF_DIC_IMP_FREE5 || chr(13) ||
       vAccountInfo.DEF_TEXT1         || chr(13) ||
       vAccountInfo.DEF_TEXT2         || chr(13) ||
       vAccountInfo.DEF_TEXT3         || chr(13) ||
       vAccountInfo.DEF_TEXT4         || chr(13) ||
       vAccountInfo.DEF_TEXT5         || chr(13) ||
       vAccountInfo.DEF_NUMBER1       || chr(13) ||
       vAccountInfo.DEF_NUMBER2       || chr(13) ||
       vAccountInfo.DEF_NUMBER3       || chr(13) ||
       vAccountInfo.DEF_NUMBER4       || chr(13) ||
       vAccountInfo.DEF_NUMBER5);
      */
      if tplMainMovement.C_POS_CREATE_MODE in('205', '206') then
        -- Attraper l'exception, parce que la position source n'a pas forcement de mvt.
        begin
          select SMO_MOVEMENT_ORDER_KEY
            into tplMainMovement.SMO_MOVEMENT_ORDER_KEY
            from STM_STOCK_MOVEMENT
           where DOC_POSITION_DETAIL_ID = tplMainMovement.DOC_COPY_POSITION_DETAIL_ID
             and STM_STM_STOCK_MOVEMENT_ID(+) is null
             and not STM_MOVEMENT_KIND_ID(+) = getReportMovementKindId
             and SMO_EXTOURNE_MVT = 0;
        exception
          when no_data_found then
            tplMainMovement.SMO_MOVEMENT_ORDER_KEY  := null;
        end;
      end if;

      if tplMainMovement.STM_STOCK_MOVEMENT_ID is not null then
        lnNewStockMovementId  := INIT_ID_SEQ.nextval;

        update DOC_POSITION_DETAIL
           set STM_STOCK_MOVEMENT_ID = lnNewStockMovementId
         where STM_STOCK_MOVEMENT_ID = tplMainMovement.STM_STOCK_MOVEMENT_ID;

        update STM_TRANSFER_ATTRIB
           set STM_STOCK_MOVEMENT_ID = lnNewStockMovementId
         where STM_STOCK_MOVEMENT_ID = tplMainMovement.STM_STOCK_MOVEMENT_ID;

        StockMovementId       := lnNewStockMovementId;
      end if;

      STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => stockMovementId
                                      , iGoodId                => tplMainMovement.GCO_GOOD_ID
                                      , iMovementKindId        => tplMainMovement.STM_MOVEMENT_KIND_ID
                                      , iExerciseId            => tplMainMovement.STM_EXERCISE_ID
                                      , iPeriodId              => tplMainMovement.STM_PERIOD_ID
                                      , iMvtDate               => tplMainMovement.SMO_MOVEMENT_DATE
                                      , iValueDate             => tplMainMovement.SMO_VALUE_DATE
                                      , iStockId               => tplMainMovement.STM_STOCK_ID
                                      , iLocationId            => tplMainMovement.STM_LOCATION_ID
                                      , iThirdId               => tplMainMovement.PAC_THIRD_ID
                                      , iThirdAciId            => tplMainMovement.PAC_THIRD_ACI_ID
                                      , iThirdDeliveryId       => tplMainMovement.PAC_THIRD_DELIVERY_ID
                                      , iThirdTariffId         => tplMainMovement.PAC_THIRD_TARIFF_ID
                                      , iRecordId              => tplMainMovement.DOC_RECORD_ID
                                      , iChar1Id               => tplMainMovement.GCO_CHARACTERIZATION_ID
                                      , iChar2Id               => tplMainMovement.GCO_GCO_CHARACTERIZATION_ID
                                      , iChar3Id               => tplMainMovement.GCO2_GCO_CHARACTERIZATION_ID
                                      , iChar4Id               => tplMainMovement.GCO3_GCO_CHARACTERIZATION_ID
                                      , iChar5Id               => tplMainMovement.GCO4_GCO_CHARACTERIZATION_ID
                                      , iCharValue1            => tplMainMovement.PDE_CHARACTERIZATION_VALUE_1
                                      , iCharValue2            => tplMainMovement.PDE_CHARACTERIZATION_VALUE_2
                                      , iCharValue3            => tplMainMovement.PDE_CHARACTERIZATION_VALUE_3
                                      , iCharValue4            => tplMainMovement.PDE_CHARACTERIZATION_VALUE_4
                                      , iCharValue5            => tplMainMovement.PDE_CHARACTERIZATION_VALUE_5
                                      , iMovement2Id           => null   -- STM_STOCK_MOVEMENT.STM_STM_STOCK_MOVEMENT_ID%type,
                                      , iMovement3Id           => null   -- STM_STOCK_MOVEMENT.STM2_STM_STOCK_MOVEMENT_ID%type,
                                      , iWording               => tplMainMovement.SMO_WORDING
                                      , iExternalDocument      => null   --STM_STOCK_MOVEMENT.SMO_EXTERNAL_DOCUMENT%type,
                                      , iExternalPartner       => null   --STM_STOCK_MOVEMENT.SMO_EXTERNAL_PARTNER%type,
                                      , iMvtQty                => tplMainMovement.PDE_MOVEMENT_QUANTITY   -- STM_STOCK_MOVEMENT.SMO_MOVEMENT_QUANTITY%type,
                                      , iMvtPrice              => tplMainMovement.PDE_MOVEMENT_VALUE   -- STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type,
                                      , iDocQty                => tplMainMovement.SMO_DOCUMENT_QUANTITY
                                      , iDocPrice              => tplMainMovement.SMO_DOCUMENT_PRICE
                                      , iUnitPrice             => tplMainMovement.SMO_UNIT_PRICE
                                      , iRefUnitPrice          => tplMainMovement.SMO_REFERENCE_UNIT_PRICE
                                      , iAltQty1               => tplMainMovement.SMO_ALTERNATIVE_QUANTITY_1
                                      , iAltQty2               => tplMainMovement.SMO_ALTERNATIVE_QUANTITY_2
                                      , iAltQty3               => tplMainMovement.SMO_ALTERNATIVE_QUANTITY_3
                                      , iDocPositionDetailId   => tplMainMovement.DOC_POSITION_DETAIL_ID
                                      , iDocPositionId         => tplMainMovement.DOC_POSITION_ID
                                      , iFinancialAccountId    => vFinancialAccountID   -- ACS_FINANCIAL_ACCOUNT_ID,
                                      , iDivisionAccountId     => vDivisionAccountID   -- ACS_DIVISION_ACCOUNT_ID,
                                      , iAFinancialAccountId   => vFinancialAccountID2   -- ACS_ACS_FINANCIAL_ACCOUNT_ID,
                                      , iADivisionAccountId    => vDivisionAccountID2   -- ACS_ACS_DIVISION_ACCOUNT_ID,
                                      , iCPNAccountId          => vCPNAccountID   -- ACS_CPN_ACCOUNT_ID,
                                      , iACPNAccountId         => vCPNAccountID2   -- ACS_ACS_CPN_ACCOUNT_ID,
                                      , iCDAAccountId          => vCDAAccountID   -- ACS_CDA_ACCOUNT_ID,
                                      , iACDAAccountId         => vCDAAccountID2   -- ACS_ACS_CDA_ACCOUNT_ID,
                                      , iPFAccountId           => vPFAccountID   -- ACS_PF_ACCOUNT_ID,
                                      , iAPFAccountId          => vPFAccountID2   -- ACS_ACS_PF_ACCOUNT_ID,
                                      , iPJAccountId           => vPJAccountID   -- ACS_PJ_ACCOUNT_ID,
                                      , iAPJAccountId          => vPJAccountID2   -- ACS_ACS_PJ_ACCOUNT_ID,
                                      , iFamFixedAssetsId      => vAccountInfo.FAM_FIXED_ASSETS_ID
                                      , iFamTransactionTyp     => vAccountInfo.C_FAM_TRANSACTION_TYP
                                      , iHrmPersonId           => ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(vAccountInfo.DEF_HRM_PERSON)
                                      , iDicImpfree1Id         => vAccountInfo.DEF_DIC_IMP_FREE1
                                      , iDicImpfree2Id         => vAccountInfo.DEF_DIC_IMP_FREE2
                                      , iDicImpfree3Id         => vAccountInfo.DEF_DIC_IMP_FREE3
                                      , iDicImpfree4Id         => vAccountInfo.DEF_DIC_IMP_FREE4
                                      , iDicImpfree5Id         => vAccountInfo.DEF_DIC_IMP_FREE5
                                      , iImpText1              => vAccountInfo.DEF_TEXT1
                                      , iImpText2              => vAccountInfo.DEF_TEXT2
                                      , iImpText3              => vAccountInfo.DEF_TEXT3
                                      , iImpText4              => vAccountInfo.DEF_TEXT4
                                      , iImpText5              => vAccountInfo.DEF_TEXT5
                                      , iImpNumber1            => to_number(vAccountInfo.DEF_NUMBER1)
                                      , iImpNumber2            => to_number(vAccountInfo.DEF_NUMBER2)
                                      , iImpNumber3            => to_number(vAccountInfo.DEF_NUMBER3)
                                      , iImpNumber4            => to_number(vAccountInfo.DEF_NUMBER4)
                                      , iImpNumber5            => to_number(vAccountInfo.DEF_NUMBER5)
                                      , iFinancialCharging     => tplMainMovement.SMO_FINANCIAL_CHARGING
                                      , iUpdateProv            => tplMainMovement.SMO_UPDATE_PROV
                                      , iExtourneMvt           => 0   -- STM_STOCK_MOVEMENT.SMO_EXTOURNE_MVT%type,
                                      , iRecStatus             => 2   -- STM_STOCK_MOVEMENT.A_RECSTATUS%type
                                      , iOrderKey              => tplMainMovement.SMO_MOVEMENT_ORDER_KEY
                                       );
    end loop;
  end DocMainMovements;

  procedure DocExtourneInputMovements(documentId in doc_document.doc_document_id%type)
  is
    cursor crExtourneInput(document_id doc_document.doc_document_id%type, reportMovementKind_id stm_movement_kind.stm_movement_kind_id%type)
    is
      select   SMO.STM_STOCK_MOVEMENT_ID
             , decode(GAR.GAR_TRANSFERT_MOVEMENT_DATE, 1, SMO.STM_STOCK_MOVEMENT_ID, null) SMO_MOVEMENT_ORDER_KEY
             , PDE.PDE_MOVEMENT_QUANTITY +(nvl(PDE.PDE_BALANCE_QUANTITY_PARENT, 0) * POS.POS_CONVERT_FACTOR) SMO_MOVEMENT_QUANTITY
             , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT), DMT.DMT_DATE_DOCUMENT) SMO_MOVEMENT_DATE
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_1, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_1, SMO.SMO_CHARACTERIZATION_VALUE_1) SMO_CHARACTERIZATION_VALUE_1
             , SMO.GCO_GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_2, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_2, SMO.SMO_CHARACTERIZATION_VALUE_2) SMO_CHARACTERIZATION_VALUE_2
             , SMO.GCO2_GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_3, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_3, SMO.SMO_CHARACTERIZATION_VALUE_3) SMO_CHARACTERIZATION_VALUE_3
             , SMO.GCO3_GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_4, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_4, SMO.SMO_CHARACTERIZATION_VALUE_4) SMO_CHARACTERIZATION_VALUE_4
             , SMO.GCO4_GCO_CHARACTERIZATION_ID
             , decode(SMO.SMO_CHARACTERIZATION_VALUE_5, 'N/A', PDE.PDE_CHARACTERIZATION_VALUE_5, SMO.SMO_CHARACTERIZATION_VALUE_5) SMO_CHARACTERIZATION_VALUE_5
             , decode(PDE.STM_STM_LOCATION_ID, null, 1, PDE.STM_LOCATION_ID, 0, 1) SMO_UPDATE_PROV
             , PDE.DOC_POSITION_DETAIL_ID
          from STM_STOCK_MOVEMENT SMO
             , DOC_POSITION_DETAIL PDE
             , DOC_POSITION POS
             , DOC_DOCUMENT DMT
             , STM_MOVEMENT_KIND MOK
             , GCO_PRODUCT PDT
             , GCO_GOOD GOO
             , DOC_GAUGE_RECEIPT GAR
             , DOC_GAUGE_POSITION GAP
         where PDE.DOC_DOCUMENT_ID = document_id
           and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and SMO.DOC_POSITION_DETAIL_ID = PDE.DOC_DOC_POSITION_DETAIL_ID
           and SMO.STM_STOCK_MOVEMENT_ID <= nvl(SMO.STM_STM_STOCK_MOVEMENT_ID, SMO.STM_STOCK_MOVEMENT_ID)   /* Ne prend que les mouvements principaux */
           and MOK.STM_MOVEMENT_KIND_ID = SMO.STM_MOVEMENT_KIND_ID
           and not MOK.STM_MOVEMENT_KIND_ID = reportMovementKind_id
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
  begin
    for tplExtourneInput in crExtourneInput(documentId, getReportMovementKindId) loop
      STM_PRC_MOVEMENT.GenerateReversalMvt(iSTM_STOCK_MOVEMENT_ID   => tplExtourneInput.STM_STOCK_MOVEMENT_ID
                                         , iMvtQty                  => tplExtourneInput.SMO_MOVEMENT_QUANTITY
                                         , iUpdateProv              => tplExtourneInput.SMO_UPDATE_PROV
                                         , iCharValue1              => tplExtourneInput.SMO_CHARACTERIZATION_VALUE_1
                                         , iCharValue2              => tplExtourneInput.SMO_CHARACTERIZATION_VALUE_2
                                         , iCharValue3              => tplExtourneInput.SMO_CHARACTERIZATION_VALUE_3
                                         , iCharValue4              => tplExtourneInput.SMO_CHARACTERIZATION_VALUE_4
                                         , iCharValue5              => tplExtourneInput.SMO_CHARACTERIZATION_VALUE_5
                                         , iMvtDate                 => tplExtourneInput.SMO_MOVEMENT_DATE
                                         , iPositionDetailId        => tplExtourneInput.DOC_POSITION_DETAIL_ID
                                          );
    end loop;
  end DocExtourneInputMovements;

  procedure DocTransfertMovements(documentId in doc_document.doc_document_id%type, wording in stm_stock_movement.smo_wording%type)
  is
    cursor crTransfert(
      document_id           doc_document.doc_document_id%type
    , wording               stm_stock_movement.smo_wording%type
    , reportMovementKind_id stm_movement_kind.stm_movement_kind_id%type
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
             , decode(PDE.STM_STM_LOCATION_ID, null, 1, PDE.STM_LOCATION_ID, 0, 1) SMO_UPDATE_PROV
             , POS.GCO_GOOD_ID
             , decode(GAR.GAR_TRANSFERT_MOVEMENT_DATE, 1, SMO2.STM_STOCK_MOVEMENT_ID) SMO_MOVEMENT_ORDER_KEY
             , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT), DMT.DMT_DATE_DOCUMENT) SMO_MOVEMENT_DATE
             , PDE.PDE_MOVEMENT_DATE SMO_VALUE_DATE
             , nvl(wording, DMT.DMT_NUMBER || decode(POS.POS_NUMBER, 0, null, null, null, ' / ') || to_char(POS.POS_NUMBER) ) SMO_WORDING
             , PDE.PDE_MOVEMENT_QUANTITY
             , PDE.PDE_MOVEMENT_VALUE
             , decode(GAP_VALUE_QUANTITY
                    , 0, PDE_FINAL_QUANTITY
                    , decode(sign(POS_FINAL_QUANTITY - POS_VALUE_QUANTITY)
                           , 1, DOC_INIT_MOVEMENT.GetDocumentQty(POS.DOC_POSITION_ID, POS.POS_VALUE_QUANTITY, PDE.DOC_POSITION_DETAIL_ID
                                                               , PDE.PDE_FINAL_QUANTITY)
                           , PDE.PDE_FINAL_QUANTITY
                            )
                     ) SMO_DOCUMENT_QUANTITY
             , decode(GAP_VALUE_QUANTITY
                    , 0, PDE_FINAL_QUANTITY
                    , decode(sign(POS_FINAL_QUANTITY - POS_VALUE_QUANTITY)
                           , 1, DOC_INIT_MOVEMENT.GetDocumentQty(POS.DOC_POSITION_ID, POS.POS_VALUE_QUANTITY, PDE.DOC_POSITION_DETAIL_ID
                                                               , PDE.PDE_FINAL_QUANTITY)
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
             , (select *
                  from STM_STOCK_MOVEMENT
                 where STM_STOCK_MOVEMENT_ID > nvl(STM_STM_STOCK_MOVEMENT_ID, STM_STOCK_MOVEMENT_ID) ) SMO2
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
           and not SMO2.STM_MOVEMENT_KIND_ID(+) = reportMovementKind_id
           and MOK2.STM_MOVEMENT_KIND_ID = MOK.STM_STM_MOVEMENT_KIND_ID
           and not SMO.STM_MOVEMENT_KIND_ID = reportMovementKind_id
           and PDE.DOC_DOCUMENT_ID = DOCUMENT_ID
           and nvl(SMO.SMO_EXTOURNE_MVT, 0) = 0
      order by POS.GCO_GOOD_ID
             , SMO.SMO_CHARACTERIZATION_VALUE_1
             , SMO.SMO_CHARACTERIZATION_VALUE_2
             , SMO.SMO_CHARACTERIZATION_VALUE_3
             , SMO.SMO_CHARACTERIZATION_VALUE_4
             , SMO.SMO_CHARACTERIZATION_VALUE_5
             , POS.POS_NUMBER;

    tplTransfert         crTransfert%rowtype;
    stockMovementId      STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
    vFinancialAccountID  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vDivisionAccountID   ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vCPNAccountID        ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vCDAAccountID        ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vPFAccountID         ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vPJAccountID         ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vFinancialAccountID2 ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vDivisionAccountID2  ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vCPNAccountID2       ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vCDAAccountID2       ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vPFAccountID2        ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vPJAccountID2        ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    vAccountInfo         ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
    vAccountInfo2        ACS_I_LIB_LOGISTIC_FINANCIAL.TAccountInfo;
  begin
    for tplTransfert in crTransfert(documentId, wording, getReportMovementKindId) loop
      stockMovementId                      := null;
      vFinancialAccountID                  := null;
      vDivisionAccountID                   := null;
      vCPNAccountID                        := null;
      vCDAAccountID                        := null;
      vPFAccountID                         := null;
      vPJAccountID                         := null;
      vFinancialAccountID2                 := null;
      vDivisionAccountID2                  := null;
      vCPNAccountID2                       := null;
      vCDAAccountID2                       := null;
      vPFAccountID2                        := null;
      vPJAccountID2                        := null;
      vAccountInfo.DEF_HRM_PERSON          := null;
      vAccountInfo.FAM_FIXED_ASSETS_ID     := null;
      vAccountInfo.C_FAM_TRANSACTION_TYP   := null;
      vAccountInfo.DEF_DIC_IMP_FREE1       := null;
      vAccountInfo.DEF_DIC_IMP_FREE2       := null;
      vAccountInfo.DEF_DIC_IMP_FREE3       := null;
      vAccountInfo.DEF_DIC_IMP_FREE4       := null;
      vAccountInfo.DEF_DIC_IMP_FREE5       := null;
      vAccountInfo.DEF_TEXT1               := null;
      vAccountInfo.DEF_TEXT2               := null;
      vAccountInfo.DEF_TEXT3               := null;
      vAccountInfo.DEF_TEXT4               := null;
      vAccountInfo.DEF_TEXT5               := null;
      vAccountInfo.DEF_NUMBER1             := null;
      vAccountInfo.DEF_NUMBER2             := null;
      vAccountInfo.DEF_NUMBER3             := null;
      vAccountInfo.DEF_NUMBER4             := null;
      vAccountInfo.DEF_NUMBER5             := null;
      vAccountInfo2.DEF_HRM_PERSON         := null;
      vAccountInfo2.FAM_FIXED_ASSETS_ID    := null;
      vAccountInfo2.C_FAM_TRANSACTION_TYP  := null;
      vAccountInfo2.DEF_DIC_IMP_FREE1      := null;
      vAccountInfo2.DEF_DIC_IMP_FREE2      := null;
      vAccountInfo2.DEF_DIC_IMP_FREE3      := null;
      vAccountInfo2.DEF_DIC_IMP_FREE4      := null;
      vAccountInfo2.DEF_DIC_IMP_FREE5      := null;
      vAccountInfo2.DEF_TEXT1              := null;
      vAccountInfo2.DEF_TEXT2              := null;
      vAccountInfo2.DEF_TEXT3              := null;
      vAccountInfo2.DEF_TEXT4              := null;
      vAccountInfo2.DEF_TEXT5              := null;
      vAccountInfo2.DEF_NUMBER1            := null;
      vAccountInfo2.DEF_NUMBER2            := null;
      vAccountInfo2.DEF_NUMBER3            := null;
      vAccountInfo2.DEF_NUMBER4            := null;
      vAccountInfo2.DEF_NUMBER5            := null;

      if tplTransfert.C_POS_CREATE_MODE in('205', '206') then
        select SMO_MOVEMENT_ORDER_KEY
          into tplTransfert.SMO_MOVEMENT_ORDER_KEY
          from STM_STOCK_MOVEMENT
         where DOC_POSITION_DETAIL_ID = tplTransfert.DOC_COPY_POSITION_DETAIL_ID
           and STM_STM_STOCK_MOVEMENT_ID is not null
           and not STM_MOVEMENT_KIND_ID(+) = getReportMovementKindId
           and SMO_EXTOURNE_MVT = 0;
      end if;

      STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId      => stockMovementId
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
                                      , iFinancialAccountId    => vFinancialAccountID   -- ACS_FINANCIAL_ACCOUNT_ID,
                                      , iDivisionAccountId     => vDivisionAccountID   -- ACS_DIVISION_ACCOUNT_ID,
                                      , iaFinancialAccountId   => vFinancialAccountID2   -- ACS_ACS_FINANCIAL_ACCOUNT_ID,
                                      , iaDivisionAccountId    => vDivisionAccountID2   -- ACS_ACS_DIVISION_ACCOUNT_ID,
                                      , iCPNAccountId          => vCPNAccountID   -- ACS_CPN_ACCOUNT_ID,
                                      , iaCPNAccountId         => vCPNAccountID2   -- ACS_ACS_CPN_ACCOUNT_ID,
                                      , iCDAAccountId          => vCDAAccountID   -- ACS_CDA_ACCOUNT_ID,
                                      , iaCDAAccountId         => vCDAAccountID2   -- ACS_ACS_CDA_ACCOUNT_ID,
                                      , iPFAccountId           => vPFAccountID   -- ACS_PF_ACCOUNT_ID,
                                      , iaPFAccountId          => vPFAccountID2   -- ACS_ACS_PF_ACCOUNT_ID,
                                      , iPJAccountId           => vPJAccountID   -- ACS_PJ_ACCOUNT_ID,
                                      , iaPJAccountId          => vPJAccountID2   -- ACS_ACS_PJ_ACCOUNT_ID,
                                      , iFamFixedAssetsId      => vAccountInfo.FAM_FIXED_ASSETS_ID
                                      , iFamTransactionTyp     => vAccountInfo.C_FAM_TRANSACTION_TYP
                                      , iHrmPersonId           => ACS_I_LIB_LOGISTIC_FINANCIAL.GetHrmPerson(vAccountInfo.DEF_HRM_PERSON)
                                      , iDicImpfree1Id         => vAccountInfo.DEF_DIC_IMP_FREE1
                                      , iDicImpfree2Id         => vAccountInfo.DEF_DIC_IMP_FREE2
                                      , iDicImpfree3Id         => vAccountInfo.DEF_DIC_IMP_FREE3
                                      , iDicImpfree4Id         => vAccountInfo.DEF_DIC_IMP_FREE4
                                      , iDicImpfree5Id         => vAccountInfo.DEF_DIC_IMP_FREE5
                                      , iImpText1              => vAccountInfo.DEF_TEXT1
                                      , iImpText2              => vAccountInfo.DEF_TEXT2
                                      , iImpText3              => vAccountInfo.DEF_TEXT3
                                      , iImpText4              => vAccountInfo.DEF_TEXT4
                                      , iImpText5              => vAccountInfo.DEF_TEXT5
                                      , iImpNumber1            => to_number(vAccountInfo.DEF_NUMBER1)
                                      , iImpNumber2            => to_number(vAccountInfo.DEF_NUMBER2)
                                      , iImpNumber3            => to_number(vAccountInfo.DEF_NUMBER3)
                                      , iImpNumber4            => to_number(vAccountInfo.DEF_NUMBER4)
                                      , iImpNumber5            => to_number(vAccountInfo.DEF_NUMBER5)
                                      , iFinancialCharging     => tplTransfert.SMO_FINANCIAL_CHARGING
                                      , iUpdateProv            => tplTransfert.SMO_UPDATE_PROV
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
    aDocumentId in     DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , aWording    in     STM_STOCK_MOVEMENT.SMO_WORDING%type default null
  , aSubCtError out    varchar2
  )
  is
    docWithMovements number(1);
    docDate          date;
    docValidPeriod   date;
    intPos           integer;
    lvError          varchar2(4000);
  begin
    select sign(nvl(max(POS.DOC_POSITION_ID), 0) )
      into docWithMovements
      from DOC_POSITION POS
     where POS.DOC_DOCUMENT_ID = aDocumentId
       and nvl(POS.POS_GENERATE_MOVEMENT, 0) = 0
       and POS.STM_MOVEMENT_KIND_ID is not null;

    -- uniquement si le document génère des mouvements de stock
    if docWithMovements = 1 then
      savepoint spBeforeGenerateMvts;
      DOC_FUNCTIONS.CreateHistoryInformation(aDocumentId, null,   -- DOC_POSITION_ID
                                             null,   -- no de document
                                             'PL/SQL',   -- DUH_TYPE
                                             'DOCUMENT GENERATE MOVEMENTS', null,   -- description libre
                                             null,   -- status document
                                             null);   -- status position
      -- Mouvements d'extourne des mouvements de sortie (a_recstatus = 1)
      DocExtourneOutputMovements(aDocumentId);
      -- Mouvement normaux (a_recstatus = 2)
      DocMainMovements(aDocumentId, aWording);
      -- Mouvements d'extourne des mouvements lié de type sortie (a_recstatus = 6)
      --DocExtTransfertOutputMovements(aDocumentId);
      -- Mouvements d'extourne des mouvements d'entrée (a_recstatus = 3)
      DocExtourneInputMovements(aDocumentId);
      -- Mouvements d'extourne des mouvements lié de type entrée (a_recstatus = 4)
      ---DocExtTransfertInputMovements(aDocumentId);
      -- Mouvement de transfert (mouvements liés) (a_recstatus = 5)
      DocTransfertMovements(aDocumentId, aWording);
      -- Mouvements des matières précieuses
      pDocPositionAlloyMovements(aDocumentId);

      -- Mis à jour du flag de génération des mouvements sur les positions
      update DOC_POSITION
         set POS_GENERATE_MOVEMENT = 1
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_DOCUMENT_ID = aDocumentId
         and STM_MOVEMENT_KIND_ID is not null;

      select DMT_DATE_DOCUMENT
        into docDate
        from DOC_DOCUMENT
       where DOC_DOCUMENT_ID = aDocumentId;

      select STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(docDate), docDate)
        into docValidPeriod
        from dual;

      lvError  := null;

      -- Mis à jour du flag de génération des mouvements sur les details de positions
      -- on fait une boucle afin de mettre à jour un seul enregistrement à la fois et de gérer
      -- les exceptions retournées par le trigger DOC_POSITION_DETAIL.DOC_PDE_AU_MOVEMENT
      for tplPos in (select DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID
                          , DOC_POSITION.POS_NUMBER
                       from DOC_POSITION
                          , DOC_POSITION_DETAIL
                      where DOC_POSITION.DOC_DOCUMENT_ID = aDocumentId
                        and DOC_POSITION.DOC_POSITION_ID = DOC_POSITION_DETAIL.DOC_POSITION_ID
                        and DOC_POSITION.STM_MOVEMENT_KIND_ID is not null) loop
        begin
          savepoint spBeforeGenerateOper;

          update DOC_POSITION_DETAIL
             set PDE_GENERATE_MOVEMENT = 1
               , PDE_MOVEMENT_DATE = nvl(PDE_MOVEMENT_DATE, docValidPeriod)
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
              intPos   := instr(lvError, 'ORA-');

              if intPos > 0 then
                lvError  := substr(lvError, 1, intPos - 1);
              end if;
            else
              lvError  := sqlerrm || co.cLineBreak || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
            end if;

            if aSubCtError is null then
              aSubCtError  := 'Position  ' || tplPos.POS_NUMBER || ' : ' || lvError;
            else
              aSubCtError  := aSubCtError || chr(13) || chr(10) || 'Position  ' || tplPos.POS_NUMBER || ' : ' || lvError;
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
  procedure SoldeDocExtourneMovements(document_id in doc_document.doc_document_id%type)
  is
    cursor crMainMovements(documentId doc_document.doc_document_id%type)
    is
      select   SMO.STM_STOCK_MOVEMENT_ID
             , least(ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 1 / power(10, GOO.GOO_NUMBER_OF_DECIMAL), 0)
                   , SMO.SMO_MOVEMENT_QUANTITY
                    ) SMO_MOVEMENT_QUANTITY
             , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT), DMT.DMT_DATE_DOCUMENT) SMO_MOVEMENT_DATE
          from STM_STOCK_MOVEMENT SMO
             , DOC_POSITION_DETAIL PDE
             , DOC_POSITION POS
             , DOC_DOCUMENT DMT
             , GCO_PRODUCT PDT
             , GCO_GOOD GOO
         where PDE.DOC_DOCUMENT_ID = documentId
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

    lDocumentDate DOC_DOCUMENT.DMT_DATE_DOCUMENT%type   := FWK_I_LIB_ENTITY.getDateFieldFromPk('DOC_DOCUMENT', 'DMT_DATE_DOCUMENT', document_id);
  begin
    DOC_FUNCTIONS.CreateHistoryInformation(document_id, null,   -- DOC_POSITION_ID
                                           null,   -- no de document
                                           'PL/SQL',   -- DUH_TYPE
                                           'DOCUMENT BALANCE MOVEMENTS', null,   -- description libre
                                           null,   -- status document
                                           null);   -- status position

    -- extournes des mouvements
    -- extournes des mouvements principaux (obligatoirement mouvement d'entrée dans le cas d'un transfert)
    -- y compris pour les éventuels composants de la position
    for tplMainMovement in crMainMovements(document_id) loop
      STM_PRC_MOVEMENT.GenerateReversalMvt(iSTM_STOCK_MOVEMENT_ID   => tplMainMovement.STM_STOCK_MOVEMENT_ID
                                         , iMvtQty                  => tplMainMovement.SMO_MOVEMENT_QUANTITY
                                         , iUpdateProv              => 0
                                         , iMvtDate                 => tplMainMovement.SMO_MOVEMENT_DATE
                                          );
    end loop;

    update DOC_POSITION_DETAIL PDE
       set PDE.PDE_GENERATE_MOVEMENT = 1
         , PDE.PDE_MOVEMENT_DATE = nvl(PDE.PDE_MOVEMENT_DATE, STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(lDocumentDate), lDocumentDate) )
         , PDE.A_DATEMOD = sysdate
         , PDE.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
     where PDE.DOC_DOCUMENT_ID = document_id
       and exists(select POS.STM_MOVEMENT_KIND_ID
                    from DOC_POSITION POS
                   where POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                     and POS.STM_MOVEMENT_KIND_ID is not null);

    update DOC_POSITION POS
       set POS.POS_GENERATE_MOVEMENT = 1
         , POS.A_DATEMOD = sysdate
         , POS.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
         , POS.C_KIND_BALANCED = 2
     where POS.DOC_DOCUMENT_ID = document_id
       and POS.STM_MOVEMENT_KIND_ID is not null;

    DocExtFootAlloyMovements(document_id);
  end SoldeDocExtourneMovements;

  -- Extourne des mouvements lors du solde d'une position
  procedure SoldePosExtourneMovements(position_id in doc_position.doc_position_id%type)
  is
    -- curseur sur les mouvements primaires
    cursor crMainMovement(positionId doc_position.doc_position_id%type)
    is
      select   SMO.STM_STOCK_MOVEMENT_ID
             , least(ACS_FUNCTION.RoundNear(PDE.PDE_BALANCE_QUANTITY * POS.POS_CONVERT_FACTOR, 1 / power(10, GOO.GOO_NUMBER_OF_DECIMAL), 0)
                   , SMO.SMO_MOVEMENT_QUANTITY
                    ) SMO_MOVEMENT_QUANTITY
             , SMO.SMO_MOVEMENT_QUANTITY SMO_MOVEMENT_ORIGINAL_QTY
             , DMT.DMT_DATE_DOCUMENT
             , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(DMT.DMT_DATE_DOCUMENT), DMT.DMT_DATE_DOCUMENT) SMO_MOVEMENT_DATE
          from STM_STOCK_MOVEMENT SMO
             , DOC_POSITION_DETAIL PDE
             , DOC_POSITION POS
             , DOC_DOCUMENT DMT
             , GCO_PRODUCT PDT
             , GCO_GOOD GOO
         where PDE.DOC_POSITION_ID = positionId
           and POS.POS_GENERATE_MOVEMENT = 1
           and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and SMO.DOC_POSITION_DETAIL_ID = PDE.DOC_POSITION_DETAIL_ID
           and SMO.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID
           and SMO.DOC_POSITION_ALLOY_ID is null
           and SMO.SMO_EXTOURNE_MVT = 0
           and GOO.GCO_GOOD_ID = POS.GCO_GOOD_ID
           and PDT.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
      order by SMO.GCO_GOOD_ID
             , SMO_CHARACTERIZATION_VALUE_1
             , SMO_CHARACTERIZATION_VALUE_2
             , SMO_CHARACTERIZATION_VALUE_3
             , SMO_CHARACTERIZATION_VALUE_4
             , SMO_CHARACTERIZATION_VALUE_5;

    stockMovementId STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
  begin
    -- extournes des mouvements principaux (obligatoirement mouvement d'entrée dans le cas d'un transfert)
    -- y compris pour les éventuels composants de la position
    for tplMainMovement in crMainMovement(position_id) loop
      STM_PRC_MOVEMENT.GenerateReversalMvt(iSTM_STOCK_MOVEMENT_ID   => tplMainMovement.STM_STOCK_MOVEMENT_ID
                                         , iMvtQty                  => tplMainMovement.SMO_MOVEMENT_QUANTITY
                                         , iUpdateProv              => 0
                                         , iMvtDate                 => tplMainMovement.SMO_MOVEMENT_DATE
                                          );

      -- maj des flag mouvement générés sur le détail de position lié
      update DOC_POSITION_DETAIL PDE
         set PDE.PDE_GENERATE_MOVEMENT = 1
           , PDE.PDE_MOVEMENT_DATE =
               nvl(PDE.PDE_MOVEMENT_DATE
                 , STM_FUNCTIONS.ValidatePeriodDate(STM_FUNCTIONS.GetPeriodId(tplMainMovement.DMT_DATE_DOCUMENT), tplMainMovement.DMT_DATE_DOCUMENT)
                  )
           , PDE.A_DATEMOD = sysdate
           , PDE.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where PDE.DOC_POSITION_ID = position_id
         and exists(select POS.STM_MOVEMENT_KIND_ID
                      from DOC_POSITION POS
                     where POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
                       and POS.STM_MOVEMENT_KIND_ID is not null);

      -- maj des flag mouvement générés sur la position liée
      update DOC_POSITION POS
         set POS.POS_GENERATE_MOVEMENT = 1
           , POS.A_DATEMOD = sysdate
           , POS.A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
           , POS.C_KIND_BALANCED = 2
       where POS.DOC_POSITION_ID = position_id
         and POS.STM_MOVEMENT_KIND_ID is not null;
    end loop;
  end SoldePosExtourneMovements;

  /**
  * Description  Procedure appelée depuis le trigger d'insertion des mouvements
  *              de stock. Elle met à jour la table des cartes de garantie
  *              ASA_GUARANTY_CARDS.
  */
  procedure InsertGuarantyCards(
    AMovementKindID   in STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type
  , APositionDetailID in DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type
  , AThirdID          in PAC_THIRD.PAC_THIRD_ID%type
  , AGoodID           in GCO_GOOD.GCO_GOOD_ID%type
  , ACharID1          in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , ACharID2          in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , ACharID3          in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , ACharID4          in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , ACharID5          in GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID%type
  , ACharValue1       in STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_1%type
  , ACharValue2       in STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_2%type
  , ACharValue3       in STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_3%type
  , ACharValue4       in STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_4%type
  , ACharValue5       in STM_STOCK_MOVEMENT.SMO_CHARACTERIZATION_VALUE_5%type
  )
  is
    DistributionMode PCS.PC_CBASE.CBACNAME%type;
  begin
    /* Le remplissage est autorisé que si la configuration + le genre de
       mouvement + le bien le permettent. */
    if (PCS.PC_CONFIG.GetConfig('ASA_GUARANTY_MANAGEMENT') = '1') then
      DistributionMode  := nvl(PCS.PC_CONFIG.GetConfig('ASA_DISTRIBUTION_MODE'), '0');

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
             , AGoodID
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
             , decode(DistributionMode, '1', AThirdID, null)   -- PAC_ASA_AGENT_ID
             , decode(DistributionMode, '1', DMT.PC_LANG_ID, null)   -- PC_ASA_AGENT_LANG_ID
             , decode(DistributionMode, '1', DMT.PAC_ADDRESS_ID, null)   -- PAC_ASA_AGENT_ADDR_ID
             , decode(DistributionMode, '1', DMT.DMT_ADDRESS1, null)   -- AGC_ADDRESS_AGENT
             , decode(DistributionMode, '1', DMT.DMT_POSTCODE1, null)   -- AGC_POSTCODE_AGENT
             , decode(DistributionMode, '1', DMT.DMT_TOWN1, null)   -- AGC_TOWN_AGENT
             , decode(DistributionMode, '1', DMT.DMT_STATE1, null)   -- AGC_STATE_AGENT
             , decode(DistributionMode, '1', DMT.DMT_FORMAT_CITY1, null)   -- AGC_FORMAT_CITY_AGENT
             , decode(DistributionMode, '1', DMT.PC_CNTRY_ID, null)   -- PC_ASA_AGENT_CNTRY_ID
             , decode(DistributionMode, '1', DMT.DMT_DATE_DOCUMENT, null)   -- AGC_SALEDATE_AGENT
             , decode(DistributionMode, '2', AThirdID, null)   -- PAC_ASA_DISTRIB_ID
             , decode(DistributionMode, '2', DMT.PC_LANG_ID, null)   -- PC_ASA_DISTRIB_LANG_ID
             , decode(DistributionMode, '2', DMT.PAC_ADDRESS_ID, null)   -- PAC_ASA_DISTRIB_ADDR_ID
             , decode(DistributionMode, '2', DMT.DMT_ADDRESS1, null)   -- AGC_ADDRESS_DISTRIB
             , decode(DistributionMode, '2', DMT.DMT_POSTCODE1, null)   -- AGC_POSTCODE_DISTRIB
             , decode(DistributionMode, '2', DMT.DMT_TOWN1, null)   -- AGC_TOWN_DISTRIB
             , decode(DistributionMode, '2', DMT.DMT_STATE1, null)   -- AGC_STATE_DISTRIB
             , decode(DistributionMode, '2', DMT.DMT_FORMAT_CITY1, null)   -- AGC_FORMAT_CITY_DISTRIB
             , decode(DistributionMode, '2', DMT.PC_CNTRY_ID, null)   -- PC_ASA_DISTRIB_CNTRY_ID
             , decode(DistributionMode, '2', DMT.DMT_DATE_DOCUMENT, null)   -- AGC_SALEDATE_DET
             , decode(DistributionMode, '3', AThirdID, null)   -- PAC_ASA_FIN_CUST_ID
             , decode(DistributionMode, '3', DMT.PC_LANG_ID, null)   -- PC_ASA_FIN_CUST_LANG_ID
             , decode(DistributionMode, '3', DMT.PAC_ADDRESS_ID, null)   -- PAC_ASA_FIN_CUST_ADDR_ID
             , decode(DistributionMode, '3', DMT.DMT_ADDRESS1, null)   -- AGC_ADDRESS_FIN_CUST
             , decode(DistributionMode, '3', DMT.DMT_POSTCODE1, null)   -- AGC_POSTCODE_FIN_CUST
             , decode(DistributionMode, '3', DMT.DMT_TOWN1, null)   -- AGC_TOWN_FIN_CUST
             , decode(DistributionMode, '3', DMT.DMT_STATE1, null)   -- AGC_STATE_FIN_CUST
             , decode(DistributionMode, '3', DMT.DMT_FORMAT_CITY1, null)   -- AGC_FORMAT_CITY_FIN_CUST
             , decode(DistributionMode, '3', DMT.PC_CNTRY_ID, null)   -- PC_ASA_FIN_CUST_CNTRY_ID
             , decode(DistributionMode, '3', DMT.DMT_DATE_DOCUMENT, null)   -- AGC_SALEDATE
             , decode(DistributionMode, '3', DMT.DMT_DATE_DOCUMENT, null)   -- AGC_BEGIN
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
         where PDT.GCO_GOOD_ID = AGoodID
           and PDT.PDT_GUARANTY_USE = 1
           and MOK.STM_MOVEMENT_KIND_ID = AMovementKindID
           and MOK_GUARANTY_USE = 1
           and PDE.DOC_POSITION_DETAIL_ID = APositionDetailID
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
  procedure DocFootAlloyMovements(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    -- Informations sur les matières précieuses sur le pied de document
    cursor crFootAlloy(cDocumentID in number, cDefStockID in number, cMngtMode in varchar2)
    is
      select   DFA.DOC_FOOT_ALLOY_ID
             , GAL.GCO_GOOD_ID
             , (DMT.DMT_NUMBER || ' / ' || decode(cMngtMode, '1', GAL.GAL_ALLOY_REF, DFA.DIC_BASIS_MATERIAL_ID) ) SMO_WORDING
             , LOC.STM_STOCK_ID
             , LOC.STM_LOCATION_ID
             , DOC_FOOT_ALLOY_FUNCTIONS.GetAdvanceWeight(cDocumentID, null, null, DFA.DFA_WEIGHT_DELIVERY, DFA.DFA_LOSS, DFA.DFA_WEIGHT_INVEST)
                                                                                                                                          SMO_MOVEMENT_QUANTITY
             , DFA.DFA_AMOUNT SMO_MOVEMENT_PRICE
          from DOC_DOCUMENT DMT
             , DOC_FOOT_ALLOY DFA
             , STM_LOCATION LOC
             , GCO_ALLOY GAL
         where DMT.DOC_DOCUMENT_ID = cDocumentID
           and DFA.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID
           and LOC.STM_STOCK_ID = DFA.STM_STOCK_ID
           and LOC.LOC_CLASSIFICATION = (select min(LOC_CLASSIFICATION)
                                           from STM_LOCATION
                                          where STM_STOCK_ID = LOC.STM_STOCK_ID)
           and (    (     (cMngtMode = '1')
                     and (DFA.GCO_ALLOY_ID is not null) )
                or (     (cMngtMode = '2')
                    and (DFA.DIC_BASIS_MATERIAL_ID is not null) ) )
           and GAL.GCO_ALLOY_ID =
                             decode(cMngtMode
                                  , '1', DFA.GCO_ALLOY_ID
                                  , '2', (select max(GAC.GCO_ALLOY_ID)
                                            from GCO_ALLOY_COMPONENT GAC
                                           where GAC.DIC_BASIS_MATERIAL_ID = DFA.DIC_BASIS_MATERIAL_ID
                                             and GAC.GAC_RATE = 100)
                                   )
      order by DFA.DOC_FOOT_ALLOY_ID;

    tplFootAlloy                 crFootAlloy%rowtype;
    tmpC_MATERIAL_MGNT_MODE      PAC_CUSTOM_PARTNER.C_MATERIAL_MGNT_MODE%type;
    tmpTHIRD_METAL_ACCOUNT       PAC_CUSTOM_PARTNER.CUS_METAL_ACCOUNT%type;
    tmpSTM_STOCK_MOVEMENT_ID     STM_STOCK_MOVEMENT.STM_STOCK_MOVEMENT_ID%type;
    tmpGAS_WEIGHT_MAT            DOC_GAUGE_STRUCTURED.GAS_WEIGHT_MAT%type;
    tmpGAS_METAL_ACCOUNT_MGM     DOC_GAUGE_STRUCTURED.GAS_METAL_ACCOUNT_MGM%type;
    tmpSTM_MOVEMENT_KIND_ID      DOC_GAUGE_POSITION.STM_MOVEMENT_KIND_ID%type;
    tmpSMO_FINANCIAL_CHARGING    STM_STOCK_MOVEMENT.SMO_FINANCIAL_CHARGING%type;
    tmpDMT_NUMBER                DOC_DOCUMENT.DMT_NUMBER%type;
    tmpDOC_RECORD_ID             DOC_DOCUMENT.DOC_RECORD_ID%type;
    tmpPAC_THIRD_ID              DOC_DOCUMENT.PAC_THIRD_ID%type;
    tmpPAC_THIRD_ACI_ID          DOC_DOCUMENT.PAC_THIRD_ACI_ID%type;
    tmpPAC_THIRD_DELIVERY_ID     DOC_DOCUMENT.PAC_THIRD_DELIVERY_ID%type;
    tmpPAC_THIRD_TARIFF_ID       DOC_DOCUMENT.PAC_THIRD_TARIFF_ID%type;
    tmpDMT_DATE_DOCUMENT         DOC_DOCUMENT.DMT_DATE_DOCUMENT%type;
    tmpDMT_RATE_OF_EXCHANGE      DOC_DOCUMENT.DMT_RATE_OF_EXCHANGE%type;
    tmpDMT_BASE_PRICE            DOC_DOCUMENT.DMT_BASE_PRICE%type;
    tmpACS_FINANCIAL_CURRENCY_ID DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
    tmpACS_LOCAL_CURRENCY_ID     DOC_DOCUMENT.ACS_FINANCIAL_CURRENCY_ID%type;
    tmpSTM_EXERCISE_ID           STM_STOCK_MOVEMENT.STM_EXERCISE_ID%type;
    tmpSTM_PERIOD_ID             STM_STOCK_MOVEMENT.STM_PERIOD_ID%type;
    tmpSMO_MOVEMENT_DATE         STM_STOCK_MOVEMENT.SMO_MOVEMENT_DATE%type;
    tmpDEF_MAT_STM_STOCK_ID      STM_STOCK.STM_STOCK_ID%type;
    tmpSMO_UNIT_PRICE            STM_STOCK_MOVEMENT.SMO_UNIT_PRICE%type;
    tmpSMO_ALT_QTY_1             STM_STOCK_MOVEMENT.SMO_MVT_ALTERNATIV_QTY_1%type;
    tmpSMO_ALT_QTY_2             STM_STOCK_MOVEMENT.SMO_MVT_ALTERNATIV_QTY_2%type;
    tmpSMO_ALT_QTY_3             STM_STOCK_MOVEMENT.SMO_MVT_ALTERNATIV_QTY_3%type;
    tmpC_ADMIN_DOMAIN            DOC_GAUGE.C_ADMIN_DOMAIN%type;
    tmpSMO_MOVEMENT_PRICE_B      STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type;
    tmpSMO_MOVEMENT_PRICE_E      STM_STOCK_MOVEMENT.SMO_MOVEMENT_PRICE%type;
  begin
    -- Gestion des comptes poids matières précieuses
    if DOC_I_LIB_CONSTANT.gcCfgMetalInfo then
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
          into tmpGAS_WEIGHT_MAT
             , tmpGAS_METAL_ACCOUNT_MGM
             , tmpSTM_MOVEMENT_KIND_ID
             , tmpSMO_FINANCIAL_CHARGING
             , tmpDOC_RECORD_ID
             , tmpPAC_THIRD_ID
             , tmpPAC_THIRD_ACI_ID
             , tmpPAC_THIRD_DELIVERY_ID
             , tmpPAC_THIRD_TARIFF_ID
             , tmpDMT_DATE_DOCUMENT
             , tmpACS_FINANCIAL_CURRENCY_ID
             , tmpDMT_RATE_OF_EXCHANGE
             , tmpDMT_BASE_PRICE
             , tmpSTM_EXERCISE_ID
             , tmpSTM_PERIOD_ID
             , tmpSMO_MOVEMENT_DATE
             , tmpC_MATERIAL_MGNT_MODE
             , tmpTHIRD_METAL_ACCOUNT
             , tmpC_ADMIN_DOMAIN
          from DOC_DOCUMENT DMT
             , DOC_GAUGE GAU
             , DOC_GAUGE_STRUCTURED GAS
             , DOC_GAUGE_POSITION GAP
             , STM_MOVEMENT_KIND MOK
             , PAC_SUPPLIER_PARTNER SUP
             , PAC_CUSTOM_PARTNER CUS
         where DMT.DOC_DOCUMENT_ID = aDocumentID
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
          into tmpDEF_MAT_STM_STOCK_ID
          from STM_STOCK STO
         where nvl(STO.STO_METAL_ACCOUNT, 0) = 1
           and nvl(STO.STO_DEFAULT_METAL_ACCOUNT, 0) = 1;
      exception
        when no_data_found then
          tmpDEF_MAT_STM_STOCK_ID  := null;
      end;

      -- Recherche la monnaie de base
      tmpACS_LOCAL_CURRENCY_ID  := ACS_FUNCTION.GetLocalCurrencyId;

      -- Gabarit si "Gestion des poids des matières précieuses" = OUI
      -- Gabarit si "Mise à jour compte poids matières précieuses" = OUI
      -- Tiers si "Gestion compte poids" = 1
      -- Type de mouvement trouvé sur le gabarit position type '1'
      -- Si Mode de gestion matières précieuses du Tiers renseigné
      if     (tmpGAS_WEIGHT_MAT = 1)
         and (tmpGAS_METAL_ACCOUNT_MGM = 1)
         and (tmpTHIRD_METAL_ACCOUNT = 1)
         and (tmpSTM_MOVEMENT_KIND_ID is not null)
         and (tmpC_MATERIAL_MGNT_MODE is not null) then
        open crFootAlloy(aDocumentID, tmpDEF_MAT_STM_STOCK_ID, tmpC_MATERIAL_MGNT_MODE);

        fetch crFootAlloy
         into tplFootAlloy;

        -- Balayer les matières précieuses sur le pied de document
        while crFootAlloy%found loop
          -- Vérifier qu'il y a un bien lié à l'alliage
          if tplFootAlloy.GCO_GOOD_ID is null then
            raise_application_error(-20928, PCS.PC_FUNCTIONS.TranslateWord('PCS - Le bien n''est pas défini sur l''alliage !') );
          else
            tmpSTM_STOCK_MOVEMENT_ID  := null;

            -- Rechercher les qtés alternatives
            select decode(PDT.PDT_ALTERNATIVE_QUANTITY_1, 1, PDT.PDT_CONVERSION_FACTOR_1 * tplFootAlloy.SMO_MOVEMENT_QUANTITY, 0) SMO_ALTERNATIVE_QUANTITY_1
                 , decode(PDT.PDT_ALTERNATIVE_QUANTITY_2, 1, PDT.PDT_CONVERSION_FACTOR_2 * tplFootAlloy.SMO_MOVEMENT_QUANTITY, 0) SMO_ALTERNATIVE_QUANTITY_2
                 , decode(PDT.PDT_ALTERNATIVE_QUANTITY_3, 1, PDT.PDT_CONVERSION_FACTOR_3 * tplFootAlloy.SMO_MOVEMENT_QUANTITY, 0) SMO_ALTERNATIVE_QUANTITY_3
              into tmpSMO_ALT_QTY_1
                 , tmpSMO_ALT_QTY_2
                 , tmpSMO_ALT_QTY_3
              from GCO_PRODUCT PDT
             where PDT.GCO_GOOD_ID = tplFootAlloy.GCO_GOOD_ID;

            -- Détermine le prix du mouvement.
            if (tmpACS_FINANCIAL_CURRENCY_ID <> tmpACS_LOCAL_CURRENCY_ID) then
              -- Convertit le montant facturé de la monnaie du document en monnaie de base pour valorisé le mouvement
              -- de stock du compte poids.
              ACS_FUNCTION.ConvertAmount(nvl(tplFootAlloy.SMO_MOVEMENT_PRICE, 0)
                                       , tmpACS_FINANCIAL_CURRENCY_ID
                                       , tmpACS_LOCAL_CURRENCY_ID
                                       , tmpDMT_DATE_DOCUMENT
                                       , tmpDMT_RATE_OF_EXCHANGE
                                       , tmpDMT_BASE_PRICE
                                       , 0
                                       , tmpSMO_MOVEMENT_PRICE_E
                                       , tmpSMO_MOVEMENT_PRICE_B
                                        );
            else
              tmpSMO_MOVEMENT_PRICE_B  := nvl(tplFootAlloy.SMO_MOVEMENT_PRICE, 0);
            end if;

            -- calcul du Prix unitaire du mouvement
            select decode(tplFootAlloy.SMO_MOVEMENT_QUANTITY
                        , 0, tplFootAlloy.SMO_MOVEMENT_QUANTITY
                        , tmpSMO_MOVEMENT_PRICE_B / tplFootAlloy.SMO_MOVEMENT_QUANTITY
                         ) SMO_UNIT_PRICE
              into tmpSMO_UNIT_PRICE
              from dual;

            -- Création du mouvement
            STM_PRC_MOVEMENT.GenerateMovement(ioStockMovementId    => tmpSTM_STOCK_MOVEMENT_ID
                                            , iGoodId              => tplFootAlloy.GCO_GOOD_ID
                                            , iMovementKindId      => tmpSTM_MOVEMENT_KIND_ID
                                            , iExerciseId          => tmpSTM_EXERCISE_ID
                                            , iPeriodId            => tmpSTM_PERIOD_ID
                                            , iMvtDate             => tmpSMO_MOVEMENT_DATE
                                            , iValueDate           => tmpSMO_MOVEMENT_DATE
                                            , iStockId             => tplFootAlloy.STM_STOCK_ID
                                            , iLocationId          => tplFootAlloy.STM_LOCATION_ID
                                            , iThirdId             => tmpPAC_THIRD_ID
                                            , iThirdAciId          => tmpPAC_THIRD_ACI_ID
                                            , iThirdDeliveryId     => tmpPAC_THIRD_DELIVERY_ID
                                            , iThirdTariffId       => tmpPAC_THIRD_TARIFF_ID
                                            , iRecordId            => tmpDOC_RECORD_ID
                                            , iWording             => tplFootAlloy.SMO_WORDING
                                            , iMvtQty              => tplFootAlloy.SMO_MOVEMENT_QUANTITY
                                            , iMvtPrice            => tmpSMO_MOVEMENT_PRICE_B
                                            , iUnitPrice           => tmpSMO_UNIT_PRICE
                                            , iAltQty1             => tmpSMO_ALT_QTY_1
                                            , iAltQty2             => tmpSMO_ALT_QTY_2
                                            , iAltQty3             => tmpSMO_ALT_QTY_3
                                            , iFinancialCharging   => tmpSMO_FINANCIAL_CHARGING
                                            , iUpdateProv          => 1
                                            , iExtourneMvt         => 0
                                            , iRecStatus           => 11
                                            , iDocFootAlloyID      => tplFootAlloy.DOC_FOOT_ALLOY_ID
                                             );
          end if;

          fetch crFootAlloy
           into tplFootAlloy;
        end loop;

        close crFootAlloy;
      end if;
    end if;
  end DocFootAlloyMovements;

  /**
  * Description
  *   Extourne des mouvements sur les matières précieuses du pied de document
  */
  procedure DocExtFootAlloyMovements(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type)
  is
    cursor crExtourneAlloy(aCrFootAlloyId DOC_FOOT_ALLOY.DOC_FOOT_ALLOY_ID%type, aCrReportMvtId STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_Id%type)
    is
      select   SMO.STM_STOCK_MOVEMENT_ID
          from STM_STOCK_MOVEMENT SMO
             , STM_MOVEMENT_KIND MOK
             , DOC_DOCUMENT DMT
             , DOC_FOOT_ALLOY DFA
         where DMT.DOC_DOCUMENT_ID = aDocumentId
           and DFA.DOC_FOOT_ID = DMT.DOC_DOCUMENT_ID
           and SMO.DOC_FOOT_ALLOY_ID = DFA.DOC_FOOT_ALLOY_ID
           and SMO.STM_STM_STOCK_MOVEMENT_ID is null   /* only main movements */
           and SMO.STM_MOVEMENT_KIND_ID <> aCrReportMvtId   /* do not take care of report movements  */
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
    if DOC_I_LIB_CONSTANT.gcCfgMetalInfo then
      for tplExtourneAlloy in crExtourneAlloy(aDocumentID, getReportMovementKindId) loop
        -- Création du mouvement
        STM_PRC_MOVEMENT.GenerateReversalMvt(tplExtourneAlloy.STM_STOCK_MOVEMENT_ID);
      end loop;
    end if;
  end DocExtFootAlloyMovements;
end DOC_INIT_MOVEMENT;
