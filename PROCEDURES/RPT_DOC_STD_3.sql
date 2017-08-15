--------------------------------------------------------
--  DDL for Procedure RPT_DOC_STD_3
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_STD_3" (
  arefcursor        in out CRYSTAL_CURSOR_TYPES.dualcursortyp
, parameter_0       in     DOC_DOCUMENT.DMT_NUMBER%type
, proccompany_owner in     PCS.PC_SCRIP.SCRDBOWNER%type
, proccompany_name  in     PCS.PC_COMP.COM_NAME%type
, report_name       in     varchar2
, pc_comp_id        in     PCS.PC_COMP.PC_COMP_ID%type
, pc_conli_id       in     PCS.PC_CONLI.PC_CONLI_ID%type
)
is
/**
* Description - Used in report DOC_STD_3_RPT

* Stored procedure used in report DOC_STD_3 (Standard document)
* @created   John Schaer 05 JUN 2007
* @lastupdate VHA 14.05.2014
* @param      parameter_0    Numéro de document    (DMT_NUMBER)
*/
  vpc_lang_id               PCS.PC_LANG.PC_LANG_ID%type       := null;
  vpc_comp_id               PCS.PC_COMP.PC_COMP_ID%type;
  vpc_conli_id              PCS.PC_CONLI.PC_CONLI_ID%type;
  vlanid                    PCS.PC_LANG.LANID%type            := null;
  vcom_logo_large           PCS.PC_COMP.COM_LOGO_LARGE%type   := null;
  vcom_logo_small           PCS.PC_COMP.COM_LOGO_SMALL%type   := null;
  vcom_vatno                PCS.PC_COMP.COM_VATNO%type        := null;
  vcom_phone                PCS.PC_COMP.COM_PHONE%type        := null;
  vcom_fax                  PCS.PC_COMP.COM_FAX%type          := null;
  vcom_web                  PCS.PC_COMP.COM_TELEX%type        := null;
  vcom_email                PCS.PC_COMP.COM_EMAIl%type        := null;
  vcom_descr                PCS.PC_COMP.COM_DESCR%type        := null;
  vcom_socialname           PCS.PC_COMP.COM_SOCIALNAME%type   := null;
  vcom_ide                  PCS.PC_COMP.COM_IDE%type          := null;
  vcom_adr                  varchar2(4000)                    := null;
  vdiscount_surcharge_title varchar2(2)                       := null;
  vform_name                varchar2(4000)                    := null;
