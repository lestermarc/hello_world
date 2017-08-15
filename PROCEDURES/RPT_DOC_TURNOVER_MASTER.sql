--------------------------------------------------------
--  DDL for Procedure RPT_DOC_TURNOVER_MASTER
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_TURNOVER_MASTER" (
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
, parameter_21         in     varchar2
, procuser_lanid       in     pcs.pc_lang.lanid%type
, report_name          in     varchar2
, calling_pc_object_id in     pcs.pc_object.pc_object_id%type
, company_owner        in     pcs.pc_scrip.scrdbowner%type
)
is
  /**
  * procedure rpt_doc_turnover_master
  * Description
  *    Utilisation pour le rapport DOC_CUST_TURNOVER_CUST_BATCH, DOC_SUPPL_TURNOVER_SUPPL_BATCH
                                             DOC_CUST_TURNOVER_CUST_BATCH, DOC_SUPPL_TURNOVER_SUPPL_BATCH
  * @created mzh 01.07.2007
  * @lastUpdate VHA 4 February 2013
  * @public
  * @param parameter_0    : FROM(PER_KEY1 or GOO_MAJOR_REFERENCE)
  * @param parameter_1    : TO(PER_KEY1 or GOO_MAJOR_REFERENCE)
  * @param parameter_1    : used in Crystal report - use activity/line (yes or no)
  * @param parameter_3    : used in Crystal report - use region/family (yes or no)
  * @param parameter_4    : used in Crystal report - use partner type/group (yes or no)
  * @param parameter_5    : used in Crystal report - use sales person/model (yes or no)
  * @param parameter_6    : show detail (yes, no or subtotal only)
  * @param parameter_7    : date from
  * @param parameter_8    : date to
  * @param parameter_9    : gauge title (C_GAUGE_TITLE)
  * @param parameter_21   : Prise en compte matière précieuse
  * @param procuser_lanid : ID langue utilisateur
  * @param report_name    : Nom du rapport
  * @param calling_pc_object_id : crystal calling object id
  * @param company_owner : crystal company owner
  */
  vpc_lang_id             pcs.pc_lang.pc_lang_id%type;
  report_names            varchar2(100);
  report_names_1          varchar2(100);
  report_names_2          varchar2(100);
  param_c_gauge_title     varchar2(30);
  param_pos_status        varchar2(30);
  param_dmt_date_start    date;
  param_dmt_date_end      date;
  vpc_pas_ligne           dico_description.dit_descr%type;
  vpc_pas_famille         dico_description.dit_descr%type;
  vpc_pas_modele          dico_description.dit_descr%type;
  vpc_pas_groupe          dico_description.dit_descr%type;
  vpc_pas_activite        dico_description.dit_descr%type;
  vpc_pas_region          dico_description.dit_descr%type;
  vpc_pas_type_partenaire dico_description.dit_descr%type;
  vpc_pas_representant    dico_description.dit_descr%type;
