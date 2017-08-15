--------------------------------------------------------
--  DDL for Procedure RPT_ACR_CDA_IMPUTATION_DET
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_CDA_IMPUTATION_DET" (
  aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, PROCPARAM_0 in     number
, PROCPARAM_1 in     varchar2
, PROCPARAM_2 in     varchar2
, PROCUSER_LANID in  pcs.pc_lang.lanid%type
)

is
/**
* description used for report  ACR_CDA_IMPUTATION_DET AND ACR_CDA_IMPUTATION_DET_FC
* (Mouvements CDA sans et avec ME)

* @author SDO
* @lastUpdate 12 Feb 2009
* @public
* @param PROCPARAM_0    Exercice    (FYE_NO_EXERCICE)
* @param PROCPARAM_1    Compte du   (ACC_NUMBER)
* @param PROCPARAM_2    Compte au   (ACC_NUMBER)
*/
begin

pcs.PC_I_LIB_SESSION.setLanId (procuser_lanid);

open aRefCursor for
SELECT
    'REEL' INFO,
    MGM.ACT_MGM_IMPUTATION_ID ACT_MGM_IMPUTATION_ID,
    MGM.ACT_FINANCIAL_IMPUTATION_ID ACT_FINANCIAL_IMPUTATION_ID,
    MGM.IMM_TRANSACTION_DATE IMM_TRANSACTION_DATE,
    MGM.IMM_VALUE_DATE IMM_VALUE_DATE,
    MGM.IMM_DESCRIPTION IMM_DESCRIPTION,
    MGM.ACS_CPN_ACCOUNT_ID ACS_CPN_ACCOUNT_ID,
    ACS_FUNCTION.GetAccountNumber(MGM.ACS_CPN_ACCOUNT_ID) CPN_NUMBER,
    ACS_FUNCTION.GetAccountDescriptionSummary(MGM.ACS_CPN_ACCOUNT_ID) CPN_DESCR,
    MGM.ACS_CDA_ACCOUNT_ID ACS_CDA_ACCOUNT_ID,
    ACS_FUNCTION.GetAccountNumber(MGM.ACS_CDA_ACCOUNT_ID) CDA_NUMBER,
    ACS_FUNCTION.GetAccountDescriptionSummary(MGM.ACS_CDA_ACCOUNT_ID) CDA_SHORT_DESCR,
    ACS_FUNCTION.GetLargeDescription('ACS_ACCOUNT_ID',MGM.ACS_CDA_ACCOUNT_ID) CDA_LARGE_DESCR,
    MGM.ACS_PF_ACCOUNT_ID ACS_PF_ACCOUNT_ID,
    ACS_FUNCTION.GetAccountNumber(MGM.ACS_PF_ACCOUNT_ID) PF_NUMBER,
    DIS.ACT_MGM_DISTRIBUTION_ID ACT_MGM_DISTRIBUTION_ID,
    DIS.ACS_PJ_ACCOUNT_ID ACS_PJ_ACCOUNT_ID,
    ACS_FUNCTION.GetAccountNumber(DIS.ACS_PJ_ACCOUNT_ID) PJ_NUMBER,
    MGM.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID,
    ACS_FUNCTION.GetCurrencyName(MGM.ACS_ACS_FINANCIAL_CURRENCY_ID) CURRENCY_MB,
    MGM.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID,
    ACS_FUNCTION.GetCurrencyName(MGM.ACS_FINANCIAL_CURRENCY_ID) CURRENCY_ME,
    MGM.IMM_AMOUNT_LC_D IMM_AMOUNT_LC_D,
    MGM.IMM_AMOUNT_LC_C IMM_AMOUNT_LC_C,
    MGM.IMM_AMOUNT_FC_D IMM_AMOUNT_FC_D,
    MGM.IMM_AMOUNT_FC_C IMM_AMOUNT_FC_C,
    MGM.ACS_PERIOD_ID ACS_PERIOD_ID,
       MGM.DIC_IMP_FREE1_ID DIC_IMP_FREE1_ID,
    MGM.DIC_IMP_FREE2_ID DIC_IMP_FREE2_ID,
    MGM.DIC_IMP_FREE3_ID DIC_IMP_FREE3_ID,
    MGM.DIC_IMP_FREE4_ID DIC_IMP_FREE4_ID,
    MGM.DIC_IMP_FREE5_ID DIC_IMP_FREE5_ID,
    IMP.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID,
    ACS_FUNCTION.GetAccountNumber(IMP.ACS_FINANCIAL_ACCOUNT_ID) FIN_NUMBER,
    ACT_FUNCTIONS.AuxAccountFromImputation(IMP.ACT_FINANCIAL_IMPUTATION_ID) ACS_AUXILIARY_ACCOUNT_ID,
    ACS_FUNCTION.GetAccountNumber(ACT_FUNCTIONS.AuxAccountFromImputation(IMP.ACT_FINANCIAL_IMPUTATION_ID)) AUX_NUMBER,
    ACS_FUNCTION.GetAccountDescriptionSummary(ACT_FUNCTIONS.AuxAccountFromImputation(IMP.ACT_FINANCIAL_IMPUTATION_ID)) AUX_SHORT_DESCR,
    FYE.ACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR_ID,
    PER.PER_START_DATE PER_START_DATE,
    PER.PER_END_DATE PER_END_DATE,
    PER.C_TYPE_PERIOD C_TYPE_PERIOD,
    DOC.ACT_DOCUMENT_ID ACT_DOCUMENT_ID,
    DOC.DOC_NUMBER DOC_NUMBER,
    DOC.ACT_ACT_JOURNAL_ID ACT_ACT_JOURNAL_ID,
    JOU.ACT_JOURNAL_ID ACT_JOURNAL_ID,
    JOU.JOU_NUMBER JOU_NUMBER,
    JOU.JOU_DESCRIPTION JOU_DESCRIPTION,
    (SELECT ETA.C_ETAT_JOURNAL
     FROM ACT_ETAT_JOURNAL ETA
     WHERE ETA.ACT_JOURNAL_ID = JOU.ACT_JOURNAL_ID AND
           ETA.C_SUB_SET      = 'CPN') C_ETAT_JOURNAL,
    (SELECT SCA.C_TYPE_CUMUL
     FROM ACJ_SUB_SET_CAT SCA
     WHERE SCA.ACJ_CATALOGUE_DOCUMENT_ID = DOC.ACJ_CATALOGUE_DOCUMENT_ID AND
           SCA.C_SUB_SET                 = 'CPN') C_TYPE_CUMUL,
    (SELECT ACC.ACC_DETAIL_PRINTING
     FROM ACS_ACCOUNT ACC
     WHERE ACC.ACS_ACCOUNT_ID = CDA.ACS_CDA_ACCOUNT_ID) ACC_DETAIL_PRINTING,
    JOU.C_TYPE_JOURNAL C_TYPE_JOURNAL,
    PAR.ACT_PART_IMPUTATION_ID,
    PAR.PAR_DOCUMENT,
    0 PER_AMOUNT_D,
    0 PER_AMOUNT_C,
    0 ACB_BUDGET_ID,
    0 ACB_BUDGET_VERSION_ID,
    0 ACB_GLOBAL_BUDGET_ID
