--------------------------------------------------------
--  DDL for Procedure RPT_THI_NO_VAT_SUB
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "RPT_THI_NO_VAT_SUB" (
  arefcursor in out CRYSTAL_CURSOR_TYPES.dualcursortyp
, parameter_0 in varchar2
)
/**
*Description

 Used for report the sub report of ACR_VAT_FORM_DET
*@created JLIU 06.JUNE.2009
*@lastUpdate  VHA 09.04.2013
*@public
*/
is
  vpc_lang_id pcs.pc_lang.pc_lang_id%type;   --user language id
begin
  open aRefCursor for
    select PER.PER_NAME
         , THI.THI_NO_TVA
      from PAC_PERSON PER
         , PAC_THIRD THI
     where PER.PAC_PERSON_ID = THI.PAC_THIRD_ID
       and PER.PAC_PERSON_ID = to_number(parameter_0);
end RPT_THI_NO_VAT_SUB;
