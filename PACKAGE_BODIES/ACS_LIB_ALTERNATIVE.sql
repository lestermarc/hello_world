--------------------------------------------------------
--  DDL for Package Body ACS_LIB_ALTERNATIVE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACS_LIB_ALTERNATIVE" 
as
  /**
  * Description Recherche du no de compte synonyme
  **/
  function get_SynNumber(iv_AccNumber ACS_ACCOUNT.ACC_NUMBER%type)
    return ACS_ACCOUNT.ACC_NUMBER%type
  is
    lv_Result ACS_ACCOUNT.ACC_NUMBER%type;
  begin
    select max(SYN.SYN_NUMBER)
      into lv_Result
      from ACS_ALT_DESCRIPTION DES
         , ACS_SYNONYM_DATA SYN
         , ACS_ACCOUNT_CATEG CAT
         , ACS_FINANCIAL_ACCOUNT FIN
         , ACS_ACCOUNT
     where ACS_ACCOUNT.ACS_ACCOUNT_ID = SYN.ACS_ACCOUNT_ID
       and SYN.ACS_SYNONYM_DATA_ID = DES.ACS_SYNONYM_DATA_ID
       and ACS_ACCOUNT.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
       and ACS_ACCOUNT.ACS_ACCOUNT_CATEG_ID = CAT.ACS_ACCOUNT_CATEG_ID
       and ACS_ACCOUNT.ACC_NUMBER = iv_AccNumber;

    return lv_Result;
  end get_SynNumber;

  /**
  * Description Recherche de la description du compte dans pr?sentation alternative
  **/
  function get_AltDescr(iv_AccNumber ACS_ACCOUNT.ACC_NUMBER%type, in_PcLangId ACJ_TRADUCTION.PC_LANG_ID%type)
    return ACS_ALT_DESCRIPTION.ALT_DESCRIPTION%type
  is
    lv_Result ACS_ALT_DESCRIPTION.ALT_DESCRIPTION%type;
  begin
    select max(DES.ALT_DESCRIPTION)
      into lv_Result
      from ACS_ALT_DESCRIPTION DES
         , ACS_SYNONYM_DATA SYN
         , ACS_ACCOUNT_CATEG CAT
         , ACS_FINANCIAL_ACCOUNT FIN
         , ACS_ACCOUNT
     where ACS_ACCOUNT.ACS_ACCOUNT_ID = SYN.ACS_ACCOUNT_ID
       and SYN.ACS_SYNONYM_DATA_ID = DES.ACS_SYNONYM_DATA_ID
       and ACS_ACCOUNT.ACS_ACCOUNT_ID = FIN.ACS_FINANCIAL_ACCOUNT_ID
       and ACS_ACCOUNT.ACS_ACCOUNT_CATEG_ID = CAT.ACS_ACCOUNT_CATEG_ID
       and ACS_ACCOUNT.ACC_NUMBER = iv_AccNumber
       and DES.PC_LANG_ID = in_PcLangId;

    return lv_Result;
  end get_AltDescr;
end ACS_LIB_ALTERNATIVE;
