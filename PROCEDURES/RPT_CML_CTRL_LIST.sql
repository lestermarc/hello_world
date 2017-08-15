--------------------------------------------------------
--  DDL for Procedure RPT_CML_CTRL_LIST
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_CML_CTRL_LIST" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       VARCHAR2,
   parameter_1   IN       VARCHAR2,
   parameter_2   IN       VARCHAR2,
   parameter_3   IN       VARCHAR2,
   parameter_4   IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS
/**
* Description - used for the report CML_CTRL_LIST

* @CREATED IN PROCONCEPT CHINA
* @AUTHOR JLIU 27 MAY 2009
* @LAST UPDATE 28 jan 2010
* @PUBLIC

* @PARAM PARAMETER_0    Customers (1 All)
* @PARAM PARAMETER_1    Com_list des id des Customers (si PARAMETER_0 = 0 )
* @PARAM PARAMETER_2    Contracts (1 All)
* @PARAM PARAMETER_3    Com_list des id des Contrats (si PARAMETER_2 = 0 )
* @PARAM PARAMETER_4    Status of the position of contract
*/


  vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

IF PARAMETER_2 = 0 --selection de contrats
THEN
   OPEN arefcursor FOR
        SELECT
        DMT.CCO_NUMBER,
        DMT.C_CML_CONTRACT_STATUS,
        DMT.PC_LANG_ID,
        POS.CPO_SEQUENCE,
        POS.C_CML_POS_STATUS,
        POS.C_CML_POS_TYPE,
        POS.C_CML_RENT_TYPE,
        POS.C_CML_MAINT_TYPE,
        POS.CPO_RENT_PRICE,
        POS.CPO_MAINT_PRICE,
        POS.CPO_RENT_AMOUNT,
        POS.CPO_MAINT_AMOUNT,
        POS.CPO_RENT_LOSS,
        POS.CPO_MAINT_LOSS,
        POS.CPO_RENT_ADDED_AMOUNT,
        POS.CPO_MAIN_ADDED_AMOUNT,
        POS.CPO_BEGIN_CONTRACT_DATE,
        POS.CPO_END_CONTRACT_DATE,
        POS.CPO_END_EXTENDED_DATE,
        POS.CPO_RESILIATION_DATE,
        POS.CPO_DEPOT_AMOUNT,
        POS.CPO_DEPOT_BILL_DATE,
        POS.CPO_PENALITY_AMOUNT,
        POS.CPO_PENALITY_BILL_DATE,
        POS.CPO_BILL_TEXT,
        POS.CPO_FREE_TEXT_1,
        POS.CPO_FREE_TEXT_2,
        POS.CPO_FREE_TEXT_3,
        POS.CPO_FREE_TEXT_4,
        POS.CPO_FREE_TEXT_5,
        gco_functions.getdescription (goo.gco_good_id, procuser_lanid, 1, '01') DES_SHORT_DESCRIPTION,
        gco_functions.getdescription (goo.gco_good_id, procuser_lanid, 2, '01') DES_LONG_DESCRIPTION,
        gco_functions.getdescription (goo.gco_good_id, procuser_lanid, 3, '01') DES_FREE_DESCRIPTION,
        GOO.GOO_MAJOR_REFERENCE,
        ADR.ADD_ADDRESS1,
        ADR.ADD_FORMAT,
        PER.PER_NAME,
        PER.PER_FORENAME,
        PER.PER_ACTIVITY,
        CUR.CURRENCY,
        vpc_lang_id LANID
        FROM
        ACS_FINANCIAL_CURRENCY FUR,
        ( SELECT CML_DOCUMENT_ID,
                 PAC_CUSTOM_PARTNER_ID,
                 PAC_REPRESENTATIVE_ID,
                 PAC_PAYMENT_CONDITION_ID,
                 PC_LANG_ID,
                 C_CML_CONTRACT_STATUS,
                 CCO_NUMBER
          FROM CML_DOCUMENT DOC, COM_LIST COM
          WHERE CML_DOCUMENT_ID = COM.LIS_ID_1
                AND COM.LIS_JOB_ID = PARAMETER_3
                AND COM.LIS_CODE = 'CML_DOCUMENT_ID'
        ) DMT,
        CML_FREE_DATA DAT,
        CML_POSITION POS,
        GCO_GOOD GOO,
        PAC_ADDRESS ADR,
        PAC_CUSTOM_PARTNER CUS,
        PAC_PAYMENT_CONDITION PON,
        PAC_PERSON PER,
        PAC_REPRESENTATIVE REP,
        PAC_THIRD THI,
        PCS.PC_CURR CUR
        WHERE
        DMT.CML_DOCUMENT_ID = DAT.CML_DOCUMENT_ID(+)
        AND DMT.CML_DOCUMENT_ID = POS.CML_DOCUMENT_ID
        AND POS.ACS_FINANCIAL_CURRENCY_ID = FUR.ACS_FINANCIAL_CURRENCY_ID
        AND FUR.PC_CURR_ID = CUR.PC_CURR_ID
        AND POS.CPO_POS_GOOD_ID = GOO.GCO_GOOD_ID
        AND DMT.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
        AND CUS.PAC_CUSTOM_PARTNER_ID = THI.PAC_THIRD_ID
        AND THI.PAC_THIRD_ID = PER.PAC_PERSON_ID
        AND PER.PAC_PERSON_ID = ADR.PAC_PERSON_ID
        AND DMT.PAC_REPRESENTATIVE_ID = REP.PAC_REPRESENTATIVE_ID(+)
        AND DMT.PAC_PAYMENT_CONDITION_ID = PON.PAC_PAYMENT_CONDITION_ID(+)
        AND ADR.ADD_PRINCIPAL = 1
        AND (PARAMETER_4 = '#' OR INSTR(',' || PARAMETER_4 || ',', ',' || POS.C_CML_POS_STATUS ||',') > 0 );

