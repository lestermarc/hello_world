--------------------------------------------------------
--  DDL for Procedure RPT_ACR_VAT_FORM_DET
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_VAT_FORM_DET" (
  arefcursor     in out CRYSTAL_CURSOR_TYPES.dualcursortyp
, procuser_lanid in     PCS.PC_LANG.LANID%type
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
, parameter_15   in     varchar2
, parameter_16   in     varchar2
)
/**
*Description

 Used for report ACR_VAT_FORM_DET
*@created JLIU 04.JUNE.2009
*@lastUpdate  VHA 09.04.2013
*@public
*@PARAM parameter_0   Year(from)
*@PARAM parameter_1   Month(from)
*@PARAM parameter_2   Day(from)
*@PARAM parameter_3   Year(to)
*@PARAM parameter_4   Month(to)
*@PARAM parameter_5   Day(to)
*@PARAM parameter_6   ACC_NUMBER(from)
*@PARAM parameter_7   ACC_NUMBER(to)
*@PARAM parameter_10  C_TYPE_CUMUL
*@PARAM parameter_11  C_TYPE_CUMUL
*@PARAM parameter_12  C_TYPE_CUMUL
*@PARAM parameter_13  C_TYPE_CUMUL
*@PARAM parameter_15  ACT_VAT_DET_ACCOUNT_ID
*@PARAM parameter_16  ACS_VAT_DET_ACCOUNT_ID
*/
is
  vpc_lang_id pcs.pc_lang.pc_lang_id%type;   --user language id
begin
  if parameter_0 is not null then
    act_functions.date_from  := to_date(parameter_0 || lpad(parameter_1, 2, '0') || lpad(parameter_2, 2, '0'), 'YYYYMMDD');
  end if;

  if parameter_3 is not null then
    act_functions.date_to  := to_date(parameter_3 || lpad(parameter_4, 2, '0') || lpad(parameter_5, 2, '0'), 'YYYYMMDD');
  end if;

  if     (parameter_15 is not null)
     and (length(trim(parameter_15) ) > 0)
     and (parameter_15 <> '0') then
    ACT_FUNCTIONS.VAT_DET_ACC_ID  := parameter_15;
  end if;

  pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  vpc_lang_id  := pcs.PC_I_LIB_SESSION.getuserlangid;

  open arefcursor for
         select 'VAT' INFO
                 , ACC.ACC_NUMBER
                 , ACS_FUNCTION.GetDescription('ACS_VAT_DET_ACCOUNT_ID', DET.ACS_VAT_DET_ACCOUNT_ID) DES_DESCRIPTION_SUMMARY
                 , FUR.FIN_LOCAL_CURRENCY
                 , FUR.FIN_LOCAL_CURRENCY FIN_LOCAL_CURRENCY_LC
                 , YEA.FYE_NO_EXERCICE
                 , DET.ACS_VAT_DET_ACCOUNT_ID
                 , ATD.ACT_DOCUMENT_ID
                 , ATD.DOC_NUMBER
                 , TAX.ACT_VAT_DET_ACCOUNT_ID
                 , (select VTD_NUMBER
                      from ACT_VAT_DET_ACCOUNT DET
                     where TAX.ACT_VAT_DET_ACCOUNT_ID = DET.ACT_VAT_DET_ACCOUNT_ID) VTD_NUMBER
                 , CUR.CURRENCY
                 , CUR_LC.CURRENCY CURRENCY_LC
                 , TCO.ACC_NUMBER ACC_NUMBER_TCO
                 , TCO.DES_DESCRIPTION_SUMMARY DES_DESCRIPTION_SUMMARY_TCO
                 , TAX.TAX_INCLUDED_EXCLUDED
                 , TAX.TAX_RATE
                 , TAX.TAX_VAT_AMOUNT_FC
                 , TAX.TAX_VAT_AMOUNT_LC
                 , TAX.HT_LC
                 , TAX.TTC_LC
                 , TAX.HT_FC
                 , TAX.TTC_FC
                 , TAX.IMF_TRANSACTION_DATE IMF_TRANSACTION_DATE_TAX
                 , TAX.IMF_VALUE_DATE
                 , TAX.ACT_FIN_IMPUT_ORIGIN_ID
                 , FIM.IMF_DESCRIPTION
                 , FIM.IMF_EXCHANGE_RATE
                 , FIM.IMF_TRANSACTION_DATE IMF_TRANSACTION_DATE_FIN
                 , FIM.C_GENRE_TRANSACTION
                 , FIM.DOC_DATE_DELIVERY
                 , FIM.PAC_PERSON_ID
                 , JOU.JOU_NUMBER
              from ACS_ACCOUNT ACC
                 , ACS_FINANCIAL_CURRENCY FUR
                 , ACS_FINANCIAL_CURRENCY FUR_LC
                 , ACS_FINANCIAL_YEAR YEA
                 , ACS_VAT_DET_ACCOUNT DET
                 , ACT_DOCUMENT ATD
                 , PCS.PC_CURR CUR
                 , PCS.PC_CURR CUR_LC
                 , V_ACS_TAX_CODE TCO
                 , V_ACT_DET_TAX_DATE TAX
                 , V_ACT_FIN_IMPUTATION_DATE FIM
                 , V_ACT_JOURNAL JOU
             where TAX.ACT_FINANCIAL_IMPUTATION_ID = FIM.ACT_FINANCIAL_IMPUTATION_ID
               and FIM.ACT_DOCUMENT_ID = ATD.ACT_DOCUMENT_ID
               and ATD.ACT_JOB_ID = JOU.ACT_JOB_ID
               and JOU.ACS_FINANCIAL_YEAR_ID = YEA.ACS_FINANCIAL_YEAR_ID
               and FIM.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
               and FIM.ACS_FINANCIAL_CURRENCY_ID = FUR.ACS_FINANCIAL_CURRENCY_ID
               and FUR.PC_CURR_ID = CUR.PC_CURR_ID
               and FIM.ACS_ACS_FINANCIAL_CURRENCY_ID = FUR_LC.ACS_FINANCIAL_CURRENCY_ID
               and FUR_LC.PC_CURR_ID = CUR_LC.PC_CURR_ID
               and TAX.ACS_TAX_CODE_ID = TCO.ACS_TAX_CODE_ID
               and TCO.ACS_VAT_DET_ACCOUNT_ID = DET.ACS_VAT_DET_ACCOUNT_ID
               and TCO.PC_LANG_ID = vpc_lang_id
               and JOU.C_SUB_SET = 'ACC'
               and TCO.ACC_NUMBER >= nvl(parameter_6, '(')
               and TCO.ACC_NUMBER <= nvl(parameter_7, '}')
               and (    (    parameter_10 = '1'
                         and TAX.C_TYPE_CUMUL = 'INT')
                    or (    parameter_11 = '1'
                        and TAX.C_TYPE_CUMUL = 'EXT')
                    or (    parameter_12 = '1'
                        and TAX.C_TYPE_CUMUL = 'PRE')
                    or (    parameter_13 = '1'
                        and TAX.C_TYPE_CUMUL = 'ENG')
                   )
               and TAX.TAX_TMP_VAT_ENCASHMENT = 0
               and DET.ACS_VAT_DET_ACCOUNT_ID = to_number(parameter_16);
end RPT_ACR_VAT_FORM_DET;
