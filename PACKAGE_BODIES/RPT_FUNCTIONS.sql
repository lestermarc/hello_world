--------------------------------------------------------
--  DDL for Package Body RPT_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "RPT_FUNCTIONS" 
is
  /**
  * Description
  *    This function will convert a string to table type value, which will allow to 'IN' in the SQL statement
  */
  function in_list(param_string in clob, param_sep in varchar2 default ',')
    return char_table_type   --char_table_type
  is
    temp_string    clob            default param_string || param_sep;
    result_in_list char_table_type := char_table_type();
    --char_table_type  := char_table_type ();
    n              number;
    insert_string  varchar2(32767);
  begin
    n  := instr(temp_string, param_sep);

    while n <> 0 loop
      insert_string                         := substr(temp_string, 1, n - 1);
      result_in_list.extend;
      result_in_list(result_in_list.count)  := insert_string;
      temp_string                           := substr(temp_string, n + 1);
      n                                     := instr(temp_string, param_sep);
    end loop;

    return result_in_list;
  end in_list;

  function check_cust_suppl(report_names_1 in varchar2, pac_person_id in number)
    return number
  is
/**
* Function CHECK_CUST_SUPPL
* Description
*    According to the report, if the report is used for the customer, and the PAC_PERSON_ID is refer to a customer
                              then the result will be 1
                              else result will be 0
* @created MZHU 1 AUG 2007
* @lastUpdate 19 FEB 2009
* @private
* @param REPORT_NAMES_1  :  report name
* @param PAC_PERSON_ID : person id
* @return  : number
*/
    result number(1);
  begin
    case report_names_1
      when 'CUST' then
        select 1
          into result
          from pac_custom_partner cus
         where pac_person_id = cus.pac_custom_partner_id;
      when 'SUPPL' then
        select 1
          into result
          from pac_supplier_partner sup
         where pac_person_id = sup.pac_supplier_partner_id;
    end case;

    return result;
  exception
    when others then
      return 0;
  end check_cust_suppl;

  function check_record_in_range(report_names_2 in varchar2, reference_1 in varchar2, reference_2 in varchar2, parameter_0 in varchar2, parameter_1 in varchar2)
    return number
  is
/**
* Function CHECK_RECORD_IN_RANGE
* Description
*    According to the report, if the record between PARAMETER_0 AND PARAMETER_1
                              then the result will be 1
                              else result will be 0
* @created MZHU 1 AUG 2007
* @lastUpdate 19 FEB 2009
* @private
* @param REPORT_NAMES_2  :  report name
* @param REFERENCE_1 : For 'GOOD', GOO_MAJOR_REFERENCE
* @param REFERENCE_2 : For 'CUST' & 'SUPPL', PER_KEY1
* @param PARAMETER_0 : minimum value
* @param PARAMETER_1 : maxnimum value
* @return  : number
*/
    result number(1);
  begin
    case report_names_2
      when 'GOOD' then
        if reference_1 between parameter_0 and parameter_1 then
          result  := 1;
        else
          result  := 0;
        end if;
      when 'CUST' then
        if reference_2 between parameter_0 and parameter_1 then
          result  := 1;
        else
          result  := 0;
        end if;
      when 'SUPPL' then
        if reference_2 between parameter_0 and parameter_1 then
          result  := 1;
        else
          result  := 0;
        end if;
    end case;

    return result;
  exception
    when others then
      return 0;
  end check_record_in_range;

  function order_echeancier_batch(report_names in varchar2, param_final_delay in date, pde_final_delay in date, c_gauge_title in varchar2)
    return number
  is
/**
* Function ORDER_ECHEANCIER_BATCH
* Description
*    Used in report: DOC_CUST_ORDER_PORT_CUST_BATCH
                     DOC_CUST_ORDER_PORT_GOOD_BATCH
                     DOC_CUST_ECHEANCIER_CUST_BATCH
                     DOC_CUST_ECHEANCIER_GOOD_BATCH
                     DOC_SUPPL_ORDER_PORT_SUPPL_BATCH
                     DOC_SUPPL_ORDER_PORT_GOOD_BATCH
                     DOC_SUPPL_ECHEANCIER_SUPPL_BATCH
                     DOC_SUPPL_ECHEANCIER_GOOD_BATCH

     Instead of crystal's selection formula: {DOC_GAUGE_STRUCTURED.C_GAUGE_TITLE}='30' or {DOC_POSITION_DETAIL.PDE_FINAL_DELAY}<={@TEST_DATE}
* @created MZHU 1 AUG 2007
* @lastUpdate 19 FEB 2009
* @private
* @param REPORT_NAMES  :  report name
* @param PARAM_FINAL_DELAY : final delay calculated in the procedure
* @param PDE_FINAL_DELAY : final delay taken from the document
* @param C_GAUGE_TITLE : gauge title of the document
* @return  : number
*/
    result number(1);
  begin
    if report_names in
         ('DOC_CUST_ORDER_PORT_CUST_BATCH'
        , 'DOC_CUST_ORDER_PORT_GOOD_BATCH'
        , 'DOC_CUST_ECHEANCIER_CUST_BATCH'
        , 'DOC_CUST_ECHEANCIER_GOOD_BATCH'
        , 'DOC_SUPPL_ECHEANCIER_SUPPL_BATCH'
        , 'DOC_SUPPL_ECHEANCIER_GOOD_BATCH'
         )
                                     /*
          THEN IF C_GAUGE_TITLE = '30' OR (PDE_FINAL_DELAY <= PARAM_FINAL_DELAY AND (PDE_FINAL_DELAY IS NOT NULL))
          THEN RESULT := 1;
          ELSE RESULT := 0;
          END IF;*/
    then
      if c_gauge_title = '30' then
        result  := 1;
      else
        if pde_final_delay is null then
          result  := 0;
        else
          if trunc(pde_final_delay) <= param_final_delay then
            result  := 1;
          else
            result  := 0;
          end if;
        end if;
      end if;
    elsif report_names in('DOC_SUPPL_ORDER_PORT_SUPPL_BATCH', 'DOC_SUPPL_ORDER_PORT_GOOD_BATCH')                                                            /*
                                                                                                   THEN IF PDE_FINAL_DELAY <= PARAM_FINAL_DELAY AND (PDE_FINAL_DELAY IS NOT NULL)
                                                                                                        THEN RESULT := 1;
                                                                                                        ELSE RESULT := 0;
                                                                                                        END IF;*/
                                                                                                then
      if pde_final_delay is null then
        result  := 0;
      else
        if trunc(pde_final_delay) <= param_final_delay then
          result  := 1;
        else
          result  := 0;
        end if;
      end if;
    else
      result  := 1;
    end if;

    return result;
  end order_echeancier_batch;

  function cust_order_port_batch(report_names in varchar2, parameter_11 in varchar2, fan_stk_qty in number, fan_netw_qty in number)
    return number
  is
/**
* Function CUST_ORDER_PORT_BATCH
* Description
*    Used in report: DOC_CUST_ORDER_PORT_CUST_BATCH
                     DOC_CUST_ORDER_PORT_GOOD_BATCH

     Instead of crystal's formula {@TEST_ATTRIB} Allocation
     Allocation
     PARAMETER_11 = '0'   NO CHECK BOX SELECTED
     PARAMETER_11 = '1'   NONE
     PARAMETER_11 = '2'   DOCUMENT
     PARAMETER_11 = '3'   NONE,DOCUMENT
     PARAMETER_11 = '4'   STOCK
     PARAMETER_11 = '5'   NONE,STOCK
     PARAMETER_11 = '6'   DOCUMENT,STOCK
     PARAMETER_11 = '7'   ALL CHECK BOX SELECTED
* @created MZHU 1 AUG 2007
* @lastUpdate 19 FEB 2009
* @private
* @param REPORT_NAMES  :  report name
* @param PARAMETER_11 :
* @param FAN_STK_QTY :
* @param FAN_NETW_QTY :
* @return  : number
*/
    result number(1);
  begin
    if report_names in('DOC_CUST_ORDER_PORT_CUST_BATCH', 'DOC_CUST_ORDER_PORT_GOOD_BATCH') then
      case parameter_11
        when '0' then
          result  := 1;
        when '1' then
          if     fan_stk_qty = 0
             and fan_netw_qty = 0 then
            result  := 1;
          else
            result  := 0;
          end if;
        when '2' then
          if (fan_netw_qty > 0) then
            result  := 1;
          else
            result  := 0;
          end if;
        when '3' then
          if (    (    fan_stk_qty = 0
                   and fan_netw_qty = 0)
              or fan_netw_qty > 0) then
            result  := 1;
          else
            result  := 0;
          end if;
        when '4' then
          if (fan_stk_qty > 0) then
            result  := 1;
          else
            result  := 0;
          end if;
        when '5' then
          if (    (    fan_stk_qty = 0
                   and fan_netw_qty = 0)
              or fan_stk_qty > 0) then
            result  := 1;
          else
            result  := 0;
          end if;
        when '6' then
          if (   fan_netw_qty > 0
              or fan_stk_qty > 0) then
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
  end cust_order_port_batch;

  function cust_delivery_port_batch(report_names in varchar2, parameter_12 in varchar2, doc_document_id in number)
    return number
  is
/**
* Function CUST_DELIVERY_PORT_BATCH
* Description
*    Used in report: DOC_CUST_DELIVERY_PORT_CUST_BATCH
                     DOC_CUST_DELIVERY_PORT_GOOD_BATCH

     Instead of crystal's formula {@TEST_COLIS} Pracle
* @created MZHU 1 AUG 2007
* @lastUpdate 19 FEB 2009
* @private
* @param REPORT_NAMES  :  report name
* @param PARAMETER_12 :
* @param DOC_DOCUMENT_ID :  Document id
* @return  : number
*/
    result number(1);
  begin
    if report_names in('DOC_CUST_DELIVERY_PORT_CUST_BATCH', 'DOC_CUST_DELIVERY_PORT_GOOD_BATCH') then
      case parameter_12
        when '0' then
          result  := 1;
        when '1' then
          if doc_packing.getpacking(doc_document_id) in('0') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '2' then
          if doc_packing.getpacking(doc_document_id) in('1') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '3' then
          if doc_packing.getpacking(doc_document_id) in('0', '1') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '4' then
          if doc_packing.getpacking(doc_document_id) in('2') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '5' then
          if doc_packing.getpacking(doc_document_id) in('0', '2') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '6' then
          if doc_packing.getpacking(doc_document_id) in('1', '2') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '7' then
          if doc_packing.getpacking(doc_document_id) in('0', '1', '2') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '8' then
          if doc_packing.getpacking(doc_document_id) in('3') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '9' then
          if doc_packing.getpacking(doc_document_id) in('0', '3') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '10' then
          if doc_packing.getpacking(doc_document_id) in('1', '3') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '11' then
          if doc_packing.getpacking(doc_document_id) in('0', '1', '3') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '12' then
          if doc_packing.getpacking(doc_document_id) in('2', '3') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '13' then
          if doc_packing.getpacking(doc_document_id) in('0', '2', '3') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '14' then
          if doc_packing.getpacking(doc_document_id) in('1', '2', '3') then
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
  end cust_delivery_port_batch;

  function suppl_order_port_batch(report_names in varchar2, parameter_11 in varchar2, fan_stk_qty in number, fan_netw_qty in number)
    return number
  is
