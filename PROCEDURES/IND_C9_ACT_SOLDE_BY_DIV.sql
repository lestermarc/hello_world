--------------------------------------------------------
--  DDL for Procedure IND_C9_ACT_SOLDE_BY_DIV
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "IND_C9_ACT_SOLDE_BY_DIV" (PROCPARAM0 number,PROCPARAM1 number,PROCPARAM2 number, PROCPARAM3 varchar2, PROCPARAM4 number, PROCPARAM5 number, aRefCursor in out CRYSTAL_CURSOR_TYPES.DualCursorTyp)
 -- Procédure pour rapport Crystal ACT_IMP_BY_DIVISION
 is
 vYear number(4);
 vPeriodFrom number(2);
 vPeriodTo number(2);
 DivNum varchar2(10);
 SansDivExclu number(1);
 DetailPeriod number(1);

 begin
  vYear:=PROCPARAM0;
  vPeriodFrom:=PROCPARAM1;
  vPeriodTo:=PROCPARAM2;
  DivNum:=PROCPARAM3;
  SansDivExclu:=PROCPARAM4;
  DetailPeriod:=PROCPARAM5;

  -- Ouverture du curseur
  OPEN AREFCURSOR FOR
      select
(select acc_number from acs_account acc where tot.acs_division_account_id=acc.acs_account_id) div_number,
(select des_description_summary from acs_description des where tot.acs_division_account_id=des.acs_account_id and des.pc_lang_id=1) div_descr,
(select acc_number from acs_account acc where tot.acs_financial_account_id=acc.acs_account_id) acc_number,
(select des_description_summary from acs_description des where tot.acs_financial_account_id=des.acs_account_id and des.pc_lang_id=1) acc_descr,
(select currency
 from acs_financial_currency fin, pcs.pc_curr cur
 where fin.acs_financial_currency_id = tot.acs_financial_currency_id and fin.pc_curr_id = cur.pc_curr_id) currency1,
tot.tot_debit_lc,
tot.tot_credit_lc,
tot.tot_debit_lc - tot.tot_credit_lc solde_mb,
(select currency
 from acs_financial_currency fin, pcs.pc_curr cur
 where fin.acs_financial_currency_id = tot.acs_acs_financial_currency_id and fin.pc_curr_id = cur.pc_curr_id) currency2,
tot.tot_debit_fc,
tot.tot_credit_fc,
tot.tot_debit_fc - tot.tot_credit_fc solde_me,
yea.FYE_NO_EXERCICE,
per.per_no_period,
(select des_description_summary from acs_description des where per.acs_period_id=des.acs_period_id and des.pc_lang_id=1) period_descr,
per.per_start_date,
per.per_end_date,
tot.c_type_period,
tot.c_type_cumul,
DetailPeriod DETAIL_PERIOD
from
act_total_by_period tot,
acs_period per,
acs_financial_year yea
where
tot.acs_period_id=per.acs_period_id
and per.acs_financial_year_id=yea.acs_financial_year_id
and yea.fye_no_exercice=vYear
and per.per_no_period>=vPeriodFrom
and per.per_no_period<=vPeriodTo
and ((select acc_number from acs_account acc where tot.acs_division_account_id=acc.acs_account_id)=DivNum
     or DivNum is null)
and tot.acs_division_account_id is not null
and tot.acs_auxiliary_account_id is null
and exists (select 1
            from acs_financial_account fin
            where tot.acs_financial_account_id=fin.acs_financial_account_id
            and DIC_FIN_ACC_CODE_5_ID='01')
and not exists (select 1
                 from acs_division_account div
                 where tot.ACS_DIVISION_ACCOUNT_ID=div.acs_division_account_id
                 and div.DIC_DIV_ACC_CODE_1_ID=decode(SansDivExclu,1,'02','XX'));


 end ind_c9_act_solde_by_div;
