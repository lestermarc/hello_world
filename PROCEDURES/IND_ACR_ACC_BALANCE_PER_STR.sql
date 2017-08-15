--------------------------------------------------------
--  DDL for Procedure IND_ACR_ACC_BALANCE_PER_STR
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "IND_ACR_ACC_BALANCE_PER_STR" (
  aRefCursor  in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, PROCPARAM_0 in     number
, PROCPARAM_1 in     varchar2
, PROCUSER_LANID in  pcs.pc_lang.lanid%type
)

is
/**
* Procédure stockée utilisée pour le rapport ACR_ACC_BALANCE_PER_STR (Balance CG à une période, avec classification
*
* @author SDO
* @lastUpdate
* @version 2003
* @public
* @param PROCPARAM_0    Exercice        (FYE_NO_EXERCICE)
* @param PROCPARAM_1    Classification  (ClASSIFICATION_ID)
*/
begin

pcs.pc_init_session.setLanId (procuser_lanid);

open aRefCursor for
    SELECT
        CFL.LEAF_DESCR LEAF_DESCR,
        CFL.NODE01 NODE01,
        CFL.NODE02 NODE02,
        CFL.NODE03 NODE03,
        CFL.NODE04 NODE04,
        CFL.NODE05 NODE05,
        CFL.NODE06 NODE06,
        CFL.NODE07 NODE07,
        CFL.NODE08 NODE08,
        CFL.NODE09 NODE09,
        CFL.NODE10 NODE10,
        TOT.ACS_PERIOd_ID ACS_PERIOD_ID,
        TOT.C_TYPE_PERIOD C_TYPE_PERIOD,
        TOT.C_TYPE_CUMUL C_tYPE_CUMUL,
        TOT.ACS_FINANCIAL_ACCOUNT_ID ACS_FINANCIAL_ACCOUNT_ID,
        ACS_FUNCTION.GetAccountNumber(TOT.ACS_FINANCIAL_ACCOUNT_ID) ACC_NUMBER_FIN,
        TOT.ACS_DIVISION_ACCOUNT_ID ACS_DIVISION_ACCOUNT_ID,
        ACS_FUNCTION.GetAccountNumber(TOT.ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV,
        TOT.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID,
        ACS_FUNCTION.GetLocalCurrencyName LOCAL_CURRENCY_NAME,
        TOT.TOT_DEBIT_LC AMOUNT_LC_D,
        TOT.TOT_CREDIT_LC AMOUNT_LC_C,
        TOT.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID,
        ACS_FUNCTION.GetCurrencyName(TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) CURRENCY_ME,
        TOT.TOT_DEBIT_FC AMOUNT_FC_D,
        TOT.TOT_CREDIT_FC AMOUNT_FC_C,
        PER.PER_NO_PERIOD PER_NO_PERIOD,
        CFL.PC_LANG_ID,
        (select CLN_FREE_BOOLEAN_1
          from classif_node cno, classif_node_descr cnd
          where cno.classif_node_id= cnd.classif_node_id
          and cno.classification_id=cfl.classification_id
          and cnd.pc_lang_id=1
          and ltrim(nvl(cno.CLN_CODE,'')||' '||cnd.des_descr)=NODE01) bool01,
         (select CLN_FREE_BOOLEAN_1
          from classif_node cno, classif_node_descr cnd
          where cno.classif_node_id= cnd.classif_node_id
          and cno.classification_id=cfl.classification_id
          and cnd.pc_lang_id=1
          and ltrim(nvl(cno.CLN_CODE,'')||' '||cnd.des_descr)=NODE02) bool02,
         (select CLN_FREE_BOOLEAN_1
          from classif_node cno, classif_node_descr cnd
          where cno.classif_node_id= cnd.classif_node_id
          and cno.classification_id=cfl.classification_id
          and cnd.pc_lang_id=1
          and ltrim(nvl(cno.CLN_CODE,'')||' '||cnd.des_descr)=NODE03) bool03,
         (select CLN_FREE_BOOLEAN_1
          from classif_node cno, classif_node_descr cnd
          where cno.classif_node_id= cnd.classif_node_id
          and cno.classification_id=cfl.classification_id
          and cnd.pc_lang_id=1
          and ltrim(nvl(cno.CLN_CODE,'')||' '||cnd.des_descr)=NODE04) bool04,
         (select CLN_FREE_BOOLEAN_1
          from classif_node cno, classif_node_descr cnd
          where cno.classif_node_id= cnd.classif_node_id
          and cno.classification_id=cfl.classification_id
          and cnd.pc_lang_id=1
          and ltrim(nvl(cno.CLN_CODE,'')||' '||cnd.des_descr)=NODE05) bool05,
         (select CLN_FREE_BOOLEAN_1
          from classif_node cno, classif_node_descr cnd
          where cno.classif_node_id= cnd.classif_node_id
          and cno.classification_id=cfl.classification_id
          and cnd.pc_lang_id=1
          and ltrim(nvl(cno.CLN_CODE,'')||' '||cnd.des_descr)=NODE06) bool06,
         (select CLN_FREE_BOOLEAN_1
          from classif_node cno, classif_node_descr cnd
          where cno.classif_node_id= cnd.classif_node_id
          and cno.classification_id=cfl.classification_id
          and cnd.pc_lang_id=1
          and ltrim(nvl(cno.CLN_CODE,'')||' '||cnd.des_descr)=NODE07) bool07,
         (select CLN_FREE_BOOLEAN_1
          from classif_node cno, classif_node_descr cnd
          where cno.classif_node_id= cnd.classif_node_id
          and cno.classification_id=cfl.classification_id
          and cnd.pc_lang_id=1
          and ltrim(nvl(cno.CLN_CODE,'')||' '||cnd.des_descr)=NODE08) bool08,
         (select CLN_FREE_BOOLEAN_1
          from classif_node cno, classif_node_descr cnd
          where cno.classif_node_id= cnd.classif_node_id
          and cno.classification_id=cfl.classification_id
          and cnd.pc_lang_id=1
          and ltrim(nvl(cno.CLN_CODE,'')||' '||cnd.des_descr)=NODE09) bool09,
         (select CLN_FREE_BOOLEAN_1
          from classif_node cno, classif_node_descr cnd
          where cno.classif_node_id= cnd.classif_node_id
          and cno.classification_id=cfl.classification_id
          and cnd.pc_lang_id=1
          and ltrim(nvl(cno.CLN_CODE,'')||' '||cnd.des_descr)=NODE10) bool10
    FROM
        ACS_FINANCIAL_YEAR FYE,
        ACS_PERIOD PER,
        ACS_DIVISION_ACCOUNT DIV,
        ACS_FINANCIAL_ACCOUNT ACC,
        ACS_FINANCIAL_CURRENCY FIN,
        ACT_TOTAL_BY_PERIOD TOT,
        CLASSIF_FLAT CFL
    WHERE
        CFL.CLASSIFICATION_ID = PROCPARAM_1 AND
        CFL.CLASSIF_LEAF_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID AND
        TOT.ACS_FINANCIAL_CURRENCY_ID = FIN.ACS_FINANCIAL_CURRENCY_ID AND
        TOT.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_FINANCIAL_ACCOUNT_ID AND
        TOT.ACS_DIVISION_ACCOUNT_ID = DIV.ACS_DIVISION_ACCOUNT_ID (+) AND
        FYE.FYE_NO_EXERCICE = PROCPARAM_0 AND
        FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID AND
        PER.ACS_PERIOD_ID = TOT.ACS_PERIOD_ID AND
        TOT.ACS_AUXILIARY_ACCOUNT_ID IS NULL
  UNION ALL
    SELECT
        (select max(cl.LEAF_DESCR) from CLASSIF_FLAT cl where cl.classification_id=PROCPARAM_1 and instr(cl.leaf_descr,'120999')>0 and cl.pc_lang_id=CFL.PC_LANG_ID) LEAF_DESCR,
        (select max(cl.NODE01) from CLASSIF_FLAT cl where cl.classification_id=PROCPARAM_1 and instr(cl.leaf_descr,'120999')>0 and cl.pc_lang_id=CFL.PC_LANG_ID) NODE01,
        (select max(cl.NODE02) from CLASSIF_FLAT cl where cl.classification_id=PROCPARAM_1 and instr(cl.leaf_descr,'120999')>0 and cl.pc_lang_id=CFL.PC_LANG_ID) NODE02,
        (select max(cl.NODE03) from CLASSIF_FLAT cl where cl.classification_id=PROCPARAM_1 and instr(cl.leaf_descr,'120999')>0 and cl.pc_lang_id=CFL.PC_LANG_ID) NODE03,
        (select max(cl.NODE04) from CLASSIF_FLAT cl where cl.classification_id=PROCPARAM_1 and instr(cl.leaf_descr,'120999')>0 and cl.pc_lang_id=CFL.PC_LANG_ID) NODE04,
        (select max(cl.NODE05) from CLASSIF_FLAT cl where cl.classification_id=PROCPARAM_1 and instr(cl.leaf_descr,'120999')>0 and cl.pc_lang_id=CFL.PC_LANG_ID) NODE05,
        (select max(cl.NODE06) from CLASSIF_FLAT cl where cl.classification_id=PROCPARAM_1 and instr(cl.leaf_descr,'120999')>0 and cl.pc_lang_id=CFL.PC_LANG_ID) NODE06,
        (select max(cl.NODE07) from CLASSIF_FLAT cl where cl.classification_id=PROCPARAM_1 and instr(cl.leaf_descr,'120999')>0 and cl.pc_lang_id=CFL.PC_LANG_ID) NODE07,
        (select max(cl.NODE08) from CLASSIF_FLAT cl where cl.classification_id=PROCPARAM_1 and instr(cl.leaf_descr,'120999')>0 and cl.pc_lang_id=CFL.PC_LANG_ID) NODE08,
        (select max(cl.NODE09) from CLASSIF_FLAT cl where cl.classification_id=PROCPARAM_1 and instr(cl.leaf_descr,'120999')>0 and cl.pc_lang_id=CFL.PC_LANG_ID) NODE09,
        (select max(cl.NODE10) from CLASSIF_FLAT cl where cl.classification_id=PROCPARAM_1 and instr(cl.leaf_descr,'120999')>0 and cl.pc_lang_id=CFL.PC_LANG_ID) NODE10,
        TOT.ACS_PERIOd_ID ACS_PERIOD_ID,
        '2' C_TYPE_PERIOD,
        'EXT' C_tYPE_CUMUL,
        (select max(acs_account_id) from acs_account where acc_number='120999') ACS_FINANCIAL_ACCOUNT_ID,
        '120999' ACC_NUMBER_FIN,
        --(select max(b.acs_division_account_id) from acs_account a, acs_division_account b where a.acs_account_id=b.acs_division_account_id and acc_number='E00000') ACS_DIVISION_ACCOUNT_ID,
        --'E00000' ACC_NUMBER_DIV,
        TOT.ACS_DIVISION_ACCOUNT_ID,
        ACS_FUNCTION.GetAccountNumber(TOT.ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV,
        TOT.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID,
        ACS_FUNCTION.GetLocalCurrencyName LOCAL_CURRENCY_NAME,
        sum(-TOT.TOT_DEBIT_LC) AMOUNT_LC_D,
        sum(-TOT.TOT_CREDIT_LC) AMOUNT_LC_C,
        TOT.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID,
        ACS_FUNCTION.GetCurrencyName(TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) CURRENCY_ME,
        sum(-TOT.TOT_DEBIT_FC) AMOUNT_FC_D,
        sum(-TOT.TOT_CREDIT_FC) AMOUNT_FC_C,
        PER.PER_NO_PERIOD PER_NO_PERIOD,
        CFL.PC_LANG_ID,
        0 bool01,
        0 bool02,
        0 bool03,
        0 bool04,
        0 bool05,
        0 bool06,
        0 bool07,
        0 bool08,
        0 bool09,
        0 bool10
    FROM
        ACS_FINANCIAL_YEAR FYE,
        ACS_PERIOD PER,
        ACS_DIVISION_ACCOUNT DIV,
        ACS_FINANCIAL_ACCOUNT ACC,
        ACS_FINANCIAL_CURRENCY FIN,
        ACT_TOTAL_BY_PERIOD TOT,
        CLASSIF_FLAT CFL
    WHERE
        CFL.CLASSIFICATION_ID = PROCPARAM_1 AND
        CFL.CLASSIF_LEAF_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID AND
        TOT.ACS_FINANCIAL_CURRENCY_ID = FIN.ACS_FINANCIAL_CURRENCY_ID AND
        TOT.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_FINANCIAL_ACCOUNT_ID AND
        TOT.ACS_DIVISION_ACCOUNT_ID = DIV.ACS_DIVISION_ACCOUNT_ID (+) AND
        FYE.FYE_NO_EXERCICE = PROCPARAM_0 AND
        FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID AND
        PER.ACS_PERIOD_ID = TOT.ACS_PERIOD_ID AND
        TOT.ACS_AUXILIARY_ACCOUNT_ID IS NULL
        and acc.c_balance_sheet_profit_loss='B'
        group by
        TOT.ACS_PERIOd_ID,
        TOT.C_TYPE_PERIOD,
        TOT.ACS_DIVISION_ACCOUNT_ID,
        ACS_FUNCTION.GetAccountNumber(TOT.ACS_DIVISION_ACCOUNT_ID),
        TOT.ACS_FINANCIAL_CURRENCY_ID,
        ACS_FUNCTION.GetLocalCurrencyName,
        TOT.ACS_ACS_FINANCIAL_CURRENCY_ID,
        ACS_FUNCTION.GetCurrencyName(TOT.ACS_ACS_FINANCIAL_CURRENCY_ID),
        PER.PER_NO_PERIOD,
        CFL.PC_LANG_ID
    UNION ALL
        SELECT
        (select max(cl.LEAF_DESCR) from CLASSIF_FLAT cl where cl.classification_id=PROCPARAM_1 and instr(cl.leaf_descr,'880000')>0 and cl.pc_lang_id=CFL.PC_LANG_ID) LEAF_DESCR,
        (select max(cl.NODE01) from CLASSIF_FLAT cl where cl.classification_id=PROCPARAM_1 and instr(cl.leaf_descr,'880000')>0 and cl.pc_lang_id=CFL.PC_LANG_ID) NODE01,
        (select max(cl.NODE02) from CLASSIF_FLAT cl where cl.classification_id=PROCPARAM_1 and instr(cl.leaf_descr,'880000')>0 and cl.pc_lang_id=CFL.PC_LANG_ID) NODE02,
        (select max(cl.NODE03) from CLASSIF_FLAT cl where cl.classification_id=PROCPARAM_1 and instr(cl.leaf_descr,'880000')>0 and cl.pc_lang_id=CFL.PC_LANG_ID) NODE03,
        (select max(cl.NODE04) from CLASSIF_FLAT cl where cl.classification_id=PROCPARAM_1 and instr(cl.leaf_descr,'880000')>0 and cl.pc_lang_id=CFL.PC_LANG_ID) NODE04,
        (select max(cl.NODE05) from CLASSIF_FLAT cl where cl.classification_id=PROCPARAM_1 and instr(cl.leaf_descr,'880000')>0 and cl.pc_lang_id=CFL.PC_LANG_ID) NODE05,
        (select max(cl.NODE06) from CLASSIF_FLAT cl where cl.classification_id=PROCPARAM_1 and instr(cl.leaf_descr,'880000')>0 and cl.pc_lang_id=CFL.PC_LANG_ID) NODE06,
        (select max(cl.NODE07) from CLASSIF_FLAT cl where cl.classification_id=PROCPARAM_1 and instr(cl.leaf_descr,'880000')>0 and cl.pc_lang_id=CFL.PC_LANG_ID) NODE07,
        (select max(cl.NODE08) from CLASSIF_FLAT cl where cl.classification_id=PROCPARAM_1 and instr(cl.leaf_descr,'880000')>0 and cl.pc_lang_id=CFL.PC_LANG_ID) NODE08,
        (select max(cl.NODE09) from CLASSIF_FLAT cl where cl.classification_id=PROCPARAM_1 and instr(cl.leaf_descr,'880000')>0 and cl.pc_lang_id=CFL.PC_LANG_ID) NODE09,
        (select max(cl.NODE10) from CLASSIF_FLAT cl where cl.classification_id=PROCPARAM_1 and instr(cl.leaf_descr,'880000')>0 and cl.pc_lang_id=CFL.PC_LANG_ID) NODE10,
        TOT.ACS_PERIOd_ID ACS_PERIOD_ID,
        '2' C_TYPE_PERIOD,
        'EXT' C_tYPE_CUMUL,
        (select max(acs_account_id) from acs_account where acc_number='880000') ACS_FINANCIAL_ACCOUNT_ID,
        '880000' ACC_NUMBER_FIN,
        --(select max(b.acs_division_account_id) from acs_account a, acs_division_account b where a.acs_account_id=b.acs_division_account_id and acc_number='E00000') ACS_DIVISION_ACCOUNT_ID,
        --'E00000' ACC_NUMBER_DIV,
        TOT.ACS_DIVISION_ACCOUNT_ID,
        ACS_FUNCTION.GetAccountNumber(TOT.ACS_DIVISION_ACCOUNT_ID) ACC_NUMBER_DIV,
        TOT.ACS_FINANCIAL_CURRENCY_ID ACS_FINANCIAL_CURRENCY_ID,
        ACS_FUNCTION.GetLocalCurrencyName LOCAL_CURRENCY_NAME,
        sum(-TOT.TOT_DEBIT_LC) AMOUNT_LC_D,
        sum(-TOT.TOT_CREDIT_LC) AMOUNT_LC_C,
        TOT.ACS_ACS_FINANCIAL_CURRENCY_ID ACS_ACS_FINANCIAL_CURRENCY_ID,
        ACS_FUNCTION.GetCurrencyName(TOT.ACS_ACS_FINANCIAL_CURRENCY_ID) CURRENCY_ME,
        sum(-TOT.TOT_DEBIT_FC) AMOUNT_FC_D,
        sum(-TOT.TOT_CREDIT_FC) AMOUNT_FC_C,
        PER.PER_NO_PERIOD PER_NO_PERIOD,
        CFL.PC_LANG_ID,
        0 bool01,
        0 bool02,
        0 bool03,
        0 bool04,
        0 bool05,
        0 bool06,
        0 bool07,
        0 bool08,
        0 bool09,
        0 bool10
    FROM
        ACS_FINANCIAL_YEAR FYE,
        ACS_PERIOD PER,
        ACS_DIVISION_ACCOUNT DIV,
        ACS_FINANCIAL_ACCOUNT ACC,
        ACS_FINANCIAL_CURRENCY FIN,
        ACT_TOTAL_BY_PERIOD TOT,
        CLASSIF_FLAT CFL
    WHERE
        CFL.CLASSIFICATION_ID = PROCPARAM_1 AND
        CFL.CLASSIF_LEAF_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID AND
        TOT.ACS_FINANCIAL_CURRENCY_ID = FIN.ACS_FINANCIAL_CURRENCY_ID AND
        TOT.ACS_FINANCIAL_ACCOUNT_ID = ACC.ACS_FINANCIAL_ACCOUNT_ID AND
        TOT.ACS_DIVISION_ACCOUNT_ID = DIV.ACS_DIVISION_ACCOUNT_ID (+) AND
        FYE.FYE_NO_EXERCICE = PROCPARAM_0 AND
        FYE.ACS_FINANCIAL_YEAR_ID = PER.ACS_FINANCIAL_YEAR_ID AND
        PER.ACS_PERIOD_ID = TOT.ACS_PERIOD_ID AND
        TOT.ACS_AUXILIARY_ACCOUNT_ID IS NULL
        and acc.c_balance_sheet_profit_loss='P'
        group by
        TOT.ACS_PERIOd_ID,
        TOT.C_TYPE_PERIOD,
        TOT.ACS_DIVISION_ACCOUNT_ID,
        ACS_FUNCTION.GetAccountNumber(TOT.ACS_DIVISION_ACCOUNT_ID),
        TOT.ACS_FINANCIAL_CURRENCY_ID,
        ACS_FUNCTION.GetLocalCurrencyName,
        TOT.ACS_ACS_FINANCIAL_CURRENCY_ID,
        ACS_FUNCTION.GetCurrencyName(TOT.ACS_ACS_FINANCIAL_CURRENCY_ID),
        PER.PER_NO_PERIOD,
        CFL.PC_LANG_ID
        ;
end IND_ACR_ACC_BALANCE_PER_STR;
