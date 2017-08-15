--------------------------------------------------------
--  DDL for Procedure RPT_ACR_VAT_FORM_OFF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_VAT_FORM_OFF" (
  arefcursor     in out CRYSTAL_CURSOR_TYPES.dualcursortyp
, procuser_lanid in     PCS.PC_LANG.lanid%type
, parameter_0    in     varchar2
, parameter_1    in     varchar2
, parameter_2    in     varchar2
, parameter_3    in     varchar2
, parameter_4    in     varchar2
, parameter_5    in     varchar2
, parameter_6    in     varchar2
, parameter_7    in     varchar2
, parameter_10   in     varchar2
, parameter_11   in     varchar2
, parameter_12   in     varchar2
, parameter_13   in     varchar2
, parameter_14   in     varchar2
, parameter_15   in     varchar2
, parameter_17   in     varchar2
)
/**
*Description

 Used for report ACR_VAT_FORM_OFF, ACR_VAT_FORM_OFF_2010, ACR_VAT_FORM_OFF_2011
*@created VHA 17 July 2013
*@lastUpdate
*@public
*@PARAM procuser_lanid User language id
*@PARAM parameter_0   Year(from)
*@PARAM parameter_1   Month(from)
*@PARAM parameter_2   Day(from)
*@PARAM parameter_3   Year(to)
*@PARAM parameter_4   Month(to)
*@PARAM parameter_5   Day(to)
*@PARAM parameter_6   ACC_NUMBER(from)
*@PARAM parameter_7   ACC_NUMBER(to)
*@PARAM parameter_10  C_TYPE_CUMUL = INT : 0=No / 1=Yes
*@PARAM parameter_11  C_TYPE_CUMUL = EXT : 0=No / 1=Yes
*@PARAM parameter_12  C_TYPE_CUMUL = PRE : 0=No / 1=Yes
*@PARAM parameter_13  C_TYPE_CUMUL = ENG : 0=No / 1=Yes
*@PARAM parameter_14  Def. print : 0=No / 1=Yes
*@PARAM parameter_15  ACT_VAT_DET_ACCOUNT_ID
*@PARAM parameter_17  ACS_VAT_DET_ACCOUNT_ID
*/
is
  vpc_lang_id PCS.PC_LANG.PC_LANG_ID%type   := null;
