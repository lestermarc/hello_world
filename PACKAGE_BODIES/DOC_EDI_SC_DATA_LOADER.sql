--------------------------------------------------------
--  DDL for Package Body DOC_EDI_SC_DATA_LOADER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EDI_SC_DATA_LOADER" 
is
  cBUFFER_SIZE constant pls_integer := 4000;

  /**
  * procedure pArchiveFile
  * Description
  *    Transfert du fichier dans le répertoire EDI_STEPCOM_DIR_BACKUP
  * @created fp 27.11.2007
  * @lastUpdate
  * @private
  * @param aFileName : fichier à transférer
  */
  procedure pArchiveFile(aFileName in DOC_EDI_IMPORT_JOB.DEJ_FILENAME%type)
  is
  begin
    null;
  end pArchiveFile;

  /**
  * procedure pCreateJobHeader
  * Description
  *   Création de l'entête du job
  * @created fp 27.11.2007
  * @lastUpdate
  * @private
  * @param aJobId : id de l'entête à créer
  * @param aFileName : Nom du fichier
  */
  procedure pCreateJobHeader(aJobId in DOC_EDI_IMPORT_JOB.DOC_EDI_IMPORT_JOB_ID%type, aFileName in DOC_EDI_IMPORT_JOB.DEJ_FILENAME%type)
  is
  begin
    insert into DOC_EDI_IMPORT_JOB
                (DOC_EDI_IMPORT_JOB_ID
               , DOC_EDI_TYPE_ID
               , C_EDI_JOB_STATUS
               , DEJ_DESCRIPTION
               , DEJ_INTEGRATION_DATE
               , DEJ_FILENAME
               , A_DATECRE
               , A_IDCRE
                )
         values (aJobId
               , (select DOC_EDI_TYPE_ID
                    from DOC_EDI_TYPE
                   where DET_NAME = 'SC_BEST')
               , 'IMPORTED'
               , 'Stepcom XBest3c V4'
               , trunc(sysdate)
               , aFiLeName
               , sysdate
               , PCS.PC_I_LIB_SESSION.getUserIni
                );
  end pCreateJobHeader;

  /**
  * procedure pInsertLine
  * Description
  *   Insertion d'une ligne et décodage "primitif" de cette dernière
  * @created fp 27.11.2007
  * @lastUpdate
  * @private
  * @param aJobId : Id du job
  * @param aLine : contenu de la lugne dans le fichier
  * @param aNoLine : numéro de ligne
  * @param aKey1 : clef de jointure 1er niveau
  * @param aKey2 : clef de jointure 2e niveau
  */
  procedure pInsertLine(
    aJobId  in     DOC_EDI_IMPORT_JOB.DOC_EDI_IMPORT_JOB_ID%type
  , aLine   in     DOC_EDI_IMPORT_JOB_DATA.DID_VALUE%type
  , aNoLine in     DOC_EDI_IMPORT_JOB_DATA.DID_LINE_NUMBER%type
  , aKey1   in out DOC_EDI_IMPORT_JOB_DATA.DID_JOIN_KEY%type
  , aKey2   in out DOC_EDI_IMPORT_JOB_DATA.DID_JOIN_KEY%type
  )
  is
    vTplLine DOC_EDI_IMPORT_JOB_DATA%rowtype;
  begin
    if trim(aLine) is not null then
      vTplLine.DOC_EDI_IMPORT_JOB_DATA_ID  := getNewId;
      vTplLine.C_EDI_JOB_DATA_STATUS       := 'OK';
      vTplLine.DID_TAG                     := ExtractLine(aLine, 1, '#');

      -- affectation des clef de jointures
      case
        when vTplLine.DID_TAG in('INFREC') then
          aKey1                  := vTplLine.DOC_EDI_IMPORT_JOB_DATA_ID;
          vTplLine.DID_JOIN_KEY  := aKey1;
        when vTplLine.DID_TAG in('HADR01', 'HPAY01', 'DDET01') then
          aKey2                  := vTplLine.DOC_EDI_IMPORT_JOB_DATA_ID;
          vTplLine.DID_JOIN_KEY  := aKey1;
        when vTplLine.DID_TAG in
              ('HREF02', 'HCTI01', 'DDET01', 'DAPI01', 'DITD01', 'DMES01', 'DIQT01', 'DDAT01', 'DBET01', 'DTXT01', 'DIPR01', 'DREF01', 'DPLA01', 'DMWS01'
             , 'DARD01', 'DCAL01') then
          vTplLine.DID_JOIN_KEY  := aKey2;
        else
          vTplLine.DID_JOIN_KEY  := aKey1;
      end case;

      insert into DOC_EDI_IMPORT_JOB_DATA
                  (DOC_EDI_IMPORT_JOB_DATA_ID
                 , C_EDI_JOB_DATA_STATUS
                 , DOC_EDI_IMPORT_JOB_ID
                 , DID_LINE_NUMBER
                 , DID_TAG
                 , DID_VALUE
                 , DID_JOIN_KEY
                 , DID_ERROR_TEXT
                 , A_DATECRE
                 , A_IDCRE
                  )
           values (vTplLine.DOC_EDI_IMPORT_JOB_DATA_ID
                 , vTplLine.C_EDI_JOB_DATA_STATUS
                 , aJobId
                 , aNoLine
                 , vTplLine.DID_TAG
                 , aLine
                 , vTplLine.DID_JOIN_KEY
                 , vTplLine.DID_ERROR_TEXT
                 , sysdate
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                  );
    end if;
  end pInsertLine;

  /**
  * procedure pReadLine
  * Description
  *    Lecture d'une ligne du fichier
  * @created fp/pyv 28.11.2007
  * @lastUpdate
  * @private
  * @param aFileHandle :  Handle du fichier
  * @param aFileBuffer : buffer texte dans lequel la ligne sera retournée
  * @param aBufferSize : taille maximale du buffer
  * @param aEof : indicateur de fin de fichier
  */
  procedure pReadLine(aFileHandle in UTL_FILE.FILE_TYPE, aFileBuffer out varchar2, aBufferSize in number, aEof out boolean)
  is
  begin
    aEof  := false;
    UTL_FILE.GET_LINE(aFileHandle, aFileBuffer, aBufferSize);
  exception
    when no_data_found then
      aEof  := true;
    when others then
      raise;
  end pReadLine;

  /**
  * Description
  *    Charge les fichiers en attente dans le directory EDI_STEPCOM_DIR
  */
  procedure LoadPendingFiles
  is
    vFilename DOC_EDI_IMPORT_JOB.DEJ_FILENAME%type;
  begin
    gERROR_MESSAGE  := '';
    vFileName       := substr(PC_FILES.FindFirst(gEDI_STEPCOM_DIR, '*.inh'), length(gEDI_STEPCOM_DIR) + 2);

    while vFileName is not null loop
      LoadFile(vFileName);
      vFileName  := PC_FILES.FindNext;
    end loop;

    PC_FILES.FindClose;
  end LoadPendingFiles;

  /**
  * Description
  *   Chargement d'un fichier
  */
  procedure LoadFile(aFilename in DOC_EDI_IMPORT_JOB.DEJ_FILENAME%type)
  is
    vJobId       DOC_EDI_IMPORT_JOB.DOC_EDI_IMPORT_JOB_ID%type;
    vKey1        DOC_EDI_IMPORT_JOB_DATA.DID_JOIN_KEY%type;
    vKey2        DOC_EDI_IMPORT_JOB_DATA.DID_JOIN_KEY%type;
    vCurrentLine DOC_EDI_IMPORT_JOB_DATA.DID_VALUE%type;
    vNoLine      DOC_EDI_IMPORT_JOB_DATA.DID_LINE_NUMBER%type    := 0;
  begin
    savepoint LoadFile;

    declare
      vFileHandle UTL_FILE.FILE_TYPE;
      vFileBuffer varchar2(4000 char);
      vEof        boolean;
    begin
      -- ouverture du fichier
      vFileHandle  := UTL_FILE.FOPEN(gEDI_STEPCOM_DIR, aFileName, 'r');
      -- recherche d'un ID pour le job
      vJobId       := getNewId;
      -- Créationde l'entête
      pCreateJobHeader(vJobId, aFileName);
      -- lecture ligne par ligne
      pReadLine(vFileHandle, vFileBuffer, cBUFFER_SIZE, vEof);

      while not vEof loop
        vNoLine  := vNoLine + 1;
        pInsertLine(vJobId, vFileBuffer, vNoLine, vKey1, vKey2);
        pReadLine(vFileHandle, vFileBuffer, cBUFFER_SIZE, vEof);
      end loop;

      -- fermeture du fichier, permet de libérer le lock sur le fichier
      UTL_FILE.FCLOSE_ALL;

      -- transfert du fichier dans le répertoire BACKUP
      if not PC_FILES.MoveFile(gEDI_STEPCOM_DIR || '\' || aFileName, gEDI_STEPCOM_DIR_BACKUP || '\' || aFileName) then
        ra(replace('PCS - Impossible to backup file [FILENAME]!', '[FILENAME]', aFileName) );
      end if;
    exception
      when others then
        gERROR_MESSAGE  :=
          replace(PCS.PC_FUNCTIONS.TranslateWord('Le fichier "[FILENAME]" est en cours d''utilisation ou le compte "oracle" n''a pas les droits suffisant.')
                , '[FILENAME]'
                , aFilename
                 );
        DOC_EDI_SC_FUNCTIONS.setJobStatus(vJobId, 'ERR_IMPORT');
        -- fermeture du fichier, permet de libérer le lock sur le fichier
        UTL_FILE.FCLOSE_ALL;
        rollback to LoadFile;
    end;

    commit;
  end LoadFile;

  /**
  * Description
  *   Envoie les job en attente dans DOC_INTERFACE
  */
  procedure sendPendingToInterface(aRetryErrors in number default 0, aIgnoreErrors in number default 0)
  is
  begin
    for tplJob in (select DOC_EDI_IMPORT_JOB_ID
                     from DOC_EDI_IMPORT_JOB DID
                        , DOC_EDI_TYPE DET
                    where DET.DOC_EDI_TYPE_ID = DID.DOC_EDI_TYPE_ID
                      and DET.DET_NAME = 'SC_BEST'
                      and (   DID.C_EDI_JOB_STATUS in('IMPORTED')
                           or (    aRetryErrors = 1
                               and DID.C_EDI_JOB_STATUS in('FERR_GENE') ) ) ) loop
      begin
        sendBestToInterface(tplJob.DOC_EDI_IMPORT_JOB_ID);
--      exception
--        when others then
--          if aIgnoreErrors = 1 then
--            null;
--          else
--            raise;
--          end if;
      end;
    end loop;
  end sendPendingToInterface;

  /**
  * Description
  *    Envoie un job dans DOC_INTERFACE
  */
  procedure sendBestToInterface(aJobId in DOC_EDI_IMPORT_JOB.DOC_EDI_IMPORT_JOB_ID%type)
  is
    vStepcomPackage varchar2(30);
    vExistsPackage  number(1);
    vVersion        varchar2(10);
    vType           varchar2(4);
    vThird          varchar2(10);
  begin
    for vTplINFREC in (select *
                         from V_DOC_EDI_SC_INFREC
                        where DOC_EDI_IMPORT_JOB_ID = aJobId) loop
      vVersion         := replace(ExtractLine(ExtractLine(vTplINFREC."MAPPING-VERSION", 2, '-'), 3, ' '), '.', '');
      vType            := upper(substr(vTplINFREC."MAPPING-VERSION", 2, 4) );   -- BEST
      vThird           := ExtractLine(ExtractLine(vTplINFREC."MAPPING-VERSION", 2, '-'), 1, ' ');
      vStepcomPackage  := 'IND_DOC_EDI_SC_' || vType || '_' || vThird || '_' || vVersion;

      select count(*)
        into vExistsPackage
        from USER_OBJECTS
       where OBJECT_NAME = vStepcomPackage
         and OBJECT_TYPE = 'PACKAGE';

      if vExistsPackage = 1 then
        begin
          execute immediate 'begin' || co.cLineBreak || '  ' || vStepComPackage || '.sendToInterface(:AINFRECID);' || co.cLineBreak || 'end;'
                      using vTplINFREC.DOC_EDI_IMPORT_JOB_DATA_ID;
        exception
          when ex.PLSQL_ERROR then
            ra(vStepComPackage);
          when others then
            raise;
        end;
      else
        ra(replace(replace('PCS - No package defined for importing data for [PARTNER]/[VERSION]' || ' ' || vStepComPackage, '[PARTNER]'
                         , vTplINFREC."PARTNER-ID")
                 , '[VERSION]'
                 , vVersion
                  )
          );
      end if;
    end loop;

    DOC_EDI_SC_FUNCTIONS.setJobStatus(aJobId, 'GENERATED');
  end sendBestToInterface;
begin
  -- Initialisation du répertoire des fichiers
  select VAR.VAR_CHARACTER
    into gEDI_STEPCOM_DIR
    from COM_VARIABLE VAR
   where VAR.VAR_NAME = 'EDI_STEPCOM_DIR'
     and VAR.VAR_VARIANT is null;

  -- Initialisation du répertoire de backup
  select VAR.VAR_CHARACTER
    into gEDI_STEPCOM_DIR_BACKUP
    from COM_VARIABLE VAR
   where VAR.VAR_NAME = 'EDI_STEPCOM_DIR_BACKUP'
     and VAR.VAR_VARIANT is null;
end DOC_EDI_SC_DATA_LOADER;
