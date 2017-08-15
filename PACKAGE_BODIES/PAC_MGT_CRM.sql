--------------------------------------------------------
--  DDL for Package Body PAC_MGT_CRM
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_MGT_CRM" 
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
AS
--
-- Global methods
--
procedure ResetAddPrincipal(inPAC_PERSON_ID in NUMBER, inPAC_ADDRESS_ID in NUMBER)
is
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
begin
  --Initialisation entité Address
  fwk_i_mgt_entity.New(
      iv_entity_name => fwk_i_typ_pac_entity.gcPacAddress,
      iot_crud_definition => lt_crud_def);
  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'ADD_PRINCIPAL', 0);
  for tplAddress in (
    select PAC_ADDRESS_ID
    from PAC_ADDRESS
    where PAC_PERSON_ID = inPAC_PERSON_ID
      and PAC_ADDRESS_ID <> inPAC_ADDRESS_ID
      and ADD_PRINCIPAL = 1
  ) loop
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_ADDRESS_ID',tplAddress.PAC_ADDRESS_ID);
    --Mise à jour de l'entité
    fwk_i_mgt_entity.UpdateEntity(iot_crud_definition => lt_crud_def);
  end loop;
  fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
  exception
    when OTHERS then
      fwk_i_mgt_entity.Release(
        iot_crud_definition => lt_crud_def);
      fwk_i_mgt_exception.raise_exception(
        in_error_code => -20001,
        iv_message => 'Can not update address  "'||to_char(inPAC_PERSON_ID)||'"',
        iv_stack_trace => dbms_utility.format_error_backtrace,
        iv_cause => 'ResetAddPrincipal');
end;

procedure ResetMainContact(inPAC_PERSON_ID in NUMBER, inPAC_PERSON_ASSOCIATION_ID in NUMBER)
is
  lt_crud_def fwk_i_typ_definition.T_CRUD_DEF;
begin
  --Initialisation entité Address
  fwk_i_mgt_entity.New(
      iv_entity_name => fwk_i_typ_pac_entity.gcPacPersonAssociation,
      iot_crud_definition => lt_crud_def);
  fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAS_MAIN_CONTACT', 0);
  for tplAssociation in (
    select PAC_PERSON_ASSOCIATION_ID
    from PAC_PERSON_ASSOCIATION
    where PAC_PERSON_ID = inPAC_PERSON_ID
    and PAC_PERSON_ASSOCIATION_ID <> inPAC_PERSON_ASSOCIATION_ID
    and PAS_MAIN_CONTACT =  1
  ) loop
    fwk_i_mgt_entity_data.SetColumn(lt_crud_def, 'PAC_PERSON_ASSOCIATION_ID',tplAssociation.PAC_PERSON_ASSOCIATION_ID);
    --Mise à jour de l'entité
    fwk_i_mgt_entity.UpdateEntity(iot_crud_definition => lt_crud_def);
  end loop;
  fwk_i_mgt_entity.Release(iot_crud_definition => lt_crud_def);
  exception
    when OTHERS then
      fwk_i_mgt_entity.Release(
        iot_crud_definition => lt_crud_def);
      fwk_i_mgt_exception.raise_exception(
        in_error_code => -20002,
        iv_message => 'Can not update contact  "'||to_char(inPAC_PERSON_ID)||'"',
        iv_stack_trace => dbms_utility.format_error_backtrace,
        iv_cause => 'ResetMainContact');
end;

--
-- Person management
--

function InsertPERSON(
  iot_crud_definition IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF)
  return varchar2
is
begin
  --Put field PER_SHORT_NAME uppercased
  if  fwk_i_mgt_entity_data.ismodified(iot_crud_definition,'PER_SHORT_NAME') then
    fwk_i_mgt_entity_data.SetColumn(iot_crud_definition,'PER_SHORT_NAME', upper((fwk_i_mgt_entity_data.getcolumnvarchar2(iot_crud_definition,'PER_SHORT_NAME'))));
  end if;
  --Generating PER_KEY1 and PER_KEY 2 if they're null
  if fwk_i_mgt_entity_data.isnull(iot_crud_definition,'PER_KEY1') then
    fwk_i_mgt_entity_data.setcolumn(iot_crud_definition,'PER_KEY1',
                                    PAC_PARTNER_MANAGEMENT.ExtractKey(fwk_i_mgt_entity_data.getcolumnvarchar2(iot_crud_definition,'PER_SHORT_NAME'),'KEY1')
                                    );
  end if;
  if fwk_i_mgt_entity_data.isnull(iot_crud_definition,'PER_KEY2') then
    fwk_i_mgt_entity_data.setcolumn(iot_crud_definition,'PER_KEY2',
                                    PAC_PARTNER_MANAGEMENT.ExtractKey(fwk_i_mgt_entity_data.getcolumnvarchar2(iot_crud_definition,'PER_SHORT_NAME'),'KEY2')
                                    );
  end if;
  --Inserting
  return fwk_i_dml_table.CRUD(iot_crud_definition);
