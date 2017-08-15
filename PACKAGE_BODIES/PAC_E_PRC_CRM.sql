--------------------------------------------------------
--  DDL for Package Body PAC_E_PRC_CRM
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_E_PRC_CRM" 
/**
* Package spécialisé pour la gestion des relations commerciales.
*
* @version 1.0
* @date 2011
* @author spfister
* @author skalayci
*
* Copyright 1997-2011 SolvAxis SA. Tous droits réservés.
*/
as
  --
  -- Internal declaration
  --
  EX_NOT_FOUND              exception;
  pragma exception_init(EX_NOT_FOUND, -20010);
  EX_NOT_FOUND_NUM constant binary_integer := -20010;

  function CreatePERSON(
    iv_DIC_PERSON_POLITNESS_ID in     varchar2 default null
  , iv_PER_NAME                in     varchar2
  , iv_PER_FORENAME            in     varchar2 default null
  , iv_PER_ACTIVITY            in     varchar2 default null
  , iv_PER_COMMENT             in     varchar2 default null
  , iv_PER_KEY1                in     varchar2 default null
  , iv_PER_KEY2                in     varchar2 default null
  , iv_DIC_FREE_CODE1_ID       in     varchar2 default null
  , iv_DIC_FREE_CODE2_ID       in     varchar2 default null
  , iv_DIC_FREE_CODE3_ID       in     varchar2 default null
  , iv_DIC_FREE_CODE4_ID       in     varchar2 default null
  , iv_DIC_FREE_CODE5_ID       in     varchar2 default null
  , iv_DIC_FREE_CODE6_ID       in     varchar2 default null
  , iv_DIC_FREE_CODE7_ID       in     varchar2 default null
  , iv_DIC_FREE_CODE8_ID       in     varchar2 default null
  , iv_DIC_FREE_CODE9_ID       in     varchar2 default null
  , iv_DIC_FREE_CODE10_ID      in     varchar2 default null
  , iv_PER_SHORT_NAME          in     varchar2 default null
  , in_PER_CONTACT             in     number default 0
  , iv_C_PARTNER_STATUS        in     varchar2 default '1'
  , ov_PER_KEY1                out    varchar2
  , in_PAC_PERSON_ID           in     number default null
  )
    return pac_person.pac_person_id%type
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
    ln_result   pac_person.pac_person_id%type;
  begin
    --Initialisation entité PAC_PERSON
    fwk_i_mgt_entity.new(iv_entity_name => fwk_i_typ_pac_entity.gcPacPerson, iot_crud_definition => lt_crud_def);
    -- Affectation des valeurs
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_PERSON_ID', in_PAC_PERSON_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PERSON_POLITNESS_ID', iv_DIC_PERSON_POLITNESS_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PER_NAME', iv_PER_NAME);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PER_FORENAME', iv_PER_FORENAME);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PER_ACTIVITY', iv_PER_ACTIVITY);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PER_COMMENT', iv_PER_COMMENT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PER_KEY1', iv_PER_KEY1);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PER_KEY2', iv_PER_KEY2);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_FREE_CODE1_ID', iv_DIC_FREE_CODE1_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_FREE_CODE2_ID', iv_DIC_FREE_CODE2_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_FREE_CODE3_ID', iv_DIC_FREE_CODE3_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_FREE_CODE4_ID', iv_DIC_FREE_CODE4_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_FREE_CODE5_ID', iv_DIC_FREE_CODE5_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_FREE_CODE6_ID', iv_DIC_FREE_CODE6_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_FREE_CODE7_ID', iv_DIC_FREE_CODE7_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_FREE_CODE8_ID', iv_DIC_FREE_CODE8_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_FREE_CODE9_ID', iv_DIC_FREE_CODE9_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_FREE_CODE10_ID', iv_DIC_FREE_CODE10_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PER_SHORT_NAME', iv_PER_SHORT_NAME);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PER_CONTACT', in_PER_CONTACT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_PARTNER_STATUS', iv_C_PARTNER_STATUS);
    --Ajout du record
    fwk_i_mgt_entity.InsertEntity(iot_crud_definition => lt_crud_def);
    --Récupération des valeurs de retour
    ln_result    := fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'PAC_PERSON_ID');
    ov_PER_KEY1  := fwk_i_mgt_entity_data.getcolumnvarchar2(lt_crud_def, 'PER_KEY1');
    --Libèration entité
    fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
    return ln_result;
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
      fwk_i_mgt_exception.raise_exception(in_error_code    => -20001
                                        , iv_message       => sqlerrm
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CreatePERSON'
                                         );
  end;

  procedure UpdatePERSON(
    in_PAC_PERSON_ID           in number
  , iv_DIC_PERSON_POLITNESS_ID in varchar2
  , iv_PER_NAME                in varchar2
  , iv_PER_FORENAME            in varchar2
  , iv_PER_ACTIVITY            in varchar2
  , iv_PER_COMMENT             in varchar2
  , iv_PER_KEY1                in varchar2
  , iv_PER_KEY2                in varchar2
  , iv_DIC_FREE_CODE1_ID       in varchar2
  , iv_DIC_FREE_CODE2_ID       in varchar2
  , iv_DIC_FREE_CODE3_ID       in varchar2
  , iv_DIC_FREE_CODE4_ID       in varchar2
  , iv_DIC_FREE_CODE5_ID       in varchar2
  , iv_DIC_FREE_CODE6_ID       in varchar2
  , iv_DIC_FREE_CODE7_ID       in varchar2
  , iv_DIC_FREE_CODE8_ID       in varchar2
  , iv_DIC_FREE_CODE9_ID       in varchar2
  , iv_DIC_FREE_CODE10_ID      in varchar2
  , iv_PER_SHORT_NAME          in varchar2
  , in_PER_CONTACT             in number
  , iv_C_PARTNER_STATUS        in varchar2
  )
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    --Initialisation entité PAC_PERSON
    fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_pac_entity.gcPacPerson
                       , iot_crud_definition   => lt_crud_def
                       , ib_initialize         => true
                       , in_main_id            => in_PAC_PERSON_ID
                        );

    if (lt_crud_def.row_id is null) then
      raise EX_NOT_FOUND;
    end if;

    -- Affectation des valeurs
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PERSON_POLITNESS_ID', iv_DIC_PERSON_POLITNESS_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PER_NAME', iv_PER_NAME);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PER_FORENAME', iv_PER_FORENAME);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PER_ACTIVITY', iv_PER_ACTIVITY);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PER_COMMENT', iv_PER_COMMENT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PER_KEY1', iv_PER_KEY1);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PER_KEY2', iv_PER_KEY2);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_FREE_CODE1_ID', iv_DIC_FREE_CODE1_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_FREE_CODE2_ID', iv_DIC_FREE_CODE2_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_FREE_CODE3_ID', iv_DIC_FREE_CODE3_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_FREE_CODE4_ID', iv_DIC_FREE_CODE4_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_FREE_CODE5_ID', iv_DIC_FREE_CODE5_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_FREE_CODE6_ID', iv_DIC_FREE_CODE6_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_FREE_CODE7_ID', iv_DIC_FREE_CODE7_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_FREE_CODE8_ID', iv_DIC_FREE_CODE8_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_FREE_CODE9_ID', iv_DIC_FREE_CODE9_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_FREE_CODE10_ID', iv_DIC_FREE_CODE10_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PER_SHORT_NAME', iv_PER_SHORT_NAME);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PER_CONTACT', in_PER_CONTACT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_PARTNER_STATUS', iv_C_PARTNER_STATUS);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'A_DATEMOD', Sysdate);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'A_IDMOD', pcs.PC_I_LIB_SESSION.GetUserIni);
    --Mise à jour de l'entité
    fwk_i_mgt_entity.UpdateEntity(iot_crud_definition => lt_crud_def);
    --Libèration entité
    fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if (sqlcode = EX_NOT_FOUND_NUM) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => sqlcode
                                          , iv_message       => '"' || to_char(in_PAC_PERSON_ID) || '" does not exists'
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdatePERSON'
                                           );
      else
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20002
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdatePERSON'
                                           );
      end if;
  end;

  procedure DeletePERSON(in_PAC_PERSON_ID in number)
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    --Initialisation entité PAC_PERSON
    fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_pac_entity.gcPacPerson
                       , iot_crud_definition   => lt_crud_def
                       , ib_initialize         => true
                       , in_main_id            => in_PAC_PERSON_ID
                        );

    if (lt_crud_def.row_id is not null) then
      fwk_i_mgt_entity.DeleteEntity(iot_crud_definition => lt_crud_def);
    else
      raise EX_NOT_FOUND;
    end if;
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if (sqlcode = EX_NOT_FOUND_NUM) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => sqlcode
                                          , iv_message       => '"' || to_char(in_PAC_PERSON_ID) || '" does not exists'
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeletePERSON'
                                           );
      else
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20003
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeletePERSON'
                                           );
      end if;
  end;

  function CreateADDRESS(
    in_PAC_PERSON_ID       in number default null
  , iv_CNTID               in varchar2 default null
  , iv_ADD_ADDRESS1        in varchar2 default null
  , iv_ADD_ZIPCODE         in varchar2 default null
  , iv_ADD_CITY            in varchar2 default null
  , iv_ADD_STATE           in varchar2 default null
  , iv_LANID               in varchar2 default null
  , iv_ADD_COMMENT         in varchar2 default null
  , iv_DIC_ADDRESS_TYPE_ID in varchar2 default null
  , id_ADD_SINCE           in date default null
  , iv_ADD_FORMAT          in varchar2 default null
  , in_ADD_PRINCIPAL       in number default 0
  , iv_C_PARTNER_STATUS    in varchar2 default '1'
  , in_ADD_PRIORITY        in number default null
  , iv_ADD_CARE_OF         in varchar2 default null
  , iv_ADD_PO_BOX          in varchar2 default null
  , in_ADD_PO_BOX_NBR      in number default null
  , iv_ADD_COUNTY          in varchar2 default null
  , in_PAC_ADDRESS_ID      in number default null
  )
    return pac_address.pac_address_id%type
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
    ln_result   pac_address.pac_address_id%type;
  begin
    --Initialisation entité PAC_PERSON
    fwk_i_mgt_entity.new(iv_entity_name => fwk_i_typ_pac_entity.gcPacAddress, iot_crud_definition => lt_crud_def);
    -- Affectation des valeurs
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_ADDRESS_ID', in_PAC_ADDRESS_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_PERSON_ID', in_PAC_PERSON_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PC_CNTRY_ID', PCS.PC_LIB_LOOKUP.getCNTRY(iv_CNTID) );
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_ADDRESS1', iv_ADD_ADDRESS1);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_ZIPCODE', iv_ADD_ZIPCODE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_CITY', iv_ADD_CITY);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_STATE', iv_ADD_STATE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PC_LANG_ID', PCS.PC_LIB_LOOKUP.getLANG(iv_LANID) );
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_COMMENT', iv_ADD_COMMENT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_ADDRESS_TYPE_ID', iv_DIC_ADDRESS_TYPE_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_SINCE', id_ADD_SINCE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_FORMAT', iv_ADD_FORMAT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_PRINCIPAL', in_ADD_PRINCIPAL);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_PARTNER_STATUS', iv_C_PARTNER_STATUS);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_PRIORITY', in_ADD_PRIORITY);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_CARE_OF', iv_ADD_CARE_OF);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_PO_BOX', iv_ADD_PO_BOX);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_PO_BOX_NBR', in_ADD_PO_BOX_NBR);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_COUNTY', iv_ADD_COUNTY);
    --Ajout du record
    fwk_i_mgt_entity.InsertEntity(iot_crud_definition => lt_crud_def);
    --Récupération des valeurs de retour
    ln_result  := fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'PAC_ADDRESS_ID');
    --Libèration entité
    fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
    return ln_result;
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
      fwk_i_mgt_exception.raise_exception(in_error_code    => -20004
                                        , iv_message       => sqlerrm
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CreateADDRESS'
                                         );
  end;

  procedure UpdateADDRESS(
    in_PAC_ADDRESS_ID      in number
  , in_PAC_PERSON_ID       in number
  , iv_CNTID               in varchar2
  , iv_ADD_ADDRESS1        in varchar2
  , iv_ADD_ZIPCODE         in varchar2
  , iv_ADD_CITY            in varchar2
  , iv_ADD_STATE           in varchar2
  , iv_LANID               in varchar2
  , iv_ADD_COMMENT         in varchar2
  , iv_DIC_ADDRESS_TYPE_ID in varchar2
  , id_ADD_SINCE           in date
  , iv_ADD_FORMAT          in varchar2
  , in_ADD_PRINCIPAL       in number
  , iv_C_PARTNER_STATUS    in varchar2
  , in_ADD_PRIORITY        in number
  , iv_ADD_CARE_OF         in varchar2
  , iv_ADD_PO_BOX          in varchar2
  , in_ADD_PO_BOX_NBR      in number
  , iv_ADD_COUNTY          in varchar2
  )
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    --Initialisation entité PAC_ADDRESS
    fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_pac_entity.gcPacAddress
                       , iot_crud_definition   => lt_crud_def
                       , ib_initialize         => true
                       , in_main_id            => in_PAC_ADDRESS_ID
                        );

    if (lt_crud_def.row_id is null) then
      raise EX_NOT_FOUND;
    end if;

    -- Affectation des valeurs
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_PERSON_ID', in_PAC_PERSON_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PC_CNTRY_ID', PCS.PC_LIB_LOOKUP.getCNTRY(iv_CNTID) );
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_ADDRESS1', iv_ADD_ADDRESS1);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_ZIPCODE', iv_ADD_ZIPCODE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_CITY', iv_ADD_CITY);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_STATE', iv_ADD_STATE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PC_LANG_ID', PCS.PC_LIB_LOOKUP.getLANG(iv_LANID) );
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_COMMENT', iv_ADD_COMMENT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_ADDRESS_TYPE_ID', iv_DIC_ADDRESS_TYPE_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_SINCE', id_ADD_SINCE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_FORMAT', iv_ADD_FORMAT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_PRINCIPAL', in_ADD_PRINCIPAL);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_PRIORITY', in_ADD_PRIORITY);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_CARE_OF', iv_ADD_CARE_OF);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_PO_BOX', iv_ADD_PO_BOX);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_PO_BOX_NBR', in_ADD_PO_BOX_NBR);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_COUNTY', iv_ADD_COUNTY);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_PARTNER_STATUS', iv_C_PARTNER_STATUS);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'A_DATEMOD', Sysdate);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'A_IDMOD', pcs.PC_I_LIB_SESSION.GetUserIni);
    --Mise à jour de l'entité
    fwk_i_mgt_entity.UpdateEntity(iot_crud_definition => lt_crud_def);
    --Libèration entité
    fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if (sqlcode = EX_NOT_FOUND_NUM) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => sqlcode
                                          , iv_message       => '"' || to_char(in_PAC_ADDRESS_ID) || '" does not exists'
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdateADDRESS'
                                           );
      else
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20005
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdateADDRESS'
                                           );
      end if;
  end;

  procedure DeleteADDRESS(in_PAC_ADDRESS_ID in number)
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    --Initialisation entité PAC_ADRESSE
    fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_pac_entity.gcPacAddress
                       , iot_crud_definition   => lt_crud_def
                       , ib_initialize         => true
                       , in_main_id            => in_PAC_ADDRESS_ID
                        );

    if (lt_crud_def.row_id is not null) then
      fwk_i_mgt_entity.DeleteEntity(iot_crud_definition => lt_crud_def);
    else
      raise EX_NOT_FOUND;
    end if;
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if (sqlcode = EX_NOT_FOUND_NUM) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => sqlcode
                                          , iv_message       => '"' || to_char(in_PAC_ADDRESS_ID) || '" does not exists'
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeleteADDRESS'
                                           );
      else
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20006
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeleteADDRESS'
                                           );
      end if;
  end;

  --
  -- Communication management
  --
  function CreateCOMMUNICATION(
    in_PAC_PERSON_ID             in number default null
  , in_PAC_ADDRESS_ID            in number default null
  , iv_DIC_COMMUNICATION_TYPE_ID in varchar2 default null
  , iv_COM_EXT_NUMBER            in varchar2 default null
  , iv_COM_INT_NUMBER            in varchar2 default null
  , iv_COM_AREA_CODE             in varchar2 default null
  , iv_COM_COMMENT               in varchar2 default null
  , inPAC_COMMUNICATION_ID       in number default null
  , in_COM_PREFERRED_CONTACT     in number default null
  )
    return pac_communication.pac_communication_id%type
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
    ln_result   pac_communication.pac_communication_id%type;
  begin
    --Initialisation entité PAC_PERSON
    fwk_i_mgt_entity.new(iv_entity_name => fwk_i_typ_pac_entity.gcPacCommunication, iot_crud_definition => lt_crud_def);
    -- Affectation des valeurs
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_COMMUNICATION_ID', inPAC_COMMUNICATION_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_PERSON_ID', in_PAC_PERSON_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_ADDRESS_ID', in_PAC_ADDRESS_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_COMMUNICATION_TYPE_ID', iv_DIC_COMMUNICATION_TYPE_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'COM_EXT_NUMBER', iv_COM_EXT_NUMBER);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'COM_INT_NUMBER', iv_COM_INT_NUMBER);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'COM_AREA_CODE', iv_COM_AREA_CODE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'COM_COMMENT', iv_COM_COMMENT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'COM_PREFERRED_CONTACT', in_COM_PREFERRED_CONTACT);
    --Ajout du record
    fwk_i_mgt_entity.InsertEntity(iot_crud_definition => lt_crud_def);
    --Récupération des valeurs de retour
    ln_result  := fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'PAC_COMMUNICATION_ID');
    --Libèration entité
    fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
    return ln_result;
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
      fwk_i_mgt_exception.raise_exception(in_error_code    => -20007
                                        , iv_message       => sqlerrm
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CreateCOMMUNICATION'
                                         );
  end;

  procedure UpdateCOMMUNICATION(
    in_PAC_COMMUNICATION_ID      in number
  , in_PAC_PERSON_ID             in number
  , in_PAC_ADDRESS_ID            in number
  , iv_DIC_COMMUNICATION_TYPE_ID in varchar2
  , iv_COM_EXT_NUMBER            in varchar2
  , iv_COM_INT_NUMBER            in varchar2
  , iv_COM_AREA_CODE             in varchar2
  , iv_COM_COMMENT               in varchar2
  )
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    --Initialisation entité PAC_ADDRESS
    fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_pac_entity.gcPacCommunication
                       , iot_crud_definition   => lt_crud_def
                       , ib_initialize         => true
                       , in_main_id            => in_PAC_COMMUNICATION_ID
                        );

    if (lt_crud_def.row_id is null) then
      raise EX_NOT_FOUND;
    end if;

    -- Affectation des valeurs
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_PERSON_ID', in_PAC_PERSON_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_ADDRESS_ID', in_PAC_ADDRESS_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_COMMUNICATION_TYPE_ID', iv_DIC_COMMUNICATION_TYPE_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'COM_EXT_NUMBER', iv_COM_EXT_NUMBER);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'COM_INT_NUMBER', iv_COM_INT_NUMBER);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'COM_AREA_CODE', iv_COM_AREA_CODE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'COM_COMMENT', iv_COM_COMMENT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'A_DATEMOD', Sysdate);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'A_IDMOD', pcs.PC_I_LIB_SESSION.GetUserIni);
    --Mise à jour de l'entité
    fwk_i_mgt_entity.UpdateEntity(iot_crud_definition => lt_crud_def);
    --Libèration entité
    fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if (sqlcode = EX_NOT_FOUND_NUM) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => sqlcode
                                          , iv_message       => '"' || to_char(in_PAC_COMMUNICATION_ID) || '" does not exists'
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdateCOMMUNICATION'
                                           );
      else
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20008
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdateCOMMUNICATION'
                                           );
      end if;
  end;

  procedure DeleteCOMMUNICATION(in_PAC_COMMUNICATION_ID in number)
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    --Initialisation entité PAC_ADRESSE
    fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_pac_entity.gcPacCommunication
                       , iot_crud_definition   => lt_crud_def
                       , ib_initialize         => true
                       , in_main_id            => in_PAC_COMMUNICATION_ID
                        );

    if (lt_crud_def.row_id is not null) then
      fwk_i_mgt_entity.DeleteEntity(iot_crud_definition => lt_crud_def);
    else
      raise EX_NOT_FOUND;
    end if;
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if (sqlcode = EX_NOT_FOUND_NUM) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => sqlcode
                                          , iv_message       => '"' || to_char(in_PAC_COMMUNICATION_ID) || '" does not exists'
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeleteCOMMUNICATION'
                                           );
      else
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20009
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeleteCOMMUNICATION'
                                           );
      end if;
  end;

  --
  -- Person's association management
  --
  function CreatePERSON_ASSOCIATION(
    in_PAC_PERSON_ID             in number default null
  , in_PAC_PAC_PERSON_ID         in number default null
  , iv_DIC_ASSOCIATION_TYPE_ID   in varchar2 default null
  , iv_PAS_COMMENT               in varchar2 default null
  , iv_PAS_FUNCTION              in varchar2 default null
  , iv_C_PARTNER_STATUS          in varchar2 default '1'
  , in_PAS_MAIN_CONTACT          in number default 0
  , in_PAC_PERSON_ASSOCIATION_ID in number default null
  )
    return pac_person_association.pac_person_association_id%type
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
    ln_result   pac_person_association.pac_person_association_id%type;
  begin
    --Initialisation entité PAC_PERSON
    fwk_i_mgt_entity.new(iv_entity_name => fwk_i_typ_pac_entity.gcPacPersonAssociation, iot_crud_definition => lt_crud_def);
    -- Affectation des valeurs
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_PERSON_ASSOCIATION_ID', in_PAC_PERSON_ASSOCIATION_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_PERSON_ID', in_PAC_PERSON_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_PAC_PERSON_ID', in_PAC_PAC_PERSON_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_ASSOCIATION_TYPE_ID', iv_DIC_ASSOCIATION_TYPE_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAS_COMMENT', iv_PAS_COMMENT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAS_FUNCTION', iv_PAS_FUNCTION);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_PARTNER_STATUS', iv_C_PARTNER_STATUS);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAS_MAIN_CONTACT', in_PAS_MAIN_CONTACT);
    --Ajout du record
    fwk_i_mgt_entity.InsertEntity(iot_crud_definition => lt_crud_def);
    --Récupération des valeurs de retour
    ln_result  := fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'PAC_PERSON_ASSOCIATION_ID');
    --Libèration entité
    fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
    return ln_result;
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
      fwk_i_mgt_exception.raise_exception(in_error_code    => -20010
                                        , iv_message       => sqlerrm
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CreatePERSON_ASSOCIATION'
                                         );
  end;

  procedure UpdatePERSON_ASSOCIATION(
    in_PAC_PERSON_ASSOCIATION_ID in number
  , in_PAC_PERSON_ID             in number
  , in_PAC_PAC_PERSON_ID         in number
  , iv_DIC_ASSOCIATION_TYPE_ID   in varchar2
  , iv_PAS_COMMENT               in varchar2
  , iv_PAS_FUNCTION              in varchar2
  , iv_C_PARTNER_STATUS          in varchar2
  , in_PAS_MAIN_CONTACT          in number
  )
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    --Initialisation entité PAC_ADDRESS
    fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_pac_entity.gcPacPersonAssociation
                       , iot_crud_definition   => lt_crud_def
                       , ib_initialize         => true
                       , in_main_id            => in_PAC_PERSON_ASSOCIATION_ID
                        );

    if (lt_crud_def.row_id is null) then
      raise EX_NOT_FOUND;
    end if;

    -- Affectation des valeurs
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_PERSON_ID', in_PAC_PERSON_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_PAC_PERSON_ID', in_PAC_PAC_PERSON_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_ASSOCIATION_TYPE_ID', iv_DIC_ASSOCIATION_TYPE_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAS_COMMENT', iv_PAS_COMMENT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAS_FUNCTION', iv_PAS_FUNCTION);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_PARTNER_STATUS', iv_C_PARTNER_STATUS);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAS_MAIN_CONTACT', in_PAS_MAIN_CONTACT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'A_DATEMOD', Sysdate);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'A_IDMOD', pcs.PC_I_LIB_SESSION.GetUserIni);
    --Mise à jour de l'entité
    fwk_i_mgt_entity.UpdateEntity(iot_crud_definition => lt_crud_def);
    --Libèration entité
    fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if (sqlcode = EX_NOT_FOUND_NUM) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => sqlcode
                                          , iv_message       => '"' || to_char(in_PAC_PERSON_ASSOCIATION_ID) || '" does not exists'
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdatePERSON_ASSOCIATION'
                                           );
      else
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20011
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdatePERSON_ASSOCIATION'
                                           );
      end if;
  end;

  procedure DeletePERSON_ASSOCIATION(in_PAC_PERSON_ASSOCIATION_ID in number)
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    --Initialisation entité PAC_ADRESSE
    fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_pac_entity.gcPacPersonAssociation
                       , iot_crud_definition   => lt_crud_def
                       , ib_initialize         => true
                       , in_main_id            => in_PAC_PERSON_ASSOCIATION_ID
                        );

    if (lt_crud_def.row_id is not null) then
      fwk_i_mgt_entity.DeleteEntity(iot_crud_definition => lt_crud_def);
    else
      raise EX_NOT_FOUND;
    end if;
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if (sqlcode = EX_NOT_FOUND_NUM) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => sqlcode
                                          , iv_message       => '"' || to_char(in_PAC_PERSON_ASSOCIATION_ID) || '" does not exists'
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeletePERSON_ASSOCIATION'
                                           );
      else
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20012
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeletePERSON_ASSOCIATION'
                                           );
      end if;
  end;

  --
  -- Third management
  --
  function CreateTHIRD(
    in_PAC_PERSON_ID           in number default null
  , iv_THI_NO_TVA              in varchar2 default null
  , iv_THI_NO_INTRA            in varchar2 default null
  , iv_DIC_THIRD_ACTIVITY_ID   in varchar2 default null
  , iv_DIC_THIRD_AREA_ID       in varchar2 default null
  , iv_THI_NO_FORMAT           in varchar2 default null
  , iv_THI_NO_SIREN            in varchar2 default null
  , iv_THI_NO_SIRET            in varchar2 default null
  , iv_THI_WEB_KEY             in varchar2 default null
  , in_PAC_PAC_PERSON_ID       in number default null
  , iv_DIC_CITI_CODE_ID        in varchar2 default null
  , iv_DIC_JURIDICAL_STATUS_ID in varchar2 default null
  , iv_THI_CUSTOM_NUMBER       in varchar2 default null
  , iv_THI_NO_FID              in varchar2 default null
  , iv_THI_NO_STATE            in varchar2 default null
  , iv_THI_NO_IDE              in varchar2 default null
  )
    return pac_third.pac_third_id%type
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
    ln_result   pac_third.pac_third_id%type;
  begin
    --Initialisation entité
    fwk_i_mgt_entity.new(iv_entity_name => fwk_i_typ_pac_entity.gcPacThird, iot_crud_definition => lt_crud_def);
    -- Affectation des valeurs
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_THIRD_ID', in_PAC_PERSON_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'THI_NO_TVA', iv_THI_NO_TVA);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'THI_NO_INTRA', iv_THI_NO_INTRA);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_THIRD_ACTIVITY_ID', iv_DIC_THIRD_ACTIVITY_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_THIRD_AREA_ID', iv_DIC_THIRD_AREA_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'THI_NO_FORMAT', iv_THI_NO_FORMAT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'THI_NO_SIREN', iv_THI_NO_SIREN);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'THI_NO_SIRET', iv_THI_NO_SIRET);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'THI_WEB_KEY', iv_THI_WEB_KEY);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_PAC_PERSON_ID', in_PAC_PAC_PERSON_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_CITI_CODE_ID', iv_DIC_CITI_CODE_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_JURIDICAL_STATUS_ID', iv_DIC_JURIDICAL_STATUS_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'THI_CUSTOM_NUMBER', iv_THI_CUSTOM_NUMBER);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'THI_NO_FID', iv_THI_NO_FID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'THI_NO_STATE', iv_THI_NO_STATE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'THI_NO_IDE', iv_THI_NO_IDE);
    --Ajout du record
    fwk_i_mgt_entity.InsertEntity(iot_crud_definition => lt_crud_def);
    --Récupération des valeurs de retour
    ln_result  := fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'PAC_THIRD_ID');
    --Libèration entité
    fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
    return ln_result;
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
      fwk_i_mgt_exception.raise_exception(in_error_code    => -20013
                                        , iv_message       => sqlerrm
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CreateTHIRD'
                                         );
  end;

  procedure UpdateTHIRD(
    in_PAC_PERSON_ID           in number
  , iv_THI_NO_TVA              in varchar2
  , iv_THI_NO_INTRA            in varchar2
  , iv_DIC_THIRD_ACTIVITY_ID   in varchar2
  , iv_DIC_THIRD_AREA_ID       in varchar2
  , iv_THI_NO_FORMAT           in varchar2
  , iv_THI_NO_SIREN            in varchar2
  , iv_THI_NO_SIRET            in varchar2
  , iv_THI_WEB_KEY             in varchar2
  , in_PAC_PAC_PERSON_ID       in number
  , iv_DIC_CITI_CODE_ID        in varchar2
  , iv_DIC_JURIDICAL_STATUS_ID in varchar2
  , iv_THI_CUSTOM_NUMBER       in varchar2
  , iv_THI_NO_FID              in varchar2
  , iv_THI_NO_STATE            in varchar2
  , iv_THI_NO_IDE              in varchar2
  )
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    --Initialisation entité
    fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_pac_entity.gcPacThird
                       , iot_crud_definition   => lt_crud_def
                       , ib_initialize         => true
                       , in_main_id            => in_PAC_PERSON_ID
                        );

    if (lt_crud_def.row_id is null) then
      raise EX_NOT_FOUND;
    end if;

    -- Affectation des valeurs
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'THI_NO_TVA', iv_THI_NO_TVA);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'THI_NO_INTRA', iv_THI_NO_INTRA);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_THIRD_ACTIVITY_ID', iv_DIC_THIRD_ACTIVITY_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_THIRD_AREA_ID', iv_DIC_THIRD_AREA_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'THI_NO_FORMAT', iv_THI_NO_FORMAT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'THI_NO_SIREN', iv_THI_NO_SIREN);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'THI_WEB_KEY', iv_THI_WEB_KEY);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_PAC_PERSON_ID', in_PAC_PAC_PERSON_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_CITI_CODE_ID', iv_DIC_CITI_CODE_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_JURIDICAL_STATUS_ID', iv_DIC_JURIDICAL_STATUS_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'THI_CUSTOM_NUMBER', iv_THI_CUSTOM_NUMBER);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'THI_NO_FID', iv_THI_NO_FID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'THI_NO_STATE', iv_THI_NO_STATE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'THI_NO_IDE', iv_THI_NO_IDE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'A_DATEMOD', Sysdate);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'A_IDMOD', pcs.PC_I_LIB_SESSION.GetUserIni);
    --Mise à jour de l'entité
    fwk_i_mgt_entity.UpdateEntity(iot_crud_definition => lt_crud_def);
    --Libèration entité
    fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if (sqlcode = EX_NOT_FOUND_NUM) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => sqlcode
                                          , iv_message       => '"' || to_char(in_PAC_PERSON_ID) || '" does not exists'
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdateTHIRD'
                                           );
      else
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20014
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdateTHIRD'
                                           );
      end if;
  end;

  procedure DeleteTHIRD(in_PAC_PERSON_ID in number)
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    --Initialisation entité PAC_ADRESSE
    fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_pac_entity.gcPacThird
                       , iot_crud_definition   => lt_crud_def
                       , ib_initialize         => true
                       , in_main_id            => in_PAC_PERSON_ID
                        );

    if (lt_crud_def.row_id is not null) then
      fwk_i_mgt_entity.DeleteEntity(iot_crud_definition => lt_crud_def);
    else
      raise EX_NOT_FOUND;
    end if;
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if (sqlcode = EX_NOT_FOUND_NUM) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => sqlcode
                                          , iv_message       => '"' || to_char(in_PAC_PERSON_ID) || '" does not exists'
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeleteTHIRD'
                                           );
      else
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20015
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeleteTHIRD'
                                           );
      end if;
  end;

  --
  -- Customer management
  --
  function CreateCUSTOM_PARTNER(
    in_PAC_PERSON_ID          in number default null
  , iv_DIC_TYPE_SUBMISSION_ID in varchar2 default null
  , iv_DIC_TYPE_PARTNER_ID    in varchar2 default null
  , iv_DIC_TARIFF_ID          in varchar2 default null
  , iv_DIC_STATISTIC_1_ID     in varchar2 default null
  , iv_DIC_STATISTIC_2_ID     in varchar2 default null
  , iv_DIC_STATISTIC_3_ID     in varchar2 default null
  , iv_DIC_STATISTIC_4_ID     in varchar2 default null
  , iv_DIC_STATISTIC_5_ID     in varchar2 default null
  , iv_CUS_COMMENT            in varchar2 default null
  , iv_CUS_FREE_ZONE1         in varchar2 default null
  , iv_CUS_FREE_ZONE2         in varchar2 default null
  , iv_CUS_FREE_ZONE3         in varchar2 default null
  , iv_CUS_FREE_ZONE4         in varchar2 default null
  , iv_CUS_FREE_ZONE5         in varchar2 default null
  , in_ACS_VAT_DET_ACCOUNT_ID in number default null
  , iv_C_PARTNER_STATUS       in varchar2 default '1'
  , iv_C_REMAINDER_LAUNCHING  in varchar2 default 'AUTO'
  , iv_C_PARTNER_CATEGORY     in varchar2 default '1'
  , iv_C_TYPE_EDI             in varchar2 default '0'
  , iv_C_RESERVATION_TYP      in varchar2 default '0'
  , iv_C_ADV_MATERIAL_MODE    in varchar2 default '01'
  , iv_CURRENCY               in varchar2 default null
  , iv_PCO_DESCR              in varchar2 default null
  )
    return pac_custom_partner.pac_custom_partner_id%type
  is
    lt_crud_def                  fwk_i_typ_definition.T_CRUD_DEF;
    ln_result                    pac_third.pac_third_id%type;
    ln_pac_remainder_category_id pac_remainder_category.pac_remainder_category_id%type;
    ln_acs_vat_det_account_id    acs_vat_det_account.acs_vat_det_account_id%type;
    ln_acs_auxiliary_account_id  acs_auxiliary_account.acs_auxiliary_account_id%type;
    ln_pac_payment_condition_id  pac_payment_condition.pac_payment_condition_id%type;
    ln_financial_currency_id     acs_financial_currency.acs_financial_currency_id%type;
    lv_Errmsg                    varchar2(4000);
  begin
    lv_Errmsg                    := '';
    --Initialisation entité
    fwk_i_mgt_entity.new(iv_entity_name => fwk_i_typ_pac_entity.gcPacCustomPartner, iot_crud_definition => lt_crud_def);

    begin
      --Condition de paiement selon description donnée
      if (iv_PCO_DESCR is not null) then
        ln_pac_payment_condition_id  := pac_i_lib_lookup.getPAYMENT_CONDITION(iv_PCO_DESCR);
      else
        ln_pac_payment_condition_id  := pac_i_lib_lookup.getDefaultPAYMENT_CONDITION;
      end if;
    exception
      when others then
        lv_Errmsg  := 'Payment condition not found  ' || iv_PCO_DESCR;
        raise;
    end;

    begin
      --Catégorie de relance par défaut
      ln_pac_remainder_category_id  := pac_i_lib_lookup.getDefaultREMAINDER_CATEGORY;
    exception
      when others then
        lv_Errmsg  := 'Custom default remainder category not found';
        raise;
    end;

    begin
      --Décompte TVA donné ou celui du pays de l'adresse principale ou celui par défaut
      ln_acs_vat_det_account_id  := in_ACS_VAT_DET_ACCOUNT_ID;

      if ln_acs_vat_det_account_id is null then
        begin
          -- Décompte TVA donné est null--> recherche du décompte du pays de l'adresse principale
          ln_acs_vat_det_account_id  := pac_i_lib_lookup.getVAT_DET_ACCOUNT(pac_i_lib_lookup.getADDRESS_PRINCIPAL_CNTRY(in_PAC_PERSON_ID) );
        exception
          when no_data_found then
            -- Décompte du pays de l'adresse principale inexistant -- > Décompte par défaut
            ln_acs_vat_det_account_id  := pac_i_lib_lookup.getDefaultVAT_DET_ACCOUNT;
        end;
      end if;
    exception
      when others then
        lv_Errmsg  := 'Custom VAT account not found';
        raise;
    end;

    begin
      if (iv_CURRENCY is not null) then
        ln_financial_currency_id  := acs_i_lib_lookup.getFINANCIAL_CURRENCY(iv_CURRENCY);
      end if;
    exception
      when others then
        lv_Errmsg  := 'Custom currency not found ' || iv_CURRENCY;
        raise;
    end;

    -- Affectation des valeurs
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_CUSTOM_PARTNER_ID', in_PAC_PERSON_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_TYPE_SUBMISSION_ID', iv_DIC_TYPE_SUBMISSION_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_TYPE_PARTNER_ID', iv_DIC_TYPE_PARTNER_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_TARIFF_ID', iv_DIC_TARIFF_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_STATISTIC_1_ID', iv_DIC_STATISTIC_1_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_STATISTIC_2_ID', iv_DIC_STATISTIC_2_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_STATISTIC_3_ID', iv_DIC_STATISTIC_3_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_STATISTIC_4_ID', iv_DIC_STATISTIC_2_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_STATISTIC_5_ID', iv_DIC_STATISTIC_5_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CUS_COMMENT', iv_CUS_COMMENT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CUS_FREE_ZONE1', iv_CUS_FREE_ZONE1);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CUS_FREE_ZONE2', iv_CUS_FREE_ZONE2);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CUS_FREE_ZONE3', iv_CUS_FREE_ZONE3);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CUS_FREE_ZONE4', iv_CUS_FREE_ZONE4);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CUS_FREE_ZONE5', iv_CUS_FREE_ZONE5);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_PARTNER_STATUS', iv_C_PARTNER_STATUS);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_REMAINDER_LAUNCHING', iv_C_REMAINDER_LAUNCHING);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_PARTNER_CATEGORY', iv_C_PARTNER_CATEGORY);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_TYPE_EDI', iv_C_TYPE_EDI);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_RESERVATION_TYP', iv_C_RESERVATION_TYP);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ADV_MATERIAL_MODE', iv_C_ADV_MATERIAL_MODE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ACS_VAT_DET_ACCOUNT_ID', ln_acs_vat_det_account_id);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_PAYMENT_CONDITION_ID', ln_pac_payment_condition_id);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_REMAINDER_CATEGORY_ID', ln_pac_remainder_category_id);
    ln_acs_auxiliary_account_id  := fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'ACS_AUXILIARY_ACCOUNT_ID');

    if ln_acs_auxiliary_account_id is null then
      --Création compte auxiliaire
      PAC_PARTNER_MANAGEMENT.CreateAuxiliaryAccount(fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'PAC_CUSTOM_PARTNER_ID')
                                                  , pac_i_lib_lookup.getSUB_SET_ID('REC')
                                                  , '1'
                                                  , ln_financial_currency_id
                                                  , 0
                                                  , ln_acs_auxiliary_account_id
                                                   );
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ACS_AUXILIARY_ACCOUNT_ID', ln_acs_auxiliary_account_id);
    end if;

    --Ajout du record
    fwk_i_mgt_entity.InsertEntity(iot_crud_definition => lt_crud_def);
    --Récupération des valeurs de retour
    ln_result                    := fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'PAC_CUSTOM_PARTNER_ID');
    --Libèration entité
    fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
    return ln_result;
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if lv_Errmsg is null then
        lv_Errmsg  := sqlerrm;
      end if;

      fwk_i_mgt_exception.raise_exception(in_error_code    => -20016
                                        , iv_message       => lv_Errmsg
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CreateCUSTOM_PARTNER'
                                         );
  end;

  procedure UpdateCUSTOM_PARTNER(
    in_PAC_CUSTOM_PARTNER_ID  in number
  , iv_DIC_TYPE_SUBMISSION_ID in varchar2
  , iv_DIC_TYPE_PARTNER_ID    in varchar2
  , iv_DIC_TARIFF_ID          in varchar2
  , iv_DIC_STATISTIC_1_ID     in varchar2
  , iv_DIC_STATISTIC_2_ID     in varchar2
  , iv_DIC_STATISTIC_3_ID     in varchar2
  , iv_DIC_STATISTIC_4_ID     in varchar2
  , iv_DIC_STATISTIC_5_ID     in varchar2
  , iv_CUS_COMMENT            in varchar2
  , iv_CUS_FREE_ZONE1         in varchar2
  , iv_CUS_FREE_ZONE2         in varchar2
  , iv_CUS_FREE_ZONE3         in varchar2
  , iv_CUS_FREE_ZONE4         in varchar2
  , iv_CUS_FREE_ZONE5         in varchar2
  , in_ACS_VAT_DET_ACCOUNT_ID in number
  , iv_C_PARTNER_STATUS       in varchar2
  , iv_C_REMAINDER_LAUNCHING  in varchar2
  , iv_C_PARTNER_CATEGORY     in varchar2
  , iv_C_TYPE_EDI             in varchar2
  , iv_C_RESERVATION_TYP      in varchar2
  , iv_C_ADV_MATERIAL_MODE    in varchar2
  , iv_CURRENCY               in varchar2
  , iv_PCO_DESCR              in varchar2
  )
  is
    lt_crud_def                  fwk_i_typ_definition.T_CRUD_DEF;
    ln_pac_remainder_category_id pac_remainder_category.pac_remainder_category_id%type;
    ln_acs_vat_det_account_id    acs_vat_det_account.acs_vat_det_account_id%type;
    ln_acs_auxiliary_account_id  acs_auxiliary_account.acs_auxiliary_account_id%type;
    ln_pac_payment_condition_id  pac_payment_condition.pac_payment_condition_id%type;
    ln_financial_currency_id     acs_financial_currency.acs_financial_currency_id%type;
  begin
    --Initialisation entité
    fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_pac_entity.gcPacCustomPartner
                       , iot_crud_definition   => lt_crud_def
                       , ib_initialize         => true
                       , in_main_id            => in_PAC_CUSTOM_PARTNER_ID
                        );

    if (lt_crud_def.row_id is null) then
      raise EX_NOT_FOUND;
    end if;

    if (iv_PCO_DESCR is not null) then
      ln_pac_payment_condition_id  := pac_i_lib_lookup.getPAYMENT_CONDITION(iv_PCO_DESCR);
    else
      ln_pac_payment_condition_id  := fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'PAC_PAYMENT_CONDITION_ID');
    end if;

    if ln_pac_payment_condition_id is null then
      ln_pac_payment_condition_id  := pac_i_lib_lookup.getDefaultPAYMENT_CONDITION;
    end if;

    --Décompte TVA donné ou celui du pays de l'adresse principale ou celui par défaut
    ln_acs_vat_det_account_id  := in_ACS_VAT_DET_ACCOUNT_ID;

    if ln_acs_vat_det_account_id is null then
      begin
        -- Décompte TVA donné est null--> recherche du décompte du pays de l'adresse principale
        ln_acs_vat_det_account_id  := pac_i_lib_lookup.getVAT_DET_ACCOUNT(pac_i_lib_lookup.getADDRESS_PRINCIPAL_CNTRY(in_PAC_CUSTOM_PARTNER_ID) );
      exception
        when no_data_found then
          -- Décompte du pays de l'adresse principale inexistant -- > Décompte par défaut
          ln_acs_vat_det_account_id  := pac_i_lib_lookup.getDefaultVAT_DET_ACCOUNT;
      end;
    end if;

    -- Affectation des valeurs
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_TYPE_SUBMISSION_ID', iv_DIC_TYPE_SUBMISSION_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_TYPE_PARTNER_ID', iv_DIC_TYPE_PARTNER_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_STATISTIC_1_ID', iv_DIC_STATISTIC_1_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_STATISTIC_2_ID', iv_DIC_STATISTIC_2_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_STATISTIC_3_ID', iv_DIC_STATISTIC_3_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_STATISTIC_4_ID', iv_DIC_STATISTIC_4_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_STATISTIC_5_ID', iv_DIC_STATISTIC_5_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_TARIFF_ID', iv_DIC_TARIFF_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CUS_COMMENT', iv_CUS_COMMENT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CUS_FREE_ZONE1', iv_CUS_FREE_ZONE1);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CUS_FREE_ZONE2', iv_CUS_FREE_ZONE2);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CUS_FREE_ZONE3', iv_CUS_FREE_ZONE3);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CUS_FREE_ZONE4', iv_CUS_FREE_ZONE4);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CUS_FREE_ZONE5', iv_CUS_FREE_ZONE5);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_PARTNER_STATUS', iv_C_PARTNER_STATUS);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_REMAINDER_LAUNCHING', iv_C_REMAINDER_LAUNCHING);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_PARTNER_CATEGORY', iv_C_PARTNER_CATEGORY);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_TYPE_EDI', iv_C_TYPE_EDI);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_RESERVATION_TYP', iv_C_RESERVATION_TYP);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ADV_MATERIAL_MODE', iv_C_ADV_MATERIAL_MODE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ACS_VAT_DET_ACCOUNT_ID', ln_acs_vat_det_account_id);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_PAYMENT_CONDITION_ID', ln_pac_payment_condition_id);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_REMAINDER_CATEGORY_ID', ln_pac_remainder_category_id);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'A_DATEMOD', Sysdate);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'A_IDMOD', pcs.PC_I_LIB_SESSION.GetUserIni);
    --Mise à jour de l'entité
    fwk_i_mgt_entity.UpdateEntity(iot_crud_definition => lt_crud_def);
    --Libèration entité
    fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if (sqlcode = EX_NOT_FOUND_NUM) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => sqlcode
                                          , iv_message       => '"' || to_char(in_PAC_CUSTOM_PARTNER_ID) || '" does not exists'
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdateCUSTOM_PARTNER'
                                           );
      else
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20017
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdateCUSTOM_PARTNER'
                                           );
      end if;
  end;

  procedure DeleteCUSTOM_PARTNER(in_PAC_CUSTOM_PARTNER_ID in number)
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    --Initialisation entité PAC_ADRESSE
    fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_pac_entity.gcPacCustomPartner
                       , iot_crud_definition   => lt_crud_def
                       , ib_initialize         => true
                       , in_main_id            => in_PAC_CUSTOM_PARTNER_ID
                        );

    if (lt_crud_def.row_id is not null) then
      fwk_i_mgt_entity.DeleteEntity(iot_crud_definition => lt_crud_def);
    else
      raise EX_NOT_FOUND;
    end if;
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if (sqlcode = EX_NOT_FOUND_NUM) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => sqlcode
                                          , iv_message       => '"' || to_char(in_PAC_CUSTOM_PARTNER_ID) || '" does not exists'
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeleteCUSTOM_PARTNER'
                                           );
      else
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20018
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeleteCUSTOM_PARTNER'
                                           );
      end if;
  end;

  --
  -- Supplier management
  --
  function CreateSUPPLIER_PARTNER(
    in_PAC_PERSON_ID           in number default null
  , iv_DIC_TYPE_SUBMISSION_ID  in varchar2 default null
  , iv_DIC_TYPE_PARTNER_F_ID   in varchar2 default null
  , iv_DIC_PRIORITY_PAYMENT_ID in varchar2 default null
  , iv_DIC_CENTER_PAYMENT_ID   in varchar2 default null
  , iv_DIC_LEVEL_PRIORITY_ID   in varchar2 default null
  , iv_DIC_TARIFF_ID           in varchar2 default null
  , iv_DIC_STATISTIC_F1_ID     in varchar2 default null
  , iv_DIC_STATISTIC_F2_ID     in varchar2 default null
  , iv_DIC_STATISTIC_F3_ID     in varchar2 default null
  , iv_DIC_STATISTIC_F4_ID     in varchar2 default null
  , iv_DIC_STATISTIC_F5_ID     in varchar2 default null
  , in_CRE_BLOCKED             in number default null
  , iv_CRE_REMARK              in varchar2 default null
  , iv_CRE_FREE_ZONE1          in varchar2 default null
  , iv_CRE_FREE_ZONE2          in varchar2 default null
  , iv_CRE_FREE_ZONE3          in varchar2 default null
  , iv_CRE_FREE_ZONE4          in varchar2 default null
  , iv_CRE_FREE_ZONE5          in varchar2 default null
  , in_ACS_VAT_DET_ACCOUNT_ID  in number default null
  , iv_C_REMAINDER_LAUNCHING   in varchar2 default 'AUTO'
  , iv_C_PARTNER_CATEGORY      in varchar2 default '1'
  , iv_C_TYPE_EDI              in varchar2 default '0'
  , iv_C_PARTNER_STATUS        in varchar2 default '1'
  , iv_C_ADV_MATERIAL_MODE     in varchar2 default '01'
  , iv_PCO_DESCR               in varchar2 default null
  , iv_CURRENCY                in varchar2 default null
  )
    return pac_supplier_partner.pac_supplier_partner_id%type
  is
    lt_crud_def                  fwk_i_typ_definition.T_CRUD_DEF;
    ln_result                    pac_third.pac_third_id%type;
    ln_pac_remainder_category_id pac_remainder_category.pac_remainder_category_id%type;
    ln_acs_vat_det_account_id    acs_vat_det_account.acs_vat_det_account_id%type;
    ln_acs_auxiliary_account_id  acs_auxiliary_account.acs_auxiliary_account_id%type;
    ln_pac_payment_condition_id  pac_payment_condition.pac_payment_condition_id%type;
    ln_financial_currency_id     acs_financial_currency.acs_financial_currency_id%type;
    lv_Errmsg                    varchar2(4000);
  begin
    --Initialisation entité
    fwk_i_mgt_entity.new(iv_entity_name => fwk_i_typ_pac_entity.gcPacSupplierPartner, iot_crud_definition => lt_crud_def);

    begin
      --Condition de paiement selon description donnée
      if (iv_PCO_DESCR is not null) then
        ln_pac_payment_condition_id  := pac_i_lib_lookup.getPAYMENT_CONDITION(iv_PCO_DESCR);
      else
        ln_pac_payment_condition_id  := pac_i_lib_lookup.getDefaultPAYMENT_CONDITION;
      end if;
    exception
      when others then
        lv_Errmsg  := 'Payment condition not found  ' || iv_PCO_DESCR;
        raise;
    end;

    begin
      --Catégorie de relance par défaut
      ln_pac_remainder_category_id  := pac_i_lib_lookup.getDefaultREMAINDER_CATEGORY;
    exception
      when others then
        lv_Errmsg  := 'Supplier default remainder category not found';
        raise;
    end;

    begin
      --Décompte TVA donné ou celui du pays de l'adresse principale ou celui par défaut
      ln_acs_vat_det_account_id  := in_ACS_VAT_DET_ACCOUNT_ID;

      if ln_acs_vat_det_account_id is null then
        begin
          -- Décompte TVA donné est null--> recherche du décompte du pays de l'adresse principale
          ln_acs_vat_det_account_id  := pac_i_lib_lookup.getVAT_DET_ACCOUNT(pac_i_lib_lookup.getADDRESS_PRINCIPAL_CNTRY(in_PAC_PERSON_ID) );
        exception
          when no_data_found then
            -- Décompte du pays de l'adresse principale inexistant -- > Décompte par défaut
            ln_acs_vat_det_account_id  := pac_i_lib_lookup.getDefaultVAT_DET_ACCOUNT;
        end;
      end if;
    exception
      when others then
        lv_Errmsg  := 'Supplier VAT account not found';
        raise;
    end;

    begin
      if (iv_CURRENCY is not null) then
        ln_financial_currency_id  := acs_i_lib_lookup.getFINANCIAL_CURRENCY(iv_CURRENCY);
      end if;
    exception
      when others then
        lv_Errmsg  := 'Custom currency not found ' || iv_CURRENCY;
        raise;
    end;

    -- Affectation des valeurs
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_SUPPLIER_PARTNER_ID', in_PAC_PERSON_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_TYPE_SUBMISSION_ID', iv_DIC_TYPE_SUBMISSION_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_TYPE_PARTNER_F_ID', iv_DIC_TYPE_PARTNER_F_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_STATISTIC_F1_ID', iv_DIC_STATISTIC_F1_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_STATISTIC_F2_ID', iv_DIC_STATISTIC_F2_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_STATISTIC_F3_ID', iv_DIC_STATISTIC_F3_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_STATISTIC_F4_ID', iv_DIC_STATISTIC_F4_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_STATISTIC_F5_ID', iv_DIC_STATISTIC_F5_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_TARIFF_ID', iv_DIC_TARIFF_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PRIORITY_PAYMENT_ID', iv_DIC_PRIORITY_PAYMENT_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_CENTER_PAYMENT_ID', iv_DIC_CENTER_PAYMENT_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEVEL_PRIORITY_ID', iv_DIC_LEVEL_PRIORITY_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CRE_BLOCKED', in_CRE_BLOCKED);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CRE_REMARK', iv_CRE_REMARK);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CRE_FREE_ZONE1', iv_CRE_FREE_ZONE1);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CRE_FREE_ZONE2', iv_CRE_FREE_ZONE2);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CRE_FREE_ZONE3', iv_CRE_FREE_ZONE3);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CRE_FREE_ZONE4', iv_CRE_FREE_ZONE4);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CRE_FREE_ZONE5', iv_CRE_FREE_ZONE5);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_REMAINDER_LAUNCHING', iv_C_REMAINDER_LAUNCHING);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_PARTNER_CATEGORY', iv_C_PARTNER_CATEGORY);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_TYPE_EDI', iv_C_TYPE_EDI);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_PARTNER_STATUS', iv_C_PARTNER_STATUS);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ADV_MATERIAL_MODE', iv_C_ADV_MATERIAL_MODE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ACS_VAT_DET_ACCOUNT_ID', ln_acs_vat_det_account_id);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_PAYMENT_CONDITION_ID', ln_pac_payment_condition_id);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_REMAINDER_CATEGORY_ID', ln_pac_remainder_category_id);
    ln_acs_auxiliary_account_id  := fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'ACS_AUXILIARY_ACCOUNT_ID');

    if ln_acs_auxiliary_account_id is null then
      --Création compte auxiliaire
      PAC_PARTNER_MANAGEMENT.CreateAuxiliaryAccount(fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'PAC_SUPPLIER_PARTNER_ID')
                                                  , pac_i_lib_lookup.getSUB_SET_ID('PAY')
                                                  , '1'
                                                  , ln_financial_currency_id
                                                  , 0
                                                  , ln_acs_auxiliary_account_id
                                                   );
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ACS_AUXILIARY_ACCOUNT_ID', ln_acs_auxiliary_account_id);
    end if;

    --Ajout du record
    fwk_i_mgt_entity.InsertEntity(iot_crud_definition => lt_crud_def);
    --Récupération des valeurs de retour
    ln_result                    := fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'PAC_SUPPLIER_PARTNER_ID');
    --Libèration entité
    fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
    return ln_result;
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if lv_Errmsg is null then
        lv_Errmsg  := sqlerrm;
      end if;

      fwk_i_mgt_exception.raise_exception(in_error_code    => -20019
                                        , iv_message       => lv_Errmsg
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CreateSUPPLIER_PARTNER'
                                         );
  end;

  procedure UpdateSUPPLIER_PARTNER(
    in_PAC_SUPPLIER_PARTNER_ID in number
  , iv_DIC_TYPE_SUBMISSION_ID  in varchar2
  , iv_DIC_TYPE_PARTNER_F_ID   in varchar2
  , iv_DIC_PRIORITY_PAYMENT_ID in varchar2
  , iv_DIC_CENTER_PAYMENT_ID   in varchar2
  , iv_DIC_LEVEL_PRIORITY_ID   in varchar2
  , iv_DIC_TARIFF_ID           in varchar2
  , iv_DIC_STATISTIC_F1_ID     in varchar2
  , iv_DIC_STATISTIC_F2_ID     in varchar2
  , iv_DIC_STATISTIC_F3_ID     in varchar2
  , iv_DIC_STATISTIC_F4_ID     in varchar2
  , iv_DIC_STATISTIC_F5_ID     in varchar2
  , in_CRE_BLOCKED             in number
  , iv_CRE_REMARK              in varchar2
  , iv_CRE_FREE_ZONE1          in varchar2
  , iv_CRE_FREE_ZONE2          in varchar2
  , iv_CRE_FREE_ZONE3          in varchar2
  , iv_CRE_FREE_ZONE4          in varchar2
  , iv_CRE_FREE_ZONE5          in varchar2
  , in_ACS_VAT_DET_ACCOUNT_ID  in number
  , iv_C_REMAINDER_LAUNCHING   in varchar2
  , iv_C_PARTNER_CATEGORY      in varchar2
  , iv_C_TYPE_EDI              in varchar2
  , iv_C_PARTNER_STATUS        in varchar2
  , iv_C_ADV_MATERIAL_MODE     in varchar2
  , iv_PCO_DESCR               in varchar2
  , iv_CURRENCY                in varchar2
  )
  is
    lt_crud_def                  fwk_i_typ_definition.T_CRUD_DEF;
    ln_pac_remainder_category_id pac_remainder_category.pac_remainder_category_id%type;
    ln_acs_vat_det_account_id    acs_vat_det_account.acs_vat_det_account_id%type;
    ln_acs_auxiliary_account_id  acs_auxiliary_account.acs_auxiliary_account_id%type;
    ln_pac_payment_condition_id  pac_payment_condition.pac_payment_condition_id%type;
    ln_financial_currency_id     acs_financial_currency.acs_financial_currency_id%type;
  begin
    --Initialisation entité
    fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_pac_entity.gcPacSupplierPartner
                       , iot_crud_definition   => lt_crud_def
                       , ib_initialize         => true
                       , in_main_id            => in_PAC_SUPPLIER_PARTNER_ID
                        );

    if (lt_crud_def.row_id is null) then
      raise EX_NOT_FOUND;
    end if;

    begin
      --Condition de paiement selon description donnée
      if (iv_PCO_DESCR is not null) then
        ln_pac_payment_condition_id  := pac_i_lib_lookup.getPAYMENT_CONDITION(iv_PCO_DESCR);
      else
        ln_pac_payment_condition_id  := fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'PAC_PAYMENT_CONDITION_ID');
      end if;

      if ln_pac_payment_condition_id is null then
        ln_pac_payment_condition_id  := pac_i_lib_lookup.getDefaultPAYMENT_CONDITION;
      end if;

      --Catégorie de relance par défaut
      ln_pac_remainder_category_id  := pac_i_lib_lookup.getDefaultREMAINDER_CATEGORY;
      --Décompte TVA donné ou celui du pays de l'adresse principale ou celui par défaut
      ln_acs_vat_det_account_id     := in_ACS_VAT_DET_ACCOUNT_ID;

      if ln_acs_vat_det_account_id is null then
        begin
          -- Décompte TVA donné est null--> recherche du décompte du pays de l'adresse principale
          ln_acs_vat_det_account_id  := pac_i_lib_lookup.getVAT_DET_ACCOUNT(pac_i_lib_lookup.getADDRESS_PRINCIPAL_CNTRY(in_PAC_SUPPLIER_PARTNER_ID) );
        exception
          when no_data_found then
            -- Décompte du pays de l'adresse principale inexistant -- > Décompte par défaut
            ln_acs_vat_det_account_id  := pac_i_lib_lookup.getDefaultVAT_DET_ACCOUNT;
        end;
      end if;

      if (iv_CURRENCY is not null) then
        ln_financial_currency_id  := acs_i_lib_lookup.getFINANCIAL_CURRENCY(iv_CURRENCY);
      end if;
    exception
      when others then
        raise;
    end;

    -- Affectation des valeurs
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_TYPE_SUBMISSION_ID', iv_DIC_TYPE_SUBMISSION_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_TYPE_PARTNER_F_ID', iv_DIC_TYPE_PARTNER_F_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_STATISTIC_F1_ID', iv_DIC_STATISTIC_F1_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_STATISTIC_F2_ID', iv_DIC_STATISTIC_F2_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_STATISTIC_F3_ID', iv_DIC_STATISTIC_F3_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_STATISTIC_F4_ID', iv_DIC_STATISTIC_F4_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_STATISTIC_F5_ID', iv_DIC_STATISTIC_F5_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_TARIFF_ID', iv_DIC_TARIFF_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PRIORITY_PAYMENT_ID', iv_DIC_PRIORITY_PAYMENT_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_CENTER_PAYMENT_ID', iv_DIC_CENTER_PAYMENT_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEVEL_PRIORITY_ID', iv_DIC_LEVEL_PRIORITY_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CRE_BLOCKED', in_CRE_BLOCKED);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CRE_REMARK', iv_CRE_REMARK);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CRE_FREE_ZONE1', iv_CRE_FREE_ZONE1);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CRE_FREE_ZONE2', iv_CRE_FREE_ZONE2);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CRE_FREE_ZONE3', iv_CRE_FREE_ZONE3);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CRE_FREE_ZONE4', iv_CRE_FREE_ZONE4);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'CRE_FREE_ZONE5', iv_CRE_FREE_ZONE5);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_REMAINDER_LAUNCHING', iv_C_REMAINDER_LAUNCHING);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_PARTNER_CATEGORY', iv_C_PARTNER_CATEGORY);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_TYPE_EDI', iv_C_TYPE_EDI);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_PARTNER_STATUS', iv_C_PARTNER_STATUS);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_ADV_MATERIAL_MODE', iv_C_ADV_MATERIAL_MODE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ACS_VAT_DET_ACCOUNT_ID', ln_acs_vat_det_account_id);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_PAYMENT_CONDITION_ID', ln_pac_payment_condition_id);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_REMAINDER_CATEGORY_ID', ln_pac_remainder_category_id);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'A_DATEMOD', Sysdate);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'A_IDMOD', pcs.PC_I_LIB_SESSION.GetUserIni);
    --Mise à jour de l'entité
    fwk_i_mgt_entity.UpdateEntity(iot_crud_definition => lt_crud_def);
    --Libèration entité
    fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if (sqlcode = EX_NOT_FOUND_NUM) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => sqlcode
                                          , iv_message       => '"' || to_char(in_PAC_SUPPLIER_PARTNER_ID) || '" does not exists'
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdateSUPPLIER_PARTNER'
                                           );
      else
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20020
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdateSUPPLIER_PARTNER'
                                           );
      end if;
  end;

  procedure DeleteSUPPLIER_PARTNER(in_PAC_SUPPLIER_PARTNER_ID in number)
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    --Initialisation entité PAC_ADRESSE
    fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_pac_entity.gcPacSupplierPartner
                       , iot_crud_definition   => lt_crud_def
                       , ib_initialize         => true
                       , in_main_id            => in_PAC_SUPPLIER_PARTNER_ID
                        );

    if (lt_crud_def.row_id is not null) then
      fwk_i_mgt_entity.DeleteEntity(iot_crud_definition => lt_crud_def);
    else
      raise EX_NOT_FOUND;
    end if;
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if (sqlcode = EX_NOT_FOUND_NUM) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => sqlcode
                                          , iv_message       => '"' || to_char(in_PAC_SUPPLIER_PARTNER_ID) || '" does not exists'
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeleteSUPPLIER_PARTNER'
                                           );
      else
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20021
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeleteSUPPLIER_PARTNER'
                                           );
      end if;
  end;

  function CreatePARTNER_CUSTOM(
    iv_PER_NAME                in varchar2
  , iv_CNTID                   in varchar2
  , iv_ADD_ADDRESS1            in varchar2
  , iv_ADD_ZIPCODE             in varchar2
  , iv_ADD_CITY                in varchar2
  , iv_LANID                   in varchar2
  , iv_EMAIL                   in varchar2
  , iv_PHONE                   in varchar2
  , iv_CONTACT_NAME            in varchar2
  , iv_CONTACT_FORENAME        in varchar2
  , iv_PAS_FUNCTION            in varchar2
  , iv_DIC_ASSOCIATION_TYPE_ID in varchar2
  , iv_THI_NO_TVA              in varchar2
  , iv_THI_NO_IDE              in varchar2
  , iv_CURRENCY                in varchar2
  , iv_PCO_DESCR               in varchar2
  , iv_DIC_TYPE_SUBMISSION_ID  in varchar2
  )
    return pac_custom_partner.pac_custom_partner_id%type
  is
    ln_PAC_PERSON_ID        pac_person.pac_person_id%type;
    ln_PAC_ADDRESS_ID       pac_address.pac_address_id%type;
    ln_PAC_COMMUNICATION_ID pac_communication.pac_communication_id%type;
    ln_PAC_ASSOCIATION_ID   pac_person_association.pac_person_association_id%type;
    ln_PAC_THIRD_ID         pac_third.pac_third_id%type;
    ln_PAC_CUSTOM_PARTNER   pac_custom_partner.pac_custom_partner_id%type;
    ln_PAC_SUPPLIER_PARTNER pac_supplier_partner.pac_supplier_partner_id%type;
    lv_PER_KEY1             pac_person.PER_KEY1%type;
    lv_DCO_EMAIL            dic_communication_type.dic_communication_type_id%type;
    lv_DCO_PHONE            dic_communication_type.dic_communication_type_id%type;
  begin
    --Création personne
    ln_PAC_PERSON_ID       := pac_e_prc_crm.CreatePerson(iv_PER_NAME => iv_PER_NAME, ov_PER_KEY1 => lv_PER_KEY1);
    --Création Adresse
    ln_PAC_ADDRESS_ID      :=
      pac_e_prc_crm.CreateADDRESS(in_PAC_PERSON_ID         => ln_PAC_PERSON_ID
                                , iv_CNTID                 => iv_CNTID
                                , iv_ADD_ADDRESS1          => iv_ADD_ADDRESS1
                                , iv_ADD_ZIPCODE           => iv_ADD_ZIPCODE
                                , iv_ADD_CITY              => iv_ADD_CITY
                                , iv_LANID                 => iv_LANID
                                , iv_DIC_ADDRESS_TYPE_ID   => pac_i_lib_lookup.getDIC_ADDRESS_TYPE_DEFAULT
                                , in_ADD_PRINCIPAL         => '1'
                                 );

    --Création Communication Email
    if iv_EMAIL is not null then
      lv_DCO_EMAIL  := PAC_I_LIB_LOOKUP.getCOM_DIC_DEFAULT('DCO_EMAIL');

      if lv_DCO_EMAIL is not null then
        ln_PAC_COMMUNICATION_ID  :=
          pac_e_prc_crm.CreateCOMMUNICATION(in_PAC_PERSON_ID               => ln_PAC_PERSON_ID
                                          , in_PAC_ADDRESS_ID              => ln_PAC_ADDRESS_ID
                                          , iv_DIC_COMMUNICATION_TYPE_ID   => lv_DCO_EMAIL
                                          , iv_COM_EXT_NUMBER              => iv_EMAIL
                                           );
      end if;
    end if;

    --Création Communication Phone
    if iv_PHONE is not null then
      lv_DCO_PHONE  := PAC_I_LIB_LOOKUP.getCOM_DIC_DEFAULT('DCO_PHONE');

      if lv_DCO_PHONE is not null then
        ln_PAC_COMMUNICATION_ID  :=
          pac_e_prc_crm.CreateCOMMUNICATION(in_PAC_PERSON_ID               => ln_PAC_PERSON_ID
                                          , in_PAC_ADDRESS_ID              => ln_PAC_ADDRESS_ID
                                          , iv_DIC_COMMUNICATION_TYPE_ID   => lv_DCO_PHONE
                                          , iv_COM_EXT_NUMBER              => iv_PHONE
                                           );
      end if;
    end if;

    --Création Association
    ln_PAC_ASSOCIATION_ID  :=
      pac_e_prc_crm.CreatePERSON_ASSOCIATION(in_PAC_PERSON_ID             => ln_PAC_PERSON_ID
                                           , in_PAC_PAC_PERSON_ID         => pac_i_lib_lookup.getPERSON_BY_NAME(iv_CONTACT_NAME, iv_CONTACT_FORENAME)
                                           , iv_DIC_ASSOCIATION_TYPE_ID   => iv_DIC_ASSOCIATION_TYPE_ID
                                           , iv_PAS_FUNCTION              => iv_PAS_FUNCTION
                                            );
    --Création Tiers
    ln_PAC_THIRD_ID        := pac_e_prc_crm.CreateTHIRD(in_PAC_PERSON_ID => ln_PAC_PERSON_ID, iv_THI_NO_TVA => iv_THI_NO_TVA, iv_THI_NO_IDE => iv_THI_NO_IDE);
    --Création Client
    ln_PAC_CUSTOM_PARTNER  :=
      pac_e_prc_crm.CreateCUSTOM_PARTNER(in_PAC_PERSON_ID            => ln_PAC_PERSON_ID
                                       , iv_DIC_TYPE_SUBMISSION_ID   => iv_DIC_TYPE_SUBMISSION_ID
                                       , iv_CURRENCY                 => iv_CURRENCY
                                       , iv_PCO_DESCR                => iv_PCO_DESCR
                                        );
    return ln_PAC_CUSTOM_PARTNER;
  end;

  function CreatePARTNER_SUPPLIER(
    iv_PER_NAME                in varchar2
  , iv_CNTID                   in varchar2
  , iv_ADD_ADDRESS1            in varchar2
  , iv_ADD_ZIPCODE             in varchar2
  , iv_ADD_CITY                in varchar2
  , iv_LANID                   in varchar2
  , iv_EMAIL                   in varchar2
  , iv_PHONE                   in varchar2
  , iv_CONTACT_NAME            in varchar2
  , iv_CONTACT_FORENAME        in varchar2
  , iv_PAS_FUNCTION            in varchar2
  , iv_DIC_ASSOCIATION_TYPE_ID in varchar2
  , iv_THI_NO_TVA              in varchar2
  , iv_THI_NO_IDE              in varchar2
  , iv_CURRENCY                in varchar2
  , iv_PCO_DESCR               in varchar2
  , iv_DIC_TYPE_SUBMISSION_ID  in varchar2
  )
    return pac_supplier_partner.pac_supplier_partner_id%type
  is
    ln_PAC_PERSON_ID        pac_person.pac_person_id%type;
    ln_PAC_ADDRESS_ID       pac_address.pac_address_id%type;
    ln_PAC_COMMUNICATION_ID pac_communication.pac_communication_id%type;
    ln_PAC_ASSOCIATION_ID   pac_person_association.pac_person_association_id%type;
    ln_PAC_THIRD_ID         pac_third.pac_third_id%type;
    ln_PAC_SUPPLIER_PARTNER pac_supplier_partner.pac_supplier_partner_id%type;
    lv_PER_KEY1             pac_person.PER_KEY1%type;
    lv_DCO_EMAIL            dic_communication_type.dic_communication_type_id%type;
    lv_DCO_PHONE            dic_communication_type.dic_communication_type_id%type;
  begin
    --Création personne
    ln_PAC_PERSON_ID         := pac_e_prc_crm.CreatePerson(iv_PER_NAME => iv_PER_NAME, ov_PER_KEY1 => lv_PER_KEY1);
    --Création Adresse
    ln_PAC_ADDRESS_ID        :=
      pac_e_prc_crm.CreateADDRESS(in_PAC_PERSON_ID         => ln_PAC_PERSON_ID
                                , iv_CNTID                 => iv_CNTID
                                , iv_ADD_ADDRESS1          => iv_ADD_ADDRESS1
                                , iv_ADD_ZIPCODE           => iv_ADD_ZIPCODE
                                , iv_ADD_CITY              => iv_ADD_CITY
                                , iv_LANID                 => iv_LANID
                                , iv_DIC_ADDRESS_TYPE_ID   => pac_i_lib_lookup.getDIC_ADDRESS_TYPE_DEFAULT
                                , in_ADD_PRINCIPAL         => '1'
                                 );

    --Création Communication Email
    if iv_EMAIL is not null then
      lv_DCO_EMAIL  := PAC_I_LIB_LOOKUP.getCOM_DIC_DEFAULT('DCO_EMAIL');

      if lv_DCO_EMAIL is not null then
        ln_PAC_COMMUNICATION_ID  :=
          pac_e_prc_crm.CreateCOMMUNICATION(in_PAC_PERSON_ID               => ln_PAC_PERSON_ID
                                          , in_PAC_ADDRESS_ID              => ln_PAC_ADDRESS_ID
                                          , iv_DIC_COMMUNICATION_TYPE_ID   => lv_DCO_EMAIL
                                          , iv_COM_EXT_NUMBER              => iv_EMAIL
                                           );
      end if;
    end if;

    --Création Communication Phone
    if iv_PHONE is not null then
      lv_DCO_PHONE  := PAC_I_LIB_LOOKUP.getCOM_DIC_DEFAULT('DCO_PHONE');

      if lv_DCO_PHONE is not null then
        ln_PAC_COMMUNICATION_ID  :=
          pac_e_prc_crm.CreateCOMMUNICATION(in_PAC_PERSON_ID               => ln_PAC_PERSON_ID
                                          , in_PAC_ADDRESS_ID              => ln_PAC_ADDRESS_ID
                                          , iv_DIC_COMMUNICATION_TYPE_ID   => lv_DCO_PHONE
                                          , iv_COM_EXT_NUMBER              => iv_PHONE
                                           );
      end if;
    end if;

    --Création Association
    ln_PAC_ASSOCIATION_ID    :=
      pac_e_prc_crm.CreatePERSON_ASSOCIATION(in_PAC_PERSON_ID             => ln_PAC_PERSON_ID
                                           , in_PAC_PAC_PERSON_ID         => pac_i_lib_lookup.getPERSON_BY_NAME(iv_CONTACT_NAME, iv_CONTACT_FORENAME)
                                           , iv_DIC_ASSOCIATION_TYPE_ID   => iv_DIC_ASSOCIATION_TYPE_ID
                                           , iv_PAS_FUNCTION              => iv_PAS_FUNCTION
                                            );
    --Création Tiers
    ln_PAC_THIRD_ID          := pac_e_prc_crm.CreateTHIRD(in_PAC_PERSON_ID => ln_PAC_PERSON_ID, iv_THI_NO_TVA => iv_THI_NO_TVA, iv_THI_NO_IDE => iv_THI_NO_IDE);
    --Création Client
    ln_PAC_SUPPLIER_PARTNER  :=
      pac_e_prc_crm.CreateSUPPLIER_PARTNER(in_PAC_PERSON_ID            => ln_PAC_PERSON_ID
                                         , iv_DIC_TYPE_SUBMISSION_ID   => iv_DIC_TYPE_SUBMISSION_ID
                                         , iv_CURRENCY                 => iv_CURRENCY
                                         , iv_PCO_DESCR                => iv_PCO_DESCR
                                          );
    return ln_PAC_SUPPLIER_PARTNER;
  end;

  function CreateEVENT(
    id_EVE_ENDDATE        in PAC_EVENT.EVE_ENDDATE%type
  , in_PAC_PERSON_ID      in PAC_EVENT.PAC_PERSON_ID%type
  , id_EVE_DATE           in PAC_EVENT.EVE_DATE%type
  , in_PAC_company_ID     in PAC_EVENT.PAC_PERSON_ID%type
  , in_PAC_LEAD_ID        in PAC_EVENT.PAC_PERSON_ID%type
  , in_PAC_EVENT_TYPE_ID  in PAC_EVENT.PAC_EVENT_TYPE_ID%type
  , iv_EVE_SUBJECT        in PAC_EVENT.EVE_SUBJECT%type
  , iv_EVE_TEXT           in PAC_EVENT.EVE_TEXT%type
  , in_EVE_USER_ID        in PCS.PC_USER.PC_USER_ID%type
  , in_EVE_ENDED          in PAC_EVENT.EVE_ENDED%type
  , id_EVE_DATE_COMPLETED in PAC_EVENT.EVE_DATE_COMPLETED%type
  , in_PAC_EVENT_ID       in number default null
  , in_EVE_PRIVATE        in PAC_EVENT.EVE_PRIVATE%type default null
  )
    return pac_event.pac_event_id%type
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
    ln_result   pac_event.pac_event_id%type;
  begin
    --Initialisation entité PAC_PERSON
    fwk_i_mgt_entity.new(iv_entity_name => fwk_i_typ_pac_entity.gcPacEvent, iot_crud_definition => lt_crud_def);
    -- Affectation des valeurs
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_PERSON_ID', in_PAC_company_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'EVE_ENDDATE', id_EVE_ENDDATE);

    if     in_PAC_company_ID is not null
       and in_PAC_PERSON_ID is not null then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_ASSOCIATION_ID', pac_i_lib_lookup.getperson_association(in_PAC_company_ID, in_PAC_PERSON_ID) );
    end if;

    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_EVENT_ID', in_PAC_EVENT_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'EVE_DATE', id_EVE_DATE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'EVE_CAPTURE_DATE', id_EVE_DATE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_LEAD_ID', in_PAC_LEAD_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_EVENT_TYPE_ID', in_PAC_EVENT_TYPE_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'EVE_SUBJECT', iv_EVE_SUBJECT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'EVE_TEXT', iv_EVE_TEXT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'EVE_USER_ID', nvl(in_EVE_USER_ID, PCS.PC_I_LIB_SESSION.GETUSERID) );
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'EVE_ENDED', in_EVE_ENDED);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'EVE_DATE_COMPLETED', id_EVE_DATE_COMPLETED);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PC_USER_ID', nvl(in_EVE_USER_ID, PCS.PC_I_LIB_SESSION.GETUSERID) );
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'EVE_PRIVATE', in_EVE_PRIVATE);
    --Ajout du record
    fwk_i_mgt_entity.InsertEntity(iot_crud_definition => lt_crud_def);
    --Récupération des valeurs de retour
    ln_result  := fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'PAC_EVENT_ID');
    --Libèration entité
    fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
    return ln_result;
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
      fwk_i_mgt_exception.raise_exception(in_error_code    => -20004
                                        , iv_message       => sqlerrm
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CreateEVENT'
                                         );
  end CreateEVENT;

  procedure DeleteEVENT(in_PAC_EVENT_ID in PAC_EVENT.PAC_EVENT_ID%type)
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    --Initialisation entité PAC_EVENT
    fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_pac_entity.gcPacEvent
                       , iot_crud_definition   => lt_crud_def
                       , ib_initialize         => true
                       , in_main_id            => in_PAC_EVENT_ID
                        );

    if (lt_crud_def.row_id is not null) then
      fwk_i_mgt_entity.DeleteEntity(iot_crud_definition => lt_crud_def);
    else
      raise EX_NOT_FOUND;
    end if;
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if (sqlcode = EX_NOT_FOUND_NUM) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => sqlcode
                                          , iv_message       => '"' || to_char(in_PAC_EVENT_ID) || '" does not exists'
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeleteEVENT'
                                           );
      else
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20015
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeleteEVENT'
                                           );
      end if;
  end DeleteEVENT;

  procedure UpdateEVENT(
    in_PAC_EVENT_ID       in PAC_EVENT.PAC_EVENT_ID%type
  , id_EVE_ENDDATE        in PAC_EVENT.EVE_ENDDATE%type
  , in_PAC_PERSON_ID      in PAC_EVENT.PAC_PERSON_ID%type
  , id_EVE_DATE           in PAC_EVENT.EVE_DATE%type
  , in_PAC_company_ID     in PAC_EVENT.PAC_PERSON_ID%type
  , in_PAC_LEAD_ID        in PAC_EVENT.PAC_PERSON_ID%type
  , in_PAC_EVENT_TYPE_ID  in PAC_EVENT.PAC_EVENT_TYPE_ID%type
  , iv_EVE_SUBJECT        in PAC_EVENT.EVE_SUBJECT%type
  , iv_EVE_TEXT           in PAC_EVENT.EVE_TEXT%type
  , in_EVE_ENDED          in PAC_EVENT.EVE_ENDED%type
  , id_EVE_DATE_COMPLETED in PAC_EVENT.EVE_DATE_COMPLETED%type
  , in_EVE_USER_ID        in PCS.PC_USER.PC_USER_ID%type
  )
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    --Initialisation entité
    fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_pac_entity.gcPacEvent
                       , iot_crud_definition   => lt_crud_def
                       , ib_initialize         => true
                       , in_main_id            => in_PAC_EVENT_ID
                        );

    if (lt_crud_def.row_id is null) then
      raise EX_NOT_FOUND;
    end if;

    -- Affectation des valeurs
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_PERSON_ID', in_PAC_company_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'EVE_ENDDATE', id_EVE_ENDDATE);

    if in_PAC_PERSON_ID is not null then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_ASSOCIATION_ID', pac_i_lib_lookup.getperson_association(in_PAC_company_ID, in_PAC_PERSON_ID) );
    else
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_ASSOCIATION_ID', in_PAC_PERSON_ID);
    end if;

    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'EVE_DATE', id_EVE_DATE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_LEAD_ID', in_PAC_LEAD_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_EVENT_TYPE_ID', in_PAC_EVENT_TYPE_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'EVE_SUBJECT', iv_EVE_SUBJECT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'EVE_TEXT', iv_EVE_TEXT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'EVE_ENDED', in_EVE_ENDED);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'EVE_DATE_COMPLETED', id_EVE_DATE_COMPLETED);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'EVE_USER_ID', nvl(in_EVE_USER_ID, PCS.PC_I_LIB_SESSION.GETUSERID) );
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'A_DATEMOD', Sysdate);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'A_IDMOD', pcs.PC_I_LIB_SESSION.GetUserIni);
    --Mise à jour de l'entité
    fwk_i_mgt_entity.UpdateEntity(iot_crud_definition => lt_crud_def);
    --Libèration entité
    fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if (sqlcode = EX_NOT_FOUND_NUM) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => sqlcode
                                          , iv_message       => '"' || to_char(in_PAC_EVENT_ID) || '" does not exists'
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdateEVENT'
                                           );
      else
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20017
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdateEVENT'
                                           );
      end if;
  end UpdateEVENT;

  function CreateLEAD(
    in_PAC_PERSON_ID             in PAC_LEAD.PAC_PERSON_ID%type
  , iv_C_LEAD_STATUS             in PAC_LEAD.C_LEAD_STATUS%type
  , iv_LEA_LABEL                 in PAC_LEAD.LEA_LABEL%type
  , iv_LEA_COMMENT               in PAC_LEAD.LEA_COMMENT%type
  , iv_DIC_LEA_SOURCE_ID         in PAC_LEAD.DIC_LEA_SOURCE_ID%type
  , iv_LEA_SOURCE_COMMENT        in PAC_LEAD.LEA_SOURCE_COMMENT%type
  , iv_LEA_SOURCE_NR             in PAC_LEAD.LEA_SOURCE_NR%type
  , iv_DIC_LEA_CLASSIFICATION_ID in PAC_LEAD.DIC_LEA_CLASSIFICATION_ID%type
  , in_PAC_REPRESENTATIVE_ID     in PAC_LEAD.PAC_REPRESENTATIVE_ID%type
  , in_LEA_USER_ID               in PAC_LEAD.LEA_USER_ID%type
  , iv_C_OPPORTUNITY_STATUS      in PAC_LEAD.C_OPPORTUNITY_STATUS%type
  , iv_LEA_RESULT_COMMENT        in PAC_LEAD.LEA_RESULT_COMMENT%type
  , iv_DIC_LEA_NEXT_STEP_ID      in PAC_LEAD.DIC_LEA_NEXT_STEP_ID%type
  , iv_DIC_LEA_RATING_ID         in PAC_LEAD.DIC_LEA_RATING_ID%type
  , iv_currency                  in pcs.pc_curr.currency%type
  , in_LEA_BUDGET_AMOUNT         in PAC_LEAD.LEA_BUDGET_AMOUNT%type
  , id_LEA_OFFER_DEADLINE        in PAC_LEAD.LEA_OFFER_DEADLINE%type
  , id_LEA_PROJECT_BEGIN_DATE    in PAC_LEAD.LEA_PROJECT_BEGIN_DATE%type
  , id_LEA_PROJECT_END_DATE      in PAC_LEAD.LEA_PROJECT_END_DATE%type
  , id_LEA_DATE                  in PAC_LEAD.LEA_DATE%type
  , in_LEA_CONTACT_PERSON_ID     in PAC_LEAD.LEA_CONTACT_PERSON_ID%type
  , iv_LEA_NEXT_STEP_DEADLINE    in PAC_LEAD.LEA_NEXT_STEP_DEADLINE%type
  , iv_LEA_COMPANY_NAME          in PAC_LEAD.LEA_COMPANY_NAME%type
  , iv_LEA_COMP_ADDRESS          in PAC_LEAD.LEA_COMP_ADDRESS%type
  , iv_LEA_COMP_ZIPCODE          in PAC_LEAD.LEA_COMP_ZIPCODE%type
  , iv_LEA_COMP_CITY             in PAC_LEAD.LEA_COMP_CITY%type
  , iv_cntid                     in pcs.pc_cntry.cntid%type
  , iv_lanid                     in pcs.pc_lang.lanID%type
  , iv_DIC_PERSON_POLITNESS_ID   in PAC_LEAD.DIC_PERSON_POLITNESS_ID%type
  , iv_LEA_CONTACT_NAME          in PAC_LEAD.LEA_CONTACT_NAME%type
  , iv_LEA_CONTACT_FORENAME      in PAC_LEAD.LEA_CONTACT_FORENAME%type
  , iv_LEA_CONTACT_LANG_ID       in PAC_LEAD.LEA_CONTACT_LANG_ID%type
  , iv_LEA_CONTACT_FUNCTION      in PAC_LEAD.LEA_CONTACT_FUNCTION%type
  , iv_DIC_ASSOCIATION_TYPE_ID   in PAC_LEAD.DIC_ASSOCIATION_TYPE_ID%type
  , iv_LEA_CONTACT_PHONE         in PAC_LEAD.LEA_CONTACT_PHONE%type
  , iv_LEA_CONTACT_FAX           in PAC_LEAD.LEA_CONTACT_FAX%type
  , iv_LEA_CONTACT_MOBILE        in PAC_LEAD.LEA_CONTACT_MOBILE%type
  , iv_LEA_CONTACT_EMAIL         in PAC_LEAD.LEA_CONTACT_EMAIL%type
  , iv_LEA_NUMBER                in PAC_LEAD.LEA_NUMBER%type
  , iv_DIC_LEA_PROJ_STEP_ID      in PAC_LEAD.DIC_LEA_PROJ_STEP_ID%type
  , iv_DIC_LEA_REASON_ID         in PAC_LEAD.DIC_LEA_REASON_ID%type
  , iv_DIC_LEA_REASON_2_ID       in PAC_LEAD.DIC_LEA_REASON_2_ID%type
  , iv_LEA_REASON_COMMENT        in PAC_LEAD.LEA_REASON_COMMENT%type
  , iv_DIC_LEA_REASON_CUST_ID    in PAC_LEAD.DIC_LEA_REASON_CUST_ID%type
  , iv_DIC_LEA_REASON_CUST_2_ID  in PAC_LEAD.DIC_LEA_REASON_CUST_2_ID%type
  , iv_LEA_REASON_COMMENT_CUST   in PAC_LEAD.LEA_REASON_COMMENT_CUST%type
  , iv_DIC_LEA_CATEGORY_ID       in PAC_LEAD.DIC_LEA_CATEGORY_ID%type
  , iv_DIC_LEA_SUBCATEGORY_ID    in PAC_LEAD.DIC_LEA_SUBCATEGORY_ID%type
  , in_PAC_LEAD_ID               in PAC_LEAD.PAC_LEAD_ID%type
  )
    return pac_lead.pac_lead_id%type
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
    ln_result   pac_lead.pac_lead_id%type;
  begin
    --Initialisation entité PAC_PERSON
    fwk_i_mgt_entity.new(iv_entity_name => fwk_i_typ_pac_entity.gcPacLead, iot_crud_definition => lt_crud_def);
    -- Affectation des valeurs
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_LEAD_ID', in_PAC_LEAD_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_PERSON_ID', in_PAC_PERSON_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_LEAD_STATUS', iv_C_LEAD_STATUS);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_LABEL', iv_LEA_LABEL);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_COMMENT', iv_LEA_COMMENT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEA_SOURCE_ID', iv_DIC_LEA_SOURCE_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_SOURCE_COMMENT', iv_LEA_SOURCE_COMMENT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_SOURCE_NR', iv_LEA_SOURCE_NR);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEA_CLASSIFICATION_ID', iv_DIC_LEA_CLASSIFICATION_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_REPRESENTATIVE_ID', in_PAC_REPRESENTATIVE_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_USER_ID', in_LEA_USER_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_OPPORTUNITY_STATUS', iv_C_OPPORTUNITY_STATUS);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_RESULT_COMMENT', iv_LEA_RESULT_COMMENT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEA_NEXT_STEP_ID', iv_DIC_LEA_NEXT_STEP_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEA_RATING_ID', iv_DIC_LEA_RATING_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEA_CATEGORY_ID', iv_DIC_LEA_CATEGORY_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEA_SUBCATEGORY_ID', iv_DIC_LEA_SUBCATEGORY_ID);

    if iv_CURRENCY is not null then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PC_CURR_ID', PCS.PC_LIB_LOOKUP.getCURRENCY(iv_CURRENCY) );
    end if;

    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_BUDGET_AMOUNT', in_LEA_BUDGET_AMOUNT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_OFFER_DEADLINE', iD_LEA_OFFER_DEADLINE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_PROJECT_BEGIN_DATE', id_LEA_PROJECT_BEGIN_DATE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_PROJECT_END_DATE', id_LEA_PROJECT_END_DATE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_DATE', id_LEA_DATE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_CONTACT_PERSON_ID', in_LEA_CONTACT_PERSON_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_NEXT_STEP_DEADLINE', iv_LEA_NEXT_STEP_DEADLINE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_COMPANY_NAME', iv_LEA_COMPANY_NAME);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_COMP_ADDRESS', iv_LEA_COMP_ADDRESS);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_COMP_ZIPCODE', iv_LEA_COMP_ZIPCODE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_COMP_CITY', iv_LEA_COMP_CITY);

    if iv_CNTID is not null then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PC_CNTRY_ID', PCS.PC_LIB_LOOKUP.getCNTRY(iv_CNTID) );
    end if;

    if iv_LANID is not null then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PC_LANG_ID', PCS.PC_LIB_LOOKUP.getLANG(iv_LANID) );
    end if;

    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PERSON_POLITNESS_ID', iv_DIC_PERSON_POLITNESS_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_CONTACT_NAME', iv_LEA_CONTACT_NAME);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_CONTACT_FORENAME', iv_LEA_CONTACT_FORENAME);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_CONTACT_LANG_ID', iv_LEA_CONTACT_LANG_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_CONTACT_FUNCTION', iv_LEA_CONTACT_FUNCTION);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_ASSOCIATION_TYPE_ID', iv_DIC_ASSOCIATION_TYPE_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_CONTACT_PHONE', iv_LEA_CONTACT_PHONE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_CONTACT_FAX', iv_LEA_CONTACT_FAX);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_CONTACT_MOBILE', iv_LEA_CONTACT_MOBILE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_CONTACT_EMAIL', iv_LEA_CONTACT_EMAIL);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_NUMBER', iv_LEA_NUMBER);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEA_PROJ_STEP_ID', iv_DIC_LEA_PROJ_STEP_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEA_REASON_ID', iv_DIC_LEA_REASON_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEA_REASON_2_ID', iv_DIC_LEA_REASON_2_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_REASON_COMMENT', iv_LEA_REASON_COMMENT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEA_REASON_CUST_ID', iv_DIC_LEA_REASON_CUST_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEA_REASON_CUST_2_ID', iv_DIC_LEA_REASON_CUST_2_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_REASON_COMMENT_CUST', iv_LEA_REASON_COMMENT_CUST);
    --Ajout du record
    fwk_i_mgt_entity.InsertEntity(iot_crud_definition => lt_crud_def);
    --Récupération des valeurs de retour
    ln_result  := fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'PAC_LEAD_ID');
    --Libèration entité
    fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
    return ln_result;
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
      fwk_i_mgt_exception.raise_exception(in_error_code    => -20004
                                        , iv_message       => sqlerrm
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CreateLEAD'
                                         );
  end CreateLEAD;

  procedure DeleteLEAD(in_PAC_LEAD_ID in PAC_EVENT.PAC_LEAD_ID%type)
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    --Initialisation entité PAC_EVENT
    fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_pac_entity.gcPacLead
                       , iot_crud_definition   => lt_crud_def
                       , ib_initialize         => true
                       , in_main_id            => in_PAC_LEAD_ID
                        );

    if (lt_crud_def.row_id is not null) then
      fwk_i_mgt_entity.DeleteEntity(iot_crud_definition => lt_crud_def);
    else
      raise EX_NOT_FOUND;
    end if;
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if (sqlcode = EX_NOT_FOUND_NUM) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => sqlcode
                                          , iv_message       => '"' || to_char(in_PAC_LEAD_ID) || '" does not exists'
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeleteEVENT'
                                           );
      else
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20015
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeleteEVENT'
                                           );
      end if;
  end DeleteLEAD;

  procedure UpdateLEAD(
    in_PAC_LEAD_ID               in PAC_LEAD.PAC_LEAD_ID%type
  , in_PAC_PERSON_ID             in PAC_LEAD.PAC_PERSON_ID%type
  , iv_C_LEAD_STATUS             in PAC_LEAD.C_LEAD_STATUS%type
  , iv_LEA_LABEL                 in PAC_LEAD.LEA_LABEL%type
  , iv_LEA_COMMENT               in PAC_LEAD.LEA_COMMENT%type
  , iv_DIC_LEA_SOURCE_ID         in PAC_LEAD.DIC_LEA_SOURCE_ID%type
  , iv_LEA_SOURCE_COMMENT        in PAC_LEAD.LEA_SOURCE_COMMENT%type
  , iv_LEA_SOURCE_NR             in PAC_LEAD.LEA_SOURCE_NR%type
  , iv_DIC_LEA_CLASSIFICATION_ID in PAC_LEAD.DIC_LEA_CLASSIFICATION_ID%type
  , in_PAC_REPRESENTATIVE_ID     in PAC_LEAD.PAC_REPRESENTATIVE_ID%type
  , in_LEA_USER_ID               in PAC_LEAD.LEA_USER_ID%type
  , iv_C_OPPORTUNITY_STATUS      in PAC_LEAD.C_OPPORTUNITY_STATUS%type
  , iv_LEA_RESULT_COMMENT        in PAC_LEAD.LEA_RESULT_COMMENT%type
  , iv_DIC_LEA_NEXT_STEP_ID      in PAC_LEAD.DIC_LEA_NEXT_STEP_ID%type
  , iv_DIC_LEA_RATING_ID         in PAC_LEAD.DIC_LEA_RATING_ID%type
  , iv_currency                  in pcs.pc_curr.currency%type
  , in_LEA_BUDGET_AMOUNT         in PAC_LEAD.LEA_BUDGET_AMOUNT%type
  , id_LEA_OFFER_DEADLINE        in PAC_LEAD.LEA_OFFER_DEADLINE%type
  , id_LEA_PROJECT_BEGIN_DATE    in PAC_LEAD.LEA_PROJECT_BEGIN_DATE%type
  , id_LEA_PROJECT_END_DATE      in PAC_LEAD.LEA_PROJECT_END_DATE%type
  , id_LEA_DATE                  in PAC_LEAD.LEA_DATE%type
  , in_LEA_CONTACT_PERSON_ID     in PAC_LEAD.LEA_CONTACT_PERSON_ID%type
  , iv_LEA_NEXT_STEP_DEADLINE    in PAC_LEAD.LEA_NEXT_STEP_DEADLINE%type
  , iv_LEA_COMPANY_NAME          in PAC_LEAD.LEA_COMPANY_NAME%type
  , iv_LEA_COMP_ADDRESS          in PAC_LEAD.LEA_COMP_ADDRESS%type
  , iv_LEA_COMP_ZIPCODE          in PAC_LEAD.LEA_COMP_ZIPCODE%type
  , iv_LEA_COMP_CITY             in PAC_LEAD.LEA_COMP_CITY%type
  , iv_cntid                     in pcs.pc_cntry.cntid%type
  , iv_lanid                     in pcs.pc_lang.lanID%type
  , iv_DIC_PERSON_POLITNESS_ID   in PAC_LEAD.DIC_PERSON_POLITNESS_ID%type
  , iv_LEA_CONTACT_NAME          in PAC_LEAD.LEA_CONTACT_NAME%type
  , iv_LEA_CONTACT_FORENAME      in PAC_LEAD.LEA_CONTACT_FORENAME%type
  , iv_LEA_CONTACT_LANG_ID       in PAC_LEAD.LEA_CONTACT_LANG_ID%type
  , iv_LEA_CONTACT_FUNCTION      in PAC_LEAD.LEA_CONTACT_FUNCTION%type
  , iv_DIC_ASSOCIATION_TYPE_ID   in PAC_LEAD.DIC_ASSOCIATION_TYPE_ID%type
  , iv_LEA_CONTACT_PHONE         in PAC_LEAD.LEA_CONTACT_PHONE%type
  , iv_LEA_CONTACT_FAX           in PAC_LEAD.LEA_CONTACT_FAX%type
  , iv_LEA_CONTACT_MOBILE        in PAC_LEAD.LEA_CONTACT_MOBILE%type
  , iv_LEA_CONTACT_EMAIL         in PAC_LEAD.LEA_CONTACT_EMAIL%type
  , iv_LEA_NUMBER                in PAC_LEAD.LEA_NUMBER%type
  , iv_DIC_LEA_PROJ_STEP_ID      in PAC_LEAD.DIC_LEA_PROJ_STEP_ID%type
  , iv_DIC_LEA_REASON_ID         in PAC_LEAD.DIC_LEA_REASON_ID%type
  , iv_DIC_LEA_REASON_2_ID       in PAC_LEAD.DIC_LEA_REASON_2_ID%type
  , iv_LEA_REASON_COMMENT        in PAC_LEAD.LEA_REASON_COMMENT%type
  , iv_DIC_LEA_REASON_CUST_ID    in PAC_LEAD.DIC_LEA_REASON_CUST_ID%type
  , iv_DIC_LEA_REASON_CUST_2_ID  in PAC_LEAD.DIC_LEA_REASON_CUST_2_ID%type
  , iv_LEA_REASON_COMMENT_CUST   in PAC_LEAD.LEA_REASON_COMMENT_CUST%type
  , iv_DIC_LEA_CATEGORY_ID       in PAC_LEAD.DIC_LEA_CATEGORY_ID%type
  , iv_DIC_LEA_SUBCATEGORY_ID    in PAC_LEAD.DIC_LEA_SUBCATEGORY_ID%type
  )
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    --Initialisation entité
    fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_pac_entity.gcPacLead
                       , iot_crud_definition   => lt_crud_def
                       , ib_initialize         => true
                       , in_main_id            => in_PAC_LEAD_ID
                        );

    if (lt_crud_def.row_id is null) then
      raise EX_NOT_FOUND;
    end if;

    -- Affectation des valeurs
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_PERSON_ID', in_PAC_PERSON_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_LEAD_STATUS', iv_C_LEAD_STATUS);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_LABEL', iv_LEA_LABEL);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_COMMENT', iv_LEA_COMMENT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEA_SOURCE_ID', iv_DIC_LEA_SOURCE_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_SOURCE_COMMENT', iv_LEA_SOURCE_COMMENT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_SOURCE_NR', iv_LEA_SOURCE_NR);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEA_CLASSIFICATION_ID', iv_DIC_LEA_CLASSIFICATION_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_REPRESENTATIVE_ID', in_PAC_REPRESENTATIVE_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_USER_ID', in_LEA_USER_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_OPPORTUNITY_STATUS', iv_C_OPPORTUNITY_STATUS);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_RESULT_COMMENT', iv_LEA_RESULT_COMMENT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEA_NEXT_STEP_ID', iv_DIC_LEA_NEXT_STEP_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEA_RATING_ID', iv_DIC_LEA_RATING_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEA_CATEGORY_ID', iv_DIC_LEA_CATEGORY_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEA_SUBCATEGORY_ID', iv_DIC_LEA_SUBCATEGORY_ID);

    if iv_CURRENCY is not null then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PC_CURR_ID', PCS.PC_LIB_LOOKUP.getCURRENCY(iv_CURRENCY) );
    end if;

    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_BUDGET_AMOUNT', in_LEA_BUDGET_AMOUNT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_OFFER_DEADLINE', iD_LEA_OFFER_DEADLINE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_PROJECT_BEGIN_DATE', id_LEA_PROJECT_BEGIN_DATE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_PROJECT_END_DATE', id_LEA_PROJECT_END_DATE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_DATE', id_LEA_DATE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_CONTACT_PERSON_ID', in_LEA_CONTACT_PERSON_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_NEXT_STEP_DEADLINE', iv_LEA_NEXT_STEP_DEADLINE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_COMPANY_NAME', iv_LEA_COMPANY_NAME);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_COMP_ADDRESS', iv_LEA_COMP_ADDRESS);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_COMP_ZIPCODE', iv_LEA_COMP_ZIPCODE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_COMP_CITY', iv_LEA_COMP_CITY);

    if iv_CNTID is not null then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PC_CNTRY_ID', PCS.PC_LIB_LOOKUP.getCNTRY(iv_CNTID) );
    end if;

    if iv_LANID is not null then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PC_LANG_ID', PCS.PC_LIB_LOOKUP.getLANG(iv_LANID) );
    end if;

    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PERSON_POLITNESS_ID', iv_DIC_PERSON_POLITNESS_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_CONTACT_NAME', iv_LEA_CONTACT_NAME);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_CONTACT_FORENAME', iv_LEA_CONTACT_FORENAME);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_CONTACT_LANG_ID', iv_LEA_CONTACT_LANG_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_CONTACT_FUNCTION', iv_LEA_CONTACT_FUNCTION);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_ASSOCIATION_TYPE_ID', iv_DIC_ASSOCIATION_TYPE_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_CONTACT_PHONE', iv_LEA_CONTACT_PHONE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_CONTACT_FAX', iv_LEA_CONTACT_FAX);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_CONTACT_MOBILE', iv_LEA_CONTACT_MOBILE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_CONTACT_EMAIL', iv_LEA_CONTACT_EMAIL);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_NUMBER', iv_LEA_NUMBER);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEA_PROJ_STEP_ID', iv_DIC_LEA_PROJ_STEP_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEA_REASON_ID', iv_DIC_LEA_REASON_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEA_REASON_2_ID', iv_DIC_LEA_REASON_2_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_REASON_COMMENT', iv_LEA_REASON_COMMENT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEA_REASON_CUST_ID', iv_DIC_LEA_REASON_CUST_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEA_REASON_CUST_2_ID', iv_DIC_LEA_REASON_CUST_2_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEA_REASON_COMMENT_CUST', iv_LEA_REASON_COMMENT_CUST);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'A_DATEMOD', Sysdate);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'A_IDMOD', pcs.PC_I_LIB_SESSION.GetUserIni);
    --Mise à jour de l'entité
    fwk_i_mgt_entity.UpdateEntity(iot_crud_definition => lt_crud_def);
    --Libèration entité
    fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if (sqlcode = EX_NOT_FOUND_NUM) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => sqlcode
                                          , iv_message       => '"' || to_char(in_PAC_LEAD_ID) || '" does not exists'
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdateLEAD'
                                           );
      else
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20017
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdateLEAD'
                                           );
      end if;
  end UpdateLEAD;

  function CreateLEAD_OFFER(
    in_PAC_LEAD_OFFER_ID           in PAC_LEAD_OFFER.PAC_LEAD_OFFER_ID%type
  , iv_LEO_NUMBER                  in PAC_LEAD_OFFER.LEO_NUMBER%type
  , in_PAC_LEAD_ID                 in PAC_LEAD_OFFER.PAC_LEAD_ID%type
  , id_LEO_DATE                    in PAC_LEAD_OFFER.LEO_DATE%type
  , iv_LEO_COMMENT                 in PAC_LEAD_OFFER.LEO_COMMENT%type
  , in_LEO_PRICE                   in PAC_LEAD_OFFER.LEO_PRICE%type
  , iv_currency                    in pcs.pc_curr.currency%type
  , in_DOC_DOCUMENT_ID             in PAC_LEAD_OFFER.DOC_DOCUMENT_ID%type
  , iv_C_LEO_STATUS                in PAC_LEAD_OFFER.C_LEO_STATUS%type
  , iv_DIC_LEO_QUALIF_ID           in PAC_LEAD_OFFER.DIC_LEO_QUALIF_ID%type
  , iv_DIC_PAC_LEA_OFFER_FREE01_ID in PAC_LEAD_OFFER.DIC_PAC_LEAD_OFFER_FREE01_ID%type
  , iv_DIC_PAC_LEA_OFFER_FREE02_ID in PAC_LEAD_OFFER.DIC_PAC_LEAD_OFFER_FREE02_ID%type
  , iv_DIC_PAC_LEA_OFFER_FREE03_ID in PAC_LEAD_OFFER.DIC_PAC_LEAD_OFFER_FREE03_ID%type
  , iv_DIC_PAC_LEA_OFFER_FREE04_ID in PAC_LEAD_OFFER.DIC_PAC_LEAD_OFFER_FREE04_ID%type
  , iv_DIC_PAC_LEA_OFFER_FREE05_ID in PAC_LEAD_OFFER.DIC_PAC_LEAD_OFFER_FREE05_ID%type
  , iv_DIC_PAC_LEA_OFFER_FREE06_ID in PAC_LEAD_OFFER.DIC_PAC_LEAD_OFFER_FREE06_ID%type
  , iv_DIC_PAC_LEA_OFFER_FREE07_ID in PAC_LEAD_OFFER.DIC_PAC_LEAD_OFFER_FREE07_ID%type
  , iv_DIC_PAC_LEA_OFFER_FREE08_ID in PAC_LEAD_OFFER.DIC_PAC_LEAD_OFFER_FREE08_ID%type
  , iv_DIC_PAC_LEA_OFFER_FREE09_ID in PAC_LEAD_OFFER.DIC_PAC_LEAD_OFFER_FREE09_ID%type
  , iv_DIC_PAC_LEA_OFFER_FREE10_ID in PAC_LEAD_OFFER.DIC_PAC_LEAD_OFFER_FREE10_ID%type
  , iv_DIC_QUOTE_TYPE_ID           in PAC_LEAD_OFFER.DIC_QUOTE_TYPE_ID%type
  )
    return pac_lead_offer.pac_lead_offer_id%type
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
    ln_result   pac_lead_offer.pac_lead_offer_id%type;
  begin
    --Initialisation entité PAC_LEAD_OFFER
    fwk_i_mgt_entity.new(iv_entity_name => fwk_i_typ_pac_entity.gcPacLeadOffer, iot_crud_definition => lt_crud_def);
    -- Affectation des valeurs
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_LEAD_OFFER_ID', in_PAC_LEAD_OFFER_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEO_NUMBER', iv_LEO_NUMBER);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_LEAD_ID', in_PAC_LEAD_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEO_DATE', id_LEO_DATE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEO_COMMENT', iv_LEO_COMMENT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEO_PRICE', in_LEO_PRICE);

    if iv_CURRENCY is not null then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PC_CURR_ID', PCS.PC_LIB_LOOKUP.getCURRENCY(iv_CURRENCY) );
    end if;

    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DOC_DOCUMENT_ID', in_DOC_DOCUMENT_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_LEO_STATUS', iv_C_LEO_STATUS);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEO_QUALIF_ID', iv_DIC_LEO_QUALIF_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PAC_LEAD_OFFER_FREE01_ID', iv_DIC_PAC_LEA_OFFER_FREE01_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PAC_LEAD_OFFER_FREE02_ID', iv_DIC_PAC_LEA_OFFER_FREE02_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PAC_LEAD_OFFER_FREE03_ID', iv_DIC_PAC_LEA_OFFER_FREE03_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PAC_LEAD_OFFER_FREE04_ID', iv_DIC_PAC_LEA_OFFER_FREE04_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PAC_LEAD_OFFER_FREE05_ID', iv_DIC_PAC_LEA_OFFER_FREE05_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PAC_LEAD_OFFER_FREE06_ID', iv_DIC_PAC_LEA_OFFER_FREE06_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PAC_LEAD_OFFER_FREE07_ID', iv_DIC_PAC_LEA_OFFER_FREE07_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PAC_LEAD_OFFER_FREE08_ID', iv_DIC_PAC_LEA_OFFER_FREE08_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PAC_LEAD_OFFER_FREE09_ID', iv_DIC_PAC_LEA_OFFER_FREE09_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PAC_LEAD_OFFER_FREE10_ID', iv_DIC_PAC_LEA_OFFER_FREE10_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_QUOTE_TYPE_ID', iv_DIC_QUOTE_TYPE_ID);
    --Ajout du record
    fwk_i_mgt_entity.InsertEntity(iot_crud_definition => lt_crud_def);
    --Récupération des valeurs de retour
    ln_result  := fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'PAC_LEAD_OFFER_ID');
    --Libèration entité
    fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
    return ln_result;
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
      fwk_i_mgt_exception.raise_exception(in_error_code    => -20004
                                        , iv_message       => sqlerrm
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CreateLEAD_OFFER'
                                         );
  end CreateLEAD_OFFER;

  procedure UpdateLEAD_OFFER(
    in_PAC_LEAD_OFFER_ID           in PAC_LEAD_OFFER.PAC_LEAD_OFFER_ID%type
  , iv_LEO_NUMBER                  in PAC_LEAD_OFFER.LEO_NUMBER%type
  , in_PAC_LEAD_ID                 in PAC_LEAD_OFFER.PAC_LEAD_ID%type
  , id_LEO_DATE                    in PAC_LEAD_OFFER.LEO_DATE%type
  , iv_LEO_COMMENT                 in PAC_LEAD_OFFER.LEO_COMMENT%type
  , in_LEO_PRICE                   in PAC_LEAD_OFFER.LEO_PRICE%type
  , iv_currency                    in pcs.pc_curr.currency%type
  , in_DOC_DOCUMENT_ID             in PAC_LEAD_OFFER.DOC_DOCUMENT_ID%type
  , iv_C_LEO_STATUS                in PAC_LEAD_OFFER.C_LEO_STATUS%type
  , iv_DIC_LEO_QUALIF_ID           in PAC_LEAD_OFFER.DIC_LEO_QUALIF_ID%type
  , iv_DIC_PAC_LEA_OFFER_FREE01_ID in PAC_LEAD_OFFER.DIC_PAC_LEAD_OFFER_FREE01_ID%type
  , iv_DIC_PAC_LEA_OFFER_FREE02_ID in PAC_LEAD_OFFER.DIC_PAC_LEAD_OFFER_FREE02_ID%type
  , iv_DIC_PAC_LEA_OFFER_FREE03_ID in PAC_LEAD_OFFER.DIC_PAC_LEAD_OFFER_FREE03_ID%type
  , iv_DIC_PAC_LEA_OFFER_FREE04_ID in PAC_LEAD_OFFER.DIC_PAC_LEAD_OFFER_FREE04_ID%type
  , iv_DIC_PAC_LEA_OFFER_FREE05_ID in PAC_LEAD_OFFER.DIC_PAC_LEAD_OFFER_FREE05_ID%type
  , iv_DIC_PAC_LEA_OFFER_FREE06_ID in PAC_LEAD_OFFER.DIC_PAC_LEAD_OFFER_FREE06_ID%type
  , iv_DIC_PAC_LEA_OFFER_FREE07_ID in PAC_LEAD_OFFER.DIC_PAC_LEAD_OFFER_FREE07_ID%type
  , iv_DIC_PAC_LEA_OFFER_FREE08_ID in PAC_LEAD_OFFER.DIC_PAC_LEAD_OFFER_FREE08_ID%type
  , iv_DIC_PAC_LEA_OFFER_FREE09_ID in PAC_LEAD_OFFER.DIC_PAC_LEAD_OFFER_FREE09_ID%type
  , iv_DIC_PAC_LEA_OFFER_FREE10_ID in PAC_LEAD_OFFER.DIC_PAC_LEAD_OFFER_FREE10_ID%type
  , iv_DIC_QUOTE_TYPE_ID           in PAC_LEAD_OFFER.DIC_QUOTE_TYPE_ID%type
  )
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    --Initialisation entité
    fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_pac_entity.gcPacLeadOffer
                       , iot_crud_definition   => lt_crud_def
                       , ib_initialize         => true
                       , in_main_id            => in_PAC_LEAD_OFFER_ID
                        );

    if (lt_crud_def.row_id is null) then
      raise EX_NOT_FOUND;
    end if;

    -- Affectation des valeurs
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_LEAD_OFFER_ID', in_PAC_LEAD_OFFER_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEO_NUMBER', iv_LEO_NUMBER);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_LEAD_ID', in_PAC_LEAD_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEO_DATE', id_LEO_DATE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEO_COMMENT', iv_LEO_COMMENT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEO_PRICE', in_LEO_PRICE);

    if iv_CURRENCY is not null then
      fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PC_CURR_ID', PCS.PC_LIB_LOOKUP.getCURRENCY(iv_CURRENCY) );
    end if;

    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DOC_DOCUMENT_ID', in_DOC_DOCUMENT_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'C_LEO_STATUS', iv_C_LEO_STATUS);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_LEO_QUALIF_ID', iv_DIC_LEO_QUALIF_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PAC_LEAD_OFFER_FREE01_ID', iv_DIC_PAC_LEA_OFFER_FREE01_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PAC_LEAD_OFFER_FREE02_ID', iv_DIC_PAC_LEA_OFFER_FREE02_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PAC_LEAD_OFFER_FREE03_ID', iv_DIC_PAC_LEA_OFFER_FREE03_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PAC_LEAD_OFFER_FREE04_ID', iv_DIC_PAC_LEA_OFFER_FREE04_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PAC_LEAD_OFFER_FREE05_ID', iv_DIC_PAC_LEA_OFFER_FREE05_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PAC_LEAD_OFFER_FREE06_ID', iv_DIC_PAC_LEA_OFFER_FREE06_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PAC_LEAD_OFFER_FREE07_ID', iv_DIC_PAC_LEA_OFFER_FREE07_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PAC_LEAD_OFFER_FREE08_ID', iv_DIC_PAC_LEA_OFFER_FREE08_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PAC_LEAD_OFFER_FREE09_ID', iv_DIC_PAC_LEA_OFFER_FREE09_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_PAC_LEAD_OFFER_FREE10_ID', iv_DIC_PAC_LEA_OFFER_FREE10_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DIC_QUOTE_TYPE_ID', iv_DIC_QUOTE_TYPE_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'A_DATEMOD', Sysdate);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'A_IDMOD', pcs.PC_I_LIB_SESSION.GetUserIni);
    --Mise à jour de l'entité
    fwk_i_mgt_entity.UpdateEntity(iot_crud_definition => lt_crud_def);
    --Libèration entité
    fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if (sqlcode = EX_NOT_FOUND_NUM) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => sqlcode
                                          , iv_message       => '"' || to_char(in_PAC_LEAD_OFFER_ID) || '" does not exists'
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdateLEAD_OFFER'
                                           );
      else
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20017
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdateLEAD_OFFER'
                                           );
      end if;
  end UpdateLEAD_OFFER;

  procedure DeleteLEAD_OFFER(in_PAC_LEAD_OFFER_ID in PAC_LEAD_OFFER.PAC_LEAD_OFFER_ID%type)
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    --Initialisation entité LEAD_OFFER
    fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_pac_entity.gcPacLeadOffer
                       , iot_crud_definition   => lt_crud_def
                       , ib_initialize         => true
                       , in_main_id            => in_PAC_LEAD_OFFER_ID
                        );

    if (lt_crud_def.row_id is not null) then
      fwk_i_mgt_entity.DeleteEntity(iot_crud_definition => lt_crud_def);
    else
      raise EX_NOT_FOUND;
    end if;
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if (sqlcode = EX_NOT_FOUND_NUM) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => sqlcode
                                          , iv_message       => '"' || to_char(in_PAC_LEAD_OFFER_ID) || '" does not exists'
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeleteEVENT_OFFER'
                                           );
      else
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20015
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeleteEVENT_OFFER'
                                           );
      end if;
  end DeleteLEAD_OFFER;

  function CreateLEAD_OFFER_GOOD(
    in_PAC_LEAD_OFFER_GOOD_ID in PAC_LEAD_OFFER_GOOD.PAC_LEAD_OFFER_GOOD_ID%type
  , in_PAC_LEAD_OFFER_ID      in PAC_LEAD_OFFER_GOOD.PAC_LEAD_OFFER_ID%type
  , in_GCO_GOOD_ID            in PAC_LEAD_OFFER_GOOD.GCO_GOOD_ID%type
  , iv_LEO_GOOD_DESCR         in PAC_LEAD_OFFER_GOOD.LEO_GOOD_DESCR%type
  , iv_LEO_GOOD_COMMENT       in PAC_LEAD_OFFER_GOOD.LEO_GOOD_COMMENT%type
  , in_LEO_GOOD_PRICE         in PAC_LEAD_OFFER_GOOD.LEO_GOOD_PRICE%type
  , in_DOC_POSITION_ID        in PAC_LEAD_OFFER_GOOD.DOC_POSITION_ID%type
  , in_LEO_GOOD_QTY           in PAC_LEAD_OFFER_GOOD.LEO_GOOD_QTY%type
  , in_LEO_GOOD_UNIT_PRICE    in PAC_LEAD_OFFER_GOOD.LEO_GOOD_UNIT_PRICE%type
  )
    return pac_lead_offer_good.pac_lead_offer_good_id%type
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
    ln_result   pac_lead_offer_good.pac_lead_offer_good_id%type;
  begin
    --Initialisation entité PAC_LEAD_OFFER_GOOD
    fwk_i_mgt_entity.new(iv_entity_name => fwk_i_typ_pac_entity.gcPacLeadOfferGood, iot_crud_definition => lt_crud_def);
    -- Affectation des valeurs
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_LEAD_OFFER_GOOD_ID', in_PAC_LEAD_OFFER_GOOD_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_LEAD_OFFER_ID', in_PAC_LEAD_OFFER_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'GCO_GOOD_ID', in_GCO_GOOD_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEO_GOOD_DESCR', iv_LEO_GOOD_DESCR);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEO_GOOD_COMMENT', iv_LEO_GOOD_COMMENT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEO_GOOD_PRICE', in_LEO_GOOD_PRICE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DOC_POSITION_ID', in_DOC_POSITION_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEO_GOOD_QTY', in_LEO_GOOD_QTY);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEO_GOOD_UNIT_PRICE', in_LEO_GOOD_UNIT_PRICE);
    --Ajout du record
    fwk_i_mgt_entity.InsertEntity(iot_crud_definition => lt_crud_def);
    --Récupération des valeurs de retour
    ln_result  := fwk_i_mgt_entity_data.GetColumnNumber(lt_crud_def, 'PAC_LEAD_OFFER_GOOD_ID');
    --Libèration entité
    fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
    return ln_result;
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
      fwk_i_mgt_exception.raise_exception(in_error_code    => -20004
                                        , iv_message       => sqlerrm
                                        , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                        , iv_cause         => 'CreateLEAD_OFFER_GOOD'
                                         );
  end CreateLEAD_OFFER_GOOD;

  procedure UpdateLEAD_OFFER_GOOD(
    in_PAC_LEAD_OFFER_GOOD_ID in PAC_LEAD_OFFER_GOOD.PAC_LEAD_OFFER_GOOD_ID%type
  , in_PAC_LEAD_OFFER_ID      in PAC_LEAD_OFFER_GOOD.PAC_LEAD_OFFER_ID%type
  , in_GCO_GOOD_ID            in PAC_LEAD_OFFER_GOOD.GCO_GOOD_ID%type
  , iv_LEO_GOOD_DESCR         in PAC_LEAD_OFFER_GOOD.LEO_GOOD_DESCR%type
  , iv_LEO_GOOD_COMMENT       in PAC_LEAD_OFFER_GOOD.LEO_GOOD_COMMENT%type
  , in_LEO_GOOD_PRICE         in PAC_LEAD_OFFER_GOOD.LEO_GOOD_PRICE%type
  , in_DOC_POSITION_ID        in PAC_LEAD_OFFER_GOOD.DOC_POSITION_ID%type
  , in_LEO_GOOD_QTY           in PAC_LEAD_OFFER_GOOD.LEO_GOOD_QTY%type
  , in_LEO_GOOD_UNIT_PRICE    in PAC_LEAD_OFFER_GOOD.LEO_GOOD_UNIT_PRICE%type
  )
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    --Initialisation entité
    fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_pac_entity.gcPacLeadOfferGood
                       , iot_crud_definition   => lt_crud_def
                       , ib_initialize         => true
                       , in_main_id            => in_PAC_LEAD_OFFER_GOOD_ID
                        );

    if (lt_crud_def.row_id is null) then
      raise EX_NOT_FOUND;
    end if;

    -- Affectation des valeurs
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_LEAD_OFFER_GOOD_ID', in_PAC_LEAD_OFFER_GOOD_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_LEAD_OFFER_ID', in_PAC_LEAD_OFFER_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'GCO_GOOD_ID', in_GCO_GOOD_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEO_GOOD_DESCR', iv_LEO_GOOD_DESCR);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEO_GOOD_COMMENT', iv_LEO_GOOD_COMMENT);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEO_GOOD_PRICE', in_LEO_GOOD_PRICE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'DOC_POSITION_ID', in_DOC_POSITION_ID);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEO_GOOD_QTY', in_LEO_GOOD_QTY);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'LEO_GOOD_UNIT_PRICE', in_LEO_GOOD_UNIT_PRICE);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'A_DATEMOD', Sysdate);
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'A_IDMOD', pcs.PC_I_LIB_SESSION.GetUserIni);
    --Mise à jour de l'entité
    fwk_i_mgt_entity.UpdateEntity(iot_crud_definition => lt_crud_def);
    --Libèration entité
    fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if (sqlcode = EX_NOT_FOUND_NUM) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => sqlcode
                                          , iv_message       => '"' || to_char(in_PAC_LEAD_OFFER_GOOD_ID) || '" does not exists'
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdateLEAD_OFFER_GOOD'
                                           );
      else
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20017
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'UpdateLEAD_OFFER_GOOD'
                                           );
      end if;
  end UpdateLEAD_OFFER_GOOD;

  procedure DeleteLEAD_OFFER_GOOD(in_PAC_LEAD_OFFER_GOOD_ID in PAC_LEAD_OFFER_GOOD.PAC_LEAD_OFFER_GOOD_ID%type)
  is
    lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
  begin
    --Initialisation entité PAC_LEAD_OFFER_GOOD
    fwk_i_mgt_entity.new(iv_entity_name        => fwk_i_typ_pac_entity.gcPacLeadOfferGood
                       , iot_crud_definition   => lt_crud_def
                       , ib_initialize         => true
                       , in_main_id            => in_PAC_LEAD_OFFER_GOOD_ID
                        );

    if (lt_crud_def.row_id is not null) then
      fwk_i_mgt_entity.DeleteEntity(iot_crud_definition => lt_crud_def);
    else
      raise EX_NOT_FOUND;
    end if;
  exception
    when others then
      fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);

      if (sqlcode = EX_NOT_FOUND_NUM) then
        fwk_i_mgt_exception.raise_exception(in_error_code    => sqlcode
                                          , iv_message       => '"' || to_char(in_PAC_LEAD_OFFER_GOOD_ID) || '" does not exists'
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeleteEVENT_OFFER_GOOD'
                                           );
      else
        fwk_i_mgt_exception.raise_exception(in_error_code    => -20015
                                          , iv_message       => sqlerrm
                                          , iv_stack_trace   => DBMS_UTILITY.format_error_backtrace
                                          , iv_cause         => 'DeleteEVENT_OFFER_GOOD'
                                           );
      end if;
  end DeleteLEAD_OFFER_GOOD;
end PAC_E_PRC_CRM;
