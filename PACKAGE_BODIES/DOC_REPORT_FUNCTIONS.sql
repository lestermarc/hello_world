--------------------------------------------------------
--  DDL for Package Body DOC_REPORT_FUNCTIONS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_REPORT_FUNCTIONS" 
is
  procedure SendDocumentToPrintQueue(aDocumentID in DOC_DOCUMENT.DOC_DOCUMENT_ID%type, iv_exchange_system_key in varchar2 default null)
  is
    cursor crGetGaugeReports(cGaugeID in DOC_GAUGE.DOC_GAUGE_ID%type)
    is
      select   REPORT_NBR
             , substr(EDIT_NAME, 1, decode(instr(EDIT_NAME, '.') - 1, -1, length(EDIT_NAME), instr(EDIT_NAME, '.') - 1) ) EDIT_NAME
             , EDIT_TEXT
             , COPY_SUP
             , COLLATE_COPIES
             , PRINT_SQL
          from (select 1 REPORT_NBR
                     , GAU_EDIT_NAME EDIT_NAME
                     , GAU_EDIT_TEXT EDIT_TEXT
                     , C_APPLI_COPY_SUPP COPY_SUP
                     , GAU_EDIT_BOOL EDIT_BOOL
                     , GAU_COLLATE_COPIES COLLATE_COPIES
                     , GAU_REPORT_PRINT_TEST PRINT_SQL
                  from DOC_GAUGE
                 where DOC_GAUGE_ID = cGaugeID
                union all
                select 2 REPORT_NBR
                     , GAU_EDIT_NAME1 EDIT_NAME
                     , GAU_EDIT_TEXT1 EDIT_TEXT
                     , APPLI_COPY_SUPP1 COPY_SUP
                     , GAU_EDIT_BOOL1 EDIT_BOOL
                     , GAU_COLLATE_COPIES1 COLLATE_COPIES
                     , GAU_REPORT_PRINT_TEST1 PRINT_SQL
                  from DOC_GAUGE
                 where DOC_GAUGE_ID = cGaugeID
                union all
                select 3 REPORT_NBR
                     , GAU_EDIT_NAME2 EDIT_NAME
                     , GAU_EDIT_TEXT2 EDIT_TEXT
                     , APPLI_COPY_SUPP2 COPY_SUP
                     , GAU_EDIT_BOOL2 EDIT_BOOL
                     , GAU_COLLATE_COPIES2 COLLATE_COPIES
                     , GAU_REPORT_PRINT_TEST2 PRINT_SQL
                  from DOC_GAUGE
                 where DOC_GAUGE_ID = cGaugeID
                union all
                select 4 REPORT_NBR
                     , GAU_EDIT_NAME3 EDIT_NAME
                     , GAU_EDIT_TEXT3 EDIT_TEXT
                     , APPLI_COPY_SUPP3 COPY_SUP
                     , GAU_EDIT_BOOL3 EDIT_BOOL
                     , GAU_COLLATE_COPIES3 COLLATE_COPIES
                     , GAU_REPORT_PRINT_TEST3 PRINT_SQL
                  from DOC_GAUGE
                 where DOC_GAUGE_ID = cGaugeID
                union all
                select 5 REPORT_NBR
                     , GAU_EDIT_NAME4 EDIT_NAME
                     , GAU_EDIT_TEXT4 EDIT_TEXT
                     , APPLI_COPY_SUPP4 COPY_SUP
                     , GAU_EDIT_BOOL4 EDIT_BOOL
                     , GAU_COLLATE_COPIES4 COLLATE_COPIES
                     , GAU_REPORT_PRINT_TEST4 PRINT_SQL
                  from DOC_GAUGE
                 where DOC_GAUGE_ID = cGaugeID
                union all
                select 6 REPORT_NBR
                     , GAU_EDIT_NAME5 EDIT_NAME
                     , GAU_EDIT_TEXT5 EDIT_TEXT
                     , APPLI_COPY_SUPP5 COPY_SUP
                     , GAU_EDIT_BOOL5 EDIT_BOOL
                     , GAU_COLLATE_COPIES5 COLLATE_COPIES
                     , GAU_REPORT_PRINT_TEST5 PRINT_SQL
                  from DOC_GAUGE
                 where DOC_GAUGE_ID = cGaugeID
                union all
                select 7 REPORT_NBR
                     , GAU_EDIT_NAME6 EDIT_NAME
                     , GAU_EDIT_TEXT6 EDIT_TEXT
                     , APPLI_COPY_SUPP6 COPY_SUP
                     , GAU_EDIT_BOOL6 EDIT_BOOL
                     , GAU_COLLATE_COPIES6 COLLATE_COPIES
                     , GAU_REPORT_PRINT_TEST6 PRINT_SQL
                  from DOC_GAUGE
                 where DOC_GAUGE_ID = cGaugeID
                union all
                select 8 REPORT_NBR
                     , GAU_EDIT_NAME7 EDIT_NAME
                     , GAU_EDIT_TEXT7 EDIT_TEXT
                     , APPLI_COPY_SUPP7 COPY_SUP
                     , GAU_EDIT_BOOL7 EDIT_BOOL
                     , GAU_COLLATE_COPIES7 COLLATE_COPIES
                     , GAU_REPORT_PRINT_TEST7 PRINT_SQL
                  from DOC_GAUGE
                 where DOC_GAUGE_ID = cGaugeID
                union all
                select 9 REPORT_NBR
                     , GAU_EDIT_NAME8 EDIT_NAME
                     , GAU_EDIT_TEXT8 EDIT_TEXT
                     , APPLI_COPY_SUPP8 COPY_SUP
                     , GAU_EDIT_BOOL8 EDIT_BOOL
                     , GAU_COLLATE_COPIES8 COLLATE_COPIES
                     , GAU_REPORT_PRINT_TEST8 PRINT_SQL
                  from DOC_GAUGE
                 where DOC_GAUGE_ID = cGaugeID
                union all
                select 10 REPORT_NBR
                     , GAU_EDIT_NAME9 EDIT_NAME
                     , GAU_EDIT_TEXT9 EDIT_TEXT
                     , APPLI_COPY_SUPP9 COPY_SUP
                     , GAU_EDIT_BOOL9 EDIT_BOOL
                     , GAU_COLLATE_COPIES9 COLLATE_COPIES
                     , GAU_REPORT_PRINT_TEST9 PRINT_SQL
                  from DOC_GAUGE
                 where DOC_GAUGE_ID = cGaugeID
                union all
                select 11 REPORT_NBR
                     , GAU_EDIT_NAME10 EDIT_NAME
                     , GAU_EDIT_TEXT10 EDIT_TEXT
                     , APPLI_COPY_SUPP10 COPY_SUP
                     , GAU_EDIT_BOOL10 EDIT_BOOL
                     , GAU_COLLATE_COPIES10 COLLATE_COPIES
                     , GAU_REPORT_PRINT_TEST10 PRINT_SQL
                  from DOC_GAUGE
                 where DOC_GAUGE_ID = cGaugeID) REPORTS
         where EDIT_BOOL = 1
      order by 1;

    cursor crReportInfo(cRepName in PCS.PC_REPORT.REP_REPNAME%type)
    is
      select PC_REPORT_ID
           , REP_REPNAME
           , REP_REPPATH
        from PCS.PC_REPORT
       where REP_REPNAME = cRepName;

    tplReportInfo crReportInfo%rowtype;
    DmtNumber     DOC_DOCUMENT.DMT_NUMBER%type;
    GaugeID       DOC_GAUGE.DOC_GAUGE_ID%type;
    ReportName    DOC_GAUGE.GAU_EDIT_NAME%type;
    xmldata       xmltype;
    lv_queue_type varchar2(10);
  begin
    -- Recherche le n° du document
    select nvl(max(DMT_NUMBER), '-1')
         , max(DOC_GAUGE_ID)
      into DmtNumber
         , GaugeID
      from DOC_DOCUMENT
     where DOC_DOCUMENT_ID = aDocumentID;

    -- N° de document trouvé
    if (DmtNumber <> '-1') then
      -- Rechercher les valeurs des formulaires définies dans le gabarit
      for tplGetGaugeReports in crGetGaugeReports(GaugeID) loop
        -- Rechercher les infos du rapport dans la table PC_REPORT
        open crReportInfo(tplGetGaugeReports.EDIT_NAME);

        fetch crReportInfo
         into tplReportInfo;

        -- Rapport présent dans la table des rapports PC_REPORT
        if crReportInfo%found then
          declare
            -- Variable contenant les infos pour l'envoi dans une queue Oracle
            tmpReport             PCS.PC_REPORT_FUNCTIONS.TReport;
            vPrintOption          varchar2(255);
            vPrintValue           varchar2(255);
            vPrinterName          varchar2(255);
            vPaperSize            varchar2(255);
            vBinSource            varchar2(255);
            vOrientation          varchar2(255);
            vCopies               varchar2(255);
            vCollated             varchar2(255);
            nThirdSupplCopies     integer;
            vConfigDefaultCopies  varchar2(10);
            vConfigDefaultBin     varchar2(255);
            vConfigDefaultPrinter varchar2(255);
          begin
            -- Recherche les infos du rapport définies dans le champ "Imprimante" => REP_PRINTER
            for cpt in 1 .. 10 loop
              select upper(pcs.ExtractLine(print_info, 1, '=') )
                   , pcs.ExtractLine(print_info, 2, '=')
                into vPrintOption
                   , vPrintValue
                from (select pcs.ExtractLine(REP_PRINTER, cpt) as print_info
                        from PCS.PC_REPORT
                       where REP_REPNAME = tplReportInfo.REP_REPNAME);

              if (vPrintOption = 'PRINTERNAME') then
                vPrinterName  := vPrintValue;
              elsif(vPrintOption = 'PAPERSIZE') then
                vPaperSize  := vPrintValue;
              elsif(vPrintOption = 'BINSOURCE') then
                vBinSource  := vPrintValue;
              elsif(vPrintOption = 'ORIENTATION') then
                vOrientation  := vPrintValue;
              elsif(vPrintOption = 'COPIES') then
                vCopies  := vPrintValue;
              elsif(vPrintOption = 'COLLATED') then
                vCollated  := vPrintValue;
              end if;
            end loop;

            -- Nbr de copies suppl. définies dans la config DOC_DEFAULT_COPIES
            vConfigDefaultCopies                                 :=
              pcs.pc_report_functions.GetReportConfig('DOC_DEFAULT_COPIES'
                                                    , tplReportInfo.REP_REPNAME
                                                    , PCS.PC_I_LIB_SESSION.GetCompanyId
                                                    , PCS.PC_I_LIB_SESSION.GetConliId
                                                     );
            -- Recherche le bac défini dans la config DOC_DEFAULT_BIN
            vConfigDefaultBin                                    :=
              pcs.pc_report_functions.GetReportConfig('DOC_DEFAULT_BIN'
                                                    , tplReportInfo.REP_REPNAME
                                                    , PCS.PC_I_LIB_SESSION.GetCompanyId
                                                    , PCS.PC_I_LIB_SESSION.GetConliId
                                                     );
            -- Recherche l'imprimante définie dans la config DOC_DEFAULT_PRINTER
            vConfigDefaultPrinter                                :=
              pcs.pc_report_functions.GetReportConfig('DOC_DEFAULT_PRINTER'
                                                    , tplReportInfo.REP_REPNAME
                                                    , PCS.PC_I_LIB_SESSION.GetCompanyId
                                                    , PCS.PC_I_LIB_SESSION.GetConliId
                                                     );
            -- Recherche le nbr de copies suppl au niveau du tiers
            nThirdSupplCopies                                    := DOC_LIB_GAUGE.GetCopySupp(GaugeID, DmtNumber, tplGetGaugeReports.REPORT_NBR, 'DOC');
            -- Nom du rapport
            tmpReport.REPNAME                                    := tplReportInfo.REP_REPNAME;
            -- Destination de rapport
            tmpReport.OUTPUT_MODE                                := 'PRINT';

            -- Paramètres du rapport

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
                 , tmpReport.ReportParam.PC_USELANG_ID
                 , tmpReport.ReportParam.USER_LANID
                 , tmpReport.ReportParam.USER_LANGUAGE
                 , tmpReport.ReportParam.PC_COMP_ID
                 , tmpReport.ReportParam.COMPANY_NAME
                 , tmpReport.ReportParam.COMPANY_LANID
                 , tmpReport.ReportParam.COMPANY_LANGUAGE
                 , tmpReport.ReportParam.COMPANY_OWNER
                 , tmpReport.ReportParam.COMPANY_PASSWORD
              from PCS.PC_SCRIP SCR
                 , PCS.PC_LANG COM_LAN
                 , PCS.PC_COMP COM
                 , PCS.PC_LANG USR_LAN
                 , PCS.PC_USER USR
             where USR.PC_USER_ID = PCS.PC_I_LIB_SESSION.GetUserId
               and USR.PC_LANG_ID = USR_LAN.PC_LANG_ID
               and COM.PC_COMP_ID(+) = PCS.PC_I_LIB_SESSION.GetCompanyId
               and COM.PC_LANG_ID = COM_LAN.PC_LANG_ID(+)
               and COM.PC_SCRIP_ID = SCR.PC_SCRIP_ID(+);

            -- Chemin du rapport
            tmpReport.ReportParam.REPORT_PATH                    := tplReportInfo.REP_REPPATH;
            -- ID du groupe de Configuration
            tmpReport.ReportParam.PC_CONLI_ID                    := PCS.PC_I_LIB_SESSION.GetConliId;
            -- ID de l'objet
            tmpReport.ReportParam.PC_OBJECT_ID                   := PCS.PC_I_LIB_SESSION.GetObjectId;
            -- ID du rapport
            tmpReport.ReportParam.PC_REPORT_ID                   := tplReportInfo.PC_REPORT_ID;
            -- Paramètres du rapport
            tmpReport.ReportParam.PARAMETER_LIST(0).PARAM_FIELD  := 'PARAMETER_0';
            tmpReport.ReportParam.PARAMETER_LIST(0).PARAM_VALUE  := DmtNumber;
            -- Paramètres de l'imprimante
            -- Nbr de copies
            tmpReport.PRINTER_OPTION.BINSOURCE                   := nvl(vBinSource, vConfigDefaultBin);
            -- Copies assemblées
            tmpReport.PRINTER_OPTION.COLLATED                    := tplGetGaugeReports.COLLATE_COPIES;
            -- Nbr de copies
            tmpReport.PRINTER_OPTION.COPIES                      := nThirdSupplCopies + to_number(nvl(nvl(vCopies, vConfigDefaultCopies), '0') );
            -- Orientation
            tmpReport.PRINTER_OPTION.ORIENTATION                 := vOrientation;
            -- Taille de la page
            tmpReport.PRINTER_OPTION.PAGE_SIZE                   := vPaperSize;
            -- Nom de l'imprimante
            tmpReport.PRINTER_OPTION.PRINTERNAME                 := nvl(vPrinterName, vConfigDefaultPrinter);
            -- Convertir l'object contenant les infos pour le transfert dans la queue en clob contenant le xml
            xmldata                                              := PCS.PC_REPORT_FUNCTIONS.ExportReportToXml(tmpReport);
            -- envoi d'un document dans le système de queuing
            com_report_functions.EnqueuePrintDocument(xmldata, iv_exchange_system_key);
          end;
        end if;

        close crReportInfo;
      end loop;
    end if;
  end SendDocumentToPrintQueue;
end DOC_REPORT_FUNCTIONS;
