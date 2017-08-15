--------------------------------------------------------
--  DDL for Function FAL_RAISE_EXCEPTION_MSG
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "FAL_RAISE_EXCEPTION_MSG" (aExceptionCode VARCHAR2
, aPackageName VARCHAR2) return VARCHAR2
is
  aStrSQL VARCHAR2(255);
  aExceptionValue VARCHAR2(4000);
  aCursor integer;
  ignore integer;
begin
  aStrSQL := ' BEGIN '
          || '   SELECT ' || aPackageName || '.' || aExceptionCode || 'Msg'
		      || '     INTO :aResult '
          || '     FROM DUAL;'
		      || ' END;';

  aCursor := DBMS_SQL.OPEN_CURSOR;
  DBMS_SQL.PARSE(aCursor, aStrSQL, DBMS_SQL.v7);
  DBMS_SQL.bind_variable(aCursor,':aResult',aExceptionValue,4000);
  ignore  := DBMS_SQL.execute(aCursor);
  DBMS_SQL.variable_value(aCursor,':aResult',aExceptionValue);
  DBMS_SQL.CLOSE_CURSOR(aCursor);

  return aExceptionValue;
exception
  when others then
    return PCS.PC_PUBLIC.TranslateWord('Erreur')
	         || ' ' || aPackageName || '.' || aExceptionCode || 'Msg'
      	   || ' ' || PCS.PC_PUBLIC.TranslateWord('inconnue!');
end;
