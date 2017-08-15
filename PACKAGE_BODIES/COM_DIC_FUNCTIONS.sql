--------------------------------------------------------
--  DDL for Package Body COM_DIC_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_DIC_FUNCTIONS" 
IS

  function getDicoDescr(aTable varchar2,
                        aCode varchar2,
                        LangId IN pcs.pc_lang.pc_lang_id%TYPE default pcs.PC_I_LIB_SESSION.GetUserLangId)
                         return dico_Description.dit_descr%type deterministic
  is
   tmp dico_Description.dit_descr%type;
  begin
    Select dit_descr into tmp
    from dico_description
    where dit_table =  aTable
    and dit_code = aCode
    and pc_lang_id = LangId;
    return tmp;
    exception
      when others then return '';
  end getDicoDescr;

  function getDicoDescr2(aTable varchar2,
                         aCode varchar2,
                         LangId IN pcs.pc_lang.pc_lang_id%TYPE default pcs.PC_I_LIB_SESSION.GetUserLangId)
                          return dico_Description.dit_descr2%type deterministic
  is
   tmp dico_Description.dit_descr2%type;
  begin
    Select dit_descr2 into tmp
    from dico_description
    where dit_table =  aTable
    and dit_code = aCode
    and pc_lang_id = LangId;
    return tmp;
    exception
      when others then return '';
  end getDicoDescr2;


end COM_DIC_FUNCTIONS;
