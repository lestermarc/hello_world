--------------------------------------------------------
--  DDL for Package Body PAC_EVENT_INTERFACE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_EVENT_INTERFACE" 
AS

procedure IntegrateEventXml(pXml IN CLOB,
  pPersonId IN PAC_EVENT.PAC_PERSON_ID%TYPE,
  pAssocId IN PAC_EVENT.PAC_ASSOCIATION_ID%TYPE,
  pLeadId IN PAC_EVENT.PAC_LEAD_ID%TYPE,
  pEvtId IN OUT PAC_EVENT.PAC_EVENT_Id%TYPE,
  pEvtNumber IN OUT PAC_EVENT.EVE_NUMBER%TYPE)
is
begin
  IntegrateEventXmlType(XMLTYPE.createXml(pXml), pPersonId, pAssocId, pLeadId, pEvtId, pEvtNumber);
end;

procedure IntegrateEventXmlType(pXml IN XMLType,
  pPersonId IN PAC_EVENT.PAC_PERSON_ID%TYPE,
  pAssocId IN PAC_EVENT.PAC_ASSOCIATION_ID%TYPE,
  pLeadId IN PAC_EVENT.PAC_LEAD_ID%TYPE,
  pEvtId IN OUT PAC_EVENT.PAC_EVENT_Id%TYPE,
  pEvtNumber IN OUT PAC_EVENT.EVE_NUMBER%TYPE)