FROM
    ACT_JOURNAL               JOU,
    ACT_DOCUMENT              DOC,
    ACS_PERIOD                PER,
    ACS_FINANCIAL_YEAR        FYE,
    ACT_FINANCIAL_IMPUTATION  IMP,
    ACT_PART_IMPUTATION       PAR,
    ACT_MGM_DISTRIBUTION      DIS,
    ACT_MGM_IMPUTATION        MGM,
    ACS_ACCOUNT               ACC,
    ACS_CDA_ACCOUNT           CDA
WHERE
    ACC.ACC_NUMBER                     >= PROCPARAM_1 AND
    ACC.ACC_NUMBER                     <= PROCPARAM_2 AND
    CDA.ACS_CDA_ACCOUNT_ID              = ACC.ACS_ACCOUNT_ID AND
    CDA.ACS_CDA_ACCOUNT_ID              = MGM.ACS_CDA_ACCOUNT_ID (+) AND
    MGM.ACT_FINANCIAL_IMPUTATION_ID     = IMP.ACT_FINANCIAL_IMPUTATION_ID (+) AND
    MGM.ACT_MGM_IMPUTATION_ID           = DIS.ACT_MGM_IMPUTATION_ID (+) AND
    FYE.FYE_NO_EXERCICE                 = PROCPARAM_0 AND
    FYE.ACS_FINANCIAL_YEAR_ID           = PER.ACS_FINANCIAL_YEAR_ID AND
    MGM.ACS_PERIOD_ID                   = PER.ACS_PERIOD_ID AND
    MGM.ACT_DOCUMENT_ID                 = DOC.ACT_DOCUMENT_ID AND
    DOC.ACT_ACT_JOURNAL_ID              = JOU.ACT_JOURNAL_ID AND
    IMP.ACT_PART_IMPUTATION_ID          = PAR.ACT_PART_IMPUTATION_ID(+)
