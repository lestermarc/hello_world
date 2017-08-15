--------------------------------------------------------
--  DDL for Package Body ASA_E_PRC_GUARANTY_CARDS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_E_PRC_GUARANTY_CARDS" 
is
  /**
  * procedure CreateGUARANTY_CARDS_RECORD
  * Description
  *   Création d'une carte de garantie
  *
  */
  procedure CreateGUARANTY_CARDS_RECORD(iv_ARE_NUMBER ASA_RECORD.ARE_NUMBER%type, iv_AGC_NUMBER in ASA_GUARANTY_CARDS.AGC_NUMBER%type)
  is
    lnError         integer;
    lcError         varchar2(2000);
    lASA_RECORD_ID  ASA_RECORD.ASA_RECORD_ID%type;
    ltGuarantyCards FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    if iv_ARE_NUMBER is null then
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.FATAL;
      lcError  := 'ARE_NUMBER not defined';
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CreateGUARANTY_CARDS_RECORD'
                                         );
    else
      -- Rechercher l'ID du dossier SAV
      lASA_RECORD_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'ASA_RECORD', iv_column_name => 'ARE_NUMBER', iv_value => iv_ARE_NUMBER);

      if lASA_RECORD_ID is null then
        lnError  := PCS.PC_E_LIB_STANDARD_ERROR.FATAL;
        lcError  := 'ASA_RECORD_ID not defined';
        fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                          , iv_message       => lcError
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'CreateGUARANTY_CARDS_RECORD'
                                           );
      end if;
    end if;

    if iv_AGC_NUMBER is null then
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.FATAL;
      lcError  := 'AGC_NUMBER not defined';
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CreateGUARANTY_CARDS_RECORD'
                                         );
    end if;

    -- Création de l'entité ASA_GUARANTY_CARDS
    FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaGuarantyCards, ltGuarantyCards, true);

    begin
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_NUMBER', iv_AGC_NUMBER);
      ASA_I_PRC_GUARANTY_CARDS.InitFromRecord(ltGuarantyCards, lASA_RECORD_ID);
      ASA_I_PRC_GUARANTY_CARDS.CheckGoodData(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltGuarantyCards, 'GCO_GOOD_ID'), ltGuarantyCards);
      ASA_I_PRC_GUARANTY_CARDS.CheckDates(ltGuarantyCards);
      FWK_I_MGT_ENTITY.InsertEntity(ltGuarantyCards);
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.OK;
      lcError  := '';
    exception
      when others then
        lnError  := sqlcode;
        lcError  := sqlerrm;
    end;

    FWK_I_MGT_ENTITY.Release(ltGuarantyCards);

    if lnError <> PCS.PC_E_LIB_STANDARD_ERROR.OK then
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CreateGUARANTY_CARDS_RECORD'
                                         );
    end if;
  end CreateGUARANTY_CARDS_RECORD;

  /**
  * procedure CreateGUARANTY_CARDS
  * Description
  *   Création d'une carte de garantie
  *
  */
  procedure CreateGUARANTY_CARDS(
    iv_AGC_NUMBER            in ASA_GUARANTY_CARDS.AGC_NUMBER%type
  , iv_GOO_MAJOR_REFERENCE   in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  -- caractérisation
  , iv_AGC_CHAR1_VALUE       in ASA_GUARANTY_CARDS.AGC_CHAR1_VALUE%type default null
  , iv_AGC_CHAR2_VALUE       in ASA_GUARANTY_CARDS.AGC_CHAR2_VALUE%type default null
  , iv_AGC_CHAR3_VALUE       in ASA_GUARANTY_CARDS.AGC_CHAR3_VALUE%type default null
  , iv_AGC_CHAR4_VALUE       in ASA_GUARANTY_CARDS.AGC_CHAR4_VALUE%type default null
  , iv_AGC_CHAR5_VALUE       in ASA_GUARANTY_CARDS.AGC_CHAR5_VALUE%type default null
  -- client final
  , iv_KEY1_FIN_CUST         in PAC_PERSON.PER_KEY1%type default null
  -- langue et adresse client final
  , iv_FIN_CUST_LANG         in PCS.PC_LANG.LANID%type default null
  , iv_AGC_ADDRESS_FIN_CUST  in ASA_GUARANTY_CARDS.AGC_ADDRESS_FIN_CUST%type default null
  , iv_AGC_POSTCODE_FIN_CUST in ASA_GUARANTY_CARDS.AGC_POSTCODE_FIN_CUST%type default null
  , iv_AGC_TOWN_FIN_CUST     in ASA_GUARANTY_CARDS.AGC_TOWN_FIN_CUST%type default null
  , iv_AGC_STATE_FIN_CUST    in ASA_GUARANTY_CARDS.AGC_STATE_FIN_CUST%type default null
  , iv_FIN_CUST_CNTRY        in PCS.PC_CNTRY.CNTID%type default null
  , iv_AGC_CARE_OF_CUST      in ASA_GUARANTY_CARDS.AGC_CARE_OF_CUST%type default null
  , iv_AGC_PO_BOX_CUST       in ASA_GUARANTY_CARDS.AGC_PO_BOX_CUST%type default null
  , in_AGC_PO_BOX_NBR_CUST   in ASA_GUARANTY_CARDS.AGC_PO_BOX_NBR_CUST%type default null
  , iv_AGC_COUNTY_CUST       in ASA_GUARANTY_CARDS.AGC_COUNTY_CUST%type default null
  -- détaillant
  , iv_KEY1_DISTRIB          in PAC_PERSON.PER_KEY1%type default null
  -- langue et adresse détaillant
  , iv_DISTRIB_LANG          in PCS.PC_LANG.LANID%type default null
  , iv_AGC_ADDRESS_DISTRIB   in ASA_GUARANTY_CARDS.AGC_ADDRESS_DISTRIB%type default null
  , iv_AGC_POSTCODE_DISTRIB  in ASA_GUARANTY_CARDS.AGC_POSTCODE_DISTRIB%type default null
  , iv_AGC_TOWN_DISTRIB      in ASA_GUARANTY_CARDS.AGC_TOWN_DISTRIB%type default null
  , iv_AGC_STATE_DISTRIB     in ASA_GUARANTY_CARDS.AGC_STATE_DISTRIB%type default null
  , iv_DISTRIB_CNTRY         in PCS.PC_CNTRY.CNTID%type default null
  , iv_AGC_CARE_OF_DET       in ASA_GUARANTY_CARDS.AGC_CARE_OF_DET%type default null
  , iv_AGC_PO_BOX_DET        in ASA_GUARANTY_CARDS.AGC_PO_BOX_DET%type default null
  , in_AGC_PO_BOX_NBR_DET    in ASA_GUARANTY_CARDS.AGC_PO_BOX_NBR_DET%type default null
  , iv_AGC_COUNTY_DET        in ASA_GUARANTY_CARDS.AGC_COUNTY_DET%type default null
  -- agent
  , iv_KEY1_AGENT            in PAC_PERSON.PER_KEY1%type default null
  -- langue et adresse agent
  , iv_AGENT_LANG            in PCS.PC_LANG.LANID%type default null
  , iv_AGC_ADDRESS_AGENT     in ASA_GUARANTY_CARDS.AGC_ADDRESS_AGENT%type default null
  , iv_AGC_POSTCODE_AGENT    in ASA_GUARANTY_CARDS.AGC_POSTCODE_AGENT%type default null
  , iv_AGC_TOWN_AGENT        in ASA_GUARANTY_CARDS.AGC_TOWN_AGENT%type default null
  , iv_AGC_STATE_AGENT       in ASA_GUARANTY_CARDS.AGC_STATE_AGENT%type default null
  , iv_AGENT_CNTRY           in PCS.PC_CNTRY.CNTID%type default null
  , iv_AGC_CARE_OF_AGENT     in ASA_GUARANTY_CARDS.AGC_CARE_OF_AGENT%type default null
  , iv_AGC_PO_BOX_AGENT      in ASA_GUARANTY_CARDS.AGC_PO_BOX_AGENT%type default null
  , in_AGC_PO_BOX_NBR_AGENT  in ASA_GUARANTY_CARDS.AGC_PO_BOX_NBR_AGENT%type default null
  , iv_AGC_COUNTY_AGENT      in ASA_GUARANTY_CARDS.AGC_COUNTY_AGENT%type default null
  -- dates de vente client final, détaillant, agent
  , id_AGC_SALEDATE          in ASA_GUARANTY_CARDS.AGC_SALEDATE%type default null
  , id_AGC_SALEDATE_DET      in ASA_GUARANTY_CARDS.AGC_SALEDATE_DET%type default null
  , id_AGC_SALEDATE_AGENT    in ASA_GUARANTY_CARDS.AGC_SALEDATE_AGENT%type default null
  -- gestion garantie
  , id_AGC_BEGIN             in ASA_GUARANTY_CARDS.AGC_BEGIN%type default null
  , in_AGC_DAYS              in ASA_GUARANTY_CARDS.AGC_DAYS%type default null
  , iv_C_ASA_GUARANTY_UNIT   in ASA_GUARANTY_CARDS.C_ASA_GUARANTY_UNIT%type default null
  -- gestion service
  , id_AGC_LAST_SERVICE_DATE in ASA_GUARANTY_CARDS.AGC_LAST_SERVICE_DATE%type default null
  , in_AGC_SER_PERIODICITY   in ASA_GUARANTY_CARDS.AGC_SER_PERIODICITY%type default null
  , iv_C_ASA_SERVICE_UNIT    in ASA_GUARANTY_CARDS.C_ASA_SERVICE_UNIT%type default null
  )
  is
    lnError                   integer;
    lcError                   varchar2(2000);
    lGCO_GOOD_ID              GCO_GOOD.GCO_GOOD_ID%type;
    lPAC_ASA_FIN_CUST_ID      ASA_GUARANTY_CARDS.PAC_ASA_FIN_CUST_ID%type;
    lPC_ASA_FIN_CUST_LANG_ID  ASA_GUARANTY_CARDS.PC_ASA_FIN_CUST_LANG_ID%type;
    lPC_ASA_FIN_CUST_CNTRY_ID ASA_GUARANTY_CARDS.PC_ASA_FIN_CUST_CNTRY_ID%type;
    lPAC_ASA_DISTRIB_ID       ASA_GUARANTY_CARDS.PAC_ASA_DISTRIB_ID%type;
    lPC_ASA_DISTRIB_LANG_ID   ASA_GUARANTY_CARDS.PC_ASA_DISTRIB_LANG_ID%type;
    lPC_ASA_DISTRIB_CNTRY_ID  ASA_GUARANTY_CARDS.PC_ASA_DISTRIB_CNTRY_ID%type;
    lPAC_ASA_AGENT_ID         ASA_GUARANTY_CARDS.PAC_ASA_AGENT_ID%type;
    lPC_ASA_AGENT_LANG_ID     ASA_GUARANTY_CARDS.PC_ASA_AGENT_LANG_ID%type;
    lPC_ASA_AGENT_CNTRY_ID    ASA_GUARANTY_CARDS.PC_ASA_AGENT_CNTRY_ID%type;
    ltGuarantyCards           FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    if iv_GOO_MAJOR_REFERENCE is not null then
      -- Rechercher l'ID du composant
      lGCO_GOOD_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name   => 'GCO_GOOD', iv_column_name => 'GOO_MAJOR_REFERENCE'
                                                   , iv_value         => iv_GOO_MAJOR_REFERENCE);
    end if;

    if lGCO_GOOD_ID is null then
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.FATAL;
      lcError  := ' GCO_GOOD_ID not defined';
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CreateGUARANTY_CARDS'
                                         );
    end if;

    if iv_AGC_NUMBER is null then
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.FATAL;
      lcError  := ' AGC_NUMBER not defined';
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CreateGUARANTY_CARDS'
                                         );
    end if;

    -- Création de l'entité ASA_GUARANTY_CARDS
    FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaGuarantyCards, ltGuarantyCards, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_NUMBER', iv_AGC_NUMBER);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'GCO_GOOD_ID', lGCO_GOOD_ID);

    if iv_KEY1_FIN_CUST is not null then
      lPAC_ASA_FIN_CUST_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'PAC_PERSON', iv_column_name => 'PER_KEY1', iv_value => iv_KEY1_FIN_CUST);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'PAC_ASA_FIN_CUST_ID', lPAC_ASA_FIN_CUST_ID, lPAC_ASA_FIN_CUST_ID is not null);
    end if;

    if iv_FIN_CUST_LANG is not null then
      lPC_ASA_FIN_CUST_LANG_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'PCS.PC_LANG', iv_column_name => 'LANID', iv_value => iv_FIN_CUST_LANG);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'PC_ASA_FIN_CUST_LANG_ID', lPC_ASA_FIN_CUST_LANG_ID, lPC_ASA_FIN_CUST_LANG_ID is not null);
    end if;

    if iv_FIN_CUST_CNTRY is not null then
      lPC_ASA_FIN_CUST_CNTRY_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'PCS.PC_CNTRY', iv_column_name => 'CNTID', iv_value => iv_FIN_CUST_CNTRY);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'PC_ASA_FIN_CUST_CNTRY_ID', lPC_ASA_FIN_CUST_CNTRY_ID, lPC_ASA_FIN_CUST_CNTRY_ID is not null);
    end if;

    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_ADDRESS_FIN_CUST', iv_AGC_POSTCODE_FIN_CUST, iv_AGC_ADDRESS_FIN_CUST is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_POSTCODE_FIN_CUST', iv_AGC_POSTCODE_FIN_CUST, iv_AGC_POSTCODE_FIN_CUST is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_TOWN_FIN_CUST', iv_AGC_TOWN_FIN_CUST, iv_AGC_TOWN_FIN_CUST is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_STATE_FIN_CUST', iv_AGC_STATE_FIN_CUST, iv_AGC_STATE_FIN_CUST is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_CARE_OF_CUST', iv_AGC_CARE_OF_CUST, iv_AGC_CARE_OF_CUST is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_PO_BOX_CUST', iv_AGC_PO_BOX_CUST, iv_AGC_PO_BOX_CUST is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_PO_BOX_NBR_CUST', in_AGC_PO_BOX_NBR_CUST, in_AGC_PO_BOX_NBR_CUST is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_COUNTY_CUST', iv_AGC_COUNTY_CUST, iv_AGC_COUNTY_CUST is not null);

    if iv_KEY1_DISTRIB is not null then
      lPAC_ASA_DISTRIB_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'PAC_PERSON', iv_column_name => 'PER_KEY1', iv_value => iv_KEY1_DISTRIB);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'PAC_ASA_DISTRIB_ID', lPAC_ASA_DISTRIB_ID, lPAC_ASA_DISTRIB_ID is not null);
    end if;

    if iv_DISTRIB_LANG is not null then
      lPC_ASA_DISTRIB_LANG_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'PCS.PC_LANG', iv_column_name => 'LANID', iv_value => iv_DISTRIB_LANG);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'PC_ASA_DISTRIB_LANG_ID', lPC_ASA_DISTRIB_LANG_ID, lPC_ASA_DISTRIB_LANG_ID is not null);
    end if;

    if iv_DISTRIB_CNTRY is not null then
      lPC_ASA_DISTRIB_CNTRY_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'PCS.PC_CNTRY', iv_column_name => 'CNTID', iv_value => iv_DISTRIB_CNTRY);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'PC_ASA_DISTRIB_CNTRY_ID', lPC_ASA_DISTRIB_CNTRY_ID, lPC_ASA_DISTRIB_CNTRY_ID is not null);
    end if;

    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_ADDRESS_DISTRIB', iv_AGC_ADDRESS_DISTRIB, iv_AGC_ADDRESS_DISTRIB is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_POSTCODE_DISTRIB', iv_AGC_POSTCODE_DISTRIB, iv_AGC_POSTCODE_DISTRIB is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_TOWN_DISTRIB', iv_AGC_TOWN_DISTRIB, iv_AGC_TOWN_DISTRIB is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_STATE_DISTRIB', iv_AGC_STATE_DISTRIB, iv_AGC_STATE_DISTRIB is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_CARE_OF_DET', iv_AGC_CARE_OF_DET, iv_AGC_CARE_OF_DET is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_PO_BOX_DET', iv_AGC_PO_BOX_DET, iv_AGC_PO_BOX_DET is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_PO_BOX_NBR_DET', in_AGC_PO_BOX_NBR_DET, in_AGC_PO_BOX_NBR_DET is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_COUNTY_DET', iv_AGC_COUNTY_DET, iv_AGC_COUNTY_DET is not null);

    if iv_KEY1_AGENT is not null then
      lPAC_ASA_AGENT_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'PAC_PERSON', iv_column_name => 'PER_KEY1', iv_value => iv_KEY1_AGENT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'PAC_ASA_AGENT_ID', lPAC_ASA_AGENT_ID, lPAC_ASA_AGENT_ID is not null);
    end if;

    if iv_AGENT_LANG is not null then
      lPC_ASA_AGENT_LANG_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'PCS.PC_LANG', iv_column_name => 'LANID', iv_value => iv_AGENT_LANG);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'PC_ASA_AGENT_LANG_ID', lPC_ASA_AGENT_LANG_ID, lPC_ASA_AGENT_LANG_ID is not null);
    end if;

    if iv_AGENT_CNTRY is not null then
      lPC_ASA_AGENT_CNTRY_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'PCS.PC_CNTRY', iv_column_name => 'CNTID', iv_value => iv_AGENT_CNTRY);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'PC_ASA_AGENT_CNTRY_ID', lPC_ASA_AGENT_CNTRY_ID, lPC_ASA_AGENT_CNTRY_ID is not null);
    end if;

    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_ADDRESS_AGENT', iv_AGC_POSTCODE_AGENT, iv_AGC_ADDRESS_AGENT is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_POSTCODE_AGENT', iv_AGC_POSTCODE_AGENT, iv_AGC_POSTCODE_AGENT is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_TOWN_AGENT', iv_AGC_TOWN_AGENT, iv_AGC_TOWN_AGENT is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_STATE_AGENT', iv_AGC_STATE_AGENT, iv_AGC_STATE_AGENT is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_CARE_OF_AGENT', iv_AGC_CARE_OF_AGENT, iv_AGC_CARE_OF_AGENT is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_PO_BOX_AGENT', iv_AGC_PO_BOX_AGENT, iv_AGC_PO_BOX_AGENT is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_PO_BOX_NBR_AGENT', in_AGC_PO_BOX_NBR_AGENT, in_AGC_PO_BOX_NBR_AGENT is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_COUNTY_AGENT', iv_AGC_COUNTY_AGENT, iv_AGC_COUNTY_AGENT is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_CHAR1_VALUE', iv_AGC_CHAR1_VALUE, iv_AGC_CHAR1_VALUE is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_CHAR2_VALUE', iv_AGC_CHAR2_VALUE, iv_AGC_CHAR2_VALUE is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_CHAR3_VALUE', iv_AGC_CHAR3_VALUE, iv_AGC_CHAR3_VALUE is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_CHAR4_VALUE', iv_AGC_CHAR4_VALUE, iv_AGC_CHAR4_VALUE is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_CHAR5_VALUE', iv_AGC_CHAR5_VALUE, iv_AGC_CHAR5_VALUE is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_SALEDATE', id_AGC_SALEDATE, id_AGC_SALEDATE is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_SALEDATE_DET', id_AGC_SALEDATE_DET, id_AGC_SALEDATE_DET is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_SALEDATE_AGENT', id_AGC_SALEDATE_AGENT, id_AGC_SALEDATE_AGENT is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_BEGIN', id_AGC_BEGIN, id_AGC_BEGIN is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_DAYS', in_AGC_DAYS, in_AGC_DAYS is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'C_ASA_GUARANTY_UNIT', iv_C_ASA_GUARANTY_UNIT, iv_C_ASA_GUARANTY_UNIT is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_LAST_SERVICE_DATE', id_AGC_LAST_SERVICE_DATE, id_AGC_LAST_SERVICE_DATE is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_SER_PERIODICITY', in_AGC_SER_PERIODICITY, in_AGC_SER_PERIODICITY is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'C_ASA_SERVICE_UNIT', iv_C_ASA_SERVICE_UNIT, iv_C_ASA_SERVICE_UNIT is not null);

    begin
      ASA_I_PRC_GUARANTY_CARDS.CheckGoodData(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltGuarantyCards, 'GCO_GOOD_ID'), ltGuarantyCards);
      ASA_I_PRC_GUARANTY_CARDS.CheckThirdsData(ltGuarantyCards);
      ASA_I_PRC_GUARANTY_CARDS.CheckCharact(ltGuarantyCards);
      ASA_I_PRC_GUARANTY_CARDS.CheckDates(ltGuarantyCards);
      FWK_I_MGT_ENTITY.InsertEntity(ltGuarantyCards);
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.OK;
      lcError  := '';
    exception
      when others then
        lnError  := sqlcode;
        lcError  := sqlerrm;
    end;

    FWK_I_MGT_ENTITY.Release(ltGuarantyCards);

    if lnError <> PCS.PC_E_LIB_STANDARD_ERROR.OK then
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CreateGUARANTY_CARDS'
                                         );
    end if;
  end CreateGUARANTY_CARDS;

  /**
  * procedure UpdateGUARANTY_CARDS
  * Description
  *   mise à jour d'une carte de garantie
  *
  */
  procedure UpdateGUARANTY_CARDS(
    iv_AGC_NUMBER            in ASA_GUARANTY_CARDS.AGC_NUMBER%type
  , iv_GOO_MAJOR_REFERENCE   in GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  -- caractérisation
  , iv_AGC_CHAR1_VALUE       in ASA_GUARANTY_CARDS.AGC_CHAR1_VALUE%type default null
  , iv_AGC_CHAR2_VALUE       in ASA_GUARANTY_CARDS.AGC_CHAR2_VALUE%type default null
  , iv_AGC_CHAR3_VALUE       in ASA_GUARANTY_CARDS.AGC_CHAR3_VALUE%type default null
  , iv_AGC_CHAR4_VALUE       in ASA_GUARANTY_CARDS.AGC_CHAR4_VALUE%type default null
  , iv_AGC_CHAR5_VALUE       in ASA_GUARANTY_CARDS.AGC_CHAR5_VALUE%type default null
  -- client final
  , iv_KEY1_FIN_CUST         in PAC_PERSON.PER_KEY1%type default null
  -- langue et adresse client final
  , iv_FIN_CUST_LANG         in PCS.PC_LANG.LANID%type default null
  , iv_AGC_ADDRESS_FIN_CUST  in ASA_GUARANTY_CARDS.AGC_ADDRESS_FIN_CUST%type default null
  , iv_AGC_POSTCODE_FIN_CUST in ASA_GUARANTY_CARDS.AGC_POSTCODE_FIN_CUST%type default null
  , iv_AGC_TOWN_FIN_CUST     in ASA_GUARANTY_CARDS.AGC_TOWN_FIN_CUST%type default null
  , iv_AGC_STATE_FIN_CUST    in ASA_GUARANTY_CARDS.AGC_STATE_FIN_CUST%type default null
  , iv_FIN_CUST_CNTRY        in PCS.PC_CNTRY.CNTID%type default null
  , iv_AGC_CARE_OF_CUST      in ASA_GUARANTY_CARDS.AGC_CARE_OF_CUST%type default null
  , iv_AGC_PO_BOX_CUST       in ASA_GUARANTY_CARDS.AGC_PO_BOX_CUST%type default null
  , in_AGC_PO_BOX_NBR_CUST   in ASA_GUARANTY_CARDS.AGC_PO_BOX_NBR_CUST%type default null
  , iv_AGC_COUNTY_CUST       in ASA_GUARANTY_CARDS.AGC_COUNTY_CUST%type default null
  -- détaillant
  , iv_KEY1_DISTRIB          in PAC_PERSON.PER_KEY1%type default null
  -- langue et adresse détaillant
  , iv_DISTRIB_LANG          in PCS.PC_LANG.LANID%type default null
  , iv_AGC_ADDRESS_DISTRIB   in ASA_GUARANTY_CARDS.AGC_ADDRESS_DISTRIB%type default null
  , iv_AGC_POSTCODE_DISTRIB  in ASA_GUARANTY_CARDS.AGC_POSTCODE_DISTRIB%type default null
  , iv_AGC_TOWN_DISTRIB      in ASA_GUARANTY_CARDS.AGC_TOWN_DISTRIB%type default null
  , iv_AGC_STATE_DISTRIB     in ASA_GUARANTY_CARDS.AGC_STATE_DISTRIB%type default null
  , iv_DISTRIB_CNTRY         in PCS.PC_CNTRY.CNTID%type default null
  , iv_AGC_CARE_OF_DET       in ASA_GUARANTY_CARDS.AGC_CARE_OF_DET%type default null
  , iv_AGC_PO_BOX_DET        in ASA_GUARANTY_CARDS.AGC_PO_BOX_DET%type default null
  , in_AGC_PO_BOX_NBR_DET    in ASA_GUARANTY_CARDS.AGC_PO_BOX_NBR_DET%type default null
  , iv_AGC_COUNTY_DET        in ASA_GUARANTY_CARDS.AGC_COUNTY_DET%type default null
  -- agent
  , iv_KEY1_AGENT            in PAC_PERSON.PER_KEY1%type default null
  -- langue et adresse agent
  , iv_AGENT_LANG            in PCS.PC_LANG.LANID%type default null
  , iv_AGC_ADDRESS_AGENT     in ASA_GUARANTY_CARDS.AGC_ADDRESS_AGENT%type default null
  , iv_AGC_POSTCODE_AGENT    in ASA_GUARANTY_CARDS.AGC_POSTCODE_AGENT%type default null
  , iv_AGC_TOWN_AGENT        in ASA_GUARANTY_CARDS.AGC_TOWN_AGENT%type default null
  , iv_AGC_STATE_AGENT       in ASA_GUARANTY_CARDS.AGC_STATE_AGENT%type default null
  , iv_AGENT_CNTRY           in PCS.PC_CNTRY.CNTID%type default null
  , iv_AGC_CARE_OF_AGENT     in ASA_GUARANTY_CARDS.AGC_CARE_OF_AGENT%type default null
  , iv_AGC_PO_BOX_AGENT      in ASA_GUARANTY_CARDS.AGC_PO_BOX_AGENT%type default null
  , in_AGC_PO_BOX_NBR_AGENT  in ASA_GUARANTY_CARDS.AGC_PO_BOX_NBR_AGENT%type default null
  , iv_AGC_COUNTY_AGENT      in ASA_GUARANTY_CARDS.AGC_COUNTY_AGENT%type default null
  -- dates de vente client final, détaillant, agent
  , id_AGC_SALEDATE          in ASA_GUARANTY_CARDS.AGC_SALEDATE%type default null
  , id_AGC_SALEDATE_DET      in ASA_GUARANTY_CARDS.AGC_SALEDATE_DET%type default null
  , id_AGC_SALEDATE_AGENT    in ASA_GUARANTY_CARDS.AGC_SALEDATE_AGENT%type default null
  -- gestion garantie
  , id_AGC_BEGIN             in ASA_GUARANTY_CARDS.AGC_BEGIN%type default null
  , in_AGC_DAYS              in ASA_GUARANTY_CARDS.AGC_DAYS%type default null
  , iv_C_ASA_GUARANTY_UNIT   in ASA_GUARANTY_CARDS.C_ASA_GUARANTY_UNIT%type default null
  -- gestion service
  , id_AGC_LAST_SERVICE_DATE in ASA_GUARANTY_CARDS.AGC_LAST_SERVICE_DATE%type default null
  , in_AGC_SER_PERIODICITY   in ASA_GUARANTY_CARDS.AGC_SER_PERIODICITY%type default null
  , iv_C_ASA_SERVICE_UNIT    in ASA_GUARANTY_CARDS.C_ASA_SERVICE_UNIT%type default null
  )
  is
    lnError                   integer;
    lcError                   varchar2(2000);
    lASA_GUARANTY_CARDS_ID    ASA_GUARANTY_CARDS.ASA_GUARANTY_CARDS_ID%type;
    lGCO_GOOD_ID              GCO_GOOD.GCO_GOOD_ID%type;
    lPAC_ASA_FIN_CUST_ID      ASA_GUARANTY_CARDS.PAC_ASA_FIN_CUST_ID%type;
    lPC_ASA_FIN_CUST_LANG_ID  ASA_GUARANTY_CARDS.PC_ASA_FIN_CUST_LANG_ID%type;
    lPC_ASA_FIN_CUST_CNTRY_ID ASA_GUARANTY_CARDS.PC_ASA_FIN_CUST_CNTRY_ID%type;
    lPAC_ASA_DISTRIB_ID       ASA_GUARANTY_CARDS.PAC_ASA_DISTRIB_ID%type;
    lPC_ASA_DISTRIB_LANG_ID   ASA_GUARANTY_CARDS.PC_ASA_DISTRIB_LANG_ID%type;
    lPC_ASA_DISTRIB_CNTRY_ID  ASA_GUARANTY_CARDS.PC_ASA_DISTRIB_CNTRY_ID%type;
    lPAC_ASA_AGENT_ID         ASA_GUARANTY_CARDS.PAC_ASA_AGENT_ID%type;
    lPC_ASA_AGENT_LANG_ID     ASA_GUARANTY_CARDS.PC_ASA_AGENT_LANG_ID%type;
    lPC_ASA_AGENT_CNTRY_ID    ASA_GUARANTY_CARDS.PC_ASA_AGENT_CNTRY_ID%type;
    ltGuarantyCards           FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    if iv_AGC_NUMBER is null then
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.FATAL;
      lcError  := ' AGC_NUMBER not defined';
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'UpdateGUARANTY_CARDS'
                                         );
    else
      lASA_GUARANTY_CARDS_ID  :=
                               FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name   => 'ASA_GUARANTY_CARDS', iv_column_name => 'AGC_NUMBER'
                                                           , iv_value         => iv_AGC_NUMBER);
    end if;

    FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaGuarantyCards, ltGuarantyCards, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'ASA_GUARANTY_CARDS_ID', lASA_GUARANTY_CARDS_ID);

    if iv_GOO_MAJOR_REFERENCE is not null then
      lGCO_GOOD_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name   => 'GCO_GOOD', iv_column_name => 'GOO_MAJOR_REFERENCE'
                                                   , iv_value         => iv_GOO_MAJOR_REFERENCE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'GCO_GOOD_ID', lGCO_GOOD_ID, lGCO_GOOD_ID is not null);
    end if;

    if iv_KEY1_FIN_CUST is not null then
      lPAC_ASA_FIN_CUST_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'PAC_PERSON', iv_column_name => 'PER_KEY1', iv_value => iv_KEY1_FIN_CUST);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'PAC_ASA_FIN_CUST_ID', lPAC_ASA_FIN_CUST_ID, lPAC_ASA_FIN_CUST_ID is not null);
    end if;

    if iv_FIN_CUST_LANG is not null then
      lPC_ASA_FIN_CUST_LANG_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'PCS.PC_LANG', iv_column_name => 'LANID', iv_value => iv_FIN_CUST_LANG);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'PC_ASA_FIN_CUST_LANG_ID', lPC_ASA_FIN_CUST_LANG_ID, lPC_ASA_FIN_CUST_LANG_ID is not null);
    end if;

    if iv_FIN_CUST_CNTRY is not null then
      lPC_ASA_FIN_CUST_CNTRY_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'PCS.PC_CNTRY', iv_column_name => 'CNTID', iv_value => iv_FIN_CUST_CNTRY);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'PC_ASA_FIN_CUST_CNTRY_ID', lPC_ASA_FIN_CUST_CNTRY_ID, lPC_ASA_FIN_CUST_CNTRY_ID is not null);
    end if;

    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_ADDRESS_FIN_CUST', iv_AGC_POSTCODE_FIN_CUST, iv_AGC_ADDRESS_FIN_CUST is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_POSTCODE_FIN_CUST', iv_AGC_POSTCODE_FIN_CUST, iv_AGC_POSTCODE_FIN_CUST is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_TOWN_FIN_CUST', iv_AGC_TOWN_FIN_CUST, iv_AGC_TOWN_FIN_CUST is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_STATE_FIN_CUST', iv_AGC_STATE_FIN_CUST, iv_AGC_STATE_FIN_CUST is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_CARE_OF_CUST', iv_AGC_CARE_OF_CUST, iv_AGC_CARE_OF_CUST is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_PO_BOX_CUST', iv_AGC_PO_BOX_CUST, iv_AGC_PO_BOX_CUST is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_PO_BOX_NBR_CUST', in_AGC_PO_BOX_NBR_CUST, in_AGC_PO_BOX_NBR_CUST is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_COUNTY_CUST', iv_AGC_COUNTY_CUST, iv_AGC_COUNTY_CUST is not null);

    if iv_KEY1_DISTRIB is not null then
      lPAC_ASA_DISTRIB_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'PAC_PERSON', iv_column_name => 'PER_KEY1', iv_value => iv_KEY1_DISTRIB);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'PAC_ASA_DISTRIB_ID', lPAC_ASA_DISTRIB_ID, lPAC_ASA_DISTRIB_ID is not null);
    end if;

    if iv_DISTRIB_LANG is not null then
      lPC_ASA_DISTRIB_LANG_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'PCS.PC_LANG', iv_column_name => 'LANID', iv_value => iv_DISTRIB_LANG);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'PC_ASA_DISTRIB_LANG_ID', lPC_ASA_DISTRIB_LANG_ID, lPC_ASA_DISTRIB_LANG_ID is not null);
    end if;

    if iv_DISTRIB_CNTRY is not null then
      lPC_ASA_DISTRIB_CNTRY_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'PCS.PC_CNTRY', iv_column_name => 'CNTID', iv_value => iv_DISTRIB_CNTRY);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'PC_ASA_DISTRIB_CNTRY_ID', lPC_ASA_DISTRIB_CNTRY_ID, lPC_ASA_DISTRIB_CNTRY_ID is not null);
    end if;

    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_ADDRESS_DISTRIB', iv_AGC_ADDRESS_DISTRIB, iv_AGC_ADDRESS_DISTRIB is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_POSTCODE_DISTRIB', iv_AGC_POSTCODE_DISTRIB, iv_AGC_POSTCODE_DISTRIB is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_TOWN_DISTRIB', iv_AGC_TOWN_DISTRIB, iv_AGC_TOWN_DISTRIB is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_STATE_DISTRIB', iv_AGC_STATE_DISTRIB, iv_AGC_STATE_DISTRIB is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_CARE_OF_DET', iv_AGC_CARE_OF_DET, iv_AGC_CARE_OF_DET is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_PO_BOX_DET', iv_AGC_PO_BOX_DET, iv_AGC_PO_BOX_DET is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_PO_BOX_NBR_DET', in_AGC_PO_BOX_NBR_DET, in_AGC_PO_BOX_NBR_DET is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_COUNTY_DET', iv_AGC_COUNTY_DET, iv_AGC_COUNTY_DET is not null);

    if iv_KEY1_AGENT is not null then
      lPAC_ASA_AGENT_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'PAC_PERSON', iv_column_name => 'PER_KEY1', iv_value => iv_KEY1_AGENT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'PAC_ASA_AGENT_ID', lPAC_ASA_AGENT_ID, lPAC_ASA_AGENT_ID is not null);
    end if;

    if iv_AGENT_LANG is not null then
      lPC_ASA_AGENT_LANG_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'PCS.PC_LANG', iv_column_name => 'LANID', iv_value => iv_AGENT_LANG);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'PC_ASA_AGENT_LANG_ID', lPC_ASA_AGENT_LANG_ID, lPC_ASA_AGENT_LANG_ID is not null);
    end if;

    if iv_AGENT_CNTRY is not null then
      lPC_ASA_AGENT_CNTRY_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'PCS.PC_CNTRY', iv_column_name => 'CNTID', iv_value => iv_AGENT_CNTRY);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'PC_ASA_AGENT_CNTRY_ID', lPC_ASA_AGENT_CNTRY_ID, lPC_ASA_AGENT_CNTRY_ID is not null);
    end if;

    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_ADDRESS_AGENT', iv_AGC_POSTCODE_AGENT, iv_AGC_ADDRESS_AGENT is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_POSTCODE_AGENT', iv_AGC_POSTCODE_AGENT, iv_AGC_POSTCODE_AGENT is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_TOWN_AGENT', iv_AGC_TOWN_AGENT, iv_AGC_TOWN_AGENT is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_STATE_AGENT', iv_AGC_STATE_AGENT, iv_AGC_STATE_AGENT is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_CARE_OF_AGENT', iv_AGC_CARE_OF_AGENT, iv_AGC_CARE_OF_AGENT is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_PO_BOX_AGENT', iv_AGC_PO_BOX_AGENT, iv_AGC_PO_BOX_AGENT is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_PO_BOX_NBR_AGENT', in_AGC_PO_BOX_NBR_AGENT, in_AGC_PO_BOX_NBR_AGENT is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_COUNTY_AGENT', iv_AGC_COUNTY_AGENT, iv_AGC_COUNTY_AGENT is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_CHAR1_VALUE', iv_AGC_CHAR1_VALUE, iv_AGC_CHAR1_VALUE is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_CHAR2_VALUE', iv_AGC_CHAR2_VALUE, iv_AGC_CHAR2_VALUE is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_CHAR3_VALUE', iv_AGC_CHAR3_VALUE, iv_AGC_CHAR3_VALUE is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_CHAR4_VALUE', iv_AGC_CHAR4_VALUE, iv_AGC_CHAR4_VALUE is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_CHAR5_VALUE', iv_AGC_CHAR5_VALUE, iv_AGC_CHAR5_VALUE is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_SALEDATE', id_AGC_SALEDATE, id_AGC_SALEDATE is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_SALEDATE_DET', id_AGC_SALEDATE_DET, id_AGC_SALEDATE_DET is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_SALEDATE_AGENT', id_AGC_SALEDATE_AGENT, id_AGC_SALEDATE_AGENT is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_BEGIN', id_AGC_BEGIN, id_AGC_BEGIN is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_DAYS', in_AGC_DAYS, in_AGC_DAYS is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'C_ASA_GUARANTY_UNIT', iv_C_ASA_GUARANTY_UNIT, iv_C_ASA_GUARANTY_UNIT is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_LAST_SERVICE_DATE', id_AGC_LAST_SERVICE_DATE, id_AGC_LAST_SERVICE_DATE is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'AGC_SER_PERIODICITY', in_AGC_SER_PERIODICITY, in_AGC_SER_PERIODICITY is not null);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'C_ASA_SERVICE_UNIT', iv_C_ASA_SERVICE_UNIT, iv_C_ASA_SERVICE_UNIT is not null);

    begin
      ASA_I_PRC_GUARANTY_CARDS.CheckGoodData(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltGuarantyCards, 'GCO_GOOD_ID'), ltGuarantyCards);
      ASA_I_PRC_GUARANTY_CARDS.CheckThirdsData(ltGuarantyCards);
      ASA_I_PRC_GUARANTY_CARDS.CheckCharact(ltGuarantyCards);
      ASA_I_PRC_GUARANTY_CARDS.CheckDates(ltGuarantyCards);
      FWK_I_MGT_ENTITY.UpdateEntity(ltGuarantyCards);
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.OK;
      lcError  := '';
    exception
      when others then
        lnError  := sqlcode;
        lcError  := sqlerrm;
    end;

    FWK_I_MGT_ENTITY.Release(ltGuarantyCards);

    if lnError <> PCS.PC_E_LIB_STANDARD_ERROR.OK then
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'UpdateGUARANTY_CARDS'
                                         );
    end if;
  end UpdateGUARANTY_CARDS;

  /**
  * procedure DeleteGUARANTY_CARDS
  * Description
  *   Suppression d'une carte de garant
  * @author AGA
  * @created 09.2011
  * @lastUpdate
  * @public
   * @param iv_AGC_NUMBER            : référence de la carte de garantie
  */
  procedure DeleteGUARANTY_CARDS(iv_AGC_NUMBER in ASA_GUARANTY_CARDS.AGC_NUMBER%type)
  is
    lnError                integer;
    lcError                varchar2(2000);
    lASA_GUARANTY_CARDS_ID ASA_GUARANTY_CARDS.ASA_GUARANTY_CARDS_ID%type;
    ltGuarantyCards        FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    if iv_AGC_NUMBER is null then
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.FATAL;
      lcError  := ' AGC_NUMBER not defined';
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'DeleteGUARANTY_CARDS'
                                         );
    else
      lASA_GUARANTY_CARDS_ID  :=
                               FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name   => 'ASA_GUARANTY_CARDS', iv_column_name => 'AGC_NUMBER'
                                                           , iv_value         => iv_AGC_NUMBER);
    end if;

    FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaGuarantyCards, ltGuarantyCards, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltGuarantyCards, 'ASA_GUARANTY_CARDS_ID', lASA_GUARANTY_CARDS_ID);

    begin
      FWK_I_MGT_ENTITY.DeleteEntity(ltGuarantyCards);
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.OK;
      lcError  := '';
    exception
      when others then
        lnError  := sqlcode;
        lcError  := sqlerrm;
    end;

    FWK_I_MGT_ENTITY.Release(ltGuarantyCards);

    if lnError <> PCS.PC_E_LIB_STANDARD_ERROR.OK then
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'DeleteGUARANTY_CARDS'
                                         );
    end if;
  end DeleteGUARANTY_CARDS;
end ASA_E_PRC_GUARANTY_CARDS;
