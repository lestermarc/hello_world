--------------------------------------------------------
--  DDL for Procedure RPT_ACT_ARRANGEMENT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_ARRANGEMENT" (
  aRefCursor             in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, Proccompany_owner      in     pcs.pc_scrip.scrdbowner%TYPE
, PARAMETER_0            in     varchar2
, PROCUSER_LANID         in     pcs.pc_lang.lanid%type
)
is
/**
* description used for report ACT_ARRANGEMENT

* @author JLI  16 Sept 2009
* Modified VHA 26 JUNE 2013
* public
* @param PARAMETER_0   ACT_DOCUMENT_ID
*/


VPC_LANG_ID pcs.pc_lang.pc_lang_id%type := null;
v_com_logo_large pcs.pc_comp.com_logo_large%type := null;

BEGIN
if procuser_lanid is not null then
    pcs.PC_I_LIB_SESSION.setLanId (procuser_lanid);
    VPC_LANG_ID:= pcs.PC_I_LIB_SESSION.GetUserLangId;
end if;

if proccompany_owner is not null then
    SELECT com.com_logo_large
      INTO v_com_logo_large
      FROM pcs.pc_comp com, pcs.pc_scrip scr
      WHERE scr.pc_scrip_id = com.pc_scrip_id
      AND scr.scrdbowner = proccompany_owner;
end if;

open aRefCursor for
SELECT  v_com_logo_large com_logo_large,
        ATD.ACT_DOCUMENT_ID,
        ATD.DOC_NUMBER,
        ATD.DOC_TOTAL_AMOUNT_DC,
        ATD.DOC_DOCUMENT_DATE,
        EXY.ACT_EXPIRY_ID,
        EXY.EXP_ADAPTED,
        EXY.EXP_AMOUNT_LC,
        EXY.EXP_SLICE,
        PLT.DPO_DESCR,
        ADR.ADD_ADDRESS1,
        ADR.PC_LANG_ID,
        ADR.ADD_FORMAT,
        ADR.ADD_PRINCIPAL,
        PER.PER_NAME,
        PER.PER_FORENAME,
        PER.PER_ACTIVITY,
        CUR.CURRENCY,
        PER.DIC_PERSON_POLITNESS_ID,
        ADR.ADD_ZIPCODE,
        ADR.ADD_CITY
FROM    ACS_FIN_ACC_S_PAYMENT SPA,
        ACS_FINANCIAL_CURRENCY FUR,
        ACS_PAYMENT_METHOD MET,
        ACT_DOCUMENT ATD,
        ACT_EXPIRY EXY,
        ACT_PART_IMPUTATION PAR,
        DIC_PERSON_POLITNESS PLT,
        PAC_ADDRESS ADR,
        PAC_CUSTOM_PARTNER CUS,
        PAC_PERSON PER,
        PCS.PC_CURR CUR
WHERE   (PARAMETER_0 IS NULL OR ATD.ACT_DOCUMENT_ID = PARAMETER_0)
  AND   ATD.ACT_DOCUMENT_ID = EXY.ACT_DOCUMENT_ID
  AND   EXY.ACT_PART_IMPUTATION_ID = PAR.ACT_PART_IMPUTATION_ID
  AND   PAR.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
  AND   CUS.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
  AND   PER.PAC_PERSON_ID = ADR.PAC_PERSON_ID(+)
  AND   PER.DIC_PERSON_POLITNESS_ID = PLT.DIC_PERSON_POLITNESS_ID(+)
  AND   PAR.ACS_FINANCIAL_CURRENCY_ID = FUR.ACS_FINANCIAL_CURRENCY_ID
  AND   FUR.PC_CURR_ID = CUR.PC_CURR_ID
  AND   EXY.ACS_FIN_ACC_S_PAYMENT_ID = SPA.ACS_FIN_ACC_S_PAYMENT_ID
  AND   SPA.ACS_PAYMENT_METHOD_ID = MET.ACS_PAYMENT_METHOD_ID
  AND   ADR.ADD_PRINCIPAL = 1;
END RPT_ACT_ARRANGEMENT;