UNION ALL
SELECT
    'REPORT' INFO,
    0 ACT_MGM_IMPUTATION_ID,
    0 ACT_FINANCIAL_IMPUTATION_ID,
    FYE.FYE_START_DATE IMM_TRANSACTION_DATE,
    FYE.FYE_START_DATE IMM_VALUE_DATE,
    'Report' IMM_DESCRIPTION,
    TOT.ACS_CPN_ACCOUNT_ID ACS_CPN_ACCOUNT_ID,
    ACS_FUNCTION.GetAccountNumber(TOT.ACS_CPN_ACCOUNT_ID) CPN_NUMBER,
    ACS_FUNCTION.GetAccountDescriptionSummary(TOT.ACS_CPN_ACCOUNT_ID) CPN_DESCR,
    TOT.ACS_CDA_ACCOUNT_ID ACS_CDA_ACCOUNT_ID,
    ACS_FUNCTION.GetAccountNumber(TOT.ACS_CDA_ACCOUNT_ID) CDA_NUMBER,
    ACS_FUNCTION.GetAccountDescriptionSummary(TOT.ACS_CDA_ACCOUNT_ID) CDA_SHORT_DESCR,
    ACS_FUNCTION.GetLargeDescription('ACS_ACCOUNT_ID',TOT.ACS_CDA_ACCOUNT_ID) CDA_LARGE_DESCR,
    TOT.ACS_PF_ACCOUNT_ID ACS_PF_ACCOUNT_ID,
    ACS_FUNCTION.GetAccountNumber(TOT.ACS_PF_ACCOUNT_ID) PF_NUMBER,
    0 ACT_MGM_DISTRIBUTION_ID,
    TOT.ACS_PJ_ACCOUNT_ID ACS_PJ_ACCOUNT_ID,
    ACS_FUNCTION.GetAccountNumber(TOT.ACS_PJ_ACCOUNT_ID) PJ_NUMBER,
    TOT.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID,
    ACS_FUNCTION.GetCurrencyName(TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) CURRENCY_MB,
    TOT.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID,
    ACS_FUNCTION.GetCurrencyName(TOT.ACS_FINANCIAL_CURRENCY_ID) CURRENCY_ME,
    TOT.MTO_DEBIT_LC IMM_AMOUNT_LC_D,
    TOT.MTO_CREDIT_LC IMM_AMOUNT_LC_C,
    TOT.MTO_DEBIT_FC IMM_AMOUNT_FC_D,
    TOT.MTO_CREDIT_FC IMM_AMOUNT_FC_C,
    TOT.ACS_PERIOD_ID ACS_PERIOD_ID,
    NULL DIC_IMP_FREE1_ID,
    NULL DIC_IMP_FREE2_ID,
    NULL DIC_IMP_FREE3_ID,
    NULL DIC_IMP_FREE4_ID,
    NULL DIC_IMP_FREE5_ID,
    TOT.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID,
    ACS_FUNCTION.GetAccountNumber(TOT.ACS_FINANCIAL_ACCOUNT_ID) FIN_NUMBER,
    0 ACS_AUXILIARY_ACCOUNT_ID,
    NULL AUX_NUMBER,
    NULL AUX_SHORT_DESCR,
    FYE.ACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR_ID,
    PER.PER_START_DATE PER_START_DATE,
    PER.PER_END_DATE PER_END_DATE,
    PER.C_TYPE_PERIOD C_TYPE_PERIOD,
    0 ACT_DOCUMENT_ID,
    NULL DOC_NUMBER,
    0 ACT_ACT_JOURNAL_ID,
    0 ACT_JOURNAL_ID,
    0 JOU_NUMBER,
    NULL JOU_DESCRIPTION,
    'PROV' C_ETAT_JOURNAL,
    TOT.C_TYPE_CUMUL C_TYPE_CUMUL,
    (SELECT ACC.ACC_DETAIL_PRINTING
     FROM ACS_ACCOUNT ACC
     WHERE ACC.ACS_ACCOUNT_ID = CDA.ACS_CDA_ACCOUNT_ID) ACC_DETAIL_PRINTING,
    NULL C_TYPE_JOURNAL,
    NULL ACT_PART_IMPUTATION_ID,
    NULL PAR_DOCUMENT,
    0 PER_AMOUNT_D,
    0 PER_AMOUNT_C,
    0 ACB_BUDGET_ID,
    0 ACB_BUDGET_VERSION_ID,
    0 ACB_GLOBAL_BUDGET_ID
