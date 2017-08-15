--------------------------------------------------------
--  DDL for Procedure RPT_CML_INVOICING_EXTRACTION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_CML_INVOICING_EXTRACTION" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0      IN       NUMBER,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS
/**
* Description - used for the report CML_INVOICING_EXTRACTION

* @CREATED IN PROCONCEPT CHINA
* @AUTHOR MZHU 01 DEC 2006
* @LASTUPDATE  24 FEB 2009
* @VERSION
* @PUBLIC
* @PARAM PROCPARAM_0     CML_INVOICING_JOB.CML_INVOICING_JOB_ID
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT   inp.inp_selection, inp.pac_custom_partner_id, per.per_name,
               per.per_key1,
               (SELECT per_name
                  FROM pac_person per_aci
                 WHERE per_aci.pac_person_id =
                          NVL (inp.pac_custom_partner_aci_id,
                               inp.pac_custom_partner_id
                              )) per_name_aci,
               cco.cco_number, cco.cco_description, cpo.cpo_sequence,
               cpo.cpo_description, cpo.c_cml_pos_type,
               com_functions.getdescodedescr
                                    ('C_CML_POS_TYPE',
                                     cpo.c_cml_pos_type,
                                     vpc_lang_id
                                    ) c_cml_pos_type_descr,
               cpo.c_cml_pos_status,
               com_functions.getdescodedescr
                                ('C_CML_POS_STATUS',
                                 cpo.c_cml_pos_status,
                                 vpc_lang_id
                                ) c_cml_pos_status_descr,
               cpo.cpo_init_period_price, cpo.cpo_extend_period_price,
               CASE
                  WHEN inp.c_invoicing_process_type =
                                            'FIXEDPRICE'
                     THEN cpo.cpo_bill_text
                  WHEN inp.c_invoicing_process_type =
                                                'EVENTS'
                     THEN cev.cev_text
                  WHEN inp.c_invoicing_process_type =
                                               'DEPOSIT'
                     THEN cpo.cpo_depot_text
                  WHEN inp.c_invoicing_process_type =
                                              'PENALITY'
                     THEN cpo.cpo_penality_text
               END pos_free_description,
               cev.cev_sequence, cev.cml_position_service_detail_id,
               ctt.ctt_descr, ctt.dic_asa_unit_of_measure_id,
               (SELECT des.dit_descr
                  FROM dico_description des
                 WHERE des.dit_code =
                          ctt.dic_asa_unit_of_measure_id
                   AND des.dit_table = 'DIC_UNIT_OF_MEASURE'
                   AND des.pc_lang_id = vpc_lang_id)
                                               dic_asa_unit_of_measure_descr,
               cur.currency, pco.pco_descr, inp.c_invoicing_process_type,
               com_functions.getdescodedescr
                     ('C_INVOICING_PROCESS_TYPE',
                      inp.c_invoicing_process_type,
                      vpc_lang_id
                     ) c_invoicing_process_descr,
               inp.cml_document_id, cou.cou_comment,
               inp.inp_begin_period_date, inp.inp_end_period_date,
               inp.inp_amount, inp.inp_counter_begin_qty,
               inp.inp_counter_end_qty, inp.inp_free_qty,
               inp.inp_gross_consumed_qty, inp.inp_net_consumed_qty,
               inp.inp_balance_qty, inp.inp_invoicing_qty,
               cpd.cpd_unit_value, cmd.cmd_last_invoice_statement,
               cmd.cmd_initial_statement, cpm.cpm_weight, rco_inst.rco_title,
               goo.goo_major_reference, inp.inp_regroup_id
                                                          --, SUM(INP_AMOUNT) OVER (PARTITION BY INP_REGROUP_ID) SUM_INP_AMOUNT
               ,
               SUM (inp_amount) OVER (PARTITION BY per.per_key1, cco.cco_number, cpo.cpo_sequence, inp.c_invoicing_process_type)
                                                              sum_inp_amount
          FROM cml_invoicing_process inp,
               cml_invoicing_job inj,
               pac_person per,
               acs_financial_currency fin,
               pcs.pc_curr cur,
               pac_payment_condition pco,
               cml_document cco,
               cml_position cpo,
               cml_events cev,
               asa_counter_statement cst,
               asa_counter cou,
               asa_counter_type ctt,
               cml_position_service_detail cpd,
               cml_position_machine_detail cmd,
               cml_position_machine cpm,
               doc_record rco_inst,
               gco_good goo
         WHERE inp.cml_invoicing_job_id = inj.cml_invoicing_job_id
           AND inp.cml_invoicing_job_id = parameter_0
           AND inp.cml_events_id = cev.cml_events_id(+)
           AND cev.cml_events_id = cst.cml_events_id(+)
           AND cst.asa_counter_id = cou.asa_counter_id(+)
           AND cou.asa_counter_type_id = ctt.asa_counter_type_id(+)
           AND cev.cml_position_service_detail_id = cpd.cml_position_service_detail_id(+)
           AND cev.cml_position_machine_detail_id = cmd.cml_position_machine_detail_id(+)
           AND cmd.cml_position_machine_id = cpm.cml_position_machine_id(+)
           AND cpm.doc_rco_machine_id = rco_inst.doc_record_id(+)
           AND rco_inst.rco_machine_good_id = goo.gco_good_id(+)
           AND inp.doc_position_id IS NULL
           AND per.pac_person_id = inp.pac_custom_partner_id
           AND inp.cml_position_id = cpo.cml_position_id
           AND cpo.cml_document_id = cco.cml_document_id
           AND inp.acs_financial_currency_id = fin.acs_financial_currency_id
           AND fin.pc_curr_id = cur.pc_curr_id
           AND per.pac_person_id = inp.pac_custom_partner_id
           AND inp.pac_payment_condition_id = pco.pac_payment_condition_id(+)
           AND inp.inp_selection = 1
      ORDER BY inp.inp_order_by;
END rpt_cml_invoicing_extraction;
