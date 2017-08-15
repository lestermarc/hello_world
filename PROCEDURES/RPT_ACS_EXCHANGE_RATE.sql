--------------------------------------------------------
--  DDL for Procedure RPT_ACS_EXCHANGE_RATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACS_EXCHANGE_RATE" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_00     IN       VARCHAR2,
   parameter_01     IN       VARCHAR2,
   parameter_02     IN       VARCHAR2,
   parameter_03     IN       VARCHAR2,
   parameter_04     IN       VARCHAR2,
   parameter_05     IN       VARCHAR2,
   parameter_06     IN       VARCHAR2,
   parameter_07     IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
/**
*Description  Used for report acs_exchange_rate
*
*@created Eqi 18 June 2009
*@lastUpdate VHA 26 JUNE 2013
*@public
*@param
*/
IS
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE := null;
BEGIN
  if (procuser_lanid is not null) then
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;
  end if;

   OPEN arefcursor FOR
   SELECT
    ACS_PRICE_CURRENCY.PCU_DAYLY_PRICE,
    ACS_PRICE_CURRENCY.PCU_START_VALIDITY,
    ACS_PRICE_CURRENCY.PCU_VALUATION_PRICE,
    ACS_PRICE_CURRENCY.PCU_INVENTORY_PRICE,
    ACS_PRICE_CURRENCY.PCU_CLOSING_PRICE,
    ACS_PRICE_CURRENCY.PCU_BASE_PRICE,
    PC_CURR.CURRENCY CURRENCY,
    PC_CURR.CURRNAME CURRNAME,
    PC_CURR_2.CURRENCY CURRENCY2,
    PC_CURR_2.CURRNAME CURRNAME2,
    ACS_PRICE_CURRENCY.PCU_VAT_PRICE,
    ACS_PRICE_CURRENCY.PCU_INVOICE_PRICE
    FROM
    ACS_PRICE_CURRENCY     ACS_PRICE_CURRENCY,
    ACS_FINANCIAL_CURRENCY ACS_FINANCIAL_CURRENCY,
    ACS_FINANCIAL_CURRENCY ACS_FINANCIAL_CURRENCY_2,
    PCS.PC_CURR            PC_CURR_2,
    PCS.PC_CURR            PC_CURR
    WHERE
    ACS_PRICE_CURRENCY.ACS_BETWEEN_CURR_ID=ACS_FINANCIAL_CURRENCY.ACS_FINANCIAL_CURRENCY_ID and
    ACS_PRICE_CURRENCY.ACS_AND_CURR_ID=ACS_FINANCIAL_CURRENCY_2.ACS_FINANCIAL_CURRENCY_ID and
    ACS_FINANCIAL_CURRENCY_2.PC_CURR_ID=PC_CURR_2.PC_CURR_ID and
    ACS_FINANCIAL_CURRENCY.PC_CURR_ID=PC_CURR.PC_CURR_ID and
    ( (PARAMETER_02 is null)
        or (Trunc(ACS_PRICE_CURRENCY.PCU_START_VALIDITY)>=Trunc(to_date(PARAMETER_02||'/'||PARAMETER_01||'/'||PARAMETER_00,'DD/MM/YYYY')))
    ) and
    ( (PARAMETER_05 is null)
        or (Trunc(ACS_PRICE_CURRENCY.PCU_START_VALIDITY)<Trunc(to_date(PARAMETER_05||'/'||PARAMETER_04||'/'||PARAMETER_03,'DD/MM/YYYY')))
    ) and
    (PC_CURR.CURRENCY>= parameter_06 OR PC_CURR_2.CURRENCY>= parameter_06) AND
    (PC_CURR.CURRENCY<= parameter_07 OR PC_CURR_2.CURRENCY<= parameter_07);
END rpt_acs_exchange_rate;
