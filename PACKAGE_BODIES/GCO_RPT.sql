--------------------------------------------------------
--  DDL for Package Body GCO_RPT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GCO_RPT" 
is
/**
*Description
*   STORED PROCEDURE USED GCO_GOOD_CATEGORY_LIST
*/
  procedure GCO_CAT_LIST_RPT_PK(arefcursor in out crystal_cursor_types.dualcursortyp, procuser_lanid in pcs.pc_lang.lanid%type)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select CAT.GCO_GOOD_CATEGORY_ID
           , CAT.GCO_GOOD_CATEGORY_WORDING
           , CAT.GCO_CATEGORY_CODE
           , CAT.CAT_STK_POSSESSION_RATE
           , CAT.CAT_COMPL_ACHAT
           , CAT.CAT_COMPL_VENTE
           , CAT.CAT_COMPL_SAV
           , CAT.CAT_COMPL_STOCK
           , CAT.CAT_COMPL_INV
           , CAT.CAT_COMPL_FAB
           , CAT.CAT_COMPL_STRAIT
           , CAT.DIC_CATEGORY_FREE_1_ID
           , CAT.DIC_CATEGORY_FREE_2_ID
           , CAT.CAT_FREE_TEXT_1
           , CAT.CAT_FREE_TEXT_2
           , CAT.CAT_FREE_TEXT_3
           , CAT.CAT_FREE_TEXT_4
           , CAT.CAT_FREE_TEXT_5
           , CAT.CAT_FREE_NUMBER_1
           , CAT.CAT_FREE_NUMBER_2
           , CAT.CAT_FREE_NUMBER_3
           , CAT.CAT_FREE_NUMBER_4
           , CAT.CAT_FREE_NUMBER_5
           , CAT.C_EAN_TYPE
           , CAT.DIC_GOOD_EAN_GEN_ID
           , CAT.C_EAN_TYPE_PURCHASE
           , CAT.DIC_GOOD_EAN_GEN_PUR_ID
           , CAT.C_EAN_TYPE_SALE
           , CAT.DIC_GOOD_EAN_GEN_SALE_ID
           , CAT.C_EAN_TYPE_ASA
           , CAT.DIC_GOOD_EAN_GEN_ASA_ID
           , CAT.C_EAN_TYPE_STOCK
           , CAT.DIC_GOOD_EAN_GEN_STOCK_ID
           , CAT.C_EAN_TYPE_INV
           , CAT.DIC_GOOD_EAN_GEN_INV_ID
           , CAT.C_EAN_TYPE_FAL
           , CAT.DIC_GOOD_EAN_GEN_FAL_ID
           , CAT.C_EAN_TYPE_SUBCONTRACT
           , CAT.DIC_GOOD_EAN_GEN_SCO_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_1_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_2_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_3_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_4_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_5_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_6_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_7_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_8_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_9_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_10_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_11_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_12_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_13_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_14_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_15_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_16_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_17_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_18_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_19_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_20_ID
           , CAT.CAT_COMPL_ATTRIBUTE
           , CAT.C_REPLICATION_TYPE
           , NUM.GCN_DESCRIPTION
           , TEM.RTE_DESCRIPTION
           , TEM.RTE_DESIGNATION
           , DES.GCD_WORDING
        from GCO_GOOD_CATEGORY CAT
           , GCO_REFERENCE_TEMPLATE TEM
           , GCO_GOOD_NUMBERING NUM
           , GCO_GOOD_CATEGORY_DESCR DES
       where CAT.GCO_GOOD_NUMBERING_ID = NUM.GCO_GOOD_NUMBERING_ID(+)
         and CAT.GCO_REFERENCE_TEMPLATE_ID = TEM.GCO_REFERENCE_TEMPLATE_ID
         and CAT.GCO_GOOD_CATEGORY_ID = DES.GCO_GOOD_CATEGORY_ID
         and DES.PC_LANG_ID = VPC_LANG_ID;
  end GCO_CAT_LIST_RPT_PK;

