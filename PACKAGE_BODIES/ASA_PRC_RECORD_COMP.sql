--------------------------------------------------------
--  DDL for Package Body ASA_PRC_RECORD_COMP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_PRC_RECORD_COMP" 
is
  procedure ManageData(iotRecordComp in out nocopy fwk_i_typ_definition.t_crud_def)
  is
    ltplRecordComp             FWK_TYP_ASA_ENTITY.tRecordComp              := FWK_TYP_ASA_ENTITY.gttRecordComp(iotRecordComp.entity_id);
    lPC_LANG_ID                PCS.PC_LANG.PC_LANG_ID%type;
    lPAC_CUSTOM_PARTNER_ID     ASA_RECORD.PAC_CUSTOM_PARTNER_ID%type;
    lDOC_RECORD_ID             ASA_RECORD.DOC_RECORD_ID%type;
    lDIC_TARIFF_ID             ASA_RECORD.DIC_TARIFF_ID%type;
    lDIC_TARIFF2_ID            ASA_RECORD.DIC_TARIFF2_ID%type;
    lACS_FINANCIAL_CURRENCY_ID ASA_RECORD.ACS_FINANCIAL_CURRENCY_ID%type;
    lARE_DATECRE               ASA_RECORD.ARE_DATECRE%type;
    lnError                    integer;
    lcError                    varchar2(100);

    procedure InitFields
    is
      procedure CheckASA_RECORD_ID
      is
        lnEvent             ASA_RECORD.ASA_RECORD_EVENTS_ID%type;
        lvC_ASA_GEN_DOC_POS ASA_RECORD_COMP.C_ASA_GEN_DOC_POS%type;
        lnPos               ASA_RECORD_COMP.ARC_POSITION%type;
        lASA_RECORD_ID      ASA_RECORD.ASA_RECORD_ID%type;
      begin
        if FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ASA_RECORD_ID') then
          lASA_RECORD_ID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotRecordComp, 'ASA_RECORD_ID');

          if ASA_I_LIB_RECORD.IsRecordProtected(lASA_RECORD_ID) then
            fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                              , iv_message       => PCS.PC_FUNCTIONS.TranslateWord('Ce dossier est protégé !')
                                              , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                              , iv_cause         => 'CheckASA_RECORD_ID'
                                               );
          end if;

          -- Enregistrement de l'évènement actif pour la gestion de l'historique
          select ASA_RECORD_EVENTS_ID
            into lnEvent
            from ASA_RECORD
           where ASA_RECORD_ID = lASA_RECORD_ID;

          if lnEvent is not null then
            FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'ASA_RECORD_EVENTS_ID', lnEvent);
          end if;

          --    Initialisation du type de mouvement de stock en sortir du stock de
          --    la localisation dans le stock
          if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'C_ASA_GEN_DOC_POS') then
            select ASA_REP_TYPE.C_ASA_GEN_DOC_POS_COMP
              into lvC_ASA_GEN_DOC_POS
              from ASA_REP_TYPE
                 , ASA_RECORD
             where ASA_RECORD.ASA_RECORD_ID = lASA_RECORD_ID
               and ASA_RECORD.ASA_REP_TYPE_ID = ASA_REP_TYPE.ASA_REP_TYPE_ID;

            FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp
                                          , 'C_ASA_GEN_DOC_POS'
                                          , nvl(lvC_ASA_GEN_DOC_POS, PCS.PC_CONFIG.GetConfig('ASA_COMPONENT_DEFAULT_DOC_POS') )
                                           );
          end if;

          -- position du composant
          if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ARC_POSITION') then
            select nvl(max(ARC_POSITION), 0) + PCS.PC_CONFIG.GetConfig('ASA_COMPONENT_INCREMENT')
              into lnPos
              from ASA_RECORD_COMP
             where ASA_RECORD_ID = lASA_RECORD_ID;

            FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'ARC_POSITION', lnPos);
          end if;
        end if;
      end CheckASA_RECORD_ID;
    begin
      if ltplRecordComp.ARC_OPTIONAL is null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'ARC_OPTIONAL', false);
      end if;

      if ltplRecordComp.ARC_GUARANTY_CODE is null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'ARC_GUARANTY_CODE', false);
      end if;

      if ltplRecordComp.ARC_PROTECTED is null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'ARC_PROTECTED', false);
      end if;

      if ltplRecordComp.C_ASA_GEN_DOC_POS is null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'C_ASA_GEN_DOC_POS ', '2');
      end if;

      if ltplRecordComp.C_ASA_ACCEPT_OPTION is null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'C_ASA_ACCEPT_OPTION', '0');
      end if;

      --  Coefficient d'utilisation
      if ltplRecordComp.ARC_QUANTITY is null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'ARC_QUANTITY', 1);
      end if;

      CheckASA_RECORD_ID;
    end InitFields;

    procedure CheckARC_POSITION
    is
      ltplRecordComp FWK_TYP_ASA_ENTITY.tRecordComp      := FWK_TYP_ASA_ENTITY.gttRecordComp(iotRecordComp.entity_id);
      lnPos          ASA_RECORD_COMP.ARC_POSITION%type;
    begin
      if FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ARC_POSITION') then
        begin
          select ARC_POSITION
            into lnPos
            from ASA_RECORD_COMP ARC
               , ASA_RECORD are
           where ARC.ASA_RECORD_ID = are.ASA_RECORD_ID
             and ARC.ASA_RECORD_EVENTS_ID = are.ASA_RECORD_EVENTS_ID
             and are.ASA_RECORD_ID = ltplRecordComp.ASA_RECORD_ID
             and ARC.ASA_RECORD_COMP_ID <> ltplRecordComp.ASA_RECORD_COMP_ID
             and ARC_POSITION = ltplRecordComp.ARC_POSITION;

          fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                            , iv_message       => PCS.PC_FUNCTIONS.TranslateWord('Numéro de position déjà utilisé !') ||
                                                                  chr(10) ||
                                                                  PCS.PC_FUNCTIONS.TranslateWord('Valeur :') ||
                                                                  ' ' ||
                                                                  FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotRecordComp, 'ARC_POSITION')
                                            , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                            , iv_cause         => 'CheckARC_POSITION'
                                             );
        exception
          when no_data_found then
            null;
        end;
      end if;
    end CheckARC_POSITION;

    procedure CheckARC_CDMVT
    is
      ltplRecordComp FWK_TYP_ASA_ENTITY.tRecordComp      := FWK_TYP_ASA_ENTITY.gttRecordComp(iotRecordComp.entity_id);
      lnPos          ASA_RECORD_COMP.ARC_POSITION%type;
    begin
      if     FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ARC_CDMVT')
         and (ltplRecordComp.ARC_CDMVT = 1)
         and not GCO_I_LIB_FUNCTIONS.IsStockManagement(ltplRecordComp.GCO_COMPONENT_ID) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                          , iv_message       => PCS.PC_FUNCTIONS.TranslateWord('Ce composant n''a pas de gestion de stock !')
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'CheckARC_CDMVT'
                                           );
      end if;
    end CheckARC_CDMVT;

    procedure CheckGCO_COMPONENT_ID
    is
      ltplRecordComp     FWK_TYP_ASA_ENTITY.tRecordComp               := FWK_TYP_ASA_ENTITY.gttRecordComp(iotRecordComp.entity_id);
      lnSalePrice        ASA_RECORD_COMP.ARC_SALE_PRICE_ME%type;
      lGCO_COMPONENT_ID  ASA_RECORD_COMP.GCO_COMPONENT_ID%type;
      lvShortDescription GCO_DESCRIPTION.DES_SHORT_DESCRIPTION%type;
      lvLongDescription  GCO_DESCRIPTION.DES_LONG_DESCRIPTION%type;
      lvFreeDescription  GCO_DESCRIPTION.DES_FREE_DESCRIPTION%type;
      lvMvtSort          PCS.PC_GCLST.GCLCODE%type;

      procedure InitStockIdFromConfig
      is
        lvConfig                 PCS.PC_CBASE.CBACVALUE%type;
        lnSTK_MANAG              integer                       := 0;
        lnCompStockId_out        number                        := 0;
        lnCompLocId_out          number                        := 0;
        lnCompKindMvt_out        number                        := 0;
        lnCompKindMvt_out_transf number                        := 0;
        lnCompStockId_in         number                        := 0;
        lnCompLocId_in           number                        := 0;
        lnCompKindMvt_in         number                        := 0;
        lnStockId                number                        := 0;
        lnLocId                  number                        := 0;
        lnCompId                 number                        := 0;
      begin
        lnCompId  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotRecordComp, 'GCO_COMPONENT_ID');
        lvConfig  := PCS.PC_CONFIG.GetConfig('ASA_COMPONENT_DEFAULT_STOCK');

        if lvConfig is not null then
          select STM_STOCK_ID
            into lnCompStockId_out
            from STM_STOCK
           where STO_DESCRIPTION = lvConfig;
        end if;

        lvConfig  := PCS.PC_CONFIG.GetConfig('ASA_COMPONENT_DEFAULT_LOCATION');

        if lvConfig is not null then
          select STM_LOCATION_ID
            into lnCompLocId_out
            from STM_LOCATION
           where LOC_DESCRIPTION = lvConfig;
        end if;

        lvConfig  := PCS.PC_CONFIG.GetConfig('ASA_COMPONENT_KIND_MVT');

        if lvConfig is not null then
          select STM_MOVEMENT_KIND_ID
            into lnCompKindMvt_out
            from STM_MOVEMENT_KIND
           where MOK_ABBREVIATION = lvConfig;
        end if;

        lvConfig  := PCS.PC_CONFIG.GetConfig('ASA_COMPONENT_KIND_MVT_OUT_TRA');

        if lvConfig is not null then
          select STM_MOVEMENT_KIND_ID
            into lnCompKindMvt_out_transf
            from STM_MOVEMENT_KIND
           where MOK_ABBREVIATION = lvConfig;
        end if;

        lvConfig  := PCS.PC_CONFIG.GetConfig('ASA_COMPONENT_DEFAULT_STO_IN');

        if lvConfig is not null then
          select STM_STOCK_ID
            into lnCompStockId_in
            from STM_STOCK
           where STO_DESCRIPTION = lvConfig;
        end if;

        lvConfig  := PCS.PC_CONFIG.GetConfig('ASA_COMPONENT_DEFAULT_LOC_IN');

        if lvConfig is not null then
          select STM_LOCATION_ID
            into lnCompLocId_in
            from STM_LOCATION
           where LOC_DESCRIPTION = lvConfig;
        end if;

        lvConfig  := PCS.PC_CONFIG.GetConfig('ASA_COMPONENT_KIND_MVT_IN');

        if lvConfig is not null then
          select STM_MOVEMENT_KIND_ID
            into lnCompKindMvt_in
            from STM_MOVEMENT_KIND
           where MOK_ABBREVIATION = lvConfig;
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ARC_CDMVT') then
          lvConfig  := upper(PCS.PC_CONFIG.GetConfig('ASA_COMPONENT_STOCK_MVT') );

          if lvConfig = 'TRUE' then
            select nvl(max(PDT_STOCK_MANAGEMENT), 0)
              into lnSTK_MANAG
              from GCO_PRODUCT
             where GCO_GOOD_ID = lnCompId;

            FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'ARC_CDMVT', lnSTK_MANAG = 1);
          elsif lvConfig = 'FALSE' then
            FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'ARC_CDMVT', lnSTK_MANAG = 1);
          end if;
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'STM_COMP_MVT_KIND_ID') then
          -- Le type de mouvement de stock n'est pas défini
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordComp, 'STM_COMP_MVT_KIND_ID') then
            -- sortie de stock
            if upper(PCS.PC_CONFIG.GetConfig('ASA_WORK_STOCK_MNG') ) = 'FALSE' then
              if (lnCompKindMvt_out > 0) then
                FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'STM_COMP_MVT_KIND_ID', lnCompKindMvt_out);
              -- type de mouvement : sortie de stock
              end if;
            else
              if (lnCompKindMvt_out_transf > 0) then
                FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'STM_COMP_MVT_KIND_ID', lnCompKindMvt_out_transf);
              -- type de mouvement : sortie de stock pour transfer
              end if;
            end if;
          end if;
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'STM_COMP_STOCK_ID') then
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordComp, 'STM_COMP_STOCK_ID') then
            -- Le type de mouvement de stock n'est pas défini
            -- Initialisation des identifiant du stock et de la location du stock ---
            -- a) reprise des codes de configuration (sortie)
            if lnCompStockId_out > 0 then
              lnStockId  := lnCompStockId_out;
            end if;

            if     (lnStockId = 0)
               and (lnCompId > 0) then
              -- b) recherche du stock par défaut du composant
              select STM_STOCK_ID
                into lnStockId
                from GCO_PRODUCT
               where GCO_GOOD_ID = lnCompId;
            end if;

            if lnStockId > 0 then
              FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'STM_COMP_STOCK_ID', lnStockId);
            end if;
          end if;
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'STM_COMP_LOCATION_ID') then
          lnStockId  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotRecordComp, 'STM_COMP_STOCK_ID');

          if FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordComp, 'STM_COMP_LOCATION_ID') then
            if (lnCompLocId_out > 0) then
              lnLocId  := lnCompLocId_out;
            end if;

            if     (lnLocId = 0)
               and (lnCompId > 0) then
              -- b) recherche du stock/location par défaut du composant
              select STM_LOCATION_ID
                into lnLocId
                from GCO_PRODUCT
               where GCO_GOOD_ID = lnCompId;
            end if;

            if not lnLocId is null then
              FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'STM_COMP_LOCATION_ID', lnLocId);
            end if;
          else
            lnLocId  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotRecordComp, 'STM_COMP_LOCATION_ID');
          end if;

          if     lnStockId > 0
             and lnLocId > 0 then
            -- validation de la location de stock par rapport au stock
            begin
              select STM_LOCATION_ID
                into lnLocId
                from STM_LOCATION
               where STM_STOCK_ID = lnStockId
                 and STM_LOCATION_ID = lnLocId;
            exception
              when no_data_found then
                lnLocId  := null;
            end;

            if lnLocId is null then
              FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotRecordComp, 'STM_COMP_LOCATION_ID');
            end if;
          end if;
        end if;
      end InitStockIdFromConfig;
    begin
      -- procedure CheckGCO_COMPONENT_ID
      if FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'GCO_COMPONENT_ID') then
        lGCO_COMPONENT_ID  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotRecordComp, 'GCO_COMPONENT_ID');
        ASA_I_LIB_RECORD.GetGoodDescr(lGCO_COMPONENT_ID, lPC_LANG_ID, lvShortDescription, lvLongDescription, lvFreeDescription);

        if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ARC_DESCR') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'ARC_DESCR', lvShortDescription);
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ARC_DESCR2') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'ARC_DESCR2', lvLongDescription);
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ARC_DESCR3') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'ARC_DESCR3', lvFreeDescription);
        end if;

        -- initialisation des données de gestion de stock
        InitStockIdFromConfig;

        -- initialisation des prix
        if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ARC_COST_PRICE') then
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp
                                        , 'ARC_COST_PRICE'
                                        , nvl(GCO_I_LIB_PRICE.GetCostPriceWithManagementMode(lGCO_COMPONENT_ID, lPAC_CUSTOM_PARTNER_ID), 0)
                                         );
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ARC_SALE_PRICE_ME') then
          if not lDIC_TARIFF_ID is null then
            lnSalePrice  :=
              ASA_I_LIB_RECORD.GetGoodSalePrice(lGCO_COMPONENT_ID
                                              , lPAC_CUSTOM_PARTNER_ID
                                              , lDOC_RECORD_ID
                                              , lDIC_TARIFF_ID
                                              , lACS_FINANCIAL_CURRENCY_ID
                                              , ASA_LIB_RECORD.GetTariffDateRef(lARE_DATECRE)
                                               );
            FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'ARC_SALE_PRICE_ME', lnSalePrice);
          end if;
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ARC_SALE_PRICE2_ME') then
          if not lDIC_TARIFF2_ID is null then
            lnSalePrice  :=
              ASA_I_LIB_RECORD.GetGoodSalePrice(lGCO_COMPONENT_ID
                                              , lPAC_CUSTOM_PARTNER_ID
                                              , lDOC_RECORD_ID
                                              , lDIC_TARIFF2_ID
                                              , lACS_FINANCIAL_CURRENCY_ID
                                              , ASA_LIB_RECORD.GetTariffDateRef(lARE_DATECRE)
                                               );
            FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'ARC_SALE_PRICE2_ME', lnSalePrice);
          end if;
        end if;
      end if;
    end CheckGCO_COMPONENT_ID;

    procedure CheckPrices
    is
      lnSalePrice ASA_RECORD_COMP.ARC_SALE_PRICE_ME%type;
      lnAmountEUR ASA_RECORD_COMP.ARC_SALE_PRICE_EURO%type;
      lnAmountMB  ASA_RECORD_COMP.ARC_SALE_PRICE%type;
    begin
      if FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ARC_SALE_PRICE_ME') then
        lnSalePrice  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotRecordComp, 'ARC_SALE_PRICE_ME');

        if nvl(lnSalePrice, 0) <> 0 then
          ACS_FUNCTION.ConvertAmount(lnSalePrice
                                   , lACS_FINANCIAL_CURRENCY_ID
                                   , ACS_FUNCTION.GetLocalCurrencyId
                                   , ASA_LIB_RECORD.GetTariffDateRef(lARE_DATECRE)
                                   , 0
                                   , 0
                                   , 1
                                   , lnAmountEUR
                                   , lnAmountMB
                                   , 5   -- utilisation du cours de facturation
                                    );
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'ARC_SALE_PRICE', lnAmountMB);
          ACS_FUNCTION.ConvertAmount(lnAmountMB
                                   , ACS_FUNCTION.GetLocalCurrencyId
                                   , ACS_FUNCTION.GetEuroCurrency
                                   , ASA_LIB_RECORD.GetTariffDateRef(lARE_DATECRE)
                                   , 0
                                   , 0
                                   , 1
                                   , lnAmountEUR
                                   , lnAmountMB
                                   , 5   -- utilisation du cours de facturation
                                    );
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'ARC_SALE_PRICE_EURO', lnAmountEUR);
        end if;
      end if;

      if FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ARC_SALE_PRICE2_ME') then
        lnSalePrice  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotRecordComp, 'ARC_SALE_PRICE2_ME');

        if nvl(lnSalePrice, 0) <> 0 then
          ACS_FUNCTION.ConvertAmount(lnSalePrice
                                   , lACS_FINANCIAL_CURRENCY_ID
                                   , ACS_FUNCTION.GetLocalCurrencyId
                                   , ASA_LIB_RECORD.GetTariffDateRef(lARE_DATECRE)
                                   , 0
                                   , 0
                                   , 1
                                   , lnAmountEUR
                                   , lnAmountMB
                                   , 5   -- utilisation du cours de facturation
                                    );
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'ARC_SALE_PRICE2', lnAmountMB);
          ACS_FUNCTION.ConvertAmount(lnAmountMB
                                   , ACS_FUNCTION.GetLocalCurrencyId
                                   , ACS_FUNCTION.GetEuroCurrency
                                   , ASA_LIB_RECORD.GetTariffDateRef(lARE_DATECRE)
                                   , 0
                                   , 0
                                   , 1
                                   , lnAmountEUR
                                   , lnAmountMB
                                   , 5   -- utilisation du cours de facturation
                                    );
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'ARC_SALE_PRICE2_EURO', lnAmountEUR);
        end if;
      end if;
    end CheckPrices;

    procedure CheckCharact
    is
      lnCharactID_1 DOC_POSITION_DETAIL.GCO_CHARACTERIZATION_ID%type;
      lnCharactID_2 DOC_POSITION_DETAIL.GCO_GCO_CHARACTERIZATION_ID%type;
      lnCharactID_3 DOC_POSITION_DETAIL.GCO2_GCO_CHARACTERIZATION_ID%type;
      lnCharactID_4 DOC_POSITION_DETAIL.GCO3_GCO_CHARACTERIZATION_ID%type;
      lnCharactID_5 DOC_POSITION_DETAIL.GCO4_GCO_CHARACTERIZATION_ID%type;
    begin
      if FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'GCO_COMPONENT_ID') then
        -- initialisation des caractérisations
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotRecordComp, 'GCO_CHAR1_ID');
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotRecordComp, 'GCO_CHAR2_ID');
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotRecordComp, 'GCO_CHAR3_ID');
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotRecordComp, 'GCO_CHAR4_ID');
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotRecordComp, 'GCO_CHAR5_ID');

        if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ARC_CHAR1_VALUE') then
          FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotRecordComp, 'ARC_CHAR1_VALUE');
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ARC_CHAR2_VALUE') then
          FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotRecordComp, 'ARC_CHAR2_VALUE');
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ARC_CHAR3_VALUE') then
          FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotRecordComp, 'ARC_CHAR3_VALUE');
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ARC_CHAR4_VALUE') then
          FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotRecordComp, 'ARC_CHAR4_VALUE');
        end if;

        if not FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ARC_CHAR5_VALUE') then
          FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotRecordComp, 'ARC_CHAR5_VALUE');
        end if;
      end if;

      if not FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordComp, 'GCO_COMPONENT_ID') then
        if     (FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotRecordComp, 'ARC_QUANTITY') > 1)
           and GCO_I_LIB_CHARACTERIZATION.IsPieceChar(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotRecordComp, 'GCO_COMPONENT_ID') ) <> 0 then
          -- si gestion des pieces -> la quantité doit être égale à 1
          FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'ARC_QUANTITY', 1);
        end if;

        GCO_I_LIB_CHARACTERIZATION.GetCharacterizationsID(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotRecordComp, 'GCO_COMPONENT_ID')
                                                        , FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iotRecordComp, 'STM_COMP_MVT_KIND_ID')
                                                        , null
                                                        , 1
                                                        , '2'   -- domaine des ventes
                                                        , lnCharactID_1
                                                        , lnCharactID_2
                                                        , lnCharactID_3
                                                        , lnCharactID_4
                                                        , lnCharactID_5
                                                         );

        if FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ARC_CHAR1_VALUE') then
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordComp, 'ARC_CHAR1_VALUE') then
            FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotRecordComp, 'GCO_CHAR1_ID');
          else
            FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'GCO_CHAR1_ID', lnCharactID_1);
          end if;
        end if;

        if FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ARC_CHAR2_VALUE') then
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordComp, 'ARC_CHAR2_VALUE') then
            FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotRecordComp, 'GCO_CHAR2_ID');
          else
            FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'GCO_CHAR2_ID', lnCharactID_2);
          end if;
        end if;

        if FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ARC_CHAR3_VALUE') then
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordComp, 'ARC_CHAR3_VALUE') then
            FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotRecordComp, 'GCO_CHAR3_ID');
          else
            FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'GCO_CHAR3_ID', lnCharactID_3);
          end if;
        end if;

        if FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ARC_CHAR4_VALUE') then
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordComp, 'ARC_CHAR4_VALUE') then
            FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotRecordComp, 'GCO_CHAR4_ID');
          else
            FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'GCO_CHAR4_ID', lnCharactID_4);
          end if;
        end if;

        if FWK_I_MGT_ENTITY_DATA.IsModified(iotRecordComp, 'ARC_CHAR5_VALUE') then
          if FWK_I_MGT_ENTITY_DATA.IsNull(iotRecordComp, 'ARC_CHAR5_VALUE') then
            FWK_I_MGT_ENTITY_DATA.SetColumnNull(iotRecordComp, 'GCO_CHAR5_ID');
          else
            FWK_I_MGT_ENTITY_DATA.SetColumn(iotRecordComp, 'GCO_CHAR5_ID', lnCharactID_5);
          end if;
        end if;
      end if;
    end CheckCharact;
  begin
    -- Procedure ManageData
    if     ltplRecordComp.ASA_RECORD_ID is not null
       and ltplRecordComp.GCO_COMPONENT_ID is not null then
      select PC_ASA_CUST_LANG_ID
           , PAC_CUSTOM_PARTNER_ID
           , DOC_RECORD_ID
           , ACS_FINANCIAL_CURRENCY_ID
           , DIC_TARIFF_ID
           , DIC_TARIFF2_ID
           , ARE_DATECRE
        into lPC_LANG_ID
           , lPAC_CUSTOM_PARTNER_ID
           , lDOC_RECORD_ID
           , lACS_FINANCIAL_CURRENCY_ID
           , lDIC_TARIFF_ID
           , lDIC_TARIFF2_ID
           , lARE_DATECRE
        from ASA_RECORD
       where ASA_RECORD_ID = ltplRecordComp.ASA_RECORD_ID;

      CheckARC_POSITION;
      CheckARC_CDMVT;
      InitFields;
      CheckGCO_COMPONENT_ID;
      CheckPrices;
      CheckCharact;
    else
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.FATAL;

      if ltplRecordComp.ASA_RECORD_ID is null then
        lcError  := lcError || chr(13) || PCS.PC_FUNCTIONS.TranslateWord('Données manquantes') || ' : ASA_RECORD_ID !';
      end if;

      if ltplRecordComp.GCO_COMPONENT_ID is null then
        lcError  := lcError || chr(13) || PCS.PC_FUNCTIONS.TranslateWord('Données manquantes') || ' : GCO_COMPONENT_ID !';
      end if;

      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'InternalManageData'
                                         );
    end if;
  end ManageData;

  /**
  * procedure ClearPositionCompLink
  * Description
  *   Effacer le lien du composant SAV sur les positions de document
  * @author ECA
  * @created AUG.2011
  * @lastUpdate
  * @public
  * @param iCompID : id du composant du dossier SAV
  */
  procedure ClearPositionCompLink(iCompID in ASA_RECORD_COMP.ASA_RECORD_COMP_ID%type)
  is
    ltPos FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Effacer le lien du composant SAV sur les positions de document
    for tplPos in (select DOC_POSITION_ID
                     from DOC_POSITION
                    where ASA_RECORD_COMP_ID = iCompID) loop
      FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_DOC_ENTITY.gcDocPosition, iot_crud_definition => ltPos, in_main_id => tplPos.DOC_POSITION_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltPos, 'ASA_RECORD_COMP_ID');
      FWK_I_MGT_ENTITY.UpdateEntity(ltPos);
      FWK_I_MGT_ENTITY.Release(ltPos);
    end loop;
  end ClearPositionCompLink;

  /**
  * procedure CreateWorkshopOutStkMvts
  * Description
  *   Création des mvts de sortie de stock atelier de tous les composants d'un dossier SAV
  */
  procedure CreateWorkshopOutStkMvts(iAsaRecordID in ASA_RECORD.ASA_RECORD_ID%type, iRecordEventID in ASA_RECORD_EVENTS.ASA_RECORD_EVENTS_ID%type)
  is
    lMvtKindID STM_MOVEMENT_KIND.STM_MOVEMENT_KIND_ID%type;
    lErrMess   varchar2(1000);
  begin
    lMvtKindID  :=
      FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name   => 'STM_MOVEMENT_KIND'
                                  , iv_column_name   => 'MOK_ABBREVIATION'
                                  , iv_value         => PCS.PC_CONFIG.GetConfig('ASA_COMPONENT_KIND_MVT_OUT_TRA')
                                   );

    for ltplComp in (select   ARC_POSITION
                            , ASA_RECORD_COMP_ID
                            , STM_COMP_STOCK_MVT_ID
                            , STM_WORK_STOCK_MOVEMENT_ID
                         from ASA_RECORD_COMP
                        where ASA_RECORD_ID = iAsaRecordID
                          and ASA_RECORD_EVENTS_ID = iRecordEventID
                          and STM_COMP_STOCK_MVT_ID is not null
                          and STM_WORK_STOCK_MOVEMENT_ID is null
                          and STM_COMP_MVT_KIND_ID = lMvtKindID
                     order by GCO_COMPONENT_ID
                            , ARC_POSITION) loop
      -- sortie du stock atelier
      ASA_PRC_STOCK_MOVEMENTS.CpFactoryOutputMvt(ltplComp.ASA_RECORD_COMP_ID, lErrMess);

      if lErrMess is not null then
        ra(lErrMess);
      end if;
    end loop;
  end CreateWorkshopOutStkMvts;

  /**
  * procedure UpdateRecordEvent
  * Description
  *   Màj de l'ID d'une étape de flux sur tous les composants d'un dossier SAV
  */
  procedure UpdateRecordEvent(
    iAsaRecordID in ASA_RECORD.ASA_RECORD_ID%type
  , iNewEventID  in ASA_RECORD_EVENTS.ASA_RECORD_EVENTS_ID%type
  , iOldEventID  in ASA_RECORD_EVENTS.ASA_RECORD_EVENTS_ID%type
  )
  is
    ltComp         FWK_I_TYP_DEFINITION.t_crud_def;
    ltPos          FWK_I_TYP_DEFINITION.t_crud_def;
    lExistOldEvent integer;
  begin
    -- Vérifier s'il y a eu une suppression d'une étape de flux
    select sign(nvl(max(ASA_RECORD_EVENTS_ID), 0) )
      into lExistOldEvent
      from ASA_RECORD_EVENTS
     where ASA_RECORD_EVENTS_ID = iOldEventID;

    -- Une étape du flux a été supprimée
    if lExistOldEvent = 0 then
      -- Màj des DOC_POSITION avec le nouveau lien composant
      for tplComp in (select   ARC_NEW.ARC_POSITION
                             , ARC_NEW.ASA_RECORD_COMP_ID NEW_COMP_ID
                             , ARC_OLD.ASA_RECORD_COMP_ID OLD_COMP_ID
                          from (select ARC_POSITION
                                     , ASA_RECORD_COMP_ID
                                  from ASA_RECORD_COMP
                                 where ASA_RECORD_ID = iAsaRecordID
                                   and ASA_RECORD_EVENTS_ID = iOldEventID) ARC_OLD
                             , (select ARC_POSITION
                                     , ASA_RECORD_COMP_ID
                                  from ASA_RECORD_COMP
                                 where ASA_RECORD_ID = iAsaRecordID
                                   and ASA_RECORD_EVENTS_ID = iNewEventID) ARC_NEW
                         where ARC_OLD.ARC_POSITION = ARC_NEW.ARC_POSITION
                      order by ARC_NEW.ARC_POSITION) loop
        -- Màj des DOC_POSITION liées à l'ancien composant
        for tplPos in (select DOC_POSITION_ID
                         from DOC_POSITION
                        where ASA_RECORD_COMP_ID = tplComp.OLD_COMP_ID) loop
          FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocPosition, ltPos);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'DOC_POSITION_ID', tplPos.DOC_POSITION_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'ASA_RECORD_COMP_ID', tplComp.NEW_COMP_ID);
          FWK_I_MGT_ENTITY.UpdateEntity(ltPos);
          FWK_I_MGT_ENTITY.Release(ltPos);
        end loop;
      end loop;

      -- Effacer les composants historiés liées au flux qui va devenir le dernier flux
      for tplComp in (select   ASA_RECORD_COMP_ID
                          from ASA_RECORD_COMP
                         where ASA_RECORD_ID = iAsaRecordID
                           and nvl(ASA_RECORD_EVENTS_ID, -1) = iNewEventID
                      order by ARC_POSITION) loop
        FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordComp, ltComp);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'ASA_RECORD_COMP_ID', tplComp.ASA_RECORD_COMP_ID);
        FWK_I_MGT_ENTITY.DeleteEntity(ltComp);
        FWK_I_MGT_ENTITY.Release(ltComp);
      end loop;

      -- Les composants liés au flux supprimé deviennent liées au dernier flux
      for tplComp in (select   ASA_RECORD_COMP_ID
                          from ASA_RECORD_COMP
                         where ASA_RECORD_ID = iAsaRecordID
                           and nvl(ASA_RECORD_EVENTS_ID, -1) = nvl(iOldEventID, -1)
                      order by ARC_POSITION) loop
        FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordComp, ltComp);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'ASA_RECORD_COMP_ID', tplComp.ASA_RECORD_COMP_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'ASA_RECORD_EVENTS_ID', iNewEventID);
        FWK_I_MGT_ENTITY.UpdateEntity(ltComp);
        FWK_I_MGT_ENTITY.Release(ltComp);
      end loop;
    -- Gestion de l'historique des opérations = NON
    elsif    (upper(PCS.PC_CONFIG.GetConfig('ASA_TASK_AND_COMP_HISTORY') ) = 'FALSE')
          or (iOldEventID is null) then
      -- Màj l'id de l'étape de flux sur les composants
      for tplComp in (select   ASA_RECORD_COMP_ID
                          from ASA_RECORD_COMP
                         where ASA_RECORD_ID = iAsaRecordID
                           and nvl(ASA_RECORD_EVENTS_ID, -1) = nvl(iOldEventID, -1)
                      order by ARC_POSITION) loop
        FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordComp, ltComp);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'ASA_RECORD_COMP_ID', tplComp.ASA_RECORD_COMP_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'ASA_RECORD_EVENTS_ID', iNewEventID);
        FWK_I_MGT_ENTITY.UpdateEntity(ltComp);
        FWK_I_MGT_ENTITY.Release(ltComp);
      end loop;
    elsif     (upper(PCS.PC_CONFIG.GetConfig('ASA_TASK_AND_COMP_HISTORY') ) = 'TRUE')
          and (iOldEventID is not null) then
      -- Gestion de l'historique des composants = OUI
      -- et pas première étape du flux
      -- Balayer les composants liés à l'id de nouvelle étape de flux
      for tplComp in (select ASA_RECORD_COMP_ID
                        from ASA_RECORD_COMP
                       where ASA_RECORD_ID = iAsaRecordID
                         and ASA_RECORD_EVENTS_ID = iNewEventID) loop
        -- Effacer le lien ASA_RECORD_COMP_ID sur les positions document qui
        -- ont un id de composant qui est lié l'id de la nouvelle étape de flux
        for tplPos in (select DOC_POSITION_ID
                         from DOC_POSITION
                        where ASA_RECORD_COMP_ID = tplComp.ASA_RECORD_COMP_ID) loop
          FWK_I_MGT_ENTITY.new(FWK_TYP_DOC_ENTITY.gcDocPosition, ltPos);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltPos, 'DOC_POSITION_ID', tplPos.DOC_POSITION_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltPos, 'ASA_RECORD_COMP_ID');
          FWK_I_MGT_ENTITY.UpdateEntity(ltPos);
          FWK_I_MGT_ENTITY.Release(ltPos);
        end loop;

        -- Effacer les composants liés à l'id de la nouvelle étape de flux
        FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordComp, ltComp);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'ASA_RECORD_COMP_ID', tplComp.ASA_RECORD_COMP_ID);
        FWK_I_MGT_ENTITY.DeleteEntity(ltComp);
        FWK_I_MGT_ENTITY.Release(ltComp);
      end loop;

      -- Copie des composants pour le nouveau statut
      for tplComp in (select   ASA_RECORD_COMP_ID
                          from ASA_RECORD_COMP
                         where ASA_RECORD_ID = iAsaRecordID
                           and ASA_RECORD_EVENTS_ID = iOldEventID
                      order by ARC_POSITION) loop
        FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordComp, ltComp);
        FWK_I_MGT_ENTITY.load(ltComp, tplComp.ASA_RECORD_COMP_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'ASA_RECORD_COMP_ID', INIT_ID_SEQ.nextval);
        FWK_I_MGT_ENTITY_DATA.SetColumnsCreation(ltComp, true);   -- Initialise les champs de création A_DATECRE et A_IDMOD
        FWK_I_MGT_ENTITY_DATA.SetColumnsModification(ltComp, false);   -- Supprime les valeurs des champs de modification A_DATEMOD et A_IDMOD
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'ASA_RECORD_EVENTS_ID', iNewEventID);
        FWK_I_MGT_ENTITY.InsertEntity(ltComp);
        FWK_I_MGT_ENTITY.Release(ltComp);
      end loop;

      -- La position d'attribution ne doit être liée qu'à la version la plus récente du composant
      -- (même ASA_RECORD_EVENTS_ID que le dossier de réparation) }
      for tplComp in (select ASA_RECORD_COMP_ID
                        from ASA_RECORD_COMP
                       where ASA_RECORD_ID = iAsaRecordID
                         and ASA_RECORD_EVENTS_ID <> iNewEventID
                         and DOC_ATTRIB_POSITION_ID is not null) loop
        FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordComp, ltComp);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltComp, 'ASA_RECORD_COMP_ID', tplComp.ASA_RECORD_COMP_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltComp, 'DOC_ATTRIB_POSITION_ID');
        FWK_I_MGT_ENTITY.UpdateEntity(ltComp);
        FWK_I_MGT_ENTITY.Release(ltComp);
      end loop;
    end if;
  end UpdateRecordEvent;

  /**
  * procedure ClearAttribLink
  * Description
  *   Effacer le lien de la position d'attrib de tous les composants du dossier SAV
  */
  procedure ClearAttribLink(iAsaRecordID in ASA_RECORD.ASA_RECORD_ID%type)
  is
    ltComp FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Effacer le lien de la position d'attrib de tous les composants du dossier SAV
    FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordComp, ltComp);

    for tplComp in (select ASA_RECORD_COMP_ID
                      from ASA_RECORD_COMP
                     where ASA_RECORD_ID = iAsaRecordID
                       and DOC_ATTRIB_POSITION_ID is not null) loop
      FWK_I_MGT_ENTITY.new(iv_entity_name => FWK_TYP_ASA_ENTITY.gcAsaRecordComp, iot_crud_definition => ltComp, in_main_id => tplComp.ASA_RECORD_COMP_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumnNull(ltComp, 'DOC_ATTRIB_POSITION_ID');
      FWK_I_MGT_ENTITY.UpdateEntity(ltComp);
      FWK_I_MGT_ENTITY.Release(ltComp);
    end loop;
  end ClearAttribLink;

  /**
  * procedure CtrlAllStkMvt
  * Description
  *   Vérifier si tous les mvts des composants ont été effectués
  */
  function CtrlAllStkMvt(iAsaRecordID in ASA_RECORD.ASA_RECORD_ID%type, iRecordEventID in ASA_RECORD_EVENTS.ASA_RECORD_EVENTS_ID%type)
    return boolean
  is
    lResult boolean := true;
  begin
    -- Liste des composants du dossier pour le ctrl des mvts de stk
    for tplComp in (select   ARC_POSITION
                           , nvl(ARC_CDMVT, 0) ARC_CDMVT
                           , nvl(ARC_OPTIONAL, 0) ARC_OPTIONAL
                           , C_ASA_ACCEPT_OPTION
                           , STM_COMP_STOCK_MVT_ID
                        from ASA_RECORD_COMP
                       where ASA_RECORD_ID = iAsaRecordID
                         and ASA_RECORD_EVENTS_ID = iRecordEventID
                    order by ARC_POSITION) loop
      -- Vérifie si le mvt a été éffectué lorsqu'il n'est pas optionnel et
      -- qu'il est géré en stock
      if     (tplComp.ARC_CDMVT = 1)
         and (    (tplComp.ARC_OPTIONAL = 0)
              or (tplComp.C_ASA_ACCEPT_OPTION = '2') )
         and (tplComp.STM_COMP_STOCK_MVT_ID is null) then
        lResult  := false;
      end if;
    end loop;

    return lResult;
  end CtrlAllStkMvt;

  /**
  * Procedure AcceptEstimateComponent
  * Description
  *   Acceptation de composants pour le devis
  */
  procedure AcceptEstimateComponent(iComponentId in ASA_RECORD_COMP.ASA_RECORD_COMP_ID%type, iAccept in number)
  is
    ltRecordComp       FWK_I_TYP_DEFINITION.t_crud_def;
    lvCAsaAcceptOption varchar2(10);
  begin
    -- Création de l'entité ASA_RECORD_COMP
    FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordComp, ltRecordComp);
    -- Init de l'id du composant
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComp, 'ASA_RECORD_COMP_ID', iComponentId);

    -- Init de l'acceptation de l'option
    if iAccept = 0 then
      lvCAsaAcceptOption  := '1';
    else
      lvCAsaAcceptOption  := '2';
    end if;

    FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComp, 'C_ASA_ACCEPT_OPTION', lvCAsaAcceptOption);
    --Modification du composant
    FWK_I_MGT_ENTITY.UpdateEntity(ltRecordComp);
    FWK_I_MGT_ENTITY.Release(ltRecordComp);
  end AcceptEstimateComponent;
end ASA_PRC_RECORD_COMP;
