--------------------------------------------------------
--  DDL for Procedure RPT_DOC_SUPPL_REMINDER_MAIL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_SUPPL_REMINDER_MAIL" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, parameter_0    in     varchar2
, parameter_1    in     varchar2
, parameter_6    in     varchar2
, parameter_14   in     varchar2
, parameter_15   in     varchar2
, procuser_lanid in     PCS.PC_LANG.LANID%type
)
is
/**
*Description
        Used for report DOC_SUPPL_REMINDER_MAIL

*@created EQI 23 AUG 2007
*@lastUpdate sma 30.10.2013
*@public
*@param parameter_0 : minimum value for PAC_PERSON.PER_KEY1
*@param parameter_1 : maximum value for PAC_PERSON.PER_KEY1
*@param parameter_6 : Final delay for detail information of document
*@param PARAMETER_14 : minimum value for DOC_DOCUMENT.DMT_DATE_DOCUMENT
*@param PARAMETER_15 : maximum value for DOC_DOCUMENT.DMT_DATE_DOCUMENT
*@param procuser_lanid : user language
*/
  vpc_lang_id             PCS.PC_LANG.PC_LANG_ID%type;   --user language id
  nDocDelayWeekstart      number;
begin
  PCS.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  vpc_lang_id  := PCS.PC_I_LIB_SESSION.getuserlangid;

  -- Premier jour de la semaine
  nDocDelayWeekstart := to_number(nvl(PCS.PC_CONFIG.GetConfig('DOC_DELAY_WEEKSTART'), '2') );

  open arefcursor for
    select nDocDelayWeekstart DOC_DELAY_WEEKSTART_CONFIG
         , DOC.DMT_NUMBER
         , ADR.ADD_ADDRESS1
         , ADR.ADD_FORMAT
         , GAS.C_GAUGE_TITLE
         , POS.POS_NUMBER
         , POS.C_GAUGE_TYPE_POS
         , POS.C_DOC_POS_STATUS
         , GAP.C_GAUGE_SHOW_DELAY
         , POS.POS_SHORT_DESCRIPTION
         , PDE.PDE_FINAL_QUANTITY
         , POS.POS_BALANCE_QUANTITY
         , PDE.PDE_BALANCE_QUANTITY
         , PDE_INTERMEDIATE_QUANTITY
         , PDE_MOVEMENT_QUANTITY
         , POS.DIC_UNIT_OF_MEASURE_ID
         , PDE.PDE_FINAL_DELAY
         , PDE.PDE_INTERMEDIATE_DELAY
         , PDE_BASIS_DELAY
         , GOO.GOO_MAJOR_REFERENCE
         , GOO.GOO_NUMBER_OF_DECIMAL
         , PER.PER_NAME
         , PER.PER_KEY1
         , LAN.LANID
         , CUR.CURRENCY
         , count(distinct POS.DIC_UNIT_OF_MEASURE_ID) over(partition by PER.PER_NAME) distinct_measure
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
       and DOC.dmt_date_document >= decode(parameter_14, '0', to_date('19800101', 'YYYYMMDD'), to_date(parameter_14, 'YYYYMMDD') )
       and DOC.dmt_date_document <= decode(parameter_15, '0', to_date('30001231', 'YYYYMMDD'), to_date(parameter_15, 'YYYYMMDD') )
       and GAS.C_GAUGE_TITLE in('1', '5')
       and POS.C_DOC_POS_STATUS in('02', '03')
       and POS.C_GAUGE_TYPE_POS in('1', '7', '8', '91', '10')
       and PER.PER_KEY1 >= parameter_0
       and PER.PER_KEY1 <= parameter_1
       and PDE.PDE_FINAL_DELAY <= decode(parameter_6, '0', to_date('30001231', 'YYYYMMDD'), to_date(parameter_6, 'YYYYMMDD') )
       and PDE.PDE_BALANCE_QUANTITY > 0;
end RPT_DOC_SUPPL_REMINDER_MAIL;