is
    vActUser            PCS.PC_USER.USE_INI%TYPE;
    vActUserId          PCS.PC_USER.PC_USER_ID%TYPE;
    vRecordId           PAC_EVENT.DOC_RECORD_ID%TYPE;
    vPacPersonId        PAC_EVENT.PAC_PERSON_ID%TYPE;
    vPacPacPersonId     PAC_PERSON_ASSOCIATION.PAC_PAC_PERSON_ID%TYPE;
    vPacAssociationId   PAC_EVENT.PAC_ASSOCIATION_ID%TYPE;
    vPacLeadId          PAC_EVENT.PAC_LEAD_ID%TYPE;
    vEveUserId          PAC_EVENT.EVE_USER_ID%TYPE;
    vUserId             PAC_EVENT.PC_USER_ID%TYPE;
    vOriEveId           PAC_EVENT.PAC_PAC_EVENT_ID%TYPE;
    vPacEventTypeId     PAC_EVENT.PAC_EVENT_TYPE_ID%TYPE;
    vOldPacEventTypeId  PAC_EVENT.PAC_EVENT_TYPE_ID%TYPE;
    vGcoGoodId          PAC_EVENT.GCO_GOOD_ID%TYPE;
    vDocDocumentId      PAC_EVENT.DOC_DOCUMENT_ID%TYPE;
    vCmlPositionId      PAC_EVENT.CML_POSITION_ID%TYPE;
    vFamFixedAssetsId   PAC_EVENT.FAM_FIXED_ASSETS_ID%TYPE;
    vAsaRecordId        PAC_EVENT.ASA_RECORD_ID%TYPE;
    vAsaGuarantyCardsId PAC_EVENT.ASA_GUARANTY_CARDS_ID%TYPE;
    vPacCampaignEventId PAC_EVENT.PAC_CAMPAIGN_EVENT_ID%TYPE;
    vGalProjectId       PAC_EVENT.GAL_PROJECT_ID%TYPE;
    vRecordMachineId    PAC_EVENT.DOC_MACHINE_RECORD_ID%TYPE;
    vEveNumber          PAC_EVENT.EVE_NUMBER%TYPE;
    vEventId            PAC_EVENT.PAC_EVENT_ID%TYPE;


    cursor cEvent is
      select
        to_number(extractvalue(value(p),'PAC_EVENT/PAC_EVENT_ID')) PAC_EVENT_ID,
        to_number(extractvalue(value(p),'PAC_EVENT/DOC_RECORD_ID')) DOC_RECORD_ID,
        to_number(extractvalue(value(p),'PAC_EVENT/PAC_PERSON_ID')) PAC_PERSON_ID,
        to_number(extractvalue(value(p),'PAC_EVENT/PAC_ASSOCIATION_ID')) PAC_ASSOCIATION_ID,
        to_number(extractvalue(value(p),'PAC_EVENT/PAC_LEAD_ID')) PAC_LEAD_ID,
        to_number(extractvalue(value(p),'PAC_EVENT/DOC_MACHINE_RECORD_ID')) DOC_MACHINE_RECORD_ID,
        to_number(extractvalue(value(p),'PAC_EVENT/GAL_PROJECT_ID')) GAL_PROJECT_ID,
        to_number(extractvalue(value(p),'PAC_EVENT/EVE_PRIVATE')) EVE_PRIVATE,
        to_number(extractvalue(value(p),'PAC_EVENT/EVE_USER_ID')) EVE_USER_ID,
        extractvalue(value(p),'PAC_EVENT/EVE_TEXT') EVE_TEXT,
        getDateFromXML(extractvalue(value(p),'PAC_EVENT/EVE_DATE')) EVE_DATE,
        to_number(extractvalue(value(p),'PAC_EVENT/EVE_ENDED')) EVE_ENDED,
        to_number(extractvalue(value(p),'PAC_EVENT/PAC_PAC_EVENT_ID')) PAC_PAC_EVENT_ID,
        extractvalue(value(p),'PAC_EVENT/EVE_NUMBER') EVE_NUMBER,
        to_number(extractvalue(value(p),'PAC_EVENT/PAC_EVENT_TYPE_ID')) PAC_EVENT_TYPE_ID,
        to_number(extractvalue(value(p),'PAC_EVENT/A_CONFIRM')) A_CONFIRM,
        getDateFromXML(extractvalue(value(p),'PAC_EVENT/A_DATECRE')) A_DATECRE,
        getDateFromXML(extractvalue(value(p),'PAC_EVENT/A_DATEMOD')) A_DATEMOD,
        extractvalue(value(p),'PAC_EVENT/A_IDCRE') A_IDCRE,
        extractvalue(value(p),'PAC_EVENT/A_IDMOD') A_IDMOD,
        to_number(extractvalue(value(p),'PAC_EVENT/A_RECLEVEL')) A_RECLEVEL,
        to_number(extractvalue(value(p),'PAC_EVENT/A_RECSTATUS')) A_RECSTATUS,
        extractvalue(value(p),'PAC_EVENT/EVE_SUBJECT') EVE_SUBJECT,
        getDateFromXML(extractvalue(value(p),'PAC_EVENT/EVE_ENDDATE')) EVE_ENDDATE,
        extractvalue(value(p),'DIC_EVE_END_TYPE_ID') DIC_EVE_END_TYPE_ID,
        extractvalue(value(p),'DIC_EVE_INCIDENT_ID') DIC_EVE_INCIDENT_ID,
        extractvalue(value(p),'DIC_EVE_INCIDENT_ORIGIN_ID') DIC_EVE_INCIDENT_ORIGIN_ID,
        extractvalue(value(p),'EVE_VERSION') EVE_VERSION,
        to_number(extractvalue(value(p),'PAC_EVENT/GCO_GOOD_ID')) GCO_GOOD_ID,
        to_number(extractvalue(value(p),'PAC_EVENT/DOC_DOCUMENT_ID')) DOC_DOCUMENT_ID,
        to_number(extractvalue(value(p),'PAC_EVENT/CML_POSITION_ID')) CML_POSITION_ID,
        extractvalue(value(p),'PAC_EVENT/DIC_PRIORITY_CODE_ID') DIC_PRIORITY_CODE_ID,
        to_number(extractvalue(value(p),'PAC_EVENT/EVE_PERCENT_COMPLETE')) EVE_PERCENT_COMPLETE,
        getDateFromXML(extractvalue(value(p),'PAC_EVENT/EVE_DATE_COMPLETED')) EVE_DATE_COMPLETED,
        to_number(extractvalue(value(p),'PAC_EVENT/FAM_FIXED_ASSETS_ID')) FAM_FIXED_ASSETS_ID,
        extractvalue(value(p),'PAC_EVENT/EVE_ENTRY_ID') EVE_ENTRY_ID,
        to_number(extractvalue(value(p),'PAC_EVENT/PC_USER_ID')) PC_USER_ID,
        to_number(extractvalue(value(p),'PAC_EVENT/ASA_RECORD_ID')) ASA_RECORD_ID,
        to_number(extractvalue(value(p),'PAC_EVENT/ACT_DOCUMENT_ID')) ACT_DOCUMENT_ID,
        to_number(extractvalue(value(p),'PAC_EVENT/ASA_GUARANTY_CARDS_ID')) ASA_GUARANTY_CARDS_ID,
        getDateFromXML(extractvalue(value(p),'PAC_EVENT/EVE_REMDATE')) EVE_REMDATE,
        getDateFromXML(extractvalue(value(p),'PAC_EVENT/EVE_CAPTURE_DATE')) EVE_CAPTURE_DATE,
        to_number(extractvalue(value(p),'PAC_EVENT/PAC_CAMPAIGN_EVENT_ID')) PAC_CAMPAIGN_EVENT_ID,
        extractvalue(value(p),'PAC_EVENT/EVE_CONTACT_NAME') EVE_CONTACT_NAME,
        extractvalue(value(p),'PAC_EVENT/EVE_CONTACT_FORENAME') EVE_CONTACT_FORENAME,
        extractvalue(value(p),'PAC_EVENT/RCO_TITLE') RCO_TITLE,
        extractvalue(value(p),'PAC_EVENT/PER_KEY1') PER_KEY1,
        extractvalue(value(p),'PAC_EVENT/ASS_KEY1') ASS_KEY1,
        extractvalue(value(p),'PAC_EVENT/EVE_USE_NAME') EVE_USE_NAME,
        extractvalue(value(p),'PAC_EVENT/ORI_EVE_NUMBER') ORI_EVE_NUMBER,
        extractvalue(value(p),'PAC_EVENT/TYP_SHORT_DESCRIPTION') TYP_SHORT_DESCRIPTION,
        extractvalue(value(p),'PAC_EVENT/GOO_MAJOR_REFERENCE') GOO_MAJOR_REFERENCE,
        extractvalue(value(p),'PAC_EVENT/DMT_NUMBER') DMT_NUMBER,
        extractvalue(value(p),'PAC_EVENT/CCO_NUMBER') CCO_NUMBER,
        to_number(extractvalue(value(p),'PAC_EVENT/CPO_SEQUENCE')) CPO_SEQUENCE,
        extractvalue(value(p),'PAC_EVENT/FIX_NUMBER') FIX_NUMBER,
        extractvalue(value(p),'PAC_EVENT/USE_NAME') USE_NAME,
        extractvalue(value(p),'PAC_EVENT/ARE_NUMBER') ARE_NUMBER,
        extractvalue(value(p),'PAC_EVENT/AGC_NUMBER') AGC_NUMBER,
        extractvalue(value(p),'PAC_EVENT/LEA_LABEL') LEA_LABEL,
        extractvalue(value(p),'PAC_EVENT/GAL_PRJ_CODE') GAL_PRJ_CODE,
        extractvalue(value(p),'PAC_EVENT/MACHINE_TILE') MACHINE_TITLE,
        extractvalue(value(p),'PAC_EVENT/CAMPAIGN_TITLE') CAMPAIGN_TITLE,
        to_number(extractvalue(value(p),'PAC_EVENT/CAMPAIGN_EVENT_SEQ')) CAMPAIGN_EVENT_SEQ
      from table(xmlsequence(extract(pXml,'//PAC_EVENT'))) p;

    cursor cFreeBooleanCode is
      select DIC_BOOLEAN_CODE_TYP_ID, BOO_CODE
      from (
        select extractvalue(value(p),'PAC_BOOLEAN_CODE/DIC_BOOLEAN_CODE_TYP_ID') DIC_BOOLEAN_CODE_TYP_ID,
          to_number(extractvalue(value(p),'PAC_BOOLEAN_CODE/BOO_CODE')) BOO_CODE
        from table(xmlsequence(extract(pXml,'//PAC_EVENT/PAC_BOOLEAN_CODE'))) p)
      where DIC_BOOLEAN_CODE_TYP_ID is not null;


    cursor cFreeNumberCode is
      select DIC_NUMBER_CODE_TYP_ID, NUM_CODE
      from (
        select extractvalue(value(p),'PAC_NUMBER_CODE/DIC_NUMBER_CODE_TYP_ID') DIC_NUMBER_CODE_TYP_ID,
          to_number(extractvalue(value(p),'PAC_NUMBER_CODE/NUM_CODE')) NUM_CODE
        from table(xmlsequence(extract(pXml,'//PAC_EVENT/PAC_NUMBER_CODE'))) p)
      where DIC_NUMBER_CODE_TYP_ID is not null;


    cursor cFreeCharCode is
      select DIC_CHAR_CODE_TYP_ID, CHA_CODE
      from (
        select extractvalue(value(p),'PAC_CHAR_CODE/DIC_CHAR_CODE_TYP_ID') DIC_CHAR_CODE_TYP_ID,
          extractvalue(value(p),'PAC_CHAR_CODE/CHA_CODE') CHA_CODE
        from table(xmlsequence(extract(pXml,'//PAC_EVENT/PAC_CHAR_CODE'))) p)
      where DIC_CHAR_CODE_TYP_ID is not null;


    cursor cFreeDateCode is
      select DIC_DATE_CODE_TYP_ID, DAT_CODE
      from (
        select extractvalue(value(p),'PAC_DATE_CODE/DIC_DATE_CODE_TYP_ID') DIC_DATE_CODE_TYP_ID,
          getDateFromXML(extractvalue(value(p),'PAC_DATE_CODE/DAT_CODE')) DAT_CODE
        from table(xmlsequence(extract(pXml,'//PAC_EVENT/PAC_DATE_CODE'))) p)
      where DIC_DATE_CODE_TYP_ID is not null;

    cursor cVirtual is
      select FIELDNAME, CHARVALUE, NUMBERVALUE, DATEVALUE
      from (
        select extractvalue(value(p),'COM_VFIELDS_RECORDS/FIELDNAME') FIELDNAME,
          extractvalue(value(p),'COM_VFIELDS_RECORDS/CHARVALUE') CHARVALUE,
          to_number(extractvalue(value(p),'COM_VFIELDS_RECORDS/NUMBERVALUE')) NUMBERVALUE,
          getDateFromXML(extractvalue(value(p),'COM_VFIELDS_RECORDS/DATEVALUE')) DATEVALUE
        from table(xmlsequence(extract(pXml,'//PAC_EVENT/COM_VFIELDS_RECORDS'))) p);

