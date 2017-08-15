--------------------------------------------------------
--  DDL for Procedure RPT_DOC_STD_3_POS_CHARGE_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_STD_3_POS_CHARGE_SUB" (
  arefcursor in out CRYSTAL_CURSOR_TYPES.dualcursortyp
, parameter_3 in number
)
is
/**
*Description - Used for report DOC_STD_3

*@created MZHU 21 Jan 2009
*@lastUpdate VHA 15.05.2014
*@public
*@param parameter_0:  DOC_POSITION_ID
*/
begin
  open arefcursor for
    select DMT.DMT_NUMBER
         , POS.POS_NUMBER
         , POS.DIC_IMP_FREE1_ID
         , POS.DIC_IMP_FREE2_ID
         , POS.DIC_IMP_FREE3_ID
         , POS.DIC_IMP_FREE4_ID
         , POS.DIC_IMP_FREE5_ID
         , POS.DIC_POS_FREE_TABLE_1_ID
         , POS.DIC_POS_FREE_TABLE_2_ID
         , POS.DIC_POS_FREE_TABLE_3_ID
         , DNT.C_CALCULATION_MODE C_CALCULATION_MODE_DNT
         , CRG.C_CALCULATION_MODE C_CALCULATION_MODE_CRG
         , case nvl(DNT.C_CALCULATION_MODE, CRG.C_CALCULATION_MODE)
             when '0' then 'AMOUNT'
             when '1' then 'AMOUNT'
             when '6' then 'AMOUNT'
             when '8' then 'AMOUNT'
             when '2' then 'RATE'
             when '3' then 'RATE'
             when '4' then 'RATE'
             when '5' then 'RATE'
             when '7' then 'RATE'
             when '9' then 'RATE'
           end CHARGE_CALCULATION_MODE
         , PCH.PCH_DESCRIPTION
         , PCH.PCH_NAME
         , PCH.PCH_RATE
         , PCH.PCH_AMOUNT
         , PCH.PCH_EXPRESS_IN
         , PCH.PTC_DISCOUNT_ID
         , PCH.PTC_CHARGE_ID
         , decode(PCH.PTC_DISCOUNT_ID, null, 2, 1) DIS_SUR_GRP
         , PCH.PCH_IN_SERIES_CALCULATION
      from DOC_DOCUMENT DMT
         , DOC_POSITION POS
         , DOC_POSITION_CHARGE PCH
         , PTC_DISCOUNT DNT
         , PTC_CHARGE CRG
     where DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
       and POS.DOC_POSITION_ID = PCH.DOC_POSITION_ID
       and DNT.PTC_DISCOUNT_ID(+) = PCH.PTC_DISCOUNT_ID
       and CRG.PTC_CHARGE_ID(+) = PCH.PTC_CHARGE_ID
       and POS.DOC_POSITION_ID = parameter_3;
end RPT_DOC_STD_3_POS_CHARGE_SUB;
