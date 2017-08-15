--------------------------------------------------------
--  DDL for Procedure RPT_STM_STOCK_EVOL_BY_YEAR
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_STM_STOCK_EVOL_BY_YEAR" (
   AREFCURSOR    IN OUT     CRYSTAL_CURSOR_TYPES.DUALCURSORTYP,
   PROCPARAM_0     IN       VARCHAR2,
   PROCPARAM_1     IN       VARCHAR2,
   PROCPARAM_2     IN       VARCHAR2,
   PROCPARAM_3     IN       VARCHAR2,
   PROCUSER_LANID   IN      PCS.PC_LANG.LANID%TYPE
)
IS

/**
*Description USED FOR REPORT RPT_STM_STOCK_EVOLUTION_BY_YEAR
* @AUTHOR VHA 07.09.2011
* @LASTUPDATE SMA 26.08.2013
* @PUBLIC
* @PARAM PROCPARAM_0          Année (SAE_YEAR)
* @PARAM PROCPARAM_1          Sélection par bien (GOO_MAJOR_REFERENCE)
* @PARAM PROCPARAM_2          Sélection par stock (STO_DESCRIPTION)
* @PARAM PROCPARAM_3          Sélection par emplacement (LOC_DESCRIPTION)
* @PARAM PROCUSER_LANID      USER LANGUAGE
*/

   VPC_LANG_ID              PCS.PC_LANG.PC_LANG_ID%TYPE;

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
                SAV.SAE_START_QUANTITY,
                SAV.SAE_INPUT_QUANTITY,
                SAV.SAE_OUTPUT_QUANTITY,
                SAV.SAE_START_QUANTITY + (SAE_INPUT_QUANTITY - SAE_OUTPUT_QUANTITY) BALANCE_QUANTITY,
                SAV.SAE_START_VALUE,
                SAV.SAE_INPUT_VALUE,
                SAV.SAE_OUTPUT_VALUE,
                SAV.SAE_START_VALUE + (SAE_INPUT_VALUE - SAE_OUTPUT_VALUE) BALANCE_VALUE,
                CAST(SAV.SAE_YEAR AS varchar2(4)) SAE_YEAR,      -- Forcer le type de la valeur (web)
                STO.STO_DESCRIPTION,
                LOC.LOC_DESCRIPTION
    FROM   STM_ANNUAL_EVOLUTION SAV,
                GCO_GOOD GOO,
                STM_STOCK STO,
                STM_LOCATION LOC
    WHERE  SAV.GCO_GOOD_ID = GOO.GCO_GOOD_ID
        AND  SAV.STM_STOCK_ID = STO.STM_STOCK_ID
        AND  LOC.STM_STOCK_ID = STO.STM_STOCK_ID
        AND  SAV.SAE_YEAR  = COALESCE(PROCPARAM_0, SAV.SAE_YEAR)
            AND  (
                        ((PROCPARAM_1 IS NOT NULL) AND  (GOO.GOO_MAJOR_REFERENCE LIKE PCS.LIKE_PARAM_FS(PROCPARAM_1))) OR
                        ((PROCPARAM_1 IS NULL))
                   )
            AND  (
                        ((PROCPARAM_2 IS NOT NULL) AND  (STO.STO_DESCRIPTION LIKE PCS.LIKE_PARAM_FS(PROCPARAM_2))) OR
                        ((PROCPARAM_2 IS NULL))
                   )
            AND  (
                        ((PROCPARAM_3 IS NOT NULL) AND  (LOC.LOC_DESCRIPTION LIKE PCS.LIKE_PARAM_FS(PROCPARAM_3))) OR
                        ((PROCPARAM_3 IS NULL))
                   )
;

END RPT_STM_STOCK_EVOL_BY_YEAR;
