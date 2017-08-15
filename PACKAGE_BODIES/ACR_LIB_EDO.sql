--------------------------------------------------------
--  DDL for Package Body ACR_LIB_EDO
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACR_LIB_EDO" 
is
  /**
  * Description :
  *   Retourne le répertoire sans le nom de fichier
  */
  function GetDirectory(iEDO_XML_PATH in ACR_EDO.EDO_XML_PATH%type)
    return ACR_EDO.EDO_XML_PATH%type
  is
    lvResult ACR_EDO.EDO_XML_PATH%type;
  begin
    select case
             when(instr(upper(iEDO_XML_PATH), '.XML') > 0)
             and (instr(iEDO_XML_PATH, '\') > 0) then   -- Parse string for Windows system
                                                     substr(iEDO_XML_PATH, 1,(instr(iEDO_XML_PATH, '\', -1, 1) ) )
             when(instr(upper(iEDO_XML_PATH), '.XML') > 0)
             and (instr(iEDO_XML_PATH, '/') > 0) then   -- Parse string for UNIX system
                                                     substr(iEDO_XML_PATH, 1,(instr(iEDO_XML_PATH, '/', -1, 1) ) )
             else iEDO_XML_PATH
           end EDO_XML_PATH
      into lvResult
      from dual;

    return lvResult;
  end GetDirectory;

  /**
  * Description :
  *   Copie du dernier record historié
  */
  procedure DuplicateLastRecord(oACR_EDO_ID out ACR_EDO.ACR_EDO_ID%type)
  is
    lnHIST_ACR_EDO_ID ACR_EDO.ACR_EDO_ID%type;
    ltCRUD_DEF        FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    select init_id_seq.nextval
         , (select nvl(max(ACR_EDO_ID), 0)
              from ACR_EDO
             where C_EDO_STATUS = '1')   --Un seul statut actif
      into oACR_EDO_ID
         , lnHIST_ACR_EDO_ID
      from dual;

    if lnHIST_ACR_EDO_ID = 0 then
      oACR_EDO_ID  := 0;
      return;
    end if;

    --Copie sans la valeur XML et avec statut actif
    for tplAcrEdo in (select oACR_EDO_ID ACR_EDO_ID
                           , ACS_FINANCIAL_YEAR_ID
                           , PC_LANG_ID
                           , C_EDO_CANTON
                           , C_EDO_CONTACT_TITLE
                           , C_EDO_ACCOUNTING_MODEL
                           , C_EDO_ACCOUNTING_TYPE
                           , '1' C_EDO_STATUS
                           , EDO_MUNICIPALITY_NUMBER
                           , EDO_MUNICIPALITY_NAME
                           , EDO_CONTACT_NAME
                           , EDO_CONTACT_FORENAME
                           , EDO_CONTACT_AUTHORITIES
                           , EDO_CONTACT_POSITION
                           , EDO_CONTACT_STREET
                           , EDO_CONTACT_ZIPCODE
                           , EDO_CONTACT_CITY
                           , EDO_CONTACT_TEL
                           , EDO_CONTACT_EMAIL
                           , EDO_CURRENT_YEAR_DATAS
                           , EDO_PREVIOUS_YEAR_DATAS
                           , EDO_BUDGET_DATAS
                           , EDO_COMMENT
                           , EDO_RECEIVER_EMAIL
                           , null EDO_XML
                           , GetDirectory(EDO_XML_PATH) EDO_XML_PATH
                        from ACR_EDO
                       where ACR_EDO_ID = lnHIST_ACR_EDO_ID) loop
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACR_ENTITY.gcAcrEdo, ltCRUD_DEF);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACR_EDO_ID', tplAcrEdo.ACR_EDO_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACS_FINANCIAL_YEAR_ID', tplAcrEdo.ACS_FINANCIAL_YEAR_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'PC_LANG_ID', tplAcrEdo.PC_LANG_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_EDO_CANTON', tplAcrEdo.C_EDO_CANTON);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_EDO_CONTACT_TITLE', tplAcrEdo.C_EDO_CONTACT_TITLE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_EDO_ACCOUNTING_MODEL', tplAcrEdo.C_EDO_ACCOUNTING_MODEL);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_EDO_ACCOUNTING_TYPE', tplAcrEdo.C_EDO_ACCOUNTING_TYPE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_EDO_STATUS', tplAcrEdo.C_EDO_STATUS);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDO_MUNICIPALITY_NUMBER', tplAcrEdo.EDO_MUNICIPALITY_NUMBER);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDO_MUNICIPALITY_NAME', tplAcrEdo.EDO_MUNICIPALITY_NAME);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDO_CONTACT_NAME', tplAcrEdo.EDO_CONTACT_NAME);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDO_CONTACT_FORENAME', tplAcrEdo.EDO_CONTACT_FORENAME);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDO_CONTACT_AUTHORITIES', tplAcrEdo.EDO_CONTACT_AUTHORITIES);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDO_CONTACT_POSITION', tplAcrEdo.EDO_CONTACT_POSITION);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDO_CONTACT_STREET', tplAcrEdo.EDO_CONTACT_STREET);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDO_CONTACT_ZIPCODE', tplAcrEdo.EDO_CONTACT_ZIPCODE);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDO_CONTACT_CITY', tplAcrEdo.EDO_CONTACT_CITY);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDO_CONTACT_TEL', tplAcrEdo.EDO_CONTACT_TEL);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDO_CONTACT_EMAIL', tplAcrEdo.EDO_CONTACT_EMAIL);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDO_CURRENT_YEAR_DATAS', tplAcrEdo.EDO_CURRENT_YEAR_DATAS);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDO_PREVIOUS_YEAR_DATAS', tplAcrEdo.EDO_PREVIOUS_YEAR_DATAS);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDO_BUDGET_DATAS', tplAcrEdo.EDO_BUDGET_DATAS);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDO_COMMENT', tplAcrEdo.EDO_COMMENT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDO_RECEIVER_EMAIL', tplAcrEdo.EDO_RECEIVER_EMAIL);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDO_XML', tplAcrEdo.EDO_XML);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDO_XML_PATH', tplAcrEdo.EDO_XML_PATH);
      FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    end loop;

    --Table des interactions de fonctionnement
    for tplAcrEdo in (select oACR_EDO_ID ACR_EDO_ID
                           , EDW_TASK
                        from ACR_EDO_WO
                       where ACR_EDO_ID = lnHIST_ACR_EDO_ID) loop
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACR_ENTITY.gcAcrEdoWo, ltCRUD_DEF);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACR_EDO_ID', tplAcrEdo.ACR_EDO_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDW_TASK', tplAcrEdo.EDW_TASK);
      FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    end loop;

    --Table des interactions des investissements
    for tplAcrEdo in (select oACR_EDO_ID ACR_EDO_ID
                           , EDI_TASK
                        from ACR_EDO_IN
                       where ACR_EDO_ID = lnHIST_ACR_EDO_ID) loop
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACR_ENTITY.gcAcrEdoIn, ltCRUD_DEF);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACR_EDO_ID', tplAcrEdo.ACR_EDO_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDI_TASK', tplAcrEdo.EDI_TASK);
      FWK_I_MGT_ENTITY.InsertEntity(ltCRUD_DEF);
      FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
    end loop;

    --Changer le statut du record encore actif => le passer à historié
    ChangeStatus(lnHIST_ACR_EDO_ID, '2');
  end DuplicateLastRecord;

  /**
  * Description :
  *   Mise à jour du statut dans la table
  */
  procedure ChangeStatus(iACR_EDO_ID in ACR_EDO.ACR_EDO_ID%type, iC_EDO_STATUS in ACR_EDO.C_EDO_STATUS%type)
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACR_ENTITY.gcAcrEdo, ltCRUD_DEF);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACR_EDO_ID', iACR_EDO_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'C_EDO_STATUS', iC_EDO_STATUS);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end ChangeStatus;

  /**
  * Description :
  *   Sauvegarde du nom de fichier
  */
  procedure SaveFilePath(iACR_EDO_ID in ACR_EDO.ACR_EDO_ID%type, iEDO_XML_PATH in ACR_EDO.EDO_XML_PATH%type)
  is
    ltCRUD_DEF FWK_I_TYP_DEFINITION.t_crud_def;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACR_ENTITY.gcAcrEdo, ltCRUD_DEF);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACR_EDO_ID', iACR_EDO_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDO_XML_PATH', iEDO_XML_PATH);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end SaveFilePath;

  /**
  * Description :
  *   Sauvegarde du document XML
  */
  procedure SaveXMLDocument(iACR_EDO_ID in ACR_EDO.ACR_EDO_ID%type, iEDO_XML in ACR_EDO.EDO_XML%type)
  is
    ltCRUD_DEF     FWK_I_TYP_DEFINITION.t_crud_def;
    lvEDO_XML_PATH ACR_EDO.EDO_XML_PATH%type;
  begin
    -- Lors de la mise à jour du document xml, suppression du nom de fichier de EDO_XML_PATH
    select case
             when(instr(EDO_XML_PATH, '.xml') > 0)
             and (instr(EDO_XML_PATH, '\') > 0) then   -- Parse string for Windows system
                                                    substr(EDO_XML_PATH, 1,(instr(EDO_XML_PATH, '\', -1, 1) - 1) )
             when(instr(EDO_XML_PATH, '.xml') > 0)
             and (instr(EDO_XML_PATH, '/') > 0) then   -- Parse string for UNIX system
                                                    substr(EDO_XML_PATH, 1,(instr(EDO_XML_PATH, '/', -1, 1) - 1) )
             else EDO_XML_PATH
           end EDO_XML_PATH
      into lvEDO_XML_PATH
      from ACR_EDO
     where ACR_EDO_ID = iACR_EDO_ID;

    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACR_ENTITY.gcAcrEdo, ltCRUD_DEF);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'ACR_EDO_ID', iACR_EDO_ID);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDO_XML', iEDO_XML);
    FWK_I_MGT_ENTITY_DATA.SetColumn(ltCRUD_DEF, 'EDO_XML_PATH', lvEDO_XML_PATH);
    FWK_I_MGT_ENTITY.UpdateEntity(ltCRUD_DEF);
    FWK_I_MGT_ENTITY.Release(ltCRUD_DEF);
  end SaveXMLDocument;

end ACR_LIB_EDO;
