--------------------------------------------------------
--  DDL for Procedure RPT_DOC_PORT_3RD_PAR_MASTER
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_PORT_3RD_PAR_MASTER" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0      IN       VARCHAR2,
   parameter_1      IN       VARCHAR2,
   parameter_2      IN       VARCHAR2,
   parameter_3      IN       VARCHAR2,
   parameter_4      IN       VARCHAR2,
   parameter_5      IN       VARCHAR2,
   parameter_6      IN       VARCHAR2,
   parameter_7      IN       VARCHAR2,
   parameter_8      IN       VARCHAR2,
   parameter_9      IN       VARCHAR2,
   parameter_10     IN       VARCHAR2,
   parameter_11     IN       VARCHAR2,
   parameter_12     IN       VARCHAR2,
   parameter_13     IN       VARCHAR2,
   parameter_14     IN       VARCHAR2,
   parameter_15     IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   report_name      IN       VARCHAR2,
   calling_pc_object_id  IN  pcs.pc_object.pc_object_id%type,
   company_owner    IN       pcs.pc_scrip.scrdbowner%type
)
IS
/**
*Description
 Used for the reports

 Group 1 - PORTFOLIO BY THIRD PARTY
 DOC_CUST_ORDER_PORT_CUST_BATCH
 DOC_CUST_CONSIG_PORT_CUST_BATCH
 DOC_CUST_DELIVERY_PORT_CUST_BATCH
 DOC_SUPPL_ORDER_PORT_SUPPL_BATCH
 DOC_SUPPL_DELIVERY_PORT_SUPPL_BATCH

*@created PNA 1 JUN 2007
*@lastUpdate VHA 4 February 2013
*@public
*@param PARAMETER_0 : minimun value fro GCO_GOOD.GOO_MAJOR_REFERENCE or PAC_PERSON.PER_KEY1
*@param PARAMETER_1 : maximun value fro GCO_GOOD.GOO_MAJOR_REFERENCE or PAC_PERSON.PER_KEY1
*@param PARAMETER_2 : used in Crystal report - use activity (yes or no)
*@param PARAMETER_3 : used in Crystal report - use region (yes or no)
*@param PARAMETER_4 : used in Crystal report - use partner type (yes or no)
*@param PARAMETER_5 : used in Crystal report - use sales person (yes or no)
*@param PARAMETER_6 : Final delay for detail information of document
*@param PARAMETER_7 : used in Crystal report - show value (yes or no)
*@param PARAMETER_8 : used in Crystal report - due date type (0 = day or 1 = week)
*@param PARAMETER_9 : document gauge title
*@param PARAMETER_10 : position status of document
*@param PARAMETER_11 : for parameter Allocation
*@param PARAMETER_12 : for parameter Parcel
*@param PARAMETER_13 : for parameter Lateness
*@param PARAMETER_14 : minimum value for DOC_DOCUMENT.DMT_DATE_DOCUMENT
*@param PARAMETER_15 : maximum value for DOC_DOCUMENT.DMT_DATE_DOCUMENT
*@param PROCUSER_LANID : user language
*@param REPORT_NAME : crystal report name
*@param CALLING_PC_OBJECT_ID : crystal calling object id
*@param COMPANY_OWNER : crystal company owner
*/
   vpc_lang_id               pcs.pc_lang.pc_lang_id%TYPE;
   report_names              VARCHAR2 (100 CHAR);
   report_names_1            VARCHAR2 (100 CHAR);
   report_names_2            VARCHAR2 (100 CHAR);
   param_c_gauge_title       VARCHAR2 (30 CHAR);
   param_pos_status          VARCHAR2 (30 CHAR);
   param_doc_status          VARCHAR2 (30 CHAR);
   param_dmt_date_start      DATE;
   param_dmt_date_end        DATE;
   param_final_delay         DATE;
   param_0                   VARCHAR2 (30 CHAR);
   param_1                   VARCHAR2 (30 CHAR);
   param_6                   VARCHAR2 (8 CHAR);
   param_9                   VARCHAR2 (1 CHAR);
   param_10                  VARCHAR2 (1 CHAR);
   param_11                  VARCHAR2 (30 CHAR);
   param_12                  VARCHAR2 (30 CHAR);
   param_13                  VARCHAR2 (30 CHAR);
   param_14                  VARCHAR2 (8 CHAR);
   param_15                  VARCHAR2 (8 CHAR);
   vpc_pas_ligne             dico_description.dit_descr%TYPE;
   vpc_pas_famille           dico_description.dit_descr%TYPE;
   vpc_pas_modele            dico_description.dit_descr%TYPE;
   vpc_pas_groupe            dico_description.dit_descr%TYPE;
   vpc_pas_activite          dico_description.dit_descr%TYPE;
   vpc_pas_region            dico_description.dit_descr%TYPE;
   vpc_pas_type_partenaire   dico_description.dit_descr%TYPE;
   vpc_pas_representant      dico_description.dit_descr%TYPE;
   nDocDelayWeekstart        number;