/**
* Function SUPPL_ORDER_PORT_BATCH
* Description
*    Used in report: DOC_SUPPL_ORDER_PORT_SUPPL_BATCH
                     DOC_SUPPL_ORDER_PORT_GOOD_BATCH

     Instead of crystal's formula {@TEST_ATTRIB} Allocation
     Allocation
     PARAMETER_11 = '0'   NO CHECK BOX SELECTED
     PARAMETER_11 = '1'   NONE
     PARAMETER_11 = '2'   DOCUMENT
     PARAMETER_11 = '3'   NONE,DOCUMENT
     PARAMETER_11 = '4'   STOCK
     PARAMETER_11 = '5'   NONE,STOCK
     PARAMETER_11 = '6'   DOCUMENT,STOCK
     PARAMETER_11 = '7'   ALL CHECK BOX SELECTED

* @created MZHU 1 AUG 2007
* @lastUpdate 19 FEB 2009
* @private
* @param REPORT_NAMES  :  report name
* @param PARAMETER_11 :
* @param FAN_STK_QTY :
* @param FAN_NETW_QTY :
* @return  : number
*/
    result number(1);
  begin
    if report_names in('DOC_SUPPL_ORDER_PORT_SUPPL_BATCH', 'DOC_SUPPL_ORDER_PORT_GOOD_BATCH') then
      case parameter_11
        when '0' then
          result  := 1;
        when '1' then
          if     fan_stk_qty = 0
             and fan_netw_qty = 0 then
            result  := 1;
          else
            result  := 0;
          end if;
        when '2' then
          if (fan_netw_qty > 0) then
            result  := 1;
          else
            result  := 0;
          end if;
        when '3' then
          if (    (    fan_stk_qty = 0
                   and fan_netw_qty = 0)
              or fan_netw_qty > 0) then
            result  := 1;
          else
            result  := 0;
          end if;
        when '4' then
          if (fan_stk_qty > 0) then
            result  := 1;
          else
            result  := 0;
          end if;
        when '5' then
          if (    (    fan_stk_qty = 0
                   and fan_netw_qty = 0)
              or fan_stk_qty > 0) then
            result  := 1;
          else
            result  := 0;
          end if;
        when '6' then
          if (   fan_netw_qty > 0
              or fan_stk_qty > 0) then
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
  end suppl_order_port_batch;

  function suppl_order_port_batch_2(report_names in varchar2, parameter_13 in varchar2, c_doc_pos_status in varchar2, pde_final_delay in date)
    return number
  is
/**
* Function SUPPL_ORDER_PORT_BATCH_2
* Description
*    Used in report: DOC_SUPPL_ORDER_PORT_SUPPL_BATCH
                     DOC_SUPPL_ORDER_PORT_GOOD_BATCH

     Instead of crystal's formula {@TEST_RETARD} Lateness
* @created MZHU 1 AUG 2007
* @lastUpdate 19 FEB 2009
* @private
* @param REPORT_NAMES  :  report name
* @param PARAMETER_13 :
* @param C_DOC_POS_STATUS : postion status of document
* @param PDE_FINAL_DELAY : final delay
* @return  : number
*/
    result     number(1);
    delay_days number(38);
    p_13       number(38);
  begin
    p_13  := to_number(parameter_13);

    if report_names in('DOC_SUPPL_ORDER_PORT_SUPPL_BATCH', 'DOC_SUPPL_ORDER_PORT_GOOD_BATCH') then
      if c_doc_pos_status <> '04' then
        delay_days  := trunc(sysdate) - trunc(pde_final_delay);
      else
        delay_days  := 0;
      end if;

      if p_13 > 0 then
        if delay_days > p_13 then
          result  := 1;
        else
          result  := 0;
        end if;
      elsif p_13 < 0 then
        if delay_days < 0 then
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
  end suppl_order_port_batch_2;

  function suppl_turnover_batch(report_names in varchar2, parameter_9 in varchar2, c_gauge_title in varchar2, gas_financial_charge in number)
    return number
  is
/**
* Function SUPPL_TURNOVER_BATCH
* Description
*    Used in report: DOC_SUPPL_TURNOVER_SUPPL_BATCH
                     DOC_SUPPL_TURNOVER_GOOD_BATCH

     Turnover with credit over
* @created MZHU 1 AUG 2007
* @lastUpdate 19 FEB 2009
* @private
* @param REPORT_NAMES  :  report name
* @param PARAMETER_9 :
* @param C_GAUGE_TITLE : gauge title of document
* @param GAS_FINANCIAL_CHARGE :
* @return  : number
*/
    result number(1);
  begin
    if report_names in('DOC_SUPPL_TURNOVER_SUPPL_BATCH', 'DOC_SUPPL_TURNOVER_GOOD_BATCH') then
      case parameter_9
        when '0' then
          if c_gauge_title = '4' then
            result  := 1;
          else
            result  := 0;
          end if;
        when '1' then
          if    (    c_gauge_title = '5'
                 and gas_financial_charge = 1)
             or (c_gauge_title = '4') then
            result  := 1;
          else
            result  := 0;
          end if;
        when '2' then
          if     c_gauge_title = '5'
             and gas_financial_charge = 1 then
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
  end suppl_turnover_batch;

  function getaccountnumberlist(aacs_account_id_list in varchar2)
    return varchar2
  is
    accountnumberlist varchar2(100);
    accountnumber     varchar2(100);

    cursor curdtl
    is
      select acc.acc_number
        from acs_account acc
           , the(select cast(doc_document_list_functions.in_list(aacs_account_id_list) as char_table_type)
                   from dual) division_account_id_list
       where acc.acs_account_id = division_account_id_list.column_value;

    cursor curdt2
    is
      select acc.acc_number
        from acs_account acc
           , acs_sub_set sub
       where acc.acs_sub_set_id = sub.acs_sub_set_id
         and sub.c_type_sub_set = 'DIVI';
  begin
    if aacs_account_id_list = '#' then
      open curdt2;

      -- fetch curDt2 into AccountNumber;
      loop
        fetch curdt2
         into accountnumber;

        if curdt2%found then
          accountnumberlist  := accountnumberlist || accountnumber || ',';
        else
          exit;
        end if;
      end loop;

      if substr(accountnumberlist, -1) = ',' then
        accountnumberlist  := substr(accountnumberlist, 1, length(accountnumberlist) - 1);
      end if;

      close curdt2;
    else
      open curdtl;

      --fetch curDtl into AccountNumber;
      loop
        fetch curdtl
         into accountnumber;

        if curdtl%found then
          accountnumberlist  := accountnumberlist || accountnumber || ',';
        else
          exit;
        end if;
      end loop;

      if substr(accountnumberlist, -1) = ',' then
        accountnumberlist  := substr(accountnumberlist, 1, length(accountnumberlist) - 1);
      end if;

      close curdtl;
    end if;

    return trim(accountnumberlist);
  exception
    when others then
      return null;
  end getaccountnumberlist;

  /**
   * Description
   *       The function will return the financial year no according to the id given
   */
  function getfinancialyearno(aacs_financial_year_id in number)
    return number
  is
    result number;
  begin
    select fye.fye_no_exercice
      into result
      from acs_financial_year fye
     where fye.acs_financial_year_id = aacs_financial_year_id;

    return result;
  exception
    when others then
      return null;
  end getfinancialyearno;

  /**
   * Description
   *       The function will return the budget version according to the id given
   */
  function getbudgetversion(aacb_budget_version_id in number)
    return varchar2
  is
    result varchar2(30);
  begin
    select ver.ver_number
      into result
      from acb_budget_version ver
     where ver.acb_budget_version_id = aacb_budget_version_id;

    return result;
  exception
    when others then
      return null;
  end getbudgetversion;

  function getinterestbalanceamountfc(
    pjobid                    act_job.act_job_id%type
  , pfinaccid                 acs_financial_account.acs_financial_account_id%type
  , pdivaccid                 acs_division_account.acs_division_account_id%type
  , pacs_financal_currency_id act_interest_detail.acs_financial_currency_id%type
  , ptype                     number
  )
    return act_interest_detail.ide_balance_amount%type
  is
    cursor interestdetail
    is
      select   ide_balance_amount
          from act_interest_detail
         where act_job_id = pjobid
           and acs_financial_account_id = pfinaccid
           and (   acs_division_account_id = pdivaccid
                or pdivaccid is null)
      --and ACS_FINANCIAL_CURRENCY_ID <> pACS_FINANCAL_CURRENCY_ID
      order by ide_value_date desc
             , nvl(ide_transaction_date, ide_value_date) desc
             , nvl(act_financial_imputation_id, 0) desc;

    vamount act_interest_detail.ide_balance_amount%type;
  begin
    if ptype = 0 then
      open interestdetail;

      fetch interestdetail
       into vamount;

      close interestdetail;
    elsif ptype = 1 then
      select nvl(sum(imf_amount_fc_d - imf_amount_fc_c), 0)
        into vamount
        from v_act_interest_document_fc
       where act_job_id = pjobid
         and acs_financial_account_id = pfinaccid
         and (   acs_division_account_id = pdivaccid
              or pdivaccid is null);
    end if;

    return vamount;
  end getinterestbalanceamountfc;

  function getqtystock(agoodid gco_good.gco_good_id%type, astocklist in clob default null, alocationlist in clob default null)
    return varchar2
  is
    result number;
  begin
    select sum(a.spo_stock_quantity)
      into result
      from stm_stock_position a
     where a.gco_good_id = agoodid
       and (   instr(astocklist, ',' || to_char(a.stm_stock_id) || ',') > 0
            or astocklist is null)
       and (   instr(alocationlist, ',' || to_char(a.stm_location_id) || ',') > 0
            or alocationlist is null);

    return to_char(result);
  --  RETURN ANNEE||MOIS;
  exception
    when no_data_found then
      return '0';
  end getqtystock;

/*******************************************************************************************************************************/
/* Retourne la quantité en commande fournisseur                                                                                */
/*******************************************************************************************************************************/
  function getqtycf(agoodid gco_good.gco_good_id%type, astocklist in clob default null, alocationlist in clob default null)
    return varchar2
  is
    result number;
  begin
    select sum(a.fan_balance_qty)
      into result
      from fal_network_supply a
     where a.gco_good_id = agoodid
       and a.doc_position_detail_id is not null
       and (   instr(astocklist, ',' || to_char(a.stm_stock_id) || ',') > 0
            or astocklist is null)
       and (   instr(alocationlist, ',' || to_char(a.stm_location_id) || ',') > 0
            or alocationlist is null);

    return to_char(result);
  --  RETURN ANNEE||MOIS;
  exception
    when no_data_found then
      return '0';
  end getqtycf;