end;


function UpdatePERSON(
  iot_crud_definition IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF)
  return varchar2
is
begin
  --Put field PER_SHORT_NAME uppercased
  if  fwk_i_mgt_entity_data.ismodified(iot_crud_definition,'PER_SHORT_NAME') then
    fwk_i_mgt_entity_data.SetColumn(iot_crud_definition,'PER_SHORT_NAME', upper((fwk_i_mgt_entity_data.getcolumnvarchar2(iot_crud_definition,'PER_SHORT_NAME'))));
  end if;
  --Generating PER_KEY1 and PER_KEY 2 if they're null
  if fwk_i_mgt_entity_data.isnull(iot_crud_definition,'PER_KEY1') then
    fwk_i_mgt_entity_data.setcolumn(iot_crud_definition,'PER_KEY1',
                                    PAC_PARTNER_MANAGEMENT.ExtractKey(fwk_i_mgt_entity_data.getcolumnvarchar2(iot_crud_definition,'PER_SHORT_NAME'),'KEY1')
                                    );
  end if;
  if fwk_i_mgt_entity_data.isnull(iot_crud_definition,'PER_KEY2') then
    fwk_i_mgt_entity_data.setcolumn(iot_crud_definition,'PER_KEY2',
                                    PAC_PARTNER_MANAGEMENT.ExtractKey(fwk_i_mgt_entity_data.getcolumnvarchar2(iot_crud_definition,'PER_SHORT_NAME'),'KEY2')
                                    );
  end if;
  --Updating
  return fwk_i_dml_table.CRUD(iot_crud_definition);
end;


--
-- Address management
--
function InsertADDRESS(
  iot_crud_definition IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF)
  return varchar2
is
  ln_id pac_address.pac_address_id%TYPE;
begin
  if  fwk_i_mgt_entity_data.ismodified(iot_crud_definition,'DIC_ADDRESS_TYPE_ID') then
    ln_id := pac_i_lib_lookup.getADDRESS(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_definition, 'PAC_PERSON_ID'),
                                         fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_definition, 'DIC_ADDRESS_TYPE_ID'));
    if (ln_id  > 0.0 )then
      fwk_i_mgt_exception.raise_exception(
        in_error_code => -20003,
        iv_message => 'Only one address by type and by person is allowed ' || fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_definition, 'DIC_ADDRESS_TYPE_ID'),
        iv_stack_trace => dbms_utility.format_error_backtrace,
        iv_cause => 'InsertADDRESS ');
    end if;
  end if;
  --La dernière adresse principale obtient ce statut, les autres non
  if (fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_definition, 'ADD_PRINCIPAL') = 1) then
    PAC_MGT_CRM.ResetAddPrincipal(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_definition, 'PAC_PERSON_ID'),
                                  fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_definition, 'PAC_ADDRESS_ID'));
  end if;
  --Inserting
  return fwk_i_dml_table.CRUD(iot_crud_definition);
end;

function UpdateADDRESS(
  iot_crud_definition IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF)
  return varchar2
is
  ln_id pac_address.pac_address_id%TYPE;
begin
  if  fwk_i_mgt_entity_data.ismodified(iot_crud_definition,'DIC_ADDRESS_TYPE_ID') then
    ln_id := pac_i_lib_lookup.getADDRESS(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_definition, 'PAC_PERSON_ID'),
                                         fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_definition, 'DIC_ADDRESS_TYPE_ID'));
    if (ln_id  > 0.0 ) and (ln_id <> fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_definition, 'PAC_ADDRESS_ID'))then
      fwk_i_mgt_exception.raise_exception(
        in_error_code => -20004,
        iv_message => 'Only one address by type and by person is allowed ' || fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_definition, 'DIC_ADDRESS_TYPE_ID'),
        iv_stack_trace => dbms_utility.format_error_backtrace,
        iv_cause => 'UpdateADDRESS ');
    end if;
  end if;
  --La dernière adresse principale obtient ce statut, les autres non
  if (fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_definition, 'ADD_PRINCIPAL') = 1) then
    PAC_MGT_CRM.ResetAddPrincipal(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_definition, 'PAC_PERSON_ID'),
                                  fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_definition, 'PAC_ADDRESS_ID'));
  end if;
  --Updating
  return fwk_i_dml_table.CRUD(iot_crud_definition);
