--------------------------------------------------------
--  DDL for Procedure RPT_DOC_STD_3_ASA_REPLY_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_DOC_STD_3_ASA_REPLY_SUB" (
  arefcursor     in out CRYSTAL_CURSOR_TYPES.dualcursortyp
, procuser_lanid in     PCS.PC_LANG.LANID%type
, parameter_0       in     DOC_DOCUMENT.DMT_NUMBER%type
)
is
/**
*Description - Used for report DOC_STD_3

*@created MZH 09 FEB 2010
*@lastUpdate VHA 14.05.2014
*@public
*@param parameter_0:  DMT_NUMBER
*/
  vpc_lang_id            PCS.PC_LANG.PC_LANG_ID%type;
  vrequired_total_amount number;
begin
  PCS.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  vpc_lang_id  := PCS.PC_I_LIB_SESSION.getuserlangid;

--Get the total amount for the required operation or work
  begin
    select sum(decode(nvl(ARC.ARC_OPTIONAL, nvl(RET.RET_OPTIONAL, 0) ), 0, POS.POS_NET_VALUE_INCL, 0) )
      into vrequired_total_amount
      from DOC_DOCUMENT DMT
         , DOC_POSITION POS
         , GCO_GOOD GOO_POS
         , ASA_RECORD_COMP ARC
         , ASA_RECORD_TASK RET
     where DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
       and GOO_POS.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
       and ARC.ASA_RECORD_COMP_ID(+) = POS.ASA_RECORD_COMP_ID
       and RET.ASA_RECORD_TASK_ID(+) = POS.ASA_RECORD_TASK_ID
       and DMT.DMT_NUMBER = parameter_0;
  exception
    when no_data_found then
      vrequired_total_amount  := 0;
  end;

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
         , round(decode(  ARE.ARE_DATE_END_SENDING
                        , null,(decode(  ARE.ARE_CONF_DATE_C
                                       , null,(  nvl(ARE.ARE_NB_DAYS_WAIT_MAX, nvl(ARE.ARE_NB_DAYS_WAIT, nvl(ARE.ARE_NB_DAYS_WAIT_COMP, 0) ) ) --Wait days
                                               + nvl(ARE.ARE_NB_DAYS, 0) --Repair days
                                               + nvl(ARE.ARE_NB_DAYS_CTRL, 0) --Ctrl days
                                               + nvl(ARE.ARE_NB_DAYS_SENDING, 0) --Sending days
                                               + nvl(ARE.ARE_NB_DAYS_EXP, 0) --EXP DAYS
                                          ) / 5
                                       , (ARE.ARE_CONF_DATE_C - DMT.DMT_DATE_DOCUMENT) / 7
                                      )
                              )
                        , (ARE.ARE_DATE_END_SENDING - DMT.DMT_DATE_DOCUMENT) / 7
                       )
                ) DUE_DATE
         , vrequired_total_amount REQUIRED_TOTAL_AMOUNT
         , POS.POS_NUMBER
         , POS.POS_SHORT_DESCRIPTION
         , POS.POS_NET_VALUE_INCL
         , POS.ASA_RECORD_TASK_ID
         , POS.ASA_RECORD_COMP_ID
         , POS.DIC_IMP_FREE1_ID
         , POS.DIC_IMP_FREE2_ID
         , POS.DIC_IMP_FREE3_ID
         , POS.DIC_IMP_FREE4_ID
         , POS.DIC_IMP_FREE5_ID
         , POS.DIC_POS_FREE_TABLE_1_ID
         , POS.DIC_POS_FREE_TABLE_2_ID
         , POS.DIC_POS_FREE_TABLE_3_ID
         , decode(POS.ASA_RECORD_COMP_ID, null, decode(POS.ASA_RECORD_TASK_ID, null, 0, 1), 2) OPER_COMP
         , nvl(ARC.ARC_OPTIONAL, nvl(RET.RET_OPTIONAL, 0) ) OPTIONAL
      from ASA_RECORD ARE
         , GCO_GOOD GOO
         , DOC_DOCUMENT DMT
         , DOC_GAUGE_STRUCTURED GAS
         , DOC_POSITION POS
         , GCO_GOOD GOO_POS
         , ASA_RECORD_COMP ARC
         , ASA_RECORD_TASK RET
     where ARE.GCO_ASA_TO_REPAIR_ID = GOO.GCO_GOOD_ID
       AND ARE.ASA_RECORD_ID = DMT.ASA_RECORD_ID
       AND DMT.DOC_GAUGE_ID = GAS.DOC_GAUGE_ID
       AND DMT.DOC_DOCUMENT_ID = POS.DOC_DOCUMENT_ID
       AND GOO_POS.GCO_GOOD_ID(+) = POS.GCO_GOOD_ID
       AND ARC.ASA_RECORD_COMP_ID(+) = POS.ASA_RECORD_COMP_ID
       AND RET.ASA_RECORD_TASK_ID(+) = POS.ASA_RECORD_TASK_ID
       AND DMT.DMT_NUMBER = parameter_0;
end RPT_DOC_STD_3_ASA_REPLY_SUB;
