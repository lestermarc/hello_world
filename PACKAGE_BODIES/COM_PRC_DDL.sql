--------------------------------------------------------
--  DDL for Package Body COM_PRC_DDL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_PRC_DDL" 
is

  object_does_not_exists exception;
  pragma exception_init(object_does_not_exists, -4043);

  object_already_exists exception;
  pragma exception_init(object_already_exists, -955);

  table_or_view_does_not_exists exception;
  pragma exception_init(table_or_view_does_not_exists, -942);

  index_does_not_exists exception;
  pragma exception_init(index_does_not_exists, -1418);

  invalid_identifier exception;
  pragma exception_init(invalid_identifier, -904);

  column_already_exists exception;
  pragma exception_init(column_already_exists, -1430);

  /**
  * Description
  *    Drop a package without exception in case of it does not exists
  */
  procedure DropPackage(iPackageName  in varchar2)
  is
  begin
    execute immediate 'DROP PACKAGE '||iPackageName;
  exception
    when object_does_not_exists then
      null;
  end DropPackage;

  /**
  * Description
  *    Drop a procedure without exception in case of it does not exists
  */
  procedure DropProcedure(iProcedureName  in varchar2)
  is
  begin
    execute immediate 'DROP PROCEDURE '||iProcedureName;
  exception
    when object_does_not_exists then
      null;
  end DropProcedure;

  /**
  * Description
  *    Drop a function without exception in case of it does not exists
  */
  procedure DropFunction(iFunctionName  in varchar2)
  is
  begin
    execute immediate 'DROP FUNCTION '||iFunctionName;
  exception
    when object_does_not_exists then
      null;
  end DropFunction;

  /**
  * Description
  *    Drop a table without exception in case of it does not exists
  */
  procedure DropTable(iTableName  in varchar2
                    , iCascade in boolean default false)
  is
  begin
    if iCascade then
      execute immediate 'DROP TABLE '||iTableName||' CASCADE CONSTRAINTS';
    else
      execute immediate 'DROP TABLE '||iTableName;
    end if;
  exception
    when table_or_view_does_not_exists then
      null;
  end DropTable;

  /**
  * Description
  *    Drop an index without exception in case of it does not exists
  */
  procedure DropIndex(iIndexName  in varchar2)
  is
  begin
    execute immediate 'DROP INDEX '||iIndexName;
  exception
    when index_does_not_exists then
      null;
  end DropIndex;

  /**
  * Description
  *    Drop a table constraint without exception in case of it does not exists
  */
  procedure DropConstraint(iTableName  in varchar2,
                           iConstraintName in varchar2)
  is
  begin
    execute immediate 'ALTER TABLE '||iTableName||' DROP CONSTRAINT '||iConstraintName;
  exception
    when table_or_view_does_not_exists then
      null;
    when invalid_identifier then
      null;
  end DropConstraint;

  /**
  * Description
  *    Drop a table constraint without exception in case of it does not exists
  */
  procedure DropColumn(iTableName  in varchar2,
                       iColumnName in varchar2)
  is
  begin
    execute immediate 'ALTER TABLE '||iTableName||' DROP COLUMN '||iColumnName;
  exception
    when table_or_view_does_not_exists then
      null;
    when invalid_identifier then
      null;
  end DropColumn;

  /**
  * Description
  *    Add a table column without exception in case of it already exists
  */
  procedure AddColumn(iFullStatement  in varchar2)
  is
  begin
    execute immediate iFullStatement;
  exception
    when column_already_exists then
      null;
  end AddColumn;

  /**
  * Description
  *    Add a table column without exception in case of it already exists
  */
  procedure AddIndex(iFullStatement  in varchar2)
  is
  begin
    execute immediate iFullStatement;
  exception
    when object_already_exists then
      null;
  end AddIndex;

end COM_PRC_DDL;
