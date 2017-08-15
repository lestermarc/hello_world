--------------------------------------------------------
--  DDL for Package Body DOC_STAT_RPT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_STAT_RPT" 
is
  procedure doc_can_customer_rpt_pk(
    AREFCURSOR     in out Crystal_Cursor_Types.DUALCURSORTYP
  , PARAMETER_0    in     varchar2
  , PARAMETER_1    in     varchar2
  , PARAMETER_17   in     varchar2
  , PARAMETER_18   in     varchar2
  , PARAMETER_19   in     varchar2
  , PARAMETER_20   in     varchar2
  , PROCUSER_LANID in     PCS.PC_LANG.LANID%type
  )
  is
/*
 STORED PROCEDURE USED FOR THE REPORT DOC_CAN_CUSTOMER.RPT

 @CREATED IN PROCONCEPT CHINA
 @AUTHOR MZH
 @LASTUPDATE NOV. 14 2006
 @VERSION
 @PUBLIC
 @PARAM PARAMETER_0      PAC_PERSON.PER_KEY1(MIN)
 @PARAM PARAMETER_1      PAC_PERSON.PER_KEY1(MAX)
 @PARAM PARAMETER_17    DOC_DOCUMENT.DMT_DATE_DOCUMENT(MIN)
 @PARAM PARAMETER_18    DOC_DOCUMENT.DMT_DATE_DOCUMENT(MAX)
 @PARAM PARAMETER_19    DOC_DOCUMENT.DMT_DATE_DOCUMENT(MIN)
 @PARAM PARAMETER_20    DOC_DOCUMENT.DMT_DATE_DOCUMENT(MAX)
*/
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select DOC.DMT_NUMBER
           , DOC.DMT_DATE_DOCUMENT
           , DOC.DMT_DATE_VALUE
           , STR.C_GAUGE_TITLE
           , POS.C_GAUGE_TYPE_POS
           , POS.C_DOC_POS_STATUS
           , POS.POS_FINAL_QUANTITY
           , POS.POS_FINAL_QUANTITY_SU
           , POS.DIC_UNIT_OF_MEASURE_ID
           , POS.POS_UNIT_COST_PRICE
           , POS.POS_NET_VALUE_EXCL_B
           , GOO.GCO_GOOD_ID
           , GOO.DIC_GOOD_LINE_ID
           , GOO.DIC_GOOD_FAMILY_ID
           , GOO.DIC_GOOD_MODEL_ID
           , GOO.DIC_GOOD_GROUP_ID
           , GOO.GOO_MAJOR_REFERENCE
           , GOO.GOO_NUMBER_OF_DECIMAL
           , CUS.DIC_TYPE_PARTNER_ID
           , PER.PER_NAME
           , PER.PER_KEY1
           , REP.REP_DESCR
           , THI.DIC_THIRD_ACTIVITY_ID
           , THI.DIC_THIRD_AREA_ID
           , DES.DES_SHORT_DESCRIPTION
        from DOC_DOCUMENT DOC
           , DOC_GAUGE_STRUCTURED STR
           , DOC_POSITION POS
           , GCO_GOOD GOO
           , GCO_DESCRIPTION DES
           , PAC_CUSTOM_PARTNER CUS
           , PAC_PERSON PER
           , PAC_REPRESENTATIVE REP
           , PAC_THIRD THI
       where DOC.DOC_GAUGE_ID = STR.DOC_GAUGE_ID
         and DOC.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID
         and GOO.GCO_GOOD_ID = DES.GCO_GOOD_ID
         and DES.C_DESCRIPTION_TYPE = '01'
         and DES.PC_LANG_ID = VPC_LANG_ID
         and DOC.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID
         and DOC.PAC_THIRD_ID = PER.PAC_PERSON_ID
         and DOC.PAC_THIRD_ID = THI.PAC_THIRD_ID
         and DOC.PAC_REPRESENTATIVE_ID = REP.PAC_REPRESENTATIVE_ID(+)
         and (   STR.C_GAUGE_TITLE = '8'
              or STR.C_GAUGE_TITLE = '9'
              or STR.C_GAUGE_TITLE = '30')
         and (   PARAMETER_0 = '%'
              or (PER.PER_KEY1 >= PARAMETER_0) )
         and (   PARAMETER_1 = '%'
              or (PER.PER_KEY1 <= PARAMETER_1) )
         and (POS.C_GAUGE_TYPE_POS in('1', '7', '8', '91', '10', '101') )
         and POS.C_DOC_POS_STATUS = '04'
         and (    (    DOC.DMT_DATE_DOCUMENT >= to_date(PARAMETER_17, 'YYYYMMDD')
                   and DOC.DMT_DATE_DOCUMENT <= to_date(PARAMETER_18, 'YYYYMMDD') )
              or (    DOC.DMT_DATE_DOCUMENT >= to_date(PARAMETER_19, 'YYYYMMDD')
                  and DOC.DMT_DATE_DOCUMENT <= to_date(PARAMETER_20, 'YYYYMMDD') )
             );
  end doc_can_customer_rpt_pk;

  procedure doc_can_good_rpt_pk(
    AREFCURSOR     in out Crystal_Cursor_Types.DUALCURSORTYP
  , PARAMETER_0    in     varchar2
  , PARAMETER_1    in     varchar2
  , PARAMETER_17   in     varchar2
  , PARAMETER_18   in     varchar2
  , PARAMETER_19   in     varchar2
  , PARAMETER_20   in     varchar2
  , PROCUSER_LANID in     PCS.PC_LANG.LANID%type
  )
  is
/*
 STORED PROCEDURE USED FOR THE REPORT DOC_CAN_GOOD.RPT

 @CREATED IN PROCONCEPT CHINA
 @AUTHOR MZHU
 @LASTUPDATE NOV. 29 2006
 @VERSION
 @PUBLIC
 @PARAM PARAMETER_0     GCO_GOOD.GOO_MAJOR_REFERENCE(MIN)
 @PARAM PARAMETER_1     GCO_GOOD.GOO_MAJOR_REFERENCE(MAX)
 @PARAM PARAMETER_17    DOC_DOCUMENT.DMT_DATE_DOCUMENT(MIN)
 @PARAM PARAMETER_18    DOC_DOCUMENT.DMT_DATE_DOCUMENT(MAX)
 @PARAM PARAMETER_19    DOC_DOCUMENT.DMT_DATE_DOCUMENT(MIN)
 @PARAM PARAMETER_20    DOC_DOCUMENT.DMT_DATE_DOCUMENT(MAX)
*/
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select DOC.DMT_NUMBER
           , DOC.DMT_DATE_DOCUMENT
           , DOC.DMT_DATE_VALUE
           , STR.C_GAUGE_TITLE
           , POS.C_GAUGE_TYPE_POS
           , POS.C_DOC_POS_STATUS
           , POS.POS_FINAL_QUANTITY
           , POS.POS_FINAL_QUANTITY_SU
           , POS.DIC_UNIT_OF_MEASURE_ID
           , POS.POS_UNIT_COST_PRICE
           , POS.POS_NET_VALUE_EXCL_B
           , GOO.GCO_GOOD_ID
           , GOO.DIC_GOOD_LINE_ID
           , GOO.DIC_GOOD_FAMILY_ID
           , GOO.DIC_GOOD_MODEL_ID
           , GOO.DIC_GOOD_GROUP_ID
           , GOO.GOO_MAJOR_REFERENCE
           , GOO.GOO_NUMBER_OF_DECIMAL
           , CUS.DIC_TYPE_PARTNER_ID
           , PER.PER_NAME
           , PER.PER_KEY1
           , REP.REP_DESCR
           , THI.DIC_THIRD_ACTIVITY_ID
           , THI.DIC_THIRD_AREA_ID
           , DES.DES_SHORT_DESCRIPTION
        from DOC_DOCUMENT DOC
           , DOC_GAUGE_STRUCTURED STR
           , DOC_POSITION POS
           , GCO_GOOD GOO
           , GCO_DESCRIPTION DES
           , PAC_CUSTOM_PARTNER CUS
           , PAC_PERSON PER
           , PAC_REPRESENTATIVE REP
           , PAC_THIRD THI
       where DOC.DOC_GAUGE_ID = STR.DOC_GAUGE_ID
         and DOC.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID
         and GOO.GCO_GOOD_ID = DES.GCO_GOOD_ID
         and DES.C_DESCRIPTION_TYPE = '01'
         and DES.PC_LANG_ID = VPC_LANG_ID
         and DOC.PAC_THIRD_ID = CUS.PAC_CUSTOM_PARTNER_ID
         and DOC.PAC_THIRD_ID = PER.PAC_PERSON_ID
         and DOC.PAC_THIRD_ID = THI.PAC_THIRD_ID
         and DOC.PAC_REPRESENTATIVE_ID = REP.PAC_REPRESENTATIVE_ID(+)
         and (   STR.C_GAUGE_TITLE = '8'
              or STR.C_GAUGE_TITLE = '9'
              or STR.C_GAUGE_TITLE = '30')
         and (   PARAMETER_0 = '%'
              or (GOO.GOO_MAJOR_REFERENCE >= PARAMETER_0) )
         and (   PARAMETER_1 = '%'
              or (GOO.GOO_MAJOR_REFERENCE <= PARAMETER_1) )
         and (POS.C_GAUGE_TYPE_POS in('1', '7', '8', '91', '10', '101') )
         and POS.C_DOC_POS_STATUS = '04'
         and (    (    DOC.DMT_DATE_DOCUMENT >= to_date(PARAMETER_17, 'YYYYMMDD')
                   and DOC.DMT_DATE_DOCUMENT <= to_date(PARAMETER_18, 'YYYYMMDD') )
              or (    DOC.DMT_DATE_DOCUMENT >= to_date(PARAMETER_19, 'YYYYMMDD')
                  and DOC.DMT_DATE_DOCUMENT <= to_date(PARAMETER_20, 'YYYYMMDD') )
             );
  end doc_can_good_rpt_pk;

  procedure doc_turnover_master_rpt_pk(
    arefcursor     in out crystal_cursor_types.dualcursortyp
  , parameter_0    in     varchar2
  , parameter_1    in     varchar2
  , parameter_2    in     varchar2
  , parameter_3    in     varchar2
  , parameter_4    in     varchar2
  , parameter_5    in     varchar2
  , parameter_6    in     varchar2
  , parameter_7    in     varchar2
  , parameter_8    in     varchar2
  , parameter_9    in     varchar2
  , procuser_lanid in     pcs.pc_lang.lanid%type
  , report_name    in     varchar2
  )
  is
/*
 *Description
 Stored procedure used for the reports


 Group 5 - TURNOVER BY THIRD PARTY
 DOC_CUST_TURNOVER_CUST_BATCH.RPT
 DOC_CUST_TURNOVER_GOOD_BATCH.RPT

 Group 6 - TURNOVER BY PRODUCT
 DOC_SUPPL_TURNOVER_SUPPL_BATCH.RPT
 DOC_SUPPL_TURNOVER_GOOD_BATCH.RPT




*@CREATED IN PROCONCEPT CHINA
*@AUTHOR MZHU
*@LASTUPDATE JULY 2007
*@VERSION
*@PUBLIC
*@PARAM PARAMETER_0 : FROM(PER_KEY1 or GOO_MAJOR_REFERENCE)
*@PARAM PARAMETER_1 : TO(PER_KEY1 or GOO_MAJOR_REFERENCE)
*@param PARAMETER_2 : used in Crystal report - use activity/line (yes or no)
*@param PARAMETER_3 : used in Crystal report - use region/family (yes or no)
*@param PARAMETER_4 : used in Crystal report - use partner type/group (yes or no)
*@param PARAMETER_5 : used in Crystal report - use sales person/model (yes or no)
*@PARAM PARAMETER_6 : show detail (yes, no or subtotal only)
*@PARAM PARAMETER_7 : date from
*@PARAM PARAMETER_8 : date to
*@PARAM PARAMETER_9 : gauge title (C_GAUGE_TITLE)

*/
    vpc_lang_id          pcs.pc_lang.pc_lang_id%type;
    report_names         varchar2(100);
    report_names_1       varchar2(100);
    report_names_2       varchar2(100);
    param_c_gauge_title  varchar2(30);
    param_pos_status     varchar2(30);
    param_dmt_date_start date;
    param_dmt_date_end   date;
  begin
