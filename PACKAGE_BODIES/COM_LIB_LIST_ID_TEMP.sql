--------------------------------------------------------
--  DDL for Package Body COM_LIB_LIST_ID_TEMP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_LIB_LIST_ID_TEMP" 
is
  /**
  * Description
  *    Assigne la valeur donnée dans la variable donnée.
  */
  procedure setGlobalVar(iVarName in COM_LIST_ID_TEMP.LID_FREE_CHAR_1%type, iValue in COM_LIST_ID_TEMP.LID_FREE_MEMO_1%type)
  as
  begin
    clearGlobalVar(iVarName => iVarName);

    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
               , LID_FREE_CHAR_1
               , LID_FREE_MEMO_1
                )
         values (GetNewId
               , gcvGlobalVarCtx
               , upper(iVarName)
               , iValue
                );
  end setGlobalVar;

  /**
  * Description
  *    Retourne la valeur de la variable dont le nom est transmis en paramètre. Si pas trouvé, retourne la valeur par défaut transmise.
  */
  function getGlobalVar(iVarName in COM_LIST_ID_TEMP.LID_FREE_CHAR_1%type, iDefaultValue in COM_LIST_ID_TEMP.LID_FREE_MEMO_1%type default null)
    return COM_LIST_ID_TEMP.LID_FREE_MEMO_1%type
  as
    lValue COM_LIST_ID_TEMP.LID_FREE_MEMO_1%type;
  begin
    select LID_FREE_MEMO_1
      into lValue
      from COM_LIST_ID_TEMP
     where LID_CODE = gcvGlobalVarCtx
       and LID_FREE_CHAR_1 = upper(iVarName);

    return lValue;
  exception
    when no_data_found then
      return iDefaultValue;
  end getGlobalVar;

  /**
  * Description
  *    Supprime la variable dont le nom est transmis en paramètre.
  */
  procedure clearGlobalVar(iVarName in COM_LIST_ID_TEMP.LID_FREE_CHAR_1%type)
  as
  begin
    delete from COM_LIST_ID_TEMP
          where LID_CODE = gcvGlobalVarCtx
            and LID_FREE_CHAR_1 = upper(iVarName);
  end clearGlobalVar;
end COM_LIB_LIST_ID_TEMP;