/*******************************************************************************************************************************/
/* Retourne la quantité en commande client                                                                                     */
/*******************************************************************************************************************************/
  function getqtycc(agoodid gco_good.gco_good_id%type, astocklist in clob default null, alocationlist in clob default null)
    return varchar2
  is
    result number;
  begin
    select sum(a.fan_balance_qty)
      into result
      from fal_network_need a
     where a.gco_good_id = agoodid
       and a.doc_position_detail_id is not null
       and (   instr(astocklist, ',' || to_char(a.stm_stock_id) || ',') > 0
            or astocklist is null)
       and (   instr(alocationlist, ',' || to_char(a.stm_location_id) || ',') > 0
            or alocationlist is null);

    return to_char(result);
  exception
    when no_data_found then
      return '0';
  end getqtycc;

  function getpernumber(aacs_period_id act_total_by_period.acs_period_id%type default null)
    return acs_period.per_no_period%type
  is
    num             acs_period.per_no_period%type;
    financialyearid acs_period.acs_financial_year_id%type;
  begin
    if aacs_period_id is null then
      financialyearid  := acs_function.getmaxnoexerciceid;

      select max(per_no_period)
        into num
        from acs_period
       where acs_financial_year_id = financialyearid;
    else
      begin
        select acs_financial_year_id
             , per_no_period
          into financialyearid
             , num
          from acs_period
         where acs_period_id = aacs_period_id;
      exception
        when no_data_found then
          financialyearid  := null;
          num              := null;
      end;
    end if;

    return num;
  end;

  /**
  * Description
  * To get the address information for DOC_STD_3
  */
  function getdocadr(adoc_document_id number, atype number, ablock number, apc_lang_id number)
    return varchar2
  is
    result                varchar2(4000 char);
    result_title          varchar2(4000 char);
    result_name           varchar2(4000 char);
    result_info           varchar2(4000 char);
    vc_gauge_title        varchar2(10 char);
    vgas_financial_charge number(1);
    adr1_title            varchar2(4000 char);
    adr1_name             varchar2(4000 char);
    adr1_info             varchar2(4000 char);
    adr2_title            varchar2(4000 char);
    adr2_name             varchar2(4000 char);
    adr2_info             varchar2(4000 char);
    adr3_title            varchar2(4000 char);
    adr3_name             varchar2(4000 char);
    adr3_info             varchar2(4000 char);
    lAdminDomain          DOC_GAUGE.C_ADMIN_DOMAIN%type;
  /*

  "   Adresse du donneur d'ordre (Adr1)
    Partner address
  "   Adresse de livraison (Adr2)
    Delivery address
  "   Adresse de facturation (Adr3)
    Invoice address

  */
  begin
    select gas.c_gauge_title
         , gas.gas_financial_charge
         , gau.c_admin_domain
      into vc_gauge_title
         , vgas_financial_charge
         , lAdminDomain
      from doc_document dmt
         , doc_gauge gau
         , doc_gauge_structured gas
     where dmt.doc_gauge_id = gau.doc_gauge_id
       and gas.doc_gauge_id = gau.doc_gauge_id
       and dmt.doc_document_id = adoc_document_id;

    -- Si domaine achats
    if lAdminDomain = '1' then
      adr1_title  := pcs.pc_functions.translateword('Adresse preneur d''ordre', apc_lang_id);
    else
      adr1_title  := pcs.pc_functions.translateword('Adresse donneur d ordre', apc_lang_id);
    end if;

    adr3_title  := pcs.pc_functions.translateword('Adresse de facturation', apc_lang_id);
    adr2_title  := pcs.pc_functions.translateword('Adresse de livraison', apc_lang_id);

    select nvl(dmt.dmt_name1, per.per_name) per_name
         , nvl(dmt.dmt_name2, per2.per_name) per2_name
         , nvl(dmt.dmt_name3, per3.per_name) per3_name
         , decode(dmt.dmt_forename1, null, '', dmt.dmt_forename1 || chr(13) ) ||
           decode(dmt.dmt_contact1, null, '', dmt.dmt_contact1 || chr(13) ) ||
           decode(dmt.dmt_activity1, null, '', dmt.dmt_activity1 || chr(13) ) ||
           decode(dmt.dmt_care_of1, null, '', dmt.dmt_care_of1 || chr(13) ) ||
           decode(dmt.dmt_address1, null, '', dmt.dmt_address1 || chr(13) ) ||
           decode(dmt.dmt_po_box1 || dmt.dmt_po_box_nbr1
                , null, ''
                , dmt.dmt_po_box1 || decode(dmt.dmt_po_box_nbr1, null, '', decode(dmt.dmt_po_box1, null, '', ' ') || dmt.dmt_po_box_nbr1) || chr(13)
                 ) ||
           decode(dmt.dmt_format_city1, null, '', dmt.dmt_format_city1) add_1
         , decode(dmt.dmt_forename2, null, '', dmt.dmt_forename2 || chr(13) ) ||
           decode(dmt.dmt_contact2, null, '', dmt.dmt_contact2 || chr(13) ) ||
           decode(dmt.dmt_activity2, null, '', dmt.dmt_activity2 || chr(13) ) ||
           decode(dmt.dmt_care_of2, null, '', dmt.dmt_care_of2 || chr(13) ) ||
           decode(dmt.dmt_address2, null, '', dmt.dmt_address2 || chr(13) ) ||
           decode(dmt.dmt_po_box2 || dmt.dmt_po_box_nbr2
                , null, ''
                , dmt.dmt_po_box2 || decode(dmt.dmt_po_box_nbr2, null, '', decode(dmt.dmt_po_box2, null, '', ' ') || dmt.dmt_po_box_nbr2) || chr(13)
                 ) ||
           decode(dmt.dmt_format_city2, null, '', dmt.dmt_format_city2) add_2
         , decode(dmt.dmt_forename3, null, '', dmt.dmt_forename3 || chr(13) ) ||
           decode(dmt.dmt_contact3, null, '', dmt.dmt_contact3 || chr(13) ) ||
           decode(dmt.dmt_activity3, null, '', dmt.dmt_activity3 || chr(13) ) ||
           decode(dmt.dmt_care_of3, null, '', dmt.dmt_care_of3 || chr(13) ) ||
           decode(dmt.dmt_address3, null, '', dmt.dmt_address3 || chr(13) ) ||
           decode(dmt.dmt_po_box3 || dmt.dmt_po_box_nbr3
                , null, ''
                , dmt.dmt_po_box3 || decode(dmt.dmt_po_box_nbr3, null, '', decode(dmt.dmt_po_box3, null, '', ' ') || dmt.dmt_po_box_nbr3) || chr(13)
                 ) ||
           decode(dmt.dmt_format_city3, null, '', dmt.dmt_format_city3) add_3
      into adr1_name
         , adr2_name
         , adr3_name
         , adr1_info
         , adr2_info
         , adr3_info
      from doc_document dmt
         , pac_address adr
         , pac_address adr2
         , pac_address adr3
         , pac_person per
         , pac_person per2
         , pac_person per3
     where dmt.pac_address_id = adr.pac_address_id(+)
       and adr.pac_person_id = per.pac_person_id(+)
       and dmt.pac_pac_address_id = adr2.pac_address_id(+)
       and adr2.pac_person_id = per2.pac_person_id(+)
       and dmt.pac2_pac_address_id = adr3.pac_address_id(+)
       and adr3.pac_person_id = per3.pac_person_id(+)
       and dmt.doc_document_id = adoc_document_id;

      /*
      BLOC 1
    "  Pour les documents de type 7 (Bulletin de livraison) pour lesquels on imprime l'adresse de livraison (Adr2)
    For 7 (delivery Bulletin) documents print the address of delivery (Adr2)
    "  Pour les documents de type  (Commandes - Offres) pour lesquels on imprime l'adresse du donneur d'ordre (Adr1)
    For (orders - offers) documents print the address of the customer (Adr1)
    "  Dans le cas d'un Retour fournisseur non valoris? on n'affiche pas d'adresse dans ce bloc car il s'agit d'un document interne
    In the case of a provider not recovered back, it does not address display in this block because it is an internal document
    "  Pour tous les autres documents, on imprime l'adresse de facturation (Adr3)
    For all other documents we print the billing address (Adr3)

      */
    if ablock = 1   --get the information for the 1st block
                 then
      if vc_gauge_title = '7' then
        result_title  := adr2_title;
        result_name   := adr2_name;
        result_info   := adr2_info;
      elsif     vc_gauge_title = '5'
            and vgas_financial_charge = 0 then
        result_title  := '';
        result_name   := '';
        result_info   := '';
      elsif vc_gauge_title in('1', '6', '11', '12', '60') then
        result_title  := adr1_title;
        result_name   := adr1_name;
        result_info   := adr1_info;
      else
        result_title  := adr3_title;
        result_name   := adr3_name;
        result_info   := adr3_info;
      end if;

      if     result_name is null
         and result_info is null then
        result_title  := null;
      end if;
    end if;

      /*
      BLOC 2
    R?les d'application
    "  S'il s'agit d'un BL et que l'adresse de livraison (adr2) et diff?ente de l'adresse de facturation (Adr3) alors on imprime l'adresse de facturation (Adr3)
    If it is a BL and address of delivery (adr2) and different from the billing address (Adr3) then we print the address of billing (Adr3)
    "  Dans tous les autres cas si l'adresse de livraison (Adr2) est diff?ente de l'adresse de facturation (Adr3) alors on imprime l'adresse de Livraison (Adr2) sinon vide
    In all other cases if the delivery address (Adr2) is different from the billing address (Adr3) then it to print the address of delivery (Adr2) otherwise empty
    "  Dans le cas d'un Retour fournisseur non valoris? on affiche l'adresse de livraison
    In the case of a provider not valued return, contains the address of delivery(ADR2)
      */
    if ablock = 2   --get the information for the 2nd block
                 then
      if vc_gauge_title = '7' then
        if (nvl(adr2_info, ' ') <> nvl(adr3_info, ' ') ) then
          result_title  := adr3_title;
          result_name   := adr3_name;
          result_info   := adr3_info;
        end if;
      elsif     vc_gauge_title = '5'
            and vgas_financial_charge = 0 then
        result_title  := adr2_title;
        result_name   := adr2_name;
        result_info   := adr2_info;
      elsif vc_gauge_title in('1', '6', '11', '12', '60') then
        if (nvl(adr2_info, ' ') <> nvl(adr1_info, ' ') ) then
          result_title  := adr2_title;
          result_name   := adr2_name;
          result_info   := adr2_info;
        end if;
      elsif nvl(adr2_info, ' ') <> nvl(adr3_info, ' ') then
        result_title  := adr2_title;
        result_name   := adr2_name;
        result_info   := adr2_info;
      end if;

      if     result_name is null
         and result_info is null then
        result_title  := null;
      end if;
    end if;

      /*
      BLOC 3
    R?les d'application
    "  S'il s'agit de commandes - offres et que l'adresse de facturation est diff?ente de celle du donneur d'ordre alors on imprime l'adresse de facturation (Adr3)
    If it orders - offers and the billing address is different from the customer then we print the billing address (Adr3)
    "  Dans les autres cas, si l'adresse du donneur d'ordre (Adr1) <> adresse de facturation (Adr3) alors on imprime l'adresse du donneur d'ordre (Adr1) sinon vide
    In other cases, if the address of the customer (Adr1) <> address of invoicing (Adr3) then we print the address of the customer (Adr1) otherwise empty

      */
    if ablock = 3   --get the information for the 2rd block
                 then
      if vc_gauge_title in('1', '6', '11', '12', '60') then
        if (nvl(adr3_info, ' ') <> nvl(adr1_info, ' ') ) then
          result_title  := adr3_title;
          result_name   := adr3_name;
          result_info   := adr3_info;
        end if;
      elsif     vc_gauge_title = '5'
            and vgas_financial_charge = 0 then
        if nvl(adr1_info, ' ') <> nvl(adr2_info, ' ') then
          result_title  := adr1_title;
          result_name   := adr1_name;
          result_info   := adr1_info;
        end if;
      elsif nvl(adr1_info, ' ') <> nvl(adr3_info, ' ') then
        result_title  := adr1_title;
        result_name   := adr1_name;
        result_info   := adr1_info;
      end if;

      if     result_name is null
         and result_info is null then
        result_title  := null;
      end if;
    end if;

    if atype = 1   --get the info for the title
                then
      result  := result_title;
    elsif atype = 2   --get the info for the name
                   then
      result  := result_name;
    elsif atype = 3   --get the info for the detail address information
                   then
      result  := result_info;
    end if;

    return result;
  exception
    when others then
      return null;
  end;

  function getasaadr(aasa_record_id number, atype number, ablock number, apc_lang_id number)
    return varchar2
  is
    result       varchar2(4000 char);
    result_title varchar2(4000 char);
    result_name  varchar2(4000 char);
    result_info  varchar2(4000 char);
    adr1_title   varchar2(4000 char);
    adr1_name    varchar2(4000 char);
    adr1_info    varchar2(4000 char);
    adr2_title   varchar2(4000 char);
    adr2_name    varchar2(4000 char);
    adr2_info    varchar2(4000 char);
    adr3_title   varchar2(4000 char);
    adr3_name    varchar2(4000 char);
    adr3_info    varchar2(4000 char);
  begin
    adr1_title  := pcs.pc_functions.translateword('Adresse donneur d ordre', apc_lang_id);
    adr2_title  := pcs.pc_functions.translateword('Adresse de livraison', apc_lang_id);
    adr3_title  := pcs.pc_functions.translateword('Adresse de facturation', apc_lang_id);

    select per.per_name
         , per2.per_name
         , per3.per_name
         , decode(per.per_forename, null, '', per.per_forename || chr(13) ) ||
           decode(are.are_care_of1, null, '', are.are_care_of1 || chr(13) ) ||
           decode(are.are_address1, null, '', are.are_address1 || chr(13) ) ||
           decode(are.are_format_city1, null, '', are.are_format_city1 || chr(13) ) add_1
         , decode(per2.per_forename, null, '', per2.per_forename || chr(13) ) ||
           decode(are.are_care_of2, null, '', are.are_care_of2 || chr(13) ) ||
           decode(are.are_address2, null, '', are.are_address2 || chr(13) ) ||
           decode(are.are_format_city2, null, '', are.are_format_city2 || chr(13) ) add_2
         , decode(per3.per_forename, null, '', per3.per_forename || chr(13) ) ||
           decode(are.are_care_of3, null, '', are.are_care_of3 || chr(13) ) ||
           decode(are.are_address3, null, '', are.are_address3 || chr(13) ) ||
           decode(are.are_format_city3, null, '', are.are_format_city3 || chr(13) ) add_3
      into adr1_name
         , adr2_name
         , adr3_name
         , adr1_info
         , adr2_info
         , adr3_info
      from asa_record are
         , pac_address adr
         , pac_address adr2
         , pac_address adr3
         , pac_person per
         , pac_person per2
         , pac_person per3
     where are.pac_asa_addr1_id = adr.pac_address_id
       and adr.pac_person_id = per.pac_person_id(+)
       and are.pac_asa_addr2_id = adr2.pac_address_id(+)
       and adr2.pac_person_id = per2.pac_person_id(+)
       and are.pac_asa_addr3_id = adr3.pac_address_id(+)
       and adr3.pac_person_id = per3.pac_person_id(+)
       and are.asa_record_id = aasa_record_id;

    if ablock = 1   --get the information for the 1st block
                 then
      result_title  := adr1_title;
      result_name   := adr1_name;
      result_info   := adr1_info;
    end if;

    if ablock = 2   --get the information for the 2nd block
                 then
      if adr1_info <> adr2_info then
        result_title  := adr2_title;
        result_name   := adr2_name;
        result_info   := adr2_info;
      end if;
    end if;

    if ablock = 3   --get the information for the 2rd block
                 then
      if     adr1_info <> adr3_info
         and adr2_info <> adr3_info then
        result_title  := adr3_title;
        result_name   := adr3_name;
        result_info   := adr3_info;
      end if;
    end if;

    if atype = 1   --get the info for the title
                then
      result  := result_title;
    elsif atype = 2   --get the info for the name
                   then
      result  := result_name;
    elsif atype = 3   --get the info for the detail address information
                   then
      result  := result_info;
    end if;

    return result;
  exception
    when others then
      return null;
  end;

  function getqtystockt(agoodid gco_good.gco_good_id%type, ajobid in number)
    return number
  is
    result number;
  begin
    select sum(a.spo_stock_quantity)
      into result
      from stm_stock_position a
         , com_list l
     where a.gco_good_id = agoodid
       and l.lis_job_id = ajobid
       and l.lis_code = 'STM_LOCATION_ID'
       and l.lis_id_1 = a.stm_location_id;

    return result;
  --  RETURN ANNEE||MOIS;
  exception
    when no_data_found then
      return 0;
  end getqtystockt;

