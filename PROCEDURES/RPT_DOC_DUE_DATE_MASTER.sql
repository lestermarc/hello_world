--------------------------------------------------------
--  DDL for Procedure RPT_DOC_DUE_DATE_MASTER
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_DUE_DATE_MASTER" (
  arefcursor           in out crystal_cursor_types.dualcursortyp
, parameter_0          in     varchar2
, parameter_1          in     varchar2
, parameter_2          in     varchar2
, parameter_3          in     varchar2
, parameter_4          in     varchar2
, parameter_5          in     varchar2
, parameter_6          in     varchar2
, parameter_7          in     varchar2
, parameter_8          in     varchar2
, parameter_9          in     varchar2
, parameter_10         in     varchar2
, parameter_11         in     varchar2
, parameter_12         in     varchar2
, parameter_13         in     varchar2
, parameter_14         in     varchar2
, parameter_15         in     varchar2
, procuser_lanid       in     pcs.pc_lang.lanid%type
, report_name          in     varchar2
, calling_pc_object_id in     pcs.pc_object.pc_object_id%type
, company_owner        in     pcs.pc_scrip.scrdbowner%type
)
is
/**
*Description
 Used for the reports  DOC_CUST_ECHEANCIER_CUST_BATCH, DOC_SUPPL_ECHEANCIER_SUPPL_BATCH
                               DOC_CUST_ECHEANCIER_GOOD_BATCH, DOC_SUPPL_ECHEANCIER_GOOD_BATCH

*@created PNA 27 Mar 2007
*@lastUpdate sma 30.10.2013
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
  vpc_lang_id             pcs.pc_lang.pc_lang_id%type;
  report_names            varchar2(100);
  report_names_1          varchar2(100);
  report_names_2          varchar2(100);
  param_c_gauge_title     varchar2(30);
  param_pos_status        varchar2(30);
  param_doc_status        varchar2(30);
  param_dmt_date_start    date;
  param_dmt_date_end      date;
  param_final_delay       date;
  vpc_pas_ligne           dico_description.dit_descr%type;
  vpc_pas_famille         dico_description.dit_descr%type;
  vpc_pas_modele          dico_description.dit_descr%type;
  vpc_pas_groupe          dico_description.dit_descr%type;
  vpc_pas_activite        dico_description.dit_descr%type;
  vpc_pas_region          dico_description.dit_descr%type;
  vpc_pas_type_partenaire dico_description.dit_descr%type;
  vpc_pas_representant    dico_description.dit_descr%type;
  nDocDelayWeekstart      number;
begin
--Initialize the name of the report
  report_names             := substr(substr(report_name, instr(report_name, '\', -1) + 1), 1, length(substr(report_name, instr(report_name, '\', -1) + 1) ) - 4);
  report_names             := RPT_FUNCTIONS.GetStdReportName(report_names, CALLING_PC_OBJECT_ID);
  report_names_1           := substr(report_names, instr(report_names, '_') + 1, instr(report_names, '_', 1, 2) - instr(report_names, '_') - 1);
  report_names_2           := substr(report_names, instr(report_names, '_', -1, 2) + 1, instr(report_names, '_', -1) - instr(report_names, '_', -1, 2) - 1);

--
  begin
    if parameter_6 = '0' then
      param_final_delay  := to_date('30001231', 'YYYYMMDD');
    else
      param_final_delay  := to_date(parameter_6, 'YYYYMMDD');
    end if;
  exception
    when others then
      param_final_delay  := to_date('22001231', 'YYYYMMDD');
  end;

  begin
    if parameter_14 = '0' then
      param_dmt_date_start  := to_date('19800101', 'YYYYMMDD');
    else
      param_dmt_date_start  := to_date(parameter_14, 'YYYYMMDD');
    -- parameter_14  ************************************
    end if;
  exception
    when others then
      param_dmt_date_start  := to_date('19801231', 'YYYYMMDD');
  end;

  begin
    if parameter_15 = '0' then
      param_dmt_date_end  := to_date('22001231', 'YYYYMMDD');
    else
      param_dmt_date_end  := to_date(parameter_15, 'YYYYMMDD');
    -- parameter_15  ************************************
    end if;
  exception
    when others then
      param_dmt_date_end  := to_date('22001231', 'YYYYMMDD');
  end;

  if report_names in('DOC_CUST_ECHEANCIER_CUST_BATCH', 'DOC_CUST_ECHEANCIER_GOOD_BATCH') then
    case parameter_9
      when '0' then
        param_c_gauge_title  := '6,30';
      when '1' then
        param_c_gauge_title  := '6';
      when '2' then
        param_c_gauge_title  := '30';
    end case;
  elsif report_names in('DOC_SUPPL_ECHEANCIER_SUPPL_BATCH', 'DOC_SUPPL_ECHEANCIER_GOOD_BATCH') then
    case parameter_9
      when '0' then
        param_c_gauge_title  := '1,5';
      when '1' then
        param_c_gauge_title  := '1';
      when '2' then
        param_c_gauge_title  := '5';
    end case;
  end if;

  pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  vpc_lang_id              := pcs.PC_I_LIB_SESSION.getuserlangid;
  vpc_pas_ligne            := pcs.pc_functions.translateword2('Pas de ligne produit', vpc_lang_id);
  vpc_pas_famille          := pcs.pc_functions.translateword2('Pas de famille produit', vpc_lang_id);
  vpc_pas_modele           := pcs.pc_functions.translateword2('Pas de modèle produit', vpc_lang_id);
  vpc_pas_groupe           := pcs.pc_functions.translateword2('Pas de groupe produit', vpc_lang_id);
  vpc_pas_activite         := pcs.pc_functions.translateword2('Pas activité', vpc_lang_id);
  vpc_pas_region           := pcs.pc_functions.translateword2('Pas de région', vpc_lang_id);
  vpc_pas_type_partenaire  := pcs.pc_functions.translateword2('Pas de type de partenaire', vpc_lang_id);

  -- Premier jour de la semaine
  nDocDelayWeekstart := to_number(nvl(PCS.PC_CONFIG.GetConfig('DOC_DELAY_WEEKSTART'), '2') );

  open arefcursor for
    select nDocDelayWeekstart DOC_DELAY_WEEKSTART_CONFIG
         , to_char(sysdate, 'YYYYIW') year_week
         , to_char(sysdate, 'YYYYMM') year_month
         , dmt.dmt_number
         , dmt.dmt_date_document
         , dmt.dmt_rate_euro
         , dmt.dmt_base_price
         , dmt.dmt_rate_of_exchange
         , gas.c_gauge_title
         , pos.c_doc_pos_status
         , pos.gco_good_id
         , pos.pos_number
         , gco_functions.getdescription2(goo.gco_good_id, vpc_lang_id, 1, '01') des_short_description
         , gco_functions.getdescription2(goo.gco_good_id, vpc_lang_id, 2, '01') des_long_description
         , pos.pos_net_unit_value
         , pos.pos_net_value_excl
         , pos.pos_final_quantity
         , pos.dic_unit_of_measure_id
         , pos.pos_net_value_excl_b
         , pos.pos_balance_quantity
         , goo.goo_major_reference
         , goo.goo_secondary_reference
         , gco_functions.getcostpricewithmanagementmode(goo.gco_good_id) cost_price
         , goo.goo_number_of_decimal
         , goo.dic_good_line_id
         , nvl( (select dit_descr
                   from dico_description dit
                  where dit.dit_table = 'DIC_GOOD_LINE'
                    and dit_code = goo.dic_good_line_id
                    and dit.pc_lang_id = vpc_lang_id), vpc_pas_ligne) dic_good_line_descr
         ,
           --1 differentiate  lines which are null or not in crystal
           goo.dic_good_family_id
         , nvl( (select dit_descr
                   from dico_description dit
                  where dit.dit_table = 'DIC_GOOD_FAMILY'
                    and dit_code = goo.dic_good_family_id
                    and dit.pc_lang_id = vpc_lang_id), vpc_pas_famille) dic_good_family_descr
         ,
           --1 differentiate between families which are null or not in crystal
           goo.dic_good_model_id
         , nvl( (select dit_descr
                   from dico_description dit
                  where dit.dit_table = 'DIC_GOOD_MODEL'
                    and dit_code = goo.dic_good_model_id
                    and dit.pc_lang_id = vpc_lang_id), vpc_pas_modele) dic_good_model_descr
         ,
           --1 differentiate between models which are null or not in crystal
           goo.dic_good_group_id
         , nvl( (select dit_descr
                   from dico_description dit
                  where dit.dit_table = 'DIC_GOOD_GROUP'
                    and dit_code = goo.dic_good_group_id
                    and dit.pc_lang_id = vpc_lang_id), vpc_pas_groupe) dic_good_group_descr
         ,
           --1 differentiate between groups which are null or not in crystal
           pde.pde_final_delay
         , to_char(pde.pde_final_delay, 'YYYYIW') pde_year_week
         , to_char(pde.pde_final_delay, 'YYYYMM') pde_year_month
         , pde.pde_final_quantity
         , pde.pde_balance_quantity
         , pde.pde_characterization_value_1
         , pde.pde_characterization_value_2
         , pde.pde_characterization_value_3
         , pde.pde_characterization_value_4
         , pde.pde_characterization_value_5
         , decode(report_names, 'DOC_SUPPL_ORDER_PORT_SUPPL_BATCH', fns.fan_netw_qty, 'DOC_SUPPL_ORDER_PORT_SUPPL_BATCH', fns.fan_netw_qty, fnn.fan_netw_qty)
                                                                                                                                                   fan_netw_qty
         , decode(report_names, 'DOC_SUPPL_ORDER_PORT_SUPPL_BATCH', fns.fan_stk_qty, 'DOC_SUPPL_ORDER_PORT_SUPPL_BATCH', fns.fan_stk_qty, fnn.fan_stk_qty)
                                                                                                                                                    fan_stk_qty
         , per.per_name
         , (select adr.add_address1 || '  ' || adr.add_format
              from pac_address adr
             where adr.pac_person_id = dmt.pac_third_id
               and adr.add_principal = 1) inv_address
         , per.per_key1
         , thi.pac_third_id
         , thi.dic_third_activity_id
         , decode(thi.dic_third_activity_id, null, vpc_pas_activite, (select thi.dic_third_activity_id || ' - ' || act.act_descr
                                                                        from dic_third_activity act
                                                                       where act.dic_third_activity_id = thi.dic_third_activity_id) ) act_descr
         , decode(thi.dic_third_area_id, null, vpc_pas_region, (select thi.dic_third_area_id || ' - ' || are.are_descr
                                                                  from dic_third_area are
                                                                 where are.dic_third_area_id = thi.dic_third_area_id) ) are_descr
         , decode(report_names_1, 'CUST', cus.dic_type_partner_id, 'SUPPL', sup.dic_type_partner_f_id) dic_type_partner_id
         , decode(report_names_1
                , 'CUST', decode(cus.dic_type_partner_id
                               , null, vpc_pas_type_partenaire
                               , (select (select dit.dit_descr
                                            from dico_description dit
                                           where dit.dit_table = 'DIC_TYPE_PARTNER'
                                             and dit.pc_lang_id = vpc_lang_id
                                             and dit.dit_code = dtp.dic_type_partner_id)
                                    from dic_type_partner dtp
                                   where dtp.dic_type_partner_id = cus.dic_type_partner_id)
                                )
                , 'SUPPL', decode(sup.dic_type_partner_f_id
                                , null, vpc_pas_type_partenaire
                                , (select (select dit.dit_descr
                                             from dico_description dit
                                            where dit.dit_table = 'DIC_TYPE_PARTNER'
                                              and dit.pc_lang_id = vpc_lang_id
                                              and dit.dit_code = dtp.dic_type_partner_f_id)
                                     from dic_type_partner_f dtp
                                    where dtp.dic_type_partner_f_id = sup.dic_type_partner_f_id)
                                 )
                 ) dic_descr
         , decode(dmt.pac_representative_id, null, vpc_pas_representant, (select rep.rep_descr
                                                                            from pac_representative rep
                                                                           where rep.pac_representative_id = dmt.pac_representative_id) ) rep_descr
         , (select max(cre.cre_amount_limit)
              from pac_credit_limit cre
                 , acs_financial_currency acs
             where cre.pac_supplier_partner_id || cre.pac_custom_partner_id = dmt.pac_third_id
               and cre.acs_financial_currency_id = dmt.acs_financial_currency_id) cre_amount_limit
         , (select max(curr.currency)
              from acs_financial_currency acs
                 , pcs.pc_curr curr
             where dmt.acs_financial_currency_id = acs.acs_financial_currency_id
               and acs.pc_curr_id = curr.pc_curr_id) currency
         , vgq.spo_available_quantity
      from acs_financial_currency fin
         , doc_document dmt
         , doc_gauge_structured gas
         , doc_position pos
         , doc_position_detail pde
         , gco_good goo
         , pac_person per
         , pac_third thi
         , pcs.pc_curr cur
         , pac_representative pac
         , pac_custom_partner cus
         , pac_supplier_partner sup
         , fal_network_need fnn
         , fal_network_supply fns
         , v_stm_gco_good_qty vgq
     where dmt.acs_financial_currency_id = fin.acs_financial_currency_id
       and fin.pc_curr_id = cur.pc_curr_id
       and dmt.doc_gauge_id = gas.doc_gauge_id
       and dmt.doc_document_id = pos.doc_document_id
       and pos.doc_position_id = pde.doc_position_id
       and pos.gco_good_id = goo.gco_good_id
       and pos.pac_representative_id = pac.pac_representative_id(+)
       and pde.doc_position_detail_id = fnn.doc_position_detail_id(+)
       and pde.doc_position_detail_id = fns.doc_position_detail_id(+)
       and goo.gco_good_id = vgq.gco_good_id(+)
       and dmt.pac_third_id = thi.pac_third_id
       and thi.pac_third_id = per.pac_person_id
       and per.pac_person_id = cus.pac_custom_partner_id(+)
       and per.pac_person_id = sup.pac_supplier_partner_id(+)
       and pos.c_gauge_type_pos in('1', '7', '8', '91', '10')
       and rpt_functions.check_cust_suppl(report_names_1, per.pac_person_id) = 1
       --According to report name to define customer or supplier
       and rpt_functions.check_record_in_range(report_names_2, goo.goo_major_reference, per.per_key1, parameter_0, parameter_1) = 1
       and pos.c_doc_pos_status in('01', '02', '03', '04')
       and dmt.dmt_date_document >= param_dmt_date_start
       and dmt.dmt_date_document <= param_dmt_date_end
       and instr(',' || param_c_gauge_title || ',', ',' || gas.c_gauge_title || ',') > 0
       and c_document_status in('01', '02', '03')
       --{@TEST_RETARD} Lateness
       and rpt_functions.order_echeancier_batch(report_names, param_final_delay, pde.pde_final_delay, gas.c_gauge_title) = 1;
end rpt_doc_due_date_master;
