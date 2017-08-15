--------------------------------------------------------
--  DDL for Package Body ASA_INSTALLATION_RPT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ASA_INSTALLATION_RPT" 
is
  procedure ASA_FORM_RPT_PK(aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp, PROCPARAM_0 in varchar2, PROCUSER_LANID in pcs.pc_lang.lanid%type)
  is
/**
 Procedure stockee utilisee pour le rapport ASA_INSTALLATION_FORM (Fiche d'installation)

 @author JSC
 @lastUpdate 07 Août 2007 (voir commentaire à coté des champs)
 @version 2003
 @public
 @param PROCPARAM_0    Numero d'insallation RCO_TITLE
*/
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open aRefCursor for
      select RCO.DOC_RECORD_ID
           , CAT.RCY_DESCR
           , RCO.RCO_TITLE
           , RCO.RCO_TITLE || ' ' || to_char(RCO.RCO_NUMBER, '0000000') RCO_TITLE_NUMBER   -- ajout
           , GCO.GOO_MAJOR_REFERENCE
           , SEN.SEM_VALUE
           , RCO.C_ASA_MACHINE_STATE
           , (select DCOD.GCDTEXT1
                from PCS.PC_GCODES DCOD
               where DCOD.GCGNAME = 'C_ASA_MACHINE_STATE'
                 and DCOD.GCLCODE = RCO.C_ASA_MACHINE_STATE
                 and DCOD.PC_LANG_ID = VPC_LANG_ID) C_ASA_MACHINE_STATE_DESCR
           , RCO.C_RCO_STATUS
           , (select DCOD.GCDTEXT1
                from PCS.PC_GCODES DCOD
               where DCOD.GCGNAME = 'C_RCO_STATUS'
                 and DCOD.GCLCODE = RCO.C_RCO_STATUS
                 and DCOD.PC_LANG_ID = VPC_LANG_ID) C_RCO_STATUS_DESCR
           , RCO.RCO_MACHINE_LONG_DESCR
           , RCO.RCO_MACHINE_FREE_DESCR
           , RCO.RCO_MACHINE_COMMENT
           , GAL.RCO_TITLE
           , decode(RCO.PPS_NOMENCLATURE_ID, null, 0, 1)
           , PER_SUP.PER_NAME
           , DMT.DMT_NUMBER
           , POS.POS_NUMBER
           , DMT.DMT_DATE_DOCUMENT
           , RCO.RCO_SUPPLIER_SERIAL_NUMBER
           , RCO.RCO_SUPPLIER_WARRANTY_START
           , RCO.RCO_SUPPLIER_WARRANTY_END
           , RCO.RCO_SUPPLIER_WARRANTY_TERM
           , (select DCOD.GCDTEXT1
                from PCS.PC_GCODES DCOD
               where DCOD.GCGNAME = 'C_ASA_GUARANTY_UNIT'
                 and DCOD.GCLCODE = RCO.C_ASA_GUARANTY_UNIT
                 and DCOD.PC_LANG_ID = VPC_LANG_ID) C_ASA_GUARANTY_UNIT_DESCR
           , RCO.RCO_WARRANTY_TEXT
           , RCO.RCO_MACHINE_REMARK
           , RCO.RCO_ESTIMATE_PRICE
           , RCO.RCO_SALE_PRICE
           , RCO.RCO_COST_PRICE
           , PER_CUS.PER_NAME CUS_PER_NAME   --changé le nom du champ car PER_NAME existe déjà dans cette requète
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
           , ADR.ADD_ADDRESS1 || chr(13) || ADR.ADD_FORMAT ADR   --c'est plus simple de concatener les champs dans oracle
           , MOV.AIM_CUSTOM_NUMBER
           , MOV.AIM_MOVEMENT_DATE
           , MOV.AIM_GUARANTEE_END_DATE
           , MOV.AIM_NEXT_MISSION_COUNTER
           , MOV.AIM_NEXT_MISSION_DATE
           , MOV.DIC_AIM_LOCK_CODE_ID
           , MOV.AIM_LOCATION_COMMENT1
           , MOV.AIM_LOCATION_COMMENT2
           , MOV.AIM_COMMENT
        from DOC_RECORD RCO
           , DOC_RECORD GAL
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
       where RCO.DOC_RECORD_ID = MOV.DOC_RECORD_ID(+)
         and RCO.DOC_RECORD_GAL_ID = GAL.DOC_RECORD_ID(+)
         and RCO.DOC_RECORD_CATEGORY_ID = CAT.DOC_RECORD_CATEGORY_ID(+)
         and RCO.RCO_MACHINE_GOOD_ID = GCO.GCO_GOOD_ID(+)
         and RCO.STM_ELEMENT_NUMBER_ID = SEN.STM_ELEMENT_NUMBER_ID(+)
         and RCO.PAC_THIRD_ID = PER_SUP.PAC_PERSON_ID(+)
         and RCO.DOC_PURCHASE_POSITION_ID = POS.DOC_POSITION_ID(+)
         and POS.DOC_DOCUMENT_ID = DMT.DOC_DOCUMENT_ID(+)
         and MOV.PAC_DEPARTMENT_ID = DEP.PAC_DEPARTMENT_ID(+)
         and MOV.PAC_ADDRESS_ID = ADR.PAC_ADDRESS_ID(+)
         and MOV.C_ASA_AIM_HISTORY_CODE(+) = 1
         and MOV.PAC_CUSTOM_PARTNER_ID = PER_CUS.PAC_PERSON_ID(+)
         and RCO.RCO_TITLE = PROCPARAM_0
         and RCO.C_RCO_TYPE = '11';
  end ASA_FORM_RPT_PK;

  procedure ASA_FORM_LINK_RPT_PK(aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp, ANYTHING in varchar2   --NUMBER
                                                                                                           , PROCUSER_LANID in pcs.pc_lang.lanid%type)
  is
