--------------------------------------------------------
--  DDL for Procedure RPT_DOC_STD_3_VAT_RECAP_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_STD_3_VAT_RECAP_SUB" (
  arefcursor     in out CRYSTAL_CURSOR_TYPES.dualcursortyp
, parameter_3    in     number
, procuser_lanid in     PCS.PC_LANG.LANID%type
)
is
/**
*Description - Used for report DOC_STD_3

*@created MZHU 17 MAY 2009
*@lastUpdate VHA 14.05.2014
*@public
*@param PARAMETER_3:  DOC_FOOT_ID
*/
  vpc_lang_id PCS.PC_LANG.PC_LANG_ID%type;
begin
  PCS.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  vpc_lang_id  := PCS.PC_I_LIB_SESSION.getuserlangid;

  open arefcursor for
    select ACC.ACC_NUMBER
         , DES.DES_DESCRIPTION_SUMMARY
         , DMT.DMT_DATE_DELIVERY
         , VDA.VDA_LIABLE_AMOUNT
         , VDA.VDA_NET_AMOUNT_EXCL
         , VDA.VDA_VAT_RATE
         , VDA.VDA_VAT_TOTAL_AMOUNT
         , ACS_FUNCTION.getvatrate(COD.ACS_TAX_CODE_ID, to_char(DMT.DMT_DATE_DOCUMENT, 'YYYYMMDD') ) RATE_1
         , ACS_FUNCTION.getvatrate(COD.ACS_TAX_CODE_ID, to_char(DMT.DMT_DATE_DELIVERY, 'YYYYMMDD') ) RATE_2
      from ACS_ACCOUNT ACC
         , ACS_DESCRIPTION DES
         , ACS_TAX_CODE COD
         , DOC_DOCUMENT DMT
         , DOC_VAT_DET_ACCOUNT VDA
     where DMT.DOC_DOCUMENT_ID(+) = VDA.DOC_FOOT_ID
       and VDA.ACS_TAX_CODE_ID = COD.ACS_TAX_CODE_ID
       and COD.ACS_TAX_CODE_ID = ACC.ACS_ACCOUNT_ID
       and ACC.ACS_ACCOUNT_ID = DES.ACS_ACCOUNT_ID
       and DES.PC_LANG_ID = vpc_lang_id
       and VDA.DOC_FOOT_ID = parameter_3;
end RPT_DOC_STD_3_VAT_RECAP_SUB;
