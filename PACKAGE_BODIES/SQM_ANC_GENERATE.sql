--------------------------------------------------------
--  DDL for Package Body SQM_ANC_GENERATE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "SQM_ANC_GENERATE" 
is
  /* Ajout d'une erreur au rapport d'erreur au niveau de l'ANC.
  *
  */
  procedure AddErrorReport(aErrormsg varchar2, aSQM_ANC_ID SQM_ANC.SQM_ANC_ID%type, aError_Detected integer)
  is
  begin
    update SQM_ANC
       set ANC_ERROR_REPORT = ANC_ERROR_REPORT || chr(13) || chr(10) || aErrormsg
         , ANC_ERROR_DETECTED = aError_Detected
     where SQM_ANC_ID = aSQM_ANC_ID;
  end AddErrorReport;

  /**
  * Procedure    : FormatANCWithGenerationParams
  * Description  : Formatage du record mémoire de stockage de l'ANC avec les paramètres d'appel de la fonction
  *                de génération de celle-ci, si une initialisation préalable n'a pas déjà été effectuée.
  */
  procedure FormatANCWithGenerationParams(
    aSQM_ANC_Rec             in out SQM_ANC_INITIALIZE.TSQM_ANC_Rec
  , aC_ANC_TYPE              in     SQM_ANC.C_ANC_TYPE%type   -- Type d'NC.
  , aDIC_ANC_CODE_ID         in     SQM_ANC.DIC_ANC_CODE_ID%type   -- Code NC.
  , aPC_LANG_ID              in     SQM_ANC.PC_LANG_ID%type   -- Langue NC.
  , aPAC_CUSTOM_PARTNER_ID   in     SQM_ANC.PAC_CUSTOM_PARTNER_ID%type   -- Client.
  , aPAC_SUPPLIER_PARTNER_ID in     SQM_ANC.PAC_SUPPLIER_PARTNER_ID%type   -- Fournisseur.
  , aDOC_DOCUMENT_ID         in     SQM_ANC.DOC_DOCUMENT_ID%type   -- Document.
  , aFAL_LOT_ID              in     SQM_ANC.FAL_LOT_ID%type   -- Lot de fabrication.
  , aANC_SHORT_DESCRIPTION   in     SQM_ANC.ANC_SHORT_DESCRIPTION%type   -- Descr. courte.
  , aANC_LONG_DESCRIPTION    in     SQM_ANC.ANC_LONG_DESCRIPTION%type   -- Description longue.
  , aDOC_RECORD_ID           in     SQM_ANC.DOC_RECORD_ID%type   -- Dossier.
  , aASA_RECORD_ID           in     SQM_ANC.ASA_RECORD_ID%type   -- Dossier SAV
  , aA_IDCRE                 in     SQM_ANC.A_IDCRE%type   -- Créateur ANC
  , aANC_DATE                in     SQM_ANC.ANC_DATE%type
  , aPAC_ADDRESS_ID          in     SQM_ANC.PAC_ADDRESS_ID%Type default null
  )   -- Date ANC
  is
  begin
    --Type de NC.
    aSQM_ANC_Rec.C_ANC_TYPE               := nvl(aSQM_ANC_Rec.C_ANC_TYPE, aC_ANC_TYPE);
    -- Code NC.
    aSQM_ANC_Rec.DIC_ANC_CODE_ID          := nvl(aSQM_ANC_Rec.DIC_ANC_CODE_ID, aDIC_ANC_CODE_ID);
    -- Langue NC.
    aSQM_ANC_Rec.PC_LANG_ID               := nvl(aSQM_ANC_Rec.PC_LANG_ID, aPC_LANG_ID);
    -- Client
    aSQM_ANC_Rec.PAC_CUSTOM_PARTNER_ID    := nvl(aSQM_ANC_Rec.PAC_CUSTOM_PARTNER_ID, aPAC_CUSTOM_PARTNER_ID);
    -- Fournisseur
    aSQM_ANC_Rec.PAC_SUPPLIER_PARTNER_ID  := nvl(aSQM_ANC_Rec.PAC_SUPPLIER_PARTNER_ID, aPAC_SUPPLIER_PARTNER_ID);
    -- Document
    aSQM_ANC_Rec.DOC_DOCUMENT_ID          := nvl(aSQM_ANC_Rec.DOC_DOCUMENT_ID, aDOC_DOCUMENT_ID);
    -- Lot
    aSQM_ANC_Rec.FAL_LOT_ID               := nvl(aSQM_ANC_Rec.FAL_LOT_ID, aFAL_LOT_ID);
    -- Description courte
    aSQM_ANC_Rec.ANC_SHORT_DESCRIPTION    :=
                                        nvl(aSQM_ANC_Rec.ANC_SHORT_DESCRIPTION, substr(aANC_SHORT_DESCRIPTION, 0, 50) );
    -- Description longue
    aSQM_ANC_Rec.ANC_LONG_DESCRIPTION     :=
                                        nvl(aSQM_ANC_Rec.ANC_LONG_DESCRIPTION, substr(aANC_LONG_DESCRIPTION, 0, 4000) );
    -- Dossier
    aSQM_ANC_Rec.DOC_RECORD_ID            := nvl(aSQM_ANC_Rec.DOC_RECORD_ID, aDOC_RECORD_ID);
    -- Dossier SAV
    aSQM_ANC_Rec.ASA_RECORD_ID            := nvl(aSQM_ANC_Rec.ASA_RECORD_ID, aASA_RECORD_ID);
    -- Créateur
    aSQM_ANC_Rec.A_IDCRE                  := nvl(aSQM_ANC_Rec.A_IDCRE, aA_IDCRE);
    -- Créateur
    aSQM_ANC_Rec.ANC_DATE                 := nvl(aSQM_ANC_Rec.ANC_DATE, aANC_DATE);
    --Adresse
    aSQM_ANC_Rec.PAC_ADDRESS_ID           := nvl(aSQM_ANC_Rec.PAC_ADDRESS_ID, aPAC_ADDRESS_ID);
  end FormatANCWithGenerationParams;

  /*
  * Procdure CheckNCIntegrity.
  * Description :  Procédure de détection des erreurs de création d'une NC (erreurs non-blocantes permettant tout de même
  *                la création de celle-ci). En cas de problème, le Flag ANC_ERROR_DETECTED est mis à 1 et le champ ANC_ERROR_REPORT
  *                est nourri avec les informations concernant l'erreur détectée.
  *                Les erreurs peuvent ensuite être traitées via l'interface (Elles sont relevées par le cadenas rouge et peuvent être
  *                traitées comme dans le cas de NC protégées (Idem documents protégés)
  */
  procedure CheckNCIntegrity(aSQM_ANC_Rec in out SQM_ANC_INITIALIZE.TSQM_ANC_Rec)
  is
  begin
    -- Détection d'erreur = 0 pour le moment
    aSQM_ANC_Rec.ANC_ERROR_DETECTED  := 0;
    aSQM_ANC_Rec.ANC_ERROR_REPORT    := '';

    -- Créateur ANC
    if aSQM_ANC_Rec.PC_ANC_USER1_ID is null then
      SQM_ANC_INITIALIZE.GetUserInfo(aSQM_ANC_Rec.A_IDCRE, aSQM_ANC_Rec.PC_ANC_USER1_ID);
    end if;

    -- Client et fournisseurs en fonction du type.
    if     aSQM_ANC_Rec.PAC_CUSTOM_PARTNER_ID is not null
       and aSQM_ANC_Rec.C_ANC_TYPE <> '3' then
      aSQM_ANC_Rec.ANC_ERROR_DETECTED     := 1;
      aSQM_ANC_Rec.ANC_ERROR_REPORT       :=
        aSQM_ANC_Rec.ANC_ERROR_REPORT ||
        chr(13) ||
        chr(10) ||
        PCS.PC_FUNCTIONS.TranslateWord('Seule un NC client porte sur un client! Celui-ci à été supprimé.') ||
        ' (' ||
        PCS.PC_FUNCTIONS.TranslateWord('Client') ||
        ' ' ||
        PAC_FUNCTIONS.GetNamesAndCity(aSQM_ANC_Rec.PAC_CUSTOM_PARTNER_ID) ||
        ' )';
      aSQM_ANC_Rec.PAC_CUSTOM_PARTNER_ID  := null;
    end if;

    -- Fournisseur en fonction du type.
    if     aSQM_ANC_Rec.PAC_SUPPLIER_PARTNER_ID is not null
       and aSQM_ANC_Rec.C_ANC_TYPE <> '2' then
      aSQM_ANC_Rec.ANC_ERROR_DETECTED       := 1;
      aSQM_ANC_Rec.ANC_ERROR_REPORT         :=
        aSQM_ANC_Rec.ANC_ERROR_REPORT ||
        chr(13) ||
        chr(10) ||
        PCS.PC_FUNCTIONS.TranslateWord('Seule un NC fournisseur porte sur un client! Celui-ci à été supprimé.') ||
        ' (' ||
        PCS.PC_FUNCTIONS.TranslateWord('Fournisseur') ||
        ' ' ||
        PAC_FUNCTIONS.GetNamesAndCity(aSQM_ANC_Rec.PAC_SUPPLIER_PARTNER_ID) ||
        ' )';
      aSQM_ANC_Rec.PAC_SUPPLIER_PARTNER_ID  := null;
    end if;

    if     (   aSQM_ANC_Rec.FAL_LOT_ID is not null)
       and (aSQM_ANC_Rec.C_ANC_TYPE <> '1') then
      aSQM_ANC_Rec.ANC_ERROR_DETECTED  := 1;
      aSQM_ANC_Rec.ANC_ERROR_REPORT    :=
        aSQM_ANC_Rec.ANC_ERROR_REPORT ||
        chr(13) ||
        chr(10) ||
        PCS.PC_FUNCTIONS.TranslateWord
                                    ('Seule une NC interne porte sur un lot de fabrication! Celui-ci à été supprimé.') ||
        ' (' ||
        PCS.PC_FUNCTIONS.TranslateWord('Lot') ||
        ' ' ||
        FAL_TOOLS.Format_Lot_Generic(aSQM_ANC_Rec.FAL_LOT_ID)
        ||
        ' )';
      aSQM_ANC_Rec.FAL_LOT_ID          := null;
    end if;

    -- Adresse
    if aSQM_ANC_Rec.PAC_ADDRESS_ID is null then
      if aSQM_ANC_Rec.PAC_CUSTOM_PARTNER_ID is not null then
        begin
          select PAC_ADDRESS_ID
            into aSQM_ANC_Rec.PAC_ADDRESS_ID
            from PAC_ADDRESS
           where PAC_PERSON_ID = aSQM_ANC_Rec.PAC_CUSTOM_PARTNER_ID
             and ADD_PRINCIPAL = 1;
        exception
          when others then
            null;
        end;
      elsif aSQM_ANC_Rec.PAC_SUPPLIER_PARTNER_ID is not null then
        begin
          select PAC_ADDRESS_ID
            into aSQM_ANC_Rec.PAC_ADDRESS_ID
            from PAC_ADDRESS
           where PAC_PERSON_ID = aSQM_ANC_Rec.PAC_SUPPLIER_PARTNER_ID
             and ADD_PRINCIPAL = 1;
        exception
          when others then
            null;
        end;
      end if;
    end if;

      /* Vérification des renseignements des champs mandatory qui peuvent êtres "remplis" automatiquement
    (Avec signalement de l'erreur si celle-ci est réellement influente sur la NC) . */

    -- ID ANC
    if aSQM_ANC_Rec.SQM_ANC_ID is null then
      select INIT_ID_SEQ.nextval
        into aSQM_ANC_Rec.SQM_ANC_ID
        from dual;
    end if;

    -- Langue
    if aSQM_ANC_Rec.PC_LANG_ID is null then
      -- Si adresse existante, langue de l'adresse (si inexistante, celle de la companie),
      if aSQM_ANC_Rec.PAC_ADDRESS_ID is not null then
        begin
          select PC_LANG_ID
            into aSQM_ANC_Rec.PC_LANG_ID
            from PAC_ADDRESS
           where PAC_ADDRESS_ID = aSQM_ANC_Rec.PAC_ADDRESS_ID;
        exception
          when no_data_found then
            aSQM_ANC_Rec.PC_LANG_ID  := PCS.PC_PUBLIC.GetCompLangId;
        end;
      -- Sinon langue de la companie
      else
        aSQM_ANC_Rec.PC_LANG_ID  := PCS.PC_PUBLIC.GetCompLangId;
      end if;
    end if;

    -- Numéro ANC
    if aSQM_ANC_Rec.ANC_NUMBER is null then
      SQM_ANC_FUNCTIONS.GetANCNumber(aSQM_ANC_Rec.C_ANC_TYPE, aSQM_ANC_Rec.ANC_NUMBER);
    end if;

    -- Protection
    aSQM_ANC_Rec.ANC_PROTECTED       := nvl(aSQM_ANC_Rec.ANC_PROTECTED, 0);
    -- Date Création NC
    aSQM_ANC_Rec.ANC_DATE            := nvl(aSQM_ANC_Rec.ANC_DATE, sysdate);
    --  Datecre
    aSQM_ANC_Rec.A_DATECRE           := nvl(aSQM_ANC_Rec.A_DATECRE, sysdate);

    -- Vérification des valeurs de dico
    if not IsGoodDicoValue('DIC_ANC_CODE', aSQM_ANC_Rec.DIC_ANC_CODE_ID) then
      aSQM_ANC_Rec.DIC_ANC_CODE_ID  := null;
    end if;

    if not IsGoodDicoValue('DIC_ANC_FREE1', aSQM_ANC_Rec.DIC_ANC_FREE1_ID) then
      aSQM_ANC_Rec.DIC_ANC_FREE1_ID  := null;
    end if;

    if not IsGoodDicoValue('DIC_ANC_FREE2', aSQM_ANC_Rec.DIC_ANC_FREE2_ID) then
      aSQM_ANC_Rec.DIC_ANC_FREE2_ID  := null;
    end if;

    if not IsGoodDicoValue('DIC_ANC_FREE3', aSQM_ANC_Rec.DIC_ANC_FREE3_ID) then
      aSQM_ANC_Rec.DIC_ANC_FREE3_ID  := null;
    end if;

    if not IsGoodDicoValue('DIC_ANC_FREE4', aSQM_ANC_Rec.DIC_ANC_FREE4_ID) then
      aSQM_ANC_Rec.DIC_ANC_FREE4_ID  := null;
    end if;

    if not IsGoodDicoValue('DIC_ANC_FREE5', aSQM_ANC_Rec.DIC_ANC_FREE5_ID) then
      aSQM_ANC_Rec.DIC_ANC_FREE5_ID  := null;
    end if;
  end CheckNCIntegrity;

  /**
  * Procedure    : Insert_NC
  * Description  : Enregistrement dans la base de la NC. (Fin de génération);
  *
  */
  procedure Insert_NC(aSQM_ANC_Rec SQM_ANC_INITIALIZE.TSQM_ANC_Rec)
  is
  begin
    -- Insertion de la NC
    insert into SQM_ANC
                (SQM_ANC_ID
               , PC_ANC_USER1_ID
               , PC_ANC_USER2_ID
               , PC_ANC_USER3_ID
               , PC_ANC_USER4_ID
               , DIC_ANC_CODE_ID
               , DOC_RECORD_ID
               , PC_LANG_ID
               , PAC_ADDRESS_ID
               , PAC_PERSON_ASSOCIATION_ID
               , FAL_LOT_ID
               , DOC_DOCUMENT_ID
               , PAC_SUPPLIER_PARTNER_ID
               , PAC_CUSTOM_PARTNER_ID
               , C_ANC_STATUS
               , C_ANC_TYPE
               , DIC_ANC_FREE1_ID
               , DIC_ANC_FREE2_ID
               , DIC_ANC_FREE3_ID
               , DIC_ANC_FREE4_ID
               , DIC_ANC_FREE5_ID
               , ANC_NUMBER
               , ANC_SHORT_DESCRIPTION
               , ANC_LONG_DESCRIPTION
               , ANC_PARTNER_NUMBER
               , ANC_PARTNER_REF
               , ANC_PARTNER_DATE
               , ANC_DATE
               , ANC_PRINT_RECEPT_DATE
               , ANC_VALIDATION_DATE
               , ANC_ALLOCATION_DATE
               , ANC_CLOSING_DATE
               , ANC_VALIDATION_DURATION
               , ANC_REPLY_DURATION
               , ANC_ALLOCATION_DURATION
               , ANC_PROCESSING_DURATION
               , ANC_TOTAL_DURATION
               , ANC_DIRECT_COST
               , ANC_PREVENTIVE_COST
               , ANC_FIXED_COST
               , ANC_TOTAL_COST
               , A_DATECRE
               , A_DATEMOD
               , A_IDCRE
               , A_IDMOD
               , ANC_FREE_TEXT1
               , ANC_FREE_TEXT2
               , ANC_FREE_TEXT3
               , ANC_FREE_TEXT4
               , ANC_FREE_TEXT5
               , ANC_FREE_DATE1
               , ANC_FREE_DATE2
               , ANC_FREE_DATE3
               , ANC_FREE_DATE4
               , ANC_FREE_DATE5
               , ANC_FREE_NUMBER1
               , ANC_FREE_NUMBER2
               , ANC_FREE_NUMBER3
               , ANC_FREE_NUMBER4
               , ANC_FREE_NUMBER5
               , ANC_FREE_COMMENT1
               , ANC_FREE_COMMENT2
               , ANC_PROTECTED
               , ANC_SESSION_ID
               , ANC_ERROR_DETECTED
               , ANC_ERROR_REPORT
               , ASA_RECORD_ID
                )
         values (aSQM_ANC_Rec.SQM_ANC_ID
               , aSQM_ANC_Rec.PC_ANC_USER1_ID
               , aSQM_ANC_Rec.PC_ANC_USER2_ID
               , aSQM_ANC_Rec.PC_ANC_USER3_ID
               , aSQM_ANC_Rec.PC_ANC_USER4_ID
               , aSQM_ANC_Rec.DIC_ANC_CODE_ID
               , aSQM_ANC_Rec.DOC_RECORD_ID
               , aSQM_ANC_Rec.PC_LANG_ID
               , aSQM_ANC_Rec.PAC_ADDRESS_ID
               , aSQM_ANC_Rec.PAC_PERSON_ASSOCIATION_ID
               , aSQM_ANC_Rec.FAL_LOT_ID
               , aSQM_ANC_Rec.DOC_DOCUMENT_ID
               , aSQM_ANC_Rec.PAC_SUPPLIER_PARTNER_ID
               , aSQM_ANC_Rec.PAC_CUSTOM_PARTNER_ID
               , aSQM_ANC_Rec.C_ANC_STATUS
               , aSQM_ANC_Rec.C_ANC_TYPE
               , aSQM_ANC_Rec.DIC_ANC_FREE1_ID
               , aSQM_ANC_Rec.DIC_ANC_FREE2_ID
               , aSQM_ANC_Rec.DIC_ANC_FREE3_ID
               , aSQM_ANC_Rec.DIC_ANC_FREE4_ID
               , aSQM_ANC_Rec.DIC_ANC_FREE5_ID
               , aSQM_ANC_Rec.ANC_NUMBER
               , substr(aSQM_ANC_Rec.ANC_SHORT_DESCRIPTION, 0, 50)
               , substr(aSQM_ANC_Rec.ANC_LONG_DESCRIPTION, 0, 4000)
               , substr(aSQM_ANC_Rec.ANC_PARTNER_NUMBER, 0, 30)
               , substr(aSQM_ANC_Rec.ANC_PARTNER_REF, 0, 50)
               , aSQM_ANC_Rec.ANC_PARTNER_DATE
               , aSQM_ANC_Rec.ANC_DATE
               , aSQM_ANC_Rec.ANC_PRINT_RECEPT_DATE
               , aSQM_ANC_Rec.ANC_VALIDATION_DATE
               , aSQM_ANC_Rec.ANC_ALLOCATION_DATE
               , aSQM_ANC_Rec.ANC_CLOSING_DATE
               , aSQM_ANC_Rec.ANC_VALIDATION_DURATION
               , aSQM_ANC_Rec.ANC_REPLY_DURATION
               , aSQM_ANC_Rec.ANC_ALLOCATION_DURATION
               , aSQM_ANC_Rec.ANC_PROCESSING_DURATION
               , aSQM_ANC_Rec.ANC_TOTAL_DURATION
               , aSQM_ANC_Rec.ANC_DIRECT_COST
               , aSQM_ANC_Rec.ANC_PREVENTIVE_COST
               , aSQM_ANC_Rec.ANC_FIXED_COST
               , aSQM_ANC_Rec.ANC_TOTAL_COST
               , aSQM_ANC_Rec.A_DATECRE
               , aSQM_ANC_Rec.A_DATEMOD
               , aSQM_ANC_Rec.A_IDCRE
               , aSQM_ANC_Rec.A_IDMOD
               , substr(aSQM_ANC_Rec.ANC_FREE_TEXT1, 0, 250)
               , substr(aSQM_ANC_Rec.ANC_FREE_TEXT2, 0, 250)
               , substr(aSQM_ANC_Rec.ANC_FREE_TEXT3, 0, 250)
               , substr(aSQM_ANC_Rec.ANC_FREE_TEXT4, 0, 250)
               , substr(aSQM_ANC_Rec.ANC_FREE_TEXT5, 0, 250)
               , aSQM_ANC_Rec.ANC_FREE_DATE1
               , aSQM_ANC_Rec.ANC_FREE_DATE2
               , aSQM_ANC_Rec.ANC_FREE_DATE3
               , aSQM_ANC_Rec.ANC_FREE_DATE4
               , aSQM_ANC_Rec.ANC_FREE_DATE5
               , aSQM_ANC_Rec.ANC_FREE_NUMBER1
               , aSQM_ANC_Rec.ANC_FREE_NUMBER2
               , aSQM_ANC_Rec.ANC_FREE_NUMBER3
               , aSQM_ANC_Rec.ANC_FREE_NUMBER4
               , aSQM_ANC_Rec.ANC_FREE_NUMBER5
               , substr(aSQM_ANC_Rec.ANC_FREE_COMMENT1, 0, 4000)
               , substr(aSQM_ANC_Rec.ANC_FREE_COMMENT2, 0, 4000)
               , aSQM_ANC_Rec.ANC_PROTECTED
               , aSQM_ANC_Rec.ANC_SESSION_ID
               , aSQM_ANC_Rec.ANC_ERROR_DETECTED
               , aSQM_ANC_Rec.ANC_ERROR_REPORT
               , aSQM_ANC_Rec.ASA_RECORD_ID
                );
  end INSERT_NC;

  /* Procédure
  *  Description :  Procedure d'ajout au record des champs calculés
  *
  */
  procedure CalculateANCFields(aSQM_ANC_Rec in out SQM_ANC_INITIALIZE.TSQM_ANC_Rec)
  is
    aResultat SQM_ANC_FUNCTIONS.MaxVarchar2;
  begin
    -- Statut NC (A valider en création).
    aSQM_ANC_Rec.C_ANC_STATUS             := '1';

    -- ID ANC
    select INIT_ID_SEQ.nextval
      into aSQM_ANC_Rec.SQM_ANC_ID
      from dual;

    -- Numéro ANC
    SQM_ANC_FUNCTIONS.GetANCNumber(aSQM_ANC_Rec.C_ANC_TYPE, aSQM_ANC_Rec.ANC_NUMBER);
    -- Durée validation
    aSQM_ANC_Rec.ANC_VALIDATION_DURATION  := null;
    -- Durée réponse
    aSQM_ANC_Rec.ANC_REPLY_DURATION       := null;
    -- Durée pour affectation
    aSQM_ANC_Rec.ANC_ALLOCATION_DURATION  := null;
    -- Durée de traitement
    aSQM_ANC_Rec.ANC_PROCESSING_DURATION  := null;
    -- Durée totale
    aSQM_ANC_Rec.ANC_TOTAL_DURATION       := null;
    -- Coût corrections
    aSQM_ANC_Rec.ANC_DIRECT_COST          := null;
    -- Coûts actions
    aSQM_ANC_Rec.ANC_PREVENTIVE_COST      := null;

    -- Cout Forfaitaire (Si non renseigné par les paramètres d'appel de la fonction, on va rechercher sur les configs suivant le type de l'ANC
    if aSQM_ANC_Rec.ANC_FIXED_COST is null then
      -- Interne
      if aSQM_ANC_Rec.C_ANC_TYPE = '1' then
        begin
          aSQM_ANC_Rec.ANC_FIXED_COST  := to_number(PCS.PC_CONFIG.GetConfig('SQM_ANC_INTERN_COST') );
        exception
          when others then
            aSQM_ANC_Rec.ANC_FIXED_COST  := null;
        end;
      -- Fournisseur
      elsif aSQM_ANC_Rec.C_ANC_TYPE = '2' then
        begin
          aSQM_ANC_Rec.ANC_FIXED_COST  := to_number(PCS.PC_CONFIG.GetConfig('SQM_ANC_SUPPLY_COST') );
        exception
          when others then
            aSQM_ANC_Rec.ANC_FIXED_COST  := null;
        end;
      -- Client
      elsif aSQM_ANC_Rec.C_ANC_TYPE = '3' then
        begin
          aSQM_ANC_Rec.ANC_FIXED_COST  := to_number(PCS.PC_CONFIG.GetConfig('SQM_ANC_CUSTOM_COST') );
        exception
          when others then
            aSQM_ANC_Rec.ANC_FIXED_COST  := null;
        end;
      end if;
    end if;

    -- Coût Total
    aSQM_ANC_Rec.ANC_TOTAL_COST           := null;
    -- NC protégée
    aSQM_ANC_Rec.ANC_PROTECTED            := 0;
    -- Session Oracle
    aSQM_ANC_Rec.ANC_SESSION_ID           := null;
    -- Date de validation
    aSQM_ANC_Rec.ANC_VALIDATION_DATE      := null;
    -- User validation
    aSQM_ANC_Rec.PC_ANC_USER2_ID          := null;
    -- Date Allocation
    aSQM_ANC_Rec.ANC_ALLOCATION_DATE      := null;
    -- User allocation
    aSQM_ANC_Rec.PC_ANC_USER3_ID          := null;
    -- Date bouclement
    aSQM_ANC_Rec.ANC_CLOSING_DATE         := null;
  end;

  /* procédure GenerateANC .
  * Description :  procedure de génération hors interface d'une ANC.
  *          La procédure d'initialisation individualisée permet une initialisation autre que celle par défaut
  *          Si une procédure d'initialisation indiv. est précisée alors les paramètres de cette fonction ne sont utilisés
  *                que si cette procédure d'initialisation n'a pas déjà initialisé les champs de l'ANC correspondants.
  *
  */
  function GenerateANC(
    aC_ANC_TYPE              in SQM_ANC.C_ANC_TYPE%type   -- Type d'NC.
  , aDIC_ANC_CODE_ID         in SQM_ANC.DIC_ANC_CODE_ID%type   -- Code NC.
  , aPC_LANG_ID              in SQM_ANC.PC_LANG_ID%type   -- Langue NC.
  , aPAC_CUSTOM_PARTNER_ID   in SQM_ANC.PAC_CUSTOM_PARTNER_ID%type   -- Client.
  , aPAC_SUPPLIER_PARTNER_ID in SQM_ANC.PAC_SUPPLIER_PARTNER_ID%type   -- Fournisseur.
  , aPAC_ADDRESS_ID          in SQM_ANC.PAC_ADDRESS_ID%type   -- Adresse.
  , aDOC_DOCUMENT_ID         in SQM_ANC.DOC_DOCUMENT_ID%type   -- Document.
  , aFAL_LOT_ID              in SQM_ANC.FAL_LOT_ID%type   -- Lot de fabrication.
  , aANC_SHORT_DESCRIPTION   in SQM_ANC.ANC_SHORT_DESCRIPTION%type   -- Descr. courte.
  , aANC_LONG_DESCRIPTION    in SQM_ANC.ANC_LONG_DESCRIPTION%type   -- Description longue.
  , aDOC_RECORD_ID           in SQM_ANC.DOC_RECORD_ID%type   -- Dossier.
  , aASA_RECORD_ID           in SQM_ANC.ASA_RECORD_ID%type   -- Dossier SAV.
  , aA_IDCRE                 in SQM_ANC.A_IDCRE%type   -- Créateur ANC
  , aANC_DATE                in SQM_ANC.ANC_DATE%type   -- Date ANC
  , aIndivInitProc           in varchar2 default null   -- Procédure d'initialisation individualisée.
  , aStringParam1            in varchar2 default null   -- paramètres utilisable pour la procedure indiv d'initialisation
  , aStringParam2            in varchar2 default null   -- idem.
  , aStringParam3            in varchar2 default null   -- idem.
  , aStringParam4            in varchar2 default null   -- idem.
  , aStringParam5            in varchar2 default null   -- idem.
  , aCurrencyParam1          in number default null   -- idem.
  , aCurrencyParam2          in number default null   -- idem.
  , aCurrencyParam3          in number default null   -- idem.
  , aCurrencyParam4          in number default null   -- idem.
  , aCurrencyParam5          in number default null   -- idem.
  , aIntegerParam1           in integer default null   -- idem.
  , aIntegerParam2           in integer default null   -- idem.
  , aIntegerParam3           in integer default null   -- idem.
  , aIntegerParam4           in integer default null   -- idem.
  , aIntegerParam5           in integer default null   -- idem.
  , aDateParam1              in date default null   -- idem.
  , aDateParam2              in date default null   -- idem.
  , aDateParam3              in date default null   -- idem.
  , aDateParam4              in date default null   -- idem.
  , aDateParam5              in date default null
  )   -- idem.
    return SQM_ANC.SQM_ANC_ID%type
  is
    -- Champs calculés
    nSQM_ANC_ID              SQM_ANC.SQM_ANC_ID%type;
    vANC_NUMBER              SQM_ANC.ANC_NUMBER%type;
    nANC_VALIDATION_DURATION SQM_ANC.ANC_VALIDATION_DURATION%type;
    nANC_REPLY_DURATION      SQM_ANC.ANC_REPLY_DURATION%type;
    nANC_ALLOCATION_DURATION SQM_ANC.ANC_ALLOCATION_DURATION%type;
    nANC_PROCESSING_DURATION SQM_ANC.ANC_PROCESSING_DURATION%type;
    nANC_TOTAL_DURATION      SQM_ANC.ANC_TOTAL_DURATION%type;
    nANC_DIRECT_COST         SQM_ANC.ANC_DIRECT_COST%type;
    nANC_PREVENTIVE_COST     SQM_ANC.ANC_PREVENTIVE_COST%type;
    nANC_TOTAL_COST          SQM_ANC.ANC_TOTAL_COST%type;
    iANC_PROTECTED           SQM_ANC.ANC_PROTECTED%type;
    vANC_SESSION_ID          SQM_ANC.ANC_SESSION_ID%type;
  begin
    -- Vérification de l'information prédominante à la création de la NC : Son Type
    if     aC_ANC_TYPE is not null
       and aC_ANC_TYPE in('1', '2', '3') then
      if aA_IDCRE is not null then
        -- RAZ des Variables globales
        SQM_ANC_INITIALIZE.ResetANCRecord(SQM_ANC_INITIALIZE.SQM_ANC_Rec);

        -- Initialisation du Record : Si initialisation indiv .
        if aIndivInitProc is not null then
          SQM_ANC_INITIALIZE.CallIndivInitProc(aIndivInitProc
                                             , 'SQM_ANC_INITIALIZE.SQM_ANC_Rec'
                                             , aStringparam1
                                             , aStringParam2
                                             , aStringParam3
                                             , aStringParam4
                                             , aStringParam5
                                             , aCurrencyParam1
                                             , aCurrencyParam2
                                             , aCurrencyParam3
                                             , aCurrencyParam4
                                             , aCurrencyParam5
                                             , aIntegerParam1
                                             , aIntegerParam2
                                             , aIntegerParam3
                                             , aIntegerParam4
                                             , aIntegerParam5
                                             , aDateParam1
                                             , aDateParam2
                                             , aDateParam3
                                             , aDateParam4
                                             , aDateParam5
                                              );
        end if;

        -- Utilisation des paramètres d'appel de la fonction.
        FormatANCWithGenerationParams(SQM_ANC_INITIALIZE.SQM_ANC_Rec
                                    , aC_ANC_TYPE
                                    , aDIC_ANC_CODE_ID
                                    , aPC_LANG_ID
                                    , aPAC_CUSTOM_PARTNER_ID
                                    , aPAC_SUPPLIER_PARTNER_ID
                                    , aDOC_DOCUMENT_ID
                                    , aFAL_LOT_ID
                                    , aANC_SHORT_DESCRIPTION
                                    , aANC_LONG_DESCRIPTION
                                    , aDOC_RECORD_ID
                                    , aASA_RECORD_ID
                                    , aA_IDCRE
                                    , aANC_DATE
                                    , aPAC_ADDRESS_ID
                                     );
        -- Champs calculés:
        CalculateANCFields(SQM_ANC_INITIALIZE.SQM_ANC_Rec);
        -- Vérification des règles d'intégrité de la NC.
        CheckNCIntegrity(SQM_ANC_INITIALIZE.SQM_ANC_Rec);

        -- Création de la NC.
        begin
          Insert_NC(SQM_ANC_INITIALIZE.SQM_ANC_Rec);
        exception
          when others then
            raise;
        end;

        return SQM_ANC_INITIALIZE.SQM_ANC_Rec.SQM_ANC_ID;
      -- A_IDCRE non précisé
      else
        Raise_application_error(-20100, PCS.PC_FUNCTIONS.TranslateWord('Le créateur de la NC doit être précisé!') );
      end if;
    -- Type non précisé
    else
      Raise_application_error
        (-20100
       , PCS.PC_FUNCTIONS.TranslateWord
                                    ('Le type de la NC à créer doit obligatoirement être précisé. Echec de la création!')
        );
    end if;
  end GenerateANC;

  /**
  * Procedure   : UpdateNCStatus
  *
  * Description : Procédure de changement de status d'une NC (Ne permet pas de passer à un status inférieur).
  *
  */
  procedure UpdateNCStatus(
    aSQM_ANC_ID            SQM_ANC.SQM_ANC_ID%type
  , aUseExternalProc       boolean
  , aPC_ANC_USER2_ID       SQM_ANC.PC_ANC_USER2_ID%type   -- Valideur NC.
  , aPC_ANC_USER3_ID       SQM_ANC.PC_ANC_USER3_ID%type   -- Affecteur NC.
  , aPC_ANC_USER4_ID       SQM_ANC.PC_ANC_USER4_ID%type   -- Responsable NC.
  , aC_ANC_STATUS          SQM_ANC.C_ANC_STATUS%type   -- Statut NC. (A valider de toute façon à la création).
  , aANC_PARTNER_DATE      SQM_ANC.ANC_PARTNER_DATE%type   -- Date réclamation tiers
  , aANC_PRINT_RECEPT_DATE SQM_ANC.ANC_PRINT_RECEPT_DATE%type   -- Date Impression
  , aANC_VALIDATION_DATE   SQM_ANC.ANC_VALIDATION_DATE%type   -- Date validation
  , aANC_ALLOCATION_DATE   SQM_ANC.ANC_ALLOCATION_DATE%type
  )   -- Date affectation
  is
    aOldStatus        SQM_ANC.C_ANC_STATUS%type;
    aResultat         SQM_ANC_FUNCTIONS.MaxVarchar2;
    blnContinueUpdate boolean;
  begin
    blnContinueUpdate  := true;

    -- Récupération du status de la NC avant modification
    select C_ANC_STATUS
      into aOldStatus
      from SQM_ANC
     where SQM_ANC_ID = aSQM_ANC_ID;

    -- Si NC Refusée
    if aOldStatus = '2' then
      SQM_ANC_GENERATE.AddErrorReport
                       (PCS.PC_FUNCTIONS.TranslateWord('La NC est déjà refusée, son statut ne peut plus être changé!')
                      , aSQM_ANC_ID
                      , 1
                       );
      blnContinueUpdate  := false;
    -- Si NC Bouclée.
    elsif aOldStatus = '5' then
      SQM_ANC_GENERATE.AddErrorReport
                       (PCS.PC_FUNCTIONS.TranslateWord('La NC est déjà bouclée, son statut ne peut plus être changé!')
                      , aSQM_ANC_ID
                      , 1
                       );
      blnContinueUpdate  := false;
    -- Si NC "A valider".
    elsif aOldStatus = '1' then
      -- Doit être refusée
      if aC_ANC_STATUS = '2' then
        SQM_ANC_FUNCTIONS.ANCRejection(aSQM_ANC_ID, aResultat, aUseExternalProc, aANC_VALIDATION_DATE
                                     , aPC_ANC_USER2_ID);

        if aResultat is not null then
          SQM_ANC_GENERATE.AddErrorReport(aResultat, aSQM_ANC_ID, 1);
          blnContinueUpdate  := false;
        end if;
      end if;

      -- Doit être validée
      if     (   aC_ANC_STATUS = '3'
              or aC_ANC_STATUS = '4')
         and blnContinueUpdate then
        SQM_ANC_FUNCTIONS.ANCValidation(aSQM_ANC_ID
                                      , aResultat
                                      , aUseExternalProc
                                      , aANC_VALIDATION_DATE
                                      , aPC_ANC_USER2_ID
                                       );

        if aResultat is not null then
          SQM_ANC_GENERATE.AddErrorReport(aResultat, aSQM_ANC_ID, 1);
          blnContinueUpdate  := false;
        end if;
      end if;

      -- Doit être Affectée
      if     aC_ANC_STATUS = '4'
         and blnContinueUpdate then
        SQM_ANC_FUNCTIONS.ANCAllocation(aSQM_ANC_ID
                                      , aPC_ANC_USER4_ID
                                      , aResultat
                                      , aUseExternalProc
                                      , aANC_ALLOCATION_DATE
                                      , aPC_ANC_USER3_ID
                                       );

        if aResultat is not null then
          SQM_ANC_GENERATE.AddErrorReport(aResultat, aSQM_ANC_ID, 1);
          blnContinueUpdate  := false;
        end if;
      end if;
    -- Si NC "Validée""
    elsif aOldStatus = '3' then
      -- Doit être affectée
      if aC_ANC_STATUS = '4' then
        SQM_ANC_FUNCTIONS.ANCAllocation(aSQM_ANC_ID
                                      , aPC_ANC_USER4_ID
                                      , aResultat
                                      , aUseExternalProc
                                      , aANC_ALLOCATION_DATE
                                      , aPC_ANC_USER3_ID
                                       );

        if aResultat is not null then
          SQM_ANC_GENERATE.AddErrorReport(aResultat, aSQM_ANC_ID, 1);
          blnContinueUpdate  := false;
        end if;
      end if;
    end if;
  end UpdateNCStatus;

  /**
  * function ExistAttributField.
  * Description :  Fonction qui teste si l'attribut existe
  *
  * aAttributeName  : Nom du champ attribut
  */
  function ExistAttributField(aAttributeName varchar2)
    return boolean
  is
    aResultat      boolean;
    tmpPC_FLDSC_ID PCS.PC_FLDSC.PC_FLDSC_ID%type;
  begin
    aResultat  := true;

    -- Vérification de la validité du nom de l'attribut
    -- Si champ dictionnaire
    if instr(aAttributeName, 'DIC_SQM_ATTRIBUTE_FREE') <> 0 then
      begin
        select FLD.PC_FLDSC_ID
          into tmpPC_FLDSC_ID
          from PCS.PC_FLDSC FLD
             , PCS.PC_TABLE TBL
         where TBL.PC_TABLE_ID = FLD.PC_TABLE_ID
           and TBL.TABNAME = replace(aAttributeName, '_ID', '')
           and FLD.FLDNAME = aAttributeName;
      exception
        when no_data_found then
          aResultat  := false;
      end;
    -- Sinon
    else
      begin
        select FLD.PC_FLDSC_ID
          into tmpPC_FLDSC_ID
          from PCS.PC_FLDSC FLD
             , PCS.PC_TABLE TBL
         where TBL.PC_TABLE_ID = FLD.PC_TABLE_ID
           and TBL.TABNAME = 'SQM_ANC_ATTRIBUTE'
           and FLD.FLDNAME = aAttributeName;
      exception
        when no_data_found then
          aResultat  := false;
      end;
    end if;

    return aResultat;
  end;

  /**
  * function ExistAttributRecord.
  * Description :  Fonction qui teste si l'enregistrement l'attribut existe pour l'ANC ou non.
  *
  * aSQM_ANC_ID : NC concernée.
  */
  function ExistAttributRecord(aSQM_ANC_ID SQM_ANC.SQM_ANC_ID%type)
    return boolean
  is
    aResultat     boolean;
    tmpSQM_ANC_ID SQM_ANC.SQM_ANC_ID%type;
  begin
    aResultat  := true;

    begin
      select SQM_ANC_ID
        into tmpSQM_ANC_ID
        from SQM_ANC_ATTRIBUTE
       where SQM_ANC_ID = aSQM_ANC_ID;
    exception
      when no_data_found then
        aResultat  := false;
    end;

    return aResultat;
  end;

  /**
  * Procedure AddANCCHARAttribute
  * Description :  Ajout d'un attribut de Type Chaine de caractère à l'ANC. Si déjà existant, son ancienne valeur est écrasée.
  *                Utilisée pour l'ajout des attributs de type Dico, Textes et descodes
  *
  * aAttributeName  : Nom du champ attribut
  * aAttributeValue : Valeur de l'attribut
  */
  procedure AddANCAttribute(
    aSQM_ANC_ID        SQM_ANC.SQM_ANC_ID%type
  , aAttributeName     varchar2
  , aAttributCharValue varchar2
  , aAttributNumValue  number
  , aAttributDateValue varchar2
  , aDateFormat        varchar2
  )
  is
    BuffSQL               varchar2(4000);
    Cursor_Handle         integer;
    Execute_Cursor        integer;
    blnCreateAttribRecord boolean;
    blnValidAttributeName boolean;
    tmpSQM_ANC_ID         SQM_ANC.SQM_ANC_ID%type;
    tmpPC_FLDSC_ID        PCS.PC_FLDSC.PC_FLDSC_ID%type;
  begin
    blnCreateAttribRecord  := false;
    blnValidAttributeName  := true;

    -- Insertion de l'attribut
    if (aAttributeName is not null) then
      -- Vérification du nom de l'attribut
      if ExistAttributField(aAttributeName) then
        if    (     (instr(aAttributeName, 'DIC_SQM_ATTRIBUTE') > 0)
               and IsGoodDicoValue(replace(aAttributeName, '_ID', ''), aAttributCharValue)
              )
           or (instr(aAttributeName, 'DIC_SQM_ATTRIBUTE') = 0) then
          -- Vérification de l'existance du record d'attributs pour la NC.
          blnCreateAttribRecord  := not(ExistAttributRecord(aSQM_ANC_ID) );

          -- Construction dynamique INSERT ou UPDATE
          if blnCreateAttribRecord then
            BuffSQL  :=
              ' INSERT INTO SQM_ANC_ATTRIBUTE (SQM_ANC_ID' ||
              ',' ||
              aAttributeName ||
              ',A_DATECRE' ||
              ',A_IDCRE)' ||
              ' VALUES (' ||
              aSQM_ANC_ID;

            if aAttributCharValue is not null then
              BuffSQL  := BuffSQL || ',''' || replace(aAttributCharValue, '''', '''''') || '''';
            elsif aAttributNumValue is not null then
              BuffSQL  := BuffSQL || ',' || aAttributNumValue;
            elsif aAttributDateValue is not null then
              BuffSQL  := BuffSQL || ',TO_DATE(''' || aAttributDateValue || ''',''' || aDateFormat || ''')';
            end if;

            BuffSQL  := BuffSQL || ',sysdate' || ',''' || PCS.PC_PUBLIC.GetUserIni || ''')';
          else
            BuffSQL  := ' UPDATE SQM_ANC_ATTRIBUTE ' || '    SET ' || aAttributeName || ' = ';

            if aAttributCharValue is not null then
              BuffSQL  := BuffSQL || '''' || replace(aAttributCharValue, '''', '''''') || '''';
            elsif aAttributNumValue is not null then
              BuffSQL  := BuffSQL || aAttributNumValue;
            elsif aAttributDateValue is not null then
              BuffSQL  := BuffSQL || 'TO_DATE(''' || aAttributDateValue || ''',''' || aDateFormat || ''')';
            end if;

            BuffSQL  :=
              BuffSQL ||
              ' , A_DATEMOD = sysdate' ||
              ' , A_IDMOD   = ''' ||
              PCS.PC_PUBLIC.GetUserIni ||
              '''' ||
              ' WHERE SQM_ANC_ID = ' ||
              aSQM_ANC_ID;
          end if;

          Cursor_Handle          := DBMS_SQL.open_cursor;
          DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.V7);
          Execute_Cursor         := DBMS_SQL.execute(Cursor_Handle);
          DBMS_SQL.close_cursor(Cursor_Handle);
        else
          AddErrorReport
                   (PCS.PC_FUNCTIONS.TranslateWord('Problème de création de l''attribut. La valeur est incorrecte!') ||
                    '( ' ||
                    aAttributeName ||
                    ' )'
                  , aSQM_ANC_ID
                  , 1
                   );
        end if;
      else
        AddErrorReport
               (PCS.PC_FUNCTIONS.TranslateWord('Problème de création de l''attribut. Le nom précisé est incorrect!') ||
                '( ' ||
                aAttributeName ||
                ' )'
              , aSQM_ANC_ID
              , 1
               );
      end if;
    else
      AddErrorReport
        (PCS.PC_FUNCTIONS.TranslateWord('Problème de création de l''attribut. Le nom de l''attribut doit être précisé!')
       , aSQM_ANC_ID
       , 1
        );
    end if;
  exception
    when others then
      AddErrorReport(PCS.PC_FUNCTIONS.TranslateWord('Erreur à l''insertion d''un attribut') ||
                     ' ' ||
                     sqlcode ||
                     ' ' ||
                     sqlerrm
                   , aSQM_ANC_ID
                   , 1
                    );
  end;

  /**
  * function AddANCNUMERICAttribute
  * Description :  Ajout d'un attribut de type numérique à l'ANC. Si déjà existant, son ancienne valeur est écrasée.
  *                Utilisée pour l'ajout des attributs de type Integer, float et booléen.
  *
  * aAttributeName  : Nom du champ attribut
  * aAttributeValue : Valeur de l'attribut
  */
  procedure AddANCNUMERICAttribute(aSQM_ANC_ID SQM_ANC.SQM_ANC_ID%type, aAttributeName varchar2, aAttributValue number)
  is
  begin
    AddANCAttribute(aSQM_ANC_ID, aAttributeName, null, aAttributValue, null, null);
  end AddANCNUMERICAttribute;

  /**
  * function AddANCDATEAttribute
  * Description :  Ajout d'un attribut de type date à l'ANC. Si déjà existant, son ancienne valeur est écrasée.
  *                Utilisée pour l'ajout des attributs de type date.
  *
  * aAttributeName  : Nom du champ attribut
  * aAttributeValue : Valeur de l'attribut
  */
  procedure AddANCDATEAttribute(
    aSQM_ANC_ID    SQM_ANC.SQM_ANC_ID%type
  , aAttributeName varchar2
  , aAttributValue varchar2
  , aDateFormat    varchar2
  )
  is
  begin
    AddANCAttribute(aSQM_ANC_ID, aAttributeName, null, null, aAttributValue, aDateFormat);
  end AddANCDATEAttribute;

  /**
  * Procedure AddANCCHARAttribute
  * Description :  Ajout d'un attribut de Type Chaine de caractère à l'ANC. Si déjà existant, son ancienne valeur est écrasée.
  *                Utilisée pour l'ajout des attributs de type Dico, Textes et descodes
  *
  * aAttributeName  : Nom du champ attribut
  * aAttributeValue : Valeur de l'attribut
  */
  procedure AddANCCHARAttribute(aSQM_ANC_ID SQM_ANC.SQM_ANC_ID%type, aAttributeName varchar2, aAttributValue varchar2)
  is
  begin
    AddANCAttribute(aSQM_ANC_ID, aAttributeName, aAttributValue, null, null, null);
  end AddANCCHARAttribute;

  /*
  * Fonction de vérification de la valeur d'une dictionnaire
  *
  */
  function IsGoodDicoValue(aDicoName varchar2, aDicoValue varchar2)
    return boolean
  is
    BuffSQL        varchar2(2000);
    Cursor_Handle  integer;
    Execute_Cursor integer;
    vDIC_ID        varchar2(10);
    aResultat      boolean;
  begin
    if aDicoValue is not null then
      aResultat       := true;
      -- Recherche du taux
      BuffSQL         :=
        'SELECT ' || aDicoName || '_ID' || '  FROM ' || aDicoName || ' WHERE ' || aDicoName || '_ID = ''' || aDicoValue
        || '''';
      Cursor_Handle   := DBMS_SQL.open_cursor;
      DBMS_SQL.PARSE(Cursor_Handle, BuffSQL, DBMS_SQL.V7);
      DBMS_SQL.Define_column(Cursor_Handle, 1, vDIC_ID, 10);
      Execute_Cursor  := DBMS_SQL.execute(Cursor_Handle);

      loop
        if DBMS_SQL.fetch_rows(Cursor_Handle) > 0 then
          aResultat  := true;
          exit;
        else
          aResultat  := false;
          exit;
        end if;
      end loop;

      DBMS_SQL.close_cursor(Cursor_Handle);
      return aResultat;
    else
      return true;
    end if;
  exception
    when others then
      return false;
  end IsGoodDicoValue;
end SQM_ANC_GENERATE;
