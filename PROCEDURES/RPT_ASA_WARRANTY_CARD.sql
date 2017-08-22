--------------------------------------------------------
--  DDL for Procedure RPT_ASA_WARRANTY_CARD
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ASA_WARRANTY_CARD" (
   AREFCURSOR       IN OUT   CRYSTAL_CURSOR_TYPES.DUALCURSORTYP,
   PROCPARAM_0      IN       varchar2
)
IS
/**
 Description - used for the report RPT_ASA_WARRANTY_CARD


 @param PROCPARAM_0: AGC_NUMBER

 @author VHA 22.08.2011
 @public
*/

BEGIN

   OPEN AREFCURSOR FOR

      SELECT
        AGC.ASA_GUARANTY_CARDS_ID,
        AGC.AGC_NUMBER,
        GCO.GOO_MAJOR_REFERENCE,
        (SELECT GCO_DESC.DES_SHORT_DESCRIPTION
          FROM GCO_DESCRIPTION GCO_DESC
          WHERE GCO_DESC.GCO_GOOD_ID = GCO.GCO_GOOD_ID AND
                GCO_DESC.PC_LANG_ID = COALESCE (AGC.PC_ASA_FIN_CUST_LANG_ID,PC_ASA_DISTRIB_LANG_ID,PC_ASA_AGENT_LANG_ID) AND
                GCO_DESC.C_DESCRIPTION_TYPE = '01' ) GOO_SECONDARY_REFERENCE,
        COALESCE ((SELECT CHA.CHA_CHARACTERIZATION_DESIGN
                    FROM GCO_CHARACTERIZATION CHA
                    WHERE CHA.GCO_CHARACTERIZATION_ID = AGC.GCO_CHAR1_ID),
                  (SELECT CHA.CHA_CHARACTERIZATION_DESIGN
                    FROM GCO_CHARACTERIZATION CHA
                    WHERE CHA.GCO_CHARACTERIZATION_ID = AGC.GCO_CHAR2_ID),
                  (SELECT CHA.CHA_CHARACTERIZATION_DESIGN
                    FROM GCO_CHARACTERIZATION CHA
                    WHERE CHA.GCO_CHARACTERIZATION_ID = AGC.GCO_CHAR3_ID),
                  (SELECT CHA.CHA_CHARACTERIZATION_DESIGN
                    FROM GCO_CHARACTERIZATION CHA
                    WHERE CHA.GCO_CHARACTERIZATION_ID = AGC.GCO_CHAR4_ID),
                  (SELECT CHA.CHA_CHARACTERIZATION_DESIGN
                    FROM GCO_CHARACTERIZATION CHA
                    WHERE CHA.GCO_CHARACTERIZATION_ID = AGC.GCO_CHAR5_ID)) CHAR_DESC_1,
        COALESCE ((SELECT CHA.CHA_CHARACTERIZATION_DESIGN
                    FROM GCO_CHARACTERIZATION CHA
                    WHERE CHA.GCO_CHARACTERIZATION_ID = AGC.GCO_CHAR2_ID),
                  (SELECT CHA.CHA_CHARACTERIZATION_DESIGN
                    FROM GCO_CHARACTERIZATION CHA
                    WHERE CHA.GCO_CHARACTERIZATION_ID = AGC.GCO_CHAR3_ID),
                  (SELECT CHA.CHA_CHARACTERIZATION_DESIGN
                    FROM GCO_CHARACTERIZATION CHA
                    WHERE CHA.GCO_CHARACTERIZATION_ID = AGC.GCO_CHAR4_ID),
                  (SELECT CHA.CHA_CHARACTERIZATION_DESIGN
                    FROM GCO_CHARACTERIZATION CHA
                    WHERE CHA.GCO_CHARACTERIZATION_ID = AGC.GCO_CHAR5_ID)) CHAR_DESC_2,
        COALESCE ((SELECT CHA.CHA_CHARACTERIZATION_DESIGN
                    FROM GCO_CHARACTERIZATION CHA
                   WHERE CHA.GCO_CHARACTERIZATION_ID = AGC.GCO_CHAR3_ID),
                  (SELECT CHA.CHA_CHARACTERIZATION_DESIGN
                    FROM GCO_CHARACTERIZATION CHA
                    WHERE CHA.GCO_CHARACTERIZATION_ID = AGC.GCO_CHAR4_ID),
                  (SELECT CHA.CHA_CHARACTERIZATION_DESIGN
                    FROM GCO_CHARACTERIZATION CHA
                    WHERE CHA.GCO_CHARACTERIZATION_ID = AGC.GCO_CHAR5_ID)) CHAR_DESC_3,
        COALESCE ((SELECT CHA.CHA_CHARACTERIZATION_DESIGN
                    FROM GCO_CHARACTERIZATION CHA
                    WHERE CHA.GCO_CHARACTERIZATION_ID = AGC.GCO_CHAR4_ID),
                  (SELECT CHA.CHA_CHARACTERIZATION_DESIGN
                    FROM GCO_CHARACTERIZATION CHA
                    WHERE CHA.GCO_CHARACTERIZATION_ID = AGC.GCO_CHAR5_ID)) CHAR_DESC_4,
        (SELECT CHA.CHA_CHARACTERIZATION_DESIGN
          FROM GCO_CHARACTERIZATION CHA
          WHERE CHA.GCO_CHARACTERIZATION_ID = AGC.GCO_CHAR5_ID) CHAR_DESC_5,
        COALESCE (AGC.AGC_CHAR1_VALUE,AGC.AGC_CHAR2_VALUE,AGC.AGC_CHAR3_VALUE,AGC.AGC_CHAR4_VALUE,AGC.AGC_CHAR5_VALUE) CHAR_VALUE_1,
        COALESCE (AGC.AGC_CHAR2_VALUE,AGC.AGC_CHAR3_VALUE,AGC.AGC_CHAR4_VALUE,AGC.AGC_CHAR5_VALUE) CHAR_VALUE_2,
        COALESCE (AGC.AGC_CHAR3_VALUE,AGC.AGC_CHAR4_VALUE,AGC.AGC_CHAR5_VALUE) CHAR_VALUE_3,
        COALESCE (AGC.AGC_CHAR4_VALUE,AGC.AGC_CHAR5_VALUE) CHAR_VALUE_4,
        AGC.AGC_CHAR5_VALUE CHAR_VALUE_5,
        AGC.AGC_BEGIN,
        AGC.AGC_DAYS,
        AGC.AGC_END,
        (SELECT DCOD.GCDTEXT1
          FROM PCS.PC_GCODES DCOD
          WHERE DCOD.GCGNAME = 'C_ASA_GUARANTY_UNIT'
          AND DCOD.GCLCODE = AGC.C_ASA_GUARANTY_UNIT
          AND DCOD.PC_LANG_ID = COALESCE (AGC.PC_ASA_FIN_CUST_LANG_ID,PC_ASA_DISTRIB_LANG_ID,PC_ASA_AGENT_LANG_ID)) C_ASA_GUARANTY_UNIT_DESCR,
        AGC.AGC_SER_PERIODICITY,
        (SELECT DCOD.GCDTEXT1
          FROM PCS.PC_GCODES DCOD
          WHERE DCOD.GCGNAME = 'C_ASA_SERVICE_UNIT'
          AND DCOD.GCLCODE = AGC.C_ASA_SERVICE_UNIT
          AND DCOD.PC_LANG_ID = COALESCE (AGC.PC_ASA_FIN_CUST_LANG_ID,PC_ASA_DISTRIB_LANG_ID,PC_ASA_AGENT_LANG_ID)) C_ASA_SERVICE_UNIT_DESCR,
        AGC.AGC_LAST_SERVICE_DATE,
        AGC.AGC_NEXT_SERVICE_DATE,
        AGC.AGC_MEMO,
        COALESCE (AGC.AGC_SALEDATE,AGC.AGC_SALEDATE_DET,AGC.AGC_SALEDATE_AGENT) SALEDATE,
        COALESCE (AGC.PAC_ASA_FIN_CUST_ID,AGC.PAC_ASA_DISTRIB_ID,AGC.PAC_ASA_AGENT_ID) CUST_ID,
        CASE WHEN (AGC.PAC_ASA_FIN_CUST_ADDR_ID IS NULL) AND (AGC.PAC_ASA_DISTRIB_ADDR_ID IS NULL) THEN
                (SELECT PAC.PER_NAME
                  FROM PAC_PERSON PAC
                  WHERE AGC.PAC_ASA_AGENT_ID = PAC.PAC_PERSON_ID)
             WHEN (AGC.PAC_ASA_FIN_CUST_ADDR_ID IS NULL) AND (AGC.PAC_ASA_DISTRIB_ADDR_ID IS NOT NULL) THEN
                (SELECT PAC.PER_NAME
                  FROM PAC_PERSON PAC
                  WHERE AGC.PAC_ASA_DISTRIB_ID = PAC.PAC_PERSON_ID)
            ELSE
              (SELECT PAC.PER_NAME
                FROM PAC_PERSON PAC
                WHERE AGC.PAC_ASA_FIN_CUST_ID =  PAC.PAC_PERSON_ID)
        END CUST_NAME,
        CASE WHEN (AGC.PAC_ASA_FIN_CUST_ADDR_ID IS NULL) AND (AGC.PAC_ASA_DISTRIB_ADDR_ID IS NULL) THEN
                (SELECT LAN.LANID
                  FROM PCS.PC_LANG LAN
                  WHERE AGC.PC_ASA_AGENT_LANG_ID = LAN.PC_LANG_ID)
             WHEN (AGC.PAC_ASA_FIN_CUST_ADDR_ID IS NULL) AND (AGC.PAC_ASA_DISTRIB_ADDR_ID IS NOT NULL) THEN
                (SELECT LAN.LANID
                  FROM PCS.PC_LANG LAN
                  WHERE AGC.PC_ASA_DISTRIB_LANG_ID = LAN.PC_LANG_ID)
             ELSE
              (SELECT LAN.LANID
                  FROM PCS.PC_LANG LAN
                  WHERE AGC.PC_ASA_FIN_CUST_LANG_ID = LAN.PC_LANG_ID)
        END CUST_LANID,
        CASE WHEN (AGC.PAC_ASA_FIN_CUST_ADDR_ID IS NULL) AND (AGC.PAC_ASA_DISTRIB_ADDR_ID IS NULL) THEN
                AGC.AGC_CARE_OF_AGENT
             WHEN (AGC.PAC_ASA_FIN_CUST_ADDR_ID IS NULL) AND (AGC.PAC_ASA_DISTRIB_ADDR_ID IS NOT NULL) THEN
                AGC.AGC_CARE_OF_DET
             ELSE
                AGC.AGC_CARE_OF_CUST
        END CUST_CARE_OF,
        CASE WHEN (AGC.PAC_ASA_FIN_CUST_ADDR_ID IS NULL) AND (AGC.PAC_ASA_DISTRIB_ADDR_ID IS NULL) THEN
                AGC.AGC_ADDRESS_AGENT
             WHEN (AGC.PAC_ASA_FIN_CUST_ADDR_ID IS NULL) AND (AGC.PAC_ASA_DISTRIB_ADDR_ID IS NOT NULL) THEN
                AGC.AGC_ADDRESS_DISTRIB
             ELSE
                AGC.AGC_ADDRESS_FIN_CUST
        END CUST_ADDRESS,
        CASE WHEN (AGC.PAC_ASA_FIN_CUST_ADDR_ID IS NULL) AND (AGC.PAC_ASA_DISTRIB_ADDR_ID IS NULL) THEN
                AGC.AGC_PO_BOX_AGENT
             WHEN (AGC.PAC_ASA_FIN_CUST_ADDR_ID IS NULL) AND (AGC.PAC_ASA_DISTRIB_ADDR_ID IS NOT NULL) THEN
                AGC.AGC_PO_BOX_DET
             ELSE
                AGC.AGC_PO_BOX_CUST
        END CUST_PO_BOX,
         CASE WHEN (AGC.PAC_ASA_FIN_CUST_ADDR_ID IS NULL) AND (AGC.PAC_ASA_DISTRIB_ADDR_ID IS NULL) THEN
                AGC.AGC_PO_BOX_NBR_AGENT
             WHEN (AGC.PAC_ASA_FIN_CUST_ADDR_ID IS NULL) AND (AGC.PAC_ASA_DISTRIB_ADDR_ID IS NOT NULL) THEN
                AGC.AGC_PO_BOX_NBR_DET
             ELSE
                AGC.AGC_PO_BOX_NBR_CUST
        END CUST_PO_BOX_NBR,
        CASE WHEN (AGC.PAC_ASA_FIN_CUST_ADDR_ID IS NULL) AND (AGC.PAC_ASA_DISTRIB_ADDR_ID IS NULL) THEN
                AGC.AGC_POSTCODE_AGENT
             WHEN (AGC.PAC_ASA_FIN_CUST_ADDR_ID IS NULL) AND (AGC.PAC_ASA_DISTRIB_ADDR_ID IS NOT NULL) THEN
                AGC.AGC_POSTCODE_DISTRIB
             ELSE
                AGC.AGC_POSTCODE_FIN_CUST
        END CUST_POSTCODE,
        CASE WHEN (AGC.PAC_ASA_FIN_CUST_ADDR_ID IS NULL) AND (AGC.PAC_ASA_DISTRIB_ADDR_ID IS NULL) THEN
                AGC.AGC_TOWN_AGENT
             WHEN (AGC.PAC_ASA_FIN_CUST_ADDR_ID IS NULL) AND (AGC.PAC_ASA_DISTRIB_ADDR_ID IS NOT NULL) THEN
                AGC.AGC_TOWN_DISTRIB
             ELSE
                AGC.AGC_TOWN_FIN_CUST
        END CUST_TOWN,
        CASE WHEN (AGC.PAC_ASA_FIN_CUST_ADDR_ID IS NULL) AND (AGC.PAC_ASA_DISTRIB_ADDR_ID IS NULL) THEN
                AGC.AGC_FORMAT_CITY_AGENT
             WHEN (AGC.PAC_ASA_FIN_CUST_ADDR_ID IS NULL) AND (AGC.PAC_ASA_DISTRIB_ADDR_ID IS NOT NULL) THEN
                AGC.AGC_FORMAT_CITY_DISTRIB
             ELSE
                AGC.AGC_FORMAT_CITY_FIN_CUST
        END CUST_FORMAT_CITY,
        CASE WHEN (AGC.PAC_ASA_FIN_CUST_ADDR_ID IS NULL) AND (AGC.PAC_ASA_DISTRIB_ADDR_ID IS NULL) THEN
                AGC.AGC_STATE_AGENT
             WHEN (AGC.PAC_ASA_FIN_CUST_ADDR_ID IS NULL) AND (AGC.PAC_ASA_DISTRIB_ADDR_ID IS NOT NULL) THEN
                AGC.AGC_STATE_DISTRIB
             ELSE
                AGC.AGC_STATE_FIN_CUST
        END CUST_STATE,
        CASE WHEN (AGC.PAC_ASA_FIN_CUST_ADDR_ID IS NULL) AND (AGC.PAC_ASA_DISTRIB_ADDR_ID IS NULL) THEN
                (SELECT CNTNAME
                  FROM PCS.PC_CNTRY CNT
                  WHERE AGC.PC_ASA_AGENT_CNTRY_ID = CNT.PC_CNTRY_ID)
             WHEN (AGC.PAC_ASA_FIN_CUST_ADDR_ID IS NULL) AND (AGC.PAC_ASA_DISTRIB_ADDR_ID IS NOT NULL) THEN
                (SELECT CNTNAME
                  FROM PCS.PC_CNTRY CNT
                  WHERE AGC.PC_ASA_DISTRIB_CNTRY_ID = CNT.PC_CNTRY_ID)
             ELSE
                (SELECT CNTNAME
                  FROM PCS.PC_CNTRY CNT
                  WHERE AGC.PC_ASA_FIN_CUST_CNTRY_ID = CNT.PC_CNTRY_ID)
        END CUST_COUNTRY
      FROM
        ASA_GUARANTY_CARDS AGC,
        GCO_GOOD GCO
      WHERE
        GCO.GCO_GOOD_ID =  AGC.GCO_GOOD_ID AND
        AGC.AGC_NUMBER = PROCPARAM_0;

END RPT_ASA_WARRANTY_CARD;