begin

  vActUser := pcs.PC_I_LIB_SESSION.getUserIni;
  vActUserId := pcs.PC_I_LIB_SESSION.getUserId;
  if pEvtId is null then
    vOldPacEventTypeId := null;
  else
    vOldPacEventTypeId := getOldPacEventTypeId(pEvtId);
  end if;

  for aEvent in cEvent loop

    -- Recherche du type d'événement
    if aEvent.pac_event_type_id is not null then
      vPacEventTypeId := aEvent.pac_event_type_id;
    elsif aEvent.typ_short_description is not null then
      vPacEventTypeId := nvl(getPacEventTypeId(aEvent.typ_short_description), vOldPacEventTypeId);
      if vPacEventTypeId is null then
        raise_application_error(-20000,
            pcs.pc_functions.TranslateWord('Type d''événement invalide ou inexistant'));
      end if;
    end if;

    -- N° de l'événement (dépend du type d'événement)
    if pEvtNumber is null then
      if aEvent.eve_number is null then
        vEveNumber := getNewEveNumber(vPacEventTypeId, nvl(aEvent.eve_date, sysdate));
      else
        vEveNumber := aEvent.eve_number;
      end if;
    else
      if vPacEventTypeId <> vOldPacEventTypeId then
        -- Mise à jour de EveNumber en fonction du nouveau type d'événement
        vEveNumber := getNewEveNumber(vPacEventTypeId, nvl(aEvent.eve_date, sysdate), pEvtNumber);
      else
        vEveNumber := pEvtNumber;
      end if;
    end if;

    -- Id de l'événement
    if pEvtId is null then
      if aEvent.pac_event_id is null then
        select pac_event_seq.nextval into vEventId from dual;
      else
        vEventId := aEvent.pac_event_id; -- Si existe provoquera un exception...
      end if;
    else
      vEventId := pEvtId;
    end if;


    if aEvent.doc_record_id is null and aEvent.rco_title is not null then
      vRecordId := getDocRecordId(aEvent.rco_title);
    else
      vRecordId := aEvent.doc_record_id;
    end if;

    vPacPersonId := aEvent.pac_person_id;
    if vPacPersonId is null and aEvent.per_key1 is not null then
      vPacPersonId := nvl(getPacPersonId(aEvent.per_key1), pPersonId);
    else
      vPacPersonId := pPersonId;
    end if;

    if aEvent.pac_association_id is not null then
      vPacAssociationId := aEvent.pac_association_id;
    else
      if aEvent.ass_key1 is not null then
        vPacAssociationId := getPacAssociationId(vPacPersonId, getPacPersonId(aEvent.ass_key1));
      end if;
      -- Initialiser avec le contact par défaut (si la personne est celle par défaut)
      if vPacAssociationId is null and vPacPersonId = pPersonId then
        vPacAssociationId := pAssocId;
      end if;
    end if;

    vPacLeadId := aEvent.pac_lead_id;
    if vPacLeadId is null and aEvent.lea_label is not null then
      vPacLeadId := nvl(getPacLeadId(aEvent.lea_label), pLeadId);
    else
      vPacLeadId := pLeadId;
    end if;

    if aEvent.eve_user_id is null and aEvent.eve_use_name is not null then
      vEveUserId := getUserId(aEvent.eve_use_name);
    else
      vEveUserId := aEvent.eve_user_id;
    end if;

    if aEvent.pc_user_id is null and aEvent.use_name is not null then
      vUserId := getUserId(aEvent.use_name);
    else
      vUserId := aEvent.pc_user_id;
    end if;

    if aEvent.pac_pac_event_id is null and aEvent.ori_eve_number is not null then
      vOriEveId := getPacEventId(aEvent.ori_eve_number);
    else
      vOriEveId := aEvent.pac_pac_event_id;
    end if;

    if aEvent.gco_good_id is null and aEvent.goo_major_reference is not null then
      vGcoGoodId := getGcoGoodId(aEvent.goo_major_reference);
    else
      vGcoGoodId := aEvent.gco_good_id;
    end if;

    if aEvent.doc_document_id is null and aEvent.dmt_number is not null then
      vDocDocumentId := getDocDocumentId(aEvent.dmt_number);
    else
      vDocDocumentId := aEvent.doc_document_id;
    end if;

    if aEvent.cml_position_id is null and aEvent.cco_number is not null then
      vCmlPositionId := getCmlPositionId(aEvent.cco_number,aEvent.cpo_sequence);
    else
      vCmlPositionId := aEvent.cml_position_id;
    end if;

    if aEvent.fam_fixed_assets_id is null and aEvent.fix_number is not null then
      vFamFixedAssetsId := getFamFixedAssetsId(aEvent.fix_number);
    else
      vFamFixedAssetsId := aEvent.fam_fixed_assets_id;
    end if;

    if aEvent.asa_record_id is null and aEvent.are_number is not null then
      vAsaRecordId := getAsaRecordId(aEvent.are_number);
    else
      vAsaRecordId := aEvent.asa_record_id;
    end if;

    if aEvent.asa_guaranty_cards_id is null and aEvent.agc_number is not null then
      vAsaGuarantyCardsId := getAsaGuarantyCardsId(aEvent.agc_number);
    else
      vAsaGuarantyCardsId := aEvent.asa_guaranty_cards_id;
    end if;

    if aEvent.pac_campaign_event_id is null and aEvent.campaign_title is not null then
      vPacCampaignEventId := getPacCampaignEventId(aEvent.campaign_title,aEvent.campaign_event_seq);
    else
      vPacCampaignEventId := aEvent.pac_campaign_event_id;
    end if;

    if aEvent.gal_project_id is null and aEvent.gal_prj_code is not null then
      vGalProjectId := getGalProjectId(aEvent.gal_prj_code);
    else
      vGalProjectId := aEvent.gal_project_id;
    end if;

    if aEvent.doc_machine_record_id is null and aEvent.machine_title is not null then
      vRecordMachineId := getDocRecordId(aEvent.machine_title);
    else
      vRecordMachineId := aEvent.doc_machine_record_id;
    end if;

    if pEvtId is null then

      insert into pac_event(PAC_EVENT_ID,
        DOC_RECORD_ID,PAC_PERSON_ID,PAC_ASSOCIATION_ID,EVE_PRIVATE,EVE_USER_ID,EVE_TEXT,EVE_DATE,EVE_ENDED,PAC_PAC_EVENT_ID,EVE_NUMBER,
        PAC_EVENT_TYPE_ID,A_CONFIRM,A_DATECRE,A_DATEMOD,A_IDCRE,A_IDMOD,A_RECLEVEL,A_RECSTATUS,EVE_SUBJECT,EVE_ENDDATE,GCO_GOOD_ID,
        DOC_DOCUMENT_ID,CML_POSITION_ID,DIC_PRIORITY_CODE_ID,EVE_PERCENT_COMPLETE,EVE_DATE_COMPLETED,FAM_FIXED_ASSETS_ID,EVE_ENTRY_ID,
        PC_USER_ID,ASA_RECORD_ID,ACT_DOCUMENT_ID,ASA_GUARANTY_CARDS_ID,EVE_REMDATE,EVE_CAPTURE_DATE,PAC_CAMPAIGN_EVENT_ID,EVE_CONTACT_NAME,
        EVE_CONTACT_FORENAME, PAC_LEAD_ID, GAL_PROJECT_ID, DOC_MACHINE_RECORD_ID,
        EVE_VERSION, DIC_EVE_END_TYPE_ID, DIC_EVE_INCIDENT_ID, DIC_EVE_INCIDENT_ORIGIN_ID)
      values(
        vEventId,
        vRecordId,
        vPacPersonId,
        vPacAssociationId,
        aEvent.EVE_PRIVATE,
        nvl(nvl(vEveUserId, vUserId), vActUserId),
        aEvent.EVE_TEXT,
        nvl(aEvent.EVE_DATE,sysdate),
        aEvent.EVE_ENDED,
        vOriEveId,
        vEveNumber,
        vPacEventTypeId,
        aEvent.A_CONFIRM,
        nvl(aEvent.A_DATECRE,sysdate),
        aEvent.A_DATEMOD,
        nvl(aEvent.A_IDCRE,pcs.PC_I_LIB_SESSION.getuserini),
        aEvent.A_IDMOD,
        aEvent.A_RECLEVEL,
        aEvent.A_RECSTATUS,
        aEvent.EVE_SUBJECT,
        aEvent.EVE_ENDDATE,
        vGcoGoodId,
        vDocDocumentId,
        vCmlPositionId,
        aEvent.DIC_PRIORITY_CODE_ID,
        aEvent.EVE_PERCENT_COMPLETE,
        aEvent.EVE_DATE_COMPLETED,
        vFamFixedAssetsId,
        aEvent.EVE_ENTRY_ID,
        nvl(nvl(vUserId, vEveUserId), vActUserId),
        vAsaRecordId,
        aEvent.ACT_DOCUMENT_ID,
        vAsaGuarantyCardsId,
        aEvent.EVE_REMDATE,
        nvl(aEvent.EVE_CAPTURE_DATE, sysdate),
        vPacCampaignEventId,
        aEvent.EVE_CONTACT_NAME,
        aEvent.EVE_CONTACT_FORENAME,
        vPacLeadId,
        vGalProjectId,
        vRecordMachineId,
        aEvent.EVE_VERSION,
        aEvent.DIC_EVE_END_TYPE_ID,
        aEvent.DIC_EVE_INCIDENT_ID,
        aEvent.DIC_EVE_INCIDENT_ORIGIN_ID);

    else

      UPDATE pac_event
      SET
        DOC_RECORD_ID = vRecordId,
        PAC_PERSON_ID = vPacPersonId,
        PAC_ASSOCIATION_ID = vPacAssociationId,
        EVE_PRIVATE = aEvent.EVE_PRIVATE,
        EVE_USER_ID = nvl(nvl(vEveUserId, vUserId), vActUserId),
        EVE_TEXT = aEvent.EVE_TEXT,
        EVE_DATE = nvl(aEvent.EVE_DATE,sysdate),
        EVE_ENDED = aEvent.EVE_ENDED,
        PAC_PAC_EVENT_ID = vOriEveId,
        EVE_NUMBER = vEveNumber,
        PAC_EVENT_TYPE_ID = vPacEventTypeId,
        A_CONFIRM = aEvent.A_CONFIRM,
        -- A_DATECRE = nvl(aEvent.A_DATECRE,sysdate),
        -- A_DATEMOD = aEvent.A_DATEMOD
        A_DATEMOD = sysdate,
        -- A_IDCRE = nvl(aEvent.A_IDCRE,pcs.PC_I_LIB_SESSION.getuserini),
        -- A_IDMOD = aEvent.A_IDMOD
        A_IDMOD = pcs.PC_I_LIB_SESSION.getuserini,
        A_RECLEVEL = aEvent.A_RECLEVEL,
        A_RECSTATUS = aEvent.A_RECSTATUS,
        EVE_SUBJECT = aEvent.EVE_SUBJECT,
        EVE_ENDDATE = aEvent.EVE_ENDDATE,
        GCO_GOOD_ID = vGcoGoodId,
        DOC_DOCUMENT_ID = vDocDocumentId,
        CML_POSITION_ID = vCmlPositionId,
        DIC_PRIORITY_CODE_ID = aEvent.DIC_PRIORITY_CODE_ID,
        EVE_PERCENT_COMPLETE = aEvent.EVE_PERCENT_COMPLETE,
        EVE_DATE_COMPLETED = aEvent.EVE_DATE_COMPLETED,
        FAM_FIXED_ASSETS_ID = vFamFixedAssetsId,
        EVE_ENTRY_ID = aEvent.EVE_ENTRY_ID,
        PC_USER_ID = nvl(nvl(vUserId, vEveUserId), vActUserId),
        ASA_RECORD_ID = vAsaRecordId,
        ACT_DOCUMENT_ID = aEvent.ACT_DOCUMENT_ID,
        ASA_GUARANTY_CARDS_ID = vAsaGuarantyCardsId,
        EVE_REMDATE = aEvent.EVE_REMDATE,
        EVE_CAPTURE_DATE = nvl(aEvent.EVE_CAPTURE_DATE, sysdate),
        PAC_CAMPAIGN_EVENT_ID = vPacCampaignEventId,
        EVE_CONTACT_NAME = aEvent.EVE_CONTACT_NAME,
        EVE_CONTACT_FORENAME = aEvent.EVE_CONTACT_FORENAME,
        PAC_LEAD_ID = vPacLeadId,
        GAL_PROJECT_ID = vGalProjectId,
        DOC_MACHINE_RECORD_ID = vRecordMachineId,
        EVE_VERSION = aEvent.EVE_VERSION,
        DIC_EVE_END_TYPE_ID = aEvent.DIC_EVE_END_TYPE_ID,
        DIC_EVE_INCIDENT_ID = aEvent.DIC_EVE_INCIDENT_ID,
        DIC_EVE_INCIDENT_ORIGIN_ID = aEvent.DIC_EVE_INCIDENT_ORIGIN_ID
      WHERE PAC_EVENT_ID = vEventId;

      DELETE PAC_BOOLEAN_CODE WHERE PAC_EVENT_ID = vEventId;
      DELETE PAC_NUMBER_CODE WHERE PAC_EVENT_ID = vEventId;
      DELETE PAC_CHAR_CODE WHERE PAC_EVENT_ID = vEventId;
      DELETE PAC_DATE_CODE WHERE PAC_EVENT_ID = vEventId;

    end if;

    for aFreeBooleanCode in cFreeBooleanCode loop
      insert into pac_boolean_code(DIC_BOOLEAN_CODE_TYP_ID, PAC_EVENT_ID, BOO_CODE, A_DATECRE, A_IDCRE)
      values(aFreeBooleanCode.dic_boolean_code_typ_id, vEventId,
        aFreeBooleanCode.boo_code, sysdate, vActUser);
    end loop;

    for aFreeNumberCode in cFreeNumberCode loop
      insert into pac_number_code(DIC_NUMBER_CODE_TYP_ID, PAC_EVENT_ID, NUM_CODE, A_DATECRE, A_IDCRE)
      values(aFreeNumberCode.dic_number_code_typ_id, vEventId,
        aFreeNumberCode.num_code, sysdate, vActUser);
    end loop;

    for aFreeCharCode in cFreeCharCode loop
      insert into pac_char_code(DIC_CHAR_CODE_TYP_ID, PAC_EVENT_ID, CHA_CODE, A_DATECRE, A_IDCRE)
      values(aFreeCharCode.dic_char_code_typ_id, vEventId,
        aFreeCharCode.cha_code, sysdate, vActUser);
    end loop;

    for aFreeDateCode in cFreeDateCode loop
      insert into pac_date_code(DIC_DATE_CODE_TYP_ID, PAC_EVENT_ID, DAT_CODE, A_DATECRE, A_IDCRE)
      values(aFreeDateCode.dic_date_code_typ_id, vEventId,
        aFreeDateCode.dat_code, sysdate, vActUser);
    end loop;

    -- Insert or Update VirtualFields
    for aVirtual in cVirtual loop
      if aVirtual.charvalue is not null then
        setvfcharvalue(aVirtual.fieldname,vEventId,aVirtual.charvalue);
      elsif aVirtual.datevalue is not null then
        setvfdatevalue(aVirtual.fieldname,vEventId,aVirtual.datevalue);
      else
        setvfnumbervalue(aVirtual.fieldname,vEventId,aVirtual.numbervalue);
      end if;
    end loop;

    Exit; -- Extraction d'un seul événement
  end loop;

  pEvtId := vEventId;
  pEvtNumber := vEveNumber;