/*******************************************************************************************************************************/
/* Retourne la quantit?en commande fournisseur                                                                                */
/*******************************************************************************************************************************/
  function getqtycft(agoodid gco_good.gco_good_id%type, ajobid in number)
    return number
  is
    result number;
  begin
    select sum(a.fan_balance_qty)
      into result
      from fal_network_supply a
         , com_list l
     where a.gco_good_id = agoodid
       and a.doc_position_detail_id is not null
       and l.lis_job_id = ajobid
       and l.lis_code = 'STM_LOCATION_ID'
       and l.lis_id_1 = a.stm_location_id;

    return result;
  --  RETURN ANNEE||MOIS;
  exception
    when no_data_found then
      return 0;
  end getqtycft;

/*******************************************************************************************************************************/
/* Retourne la quantit?en commande client                                                                                     */
/*******************************************************************************************************************************/
  function getqtycct(agoodid gco_good.gco_good_id%type, ajobid in number)
    return number
  is
    result number;
  begin
    select sum(a.fan_balance_qty)
      into result
      from fal_network_need a
         , com_list l
     where a.gco_good_id = agoodid
       and a.doc_position_detail_id is not null
       and l.lis_job_id = ajobid
       and l.lis_code = 'STM_LOCATION_ID'
       and l.lis_id_1 = a.stm_location_id + 0;

    return result;
  exception
    when no_data_found then
      return 0;
  end getqtycct;

/**
* Function CgetselectedstockatdateT
* Description
*    Used in the procedure RPT_STM_QTY_EOM_WITH_GRP of report STM_QTY_END_OF_MONTH_WITH_GROUP
* @created AWU 11 NOV 2009
* @updated FPE 16 APR 2009
*/
  function getselectedstockatdatet(agoodid in number, adate in varchar2, ajobid in number)
    return number
  is
    vresult          stm_stock_position.spo_stock_quantity%type      := 0;
    vmovementsqty    stm_stock_movement.smo_movement_quantity%type;
    vstockqty        stm_stock_position.spo_stock_quantity%type;
    vstockmanagement gco_product.pdt_stock_management%type;
    visdate          date;
    vlocation        varchar2(4000);
  begin
    select pdt_stock_management
      into vstockmanagement
      from gco_product
     where gco_good_id = agoodid;

    -- if no stock management of the product then return 0
    if vstockmanagement in(1, 2) then
      visdate  := to_date(adate, 'YYYYMMDD');

      select nvl(sum(spo_stock_quantity), 0)
        into vstockqty
        from stm_stock_position a
           , com_list l
       where gco_good_id = agoodid
         and l.lis_job_id = ajobid
         and l.lis_code = 'STM_LOCATION_ID'
         and l.lis_id_1 = a.stm_location_id;

      select nvl(sum(decode(c_movement_sort, 'ENT', smo_movement_quantity, smo_movement_quantity * -1) ), 0)
        into vmovementsqty
        from stm_stock_movement stm
           , stm_movement_kind kind
           , com_list l
       where gco_good_id = agoodid
         and l.lis_job_id = ajobid
         and l.lis_code = 'STM_LOCATION_ID'
         and l.lis_id_1 = stm.stm_location_id
         and stm.stm_movement_kind_id = kind.stm_movement_kind_id
         and c_movement_type <> 'EXE'
         and trunc(stm.smo_movement_date) > trunc(visdate);

      vresult  := vstockqty - vmovementsqty;
    end if;

    return vresult;
  end getselectedstockatdatet;

  function formataddressconvertion(p_pac_address_id in number)
    return varchar2
  is
    p_add_format varchar2(255 char);
    v_add_format varchar2(255 char);
  begin
    select adr.add_format
      into p_add_format
      from pac_address adr
     where adr.pac_address_id = p_pac_address_id;

    v_add_format  := replace(p_add_format, chr(10), ', ');

    /* Combine different lines into one line */
    loop   /* Get rid of needless space */
      if instr(v_add_format, '  ') <> 0 then
        v_add_format  := replace(v_add_format, '  ', ' ');
      else
        exit;
      end if;
    end loop;

    v_add_format  := replace(v_add_format, ' ,', ',');
    v_add_format  := replace(v_add_format, ',,', ',');
    return v_add_format;
  end formataddressconvertion;

  function getpacadr(apacid in number, aoption in number)
    return varchar2
  is
    vadd varchar2(4000);
    vzip varchar2(4000);
    vcty varchar2(4000);
    vsta varchar2(4000);
  begin
    begin
      select adr.add_address1
           , adr.add_zipcode
           , adr.add_city
           , adr.add_state
        into vadd
           , vzip
           , vcty
           , vsta
        from pac_address adr
       where adr.pac_person_id = apacid
         and adr.add_principal = 1;
    end;

    case aoption
      when 0 then
        return vadd;
      when 1 then
        return vzip;
      when 2 then
        return vcty;
      when 3 then
        return vsta;
      else
        return vadd;
    end case;
  end getpacadr;

  /**
  * PROCEDURE InsertSelectedStockatDate
  * Description
  * Insert the data into table COM_LIST
  */
  procedure insertselectedstockatdate(adate in varchar2, ajobid in number, agoodsel in varchar2, ajobid2 in number, ajobid3 in number)
  is
    visdate          date;
    vlis_description varchar2(4000 char);
    va_idcre         varchar2(5 char);
    va_datecre       date;
    vsession_id      varchar2(24);
  begin
    visdate           := to_date(adate, 'YYYYMMDD');
    vlis_description  := 'Stock qty for report STM_QTY_END_OF_MONTH_WITH_GROUP';
    va_idcre          := pcs.PC_I_LIB_SESSION.getuserini;
    va_datecre        := sysdate;

    select init_id_seq.nextval
      into vsession_id
      from dual;

    if agoodsel = '1'   --all products
                     then
      insert into com_list
                  (com_list_id
                 , lis_session_id
                 , lis_job_id
                 , lis_description
                 , a_idcre
                 , a_datecre
                 , lis_id_1
                 , lis_free_number_1
                  )
        (select init_id_seq.nextval
              , vsession_id
              , ajobid3
              , vlis_description
              , va_idcre
              , va_datecre
              , pdt.gco_good_id
              , nvl(v1.qty, 0) - nvl(v2.qty, 0)
           from (select   gco_good_id
                        , nvl(sum(spo_stock_quantity), 0) qty
                     from stm_stock_position a
                        , com_list l
                    where l.lis_job_id = ajobid
                      and l.lis_code = 'STM_LOCATION_ID'
                      and l.lis_id_1 = a.stm_location_id
                 group by gco_good_id) v1
              , (select   stm.gco_good_id
                        , nvl(sum(decode(c_movement_sort, 'ENT', smo_movement_quantity, smo_movement_quantity * -1) ), 0) qty
                     from stm_stock_movement stm
                        , stm_movement_kind kind
                        , com_list l
                    where l.lis_job_id = ajobid
                      and l.lis_code = 'STM_LOCATION_ID'
                      and l.lis_id_1 = stm.stm_location_id
                      and stm.stm_movement_kind_id = kind.stm_movement_kind_id
                      and trunc(stm.smo_movement_date) > trunc(visdate)
                      and c_movement_type <> 'EXE'
                 group by stm.gco_good_id) v2
              , gco_product pdt
          where pdt.pdt_stock_management in(1, 2)
            and pdt.gco_good_id = v1.gco_good_id(+)
            and pdt.gco_good_id = v2.gco_good_id(+));
    else
      insert into com_list
                  (com_list_id
                 , lis_session_id
                 , lis_job_id
                 , lis_description
                 , a_idcre
                 , a_datecre
                 , lis_id_1
                 , lis_free_number_1
                  )
        (select init_id_seq.nextval
              , vsession_id
              , ajobid3
              , vlis_description
              , va_idcre
              , va_datecre
              , pdt.gco_good_id
              , nvl(v1.qty, 0) - nvl(v2.qty, 0)
           from (select   gco_good_id
                        , nvl(sum(spo_stock_quantity), 0) qty
                     from stm_stock_position a
                        , com_list l
                    where l.lis_job_id = ajobid
                      and l.lis_code = 'STM_LOCATION_ID'
                      and l.lis_id_1 = a.stm_location_id
                 group by gco_good_id) v1
              , (select   stm.gco_good_id
                        , nvl(sum(decode(c_movement_sort, 'ENT', smo_movement_quantity, smo_movement_quantity * -1) ), 0) qty
                     from stm_stock_movement stm
                        , stm_movement_kind kind
                        , com_list l
                    where l.lis_job_id = ajobid
                      and l.lis_code = 'STM_LOCATION_ID'
                      and l.lis_id_1 = stm.stm_location_id
                      and stm.stm_movement_kind_id = kind.stm_movement_kind_id
                      and trunc(stm.smo_movement_date) > trunc(visdate)
                      and c_movement_type <> 'EXE'
                 group by stm.gco_good_id) v2
              , gco_product pdt
              , com_list goo_list
          where pdt.pdt_stock_management in(1, 2)
            and pdt.gco_good_id = goo_list.lis_id_1
            and goo_list.lis_job_id = ajobid2
            and goo_list.lis_code = 'GCO_GOOD_ID'
            and pdt.gco_good_id = v1.gco_good_id(+)
            and pdt.gco_good_id = v2.gco_good_id(+));
    end if;

    commit;
  end insertselectedstockatdate;

