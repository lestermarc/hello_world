--------------------------------------------------------
--  DDL for Package Body DOC_GAU_RPT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_GAU_RPT" 
is
/**
*Description
*   STORED PROCEDURE USED GAU_FORM_STRUCTURED
*/
  procedure GAU_FORM_STRUCTURED_RPT_PK(AREFCURSOR in out Crystal_Cursor_Types.DUALCURSORTYP, PROCUSER_LANID in PCS.PC_LANG.LANID%type)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select DGD.GAD_DESCRIBE
           , V_DG.DOC_GAUGE_ID
           , V_DG.GAU_DESCRIBE
           , V_DG.C_GAUGE_STATUS_WORDING
           , V_DG.C_ADMIN_DOMAIN
           , V_DG.C_ADMIN_DOMAIN_WORDING
           , V_DG.C_GAUGE_TYPE
           , V_DG.C_GAUGE_TYPE_WORDING
           , V_DG.DIC_GAUGE_CATEG_ID
           , V_DG.GAUGE_CATEG_WORDING
           , V_DG.DIC_GAUGE_TYPE_DOC_ID
           , V_DG.GAUGE_TYPE_DOC_WORDING
           , V_DG.GAU_NUMBERING
           , V_DG.GAU_REF_PARTNER
           , V_DG.GAU_TRAVELLER
           , V_DG.GAU_DOSSIER
           , V_DG.GAU_EXPIRY
           , V_DG.GAU_EDIFACT
           , V_DG.GAU_EXPIRY_NBR
           , V_DG.PER_NAME
           , V_DG.GAN_DESCRIBE
           , V_DG.PC__PC_APPLTXT_ID
           , V_DG.TITEL_TEXT
           , V_DG.GAU_EDIT_NAME
           , V_DG.GAU_EDIT_NAME1
           , V_DG.GAU_EDIT_NAME2
           , V_DG.GAU_EDIT_NAME3
           , V_DG.GAU_EDIT_NAME4
           , V_DG.GAU_EDIT_NAME5
           , V_DG.GAU_EDIT_NAME6
           , V_DG.GAU_EDIT_NAME7
           , V_DG.GAU_EDIT_NAME8
           , V_DG.GAU_EDIT_NAME9
           , V_DG.GAU_EDIT_NAME10
           , V_DG.GAU_EDIT_TEXT
           , V_DG.GAU_EDIT_TEXT1
           , V_DG.GAU_EDIT_TEXT2
           , V_DG.GAU_EDIT_TEXT3
           , V_DG.GAU_EDIT_TEXT4
           , V_DG.GAU_EDIT_TEXT5
           , V_DG.GAU_EDIT_TEXT6
           , V_DG.GAU_EDIT_TEXT7
           , V_DG.GAU_EDIT_TEXT8
           , V_DG.GAU_EDIT_TEXT9
           , V_DG.GAU_EDIT_TEXT10
           , V_DG.C_GAUGE_FORM_TYPE
           , V_DG.GAUGE_FORM_TYPE1
           , V_DG.GAUGE_FORM_TYPE2
           , V_DG.GAUGE_FORM_TYPE3
           , V_DG.GAUGE_FORM_TYPE4
           , V_DG.GAUGE_FORM_TYPE5
           , V_DG.GAUGE_FORM_TYPE6
           , V_DG.GAUGE_FORM_TYPE7
           , V_DG.GAUGE_FORM_TYPE8
           , V_DG.GAUGE_FORM_TYPE9
           , V_DG.GAUGE_FORM_TYPE10
           , V_DG.GAU_EDIT_BOOL1
           , V_DG.GAU_EDIT_BOOL2
           , V_DG.GAU_EDIT_BOOL3
           , V_DG.GAU_EDIT_BOOL4
           , V_DG.GAU_EDIT_BOOL5
           , V_DG.GAU_EDIT_BOOL6
           , V_DG.GAU_EDIT_BOOL7
           , V_DG.GAU_EDIT_BOOL8
           , V_DG.GAU_EDIT_BOOL9
           , V_DG.GAU_EDIT_BOOL10
           , V_DG.GAU_CONFIRM_CANCEL
           , V_DG.C_GAUGE_RECORD_VERIFY
           , V_DG.C_GAU_AUTO_CREATE_RECORD
           , V_DG.GAU_SHOW_FORMS_ON_INSERT
           , V_DG.GAU_SHOW_FORMS_ON_UPDATE
           , V_DG.DIC_GAUGE_GROUP_ID
           , V_DG.GAU_INCOTERMS
           , V_DG.GAU_COLLATE_PRINTED_REPORTS
           , V_DG.C_GAUGE_TYPE_COMMENT_VISIBLE
           , V_DG.GAU_ALWAYS_SHOW_COMMENT
           , V_DG.GAU_CANCEL_STATUS
           , V_DG.GAU_SHOW_FORMS_ON_CONFIRM
           , V_DG.GAU_ASA_RECORD
           , V_DG.GAU_CONFIRM_STATUS
           , V_DG.GAU_HISTORY
           , V_DG.A_DATECRE
           , V_DG.A_DATEMOD
           , V_DGS.GAS_DIFFERED_CONFIRMATION
           , V_DGS.GAS_AUTH_BALANCE_RETURN
           , V_DGS.GAS_AUTH_BALANCE_NO_RETURN
           , PCS.PC_Functions.GetApplTxtLabel(V_DG.PC__PC_APPLTXT_ID, VPC_LANG_ID) APPLTXT
        from DOC_GAUGE_DESCRIPTION DGD
           , V_DOC_GAUGE V_DG
           , V_DOC_GAUGE_STRUCTURED V_DGS
       where V_DG.DOC_GAUGE_ID = DGD.DOC_GAUGE_ID(+)
         and V_DG.DOC_GAUGE_ID = V_DGS.DOC_GAUGE_ID(+)
         and V_DG.PC_LANG_ID = VPC_LANG_ID
         and DGD.PC_LANG_ID = VPC_LANG_ID
         and V_DGS.PC_LANG_ID = VPC_LANG_ID;
  end GAU_FORM_STRUCTURED_RPT_PK;