--Initialize the name of the report
    report_names    := substr(substr(report_name, instr(report_name, '\', -1) + 1), 1, length(substr(report_name, instr(report_name, '\', -1) + 1) ) - 4);
    report_names_1  := substr(report_names, instr(report_names, '_') + 1, instr(report_names, '_', 1, 2) - instr(report_names, '_') - 1);
    report_names_2  := substr(report_names, instr(report_names, '_', -1, 2) + 1, instr(report_names, '_', -1) - instr(report_names, '_', -1, 2) - 1);

--
    if parameter_7 = '0' then
      param_dmt_date_start  := to_date(10000101, 'YYYYMMDD');
    else
      param_dmt_date_start  := to_date(parameter_7, 'YYYYMMDD');
    end if;

    if parameter_8 = '0' then
      param_dmt_date_end  := to_date(30001231, 'YYYYMMDD');
    else
      param_dmt_date_end  := to_date(parameter_8, 'YYYYMMDD');
    end if;

    if report_names in('DOC_CUST_TURNOVER_CUST_BATCH', 'DOC_CUST_TURNOVER_GOOD_BATCH') then
      case parameter_9
        when '0' then
          param_c_gauge_title  := '8,30';
        when '1' then
          param_c_gauge_title  := '8,9,30';
        when '2' then
          param_c_gauge_title  := '9';
      end case;
    elsif report_names in('DOC_SUPPL_TURNOVER_SUPPL_BATCH', 'DOC_SUPPL_TURNOVER_GOOD_BATCH') then
      param_c_gauge_title  := '4,5';
    end if;

    pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
    vpc_lang_id     := pcs.PC_I_LIB_SESSION.getuserlangid;

    open arefcursor for
      select to_char(sysdate, 'YYYYIW') year_week
           , to_char(sysdate, 'YYYYMM') year_month
           , dmt.dmt_number
           , dmt.dmt_date_document
           , dmt.dmt_rate_euro
           , dmt.dmt_base_price
           , dmt.dmt_rate_of_exchange
           , gas.c_gauge_title
           , gas.gas_financial_charge
           , pos.c_doc_pos_status
           , pos.gco_good_id
           , pos.pos_number
           , gco_functions.getdescription2(goo.gco_good_id, 3, 2, '01') des_long_description
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
                      and dit.pc_lang_id = 3)
               , PCS.PC_FUNCTIONS.TranslateWord2('Pas de ligne produit', VPC_LANG_ID)
                ) dic_good_line_descr
           ,
             --used to differentiate between lines which are null or not in crystal
             goo.dic_good_family_id
           , nvl( (select dit_descr
                     from dico_description dit
                    where dit.dit_table = 'DIC_GOOD_FAMILY'
                      and dit_code = goo.dic_good_family_id
                      and dit.pc_lang_id = 3)
               , PCS.PC_FUNCTIONS.TranslateWord2('Pas de famille produit', VPC_LANG_ID)
                ) dic_good_family_descr
           ,
             --used to differentiate between families which are null or not in crystal
             goo.dic_good_model_id
           , nvl( (select dit_descr
                     from dico_description dit
                    where dit.dit_table = 'DIC_GOOD_MODEL'
                      and dit_code = goo.dic_good_model_id
                      and dit.pc_lang_id = 3)
               , PCS.PC_FUNCTIONS.TranslateWord2('Pas de modèle produit', VPC_LANG_ID)
                ) dic_good_model_descr
           ,
             --used to differentiate between models which are null or not in crystal
             goo.dic_good_group_id
           , nvl( (select dit_descr
                     from dico_description dit
                    where dit.dit_table = 'DIC_GOOD_GROUP'
                      and dit_code = goo.dic_good_group_id
                      and dit.pc_lang_id = 3)
               , PCS.PC_FUNCTIONS.TranslateWord2('Pas de group produit', VPC_LANG_ID)
                ) dic_good_group_descr
           ,
             --used to differentiate between groups which are null or not in crystal
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
           , (select max(adr.add_address1 || '  ' || adr.add_format)
                from pac_address adr
                   , dic_address_type DAD
               where adr.pac_person_id = dmt.pac_third_id
                 and ADR.DIC_ADDRESS_TYPE_ID = DAD.DIC_ADDRESS_TYPE_ID
                 and DAD.DAD_DEFAULT = 1) inv_address
           , per.per_key1
           , thi.pac_third_id
           , thi.dic_third_activity_id
           , decode(thi.dic_third_activity_id
                  , null, PCS.PC_FUNCTIONS.TranslateWord2('Pas activité', VPC_LANG_ID)
                  , (select thi.dic_third_activity_id || ' - ' || act.act_descr
                       from dic_third_activity act
                      where act.dic_third_activity_id = thi.dic_third_activity_id)
                   ) act_descr
           , decode(thi.dic_third_area_id
                  , null, PCS.PC_FUNCTIONS.TranslateWord2('Pas de région', VPC_LANG_ID)
                  , (select thi.dic_third_area_id || ' - ' || are.are_descr
                       from dic_third_area are
                      where are.dic_third_area_id = thi.dic_third_area_id)
                   ) are_descr
           , decode(report_names_1
                  , 'CUST', decode(cus.dic_type_partner_id
                                 , null, PCS.PC_FUNCTIONS.TranslateWord2('Pas de type de partenaire', VPC_LANG_ID)
                                 , (select (select DIT.DIT_DESCR
                                              from dico_description dit
                                             where dit.dit_table = 'DIC_TYPE_PARTNER'
                                               and DIT.PC_LANG_ID = VPC_LANG_ID
                                               and DIT.DIT_CODE = dtp.dic_type_partner_id)
                                      from dic_type_partner dtp
                                     where dtp.dic_type_partner_id = cus.dic_type_partner_id)
                                  )
                  , 'SUPPL', decode(sup.dic_type_partner_f_id
                                  , null, PCS.PC_FUNCTIONS.TranslateWord2('Pas de type de partenaire', VPC_LANG_ID)
                                  , (select (select DIT.DIT_DESCR
                                               from dico_description dit
                                              where dit.dit_table = 'DIC_TYPE_PARTNER'
                                                and DIT.PC_LANG_ID = VPC_LANG_ID
                                                and DIT.DIT_CODE = dtp.dic_type_partner_f_id)
                                       from dic_type_partner_f dtp
                                      where dtp.dic_type_partner_f_id = sup.dic_type_partner_f_id)
                                   )
                   ) dic_descr
           , decode(DMT.pac_representative_id
                  , null, PCS.PC_FUNCTIONS.TranslateWord2('Pas de représentant', VPC_LANG_ID)
                  , (select rep.rep_descr
                       from pac_representative rep
                      where rep.pac_representative_id = dmt.pac_representative_id)
                   ) rep_descr
           , (select to_char(cre.cre_amount_limit)
                from pac_credit_limit cre
               where cre.pac_supplier_partner_id = dmt.pac_third_id) ||
             ' ' ||
             (select cu2.currency
                from pac_credit_limit cre
                   , acs_financial_currency acs
                   , pcs.pc_curr cu2
               where cre.pac_supplier_partner_id = dmt.pac_third_id
                 and cre.acs_financial_currency_id = acs.acs_financial_currency_id
                 and acs.pc_curr_id = cu2.pc_curr_id) cre_amount_limit
           , cur.currency
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
           , the(select cast(in_list(param_c_gauge_title) as char_table_type)
                   from dual) gauge_tile_list
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
         and check_cust_suppl(report_names_1, per.pac_person_id) = 1
         --According to report name to define customer or supplier
         and check_record_in_range(report_names_2, goo.goo_major_reference, per.per_key1, parameter_0, parameter_1) = 1
         and pos.c_doc_pos_status = '04'
         and gas.c_gauge_title = gauge_tile_list.column_value
         and dmt.dmt_date_document between param_dmt_date_start and param_dmt_date_end
         and suppl_turnover_batch(report_names, parameter_9, gas.c_gauge_title, gas.gas_financial_charge) = 1;
  end doc_turnover_master_rpt_pk;

  procedure doc_due_date_master_rpt_pk(
    arefcursor     in out crystal_cursor_types.dualcursortyp
  , parameter_0    in     varchar2
  , parameter_1    in     varchar2
  , parameter_2    in     varchar2
  , parameter_3    in     varchar2
  , parameter_4    in     varchar2
  , parameter_5    in     varchar2
  , parameter_6    in     varchar2
  , parameter_7    in     varchar2
  , parameter_8    in     varchar2
  , parameter_9    in     varchar2
  , parameter_10   in     varchar2
  , parameter_11   in     varchar2
  , parameter_12   in     varchar2
  , parameter_13   in     varchar2
  , parameter_14   in     varchar2
  , parameter_15   in     varchar2
  , procuser_lanid in     pcs.pc_lang.lanid%type
  , report_name    in     varchar2
  )
  is
/*
*Description
 Used for the reports

   Group 3 - DUE DATE BY THIRD PARTY
   Master -   DOC_DUE_DATE_THIRD_PARTY_MASTER
   DOC_CUST_ECHEANCIER_CUST_BATCH
   DOC_SUPPL_ECHEANCIER_SUPPL_BATCH
   Created 27th March 2008 - PNA


*/
    vpc_lang_id          pcs.pc_lang.pc_lang_id%type;
    report_names         varchar2(100);
    report_names_1       varchar2(100);
    report_names_2       varchar2(100);
    param_c_gauge_title  varchar2(30);
    param_pos_status     varchar2(30);
    param_doc_status     varchar2(30);
    param_dmt_date_start date;
    param_dmt_date_end   date;
    param_final_delay    date;
  begin
--Initialize the name of the report
    report_names    := substr(substr(report_name, instr(report_name, '\', -1) + 1), 1, length(substr(report_name, instr(report_name, '\', -1) + 1) ) - 4);
    report_names_1  := substr(report_names, instr(report_names, '_') + 1, instr(report_names, '_', 1, 2) - instr(report_names, '_') - 1);
    report_names_2  := substr(report_names, instr(report_names, '_', -1, 2) + 1, instr(report_names, '_', -1) - instr(report_names, '_', -1, 2) - 1);

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
    vpc_lang_id     := pcs.PC_I_LIB_SESSION.getuserlangid;

    open arefcursor for
      select to_char(sysdate, 'YYYYIW') year_week
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
           , gco_functions.getdescription2(goo.gco_good_id, 3, 2, '01') des_long_description
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
                      and dit.pc_lang_id = 3)
               , PCS.PC_FUNCTIONS.TranslateWord2('Pas de ligne produit', VPC_LANG_ID)
                ) dic_good_line_descr
           ,
             --&&  to differentiate  lines which are null or not in crystal
             goo.dic_good_family_id
           , nvl( (select dit_descr
                     from dico_description dit
                    where dit.dit_table = 'DIC_GOOD_FAMILY'
                      and dit_code = goo.dic_good_family_id
                      and dit.pc_lang_id = 3)
               , PCS.PC_FUNCTIONS.TranslateWord2('Pas de famille produit', VPC_LANG_ID)
                ) dic_good_family_descr
           ,
--&&  to differentiate between families which are null or not in crystal
             goo.dic_good_model_id
           , nvl( (select dit_descr
                     from dico_description dit
                    where dit.dit_table = 'DIC_GOOD_MODEL'
                      and dit_code = goo.dic_good_model_id
                      and dit.pc_lang_id = 3)
               , PCS.PC_FUNCTIONS.TranslateWord2('Pas de modèle produit', VPC_LANG_ID)
                ) dic_good_model_descr
           ,
             --&&  to differentiate between models which are null or not in crystal
             goo.dic_good_group_id
           , nvl( (select dit_descr
                     from dico_description dit
                    where dit.dit_table = 'DIC_GOOD_GROUP'
                      and dit_code = goo.dic_good_group_id
                      and dit.pc_lang_id = 3)
               , PCS.PC_FUNCTIONS.TranslateWord2('Pas de groupe produit', VPC_LANG_ID)
                ) dic_good_group_descr
           ,
             --&&  to differentiate between groups which are null or not in crystal
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
                 and adr.dic_address_type_id = 'Inv') inv_address
           , per.per_key1
           , thi.pac_third_id
           , thi.dic_third_activity_id
           , decode(thi.dic_third_activity_id
                  , null, PCS.PC_FUNCTIONS.TranslateWord2('Pas activité', VPC_LANG_ID)
                  , (select thi.dic_third_activity_id || ' - ' || act.act_descr
                       from dic_third_activity act
                      where act.dic_third_activity_id = thi.dic_third_activity_id)
                   ) act_descr
           , decode(thi.dic_third_area_id
                  , null, PCS.PC_FUNCTIONS.TranslateWord2('Pas de région', VPC_LANG_ID)
                  , (select thi.dic_third_area_id || ' - ' || are.are_descr
                       from dic_third_area are
                      where are.dic_third_area_id = thi.dic_third_area_id)
                   ) are_descr
           , decode(report_names_1
                  , 'CUST', decode(cus.dic_type_partner_id
                                 , null, PCS.PC_FUNCTIONS.TranslateWord2('Pas de type de partenaire', VPC_LANG_ID)
                                 , (select (select DIT.DIT_DESCR
                                              from dico_description dit
                                             where dit.dit_table = 'DIC_TYPE_PARTNER'
                                               and DIT.PC_LANG_ID = VPC_LANG_ID
                                               and DIT.DIT_CODE = dtp.dic_type_partner_id)
                                      from dic_type_partner dtp
                                     where dtp.dic_type_partner_id = cus.dic_type_partner_id)
                                  )
                  , 'SUPPL', decode(sup.dic_type_partner_f_id
                                  , null, PCS.PC_FUNCTIONS.TranslateWord2('Pas de type de partenaire', VPC_LANG_ID)
                                  , (select (select DIT.DIT_DESCR
                                               from dico_description dit
                                              where dit.dit_table = 'DIC_TYPE_PARTNER'
                                                and DIT.PC_LANG_ID = VPC_LANG_ID
                                                and DIT.DIT_CODE = dtp.dic_type_partner_f_id)
                                       from dic_type_partner_f dtp
                                      where dtp.dic_type_partner_f_id = sup.dic_type_partner_f_id)
                                   )
                   ) dic_descr
           , decode(DMT.pac_representative_id
                  , null, PCS.PC_FUNCTIONS.TranslateWord2('Pas de représentant', VPC_LANG_ID)
                  , (select rep.rep_descr
                       from pac_representative rep
                      where rep.pac_representative_id = dmt.pac_representative_id)
                   ) rep_descr
           , (select to_char(cre.cre_amount_limit)
                from pac_credit_limit cre
               where cre.pac_supplier_partner_id = dmt.pac_third_id) ||
             ' ' ||
             (select cu2.currency
                from pac_credit_limit cre
                   , acs_financial_currency acs
                   , pcs.pc_curr cu2
               where cre.pac_supplier_partner_id = dmt.pac_third_id
                 and cre.acs_financial_currency_id = acs.acs_financial_currency_id
                 and acs.pc_curr_id = cu2.pc_curr_id) cre_amount_limit
           , cur.currency
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
           , the(select cast(in_list(param_c_gauge_title) as char_table_type)
                   from dual) gauge_tile_list
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
         and check_cust_suppl(report_names_1, per.pac_person_id) = 1
         --According to report name to define customer or supplier
         and check_record_in_range(report_names_2, goo.goo_major_reference, per.per_key1, parameter_0, parameter_1) = 1
         and pos.c_doc_pos_status in('01', '02', '03', '04')
         and gas.c_gauge_title = gauge_tile_list.column_value
         and c_document_status in('01', '02', '03')
         --{@TEST_RETARD} Lateness
         and order_echeancier_batch(report_names, param_final_delay, pde.pde_final_delay, gas.c_gauge_title) = 1;
  end doc_due_date_master_rpt_pk;

  procedure doc_port_3rd_par_master_rpt_pk(
    arefcursor     in out crystal_cursor_types.dualcursortyp
  , parameter_0    in     varchar2
  , parameter_1    in     varchar2
  , parameter_2    in     varchar2
  , parameter_3    in     varchar2
  , parameter_4    in     varchar2
  , parameter_5    in     varchar2
  , parameter_6    in     varchar2
  , parameter_7    in     varchar2
  , parameter_8    in     varchar2
  , parameter_9    in     varchar2
  , parameter_10   in     varchar2
  , parameter_11   in     varchar2
  , parameter_12   in     varchar2
  , parameter_13   in     varchar2
  , parameter_14   in     varchar2
  , parameter_15   in     varchar2
  , procuser_lanid in     pcs.pc_lang.lanid%type
  , report_name    in     varchar2
  )
  is
/*
*Description
 Used for the reports

 Group 1 - PORTFOLIO BY THIRD PARTY
 DOC_CUST_ORDER_PORT_CUST_BATCH
 DOC_CUST_CONSIG_PORT_CUST_BATCH
 DOC_CUST_DELIVERY_PORT_CUST_BATCH
 DOC_SUPPL_ORDER_PORT_SUPPL_BATCH
 DOC_SUPPL_DELIVERY_PORT_SUPPL_BATCH

 Group 2 - PORTFOLIO BY PRODUCT
 DOC_CUST_ORDER_PORT_GOOD_BATCH
 DOC_CUST_CONSIG_PORT_GOOD_BATCH
 DOC_CUST_DELIVERY_PORT_GOOD_BATCH
 DOC_SUPPL_ORDER_PORT_GOOD_BATCH
 DOC_SUPPL_DELIVERY_PORT_GOOD_BATCH

 Group 3 - DUE DATE BY THIRD PARTY
 DOC_CUST_ECHEANCIER_CUST_BATCH
 DOC_SUPPL_ECHEANCIER_SUPPL_BATCH

 Group 4 - DUE DATE BY PRODUCT
 DOC_CUST_ECHEANCIER_GOOD_BATCH
 DOC_SUPPL_ECHEANCIER_GOOD_BATCH

*@created PNA 06.2007
*@lastUpdate MZHU 07.2007
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

 STORED PROCEDURE USED FOR THE REPORTS

   Group 1 - PORTFOLIO BY THIRD PARTY
   DOC_CUST_ORDER_PORT_CUST_BATCH
   DOC_CUST_CONSIG_PORT_CUST_BATCH
   DOC_CUST_DELIVERY_PORT_CUST_BATCH
   DOC_SUPPL_ORDER_PORT_SUPPL_BATCH
   DOC_SUPPL_DELIVERY_PORT_SUPPL_BATCH

   Group 2 - PORTFOLIO BY PRODUCT
   DOC_CUST_ORDER_PORT_GOOD_BATCH
   DOC_CUST_CONSIG_PORT_GOOD_BATCH
   DOC_CUST_DELIVERY_PORT_GOOD_BATCH
   DOC_SUPPL_ORDER_PORT_GOOD_BATCH
   DOC_SUPPL_DELIVERY_PORT_GOOD_BATCH

   Group 3 - DUE DATE BY THIRD PARTY
   DOC_CUST_ECHEANCIER_CUST_BATCH
   DOC_SUPPL_ECHEANCIER_SUPPL_BATCH

   Group 4 - DUE DATE BY PRODUCT
   DOC_CUST_ECHEANCIER_GOOD_BATCH
   DOC_SUPPL_ECHEANCIER_GOOD_BATCH
*/
    vpc_lang_id          pcs.pc_lang.pc_lang_id%type;
    report_names         varchar2(100 char);
    report_names_1       varchar2(100 char);
    report_names_2       varchar2(100 char);
    param_c_gauge_title  varchar2(30 char);
    param_pos_status     varchar2(30 char);
    param_doc_status     varchar2(30 char);
    param_dmt_date_start date;
    param_dmt_date_end   date;
    param_final_delay    date;
    param_0              varchar2(30 char);
    param_1              varchar2(30 char);
    param_6              varchar2(8 char);
    param_9              varchar2(1 char);
    PARAM_10             varchar2(1 char);
    PARAM_11             varchar2(30 char);
    PARAM_12             varchar2(30 char);
    PARAM_13             varchar2(30 char);
    PARAM_14             varchar2(8 char);
    PARAM_15             varchar2(8 char);
  begin
--Initialize the parameter, remove all the space in the parameter
    param_0         := trim(parameter_0);
    param_1         := trim(parameter_1);
    param_6         := trim(parameter_6);
    param_9         := trim(parameter_9);
    param_10        := trim(parameter_10);
    param_11        := trim(parameter_11);
    param_12        := trim(parameter_12);
    param_13        := trim(parameter_13);
    param_14        := trim(parameter_14);
    param_15        := trim(parameter_15);
--Initialize the name of the report
    report_names    := substr(substr(report_name, instr(report_name, '\', -1) + 1), 1, length(substr(report_name, instr(report_name, '\', -1) + 1) ) - 4);
    report_names_1  := substr(report_names, instr(report_names, '_') + 1, instr(report_names, '_', 1, 2) - instr(report_names, '_') - 1);
    report_names_2  := substr(report_names, instr(report_names, '_', -1, 2) + 1, instr(report_names, '_', -1) - instr(report_names, '_', -1, 2) - 1);

--Final delay for detail information of document
    begin
      if param_6 = '0' then
        param_final_delay  := to_date('22001231', 'YYYYMMDD');
      else
        param_final_delay  := to_date(param_6, 'YYYYMMDD');
      end if;
    exception
      when others then
        param_final_delay  := to_date('22001231', 'YYYYMMDD');
    end;

    if report_names in('DOC_CUST_ORDER_PORT_CUST_BATCH', 'DOC_CUST_ORDER_PORT_GOOD_BATCH') then
      case param_9
        when '0' then
          param_c_gauge_title  := '6,30';
        when '1' then
          param_c_gauge_title  := '6';
        when '2' then
          param_c_gauge_title  := '30';
      end case;

      case param_10
        when 0 then
          param_pos_status  := '01,02,03,04';   --All
        when 1 then
          param_pos_status  := '01';   --To Confirm
        when 2 then
          param_pos_status  := '02,03';   --To Balance and Partially Balanced
        when 3 then
          param_pos_status  := '01,02,03';
        --To Confirm, To Balance and Partially Balanced
      when 4 then
          param_pos_status  := '04';   --Finished
        when 5 then
          param_pos_status  := '01,04';   --To Confirm and Finished
        when 6 then
          param_pos_status  := '02,03,04';
        --To Balance and Partially Balanced and Finished
      when 7 then
          param_pos_status  := '01,02,03,04';   --All
      end case;

      param_doc_status      := '01,02,03,04,05';
      param_dmt_date_start  := to_date(19800101, 'YYYYMMDD');
      param_dmt_date_end    := to_date(22001231, 'YYYYMMDD');
    elsif report_names = 'DOC_CUST_CONSIG_PORT_CUST_BATCH' then
      param_c_gauge_title   := '20';
      param_pos_status      := '02,03';
      param_doc_status      := '02,03';
      param_dmt_date_start  := to_date(19800101, 'YYYYMMDD');
      param_dmt_date_end    := to_date(22001231, 'YYYYMMDD');
    elsif report_names = 'DOC_CUST_CONSIG_PORT_GOOD_BATCH' then
      param_c_gauge_title   := '20';
      param_pos_status      := '02,03';
      param_doc_status      := '01,02,03,04,05';
      param_dmt_date_start  := to_date(19800101, 'YYYYMMDD');
      param_dmt_date_end    := to_date(22001231, 'YYYYMMDD');
    elsif report_names in('DOC_CUST_DELIVERY_PORT_CUST_BATCH', 'DOC_CUST_DELIVERY_PORT_GOOD_BATCH') then
      param_c_gauge_title  := '7';

      case param_10
        when 0 then
          param_pos_status  := '01,02,03,04';   --All
        when 1 then
          param_pos_status  := '01';   --To Confirm
        when 2 then
          param_pos_status  := '02,03';   --To Balance and Partially Balanced
        when 3 then
          param_pos_status  := '01,02,03';
        --To Confirm, To Balance and Partially Balanced
      when 4 then
          param_pos_status  := '04';   --Finished
        when 5 then
          param_pos_status  := '01,04';   --To Confirm and Finished
        when 6 then
          param_pos_status  := '02,03,04';
        --To Balance and Partially Balanced and Finished
      when 7 then
          param_pos_status  := '01,02,03,04';   --All
      end case;

      param_doc_status     := '01,02,03,04,05';

      begin
        if param_14 = '0' then
          param_dmt_date_start  := to_date(19800101, 'YYYYMMDD');
        else
          param_dmt_date_start  := to_date(param_14, 'YYYYMMDD');   -- parameter_14  ************************************
        end if;
      exception
        when others then
          param_dmt_date_start  := to_date('19801231', 'YYYYMMDD');
      end;

      begin
        if param_15 = '0' then
          param_dmt_date_end  := to_date(22001231, 'YYYYMMDD');
        else
          param_dmt_date_end  := to_date(param_15, 'YYYYMMDD');   -- parameter_15  ************************************
        end if;
      exception
        when others then
          param_dmt_date_end  := to_date('22001231', 'YYYYMMDD');
      end;
    elsif report_names in('DOC_SUPPL_ORDER_PORT_SUPPL_BATCH', 'DOC_SUPPL_ORDER_PORT_GOOD_BATCH') then
      case param_9
        when '0' then
          param_c_gauge_title  := '1,5';   --both order and return
        when '1' then
          param_c_gauge_title  := '1';   --only order
        when '2' then
          param_c_gauge_title  := '5';   --only return
      end case;

      case param_10
        when 0 then
          param_pos_status  := '01,02,03,04';   --All
        when 1 then
          param_pos_status  := '01';   --To Confirm
        when 2 then
          param_pos_status  := '02,03';   --To Balance and Partially Balanced
        when 3 then
          param_pos_status  := '01,02,03';
        --To Confirm, To Balance and Partially Balanced
      when 4 then
          param_pos_status  := '04';   --Finished
        when 5 then
          param_pos_status  := '01,04';   --To Confirm and Finished
        when 6 then
          param_pos_status  := '02,03,04';
        --To Balance and Partially Balanced and Finished
      when 7 then
          param_pos_status  := '01,02,03,04';   --All
      end case;

      param_doc_status      := '01,02,03,04,05';
      param_dmt_date_start  := to_date(19800101, 'YYYYMMDD');
      param_dmt_date_end    := to_date(22001231, 'YYYYMMDD');
    elsif report_names in('DOC_SUPPL_DELIVERY_PORT_SUPPL_BATCH', 'DOC_SUPPL_DELIVERY_PORT_GOOD_BATCH') then
      param_c_gauge_title  := '2,3';

      case param_10
        when 0 then
          param_pos_status  := '01,02,03,04';   --All
        when 1 then
          param_pos_status  := '01';   --To Confirm
        when 2 then
          param_pos_status  := '02,03';   --To Balance and Partially Balanced
        when 3 then
          param_pos_status  := '01,02,03';
        --To Confirm, To Balance and Partially Balanced
      when 4 then
          param_pos_status  := '04';   --Finished
        when 5 then
          param_pos_status  := '01,04';   --To Confirm and Finished
        when 6 then
          param_pos_status  := '02,03,04';
        --To Balance and Partially Balanced and Finished
      when 7 then
          param_pos_status  := '01,02,03,04';   --All
      end case;

      param_doc_status     := '01,02,03,04,05';

      begin
        if param_14 = '0' then
          param_dmt_date_start  := to_date(19800101, 'YYYYMMDD');
        else
          param_dmt_date_start  := to_date(param_14, 'YYYYMMDD');   -- parameter_14  ************************************
        end if;
      exception
        when others then
          param_dmt_date_start  := to_date('19801231', 'YYYYMMDD');
      end;

      begin
        if param_15 = '0' then
          param_dmt_date_end  := to_date(22001231, 'YYYYMMDD');
        else
          param_dmt_date_end  := to_date(param_15, 'YYYYMMDD');   -- parameter_15  ************************************
        end if;
      exception
        when others then
          param_dmt_date_end  := to_date('22001231', 'YYYYMMDD');
      end;
    end if;

    pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
    vpc_lang_id     := pcs.PC_I_LIB_SESSION.getuserlangid;

    open arefcursor for
      select to_char(sysdate, 'YYYYIW') year_week
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
           , gco_functions.getdescription2(goo.gco_good_id, 3, 2, '01') des_long_description
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
                      and dit.pc_lang_id = 3)
               , PCS.PC_FUNCTIONS.TranslateWord2('Pas de ligne produit', VPC_LANG_ID)
                ) dic_good_line_descr
           ,
             --&&  to differentiate  lines which are null or not in crystal
             goo.dic_good_family_id
           , nvl( (select dit_descr
                     from dico_description dit
                    where dit.dit_table = 'DIC_GOOD_FAMILY'
                      and dit_code = goo.dic_good_family_id
                      and dit.pc_lang_id = 3)
               , PCS.PC_FUNCTIONS.TranslateWord2('Pas de famille produit', VPC_LANG_ID)
                ) dic_good_family_descr
           ,
--&&  to differentiate between families which are null or not in crystal
             goo.dic_good_model_id
           , nvl( (select dit_descr
                     from dico_description dit
                    where dit.dit_table = 'DIC_GOOD_MODEL'
                      and dit_code = goo.dic_good_model_id
                      and dit.pc_lang_id = 3)
               , PCS.PC_FUNCTIONS.TranslateWord2('Pas de modèle produit', VPC_LANG_ID)
                ) dic_good_model_descr
           ,
             --&&  to differentiate between models which are null or not in crystal
             goo.dic_good_group_id
           , nvl( (select dit_descr
                     from dico_description dit
                    where dit.dit_table = 'DIC_GOOD_GROUP'
                      and dit_code = goo.dic_good_group_id
                      and dit.pc_lang_id = 3)
               , PCS.PC_FUNCTIONS.TranslateWord2('Pas de groupe produit', VPC_LANG_ID)
                ) dic_good_group_descr
           ,
             --&&  to differentiate between groups which are null or not in crystal
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
                 and adr.dic_address_type_id = 'Inv') inv_address
           , per.per_key1
           , thi.pac_third_id
           , decode(thi.dic_third_activity_id
                  , null, PCS.PC_FUNCTIONS.TranslateWord2('Pas activité', VPC_LANG_ID)
                  , (select thi.dic_third_activity_id || ' - ' || act.act_descr
                       from dic_third_activity act
                      where act.dic_third_activity_id = thi.dic_third_activity_id)
                   ) act_descr
           , decode(thi.dic_third_area_id
                  , null, PCS.PC_FUNCTIONS.TranslateWord2('Pas de région', VPC_LANG_ID)
                  , (select thi.dic_third_area_id || ' - ' || are.are_descr
                       from dic_third_area are
                      where are.dic_third_area_id = thi.dic_third_area_id)
                   ) are_descr
           ,
             --DECODE (report_names_1,
              --        'CUST', cus.dic_type_partner_id,
              --       'SUPPL', sup.dic_type_partner_f_id
              --      ) dic_type_partner_id,
             decode(report_names_1
                  , 'CUST', decode(cus.dic_type_partner_id
                                 , null, PCS.PC_FUNCTIONS.TranslateWord2('Pas de type de partenaire', VPC_LANG_ID)
                                 , (select (select DIT.DIT_DESCR
                                              from dico_description dit
                                             where dit.dit_table = 'DIC_TYPE_PARTNER'
                                               and DIT.PC_LANG_ID = VPC_LANG_ID
                                               and DIT.DIT_CODE = dtp.dic_type_partner_id)
                                      from dic_type_partner dtp
                                     where dtp.dic_type_partner_id = cus.dic_type_partner_id)
                                  )
                  , 'SUPPL', decode(sup.dic_type_partner_f_id
                                  , null, PCS.PC_FUNCTIONS.TranslateWord2('Pas de type de partenaire', VPC_LANG_ID)
                                  , (select (select DIT.DIT_DESCR
                                               from dico_description dit
                                              where dit.dit_table = 'DIC_TYPE_PARTNER'
                                                and DIT.PC_LANG_ID = VPC_LANG_ID
                                                and DIT.DIT_CODE = dtp.dic_type_partner_f_id)
                                       from dic_type_partner_f dtp
                                      where dtp.dic_type_partner_f_id = sup.dic_type_partner_f_id)
                                   )
                   ) dic_descr
           , decode(DMT.pac_representative_id
                  , null, PCS.PC_FUNCTIONS.TranslateWord2('Pas de représentant', VPC_LANG_ID)
                  , (select rep.rep_descr
                       from pac_representative rep
                      where rep.pac_representative_id = dmt.pac_representative_id)
                   ) rep_descr
           , (select to_char(cre.cre_amount_limit)
                from pac_credit_limit cre
               where cre.pac_supplier_partner_id = dmt.pac_third_id) ||
             ' ' ||
             (select cu2.currency
                from pac_credit_limit cre
                   , acs_financial_currency acs
                   , pcs.pc_curr cu2
               where cre.pac_supplier_partner_id = dmt.pac_third_id
                 and cre.acs_financial_currency_id = acs.acs_financial_currency_id
                 and acs.pc_curr_id = cu2.pc_curr_id) cre_amount_limit
           , cur.currency
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
           , the(select cast(in_list(param_pos_status) as char_table_type)
                   from dual) pos_status_list
           , the(select cast(in_list(param_c_gauge_title) as char_table_type)
                   from dual) gauge_tile_list
           , the(select cast(in_list(param_doc_status) as char_table_type)
                   from dual) doc_status_list
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
         and check_cust_suppl(report_names_1, per.pac_person_id) = 1
         --According to report name to define customer or supplier
         and check_record_in_range(report_names_2, goo.goo_major_reference, per.per_key1, param_0, param_1) = 1
         and pos.c_doc_pos_status = pos_status_list.column_value
         and gas.c_gauge_title = gauge_tile_list.column_value
         and dmt.c_document_status = doc_status_list.column_value
         and dmt.dmt_date_document >= param_dmt_date_start
         and dmt.dmt_date_document <= param_dmt_date_end
         --{@TEST_ATTRIB} Allocation
         and cust_order_port_batch(report_names, param_11, fnn.fan_stk_qty, fnn.fan_netw_qty) = 1
         --{@TEST_COLIS} Packaging
         and cust_delivery_port_batch(report_names, param_12, dmt.doc_document_id) = 1
         --{@TEST_ATTRIB} Allocation
         and suppl_order_port_batch(report_names, param_11, fns.fan_stk_qty, fns.fan_netw_qty) = 1
         --{@TEST_RETARD} Lateness
         and suppl_order_port_batch_2(report_names, param_13, pos.c_doc_pos_status, pde.pde_final_delay) = 1
         and order_echeancier_batch(report_names, param_final_delay, pde.pde_final_delay, gas.c_gauge_title) = 1;
  end doc_port_3rd_par_master_rpt_pk;

  procedure doc_port_good_master_rpt_pk(
    arefcursor     in out crystal_cursor_types.dualcursortyp
  , parameter_0    in     varchar2
  , parameter_1    in     varchar2
  , parameter_2    in     varchar2
  , parameter_3    in     varchar2
  , parameter_4    in     varchar2
  , parameter_5    in     varchar2
  , parameter_6    in     varchar2
  , parameter_7    in     varchar2
  , parameter_8    in     varchar2
  , parameter_9    in     varchar2
  , parameter_10   in     varchar2
  , parameter_11   in     varchar2
  , parameter_12   in     varchar2
  , parameter_13   in     varchar2
  , parameter_14   in     varchar2
  , parameter_15   in     varchar2
  , procuser_lanid in     pcs.pc_lang.lanid%type
  , report_name    in     varchar2
  )
  is
/*
*Description
 Used for the reports

 Group 1 - PORTFOLIO BY THIRD PARTY
 DOC_CUST_ORDER_PORT_CUST_BATCH
 DOC_CUST_CONSIG_PORT_CUST_BATCH
 DOC_CUST_DELIVERY_PORT_CUST_BATCH
 DOC_SUPPL_ORDER_PORT_SUPPL_BATCH
 DOC_SUPPL_DELIVERY_PORT_SUPPL_BATCH

 Group 2 - PORTFOLIO BY PRODUCT
 DOC_CUST_ORDER_PORT_GOOD_BATCH
 DOC_CUST_CONSIG_PORT_GOOD_BATCH
 DOC_CUST_DELIVERY_PORT_GOOD_BATCH
 DOC_SUPPL_ORDER_PORT_GOOD_BATCH
 DOC_SUPPL_DELIVERY_PORT_GOOD_BATCH

 Group 3 - DUE DATE BY THIRD PARTY
 DOC_CUST_ECHEANCIER_CUST_BATCH
 DOC_SUPPL_ECHEANCIER_SUPPL_BATCH

 Group 4 - DUE DATE BY PRODUCT
 DOC_CUST_ECHEANCIER_GOOD_BATCH
 DOC_SUPPL_ECHEANCIER_GOOD_BATCH

*@created PNA 06.2007
*@lastUpdate MZHU 07.2007
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

 STORED PROCEDURE USED FOR THE REPORTS

   Group 1 - PORTFOLIO BY THIRD PARTY
   DOC_CUST_ORDER_PORT_CUST_BATCH
   DOC_CUST_CONSIG_PORT_CUST_BATCH
   DOC_CUST_DELIVERY_PORT_CUST_BATCH
   DOC_SUPPL_ORDER_PORT_SUPPL_BATCH
   DOC_SUPPL_DELIVERY_PORT_SUPPL_BATCH

   Group 2 - PORTFOLIO BY PRODUCT
   DOC_CUST_ORDER_PORT_GOOD_BATCH
   DOC_CUST_CONSIG_PORT_GOOD_BATCH
   DOC_CUST_DELIVERY_PORT_GOOD_BATCH
   DOC_SUPPL_ORDER_PORT_GOOD_BATCH
   DOC_SUPPL_DELIVERY_PORT_GOOD_BATCH

   Group 3 - DUE DATE BY THIRD PARTY
   DOC_CUST_ECHEANCIER_CUST_BATCH
   DOC_SUPPL_ECHEANCIER_SUPPL_BATCH

   Group 4 - DUE DATE BY PRODUCT
   DOC_CUST_ECHEANCIER_GOOD_BATCH
   DOC_SUPPL_ECHEANCIER_GOOD_BATCH
*/
    vpc_lang_id          pcs.pc_lang.pc_lang_id%type;
    report_names         varchar2(100);
    report_names_1       varchar2(100);
    report_names_2       varchar2(100);
    param_c_gauge_title  varchar2(30);
    param_pos_status     varchar2(30);
    param_doc_status     varchar2(30);
    param_dmt_date_start date;
    param_dmt_date_end   date;
    param_final_delay    date;
  begin
--Initialize the name of the report
    report_names    := substr(substr(report_name, instr(report_name, '\', -1) + 1), 1, length(substr(report_name, instr(report_name, '\', -1) + 1) ) - 4);
    report_names_1  := substr(report_names, instr(report_names, '_') + 1, instr(report_names, '_', 1, 2) - instr(report_names, '_') - 1);
    report_names_2  := substr(report_names, instr(report_names, '_', -1, 2) + 1, instr(report_names, '_', -1) - instr(report_names, '_', -1, 2) - 1);

--
    begin
      if parameter_6 = '0' then
        param_final_delay  := to_date('22001231', 'YYYYMMDD');
      else
        param_final_delay  := to_date(parameter_6, 'YYYYMMDD');
      end if;
    exception
      when others then
        param_final_delay  := to_date('22001231', 'YYYYMMDD');
    end;

    if report_names in('DOC_CUST_ORDER_PORT_CUST_BATCH', 'DOC_CUST_ORDER_PORT_GOOD_BATCH') then
      case parameter_9
        when '0' then
          param_c_gauge_title  := '6,30';
        when '1' then
          param_c_gauge_title  := '6';
        when '2' then
          param_c_gauge_title  := '30';
      end case;

      case parameter_10
        when 0 then
          param_pos_status  := '01,02,03,04';   --All
        when 1 then
          param_pos_status  := '01';   --To Confirm
        when 2 then
          param_pos_status  := '02,03';   --To Balance and Partially Balanced
        when 3 then
          param_pos_status  := '01,02,03';
        --To Confirm, To Balance and Partially Balanced
      when 4 then
          param_pos_status  := '04';   --Finished
        when 5 then
          param_pos_status  := '01,04';   --To Confirm and Finished
        when 6 then
          param_pos_status  := '02,03,04';
        --To Balance and Partially Balanced and Finished
      when 7 then
          param_pos_status  := '01,02,03,04';   --All
      end case;

      param_doc_status      := '01,02,03,04,05';
      param_dmt_date_start  := to_date(19800101, 'YYYYMMDD');
      param_dmt_date_end    := to_date(22001231, 'YYYYMMDD');
    elsif report_names in('DOC_CUST_ECHEANCIER_CUST_BATCH', 'DOC_CUST_ECHEANCIER_GOOD_BATCH') then
      case parameter_9
        when '0' then
          param_c_gauge_title  := '6,30';
        when '1' then
          param_c_gauge_title  := '6';
        when '2' then
          param_c_gauge_title  := '30';
      end case;

      param_pos_status      := '01,02,03,04';
      param_doc_status      := '01,02,03';
      param_dmt_date_start  := to_date(19800101, 'YYYYMMDD');
      param_dmt_date_end    := to_date(22001231, 'YYYYMMDD');
    elsif report_names = 'DOC_CUST_CONSIG_PORT_CUST_BATCH' then
      param_c_gauge_title   := '20';
      param_pos_status      := '02,03';
      param_doc_status      := '02,03';
      param_dmt_date_start  := to_date(19800101, 'YYYYMMDD');
      param_dmt_date_end    := to_date(22001231, 'YYYYMMDD');
    elsif report_names = 'DOC_CUST_CONSIG_PORT_GOOD_BATCH' then
      param_c_gauge_title   := '20';
      param_pos_status      := '02,03';
      param_doc_status      := '01,02,03,04,05';
      param_dmt_date_start  := to_date(19800101, 'YYYYMMDD');
      param_dmt_date_end    := to_date(22001231, 'YYYYMMDD');
    elsif report_names in('DOC_CUST_DELIVERY_PORT_CUST_BATCH', 'DOC_CUST_DELIVERY_PORT_GOOD_BATCH') then
      param_c_gauge_title  := '7';

      case parameter_10
        when 0 then
          param_pos_status  := '01,02,03,04';   --All
        when 1 then
          param_pos_status  := '01';   --To Confirm
        when 2 then
          param_pos_status  := '02,03';   --To Balance and Partially Balanced
        when 3 then
          param_pos_status  := '01,02,03';
        --To Confirm, To Balance and Partially Balanced
      when 4 then
          param_pos_status  := '04';   --Finished
        when 5 then
          param_pos_status  := '01,04';   --To Confirm and Finished
        when 6 then
          param_pos_status  := '02,03,04';
        --To Balance and Partially Balanced and Finished
      when 7 then
          param_pos_status  := '01,02,03,04';   --All
      end case;

      param_doc_status     := '01,02,03,04,05';

      begin
        if parameter_14 = '0' then
          param_dmt_date_start  := to_date(19800101, 'YYYYMMDD');
        else
          param_dmt_date_start  := to_date(parameter_14, 'YYYYMMDD');   -- parameter_14  ************************************
        end if;
      exception
        when others then
          param_dmt_date_start  := to_date('19801231', 'YYYYMMDD');
      end;

      begin
        if parameter_15 = '0' then
          param_dmt_date_end  := to_date(22001231, 'YYYYMMDD');
        else
          param_dmt_date_end  := to_date(parameter_14, 'YYYYMMDD');   -- parameter_15  ************************************
        end if;
      exception
        when others then
          param_dmt_date_end  := to_date('22001231', 'YYYYMMDD');
      end;
    elsif report_names in('DOC_SUPPL_ORDER_PORT_SUPPL_BATCH', 'DOC_SUPPL_ORDER_PORT_GOOD_BATCH') then
      case parameter_9
        when '0' then
          param_c_gauge_title  := '1,5';   --both order and return
        when '1' then
          param_c_gauge_title  := '1';   --only order
        when '2' then
          param_c_gauge_title  := '5';   --only return
      end case;

      case parameter_10
        when 0 then
          param_pos_status  := '01,02,03,04';   --All
        when 1 then
          param_pos_status  := '01';   --To Confirm
        when 2 then
          param_pos_status  := '02,03';   --To Balance and Partially Balanced
        when 3 then
          param_pos_status  := '01,02,03';
        --To Confirm, To Balance and Partially Balanced
      when 4 then
          param_pos_status  := '04';   --Finished
        when 5 then
          param_pos_status  := '01,04';   --To Confirm and Finished
        when 6 then
          param_pos_status  := '02,03,04';
        --To Balance and Partially Balanced and Finished
      when 7 then
          param_pos_status  := '01,02,03,04';   --All
      end case;

      param_doc_status      := '01,02,03,04,05';
      param_dmt_date_start  := to_date(19800101, 'YYYYMMDD');
      param_dmt_date_end    := to_date(22001231, 'YYYYMMDD');
    elsif report_names in('DOC_SUPPL_ECHEANCIER_SUPPL_BATCH', 'DOC_SUPPL_ECHEANCIER_GOOD_BATCH') then
      case parameter_9
        when '0' then
          param_c_gauge_title  := '1,5';
        when '1' then
          param_c_gauge_title  := '1';
        when '2' then
          param_c_gauge_title  := '5';
      end case;

      param_pos_status      := '01,02,03,04';
      param_doc_status      := '01,02,03';
      param_dmt_date_start  := to_date(19800101, 'YYYYMMDD');
      param_dmt_date_end    := to_date(22001231, 'YYYYMMDD');
    elsif report_names in('DOC_SUPPL_DELIVERY_PORT_SUPPL_BATCH', 'DOC_SUPPL_DELIVERY_PORT_GOOD_BATCH') then
      param_c_gauge_title  := '2,3';

      case parameter_10
        when 0 then
          param_pos_status  := '01,02,03,04';   --All
        when 1 then
          param_pos_status  := '01';   --To Confirm
        when 2 then
          param_pos_status  := '02,03';   --To Balance and Partially Balanced
        when 3 then
          param_pos_status  := '01,02,03';
        --To Confirm, To Balance and Partially Balanced
      when 4 then
          param_pos_status  := '04';   --Finished
        when 5 then
          param_pos_status  := '01,04';   --To Confirm and Finished
        when 6 then
          param_pos_status  := '02,03,04';
        --To Balance and Partially Balanced and Finished
      when 7 then
          param_pos_status  := '01,02,03,04';   --All
      end case;

      param_doc_status     := '01,02,03,04,05';

      begin
        if parameter_14 = '0' then
          param_dmt_date_start  := to_date(19800101, 'YYYYMMDD');
        else
          param_dmt_date_start  := to_date(parameter_14, 'YYYYMMDD');   -- parameter_14  ************************************
        end if;
      exception
        when others then
          param_dmt_date_start  := to_date('19801231', 'YYYYMMDD');
      end;

      begin
        if parameter_15 = '0' then
          param_dmt_date_end  := to_date(22001231, 'YYYYMMDD');
        else
          param_dmt_date_end  := to_date(parameter_14, 'YYYYMMDD');   -- parameter_15  ************************************
        end if;
      exception
        when others then
          param_dmt_date_end  := to_date('22001231', 'YYYYMMDD');
      end;
    end if;

    pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
    vpc_lang_id     := pcs.PC_I_LIB_SESSION.getuserlangid;

    open arefcursor for
      select to_char(sysdate, 'YYYYIW') year_week
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
           , gco_functions.getdescription2(goo.gco_good_id, 3, 2, '01') des_long_description
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
                      and dit.pc_lang_id = 3)
               , PCS.PC_FUNCTIONS.TranslateWord2('Pas de ligne produit', VPC_LANG_ID)
                ) dic_good_line_descr
           ,
             --&&  to differentiate  lines which are null or not in crystal
             goo.dic_good_family_id
           , nvl( (select dit_descr
                     from dico_description dit
                    where dit.dit_table = 'DIC_GOOD_FAMILY'
                      and dit_code = goo.dic_good_family_id
                      and dit.pc_lang_id = 3)
               , PCS.PC_FUNCTIONS.TranslateWord2('Pas de group produit', VPC_LANG_ID)
                ) dic_good_family_descr
           ,
--&&  to differentiate between families which are null or not in crystal
             goo.dic_good_model_id
           , nvl( (select dit_descr
                     from dico_description dit
                    where dit.dit_table = 'DIC_GOOD_MODEL'
                      and dit_code = goo.dic_good_model_id
                      and dit.pc_lang_id = 3)
               , PCS.PC_FUNCTIONS.TranslateWord2('Pas de modèle produit', VPC_LANG_ID)
                ) dic_good_model_descr
           ,
             --&&  to differentiate between models which are null or not in crystal
             goo.dic_good_group_id
           , nvl( (select dit_descr
                     from dico_description dit
                    where dit.dit_table = 'DIC_GOOD_GROUP'
                      and dit_code = goo.dic_good_group_id
                      and dit.pc_lang_id = 3)
               , PCS.PC_FUNCTIONS.TranslateWord2('Pas de groupe produit', VPC_LANG_ID)
                ) dic_good_group_descr
           ,
             --&&  to differentiate between groups which are null or not in crystal
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
                 and adr.dic_address_type_id = 'Inv') inv_address
           , per.per_key1
           , thi.pac_third_id
           , thi.dic_third_activity_id
           , (select act.act_descr
                from dic_third_activity act
               where act.dic_third_activity_id = thi.dic_third_activity_id) act_descr
           , thi.dic_third_area_id
           , (select are.are_descr
                from dic_third_area are
               where are.dic_third_area_id = thi.dic_third_area_id) are_descr
           , decode(report_names_1, 'CUST', cus.dic_type_partner_id, 'SUPPL', sup.dic_type_partner_f_id) dic_type_partner_id
           , decode(report_names_1
                  , 'CUST', (select dtp.tpa_descr
                               from dic_type_partner dtp
                              where dtp.dic_type_partner_id = cus.dic_type_partner_id)
                  , 'SUPPL', (select dtp.dic_descr
                                from dic_type_partner_f dtp
                               where dtp.dic_type_partner_f_id = sup.dic_type_partner_f_id)
                   ) dic_descr
           , (select rep.rep_descr
                from pac_representative rep
               where rep.pac_representative_id = dmt.pac_representative_id) rep_descr
           , (select to_char(cre.cre_amount_limit)
                from pac_credit_limit cre
               where cre.pac_supplier_partner_id = dmt.pac_third_id) ||
             ' ' ||
             (select cu2.currency
                from pac_credit_limit cre
                   , acs_financial_currency acs
                   , pcs.pc_curr cu2
               where cre.pac_supplier_partner_id = dmt.pac_third_id
                 and cre.acs_financial_currency_id = acs.acs_financial_currency_id
                 and acs.pc_curr_id = cu2.pc_curr_id) cre_amount_limit
           , cur.currency
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
           , the(select cast(in_list(param_pos_status) as char_table_type)
                   from dual) pos_status_list
           , the(select cast(in_list(param_c_gauge_title) as char_table_type)
                   from dual) gauge_tile_list
           , the(select cast(in_list(param_doc_status) as char_table_type)
                   from dual) doc_status_list
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
         and check_cust_suppl(report_names_1, per.pac_person_id) = 1
         --According to report name to define customer or supplier
         and check_record_in_range(report_names_2, goo.goo_major_reference, per.per_key1, parameter_0, parameter_1) = 1
         and pos.c_doc_pos_status = pos_status_list.column_value
         and gas.c_gauge_title = gauge_tile_list.column_value
         and c_document_status = doc_status_list.column_value
         and dmt.dmt_date_document >= param_dmt_date_start
         and dmt.dmt_date_document <= param_dmt_date_end
         and cust_order_port_batch(report_names, parameter_11, fnn.fan_stk_qty, fnn.fan_netw_qty) = 1
         --{@TEST_ATTRIB} Allocation
         and cust_delivery_port_batch(report_names, parameter_12, dmt.doc_document_id) = 1
         --{@TEST_COLIS} Packaging
         and suppl_order_port_batch(report_names, parameter_11, fns.fan_stk_qty, fns.fan_netw_qty) = 1
         --{@TEST_ATTRIB} Allocation
         and suppl_order_port_batch_2(report_names, parameter_13, pos.c_doc_pos_status, pde.pde_final_delay) = 1
         --{@TEST_RETARD} Lateness
         and order_echeancier_batch(report_names, param_final_delay, pde.pde_final_delay, gas.c_gauge_title) = 1;
  end doc_port_good_master_rpt_pk;

  procedure DOC_STOCK_SITUATION_SUB_RPT_PK(arefcursor in out crystal_cursor_types.dualcursortyp,
                                                                                                --PARAMETER_0     IN       NUMBER,
                                                                                                PARAMETER_1 in varchar2)
  is
  begin
    open AREFCURSOR for
      select LOC.STM_LOCATION_ID
           , LOC.LOC_DESCRIPTION
           , STO.STO_DESCRIPTION
           , STO.C_ACCESS_METHOD
           , SPO.GCO_GOOD_ID
           , SPO.SPO_STOCK_QUANTITY
           , SPO.SPO_ASSIGN_QUANTITY
           , SPO.SPO_PROVISORY_INPUT
           , SPO.SPO_PROVISORY_OUTPUT
           , SPO.SPO_AVAILABLE_QUANTITY
        from STM_STOCK STO
           , STM_LOCATION LOC
           , STM_STOCK_POSITION SPO
       where SPO.STM_STOCK_ID = STO.STM_STOCK_ID
         and SPO.STM_LOCATION_ID = LOC.STM_LOCATION_ID
         and STO.C_ACCESS_METHOD <> 'PRIVATE'
         and SPO.GCO_GOOD_ID = to_number(PARAMETER_1);
  end DOC_STOCK_SITUATION_SUB_RPT_PK;

  procedure DOC_CAN_SUPPLIER_RPT_PK(
    arefcursor     in out crystal_cursor_types.dualcursortyp
  , parameter_0    in     varchar2
  , parameter_1    in     varchar2
  , parameter_17   in     varchar2
  , parameter_18   in     varchar2
  , parameter_19   in     varchar2
  , parameter_20   in     varchar2
  ,
    --procparam_2      in       VARCHAR2,
    procuser_lanid in     pcs.pc_lang.lanid%type
  )
  is
/*
 STORED PROCEDURE USED FOR THE REPORT DOC_CAN_SUPPLIER.RPT

 @CREATED IN PROCONCEPT CHINA
 @AUTHOR MZH
 @LASTUPDATE DES. 19 2006
 @VERSION
 @PUBLIC
 @PARAM PARAMETER_0      PAC_PERSON.PER_KEY1(MIN)
 @PARAM PARAMETER_1      PAC_PERSON.PER_KEY1(MAX)
 @PARAM PARAMETER_17    DOC_DOCUMENT.DMT_DATE_DOCUMENT(MIN)
 @PARAM PARAMETER_18    DOC_DOCUMENT.DMT_DATE_DOCUMENT(MAX)
 @PARAM PARAMETER_19    DOC_DOCUMENT.DMT_DATE_DOCUMENT(MIN)
 @PARAM PARAMETER_20    DOC_DOCUMENT.DMT_DATE_DOCUMENT(MAX)
*/
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select DOC.DMT_NUMBER
           , DOC.DMT_DATE_DOCUMENT
           , DOC.DMT_DATE_VALUE
           , STR.C_GAUGE_TITLE
           , STR.GAS_FINANCIAL_CHARGE
           , POS.C_GAUGE_TYPE_POS
           , POS.C_DOC_POS_STATUS
           , POS.POS_FINAL_QUANTITY
           ,
--POS.POS_FINAL_QUANTITY_SU,
             POS.DIC_UNIT_OF_MEASURE_ID
           , POS.POS_UNIT_COST_PRICE
           , POS.POS_NET_VALUE_EXCL_B
           , GOO.GCO_GOOD_ID
           , GOO.DIC_GOOD_LINE_ID
           , GOO.DIC_GOOD_FAMILY_ID
           , GOO.DIC_GOOD_MODEL_ID
           , GOO.DIC_GOOD_GROUP_ID
           , GOO.GOO_MAJOR_REFERENCE
           , GOO.GOO_NUMBER_OF_DECIMAL
           , SUP.DIC_TYPE_PARTNER_F_ID
           , PER.PER_NAME
           , PER.PER_KEY1
           , REP.REP_DESCR
           , THI.DIC_THIRD_ACTIVITY_ID
           , THI.DIC_THIRD_AREA_ID
           , DES.DES_SHORT_DESCRIPTION
        from DOC_DOCUMENT DOC
           , DOC_GAUGE_STRUCTURED STR
           , DOC_POSITION POS
           , GCO_GOOD GOO
           , GCO_DESCRIPTION DES
           , PAC_SUPPLIER_PARTNER SUP
           , PAC_PERSON PER
           , PAC_REPRESENTATIVE REP
           , PAC_THIRD THI
       where DOC.DOC_GAUGE_ID = STR.DOC_GAUGE_ID
         and DOC.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID
         and GOO.GCO_GOOD_ID = DES.GCO_GOOD_ID
         and DES.C_DESCRIPTION_TYPE = '01'
         and DES.PC_LANG_ID = VPC_LANG_ID
         and DOC.PAC_THIRD_ID = SUP.PAC_SUPPLIER_PARTNER_ID
         and DOC.PAC_THIRD_ID = PER.PAC_PERSON_ID
         and DOC.PAC_THIRD_ID = THI.PAC_THIRD_ID
         and DOC.PAC_REPRESENTATIVE_ID = REP.PAC_REPRESENTATIVE_ID(+)
         and (   STR.C_GAUGE_TITLE = '4'
              or (    STR.C_GAUGE_TITLE = '5'
                  and STR.GAS_FINANCIAL_CHARGE = 1) )
         and (   PARAMETER_0 = '%'
              or GOO.GOO_MAJOR_REFERENCE >= PARAMETER_0)
         and (   PARAMETER_1 = '%'
              or GOO.GOO_MAJOR_REFERENCE <= PARAMETER_1)
         and (POS.C_GAUGE_TYPE_POS in('1', '7', '8', '91', '10') )
         and POS.C_DOC_POS_STATUS = '04'
         and (    (    DOC.DMT_DATE_DOCUMENT >= to_date(PARAMETER_17, 'YYYYMMDD')
                   and DOC.DMT_DATE_DOCUMENT <= to_date(PARAMETER_18, 'YYYYMMDD') )
              or (    DOC.DMT_DATE_DOCUMENT >= to_date(PARAMETER_19, 'YYYYMMDD')
                  and DOC.DMT_DATE_DOCUMENT <= to_date(PARAMETER_20, 'YYYYMMDD') )
             );
  end DOC_CAN_SUPPLIER_RPT_PK;

  procedure DOC_CAN_GOOD_SUPPLIER_RPT_PK(
    AREFCURSOR     in out Crystal_Cursor_Types.DUALCURSORTYP
  , PARAMETER_0    in     varchar2
  , PARAMETER_1    in     varchar2
  , PARAMETER_17   in     varchar2
  , PARAMETER_18   in     varchar2
  , PARAMETER_19   in     varchar2
  , PARAMETER_20   in     varchar2
  ,
    --PROCPARAM_2      IN       VARCHAR2,
    PROCUSER_LANID in     PCS.PC_LANG.LANID%type
  )
  is
/*
 STORED PROCEDURE USED FOR THE REPORT DOC_CAN_GOOD_SUPPLIER.RPT

 @CREATED IN PROCONCEPT CHINA
 @AUTHOR MZH
 @LASTUPDATE DES. 18 2006
 @VERSION
 @PUBLIC
 @PARAM PARAMETER_0      PAC_PERSON.PER_KEY1(MIN)
 @PARAM PARAMETER_1      PAC_PERSON.PER_KEY1(MAX)
 @PARAM PARAMETER_17    DOC_DOCUMENT.DMT_DATE_DOCUMENT(MIN)
 @PARAM PARAMETER_18    DOC_DOCUMENT.DMT_DATE_DOCUMENT(MAX)
 @PARAM PARAMETER_19    DOC_DOCUMENT.DMT_DATE_DOCUMENT(MIN)
 @PARAM PARAMETER_20    DOC_DOCUMENT.DMT_DATE_DOCUMENT(MAX)
*/
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select DOC.DMT_NUMBER
           , DOC.DMT_DATE_DOCUMENT
           , DOC.DMT_DATE_VALUE
           , STR.C_GAUGE_TITLE
           , STR.GAS_FINANCIAL_CHARGE
           , POS.C_GAUGE_TYPE_POS
           , POS.C_DOC_POS_STATUS
           , POS.POS_FINAL_QUANTITY
           , POS.POS_FINAL_QUANTITY_SU
           , POS.DIC_UNIT_OF_MEASURE_ID
           , POS.POS_UNIT_COST_PRICE
           , POS.POS_NET_VALUE_EXCL_B
           , GOO.GCO_GOOD_ID
           , GOO.DIC_GOOD_LINE_ID
           , GOO.DIC_GOOD_FAMILY_ID
           , GOO.DIC_GOOD_MODEL_ID
           , GOO.DIC_GOOD_GROUP_ID
           , GOO.GOO_MAJOR_REFERENCE
           , GOO.GOO_NUMBER_OF_DECIMAL
           , SUP.DIC_TYPE_PARTNER_F_ID
           , PER.PER_NAME
           , PER.PER_KEY1
           , REP.REP_DESCR
           , THI.DIC_THIRD_ACTIVITY_ID
           , THI.DIC_THIRD_AREA_ID
           , DES.DES_SHORT_DESCRIPTION
        from DOC_DOCUMENT DOC
           , DOC_GAUGE_STRUCTURED STR
           , DOC_POSITION POS
           , GCO_GOOD GOO
           , GCO_DESCRIPTION DES
           , PAC_SUPPLIER_PARTNER SUP
           , PAC_PERSON PER
           , PAC_REPRESENTATIVE REP
           , PAC_THIRD THI
       where DOC.DOC_GAUGE_ID = STR.DOC_GAUGE_ID
         and DOC.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID
         and GOO.GCO_GOOD_ID = DES.GCO_GOOD_ID
         and DES.C_DESCRIPTION_TYPE = '01'
         and DES.PC_LANG_ID = VPC_LANG_ID
         and DOC.PAC_THIRD_ID = SUP.PAC_SUPPLIER_PARTNER_ID
         and DOC.PAC_THIRD_ID = PER.PAC_PERSON_ID
         and DOC.PAC_THIRD_ID = THI.PAC_THIRD_ID
         and DOC.PAC_REPRESENTATIVE_ID = REP.PAC_REPRESENTATIVE_ID(+)
         and (   STR.C_GAUGE_TITLE = '4'
              or (    STR.C_GAUGE_TITLE = '5'
                  and STR.GAS_FINANCIAL_CHARGE = 1) )
         and (   PARAMETER_0 = '%'
              or GOO.GOO_MAJOR_REFERENCE >= PARAMETER_0)
         and (   PARAMETER_1 = '%'
              or GOO.GOO_MAJOR_REFERENCE <= PARAMETER_1)
         and (POS.C_GAUGE_TYPE_POS in('1', '7', '8', '91', '10') )
         and POS.C_DOC_POS_STATUS = '04'
         and (    (    DOC.DMT_DATE_DOCUMENT >= to_date(PARAMETER_17, 'YYYYMMDD')
                   and DOC.DMT_DATE_DOCUMENT <= to_date(PARAMETER_18, 'YYYYMMDD') )
              or (    DOC.DMT_DATE_DOCUMENT >= to_date(PARAMETER_19, 'YYYYMMDD')
                  and DOC.DMT_DATE_DOCUMENT <= to_date(PARAMETER_20, 'YYYYMMDD') )
             );
  end DOC_CAN_GOOD_SUPPLIER_RPT_PK;

  procedure DOC_SUPPL_REMINDER_MAIL_RPT_PK(
    AREFCURSOR     in out Crystal_Cursor_Types.DUALCURSORTYP
  , PARAMETER_0    in     varchar2
  , PARAMETER_1    in     varchar2
  , PARAMETER_6    in     varchar2
  , PROCUSER_LANID in     PCS.PC_LANG.LANID%type
  )
  is
/**
*Description
        Used for report DOC_SUPPL_REMINDER_MAIL
*@created EQI 23.08.2007
*@lastUpdate
*@public
*@param PARAMETER_0 : minimum value for PAC_PERSON.PER_KEY1
*@param PARAMETER_1 : maximum value for PAC_PERSON.PER_KEY1
*@param PARAMETER_6 : Final delay for detail information of document
*@param PROCUSER_LANID : user language
*/
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;   --user language id
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select DOC.DMT_NUMBER
           , ADR.ADD_ADDRESS1
           , ADR.ADD_FORMAT
           , GAS.C_GAUGE_TITLE
           , POS.C_GAUGE_TYPE_POS
           , POS.C_DOC_POS_STATUS
           , GAP.C_GAUGE_SHOW_DELAY
           , PDE.PDE_FINAL_QUANTITY
           , POS.POS_SHORT_DESCRIPTION
           , POS.POS_BALANCE_QUANTITY
           , POS.DIC_UNIT_OF_MEASURE_ID
           , PDE.PDE_FINAL_DELAY
           , PDE.PDE_BALANCE_QUANTITY
           , GOO.GOO_MAJOR_REFERENCE
           , GOO.GOO_NUMBER_OF_DECIMAL
           , PER.PER_NAME
           , PER.PER_KEY1
           , LAN.LANID
           , CUR.CURRENCY
        from DOC_DOCUMENT DOC
           , DOC_POSITION POS
           , DOC_GAUGE GAU
           , ACS_FINANCIAL_CURRENCY FIN
           , PAC_ADDRESS ADR
           , PCS.PC_LANG LAN
           , DOC_POSITION_DETAIL PDE
           , GCO_GOOD GOO
           , DOC_GAUGE_POSITION GAP
           , DOC_GAUGE_STRUCTURED GAS
           , PCS.PC_CURR CUR
           , PAC_PERSON PER
       where DOC.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
         and DOC.DOC_GAUGE_ID = GAU.DOC_GAUGE_ID(+)
         and DOC.ACS_FINANCIAL_CURRENCY_ID = FIN.ACS_FINANCIAL_CURRENCY_ID
         and DOC.PAC_ADDRESS_ID = ADR.PAC_ADDRESS_ID
         and DOC.PC_LANG_ID = LAN.PC_LANG_ID
         and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
         and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID
         and POS.DOC_GAUGE_POSITION_ID = GAP.DOC_GAUGE_POSITION_ID
         and GAU.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
         and FIN.PC_CURR_ID = CUR.PC_CURR_ID
         and ADR.PAC_PERSON_ID = PER.PAC_PERSON_ID
         and GAS.C_GAUGE_TITLE = '1'
         and POS.C_DOC_POS_STATUS in('02', '03')
         and POS.C_GAUGE_TYPE_POS in('1', '7', '8', '91', '10')
         and PER.PER_KEY1 >= PARAMETER_0
         and PER.PER_KEY1 <= PARAMETER_1
         and (   PARAMETER_6 = '0'
              or to_char(PDE.PDE_FINAL_DELAY, 'yyyyMMdd') <= PARAMETER_6)
         and POS.POS_BALANCE_QUANTITY > 0;
  end DOC_SUPPL_REMINDER_MAIL_RPT_PK;

  procedure DOC_GLOB_GOOD_BATCH_RPT_PK(
    AREFCURSOR  in out Crystal_Cursor_Types.DUALCURSORTYP
  , PARAMETER_0 in     varchar2
  , PARAMETER_1 in     varchar2
  , PARAMETER_6 in     varchar2
  , PARAMETER_7 in     varchar2
  , PARAMETER_9 in     varchar2
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select DDO.C_DOCUMENT_STATUS
           , DGA.C_GAUGE_TITLE
           , DPO.C_GAUGE_TYPE_POS
           , DPO.GCO_GOOD_ID P_GCO_GOOD_ID
           , DPD.PDE_FINAL_DELAY
           , DPD.PDE_BALANCE_QUANTITY
           , GGO.GCO_GOOD_ID G_GCO_GOOD_ID
           , GGO.DIC_GOOD_LINE_ID
           , GGO.DIC_GOOD_FAMILY_ID
           , GGO.DIC_GOOD_MODEL_ID
           , GGO.DIC_GOOD_GROUP_ID
           , nvl( (select dit_descr
                     from dico_description dit
                    where dit.dit_table = 'DIC_GOOD_LINE'
                      and dit_code = ggo.dic_good_line_id
                      and dit.pc_lang_id = 3)
               , PCS.PC_FUNCTIONS.TranslateWord2('Pas de ligne produit', VPC_LANG_ID)
                ) dic_good_line_descr
           ,
             --used to differentiate between lines which are null or not in crystal
             nvl( (select dit_descr
                     from dico_description dit
                    where dit.dit_table = 'DIC_GOOD_FAMILY'
                      and dit_code = ggo.dic_good_family_id
                      and dit.pc_lang_id = 3)
               , PCS.PC_FUNCTIONS.TranslateWord2('Pas de famille produit', VPC_LANG_ID)
                ) dic_good_family_descr
           ,
             --used to differentiate between families which are null or not in crystal
             nvl( (select dit_descr
                     from dico_description dit
                    where dit.dit_table = 'DIC_GOOD_MODEL'
                      and dit_code = ggo.dic_good_model_id
                      and dit.pc_lang_id = 3)
               , PCS.PC_FUNCTIONS.TranslateWord2('Pas de modèle produit', VPC_LANG_ID)
                ) dic_good_model_descr
           ,
             --used to differentiate between models which are null or not in crystal
             nvl( (select dit_descr
                     from dico_description dit
                    where dit.dit_table = 'DIC_GOOD_GROUP'
                      and dit_code = ggo.dic_good_group_id
                      and dit.pc_lang_id = 3)
               , PCS.PC_FUNCTIONS.TranslateWord2('Pas de group produit', VPC_LANG_ID)
                ) dic_good_group_descr
           , GGO.GOO_MAJOR_REFERENCE
           , GGO.GOO_SECONDARY_REFERENCE
           , GGO.GOO_NUMBER_OF_DECIMAL
           , PPE.PER_NAME
           , PPE.PER_KEY1
           , PTH.PAC_THIRD_ID
           , GCO_FUNCTIONS.GetCostPriceWithManagementMode(GGO.GCO_GOOD_ID) CostPrice
        from DOC_DOCUMENT DDO
           , DOC_POSITION DPO
           , DOC_GAUGE_STRUCTURED DGA
           , ACS_FINANCIAL_CURRENCY AFI
           , PAC_THIRD PTH
           , DOC_POSITION_DETAIL DPD
           , GCO_GOOD GGO
           , PCS.PC_CURR PCU
           , PAC_PERSON PPE
           , FAL_NETWORK_NEED FNE
           , V_STM_GCO_GOOD_QTY V_STM
       where DDO.DOC_DOCUMENT_ID = DPO.DOC_DOCUMENT_ID
         and DPO.DOC_POSITION_ID = DPD.DOC_POSITION_ID
         and DPD.DOC_POSITION_DETAIL_ID = FNE.DOC_POSITION_DETAIL_ID(+)
         and DPO.GCO_GOOD_ID = GGO.GCO_GOOD_ID
         and GGO.GCO_GOOD_ID = V_STM.GCO_GOOD_ID(+)
         and DDO.DOC_GAUGE_ID = DGA.DOC_GAUGE_ID
         and DDO.ACS_FINANCIAL_CURRENCY_ID = AFI.ACS_FINANCIAL_CURRENCY_ID
         and AFI.PC_CURR_ID = PCU.PC_CURR_ID
         and DDO.PAC_THIRD_ID = PTH.PAC_THIRD_ID
         and PTH.PAC_THIRD_ID = PPE.PAC_PERSON_ID
         and (   DGA.C_GAUGE_TITLE = decode(PARAMETER_9, '0', '6', '1', '6', '30')
              or DGA.C_GAUGE_TITLE = decode(PARAMETER_9, '0', '30', '2', '30', '6')
              or DGA.C_GAUGE_TITLE = decode(PARAMETER_7, '0', '1', '1', '1', '5')
              or DGA.C_GAUGE_TITLE = decode(PARAMETER_7, '0', '5', '2', '5', '1')
             )
         and (   DGA.C_GAUGE_TITLE = '30'
              or DPD.PDE_FINAL_DELAY <= decode(PARAMETER_6, '0', to_date('30001231', 'YYYYMMDD'), to_date(PARAMETER_6, 'YYYYMMDD') ) )
         and DDO.C_DOCUMENT_STATUS in('01', '02', '03')
         and DPO.C_GAUGE_TYPE_POS in('1', '7', '8', '91', '10')
         and GGO.GOO_MAJOR_REFERENCE >= PARAMETER_0
         and GGO.GOO_MAJOR_REFERENCE <= PARAMETER_1;
  end DOC_GLOB_GOOD_BATCH_RPT_PK;

  procedure ART_DESC_SUB_RPT_PK(
    AREFCURSOR     in out Crystal_Cursor_Types.DUALCURSORTYP
  , PM_GCO_GOOD_ID in     GCO_GOOD.GCO_GOOD_ID%type
  , PROCUSER_LANID in     PCS.PC_LANG.LANID%type
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select GDE.GCO_GOOD_ID
           , GDE.C_DESCRIPTION_TYPE
           , GDE.DES_SHORT_DESCRIPTION
           , GDE.DES_LONG_DESCRIPTION
           , GDE.DES_FREE_DESCRIPTION
        from GCO_DESCRIPTION GDE
       where GDE.PC_LANG_ID = VPC_LANG_ID
         and GDE.C_DESCRIPTION_TYPE = '01'
         and GDE.GCO_GOOD_ID = PM_GCO_GOOD_ID;
  end ART_DESC_SUB_RPT_PK;

  procedure STOCK_SITUATION_SUB_RPT_PK(
    AREFCURSOR     in out Crystal_Cursor_Types.DUALCURSORTYP
  , PM_GCO_GOOD_ID in     GCO_GOOD.GCO_GOOD_ID%type
  , PROCUSER_LANID in     PCS.PC_LANG.LANID%type
  )
  is
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select SLO.LOC_DESCRIPTION
           , SST.STO_DESCRIPTION
           , SST.C_ACCESS_METHOD
           , SSP.GCO_GOOD_ID
           , SSP.SPO_STOCK_QUANTITY
           , SSP.SPO_ASSIGN_QUANTITY
           , SSP.SPO_PROVISORY_INPUT
           , SSP.SPO_PROVISORY_OUTPUT
           , SSP.SPO_AVAILABLE_QUANTITY
        from STM_STOCK_POSITION SSP
           , STM_STOCK SST
           , STM_LOCATION SLO
       where SSP.STM_STOCK_ID = SST.STM_STOCK_ID
         and SSP.STM_LOCATION_ID = SLO.STM_LOCATION_ID
         and SSP.GCO_GOOD_ID = PM_GCO_GOOD_ID
         and SST.C_ACCESS_METHOD <> 'PRIVATE';
  end STOCK_SITUATION_SUB_RPT_PK;

  procedure DOC_SUPPL_REMINDER_BAT_RPT_PK(
    AREFCURSOR     in out Crystal_Cursor_Types.DUALCURSORTYP
  , PARAMETER_0    in     varchar2
  , PARAMETER_1    in     varchar2
  , PROCUSER_LANID in     PCS.PC_LANG.LANID%type
  )
  is
/**
*Description
        Used for report DOC_SUPPL_REMINDER_BATCH
*@created EQI 21.08.2007
*@lastUpdate AWU Nov.2008
*@public
*@param PARAMETER_0 : minimum value for PAC_PERSON.PER_KEY1
*@param PARAMETER_1 : maximum value for PAC_PERSON.PER_KEY1
*@param PROCUSER_LANID : user language
*/
    VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;   --user language id
  begin
    PCS.PC_I_LIB_SESSION.SETLANID(PROCUSER_LANID);
    VPC_LANG_ID  := pcs.PC_I_LIB_SESSION.GetUserLangId;

    open AREFCURSOR for
      select   DMT.DMT_NUMBER
             , DMT.C_DOCUMENT_STATUS
             , GAS.C_GAUGE_TITLE
             , POS.POS_NUMBER
             , POS.C_GAUGE_TYPE_POS
             , POS.POS_FINAL_QUANTITY
             , POS.POS_NET_VALUE_EXCL_B
             , POS.DIC_UNIT_OF_MEASURE_ID
             , POS.POS_NET_UNIT_VALUE
             , PDE.PDE_BALANCE_QUANTITY
             , PDE.PDE_FINAL_QUANTITY
             , PDE.PDE_FINAL_DELAY
             , GOO.GCO_GOOD_ID
             , GOO.GOO_MAJOR_REFERENCE
             , GOO.GOO_NUMBER_OF_DECIMAL
             , PER.PAC_PERSON_ID
             , PER.PER_NAME
             , PER.PER_KEY1
             , PER.PER_SHORT_NAME
             , (select ADR.ADD_ADDRESS1 || '  ' || ADR.ADD_FORMAT
                  from PAC_ADDRESS ADR
                 where ADR.PAC_PERSON_ID = DMT.PAC_THIRD_ID
                   and ADR.DIC_ADDRESS_TYPE_ID = 'Inv') INV_ADDRESS
             , SUP.PAC_SUPPLIER_PARTNER_ID
             , SUP.ACS_AUXILIARY_ACCOUNT_ID
             , THI.PAC_THIRD_ID
             , CUR.CURRENCY
             , ADR.ADD_ADDRESS1
             , DES.DES_SHORT_DESCRIPTION
             , FNN.FAN_STK_QTY
             , FNN.FAN_NETW_QTY
             , (select CU2.CURRENCY
                  from PAC_CREDIT_LIMIT CRE
                     , ACS_FINANCIAL_CURRENCY ACS
                     , PCS.PC_CURR CU2
                 where CRE.PAC_SUPPLIER_PARTNER_ID = DMT.PAC_THIRD_ID
                   and CRE.ACS_FINANCIAL_CURRENCY_ID = ACS.ACS_FINANCIAL_CURRENCY_ID
                   and ACS.PC_CURR_ID = CU2.PC_CURR_ID) CRE_AMOUNT_LIMIT
             , STM_FUNCTIONS.GETAVAILABLEQUANTITY(GOO.GCO_GOOD_ID) AVAILABLE_QTY
          from ACS_FINANCIAL_CURRENCY FIN
             , DOC_DOCUMENT DMT
             , DOC_GAUGE_STRUCTURED GAS
             , DOC_POSITION POS
             , DOC_POSITION_DETAIL PDE
             , FAL_NETWORK_NEED FNN
             , GCO_GOOD GOO
             , PAC_PERSON PER
             , PAC_SUPPLIER_PARTNER SUP
             , PAC_THIRD THI
             , PCS.PC_CURR CUR
             , PAC_ADDRESS ADR
             , GCO_DESCRIPTION DES
         where GOO.GCO_GOOD_ID = DES.GCO_GOOD_ID
           and DES.PC_LANG_ID = VPC_LANG_ID
           and DES.C_DESCRIPTION_TYPE = '01'
           and PER.PAC_PERSON_ID = ADR.PAC_PERSON_ID
           and DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
           and POS.DOC_POSITION_ID = PDE.DOC_POSITION_ID
           and PDE.DOC_POSITION_DETAIL_ID = FNN.DOC_POSITION_DETAIL_ID(+)
           and POS.GCO_GOOD_ID = GOO.GCO_GOOD_ID
           and DMT.DOc_GAUGE_ID = GAS.DOc_GAUGE_ID
           and DMT.ACS_FINANCIAL_CURRENCY_ID = FIN.ACS_FINANCIAL_CURRENCY_ID
           and FIN.PC_CURR_ID = CUR.PC_CURR_ID
           and DMT.PAC_THIRD_ID = THI.PAC_THIRD_ID
           and THI.PAC_THIRD_ID = PER.PAC_PERSON_ID
           and PER.PAC_PERSON_ID = SUP.PAC_SUPPLIER_PARTNER_ID
           and GAS.C_GAUGE_TITLE = '1'
           and DMT.C_DOCUMENT_STATUS in('02', '03')
           and POS.C_GAUGE_TYPE_POS in('1', '7', '8', '91', '10')
           and PER.PER_KEY1 >= PARAMETER_0
           and PER.PER_KEY1 <= PARAMETER_1
      order by DMT.DMT_NUMBER
             , POS.POS_NUMBER;
  end DOC_SUPPL_REMINDER_BAT_RPT_PK;

/****************************************************/
/*Functions which will be used in the crystal report*/
/****************************************************/
/**
* Description
*    This function will convert a string to table type value, which will allow to 'IN' in the SQL statement
*/
  function IN_LIST(PARAM_STRING in varchar2)
    return CHAR_TABLE_TYPE
  is
    TEMP_STRING    varchar2(32767) default PARAM_STRING || ',';
    RESULT_IN_LIST CHAR_TABLE_TYPE := CHAR_TABLE_TYPE();
    N              number;
  begin
    TEMP_STRING  := replace(TEMP_STRING, ';', ',');

    loop
      exit when TEMP_STRING is null;
      N                                     := instr(TEMP_STRING, ',');
      RESULT_IN_LIST.extend;
      RESULT_IN_LIST(RESULT_IN_LIST.count)  := ltrim(rtrim(substr(TEMP_STRING, 1, N - 1) ) );
      TEMP_STRING                           := substr(TEMP_STRING, N + 1);
    end loop;

    return RESULT_IN_LIST;
  end IN_LIST;

/**
* Description
*    According to the report, if the report is used for the customer, and the PAC_PERSON_ID is refer to a customer
                              then the result will be 1
                              else result will be 0
*/
  function CHECK_CUST_SUPPL(REPORT_NAMES_1 in varchar2, PAC_PERSON_ID in number)
    return number
  is
    result number(1);
  begin
    case REPORT_NAMES_1
      when 'CUST' then
        select 1
          into result
          from PAC_CUSTOM_PARTNER CUS
         where PAC_PERSON_ID = CUS.PAC_CUSTOM_PARTNER_ID;
      when 'SUPPL' then
        select 1
          into result
          from PAC_SUPPLIER_PARTNER SUP
         where PAC_PERSON_ID = SUP.PAC_SUPPLIER_PARTNER_ID;
    end case;

    return result;
  exception
    when others then
      return 0;
  end CHECK_CUST_SUPPL;

/**
* Description
*    According to the report, if the record between PARAMETER_0 AND PARAMETER_1
                            then the result will be 1
                            else result will be 0
*/
  function CHECK_RECORD_IN_RANGE(REPORT_NAMES_2 in varchar2, REFERENCE_1 in varchar2, REFERENCE_2 in varchar2, PARAMETER_0 in varchar2, PARAMETER_1 in varchar2)
    return number
  is
    result number(1);
  begin
    case REPORT_NAMES_2
      when 'GOOD' then
        if REFERENCE_1 between PARAMETER_0 and PARAMETER_1 then
          result  := 1;
        else
          result  := 0;
        end if;
      when 'CUST' then
        if REFERENCE_2 between PARAMETER_0 and PARAMETER_1 then
          result  := 1;
        else
          result  := 0;
        end if;
      when 'SUPPL' then
        if REFERENCE_2 between PARAMETER_0 and PARAMETER_1 then
          result  := 1;
        else
          result  := 0;
        end if;
    end case;

    return result;
  exception
    when others then
      return 0;
  end CHECK_RECORD_IN_RANGE;

/**
* Description
*    USED IN REPORT: DOC_CUST_ORDER_PORT_CUST_BATCH
                     DOC_CUST_ORDER_PORT_GOOD_BATCH
                     DOC_CUST_ECHEANCIER_CUST_BATCH
                     DOC_CUST_ECHEANCIER_GOOD_BATCH
                     DOC_SUPPL_ORDER_PORT_SUPPL_BATCH
                     DOC_SUPPL_ORDER_PORT_GOOD_BATCH
                     DOC_SUPPL_ECHEANCIER_SUPPL_BATCH
                     DOC_SUPPL_ECHEANCIER_GOOD_BATCH
     INSTEAD OF CRYSTAL'S SELECTION FORMULA: {DOC_GAUGE_STRUCTURED.C_GAUGE_TITLE}='30' OR {DOC_POSITION_DETAIL.PDE_FINAL_DELAY}<={@TEST_DATE}
*/
  function ORDER_ECHEANCIER_BATCH(REPORT_NAMES in varchar2, PARAM_FINAL_DELAY in date, PDE_FINAL_DELAY in date, C_GAUGE_TITLE in varchar2)
    return number
  is
    result number(1);
  begin
    if REPORT_NAMES in
         ('DOC_CUST_ORDER_PORT_CUST_BATCH', 'DOC_CUST_ORDER_PORT_GOOD_BATCH', 'DOC_CUST_ECHEANCIER_CUST_BATCH', 'DOC_CUST_ECHEANCIER_GOOD_BATCH'
        , 'DOC_SUPPL_ECHEANCIER_SUPPL_BATCH', 'DOC_SUPPL_ECHEANCIER_GOOD_BATCH')                                                         /*
                                                                                   THEN IF C_GAUGE_TITLE = '30' OR (PDE_FINAL_DELAY <= PARAM_FINAL_DELAY AND (PDE_FINAL_DELAY IS NOT NULL))
                                                                                        THEN RESULT := 1;
                                                                                        ELSE RESULT := 0;
                                                                                        END IF;*/
                                                                                then
      if C_GAUGE_TITLE = '30' then
        result  := 1;
      else
        if PDE_FINAL_DELAY is null then
          result  := 0;
        else
          if trunc(PDE_FINAL_DELAY) <= PARAM_FINAL_DELAY then
            result  := 1;
          else
            result  := 0;
          end if;
        end if;
      end if;
    elsif REPORT_NAMES in('DOC_SUPPL_ORDER_PORT_SUPPL_BATCH', 'DOC_SUPPL_ORDER_PORT_GOOD_BATCH')                                                            /*
                                                                                                   THEN IF PDE_FINAL_DELAY <= PARAM_FINAL_DELAY AND (PDE_FINAL_DELAY IS NOT NULL)
                                                                                                        THEN RESULT := 1;
                                                                                                        ELSE RESULT := 0;
                                                                                                        END IF;*/
                                                                                                then
      if PDE_FINAL_DELAY is null then
        result  := 0;
      else
        if trunc(PDE_FINAL_DELAY) <= PARAM_FINAL_DELAY then
          result  := 1;
        else
          result  := 0;
        end if;
      end if;
    else
      result  := 1;
    end if;

    return result;
  end ORDER_ECHEANCIER_BATCH;

/**
* Description
*    USED IN REPORT: DOC_CUST_ORDER_PORT_CUST_BATCH
                  DOC_CUST_ORDER_PORT_GOOD_BATCH
     INSTEAD OF CRYSTAL'S FORMULA {@TEST_ATTRIB} Allocation
     ALLOCATION
     PARAMETER_11 = '0'   NO CHECK BOX SELECTED
     PARAMETER_11 = '1'   NONE
     PARAMETER_11 = '2'   DOCUMENT
     PARAMETER_11 = '3'   NONE,DOCUMENT
     PARAMETER_11 = '4'   STOCK
     PARAMETER_11 = '5'   NONE,STOCK
     PARAMETER_11 = '6'   DOCUMENT,STOCK
     PARAMETER_11 = '7'   ALL CHECK BOX SELECTED
*/
  function CUST_ORDER_PORT_BATCH(REPORT_NAMES in varchar2, PARAMETER_11 in varchar2, FAN_STK_QTY in number, FAN_NETW_QTY in number)
    return number
  is
    result number(1);
  begin
    if REPORT_NAMES in('DOC_CUST_ORDER_PORT_CUST_BATCH', 'DOC_CUST_ORDER_PORT_GOOD_BATCH') then
      case PARAMETER_11
        when '0' then
          result  := 1;
        when '1' then
          if     nvl(FAN_STK_QTY, 0) = 0
             and nvl(FAN_NETW_QTY, 0) = 0 then
            result  := 1;
          else
            result  := 0;
          end if;
        when '2' then
          if (FAN_NETW_QTY > 0) then
            result  := 1;
          else
            result  := 0;
          end if;
        when '3' then
          if (   FAN_NETW_QTY > 0
              or (    nvl(FAN_STK_QTY, 0) = 0
                  and nvl(FAN_NETW_QTY, 0) = 0) ) then
            result  := 1;
          else
            result  := 0;
          end if;
        when '4' then
          if (FAN_STK_QTY > 0) then
            result  := 1;
          else
            result  := 0;
          end if;
        when '5' then
          if (   FAN_STK_QTY > 0
              or (    nvl(FAN_STK_QTY, 0) = 0
                  and nvl(FAN_NETW_QTY, 0) = 0) ) then
            result  := 1;
          else
            result  := 0;
          end if;
        when '6' then
          if (   FAN_NETW_QTY > 0
              or FAN_STK_QTY > 0) then
            result  := 1;
          else
            result  := 0;
          end if;
        when '7' then
          result  := 1;
        else
          result  := 0;
      end case;
    else
      result  := 1;
    end if;

    return result;
  end CUST_ORDER_PORT_BATCH;

/**
* Description
*    USED IN REPORT: DOC_CUST_DELIVERY_PORT_CUST_BATCH
                  DOC_CUST_DELIVERY_PORT_GOOD_BATCH
     INSTEAD OF CRYSTAL'S FORMULA {@TEST_COLIS} Pracle
*/
  function CUST_DELIVERY_PORT_BATCH(REPORT_NAMES in varchar2, PARAMETER_12 in varchar2, DOC_DOCUMENT_ID in number)
    return number
  is
    result number(1);
  begin
    if REPORT_NAMES in('DOC_CUST_DELIVERY_PORT_CUST_BATCH', 'DOC_CUST_DELIVERY_PORT_GOOD_BATCH') then
      case PARAMETER_12
        when '0' then
          result  := 1;
        when '1' then
          if DOC_PACKING.GETPACKING(DOC_DOCUMENT_ID) in('0') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '2' then
          if DOC_PACKING.GETPACKING(DOC_DOCUMENT_ID) in('1') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '3' then
          if DOC_PACKING.GETPACKING(DOC_DOCUMENT_ID) in('0', '1') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '4' then
          if DOC_PACKING.GETPACKING(DOC_DOCUMENT_ID) in('2') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '5' then
          if DOC_PACKING.GETPACKING(DOC_DOCUMENT_ID) in('0', '2') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '6' then
          if DOC_PACKING.GETPACKING(DOC_DOCUMENT_ID) in('1', '2') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '7' then
          if DOC_PACKING.GETPACKING(DOC_DOCUMENT_ID) in('0', '1', '2') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '8' then
          if DOC_PACKING.GETPACKING(DOC_DOCUMENT_ID) in('3') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '9' then
          if DOC_PACKING.GETPACKING(DOC_DOCUMENT_ID) in('0', '3') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '10' then
          if DOC_PACKING.GETPACKING(DOC_DOCUMENT_ID) in('1', '3') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '11' then
          if DOC_PACKING.GETPACKING(DOC_DOCUMENT_ID) in('0', '1', '3') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '12' then
          if DOC_PACKING.GETPACKING(DOC_DOCUMENT_ID) in('2', '3') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '13' then
          if DOC_PACKING.GETPACKING(DOC_DOCUMENT_ID) in('0', '2', '3') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '14' then
          if DOC_PACKING.GETPACKING(DOC_DOCUMENT_ID) in('1', '2', '3') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '15' then
          result  := 1;
      end case;
    else
      result  := 1;
    end if;

    return result;
  exception
    when others then
      return 0;
  end CUST_DELIVERY_PORT_BATCH;

/**
* Description
*    USED IN REPORT: DOC_SUPPL_ORDER_PORT_SUPPL_BATCH
                     DOC_SUPPL_ORDER_PORT_GOOD_BATCH
     INSTEAD OF CRYSTAL'S FORMULA {@TEST_ATTRIB} Allocation
     ALLOCATION
     PARAMETER_11 = '0'   NO CHECK BOX SELECTED
     PARAMETER_11 = '1'   NONE
     PARAMETER_11 = '2'   DOCUMENT
     PARAMETER_11 = '3'   NONE,DOCUMENT
     PARAMETER_11 = '4'   STOCK
     PARAMETER_11 = '5'   NONE,STOCK
     PARAMETER_11 = '6'   DOCUMENT,STOCK
     PARAMETER_11 = '7'   ALL CHECK BOX SELECTED
*/
  function SUPPL_ORDER_PORT_BATCH(REPORT_NAMES in varchar2, PARAMETER_11 in varchar2, FAN_STK_QTY in number, FAN_NETW_QTY in number)
    return number
  is
    result number(1);
  begin
    if REPORT_NAMES in('DOC_SUPPL_ORDER_PORT_SUPPL_BATCH', 'DOC_SUPPL_ORDER_PORT_GOOD_BATCH') then
      case PARAMETER_11
        when '0' then
          result  := 1;
        when '1' then
          if     nvl(FAN_STK_QTY, 0) = 0
             and nvl(FAN_NETW_QTY, 0) = 0 then
            result  := 1;
          else
            result  := 0;
          end if;
        when '2' then
          if (FAN_NETW_QTY > 0) then
            result  := 1;
          else
            result  := 0;
          end if;
        when '3' then
          if (   FAN_NETW_QTY > 0
              or (    nvl(FAN_STK_QTY, 0) = 0
                  and nvl(FAN_NETW_QTY, 0) = 0) ) then
            result  := 1;
          else
            result  := 0;
          end if;
        when '4' then
          if (FAN_STK_QTY > 0) then
            result  := 1;
          else
            result  := 0;
          end if;
        when '5' then
          if (   FAN_STK_QTY > 0
              or (    nvl(FAN_STK_QTY, 0) = 0
                  and nvl(FAN_NETW_QTY, 0) = 0) ) then
            result  := 1;
          else
            result  := 0;
          end if;
        when '6' then
          result  := 1;
        when '7' then
          result  := 1;
        else
          result  := 0;
      end case;
    else
      result  := 1;
    end if;

    return result;
  end SUPPL_ORDER_PORT_BATCH;

/**
* Description
*    USED IN REPORT: DOC_SUPPL_ORDER_PORT_SUPPL_BATCH
                  DOC_SUPPL_ORDER_PORT_GOOD_BATCH
     INSTEAD OF CRYSTAL'S FORMULA {@TEST_RETARD} Lateness
*/
  function SUPPL_ORDER_PORT_BATCH_2(REPORT_NAMES in varchar2, PARAMETER_13 in varchar2, C_DOC_POS_STATUS in varchar2, PDE_FINAL_DELAY in date)
    return number
  is
    result     number(1);
    DELAY_DAYS number(38);
    P_13       number(38);
  begin
    P_13  := to_number(PARAMETER_13);

    if REPORT_NAMES in('DOC_SUPPL_ORDER_PORT_SUPPL_BATCH', 'DOC_SUPPL_ORDER_PORT_GOOD_BATCH') then
      if C_DOC_POS_STATUS <> '04' then
        DELAY_DAYS  := trunc(sysdate) - trunc(PDE_FINAL_DELAY);
      else
        DELAY_DAYS  := 0;
      end if;

      if P_13 > 0 then
        if DELAY_DAYS > P_13 then
          result  := 1;
        else
          result  := 0;
        end if;
      elsif P_13 < 0 then
        if DELAY_DAYS < 0 then
          result  := 1;
        else
          result  := 0;
        end if;
      else
        result  := 1;
      end if;
    else
      result  := 1;
    end if;

    return result;
  exception
    when others then
      return 0;
  end SUPPL_ORDER_PORT_BATCH_2;

/**
* Description
*    USED IN REPORT: DOC_SUPPL_TURNOVER_SUPPL_BATCH
                     DOC_SUPPL_TURNOVER_GOOD_BATCH
     Turnover with credit over
*/
  function SUPPL_TURNOVER_BATCH(REPORT_NAMES in varchar2, PARAMETER_9 in varchar2, C_GAUGE_TITLE in varchar2, GAS_FINANCIAL_CHARGE in number)
    return number
  is
    result number(1);
  begin
    if REPORT_NAMES in('DOC_SUPPL_TURNOVER_SUPPL_BATCH', 'DOC_SUPPL_TURNOVER_GOOD_BATCH') then
      case PARAMETER_9
        when '0' then
          if C_GAUGE_TITLE = '4' then
            result  := 1;
          else
            result  := 0;
          end if;
        when '1' then
          if    (    C_GAUGE_TITLE = '5'
                 and GAS_FINANCIAL_CHARGE = 1)
             or (C_GAUGE_TITLE = '4') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '2' then
          if     C_GAUGE_TITLE = '5'
             and GAS_FINANCIAL_CHARGE = 1 then
            result  := 1;
          else
            result  := 0;
          end if;
      end case;
    else
      result  := 1;
    end if;

    return result;
  exception
    when others then
      return 0;
  end SUPPL_TURNOVER_BATCH;
end DOC_STAT_RPT;