/**
 Procedure stockee utilisee pour le sous-rapport LINKS du rapport ASA_INSTALLATION_FORM (Fiche d'installation)

 @author PNA
 @lastUpdate
 @version 2003
 @public
 @param PROCPARAM_0    Numero d'insallation DOC_RECORD_ID
*/
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open aRefCursor for
      select RCO_FATHER.RCO_TITLE RCO_FATHER
           , DCL.RLT_UPWARD_SEMANTIC
           , RCO_SON.RCO_TITLE RCO_SON
           , (select GOO_MAJOR_REFERENCE
                from GCO_GOOD GOO
               where GOO.GCO_GOOD_ID = RCO_SON.RCO_MACHINE_GOOD_ID) GOO_MAJOR_REFERENCE
           , RCO_SON.RCO_MACHINE_LONG_DESCR
           , RCO_SON.RCO_MACHINE_FREE_DESCR
           , RCL_COMMENT
        from DOC_RECORD RCO_FATHER
           , DOC_RECORD_LINK RCL
           , DOC_RECORD RCO_SON
           , DOC_RECORD_CATEGORY_LINK RLT
           , DOC_RECORD_CAT_LINK_TYPE DCL
       where RCO_FATHER.DOC_RECORD_ID = RCL.DOC_RECORD_FATHER_ID
         and RCL.DOC_RECORD_SON_ID = RCO_SON.DOC_RECORD_ID
         and RCL.DOC_RECORD_CATEGORY_LINK_ID = RLT.DOC_RECORD_CATEGORY_LINK_ID
         and RLT.DOC_RECORD_CAT_LINK_TYPE_ID = DCL.DOC_RECORD_CAT_LINK_TYPE_ID
         and RCO_FATHER.RCO_TITLE = ANYTHING;
  end ASA_FORM_LINK_RPT_PK;
end ASA_INSTALLATION_RPT;
