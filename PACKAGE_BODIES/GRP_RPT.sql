--------------------------------------------------------
--  DDL for Package Body GRP_RPT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "GRP_RPT" 
IS


PROCEDURE  acr_balance_3_col_be_rpt_pk (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       VARCHAR2,
   parameter_1      IN       NUMBER,
   parameter_4      IN       NUMBER,
   parameter_5      IN       NUMBER,
   parameter_8      IN       NUMBER,
   parameter_9      IN       NUMBER,
   parameter_12     IN       NUMBER,
   account_from     IN       VARCHAR2,
   account_to       IN       VARCHAR2
)

IS

/**
*Description
        Used for report ACR_BALANCE_THREE_COL_BE / ACR_BALANCE_THREE_COL_BE_RECAP / ACR_RECAP_BE / ACR_RECAP_BE_RECAP
**/

   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;              --user language id
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT ver.acb_budget_version_id, pam.per_amount_d, pam.per_amount_c,
             acc.acs_account_id, acc.acc_number division_acc_number,
             per.acs_financial_year_id, per.per_no_period,
             per_bud.per_no_period bud_per_no_period, tot.tot_debit_lc,
             tot.tot_credit_lc, tot.acs_auxiliary_account_id,
             tot.c_type_cumul, tot.acs_division_account_id, cfl.node01,
             cfl.node02, cfl.node03, cfl.node04, cfl.node05, cfl.node06,
             cfl.node07, cfl.node08, cfl.node09, cfl.node10,
             cfl.classif_leaf_id, cfl.leaf_descr, vac.acc_number,
             vac.des_description_summary, cla.cla_descr
        FROM acb_budget_version ver,
             acb_global_budget glo,
             acb_period_amount pam,
             acs_account acc,
             acs_period per,
             acs_period per_bud,
             act_total_by_period tot,
             classif_flat cfl,
             classification cla,
             (SELECT acc.acs_financial_account_id,
                     tot.acs_division_account_id,
                     tot.act_total_by_period_id ID, 'TOT' typ,
                     per.acs_financial_year_id, 0 acb_budget_version_id
                FROM acs_financial_account acc,
                     act_total_by_period tot,
                     acs_period per
               WHERE acc.acs_financial_account_id =
                                                  tot.acs_financial_account_id
                 AND tot.acs_period_id = per.acs_period_id
                 AND tot.acs_auxiliary_account_id IS NULL
              UNION ALL
              SELECT acc.acs_financial_account_id,
                     glo.acs_division_account_id, amo.acb_period_amount_id ID,
                     'BUD' typ, per.acs_financial_year_id,
                     glo.acb_budget_version_id
                FROM acs_financial_account acc,
                     acb_period_amount amo,
                     acb_global_budget glo,
                     acs_period per,
                     acs_financial_currency cur
               WHERE acc.acs_financial_account_id =
                                                  glo.acs_financial_account_id
                 AND glo.acb_global_budget_id = amo.acb_global_budget_id
                 AND glo.acs_financial_currency_id =
                                                 cur.acs_financial_currency_id
                 AND cur.fin_local_currency = 1
                 AND amo.acs_period_id = per.acs_period_id) vba,
             (SELECT cla.classification_id
                FROM classification cla, classif_tables tab
               WHERE cla.classification_id = tab.classification_id
                 AND tab.cta_tablename = 'ACS_ACCOUNT') vcl,
             (SELECT acs_financial_account.acs_financial_account_id,
                     acs_account.acc_number, acs_description.pc_lang_id,
                     acs_description.des_description_summary
                FROM acs_description,
                     acs_account,
                     acs_financial_account,
                     acs_sub_set
               WHERE acs_financial_account.acs_financial_account_id =
                                                    acs_account.acs_account_id
                 AND acs_account.acs_account_id =
                                                acs_description.acs_account_id
                 AND acs_account.acs_sub_set_id = acs_sub_set.acs_sub_set_id
                 AND acs_sub_set.c_sub_set = 'ACC') vac
       WHERE vac.pc_lang_id = vpc_lang_id
         AND vac.acs_financial_account_id = cfl.classif_leaf_id
         AND cfl.classification_id = vcl.classification_id
         AND cfl.pc_lang_id = vpc_lang_id
         AND vac.acs_financial_account_id = vba.acs_financial_account_id
         AND vba.ID = tot.act_total_by_period_id(+)
         AND vba.acs_financial_account_id = tot.acs_financial_account_id(+)
         AND tot.acs_period_id = per.acs_period_id(+)
         AND vba.acs_division_account_id = acc.acs_account_id(+)
         AND vba.ID = pam.acb_period_amount_id(+)
         AND pam.acb_global_budget_id = glo.acb_global_budget_id(+)
         AND glo.acb_budget_version_id = ver.acb_budget_version_id(+)
         AND pam.acs_period_id = per_bud.acs_period_id(+)
         AND vcl.classification_id = cla.classification_id(+)
         AND vcl.classification_id = TO_NUMBER (parameter_0)
         AND vba.acs_financial_year_id IN
                                     (parameter_1, parameter_5, parameter_9)
         AND vba.acb_budget_version_id IN
                                    (parameter_4, parameter_8, parameter_12)
         AND (SUBSTR (LTRIM (cfl.leaf_descr), 1, 3) BETWEEN account_from
                                                        AND account_to
             );
