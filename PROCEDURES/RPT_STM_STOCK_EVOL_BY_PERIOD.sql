--------------------------------------------------------
--  DDL for Procedure RPT_STM_STOCK_EVOL_BY_PERIOD
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_STM_STOCK_EVOL_BY_PERIOD" (
   AREFCURSOR    IN OUT   CRYSTAL_CURSOR_TYPES.DUALCURSORTYP,
   PROCPARAM_0       IN      VARCHAR2,
   PROCPARAM_1       IN      VARCHAR2,
   PROCPARAM_2       IN      VARCHAR2,
   PROCPARAM_3       IN      VARCHAR2,
   PROCPARAM_4       IN      VARCHAR2,
   PROCUSER_LANID   IN      PCS.PC_LANG.LANID%TYPE
)
IS

/**
*Description USED FOR REPORT RPT_STM_STOCK_EVOLUTION_BY_PERIOD
* @AUTHOR VHA 12.09.2011
* @LASTUPDATE
* @PUBLIC
* @PARAM PROCPARAM_0           Start date (YYYYMMDD)
* @PARAM PROCPARAM_1           End date (YYYYMMDD)
* @PARAM PROCPARAM_2          S�lection par bien (GOO_MAJOR_REFERENCE)
* @PARAM PROCPARAM_3          S�lection par stock (STO_DESCRIPTION)
* @PARAM PROCPARAM_4          S�lection par emplacement (LOC_DESCRIPTION)

* @PARAM PROCUSER_LANID      USER LANGUAGE
*/

   VPC_LANG_ID               PCS.PC_LANG.PC_LANG_ID%TYPE;

BEGIN
   PCS.PC_I_LIB_SESSION.SETLANID (PROCUSER_LANID);
   VPC_LANG_ID := PCS.PC_I_LIB_SESSION.GETUSERLANGID;

   OPEN AREFCURSOR FOR
    SELECT GOO.GOO_MAJOR_REFERENCE,
                (SELECT   DES.DES_SHORT_DESCRIPTION
                    FROM   GCO_DESCRIPTION DES
                    WHERE DES.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                        AND DES.PC_LANG_ID = VPC_LANG_ID
                        AND C_DESCRIPTION_TYPE ='01') SHORT_DESCRIPTION,
                SEV.SPE_START_QUANTITY,
                SEV.SPE_INPUT_QUANTITY,
                SEV.SPE_OUTPUT_QUANTITY,
                SEV.SPE_START_QUANTITY + (SPE_INPUT_QUANTITY - SPE_OUTPUT_QUANTITY) BALANCE_QUANTITY,
                SEV.SPE_START_VALUE,
                SEV.SPE_INPUT_VALUE,
                SEV.SPE_OUTPUT_VALUE,
                SEV.SPE_START_VALUE + (SPE_INPUT_VALUE-SPE_OUTPUT_VALUE) BALANCE_VALUE,
                SPE.PER_STARTING_PERIOD,
                SPE.PER_ENDING_PERIOD,
                STO.STO_DESCRIPTION,
                LOC.LOC_DESCRIPTION
    FROM   STM_EXERCISE_EVOLUTION SEV,
                GCO_GOOD GOO,
                STM_STOCK STO,
                STM_LOCATION LOC,
                STM_PERIOD SPE
    WHERE  SEV.GCO_GOOD_ID = GOO.GCO_GOOD_ID
        AND  SEV.STM_STOCK_ID = STO.STM_STOCK_ID
        AND  SEV.STM_PERIOD_ID = SPE.STM_PERIOD_ID
        AND  LOC.STM_STOCK_ID = STO.STM_STOCK_ID
        AND  SPE.PER_STARTING_PERIOD >= COALESCE(TO_DATE (PROCPARAM_0,'YYYYMMDD'), SPE.PER_STARTING_PERIOD)
        AND  SPE.PER_ENDING_PERIOD <= COALESCE(TO_DATE (PROCPARAM_1,'YYYYMMDD'), SPE.PER_ENDING_PERIOD)
        AND  (
                      ((PROCPARAM_2 IS NOT NULL) AND  (GOO.GOO_MAJOR_REFERENCE LIKE PCS.LIKE_PARAM_FS(PROCPARAM_2))) OR
                      ((PROCPARAM_2 IS NULL))
                )
        AND  (
                      ((PROCPARAM_3 IS NOT NULL) AND  (STO.STO_DESCRIPTION LIKE PCS.LIKE_PARAM_FS(PROCPARAM_3))) OR
                      ((PROCPARAM_3 IS NULL))
                )
        AND  (
                      ((PROCPARAM_4 IS NOT NULL) AND  (LOC.LOC_DESCRIPTION LIKE PCS.LIKE_PARAM_FS(PROCPARAM_4))) OR
                      ((PROCPARAM_4 IS NULL))
                )
;

END RPT_STM_STOCK_EVOL_BY_PERIOD;