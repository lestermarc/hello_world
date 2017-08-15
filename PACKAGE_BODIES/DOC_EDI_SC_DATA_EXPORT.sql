--------------------------------------------------------
--  DDL for Package Body DOC_EDI_SC_DATA_EXPORT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EDI_SC_DATA_EXPORT" 
is
  -- constante
  cStepcomSep constant varchar2(1) := '#';

  /**
  * Description
  *   Envoie les jobs en attente dans PC_EXCHANGE_DATA_OUT
  */
  procedure sendPendingToPcExchange(aExportType in DOC_EDI_TYPE.DET_NAME%type)
  is
    vExchangeSystemId       PCS.PC_EXCHANGE_SYSTEM.PC_EXCHANGE_SYSTEM_ID%type;
    vEdiTypeId              DOC_EDI_TYPE.DOC_EDI_TYPE_ID%type;
    vExchangeDataOutId      PCS.PC_EXCHANGE_DATA_OUT.PC_EXCHANGE_DATA_OUT_ID%type;
    vExchangeDataOutlinesId PCS.PC_EXCHANGE_DATA_OUT_LINES.PC_EXCHANGE_DATA_OUT_LINES_ID%type;
    vNoLine                 pls_integer;
  begin
    -- recherche du système de données correspondant
    select DOC_EDI_TYPE_ID
         , PC_EXCHANGE_SYSTEM_ID
      into vEdiTypeId
         , vExchangeSystemId
      from DOC_EDI_TYPE
     where DET_NAME = aExportType;

    -- réservation du groupe de données
    update    PCS.PC_EXCHANGE_DATA_OUT
          set C_EDO_PROCESS_STATUS = '01'
        where PC_EXCHANGE_SYSTEM_ID = vExchangeSystemId
          and C_EDO_PROCESS_STATUS = '02'
    returning PC_EXCHANGE_DATA_OUT_ID
         into vExchangeDataOutId;

    if vExchangeDataOutId is null then
      select PCS.INIT_ID_SEQ.nextval
        into vExchangeDataOutId
        from dual;

      insert into PCS.PC_EXCHANGE_DATA_OUT
                  (PC_EXCHANGE_DATA_OUT_ID
                 , C_EDO_PROCESS_STATUS
                 , PC_EXCHANGE_SYSTEM_ID
                 , EDO_CLOB
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
                 , null
                 , null
                 , null
                 , null
                 , null
                 , PCS.PC_I_LIB_SESSION.GetUserIni
                 , sysdate
                  );
    end if;

    -- init du compteur de lignes
    select count(*) + 1
      into vNoLine
      from PCS.PC_EXCHANGE_DATA_OUT_LINES
     where PC_EXCHANGE_DATA_OUT_ID = vExchangeDataOutId;

    for tplDocsToSend in (select   DOC_EDI_EXPORT_JOB_ID
                              from DOC_EDI_EXPORT_JOB
                             where DOC_EDI_TYPE_ID = vEdiTypeId
                               and C_EDI_JOB_STATUS = 'READY'
                          order by DOC_EDI_EXPORT_JOB_ID) loop
      for tplDataToSend in (select   DED_VALUE
                                from DOC_EDI_EXPORT_JOB_DATA
                               where DOC_EDI_EXPORT_JOB_ID = tplDocsToSend.DOC_EDI_EXPORT_JOB_ID
                            order by DOC_EDI_EXPORT_JOB_DATA_ID) loop
        select PCS.INIT_ID_SEQ.nextval
          into vExchangeDataOutlinesId
          from dual;

        insert into PCS.PC_EXCHANGE_DATA_OUT_LINES
                    (PC_EXCHANGE_DATA_OUT_LINES_ID
                   , PC_EXCHANGE_DATA_OUT_ID
                   , EDO_SEQ
                   , EDO_LINE
                   , A_DATECRE
                   , A_IDCRE
                    )
             values (vExchangeDataOutlinesId
                   , vExchangeDataOutId
                   , vNoLine
                   , tplDataToSend.DED_VALUE
                   , sysdate
                   , PCS.PC_I_LIB_SESSION.GetUserIni
                    );

        vNoLine  := vNoLine + 1;
      end loop;

      update DOC_EDI_EXPORT_JOB
         set C_EDI_JOB_STATUS = 'EXPORTED'
       where DOC_EDI_EXPORT_JOB_ID = tplDocsToSend.DOC_EDI_EXPORT_JOB_ID;
    end loop;

    -- libération du groupe de données
    update PCS.PC_EXCHANGE_DATA_OUT
       set C_EDO_PROCESS_STATUS = '02'
     where PC_EXCHANGE_DATA_OUT_ID = vExchangeDataOutId;
  end sendPendingToPcExchange;

  /**
  * Description
  *    Appel de la méthode d'exportation de document
  */
  procedure exportDocument(aDocumentId in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, aPackageName in varchar2)
  is
  begin
    execute immediate 'begin' || chr(10) || '  ' || aPackageName || '.ExportDocument(:ADOCUMENTID);' || chr(10) || 'end;'
                using aDocumentId;
  end exportDocument;
end DOC_EDI_SC_DATA_EXPORT;
