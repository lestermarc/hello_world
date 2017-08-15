--------------------------------------------------------
--  DDL for Function CHECKLIST
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "CHECKLIST" (aValue in varchar2, aListRef in varchar2, aSep in varchar := ';', aDuplicates in number := 1)
  return number
/**
* Description
*    Teste l'existance des valeurs d'une liste dans une autre liste
* @created fp 06.12.2006
* @lastUpdate
* @public
* @param aValue      : liste de valeurs à tester
* @param aListRef    : liste de référence
* @param aSep        : séparateur (par défaut ;)
* @param aDuplicates : 1 (default) : autorise les doublons, 0 : contrôle qu'il n'y ait pas de doublons dans la liste de valeur
* @return 1 si OK, 0 si problème
*/
is
  i      pls_integer    := 1;
  vValue varchar2(4000);
  vError boolean        := false;
begin
  -- supression du séparateur si la valeur commence par un séparateur
  if substr(aValue, 1, length(aSep) ) = aSep then
    vValue  := substr(aValue, length(aSep) + 1);
  else
    vValue  := aValue;
  end if;

  -- Teste chaque valeur
  while ExtractLine(vValue, i, aSep) is not null
   and not vError loop
    vError  :=(instr(aSep || aListRef || aSep, aSep || ExtractLine(vValue, i, aSep) || aSep) = 0);

    if     not vError
       and aDuplicates = 0 then
      vError  :=(instr(aSep || vValue || aSep, aSep || ExtractLine(vValue, i, aSep) || aSep, 1, 2) > 0);
    end if;

    i       := i + 1;
  end loop;

  -- retour de la fonction
  if vError then
    return 0;
  else
    return 1;
  end if;
end checkList;
