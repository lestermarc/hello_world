--------------------------------------------------------
--  DDL for Procedure RPT_ACT_CUSTOMER_EXTRACT3
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_CUSTOMER_EXTRACT3" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0      IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS
/**
* description used for report  ACT_CUSTOMER_EXTRACT3  (SI - rupture par no abonnement)

* @author PYB
* @lastupdate 16 jun 2010
* @Update
* @public
* @param PROCPARAM_0    customer id         ACC_NUMBER (AUXILIARY_ACCOUNT_ID)

*/

 vcurrency     PCS.PC_CURR.CURRENCY%Type;

BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);

   select currency into vcurrency
   from pcs.pc_curr cur, acs_financial_currency acr
   where acr.fin_local_currency = '1'
   AND acr.pc_curr_id = cur.pc_curr_id;

   DELETE FROM com_list_id_temp
         WHERE lid_code = 'ACS_FINANCIAL_YEAR_ID';

   DELETE FROM com_list_id_temp
         WHERE lid_code = 'MAIN_ID';

   INSERT INTO com_list_id_temp
               (com_list_id_temp_id, lid_free_number_1, lid_code
               )
        VALUES (init_id_seq.NEXTVAL, parameter_0, 'MAIN_ID'
               );

   INSERT INTO com_list_id_temp
               (com_list_id_temp_id, lid_code, lid_free_number_2)
      SELECT init_id_seq.NEXTVAL, 'ACS_FINANCIAL_YEAR_ID',
             acs_financial_year_id
        FROM acs_financial_year;

   OPEN arefcursor FOR
      SELECT
             ( select nvl(com_city,'') from pcs.pc_comp where pc_comp_id = pcs.PC_public.GetCompanyId ) com_city,
             isa.*, per.per_forename, per.per_name, adr.add_address1,
             POL.DPO_DESCR,
             adr.add_format, acc.acc_number,
             vcurrency currency
        FROM v_acr_rec_imputation_isag isa,
             act_part_imputation imp,
             pac_person per,
             dic_person_politness pol,
             pac_address adr,
             acs_account acc
       WHERE isa.act_part_imputation_id = imp.act_part_imputation_id
         AND imp.pac_custom_partner_id = per.pac_person_id
         AND isa.acs_auxiliary_account_id = acc.acs_account_id
         AND per.pac_person_id = adr.pac_person_id(+)
         AND adr.add_principal(+) = 1
         AND per.dic_person_politness_id = pol.dic_person_politness_id(+)
         AND c_type_catalogue <> '7';
END rpt_act_customer_extract3;
