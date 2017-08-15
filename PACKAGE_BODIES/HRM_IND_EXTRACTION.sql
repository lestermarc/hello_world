--------------------------------------------------------
--  DDL for Package Body HRM_IND_EXTRACTION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HRM_IND_EXTRACTION" 
is

  function GetVF2Value_prnt(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in number) return varchar2
  is
   retour varchar2(255);
  begin
   select COM_VFIELDS_4_PRNT.GetVF2Value_prnt(aTableName, aFieldName, aIdFieldValue) into retour
   from dual;

   return retour;
  end GetVF2Value_prnt;

  function GetVF2Value_char(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in number) return varchar2
  is
   retour varchar2(255);
  begin
   select COM_VFIELDS_4_PRNT.GetVF2Value_char(aTableName, aFieldName, aIdFieldValue) into retour
   from dual;

   return retour;
  end GetVF2Value_char;

  function GetVF2Value_number(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in number) return number
  is
   retour number;
  begin
   select COM_VFIELDS_4_PRNT.GetVF2Value_number(aTableName, aFieldName, aIdFieldValue) into retour
   from dual;

   return retour;
  end GetVF2Value_number;

  function GetVF2Value_date(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in number) return date
  is
   retour date;
  begin
   select COM_VFIELDS_4_PRNT.GetVF2Value_date(aTableName, aFieldName, aIdFieldValue) into retour
   from dual;

   return retour;
  end GetVF2Value_date;

end hrm_ind_extraction;
