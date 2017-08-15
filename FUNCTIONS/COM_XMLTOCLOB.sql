--------------------------------------------------------
--  DDL for Function COM_XMLTOCLOB
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "COM_XMLTOCLOB" (xmldata IN XMLType) return CLOB
/**
 * Fonction COM_XMLTOCLOB
 * @version 1.0
 * @date 05/2005
 * @author spfister
 *
 * Copyright 1997-2005 Pro-Concept SA. Tous droits r�serv�s.
 *
 * Convertion d'un XMLType en clob avec sp�cification de l'encodage.
 * Cette m�thode est particuli�rement adapt�e pour une utilisation par un parseur
 * xml d'un client, car l'encodage par d�faut d'un document xml (XMLType) est
 * identique � celui de la base.
 *
 * Modifications:
 */
is
  result CLOB;
  tmpclob CLOB;
  strProlog VARCHAR(2000);
  nPos PLS_INTEGER;
begin
  if xmldata is null then
    return null;
  end if;

  result := xmldata.getCLobVal();

  -- Recherche du prologue
  nPos := dbms_lob.instr(result, '<?xml');
  if (nPos != 1) then
    -- Ajouter le prologue et retourner le clob
    return pc_jutils.get_XMLPrologDefault||Chr(10)||xmldata.getCLobVal();
  end if;

  -- Recherche de la fin du prologue
  nPos := dbms_lob.instr(result, '?>');
  if (nPos > 0) then
    nPos := nPos + 2;
    strProlog := dbms_lob.substr(result, nPos);
    if (Instr(strProlog, 'encoding') > 0) then
      -- Si l'encodage est d�fini, simplement retourner le clob
      return xmldata.getCLobVal();
    else
      -- Copie du reste du clob et ajout de l'encodage pour le retour
      dbms_lob.CreateTemporary(tmpClob, false, dbms_lob.CALL);
      dbms_lob.copy(tmpClob, result, dbms_lob.getlength(result)-nPos, 1, nPos);
      return pc_jutils.get_XMLPrologDefault||tmpCLob;
    end if;
  else
    -- Ajouter le prologue et retourner le clob
    return pc_jutils.get_XMLPrologDefault||Chr(10)||result;
  end if;

  exception
    when others then return null;
end;
