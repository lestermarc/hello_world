--------------------------------------------------------
--  DDL for Procedure RPT_ACS_DIVISION_ACCOUNT_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACS_DIVISION_ACCOUNT_SUB" (
  aRefCursor     in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, procparam_10   in     varchar2
, procuser_lanid in     PCS.PC_LANG.LANID%type
)
is
/**
* description used for report ACR_ACC_IMPUTATION_DET
  (Grand livre standard et grand livre pour les communes bernoises)
* @author VHA 2003
 *@created VHA 10 october 2013
* @lastUpdate
* @public
* @param procparam_10    Job ID (COM_LIST)
*/
  vpc_lang_id PCS.PC_LANG.PC_LANG_ID%type;
begin
  if (procuser_lanid is not null) then
      pcs.PC_I_LIB_SESSION.setLanId(procuser_lanid);
      vpc_lang_id  := PCS.PC_I_LIB_SESSION.GetUserLangId;
  end if;

  open aRefCursor for
    select ACC.ACC_NUMBER DIV_NUMBER
      from ACS_ACCOUNT ACC
         , (select LIS_ID_1
              from COM_LIST
             where LIS_JOB_ID = to_number(procparam_10)
               and LIS_CODE = 'ACS_DIVISION_ACCOUNT_ID') LIS
     where ACC.ACS_ACCOUNT_ID = LIS_ID_1;
end RPT_ACS_DIVISION_ACCOUNT_SUB;