begin
--Initialize the name of the report
  report_names             := substr(substr(report_name, instr(report_name, '\', -1) + 1), 1, length(substr(report_name, instr(report_name, '\', -1) + 1) ) - 4);
  report_names             := RPT_FUNCTIONS.GetStdReportName(report_names, CALLING_PC_OBJECT_ID);
  report_names_1           := substr(report_names, instr(report_names, '_') + 1, instr(report_names, '_', 1, 2) - instr(report_names, '_') - 1);
  report_names_2           := substr(report_names, instr(report_names, '_', -1, 2) + 1, instr(report_names, '_', -1) - instr(report_names, '_', -1, 2) - 1);

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
  vpc_lang_id              := pcs.PC_I_LIB_SESSION.GetUserLangId;
  vpc_pas_ligne            := pcs.PC_FUNCTIONS.TranslateWord2('Pas de ligne produit', vpc_lang_id);
  vpc_pas_famille          := pcs.PC_FUNCTIONS.TranslateWord2('Pas de famille produit', vpc_lang_id);
  vpc_pas_modele           := pcs.PC_FUNCTIONS.TranslateWord2('Pas de modèle produit', vpc_lang_id);
  vpc_pas_groupe           := pcs.PC_FUNCTIONS.TranslateWord2('Pas de groupe produit', vpc_lang_id);
  vpc_pas_activite         := pcs.PC_FUNCTIONS.TranslateWord2('Pas activité', vpc_lang_id);
  vpc_pas_region           := pcs.PC_FUNCTIONS.TranslateWord2('Pas de région', vpc_lang_id);
  vpc_pas_type_partenaire  := pcs.PC_FUNCTIONS.TranslateWord2('Pas de type de partenaire', vpc_lang_id);

  open arefcursor for
    select to_char(sysdate, 'YYYYIW') year_week
         , to_char(sysdate, 'YYYYMM') year_month
         , dmt.DMT_NUMBER
         , dmt.DMT_DATE_DOCUMENT
         , dmt.DMT_RATE_EURO
         , dmt.DMT_BASE_PRICE
         , dmt.DMT_RATE_OF_EXCHANGE
         , gas.C_GAUGE_TITLE
         , gas.GAS_FINANCIAL_CHARGE
         , pos.C_DOC_POS_STATUS
         , pos.GCO_GOOD_ID
         , pos.POS_NUMBER
         , GCO_FUNCTIONS.GetDescription2(goo.GCO_GOOD_ID, vpc_lang_id, 1, '01') DES_SHORT_DESCRIPTION
         , GCO_FUNCTIONS.GetDescription2(goo.GCO_GOOD_ID, vpc_lang_id, 2, '01') DES_LONG_DESCRIPTION
         , case parameter_21
             when '1' then case DOC_I_LIB_DISCOUNT_CHARGE.existFootPMDiscount(iDocumentID => pos.DOC_DOCUMENT_ID)
                            when 1 then pos.POS_NET_UNIT_VALUE
                            else DOC_I_LIB_DISCOUNT_CHARGE.getUnitPosValueWithoutPMCharge(iPositionID => pos.DOC_POSITION_ID, iCurrencyType => '')
                          end
             else DOC_I_LIB_DISCOUNT_CHARGE.getUnitPosValueWithoutPMCharge(iPositionID => pos.DOC_POSITION_ID, iCurrencyType => '')
           end POS_NET_UNIT_VALUE
         , case parameter_21
             when '1' then case DOC_I_LIB_DISCOUNT_CHARGE.existFootPMDiscount(iDocumentID => pos.DOC_DOCUMENT_ID)
                            when 1 then pos.POS_NET_VALUE_EXCL
                            else DOC_I_LIB_DISCOUNT_CHARGE.getPosValueWithoutPMCharge(iPositionID => pos.DOC_POSITION_ID, iCurrencyType => '')
                          end
             else DOC_I_LIB_DISCOUNT_CHARGE.getPosValueWithoutPMCharge(iPositionID => pos.DOC_POSITION_ID, iCurrencyType => '')
           end POS_NET_VALUE_EXCL
         , pos.POS_FINAL_QUANTITY
         , pos.DIC_UNIT_OF_MEASURE_ID
         , case parameter_21
             when '1' then case DOC_I_LIB_DISCOUNT_CHARGE.existFootPMDiscount(iDocumentID => pos.DOC_DOCUMENT_ID)
                            when 1 then pos.POS_NET_VALUE_EXCL_B
                            else DOC_I_LIB_DISCOUNT_CHARGE.getPosValueWithoutPMCharge(iPositionID => pos.DOC_POSITION_ID, iCurrencyType => 'B')
                          end
             else DOC_I_LIB_DISCOUNT_CHARGE.getPosValueWithoutPMCharge(iPositionID => pos.DOC_POSITION_ID, iCurrencyType => 'B')
           end POS_NET_VALUE_EXCL_B
         , pos.POS_BALANCE_QUANTITY
         , goo.GOO_MAJOR_REFERENCE
         , goo.GOO_SECONDARY_REFERENCE
         , GCO_FUNCTIONS.GetCostPriceWithManagementMode(goo.GCO_GOOD_ID) COST_PRICE
         , goo.GOO_NUMBER_OF_DECIMAL
         , goo.DIC_GOOD_LINE_ID
         , nvl( (select DIT_DESCR
                   from DICO_DESCRIPTION dit
                  where dit.DIT_TABLE = 'DIC_GOOD_LINE'
                    and DIT_CODE = goo.DIC_GOOD_LINE_ID
                    and dit.PC_LANG_ID = vpc_lang_id), vpc_pas_ligne) DIC_GOOD_LINE_DESCR
         ,
           --1 differentiate  lines which are null or not in crystal
           goo.DIC_GOOD_FAMILY_ID
         , nvl( (select DIT_DESCR
                   from DICO_DESCRIPTION dit
                  where dit.DIT_TABLE = 'DIC_GOOD_FAMILY'
                    and DIT_CODE = goo.DIC_GOOD_FAMILY_ID
                    and dit.PC_LANG_ID = vpc_lang_id), vpc_pas_famille) DIC_GOOD_FAMILY_DESCR
         ,
           --1 differentiate between families which are null or not in crystal
           goo.DIC_GOOD_MODEL_ID
         , nvl( (select DIT_DESCR
                   from DICO_DESCRIPTION dit
                  where dit.DIT_TABLE = 'DIC_GOOD_MODEL'
                    and DIT_CODE = goo.DIC_GOOD_MODEL_ID
                    and dit.PC_LANG_ID = vpc_lang_id), vpc_pas_modele) DIC_GOOD_MODEL_DESCR
         ,
           --1 differentiate between models which are null or not in crystal
           goo.DIC_GOOD_GROUP_ID
         , nvl( (select DIT_DESCR
                   from DICO_DESCRIPTION dit
                  where dit.DIT_TABLE = 'DIC_GOOD_GROUP'
                    and DIT_CODE = goo.DIC_GOOD_GROUP_ID
                    and dit.PC_LANG_ID = vpc_lang_id), vpc_pas_groupe) DIC_GOOD_GROUP_DESCR
         ,
           --used to differentiate between groups which are null or not in crystal
           pde.PDE_FINAL_DELAY
         , to_char(pde.PDE_FINAL_DELAY, 'YYYYIW') pde_year_week
         , to_char(pde.PDE_FINAL_DELAY, 'YYYYMM') pde_year_month
         , pde.PDE_FINAL_QUANTITY
         , pde.PDE_BALANCE_QUANTITY
         , pde.PDE_CHARACTERIZATION_VALUE_1
         , pde.PDE_CHARACTERIZATION_VALUE_2
         , pde.PDE_CHARACTERIZATION_VALUE_3
         , pde.PDE_CHARACTERIZATION_VALUE_4
         , pde.PDE_CHARACTERIZATION_VALUE_5
         , decode(report_names, 'DOC_SUPPL_ORDER_PORT_SUPPL_BATCH', fns.FAN_NETW_QTY, 'DOC_SUPPL_ORDER_PORT_SUPPL_BATCH', fns.FAN_NETW_QTY, fnn.FAN_NETW_QTY)
                                                                                                                                                   FAN_NETW_QTY
         , decode(report_names, 'DOC_SUPPL_ORDER_PORT_SUPPL_BATCH', fns.FAN_STK_QTY, 'DOC_SUPPL_ORDER_PORT_SUPPL_BATCH', fns.FAN_STK_QTY, fnn.FAN_STK_QTY)
                                                                                                                                                    FAN_STK_QTY
         , per.PER_NAME
         , (select max(adr.ADD_ADDRESS1 || '  ' || adr.ADD_FORMAT)
              from PAC_ADDRESS adr
                 , DIC_ADDRESS_TYPE dad
             where adr.PAC_PERSON_ID = dmt.PAC_THIRD_ID
               and adr.DIC_ADDRESS_TYPE_ID = dad.DIC_ADDRESS_TYPE_ID
               and dad.DAD_DEFAULT = 1) INV_ADDRESS
         , per.PER_KEY1
         , thi.PAC_THIRD_ID
         , thi.DIC_THIRD_ACTIVITY_ID
         , decode(thi.DIC_THIRD_ACTIVITY_ID, null, vpc_pas_activite, (select thi.DIC_THIRD_ACTIVITY_ID || ' - ' || act.ACT_DESCR
                                                                        from DIC_THIRD_ACTIVITY act
                                                                       where act.DIC_THIRD_ACTIVITY_ID = thi.DIC_THIRD_ACTIVITY_ID) ) ACT_DESCR
         , decode(thi.DIC_THIRD_AREA_ID, null, vpc_pas_region, (select thi.DIC_THIRD_AREA_ID || ' - ' || are.ARE_DESCR
                                                                  from DIC_THIRD_AREA are
                                                                 where are.DIC_THIRD_AREA_ID = thi.DIC_THIRD_AREA_ID) ) ARE_DESCR
         , thi.DIC_THIRD_AREA_ID
         , decode(report_names_1, 'CUST', cus.DIC_TYPE_PARTNER_ID, 'SUPPL', sup.DIC_TYPE_PARTNER_F_ID) DIC_TYPE_PARTNER_ID
         , decode(report_names_1
                , 'CUST', decode(cus.DIC_TYPE_PARTNER_ID
                               , null, vpc_pas_type_partenaire
                               , (select (select dit.DIT_DESCR
                                            from DICO_DESCRIPTION dit
                                           where dit.DIT_TABLE = 'DIC_TYPE_PARTNER'
                                             and dit.PC_LANG_ID = vpc_lang_id
                                             and dit.DIT_CODE = dtp.DIC_TYPE_PARTNER_ID)
                                    from DIC_TYPE_PARTNER dtp
                                   where dtp.DIC_TYPE_PARTNER_ID = cus.DIC_TYPE_PARTNER_ID)
                                )
                , 'SUPPL', decode(sup.DIC_TYPE_PARTNER_F_ID
                                , null, vpc_pas_type_partenaire
                                , (select (select dit.DIT_DESCR
                                             from DICO_DESCRIPTION dit
                                            where dit.DIT_TABLE = 'DIC_TYPE_PARTNER'
                                              and dit.PC_LANG_ID = vpc_lang_id
                                              and dit.DIT_CODE = dtp.DIC_TYPE_PARTNER_F_ID)
                                     from DIC_TYPE_PARTNER_F dtp
                                    where dtp.DIC_TYPE_PARTNER_F_ID = sup.DIC_TYPE_PARTNER_F_ID)
                                 )
                 ) DIC_DESCR
         , decode(dmt.PAC_REPRESENTATIVE_ID, null, vpc_pas_representant, (select rep.REP_DESCR
                                                                            from PAC_REPRESENTATIVE rep
                                                                           where rep.PAC_REPRESENTATIVE_ID = dmt.PAC_REPRESENTATIVE_ID) ) REP_DESCR
         , (select max(cre.CRE_AMOUNT_LIMIT)
              from PAC_CREDIT_LIMIT cre
                 , ACS_FINANCIAL_CURRENCY acs
             where cre.PAC_SUPPLIER_PARTNER_ID || cre.PAC_CUSTOM_PARTNER_ID = dmt.PAC_THIRD_ID
               and cre.ACS_FINANCIAL_CURRENCY_ID = dmt.ACS_FINANCIAL_CURRENCY_ID) CRE_AMOUNT_LIMIT
         , (select max(curr.CURRENCY)
              from ACS_FINANCIAL_CURRENCY acs
                 , pcs.PC_CURR curr
             where dmt.ACS_FINANCIAL_CURRENCY_ID = acs.ACS_FINANCIAL_CURRENCY_ID
               and acs.PC_CURR_ID = curr.PC_CURR_ID) CURRENCY
         , vgq.SPO_AVAILABLE_QUANTITY
      from ACS_FINANCIAL_CURRENCY fin
         , DOC_DOCUMENT dmt
         , DOC_GAUGE_STRUCTURED gas
         , DOC_POSITION pos
         , DOC_POSITION_DETAIL pde
         , GCO_GOOD goo
         , PAC_PERSON per
         , PAC_THIRD thi
         , pcs.PC_CURR cur
         , PAC_REPRESENTATIVE pac
         , PAC_CUSTOM_PARTNER cus
         , PAC_SUPPLIER_PARTNER sup
         , FAL_NETWORK_NEED fnn
         , FAL_NETWORK_SUPPLY fns
         , V_STM_GCO_GOOD_QTY vgq
     where dmt.ACS_FINANCIAL_CURRENCY_ID = fin.ACS_FINANCIAL_CURRENCY_ID
       and fin.PC_CURR_ID = cur.PC_CURR_ID
       and dmt.DOC_GAUGE_ID = gas.DOC_GAUGE_ID
       and dmt.DOC_DOCUMENT_ID = pos.DOC_DOCUMENT_ID
       and pos.DOC_POSITION_ID = pde.DOC_POSITION_ID
       and pos.GCO_GOOD_ID = goo.GCO_GOOD_ID
       and pos.PAC_REPRESENTATIVE_ID = pac.PAC_REPRESENTATIVE_ID(+)
       and pde.DOC_POSITION_DETAIL_ID = fnn.DOC_POSITION_DETAIL_ID(+)
       and pde.DOC_POSITION_DETAIL_ID = fns.DOC_POSITION_DETAIL_ID(+)
       and goo.GCO_GOOD_ID = vgq.GCO_GOOD_ID(+)
       and dmt.PAC_THIRD_ID = thi.PAC_THIRD_ID
       and thi.PAC_THIRD_ID = per.PAC_PERSON_ID
       and per.PAC_PERSON_ID = cus.PAC_CUSTOM_PARTNER_ID(+)
       and per.PAC_PERSON_ID = sup.PAC_SUPPLIER_PARTNER_ID(+)
       and pos.C_GAUGE_TYPE_POS in('1', '7', '8', '91', '10')
       and RPT_FUNCTIONS.check_cust_suppl(report_names_1, per.PAC_PERSON_ID) = 1
       --According to report name to define customer or supplier
       and RPT_FUNCTIONS.check_record_in_range(report_names_2, goo.GOO_MAJOR_REFERENCE, per.PER_KEY1, parameter_0, parameter_1) = 1
       and pos.C_DOC_POS_STATUS = '04'
       and instr(',' || param_c_gauge_title || ',', ',' || gas.C_GAUGE_TITLE || ',') > 0
       and dmt.DMT_DATE_DOCUMENT between param_dmt_date_start and param_dmt_date_end
       and RPT_FUNCTIONS.suppl_turnover_batch(report_names, parameter_9, gas.C_GAUGE_TITLE, gas.GAS_FINANCIAL_CHARGE) = 1;
end rpt_doc_turnover_master;
