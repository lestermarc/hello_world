--------------------------------------------------------
--  DDL for Procedure RPT_FAM_FIXED_ASSETS_CATEG
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAM_FIXED_ASSETS_CATEG" (
 aRefCursor       in out CRYSTAL_CURSOR_TYPES.DualCursorTyp,
 PROCUSER_LANID   in     pcs.pc_lang.lanid%type
)
IS

/**
*Description
 Used for the report FAM_FIXED_ASSETS_CATEG

*author JLI
*lastUpdate July 23 2009
*@public
*/

VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;


BEGIN


pcs.PC_I_LIB_SESSION.setLanId (procuser_lanid);
VPC_LANG_ID:= pcs.PC_I_LIB_SESSION.GetUserLangId;



open aRefCursor for

SELECT
FCG.FAM_FIXED_ASSETS_CATEG_ID,
FCG.CAT_DESCR,
FCG.C_FIXED_ASSETS_STATUS,
FCG.C_FIXED_ASSETS_TYP,
FCG.C_OWNERSHIP,
FCG.FAM_NUMBER_METHOD_ID,
FCG.DIC_FAM_CAT_FREECOD1_ID,
FCG.DIC_FAM_CAT_FREECOD2_ID,
FCG.DIC_FAM_CAT_FREECOD3_ID,
FCG.DIC_FAM_CAT_FREECOD4_ID,
FCG.DIC_FAM_CAT_FREECOD5_ID,
FCG.DIC_FAM_CAT_FREECOD6_ID,
FCG.DIC_FAM_CAT_FREECOD7_ID,
FCG.DIC_FAM_CAT_FREECOD8_ID,
FCG.DIC_FAM_CAT_FREECOD9_ID,
FCG.DIC_FAM_CAT_FREECOD10_ID,
MET.ACJ_NUMBER_METHOD_ID,
MET.FNM_LAST_NUMBER
FROM
FAM_FIXED_ASSETS_CATEG FCG,
FAM_NUMBER_METHOD MET
WHERE
FCG.FAM_NUMBER_METHOD_ID = MET.FAM_NUMBER_METHOD_ID(+);

END RPT_FAM_FIXED_ASSETS_CATEG;