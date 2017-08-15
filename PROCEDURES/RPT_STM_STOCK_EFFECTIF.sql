--------------------------------------------------------
--  DDL for Procedure RPT_STM_STOCK_EFFECTIF
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_STM_STOCK_EFFECTIF" (
   AREFCURSOR    IN OUT   CRYSTAL_CURSOR_TYPES.DUALCURSORTYP,
   PROCPARAM_0   IN       VARCHAR2,
   PROCPARAM_1   IN       VARCHAR2,
   PROCPARAM_2   IN       VARCHAR2,
   PROCPARAM_3   IN       VARCHAR2,
   PROCPARAM_4   IN       VARCHAR2,
   PROCPARAM_5   IN       VARCHAR2,
   PROCPARAM_6   IN       VARCHAR2,
   USER_LANID    IN       PCS.PC_LANG.LANID%TYPE
)
IS
/**
*Description USED FOR REPORT STM_STOCK_EFFECTIF_VALORISED_DET
* @CREATED IN PROCONCEPT CHINA
* @AUTHOR MZH 21 Feb 2009
* @LASTUPDATE VHA 8 Sept 2011
* @PUBLIC
* @PARAM PROCPARAM_0     Mode de Prix  (0: Mode de gestion, 1: PRCS, 2 PRC, 3: PRF, 4: prix dernier mouvement)
* @PARAM PROCPARAM_1    Code famille de bien (DIC_GOOD_FAMILY_ID)
* @PARAM PROCPARAM_2    Code groupe de bien (DIC_GOOD_GROUP_ID)
* @PARAM PROCPARAM_3    Code ligne de bien (DIC_GOOD_LINE_ID)
* @PARAM PROCPARAM_4    Code modèle de bien (DIC_GOOD_MODEL_ID)
* @PARAM PROCPARAM_5    Sélection par bien (GOO_MAJOR_REFERENCE)
* @PARAM PROCPARAM_6    Sélection par stock (STO_DESCRIPTION)
* @PARAM USER_LANID     User language
*/

   VPC_LANG_ID   PCS.PC_LANG.PC_LANG_ID%TYPE;

BEGIN
   PCS.PC_I_LIB_SESSION.SETLANID (USER_LANID);
   VPC_LANG_ID := PCS.PC_I_LIB_SESSION.GETUSERLANGID;

   OPEN AREFCURSOR FOR
      SELECT GOO.GCO_GOOD_ID,
                  GOO.GOO_MAJOR_REFERENCE,
                  GOO.GOO_NUMBER_OF_DECIMAL,
                  GOO.C_MANAGEMENT_MODE,
                  NVL (GOO.DIC_GOOD_FAMILY_ID,
                  PCS.PC_FUNCTIONS.TRANSLATEWORD2 ('Vide', VPC_LANG_ID)) DIC_GOOD_FAMILY_ID,
                  NVL (FAM.DIC_GOOD_FAMILY_WORDING,
                  PCS.PC_FUNCTIONS.TRANSLATEWORD2 ('Pas de famille produit', VPC_LANG_ID)) DIC_GOOD_FAMILY_WORDING,
                  DES.DES_SHORT_DESCRIPTION,
                  DES.DES_LONG_DESCRIPTION,
                  DES.DES_FREE_DESCRIPTION,
                  STO.STO_DESCRIPTION,
                  LOC.LOC_DESCRIPTION,
                  SPO.SPO_STOCK_QUANTITY,
                  (GCO_FUNCTIONS.GETCOSTPRICEWITHMANAGEMENTMODE(GOO.GCO_GOOD_ID,NULL,DECODE (PROCPARAM_0, '0', GOO.C_MANAGEMENT_MODE, PROCPARAM_0))) PRICE
        FROM STM_STOCK_POSITION SPO,
                  GCO_GOOD GOO,
                  STM_STOCK STO,
                  DIC_GOOD_FAMILY FAM,
                  STM_LOCATION LOC,
                  (SELECT   GCO_GOOD_ID, DES_SHORT_DESCRIPTION, DES_LONG_DESCRIPTION, DES_FREE_DESCRIPTION
                    FROM     GCO_DESCRIPTION
                    WHERE   PC_LANG_ID = VPC_LANG_ID AND C_DESCRIPTION_TYPE = '01') DES
        WHERE SPO.GCO_GOOD_ID = GOO.GCO_GOOD_ID
            AND  SPO.STM_STOCK_ID = STO.STM_STOCK_ID
            AND  SPO.STM_LOCATION_ID = LOC.STM_LOCATION_ID
            AND  GOO.GCO_GOOD_ID = DES.GCO_GOOD_ID(+)
            AND  GOO.DIC_GOOD_FAMILY_ID = FAM.DIC_GOOD_FAMILY_ID(+)
            AND  (
                        ((PROCPARAM_1 IS NOT NULL) AND  (GOO.DIC_GOOD_FAMILY_ID LIKE PCS.LIKE_PARAM_FS(PROCPARAM_1))) OR
                        ((PROCPARAM_1 IS NULL))
                   )
            AND  (
                        ((PROCPARAM_2 IS NOT NULL) AND  (GOO.DIC_GOOD_GROUP_ID LIKE PCS.LIKE_PARAM_FS(PROCPARAM_2))) OR
                        ((PROCPARAM_2 IS NULL))
                   )
            AND  (
                        ((PROCPARAM_3 IS NOT NULL) AND  (GOO.DIC_GOOD_LINE_ID LIKE PCS.LIKE_PARAM_FS(PROCPARAM_3))) OR
                        ((PROCPARAM_3 IS NULL))
                   )
            AND  (
                        ((PROCPARAM_4 IS NOT NULL) AND  (GOO.DIC_GOOD_MODEL_ID LIKE PCS.LIKE_PARAM_FS(PROCPARAM_4))) OR
                        ((PROCPARAM_4 IS NULL))
                   )
            AND  (
                        ((PROCPARAM_5 IS NOT NULL) AND  (GOO.GOO_MAJOR_REFERENCE LIKE PCS.LIKE_PARAM_FS(PROCPARAM_5))) OR
                        ((PROCPARAM_5 IS NULL))
                   )
            AND  (
                        ((PROCPARAM_6 IS NOT NULL) AND  (STO.STO_DESCRIPTION LIKE PCS.LIKE_PARAM_FS(PROCPARAM_6))) OR
                        ((PROCPARAM_6 IS NULL))
                   )
;
END RPT_STM_STOCK_EFFECTIF;
