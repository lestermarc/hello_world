--------------------------------------------------------
--  DDL for Procedure RPT_CML_POSITION_STD
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_CML_POSITION_STD" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       cml_position.cml_position_id%TYPE,
   parameter_1      IN       CML_DOCUMENT.CML_DOCUMENT_ID%TYPE
)
IS
/*
* Description stored procedure used for the report CML_POSITION_STD

* @created AWU 01 NOV 2008
* @update AWU 23 Apr 2009
* @lastupdate cliu 23 July 2010  added PARAMETER_1 CML_DOCUMENT_ID
* @public
* @param PARAMETER_0: CML_POSITION_ID
* @param PARAMETER_1: CML_DOCUMENT_ID
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT cco.cco_number,                                   /*No contrat*/
             cco.cco_initdate,

             /*Date*/
             cco.cco_description,                                   /*Descr*/
             pcs.pc_functions.getdescodedescr
                            ('C_CML_CONTRACT_STATUS',
                             cco.c_cml_contract_status,
                             vpc_lang_id
                            ) c_cml_contract_status,               /*Statut*/
             (SELECT per1.per_name
                FROM pac_person per1
               WHERE per1.pac_person_id = cco.pac_custom_partner_id) client,

             /*Client*/
             (SELECT per2.per_name
                FROM pac_person per2
               WHERE per2.pac_person_id =
                                    cco.pac_custom_partner_aci_id)
                                                                 client_fact,

             /*Client fact*/
             (SELECT per3.per_name
                FROM pac_person per3
               WHERE per3.pac_person_id =
                                cco.pac_custom_partner_tariff_id)
                                                                client_tarif,

             /*Client tarif*/
             cco.dic_tariff_id,                                /*Code tarif*/
                               cpo.cpo_sequence,                   /*No pos*/
                                                cpo.cpo_description,

             /*Descr pos*/
             pcs.pc_functions.getdescodedescr
                                          ('C_CML_POS_TYPE',
                                           cpo.c_cml_pos_type,
                                           vpc_lang_id
                                          ) c_cml_pos_type,          /*Type*/
             cpo.cpo_cost_price,                                       /*PR*/
             (SELECT rco1.rco_title
                FROM doc_record rco1
               WHERE rco1.doc_record_id = cpo.doc_record_id) dossier,

             /*Dossier*/
             (SELECT rep.rep_descr
                FROM pac_representative rep
               WHERE rep.pac_representative_id =
                                               cpo.pac_representative_id)
                                                                        repr,

             /*Repr.*/
             (SELECT pus.use_name
                FROM pcs.pc_user pus
               WHERE pus.pc_user_id = cpo.cpo_pc_user_id) visa_ctrl,

             /*Visa ctrl*/
             cpo.cpo_sale_price,                                       /*PV*/
             cpo.cpo_conclusion_date,

             /*Date Conclusion*/
             cpo.cpo_begin_contract_date,

             /*Date d?ut*/
             cpo.cpo_extended_monthes,                 /*Prol. Contrat/mois*/
                                      cpo.cpo_extension_period_nb,

             /*Prol autoris?*/
             cpo.cpo_begin_service_date,

             /*Date mise service*/
             cpo.cpo_contract_monthes,                               /*Dur?*/
                                      cpo.cpo_extension_time,   /*Dur? prol*/
             cpo.cpo_ext_period_nb_done,                    /*Prol effectu?*/
             cpo.cpo_end_contract_date,

             /*Date fin pr?ue*/
             cpo.cpo_end_extended_date,

             /*Date fin pr?ue prol*/
             cpo.cpo_init_period_price,                  /*Prix p?iode init*/
                                       cpo.cpo_extend_period_price,

             /*Prix prolongation*/
             cpo.cpo_position_cost_price,               /*Prix revient pos.*/
                                         cpo.cpo_position_amount,

             /*Montant factur?/*/
             cpo.cpo_position_added_amount,           /*Montant suppl fact.*/
                                           cpo.cpo_position_loss,

             /*Perte position*/
             cpr.cpr_january, cpr.cpr_february, cpr.cpr_march, cpr.cpr_april,
             cpr.cpr_may, cpr.cpr_june, cpr.cpr_july, cpr.cpr_august,
             cpr.cpr_september, cpr.cpr_october, cpr.cpr_november,
             cpr.cpr_december,
             cpo.cpo_last_period_begin,

             /*D?ut derni?e p?iode*/
             cpo.cpo_last_period_end,

             /*Fin derni?e p?iode*/
             cpo.cpo_next_date,

             /*Prochaine ?h?nce*/
             cpo.dic_cml_invoice_regrouping_id,    /*Code regroupement fact*/
                                               cpo.cpo_bill_text,

             /*Texte facturation*/
             cpo.cpo_suspension_date,

             /*Date suspension*/
             cpo.dic_cml_suspension_reason_id,           /*Motif suspension*/
             cpo.cpo_resiliation_date,

             /*Date r?iliation*/
             cpo.dic_cml_resiliation_reason_id,          /*Motif r?iliation*/
                                               cpo.cpo_depot_amount,

             /*Montant d??t*/
             cpo.cpo_depot_bill_date,

             /*Date facture d??t*/
             cpo.cpo_depot_cn_date,

             /*Date NC d??t*/
             cpo.cpo_penality_amount,                    /*Montant p?alit?/*/
             cpo.cpo_penality_bill_date,
        /*Date fact. P?alit?/*/
        cpo.CML_POSITION_ID
      FROM   cml_position cpo, cml_document cco, cml_processing cpr
       WHERE cpo.cml_document_id = cco.cml_document_id
         AND cpo.cml_position_id = cpr.cml_position_id(+)
         AND ((nvl(parameter_1,0) = 0 and  cpo.cml_position_id = parameter_0)
         OR CCO.CML_DOCUMENT_ID = parameter_1);
END rpt_cml_position_std;
