--------------------------------------------------------
--  DDL for Procedure RPT_ASA_INSTALLATION_FORM
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ASA_INSTALLATION_FORM" (
  aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, PROCPARAM_0   in  varchar2
, PROCUSER_LANID in  pcs.pc_lang.lanid%type
)

is
/**
 Proc�dure stock�e utilis�e pour le rapport ASA_INSTALLATION_FORM (Fiche d'installation)
* replace the procedure ASA_INSTALLATION_FORM_RPT
 @author JSC
 @lastUpdate
 @version 2003
 @public
 @param PROCPARAM_0    Num�ro d'insallation RCO_TITLE
*/

VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;

begin
pcs.PC_I_LIB_SESSION.setLanId (procuser_lanid);
VPC_LANG_ID:= pcs.PC_I_LIB_SESSION.GetUserLangId;

  open aRefCursor for
    SELECT CAT.RCY_DESCR
     , RCO.RCO_TITLE
     , GCO.GOO_MAJOR_REFERENCE
     , SEN.SEM_VALUE
     , RCO.C_ASA_MACHINE_STATE
     , (SELECT DCOD.GCDTEXT1
         FROM PCS.PC_GCODES DCOD
        WHERE DCOD.GCGNAME = 'C_ASA_MACHINE_STATE'
          AND DCOD.GCLCODE = RCO.C_ASA_MACHINE_STATE
          AND DCOD.PC_LANG_ID = VPC_LANG_ID) C_ASA_MACHINE_STATE_DESCR
     , RCO.C_RCO_STATUS
     , (SELECT DCOD.GCDTEXT1
         FROM PCS.PC_GCODES DCOD
        WHERE DCOD.GCGNAME = 'C_RCO_STATUS'
          AND DCOD.GCLCODE = RCO.C_RCO_STATUS
          AND DCOD.PC_LANG_ID = VPC_LANG_ID) C_RCO_STATUS_DESCR
     , RCO.RCO_MACHINE_LONG_DESCR
     , RCO.RCO_MACHINE_FREE_DESCR
     , RCO.RCO_MACHINE_COMMENT
     , PER_SUP.PER_NAME
     , DMT.DMT_NUMBER
     , POS.POS_NUMBER
     , DMT.DMT_DATE_DOCUMENT
     , RCO.RCO_SUPPLIER_SERIAL_NUMBER
     , RCO.RCO_SUPPLIER_WARRANTY_START
     , RCO.RCO_SUPPLIER_WARRANTY_END
     , RCO.RCO_SUPPLIER_WARRANTY_TERM
     , (SELECT DCOD.GCDTEXT1
         FROM PCS.PC_GCODES DCOD
        WHERE DCOD.GCGNAME = 'C_ASA_GUARANTY_UNIT'
          AND DCOD.GCLCODE = RCO.C_ASA_GUARANTY_UNIT
          AND DCOD.PC_LANG_ID = VPC_LANG_ID) C_ASA_GUARANTY_UNIT_DESCR
     , RCO.RCO_WARRANTY_TEXT
     , RCO.RCO_MACHINE_REMARK
     , RCO.RCO_ESTIMATE_PRICE
     , RCO.RCO_SALE_PRICE
     , RCO.RCO_COST_PRICE
     , PER_CUS.PER_NAME
     , DEP.DEP_DESCRIPTION
     , ADR.ADD_CARE_OF
     , ADR.ADD_ADDRESS1
     , ADR.ADD_PO_BOX
     , ADR.ADD_PO_BOX_NBR
     , ADR.ADD_ZIPCODE
     , ADR.ADD_CITY
     , ADR.ADD_FORMAT
     , ADR.ADD_STATE
     , ADR.ADD_COUNTY
     , MOV.AIM_CUSTOM_NUMBER
     , MOV.AIM_MOVEMENT_DATE
     , MOV.AIM_GUARANTEE_END_DATE
     , MOV.AIM_NEXT_MISSION_COUNTER
     , MOV.AIM_NEXT_MISSION_DATE
     , MOV.DIC_AIM_LOCK_CODE_ID
     , MOV.AIM_LOCATION_COMMENT1
     , MOV.AIM_LOCATION_COMMENT2
     , MOV.AIM_COMMENT
      FROM DOC_RECORD RCO
         , DOC_RECORD_CATEGORY CAT
         , GCO_GOOD GCO
         , STM_ELEMENT_NUMBER SEN
         , PAC_PERSON PER_SUP
         , PAC_PERSON PER_CUS
         , PAC_DEPARTMENT DEP
         , PAC_ADDRESS ADR
         , DOC_DOCUMENT DMT
         , DOC_POSITION POS
         , ASA_INSTALLATION_MOVEMENT MOV
     WHERE RCO.DOC_RECORD_ID = MOV.DOC_RECORD_ID (+)
       AND RCO.DOC_RECORD_CATEGORY_ID = CAT.DOC_RECORD_CATEGORY_ID (+)
       AND RCO.RCO_MACHINE_GOOD_ID = GCO.GCO_GOOD_ID (+)
       AND RCO.STM_ELEMENT_NUMBER_ID = SEN.STM_ELEMENT_NUMBER_ID (+)
       AND RCO.PAC_THIRD_ID = PER_SUP.PAC_PERSON_ID (+)
       AND RCO.DOC_PURCHASE_POSITION_ID = POS.DOC_POSITION_ID (+)
       AND POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID (+)
       AND MOV.PAC_DEPARTMENT_ID = DEP.PAC_DEPARTMENT_ID (+)
       AND MOV.PAC_ADDRESS_ID = ADR.PAC_ADDRESS_ID (+)
       AND MOV.C_ASA_AIM_HISTORY_CODE (+) = 1
       AND MOV.PAC_CUSTOM_PARTNER_ID = PER_CUS.PAC_PERSON_ID (+)
       AND RCO.RCO_TITLE = PROCPARAM_0
       AND RCO.C_RCO_TYPE = '11';

end RPT_ASA_INSTALLATION_FORM;