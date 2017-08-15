--------------------------------------------------------
--  DDL for Package Body PAC_EVENT_MANAGEMENT
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_EVENT_MANAGEMENT" 
is
  /**
  * function CreateEventFromMailing
  * Description  Création d'événements lors du publipostage
  */
  procedure CreateEventFromMailing (pExtractionId  PAC_EXTRACT_DATA.PAC_EXTRACTION_ID%type,
                                    pEveSubject    PAC_EVENT.EVE_SUBJECT%type,
                                    pEveText       PAC_EVENT.EVE_TEXT%type,
                                    pEveDate       PAC_EVENT.EVE_DATE%type,
                                    pEndDate       PAC_EVENT.EVE_ENDDATE%type,
                                    pEvePrivate    PAC_EVENT.EVE_PRIVATE%type,
                                    pEndDateManagement PAC_EVENT_TYPE.TYP_ENDDATE_MANAGEMENT%type,
                                    pEveEnded      PAC_EVENT.EVE_ENDED%type,
                                    pDateCompleted PAC_EVENT.EVE_DATE_COMPLETED%type,
                                    pPriority      PAC_EVENT.DIC_PRIORITY_CODE_ID%type,
                                    pUserId        PAC_EVENT.EVE_USER_ID%type,
                                    pEveTypeId     PAC_EVENT.PAC_EVENT_TYPE_ID%type
                                    )
  is
    /*Curseur de sélection des données extraites du publipostage selon l'extraction donné*/
    cursor ExtractedDatasCursor (pExtractionId PAC_EXTRACT_DATA.PAC_EXTRACTION_ID%type)
    is
      select PAC_PERSON_ID,
             PAC_PARTNER_MANAGEMENT.GetAssociationId(PAC_PERSON_ID,PAC_PAC_PERSON_ID) AssociationId
      from  PAC_EXTRACT_DATA
      where PAC_EXTRACTION_ID = pExtractionId;

    vExtractedDatas ExtractedDatasCursor%rowtype;  --Réceptionne les données du curseur
    vEveNumber      PAC_EVENT.EVE_NUMBER%type;     -- N° événement
    vEndDate        PAC_EVENT.EVE_ENDDATE%type;    --Date fin
    vPercent        PAC_EVENT.EVE_PERCENT_COMPLETE%type;-- % Réalisé
  begin

    if pEndDateManagement = 1 then  --Initialisation de la date fin si date de fin est géré
      vEndDate := pEndDate;
    else                            --sinon date fin = null
      vEndDate := null;
    end if;

    if pEveEnded = 1 then           --Si événement liquidé alors pourcentage = 100%
      vPercent := 100;
    else                            --sinon pourcentage = 0
      vPercent := 0;
    end if;

    open ExtractedDatasCursor(pExtractionId);
    fetch ExtractedDatasCursor into vExtractedDatas;
    while ExtractedDatasCursor%found
    loop
      PAC_PARTNER_MANAGEMENT.GetEventNumber(pEveTypeId, pEveDate, vEveNumber);
      InsertEvent (vEveNumber,                    --N° d'événement
                   pEveSubject,                   --Sujet
                   pEveText,                      --Texte
                   pEveDate,                      --Date événement
                   vEndDate,                      --Date fin
                   pEvePrivate,                   --Evénement privé
                   pUserId,                       --Utilisateur
                   pEveEnded,                     --Liquidé
                   vPercent,                      --Pourcentage réalisé
                   pDateCompleted,                --Terminé le
                   sysdate,                       --Saisie le
                   null,                          --Entry Id
                   pPriority,                     --Priorité
                   pEveTypeId,                    --Type d'événement
                   null,                          --Evénement déclencheur
                   pUserId,                       --Utilisateur
                   vExtractedDatas.AssociationId, --Contact
                   vExtractedDatas.PAC_PERSON_ID, --Personne
                   null,                          --Dossier
                   null,                          --Bien
                   null,                          --Document
                   null,                          --Avenant
                   null);                         --Immobilisation
      fetch ExtractedDatasCursor into vExtractedDatas;
    end loop;
    close ExtractedDatasCursor;
  end CreateEventFromMailing;

  /**
  * function InsertEvent
  * Description  Ajout d'événements avec toutes les valeurs déjà définies en amont
  */
  procedure InsertEvent (pEveNumber     PAC_EVENT.EVE_NUMBER%type,           --N° d'événement
                         pEveSubject    PAC_EVENT.EVE_SUBJECT%type,          --Sujet
                         pEveText       PAC_EVENT.EVE_TEXT%type,             --Texte
                         pEveDate       PAC_EVENT.EVE_DATE%type,             --Date événement
                         pEveEndDate    PAC_EVENT.EVE_ENDDATE%type,          --Date fin
                         pEvePrivate    PAC_EVENT.EVE_PRIVATE%type,          --Evénement privé
                         pEveUserId     PAC_EVENT.EVE_USER_ID%type,          --Utilisateur
                         pEveEnded      PAC_EVENT.EVE_ENDED%type,            --Liquidé
                         pEveComplete   PAC_EVENT.EVE_PERCENT_COMPLETE%type, --Pourcentage réalisé
                         pDateComplete  PAC_EVENT.EVE_DATE_COMPLETED%type,   --Terminé le
                         pEveCaptureDat PAC_EVENT.EVE_CAPTURE_DATE%type,     --Saisie le
                         pEveEntryId    PAC_EVENT.EVE_ENTRY_ID%type,         --Entry Id
                         pPriority      PAC_EVENT.DIC_PRIORITY_CODE_ID%type, --Priorité
                         pEventTypeId   PAC_EVENT.PAC_EVENT_TYPE_ID%type,    --Type d'événement
                         pEventEventId  PAC_EVENT.PAC_PAC_EVENT_ID%type,     --Evénement déclencheur
                         pPcUserId      PAC_EVENT.PC_USER_ID%type,           --Utilisateur
                         pAssociationId PAC_EVENT.PAC_ASSOCIATION_ID%type,   --Contact
                         pPersonId      PAC_EVENT.PAC_PERSON_ID%type,        --Personne
                         pRecordId      PAC_EVENT.DOC_RECORD_ID%type,        --Dossier
                         pGoodId        PAC_EVENT.GCO_GOOD_ID%type,          --Bien
                         pDocumentId    PAC_EVENT.DOC_DOCUMENT_ID%type,      --Document
                         pCmlPositionId PAC_EVENT.CML_POSITION_ID%type,      --Avenant
                         pFixAssetsId   PAC_EVENT.FAM_FIXED_ASSETS_ID%type)  --Immobilisation
  is
    vEventId PAC_EVENT.PAC_EVENT_ID%type;
  begin
    /*Réception d'un nouvel id d'événement*/
    select PAC_EVENT_SEQ.NextVal into vEventId from dual;
    begin
      insert into PAC_EVENT(PAC_EVENT_ID,
                            EVE_NUMBER,
                            EVE_SUBJECT,
                            EVE_TEXT,
                            EVE_DATE,
                            EVE_ENDDATE,
                            EVE_PRIVATE,
                            EVE_USER_ID,
                            EVE_ENDED,
                            EVE_PERCENT_COMPLETE,
                            EVE_DATE_COMPLETED,
                            EVE_CAPTURE_DATE,
                            EVE_ENTRY_ID,
                            DIC_PRIORITY_CODE_ID,
                            PAC_EVENT_TYPE_ID,
                            PAC_PAC_EVENT_ID,
                            PC_USER_ID,
                            PAC_ASSOCIATION_ID,
                            PAC_PERSON_ID,
                            DOC_RECORD_ID,
                            GCO_GOOD_ID,
                            DOC_DOCUMENT_ID,
                            CML_POSITION_ID,
                            FAM_FIXED_ASSETS_ID,
                            A_DATECRE,
                            A_IDCRE)
      values(vEventId,
             pEveNumber,
             pEveSubject,
             pEveText,
             pEveDate,
             pEveEndDate,
             pEvePrivate,
             pEveUserId,
             pEveEnded,
             pEveComplete,
             pDateComplete,
             pEveCaptureDat,
             pEveEntryId,
             pPriority,
             pEventTypeId,
             pEventEventId,
             pPcUserId,
             pAssociationId,
             pPersonId,
             pRecordId,
             pGoodId,
             pDocumentId,
             pCmlPositionId,
             pFixAssetsId,
             SYSDATE,
             PCS.PC_I_LIB_SESSION.GETUSERINI);
    exception
      when others then null;
    end;
  end InsertEvent;

  /**
  * function GetEventNumberingDatas
  * Description  Recherche des infos des méthode de numération de l'événement
  */
  procedure GetEventNumberingDatas (pEventTypeId  in PAC_EVENT.PAC_EVENT_TYPE_ID%type,
                                    pEveDate      in PAC_EVENT.EVE_DATE%type,
                                    pEveNumMask   in out varchar2,
                                    pEveNumType   in out varchar2)
  is
    cursor EventNumberingCursor is
      select PPI.PIC_PICTURE PIC_PREFIX,
             NPI.PIC_PICTURE PIC_NUMBER,
             SPI.PIC_PICTURE PIC_SUFFIX,
             NUM.C_NUMBER_TYPE
      from ACS_PICTURE            PPI,
           ACS_PICTURE            NPI,
           ACS_PICTURE            SPI,
           ACJ_NUMBER_METHOD      NUM,
           PAC_NUMBER_METHOD      MET,
           PAC_NUMBER_APPLICATION APP
      where APP.PAC_EVENT_TYPE_ID = pEventTypeId
        and (NUA_SINCE <= pEveDate or NUA_SINCE is null)
        and (NUA_TO    >= pEveDate or NUA_TO is null)
        and APP.PAC_NUMBER_METHOD_ID = MET.PAC_NUMBER_METHOD_ID
        and MET.ACJ_NUMBER_METHOD_ID = NUM.ACJ_NUMBER_METHOD_ID
        and NUM.ACS_PIC_PREFIX_ID    = PPI.ACS_PICTURE_ID (+)
        and NUM.ACS_PIC_NUMBER_ID    = NPI.ACS_PICTURE_ID
        and NUM.ACS_PIC_SUFFIX_ID    = SPI.ACS_PICTURE_ID (+);

    EventNumbering  EventNumberingCursor%rowtype;
  begin
    pEveNumMask := '';
    pEveNumType := '';
    open EventNumberingCursor;
    fetch EventNumberingCursor into EventNumbering;
    if EventNumberingCursor%found then
      pEveNumMask  := EventNumbering.PIC_PREFIX || EventNumbering.PIC_NUMBER || EventNumbering.PIC_SUFFIX;
      pEveNumType  := EventNumbering.C_NUMBER_TYPE;
    end if;
  end GetEventNumberingDatas;

  /**
   * function GetCascadeLangId
   * Description: Recherche en cascade de la langue à utiliser
   */
  function GetCascadeLangId(pContactId PAC_EVENT.PAC_PERSON_ID%type,
                            pPersonId PAC_EVENT.PAC_PERSON_ID%type) return number
  is
    cursor crPacGetLangId(pPersonId PAC_PERSON.PAC_PERSON_ID%type)
    is
      SELECT adr.pc_lang_id
      FROM dic_address_type dic, pac_address adr
      WHERE adr.pac_person_id = pPersonId AND
        dic.dic_address_type_id = adr.dic_address_type_id
      ORDER BY adr.add_principal DESC, dic.dad_default DESC, adr.dic_address_type_id ASC;

    Result number;
  begin
    -- Langue du contact
    open crPacGetLangId(pContactId);
    fetch crPacGetLangId into Result;
    if crPacGetLangId%found then
      close crPacGetLangId;
      return Result;
    end if;

    -- Si pas trouvé, langue de la personne
    close crPacGetLangId;
    open crPacGetLangId(pPersonId);
    fetch crPacGetLangId into Result;
    if crPacGetLangId%found then
      close crPacGetLangId;
      return Result;
    end if;

    -- A défaut, langue de l'utilisateur
    close crPacGetLangId;
    return PCS.PC_PUBLIC.GetUserLangId;

    exception
      when others then return null;
  end;

  /**
   * procedure GetDefaultText
   * Description: Recherche des textes par défaut avec mention de la langue
   */
  procedure GetDefaultText(pPacEventTypeId in PAC_EVENT_TYPE.PAC_EVENT_TYPE_ID%type,
    pPacPersonId in PAC_EVENT.PAC_PERSON_ID%type,
    pPacAssocId in PAC_EVENT.PAC_ASSOCIATION_ID%type,
    pPcUserId in PCS.PC_USER.PC_USER_ID%type,
    pEveDate IN pac_event.eve_date%type,
    pEveEndDate IN pac_event.eve_enddate%type,
    pEveNumber IN pac_event.eve_number%type,
    pEveRecordId IN pac_event.doc_record_id%type,
    pDefaultSubject out PAC_EVENT.EVE_SUBJECT%type,
    pDefaultText out PAC_EVENT.EVE_TEXT%type)
  is
    vPacPacPersonId PAC_PERSON.PAC_PERSON_ID%TYPE;
  begin
    if pPacAssocId is not null then
      vPacPacPersonId := PAC_PARTNER_MANAGEMENT.GetContactId(pPacAssocId);
    end if;

    SELECT typ_default_subject,
        pac_macro.formatEventText(
            pPacPersonId, vPacPacPersonId, pPcUserId,
            pEveDate, pEveEndDate, pEveNumber, pEveRecordId,
            typ_long_description, typ_default_text)
    INTO pDefaultSubject, pDefaultText
    FROM pac_event_type_descr
    WHERE pac_event_type_id = pPacEventTypeId AND
          pc_lang_id = GetCascadeLangId(vPacPacPersonId, pPacPersonId);

    exception
      when others then
        pDefaultSubject := null;
        pDefaultText := null;
  end;

end PAC_EVENT_MANAGEMENT;
