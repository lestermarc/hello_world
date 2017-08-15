--------------------------------------------------------
--  DDL for Package Body DOC_EDI_IMPORT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EDI_IMPORT" 
as
  procedure HeadProc(paTitle varchar2)
  -- Affichage titre et incrémente position titre
  is
  begin
    SYSREC.CNT_LEVEL  := SYSREC.CNT_LEVEL + 2;
    WRITELOG(lpad('-', SYSREC.CNT_LEVEL, '-') || 'Début ' || paTitle, 0);
  end;

  procedure FootProc(paTitle varchar2)
  -- Affichage titre et décrémente position titre
  is
  begin
    WRITELOG(lpad('-', SYSREC.CNT_LEVEL, '-') || 'Fin ' || paTitle, 0);
    SYSREC.CNT_LEVEL  := SYSREC.CNT_LEVEL - 2;
  end;

  procedure WriteParams
  -- Inscrit les paramètres dans le log
  is
    i DOC_EDI_TYPE_PARAM.DOC_EDI_TYPE_PARAM_ID%type;
  begin
    HeadProc('WRITEPARAMS');
    --
    WRITELOG('', 0);
    WRITELOG(PCS.PC_FUNCTIONS.TranslateWord('LISTE DES PARAMETRES :'), 0);
    WRITELOG('', 0);
    i  := DOC_EDI_FUNCTION.vParamsTable.first;

    while i is not null loop
      WRITELOG(DOC_EDI_FUNCTION.vParamsTable(i).DEP_NAME || ' : ' || DOC_EDI_FUNCTION.vParamsTable(i).DEP_VALUE, 0);
      i  := DOC_EDI_FUNCTION.vParamsTable.next(i);
    end loop;

    WRITELOG('', 0);
    --
    FootProc('WRITEPARAMS');
  end;

  procedure GetFirstToken(aLine in out varchar2, aSeparator in varchar2, aToken out varchar2, EoLine in out boolean)
  -- Recherche du premier token (PYV)
  is
    vSeparatorPos number;
    vLineLength   number;
  begin
    vSeparatorPos  := 0;
    vLineLength    := 0;
    EoLine         := true;
    aToken         := null;

    if aLine is not null then
      begin
        -- search the 1st occurence of aSeparator
        vSeparatorPos  := instr(aLine, aSeparator, 1, 1);
        -- Determine line length
        vLineLength    := length(aLine);

        if (vSeparatorPos = 0) then
          -- Separator hasn't been found
          -- assume this is the end of the line
          aToken  := aLine;
          aLine   := null;
        elsif(vSeparatorPos = vLineLength) then
          -- Separator is at then end of the line
          aToken  := substr(aLine, 1, vLineLength - 1);
          aLine   := null;
        else
          -- we have a token
          aToken  := substr(aLine, 1, vSeparatorPos - 1);
          aLine   := substr(aLine, vSeparatorPos + 1, vLineLength - vSeparatorPos);
          EoLine  := false;
        end if;
      end;
    end if;
  end GetFirstToken;

  function GetAToken(aLine in varchar2, aSeparator in varchar2, aTokenPos in number)
    return varchar2
  -- Recherche du x ieme token (PYV)
  is
    vLine        varchar2(32767);
    aToken       varchar2(32767);
    TokenCounter number;
    EoLine       boolean;
  begin
    vLine   := aLine;
    aToken  := null;

    for TokenCounter in 1 .. aTokenPos loop
      GetFirstToken(vLine, aSeparator, aToken, EoLine);
    end loop;

    --
    return aToken;
  end GetAToken;

  function GetATokenPos(aLine in varchar2, aSeparator in varchar2, aTokenPos in number)
    return varchar2
  -- Retourne le début de la position d'un aTokenPos
  is
    result   integer;   -- Position désirée
    cntPos   integer;   -- Position d'origine
    cntFound boolean;   -- Recherche aboutie
    cntLen   integer;   -- Longueur du string
    cntSep   integer;   -- Nombre de séparteurs détecté
  begin
    cntSep    := 0;
    cntPos    := 1;
    cntFound  := false;
    cntLen    := length(aLine);

    --
    if aTokenPos = 1 then
      result  := 1;
    else
      result  := 0;

      while(cntPos <= cntLen)
       and (cntFound = false) loop
        -- Séparateur trouvé
        if substr(aLine, cntPos, 1) = aSeparator then
          cntSep  := cntSep + 1;
        end if;

        -- Nombre de séparateurs détecté
        if cntSep = aTokenPos - 1 then
          cntFound  := true;
          -- Position à indiquer
          result    := cntPos + 1;
        end if;

        --
        cntPos  := cntPos + 1;
      end loop;
    end if;

    --
    return to_char(result);
  end GetATokenPos;

  function ParamExists(aParaList in TStructureArray, aPara in varchar2)
    return boolean
  -- Détermine si le paramètre existe
  is
    i     integer;   --Position dans l'array
    value boolean;   --Valeur de retour
  begin
    WRITELOG('*ParamExists', 0);
    --
    value  := false;
    --
    i      := aParaList.first;

    while i is not null loop
      if aParaList(i).value = aPara then
        value  := true;
        exit;
      end if;

      i  := aParaList.next(i);
    end loop;

    --
    return value;
  end;

  function GetValue(aParaList in TStructureArray, aDataList in TStructureArray, aPara in varchar2)
    return varchar2
  -- Retourne la valeur d'un paramètre en fonction du nom du paramètre
  is
    i     integer;   --Position dans l'array
    value varchar2(1000);   --Valeur du paramètre
  begin
    WRITELOG('*GetValue', 0);
    --
    value  := null;
    --
    i      := aParaList.first;

    while i is not null loop
      if aParaList(i).value = aPara then
        value  := aDataList(i).value;
        exit;
      end if;

      i  := aParaList.next(i);
    end loop;

    --
    WRITELOG('         Param = ' || aPara || ' value = ' || value, 0);
    --
    return value;
  end;

  function GetPosition(aParaList in TStructureArray, aDataList in TStructureArray, aPara in varchar2)
    return integer
  -- Retourne la position de début de valeur d'un paramètre
  is
    i     integer;   --Position dans l'array
    Posit integer;   --Valeur de la position
  begin
    WRITELOG('*GetPosition', 0);
    --
    Posit  := 0;
    --
    i      := aParaList.first;

    while i is not null loop
      if aParaList(i).value = aPara then
        Posit  := aDataList(i).position;
        exit;
      end if;

      i  := aParaList.next(i);
    end loop;

    --
    return Posit;
  end;

  procedure FillRec(aString varchar2, aList out TStructureArray)
  -- Remplissage d'un array en fonction l'une liste séparée par des ;
  is
    aPos     integer;   -- Position dans le string
    aPosit   integer;   -- Position de la valeur dans le string
    aIndex   integer;   -- Index d'array
    str      varchar2(1000);   -- Valeur d'array
    inString varchar2(2000);   -- String en entrée
  begin
    WRITELOG('*FillRec', 0);
    --
    aIndex    := 1;
    aPosit    := 0;
    str       := null;
    inString  := aString;
    --
    aList.delete;

    --
    -- Ajout ; à la fin
    if substr(inString, length(inString), 1) <> ';' then
      inString  := inString || ';';
    end if;

    --
    -- Parcours le string
    for aPos in 1 .. length(inString) loop
      -- Séparateur
      if substr(inString, aPos, 1) = ';' then
        aList(aIndex).value     := str;
        aList(aIndex).position  := aPosit + 1;   --Début de position de la valeur
        --
        WRITELOG('          ' || str, 0);
        --
        str                     := null;
        aIndex                  := aIndex + 1;   --Index suivant
        aPosit                  := aPos;   --Mémo début de position pour valeur suivante
      else
        str  := str || substr(inString, aPos, 1);
      end if;
    end loop;
  end;

  function GET_JOBID
    return DOC_EDI_TYPE.DOC_EDI_TYPE_ID%type
  -- Retourne la valeur du job_id
  is
  begin
    return SYSREC.JOB_ID;
  end;

  procedure SET_RETURN_VALUE(paRetVal integer)
  -- Attribution de la valeur de retour
  is
  begin
    SYSREC.RETURN_VALUE  := paRetVal;
  end;

  procedure WriteLog(aLine varchar2, aType_1 integer)
  -- Ajout dans le log de traitement
  -- Ce log sera repris par Delphi et ajouté au log en cours.
  -- L'inscription en Delphi se fera en fonction du type a_Type_1
  --
  -- aLine : ligne de texte
  -- aType_1 : 0  Texte uniquement (inscription en fonction d'une config)
  --           10 Texte uniquement (inscription dans tous les cas)
  --           50 Warning sans incrémentation du compteur warning
  --           59 Warning avec incrémentation du compteur warning
  --           90 Error sans incrémentation du compteur error
  --           99 Error avec incrémentation du compteur error
  is
    newId   number(12);
    TraceOk boolean;
  begin
    TraceOk  := true;

    --
    -- Inscription en fonction de la config
    if     not SysRec.TRACE_LOG
       and aType_1 = 0 then
      TraceOk  := false;
    end if;

    --
    --Inscription
    if TraceOk then
      -- Nouvelle Id de l'enregistrement
      select Init_id_seq.nextval
        into newId
        from dual;

      --
      insert into DOC_EDI_GENERATION_LOG
                  (DOC_EDI_GENERATION_LOG_ID
                 , DOC_EDI_IMPORT_JOB_ID
                 , DGL_LINE
                 , DGL_TYPE_1
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (newid
                 , SysRec.JOB_ID
                 , substr(aLine, 1, 250)
                 , aType_1
                 , sysdate
                 , pcs.PC_I_LIB_SESSION.GetUserIni
                  );
    end if;
  end;

  procedure PutError(aMessage in out varchar2, aJobDataId in number, aValue in varchar2, aLineNumber in integer, aRowPosition in integer)
  -- Message d'erreur dans le log avec le numéro de ligne, la ligne, le message avec colone
  -- Le message est reformatté en fonction de la position
  is
  begin
    HeadProc('PutError');

    --
    -- Erreur sur ligne effective
    if aJobDataId is not null then
      -- Si position de l'erreur
      if aRowPosition is not null then
        aMessage  := 'Pos' || ' : ' || aRowPosition || ' ' || aMessage;
      end if;

      --
      WRITELOG(' ', 10);
      WRITELOG(PCS.PC_FUNCTIONS.TranslateWord('Ligne') || ' : ' || to_char(aLineNumber, '9999'), 90);
      WRITELOG(aValue, 90);
      WRITELOG(aMessage, 99);
      WRITELOG(' ', 10);
    -- Erreur sans ligne effective (par exemple : ligne devant existant mais manquante)
    -- Seul le message est important, car il n'existe ni ligne ni position de référence
    else
      WRITELOG(' ', 10);
      WRITELOG(aMessage, 99);
      WRITELOG(' ', 10);
    end if;

    --
    FootProc('PutError');
  end;

  procedure PutWarning(aMessage in out varchar2, aJobDataId in number, aValue in varchar2, aLineNumber in integer, aRowPosition in integer)
  -- Message d'erreur dans le log avec le numéro de ligne, la ligne, le message avec colone
  -- Le message est reformatté en fonction de la position
  is
  begin
    HeadProc('PutWarning');

    --
    -- Erreur sur ligne effective
    if aJobDataId is not null then
      -- Si position de l'erreur
      if aRowPosition is not null then
        aMessage  := 'Pos' || ' : ' || aRowPosition || ' ' || aMessage;
      end if;

      --
      WRITELOG(' ', 10);
      WRITELOG(PCS.PC_FUNCTIONS.TranslateWord('Ligne') || ' : ' || to_char(aLineNumber, '9999'), 50);
      WRITELOG(aValue, 50);
      WRITELOG(aMessage, 59);
      WRITELOG(' ', 10);
    -- Erreur sans ligne effective (par exemple : ligne devant existant mais manquante)
    -- Seul le message est important, car il n'existe ni ligne ni position de référence
    else
      WRITELOG(' ', 10);
      WRITELOG(aMessage, 59);
      WRITELOG(' ', 10);
    end if;

    --
    FootProc('PutWarning');
  end;

  procedure DeleteInterfaceRecords(paInterfaceId in number)
  -- Suppression de toutes les enregistrements ajoutés dans l'interface et interface position
  -- dans le cas ou une erreur est survenue.
  is
  begin
    -- Test existence ID
    if paInterfaceId is not null then
      HeadProc('DeleteInterfaceRecords');

      --
      -- Suppression des interfaces positions
      delete from DOC_INTERFACE_POSITION
            where DOC_INTERFACE_ID = paInterfaceId;

      --
      -- Suppression de l'interface
      delete from DOC_INTERFACE
            where DOC_INTERFACE_ID = paInterfaceId;

      --
      FootProc('DeleteInterfaceRecords');
    end if;
  end;

  procedure UpdateInterfaceRecords(paInterfaceId in number)
  -- Mise à jour du status des enregistrements interfaces et interface position afin de prendre
  -- en compte les enregistrements au prochain traitement.
  is
  begin
    -- Test existence ID
    if paInterfaceId is not null then
      HeadProc('UpdateInterfaceRecords');

      --
      -- Mise à jour des positions
      update DOC_INTERFACE_POSITION
         set C_DOP_INTERFACE_STATUS = '02'
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_INTERFACE_ID = paInterfaceId;

      --
      -- Mise à jour de l'interface
      update DOC_INTERFACE
         set C_DOI_INTERFACE_STATUS = '02'
           , A_DATEMOD = sysdate
           , A_IDMOD = PCS.PC_I_LIB_SESSION.GetUserIni
       where DOC_INTERFACE_ID = paInterfaceId;

      --
      FootProc('UpdateInterfaceRecords');
    end if;
  end;

  -- Importation générale
  function Import(aJobId in number)
    return integer
  is
    SqlCommand    varchar2(2000);
    DynamicCursor integer;
    ErrorCursor   integer;
    result        integer;
    ParamF        varchar2(200);
  begin
    begin
      -- Positionnement de base pour l'affichage des procedures dans le log
      SysRec.CNT_LEVEL  := 0;
      -- Id du job recu en paramètre
      SysRec.JOB_ID     := aJobId;
      -- Recherche l'id du transfert attribué au job
      DOC_EDI_FUNCTION.GetJob(SysRec.JOB_ID, SysRec.DOC_EDI_TYPE_ID);
      -- Chargement des paramètres du transfert
      DOC_EDI_FUNCTION.FillParamsTable(SysRec.DOC_EDI_TYPE_ID);
      -- Chargement des valeurs des paramètres spéciaux
      DOC_EDI_FUNCTION.FillSpecialParams(SysRec.JOB_ID);
      -- Recherche de la fonction à appeler
      ParamF            := DOC_EDI_FUNCTION.GetParamValue('JOB_FUNCTION');
      -- Détermine si le log sera complet
      SysRec.TRACE_LOG  := nvl(DOC_EDI_FUNCTION.GetParamValue('TRACE_LOG'), '0') = '1';
      -- Entete de la fonction dans le log
      HeadProc('IMPORT (DOC_EDI_IMPORT)');
      --
      -- Inscription des paramètres
      WriteParams;
      -- Formatage de la commande
      SqlCommand        := 'BEGIN ' || ParamF || ';' || ' END;';
      DynamicCursor     := DBMS_SQL.open_cursor;
      -- Vérification
      DBMS_SQL.parse(dynamicCursor, SqlCommand, DBMS_SQL.native);
      -- Execution
      ErrorCursor       := DBMS_SQL.execute(dynamicCursor);
      -- Ferme le curseur
      DBMS_SQL.close_cursor(DynamicCursor);
      -- Cette valeur de retour est initialisé depuis les procédures d'importation.
      result            := SysRec.RETURN_VALUE;
    --
    -- Erreur technique non prévue
    exception
      when others then
        WRITELOG(sqlerrm, 99);
        result  := 9;
    end;

    --
    FootProc('IMPORT (DOC_EDI_IMPORT)');
    return result;
  end;
end;
