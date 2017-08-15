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
    pSourceLinkType            PAC_LINK_TYP.PAC_LINK_TYP_ID%type   /*Type source � duplifier   */
  , pSourceLinkDescr           PAC_LINK_TYP.TLI_DESCR%type   /*Descriptif source         */
  , pDuplicateAllChain         number   /*Duplifier toute la cha�ne */
  , pDuplicatedLinkType in out PAC_LINK_TYP.PAC_LINK_TYP_ID%type
  )
  is
    --Curseur de recheche des liens automatiques du type source
    cursor TypeAutomaticLink(pSourceLinkType PAC_LINK_TYP.PAC_LINK_TYP_ID%type)
    is
      select *
        from PAC_AUTOMATIC_LINK
       where PAC_LINK_TYP_ID = pSourceLinkType;

    vDuplicatedLinkType PAC_LINK_TYP.PAC_LINK_TYP_ID%type;   /*R�ceptionne l'id du type cr��             */
    vAutomaticLink      TypeAutomaticLink%rowtype;   /*R�ceptionne les donn�es du curseur        */
    vDuplicatedAutoLink PAC_AUTOMATIC_LINK.PAC_AUTOMATIC_LINK_ID%type;   /*R�ceptionne l'id du lien automatique cr�� */
    vLinkDescr          PAC_LINK_TYP.TLI_DESCR%type;   /*Descriptif format� cible                  */
    vVersionPosCpt      number;   /* Position du [ dans le descriptif indiquant la "version" duplifi�e */
                                  /* et accessoirement r�ceptionne le compteur de version              */
  begin
    begin
      --R�ception d'un nouvel Id de Type de lien
      select INIT_ID_SEQ.nextval
        into vDuplicatedLinkType
        from dual;

      select instr(pSourceLinkDescr, '' || '[' || '')   --R�ception du num�ro de version
        into vVersionPosCpt
        from dual;

      vLinkDescr  := pSourceLinkDescr;

      if vVersionPosCpt > 0 then   --Le type courant est un type d�j� duplifi�
        select substr(pSourceLinkDescr, 1, vVersionPosCpt + 1)   --R�ception de la "Racine" du descriptif
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

      /* Cr�ation de l'enregistrement sur la base du type � duplifier*/
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
             , vLinkDescr   /* Descriptif         -> Initialis� par param�tre       */
             , TLI_PATH   /* Chemin par d�faut  -> Initialis� par origine         */
             , TLI_EXT   /* Extension          -> Initialis� par origine         */
             , C_LINK_TYP   /* Type de lien       -> Initialis� par origine         */
             , C_UTILITY_MODE   /* Mode utilitaire externe -> Initialis� par origine    */
             , C_ADDRESSING_TYP   /* Adressage          -> Initialis� par origine         */
             , TLI_SOURCE_FILE   /* Fichier source     -> Initialis� par origine         */
             , TLI_TEXT_INCLUDE   /* Inclusion du text  -> Initialis� par origine         */
             , TLI_FOLDER   /* Dossier Outlook    -> Initialis� par origine         */
             , TLI_FOLDER_ENTRYID   /* FolderEntry        -> Initialis� par origine         */
             , TLI_FOLDER_STOREID   /* StoreId            -> Initialis� par origine         */
             , sysdate   /* Date cr�ation      -> Date syst�me                   */
             , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id cr�ation        -> user                           */
          from PAC_LINK_TYP
         where PAC_LINK_TYP_ID = pSourceLinkType;

      /*Duplification de toute la cha�ne parent- enfant */
      if pDuplicateAllChain = 1 then
        /*Parcours des liens automatiques du type courant � duplifier        */
        /*Chaque lien automatique est duplifi� et est rattach� au type cible */
        open TypeAutomaticLink(pSourceLinkType);

        fetch TypeAutomaticLink
         into vAutomaticLink;

        while TypeAutomaticLink%found loop
          DuplicateAutomaticLink(vDuplicatedLinkType
                               ,   /*Type parent             */
                                 vAutomaticLink.PAC_AUTOMATIC_LINK_ID
                               ,   /*Lien automatique source */
                                 vDuplicatedAutoLink   /* Lien automatique cr��  */
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

    pDuplicatedLinkType  := vDuplicatedLinkType;   /*Assignation du param�tre de retour*/
  end DuplicateLinkType;

  /**
  * Description
  *        Fonction de duplification des types d'�v�nements
  */
  procedure DuplicateEventType(
    pSourceEventType            PAC_EVENT_TYPE.PAC_EVENT_TYPE_ID%type   /*Type source � duplifier   */
  , pDuplicateAllChain          number   /*Duplifier toute la cha�ne */
  , pDuplicatedEventType in out PAC_EVENT_TYPE.PAC_EVENT_TYPE_ID%type
  )
  is
    --Curseur de recheche des m�thode de num�rotation
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

    vEvtTypeDescr             PAC_EVENT_TYPE.TYP_DESCRIPTION%type;   /*R�ception description racine*/
    vDuplicatedEventType      PAC_EVENT_TYPE.PAC_EVENT_TYPE_ID%type;   /*R�ceptionne le nouvel id cr��                                      */
    vMandatoryCode            EventTypeMandatoryCode%rowtype;   /*R�ceptionne les donn�es du curseur sur les codes obligatoires      */
    vAutomaticLink            TypeAutomaticLink%rowtype;   /*R�ceptionne les donn�es du curseur sur les liens automatiques      */
    vApplicationNumber        EventTypeApplicationNumber%rowtype;   /*R�ceptionne les donn�es du curseur sur les num�rotations           */
    vDuplicatedAutoLink       PAC_AUTOMATIC_LINK.PAC_AUTOMATIC_LINK_ID%type;   /*R�ceptionne l'id du lien cr�� par duplification         */
    vDuplicatedMandatoryCode  PAC_MANDATORY_CODE.PAC_MANDATORY_CODE_ID%type;   /*R�ceptionne l'id du code cr��par duplification          */
    vDuplicatedApplicationNum PAC_NUMBER_APPLICATION.PAC_NUMBER_APPLICATION_ID%type;   /*R�ceptionne l'id de num�rotation cr�� par duplification */
  begin
    begin
      --R�ception d'un nouvel Id de Type d'�v�nement
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

      /* Cr�ation de l'enregistrement sur la base du type � copier */
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
        select vDuplicatedEventType   /* Type d'�v�nement   -> Nouvel Id                      */
             , TYP_SHORT_DESCRIPTION   /* Descriptif abbr�g� -> Initialis� par param�tre       */
             , vEvtTypeDescr
             , TYP_EVENT_AVAILABLE   /* Disponible         -> Initialis� par origine         */
             , TYP_ENDDATE_MANAGEMENT   /* Gestion date fin   -> Initialis� par origine         */
             , TYP_REMDATE_MANAGEMENT   /* Getsion date rappel-> Initialis� par origine         */
             , TYP_PAC_PERSON_LINK   /* Lien parsonne      -> Initialis� par origine         */
             , TYP_DOC_RECORD_LINK   /* Lien dossier       -> Initialis� par origine         */
             , TYP_GCO_GOOD_LINK   /* Lien bien          -> Initialis� par origine         */
             , TYP_DOC_DOCUMENT_LINK   /* Lien document      -> Initialis� par origine         */
             , TYP_CML_POSITION_LINK   /* Lien pos. contrat  -> Initialis� par origine         */
             , TYP_FAM_ASSETS_LINK   /* Lien Immo          -> Initialis� par origine         */
             , TYP_ACT_DOCUMENT_LINK   /* Lien Doc finance   -> Initialis� par origine         */
             , TYP_ASA_GUARANTY_LINK   /* Lien carte garantie-> Initialis� par origine         */
             , TYP_ASA_RECORD_LINK   /* Lien SAV           -> Initialis� par origine         */
             , TYP_REGROUP_FREE_CODE   /* Code libre regroup�-> Initialis� par origine         */
             , DIC_EVENT_DOMAIN_ID   /* Domaine            -> Initialis� par origine         */
             , DIC_EVENT_TYPE_GROUP_ID   /* Groupe             -> Initialis� par origine         */
             , C_PAC_CONFIG   /* Config PAC         -> Initialis� par origine         */
             , C_EVENT_DATE_FORMAT   /* Format date        -> Initialis� par origine         */
             , C_END_EVENT_DATE_FORMAT   /* Format date fin    -> Initialis� par origine         */
             , C_REM_EVENT_DATE_FORMAT   /* Format date rappel -> Initialis� par origine         */
             , sysdate   /* Date cr�ation      -> Date syst�me                   */
             , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id cr�ation        -> user                           */
          from PAC_EVENT_TYPE
         where PAC_EVENT_TYPE_ID = pSourceEventType;

      -- Descriptions et textes par d�faut multi-langue
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

      /*Duplification de toute la cha�ne parent- enfant */
      if pDuplicateAllChain = 1 then
        /*Parcours des num�rotations du type d'�v�nement courant                                */
        /*Chaque m�thode de num�rotation est duplifi� et est rattach� au type d'�v�nement cible */
        open EventTypeApplicationNumber(pSourceEventType);

        fetch EventTypeApplicationNumber
         into vApplicationNumber;

        while EventTypeApplicationNumber%found loop
          DuplicateEventTypeApplNumber(vDuplicatedEventType
                                     ,   /*Type d'�v�nement parent  */
                                       vApplicationNumber.PAC_NUMBER_APPLICATION_ID
                                     ,   /*Num�rotation source      */
                                       vDuplicatedApplicationNum   /*Num�rotation cr��        */
                                      );

          fetch EventTypeApplicationNumber
           into vApplicationNumber;
        end loop;

        close EventTypeApplicationNumber;

        /*Parcours des codes obligatoires du type d'�v�nement courant                    */
        /*Chaque code obligatoire est duplifi� et est rattach� au type d'�v�nement cible */
        open EventTypeMandatoryCode(pSourceEventType);

        fetch EventTypeMandatoryCode
         into vMandatoryCode;

        while EventTypeMandatoryCode%found loop
          DuplicateEventTypeCode(vDuplicatedEventType
                               ,   /*Type d'�v�nement parent  */
                                 vMandatoryCode.PAC_MANDATORY_CODE_ID
                               ,   /*Code obligatoire source  */
                                 vDuplicatedMandatoryCode   /*Code obligatoire cr��    */
                                );

          fetch EventTypeMandatoryCode
           into vMandatoryCode;
        end loop;

        close EventTypeMandatoryCode;

        /*Parcours des liens automatiques du type courant � duplifier        */
        /*Chaque lien automatique est duplifi� et est rattach� au type cible */
        open TypeAutomaticLink(pSourceEventType);

        fetch TypeAutomaticLink
         into vAutomaticLink;

        while TypeAutomaticLink%found loop
          DuplicateEventTypeAutoLink(vDuplicatedEventType
                                   ,   /*Type d'�v�nement parent */
                                     vAutomaticLink.PAC_AUTOMATIC_LINK_ID
                                   ,   /*Lien automatique source */
                                     vDuplicatedAutoLink   /* Lien automatique cr��  */
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

    pDuplicatedEventType  := vDuplicatedEventType;   /*Assignation du param�tre de retour*/
  end DuplicateEventType;

  /**
  * Description
  *        Procedure de duplification des liens automatiques d'un type de lien
  */
  procedure DuplicateAutomaticLink(
    pLinkType                   PAC_LINK_TYP.PAC_LINK_TYP_ID%type   /*Type parent             */
  , pSourceAutomaticLink        PAC_AUTOMATIC_LINK.PAC_AUTOMATIC_LINK_ID%type   /*Lien automatique source */
  , pDuplicatedAutoLink  in out PAC_AUTOMATIC_LINK.PAC_AUTOMATIC_LINK_ID%type
  )   /* Lien automatique cr��  */
  is
    vDuplicatedAutoLink PAC_AUTOMATIC_LINK.PAC_AUTOMATIC_LINK_ID%type;   /*R�ceptionne l'id du lien automatique cr�� */
  begin
    begin
      /*R�ception d'un nouvel Id de Type de lien*/
      select INIT_ID_SEQ.nextval
        into vDuplicatedAutoLink
        from dual;

      /* Cr�ation de l'enregistrement sur la base du type � duplifier*/
      insert into PAC_AUTOMATIC_LINK
                  (PAC_AUTOMATIC_LINK_ID
                 , PAC_EVENT_TYPE_ID
                 , PAC_LINK_TYP_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select vDuplicatedAutoLink   /* Lien automatique   -> Nouvel Id                      */
             , PAC_EVENT_TYPE_ID   /* Type d'�v�nement   -> Initialis� par origine         */
             , pLinkType   /* Type de lien       -> Initialis� par param�tre       */
             , sysdate   /* Date cr�ation      -> Date syst�me                   */
             , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id cr�ation        -> user                           */
          from PAC_AUTOMATIC_LINK
         where PAC_AUTOMATIC_LINK_ID = pSourceAutomaticLink;
    exception
      when others then
        vDuplicatedAutoLink  := 0;
        raise;
    end;

    pDuplicatedAutoLink  := vDuplicatedAutoLink;   /*Assignation du param�tre de retour */
  end DuplicateAutomaticLink;

  /**
  * Description
  *        Procedure de duplification des liens automatiques d'un type d'�v�nement
  */
  procedure DuplicateEventTypeAutoLink(
    pEventType                  PAC_EVENT_TYPE.PAC_EVENT_TYPE_ID%type   /*Type d'�v�nement parent */
  , pSourceAutomaticLink        PAC_AUTOMATIC_LINK.PAC_AUTOMATIC_LINK_ID%type   /*Lien automatique source */
  , pDuplicatedAutoLink  in out PAC_AUTOMATIC_LINK.PAC_AUTOMATIC_LINK_ID%type
  )   /* Lien automatique cr��  */
  is
    vDuplicatedAutoLink PAC_AUTOMATIC_LINK.PAC_AUTOMATIC_LINK_ID%type;   /*R�ceptionne l'id du lien automatique cr�� */
  begin
    begin
      /*R�ception d'un nouvel Id de Type de lien*/
      select INIT_ID_SEQ.nextval
        into vDuplicatedAutoLink
        from dual;

      /* Cr�ation de l'enregistrement sur la base du type � duplifier*/
      insert into PAC_AUTOMATIC_LINK
                  (PAC_AUTOMATIC_LINK_ID
                 , PAC_EVENT_TYPE_ID
                 , PAC_LINK_TYP_ID
                 , A_DATECRE
                 , A_IDCRE
                  )
        select vDuplicatedAutoLink   /* Lien automatique   -> Nouvel Id                      */
             , pEventType   /* Type d'�v�nement   -> Initialis� par param�tre       */
             , PAC_LINK_TYP_ID   /* Type de lien       -> Initialis� par origine         */
             , sysdate   /* Date cr�ation      -> Date syst�me                   */
             , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id cr�ation        -> user                           */
          from PAC_AUTOMATIC_LINK
         where PAC_AUTOMATIC_LINK_ID = pSourceAutomaticLink;
    exception
      when others then
        vDuplicatedAutoLink  := 0;
        raise;
    end;

    pDuplicatedAutoLink  := vDuplicatedAutoLink;   /*Assignation du param�tre de retour */
  end DuplicateEventTypeAutoLink;

  /**
  * Description
  *        Procedure de duplification des m�thode de num�rotation
  */
  procedure DuplicateEventTypeApplNumber(
    pEventType                  PAC_EVENT_TYPE.PAC_EVENT_TYPE_ID%type   /*Type d'�v�nement parent       */
  , pSourceNumberApp            PAC_NUMBER_APPLICATION.PAC_NUMBER_APPLICATION_ID%type   /*M�thode de num�rotation source*/
  , pDuplicatedNumberApp in out PAC_NUMBER_APPLICATION.PAC_NUMBER_APPLICATION_ID%type
  )   /*M�thdoe de num�rotation cr��  */
  is
    vDuplicatedNumberApp PAC_NUMBER_APPLICATION.PAC_NUMBER_APPLICATION_ID%type;   /*R�ceptionne l'id de la num�rotation cr��e */
  begin
    begin
      /*R�ception d'un nouvel Id de Type de lien*/
      select INIT_ID_SEQ.nextval
        into vDuplicatedNumberApp
        from dual;

      /* Cr�ation de l'enregistrement sur la base du type � duplifier*/
      insert into PAC_NUMBER_APPLICATION
                  (PAC_NUMBER_APPLICATION_ID
                 , PAC_EVENT_TYPE_ID
                 , PAC_NUMBER_METHOD_ID
                 , NUA_SINCE
                 , NUA_TO
                 , A_DATECRE
                 , A_IDCRE
                  )
        select vDuplicatedNumberApp   /* Num�rotation      -> Nouvel Id                      */
             , pEventType   /* Type d'�v�nement  -> Initialis� par param�tre       */
             , PAC_NUMBER_METHOD_ID   /* M�thode de num.   -> Initialis� par origine         */
             , NUA_SINCE   /* Depuis            -> Initialis� par origine         */
             , NUA_TO   /* Jusqu'au          -> Initialis� par origine         */
             , sysdate   /* Date cr�ation      -> Date syst�me                   */
             , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id cr�ation        -> user                           */
          from PAC_NUMBER_APPLICATION
         where PAC_NUMBER_APPLICATION_ID = pSourceNumberApp;
    exception
      when others then
        vDuplicatedNumberApp  := 0;
        raise;
    end;

    pDuplicatedNumberApp  := vDuplicatedNumberApp;   /*Assignation du param�tre de retour */
  end DuplicateEventTypeApplNumber;

  /**
  * Description
  *        Procedure de duplification des codes obligatoires des type d'�v�nement
  */
  procedure DuplicateEventTypeCode(
    pEventType                      PAC_EVENT_TYPE.PAC_EVENT_TYPE_ID%type   /*Type d'�v�nement parent*/
  , pSourceMandatoryCode            PAC_MANDATORY_CODE.PAC_MANDATORY_CODE_ID%type   /*Code obligatoire source*/
  , pDuplicatedMandatoryCode in out PAC_MANDATORY_CODE.PAC_MANDATORY_CODE_ID%type
  )   /*Code obligatoire cr��  */
  is
    vDuplicatedMandatoryCode PAC_MANDATORY_CODE.PAC_MANDATORY_CODE_ID%type;   /*R�ceptionne l'id du code cr�� */
  begin
    begin
      /*R�ception d'un nouvel Id de Type de lien*/
      select INIT_ID_SEQ.nextval
        into vDuplicatedMandatoryCode
        from dual;

      /* Cr�ation de l'enregistrement sur la base du type � duplifier*/
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
        select vDuplicatedMandatoryCode   /* Num�rotation      -> Nouvel Id                      */
             , pEventType   /* Type d'�v�nement  -> Initialis� par param�tre       */
             , DIC_BOOLEAN_CODE_TYP_ID   /* Type code bool�en -> Initialis� par origine         */
             , DIC_CHAR_CODE_TYP_ID   /* Type code car.    -> Initialis� par origine         */
             , DIC_NUMBER_CODE_TYP_ID   /* Type code num.    -> Initialis� par origine         */
             , DIC_DATE_CODE_TYP_ID   /* Type code date    -> Initialis� par origine         */
             , sysdate   /* Date cr�ation     -> Date syst�me                   */
             , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id cr�ation       -> user                           */
          from PAC_MANDATORY_CODE
         where PAC_MANDATORY_CODE_ID = pSourceMandatoryCode;
    exception
      when others then
        vDuplicatedMandatoryCode  := 0;
        raise;
    end;

    pDuplicatedMandatoryCode  := vDuplicatedMandatoryCode;   /*Assignation du param�tre de retour */
  end DuplicateEventTypeCode;

  /**
  * Description   Proc�dure de copie de personnes
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
    vAddressId       PAC_ADDRESS.PAC_ADDRESS_ID%type;   --R�ceptionne Id adresse source
    vNewAddLinkId    PAC_ADDRESS.PAC_ADDRESS_ID%type;   --R�ceptionne Id adresse cr��e
    vCommunicationId PAC_COMMUNICATION.PAC_COMMUNICATION_ID%type;
    vThirdId         PAC_THIRD.PAC_THIRD_ID%type;
    vPublicationId   PAC_THIRD_PUBLICATION.PAC_THIRD_PUBLICATION_ID%type;
    vKey1            PAC_PERSON.PER_KEY1%type;
    vKey2            PAC_PERSON.PER_KEY2%type;
  begin
    begin
      /** R�ception d'un nouvel Id **/
      select INIT_ID_SEQ.nextval
        into pDuplicatedRecordId
        from dual;

      /** L'appel de la fonction dans la proc�dure " insert into as select ""
        provoque une exception "...mutation"...aussi on r�ceptionne les
        nouvelles cl�s selon nom de la personnne source dans des varaibles
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
             , vKey1   --Cl� 1 g�n�r�e
             , vKey2   --Cl� 2 g�n�r�e
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
             , sysdate   --Date syst�me
             , PCS.PC_I_LIB_SESSION.GetUserIni   --User courant
          from PAC_PERSON
         where PAC_PERSON_ID = pSourceRecordId;
    exception
      when others then
        pDuplicatedRecordId  := null;
        raise;
    end;

    if (not pDuplicatedRecordId is null) then
      if pDuplicateAllChain = 1 then   --Copie de toute la cha�ne parent- enfant
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

            /** Copie des communications li�es � la personne et adresse courante **/
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

          /** Copie des communications li�es � la personne uniquement **/
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

          /** Copie des donn�es tiers de la personne source  **/
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

          /** Copie des donn�es de publications tiers de la personne source  **/
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
           , sysdate   --Date syst�me
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
    /** R�ception d'un nouvel Id **/
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
           , sysdate   --Date syst�me
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
           , sysdate   --Date syst�me
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
           , sysdate   --Date syst�me
           , PCS.PC_I_LIB_SESSION.GetUserIni   --User courant
        from PAC_THIRD_PUBLICATION
       where PAC_THIRD_PUBLICATION_ID = pSourceRecordId;
  end DuplicatePublicationLink;

  procedure DuplicateCommunicationLink(
    pLinkedParentId PAC_PERSON.PAC_PERSON_ID%type   -- Personne parente
  , pAddressLinkId  PAC_COMMUNICATION.PAC_ADDRESS_ID%type   -- Adresse li�e
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
           , pAddressLinkId   --Adresse li�e
           , COM_EXT_NUMBER
           , COM_INT_NUMBER
           , COM_AREA_CODE
           , COM_COMMENT
           , COM_INTERNATIONAL_NUMBER
           , DIC_COMMUNICATION_TYPE_ID
           , sysdate   --Date syst�me
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
  , pDuplicateAllChain        number   --Duplifier toute la cha�ne
  , pDuplicatedId      in out PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type   -- Condition cr��e
  )
  is
    --Curseur de recheche des d�tails de condition de paiement
    cursor curConditionDetails(pSourceRecordId PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type)
    is
      select *
        from PAC_CONDITION_DETAIL
       where PAC_PAYMENT_CONDITION_ID = pSourceRecordId;

    vDuplicatedConditionId PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type;   --R�ceptionne l'id du type cr��
    vDuplicatedDetailId    PAC_CONDITION_DETAIL.PAC_CONDITION_DETAIL_ID%type;   --R�ceptionne id d�tail cr��
    vConditionDetails      curConditionDetails%rowtype;   --R�ceptionne les donn�es du curseur
    vSourceDescription     PAC_PAYMENT_CONDITION.PCO_DESCR%type;   --Descriptif source
    vDescriptionPosCpt     number;   --Position du [ dans le descriptif indiquant la "version" duplifi�e...
                                     --...et accessoirement r�ceptionne le compteur de version
    vDuplicatedDate varchar2(20); --' [DD.MM.YYYY-vDescriptionPosCpt]'
  begin
    begin
      --R�ception d'un nouvel Id de Type de lien
      select INIT_ID_SEQ.nextval
        into vDuplicatedConditionId
        from dual;

      select instr(pSourceDescription, '' || '[' || '')   --R�ception du num�ro de version
        into vDescriptionPosCpt
        from dual;

      if vDescriptionPosCpt > 0 then   --La condition courante est une condition d�j� duplifi�e
        select trim(substr(pSourceDescription, 1, vDescriptionPosCpt -1))   --R�ception de la "Racine" du descriptif sans la date de copie
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

      /* Cr�ation de l'enregistrement sur la base du type � duplifier*/
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
             , vSourceDescription   /* Descriptif             -> Initialis� par param�tre  */
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
             , sysdate   /* Date cr�ation      -> Date syst�me                   */
             , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id cr�ation        -> user                           */
          from PAC_PAYMENT_CONDITION
         where PAC_PAYMENT_CONDITION_ID = pSourceRecordId;

      /*Duplification de toute la cha�ne parent- enfant */
      if pDuplicateAllChain = 1 then
        /*Parcours des d�tails de la condition courante � copier              */
        /*Chaque d�tail est copi�e et est rattach�e � la condition cible      */
        open curConditionDetails(pSourceRecordId);

        fetch curConditionDetails
         into vConditionDetails;

        while curConditionDetails%found loop
          DuplicateConditionDetails(vDuplicatedConditionId
                                  ,   /*Type parent             */
                                    vConditionDetails.PAC_CONDITION_DETAIL_ID
                                  ,   /*Lien automatique source */
                                    vDuplicatedDetailId   /*D�tail cr��             */
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

    pDuplicatedId  := vDuplicatedConditionId;   /*Assignation du param�tre de retour*/
  end DuplicatePaymentCondition;

  /**
  * Description   Procedure de copie des d�tails de conditions de paiement
  **/
  procedure DuplicateConditionDetails(
    pLinkedParentId        PAC_PAYMENT_CONDITION.PAC_PAYMENT_CONDITION_ID%type   -- Condition parente
  , pSourceRecordId        PAC_CONDITION_DETAIL.PAC_CONDITION_DETAIL_ID%type   -- D�tail parente
  , pDuplicatedId   in out PAC_CONDITION_DETAIL.PAC_CONDITION_DETAIL_ID%type   --D�tail cr��
  )
  is
    vDuplicatedId PAC_CONDITION_DETAIL.PAC_CONDITION_DETAIL_ID%type;   --R�ceptionne l'id du lien automatique cr��
  begin
    begin
      /*R�ception d'un nouvel Id de d�tail*/
      select INIT_ID_SEQ.nextval
        into vDuplicatedId
        from dual;

      /* Cr�ation de l'enregistrement sur la base du d�tail � copier*/
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
        select vDuplicatedId   /* D�tail de condition-> Nouvel Id                      */
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
             , sysdate   /* Date cr�ation      -> Date syst�me                   */
             , PCS.PC_I_LIB_SESSION.GetUserIni   /* Id cr�ation        -> user                           */
          from PAC_CONDITION_DETAIL
         where PAC_CONDITION_DETAIL_ID = pSourceRecordId;
    exception
      when others then
        vDuplicatedId  := 0;
        raise;
    end;

    pDuplicatedId  := vDuplicatedId;   /*Assignation du param�tre de retour */
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
    /** R�ception d'un nouvel Id **/
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
           , 0   -- ne peut pas �tre 'principale'
           , ADD_PRIORITY
           , ADD_CARE_OF
           , ADD_PO_BOX
           , ADD_PO_BOX_NBR
           , ADD_COUNTY
           , DIC_ADDRESS_TYPE_ID
           , C_PARTNER_STATUS
           , sysdate   --Date syst�me
           , PCS.PC_I_LIB_SESSION.GetUserIni   --User courant
        from PAC_ADDRESS
       where PAC_ADDRESS_ID = pSourceRecordId;
  end DuplicatePacAddress;
end PAC_DUPLICATE;