ELSE
IF PARAMETER_0 = 0 --selection de CLIENTS
THEN
  OPEN arefcursor FOR
        SELECT
        DMT.CCO_NUMBER,
        DMT.C_CML_CONTRACT_STATUS,
        DMT.PC_LANG_ID,
        DMT.CPO_SEQUENCE,
        DMT.C_CML_POS_STATUS,
        DMT.C_CML_POS_TYPE,
        DMT.C_CML_RENT_TYPE,
        DMT.C_CML_MAINT_TYPE,
        DMT.CPO_RENT_PRICE,
        DMT.CPO_MAINT_PRICE,
        DMT.CPO_RENT_AMOUNT,
        DMT.CPO_MAINT_AMOUNT,
        DMT.CPO_RENT_LOSS,
        DMT.CPO_MAINT_LOSS,
        DMT.CPO_RENT_ADDED_AMOUNT,
        DMT.CPO_MAIN_ADDED_AMOUNT,
        DMT.CPO_BEGIN_CONTRACT_DATE,
        DMT.CPO_END_CONTRACT_DATE,
        DMT.CPO_END_EXTENDED_DATE,
        DMT.CPO_RESILIATION_DATE,
        DMT.CPO_DEPOT_AMOUNT,
        DMT.CPO_DEPOT_BILL_DATE,
        DMT.CPO_PENALITY_AMOUNT,
        DMT.CPO_PENALITY_BILL_DATE,
        DMT.CPO_BILL_TEXT,
        DMT.CPO_FREE_TEXT_1,
        DMT.CPO_FREE_TEXT_2,
        DMT.CPO_FREE_TEXT_3,
        DMT.CPO_FREE_TEXT_4,
        DMT.CPO_FREE_TEXT_5,
        gco_functions.getdescription (goo.gco_good_id, procuser_lanid, 1, '01') DES_SHORT_DESCRIPTION,
        gco_functions.getdescription (goo.gco_good_id, procuser_lanid, 2, '01') DES_LONG_DESCRIPTION,
        gco_functions.getdescription (goo.gco_good_id, procuser_lanid, 3, '01') DES_FREE_DESCRIPTION,
        GOO.GOO_MAJOR_REFERENCE,
        ADR.ADD_ADDRESS1,
        ADR.ADD_FORMAT,
        PER.PER_NAME,
        PER.PER_FORENAME,
        PER.PER_ACTIVITY,
        CUR.CURRENCY,
        vpc_lang_id LANID
        FROM
        ACS_FINANCIAL_CURRENCY FUR,
        ( SELECT DOC.CML_DOCUMENT_ID,
                 DOC.PAC_REPRESENTATIVE_ID,
                 DOC.PAC_PAYMENT_CONDITION_ID,
                 PC_LANG_ID,
                 C_CML_CONTRACT_STATUS,
                 CCO_NUMBER,
                 CUS.PAC_CUSTOM_PARTNER_ID,
                 POS.ACS_FINANCIAL_CURRENCY_ID,
                 POS.CPO_POS_GOOD_ID,POS.CPO_SEQUENCE,
                 POS.C_CML_POS_STATUS,
                 POS.C_CML_POS_TYPE,
                 POS.C_CML_RENT_TYPE,
                 POS.C_CML_MAINT_TYPE,
                 POS.CPO_RENT_PRICE,
                 POS.CPO_MAINT_PRICE,
                 POS.CPO_RENT_AMOUNT,
                 POS.CPO_MAINT_AMOUNT,
                 POS.CPO_RENT_LOSS,
                 POS.CPO_MAINT_LOSS,
                 POS.CPO_RENT_ADDED_AMOUNT,
                 POS.CPO_MAIN_ADDED_AMOUNT,
                 POS.CPO_BEGIN_CONTRACT_DATE,
                 POS.CPO_END_CONTRACT_DATE,
                 POS.CPO_END_EXTENDED_DATE,
                 POS.CPO_RESILIATION_DATE,
                 POS.CPO_DEPOT_AMOUNT,
                 POS.CPO_DEPOT_BILL_DATE,
                 POS.CPO_PENALITY_AMOUNT,
                 POS.CPO_PENALITY_BILL_DATE,
                 POS.CPO_BILL_TEXT,
                 POS.CPO_FREE_TEXT_1,
                 POS.CPO_FREE_TEXT_2,
                 POS.CPO_FREE_TEXT_3,
                 POS.CPO_FREE_TEXT_4,
                 POS.CPO_FREE_TEXT_5
          FROM  PAC_CUSTOM_PARTNER CUS,CML_DOCUMENT DOC, COM_LIST COM, CML_POSITION POS
          WHERE CUS.PAC_CUSTOM_PARTNER_ID = COM.LIS_ID_1
                AND COM.LIS_JOB_ID = PARAMETER_1
                AND COM.LIS_CODE = 'PAC_CUSTOM_PARTNER_ID'
                AND CUS.PAC_CUSTOM_PARTNER_ID = DOC.PAC_CUSTOM_PARTNER_ID
                AND DOC.CML_DOCUMENT_ID = POS.CML_DOCUMENT_ID
                AND (PARAMETER_4 = '#' OR INSTR(',' || PARAMETER_4 || ',', ',' || POS.C_CML_POS_STATUS ||',') > 0 )
        ) DMT,
        CML_FREE_DATA DAT,
        GCO_GOOD GOO,
        PAC_ADDRESS ADR,
        PAC_PAYMENT_CONDITION PON,
        PAC_PERSON PER,
        PAC_REPRESENTATIVE REP,
        PAC_THIRD THI,
        PCS.PC_CURR CUR
        WHERE
            DMT.CML_DOCUMENT_ID = DAT.CML_DOCUMENT_ID(+)
        AND DMT.ACS_FINANCIAL_CURRENCY_ID = FUR.ACS_FINANCIAL_CURRENCY_ID
        AND FUR.PC_CURR_ID = CUR.PC_CURR_ID
        AND DMT.CPO_POS_GOOD_ID = GOO.GCO_GOOD_ID
        AND DMT.PAC_CUSTOM_PARTNER_ID = THI.PAC_THIRD_ID
        AND THI.PAC_THIRD_ID = PER.PAC_PERSON_ID
        AND PER.PAC_PERSON_ID = ADR.PAC_PERSON_ID
        AND DMT.PAC_REPRESENTATIVE_ID = REP.PAC_REPRESENTATIVE_ID(+)
        AND DMT.PAC_PAYMENT_CONDITION_ID = PON.PAC_PAYMENT_CONDITION_ID(+)
        AND ADR.ADD_PRINCIPAL = 1;
