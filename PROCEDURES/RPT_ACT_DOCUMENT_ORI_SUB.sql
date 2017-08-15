--------------------------------------------------------
--  DDL for Procedure RPT_ACT_DOCUMENT_ORI_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_DOCUMENT_ORI_SUB" (
arefcursor in out CRYSTAL_CURSOR_TYPES.dualcursortyp
, procuser_lanid in     PCS.PC_LANG.LANID%type
, parameter_0 in varchar2
)
/**
*Description

 Used for subreport ACT_DOCUMENT_ORI_SUB, subreport OF ACR_VAT_FORM_DET
*@created JLIU 06.JUNE.2009
*@lastUpdate VHA 09.04.2013
*@public
*/
is
  vpc_lang_id pcs.pc_lang.pc_lang_id%type;   --user language id
begin
  pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  vpc_lang_id  := pcs.PC_I_LIB_SESSION.getuserlangid;

  open aRefCursor for
    select ACC.ACC_NUMBER
         , DOC.DOC_NUMBER
         , IMP.ACT_FINANCIAL_IMPUTATION_ID
         , IMP.IMF_DESCRIPTION
         , IMP.IMF_TRANSACTION_DATE
         , JOU.JOU_NUMBER
         , PAR.DOC_DATE_DELIVERY
      from ACS_ACCOUNT ACC
         , ACT_DOCUMENT DOC
         , ACT_FINANCIAL_IMPUTATION IMP
         , ACT_JOURNAL JOU
         , ACT_PART_IMPUTATION PAR
     where IMP.ACT_DOCUMENT_ID = DOC.ACT_DOCUMENT_ID
       and DOC.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID
       and IMP.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
       and IMP.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
       and IMP.ACT_FINANCIAL_IMPUTATION_ID = to_number(parameter_0);
end RPT_ACT_DOCUMENT_ORI_SUB;
