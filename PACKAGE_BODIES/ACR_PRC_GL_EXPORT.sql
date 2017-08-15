--------------------------------------------------------
--  DDL for Package Body ACR_PRC_GL_EXPORT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACR_PRC_GL_EXPORT" 
is
  /**
  * Description
  *   Copie de l'enregistrement actif de l'export du Grand-Livre
  */
  procedure DuplicateActiveRecord(iRefId out number, oCurrentId out number)
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    select init_id_seq.nextval
         , (select nvl(max(ACR_GL_EXPORT_ID), 0)
              from ACR_GL_EXPORT
             where C_GL_EXPORT_STATUS = '1')   --Un seul statut actif
      into oCurrentId
         , iRefId
      from dual;

    if iRefId = 0 then
      oCurrentId  := 0.0;
      return;
    end if;

    --Copie sans la valeur XML et avec statut actif
    for tplActiveRecord in (select ACS_FINANCIAL_YEAR_ID
                                 , AGE_PERIOD_FROM_ID
                                 , AGE_PERIOD_TO_ID
                                 , AGE_WITH_TRANSFER
                                 , AGE_ACR_CG
                                 , AGE_ACR_REC
                                 , AGE_ACR_PAY
                                 , AGE_JOURNAL_BRO
                                 , AGE_TYPE_CUMUL_EXT
                                 , AGE_TYPE_CUMUL_INT
                                 , AGE_TYPE_CUMUL_PRE
                                 , AGE_TYPE_CUMUL_ENG
                                 , C_GL_EXPORT_VER
                                 , C_TAXPAYER_TYPE
                                 , C_FILE_GRANULARITY
                                 , AGE_RECEIVER_EMAIL
                                 , '1' C_GL_EXPORT_STATUS
                              from ACR_GL_EXPORT
                             where ACR_GL_EXPORT_ID = iRefId) loop
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACR_ENTITY.gcAcrGLExport, lt_crud_def);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACR_GL_EXPORT_ID', oCurrentId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_FINANCIAL_YEAR_ID', tplActiveRecord.ACS_FINANCIAL_YEAR_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'AGE_PERIOD_FROM_ID', tplActiveRecord.AGE_PERIOD_FROM_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'AGE_PERIOD_TO_ID', tplActiveRecord.AGE_PERIOD_TO_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'AGE_WITH_TRANSFER', tplActiveRecord.AGE_WITH_TRANSFER);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'AGE_ACR_CG', tplActiveRecord.AGE_ACR_CG);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'AGE_ACR_REC', tplActiveRecord.AGE_ACR_REC);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'AGE_ACR_PAY', tplActiveRecord.AGE_ACR_PAY);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'AGE_JOURNAL_BRO', tplActiveRecord.AGE_JOURNAL_BRO);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'AGE_TYPE_CUMUL_EXT', tplActiveRecord.AGE_TYPE_CUMUL_EXT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'AGE_TYPE_CUMUL_INT', tplActiveRecord.AGE_TYPE_CUMUL_INT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'AGE_TYPE_CUMUL_PRE', tplActiveRecord.AGE_TYPE_CUMUL_PRE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'AGE_TYPE_CUMUL_ENG', tplActiveRecord.AGE_TYPE_CUMUL_ENG);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'C_GL_EXPORT_VER', tplActiveRecord.C_GL_EXPORT_VER);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'C_TAXPAYER_TYPE', tplActiveRecord.C_TAXPAYER_TYPE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'C_FILE_GRANULARITY', tplActiveRecord.C_FILE_GRANULARITY);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'AGE_RECEIVER_EMAIL', tplActiveRecord.AGE_RECEIVER_EMAIL);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'C_GL_EXPORT_STATUS', tplActiveRecord.C_GL_EXPORT_STATUS);
      FWK_I_MGT_ENTITY.InsertEntity(lt_crud_def);
      FWK_I_MGT_ENTITY.Release(lt_crud_def);
    end loop;
  end DuplicateActiveRecord;

  /**
  * Description :
  *   Mise à jour du statut dans la table
  */
  procedure SetStatusState(inGLExportId in number, iStatusState in varchar2)
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACR_ENTITY.gcAcrGLExport, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACR_GL_EXPORT_ID', inGLExportId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'C_GL_EXPORT_STATUS', iStatusState);
    FWK_I_MGT_ENTITY.UpdateEntity(lt_crud_def);
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end SetStatusState;

  /**
  * Description
  *     Création d'un nouvel enregistrement de fichier d'export du Grand-Livre
  */
  procedure CreateGLExportFile(
    inGLExportId   in ACR_GL_EXPORT_FILE.ACR_GL_EXPORT_ID%type
  , inFinYearId    in ACR_GL_EXPORT_FILE.ACS_FINANCIAL_YEAR_ID%type
  , inPeriodFromId in ACR_GL_EXPORT_FILE.AGF_PERIOD_FROM_ID%type
  , inPeriodToId   in ACR_GL_EXPORT_FILE.AGF_PERIOD_TO_ID%type
  , ivPartNum      in ACR_GL_EXPORT_FILE.AGF_PART_NUM%type
  , icXmlData      in ACR_GL_EXPORT_FILE.AGF_XML%type
  , ivXmlPath      in ACR_GL_EXPORT_FILE.AGF_XML_PATH%type
  )
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACR_ENTITY.gcAcrGLExportFile, ltCRUD_DEF);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACR_GL_EXPORT_FILE_ID', INIT_ID_SEQ.nextval);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACR_GL_EXPORT_ID', inGLExportId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_FINANCIAL_YEAR_ID', inFinYearId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'AGF_PERIOD_FROM_ID', inPeriodFromId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'AGF_PERIOD_TO_ID', inPeriodToId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'AGF_PART_NUM', ivPartNum);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'AGF_XML', icXmlData);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'AGF_XML_PATH', ivXmlPath);
    FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end CreateGLExportFile;

  /**
  * Description
  *     Suppression des fichiers d'export du Grand-Livre courant
  */
  procedure DeleteGLExportFile(inGLExportId in ACR_GL_EXPORT_FILE.ACR_GL_EXPORT_ID%type)
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    for tplGLExportFile in (select ACR_GL_EXPORT_FILE_ID
                              from ACR_GL_EXPORT_FILE
                             where ACR_GL_EXPORT_ID = inGLExportId) loop
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACR_ENTITY.gcAcrGLExportFile, ltCRUD_DEF);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACR_GL_EXPORT_FILE_ID', tplGLExportFile.ACR_GL_EXPORT_FILE_ID);
      FWK_I_MGT_ENTITY.DeleteEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    end loop;
  end DeleteGLExportFile;

  /**
  * Description :
  *   Mise à jour du champ XML
  */
  procedure SetXmlData(inGLExportFileId in number, iXmlData in clob)
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACR_ENTITY.gcAcrGLExportFile, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACR_GL_EXPORT_FILE_ID', inGLExportFileId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'AGF_XML', iXmlData);
    FWK_I_MGT_ENTITY.UpdateEntity(lt_crud_def);
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end SetXmlData;

  /**
  * Description :
  *   Mise à jour du chemin du du fichier XML
  */
  procedure SetXMLPath(inGLExportFileId in number, ivPath in varchar2)
  is
    lt_crud_def FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACR_ENTITY.gcAcrGLExportFile, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACR_GL_EXPORT_FILE_ID', inGLExportFileId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'AGF_XML_PATH', ivPath);
    FWK_I_MGT_ENTITY.UpdateEntity(lt_crud_def);
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end SetXMLPath;
end ACR_PRC_GL_EXPORT;
