--------------------------------------------------------
--  DDL for Procedure RPT_ASA_RECORD_FORM3_II
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ASA_RECORD_FORM3_II" (
   AREFCURSOR      IN OUT   CRYSTAL_CURSOR_TYPES.DUALCURSORTYP,
   PARAMETER_0     IN       ASA_RECORD.ARE_NUMBER%TYPE,
   COMPANY_OWNER   IN       PCS.PC_COMP.COM_NAME%TYPE,
   USER_LANID      IN       VARCHAR2
)
IS
/*
* description used for report ASA_RECORD_FORM3_II

*@created VHA 02.09.2011
*@version
*@public
*@param param procparam_0: asa_record.are_number
*/
   VPC_LANG_ID   NUMBER (12);

BEGIN
   PCS.PC_I_LIB_SESSION.SETLANID (USER_LANID);
   VPC_LANG_ID := PCS.PC_I_LIB_SESSION.GETUSERLANGID;

   OPEN AREFCURSOR FOR
      SELECT ARE.ASA_RECORD_ID,
            ARE.ASA_RECORD_EVENTS_ID,
            ARE.ARE_NUMBER,
             ARE.ARE_CUSTOMER_REF,
             ARE.ARE_DATECRE,
             ARE.ARE_CHAR1_VALUE,
             GOO.GOO_MAJOR_REFERENCE,
                GOO.GOO_MAJOR_REFERENCE || ' / ' || ARE.ARE_CHAR1_VALUE GOO_GOO_CHAR,
             EXC.GOO_MAJOR_REFERENCE EXC_MAJOR_REFERENCE,
                EXC.GOO_MAJOR_REFERENCE || ' / ' || ARE.ARE_NEW_CHAR1_VALUE EXC_GOO_CHAR,
             ARE.ARE_NEW_CHAR1_VALUE,
             ARE.GCO_ASA_EXCHANGE_ID,
             ARE.ARE_EXCH_CHAR1_VALUE,
             ARE.C_ASA_REP_STATUS,
             COM_FUNCTIONS.GETDESCODEDESCR('C_ASA_REP_STATUS', ARE.C_ASA_REP_STATUS, VPC_LANG_ID) C_ASA_REP_STATUS_DESCR,
             ARE.ARE_GCO_SHORT_DESCR_EX,
             ARE.ARE_GCO_FREE_DESCR_EX,
             ARE.ARE_DATE_END_REP,
             ARE.ARE_DATE_END_CTRL,
             ARE.ARE_GCO_SHORT_DESCR,
             ARE.ARE_GCO_LONG_DESCR,
             ARE.ARE_DATE_END_SENDING,
             ARE.GCO_ASA_TO_REPAIR_ID,
             ARE.DIC_GARANTY_CODE_ID,
             COM_DIC_FUNCTIONS.GETDICODESCR('DIC_GARANTY_CODE', ARE.DIC_GARANTY_CODE_ID, VPC_LANG_ID) DIC_GARANTY_CODE_DES,
             PER.PER_NAME, ARE.ARE_ADDRESS1,
             PCS.EXTRACTLINE (ARE.ARE_ADDRESS1, 1) ARE_ADDRESS1_EXTRACT,
             PER.PER_SHORT_NAME, ARE.GCO_NEW_GOOD_ID, ARE.ASA_REP_TYPE_ID,
             LAN.LANID, RET.C_ASA_REP_TYPE_KIND,
             --for showing the picture
             RPT_FUNCTIONS.GET_ASA_IMG_PATH (ARE.ASA_RECORD_ID) ASA_PICTURE,
             TO_CHAR (NVL (DLO.OFFER_DATECRE, SYSDATE), 'YYYYMMDD HH24:MI:SS') OFFER_DATECRE,
             NVL ((SELECT COUNT (*)
                     FROM ASA_RECORD_TASK RET
                    WHERE RET.ASA_RECORD_ID = ARE.ASA_RECORD_ID
                      AND RET.ASA_RECORD_EVENTS_ID = ARE.ASA_RECORD_EVENTS_ID
                      AND RET.RET_OPTIONAL = 0
                      AND (RET.A_DATECRE) <=(NVL (DLO.OFFER_DATECRE, SYSDATE))), 0
                 ) OPE_REQ,
             NVL ((SELECT COUNT (*)
                     FROM ASA_RECORD_COMP ARC
                    WHERE ARC.ASA_RECORD_ID = ARE.ASA_RECORD_ID
                      AND ARC.ASA_RECORD_EVENTS_ID = ARE.ASA_RECORD_EVENTS_ID
                      AND ARC.ARC_OPTIONAL = 0
                      AND (ARC.A_DATECRE) <= (NVL (DLO.OFFER_DATECRE, SYSDATE))), 0
                 ) COMP_REQ,
             NVL ((SELECT COUNT (*)
                     FROM ASA_RECORD_TASK RET
                    WHERE RET.ASA_RECORD_ID = ARE.ASA_RECORD_ID
                      AND RET.ASA_RECORD_EVENTS_ID = ARE.ASA_RECORD_EVENTS_ID
                      AND RET.RET_OPTIONAL = 1
                      AND (RET.A_DATECRE) <= (NVL (DLO.OFFER_DATECRE, SYSDATE))), 0
                 ) OPE_OPT,
             NVL ((SELECT COUNT (*)
                     FROM ASA_RECORD_COMP ARC
                    WHERE ARC.ASA_RECORD_ID = ARE.ASA_RECORD_ID
                      AND ARC.ASA_RECORD_EVENTS_ID = ARE.ASA_RECORD_EVENTS_ID
                      AND ARC.ARC_OPTIONAL = 1
                      AND (ARC.A_DATECRE) <= (NVL (DLO.OFFER_DATECRE, SYSDATE))), 0
                 ) COMP_OPT,
             NVL ((SELECT COUNT (*)
                     FROM ASA_RECORD_TASK RET
                    WHERE RET.ASA_RECORD_ID = ARE.ASA_RECORD_ID
                      AND RET.ASA_RECORD_EVENTS_ID = ARE.ASA_RECORD_EVENTS_ID
                      AND (RET.A_DATECRE) > (NVL (DLO.OFFER_DATECRE, SYSDATE))), 0
                 ) OPE_ADD,
             NVL ((SELECT COUNT (*)
                     FROM ASA_RECORD_COMP ARC
                    WHERE ARC.ASA_RECORD_ID = ARE.ASA_RECORD_ID
                      AND ARC.ASA_RECORD_EVENTS_ID = ARE.ASA_RECORD_EVENTS_ID
                      AND (ARC.A_DATECRE) > (NVL (DLO.OFFER_DATECRE, SYSDATE))), 0
                 ) COMP_ADD,
             COM_DIC_FUNCTIONS.GETDICODESCR('DIC_RECEPTION_MODE', ARE.DIC_RECEPTION_MODE_ID, VPC_LANG_ID) DIC_RECEPTION_MODE_DESC,
             ARE.ARE_INTERNAL_REMARK,
             ARE.ARE_CUSTOMER_REMARK,
             ARE.ARE_REQ_DATE_TEXT,
             COM_FUNCTIONS.GETDESCODEDESCR('C_PRIORITY', ARE.C_PRIORITY, VPC_LANG_ID) C_PRIORITY_DESC,
             ARE.ARE_ADDITIONAL_ITEMS,
             ARE.ARE_CUSTOMS_VALUE,
             ARE.ACS_CUSTOM_FIN_CURR_ID,
             ARE.ARE_CONTACT_COMMENT
        FROM ASA_RECORD ARE,
             GCO_GOOD GOO,
             GCO_GOOD EXC,
             PAC_PERSON PER,
             (SELECT   MAX (RRE1.A_DATECRE) OFFER_DATECRE, ARE1.ASA_RECORD_ID
                  FROM ASA_RECORD ARE1, ASA_RECORD_EVENTS RRE1
                 WHERE ARE1.ASA_RECORD_ID = RRE1.ASA_RECORD_ID
                   AND ARE1.C_ASA_REP_STATUS = '02'
              GROUP BY ARE1.ASA_RECORD_ID) DLO,
             PCS.PC_LANG LAN,
             ASA_REP_TYPE RET
       WHERE ARE.PAC_CUSTOM_PARTNER_ID = PER.PAC_PERSON_ID
         AND ARE.GCO_ASA_TO_REPAIR_ID = GOO.GCO_GOOD_ID(+)
         AND ARE.GCO_ASA_EXCHANGE_ID = EXC.GCO_GOOD_ID(+)
         AND DLO.ASA_RECORD_ID(+) = ARE.ASA_RECORD_ID
         AND ARE.PC_ASA_CUST_LANG_ID = LAN.PC_LANG_ID(+)
         AND ARE.ASA_REP_TYPE_ID = RET.ASA_REP_TYPE_ID(+)
         AND ARE.ARE_NUMBER = PARAMETER_0;
END RPT_ASA_RECORD_FORM3_II;