--------------------------------------------------------
--  DDL for Procedure RPT_ACS_VAT_CODE_FORM
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACS_VAT_CODE_FORM" (
  aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, PROCPARAM_0 in     varchar2
, PROCPARAM_1 in     varchar2
, PROCPARAM_2 in     varchar2
, PROCUSER_LANID in  pcs.pc_lang.lanid%type
)

is
/**
* Proc�dure stock�e utilis�e pour le rapport ACS_VAT_CODE_FORM(Fiche des codes TVA)
*
* @author VBO
* @lastUpdate f�vrier 2011
* @version 2003
* @public
* @param PROCPARAM_0    Compte du   (ACC_NUMBER)
* @param PROCPARAM_1    Compte au   (ACC_NUMBER)
* @param PROCPARAM_2    D�compte TVA (ACS_VAT_DET_ACCOUNT_ID)
*/

VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;

begin

pcs.PC_I_LIB_SESSION.setLanId (procuser_lanid);
VPC_LANG_ID:= pcs.PC_I_LIB_SESSION.GetUserLangId;

open aRefCursor for
SELECT
  TAX.ACS_TAX_CODE_ID,
  ACC.ACC_NUMBER,
  TAX.TAX_RATE,
  TAX.TAX_LIABLED_RATE,
  TAX.C_ROUND_TYPE,
  TAX.TAX_ROUNDED_AMOUNT,
  TAX.ACS_VAT_DET_ACCOUNT_ID,
  (SELECT DE6.DES_DESCRIPTION_SUMMARY
   FROM ACS_DESCRIPTION DE6
   WHERE TAX.ACS_VAT_DET_ACCOUNT_ID = DE6.ACS_VAT_DET_ACCOUNT_ID AND
             DE6.PC_LANG_ID = VPC_LANG_ID) DEC_TVA_DES,
  TAX.C_TYPE_TAX,
  TAX.TAX_DEDUCTIBLE_RATE,
  TAX.ACS_NONDED_ACCOUNT_ID,
  (SELECT AC3.ACC_NUMBER
   FROM ACS_ACCOUNT AC3
   WHERE TAX.ACS_NONDED_ACCOUNT_ID = AC3.ACS_ACCOUNT_ID) CPT_TVA_NO_DED,
  (SELECT DE5.DES_DESCRIPTION_SUMMARY
   FROM ACS_DESCRIPTION DE5
   WHERE TAX.ACS_NONDED_ACCOUNT_ID = DE5.ACS_ACCOUNT_ID AND
            DE5.PC_LANG_ID = VPC_LANG_ID) CPT_TVA_NO_DED_DES,
  TAX.C_ESTABLISHING_CALC_SHEET,
  TAX.ACS_PREA_ACCOUNT_ID,
  (SELECT AC1.ACC_NUMBER
   FROM ACS_ACCOUNT AC1
   WHERE TAX.ACS_PREA_ACCOUNT_ID = AC1.ACS_ACCOUNT_ID) CPT_TAXE,
  (SELECT DE1.DES_DESCRIPTION_SUMMARY
   FROM ACS_DESCRIPTION DE1
   WHERE TAX.ACS_PREA_ACCOUNT_ID = DE1.ACS_ACCOUNT_ID AND
            DE1.PC_LANG_ID = VPC_LANG_ID) CPT_TAXE_DES,
  TAX.ACS_PROV_ACCOUNT_ID,
  (SELECT AC2.ACC_NUMBER
   FROM ACS_ACCOUNT AC2
   WHERE TAX.ACS_PROV_ACCOUNT_ID = AC2.ACS_ACCOUNT_ID) CPT_PROV,
  (SELECT DE2.DES_DESCRIPTION_SUMMARY
   FROM ACS_DESCRIPTION DE2
   WHERE TAX.ACS_PROV_ACCOUNT_ID = DE2.ACS_ACCOUNT_ID AND
         DE2.PC_LANG_ID = VPC_LANG_ID) CPT_PROV_DES,
  TAX.DIC_NO_POS_CALC_SHEET_ID,
  TAX.DIC_NO_POS_CALC_SHEET2_ID,
  TAX.DIC_NO_POS_CALC_SHEET3_ID,
  TAX.DIC_NO_POS_CALC_SHEET4_ID,
  TAX.DIC_NO_POS_CALC_SHEET5_ID,
  TAX.DIC_NO_POS_CALC_SHEET6_ID,
  TAX.DIC_TYPE_MOVEMENT_ID,
  TAX.DIC_TYPE_SUBMISSION_ID,
  TAX.DIC_TYPE_VAT_GOOD_ID,
  TAX.ACS_TAX_CODE1_ID,
  (SELECT AC4.ACC_NUMBER
   FROM ACS_ACCOUNT AC4
   WHERE TAX.ACS_TAX_CODE1_ID = AC4.ACS_ACCOUNT_ID) CPT_TAX_CODE1,
  (SELECT DE3.DES_DESCRIPTION_SUMMARY
   FROM ACS_DESCRIPTION DE3
   WHERE TAX.ACS_TAX_CODE1_ID = DE3.ACS_ACCOUNT_ID AND
         DE3.PC_LANG_ID = VPC_LANG_ID) CPT_TAX_CODE1_DES,
  TAX.ACS_TAX_CODE2_ID,
  (SELECT AC5.ACC_NUMBER
   FROM ACS_ACCOUNT AC5
   WHERE TAX.ACS_TAX_CODE2_ID = AC5.ACS_ACCOUNT_ID) CPT_TAX_CODE2,
  (SELECT DE4.DES_DESCRIPTION_SUMMARY
   FROM ACS_DESCRIPTION DE4
   WHERE TAX.ACS_TAX_CODE2_ID = DE4.ACS_ACCOUNT_ID AND
         DE4.PC_LANG_ID = VPC_LANG_ID) CPT_TAX_CODE2_DES,
  ACC.C_VALID,
  ACC.ACC_INTEREST,
  DES.DES_DESCRIPTION_SUMMARY,
  DES.DES_DESCRIPTION_LARGE,
  VAT.VAT_SINCE,
  VAT.VAT_TO,
  VAT.VAT_RATE
FROM
  ACS_VAT_RATE VAT,
  ACS_DESCRIPTION DES,
  ACS_ACCOUNT ACC,
  ACS_TAX_CODE TAX
WHERE
  ACC.ACC_NUMBER >= PROCPARAM_0 AND
  ACC.ACC_NUMBER <= PROCPARAM_1 AND
  (TAX.ACS_VAT_DET_ACCOUNT_ID = PROCPARAM_2 OR PROCPARAM_2 is null) AND
  TAX.ACS_TAX_CODE_ID = ACC.ACS_ACCOUNT_ID AND
  TAX.ACS_TAX_CODE_ID = VAT.ACS_TAX_CODE_ID(+) AND
  ACC.ACS_ACCOUNT_ID = DES.ACS_ACCOUNT_ID AND
  DES.PC_LANG_ID = VPC_LANG_ID;

end RPT_ACS_VAT_CODE_FORM;