end;

function getNewEveNumber(pPacEventTypeId IN PAC_EVENT.PAC_EVENT_TYPE_ID%TYPE,
  pDate IN PAC_EVENT.EVE_DATE%TYPE,
  pEveNumber IN PAC_EVENT.EVE_NUMBER%TYPE DEFAULT NULL)
  return PAC_EVENT.EVE_NUMBER%TYPE
is
  -- transaction autonome pour ne pas bloquer la création d'événements
  pragma autonomous_transaction;
  result PAC_EVENT.EVE_NUMBER%TYPE;
begin
  result := pEveNumber;
  pac_partner_management.GetEventNumber(pPacEventTypeId, pDate, result);
  commit;
  return result;
end;

procedure freeEveNumber(pPacEventId IN PAC_EVENT.PAC_EVENT_ID%TYPE)
is
  vEvtTypeId PAC_EVENT.PAC_EVENT_TYPE_ID%TYPE;
  vDate PAC_EVENT.EVE_DATE%TYPE;
  vNumber PAC_EVENT.EVE_NUMBER%TYPE;
begin
  select pac_event_type_id, eve_date, eve_number
  into vEvtTypeId, vDate, vNumber
  from pac_event where pac_event_id = pPacEventId;

  freeEveNumber(vEvtTypeId, vDate, vNumber);
