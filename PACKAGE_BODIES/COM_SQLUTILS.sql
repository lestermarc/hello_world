--------------------------------------------------------
--  DDL for Package Body COM_SQLUTILS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_SQLUTILS" 
IS
  -- Package state is needed only for the duration of one call to the server.
  -- It's not allocated to individual user in the UGA and the package work area
  -- can be reused. Each time the package is called, public variables are
  -- initialized to their default values or NULL.
  PRAGMA SERIALLY_REUSABLE;

  /**
   * Fonction interne de convertion de booléen en valeur entière
   * @param b  Booléen
   * @return 1 si le paramètres est TRUE sinon 0;
   */
  function p_bool2int(b BOOLEAN) return INTEGER is
  begin
    if b is null then return 0;
    elsif b then return 1;
    else return 0;
    end if;
  end;

  procedure ParseSQL(SQLCommand IN VARCHAR2,
    ReturnCode OUT BOOLEAN,
    ErrorMsg OUT NOCOPY VARCHAR2)
  is
    DML_Cursor INTEGER;
  begin
    ReturnCode := False;
    ErrorMsg := '';
    DML_Cursor := dbms_sql.open_cursor;
    begin
      dbms_sql.parse(DML_Cursor, SQLCommand, dbms_sql.NATIVE);
      ReturnCode := True;
    exception
      when others then
        ErrorMsg := sqlerrm;
    end;
    if dbms_sql.is_open(DML_Cursor) then
      dbms_sql.close_cursor(DML_Cursor);
    end if;
  end;


  function IsValidSQL(SQLCommand IN VARCHAR2)
    return INTEGER
  is
    strError VARCHAR2(2000);
  begin
    return com_sqlutils.IsValidSQL(SQLCommand, strError);
  end;
  function IsValidSQL(SQLCommand IN CLOB)
    return INTEGER
  is
    strError VARCHAR2(2000);
  begin
    return com_sqlutils.IsValidSQL(SQLCommand, strError);
  end;

  function IsValidSQL(SQLCommand IN VARCHAR2,
    ErrorMsg OUT NOCOPY VARCHAR2)
    return INTEGER
  is
    Result BOOLEAN;
  begin
    com_sqlutils.IsValidSQL(SQLCommand, Result, ErrorMsg);
    return p_bool2int(Result);
  end;
  function IsValidSQL(SQLCommand IN CLOB,
    ErrorMsg OUT NOCOPY VARCHAR2)
    return INTEGER
  is
    Result BOOLEAN;
  begin
    com_sqlutils.IsValidSQL(SQLCommand, Result, ErrorMsg);
    return p_bool2int(Result);
  end;

  procedure IsValidSQL(SQLCommand IN VARCHAR2,
    ReturnCode OUT BOOLEAN,
    ErrorMsg OUT NOCOPY VARCHAR2)
  is
  begin
    ParseSQL(SQLCommand, ReturnCode, ErrorMsg);
  end;
  procedure IsValidSQL(SQLCommand IN CLOB,
    ReturnCode OUT BOOLEAN,
    ErrorMsg OUT NOCOPY VARCHAR2)
  is
    strLargeSQL VARCHAR2(32767);
  begin
    strLargeSQL := SQLCommand;
    ParseSQL(strLargeSQL, ReturnCode, ErrorMsg);
  end;


END COM_SQLUTILS;