FROM
    ACS_FINANCIAL_YEAR FYE,
    ACS_PERIOD PER,
    ACS_CDA_ACCOUNT CDA,
    ACS_ACCOUNT ACC,
    ACT_MGM_TOT_BY_PERIOD TOT
WHERE
    ACC.ACC_NUMBER                     >= PROCPARAM_1 AND
    ACC.ACC_NUMBER                     <= PROCPARAM_2 AND
    CDA.ACS_CDA_ACCOUNT_ID              = ACC.ACS_ACCOUNT_ID AND
    CDA.ACS_CDA_ACCOUNT_ID              = TOT.ACS_CDA_ACCOUNT_ID AND
    ACS_FUNCTION.GetStatePreviousFinancialYear(FYE.ACS_FINANCIAL_YEAR_ID) = 'ACT' AND
    FYE.FYE_NO_EXERCICE                 = PROCPARAM_0 AND
    FYE.ACS_FINANCIAL_YEAR_ID           = PER.ACS_FINANCIAL_YEAR_ID AND
    PER.ACS_PERIOD_ID                   = TOT.ACS_PERIOD_ID AND
    PER.C_TYPE_PERIOD                   = '1'
UNION ALL
SELECT
    'BUDGET' INFO,
    0 ACT_MGM_IMPUTATION_ID,
    0 ACT_FINANCIAL_IMPUTATION_ID,
    NULL IMM_TRANSACTION_DATE,
    NULL IMM_VALUE_DATE,
    NULL IMM_DESCRIPTION,
    GLO.ACS_CPN_ACCOUNT_ID,
    ACS_FUNCTION.GetAccountNumber(GLO.ACS_CPN_ACCOUNT_ID) CPN_NUMBER,
    ACS_FUNCTION.GetAccountDescriptionSummary(GLO.ACS_CPN_ACCOUNT_ID) CPN_DESCR,
    GLO.ACS_CDA_ACCOUNT_ID ACS_CDA_ACCOUNT_ID,
    ACS_FUNCTION.GetAccountNumber(GLO.ACS_CDA_ACCOUNT_ID) CDA_NUMBER,
    ACS_FUNCTION.GetAccountDescriptionSummary(GLO.ACS_CDA_ACCOUNT_ID) CDA_SHORT_DESCR,
    ACS_FUNCTION.GetLargeDescription('ACS_ACCOUNT_ID',GLO.ACS_CDA_ACCOUNT_ID) CDA_LARGE_DESCR,
    GLO.ACS_PF_ACCOUNT_ID ACS_PF_ACCOUNT_ID,
    ACS_FUNCTION.GetAccountNumber(GLO.ACS_PF_ACCOUNT_ID) PF_NUMBER,
    0 ACT_MGM_DISTRIBUTION_ID,
    GLO.ACS_PJ_ACCOUNT_ID ACS_PJ_ACCOUNT_ID,
    ACS_FUNCTION.GetAccountNumber(GLO.ACS_PJ_ACCOUNT_ID) PJ_NUMBER,
    GLO.ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID,
    ACS_FUNCTION.GetCurrencyName(GLO.ACS_FINANCIAL_CURRENCY_ID) CURRENCY_MB,
    0 ACS_FINANCIAL_CURRENCY_ID,
    NULL CURRENCY_ME,
    0 IMM_AMOUNT_LC_D,
    0 IMM_AMOUNT_LC_C,
    0 IMM_AMOUNT_FC_D,
    0 IMM_AMOUNT_FC_C,
    PERB.ACS_PERIOD_ID ACS_PERIOD_ID,
    NULL DIC_IMP_FREE1_ID,
    NULL DIC_IMP_FREE2_ID,
    NULL DIC_IMP_FREE3_ID,
    NULL DIC_IMP_FREE4_ID,
    NULL DIC_IMP_FREE5_ID,
    GLO.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID,
    ACS_FUNCTION.GetAccountNumber(GLO.ACS_FINANCIAL_ACCOUNT_ID) FIN_NUMBER,
    0 ACS_AUXILIARY_ACCOUNT_ID,
    NULL AUX_NUMBER,
    NULL AUX_SHORT_DESCR,
    FYE.ACS_FINANCIAL_YEAR_ID ACS_FINANCIAL_YEAR_ID,
    PER.PER_START_DATE PER_START_DATE,
    PER.PER_END_DATE PER_END_DATE,
    NULL C_TYPE_PERIOD,
    0 ACT_DOCUMENT_ID,
    NULL DOC_NUMBER,
    0 ACT_ACT_JOURNAL_ID,
    0 ACT_JOURNAL_ID,
    0 JOU_NUMBER,
    NULL JOU_DESCRIPTION,
    NULL C_ETAT_JOURNAL,
    NULL C_TYPE_CUMUL,
    (SELECT ACC.ACC_DETAIL_PRINTING
     FROM ACS_ACCOUNT ACC
     WHERE ACC.ACS_ACCOUNT_ID = CDA.ACS_CDA_ACCOUNT_ID) ACC_DETAIL_PRINTING,
    NULL C_TYPE_JOURNAL,
    NULL ACT_PART_IMPUTATION_ID,
    NULL PAR_DOCUMENT,
    PERB.PER_AMOUNT_D PER_AMOUNT_D,
    PERB.PER_AMOUNT_C PER_AMOUNT_C,
    BUD.ACB_BUDGET_ID ACB_BUDGET_ID,
    VER.ACB_BUDGET_VERSION_ID ACB_BUDGET_VERSION_ID,
    GLO.ACB_GLOBAL_BUDGET_ID ACB_GLOBAL_BUDGET_ID
