--------------------------------------------------------
--  DDL for Package Body PAC_CAMPAIGN
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_CAMPAIGN" 
is
  cursor crPersonID
  is
    select PAC_PERSON_ID
    from PAC_PERSON
    where PAC_PERSON_ID = 0;

  type TtblPersonID is table of crPersonID%rowtype
    index by binary_integer;

  cursor crDicAssociationTypeID
  is
    select DIC_ASSOCIATION_TYPE_ID
    from DIC_ASSOCIATION_TYPE
    where DIC_ASSOCIATION_TYPE_ID IS NULL;

  type TtblDicAssociationTypeID is table of crDicAssociationTypeID%rowtype
    index by binary_integer;


  /**
  * procedure CreatePersonEvent
  * Description
  *   création de tous les événements n'existant pas après le plan de campagne venant d'être terminé, jusqu'au jalon suivant
  */
  procedure CreatePersonEvent(pPAC_CAMPAIGN_EVENT_ID  PAC_CAMPAIGN_EVENT.PAC_CAMPAIGN_EVENT_ID%type,
                              pPAC_PERSON_ID          PAC_PERSON.PAC_PERSON_ID%type,
                              pEVE_DATE_COMPLETED     PAC_EVENT.EVE_DATE_COMPLETED%type,
                              pPAC_EVENT_ID           PAC_EVENT.PAC_EVENT_ID%type,
                              pPAC_ASSOCIATION_ID     PAC_EVENT.PAC_ASSOCIATION_ID%type)
  is
    pragma autonomous_transaction;
    vNextCAMPAIGN_EVENT_ID  PAC_CAMPAIGN_EVENT.PAC_CAMPAIGN_EVENT_ID%type;
  begin
    --Recherche du plan de campagne suivant le plan passé en paramètre
    vNextCAMPAIGN_EVENT_ID := GetNextCampaignPlan(pPAC_CAMPAIGN_EVENT_ID);
    InsertCampaignEvent(vNextCAMPAIGN_EVENT_ID, pPAC_PERSON_ID, pEVE_DATE_COMPLETED, pPAC_EVENT_ID, pPAC_ASSOCIATION_ID);
    commit;
  end CreatePersonEvent;

  /**
  * Description
  * suppression de tous les événements de la personne après le dernier événement modifié
  * et création du premier événement pour chaque personne cible
  */
  procedure CreateTargetsCampaignPlan(pDOC_RECORD_ID DOC_RECORD.DOC_RECORD_ID%type)
  is
    cursor crPacCampaignTarget(pDOC_RECORD_ID DOC_RECORD.DOC_RECORD_ID%type)
    is
      select
        CSP.PAC_PERSON_ID,
        nvl(CSP.PAC_PERSON_ASSOCIATION_ID, 0) PAC_PERSON_ASSOCIATION_ID
      from PAC_CAMPAIGN_S_PERSON CSP
      where
        CSP.DOC_RECORD_ID = pDOC_RECORD_ID and
        not exists(select 0
                   from PAC_EVENT EVE, PAC_CAMPAIGN_QUALIF CAQ
                   where EVE.PAC_EVENT_ID = CAQ.PAC_EVENT_ID and
                         CAQ.DOC_RECORD_ID = pDOC_RECORD_ID and
                         CAQ.CAQ_END_CAMPAIGN = 1 and
                         EVE.PAC_PERSON_ID = CSP.PAC_PERSON_ID and
                         nvl(EVE.PAC_ASSOCIATION_ID, 0) = nvl(CSP.PAC_PERSON_ASSOCIATION_ID, 0));

    cursor crPacEndCampaign(pDOC_RECORD_ID      DOC_RECORD.DOC_RECORD_ID%type,
                            pPAC_PERSON_ID      PAC_EVENT.PAC_PERSON_ID%type,
                            pPAC_ASSOCIATION_ID PAC_EVENT.PAC_ASSOCIATION_ID%type)
    is
      select
        CAE.PAC_CAMPAIGN_EVENT_ID
      from
        PAC_CAMPAIGN_EVENT CAE,
        PAC_EVENT EVE
      where
        exists(select 1
               from
                 PAC_CAMPAIGN_EVENT C1,
                 PAC_EVENT E1
               WHERE
                 CAE.CAE_SEQUENCE             >= C1.CAE_SEQUENCE and
                 C1.DOC_RECORD_ID              = pDOC_RECORD_ID and
                 E1.PAC_PERSON_ID              = pPAC_PERSON_ID and
                 nvl(E1.PAC_ASSOCIATION_ID, 0) = nvl(pPAC_ASSOCIATION_ID, 0) and
                 E1.EVE_ENDED                  = 1 and
                 E1.PAC_CAMPAIGN_EVENT_ID      = C1.PAC_CAMPAIGN_EVENT_ID) and
         CAE.DOC_RECORD_ID              = pDOC_RECORD_ID and
         EVE.PAC_PERSON_ID              = pPAC_PERSON_ID and
         nvl(EVE.PAC_ASSOCIATION_ID, 0) = nvl(pPAC_ASSOCIATION_ID, 0) and
         EVE.EVE_ENDED                  = 1 and
         EVE.PAC_CAMPAIGN_EVENT_ID      = CAE.PAC_CAMPAIGN_EVENT_ID;

    vPacEndCampaign             crPacEndCampaign%rowtype;
    vCampaignTarget             crPacCampaignTarget%rowtype;
    vEND_CAMPAIGN_EVENT_ID      PAC_CAMPAIGN_EVENT.PAC_CAMPAIGN_EVENT_ID%type;
    vNextCAMPAIGN_EVENT_ID      PAC_CAMPAIGN_EVENT.PAC_CAMPAIGN_EVENT_ID%type;
    vPAC_EVENT_ID               PAC_EVENT.PAC_EVENT_ID%type;
    vEVE_DATE_COMPLETED         PAC_EVENT.EVE_DATE_COMPLETED%type;
  begin
    --suppression de tous les événements de la personne après le dernier événement modifié
    ClearCampaignEvents(pDOC_RECORD_ID);
    --Depuis l'événement suivant le dernier jalon, création des événements jusqu'au prochain jalon inclus.
    open crPacCampaignTarget(pDOC_RECORD_ID);
    fetch crPacCampaignTarget into vCampaignTarget;
    while crPacCampaignTarget%found loop
      if IsCampaignTargetEnded(pDOC_RECORD_ID, vCampaignTarget.PAC_PERSON_ID, vCampaignTarget.PAC_PERSON_ASSOCIATION_ID) < 1 then
        vPAC_EVENT_ID          := 0;
        vEND_CAMPAIGN_EVENT_ID := 0;
        vEVE_DATE_COMPLETED    := null;
        --recherche du dernier plan de campagne ayant une tâche terminée
        open crPacEndCampaign(pDOC_RECORD_ID, vCampaignTarget.PAC_PERSON_ID, vCampaignTarget.PAC_PERSON_ASSOCIATION_ID);
        fetch crPacEndCampaign into vPacEndCampaign;
        if crPacEndCampaign%found then
          vEND_CAMPAIGN_EVENT_ID := vPacEndCampaign.PAC_CAMPAIGN_EVENT_ID;
        end if;
        close crPacEndCampaign;
        -- Une tâche terminée a été trouvée, recherche du plan de campagne suivant le plan correspondant à la dernière tâche terminée
        vNextCAMPAIGN_EVENT_ID := GetNextCampaignPlan(vEND_CAMPAIGN_EVENT_ID);
        if vEND_CAMPAIGN_EVENT_ID > 0 then
          -- Recherche des informations de la tâche terminée
          select
            EVE.PAC_EVENT_ID,
            EVE.EVE_DATE_COMPLETED
          into
            vPAC_EVENT_ID,
            vEVE_DATE_COMPLETED
          from PAC_EVENT EVE
          where
             EVE.PAC_CAMPAIGN_EVENT_ID      = vEND_CAMPAIGN_EVENT_ID and
             EVE.PAC_PERSON_ID              = vCampaignTarget.PAC_PERSON_ID and
             nvl(EVE.PAC_ASSOCIATION_ID, 0) = nvl(vCampaignTarget.PAC_PERSON_ASSOCIATION_ID, 0);
        else --Premier plan de campagne saisi, tâche terminée non trouvée
          --Contrôle qu'aucune tâche non terminée n'existe pour la personne et son association, si existe ne pas en créer
          select
            nvl(max(CAE.PAC_CAMPAIGN_EVENT_ID), 0)
          into
            vNextCAMPAIGN_EVENT_ID
          from
            PAC_CAMPAIGN_EVENT CAE
          where
            CAE.DOC_RECORD_ID = pDOC_RECORD_ID and
            exists (select 1
              from PAC_EVENT EVE
              where
                EVE.PAC_CAMPAIGN_EVENT_ID      = CAE.PAC_CAMPAIGN_EVENT_ID and
                EVE.PAC_PERSON_ID              = vCampaignTarget.PAC_PERSON_ID and
                nvl(EVE.PAC_ASSOCIATION_ID, 0) = nvl(vCampaignTarget.PAC_PERSON_ASSOCIATION_ID, 0) and
                EVE.EVE_ENDED                  = 0);
          if vNextCAMPAIGN_EVENT_ID = 0 then
            --Aucune tâche trouvée, recherche de la première séquence
            select  nvl(min(CAE.PAC_CAMPAIGN_EVENT_ID), 0)
            into    vNextCAMPAIGN_EVENT_ID
            from    PAC_CAMPAIGN_EVENT CAE
            where   CAE.DOC_RECORD_ID = pDOC_RECORD_ID and
                    CAE.CAE_SEQUENCE  = (select nvl(min(C1.CAE_SEQUENCE), -1)
                                         from PAC_CAMPAIGN_EVENT C1
                                         where C1.DOC_RECORD_ID = pDOC_RECORD_ID);
          end if;
        end if;
        InsertCampaignEvent(vNextCAMPAIGN_EVENT_ID,
                            vCampaignTarget.PAC_PERSON_ID,
                            vEVE_DATE_COMPLETED,
                            vPAC_EVENT_ID,
                            vCampaignTarget.PAC_PERSON_ASSOCIATION_ID);
      end if;
      fetch crPacCampaignTarget into vCampaignTarget;
    end loop;
    close crPacCampaignTarget;
  end CreateTargetsCampaignPlan;

  procedure p_getDefaultText(
    pCampaignEvtId in pac_campaign_event.pac_campaign_event_id%type,
    pEventTypeId in pac_campaign_event.pac_event_type_id%type,
    pLangId in pcs.pc_lang.pc_lang_id%type,
    pTypeLongDescr out pac_event_type_descr.typ_long_description%type,
    pDefaultSubject out pac_event.eve_subject%type,
    pDefaultText out pac_event.eve_text%type)
  is
    vPacPacPersonId PAC_PERSON.PAC_PERSON_ID%TYPE;
  begin
    -- Recherche sujet, texte par défaut et type d'événement
    begin
      SELECT typ_default_subject, typ_default_text, typ_long_description
      INTO pDefaultSubject, pDefaultText, pTypeLongDescr
      FROM pac_event_type_descr
      WHERE pac_event_type_id = pEventTypeId and
        pc_lang_id = pLangId;
    exception
      when no_data_found then null;
    end;

    -- Recherche sujet et texte par défaut définis pour le plan de campagne
    SELECT typ_default_subject, typ_default_text
    INTO pDefaultSubject, pDefaultText
    FROM pac_event_type_descr
    WHERE pac_campaign_event_id = pCampaignEvtId and
      pac_event_type_id is null and
      pc_lang_id = pLangId;

    exception
      when no_data_found then null;
  end p_getDefaultText;

  /**
  * Description
  *   Création d'une tâche liée à une campagne
  */
  procedure InsertCampaignEvent(pPAC_CAMPAIGN_EVENT_ID  PAC_CAMPAIGN_EVENT.PAC_CAMPAIGN_EVENT_ID%type,
                                pPAC_PERSON_ID          PAC_EVENT.PAC_PERSON_ID%type,
                                pEVE_DATE_COMPLETED     PAC_EVENT.EVE_DATE_COMPLETED%type,
                                pPAC_PAC_EVENT_ID       PAC_EVENT.PAC_PAC_EVENT_ID%type,
                                pPAC_ASSOCIATION_ID     PAC_EVENT.PAC_ASSOCIATION_ID%type)
  is
    vDOC_RECORD_ID          PAC_CAMPAIGN_EVENT.DOC_RECORD_ID%type;
    vPAC_EVENT_TYPE_ID      PAC_CAMPAIGN_EVENT.PAC_EVENT_TYPE_ID%type;
    vCAE_PRIVATE            PAC_CAMPAIGN_EVENT.CAE_PRIVATE%type;
    vDIC_PRIORITY_CODE_ID   PAC_CAMPAIGN_EVENT.DIC_PRIORITY_CODE_ID%type;
    vEveDate                PAC_EVENT.EVE_DATE%type;
    vEveNumber              PAC_EVENT.EVE_NUMBER%type;
    vEveSubject             PAC_EVENT.EVE_SUBJECT%type;
    vEveText                PAC_EVENT.EVE_TEXT%type;
    vAssignedUserId         PAC_EVENT.EVE_USER_ID%type;
    vTypeLongDescr          PAC_EVENT_TYPE_DESCR.TYP_LONG_DESCRIPTION%type;
    vPacPacPersonId         PAC_PERSON.PAC_PERSON_ID%TYPE;
    vTmp                    PAC_EVENT.PAC_EVENT_ID%type;
  begin
    if (pPAC_CAMPAIGN_EVENT_ID > 0) and (ExistTargetCampaignEvent(pPAC_CAMPAIGN_EVENT_ID, pPAC_PERSON_ID, pPAC_ASSOCIATION_ID) < 1) then
      --Recherche des informations du plan de campagne à utiliser pour créer la tâche
      select
        CAE.DOC_RECORD_ID,
        CAE.PAC_EVENT_TYPE_ID,
        CAE.CAE_PRIVATE,
        CAE.DIC_PRIORITY_CODE_ID,
        nvl(CAE.PC_USER_ID, nvl(DOC.PC_USER_ID, 0))
      into
        vDOC_RECORD_ID,
        vPAC_EVENT_TYPE_ID,
        vCAE_PRIVATE,
        vDIC_PRIORITY_CODE_ID,
        vAssignedUserId
      from
        DOC_RECORD DOC,
        PAC_CAMPAIGN_EVENT CAE
      where
        DOC.DOC_RECORD_ID = CAE.DOC_RECORD_ID AND
        CAE.PAC_CAMPAIGN_EVENT_ID = pPAC_CAMPAIGN_EVENT_ID;


      -- Calcul de la date de fin de la tâche à créer
      vEveDate := CalculateEventDate(pPAC_CAMPAIGN_EVENT_ID, pPAC_PERSON_ID, pPAC_ASSOCIATION_ID, pEVE_DATE_COMPLETED);
      --Numéro de la tâche
      PAC_PARTNER_MANAGEMENT.GetEventNumber(vPAC_EVENT_TYPE_ID, vEveDate, vEveNumber);

      -- Recherche des textes par défaut
      vPacPacPersonId := PAC_PARTNER_MANAGEMENT.GetContactId(pPAC_ASSOCIATION_ID);
      p_getDefaultText(pPAC_CAMPAIGN_EVENT_ID, vPAC_EVENT_TYPE_ID,
          PAC_EVENT_MANAGEMENT.GetCascadeLangId(vPacPacPersonId, pPAC_PERSON_ID),
          vTypeLongDescr, vEveSubject, vEveText);
      -- Formatage du texte
      if vEveText is not null then
        vEveText := pac_macro.formatEventText(
            pPAC_PERSON_ID, vPacPacPersonId, vAssignedUserId,
            vEveDate, null, vEveNumber, vDOC_RECORD_ID,
            vTypeLongDescr, vEveText);
      end if;

      vTmp := InsertNewCampEvent(vPAC_EVENT_TYPE_ID,      /*Type d'événement                                      */
                         pPAC_CAMPAIGN_EVENT_ID,          /*Plan de campagne                                      */
                         vDOC_RECORD_ID,                  /*Dossier                                               */
                         vAssignedUserId,                 /*Attribué à                                            */
                         pPAC_PERSON_ID,                  /*Personne cible                                        */
                         pPAC_ASSOCIATION_ID,             /*Contact                                               */
                         vEveNumber,                      /*Numéro d'événement                                    */
                         vEveSubject,                     /*Sujet de l'événement                                  */
                         vEveText,                        /*Texte de l'événement                                  */
                         vEveDate,                        /*Date de l'événement                                   */
                         vCAE_PRIVATE,                    /*Privé -> visible par l'utilisteur                     */
                         vDIC_PRIORITY_CODE_ID,           /*Priorité                                              */
                         null,                            /*date de fin de tâche                                  */
                         0,                               /*tâche terminée                                        */
                         pPAC_PAC_EVENT_ID);              /*Evénement déclencheur                                 */
    end if;
  end InsertCampaignEvent;

  /**
  * Description
  *   Insertion d'une tâche liée à une campagne
  */
  function InsertNewCampEvent(pPAC_EVENT_TYPE_ID      PAC_EVENT.PAC_EVENT_TYPE_ID%type,
                              pPAC_CAMPAIGN_EVENT_ID  PAC_EVENT.PAC_CAMPAIGN_EVENT_ID%type,
                              pDOC_RECORD_ID          PAC_EVENT.DOC_RECORD_ID%type,
                              pEVE_USER_ID            PAC_EVENT.EVE_USER_ID%type,
                              pPAC_PERSON_ID          PAC_EVENT.PAC_PERSON_ID%type,
                              pPAC_ASSOCIATION_ID     PAC_EVENT.PAC_ASSOCIATION_ID%type,
                              pEVE_NUMBER             PAC_EVENT.EVE_NUMBER%type,
                              pEVE_SUBJECT            PAC_EVENT.EVE_SUBJECT%type,
                              pEVE_TEXT               PAC_EVENT.EVE_TEXT%type,
                              pEVE_DATE               PAC_EVENT.EVE_DATE%type,
                              pEVE_PRIVATE            PAC_EVENT.EVE_PRIVATE%type,
                              pDIC_PRIORITY_CODE_ID   PAC_EVENT.DIC_PRIORITY_CODE_ID%type,
                              pEVE_DATE_COMPLETED     PAC_EVENT.EVE_DATE_COMPLETED%type,
                              pEVE_ENDED              PAC_EVENT.EVE_ENDED%type,
                              pPAC_PAC_EVENT_ID       PAC_EVENT.PAC_PAC_EVENT_ID%type) return PAC_EVENT.PAC_EVENT_ID%type
  is
    vPAC_EVENT_ID PAC_EVENT.PAC_EVENT_ID%type;
  begin
    -- Recherche du nouvel Id
    SELECT PAC_EVENT_SEQ.nextval into vPAC_EVENT_ID FROM DUAL;

    -- Insertion de l'événement
    insert into PAC_EVENT
     (PAC_EVENT_ID,
      PAC_EVENT_TYPE_ID,
      PAC_CAMPAIGN_EVENT_ID,
      DOC_RECORD_ID,
      EVE_USER_ID,
      PAC_PERSON_ID,
      PAC_ASSOCIATION_ID,
      PC_USER_ID,
      EVE_NUMBER,
      EVE_DATE,
      EVE_CAPTURE_DATE,
      EVE_PRIVATE,
      EVE_SUBJECT,
      EVE_TEXT,
      DIC_PRIORITY_CODE_ID,
      EVE_DATE_COMPLETED,
      EVE_ENDED,
      PAC_PAC_EVENT_ID,
      A_DATECRE,
      A_IDCRE)
    values
     (vPAC_EVENT_ID,                   /*Evénement           -> Nouvel ID                      */
      pPAC_EVENT_TYPE_ID,              /*Type d'événement                                      */
      pPAC_CAMPAIGN_EVENT_ID,          /*Plan de campagne                                      */
      pDOC_RECORD_ID,                  /*Dossier                                               */
      decode(pEVE_USER_ID, 0, PCS.PC_I_LIB_SESSION.GetUserID, pEVE_USER_ID),/*Attribué à        */
      pPAC_PERSON_ID,                  /*Personne cible                                        */
      decode(pPAC_ASSOCIATION_ID,0, null, pPAC_ASSOCIATION_ID),     /*Contact                  */
      PCS.PC_I_LIB_SESSION.GetUserID,   /*Créateur de la tâche                                  */
      pEVE_NUMBER,                     /*Numéro d'événement                                    */
      pEVE_DATE,                       /*Date de l'événement                                   */
      SYSDATE,                         /*Date de saisie de l'événement                         */
      pEVE_PRIVATE,                    /*Privé -> visible par l'utilisateur                    */
      pEVE_SUBJECT,                    /*Sujet de l'événement                                  */
      pEVE_TEXT,                       /*Texte de l'événement                                  */
      pDIC_PRIORITY_CODE_ID,           /*Priorité                                              */
      pEVE_DATE_COMPLETED,             /*Date de fin de tâche                                  */
      pEVE_ENDED,                      /*tâche terminée                                        */
      DECODE(pPAC_PAC_EVENT_ID, 0, null, pPAC_PAC_EVENT_ID),     /*Evénement déclencheur       */
      SYSDATE,                         /* Date création      -> Date système                   */
      PCS.PC_I_LIB_SESSION.GetUserIni); /* Id création        -> user                           */
    return vPAC_EVENT_ID;
  end InsertNewCampEvent;

  /**
  * Description
  *   Retourne un utilisateur pour créer une tâche
  */
  function GetAssignedUser(pPAC_CAMPAIGN_EVENT_ID PAC_CAMPAIGN_EVENT.PAC_CAMPAIGN_EVENT_ID%type) return PCS.PC_USER.PC_USER_ID%type
  is
    vPC_USER_ID  PCS.PC_USER.PC_USER_ID%type;
  begin
    vPC_USER_ID  := 0;
    select nvl(CAE.PC_USER_ID, nvl(RCO.PC_USER_ID, 0))
    into vPC_USER_ID
    from PAC_CAMPAIGN_EVENT CAE, DOC_RECORD RCO
    where CAE.PAC_CAMPAIGN_EVENT_ID = pPAC_CAMPAIGN_EVENT_ID and
          CAE.DOC_RECORD_ID         = RCO.DOC_RECORD_ID;
    return vPC_USER_ID;
  end GetAssignedUser;

  /**
  * Description
  *   Retourne la date pour créer une tâche
  */
  function CalculateEventDate(pPAC_CAMPAIGN_EVENT_ID  PAC_CAMPAIGN_EVENT.PAC_CAMPAIGN_EVENT_ID%type,
                              pPAC_PERSON_ID          PAC_PERSON.PAC_PERSON_ID%type,
                              pPAC_ASSOCIATION_ID     PAC_EVENT.PAC_ASSOCIATION_ID%type,
                              pRefDate                PAC_CAMPAIGN_EVENT.CAE_SCHEDULED_DATE%type)
    return PAC_CAMPAIGN_EVENT.CAE_SCHEDULED_DATE%type
  is
    vNewDate  PAC_CAMPAIGN_EVENT.CAE_SCHEDULED_DATE%type;
    vRefDate  PAC_CAMPAIGN_EVENT.CAE_SCHEDULED_DATE%type;
    vNewDelay PAC_CAMPAIGN_EVENT.CAE_DELAY%type;
    function CalculDelay(pDelay   PAC_CAMPAIGN_EVENT.CAE_DELAY%type,
                         pRefDate PAC_CAMPAIGN_eVENT.CAE_SCHEDULED_DATE%type)
      return PAC_CAMPAIGN_EVENT.CAE_SCHEDULED_DATE%type
    is
      vResult PAC_CAMPAIGN_EVENT.CAE_SCHEDULED_DATE%type;
    begin
      select
        decode(pDelay,
          15,  pRefDate + 14,
          30,  ADD_MONTHS(pRefDate, 1),
          360, ADD_MONTHS(pRefDate, 12),
          pRefDate + pDelay) NewDate
      into vResult
      from dual;
      return vResult;
    end;
  begin
    vNewDelay := null;
    vRefDate  := pRefDate;
    if vRefDate is null then
      --Pas de date passée en paramètre, la date de fin de la tâche précédant cette planification sera utilisée comme référence
      select min(EVE.EVE_DATE_COMPLETED)
      into vRefDate
      from
        PAC_EVENT EVE,
        PAC_CAMPAIGN_EVENT CAE
      where
        CAE.DOC_RECORD_ID                  = (select DOC_RECORD_ID
                                              from PAC_CAMPAIGN_EVENT
                                              where PAC_CAMPAIGN_EVENT_ID = pPAC_CAMPAIGN_EVENT_ID)
        and CAE.PAC_CAMPAIGN_EVENT_ID      = EVE.PAC_CAMPAIGN_EVENT_ID
        and EVE.PAC_PERSON_ID              = pPAC_PERSON_ID
        and nvl(EVE.PAC_ASSOCIATION_ID, 0) = nvl(pPAC_ASSOCIATION_ID, 0)
        and cae.cae_sequence               = (select nvl(max(SEQ.CAE_SEQUENCE), -1)
                                              from (select C1.CAE_SEQUENCE
                                                    from PAC_CAMPAIGN_EVENT C1,
                                                         PAC_EVENT E1
                                                    where
                                                       C1.DOC_RECORD_ID = (select DOC_RECORD_ID
                                                                           from PAC_CAMPAIGN_EVENT
                                                                           where PAC_CAMPAIGN_EVENT_ID = pPAC_CAMPAIGN_EVENT_ID) and
                                                       C1.CAE_SEQUENCE < (select CAE_SEQUENCE
                                                                          from PAC_CAMPAIGN_EVENT
                                                                          where PAC_CAMPAIGN_EVENT_ID = pPAC_CAMPAIGN_EVENT_ID) and
                                                      E1.PAC_PERSON_ID              = pPAC_PERSON_ID and
                                                      nvl(E1.PAC_ASSOCIATION_ID, 0) = nvl(pPAC_ASSOCIATION_ID, 0) and
                                                      E1.PAC_CAMPAIGN_EVENT_ID      = C1.PAC_CAMPAIGN_EVENT_ID)SEQ);
    end if;
    --Si date inexistante (pas de tâche jalonnée précédante),
    --recherche de la date de la planification, de la campagne(contrôle si date > sysdate) sinon sysdate
    if vRefDate is null then
      --Recherche de la date de début de campagne
      select
        min(CAE.CAE_SCHEDULED_DATE),
        nvl(min(CAE.CAE_DELAY), 0)
      into
        vNewDate,
        vNewDelay
      from PAC_CAMPAIGN_EVENT CAE
      where CAE.PAC_CAMPAIGN_EVENT_ID = pPAC_CAMPAIGN_EVENT_ID;
      if vNewDate is null then
        --(date de campagne inexistante) ou (date de campagne < que sysdate), prendre sysdate
        select
          decode(sign(trunc(RCO_STARTING_DATE) - trunc(SYSDATE)),
                 1, RCO_STARTING_DATE,
                 sysdate)
        into vNewDate
        from PAC_CAMPAIGN_EVENT CAE, DOC_RECORD RCO
        where CAE.PAC_CAMPAIGN_EVENT_ID = pPAC_CAMPAIGN_EVENT_ID
        and CAE.DOC_RECORD_ID = RCO.DOC_RECORD_ID;
        vNewDate := CalculDelay(vNewDelay, vNewDate);
      end if;
    else
      select CAE.CAE_SCHEDULED_DATE, CAE.CAE_DELAY
      into vNewDate, vNewDelay
      from PAC_CAMPAIGN_EVENT CAE where CAE.PAC_CAMPAIGN_EVENT_ID = pPAC_CAMPAIGN_EVENT_ID;
      if vNewDate is null then
        vNewDate := CalculDelay(vNewDelay, vRefDate);
      end if;
    end if;
    return vNewDate;
  end CalculateEventDate;

  /**
  * Description
  *   Efface tous les événements non modifiés pour une campagne
  */
  procedure ClearCampaignEvents(pDOC_RECORD_ID DOC_RECORD.DOC_RECORD_ID%type)
  is
  begin
    delete from PAC_EVENT EVE
    where
      EVE.A_DATEMOD is null and
      exists(select 0 from PAC_CAMPAIGN_EVENT CAE
             where CAE.DOC_RECORD_ID = pDOC_RECORD_ID
               and CAE.PAC_CAMPAIGN_EVENT_ID = EVE.PAC_CAMPAIGN_EVENT_ID);
  end ClearCampaignEvents;

  /**
  * Description
  *   Recherche si une tâche existe pour un plan de campagne et une personne cible
  */
  function ExistTargetCampaignEvent(pPAC_CAMPAIGN_EVENT_ID  PAC_EVENT.PAC_CAMPAIGN_EVENT_ID%type,
                                    pPAC_PERSON_ID          PAC_EVENT.PAC_PERSON_ID%type,
                                    pPAC_ASSOCIATION_ID     PAC_EVENT.PAC_ASSOCIATION_ID%type)
    return number
  is
    vResult number(1);
  begin
    select
      decode(nvl(max(EVE.PAC_EVENT_ID), 0), 0, 0, 1)
    into vResult
    from
      PAC_EVENT EVE
    where
      EVE.PAC_CAMPAIGN_EVENT_ID      = pPAC_CAMPAIGN_EVENT_ID and
      EVE.PAC_PERSON_ID              = pPAC_PERSON_ID and
      nvl(EVE.PAC_ASSOCIATION_ID, 0) = nvl(pPAC_ASSOCIATION_ID, 0);

    return vResult;
  end ExistTargetCampaignEvent;

  /**
  * Description
  *   Recherche si une campagne est terminée pour une personne cible
  */
  function IsCampaignTargetEnded(pDOC_RECORD_ID      PAC_CAMPAIGN_EVENT.DOC_RECORD_ID%type,
                                 pPAC_PERSON_ID      PAC_EVENT.PAC_PERSON_ID%type,
                                 pPAC_ASSOCIATION_ID PAC_EVENT.PAC_ASSOCIATION_ID%type)
    return number
  is
    vResult number(1);
  begin
    select
      nvl(max(CAQ.CAQ_END_CAMPAIGN), 0)
    into vResult
    from
      PAC_EVENT EVE,
      PAC_CAMPAIGN_EVENT CAE,
      PAC_CAMPAIGN_QUALIF CAQ
    where
      CAE.DOC_RECORD_ID              = pDOC_RECORD_ID and
      EVE.PAC_PERSON_ID              = pPAC_PERSON_ID and
      nvl(EVE.PAC_ASSOCIATION_ID, 0) = nvl(pPAC_ASSOCIATION_ID, 0) and
      CAE.PAC_CAMPAIGN_EVENT_ID      = EVE.PAC_CAMPAIGN_EVENT_ID and
      EVE.PAC_EVENT_ID               = CAQ.PAC_EVENT_ID;
    return vResult;
  end IsCampaignTargetEnded;

  /*
  * function GetNextCampaignPlan
  * Description
  *   Recherche le plan de campagne suivant le plan passé en paramètre
  */
  function GetNextCampaignPlan(pPAC_CAMPAIGN_EVENT_ID PAC_CAMPAIGN_EVENT.PAC_CAMPAIGN_EVENT_ID%type)
    return PAC_CAMPAIGN_EVENT.PAC_CAMPAIGN_EVENT_ID%type
  is
    cursor crPacCampNextIDSequence(pPAC_CAMPAIGN_EVENT_ID PAC_CAMPAIGN_EVENT.PAC_CAMPAIGN_EVENT_ID%type)
    is
      select
        CAE.PAC_CAMPAIGN_EVENT_ID
      from
        PAC_CAMPAIGN_EVENT CAE
      where
        exists(select 1
               from PAC_CAMPAIGN_EVENT CAE1
               where
                 CAE.CAE_SEQUENCE > CAE1.CAE_SEQUENCE and
                 CAE1.PAC_CAMPAIGN_EVENT_ID = pPAC_CAMPAIGN_EVENT_ID) and
        CAE.DOC_RECORD_ID = (select nvl(min(DOC_RECORD_ID), 0) from PAC_CAMPAIGN_EVENT where PAC_CAMPAIGN_EVENT_ID = pPAC_CAMPAIGN_EVENT_ID)
      order by
        CAE.CAE_SEQUENCE ASC;

    vPacCampNextIDSequence crPacCampNextIDSequence%rowtype;
    vResult PAC_CAMPAIGN_EVENT.PAC_CAMPAIGN_EVENT_ID%type;
  begin
    vResult := 0;
    if pPAC_CAMPAIGN_EVENT_ID > 0 then
      open crPacCampNextIDSequence(pPAC_CAMPAIGN_EVENT_ID);
      fetch crPacCampNextIDSequence into vPacCampNextIDSequence;
      if crPacCampNextIDSequence%found then
        vResult := vPacCampNextIDSequence.PAC_CAMPAIGN_EVENT_ID;
      end if;
      close crPacCampNextIDSequence;
    end if;
    return vResult;
  end GetNextCampaignPlan;

  /**
  * procedure AddTargetsFromSearch
  * Description
  *   Ajoute des personnes et des contacts selon sélection via PC_SEARCH
  *   En fonction de la table COM_LIST_ID_TMP,
  *     - si LID_FREE_CHAR_1 = PAC_PERSON
  *          recherche des contacts en fonction des types d'association
  *          sélectionnés pour la campagne
  *     - si LID_FREE_CHAR_1 = PAC_PERSON_ASSOCIATION
  *          utiliser pac_person_id et pac_pac_person_id de l'association retourné
  *          (la règle des types d'association ne s'applique alors pas)
  */
  procedure AddTargetsFromSearch(pDOC_RECORD_ID DOC_RECORD.DOC_RECORD_ID%type,
                       pRCO_DIC_ASSOCIATION_TYPE DOC_RECORD.RCO_DIC_ASSOCIATION_TYPE%type,
                       pDropAllTargets number)
  is
    tblDicAssociationTypeID TtblDicAssociationTypeID;
  begin
    -- Suppression de toutes les cibles pour cette campagne
    if pDropAllTargets > 0 then

      -- Suppression des événements non terminés.
      -- S'il n'existe pas d'événements terminés pour la personne/association).
      delete pac_event eve
      where eve_ended = 0 and
        pac_campaign_event_id in (select pac_campaign_event_id
                                  from pac_campaign_event
                                  where doc_record_id = pDOC_RECORD_ID) and
        not exists
            (select 1 from pac_event ended
             where ended.pac_person_id = eve.pac_person_id and
                (nvl(ended.pac_association_id,0) = nvl(eve.pac_association_id,0)) and
                ended.eve_ended = 1 and
                ended.pac_campaign_event_id in(select pac_campaign_event_id
                                               from pac_campaign_event
                                               where doc_record_id = pDOC_RECORD_ID));

      -- suppression des cibles sans événements liés.
      delete pac_campaign_s_person cap
      where doc_record_id = pDOC_RECORD_ID and
        not exists
            (select 1 from pac_event eve
             where eve.pac_person_id = cap.pac_person_id and
                (nvl(eve.pac_association_id,0) = nvl(cap.pac_person_association_id, 0)) and
                eve.pac_campaign_event_id in(select pac_campaign_event_id
                                             from pac_campaign_event
                                             where doc_record_id = pDOC_RECORD_ID));

    end if;

    /* Sélection selon PAC_PERSON_ASSOCIATION */
    -- Insertion des personnes et des contacts
    insert into pac_campaign_s_person(pac_campaign_s_person_id,
      pac_person_id, pac_person_association_id, doc_record_id)
    select init_id_seq.nextval, pac_person_id, pac_person_association_id,
      pDOC_RECORD_ID
    from pac_person_association a
    where pac_person_association_id in
      (select com_list_id_temp_id from com_list_id_temp
       where lid_code = 'PC_SEARCH' and
             lid_free_char_1 = 'PAC_PERSON_ASSOCIATION') and
      not exists (select 1 from pac_campaign_s_person c
                  where doc_record_id = pDOC_RECORD_ID and
                    c.pac_person_association_id = a.pac_person_association_id);

    /* Sélection selon PAC_PERSON */
    -- Insertion des contacts selon type d'association
    if pRCO_DIC_ASSOCIATION_TYPE is not null then

      -- Remplir une table avec tous les dicos valables
      execute immediate 'select DIC_ASSOCIATION_TYPE_ID from DIC_ASSOCIATION_TYPE '||
                        'where DIC_ASSOCIATION_TYPE_ID IN('''|| replace(pRCO_DIC_ASSOCIATION_TYPE, ';', ''',''') ||''')'
        bulk collect into tblDicAssociationTypeID;

      -- Création pour les différents dicos
      if tblDicAssociationTypeID.count > 0 then
        for j in tblDicAssociationTypeID.first .. tblDicAssociationTypeID.last loop
          insert into pac_campaign_s_person(pac_campaign_s_person_id,
            pac_person_id, pac_person_association_id, doc_record_id)
          select init_id_seq.nextval, pac_person_id, pac_person_association_id,
            pDOC_RECORD_ID
          from pac_person_association a
          where a.dic_association_type_id = tblDicAssociationTypeID(j).DIC_ASSOCIATION_TYPE_ID and
             a.pac_person_id in
                (select com_list_id_temp_id from com_list_id_temp
                 where lid_code = 'PC_SEARCH' and
                       lid_free_char_1 = 'PAC_PERSON') and
             not exists (select 1 from pac_campaign_s_person c
                         where c.doc_record_id = pDOC_RECORD_ID and
                               c.pac_person_association_id = a.pac_person_association_id);
        end loop;
      end if;
    end if;

    -- Insertion des personnes si pas de type d'association ou
    -- type d'association inexistant
    insert into pac_campaign_s_person(pac_campaign_s_person_id,
      pac_person_id, doc_record_id)
    select init_id_seq.nextval, pac_person_id, pDOC_RECORD_ID
    from
      (select com_list_id_temp_id pac_person_id from com_list_id_temp
       where lid_code = 'PC_SEARCH' and
             lid_free_char_1 = 'PAC_PERSON') t
    where not exists (select 1 from pac_campaign_s_person c
                      where c.doc_record_id = pDOC_RECORD_ID and
                        c.pac_person_id = t.pac_person_id);
  end;

  /**
  * procedure DelTargetsFromSearch
  *
  * Description
  *   Supprimer toutes les personnes sélectionnées (via PC_SEARCH)
  *   (excepté celles pour lesquels il existe des événements)
  */
  procedure DelTargetsFromSearch(pDOC_RECORD_ID DOC_RECORD.DOC_RECORD_ID%type)
  is
  begin
    -- Suppression des événements non terminés
    -- S'il n'existe pas d'événements terminés...
    delete pac_event eve
    where eve_ended = 0 and
      pac_campaign_event_id in
        (select pac_campaign_event_id from pac_campaign_event
         where doc_record_id = pDOC_RECORD_ID) and
      pac_association_id in
        (select com_list_id_temp_id from com_list_id_temp
         where lid_code = 'PC_SEARCH' and
               lid_free_char_1 = 'PAC_PERSON_ASSOCIATION') and
      not exists (select 1 from pac_event ended
                  where ended.eve_ended = 1 and
                    ended.pac_association_id = eve.pac_association_id and
                    ended.pac_campaign_event_id in
                      (select pac_campaign_event_id from pac_campaign_event
                       where doc_record_id = pDOC_RECORD_ID));

    delete pac_event eve
    where eve_ended = 0 and
      pac_campaign_event_id in
        (select pac_campaign_event_id from pac_campaign_event
         where doc_record_id = pDOC_RECORD_ID) and
      pac_person_id in
        (select com_list_id_temp_id from com_list_id_temp
         where lid_code = 'PC_SEARCH' and
               lid_free_char_1 = 'PAC_PERSON') and
      not exists (select 1 from pac_event ended
                  where ended.eve_ended = 1 and
                    ended.pac_person_id = eve.pac_person_id and
                    ended.pac_campaign_event_id in
                      (select pac_campaign_event_id from pac_campaign_event
                       where doc_record_id = pDOC_RECORD_ID));


    /* PAC_PERSON_ASSOCIATION */
    delete from pac_campaign_s_person cap
    where doc_record_id = pDOC_RECORD_ID and
      pac_person_association_id in
        (select com_list_id_temp_id from com_list_id_temp
         where lid_code = 'PC_SEARCH' and
               lid_free_char_1 = 'PAC_PERSON_ASSOCIATION') and
      not exists
        (select 1 from pac_event eve
         where pac_association_id = cap.pac_person_association_id and
               pac_campaign_event_id in (select pac_campaign_event_id
                                         from pac_campaign_event
                                         where doc_record_id = pDOC_RECORD_ID));

    /* PAC_PERSON */
    delete from pac_campaign_s_person cap
    where doc_record_id = pDOC_RECORD_ID and
      pac_person_id in
        (select com_list_id_temp_id from com_list_id_temp
         where lid_code = 'PC_SEARCH' and
               lid_free_char_1 = 'PAC_PERSON') and
      not exists
        (select 1 from pac_event eve
         where eve.pac_person_id = cap.pac_person_id and
               pac_campaign_event_id in (select pac_campaign_event_id
                                         from pac_campaign_event
                                         where doc_record_id = pDOC_RECORD_ID));
  end;

  /**
  * procedure CountAllTargetsEvt
  *
  * Description
  *   Retourne le nombre de cibles avec des événements
  */
  function CountAllTargetsEvt(pDOC_RECORD_ID DOC_RECORD.DOC_RECORD_ID%type) return number
  is
    vResult number;
  begin
    SELECT COUNT(*) INTO vResult
    FROM PAC_CAMPAIGN_S_PERSON cap
    WHERE DOC_RECORD_ID = pDOC_RECORD_ID AND
      EXISTS
          (SELECT 1 FROM PAC_EVENT eve, PAC_CAMPAIGN_EVENT ce
           WHERE eve.PAC_PERSON_ID = cap.PAC_PERSON_ID AND
              (NVL(eve.PAC_ASSOCIATION_ID,0) = NVL(cap.PAC_PERSON_ASSOCIATION_ID, 0)) AND
              eve.PAC_CAMPAIGN_EVENT_ID = ce.PAC_CAMPAIGN_EVENT_id and
              ce.DOC_RECORD_ID = pDoc_RECORD_ID);

    return vResult;
  end;



  /**
  * procedure CountTargetsEvt
  *
  * Description
  *   Retourne le nombre de cibles sélectionnées (com_list_id_temp)
  *   avec des événements (terminés ?)
  */
  function CountTargetsEvt(pDOC_RECORD_ID DOC_RECORD.DOC_RECORD_ID%type) return number
  is
    vResult number;
  begin
    SELECT COUNT(*)INTO vResult FROM pac_campaign_s_person cap
    WHERE doc_record_id = pDOC_RECORD_ID and
      ((pac_person_association_id in
         (SELECT com_list_id_temp_id from com_list_id_temp
          WHERE lid_code = 'PC_SEARCH' and
                lid_free_char_1 = 'PAC_PERSON_ASSOCIATION')) or
       (pac_person_id in
         (SELECT com_list_id_temp_id from com_list_id_temp
          WHERE lid_code = 'PC_SEARCH' and
                lid_free_char_1 = 'PAC_PERSON'))) and
       EXISTS
         (SELECT 1 from pac_event eve, pac_campaign_event ce
          WHERE eve.pac_person_id = cap.pac_person_id and
            (nvl(eve.pac_association_id,0) = nvl(cap.pac_person_association_id, 0)) and
            eve.pac_campaign_event_id =  ce.pac_campaign_event_id and
            ce.doc_record_id = pDOC_RECORD_ID);

    return vResult;
  end;

  /**
  * procedure DuplicateCampaign
  * Description
  *   Copie une campagne
  */
  procedure DuplicateCampaign(pSrcDOC_RECORD_ID     DOC_RECORD.DOC_RECORD_ID%type,
                              pNewDOC_RECORD_ID out DOC_RECORD.DOC_RECORD_ID%type,
                              pNewTitle             DOC_RECORD.RCO_TITLE%type,
                              pNewNumber            DOC_RECORD.RCO_NUMBER%type,
                              pImportTargets        number,
                              pImportCampaignPlan   number,
                              pCreatePlanification  number)
  is
    vNewCampaignEvtId PAC_CAMPAIGN_EVENT.PAC_CAMPAIGN_EVENT_ID%TYPE;
    vUser PCS.PC_USER.USE_INI%TYPE;
  begin
    select init_id_seq.nextval
      into pNewDOC_RECORD_ID
      from dual;

    vUser := PCS.PC_I_LIB_SESSION.GetUserIni;

    --Copie de la campagne
    insert into DOC_RECORD
     (DOC_RECORD_ID,
      RCO_TITLE,
      RCO_DESCRIPTION,
      RCO_NUMBER,
      RCO_DIC_ASSOCIATION_TYPE,
      RCO_STARTING_DATE,
      RCO_ENDING_DATE,
      PC_USER_ID,
      C_RCO_STATUS,
      C_RCO_TYPE,
      RCO_XML_CONDITIONS,
      A_DATECRE,
      A_IDCRE)
    (select
      pNewDOC_RECORD_ID,
      pNewTitle,
      RCO.RCO_DESCRIPTION,
      nvl(pNewNumber, RCO_NUMBER_SEQ.nextval),
      RCO.RCO_DIC_ASSOCIATION_TYPE,
      RCO.RCO_STARTING_DATE,
      RCO.RCO_ENDING_DATE,
      RCO.PC_USER_ID,
      RCO.C_RCO_STATUS,
      RCO.C_RCO_TYPE,
      RCO.RCO_XML_CONDITIONS,
      sysdate,
      vUser
    from
      DOC_RECORD RCO
    where
      RCO.DOC_RECORD_ID = pSrcDOC_RECORD_ID);

    --Copie des personnes cibles si voulu
    if pImportTargets > 0 then
      insert into PAC_CAMPAIGN_S_PERSON
       (PAC_CAMPAIGN_S_PERSON_ID,
        DOC_RECORD_ID,
        PAC_PERSON_ID,
        PAC_PERSON_ASSOCIATION_ID)
      (select
         init_id_seq.nextval,
         pNewDOC_RECORD_ID,
         CSP.PAC_PERSON_ID,
         CSP.PAC_PERSON_ASSOCIATION_ID
       from
         PAC_CAMPAIGN_S_PERSON CSP
       where
         CSP.DOC_RECORD_ID = pSrcDOC_RECORD_ID);
    end if;

    vUser := PCS.PC_I_LIB_SESSION.GetUserIni;

    --Copie du plan de campagne
    if pImportCampaignPlan > 0 then
      for tplCampaignEvt in (
          select PAC_CAMPAIGN_EVENT_ID, PAC_EVENT_TYPE_ID,
            PC_USER_ID, DIC_PRIORITY_CODE_ID, DOC_RECORD_ID, CAE_SUBJECT,
            CAE_PRIVATE, CAE_FLAG, CAE_TARGET_RESPONSIBLE, CAE_SCHEDULED_DATE,
            CAE_DELAY, CAE_DAYS_QTY, CAE_SEQUENCE
          from PAC_CAMPAIGN_EVENT
          where DOC_RECORD_ID = pSrcDOC_RECORD_ID)
      loop
        select init_id_seq.nextval into vNewCampaignEvtId from dual;

        -- Copie du plan de campagne
        insert into PAC_CAMPAIGN_EVENT
         (PAC_CAMPAIGN_EVENT_ID,
          PAC_EVENT_TYPE_ID,
          PC_USER_ID,
          DIC_PRIORITY_CODE_ID,
          DOC_RECORD_ID,
          CAE_SUBJECT,
          CAE_PRIVATE,
          CAE_FLAG,
          CAE_TARGET_RESPONSIBLE,
          CAE_SCHEDULED_DATE,
          CAE_DELAY,
          CAE_DAYS_QTY,
          CAE_SEQUENCE,
          A_DATECRE,
          A_IDCRE)
        values(
          vNewCampaignEvtId,
          tplCampaignEvt.PAC_EVENT_TYPE_ID,
          tplCampaignEvt.PC_USER_ID,
          tplCampaignEvt.DIC_PRIORITY_CODE_ID,
          pNewDOC_RECORD_ID,
          tplCampaignEvt.CAE_SUBJECT,
          tplCampaignEvt.CAE_PRIVATE,
          tplCampaignEvt.CAE_FLAG,
          tplCampaignEvt.CAE_TARGET_RESPONSIBLE,
          tplCampaignEvt.CAE_SCHEDULED_DATE,
          tplCampaignEvt.CAE_DELAY,
          tplCampaignEvt.CAE_DAYS_QTY,
          tplCampaignEvt.CAE_SEQUENCE,
          sysdate,
          vUser);

        -- Copie des textes
        insert into PAC_EVENT_TYPE_DESCR
          (PAC_CAMPAIGN_EVENT_ID, PC_LANG_ID, TYP_LONG_DESCRIPTION,
           TYP_DEFAULT_SUBJECT, TYP_DEFAULT_TEXT,
           A_DATECRE, A_IDCRE)
        (select
          vNewCampaignEvtId,
          PC_LANG_ID,
          TYP_LONG_DESCRIPTION,
          TYP_DEFAULT_SUBJECT,
          TYP_DEFAULT_TEXT,
          sysdate,
          vUser
         from
           PAC_EVENT_TYPE_DESCR
         where
           PAC_CAMPAIGN_EVENT_ID = tplCampaignEvt.PAC_CAMPAIGN_EVENT_ID);

        -- Copie des pièces jointes
        insert into PAC_EVENT_FILES
          (PAC_EVENT_FILES_ID, PAC_CAMPAIGN_EVENT_ID, PC_LANG_ID,
           EVF_NAME, EVF_FILE, EVF_COMMENT, A_DATECRE, A_IDCRE)
        (select
          init_id_seq.nextval,
          vNewCampaignEvtId,
          PC_LANG_ID,
          EVF_NAME,
          EVF_FILE,
          EVF_COMMENT,
          sysdate,
          vUser
         from
           PAC_EVENT_FILES
         where
           PAC_CAMPAIGN_EVENT_ID = tplCampaignEvt.PAC_CAMPAIGN_EVENT_ID);

      end loop;
    end if;

    --Création de la planification
    if (pCreatePlanification > 0) then
      CreateTargetsCampaignPlan(pNewDOC_RECORD_ID);
    end if;

  end DuplicateCampaign;

  /**
  * function IsCampaignEnded
  * Description
  *   Contrôle que l'événement passé en paramètre ne fait pas partie d'une campagne terminée
  */
  function IsCampaignEnded(pPAC_EVENT_ID PAC_EVENT.PAC_EVENT_ID%type) return number
  is
    vResult number(1);
  begin
    select nvl(max(CAQ.CAQ_END_CAMPAIGN), 0)
    into vResult
    from PAC_CAMPAIGN_QUALIF CAQ
    where exists
      (select 1
       from
         PAC_CAMPAIGN_EVENT CAE,
         PAC_EVENT EVE
       where
         CAE.PAC_CAMPAIGN_EVENT_ID      = EVE.PAC_CAMPAIGN_EVENT_ID and
         CAE.DOC_RECORD_ID              = (select DOC_RECORD_ID from PAC_EVENT where PAC_EVENT_ID = pPAC_EVENT_ID) and
         EVE.PAC_PERSON_ID              = (select PAC_PERSON_ID from PAC_EVENT where PAC_EVENT_ID = pPAC_EVENT_ID) and
         nvl(EVE.PAC_ASSOCIATION_ID, 0) = (select nvl(max(PAC_ASSOCIATION_ID), 0) from PAC_EVENT where PAC_EVENT_ID = pPAC_EVENT_ID) and
         CAQ.PAC_EVENT_ID               = EVE.PAC_EVENT_ID);
    return vResult;
  end IsCampaignEnded;


  /**
  * function CheckEndCampaign
  * Description
  *   Contrôle que pour cette campagne et cette personne + association, il n'existe pas déjà une qualification finale
  */
  function CheckEndCampaign(pDOC_RECORD_ID          DOC_RECORD.DOC_RECORD_ID%type,
                            pPAC_CAMPAIGN_QUALIF_ID PAC_CAMPAIGN_QUALIF.PAC_CAMPAIGN_QUALIF_ID%type,
                            pPAC_PERSON_ID          PAC_CAMPAIGN_S_PERSON.PAC_PERSON_ID%type,
                            pPAC_ASSOCIATION_ID     PAC_EVENT.PAC_ASSOCIATION_ID%type) return number
  is
    vResult number(1);
  begin
    select nvl(max(CAQ.CAQ_END_CAMPAIGN), 0)
    into vResult
    from
      PAC_CAMPAIGN_EVENT CAE,
      PAC_EVENT EVE,
      PAC_CAMPAIGN_QUALIF CAQ
    where
      CAE.DOC_RECORD_ID              = pDOC_RECORD_ID and
      CAQ.PAC_CAMPAIGN_QUALIF_ID    <> pPAC_CAMPAIGN_QUALIF_ID and
      CAQ.CAQ_END_CAMPAIGN           = 1 and
      EVE.PAC_PERSON_ID              = pPAC_PERSON_ID and
      nvl(EVE.PAC_ASSOCIATION_ID, 0) = pPAC_ASSOCIATION_ID and
      CAE.PAC_CAMPAIGN_EVENT_ID      = EVE.PAC_CAMPAIGN_EVENT_ID and
      EVE.PAC_EVENT_ID               = CAQ.PAC_EVENT_ID;
    return vResult;
  end CheckEndCampaign;

end PAC_CAMPAIGN;
