--------------------------------------------------------
--  DDL for Procedure RPT_FAM_FIXED_ASSETS_BY_EMP
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAM_FIXED_ASSETS_BY_EMP" (
 aRefCursor       in out CRYSTAL_CURSOR_TYPES.DualCursorTyp,
 PROCUSER_LANID   in     pcs.pc_lang.lanid%type
)
IS

/**
*Description
Used for report FAM_STRUCTURE

*author VHA
*created on April 21 2011
* @public
*/

VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;

BEGIN
  pcs.PC_I_LIB_SESSION.setLanId (procuser_lanid);
  VPC_LANG_ID:= pcs.PC_I_LIB_SESSION.GetUserLangId;

  open aRefCursor for
    SELECT
      nvl(HPE.PER_FULLNAME, 'zzz') HPE_FULLNAME,
      FIX.FIX_NUMBER,
      FIX.FIX_SHORT_DESCR,
      FIX.FIX_PURCHASE_DATE,
      FIX.FIX_MODEL,
      FIX.FIX_SERIAL_NUMBER,
      FIX.FIX_WARRANT_END,
      LOC.DIC_DESCR
    FROM
      FAM_FIXED_ASSETS FIX,
      DIC_LOCATION LOC,
      HRM_PERSON HPE
    WHERE
      FIX.DIC_LOCATION_ID = LOC.DIC_LOCATION_ID(+)
      AND FIX.HRM_PERSON_ID = HPE.HRM_PERSON_ID(+);

END RPT_FAM_FIXED_ASSETS_BY_EMP;