END acr_balance_3_col_be_rpt_pk;

PROCEDURE  acr_bal_3_col_be_sub_rpt_pk (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       VARCHAR2,
   parameter_1      IN       NUMBER,
   parameter_4      IN       NUMBER,
   parameter_5      IN       NUMBER,
   parameter_8      IN       NUMBER,
   parameter_9      IN       NUMBER,
   parameter_12     IN       NUMBER,
   account_from     IN       VARCHAR2,
   account_to       IN       VARCHAR2
)

IS

/**
*Description
        Used for report ACR_BALANCE_THREE_COL_BE.RPT(SUB-REPORT: ACR_RECAP_BE.RPT)
**/

   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;              --user language id
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT ver.acb_budget_version_id, pam.per_amount_d, pam.per_amount_c,
             acc.acs_account_id, acc.acc_number division_acc_number,
             per.acs_financial_year_id, per.per_no_period,
             per_bud.per_no_period bud_per_no_period, tot.tot_debit_lc,
             tot.tot_credit_lc, tot.acs_auxiliary_account_id,
             tot.c_type_cumul, tot.acs_division_account_id, cfl.node01,
             cfl.node02, cfl.leaf_descr, vac.acs_financial_account_id,
             cla.cla_descr
        FROM acb_budget_version ver,
             acb_global_budget glo,
             acb_period_amount pam,
             acs_account acc,
             acs_period per,
             acs_period per_bud,
             act_total_by_period tot,
             classif_flat cfl,
             classification cla,
             (SELECT acc.acs_financial_account_id,
                     tot.acs_division_account_id,
                     tot.act_total_by_period_id ID, 'TOT' typ,
                     per.acs_financial_year_id, 0 acb_budget_version_id
                FROM acs_financial_account acc,
                     act_total_by_period tot,
                     acs_period per
               WHERE acc.acs_financial_account_id =
                                                  tot.acs_financial_account_id
                 AND tot.acs_period_id = per.acs_period_id
                 AND tot.acs_auxiliary_account_id IS NULL
              UNION ALL
              SELECT acc.acs_financial_account_id,
                     glo.acs_division_account_id, amo.acb_period_amount_id ID,
                     'BUD' typ, per.acs_financial_year_id,
                     glo.acb_budget_version_id
                FROM acs_financial_account acc,
                     acb_period_amount amo,
                     acb_global_budget glo,
                     acs_period per,
                     acs_financial_currency cur
               WHERE acc.acs_financial_account_id =
                                                  glo.acs_financial_account_id
                 AND glo.acb_global_budget_id = amo.acb_global_budget_id
                 AND glo.acs_financial_currency_id =
                                                 cur.acs_financial_currency_id
                 AND cur.fin_local_currency = 1
                 AND amo.acs_period_id = per.acs_period_id) vba,
             (SELECT cla.classification_id
                FROM classification cla, classif_tables tab
               WHERE cla.classification_id = tab.classification_id
                 AND tab.cta_tablename = 'ACS_ACCOUNT') vcl,
             (SELECT acs_financial_account.acs_financial_account_id,
                     acs_account.acc_number, acs_description.pc_lang_id,
                     acs_description.des_description_summary
                FROM acs_description,
                     acs_account,
                     acs_financial_account,
                     acs_sub_set
               WHERE acs_financial_account.acs_financial_account_id =
                                                    acs_account.acs_account_id
                 AND acs_account.acs_account_id =
                                                acs_description.acs_account_id
                 AND acs_account.acs_sub_set_id = acs_sub_set.acs_sub_set_id
                 AND acs_sub_set.c_sub_set = 'ACC') vac
       WHERE vac.pc_lang_id = vpc_lang_id
         AND vac.acs_financial_account_id = cfl.classif_leaf_id
         AND cfl.classification_id = vcl.classification_id
         AND cfl.pc_lang_id = vpc_lang_id
         AND vac.acs_financial_account_id = vba.acs_financial_account_id
         AND vba.ID = tot.act_total_by_period_id(+)
         AND vba.acs_financial_account_id = tot.acs_financial_account_id(+)
         AND tot.acs_period_id = per.acs_period_id(+)
         AND vba.acs_division_account_id = acc.acs_account_id(+)
         AND vba.ID = pam.acb_period_amount_id(+)
         AND pam.acb_global_budget_id = glo.acb_global_budget_id(+)
         AND glo.acb_budget_version_id = ver.acb_budget_version_id(+)
         AND pam.acs_period_id = per_bud.acs_period_id(+)
         AND vcl.classification_id = cla.classification_id(+)
         AND vcl.classification_id = TO_NUMBER (parameter_0)
         AND vba.acs_financial_year_id IN
                                      (parameter_1, parameter_5, parameter_9)
         AND vba.acb_budget_version_id IN
                                     (parameter_4, parameter_8, parameter_12)
         AND (SUBSTR (LTRIM (cfl.leaf_descr), 1, 3) BETWEEN account_from
                                                        AND account_to
             );