end;

procedure freeEveNumber(
  pEvtTypeId PAC_EVENT.PAC_EVENT_TYPE_ID%TYPE,
  pDate PAC_EVENT.EVE_DATE%TYPE,
  pNumber PAC_EVENT.EVE_NUMBER%TYPE)
is
  -- transaction autonome pour ne pas bloquer la création d'événements
  pragma autonomous_transaction;
begin
  pac_partner_management.AddFreeNumber(pEvtTypeId, pDate, pNumber);
  commit;
end;

function getDocRecordId(pRcoTitle IN DOC_RECORD.RCO_TITLE%TYPE) return number
is
  result number(12);
begin
  select doc_record_id into result
  from doc_record
  where rco_title = pRcoTitle;

  return result;

  exception
    when others then return null;
end;

function getPacPersonId(pKey1 IN PAC_PERSON.PER_KEY1%TYPE) return number
is
  result number(12);
begin
  select pac_person_id into result
  from pac_person
  where per_key1 = pKey1;

  return result;

  exception
    when others then return null;
end;

function getPacAssociationId(pThirdId IN PAC_PERSON_ASSOCIATION.PAC_PERSON_ID%TYPE,
  pContactId IN PAC_PERSON_ASSOCIATION.PAC_PAC_PERSON_ID%TYPE) return number
