--------------------------------------------------------
--  DDL for Procedure RPT_DOC_SUPPL_REMINDER_BAT
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_SUPPL_REMINDER_BAT" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, parameter_0    in     varchar2
, parameter_1    in     varchar2
, parameter_14   in     varchar2
, parameter_15   in     varchar2
, procuser_lanid in     pcs.pc_lang.lanid%type
)
is
/**
*Description
        Used for report DOC_SUPPL_REMINDER_BATCH

*@created EQI 21 AUG 2007
*@lastUpdate  sma 30.10.2013
*@public
*@param PARAMETER_0 : minimum value for PAC_PERSON.PER_KEY1
*@param PARAMETER_1 : maximum value for PAC_PERSON.PER_KEY1
*@param PARAMETER_14 : minimum value for DOC_DOCUMENT.DMT_DATE_DOCUMENT
*@param PARAMETER_15 : maximum value for DOC_DOCUMENT.DMT_DATE_DOCUMENT
*@param PROCUSER_LANID : user language
*/
  vpc_lang_id             pcs.pc_lang.pc_lang_id%type;   --user language id
  nDocDelayWeekstart      number;
begin
  pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  vpc_lang_id  := pcs.PC_I_LIB_SESSION.getuserlangid;

  -- Premier jour de la semaine
  nDocDelayWeekstart := to_number(nvl(PCS.PC_CONFIG.GetConfig('DOC_DELAY_WEEKSTART'), '2') );

  open arefcursor for
    select   nDocDelayWeekstart DOC_DELAY_WEEKSTART_CONFIG
           , dmt.dmt_number
           , dmt.c_document_status
           , gas.c_gauge_title
           , pos.pos_number
           , pos.c_gauge_type_pos
           , pos.pos_final_quantity
           , pos.pos_net_value_excl_b
           , pos.dic_unit_of_measure_id
           , pos.pos_net_unit_value
           , pde.pde_balance_quantity
           , pde.pde_final_quantity
           , pde.pde_final_delay
           , goo.gco_good_id
           , goo.goo_major_reference
           , goo.goo_number_of_decimal
           , per.pac_person_id
           , per.per_name
           , per.per_key1
           , per.per_short_name
           , (select adr.add_address1 || '  ' || adr.add_format
                from pac_address adr
               where adr.pac_person_id = dmt.pac_third_id
                 and adr.dic_address_type_id = 'Inv') inv_address
           , sup.pac_supplier_partner_id
           , sup.acs_auxiliary_account_id
           , thi.pac_third_id
           , cur.currency
           , adr.add_address1
           , des.des_short_description
           , fnn.fan_stk_qty
           , fnn.fan_netw_qty
           , (select cu2.currency
                from pac_credit_limit cre
                   , acs_financial_currency acs
                   , pcs.pc_curr cu2
               where cre.pac_supplier_partner_id = dmt.pac_third_id
                 and cre.acs_financial_currency_id = acs.acs_financial_currency_id
                 and acs.pc_curr_id = cu2.pc_curr_id) cre_amount_limit
           , stm_functions.getavailablequantity(goo.gco_good_id) available_qty
        from acs_financial_currency fin
           , doc_document dmt
           , doc_gauge_structured gas
           , doc_position pos
           , doc_position_detail pde
           , fal_network_need fnn
           , gco_good goo
           , pac_person per
           , pac_supplier_partner sup
           , pac_third thi
           , pcs.pc_curr cur
           , pac_address adr
           , gco_description des
       where goo.gco_good_id = des.gco_good_id
         and des.pc_lang_id = vpc_lang_id
         and des.c_description_type = '01'
         and per.pac_person_id = adr.pac_person_id
         and dmt.doc_document_id = pos.doc_document_id
         and pos.doc_position_id = pde.doc_position_id
         and pde.doc_position_detail_id = fnn.doc_position_detail_id(+)
         and pos.gco_good_id = goo.gco_good_id
         and dmt.doc_gauge_id = gas.doc_gauge_id
         and dmt.acs_financial_currency_id = fin.acs_financial_currency_id
         and fin.pc_curr_id = cur.pc_curr_id
         and dmt.pac_third_id = thi.pac_third_id
         and thi.pac_third_id = per.pac_person_id
         and per.pac_person_id = sup.pac_supplier_partner_id
         and gas.c_gauge_title = '1'
         and dmt.dmt_date_document >= decode(parameter_14, '0', to_date('19800101', 'YYYYMMDD'), to_date(parameter_14, 'YYYYMMDD') )
         and dmt.dmt_date_document <= decode(parameter_15, '0', to_date('30001231', 'YYYYMMDD'), to_date(parameter_15, 'YYYYMMDD') )
         and dmt.c_document_status in('02', '03')
         and pos.c_gauge_type_pos in('1', '7', '8', '91', '10')
         and per.per_key1 >= parameter_0
         and per.per_key1 <= parameter_1
    order by dmt.dmt_number
           , pos.pos_number;
end rpt_doc_suppl_reminder_bat;
