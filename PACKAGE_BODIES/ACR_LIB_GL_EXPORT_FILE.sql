--------------------------------------------------------
--  DDL for Package Body ACR_LIB_GL_EXPORT_FILE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACR_LIB_GL_EXPORT_FILE" 
is
  /**
  * procedure IsTaxSourceListDefined
  * description :
  *    Indique si le fichier xml a été généré dans la base
  * @created rba 06.10.2014
  * @public
  * @return 0 : Le fichier xml n'a pas encore été généré
  *         1 : Le fichier xml a été généré
  */
  function HasXmlData(iGLExportFileId in ACR_GL_EXPORT_FILE.ACR_GL_EXPORT_FILE_ID%type)
    return integer
  is
    lnResult integer;
  begin
    select sign(count(*) )
      into lnResult
      from ACR_GL_EXPORT_FILE
     where ACR_GL_EXPORT_FILE_ID = iGLExportFileId
       and DBMS_LOB.getlength(AGF_XML) > 0;

    return lnResult;
  end HasXmlData;

  /**
  * Description :
  *   Retourne le fichier xml généré
  */
  function GetXmlData(iGLExportFileId in ACR_GL_EXPORT_FILE.ACR_GL_EXPORT_FILE_ID%type)
    return clob
  is
    lResult clob;
  begin
    if HasXmlData(iGLExportFileId) = 0 then
      lResult  := null;
    else
      select AGF_XML
        into lResult
        from ACR_GL_EXPORT_FILE
       where ACR_GL_EXPORT_FILE_ID = iGLExportFileId;
    end if;

    return lResult;
  end GetXmlData;

  /**
   * Retourne le fichier xml généré sous forme de blob avec un encoding iCSID
   */
  procedure GetXmlData(oBLOBData in out blob, iGLExportFileId in ACR_GL_EXPORT_FILE.ACR_GL_EXPORT_FILE_ID%type, iCSID in number)
  is
    lTempBLOB                  blob;
    lTempCLOB                  clob;
    lnDest_offset              integer;
    lnSrc_offset               integer;
    lnLang_ctx                 integer;
    lnWarning                  varchar2(1000);
  begin
    lTempCLOB := ReplaceXmlEncoding(GetXmlData(iGLExportFileId), iCSID);
    if lTempCLOB is not null then
      lnDest_offset  := 1;
      lnSrc_offset   := 1;
      lnLang_ctx     := DBMS_LOB.default_lang_ctx;
      DBMS_LOB.converttoblob(oBLOBData
                           , lTempCLOB
                           , DBMS_LOB.LOBMAXSIZE
                           , lnDest_offset
                           , lnSrc_offset
                           , iCSID
                           , lnLang_ctx
                           , lnWarning
                            );
    end if;
  end GetXmlData;

  /**
   * Remplace le champs encoding d'un xml contenu dans un clob par celui du csid en paramètre.
   */
  function ReplaceXmlEncoding(iXml in clob, iCSID in number)
    return clob
  is
    sEncoding varchar2(200);
  begin
    if iCSID <> DBMS_LOB.default_csid then
      if NLS_CHARSET_NAME(iCSID) = 'UTF8' then
        sEncoding := 'UTF-8';
      elsif REGEXP_INSTR(NLS_CHARSET_NAME(iCSID), 'WE8(ISO)(\d+)P(\d+)', 1, 1, 0, 'i') = 1 then
        sEncoding := REGEXP_REPLACE(NLS_CHARSET_NAME(iCSID), 'WE8(ISO)(\d+)P(\d+)', '\1-\2-\3');
      else
        return iXml;
      end if;
      -- REGEXP_REPLACE(NLS_CHARSET_NAME(iCSID),'WE8(MSWIN)(\d+)', 'windows-\2')
      return REGEXP_REPLACE(iXml, '(<\?.*encoding=")(.+)(".*\?>)', '\1'||sEncoding||'\3', 1, 1, 'i');
    else
      return iXml;
    end if;
  end ReplaceXmlEncoding;

end ACR_LIB_GL_EXPORT_FILE;