/**
*Description
*   STORED PROCEDURE USED GAU_FORM_STRUCTURED
*/
  procedure GAU_STRUCTURE_SUB_RPT_PK(
    AREFCURSOR      in out Crystal_Cursor_Types.DUALCURSORTYP
  , PROCUSER_LANID  in     PCS.PC_LANG.LANID%type
  , PM_DOC_GAUGE_ID in     varchar2
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select V_AFA.ACC_NUMBER
           , V_AFA.DES_DESCRIPTION_SUMMARY
           , V_DG.C_DIRECTION_NUMBER
           , V_DG.GAU_USE_MANAGED_DATA
           , V_DG.DIC_TYPE_DOC_CUSTOM_ID
           , V_DGS.C_GAUGE_TITLE
           , V_DGS.GCDTEXT1
           , V_DGS.DIC_TYPE_MOVEMENT_ID
           , V_DGS.DIC_DESCRIPTION
           , V_DGS.C_ROUND_TYPE
           , V_DGS.C_ROUND_TYPE_WORDING
           , V_DGS.GAS_ROUND_AMOUNT
           , V_DGS.GAS_POSITION__NUMBERING
           , V_DGS.GAS_MODIFY_NUMBERING
           , V_DGS.GAS_INCREMENT
           , V_DGS.GAS_FIRST_NO
           , V_DGS.GAS_INCREMENT_NBR
           , V_DGS.GAS_BALANCE_STATUS
           , V_DGS.GAS_PCENT
           , V_DGS.GAS_FINANCIAL_CHARGE
           , V_DGS.GAS_TOTAL_DOC
           , V_DGS.ACS_FIN_ACC_S_PAYMENT_ID
           , V_DGS.CAT_DESCRIPTION
           , V_DGS.GAS_FINANCIAL_REF
           , V_DGS.ACS_FINANCIAL_ACCOUNT_ID
           , V_DGS.GAS_GOOD_THIRD
           , V_DGS.GAS_WEIGHT
           , V_DGS.GAS_CORRELATION
           , V_DGS.GAS_SUBSTITUTE
           , V_DGS.GAS_CHARACTERIZATION
           , V_DGS.GAS_PAY_CONDITION
           , V_DGS.GAS_VAT
           , V_DGS.GAS_TAXE
           , V_DGS.C_TYPE_EDI
           , V_DGS.C_CONTROLE_DATE_DOCUM
           , V_DGS.C_CONTROLE_DATE_DOCUM_WORDING
           , V_DGS.GAS_ANAL_CHARGE
           , V_DGS.GAS_SENDING_CONDITION
           , V_DGS.GAS_CHANGE_ACC_S_PAYMENT
           , V_DGS.GAS_VISIBLE_COUNT
           , V_DGS.C_CREDIT_LIMIT
           , V_DGS.GAS_COMMISSION_MANAGEMENT
           , V_DGS.GAS_CALCULATE_COMMISSION
           , V_DGS.GAS_CASH_REGISTER
           , V_DGS.GAS_FORM_CASH_REGISTER
           , V_DGS.GAS_VAT_DET_ACCOUNT_VISIBLE
           , V_DGS.GAS_INIT_FREE_DATA
           , V_DGS.GAS_AUTO_ATTRIBUTION
           , V_DGS.PAC_PAYMENT_CONDITION_WORDING
           , V_DGS.C_BVR_GENERATION_METHOD
           , V_DGS.C_START_CONTROL_DATE
           , V_DGS.C_START_CONTROL_DATE_WORDING
           , V_DGS.C_DOC_PRE_ENTRY
           , V_DGS.C_DOC_PRE_ENTRY_THIRD
           , V_DGS.GAS_CALCUL_CREDIT_LIMIT
           , V_DGS.GAS_CREDIT_LIMIT_STATUS_01
           , V_DGS.GAS_CREDIT_LIMIT_STATUS_02
           , V_DGS.GAS_CREDIT_LIMIT_STATUS_03
           , V_DGS.GAS_CREDIT_LIMIT_STATUS_04
           , V_DGS.CAT_PMT_DESCRIPTION
           , V_DGS.GAS_UNIT_PRICE_DECIMAL
           , V_DGS.GAS_POS_QTY_DECIMAL
           , V_DGS.GAS_ALL_CHARACTERIZATION
           , V_DGS.GAS_CPN_ACCOUNT_MODIFY
           , V_DGS.GAS_AUTO_MRP
           , V_DGS.C_DOC_CREDITLIMIT_MODE
           , V_DGS.GAS_WEIGHING_MGM
           , V_DGS.GAS_WEIGHT_MAT
           , V_DGS.GAS_USE_PARTNER_DATE
           , V_DGS.GAS_COST
           , V_DGS.GAS_DISCOUNT
           , V_DGS.GAS_CHARGE
           , V_DGS.GAS_CASH_MULTIPLE_TRANSACTION
           , V_DGS.C_PIC_FORECAST_CONTROL
           , V_DGS.GAS_PREVIOUS_PERIODS_NB
           , V_DGS.GAS_FOLLOWING_PERIODS_NB
           , V_DGS.GAS_MULTISOURCING_MGM
        from V_DOC_GAUGE V_DG
           , V_DOC_GAUGE_STRUCTURED V_DGS
           , V_ACS_FINANCIAL_ACCOUNT V_AFA
           , V_ACS_DIVISION_ACCOUNT V_ADA
           , ACS_DESCRIPTION ADE
       where V_DG.DOC_GAUGE_ID = V_DGS.DOC_GAUGE_ID
         and V_DGS.PC_LANG_ID = V_AFA.PC_LANG_ID(+)
         and V_DGS.ACS_FINANCIAL_ACCOUNT_ID = V_AFA.ACS_FINANCIAL_ACCOUNT_ID(+)
         and V_DGS.PC_LANG_ID = V_ADA.PC_LANG_ID(+)
         and V_DGS.ACS_DIVISION_ACCOUNT_ID = V_ADA.ACS_DIVISION_ACCOUNT_ID(+)
         and V_DGS.PC_LANG_ID = ADE.PC_LANG_ID(+)
         and V_DGS.ACS_PAYMENT_METHOD_ID = ADE.ACS_PAYMENT_METHOD_ID(+)
         and V_DGS.PC_LANG_ID = VPC_LANG_ID
         and V_DG.PC_LANG_ID = VPC_LANG_ID
         and V_DG.DOC_GAUGE_ID = to_number(PM_DOC_GAUGE_ID);
  end GAU_STRUCTURE_SUB_RPT_PK;

/**
*Description
*   STORED PROCEDURE USED GAU_FORM_STRUCTURED
*/
  procedure GAU_HEADER_SUB_RPT_PK(AREFCURSOR in out Crystal_Cursor_Types.DUALCURSORTYP, PROCUSER_LANID in PCS.PC_LANG.LANID%type, PM_DOC_GAUGE_ID in varchar2)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select V_DG.HEADER_TEXT
           , V_DG.DOC_TEXT
           , V_DG.DIC_ADDRESS_TYPE_ID
           , V_DG.DIC_ADD_TYP_WORDING
           , V_DG.DIC_ADDRESS_TYPE1_ID
           , V_DG.DIC_ADD_TYP1_WORDING
           , V_DG.DIC_ADDRESS_TYPE2_ID
           , V_DG.DIC_ADD_TYP2_WORDING
        from V_DOC_GAUGE V_DG
       where V_DG.PC_LANG_ID = VPC_LANG_ID
         and V_DG.DOC_GAUGE_ID = to_number(PM_DOC_GAUGE_ID);
  end GAU_HEADER_SUB_RPT_PK;

/**
*Description
*   STORED PROCEDURE USED GAU_FORM_STRUCTURED
*/
  procedure GAU_POSITION_SUB_RPT_PK(
    AREFCURSOR      in out Crystal_Cursor_Types.DUALCURSORTYP
  , PROCUSER_LANID  in     PCS.PC_LANG.LANID%type
  , PM_DOC_GAUGE_ID in     varchar2
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select DDGP.GAP_DESIGNATION
           , DGP.C_GAUGE_TYPE_POS
           , DGP.C_GAUGE_INIT_PRICE_POS
           , DGP.GAP_VALUE
           , DGP.GAP_BLOC_ACCESS_VALUE
           , DGP.GAP_DELAY
           , DGP.C_GAUGE_SHOW_DELAY
           , DGP.C_ROUND_APPLICATION
           , DGP.GAP_POS_DELAY
           , DGP.GAP_PCENT
           , DGP.GAP_TXT
           , DGP.GAP_DEFAULT
           , DGP.GAP_STOCK_ACCESS
           , DGP.GAP_MVT_UTILITY
           , DGP.GAP_TRANS_ACCESS
           , DGP.GAP_INIT_STOCK_PLACE
           , DGP.GAP_DIRECT_REMIS
           , DGP.GAP_DESIGNATION
           , DGP.GAP_DELAY_COPY_PREV_POS
           , DGP.GAP_VALUE_QUANTITY
           , DGP.GAP_INCLUDE_TAX_TARIFF
           , DGP.DIC_TARIFF_ID
           , DGP.GAP_FORCED_TARIFF
           , DGP.GAP_STOCK_MVT
           , DGP.DIC_DELAY_UPDATE_TYPE_ID
           , DGP.STM_STOCK_ID
           , DGP.STM_LOCATION_ID
           , DGP.DOC_DOC_GAUGE_POSITION_ID
           , DGP.GAP_MRP
           , DGP.GAP_SQM_SHOW_DFLT
           , DGP.C_SQM_EVAL_TYPE
           , DGP.GAP_TRANSFERT_PROPRIETOR
           , DGP.GAP_ASA_TASK_IMPUT
           , DGP.DIC_TYPE_MOVEMENT_ID
           , GGD.GOO_MAJOR_REFERENCE
           , GGD.GOO_SECONDARY_REFERENCE
           , PAP.APH_CODE
           , SLO.LOC_DESCRIPTION
           , SMK.C_MOVEMENT_CODE
           , SMK.MOK_ABBREVIATION
           , SST.STO_DESCRIPTION
           , V_PDE.GCDTEXT1
           , V_PDE1.GCDTEXT1
           , PCS.PC_Functions.GetApplTxtLabel(DGP.PC_APPLTXT_ID, VPC_LANG_ID) APPLTXT
        from DOC_GAUGE_POSITION DDGP
           , DOC_GAUGE_POSITION DGP
           , GCO_GOOD GGD
           , PCS.PC_APPLTXT PAP
           , STM_LOCATION SLO
           , STM_MOVEMENT_KIND SMK
           , STM_STOCK SST
           , PCS.V_PC_DESCODES V_PDE
           , PCS.V_PC_DESCODES V_PDE1
       where DGP.C_GAUGE_TYPE_POS = V_PDE.GCLCODE
         and DGP.C_GAUGE_INIT_PRICE_POS = V_PDE1.GCLCODE
         and DGP.STM_MOVEMENT_KIND_ID = SMK.STM_MOVEMENT_KIND_ID(+)
         and DGP.GCO_GOOD_ID = GGD.GCO_GOOD_ID(+)
         and DGP.PC_APPLTXT_ID = PAP.PC_APPLTXT_ID(+)
         and DGP.STM_STOCK_ID = SST.STM_STOCK_ID(+)
         and DGP.STM_LOCATION_ID = SLO.STM_LOCATION_ID(+)
         and DGP.DOC_DOC_GAUGE_POSITION_ID = DDGP.DOC_GAUGE_POSITION_ID(+)
         and V_PDE.PC_LANG_ID = VPC_LANG_ID
         and V_PDE1.PC_LANG_ID = VPC_LANG_ID
         and V_PDE.GCGNAME = 'C_GAUGE_TYPE_POS'
         and V_PDE1.GCGNAME = 'C_GAUGE_INIT_PRICE_POS'
         and DGP.DOC_GAUGE_ID = to_number(PM_DOC_GAUGE_ID);
  end GAU_POSITION_SUB_RPT_PK;

/**
*Description
*   STORED PROCEDURE USED GAU_FORM_STRUCTURED
*/
  procedure GAU_FOOT_SUB_RPT_PK(AREFCURSOR in out Crystal_Cursor_Types.DUALCURSORTYP, PROCUSER_LANID in PCS.PC_LANG.LANID%type, PM_DOC_GAUGE_ID in varchar2)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select DGS.DOC_GAUGE_SIGNATORY_ID
           , DGS.GAG_NAME
           , DGS.GAG_FUNCTION
           , DGS1.DOC_GAUGE_SIGNATORY_ID
           , DGS1.GAG_NAME
           , DGS1.GAG_FUNCTION
           , V_PAP.APH_CODE
           , V_PAP.APT_LABEL
        from DOC_GAUGE DGA
           , DOC_GAUGE_SIGNATORY DGS
           , DOC_GAUGE_SIGNATORY DGS1
           , PCS.V_PC_APPLTXT V_PAP
       where DGA.DOC_GAUGE_SIGNATORY_ID = DGS.DOC_GAUGE_SIGNATORY_ID(+)
         and DGA.DOC_DOC_GAUGE_SIGNATORY_ID = DGS1.DOC_GAUGE_SIGNATORY_ID(+)
         and DGA.PC_3_PC_APPLTXT_ID = V_PAP.PC_APPLTXT_ID(+)
         and V_PAP.PC_LANG_ID = VPC_LANG_ID
         and DGA.DOC_GAUGE_ID = to_number(PM_DOC_GAUGE_ID);
  end GAU_FOOT_SUB_RPT_PK;

/**
*Description
*   STORED PROCEDURE USED GAU_FORM_SIMPLE
*/
  procedure GAU_FORM_SIMPLE_RPT_PK(AREFCURSOR in out Crystal_Cursor_Types.DUALCURSORTYP, PROCUSER_LANID in PCS.PC_LANG.LANID%type)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select V_DG.DOC_GAUGE_ID
           , V_DG.GAU_DESCRIBE
           , V_DG.C_GAUGE_STATUS_WORDING
           , V_DG.C_ADMIN_DOMAIN
           , V_DG.C_ADMIN_DOMAIN_WORDING
           , V_DG.C_GAUGE_TYPE
           , V_DG.C_GAUGE_TYPE_WORDING
           , V_DG.DIC_GAUGE_CATEG_ID
           , V_DG.GAUGE_CATEG_WORDING
           , V_DG.DIC_GAUGE_TYPE_DOC_ID
           , V_DG.GAUGE_TYPE_DOC_WORDING
           , V_DG.GAU_NUMBERING
           , V_DG.GAU_REF_PARTNER
           , V_DG.GAU_TRAVELLER
           , V_DG.GAU_DOSSIER
           , V_DG.GAU_EXPIRY
           , V_DG.GAU_EDIFACT
           , V_DG.GAU_EXPIRY_NBR
           , V_DG.PER_NAME
           , V_DG.GAN_DESCRIBE
           , V_DG.TITEL_TEXT
           , V_DG.GAU_EDIT_NAME
           , V_DG.GAU_EDIT_NAME1
           , V_DG.GAU_EDIT_NAME2
           , V_DG.GAU_EDIT_NAME3
           , V_DG.GAU_EDIT_NAME4
           , V_DG.GAU_EDIT_NAME5
           , V_DG.GAU_EDIT_TEXT
           , V_DG.GAU_EDIT_TEXT1
           , V_DG.GAU_EDIT_TEXT2
           , V_DG.GAU_EDIT_TEXT3
           , V_DG.GAU_EDIT_TEXT4
           , V_DG.GAU_EDIT_TEXT5
           , V_DG.C_GAUGE_FORM_TYPE
           , V_DG.GAUGE_FORM_TYPE1
           , V_DG.GAUGE_FORM_TYPE2
           , V_DG.GAUGE_FORM_TYPE3
           , V_DG.GAUGE_FORM_TYPE4
           , V_DG.GAUGE_FORM_TYPE5
           , V_DG.GAU_EDIT_BOOL1
           , V_DG.GAU_EDIT_BOOL2
           , V_DG.GAU_EDIT_BOOL3
           , V_DG.GAU_EDIT_BOOL4
           , V_DG.GAU_EDIT_BOOL5
           , V_DG.A_DATECRE
           , V_DG.A_DATEMOD
           , DGD.GAD_DESCRIBE
        from V_DOC_GAUGE V_DG
           , DOC_GAUGE_DESCRIPTION DGD
       where V_DG.DOC_GAUGE_ID = DGD.DOC_GAUGE_ID(+)
         and V_DG.PC_LANG_ID = VPC_LANG_ID
         and DGD.PC_LANG_ID(+) = VPC_LANG_ID;
  end GAU_FORM_SIMPLE_RPT_PK;

  procedure GAU_FLOW_DATA_RPT_PK(AREFCURSOR in out Crystal_Cursor_Types.DUALCURSORTYP, PROCUSER_LANID in PCS.PC_LANG.LANID%type)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select 'DISCHARGE' code
           , dgf.gaf_describe
           , dgf.gaf_version
           , c_gaf_flow_status
           , gaf_comment
           , gad.gad_seq
           , des.gad_describe src
           , gad.gad_seq seq_dst
           , des_dst.gad_describe dst
           , gar_quantity_exceed
           , gar_good_changing
           , gar_partner_changing
           , gar_extourne_mvt
           , gar_balance_parent
           , gar_transfert_price
           , gar_transfert_quantity
           , gar_init_price_mvt
           , gar_init_qty_mvt
           , gar_part_discharge
           , gar_transfert_stock
           , gar_transfert_descr
           , gar_transfert_remise_taxe
           , gar_init_cost_price
           , gar_transfer_mvmt_swap
           , gar_invert_amount
           , gar_transfert_record
           , gar_transfert_represent
           , gar_transfert_free_data
           , gar_transfert_price_mvt
           , gar_transfert_precious_mat
           , null gac_transfert_price
           , null gac_transfert_quantity
           , null gac_init_price_mvt
           , null gac_init_qty_mvt
           , null gac_bond
           , null gac_part_copy
           , null gac_transfert_stock
           , null gac_transfert_descr
           , null gac_transfert_remise_taxe
           , null gac_transfert_record
           , null gac_transfert_represent
           , null gac_transfert_free_data
           , null gac_transfert_price_mvt
           , null gac_init_cost_price
           , null gac_transfert_charact
           , null gac_transfert_precious_mat
           , gau.doc_gauge_id gauge_src_id
           , gau_dst.doc_gauge_id gauge_dst_id
           , gar.doc_gauge_receipt_id
           , gad.doc_gauge_flow_docum_id flow_docum_src_id
           , dgf.doc_gauge_flow_id
        from doc_gauge gau
           , doc_gauge gau_dst
           , doc_gauge_receipt gar
           , doc_gauge_flow_docum gad
           , doc_gauge_flow dgf
           , doc_gauge_description des
           , doc_gauge_description des_dst
       where gad.doc_gauge_id = gau.doc_gauge_id
         and gar.doc_gauge_flow_docum_id = gad.doc_gauge_flow_docum_id
         and gau_dst.doc_gauge_id = gar.doc_doc_gauge_id
         and gad.doc_gauge_flow_id = dgf.doc_gauge_flow_id
         and gau.doc_gauge_id = des.doc_gauge_id(+)
         and des.pc_lang_id(+) = pcs.pc_public.getuserlangid
         and gau_dst.doc_gauge_id = des_dst.doc_gauge_id(+)
         and des_dst.pc_lang_id(+) = VPC_LANG_ID
      union all
      select 'COPY' code
           , dgf.gaf_describe
           , gaf_version
           , c_gaf_flow_status
           , gaf_comment
           , gad.gad_seq
           , des.gad_describe src
           , gad.gad_seq seq_dst
           , des_dst.gad_describe dst
           , null gar_quantity_exceed
           , null gar_good_changing
           , null gar_partner_changing
           , null gar_extourne_mvt
           , null gar_balance_parent
           , null gar_transfert_price
           , null gar_transfert_quantity
           , null gar_init_price_mvt
           , null gar_init_qty_mvt
           , null gar_part_discharge
           , null gar_transfert_stock
           , null gar_transfert_descr
           , null gar_transfert_remise_taxe
           , null gar_init_cost_price
           , null gar_transfer_mvmt_swap
           , null gar_invert_amount
           , null gar_transfert_record
           , null gar_transfert_represent
           , null gar_transfert_free_data
           , null gar_transfert_price_mvt
           , null gar_transfert_precious_mat
           , gac_transfert_price
           , gac_transfert_quantity
           , gac_init_price_mvt
           , gac_init_qty_mvt
           , gac_bond
           , gac_part_copy
           , gac_transfert_stock
           , gac_transfert_descr
           , gac_transfert_remise_taxe
           , gac_transfert_record
           , gac_transfert_represent
           , gac_transfert_free_data
           , gac_transfert_price_mvt
           , gac_init_cost_price
           , gac_transfert_charact
           , gac_transfert_precious_mat
           , gau.doc_gauge_id
           , gau_dst.doc_gauge_id
           , gar.doc_gauge_copy_id
           , gad.doc_gauge_flow_docum_id
           , dgf.doc_gauge_flow_id
        from doc_gauge gau
           , doc_gauge gau_dst
           , doc_gauge_copy gar
           , doc_gauge_flow_docum gad
           , doc_gauge_flow dgf
           , doc_gauge_description des
           , doc_gauge_description des_dst
       where gad.doc_gauge_id = gau.doc_gauge_id
         and gar.doc_gauge_flow_docum_id = gad.doc_gauge_flow_docum_id
         and gau_dst.doc_gauge_id = gar.doc_doc_gauge_id
         and gad.doc_gauge_flow_id = dgf.doc_gauge_flow_id
         and gau.doc_gauge_id = des.doc_gauge_id(+)
         and des.pc_lang_id(+) = pcs.pc_public.getuserlangid
         and gau_dst.doc_gauge_id = des_dst.doc_gauge_id(+)
         and des_dst.pc_lang_id(+) = VPC_LANG_ID;
  end GAU_FLOW_DATA_RPT_PK;
end DOC_GAU_RPT;