begin
  pcs.PC_I_LIB_SESSION.setcompanyid(pc_comp_id);
  pcs.PC_I_LIB_SESSION.setconliid(pc_conli_id);
  vpc_comp_id   := pcs.PC_I_LIB_SESSION.getcompanyid;
  vpc_conli_id  := pcs.PC_I_LIB_SESSION.getconliid;

  if (proccompany_name is not null) then
    select COM.COM_LOGO_LARGE
         , COM.COM_LOGO_SMALL
         , COM.COM_VATNO
         , COM.COM_DESCR
         , COM.COM_ADR || chr(13) || COM.COM_ZIP || ' - ' || COM.COM_CITY
         , COM.COM_PHONE
         , COM.COM_FAX
         , COM.COM_TELEX
         , COM.COM_EMAIL
         , COM.COM_SOCIALNAME
         , COM.COM_IDE
      into VCOM_LOGO_LARGE
         , VCOM_LOGO_SMALL
         , VCOM_VATNO
         , VCOM_DESCR
         , VCOM_ADR
         , VCOM_PHONE
         , VCOM_FAX
         , VCOM_WEB
         , VCOM_EMAIL
         , VCOM_SOCIALNAME
         , VCOM_IDE
      from PCS.PC_COMP COM
     where COM.COM_NAME = proccompany_name;
  end if;

  begin
    if (parameter_0 is not null) then
      select DMT.PC_LANG_ID
           , LAN.LANID
        into vpc_lang_id
           , VLANID
        from DOC_DOCUMENT DMT
           , PCS.PC_LANG LAN
       where DMT.PC_LANG_ID = LAN.PC_LANG_ID
         and DMT.DMT_NUMBER = parameter_0;
    end if;
  exception
    when no_data_found then
      vpc_lang_id  := '';
      vlanid       := '';
  end;

  case(substr(substr(report_name, instr(report_name, '\', -1) + 1), 1, length(substr(report_name, instr(report_name, '\', -1) + 1) ) - 4) )
    when 'DOC_STD_3' then
      vform_name  := 'SD';
    when 'DOC_STD_3_IMAGE' then
      vform_name  := 'SI';
    when 'DOC_STD_3_BL' then
      vform_name  := 'SB';
    when 'DOC_ASA_3' then
      vform_name  := 'AS';
    when 'DOC_STD_STOCK_3' then
      vform_name  := 'ST';
    when 'DOC_STD_STOCK_IMAGE_3' then
      vform_name  := 'SM';
    when 'DOC_STD_3_TTC' then
      vform_name  := 'TT';
    when 'DOC_STD_PICKING_3' then
      vform_name  := 'PK';
    when 'DOC_STD_MP_USH_3' then
      vform_name  := 'MP';
    else
      vform_name  := 'SD';
  end case;

  begin
    if (     (proccompany_name is not null)
        and (parameter_0 is not null) ) then
      case vform_name
        when 'PK' then
          select LAN.PC_LANG_ID
               , LAN.LANID
            into vpc_lang_id
               , vlanid
            from PCS.PC_COMP COM
               , PCS.PC_LANG LAN
           where COM.PC_LANG_ID = LAN.PC_LANG_ID
             and COM.COM_NAME = proccompany_name;
        else
          select DMT.PC_LANG_ID
               , LAN.LANID
            into vpc_lang_id
               , vlanid
            from DOC_DOCUMENT DMT
               , PCS.PC_LANG LAN
           where DMT.PC_LANG_ID = LAN.PC_LANG_ID
             and DMT.DMT_NUMBER = parameter_0;
      end case;
    end if;
  exception
    when no_data_found then
      vpc_lang_id  := '';
      vlanid       := '';
  end;

  /*This filed is used to control the title display for discount and surcharge
    If the document's position has no discount or surcharge, then return '0';
    If it only has discounet, then return '1';
    If it only has surcharge, then return '02;
    If it has discount and surcharge, then return '12'.
  */
  begin
    select   decode(max(PCH.PTC_DISCOUNT_ID), null, decode(max(PCH.PTC_CHARGE_ID), null, '0', '2'), decode(max(PCH.PTC_CHARGE_ID), null, '1', '12') )
        into vdiscount_surcharge_title
        from DOC_DOCUMENT DMT
           , DOC_POSITION POS
           , DOC_POSITION_CHARGE PCH
           , PTC_DISCOUNT DNT
           , PTC_CHARGE CRG
       where DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and POS.DOC_POSITION_ID = PCH.DOC_POSITION_ID
         and DNT.PTC_DISCOUNT_ID(+) = PCH.PTC_DISCOUNT_ID
         and CRG.PTC_CHARGE_ID(+) = PCH.PTC_CHARGE_ID
         and DMT.DMT_NUMBER = PARAMETER_0
    group by DMT.DMT_NUMBER;
  exception
    when no_data_found then
      vdiscount_surcharge_title  := '';
  end;

  open arefcursor for
    select   vform_name FORM_NAME
           , vcom_phone COM_PHONE
           , vcom_fax COM_FAX
           , vcom_web COM_WEB
           , vcom_email COM_EMAIL
           , vcom_socialname COM_SOCIALNAME
           , DMT.DOC_DOCUMENT_ID
           , DMT.DOC_GAUGE_ID
           , DMT.DMT_NUMBER DOCNUMBER
           , DETAIL.DMT_NUMBER
           , DMT.DMT_DATE_DOCUMENT
           , DMT.DMT_DATE_VALUE
           , DMT.DMT_DATE_FALLING_DUE
           , DMT.DMT_DATE_DELIVERY
           , DMT.C_DOCUMENT_STATUS
           , DMT.DMT_PARTNER_NUMBER
           , DMT.DMT_PARTNER_REFERENCE
           , DMT.DMT_DATE_PARTNER_DOCUMENT
           , DMT.DMT_REFERENCE
           , DMT.DMT_TITLE_TEXT
           , DMT.DMT_HEADING_TEXT
           , DMT.DMT_DOCUMENT_TEXT
           , DMT.DIC_DOC_FREE_1_ID
           , DMT.DIC_DOC_FREE_2_ID
           , DMT.DIC_DOC_FREE_3_ID
           , DMT.DIC_TYPE_SUBMISSION_ID
           , DMT.DIC_POS_FREE_TABLE_1_ID DOC_DIC_POS_FREE_TABLE_1_ID
           , DMT.DIC_POS_FREE_TABLE_2_ID DOC_DIC_POS_FREE_TABLE_2_ID
           , DMT.DIC_POS_FREE_TABLE_3_ID DOC_DIC_POS_FREE_TABLE_3_ID
           , DMT.DMT_DECIMAL_1
           , DMT.DMT_DECIMAL_2
           , DMT.DMT_DECIMAL_3
           , DMT.DMT_TEXT_1
           , DMT.DMT_TEXT_2
           , DMT.DMT_TEXT_3
           , DMT.DMT_DATE_1
           , DMT.DMT_DATE_2
           , DMT.DMT_DATE_3
           , DMT.DIC_GAUGE_FREE_CODE_1_ID
           , DMT.DIC_GAUGE_FREE_CODE_2_ID
           , DMT.DIC_GAUGE_FREE_CODE_3_ID
           , DMT.DMT_GAU_FREE_NUMBER1
           , DMT.DMT_GAU_FREE_NUMBER2
           , DMT.DMT_GAU_FREE_DATE1
           , DMT.DMT_GAU_FREE_DATE2
           , DMT.DMT_GAU_FREE_TEXT_LONG
           , DMT.DMT_GAU_FREE_TEXT_SHORT
           , DMT.DMT_GAU_FREE_BOOL1
           , DMT.DMT_GAU_FREE_BOOL2
           , DMT.DIC_TARIFF_ID
           , DMT.C_INCOTERMS
           , DMT.DMT_INCOTERMS_PLACE
           , REP.PAC_REPRESENTATIVE_ID
           , REP.REP_DESCR
           , REC.DIC_ACCOUNTABLE_GROUP_ID
           , REC.RCO_TITLE
           , REC.RCO_DESCRIPTION
           , DMT.PAC_THIRD_ID
           , THI.DIC_THIRD_ACTIVITY_ID
           , THI.DIC_THIRD_AREA_ID
           , THI.THI_NO_INTRA
           , THI.THI_NO_TVA
           , THI.THI_NO_SIREN
           , THI.THI_NO_SIRET
           , THI.THI_NO_FORMAT
           , CUS.C_DELIVERY_TYP
           , CUS.CUS_SUPPLIER_NUMBER
           , CUS.CUS_FREE_ZONE1
           , CUS.CUS_FREE_ZONE2
           , CUS.CUS_FREE_ZONE3
           , CUS.CUS_FREE_ZONE4
           , CUS.CUS_FREE_ZONE5
           , CUS.DIC_STATISTIC_1_ID
           , CUS.DIC_STATISTIC_2_ID
           , CUS.DIC_STATISTIC_3_ID
           , CUS.DIC_STATISTIC_4_ID
           , CUS.DIC_STATISTIC_5_ID
           , CUS.DIC_TYPE_PARTNER_ID
           , SUP.CRE_CUSTOMER_NUMBER
           , SUP.CRE_FREE_ZONE1
           , SUP.CRE_FREE_ZONE2
           , SUP.CRE_FREE_ZONE3
           , SUP.CRE_FREE_ZONE4
           , SUP.CRE_FREE_ZONE5
           , SUP.DIC_STATISTIC_F1_ID
           , SUP.DIC_STATISTIC_F2_ID
           , SUP.DIC_STATISTIC_F3_ID
           , SUP.DIC_STATISTIC_F4_ID
           , SUP.DIC_STATISTIC_F5_ID
           , SUP.DIC_TYPE_PARTNER_F_ID
           , PSC.PAC_SENDING_CONDITION_ID
           , PSC.PAC_ADDRESS_ID SENDING_ADDRESS_ID
           , PER_SEN.PER_NAME SEN_PER_NAME
           , PER_SEN.PER_FORENAME SEN_PER_FORENAME
           , PER_SEN.PER_ACTIVITY SEN_PER_ACTIVITY
           , PER_SEN.PER_COMMENT SEN_PER_COMMENT
           , PER_SEN.PER_KEY1 SEN_PER_KEY1
           , PER_SEN.PER_KEY2 SEN_PER_KEY2
           , ADR_SEN.ADD_ADDRESS1 SEN_ADD_ADDRESS1
           , ADR_SEN.ADD_FORMAT SEN_ADD_FORMAT
           , APM.ACS_PAYMENT_METHOD_ID
           , ACCC.ACC_NUMBER CUSTOMER_ACCOUNT
           , ACCS.ACC_NUMBER SUPPLIER_ACCOUNT
           , vpc_lang_id pc_lang_id
           , PMT.PAC_PAYMENT_CONDITION_ID
           , PMT.PCO_DESCR
           , PMT.PC_APPLTXT_ID PMT_PC_APPLTXT_ID
           , AFC.ACS_FINANCIAL_CURRENCY_ID
           , CUR.CURRENCY
           , CUR.CURRNAME
           , vlanid lanid
           , DMT.PAC_ADDRESS_ID ADDRESS_ID
           , nvl(DMT.DMT_NAME1, PER.PER_NAME) PER_NAME
           , nvl(DMT.DMT_FORENAME1, PER.PER_FORENAME) PER_FORENAME
           , nvl(DMT.DMT_ACTIVITY1, PER.PER_ACTIVITY) PER_ACTIVITY
           , PER.PER_COMMENT
           , PER.PER_KEY1
           , PER.PER_KEY2
           , DMT.DMT_ADDRESS1
           , DMT.DMT_FORMAT_CITY1
           , DMT.DMT_TOWN1
           , CNT.CNTID
           , CNT.CNTNAME
           , CNT.DIC_PC_CNTRY_GRP_ID
           , CNT.CNT_CE_CODE
           , CNT.CNT_CE_MEMBER
           , DMT.PAC_PAC_ADDRESS_ID ADDRESS2_ID
           , nvl(DMT.DMT_NAME2, PER2.PER_NAME) PER2_NAME
           , nvl(DMT.DMT_FORENAME2, PER2.PER_FORENAME) PER2_FORENAME
           , nvl(DMT.DMT_ACTIVITY2, PER2.PER_ACTIVITY) PER2_ACTIVITY
           , PER2.PER_COMMENT PER2_COMMENT
           , PER2.PER_KEY1 PER2_KEY1
           , PER2.PER_KEY2 PER2_KEY2
           , DMT.DMT_ADDRESS2
           , DMT.DMT_FORMAT_CITY2
           , DMT.DMT_TOWN2
           , CNT2.CNTID CNTID2
           , CNT2.CNTNAME CNTNAME2
           , CNT2.DIC_PC_CNTRY_GRP_ID DIC_PC_CNTRY_GRP_ID2
           , CNT2.CNT_CE_CODE CNT_CE_CODE2
           , CNT2.CNT_CE_MEMBER CNT_CE_MEMBER2
           , DMT.PAC2_PAC_ADDRESS_ID ADDRESS3_ID
           , nvl(DMT.DMT_NAME3, PER3.PER_NAME) PER3_NAME
           , nvl(DMT.DMT_FORENAME3, PER3.PER_FORENAME) PER3_FORENAME
           , nvl(DMT.DMT_ACTIVITY3, PER3.PER_ACTIVITY) PER3_ACTIVITY
           , PER3.PER_COMMENT PER3_COMMENT
           , PER3.PER_KEY1 PER3_KEY1
           , PER3.PER_KEY2 PER3_KEY2
           , DMT.DMT_ADDRESS3
           , DMT.DMT_FORMAT_CITY3
           , DMT.DMT_TOWN3
           , CNT3.CNTID CNTID3
           , CNT3.CNTNAME CNTNAME3
           , CNT3.DIC_PC_CNTRY_GRP_ID DIC_PC_CNTRY_GRP_ID3
           , CNT3.CNT_CE_CODE CNT_CE_CODE3
           , CNT3.CNT_CE_MEMBER CNT_CE_MEMBER3
           , GAU.C_GAUGE_TYPE
           , GST.C_GAUGE_TITLE
           , GST.GAS_FINANCIAL_CHARGE
           , GAU.C_ADMIN_DOMAIN
           , GAU.DIC_GAUGE_TYPE_DOC_ID
           , DFD.DIC_DOC_FREE_TABLE_1_ID
           , DFD.DIC_DOC_FREE_TABLE_2_ID
           , DFD.DIC_DOC_FREE_TABLE_3_ID
           , DFD.DIC_DOC_FREE_TABLE_4_ID
           , DFD.DIC_DOC_FREE_TABLE_5_ID
           , DFD.FRD_ALPHA_SHORT_1
           , DFD.FRD_ALPHA_SHORT_2
           , DFD.FRD_ALPHA_SHORT_3
           , DFD.FRD_ALPHA_SHORT_4
           , DFD.FRD_ALPHA_SHORT_5
           , DFD.FRD_ALPHA_LONG_1
           , DFD.FRD_ALPHA_LONG_2
           , DFD.FRD_ALPHA_LONG_3
           , DFD.FRD_ALPHA_LONG_4
           , DFD.FRD_ALPHA_LONG_5
           , DFD.FRD_INTEGER_1
           , DFD.FRD_INTEGER_2
           , DFD.FRD_INTEGER_3
           , DFD.FRD_INTEGER_4
           , DFD.FRD_INTEGER_5
           , DFD.FRD_DECIMAL_1
           , DFD.FRD_DECIMAL_2
           , DFD.FRD_DECIMAL_3
           , DFD.FRD_DECIMAL_4
           , DFD.FRD_DECIMAL_5
           , DFD.FRD_BOOLEAN_1
           , DFD.FRD_BOOLEAN_2
           , DFD.FRD_BOOLEAN_3
           , DFD.FRD_BOOLEAN_4
           , DFD.FRD_BOOLEAN_5
           , FOO.DOC_FOOT_ID
           , FOO.DOC_GAUGE_SIGNATORY_ID
           , 'DOC' || to_char(DGS.DOC_GAUGE_SIGNATORY_ID) || '.BMP' DGS_FILE_NAME1
           , DGS.GAG_NAME
           , DGS.GAG_FUNCTION
           , FOO.DOC_DOC_GAUGE_SIGNATORY_ID
           , 'DOC' || to_char(DGS2.DOC_GAUGE_SIGNATORY_ID) || '.BMP' DGS_FILE_NAME2
           , DGS2.GAG_NAME GAG2_NAME
           , DGS2.GAG_FUNCTION GAG2_FUNCTION
           , FOO.FOO_FOOT_TEXT
           , FOO.FOO_FOOT_TEXT2
           , FOO.FOO_FOOT_TEXT3
           , FOO.FOO_FOOT_TEXT4
           , FOO.FOO_FOOT_TEXT5
           , FOO.FOO_DOCUMENT_TOTAL_AMOUNT
           , FOO.FOO_GOOD_TOTAL_AMOUNT
           , FOO.FOO_TOTAL_VAT_AMOUNT
           , FOO.FOO_CHARGE_TOTAL_AMOUNT
           , FOO.FOO_DISCOUNT_TOTAL_AMOUNT
           , FOO.FOO_COST_TOTAL_AMOUNT
           , FOO.FOO_GOOD_TOT_AMOUNT_EXCL
           , FOO.FOO_CHARG_TOT_AMOUNT_EXCL
           , FOO.FOO_DISC_TOT_AMOUNT_EXCL
           , FOO.FOO_COST_TOT_AMOUNT_EXCL
           , FOO.FOO_TOTAL_NET_WEIGHT
           , FOO.FOO_TOTAL_GROSS_WEIGHT
           , FOO.FOO_TOTAL_BASIS_QUANTITY
           , FOO.FOO_TOTAL_INTERM_QUANTITY
           , FOO.FOO_TOTAL_FINAL_QUANTITY
           , FOO.C_BVR_GENERATION_METHOD
           , FOO.FOO_GENERATE_BVR_NUMBER
           , FOO.FOO_REF_BVR_NUMBER
           , FOO.FOO_DOCUMENT_TOT_AMOUNT_B
           , FOO.FOO_DOCUMENT_TOT_AMOUNT_E
           , FOO.FOO_PAID_AMOUNT
           , FOO.FOO_RETURN_AMOUNT
           , FOO.FOO_PACKAGING
           , FOO.FOO_MARKING
           , FOO.FOO_MEASURE
           , FOO.DIC_TYPE_DOC_CUSTOM_ID
           , FOO.C_DIRECTION_NUMBER
           , FOO.FOO_TOT_VAT_AMOUNT_V
           , FOO.FOO_RECEIVED_AMOUNT
           , FOO.FOO_PAID_BALANCED_AMOUNT
           , FOO.FOO_PARCEL_QTY
           , GOO.GCO_GOOD_ID
           , GOO.GOO_MAJOR_REFERENCE
           , GOO.GOO_SECONDARY_REFERENCE
           , GOO.GOO_NUMBER_OF_DECIMAL GOOD_NUMBER_OF_DECIMAL
           , case GAU.C_ADMIN_DOMAIN
               when '1' then GCO_FUNCTIONS.GetCDADecimal(POS.GCO_GOOD_ID, 'PURCHASE', THI.PAC_THIRD_ID)
               when '2' then GCO_FUNCTIONS.GetCDADecimal(POS.GCO_GOOD_ID, 'SALE', THI.PAC_THIRD_ID)
               else GCO_FUNCTIONS.GetCDADecimal(POS.GCO_GOOD_ID, ' ', THI.PAC_THIRD_ID)
             end GOO_NUMBER_OF_DECIMAL
           , GOO.DIC_GOOD_LINE_ID
           , GOO.DIC_GOOD_FAMILY_ID
           , GOO.DIC_GOOD_MODEL_ID
           , GOO.DIC_GOOD_GROUP_ID
           , PDT.PDT_STOCK_MANAGEMENT
           , DGP.C_GAUGE_SHOW_DELAY
           , DGP.GAP_POS_DELAY
           , vdiscount_surcharge_title DISCOUNT_SURCHARGE_TITLE
           , TVA.ACC_NUMBER TVA_ACC_NUMBER
           , REC_POS.RCO_TITLE POS_RCO_TITLE
           , REC_POS.DIC_ACCOUNTABLE_GROUP_ID POS_DIC_ACCOUNTABLE_GROUP_ID
           , REC_POS.RCO_DESCRIPTION POS_RCO_DESCRIPTION
           , REP_POS.PAC_REPRESENTATIVE_ID POS_PAC_REPRESENTATIVE_ID
           , REP_POS.REP_DESCR POS_REP_DESCR
           , GCE.CUS_CUSTONS_POSITION
           , GCE.CUS_KEY_TARIFF
           , GCE.CUS_LICENCE_NUMBER
           , GCE.CUS_RATE_FOR_VALUE
           , GCE.CUS_TRANSPORT_INFORMATION
           , GCE.DIC_REPAYMENT_CODE_ID
           , GCE.DIC_SUBJUGATED_LICENCE_ID
           , CNT_CUSTOMS.CNTID CNTID_CUSTOMS
           , CNT_CUSTOMS.CNTNAME CNTNAME_CUSTOMS
           , CNT_CUSTOMS.DIC_PC_CNTRY_GRP_ID DIC_PC_CNTRY_GRP_ID_CUSTOMS
           , CNT_CUSTOMS.CNT_CE_CODE CNT_CE_CODE_CUSTOMS
           , CNT_CUSTOMS.CNT_CE_MEMBER CNT_CE_MEMBER_CUSTOMS
           , CNT_ORIGIN.CNTID CNTID_ORIGIN
           , CNT_ORIGIN.CNTNAME CNTNAME_ORIGIN
           , CNT_ORIGIN.DIC_PC_CNTRY_GRP_ID DIC_PC_CNTRY_GRP_ID_ORIGIN
           , CNT_ORIGIN.CNT_CE_CODE CNT_CE_CODE_ORIGIN
           , CNT_ORIGIN.CNT_CE_MEMBER CNT_CE_MEMBER_ORIGIN
           , GFD.DATA_UNIT_PRICE_SALE
           , GFD.DIC_FREE_TABLE_1_ID
           , GFD.DIC_FREE_TABLE_2_ID
           , GFD.DIC_FREE_TABLE_3_ID
           , GFD.DIC_FREE_TABLE_4_ID
           , GFD.DIC_FREE_TABLE_5_ID
           , POS.DOC_POSITION_ID
           , POS.POS_NUMBER
           , POS.C_DOC_POS_STATUS
           , POS.C_GAUGE_TYPE_POS
           , POS.POS_REFERENCE
           , POS.POS_SHORT_DESCRIPTION
           , POS.POS_LONG_DESCRIPTION
           , POS.POS_FREE_DESCRIPTION
           , POS.POS_BODY_TEXT
           , POS.ASA_RECORD_ID
           , POS.ASA_RECORD_TASK_ID
           , POS.ASA_RECORD_COMP_ID
           , POS.POS_DISCOUNT_AMOUNT
           , POS.POS_CHARGE_AMOUNT
           , POS.POS_VAT_AMOUNT
           , POS.POS_VAT_BASE_AMOUNT
           , POS.POS_GROSS_UNIT_VALUE
           , POS.POS_GROSS_UNIT_VALUE_SU
           , POS.POS_NET_UNIT_VALUE
           , POS.POS_NET_UNIT_VALUE_INCL
           , POS.POS_REF_UNIT_VALUE
           , POS.POS_GROSS_VALUE
           , POS.POS_NET_VALUE_EXCL
           , POS.POS_NET_VALUE_INCL
           , POS.POS_BASIS_QUANTITY
           , POS.POS_BALANCE_QUANTITY
           , POS.POS_INTERMEDIATE_QUANTITY
           , POS.POS_FINAL_QUANTITY
           , POS.POS_RATE_FACTOR
           , POS.POS_NET_WEIGHT
           , POS.POS_GROSS_WEIGHT
           , POS.DIC_UNIT_OF_MEASURE_ID
           , POS.POS_NOM_TEXT
           , POS.POS_UNIT_COST_PRICE
           , POS.POS_EAN_CODE
           , POS.POS_EAN_UCC14_CODE
           , POS.POS_HIBC_PRIMARY_CODE
           , POS.DIC_POS_FREE_TABLE_1_ID
           , POS.DIC_POS_FREE_TABLE_2_ID
           , POS.DIC_POS_FREE_TABLE_3_ID
           , POS.POS_DECIMAL_1
           , POS.POS_DECIMAL_2
           , POS.POS_DECIMAL_3
           , POS.POS_TEXT_1
           , POS.POS_TEXT_2
           , POS.POS_TEXT_3
           , POS.POS_DATE_1
           , POS.POS_DATE_2
           , POS.POS_DATE_3
           , POS.POS_DISCOUNT_UNIT_VALUE
           , POS.POS_DISCOUNT_RATE
           , POS.POS_VALUE_QUANTITY
           , POS.POS_INCLUDE_TAX_TARIFF
           , POS.POS_GROSS_UNIT_VALUE_INCL
           , POS.POS_GROSS_UNIT_VALUE_INCL_SU
           , POS.POS_GROSS_VALUE_INCL
           , POS.POS_BALANCE_QTY_VALUE
           , POS.POS_UTIL_COEFF
           , POS.POS_GROSS_UNIT_VALUE2
           , POS.DIC_DIC_UNIT_OF_MEASURE_ID
           , POS.POS_CONVERT_FACTOR2
           , POS.POS_VAT_AMOUNT_V
           , POS.POS_NET_TARIFF
           , POS.POS_SPECIAL_TARIFF
           , POS.POS_FLAT_RATE
           , POS.POS_BASIS_QUANTITY_SU
           , POS.POS_INTERMEDIATE_QUANTITY_SU
           , POS.POS_FINAL_QUANTITY_SU
           , POS.C_POS_DELIVERY_TYP
           , POS.POS_BALANCED
           , POS.POS_TARIFF_SET
           , POS.CML_EVENTS_ID
           , POS.DIC_IMP_FREE1_ID POS_DIC_IMP_FREE1_ID
           , POS.DIC_IMP_FREE2_ID POS_DIC_IMP_FREE2_ID
           , POS.DIC_IMP_FREE3_ID POS_DIC_IMP_FREE3_ID
           , POS.DIC_IMP_FREE4_ID POS_DIC_IMP_FREE4_ID
           , POS.DIC_IMP_FREE5_ID POS_DIC_IMP_FREE5_ID
           , DETAIL.DOC_POSITION_DETAIL_ID
           , DETAIL.PERE_DOC_POSITION_DETAIL_ID
           , DETAIL.PERE_DMT_NUMBER
           , DETAIL.PERE_DMT_DATE_DOCUMENT
           , DETAIL.PERE_C_GAUGE_TITLE
           , DETAIL.PERE_GAU_DESCRIBE
           , DETAIL.PERE_GAD_DESCRIBE
           , DETAIL.PERE_DMT_PARTNER_NUMBER
           , DETAIL.PERE_DMT_PARTNTER_REFERENCE
           , DETAIL.PERE_DATE_PARTNER_DOCUMENT
           , DETAIL.G_PERE_DOC_POSITION_DETAIL_ID
           , DETAIL.G_PERE_DMT_NUMBER
           , DETAIL.G_PERE_DMT_DATE_DOCUMENT
           , DETAIL.G_PERE_C_GAUGE_TITLE
           , DETAIL.G_PERE_GAU_DESCRIBE
           , DETAIL.G_PERE_GAD_DESCRIBE
           , DETAIL.G_PERE_DMT_PARTNER_NUMBER
           , DETAIL.G_PERE_DMT_PARTNTER_REFERENCE
           , DETAIL.G_PERE_DATE_PARTNER_DOCUMENT
           , DETAIL.STM_LOCATION_ID
           , DETAIL.DIC_IMP_FREE1_ID PDE_DIC_IMP_FREE1_ID
           , DETAIL.DIC_IMP_FREE2_ID PDE_DIC_IMP_FREE2_ID
           , DETAIL.DIC_IMP_FREE3_ID PDE_DIC_IMP_FREE3_ID
           , DETAIL.DIC_IMP_FREE4_ID PDE_DIC_IMP_FREE4_ID
           , DETAIL.DIC_IMP_FREE5_ID PDE_DIC_IMP_FREE5_ID
           , DETAIL.DIC_PDE_FREE_TABLE_1_ID
           , DETAIL.DIC_PDE_FREE_TABLE_2_ID
           , DETAIL.DIC_PDE_FREE_TABLE_3_ID
           , DETAIL.PDE_TEXT_1
           , DETAIL.PDE_TEXT_2
           , DETAIL.PDE_TEXT_3
           , DETAIL.PDE_DECIMAL_1
           , DETAIL.PDE_DECIMAL_2
           , DETAIL.PDE_DECIMAL_3
           , DETAIL.PDE_DATE_1
           , DETAIL.PDE_DATE_2
           , DETAIL.PDE_DATE_3
           , LOC.LOC_DESCRIPTION
           , STM.STO_DESCRIPTION
           , DETAIL.STM_STM_LOCATION_ID
           , LOC_LOC.LOC_DESCRIPTION LOC_LOC_DESCRIPTION
           , STM_STM.STO_DESCRIPTION STO_STO_DESCRIPTION
           , DETAIL.DIC_DELAY_UPDATE_TYPE_ID
           , DETAIL.PDE_DELAY_UPDATE_TEXT
           , DETAIL.GCO1_CHARACTERIZATION_ID
           , DETAIL.GCO2_CHARACTERIZATION_ID
           , DETAIL.GCO3_CHARACTERIZATION_ID
           , DETAIL.GCO4_CHARACTERIZATION_ID
           , DETAIL.GCO5_CHARACTERIZATION_ID
           , substr(GCO_FUNCTIONS.GetCharacDescr(DETAIL.GCO1_CHARACTERIZATION_ID, vpc_lang_id), 1, 30) GCO1_CHARAC_DESCR
           , substr(GCO_FUNCTIONS.GetCharacDescr(DETAIL.GCO2_CHARACTERIZATION_ID, vpc_lang_id), 1, 30) GCO2_CHARAC_DESCR
           , substr(GCO_FUNCTIONS.GetCharacDescr(DETAIL.GCO3_CHARACTERIZATION_ID, vpc_lang_id), 1, 30) GCO3_CHARAC_DESCR
           , substr(GCO_FUNCTIONS.GetCharacDescr(DETAIL.GCO4_CHARACTERIZATION_ID, vpc_lang_id), 1, 30) GCO4_CHARAC_DESCR
           , substr(GCO_FUNCTIONS.GetCharacDescr(DETAIL.GCO5_CHARACTERIZATION_ID, vpc_lang_id), 1, 30) GCO5_CHARAC_DESCR
           , decode(GCO_FUNCTIONS.GetCharacType(DETAIL.GCO1_CHARACTERIZATION_ID)
                  , 2, (select distinct GCO_DESC_LANGUAGE.DLA_DESCRIPTION
                                   from GCO_CHARACTERIZATION
                                      , GCO_CHARACTERISTIC_ELEMENT
                                      , GCO_DESC_LANGUAGE
                                  where GCO_CHARACTERISTIC_ELEMENT.GCO_CHARACTERIZATION_ID = GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID
                                    and GCO_CHARACTERISTIC_ELEMENT.GCO_CHARACTERISTIC_ELEMENT_ID = GCO_DESC_LANGUAGE.GCO_CHARACTERISTIC_ELEMENT_ID
                                    and GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID = DETAIL.GCO1_CHARACTERIZATION_ID
                                    and GCO_CHARACTERISTIC_ELEMENT.CHE_VALUE = DETAIL.PDE_CHARACTERIZATION_VALUE_1
                                    and GCO_DESC_LANGUAGE.PC_LANG_ID = vpc_lang_id)
                  , DETAIL.PDE_CHARACTERIZATION_VALUE_1
                   ) PDE_CHARACTERIZATION_VALUE_1
           , decode(GCO_FUNCTIONS.GetCharacType(DETAIL.GCO2_CHARACTERIZATION_ID)
                  , 2, (select distinct GCO_DESC_LANGUAGE.DLA_DESCRIPTION
                                   from GCO_CHARACTERIZATION
                                      , GCO_CHARACTERISTIC_ELEMENT
                                      , GCO_DESC_LANGUAGE
                                  where GCO_CHARACTERISTIC_ELEMENT.GCO_CHARACTERIZATION_ID = GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID
                                    and GCO_CHARACTERISTIC_ELEMENT.GCO_CHARACTERISTIC_ELEMENT_ID = GCO_DESC_LANGUAGE.GCO_CHARACTERISTIC_ELEMENT_ID
                                    and GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID = DETAIL.GCO2_CHARACTERIZATION_ID
                                    and GCO_CHARACTERISTIC_ELEMENT.CHE_VALUE = DETAIL.PDE_CHARACTERIZATION_VALUE_2
                                    and GCO_DESC_LANGUAGE.PC_LANG_ID = vpc_lang_id)
                  , DETAIL.PDE_CHARACTERIZATION_VALUE_2
                   ) PDE_CHARACTERIZATION_VALUE_2
           , decode(gco_functions.GetCharacType(DETAIL.GCO3_CHARACTERIZATION_ID)
                  , 2, (select distinct GCO_DESC_LANGUAGE.DLA_DESCRIPTION
                                   from GCO_CHARACTERIZATION
                                      , GCO_CHARACTERISTIC_ELEMENT
                                      , GCO_DESC_LANGUAGE
                                  where GCO_CHARACTERISTIC_ELEMENT.GCO_CHARACTERIZATION_ID = GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID
                                    and GCO_CHARACTERISTIC_ELEMENT.GCO_CHARACTERISTIC_ELEMENT_ID = GCO_DESC_LANGUAGE.GCO_CHARACTERISTIC_ELEMENT_ID
                                    and GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID = DETAIL.GCO3_CHARACTERIZATION_ID
                                    and GCO_CHARACTERISTIC_ELEMENT.CHE_VALUE = DETAIL.PDE_CHARACTERIZATION_VALUE_3
                                    and GCO_DESC_LANGUAGE.PC_LANG_ID = vpc_lang_id)
                  , DETAIL.PDE_CHARACTERIZATION_VALUE_3
                   ) PDE_CHARACTERIZATION_VALUE_3
           , decode(gco_functions.GetCharacType(DETAIL.GCO4_CHARACTERIZATION_ID)
                  , 2, (select distinct GCO_DESC_LANGUAGE.DLA_DESCRIPTION
                                   from GCO_CHARACTERIZATION
                                      , GCO_CHARACTERISTIC_ELEMENT
                                      , GCO_DESC_LANGUAGE
                                  where GCO_CHARACTERISTIC_ELEMENT.GCO_CHARACTERIZATION_ID = GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID
                                    and GCO_CHARACTERISTIC_ELEMENT.GCO_CHARACTERISTIC_ELEMENT_ID = GCO_DESC_LANGUAGE.GCO_CHARACTERISTIC_ELEMENT_ID
                                    and GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID = DETAIL.GCO4_CHARACTERIZATION_ID
                                    and GCO_CHARACTERISTIC_ELEMENT.CHE_VALUE = DETAIL.PDE_CHARACTERIZATION_VALUE_4
                                    and GCO_DESC_LANGUAGE.PC_LANG_ID = vpc_lang_id)
                  , DETAIL.PDE_CHARACTERIZATION_VALUE_4
                   ) PDE_CHARACTERIZATION_VALUE_4
           , decode(gco_functions.GetCharacType(DETAIL.GCO5_CHARACTERIZATION_ID)
                  , 2, (select distinct GCO_DESC_LANGUAGE.DLA_DESCRIPTION
                                   from GCO_CHARACTERIZATION
                                      , GCO_CHARACTERISTIC_ELEMENT
                                      , GCO_DESC_LANGUAGE
                                  where GCO_CHARACTERISTIC_ELEMENT.GCO_CHARACTERIZATION_ID = GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID
                                    and GCO_CHARACTERISTIC_ELEMENT.GCO_CHARACTERISTIC_ELEMENT_ID = GCO_DESC_LANGUAGE.GCO_CHARACTERISTIC_ELEMENT_ID
                                    and GCO_CHARACTERIZATION.GCO_CHARACTERIZATION_ID = DETAIL.GCO5_CHARACTERIZATION_ID
                                    and GCO_CHARACTERISTIC_ELEMENT.CHE_VALUE = DETAIL.PDE_CHARACTERIZATION_VALUE_5
                                    and GCO_DESC_LANGUAGE.PC_LANG_ID = vpc_lang_id)
                  , DETAIL.PDE_CHARACTERIZATION_VALUE_5
                   ) PDE_CHARACTERIZATION_VALUE_5
           , DETAIL.PDE_PIECE
           , DETAIL.PDE_SET
           , DETAIL.PDE_VERSION
           , DETAIL.PDE_CHRONOLOGICAL
           , DETAIL.PDE_STD_CHAR_1
           , DETAIL.PDE_STD_CHAR_2
           , DETAIL.PDE_STD_CHAR_3
           , DETAIL.PDE_STD_CHAR_4
           , DETAIL.PDE_STD_CHAR_5
           , DETAIL.PDE_BASIS_DELAY
           , DETAIL.PDE_BASIS_DELAY_M
           , DETAIL.PDE_BASIS_DELAY_W
           , DETAIL.PDE_BASIS_QUANTITY
           , DETAIL.PDE_BASIS_QUANTITY_SU
           , DETAIL.PDE_INTERMEDIATE_DELAY
           , DETAIL.PDE_INTERMEDIATE_DELAY_M
           , DETAIL.PDE_INTERMEDIATE_DELAY_W
           , DETAIL.PDE_INTERMEDIATE_QUANTITY
           , DETAIL.PDE_INTERMEDIATE_QUANTITY_SU
           , DETAIL.PDE_FINAL_DELAY
           , DETAIL.PDE_FINAL_DELAY_M
           , DETAIL.PDE_FINAL_DELAY_W
           , DETAIL.PDE_FINAL_QUANTITY
           , DETAIL.PDE_FINAL_QUANTITY_SU
           , DETAIL.PDE_BALANCE_QUANTITY
           , DETAIL.P_PDE_BALANCE_QUANTITY
           , DETAIL.P_PDE_BALANCE_QUANTITY_PARENT
           , DETAIL.P_PDE_BASIS_QUANTITY
           , DETAIL.P_PDE_BASIS_QUANTITY_SU
           , DETAIL.P_PDE_INTERMEDIATE_QUANTITY
           , DETAIL.P_PDE_INTERMEDIATE_QUANTITY_SU
           , DETAIL.P_PDE_FINAL_QUANTITY
           , DETAIL.P_PDE_FINAL_QUANTITY_SU
           , DETAIL.NEED_FAN_EXCEED_QTY
           , DETAIL.NEED_FAN_FREE_QTY
           , DETAIL.NEED_FAN_FULL_QTY
           , DETAIL.NEED_FAN_NETW_QTY
           , DETAIL.NEED_FAN_PREV_QTY
           , DETAIL.NEED_FAN_REALIZE_QTY
           , DETAIL.NEED_FAN_RETURN_QTY
           , DETAIL.NEED_FAN_STK_QTY
           , DETAIL.NEED_FAL_NETWORK_NEED_ID
           , DETAIL.SUPPLY_FAN_EXCEED_QTY
           , DETAIL.SUPPLY_FAN_FREE_QTY
           , DETAIL.SUPPLY_FAN_FULL_QTY
           , DETAIL.SUPPLY_FAN_NETW_QTY
           , DETAIL.SUPPLY_FAN_PREV_QTY
           , DETAIL.SUPPLY_FAN_REALIZE_QTY
           , DETAIL.SUPPLY_FAN_RETURN_QTY
           , DETAIL.SUPPLY_FAN_STK_QTY
           , DETAIL.SUPPLY_FAL_NETWORK_SUPPLY_ID
           , DETAIL.LOT_REFCOMPL
           , DETAIL.GOO_MAJOR_REFERENCE COMP_MAJOR_REFERENCE
           , DETAIL.COMP_GOOD_ID COMP_GOOD_ID
           , nvl(GCO_FUNCTIONS.GetDescription(DETAIL.COMP_GOOD_ID, vlanid, 1, '06'), GCO_FUNCTIONS.GetDescription(detail.comp_good_id, vlanid, 1, '01') )
                                                                                                                                               COMP_SHORT_DESCR
           , nvl(GCO_FUNCTIONS.GetDescription(DETAIL.COMP_GOOD_ID, vlanid, 2, '06'), GCO_FUNCTIONS.GetDescription(detail.comp_good_id, vlanid, 2, '01') )
                                                                                                                                                COMP_LONG_DESCR
           , nvl(GCO_FUNCTIONS.GetDescription(DETAIL.COMP_GOOD_ID, vlanid, 3, '06'), GCO_FUNCTIONS.GetDescription(detail.comp_good_id, vlanid, 3, '01') )
                                                                                                                                                COMP_FREE_DESCR
           , DETAIL.SCS_SHORT_DESCR
           , DETAIL.SCS_LONG_DESCR
           , DETAIL.SCS_FREE_DESCR
           , FOO.FOO_TOTAL_NET_WEIGHT_MEAS
           , FOO.FOO_TOTAL_GROSS_WEIGHT_MEAS
           , DMT.DOC_RECORD_ID
           , REC.RCO_SUPPLIER_SERIAL_NUMBER
           , DMT.PAC_THIRD_ACI_ID
           , DMT.PAC_THIRD_DELIVERY_ID
           , DMT.PAC_THIRD_TARIFF_ID
           , DMT.PAC_REPR_ACI_ID
           , DMT.PAC_REPR_DELIVERY_ID
           , DMT.PC_LANG_ACI_ID
           , DMT.PC_LANG_DELIVERY_ID
           , DMT.DMT_NAME1
           , DMT.DMT_FORENAME1
           , DMT.DMT_ACTIVITY1
           , DMT.DMT_CARE_OF1
           , DMT.DMT_PO_BOX1
           , DMT.DMT_PO_BOX_NBR1
           , DMT.DMT_COUNTY1
           , DMT.DMT_CONTACT1
           , DMT.DMT_NAME2
           , DMT.DMT_FORENAME2
           , DMT.DMT_ACTIVITY2
           , DMT.DMT_CARE_OF2
           , DMT.DMT_PO_BOX2
           , DMT.DMT_PO_BOX_NBR2
           , DMT.DMT_COUNTY2
           , DMT.DMT_CONTACT2
           , DMT.DMT_NAME3
           , DMT.DMT_FORENAME3
           , DMT.DMT_ACTIVITY3
           , DMT.DMT_CARE_OF3
           , DMT.DMT_PO_BOX3
           , DMT.DMT_PO_BOX_NBR3
           , DMT.DMT_COUNTY3
           , DMT.DMT_CONTACT3
           , REC_PDE.RCO_TITLE PDE_RCO_TITLE
           , REC_PDE.RCO_SUPPLIER_SERIAL_NUMBER PDE_RCO_SUPPLIER_SERIAL_NUMBER
           , CEV.ASA_COUNTER_STATEMENT_ID
           , CEV.CML_POSITION_SERVICE_DETAIL_ID
           , CEV.CML_POSITION_MACHINE_DETAIL_ID
           , CEV.CEV_COUNTER_BEGIN_QTY
           , CEV.CEV_COUNTER_END_QTY
           , CEV.CEV_COUNTER_BEGIN_DATE
           , CEV.CEV_COUNTER_END_DATE
           , CEV.CEV_FREE_QTY
           , CEV.CEV_GROSS_CONSUMED_QTY
           , CEV.CEV_NET_CONSUMED_QTY
           , CEV.CEV_BALANCE_QTY
           , CEV.CEV_INVOICING_QTY
           , CEV.CEV_GLOBAL_EVENT
           , CEV.CEV_RENEWAL_GENERATED
           , CPO.CML_POSITION_ID
           , CPO.CPO_SEQUENCE
           , CCO.CCO_NUMBER
           , vcom_logo_large COM_LOGO_LARGE
           , vcom_logo_small COM_LOGO_SMALL
           , vcom_vatno COM_VATNO
           , vcom_descr COM_DESCR
           , vcom_adr COM_ADR
           , vcom_ide COM_IDE
           , (select MOK.C_MOVEMENT_SORT || ' ' || MOK.C_MOVEMENT_TYPE
                from STM_MOVEMENT_KIND MOK
               where MOK.STM_MOVEMENT_KIND_ID = POS.STM_MOVEMENT_KIND_ID) C_MOVEMENT_TYPE
           , (select RET.RET_OPTIONAL
                from ASA_RECORD_TASK RET
               where RET.ASA_RECORD_TASK_ID = POS.ASA_RECORD_TASK_ID) RET_OPTIONAL
           , (select ARC.ARC_OPTIONAL
                from ASA_RECORD_COMP ARC
               where ARC.ASA_RECORD_COMP_ID = POS.ASA_RECORD_COMP_ID) ARC_OPTIONAL
           , nvl( (select RET.DIC_ASA_OPTION_ID
                     from ASA_RECORD_TASK RET
                    where RET.ASA_RECORD_TASK_ID = POS.ASA_RECORD_TASK_ID), (select ARC.DIC_ASA_OPTION_ID
                                                                               from ASA_RECORD_COMP ARC
                                                                              where ARC.ASA_RECORD_COMP_ID = POS.ASA_RECORD_COMP_ID) ) DIC_ASA_OPTION_ID
           , COM_DIC_FUNCTIONS.getDicoDescr('DIC_ASA_OPTION'
                                          , nvl( (select RET.DIC_ASA_OPTION_ID
                                                    from ASA_RECORD_TASK RET
                                                   where RET.ASA_RECORD_TASK_ID = POS.ASA_RECORD_TASK_ID)
                                              , (select ARC.DIC_ASA_OPTION_ID
                                                   from ASA_RECORD_COMP ARC
                                                  where ARC.ASA_RECORD_COMP_ID = POS.ASA_RECORD_COMP_ID)
                                               )
                                          , vpc_lang_id
                                           ) DIC_ASA_OPTION_DESC
           , GAU.GAU_DESCRIBE
           , (select DES.GAD_DESCRIBE
                from DOC_GAUGE_DESCRIPTION DES
               where DES.DOC_GAUGE_ID = DMT.DOC_GAUGE_ID
                 and DES.PC_LANG_ID = vpc_lang_id) GAD_DESCRIBE
           , (select are.ARE_NUMBER
                from ASA_RECORD are
               where are.ASA_RECORD_ID = DMT.ASA_RECORD_ID) ARE_NUMBER
           , RPT_FUNCTIONS.getdocadr(DMT.DOC_DOCUMENT_ID, 1, 1, vpc_lang_id) BLOCK1_TITLE
           , RPT_FUNCTIONS.getdocadr(DMT.DOC_DOCUMENT_ID, 2, 1, vpc_lang_id) BLOCK1_NAME
           , RPT_FUNCTIONS.getdocadr(DMT.DOC_DOCUMENT_ID, 3, 1, vpc_lang_id) BLOCK1_INFO
           , RPT_FUNCTIONS.getdocadr(DMT.DOC_DOCUMENT_ID, 1, 2, vpc_lang_id) BLOCK2_TITLE
           , RPT_FUNCTIONS.getdocadr(DMT.DOC_DOCUMENT_ID, 2, 2, vpc_lang_id) BLOCK2_NAME
           , RPT_FUNCTIONS.getdocadr(DMT.DOC_DOCUMENT_ID, 3, 2, vpc_lang_id) BLOCK2_INFO
           , RPT_FUNCTIONS.getdocadr(DMT.DOC_DOCUMENT_ID, 1, 3, vpc_lang_id) BLOCK3_TITLE
           , RPT_FUNCTIONS.getdocadr(DMT.DOC_DOCUMENT_ID, 2, 3, vpc_lang_id) BLOCK3_NAME
           , RPT_FUNCTIONS.getdocadr(DMT.DOC_DOCUMENT_ID, 3, 3, vpc_lang_id) BLOCK3_INFO
           , decode(PER.PER_FORENAME, null, '', PER.PER_FORENAME || chr(13) ) ||
             decode(DMT.DMT_ACTIVITY1, null, '', DMT.DMT_ACTIVITY1 || chr(13) ) ||
             decode(DMT.DMT_CARE_OF1, null, '', DMT.DMT_CARE_OF1 || chr(13) ) ||
             decode(DMT.DMT_ADDRESS1, null, '', DMT.DMT_ADDRESS1 || chr(13) ) ||
             decode(DMT.DMT_FORMAT_CITY1, null, '', DMT.DMT_FORMAT_CITY1 || chr(13) ) ADD_1
           , decode(PER2.PER_FORENAME, null, '', PER2.PER_FORENAME || chr(13) ) ||
             decode(DMT.DMT_ACTIVITY2, null, '', DMT.DMT_ACTIVITY2 || chr(13) ) ||
             decode(DMT.DMT_CARE_OF2, null, '', DMT.DMT_CARE_OF2 || chr(13) ) ||
             decode(DMT.DMT_ADDRESS2, null, '', DMT.DMT_ADDRESS2 || chr(13) ) ||
             decode(DMT.DMT_FORMAT_CITY2, null, '', DMT.DMT_FORMAT_CITY2 || chr(13) ) ADD_2
           , decode(PER3.PER_FORENAME, null, '', PER3.PER_FORENAME || chr(13) ) ||
             decode(DMT.DMT_ACTIVITY3, null, '', DMT.DMT_ACTIVITY3 || chr(13) ) ||
             decode(DMT.DMT_CARE_OF3, null, '', DMT.DMT_CARE_OF3 || chr(13) ) ||
             decode(DMT.DMT_ADDRESS3, null, '', DMT.DMT_ADDRESS3 || chr(13) ) ||
             decode(DMT.DMT_FORMAT_CITY3, null, '', DMT.DMT_FORMAT_CITY3 || chr(13) ) ADD_3
           , (select BIT.BIT_IMAGE
                from COM_BITMAP BIT
               where BIT.BIT_TABLE_ID = POS.GCO_GOOD_ID
                 and BIT.BIT_TABLE = 'GCO_PRODUCT') BIT_IMAGE
           , to_char(DETAIL.PDE_FINAL_DELAY, 'YYYYMM') PDE_FINAL_DELAY_YEAR_MONTH
        from STM_LOCATION LOC
           , STM_LOCATION LOC_LOC
           , ACS_FIN_ACC_S_PAYMENT AFA
           , ACS_PAYMENT_METHOD APM
           , ACS_ACCOUNT TVA
           , DOC_RECORD REC
           , DOC_RECORD REC_POS
           , DOC_RECORD REC_PDE
           , DOC_FOOT FOO
           , GCO_FREE_DATA GFD
           , GCO_CUSTOMS_ELEMENT GCE
           , PCS.PC_CNTRY CNT_CUSTOMS
           , PCS.PC_CNTRY CNT_ORIGIN
           , PAC_SENDING_CONDITION PSC
           , PAC_PAYMENT_CONDITION PMT
           , ACS_FINANCIAL_CURRENCY AFC
           , DOC_FREE_DATA DFD
           , DOC_GAUGE_SIGNATORY DGS
           , DOC_GAUGE_SIGNATORY DGS2
           , DOC_GAUGE_POSITION DGP
           , PAC_CUSTOM_PARTNER CUS
           , ACS_ACCOUNT ACCC
           , PAC_ADDRESS ADR
           , PAC_ADDRESS ADR2
           , PAC_ADDRESS ADR3
           , PAC_REPRESENTATIVE REP
           , PAC_REPRESENTATIVE REP_POS
           , PAC_ADDRESS ADR_SEN
           , PAC_PERSON PER_SEN
           , PAC_PERSON PER
           , PAC_PERSON PER2
           , PAC_PERSON PER3
           , PAC_SUPPLIER_PARTNER SUP
           , ACS_ACCOUNT ACCS
           , PAC_THIRD THI
           , ACS_TAX_CODE ATC
           , PCS.PC_CURR CUR
           , PCS.PC_CNTRY CNT
           , PCS.PC_CNTRY CNT2
           , PCS.PC_CNTRY CNT3
           , DOC_GAUGE GAU
           , DOC_GAUGE_STRUCTURED GST
           , STM_STOCK STM
           , STM_STOCK STM_STM
           , GCO_GOOD GOO
           , GCO_PRODUCT PDT
           , DOC_POSITION POS
           , DOC_DOCUMENT DMT
           , CML_EVENTS CEV
           , CML_POSITION CPO
           , CML_DOCUMENT CCO
           , DOC_POSITION POS_ADD
           , DOC_POSITION_DETAIL PDE_ADD
           , (select DMT.DMT_NUMBER
                   , POS.DOC_POSITION_ID POSITIONID
                   , DMT_PERE.DMT_NUMBER PERE_DMT_NUMBER
                   , DMT_PERE.DMT_DATE_DOCUMENT PERE_DMT_DATE_DOCUMENT
                   , GAS_PERE.C_GAUGE_TITLE PERE_C_GAUGE_TITLE
                   , GAU_PERE.GAU_DESCRIBE PERE_GAU_DESCRIBE
                   , GAU_PERE_DES.GAD_DESCRIBE PERE_GAD_DESCRIBE
                   , GAS_G_PERE.C_GAUGE_TITLE G_PERE_C_GAUGE_TITLE
                   , GAU_G_PERE.GAU_DESCRIBE G_PERE_GAU_DESCRIBE
                   , GAU_G_PERE_DES.GAD_DESCRIBE G_PERE_GAD_DESCRIBE
                   , DMT_PERE.DMT_PARTNER_NUMBER PERE_DMT_PARTNER_NUMBER
                   , DMT_PERE.DMT_PARTNER_REFERENCE PERE_DMT_PARTNTER_REFERENCE
                   , DMT_PERE.DMT_DATE_PARTNER_DOCUMENT PERE_DATE_PARTNER_DOCUMENT
                   , DMT_G_PERE.DMT_NUMBER G_PERE_DMT_NUMBER
                   , DMT_G_PERE.DMT_DATE_DOCUMENT G_PERE_DMT_DATE_DOCUMENT
                   , DMT_G_PERE.DMT_PARTNER_NUMBER G_PERE_DMT_PARTNER_NUMBER
                   , DMT_G_PERE.DMT_PARTNER_REFERENCE G_PERE_DMT_PARTNTER_REFERENCE
                   , DMT_G_PERE.DMT_DATE_PARTNER_DOCUMENT G_PERE_DATE_PARTNER_DOCUMENT
                   , PDE.DOC_POSITION_DETAIL_ID
                   , PDE.FAL_SCHEDULE_STEP_ID FAL_SCHEDULE_STEP_ID
                   , PDE.DOC_RECORD_ID
                   , PDE.PDE_ADDENDUM_SRC_PDE_ID
                   , PDE.STM_LOCATION_ID STM_LOCATION_ID
                   , PDE.STM_STM_LOCATION_ID STM_STM_LOCATION_ID
                   , PDE.DIC_DELAY_UPDATE_TYPE_ID DIC_DELAY_UPDATE_TYPE_ID
                   , PDE.PDE_DELAY_UPDATE_TEXT PDE_DELAY_UPDATE_TEXT
                   , PDE.GCO_CHARACTERIZATION_ID GCO1_CHARACTERIZATION_ID
                   , PDE.GCO_GCO_CHARACTERIZATION_ID GCO2_CHARACTERIZATION_ID
                   , PDE.GCO2_GCO_CHARACTERIZATION_ID GCO3_CHARACTERIZATION_ID
                   , PDE.GCO3_GCO_CHARACTERIZATION_ID GCO4_CHARACTERIZATION_ID
                   , PDE.GCO4_GCO_CHARACTERIZATION_ID GCO5_CHARACTERIZATION_ID
                   , PDE.PDE_CHARACTERIZATION_VALUE_1 PDE_CHARACTERIZATION_VALUE_1
                   , PDE.PDE_CHARACTERIZATION_VALUE_2 PDE_CHARACTERIZATION_VALUE_2
                   , PDE.PDE_CHARACTERIZATION_VALUE_3 PDE_CHARACTERIZATION_VALUE_3
                   , PDE.PDE_CHARACTERIZATION_VALUE_4 PDE_CHARACTERIZATION_VALUE_4
                   , PDE.PDE_CHARACTERIZATION_VALUE_5 PDE_CHARACTERIZATION_VALUE_5
                   , PDE.PDE_PIECE
                   , PDE.PDE_SET
                   , PDE.PDE_VERSION
                   , PDE.PDE_CHRONOLOGICAL
                   , PDE.PDE_STD_CHAR_1
                   , PDE.PDE_STD_CHAR_2
                   , PDE.PDE_STD_CHAR_3
                   , PDE.PDE_STD_CHAR_4
                   , PDE.PDE_STD_CHAR_5
                   , PDE.PDE_BASIS_DELAY PDE_BASIS_DELAY
                   , DOC_DELAY_FUNCTIONS.DateToMonth(PDE.PDE_BASIS_DELAY) PDE_BASIS_DELAY_M
                   , DOC_DELAY_FUNCTIONS.DateToWeek(PDE.PDE_BASIS_DELAY) PDE_BASIS_DELAY_W
                   , PDE.PDE_BASIS_QUANTITY PDE_BASIS_QUANTITY
                   , PDE.PDE_BASIS_QUANTITY_SU PDE_BASIS_QUANTITY_SU
                   , PDE.PDE_INTERMEDIATE_DELAY PDE_INTERMEDIATE_DELAY
                   , DOC_DELAY_FUNCTIONS.DateToMonth(PDE.PDE_INTERMEDIATE_DELAY) PDE_INTERMEDIATE_DELAY_M
                   , DOC_DELAY_FUNCTIONS.DateToWeek(PDE.PDE_INTERMEDIATE_DELAY) PDE_INTERMEDIATE_DELAY_W
                   , PDE.PDE_INTERMEDIATE_QUANTITY PDE_INTERMEDIATE_QUANTITY
                   , PDE.PDE_INTERMEDIATE_QUANTITY_SU PDE_INTERMEDIATE_QUANTITY_SU
                   , PDE.PDE_FINAL_DELAY PDE_FINAL_DELAY
                   , DOC_DELAY_FUNCTIONS.DateToMonth(PDE.PDE_FINAL_DELAY) PDE_FINAL_DELAY_M
                   , DOC_DELAY_FUNCTIONS.DateToWeek(PDE.PDE_FINAL_DELAY) PDE_FINAL_DELAY_W
                   , PDE.PDE_FINAL_QUANTITY PDE_FINAL_QUANTITY
                   , PDE.PDE_FINAL_QUANTITY_SU PDE_FINAL_QUANTITY_SU
                   , case
                       when(DMT.DMT_ADDENDUM_INDEX is not null)
                       and (POS.C_DOC_POS_STATUS = '04') then PDE.PDE_ADDENDUM_QTY_BALANCED
                       else PDE.PDE_BALANCE_QUANTITY
                     end PDE_BALANCE_QUANTITY
                   , PDE.DIC_IMP_FREE1_ID
                   , PDE.DIC_IMP_FREE2_ID
                   , PDE.DIC_IMP_FREE3_ID
                   , PDE.DIC_IMP_FREE4_ID
                   , PDE.DIC_IMP_FREE5_ID
                   , PDE.DIC_PDE_FREE_TABLE_1_ID
                   , PDE.DIC_PDE_FREE_TABLE_2_ID
                   , PDE.DIC_PDE_FREE_TABLE_3_ID
                   , PDE.PDE_TEXT_1
                   , PDE.PDE_TEXT_2
                   , PDE.PDE_TEXT_3
                   , PDE.PDE_DECIMAL_1
                   , PDE.PDE_DECIMAL_2
                   , PDE.PDE_DECIMAL_3
                   , PDE.PDE_DATE_1
                   , PDE.PDE_DATE_2
                   , PDE.PDE_DATE_3
                   , PERE.DOC_POSITION_DETAIL_ID PERE_DOC_POSITION_DETAIL_ID
                   , PERE.PDE_BALANCE_QUANTITY P_PDE_BALANCE_QUANTITY
                   , PERE.PDE_BALANCE_QUANTITY_PARENT P_PDE_BALANCE_QUANTITY_PARENT
                   , PERE.PDE_BASIS_QUANTITY P_PDE_BASIS_QUANTITY
                   , PERE.PDE_BASIS_QUANTITY_SU P_PDE_BASIS_QUANTITY_SU
                   , PERE.PDE_INTERMEDIATE_QUANTITY P_PDE_INTERMEDIATE_QUANTITY
                   , PERE.PDE_INTERMEDIATE_QUANTITY_SU P_PDE_INTERMEDIATE_QUANTITY_SU
                   , PERE.PDE_FINAL_QUANTITY P_PDE_FINAL_QUANTITY
                   , PERE.PDE_FINAL_QUANTITY_SU P_PDE_FINAL_QUANTITY_SU
                   , G_PERE.DOC_POSITION_DETAIL_ID G_PERE_DOC_POSITION_DETAIL_ID
                   , NEE.FAN_EXCEED_QTY NEED_FAN_EXCEED_QTY
                   , NEE.FAN_FREE_QTY NEED_FAN_FREE_QTY
                   , NEE.FAN_FULL_QTY NEED_FAN_FULL_QTY
                   , NEE.FAN_NETW_QTY NEED_FAN_NETW_QTY
                   , NEE.FAN_PREV_QTY NEED_FAN_PREV_QTY
                   , NEE.FAN_REALIZE_QTY NEED_FAN_REALIZE_QTY
                   , NEE.FAN_RETURN_QTY NEED_FAN_RETURN_QTY
                   , NEE.FAN_STK_QTY NEED_FAN_STK_QTY
                   , NEE.FAL_NETWORK_NEED_ID NEED_FAL_NETWORK_NEED_ID
                   , SUPP.FAN_EXCEED_QTY SUPPLY_FAN_EXCEED_QTY
                   , SUPP.FAN_FREE_QTY SUPPLY_FAN_FREE_QTY
                   , SUPP.FAN_FULL_QTY SUPPLY_FAN_FULL_QTY
                   , SUPP.FAN_NETW_QTY SUPPLY_FAN_NETW_QTY
                   , SUPP.FAN_PREV_QTY SUPPLY_FAN_PREV_QTY
                   , SUPP.FAN_REALIZE_QTY SUPPLY_FAN_REALIZE_QTY
                   , SUPP.FAN_RETURN_QTY SUPPLY_FAN_RETURN_QTY
                   , SUPP.FAN_STK_QTY SUPPLY_FAN_STK_QTY
                   , SUPP.FAL_NETWORK_SUPPLY_ID SUPPLY_FAL_NETWORK_SUPPLY_ID
                   , LOT.LOT_REFCOMPL LOT_REFCOMPL
                   , COMP.GOO_MAJOR_REFERENCE GOO_MAJOR_REFERENCE
                   , COMP.GCO_GOOD_ID COMP_GOOD_ID
                   , LNK.SCS_SHORT_DESCR SCS_SHORT_DESCR
                   , LNK.SCS_LONG_DESCR SCS_LONG_DESCR
                   , LNK.SCS_FREE_DESCR SCS_FREE_DESCR
                from FAL_NETWORK_NEED NEE
                   , FAL_NETWORK_SUPPLY SUPP
                   , FAL_TASK_LINK LNK
                   , FAL_LOT LOT
                   , GCO_GOOD COMP
                   , DOC_GAUGE_STRUCTURED GAS_G_PERE
                   , DOC_GAUGE_STRUCTURED GAS_PERE
                   , DOC_GAUGE GAU_G_PERE
                   , DOC_GAUGE GAU_PERE
                   , (select DOC_GAUGE_ID
                           , GAD_DESCRIBE
                        from DOC_GAUGE_DESCRIPTION
                       where PC_LANG_ID = vpc_lang_id) GAU_G_PERE_DES
                   , (select DOC_GAUGE_ID
                           , GAD_DESCRIBE
                        from DOC_GAUGE_DESCRIPTION
                       where PC_LANG_ID = vpc_lang_id) GAU_PERE_DES
                   , DOC_POSITION_DETAIL G_PERE
                   , DOC_POSITION_DETAIL PERE
                   , DOC_POSITION_DETAIL PDE
                   , DOC_DOCUMENT DMT_G_PERE
                   , DOC_DOCUMENT DMT_PERE
                   , DOC_POSITION POS
                   , DOC_DOCUMENT DMT
               where DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
                 and PDE.DOC_POSITION_ID(+) = POS.DOC_POSITION_ID
                 and PERE.DOC_POSITION_DETAIL_ID(+) = PDE.DOC_DOC_POSITION_DETAIL_ID
                 and DMT_PERE.DOC_DOCUMENT_ID(+) = PERE.DOC_DOCUMENT_ID
                 and G_PERE.DOC_POSITION_DETAIL_ID(+) = PERE.DOC_DOC_POSITION_DETAIL_ID
                 and LNK.FAL_SCHEDULE_STEP_ID(+) = PDE.FAL_SCHEDULE_STEP_ID
                 and LOT.FAL_LOT_ID(+) = LNK.FAL_LOT_ID
                 and COMP.GCO_GOOD_ID(+) = LOT.GCO_GOOD_ID
                 and GAS_PERE.DOC_GAUGE_ID(+) = PERE.DOC_GAUGE_ID
                 and GAU_PERE.DOC_GAUGE_ID(+) = PERE.DOC_GAUGE_ID
                 and GAU_PERE_DES.DOC_GAUGE_ID(+) = PERE.DOC_GAUGE_ID
                 and DMT_G_PERE.DOC_DOCUMENT_ID(+) = G_PERE.DOC_DOCUMENT_ID
                 and GAS_G_PERE.DOC_GAUGE_ID(+) = G_PERE.DOC_GAUGE_ID
                 and GAU_G_PERE.DOC_GAUGE_ID(+) = G_PERE.DOC_GAUGE_ID
                 and GAU_G_PERE_DES.DOC_GAUGE_ID(+) = G_PERE.DOC_GAUGE_ID
                 and NEE.DOC_POSITION_DETAIL_ID(+) = PDE.DOC_POSITION_DETAIL_ID
                 and SUPP.DOC_POSITION_DETAIL_ID(+) = PDE.DOC_POSITION_DETAIL_ID) DETAIL
       where DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and DETAIL.POSITIONID(+) = POS.DOC_POSITION_ID
         and DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
         and GAU.DOC_GAUGE_ID = GST.DOC_GAUGE_ID
         and POS.DOC_GAUGE_POSITION_ID = DGP.DOC_GAUGE_POSITION_ID
         and TVA.ACS_ACCOUNT_ID(+) = POS.ACS_TAX_CODE_ID
         and AFA.ACS_FIN_ACC_S_PAYMENT_ID(+) = DMT.ACS_FIN_ACC_S_PAYMENT_ID
         and APM.ACS_PAYMENT_METHOD_ID(+) = AFA.ACS_PAYMENT_METHOD_ID
         and REP.PAC_REPRESENTATIVE_ID(+) = DMT.PAC_REPRESENTATIVE_ID
         and DFD.DOC_DOCUMENT_ID(+) = DMT.DOC_DOCUMENT_ID
         and FOO.DOC_DOCUMENT_ID(+) = DMT.DOC_DOCUMENT_ID
         and ATC.ACS_TAX_CODE_ID(+) = POS.ACS_TAX_CODE_ID
         and GCE.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
         and CNT_CUSTOMS.PC_CNTRY_ID(+) = GCE.PC_CNTRY_ID
         and CNT_ORIGIN.PC_CNTRY_ID(+) = GCE.PC_ORIGIN_PC_CNTRY_ID
         and GCE.C_CUSTOMS_ELEMENT_TYPE(+) = 'EXPORT'
         and REP_POS.PAC_REPRESENTATIVE_ID(+) = POS.PAC_REPRESENTATIVE_ID
         and DGS.DOC_GAUGE_SIGNATORY_ID(+) = FOO.DOC_GAUGE_SIGNATORY_ID
         and DGS2.DOC_GAUGE_SIGNATORY_ID(+) = FOO.DOC_DOC_GAUGE_SIGNATORY_ID
         and REC.DOC_RECORD_ID(+) = DMT.DOC_RECORD_ID
         and REC_POS.DOC_RECORD_ID(+) = POS.DOC_RECORD_ID
         and REC_PDE.DOC_RECORD_ID(+) = DETAIL.DOC_RECORD_ID
         and PSC.PAC_SENDING_CONDITION_ID(+) = DMT.PAC_SENDING_CONDITION_ID
         and ADR_SEN.PAC_ADDRESS_ID(+) = PSC.PAC_ADDRESS_ID
         and PER_SEN.PAC_PERSON_ID(+) = ADR_SEN.PAC_PERSON_ID
         and THI.PAC_THIRD_ID(+) = DMT.PAC_THIRD_ID
         and CUS.PAC_CUSTOM_PARTNER_ID(+) = DMT.PAC_THIRD_ID
         and ACCC.ACS_ACCOUNT_ID(+) = CUS.ACS_AUXILIARY_ACCOUNT_ID
         and ACCS.ACS_ACCOUNT_ID(+) = SUP.ACS_AUXILIARY_ACCOUNT_ID
         and SUP.PAC_SUPPLIER_PARTNER_ID(+) = DMT.PAC_THIRD_ID
         and ADR.PAC_ADDRESS_ID(+) = DMT.PAC_ADDRESS_ID
         and PER.PAC_PERSON_ID(+) = ADR.PAC_PERSON_ID
         and ADR2.PAC_ADDRESS_ID(+) = DMT.PAC_PAC_ADDRESS_ID
         and PER2.PAC_PERSON_ID(+) = ADR2.PAC_PERSON_ID
         and ADR3.PAC_ADDRESS_ID(+) = DMT.PAC2_PAC_ADDRESS_ID
         and PER3.PAC_PERSON_ID(+) = ADR3.PAC_PERSON_ID
         and CNT.PC_CNTRY_ID(+) = DMT.PC_CNTRY_ID
         and CNT2.PC_CNTRY_ID(+) = DMT.PC__PC_CNTRY_ID
         and CNT3.PC_CNTRY_ID(+) = DMT.PC_2_PC_CNTRY_ID
         and AFC.ACS_FINANCIAL_CURRENCY_ID(+) = DMT.ACS_FINANCIAL_CURRENCY_ID
         and CUR.PC_CURR_ID(+) = AFC.PC_CURR_ID
         and PMT.PAC_PAYMENT_CONDITION_ID(+) = DMT.PAC_PAYMENT_CONDITION_ID
         and LOC.STM_LOCATION_ID(+) = DETAIL.STM_LOCATION_ID
         and LOC_LOC.STM_LOCATION_ID(+) = DETAIL.STM_STM_LOCATION_ID
         and STM.STM_STOCK_ID(+) = LOC.STM_STOCK_ID
         and STM_STM.STM_STOCK_ID(+) = LOC_LOC.STM_STOCK_ID
         and GOO.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
         and PDT.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
         and GFD.GCO_GOOD_ID(+) = GOO.GCO_GOOD_ID
         and CEV.CML_EVENTS_ID(+) = POS.CML_EVENTS_ID
         and CPO.CML_POSITION_ID(+) = POS.CML_POSITION_ID
         and CCO.CML_DOCUMENT_ID(+) = CPO.CML_DOCUMENT_ID
         and POS_ADD.DOC_POSITION_ID(+) = POS.POS_ADDENDUM_SRC_POS_ID
         and PDE_ADD.DOC_POSITION_DETAIL_ID(+) = DETAIL.PDE_ADDENDUM_SRC_PDE_ID
         and DMT.DMT_NUMBER = parameter_0
    order by POS.POS_NUMBER;
end RPT_DOC_STD_3;
