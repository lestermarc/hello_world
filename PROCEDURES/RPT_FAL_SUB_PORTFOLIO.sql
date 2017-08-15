--------------------------------------------------------
--  DDL for Procedure RPT_FAL_SUB_PORTFOLIO
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_FAL_SUB_PORTFOLIO" (
  arefcursor        in out crystal_cursor_types.dualcursortyp
, procuser_lanid    in     pcs.pc_lang.lanid%type
, proccompany_owner in     pcs.pc_scrip.scrdbowner%type
, proccompany_name  in     pcs.pc_comp.com_name%type
, parameter_0       in     varchar2
)
is
/**
* Description - Used in report FAL_SUB_PORTFOLIO

* Stored procedure used by the report FAL_SUB_PORTFOLIO
* @created VHA 26 JUNE 2013
* Modified
* lastUpdate
* @param parameter_0    Job_id (COM_LIST)
*/
  vpc_lang_id     pcs.pc_lang.pc_lang_id%type := null;
  vcom_logo_large pcs.pc_comp.com_logo_large%type := null;
  vcom_logo_small pcs.pc_comp.com_logo_small%type := null;
  vcom_vatno      pcs.pc_comp.com_vatno%type := null;
  vcom_phone      pcs.pc_comp.com_phone%type := null;
  vcom_fax        pcs.pc_comp.com_fax%type := null;
  vcom_web        pcs.pc_comp.com_telex%type := null;
  vcom_email      pcs.pc_comp.com_email%type := null;
  vcom_descr      pcs.pc_comp.com_descr%type := null;
  vcom_socialname pcs.pc_comp.com_socialname%type := null;
  vcom_ide        pcs.pc_comp.com_ide%type := null;
  vcom_adr        varchar2(4000) := null;