is
  result number(12);
begin
  select pac_person_association_id into result
  from pac_person_association
  where pac_person_id = pThirdId and
    pac_pac_person_id = pContactId;

  return result;

  exception
    when others then return null;
end;

function getPacLeadId(pLabel IN PAC_LEAD.LEA_LABEL%TYPE) return number
is
  result number(12);
begin
  select pac_lead_id into result
  from pac_lead
  where lea_label = pLabel;

  return result;

  exception
    when others then return null;
end;

function getUserId(pUseName IN PCS.PC_USER.USE_NAME%TYPE) return number
is
  result number(12);
begin
  select pc_user_id into result
  from pcs.pc_user
  where use_name = pUseName;

  return result;

  exception
    when others then return null;
end;

function getPacEventId(pEveNumber IN PAC_EVENT.EVE_NUMBER%TYPE) return number
is
  result number(12);
begin
  select pac_event_id into result
  from pac_event
  where eve_number = pEveNumber;

  return result;

  exception
    when others then return null;
end;

function getPacEventTypeId(pTypDescription IN PAC_EVENT_TYPE.TYP_DESCRIPTION%TYPE) return number
is
  result number(12);
begin
  select pac_event_type_id into result
  from pac_event_type
  where typ_short_description = pTypDescription;

  return result;

  exception
    when others then return null;
end;

function getOldPacEventTypeId(pEvtId IN PAC_EVENT.PAC_EVENT_TYPE_ID%TYPE) return number
is
  result number(12);
begin
  select pac_event_type_id into result
  from pac_event
  where pac_event_id = pEvtId;

  return result;

  exception
    when others then return null;
end;

function getGcoGoodId(pGooMajorReference IN GCO_GOOD.GOO_MAJOR_REFERENCE%TYPE) return number
is
  result number(12);
begin
  select gco_good_id into result
  from gco_good
  where goo_major_reference = pGooMajorReference;

  return result;

  exception
    when others then return null;
end;

function getDocDocumentId(pDmtNumber IN DOC_DOCUMENT.DMT_NUMBER%TYPE) return number
is
  result number(12);
begin
  select doc_document_id into result
  from doc_document
  where dmt_number = pDmtNumber;

  return result;

  exception
    when others then return null;
end;

function getCmlPositionId(pCcoNumber IN CML_DOCUMENT.CCO_NUMBER%TYPE,
  pCpoSeq IN CML_POSITION.CPO_SEQUENCE%TYPE) return number
is
  result number(12);
begin
  select cml_position_id into result
  from cml_position p, cml_document d
  where p.cml_document_id = d.cml_document_id and
    d.cco_number = pCcoNumber and
    p.cpo_sequence = pCpoSeq;

  return result;

  exception
    when others then return null;
