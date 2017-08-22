
  CREATE OR REPLACE FUNCTION "C_ITX"."CHECKEXISTINTABLE" (
  aValue      in varchar2
, aTable      in varchar2
, aColumn     in varchar2
, aCondition  in varchar2 := ''
, aSep        in varchar2 := ';'
, aDuplicates in number := 1
)
  return number
/**
* test123
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


  CREATE OR REPLACE FUNCTION "C_ITX"."CHECKLIST" (aValue in varchar2, aListRef in varchar2, aSep in varchar := ';', aDuplicates in number := 1)
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




  CREATE OR REPLACE FUNCTION "C_ITX"."COM_CURRENTCOMPANYALIAS" (aDIC_PC_EXTERNAL_ALIAS_ID in pcs.DIC_PC_EXTERNAL_ALIAS.DIC_PC_EXTERNAL_ALIAS_ID%TYPE)
   return VARCHAR2
/**
 * Fonction com_currentCompanyAlias
 * @version 1.0
 * Sert à la retrouver le nom de l'alias de la société relative
 * au schéma actuellement connecté et au dictionnaire des alias externe
 * PCS.DIC_PC_EXTERNAL_ALIAS.
 */
is
  vCurrentSchema varchar2(2000);
  vCount  integer;
  vAlias  pcs.pc_comp_external_alias.EXT_ALIAS_NAME%TYPE;
begin
  -- utilisation d'une variable, car on a parfois des erreurs lorsque l'on
  -- utilise directement cette fonction COM_CURRENTSCHEMA dans une cmd sql
  vCurrentSchema  := upper(COM_CURRENTSCHEMA);

  SELECT COUNT (*) into vCount
    FROM pcs.pc_scrip
   WHERE SCRDBOWNER = vCurrentSchema;

  if vCount > 1 then
    Return 'Error : Duplicates in pcs.pc_scrip for schema ' || vCurrentSchema;
  end if;


  SELECT COUNT (*) into vCount
     FROM pcs.pc_comp, pcs.pc_scrip
  WHERE pc_comp.pc_scrip_id = pc_scrip.pc_scrip_id and SCRDBOWNER = vCurrentSchema;

  if vCount > 1 then
    Return 'Error : Duplicates in pcs.pc_comp for schema ' || vCurrentSchema;
  end if;

  begin
    SELECT EXT_ALIAS_NAME into vAlias
    FROM PCS.PC_COMP_EXTERNAL_ALIAS ALI, PCS.PC_COMP COM, PCS.PC_SCRIP SCR
    WHERE   SCR.SCRDBOWNER = vCurrentSchema
        AND SCR.PC_SCRIP_ID = COM.PC_SCRIP_ID
        AND ALI.PC_COMP_ID = COM.PC_COMP_ID
        AND ALI.DIC_PC_EXTERNAL_ALIAS_ID = aDIC_PC_EXTERNAL_ALIAS_ID;

    Return vAlias;
  Exception
    when no_data_found then
        return 'Error : No alias found for schema ' || vCurrentSchema;
  end;
end;


  CREATE OR REPLACE FUNCTION "C_ITX"."COM_CURRENTCOMPID" return VARCHAR2 deterministic
/**
* function COM_CURRENTCOMPID
* Description
*   return the PC_COMP_ID of the PLSQL object owner
* @created fpe 28.04.2015
* @updated
* @public
* @return see decription
*/
is
  lResult PCS.PC_COMP.PC_COMP_ID%type;
begin
  select min(PC_COMP_ID)
    into lResult
    from PCS.PC_COMP COM, PCS.PC_SCRIP SCR
   where SCRDBOWNER = COM_CURRENTSCHEMA
     and COM.PC_SCRIP_ID = SCR.PC_SCRIP_ID;
  return lResult;

  exception
    when NO_DATA_FOUND then return null;
end COM_CURRENTCOMPID;


  CREATE OR REPLACE FUNCTION "C_ITX"."COM_CURRENTSCHEMA" return VARCHAR2
