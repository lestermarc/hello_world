--------------------------------------------------------
--  DDL for Procedure RPT_ASA_MISSION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ASA_MISSION" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       VARCHAR2,
   parameter_1      IN       VARCHAR2,
   parameter_2      IN       VARCHAR2,
   parameter_3      IN       VARCHAR2,
   parameter_4      IN       VARCHAR2,
   parameter_5      IN       VARCHAR2,
   parameter_6      IN       VARCHAR2,
   parameter_7      IN       VARCHAR2,
   parameter_8      IN       VARCHAR2
)
IS
/*
* Description stored procedure used for the report ASA_MISSION_DET

* @created awu 01 nov 2008
* @lastupdate  15 feb 2010
* @public
* @param PARAMETER_0: ASA_MISSION_ID
* @param PARAMETER_1: ASA_INTERVENTION_ID
* @param PARAMETER_2: Printing all customer 0:no, 1:yes
* @param PARAMETER_3: COM_LIST.LIS_JOB_ID only if parameter_2 is 0
* @param PARAMETER_4: Date from
* @param PARAMETER_5: Date to
* @param PARAMETER_6: Customer option 0:invoiced custom 1:sold to party
* @param PARAMETER_7: status of mission
* @param PARAMETER_8: Detail 0:no 1:yes
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT ams.mis_number, ams.c_asa_mis_status          /*Mission_Status*/
             ,amt.mit_code                                    /*Mission_Type*/
             ,ams.mis_accomplished                               /*Completed*/
             ,com_dic_functions.getdicodescr
                  ('DIC_ASA_MIS_DEMAND_KIND',
                   ams.dic_asa_mis_demand_kind_id,
                   vpc_lang_id
                  ) dic_asa_mis_demand_kind_id          /*Severity_Criteria*/
             ,com_dic_functions.getdicodescr
                      ('DIC_ASA_MIS_EMERGENCY',
                       ams.dic_asa_mis_emergency_id,
                       vpc_lang_id
                      ) dic_asa_mis_emergency_id             /*Request_Type*/
             ,rco1.rco_title files                                   /*Files*/
             ,ddm.dmt_number                               /*Linked_Document*/
             ,ams.mis_description                              /*Description*/
             ,ams.mis_comment                                     /*Comments*/
             ,pps.per_name                                        /*Customer*/
             ,rpt_functions.getpacadr (ams.pac_custom_partner_id,
                                      0
                                     ) add_address1
                                                   /*Address*/
             ,rpt_functions.getpacadr (ams.pac_custom_partner_id,
                                      1
                                     ) add_zipcode
                                                  /*ZIPCODE*/
             ,rpt_functions.getpacadr (ams.pac_custom_partner_id, 2) add_city     /*CITY*/
             ,ams.mis_location_comment1                 /*Locality_comments1*/
             ,ams.mis_location_comment2                 /*Locality_comments2*/
             ,pdp.dep_key                                       /*Department*/
             ,rco2.rco_title installation                          /*Install*/
             ,act.ctt_key                                          /*Counter*/
             ,gsp.dic_service_type_id                         /*Service_plan*/
             ,ams.mis_service_marker                         /*Service_maker*/
             ,per1.per_fullname per_fullname_ast               /*Assigned_to*/
             ,usr.use_name                                     /*Assigned_by*/
             ,ams.mis_request_date                            /*Request_date*/
             ,ams.mis_allocation_date                      /*Assignment_date*/
             ,ams.mis_completion_date                      /*Completion_date*/
             ,per2.per_fullname per_fullname_ilt              /*Interlocutor*/
             ,v.asa_intervention_id                        /*INTERVENTION_ID*/
             ,v.goo_major_reference                   /*Services or Products*/
             ,v.short_description                        /*Short description*/
             ,v.service_product               /*Services or Products Boolean*/
             ,v.itr_number                             /*Intervention Number*/
             ,v.dic_asa_itr_kind_id                     /*Service visit type*/
             ,v.itr_expected_date                            /*Expected date*/
             ,v.itr_start_date                                  /*Start date*/
             ,v.itr_end_date                                      /*End date*/
             ,v.itr_accomplished                             /*Completed_ITR*/
             ,v.itr_description1                      /*Internal Description*/
             ,v.itr_description2                      /*External Description*/
             ,v.itr_period                                        /*Duration*/
             ,v.aid_cost_price                                  /*Cost price*/
             ,v.aid_unit_price                                  /*Unit price*/
             ,v.aid_taken_quantity                 /*Standard Qty(Qty taken)*/
             ,v.aid_consumed_quantity             /*Actual Qty(Qty consumed)*/
             ,v.aid_returned_quantity                         /*Returned Qty*/
             ,v.aid_kept_quantity                                 /*Kept Qty*/
             ,v.aid_exchange                                      /*Exchange*/
             ,v.goo_exchange                                 /*Exchange Good*/
             ,v.description_exchange   /*Short description for exchange good*/
             ,v.aid_exch_cost_price               /*Exchange good cost price*/
             ,v.aid_invoicing_qty                            /*Invoicing Qty*/
             ,v.aid_guaranty                                      /*Warranty*/
             ,des.gcdtext1 itr_status                               /*Status*/
             ,v.AID_CHAR1_VALUE
             ,v.AID_CHAR2_VALUE
             ,v.AID_CHAR3_VALUE
             ,v.AID_CHAR4_VALUE
             ,v.AID_CHAR5_VALUE
             ,v.AID_EXCH_CHAR1_VALUE
             ,v.AID_EXCH_CHAR2_VALUE
             ,v.AID_EXCH_CHAR3_VALUE
             ,v.AID_EXCH_CHAR4_VALUE
             ,v.AID_EXCH_CHAR5_VALUE
        FROM asa_mission ams,
             asa_mission_type amt,
             doc_document ddm,
             pac_person pps,
             pac_department pdp,
             asa_counter cou,
             asa_counter_type act,
             gco_service_plan gsp,
             doc_record rco1,
             doc_record rco2,
             hrm_person per1,
             hrm_person per2,
             pcs.pc_user usr,
             (SELECT itr.asa_intervention_id, itr.asa_mission_id,
                     itr.c_asa_itr_status, itr.itr_number,
                     itr.dic_asa_itr_kind_id, itr.itr_expected_date,
                     itr.itr_start_date, itr.itr_end_date,
                     itr.itr_accomplished, itr.itr_description1,
                     itr.itr_description2, itr.itr_period, itr.itr_person_id,
                     aid.aid_cost_price, aid.aid_unit_price,
                     aid.aid_taken_quantity, aid.aid_consumed_quantity,
                     aid.aid_returned_quantity, aid.aid_kept_quantity,
                     aid.aid_exchange, aid.aid_exch_cost_price,
                     aid.aid_invoicing_qty, aid.aid_guaranty, aid.gco_good_id,
                     aid.gco_service_id, aid.gco_good_exch_id,
                     DECODE (aid.gco_good_id,
                             NULL, 'S',
                             'P'
                            ) service_product, goo.goo_major_reference,
                     gco_functions.getdescription2
                                          (goo.gco_good_id,
                                           vpc_lang_id,
                                           1,
                                           '01'
                                          ) short_description,
                     goo_exc.goo_major_reference goo_exchange,
                     gco_functions.getdescription2
                                   (goo_exc.gco_good_id,
                                    vpc_lang_id,
                                    1,
                                    '01'
                                   ) description_exchange,
                     AID.AID_CHAR1_VALUE,
                     AID.AID_CHAR2_VALUE,
                     AID.AID_CHAR3_VALUE,
                     AID.AID_CHAR4_VALUE,
                     AID.AID_CHAR5_VALUE,
                     AID.AID_EXCH_CHAR1_VALUE,
                     AID.AID_EXCH_CHAR2_VALUE,
                     AID.AID_EXCH_CHAR3_VALUE,
                     AID.AID_EXCH_CHAR4_VALUE,
                     AID.AID_EXCH_CHAR5_VALUE
                FROM asa_intervention itr,
                     asa_intervention_detail aid,
                     gco_good goo,
                     gco_good goo_exc
               WHERE itr.asa_intervention_id = aid.asa_intervention_id(+)
                 AND NVL (aid.gco_good_id, aid.gco_service_id) = goo.gco_good_id(+)
                 AND aid.gco_good_exch_id = goo_exc.gco_good_id(+)
                 AND (   itr.asa_intervention_id = TO_NUMBER (parameter_1)
                      OR TO_NUMBER (parameter_1) = 0
                     )) v,
             (SELECT gclcode, gcdtext1
                FROM pcs.v_pc_descodes des
               WHERE gcgname = 'C_ASA_ITR_STATUS' AND pc_lang_id = vpc_lang_id) des
       WHERE ams.asa_mission_type_id = amt.asa_mission_type_id(+)
         AND ams.mis_document_id = ddm.doc_document_id(+)
         AND ams.pac_custom_partner_id = pps.pac_person_id(+)
         AND ams.pac_department_id = pdp.pac_department_id(+)
         AND ams.asa_counter_id = cou.asa_counter_id(+)
         AND cou.asa_counter_type_id = act.asa_counter_type_id(+)
         AND ams.gco_service_plan_id = gsp.gco_service_plan_id(+)
         AND ams.asa_mission_id = v.asa_mission_id(+)
         AND v.c_asa_itr_status = des.gclcode(+)
         AND ams.doc_record_id = rco1.doc_record_id(+)
         AND ams.asa_machine_id = rco2.doc_record_id(+)
         AND ams.mis_responsible_person_id = per1.hrm_person_id(+)
         AND v.itr_person_id = per2.hrm_person_id(+)
         AND ams.mis_pc_user_id = usr.pc_user_id(+)
         AND (ams.asa_mission_id = TO_NUMBER (parameter_0)
              OR parameter_0 = '0'
             )
         AND (   TRUNC (ams.mis_request_date) >=
                                             TO_DATE (parameter_4, 'YYYYMMDD')
              OR parameter_4 IS NULL
             )
         AND (   TRUNC (ams.mis_request_date) <=
                                             TO_DATE (parameter_5, 'YYYYMMDD')
              OR parameter_5 IS NULL
             )
         AND (   DECODE (parameter_6,
                         '0', ams.pac_custom_partner_aci_id,
                         '1', ams.pac_custom_partner_id,
                         ams.pac_custom_partner_id
                        ) IN (
                    SELECT lis.lis_id_1 pac_custom_partner_id
                      FROM com_list lis
                     WHERE lis.lis_job_id = parameter_3
                       AND lis.lis_code = 'PAC_CUSTOM_PARTNER_ID')
              OR parameter_2 = '1'
             )
         AND (   parameter_7 IS NULL
              OR INSTR (',' || parameter_7 || ',',
                        ',' || ams.c_asa_mis_status || ','
                       ) > 0
             );
END rpt_asa_mission;
