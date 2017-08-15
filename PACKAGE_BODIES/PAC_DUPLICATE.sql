--------------------------------------------------------
--  DDL for Package Body PAC_DUPLICATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PAC_DUPLICATE" 
is
  /**
  * Description
  *        Fonction de duplification des types de lien
  */
  procedure DuplicateLinkType(
    pSourceLinkType            PAC_LINK_TYP.PAC_LINK_TYP_ID%type   /*Type source à duplifier   */
  , pSourceLinkDescr           PAC_LINK_TYP.TLI_DESCR%type   /*Descriptif source         */
  , pDuplicateAllChain         number   /*Duplifier toute la chaîne */
  , pDuplicatedLinkType in out PAC_LINK_TYP.PAC_LINK_TYP_ID%type
  )
  is
    --Curseur de recheche des liens automatiques du type source
    cursor TypeAutomaticLink(pSourceLinkType PAC_LINK_TYP.PAC_LINK_TYP_ID%type)
    is
      select *
        from PAC_AUTOMATIC_LINK
       where PAC_LINK_TYP_ID = pSourceLinkType;

    vDuplicatedLinkType PAC_LINK_TYP.PAC_LINK_TYP_ID%type;   /*Réceptionne l'id du type créé             */
    vAutomaticLink      TypeAutomaticLink%rowtype;   /*Réceptionne les données du curseur        */
    vDuplicatedAutoLink PAC_AUTOMATIC_LINK.PAC_AUTOMATIC_LINK_ID%type;   /*Réceptionne l'id du lien automatique créé */
    vLinkDescr          PAC_LINK_TYP.TLI_DESCR%type;   /*Descriptif formaté cible                  */
    vVersionPosCpt      number;   /* Position du [ dans le descriptif indiquant la "version" duplifiée */
                                  /* et accessoirement réceptionne le compteur de version              */
  begin
    begin
      --Réception d'un nouvel Id de Type de lien
      select INIT_ID_SEQ.nextval
        into vDuplicatedLinkType
        from dual;

      select instr(pSourceLinkDescr, '' || '[' || '')   --Réception du numéro de version
        into vVersionPosCpt
        from dual;

      vLinkDescr  := pSourceLinkDescr;

      if vVersionPosCpt > 0 then   --Le type courant est un type déjà duplifié
        select substr(pSourceLinkDescr, 1, vVersionPosCpt + 1)   --Réception de la "Racine" du descriptif
          into vLinkDescr
          from dual;
      else
        vLinkDescr  := vLinkDescr || ' [ ';
      end if;

      select count(*) + 1   --Recherche dz nombre de version dont le descriptif = "Racine" du descriptif
        into vVersionPosCpt
        from PAC_LINK_TYP
       where TLI_DESCR like vLinkDescr || '%';

      -- Formatage du descriptif du nouveau type
      vLinkDescr  :=
                  substr( (vLinkDescr || to_char(trunc(sysdate), 'DD.MM.YYYY') || ' - ' || vVersionPosCpt || ' ]'), 1
                       , 50);

      /* Création de l'enregistrement sur la base du type à duplifier*/
      insert into PAC_LINK_TYP
                  (PAC_LINK_TYP_ID
                 , TLI_DESCR
                 , TLI_PATH
                 , TLI_EXT
                 , C_LINK_TYP
                 , C_UTILITY_MODE
                 , C_ADDRESSING_TYP
                 , TLI_SOURCE_FILE
                 , TLI_TEXT_INCLUDE
                 , TLI_FOLDER
                 , TLI_FOLDER_ENTRYID
                 , TLI_FOLDER_STOREID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select vDuplicatedLinkType   /* Type de lien       -> Nouvel Id                      */
             , vLinkDescr   /* Descriptif         -> Initialisé par paramètre       */
             , TLI_PATH   /* Chemin par défaut  -> Initialisé par origine         */
             , TLI_EXT   /* Extension          -> Initialisé par origine         */
             , C_LINK_TYP   /* Type de lien       -> Initialisé par origine         */
             , C_UTILITY_MODE   /* Mode utilitaire externe -> Initialisé par origine    */
             , C_ADDRESSING_TYP   /* Adressage          -> Initialisé par origine         */
             , TLI_SOURCE_FILE   /* Fichier source     -> Initialisé par origine         */
             , TLI_TEXT_INCLUDE   /* Inclusion du text  -> Initialisé par origine         */
             , TLI_FOLDER   /* Dossier Outlook    -> Initialisé par origine         */
             , TLI_FOLDER_ENTRYID   /* FolderEntry        -> Initialisé par origine         */
             , TLI_FOLDER_STOREID   /* StoreId            -> Initialisé par origine         */
             , sysdate   /* Date création      -> Date système                   */
             , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id création        -> user                           */
          from PAC_LINK_TYP
         where PAC_LINK_TYP_ID = pSourceLinkType;

      /*Duplification de toute la chaîne parent- enfant */
      if pDuplicateAllChain = 1 then
        /*Parcours des liens automatiques du type courant à duplifier        */
        /*Chaque lien automatique est duplifié et est rattaché au type cible */
        open TypeAutomaticLink(pSourceLinkType);

        fetch TypeAutomaticLink
         into vAutomaticLink;

        while TypeAutomaticLink%found loop
          DuplicateAutomaticLink(vDuplicatedLinkType
                               ,   /*Type parent             */
                                 vAutomaticLink.PAC_AUTOMATIC_LINK_ID
                               ,   /*Lien automatique source */
                                 vDuplicatedAutoLink   /* Lien automatique créé  */
                                );

          fetch TypeAutomaticLink
           into vAutomaticLink;
        end loop;

        close TypeAutomaticLink;
      end if;
    exception
      when others then
        vDuplicatedLinkType  := 0;
        raise;
    end;

    pDuplicatedLinkType  := vDuplicatedLinkType;   /*Assignation du paramètre de retour*/
  end DuplicateLinkType;

  /**
  * Description
  *        Fonction de duplification des types d'événements
  */
  procedure DuplicateEventType(
    pSourceEventType            PAC_EVENT_TYPE.PAC_EVENT_TYPE_ID%type   /*Type source à duplifier   */
  , pDuplicateAllChain          number   /*Duplifier toute la chaîne */
  , pDuplicatedEventType in out PAC_EVENT_TYPE.PAC_EVENT_TYPE_ID%type
  )
  is
    --Curseur de recheche des méthode de numérotation
    cursor EventTypeApplicationNumber(pEventTypeId PAC_EVENT_TYPE.PAC_EVENT_TYPE_ID%type)
    is
      select *
        from PAC_NUMBER_APPLICATION
       where PAC_EVENT_TYPE_ID = pEventTypeId;

    --Curseur de recheche des code obligatoires
    cursor EventTypeMandatoryCode(pEventTypeId PAC_EVENT_TYPE.PAC_EVENT_TYPE_ID%type)
    is
      select *
        from PAC_MANDATORY_CODE
       where PAC_EVENT_TYPE_ID = pEventTypeId;

    --Curseur de recheche des liens automatiques du type source
    cursor TypeAutomaticLink(pEventTypeId PAC_EVENT_TYPE.PAC_EVENT_TYPE_ID%type)
    is
      select *
        from PAC_AUTOMATIC_LINK
       where PAC_EVENT_TYPE_ID = pEventTypeId;

    vEvtTypeDescr             PAC_EVENT_TYPE.TYP_DESCRIPTION%type;   /*Réception description racine*/
    vDuplicatedEventType      PAC_EVENT_TYPE.PAC_EVENT_TYPE_ID%type;   /*Réceptionne le nouvel id créé                                      */
    vMandatoryCode            EventTypeMandatoryCode%rowtype;   /*Réceptionne les données du curseur sur les codes obligatoires      */
    vAutomaticLink            TypeAutomaticLink%rowtype;   /*Réceptionne les données du curseur sur les liens automatiques      */
    vApplicationNumber        EventTypeApplicationNumber%rowtype;   /*Réceptionne les données du curseur sur les numérotations           */
    vDuplicatedAutoLink       PAC_AUTOMATIC_LINK.PAC_AUTOMATIC_LINK_ID%type;   /*Réceptionne l'id du lien créé par duplification         */
    vDuplicatedMandatoryCode  PAC_MANDATORY_CODE.PAC_MANDATORY_CODE_ID%type;   /*Réceptionne l'id du code créépar duplification          */
    vDuplicatedApplicationNum PAC_NUMBER_APPLICATION.PAC_NUMBER_APPLICATION_ID%type;   /*Réceptionne l'id de numérotation créé par duplification */
  begin
    begin
      --Réception d'un nouvel Id de Type d'événement
      select INIT_ID_SEQ.nextval
        into vDuplicatedEventType
        from dual;

      -- Recherche 'racine' du type courant
      select nvl(substr(TYP_DESCRIPTION, 1, instr(TYP_DESCRIPTION, '[') - 1), TYP_DESCRIPTION) SrcDescr
        into vEvtTypeDescr
        from PAC_EVENT_TYPE
       where PAC_EVENT_TYPE_ID = pSourceEventType;

      -- Recherche nombre de version dont le descriptif = "Racine" du descriptif
      select substr( (vEvtTypeDescr || ' [' || to_char(trunc(sysdate), 'DD.MM.YYYY') || ' - ' ||(count(*) + 1) || ']')
                  , 1
                  , 50
                   )
        into vEvtTypeDescr
        from PAC_EVENT_TYPE
       where TYP_DESCRIPTION like vEvtTypeDescr || '%';

      /* Création de l'enregistrement sur la base du type à copier */
      insert into PAC_EVENT_TYPE
                  (PAC_EVENT_TYPE_ID
                 , TYP_SHORT_DESCRIPTION
                 , TYP_DESCRIPTION
                 , TYP_EVENT_AVAILABLE
                 , TYP_ENDDATE_MANAGEMENT
                 , TYP_REMDATE_MANAGEMENT
                 , TYP_PAC_PERSON_LINK
                 , TYP_DOC_RECORD_LINK
                 , TYP_GCO_GOOD_LINK
                 , TYP_DOC_DOCUMENT_LINK
                 , TYP_CML_POSITION_LINK
                 , TYP_FAM_ASSETS_LINK
                 , TYP_ACT_DOCUMENT_LINK
                 , TYP_ASA_GUARANTY_LINK
                 , TYP_ASA_RECORD_LINK
                 , TYP_REGROUP_FREE_CODE
                 , DIC_EVENT_DOMAIN_ID
                 , DIC_EVENT_TYPE_GROUP_ID
                 , C_PAC_CONFIG
                 , C_EVENT_DATE_FORMAT
                 , C_END_EVENT_DATE_FORMAT
                 , C_REM_EVENT_DATE_FORMAT
                 , A_DATECRE
                 , A_IDCRE
                  )
        select vDuplicatedEventType   /* Type d'événement   -> Nouvel Id                      */
             , TYP_SHORT_DESCRIPTION   /* Descriptif abbrégé -> Initialisé par paramètre       */
             , vEvtTypeDescr
             , TYP_EVENT_AVAILABLE   /* Disponible         -> Initialisé par origine         */
             , TYP_ENDDATE_MANAGEMENT   /* Gestion date fin   -> Initialisé par origine         */
             , TYP_REMDATE_MANAGEMENT   /* Getsion date rappel-> Initialisé par origine         */
             , TYP_PAC_PERSON_LINK   /* Lien parsonne      -> Initialisé par origine         */
             , TYP_DOC_RECORD_LINK   /* Lien dossier       -> Initialisé par origine         */
             , TYP_GCO_GOOD_LINK   /* Lien bien          -> Initialisé par origine         */
             , TYP_DOC_DOCUMENT_LINK   /* Lien document      -> Initialisé par origine         */
             , TYP_CML_POSITION_LINK   /* Lien pos. contrat  -> Initialisé par origine         */
             , TYP_FAM_ASSETS_LINK   /* Lien Immo          -> Initialisé par origine         */
             , TYP_ACT_DOCUMENT_LINK   /* Lien Doc finance   -> Initialisé par origine         */
             , TYP_ASA_GUARANTY_LINK   /* Lien carte garantie-> Initialisé par origine         */
             , TYP_ASA_RECORD_LINK   /* Lien SAV           -> Initialisé par origine         */
             , TYP_REGROUP_FREE_CODE   /* Code libre regroupé-> Initialisé par origine         */
             , DIC_EVENT_DOMAIN_ID   /* Domaine            -> Initialisé par origine         */
             , DIC_EVENT_TYPE_GROUP_ID   /* Groupe             -> Initialisé par origine         */
             , C_PAC_CONFIG   /* Config PAC         -> Initialisé par origine         */
             , C_EVENT_DATE_FORMAT   /* Format date        -> Initialisé par origine         */
             , C_END_EVENT_DATE_FORMAT   /* Format date fin    -> Initialisé par origine         */
             , C_REM_EVENT_DATE_FORMAT   /* Format date rappel -> Initialisé par origine         */
             , sysdate   /* Date création      -> Date système                   */
             , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id création        -> user                           */
          from PAC_EVENT_TYPE
         where PAC_EVENT_TYPE_ID = pSourceEventType;

      -- Descriptions et textes par défaut multi-langue
      insert into PAC_EVENT_TYPE_DESCR
                  (PAC_EVENT_TYPE_ID
                 , PC_LANG_ID
                 , TYP_SHORT_DESCRIPTION
                 , TYP_LONG_DESCRIPTION
                 , TYP_DEFAULT_SUBJECT
                 , TYP_DEFAULT_TEXT
                 , A_DATECRE
                 , A_IDCRE
                  )
        select vDuplicatedEventType
             , PC_LANG_ID
             , TYP_SHORT_DESCRIPTION
             , vEvtTypeDescr
             , TYP_DEFAULT_SUBJECT
             , TYP_DEFAULT_TEXT
             , sysdate
             , PCS.PC_I_LIB_SESSION.GetUserIni
          from PAC_EVENT_TYPE_DESCR
         where PAC_EVENT_TYPE_ID = pSourceEventType;

      --PAC_NUMBER_APPLICATION
      --PAC_MANDATORY_CODE
      --PAC_AUTOMATIC_LINK

      /*Duplification de toute la chaîne parent- enfant */
      if pDuplicateAllChain = 1 then
        /*Parcours des numérotations du type d'événement courant                                */
        /*Chaque méthode de numérotation est duplifié et est rattaché au type d'événement cible */
        open EventTypeApplicationNumber(pSourceEventType);

        fetch EventTypeApplicationNumber
         into vApplicationNumber;

        while EventTypeApplicationNumber%found loop
          DuplicateEventTypeApplNumber(vDuplicatedEventType
                                     ,   /*Type d'événement parent  */
                                       vApplicationNumber.PAC_NUMBER_APPLICATION_ID
                                     ,   /*Numérotation source      */
                                       vDuplicatedApplicationNum   /*Numérotation créé        */
                                      );

          fetch EventTypeApplicationNumber
           into vApplicationNumber;
        end loop;

        close EventTypeApplicationNumber;

        /*Parcours des codes obligatoires du type d'événement courant                    */
        /*Chaque code obligatoire est duplifié et est rattaché au type d'événement cible */
        open EventTypeMandatoryCode(pSourceEventType);

        fetch EventTypeMandatoryCode
         into vMandatoryCode;

        while EventTypeMandatoryCode%found loop
          DuplicateEventTypeCode(vDuplicatedEventType
                               ,   /*Type d'événement parent  */
                                 vMandatoryCode.PAC_MANDATORY_CODE_ID
                               ,   /*Code obligatoire source  */
                                 vDuplicatedMandatoryCode   /*Code obligatoire créé    */
                                );

          fetch EventTypeMandatoryCode
           into vMandatoryCode;
        end loop;

        close EventTypeMandatoryCode;

        /*Parcours des liens automatiques du type courant à duplifier        */
        /*Chaque lien automatique est duplifié et est rattaché au type cible */
        open TypeAutomaticLink(pSourceEventType);

        fetch TypeAutomaticLink
         into vAutomaticLink;

        while TypeAutomaticLink%found loop
          DuplicateEventTypeAutoLink(vDuplicatedEventType
                                   ,   /*Type d'événement parent */
                                     vAutomaticLink.PAC_AUTOMATIC_LINK_ID
                                   ,   /*Lien automatique source */
                                     vDuplicatedAutoLink   /* Lien automatique créé  */
                                    );

          fetch TypeAutomaticLink
           into vAutomaticLink;
        end loop;

        close TypeAutomaticLink;
      end if;
    exception
      when others then
        vDuplicatedEventType  := 0;
        raise;
    end;

    pDuplicatedEventType  := vDuplicatedEventType;   /*Assignation du paramètre de retour*/
  end DuplicateEventType;

  /**
  * Description
  *        Procedure de duplification des liens automatiques d'un type de lien
  */
  procedure DuplicateAutomaticLink(
    pLinkType                   PAC_LINK_TYP.PAC_LINK_TYP_ID%type   /*Type parent             */
  , pSourceAutomaticLink        PAC_AUTOMATIC_LINK.PAC_AUTOMATIC_LINK_ID%type   /*Lien automatique source */
  , pDuplicatedAutoLink  in out PAC_AUTOMATIC_LINK.PAC_AUTOMATIC_LINK_ID%type
  )   /* Lien automatique créé  */
  is
    vDuplicatedAutoLink PAC_AUTOMATIC_LINK.PAC_AUTOMATIC_LINK_ID%type;   /*Réceptionne l'id du lien automatique créé */
  begin
    begin
      /*Réception d'un nouvel Id de Type de lien*/
      select INIT_ID_SEQ.nextval
        into vDuplicatedAutoLink
        from dual;

      /* Création de l'enregistrement sur la base du type à duplifier*/
      insert into PAC_AUTOMATIC_LINK
                  (PAC_AUTOMATIC_LINK_ID
                 , PAC_EVENT_TYPE_ID
                 , PAC_LINK_TYP_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select vDuplicatedAutoLink   /* Lien automatique   -> Nouvel Id                      */
             , PAC_EVENT_TYPE_ID   /* Type d'événement   -> Initialisé par origine         */
             , pLinkType   /* Type de lien       -> Initialisé par paramètre       */
             , sysdate   /* Date création      -> Date système                   */
             , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id création        -> user                           */
          from PAC_AUTOMATIC_LINK
         where PAC_AUTOMATIC_LINK_ID = pSourceAutomaticLink;
    exception
      when others then
        vDuplicatedAutoLink  := 0;
        raise;
    end;

    pDuplicatedAutoLink  := vDuplicatedAutoLink;   /*Assignation du paramètre de retour */
  end DuplicateAutomaticLink;

  /**
  * Description
  *        Procedure de duplification des liens automatiques d'un type d'événement
  */
  procedure DuplicateEventTypeAutoLink(
    pEventType                  PAC_EVENT_TYPE.PAC_EVENT_TYPE_ID%type   /*Type d'événement parent */
  , pSourceAutomaticLink        PAC_AUTOMATIC_LINK.PAC_AUTOMATIC_LINK_ID%type   /*Lien automatique source */
  , pDuplicatedAutoLink  in out PAC_AUTOMATIC_LINK.PAC_AUTOMATIC_LINK_ID%type
  )   /* Lien automatique créé  */
  is
    vDuplicatedAutoLink PAC_AUTOMATIC_LINK.PAC_AUTOMATIC_LINK_ID%type;   /*Réceptionne l'id du lien automatique créé */
  begin
    begin
      /*Réception d'un nouvel Id de Type de lien*/
      select INIT_ID_SEQ.nextval
        into vDuplicatedAutoLink
        from dual;

      /* Création de l'enregistrement sur la base du type à duplifier*/
      insert into PAC_AUTOMATIC_LINK
                  (PAC_AUTOMATIC_LINK_ID
                 , PAC_EVENT_TYPE_ID
                 , PAC_LINK_TYP_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select vDuplicatedAutoLink   /* Lien automatique   -> Nouvel Id                      */
             , pEventType   /* Type d'événement   -> Initialisé par paramètre       */
             , PAC_LINK_TYP_ID   /* Type de lien       -> Initialisé par origine         */
             , sysdate   /* Date création      -> Date système                   */
             , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id création        -> user                           */
          from PAC_AUTOMATIC_LINK
         where PAC_AUTOMATIC_LINK_ID = pSourceAutomaticLink;
    exception
      when others then
        vDuplicatedAutoLink  := 0;
        raise;
    end;

    pDuplicatedAutoLink  := vDuplicatedAutoLink;   /*Assignation du paramètre de retour */
  end DuplicateEventTypeAutoLink;

  /**
  * Description
  *        Procedure de duplification des méthode de numérotation
  */
  procedure DuplicateEventTypeApplNumber(
    pEventType                  PAC_EVENT_TYPE.PAC_EVENT_TYPE_ID%type   /*Type d'événement parent       */
  , pSourceNumberApp            PAC_NUMBER_APPLICATION.PAC_NUMBER_APPLICATION_ID%type   /*Méthode de numérotation source*/
  , pDuplicatedNumberApp in out PAC_NUMBER_APPLICATION.PAC_NUMBER_APPLICATION_ID%type
  )   /*Méthdoe de numérotation créé  */
  is
    vDuplicatedNumberApp PAC_NUMBER_APPLICATION.PAC_NUMBER_APPLICATION_ID%type;   /*Réceptionne l'id de la numérotation créée */
  begin
    begin
      /*Réception d'un nouvel Id de Type de lien*/
      select INIT_ID_SEQ.nextval
        into vDuplicatedNumberApp
        from dual;

      /* Création de l'enregistrement sur la base du type à duplifier*/
      insert into PAC_NUMBER_APPLICATION
                  (PAC_NUMBER_APPLICATION_ID
                 , PAC_EVENT_TYPE_ID
                 , PAC_NUMBER_METHOD_ID
                 , NUA_SINCE
                 , NUA_TO
                 , A_DATECRE
                 , A_IDCRE
                  )
        select vDuplicatedNumberApp   /* Numérotation      -> Nouvel Id                      */
             , pEventType   /* Type d'événement  -> Initialisé par paramètre       */
             , PAC_NUMBER_METHOD_ID   /* Méthode de num.   -> Initialisé par origine         */
             , NUA_SINCE   /* Depuis            -> Initialisé par origine         */
             , NUA_TO   /* Jusqu'au          -> Initialisé par origine         */
             , sysdate   /* Date création      -> Date système                   */
             , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id création        -> user                           */
          from PAC_NUMBER_APPLICATION
         where PAC_NUMBER_APPLICATION_ID = pSourceNumberApp;
    exception
      when others then
        vDuplicatedNumberApp  := 0;
        raise;
    end;

    pDuplicatedNumberApp  := vDuplicatedNumberApp;   /*Assignation du paramètre de retour */
  end DuplicateEventTypeApplNumber;

  /**
  * Description
  *        Procedure de duplification des codes obligatoires des type d'événement
  */
  procedure DuplicateEventTypeCode(
    pEventType                      PAC_EVENT_TYPE.PAC_EVENT_TYPE_ID%type   /*Type d'événement parent*/
  , pSourceMandatoryCode            PAC_MANDATORY_CODE.PAC_MANDATORY_CODE_ID%type   /*Code obligatoire source*/
  , pDuplicatedMandatoryCode in out PAC_MANDATORY_CODE.PAC_MANDATORY_CODE_ID%type
  )   /*Code obligatoire créé  */
  is
    vDuplicatedMandatoryCode PAC_MANDATORY_CODE.PAC_MANDATORY_CODE_ID%type;   /*Réceptionne l'id du code créé */
  begin
    begin
      /*Réception d'un nouvel Id de Type de lien*/
      select INIT_ID_SEQ.nextval
        into vDuplicatedMandatoryCode
        from dual;

      /* Création de l'enregistrement sur la base du type à duplifier*/
      insert into PAC_MANDATORY_CODE
                  (PAC_MANDATORY_CODE_ID
                 , PAC_EVENT_TYPE_ID
                 , DIC_BOOLEAN_CODE_TYP_ID
                 , DIC_CHAR_CODE_TYP_ID
                 , DIC_NUMBER_CODE_TYP_ID
                 , DIC_DATE_CODE_TYP_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select vDuplicatedMandatoryCode   /* Numérotation      -> Nouvel Id                      */
             , pEventType   /* Type d'événement  -> Initialisé par paramètre       */
             , DIC_BOOLEAN_CODE_TYP_ID   /* Type code booléen -> Initialisé par origine         */
             , DIC_CHAR_CODE_TYP_ID   /* Type code car.    -> Initialisé par origine         */
             , DIC_NUMBER_CODE_TYP_ID   /* Type code num.    -> Initialisé par origine         */
             , DIC_DATE_CODE_TYP_ID   /* Type code date    -> Initialisé par origine         */
             , sysdate   /* Date création     -> Date système                   */
             , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id création       -> user                           */
          from PAC_MANDATORY_CODE
         where PAC_MANDATORY_CODE_ID = pSourceMandatoryCode;
    exception
      when others then
        vDuplicatedMandatoryCode  := 0;
        raise;
    end;

    pDuplicatedMandatoryCode  := vDuplicatedMandatoryCode;   /*Assignation du paramètre de retour */
  end DuplicateEventTypeCode;

  /**
  * Description   Procédure de copie de personnes
  **/
  procedure DuplicatePacPerson(
    pSourceRecordId            PAC_PERSON.PAC_PERSON_ID%type
  , pDuplicateAllChain         number
  , pDuplicatedRecordId in out PAC_PERSON.PAC_PERSON_ID%type
  )
  is
    cursor curAssociationToDuplicate
    is
      select PAC_PERSON_ASSOCIATION_ID
        from PAC_PERSON_ASSOCIATION
       where PAC_PERSON_ID = pSourceRecordId;

    cursor curAddressesToDuplicate
    is
      select PAC_ADDRESS_ID
        from PAC_ADDRESS
       where PAC_PERSON_ID = pSourceRecordId;

    cursor curThirdToDuplicate
    is
      select PAC_THIRD_ID
        from PAC_THIRD
       where PAC_THIRD_ID = pSourceRecordId;

    cursor curPublicationsToDuplicate
    is
      select PAC_THIRD_PUBLICATION_ID
        from PAC_THIRD_PUBLICATION
       where PAC_THIRD_ID = pSourceRecordId;

    cursor curCommToDuplicate(pAddressId PAC_COMMUNICATION.PAC_ADDRESS_ID%type)
    is
      select PAC_COMMUNICATION_ID
        from PAC_COMMUNICATION
       where PAC_PERSON_ID = pSourceRecordId
         and (    (     (not pAddressId is null)
                   and (PAC_ADDRESS_ID = pAddressId) )
              or (     (pAddressId is null)
                  and (PAC_ADDRESS_ID is null) )
             );

    vAssociationId   PAC_PERSON_ASSOCIATION.PAC_PERSON_ASSOCIATION_ID%type;
    vAddressId       PAC_ADDRESS.PAC_ADDRESS_ID%type;   --Réceptionne Id adresse source
    vNewAddLinkId    PAC_ADDRESS.PAC_ADDRESS_ID%type;   --Réceptionne Id adresse créée
    vCommunicationId PAC_COMMUNICATION.PAC_COMMUNICATION_ID%type;
    vThirdId         PAC_THIRD.PAC_THIRD_ID%type;
    vPublicationId   PAC_THIRD_PUBLICATION.PAC_THIRD_PUBLICATION_ID%type;
    vKey1            PAC_PERSON.PER_KEY1%type;
    vKey2            PAC_PERSON.PER_KEY2%type;
  begin
    begin
      /** Réception d'un nouvel Id **/
      select INIT_ID_SEQ.nextval
        into pDuplicatedRecordId
        from dual;

      /** L'appel de la fonction dans la procédure " insert into as select ""
        provoque une exception "...mutation"...aussi on réceptionne les
        nouvelles clés selon nom de la personnne source dans des varaibles
      **/
      select PAC_PARTNER_MANAGEMENT.ExtractKey(PER_SHORT_NAME, 'KEY1')
           , PAC_PARTNER_MANAGEMENT.ExtractKey(PER_SHORT_NAME, 'KEY2')
        into vKey1
           , vKey2
        from PAC_PERSON
       where PAC_PERSON_ID = pSourceRecordId;

      insert into PAC_PERSON
                  (PAC_PERSON_ID
                 , DIC_PERSON_POLITNESS_ID
                 , PER_NAME
                 , PER_SHORT_NAME
                 , PER_FORENAME
                 , PER_ACTIVITY
                 , PER_COMMENT
                 , PER_KEY1
                 , PER_KEY2
                 , PER_CONTACT
                 , C_PARTNER_STATUS
                 , DIC_FREE_CODE1_ID
                 , DIC_FREE_CODE2_ID
                 , DIC_FREE_CODE3_ID
                 , DIC_FREE_CODE4_ID
                 , DIC_FREE_CODE5_ID
                 , DIC_FREE_CODE6_ID
                 , DIC_FREE_CODE7_ID
                 , DIC_FREE_CODE8_ID
                 , DIC_FREE_CODE9_ID
                 , DIC_FREE_CODE10_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select pDuplicatedRecordId   --Nouvel Id
             , DIC_PERSON_POLITNESS_ID
             , PER_NAME
             , PER_SHORT_NAME
             , PER_FORENAME
             , PER_ACTIVITY
             , PER_COMMENT
             , vKey1   --Clé 1 générée
             , vKey2   --Clé 2 générée
             , PER_CONTACT
             , C_PARTNER_STATUS
             , DIC_FREE_CODE1_ID
             , DIC_FREE_CODE2_ID
             , DIC_FREE_CODE3_ID
             , DIC_FREE_CODE4_ID
             , DIC_FREE_CODE5_ID
             , DIC_FREE_CODE6_ID
             , DIC_FREE_CODE7_ID
             , DIC_FREE_CODE8_ID
             , DIC_FREE_CODE9_ID
             , DIC_FREE_CODE10_ID
             , sysdate   --Date système
             , PCS.PC_I_LIB_SESSION.GetUserIni   --User courant
          from PAC_PERSON
         where PAC_PERSON_ID = pSourceRecordId;
    exception
      when others then
        pDuplicatedRecordId  := null;
        raise;
    end;

    if (not pDuplicatedRecordId is null) then
      if pDuplicateAllChain = 1 then   --Copie de toute la chaîne parent- enfant
        begin
          /** Copie des contacts de la personne source  **/
          open curAssociationToDuplicate;

          fetch curAssociationToDuplicate
           into vAssociationId;

          while curAssociationToDuplicate%found loop
            DuplicateAssociationLink(pDuplicatedRecordId,   --Personne
                                     vAssociationId);   --Association source

            fetch curAssociationToDuplicate
             into vAssociationId;
          end loop;

          close curAssociationToDuplicate;

          /** Copie des Adresses de la personne source  **/
          open curAddressesToDuplicate;

          fetch curAddressesToDuplicate
           into vAddressId;

          while curAddressesToDuplicate%found loop
            vNewAddLinkId  := DuplicateAddressLink(pDuplicatedRecordId,   --Personne
                                                   vAddressId);   --Adresse source

            /** Copie des communications liées à la personne et adresse courante **/
            open curCommToDuplicate(vAddressId);

            fetch curCommToDuplicate
             into vCommunicationId;

            while curCommToDuplicate%found loop
              DuplicateCommunicationLink(pDuplicatedRecordId,   --Personne
                                         vNewAddLinkId,   --Adresse
                                         vCommunicationId);   --Communication source

              fetch curCommToDuplicate
               into vCommunicationId;
            end loop;

            close curCommToDuplicate;

            fetch curAddressesToDuplicate
             into vAddressId;
          end loop;

          close curAddressesToDuplicate;

          /** Copie des communications liées à la personne uniquement **/
          open curCommToDuplicate(null);

          fetch curCommToDuplicate
           into vCommunicationId;

          while curCommToDuplicate%found loop
            DuplicateCommunicationLink(pDuplicatedRecordId,   --Personne
                                       null,   --Adresse
                                       vCommunicationId);   --Communication source

            fetch curCommToDuplicate
             into vCommunicationId;
          end loop;

          close curCommToDuplicate;

          /** Copie des données tiers de la personne source  **/
          open curThirdToDuplicate;

          fetch curThirdToDuplicate
           into vThirdId;

          while curThirdToDuplicate%found loop
            DuplicateThirdLink(pDuplicatedRecordId,   --Personne
                               vThirdId);   --Tiers source

            fetch curThirdToDuplicate
             into vThirdId;
          end loop;

          close curThirdToDuplicate;

          /** Copie des données de publications tiers de la personne source  **/
          open curPublicationsToDuplicate;

          fetch curPublicationsToDuplicate
           into vPublicationId;

          while curPublicationsToDuplicate%found loop
            DuplicatePublicationLink(pDuplicatedRecordId,   --Tiers
                                     vPublicationId);   --Publication source

            fetch curPublicationsToDuplicate
             into vPublicationId;
          end loop;

          close curPublicationsToDuplicate;
        exception
          when others then
            raise;
        end;
      end if;
    end if;
  end DuplicatePacPerson;

  procedure DuplicateAssociationLink(
    pLinkedParentId PAC_PERSON.PAC_PERSON_ID%type   -- Personne parente
  , pSourceRecordId PAC_PERSON_ASSOCIATION.PAC_PERSON_ASSOCIATION_ID%type   -- Association source
  )
  is
  begin
    insert into PAC_PERSON_ASSOCIATION
                (PAC_PERSON_ASSOCIATION_ID
               , PAC_PERSON_ID
               , PAC_PAC_PERSON_ID
               , PAS_COMMENT
               , PAS_FUNCTION
               , DIC_ASSOCIATION_TYPE_ID
               , C_PARTNER_STATUS
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   --Nouvel Id
           , pLinkedParentId   --Id Parent
           , PAC_PAC_PERSON_ID
           , PAS_COMMENT
           , PAS_FUNCTION
           , DIC_ASSOCIATION_TYPE_ID
           , C_PARTNER_STATUS
           , sysdate   --Date système
           , PCS.PC_I_LIB_SESSION.GetUserIni   --User courant
        from PAC_PERSON_ASSOCIATION
       where PAC_PERSON_ASSOCIATION_ID = pSourceRecordId;
  end DuplicateAssociationLink;

  function DuplicateAddressLink(
    pLinkedParentId PAC_PERSON.PAC_PERSON_ID%type   -- Personne parente
  , pSourceRecordId PAC_ADDRESS.PAC_ADDRESS_ID%type   -- Adresse source
  )
    return PAC_ADDRESS.PAC_ADDRESS_ID%type
  is
    vResult PAC_ADDRESS.PAC_ADDRESS_ID%type;
  begin
    /** Réception d'un nouvel Id **/
    select INIT_ID_SEQ.nextval
      into vResult
      from dual;

    insert into PAC_ADDRESS
                (PAC_ADDRESS_ID
               , PAC_PERSON_ID
               , PC_CNTRY_ID
               , PC_LANG_ID
               , ADD_ADDRESS1
               , ADD_ZIPCODE
               , ADD_CITY
               , ADD_STATE
               , ADD_COMMENT
               , ADD_SINCE
               , ADD_FORMAT
               , ADD_PRINCIPAL
               , ADD_PRIORITY
               , ADD_CARE_OF
               , ADD_PO_BOX
               , ADD_PO_BOX_NBR
               , ADD_COUNTY
               , DIC_ADDRESS_TYPE_ID
               , C_PARTNER_STATUS
               , A_DATECRE
               , A_IDCRE
                )
      select vResult   --Nouvel Id
           , pLinkedParentId   --Id Parent
           , PC_CNTRY_ID
           , PC_LANG_ID
           , ADD_ADDRESS1
           , ADD_ZIPCODE
           , ADD_CITY
           , ADD_STATE
           , ADD_COMMENT
           , ADD_SINCE
           , ADD_FORMAT
           , ADD_PRINCIPAL
           , ADD_PRIORITY
           , ADD_CARE_OF
           , ADD_PO_BOX
           , ADD_PO_BOX_NBR
           , ADD_COUNTY
           , DIC_ADDRESS_TYPE_ID
           , C_PARTNER_STATUS
           , sysdate   --Date système
           , PCS.PC_I_LIB_SESSION.GetUserIni   --User courant
        from PAC_ADDRESS
       where PAC_ADDRESS_ID = pSourceRecordId;

    return vResult;
  end DuplicateAddressLink;

  procedure DuplicateThirdLink(
    pLinkedParentId PAC_PERSON.PAC_PERSON_ID%type   -- Personne parente
  , pSourceRecordId PAC_THIRD.PAC_THIRD_ID%type   -- Tiers source
  )
  is
  begin
    insert into PAC_THIRD
                (PAC_THIRD_ID
               , PAC_PAC_PERSON_ID
               , THI_NO_TVA
               , THI_NO_INTRA
               , THI_NO_FORMAT
               , THI_NO_SIREN
               , THI_NO_SIRET
               , THI_WEB_KEY
               , THI_CUSTOM_NUMBER
               , DIC_CITI_CODE_ID
               , DIC_JURIDICAL_STATUS_ID
               , DIC_THIRD_ACTIVITY_ID
               , DIC_THIRD_AREA_ID
               , A_DATECRE
               , A_IDCRE
                )
      select pLinkedParentId   --Id parent
           , PAC_PAC_PERSON_ID
           , THI_NO_TVA
           , THI_NO_INTRA
           , THI_NO_FORMAT
           , THI_NO_SIREN
           , THI_NO_SIRET
           , substr('[' || PCS.PC_I_LIB_SESSION.GetUserIni || to_char(sysdate, 'HH24MISS') || ']' || THI_WEB_KEY, 1, 30)
           , THI_CUSTOM_NUMBER
           , DIC_CITI_CODE_ID
           , DIC_JURIDICAL_STATUS_ID
           , DIC_THIRD_ACTIVITY_ID
           , DIC_THIRD_AREA_ID
           , sysdate   --Date système
           , PCS.PC_I_LIB_SESSION.GetUserIni   --User courant
        from PAC_THIRD
       where PAC_THIRD_ID = pSourceRecordId;
  end DuplicateThirdLink;

  procedure DuplicatePublicationLink(
    pLinkedParentId PAC_PERSON.PAC_PERSON_ID%type   -- Tiers parent
  , pSourceRecordId PAC_THIRD.PAC_THIRD_ID%type   -- Publication source
  )
  is
  begin
    insert into PAC_THIRD_PUBLICATION
                (PAC_THIRD_PUBLICATION_ID
               , PAC_THIRD_ID
               , PUB_DATE
               , PUB_PAGE
               , PUB_NUMBER
               , PUB_COMMENT
               , PUB_CAPITAL
               , PUB_TURNOVER
               , PUB_AMOUNT1
               , PUB_AMOUNT2
               , PUB_TEXT1
               , PUB_TEXT2
               , DIC_PUBLICATION_TYPE_ID
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   --Nouvel Id
           , pLinkedParentId   --Id Parent
           , PUB_DATE
           , PUB_PAGE
           , PUB_NUMBER
           , PUB_COMMENT
           , PUB_CAPITAL
           , PUB_TURNOVER
           , PUB_AMOUNT1
           , PUB_AMOUNT2
           , PUB_TEXT1
           , PUB_TEXT2
           , DIC_PUBLICATION_TYPE_ID
           , sysdate   --Date système
           , PCS.PC_I_LIB_SESSION.GetUserIni   --User courant
        from PAC_THIRD_PUBLICATION
       where PAC_THIRD_PUBLICATION_ID = pSourceRecordId;
  end DuplicatePublicationLink;

  procedure DuplicateCommunicationLink(
    pLinkedParentId PAC_PERSON.PAC_PERSON_ID%type   -- Personne parente
  , pAddressLinkId  PAC_COMMUNICATION.PAC_ADDRESS_ID%type   -- Adresse liée
  , pSourceRecordId PAC_COMMUNICATION.PAC_COMMUNICATION_ID%type   -- Communication source
  )
  is
  begin
    insert into PAC_COMMUNICATION
                (PAC_COMMUNICATION_ID
               , PAC_PERSON_ID
               , PAC_ADDRESS_ID
               , COM_EXT_NUMBER
               , COM_INT_NUMBER
               , COM_AREA_CODE
               , COM_COMMENT
               , COM_INTERNATIONAL_NUMBER
               , DIC_COMMUNICATION_TYPE_ID
               , A_DATECRE
               , A_IDCRE
                )
      select INIT_ID_SEQ.nextval   --Nouvel Id
           , pLinkedParentId   --Id Parent
           , pAddressLinkId   --Adresse liée
           , COM_EXT_NUMBER
           , COM_INT_NUMBER
           , COM_AREA_CODE
           , COM_COMMENT
           , COM_INTERNATIONAL_NUMBER
           , DIC_COMMUNICATION_TYPE_ID
           , sysdate   --Date système
           , PCS.PC_I_LIB_SESSION.GetUserIni   --User courant
        from PAC_COMMUNICATION
       where PAC_COMMUNICATION_ID = pSourceRecordId;
  end DuplicateCommunicationLink;

  /**
  * Description   Procedure de copie des conditions de paiement
  **/
  procedure DuplicatePaymentCondition(
    pSourceRecordId           PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type   -- Condition parente
  , pSourceDescription        PAC_PAYMENT_CONDITION.PCO_DESCR%type   --Descriptif source
  , pDuplicateAllChain        number   --Duplifier toute la chaîne
  , pDuplicatedId      in out PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type   -- Condition créée
  )
  is
    --Curseur de recheche des détails de condition de paiement
    cursor curConditionDetails(pSourceRecordId PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type)
    is
      select *
        from PAC_CONDITION_DETAIL
       where PAC_PAYMENT_CONDITION_ID = pSourceRecordId;

    vDuplicatedConditionId PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type;   --Réceptionne l'id du type créé
    vDuplicatedDetailId    PAC_CONDITION_DETAIL.PAC_CONDITION_DETAIL_ID%type;   --Réceptionne id détail créé
    vConditionDetails      curConditionDetails%rowtype;   --Réceptionne les données du curseur
    vSourceDescription     PAC_PAYMENT_CONDITION.PCO_DESCR%type;   --Descriptif source
    vDescriptionPosCpt     number;   --Position du [ dans le descriptif indiquant la "version" duplifiée...
                                     --...et accessoirement réceptionne le compteur de version
    vDuplicatedDate varchar2(20); --' [DD.MM.YYYY-vDescriptionPosCpt]'
  begin
    begin
      --Réception d'un nouvel Id de Type de lien
      select INIT_ID_SEQ.nextval
        into vDuplicatedConditionId
        from dual;

      select instr(pSourceDescription, '' || '[' || '')   --Réception du numéro de version
        into vDescriptionPosCpt
        from dual;

      if vDescriptionPosCpt > 0 then   --La condition courante est une condition déjà duplifiée
        select trim(substr(pSourceDescription, 1, vDescriptionPosCpt -1))   --Réception de la "Racine" du descriptif sans la date de copie
          into vSourceDescription
          from dual;
      else
        vSourceDescription  := trim(pSourceDescription);
      end if;

      select count(*) + 1   --Recherche du nombre de version dont le descriptif = "Racine" ...
        into vDescriptionPosCpt   --...du descriptif
        from PAC_PAYMENT_CONDITION
       where PCO_DESCR like vSourceDescription || '%';

      vDuplicatedDate := ' [' || to_char(trunc(sysdate), 'DD.MM.YYYY') || '-' || to_char(vDescriptionPosCpt) || ']';

      -- Formatage du descriptif du nouveau type
      vSourceDescription  :=
        substr(vSourceDescription
             , 1
             , 50 - length(vDuplicatedDate)
              ) || vDuplicatedDate;

      /* Création de l'enregistrement sur la base du type à duplifier*/
      insert into PAC_PAYMENT_CONDITION
                  (PAC_PAYMENT_CONDITION_ID
                 , PC_APPLTXT_ID
                 , PCO_DESCR
                 , PCO_DEFAULT
                 , PCO_DEFAULT_PAY
                 , C_DIRECT_PAY
                 , PCO_ONLY_AMOUNT_BILL_BOOK
                 , PCO_CUST_TOLERANCE
                 , C_VALID
                 , C_PARTNER_STATUS
                 , C_PAYMENT_CONDITION_KIND
                 , C_INVOICE_EXPIRY_INPUT_TYPE
                 , DIC_CONDITION_TYP_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select vDuplicatedConditionId   /* Condition de paiement  -> Nouvel Id                 */
             , PC_APPLTXT_ID
             , vSourceDescription   /* Descriptif             -> Initialisé par paramètre  */
             , 0
             , 0
             , C_DIRECT_PAY
             , PCO_ONLY_AMOUNT_BILL_BOOK
             , PCO_CUST_TOLERANCE
             , C_VALID
             , C_PARTNER_STATUS
             , C_PAYMENT_CONDITION_KIND
             , C_INVOICE_EXPIRY_INPUT_TYPE
             , DIC_CONDITION_TYP_ID
             , sysdate   /* Date création      -> Date système                   */
             , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id création        -> user                           */
          from PAC_PAYMENT_CONDITION
         where PAC_PAYMENT_CONDITION_ID = pSourceRecordId;

      /*Duplification de toute la chaîne parent- enfant */
      if pDuplicateAllChain = 1 then
        /*Parcours des détails de la condition courante à copier              */
        /*Chaque détail est copiée et est rattachée à la condition cible      */
        open curConditionDetails(pSourceRecordId);

        fetch curConditionDetails
         into vConditionDetails;

        while curConditionDetails%found loop
          DuplicateConditionDetails(vDuplicatedConditionId
                                  ,   /*Type parent             */
                                    vConditionDetails.PAC_CONDITION_DETAIL_ID
                                  ,   /*Lien automatique source */
                                    vDuplicatedDetailId   /*Détail créé             */
                                   );

          fetch curConditionDetails
           into vConditionDetails;
        end loop;

        close curConditionDetails;
      end if;
    exception
      when others then
        vDuplicatedConditionId  := 0;
        raise;
    end;

    pDuplicatedId  := vDuplicatedConditionId;   /*Assignation du paramètre de retour*/
  end DuplicatePaymentCondition;

  /**
  * Description   Procedure de copie des détails de conditions de paiement
  **/
  procedure DuplicateConditionDetails(
    pLinkedParentId        PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type   -- Condition parente
  , pSourceRecordId        PAC_CONDITION_DETAIL.PAC_CONDITION_DETAIL_ID%type   -- Détail parente
  , pDuplicatedId   in out PAC_CONDITION_DETAIL.PAC_CONDITION_DETAIL_ID%type   --Détail créé
  )
  is
    vDuplicatedId PAC_CONDITION_DETAIL.PAC_CONDITION_DETAIL_ID%type;   --Réceptionne l'id du lien automatique créé
  begin
    begin
      /*Réception d'un nouvel Id de détail*/
      select INIT_ID_SEQ.nextval
        into vDuplicatedId
        from dual;

      /* Création de l'enregistrement sur la base du détail à copier*/
      insert into PAC_CONDITION_DETAIL
                  (PAC_CONDITION_DETAIL_ID
                 , PAC_PAYMENT_CONDITION_ID
                 , PAC_PAC_PAYMENT_CONDITION_ID
                 , GCO_GOOD_ID
                 , DOC_GAUGE_ID
                 , CDE_DAY
                 , CDE_PART
                 , CDE_ACCOUNT
                 , CDE_DISCOUNT_RATE
                 , CDE_END_MONTH
                 , CDE_ROUND_AMOUNT
                 , CDE_AMOUNT_LC
                 , C_CALC_METHOD
                 , C_TIME_UNIT
                 , C_INVOICE_EXPIRY_DOC_TYPE
                 , C_ROUND_TYPE
                 , A_DATECRE
                 , A_IDCRE
                  )
        select vDuplicatedId   /* Détail de condition-> Nouvel Id                      */
             , pLinkedParentId   /* Condition parente                                    */
             , PAC_PAC_PAYMENT_CONDITION_ID
             , GCO_GOOD_ID
             , DOC_GAUGE_ID
             , CDE_DAY
             , CDE_PART
             , CDE_ACCOUNT
             , CDE_DISCOUNT_RATE
             , CDE_END_MONTH
             , CDE_ROUND_AMOUNT
             , CDE_AMOUNT_LC
             , C_CALC_METHOD
             , C_TIME_UNIT
             , C_INVOICE_EXPIRY_DOC_TYPE
             , C_ROUND_TYPE
             , sysdate   /* Date création      -> Date système                   */
             , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id création        -> user                           */
          from PAC_CONDITION_DETAIL
         where PAC_CONDITION_DETAIL_ID = pSourceRecordId;
    exception
      when others then
        vDuplicatedId  := 0;
        raise;
    end;

    pDuplicatedId  := vDuplicatedId;   /*Assignation du paramètre de retour */
  end DuplicateConditionDetails;

  /**
  * Description   Procedure de copie d'une adresse
  */
  procedure DuplicatePacAddress(
    pSourceRecordId            PAC_ADDRESS.PAC_ADDRESS_ID%type
  , pDuplicatedRecordId in out PAC_ADDRESS.PAC_ADDRESS_ID%type
  )
  is
  begin
    /** Réception d'un nouvel Id **/
    select INIT_ID_SEQ.nextval
      into pDuplicatedRecordId
      from dual;

    insert into PAC_ADDRESS
                (PAC_ADDRESS_ID
               , PAC_PERSON_ID
               , PC_CNTRY_ID
               , PC_LANG_ID
               , ADD_ADDRESS1
               , ADD_ZIPCODE
               , ADD_CITY
               , ADD_STATE
               , ADD_COMMENT
               , ADD_SINCE
               , ADD_FORMAT
               , ADD_PRINCIPAL
               , ADD_PRIORITY
               , ADD_CARE_OF
               , ADD_PO_BOX
               , ADD_PO_BOX_NBR
               , ADD_COUNTY
               , DIC_ADDRESS_TYPE_ID
               , C_PARTNER_STATUS
               , A_DATECRE
               , A_IDCRE
                )
      select pDuplicatedRecordId   --Nouvel Id
           , PAC_PERSON_ID
           , PC_CNTRY_ID
           , PC_LANG_ID
           , ADD_ADDRESS1
           , ADD_ZIPCODE
           , ADD_CITY
           , ADD_STATE
           , ADD_COMMENT
           , ADD_SINCE
           , ADD_FORMAT
           , 0   -- ne peut pas être 'principale'
           , ADD_PRIORITY
           , ADD_CARE_OF
           , ADD_PO_BOX
           , ADD_PO_BOX_NBR
           , ADD_COUNTY
           , DIC_ADDRESS_TYPE_ID
           , C_PARTNER_STATUS
           , sysdate   --Date système
           , PCS.PC_I_LIB_SESSION.GetUserIni   --User courant
        from PAC_ADDRESS
       where PAC_ADDRESS_ID = pSourceRecordId;
  end DuplicatePacAddress;
end PAC_DUPLICATE;