/**
 * Fonction COM_CURRENTSCHEMA
 * @version 1.0
 * @date 05/2005
 * @author spfister
 *
 * Copyright 1997-2005 Pro-Concept SA. Tous droits réservés.
 *
 * Sert à la retrouver le nom du schéma actuellement connecté.
 *
 * Modifications:
 */
is
  vSchema varchar2(2000);
  vPart1 varchar2(2000);
  vPart2 varchar2(2000);
  vDblink varchar2(2000);
  vPart1_type varchar2(2000);
  vObjectNr number;
begin
  dbms_utility.name_resolve('COM_CURRENTSCHEMA', 1,
      vSchema, vPart1, vPart2, vDblink, vPart1_type, vObjectNr);
  return vSchema;

  exception
    when others then return '';
end;




  CREATE OR REPLACE FUNCTION "C_ITX"."COM_XMLERRORDETAIL" (Error IN VARCHAR2) return XMLType
/**
 * OBSOLETE utiliser le public synonyme XmlErrorDetail
*/
IS
begin
  return XmlErrorDetail(iError => Error);
end;


  CREATE OR REPLACE FUNCTION "C_ITX"."COM_XMLTOCLOB" (xmldata IN XMLType) return CLOB
/**
 * Fonction COM_XMLTOCLOB
 * @version 1.0
 * @date 05/2005
 * @author spfister
 *
 * Copyright 1997-2005 Pro-Concept SA. Tous droits réservés.
 *
 * Convertion d'un XMLType en clob avec spécification de l'encodage.
 * Cette méthode est particulièrement adaptée pour une utilisation par un parseur
 * xml d'un client, car l'encodage par défaut d'un document xml (XMLType) est
 * identique à celui de la base.
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
      -- Si l'encodage est défini, simplement retourner le clob
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


  CREATE OR REPLACE FUNCTION "C_ITX"."FAL_GETFRACTIONALTIME" (TimeEntry VARCHAR2) RETURN FAL_LOT_PROGRESS_FOG.PFG_WORK_TIME%TYPE IS

-- Création FD le 23/10/2001
-- Permet de retourner une durée en heure et fraction d'heure suite à une entrée de type HH:MI
-- Cette fonction est utilisée dans le module du brouillard d'avancement des opérations pour le SQL*Loader
-- pour la société MECAPRO

  Result FAL_LOT_PROGRESS_FOG.PFG_WORK_TIME%TYPE;
  SeparatorPos Integer;
BEGIN

  SeparatorPos := INSTR(TimeEntry,':');

  if SeparatorPos <> 0 then
    Result := TO_NUMBER(SUBSTR(TimeEntry,1,SeparatorPos-1)) +
             (TO_NUMBER(SUBSTR(TimeEntry,SeparatorPos+1,LENGTH(TimeEntry) - SeparatorPos)) /60);
  else
    Result := NULL;
  end if;

  return Result;

  exception when OTHERS then return NULL;
END;




  CREATE OR REPLACE FUNCTION "C_ITX"."FAL_GETLOT_REFCOMPL_FROMTASKID" (TaskID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%TYPE) RETURN VARCHAR2 IS

-- Création FD le 26/09/2000
-- Permet de retourner la référence complète d'un lot selon l'ID d'une opération
-- Cette fonction est utilisée dans le module du brouillard d'avancement des opérations pour le SQL*Loader

  Result FAL_LOT.LOT_REFCOMPL%TYPE;
BEGIN
  SELECT LOT_REFCOMPL INTO Result
  FROM   FAL_LOT LOT,FAL_TASK_LINK TASK_LINK
  WHERE  TASK_LINK.FAL_SCHEDULE_STEP_ID = TaskID
  AND    LOT.FAL_LOT_ID = TASK_LINK.FAL_LOT_ID;

  RETURN Result;

  EXCEPTION WHEN NO_DATA_FOUND THEN RETURN NULL;
END;




  CREATE OR REPLACE FUNCTION "C_ITX"."FAL_GETLOT_REFCOMPL_RETECH" (TaskID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%TYPE) RETURN VARCHAR2 IS

-- Création FD le 17/05/2001
-- Permet de retourner la référence complète d'un lot selon l'ID d'une opération
-- Cette fonction est utilisée dans le module du brouillard d'avancement des opérations pour le SQL*Loader
-- pour l'interfaçage avec le système de RETECH

  Result FAL_LOT.LOT_REFCOMPL%TYPE;
BEGIN
  SELECT LOT_REFCOMPL INTO Result
  FROM   FAL_TASK_LINK TASK_LINK, FAL_LOT LOT
  WHERE  TO_NUMBER(SUBSTR(TASK_LINK.FAL_SCHEDULE_STEP_ID,-LEAST(LENGTH(TASK_LINK.FAL_SCHEDULE_STEP_ID),9),9)) = TaskID
  AND    LOT.FAL_LOT_ID = TASK_LINK.FAL_LOT_ID;

  RETURN Result;

  EXCEPTION WHEN NO_DATA_FOUND THEN RETURN NULL;
END;




  CREATE OR REPLACE FUNCTION "C_ITX"."FAL_GETPROCESSTRACK_SAMPLE" (ivInLine varchar2)
  return FAL_PFG_ENTRY_SYSTEMS.tProcessTrackTable pipelined
is
/**
   * Description
   *   Fonction d'exemple de conversion d'une ligne venant d'un barcode
   *   en données pour insertion dans le brouillard de suivi d'avancement
   *   (utilisé avec le nouveau système d'échange de données pour effectuer
   *   le travail fait auparavant par le fichier de contrôle du SQL Loader)
   * @version 2003
   * @author CLG 17.10.2011
   * @lastUpdate
   * @public
   * @param ivInLine          : Ligne à convertir
   * @return  le record à insérer dans le brouillard
*/
  ltRecProcessTrack FAL_PFG_ENTRY_SYSTEMS.tProcessTrackRecord;
