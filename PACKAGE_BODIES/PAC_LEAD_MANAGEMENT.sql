--------------------------------------------------------
--  DDL for Package Body PAC_LEAD_MANAGEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_LEAD_MANAGEMENT" 
AS

  -- Cusor for accessing Lead (PAC_LEAD) fields
  cursor csLead(pLeadId PAC_LEAD.PAC_LEAD_ID%TYPE)
  is
    SELECT * FROM pac_lead where pac_lead_id = pLeadId;
  -- Record for accessing Lead's fields
  rLead csLead%rowtype;

procedure p_setLeadId(pLeadId IN PAC_LEAD.PAC_LEAD_ID%TYPE)
is
begin
  open csLead(pLeadId);
  fetch csLead into rLead;
  close csLead;
end;

procedure p_initKeys(pShortName IN PAC_PERSON.PER_SHORT_NAME%TYPE,
  pKey1 OUT PAC_PERSON.PER_KEY1%TYPE,
  pKey2 OUT PAC_PERSON.PER_KEY2%TYPE)
is
begin
  pKey1 := pac_partner_management.extractKey(pShortName, 'KEY1');
  pKey2 := pac_partner_management.extractKey(pShortName, 'KEY2');
end;

function CreatePerson(pLeadId IN PAC_LEAD.PAC_LEAD_ID%TYPE)
  return PAC_LEAD.PAC_PERSON_ID%TYPE
is
  vNewId PAC_LEAD.PAC_PERSON_ID%TYPE;
  vUseIni PCS.PC_USER.USE_INI%TYPE;
  vKey1 PAC_PERSON.PER_KEY1%TYPE;
  vKey2 PAC_PERSON.PER_KEY2%TYPE;
  vShortName PAC_PERSON.PER_SHORT_NAME%TYPE;
begin
  p_setLeadId(pLeadId);
  vUseIni := pcs.PC_I_LIB_SESSION.getUserIni;
  vShortName := Upper(rLead.lea_company_name);
  p_initKeys(vShortName, vKey1, vKey2);

  SELECT Init_Id_Seq.NextVal INTO vNewId FROM dual;
  INSERT INTO pac_person(
    pac_person_id, per_name, per_short_name, per_key1, per_key2, a_datecre, a_idcre)
  VALUES (vNewid, rLead.lea_company_name, vShortName, vKey1, vKey2,
    sysdate, vUseIni);

  INSERT INTO pac_address(pac_address_id,pac_person_id,pc_cntry_id,
    add_address1,add_zipcode,add_city, pc_lang_id, add_principal,
    dic_address_type_id, a_datecre, a_idcre)
  VALUES (Init_Id_Seq.NextVal, vNewid, rLead.pc_cntry_id, rLead.lea_comp_address,
    rLead.lea_comp_zipcode, rLead.lea_comp_city, rLead.pc_lang_id, 1,
    pac_functions.get_address_type, sysdate, vUseIni);

  return vNewId;
end;

function CreateContact(pLeadId IN PAC_LEAD.PAC_LEAD_ID%TYPE,
  pShortName IN PAC_PERSON.PER_SHORT_NAME%TYPE)
 return PAC_LEAD.PAC_PERSON_ID%TYPE
is
  vNewId PAC_LEAD.LEA_CONTACT_PERSON_ID%TYPE;
  vAddressId PAC_ADDRESS.PAC_ADDRESS_ID%TYPE;
  vCommId DIC_COMMUNICATION_TYPE.DIC_COMMUNICATION_TYPE_ID%TYPE;
  vUseIni PCS.PC_USER.USE_INI%TYPE;
  vCntryId PAC_ADDRESS.PC_CNTRY_ID%TYPE;
  vKey1 PAC_PERSON.PER_KEY1%TYPE;
  vKey2 PAC_PERSON.PER_KEY2%TYPE;
