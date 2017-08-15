--------------------------------------------------------
--  DDL for Procedure RPT_FAM_JOURNAL_ACCOUNTING
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAM_JOURNAL_ACCOUNTING" (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0      IN       VARCHAR2,
   parameter_1      IN       VARCHAR2,
   parameter_2      IN       VARCHAR2,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE
)
IS
/**
*Description - Used for report FAM_JOURNAL_ACCOUTING

*@created JLIU 12 JAN 2009
*@lastUpdate   25 FEB 2009
*@public
*@param PARAMETER_0:  Exercice (FYE_NO_EXERCICE)
*@param PARAMETER_1:  Journal from (Jou_Number)
*@param PARAMETER_2:  Journal to (Jou_Number)
*/
   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;              --user language id
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT acc.acc_number acc_number, cda.acc_number cda_number,
             cpn.acc_number cpn_number, div.acc_number div_number,
             pf.acc_number pf_number, pj.acc_number pj_number,
             fur.fin_local_currency, yea.fye_no_exercice,
             ftm.c_fam_imputation_typ, ftm.fim_amount_lc_d,
             ftm.fim_amount_lc_c, ftm.fim_amount_fc_d, ftm.fim_amount_fc_c,
             fdo.fam_document_id, fdo.fdo_int_number, fdo.fdo_ext_number,
             fdo.fdo_document_date, ase.fix_number, ase.fix_short_descr,
             fim.fim_descr, fim.fim_transaction_date, fim.fim_value_date,
             fim.fim_exchange_rate, jou.fam_journal_id, jou.c_journal_status,
             jou.fjo_number, jou.fjo_descr, jou.a_datecre, jou.a_datemod,
             jou.a_idcre, cur.currency
        FROM acs_account acc,
             acs_account cda,
             acs_account cpn,
             acs_account div,
             acs_account pf,
             acs_account pj,
             acs_financial_currency fur,
             acs_financial_year yea,
             fam_act_imputation ftm,
             fam_document fdo,
             fam_fixed_assets ase,
             fam_imputation fim,
             fam_journal jou,
             pcs.pc_curr cur
       WHERE jou.fam_journal_id = fdo.fam_journal_id
         AND fdo.fam_document_id = ftm.fam_document_id(+)
         AND ftm.acs_financial_account_id = acc.acs_account_id(+)
         AND ftm.acs_division_account_id = div.acs_account_id(+)
         AND ftm.acs_cpn_account_id = cpn.acs_account_id(+)
         AND ftm.acs_cda_account_id = cda.acs_account_id(+)
         AND ftm.acs_pj_account_id = pj.acs_account_id(+)
         AND ftm.acs_pf_account_id = pf.acs_account_id(+)
         AND jou.acs_financial_year_id = yea.acs_financial_year_id
         AND ftm.fam_imputation_id = fim.fam_imputation_id(+)
         AND fim.acs_financial_currency_id = fur.acs_financial_currency_id
         AND fur.pc_curr_id = cur.pc_curr_id
         AND fim.fam_fixed_assets_id = ase.fam_fixed_assets_id(+)
         AND yea.fye_no_exercice = TO_NUMBER (parameter_0)
         AND jou.fjo_number >= TO_NUMBER (NVL(parameter_1,0))
         AND jou.fjo_number <= TO_NUMBER (NVL(parameter_2,999999));
END rpt_fam_journal_accounting;