begin
  ltRecProcessTrack.PFG_SELECTION        := 0;
  ltRecProcessTrack.PFG_LOT_REFCOMPL     := trim(substr(ivInLine, 1, 14) );
  ltRecProcessTrack.PFG_SEQ              := trim(substr(ivInLine, 15, 14) );
  ltRecProcessTrack.PFG_DIC_OPERATOR_ID  := trim(substr(ivInLine, 29, 10) );
  ltRecProcessTrack.PFG_DATE             := to_date(trim(substr(ivInLine, 39, 16) ), 'DD.MM.YYYY HH24:MI');
  ltRecProcessTrack.PFG_PRODUCT_QTY      := to_number(trim(substr(ivInLine, 55, 10) ) );
  ltRecProcessTrack.PFG_PT_REFECT_QTY    := to_number(trim(substr(ivInLine, 65, 15) ) );
  ltRecProcessTrack.PFG_CPT_REJECT_QFY   := to_number(trim(substr(ivInLine, 80, 15) ) );
  ltRecProcessTrack.PFG_DIC_REBUT_ID     := trim(substr(ivInLine, 95, 10) );
  pipe row(ltRecProcessTrack);
end;


  CREATE OR REPLACE FUNCTION "C_ITX"."FAL_GETSCS_STEP_NBR_FROMTASKID" (TaskID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%TYPE)
RETURN FAL_TASK_LINK.SCS_STEP_NUMBER%TYPE IS

-- Création FD le 26/09/2000
-- Permet de retourner la séquence d'une opération selon l'ID de l'opération
-- Cette fonction est utilisée dans le module du brouillard d'avancement des opérations pour le SQL*Loader

  Result FAL_TASK_LINK.SCS_STEP_NUMBER%TYPE;
BEGIN
  SELECT SCS_STEP_NUMBER INTO Result
  FROM   FAL_TASK_LINK TASK_LINK
  WHERE  TASK_LINK.FAL_SCHEDULE_STEP_ID = TaskID;

  RETURN Result;

  EXCEPTION WHEN NO_DATA_FOUND THEN RETURN NULL;
END;




  CREATE OR REPLACE FUNCTION "C_ITX"."FAL_GETSCS_STEP_NBR_RETECH" (TaskID FAL_TASK_LINK.FAL_SCHEDULE_STEP_ID%TYPE)