begin
  p_setLeadId(pLeadId);
  vUseIni := pcs.PC_I_LIB_SESSION.getUserIni;
  p_initKeys(pShortName, vKey1, vKey2);

  SELECT Init_Id_Seq.NextVal INTO vNewId FROM dual;
  INSERT INTO pac_person(
    pac_person_id, dic_person_politness_id, per_name,
    per_forename, per_short_name, per_key1, per_key2, per_contact,
    a_datecre, a_idcre)
  VALUES (vNewId, rLead.dic_person_politness_id, rLead.lea_contact_name,
    rLead.lea_contact_forename, pShortName, vKey1, vKey2, 1, sysdate, vUseIni);

  INSERT INTO pac_person_association(
    pac_person_association_id, pac_person_id, pac_pac_person_id,
    dic_association_type_id, pas_function, a_datecre, a_idcre)
  VALUES (Init_Id_Seq.Nextval, rLead.pac_person_id, vNewId,
    rLead.dic_association_type_id, rLead.lea_contact_function, sysdate, vUseIni);

  SELECT Init_Id_Seq.Nextval INTO vAddressId FROM dual;

  -- Initialiser le pays avec celui de la personne...
  SELECT max(pc_cntry_id) INTO vCntryId
  FROM pac_address
  WHERE pac_person_id = rLead.pac_person_id AND
    add_principal = 1;

  INSERT INTO pac_address(
    pac_address_id,pac_person_id,pc_cntry_id,
    pc_lang_id, add_principal, dic_address_type_id,
    a_datecre, a_idcre)
  VALUES (vAddressId, vNewId, vCntryId, rLead.lea_contact_lang_id, 1,
    pac_functions.get_address_type, sysdate, vUseIni);

  if rLead.lea_contact_phone is not null then
    SELECT max(dic_communication_type_id) INTO vCommId
    FROM dic_communication_type WHERE dco_phone = 1;

    if vCommId is not null then
      INSERT INTO pac_communication(
        pac_communication_id, pac_person_id, pac_address_id,
        dic_communication_type_id, com_ext_number, a_datecre, a_idcre)
      VALUES (init_id_seq.nextval, vNewId, vAddressId, vCommId,
        rLead.lea_contact_phone, sysdate, vUseIni);
    end if;
  end if;

  if rLead.lea_contact_email is not null then
    SELECT max(dic_communication_type_id) INTO vCommId
    FROM dic_communication_type WHERE dco_email = 1;

    if vCommId is not null then
      INSERT INTO pac_communication(
        pac_communication_id, pac_person_id, pac_address_id,
        dic_communication_type_id, com_ext_number, a_datecre, a_idcre)
      VALUES (init_id_seq.nextval, vNewId, vAddressId, vCommId,
        rLead.lea_contact_email, sysdate, vUseIni);
    end if;
  end if;

  if rLead.lea_contact_fax is not null then
    SELECT max(dic_communication_type_id) INTO vCommId
    FROM dic_communication_type WHERE dco_fax = 1;

    if vCommId is not null then
      INSERT INTO pac_communication(
        pac_communication_id, pac_person_id, pac_address_id,
        dic_communication_type_id, com_ext_number, a_datecre, a_idcre)
      VALUES (init_id_seq.nextval, vNewId, vAddressId, vCommId,
        rLead.lea_contact_fax, sysdate, vUseIni);
    end if;
  end if;

  if rLead.lea_contact_mobile is not null then
    SELECT max(dic_communication_type_id) INTO vCommId
    FROM dic_communication_type WHERE dco_mobilephone = 1;

    if vCommId is not null then
      INSERT INTO pac_communication(
        pac_communication_id, pac_person_id, pac_address_id,
        dic_communication_type_id, com_ext_number, a_datecre, a_idcre)
      VALUES (init_id_seq.nextval, vNewId, vAddressId, vCommId,
        rLead.lea_contact_mobile, sysdate, vUseIni);
    end if;
  end if;

  return vNewId;

end;

function CreateAssociation(pLeadId IN PAC_LEAD.PAC_LEAD_ID%TYPE,
  pContactId IN PAC_LEAD.LEA_CONTACT_PERSON_ID%TYPE)
  return PAC_PERSON_ASSOCIATION.PAC_PERSON_ASSOCIATION_ID%TYPE
is
  vNewId PAC_PERSON_ASSOCIATION.PAC_PERSON_ASSOCIATION_ID%TYPE;
  vUseIni PCS.PC_USER.USE_INI%TYPE;
begin
  p_setLeadId(pLeadId);
  vUseIni := pcs.PC_I_LIB_SESSION.getuserini;

  SELECT Init_Id_Seq.NextVal INTO vNewId FROM dual;
  INSERT INTO pac_person_association(
    pac_person_association_id, pac_person_id, pac_pac_person_id,
    dic_association_type_id, pas_function, a_datecre, a_idcre)
  VALUES (vNewId, rLead.pac_person_id, pContactId,
    rLead.dic_association_type_id, rLead.lea_contact_function, sysdate, vUseIni);

  return vNewId;
end;

/**
 * Recherche du numéro de lead suivant en utilisant la séquence
 */
function GetNextLeadNumber
  return PAC_LEAD.LEA_NUMBER%type
is
  vLeaNumber PAC_LEAD.LEA_NUMBER%type;
begin
  select to_char(sysdate, 'YY') || '-' || lpad(PAC_LEAD_LEA_NUMBER_SEQ.NextVal, 6, '0')
    into vLeaNumber
    from dual;

  return vLeaNumber;
end GetNextLeadNumber;

END PAC_LEAD_MANAGEMENT;
