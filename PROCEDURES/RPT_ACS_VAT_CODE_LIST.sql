--------------------------------------------------------
--  DDL for Procedure RPT_ACS_VAT_CODE_LIST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACS_VAT_CODE_LIST" (
  aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, PARAMETER_0 in     varchar2
, PARAMETER_1 in     varchar2
, PROCUSER_LANID in  pcs.pc_lang.lanid%type
)

is
/**
* Store procedure used for the report ACS_VAT_CODE_LIST (Fiche des codes TVA)
*
* @author VBO
* @lastUpdate
* @version 2003
* @public
* @param PARAMETER_0   Compte du   (ACC_NUMBER)
* @param PARAMETER_1   Compte au   (ACC_NUMBER)
*/

VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;

begin

pcs.PC_I_LIB_SESSION.setLanId (procuser_lanid);
VPC_LANG_ID:= pcs.PC_I_LIB_SESSION.GetUserLangId;

open aRefCursor for
SELECT
  TAX.ACS_TAX_CODE_ID,
  TAX.DIC_TYPE_SUBMISSION_ID,
  TAX.DIC_TYPE_MOVEMENT_ID,
  TAX.TAX_RATE,
  TAX.TAX_LIABLED_RATE,
  TAX.DIC_TYPE_VAT_GOOD_ID,
  TAX.ACC_NUMBER,
  TAX.DES_DESCRIPTION_SUMMARY,
  TAX.DES_DESCRIPTION_LARGE,
  ACC_PREA.ACC_NUMBER ACC_NUMBER_PREA,
  ACC_PROV.ACC_NUMBER ACC_NUMBER_PROV
FROM
  ACS_ACCOUNT ACC_PREA,
  ACS_ACCOUNT ACC_PROV,
  V_ACS_TAX_CODE TAX
WHERE
  TAX.ACC_NUMBER >= PARAMETER_0 AND
  TAX.ACC_NUMBER <= PARAMETER_1 AND
  TAX.ACS_PREA_ACCOUNT_ID = ACC_PREA.ACS_ACCOUNT_ID(+) AND
  TAX.ACS_PROV_ACCOUNT_ID = ACC_PROV.ACS_ACCOUNT_ID(+) AND
  TAX.PC_LANG_ID = VPC_LANG_ID;

end RPT_ACS_VAT_CODE_LIST;