BEGIN
--Initialize the parameter, remove all the space in the parameter
   param_0 := TRIM (parameter_0);
   param_1 := TRIM (parameter_1);
   param_6 := TRIM (parameter_6);
   param_9 := TRIM (parameter_9);
   param_10 := TRIM (parameter_10);
   param_11 := TRIM (parameter_11);
   param_12 := TRIM (parameter_12);
   param_13 := TRIM (parameter_13);
   param_14 := NVL (TRIM (parameter_14), '0');
   param_15 := NVL (TRIM (parameter_15), '0');
--Initialize the name of the report
   report_names :=
      SUBSTR (SUBSTR (report_name, INSTR (report_name, '\', -1) + 1),
              1,
              LENGTH (SUBSTR (report_name, INSTR (report_name, '\', -1) + 1))
              - 4
             );
   report_names := RPT_FUNCTIONS.GetStdReportName(report_names,CALLING_PC_OBJECT_ID);
   report_names_1 :=
      SUBSTR (report_names,
              INSTR (report_names, '_') + 1,
              INSTR (report_names, '_', 1, 2) - INSTR (report_names, '_') - 1
             );
   report_names_2 :=
      SUBSTR (report_names,
              INSTR (report_names, '_', -1, 2) + 1,
              INSTR (report_names, '_', -1) - INSTR (report_names, '_', -1, 2)
              - 1
             );

--Final delay for detail information of document
   BEGIN
      IF param_6 = '0'
      THEN
         param_final_delay := TO_DATE ('22001231', 'YYYYMMDD');
      ELSE
         param_final_delay := TO_DATE (param_6, 'YYYYMMDD');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         param_final_delay := TO_DATE ('22001231', 'YYYYMMDD');
   END;

   BEGIN
      IF param_14 = '0'
      THEN
         param_dmt_date_start := TO_DATE (19800101, 'YYYYMMDD');
      ELSE
         param_dmt_date_start := TO_DATE (param_14, 'YYYYMMDD');
      -- parameter_14  ************************************
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         param_dmt_date_start := TO_DATE ('19801231', 'YYYYMMDD');
   END;

   BEGIN
      IF param_15 = '0'
      THEN
         param_dmt_date_end := TO_DATE (22001231, 'YYYYMMDD');
      ELSE
         param_dmt_date_end := TO_DATE (param_15, 'YYYYMMDD');
      -- parameter_15  ************************************
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         param_dmt_date_end := TO_DATE ('22001231', 'YYYYMMDD');
   END;

   IF report_names IN ('DOC_CUST_ORDER_PORT_CUST_BATCH')
   THEN
      CASE param_9
         WHEN '0'
         THEN
            param_c_gauge_title := '6,30';
         WHEN '1'
         THEN
            param_c_gauge_title := '6';
         WHEN '2'
         THEN
            param_c_gauge_title := '30';
      END CASE;

      CASE param_10
         WHEN 0
         THEN
            param_pos_status := '01,02,03,04';                          --All
         WHEN 1
         THEN
            param_pos_status := '01';                            --To Confirm
         WHEN 2
         THEN
            param_pos_status := '02,03';  --To Balance and Partially Balanced
         WHEN 3
         THEN
            param_pos_status := '01,02,03';
         --To Confirm, To Balance and Partially Balanced
      WHEN 4
         THEN
            param_pos_status := '04';                              --Finished
         WHEN 5
         THEN
            param_pos_status := '01,04';            --To Confirm and Finished
         WHEN 6
         THEN
            param_pos_status := '02,03,04';
         --To Balance and Partially Balanced and Finished
      WHEN 7
         THEN
            param_pos_status := '01,02,03,04';                          --All
      END CASE;

      param_doc_status := '01,02,03,04,05';
   ELSIF report_names = 'DOC_CUST_CONSIG_PORT_CUST_BATCH'
   THEN
      param_c_gauge_title := '20';
      param_pos_status := '02,03';
      param_doc_status := '02,03';
      param_dmt_date_start := TO_DATE (19800101, 'YYYYMMDD');
      param_dmt_date_end := TO_DATE (22001231, 'YYYYMMDD');
   ELSIF report_names IN ('DOC_CUST_DELIVERY_PORT_CUST_BATCH')
   THEN
      param_c_gauge_title := '7';

      CASE param_10
         WHEN 0
         THEN
            param_pos_status := '01,02,03,04';                          --All
         WHEN 1
         THEN
            param_pos_status := '01';                            --To Confirm
         WHEN 2
         THEN
            param_pos_status := '02,03';  --To Balance and Partially Balanced
         WHEN 3
         THEN
            param_pos_status := '01,02,03';
         --To Confirm, To Balance and Partially Balanced
      WHEN 4
         THEN
            param_pos_status := '04';                              --Finished
         WHEN 5
         THEN
            param_pos_status := '01,04';            --To Confirm and Finished
         WHEN 6
         THEN
            param_pos_status := '02,03,04';
         --To Balance and Partially Balanced and Finished
      WHEN 7
         THEN
            param_pos_status := '01,02,03,04';                          --All
      END CASE;

      param_doc_status := '01,02,03,04,05';
   ELSIF report_names IN ('DOC_SUPPL_ORDER_PORT_SUPPL_BATCH')
   THEN
      CASE param_9
         WHEN '0'
         THEN
            param_c_gauge_title := '1,5';             --both order and return
         WHEN '1'
         THEN
            param_c_gauge_title := '1';                          --only order
         WHEN '2'
         THEN
            param_c_gauge_title := '5';                         --only return
      END CASE;

      CASE param_10
         WHEN 0
         THEN
            param_pos_status := '01,02,03,04';                          --All
         WHEN 1
         THEN
            param_pos_status := '01';                            --To Confirm
         WHEN 2
         THEN
            param_pos_status := '02,03';  --To Balance and Partially Balanced
         WHEN 3
         THEN
            param_pos_status := '01,02,03';
         --To Confirm, To Balance and Partially Balanced
      WHEN 4
         THEN
            param_pos_status := '04';                              --Finished
         WHEN 5
         THEN
            param_pos_status := '01,04';            --To Confirm and Finished
         WHEN 6
         THEN
            param_pos_status := '02,03,04';
         --To Balance and Partially Balanced and Finished
      WHEN 7
         THEN
            param_pos_status := '01,02,03,04';                          --All
      END CASE;

      param_doc_status := '01,02,03,04,05';
   ELSIF report_names IN ('DOC_SUPPL_DELIVERY_PORT_SUPPL_BATCH')
   THEN
      param_c_gauge_title := '2,3';

      CASE param_10
         WHEN 0
         THEN
            param_pos_status := '01,02,03,04';                          --All
         WHEN 1
         THEN
            param_pos_status := '01';                            --To Confirm
         WHEN 2
         THEN
            param_pos_status := '02,03';  --To Balance and Partially Balanced
         WHEN 3
         THEN
            param_pos_status := '01,02,03';
         --To Confirm, To Balance and Partially Balanced
      WHEN 4
         THEN
            param_pos_status := '04';                              --Finished
         WHEN 5
         THEN
            param_pos_status := '01,04';            --To Confirm and Finished
         WHEN 6
         THEN
            param_pos_status := '02,03,04';
         --To Balance and Partially Balanced and Finished
      WHEN 7
         THEN
            param_pos_status := '01,02,03,04';                          --All
      END CASE;

      param_doc_status := '01,02,03,04,05';
   END IF;

   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;
   vpc_pas_ligne :=
         pcs.pc_functions.translateword2 ('Pas de ligne produit', vpc_lang_id);
   vpc_pas_famille :=
       pcs.pc_functions.translateword2 ('Pas de famille produit', vpc_lang_id);
   vpc_pas_modele :=
        pcs.pc_functions.translateword2 ('Pas de modèle produit', vpc_lang_id);
   vpc_pas_groupe :=
        pcs.pc_functions.translateword2 ('Pas de groupe produit', vpc_lang_id);
   vpc_pas_activite :=
                 pcs.pc_functions.translateword2 ('Pas activité', vpc_lang_id);
   vpc_pas_region :=
                pcs.pc_functions.translateword2 ('Pas de région', vpc_lang_id);
   vpc_pas_type_partenaire :=
      pcs.pc_functions.translateword2 ('Pas de type de partenaire',
                                       vpc_lang_id
                                      );
   vpc_pas_representant :=
          pcs.pc_functions.translateword2 ('Pas de représentant', vpc_lang_id);

   -- Premier jour de la semaine
   nDocDelayWeekstart := to_number(nvl(PCS.PC_CONFIG.GetConfig('DOC_DELAY_WEEKSTART'), '2') );

   OPEN arefcursor FOR
      SELECT nDocDelayWeekstart DOC_DELAY_WEEKSTART_CONFIG
           , rpt_functions.cust_order_port_batch
                                  (report_names,
                                   param_11,
                                   fnn.fan_stk_qty,
                                   fnn.fan_netw_qty
                                  ) test_customer_allocations,
             rpt_functions.suppl_order_port_batch
                                  (report_names,
                                   param_11,
                                   fns.fan_stk_qty,
                                   fns.fan_netw_qty
                                  ) test_supplier_allocations,
             TO_CHAR (SYSDATE, 'YYYYIW') year_week,
             TO_CHAR (SYSDATE, 'YYYYMM') year_month, dmt.dmt_number,
             dmt.dmt_date_document, dmt.dmt_rate_euro, dmt.dmt_base_price,
             dmt.dmt_rate_of_exchange, gas.c_gauge_title,
             pos.c_doc_pos_status, pos.gco_good_id, pos.pos_number,
             gco_functions.getdescription2
                                       (goo.gco_good_id,
                                        vpc_lang_id,
                                        1,
                                        '01'
                                       ) des_short_description,
             gco_functions.getdescription2
                                       (goo.gco_good_id,
                                        vpc_lang_id,
                                        2,
                                        '01'
                                       ) des_long_description,
             pos.pos_net_unit_value, pos.pos_net_value_excl,
             pos.pos_final_quantity, pos.dic_unit_of_measure_id,
             pos.pos_net_value_excl_b, pos.pos_balance_quantity,
             goo.goo_major_reference, goo.goo_secondary_reference,
             gco_functions.getcostpricewithmanagementmode
                                                  (goo.gco_good_id)
                                                                   cost_price,
             goo.goo_number_of_decimal, goo.dic_good_line_id,
             NVL ((SELECT dit_descr
                     FROM dico_description dit
                    WHERE dit.dit_table = 'DIC_GOOD_LINE'
                      AND dit_code = goo.dic_good_line_id
                      AND dit.pc_lang_id = vpc_lang_id),
                  vpc_pas_ligne
                 ) dic_good_line_descr,

             --1 differentiate  lines which are null or not in crystal
             goo.dic_good_family_id,
             NVL ((SELECT dit_descr
                     FROM dico_description dit
                    WHERE dit.dit_table = 'DIC_GOOD_FAMILY'
                      AND dit_code = goo.dic_good_family_id
                      AND dit.pc_lang_id = vpc_lang_id),
                  vpc_pas_famille
                 ) dic_good_family_descr,

--1 differentiate between families which are null or not in crystal
             goo.dic_good_model_id,
             NVL ((SELECT dit_descr
                     FROM dico_description dit
                    WHERE dit.dit_table = 'DIC_GOOD_MODEL'
                      AND dit_code = goo.dic_good_model_id
                      AND dit.pc_lang_id = vpc_lang_id),
                  vpc_pas_modele
                 ) dic_good_model_descr,

             --1 differentiate between models which are null or not in crystal
             goo.dic_good_group_id,
             NVL ((SELECT dit_descr
                     FROM dico_description dit
                    WHERE dit.dit_table = 'DIC_GOOD_GROUP'
                      AND dit_code = goo.dic_good_group_id
                      AND dit.pc_lang_id = vpc_lang_id),
                  vpc_pas_groupe
                 ) dic_good_group_descr,

             --1 differentiate between groups which are null or not in crystal
             pde.pde_final_delay,
             TO_CHAR (pde.pde_final_delay, 'YYYYIW') pde_year_week,
             TO_CHAR (pde.pde_final_delay, 'YYYYMM') pde_year_month,
             pde.pde_final_quantity, pde.pde_basis_quantity,
             pde.pde_balance_quantity, pde.pde_characterization_value_1,
             pde.pde_characterization_value_2,
             pde.pde_characterization_value_3,
             pde.pde_characterization_value_4,
             pde.pde_characterization_value_5,
             NVL (DECODE (report_names,
                          'DOC_SUPPL_ORDER_PORT_SUPPL_BATCH', fns.fan_netw_qty,
                          fnn.fan_netw_qty
                         ),
                  0
                 ) fan_netw_qty,
             NVL (DECODE (report_names,
                          'DOC_SUPPL_ORDER_PORT_SUPPL_BATCH', fns.fan_stk_qty,
                          fnn.fan_stk_qty
                         ),
                  0
                 ) fan_stk_qty,
             per.per_name, per.per_key1, thi.pac_third_id,
             (SELECT adr.add_address1
                FROM pac_address adr
               WHERE adr.pac_person_id = dmt.pac_third_id
                 AND adr.add_principal = 1) default_address,
             (SELECT    adr.add_zipcode
                     || DECODE (adr.add_zipcode,
                                NULL, adr.add_city,
                                ' ' || adr.add_city
                               )
                     || DECODE (adr.add_zipcode || adr.add_city,
                                NULL, cnt.cntname,
                                CHR (13) || cnt.cntname
                               )
                FROM pac_address adr, pcs.pc_cntry cnt
               WHERE adr.pac_person_id = dmt.pac_third_id
                 AND adr.pc_cntry_id = cnt.pc_cntry_id(+)
                 AND adr.add_principal = 1) default_adr_zipcode_city_cnt,
             DECODE (thi.dic_third_activity_id,
                     NULL, vpc_pas_activite,
                     (SELECT thi.dic_third_activity_id || ' - '
                             || act.act_descr
                        FROM dic_third_activity act
                       WHERE act.dic_third_activity_id =
                                                     thi.dic_third_activity_id)
                    ) act_descr,
             DECODE (thi.dic_third_area_id,
                     NULL, vpc_pas_region,
                     (SELECT thi.dic_third_area_id || ' - ' || ARE.are_descr
                        FROM dic_third_area ARE
                       WHERE ARE.dic_third_area_id = thi.dic_third_area_id)
                    ) are_descr,
             DECODE
                (report_names_1,
                 'CUST', DECODE (cus.dic_type_partner_id,
                                 NULL, vpc_pas_type_partenaire,
                                 (SELECT (SELECT dit.dit_descr
                                            FROM dico_description dit
                                           WHERE dit.dit_table =
                                                            'DIC_TYPE_PARTNER'
                                             AND dit.pc_lang_id = vpc_lang_id
                                             AND dit.dit_code =
                                                       dtp.dic_type_partner_id)
                                    FROM dic_type_partner dtp
                                   WHERE dtp.dic_type_partner_id =
                                                       cus.dic_type_partner_id)
                                ),
                 'SUPPL', DECODE (sup.dic_type_partner_f_id,
                                  NULL, vpc_pas_type_partenaire,
                                  (SELECT (SELECT dit.dit_descr
                                             FROM dico_description dit
                                            WHERE dit.dit_table =
                                                            'DIC_TYPE_PARTNER'
                                              AND dit.pc_lang_id = vpc_lang_id
                                              AND dit.dit_code =
                                                     dtp.dic_type_partner_f_id)
                                     FROM dic_type_partner_f dtp
                                    WHERE dtp.dic_type_partner_f_id =
                                                     sup.dic_type_partner_f_id)
                                 )
                ) dic_descr,
             DECODE (dmt.pac_representative_id,
                     NULL, vpc_pas_representant,
                     (SELECT rep.rep_descr
                        FROM pac_representative rep
                       WHERE rep.pac_representative_id =
                                                     dmt.pac_representative_id)
                    ) rep_descr,
             (SELECT MAX (cre.cre_amount_limit)
                FROM pac_credit_limit cre,
                     acs_financial_currency acs
               WHERE cre.pac_supplier_partner_id || cre.pac_custom_partner_id =
                                                              dmt.pac_third_id
                 AND cre.acs_financial_currency_id =
                                                 dmt.acs_financial_currency_id)
                                                             cre_amount_limit,
             (SELECT MAX (curr.currency)
                FROM acs_financial_currency acs, pcs.pc_curr curr
               WHERE dmt.acs_financial_currency_id =
                                       acs.acs_financial_currency_id
                 AND acs.pc_curr_id = curr.pc_curr_id) currency,
             acs_function.periodsoldeamount
                            (cus.acs_auxiliary_account_id,
                             NULL,
                             NULL,
                             'EXT',
                             1,
                             NULL
                            ) balance_amount_cus,
             acs_function.periodsoldeamount
                            (sup.acs_auxiliary_account_id,
                             NULL,
                             NULL,
                             'EXT',
                             1,
                             NULL
                            ) balance_amount_sup,
             vgq.spo_available_quantity
        FROM acs_financial_currency fin,
             doc_document dmt,
             doc_gauge_structured gas,
             doc_position pos,
             doc_position_detail pde,
             gco_good goo,
             pac_person per,
             pac_third thi,
             pcs.pc_curr cur,
             pac_representative pac,
             pac_custom_partner cus,
             pac_supplier_partner sup,
             fal_network_need fnn,
             fal_network_supply fns,
             v_stm_gco_good_qty vgq
       WHERE dmt.acs_financial_currency_id = fin.acs_financial_currency_id
         AND fin.pc_curr_id = cur.pc_curr_id
         AND dmt.doc_gauge_id = gas.doc_gauge_id
         AND dmt.doc_document_id = pos.doc_document_id
         AND pos.doc_position_id = pde.doc_position_id
         AND pos.gco_good_id = goo.gco_good_id
         AND pos.pac_representative_id = pac.pac_representative_id(+)
         AND pde.doc_position_detail_id = fnn.doc_position_detail_id(+)
         AND pde.doc_position_detail_id = fns.doc_position_detail_id(+)
         AND goo.gco_good_id = vgq.gco_good_id(+)
         AND dmt.pac_third_id = thi.pac_third_id
         AND thi.pac_third_id = per.pac_person_id
         AND per.pac_person_id = cus.pac_custom_partner_id(+)
         AND per.pac_person_id = sup.pac_supplier_partner_id(+)
         AND pos.c_gauge_type_pos IN ('1', '7', '8', '91', '10', '21')
         AND (CASE
                 WHEN report_names_1 = 'CUST'
                 AND cus.pac_custom_partner_id IS NOT NULL
                    THEN 1
                 WHEN report_names_1 = 'SUPPL'
                 AND sup.pac_supplier_partner_id IS NOT NULL
                    THEN 1
                 ELSE 0
              END
             ) = 1
         --According to report name to define customer or supplier
         AND rpt_functions.check_record_in_range (report_names_2,
                                                  goo.goo_major_reference,
                                                  per.per_key1,
                                                  param_0,
                                                  param_1
                                                 ) = 1
         AND INSTR (',' || param_pos_status || ',',
                    ',' || pos.c_doc_pos_status || ','
                   ) > 0
         AND INSTR (',' || param_c_gauge_title || ',',
                    ',' || gas.c_gauge_title || ','
                   ) > 0
         AND INSTR (',' || param_doc_status || ',',
                    ',' || dmt.c_document_status || ','
                   ) > 0
         AND dmt.dmt_date_document >= param_dmt_date_start
         AND dmt.dmt_date_document <= param_dmt_date_end
         --{@TEST_ATTRIB} Allocation customer orders
         AND rpt_functions.cust_order_port_batch (report_names,
                                                  param_11,
                                                  fnn.fan_stk_qty,
                                                  fnn.fan_netw_qty
                                                 ) = 1
         --{@TEST_COLIS} Packaging
         AND rpt_functions.cust_delivery_port_batch (report_names,
                                                     param_12,
                                                     dmt.doc_document_id
                                                    ) = 1
         --{@TEST_ATTRIB} Allocation supplier orders
         AND rpt_functions.suppl_order_port_batch (report_names,
                                                   param_11,
                                                   fns.fan_stk_qty,
                                                   fns.fan_netw_qty
                                                  ) = 1
         --{@TEST_RETARD} Lateness
         AND rpt_functions.suppl_order_port_batch_2 (report_names,
                                                     param_13,
                                                     pos.c_doc_pos_status,
                                                     pde.pde_final_delay
                                                    ) = 1
         AND rpt_functions.order_echeancier_batch (report_names,
                                                   param_final_delay,
                                                   pde.pde_final_delay,
                                                   gas.c_gauge_title
                                                  ) = 1;
END rpt_doc_port_3rd_par_master;
