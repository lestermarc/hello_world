--------------------------------------------------------
--  DDL for Procedure RPT_ACR_BALANCE_3_COL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACR_BALANCE_3_COL" (
  arefcursor     in out CRYSTAL_CURSOR_TYPES.dualcursortyp
, procuser_lanid in     pcs.pc_lang.lanid%type
, parameter_0    in     varchar2
, parameter_1    in     number
, parameter_4    in     number
, parameter_5    in     number
, parameter_8    in     number
, parameter_9    in     number
, parameter_12   in     number
, parameter_14   in     varchar2
, parameter_24   in     varchar2
, parameter_29   in     varchar2
, parameter_30   in     varchar2
, parameter_31   in     varchar2
, parameter_32   in     varchar2
, parameter_33   in     varchar2
, pc_user_id     in     pcs.pc_user.pc_user_id%type
, pc_comp_id     in     pcs.pc_comp.pc_comp_id%type
, pc_conli_id    in     pcs.pc_conli.pc_conli_id%type
)
/**
* description used for report ACR_BALANCE_THREE_COL_RPT (Ech???¡ì?|anciers fournisseurs)

*@CREATED MZHU 17.09.2007
*@lastUpdate SMA 22.08.2013
*@PUBLIC
*@param parameter_0:  Classification ID       CLASSIFICATION_ID
*@param parameter_1:  Financial year id       ACS_FINANCIAL_YEAR_ID
*@param parameter_4:  Budget version id       ACB_BUDGET_VERSION_ID
*@param parameter_5:  Financial year id       ACS_FINANCIAL_YEAR_ID
*@param parameter_8:  Budget version id       ACB_BUDGET_VERSION_ID
*@param parameter_9:  Financial year id       ACS_FINANCIAL_YEAR_ID
*@param parameter_12: Budget version id       ACB_BUDGET_VERSION_ID
*@param parameter_14: Budget version id       Division-ID R?¡ì|f (list) / # = all
*@param parameter_24: Budget version id       Division-ID Comp1 (list) / # = all
*@param parameter_29: Budget version id       Division-ID Comp2 (list) / # = all
*@param parameter_30  Count division
*@param parameter_31  Count division
*@param parameter_32  Count division
*@param parameter_33  Impression soldes à 0   CHECK_NULL_BALANCE
*/
is
  vpc_lang_id         PCS.PC_LANG.PC_LANG_ID%type     := null;
  vpc_user_id         PCS.PC_USER.PC_USER_ID%type     := null;
  vpc_comp_id         PCS.PC_COMP.PC_COMP_ID%type     := null;
  vpc_conli_id        PCS.PC_CONLI.PC_CONLI_ID%type   := null;
  v_fye_no_exercice   number(9);
  v_fye_no_exercice_1 number(9);
  v_fye_no_exercice_2 number(9);
  c_fye_no_exercice   number(2);
  c_fye_no_exercice_1 number(2);
  c_fye_no_exercice_2 number(2);
  v_currency          varchar2(5 char);
  v_ver_number        varchar2(30 char);
  v_ver_number_1      varchar2(30 char);
  v_ver_number_2      varchar2(30 char);
  c_ver_number        number(2);
  c_ver_number_1      number(2);
  c_ver_number_2      number(2);
  v_div_ref           varchar2(4000 char);
  v_div_comp1         varchar2(4000 char);
  v_div_comp2         varchar2(4000 char);