END acr_bal_3_col_be_sub_rpt_pk;

PROCEDURE  ACR_CREDIT_BE_RPT_PK (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   parameter_0      IN       VARCHAR2

)

IS

/**
*Description
 Used for report ACR_CREDIT_BE.RPT
**/

   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;              --user language id
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

   OPEN arefcursor FOR
      SELECT
      VER.ACB_BUDGET_VERSION_ID,
      PAM.PER_AMOUNT_D,
      PAM.PER_AMOUNT_C,
      ACC.ACS_ACCOUNT_ID,
      PER.ACS_FINANCIAL_YEAR_ID,
      PER.PER_NO_PERIOD,
      PER_BUD.PER_NO_PERIOD PER_NO_PERIOD_BUD,
      TOT.TOT_DEBIT_LC,
      TOT.TOT_CREDIT_LC,
      TOT.ACS_AUXILIARY_ACCOUNT_ID,
      TOT.C_TYPE_CUMUL,
      TOT.ACS_DIVISION_ACCOUNT_ID,
      CFL.NODE01,
      CFL.NODE02,
      CFL.NODE03,
      CFL.NODE04,
      CFL.NODE05,
      CFL.NODE06,
      CFL.NODE07,
      CFL.NODE08,
      CFL.NODE09,
      CFL.NODE10,
      CFL.CLASSIF_LEAF_ID,
      CFL.LEAF_DESCR,
      LAN.LANID,
      LAN_FLAT.LANID LANID_FLAT,
      CLF.CLASSIFICATION_ID_STRING,
      FIN.ACC_NUMBER,
      FIN.DES_DESCRIPTION_SUMMARY
        FROM acb_budget_version ver,
             acb_global_budget glo,
             acb_period_amount pam,
             acs_account acc,
             acs_period per,
             acs_period per_bud,
             act_total_by_period tot,
             classif_flat cfl,
             PCS.PC_LANG LAN,
             PCS.PC_LANG LAN_FLAT,
             V_ACR_BALANCE BAL,
             V_ACS_ACCOUNT_CLASSIF CLF,
             V_ACS_FINANCIAL_ACCOUNT FIN
       WHERE
       FIN.ACS_FINANCIAL_ACCOUNT_ID = CFL.CLASSIF_LEAF_ID
       AND CFL.CLASSIFICATION_ID = CLF.CLASSIFICATION_ID
       AND CFL.PC_LANG_ID = LAN_FLAT.PC_LANG_ID
       AND FIN.ACS_FINANCIAL_ACCOUNT_ID = BAL.ACS_FINANCIAL_ACCOUNT_ID
       AND BAL.ID = TOT.ACT_TOTAL_BY_PERIOD_ID(+)
       AND TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID(+)
       AND BAL.ACS_FINANCIAL_ACCOUNT_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID(+)
       AND BAL.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID(+)
       AND BAL.ID = PAM.ACB_PERIOD_AMOUNT_ID(+)
       AND PAM.ACB_PERIOD_AMOUNT_ID = GLO.ACB_GLOBAL_BUDGET_ID(+)
       AND GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID(+)
       AND PAM.ACS_PERIOD_ID = PER_BUD.ACS_PERIOD_ID(+)
       AND FIN.PC_LANG_ID = LAN.PC_LANG_ID
       AND LAN.PC_LANG_ID(+) = vpc_lang_id
       AND LAN_FLAT.PC_LANG_ID(+) = vpc_lang_id
       AND CLF.CLASSIFICATION_ID_STRING = parameter_0
       AND SUBSTR(FIN.ACC_NUMBER,5,1)<>'4'
       AND SUBSTR(FIN.ACC_NUMBER,5,1)<>'6'
       ;
   END ACR_CREDIT_BE_RPT_PK;

