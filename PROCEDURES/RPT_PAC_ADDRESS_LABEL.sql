--------------------------------------------------------
--  DDL for Procedure RPT_PAC_ADDRESS_LABEL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PAC_ADDRESS_LABEL" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   PARAMETER_0      IN       VARCHAR2,
   PARAMETER_1      IN       VARCHAR2,
   PARAMETER_2      IN       VARCHAR2,
   PARAMETER_3      IN       VARCHAR2
)
IS
/**
 Description - used for the report PAC_ADDRESS_LABEL
 @Created JLIU 27 August 2009
 @public
 @PARAM  parameter_0  Adresses: 0= Toutes; 1= Clients; 2= Fournisseurs; 3= Personnes
 @PARAM  parameter_1  Print additional address
 @PARAM  parameter_2  PER_NAME : (FROM)
 @PARAM  parameter_3  PER_NAME: (TO)
*/


   vpc_lang_id             pcs.pc_lang.pc_lang_id%TYPE;

BEGIN

   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

OPEN arefcursor FOR
SELECT
ADR.ADD_ADDRESS1,
ADR.ADD_FORMAT,
ADR.ADD_PRINCIPAL,
CUS.PAC_CUSTOM_PARTNER_ID,
PER.PER_NAME,
PER.PER_FORENAME,
PER.PER_ACTIVITY,
SUP.PAC_SUPPLIER_PARTNER_ID
FROM
PAC_ADDRESS ADR,
PAC_CUSTOM_PARTNER CUS,
PAC_PERSON PER,
PAC_SUPPLIER_PARTNER SUP,
PAC_THIRD THI
WHERE
ADR.PAC_PERSON_ID = PER.PAC_PERSON_ID
AND PER.PAC_PERSON_ID = THI.PAC_THIRD_ID(+)
AND PER.PAC_PERSON_ID = SUP.PAC_SUPPLIER_PARTNER_ID(+)
AND PER.PAC_PERSON_ID = CUS.PAC_CUSTOM_PARTNER_ID(+)
AND (PER.PER_NAME >= NVL(PARAMETER_2,'(') AND PER.PER_NAME <= NVL(PARAMETER_3,'}'))
AND (PARAMETER_0 is Null OR
     (PARAMETER_0 = '1' AND CUS.PAC_CUSTOM_PARTNER_ID IS NOT NULL) OR
     (PARAMETER_0 = '2' AND SUP.PAC_SUPPLIER_PARTNER_ID IS NOT NULL) OR
     (PARAMETER_0 = '0' AND CUS.PAC_CUSTOM_PARTNER_ID IS NULL AND SUP.PAC_SUPPLIER_PARTNER_ID IS NULL)
     )
AND (PARAMETER_1 = '1' OR
     (PARAMETER_1 <> '1' AND ADR.ADD_PRINCIPAL = 1))
ORDER BY
PER.PER_NAME


;
END RPT_PAC_ADDRESS_LABEL;
