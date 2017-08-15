--------------------------------------------------------
--  DDL for Package Body ACI_DOC_PROTECTION
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ACI_DOC_PROTECTION" 
is
  /*
  * procedure DocumentProtect
  * Description
  *    Protection ou déprotection du document dans une transaction autonome
  * @created pv 19.09.2008
  * @lastUpdate
  * @private
  * @param aACI_DOCUMENT_ID document ACI
  * @param aProtect : 0 -> déprotége, <>0 -> protége
  * @param aSessionID : Id de la session courante
  * @param aUserID : Id de l'utilisateur courant
  * @param aShowError : 0 -> pas d'exception, <>0 -> exception en cas d'erreur
  * @param aAutonomousTransaction : 0 -> pas de transaction autonome, <>0 -> transaction autonome
  * @param aUpdated : 0 -> pas de màj (ERREUR), 1 -> màj (OK), 2 -> màj pas nécessaire (OK)
  */
  procedure DocumentProtect(
    aACI_DOCUMENT_ID     ACI_DOCUMENT.ACI_DOCUMENT_ID%type
  , aProtect             number
  , aSessionID           varchar2
  , aUserID              number
  , aShowError           number
  , aUpdated         out number
  )
  is
    pragma autonomous_transaction;
    vDocumentId ACI_DOCUMENT.ACI_DOCUMENT_ID%type;
    vSessionId  ACI_DOCUMENT_STATUS.DOC_LOCK_SESSION_ID%type;
  begin
    if aProtect != 0 then -- Protéger le document
      -- teste si le document n'est pas déjà protégé par quelqu'un d'autre
      select ACI_DOCUMENT_ID
        into vDocumentId
        from ACI_DOCUMENT_STATUS
       where ACI_DOCUMENT_ID = aACI_DOCUMENT_ID
         and (   DOC_LOCK_SESSION_ID = aSessionId
              or DOC_LOCK_SESSION_ID is null);

      /* Màj du flag de protection du document */
      update ACI_DOCUMENT_STATUS
         set DOC_LOCK_SESSION_ID = aSessionID
           , PC_PC_USER_ID = aUserID
       where ACI_DOCUMENT_ID = aACI_DOCUMENT_ID;

      aUpdated  := 1;
    else -- Libérer le document
      -- teste si le document n'est pas déjà protégé par quelqu'un d'autre
      select ACI_DOCUMENT_ID
           , DOC_LOCK_SESSION_ID
        into vDocumentId
           , vSessionId
        from ACI_DOCUMENT_STATUS
       where ACI_DOCUMENT_ID = aACI_DOCUMENT_ID;

      if    vSessionId = aSessionId
         or vSessionId is null then
        aUpdated  := 1;
      elsif     aSessionId is null
            and COM_FUNCTIONS.Is_Session_Alive(vSessionId) = 0 then
        aUpdated  := 1;
      elsif aShowError = 1 then
          raise_application_error
            (-20000
           , PCS.PC_FUNCTIONS.TranslateWord
                             ('PCS - Vous essayez de déprotéger un document qui a été protégé par un autre utilisateur.')
            );
      else
        aUpdated  := 0; -- erreur lors de la libération du document
      end if;

      if aUpdated = 1 then
        /* Màj du flag de protection du document */
        update ACI_DOCUMENT_STATUS
           set DOC_LOCK_SESSION_ID = null
             , PC_PC_USER_ID = null
         where ACI_DOCUMENT_ID = aACI_DOCUMENT_ID;
      end if;
    end if;

    commit;   --Car on utilise une transaction autonome
  exception
    when no_data_found then
      if aShowError = 1 then
        if aProtect = 1 then
          raise_application_error
            (-20000
           , PCS.PC_FUNCTIONS.TranslateWord
                            ('PCS - Vous essayez de protéger un document qui est déjà protégé par un autre utilisateur.')
            );
        else
          raise_application_error
            (-20000
           , PCS.PC_FUNCTIONS.TranslateWord
                             ('PCS - Vous essayez de déprotéger un document qui a été protégé par un autre utilisateur.')
            );
        end if;
      else
        aUpdated  := 0; --Erreur de protection
      end if;
  end DocumentProtect;

  /**
  * Description
  *    Protection ou déprotection du document dans une transaction autonome
  *      avec contrôle si protection par document ou travail
  */
  procedure DocumentProtectACI(
    aACI_DOCUMENT_ID       in     ACI_DOCUMENT.ACI_DOCUMENT_ID%type
  , aProtect               in     number
  , aSessionID             in     varchar2
  , aUserID                in     number
  , aShowError             in     number
  , aAutonomousTransaction in     number
  , aUpdated               out    number
  )
  is
    vMultiUser    number(1);
    vExistJobType number(1);
  begin
    --S'assurer que le document est bien lié à un modèle
    select case
             when nvl(max(ACJ_JOB_TYPE_S_CATALOGUE_ID), 0) > 0 then 1
             else 0
           end
      into vExistJobType
      from ACI_DOCUMENT
     where ACI_DOCUMENT_ID = aACI_DOCUMENT_ID;

    --Recherche si travail multi-user
    if vExistJobType > 0 then
      select nvl(min(EVE_MULTI_USERS), 0)
        into vMultiUser
        from ACJ_EVENT EVE
       where EVE.ACJ_JOB_TYPE_ID = (select ACJ_JOB_TYPE_ID
                                      from ACJ_JOB_TYPE_S_CATALOGUE
                                     where ACJ_JOB_TYPE_S_CATALOGUE_ID = (select ACJ_JOB_TYPE_S_CATALOGUE_ID
                                                                            from ACI_DOCUMENT
                                                                           where ACI_DOCUMENT_ID = aACI_DOCUMENT_ID) );
    end if;

    --Si travail multi-user ou que le document n'est pas lié à un modèle, on protège le document, sinon on fait rien
    if    (vMultiUser = 1)
       or (vExistJobType = 0) then
      -- Protection ou déprotection du document dans une transaction autonome
      DocumentProtect(aACI_DOCUMENT_ID, aProtect, aSessionID, aUserID, aShowError, aUpdated);

      if aAutonomousTransaction = 0 then
        commit;   -- Car on utilise une transaction autonome
      end if;
    else
      aUpdated  := 2; -- Pas de mise à jour nécessaire
    end if;
  end DocumentProtectACI;
end ACI_DOC_PROTECTION;