begin
  pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  vpc_lang_id  := pcs.PC_I_LIB_SESSION.getuserlangid;

  if  (proccompany_name is not null) then
      select com.com_logo_large
           , com.com_logo_small
           , com.com_vatno
           , com.com_descr
           , com.com_adr || chr(13) || com.com_zip || ' - ' || com.com_city
           , com.com_phone
           , com.com_fax
           , com.com_telex
           , com.com_email
           , com.com_socialname
           , com.com_ide
        into vcom_logo_large
           , vcom_logo_small
           , vcom_vatno
           , vcom_descr
           , vcom_adr
           , vcom_phone
           , vcom_fax
           , vcom_web
           , vcom_email
           , vcom_socialname
           , vcom_ide
        from pcs.pc_comp com
       where com.com_name = proccompany_name;
   end if;

  open arefcursor for
    select FTL.FAL_SCHEDULE_STEP_ID
         , null FAL_TASK_LINK_PROP_ID
         , vcom_phone com_phone
         , vcom_fax com_fax
         , vcom_web com_web
         , vcom_email com_email
         , vcom_socialname com_socialname
         , vcom_logo_large com_logo_large
         , vcom_logo_small com_logo_small
         , vcom_vatno com_vatno
         , vcom_descr com_descr
         , vcom_adr com_adr
         , vcom_ide com_ide
         , PER.PER_NAME
         , rpt_functions.getpacadr(PER.PAC_PERSON_ID, 0) ADDRESS
         , rpt_functions.getpacadr(PER.PAC_PERSON_ID, 1) ZIP
         , rpt_functions.getpacadr(PER.PAC_PERSON_ID, 2) CITY
         , rpt_functions.getpacadr(PER.PAC_PERSON_ID, 3) STATE
         , LOT.LOT_REFCOMPL
         , FTL.SCS_STEP_NUMBER
         , nvl(FTL.TAL_SUBCONTRACT_SELECT, 0) LID_SELECTION
         , FTL.GCO_GCO_GOOD_ID
         , GOO.GOO_MAJOR_REFERENCE
         , GOO.GOO_SECONDARY_REFERENCE
         , GCO_FUNCTIONS.GetDescription2(GOO.GCO_GOOD_ID, vpc_lang_id, 1, '01') DES_SHORT_DESCRIPTION
         , GOO.DIC_UNIT_OF_MEASURE_ID
         , GOO.GOO_NUMBER_OF_DECIMAL
         , FTL.TAL_END_PLAN_DATE
         , FTL.TAL_PCST_DATE
         , FTL.TAL_PCST_NUMBER
         , FTL.TAL_PCST_PRINT_DATE
         , FTL.TAL_CONFIRM_DATE
         , FTL.TAL_CONFIRM_DESCR
         , FTL.PAC_SUPPLIER_PARTNER_ID
         , FTL.TAL_CST_EXIST
         , FTL.TAL_CST_DATE
         , TAS.TAS_REF
         , FTL.SCS_AMOUNT
         , FTL.SCS_QTY_REF_AMOUNT
         , FTL.SCS_DIVISOR_AMOUNT
         , FTL.TAL_PLAN_QTY
         , FTL.TAL_DUE_AMT
         , FTL.TAL_AMT_BALANCE
         , decode(FTL.TAL_AVALAIBLE_QTY, 0, FTL.TAL_DUE_QTY - nvl(FTL.TAL_SUBCONTRACT_QTY, 0), FTL.TAL_AVALAIBLE_QTY) TAL_AVALAIBLE_QTY
         , FTL.TAL_SUBCONTRACT_QTY
         , FTL.TAL_RELEASE_QTY
         , FTL.TAL_DUE_QTY
         , DES1.DES_SHORT_DESCRIPTION PPS_TOOLS1
         , DES2.DES_SHORT_DESCRIPTION PPS_TOOLS2
         , FTL.FAL_LOT_ID
         , LOT.DOC_RECORD_ID
         , LOT.FAL_JOB_PROGRAM_ID
         , LOT.FAL_ORDER_ID
         , GCO_FUNCTIONS.getMajorReference(LOT.GCO_GOOD_ID) LOT_ARTICLE
         , LIS.LIS_JOB_ID
         , LIS.LIS_CODE
         , LIS.LIS_ID_1
      from COM_LIST LIS
         , FAL_TASK_LINK FTL
         , FAL_LOT LOT
         , FAL_TASK TAS
         , FAL_JOB_PROGRAM JOP
         , FAL_ORDER ORD
         , GCO_GOOD GOO
         , PAC_PERSON PER
         , GCO_DESCRIPTION DES1
         , GCO_DESCRIPTION DES2
     where LIS.LIS_ID_1 = FTL.FAL_SCHEDULE_STEP_ID
       and LIS.LIS_CODE = 'PCST_BATCH'
       and LIS.LIS_JOB_ID = to_number(parameter_0)
       and LOT.FAL_LOT_ID = FTL.FAL_LOT_ID
       and TAS.FAL_TASK_ID = FTL.FAL_TASK_ID
       and LOT.FAL_JOB_PROGRAM_ID = JOP.FAL_JOB_PROGRAM_ID
       and LOT.FAL_ORDER_ID = ORD.FAL_ORDER_ID
       and GOO.GCO_GOOD_ID = FTL.GCO_GCO_GOOD_ID
       and PER.PAC_PERSON_ID = FTL.PAC_SUPPLIER_PARTNER_ID
       and FTL.PPS_TOOLS1_ID = DES1.GCO_GOOD_ID(+)
       and FTL.TAL_PCST_NUMBER is not null
       and DES1.PC_LANG_ID(+) = vpc_lang_id
       and DES1.C_DESCRIPTION_TYPE(+) = '01'
       and FTL.PPS_TOOLS2_ID = DES2.GCO_GOOD_ID(+)
       and DES2.PC_LANG_ID(+) = vpc_lang_id
       and DES2.C_DESCRIPTION_TYPE(+) = '01'
    union
    select null FAL_SCHEDULE_STEP_ID
         , FTL.FAL_TASK_LINK_PROP_ID
         , vcom_phone com_phone
         , vcom_fax com_fax
         , vcom_web com_web
         , vcom_email com_email
         , vcom_socialname com_socialname
         , vcom_logo_large com_logo_large
         , vcom_logo_small com_logo_small
         , vcom_vatno com_vatno
         , vcom_descr com_descr
         , vcom_adr com_adr
         , vcom_ide com_ide
         , PER.PER_NAME
         , rpt_functions.getpacadr(PER.PAC_PERSON_ID, 0) ADDRESS
         , rpt_functions.getpacadr(PER.PAC_PERSON_ID, 1) ZIP
         , rpt_functions.getpacadr(PER.PAC_PERSON_ID, 2) CITY
         , rpt_functions.getpacadr(PER.PAC_PERSON_ID, 3) STATE
         , LOT.C_PREFIX_PROP || '-' || LOT.LOT_NUMBER LOT_NUMBER
         , FTL.SCS_STEP_NUMBER
         , nvl(FTL.TAL_SUBCONTRACT_SELECT, 0) LID_SELECTION
         , FTL.GCO_GOOD_ID
         , GOO.GOO_MAJOR_REFERENCE
         , GOO.GOO_SECONDARY_REFERENCE
         , GCO_FUNCTIONS.GetDescription2(GOO.GCO_GOOD_ID, vpc_lang_id, 1, '01') DES_SHORT_DESCRIPTION
         , GOO.DIC_UNIT_OF_MEASURE_ID
         , GOO.GOO_NUMBER_OF_DECIMAL
         , FTL.TAL_END_PLAN_DATE
         , FTL.TAL_PCST_DATE
         , FTL.TAL_PCST_NUMBER
         , FTL.TAL_PCST_PRINT_DATE
         , FTL.TAL_CONFIRM_DATE
         , FTL.TAL_CONFIRM_DESCR
         , FTL.PAC_SUPPLIER_PARTNER_ID
         , 0   --FTL.TAL_CST_EXIST
         , null   --FTL.TAL_CST_DATE
         , TAS.TAS_REF
         , FTL.SCS_AMOUNT
         , FTL.SCS_QTY_REF_AMOUNT
         , FTL.SCS_DIVISOR_AMOUNT
         , 0   --FTL.TAL_PLAN_QTY
         , FTL.TAL_DUE_AMT
         , 0   --FTL.TAL_AMT_BALANCE
         , FTL.TAL_DUE_QTY TAL_AVALAIBLE_QTY
         , FTL.TAL_SUBCONTRACT_QTY
         , 0   --FTL.TAL_RELEASE_QTY
         , FTL.TAL_DUE_QTY
         , DES1.DES_SHORT_DESCRIPTION PPS_TOOLS1
         , DES2.DES_SHORT_DESCRIPTION PPS_TOOLS2
         , FTL.FAL_LOT_PROP_ID
         , LOT.DOC_RECORD_ID
         , null
         , null
         , GCO_FUNCTIONS.getMajorReference(LOT.GCO_GOOD_ID) LOT_ARTICLE
         , LIS.LIS_JOB_ID
         , LIS.LIS_CODE
         , LIS.LIS_ID_1
      from COM_LIST LIS
         , FAL_TASK_LINK_PROP FTL
         , FAL_LOT_PROP LOT
         , FAL_TASK TAS
         , GCO_GOOD GOO
         , PAC_PERSON PER
         , GCO_DESCRIPTION DES1
         , GCO_DESCRIPTION DES2
     where LIS.LIS_ID_1 = FTL.FAL_TASK_LINK_PROP_ID
       and LIS.LIS_CODE = 'PCST_PROP'
       and LIS.LIS_JOB_ID = to_number(parameter_0)
       and LOT.FAL_LOT_PROP_ID = FTL.FAL_LOT_PROP_ID
       and TAS.FAL_TASK_ID = FTL.FAL_TASK_ID
       and GOO.GCO_GOOD_ID = FTL.GCO_GOOD_ID
       and PER.PAC_PERSON_ID = FTL.PAC_SUPPLIER_PARTNER_ID
       and FTL.PPS_TOOLS1_ID = DES1.GCO_GOOD_ID(+)
       and FTL.TAL_PCST_NUMBER is not null
       and DES1.PC_LANG_ID(+) = vpc_lang_id
       and DES1.C_DESCRIPTION_TYPE(+) = '01'
       and FTL.PPS_TOOLS2_ID = DES2.GCO_GOOD_ID(+)
       and DES2.PC_LANG_ID(+) = vpc_lang_id
       and DES2.C_DESCRIPTION_TYPE(+) = '01';
end RPT_FAL_SUB_PORTFOLIO;
