--------------------------------------------------------
--  DDL for Procedure RPT_ACT_INTEREST_CERTIFICATE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_INTEREST_CERTIFICATE" (
  aRefCursor             in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, Proccompany_owner      IN     pcs.pc_scrip.scrdbowner%TYPE
, PARAMETER_0           in     varchar2
, PARAMETER_1           in     varchar2
, PARAMETER_2           in     varchar2
, PROCUSER_LANID         in     pcs.pc_lang.lanid%type
)
is

/**
*DESCRIPTION
USED FOR REPORT ACT_INTEREST_CERTIFICATE
*author EQI
*lastUpdate 2 SEP 2010
*public
*@param PARAMETER_0:  FINANCIAL YEAR ID
*@param PARAMETER_1:  icm_description
*@param PARAMETER_2:  icm_description
*/

TMP NUMBER;
VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;
v_max_act_job_id NUMBER;
v_max_period number;
v_com_logo_large pcs.pc_comp.com_logo_large%type;
v_perioddate date;
v_mb varchar2 (10);
v_max_end_date date;

BEGIN

pcs.PC_I_LIB_SESSION.setLanId (procuser_lanid);
VPC_LANG_ID:= pcs.PC_I_LIB_SESSION.GetUserLangId;

select max(act_job_id) into v_max_act_job_id
from  v_act_interest_document v
where (PARAMETER_0 = 0 OR v.acs_financial_year_id = TO_NUMBER(PARAMETER_0))
    AND (PARAMETER_1 IS NULL OR icm_description >= PARAMETER_1)
    AND (PARAMETER_2 IS NULL OR icm_description <= PARAMETER_2);

SELECT MAX (cal.acs_period_id) into v_max_period
     FROM act_calc_period cal,v_act_interest_document v
where (PARAMETER_0 = 0 OR v.acs_financial_year_id = TO_NUMBER(PARAMETER_0))
       AND (PARAMETER_1 IS NULL OR icm_description >= PARAMETER_1)
       AND (PARAMETER_2 IS NULL OR icm_description <= PARAMETER_2)
       AND cal.act_job_id = v.act_job_id;

select max(per_end_date) into v_max_end_date from acs_period where acs_period_id = v_max_period;

SELECT max(com.com_logo_large) into v_com_logo_large
 FROM pcs.pc_comp com, pcs.pc_scrip scr
 WHERE scr.pc_scrip_id = com.pc_scrip_id
 AND scr.scrdbowner = proccompany_owner;

select ACS_FUNCTION.GETLOCALCURRENCYNAME into v_mb from dual;


open aRefCursor for
select
       v_max_act_job_id max_job_id,
       v_max_end_date per_end_date,
       act_job_id,
       acs_int_calc_method_id,
       icm_description,
       c_type_cumul,
       act_calc_period_id,
       v.acs_period_id,
       v.acs_financial_year_id,
       fye_no_exercice,
       v.acs_financial_account_id,
       fin_number,
       v.pac_person_id,
       v.acs_division_account_id,
       div_number,
       v.act_document_id,
       doc_number,
       v.imf_description,
       v.imf_amount_lc_d,
       v.imf_amount_lc_c,
       fin.imf_amount_fc_d,
       fin.imf_amount_fc_c,
       v.act_financial_imputation_id,
       v.c_genre_transaction,
       DES_DESCRIPTION_SUMMARY,
       IMF_EXCHANGE_RATE,
       v.ACS_FINANCIAL_CURRENCY_ID,
       case when v.acs_financial_currency_id is not null then
         (select currency
          from PCS.PC_CURR p, acs_financial_currency cur
          where v.acs_financial_currency_id =  CUR.ACS_FINANCIAL_CURRENCY_ID
                and cur.pc_curr_id = P.PC_CURR_ID)
       else ' '
       end  currency_me,
       v_mb  currency_mb,
       TO_CHAR(imf_transaction_date,'YYYY')||TO_CHAR(imf_transaction_date,'Q') imf_transaction_qdate,
       v_com_logo_large com_logo_large,
       v_max_period max_acs_period_id
 from  v_act_interest_document v,
      act_financial_imputation fin,
      acs_description des
    where V.ACS_FINANCIAL_ACCOUNT_ID = des.acs_account_id
        and des.pc_lang_id = VPC_LANG_ID
        and V.ACT_FINANCIAL_IMPUTATION_ID = FIN.ACT_FINANCIAL_IMPUTATION_ID
        AND (PARAMETER_0 = 0 OR v.acs_financial_year_id = TO_NUMBER(PARAMETER_0))
        AND (PARAMETER_1 IS NULL OR icm_description >= PARAMETER_1)
        AND (PARAMETER_2 IS NULL OR icm_description <= PARAMETER_2);



END RPT_ACT_INTEREST_CERTIFICATE;