end;

function getFamFixedAssetsId(pFixNumber IN FAM_FIXED_ASSETS.FIX_NUMBER%TYPE) return number
is
  result number(12);
begin
  select fam_fixed_assets_id into result
  from fam_fixed_assets
  where fix_number = pFixNumber;

  return result;

  exception
    when others then return null;
end;

function getAsaRecordId(pAreNumber IN ASA_RECORD.ARE_NUMBER%TYPE) return number
is
  result number(12);
begin
  select asa_record_id into result
  from asa_record
  where are_number = pAreNumber;

  return result;

  exception
    when others then return null;
end;

function getAsaGuarantyCardsId(pAgcNumber IN ASA_GUARANTY_CARDS.AGC_NUMBER%TYPE) return number
is
  result number(12);
begin
  select asa_guaranty_cards_id into result
  from asa_guaranty_cards
  where agc_number = pAgcNumber;

  return result;

  exception
    when others then return null;
end;

function getPacCampaignEventId(pRcoTitle IN DOC_RECORD.RCO_TITLE%TYPE,
  pSeq IN PAC_CAMPAIGN_EVENT.CAE_SEQUENCE%TYPE) return number
is
  result number(12);
begin
  select pac_campaign_event_id into result
  from pac_campaign_event
  where doc_record_id = getDocRecordId(pRcoTitle) and
    cae_sequence = pSeq;

  return result;

  exception
    when others then return null;
end;

function getGalProjectId(pPrjCode IN GAL_PROJECT.PRJ_CODE%TYPE) return number
is
  result number(12);
begin
  select gal_project_id into result
  from gal_project
  where prj_code = pPrjCode;

  exception
    when others then return null;
end;


procedure SetVFCharValue(pFieldName in varchar2,pRecId in number, pCharValue in varchar2)
is
begin
  com_vfields.SETVF2VALUE('PAC_EVENT',pFieldName,pRecId, pCharValue);
end;

procedure SetVFDateValue(pFieldName in varchar2,pRecId in number, pDateValue in date)
is
begin
  com_vfields.SETVF2VALUE('PAC_EVENT',pFieldName,pRecId, pDateValue);
end;


procedure SetVFNumberValue(pFieldName in varchar2,pRecId in number, pNumberValue in number)
is
begin
  com_vfields.SETVF2VALUE('PAC_EVENT',pFieldName,pRecId, pNumberValue);
end;

function getDateFromXML(InVa varchar2) return date
is
begin
  if inVa is null then
    return null;
  elsif inVa like '____-__-__' and to_number(substr(inVa,6,2)) <= 12 then
    return to_date(inVa,'yyyy-mm-dd');
  elsif inVa like '__.__.____' and to_number(substr(inVa,4,2)) <= 12 then
    return to_date(inVa,'dd.mm.yyyy');
  elsif inVa like '____-__-__T__:__:__' and to_number(substr(inVa,6,2)) <= 12 then
    return to_date(replace(inVa,'T',' '),'yyyy-mm-dd hh24:mi:ss');
  elsif inVa like '____-__-__ __:__:__' and to_number(substr(inVa,6,2)) <= 12 then
    return to_date(inVa,'yyyy-mm-dd hh24:mi:ss');
  elsif inVa like '__.__.____ __:__:__' and to_number(substr(inVa,4,2)) <= 12 then
    return to_date(inVa,'dd.mm.yyyy hh24:mi:ss');
  elsif inVa like '__:__:__' then
    return to_date(inVa,'hh24:mi:ss');
  else
    raise_application_error(-20000,
        pcs.pc_functions.TranslateWord('Format de date invalide')||inVa);
  end if;
end;

/**
 * Intégration pour Outlook
 */
procedure IntegrateEvent(pPersonId IN PAC_EVENT.PAC_PERSON_ID%TYPE,
  pAssocId IN PAC_EVENT.PAC_ASSOCIATION_ID%TYPE,
  pLeadId IN PAC_EVENT.PAC_LEAD_ID%TYPE,
  pSubject IN PAC_EVENT.EVE_SUBJECT%TYPE,
  pBody IN PAC_EVENT.EVE_TEXT%TYPE,
  pSenderName IN VARCHAR2,
  pSenderAddress IN VARCHAR2,
  pDate IN PAC_EVENT.EVE_DATE%TYPE,
  pEvtId IN OUT PAC_EVENT.PAC_EVENT_Id%TYPE,
  pEvtNumber IN OUT PAC_EVENT.EVE_NUMBER%TYPE)
is
  vEvtId PAC_EVENT.PAC_EVENT_ID%TYPE;
  vEvtNumber PAC_EVENT.EVE_NUMBER%TYPE;
  vPacEventTypeId PAC_EVENT.PAC_EVENT_TYPE_ID%TYPE;
  vOldPacEventTypeId PAC_EVENT.PAC_EVENT_TYPE_ID%TYPE;
  vPacPersonId PAC_EVENT.PAC_PERSON_ID%TYPE;
  vPacAssociationId PAC_EVENT.PAC_ASSOCIATION_ID%TYPE;
  vUserId PAC_EVENT.PC_USER_ID%TYPE;