/**
   * PROCEDURE InsertSelectedStockatDate - Vers 400.1
   * Description
   * Insert the data into table COM_LIST
   */
  procedure insertselectedstockatdate4(adate in varchar2, ajobid in number, agoodmin in varchar2, agoodmax in varchar2)
  is
    visdate          date;
    vlis_description varchar2(4000 char);
    va_idcre         varchar2(5 char);
    va_datecre       date;
    vsession_id      varchar2(24);
  begin
    visdate           := to_date(adate, 'YYYYMMDD');
    vlis_description  := 'Stock qty for report STM_QTY_END_OF_MONTH_WITH_GROUP';
    va_idcre          := pcs.PC_I_LIB_SESSION.getuserini;
    va_datecre        := sysdate;

    select init_id_seq.nextval
      into vsession_id
      from dual;

    insert into com_list
                (com_list_id
               , lis_session_id
               , lis_job_id
               , lis_description
               , a_idcre
               , a_datecre
               , lis_id_1
               , lis_free_number_1
                )
      (select init_id_seq.nextval
            , vsession_id
            , ajobid
            , vlis_description
            , va_idcre
            , va_datecre
            , pdt.gco_good_id
            , nvl(v1.qty, 0) - nvl(v2.qty, 0)
         from (select   gco_good_id
                      , nvl(sum(spo_stock_quantity), 0) qty
                   from stm_stock_position a
                      , com_list l
                  where l.lis_job_id = ajobid
                    and l.lis_code = 'STM_LOCATION_ID'
                    and l.lis_id_1 = a.stm_location_id
               group by gco_good_id) v1
            , (select   stm.gco_good_id
                      , nvl(sum(decode(c_movement_sort, 'ENT', smo_movement_quantity, smo_movement_quantity * -1) ), 0) qty
                   from stm_stock_movement stm
                      , stm_movement_kind kind
                      , com_list l
                  where l.lis_job_id = ajobid
                    and l.lis_code = 'STM_LOCATION_ID'
                    and l.lis_id_1 = stm.stm_location_id
                    and stm.stm_movement_kind_id = kind.stm_movement_kind_id
                    and trunc(stm.smo_movement_date) > trunc(sysdate)
                    and c_movement_type <> 'EXE'
               group by stm.gco_good_id) v2
            , gco_product pdt
            , gco_good gco
        where pdt.pdt_stock_management in(1, 2)
          and pdt.gco_good_id = gco.gco_good_id
          and gco.goo_major_reference >= agoodmin
          and gco.goo_major_reference <= agoodmax
          and pdt.gco_good_id = v1.gco_good_id(+)
          and pdt.gco_good_id = v2.gco_good_id(+));

    commit;
  end insertselectedstockatdate4;

  /**
  * Description
  * To get the attached image path for the repair
  */
  function get_asa_img_path(arecid in number)
    return varchar2
  is
    result varchar2(4000 char);
  begin
    select imf.imf_pathfile
      into result
      from com_image_files imf
         , (select   a.imf_rec_id
                   , min(a.imf_sequence) imf_sequence
                from com_image_files a
               where upper(substr(a.imf_file, instr(a.imf_file, '.', -1) + 1)
                                                                              -- get the extension for the file
                     ) in('JPG', 'JPEG', 'BMP')
            /*AND rpt_functions.check_file_exist
                       (SUBSTR (a.imf_pathfile,
                                1,
                                INSTR (a.imf_pathfile, '\', -1)
                               ),                      --file directory
                        SUBSTR (a.imf_pathfile,
                                INSTR (a.imf_pathfile, '\', -1) + 1
                               )                            --file name
                       ) = 1*/
            group by imf_rec_id) v
     where imf.imf_rec_id = v.imf_rec_id
       and imf.imf_sequence = v.imf_sequence
       and imf.imf_rec_id = arecid;

    return result;
  exception
    when others then
      return null;
  end get_asa_img_path;

  /**
  * Description
  * To check whether this file exist in the OS or not
  */
  function check_file_exist(apath in varchar2, afilename in varchar2)
    return number
  is
    ex     boolean;
    flen   number;
    bsize  number;
    result number(1);
  begin
    UTL_FILE.fgetattr(apath, afilename, ex, flen, bsize);

    if ex then
      result  := 1;
    else
      result  := 0;
    end if;

    return result;
    return result;
  exception
    when others then
      return 0;
  end check_file_exist;

  /**
  * Description
  * This function returns the standard name of the report passed in parameter
  */
  function GetStdReportName(ivReportName in PCS.PC_REPORT.REP_REPNAME%type, inCallingObjectId in PCS.PC_OBJECT.PC_OBJECT_ID%type)
    return PCS.PC_REPORT.REP_REPNAME%type
  is
    lvResult varchar2(500);
  begin
    begin
      select RPT.REP_REPNAME
        into lvResult
        from PCS.PC_REPORT RPT
       where exists(
               select 1
                 from PCS.PC_REPLACE_REPORT RPC1
                    , PCS.PC_REPORT RPT1
                where RPC1.PC_REPORT2_ID = RPT1.PC_REPORT_ID
                  and RPC1.PC_OBJECT_ID = inCallingObjectId
                  and upper(RPT1.REP_REPNAME) = upper(ivReportName)
                  and RPT.PC_REPORT_ID = RPC1.PC_REPORT1_ID);

      return lvResult;
    exception
      when others then
        return ivReportName;
    end;
  end GetStdReportName;

  /**
  * Description
  *    Test si une division est autorisée pour pour les formes d'impression pour un utilisateur donné
  */
  function PrintingDivisionAuthorized(
    aACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT.ACS_DIVISION_ACCOUNT_ID%type
  , aPC_USER_ID              PCS.PC_USER.PC_USER_ID%type default null
  )
    return number
  is
    Cont       boolean                           := true;
    TestExists ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
  begin
    if     (aPC_USER_ID is not null)
       and (aPC_USER_ID != 0)
       and (upper(PCS.PC_CONFIG.GetConfig('ACJ_USER_DIV_REPORTING') ) = 'TRUE') then
      select max(AUTH.ACS_DIVISION_ACCOUNT_ID)
        into TestExists
        from ACS_AUTHORIZED_DIVISION_ACC AUTH
       where (   exists(select 0
                          from PCS.PC_USER_GROUP
                         where PC_USER_ID = aPC_USER_ID
                           and USE_GROUP_ID = AUTH.PC_USER_ID)
              or AUTH.PC_USER_ID = aPC_USER_ID);

      if TestExists is not null then
        select max(AUTH.ACS_DIVISION_ACCOUNT_ID)
          into TestExists
          from ACS_AUTHORIZED_DIVISION_ACC AUTH
         where AUTH.ACS_DIVISION_ACCOUNT_ID = aACS_DIVISION_ACCOUNT_ID
           and (   exists(select 0
                            from PCS.PC_USER_GROUP
                           where PC_USER_ID = aPC_USER_ID
                             and USE_GROUP_ID = AUTH.PC_USER_ID)
                or AUTH.PC_USER_ID = aPC_USER_ID);

        Cont  := TestExists is not null;
      end if;
    end if;

    if Cont then
      return 1;
    else
      return 0;
    end if;
  end PrintingDivisionAuthorized;

  /**
  * Description
  *    Retourne toutes les divisions autorisées dans les formes d'impression pour une date et un utilisateur donné
  */
  function TableAuthRptDivisions(aPC_USER_ID PCS.PC_USER.PC_USER_ID%type default null, lstdivisions varchar2 default null)
    return ID_TABLE_TYPE
  is
    TestExists ACS_ACCOUNT.ACS_ACCOUNT_ID%type;
    result     ID_TABLE_TYPE;
  begin
    TestExists := null;
    if PCS.PC_CONFIG.GetBooleanConfig('ACJ_USER_DIV_REPORTING') then
      if     (aPC_USER_ID is not null)
         and (aPC_USER_ID != 0) then
        select max(AUTH.ACS_DIVISION_ACCOUNT_ID)
          into TestExists
          from ACS_AUTHORIZED_DIVISION_ACC AUTH
         where (   exists(select 0
                            from PCS.PC_USER_GROUP
                           where PC_USER_ID = aPC_USER_ID
                             and USE_GROUP_ID = AUTH.PC_USER_ID)
                or AUTH.PC_USER_ID = aPC_USER_ID);
      end if;
    end if;

    if TestExists is not null then
      select cast(multiset(select distinct (AUTH.ACS_DIVISION_ACCOUNT_ID)
                                      from ACS_ACCOUNT ACC
                                         , ACS_AUTHORIZED_DIVISION_ACC AUTH
                                     where AUTH.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                                       and (   exists(select 0
                                                        from PCS.PC_USER_GROUP
                                                       where PC_USER_ID = aPC_USER_ID
                                                         and USE_GROUP_ID = AUTH.PC_USER_ID)
                                            or AUTH.PC_USER_ID = aPC_USER_ID)
                                       and (    (lstdivisions is null)
                                            or (instr(',' || lstdivisions || ',', to_char(',' || AUTH.ACS_DIVISION_ACCOUNT_ID || ',') ) > 0)
                                           )
                           union all
                           select null
                             from dual
                          ) as ID_TABLE_TYPE
                 )
        into result
        from dual;
    else
      select cast(multiset(select ACC.ACS_ACCOUNT_ID
                             from ACS_ACCOUNT ACC
                                , ACS_DIVISION_ACCOUNT DIV
                            where DIV.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                              and (    (lstdivisions is null)
                                   or (instr(',' || lstdivisions || ',', to_char(',' || ACC.ACS_ACCOUNT_ID || ',') ) > 0) )
                           union all
                           select null
                             from dual
                          ) as ID_TABLE_TYPE
                 )
        into result
        from dual;
    end if;

    return result;
  end TableAuthRptDivisions;

  /**
  * Description
  *    Retourne la quantité déjà utilisé pour la répartition des approvissionnements
  */
  function getQtyAlreadyUse(iFalNetworkSupplyId FAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID%type, iLidCode COM_LIST_ID_TEMP.LID_CODE%type)
    return FAL_NETWORK_SUPPLY.FAN_BALANCE_QTY%type
  is
    lnQtyAlreadyUse FAL_NETWORK_SUPPLY.FAN_BALANCE_QTY%type;
  begin
    select nvl(sum(LID_FREE_NUMBER_1), 0)
      into lnQtyAlreadyUse
      from COM_LIST_ID_TEMP
     where LID_CODE = iLidCode
       and LID_ID_2 = iFalNetworkSupplyId;

    return lnQtyAlreadyUse;
  end getQtyAlreadyUse;

   /**
  * Description
  *    Attribuer les approvissionnements aux différents besoins pour la création
  *    d'un lot
  */
  procedure AttributeSupply(iLidCode COM_LIST_ID_TEMP.LID_CODE%type)
  is
    ltComListTmp         FWK_I_TYP_DEFINITION.t_crud_def;
    lnFalNetworkSupplyId FAL_NETWORK_SUPPLY.FAL_NETWORK_SUPPLY_ID%type;
    lnFanDescription     FAL_NETWORK_SUPPLY.FAN_DESCRIPTION%type;
    lnFanBalanceQty      FAL_NETWORK_SUPPLY.FAN_BALANCE_QTY%type;
    lnFanEndPlan         FAL_NETWORK_SUPPLY.FAN_END_PLAN%type;
    lnUseQtySupply       FAL_NETWORK_SUPPLY.FAN_BALANCE_QTY%type;
    lnNeedQtySupply      FAL_NETWORK_SUPPLY.FAN_BALANCE_QTY%type;

    cursor curSupply(iGcoGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    is
      select   FNS.FAL_NETWORK_SUPPLY_ID
             , FNS.FAN_DESCRIPTION
             , FNS.FAN_BALANCE_QTY - getQtyAlreadyUse(FNS.FAL_NETWORK_SUPPLY_ID, iLidCode || '_SUPPLY') FAN_BALANCE_QTY
             , FNS.FAN_END_PLAN
          from FAL_NETWORK_SUPPLY FNS
         where GCO_GOOD_ID = iGcoGoodId
           and FNS.FAN_BEG_PLAN is not null
           and FNS.FAN_BALANCE_QTY > getQtyAlreadyUse(FNS.FAL_NETWORK_SUPPLY_ID, iLidCode || '_SUPPLY')
      order by FAN_END_PLAN
             , FAL_NETWORK_SUPPLY_ID;
  begin
    for ltplBatchMaterialLinkSupply in (select   LID_ID_3 FAL_LOT_MATERIAL_LINK_ID
                                               , LID_ID_2 GCO_GOOD_ID
                                               , LID_FREE_NUMBER_4   -- MISS_COMPONENT
                                            from COM_LIST_ID_TEMP
                                           where LID_CODE = iLidCode
                                             and LID_FREE_NUMBER_4 > 0
                                        order by COM_LIST_ID_TEMP_ID) loop
      lnNeedQtySupply  := ltplBatchMaterialLinkSupply.LID_FREE_NUMBER_4;
      lnUseQtySupply   := 0;

      open curSupply(ltplBatchMaterialLinkSupply.GCO_GOOD_ID);

      loop
        fetch curSupply
         into lnFalNetworkSupplyId
            , lnFanDescription
            , lnFanBalanceQty
            , lnFanEndPlan;

        exit when curSupply%notfound
              or lnNeedQtySupply <= 0;

        if lnNeedQtySupply <= lnFanBalanceQty then
          lnUseQtySupply   := lnNeedQtySupply;
          lnNeedQtySupply  := 0;
        else
          lnUseQtySupply   := lnFanBalanceQty;
          lnNeedQtySupply  := lnNeedQtySupply - lnFanBalanceQty;
        end if;

        -- Ajouter dans la COM_LIST_ID_TEMP la répartition des approvisionnements
        FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'COM_LIST_ID_TEMP_ID', INIT_ID_SEQ.nextval);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_CODE', iLidCode || '_SUPPLY');
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_1', ltplBatchMaterialLinkSupply.FAL_LOT_MATERIAL_LINK_ID);
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_2', lnFalNetworkSupplyId);
        -- Nom l'approvisionnement
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_CHAR_1', lnFanDescription);
        -- Qté de l'approvisionnement utilisé
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_NUMBER_1', lnUseQtySupply);
        -- Date de l'approvisionnement
        FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_DATE_1', lnFanEndPlan);
        FWK_I_MGT_ENTITY.InsertEntity(ltComListTmp);
        FWK_I_MGT_ENTITY.Release(ltComListTmp);
      end loop;

      close curSupply;
    end loop;
  end AttributeSupply;

   /**
  * Description
  *    Retourne la quantité stock atelier (lot), somme des mouvements
  */
  function getWorkshopStock(iGcoGoodId in GCO_GOOD.GCO_GOOD_ID%type, iFalLotId in FAL_LOT.FAL_LOT_ID%type)
    return number
  is
    iQtyIn  number;
    iQtyOut number;
  begin
    select sum(FFI.IN_IN_QTE)
      into iQtyIn
      from FAL_FACTORY_IN FFI
     where FFI.GCO_GOOD_ID(+) = iGcoGoodId
       and FFI.FAL_LOT_ID(+) = iFalLotId;

    select sum(FFO.OUT_QTE)
      into iQtyOut
      from FAL_FACTORY_OUT FFO
     where FFO.GCO_GOOD_ID(+) = iGcoGoodId
       and FFO.FAL_LOT_ID(+) = iFalLotId;

    iQtyIn   := nvl(iQtyIn, 0);
    iQtyOut  := nvl(iQtyOut, 0);
    return iQtyIn - iQtyOut;
  end getWorkshopStock;

   /**
  * Description
  *    Retourne la quantité stock disponible entreprise
  */
  function getSumStockQty(iGoodId in GCO_GOOD.GCO_GOOD_ID%type)
    return number
  is
    iStockQty number;
  begin
    -- Récupération du stock disponible entreprise
    select nvl( (sum(SPO_AVAILABLE_QUANTITY) + sum(SPO_PROVISORY_INPUT) ), 0)
      into iStockQty
      from STM_STOCK_POSITION SPO
         , STM_STOCK STM
     where SPO.GCO_GOOD_ID = iGoodId
       and SPO.STM_STOCK_ID = STM.STM_STOCK_ID
       and STM.C_ACCESS_METHOD = 'PUBLIC';

    return iStockQty;
  end getSumStockQty;

   /**
  * Description
  *    Calculer les informations nécessaires pour chaque lien composant et lot
  */
  procedure BatchesCalculateStock(iJobId COM_LIST.LIS_JOB_ID%type)
  is
    lnWorshopStock   number;
    lnAvailableStock number;
    lnMissComponent  number;
    ltComListTmp     FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Supprimer les données existantes dans la COM_LIST_ID_TEMP
    COM_PRC_LIST_ID_TEMP.DeleteIDList(aCode => 'BATCH_MATERIAL_LINK');
    COM_PRC_LIST_ID_TEMP.DeleteIDList(aCode => 'BATCH_MATERIAL_LINK_SUPPLY');

    for ltplBatchMaterialLink in (select   LOT.FAL_LOT_ID
                                         , LOT.LOT_PLAN_BEGIN_DTE
                                         , GOO.GCO_GOOD_ID
                                         , LOM.FAL_LOT_MATERIAL_LINK_ID
                                         , LOM.LOM_NEED_QTY
                                      from COM_LIST LIS
                                         , FAL_LOT LOT
                                         , FAL_LOT_MATERIAL_LINK LOM
                                         , GCO_GOOD GOO
                                     where LIS.LIS_ID_1 = LOT.FAL_LOT_ID
                                       and LIS.LIS_CODE = 'BATCHES_COMPONENTS'
                                       and LIS.LIS_JOB_ID = iJobId
                                       and LOT.FAL_LOT_ID = LOM.FAL_LOT_ID
                                       and LOM.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                                  order by LOT.LOT_PLAN_BEGIN_DTE
                                         , GOO.GOO_MAJOR_REFERENCE) loop
      -- Ajouter dans la COM_LIST_ID_TEMP les informations des besoins du lot
      FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'COM_LIST_ID_TEMP_ID', INIT_ID_SEQ.nextval);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_CODE', 'BATCH_MATERIAL_LINK');
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_1', ltplBatchMaterialLink.FAL_LOT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_2', ltplBatchMaterialLink.GCO_GOOD_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_3', ltplBatchMaterialLink.FAL_LOT_MATERIAL_LINK_ID);
      -- Qté solde besoin lot
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_NUMBER_1', ltplBatchMaterialLink.LOM_NEED_QTY);
      -- Qté Stock atelier
      lnWorshopStock   := getWorkshopStock(ltplBatchMaterialLink.GCO_GOOD_ID, ltplBatchMaterialLink.FAL_LOT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_NUMBER_2', lnWorshopStock);

      -- Qté Stock disponible
      select getSumStockQty(ltplBatchMaterialLink.GCO_GOOD_ID) - nvl(sum(LID_FREE_NUMBER_1), 0) SUM_LOM_NEED_QTY
        into lnAvailableStock
        from COM_LIST_ID_TEMP
       where LID_CODE = 'BATCH_MATERIAL_LINK'
         and LID_ID_2 = ltplBatchMaterialLink.GCO_GOOD_ID;

      if lnAvailableStock < 0 then
        lnAvailableStock  := 0;
      end if;

      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_NUMBER_3', lnAvailableStock);
      -- Composant manquant
      lnMissComponent  := ltplBatchMaterialLink.LOM_NEED_QTY - lnAvailableStock - lnWorshopStock;

      if lnMissComponent < 0 then
        lnMissComponent  := 0;
      end if;

      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_NUMBER_4', lnMissComponent);
      FWK_I_MGT_ENTITY.InsertEntity(ltComListTmp);
      FWK_I_MGT_ENTITY.Release(ltComListTmp);
    end loop;

    -- Attribuer les approvisionnements à chaque lot en fontion des composants manquants
    AttributeSupply('BATCH_MATERIAL_LINK');
  end BatchesCalculateStock;

     /**
  * Description
  *    Calculer les informations nécessaires pour chaque lien composant et lot
  */
  procedure ComponentsCalculateStock(iJobId COM_LIST.LIS_JOB_ID%type)
  is
    lnWorshopStock   number;
    lnAvailableStock number;
    lnMissComponent  number;
    ltComListTmp     FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    -- Supprimer les données existantes dans la COM_LIST_ID_TEMP
    COM_PRC_LIST_ID_TEMP.DeleteIDList(aCode => 'COMPONENT_MATERIAL_LINK');
    COM_PRC_LIST_ID_TEMP.DeleteIDList(aCode => 'COMPONENT_MATERIAL_LINK_SUPPLY');

    for ltplBatchMaterialLink in (select   GOO.GCO_GOOD_ID
                                         , LOT.FAL_LOT_ID
                                         , LOT.LOT_PLAN_BEGIN_DTE
                                         , LOM.FAL_LOT_MATERIAL_LINK_ID
                                         , LOM.LOM_NEED_QTY
                                      from COM_LIST LIS
                                         , FAL_LOT LOT
                                         , FAL_LOT_MATERIAL_LINK LOM
                                         , GCO_GOOD GOO
                                     where LIS.LIS_ID_1 = LOM.FAL_LOT_MATERIAL_LINK_ID
                                       and LIS.LIS_CODE = 'COMPONENTS_BATCHES'
                                       and LIS.LIS_JOB_ID = iJobId
                                       and LOT.FAL_LOT_ID = LOM.FAL_LOT_ID
                                       and LOM.GCO_GOOD_ID = GOO.GCO_GOOD_ID
                                  order by GOO.GOO_MAJOR_REFERENCE
                                         , LOT.LOT_PLAN_BEGIN_DTE) loop
      -- Ajouter dans la COM_LIST_ID_TEMP les informations des besoins du lot
      FWK_I_MGT_ENTITY.new(FWK_TYP_COM_ENTITY.gcComListIdTemp, ltComListTmp);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'COM_LIST_ID_TEMP_ID', INIT_ID_SEQ.nextval);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_CODE', 'COMPONENT_MATERIAL_LINK');
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_1', ltplBatchMaterialLink.FAL_LOT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_2', ltplBatchMaterialLink.GCO_GOOD_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_ID_3', ltplBatchMaterialLink.FAL_LOT_MATERIAL_LINK_ID);
      -- Qté solde besoin lot
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_NUMBER_1', ltplBatchMaterialLink.LOM_NEED_QTY);
      -- Qté Stock atelier
      lnWorshopStock   := getWorkshopStock(ltplBatchMaterialLink.GCO_GOOD_ID, ltplBatchMaterialLink.FAL_LOT_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_NUMBER_2', lnWorshopStock);

      -- Qté Stock disponible
      select getSumStockQty(ltplBatchMaterialLink.GCO_GOOD_ID) - nvl(sum(LID_FREE_NUMBER_1), 0) SUM_LOM_NEED_QTY
        into lnAvailableStock
        from COM_LIST_ID_TEMP
       where LID_CODE = 'COMPONENT_MATERIAL_LINK'
         and LID_ID_2 = ltplBatchMaterialLink.GCO_GOOD_ID;

      if lnAvailableStock < 0 then
        lnAvailableStock  := 0;
      end if;

      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_NUMBER_3', lnAvailableStock);
      -- Composant manquant
      lnMissComponent  := ltplBatchMaterialLink.LOM_NEED_QTY - lnAvailableStock - lnWorshopStock;

      if lnMissComponent < 0 then
        lnMissComponent  := 0;
      end if;

      FWK_I_MGT_ENTITY_DATA.SetColumn(ltComListTmp, 'LID_FREE_NUMBER_4', lnMissComponent);
      FWK_I_MGT_ENTITY.InsertEntity(ltComListTmp);
      FWK_I_MGT_ENTITY.Release(ltComListTmp);
    end loop;

    -- Attribuer les approvisionnements à chaque lot en fontion des composants manquants
    AttributeSupply('COMPONENT_MATERIAL_LINK');
  end ComponentsCalculateStock;

   /**
  * Description
  *    Retourne la date founie en paramètre au format YYYYMMDD en type date
  */
  function StringToDate(aDateString in varchar2)
    return date
  is
    vDate date;
  begin
    vDate  := to_date(aDateString, 'YYYYMMDD');
    return vDate;
  end StringToDate;

   /**
  * function DateToString
  *    Retourne la date founie en paramètre en type varchar2 au format YYYYMMDD
  */
  function DateToString(aDate in date)
    return varchar2
  is
    vDate varchar2(10);
  begin
    vDate  := to_char(aDate, 'YYYYMMDD');
    return vDate;
  end;

  /**
  * procedure InsertList
  * Description
  * Insère une liste d'Id dans la table COM_LIST_ID_TEMP
  */
  procedure InsertList(
    aJobId     in out COM_LIST.LIS_JOB_ID%type
  , aSessionID in out COM_LIST.LIS_SESSION_ID%type
  , aListID    in     varchar2
  , aCode      in     COM_LIST_ID_TEMP.LID_CODE%type
  , aDescr     in     COM_LIST_ID_TEMP.LID_DESCRIPTION%type default null
  )
  is
  begin
    select INIT_TEMP_ID_SEQ.nextval
      into aJobId
      from dual;

    for ltplId in (select *
                     from table(IdListToTable(aListID) ) ) loop
      insert into COM_LIST_ID_TEMP
                  (COM_LIST_ID_TEMP_ID
                 , LID_ID_1
                 , LID_CODE
                 , LID_DESCRIPTION
                  )
           values (aJobId
                 , ltplId.column_value
                 , aCode
                 , aDescr
                  );

      aJobId  := INIT_TEMP_ID_SEQ.nextval;
    end loop;
  end;

  /**
  * procedure InsertFinImputationToPrint
  * Description
  *     Insère les id des imputations financière dans la table COM_LIST pour l'impression des rapports FIN
  */
  procedure InsertFinImputationToPrint(
    aJobId       in out COM_LIST.LIS_JOB_ID%type
  , aSessionID   in out COM_LIST.LIS_SESSION_ID%type
  , aNoExercice  in     ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type
  , aAccountFrom in     ACS_ACCOUNT.ACC_NUMBER%type default null
  , aAccountTo   in     ACS_ACCOUNT.ACC_NUMBER%type default null
  , aExistDIVI   in     varchar2
  )
  is
  begin
    -- Suppression des anciennes valeurs
    COM_PRC_LIST.DeleteIDList(aJobId, aSessionID, 'ACT_FINANCIAL_IMPUTATION_ID');

    if (aExistDIVI = '0') then
      -- insertion des id des imputations financières pour impression
      for ltplPrint in (select distinct IMP.ACT_FINANCIAL_IMPUTATION_ID
                                   from ACS_ACCOUNT ACC
                                      , ACS_FINANCIAL_ACCOUNT FIN
                                      , ACT_FINANCIAL_IMPUTATION IMP
                                      , ACS_PERIOD PER
                                      , ACS_FINANCIAL_YEAR FYE
                                  where FIN.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                                    and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                                    and PER.ACS_PERIOD_ID = IMP.ACS_PERIOD_ID
                                    and FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
                                    and FYE.FYE_NO_EXERCICE = aNoExercice
                                    and ACC.ACC_NUMBER >= aAccountFrom
                                    and ACC.ACC_NUMBER <= aAccountTo
                               order by IMP.ACT_FINANCIAL_IMPUTATION_ID asc) loop
        COM_PRC_LIST.InsertIDList(ltplPrint.ACT_FINANCIAL_IMPUTATION_ID
                                , 'ACT_FINANCIAL_IMPUTATION_ID'
                                , 'Impression des imputations financières'
                                , aJobId
                                , aSessionID
                                 );
      end loop;
    else
      -- insertion des id des imputations financières pour impression avec filtre sur divisions autorisées
      for ltplPrint in (select distinct IMP.ACT_FINANCIAL_IMPUTATION_ID
                                   from COM_LIST LIS
                                      , ACS_ACCOUNT ACC
                                      , ACS_FINANCIAL_ACCOUNT FIN
                                      , ACT_FINANCIAL_IMPUTATION IMP
                                      , ACS_PERIOD PER
                                      , ACS_FINANCIAL_YEAR FYE
                                  where LIS.LIS_JOB_ID = aJobId
                                    and LIS.LIS_CODE = 'ACS_DIVISION_ACCOUNT_ID'
                                    and IMP.IMF_ACS_DIVISION_ACCOUNT_ID = LIS.LIS_ID_1
                                    and FIN.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                                    and IMP.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                                    and PER.ACS_PERIOD_ID = IMP.ACS_PERIOD_ID
                                    and FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
                                    and FYE.FYE_NO_EXERCICE = aNoExercice
                                    and ACC.ACC_NUMBER >= aAccountFrom
                                    and ACC.ACC_NUMBER <= aAccountTo
                               order by IMP.ACT_FINANCIAL_IMPUTATION_ID asc) loop
        COM_PRC_LIST.InsertIDList(ltplPrint.ACT_FINANCIAL_IMPUTATION_ID
                                , 'ACT_FINANCIAL_IMPUTATION_ID'
                                , 'Impression des imputations financières'
                                , aJobId
                                , aSessionID
                                 );
      end loop;
    end if;

    aJobId      := aJobId;
    aSessionID  := aSessionID;
  end InsertFinImputationToPrint;

  /**
  * procedure InsertTotalByPeriodToPrint
  * Description
  *     Insère les id des cumuls périodiques dans  la table COM_LIST pour l'impression des rapports FIN
  */
  procedure InsertTotalByPeriodToPrint(
    aJobId       in out COM_LIST.LIS_JOB_ID%type
  , aSessionID   in out COM_LIST.LIS_SESSION_ID%type
  , aNoExercice  in     ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type
  , aAccountFrom in     ACS_ACCOUNT.ACC_NUMBER%type default null
  , aAccountTo   in     ACS_ACCOUNT.ACC_NUMBER%type default null
  , aExistDIVI   in     varchar2
  )
  is
  begin
    -- Suppression des anciennes valeurs
    COM_PRC_LIST.DeleteIDList(aJobId, aSessionID, 'ACT_TOTAL_BY_PERIOD_ID');

    if (aExistDIVI = '0') then
      -- insertion des id des imputations financières pour impression
      for ltplPrint in (select distinct TOT.ACT_TOTAL_BY_PERIOD_ID
                                   from ACS_ACCOUNT ACC
                                      , ACS_FINANCIAL_ACCOUNT FIN
                                      , ACT_TOTAL_BY_PERIOD TOT
                                      , ACS_PERIOD PER
                                      , ACS_FINANCIAL_YEAR FYE
                                  where FIN.ACS_FINANCIAL_ACCOUNT_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID
                                    and ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                                    and PER.ACS_PERIOD_ID = TOT.ACS_PERIOD_ID
                                    and FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
                                    and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
                                    and FYE.FYE_NO_EXERCICE = aNoExercice
                                    and ACC.ACC_NUMBER >= aAccountFrom
                                    and ACC.ACC_NUMBER <= aAccountTo
                               order by TOT.ACT_TOTAL_BY_PERIOD_ID asc) loop
        COM_PRC_LIST.InsertIDList(ltplPrint.ACT_TOTAL_BY_PERIOD_ID, 'ACT_TOTAL_BY_PERIOD_ID', 'Impression des cumuls périodiques', aJobId, aSessionID);
      end loop;
    else
      -- insertion des id des imputations financières pour impression avec filtre sur divisions autorisées
      for ltplPrint in (select distinct TOT.ACT_TOTAL_BY_PERIOD_ID
                                   from COM_LIST LIS
                                      , ACS_ACCOUNT ACC
                                      , ACS_FINANCIAL_ACCOUNT FIN
                                      , ACT_TOTAL_BY_PERIOD TOT
                                      , ACS_PERIOD PER
                                      , ACS_FINANCIAL_YEAR FYE
                                  where LIS.LIS_JOB_ID = aJobId
                                    and LIS.LIS_CODE = 'ACS_DIVISION_ACCOUNT_ID'
                                    and TOT.ACS_DIVISION_ACCOUNT_ID = LIS.LIS_ID_1
                                    and FIN.ACS_FINANCIAL_ACCOUNT_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID
                                    and ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                                    and PER.ACS_PERIOD_ID = TOT.ACS_PERIOD_ID
                                    and FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID
                                    and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
                                    and FYE.FYE_NO_EXERCICE = aNoExercice
                                    and ACC.ACC_NUMBER >= aAccountFrom
                                    and ACC.ACC_NUMBER <= aAccountTo
                               order by TOT.ACT_TOTAL_BY_PERIOD_ID asc) loop
        COM_PRC_LIST.InsertIDList(ltplPrint.ACT_TOTAL_BY_PERIOD_ID, 'ACT_TOTAL_BY_PERIOD_ID', 'Impression des cumuls périodiques', aJobId, aSessionID);
      end loop;
    end if;

    aJobId      := aJobId;
    aSessionID  := aSessionID;
  end InsertTotalByPeriodToPrint;

  /**
  * procedure InsertGlobalBudgetToPrint
  * Description
  *     Insère les id des budgets globaux dans  la table COM_LIST pour l'impression des rapports FIN
  */
  procedure InsertGlobalBudgetToPrint(
    aJobId       in out COM_LIST.LIS_JOB_ID%type
  , aSessionID   in out COM_LIST.LIS_SESSION_ID%type
  , aNoExercice  in     ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type
  , aAccountFrom in     ACS_ACCOUNT.ACC_NUMBER%type default null
  , aAccountTo   in     ACS_ACCOUNT.ACC_NUMBER%type default null
  , aExistDIVI   in     varchar2
  )
  is
  begin
    -- Suppression des anciennes valeurs
    COM_PRC_LIST.DeleteIDList(aJobId, aSessionID, 'ACB_GLOBAL_BUDGET_ID');

    if (aExistDIVI = '0') then
      -- insertion des id des imputations financières pour impression
      for ltplPrint in (select distinct GLO.ACB_GLOBAL_BUDGET_ID
                                   from ACS_ACCOUNT ACC
                                      , ACS_FINANCIAL_ACCOUNT FIN
                                      , ACB_GLOBAL_BUDGET GLO
                                      , ACB_BUDGET_VERSION VER
                                      , ACS_FINANCIAL_YEAR FYE
                                  where FIN.ACS_FINANCIAL_ACCOUNT_ID = GLO.ACS_FINANCIAL_ACCOUNT_ID
                                    and ACC.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                                    and VER.ACB_BUDGET_VERSION_ID = GLO.ACB_BUDGET_VERSION_ID
                                    and VER.VER_DEFAULT = 1
                                    and FYE.FYE_NO_EXERCICE = aNoExercice
                                    and ACC.ACC_NUMBER >= aAccountFrom
                                    and ACC.ACC_NUMBER <= aAccountTo
                               order by GLO.ACB_GLOBAL_BUDGET_ID asc) loop
        COM_PRC_LIST.InsertIDList(ltplPrint.ACB_GLOBAL_BUDGET_ID, 'ACB_GLOBAL_BUDGET_ID', 'Impression des budgets globaux', aJobId, aSessionID);
      end loop;
    else
      -- insertion des id des imputations financières pour impression avec filtre sur divisions autorisées
      for ltplPrint in (select distinct GLO.ACB_GLOBAL_BUDGET_ID
                                   from COM_LIST LIS
                                      , ACS_ACCOUNT ACC
                                      , ACS_FINANCIAL_ACCOUNT FIN
                                      , ACB_GLOBAL_BUDGET GLO
                                      , ACB_BUDGET_VERSION VER
                                      , ACS_FINANCIAL_YEAR FYE
                                  where LIS.LIS_JOB_ID = aJobId
                                    and LIS.LIS_CODE = 'ACS_DIVISION_ACCOUNT_ID'
                                    and GLO.ACS_DIVISION_ACCOUNT_ID = LIS.LIS_ID_1
                                    and FIN.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                                    and GLO.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
                                    and VER.ACB_BUDGET_VERSION_ID = GLO.ACB_BUDGET_VERSION_ID
                                    and VER.VER_DEFAULT = 1
                                    and FYE.FYE_NO_EXERCICE = aNoExercice
                                    and ACC.ACC_NUMBER >= aAccountFrom
                                    and ACC.ACC_NUMBER <= aAccountTo
                               order by GLO.ACB_GLOBAL_BUDGET_ID asc) loop
        COM_PRC_LIST.InsertIDList(ltplPrint.ACB_GLOBAL_BUDGET_ID, 'ACB_GLOBAL_BUDGET_ID', 'Impression des budgets globaux', aJobId, aSessionID);
      end loop;
    end if;

    aJobId      := aJobId;
    aSessionID  := aSessionID;
  end InsertGlobalBudgetToPrint;

  /**
  * procedure InsertFinancialAccountToPrint
  * Description
  *     Insère les id des comptes financiers dans  la table COM_LIST pour l'impression des rapports FIN
  */
  procedure InsertFinancialAccountToPrint(
    aJobId       in out COM_LIST.LIS_JOB_ID%type
  , aSessionID   in out COM_LIST.LIS_SESSION_ID%type
  , aNoExercice  in     ACS_FINANCIAL_YEAR.FYE_NO_EXERCICE%type
  , aAccountFrom in     ACS_ACCOUNT.ACC_NUMBER%type default null
  , aAccountTo   in     ACS_ACCOUNT.ACC_NUMBER%type default null
  , aExistDIVI   in     varchar2
  )
  is
  begin
--     Suppression des anciennes valeurs
    COM_PRC_LIST.DeleteIDList(aJobId, aSessionID, 'ACS_FINANCIAL_ACCOUNT_ID');

--       insertion des id des imputations financières pour impression
    for ltplPrint in (select distinct FIN.ACS_FINANCIAL_ACCOUNT_ID
                                 from ACS_ACCOUNT ACC
                                    , ACS_FINANCIAL_ACCOUNT FIN
                                where FIN.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID
                                  and ACC.ACC_NUMBER >= aAccountFrom
                                  and ACC.ACC_NUMBER <= aAccountTo
                             order by FIN.ACS_FINANCIAL_ACCOUNT_ID asc) loop
      COM_PRC_LIST.InsertIDList(ltplPrint.ACS_FINANCIAL_ACCOUNT_ID, 'ACS_FINANCIAL_ACCOUNT_ID', 'Impression des comptes financiers', aJobId, aSessionID);
    end loop;

    aJobId      := aJobId;
    aSessionID  := aSessionID;
  end InsertFinancialAccountToPrint;

  /**
  * Description
  *   Retourne le compte financier utilisé pour ce compte
  *   ATTENTION : Rapport ACR_ACC_IMPUTATION -> Une seule devise étrangère pris en compte
  */
  function getFinancialCurrencyId(iFinancialAccount in ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type)
    return ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type
  is
    lFinCurr ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID%type;
  begin
    select max(FCU.ACS_FINANCIAL_CURRENCY_ID) ACS_FINANCIAL_CURRENCY_ID
      into lFinCurr
      from ACS_FIN_ACCOUNT_S_FIN_CURR AFE
         , ACS_FINANCIAL_CURRENCY FCU
     where AFE.ACS_FINANCIAL_CURRENCY_ID = FCU.ACS_FINANCIAL_CURRENCY_ID
       and AFE.ACS_FINANCIAL_ACCOUNT_ID = iFinancialAccount
       and FCU.FIN_LOCAL_CURRENCY = 0;

    return lFinCurr;
  end getFinancialCurrencyId;

  /**
  * Description
  *   Retourne la monnaie étrangère utilisé pour ce compte
  *   ATTENTION : Rapport ACR_ACC_IMPUTATION -> Une seule devise étrangère pris en compte
  */
  function getCurrencyId(iFinancialAccount in ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID%type)
    return PCS.PC_CURR.CURRENCY%type
  is
    lCurr PCS.PC_CURR.CURRENCY%type;
  begin
    begin
      select CURRENCY
        into lCurr
        from ACS_FINANCIAL_CURRENCY FCE
           , PCS.PC_CURR CUE
       where FCE.PC_CURR_ID = CUE.PC_CURR_ID
         and FCE.ACS_FINANCIAL_CURRENCY_ID = getFinancialCurrencyId(iFinancialAccount);

      return lCurr;
    exception
      when no_data_found then
        return '';
    end;
  end getCurrencyId;
end rpt_functions;
