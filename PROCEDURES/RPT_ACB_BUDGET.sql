--------------------------------------------------------
--  DDL for Procedure RPT_ACB_BUDGET
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACB_BUDGET" (
  arefcursor     in out crystal_cursor_types.dualcursortyp
, parameter_0    in     varchar2
, procparam_0    in     varchar2
, procuser_lanid in     pcs.pc_lang.lanid%type
, pc_user_id     in     PCS.PC_USER.PC_USER_ID%type
)
/**
*Description

 Used for report ACB_BUDGET
*@created JLIU 02.JUNE.2009
* @lastUpdate VHA 26 JUNE 2013
*@public
*@PARAM parameter_0    BUDGET VERSION ID
*@procparam_0        Division_ID (List)  NULL = All or ACS_DIVISION_ACCOUNT_ID list
*/
is
  vpc_lang_id PCS.PC_LANG.PC_LANG_ID%type := null;
  vpc_user_id PCS.PC_USER.PC_USER_ID%type := null;
begin

  if parameter_0 is not null then
      PCS.PC_I_LIB_SESSION.setLanId(procuser_lanid);
      PCS.PC_I_LIB_SESSION.setUserId(pc_user_id);
      vpc_lang_id  := PCS.PC_I_LIB_SESSION.getUserlangId;
      vpc_user_id  := PCS.PC_I_LIB_SESSION.getUserId;
  end if;

  if (ACS_FUNCTION.ExistDIVI = 1) then
  open arefcursor for
    select BGT.BUD_DESCR
         , BGT.BUD_COMMENT
         , BGV.ACB_BUDGET_VERSION_ID
         , BGV.C_BUDGET_STATUS
         , BGV.VER_NUMBER
         , BGV.VER_COMMENT
         , BGV.VER_DEFAULT
         , GLB.GLO_DESCR
         , GLB.GLO_AMOUNT_D
         , GLB.GLO_AMOUNT_C
         , GLB.GLO_QTY_D
         , GLB.GLO_QTY_C
         , ACC.ACC_NUMBER
         , CDA.ACC_NUMBER CDA_NUMBER
         , CPN.ACC_NUMBER CPN_NUMBER
         , DIV.ACC_NUMBER DIV_NUMBER
         , FIN.ACC_NUMBER FIN_NUMBER
         , APF.ACC_NUMBER APF_NUMBER
         , APJ.ACC_NUMBER APJ_NUMBER
         , QTY.ACC_NUMBER QTY_NUMBER
         , YEA.FYE_NO_EXERCICE
      from ACB_BUDGET BGT
         , ACB_BUDGET_VERSION BGV
         , ACB_GLOBAL_BUDGET GLB
         , ACS_ACCOUNT ACC
         , ACS_ACCOUNT CDA
         , ACS_ACCOUNT CPN
         , ACS_ACCOUNT DIV
         , ACS_ACCOUNT FIN
         , ACS_ACCOUNT APF
         , ACS_ACCOUNT APJ
         , ACS_ACCOUNT QTY
         , ACS_FINANCIAL_YEAR YEA
         , table(RPT_FUNCTIONS.TableAuthRptDivisions(vpc_user_id, procparam_0) ) AUT
     where BGV.ACB_BUDGET_VERSION_ID = parameter_0
       and BGT.ACB_BUDGET_ID = BGV.ACB_BUDGET_ID
       and BGV.ACB_BUDGET_VERSION_ID = GLB.ACB_BUDGET_VERSION_ID
       and GLB.ACS_BUDGET_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID(+)
       and GLB.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_ACCOUNT_ID(+)
       and GLB.ACS_DIVISION_ACCOUNT_ID = DIV.ACS_ACCOUNT_ID(+)
       and GLB.ACS_CPN_ACCOUNT_ID = CPN.ACS_ACCOUNT_ID(+)
       and GLB.ACS_PF_ACCOUNT_ID = APF.ACS_ACCOUNT_ID(+)
       and GLB.ACS_CDA_ACCOUNT_ID = CDA.ACS_ACCOUNT_ID(+)
       and GLB.ACS_PJ_ACCOUNT_ID = APJ.ACS_ACCOUNT_ID(+)
       and GLB.ACS_QTY_UNIT_ID = QTY.ACS_ACCOUNT_ID(+)
       and BGT.ACS_FINANCIAL_YEAR_ID = YEA.ACS_FINANCIAL_YEAR_ID
       and GLB.ACS_DIVISION_ACCOUNT_ID is not null
       and AUT.column_value = GLB.ACS_DIVISION_ACCOUNT_ID;
else -- if (ACS_FUNCTION.ExistDIVI = 0) = No divisions
  open arefcursor for
    select BGT.BUD_DESCR
         , BGT.BUD_COMMENT
         , BGV.ACB_BUDGET_VERSION_ID
         , BGV.C_BUDGET_STATUS
         , BGV.VER_NUMBER
         , BGV.VER_COMMENT
         , BGV.VER_DEFAULT
         , GLB.GLO_DESCR
         , GLB.GLO_AMOUNT_D
         , GLB.GLO_AMOUNT_C
         , GLB.GLO_QTY_D
         , GLB.GLO_QTY_C
         , ACC.ACC_NUMBER
         , CDA.ACC_NUMBER CDA_NUMBER
         , CPN.ACC_NUMBER CPN_NUMBER
         , DIV.ACC_NUMBER DIV_NUMBER
         , FIN.ACC_NUMBER FIN_NUMBER
         , APF.ACC_NUMBER APF_NUMBER
         , APJ.ACC_NUMBER APJ_NUMBER
         , QTY.ACC_NUMBER QTY_NUMBER
         , YEA.FYE_NO_EXERCICE
      from ACB_BUDGET BGT
         , ACB_BUDGET_VERSION BGV
         , ACB_GLOBAL_BUDGET GLB
         , ACS_ACCOUNT ACC
         , ACS_ACCOUNT CDA
         , ACS_ACCOUNT CPN
         , ACS_ACCOUNT DIV
         , ACS_ACCOUNT FIN
         , ACS_ACCOUNT APF
         , ACS_ACCOUNT APJ
         , ACS_ACCOUNT QTY
         , ACS_FINANCIAL_YEAR YEA
     where BGV.ACB_BUDGET_VERSION_ID = parameter_0
       and BGT.ACB_BUDGET_ID = BGV.ACB_BUDGET_ID
       and BGV.ACB_BUDGET_VERSION_ID = GLB.ACB_BUDGET_VERSION_ID
       and GLB.ACS_BUDGET_ACCOUNT_ID = ACC.ACS_ACCOUNT_ID(+)
       and GLB.ACS_FINANCIAL_ACCOUNT_ID = FIN.ACS_ACCOUNT_ID(+)
       and GLB.ACS_DIVISION_ACCOUNT_ID = DIV.ACS_ACCOUNT_ID(+)
       and GLB.ACS_CPN_ACCOUNT_ID = CPN.ACS_ACCOUNT_ID(+)
       and GLB.ACS_PF_ACCOUNT_ID = APF.ACS_ACCOUNT_ID(+)
       and GLB.ACS_CDA_ACCOUNT_ID = CDA.ACS_ACCOUNT_ID(+)
       and GLB.ACS_PJ_ACCOUNT_ID = APJ.ACS_ACCOUNT_ID(+)
       and GLB.ACS_QTY_UNIT_ID = QTY.ACS_ACCOUNT_ID(+)
       and BGT.ACS_FINANCIAL_YEAR_ID = YEA.ACS_FINANCIAL_YEAR_ID;
end if;
end RPT_ACB_BUDGET;