PROCEDURE  ACR_PAC_PERSON_GOV_RPT_PK (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   PARAMETER_0      IN       number,
   PARAMETER_1      IN       date,
   PARAMETER_2      IN       date,
   PARAMETER_3      IN       varchar2
)

IS

/**
*Description
 Used for report ACR_PAC_PERSON_GOV.RPT
*/

   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;              --user language id
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

  OPEN arefcursor FOR
  select DOC.ACT_DOCUMENT_ID ACT_DOCUMENT_ID
       , act_financial_imputation_id act_financial_imputation_id
       , IMP.ACS_FINANCIAL_ACCOUNT_ID ACS_ACCOUNT_iD
       , ACC_NUMBER ACC_NUMBER
       , IMF_DESCRIPTION IMF_DESCRIPTION
       , IMF_TRANSACTION_DATE
       , DOC_NUMBER DOC_NUMBER
       , (IMF_AMOUNT_LC_D) IMF_AMOUNT_LC_D
       , (IMF_AMOUNT_LC_C) IMF_AMOUNT_LC_C
       , 0 IDE_BALANCE_AMOUNT
       , Y.ACS_FINANCIAL_YEAR_ID
       , PERS.PAC_PERSON_ID
       , 0
       , 0
       , PACCUS.PER_NAME
       , PACSUP.PER_NAME
    from ACT_FINANCIAL_IMPUTATION IMP
       , ACT_DOCUMENT DOC
       , ACT_PART_IMPUTATION PAR
       , PAC_CUSTOM_PARTNER CUS
       , PAC_SUPPLIER_PARTNER SUP
       , PAC_PERSON PACCUS
       , PAC_PERSON PACSUP
       , ACS_PERIOD PER
       , ACS_FINANCIAL_YEAR Y
       , ACS_ACCOUNT_CATEG CATEG
       , ACS_ACCOUNT CG
       , PAC_PERSON PERS
   where
     IMP.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
     and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
     AND DOC.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID (+)
     AND PAR.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID (+)
     AND CUS.PAC_CUSTOM_PARTNER_ID = PACCUS.PAC_PERSON_ID (+)
     AND PAR.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID (+)
     AND SUP.PAC_SUPPLIER_PARTNER_ID = PACSUP.PAC_PERSON_ID (+)
     and IMP.PAC_PERSON_ID = PERS.PAC_PERSON_ID
     and PER.ACS_FINANCIAL_YEAR_ID = Y.ACS_FINANCIAL_YEAR_ID
     and IMP.ACS_FINANCIAL_ACCOUNT_ID = CG.ACS_ACCOUNT_ID
     and CG.ACS_ACCOUNT_CATEG_ID = CATEG.ACS_ACCOUNT_CATEG_ID
     and PER.C_TYPE_PERIOD = 2
     and (IMF_TRANSACTION_DATE >= PARAMETER_1 and IMF_TRANSACTION_DATE <= PARAMETER_2)
     and ((PARAMETER_3 = 'N' and PERS.PAC_PERSON_ID = PARAMETER_0) or (PARAMETER_3 <>'N'))
  union all
  select   null ACT_DOCUMENT_ID
         , null act_financial_imputation_id
         , null ACS_ACCOUNT_ID
         , ACC_NUMBER ACC_NUMBER
         , des_description_summary IMF_DESCRIPTION
         , null IMF_TRANSACTION_DATE
         , null DOC_NUMBER
         , sum(IMF_AMOUNT_LC_D) IMF_AMOUNT_LC_D
         , sum(IMF_AMOUNT_LC_C) IMF_AMOUNT_LC_C
         , sum(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C) IDE_BALANCE_AMOUNT
         , Y.ACS_FINANCIAL_YEAR_ID
         , PERS.PAC_PERSON_ID
         , grouping(DES_DESCRIPTION_SUMMARY)
         , grouping(ACC_NUMBER)
         , null
         , null
      from ACT_FINANCIAL_IMPUTATION IMP
         , ACT_DOCUMENT DOC
         , ACS_PERIOD PER
         , ACS_FINANCIAL_YEAR Y
         , ACS_ACCOUNT_CATEG CATEG
         , ACS_ACCOUNT CG
         , PAC_PERSON PERS
         , ACS_DESCRIPTION DESCR
     where IMP.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
       and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
       and IMP.PAC_PERSON_ID = PERS.PAC_PERSON_ID
       and CG.ACS_ACCOUNT_ID = DESCR.ACS_ACCOUNT_ID
       and DESCR.PC_LANG_ID = vpc_lang_id
       and PER.ACS_FINANCIAL_YEAR_ID = Y.ACS_FINANCIAL_YEAR_ID
       and IMP.ACS_FINANCIAL_ACCOUNT_ID = CG.ACS_ACCOUNT_ID
       and CG.ACS_ACCOUNT_CATEG_ID = CATEG.ACS_ACCOUNT_CATEG_ID
       and PER.C_TYPE_PERIOD = 2
       and acc_Number is not null
       and ((PARAMETER_3 = 'N' and PERS.PAC_PERSON_ID = PARAMETER_0) or (PARAMETER_3 <>'N'))
  group by rollup(acc_number, des_description_summary)
         , Y.ACS_FINANCIAL_YEAR_ID
         , PERS.PAC_PERSON_ID
    having grouping(DES_DESCRIPTION_SUMMARY) = 0
        or grouping(ACC_NUMBER) = 1;

