--------------------------------------------------------
--  DDL for Procedure RPT_DOC_CAN_GOOD_SUPPLIER
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_CAN_GOOD_SUPPLIER" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, parameter_0    in     varchar2
, parameter_1    in     varchar2
, parameter_17   in     varchar2
, parameter_18   in     varchar2
, parameter_19   in     varchar2
, parameter_20   in     varchar2
, parameter_21   in     varchar2
, procuser_lanid in     pcs.pc_lang.lanid%type
)
is
  /**
  * procedure rpt_doc_can_good_supplier
  * Description
  *    Utilisation pour le rapport DOC_CAN_GOOD_SUPPLIER
  * @created mzh 18.12.2006
  * @lastUpdate age 20.09.2012
  * @public
  * @param parameter_0  : PAC_PERSON.PER_KEY1(MIN)
  * @param parameter_1  : PAC_PERSON.PER_KEY1(MAX)
  * @param parameter_17 : DOC_DOCUMENT.DMT_DATE_DOCUMENT(MIN)
  * @param parameter_18 : DOC_DOCUMENT.DMT_DATE_DOCUMENT(MAX)
  * @param parameter_19 : DOC_DOCUMENT.DMT_DATE_DOCUMENT(MIN)
  * @param parameter_20 : DOC_DOCUMENT.DMT_DATE_DOCUMENT(MAX)
  * @param parameter_21 : Prise en compte matière précieuse
  */
  vpc_lang_id             pcs.pc_lang.pc_lang_id%type;
  nDocDelayWeekstart      number;
begin
  pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  vpc_lang_id  := pcs.PC_I_LIB_SESSION.GetUserLangId;

  -- Premier jour de la semaine
  nDocDelayWeekstart := to_number(nvl(PCS.PC_CONFIG.GetConfig('DOC_DELAY_WEEKSTART'), '2') );

  open arefcursor for
    select nDocDelayWeekstart DOC_DELAY_WEEKSTART_CONFIG
         , doc.DMT_NUMBER
         , doc.DMT_DATE_DOCUMENT
         , doc.DMT_DATE_VALUE
         , str.C_GAUGE_TITLE
         , str.GAS_FINANCIAL_CHARGE
         , pos.C_GAUGE_TYPE_POS
         , pos.C_DOC_POS_STATUS
         , pos.POS_FINAL_QUANTITY
         , pos.POS_FINAL_QUANTITY_SU
         , pos.DIC_UNIT_OF_MEASURE_ID
         , pos.POS_UNIT_COST_PRICE
         , case parameter_21
             when '1' then case DOC_I_LIB_DISCOUNT_CHARGE.existFootPMDiscount(iDocumentID => pos.DOC_DOCUMENT_ID)
                            when 1 then pos.POS_NET_VALUE_EXCL_B
                            else DOC_I_LIB_DISCOUNT_CHARGE.getPosValueWithoutPMCharge(iPositionID => pos.DOC_POSITION_ID, iCurrencyType => 'B')
                          end
             else DOC_I_LIB_DISCOUNT_CHARGE.getPosValueWithoutPMCharge(iPositionID => pos.DOC_POSITION_ID, iCurrencyType => 'B')
           end POS_NET_VALUE_EXCL_B
         , goo.GCO_GOOD_ID
         , goo.DIC_GOOD_LINE_ID
         , goo.DIC_GOOD_FAMILY_ID
         , goo.DIC_GOOD_MODEL_ID
         , goo.DIC_GOOD_GROUP_ID
         , goo.GOO_MAJOR_REFERENCE
         , goo.GOO_NUMBER_OF_DECIMAL
         , sup.DIC_TYPE_PARTNER_F_ID
         , per.PER_NAME
         , per.PER_KEY1
         , rep.REP_DESCR
         , thi.DIC_THIRD_ACTIVITY_ID
         , thi.DIC_THIRD_AREA_ID
         , des.DES_SHORT_DESCRIPTION
      from DOC_DOCUMENT doc
         , DOC_GAUGE_STRUCTURED str
         , DOC_POSITION pos
         , GCO_GOOD goo
         , GCO_DESCRIPTION des
         , PAC_SUPPLIER_PARTNER sup
         , PAC_PERSON per
         , PAC_REPRESENTATIVE rep
         , PAC_THIRD thi
     where doc.DOC_GAUGE_ID = str.DOC_GAUGE_ID
       and doc.DOC_DOCUMENT_ID = pos.DOC_DOCUMENT_ID
       and pos.GCO_GOOD_ID = goo.GCO_GOOD_ID
       and goo.GCO_GOOD_ID = des.GCO_GOOD_ID
       and des.C_DESCRIPTION_TYPE = '01'
       and des.PC_LANG_ID = vpc_lang_id
       and doc.PAC_THIRD_ID = sup.PAC_SUPPLIER_PARTNER_ID
       and doc.PAC_THIRD_ID = per.PAC_PERSON_ID
       and doc.PAC_THIRD_ID = thi.PAC_THIRD_ID
       and doc.PAC_REPRESENTATIVE_ID = rep.PAC_REPRESENTATIVE_ID(+)
       and (   str.C_GAUGE_TITLE = '4'
            or (    str.C_GAUGE_TITLE = '5'
                and str.GAS_FINANCIAL_CHARGE = 1) )
       and (   parameter_0 = '%'
            or goo.GOO_MAJOR_REFERENCE >= parameter_0)
       and (   parameter_1 = '%'
            or goo.GOO_MAJOR_REFERENCE <= parameter_1)
       and (pos.C_GAUGE_TYPE_POS in('1', '7', '8', '91', '10') )
       and pos.C_DOC_POS_STATUS = '04'
       and (    (    doc.DMT_DATE_DOCUMENT >= to_date(parameter_17, 'YYYYMMDD')
                 and doc.DMT_DATE_DOCUMENT <= to_date(parameter_18, 'YYYYMMDD') )
            or (    doc.DMT_DATE_DOCUMENT >= to_date(parameter_19, 'YYYYMMDD')
                and doc.DMT_DATE_DOCUMENT <= to_date(parameter_20, 'YYYYMMDD') )
           );
end rpt_doc_can_good_supplier;