begin
  if pEvtId is null then
    vOldPacEventTypeId := null;
  else
    vOldPacEventTypeId := getOldPacEventTypeId(pEvtId);
  end if;

  -- Type d'événement (par défaut messagerie)
  vPacEventTypeId := nvl(getMailEventTypeId, vOldPacEventTypeId);
  if vPacEventTypeId is null then
    raise_application_error(-20000,
        pcs.pc_functions.TranslateWord('Aucun type d''événement pour messagerie'));
  end if;

  -- N° d'événement (dépend du type d'événement)
  if pEvtNumber is null then
    vEvtNumber := getNewEveNumber(vPacEventTypeId, nvl(pDate, sysdate));
  elsif vPacEventTypeId <> vOldPacEventTypeId then
    -- Mise à jour de EveNumber en fonction du nouveau type d'événement
    vEvtNumber := getNewEveNumber(vPacEventTypeId, nvl(pDate, sysdate), pEvtNumber);
  else
    vEvtNumber := pEvtNumber;
  end if;

  if pPersonId is not null then
    vPacAssociationId := nvl(getContact(pSenderName, pSenderAddress, pPersonId), pAssocId);
    vPacPersonId := pPersonId;
  else
    getPersonContact(pSenderName, pSenderAddress, vPacPersonId, vPacAssociationId);
  end if;

  vUserId := pcs.PC_I_LIB_SESSION.getuserid;

  if pEvtId is null then
    SELECT pac_event_seq.NextVal into vEvtId from dual;

    INSERT INTO pac_event(
      pac_event_id, pac_event_type_id, eve_number,
      pac_person_id, pac_association_id, pac_lead_id, eve_subject, eve_text,
      eve_date, eve_enddate, eve_capture_date,
      eve_user_id, pc_user_id, a_datecre, a_idcre)
    VALUES(
      vEvtId, vPacEventTypeId, vEvtNumber,
      vPacPersonId, vPacAssociationId, pLeadId, pSubject, pBody,
      pDate, pDate, sysdate,
      vUserId, vUserId, sysdate, pcs.PC_I_LIB_SESSION.getuserini);
  else
    vEvtId := pEvtId;

    UPDATE pac_event
    SET eve_number = vEvtNumber,
        eve_date = nvl(pDate, sysdate),
        pac_event_type_id = vPacEventTypeId,
        eve_subject = pSubject,
        eve_text = pBody,
        pac_person_id = nvl(vPacPersonId, pac_person_id),
        pac_association_id = nvl(vPacAssociationId, pac_association_id),
        pac_lead_id = nvl(pLeadId, pac_lead_id),
        a_datemod = sysdate,
        a_idmod = pcs.PC_I_LIB_SESSION.getuserini
    WHERE
      pac_event_id = vEvtId;

  end if;

  pEvtId := vEvtId;
  pEvtNumber := vEvtNumber;
end;

function getContact(pSenderName IN VARCHAR2, pSenderAddress IN VARCHAR2,
  pPersonId IN PAC_EVENT.PAC_PERSON_ID%TYPE) return number
is
  Result PAC_PERSON_ASSOCIATION.PAC_PERSON_ASSOCIATION_ID%TYPE;
begin
  -- Contact de la personne en fonction de l'email
  if instr(pSenderAddress, '@') > 1 then
    begin
      SELECT a.pac_person_association_id INTO Result
      FROM PAC_COMMUNICATION c, PAC_PERSON_ASSOCIATION a
      WHERE a.pac_person_id = pPersonId and
        c.pac_person_id = a.pac_pac_person_id and
        c.com_ext_number = pSenderAddress and
        c.dic_communication_type_id = (SELECT max(dic_communication_type_id)
                                       FROM DIC_COMMUNICATION_TYPE t
                                       WHERE t.dco_email = 1);
      return Result;
    exception
      when no_data_found then null;
    end;
  end if;

  -- Contact de la personne en fonction du nom
  SELECT a.pac_person_association_id INTO Result
  FROM PAC_PERSON p, PAC_PERSON_ASSOCIATION a
  WHERE UPPER(p.per_name) = UPPER(pSenderName) and
    p.pac_person_id = a.pac_pac_person_id and
    a.pac_person_id = pPersonId;

  return Result;

  exception
    when others then return null;
end;

procedure getPersonContact(pSenderName IN VARCHAR2, pSenderAddress IN VARCHAR2,
  pPersonId OUT PAC_EVENT.PAC_PERSON_Id%TYPE,
  pAssociationId OUT PAC_PERSON_ASSOCIATION.PAC_PERSON_ASSOCIATION_ID%TYPE)
is
  cursor csByMail is
    SELECT nvl(a.PAC_PERSON_ID, c.pac_person_id) pac_person_id,
      a.PAC_PERSON_ASSOCIATION_ID
    FROM PAC_PERSON_ASSOCIATION a, PAC_COMMUNICATION c
    WHERE a.PAC_PAC_PERSON_ID(+) = c.PAC_PERSON_ID AND
      c.COM_EXT_NUMBER = pSenderAddress AND
      c.DIC_COMMUNICATION_TYPE_ID = (SELECT max(dic_communication_type_id)
                                     FROM DIC_COMMUNICATION_TYPE t
                                     WHERE t.dco_email = 1)
    ORDER BY NVL2(a.pac_person_association_id, 0, 1);

  cursor csByName is
    SELECT nvl(a.PAC_PERSON_ID, p.pac_person_id) pac_person_id,
      a.PAC_PERSON_ASSOCIATION_ID
    FROM PAC_PERSON_ASSOCIATION a, PAC_PERSON p
    WHERE a.PAC_PAC_PERSON_ID(+) = p.PAC_PERSON_ID AND
      UPPER(p.PER_NAME) = UPPER(pSenderName)
    ORDER BY NVL2(a.pac_person_association_id, 0, 1);

begin
  -- Personne (et contact) en fonction de l'email
  if instr(pSenderAddress, '@') > 1 then
    open csByMail;
    fetch csByMail into pPersonId, pAssociationId;
    if csByMail%found then
      close csByMail;
      return;
    end if;
    close csByMail;
  end if;

  -- Personne (et Contact) en fonction du nom
  open csByName;
  fetch csByName into pPersonId, pAssociationId;
  close csByName;

  exception
    when others then return;
end;

function getMailEventTypeId return number
is
  cursor csEvtType is
    SELECT PAC_EVENT_TYPE_ID
    FROM PAC_EVENT_TYPE
    WHERE C_PAC_CONFIG = '00'
    ORDER BY TYP_EVENT_AVAILABLE DESC;
  Result number(12);
begin
  open csEvtType;
  fetch csEvtType into Result;
  close csEvtType;

  return Result;

  exception
    when others then return null;
end;

END PAC_EVENT_INTERFACE;
