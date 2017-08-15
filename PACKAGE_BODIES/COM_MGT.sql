--------------------------------------------------------
--  DDL for Package Body COM_MGT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "COM_MGT" 
is
  /**
  * Description
  *    Insert of COM_IMAGE_FILES
  */
  function insertIMAGE_FILES(iot_crud_definition in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lvNameServer                    PCS.PC_CBASE.CBACVALUE%type;
    liIMF_SEQUENCE                  COM_IMAGE_FILES.IMF_SEQUENCE%type;
    lResult                         varchar2(40);
    lnRecId                         number;
    lvTabName                       varchar2(30);
  begin
    begin
      FWK_I_MGT_ENTITY_DATA.SetColumn(iot_crud_definition, 'IMF_CABINET'           , PCS.PC_I_LIB_SESSION.GetCompanyOwner);
      FWK_I_MGT_ENTITY_DATA.SetColumn(iot_crud_definition, 'IMF_DRAWER'           , FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iot_crud_definition , 'IMF_TABLE'));
      FWK_I_MGT_ENTITY_DATA.SetColumn(iot_crud_definition, 'IMF_FOLDER'            , TO_CHAR(SYSDATE,'YYYY_MM'));

      if  FWK_I_MGT_ENTITY_DATA.IsNull(iot_crud_definition, 'IMF_SEQUENCE')    then
        lnRecId                         :=  FWK_I_MGT_ENTITY_DATA.GetColumnNumber (iot_crud_definition , 'IMF_REC_ID');
        lvTabName                   :=  FWK_I_MGT_ENTITY_DATA.GetColumnVarchar2(iot_crud_definition , 'IMF_TABLE');

        SELECT MAX (IMF_SEQUENCE) + 1
               into liIMF_SEQUENCE
        FROM  COM_IMAGE_FILES
        WHERE IMF_TABLE = lvTabName AND IMF_REC_ID = lnRecId;

        if liIMF_SEQUENCE is null then
          liIMF_SEQUENCE := 1;
        end if;
        FWK_I_MGT_ENTITY_DATA.SetColumn(iot_crud_definition, 'IMF_SEQUENCE'     , liIMF_SEQUENCE);
      end if;

      if FWK_I_MGT_ENTITY_DATA.IsNull(iot_crud_definition, 'IMF_IMAGE_INDEX')  then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iot_crud_definition, 'IMF_IMAGE_INDEX'     , 1);
      end if;

      if FWK_I_MGT_ENTITY_DATA.IsNull(iot_crud_definition, 'IMF_STORED_IN')  then
          lvNameServer                := PCS.PC_CONFIG.GetConfig('COM_ATT_STORAGE_TYPE');
          if lvNameServer     = 'ORACLE' then
             FWK_I_MGT_ENTITY_DATA.SetColumn(iot_crud_definition, 'IMF_STORED_IN'   , 'DB');
          else
             FWK_I_MGT_ENTITY_DATA.SetColumn(iot_crud_definition, 'IMF_STORED_IN'   , lvNameServer);
          end if;
      end if;

      if (FWK_TYP_COM_ENTITY.gttImageFiles(iot_crud_definition.entity_id).IMF_STORED_IN = 'HTTP') or
         (FWK_TYP_COM_ENTITY.gttImageFiles(iot_crud_definition.entity_id).IMF_STORED_IN = 'DB')  then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iot_crud_definition, 'IMF_LINKED_FILE'      , 1);
      elsif FWK_I_MGT_ENTITY_DATA.IsNull(iot_crud_definition, 'IMF_LINKED_FILE')  then
        FWK_I_MGT_ENTITY_DATA.SetColumn(iot_crud_definition, 'IMF_LINKED_FILE'      , 1);
      end if;

    end;

    /***********************************
    ** insert record in table
    ***********************************/
    lResult  := fwk_i_dml_table.CRUD(iot_crud_definition);

    return lResult;
  end insertIMAGE_FILES;

  /**
  * Update of COM_IMAGE_FILES
  */
  function updateIMAGE_FILES(iot_crud_definition in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    /***********************************
    ** Update record in table
    ***********************************/
    lResult  := fwk_i_dml_table.CRUD(iot_crud_definition);
    return lResult;
  end updateIMAGE_FILES;

  /**
  * Delete of COM_IMAGE_FILES
  */
  function deleteIMAGE_FILES(iot_crud_definition in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  is
    lResult varchar2(40);
  begin
    /***********************************
    ** Delete record in table
    ***********************************/
    lResult  := fwk_i_dml_table.CRUD(iot_crud_definition);
    return lResult;
  end deleteIMAGE_FILES;

  /**
  * Delete of COM_EBANKING
  */
  function deleteCOM_EBANKING(iot_crud_definition in out nocopy fwk_i_typ_definition.t_crud_def)
    return varchar2
  as
    lResult varchar2(40);
  begin
    -- Delete children
    COM_PRC_EBANKING_FILES.DeleteEBPPFile(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_crud_definition, 'COM_EBANKING_ID') );
    COM_PRC_EBANKING_DET.DeleteEBPPDetail(FWK_I_MGT_ENTITY_DATA.GetColumnNumber(iot_crud_definition, 'COM_EBANKING_ID') );
    lResult  := fwk_i_dml_table.CRUD(iot_crud_definition);
    return lResult;
  end deleteCOM_EBANKING;
end COM_MGT;
