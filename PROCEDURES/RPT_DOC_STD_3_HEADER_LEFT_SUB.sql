--------------------------------------------------------
--  DDL for Procedure RPT_DOC_STD_3_HEADER_LEFT_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_STD_3_HEADER_LEFT_SUB" (
  arefcursor in out CRYSTAL_CURSOR_TYPES.dualcursortyp
, parameter_0 in DOC_DOCUMENT.DMT_NUMBER%type
)
is
/**
*Description - Used for report DOC_STD_3

*@created MZHU 1 FEB 2010
*@lastUpdate VHA 14.05.2014
*@public
*@param parameter_0:  DMT_NUMBER
*/
begin
  open arefcursor for
    select DMT.DMT_NUMBER
         , DMT.DMT_DATE_DOCUMENT
         , DMT.DMT_REFERENCE
         , REP.REP_DESCR
         , REC.RCO_TITLE
         , ACS_FUNCTION.GetPayMethDescr(APM.ACS_PAYMENT_METHOD_ID, DMT.PC_LANG_ID) PAY_METH_DESCR
         , PCS.PC_FUNCTIONS.GETAPPLTXTDESCR(PMT.PC_APPLTXT_ID, DMT.PC_LANG_ID) COND_DESCR
         , CUR.CURRENCY
         , PER.PER_KEY1
         , PER.PER_KEY2
         , GST.C_GAUGE_TITLE
         , GAU.C_ADMIN_DOMAIN
         , DPD.PAD_PAYMENT_DATE
         , DPD.PAD_NET_DATE_AMOUNT
         , DPD.PAD_BAND_NUMBER
         , DMT.DOC_DOCUMENT_ID
         , FOO.DOC_FOOT_ID
         , REC.DOC_RECORD_ID
         , PER.PAC_PERSON_ID
         , ADR.PAC_ADDRESS_ID
         , REP.PAC_REPRESENTATIVE_ID
         , PMT.PAC_PAYMENT_CONDITION_ID
         , GAU.DOC_GAUGE_ID
         , DPD.DOC_PAYMENT_DATE_ID
         , APM.ACS_PAYMENT_METHOD_ID
         , AFC.ACS_FINANCIAL_CURRENCY_ID
         , CUR.PC_CURR_ID
         , LANG.PC_LANG_ID
      from PCS.PC_LANG LANG
         , ACS_FIN_ACC_S_PAYMENT AFA
         , ACS_PAYMENT_METHOD APM
         , DOC_RECORD REC
         , DOC_PAYMENT_DATE DPD
         , DOC_FOOT FOO
         , PAC_PAYMENT_CONDITION PMT
         , ACS_FINANCIAL_CURRENCY AFC
         , PAC_ADDRESS ADR
         , PAC_REPRESENTATIVE REP
         , PAC_PERSON PER
         , PCS.PC_CURR CUR
         , DOC_GAUGE GAU
         , DOC_GAUGE_STRUCTURED GST
         , DOC_DOCUMENT DMT
     where DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
       and GAU.DOC_GAUGE_ID = GST.DOC_GAUGE_ID
       and DMT.PC_LANG_ID = LANG.PC_LANG_ID
       and DPD.DOC_FOOT_ID(+) = FOO.DOC_FOOT_ID
       and AFA.ACS_FIN_ACC_S_PAYMENT_ID(+) = DMT.ACS_FIN_ACC_S_PAYMENT_ID
       and APM.ACS_PAYMENT_METHOD_ID(+) = AFA.ACS_PAYMENT_METHOD_ID
       and REP.PAC_REPRESENTATIVE_ID(+) = DMT.PAC_REPRESENTATIVE_ID
       and FOO.DOC_DOCUMENT_ID(+) = DMT.DOC_DOCUMENT_ID
       and REC.DOC_RECORD_ID(+) = DMT.DOC_RECORD_ID
       and ADR.PAC_ADDRESS_ID(+) = DMT.PAC_ADDRESS_ID
       and PER.PAC_PERSON_ID(+) = ADR.PAC_PERSON_ID
       and AFC.ACS_FINANCIAL_CURRENCY_ID(+) = DMT.ACS_FINANCIAL_CURRENCY_ID
       and CUR.PC_CURR_ID(+) = AFC.PC_CURR_ID
       and PMT.PAC_PAYMENT_CONDITION_ID(+) = DMT.PAC_PAYMENT_CONDITION_ID
       and DMT.DMT_NUMBER = parameter_0;
end RPT_DOC_STD_3_HEADER_LEFT_SUB;
