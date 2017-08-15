--------------------------------------------------------
--  DDL for Package Body COM_REPORT_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_REPORT_FUNCTIONS" 
IS

  /**
  * procedure SendReportToPrintQueue
  * Description
  *    Envoi des données pour l'impression dans une queue Oracle
  */
  procedure SendReportToPrintQueue(
    aReport            in varchar2
  , aPrinter           in varchar2 default null   -- UNC de l'imprimante
  , aOutputMode        in varchar2 default 'PRINT'
  , aConfigContext     in varchar2 default 'COM'
  , aExportName        in varchar2 default 'ATTACHMENT'
  , aExportFormat      in varchar2 default 'PDF'
  , aMailTo            in varchar2 default null
  , aMailCC            in varchar2 default null
  , aMailSubject       in varchar2 default 'PCS PrintServer'
  , aMailText          in varchar2 default null
  , aClause            in varchar2 default null
  , aCopies            in integer default null
  , aStoreTable        in varchar2 default null
  , aStoreField        in varchar2 default null
  , aStoreFieldType    in varchar2 default null
  , aStoreKeyField     in varchar2 default null
  , aStoreKeyValue     in varchar2 default null
  , aStoreKeyFieldType in varchar2 default null
  , aProcToCall        in varchar2 default null
  , iv_exchange_system_key IN VARCHAR2 DEFAULT null
  , iv_entity_name     in varchar2 default null
  , in_record_id       in number default null
  , aMailFrom          in varchar2 default null
  )
  is
    cursor crReportInfo(cRepName in PCS.PC_REPORT.REP_REPNAME%type)
    is
      select PC_REPORT_ID
           , REP_REPNAME
           , REP_REPPATH
           , REP_PRINTER
        from PCS.PC_REPORT
       where REP_REPNAME = cRepName;

    tplReportinfo         crReportInfo%rowtype;
    -- Variable contenant les infos pour l'envoi dans une queue Oracle
    tmpReport             PCS.PC_REPORT_FUNCTIONS.TReport;
    vUserDescr            PCS.PC_USER.USE_DESCR%type;
    vUserEmail            PCS.PC_USER.USE_EMAIL%type;
    vPrinterName          varchar2(255);
    vPaperSize            varchar2(255);
    vBinSource            varchar2(255);
    vOrientation          varchar2(255);
    vCopies               varchar2(255);
    vCollated             varchar2(255);
    vConfigDefaultCopies  varchar2(10);
    vConfigDefaultBin     varchar2(255);
    vConfigDefaultPrinter varchar2(255);
    vEmail_TO             PCS.PC_REPORT_FUNCTIONS.TItemList;
    vEmail_CC             PCS.PC_REPORT_FUNCTIONS.TItemList;
    vParamList            PCS.PC_REPORT_FUNCTIONS.TParamList;
    xmldata               xmltype;
    visCorrectQueueType   integer;
  begin
    if aOutputMode = 'EXPORT_TO_DOCUWARE' then
      --Teste en cas de outputmode = EXPORT_TO_DOCUWARE que les champs iv_entity_name, in_record_id soient différents de null
      PCS_FWK.FWK_LIB_UTILS.check_argument('iv_entity_name',iv_entity_name);
      PCS_FWK.FWK_LIB_UTILS.check_argument('in_record_id',in_record_id);
    end if;

    open crReportInfo(aReport);

    fetch crReportInfo
     into tplReportInfo;

    if crReportInfo%found then
      -- Conversion du string contenant les destinataires du mail en liste
      if aMailTo is not null then
        select LINE
        bulk collect into vEmail_TO
          from (select PCS.EXTRACTLINE(aMailTo, no, ';', 1) LINE
                  from PCS.PC_NUMBER
                 where no <= length(aMailTo) - length(replace(aMailTo, ';') ) + 1)
         where LINE is not null;
      end if;

      -- Conversion du string contenant les destinataires CC du mail en liste
      if aMailCC is not null then
        select LINE
        bulk collect into vEmail_CC
          from (select PCS.EXTRACTLINE(aMailCC, no, ';', 1) LINE
                  from PCS.PC_NUMBER
                 where no <= length(aMailCC) - length(replace(aMailCC, ';') ) + 1)
         where LINE is not null;
      end if;

      -- Conversion du string contenant les paramètres du rapport en liste
      select substr(LINE, 1, instr(LINE, '=') - 1) PARAM_NAME
           , substr(LINE, instr(LINE, '=') + 1) PARAM_VALUE
      bulk collect into vParamList
        from (select PCS.EXTRACTLINE(aClause, no, ';', 1) LINE
                from PCS.PC_NUMBER
               where no <= length(aClause) - length(replace(aClause, ';') ) + 1)
       where LINE is not null;

      -- Recherche les infos du rapport définies dans le champ "Imprimante" => REP_PRINTER
      for tplPrinterOption in (select upper(substr(LINE, 1, instr(LINE, '=') - 1) ) PRINT_OPTION
                                    , substr(LINE, instr(LINE, '=') + 1) PRINT_VALUE
                                 from (select EXTRACTLINE(tplReportInfo.REP_PRINTER, no) LINE
                                         from PCS.PC_NUMBER
                                        where no < 100)
                                where LINE is not null) loop
        if tplPrinterOption.PRINT_OPTION = 'PRINTERNAME' then
          vPrinterName  := tplPrinterOption.PRINT_VALUE;
        elsif tplPrinterOption.PRINT_OPTION = 'PAPERSIZE' then
          vPaperSize  := tplPrinterOption.PRINT_VALUE;
        elsif tplPrinterOption.PRINT_OPTION = 'BINSOURCE' then
          vBinSource  := tplPrinterOption.PRINT_VALUE;
        elsif tplPrinterOption.PRINT_OPTION = 'ORIENTATION' then
          vOrientation  := tplPrinterOption.PRINT_VALUE;
        elsif tplPrinterOption.PRINT_OPTION = 'COPIES' then
          vCopies  := tplPrinterOption.PRINT_VALUE;
        elsif tplPrinterOption.PRINT_OPTION = 'COLLATED' then
          vCollated  := tplPrinterOption.PRINT_VALUE;
        end if;
      end loop;

      -- Nbr de copies suppl. définies dans la config ..._DEFAULT_COPIES
      vConfigDefaultCopies                        :=
        pcs.pc_report_functions.GetReportConfig(aConfigContext || '_DEFAULT_COPIES'
                                              , tplReportInfo.REP_REPNAME
                                              , PCS.PC_I_LIB_SESSION.GetCompanyId
                                              , PCS.PC_I_LIB_SESSION.GetConliId
                                               );
      -- Recherche le bac défini dans la config ..._DEFAULT_BIN
      vConfigDefaultBin                           :=
        pcs.pc_report_functions.GetReportConfig(aConfigContext || '_DEFAULT_BIN'
                                              , tplReportInfo.REP_REPNAME
                                              , PCS.PC_I_LIB_SESSION.GetCompanyId
                                              , PCS.PC_I_LIB_SESSION.GetConliId
                                               );
      -- Recherche l'imprimante définie dans la config ..._DEFAULT_PRINTER
      vConfigDefaultPrinter                       :=
        pcs.pc_report_functions.GetReportConfig(aConfigContext || '_DEFAULT_PRINTER'
                                              , tplReportInfo.REP_REPNAME
                                              , PCS.PC_I_LIB_SESSION.GetCompanyId
                                              , PCS.PC_I_LIB_SESSION.GetConliId
                                               );
                                                           --
      -- Nom du rapport
      tmpReport.REPNAME                           := tplReportInfo.REP_REPNAME;
      -- Destination de rapport EMAIL, EXPORT, PRINT, STORE_IN_DB, EXPORT_TO_DOCUWARE
      tmpReport.OUTPUT_MODE                       := aOutputMode;

      --
      -- Paramètres du rapport

      begin
        -- ID de l'utilisateur
        -- Nom de l'utilisateur
        -- ID de la langue de l'utilisateur
        -- Code langue de l'utilisateur (LANID=FR,GE,EN)
        -- Langue de l'utilisateur  (LANGUAGE=Français,Deutsch,English)
        -- ID de la company
        -- Nom de la company
        -- Code langue de la company (LANID=FR,GE,EN)
        -- Langue de la company  (LANGUAGE=Français,Deutsch,English)
        -- Propriétaire de la company
        -- Mot de passe de la company
        select USR.PC_USER_ID
             , USR.USE_NAME
             , USR.USE_DESCR
             , USR.USE_EMAIL
             , USR.PC_LANG_ID
             , USR_LAN.LANID
             , USR_LAN.LANNAME
             , COM.PC_COMP_ID
             , COM.COM_NAME
             , COM_LAN.LANID
             , COM_LAN.LANNAME
             , SCR.SCRDBOWNER
             , SCR.SCRDBOWNERPASSW
          into tmpReport.ReportParam.PC_USER_ID
             , tmpReport.ReportParam.USERNAME
             , vUserDescr
             , vUserEmail
             , tmpReport.ReportParam.PC_USELANG_ID
             , tmpReport.ReportParam.USER_LANID
             , tmpReport.ReportParam.USER_LANGUAGE
             , tmpReport.ReportParam.PC_COMP_ID
             , tmpReport.ReportParam.COMPANY_NAME
             , tmpReport.ReportParam.COMPANY_LANID
             , tmpReport.ReportParam.COMPANY_LANGUAGE
             , tmpReport.ReportParam.COMPANY_OWNER
             , tmpReport.ReportParam.COMPANY_PASSWORD
          from PCS.PC_USER USR
             , PCS.PC_LANG USR_LAN
             , PCS.PC_COMP COM
             , PCS.PC_LANG COM_LAN
             , PCS.PC_SCRIP SCR
         where USR.PC_USER_ID = PCS.PC_I_LIB_SESSION.GetUserId
           and USR.PC_LANG_ID = USR_LAN.PC_LANG_ID
           and COM.PC_COMP_ID = PCS.PC_I_LIB_SESSION.GetCompanyId
           and COM.PC_LANG_ID = COM_LAN.PC_LANG_ID(+)
           and COM.PC_SCRIP_ID = SCR.PC_SCRIP_ID(+);
      exception
        when no_data_found then
          ra('User and/or company not set in session');
      end;

      -- Remarque : Les rapports PC (sans connexion société) ne sont pas correctement gérés, il faut obligatoirement
      -- définir une société (pour avoir le owner et password) pour pouvoir les imprimer.
      -- A voir si on définit que le mot de passe PCS est stocké dans PC_SCRIP.

      if tmpReport.ReportParam.COMPANY_OWNER is null then
        ra('Company owner not found');
      end if;

      -- Nom de la table
      tmpReport.ReportParam.ENTITY_NAME           := iv_entity_name;
      -- Id du record lié à la table
      tmpReport.ReportParam.RECORD_ID             := in_record_id;
      -- Chemin du rapport
      tmpReport.ReportParam.REPORT_PATH           := tplReportInfo.REP_REPPATH;
      -- ID du groupe de Configuration
      tmpReport.ReportParam.PC_CONLI_ID           := PCS.PC_I_LIB_SESSION.GETCONLIID;
      -- ID de l'objet
      tmpReport.ReportParam.PC_OBJECT_ID          := PCS.PC_I_LIB_SESSION.GETOBJECTID;
      -- ID du rapport
      tmpReport.ReportParam.PC_REPORT_ID          := tplReportInfo.PC_REPORT_ID;
      -- Paramètres du rapport
      tmpReport.ReportParam.PARAMETER_LIST        := vParamList;

      if aOutputMode = 'EXPORT_TO_DOCUWARE' then
        tmpReport.DOCUWARE_OPTION.ACTIVE_IMPORT_FOLDER := COM_LIB_ECM.get_dw_active_import_folder(iv_entity_name,in_record_id);
      else
        tmpReport.DOCUWARE_OPTION.ACTIVE_IMPORT_FOLDER := null;
      end if;

      -- Paramètres de l'imprimante
      -- Bac
      tmpReport.PRINTER_OPTION.BINSOURCE          := nvl(nvl(vBinSource, vConfigDefaultBin), 1);

      -- Copies assemblées
      case
        when upper(vCollated) = 'TRUE' then
          tmpReport.PRINTER_OPTION.COLLATED  := 1;
        else
          tmpReport.PRINTER_OPTION.COLLATED  := 0;
      end case;

      -- Nbr de copies
      tmpReport.PRINTER_OPTION.COPIES             :=
                                                 nvl(aCopies, to_number(nvl(nvl(vCopies, vConfigDefaultCopies), '0') ) );
      -- Orientation
      tmpReport.PRINTER_OPTION.ORIENTATION        := vOrientation;
      -- Taille de la page
      tmpReport.PRINTER_OPTION.PAGE_SIZE          := vPaperSize;
      -- Nom de l'imprimante
      tmpReport.PRINTER_OPTION.PRINTERNAME        := nvl(aPrinter, nvl(vPrinterName, vConfigDefaultPrinter) );
      -- Nom du fichier
      tmpReport.EXPORT_OPTION.FILENAME            := aExportName;
      tmpReport.EXPORT_OPTION.FORMAT_TYPE         := aExportFormat;
      -- Email
      tmpReport.EMAIL_OPTION.TO_ADDRESS_LIST      := vEmail_TO;
      tmpReport.EMAIL_OPTION.CC_ADDRESS_LIST      := vEmail_CC;
      tmpReport.EMAIL_OPTION.FORMAT_TYPE          := aExportFormat;
      tmpReport.EMAIL_OPTION.EMAIL_FROM           := coalesce(aMailFrom, '"' || vUserDescr || '" <' || vUserEmail || '>');
      tmpReport.EMAIL_OPTION.EMAIL_SUBJECT        := aMailSubject;
      tmpReport.EMAIL_OPTION.EMAIL_MESSAGE        := aMailText;
      -- Stockage dans la base de données
      tmpReport.STORE_DB_OPTION.TABLE_NAME        := aStoreTable;
      tmpReport.STORE_DB_OPTION.COLUMN_TO_UPDATE  := aStoreField;
      tmpReport.STORE_DB_OPTION.COLUMN_TYPE       := aStoreFieldType;
      tmpReport.STORE_DB_OPTION.KEY_FIELD_NAME    := aStoreKeyField;
      tmpReport.STORE_DB_OPTION.KEY_FIELD_VALUE   := aStoreKeyValue;
      tmpReport.STORE_DB_OPTION.KEY_FIELD_TYPE    := aStoreKeyFieldType;
      tmpReport.STORE_DB_OPTION.PROC_TO_CALL      := aProcToCall;
      --
      -- Convertir l'object contenant les infos pour le transfert dans la queue en clob contenant le xml
      xmldata := PCS.PC_REPORT_FUNCTIONS.ExportReportToXml(tmpReport);

      -- envoi d'un document dans le système de queuing
      EnqueuePrintDocument(xmldata, iv_exchange_system_key);
    else
      ra('Report not found');
    end if;
    close crReportInfo;
  end SendReportToPrintQueue;


  procedure EnqueuePrintDocument(
    ix_document IN XMLType
  , iv_exchange_system_key IN VARCHAR2 DEFAULT null
  )
  is
    lv_queue_type VARCHAR2(10);
  begin
    if (ix_document is null) then
      pcs.pc_mgt_queue_exception.raise_exception(
          pcs.pc_mgt_queue_exception.PAYLOAD_IS_NULL_NO,
          'The document to enqueue is null');
    end if;

    -- détection du type de queue du système d'échange demandé
    if (iv_exchange_system_key is not null) then
      select exs.C_QUEUE_TYPE
        into lv_queue_type
        from PCS.PC_EXCHANGE_SYSTEM exs
       where exs.ECS_KEY = iv_exchange_system_key
         and exs.PC_COMP_ID = pcs.PC_I_LIB_SESSION.GetCompanyId;
    else
      lv_queue_type := 'PRTSRV';
    end if;
    if lv_queue_type is null then
      lv_queue_type := 'PRTSRV';
    end if;

    if not ((lv_queue_type = 'PRTSRV') or (substr(lv_queue_type, 1, 5) = 'PRINT' )) then
      pcs.pc_mgt_queue_exception.raise_exception(
        pcs.pc_mgt_queue_exception.NO_QUEUING_SYSTEM_NO,
        'Invalid queuing system : '''|| lv_queue_type|| '''');
    end if;

    -- Envoi du rapport dans une queue Oracle
    case pcs.pc_mgt_queue_sys.queuing(lv_queue_type)
      when pcs.pc_mgt_queue_sys.SOLVA_QUEUING then
        EXECUTE IMMEDIATE
          'begin rep_que_fct.enqueue(com_CurrentSchema, '''|| lv_queue_type ||''', ''PRINT_DOCUMENT'', :1) ; end;'
          USING IN ix_document; -- :1
      when pcs.pc_mgt_queue_sys.ADVANCED_QUEUING then
        if (pcs.pc_option_functions.isOptionActive('ADVANCED_QUEUING', pcs.PC_I_LIB_SESSION.GetCompanyId) = 1) then
          EXECUTE IMMEDIATE
            'begin rep_que_fct.use_enqueue(com_CurrentSchema, '''|| lv_queue_type ||'_Q'', ''PRINT_DOCUMENT'', :1) ; end;'
            USING IN ix_document; -- :1
        else
          ra('Impossible d’envoyer les données au serveur d’impression. Veuillez  activer / configurer l’option « ADVANCED_QUEUEING » pour la société' || Chr(10) ||
              pcs.PC_I_LIB_SESSION.GetComName);
        end if;
      else
        pcs.pc_mgt_queue_exception.raise_exception(
          pcs.pc_mgt_queue_exception.NO_QUEUING_SYSTEM_NO,
          'No queuing system for '''|| lv_queue_type|| '''');
    end case;
  end EnqueuePrintDocument;

END COM_REPORT_FUNCTIONS;