ELSE  -- TOUS  LES CONTRATS ET CLIENTS
   OPEN arefcursor FOR
        SELECT
        DMT.CCO_NUMBER,
        DMT.C_CML_CONTRACT_STATUS,
        DMT.PC_LANG_ID,
        POS.CPO_SEQUENCE,
        POS.C_CML_POS_STATUS,
        POS.C_CML_POS_TYPE,
        POS.C_CML_RENT_TYPE,
        POS.C_CML_MAINT_TYPE,
        POS.CPO_RENT_PRICE,
        POS.CPO_MAINT_PRICE,
        POS.CPO_RENT_AMOUNT,
        POS.CPO_MAINT_AMOUNT,
        POS.CPO_RENT_LOSS,
        POS.CPO_MAINT_LOSS,
        POS.CPO_RENT_ADDED_AMOUNT,
        POS.CPO_MAIN_ADDED_AMOUNT,
        POS.CPO_BEGIN_CONTRACT_DATE,
        POS.CPO_END_CONTRACT_DATE,
        POS.CPO_END_EXTENDED_DATE,
        POS.CPO_RESILIATION_DATE,
        POS.CPO_DEPOT_AMOUNT,
        POS.CPO_DEPOT_BILL_DATE,
        POS.CPO_PENALITY_AMOUNT,
        POS.CPO_PENALITY_BILL_DATE,
        POS.CPO_BILL_TEXT,
        POS.CPO_FREE_TEXT_1,
        POS.CPO_FREE_TEXT_2,
        POS.CPO_FREE_TEXT_3,
        POS.CPO_FREE_TEXT_4,
        POS.CPO_FREE_TEXT_5,
        gco_functions.getdescription (goo.gco_good_id, procuser_lanid, 1, '01') DES_SHORT_DESCRIPTION,
        gco_functions.getdescription (goo.gco_good_id, procuser_lanid, 2, '01') DES_LONG_DESCRIPTION,
        gco_functions.getdescription (goo.gco_good_id, procuser_lanid, 3, '01') DES_FREE_DESCRIPTION,
        GOO.GOO_MAJOR_REFERENCE,
        ADR.ADD_ADDRESS1,
        ADR.ADD_FORMAT,
        PER.PER_NAME,
        PER.PER_FORENAME,
        PER.PER_ACTIVITY,
        CUR.CURRENCY,
        vpc_lang_id LANID
        FROM
        ACS_FINANCIAL_CURRENCY FUR,
        ( SELECT CPO_SEQUENCE,
                 C_CML_POS_STATUS,
                 C_CML_POS_TYPE,
                 C_CML_RENT_TYPE,
                 C_CML_MAINT_TYPE,
                 CPO_RENT_PRICE,
                 CPO_MAINT_PRICE,
                 CPO_RENT_AMOUNT,
                 CPO_MAINT_AMOUNT,
                 CPO_RENT_LOSS,
                 CPO_MAINT_LOSS,
                 CPO_RENT_ADDED_AMOUNT,
                 CPO_MAIN_ADDED_AMOUNT,
                 CPO_BEGIN_CONTRACT_DATE,
                 CPO_END_CONTRACT_DATE,
                 CPO_END_EXTENDED_DATE,
                 CPO_RESILIATION_DATE,
                 CPO_DEPOT_AMOUNT,
                 CPO_DEPOT_BILL_DATE,
                 CPO_PENALITY_AMOUNT,
                 CPO_PENALITY_BILL_DATE,
                 CPO_BILL_TEXT,
                 CPO_FREE_TEXT_1,
                 CPO_FREE_TEXT_2,
                 CPO_FREE_TEXT_3,
                 CPO_FREE_TEXT_4,
                 CPO_FREE_TEXT_5,
                 CPO_POS_GOOD_ID,
                 ACS_FINANCIAL_CURRENCY_ID,
                 CML_DOCUMENT_ID
          FROM CML_POSITION
          WHERE (PARAMETER_4 = '#' OR INSTR(',' || PARAMETER_4 || ',', ',' || C_CML_POS_STATUS ||',') > 0 )
        ) POS,
        CML_DOCUMENT DMT,
        CML_FREE_DATA DAT,
        GCO_GOOD GOO,
        PAC_ADDRESS ADR,
        PAC_CUSTOM_PARTNER CUS,
        PAC_PAYMENT_CONDITION PON,
        PAC_PERSON PER,
        PAC_REPRESENTATIVE REP,
        PAC_THIRD THI,
        PCS.PC_CURR CUR
        WHERE
            POS.CML_DOCUMENT_ID = DMT.CML_DOCUMENT_ID
        AND DMT.CML_DOCUMENT_ID = DAT.CML_DOCUMENT_ID(+)
        AND POS.ACS_FINANCIAL_CURRENCY_ID = FUR.ACS_FINANCIAL_CURRENCY_ID
        AND FUR.PC_CURR_ID = CUR.PC_CURR_ID
        AND POS.CPO_POS_GOOD_ID = GOO.GCO_GOOD_ID
        AND DMT.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID
        AND CUS.PAC_CUSTOM_PARTNER_ID = THI.PAC_THIRD_ID
        AND THI.PAC_THIRD_ID = PER.PAC_PERSON_ID
        AND PER.PAC_PERSON_ID = ADR.PAC_PERSON_ID
        AND DMT.PAC_REPRESENTATIVE_ID = REP.PAC_REPRESENTATIVE_ID(+)
        AND DMT.PAC_PAYMENT_CONDITION_ID = PON.PAC_PAYMENT_CONDITION_ID(+)
        AND ADR.ADD_PRINCIPAL = 1;



END IF;
END IF;
END RPT_CML_CTRL_LIST;