begin
  if (parameter_0 is not null and parameter_1 is not null and parameter_2 is not null) then
    ACT_FUNCTIONS.date_from  := to_date(parameter_0 || lpad(parameter_1, 2, '0') || lpad(parameter_2, 2, '0'), 'YYYYMMDD');
    PCS.PC_I_LIB_SESSION.setlanid(procuser_lanid);
    vpc_lang_id              := PCS.PC_I_LIB_SESSION.getuserlangid;
  end if;

  if (parameter_3 is not null and parameter_4 is not null and parameter_5 is not null) then
    ACT_FUNCTIONS.date_to  := to_date(parameter_3 || lpad(parameter_4, 2, '0') || lpad(parameter_5, 2, '0'), 'YYYYMMDD');
  end if;

  if     (parameter_15 is not null)
     and (length(trim(parameter_15) ) > 0)
     and (parameter_15 <> '0') then
    ACT_FUNCTIONS.vat_det_acc_id  := parameter_15;
  end if;

  if (parameter_14 = '1') then
    update ACT_VAT_DET_ACCOUNT VAT
       set VAT.C_VAT_TAX_DET_ACC_STATUS = '2'
     where VAT.ACT_VAT_DET_ACCOUNT_ID = to_number(parameter_15);
  end if;

  if (procuser_lanid is not null) then
    PCS.PC_I_LIB_SESSION.setlanid(procuser_lanid);
    vpc_lang_id              := PCS.PC_I_LIB_SESSION.getuserlangid;
  end if;

  open arefcursor for
    select DOC.DOC_NUMBER,
       V_TAX.HT_LC,
       V_TAX.TTC_LC,
       V_TAX.TAX_VAT_AMOUNT_LC,
       V_TAX.HT_FC,
       V_TAX.TTC_FC,
       V_TAX.TAX_VAT_AMOUNT_FC,
       V_TAX.C_TYPE_CUMUL,
       V_TAX.TAX_TMP_VAT_ENCASHMENT,
       V_TAX.TAX_INCLUDED_EXCLUDED,
       V_TAX.ACS_TAX_CODE_ID,
       V_TAX.ACT_FINANCIAL_IMPUTATION_ID,
       V_TAX.ACT_DOCUMENT_ID,
       V_TAX.TAX_REDUCTION,
       V_TAX. TAX_RATE_REF,
       TAX.DIC_NO_POS_CALC_SHEET_ID,
       TAX.DIC_NO_POS_CALC_SHEET2_ID,
       TAX.DIC_NO_POS_CALC_SHEET3_ID,
       TAX.DIC_NO_POS_CALC_SHEET4_ID,
       TAX.DIC_NO_POS_CALC_SHEET5_ID,
       TAX.DIC_NO_POS_CALC_SHEET6_ID,
       TAX.C_ESTABLISHING_CALC_SHEET,
       YEA.FYE_NO_EXERCICE,
       YEA1.FYE_NO_EXERCICE FYE_NO_EXERCICE1,
       ACC.ACC_NUMBER,
       CAT.CAT_DESCRIPTION,
       VAT.ACS_VAT_DET_ACCOUNT_ID,
       VAT.VDE_VAT_NUMBER,
       VAT1.ACT_VAT_DET_ACCOUNT_ID,
       VAT1.VTD_NUMBER,
       IMP.C_GENRE_TRANSACTION
      from ACJ_CATALOGUE_DOCUMENT CAT
         , ACS_ACCOUNT ACC
         , ACS_FINANCIAL_YEAR YEA
         , ACS_FINANCIAL_YEAR YEA1
         , ACS_TAX_CODE TAX
         , ACS_VAT_DET_ACCOUNT VAT
         , ACT_DOCUMENT DOC
         , ACT_VAT_DET_ACCOUNT VAT1
         , V_ACT_DET_TAX_DATE V_TAX
         , V_ACT_FIN_IMPUTATION_DATE IMP
     where IMP.ACT_FINANCIAL_IMPUTATION_ID = V_TAX.ACT_FINANCIAL_IMPUTATION_ID
       and TAX.ACS_TAX_CODE_ID = V_TAX.ACS_TAX_CODE_ID
       and ACC.ACS_ACCOUNT_ID = TAX.ACS_TAX_CODE_ID
       and VAT.ACS_VAT_DET_ACCOUNT_ID = TAX.ACS_VAT_DET_ACCOUNT_ID
       and DOC.ACT_DOCUMENT_ID = V_TAX.ACT_DOCUMENT_ID
       and CAT.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID
       and YEA.ACS_FINANCIAL_YEAR_ID = DOC.ACS_FINANCIAL_YEAR_ID
       and VAT1.ACT_VAT_DET_ACCOUNT_ID(+) = V_TAX.ACT_VAT_DET_ACCOUNT_ID
       and YEA1.ACS_FINANCIAL_YEAR_ID(+) = VAT1.ACS_FINANCIAL_YEAR_ID
       and ACC.ACC_NUMBER >= parameter_6
       and ACC.ACC_NUMBER <= parameter_7
       and (    (    parameter_10 = '1'
                 and V_TAX.C_TYPE_CUMUL = 'INT')
            or (    parameter_11 = '1'
                and V_TAX.C_TYPE_CUMUL = 'EXT')
            or (    parameter_12 = '1'
                and V_TAX.C_TYPE_CUMUL = 'PRE')
            or (    parameter_13 = '1'
                and V_TAX.C_TYPE_CUMUL = 'ENG')
           )
       and V_TAX.TAX_TMP_VAT_ENCASHMENT = 0
       and VAT.ACS_VAT_DET_ACCOUNT_ID = to_number(parameter_17);
end RPT_ACR_VAT_FORM_OFF;