FROM
    ACS_FINANCIAL_YEAR      FYE,
    ACS_PERIOD              PER,
    ACB_PERIOD_AMOUNT       PERB,
    ACB_GLOBAL_BUDGET       GLO,
    ACB_BUDGET_VERSION      VER,
    ACB_BUDGET              BUD,
    ACS_ACCOUNT             ACC,
    ACS_CDA_ACCOUNT         CDA
WHERE
    FYE.FYE_NO_EXERCICE       = PROCPARAM_0 AND
    FYE.ACS_FINANCIAL_YEAR_ID = BUD.ACS_FINANCIAL_YEAR_ID AND
    BUD.ACB_BUDGET_ID         = VER.ACB_BUDGET_ID AND
    VER.VER_DEFAULT           = 1 AND
    VER.ACB_BUDGET_VERSION_ID = GLO.ACB_BUDGET_VERSION_ID AND
    ACC.ACC_NUMBER            >= PROCPARAM_1 AND
    ACC.ACC_NUMBER            <= PROCPARAM_2 AND
    ACC.ACS_ACCOUNT_ID        = CDA.ACS_CDA_ACCOUNT_ID AND
    CDA.ACS_CDA_ACCOUNT_ID    = GLO.ACS_CDA_ACCOUNT_ID AND
    GLO.ACB_GLOBAL_BUDGET_ID  = PERB.ACB_GLOBAL_BUDGET_ID AND
    PERB.ACS_PERIOD_ID        = PER.ACS_PERIOD_ID AND
    PER.ACS_FINANCIAL_YEAR_ID = FYE.ACS_FINANCIAL_YEAR_ID
