--------------------------------------------------------
--  DDL for Procedure RPT_ACT_CUSTOMER_EXTRACT3_OE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_CUSTOMER_EXTRACT3_OE" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0      IN       VARCHAR2,
   parameter_1      IN       VARCHAR2
)
IS

/**
* description used for report  ACT_CUSTOMER_EXTRACT3  (SI - rupture par no abonnement)

* @author PYB
* @lastupdate 11 jun 2010
* @Update
* @public
* @param PROCPARAM_0    customer id         ACC_NUMBER (AUXILIARY_ACCOUNT_ID)
* @param PROCPARAM_1                        DATE for the open entries
*/

 v_date   varchar2 (20);

BEGIN

   v_date := substr(parameter_1,7,4) || substr(parameter_1,4,2)  || substr(parameter_1,1,2);

   DELETE FROM COM_LIST_ID_TEMP  WHERE LID_CODE = 'MAIN_ID';

   INSERT INTO COM_LIST_ID_TEMP  (COM_LIST_ID_TEMP_ID, LID_FREE_NUMBER_1, LID_CODE)
   VALUES (INIT_ID_SEQ.NEXTVAL, parameter_0, 'MAIN_ID');


   ACT_FUNCTIONS.SETANALYSE_PARAMETERS   (v_date, '', '', 1);

   OPEN arefcursor FOR
   select *
   from  V_ACR_EXPIRY_CUST_ISAG;




END rpt_act_customer_extract3_oe;