end;

--
-- Communication management
--
function InsertCOMMUNICATION(
  iot_crud_definition IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF)
return varchar2
is
  ln_id pac_communication.pac_communication_id%TYPE;
begin
  if  fwk_i_mgt_entity_data.ismodified(iot_crud_definition,'DIC_COMMUNICATION_TYPE_ID') then
    ln_id := pac_i_lib_lookup.getCommunication(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_definition, 'PAC_PERSON_ID'),
                                               fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_definition, 'DIC_COMMUNICATION_TYPE_ID'));
    if (ln_id  > 0.0 ) then
      fwk_i_mgt_exception.raise_exception(
        in_error_code => -20005,
        iv_message => 'Only one communication by type and by person is allowed   ' || fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_definition, 'DIC_COMMUNICATION_TYPE_ID'),
        iv_stack_trace => dbms_utility.format_error_backtrace,
        iv_cause => 'InsertCOMMUNICATION ');
    end if;
  end if;
  --Inserting
  return fwk_i_dml_table.CRUD(iot_crud_definition);
end;
function UpdateCOMMUNICATION(
iot_crud_definition IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF)
return varchar2
is
  ln_id pac_communication.pac_communication_id%TYPE;
begin
  if  fwk_i_mgt_entity_data.ismodified(iot_crud_definition,'DIC_COMMUNICATION_TYPE_ID') then
    ln_id := pac_i_lib_lookup.getCommunication(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_definition, 'PAC_PERSON_ID'),
                                               fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_definition, 'DIC_COMMUNICATION_TYPE_ID'));
    if (ln_id  > 0.0 ) and (ln_id <> fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_definition, 'PAC_COMMUNICATION_ID'))then
      fwk_i_mgt_exception.raise_exception(
        in_error_code => -20006,
        iv_message => 'Only one communication by type and by person is allowed   ' || fwk_i_mgt_entity_data.GetColumnVarchar2(iot_crud_definition, 'DIC_COMMUNICATION_TYPE_ID'),
        iv_stack_trace => dbms_utility.format_error_backtrace,
        iv_cause => 'UpdateCOMMUNICATION ');
    end if;
  end if;
  --Updating
  return fwk_i_dml_table.CRUD(iot_crud_definition);
end;

--
-- Person's association management
--
function InsertPERSON_ASSOCIATION(
  iot_crud_definition IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF)
  return varchar2
is
begin
  --Le dernier contact principal de la personne obtient ce statut, les autres non
  if (fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_definition, 'PAS_MAIN_CONTACT') = 1) then
    PAC_MGT_CRM.ResetMainContact(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_definition, 'PAC_PERSON_ID'),
                                   fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_definition, 'PAC_PERSON_ASSOCIATION_ID'));
  end if;
  --Inserting
  return fwk_i_dml_table.CRUD(iot_crud_definition);
end;
function UpdatePERSON_ASSOCIATION(
  iot_crud_definition IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF)
  return varchar2
is
begin
  --Le dernier contact principal de la personne obtient ce statut, les autres non
  if (fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_definition, 'PAS_MAIN_CONTACT') = 1) then
    PAC_MGT_CRM.ResetMainContact(fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_definition, 'PAC_PERSON_ID'),
                                   fwk_i_mgt_entity_data.GetColumnNumber(iot_crud_definition, 'PAC_PERSON_ASSOCIATION_ID'));
  end if;
  --Updating
  return fwk_i_dml_table.CRUD(iot_crud_definition);
end;


--
-- Third management
--

--
-- Customer management
--
function InsertCUSTOM_PARTNER(
  iot_crud_definition IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF)
  return varchar2
is
begin
  --Inserting
  return fwk_i_dml_table.CRUD(iot_crud_definition);
end;
function UpdateCUSTOM_PARTNER(
  iot_crud_definition IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF)
  return varchar2
is
begin
  --Updating
  return fwk_i_dml_table.CRUD(iot_crud_definition);
end;


--
-- Supplier management
--
function InsertSUPPLIER_PARTNER(
  iot_crud_definition IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF)
  return varchar2
is
begin
  --Inserting
  return fwk_i_dml_table.CRUD(iot_crud_definition);
end;
function UpdateSUPPLIER_PARTNER(
  iot_crud_definition IN OUT NOCOPY fwk_i_typ_definition.T_CRUD_DEF)
  return varchar2
is
begin
  --Updating
  return fwk_i_dml_table.CRUD(iot_crud_definition);
end;

END PAC_MGT_CRM;
