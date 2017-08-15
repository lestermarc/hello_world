--------------------------------------------------------
--  DDL for Package Body COM_PRC_LIST_ID_TEMP
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_PRC_LIST_ID_TEMP" 
is
  /**
  * procedure InsertIDList
  * Description
  *   Insertion d'un Id dans la table COM_LIST_ID_TEMP
  *
  */
  procedure InsertIDList(
    aID    in COM_LIST_ID_TEMP.COM_LIST_ID_TEMP_ID%type
  , aCode  in COM_LIST_ID_TEMP.LID_CODE%type
  , aDescr in COM_LIST_ID_TEMP.LID_DESCRIPTION%type
  )
  is
  begin
    insert into COM_LIST_ID_TEMP
                (COM_LIST_ID_TEMP_ID
               , LID_CODE
               , LID_DESCRIPTION
                )
         values (aID
               , aCode
               , aDescr
                );
  end InsertIDList;

  /**
  * procedure InsertList
  * Description
  *   Insertion d'une liste d'Id dans la table COM_LIST_ID_TEMP
  * @created fpe 30.08.2012
  * @param lListID : liste d'ID séparés par des ,
  * @param lCode   : contexte
  * @param lDescription : description (facultatif)
  */
  procedure InsertList(
    lListID    in varchar2
  , lCode  in COM_LIST_ID_TEMP.LID_CODE%type
  , lDescr in COM_LIST_ID_TEMP.LID_DESCRIPTION%type default null
  )
  is
  begin
    for ltplId in (select * from table(IdListToTable(lListId))) loop
      InsertIDList(ltplId.COLUMN_VALUE, lCode, lDescr);
    end loop;
  end;

  /**
  * procedure DeleteList
  * Description
  *   Suppression des ID d'un même code dans la table COM_LIST_ID_TEMP
  *
  */
  procedure DeleteList(
    lListID    in varchar2
  , lCode  in COM_LIST_ID_TEMP.LID_CODE%type default null)
  is
  begin
    for ltplId in (select * from table(IdListToTable(lListId))) loop
      delete from COM_LIST_ID_TEMP
        where COM_LIST_ID_TEMP_ID = ltplId.COLUMN_VALUE
          and LID_CODE = lCode or lCode is null;
    end loop;
  end DeleteList;

  /**
  * procedure DeleteIDList
  * Description
  *   Suppression des ID d'un même code dans la table COM_LIST_ID_TEMP
  *
  */
  procedure DeleteIDList(aCode in COM_LIST_ID_TEMP.LID_CODE%type)
  is
  begin
    delete from COM_LIST_ID_TEMP
          where LID_CODE = aCode;
  end DeleteIDList;

  /**
  * procedure ClearIDList
  * Description
  *   Suppression tous les enregistrements de la COM_LIST_ID_TEMP
  *
  */
  procedure ClearIDList(lCode  in COM_LIST_ID_TEMP.LID_CODE%type default null)
  is
  begin
    -- Effacement des enregistrements
    delete from COM_LIST_ID_TEMP where LID_CODE = lCode or lCode is null;
  end ClearIDList;
end COM_PRC_LIST_ID_TEMP;
