--------------------------------------------------------
--  DDL for Procedure RPT_DOC_STD_3_ASA_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_STD_3_ASA_SUB" (
  arefcursor     in out CRYSTAL_CURSOR_TYPES.dualcursortyp
, procuser_lanid in     PCS.PC_LANG.LANID%type
, parameter_0    in     varchar2
)
is
/**
*Description - Used for report DOC_STD_3

*@created MZHU 17 MAY 2009
*@lastUpdate VHA 14.05.2014
*@public
*@param parameter_2:  ASA_RECORD_ID
*/
  vpc_lang_id PCS.PC_LANG.PC_LANG_ID%type;
begin
  PCS.PC_I_LIB_SESSION.SETLANID(procuser_lanid);
  vpc_lang_id  := PCS.PC_I_LIB_SESSION.getuserlangid;

  open arefcursor for
    select ARE.ARE_CHAR1_VALUE
         , GOO.GOO_MAJOR_REFERENCE
         , ARE.ARE_GCO_SHORT_DESCR
         , ARE.ARE_GCO_LONG_DESCR
         , ARE.ARE_GCO_FREE_DESCR
         , (select DIT.DIT_DESCR
              from DICO_DESCRIPTION DIT
             where DIT.DIT_TABLE = 'DIC_GOOD_FAMILY'
               and DIT.DIT_CODE = GOO.DIC_GOOD_FAMILY_ID
               and DIT.PC_LANG_ID = vpc_lang_id) DIC_GOOD_FAMILY_WORDING
         , GAS.C_GAUGE_TITLE
         , round( decode( ARE.ARE_DATE_END_SENDING
                        , null,(decode(  ARE.ARE_CONF_DATE_C
                                       , null,(  nvl(ARE.ARE_NB_DAYS_WAIT_MAX, nvl(ARE.ARE_NB_DAYS_WAIT, nvl(ARE.ARE_NB_DAYS_WAIT_COMP, 0) ) ) --Wait days
                                               + nvl(ARE.ARE_NB_DAYS, 0) --Repair days
                                               + nvl(ARE.ARE_NB_DAYS_CTRL, 0) --Ctrl days
                                               + nvl(ARE.ARE_NB_DAYS_SENDING, 0) --Sending days
                                               + nvl(ARE.ARE_NB_DAYS_EXP, 0) --Exp days
                                              ) / 5
                                       , (ARE.ARE_CONF_DATE_C - DMT.DMT_DATE_DOCUMENT) / 7
                                      )
                               )
                        , (are.ARE_DATE_END_SENDING - DMT.DMT_DATE_DOCUMENT) / 7
                       )
                ) DUE_DATE
      from ASA_RECORD ARE
         , GCO_GOOD GOO
         , DOC_DOCUMENT DMT
         , DOC_GAUGE_STRUCTURED GAS
     where ARE.GCO_ASA_TO_REPAIR_ID = GOO.GCO_GOOD_ID
       and ARE.ASA_RECORD_ID = DMT.ASA_RECORD_ID
       and DMT.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
       and DMT.DMT_NUMBER = parameter_0;
end RPT_DOC_STD_3_ASA_SUB;
