--------------------------------------------------------
--  DDL for Package Body ASA_E_PRC_RECORD
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_E_PRC_RECORD" 
is
  procedure CreateRECORD(
    iov_ARE_NUMBER                in out ASA_RECORD.ARE_NUMBER%type
  , iv_RET_REP_TYPE               in     ASA_REP_TYPE.RET_REP_TYPE%type default null
  , iv_C_ASA_REP_TYPE_KIND        in     ASA_RECORD.C_ASA_REP_TYPE_KIND%type default null
  , id_ARE_DATECRE                in     ASA_RECORD.ARE_DATECRE%type default sysdate
  , iv_RCO_TITLE                  in     DOC_RECORD.RCO_TITLE%type default null
  , iv_PCO_DESCR                  in     PAC_PAYMENT_CONDITION.PCO_DESCR%type default null
  , iv_REP_DESCR                  in     PAC_REPRESENTATIVE.REP_DESCR%type default null
  , iv_DIC_TARIFF_ID              in     ASA_RECORD.DIC_TARIFF_ID%type default null
  , iv_DIC_TARIFF2_ID             in     ASA_RECORD.DIC_TARIFF2_ID%type default null
  , iv_DIC_TYPE_SUBMISSION_ID     in     ASA_RECORD.DIC_TYPE_SUBMISSION_ID%type default null
  , iv_CURRENCY                   in     PCS.PC_CURR.CURRNAME%type default null
  , in_ARE_CURR_BASE_PRICE        in     ASA_RECORD.ARE_CURR_BASE_PRICE%type default null
  , in_ARE_CURR_RATE_OF_EXCH      in     ASA_RECORD.ARE_CURR_RATE_OF_EXCH%type default null
  , in_ARE_COST_PRICE_S           in     ASA_RECORD.ARE_COST_PRICE_S%type default null
  , in_ARE_COST_PRICE_W           in     ASA_RECORD.ARE_COST_PRICE_W%type default null
  , in_ARE_COST_PRICE_C           in     ASA_RECORD.ARE_COST_PRICE_C%type default null
  , in_ARE_COST_PRICE_T           in     ASA_RECORD.ARE_COST_PRICE_T%type default null
  , in_ARE_SALE_PRICE_S           in     ASA_RECORD.ARE_SALE_PRICE_S%type default null
  , in_ARE_SALE_PRICE_W           in     ASA_RECORD.ARE_SALE_PRICE_W%type default null
  , in_ARE_SALE_PRICE_C           in     ASA_RECORD.ARE_SALE_PRICE_C%type default null
  , in_ARE_SALE_PRICE_T_MB        in     ASA_RECORD.ARE_SALE_PRICE_T_MB%type default null
  , in_ARE_SALE_PRICE_T_ME        in     ASA_RECORD.ARE_SALE_PRICE_T_ME%type default null
  , in_ARE_MIN_SALE_PRICE_MB      in     ASA_RECORD.ARE_MIN_SALE_PRICE_MB%type default null
  , in_ARE_MIN_SALE_PRICE_ME      in     ASA_RECORD.ARE_MIN_SALE_PRICE_ME%type default null
  , in_ARE_MAX_SALE_PRICE_MB      in     ASA_RECORD.ARE_MAX_SALE_PRICE_MB%type default null
  , in_ARE_MAX_SALE_PRICE_ME      in     ASA_RECORD.ARE_MAX_SALE_PRICE_ME%type default null
  , in_ARE_RECALC_SALE_PRICE_2    in     ASA_RECORD.ARE_RECALC_SALE_PRICE_2%type default 0
  , in_ARE_RECALC_COST_PRICE_2    in     ASA_RECORD.ARE_RECALC_COST_PRICE_2%type default 0
  , iv_CUSTOMER_KEY               in     PAC_PERSON.PER_KEY1%type default null
  , iv_CUSTOMER_LANID             in     PCS.PC_LANG.LANID%type default null
  , iv_SEN_KEY                    in     PAC_SENDING_CONDITION.SEN_KEY%type default null
  , iv_C_CONDITION_MODE           in     PAC_SENDING_CONDITION.C_CONDITION_MODE%type default null
  , iv_ARE_ADDRESS1               in     ASA_RECORD.ARE_ADDRESS1%type default null
  , iv_ARE_POSTCODE1              in     ASA_RECORD.ARE_POSTCODE1%type default null
  , iv_ARE_TOWN1                  in     ASA_RECORD.ARE_TOWN1%type default null
  , iv_ARE_STATE1                 in     ASA_RECORD.ARE_STATE1%type default null
  , iv_CNTID1                     in     PCS.PC_CNTRY.CNTID%type default null
  , iv_ARE_CARE_OF1               in     ASA_RECORD.ARE_CARE_OF1%type default null
  , iv_ARE_PO_BOX1                in     ASA_RECORD.ARE_PO_BOX1%type default null
  , in_ARE_PO_BOX_NBR1            in     ASA_RECORD.ARE_PO_BOX_NBR1%type default null
  , iv_ARE_COUNTY1                in     ASA_RECORD.ARE_COUNTY1%type default null
  , iv_ARE_ADDRESS2               in     ASA_RECORD.ARE_ADDRESS1%type default null
  , iv_ARE_POSTCODE2              in     ASA_RECORD.ARE_POSTCODE1%type default null
  , iv_ARE_TOWN2                  in     ASA_RECORD.ARE_TOWN1%type default null
  , iv_ARE_STATE2                 in     ASA_RECORD.ARE_STATE1%type default null
  , iv_CNTID2                     in     PCS.PC_CNTRY.CNTID%type default null
  , iv_ARE_CARE_OF2               in     ASA_RECORD.ARE_CARE_OF2%type default null
  , iv_ARE_PO_BOX2                in     ASA_RECORD.ARE_PO_BOX2%type default null
  , in_ARE_PO_BOX_NBR2            in     ASA_RECORD.ARE_PO_BOX_NBR2%type default null
  , iv_ARE_COUNTY2                in     ASA_RECORD.ARE_COUNTY2%type default null
  , iv_ARE_ADDRESS3               in     ASA_RECORD.ARE_ADDRESS1%type default null
  , iv_ARE_POSTCODE3              in     ASA_RECORD.ARE_POSTCODE1%type default null
  , iv_ARE_TOWN3                  in     ASA_RECORD.ARE_TOWN1%type default null
  , iv_ARE_STATE3                 in     ASA_RECORD.ARE_STATE1%type default null
  , iv_CNTID3                     in     PCS.PC_CNTRY.CNTID%type default null
  , iv_ARE_CARE_OF3               in     ASA_RECORD.ARE_CARE_OF3%type default null
  , iv_ARE_PO_BOX3                in     ASA_RECORD.ARE_PO_BOX3%type default null
  , in_ARE_PO_BOX_NBR3            in     ASA_RECORD.ARE_PO_BOX_NBR3%type default null
  , iv_ARE_COUNTY3                in     ASA_RECORD.ARE_COUNTY3%type default null
  , iv_AGENT_KEY                  in     PAC_PERSON.PER_KEY1%type default null
  , iv_AGENT_LANID                in     PCS.PC_LANG.LANID%type default null
  , iv_ARE_ADDRESS_AGENT          in     ASA_RECORD.ARE_ADDRESS1%type default null
  , iv_ARE_POSTCODE_AGENT         in     ASA_RECORD.ARE_POSTCODE1%type default null
  , iv_ARE_TOWN_AGENT             in     ASA_RECORD.ARE_TOWN1%type default null
  , iv_ARE_STATE_AGENT            in     ASA_RECORD.ARE_STATE1%type default null
  , iv_AGENT_CNTID                in     PCS.PC_CNTRY.CNTID%type default null
  , iv_ARE_CARE_OF_AGENT          in     ASA_RECORD.ARE_CARE_OF_AGENT%type default null
  , iv_ARE_PO_BOX_AGENT           in     ASA_RECORD.ARE_PO_BOX_AGENT%type default null
  , in_ARE_PO_BOX_NBR_AGENT       in     ASA_RECORD.ARE_PO_BOX_NBR_AGENT%type default null
  , iv_ARE_COUNTY_AGENT           in     ASA_RECORD.ARE_COUNTY_AGENT%type default null
  , iv_DISTRIB_KEY                in     PAC_PERSON.PER_KEY1%type default null
  , iv_DISTRIB_LANID              in     PCS.PC_LANG.LANID%type default null
  , iv_ARE_ADDRESS_DISTRIB        in     ASA_RECORD.ARE_ADDRESS1%type default null
  , iv_ARE_POSTCODE_DISTRIB       in     ASA_RECORD.ARE_POSTCODE1%type default null
  , iv_ARE_TOWN_DISTRIB           in     ASA_RECORD.ARE_TOWN1%type default null
  , iv_ARE_STATE_DISTRIB          in     ASA_RECORD.ARE_STATE1%type default null
  , iv_DISTRIB_CNTID              in     PCS.PC_CNTRY.CNTID%type default null
  , iv_ARE_CARE_OF_DET            in     ASA_RECORD.ARE_CARE_OF_DET%type default null
  , iv_ARE_PO_BOX_DET             in     ASA_RECORD.ARE_PO_BOX_DET%type default null
  , in_ARE_PO_BOX_NBR_DET         in     ASA_RECORD.ARE_PO_BOX_NBR_DET%type default null
  , iv_ARE_COUNTY_DET             in     ASA_RECORD.ARE_COUNTY_DET%type default null
  , iv_FIN_CUST_KEY               in     PAC_PERSON.PER_KEY1%type default null
  , iv_FIN_CUST_LANID             in     PCS.PC_LANG.LANID%type default null
  , iv_ARE_ADDRESS_FIN_CUST       in     ASA_RECORD.ARE_ADDRESS1%type default null
  , iv_ARE_POSTCODE_FIN_CUST      in     ASA_RECORD.ARE_POSTCODE1%type default null
  , iv_ARE_TOWN_FIN_CUST          in     ASA_RECORD.ARE_TOWN1%type default null
  , iv_ARE_STATE_FIN_CUST         in     ASA_RECORD.ARE_STATE1%type default null
  , iv_FIN_CUST_CNTID             in     PCS.PC_CNTRY.CNTID%type default null
  , iv_ARE_CARE_OF_CUST           in     ASA_RECORD.ARE_CARE_OF_CUST%type default null
  , iv_ARE_PO_BOX_CUST            in     ASA_RECORD.ARE_PO_BOX_CUST%type default null
  , in_ARE_PO_BOX_NBR_CUST        in     ASA_RECORD.ARE_PO_BOX_NBR_CUST%type default null
  , iv_ARE_COUNTY_CUST            in     ASA_RECORD.ARE_COUNTY_CUST%type default null
  , iv_SUPPLIER_KEY               in     PAC_PERSON.PER_KEY1%type default null
  , iv_SUPPLIER_CURRENCY          in     PCS.PC_CURR.CURRNAME%type default null
  , iv_SUPPLIER_LANID             in     PCS.PC_CNTRY.CNTID%type default null
  , iv_ARE_ADDRESS_SUPPLIER       in     ASA_RECORD.ARE_ADDRESS1%type default null
  , iv_ARE_POSTCODE_SUPPLIER      in     ASA_RECORD.ARE_POSTCODE1%type default null
  , iv_ARE_TOWN_SUPPLIER          in     ASA_RECORD.ARE_TOWN1%type default null
  , iv_ARE_STATE_SUPPLIER         in     ASA_RECORD.ARE_STATE1%type default null
  , iv_SUPPLIER_CNTID             in     PCS.PC_CNTRY.CNTID%type default null
  , iv_ARE_CARE_OF_SUP            in     ASA_RECORD.ARE_CARE_OF_SUP%type default null
  , iv_ARE_PO_BOX_SUP             in     ASA_RECORD.ARE_PO_BOX_SUP%type default null
  , in_ARE_PO_BOX_NBR_SUP         in     ASA_RECORD.ARE_PO_BOX_NBR_SUP%type default null
  , iv_ARE_COUNTY_SUP             in     ASA_RECORD.ARE_COUNTY_SUP%type default null
  , iv_SUPPLIER_MAJOR_REFERENCE   in     GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  , iv_REPAIR_MAJOR_REFERENCE     in     GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  , in_ARE_REPAIR_QTY             in     ASA_RECORD.ARE_REPAIR_QTY%type default 1
  , iv_ARE_GCO_SHORT_DESCR        in     ASA_RECORD.ARE_GCO_SHORT_DESCR%type default null
  , iv_ARE_GCO_LONG_DESCR         in     ASA_RECORD.ARE_GCO_LONG_DESCR%type default null
  , iv_ARE_GCO_FREE_DESCR         in     ASA_RECORD.ARE_GCO_FREE_DESCR%type default null
  , iv_ARE_CHAR1_VALUE            in     ASA_RECORD.ARE_CHAR1_VALUE%type default null
  , iv_ARE_CHAR2_VALUE            in     ASA_RECORD.ARE_CHAR2_VALUE%type default null
  , iv_ARE_CHAR3_VALUE            in     ASA_RECORD.ARE_CHAR3_VALUE%type default null
  , iv_ARE_CHAR4_VALUE            in     ASA_RECORD.ARE_CHAR4_VALUE%type default null
  , iv_ARE_CHAR5_VALUE            in     ASA_RECORD.ARE_CHAR5_VALUE%type default null
  , iv_ARE_CUSTOMER_REF           in     ASA_RECORD.ARE_CUSTOMER_REF%type default null
  , iv_ARE_GOOD_REF_1             in     ASA_RECORD.ARE_GOOD_REF_1%type default null
  , iv_ARE_GOOD_REF_2             in     ASA_RECORD.ARE_GOOD_REF_2%type default null
  , iv_ARE_GOOD_REF_3             in     ASA_RECORD.ARE_GOOD_REF_3%type default null
  , iv_ARE_GOOD_NEW_REF           in     ASA_RECORD.ARE_GOOD_NEW_REF%type default null
  , iv_NEW_MAJOR_REFERENCE        in     GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  , iv_ARE_NEW_CHAR1_VALUE        in     ASA_RECORD.ARE_NEW_CHAR1_VALUE%type default null
  , iv_ARE_NEW_CHAR2_VALUE        in     ASA_RECORD.ARE_NEW_CHAR2_VALUE%type default null
  , iv_ARE_NEW_CHAR3_VALUE        in     ASA_RECORD.ARE_NEW_CHAR3_VALUE%type default null
  , iv_ARE_NEW_CHAR4_VALUE        in     ASA_RECORD.ARE_NEW_CHAR4_VALUE%type default null
  , iv_ARE_NEW_CHAR5_VALUE        in     ASA_RECORD.ARE_NEW_CHAR5_VALUE%type default null
  , iv_DEFECT_LOCATION            in     STM_LOCATION.LOC_DESCRIPTION%type default null
  , iv_DEFECT_STOCK               in     STM_STOCK.STO_DESCRIPTION%type default null
  , iv_ORIGIN_CNTID               in     PCS.PC_CNTRY.CNTID%type default null
  , id_ARE_SALE_DATE              in     ASA_RECORD.ARE_SALE_DATE%type default null
  , iv_ARE_SALE_DATE_TEXT         in     ASA_RECORD.ARE_SALE_DATE_TEXT%type default null
  , id_ARE_DET_SALE_DATE          in     ASA_RECORD.ARE_DET_SALE_DATE%type default null
  , iv_ARE_DET_SALE_DATE_TEXT     in     ASA_RECORD.ARE_DET_SALE_DATE_TEXT%type default null
  , id_ARE_FIN_SALE_DATE          in     ASA_RECORD.ARE_FIN_SALE_DATE%type default null
  , iv_ARE_FIN_SALE_DATE_TEXT     in     ASA_RECORD.ARE_FIN_SALE_DATE_TEXT%type default null
  , id_ARE_BEGIN_GUARANTY_DATE    in     ASA_RECORD.ARE_BEGIN_GUARANTY_DATE%type default null
  , in_ARE_GUARANTY               in     ASA_RECORD.ARE_GUARANTY%type default null
  , iv_C_ASA_GUARANTY_UNIT        in     ASA_RECORD.C_ASA_GUARANTY_UNIT%type default 'D'
  , id_ARE_END_GUARANTY_DATE      in     ASA_RECORD.ARE_END_GUARANTY_DATE%type default null
  , in_ARE_GUARANTY_CODE          in     ASA_RECORD.ARE_GUARANTY_CODE%type default 0
  , in_ARE_OFFERED_CODE           in     ASA_RECORD.ARE_OFFERED_CODE%type default 0
  , in_ARE_GENERATE_BILL          in     ASA_RECORD.ARE_GENERATE_BILL%type default 1
  , id_ARE_REP_BEGIN_GUAR_DATE    in     ASA_RECORD.ARE_REP_BEGIN_GUAR_DATE%type default null
  , in_ARE_REP_GUAR               in     ASA_RECORD.ARE_REP_GUAR%type default null
  , iv_DIC_GARANTY_CODE_ID        in     ASA_RECORD.DIC_GARANTY_CODE_ID%type default null
  , iv_C_ASA_REP_GUAR_UNIT        in     ASA_RECORD.C_ASA_REP_GUAR_UNIT%type default 'D'
  , id_ARE_REP_END_GUAR_DATE      in     ASA_RECORD.ARE_REP_END_GUAR_DATE%type default null
  , iv_C_ASA_DEVIS_CODE           in     ASA_RECORD.C_ASA_DEVIS_CODE%type default null
  , in_ARE_MIN_DEVIS_MB           in     ASA_RECORD.ARE_MIN_DEVIS_MB%type default null
  , in_ARE_MIN_DEVIS_ME           in     ASA_RECORD.ARE_MIN_DEVIS_ME%type default null
  , id_ARE_VAL_DEVIS_DATE         in     ASA_RECORD.ARE_VAL_DEVIS_DATE%type default null
  , in_ARE_PRICE_DEVIS_MB         in     ASA_RECORD.ARE_PRICE_DEVIS_MB%type default null
  , in_ARE_PRICE_DEVIS_ME         in     ASA_RECORD.ARE_PRICE_DEVIS_ME%type default null
  , iv_DEVIS_BILL_MAJOR_REFERENCE in     GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  , iv_BILL_MAJOR_REFERENCE       in     GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  , iv_EXCHANGE_MAJOR_REFERENCE   in     GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  , in_ARE_EXCH_QTY               in     ASA_RECORD.ARE_EXCH_QTY%type default 1
  , iv_ARE_GCO_SHORT_DESCR_EX     in     ASA_RECORD.ARE_GCO_SHORT_DESCR_EX%type default null
  , iv_ARE_GCO_LONG_DESCR_EX      in     ASA_RECORD.ARE_GCO_LONG_DESCR_EX%type default null
  , iv_ARE_GCO_FREE_DESCR_EX      in     ASA_RECORD.ARE_GCO_FREE_DESCR_EX%type default null
  , iv_ARE_EXCH_CHAR1_VALUE       in     ASA_RECORD.ARE_EXCH_CHAR1_VALUE%type default null
  , iv_ARE_EXCH_CHAR2_VALUE       in     ASA_RECORD.ARE_EXCH_CHAR2_VALUE%type default null
  , iv_ARE_EXCH_CHAR3_VALUE       in     ASA_RECORD.ARE_EXCH_CHAR3_VALUE%type default null
  , iv_ARE_EXCH_CHAR4_VALUE       in     ASA_RECORD.ARE_EXCH_CHAR4_VALUE%type default null
  , iv_ARE_EXCH_CHAR5_VALUE       in     ASA_RECORD.ARE_EXCH_CHAR5_VALUE%type default null
  , iv_EXCH_LOCATION              in     STM_LOCATION.LOC_DESCRIPTION%type default null
  , iv_EXCH_STOCK                 in     STM_STOCK.STO_DESCRIPTION%type default null
  , iv_LAST_RECORD_NUMBER         in     ASA_RECORD.ARE_NUMBER%type default null
  , iv_DMT_ORIGIN_NUMBER          in     DOC_DOCUMENT.DMT_NUMBER%type default null
  , iv_POS_ORIGIN_NUMBER          in     DOC_POSITION.POS_NUMBER%type default null
  , iv_GUARANTY_CARD_NUMBER       in     ASA_GUARANTY_CARDS.AGC_NUMBER%type default null
  , id_ARE_DATE_REG_REP           in     ASA_RECORD.ARE_DATE_REG_REP%type default trunc(sysdate)
  , in_ARE_NB_DAYS_WAIT           in     ASA_RECORD.ARE_NB_DAYS_WAIT%type default null
  , in_ARE_NB_DAYS_WAIT_COMP      in     ASA_RECORD.ARE_NB_DAYS_WAIT_COMP%type default null
  , in_ARE_NB_DAYS_WAIT_MAX       in     ASA_RECORD.ARE_NB_DAYS_WAIT_MAX%type default null
  , id_ARE_DATE_START_REP         in     ASA_RECORD.ARE_DATE_START_REP%type default null
  , in_ARE_NB_DAYS                in     ASA_RECORD.ARE_NB_DAYS%type default null
  , id_ARE_DATE_END_REP           in     ASA_RECORD.ARE_DATE_END_REP%type default null
  , in_ARE_NB_DAYS_CTRL           in     ASA_RECORD.ARE_NB_DAYS_CTRL%type default null
  , id_ARE_DATE_END_CTRL          in     ASA_RECORD.ARE_DATE_END_CTRL%type default null
  , in_ARE_NB_DAYS_EXP            in     ASA_RECORD.ARE_NB_DAYS_EXP%type default null
  , id_ARE_DATE_START_EXP         in     ASA_RECORD.ARE_DATE_START_EXP%type default null
  , in_ARE_NB_DAYS_SENDING        in     ASA_RECORD.ARE_NB_DAYS_SENDING%type default null
  , id_ARE_DATE_END_SENDING       in     ASA_RECORD.ARE_DATE_END_SENDING%type default null
  , id_ARE_REQ_DATE_C             in     ASA_RECORD.ARE_REQ_DATE_C%type default null
  , id_ARE_CONF_DATE_C            in     ASA_RECORD.ARE_CONF_DATE_C%type default null
  , id_ARE_UPD_DATE_C             in     ASA_RECORD.ARE_UPD_DATE_C%type default null
  , id_ARE_REQ_DATE_S             in     ASA_RECORD.ARE_REQ_DATE_S%type default null
  , id_ARE_CONF_DATE_S            in     ASA_RECORD.ARE_CONF_DATE_S%type default null
  , id_ARE_UPD_DATE_S             in     ASA_RECORD.ARE_UPD_DATE_S%type default null
  , in_ARE_LPOS_COMP_TASK         in     ASA_RECORD.ARE_LPOS_COMP_TASK%type default 0
  , iv_C_ASA_SELECT_PRICE         in     ASA_RECORD.C_ASA_SELECT_PRICE%type default '1'
  , iv_DMT_ATTRIB_NUMBER          in     DOC_DOCUMENT.DMT_NUMBER%type default null
  , iv_ARE_PIECE                  in     ASA_RECORD.ARE_PIECE%type default null
  , iv_ARE_SET                    in     ASA_RECORD.ARE_SET%type default null
  , iv_ARE_VERSION                in     ASA_RECORD.ARE_VERSION%type default null
  , iv_ARE_CHRONOLOGICAL          in     ASA_RECORD.ARE_CHRONOLOGICAL%type default null
  , iv_ARE_STD_CHAR_1             in     ASA_RECORD.ARE_STD_CHAR_1%type default null
  , iv_ARE_STD_CHAR_2             in     ASA_RECORD.ARE_STD_CHAR_2%type default null
  , iv_ARE_STD_CHAR_3             in     ASA_RECORD.ARE_STD_CHAR_3%type default null
  , iv_ARE_STD_CHAR_4             in     ASA_RECORD.ARE_STD_CHAR_4%type default null
  , iv_ARE_STD_CHAR_5             in     ASA_RECORD.ARE_STD_CHAR_5%type default null
  , iv_THIRD_DELIVERY_KEY         in     PAC_PERSON.PER_KEY1%type default null
  , iv_THIRD_ACI_KEY              in     PAC_PERSON.PER_KEY1%type default null
  , iv_THIRD_TARIFF_KEY           in     PAC_PERSON.PER_KEY1%type default null
  , iv_C_PRIORITY                 in     ASA_RECORD.C_PRIORITY%type default null
  , iv_DIC_COMMUNICATION_TYPE_ID  in     PAC_COMMUNICATION.DIC_COMMUNICATION_TYPE_ID%type default null
  , iv_COM_EXT_NUMBER             in     PAC_COMMUNICATION.COM_EXT_NUMBER%type default null
  , iv_DIC_RECEPTION_MODE_ID      in     ASA_RECORD.DIC_RECEPTION_MODE_ID%type default null
  , iv_ARE_CONTACT1               in     ASA_RECORD.ARE_CONTACT1%type default null
  , iv_ARE_CONTACT2               in     ASA_RECORD.ARE_CONTACT2%type default null
  , iv_ARE_CONTACT3               in     ASA_RECORD.ARE_CONTACT3%type default null
  , iv_ARE_CONTACT_COMMENT        in     ASA_RECORD.ARE_CONTACT_COMMENT%type default null
  , iv_ARE_INTERNAL_REMARK        in     ASA_RECORD.ARE_INTERNAL_REMARK%type default null
  , iv_ARE_CUSTOMER_REMARK        in     ASA_RECORD.ARE_CUSTOMER_REMARK%type default null
  , iv_ARE_ADDITIONAL_ITEMS       in     ASA_RECORD.ARE_ADDITIONAL_ITEMS%type default null
  , in_ARE_CUSTOMS_VALUE          in     ASA_RECORD.ARE_CUSTOMS_VALUE%type default null
  , iv_CUSTOM_CURRENCY            in     PCS.PC_CURR.CURRNAME%type default null
  , iv_ARE_REQ_DATE_TEXT          in     ASA_RECORD.ARE_REQ_DATE_TEXT%type default null
  )
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ASA_ENTITY.gcAsaRecord, ltCRUD_DEF, true);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_NUMBER', iov_ARE_NUMBER);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ASA_REP_TYPE_ID', FWK_I_LIB_ENTITY.getIdfromPk2('ASA_REP_TYPE', 'RET_REP_TYPE', iv_RET_REP_TYPE) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_ASA_REP_TYPE_KIND', iv_C_ASA_REP_TYPE_KIND);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_DATECRE', id_ARE_DATECRE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_RECORD_ID', FWK_I_LIB_ENTITY.getIdfromPk2('DOC_RECORD', 'RCO_TITLE', iv_RCO_TITLE) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_REPRESENTATIVE_ID', FWK_I_LIB_ENTITY.getIdfromPk2('PAC_REPRESENTATIVE', 'REP_DESCR', iv_REP_DESCR) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_FINANCIAL_CURRENCY_ID', ACS_FUNCTION.GetCurrencyId(iv_CURRENCY) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CURR_BASE_PRICE', in_ARE_CURR_BASE_PRICE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CURR_RATE_OF_EXCH', in_ARE_CURR_RATE_OF_EXCH);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_COST_PRICE_S', in_ARE_COST_PRICE_S);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_COST_PRICE_W', in_ARE_COST_PRICE_W);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_COST_PRICE_C', in_ARE_COST_PRICE_C);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_COST_PRICE_T', in_ARE_COST_PRICE_T);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_SALE_PRICE_S', in_ARE_SALE_PRICE_S);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_SALE_PRICE_W', in_ARE_SALE_PRICE_W);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_SALE_PRICE_C', in_ARE_SALE_PRICE_C);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_SALE_PRICE_T_MB', in_ARE_SALE_PRICE_T_MB);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_SALE_PRICE_T_ME', in_ARE_SALE_PRICE_T_ME);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_CUSTOM_PARTNER_ID', PAC_I_LIB_THIRD.GetCustomerIdfromPerKey1(iv_CUSTOMER_KEY) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_ASA_CUST_LANG_ID', FWK_I_LIB_ENTITY.getIdfromPk2('PCS.PC_LANG', 'LANID', iv_CUSTOMER_LANID) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_ADDRESS1', iv_ARE_ADDRESS1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_POSTCODE1', iv_ARE_POSTCODE1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_TOWN1', iv_ARE_TOWN1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_STATE1', iv_ARE_STATE1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_ASA_CNTRY1_ID', FWK_I_LIB_ENTITY.getIdfromPk2('PCS.PC_CNTRY', 'CNTID', iv_CNTID1) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CARE_OF1', iv_ARE_CARE_OF1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_PO_BOX1', iv_ARE_PO_BOX1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_PO_BOX_NBR1', in_ARE_PO_BOX_NBR1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_COUNTY1', iv_ARE_COUNTY1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_ADDRESS2', iv_ARE_ADDRESS2);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_POSTCODE2', iv_ARE_POSTCODE2);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_TOWN2', iv_ARE_TOWN2);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_STATE2', iv_ARE_STATE2);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_ASA_CNTRY2_ID', FWK_I_LIB_ENTITY.getIdfromPk2('PCS.PC_CNTRY', 'CNTID', iv_CNTID2) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CARE_OF2', iv_ARE_CARE_OF2);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_PO_BOX2', iv_ARE_PO_BOX2);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_PO_BOX_NBR2', in_ARE_PO_BOX_NBR2);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_COUNTY2', iv_ARE_COUNTY2);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_ADDRESS3', iv_ARE_ADDRESS3);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_POSTCODE3', iv_ARE_POSTCODE3);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_TOWN3', iv_ARE_TOWN3);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_STATE3', iv_ARE_STATE3);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_ASA_CNTRY3_ID', FWK_I_LIB_ENTITY.getIdfromPk2('PCS.PC_CNTRY', 'CNTID', iv_CNTID3) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CARE_OF3', iv_ARE_CARE_OF3);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_PO_BOX3', iv_ARE_PO_BOX3);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_PO_BOX_NBR3', in_ARE_PO_BOX_NBR3);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_COUNTY3', iv_ARE_COUNTY3);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_ASA_FIN_CUST_ID', PAC_I_LIB_THIRD.GetCustomerIdfromPerKey1(iv_FIN_CUST_KEY) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_ASA_FIN_CUST_LANG_ID', FWK_I_LIB_ENTITY.getIdfromPk2('PCS.PC_LANG', 'LANID', iv_FIN_CUST_LANID) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_ADDRESS_FIN_CUST', iv_ARE_ADDRESS_FIN_CUST);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_POSTCODE_FIN_CUST', iv_ARE_POSTCODE_FIN_CUST);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_TOWN_FIN_CUST', iv_ARE_TOWN_FIN_CUST);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_STATE_FIN_CUST', iv_ARE_STATE_FIN_CUST);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_ASA_FIN_CUST_CNTRY_ID', FWK_I_LIB_ENTITY.getIdfromPk2('PCS.PC_CNTRY', 'CNTID', iv_FIN_CUST_CNTID) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CARE_OF_CUST', iv_ARE_CARE_OF_CUST);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_PO_BOX_CUST', iv_ARE_PO_BOX_CUST);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_PO_BOX_NBR_CUST', in_ARE_PO_BOX_NBR_CUST);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_COUNTY_CUST', iv_ARE_COUNTY_CUST);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_SUPPLIER_PARTNER_ID', PAC_I_LIB_THIRD.GetSupplierIdfromPerKey1(iv_SUPPLIER_KEY) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_ASA_SUP_FIN_CURR_ID', ACS_FUNCTION.GetCurrencyId(iv_SUPPLIER_CURRENCY) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_ASA_SUP_LANG_ID', FWK_I_LIB_ENTITY.getIdfromPk2('PCS.PC_LANG', 'LANID', iv_SUPPLIER_LANID) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_ADDRESS_SUPPLIER', iv_ARE_ADDRESS_SUPPLIER);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_POSTCODE_SUPPLIER', iv_ARE_POSTCODE_SUPPLIER);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_TOWN_SUPPLIER', iv_ARE_TOWN_SUPPLIER);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_STATE_SUPPLIER', iv_ARE_STATE_SUPPLIER);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_ASA_SUPPLIER_CNTRY_ID', FWK_I_LIB_ENTITY.getIdfromPk2('PCS.PC_CNTRY', 'CNTID', iv_SUPPLIER_CNTID) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_FORMAT_CITY_SUPPLIER', iv_SUPPLIER_CNTID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CARE_OF_SUP', iv_ARE_CARE_OF_SUP);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_PO_BOX_SUP', iv_ARE_PO_BOX_SUP);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_PO_BOX_NBR_SUP', in_ARE_PO_BOX_NBR_SUP);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_COUNTY_SUP', iv_ARE_COUNTY_SUP);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF
                                  , 'GCO_SUPPLIER_GOOD_ID'
                                  , FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', iv_SUPPLIER_MAJOR_REFERENCE)
                                   );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF
                                  , 'GCO_ASA_TO_REPAIR_ID'
                                  , FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', iv_REPAIR_MAJOR_REFERENCE)
                                   );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CHAR1_VALUE', iv_ARE_CHAR1_VALUE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CHAR2_VALUE', iv_ARE_CHAR2_VALUE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CHAR3_VALUE', iv_ARE_CHAR3_VALUE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CHAR4_VALUE', iv_ARE_CHAR4_VALUE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CHAR5_VALUE', iv_ARE_CHAR5_VALUE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_PIECE', iv_ARE_PIECE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_SET', iv_ARE_SET);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_VERSION', iv_ARE_VERSION);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CHRONOLOGICAL', iv_ARE_CHRONOLOGICAL);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_STD_CHAR_1', iv_ARE_STD_CHAR_1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_STD_CHAR_2', iv_ARE_STD_CHAR_2);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_STD_CHAR_3', iv_ARE_STD_CHAR_3);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_STD_CHAR_4', iv_ARE_STD_CHAR_4);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_STD_CHAR_5', iv_ARE_STD_CHAR_5);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CUSTOMER_REF', iv_ARE_CUSTOMER_REF);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_GOOD_REF_1', iv_ARE_GOOD_REF_1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_GOOD_REF_2', iv_ARE_GOOD_REF_2);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_GOOD_REF_3', iv_ARE_GOOD_REF_3);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_GOOD_NEW_REF', iv_ARE_GOOD_NEW_REF);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_ASA_DEFECT_LOC_ID', FWK_I_LIB_ENTITY.getIdfromPk2('STM_LOCATION', 'LOC_DESCRIPTION', iv_DEFECT_LOCATION) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_ASA_DEFECT_STK_ID', FWK_I_LIB_ENTITY.getIdfromPk2('STM_STOCK', 'STO_DESCRIPTION', iv_DEFECT_STOCK) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_SALE_DATE', id_ARE_SALE_DATE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_SALE_DATE_TEXT', iv_ARE_SALE_DATE_TEXT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_ORIGIN_CNTRY_ID', FWK_I_LIB_ENTITY.getIdfromPk2('PCS.PC_CNTRY', 'CNTID', iv_ORIGIN_CNTID) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_GUARANTY', in_ARE_GUARANTY);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_ASA_GUARANTY_UNIT', iv_C_ASA_GUARANTY_UNIT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_END_GUARANTY_DATE', id_ARE_END_GUARANTY_DATE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_GUARANTY_CODE', in_ARE_GUARANTY_CODE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_OFFERED_CODE', in_ARE_OFFERED_CODE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_GENERATE_BILL', in_ARE_GENERATE_BILL);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_ASA_DEVIS_CODE', iv_C_ASA_DEVIS_CODE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_MIN_DEVIS_MB', in_ARE_MIN_DEVIS_MB);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_MIN_DEVIS_ME', in_ARE_MIN_DEVIS_ME);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_VAL_DEVIS_DATE', id_ARE_VAL_DEVIS_DATE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_PRICE_DEVIS_MB', in_ARE_PRICE_DEVIS_MB);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_PRICE_DEVIS_ME', in_ARE_PRICE_DEVIS_ME);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF
                                  , 'GCO_DEVIS_BILL_GOOD_ID'
                                  , FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', iv_DEVIS_BILL_MAJOR_REFERENCE)
                                   );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF
                                  , 'GCO_ASA_EXCHANGE_ID'
                                  , FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', iv_EXCHANGE_MAJOR_REFERENCE)
                                   );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_ASA_EXCH_LOC_ID', FWK_I_LIB_ENTITY.getIdfromPk2('STM_LOCATION', 'LOC_DESCRIPTION', iv_EXCH_LOCATION) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'STM_ASA_EXCH_STK_ID', FWK_I_LIB_ENTITY.getIdfromPk2('STM_STOCK', 'STO_DESCRIPTION', iv_EXCH_STOCK) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ASA_LAST_RECORD_ID', FWK_I_LIB_ENTITY.getIdfromPk2('ASA_RECORD', 'ARE_NUMBER', iv_LAST_RECORD_NUMBER) );

    declare
      lPositionId       DOC_POSITION.DOC_POSITION_ID%type;
      lPositionDetailId DOC_POSITION_DETAIL.DOC_POSITION_DETAIL_ID%type;
    begin
      select POS.DOC_POSITION_ID
        into lPositionId
        from DOC_DOCUMENT DMT inner join DOC_POSITION POS on DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
       where POS.POS_NUMBER = iv_POS_ORIGIN_NUMBER
         and DMT.DMT_NUMBER = iv_DMT_ORIGIN_NUMBER;

      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_ORIGIN_POSITION_ID', lPositionId);

      begin
        select DOC_POSITION_DETAIL_ID
          into lPositionDetailId
          from DOC_POSITION_DETAIL
         where DOC_POSITION_ID = lPositionId;

        FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_ORIGIN_POSITION_DETAIL_ID', lPositionDetailId);
      exception
        when too_many_rows then
          null;
      end;
    exception
      when no_data_found then
        null;
    end;

    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_NB_DAYS', in_ARE_NB_DAYS);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_REQ_DATE_C', id_ARE_REQ_DATE_C);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CONF_DATE_C', id_ARE_CONF_DATE_C);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_UPD_DATE_C', id_ARE_UPD_DATE_C);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_REQ_DATE_S', id_ARE_REQ_DATE_S);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CONF_DATE_S', id_ARE_CONF_DATE_S);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_UPD_DATE_S', id_ARE_UPD_DATE_S);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_GCO_SHORT_DESCR', iv_ARE_GCO_SHORT_DESCR);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_GCO_LONG_DESCR', iv_ARE_GCO_LONG_DESCR);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_GCO_FREE_DESCR', iv_ARE_GCO_FREE_DESCR);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_GCO_SHORT_DESCR_EX', iv_ARE_GCO_SHORT_DESCR_EX);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_GCO_LONG_DESCR_EX', iv_ARE_GCO_LONG_DESCR_EX);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_GCO_FREE_DESCR_EX', iv_ARE_GCO_FREE_DESCR_EX);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_SENDING_CONDITION_ID', PAC_I_LIB_THIRD.GetSendingContitionId(iv_SEN_KEY, iv_C_CONDITION_MODE) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_RECALC_SALE_PRICE_2', in_ARE_RECALC_SALE_PRICE_2);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_RECALC_COST_PRICE_2', in_ARE_RECALC_COST_PRICE_2);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_BILL_GOOD_ID', FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', iv_BILL_MAJOR_REFERENCE) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_LPOS_COMP_TASK', in_ARE_LPOS_COMP_TASK);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_REPAIR_QTY', in_ARE_REPAIR_QTY);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_EXCH_QTY', in_ARE_EXCH_QTY);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'GCO_NEW_GOOD_ID', FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', iv_NEW_MAJOR_REFERENCE) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_BEGIN_GUARANTY_DATE', id_ARE_BEGIN_GUARANTY_DATE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF
                                  , 'ASA_GUARANTY_CARDS_ID'
                                  , FWK_I_LIB_ENTITY.getIdfromPk2('ASA_GUARANTY_CARDS', 'AGC_NUMBER', iv_GUARANTY_CARD_NUMBER)
                                   );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_REP_BEGIN_GUAR_DATE', id_ARE_REP_BEGIN_GUAR_DATE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_REP_GUAR', in_ARE_REP_GUAR);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_ASA_REP_GUAR_UNIT', iv_C_ASA_REP_GUAR_UNIT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_REP_END_GUAR_DATE', id_ARE_REP_END_GUAR_DATE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_FIN_SALE_DATE', id_ARE_FIN_SALE_DATE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_TARIFF_ID', iv_DIC_TARIFF_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_MIN_SALE_PRICE_MB', in_ARE_MIN_SALE_PRICE_MB);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_MIN_SALE_PRICE_ME', in_ARE_MIN_SALE_PRICE_ME);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_MAX_SALE_PRICE_MB', in_ARE_MAX_SALE_PRICE_MB);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_MAX_SALE_PRICE_ME', in_ARE_MAX_SALE_PRICE_ME);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_GARANTY_CODE_ID', iv_DIC_GARANTY_CODE_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_TARIFF2_ID', iv_DIC_TARIFF2_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_PAYMENT_CONDITION_ID', FWK_I_LIB_ENTITY.getIdfromPk2('PAC_PAYMENT_CONDITION', 'PCO_DESCR', iv_PCO_DESCR) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_ASA_AGENT_ID', PAC_I_LIB_THIRD.GetPersonIdfromPerKey1(iv_AGENT_KEY) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_ASA_AGENT_LANG_ID', FWK_I_LIB_ENTITY.getIdfromPk2('PCS.PC_LANG', 'LANID', iv_AGENT_LANID) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_ADDRESS_AGENT', iv_ARE_ADDRESS_AGENT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_POSTCODE_AGENT', iv_ARE_POSTCODE_AGENT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_TOWN_AGENT', iv_ARE_TOWN_AGENT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_STATE_AGENT', iv_ARE_STATE_AGENT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_ASA_AGENT_CNTRY_ID', FWK_I_LIB_ENTITY.getIdfromPk2('PCS.PC_CNTRY', 'CNTID', iv_AGENT_CNTID) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CARE_OF_AGENT', iv_ARE_CARE_OF_AGENT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_PO_BOX_AGENT', iv_ARE_PO_BOX_AGENT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_PO_BOX_NBR_AGENT', in_ARE_PO_BOX_NBR_AGENT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_COUNTY_AGENT', iv_ARE_COUNTY_AGENT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_ASA_DISTRIB_ID', PAC_I_LIB_THIRD.GetPersonIdfromPerKey1(iv_DISTRIB_KEY) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_ASA_DISTRIB_LANG_ID', FWK_I_LIB_ENTITY.getIdfromPk2('PCS.PC_LANG', 'LANID', iv_DISTRIB_LANID) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_ADDRESS_DISTRIB', iv_ARE_ADDRESS_DISTRIB);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_POSTCODE_DISTRIB', iv_ARE_POSTCODE_DISTRIB);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_TOWN_DISTRIB', iv_ARE_TOWN_DISTRIB);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_STATE_DISTRIB', iv_ARE_STATE_DISTRIB);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_ASA_DISTRIB_CNTRY_ID', FWK_I_LIB_ENTITY.getIdfromPk2('PCS.PC_CNTRY', 'CNTID', iv_DISTRIB_CNTID) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CARE_OF_DET', iv_ARE_CARE_OF_DET);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_PO_BOX_DET', iv_ARE_PO_BOX_DET);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_PO_BOX_NBR_DET', in_ARE_PO_BOX_NBR_DET);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_COUNTY_DET', iv_ARE_COUNTY_DET);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_DET_SALE_DATE', id_ARE_DET_SALE_DATE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_DET_SALE_DATE_TEXT', iv_ARE_DET_SALE_DATE_TEXT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_FIN_SALE_DATE', id_ARE_FIN_SALE_DATE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_FIN_SALE_DATE_TEXT', iv_ARE_FIN_SALE_DATE_TEXT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_ASA_SELECT_PRICE', iv_C_ASA_SELECT_PRICE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_DATE_REG_REP', id_ARE_DATE_REG_REP);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_NB_DAYS_WAIT', in_ARE_NB_DAYS_WAIT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_NB_DAYS_WAIT_COMP', in_ARE_NB_DAYS_WAIT_COMP);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_NB_DAYS_WAIT_MAX', in_ARE_NB_DAYS_WAIT_MAX);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_DATE_START_REP', id_ARE_DATE_START_REP);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_DATE_END_REP', id_ARE_DATE_END_REP);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_NB_DAYS_CTRL', in_ARE_NB_DAYS_CTRL);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_DATE_END_CTRL', id_ARE_DATE_END_CTRL);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_NB_DAYS_EXP', in_ARE_NB_DAYS_EXP);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_DATE_START_EXP', id_ARE_DATE_START_EXP);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_NB_DAYS_SENDING', in_ARE_NB_DAYS_SENDING);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_DATE_END_SENDING', id_ARE_DATE_END_SENDING);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_TYPE_SUBMISSION_ID', iv_DIC_TYPE_SUBMISSION_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_ATTRIB_DOCUMENT_ID', FWK_I_LIB_ENTITY.getIdfromPk2('DOC_DOCUMENT', 'DMT_NUMBER', iv_DMT_ATTRIB_NUMBER) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_THIRD_DELIVERY_ID', PAC_I_LIB_THIRD.GetThirdIdfromPerKey1(iv_THIRD_DELIVERY_KEY) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_THIRD_ACI_ID', PAC_I_LIB_THIRD.GetThirdIdfromPerKey1(iv_THIRD_ACI_KEY) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_THIRD_TARIFF_ID', PAC_I_LIB_THIRD.GetThirdIdfromPerKey1(iv_THIRD_TARIFF_KEY) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_PRIORITY', iv_C_PRIORITY);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF
                                  , 'PAC_COMMUNICATION_ID'
                                  , PAC_I_LIB_THIRD.GetCommunicationId(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_DEF, 'PAC_CUSTOM_PARTNER_ID')
                                                                     , iv_DIC_COMMUNICATION_TYPE_ID
                                                                     , iv_COM_EXT_NUMBER
                                                                      )
                                   );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DIC_RECEPTION_MODE_ID', iv_DIC_RECEPTION_MODE_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CONTACT1', iv_ARE_CONTACT1);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CONTACT2', iv_ARE_CONTACT2);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CONTACT3', iv_ARE_CONTACT3);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CONTACT_COMMENT', iv_ARE_CONTACT_COMMENT);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_INTERNAL_REMARK', iv_ARE_INTERNAL_REMARK);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CUSTOMER_REMARK', iv_ARE_CUSTOMER_REMARK);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_ADDITIONAL_ITEMS', iv_ARE_ADDITIONAL_ITEMS);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CUSTOMS_VALUE', in_ARE_CUSTOMS_VALUE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_CUSTOM_FIN_CURR_ID', ACS_FUNCTION.GetCurrencyId(iv_CUSTOM_CURRENCY) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_REQ_DATE_TEXT', iv_ARE_REQ_DATE_TEXT);
    -- DML statement
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    iov_ARE_NUMBER  := FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(ltCRUD_DEF, 'ARE_NUMBER');
  end CreateRECORD;

  /**
  * function CreateRECORD
  * Description
  *   Création d'un dossier SAV
  *
  */
  function CreateRECORD(
    iv_RET_REP_TYPE        in ASA_REP_TYPE.RET_REP_TYPE%type
  , iv_ARE_PIECE           in ASA_RECORD.ARE_PIECE%type
  , iv_GOO_MAJOR_REFERENCE in GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , iv_ARE_GUARANTY_CODE   in ASA_RECORD.ARE_GUARANTY_CODE%type
  , iv_ARE_GCO_FREE_DESCR  in ASA_RECORD.ARE_GCO_FREE_DESCR%type
  , iv_PER_KEY1            in PAC_PERSON.PER_KEY1%type
  , iv_LANID               in PCS.PC_LANG.LANID%type
  , iv_ARE_CUSTOMER_REMARK in ASA_RECORD.ARE_CUSTOMER_REMARK%type
  , id_ARE_REQ_DATE_C      in ASA_RECORD.ARE_REQ_DATE_C%type
  , iv_ARE_REQ_DATE_TEXT   in ASA_RECORD.ARE_REQ_DATE_TEXT%type
  )
    return number
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
    lResult    ASA_RECORD.ASA_RECORD_ID%type;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ASA_ENTITY.gcAsaRecord, ltCRUD_DEF, true);
    --ASA_RECORD_ID automatique
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ASA_REP_TYPE_ID', FWK_I_LIB_ENTITY.getIdfromPk2('ASA_REP_TYPE', 'RET_REP_TYPE', iv_RET_REP_TYPE) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PAC_CUSTOM_PARTNER_ID', PAC_I_LIB_THIRD.GetCustomerIdfromPerKey1(iv_PER_KEY1) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_ASA_CUST_LANG_ID', FWK_I_LIB_ENTITY.getIdfromPk2('PCS.PC_LANG', 'LANID', iv_LANID) );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF
                                  , 'GCO_ASA_TO_REPAIR_ID'
                                  , FWK_I_LIB_ENTITY.getIdfromPk2('GCO_GOOD', 'GOO_MAJOR_REFERENCE', iv_GOO_MAJOR_REFERENCE)
                                   );
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_PIECE', iv_ARE_PIECE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_GUARANTY_CODE', iv_ARE_GUARANTY_CODE);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_REQ_DATE_C', id_ARE_REQ_DATE_C);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_GCO_FREE_DESCR', iv_ARE_GCO_FREE_DESCR);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_CUSTOMER_REMARK', iv_ARE_CUSTOMER_REMARK);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ARE_REQ_DATE_TEXT', iv_ARE_REQ_DATE_TEXT);
    -- DML statement
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    lResult  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltCRUD_DEF, 'ASA_RECORD_ID');
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    return lResult;
  end CreateRECORD;

  /**
  * procedure CheckRecordBeforeUpdate
  * Description
  *   Contrôle avant mise à jour d'un dossier SAV au autre maj lié à un dossier SAV
  *
  */
  procedure CheckRecordBeforeUpdate(iv_ARE_NUMBER in ASA_RECORD.ARE_NUMBER%type)
  is
    lnError        integer;
    lcError        varchar2(2000);
    lASA_RECORD_ID ASA_RECORD.ASA_RECORD_ID%type;
    ltCRUD_DEF     FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Rechercher l'ID du dossier SAV
    lASA_RECORD_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'ASA_RECORD', iv_column_name => 'ARE_NUMBER', iv_value => iv_ARE_NUMBER);

    if lASA_RECORD_ID is null then
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.FATAL;
      lcError  := 'ASA_RECORD_ID not defined';
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckRecordBeforeUpdate'
                                         );
    end if;

    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ASA_ENTITY.gcAsaRecord, ltCRUD_DEF);
    FWK_I_MGT_ENTITY.load(ltCRUD_DEF, lASA_RECORD_ID);

    begin
      ASA_I_PRC_RECORD.CheckRecordBeforeUpdate(ltCRUD_DEF);
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.OK;
      lcError  := '';
    exception
      when others then
        lnError  := sqlcode;
        lcError  := sqlerrm;
    end;

    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);

    if lnError <> PCS.PC_E_LIB_STANDARD_ERROR.OK then
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CheckRecordBeforeUpdate'
                                         );
    end if;
  end CheckRecordbeforeUpdate;

  /**
  * procedure FinalizeRecord
  * Description
  *   Finalisation d'un dossier SAV
  *
  */
  procedure FinalizeRecord(iv_ARE_NUMBER in ASA_RECORD.ARE_NUMBER%type)
  is
    lnError        integer;
    lcError        varchar2(2000);
    lASA_RECORD_ID ASA_RECORD.ASA_RECORD_ID%type;
    ltCRUD_DEF     FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Rechercher l'ID du dossier SAV
    lASA_RECORD_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'ASA_RECORD', iv_column_name => 'ARE_NUMBER', iv_value => iv_ARE_NUMBER);

    if lASA_RECORD_ID is null then
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.FATAL;
      lcError  := 'ASA_RECORD_ID not defined';
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'FinalizeRecord'
                                         );
    end if;

    begin
      ASA_I_PRC_RECORD.FinalizeRECORD(lASA_RECORD_ID);
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.OK;
      lcError  := '';
    exception
      when others then
        lnError  := sqlcode;
        lcError  := sqlerrm;
    end;

    if lnError <> PCS.PC_E_LIB_STANDARD_ERROR.OK then
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'FinalizeRecord'
                                         );
    end if;
  end FinalizeRecord;

  /**
  * procedure DeleteRECORD
  * Description
  *   Suppression d'un dossier SAV
  *
  */
  procedure DeleteRECORD(iv_ARE_NUMBER in ASA_RECORD.ARE_NUMBER%type)
  is
    lnError          integer;
    lcError          varchar2(2000);
    lASA_RECORD_ID   ASA_RECORD.ASA_RECORD_ID%type;
    ltCRUD_DEF       FWK_I_TYP_DEFINITION.t_crud_def;
    lDOC_GAUGE_ID    DOC_GAUGE.DOC_GAUGE_ID%type;
    lDoc_position_id Doc_position.Doc_position_id%type;
  begin
    -- Rechercher l'ID du dossier SAV
    lASA_RECORD_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'ASA_RECORD', iv_column_name => 'ARE_NUMBER', iv_value => iv_ARE_NUMBER);
    -- Recherche de l'ID gabarit du dossier
    lDOC_GAUGE_ID   := FWK_I_LIB_ENTITY.getNumberFieldFromPk(iv_entity_name => 'ASA_RECORD', iv_column_name => 'DOC_GAUGE_ID', it_pk_value => lASA_RECORD_ID);

    if lASA_RECORD_ID is null then
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.FATAL;
      lcError  := 'ASA_RECORD_ID not defined';
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'DeleteRECORD'
                                         );
    end if;

    /* Suppression du dossier sav */
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ASA_ENTITY.gcAsaRecord, ltCRUD_DEF);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ASA_RECORD_ID', lASA_RECORD_ID);

    begin
      FWK_I_MGT_ENTITY.DeleteEntity(ltCRUD_DEF);
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.OK;
      lcError  := '';
    exception
      when others then
        lnError  := sqlcode;
        lcError  := sqlerrm;
    end;

    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);

    if lnError <> PCS.PC_E_LIB_STANDARD_ERROR.OK then
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'DeleteRECORD'
                                         );
    end if;


    /* Libération du numéro de dossier sav après suppression*/
    FreeDocumentNumber(lDOC_GAUGE_ID, iv_ARE_NUMBER);
  end DeleteRECORD;

  /**
  * procedure CreateCOM_IMAGE_FILES
  * Description
  *    création d'un lien avec un fichier et un dossier SAV (COM_IMAGE_FILES)
  *
  */
  procedure CreateCOM_IMAGE_FILES(
    iv_ARE_NUMBER   in ASA_RECORD.ARE_NUMBER%type
  , iv_IMF_FILE     in COM_IMAGE_FILES.IMF_FILE%type
  , iv_IMF_PATHFILE in COM_IMAGE_FILES.IMF_PATHFILE%type
  )
  is
    lnRecordId ASA_RECORD.ASA_RECORD_ID%type;
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
    lnError    integer;
    lcError    varchar2(100);
  begin
    -- traitement PK2 -> recherche de l'ID
    begin
      select ASA_RECORD_ID
        into lnRecordId
        from ASA_RECORD
       where ARE_NUMBER = iv_ARE_NUMBER;
    exception
      when no_data_found then
        lnRecordId  := null;
    end;

    if lnRecordId is not null then
      --  Create objet record
      FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComImageFiles, ltCRUD_DEF);
      -- initialize PK2 and mandatory fields with parameters
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'IMF_TABLE', 'ASA_RECORD');
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'IMF_REC_ID', lnRecordId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'IMF_FILE', iv_IMF_FILE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'IMF_PATHFILE', iv_IMF_PATHFILE);

      --BeforeInsert for customization

      -- insert record in DB
      begin
        FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
        lnError  := PCS.PC_E_LIB_STANDARD_ERROR.OK;
        lcError  := '';
      exception
        when others then
          lnError  := sqlcode;
          lcError  := sqlerrm;
      end;

      if lnError = PCS.PC_E_LIB_STANDARD_ERROR.OK then
        --AfterInsert for customization
        --
        --   Check errors
        if FWK_I_MGT_ENTITY_DATA.IsNull(ltCRUD_DEF, 'COM_IMAGE_FILES_ID') then
          lnError  := PCS.PC_E_LIB_STANDARD_ERROR.ERROR;
          lcError  := 'Cannot create record COM_IMAGE_FILES';
        else
          lnError  := PCS.PC_E_LIB_STANDARD_ERROR.OK;
          lcError  := '';
        end if;
      end if;

      -- Delete objet record
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    else
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.FATAL;
      lcError  := 'ASA_RECORD_ID not defined';
    end if;

    if lnError <> PCS.PC_E_LIB_STANDARD_ERROR.OK then
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'InsertLinkedFiles'
                                         );
    end if;
  end CreateCOM_IMAGE_FILES;

  /**
  * procedure CreateRECORD_COMP
  * Description
  *   Création d'un composant dans un dossier SAV
  *
  */
  procedure CreateRECORD_COMP(
    iv_ARE_NUMBER          in     ASA_RECORD.ARE_NUMBER%type
  , iv_GOO_MAJOR_REFERENCE in     GCO_GOOD.GOO_MAJOR_REFERENCE%type
  , ion_ARC_POSITION       in out ASA_RECORD_COMP.ARC_POSITION%type
  , in_ARC_QUANTITY        in     ASA_RECORD_COMP.ARC_QUANTITY%type default null
  , in_ARC_SALE_PRICE_ME   in     ASA_RECORD_COMP.ARC_SALE_PRICE_ME%type default null
  , iv_STO_DESCRIPTION     in     STM_STOCK.STO_DESCRIPTION%type default null
  , iv_LOC_DESCRIPTION     in     STM_LOCATION.LOC_DESCRIPTION%type default null
  , iv_ARC_CHAR1_VALUE     in     ASA_RECORD_COMP.ARC_CHAR1_VALUE%type default null
  , iv_ARC_CHAR2_VALUE     in     ASA_RECORD_COMP.ARC_CHAR2_VALUE%type default null
  , iv_ARC_CHAR3_VALUE     in     ASA_RECORD_COMP.ARC_CHAR3_VALUE%type default null
  , iv_ARC_CHAR4_VALUE     in     ASA_RECORD_COMP.ARC_CHAR4_VALUE%type default null
  , iv_ARC_CHAR5_VALUE     in     ASA_RECORD_COMP.ARC_CHAR5_VALUE%type default null
  , iv_ARC_FREE_CHAR1      in     ASA_RECORD_COMP.ARC_FREE_CHAR1%type default null
  , iv_ARC_FREE_CHAR2      in     ASA_RECORD_COMP.ARC_FREE_CHAR2%type default null
  , iv_ARC_FREE_CHAR3      in     ASA_RECORD_COMP.ARC_FREE_CHAR3%type default null
  , iv_ARC_FREE_CHAR4      in     ASA_RECORD_COMP.ARC_FREE_CHAR4%type default null
  , iv_ARC_FREE_CHAR5      in     ASA_RECORD_COMP.ARC_FREE_CHAR5%type default null
  , in_ARC_FREE_NUM1       in     ASA_RECORD_COMP.ARC_FREE_NUM1%type default null
  , in_ARC_FREE_NUM2       in     ASA_RECORD_COMP.ARC_FREE_NUM2%type default null
  , in_ARC_FREE_NUM3       in     ASA_RECORD_COMP.ARC_FREE_NUM3%type default null
  , in_ARC_FREE_NUM4       in     ASA_RECORD_COMP.ARC_FREE_NUM4%type default null
  , in_ARC_FREE_NUM5       in     ASA_RECORD_COMP.ARC_FREE_NUM5%type default null
  , in_FINALIZE_RECORD     in     number default 1
  )
  is
    lnError           integer;
    lcError           varchar2(2000);
    lASA_RECORD_ID    ASA_RECORD.ASA_RECORD_ID%type;
    lGCO_GOOD_ID      GCO_GOOD.GCO_GOOD_ID%type;
    lSTM_STOCK_ID     STM_STOCK.STM_STOCK_ID%type;
    lSTM_LOCATION_ID  STM_LOCATION.STM_LOCATION_ID%type;
    ltRecordComponent FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Rechercher l'ID du dossier SAV
    lASA_RECORD_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'ASA_RECORD', iv_column_name => 'ARE_NUMBER', iv_value => iv_ARE_NUMBER);

    if iv_GOO_MAJOR_REFERENCE is not null then
      -- Rechercher l'ID du composant
      lGCO_GOOD_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name   => 'GCO_GOOD', iv_column_name => 'GOO_MAJOR_REFERENCE'
                                                   , iv_value         => iv_GOO_MAJOR_REFERENCE);
    end if;

    if    lASA_RECORD_ID is null
       or lGCO_GOOD_ID is null then
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.FATAL;

      if lASA_RECORD_ID is null then
        lcError  := lcError || chr(13) || 'ASA_RECORD_ID not defined';
      end if;

      if lGCO_GOOD_ID is null then
        lcError  := lcError || chr(13) || 'GCO_GOOD_ID not defined';
      end if;

      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CreateRECORD_COMP'
                                         );
    end if;

    if iv_STO_DESCRIPTION is not null then
      -- Rechercher l'ID du stock
      lSTM_STOCK_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'STM_STOCK', iv_column_name => 'STO_DESCRIPTION', iv_value => iv_STO_DESCRIPTION);
    end if;

    if     lSTM_STOCK_ID is not null
       and iv_LOC_DESCRIPTION is not null then
      select STM_LOCATION_ID
        into lSTM_LOCATION_ID
        from STM_LOCATION
       where LOC_DESCRIPTION = iv_LOC_DESCRIPTION
         and STM_STOCK_ID = lSTM_STOCK_ID;
    end if;

    -- Création de l'entité ASA_RECORD_COMP
    FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordComp, ltRecordComponent, true);
    -- Init de l'id du dossier SAV
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ASA_RECORD_ID', lASA_RECORD_ID);

    -- Init du n° de position
    if ion_ARC_POSITION is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_POSITION', ion_ARC_POSITION);
    end if;

    -- Init de l'id du composant
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'GCO_COMPONENT_ID', lGCO_GOOD_ID);

    -- Init de l'id du stock du composant
    if lSTM_STOCK_ID is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'STM_COMP_STOCK_ID', lSTM_STOCK_ID);
    end if;

    -- Init de l'id de la location du stock du composant
    if lSTM_LOCATION_ID is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'STM_COMP_LOCATION_ID', lSTM_LOCATION_ID);
    end if;

    if in_ARC_QUANTITY is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_QUANTITY', in_ARC_QUANTITY);
    end if;

    if in_ARC_SALE_PRICE_ME is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_SALE_PRICE_ME', in_ARC_SALE_PRICE_ME);
    end if;

    if iv_ARC_CHAR1_VALUE is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_CHAR1_VALUE', trim(iv_ARC_CHAR1_VALUE) );
    end if;

    if iv_ARC_CHAR2_VALUE is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_CHAR2_VALUE', trim(iv_ARC_CHAR2_VALUE) );
    end if;

    if iv_ARC_CHAR3_VALUE is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_CHAR3_VALUE', trim(iv_ARC_CHAR3_VALUE) );
    end if;

    if iv_ARC_CHAR4_VALUE is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_CHAR4_VALUE', trim(iv_ARC_CHAR4_VALUE) );
    end if;

    if iv_ARC_CHAR5_VALUE is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_CHAR5_VALUE', trim(iv_ARC_CHAR5_VALUE) );
    end if;

    if iv_ARC_FREE_CHAR1 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_FREE_CHAR1', trim(iv_ARC_FREE_CHAR1) );
    end if;

    if iv_ARC_FREE_CHAR2 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_FREE_CHAR2', trim(iv_ARC_FREE_CHAR2) );
    end if;

    if iv_ARC_FREE_CHAR3 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_FREE_CHAR3', trim(iv_ARC_FREE_CHAR3) );
    end if;

    if iv_ARC_FREE_CHAR4 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_FREE_CHAR4', trim(iv_ARC_FREE_CHAR4) );
    end if;

    if iv_ARC_FREE_CHAR5 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_FREE_CHAR5', trim(iv_ARC_FREE_CHAR5) );
    end if;

    if in_ARC_FREE_NUM1 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_FREE_NUM1', in_ARC_FREE_NUM1);
    end if;

    if in_ARC_FREE_NUM2 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_FREE_NUM2', in_ARC_FREE_NUM2);
    end if;

    if in_ARC_FREE_NUM3 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_FREE_NUM3', in_ARC_FREE_NUM3);
    end if;

    if in_ARC_FREE_NUM4 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_FREE_NUM4', in_ARC_FREE_NUM4);
    end if;

    if in_ARC_FREE_NUM5 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_FREE_NUM5', in_ARC_FREE_NUM5);
    end if;

    -- insert record in DB
    begin
      FWK_I_MGT_ENTITY.InsertEntity(ltRecordComponent);
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.OK;
      lcError  := '';
    exception
      when others then
        lnError  := sqlcode;
        lcError  := sqlerrm;
    end;

    if lnError <> PCS.PC_E_LIB_STANDARD_ERROR.OK then
      FWK_I_MGT_ENTITY.Release(ltRecordComponent);
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CreateRECORD_COMP'
                                         );
    else
      -- Retourner la PK2 de ASA_RECORD_COMP crée
      ion_ARC_POSITION  := FWK_I_MGT_ENTITY_DATA.GetColumnNumber(ltRecordComponent, 'ARC_POSITION');

      if in_FINALIZE_RECORD = 1 then
        -- Finalisation du dossier SAV, recalcul des montants du dossier SAV
        FinalizeRecord(iv_ARE_NUMBER);
      end if;

      FWK_I_MGT_ENTITY.Release(ltRecordComponent);
    end if;
  end CreateRECORD_COMP;

  /**
  * procedure UpdateRECORD_COMP
  * Description
  *   Mise à jour d'un composant dans un dossier SAV relatif au dernier élément du flux ASA_RECORD.ASA_RECORD_EVENTS_ID
  *
  */
  procedure UpdateRECORD_COMP(
    iv_ARE_NUMBER          in ASA_RECORD.ARE_NUMBER%type
  , in_ARC_POSITION        in ASA_RECORD_COMP.ARC_POSITION%type
  , iv_GOO_MAJOR_REFERENCE in GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  , in_ARC_QUANTITY        in ASA_RECORD_COMP.ARC_QUANTITY%type default null
  , in_ARC_SALE_PRICE_ME   in ASA_RECORD_COMP.ARC_SALE_PRICE_ME%type default null
  , iv_STO_DESCRIPTION     in STM_STOCK.STO_DESCRIPTION%type default null
  , iv_LOC_DESCRIPTION     in STM_LOCATION.LOC_DESCRIPTION%type default null
  , iv_ARC_CHAR1_VALUE     in ASA_RECORD_COMP.ARC_CHAR1_VALUE%type default null
  , iv_ARC_CHAR2_VALUE     in ASA_RECORD_COMP.ARC_CHAR2_VALUE%type default null
  , iv_ARC_CHAR3_VALUE     in ASA_RECORD_COMP.ARC_CHAR3_VALUE%type default null
  , iv_ARC_CHAR4_VALUE     in ASA_RECORD_COMP.ARC_CHAR4_VALUE%type default null
  , iv_ARC_CHAR5_VALUE     in ASA_RECORD_COMP.ARC_CHAR5_VALUE%type default null
  , iv_ARC_FREE_CHAR1      in ASA_RECORD_COMP.ARC_FREE_CHAR1%type default null
  , iv_ARC_FREE_CHAR2      in ASA_RECORD_COMP.ARC_FREE_CHAR2%type default null
  , iv_ARC_FREE_CHAR3      in ASA_RECORD_COMP.ARC_FREE_CHAR3%type default null
  , iv_ARC_FREE_CHAR4      in ASA_RECORD_COMP.ARC_FREE_CHAR4%type default null
  , iv_ARC_FREE_CHAR5      in ASA_RECORD_COMP.ARC_FREE_CHAR5%type default null
  , in_ARC_FREE_NUM1       in ASA_RECORD_COMP.ARC_FREE_NUM1%type default null
  , in_ARC_FREE_NUM2       in ASA_RECORD_COMP.ARC_FREE_NUM2%type default null
  , in_ARC_FREE_NUM3       in ASA_RECORD_COMP.ARC_FREE_NUM3%type default null
  , in_ARC_FREE_NUM4       in ASA_RECORD_COMP.ARC_FREE_NUM4%type default null
  , in_ARC_FREE_NUM5       in ASA_RECORD_COMP.ARC_FREE_NUM5%type default null
  , in_FINALIZE_RECORD     in number default 1
  )
  is
    lnError             integer;
    lcError             varchar2(2000);
    lASA_RECORD_COMP_ID ASA_RECORD_COMP.ASA_RECORD_COMP_ID%type;
    lASA_RECORD_ID      ASA_RECORD.ASA_RECORD_ID%type;
    lGCO_GOOD_ID        GCO_GOOD.GCO_GOOD_ID%type;
    lSTM_STOCK_ID       STM_STOCK.STM_STOCK_ID%type;
    lSTM_LOCATION_ID    STM_LOCATION.STM_LOCATION_ID%type;
    ltRecordComponent   FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    select A.ASA_RECORD_COMP_ID
      into lASA_RECORD_COMP_ID
      from ASA_RECORD_COMP A
         , ASA_RECORD B
     where b.ARE_NUMBER = iv_ARE_NUMBER
       and a.ASA_RECORD_ID = b.ASA_RECORD_ID
       and A.ARC_POSITION = in_ARC_POSITION
       and A.ASA_RECORD_EVENTS_ID = B.ASA_RECORD_EVENTS_ID;

    -- Rechercher l'ID du composant du dossier SAV
    if lASA_RECORD_COMP_ID is null then
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => 'ASA_RECORD_COMP record does not exists ARE_NUMBER = ' ||
                                                              iv_ARE_NUMBER ||
                                                              ' ARC_POSITION = ' ||
                                                              in_ARC_POSITION
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'UpdateRECORD_COMP'
                                         );
    end if;

    if iv_GOO_MAJOR_REFERENCE is not null then
      -- Rechercher l'ID du composant
      lGCO_GOOD_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name   => 'GCO_GOOD', iv_column_name => 'GOO_MAJOR_REFERENCE'
                                                   , iv_value         => iv_GOO_MAJOR_REFERENCE);
    end if;

    if iv_STO_DESCRIPTION is not null then
      -- Rechercher l'ID du stock
      lSTM_STOCK_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'STM_STOCK', iv_column_name => 'STO_DESCRIPTION', iv_value => iv_STO_DESCRIPTION);
    end if;

    -- Rechercher l'ID de la location de stock
    if     lSTM_STOCK_ID is not null
       and iv_LOC_DESCRIPTION is not null then
      select STM_LOCATION_ID
        into lSTM_LOCATION_ID
        from STM_LOCATION
       where LOC_DESCRIPTION = iv_LOC_DESCRIPTION
         and STM_STOCK_ID = lSTM_STOCK_ID;
    end if;

    -- Création de l'entité ASA_RECORD_COMP
    FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordComp, ltRecordComponent, true);
    -- Init de l'id du composant du dossier SAV
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ASA_RECORD_COMP_ID', lASA_RECORD_COMP_ID);

    if lGCO_GOOD_ID is not null then
      -- Init de l'id du composant
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'GCO_COMPONENT_ID', lGCO_GOOD_ID);
    end if;

    -- Init de l'id du stock du composant
    if lSTM_STOCK_ID is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'STM_COMP_STOCK_ID', lSTM_STOCK_ID);
    end if;

    -- Init de l'id de la location du stock du composant
    if lSTM_LOCATION_ID is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'STM_COMP_LOCATION_ID', lSTM_LOCATION_ID);
    end if;

    if in_ARC_QUANTITY is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_QUANTITY', in_ARC_QUANTITY);
    end if;

    if in_ARC_SALE_PRICE_ME is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_SALE_PRICE_ME', in_ARC_SALE_PRICE_ME);
    end if;

    if iv_ARC_CHAR1_VALUE is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_CHAR1_VALUE', trim(iv_ARC_CHAR1_VALUE) );
    end if;

    if iv_ARC_CHAR2_VALUE is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_CHAR2_VALUE', trim(iv_ARC_CHAR2_VALUE) );
    end if;

    if iv_ARC_CHAR3_VALUE is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_CHAR3_VALUE', trim(iv_ARC_CHAR3_VALUE) );
    end if;

    if iv_ARC_CHAR4_VALUE is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_CHAR4_VALUE', trim(iv_ARC_CHAR4_VALUE) );
    end if;

    if iv_ARC_CHAR5_VALUE is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_CHAR5_VALUE', trim(iv_ARC_CHAR5_VALUE) );
    end if;

    if iv_ARC_FREE_CHAR1 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_FREE_CHAR1', trim(iv_ARC_FREE_CHAR1) );
    end if;

    if iv_ARC_FREE_CHAR2 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_FREE_CHAR2', trim(iv_ARC_FREE_CHAR2) );
    end if;

    if iv_ARC_FREE_CHAR3 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_FREE_CHAR3', trim(iv_ARC_FREE_CHAR3) );
    end if;

    if iv_ARC_FREE_CHAR4 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_FREE_CHAR4', trim(iv_ARC_FREE_CHAR4) );
    end if;

    if iv_ARC_FREE_CHAR5 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_FREE_CHAR5', trim(iv_ARC_FREE_CHAR5) );
    end if;

    if in_ARC_FREE_NUM1 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_FREE_NUM1', in_ARC_FREE_NUM1);
    end if;

    if in_ARC_FREE_NUM2 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_FREE_NUM2', in_ARC_FREE_NUM2);
    end if;

    if in_ARC_FREE_NUM3 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_FREE_NUM3', in_ARC_FREE_NUM3);
    end if;

    if in_ARC_FREE_NUM4 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_FREE_NUM4', in_ARC_FREE_NUM4);
    end if;

    if in_ARC_FREE_NUM5 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ARC_FREE_NUM5', in_ARC_FREE_NUM5);
    end if;

    -- update record in DB
    begin
      FWK_I_MGT_ENTITY.UpdateEntity(ltRecordComponent);
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.OK;
      lcError  := '';
    exception
      when others then
        lnError  := sqlcode;
        lcError  := sqlerrm;
    end;

    if lnError <> PCS.PC_E_LIB_STANDARD_ERROR.OK then
      FWK_I_MGT_ENTITY.Release(ltRecordComponent);
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'UpdateRECORD_COMP'
                                         );
    else
      -- Finalisation du dossier SAV, recalcul des montants du dossier SAV
      if in_FINALIZE_RECORD = 1 then
        FinalizeRecord(iv_ARE_NUMBER);
      end if;

      FWK_I_MGT_ENTITY.Release(ltRecordComponent);
    end if;
  end UpdateRECORD_COMP;

  /**
  * procedure DeleteRECORD_COMP
  * Description
  *   Suppression d'un composant d'un dossier SAV  qui concerne le flux actif du dossier SAV
  *
  */
  procedure DeleteRECORD_COMP(
    iv_ARE_NUMBER      in ASA_RECORD.ARE_NUMBER%type
  , in_ARC_POSITION    in ASA_RECORD_COMP.ARC_POSITION%type
  , in_FINALIZE_RECORD in number default 1
  )
  is
    lnError              integer;
    lcError              varchar2(2000);
    lnASA_RECORD_COMP_ID number;
    ltRecordComponent    FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    select A.ASA_RECORD_COMP_ID
      into lnASA_RECORD_COMP_ID
      from ASA_RECORD_COMP A
         , ASA_RECORD B
     where b.ARE_NUMBER = iv_ARE_NUMBER
       and a.ASA_RECORD_ID = b.ASA_RECORD_ID
       and A.ARC_POSITION = in_ARC_POSITION
       and A.ASA_RECORD_EVENTS_ID = B.ASA_RECORD_EVENTS_ID;

    -- Rechercher l'ID du composant du dossier SAV
    if lnASA_RECORD_COMP_ID is null then
      fwk_i_mgt_exception.raise_exception(in_error_code    => PCS.PC_E_LIB_STANDARD_ERROR.FATAL
                                        , iv_message       => 'ASA_RECORD_COMP record does not exists ARE_NUMBER = ' ||
                                                              iv_ARE_NUMBER ||
                                                              ' ARC_POSITION = ' ||
                                                              in_ARC_POSITION
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'DeleteRECORD_COMP'
                                         );
    end if;

    -- Suppression du composant correspondant
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ASA_ENTITY.gcAsaRecordComp, ltRecordComponent);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordComponent, 'ASA_RECORD_COMP_ID', lnASA_RECORD_COMP_ID);

    -- delete record in DB
    begin
      FWK_I_MGT_ENTITY.DeleteEntity(ltRecordComponent);
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.OK;
      lcError  := '';
    exception
      when others then
        lnError  := sqlcode;
        lcError  := sqlerrm;
    end;

    FWK_I_MGT_ENTITY.Release(ltRecordComponent);

    if lnError <> PCS.PC_E_LIB_STANDARD_ERROR.OK then
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'DeleteRECORD_COMP'
                                         );
    else
      if in_FINALIZE_RECORD = 1 then
        -- Finalisation du dossier SAV
        -- Recalculer les montants du dossier SAV
        FinalizeRecord(iv_ARE_NUMBER);
      end if;
    end if;
  end DeleteRECORD_COMP;

  /**
  * procedure CreateRECORD_TASK
  * Description
  *   Création d'une opération dans un dossier SAV
  *
  */
  procedure CreateRECORD_TASK(
    iv_ARE_NUMBER          in     ASA_RECORD.ARE_NUMBER%type
  , iv_TAS_REF             in     FAL_TASK.TAS_REF%type default null
  , iv_GOO_MAJOR_REFERENCE in     GCO_GOOD.GOO_MAJOR_REFERENCE%type default null
  , in_RET_SALE_AMOUNT_ME  in     ASA_RECORD_TASK.RET_SALE_AMOUNT_ME%type default null
  , iv_DIC_OPERATOR_ID     in     DIC_OPERATOR.DIC_OPERATOR_ID%type default null
  , in_RET_TIME_USED       in     ASA_RECORD_TASK.RET_TIME_USED%type default null
  , in_RET_FREE_NUM1       in     ASA_RECORD_TASK.RET_FREE_NUM1%type default null
  , in_RET_FREE_NUM2       in     ASA_RECORD_TASK.RET_FREE_NUM2%type default null
  , in_RET_FREE_NUM3       in     ASA_RECORD_TASK.RET_FREE_NUM3%type default null
  , in_RET_FREE_NUM4       in     ASA_RECORD_TASK.RET_FREE_NUM4%type default null
  , in_RET_FREE_NUM5       in     ASA_RECORD_TASK.RET_FREE_NUM5%type default null
  , iv_RET_FREE_CHAR1      in     ASA_RECORD_TASK.RET_FREE_CHAR1%type default null
  , iv_RET_FREE_CHAR2      in     ASA_RECORD_TASK.RET_FREE_CHAR2%type default null
  , iv_RET_FREE_CHAR3      in     ASA_RECORD_TASK.RET_FREE_CHAR3%type default null
  , iv_RET_FREE_CHAR4      in     ASA_RECORD_TASK.RET_FREE_CHAR4%type default null
  , iv_RET_FREE_CHAR5      in     ASA_RECORD_TASK.RET_FREE_CHAR5%type default null
  , in_FINALIZE_RECORD     in     number default 1
  , on_RET_POSITION        out    ASA_RECORD_TASK.RET_POSITION%type
  )
  is
    lnError        integer;
    lcError        varchar2(2000);
    lASA_RECORD_ID ASA_RECORD.ASA_RECORD_ID%type;
    lFAL_TASK_ID   FAL_TASK.FAL_TASK_ID%type;
    lGCO_GOOD_ID   GCO_GOOD.GCO_GOOD_ID%type;
    ltRecordTask   FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Rechercher l'ID du dossier SAV
    lASA_RECORD_ID  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'ASA_RECORD', iv_column_name => 'ARE_NUMBER', iv_value => iv_ARE_NUMBER);
    -- Rechercher l'ID de l'opération de fabrication
    lFAL_TASK_ID    := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'FAL_TASK', iv_column_name => 'TAS_REF', iv_value => iv_TAS_REF);
    -- Rechercher l'ID du produit pour facturation
    lGCO_GOOD_ID    := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name   => 'GCO_GOOD', iv_column_name => 'GOO_MAJOR_REFERENCE'
                                                   , iv_value         => iv_GOO_MAJOR_REFERENCE);
    -- Création de l'entité ASA_RECORD_TASK
    FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordTask, ltRecordTask, true);
    -- Init de l'id du dossier SAV
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'ASA_RECORD_ID', lASA_RECORD_ID);

    if lFAL_TASK_ID is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'FAL_TASK_ID', lFAL_TASK_ID);
    end if;

    if lGCO_GOOD_ID is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'GCO_BILL_GOOD_ID', lGCO_GOOD_ID);
    end if;

    if in_RET_SALE_AMOUNT_ME is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_SALE_AMOUNT_ME', in_RET_SALE_AMOUNT_ME);
    end if;

    if iv_DIC_OPERATOR_ID is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'DIC_OPERATOR_ID', iv_DIC_OPERATOR_ID);
    end if;

    if in_RET_SALE_AMOUNT_ME is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_SALE_AMOUNT', in_RET_SALE_AMOUNT_ME);
    end if;

    if in_RET_TIME_USED is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_TIME_USED', in_RET_TIME_USED);
    end if;

    if in_RET_FREE_NUM1 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_FREE_NUM1', in_RET_FREE_NUM1);
    end if;

    if in_RET_FREE_NUM2 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_FREE_NUM2', in_RET_FREE_NUM2);
    end if;

    if in_RET_FREE_NUM3 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_FREE_NUM3', in_RET_FREE_NUM3);
    end if;

    if in_RET_FREE_NUM4 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_FREE_NUM4', in_RET_FREE_NUM4);
    end if;

    if in_RET_FREE_NUM5 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_FREE_NUM5', in_RET_FREE_NUM5);
    end if;

    if iv_RET_FREE_CHAR1 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_FREE_CHAR1', iv_RET_FREE_CHAR1);
    end if;

    if iv_RET_FREE_CHAR2 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_FREE_CHAR2', iv_RET_FREE_CHAR2);
    end if;

    if iv_RET_FREE_CHAR4 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_FREE_CHAR3', iv_RET_FREE_CHAR3);
    end if;

    if iv_RET_FREE_CHAR4 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_FREE_CHAR4', iv_RET_FREE_CHAR4);
    end if;

    if iv_RET_FREE_CHAR5 is not null then
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_FREE_CHAR5', iv_RET_FREE_CHAR5);
    end if;

    -- insert record in DB
    begin
      FWK_I_MGT_ENTITY.InsertEntity(ltRecordTask);
      lnError  := PCS.PC_E_LIB_STANDARD_ERROR.OK;
      lcError  := '';
    exception
      when others then
        lnError  := sqlcode;
        lcError  := sqlerrm;
    end;

    if lnError <> PCS.PC_E_LIB_STANDARD_ERROR.OK then
      FWK_I_MGT_ENTITY.Release(ltRecordTask);
      fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                        , iv_message       => lcError
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CreateRECORD_TASK'
                                         );
    else
      -- Retourner la PK2 de ASA_RECORD_TASK crée
      on_RET_POSITION  := to_char(FWK_TYP_ASA_ENTITY.gttRecordTask(ltRecordTask.entity_id).RET_POSITION);

      -- Finalisation du dossier SAV, recalcul des montants du dossier SAV
      if in_FINALIZE_RECORD = 1 then
        FinalizeRecord(iv_ARE_NUMBER);
      end if;

      FWK_I_MGT_ENTITY.Release(ltRecordTask);
    end if;
  end CreateRECORD_TASK;

  /**
  * procedure UpdateRECORD_TASK
  * Description
  *   Modification d'une opération dans un dossier SAV
  *
  */
  procedure UpdateRECORD_TASK(
    iv_ARE_NUMBER         in ASA_RECORD.ARE_NUMBER%type
  , in_RET_POSITION       in ASA_RECORD_TASK.RET_POSITION%type
  , in_RET_SALE_AMOUNT_ME in ASA_RECORD_TASK.RET_SALE_AMOUNT_ME%type default null
  , iv_DIC_OPERATOR_ID    in DIC_OPERATOR.DIC_OPERATOR_ID%type default null
  , in_RET_TIME_USED      in ASA_RECORD_TASK.RET_TIME_USED%type default null
  , in_RET_FREE_NUM1      in ASA_RECORD_TASK.RET_FREE_NUM1%type default null
  , in_RET_FREE_NUM2      in ASA_RECORD_TASK.RET_FREE_NUM2%type default null
  , in_RET_FREE_NUM3      in ASA_RECORD_TASK.RET_FREE_NUM3%type default null
  , in_RET_FREE_NUM4      in ASA_RECORD_TASK.RET_FREE_NUM4%type default null
  , in_RET_FREE_NUM5      in ASA_RECORD_TASK.RET_FREE_NUM5%type default null
  , iv_RET_FREE_CHAR1     in ASA_RECORD_TASK.RET_FREE_CHAR1%type default null
  , iv_RET_FREE_CHAR2     in ASA_RECORD_TASK.RET_FREE_CHAR2%type default null
  , iv_RET_FREE_CHAR3     in ASA_RECORD_TASK.RET_FREE_CHAR3%type default null
  , iv_RET_FREE_CHAR4     in ASA_RECORD_TASK.RET_FREE_CHAR4%type default null
  , iv_RET_FREE_CHAR5     in ASA_RECORD_TASK.RET_FREE_CHAR5%type default null
  , in_FINALIZE_RECORD    in number default 1
  )
  is
    lnError      integer;
    lcError      varchar2(2000);
    lTaskID      ASA_RECORD_TASK.ASA_RECORD_TASK_ID%type;
    ltRecordTask FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Rechercher l'id de l'opération à modifier
    select max(RET.ASA_RECORD_TASK_ID)
      into lTaskID
      from ASA_RECORD_TASK RET
         , ASA_RECORD are
     where RET.ASA_RECORD_ID = are.ASA_RECORD_ID
       and are.ARE_NUMBER = iv_ARE_NUMBER
       and RET.RET_POSITION = in_RET_POSITION
       and are.ASA_RECORD_EVENTS_ID = RET.ASA_RECORD_EVENTS_ID;

    if lTaskID is not null then
      -- Création de l'entité ASA_RECORD_TASK
      FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordTask, ltRecordTask);
      -- Init de l'id de l'opération à modifier
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'ASA_RECORD_TASK_ID', lTaskID);

      if in_RET_SALE_AMOUNT_ME is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_SALE_AMOUNT_ME', in_RET_SALE_AMOUNT_ME);
      end if;

      if iv_DIC_OPERATOR_ID is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'DIC_OPERATOR_ID', iv_DIC_OPERATOR_ID);
      end if;

      if in_RET_SALE_AMOUNT_ME is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_SALE_AMOUNT', in_RET_SALE_AMOUNT_ME);
      end if;

      if in_RET_TIME_USED is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_TIME_USED', in_RET_TIME_USED);
      end if;

      if in_RET_FREE_NUM1 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_FREE_NUM1', in_RET_FREE_NUM1);
      end if;

      if in_RET_FREE_NUM2 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_FREE_NUM2', in_RET_FREE_NUM2);
      end if;

      if in_RET_FREE_NUM3 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_FREE_NUM3', in_RET_FREE_NUM3);
      end if;

      if in_RET_FREE_NUM4 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_FREE_NUM4', in_RET_FREE_NUM4);
      end if;

      if in_RET_FREE_NUM5 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_FREE_NUM5', in_RET_FREE_NUM5);
      end if;

      if iv_RET_FREE_CHAR1 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_FREE_CHAR1', iv_RET_FREE_CHAR1);
      end if;

      if iv_RET_FREE_CHAR2 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_FREE_CHAR2', iv_RET_FREE_CHAR2);
      end if;

      if iv_RET_FREE_CHAR3 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_FREE_CHAR3', iv_RET_FREE_CHAR3);
      end if;

      if iv_RET_FREE_CHAR4 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_FREE_CHAR4', iv_RET_FREE_CHAR4);
      end if;

      if iv_RET_FREE_CHAR5 is not null then
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'RET_FREE_CHAR5', iv_RET_FREE_CHAR5);
      end if;

      -- update record in DB
      begin
        FWK_I_MGT_ENTITY.UpdateEntity(ltRecordTask);
        lnError  := PCS.PC_E_LIB_STANDARD_ERROR.OK;
        lcError  := '';
      exception
        when others then
          lnError  := sqlcode;
          lcError  := sqlerrm;
      end;

      if lnError <> PCS.PC_E_LIB_STANDARD_ERROR.OK then
        FWK_I_MGT_ENTITY.Release(ltRecordTask);
        fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                          , iv_message       => lcError
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdateRECORD_TASK'
                                           );
      else
        -- Finalisation du dossier SAV, recalcul des montants du dossier SAV
        if in_FINALIZE_RECORD = 1 then
          FinalizeRecord(iv_ARE_NUMBER);
        end if;

        FWK_I_MGT_ENTITY.Release(ltRecordTask);
      end if;
    end if;
  end UpdateRECORD_TASK;

  /**
  * procedure DeleteRECORD_TASK
  * Description
  *   Effacement d'une opération dans un dossier SAV
  *
  */
  procedure DeleteRECORD_TASK(
    iv_ARE_NUMBER      in ASA_RECORD.ARE_NUMBER%type
  , in_RET_POSITION    in ASA_RECORD_TASK.RET_POSITION%type
  , in_FINALIZE_RECORD in number default 1
  )
  is
    lnError      integer;
    lcError      varchar2(2000);
    lTaskID      ASA_RECORD_TASK.ASA_RECORD_TASK_ID%type;
    ltRecordTask FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Rechercher l'id de l'opération à effacer
    select max(RET.ASA_RECORD_TASK_ID)
      into lTaskID
      from ASA_RECORD_TASK RET
         , ASA_RECORD are
     where RET.ASA_RECORD_ID = are.ASA_RECORD_ID
       and are.ARE_NUMBER = iv_ARE_NUMBER
       and RET.RET_POSITION = in_RET_POSITION
       and are.ASA_RECORD_EVENTS_ID = RET.ASA_RECORD_EVENTS_ID;

    if lTaskID is not null then
      -- Création de l'entité ASA_RECORD_TASK
      FWK_I_MGT_ENTITY.new(FWK_TYP_ASA_ENTITY.gcAsaRecordTask, ltRecordTask);
      -- Init de l'id de l'opération à effacer
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltRecordTask, 'ASA_RECORD_TASK_ID', lTaskID);

      -- delete record in DB
      begin
        FWK_I_MGT_ENTITY.DeleteEntity(ltRecordTask);
        lnError  := PCS.PC_E_LIB_STANDARD_ERROR.OK;
        lcError  := '';
      exception
        when others then
          lnError  := sqlcode;
          lcError  := sqlerrm;
      end;

      if lnError <> PCS.PC_E_LIB_STANDARD_ERROR.OK then
        FWK_I_MGT_ENTITY.Release(ltRecordTask);
        fwk_i_mgt_exception.raise_exception(in_error_code    => lnError
                                          , iv_message       => lcError
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeleteRECORD_TASK'
                                           );
      else
        -- Finalisation du dossier SAV, recalcul des montants du dossier SAV
        if in_FINALIZE_RECORD = 1 then
          FinalizeRecord(iv_ARE_NUMBER);
        end if;

        FWK_I_MGT_ENTITY.Release(ltRecordTask);
      end if;
    end if;
  end DeleteRECORD_TASK;

  /**
  * procedure CreateRECORD_EVENTS
  * Description
  *   Création d'un événement de flux dans un dossier SAV
  *
  */
  procedure CreateRECORD_EVENTS(
    iv_ARE_NUMBER        in     ASA_RECORD.ARE_NUMBER%type
  , iv_NEW_STATUS        in     ASA_RECORD_EVENTS.C_ASA_REP_STATUS%type
  , in_GENERATE_OF       in     number default 1
  , in_LAUNCH_OF         in     number default null
  , id_PLAN_BEGIN_DATE   in     date default null
  , in_GENERATE_DOCUMENT in     number default 1
  , id_DATE_DOCUMENT     in     date default null
  , id_DATE_VALUE        in     date default null
  , id_DATE_DELIVERY     in     date default null
  , iv_GAU_DESCRIBE      in     DOC_GAUGE.GAU_DESCRIBE%type default null
  , ov_EVENTS_SEQ        out    varchar2
  )
  is
    lAsaRecordId ASA_RECORD.ASA_RECORD_ID%type;
    lvEventsSeq  varchar2(10);
  begin
    -- traitement PK2 -> recherche de l'ID
    lAsaRecordId   := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'ASA_RECORD', iv_column_name => 'ARE_NUMBER', iv_value => iv_ARE_NUMBER);
    ASA_I_PRC_RECORD_EVENTS.CreateRecordEvents(iAsaRecordId        => lAsaRecordId
                                             , iNewStatus          => iv_NEW_STATUS
                                             , iGenerateOF         => in_GENERATE_OF
                                             , iLaunchOF           => in_LAUNCH_OF
                                             , iPlanBeginDate      => id_PLAN_BEGIN_DATE
                                             , iGenerateDocument   => in_GENERATE_DOCUMENT
                                             , iDateDocument       => id_DATE_DOCUMENT
                                             , iDateValue          => id_DATE_VALUE
                                             , iDateDelivery       => id_DATE_DELIVERY
                                             , iGauDescribe        => iv_GAU_DESCRIBE
                                             , oEventsSeq          => lvEventsSeq
                                              );
    -- Retourner la PK2 de ASA_RECORD_EVENTS crée
    ov_EVENTS_SEQ  := lvEventsSeq;
  end CreateRECORD_EVENTS;

  /**
  * procedure AcceptEstimate
  * Description
  *   Accepter/Refuser des composants et des opérations
  *   dans le cadre d'un devis
  *
  */
  procedure AcceptEstimate(
    iv_ARE_NUMBER        in ASA_RECORD.ARE_NUMBER%type
  , in_ACCEPT            in number
  , iv_DIC_ASA_OPTION_ID in DIC_ASA_OPTION.DIC_ASA_OPTION_ID%type default null
  , in_ARC_POSITION      in ASA_RECORD_COMP.ARC_POSITION%type default null
  , in_RET_POSITION      in ASA_RECORD_TASK.RET_POSITION%type default null
  )
  is
    lAsaRecordId ASA_RECORD.ASA_RECORD_ID%type;
    lComponentId ASA_RECORD_COMP.ASA_RECORD_COMP_ID%type;
    lTaskId      ASA_RECORD_TASK.ASA_RECORD_TASK_ID%type;
  begin
    if iv_DIC_ASA_OPTION_ID is not null then
      -- Rechercher l'id du dossier SAV
      lAsaRecordId  := FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name => 'ASA_RECORD', iv_column_name => 'ARE_NUMBER', iv_value => iv_ARE_NUMBER);
      --Acceptation d'une option
      ASA_I_PRC_RECORD.AcceptEstimateOption(lAsaRecordId, iv_DIC_ASA_OPTION_ID, in_ACCEPT);
    end if;

    if in_ARC_POSITION is not null then
      -- Rechercher l'id de l'opération à modifier
      select max(REC.ASA_RECORD_COMP_ID)
        into lComponentId
        from ASA_RECORD_COMP REC
           , ASA_RECORD are
       where REC.ASA_RECORD_ID = are.ASA_RECORD_ID
         and are.ARE_NUMBER = iv_ARE_NUMBER
         and REC.ARC_POSITION = in_ARC_POSITION
         and are.ASA_RECORD_EVENTS_ID = REC.ASA_RECORD_EVENTS_ID;

      -- Acceptation d'un composant
      ASA_I_PRC_RECORD_COMP.AcceptEstimateComponent(lComponentId, in_ACCEPT);
    end if;

    if in_RET_POSITION is not null then
      -- Rechercher l'id de l'opération à modifier
      select max(RET.ASA_RECORD_TASK_ID)
        into lTaskId
        from ASA_RECORD_TASK RET
           , ASA_RECORD are
       where RET.ASA_RECORD_ID = are.ASA_RECORD_ID
         and are.ARE_NUMBER = iv_ARE_NUMBER
         and RET.RET_POSITION = in_RET_POSITION
         and are.ASA_RECORD_EVENTS_ID = RET.ASA_RECORD_EVENTS_ID;

      -- Acceptation d'une opération
      ASA_I_PRC_RECORD_TASK.AcceptEstimateTask(lTaskId, in_ACCEPT);
    end if;
  end AcceptEstimate;

  /**
  * procedure FreeDocumentNumber
  * Description
  *   Liberer un numéro de dossier SAV
  */
  procedure FreeDocumentNumber(ivDOC_GAUGE_ID DOC_GAUGE.DOC_GAUGE_ID%type, iv_ARE_NUMBER in ASA_RECORD.ARE_NUMBER%type)
  is
    ltCRUD_DEF              FWK_I_TYP_DEFINITION.t_crud_def;
    lDOC_GAUGE_NUMBERING_ID DOC_GAUGE.DOC_GAUGE_NUMBERING_ID%type;
    lGAN_FREE_NUMBER        DOC_GAUGE_NUMBERING.GAN_FREE_NUMBER%type;
    lDOF_NUMBER             DOC_FREE_NUMBER.DOF_NUMBER%type;
    lnError                 integer;
    lcError                 varchar2(2000);
  begin
    --Recherche des informations concernant la numérotation utilisée
    lDOC_GAUGE_NUMBERING_ID  :=
                FWK_I_LIB_ENTITY.getNumberFieldFromPk(iv_entity_name   => 'DOC_GAUGE', iv_column_name => 'DOC_GAUGE_NUMBERING_ID'
                                                    , it_pk_value      => ivDOC_GAUGE_ID);

    if lDOC_GAUGE_NUMBERING_ID > 0 then
      --Récupération du N° libre
      lGAN_FREE_NUMBER  :=
        FWK_I_LIB_ENTITY.getNumberFieldFromPk(iv_entity_name   => 'DOC_GAUGE_NUMBERING'
                                            , iv_column_name   => 'GAN_FREE_NUMBER'
                                            , it_pk_value      => lDOC_GAUGE_NUMBERING_ID
                                             );

      if lGAN_FREE_NUMBER = 1 then
        -- Suppression du numéro libre utilisé
        if FWK_I_LIB_ENTITY.RecordsExists(iv_entity_name => 'DOC_FREE_NUMBER', iv_column_name => 'DOF_NUMBER', iv_value => iv_ARE_NUMBER) then
          FWK_I_MGT_ENTITY.new(FWK_I_TYP_DOC_ENTITY.gcDocFreeNumber, ltCRUD_DEF);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF
                                        , 'DOC_FREE_NUMBER_ID'
                                        , FWK_I_LIB_ENTITY.getIdfromPk2(iv_entity_name   => 'DOC_FREE_NUMBER'
                                                                      , iv_column_name   => 'DOF_NUMBER'
                                                                      , iv_value         => iv_ARE_NUMBER
                                                                       )
                                         );
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOF_SESSION_ID', 0);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOF_CREATING', 0);
          FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
          FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
        else
          FWK_I_MGT_ENTITY.new(FWK_I_TYP_DOC_ENTITY.gcDocFreeNumber, ltCRUD_DEF);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_FREE_NUMBER_ID', INIT_ID_SEQ.nextval);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOC_GAUGE_NUMBERING_ID', lDOC_GAUGE_NUMBERING_ID);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOF_NUMBER', iv_ARE_NUMBER);
          FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'DOF_CREATING', 0);

          begin
            FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
            lnError  := PCS.PC_E_LIB_STANDARD_ERROR.OK;
            lcError  := '';
          exception
            when others then
              lnError  := sqlcode;
              lcError  := sqlerrm;
          end;

          FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
        end if;
      end if;
    end if;
  end FreeDocumentNumber;
end ASA_E_PRC_RECORD;
