--------------------------------------------------------
--  DDL for Procedure RPT_FAM_JOURNAL_ACC_SUM_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAM_JOURNAL_ACC_SUM_SUB" (
   arefcursor    IN OUT   crystal_cursor_types.dualcursortyp,
   parameter_0   IN       VARCHAR2
)
IS
/**
*Description - used for report FAM_JOURNAL_ACCOUTING

*@created JLIU 12 JAN 2009
*@lastUpdate 25 FEB 2009
*@public
*@param PARAMETER_0:  FAM_JOURNAL_ID
*/
BEGIN
   OPEN arefcursor FOR
      SELECT acc.acs_account_id acc_account_id, acc.acc_number acc_number,
             cda.acs_account_id cda_account_id, cda.acc_number cda_number,
             cpn.acs_account_id cpn_account_id, cpn.acc_number cpn_number,
             div.acs_account_id div_account_id, div.acc_number div_number,
             pf.acs_account_id pf_account_id, pf.acc_number pf_number,
             pj.acs_account_id pj_account_id, pj.acc_number pj_number,
             fur.fin_local_currency, yea.fye_no_exercice,
             ftm.c_fam_imputation_typ, ftm.fim_amount_lc_d,
             ftm.fim_amount_lc_c, ftm.fim_amount_fc_d, ftm.fim_amount_fc_c,
             fat.fam_catalogue_id, fat.fca_descr, jou.fam_journal_id,
             jou.fjo_descr, cur.currency
        FROM acs_account acc,
             acs_account cda,
             acs_account cpn,
             acs_account div,
             acs_account pf,
             acs_account pj,
             acs_financial_currency fur,
             acs_financial_year yea,
             fam_act_imputation ftm,
             fam_catalogue fat,
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
         AND fdo.fam_catalogue_id = fat.fam_catalogue_id
         AND jou.fam_journal_id = TO_NUMBER (parameter_0);
END rpt_fam_journal_acc_sum_sub;
