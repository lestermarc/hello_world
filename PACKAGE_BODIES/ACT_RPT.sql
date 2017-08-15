--------------------------------------------------------
--  DDL for Package Body ACT_RPT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACT_RPT" 
is
/*
* Description
* STORED PROCEDURE USED FOR REPORT ACT_JOB_PRE_BATCH.RPT
*/
  procedure ACT_JOB_PRE_BATCH_RPT_PK(
    aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , PARAMETER_1    in     number
  , PARAMETER_2    in     varchar2
  , PARAMETER_3    in     varchar2
  , PARAMETER_4    in     number
  , PARAMETER_5    in     varchar2
  , PROCUSER_LANID in     pcs.pc_lang.lanid%type
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open aRefCursor for
      select CAT.ACJ_CATALOGUE_DOCUMENT_ID
           , CAT.C_TYPE_CATALOGUE
           , ACJ_FUNCTIONS.TranslateCatDescr(CAT.ACJ_CATALOGUE_DOCUMENT_ID, VPC_LANG_ID) CAT_DESCRIPTION
           , TYP.ACJ_JOB_TYPE_ID
           , TYP.TYP_SUPPLIER_PERMANENT
           , YEA.FYE_NO_EXERCICE
           , DOC.ACT_DOCUMENT_ID
           , DOC.DOC_NUMBER
           , DOC.DOC_TOTAL_AMOUNT_DC
           , DOC.DOC_DOCUMENT_DATE
           , DOC.DOC_PRE_ENTRY_EXPIRY
           , DOC.DOC_PRE_ENTRY_VALIDATION
           , DOC.DOC_PRE_ENTRY_INI
           , JOB.ACT_JOB_ID
           , JOB.JOB_DESCRIPTION
           , JOB.ACS_FINANCIAL_YEAR_ID
           , CUR.CURRENCY
           , USR.PC_USER_ID
           , USR.USE_NAME
           , USR.USE_DESCR
           , IMP.PAR_DOCUMENT
           , PER.PER_NAME CUS_NAME
           , PER.PER_FORENAME CUS_FORNAME
           , PER2.PER_NAME SUP_NAME
           , PER2.PER_FORENAME SUP_FORNAME
        from ACJ_CATALOGUE_DOCUMENT CAT
           , ACJ_JOB_TYPE TYP
           , ACS_FINANCIAL_CURRENCY FUR
           , ACS_FINANCIAL_YEAR YEA
           , ACT_DOCUMENT DOC
           , ACT_JOB JOB
           , PCS.PC_CURR CUR
           , PCS.PC_USER USR
           , ACT_PART_IMPUTATION IMP
           , PAC_PERSON PER
           , PAC_PERSON PER2
       where JOB.ACT_JOB_ID = DOC.ACT_JOB_ID(+)
         and DOC.PC_USER_ID = USR.PC_USER_ID(+)
         and DOC.ACS_FINANCIAL_CURRENCY_ID = FUR.ACS_FINANCIAL_CURRENCY_ID(+)
         and FUR.PC_CURR_ID = CUR.PC_CURR_ID(+)
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID(+)
         and JOB.ACJ_JOB_TYPE_ID = TYP.ACJ_JOB_TYPE_ID
         and JOB.ACS_FINANCIAL_YEAR_ID = YEA.ACS_FINANCIAL_YEAR_ID
         and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
         and IMP.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID(+)
         and IMP.PAC_SUPPLIER_PARTNER_ID = PER2.PAC_PERSON_ID(+)
         and JOB.ACS_FINANCIAL_YEAR_ID = PARAMETER_4
         and TYP.TYP_SUPPLIER_PERMANENT = 1
         and JOB.JOB_DESCRIPTION >= PARAMETER_2
         and JOB.JOB_DESCRIPTION <= PARAMETER_3
         and ACT_FUNCTIONS.IsUserAutorizedForJobType(PARAMETER_5, JOB.ACJ_JOB_TYPE_ID) = 1
         and PARAMETER_1 = 0
         and TYP.ACJ_JOB_TYPE_ID = PARAMETER_1;
  end ACT_JOB_PRE_BATCH_RPT_PK;

/*
* Description
* STORED PROCEDURE USED FOR REPORT ACT_JOB.RPT
*/
  procedure ACT_JOB_RPT_PK(aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp, PARAMETER_0 in varchar2, PROCUSER_LANID in pcs.pc_lang.lanid%type)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open aRefCursor for
      select CAT.ACJ_CATALOGUE_DOCUMENT_ID
           , ACJ_FUNCTIONS.TranslateCatDescr(CAT.ACJ_CATALOGUE_DOCUMENT_ID, VPC_LANG_ID) CAT_DESCRIPTION
           , FUR.FIN_LOCAL_CURRENCY
           , DOC.ACT_DOCUMENT_ID
           , DOC.DOC_NUMBER
           , DOC.DOC_TOTAL_AMOUNT_DC
           , DOC.DOC_DOCUMENT_DATE
           , DOC.ACT_JOURNAL_ID
           , DOC.ACT_ACT_JOURNAL_ID
           , JOB.ACT_JOB_ID
           , JOB.JOB_DESCRIPTION
           , JOB.ACS_FINANCIAL_YEAR_ID
           , JOB.A_DATECRE
           , JOB.A_DATEMOD
           , JOB.A_IDCRE
           , JOB.A_IDMOD
           , CUR.CURRENCY
        from ACJ_CATALOGUE_DOCUMENT CAT
           , ACJ_JOB_TYPE TYP
           , ACS_FINANCIAL_CURRENCY FUR
           , ACS_FINANCIAL_YEAR YEA
           , ACT_DOCUMENT DOC
           , ACT_JOB JOB
           , PCS.PC_CURR CUR
       where JOB.ACT_JOB_ID = DOC.ACT_JOB_ID(+)
         and DOC.ACS_FINANCIAL_CURRENCY_ID = FUR.ACS_FINANCIAL_CURRENCY_ID(+)
         and FUR.PC_CURR_ID = CUR.PC_CURR_ID(+)
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID(+)
         and JOB.ACJ_JOB_TYPE_ID = TYP.ACJ_JOB_TYPE_ID
         and JOB.ACS_FINANCIAL_YEAR_ID = YEA.ACS_FINANCIAL_YEAR_ID
         and JOB.ACT_JOB_ID = to_number(PARAMETER_0);
  end ACT_JOB_RPT_PK;

/*
* Description
* STORED PROCEDURE USED FOR REPORT ACT_PART_IMPUTATION.RPT, THE SUB REPORT OF ACT_JOB.RPT
*/
  procedure ACT_PART_IMP_SUB_RPT_PK(aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp, PARAMETER_1 in number, PROCUSER_LANID in pcs.pc_lang.lanid%type)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open aRefCursor for
      select FMP.IMF_AMOUNT_LC_D
           , FMP.IMF_AMOUNT_LC_C
           , FMP.IMF_AMOUNT_FC_D
           , FMP.IMF_AMOUNT_FC_C
           , FMP.ACS_AUXILIARY_ACCOUNT_ID
           , FMP.ACS_FINANCIAL_CURRENCY_ID
           , FMP.ACS_ACS_FINANCIAL_CURRENCY_ID
           , IMP.PAR_DOCUMENT
           , CUS.PAC_PERSON_ID CUS_PERSON_ID
           , CUS.PER_NAME CUS_NAME
           , CUS.PER_FORENAME CUS_FORENAME
           , SUP.PAC_PERSON_ID SUP_PERSON_ID
           , SUP.PER_NAME SUP_NAME
           , SUP.PER_FORENAME SUP_FORENAME
           , CMB.CURRENCY CURRENCY_MB
           , CME.CURRENCY CURRENCY_ME
        from ACT_PART_IMPUTATION IMP
           , PAC_PERSON CUS
           , PAC_PERSON SUP
           , ACT_FINANCIAL_IMPUTATION FMP
           , ACS_FINANCIAL_CURRENCY FMB
           , ACS_FINANCIAL_CURRENCY FME
           , PCS.PC_CURR CMB
           , PCS.PC_CURR CME
       where IMP.ACT_DOCUMENT_ID = PARAMETER_1
         and IMP.PAC_CUSTOM_PARTNER_ID = CUS.PAC_PERSON_ID(+)
         and IMP.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_PERSON_ID(+)
         and IMP.ACT_PART_IMPUTATION_ID = FMP.ACT_PART_IMPUTATION_ID(+)
         and FMP.ACS_ACS_FINANCIAL_CURRENCY_ID = FMB.ACS_FINANCIAL_CURRENCY_ID(+)
         and FMP.ACS_FINANCIAL_CURRENCY_ID = FME.ACS_FINANCIAL_CURRENCY_ID(+)
         and FMB.PC_CURR_ID = CMB.PC_CURR_ID(+)
         and FME.PC_CURR_ID = CME.PC_CURR_ID(+)
         and FMP.ACS_AUXILIARY_ACCOUNT_ID is not null;
  end ACT_PART_IMP_SUB_RPT_PK;

/*
* Description
* STORED PROCEDURE USED FOR REPORT ACT_REMINDER.RPT, THE SUB REPORT OF ACT_JOB.RPT
*/
  procedure ACT_REMINDER_SUB_RPT_PK(aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp, PARAMETER_1 in number, PROCUSER_LANID in pcs.pc_lang.lanid%type)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open aRefCursor for
      select ATD.DOC_NUMBER
           , exp.EXP_ADAPTED
           , exp.EXP_AMOUNT_LC
           , exp.EXP_AMOUNT_FC
           , IMP.IMF_PRIMARY
           , IMP.IMF_TRANSACTION_DATE
           , RMD.ACS_FINANCIAL_CURRENCY_ID
           , RMD.ACS_ACS_FINANCIAL_CURRENCY_ID
           , RMD.REM_PAYABLE_AMOUNT_LC
           , RMD.REM_PAYABLE_AMOUNT_FC
           , RMD.REM_NUMBER
           , CUS.PAC_PERSON_ID CUS_PERSON_ID
           , CUS.PER_NAME CUS_NAME
           , SUP.PAC_PERSON_ID SUP_PERSON_ID
           , SUP.PER_NAME SUP_NAME
        from ACT_REMINDER RMD
           , ACT_EXPIRY exp
           , ACT_PART_IMPUTATION PAR
           , ACT_DOCUMENT ATD
           , PAC_PERSON CUS
           , PAC_PERSON SUP
           , ACT_FINANCIAL_IMPUTATION IMP
       where RMD.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
         and RMD.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
         and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
         and PAR.ACT_DOCUMENT_ID = ATD.ACT_DOCUMENT_ID
         and ATD.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
         and PAR.PAC_CUSTOM_PARTNER_ID = CUS.PAC_PERSON_ID(+)
         and PAR.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_PERSON_ID(+)
         and IMP.IMF_PRIMARY = 1
         and RMD.ACT_DOCUMENT_ID = PARAMETER_1;
  end ACT_REMINDER_SUB_RPT_PK;

/*
* Description
* STORED PROCEDURE USED FOR REPORT ACT_JOB_BATCH.RPT
*/
  procedure ACT_JOB_BATCH_RPT_PK(
    aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , PARAMETER_00   in     varchar2
  , PARAMETER_1    in     number
  , PARAMETER_2    in     varchar2
  , PARAMETER_3    in     varchar2
  , PARAMETER_4    in     number
  , PARAMETER_5    in     varchar2
  , PROCUSER_LANID in     pcs.pc_lang.lanid%type
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open aRefCursor for
      select CAT.ACJ_CATALOGUE_DOCUMENT_ID
           , ACJ_FUNCTIONS.TranslateCatDescr(CAT.ACJ_CATALOGUE_DOCUMENT_ID, VPC_LANG_ID) CAT_DESCRIPTION
           , FUR.FIN_LOCAL_CURRENCY
           , DOC.ACT_DOCUMENT_ID
           , DOC.DOC_NUMBER
           , DOC.DOC_TOTAL_AMOUNT_DC
           , DOC.DOC_DOCUMENT_DATE
           , DOC.ACT_JOURNAL_ID
           , DOC.ACT_ACT_JOURNAL_ID
           , JOB.ACT_JOB_ID
           , JOB.JOB_DESCRIPTION
           , JOB.ACS_FINANCIAL_YEAR_ID
           , JOB.A_DATECRE
           , JOB.A_DATEMOD
           , JOB.A_IDCRE
           , JOB.A_IDMOD
           , CUR.CURRENCY
        from ACJ_CATALOGUE_DOCUMENT CAT
           , ACJ_JOB_TYPE TYP
           , ACS_FINANCIAL_CURRENCY FUR
           , ACS_FINANCIAL_YEAR YEA
           , ACT_DOCUMENT DOC
           , ACT_JOB JOB
           , PCS.PC_CURR CUR
       where JOB.ACT_JOB_ID = DOC.ACT_JOB_ID(+)
         and DOC.ACS_FINANCIAL_CURRENCY_ID = FUR.ACS_FINANCIAL_CURRENCY_ID(+)
         and FUR.PC_CURR_ID = CUR.PC_CURR_ID(+)
         and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID(+)
         and JOB.ACJ_JOB_TYPE_ID = TYP.ACJ_JOB_TYPE_ID
         and JOB.ACS_FINANCIAL_YEAR_ID = YEA.ACS_FINANCIAL_YEAR_ID
         and JOB.ACS_FINANCIAL_YEAR_ID = PARAMETER_4
         and TYP.ACJ_JOB_TYPE_ID = PARAMETER_1
         and ACT_FUNCTIONS.IsUserAutorizedForJobType(PARAMETER_5, JOB.ACJ_JOB_TYPE_ID) = 1
         and (        (PARAMETER_2 <> PARAMETER_3)
                 and (    PARAMETER_2 is not null
                      and PARAMETER_3 is not null)
                 and (    JOB.JOB_DESCRIPTION >= PARAMETER_2
                      and JOB.JOB_DESCRIPTION <= PARAMETER_3)
              or (     (PARAMETER_2 <> PARAMETER_3)
                  and (    PARAMETER_2 is not null
                       and PARAMETER_3 is null)
                  and (JOB.JOB_DESCRIPTION >= PARAMETER_2) )
              or (     (PARAMETER_2 <> PARAMETER_3)
                  and (    PARAMETER_2 is null
                       and PARAMETER_3 is not null)
                  and (JOB.JOB_DESCRIPTION <= PARAMETER_3) )
              --OR ((PARAMETER_2 = PARAMETER_3 AND PARAMETER_2 IS NOT NULL AND PARAMETER_3 IS NOT NULL) AND (JOB.JOB_DESCRIPTION = PARAMETER_2))
              or (    PARAMETER_2 is null
                  and PARAMETER_3 is null
                  and PARAMETER_00 = 0)
              or (    not(    PARAMETER_2 is null
                          and PARAMETER_3 is null
                          and PARAMETER_00 = 0)
                  and JOB.ACT_JOB_ID = PARAMETER_00)
             );
  end ACT_JOB_BATCH_RPT_PK;

/*
* Description
* STORED PROCEDURE USED FOR REPORT ACT_JOB_BATCH.RPT
*/
  procedure ACT_JOB_AUX_CTRL_RPT_PK(
    aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , PARAMETER_00   in     number
  , PARAMETER_01   in     number
  , PARAMETER_02   in     varchar2
  , PARAMETER_03   in     varchar2
  , PARAMETER_04   in     number
  , PARAMETER_05   in     number
  , PROCUSER_LANID in     pcs.pc_lang.lanid%type
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open aRefCursor for
      select ACJ_FUNCTIONS.TranslateCatDescr(CAT.ACJ_CATALOGUE_DOCUMENT_ID, VPC_LANG_ID) CAT_DESCRIPTION
           , TYP.ACJ_JOB_TYPE_ID
           , ACC.ACS_ACCOUNT_ID
           , ACC.ACC_NUMBER
           , ACC_AUX.ACS_ACCOUNT_ID AUX_ACCOUNT_ID
           , ACC_AUX.ACC_NUMBER AUX_ACC_NUMBER
           , ACC_DIV.ACS_ACCOUNT_ID DIV_ACCOUNT_ID
           , ACC_DIV.ACC_NUMBER DIV_ACC_NUMBER
           , DIV.ACS_DIVISION_ACCOUNT_ID
           , FCC.ACS_FINANCIAL_ACCOUNT_ID
           , FCC.FIN_COLLECTIVE
           , ATD.ACT_DOCUMENT_ID
           , ATD.DOC_NUMBER
           , IMP.IMF_AMOUNT_LC_D
           , IMP.IMF_AMOUNT_LC_C
           , IMP.IMF_AMOUNT_FC_D
           , IMP.IMF_AMOUNT_FC_C
           , IMP.IMF_TRANSACTION_DATE
           , JOB.ACT_JOB_ID
           , JOB.JOB_DESCRIPTION
           , JOB.ACJ_JOB_TYPE_ID
           , JOB.ACS_FINANCIAL_YEAR_ID
           , PAR.PAR_DOCUMENT
           , PAR.DOC_DATE_DELIVERY
           , CUS.PER_SHORT_NAME CUS_SHORT_NAME
           , CUS.PAC_PERSON_ID CUS_PERSON_ID
           , CUS.PER_NAME CUS_NAME
           , SUP.PER_SHORT_NAME SUP_SHORT_NAME
           , SUP.PAC_PERSON_ID SUP_PERSON_ID
           , SUP.PER_NAME SUP_NAME
           , CUR_ME.CURRENCY CURRENCY_ME
           , CUR_MB.CURRENCY CURRENCY_MB
           , DES_DIV.DES_DESCRIPTION_SUMMARY DIV_DESCRIPTION_SUMMARY
           , DES_FIN.DES_DESCRIPTION_SUMMARY FIN_DESCRIPTION_SUMMARY
           , ACS_FUNCTION.GetLocalCurrencyName C_monnaie_MB
        from ACT_JOB JOB
           , ACT_DOCUMENT ATD
           , ACT_FINANCIAL_IMPUTATION IMP
           , ACT_FINANCIAL_DISTRIBUTION DIS
           , ACS_FINANCIAL_ACCOUNT FCC
           , ACS_DIVISION_ACCOUNT DIV
           , ACS_ACCOUNT ACC
           , ACS_ACCOUNT ACC_DIV
           , ACS_ACCOUNT ACC_AUX
           , ACT_PART_IMPUTATION PAR
           , ACS_FINANCIAL_CURRENCY FCR_ME
           , ACS_FINANCIAL_CURRENCY FCR_MB
           , PCS.PC_CURR CUR_ME
           , PCS.PC_CURR CUR_MB
           , PAC_PERSON CUS
           , PAC_PERSON SUP
           , ACJ_CATALOGUE_DOCUMENT CAT
           , ACJ_JOB_TYPE TYP
           , ACS_DESCRIPTION DES_FIN
           , ACS_DESCRIPTION DES_DIV
       where JOB.ACT_JOB_ID = ATD.ACT_JOB_ID(+)
         and ATD.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID(+)
         and IMP.ACT_FINANCIAL_IMPUTATION_ID = DIS.ACT_FINANCIAL_IMPUTATION_ID(+)
         and DIS.ACS_DIVISION_ACCOUNT_ID = DIV.ACS_DIVISION_ACCOUNT_ID(+)
         and DIS.ACS_DIVISION_ACCOUNT_ID = ACC_DIV.ACS_ACCOUNT_ID(+)
         and IMP.ACS_FINANCIAL_ACCOUNT_ID = FCC.ACS_FINANCIAL_ACCOUNT_ID(+)
         and IMP.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID(+)
         and IMP.ACS_AUXILIARY_ACCOUNT_ID = ACC_AUX.ACS_ACCOUNT_ID(+)
         and IMP.ACS_FINANCIAL_CURRENCY_ID = FCR_ME.ACS_FINANCIAL_CURRENCY_ID(+)
         and IMP.ACS_ACS_FINANCIAL_CURRENCY_ID = FCR_MB.ACS_FINANCIAL_CURRENCY_ID(+)
         and FCR_ME.PC_CURR_ID = CUR_ME.PC_CURR_ID(+)
         and FCR_MB.PC_CURR_ID = CUR_MB.PC_CURR_ID(+)
         and IMP.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID(+)
         and PAR.PAC_CUSTOM_PARTNER_ID = CUS.PAC_PERSON_ID(+)
         and PAR.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_PERSON_ID(+)
         and ATD.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID(+)
         and JOB.ACJ_JOB_TYPE_ID = TYP.ACJ_JOB_TYPE_ID(+)
         and FCC.ACS_FINANCIAL_ACCOUNT_ID = DES_FIN.ACS_ACCOUNT_ID(+)
         and DES_FIN.PC_LANG_ID(+) = VPC_LANG_ID
         and DIV.ACS_DIVISION_ACCOUNT_ID = DES_DIV.ACS_ACCOUNT_ID(+)
         and DES_DIV.PC_LANG_ID(+) = VPC_LANG_ID
         and JOB.ACS_FINANCIAL_YEAR_ID = PARAMETER_04
         and ACT_FUNCTIONS.IsUserAutorizedForJobType(PARAMETER_05, JOB.ACJ_JOB_TYPE_ID) = 1
         and (        (PARAMETER_02 <> PARAMETER_03)
                 and (    PARAMETER_02 is not null
                      and PARAMETER_03 is not null)
                 and (    JOB.JOB_DESCRIPTION >= PARAMETER_02
                      and JOB.JOB_DESCRIPTION <= PARAMETER_03)
              or (     (PARAMETER_02 <> PARAMETER_03)
                  and (    PARAMETER_02 is not null
                       and PARAMETER_03 is null)
                  and (JOB.JOB_DESCRIPTION >= PARAMETER_02) )
              or (     (PARAMETER_02 <> PARAMETER_03)
                  and (    PARAMETER_02 is null
                       and PARAMETER_03 is not null)
                  and (JOB.JOB_DESCRIPTION <= PARAMETER_03) )
              --OR ((PARAMETER_02 = PARAMETER_03 AND PARAMETER_02 IS NOT NULL AND PARAMETER_03 IS NOT NULL) AND (JOB.JOB_DESCRIPTION = PARAMETER_02))
              or (    PARAMETER_02 is null
                  and PARAMETER_03 is null
                  and PARAMETER_00 = 0)
              or (    not(    PARAMETER_02 is null
                          and PARAMETER_03 is null
                          and PARAMETER_00 = 0)
                  and JOB.ACT_JOB_ID = PARAMETER_00
                  and TYP.ACJ_JOB_TYPE_ID = PARAMETER_01
                 )
             );
  end ACT_JOB_AUX_CTRL_RPT_PK;

/*
* Description
* STORED PROCEDURE USED FOR REPORT ACT_JOURNAL_AUX.RPT
*/
  procedure ACT_JOURNAL_AUX_RPT_PK(
    aRefCursor             in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , aJOU_NUMBER_From       in     varchar2
  , aJOU_NUMBER_To         in     varchar2
  , aACS_FINANCIAL_YEAR_ID in     varchar2
  , PARAMETER_0            in     varchar2
  , PROCUSER_LANID         in     pcs.pc_lang.lanid%type
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    if     (aJOU_NUMBER_From is not null)
       and (length(trim(aJOU_NUMBER_From) ) > 0) then
      ACR_FUNCTIONS.JOU_NUMBER1  := aJOU_NUMBER_From;
    else
      ACR_FUNCTIONS.JOU_NUMBER1  := ' ';
    end if;

    if     (aJOU_NUMBER_To is not null)
       and (length(trim(aJOU_NUMBER_To) ) > 0) then
      ACR_FUNCTIONS.JOU_NUMBER2  := aJOU_NUMBER_To;
    end if;

    if     (aACS_FINANCIAL_YEAR_ID is not null)
       and (length(trim(aACS_FINANCIAL_YEAR_ID) ) > 0) then
      ACR_FUNCTIONS.FIN_YEAR_ID  := aACS_FINANCIAL_YEAR_ID;
    end if;

    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open aRefCursor for
      select DES.PC_LANG_ID
           , DES.DES_DESCRIPTION_SUMMARY
           , FUR_ME.PC_CURR_ID ME_CURR_ID
           , FUR_MB.PC_CURR_ID MB_CURR_ID
           , ATD.ACT_DOCUMENT_ID
           , ATD.ACT_JOB_ID
           , ATD.DOC_NUMBER
           , ATD.DOC_DOCUMENT_DATE
           , DIS.ACS_DIVISION_ACCOUNT_ID
           , PAR.ACT_PART_IMPUTATION_ID
           , PAR.PAR_DOCUMENT
           , PAR.PAC_CUSTOM_PARTNER_ID
           , PAR.PAC_SUPPLIER_PARTNER_ID
           , PAR.DOC_DATE_DELIVERY
           , CUR_MB.CURRENCY MB_CURRENCY
           , CUR_ME.CURRENCY ME_CURRENCY
           , PTJ.ACT_FINANCIAL_IMPUTATION_ID
           , PTJ.ACT_DOCUMENT_ID
           , PTJ.ACS_FINANCIAL_ACCOUNT_ID
           , PTJ.IMF_PRIMARY
           , PTJ.IMF_DESCRIPTION
           , PTJ.IMF_AMOUNT_LC_D
           , PTJ.IMF_AMOUNT_LC_C
           , PTJ.IMF_AMOUNT_FC_D
           , PTJ.IMF_AMOUNT_FC_C
           , PTJ.IMF_EXCHANGE_RATE
           , PTJ.IMF_VALUE_DATE
           , PTJ.ACS_TAX_CODE_ID
           , PTJ.IMF_TRANSACTION_DATE
           , PTJ.ACS_AUXILIARY_ACCOUNT_ID
           , JOU.ACT_JOURNAL_ID
           , JOU.PC_USER_ID
           , JOU.JOU_DESCRIPTION
           , JOU.JOU_NUMBER
           , JOU.ACS_FINANCIAL_YEAR_ID
           , JOU.C_ETAT_JOURNAL
           , JOU.C_SUB_SET
           , ACS_FUNCTION.GetAccountNumber(PTJ.ACS_AUXILIARY_ACCOUNT_ID) AUX_ACC_NUMBER
           , ACS_FUNCTION.GetAccountNumber(DIS.ACS_DIVISION_ACCOUNT_ID) DIV_ACC_NUMBER
           , ACS_FUNCTION.GetAccountNumber(PTJ.ACS_FINANCIAL_ACCOUNT_ID) ACC_NUMBER
           , ACS_FUNCTION.GetAccountNumber(PTJ.ACS_TAX_CODE_ID) TAX_ACC_NUMBER
        from V_ACT_IMPUTATION_JOU PTJ
           , ACS_DESCRIPTION DES
           , ACT_FINANCIAL_DISTRIBUTION DIS
           , ACT_DOCUMENT ATD
           , V_ACT_JOURNAL JOU
           , ACS_FINANCIAL_CURRENCY FUR_MB
           , ACS_FINANCIAL_CURRENCY FUR_ME
           , PCS.PC_CURR CUR_MB
           , PCS.PC_CURR CUR_ME
           , ACT_PART_IMPUTATION PAR
       where PTJ.ACS_AUXILIARY_ACCOUNT_ID = DES.ACS_ACCOUNT_ID(+)
         and PTJ.ACT_FINANCIAL_IMPUTATION_ID = DIS.ACT_FINANCIAL_IMPUTATION_ID(+)
         and PTJ.ACT_DOCUMENT_ID = ATD.ACT_DOCUMENT_ID
         and ATD.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
         and PTJ.ACS_FINANCIAL_CURRENCY_ID = FUR_ME.ACS_FINANCIAL_CURRENCY_ID(+)
         and PTJ.ACS_ACS_FINANCIAL_CURRENCY_ID = FUR_MB.ACS_FINANCIAL_CURRENCY_ID(+)
         and FUR_ME.PC_CURR_ID = CUR_ME.PC_CURR_ID(+)
         and FUR_MB.PC_CURR_ID = CUR_MB.PC_CURR_ID(+)
         and PTJ.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
         and JOU.C_SUB_SET = PARAMETER_0
         and (   DES.PC_LANG_ID is null
              or DES.PC_LANG_ID = VPC_LANG_ID);
  end ACT_JOURNAL_AUX_RPT_PK;

  procedure ACT_JOURNAL_COND_RPT_PK(
    aRefCursor             in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , aJOU_NUMBER_From       in     varchar2
  , aJOU_NUMBER_To         in     varchar2
  , aACS_FINANCIAL_YEAR_ID in     varchar2
  , PROCUSER_LANID         in     pcs.pc_lang.lanid%type
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    if     (aJOU_NUMBER_From is not null)
       and (length(trim(aJOU_NUMBER_From) ) > 0) then
      ACR_FUNCTIONS.JOU_NUMBER1  := aJOU_NUMBER_From;
    else
      ACR_FUNCTIONS.JOU_NUMBER1  := ' ';
    end if;

    if     (aJOU_NUMBER_To is not null)
       and (length(trim(aJOU_NUMBER_To) ) > 0) then
      ACR_FUNCTIONS.JOU_NUMBER2  := aJOU_NUMBER_To;
    end if;

    if     (aACS_FINANCIAL_YEAR_ID is not null)
       and (length(trim(aACS_FINANCIAL_YEAR_ID) ) > 0) then
      ACR_FUNCTIONS.FIN_YEAR_ID  := aACS_FINANCIAL_YEAR_ID;
    end if;

    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open aRefCursor for
      select ACJ_FUNCTIONS.TranslateCatDescr(CAT.ACJ_CATALOGUE_DOCUMENT_ID, VPC_LANG_ID) CAT_DESCRIPTION
           , ACJ_FUNCTIONS.TranslateTypDescr(TYP.ACJ_JOB_TYPE_ID, VPC_LANG_ID) TYP_DESCRIPTION
           , YEA.FYE_NO_EXERCICE
           , PRD.PER_NO_PERIOD
           , ETA.C_ETAT_JOURNAL
           , ETA.C_SUB_SET
           , JOB.JOB_DESCRIPTION
           , JOU.ACT_JOURNAL_ID
           , JOU.A_IDMOD
           , JOU.A_IDCRE
           , JOU.A_DATEMOD
           , JOU.A_DATECRE
           , JOU.JOU_NUMBER
           , JOU.JOU_DESCRIPTION
           , CUR_MB.CURRENCY CURRENCY_MB
           , CUR_ME.CURRENCY CURRENCY_ME
           , V_JOU.ACT_JOURNAL_ID
           , V_JOU.IMF_TRANSACTION_DATE
           , V_JOU.ACS_FINANCIAL_ACCOUNT_ID
           , V_JOU.ACS_DIVISION_ACCOUNT_ID
           , V_JOU.IMF_AMOUNT_LC_D_SUM
           , V_JOU.IMF_AMOUNT_LC_C_SUM
           , V_JOU.IMF_AMOUNT_FC_D_SUM
           , V_JOU.IMF_AMOUNT_FC_C_SUM
           , V_JOU.IMF_AMOUNT_EUR_D_SUM
           , V_JOU.IMF_AMOUNT_EUR_C_SUM
           , ACS_FUNCTION.GetAccountNumber(V_JOU.ACS_DIVISION_ACCOUNT_ID) DIV_ACC_NUMBER
           , ACS_FUNCTION.GetAccountNumber(V_JOU.ACS_FINANCIAL_ACCOUNT_ID) ACC_NUMBER
           , ACS_FUNCTION.GetAccountNumber(V_JOU.ACS_TAX_CODE_ID) TAX_ACC_NUMBER
           , DES_FIN.DES_DESCRIPTION_SUMMARY FIN_DESCRIPTION_SUMMARY
           , DES_DIV.DES_DESCRIPTION_SUMMARY DIV_DESCRIPTION_SUMMARY
        from V_ACT_JOURNAL_COND V_JOU
           , ACT_JOURNAL JOU
           , ACT_JOB JOB
           , ACS_FINANCIAL_YEAR YEA
           , ACJ_JOB_TYPE TYP
           , ACT_ETAT_JOURNAL ETA
           , ACS_FINANCIAL_CURRENCY FUR_MB
           , ACS_FINANCIAL_CURRENCY FUR_ME
           , PCS.PC_CURR CUR_MB
           , PCS.PC_CURR CUR_ME
           , ACJ_CATALOGUE_DOCUMENT CAT
           , ACS_PERIOD PRD
           , ACS_DESCRIPTION DES_FIN
           , ACS_DESCRIPTION DES_DIV
       where V_JOU.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
         and JOU.ACT_JOB_ID = JOB.ACT_JOB_ID
         and JOU.ACS_FINANCIAL_YEAR_ID = YEA.ACS_FINANCIAL_YEAR_ID
         and JOB.ACJ_JOB_TYPE_ID = TYP.ACJ_JOB_TYPE_ID
         and V_JOU.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
         and V_JOU.ACS_ACS_FINANCIAL_CURRENCY_ID = FUR_MB.ACS_FINANCIAL_CURRENCY_ID
         and FUR_MB.PC_CURR_ID = CUR_MB.PC_CURR_ID
         and V_JOU.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and V_JOU.ACS_PERIOD_ID = PRD.ACS_PERIOD_ID
         and ETA.C_SUB_SET = 'ACC'
         and V_JOU.ACS_FINANCIAL_ACCOUNT_ID = DES_FIN.ACS_ACCOUNT_ID(+)
         and DES_FIN.PC_LANG_ID(+) = VPC_LANG_ID
         and V_JOU.ACS_DIVISION_ACCOUNT_ID = DES_DIV.ACS_ACCOUNT_ID(+)
         and DES_DIV.PC_LANG_ID(+) = VPC_LANG_ID;
  end ACT_JOURNAL_COND_RPT_PK;

  procedure ACT_JOURNAL_GEN_RPT_PK(
    aRefCursor             in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , aJOU_NUMBER_From       in     varchar2
  , aJOU_NUMBER_To         in     varchar2
  , aACS_FINANCIAL_YEAR_ID in     varchar2
  , PROCUSER_LANID         in     pcs.pc_lang.lanid%type
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    if     (aJOU_NUMBER_From is not null)
       and (length(trim(aJOU_NUMBER_From) ) > 0) then
      ACR_FUNCTIONS.JOU_NUMBER1  := aJOU_NUMBER_From;
    else
      ACR_FUNCTIONS.JOU_NUMBER1  := ' ';
    end if;

    if     (aJOU_NUMBER_To is not null)
       and (length(trim(aJOU_NUMBER_To) ) > 0) then
      ACR_FUNCTIONS.JOU_NUMBER2  := aJOU_NUMBER_To;
    end if;

    if     (aACS_FINANCIAL_YEAR_ID is not null)
       and (length(trim(aACS_FINANCIAL_YEAR_ID) ) > 0) then
      ACR_FUNCTIONS.FIN_YEAR_ID  := aACS_FINANCIAL_YEAR_ID;
    end if;

    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open aRefCursor for
      select FUR_MB.PC_CURR_ID MB_CURR_ID
           , FUR_ME.PC_CURR_ID ME_CURR_ID
           , ATD.ACT_DOCUMENT_ID
           , ATD.DOC_NUMBER
           , ATD.DOC_DOCUMENT_DATE
           , JOB.JOB_DESCRIPTION
           , PAR.ACT_PART_IMPUTATION_ID
           , PAR.PAR_DOCUMENT
           , CUR_MB.CURRENCY MB_CURRENCY
           , CUR_ME.CURRENCY ME_CURRENCY
           , USR.USE_DESCR
           , V_IMU.ACT_FINANCIAL_IMPUTATION_ID
           , V_IMU.ACT_DOCUMENT_ID
           , V_IMU.IMF_PRIMARY
           , V_IMU.IMF_DESCRIPTION
           , V_IMU.IMF_AMOUNT_LC_D
           , V_IMU.IMF_AMOUNT_LC_C
           , V_IMU.IMF_EXCHANGE_RATE
           , V_IMU.IMF_AMOUNT_FC_D
           , V_IMU.IMF_AMOUNT_FC_C
           , V_IMU.IMF_VALUE_DATE
           , V_IMU.IMF_TRANSACTION_DATE
           , V_JOU.ACT_JOURNAL_ID
           , V_JOU.JOU_DESCRIPTION
           , V_JOU.JOU_NUMBER
           , V_JOU.ACS_FINANCIAL_YEAR_ID
           , V_JOU.C_ETAT_JOURNAL
           , V_JOU.C_SUB_SET
           , ACC_DIS.ACC_NUMBER ACC_NUMBER_DIV
           , VPC_LANG_ID
           , ACS_FUNCTION.GetAccountNumber(V_IMU.ACS_DIVISION_ACCOUNT_ID) DIV_ACC_NUMBER
           , ACS_FUNCTION.GetAccountNumber(V_IMU.ACS_FINANCIAL_ACCOUNT_ID) FIN_ACC_NUMBER
           , ACS_FUNCTION.GetAccountNumber(V_IMU.ACS_TAX_CODE_ID) TAX_ACC_NUMBER
           , ACS_FUNCTION.GetAccountNumber(V_IMU.ACS_AUXILIARY_ACCOUNT_ID) AUX_ACC_NUMBER
           , DES_AUX.DES_DESCRIPTION_SUMMARY AUX_DESCRIPTION_SUMMARY
        from V_ACT_IMPUTATION_JOU V_IMU
           , V_ACT_JOURNAL V_JOU
           , ACT_FINANCIAL_DISTRIBUTION DIS
           , ACS_ACCOUNT ACC_DIS
           , ACT_DOCUMENT ATD
           , ACT_JOURNAL JOU
           , ACT_JOB JOB
           , PCS.PC_USER USR
           , ACS_FINANCIAL_YEAR YEA
           , ACJ_JOB_TYPE TYP
           , ACT_PART_IMPUTATION PAR
           , ACS_FINANCIAL_CURRENCY FUR_MB
           , ACS_FINANCIAL_CURRENCY FUR_ME
           , PCS.PC_CURR CUR_MB
           , PCS.PC_CURR CUR_ME
           , ACS_DESCRIPTION DES_AUX
       where V_IMU.ACT_DOCUMENT_ID = ATD.ACT_DOCUMENT_ID
         and V_IMU.ACT_FINANCIAL_IMPUTATION_ID = DIS.ACT_FINANCIAL_IMPUTATION_ID(+)
         and DIS.ACS_DIVISION_ACCOUNT_ID = ACC_DIS.ACS_ACCOUNT_ID(+)
         and ATD.ACT_JOB_ID = JOB.ACT_JOB_ID
         and JOB.ACJ_JOB_TYPE_ID = TYP.ACJ_JOB_TYPE_ID
         and ATD.ACT_JOURNAL_ID = V_JOU.ACT_JOURNAL_ID
         and V_JOU.PC_USER_ID = USR.PC_USER_ID(+)
         and V_JOU.ACS_FINANCIAL_YEAR_ID = YEA.ACS_FINANCIAL_YEAR_ID
         and V_IMU.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID(+)
         and V_IMU.ACS_ACS_FINANCIAL_CURRENCY_ID = FUR_MB.ACS_FINANCIAL_CURRENCY_ID(+)
         and FUR_MB.PC_CURR_ID = CUR_MB.PC_CURR_ID(+)
         and V_IMU.ACS_FINANCIAL_CURRENCY_ID = FUR_ME.ACS_FINANCIAL_CURRENCY_ID(+)
         and FUR_ME.PC_CURR_ID = CUR_ME.PC_CURR_ID(+)
         and V_IMU.ACS_AUXILIARY_ACCOUNT_ID = DES_AUX.ACS_ACCOUNT_ID(+)
         and DES_AUX.PC_LANG_ID(+) = VPC_LANG_ID
         and V_JOU.C_SUB_SET = 'ACC';
  end ACT_JOURNAL_GEN_RPT_PK;

/*
* Description
* STORED PROCEDURE USED FOR REPORT ACT_JOURNAL_GEN.RPT
*/
  procedure ACT_JOURNAL_GEN_SUB_RPT_PK(
    aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , PARAMETER_1    in     varchar2
  , PARAMETER_2    in     number
  , PROCUSER_LANID in     pcs.pc_lang.lanid%type
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open aRefCursor for
      select ACC_DIV.ACC_NUMBER DIV_NUMBER
           , ACC_FIN.ACC_NUMBER FIN_NUMBER
           , DES_DIV.PC_LANG_ID DIV_PC_LAN_ID
           , DES_DIV.DES_DESCRIPTION_SUMMARY DIV_DESCRIPTION_SUMMARY
           , DES_FIN.PC_LANG_ID FIN_PC_LAN_ID
           , DES_FIN.DES_DESCRIPTION_SUMMARY FIN_DESCRIPTION_SUMMARY
           , FUR_MB.PC_CURR_ID MB_CURR_ID
           , FUR_ME.PC_CURR_ID ME_CURR_ID
           , IMP.IMF_AMOUNT_LC_D
           , IMP.IMF_AMOUNT_LC_C
           , IMP.IMF_AMOUNT_FC_D
           , IMP.IMF_AMOUNT_FC_C
           , CUR_MB.CURRENCY CURRENCY_MB
           , CUR_ME.CURRENCY CURRENCY_ME
           , JOU.ACT_JOURNAL_ID
           , JOU.C_SUB_SET
        from ACT_FINANCIAL_IMPUTATION IMP
           , ACT_FINANCIAL_DISTRIBUTION DIS
           , ACS_ACCOUNT ACC_DIV
           , ACS_DESCRIPTION DES_DIV
           , ACT_DOCUMENT ATD
           , V_ACT_JOURNAL JOU
           , ACS_ACCOUNT ACC_FIN
           , ACS_DESCRIPTION DES_FIN
           , ACS_FINANCIAL_CURRENCY FUR_MB
           , ACS_FINANCIAL_CURRENCY FUR_ME
           , PCS.PC_CURR CUR_MB
           , PCS.PC_CURR CUR_ME
       where IMP.ACT_FINANCIAL_IMPUTATION_ID = DIS.ACT_FINANCIAL_IMPUTATION_ID(+)
         and DIS.ACS_DIVISION_ACCOUNT_ID = ACC_DIV.ACS_ACCOUNT_ID(+)
         and ACC_DIV.ACS_ACCOUNT_ID = DES_DIV.ACS_ACCOUNT_ID(+)
         and IMP.ACT_DOCUMENT_ID = ATD.ACT_DOCUMENT_ID
         and ATD.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
         and IMP.ACS_FINANCIAL_ACCOUNT_ID = ACC_FIN.ACS_ACCOUNT_ID
         and ACC_FIN.ACS_ACCOUNT_ID = DES_FIN.ACS_ACCOUNT_ID(+)
         and IMP.ACS_FINANCIAL_CURRENCY_ID = FUR_ME.ACS_FINANCIAL_CURRENCY_ID(+)
         and IMP.ACS_ACS_FINANCIAL_CURRENCY_ID = FUR_MB.ACS_FINANCIAL_CURRENCY_ID(+)
         and FUR_ME.PC_CURR_ID = CUR_ME.PC_CURR_ID(+)
         and FUR_MB.PC_CURR_ID = CUR_MB.PC_CURR_ID(+)
         and JOU.C_SUB_SET = 'ACC'
         and JOU.ACT_JOURNAL_ID = PARAMETER_2
         and DES_FIN.PC_LANG_ID = to_number(PARAMETER_1)
         and (    (DES_DIV.PC_LANG_ID is null)
              or (    DES_DIV.PC_LANG_ID is not null
                  and DES_DIV.PC_LANG_ID = to_number(PARAMETER_1) ) );
  end ACT_JOURNAL_GEN_SUB_RPT_PK;

/*
* Description
* STORED PROCEDURE USED FOR REPORT ACT_JOURNAL_LIST.RPT
*/
  procedure ACT_JOURNAL_LIST_RPT_PK(
    aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , PARAMETER_0    in     number
  , PARAMETER_1    in     number
  , PARAMETER_2    in     number
  , PARAMETER_3    in     number
  , PARAMETER_4    in     varchar2
  , PROCUSER_LANID in     pcs.pc_lang.lanid%type
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open aRefCursor for
      select DES.DES_DESCRIPTION_SUMMARY
           , ETA.C_ETAT_JOURNAL
           , JOB.ACT_JOB_ID
           , JOU.ACT_JOURNAL_ID
           , JOU.JOU_DESCRIPTION
           , JOU.JOU_NUMBER
           , JOU.A_DATECRE
           , JOU.A_DATEMOD
           , JOU.A_IDCRE
           , JOU.A_IDMOD
        from ACT_JOURNAL JOU
           , ACT_ETAT_JOURNAL ETA
           , ACS_ACCOUNTING ATG
           , ACT_JOB JOB
           , ACS_FINANCIAL_YEAR YEA
           , ACS_DESCRIPTION DES
           , ACJ_JOB_TYPE TYP
           , PCS.PC_LANG LAN
       where JOU.ACT_JOURNAL_ID = ETA.ACT_JOURNAL_ID
         and JOU.ACS_ACCOUNTING_ID = ATG.ACS_ACCOUNTING_ID
         and ATG.ACS_ACCOUNTING_ID = DES.ACS_ACCOUNTING_ID
         and DES.PC_LANG_ID = LAN.PC_LANG_ID
         and JOU.ACT_JOB_ID = JOB.ACT_JOB_ID
         and JOB.ACJ_JOB_TYPE_ID = TYP.ACJ_JOB_TYPE_ID
         and JOU.ACS_FINANCIAL_YEAR_ID = YEA.ACS_FINANCIAL_YEAR_ID
         and LAN.PC_LANG_ID = VPC_LANG_ID
         and YEA.ACS_FINANCIAL_YEAR_ID = PARAMETER_0
         and ACT_FUNCTIONS.IsUserAutorizedForJobType(PARAMETER_1, JOB.ACJ_JOB_TYPE_ID) = 1
         and (    JOU.JOU_NUMBER >= PARAMETER_2
              and JOU.JOU_NUMBER <= PARAMETER_3)
         and ATG.C_TYPE_ACCOUNTING = PARAMETER_4
         and ETA.C_SUB_SET <> 'REC'
         and ETA.C_SUB_SET <> 'PAY';
  end ACT_JOURNAL_LIST_RPT_PK;

/*
* Description
* STORED PROCEDURE USED FOR REPORT ACT_COUNT_DOCUMENT.RPT THE SUB REPORT OF ACT_JOURNAL_LIST.RPT
*/
  procedure ACT_JOURNAL_LIST_SUB_RPT_PK(aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp, PARAMETER_1 in number, PROCUSER_LANID in pcs.pc_lang.lanid%type)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open aRefCursor for
      select ATD.ACT_DOCUMENT_ID
           , JOB.ACT_JOB_ID
        from ACT_JOB JOB
           , ACT_DOCUMENT ATD
       where JOB.ACT_JOB_ID = PARAMETER_1
         and JOB.ACT_JOB_ID = ATD.ACT_JOB_ID;
  end ACT_JOURNAL_LIST_SUB_RPT_PK;

/*
* Description
* STORED PROCEDURE USED FOR REPORT ACT_MGM_DISTRIBUTION.RPT,THE SUB REPORT OF ACT_JOURNAL_MGM.RPT
*/
  procedure ACT_JOURNAL_MGM_RPT_PK(
    aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , PARAMETER_0    in     number
  , PARAMETER_1    in     number
  , PARAMETER_2    in     number
  , PROCUSER_LANID in     pcs.pc_lang.lanid%type
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open aRefCursor for
      select AUX_ACC.ACC_NUMBER AUX_ACC_NUMBER
           , CDA_ACC.ACC_NUMBER CDA_ACC_NUMBER
           , CPN_ACC.ACC_NUMBER CPN_ACC_NUMBER
           , PF_ACC.ACC_NUMBER PF_ACC_NUMBER
           , QTY_ACC.ACC_NUMBER QTY_ACC_NUMBER
           , CUR_MB.CURRENCY CURRENCY_MB
           , CUR_ME.CURRENCY CURRENCY_ME
           , MGM.ACT_JOURNAL_ID
           , MGM.JOU_NUMBER
           , MGM.JOU_DESCRIPTION
           , MGM.PC_USER_ID
           , MGM.C_ETAT_JOURNAL
           , MGM.C_SUB_SET
           , MGM.ACS_FINANCIAL_YEAR_ID
           , MGM.JOB_DESCRIPTION
           , MGM.ACT_DOCUMENT_ID
           , MGM.DOC_DOCUMENT_DATE
           , MGM.DOC_NUMBER
           , MGM.IMM_TRANSACTION_DATE
           , MGM.ACT_MGM_IMPUTATION_ID
           , MGM.IMM_VALUE_DATE
           , MGM.IMM_PRIMARY
           , MGM.IMM_DESCRIPTION
           , MGM.ACS_CPN_ACCOUNT_ID
           , MGM.ACS_CDA_ACCOUNT_ID
           , MGM.ACS_PF_ACCOUNT_ID
           , MGM.ACS_QTY_UNIT_ID
           , MGM.ACS_ACS_FINANCIAL_CURRENCY_ID
           , MGM.IMM_AMOUNT_LC_D
           , MGM.IMM_AMOUNT_LC_C
           , MGM.ACS_FINANCIAL_CURRENCY_ID
           , MGM.IMM_AMOUNT_FC_D
           , MGM.IMM_AMOUNT_FC_C
           , MGM.IMM_EXCHANGE_RATE
           , MGM.IMM_QUANTITY_D
           , MGM.IMM_QUANTITY_C
           , MGM.ACT_MGM_DISTRIBUTION_ID
           , MGM.ACS_AUXILIARY_ACCOUNT_ID
           , DES.DES_DESCRIPTION_SUMMARY
        from V_ACT_REP_MGM_IMPUTATION MGM
           , ACS_ACCOUNT AUX_ACC
           , ACS_ACCOUNT CDA_ACC
           , ACS_ACCOUNT CPN_ACC
           , ACS_ACCOUNT PF_ACC
           , ACS_ACCOUNT QTY_ACC
           , ACS_DESCRIPTION DES
           , ACS_FINANCIAL_CURRENCY FUR_MB
           , ACS_FINANCIAL_CURRENCY FUR_ME
           , PCS.PC_CURR CUR_MB
           , PCS.PC_CURR CUR_ME
       where MGM.ACS_CPN_ACCOUNT_ID = CPN_ACC.ACS_ACCOUNT_ID
         and MGM.ACS_CDA_ACCOUNT_ID = CDA_ACC.ACS_ACCOUNT_ID(+)
         and MGM.ACS_PF_ACCOUNT_ID = PF_ACC.ACS_ACCOUNT_ID(+)
         and MGM.ACS_QTY_UNIT_ID = QTY_ACC.ACS_ACCOUNT_ID(+)
         and MGM.ACS_AUXILIARY_ACCOUNT_ID = DES.ACS_ACCOUNT_ID(+)
         and DES.PC_LANG_ID(+) = VPC_LANG_ID
         and MGM.ACS_ACS_FINANCIAL_CURRENCY_ID = FUR_MB.ACS_FINANCIAL_CURRENCY_ID
         and FUR_MB.PC_CURR_ID = CUR_MB.PC_CURR_ID
         and MGM.ACS_FINANCIAL_CURRENCY_ID = FUR_ME.ACS_FINANCIAL_CURRENCY_ID
         and FUR_ME.PC_CURR_ID = CUR_ME.PC_CURR_ID
         and MGM.ACS_AUXILIARY_ACCOUNT_ID = AUX_ACC.ACS_ACCOUNT_ID(+)
         and MGM.C_SUB_SET = 'CPN'
         and MGM.ACS_FINANCIAL_YEAR_ID = PARAMETER_0
         and MGM.JOU_NUMBER >= PARAMETER_1
         and MGM.JOU_NUMBER <= PARAMETER_2;
  end ACT_JOURNAL_MGM_RPT_PK;

/*
* Description
* STORED PROCEDURE USED FOR REPORT ACT_MGM_DISTRIBUTION.RPT, THE SUB REPORT OF ACT_JOURNAL_MGM.RPT
*/
  procedure ACT_MGM_DIS_SUB_RPT_PK(aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp, PARAMETER_1 in number, PROCUSER_LANID in pcs.pc_lang.lanid%type)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open aRefCursor for
      select PJ_ACC.ACC_NUMBER
           , DIS.ACT_MGM_DISTRIBUTION_ID
           , DIS.MGM_AMOUNT_LC_D
           , DIS.MGM_AMOUNT_FC_D
           , DIS.MGM_AMOUNT_LC_C
           , DIS.MGM_AMOUNT_FC_C
        from ACT_MGM_DISTRIBUTION DIS
           , ACT_MGM_IMPUTATION IMP
           , ACS_ACCOUNT PJ_ACC
       where DIS.ACT_MGM_IMPUTATION_ID = IMP.ACT_MGM_IMPUTATION_ID
         and DIS.ACS_PJ_ACCOUNT_ID = PJ_ACC.ACS_ACCOUNT_ID(+)
         and DIS.ACT_MGM_DISTRIBUTION_ID = PARAMETER_1;
  end ACT_MGM_DIS_SUB_RPT_PK;

/*
* Description
* STORED PROCEDURE USED FOR REPORT ACT_MGM_RECAP.RPT, THE SUB REPORT OF ACT_JOURNAL_MGM.RPT
*/
  procedure ACT_MGM_RECAP_SUB_RPT_PK(aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp, PARAMETER_1 in number, PROCUSER_LANID in pcs.pc_lang.lanid%type)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open aRefCursor for
      select CDA_ACC.ACC_NUMBER CDA_ACC_NUMBER
           , CPN_ACC.ACC_NUMBER CPN_ACC_NUMBER
           , PF_ACC.ACC_NUMBER PF_ACC_NUMBER
           , QTY_ACC.ACC_NUMBER QTY_ACC_NUMBER
           , CUR_MB.CURRENCY CURRENCY_MB
           , CUR_ME.CURRENCY CURRENCY_ME
           , IMP.ACS_CDA_ACCOUNT_ID
           , IMP.ACS_CPN_ACCOUNT_ID
           , IMP.ACS_PF_ACCOUNT_ID
           , IMP.ACS_QTY_UNIT_ID
           , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
           , IMP.IMM_AMOUNT_LC_D
           , IMP.IMM_AMOUNT_LC_C
           , IMP.ACS_FINANCIAL_CURRENCY_ID
           , IMP.IMM_AMOUNT_FC_D
           , IMP.IMM_AMOUNT_FC_C
           , IMP.IMM_QUANTITY_D
           , IMP.IMM_QUANTITY_C
        from ACS_ACCOUNT CDA_ACC
           , ACS_ACCOUNT CPN_ACC
           , ACS_ACCOUNT PF_ACC
           , ACS_ACCOUNT QTY_ACC
           , ACS_FINANCIAL_CURRENCY FUR_MB
           , ACS_FINANCIAL_CURRENCY FUR_ME
           , PCS.PC_CURR CUR_MB
           , PCS.PC_CURR CUR_ME
           , V_ACT_REP_MGM_IMPUTATION IMP
       where IMP.ACS_CDA_ACCOUNT_ID = CDA_ACC.ACS_ACCOUNT_ID(+)
         and IMP.ACS_FINANCIAL_CURRENCY_ID = FUR_ME.ACS_FINANCIAL_CURRENCY_ID
         and FUR_ME.PC_CURR_ID = CUR_ME.PC_CURR_ID
         and IMP.ACS_ACS_FINANCIAL_CURRENCY_ID = FUR_MB.ACS_FINANCIAL_CURRENCY_ID
         and FUR_MB.PC_CURR_ID = CUR_MB.PC_CURR_ID
         and IMP.ACS_CPN_ACCOUNT_ID = CPN_ACC.ACS_ACCOUNT_ID
         and IMP.ACS_QTY_UNIT_ID = QTY_ACC.ACS_ACCOUNT_ID(+)
         and IMP.ACS_PF_ACCOUNT_ID = PF_ACC.ACS_ACCOUNT_ID(+)
         and IMP.ACT_JOURNAL_ID = PARAMETER_1
         and IMP.C_SUB_SET = 'CPN';
  end ACT_MGM_RECAP_SUB_RPT_PK;

/*
* Description
* STORED PROCEDURE USED FOR REPORT ACT_MGM_DISTRIBUTION_RECAP.RPT, THE SUB REPORT OF ACT_JOURNAL_MGM.RPT
*/
  procedure ACT_MGM_DIS_RECAP_SUB_RPT_PK(aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp, PARAMETER_1 in number, PROCUSER_LANID in pcs.pc_lang.lanid%type)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open aRefCursor for
      select CPN_ACC.ACC_NUMBER CPN_ACC_NUMBER
           , PJ_ACC.ACC_NUMBER PJ_ACC_NUMBER
           , QTY_ACC.ACC_NUMBER QTY_ACC_NUMBER
           , CUR_MB.CURRENCY CURRENCY_MB
           , CUR_ME.CURRENCY CURRENCY_ME
           , ATD.ACT_ACT_JOURNAL_ID
           , DIS.MGM_AMOUNT_LC_D
           , DIS.MGM_AMOUNT_FC_D
           , DIS.MGM_AMOUNT_LC_C
           , DIS.MGM_AMOUNT_FC_C
           , DIS.MGM_QUANTITY_D
           , DIS.MGM_QUANTITY_C
           , IMP.ACS_FINANCIAL_CURRENCY_ID
           , IMP.ACS_ACS_FINANCIAL_CURRENCY_ID
           , IMP.ACS_QTY_UNIT_ID
           , CUR_MB.CURRENCY CURRENCY_MB
           , CUR_ME.CURRENCY CURRENCY_ME
        from ACS_ACCOUNT CPN_ACC
           , ACS_ACCOUNT PJ_ACC
           , ACS_ACCOUNT QTY_ACC
           , ACS_FINANCIAL_CURRENCY FUR_MB
           , ACS_FINANCIAL_CURRENCY FUR_ME
           , PCS.PC_CURR CUR_MB
           , PCS.PC_CURR CUR_ME
           , ACT_MGM_IMPUTATION IMP
           , ACT_MGM_DISTRIBUTION DIS
           , ACT_DOCUMENT ATD
       where DIS.ACT_MGM_IMPUTATION_ID = IMP.ACT_MGM_IMPUTATION_ID
         and IMP.ACS_FINANCIAL_CURRENCY_ID = FUR_ME.ACS_FINANCIAL_CURRENCY_ID
         and FUR_ME.PC_CURR_ID = CUR_ME.PC_CURR_ID
         and IMP.ACS_ACS_FINANCIAL_CURRENCY_ID = FUR_MB.ACS_FINANCIAL_CURRENCY_ID
         and FUR_MB.PC_CURR_ID = CUR_MB.PC_CURR_ID
         and IMP.ACS_CPN_ACCOUNT_ID = CPN_ACC.ACS_ACCOUNT_ID
         and IMP.ACT_DOCUMENT_ID = ATD.ACT_DOCUMENT_ID
         and IMP.ACS_QTY_UNIT_ID = QTY_ACC.ACS_ACCOUNT_ID(+)
         and DIS.ACS_PJ_ACCOUNT_ID = PJ_ACC.ACS_ACCOUNT_ID
         and ATD.ACT_ACT_JOURNAL_ID = PARAMETER_1;
  end ACT_MGM_DIS_RECAP_SUB_RPT_PK;

/*
* Description
* STORED PROCEDURE USED FOR REPORT ACT_JOURNAL_OPERATION_TYP.RPT
*/
  procedure ACT_JOURNAL_OPT_TYP_RPT_PK(
    aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , aFrom          in     varchar2
  , aTo            in     varchar2
  , PARAMETER_1    in     varchar2
  , PARAMETER_2    in     varchar2
  , PROCUSER_LANID in     pcs.pc_lang.lanid%type
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    if     (aFrom is not null)
       and (length(trim(aFrom) ) > 0) then
      ACT_FUNCTIONS.DATE_FROM  := to_date(aFrom, 'yyyymmdd');
    end if;

    if     (aTo is not null)
       and (length(trim(aTo) ) > 0) then
      ACT_FUNCTIONS.DATE_TO  := to_date(aTo, 'yyyymmdd');
    end if;

    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open aRefCursor for
      select CAT.DIC_OPERATION_TYP_ID
           , TAX_ACC.ACC_NUMBER TAX_ACC_NUMBER
           , AUX_ACC.ACC_NUMBER AUX_ACC_NUMBER
           , DIV_ACC.ACC_NUMBER DIV_ACC_NUMBER
           , FIN_ACC.ACC_NUMBER FIN_ACC_NUMBER
           , DES.DES_DESCRIPTION_SUMMARY
           , ATD.ACT_DOCUMENT_ID
           , ATD.DOC_NUMBER
           , ATD.DOC_DOCUMENT_DATE
           , PAR.ACT_PART_IMPUTATION_ID
           , PAR.PAR_DOCUMENT
           , CUR_ME.PC_CURR_ID PC_CURR_ID_ME
           , CUR_ME.CURRENCY CURRENCY_ME
           , CUR_MB.PC_CURR_ID PC_CURR_ID_MB
           , CUR_MB.CURRENCY CURRENCY_MB
           , V_IMP.ACT_FINANCIAL_IMPUTATION_ID
           , V_IMP.ACT_DOCUMENT_ID
           , V_IMP.IMF_PRIMARY
           , V_IMP.IMF_DESCRIPTION
           , V_IMP.IMF_AMOUNT_LC_D
           , V_IMP.IMF_AMOUNT_LC_C
           , V_IMP.IMF_EXCHANGE_RATE
           , V_IMP.IMF_AMOUNT_FC_D
           , V_IMP.IMF_AMOUNT_FC_C
           , V_IMP.IMF_VALUE_DATE
           , V_IMP.IMF_TRANSACTION_DATE
           , V_JOU.JOU_NUMBER
           , V_JOU.ACS_FINANCIAL_YEAR_ID
        from ACJ_CATALOGUE_DOCUMENT CAT
           , ACJ_JOB_TYPE TYP
           , ACS_ACCOUNT TAX_ACC
           , ACS_ACCOUNT AUX_ACC
           , ACS_ACCOUNT DIV_ACC
           , ACS_ACCOUNT FIN_ACC
           , ACS_DESCRIPTION DES
           , ACS_FINANCIAL_CURRENCY FUR_MB
           , ACS_FINANCIAL_CURRENCY FUR_ME
           , ACS_FINANCIAL_YEAR YEA
           , ACT_DOCUMENT ATD
           , ACT_FINANCIAL_DISTRIBUTION DIS
           , ACT_JOB JOB
           , ACT_PART_IMPUTATION PAR
           , PCS.PC_CURR CUR_MB
           , PCS.PC_CURR CUR_ME
           , PCS.PC_USER USR
           , V_ACT_FIN_IMPUTATION_DATE V_IMP
           , V_ACT_JOURNAL V_JOU
       where V_IMP.ACT_FINANCIAL_IMPUTATION_ID = DIS.ACT_FINANCIAL_IMPUTATION_ID(+)
         and DIS.ACS_DIVISION_ACCOUNT_ID = DIV_ACC.ACS_ACCOUNT_ID(+)
         and V_IMP.ACT_DOCUMENT_ID = ATD.ACT_DOCUMENT_ID
         and ATD.ACT_JOB_ID = JOB.ACT_JOB_ID
         and JOB.ACJ_JOB_TYPE_ID = TYP.ACJ_JOB_TYPE_ID
         and ATD.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and ATD.ACT_JOURNAL_ID = V_JOU.ACT_JOURNAL_ID
         and V_JOU.PC_USER_ID = USR.PC_USER_ID(+)
         and V_JOU.ACS_FINANCIAL_YEAR_ID = YEA.ACS_FINANCIAL_YEAR_ID
         and V_IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN_ACC.ACS_ACCOUNT_ID
         and V_IMP.ACS_TAX_CODE_ID = TAX_ACC.ACS_ACCOUNT_ID
         and V_IMP.ACS_FINANCIAL_CURRENCY_ID = FUR_ME.ACS_FINANCIAL_CURRENCY_ID(+)
         and FUR_ME.PC_CURR_ID = CUR_ME.PC_CURR_ID(+)
         and V_IMP.ACS_AUXILIARY_ACCOUNT_ID = AUX_ACC.ACS_ACCOUNT_ID(+)
         and AUX_ACC.ACS_ACCOUNT_ID = DES.ACS_ACCOUNT_ID(+)
         and V_IMP.ACS_ACS_FINANCIAL_CURRENCY_ID = FUR_MB.ACS_FINANCIAL_CURRENCY_ID(+)
         and FUR_MB.PC_CURR_ID = CUR_MB.PC_CURR_ID(+)
         and V_IMP.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID(+)
         and (   DES.PC_LANG_ID is null
              or DES.PC_LANG_ID = VPC_LANG_ID)
         and V_JOU.C_SUB_SET = 'ACC'
         and (        (PARAMETER_1 <> PARAMETER_2)
                 and (    PARAMETER_1 is not null
                      and PARAMETER_2 is not null)
                 and (    CAT.DIC_OPERATION_TYP_ID >= PARAMETER_1
                      and CAT.DIC_OPERATION_TYP_ID <= PARAMETER_2)
              or (     (PARAMETER_1 <> PARAMETER_2)
                  and (    PARAMETER_1 is not null
                       and PARAMETER_2 is null)
                  and (CAT.DIC_OPERATION_TYP_ID >= PARAMETER_1) )
              or (     (PARAMETER_1 <> PARAMETER_2)
                  and (    PARAMETER_1 is null
                       and PARAMETER_2 is not null)
                  and (CAT.DIC_OPERATION_TYP_ID <= PARAMETER_2) )
              or (     (    PARAMETER_1 = PARAMETER_2
                        and PARAMETER_1 is not null
                        and PARAMETER_2 is not null)
                  and (CAT.DIC_OPERATION_TYP_ID = PARAMETER_1) )
              or (    PARAMETER_1 is null
                  and PARAMETER_2 is null)
             );
  end ACT_JOURNAL_OPT_TYP_RPT_PK;

/*
* Description
* STORED PROCEDURE USED FOR REPORT ACT_JOURNAL_OPERATION_TYP_VAT.RPT,THE SUB REPORT OF ACT_JOURNAL_OPERATION_TYP.RPT
*/
  procedure ACT_JOU_OPT_TYP_VAT_SUB_RPT_PK(
    aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , PARAMETER_1    in     varchar2
  , PARAMETER_2    in     varchar2
  , PROCUSER_LANID in     pcs.pc_lang.lanid%type
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open aRefCursor for
      select CAT.DIC_OPERATION_TYP_ID
           , VAT_ACC.ACC_NUMBER
           , V_TAX.TAX_VAT_AMOUNT_LC
           , V_TAX.HT_LC
           , V_TAX.TTC_LC
           , V_IMP.ACT_FINANCIAL_IMPUTATION_ID
           , V_IMP.IMF_PRIMARY
           , V_IMP.C_GENRE_TRANSACTION
        from V_ACT_FIN_IMPUTATION_DATE V_IMP
           , V_ACT_DET_TAX V_TAX
           , ACT_DOCUMENT ATD
           , ACJ_CATALOGUE_DOCUMENT CAT
           , ACS_ACCOUNT VAT_ACC
       where V_IMP.ACT_FINANCIAL_IMPUTATION_ID = V_TAX.ACT_FINANCIAL_IMPUTATION_ID(+)
         and V_IMP.ACT_DOCUMENT_ID = ATD.ACT_DOCUMENT_ID
         and ATD.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
         and V_IMP.ACS_TAX_CODE_ID = VAT_ACC.ACS_ACCOUNT_ID(+)
         and (        (PARAMETER_1 <> PARAMETER_2)
                 and (    PARAMETER_1 is not null
                      and PARAMETER_2 is not null)
                 and (    CAT.DIC_OPERATION_TYP_ID >= PARAMETER_1
                      and CAT.DIC_OPERATION_TYP_ID <= PARAMETER_2)
              or (     (PARAMETER_1 <> PARAMETER_2)
                  and (    PARAMETER_1 is not null
                       and PARAMETER_2 is null)
                  and (CAT.DIC_OPERATION_TYP_ID >= PARAMETER_1) )
              or (     (PARAMETER_1 <> PARAMETER_2)
                  and (    PARAMETER_1 is null
                       and PARAMETER_2 is not null)
                  and (CAT.DIC_OPERATION_TYP_ID <= PARAMETER_2) )
              or (     (    PARAMETER_1 = PARAMETER_2
                        and PARAMETER_1 is not null
                        and PARAMETER_2 is not null)
                  and (CAT.DIC_OPERATION_TYP_ID = PARAMETER_1) )
              or (    PARAMETER_1 is null
                  and PARAMETER_2 is null)
             )
         and (   V_TAX.ACT_DET_TAX_ID is null
              or nvl(V_TAX.TAX_TMP_VAT_ENCASHMENT, 0) = 0);
  end ACT_JOU_OPT_TYP_VAT_SUB_RPT_PK;

/*
* Description
* STORED PROCEDURE USED FOR REPORT ACT_EXPIRY_SELECTION_DET.RPT
*/
  procedure ACT_EXP_SELECTION_DET_RPT_PK(aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp, PROCUSER_LANID in pcs.pc_lang.lanid%type)
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open aRefCursor for
      select SUP.PAC_SUPPLIER_PARTNER_ID
           , PER_SUP.PER_NAME PER_NAME_SUP
           , PER_SUP.PER_ACTIVITY PER_ACTIVITY_SUP
           , ACC_SUP.ACS_ACCOUNT_ID ACS_ACCOUNT_ID_SUP
           , ACC_SUP.ACC_NUMBER ACC_NUMBER_SUP
           , DES_SUP.DES_DESCRIPTION_SUMMARY DES_DESCRIPTION_SUMMARY_SUP
           , CUS.PAC_CUSTOM_PARTNER_ID
           , PER_CUS.PER_NAME PER_NAME_CUS
           , PER_CUS.PER_ACTIVITY PER_ACTIVITY_CUS
           , ACC_CUS.ACS_ACCOUNT_ID ACS_ACCOUNT_ID_CUS
           , ACC_CUS.ACC_NUMBER ACC_NUMBER_CUS
           , DES_CUS.DES_DESCRIPTION_SUMMARY DES_DESCRIPTION_SUMMARY_CUS
           ,
--FIN.ACS_FINANCIAL_CURRENCY_ID,
             FIN.FIN_LOCAL_CURRENCY
           , PME.C_TYPE_SUPPORT
           , DOC.DOC_NUMBER
           , DOC.DOC_DOCUMENT_DATE
           , exp.EXP_ADAPTED
           , exp.EXP_AMOUNT_LC
           , exp.EXP_AMOUNT_FC
           , exp.EXP_REF_BVR
           , EXS.ACT_EXPIRY_ID
           , EXS.DET_DEDUCTION_FC
           , EXS.DET_DEDUCTION_LC
           , EXS.DET_DISCOUNT_FC
           , EXS.DET_DISCOUNT_LC
           , EXS.DET_PAIED_FC
           , EXS.DET_PAIED_LC
           , IMF.IMF_PRIMARY
           , IMF.IMF_DESCRIPTION
           , IMF.ACS_FINANCIAL_CURRENCY_ID
           , IMF.ACS_ACS_FINANCIAL_CURRENCY_ID
           , ACJ.ACT_JOB_ID
           , ACJ.JOB_DESCRIPTION
           , PAR.PAR_DOCUMENT
           , PAR.PAC_FINANCIAL_REFERENCE_ID
           , FRE.C_TYPE_REFERENCE
           , FRE.PC_BANK_ID
           , FRE.PAC_ADDRESS_ID
           , FRE.FRE_ACCOUNT_CONTROL
           , FRE.FRE_ACCOUNT_NUMBER
           , FRE.FRE_ESTAB
           , FRE.FRE_POSITION
           , FRE.FRE_DOM_NAME
           , FRE.FRE_DOM_CITY
           , BAN.BAN_NAME1
           , BAN.BAN_ZIP
           , BAN.BAN_CITY
           , BAN.BAN_ETAB
           , BAN.BAN_GUICH
           , BAN.BAN_DOMIC
           , BAN.BAN_CLEAR
           , BAN.BAN_SWIFT
           , BAN.BAN_BLZ
           , CNT.CNTID
           , PAC_FUNCTIONS.ISPARTNERFINANCIALREF(CUS.PAC_CUSTOM_PARTNER_ID, 1, '1') CTRL_TYPE_REF_1
           , PAC_FUNCTIONS.ISPARTNERFINANCIALREF(CUS.PAC_CUSTOM_PARTNER_ID, 1, '2') CTRL_TYPE_REF_2
           , PAC_FUNCTIONS.ISPARTNERFINANCIALREF(CUS.PAC_CUSTOM_PARTNER_ID, 1, '3') CTRL_TYPE_REF_3
           , PAC_FUNCTIONS.ISPARTNERFINANCIALREF(CUS.PAC_CUSTOM_PARTNER_ID, 1, '4') CTRL_TYPE_REF_4
           , PAC_FUNCTIONS.ISPARTNERFINANCIALREF(CUS.PAC_CUSTOM_PARTNER_ID, 1, '5') CTRL_TYPE_REF_5
           , ACT_FUNCTIONS.CURRENCY(FIN.ACS_FINANCIAL_CURRENCY_ID) CURRENCY
        from ACT_ETAT_EVENT ETA
           , ACT_JOB ACJ
           , ACT_EXPIRY_SELECTION EXS
           , ACT_EXPIRY exp
           , ACS_FIN_ACC_S_PAYMENT PMM
           , ACS_PAYMENT_METHOD PME
           , ACT_PART_IMPUTATION PAR
           , ACT_DOCUMENT DOC
           , ACT_FINANCIAL_IMPUTATION IMF
           , PAC_CUSTOM_PARTNER CUS
           , PAC_PERSON PER_CUS
           , ACS_ACCOUNT ACC_CUS
           , ACS_DESCRIPTION DES_CUS
           , PAC_SUPPLIER_PARTNER SUP
           , PAC_PERSON PER_SUP
           , ACS_ACCOUNT ACC_SUP
           , ACS_DESCRIPTION DES_SUP
           , PAC_FINANCIAL_REFERENCE FRE
           , PCS.PC_BANK BAN
           , PCS.PC_CNTRY CNT
           , ACS_FINANCIAL_CURRENCY FIN
       where ETA.ACT_JOB_ID = ACJ.ACT_JOB_ID
         and ETA.ACT_ETAT_EVENT_ID = EXS.ACT_ETAT_EVENT_ID
         and EXS.ACT_EXPIRY_ID = exp.ACT_EXPIRY_ID
         and exp.ACS_FIN_ACC_S_PAYMENT_ID = PMM.ACS_FIN_ACC_S_PAYMENT_ID(+)
         and PMM.ACS_PAYMENT_METHOD_ID = PME.ACS_PAYMENT_METHOD_ID(+)
         and exp.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
         and PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
         and DOC.ACT_DOCUMENT_ID = IMF.ACT_DOCUMENT_ID
         and PAR.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
         and CUS.PAC_CUSTOM_PARTNER_ID = PER_CUS.PAC_PERSON_ID(+)
         and CUS.ACS_AUXILIARY_ACCOUNT_ID = ACC_CUS.ACS_ACCOUNT_ID(+)
         and ACC_CUS.ACS_ACCOUNT_ID = DES_CUS.ACS_ACCOUNT_ID(+)
         and DES_CUS.PC_LANG_ID(+) = VPC_LANG_ID
         and PAR.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID(+)
         and SUP.PAC_SUPPLIER_PARTNER_ID = PER_SUP.PAC_PERSON_ID(+)
         and SUP.ACS_AUXILIARY_ACCOUNT_ID = ACC_SUP.ACS_ACCOUNT_ID(+)
         and ACC_SUP.ACS_ACCOUNT_ID = DES_SUP.ACS_ACCOUNT_ID(+)
         and DES_SUP.PC_LANG_ID(+) = VPC_LANG_ID
         and PAR.PAC_FINANCIAL_REFERENCE_ID = FRE.PAC_FINANCIAL_REFERENCE_ID(+)
         and FRE.PC_BANK_ID = BAN.PC_BANK_ID(+)
         and BAN.PC_CNTRY_ID = CNT.PC_CNTRY_ID(+)
         and PAR.ACS_FINANCIAL_CURRENCY_ID = FIN.ACS_FINANCIAL_CURRENCY_ID
         and IMF.IMF_PRIMARY = 1;
  end ACT_EXP_SELECTION_DET_RPT_PK;

/**
* Procédure stockée utilisée pour le rapport ACT_EXPIRY_SUPPLIER.RPT (Postes ouverts créanciers)
 */
  procedure ACT_EXPIRY_SUPPLIER_RPT_PK(
    aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , PROCPARAM_0    in     varchar2
  , PROCPARAM_1    in     varchar2
  , PROCPARAM_2    in     varchar2
  , PROCPARAM_3    in     varchar2
  , PROCPARAM_4    in     varchar2
  , PROCPARAM_5    in     varchar2
  , PROCPARAM_6    in     number
  , PROCPARAM_7    in     number
  , PROCUSER_LANID in     pcs.pc_lang.lanid%type
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    if (PROCPARAM_2 is null) then
      open aRefCursor for
        select PAR.PAR_DOCUMENT
             , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
             , (select CUB.CURRENCY
                  from PCS.PC_CURR CUB
                     , ACS_FINANCIAL_CURRENCY CFB
                 where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                   and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_MB
             , PAR.ACS_FINANCIAL_CURRENCY_ID
             , (select CUB.CURRENCY
                  from PCS.PC_CURR CUB
                     , ACS_FINANCIAL_CURRENCY CFB
                 where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_FINANCIAL_CURRENCY_ID
                   and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_ME
             , DOC.DOC_NUMBER
             , CAT.C_TYPE_CATALOGUE
             , (select SUB.C_TYPE_CUMUL
                  from ACJ_SUB_SET_CAT SUB
                 where DOC.ACJ_CATALOGUE_DOCUMENT_ID = SUB.ACJ_CATALOGUE_DOCUMENT_ID
                   and SUB.C_SUB_SET = 'PAY') C_TYPE_CUMUL
             , exp.ACT_EXPIRY_ID
             , exp.ACT_DOCUMENT_ID
             , exp.ACT_PART_IMPUTATION_ID
             , exp.C_STATUS_EXPIRY
             , case
                 when(PROCPARAM_7 = 1)
                 and (ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, sysdate, 1) <> 0) then ACT_FUNCTIONS.DiscountDateAfter
                                                                                                                                           (exp.ACT_DOCUMENT_ID
                                                                                                                                          , exp.EXP_SLICE
                                                                                                                                          , sysdate
                                                                                                                                           )
                 else exp.EXP_ADAPTED
               end EXP_ADAPTED
             , exp.EXP_CALCULATED
             , exp.EXP_AMOUNT_LC
             , exp.EXP_AMOUNT_FC
             , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, sysdate, 1) DISCOUNT_LC
             , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, sysdate, 0) DISCOUNT_FC
             , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 1) DET_PAIED_LC
             , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 0) DET_PAIED_FC
             , exp.EXP_AMOUNT_LC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 1) SOLDE_EXP_LC
             , exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 0) SOLDE_EXP_FC
             , ACT_CURRENCY_EVALUATION.GetConvertAmount(exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 0)
                                                      , PAR.ACS_FINANCIAL_CURRENCY_ID
                                                      , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                      , sysdate
                                                      , PROCPARAM_6
                                                       ) SOLDE_REEVAL_LC
             , exp.EXP_SLICE
             , exp.ACS_FIN_ACC_S_PAYMENT_ID
             , ACT_FUNCTIONS.LastClaimsNumber(exp.ACT_EXPIRY_ID) LAST_CLAIMS_LEVEL
             , ACT_FUNCTIONS.LastClaimsDate(exp.ACT_EXPIRY_ID) LAST_CLAIMS_DATE
             , CO2.PCO_DESCR PCO_DESCR_EXP
             , IMP.ACS_PERIOD_ID
             , IMP.IMF_TRANSACTION_DATE
             , IMP.IMF_VALUE_DATE
             , IMP.IMF_DESCRIPTION
             , IMP.ACS_FINANCIAL_ACCOUNT_ID
             , (select ACF.ACC_NUMBER
                  from ACS_ACCOUNT ACF
                 where ACF.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID) ACC_NUMBER_FIN
             , (select DE1.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE1
                 where DE1.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
                   and DE1.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_FIN_DESCR
             , IMP.DIC_IMP_FREE1_ID
             , IMP.DIC_IMP_FREE2_ID
             , IMP.DIC_IMP_FREE3_ID
             , IMP.DIC_IMP_FREE4_ID
             , IMP.DIC_IMP_FREE5_ID
             , IMP.IMF_NUMBER
             , IMP.IMF_NUMBER2
             , IMP.IMF_NUMBER3
             , IMP.IMF_NUMBER4
             , IMP.IMF_NUMBER5
             , IMP.IMF_TEXT1
             , IMP.IMF_TEXT2
             , IMP.IMF_TEXT3
             , IMP.IMF_TEXT4
             , IMP.IMF_TEXT5
             , JOU.JOU_NUMBER
             , EJO.C_ETAT_JOURNAL
             , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
             , (select ACD.ACC_NUMBER
                  from ACS_ACCOUNT ACD
                 where ACD.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV
             , (select DE2.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE2
                 where DE2.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                   and DE2.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_DIV_DESCR
             , SUP.PAC_SUPPLIER_PARTNER_ID
             , SUP.ACS_AUXILIARY_ACCOUNT_ID
             , SUP.C_PARTNER_CATEGORY
             , CO1.PCO_DESCR PCO_DESCR_SUP
             , ACC.ACC_NUMBER ACC_NUMBER_AUX
             , (select DE3.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE3
                 where DE3.ACS_ACCOUNT_ID = SUP.ACS_AUXILIARY_ACCOUNT_ID
                   and DE3.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_AUX_DESCR
             , (select DE4.DES_DESCRIPTION_LARGE
                  from ACS_DESCRIPTION DE4
                 where DE4.ACS_ACCOUNT_ID = SUP.ACS_AUXILIARY_ACCOUNT_ID
                   and DE4.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_AUX_LARGE_DESCR
             , ACC.ACS_SUB_SET_ID
             , (select DE5.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE5
                 where DE5.ACS_SUB_SET_ID = ACC.ACS_SUB_SET_ID
                   and DE5.PC_LANG_ID = VPC_LANG_ID) SUB_SET_DESCR
             , AUX.C_TYPE_ACCOUNT
             , PER.PER_NAME
             , PER.PER_FORENAME
             , PER.PER_SHORT_NAME
             , PER.PER_ACTIVITY
             , PER.PER_KEY1
             , (select ADR.ADD_FORMAT
                  from PAC_ADDRESS ADR
                 where ADR.PAC_PERSON_ID = SUP.PAC_SUPPLIER_PARTNER_ID
                   and ADR.ADD_PRINCIPAL = '1') ADD_FORMAT
             , (select DE6.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE6
                 where DE6.ACS_PAYMENT_METHOD_ID = PFC.ACS_PAYMENT_METHOD_ID
                   and DE6.PC_LANG_ID = VPC_LANG_ID) ACS_PAYMENT_METHOD_DESCR_SUPP
             , (select DE7.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE7
                 where DE7.ACS_PAYMENT_METHOD_ID = PFE.ACS_PAYMENT_METHOD_ID
                   and DE7.PC_LANG_ID = VPC_LANG_ID) ACS_PAYMENT_METHOD_DESCR_EXP
          from ACS_PAYMENT_METHOD PAE
             , ACS_FIN_ACC_S_PAYMENT PFE
             , ACS_PAYMENT_METHOD PAC
             , ACS_FIN_ACC_S_PAYMENT PFC
             , PAC_PAYMENT_CONDITION CO2
             , PAC_PAYMENT_CONDITION CO1
             , PAC_PERSON PER
             , ACS_AUXILIARY_ACCOUNT AUX
             , PAC_SUPPLIER_PARTNER SUP
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACT_FINANCIAL_IMPUTATION IMP
             , ACT_ETAT_JOURNAL EJO
             , ACT_JOURNAL JOU
             , ACT_EXPIRY exp
             , ACJ_CATALOGUE_DOCUMENT CAT
             , ACT_DOCUMENT DOC
             , ACT_PART_IMPUTATION PAR
             , ACS_ACCOUNT ACC
         where PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
           and CAT.C_TYPE_CATALOGUE <> '8'
           and   -- Transaction de relance
               PAR.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
           and EXP_CALC_NET + 0 = 1
           and ACT_EXPIRY_MANAGEMENT.IsExpiryOpenedAt(exp.ACT_EXPIRY_ID, sysdate) = 1
           and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
           and DOC.ACT_JOURNAL_ID = EJO.ACT_JOURNAL_ID
           and EJO.C_SUB_SET = 'PAY'
           and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
           and IMP.ACT_DET_PAYMENT_ID is null
           and IMP.ACS_AUXILIARY_ACCOUNT_ID is not null
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and exp.C_STATUS_EXPIRY = 0
           and FIN.FIN_COLLECTIVE = 1
           and ACC.ACC_NUMBER >= PROCPARAM_0
           and ACC.ACC_NUMBER <= PROCPARAM_1
           and (   ACC.ACS_SUB_SET_ID = PROCPARAM_3
                or PROCPARAM_3 is null)
           and (   instr(',' || PROCPARAM_4 || ',', to_char(',' || IMP.IMF_ACS_DIVISION_ACCOUNT_ID || ',') ) > 0
                or PROCPARAM_4 is null)
           and (   instr(',' || PROCPARAM_5 || ',', to_char(',' || FIN.ACS_FINANCIAL_ACCOUNT_ID || ',') ) > 0
                or PROCPARAM_5 is null)
           and PAR.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
           and SUP.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and SUP.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
           and SUP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID
           and SUP.PAC_PAYMENT_CONDITION_ID = CO1.PAC_PAYMENT_CONDITION_ID
           and PAR.PAC_PAYMENT_CONDITION_ID = CO2.PAC_PAYMENT_CONDITION_ID(+)
           and SUP.ACS_FIN_ACC_S_PAYMENT_ID = PFC.ACS_FIN_ACC_S_PAYMENT_ID(+)
           and PFC.ACS_PAYMENT_METHOD_ID = PAC.ACS_PAYMENT_METHOD_ID(+)
           and exp.ACS_FIN_ACC_S_PAYMENT_ID = PFE.ACS_FIN_ACC_S_PAYMENT_ID(+)
           and PFE.ACS_PAYMENT_METHOD_ID = PAE.ACS_PAYMENT_METHOD_ID(+);
    else
      open aRefCursor for
        select PAR.PAR_DOCUMENT
             , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
             , (select CUB.CURRENCY
                  from PCS.PC_CURR CUB
                     , ACS_FINANCIAL_CURRENCY CFB
                 where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                   and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_MB
             , PAR.ACS_FINANCIAL_CURRENCY_ID
             , (select CUB.CURRENCY
                  from PCS.PC_CURR CUB
                     , ACS_FINANCIAL_CURRENCY CFB
                 where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_FINANCIAL_CURRENCY_ID
                   and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_ME
             , DOC.DOC_NUMBER
             , CAT.C_TYPE_CATALOGUE
             , (select SUB.C_TYPE_CUMUL
                  from ACJ_SUB_SET_CAT SUB
                 where DOC.ACJ_CATALOGUE_DOCUMENT_ID = SUB.ACJ_CATALOGUE_DOCUMENT_ID
                   and SUB.C_SUB_SET = 'PAY') C_TYPE_CUMUL
             , exp.ACT_EXPIRY_ID
             , exp.ACT_DOCUMENT_ID
             , exp.ACT_PART_IMPUTATION_ID
             , exp.C_STATUS_EXPIRY
             , case
                 when(PROCPARAM_7 = 1)
                 and (ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, to_date(PROCPARAM_2, 'YYYYMMDD'), 1) <> 0) then ACT_FUNCTIONS.DiscountDateAfter
                                                                                                                                             (exp.ACT_DOCUMENT_ID
                                                                                                                                            , exp.EXP_SLICE
                                                                                                                                            , to_date
                                                                                                                                                   (PROCPARAM_2
                                                                                                                                                  , 'YYYYMMDD'
                                                                                                                                                   )
                                                                                                                                             )
                 else exp.EXP_ADAPTED
               end EXP_ADAPTED
             , exp.EXP_CALCULATED
             , exp.EXP_AMOUNT_LC
             , exp.EXP_AMOUNT_FC
             , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, to_date(PROCPARAM_2, 'YYYYMMDD'), 1) DISCOUNT_LC
             , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, to_date(PROCPARAM_2, 'YYYYMMDD'), 0) DISCOUNT_FC
             , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD'), 1) DET_PAIED_LC
             , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD'), 0) DET_PAIED_FC
             , exp.EXP_AMOUNT_LC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD'), 1) SOLDE_EXP_LC
             , exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD'), 0) SOLDE_EXP_FC
             , ACT_CURRENCY_EVALUATION.GetConvertAmount(exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD'), 0)
                                                      , PAR.ACS_FINANCIAL_CURRENCY_ID
                                                      , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                      , to_date(PROCPARAM_2, 'YYYYMMDD')
                                                      , PROCPARAM_6
                                                       ) SOLDE_REEVAL_LC
             , exp.EXP_SLICE
             , exp.ACS_FIN_ACC_S_PAYMENT_ID
             , ACT_FUNCTIONS.LastClaimsNumber(exp.ACT_EXPIRY_ID) LAST_CLAIMS_LEVEL
             , ACT_FUNCTIONS.LastClaimsDate(exp.ACT_EXPIRY_ID) LAST_CLAIMS_DATE
             , CO2.PCO_DESCR PCO_DESCR_EXP
             , IMP.ACS_PERIOD_ID
             , IMP.IMF_TRANSACTION_DATE
             , IMP.IMF_VALUE_DATE
             , IMP.IMF_DESCRIPTION
             , IMP.ACS_FINANCIAL_ACCOUNT_ID
             , (select ACF.ACC_NUMBER
                  from ACS_ACCOUNT ACF
                 where ACF.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID) ACC_NUMBER_FIN
             , (select DE1.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE1
                 where DE1.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
                   and DE1.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_FIN_DESCR
             , JOU.JOU_NUMBER
             , EJO.C_ETAT_JOURNAL
             , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
             , (select ACD.ACC_NUMBER
                  from ACS_ACCOUNT ACD
                 where ACD.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV
             , (select DE2.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE2
                 where DE2.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                   and DE2.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_DIV_DESCR
             , SUP.PAC_SUPPLIER_PARTNER_ID
             , SUP.ACS_AUXILIARY_ACCOUNT_ID
             , SUP.C_PARTNER_CATEGORY
             , CO1.PCO_DESCR PCO_DESCR_SUP
             , ACC.ACC_NUMBER ACC_NUMBER_AUX
             , (select DE3.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE3
                 where DE3.ACS_ACCOUNT_ID = SUP.ACS_AUXILIARY_ACCOUNT_ID
                   and DE3.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_AUX_DESCR
             , (select DE4.DES_DESCRIPTION_LARGE
                  from ACS_DESCRIPTION DE4
                 where DE4.ACS_ACCOUNT_ID = SUP.ACS_AUXILIARY_ACCOUNT_ID
                   and DE4.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_AUX_LARGE_DESCR
             , ACC.ACS_SUB_SET_ID
             , (select DE5.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE5
                 where DE5.ACS_SUB_SET_ID = ACC.ACS_SUB_SET_ID
                   and DE5.PC_LANG_ID = VPC_LANG_ID) SUB_SET_DESCR
             , AUX.C_TYPE_ACCOUNT
             , PER.PER_NAME
             , PER.PER_FORENAME
             , PER.PER_SHORT_NAME
             , PER.PER_ACTIVITY
             , PER.PER_KEY1
             , (select ADR.ADD_FORMAT
                  from PAC_ADDRESS ADR
                 where ADR.PAC_PERSON_ID = SUP.PAC_SUPPLIER_PARTNER_ID
                   and ADR.ADD_PRINCIPAL = '1') ADD_FORMAT
             , (select DE6.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE6
                 where DE6.ACS_PAYMENT_METHOD_ID = PFC.ACS_PAYMENT_METHOD_ID
                   and DE6.PC_LANG_ID = VPC_LANG_ID) ACS_PAYMENT_METHOD_DESCR_SUPP
             , (select DE7.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE7
                 where DE7.ACS_PAYMENT_METHOD_ID = PFE.ACS_PAYMENT_METHOD_ID
                   and DE7.PC_LANG_ID = VPC_LANG_ID) ACS_PAYMENT_METHOD_DESCR_EXP
          from ACS_PAYMENT_METHOD PAE
             , ACS_FIN_ACC_S_PAYMENT PFE
             , ACS_PAYMENT_METHOD PAC
             , ACS_FIN_ACC_S_PAYMENT PFC
             , PAC_PAYMENT_CONDITION CO2
             , PAC_PAYMENT_CONDITION CO1
             , PAC_PERSON PER
             , ACS_AUXILIARY_ACCOUNT AUX
             , PAC_SUPPLIER_PARTNER SUP
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACT_FINANCIAL_IMPUTATION IMP
             , ACT_ETAT_JOURNAL EJO
             , ACT_JOURNAL JOU
             , ACT_EXPIRY exp
             , ACJ_CATALOGUE_DOCUMENT CAT
             , ACT_DOCUMENT DOC
             , ACT_PART_IMPUTATION PAR
             , ACS_ACCOUNT ACC
         where PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
           and CAT.C_TYPE_CATALOGUE <> '8'
           and   -- Transaction de relance
               PAR.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
           and EXP_CALC_NET + 0 = 1
           and ACT_EXPIRY_MANAGEMENT.IsExpiryOpenedAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD') ) = 1
           and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
           and DOC.ACT_JOURNAL_ID = EJO.ACT_JOURNAL_ID
           and EJO.C_SUB_SET = 'PAY'
           and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
           and IMP.ACT_DET_PAYMENT_ID is null
           and IMP.ACS_AUXILIARY_ACCOUNT_ID is not null
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and (   IMP.IMF_TRANSACTION_DATE <= to_date(PROCPARAM_2, 'YYYYMMDD')
                or PROCPARAM_2 is null)
           and FIN.FIN_COLLECTIVE = 1
           and ACC.ACC_NUMBER >= PROCPARAM_0
           and ACC.ACC_NUMBER <= PROCPARAM_1
           and (   ACC.ACS_SUB_SET_ID = PROCPARAM_3
                or PROCPARAM_3 is null)
           and (   instr(',' || PROCPARAM_4 || ',', to_char(',' || IMP.IMF_ACS_DIVISION_ACCOUNT_ID || ',') ) > 0
                or PROCPARAM_4 is null)
           and (   instr(',' || PROCPARAM_5 || ',', to_char(',' || FIN.ACS_FINANCIAL_ACCOUNT_ID || ',') ) > 0
                or PROCPARAM_5 is null)
           and PAR.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
           and SUP.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and SUP.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
           and SUP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID
           and SUP.PAC_PAYMENT_CONDITION_ID = CO1.PAC_PAYMENT_CONDITION_ID
           and PAR.PAC_PAYMENT_CONDITION_ID = CO2.PAC_PAYMENT_CONDITION_ID(+)
           and SUP.ACS_FIN_ACC_S_PAYMENT_ID = PFC.ACS_FIN_ACC_S_PAYMENT_ID(+)
           and PFC.ACS_PAYMENT_METHOD_ID = PAC.ACS_PAYMENT_METHOD_ID(+)
           and exp.ACS_FIN_ACC_S_PAYMENT_ID = PFE.ACS_FIN_ACC_S_PAYMENT_ID(+)
           and PFE.ACS_PAYMENT_METHOD_ID = PAE.ACS_PAYMENT_METHOD_ID(+);
    end if;
  end ACT_EXPIRY_SUPPLIER_RPT_PK;

/**
* Procédure stockée utilisée pour le rapport ACT_EXPIRY_CUSTOMER.RPT (Postes ouverts débiteurs)
*/
  procedure ACT_EXPIRY_CUSTOMER_RPT_PK(
    aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , PROCPARAM_0    in     varchar2
  , PROCPARAM_1    in     varchar2
  , PROCPARAM_2    in     varchar2
  , PROCPARAM_3    in     varchar2
  , PROCPARAM_4    in     varchar2
  , PROCPARAM_5    in     varchar2
  , PROCPARAM_6    in     number
  , PROCPARAM_7    in     number
  , PROCUSER_LANID in     pcs.pc_lang.lanid%type
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    if (PROCPARAM_2 is null) then
      open aRefCursor for
        select PAR.PAR_DOCUMENT
             , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
             , (select CUB.CURRENCY
                  from PCS.PC_CURR CUB
                     , ACS_FINANCIAL_CURRENCY CFB
                 where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                   and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_MB
             , PAR.ACS_FINANCIAL_CURRENCY_ID
             , (select CUB.CURRENCY
                  from PCS.PC_CURR CUB
                     , ACS_FINANCIAL_CURRENCY CFB
                 where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_FINANCIAL_CURRENCY_ID
                   and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_ME
             , DOC.DOC_NUMBER
             , CAT.C_TYPE_CATALOGUE
             , (select SUB.C_TYPE_CUMUL
                  from ACJ_SUB_SET_CAT SUB
                 where DOC.ACJ_CATALOGUE_DOCUMENT_ID = SUB.ACJ_CATALOGUE_DOCUMENT_ID
                   and SUB.C_SUB_SET = 'REC') C_TYPE_CUMUL
             , exp.ACT_EXPIRY_ID
             , exp.ACT_DOCUMENT_ID
             , exp.ACT_PART_IMPUTATION_ID
             , exp.C_STATUS_EXPIRY
             , case
                 when(PROCPARAM_7 = 1)
                 and (ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, sysdate, 1) <> 0) then ACT_FUNCTIONS.DiscountDateAfter
                                                                                                                                           (exp.ACT_DOCUMENT_ID
                                                                                                                                          , exp.EXP_SLICE
                                                                                                                                          , sysdate
                                                                                                                                           )
                 else exp.EXP_ADAPTED
               end EXP_ADAPTED
             , exp.EXP_CALCULATED
             , exp.EXP_AMOUNT_LC
             , exp.EXP_AMOUNT_FC
             , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, sysdate, 1) DISCOUNT_LC
             , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, sysdate, 0) DISCOUNT_FC
             , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 1) DET_PAIED_LC
             , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 0) DET_PAIED_FC
             , exp.EXP_AMOUNT_LC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 1) SOLDE_EXP_LC
             , exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 0) SOLDE_EXP_FC
             , ACT_CURRENCY_EVALUATION.GetConvertAmount(exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 0)
                                                      , PAR.ACS_FINANCIAL_CURRENCY_ID
                                                      , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                      , sysdate
                                                      , PROCPARAM_6
                                                       ) SOLDE_REEVAL_LC
             , exp.EXP_SLICE
             , exp.ACS_FIN_ACC_S_PAYMENT_ID
             , ACT_FUNCTIONS.LastClaimsNumber(exp.ACT_EXPIRY_ID) LAST_CLAIMS_LEVEL
             , ACT_FUNCTIONS.LastClaimsDate(exp.ACT_EXPIRY_ID) LAST_CLAIMS_DATE
             , CO2.PCO_DESCR PCO_DESCR_EXP
             , IMP.ACS_PERIOD_ID
             , IMP.IMF_TRANSACTION_DATE
             , IMP.IMF_VALUE_DATE
             , IMP.IMF_DESCRIPTION
             , IMP.ACS_FINANCIAL_ACCOUNT_ID
             , (select ACF.ACC_NUMBER
                  from ACS_ACCOUNT ACF
                 where ACF.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID) ACC_NUMBER_FIN
             , (select DE1.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE1
                 where DE1.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
                   and DE1.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_FIN_DESCR
             , IMP.DIC_IMP_FREE1_ID
             , IMP.DIC_IMP_FREE2_ID
             , IMP.DIC_IMP_FREE3_ID
             , IMP.DIC_IMP_FREE4_ID
             , IMP.DIC_IMP_FREE5_ID
             , IMP.IMF_NUMBER
             , IMP.IMF_NUMBER2
             , IMP.IMF_NUMBER3
             , IMP.IMF_NUMBER4
             , IMP.IMF_NUMBER5
             , IMP.IMF_TEXT1
             , IMP.IMF_TEXT2
             , IMP.IMF_TEXT3
             , IMP.IMF_TEXT4
             , IMP.IMF_TEXT5
             , JOU.JOU_NUMBER
             , EJO.C_ETAT_JOURNAL
             , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
             , (select ACD.ACC_NUMBER
                  from ACS_ACCOUNT ACD
                 where ACD.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV
             , (select DE2.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE2
                 where DE2.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                   and DE2.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_DIV_DESCR
             , CUS.PAC_CUSTOM_PARTNER_ID
             , CUS.ACS_AUXILIARY_ACCOUNT_ID
             , CUS.C_PARTNER_CATEGORY
             , CO1.PCO_DESCR PCO_DESCR_CUS
             , ACC.ACC_NUMBER ACC_NUMBER_AUX
             , (select DE3.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE3
                 where DE3.ACS_ACCOUNT_ID = CUS.ACS_AUXILIARY_ACCOUNT_ID
                   and DE3.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_AUX_DESCR
             , (select DE4.DES_DESCRIPTION_LARGE
                  from ACS_DESCRIPTION DE4
                 where DE4.ACS_ACCOUNT_ID = CUS.ACS_AUXILIARY_ACCOUNT_ID
                   and DE4.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_AUX_LARGE_DESCR
             , ACC.ACS_SUB_SET_ID
             , (select DE5.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE5
                 where DE5.ACS_SUB_SET_ID = ACC.ACS_SUB_SET_ID
                   and DE5.PC_LANG_ID = VPC_LANG_ID) SUB_SET_DESCR
             , AUX.C_TYPE_ACCOUNT
             , PER.PER_NAME
             , PER.PER_FORENAME
             , PER.PER_SHORT_NAME
             , PER.PER_ACTIVITY
             , PER.PER_KEY1
             , (select ADR.ADD_FORMAT
                  from PAC_ADDRESS ADR
                 where ADR.PAC_PERSON_ID = CUS.PAC_CUSTOM_PARTNER_ID
                   and ADR.ADD_PRINCIPAL = '1') ADD_FORMAT
             , (select DE6.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE6
                 where DE6.ACS_PAYMENT_METHOD_ID = PFC.ACS_PAYMENT_METHOD_ID
                   and DE6.PC_LANG_ID = VPC_LANG_ID) ACS_PAYMENT_METHOD_DESCR_CUST
             , (select DE7.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE7
                 where DE7.ACS_PAYMENT_METHOD_ID = PFE.ACS_PAYMENT_METHOD_ID
                   and DE7.PC_LANG_ID = VPC_LANG_ID) ACS_PAYMENT_METHOD_DESCR_EXP
          from ACS_PAYMENT_METHOD PAE
             , ACS_FIN_ACC_S_PAYMENT PFE
             , ACS_PAYMENT_METHOD PAC
             , ACS_FIN_ACC_S_PAYMENT PFC
             , PAC_PAYMENT_CONDITION CO2
             , PAC_PAYMENT_CONDITION CO1
             , PAC_PERSON PER
             , ACS_AUXILIARY_ACCOUNT AUX
             , PAC_CUSTOM_PARTNER CUS
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACT_FINANCIAL_IMPUTATION IMP
             , ACT_ETAT_JOURNAL EJO
             , ACT_JOURNAL JOU
             , ACT_EXPIRY exp
             , ACJ_CATALOGUE_DOCUMENT CAT
             , ACT_DOCUMENT DOC
             , ACT_PART_IMPUTATION PAR
             , ACS_ACCOUNT ACC
         where PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
           and CAT.C_TYPE_CATALOGUE <> '8'
           and   -- Transaction de relance
               PAR.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
           and EXP_CALC_NET + 0 = 1
           and ACT_EXPIRY_MANAGEMENT.IsExpiryOpenedAt(exp.ACT_EXPIRY_ID, sysdate) = 1
           and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
           and DOC.ACT_JOURNAL_ID = EJO.ACT_JOURNAL_ID
           and EJO.C_SUB_SET = 'REC'
           and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
           and IMP.ACT_DET_PAYMENT_ID is null
           and IMP.ACS_AUXILIARY_ACCOUNT_ID is not null
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and exp.C_STATUS_EXPIRY = 0
           and FIN.FIN_COLLECTIVE = 1
           and ACC.ACC_NUMBER >= PROCPARAM_0
           and ACC.ACC_NUMBER <= PROCPARAM_1
           and (   ACC.ACS_SUB_SET_ID = PROCPARAM_3
                or PROCPARAM_3 is null)
           and (   instr(',' || PROCPARAM_4 || ',', to_char(',' || IMP.IMF_ACS_DIVISION_ACCOUNT_ID || ',') ) > 0
                or PROCPARAM_4 is null)
           and (   instr(',' || PROCPARAM_5 || ',', to_char(',' || FIN.ACS_FINANCIAL_ACCOUNT_ID || ',') ) > 0
                or PROCPARAM_5 is null)
           and PAR.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
           and CUS.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and CUS.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
           and CUS.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
           and CUS.PAC_PAYMENT_CONDITION_ID = CO1.PAC_PAYMENT_CONDITION_ID
           and PAR.PAC_PAYMENT_CONDITION_ID = CO2.PAC_PAYMENT_CONDITION_ID(+)
           and CUS.ACS_FIN_ACC_S_PAYMENT_ID = PFC.ACS_FIN_ACC_S_PAYMENT_ID(+)
           and PFC.ACS_PAYMENT_METHOD_ID = PAC.ACS_PAYMENT_METHOD_ID(+)
           and exp.ACS_FIN_ACC_S_PAYMENT_ID = PFE.ACS_FIN_ACC_S_PAYMENT_ID(+)
           and PFE.ACS_PAYMENT_METHOD_ID = PAE.ACS_PAYMENT_METHOD_ID(+);
    else
      open aRefCursor for
        select PAR.PAR_DOCUMENT
             , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
             , (select CUB.CURRENCY
                  from PCS.PC_CURR CUB
                     , ACS_FINANCIAL_CURRENCY CFB
                 where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                   and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_MB
             , PAR.ACS_FINANCIAL_CURRENCY_ID
             , (select CUB.CURRENCY
                  from PCS.PC_CURR CUB
                     , ACS_FINANCIAL_CURRENCY CFB
                 where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_FINANCIAL_CURRENCY_ID
                   and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_ME
             , DOC.DOC_NUMBER
             , CAT.C_TYPE_CATALOGUE
             , (select SUB.C_TYPE_CUMUL
                  from ACJ_SUB_SET_CAT SUB
                 where DOC.ACJ_CATALOGUE_DOCUMENT_ID = SUB.ACJ_CATALOGUE_DOCUMENT_ID
                   and SUB.C_SUB_SET = 'REC') C_TYPE_CUMUL
             , exp.ACT_EXPIRY_ID
             , exp.ACT_DOCUMENT_ID
             , exp.ACT_PART_IMPUTATION_ID
             , exp.C_STATUS_EXPIRY
             , case
                 when(PROCPARAM_7 = 1)
                 and (ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, to_date(PROCPARAM_2, 'YYYYMMDD'), 1) <> 0) then ACT_FUNCTIONS.DiscountDateAfter
                                                                                                                                             (exp.ACT_DOCUMENT_ID
                                                                                                                                            , exp.EXP_SLICE
                                                                                                                                            , to_date
                                                                                                                                                   (PROCPARAM_2
                                                                                                                                                  , 'YYYYMMDD'
                                                                                                                                                   )
                                                                                                                                             )
                 else exp.EXP_ADAPTED
               end EXP_ADAPTED
             , exp.EXP_CALCULATED
             , exp.EXP_AMOUNT_LC
             , exp.EXP_AMOUNT_FC
             , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, to_date(PROCPARAM_2, 'YYYYMMDD'), 1) DISCOUNT_LC
             , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, to_date(PROCPARAM_2, 'YYYYMMDD'), 0) DISCOUNT_FC
             , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD'), 1) DET_PAIED_LC
             , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD'), 0) DET_PAIED_FC
             , exp.EXP_AMOUNT_LC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD'), 1) SOLDE_EXP_LC
             , exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD'), 0) SOLDE_EXP_FC
             , ACT_CURRENCY_EVALUATION.GetConvertAmount(exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD'), 0)
                                                      , PAR.ACS_FINANCIAL_CURRENCY_ID
                                                      , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                      , to_date(PROCPARAM_2, 'YYYYMMDD')
                                                      , PROCPARAM_6
                                                       ) SOLDE_REEVAL_LC
             , exp.EXP_SLICE
             , exp.ACS_FIN_ACC_S_PAYMENT_ID
             , ACT_FUNCTIONS.LastClaimsNumber(exp.ACT_EXPIRY_ID) LAST_CLAIMS_LEVEL
             , ACT_FUNCTIONS.LastClaimsDate(exp.ACT_EXPIRY_ID) LAST_CLAIMS_DATE
             , CO2.PCO_DESCR PCO_DESCR_EXP
             , IMP.ACS_PERIOD_ID
             , IMP.IMF_TRANSACTION_DATE
             , IMP.IMF_VALUE_DATE
             , IMP.IMF_DESCRIPTION
             , IMP.ACS_FINANCIAL_ACCOUNT_ID
             , (select ACF.ACC_NUMBER
                  from ACS_ACCOUNT ACF
                 where ACF.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID) ACC_NUMBER_FIN
             , (select DE1.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE1
                 where DE1.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
                   and DE1.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_FIN_DESCR
             , JOU.JOU_NUMBER
             , EJO.C_ETAT_JOURNAL
             , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
             , (select ACD.ACC_NUMBER
                  from ACS_ACCOUNT ACD
                 where ACD.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV
             , (select DE2.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE2
                 where DE2.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                   and DE2.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_DIV_DESCR
             , CUS.PAC_CUSTOM_PARTNER_ID
             , CUS.ACS_AUXILIARY_ACCOUNT_ID
             , CUS.C_PARTNER_CATEGORY
             , CO1.PCO_DESCR PCO_DESCR_CUS
             , ACC.ACC_NUMBER ACC_NUMBER_AUX
             , (select DE3.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE3
                 where DE3.ACS_ACCOUNT_ID = CUS.ACS_AUXILIARY_ACCOUNT_ID
                   and DE3.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_AUX_DESCR
             , (select DE4.DES_DESCRIPTION_LARGE
                  from ACS_DESCRIPTION DE4
                 where DE4.ACS_ACCOUNT_ID = CUS.ACS_AUXILIARY_ACCOUNT_ID
                   and DE4.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_AUX_LARGE_DESCR
             , ACC.ACS_SUB_SET_ID
             , (select DE5.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE5
                 where DE5.ACS_SUB_SET_ID = ACC.ACS_SUB_SET_ID
                   and DE5.PC_LANG_ID = VPC_LANG_ID) SUB_SET_DESCR
             , AUX.C_TYPE_ACCOUNT
             , PER.PER_NAME
             , PER.PER_FORENAME
             , PER.PER_SHORT_NAME
             , PER.PER_ACTIVITY
             , PER.PER_KEY1
             , (select ADR.ADD_FORMAT
                  from PAC_ADDRESS ADR
                 where ADR.PAC_PERSON_ID = CUS.PAC_CUSTOM_PARTNER_ID
                   and ADR.ADD_PRINCIPAL = '1') ADD_FORMAT
             , (select DE6.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE6
                 where DE6.ACS_PAYMENT_METHOD_ID = PFC.ACS_PAYMENT_METHOD_ID
                   and DE6.PC_LANG_ID = VPC_LANG_ID) ACS_PAYMENT_METHOD_DESCR_CUST
             , (select DE7.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE7
                 where DE7.ACS_PAYMENT_METHOD_ID = PFE.ACS_PAYMENT_METHOD_ID
                   and DE7.PC_LANG_ID = VPC_LANG_ID) ACS_PAYMENT_METHOD_DESCR_EXP
          from ACS_PAYMENT_METHOD PAE
             , ACS_FIN_ACC_S_PAYMENT PFE
             , ACS_PAYMENT_METHOD PAC
             , ACS_FIN_ACC_S_PAYMENT PFC
             , PAC_PAYMENT_CONDITION CO2
             , PAC_PAYMENT_CONDITION CO1
             , PAC_PERSON PER
             , ACS_AUXILIARY_ACCOUNT AUX
             , PAC_CUSTOM_PARTNER CUS
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACT_FINANCIAL_IMPUTATION IMP
             , ACT_ETAT_JOURNAL EJO
             , ACT_JOURNAL JOU
             , ACT_EXPIRY exp
             , ACJ_CATALOGUE_DOCUMENT CAT
             , ACT_DOCUMENT DOC
             , ACT_PART_IMPUTATION PAR
             , ACS_ACCOUNT ACC
         where PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
           and CAT.C_TYPE_CATALOGUE <> '8'
           and   -- Transaction de relance
               PAR.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
           and EXP_CALC_NET + 0 = 1
           and ACT_EXPIRY_MANAGEMENT.IsExpiryOpenedAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD') ) = 1
           and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
           and DOC.ACT_JOURNAL_ID = EJO.ACT_JOURNAL_ID
           and EJO.C_SUB_SET = 'REC'
           and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
           and IMP.ACT_DET_PAYMENT_ID is null
           and IMP.ACS_AUXILIARY_ACCOUNT_ID is not null
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and (   IMP.IMF_TRANSACTION_DATE <= to_date(PROCPARAM_2, 'YYYYMMDD')
                or PROCPARAM_2 is null)
           and FIN.FIN_COLLECTIVE = 1
           and ACC.ACC_NUMBER >= PROCPARAM_0
           and ACC.ACC_NUMBER <= PROCPARAM_1
           and (   ACC.ACS_SUB_SET_ID = PROCPARAM_3
                or PROCPARAM_3 is null)
           and (   instr(',' || PROCPARAM_4 || ',', to_char(',' || IMP.IMF_ACS_DIVISION_ACCOUNT_ID || ',') ) > 0
                or PROCPARAM_4 is null)
           and (   instr(',' || PROCPARAM_5 || ',', to_char(',' || FIN.ACS_FINANCIAL_ACCOUNT_ID || ',') ) > 0
                or PROCPARAM_5 is null)
           and PAR.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
           and CUS.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and CUS.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
           and CUS.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
           and CUS.PAC_PAYMENT_CONDITION_ID = CO1.PAC_PAYMENT_CONDITION_ID
           and PAR.PAC_PAYMENT_CONDITION_ID = CO2.PAC_PAYMENT_CONDITION_ID(+)
           and CUS.ACS_FIN_ACC_S_PAYMENT_ID = PFC.ACS_FIN_ACC_S_PAYMENT_ID(+)
           and PFC.ACS_PAYMENT_METHOD_ID = PAC.ACS_PAYMENT_METHOD_ID(+)
           and exp.ACS_FIN_ACC_S_PAYMENT_ID = PFE.ACS_FIN_ACC_S_PAYMENT_ID(+)
           and PFE.ACS_PAYMENT_METHOD_ID = PAE.ACS_PAYMENT_METHOD_ID(+);
    end if;
  end ACT_EXPIRY_CUSTOMER_RPT_PK;

/**
* Procédure stockée utilisée pour le rapport ACT_AGED_BALANCE_SUPP (Balance âgée fournisseurs)
*
*                                            2 : Cours d'évaluation
*                                            3 : Cours d'inventaire
*                                            4 : Cours de bouclement
*                                            5 : Cours de facturation
*/
  procedure ACT_AGED_BALANCE_SUPP_RPT_PK(
    aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , PARAMETER_1    in     varchar2
  , PARAMETER_2    in     varchar2
  , PARAMETER_3    in     varchar2
  , PARAMETER_4    in     varchar2
  , PARAMETER_5    in     varchar2
  , PARAMETER_6    in     varchar2
  , PARAMETER_11   in     varchar2
  , PROCPARAM_0    in     varchar2
  , PROCPARAM_1    in     varchar2
  , PROCPARAM_2    in     varchar2
  , PROCPARAM_3    in     varchar2
  , PROCPARAM_4    in     varchar2
  , PROCPARAM_5    in     varchar2
  , PROCPARAM_6    in     number
  , PROCPARAM_7    in     number
  , PROCUSER_LANID in     pcs.pc_lang.lanid%type
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    if (PROCPARAM_2 is null) then
      open aRefCursor for
        select PAR.PAR_DOCUMENT
             , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
             , (select CUB.CURRENCY
                  from PCS.PC_CURR CUB
                     , ACS_FINANCIAL_CURRENCY CFB
                 where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                   and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_MB
             , PAR.ACS_FINANCIAL_CURRENCY_ID
             , (select CUB.CURRENCY
                  from PCS.PC_CURR CUB
                     , ACS_FINANCIAL_CURRENCY CFB
                 where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_FINANCIAL_CURRENCY_ID
                   and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_ME
             , DOC.DOC_NUMBER
             , CAT.C_TYPE_CATALOGUE
             , SUB.C_TYPE_CUMUL
             , exp.ACT_EXPIRY_ID
             , exp.ACT_DOCUMENT_ID
             , exp.ACT_PART_IMPUTATION_ID
             , exp.C_STATUS_EXPIRY
             , case
                 when(PROCPARAM_7 = 1)
                 and (ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, sysdate, 1) <> 0) then ACT_FUNCTIONS.DiscountDateAfter
                                                                                                                                           (exp.ACT_DOCUMENT_ID
                                                                                                                                          , exp.EXP_SLICE
                                                                                                                                          , sysdate
                                                                                                                                           )
                 else exp.EXP_ADAPTED
               end EXP_ADAPTED
             , exp.EXP_CALCULATED
             , to_date(sysdate) - exp.EXP_ADAPTED DAYS
             , exp.EXP_AMOUNT_LC
             , exp.EXP_AMOUNT_FC
             , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, sysdate, 1) DISCOUNT_LC
             , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, sysdate, 0) DISCOUNT_FC
             , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 1) DET_PAIED_LC
             , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 0) DET_PAIED_FC
             , exp.EXP_AMOUNT_LC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 1) SOLDE_EXP_LC
             , exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 0) SOLDE_EXP_FC
             , ACT_CURRENCY_EVALUATION.GetConvertAmount(exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 0)
                                                      , PAR.ACS_FINANCIAL_CURRENCY_ID
                                                      , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                      , sysdate
                                                      , PROCPARAM_6
                                                       ) SOLDE_REEVAL_LC
             , exp.EXP_SLICE
             , exp.ACS_FIN_ACC_S_PAYMENT_ID
             , ACT_FUNCTIONS.LastClaimsNumber(exp.ACT_EXPIRY_ID) LAST_CLAIMS_LEVEL
             , ACT_FUNCTIONS.LastClaimsDate(exp.ACT_EXPIRY_ID) LAST_CLAIMS_DATE
             , CO2.PCO_DESCR PCO_DESCR_EXP
             , IMP.ACS_PERIOD_ID
             , IMP.IMF_TRANSACTION_DATE
             , IMP.IMF_VALUE_DATE
             , IMP.IMF_DESCRIPTION
             , IMP.ACS_FINANCIAL_ACCOUNT_ID
             , (select ACF.ACC_NUMBER
                  from ACS_ACCOUNT ACF
                 where ACF.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID) ACC_NUMBER_FIN
             , (select DE1.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE1
                 where DE1.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
                   and DE1.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_FIN_DESCR
             , JOU.JOU_NUMBER
             , EJO.C_ETAT_JOURNAL
             , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
             , (select ACD.ACC_NUMBER
                  from ACS_ACCOUNT ACD
                 where ACD.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV
             , (select DE2.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE2
                 where DE2.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                   and DE2.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_DIV_DESCR
             , SUP.PAC_SUPPLIER_PARTNER_ID
             , SUP.ACS_AUXILIARY_ACCOUNT_ID
             , SUP.C_PARTNER_CATEGORY
             , CO1.PCO_DESCR PCO_DESCR_SUP
             , ACC.ACC_NUMBER ACC_NUMBER_AUX
             , (select DE3.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE3
                 where DE3.ACS_ACCOUNT_ID = SUP.ACS_AUXILIARY_ACCOUNT_ID
                   and DE3.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_AUX_DESCR
             , (select DE4.DES_DESCRIPTION_LARGE
                  from ACS_DESCRIPTION DE4
                 where DE4.ACS_ACCOUNT_ID = SUP.ACS_AUXILIARY_ACCOUNT_ID
                   and DE4.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_AUX_LARGE_DESCR
             , ACC.ACS_SUB_SET_ID
             , (select DE5.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE5
                 where DE5.ACS_SUB_SET_ID = ACC.ACS_SUB_SET_ID
                   and DE5.PC_LANG_ID = VPC_LANG_ID) SUB_SET_DESCR
             , AUX.C_TYPE_ACCOUNT
             , PER.PER_NAME
             , PER.PER_FORENAME
             , PER.PER_SHORT_NAME
             , PER.PER_ACTIVITY
             , PER.PER_KEY1
             , (select ADR.ADD_FORMAT
                  from PAC_ADDRESS ADR
                 where ADR.PAC_PERSON_ID = SUP.PAC_SUPPLIER_PARTNER_ID
                   and ADR.ADD_PRINCIPAL = '1') ADD_FORMAT
             , (select DE6.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE6
                 where DE6.ACS_PAYMENT_METHOD_ID = PFC.ACS_PAYMENT_METHOD_ID
                   and DE6.PC_LANG_ID = VPC_LANG_ID) ACS_PAYMENT_METHOD_DESCR_SUPP
             , (select DE7.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE7
                 where DE7.ACS_PAYMENT_METHOD_ID = PFE.ACS_PAYMENT_METHOD_ID
                   and DE7.PC_LANG_ID = VPC_LANG_ID) ACS_PAYMENT_METHOD_DESCR_EXP
          from ACS_PAYMENT_METHOD PAE
             , ACS_FIN_ACC_S_PAYMENT PFE
             , ACS_PAYMENT_METHOD PAC
             , ACS_FIN_ACC_S_PAYMENT PFC
             , PAC_PAYMENT_CONDITION CO2
             , PAC_PAYMENT_CONDITION CO1
             , PAC_PERSON PER
             , ACS_AUXILIARY_ACCOUNT AUX
             , PAC_SUPPLIER_PARTNER SUP
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACT_FINANCIAL_IMPUTATION IMP
             , ACT_ETAT_JOURNAL EJO
             , ACT_JOURNAL JOU
             , ACT_EXPIRY exp
             , ACJ_CATALOGUE_DOCUMENT CAT
             , ACT_DOCUMENT DOC
             , ACT_PART_IMPUTATION PAR
             , ACS_ACCOUNT ACC
             , (select C_TYPE_CUMUL
                     , ACJ_CATALOGUE_DOCUMENT_ID
                  from ACJ_SUB_SET_CAT
                 where C_SUB_SET = 'PAY') SUB
         where PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
           and CAT.C_TYPE_CATALOGUE <> '8'
           and   -- Transaction de relance
               PAR.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
           and EXP_CALC_NET + 0 = 1
           and ACT_EXPIRY_MANAGEMENT.IsExpiryOpenedAt(exp.ACT_EXPIRY_ID, sysdate) = 1
           and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
           and DOC.ACT_JOURNAL_ID = EJO.ACT_JOURNAL_ID
           and EJO.C_SUB_SET = 'PAY'
           and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
           and IMP.ACT_DET_PAYMENT_ID is null
           and IMP.ACS_AUXILIARY_ACCOUNT_ID is not null
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and exp.C_STATUS_EXPIRY = 0
           and FIN.FIN_COLLECTIVE = 1
           and ACC.ACC_NUMBER >= PROCPARAM_0
           and ACC.ACC_NUMBER <= PROCPARAM_1
           and (   ACC.ACS_SUB_SET_ID = PROCPARAM_3
                or PROCPARAM_3 is null)
           and (   instr(',' || PROCPARAM_4 || ',', to_char(',' || IMP.IMF_ACS_DIVISION_ACCOUNT_ID || ',') ) > 0
                or PROCPARAM_4 is null)
           and (   instr(',' || PROCPARAM_5 || ',', to_char(',' || FIN.ACS_FINANCIAL_ACCOUNT_ID || ',') ) > 0
                or PROCPARAM_5 is null)
           and PAR.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
           and SUP.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and SUP.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
           and SUP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID
           and SUP.PAC_PAYMENT_CONDITION_ID = CO1.PAC_PAYMENT_CONDITION_ID
           and PAR.PAC_PAYMENT_CONDITION_ID = CO2.PAC_PAYMENT_CONDITION_ID(+)
           and SUP.ACS_FIN_ACC_S_PAYMENT_ID = PFC.ACS_FIN_ACC_S_PAYMENT_ID(+)
           and PFC.ACS_PAYMENT_METHOD_ID = PAC.ACS_PAYMENT_METHOD_ID(+)
           and exp.ACS_FIN_ACC_S_PAYMENT_ID = PFE.ACS_FIN_ACC_S_PAYMENT_ID(+)
           and PFE.ACS_PAYMENT_METHOD_ID = PAE.ACS_PAYMENT_METHOD_ID(+)
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SUB.ACJ_CATALOGUE_DOCUMENT_ID(+)
           and
               --Ctrl_only)expired
               (   PARAMETER_1 = '0'
                or (    PARAMETER_1 = '1'
                    and (case
                           when(PROCPARAM_7 = 1)
                           and (ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, sysdate, 1) <> 0) then ACT_FUNCTIONS.DiscountDateAfter
                                                                                                                                           (exp.ACT_DOCUMENT_ID
                                                                                                                                          , exp.EXP_SLICE
                                                                                                                                          , sysdate
                                                                                                                                           )
                           else exp.EXP_ADAPTED
                         end
                        ) <= to_date(PARAMETER_2, 'YYYYMMDD')
                   )
               )
           and
               --Ctrl_c_type_cumul
               (    (    PARAMETER_3 = '1'
                     and SUB.C_TYPE_CUMUL = 'INT')
                or (    PARAMETER_4 = '1'
                    and SUB.C_TYPE_CUMUL = 'EXT')
                or (    PARAMETER_5 = '1'
                    and SUB.C_TYPE_CUMUL = 'PRE')
                or (    PARAMETER_6 = '1'
                    and SUB.C_TYPE_CUMUL = 'ENG')
               )
           and
               --Ctrl_c_etat_journal
               (   PARAMETER_11 = '1'
                or (    PARAMETER_11 = '0'
                    and EJO.C_ETAT_JOURNAL <> 'BRO') );
    else
      open aRefCursor for
        select PAR.PAR_DOCUMENT
             , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
             , (select CUB.CURRENCY
                  from PCS.PC_CURR CUB
                     , ACS_FINANCIAL_CURRENCY CFB
                 where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                   and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_MB
             , PAR.ACS_FINANCIAL_CURRENCY_ID
             , (select CUB.CURRENCY
                  from PCS.PC_CURR CUB
                     , ACS_FINANCIAL_CURRENCY CFB
                 where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_FINANCIAL_CURRENCY_ID
                   and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_ME
             , DOC.DOC_NUMBER
             , CAT.C_TYPE_CATALOGUE
             , SUB.C_TYPE_CUMUL
             , exp.ACT_EXPIRY_ID
             , exp.ACT_DOCUMENT_ID
             , exp.ACT_PART_IMPUTATION_ID
             , exp.C_STATUS_EXPIRY
             , case
                 when(PROCPARAM_7 = 1)
                 and (ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, to_date(PROCPARAM_2, 'YYYYMMDD'), 1) <> 0) then ACT_FUNCTIONS.DiscountDateAfter
                                                                                                                                             (exp.ACT_DOCUMENT_ID
                                                                                                                                            , exp.EXP_SLICE
                                                                                                                                            , to_date
                                                                                                                                                   (PROCPARAM_2
                                                                                                                                                  , 'YYYYMMDD'
                                                                                                                                                   )
                                                                                                                                             )
                 else exp.EXP_ADAPTED
               end EXP_ADAPTED
             , exp.EXP_CALCULATED
             , to_date(PROCPARAM_2, 'YYYYMMDD') - exp.EXP_ADAPTED DAYS
             , exp.EXP_AMOUNT_LC
             , exp.EXP_AMOUNT_FC
             , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, to_date(PROCPARAM_2, 'YYYYMMDD'), 1) DISCOUNT_LC
             , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, to_date(PROCPARAM_2, 'YYYYMMDD'), 0) DISCOUNT_FC
             , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD'), 1) DET_PAIED_LC
             , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD'), 0) DET_PAIED_FC
             , exp.EXP_AMOUNT_LC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD'), 1) SOLDE_EXP_LC
             , exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD'), 0) SOLDE_EXP_FC
             , ACT_CURRENCY_EVALUATION.GetConvertAmount(exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD'), 0)
                                                      , PAR.ACS_FINANCIAL_CURRENCY_ID
                                                      , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                      , to_date(PROCPARAM_2, 'YYYYMMDD')
                                                      , PROCPARAM_6
                                                       ) SOLDE_REEVAL_LC
             , exp.EXP_SLICE
             , exp.ACS_FIN_ACC_S_PAYMENT_ID
             , ACT_FUNCTIONS.LastClaimsNumber(exp.ACT_EXPIRY_ID) LAST_CLAIMS_LEVEL
             , ACT_FUNCTIONS.LastClaimsDate(exp.ACT_EXPIRY_ID) LAST_CLAIMS_DATE
             , CO2.PCO_DESCR PCO_DESCR_EXP
             , IMP.ACS_PERIOD_ID
             , IMP.IMF_TRANSACTION_DATE
             , IMP.IMF_VALUE_DATE
             , IMP.IMF_DESCRIPTION
             , IMP.ACS_FINANCIAL_ACCOUNT_ID
             , (select ACF.ACC_NUMBER
                  from ACS_ACCOUNT ACF
                 where ACF.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID) ACC_NUMBER_FIN
             , (select DE1.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE1
                 where DE1.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
                   and DE1.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_FIN_DESCR
             , JOU.JOU_NUMBER
             , EJO.C_ETAT_JOURNAL
             , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
             , (select ACD.ACC_NUMBER
                  from ACS_ACCOUNT ACD
                 where ACD.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV
             , (select DE2.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE2
                 where DE2.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                   and DE2.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_DIV_DESCR
             , SUP.PAC_SUPPLIER_PARTNER_ID
             , SUP.ACS_AUXILIARY_ACCOUNT_ID
             , SUP.C_PARTNER_CATEGORY
             , CO1.PCO_DESCR PCO_DESCR_SUP
             , ACC.ACC_NUMBER ACC_NUMBER_AUX
             , (select DE3.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE3
                 where DE3.ACS_ACCOUNT_ID = SUP.ACS_AUXILIARY_ACCOUNT_ID
                   and DE3.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_AUX_DESCR
             , (select DE4.DES_DESCRIPTION_LARGE
                  from ACS_DESCRIPTION DE4
                 where DE4.ACS_ACCOUNT_ID = SUP.ACS_AUXILIARY_ACCOUNT_ID
                   and DE4.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_AUX_LARGE_DESCR
             , ACC.ACS_SUB_SET_ID
             , (select DE5.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE5
                 where DE5.ACS_SUB_SET_ID = ACC.ACS_SUB_SET_ID
                   and DE5.PC_LANG_ID = VPC_LANG_ID) SUB_SET_DESCR
             , AUX.C_TYPE_ACCOUNT
             , PER.PER_NAME
             , PER.PER_FORENAME
             , PER.PER_SHORT_NAME
             , PER.PER_ACTIVITY
             , PER.PER_KEY1
             , (select ADR.ADD_FORMAT
                  from PAC_ADDRESS ADR
                 where ADR.PAC_PERSON_ID = SUP.PAC_SUPPLIER_PARTNER_ID
                   and ADR.ADD_PRINCIPAL = '1') ADD_FORMAT
             , (select DE6.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE6
                 where DE6.ACS_PAYMENT_METHOD_ID = PFC.ACS_PAYMENT_METHOD_ID
                   and DE6.PC_LANG_ID = VPC_LANG_ID) ACS_PAYMENT_METHOD_DESCR_SUPP
             , (select DE7.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE7
                 where DE7.ACS_PAYMENT_METHOD_ID = PFE.ACS_PAYMENT_METHOD_ID
                   and DE7.PC_LANG_ID = VPC_LANG_ID) ACS_PAYMENT_METHOD_DESCR_EXP
          from ACS_PAYMENT_METHOD PAE
             , ACS_FIN_ACC_S_PAYMENT PFE
             , ACS_PAYMENT_METHOD PAC
             , ACS_FIN_ACC_S_PAYMENT PFC
             , PAC_PAYMENT_CONDITION CO2
             , PAC_PAYMENT_CONDITION CO1
             , PAC_PERSON PER
             , ACS_AUXILIARY_ACCOUNT AUX
             , PAC_SUPPLIER_PARTNER SUP
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACT_FINANCIAL_IMPUTATION IMP
             , ACT_ETAT_JOURNAL EJO
             , ACT_JOURNAL JOU
             , ACT_EXPIRY exp
             , ACJ_CATALOGUE_DOCUMENT CAT
             , ACT_DOCUMENT DOC
             , ACT_PART_IMPUTATION PAR
             , ACS_ACCOUNT ACC
             , (select C_TYPE_CUMUL
                     , ACJ_CATALOGUE_DOCUMENT_ID
                  from ACJ_SUB_SET_CAT
                 where C_SUB_SET = 'PAY') SUB
         where PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
           and CAT.C_TYPE_CATALOGUE <> '8'
           and   -- Transaction de relance
               PAR.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
           and EXP_CALC_NET + 0 = 1
           and ACT_EXPIRY_MANAGEMENT.IsExpiryOpenedAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD') ) = 1
           and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
           and DOC.ACT_JOURNAL_ID = EJO.ACT_JOURNAL_ID
           and EJO.C_SUB_SET = 'PAY'
           and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
           and IMP.ACT_DET_PAYMENT_ID is null
           and IMP.ACS_AUXILIARY_ACCOUNT_ID is not null
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and (   IMP.IMF_TRANSACTION_DATE <= to_date(PROCPARAM_2, 'YYYYMMDD')
                or PROCPARAM_2 is null)
           and FIN.FIN_COLLECTIVE = 1
           and ACC.ACC_NUMBER >= PROCPARAM_0
           and ACC.ACC_NUMBER <= PROCPARAM_1
           and (   ACC.ACS_SUB_SET_ID = PROCPARAM_3
                or PROCPARAM_3 is null)
           and (   instr(',' || PROCPARAM_4 || ',', to_char(',' || IMP.IMF_ACS_DIVISION_ACCOUNT_ID || ',') ) > 0
                or PROCPARAM_4 is null)
           and (   instr(',' || PROCPARAM_5 || ',', to_char(',' || FIN.ACS_FINANCIAL_ACCOUNT_ID || ',') ) > 0
                or PROCPARAM_5 is null)
           and PAR.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID
           and SUP.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and SUP.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
           and SUP.PAC_SUPPLIER_PARTNER_ID = PER.PAC_PERSON_ID
           and SUP.PAC_PAYMENT_CONDITION_ID = CO1.PAC_PAYMENT_CONDITION_ID
           and PAR.PAC_PAYMENT_CONDITION_ID = CO2.PAC_PAYMENT_CONDITION_ID(+)
           and SUP.ACS_FIN_ACC_S_PAYMENT_ID = PFC.ACS_FIN_ACC_S_PAYMENT_ID(+)
           and PFC.ACS_PAYMENT_METHOD_ID = PAC.ACS_PAYMENT_METHOD_ID(+)
           and exp.ACS_FIN_ACC_S_PAYMENT_ID = PFE.ACS_FIN_ACC_S_PAYMENT_ID(+)
           and PFE.ACS_PAYMENT_METHOD_ID = PAE.ACS_PAYMENT_METHOD_ID(+)
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SUB.ACJ_CATALOGUE_DOCUMENT_ID(+)
           and
               --Ctrl_only)expired
               (   PARAMETER_1 = '0'
                or (    PARAMETER_1 = '1'
                    and (case
                           when(PROCPARAM_7 = 1)
                           and (ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, sysdate, 1) <> 0) then ACT_FUNCTIONS.DiscountDateAfter
                                                                                                                                           (exp.ACT_DOCUMENT_ID
                                                                                                                                          , exp.EXP_SLICE
                                                                                                                                          , sysdate
                                                                                                                                           )
                           else exp.EXP_ADAPTED
                         end
                        ) <= to_date(PARAMETER_2, 'YYYYMMDD')
                   )
               )
           and
               --Ctrl_c_type_cumul
               (    (    PARAMETER_3 = '1'
                     and SUB.C_TYPE_CUMUL = 'INT')
                or (    PARAMETER_4 = '1'
                    and SUB.C_TYPE_CUMUL = 'EXT')
                or (    PARAMETER_5 = '1'
                    and SUB.C_TYPE_CUMUL = 'PRE')
                or (    PARAMETER_6 = '1'
                    and SUB.C_TYPE_CUMUL = 'ENG')
               )
           and
               --Ctrl_c_etat_journal
               (   PARAMETER_11 = '1'
                or (    PARAMETER_11 = '0'
                    and EJO.C_ETAT_JOURNAL <> 'BRO') );
    end if;
  end ACT_AGED_BALANCE_SUPP_RPT_PK;

/**
* Procédure stockée utilisée pour le rapport ACT_AGED_BALANCE_CUST (Balance âgée clients)
*
*                                            2 : Cours d'évaluation
*                                            3 : Cours d'inventaire
*                                            4 : Cours de bouclement
*                                            5 : Cours de facturation
*/
  procedure ACT_AGED_BALANCE_CUST_RPT_PK(
    aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
  , PARAMETER_1    in     varchar2
  , PARAMETER_2    in     varchar2
  , PARAMETER_3    in     varchar2
  , PARAMETER_4    in     varchar2
  , PARAMETER_5    in     varchar2
  , PARAMETER_6    in     varchar2
  , PARAMETER_11   in     varchar2
  , PROCPARAM_0    in     varchar2
  , PROCPARAM_1    in     varchar2
  , PROCPARAM_2    in     varchar2
  , PROCPARAM_3    in     varchar2
  , PROCPARAM_4    in     varchar2
  , PROCPARAM_5    in     varchar2
  , PROCPARAM_6    in     number
  , PROCPARAM_7    in     number
  , PROCUSER_LANID in     pcs.pc_lang.lanid%type
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    if (PROCPARAM_2 is null) then
      open aRefCursor for
        select PAR.PAR_DOCUMENT
             , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
             , (select CUB.CURRENCY
                  from PCS.PC_CURR CUB
                     , ACS_FINANCIAL_CURRENCY CFB
                 where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                   and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_MB
             , PAR.ACS_FINANCIAL_CURRENCY_ID
             , (select CUB.CURRENCY
                  from PCS.PC_CURR CUB
                     , ACS_FINANCIAL_CURRENCY CFB
                 where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_FINANCIAL_CURRENCY_ID
                   and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_ME
             , DOC.DOC_NUMBER
             , CAT.C_TYPE_CATALOGUE
             , SUB.C_TYPE_CUMUL
             , exp.ACT_EXPIRY_ID
             , exp.ACT_DOCUMENT_ID
             , exp.ACT_PART_IMPUTATION_ID
             , exp.C_STATUS_EXPIRY
             , case
                 when(PROCPARAM_7 = 1)
                 and (ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, sysdate, 1) <> 0) then ACT_FUNCTIONS.DiscountDateAfter
                                                                                                                                           (exp.ACT_DOCUMENT_ID
                                                                                                                                          , exp.EXP_SLICE
                                                                                                                                          , sysdate
                                                                                                                                           )
                 else exp.EXP_ADAPTED
               end EXP_ADAPTED
             , exp.EXP_CALCULATED
             , to_date(sysdate) - exp.EXP_ADAPTED DAYS
             , exp.EXP_AMOUNT_LC
             , exp.EXP_AMOUNT_FC
             , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, sysdate, 1) DISCOUNT_LC
             , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, sysdate, 0) DISCOUNT_FC
             , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 1) DET_PAIED_LC
             , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 0) DET_PAIED_FC
             , exp.EXP_AMOUNT_LC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 1) SOLDE_EXP_LC
             , exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 0) SOLDE_EXP_FC
             , ACT_CURRENCY_EVALUATION.GetConvertAmount(exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, sysdate, 0)
                                                      , PAR.ACS_FINANCIAL_CURRENCY_ID
                                                      , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                      , sysdate
                                                      , PROCPARAM_6
                                                       ) SOLDE_REEVAL_LC
             , exp.EXP_SLICE
             , exp.ACS_FIN_ACC_S_PAYMENT_ID
             , ACT_FUNCTIONS.LastClaimsNumber(exp.ACT_EXPIRY_ID) LAST_CLAIMS_LEVEL
             , ACT_FUNCTIONS.LastClaimsDate(exp.ACT_EXPIRY_ID) LAST_CLAIMS_DATE
             , CO2.PCO_DESCR PCO_DESCR_EXP
             , IMP.ACS_PERIOD_ID
             , IMP.IMF_TRANSACTION_DATE
             , IMP.IMF_VALUE_DATE
             , IMP.IMF_DESCRIPTION
             , IMP.ACS_FINANCIAL_ACCOUNT_ID
             , (select ACF.ACC_NUMBER
                  from ACS_ACCOUNT ACF
                 where ACF.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID) ACC_NUMBER_FIN
             , (select DE1.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE1
                 where DE1.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
                   and DE1.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_FIN_DESCR
             , JOU.JOU_NUMBER
             , EJO.C_ETAT_JOURNAL
             , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
             , (select ACD.ACC_NUMBER
                  from ACS_ACCOUNT ACD
                 where ACD.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV
             , (select DE2.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE2
                 where DE2.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                   and DE2.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_DIV_DESCR
             , CUS.PAC_CUSTOM_PARTNER_ID
             , CUS.ACS_AUXILIARY_ACCOUNT_ID
             , CUS.C_PARTNER_CATEGORY
             , CO1.PCO_DESCR PCO_DESCR_CUS
             , ACC.ACC_NUMBER ACC_NUMBER_AUX
             , (select DE3.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE3
                 where DE3.ACS_ACCOUNT_ID = CUS.ACS_AUXILIARY_ACCOUNT_ID
                   and DE3.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_AUX_DESCR
             , (select DE4.DES_DESCRIPTION_LARGE
                  from ACS_DESCRIPTION DE4
                 where DE4.ACS_ACCOUNT_ID = CUS.ACS_AUXILIARY_ACCOUNT_ID
                   and DE4.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_AUX_LARGE_DESCR
             , ACC.ACS_SUB_SET_ID
             , (select DE5.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE5
                 where DE5.ACS_SUB_SET_ID = ACC.ACS_SUB_SET_ID
                   and DE5.PC_LANG_ID = VPC_LANG_ID) SUB_SET_DESCR
             , AUX.C_TYPE_ACCOUNT
             , PER.PER_NAME
             , PER.PER_FORENAME
             , PER.PER_SHORT_NAME
             , PER.PER_ACTIVITY
             , PER.PER_KEY1
             , (select ADR.ADD_FORMAT
                  from PAC_ADDRESS ADR
                 where ADR.PAC_PERSON_ID = CUS.PAC_CUSTOM_PARTNER_ID
                   and ADR.ADD_PRINCIPAL = '1') ADD_FORMAT
             , (select DE6.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE6
                 where DE6.ACS_PAYMENT_METHOD_ID = PFC.ACS_PAYMENT_METHOD_ID
                   and DE6.PC_LANG_ID = VPC_LANG_ID) ACS_PAYMENT_METHOD_DESCR_CUST
             , (select DE7.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE7
                 where DE7.ACS_PAYMENT_METHOD_ID = PFE.ACS_PAYMENT_METHOD_ID
                   and DE7.PC_LANG_ID = VPC_LANG_ID) ACS_PAYMENT_METHOD_DESCR_EXP
          from ACS_PAYMENT_METHOD PAE
             , ACS_FIN_ACC_S_PAYMENT PFE
             , ACS_PAYMENT_METHOD PAC
             , ACS_FIN_ACC_S_PAYMENT PFC
             , PAC_PAYMENT_CONDITION CO2
             , PAC_PAYMENT_CONDITION CO1
             , PAC_PERSON PER
             , ACS_AUXILIARY_ACCOUNT AUX
             , PAC_CUSTOM_PARTNER CUS
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACT_FINANCIAL_IMPUTATION IMP
             , ACT_ETAT_JOURNAL EJO
             , ACT_JOURNAL JOU
             , ACT_EXPIRY exp
             , ACJ_CATALOGUE_DOCUMENT CAT
             , ACT_DOCUMENT DOC
             , ACT_PART_IMPUTATION PAR
             , ACS_ACCOUNT ACC
             , (select C_TYPE_CUMUL
                     , ACJ_CATALOGUE_DOCUMENT_ID
                  from ACJ_SUB_SET_CAT
                 where C_SUB_SET = 'REC') SUB
         where PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
           and CAT.C_TYPE_CATALOGUE <> '8'
           and   -- Transaction de relance
               PAR.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
           and EXP_CALC_NET + 0 = 1
           and ACT_EXPIRY_MANAGEMENT.IsExpiryOpenedAt(exp.ACT_EXPIRY_ID, sysdate) = 1
           and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
           and DOC.ACT_JOURNAL_ID = EJO.ACT_JOURNAL_ID
           and EJO.C_SUB_SET = 'REC'
           and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
           and IMP.ACT_DET_PAYMENT_ID is null
           and IMP.ACS_AUXILIARY_ACCOUNT_ID is not null
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and exp.C_STATUS_EXPIRY = 0
           and FIN.FIN_COLLECTIVE = 1
           and ACC.ACC_NUMBER >= PROCPARAM_0
           and ACC.ACC_NUMBER <= PROCPARAM_1
           and (   ACC.ACS_SUB_SET_ID = PROCPARAM_3
                or PROCPARAM_3 is null)
           and (   instr(',' || PROCPARAM_4 || ',', to_char(',' || IMP.IMF_ACS_DIVISION_ACCOUNT_ID || ',') ) > 0
                or PROCPARAM_4 is null)
           and (   instr(',' || PROCPARAM_5 || ',', to_char(',' || FIN.ACS_FINANCIAL_ACCOUNT_ID || ',') ) > 0
                or PROCPARAM_5 is null)
           and PAR.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
           and CUS.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and CUS.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
           and CUS.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
           and CUS.PAC_PAYMENT_CONDITION_ID = CO1.PAC_PAYMENT_CONDITION_ID
           and PAR.PAC_PAYMENT_CONDITION_ID = CO2.PAC_PAYMENT_CONDITION_ID(+)
           and CUS.ACS_FIN_ACC_S_PAYMENT_ID = PFC.ACS_FIN_ACC_S_PAYMENT_ID(+)
           and PFC.ACS_PAYMENT_METHOD_ID = PAC.ACS_PAYMENT_METHOD_ID(+)
           and exp.ACS_FIN_ACC_S_PAYMENT_ID = PFE.ACS_FIN_ACC_S_PAYMENT_ID(+)
           and PFE.ACS_PAYMENT_METHOD_ID = PAE.ACS_PAYMENT_METHOD_ID(+)
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SUB.ACJ_CATALOGUE_DOCUMENT_ID(+)
           and
               --Ctrl_only)expired
               (   PARAMETER_1 = '0'
                or (    PARAMETER_1 = '1'
                    and (case
                           when(PROCPARAM_7 = 1)
                           and (ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, sysdate, 1) <> 0) then ACT_FUNCTIONS.DiscountDateAfter
                                                                                                                                           (exp.ACT_DOCUMENT_ID
                                                                                                                                          , exp.EXP_SLICE
                                                                                                                                          , sysdate
                                                                                                                                           )
                           else exp.EXP_ADAPTED
                         end
                        ) <= to_date(PARAMETER_2, 'YYYYMMDD')
                   )
               )
           and
               --Ctrl_c_type_cumul
               (    (    PARAMETER_3 = '1'
                     and SUB.C_TYPE_CUMUL = 'INT')
                or (    PARAMETER_4 = '1'
                    and SUB.C_TYPE_CUMUL = 'EXT')
                or (    PARAMETER_5 = '1'
                    and SUB.C_TYPE_CUMUL = 'PRE')
                or (    PARAMETER_6 = '1'
                    and SUB.C_TYPE_CUMUL = 'ENG')
               )
           and
               --Ctrl_c_etat_journal
               (   PARAMETER_11 = '1'
                or (    PARAMETER_11 = '0'
                    and EJO.C_ETAT_JOURNAL <> 'BRO') );
    else
      open aRefCursor for
        select PAR.PAR_DOCUMENT
             , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
             , (select CUB.CURRENCY
                  from PCS.PC_CURR CUB
                     , ACS_FINANCIAL_CURRENCY CFB
                 where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                   and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_MB
             , PAR.ACS_FINANCIAL_CURRENCY_ID
             , (select CUB.CURRENCY
                  from PCS.PC_CURR CUB
                     , ACS_FINANCIAL_CURRENCY CFB
                 where CFB.ACS_FINANCIAL_CURRENCY_ID = PAR.ACS_FINANCIAL_CURRENCY_ID
                   and CUB.PC_CURR_ID = CFB.PC_CURR_ID) CURRENCY_ME
             , DOC.DOC_NUMBER
             , SUB.C_TYPE_CUMUL
             , exp.ACT_EXPIRY_ID
             , exp.ACT_DOCUMENT_ID
             , exp.ACT_PART_IMPUTATION_ID
             , exp.C_STATUS_EXPIRY
             , case
                 when(PROCPARAM_7 = 1)
                 and (ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, to_date(PROCPARAM_2, 'YYYYMMDD'), 1) <> 0) then ACT_FUNCTIONS.DiscountDateAfter
                                                                                                                                             (exp.ACT_DOCUMENT_ID
                                                                                                                                            , exp.EXP_SLICE
                                                                                                                                            , to_date
                                                                                                                                                   (PROCPARAM_2
                                                                                                                                                  , 'YYYYMMDD'
                                                                                                                                                   )
                                                                                                                                             )
                 else exp.EXP_ADAPTED
               end EXP_ADAPTED
             , exp.EXP_CALCULATED
             , to_date(PROCPARAM_2, 'YYYYMMDD') - exp.EXP_ADAPTED DAYS
             , exp.EXP_AMOUNT_LC
             , exp.EXP_AMOUNT_FC
             , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, to_date(PROCPARAM_2, 'YYYYMMDD'), 1) DISCOUNT_LC
             , ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, to_date(PROCPARAM_2, 'YYYYMMDD'), 0) DISCOUNT_FC
             , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD'), 1) DET_PAIED_LC
             , ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD'), 0) DET_PAIED_FC
             , exp.EXP_AMOUNT_LC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD'), 1) SOLDE_EXP_LC
             , exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD'), 0) SOLDE_EXP_FC
             , ACT_CURRENCY_EVALUATION.GetConvertAmount(exp.EXP_AMOUNT_FC - ACT_FUNCTIONS.TotalPaymentAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD'), 0)
                                                      , PAR.ACS_FINANCIAL_CURRENCY_ID
                                                      , PAR.ACS_ACS_FINANCIAL_CURRENCY_ID
                                                      , to_date(PROCPARAM_2, 'YYYYMMDD')
                                                      , PROCPARAM_6
                                                       ) SOLDE_REEVAL_LC
             , exp.EXP_SLICE
             , exp.ACS_FIN_ACC_S_PAYMENT_ID
             , ACT_FUNCTIONS.LastClaimsNumber(exp.ACT_EXPIRY_ID) LAST_CLAIMS_LEVEL
             , ACT_FUNCTIONS.LastClaimsDate(exp.ACT_EXPIRY_ID) LAST_CLAIMS_DATE
             , CO2.PCO_DESCR PCO_DESCR_EXP
             , IMP.ACS_PERIOD_ID
             , IMP.IMF_TRANSACTION_DATE
             , IMP.IMF_VALUE_DATE
             , IMP.IMF_DESCRIPTION
             , IMP.ACS_FINANCIAL_ACCOUNT_ID
             , (select ACF.ACC_NUMBER
                  from ACS_ACCOUNT ACF
                 where ACF.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID) ACC_NUMBER_FIN
             , (select DE1.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE1
                 where DE1.ACS_ACCOUNT_ID = IMP.ACS_FINANCIAL_ACCOUNT_ID
                   and DE1.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_FIN_DESCR
             , JOU.JOU_NUMBER
             , EJO.C_ETAT_JOURNAL
             , IMP.IMF_ACS_DIVISION_ACCOUNT_ID
             , (select ACD.ACC_NUMBER
                  from ACS_ACCOUNT ACD
                 where ACD.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV
             , (select DE2.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE2
                 where DE2.ACS_ACCOUNT_ID = IMP.IMF_ACS_DIVISION_ACCOUNT_ID
                   and DE2.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_DIV_DESCR
             , CUS.PAC_CUSTOM_PARTNER_ID
             , CUS.ACS_AUXILIARY_ACCOUNT_ID
             , CUS.C_PARTNER_CATEGORY
             , CO1.PCO_DESCR PCO_DESCR_CUS
             , ACC.ACC_NUMBER ACC_NUMBER_AUX
             , (select DE3.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE3
                 where DE3.ACS_ACCOUNT_ID = CUS.ACS_AUXILIARY_ACCOUNT_ID
                   and DE3.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_AUX_DESCR
             , (select DE4.DES_DESCRIPTION_LARGE
                  from ACS_DESCRIPTION DE4
                 where DE4.ACS_ACCOUNT_ID = CUS.ACS_AUXILIARY_ACCOUNT_ID
                   and DE4.PC_LANG_ID = VPC_LANG_ID) ACCOUNT_AUX_LARGE_DESCR
             , ACC.ACS_SUB_SET_ID
             , (select DE5.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE5
                 where DE5.ACS_SUB_SET_ID = ACC.ACS_SUB_SET_ID
                   and DE5.PC_LANG_ID = VPC_LANG_ID) SUB_SET_DESCR
             , AUX.C_TYPE_ACCOUNT
             , PER.PER_NAME
             , PER.PER_FORENAME
             , PER.PER_SHORT_NAME
             , PER.PER_ACTIVITY
             , PER.PER_KEY1
             , (select ADR.ADD_FORMAT
                  from PAC_ADDRESS ADR
                 where ADR.PAC_PERSON_ID = CUS.PAC_CUSTOM_PARTNER_ID
                   and ADR.ADD_PRINCIPAL = '1') ADD_FORMAT
             , (select DE6.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE6
                 where DE6.ACS_PAYMENT_METHOD_ID = PFC.ACS_PAYMENT_METHOD_ID
                   and DE6.PC_LANG_ID = VPC_LANG_ID) ACS_PAYMENT_METHOD_DESCR_CUST
             , (select DE7.DES_DESCRIPTION_SUMMARY
                  from ACS_DESCRIPTION DE7
                 where DE7.ACS_PAYMENT_METHOD_ID = PFE.ACS_PAYMENT_METHOD_ID
                   and DE7.PC_LANG_ID = VPC_LANG_ID) ACS_PAYMENT_METHOD_DESCR_EXP
          from ACS_PAYMENT_METHOD PAE
             , ACS_FIN_ACC_S_PAYMENT PFE
             , ACS_PAYMENT_METHOD PAC
             , ACS_FIN_ACC_S_PAYMENT PFC
             , PAC_PAYMENT_CONDITION CO2
             , PAC_PAYMENT_CONDITION CO1
             , PAC_PERSON PER
             , ACS_AUXILIARY_ACCOUNT AUX
             , PAC_CUSTOM_PARTNER CUS
             , ACS_FINANCIAL_ACCOUNT FIN
             , ACT_FINANCIAL_IMPUTATION IMP
             , ACT_ETAT_JOURNAL EJO
             , ACT_JOURNAL JOU
             , ACT_EXPIRY exp
             , ACJ_CATALOGUE_DOCUMENT CAT
             , ACT_DOCUMENT DOC
             , ACT_PART_IMPUTATION PAR
             , ACS_ACCOUNT ACC
             , (select C_TYPE_CUMUL
                     , ACJ_CATALOGUE_DOCUMENT_ID
                  from ACJ_SUB_SET_CAT
                 where C_SUB_SET = 'REC') SUB
         where PAR.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = CAT.ACJ_CATALOGUE_DOCUMENT_ID
           and CAT.C_TYPE_CATALOGUE <> '8'
           and   -- Transaction de relance
               PAR.ACT_PART_IMPUTATION_ID = exp.ACT_PART_IMPUTATION_ID
           and EXP_CALC_NET + 0 = 1
           and ACT_EXPIRY_MANAGEMENT.IsExpiryOpenedAt(exp.ACT_EXPIRY_ID, to_date(PROCPARAM_2, 'YYYYMMDD') ) = 1
           and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
           and DOC.ACT_JOURNAL_ID = EJO.ACT_JOURNAL_ID
           and EJO.C_SUB_SET = 'REC'
           and exp.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
           and IMP.ACT_DET_PAYMENT_ID is null
           and IMP.ACS_AUXILIARY_ACCOUNT_ID is not null
           and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
           and (   IMP.IMF_TRANSACTION_DATE <= to_date(PROCPARAM_2, 'YYYYMMDD')
                or PROCPARAM_2 is null)
           and FIN.FIN_COLLECTIVE = 1
           and ACC.ACC_NUMBER >= PROCPARAM_0
           and ACC.ACC_NUMBER <= PROCPARAM_1
           and (   ACC.ACS_SUB_SET_ID = PROCPARAM_3
                or PROCPARAM_3 is null)
           and (   instr(',' || PROCPARAM_4 || ',', to_char(',' || IMP.IMF_ACS_DIVISION_ACCOUNT_ID || ',') ) > 0
                or PROCPARAM_4 is null)
           and (   instr(',' || PROCPARAM_5 || ',', to_char(',' || FIN.ACS_FINANCIAL_ACCOUNT_ID || ',') ) > 0
                or PROCPARAM_5 is null)
           and PAR.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
           and CUS.ACS_AUXILIARY_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
           and CUS.ACS_AUXILIARY_ACCOUNT_ID = AUX.ACS_AUXILIARY_ACCOUNT_ID
           and CUS.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
           and CUS.PAC_PAYMENT_CONDITION_ID = CO1.PAC_PAYMENT_CONDITION_ID
           and PAR.PAC_PAYMENT_CONDITION_ID = CO2.PAC_PAYMENT_CONDITION_ID(+)
           and CUS.ACS_FIN_ACC_S_PAYMENT_ID = PFC.ACS_FIN_ACC_S_PAYMENT_ID(+)
           and PFC.ACS_PAYMENT_METHOD_ID = PAC.ACS_PAYMENT_METHOD_ID(+)
           and exp.ACS_FIN_ACC_S_PAYMENT_ID = PFE.ACS_FIN_ACC_S_PAYMENT_ID(+)
           and PFE.ACS_PAYMENT_METHOD_ID = PAE.ACS_PAYMENT_METHOD_ID(+)
           and DOC.ACJ_CATALOGUE_DOCUMENT_ID = SUB.ACJ_CATALOGUE_DOCUMENT_ID(+)
           and
               --Ctrl_only)expired
               (   PARAMETER_1 = '0'
                or (    PARAMETER_1 = '1'
                    and (case
                           when(PROCPARAM_7 = 1)
                           and (ACT_FUNCTIONS.DiscountAmountAfter(exp.ACT_DOCUMENT_ID, exp.EXP_SLICE, sysdate, 1) <> 0) then ACT_FUNCTIONS.DiscountDateAfter
                                                                                                                                           (exp.ACT_DOCUMENT_ID
                                                                                                                                          , exp.EXP_SLICE
                                                                                                                                          , sysdate
                                                                                                                                           )
                           else exp.EXP_ADAPTED
                         end
                        ) <= to_date(PARAMETER_2, 'YYYYMMDD')
                   )
               )
           and
               --Ctrl_c_type_cumul
               (    (    PARAMETER_3 = '1'
                     and SUB.C_TYPE_CUMUL = 'INT')
                or (    PARAMETER_4 = '1'
                    and SUB.C_TYPE_CUMUL = 'EXT')
                or (    PARAMETER_5 = '1'
                    and SUB.C_TYPE_CUMUL = 'PRE')
                or (    PARAMETER_6 = '1'
                    and SUB.C_TYPE_CUMUL = 'ENG')
               )
           and
               --Ctrl_c_etat_journal
               (   PARAMETER_11 = '1'
                or (    PARAMETER_11 = '0'
                    and EJO.C_ETAT_JOURNAL <> 'BRO') );
    end if;
  end ACT_AGED_BALANCE_CUST_RPT_PK;
end ACT_RPT;