RETURN FAL_TASK_LINK.SCS_STEP_NUMBER%TYPE IS

-- Création FD le 17/05/2001
-- Permet de retourner la séquence d'une opération selon l'ID de l'opération
-- Cette fonction est utilisée dans le module du brouillard d'avancement des opérations pour le SQL*Loader
-- pour l'interfaçage avec le système de RETECH

  Result FAL_TASK_LINK.SCS_STEP_NUMBER%TYPE;
BEGIN
  SELECT SCS_STEP_NUMBER INTO Result
  FROM   FAL_TASK_LINK TASK_LINK
  WHERE  TO_NUMBER(SUBSTR(TASK_LINK.FAL_SCHEDULE_STEP_ID,-LEAST(LENGTH(TASK_LINK.FAL_SCHEDULE_STEP_ID),9),9)) = TaskID;

  RETURN Result;

  EXCEPTION WHEN NO_DATA_FOUND THEN RETURN NULL;
END;




  CREATE OR REPLACE FUNCTION "C_ITX"."FAL_RAISE_EXCEPTION_MSG" (aExceptionCode VARCHAR2
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




  CREATE OR REPLACE FUNCTION "C_ITX"."GETNEWID"
  return number
is
  vId PCS.PC_COMP.PC_COMP_ID%type;
begin
  select INIT_ID_SEQ.nextval
    into vId
    from dual;

  return vId;
end getNewId;


  CREATE OR REPLACE FUNCTION "C_ITX"."HRM_GET_RDV_SUMMARY" (DayDate IN DATE) RETURN VARCHAR2
/**
* Function HRM_Get_Rdv_Summary
 * @version 1.0
 * @date 11/2005
 * @author spfister
 *
 * Copyright 1997-2005 Pro-Concept SA. Tous droits réservés.
 *
 * Retourne le résumé des rendez-vous pour une date.
 *
 * Modifications:
 */
is
  result VARCHAR2(4000);
begin
  for tplSchedule in (
      select to_char(Sci_Start_Time,'HH24:MI')||'-'||to_char(Sci_End_Time,'HH24:MI')||Chr(10)||Scp_Comment rdv
      from pac_schedule_interro
      where scp_date = DayDate and hrm_person_id is not null and Sci_Start_Time is not null
      order by Sci_Start_Time) loop
    result := result || tplSchedule.rdv ||Chr(10);
  end loop;
  return result;
end;




  CREATE OR REPLACE FUNCTION "C_ITX"."HRM_ISLASTPAYINCURENTYEAR" (LastPayDate IN DATE)
  RETURN INTEGER
/**
 * @version 2.0
 * @date 12/2005
 * @author jsomers
 * @author spfister
 *
 * Copyright 1997-2005 Pro-Concept SA. Tous droits réservés.
 *
 * Tested in the where clause of v_hrm_emp_sum as no sums should be carried over the end of year.
 * Return 1(one) if lastPayDate is in the year defined by the active period, otherwise 0(zero)
 *
 * Modifications:
 * 20.12.2006: Remplacement du curseur par l'appel direct de la commande.
 */
IS
  result INTEGER;
BEGIN
  SELECT case when Trunc(Max(per_begin),'Y') = Trunc(LastPayDate,'Y') then 1 else 0 end INTO result
  FROM hrm_period
  WHERE per_act = 1;

  return result;

  exception
    when no_data_found then return 0;
END;




  CREATE OR REPLACE FUNCTION "C_ITX"."HRM_ISPERIODBEGINOFYEAR"
  RETURN INTEGER
/*
 * @version 2.0
 * @date 12/2005
 * @author jsomers
 * @author spfister
 *
 * Copyright 1997-2005 Pro-Concept SA. Tous droits réservés.
 *
 * Tested in the where clause of v_hrm_emp_sum as no sums should be carried
 * over the end of year.
 * Return 1(one) if active period is january, otherwise 0 (zero).
 *
 * Modifications:
 * 20.12.2006: Remplacement du curseur par l'appel direct de la commande.
 */
IS
  result INTEGER;
BEGIN
  SELECT case when To_Char(Max(per_begin),'MM') = '01' then 1 else 0 end into result
  FROM hrm_period
  WHERE per_act = 1;

  return result;

  exception
    when no_data_found then return 0;
END;




  CREATE OR REPLACE FUNCTION "C_ITX"."HRM_LAA_CODE" (
  vEmpId IN hrm_person.hrm_person_id%TYPE,
  vPayNum IN hrm_history_detail.his_pay_num%TYPE)
  return VARCHAR2
  RESULT_CACHE RELIES_ON (HRM_HISTORY_DETAIL,HRM_ELEMENTS_ROOT)
/**
 * Recherche du code LAA utilisé pour le calcul d'un décompte d'une personne.
 * @param vEmpId  Identifiant de l'employé.
 * @param vPayNum  Numéro du décompte calculé
 * @return le code LAA de l'employé pour le décompte, sinon null.
 *
 * @version 2.0
 * @date 12/2005
 * @author jsomers
 * @author spfister
 *
 * Copyright 1997-2010 SolvAxis SA. Tous droits réservés.
 *
 * Modification:
 * spfister 29.09.2010: Activation du cache du résultat.
 * 30.08.2006: Remplacement du curseur par l'appel direct de la commande.
 */
IS
  lv_result VARCHAR2(2);
BEGIN
  select Replace(HIS_PAY_VALUE, '"')
  into lv_result
  from HRM_HISTORY_DETAIL
  where HRM_EMPLOYEE_ID = vEmpId and HIS_PAY_NUM = vPayNum and
    HRM_ELEMENTS_ID = (select HRM_ELEMENTS_ID from HRM_ELEMENTS_ROOT
                       where C_ROOT_FUNCTION='LAA' and C_HRM_SAL_CONST_TYPE='2');
  return lv_result;

  exception
    when NO_DATA_FOUND then
      return '';
END;


  CREATE OR REPLACE FUNCTION "C_ITX"."HRM_PAYCOUNT" (vEmpId IN HRM_PERSON.HRM_PERSON_ID%TYPE,
  vPeriod IN DATE)
  RETURN INTEGER
/**
 * @version 2.0
 * @date 12/2005
 * @author jsomers
 * @author spfister
 *
 * Copyright 1997-2005 Pro-Concept SA. Tous droits réservés.
 *
 * Calculate the number of Pay calculated de finitively in a given Period for
 * a given employee.
 * Return the number of payroll calculated.
 * @param vEmpId  Identifier of the employee.
 *
 * Modifications:
 * 20.12.2006: Remplacement du curseur par l'appel direct de la commande.
 */
IS
  result INTEGER;
BEGIN
  SELECT count(*) INTO result
  FROM hrm_history
  WHERE hrm_employee_id = vEmpId AND hit_pay_period = vPeriod AND
    hit_definitive = 1;
  return result;

  exception
    when no_data_found then return 0;
END;




  CREATE OR REPLACE FUNCTION "C_ITX"."IMP_CHECKCCP" (pRefNumber varchar2)
  return number
is
  type TtblCCP is table of varchar2(20)
    index by binary_integer;

  vtblCCP TtblCCP;
  vCont   varchar2(20);
  vKey    varchar2(2);
begin
  select column_value
  bulk collect into vtblCCP
    from table(charListToTable(pRefNumber, '-') );

  if vtblCCP.count = 3 then
    vCont  := lpad(vtblCCP(1), 2, '0') || lpad(vtblCCP(2), 6, '0');
    vKey   := vtblCCP(3);
  elsif vtblCCP.count = 1 then
    vCont  := lpad(substr(vtblCCP(1), 1, length(vtblCCP(1) ) - 1), 8, '0');
    vKey   := substr(vtblCCP(1), length(vtblCCP(1) ), 1);
  else
    return 0;
  end if;

  if ACS_FUNCTION.Modulo10(vCont) = vKey then
    return 1;
  else
    return 0;
  end if;
end IMP_CheckCCP;


  CREATE OR REPLACE FUNCTION "C_ITX"."WEB_DOCUMENT_CONFIRM_PROC" (
    WEB_DOCUMENT_CONFIRM_PROC_ID DOC_DOCUMENT.DOC_DOCUMENT_ID%type
  , pEcoUserId in econcept.eco_users.eco_users_id%type
  , pMsg out varchar2
) RETURN NUMBER
IS
tmpVar doc_document.doc_document_id%type;
tmpStatus doc_document.C_DOCUMENT_STATUS%type;
tmpErrorCode varchar2(10);
tmpErrorMsg  varchar2(2000);
/******************************************************************************
   NAME:       WEB_DOCUMENT_CONFIRM_PROC
   PURPOSE: exemple de procédure appelée depuis ePrint, ici cpour confirmer un
   document logistique


******************************************************************************/
BEGIN
   pMsg := '<b>Document validé.</b>';

  select
     doc_document_id,
     C_DOCUMENT_STATUS
   into
     tmpVar,
     tmpStatus
   from
     doc_document
   where
     doc_document_id = WEB_DOCUMENT_CONFIRM_PROC_ID;

    if (tmpStatus <> '01' ) then
      pMsg := '<b>Document déjà validé.</b>';
      return WEB_FUNCTIONS.RETURN_WARNING;
    end if;

   doc_document_functions.CONFIRMDOCUMENT(tmpVar,tmpErrorCode,tmpErrorMsg,0);
   commit;

  pMsg := tmpErrorCode||' '||tmpErrorMsg;

   RETURN  WEB_FUNCTIONS.RETURN_WARNING;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       pMsg := '<b>Document non trouvé.</b>';
       return WEB_FUNCTIONS.RETURN_WARNING;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       pMsg := '<b>Document non trouvé.</b>';
       return WEB_FUNCTIONS.RETURN_FATAL;
END WEB_DOCUMENT_CONFIRM_PROC;


  CREATE OR REPLACE FUNCTION "C_ITX"."WEB_SHOP_SEARCH_STD" (
   searchtype    VARCHAR2,
   searchparam   VARCHAR2
)
   RETURN web_shop_functions_std.web_shop_search_ids_table PIPELINED
IS
/**
*
*  Author RRI ProConcept 2008 03 10
*
* Use : multi search type : recherche standard par référence ou description
* utilisée depuis ViewObject  : ViewShopSearch2Params

SELECT * FROM TABLE(web_shop_search_std('SN, '1001'))

SELECT * FROM TABLE(web_shop_search_std('DESCR', 'NIPPEL'))

SELECT * FROM TABLE(web_shop_search_std('REF', '154-016019'))
*/
   TYPE ref0 IS REF CURSOR;

   cur0      ref0;
   out_rec   web_shop_functions_std.web_shop_search_ids; -- := web_shop_functions_std.web_shop_search_ids (NULL, NULL);
   sqlstmt   VARCHAR2 (4000);

BEGIN
   IF    (searchparam IS NULL)
      OR (searchparam = '')
      OR (searchparam = '%')
      OR (searchparam = '*')
   THEN
      BEGIN
         sqlstmt := 'SELECT null, null from dual where rownum=0';

         OPEN cur0 FOR sqlstmt;

         LOOP
            FETCH cur0
             INTO out_rec.gco_good_id, out_rec.sem_value;

            EXIT WHEN cur0%NOTFOUND;
            PIPE ROW (out_rec);
         END LOOP;

         CLOSE cur0;

         RETURN;
      END;
   ELSIF (searchtype = 'SN') --recherche par numéro de série
   THEN
      BEGIN
         sqlstmt :=
               'SELECT '
            ||'   ENU.GCO_GOOD_ID,ENU.SEM_VALUE '
            ||' FROM '
            ||'   STM_ELEMENT_NUMBER ENU'
            ||'   ,GCO_GOOD G '
            ||'   ,WEB_GOOD W '
            || 'WHERE '
            || '  G.GCO_GOOD_ID=ENU.GCO_GOOD_ID AND '
            || '  G.GCO_GOOD_ID=W.GCO_GOOD_ID AND WGO_IS_ACTIVE=1 AND '
            || '  ENU.SEM_VALUE LIKE LIKE_PARAM (:SEM_VALUE) ORDER BY ENU.A_DATECRE DESC';

         OPEN cur0 FOR sqlstmt USING searchparam;

         LOOP
            FETCH cur0
             INTO out_rec.gco_good_id, out_rec.sem_value;

            EXIT WHEN cur0%NOTFOUND;
            PIPE ROW (out_rec);
         END LOOP;

         CLOSE cur0;

         RETURN;
      END;
   ELSIF (searchtype = 'REF') --recherche par référence
   THEN
      BEGIN
         sqlstmt :=
               'SELECT '
            || ' distinct G.GCO_GOOD_ID,null SEM_VALUE '
            || 'FROM '
            || ' GCO_GOOD G, '
            || ' WEB_GOOD W  '
            || 'WHERE '
            || ' G.gco_good_id=w.gco_good_id and wgo_is_active=1 and'
            || ' G.GOO_MAJOR_REFERENCE LIKE LIKE_PARAM(:GOO_MAJOR_REFERENCE)';

         OPEN cur0 FOR sqlstmt USING searchparam;

         LOOP
            FETCH cur0
             INTO out_rec.gco_good_id, out_rec.sem_value;

            EXIT WHEN cur0%NOTFOUND;
            PIPE ROW (out_rec);
         END LOOP;

         CLOSE cur0;

         RETURN;
      END;
   ELSIF (searchtype = 'DESCR')
   THEN
      BEGIN
         sqlstmt :=
               ' SELECT distinct GCO_GOOD_ID, SEM_VALUE from ('
            || ' SELECT distinct GCO_GOOD_ID, SEM_VALUE,goo_major_reference from ('
            || 'SELECT '
            || ' G.GCO_GOOD_ID,null SEM_VALUE, goo_major_reference '
            || ' FROM '
            || ' GCO_GOOD G  '
            || ' ,GCO_DESCRIPTION D   '
            || ' ,WEB_GOOD W   '
            || 'WHERE '
            || '  G.GCO_GOOD_ID = D.GCO_GOOD_ID '
            || '  AND G.GCO_GOOD_ID=W.GCO_GOOD_ID AND WGO_IS_ACTIVE=1'
            || '  AND D.C_DESCRIPTION_TYPE = ''01'''
            || '  AND (UPPER(D.DES_SHORT_DESCRIPTION) LIKE ''%''||UPPER(LIKE_PARAM (:DES_SHORT_DESCRIPTION))||''%''      '
            || '       OR  UPPER(D.DES_FREE_DESCRIPTION) LIKE ''%''||UPPER(LIKE_PARAM (:DES_SHORT_DESCRIPTION))||''%'')) '
            || ' ORDER BY GOO_MAJOR_REFERENCE )';

         OPEN cur0 FOR sqlstmt USING searchparam, searchparam;

         LOOP
            FETCH cur0
             INTO out_rec.gco_good_id, out_rec.sem_value;

            EXIT WHEN cur0%NOTFOUND;
            PIPE ROW (out_rec);
         END LOOP;

         CLOSE cur0;

         RETURN;
      END;
   ELSIF ((searchtype = 'INIT') OR (searchtype IS NULL))
   THEN
      BEGIN
         sqlstmt := 'SELECT 1 GCO_GOOD_ID, ''1'' SEM_VALUE FROM DUAL';

         OPEN cur0 FOR sqlstmt;

         LOOP
            FETCH cur0
             INTO out_rec.gco_good_id, out_rec.sem_value;

            EXIT WHEN cur0%NOTFOUND;
            PIPE ROW (out_rec);
         END LOOP;

         CLOSE cur0;

         RETURN;
      END;
   END IF;
END;


  CREATE OR REPLACE FUNCTION "C_ITX"."WFL_WHOAMI" return varchar2
is
  cOwner varchar2(30);
  cName varchar2(30);
  nLineNum number;
  cType Varchar2(30);
begin
   WFL_WhoCalledMe(cOwner,cName,nLineNum,cType);
   Return cOwner || '.' || cName;
end;

