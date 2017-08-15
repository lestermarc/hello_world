--------------------------------------------------------
--  DDL for Procedure RPT_PAC_THI_NO_VAT_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_PAC_THI_NO_VAT_SUB" (
  arefcursor in out CRYSTAL_CURSOR_TYPES.dualcursortyp
, procuser_lanid in PCS.PC_LANG.LANID%type
, parameter_0 in varchar2
)
/**
*Description

 Used for subreport RPT_PAC_THI_NO_VAT_SUB, subreport OF ACR_VAT_FORM_DET
*@created JLIU 06.JUNE.2009
*@lastUpdate  VHA 09.04.2013
*@public
*/
is
  vpc_lang_id pcs.pc_lang.pc_lang_id%type;   --user language id
begin
  pcs.PC_I_LIB_SESSION.setlanid(procuser_lanid);
  vpc_lang_id  := pcs.PC_I_LIB_SESSION.getuserlangid;

  open aRefCursor for
    select PER.PER_NAME
         , THI.THI_NO_TVA
      from PAC_PERSON PER
         , PAC_THIRD THI
     where PER.PAC_PERSON_ID = THI.PAC_THIRD_ID
       and PER.PAC_PERSON_ID = to_number(parameter_0);
end RPT_PAC_THI_NO_VAT_SUB;
