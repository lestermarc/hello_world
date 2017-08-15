--------------------------------------------------------
--  DDL for Procedure RPT_ACT_ARGMT_SUB_0
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_ACT_ARGMT_SUB_0" (
  aRefCursor             in out CRYSTAL_CURSOR_TYPES.DualCursorTyp
, PARAMETER_0            in     varchar2
)
is
/**
* description used for  sub report of ACT_ARRANGEMENT

* @author JLI  16 Sep 2009
* Published VHA 07 Sept 2011
* public
* @param PARAMETER_0   ACT_DOCUMENT_ID
*/


VPC_LANG_ID pcs.pc_lang.pc_lang_id%type;

BEGIN


open aRefCursor for
SELECT  EXY.ACT_DOCUMENT_ID,
        EXY.EXP_ADAPTED,
        EXY.EXP_AMOUNT_LC,
        EXY.EXP_SLICE,
        CUR.CURRENCY
FROM    ACS_FINANCIAL_CURRENCY FUR,
        ACT_EXPIRY EXY,
        ACT_PART_IMPUTATION IMP,
        PCS.PC_CURR CUR
WHERE   EXY.ACT_DOCUMENT_ID = PARAMETER_0
  AND   EXY.ACT_PART_IMPUTATION_ID = IMP.ACT_PART_IMPUTATION_ID
  AND   IMP.ACS_FINANCIAL_CURRENCY_ID = FUR.ACS_FINANCIAL_CURRENCY_ID
  AND   FUR.PC_CURR_ID = CUR.PC_CURR_ID;
END RPT_ACT_ARGMT_SUB_0;
