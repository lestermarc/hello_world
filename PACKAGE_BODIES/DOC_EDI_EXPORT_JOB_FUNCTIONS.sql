--------------------------------------------------------
--  DDL for Package Body DOC_EDI_EXPORT_JOB_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EDI_EXPORT_JOB_FUNCTIONS" 
is
  /**
  * procedure SendJobToPcExchange
  * Description
  *   Envoi d'un job d'exporation EDI dans la table du système d'échange
  *    des données PC_EXCHANGE_DATA_OUT
  * @created NGV JAN 2010
  * @lastUpdate
  * @public
  * @param aExportJobID : ID du job à exporter
  */
  procedure SendJobToPcExchange(aExportJobID in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type, aErrorMsg out varchar2)
  is
    vExchangeSystemId       PCS.PC_EXCHANGE_SYSTEM.PC_EXCHANGE_SYSTEM_ID%type;
    vEdiTypeId              DOC_EDI_TYPE.DOC_EDI_TYPE_ID%type;
    vExchangeDataOutId      PCS.PC_EXCHANGE_DATA_OUT.PC_EXCHANGE_DATA_OUT_ID%type;
    vExchangeDataOutlinesId PCS.PC_EXCHANGE_DATA_OUT_LINES.PC_EXCHANGE_DATA_OUT_LINES_ID%type;
    vNoLine                 pls_integer;
    vFileName               DOC_EDI_EXPORT_JOB.DIJ_FILENAME%type;
  begin
    -- recherche du système de données correspondant
    select DET.DOC_EDI_TYPE_ID
         , DET.PC_EXCHANGE_SYSTEM_ID
         , DIJ.DIJ_FILENAME
      into vEdiTypeId
         , vExchangeSystemId
         , vFileName
      from DOC_EDI_EXPORT_JOB DIJ
         , DOC_EDI_TYPE DET
     where DIJ.DOC_EDI_EXPORT_JOB_ID = aExportJobID
       and DIJ.DOC_EDI_TYPE_ID = DET.DOC_EDI_TYPE_ID;

    select PCS.INIT_ID_SEQ.nextval
      into vExchangeDataOutId
      from dual;

    insert into PCS.PC_EXCHANGE_DATA_OUT
                (PC_EXCHANGE_DATA_OUT_ID
               , C_EDO_PROCESS_STATUS
               , PC_EXCHANGE_SYSTEM_ID
               , EDO_FILENAME
               , EDO_DESTINATION_URL
               , C_ECS_FILE_ENCODING
               , EDO_ERROR_MESSAGE
               , A_IDCRE
               , A_DATECRE
                )
         values (vExchangeDataOutId
               , '01'
               , vExchangeSystemId
               , nvl(vFileName, to_char(sysdate, 'yyyymmddhh24miss') || '.txt')
               , null
               , null
               , null
               , PCS.PC_I_LIB_SESSION.GetUserIni
               , sysdate
                );

    for tplDocsToSend in (select   DOC_EDI_EXPORT_JOB_ID
                              from DOC_EDI_EXPORT_JOB
                             where DOC_EDI_TYPE_ID = vEdiTypeId
                               and DOC_EDI_EXPORT_JOB_ID = aExportJobID
                               and C_EDI_JOB_STATUS = 'READY'
                          order by DOC_EDI_EXPORT_JOB_ID) loop
      insert into PCS.PC_EXCHANGE_DATA_OUT_LINES
                  (PC_EXCHANGE_DATA_OUT_LINES_ID
                 , PC_EXCHANGE_DATA_OUT_ID
                 , EDO_SEQ
                 , EDO_LINE
                 , EDO_APPEND_NEXTLINE
                 , A_DATECRE
                 , A_IDCRE
                  )
        select PCS.INIT_ID_SEQ.nextval
             , MAIN.*
          from (select   vExchangeDataOutId
                       , DED_LINE_NUMBER
                       , DED_VALUE
                       , DED_APPEND_NEXTLINE
                       , sysdate
                       , PCS.PC_I_LIB_SESSION.GetUserIni
                    from DOC_EDI_EXPORT_JOB_DATA
                   where DOC_EDI_EXPORT_JOB_ID = tplDocsToSend.DOC_EDI_EXPORT_JOB_ID
                order by DOC_EDI_EXPORT_JOB_DATA_ID) MAIN;

      update DOC_EDI_EXPORT_JOB
         set C_EDI_JOB_STATUS = 'EXPORTED'
       where DOC_EDI_EXPORT_JOB_ID = tplDocsToSend.DOC_EDI_EXPORT_JOB_ID;
    end loop;

    -- libération du groupe de données
    update PCS.PC_EXCHANGE_DATA_OUT
       set C_EDO_PROCESS_STATUS = '02'
     where PC_EXCHANGE_DATA_OUT_ID = vExchangeDataOutId;

    if vExchangeDataOutId is not null then
      aErrorMsg  := '';
    else
      aErrorMsg  := 'PCS - export failed';
    end if;
  exception
    when others then
      aErrorMsg  := sqlerrm;
  end SendJobToPcExchange;

  /**
  * procedure WriteLineToJobData
  * Description
  *    Insertion dans la table des données d'export des lignes correspondant au
  *      texte formaté passé en param
  */
  procedure WriteLineToJobData(aExportJobID in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type, aFormattedText in varchar2)
  is
    vLinesCount integer;
    vLine       DOC_EDI_EXPORT_JOB_DATA.DED_VALUE%type;
    vCpt        integer;
    vOffset     integer;
  begin
    -- Désormais on prend que 1000 caractères au lieu de 4000 à cause des BD
    -- en UTF8. Avec 4000 caratères nous avions l'erreur suivante lors de l'insert
    -- "ORA-01461: can bind a LONG value only for insert into a LONG column"
    --
    -- Définition du nbr de lignes à insèrer
    vLinesCount  := ceil(length(aFormattedText) / 1000);

    -- Récupèrer le dernier n° de ligne pour l'export courant dans la table
    -- des données de l'export
    select nvl(max(DED_LINE_NUMBER), 0)
      into vOffset
      from DOC_EDI_EXPORT_JOB_DATA
     where DOC_EDI_EXPORT_JOB_ID = aExportJobID;

    -- Extraire des lignes de 1000 caractères et insèrer ces lignes dans la table d'export
    for vCpt in 1 .. vLinesCount loop
      vLine  := substr(aFormattedText,( (vCpt - 1) * 1000) + 1, 1000);

      insert into DOC_EDI_EXPORT_JOB_DATA
                  (DOC_EDI_EXPORT_JOB_DATA_ID
                 , DOC_EDI_EXPORT_JOB_ID
                 , C_EDI_JOB_DATA_STATUS
                 , DED_LINE_NUMBER
                 , DED_VALUE
                 , DED_APPEND_NEXTLINE
                  )
        select INIT_ID_SEQ.nextval
             , aExportJobID
             , 'OK'
             , vOffset + vCpt
             , vLine
             , case
                 when vCpt = vLinesCount then 0
                 else 1
               end
          from dual;
    end loop;
  end WriteLineToJobData;

  /**
  * function CreateEdecExportJob
  * Description
  *   Création du job d'exportation dans la table DOC_EDI_EXPORT_JOB
  */
  function CreateExportJob(
    aFileName    in DOC_EDI_EXPORT_JOB.DIJ_FILENAME%type
  , aDescription in DOC_EDI_EXPORT_JOB.DIJ_DESCRIPTION%type
  , aEdiTypeID   in DOC_EDI_EXPORT_JOB.DOC_EDI_TYPE_ID%type
  )
    return DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  is
    vJobID DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type;
  begin
    select INIT_ID_SEQ.nextval
      into vJobID
      from dual;

    -- Insertion du job d'exportation
    insert into DOC_EDI_EXPORT_JOB
                (DOC_EDI_EXPORT_JOB_ID
               , C_EDI_JOB_STATUS
               , DOC_EDI_TYPE_ID
               , DIJ_DESCRIPTION
               , DIJ_FILENAME
               , A_DATECRE
               , A_IDCRE
                )
      select vJobID as DOC_EDI_EXPORT_JOB_ID
           , 'READY' as C_EDI_JOB_STATUS
           , aEdiTypeID as DOC_EDI_TYPE_ID
           , aDescription as DIJ_DESCRIPTION
           , aFileName as DIJ_FILENAME
           , sysdate as A_DATECRE
           , PCS.PC_I_LIB_SESSION.GetUserIni A_IDCRE
        from dual;

    return vJobID;
  end CreateExportJob;

  /**
  * function PcsRpad
  * Description
  *   Rpad
  * @created PYV Mar 2010
  * @lastUpdate
  * @public
  * @param aText     texte à compléter (à droite) par le caractère spécifié par le paramètre aChar
  * @param aLength   longueur finale du texte complété
  * @param aChar     caractère de remplacement des LF (chr(10)), '' par défaut
  * @return texte complété
  */
  function PcsRpad(aText in varchar2, aLength in number, aChar in varchar2 default '')
    return varchar2
  is
    lv_Text varchar2(4000);
  begin
    lv_text  := aText;

    if lv_text is null then
      lv_text  := ' ';
    end if;

    return rpad(replace(lv_Text, chr(10), aChar), aLength, ' ');
  end PcsRpad;

  /**
  * function PcsLpad
  * Description
  *   Rpad
  * @created PYV Mar 2010
  * @lastUpdate
  * @public
  * @param aNumber   nombre à compléter (à gauche) par des espaces
  * @param aFormat   format à appliquer au nombre
  * @param aLength   longueur finale du nombre complété
  * @return nombre complété
  */
  function PcsLpad(aNumber in number, aFormat varchar2, aLength in number)
    return varchar2
  is
  begin
    if aNumber is null then
      return lpad(' ', aLength, ' ');
    else
      return lpad(to_char(aNumber, aFormat), aLength, ' ');
    end if;
  end PcsLpad;

  /**
  * function PcsLpad
  * Description
  *   Rpad
  * @created PYV Mar 2010
  * @lastUpdate
  * @public
  * @param aDate     date à compléter (à gauche) par des espaces
  * @param aFormat   format à appliquer à la date
  * @param aLength   longueur finale de la date complétée
  * @return date complétée
  */
  function PcsLpad(aDate in date, aFormat varchar2, aLength in number)
    return varchar2
  is
  begin
    if aDate is null then
      return lpad(' ', aLength, ' ');
    else
      return lpad(to_char(aDate, aFormat), aLength, ' ');
    end if;
  end PcsLpad;
end DOC_EDI_EXPORT_JOB_FUNCTIONS;