UNION ALL
SELECT
    'VIDE' INFO,
    0 ACT_MGM_IMPUTATION_ID,
    0 ACT_FINANCIAL_IMPUTATION_ID,
    NULL IMM_TRANSACTION_DATE,
    NULL IMM_VALUE_DATE,
    NULL IMM_DESCRIPTION,
    0 ACS_CPN_ACCOUNT_ID,
    NULL CPN_NUMBER,
    NULL CPN_DESCR,
    0 ACS_CDA_ACCOUNT_ID,
    ACS_FUNCTION.GetAccountNumber(CDA.ACS_CDA_ACCOUNT_ID) CDA_NUMBER,
    ACS_FUNCTION.GetAccountDescriptionSummary(CDA.ACS_CDA_ACCOUNT_ID) CDA_SHORT_DESCR,
    ACS_FUNCTION.GetLargeDescription('ACS_ACCOUNT_ID',CDA.ACS_CDA_ACCOUNT_ID) CDA_LARGE_DESCR,
    0 ACS_PF_ACCOUNT_ID,
    NULL PF_NUMBER,
    0 ACT_MGM_DISTRIBUTION_ID,
    0 ACS_PJ_ACCOUNT_ID,
    NULL PJ_NUMBER,
    0 ACS_ACS_FINANCIAL_CURRENCY_ID,
    NULL CURRENCY_MB,
    0 ACS_FINANCIAL_CURRENCY_ID,
    NULL CURRENCY_ME,
    0 IMM_AMOUNT_LC_D,
    0 IMM_AMOUNT_LC_C,
    0 IMM_AMOUNT_FC_D,
    0 IMM_AMOUNT_FC_C,
    0 ACS_PERIOD_ID,
    NULL DIC_IMP_FREE1_ID,
    NULL DIC_IMP_FREE2_ID,
    NULL DIC_IMP_FREE3_ID,
    NULL DIC_IMP_FREE4_ID,
    NULL DIC_IMP_FREE5_ID,
    0 ACS_FINANCIAL_ACCOUNT_ID,
    NULL FIN_NUMBER,
    0 ACS_AUXILIARY_ACCOUNT_ID,
    NULL AUX_NUMBER,
    NULL AUX_SHORT_DESCR,
    0 ACS_FINANCIAL_YEAR_ID,
    NULL PER_START_DATE,
    NULL PER_END_DATE,
    NULL C_TYPE_PERIOD,
    0 ACT_DOCUMENT_ID,
    NULL DOC_NUMBER,
    0 ACT_ACT_JOURNAL_ID,
    0 ACT_JOURNAL_ID,
    0 JOU_NUMBER,
    NULL JOU_DESCRIPTION,
    'PROV' C_ETAT_JOURNAL,
    NULL C_TYPE_CUMUL,
    (SELECT ACC.ACC_DETAIL_PRINTING
     FROM ACS_ACCOUNT ACC
     WHERE ACC.ACS_ACCOUNT_ID = CDA.ACS_CDA_ACCOUNT_ID) ACC_DETAIL_PRINTING,
    NULL C_TYPE_JOURNAL,
    NULL ACT_PART_IMPUTATION_ID,
    NULL PAR_DOCUMENT,
    0 PER_AMOUNT_D,
    0 PER_AMOUNT_C,
    0 ACB_BUDGET_ID,
    0 ACB_BUDGET_VERSION_ID,
    0 ACB_GLOBAL_BUDGET_ID
FROM
    ACS_CDA_ACCOUNT CDA,
    ACS_ACCOUNT     ACC
WHERE
    ACC.ACC_NUMBER      >= PROCPARAM_1 AND
    ACC.ACC_NUMBER      <= PROCPARAM_2 AND
    ACC.ACS_ACCOUNT_ID   = CDA.ACS_CDA_ACCOUNT_ID AND
    NOT EXISTS(SELECT 1
               FROM ACS_FINANCIAL_YEAR  FYE,
                    ACS_PERIOD          PER,
                    ACT_MGM_IMPUTATION  MGM
                WHERE   FYE.FYE_NO_EXERCICE         = PROCPARAM_0 AND
                        FYE.ACS_FINANCIAL_YEAR_ID   = PER.ACS_FINANCIAL_YEAR_ID AND
                        MGM.ACS_PERIOD_ID           = PER.ACS_PERIOD_ID AND
                        MGM.ACS_CDA_ACCOUNT_ID      = CDA.ACS_CDA_ACCOUNT_ID) AND
    NOT EXISTS(SELECT 1
               FROM ACS_FINANCIAL_YEAR              FYE,
                    ACS_PERIOD                      PER,
                    ACT_MGM_TOT_BY_PERIOD            TOT
                WHERE   FYE.FYE_NO_EXERCICE         = PROCPARAM_0 AND
                        FYE.ACS_FINANCIAL_YEAR_ID   = PER.ACS_FINANCIAL_YEAR_ID AND
                        TOT.ACS_PERIOD_ID           = PER.ACS_PERIOD_ID AND
                        TOT.ACS_CDA_ACCOUNT_ID      = CDA.ACS_CDA_ACCOUNT_ID);
end RPT_ACR_CDA_IMPUTATION_DET;
