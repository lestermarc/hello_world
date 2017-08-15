--------------------------------------------------------
--  DDL for Package Body COM_VFIELDS_4_PRNT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_VFIELDS_4_PRNT" 
is

  /**
  * Description
  *   wrapper sur la fonction COM_VFIELDS.GetVFChar
  *   qui renvoie le résultat sous forme de string
  */
  function GetVFChar_prnt(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in varchar2) return varchar2
  is
    result COM_VFIELDS_VALUE.CVF_CHAR%type;
    fieldType COM_VFIELDS_VALUE.CVF_TYPE%type;
    idnum COM_VFIELDS_VALUE.CVF_REC_ID%type;

  begin

    idnum := TO_NUMBER(aIdFieldValue);

    result := COM_VFIELDS.GetVfChar(aTableName,aFieldName,idnum);

    return result;

  end GetVFChar_prnt;


  /**
  * Description
  *   wrapper sur la fonction COM_VFIELDS.GetVFNumber
  *   qui renvoie le résultat sous forme de string
  */
  function GetVFNumber_prnt(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in varchar2) return number
  is
    result COM_VFIELDS_VALUE.CVF_NUM%type;
    fieldType COM_VFIELDS_VALUE.CVF_TYPE%type;
    idnum COM_VFIELDS_VALUE.CVF_REC_ID%type;
  begin

    idnum := TO_NUMBER(aIdFieldValue);

    result := COM_VFIELDS.GetVfNumber(aTableName,aFieldName,idnum);

    return result;

  end GetVFNumber_prnt;


  /**
  * Description
  *   wrapper sur la fonction COM_VFIELDS.GetVFBoolean
  *   qui renvoie le résultat sous forme de string
  */
  function GetVFBoolean_prnt(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in varchar2) return number
  is
    result COM_VFIELDS_VALUE.CVF_BOOL%type;
    fieldType COM_VFIELDS_VALUE.CVF_TYPE%type;
    idnum COM_VFIELDS_VALUE.CVF_REC_ID%type;

  begin
    idnum := TO_NUMBER(aIdFieldValue);

    result := COM_VFIELDS.GetVfBoolean(aTableName,aFieldName,idnum);

    return result;

  end GetVFBoolean_prnt;


  /**
  * Description
  *   wrapper sur la fonction COM_VFIELDS.GetVFmemo
  *   qui renvoie le résultat sous forme de string
  */
  function GetVFMemo_prnt(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in varchar2) return varchar2
  is
    result COM_VFIELDS_VALUE.CVF_MEMO%type;
    fieldType COM_VFIELDS_VALUE.CVF_TYPE%type;
    idnum COM_VFIELDS_VALUE.CVF_REC_ID%type;

  begin
    idnum := TO_NUMBER(aIdFieldValue);

    result := COM_VFIELDS.GetVfMemo(aTableName,aFieldName,idnum);

    return result;

  end GetVFMemo_prnt;


  /**
  * Description
  *   wrapper sur la fonction COM_VFIELDS.GetVFDate
  *   qui renvoie le résultat sous forme de string
  */
  function GetVFDate_prnt(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in varchar2) return date
  is
    result COM_VFIELDS_VALUE.CVF_DATE%type;
    fieldType COM_VFIELDS_VALUE.CVF_TYPE%type;
    idnum COM_VFIELDS_VALUE.CVF_REC_ID%type;

  begin
    idnum := TO_NUMBER(aIdFieldValue);

    result := COM_VFIELDS.GetVfDate(aTableName,aFieldName,idnum);

    return result;

  end GetVFDate_prnt;

  /**
  * Description
  *    wrapper sur la fonction COM_VFIELDS.GetVF2Value
  *    Recherche des valeurs des champs virtuels 2ème type
  */
  function GetVF2Value_prnt(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in varchar2)
     return varchar2
  is
    idnum COM_VFIELDS_VALUE.CVF_REC_ID%type;
  begin
    idnum := TO_NUMBER(aIdFieldValue);
    return COM_VFIELDS.GetVF2Value(aTableName, aFieldName, idNum);
  end GetVF2Value_prnt;

  function GetVF2Value_char(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in varchar2)
     return varchar2
  is
    idnum COM_VFIELDS_VALUE.CVF_REC_ID%type;
  begin
    idnum := TO_NUMBER(aIdFieldValue);
    return COM_VFIELDS.GetVf2Value_char(aTableName, aFieldName, aIdFieldValue);
  end GetVF2Value_char;

  function GetVF2Value_number(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in varchar2)
     return number
  is
    idnum COM_VFIELDS_VALUE.CVF_REC_ID%type;
  begin
    idnum := TO_NUMBER(aIdFieldValue);
    return COM_VFIELDS.GetVf2Value_number(aTableName, aFieldName, aIdFieldValue);
  end GetVF2Value_number;

  function GetVF2Value_date(aTableName in varchar2, aFieldName in varchar2, aIdFieldValue in varchar2)
     return date
  is
    idnum COM_VFIELDS_VALUE.CVF_REC_ID%type;
  begin
    idnum := TO_NUMBER(aIdFieldValue);
    return COM_VFIELDS.GetVf2Value_date(aTableName, aFieldName, aIdFieldValue);
  end GetVF2Value_date;

end COM_VFIELDS_4_PRNT;
