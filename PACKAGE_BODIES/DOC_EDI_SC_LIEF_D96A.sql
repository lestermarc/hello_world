--------------------------------------------------------
--  DDL for Package Body DOC_EDI_SC_LIEF_D96A
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "DOC_EDI_SC_LIEF_D96A" 
is
  -- constante
  cStepcomSep constant varchar2(1) := '#';

  /**
  * Description
  *    Inserting a row of INFREC type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_INFREC(
    aExportJobId out    DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in     DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aINFREC      in     tINFREC
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
    vTplEdiJob     DOC_EDI_EXPORT_JOB%rowtype;
  begin
    aExportJobId                               := getNewId;
    vTplEdiJob.DOC_EDI_EXPORT_JOB_ID           := aExportJobId;

    begin
      select DOC_EDI_TYPE_ID
        into vTplEdiJob.DOC_EDI_TYPE_ID
        from DOC_EDI_TYPE
       where DET_NAME = 'SC_LIEF';
    exception
      when no_data_found then
        ra('No EDI type for SC_LIEF definied');
    end;

    vTplEdiJob.C_EDI_JOB_STATUS                := 'READY';
    vTplEdiJob.DIJ_DESCRIPTION                 := aINFREC.DOCUMENT_ID;
    vTplEdiJob.A_DATECRE                       := sysdate;
    vTplEdiJob.A_IDCRE                         := PCS.PC_I_LIB_SESSION.GetUserIni;

    insert into DOC_EDI_EXPORT_JOB
         values vTplEdiJob;

    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'INFREC';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('INFREC', 6) ||
      cStepcomSep ||
      rpad(nvl(aINFREC.NRCODE, ' '), 1) ||
      cStepcomSep ||
      rpad(nvl(aINFREC.PARTNER_ID, ' '), 15) ||
      cStepcomSep ||
      rpad(nvl(aINFREC.OWNER_ID, ' '), 19) ||
      cStepcomSep ||
      rpad(nvl(aINFREC.APPLICATION_ID, ' '), 20) ||
      cStepcomSep ||
      rpad(nvl(aINFREC.TESTINDICATOR, ' '), 1) ||
      cStepcomSep ||
      rpad(nvl(aINFREC.DOCUMENT_REF, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aINFREC.MAPPING_VERSION, ' '), 29) ||
      cStepcomSep ||
      rpad(nvl(aINFREC.INTERCHANGE_REF, ' '), 14) ||
      cStepcomSep ||
      rpad(nvl(aINFREC.APPLICATION_REF, ' '), 14) ||
      cStepcomSep ||
      rpad(nvl(aINFREC.COMMON_AGREEMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aINFREC.PREPERATION_DATE, ' '), 8) ||
      cStepcomSep ||
      rpad(nvl(aINFREC.PREPERATION_TIME, ' '), 6) ||
      cStepcomSep ||
      rpad(nvl(aINFREC.REVERSE_ROUTING, ' '), 14) ||
      cStepcomSep ||
      rpad(nvl(aINFREC.ROUTING_ADRESS, ' '), 14) ||
      cStepcomSep ||
      rpad(nvl(aINFREC.ACKNOWLEDGEMENT_REQ, ' '), 1) ||
      cStepcomSep ||
      rpad(nvl(aINFREC.MESSAGE_REF, ' '), 14) ||
      cStepcomSep ||
      rpad(nvl(aINFREC.DOCUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aINFREC.REST, ' '), 49) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_INFREC";

  /**
  * Description
  *    Inserting a row of HHDR01 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_HHDR01(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aHHDR01      in tHHDR01
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'HHDR01';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('HHDR01', 6) ||
      cStepcomSep ||
      rpad(nvl(aHHDR01.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHHDR01.DOKUMENT_ART, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHHDR01.DOKUMENT_FUNKTION, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHHDR01.DOKUMENT_ANTWORT, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHHDR01.REST, ' '), 100) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_HHDR01";

  /**
  * Description
  *    Inserting a row of HDAT01 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_HDAT01(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aHDAT01      in tHDAT01
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'HDAT01';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('HDAT01', 6) ||
      cStepcomSep ||
      rpad(nvl(aHDAT01.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHDAT01.DATUM_QUAL, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHDAT01.DATUM, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHDAT01.DATUM_FORMAT, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHDAT01.REST, ' '), 100) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_HDAT01";

  /**
  * Description
  *    Inserting a row of HREF01 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_HREF01(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aHREF01      in tHREF01
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'HREF01';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('HREF01', 6) ||
      cStepcomSep ||
      rpad(nvl(aHREF01.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHREF01.REFERENZ_QUAL, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHREF01.REFERENZ_NR, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHREF01.REFERENZ_DAT_1, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHREF01.REFERENZ_DAT_2, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHREF01.REST, ' '), 100) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_HREF01";

  /**
  * Description
  *    Inserting a row of HADR01 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_HADR01(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aHADR01      in tHADR01
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'HADR01';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('HADR01', 6) ||
      cStepcomSep ||
      rpad(nvl(aHADR01.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHADR01.ADRESSE_QUAL, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHADR01.PARTNER_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHADR01.PARTNER_QUAL, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHADR01.NAME_ZEILE_1, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHADR01.NAME_ZEILE_2, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHADR01.NAME_ZEILE_3, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHADR01.NAME_ZEILE_4, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHADR01.STRASSE_1, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHADR01.STRASSE_2, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHADR01.STRASSE_3, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHADR01.STRASSE_4, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHADR01.ORT, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHADR01.PLZ, ' '), 9) ||
      cStepcomSep ||
      rpad(nvl(aHADR01.LAND, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHADR01.REST, ' '), 100) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_HADR01";

  /**
  * Description
  *    Inserting a row of HREF02 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_HREF02(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aHREF02      in tHREF02
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'HREF02';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('HREF02', 6) ||
      cStepcomSep ||
      rpad(nvl(aHREF02.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHREF02.ADRESSE_QUAL, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHREF02.PARTNER_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHREF02.REFERENZ_QUAL, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHREF02.REFERENZ_NR, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHREF02.REFERENZ_VERSION, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHREF02.REST, ' '), 100) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_HREF02";

  /**
  * Description
  *    Inserting a row of HCTI01 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_HCTI01(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aHCTI01      in tHCTI01
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'HCTI01';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('HCTI01', 6) ||
      cStepcomSep ||
      rpad(nvl(aHCTI01.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHCTI01.ADRESSE_QUAL, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHCTI01.PARTNER_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHCTI01.KONTAKT_QUAL, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHCTI01.KONTAKT_ID, ' '), 17) ||
      cStepcomSep ||
      rpad(nvl(aHCTI01.KONTAKT_BEZ, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHCTI01.KONTAKT_TELEFON, ' '), 25) ||
      cStepcomSep ||
      rpad(nvl(aHCTI01.KONTAKT_TELEFAX, ' '), 25) ||
      cStepcomSep ||
      rpad(nvl(aHCTI01.KONTAKT_TELEX, ' '), 25) ||
      cStepcomSep ||
      rpad(nvl(aHCTI01.KONTAKT_EMAIL, ' '), 25) ||
      cStepcomSep ||
      rpad(nvl(aHCTI01.REST, ' '), 100) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_HCTI01";

  /**
  * Description
  *    Inserting a row of HTRS01 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_HTRS01(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aHTRS01      in tHTRS01
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'HTRS01';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('HTRS01', 6) ||
      cStepcomSep ||
      rpad(nvl(aHTRS01.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHTRS01.TRANSPORT_QUAL, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHTRS01.TRANSPORT_REF, ' '), 17) ||
      cStepcomSep ||
      rpad(nvl(aHTRS01.TRANSPORT_ART, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHTRS01.TRANSPORT_TYP, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHTRS01.TRANSPORTEUR, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHTRS01.ORT_QUAL, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHTRS01.ORT_ID, ' '), 25) ||
      cStepcomSep ||
      rpad(nvl(aHTRS01.ORT_ID_QUAL, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHTRS01.ORT_BEZ, ' '), 70) ||
      cStepcomSep ||
      rpad(nvl(aHTRS01.REST, ' '), 100) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_HTRS01";

  /**
  * Description
  *    Inserting a row of HMES01 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_HMES01(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aHMES01      in tHMES01
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'HMES01';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('HMES01', 6) ||
      cStepcomSep ||
      rpad(nvl(aHMES01.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aHMES01.AUSSTATT_QUAL, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHMES01.MASS_QUALIFIER, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHMES01.MASS_ANGABE, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHMES01.MASS_DEFINITION, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHMES01.MASS_EINHEIT_1, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHMES01.ANZAHL_EINHEITEN_1, ' '), 18) ||
      cStepcomSep ||
      rpad(nvl(aHMES01.MASS_EINHEIT_2, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHMES01.ANZAHL_EINHEITEN_2, ' '), 18) ||
      cStepcomSep ||
      rpad(nvl(aHMES01.MASS_EINHEIT_3, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aHMES01.ANZAHL_EINHEITEN_3, ' '), 18) ||
      cStepcomSep ||
      rpad(nvl(aHMES01.REST, ' '), 100) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_HMES01";

  /**
  * Description
  *    Inserting a row of DSEQ01 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_DSEQ01(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aDSEQ01      in tDSEQ01
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'DSEQ01';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('DSEQ01', 6) ||
      cStepcomSep ||
      rpad(nvl(aDSEQ01.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDSEQ01.SEQUENZ_NR, ' '), 12) ||
      cStepcomSep ||
      rpad(nvl(aDSEQ01.EBENE_NR, ' '), 12) ||
      cStepcomSep ||
      rpad(nvl(aDSEQ01.REST, ' '), 100) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_DSEQ01";

  /**
  * Description
  *    Inserting a row of DPKI01 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_DPKI01(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aDPKI01      in tDPKI01
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'DPKI01';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('DPKI01', 6) ||
      cStepcomSep ||
      rpad(nvl(aDPKI01.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDPKI01.VERPACKUNG_ANZ, ' '), 8) ||
      cStepcomSep ||
      rpad(nvl(aDPKI01.VERPACKUNG_EBENE, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDPKI01.VERPACKUNG_INFO, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDPKI01.VERPACKUNG_CODE, ' '), 17) ||
      cStepcomSep ||
      rpad(nvl(aDPKI01.VERPACKUNG_CODE_ID, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDPKI01.VERPACKUNG_TEXT, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDPKI01.REST, ' '), 100) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_DPKI01";

  /**
  * Description
  *    Inserting a row of DMES01 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_DMES01(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aDMES01      in tDMES01
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'DMES01';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('DMES01', 6) ||
      cStepcomSep ||
      rpad(nvl(aDMES01.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDMES01.MASS_QUALIFIER, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDMES01.MASS_ANGABE, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDMES01.MASS_DEFINITION, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDMES01.MASS_EINHEIT, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDMES01.ANZAHL_MASSEINHEITEN, ' '), 18) ||
      cStepcomSep ||
      rpad(nvl(aDMES01.REST, ' '), 100) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_DMES01";

  /**
  * Description
  *    Inserting a row of DPID01 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_DPID01(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aDPID01      in tDPID01
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'DPID01';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('DPID01', 6) ||
      cStepcomSep ||
      rpad(nvl(aDPID01.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDPID01.MARKIERUNG_QUAL, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDPID01.IDENTIFIKATION_TYP_1, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDPID01.IDENTIFIKATION_NR_1, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDPID01.IDENTIFIKATION_TYP_2, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDPID01.IDENTIFIKATION_NR_2, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDPID01.IDENTIFIKATION_DAT_1, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDPID01.IDENTIFIKATION_DAT_2, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDPID01.REST, ' '), 100) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_DPID01";

  /**
  * Description
  *    Inserting a row of DPKI02 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_DPKI02(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aDPKI02      in tDPKI02
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'DPKI02';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('DPKI02', 6) ||
      cStepcomSep ||
      rpad(nvl(aDPKI02.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDPKI02.VERPACKUNG_ANZ, ' '), 8) ||
      cStepcomSep ||
      rpad(nvl(aDPKI02.VERPACKUNG_EBENE, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDPKI02.VERPACKUNG_INFO, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDPKI02.VERPACKUNG_ART, ' '), 17) ||
      cStepcomSep ||
      rpad(nvl(aDPKI02.VERPACKUNG_CODE, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDPKI02.VERPACKUNG_TEXT, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDPKI02.REST, ' '), 100) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_DPKI02";

  /**
  * Description
  *    Inserting a row of DDET01 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_DDET01(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aDDET01      in tDDET01
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'DDET01';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('DDET01', 6) ||
      cStepcomSep ||
      rpad(nvl(aDDET01.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDDET01.POSITION_NR, ' '), 6) ||
      cStepcomSep ||
      rpad(nvl(aDDET01.SUB_LINE_ARTIKEL_NR, ' '), 6) ||
      cStepcomSep ||
      rpad(nvl(aDDET01.KONFIGURATION_CODE, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDDET01.ARTIKEL_NR, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDDET01.ARTIKEL_TYP, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDDET01.REST, ' '), 100) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_DDET01";

  /**
  * Description
  *    Inserting a row of DAPI01 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_DAPI01(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aDAPI01      in tDAPI01
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'DAPI01';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('DAPI01', 6) ||
      cStepcomSep ||
      rpad(nvl(aDAPI01.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDAPI01.POSITION_NR, ' '), 6) ||
      cStepcomSep ||
      rpad(nvl(aDAPI01.PRODUKT_QUAL, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDAPI01.PRODUKT_ID_1, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDAPI01.PRODUKT_TYP_1, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDAPI01.PRODUKT_ID_2, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDAPI01.PRODUKT_TYP_2, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDAPI01.REST, ' '), 100) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_DAPI01";

  /**
  * Description
  *    Inserting a row of DITD01 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_DITD01(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aDITD01      in tDITD01
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'DITD01';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('DITD01', 6) ||
      cStepcomSep ||
      rpad(nvl(aDITD01.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDITD01.POSITION_NR, ' '), 6) ||
      cStepcomSep ||
      rpad(nvl(aDITD01.ARTIKEL_BEZ_QUAL, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDITD01.ARTIKEL_BEZ_CODE, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDITD01.ARTIKEL_BEZ_1, ' '), 70) ||
      cStepcomSep ||
      rpad(nvl(aDITD01.ARTIKEL_BEZ_2, ' '), 70) ||
      cStepcomSep ||
      rpad(nvl(aDITD01.ARTIKEL_BEZ_ID, ' '), 17) ||
      cStepcomSep ||
      rpad(nvl(aDITD01.REST, ' '), 82) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_DITD01";

  /**
  * Description
  *    Inserting a row of DIPR01 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_DIPR01(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aDIPR01      in tDIPR01
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'DIPR01';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('DIPR01', 6) ||
      cStepcomSep ||
      rpad(nvl(aDIPR01.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDIPR01.POSITION_NR, ' '), 6) ||
      cStepcomSep ||
      rpad(nvl(aDIPR01.PREIS_QUAL, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDIPR01.PREIS, ' '), 14) ||
      cStepcomSep ||
      rpad(nvl(aDIPR01.PREIS_ART, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDIPR01.PREIS_DEF, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDIPR01.PREIS_BASIS, ' '), 9) ||
      cStepcomSep ||
      rpad(nvl(aDIPR01.PREIS_EINHEIT, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDIPR01.PREIS_SUBLINE_AEND, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDIPR01.PREIS_WAEHRUNG, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDIPR01.REST, ' '), 100) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_DIPR01";

  /**
  * Description
  *    Inserting a row of DMES02 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_DMES02(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aDMES02      in tDMES02
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'DMES02';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('DMES02', 6) ||
      cStepcomSep ||
      rpad(nvl(aDMES02.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDMES02.POSITION_NR, ' '), 6) ||
      cStepcomSep ||
      rpad(nvl(aDMES02.MASS_QUALIFIER, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDMES02.MASS_ANGABE, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDMES02.MASS_DEFINITION, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDMES02.MASS_EINHEIT, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDMES02.ANZAHL_MASSEINHEITEN, ' '), 18) ||
      cStepcomSep ||
      rpad(nvl(aDMES02.REST, ' '), 100) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_DMES02";

  /**
  * Description
  *    Inserting a row of DIQT01 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_DIQT01(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aDIQT01      in tDIQT01
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'DIQT01';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('DIQT01', 6) ||
      cStepcomSep ||
      rpad(nvl(aDIQT01.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDIQT01.POSITION_NR, ' '), 6) ||
      cStepcomSep ||
      rpad(nvl(aDIQT01.MENGE_QUAL, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDIQT01.MENGE, ' '), 14) ||
      cStepcomSep ||
      rpad(nvl(aDIQT01.MENGE_EINHEIT, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDIQT01.REST, ' '), 100) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_DIQT01";

  /**
  * Description
  *    Inserting a row of DDAT01 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_DDAT01(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aDDAT01      in tDDAT01
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'DDAT01';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('DDAT01', 6) ||
      cStepcomSep ||
      rpad(nvl(aDDAT01.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDDAT01.POSITION_NR, ' '), 6) ||
      cStepcomSep ||
      rpad(nvl(aDDAT01.DATUM_QUAL, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDDAT01.DATUM, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDDAT01.DATUM_FORMAT, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDDAT01.REST, ' '), 100) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_DDAT01";

  /**
  * Description
  *    Inserting a row of DREF01 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_DREF01(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aDREF01      in tDREF01
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'DREF01';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('DREF01', 6) ||
      cStepcomSep ||
      rpad(nvl(aDREF01.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDREF01.POSITION_NR, ' '), 6) ||
      cStepcomSep ||
      rpad(nvl(aDREF01.REFERENZ_QUAL, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDREF01.REFERENZ_NR, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDREF01.REFERENZ_POS, ' '), 6) ||
      cStepcomSep ||
      rpad(nvl(aDREF01.REFERENZ_DAT_1, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDREF01.REFERENZ_DAT_2, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDREF01.REST, ' '), 100) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_DREF01";

  /**
  * Description
  *    Inserting a row of DPID02 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_DPID02(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aDPID02      in tDPID02
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'DPID02';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('DPID02', 6) ||
      cStepcomSep ||
      rpad(nvl(aDPID02.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDPID02.POSITION_NR, ' '), 6) ||
      cStepcomSep ||
      rpad(nvl(aDPID02.MARKIERUNG_QUAL, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDPID02.IDENTIFIKATION_TYP_1, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDPID02.IDENTIFIKATION_NR_1, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDPID02.IDENTIFIKATION_TYP_2, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDPID02.IDENTIFIKATION_NR_2, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDPID02.IDENTIFIKATION_DAT_1, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDPID02.IDENTIFIKATION_DAT_2, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDPID02.REST, ' '), 100) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_DPID02";

  /**
  * Description
  *    Inserting a row of DVAR01 type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_DVAR01(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aDVAR01      in tDVAR01
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'DVAR01';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('DVAR01', 6) ||
      cStepcomSep ||
      rpad(nvl(aDVAR01.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDVAR01.POSITION_NR, ' '), 6) ||
      cStepcomSep ||
      rpad(nvl(aDVAR01.MENGE, ' '), 14) ||
      cStepcomSep ||
      rpad(nvl(aDVAR01.MENGE_QUAL, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDVAR01.DISKREPANZ_CODE, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDVAR01.AENDERUNGSGRUND_CODE, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDVAR01.AENDERUNGSGRUND_QUAL, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDVAR01.AENDERUNGSGRUND_TEXT, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDVAR01.LIEFERDATUM, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aDVAR01.LIEFERDATUM_FORMAT, ' '), 3) ||
      cStepcomSep ||
      rpad(nvl(aDVAR01.REST, ' '), 100) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_DVAR01";

  /**
  * Description
  *    Inserting a row of ENDREC type in the table DOC_EDI_EXPORT_JOB_DATA
  */
  procedure WRITE_ENDREC(
    aExportJobId in DOC_EDI_EXPORT_JOB.DOC_EDI_EXPORT_JOB_ID%type
  , aJoinKey     in DOC_EDI_EXPORT_JOB_DATA.DED_JOIN_KEY%type
  , aENDREC      in tENDREC
  )
  is
    vTplEdiJobData DOC_EDI_EXPORT_JOB_DATA%rowtype;
  begin
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_DATA_ID  := getNewId;
    vTplEdiJobData.C_EDI_JOB_DATA_STATUS       := 'OK';
    vTplEdiJobData.DOC_EDI_EXPORT_JOB_ID       := aExportJobId;
    vTplEdiJobData.DED_TAG                     := 'ENDREC';
    vTplEdiJobData.DED_JOIN_KEY                := aJoinKey;
    vTplEdiJobData.DED_VALUE                   :=
      vTplEdiJobData.DED_VALUE ||
      rpad('ENDREC', 6) ||
      cStepcomSep ||
      rpad(nvl(aENDREC.DOKUMENT_ID, ' '), 35) ||
      cStepcomSep ||
      rpad(nvl(aENDREC.NPOSITION, ' '), 6) ||
      cStepcomSep ||
      rpad(nvl(aENDREC.NRECORD, ' '), 6) ||
      cStepcomSep ||
      rpad(nvl(aENDREC.REST, ' '), 50) ||
      '@';

    insert into DOC_EDI_EXPORT_JOB_DATA
         values vTplEdiJobData;
  end "WRITE_ENDREC";
end DOC_EDI_SC_LIEF_D96A;