/**
*Description
*   STORED PROCEDURE USED GCO_GOOD_CATEGORY_LIST
*/
  procedure GCO_CAT_LIST_SUB_RPT_PK(
    arefcursor                   in out crystal_cursor_types.dualcursortyp
  , procuser_lanid               in     pcs.pc_lang.lanid%type
  , PM_DIC_TABSHEET_ATTRIBUTE_ID in     GCO_ATTRIBUTE_FIELDS.DIC_TABSHEET_ATTRIBUTE_ID%type
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select DTA.DIC_TABSHEET_ATTRIBUTE_ID
           , DTA.DIC_DESCRIPTION
           , GAF.ATF_MANDATORY
           , GAF.ATF_SEQUENCE_NUMBER
           , FDI.FDIHEADER
           , FLD.FLDNAME
        from DIC_TABSHEET_ATTRIBUTE DTA
           , GCO_ATTRIBUTE_FIELDS GAF
           , PCS.PC_FDICO FDI
           , PCS.PC_FLDSC FLD
       where DTA.DIC_TABSHEET_ATTRIBUTE_ID = GAF.DIC_TABSHEET_ATTRIBUTE_ID
         and GAF.PC_FLDSC_ID = FLD.PC_FLDSC_ID
         and FDI.PC_FLDSC_ID = FLD.PC_FLDSC_ID
         and FDI.PC_LANG_ID = VPC_LANG_ID
         and DTA.DIC_TABSHEET_ATTRIBUTE_ID = PM_DIC_TABSHEET_ATTRIBUTE_ID;
  end GCO_CAT_LIST_SUB_RPT_PK;

/**
*Description
*   STORED PROCEDURE USED GCO_GOOD_CATEGORY_LIST
*/
  procedure GCO_CAT_LIST_INTER_SUB_RPT_PK(
    arefcursor              in out crystal_cursor_types.dualcursortyp
  , procuser_lanid          in     pcs.pc_lang.lanid%type
  , PM_GCO_GOOD_CATEGORY_ID in     varchar2
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select GTL.GCO_TRANSFER_LIST_ID
           , GTL.C_DEFAULT_REPL
           , GTL.C_TRANSFER_TYPE
           , GTL.XLI_TABLE_NAME
           , GTL.XLI_FIELD_NAME
           , GTL.XLI_SUBSTITUTION
           , GTL.GCO_GOOD_CATEGORY_ID
           , GTS.XSU_ORIGINAL
           , GTS.XSU_REPLACEMENT
           , GTS.XSU_IS_DEFAULT_VALUE
        from GCO_TRANSFER_SUBST GTS
           , GCO_TRANSFER_LIST GTL
       where GTS.GCO_TRANSFER_LIST_ID = GTL.GCO_TRANSFER_LIST_ID
         and GTL.GCO_GOOD_CATEGORY_ID = to_number(PM_GCO_GOOD_CATEGORY_ID);
  end GCO_CAT_LIST_INTER_SUB_RPT_PK;

/**
*Description
*   STORED PROCEDURE USED GCO_GOOD_BY_THIRD
*/
  procedure GCO_GOOD_BY_THIRD_RPT_PK(arefcursor in out crystal_cursor_types.dualcursortyp, procuser_lanid in pcs.pc_lang.lanid%type)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select GCP.CDA_COMPLEMENTARY_REFERENCE
           , GCP.CDA_SHORT_DESCRIPTION
           , GCP.CDA_LONG_DESCRIPTION
           , GCP.CPU_DEFAULT_SUPPLIER
           , GDE.DES_SHORT_DESCRIPTION
           , GDE.DES_LONG_DESCRIPTION
           , GOO.GOO_MAJOR_REFERENCE
           , PPE.PER_NAME
        from GCO_COMPL_DATA_PURCHASE GCP
           , GCO_DESCRIPTION GDE
           , GCO_GOOD GOO
           , PAC_PERSON PPE
       where GCP.PAC_SUPPLIER_PARTNER_ID = PPE.PAC_PERSON_ID
         and GCP.GCO_GOOD_ID = GOO.GCO_GOOD_ID
         and GOO.GCO_GOOD_ID = GDE.GCO_GOOD_ID
         and GDE.C_DESCRIPTION_TYPE = '01'
         and GDE.PC_LANG_ID = VPC_LANG_ID;
  end GCO_GOOD_BY_THIRD_RPT_PK;

/**
* PROCEDURE GCO_GOOD_BY_THIRD_REAL_RPT_PK
* Description
*    Used in the GCO_GOOD_BY_THIRD_REAL
* @created AWU 09.2008
* @lastUpdate
* */
  procedure GCO_GOOD_BY_THIRD_REAL_RPT_PK(
    arefcursor     in out crystal_cursor_types.dualcursortyp
  , procuser_lanid in     pcs.pc_lang.lanid%type
  , parameter_0    in     varchar2
  , parameter_1    in     varchar2
  , parameter_2    in     varchar2
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select GOO.GCO_GOOD_ID
           , GOO.GOO_MAJOR_REFERENCE
           , GOO.GOO_NUMBER_OF_DECIMAL
           , GDE.GCD_WORDING
           , GCA.GCO_GOOD_CATEGORY_WORDING
           , PPE.PER_NAME
           , V_DPS.V_BASIS_QUANTITY
           , V_DPS.MIN_DATE_VALUE
           , V_DPS.MAX_DATE_VALUE
           , GCO_FUNCTIONS.GETDESCRIPTION(GOO.GCO_GOOD_ID, VPC_LANG_ID, 1, '01') DESCR
        from GCO_GOOD GOO
           , GCO_GOOD_CATEGORY_DESCR GDE
           , PAC_PERSON PPE
           , V_DOC_POSITION_SUPPL V_DPS
           , GCO_GOOD_CATEGORY GCA
       where GOO.GCO_GOOD_ID = V_DPS.V_GOOD_ID
         and V_DPS.V_THIRD_ID = PPE.PAC_PERSON_ID
         and GOO.GCO_GOOD_CATEGORY_ID = GDE.GCO_GOOD_CATEGORY_ID(+)
         and GDE.PC_LANG_ID = VPC_LANG_ID
         and GOO.GCO_GOOD_CATEGORY_ID = GCA.GCO_GOOD_CATEGORY_ID
         and GCA.GCO_GOOD_CATEGORY_WORDING like decode(PARAMETER_0, '0', '%', PARAMETER_0 || '%')
         and GOO.GOO_MAJOR_REFERENCE >= decode(PARAMETER_1, '0', '0', PARAMETER_1)
         and GOO.GOO_MAJOR_REFERENCE <= decode(PARAMETER_2, '0', chr(255), PARAMETER_2);
  end GCO_GOOD_BY_THIRD_REAL_RPT_PK;

/**
*Description
*   STORED PROCEDURE USED GCO_PRODUCT_FORM_BATCH
*/
  procedure GCO_PRODUCT_FORM_BATCH_RPT_PK(arefcursor in out crystal_cursor_types.dualcursortyp, procuser_lanid in pcs.pc_lang.lanid%type)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select V_GGC.GCO_GOOD_ID GC_GCO_GOOD_ID
           , V_GGC.GOO_MAJOR_REFERENCE
           , V_GGC.GOO_SECONDARY_REFERENCE
           , V_GGC.GOO_NUMBER_OF_DECIMAL
           , V_GGC.A_DATECRE
           , V_GGC.A_DATEMOD
           , V_GGC.PC_LANG_ID
           , V_GGC.DES_SHORT_DESCRIPTION
           , V_GGC.DES_LONG_DESCRIPTION
           , V_GGC.DES_FREE_DESCRIPTION
           , V_GGC.GCO_GOOD_CATEGORY_WORDING
           , V_GGC.DIC_UNIT_OF_MEASURE_WORDING
           , V_GGC.C_MNGMNT_MODE_WORDING1
           , V_GGL.GOO_PRECIOUS_MAT
           , V_GPL.GCO_GOOD_ID
           , V_GPL.STM_STOCK_ID
           , V_GPL.PDT_FULL_TRACABILITY
           , V_GPL.STO_DESCRIPTION
           , V_GPL.STM_LOCATION_ID
           , V_GPL.LOC_DESCRIPTION
           , V_GPL.C_SUPPLY_MODE_WORDING1
           , V_GPL.PDT_STOCK_MANAGEMENT
           , V_GPL.PDT_STOCK_OBTAIN_MANAGEMENT
           , V_GPL.PDT_CALC_REQUIREMENT_MNGMENT
           , V_GPL.PDT_CONTINUOUS_INVENTAR
           , V_GPL.PDT_PIC
           , V_GPL.PDT_BLOCK_EQUI
           , V_GPL.PDT_GUARANTY_USE
           , V_GPL.PDT_MULTI_SOURCING
           , GDE.GCD_WORDING
        from V_GCO_GOOD_CATALOGUE V_GGC
           , V_GCO_GOOD_LIST V_GGL
           , V_GCO_PRODUCT_LIST V_GPL
           , GCO_GOOD_CATEGORY_DESCR GDE
       where V_GPL.GCO_GOOD_ID = V_GGC.GCO_GOOD_ID
         and V_GPL.PC_LANG_ID = V_GGC.PC_LANG_ID
         and V_GPL.GCO_GOOD_ID = V_GGL.GCO_GOOD_ID
         and V_GGC.PC_LANG_ID = VPC_LANG_ID
         and V_GGC.GCO_GOOD_CATEGORY_ID = GDE.GCO_GOOD_CATEGORY_ID
         and V_GGC.PC_LANG_ID = GDE.PC_LANG_ID;
  end GCO_PRODUCT_FORM_BATCH_RPT_PK;

/**
*Description
*   STORED PROCEDURE USED GCO_GOOD_CATEGORY_BATCH
*/
  procedure GCO_CAT_BATCH_RPT_PK(arefcursor in out crystal_cursor_types.dualcursortyp, procuser_lanid in pcs.pc_lang.lanid%type, parameter_0 in number)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select CAT.GCO_GOOD_CATEGORY_ID
           , CAT.GCO_GOOD_CATEGORY_WORDING
           , CAT.GCO_CATEGORY_CODE
           , CAT.CAT_STK_POSSESSION_RATE
           , CAT.CAT_COMPL_ACHAT
           , CAT.CAT_COMPL_VENTE
           , CAT.CAT_COMPL_SAV
           , CAT.CAT_COMPL_STOCK
           , CAT.CAT_COMPL_INV
           , CAT.CAT_COMPL_FAB
           , CAT.CAT_COMPL_STRAIT
           , CAT.DIC_CATEGORY_FREE_1_ID
           , CAT.DIC_CATEGORY_FREE_2_ID
           , CAT.CAT_FREE_TEXT_1
           , CAT.CAT_FREE_TEXT_2
           , CAT.CAT_FREE_TEXT_3
           , CAT.CAT_FREE_TEXT_4
           , CAT.CAT_FREE_TEXT_5
           , CAT.CAT_FREE_NUMBER_1
           , CAT.CAT_FREE_NUMBER_2
           , CAT.CAT_FREE_NUMBER_3
           , CAT.CAT_FREE_NUMBER_4
           , CAT.CAT_FREE_NUMBER_5
           , CAT.C_EAN_TYPE
           , CAT.DIC_GOOD_EAN_GEN_ID
           , CAT.C_EAN_TYPE_PURCHASE
           , CAT.DIC_GOOD_EAN_GEN_PUR_ID
           , CAT.C_EAN_TYPE_SALE
           , CAT.DIC_GOOD_EAN_GEN_SALE_ID
           , CAT.C_EAN_TYPE_ASA
           , CAT.DIC_GOOD_EAN_GEN_ASA_ID
           , CAT.C_EAN_TYPE_STOCK
           , CAT.DIC_GOOD_EAN_GEN_STOCK_ID
           , CAT.C_EAN_TYPE_INV
           , CAT.DIC_GOOD_EAN_GEN_INV_ID
           , CAT.C_EAN_TYPE_FAL
           , CAT.DIC_GOOD_EAN_GEN_FAL_ID
           , CAT.C_EAN_TYPE_SUBCONTRACT
           , CAT.DIC_GOOD_EAN_GEN_SCO_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_1_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_2_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_3_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_4_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_5_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_6_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_7_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_8_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_9_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_10_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_11_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_12_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_13_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_14_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_15_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_16_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_17_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_18_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_19_ID
           , CAT.DIC_TABSHEET_ATTRIBUTE_20_ID
           , CAT.CAT_COMPL_ATTRIBUTE
           , CAT.C_REPLICATION_TYPE
           , NUM.GCN_DESCRIPTION
           , TEM.RTE_DESCRIPTION
           , TEM.RTE_DESIGNATION
           , DES.GCD_WORDING
        from GCO_GOOD_CATEGORY CAT
           , GCO_REFERENCE_TEMPLATE TEM
           , GCO_GOOD_NUMBERING NUM
           , GCO_GOOD_CATEGORY_DESCR DES
       where CAT.GCO_GOOD_NUMBERING_ID = NUM.GCO_GOOD_NUMBERING_ID(+)
         and CAT.GCO_REFERENCE_TEMPLATE_ID = TEM.GCO_REFERENCE_TEMPLATE_ID
         and CAT.GCO_GOOD_CATEGORY_ID = DES.GCO_GOOD_CATEGORY_ID
         and DES.PC_LANG_ID = VPC_LANG_ID
         and CAT.GCO_GOOD_CATEGORY_ID = PARAMETER_0;
  end GCO_CAT_BATCH_RPT_PK;

/**
*Description
*   STORED PROCEDURE USED GCO_PSEUDO_FORM_BATCH
*/
  procedure GCO_PSEUDO_FORM_BATCH_RPT_PK(arefcursor in out crystal_cursor_types.dualcursortyp, procuser_lanid in pcs.pc_lang.lanid%type)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select PSE.GCO_GOOD_ID
           , V_CA.GOO_MAJOR_REFERENCE
           , V_CA.GOO_SECONDARY_REFERENCE
           , V_CA.GOO_EAN_CODE
           , V_CA.GOO_NUMBER_OF_DECIMAL
           , V_CA.A_DATECRE
           , V_CA.A_DATEMOD
           , V_CA.DES_SHORT_DESCRIPTION
           , V_CA.DES_LONG_DESCRIPTION
           , V_CA.DES_FREE_DESCRIPTION
           , V_CA.GCO_GOOD_CATEGORY_WORDING
           , V_CA.DIC_UNIT_OF_MEASURE_WORDING
           , V_CA.C_MNGMNT_MODE_WORDING1
           , DES.GCD_WORDING
        from GCO_PSEUDO_GOOD PSE
           , V_GCO_GOOD_CATALOGUE V_CA
           , GCO_GOOD_CATEGORY_DESCR DES
       where PSE.GCO_GOOD_ID = V_CA.GCO_GOOD_ID
         and V_CA.PC_LANG_ID = VPC_LANG_ID
         and V_CA.GCO_GOOD_CATEGORY_ID = DES.GCO_GOOD_CATEGORY_ID
         and DES.PC_LANG_ID = VPC_LANG_ID;
  end GCO_PSEUDO_FORM_BATCH_RPT_PK;

/**
*Description
*   STORED PROCEDURE USED GCO_PSEUDO_FORM_BATCH; GCO_SERVICE_FORM_BATCH
*/
  procedure GCO_DESCRIPTION_SUB_RPT_PK(arefcursor in out crystal_cursor_types.dualcursortyp, procuser_lanid in pcs.pc_lang.lanid%type, parameter_0 in number)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select V_DES.DES_SHORT_DESCRIPTION
           , V_DES.DES_LONG_DESCRIPTION
           , V_DES.DES_FREE_DESCRIPTION
           , V_DES.DES_SHORT_DESCR_ST
           , V_DES.DES_LONG_DESCR_ST
           , V_DES.DES_FREE_DESCR_ST
           , V_DES.DES_SHORT_DESCR_PU
           , V_DES.DES_LONG_DESCR_PU
           , V_DES.DES_FREE_DESCR_PU
           , V_DES.DES_SHORT_DESCR_SA
           , V_DES.DES_LONG_DESCR_SA
           , V_DES.DES_FREE_DESCR_SA
           , LAN.LANNAME
           , LAN.PC_LANG_ID
        from V_GOOD_DESCRIPTION V_DES
           , PCS.PC_LANG LAN
       where V_DES.PC_LANG_ID = LAN.PC_LANG_ID
         and V_DES.GCO_GOOD_ID = PARAMETER_0;
  end GCO_DESCRIPTION_SUB_RPT_PK;

/**
*Description
*   STORED PROCEDURE USED GCO_PSEUDO_FORM_BATCH; GCO_SERVICE_FORM_BATCH
*/
  procedure GCO_AUX_SUB_RPT_PK(arefcursor in out crystal_cursor_types.dualcursortyp, procuser_lanid in pcs.pc_lang.lanid%type, parameter_0 in number)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select GOO.GOO_MAJOR_REFERENCE
           , GOO.GOO_SECONDARY_REFERENCE
           , V_GOO.GCO_MULTIMEDIA_ELEMENT_ID
           , V_GOO.MME_MULTIMEDIA_DESIGNATION
           , V_GOO.MME_FREE_DESCRIPTION
           , V_GOO.GCO_SUBSTITUTION_LIST_ID
           , V_GOO.SUL_SUBST_DESIGN_SHORT
           , V_GOO.SUL_COMMENT
           , V_GOO.SUL_FROM_DATE
           , V_GOO.SUL_UNTIL_DATE
           , V_GOO.DIC_ACCOUNTABLE_GROUP_ID
           , V_GOO.DIC_ACCOUNTABLE_GROUP_WORDING
           , V_GOO.DIC_GOOD_LINE_ID
           , V_GOO.DIC_GOOD_LINE_WORDING
           , V_GOO.DIC_GOOD_FAMILY_ID
           , V_GOO.DIC_GOOD_FAMILY_WORDING
           , V_GOO.DIC_GOOD_MODEL_ID
           , V_GOO.DIC_GOOD_MODEL_WORDING
           , V_GOO.DIC_GOOD_GROUP_ID
           , V_GOO.DIC_GOOD_GROUP_WORDING
        from V_GCO_GOOD_LIST V_GOO
           , GCO_GOOD GOO
       where V_GOO.SUL_REPLACEMENT_GOOD_ID = GOO.GCO_GOOD_ID(+)
         and V_GOO.GCO_GOOD_ID = PARAMETER_0;
  end GCO_AUX_SUB_RPT_PK;

/**
*Description
*   STORED PROCEDURE USED GCO_SERVICE_FORM_BATCH
*/
  procedure GCO_SERVICE_FORM_BATCH_RPT_PK(arefcursor in out crystal_cursor_types.dualcursortyp, procuser_lanid in pcs.pc_lang.lanid%type)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select SER.GCO_GOOD_ID
           , V_GCA.GOO_MAJOR_REFERENCE
           , V_GCA.GOO_SECONDARY_REFERENCE
           , V_GCA.GOO_EAN_CODE
           , V_GCA.GOO_NUMBER_OF_DECIMAL
           , V_GCA.A_DATECRE
           , V_GCA.A_DATEMOD
           , V_GCA.DES_SHORT_DESCRIPTION
           , V_GCA.DES_LONG_DESCRIPTION
           , V_GCA.DES_FREE_DESCRIPTION
           , V_GCA.GCO_GOOD_CATEGORY_WORDING
           , V_GCA.DIC_UNIT_OF_MEASURE_WORDING
           , V_GCA.C_MNGMNT_MODE_WORDING1
           , DES.GCD_WORDING
        from GCO_SERVICE SER
           , V_GCO_GOOD_CATALOGUE V_GCA
           , GCO_GOOD_CATEGORY_DESCR DES
       where SER.GCO_GOOD_ID = V_GCA.GCO_GOOD_ID
         and V_GCA.PC_LANG_ID = 1
         and V_GCA.GCO_GOOD_CATEGORY_ID = DES.GCO_GOOD_CATEGORY_ID
         and DES.PC_LANG_ID = 1;
  end GCO_SERVICE_FORM_BATCH_RPT_PK;
end GCO_RPT;