END ACR_PAC_PERSON_GOV_RPT_PK ;

PROCEDURE  ACR_PAC_PER_GOV_SUB_RPT_PK (
   arefcursor       IN OUT   crystal_cursor_types.dualcursortyp,
   procuser_lanid   IN       pcs.pc_lang.lanid%TYPE,
   PARAMETER_0      IN       number,
   PARAMETER_1      IN       date,
   PARAMETER_2      IN       date
)

IS

/**
*Description
 Used for report TOT_COMPLIE.RPT, THE SUB REPORT OF ACR_PAC_PERSON_GOV.RPT
*/

   vpc_lang_id   pcs.pc_lang.pc_lang_id%TYPE;              --user language id
BEGIN
   pcs.PC_I_LIB_SESSION.setlanid (procuser_lanid);
   vpc_lang_id := pcs.PC_I_LIB_SESSION.getuserlangid;

  OPEN arefcursor FOR
  select DOC.ACT_DOCUMENT_ID ACT_DOCUMENT_ID
       , act_financial_imputation_id act_financial_imputation_id
       , IMP.ACS_FINANCIAL_ACCOUNT_ID ACS_ACCOUNT_iD
       , ACC_NUMBER ACC_NUMBER
       , IMF_DESCRIPTION IMF_DESCRIPTION
       , IMF_TRANSACTION_DATE
       , DOC_NUMBER DOC_NUMBER
       , (IMF_AMOUNT_LC_D) IMF_AMOUNT_LC_D
       , (IMF_AMOUNT_LC_C) IMF_AMOUNT_LC_C
       , 0 IDE_BALANCE_AMOUNT
       , Y.ACS_FINANCIAL_YEAR_ID
       , PERS.PAC_PERSON_ID
       , 0
       , 0
       , PACCUS.PER_NAME
       , PACSUP.PER_NAME
    from ACT_FINANCIAL_IMPUTATION IMP
       , ACT_DOCUMENT DOC
       , ACT_PART_IMPUTATION PAR
       , PAC_CUSTOM_PARTNER CUS
       , PAC_SUPPLIER_PARTNER SUP
       , PAC_PERSON PACCUS
       , PAC_PERSON PACSUP
       , ACS_PERIOD PER
       , ACS_FINANCIAL_YEAR Y
       , ACS_ACCOUNT_CATEG CATEG
       , ACS_ACCOUNT CG
       , PAC_PERSON PERS
   where
     IMP.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
     and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
     AND DOC.ACT_DOCUMENT_ID = PAR.ACT_DOCUMENT_ID (+)
     AND PAR.PAC_CUSTOM_PARTNER_ID = CUS.PAC_CUSTOM_PARTNER_ID (+)
     AND CUS.PAC_CUSTOM_PARTNER_ID = PACCUS.PAC_PERSON_ID (+)
     AND PAR.PAC_SUPPLIER_PARTNER_ID = SUP.PAC_SUPPLIER_PARTNER_ID (+)
     AND SUP.PAC_SUPPLIER_PARTNER_ID = PACSUP.PAC_PERSON_ID (+)
     and IMP.PAC_PERSON_ID = PERS.PAC_PERSON_ID
     and PER.ACS_FINANCIAL_YEAR_ID = Y.ACS_FINANCIAL_YEAR_ID
     and IMP.ACS_FINANCIAL_ACCOUNT_ID = CG.ACS_ACCOUNT_ID
     and CG.ACS_ACCOUNT_CATEG_ID = CATEG.ACS_ACCOUNT_CATEG_ID
     and PER.C_TYPE_PERIOD = 2
     and (IMF_TRANSACTION_DATE >= PARAMETER_1 and IMF_TRANSACTION_DATE <= PARAMETER_2)
     and PERS.PAC_PERSON_ID = PARAMETER_0
  union all
  select   null ACT_DOCUMENT_ID
         , null act_financial_imputation_id
         , null ACS_ACCOUNT_ID
         , ACC_NUMBER ACC_NUMBER
         , des_description_summary IMF_DESCRIPTION
         , null IMF_TRANSACTION_DATE
         , null DOC_NUMBER
         , sum(IMF_AMOUNT_LC_D) IMF_AMOUNT_LC_D
         , sum(IMF_AMOUNT_LC_C) IMF_AMOUNT_LC_C
         , sum(IMF_AMOUNT_LC_D - IMF_AMOUNT_LC_C) IDE_BALANCE_AMOUNT
         , Y.ACS_FINANCIAL_YEAR_ID
         , PERS.PAC_PERSON_ID
         , grouping(DES_DESCRIPTION_SUMMARY)
         , grouping(ACC_NUMBER)
         , null
         , null
      from ACT_FINANCIAL_IMPUTATION IMP
         , ACT_DOCUMENT DOC
         , ACS_PERIOD PER
         , ACS_FINANCIAL_YEAR Y
         , ACS_ACCOUNT_CATEG CATEG
         , ACS_ACCOUNT CG
         , PAC_PERSON PERS
         , ACS_DESCRIPTION DESCR
     where IMP.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
       and DOC.ACT_DOCUMENT_ID = IMP.ACT_DOCUMENT_ID
       and IMP.PAC_PERSON_ID = PERS.PAC_PERSON_ID
       and CG.ACS_ACCOUNT_ID = DESCR.ACS_ACCOUNT_ID
       and DESCR.PC_LANG_ID = vpc_lang_id
       and PER.ACS_FINANCIAL_YEAR_ID = Y.ACS_FINANCIAL_YEAR_ID
       and IMP.ACS_FINANCIAL_ACCOUNT_ID = CG.ACS_ACCOUNT_ID
       and CG.ACS_ACCOUNT_CATEG_ID = CATEG.ACS_ACCOUNT_CATEG_ID
       and PER.C_TYPE_PERIOD = 2
       and acc_Number is not null
       and PERS.PAC_PERSON_ID = PARAMETER_0
  group by rollup(acc_number, des_description_summary)
         , Y.ACS_FINANCIAL_YEAR_ID
         , PERS.PAC_PERSON_ID
    having grouping(DES_DESCRIPTION_SUMMARY) = 0
        or grouping(ACC_NUMBER) = 1;

END ACR_PAC_PER_GOV_SUB_RPT_PK ;

END GRP_RPT;
