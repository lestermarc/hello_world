--------------------------------------------------------
--  DDL for Package Body ACR_PRC_SOCIAL_BREAKDOWN
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACR_PRC_SOCIAL_BREAKDOWN" 
is

  /**
  * Description
  *   Copie de l'enregistrement actif du décompte social
  */
  procedure DuplicateActiveRecord(iRefId out number, oCurrentId out number)
  is
    lt_crud_def   FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    select init_id_seq.nextval
         , (select nvl(max(ACR_SOCIAL_BREAKDOWN_ID), 0) from ACR_SOCIAL_BREAKDOWN  where C_SOC_BREAKDOWN_STATUS = '1')   --Un seul statut actif
    into oCurrentId
       , iRefId
    from dual;

    if iRefId = 0 then
      oCurrentId := 0.0;
      Return;
    end if;

      --Copie sans la valeur XML et avec statut actif
    for tplActiveRecord in (select ACS_FINANCIAL_YEAR_ID
                           , ASB_MUNICIPALITY_NUMBER
                           , ASB_MUNICIPALITY_AFFILIATED
                           , ASB_RECEIVER_EMAIL
                           , ASB_COMMENT
                           , null ASB_XML
                           , ACR_LIB_EDO.GetDirectory(ASB_XML_PATH) ASB_XML_PATH
                           , '1' C_SOC_BREAKDOWN_STATUS
                      from ACR_SOCIAL_BREAKDOWN
                     where ACR_SOCIAL_BREAKDOWN_ID = iRefId) loop
      FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACR_ENTITY.gcAcrSocialBreakDown, lt_crud_def);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACR_SOCIAL_BREAKDOWN_ID', oCurrentId);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACS_FINANCIAL_YEAR_ID', tplActiveRecord.ACS_FINANCIAL_YEAR_ID);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ASB_MUNICIPALITY_NUMBER', tplActiveRecord.ASB_MUNICIPALITY_NUMBER);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ASB_MUNICIPALITY_AFFILIATED', tplActiveRecord.ASB_MUNICIPALITY_AFFILIATED);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ASB_RECEIVER_EMAIL', tplActiveRecord.ASB_RECEIVER_EMAIL);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ASB_COMMENT', tplActiveRecord.ASB_COMMENT);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ASB_XML', tplActiveRecord.ASB_XML);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ASB_XML_PATH', tplActiveRecord.ASB_XML_PATH);
      FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'C_SOC_BREAKDOWN_STATUS', tplActiveRecord.C_SOC_BREAKDOWN_STATUS);
      FWK_I_MGT_ENTITY.InsertEntity(lt_crud_def);
      FWK_I_MGT_ENTITY.Release(lt_crud_def);
    end loop;
  end;

  /**
  * Description :
  *   Mise à jour du statut dans la table
  */
  procedure SetStatusState(iCurrentId in number , iStatusState in varchar2)
  is
    lt_crud_def   FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACR_ENTITY.gcAcrSocialBreakDown, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACR_SOCIAL_BREAKDOWN_ID', iCurrentId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'C_SOC_BREAKDOWN_STATUS', iStatusState);
    FWK_I_MGT_ENTITY.UpdateEntity(lt_crud_def);
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end SetStatusState;


  /**
  * Description :
  *   Mise à jour du champ XML
  */
  procedure SetXmlData(iCurrentId in number , iXmlData in Clob)
  is
    lt_crud_def   FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACR_ENTITY.gcAcrSocialBreakDown, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACR_SOCIAL_BREAKDOWN_ID', iCurrentId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ASB_XML', iXmlData);
    FWK_I_MGT_ENTITY.UpdateEntity(lt_crud_def);
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end SetXmlData;

  /**
  * Description :
  *   Mise à jour du chemin du du fichier XML
  */
  procedure SetXMLPath(iCurrentId in number , iPath in varchar2)
  is
    lt_crud_def   FWK_I_TYP_DEFINITION.T_CRUD_DEF;
  begin
    FWK_I_MGT_ENTITY.new(FWK_I_TYP_ACR_ENTITY.gcAcrSocialBreakDown, lt_crud_def);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ACR_SOCIAL_BREAKDOWN_ID', iCurrentId);
    FWK_I_MGT_ENTITY_DATA.SetColumn(lt_crud_def, 'ASB_XML_PATH', iPath);
    FWK_I_MGT_ENTITY.UpdateEntity(lt_crud_def);
    FWK_I_MGT_ENTITY.Release(lt_crud_def);
  end SetXMLPath;

end ACR_PRC_SOCIAL_BREAKDOWN;
