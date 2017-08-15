--------------------------------------------------------
--  DDL for Procedure RPT_DOC_STD_3_HEADER_RIGHT_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_STD_3_HEADER_RIGHT_SUB" (
  arefcursor  in out CRYSTAL_CURSOR_TYPES.dualcursortyp
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
         , DMT.DMT_DATE_FALLING_DUE
         , DMT.DMT_PARTNER_NUMBER
         , DMT.DMT_PARTNER_REFERENCE
         , DMT.DMT_DATE_PARTNER_DOCUMENT
         , DMT.C_INCOTERMS
         , THI.THI_NO_INTRA
         , THI.THI_NO_TVA
         , PAC_FUNCTIONS.GetSendCondDescr(PSC.PAC_SENDING_CONDITION_ID, DMT.PC_LANG_ID) SEN_DESCR
         , PER_SEN.PER_NAME SEN_PER_NAME
         , PER_SEN.PER_FORENAME SEN_PER_FORENAME
         , PER_SEN.PER_ACTIVITY SEN_PER_ACTIVITY
         , PER_SEN.PER_KEY1
         , PER_SEN.PER_KEY2
         , ADR_SEN.ADD_ADDRESS1 SEN_ADD_ADDRESS1
         , ADR_SEN.ADD_FORMAT SEN_ADD_FORMAT
         , GST.C_GAUGE_TITLE
         , DPD.PAD_PAYMENT_DATE
         , DPD.PAD_BAND_NUMBER
         , DPD.PAD_DISCOUNT_AMOUNT
         , DMT.DOC_DOCUMENT_ID
         , THI.PAC_THIRD_ID
         , FOO.DOC_FOOT_ID
         , PSC.PAC_SENDING_CONDITION_ID
         , DPD.DOC_PAYMENT_DATE_ID
         , PER_SEN.PAC_PERSON_ID
         , ADR_SEN.PAC_ADDRESS_ID
         , GAU.DOC_GAUGE_ID
         , LANG.PC_LANG_ID
      from PCS.PC_LANG LANG
         , DOC_PAYMENT_DATE DPD
         , DOC_FOOT FOO
         , PAC_SENDING_CONDITION PSC
         , PAC_ADDRESS ADR_SEN
         , PAC_PERSON PER_SEN
         , PAC_THIRD THI
         , DOC_GAUGE GAU
         , DOC_GAUGE_STRUCTURED GST
         , DOC_DOCUMENT DMT
     where DMT.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID
       and GAU.DOC_GAUGE_ID = GST.DOC_GAUGE_ID
       and DMT.PC_LANG_ID = LANG.PC_LANG_ID
       and DPD.DOC_FOOT_ID(+) = FOO.DOC_FOOT_ID
       and FOO.DOC_DOCUMENT_ID(+) = DMT.DOC_DOCUMENT_ID
       and PSC.PAC_SENDING_CONDITION_ID(+) = DMT.PAC_SENDING_CONDITION_ID
       and ADR_SEN.PAC_ADDRESS_ID(+) = PSC.PAC_ADDRESS_ID
       and PER_SEN.PAC_PERSON_ID(+) = ADR_SEN.PAC_PERSON_ID
       and THI.PAC_THIRD_ID(+) = DMT.PAC_THIRD_ID
       and DMT.DMT_NUMBER = parameter_0;
end RPT_DOC_STD_3_HEADER_RIGHT_SUB;
