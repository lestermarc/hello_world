--------------------------------------------------------
--  DDL for Procedure RPT_ASA_INVOICING_EXTRACTION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ASA_INVOICING_EXTRACTION" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       NUMBER
)
IS
/**
* Description - used for the report ASA_INVOICING_EXTRACTION

* @AUTHOR AWU 20 JUL 2009
* @LASTUPDATE
* @VERSION
* @PUBLIC
* @PARAM PROCPARAM_0     ASA_INVOICING_JOB_ID
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT per1.per_name, per1.per_key1, per2.per_name per_name_aci,
             cur.currency, pco.pco_descr, mis.asa_mission_id, mis.mis_number,
             itr.asa_intervention_id, itr.itr_number,
             NVL (itr.itr_description2, itr.itr_description1)
                                                             itr_description,
             goo.goo_major_reference, aid.aid_consumed_quantity,
             aid.aid_invoicing_qty,
             gco_functions.getdescription2 (goo.gco_good_id,
                                            vpc_lang_id,
                                            1,
                                            '01'
                                           ) goo_description,
             goo.dic_unit_of_measure_id, aid.aid_unit_price,
             itr.c_asa_itr_status, mit.mit_code
        FROM asa_invoicing_process aip,
             pac_person per1,
             pac_person per2,
             acs_financial_currency acs,
             pcs.pc_curr cur,
             pac_payment_condition pco,
             asa_mission mis,
             asa_intervention itr,
             asa_intervention_detail aid,
             gco_good goo,
             asa_mission_type mit
       WHERE aip.pac_custom_partner_id = per1.pac_person_id(+)
         AND aip.pac_custom_partner_aci_id = per2.pac_person_id(+)
         AND aip.acs_financial_currency_id = acs.acs_financial_currency_id(+)
         AND acs.pc_curr_id = cur.pc_curr_id
         AND aip.pac_payment_condition_id = pco.pac_payment_condition_id(+)
         AND aip.asa_mission_id = mis.asa_mission_id(+)
         AND aip.asa_intervention_id = itr.asa_intervention_id(+)
         AND aip.asa_intervention_detail_id = aid.asa_intervention_detail_id(+)
         AND NVL (aid.gco_service_id, aid.gco_good_id) = goo.gco_good_id(+)
         AND mis.asa_mission_type_id = mit.asa_mission_type_id(+)
         AND aip.doc_position_id IS NULL
         AND aip.aip_selection = 1
         AND aip.asa_invoicing_job_id = parameter_0;
END rpt_asa_invoicing_extraction;