begin
  if parameter_0 is not null then
    PCS.PC_LIB_SESSION.setLanUserId(iLanId    => procuser_lanid
                                  , iPcUserId => pc_user_id
                                  , iPcCompId => pc_comp_id
                                  , iConliId  => pc_conli_id);
    vpc_lang_id   := PCS.PC_I_LIB_SESSION.getUserlangId;
    vpc_user_id   := PCS.PC_I_LIB_SESSION.getUserId;
    vpc_comp_id   := PCS.PC_I_LIB_SESSION.getCompanyId;
    vpc_conli_id  := PCS.PC_I_LIB_SESSION.getConliId;
  end if;

  v_fye_no_exercice    := rpt_functions.getfinancialyearno(parameter_1);
  v_fye_no_exercice_1  := rpt_functions.getfinancialyearno(parameter_5);
  v_fye_no_exercice_2  := rpt_functions.getfinancialyearno(parameter_9);

  select CUR.CURRENCY
    into v_currency
    from ACS_FINANCIAL_CURRENCY ACS
       , PCS.PC_CURR CUR
   where ACS.PC_CURR_ID = CUR.PC_CURR_ID
     and ACS.FIN_LOCAL_CURRENCY = 1;

  v_ver_number         := RPT_FUNCTIONS.getbudgetversion(parameter_4);
  v_ver_number_1       := RPT_FUNCTIONS.getbudgetversion(parameter_8);
  v_ver_number_2       := RPT_FUNCTIONS.getbudgetversion(parameter_12);

  if parameter_30 = '1' then
    v_div_ref  := RPT_FUNCTIONS.getaccountnumberlist(parameter_14);
  end if;

  if parameter_31 = '1' then
    v_div_comp1  := RPT_FUNCTIONS.getaccountnumberlist(parameter_24);
  end if;

  if parameter_32 = '1' then
    v_div_comp2  := RPT_FUNCTIONS.getaccountnumberlist(parameter_29);
  end if;

  if (ACS_FUNCTION.ExistDIVI = 1) then
    if (upper(PCS.PC_CONFIG.GetConfig('ACJ_USER_DIV_REPORTING') ) = 'TRUE') then
      open arefcursor for
        select VER.ACB_BUDGET_VERSION_ID
             , PAM.PER_AMOUNT_D
             , PAM.PER_AMOUNT_C
             , ACC.ACS_ACCOUNT_ID
             , ACC.ACC_NUMBER DIVISION_ACC_NUMBER
             , PER.ACS_FINANCIAL_YEAR_ID
             , PER.PER_NO_PERIOD
             , PER_BUD.PER_NO_PERIOD BUD_PER_NO_PERIOD
             , TOT.TOT_DEBIT_LC
             , TOT.TOT_CREDIT_LC
             , TOT.ACS_AUXILIARY_ACCOUNT_ID
             , TOT.C_TYPE_CUMUL
             , TOT.ACS_DIVISION_ACCOUNT_ID
             , CFL.NODE01
             , CFL.NODE02
             , CFL.NODE03
             , CFL.NODE04
             , CFL.NODE05
             , CFL.NODE06
             , CFL.NODE07
             , CFL.NODE08
             , CFL.NODE09
             , CFL.NODE10
             , CFL.CLASSIF_LEAF_ID
             , CFL.LEAF_DESCR
             , VAC.ACC_NUMBER
             , VAC.DES_DESCRIPTION_SUMMARY
             , VAC.ACS_FINANCIAL_ACCOUNT_ID
             , VAC.ISFINACCOUNTINME
             , CLA.CLA_DESCR
             , V_DIV_REF DIV_REF
             , V_DIV_COMP1 DIV_COMP1
             , V_DIV_COMP2 DIV_COMP2
             , V_FYE_NO_EXERCICE FYE_NO_EXERCICE
             , V_FYE_NO_EXERCICE_1 FYE_NO_EXERCICE_1
             , V_FYE_NO_EXERCICE_2 FYE_NO_EXERCICE_2
             , V_CURRENCY CURRENCY
             , V_VER_NUMBER VER_NUMBER
             , V_VER_NUMBER_1 VER_NUMBER_1
             , V_VER_NUMBER_2 VER_NUMBER_2
          from ACB_BUDGET_VERSION VER
             , ACB_GLOBAL_BUDGET GLO
             , ACB_PERIOD_AMOUNT PAM
             , ACS_ACCOUNT ACC
             , ACS_PERIOD PER
             , ACS_PERIOD PER_BUD
             , ACT_TOTAL_BY_PERIOD TOT
             , CLASSIF_FLAT CFL
             , CLASSIFICATION CLA
             , (select ACC.ACS_FINANCIAL_ACCOUNT_ID
                     , TOT.ACS_DIVISION_ACCOUNT_ID
                     , TOT.ACT_TOTAL_BY_PERIOD_ID id
                     , 'TOT' TYP
                     , PER.ACS_FINANCIAL_YEAR_ID
                     , 0 ACB_BUDGET_VERSION_ID
                  from ACS_FINANCIAL_ACCOUNT ACC
                     , ACT_TOTAL_BY_PERIOD TOT
                     , ACS_PERIOD PER
                 where ACC.ACS_FINANCIAL_ACCOUNT_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID
                   and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                   and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
                union all
                select ACC.ACS_FINANCIAL_ACCOUNT_ID
                     , GLO.ACS_DIVISION_ACCOUNT_ID
                     , AMO.ACB_PERIOD_AMOUNT_ID id
                     , 'BUD' TYP
                     , PER.ACS_FINANCIAL_YEAR_ID
                     , GLO.ACB_BUDGET_VERSION_ID
                  from ACS_FINANCIAL_ACCOUNT ACC
                     , ACB_PERIOD_AMOUNT AMO
                     , ACB_GLOBAL_BUDGET GLO
                     , ACS_PERIOD PER
                     , ACS_FINANCIAL_CURRENCY CUR
                 where ACC.ACS_FINANCIAL_ACCOUNT_ID = GLO.ACS_FINANCIAL_ACCOUNT_ID
                   and GLO.ACB_GLOBAL_BUDGET_ID = AMO.ACB_GLOBAL_BUDGET_ID
                   and GLO.ACS_FINANCIAL_CURRENCY_ID = CUR.ACS_FINANCIAL_CURRENCY_ID
                   and CUR.FIN_LOCAL_CURRENCY = 1
                   and AMO.ACS_PERIOD_ID = PER.ACS_PERIOD_ID) VBA
             , (select CLA.CLASSIFICATION_ID
                  from CLASSIFICATION CLA
                     , CLASSIF_TABLES TAB
                 where CLA.CLASSIFICATION_ID = TAB.CLASSIFICATION_ID
                   and TAB.CTA_TABLENAME = 'ACS_ACCOUNT') VCL
             , (select ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID
                     , ACS_ACCOUNT.ACC_NUMBER
                     , ACS_DESCRIPTION.PC_LANG_ID
                     , ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY
                     , ACS_FUNCTION.ISFINACCOUNTINME(ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID) ISFINACCOUNTINME
                  from ACS_DESCRIPTION
                     , ACS_ACCOUNT
                     , ACS_FINANCIAL_ACCOUNT
                     , ACS_SUB_SET
                 where ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
                   and ACS_ACCOUNT.ACS_ACCOUNT_ID = ACS_DESCRIPTION.ACS_ACCOUNT_ID
                   and ACS_ACCOUNT.ACS_SUB_SET_ID = ACS_SUB_SET.ACS_SUB_SET_ID
                   and ACS_SUB_SET.C_SUB_SET = 'ACC') VAC
             , table(RPT_FUNCTIONS.TableAuthRptDivisions(vpc_user_id, null) ) AUT
         where VAC.PC_LANG_ID = vpc_lang_id
           and VAC.ACS_FINANCIAL_ACCOUNT_ID = CFL.CLASSIF_LEAF_ID
           and CFL.CLASSIFICATION_ID = VCL.CLASSIFICATION_ID
           and CFL.PC_LANG_ID = vpc_lang_id
           and VAC.ACS_FINANCIAL_ACCOUNT_ID = VBA.ACS_FINANCIAL_ACCOUNT_ID
           and VBA.id = TOT.ACT_TOTAL_BY_PERIOD_ID(+)
           and VBA.ACS_FINANCIAL_ACCOUNT_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID(+)
           and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID(+)
           and VBA.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID(+)
           and VBA.id = PAM.ACB_PERIOD_AMOUNT_ID(+)
           and PAM.ACB_GLOBAL_BUDGET_ID = GLO.ACB_GLOBAL_BUDGET_ID(+)
           and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID(+)
           and PAM.ACS_PERIOD_ID = PER_BUD.ACS_PERIOD_ID(+)
           and VCL.CLASSIFICATION_ID = CLA.CLASSIFICATION_ID(+)
           and VCL.CLASSIFICATION_ID = to_number(parameter_0)
           and VBA.ACS_FINANCIAL_YEAR_ID in(parameter_1, parameter_5, parameter_9)
           and VBA.ACB_BUDGET_VERSION_ID in(parameter_4, parameter_8, parameter_12)
           and (    (     (    ACC.ACS_ACCOUNT_ID is not null
                           and AUT.column_value is not null)
                     and (ACC.ACS_ACCOUNT_ID = AUT.column_value) )
                or (    ACC.ACS_ACCOUNT_ID is null
                    and AUT.column_value is null
                    and TYP = 'BUD')
               )
        union all
        select 0 ACB_BUDGET_VERSION_ID
             , 0 PER_AMOUNT_D
             , 0 PER_AMOUNT_C
             , null ACS_ACCOUNT_ID
             , null DIVISION_ACC_NUMBER
             , 0 ACS_FINANCIAL_YEAR_ID
             , 0 PER_NO_PERIOD
             , 0 BUD_PER_NO_PERIOD
             , 0 TOT_DEBIT_LC
             , 0 TOT_CREDIT_LC
             , 0 ACS_AUXILIARY_ACCOUNT_ID
             , '' C_TYPE_CUMUL
             , 0 ACS_DIVISION_ACCOUNT_ID
             , CFL.NODE01
             , CFL.NODE02
             , CFL.NODE03
             , CFL.NODE04
             , CFL.NODE05
             , CFL.NODE06
             , CFL.NODE07
             , CFL.NODE08
             , CFL.NODE09
             , CFL.NODE10
             , CFL.CLASSIF_LEAF_ID
             , CFL.LEAF_DESCR
             , VAC.ACC_NUMBER
             , VAC.DES_DESCRIPTION_SUMMARY
             , VAC.ACS_FINANCIAL_ACCOUNT_ID
             , VAC.ISFINACCOUNTINME
             , CLA.CLA_DESCR
             , V_DIV_REF DIV_REF
             , V_DIV_COMP1 DIV_COMP1
             , V_DIV_COMP2 DIV_COMP2
             , V_FYE_NO_EXERCICE FYE_NO_EXERCICE
             , V_FYE_NO_EXERCICE_1 FYE_NO_EXERCICE_1
             , V_FYE_NO_EXERCICE_2 FYE_NO_EXERCICE_2
             , V_CURRENCY CURRENCY
             , V_VER_NUMBER VER_NUMBER
             , V_VER_NUMBER_1 VER_NUMBER_1
             , V_VER_NUMBER_2 VER_NUMBER_2
          from ACS_ACCOUNT ACC
             , CLASSIF_FLAT CFL
             , CLASSIFICATION CLA
             , (select CLA.CLASSIFICATION_ID
                  from CLASSIFICATION CLA
                     , CLASSIF_TABLES TAB
                 where CLA.CLASSIFICATION_ID = TAB.CLASSIFICATION_ID
                   and TAB.CTA_TABLENAME = 'ACS_ACCOUNT') VCL
             , (select ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID
                     , ACS_ACCOUNT.ACC_NUMBER
                     , ACS_DESCRIPTION.PC_LANG_ID
                     , ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY
                     , ACS_FUNCTION.ISFINACCOUNTINME(ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID) ISFINACCOUNTINME
                  from ACS_DESCRIPTION
                     , ACS_ACCOUNT
                     , ACS_FINANCIAL_ACCOUNT
                     , ACS_SUB_SET
                 where ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
                   and ACS_ACCOUNT.ACS_ACCOUNT_ID = ACS_DESCRIPTION.ACS_ACCOUNT_ID
                   and ACS_ACCOUNT.ACS_SUB_SET_ID = ACS_SUB_SET.ACS_SUB_SET_ID
                   and ACS_SUB_SET.C_SUB_SET = 'ACC') VAC
         where VAC.PC_LANG_ID = vpc_lang_id
           and VAC.ACS_FINANCIAL_ACCOUNT_ID = CFL.CLASSIF_LEAF_ID
           and ACC.ACS_ACCOUNT_ID = VAC.ACS_FINANCIAL_ACCOUNT_ID
           and CFL.CLASSIFICATION_ID = VCL.CLASSIFICATION_ID
           and CFL.PC_LANG_ID = vpc_lang_id
           and VCL.CLASSIFICATION_ID = CLA.CLASSIFICATION_ID(+)
           and VCL.CLASSIFICATION_ID = to_number(parameter_0)
           and parameter_33 = '1';
    else   -- Config('ACJ_USER_DIV_REPORTING') = 'FALSE'
      open arefcursor for
        select VER.ACB_BUDGET_VERSION_ID
             , PAM.PER_AMOUNT_D
             , PAM.PER_AMOUNT_C
             , ACC.ACS_ACCOUNT_ID
             , ACC.ACC_NUMBER DIVISION_ACC_NUMBER
             , PER.ACS_FINANCIAL_YEAR_ID
             , PER.PER_NO_PERIOD
             , PER_BUD.PER_NO_PERIOD BUD_PER_NO_PERIOD
             , TOT.TOT_DEBIT_LC
             , TOT.TOT_CREDIT_LC
             , TOT.ACS_AUXILIARY_ACCOUNT_ID
             , TOT.C_TYPE_CUMUL
             , TOT.ACS_DIVISION_ACCOUNT_ID
             , CFL.NODE01
             , CFL.NODE02
             , CFL.NODE03
             , CFL.NODE04
             , CFL.NODE05
             , CFL.NODE06
             , CFL.NODE07
             , CFL.NODE08
             , CFL.NODE09
             , CFL.NODE10
             , CFL.CLASSIF_LEAF_ID
             , CFL.LEAF_DESCR
             , VAC.ACC_NUMBER
             , VAC.DES_DESCRIPTION_SUMMARY
             , VAC.ACS_FINANCIAL_ACCOUNT_ID
             , VAC.ISFINACCOUNTINME
             , CLA.CLA_DESCR
             , V_DIV_REF DIV_REF
             , V_DIV_COMP1 DIV_COMP1
             , V_DIV_COMP2 DIV_COMP2
             , V_FYE_NO_EXERCICE FYE_NO_EXERCICE
             , V_FYE_NO_EXERCICE_1 FYE_NO_EXERCICE_1
             , V_FYE_NO_EXERCICE_2 FYE_NO_EXERCICE_2
             , V_CURRENCY CURRENCY
             , V_VER_NUMBER VER_NUMBER
             , V_VER_NUMBER_1 VER_NUMBER_1
             , V_VER_NUMBER_2 VER_NUMBER_2
          from ACB_BUDGET_VERSION VER
             , ACB_GLOBAL_BUDGET GLO
             , ACB_PERIOD_AMOUNT PAM
             , ACS_ACCOUNT ACC
             , ACS_PERIOD PER
             , ACS_PERIOD PER_BUD
             , ACT_TOTAL_BY_PERIOD TOT
             , CLASSIF_FLAT CFL
             , CLASSIFICATION CLA
             , (select ACC.ACS_FINANCIAL_ACCOUNT_ID
                     , TOT.ACS_DIVISION_ACCOUNT_ID
                     , TOT.ACT_TOTAL_BY_PERIOD_ID id
                     , 'TOT' TYP
                     , PER.ACS_FINANCIAL_YEAR_ID
                     , 0 ACB_BUDGET_VERSION_ID
                  from ACS_FINANCIAL_ACCOUNT ACC
                     , ACT_TOTAL_BY_PERIOD TOT
                     , ACS_PERIOD PER
                 where ACC.ACS_FINANCIAL_ACCOUNT_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID
                   and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                   and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
                union all
                select ACC.ACS_FINANCIAL_ACCOUNT_ID
                     , GLO.ACS_DIVISION_ACCOUNT_ID
                     , AMO.ACB_PERIOD_AMOUNT_ID id
                     , 'BUD' TYP
                     , PER.ACS_FINANCIAL_YEAR_ID
                     , GLO.ACB_BUDGET_VERSION_ID
                  from ACS_FINANCIAL_ACCOUNT ACC
                     , ACB_PERIOD_AMOUNT AMO
                     , ACB_GLOBAL_BUDGET GLO
                     , ACS_PERIOD PER
                     , ACS_FINANCIAL_CURRENCY CUR
                 where ACC.ACS_FINANCIAL_ACCOUNT_ID = GLO.ACS_FINANCIAL_ACCOUNT_ID
                   and GLO.ACB_GLOBAL_BUDGET_ID = AMO.ACB_GLOBAL_BUDGET_ID
                   and GLO.ACS_FINANCIAL_CURRENCY_ID = CUR.ACS_FINANCIAL_CURRENCY_ID
                   and CUR.FIN_LOCAL_CURRENCY = 1
                   and AMO.ACS_PERIOD_ID = PER.ACS_PERIOD_ID) VBA
             , (select CLA.CLASSIFICATION_ID
                  from CLASSIFICATION CLA
                     , CLASSIF_TABLES TAB
                 where CLA.CLASSIFICATION_ID = TAB.CLASSIFICATION_ID
                   and TAB.CTA_TABLENAME = 'ACS_ACCOUNT') VCL
             , (select ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID
                     , ACS_ACCOUNT.ACC_NUMBER
                     , ACS_DESCRIPTION.PC_LANG_ID
                     , ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY
                     , ACS_FUNCTION.ISFINACCOUNTINME(ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID) ISFINACCOUNTINME
                  from ACS_DESCRIPTION
                     , ACS_ACCOUNT
                     , ACS_FINANCIAL_ACCOUNT
                     , ACS_SUB_SET
                 where ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
                   and ACS_ACCOUNT.ACS_ACCOUNT_ID = ACS_DESCRIPTION.ACS_ACCOUNT_ID
                   and ACS_ACCOUNT.ACS_SUB_SET_ID = ACS_SUB_SET.ACS_SUB_SET_ID
                   and ACS_SUB_SET.C_SUB_SET = 'ACC') VAC
         where VAC.PC_LANG_ID = vpc_lang_id
           and VAC.ACS_FINANCIAL_ACCOUNT_ID = CFL.CLASSIF_LEAF_ID
           and CFL.CLASSIFICATION_ID = VCL.CLASSIFICATION_ID
           and CFL.PC_LANG_ID = vpc_lang_id
           and VAC.ACS_FINANCIAL_ACCOUNT_ID = VBA.ACS_FINANCIAL_ACCOUNT_ID
           and VBA.id = TOT.ACT_TOTAL_BY_PERIOD_ID(+)
           and VBA.ACS_FINANCIAL_ACCOUNT_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID(+)
           and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID(+)
           and VBA.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID(+)
           and VBA.id = PAM.ACB_PERIOD_AMOUNT_ID(+)
           and PAM.ACB_GLOBAL_BUDGET_ID = GLO.ACB_GLOBAL_BUDGET_ID(+)
           and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID(+)
           and PAM.ACS_PERIOD_ID = PER_BUD.ACS_PERIOD_ID(+)
           and VCL.CLASSIFICATION_ID = CLA.CLASSIFICATION_ID(+)
           and VCL.CLASSIFICATION_ID = to_number(parameter_0)
           and VBA.ACS_FINANCIAL_YEAR_ID in(parameter_1, parameter_5, parameter_9)
           and VBA.ACB_BUDGET_VERSION_ID in(parameter_4, parameter_8, parameter_12)
           and (    (    ACC.ACS_ACCOUNT_ID is null
                     and TYP = 'BUD')
                or (ACC.ACS_ACCOUNT_ID is not null) )
        union all
        select 0 ACB_BUDGET_VERSION_ID
             , 0 PER_AMOUNT_D
             , 0 PER_AMOUNT_C
             , null ACS_ACCOUNT_ID
             , null DIVISION_ACC_NUMBER
             , 0 ACS_FINANCIAL_YEAR_ID
             , 0 PER_NO_PERIOD
             , 0 BUD_PER_NO_PERIOD
             , 0 TOT_DEBIT_LC
             , 0 TOT_CREDIT_LC
             , 0 ACS_AUXILIARY_ACCOUNT_ID
             , '' C_TYPE_CUMUL
             , 0 ACS_DIVISION_ACCOUNT_ID
             , CFL.NODE01
             , CFL.NODE02
             , CFL.NODE03
             , CFL.NODE04
             , CFL.NODE05
             , CFL.NODE06
             , CFL.NODE07
             , CFL.NODE08
             , CFL.NODE09
             , CFL.NODE10
             , CFL.CLASSIF_LEAF_ID
             , CFL.LEAF_DESCR
             , VAC.ACC_NUMBER
             , VAC.DES_DESCRIPTION_SUMMARY
             , VAC.ACS_FINANCIAL_ACCOUNT_ID
             , VAC.ISFINACCOUNTINME
             , CLA.CLA_DESCR
             , V_DIV_REF DIV_REF
             , V_DIV_COMP1 DIV_COMP1
             , V_DIV_COMP2 DIV_COMP2
             , V_FYE_NO_EXERCICE FYE_NO_EXERCICE
             , V_FYE_NO_EXERCICE_1 FYE_NO_EXERCICE_1
             , V_FYE_NO_EXERCICE_2 FYE_NO_EXERCICE_2
             , V_CURRENCY CURRENCY
             , V_VER_NUMBER VER_NUMBER
             , V_VER_NUMBER_1 VER_NUMBER_1
             , V_VER_NUMBER_2 VER_NUMBER_2
          from ACS_ACCOUNT ACC
             , CLASSIF_FLAT CFL
             , CLASSIFICATION CLA
             , (select CLA.CLASSIFICATION_ID
                  from CLASSIFICATION CLA
                     , CLASSIF_TABLES TAB
                 where CLA.CLASSIFICATION_ID = TAB.CLASSIFICATION_ID
                   and TAB.CTA_TABLENAME = 'ACS_ACCOUNT') VCL
             , (select ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID
                     , ACS_ACCOUNT.ACC_NUMBER
                     , ACS_DESCRIPTION.PC_LANG_ID
                     , ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY
                     , ACS_FUNCTION.ISFINACCOUNTINME(ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID) ISFINACCOUNTINME
                  from ACS_DESCRIPTION
                     , ACS_ACCOUNT
                     , ACS_FINANCIAL_ACCOUNT
                     , ACS_SUB_SET
                 where ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
                   and ACS_ACCOUNT.ACS_ACCOUNT_ID = ACS_DESCRIPTION.ACS_ACCOUNT_ID
                   and ACS_ACCOUNT.ACS_SUB_SET_ID = ACS_SUB_SET.ACS_SUB_SET_ID
                   and ACS_SUB_SET.C_SUB_SET = 'ACC') VAC
         where VAC.PC_LANG_ID = vpc_lang_id
           and VAC.ACS_FINANCIAL_ACCOUNT_ID = CFL.CLASSIF_LEAF_ID
           and ACC.ACS_ACCOUNT_ID = VAC.ACS_FINANCIAL_ACCOUNT_ID
           and CFL.CLASSIFICATION_ID = VCL.CLASSIFICATION_ID
           and CFL.PC_LANG_ID = vpc_lang_id
           and VCL.CLASSIFICATION_ID = CLA.CLASSIFICATION_ID(+)
           and VCL.CLASSIFICATION_ID = to_number(parameter_0)
           and parameter_33 = '1';
    end if;
  else   -- ExistDIVI = 0
    open arefcursor for
      select VER.ACB_BUDGET_VERSION_ID
           , PAM.PER_AMOUNT_D
           , PAM.PER_AMOUNT_C
           , ACC.ACS_ACCOUNT_ID
           , ACC.ACC_NUMBER DIVISION_ACC_NUMBER
           , PER.ACS_FINANCIAL_YEAR_ID
           , PER.PER_NO_PERIOD
           , PER_BUD.PER_NO_PERIOD BUD_PER_NO_PERIOD
           , TOT.TOT_DEBIT_LC
           , TOT.TOT_CREDIT_LC
           , TOT.ACS_AUXILIARY_ACCOUNT_ID
           , TOT.C_TYPE_CUMUL
           , TOT.ACS_DIVISION_ACCOUNT_ID
           , CFL.NODE01
           , CFL.NODE02
           , CFL.NODE03
           , CFL.NODE04
           , CFL.NODE05
           , CFL.NODE06
           , CFL.NODE07
           , CFL.NODE08
           , CFL.NODE09
           , CFL.NODE10
           , CFL.CLASSIF_LEAF_ID
           , CFL.LEAF_DESCR
           , VAC.ACC_NUMBER
           , VAC.DES_DESCRIPTION_SUMMARY
           , VAC.ACS_FINANCIAL_ACCOUNT_ID
           , VAC.ISFINACCOUNTINME
           , CLA.CLA_DESCR
           , V_DIV_REF DIV_REF
           , V_DIV_COMP1 DIV_COMP1
           , V_DIV_COMP2 DIV_COMP2
           , V_FYE_NO_EXERCICE FYE_NO_EXERCICE
           , V_FYE_NO_EXERCICE_1 FYE_NO_EXERCICE_1
           , V_FYE_NO_EXERCICE_2 FYE_NO_EXERCICE_2
           , V_CURRENCY CURRENCY
           , V_VER_NUMBER VER_NUMBER
           , V_VER_NUMBER_1 VER_NUMBER_1
           , V_VER_NUMBER_2 VER_NUMBER_2
        from ACB_BUDGET_VERSION VER
           , ACB_GLOBAL_BUDGET GLO
           , ACB_PERIOD_AMOUNT PAM
           , ACS_ACCOUNT ACC
           , ACS_PERIOD PER
           , ACS_PERIOD PER_BUD
           , ACT_TOTAL_BY_PERIOD TOT
           , CLASSIF_FLAT CFL
           , CLASSIFICATION CLA
           , (select ACC.ACS_FINANCIAL_ACCOUNT_ID
                   , TOT.ACS_DIVISION_ACCOUNT_ID
                   , TOT.ACT_TOTAL_BY_PERIOD_ID id
                   , 'TOT' TYP
                   , PER.ACS_FINANCIAL_YEAR_ID
                   , 0 ACB_BUDGET_VERSION_ID
                from ACS_FINANCIAL_ACCOUNT ACC
                   , ACT_TOTAL_BY_PERIOD TOT
                   , ACS_PERIOD PER
               where ACC.ACS_FINANCIAL_ACCOUNT_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID
                 and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID
                 and TOT.ACS_AUXILIARY_ACCOUNT_ID is null
              union all
              select ACC.ACS_FINANCIAL_ACCOUNT_ID
                   , GLO.ACS_DIVISION_ACCOUNT_ID
                   , AMO.ACB_PERIOD_AMOUNT_ID id
                   , 'BUD' TYP
                   , PER.ACS_FINANCIAL_YEAR_ID
                   , GLO.ACB_BUDGET_VERSION_ID
                from ACS_FINANCIAL_ACCOUNT ACC
                   , ACB_PERIOD_AMOUNT AMO
                   , ACB_GLOBAL_BUDGET GLO
                   , ACS_PERIOD PER
                   , ACS_FINANCIAL_CURRENCY CUR
               where ACC.ACS_FINANCIAL_ACCOUNT_ID = GLO.ACS_FINANCIAL_ACCOUNT_ID
                 and GLO.ACB_GLOBAL_BUDGET_ID = AMO.ACB_GLOBAL_BUDGET_ID
                 and GLO.ACS_FINANCIAL_CURRENCY_ID = CUR.ACS_FINANCIAL_CURRENCY_ID
                 and CUR.FIN_LOCAL_CURRENCY = 1
                 and AMO.ACS_PERIOD_ID = PER.ACS_PERIOD_ID) VBA
           , (select CLA.CLASSIFICATION_ID
                from CLASSIFICATION CLA
                   , CLASSIF_TABLES TAB
               where CLA.CLASSIFICATION_ID = TAB.CLASSIFICATION_ID
                 and TAB.CTA_TABLENAME = 'ACS_ACCOUNT') VCL
           , (select ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID
                   , ACS_ACCOUNT.ACC_NUMBER
                   , ACS_DESCRIPTION.PC_LANG_ID
                   , ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY
                   , ACS_FUNCTION.ISFINACCOUNTINME(ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID) ISFINACCOUNTINME
                from ACS_DESCRIPTION
                   , ACS_ACCOUNT
                   , ACS_FINANCIAL_ACCOUNT
                   , ACS_SUB_SET
               where ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
                 and ACS_ACCOUNT.ACS_ACCOUNT_ID = ACS_DESCRIPTION.ACS_ACCOUNT_ID
                 and ACS_ACCOUNT.ACS_SUB_SET_ID = ACS_SUB_SET.ACS_SUB_SET_ID
                 and ACS_SUB_SET.C_SUB_SET = 'ACC') VAC
       where VAC.PC_LANG_ID = vpc_lang_id
         and VAC.ACS_FINANCIAL_ACCOUNT_ID = CFL.CLASSIF_LEAF_ID
         and CFL.CLASSIFICATION_ID = VCL.CLASSIFICATION_ID
         and CFL.PC_LANG_ID = vpc_lang_id
         and VAC.ACS_FINANCIAL_ACCOUNT_ID = VBA.ACS_FINANCIAL_ACCOUNT_ID
         and VBA.id = TOT.ACT_TOTAL_BY_PERIOD_ID(+)
         and VBA.ACS_FINANCIAL_ACCOUNT_ID = TOT.ACS_FINANCIAL_ACCOUNT_ID(+)
         and TOT.ACS_PERIOD_ID = PER.ACS_PERIOD_ID(+)
         and VBA.ACS_DIVISION_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID(+)
         and VBA.id = PAM.ACB_PERIOD_AMOUNT_ID(+)
         and PAM.ACB_GLOBAL_BUDGET_ID = GLO.ACB_GLOBAL_BUDGET_ID(+)
         and GLO.ACB_BUDGET_VERSION_ID = VER.ACB_BUDGET_VERSION_ID(+)
         and PAM.ACS_PERIOD_ID = PER_BUD.ACS_PERIOD_ID(+)
         and VCL.CLASSIFICATION_ID = CLA.CLASSIFICATION_ID(+)
         and VCL.CLASSIFICATION_ID = to_number(parameter_0)
         and VBA.ACS_FINANCIAL_YEAR_ID in(parameter_1, parameter_5, parameter_9)
         and VBA.ACB_BUDGET_VERSION_ID in(parameter_4, parameter_8, parameter_12)
      union all
      select 0 ACB_BUDGET_VERSION_ID
           , 0 PER_AMOUNT_D
           , 0 PER_AMOUNT_C
           , null ACS_ACCOUNT_ID
           , null DIVISION_ACC_NUMBER
           , 0 ACS_FINANCIAL_YEAR_ID
           , 0 PER_NO_PERIOD
           , 0 BUD_PER_NO_PERIOD
           , 0 TOT_DEBIT_LC
           , 0 TOT_CREDIT_LC
           , 0 ACS_AUXILIARY_ACCOUNT_ID
           , '' C_TYPE_CUMUL
           , 0 ACS_DIVISION_ACCOUNT_ID
           , CFL.NODE01
           , CFL.NODE02
           , CFL.NODE03
           , CFL.NODE04
           , CFL.NODE05
           , CFL.NODE06
           , CFL.NODE07
           , CFL.NODE08
           , CFL.NODE09
           , CFL.NODE10
           , CFL.CLASSIF_LEAF_ID
           , CFL.LEAF_DESCR
           , VAC.ACC_NUMBER
           , VAC.DES_DESCRIPTION_SUMMARY
           , VAC.ACS_FINANCIAL_ACCOUNT_ID
           , VAC.ISFINACCOUNTINME
           , CLA.CLA_DESCR
           , V_DIV_REF DIV_REF
           , V_DIV_COMP1 DIV_COMP1
           , V_DIV_COMP2 DIV_COMP2
           , V_FYE_NO_EXERCICE FYE_NO_EXERCICE
           , V_FYE_NO_EXERCICE_1 FYE_NO_EXERCICE_1
           , V_FYE_NO_EXERCICE_2 FYE_NO_EXERCICE_2
           , V_CURRENCY CURRENCY
           , V_VER_NUMBER VER_NUMBER
           , V_VER_NUMBER_1 VER_NUMBER_1
           , V_VER_NUMBER_2 VER_NUMBER_2
        from ACS_ACCOUNT ACC
           , CLASSIF_FLAT CFL
           , CLASSIFICATION CLA
           , (select CLA.CLASSIFICATION_ID
                from CLASSIFICATION CLA
                   , CLASSIF_TABLES TAB
               where CLA.CLASSIFICATION_ID = TAB.CLASSIFICATION_ID
                 and TAB.CTA_TABLENAME = 'ACS_ACCOUNT') VCL
           , (select ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID
                   , ACS_ACCOUNT.ACC_NUMBER
                   , ACS_DESCRIPTION.PC_LANG_ID
                   , ACS_DESCRIPTION.DES_DESCRIPTION_SUMMARY
                   , ACS_FUNCTION.ISFINACCOUNTINME(ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID) ISFINACCOUNTINME
                from ACS_DESCRIPTION
                   , ACS_ACCOUNT
                   , ACS_FINANCIAL_ACCOUNT
                   , ACS_SUB_SET
               where ACS_FINANCIAL_ACCOUNT.ACS_FINANCIAL_ACCOUNT_ID = ACS_ACCOUNT.ACS_ACCOUNT_ID
                 and ACS_ACCOUNT.ACS_ACCOUNT_ID = ACS_DESCRIPTION.ACS_ACCOUNT_ID
                 and ACS_ACCOUNT.ACS_SUB_SET_ID = ACS_SUB_SET.ACS_SUB_SET_ID
                 and ACS_SUB_SET.C_SUB_SET = 'ACC') VAC
       where VAC.PC_LANG_ID = vpc_lang_id
         and VAC.ACS_FINANCIAL_ACCOUNT_ID = CFL.CLASSIF_LEAF_ID
         and ACC.ACS_ACCOUNT_ID = VAC.ACS_FINANCIAL_ACCOUNT_ID
         and CFL.CLASSIFICATION_ID = VCL.CLASSIFICATION_ID
         and CFL.PC_LANG_ID = vpc_lang_id
         and VCL.CLASSIFICATION_ID = CLA.CLASSIFICATION_ID(+)
         and VCL.CLASSIFICATION_ID = to_number(parameter_0)
         and parameter_33 = '1';
  end if;
end RPT_ACR_BALANCE_3_COL;
