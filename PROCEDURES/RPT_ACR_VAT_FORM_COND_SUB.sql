--------------------------------------------------------
--  DDL for Procedure RPT_ACR_VAT_FORM_COND_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_VAT_FORM_COND_SUB" (
  arefcursor     in out CRYSTAL_CURSOR_TYPES.dualcursortyp
, procuser_lanid in     PCS.PC_LANG.LANID%type
, parameter_0    in     varchar2
, parameter_6    in     varchar2
, parameter_7    in     varchar2
, parameter_10   in     varchar2
, parameter_11   in     varchar2
, parameter_12   in     varchar2
, parameter_13   in     varchar2
)
/**
*Description

 Used for subreport ACR_VAT_FORM_COND, subreport OF ACR_VAT_FORM_DET
*@created JLIU 03.JUNE.2009
*@lastUpdate VHA 09.04.2013
*@public
*@param parameter_0   ACS_VAT_DET_ACCOUNT_ID
*@param parameter_6   ACC_NUMBER(from)
*@param parameter_7   ACC_NUMBER(to)
*@param parameter_10  C_TYPE_CUMUL
*@param parameter_11  C_TYPE_CUMUL
*@param parameter_12  C_TYPE_CUMUL
*@param parameter_13  C_TYPE_CUMUL
*/
is
  vpc_lang_id pcs.pc_lang.pc_lang_id%type;   --user language id
begin
  pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  vpc_lang_id  := pcs.PC_I_LIB_SESSION.getuserlangid;

  open arefcursor for
    select ACC.ACC_NUMBER
         , ACC.ACC_INTEREST
         , FIN.ACC_NUMBER ACC_NUMBER_FIN
         , FIN_1.ACC_NUMBER ACC_NUMBER_FIN_1
         , FUR_LC.FIN_LOCAL_CURRENCY FIN_LOCAL_CURRENCY_LC
         , FUR.FIN_LOCAL_CURRENCY
         , DET.ACS_VAT_DET_ACCOUNT_ID
         , CUR.PC_CURR_ID
         , CUR.CURRENCY
         , CUR_LC.PC_CURR_ID PC_CURR_ID_LC
         , VDT.TAX_INCLUDED_EXCLUDED
         , VDT.TAX_RATE
         , VDT.TAX_VAT_AMOUNT_FC
         , VDT.TAX_VAT_AMOUNT_LC
         , VDT.HT_LC
         , VDT.TTC_LC
         , VDT.HT_FC
         , VDT.TTC_FC
         , VDT.IMF_TRANSACTION_DATE
         , VDT.C_TYPE_CUMUL
         , VDT.TAX_TMP_VAT_ENCASHMENT
         , VIM.IMF_TRANSACTION_DATE
         , VIM.C_GENRE_TRANSACTION
      from ACS_ACCOUNT ACC
         , ACS_ACCOUNT FIN
         , ACS_ACCOUNT FIN_1
         , ACS_FINANCIAL_CURRENCY FUR_LC
         , ACS_FINANCIAL_CURRENCY FUR
         , ACS_TAX_CODE TCO
         , ACS_VAT_DET_ACCOUNT DET
         , PCS.PC_CURR CUR
         , PCS.PC_CURR CUR_LC
         , V_ACT_DET_TAX_DATE VDT
         , V_ACT_FIN_IMPUTATION_DATE VIM
     where DET.ACS_VAT_DET_ACCOUNT_ID = to_number(PARAMETER_0)
       and VDT.ACT_FINANCIAL_IMPUTATION_ID = VIM.ACT_FINANCIAL_IMPUTATION_ID
       and VIM.ACS_FINANCIAL_ACCOUNT_ID = FIN_1.ACS_ACCOUNT_ID
       and VIM.ACS_FINANCIAL_CURRENCY_ID = FUR.ACS_FINANCIAL_CURRENCY_ID
       and FUR.PC_CURR_ID = CUR.PC_CURR_ID
       and VIM.ACS_ACS_FINANCIAL_CURRENCY_ID = FUR_LC.ACS_FINANCIAL_CURRENCY_ID
       and FUR_LC.PC_CURR_ID = CUR_LC.PC_CURR_ID
       and VDT.ACS_TAX_CODE_ID = TCO.ACS_TAX_CODE_ID
       and TCO.ACS_TAX_CODE_ID = ACC.ACS_ACCOUNT_ID
       and TCO.ACS_VAT_DET_ACCOUNT_ID = DET.ACS_VAT_DET_ACCOUNT_ID
       and VDT.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_ACCOUNT_ID(+)
       and acc.acc_number >= parameter_6
       and acc.acc_number <= parameter_7
       and (    (    parameter_10 = '1'
                 and VDT.C_TYPE_CUMUL = 'INT')
            or (    parameter_11 = '1'
                and VDT.C_TYPE_CUMUL = 'EXT')
            or (    parameter_12 = '1'
                and VDT.C_TYPE_CUMUL = 'PRE')
            or (    parameter_13 = '1'
                and VDT.C_TYPE_CUMUL = 'ENG')
           )
       and VDT.TAX_TMP_VAT_ENCASHMENT = 0;
end RPT_ACR_VAT_FORM_COND_SUB;
