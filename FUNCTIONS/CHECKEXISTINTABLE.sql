--------------------------------------------------------
--  DDL for Function CHECKEXISTINTABLE
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "CHECKEXISTINTABLE" (
  aValue      in varchar2
, aTable      in varchar2
, aColumn     in varchar2
, aCondition  in varchar2 := ''
, aSep        in varchar2 := ';'
, aDuplicates in number := 1
)
  return number
/**
* function checkExistInTable
* Description
*   Test l'existance d'une liste de valeur dans une table
* @created fp 06.12.2006
* @lastUpdate
* @public
* @param  aValue : liste de valeur
* @param  aTable : nom de la table
* @param  aColumn : nom de la colonne à tester
* @param  aCondition : condition de filtre sur la table
* @param  aSep : séparateur de la liste de valeur (par défaut ;)
* @param  aDuplicates : 1 (default) : autorise les doublons, 0 : contrôle qu'il n'y ait pas de doublons dans la liste de valeur
* @return 1 si OK, 0 si problème
*/
is
  i      pls_integer     := 1;
  vValue varchar2(4000);
  vError boolean         := false;
  vTest  varchar2(100);
  vSql   varchar2(20000);
begin
  -- supression du séparateur si la valeur commence par un séparateur
  if substr(aValue, 1, length(aSep) ) = aSep then
    vValue  := substr(aValue, length(aSep) + 1);
  else
    vValue  := aValue;
  end if;

  vSql  := 'SELECT ' || aColumn || ' FROM ' || aTable || ' WHERE ' || aColumn || '= :VALUE ';

  if aCondition is not null then
    vSql  := vSql || ' AND ' || aCondition;
  end if;

  -- Teste chaque valeur
  while ExtractLine(vValue, i, aSep) is not null
   and not vError loop
    begin
      execute immediate vSql
                   into vTest
                  using trim(both ' ' from ExtractLine(vValue, i, aSep));
    exception
      when no_data_found then
        vError  := true;
      when too_many_rows then
        null;
    end;

    -- test qu'on ait pas deux fois la valeur
    if     not vError
       and aDuplicates = 0 then
      vError  :=(instr(aSep || vValue || aSep, aSep || ExtractLine(vValue, i, aSep) || aSep, 1, 2) > 0);
    end if;

    i  := i + 1;
  end loop;

  -- retour de la fonction
  if vError then
    return 0;
  else
    return 1;
  end if;
end checkExistInTable;
