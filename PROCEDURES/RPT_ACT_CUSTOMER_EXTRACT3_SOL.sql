--------------------------------------------------------
--  DDL for Procedure RPT_ACT_CUSTOMER_EXTRACT3_SOL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_CUSTOMER_EXTRACT3_SOL" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0      IN       VARCHAR2,
   parameter_1      IN       NUMBER,
   parameter_2      IN       NUMBER,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS

/**
* description used for report  ACT_CUSTOMER_EXTRACT3  (SI - rupture par no abonnement)

* @author PYB
* @lastupdate 24 jun 2010
* @Update
* @public
* @param PROCPARAM_0    customer id         ACC_NUMBER (AUXILIARY_ACCOUNT_ID)
* @param PROCPARAM_1                        DATE (20060101)
* @param PROCPARAM_2    Imf_number2         NO ABONNEMENT


*/
BEGIN

   DELETE FROM COM_LIST_ID_TEMP  WHERE LID_CODE = 'ACS_FINANCIAL_YEAR_ID';

   DELETE FROM COM_LIST_ID_TEMP  WHERE LID_CODE = 'MAIN_ID';

   INSERT INTO COM_LIST_ID_TEMP  (COM_LIST_ID_TEMP_ID, LID_FREE_NUMBER_1, LID_CODE)
   VALUES (INIT_ID_SEQ.NEXTVAL, parameter_0, 'MAIN_ID');

   INSERT INTO COM_LIST_ID_TEMP  (COM_LIST_ID_TEMP_ID, LID_CODE, LID_FREE_NUMBER_2)
   SELECT INIT_ID_SEQ.NEXTVAL, 'ACS_FINANCIAL_YEAR_ID', ACS_FINANCIAL_YEAR_ID FROM ACS_FINANCIAL_YEAR;


   OPEN arefcursor FOR
   select imf_amount_lc_d, imf_amount_lc_c, IMF_NUMBER2
   from  V_ACR_REC_IMPUTATION_ISAG
   WHERE c_type_catalogue <> '7' and
       (IMF_NUMBER2 = parameter_2 or (imf_number2 is null and parameter_2 = 0))
   AND TO_NUMBER(TO_cHAR(IMF_TRANSACTION_DATE,'YYYYMMDD')) < PARAMETER_1;

END rpt_act_customer_extract3_sol;
